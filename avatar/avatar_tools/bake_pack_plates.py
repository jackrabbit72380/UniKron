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
import shutil
import subprocess
import sys
import tempfile

import numpy as np

import bake_turntable as bt
from bake_pack_thumbs import slug

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = {"MaleBody", "FemaleBody", "Head"}
# Per process: two bakes running at once were deleting each other's objects when
# this was a fixed name in /tmp.
WORK = tempfile.mkdtemp(prefix="plate_")
DRESS = {"80_dress", "81_formal", "83_dress-formal"}


def bake_obj(pack, clip, description, parts, out):
    # `--face` brings the brow, eye and mouth masks, the same ones the 3D
    # turntables are baked with. Without it the head is a blank skin shell, which
    # is what the first run of plates looked like.
    args = [sys.executable, os.path.join(HERE, "bake_avatar.py"), pack, clip, "0", out,
            "--colours=" + description, "--hair=6e5326", "--face"] + list(parts)
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode != 0 or not os.path.exists(out):
        raise RuntimeError((result.stderr.strip().splitlines() or ["bake_avatar failed"])[-1])
    return out


def reference_frame(pack, clip, description):
    """The avatar's own normalisation: centre x/z, feet at zero, one unit tall.

    Measured on the body *with* its head. The pack keeps the head in a separate
    asset, so measuring the body alone puts the top of the frame at the neck and
    crops every plate that reaches above it.
    """
    obj = bake_obj(pack, clip, description, ["MaleBody", "Head"],
                   os.path.join(WORK, "body.obj"))
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
    ap.add_argument("--start", type=int, default=0,
                    help="skip the first N items, so a long rebake can be run "
                         "in chunks")
    ap.add_argument("--include-base", action="store_true",
                    help="also plate MaleBody/FemaleBody/Head, for a base layer "
                         "drawn in the same frame as the items")
    ap.add_argument("--force", action="store_true", help="rebake plates that exist")
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
    if args.start:
        items = items[args.start:]
    if args.limit:
        items = items[:args.limit]
    print("%d plates to bake" % len(items))

    centre, height = reference_frame(args.pack, args.clip, args.description)
    print("body frame: centre %s, height %.4f" % (np.round(centre, 4), height))

    baked = skipped = failed = 0
    occluder = []
    for name, category in items:
        folder = os.path.join(args.outdir, category)
        path = os.path.join(folder, slug(name) + ".png")
        if os.path.exists(path) and not args.force:
            skipped += 1
            continue
        obj = os.path.join(WORK, slug(name) + ".obj")
        # MaleBody and FemaleBody are bodies without heads - the pack keeps the
        # head in its own asset (the descriptor equips `Head` in slot 1) - so a
        # body plate has to bring it along or the 2D avatar has no head at all.
        parts = [name]
        if name in ("MaleBody", "FemaleBody"):
            parts.append("Head")
        try:
            bake_obj(args.pack, args.clip, args.description, parts, obj)
        except RuntimeError as exc:
            failed += 1
            print("  failed %s: %s" % (name, exc))
            continue
        verts, tris, colours = bt.read_obj(obj)
        face = bt.load_face(obj)
        verts = (verts - centre) / height
        vnormals = bt.vertex_normals(verts, tris)
        # Hair is an open shell: on its own the inside of its far side covers the
        # face, so the head is drawn into the depth buffer first and the plate
        # keeps only the hair that is actually in front of it.
        if category == "50_hair" and not occluder:
            head_obj = os.path.join(WORK, "occluder.obj")
            bake_obj(args.pack, args.clip, args.description,
                     ["MaleBody", "Head"], head_obj)
            overts, otris, _ = bt.read_obj(head_obj)
            occluder.append(((overts - centre) / height, otris))
        # Half a turn: the bake starts at the avatar's back.
        rgba = bt.render(verts, tris, colours, vnormals, math.pi,
                         args.width, args.height, face=face,
                         occluders=occluder if category == "50_hair" else None)
        os.makedirs(folder, exist_ok=True)
        bt.write_png(path, rgba)
        baked += 1
        if baked % 20 == 0:
            print("  %d baked" % baked)

    shutil.rmtree(WORK, ignore_errors=True)
    print("baked %d, skipped %d, failed %d into %s"
          % (baked, skipped, failed, args.outdir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
