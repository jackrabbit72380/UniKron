#!/usr/bin/env python3
"""Bake a 3D turntable per wardrobe shirt, so 3D follows the closet pick.

    python3 bake_shirts.py PACK CLIP DESCRIPTION OUTDIR [--frames 12]

Every wardrobe shirt stem (`tee_blue`, `hoodie_plum`, ...) is drawn from a real
pack garment tinted with the colour the 2D wardrobe draws it in, read from
`shirts_3d.json`. Pants and shoes stay on the stock look, and the hairstyle is the
seeded one, which is also the hairstyle the animated set is baked in - so the
item sets and the animated set agree on everything except the shirt.

Writes OUTDIR/<stem>/frame_00.png ... for each stem; AvatarStage3D swaps its
turntable folder to `shirts/<stem>/` when the player picks one of these.
"""
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
# The rest of the stock look: the description's outfit minus the shirt.
PANTS = "Male Flower Print Flares"
SHOES = "Grunge Trainers"
HAIR = "Left Parting"
HAIR_COLOUR = "6e5326"


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = {}
    rest = sys.argv[1:]
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

    with open(os.path.join(HERE, "shirts_3d.json"), "r", encoding="utf-8") as fh:
        spec = {k: v for k, v in json.load(fh).items() if not k.startswith("_")}

    os.makedirs(outdir, exist_ok=True)
    for stem, entry in sorted(spec.items()):
        obj = os.path.join("/tmp", "shirt_%s.obj" % stem)
        subprocess.run(
            [sys.executable, os.path.join(HERE, "bake_avatar.py"), pack, clip, "0", obj,
             "--colours=" + description, "--hair=" + HAIR_COLOUR, "--face",
             "--tint=%s=%s" % (entry["asset"], entry["colour"]),
             "MaleBody", "Head", HAIR, entry["asset"], PANTS, SHOES],
            check=True, stdout=subprocess.DEVNULL)

        target = os.path.join(outdir, stem)
        shutil.rmtree(target, ignore_errors=True)
        os.makedirs(target, exist_ok=True)
        subprocess.run(
            [sys.executable, os.path.join(HERE, "bake_turntable.py"), obj, target,
             "--frames", str(frames), "--width", "384", "--height", "576"],
            check=True, stdout=subprocess.DEVNULL)
        print("  %s -> %s (%s)" % (stem, os.path.relpath(target, HERE), entry["asset"]))

    total = sum(os.path.getsize(os.path.join(outdir, d, f))
                for d in os.listdir(outdir) if os.path.isdir(os.path.join(outdir, d))
                for f in os.listdir(os.path.join(outdir, d)))
    print("%d sets, %.1f KiB in %s" % (len(spec), total / 1024.0, outdir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
