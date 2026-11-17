"""Look at one hand, closely, from every side - and at what the rig does to it.

The bakes are framed on a whole avatar, where a hand is 40 pixels tall and every
question about it is a guess. This isolates the hand by its skin weights (not by
distance: a sphere round the wrist cuts the fingers off) and draws it from eight
angles with its own projection, so the shape can actually be seen.

    python3 show_hand.py                    # bind pose vs the idle clip
    python3 show_hand.py --yaws 12 --out /tmp/hand.png
    python3 show_hand.py --hand right
"""

import argparse
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

import avatar_mesh as am
import avatar_pose as ap
import pack_clip
import skeleton_nxe as sk

HERE = os.path.dirname(os.path.abspath(__file__))
PACK = os.path.join(HERE, "../../../src_archive/XBOX HUB/resources/editors/metro2010/assets/"
                          "AvatarAssetPack.toc")
CLIP = os.path.join(HERE, "../../../src_archive/XBOX HUB/resources/editors/metro2010/assets/"
                          "Cheer.AvatarAnimation")

HAND_JOINTS = set(range(37, 51))


def hand_mesh(pack, asset, poses, joints, side):
    """The vertices the rig itself calls hand: any influence on 37..50."""
    batch = am.read_model(am.decompress(
        [b for b in am.strb_blocks(am.asset_bytes(pack, am.load_pack_index(pack), asset))
         if b[0] == 3][0][3]))[0]
    tris = np.array(batch["indices"]).reshape(-1, 3)

    wrist = ap.WRIST_JOINTS[0 if side == "left" else 1]
    posed = ap.posed_positions([batch], joints, poses)[0]
    all_verts = np.array(posed["vertices"])
    wrist_at = np.array(ap.posed_joint_positions(joints, poses)[wrist])
    keep = []
    for i, (js, ws) in enumerate(zip(batch["joints"], batch["weights"])):
        # The palm is weighted to the wrist joint itself, not to a finger: keeping
        # only vertices the fingers touch leaves the hand as a few loose strips.
        rides_wrist = any(j == wrist and w > 0.5 for j, w in zip(js, ws))
        if rides_wrist and np.linalg.norm(all_verts[i] - wrist_at) < 0.17:
            keep.append(i)
            continue
        for j, w in zip(js, ws):
            if w > 0.15 and j in HAND_JOINTS:
                # Split the two hands by which wrist the vertex rides.
                if _nearest_wrist(batch, i, joints) == wrist:
                    keep.append(i)
                break
    keep = np.array(sorted(set(keep)))
    remap = {int(v): i for i, v in enumerate(keep)}
    sub = np.array([(remap[a], remap[b], remap[c]) for a, b, c in tris
                    if a in remap and b in remap and c in remap])
    return all_verts[keep], sub


def _nearest_wrist(batch, index, joints):
    js, ws = batch["joints"][index], batch["weights"][index]
    best, weight = None, -1.0
    for j, w in zip(js, ws):
        node, guard = j, 0
        while node not in ap.WRIST_JOINTS and guard < 16:
            parents = [k for k, info in enumerate(joints) if info["parent"] == node]
            if not parents:
                break
            node = parents[0]
            guard += 1
        if node in ap.WRIST_JOINTS and w > weight:
            best, weight = node, w
    return best


def draw(verts, tris, yaw, size, colour=(214, 171, 112)):
    """Orthographic, back-to-front, one flat colour with a little face shading."""
    c, s = math.cos(yaw), math.sin(yaw)
    rot = np.array([[c, 0.0, s], [0.0, 1.0, 0.0], [-s, 0.0, c]])
    # Centre first: the hand lives at x 0.5, so scaling on absolute coordinates
    # shrinks it to a speck in the corner.
    v = (verts - verts.mean(axis=0)) @ rot.T
    span = max(np.abs(v[:, 0]).max(), np.abs(v[:, 1]).max(), 1e-6)
    scale = size * 0.42 / span
    xy = np.stack([size * 0.5 + v[:, 0] * scale, size * 0.5 - v[:, 1] * scale], axis=1)

    order = np.argsort(v[tris][:, :, 2].mean(axis=1))
    img = Image.new("RGB", (size, size), (246, 249, 252))
    pen = ImageDraw.Draw(img)
    light = np.array([0.35, 0.5, 0.79])
    light = light / np.linalg.norm(light)
    for index in order:
        a, b, d = tris[index]
        p0, p1, p2 = verts[a], verts[b], verts[d]
        n = np.cross(p1 - p0, p2 - p0)
        length = np.linalg.norm(n)
        if length < 1e-12:
            continue
        n = n / length
        shade = 0.55 + 0.45 * max(0.0, abs(float(n @ light)))
        fill = tuple(int(min(255, ch * shade)) for ch in colour)
        pen.polygon([tuple(xy[a]), tuple(xy[b]), tuple(xy[d])], fill=fill)
    return img


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--yaws", type=int, default=8)
    parser.add_argument("--size", type=int, default=260)
    parser.add_argument("--hand", choices=("left", "right"), default="left")
    parser.add_argument("--out", default=os.path.join(HERE, "hand_sides.png"))
    parser.add_argument("--clip-asset", default="Animation Male Idle Shifts Weight")
    parser.add_argument("--frame", type=int, default=0)
    args = parser.parse_args()

    joints = sk.read_skeleton()
    clip = pack_clip.resolve(PACK, CLIP, args.clip_asset, "/tmp")
    poses, total = ap.read_animation_poses(
        [b for b in am.strb_blocks(open(clip, "rb").read()) if b[0] == 1][0][3], args.frame)

    rows = []
    for label, use in (("bind", None), ("clip", poses)):
        ps = [((0.0, 0.0, 0.0), (0.0, 0.0, 0.0, 1.0), (1.0, 1.0, 1.0))] * len(joints) if use is None else use
        verts, tris = hand_mesh(PACK, "MaleBody", ps, joints, args.hand)
        grid = Image.new("RGB", (args.size * 4, args.size * math.ceil(args.yaws / 4)),
                         (255, 255, 255))
        for k in range(args.yaws):
            tile = draw(verts, tris, math.pi * 2 * k / args.yaws, args.size)
            grid.paste(tile, ((k % 4) * args.size, (k // 4) * args.size))
        rows.append(grid)
        print("%s: %d vertices, %d triangles" % (label, len(verts), len(tris)))

    out = Image.new("RGB", (rows[0].width, sum(r.height for r in rows)), (255, 255, 255))
    y = 0
    for row in rows:
        out.paste(row, (0, y))
        y += row.height
    out.save(args.out)
    print("clip %s: %d frames -> %s" % (args.clip_asset, total, args.out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
