"""Bake 2D overlay plates for the face categories.

The wardrobe's face items are not meshes and not body plates: they are UV sheets
painted onto the head's material - eyes, beards, face paint. That is why the 2D
layer stack leaves `15_face`, `16_face-paint` and `45_facial-hair` out, and why a
pack avatar in 2D has a bare face while the 3D sets have eyes and a mouth.

The overlay is recovered by difference: render the head twice, once with the stock
face and once with the item applied, and keep only the pixels the item changed.
Both renders are the same geometry in the same frame, so the difference is exactly
the painted area - no guessing at positions, and nothing drawn that the sheet does
not paint.

    python3 bake_pack_face.py PACK CLIP DESCRIPTION \
        --categories 15_face,16_face-paint,45_facial-hair
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
import pack_clip
from bake_pack_thumbs import slug
from bake_pack_turntables import DECAL_SETS, HAIR_COLOUR, HAIR_TINT, read_rgba

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(os.path.dirname(HERE), "pack_art")
# Per process: runs for the three categories go at once, and one cleaning up a
# shared directory took the others' clip and objects with it.
WORK = tempfile.mkdtemp(prefix="face_plate_")
# The stock face the comparison starts from, the same default the 3D bake uses.
FACE_DEFAULT = ("Straight Eyebrows", "Happy Eyes", "Smirk Mouth")
# The item that *is* the stock face cannot be recovered by difference against it:
# the two renders are the same picture and every pixel is unchanged, so that one
# plate came out empty. It is compared against this other eye instead, which
# differs only in the iris - exactly what that plate should carry.
FACE_ALTERNATE = "Sharp Eyes"
# A sheet's edge is antialiased, so the difference fades out rather than stopping.
# Below LO is rounding noise and stays clear, above HI is paint at full alpha, and
# in between the plate keeps a soft edge - a hard cutoff drew a faint rectangular
# fringe around the eyes at the sheet's own border.
LO, HI = 6.0 / 255.0, 24.0 / 255.0


def bake_head(pack, clip, description, face_arg, out):
    args = [sys.executable, os.path.join(HERE, "bake_avatar.py"), pack, clip, "0", out,
            "--colours=" + description, "--hair=" + HAIR_COLOUR, face_arg, "Head"]
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode != 0 or not os.path.exists(out):
        raise RuntimeError((result.stderr.strip().splitlines() or ["bake_avatar failed"])[-1])
    return out


def render_head(pack, clip, description, face_arg, centre, height, width, height_px,
                decal=None):
    obj = bake_head(pack, clip, description, face_arg, os.path.join(WORK, "head.obj"))
    verts, tris, colours = bt.read_obj(obj)
    face = bt.load_face(obj)
    if decal is not None and face is not None and "uvsets" in face:
        decal_set, is_mask, category, asset = decal
        sheet = os.path.join(ART, category, slug(asset) + ".png")
        spec = {"uvs": face["uvsets"][:, :, decal_set, :], "texture": read_rgba(sheet)}
        if is_mask:
            spec["tint"] = np.power(np.array(HAIR_TINT, dtype=np.float64), 2.2)
        face = dict(face)
        face["decals"] = [spec]
    verts = (verts - centre) / height
    vnormals = bt.vertex_normals(verts, tris)
    return bt.render(verts, tris, colours, vnormals, math.pi, width, height_px, face=face)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("pack")
    ap.add_argument("clip")
    ap.add_argument("description")
    ap.add_argument("--categories", default="15_face,16_face-paint,45_facial-hair")
    ap.add_argument("--catalog", default=os.path.join(HERE, "asset_catalog.json"))
    ap.add_argument("--outdir", default=os.path.join(os.path.dirname(HERE), "pack_plates"))
    ap.add_argument("--width", type=int, default=256)
    ap.add_argument("--height", type=int, default=384)
    ap.add_argument("--clip-asset", default="")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()

    os.makedirs(WORK, exist_ok=True)
    clip = pack_clip.resolve(args.pack, args.clip, args.clip_asset, WORK)

    wanted = set(args.categories.split(","))
    with open(args.catalog, "r", encoding="utf-8") as fh:
        catalog = json.load(fh)["assets"]
    items = []
    for record in catalog:
        category = (record.get("metadata") or {}).get("category")
        if category in wanted:
            items.append((record["name"], category))

    # The frame every other plate is drawn in: the body with its head.
    import bake_pack_plates as bp
    centre, height = bp.reference_frame(args.pack, clip, args.description)

    default_arg = "--face"
    source = render_head(args.pack, clip, args.description, default_arg,
                         centre, height, args.width, args.height)

    baked = skipped = failed = 0
    for name, category in items:
        folder = os.path.join(args.outdir, category)
        path = os.path.join(folder, slug(name) + ".png")
        if os.path.exists(path) and not args.force:
            skipped += 1
            continue
        if args.limit and baked >= args.limit:
            break
        try:
            if category == "15_face":
                if "nose" in name.lower():
                    # The nose sheets have no UV set of their own; see CATALOG.md.
                    failed += 1
                    continue
                painted = render_head(args.pack, clip, args.description,
                                      "--face=Straight Eyebrows,%s,Smirk Mouth" % name,
                                      centre, height, args.width, args.height)
            else:
                decal_set, is_mask = DECAL_SETS[category]
                painted = render_head(args.pack, clip, args.description, default_arg,
                                      centre, height, args.width, args.height,
                                      decal=(decal_set, is_mask, category, name))
        except Exception as exc:                                # noqa: BLE001
            failed += 1
            print("  failed %s: %s" % (name, exc))
            continue

        # Keep only what the item changed: same geometry, same frame, so the
        # difference is the sheet's own painting and nothing else.
        base = source
        if category == "15_face" and name == FACE_DEFAULT[1]:
            base = render_head(args.pack, clip, args.description,
                               "--face=%s,%s,%s" % (FACE_DEFAULT[0], FACE_ALTERNATE,
                                                    FACE_DEFAULT[2]),
                               centre, height, args.width, args.height)
        diff = np.abs(painted[..., :3] - base[..., :3]).max(axis=2)
        alpha = np.clip((diff - LO) / (HI - LO), 0.0, 1.0) * painted[..., 3]
        changed = alpha > 0.0
        if not changed.any():
            failed += 1
            print("  failed %s: the sheet changed nothing" % name)
            continue
        plate = np.zeros_like(painted)
        plate[..., :3] = painted[..., :3]
        plate[..., 3] = alpha
        os.makedirs(folder, exist_ok=True)
        bt.write_png(path, plate)
        baked += 1
        if baked % 10 == 0:
            print("  %d baked" % baked)

    shutil.rmtree(WORK, ignore_errors=True)
    print("baked %d, skipped %d, failed %d into %s"
          % (baked, skipped, failed, args.outdir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
