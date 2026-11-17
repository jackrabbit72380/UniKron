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
# The two seeds are the two .Avatar descriptors: Avatar6400 (male) dresses in the
# male seed below, Avatar6404 (female) in the female one. Both come from the
# descriptor's look block, not from a guess (see CATALOG.md).
STOCK = {"shirts": "Jacket with Sweater",
         "pants": "Male Flower Print Flares",
         "shoes": "Grunge Trainers"}
STOCK_FEMALE = {"shirts": "Sweater with Shirt",
                "pants": "Formal Trouser Suit",
                "shoes": "Female Jelly Clogs"}
HAIR = "Left Parting"
HAIR_FEMALE = "Shaved Pattern"
BODY_FOR = {"male": "MaleBody", "female": "FemaleBody"}
GENDERS_JSON = os.path.join(HERE, "pack_genders.json")
HAIR_COLOUR = "6e5326"
# Which head UV set a decal sheet is painted through, established by
# probe_decal_render.py: facial hair on set 1 (and it is a tint mask, red marks
# the hair), face paint on set 0 (its own colours). See DECALS.md.
# Which UV set of the head each decal sheet paints through, and whether the sheet
# is a mask tinted with the avatar's colour or a colour sheet used as drawn.
#
# The eye-shadow sheets are filed under 50_hair but they paint the head. Probe run
# on eye-shadow-001.png across all six sets, measuring where each set puts the
# sheet (y as a fraction of the frame, x across it):
#
#     set 0  y 0.28..0.55  wide      forehead      - face paint
#     set 1  y 0.68..0.91            jaw and chin  - facial hair
#     set 2  y 0.40..0.50            brow band     - brow
#     set 3  y 0.51..0.58  narrow    lashes only   - eye
#     set 4  y 0.76..0.82            mouth         - mouth
#     set 5  y 0.50..0.59  x 0.32..0.70  brackets the eye band, wider than the
#                                     lash sheet: the eyelid wash
#
# So eye shadow is set 5, and its sheet carries the mask in alpha (red is 1.0
# everywhere), which the renderer already multiplies.
DECAL_SETS = {"45_facial-hair": (1, True), "16_face-paint": (0, False),
              "eye-shadow": (5, True)}
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
                 "50_hair": "hair",
                 # Brows are the first of the same three masks: the item replaces
                 # the brow sheet and the eye and mouth sheets stay stock.
                 "10_body": "brow"}


def read_rgba(path):
    from PIL import Image
    return np.asarray(Image.open(path).convert("RGBA"), dtype=np.float64) / 255.0


