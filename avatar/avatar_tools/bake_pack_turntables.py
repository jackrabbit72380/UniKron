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
import tempfile

import numpy as np

import avatar_mesh as am
import bake_turntable as bt
from bake_pack_thumbs import slug

HERE = os.path.dirname(os.path.abspath(__file__))
WORK = tempfile.mkdtemp(prefix="pack_tt_")
STOCK = {"shirts": "Jacket with Sweater",
         "pants": "Male Flower Print Flares",
         "shoes": "Grunge Trainers"}
HAIR = "Left Parting"
HAIR_COLOUR = "6e5326"
# Which head UV set a decal sheet is painted through, established by
# probe_decal_render.py: facial hair on set 1 (and it is a tint mask, red marks
# the hair), face paint on set 0 (its own colours). See DECALS.md.
DECAL_SETS = {"45_facial-hair": (1, True), "16_face-paint": (0, False)}
HAIR_TINT = (0x6E / 255.0, 0x53 / 255.0, 0x26 / 255.0)
ART = os.path.join(os.path.dirname(HERE), "pack_art")
BASE_ASSETS = {"MaleBody", "FemaleBody", "Head"}

CATEGORY_KIND = {"40_shirt": "shirts", "20_pants": "pants", "30_shoes": "shoes",
                 "45_facial-hair": "decal", "16_face-paint": "decal",
                 # The pack's eye sheets replace the middle mask of the three
                 # bake_avatar builds (brow, eye, mouth), keeping the other two.
                 "15_face": "eyes",
                 # A dress or a suit covers the torso and legs at once, so only the
                 # shoes are kept underneath.
                 "80_dress": "dress", "81_formal": "dress", "83_dress-formal": "dress",
                 # Picking a hairstyle takes the stock one off.
                 "50_hair": "hair"}


def read_rgba(path):
    from PIL import Image
    return np.asarray(Image.open(path).convert("RGBA"), dtype=np.float64) / 255.0


def bake_one(pack, clip, description, asset, kind, folder, frames, width, height,
             category=None):
    # Per process: two bakes at once were deleting each other's objects.
    obj = os.path.join(WORK, slug(asset) + ".obj")
    if kind == "dress":
        worn = [STOCK["shoes"]]
    else:
        worn = [STOCK[k] for k in ("shirts", "pants", "shoes") if k != kind]
    head = ["MaleBody", "Head"] + ([] if kind == "hair" else [HAIR])
    parts = head + [asset] + worn
    face_arg = "--face"
    if kind == "eyes":
        face_arg = "--face=Straight Eyebrows,%s,Smirk Mouth" % asset
    result = subprocess.run(
        [sys.executable, os.path.join(HERE, "bake_avatar.py"), pack, clip, "0", obj,
         "--colours=" + description, "--hair=" + HAIR_COLOUR, face_arg] + parts,
        capture_output=True, text=True)
    if result.returncode != 0 or not os.path.exists(obj):
        return "bake_avatar: " + (result.stderr.strip().splitlines() or ["failed"])[-1]

    verts, tris, colours = bt.read_obj(obj)
    face = bt.load_face(obj)
    if kind == "decal" and face is not None and "uvsets" in face:
        decal_set, is_mask = DECAL_SETS[category]
        sheet = os.path.join(ART, category, slug(asset) + ".png")
        if not os.path.exists(sheet):
            return "no decal sheet for " + asset
        spec = {"uvs": face["uvsets"][:, :, decal_set, :], "texture": read_rgba(sheet)}
        if is_mask:
            spec["tint"] = np.power(np.array(HAIR_TINT, dtype=np.float64), 2.2)
        else:
            spec["tint"] = None
        if spec["tint"] is None:
            del spec["tint"]
        face = dict(face)
        face["decals"] = [spec]
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
    ap.add_argument("--start", type=int, default=0,
                    help="skip the first N items, to run a long rebake in chunks")
    ap.add_argument("--force", action="store_true", help="rebake sets that exist")
    ap.add_argument("--clip-asset", default="",
                    help="pose from this animation asset inside the pack instead "
                         "of the clip file (the idles give natural hands)")
    args = ap.parse_args()

    wanted = set(args.categories.split(","))
    with open(args.catalog, "r", encoding="utf-8") as fh:
        catalog = json.load(fh)["assets"]

    items = []
    for record in catalog:
        category = (record.get("metadata") or {}).get("category")
        # Decal and eye categories have a texture and no mesh, so they pass on
        # their own; the base body and head are never stage variants.
        has_mesh = bool(record.get("vertices"))
        if record["name"] in BASE_ASSETS:
            continue
        if category == "15_face" and "nose" in record["name"].lower():
            # The nose sheets go somewhere else entirely; dropping one into the
            # eye slot would put a nose on each eyeball.
            continue
        if category in wanted and (has_mesh or category in DECAL_SETS
                                   or category == "15_face"):
            # Categories outside the stock three (hats, hair, glasses) are worn on
            # top of the whole stock outfit rather than replacing part of it.
            items.append((record["name"], CATEGORY_KIND.get(category), category))
    if args.start:
        items = items[args.start:]
    print("%d items to bake" % len(items))

    import pack_clip
    clip = pack_clip.resolve(args.pack, args.clip, args.clip_asset, "/tmp")
    if clip != args.clip:
        print("posing from pack asset %r" % args.clip_asset)

    done = skipped = failed = 0
    for name, kind, category in items:
        # --limit caps how many are *baked*, not how many are looked at: a run
        # restarted after a timeout must still find work, and slicing the list
        # first would only re-walk the sets that already exist.
        if args.limit and done >= args.limit:
            break
        folder = os.path.join(args.outdir, slug(name))
        if (not args.force and os.path.isdir(folder)
                and any(f.startswith("frame_") for f in os.listdir(folder))):
            skipped += 1
            continue
        error = bake_one(args.pack, clip, args.description, name, kind, folder,
                         args.frames, args.width, args.height, category=category)
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
