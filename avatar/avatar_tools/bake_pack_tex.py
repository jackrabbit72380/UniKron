"""Extract the pack's `Texture` blocks as PNGs.

187 assets ship STRB block 2 instead of, or as well as, a Model block. Those are
exactly the skin, eye, hair-detail and face-paint items that have no geometry to
render, so this is the only art those items have.

Layout, confirmed on every one of the 187:

    the block is LZX-framed, so avatar_mesh.decompress opens it
    33-byte header, then exactly width*height bytes of pixels
    u32 width at +0x04, u32 height at +0x08, u32 size at +0x0c
    pixels are **DXT5 (BC3), linear, not tiled** and one byte per pixel

DXT1 was the first guess and is wrong: it decodes to stripes. DXT5 gives the
camo decal and the beard mask their shapes and their alpha.

    python3 bake_pack_tex.py PACK [--outdir ../pack_art] [--index ../PackIndex.qml]
"""

import argparse
import json
import os
import struct
import sys

import numpy as np

import avatar_mesh as am
import bake_turntable as bt
from bake_pack_thumbs import slug, write_index

HERE = os.path.dirname(os.path.abspath(__file__))


def texture_png(blob):
    """A STRB blob's Texture block -> (rgba array, width, height)."""
    payload = next((p for i, _, _, p in am.strb_blocks(blob) if i == 2), None)
    if payload is None:
        return None
    raw = am.decompress(payload)
    if len(raw) < 33:
        return None
    width, height = struct.unpack_from("<II", raw, 4)
    pixels = raw[33:33 + width * height]
    if len(pixels) != width * height:
        return None
    return np.asarray(am.decode_dxt(pixels, width, height, True)), width, height


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("pack")
    ap.add_argument("--catalog", default=os.path.join(HERE, "asset_catalog.json"))
    ap.add_argument("--outdir", default=os.path.join(os.path.dirname(HERE), "pack_art"))
    ap.add_argument("--index", metavar="PATH", help="rewrite this PackIndex.qml")
    args = ap.parse_args()

    with open(args.catalog, "r", encoding="utf-8") as fh:
        catalog = json.load(fh)["assets"]
    with open(args.pack, "rb") as fh:
        pack = fh.read()

    written = filled = skipped = failed = 0
    for record in catalog:
        if not any(b["id"] == 2 for b in record.get("blocks") or []):
            continue
        category = (record.get("metadata") or {}).get("category")
        if not category:
            continue
        folder = os.path.join(args.outdir, category)
        base = slug(record["name"])
        blob = pack[record["offset"]:record["offset"] + record["size"]]
        try:
            result = texture_png(blob)
        except Exception as exc:
            failed += 1
            print("  failed %s: %s" % (record["name"], exc))
            continue
        if not result:
            failed += 1
            continue
        rgba, width, height = result
        # An item with geometry already has a render, so its texture goes beside
        # it under its own name; an item without one gets the texture as its art.
        path = os.path.join(folder, base + ".png")
        if os.path.exists(path):
            path = os.path.join(folder, base + "-texture.png")
            skipped += 1
        else:
            filled += 1
        os.makedirs(folder, exist_ok=True)
        bt.write_png(path, rgba.astype(np.uint8))
        written += 1

    print("textures written %d (as item art %d, alongside a render %d), failed %d"
          % (written, filled, skipped, failed))

    if args.index:
        write_index(args.outdir, args.index)
    return 0


if __name__ == "__main__":
    sys.exit(main())
