#!/usr/bin/env python3
"""Bake an animated 3D set: yaw angles crossed with poses from a real clip.

    python3 bake_animated.py PACK CLIP DESCRIPTION OUTDIR [--poses 6] [--yaws 8]

    python3 bake_animated.py \\
        ../../../src_archive/XBOX_HUB/resources/editors/nxe2008/assets/AvatarAssetPack.toc \\
        ../../../src_archive/.../clip-Male.bin \\
        ../../../src_archive/.../Avatar6400.Avatar \\
        ../assets/3d/animated

The static turntable (`bake_outfits.py`) bakes one pose across 20 yaw angles,
which is why 3D mode reads as a still picture while it turns. This bakes both
axes so the stage can rotate and animate at once: `--poses` frames sampled evenly
across the clip, each rendered at `--yaws` angles, written as

    yaw_00_pose_00.png ... yaw_07_pose_05.png

AvatarStage3D probes those names, drives yaw from its spin timer and pose from a
second timer, and falls back to the `frame_XX.png` set when they are absent.
Poses come from a real clip rather than an invented sway: the pack's
`Male Idle Shifts Weight` is 242 frames of standing weight shifts.

The pose is the default look from outfits.json (skin and hair colours from the
avatar description); hairstyle-specific animated sets are not baked, so a player
who picks a different hairstyle falls back to the static turntable.
"""
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CLOTHES = ["Male Power Tee", "Worn Jeans", "Formal Shoes"]


def padded(value):
    return ("0" if value < 10 else "") + str(value)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a.lstrip("-").split("=", 1) for a in sys.argv[1:] if a.startswith("--"))
    if len(args) < 4:
        print(__doc__)
        return 1
    pack, clip, description, outdir = args[:4]
    poses = int(opts.get("poses", 6))
    yaws = int(opts.get("yaws", 8))

    with open(os.path.join(HERE, "outfits.json"), "r", encoding="utf-8") as fh:
        spec = json.load(fh)
    look = next(v for k, v in spec.items() if not k.startswith("_"))

    sys.path.insert(0, HERE)
    import avatar_mesh as am
    import avatar_pose as ap

    with open(clip, "rb") as fh:
        blocks = [b for b in am.strb_blocks(fh.read()) if b[0] == 1]
    _, total = ap.read_animation_poses(blocks[0][3], 0)
    # Even samples across the clip, starting at 0: one full cycle of the motion.
    frames = [round(i * (total - 1) / max(poses, 1)) for i in range(poses)]

    os.makedirs(outdir, exist_ok=True)
    for stale in os.listdir(outdir):
        if stale.startswith("yaw_") and stale.endswith(".png"):
            os.remove(os.path.join(outdir, stale))

    for index, frame in enumerate(frames):
        obj = os.path.join("/tmp", "animated_pose_%02d.obj" % index)
        subprocess.run(
            [sys.executable, os.path.join(HERE, "bake_avatar.py"), pack, clip, str(frame), obj,
             "--colours=" + description, "--hair=" + look["colour"], "--face",
             "MaleBody", "Head", look["hair"]] + CLOTHES,
            check=True, stdout=subprocess.DEVNULL)
        staging = os.path.join("/tmp", "animated_pose_%02d" % index)
        shutil.rmtree(staging, ignore_errors=True)
        subprocess.run(
            [sys.executable, os.path.join(HERE, "bake_turntable.py"), obj, staging,
             "--frames", str(yaws), "--width", "448", "--height", "672"],
            check=True, stdout=subprocess.DEVNULL)
        for yaw in range(yaws):
            shutil.move(os.path.join(staging, "frame_%s.png" % padded(yaw)),
                        os.path.join(outdir, "yaw_%s_pose_%s.png" % (padded(yaw), padded(index))))
        print("  pose %d (clip frame %d of %d): %d angles" % (index, frame, total, yaws))

    size = sum(os.path.getsize(os.path.join(outdir, f)) for f in os.listdir(outdir))
    print("%d frames, %.1f KiB in %s" % (len(os.listdir(outdir)), size / 1024.0, outdir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
