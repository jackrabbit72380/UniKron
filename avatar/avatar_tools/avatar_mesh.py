#!/usr/bin/env python3
"""Decode avatar models out of AvatarAssetPack.toc into OBJ.

This is the missing link for the 3D view: the pack stores each asset as a
Y TGR/STRB container whose Model block (id 3) is a chain of LZX-compressed
blocks holding a bit-packed mesh. Nothing here could be guessed — it follows the
format implemented by Avatar Aura (crates/avatar-formats, itself a port of
xenia's kernel/xam/avatars), with the LZX decoder in lzx.py.

    python3 avatar_mesh.py --pack <AvatarAssetPack.toc> --asset MaleBody --obj male.obj

Confirmed against the shipped pack: LZX decodes, the STRB Model block parses, and
MaleBody yields 1137 vertices / 2264 triangles (FemaleBody 1232 / 2454).

Positions come out in BIND space, not as a standing figure: MaleBody measures
1.79 along x (up), 1.51 along y, 0.37 along z, and baking it gives one bent limb
rather than a body. The block carries per-vertex blend indices and weights, so
the vertices are posed by the skeleton (STRB block 5) at draw time. Assembling a
standing avatar therefore needs skeleton + skinning, which is not implemented
here; for a posed model today, export from Avatar Aura and bake that.

Written values are positions and triangle indices only. Normals are lattice
packed and UVs are half floats per UV layer; flat shading needs neither.
"""

import argparse
import json
import os
import struct
import sys

import lzx

SIGNATURE_SIZE = 0x140
BLOCK_HEADER_SIZE = 12
WINDOW_SIZE = 0x8000

BLOCK_NAMES = {
    0: "Invalid",
    1: "Animation",
    2: "Texture",
    3: "Model",
    4: "ShapeOverrides",
    5: "Skeleton",
    6: "AssetMetadataUnversioned",
    7: "CustomColorTable",
    8: "AssetMetadataVersioned",
}


class Malformed(Exception):
    pass


# ---------------------------------------------------------------- bit stream

class BitStream:
    """LSB-first bit reader over bytes, as the avatar formats define it."""

    def __init__(self, data):
        self.data = data
        self.offset = 0
        self.size_bits = len(data) * 8

    def check(self, num_bits):
        if self.offset + num_bits > self.size_bits:
            raise Malformed("bit overrun at %d (+%d of %d)" % (self.offset, num_bits, self.size_bits))

    def read(self, num_bits):
        if num_bits > 64:
            raise Malformed("read wider than 64 bits")
        self.check(num_bits)
        result = 0
        shift = 0
        offset = self.offset
        left = num_bits
        while left > 0:
            bit_in_byte = offset % 8
            take = min(8 - bit_in_byte, left)
            mask = (1 << take) - 1
            value = self.data[offset >> 3] >> bit_in_byte
            result |= (mask & value) << shift
            shift += take
            left -= take
            offset += take
        self.offset += num_bits
        return result

    def read_u8_bits(self, n):
        if n > 8:
            raise Malformed("u8 read wider than 8 bits")
        return self.read(n)

    def read_u16(self):
        return self.read(16)

    def read_u32(self):
        return self.read(32)

    def read_i32(self):
        v = self.read(32)
        return v - (1 << 32) if v & (1 << 31) else v

    def read_i64_bits(self, n):
        v = self.read(n)
        if n and v & (1 << (n - 1)):
            v -= 1 << n
        return v

    def read_f32(self):
        return struct.unpack("<f", struct.pack("<I", self.read(32)))[0]

    def advance(self, n):
        self.check(n)
        self.offset += n

    def align_to_next_byte(self):
        self.offset = (self.offset + 7) & ~7
        self.check(0)


# ---------------------------------------------------------------- serializers

