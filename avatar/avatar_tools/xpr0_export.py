#!/usr/bin/env python3
"""Decode an XPR0 texture (the dashboard's `.xbx` skins) to PNG.

    python3 xpr0_export.py IN.xbx OUT.png
    python3 xpr0_export.py --all SRCDIR OUTDIR

An XPR0 is a 2048-byte header, then a plain DXT image. The shape follows from the
payload length (a square DXT5 texture is `side * side` bytes, DXT1 half that);
`decode_audit.py` already validated the size field against the file length. The
bytes are ordinary DXT, not the console's 8-in-16 swizzle, so they decode with
the same decoder the avatar pack uses, byte order untouched.
"""
import os
import struct
import sys

import avatar_mesh as mesh


def decode(path):
    """(rgba array, description) or None when the payload is not a DXT image."""
    size = os.path.getsize(path)
    with open(path, "rb") as fh:
        head = fh.read(12)
        if head[:4] != b"XPR0":
            return None
        total, header = struct.unpack_from("<2I", head, 4)
        if total != size or header >= size:
            return None
        payload_bytes = size - header
        fh.seek(header)
        data = fh.read(payload_bytes)
        for side in (4096, 2048, 1024, 512, 256, 128, 64, 32, 16):
            quarter = side * side // 2
            if payload_bytes == quarter:
                return (mesh.decode_dxt(data, side, side, False, swap=False),
                        "%dx%d DXT1" % (side, side))
            if payload_bytes > side * side:
                # Base image plus a mip tail, every level allocated in whole
                # 2048-byte sectors: cellwall.xbx is 256x256 DXT5 (32 sectors)
                # with 16384 + 4096 + 1024 + 1024 of mips, 43 sectors in all.
                tail = payload_bytes - side * side
                if tail % 2048:
                    continue
                rgba = mesh.decode_dxt(data[:side * side], side, side, True, swap=False)
                return rgba, "%dx%d DXT5 + %d-sector mip tail" % (side, side, tail // 2048)
            if payload_bytes != side * side:
                continue
            # side * side fits both a DXT5 image and a pair of DXT1 planes. A
            # wrong guess decodes to block noise, so judge by which comes out
            # smoother: decept.xbx scores 0.8 as two DXT1 planes and 14.7 as one
            # DXT5, and its first plane is a clean scanline graphic.
            as_dxt5 = mesh.decode_dxt(data, side, side, True, swap=False)
            as_pair = mesh.decode_dxt(data[:quarter], side, side, False, swap=False)
            if roughness(as_pair) <= roughness(as_dxt5):
                return as_pair, "%dx%d DXT1 (first of two planes)" % (side, side)
            return as_dxt5, "%dx%d DXT5" % (side, side)
    return None


def roughness(rgba):
    """How block-noisy an image is: mean neighbour difference over a band."""
    import numpy as np
    band = rgba[:64, :, :3].astype(np.int16)
    if band.size == 0:
        return 0.0
    return float(np.abs(np.diff(band, axis=1)).mean())


def write_png(path, rgba):
    """RGBA PNG, 8-bit, one IDAT: enough for checking a decode by eye."""
    import numpy as np
    import zlib
    height, width = rgba.shape[:2]
    raw = b"".join(b"\x00" + rgba[row].tobytes() for row in range(height))
    def chunk(tag, body):
        return (struct.pack(">I", len(body)) + tag + body
                + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF))
    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 9))
           + chunk(b"IEND", b""))
    open(path, "wb").write(png)


def main(argv):
    if len(argv) == 2 and argv[0] != "--all":
        result = decode(argv[0])
        if not result:
            print("%s is not a decodable XPR0 texture" % argv[0])
            return 1
        rgba, note = result
        write_png(argv[1], rgba)
        print("%s -> %s (%s)" % (argv[0], argv[1], note))
        return 0
    if len(argv) == 3 and argv[0] == "--all":
        source, outdir = argv[1], argv[2]
        os.makedirs(outdir, exist_ok=True)
        done = skipped = 0
        for base, _, files in os.walk(source):
            for name in files:
                if not name.lower().endswith(".xbx"):
                    continue
                path = os.path.join(base, name)
                result = decode(path)
                if not result:
                    skipped += 1
                    continue
                rgba, note = result
                flat = os.path.splitext(os.path.relpath(path, source).replace(os.sep, "_"))[0]
                write_png(os.path.join(outdir, flat + ".png"), rgba)
                done += 1
        print("decoded %d textures, skipped %d" % (done, skipped))
        return 0
    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