def bake_one(pack, clip, description, asset, kind, folder, frames, width, height,
             category=None, gender="male"):
    # Per process: two bakes at once were deleting each other's objects.
    obj = os.path.join(WORK, slug(asset) + ".obj")
    stock = STOCK_FEMALE if gender == "female" else STOCK
    hair = HAIR_FEMALE if gender == "female" else HAIR
    if kind == "dress":
        worn = [stock["shoes"]]
    else:
        worn = [stock[k] for k in ("shirts", "pants", "shoes") if k != kind]
    head = [BODY_FOR[gender], "Head"] + ([] if kind == "hair" else [hair])
    # A shape is not a worn asset: it rewrites the head's vertices before skinning,
    # so it goes to --shape and nothing is added to the parts list.
    shape_args = []
    if kind == "shape":
        parts = head + worn
        shape_args = ["--shape=" + asset]
    else:
        parts = head + [asset] + worn
    face_arg = "--face"
    if kind == "eyes":
        face_arg = "--face=Straight Eyebrows,%s,Smirk Mouth" % asset
    elif kind == "brow":
        face_arg = "--face=%s,Happy Eyes,Smirk Mouth" % asset
    result = subprocess.run(
        [sys.executable, os.path.join(HERE, "bake_avatar.py"), pack, clip, "0", obj,
         "--colours=" + description, "--hair=" + HAIR_COLOUR, face_arg] + shape_args + parts,
        capture_output=True, text=True)
    if result.returncode != 0 or not os.path.exists(obj):
        return "bake_avatar: " + (result.stderr.strip().splitlines() or ["failed"])[-1]

    verts, tris, colours = bt.read_obj(obj)
    face = bt.load_face(obj)
    if kind == "decal" and face is not None and "uvsets" in face:
        decal_set, is_mask = DECAL_SETS[category]
        # The sheet stays in the folder the pack files it in (50_hair for the eye
        # shadows), so only the UV-set key is remapped.
        sheet_category = "50_hair" if category == "eye-shadow" else category
        sheet = os.path.join(ART, sheet_category, slug(asset) + ".png")
        if not os.path.exists(sheet):
            return "no decal sheet for " + asset
        spec = {"uvs": face["uvsets"][:, :, decal_set, :], "texture": read_rgba(sheet)}
        if is_mask:
            tint = HAIR_TINT
            if category == "eye-shadow":
                # Tinting the shadow with the hair colour made it vanish into the
                # skin. It is drawn in the avatar's own eye-shadow slot.
                import bake_avatar
                # Not `colours`: that name already holds the mesh's vertex
                # colours, and rebinding it fed a dict to the renderer.
                desc_colours, _ = bake_avatar.read_description(description)
                tint = tuple(c / 255.0 for c in desc_colours["eye shadow"])
            spec["tint"] = np.power(np.array(tint, dtype=np.float64), 2.2)
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
    ap.add_argument("--shapes", action="store_true",
                    help="also bake the block-4 facial shapes (chin, nose, ears)")
    ap.add_argument("--only", default="",
                    help="bake only items whose retail name contains this, ignoring case")
    ap.add_argument("--start", type=int, default=0,
                    help="skip the first N items, to run a long rebake in chunks")
    ap.add_argument("--force", action="store_true", help="rebake sets that exist")
    ap.add_argument("--clip-asset", default="",
                    help="pose from this animation asset inside the pack instead "
                         "of the clip file (the idles give natural hands)")
    ap.add_argument("--gender", choices=("male", "female"), default="male",
                    help="pose on this body and only bake items the pack marks "
                         "for it (pack_genders.json; 'both' items are baked twice)")
    args = ap.parse_args()

    wanted = set(args.categories.split(","))
    with open(args.catalog, "r", encoding="utf-8") as fh:
        catalog = json.load(fh)["assets"]

    with open(GENDERS_JSON, "r", encoding="utf-8") as fh:
        genders = json.load(fh)

    items = []
    for record in catalog:
        category = (record.get("metadata") or {}).get("category")
        tagged = (genders.get(record["name"]) or {}).get("gender", "both")
        if tagged not in (args.gender, "both"):
            continue
        # Decal and eye categories have a texture and no mesh, so they pass on
        # their own; the base body and head are never stage variants.
        has_mesh = bool(record.get("vertices"))
        if record["name"] in BASE_ASSETS:
            continue
        if category == "15_face" and "nose" in record["name"].lower():
            # The nose sheets go somewhere else entirely; dropping one into the
            # eye slot would put a nose on each eyeball.
            continue
        # 10_body holds the brow sheets next to the bodies; only a brow can take
        # the brow slot of the three face masks.
        if CATEGORY_KIND.get(category) == "brow" and "brow" not in record["name"].lower():
            continue
        # The catalog spells it "Eye shadow 001"; the slug is the file stem.
        decal_key = "eye-shadow" if slug(record["name"]).startswith("eye-shadow") else category
        if category in wanted and (has_mesh or decal_key in DECAL_SETS
                                   or CATEGORY_KIND.get(category) in ("eyes", "brow")
                                   or category == "15_face"):
            # Categories outside the stock three (hats, hair, glasses) are worn on
            # top of the whole stock outfit rather than replacing part of it.
            items.append((record["name"], CATEGORY_KIND.get(category), decal_key))
    if args.shapes:
        # The decoded block-4 overrides that move the head. The other entries in
        # the same block are clothing hiding/target templates, which are not
        # faces and are not stage variants.
        with open(os.path.join(HERE, "pack_audit.json"), "r", encoding="utf-8") as fh:
            audit = json.load(fh)["shape_override_assets"]
        faces = [n for n in audit
                 if not n.endswith("Template") and n.split()[-1] in ("Chin", "Nose", "Ears")]
        items.extend((n, "shape", "shape") for n in faces)
    if args.only:
        items = [it for it in items if args.only.lower() in it[0].lower()]
    if args.start:
        items = items[args.start:]
    print("%d items to bake" % len(items))

    import pack_clip
    clip = pack_clip.resolve(args.pack, args.clip, args.clip_asset, "/tmp")
    if clip != args.clip:
        print("posing from pack asset %r" % args.clip_asset)

    done = skipped = failed = 0
    for name, kind, category in items:
        # The eye shadows are filed with the hairstyles; the decal key is what
        # says they paint the head instead.
        if category in DECAL_SETS and category != "45_facial-hair" and category != "16_face-paint":
            kind = "decal"
        elif category == "shape":
            kind = "shape"
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
                         args.frames, args.width, args.height, category=category,
                         gender=args.gender)
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
