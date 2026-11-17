"""Ask every animation in the pack the same question: does it curl the fingers?

The hands in the bakes are wrong, and hand-authored curl angles are a guess. If
one of the pack's own clips closes a hand properly, then the decoder is right and
the idle clip is simply the wrong source for a standing avatar; if none of them
does, the hand pose is stored somewhere else and hand-tuning was never going to
find it.

For each clip this prints the mean bend at the knuckles (180 = perfectly
straight) over the four fingers of both hands, at a few frames across the clip.

    python3 scan_clips.py PACK
    python3 scan_clips.py PACK --frames 0,10,40
"""

import argparse
import json
import math
import os
import sys

import avatar_mesh as am
import avatar_pose as ap
import skeleton_nxe as sk

HERE = os.path.dirname(os.path.abspath(__file__))


def finger_chains(joints):
    """(knuckle, middle, tip) for each finger of each hand."""
    out = []
    for wrist in ap.WRIST_JOINTS:
        for root, info in enumerate(joints):
            if info["parent"] != wrist:
                continue
            # Skip the helper joints that sit on the wrist itself.
            if _distance_to_wrist(joints, wrist, root) < 0.03:
                continue
            kids = [i for i, j in enumerate(joints) if j["parent"] == root]
            if not kids:
                continue
            mid = kids[0]
            tips = [i for i, j in enumerate(joints) if j["parent"] == mid]
            if tips:
                out.append((root, mid, tips[0]))
    return out


def _distance_to_wrist(joints, wrist, joint):
    a = joints[wrist]["position"]
    b = joints[joint]["position"]
    return math.sqrt(sum((a[i] - b[i]) ** 2 for i in range(3)))


def bend_degrees(a, b, c):
    u = [b[i] - a[i] for i in range(3)]
    v = [c[i] - b[i] for i in range(3)]
    nu = math.sqrt(sum(x * x for x in u))
    nv = math.sqrt(sum(x * x for x in v))
    if nu < 1e-9 or nv < 1e-9:
        return 180.0
    dot = sum(u[i] * v[i] for i in range(3)) / (nu * nv)
    return math.degrees(math.acos(max(-1.0, min(1.0, dot))))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("pack")
    parser.add_argument("--frames", default="0,10,40")
    parser.add_argument("--catalog", default=os.path.join(HERE, "avatar-assets.json"))
    args = parser.parse_args()

    frames = [int(v) for v in args.frames.split(",")]
    joints = sk.read_skeleton()
    chains = finger_chains(joints)
    index = am.load_pack_index(args.pack)
    with open(args.catalog, "r", encoding="utf-8") as fh:
        names = [a["name"] for a in json.load(fh)["assets"]]

    print("%d finger chains per hand set" % len(chains))
    rows = []
    for name in names:
        if "animation" not in name.lower():
            continue
        blob = am.asset_bytes(args.pack, index, name)
        blocks = [b for b in am.strb_blocks(blob) if b[0] == 1]
        if not blocks:
            continue
        values = []
        for frame in frames:
            try:
                poses, total = ap.read_animation_poses(blocks[0][3], frame)
            except SystemExit:
                break
            points = ap.posed_joint_positions(joints, poses)
            bends = [bend_degrees(points[a], points[b], points[c])
                     for a, b, c in chains]
            if bends:
                values.append((sum(bends) / len(bends), max(bends)))
        if not values:
            continue
        worst = max(v[0] for v in values)
        rows.append((worst, name, values))
    rows.sort(reverse=True)
    print("%-42s %s" % ("clip", " ".join("f%-2d" % f for f in frames)))
    for worst, name, values in rows:
        cells = " ".join("%4.1f" % v[0] for v in values)
        print("%-42s %s" % (name, cells))
    return 0


if __name__ == "__main__":
    sys.exit(main())
