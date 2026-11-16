"""Read the retail AvatarAssetPack.toc (the console's own avatar pack).

The toc is ASCII/UTF-16 names followed by LZX-compressed chunks. Each chunk is
the same 12-byte headered block the NXE closet uses:

    u32 compressed, u32 output_offset, u32 output_size

with output_size 0x8000 except the last chunk of an asset. The chunks are
stored out of order in the file, so they are placed by output_offset and a new
asset starts wherever output_offset is 0.

Usage:
    python3 pack_toc.py <AvatarAssetPack.toc> [outdir]

Writes one file per asset to outdir (default: pack_assets/) and prints a table
of what parsed as a model through avatar_mesh.read_model.
"""

import os
import struct
import sys

import avatar_mesh
import lzx

CHUNK = 0x8000
HEADER = 12
# The chunk table starts after the name pool; scanning the whole file is
# cheap and avoids depending on the exact header layout.
SCAN_FROM = 0x100000


def blocks(data):
    """Every (position, compressed, out_off, out_size) LZX chunk in the file."""
    found = []
    pos = SCAN_FROM
    while pos + HEADER <= len(data):
        comp, out_off, out_size = struct.unpack_from("<III", data, pos)
        # The last chunk of an asset is short, so sizes below 0x8000 count too.
        # Dropping them truncates every asset whose size is not a multiple of
        # the chunk size, which is most of them.
        if (
            0x40 <= out_size <= CHUNK
            and 0x40 <= comp < 0x40000
            and out_off % CHUNK == 0
            and out_off < 0x200000
        ):
            found.append((pos, comp, out_off, out_size))
        pos += 4
    return found


def build(data):
    """Decompressed assets, in file order, each starting at an out_off of 0."""
    assets = []
    current = None
    for pos, comp, out_off, out_size in blocks(data):
        try:
            chunk = lzx.decompress(data[pos + HEADER:pos + HEADER + comp], out_size, CHUNK)
        except Exception:
            continue
        if out_off == 0:
            current = bytearray()
            assets.append(current)
        if current is None:
            continue
        if len(current) < out_off:
            current.extend(b"\x00" * (out_off - len(current)))
        current[out_off:out_off + len(chunk)] = chunk
    return assets


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    path = sys.argv[1]
    outdir = sys.argv[2] if len(sys.argv) > 2 else "pack_assets"
    data = open(path, "rb").read()
    assets = build(data)
    os.makedirs(outdir, exist_ok=True)
    parsed = 0
    for index, asset in enumerate(assets):
        with open(os.path.join(outdir, "%04d.bin" % index), "wb") as handle:
            handle.write(asset)
        try:
            batch = avatar_mesh.read_model(bytes(asset))[0]
            ys = [v[1] for v in batch["vertices"]]
            print(
                "%4d  %6d bytes  %4d verts  %4d idx  y[%.3f, %.3f]"
                % (index, len(asset), len(batch["vertices"]), len(batch["indices"]),
                   min(ys), max(ys))
            )
            parsed += 1
        except Exception as exc:
            print("%4d  %6d bytes  %s" % (index, len(asset), exc))
    print("%d assets, %d parsed as models" % (len(assets), parsed))
    return 0


if __name__ == "__main__":
    sys.exit(main())
