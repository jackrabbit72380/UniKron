"""Split the eye sheets into the part a colour owns: the iris.

An eye sheet is not like the brow or the mouth. One sheet paints the iris *and* the
sclera, and only the iris takes the descriptor's eye colour - the whites are a fixed
near-white (`bake_turntable.render`: sclera 0.90/0.90/0.93, iris = the sheet's R zone
times the slot-3 colour). A single coverage mask (`bake_pack_face.py --mask`,
`15_face/`) therefore cannot be tinted: multiplying it by a palette colour paints the
whites too. That is why the eye screen was left unpainted in COLOURS.md.

**Where the iris is** is measured, not assumed. The same sheet is rendered three times
- eye colour white, pure red, pure green (descriptor slot 3), nothing else changed. The
pixels that move between the red and the green render are the ones the eye colour
reaches. On "Happy Eyes" that is 88 pixels in the box x 114-143, y 72-81: the two
irises, and not one pixel of the whites or the lash line.

**What the iris looks like under a colour** is two terms, not one. The renderer shades
`albedo * light` and adds a specular term, and on the eye the specular is a fifth to a
quarter of the pixel - so a mask that is only `light` reproduces the plate badly
(measured on the 51 iris pixels of "Happy Eyes": mean 28.3, p95 73.2 out of 255 with
the plate's own colour, and the hue comes out grey instead of blue). The three renders
separate the two terms exactly:

    light = lin(white) - spec     spec = ( green.R, red.G, red.B )

because a tint of (0,1,0) leaves only the specular in R, and (1,0,0) only the
specular in G and B. With both terms the same plate is reproduced to mean 5.9, p95 15.8,
and the table entry `#6381a7` is the closest of the eighteen - which is the descriptor's
slot 3, independently confirming the colour the plates were baked with.

So an eye mask is **two files**: the light term and the specular term, both straight
RGB with the iris coverage in alpha. `TintedMask.qml` samples both and writes
`pow(lin(light) * lin(tint) + lin(spec), 1/2.2) * alpha`, which is the renderer's own
shading for any other eye colour.

    python3 make_eye_masks.py                 # writes 15_face_iris/ and 15_face_iris_spec/
    python3 make_eye_masks.py --check         # measure, write nothing

Runs after `bake_pack_face.py --mask` (it reads the 15_face coverage masks for the
frames that do not move) and before `make_colour_qml.py` (which indexes the new
folders for the editor).
"""

import argparse
import json
import os
import struct
import sys

import numpy as np

import bake_pack_face as bp
import bake_pack_plates as bplate
import bake_turntable as bt
import pack_clip
from bake_pack_thumbs import slug

HERE = os.path.dirname(os.path.abspath(__file__))
AVATAR = os.path.dirname(HERE)
MASK_DIR = os.path.join(AVATAR, "pack_plates_mask")
EYE_MASKS = os.path.join(MASK_DIR, "15_face")
OUT_LIGHT = os.path.join(MASK_DIR, "15_face_iris")
OUT_SPEC = os.path.join(MASK_DIR, "15_face_iris_spec")
PLATES = os.path.join(AVATAR, "pack_plates", "15_face")
DESCRIPTOR = os.path.join(HERE, "descriptors", "Avatar6400.Avatar")
CATALOG = os.path.join(HERE, "asset_catalog.json")
PACK = os.path.join(HERE, "../../../src_archive/XBOX HUB/resources/editors/"
                    "metro2010/assets/AvatarAssetPack.toc")
CLIPS = os.path.join(HERE, "../../../src_archive/XBOX HUB/resources/editors/"
                     "metro2010/assets/Cheer.AvatarAnimation")
CLIP_ASSET = "Animation Male Idle Shifts Weight"
# Descriptor slot 3 is the eye colour (bake_avatar.COLOUR_NAMES).
EYE_SLOT = 3
WHITE, RED, GREEN = 0xFFFFFF, 0xFF0000, 0x00FF00
# A moved pixel is one the eye colour reaches; the sheet's antialiased iris edge moves
# part way, which is kept as a soft edge rather than cut off.
LO, HI = 0.02, 0.25


def sheet_names():
    """slug -> the catalog's own name, for the 15_face sheets that have a mask."""
    out = {}
    for record in json.load(open(CATALOG, encoding="utf-8"))["assets"]:
        category = (record.get("metadata") or {}).get("category")
        if category == "15_face" and "nose" not in record["name"].lower():
            out[slug(record["name"]) + ".png"] = record["name"]
    return out


def description_with_eye(colour):
    blob = bytearray(open(DESCRIPTOR, "rb").read())
    struct.pack_into(">I", blob, 0x0FC + 4 * EYE_SLOT, 0xFF000000 | colour)
    out = os.path.join(bp.WORK, "eye_%06x.Avatar" % colour)
    with open(out, "wb") as fh:
        fh.write(blob)
    return out


def linear(c):
    return np.power(np.clip(c, 0.0, 1.0), 2.2)


def encode(c):
    return np.power(np.clip(c, 0.0, 1.0), 1.0 / 2.2)


