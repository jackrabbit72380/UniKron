"""Bake a turntable set per pack item, so the 3D stage works in pack mode too.

`bake_items.py` bakes one set per entry in `items_3d.json`, i.e. per hand-drawn
wardrobe stem. Pack mode offers real items instead, whose stems are slugs of the
retail names (`male-power-tee`), and the stage looks for
`assets/3d/turntable/<slug>/frame_NN.png`.

Each set is the stock avatar wearing that one item: body, head and the seeded
hairstyle, then the item, then the rest of the stock outfit - the same
approximation `bake_items.py` makes, because a baked frame cannot mix two picks.

    python3 bake_pack_turntables.py PACK CLIP DESCRIPTION \
        --categories 40_shirt,20_pants,30_shoes [--frames 6] [--limit N]

All three inputs ship with the project, so this runs from a clean checkout:

    PACK="../../../src_archive/XBOX HUB/resources/editors/metro2010/assets/AvatarAssetPack.toc"
    CLIP="../../../src_archive/XBOX HUB/resources/editors/metro2010/assets/Cheer.AvatarAnimation"
    DESC=descriptors/Avatar6400.Avatar

Writes into ../assets/3d/turntable/<slug>/ and skips sets that already have
frames, so an interrupted run resumes.
"""

import argparse
import json
import math
import os
import subprocess
import sys

import numpy as np

import avatar_mesh as am
import bake_turntable as bt
from bake_pack_thumbs import slug

HERE = os.path.dirname(os.path.abspath(__file__))
STOCK = {"shirts": "Jacket with Sweater",
         "pants": "Male Flower Print Flares",
         "shoes": "Grunge Trainers"}
HAIR = "Left Parting"
HAIR_COLOUR = "6e5326"
CATEGORY_KIND = {"40_shirt": "shirts", "20_pants": "pants", "30_shoes": "shoes",
                 # A dress or a suit covers the torso and legs at once, so only the
                 # shoes are kept underneath.
                 "80_dress": "dress", "81_formal": "dress", "83_dress-formal": "dress"}


def bake_one(pack, clip, description, asset, kind, folder, frames, width, height):
    obj = "/tmp/pack_tt_%s.obj" % slug(asset)
    if kind == "dress":
        worn = [STOCK["shoes"]]
    else:
        worn = [STOCK[k] for k in ("shirts", "pants", "shoes") if k != kind]
    parts = ["MaleBody", "Head", HAIR, asset] + worn
    result = subprocess.run(
        [sys.executable, os.path.join(HERE, "bake_avatar.py"), pack, clip, "0", obj,
         "--colours=" + description, "--hair=" + HAIR_COLOUR, "--face"] + parts,
        capture_output=True, text=True)
    if result.returncode != 0 or not os.path.exists(obj):
        return "bake_avatar: " + (result.stderr.strip().splitlines() or ["failed"])[-1]

    verts, tris, colours = bt.read_obj(obj)
    face = bt.load_face(obj)
    verts = bt.normalise(verts)
    vnormals = bt.vertex_normals(verts, tris)
    os.makedirs(folder, exist_ok=True)
    for i in range(frames):
        # Start at a half turn: the bake begins at the avatar's back, so this
        # opens the set facing the player.
        yaw = math.pi + 2.0 * math.pi * i / frames
        rgba = bt.render(verts, tris, colours, vnormals, yaw, width, height, face=face)
        bt.write_png(os.path.join(folder, "frame_%02d.png" % i), rgba)
    os.remove(obj)
    return None


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("pack")
    ap.add_argument("clip")
    ap.add_argument("description")
    ap.add_argument("--categories", default="40_shirt,20_pants,30_shoes")
    ap.add_argument("--catalog", default=os.path.join(HERE, "asset_catalog.json"))
    ap.add_argument("--outdir", default=os.path.join(os.path.dirname(HERE), "assets", "3d", "turntable"))
    ap.add_argument("--frames", type=int, default=6)
    ap.add_argument("--width", type=int, default=192)
    ap.add_argument("--height", type=int, default=288)
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()

    wanted = set(args.categories.split(","))
    with open(args.catalog, "r", encoding="utf-8") as fh:
        catalog = json.load(fh)["assets"]

    items = []
    for record in catalog:
        category = (record.get("metadata") or {}).get("category")
        if category in wanted and record.get("vertices"):
            # Categories outside the stock three (hats, hair, glasses) are worn on
            # top of the whole stock outfit rather than replacing part of it.
            items.append((record["name"], CATEGORY_KIND.get(category)))
    if args.limit:
        items = items[:args.limit]
    print("%d items to bake" % len(items))

    done = skipped = failed = 0
    for name, kind in items:
        folder = os.path.join(args.outdir, slug(name))
        if os.path.isdir(folder) and any(f.startswith("frame_") for f in os.listdir(folder)):
            skipped += 1
            continue
        error = bake_one(args.pack, args.clip, args.description, name, kind, folder,
                         args.frames, args.width, args.height)
        if error:
            failed += 1
            print("  failed %s: %s" % (name, error))
            continue
        done += 1
        if done % 10 == 0:
            print("  %d baked" % done)

    print("baked %d, skipped %d, failed %d into %s"
          % (done, skipped, failed, args.outdir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
