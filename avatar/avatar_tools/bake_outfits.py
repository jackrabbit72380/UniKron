#!/usr/bin/env python3
"""Bake one turntable per hairstyle so the 3D view follows the closet choice.

    python3 bake_outfits.py PACK CLIP DESCRIPTION OUTDIR

    python3 bake_outfits.py \\
        ../../../src_archive/XBOX_HUB/resources/editors/nxe2008/assets/AvatarAssetPack.toc \\
        ../../../src_archive/.../IdleOffScreen.AvatarAnimation \\
        ../../../src_archive/.../Avatar6400.Avatar \\
        ../assets/3d/turntable

Reads outfits.json beside this file: each key is a hair art file stem in
assets/50_hair, and gets a subdirectory of OUTDIR with the same name. The first
entry is also written straight into OUTDIR, which is what the stage falls back
to when no hair is selected. Body and clothes stay the same in every set - only
the hairstyle and its colour change, because the pack stores no colour for a
stock garment (see EDITOR_BINARIES.md).

Frames are 448x672 at 20 a turn: three quarters of the old 512x768x24, which is
what makes four sets fit in the theme alongside the 2D art.
"""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
FRAMES = ["--frames", "20", "--width", "448", "--height", "672"]
CLOTHES = ["Male Power Tee", "Worn Jeans", "Formal Shoes"]


def main():
    if len(sys.argv) < 5:
        print(__doc__)
        return 1
    pack, clip, description, outdir = sys.argv[1:5]
    with open(os.path.join(HERE, "outfits.json"), "r", encoding="utf-8") as fh:
        spec = {k: v for k, v in json.load(fh).items() if not k.startswith("_")}

    for position, (key, entry) in enumerate(spec.items()):
        obj = os.path.join("/tmp", "outfit_%s.obj" % key)
        cmd = [sys.executable, os.path.join(HERE, "bake_avatar.py"), pack, clip, "0", obj,
               "--colours=" + description, "--hair=" + entry["colour"],
               "MaleBody", "Head", entry["hair"]] + CLOTHES
        subprocess.run(cmd, check=True)
        # The first entry doubles as the default set.
        targets = [os.path.join(outdir, key)]
        if position == 0:
            targets.append(outdir)
        for target in targets:
            os.makedirs(target, exist_ok=True)
            for stale in os.listdir(target):
                if stale.startswith("frame_") and stale.endswith(".png"):
                    os.remove(os.path.join(target, stale))
            subprocess.run([sys.executable, os.path.join(HERE, "bake_turntable.py"), obj, target] + FRAMES,
                           check=True)
            print("  -> %s" % os.path.relpath(target, HERE))
    return 0


if __name__ == "__main__":
    sys.exit(main())
