#!/usr/bin/env python3
"""Bake a 3D turntable per wardrobe item, so 3D follows the closet pick.

    python3 bake_items.py PACK CLIP DESCRIPTION OUTDIR [--frames 12] [--kinds=shirts,pants]

Every stem in `items_3d.json` is drawn from a real pack asset, tinted with the
colour the 2D wardrobe draws that item in. Each set replaces exactly one piece and
keeps the rest of the stock outfit (the outfit `Avatar6400.Avatar` names), because
a baked turntable cannot mix two picks - so the stage shows the stock avatar
wearing the item you last touched, which is the honest approximation.

The hairstyle is the seeded one, which is also the hairstyle the animated set is
baked in, so the item sets and the animated set agree on everything but clothes.

Writes OUTDIR/<kind>/<stem>/frame_00.png ... ; AvatarStage3D swaps its turntable
folder to `<kind>/<stem>/` for the picked item.
"""
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
# The stock outfit: what a set keeps unless the item being baked replaces it.
STOCK = {"shirts": "Jacket with Sweater",
         "pants": "Male Flower Print Flares",
         "shoes": "Grunge Trainers"}
HAIR = "Left Parting"
HAIR_COLOUR = "6e5326"


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    rest = sys.argv[1:]
    opts = {}
    for i, a in enumerate(rest):
        if not a.startswith("--"):
            continue
        if "=" in a:
            key, value = a[2:].split("=", 1)
        elif i + 1 < len(rest):
            key, value = a[2:], rest[i + 1]
        else:
            continue
        opts[key] = value
    if len(args) < 4:
        print(__doc__)
        return 1
    pack, clip, description, outdir = args[:4]
    frames = int(opts.get("frames", 12))
    wanted = opts.get("kinds", "shirts,pants,shoes").split(",")

    with open(os.path.join(HERE, "items_3d.json"), "r", encoding="utf-8") as fh:
        spec = {k: v for k, v in json.load(fh).items() if not k.startswith("_")}

    os.makedirs(outdir, exist_ok=True)
    done = 0
    for stem, entry in sorted(spec.items()):
        kind = entry["kind"]
        if kind not in wanted:
            continue
        worn = [STOCK[k] for k in ("shirts", "pants", "shoes") if k != kind]
        obj = os.path.join("/tmp", "item_%s.obj" % stem)
        subprocess.run(
            [sys.executable, os.path.join(HERE, "bake_avatar.py"), pack, clip, "0", obj,
             "--colours=" + description, "--hair=" + HAIR_COLOUR, "--face",
             "--tint=%s=%s" % (entry["asset"], entry["colour"]),
             "MaleBody", "Head", HAIR, entry["asset"]] + worn,
            check=True, stdout=subprocess.DEVNULL)

        target = os.path.join(outdir, kind, stem)
        shutil.rmtree(target, ignore_errors=True)
        os.makedirs(target, exist_ok=True)
        subprocess.run(
            [sys.executable, os.path.join(HERE, "bake_turntable.py"), obj, target,
             "--frames", str(frames), "--width", "384", "--height", "576"],
            check=True, stdout=subprocess.DEVNULL)
        done += 1
        print("  %s/%s -> %s (%s)" % (kind, stem, os.path.relpath(target, HERE), entry["asset"]))

    print("%d sets baked into %s" % (done, outdir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