class VectorSerializer:
    """Lattice-quantized Vec3: base point, hexagonal step, per-axis bit widths."""

    def __init__(self, stream):
        self.quant_radius = stream.read_f32()
        self.base_x = stream.read_f32()
        self.base_y = stream.read_f32()
        self.base_z = stream.read_f32()
        self.bit_count_x = stream.read_u8_bits(6)
        self.bit_count_y = stream.read_u8_bits(6)
        self.bit_count_z = stream.read_u8_bits(6)
        self.delta_x = self.quant_radius * 2.0
        self.delta_y = self.quant_radius * (2.0 / 3.0) * (6.0 ** 0.5)
        self.delta_z = self.quant_radius * (3.0 ** 0.5)

    def read(self, stream):
        # The lattice counts are unsigned: position = min + q * step * k with
        # q in 0..2^width-1. Sign-extending q shears every mesh (MaleBody came
        # out 1.79 wide and asymmetric instead of +-0.711); open-avatar-lib's
        # docs/FORMATS.md 3.3 states the formula and its MaleBody bounds, and
        # decoding these as unsigned reproduces them exactly.
        x = stream.read(self.bit_count_x) if self.bit_count_x else 0
        y = stream.read(self.bit_count_y) if self.bit_count_y else 0
        z = stream.read(self.bit_count_z) if self.bit_count_z else 0
        out_y = self.base_y + self.delta_y * y
        out_z = self.base_z + self.delta_z * z
        if y & 1:
            out_z += (1.0 / 3.0) * self.delta_z
        out_x = self.base_x + self.delta_x * x
        if (y & 1) != (z & 1):
            out_x += 0.5 * self.delta_x
        return (out_x, out_y, out_z)


class ValueSerializer:
    """Base value plus a fixed-width unsigned delta."""

    def __init__(self, stream, bits, signed=False):
        self.mask = (1 << bits) - 1
        self.signed = signed
        self.base = stream.read(bits)
        self.width = stream.read(bits)
        if self.width > 64:
            raise Malformed("value serializer width above 64")

    def read(self, stream):
        delta = stream.read(self.width) if self.width else 0
        v = (self.base + delta) & self.mask
        if self.signed and v & (1 << (self.mask.bit_length() - 1)):
            v -= self.mask + 1
        return v


# ---------------------------------------------------------------- compression

def decompress(data):
    """Chain of 12-byte-headered LZX blocks: (compressed, out_off, out_size)."""
    size = 0
    offset = 0
    while offset + BLOCK_HEADER_SIZE <= len(data):
        comp, out_off, out_size = struct.unpack_from("<III", data, offset)
        offset += BLOCK_HEADER_SIZE
        if comp > len(data) - offset:
            raise Malformed("compressed block past end")
        size = max(size, out_off + out_size)
        offset += comp
    out = bytearray(size)
    offset = 0
    while offset + BLOCK_HEADER_SIZE <= len(data):
        comp, out_off, out_size = struct.unpack_from("<III", data, offset)
        offset += BLOCK_HEADER_SIZE
        chunk = lzx.decompress(data[offset:offset + comp], out_size, WINDOW_SIZE)
        out[out_off:out_off + out_size] = chunk
        offset += comp
    return bytes(out)


# ---------------------------------------------------------------- STRB

def strb_blocks(buffer):
    """Every block: a table of (id, entry_count, entry_size) then the payloads."""
    strb = buffer
    if strb[:4] == b"YTGR":
        if len(strb) < SIGNATURE_SIZE:
            raise Malformed("short YTGR")
        strb = strb[SIGNATURE_SIZE:]
    if len(strb) < 24 or strb[:4] != b"STRB":
        raise Malformed("not a STRB container")

    has_alignment = strb[4] != 0
    little_endian = strb[5] != 0
    id_size = strb[22]
    size_size = strb[23]
    alignment = strb[26] if has_alignment else 1
    if alignment == 0:
        raise Malformed("block alignment of zero")

    def align(value):
        return (value + alignment - 1) & ~(alignment - 1)

    header_size = align(id_size + size_size + size_size)
    offset = align(30 if has_alignment else 26)
    order = "little" if little_endian else "big"
    if header_size == 0:
        raise Malformed("block header size of zero")

    out = []
    while offset + header_size <= len(strb):
        id_raw = int.from_bytes(strb[offset:offset + id_size], order)
        data_size = int.from_bytes(strb[offset + id_size:offset + id_size + size_size], order)
        entry_size = int.from_bytes(
            strb[offset + id_size + size_size:offset + id_size + 2 * size_size], order
        )
        offset += header_size
        total = data_size * entry_size
        payload = strb[offset:offset + total]
        if len(payload) != total:
            raise Malformed("block extends past container")
        out.append((id_raw, data_size, entry_size, payload))
        offset += align(data_size)
    return out


