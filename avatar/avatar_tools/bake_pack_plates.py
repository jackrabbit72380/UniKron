"""Bake one aligned 2D plate per pack item, for the 2D stage's layer stack.

`bake_pack_thumbs.py` frames each item by its own bounding box, which is right for
a strip thumbnail and wrong for a layer: a shirt and a pair of shoes come out at
different scales and positions, so stacking them cannot make one avatar.

Here every item is posed on the same frame as the body it is worn on:

1. pose `MaleBody` alone and take its centre/height (the same numbers
   `bake_turntable.normalise` uses);
2. pose the item alone in the same bind pose;
3. move the item's vertices into that reference frame and render one front view.

The result is a transparent 256x384 plate per item, all registered to each other.

    python3 bake_pack_plates.py PACK CLIP DESCRIPTION \
        --categories 40_shirt,20_pants,30_shoes [--limit N]
"""

import argparse
import json
import math
import os
import subprocess
import sys

import numpy as np

import bake_turntable as bt
from bake_pack_thumbs import slug

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = {"MaleBody", "FemaleBody", "Head"}
DRESS = {"80_dress", "81_formal", "83_dress-formal"}


def bake_obj(pack, clip, description, parts, out):
    args = [sys.executable, os.path.join(HERE, "bake_avatar.py"), pack, clip, "0", out,
            "--colours=" + description, "--hair=6e5326"] + list(parts)
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode != 0 or not os.path.exists(out):
        raise RuntimeError((result.stderr.strip().splitlines() or ["bake_avatar failed"])[-1])
    return out


def reference_frame(pack, clip, description):
    """The body's own normalisation: centre x/z, feet at zero, one unit tall."""
    obj = bake_obj(pack, clip, description, ["MaleBody"], "/tmp/plate_body.obj")
    verts, _, _ = bt.read_obj(obj)
    os.remove(obj)
    lo = verts.min(axis=0)
    hi = verts.max(axis=0)
    centre = np.array([np.median(verts[:, 0]), lo[1], np.median(verts[:, 2])])
    height = max(hi[1] - lo[1], 1e-6)
    return centre, height


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("pack")
    ap.add_argument("clip")
    ap.add_argument("description")
    ap.add_argument("--categories", default="40_shirt,20_pants,30_shoes,60_hat")
    ap.add_argument("--catalog", default=os.path.join(HERE, "asset_catalog.json"))
    ap.add_argument("--outdir", default=os.path.join(os.path.dirname(HERE), "pack_plates"))
    ap.add_argument("--width", type=int, default=256)
    ap.add_argument("--height", type=int, default=384)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--include-base", action="store_true",
                    help="also plate MaleBody/FemaleBody/Head, for a base layer "
                         "drawn in the same frame as the items")
    args = ap.parse_args()

    wanted = set(args.categories.split(","))
    with open(args.catalog, "r", encoding="utf-8") as fh:
        catalog = json.load(fh)["assets"]
    items = []
    for record in catalog:
        category = (record.get("metadata") or {}).get("category")
        if category not in wanted or not record.get("vertices"):
            continue
        if record["name"] in BASE and not args.include_base:
            continue
        items.append((record["name"], category))
    if args.limit:
        items = items[:args.limit]
    print("%d plates to bake" % len(items))

    centre, height = reference_frame(args.pack, args.clip, args.description)
    print("body frame: centre %s, height %.4f" % (np.round(centre, 4), height))

    baked = skipped = failed = 0
    for name, category in items:
        folder = os.path.join(args.outdir, category)
        path = os.path.join(folder, slug(name) + ".png")
        if os.path.exists(path):
            skipped += 1
            continue
        obj = "/tmp/plate_%s.obj" % slug(name)
        try:
            bake_obj(args.pack, args.clip, args.description, [name], obj)
        except RuntimeError as exc:
            failed += 1
            print("  failed %s: %s" % (name, exc))
            continue
        verts, tris, colours = bt.read_obj(obj)
        os.remove(obj)
        verts = (verts - centre) / height
        vnormals = bt.vertex_normals(verts, tris)
        # Half a turn: the bake starts at the avatar's back.
        rgba = bt.render(verts, tris, colours, vnormals, math.pi,
                         args.width, args.height)
        os.makedirs(folder, exist_ok=True)
        bt.write_png(path, rgba)
        baked += 1
        if baked % 20 == 0:
            print("  %d baked" % baked)

    print("baked %d, skipped %d, failed %d into %s"
          % (baked, skipped, failed, args.outdir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