def render_terms(pack, clip, centre, height, asset):
    """light, spec and the iris classification for one eye sheet."""
    face = "--face=Straight Eyebrows,%s,Smirk Mouth" % asset
    out = []
    for colour in (WHITE, RED, GREEN):
        render = bp.render_head(pack, clip, description_with_eye(colour), face,
                                centre, height, 256, 384)
        out.append(render.astype(np.float64) / 255.0)
    white, red, green = out
    # albedo*light + specular: a (1,0,0) tint leaves specular in G and B, a (0,1,0)
    # tint leaves it in R, so the three renders split the two terms without knowing
    # the renderer's light rig.
    spec = np.stack([linear(green[..., :3])[..., 0],
                     linear(red[..., :3])[..., 1],
                     linear(red[..., :3])[..., 2]], axis=-1)
    light = np.clip(linear(white[..., :3]) - spec, 0.0, 1.0)
    moved = np.abs(red[..., :3] - green[..., :3]).max(axis=2)
    iris = np.clip((moved - LO) / (HI - LO), 0.0, 1.0) * white[..., 3]
    return light, spec, iris


def check(plate, light, spec, iris, hexes):
    """Least-squares residual of the two-term model against the baked plate."""
    sel = iris > 0.8
    if not sel.any():
        return None
    rows = []
    for name, hexcol in hexes:
        c = linear(np.array([int(hexcol[i:i + 2], 16) / 255.0 for i in (1, 3, 5)]))
        pred = encode(c * light + spec)
        err = np.abs(pred - plate[..., :3])[sel].mean() * 255.0
        rows.append((float(err), name, hexcol))
    rows.sort()
    return rows


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="measure only, write nothing")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--plate", default="happy-eyes.png",
                    help="the plate the residual is quoted for")
    args = ap.parse_args()

    if not os.path.isdir(EYE_MASKS):
        raise SystemExit("missing %s - run bake_pack_face.py --mask --categories "
                         "15_face first" % EYE_MASKS)
    names = sheet_names()
    masks = sorted(f for f in os.listdir(EYE_MASKS) if f.endswith(".png"))
    if not masks:
        raise SystemExit("%s is empty" % EYE_MASKS)

    palettes = json.load(open(os.path.join(AVATAR, "colour_palettes.json")))
    eye = [(s["slot"], "#" + c[-6:]) for s in palettes["slots"] if s["slot"] == "eye"
           for c in s["colours"]]
    eye_table = [hexcol for _, hexcol in eye]

    clip = pack_clip.resolve(PACK, CLIPS, CLIP_ASSET, bp.WORK)
    centre, height = bplate.reference_frame(PACK, clip, DESCRIPTOR)
    if not args.check:
        os.makedirs(OUT_LIGHT, exist_ok=True)
        os.makedirs(OUT_SPEC, exist_ok=True)

    done = skipped = 0
    total_iris = 0
    for name in masks:
        if args.limit and done >= args.limit:
            break
        asset = names.get(name)
        if asset is None:
            skipped += 1
            print("  skip %s: no 15_face record" % name)
            continue
        light, spec, iris = render_terms(PACK, clip, centre, height, asset)
        pixels = int((iris > 0.25).sum())
        if pixels < 8:
            skipped += 1
            print("  skip %s: the eye colour reaches %d pixels" % (name, pixels))
            continue
        total_iris += pixels
        if not args.check:
            # Straight RGB with the iris coverage in alpha, which is what
            # TintedMask.qml expects of every mask.
            for folder, term in ((OUT_LIGHT, light), (OUT_SPEC, spec)):
                rgba = np.zeros(iris.shape + (4,), dtype=np.uint8)
                rgba[..., :3] = (encode(term) * 255.0).round().astype(np.uint8)
                rgba[..., 3] = (iris * 255.0).round().astype(np.uint8)
                bt.write_png(os.path.join(folder, name), rgba)
        done += 1
        if done % 10 == 0:
            print("  %d done" % done)

    line = "%s %d eye masks (%d iris px), skipped %d -> %s, %s" % (
        "measured" if args.check else "wrote", done, total_iris, skipped,
        os.path.relpath(OUT_LIGHT, AVATAR), os.path.relpath(OUT_SPEC, AVATAR))
    print(line)

    # The residual is worth printing on every run: it is the only number that says
    # the two terms still describe the shipped plate.
    plate_path = os.path.join(PLATES, args.plate)
    if os.path.exists(plate_path):
        plate = bt.read_png(plate_path)
        asset = names.get(args.plate)
        light, spec, iris = render_terms(PACK, clip, centre, height, asset)
        rows = check(plate, light, spec, iris, [("eye", c) for c in eye_table])
        if rows:
            stock = next((r for r in rows if r[2].lower() == "#6381a7"), None)
            print("residual on %s over %d iris px: best %.2f (%s)%s"
                  % (args.plate, int((iris > 0.8).sum()), rows[0][0], rows[0][2],
                     "  stock #6381a7 %.2f" % stock[0] if stock else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