# ---------------------------------------------------------------- model

def read_model(data):
    """Triangle batches: vertices (lattice positions) and u16 indices."""
    s = BitStream(data)
    cpu_size = s.read_u32()
    gpu_size = s.read_u32()
    s.read_u32()  # texture buffer size
    s.read_u32()  # vertex buffer size
    s.read_u32()  # index buffer size
    batch_count = s.read_u32()
    texture_count = s.read_u32()
    s.read_u32()  # vertex buffer offset
    s.read_u32()  # index buffer offset
    s.read_u32()  # triangle batch array offset
    s.read_u32()  # texture array offset
    s.read_u32()  # texture scratch size
    if batch_count > 16 or texture_count > 18:
        raise Malformed("batch/texture count out of range")

    batches = []
    for _ in range(batch_count):
        shader_id = s.read_u32()
        param_count = s.read_u8_bits(5)
        triangle_count = s.read_u32()
        vertex_count = s.read_u32()
        uv_count = s.read_u32()
        vertex_size = s.read_u32()
        s.read_u32()  # index size
        s.read_u32()  # vertex array offset
        s.read_u32()  # index array offset
        s.align_to_next_byte()
        if triangle_count > 8192 or vertex_count > 8192 or uv_count > 6:
            raise Malformed("batch counts out of range")
        expected = (32 + 4 * (uv_count - 1)) & 0xFFFFFFFF
        if vertex_size != expected:
            raise Malformed("vertex size %d does not match %d UVs (expected %d)"
                            % (vertex_size, uv_count, expected))
        for _ in range(param_count):
            ptype = s.read_u32()
            s.read_u32()  # usage
            if ptype == 1:
                s.read_u16()  # texture index
                s.read_u16()  # uv layer
                s.read_u32()  # flags
                s.advance(64)
            else:
                s.advance(128)  # four floats
            s.align_to_next_byte()

        local_count = s.read_u32()
        if local_count != vertex_count:
            raise Malformed("vertex count mismatch")
        position = VectorSerializer(s)
        normal = ValueSerializer(s, 32, signed=True)
        weight = ValueSerializer(s, 32)
        blend = ValueSerializer(s, 32)
        colour = ValueSerializer(s, 32)

        verts = []
        joints = []
        weights = []
        for _ in range(vertex_count):
            p = position.read(s)
            normal.read(s)
            w = weight.read(s)
            b = blend.read(s)
            colour.read(s)
            for _ in range(uv_count):
                s.read_u16()
                s.read_u16()
            verts.append(p)
            # Four bone indices and four weights, one byte each.
            joints.append(((b >> 0) & 0xFF, (b >> 8) & 0xFF, (b >> 16) & 0xFF, (b >> 24) & 0xFF))
            weights.append((((w >> 0) & 0xFF) / 255.0, ((w >> 8) & 0xFF) / 255.0,
                            ((w >> 16) & 0xFF) / 255.0, ((w >> 24) & 0xFF) / 255.0))
        s.align_to_next_byte()

        index_count = s.read_u32()
        if index_count != triangle_count * 3:
            raise Malformed("index count mismatch")
        index_serializer = ValueSerializer(s, 16)
        indices = [index_serializer.read(s) for _ in range(index_count)]
        s.align_to_next_byte()

        batches.append({
            "shader_id": shader_id,
            "vertices": verts,
            "joints": joints,
            "weights": weights,
            "indices": indices,
        })
    return batches


# ---------------------------------------------------------------- pack access

def load_pack_index(pack_path):
    """Asset name -> (offset, size), from the JSON toc_parse.py writes."""
    here = os.path.dirname(os.path.abspath(pack_path))
    for candidate in (os.path.join(here, "avatar-assets.json"),
                      os.path.join(os.path.dirname(os.path.abspath(__file__)), "avatar-assets.json")):
        if os.path.exists(candidate):
            with open(candidate, "r", encoding="utf-8") as fh:
                doc = json.load(fh)
            assets = doc.get("assets", doc)
            index = {}
            for entry in assets:
                index[entry["name"]] = (entry["offset"], entry["size"])
            return index
    raise SystemExit("no avatar-assets.json next to the pack; run toc_parse.py first")


def asset_bytes(pack_path, index, name):
    if name not in index:
        close = [n for n in index if name.lower() in n.lower()][:8]
        raise SystemExit("asset %r not in the pack. Near misses: %s" % (name, ", ".join(close)))
    offset, size = index[name]
    with open(pack_path, "rb") as fh:
        fh.seek(offset)
        return fh.read(size)


def to_upright(p, up_axis):
    """Pack space into Y-up.

    The body meshes are authored X-up, Y-across, Z-depth: a standing male body
    measures about 1.79 along x, 1.51 along y (arms out, bind pose) and 0.37
    along z. Baking them as-is lays the figure on its side.
    """
    x, y, z = p
    if up_axis == "x":
        return (y, x, z)
    if up_axis == "z":
        return (x, z, y)
    return (x, y, z)


def write_obj(path, batches, up_axis="x"):
    lines = []
    base = 1
    for batch in batches:
        lines.append("o batch_%d" % batch["shader_id"])
        for (x, y, z) in batch["vertices"]:
            x, y, z = to_upright((x, y, z), up_axis)
            lines.append("v %.6f %.6f %.6f" % (x, y, z))
        idx = batch["indices"]
        for i in range(0, len(idx) - 2, 3):
            lines.append("f %d %d %d" % (base + idx[i], base + idx[i + 1], base + idx[i + 2]))
        base += len(batch["vertices"])
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")


def main():
    parser = argparse.ArgumentParser(description="Decode an avatar mesh from the asset pack.")
    parser.add_argument("--pack", required=True, help="AvatarAssetPack.toc")
    parser.add_argument("--asset", action="append",
                        help="asset name, e.g. MaleBody (repeat to merge several)")
    parser.add_argument("--obj", help="write the mesh here")
    parser.add_argument("--up-axis", default="x", choices=("x", "y", "z"),
                        help="which pack axis is up (bodies are x)")
    parser.add_argument("--blocks", action="store_true", help="list the container's blocks")
    args = parser.parse_args()

    index = load_pack_index(args.pack)
    names = args.asset or ["MaleBody"]
    print("%d assets in pack" % len(index))

    all_batches = []
    for name in names:
        blob = asset_bytes(args.pack, index, name)
        print("%s: %d bytes" % (name, len(blob)))
        blocks = strb_blocks(blob)
        if args.blocks:
            for id_raw, count, entry_size, payload in blocks:
                print("  block %-3d %-26s count=%d entry=%d bytes=%d"
                      % (id_raw, BLOCK_NAMES.get(id_raw, "Other"), count, entry_size, len(payload)))

        models = [b for b in blocks if b[0] == 3]
        if not models:
            raise SystemExit("no Model block in %s" % name)

        verts = tris = 0
        for _, _, _, payload in models:
            for batch in read_model(decompress(payload)):
                verts += len(batch["vertices"])
                tris += len(batch["indices"]) // 3
                all_batches.append(batch)
        print("  decoded %d model block(s): %d vertices, %d triangles"
              % (len(models), verts, tris))

    if args.obj:
        write_obj(args.obj, all_batches, args.up_axis)
        print("wrote", args.obj)


if __name__ == "__main__":
    main()
