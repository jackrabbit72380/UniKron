"""The hands, close up: what the clip does to the fingers and what they look like.

The hands are the one part of the avatar that has never looked right, and the
failure has been guessing at it. This tool does two things instead:

  * prints the angle every finger joint is rotated by in the clip, so "the clip
    never moves the fingers" can be checked rather than believed;
  * renders the hand's own triangles at four yaws, once as the clip poses it and
    once with avatar_pose's authored curl on top, so the two can be compared.

  python3 probe_hand.py PACK CLIP --out hand.png
  python3 probe_hand.py PACK CLIP --asset FemaleBody --frame 0 --clip-asset "Animation Male Idle Shifts Weight"

Vertices are picked by their skin weights: anything weighted to a wrist joint or
to one of its children is part of a hand.
"""

import argparse
import math
import os
import sys

import numpy as np

import avatar_mesh as am
import avatar_pose as ap
import bake_turntable as bt
import pack_clip
import skeleton_nxe as sk

HERE = os.path.dirname(os.path.abspath(__file__))
FINGERS = tuple(ap.WRIST_JOINTS)


def quaternion_angle_degrees(q):
    """Rotation angle of a unit quaternion, degrees. Clips store deltas."""
    w = max(-1.0, min(1.0, abs(q[3])))
    return math.degrees(2.0 * math.acos(w))


def finger_joints(joints):
    """(joint, depth, side) for every finger phalanx, depth 1 at the knuckle."""
    out = []
    for wrist in FINGERS:
        kids = [i for i, j in enumerate(joints) if j["parent"] == wrist]
        for root in kids:
            out.append((root, wrist, 1))
            for mid, info in enumerate(joints):
                if info["parent"] == root:
                    out.append((mid, wrist, 2))
                    for tip, info2 in enumerate(joints):
                        if info2["parent"] == mid:
                            out.append((tip, wrist, 3))
    return out


def hand_vertices(batches, joints):
    """Per batch, the vertex indices whose weights touch a wrist or a finger."""
    fingers = {j for j, _, _ in finger_joints(joints)}
    wanted = fingers | set(FINGERS)
    out = []
    for batch in batches:
        picked = set()
        for index, names in enumerate(batch["joints"]):
            weights = batch["weights"][index]
            for j, w in zip(names, weights):
                if w > 0.0 and j in wanted:
                    picked.add(index)
                    break
        out.append(picked)
    return out


def joint_centroids(posed, batches, joints, wanted):
    """Where each wanted joint ends up: the centroid of the vertices it owns.

    The joints' own transforms say nothing about whether a finger bends (a
    twist about the finger's axis rotates the joint without moving it), so the
    bend is measured on the geometry the joint actually carries.
    """
    sums = {}
    for batch, verts in zip(batches, posed):
        for index, names in enumerate(batch["joints"]):
            weights = batch["weights"][index]
            best = max(range(len(names)), key=lambda k: weights[k]) if names else None
            if best is None or weights[best] <= 0.0:
                continue
            joint = names[best]
            if joint not in wanted:
                continue
            acc = sums.setdefault(joint, [[0.0, 0.0, 0.0], 0])
            v = verts["vertices"][index]
            for k in range(3):
                acc[0][k] += v[k]
            acc[1] += 1
    return {j: [c / n for c in sum3] for j, (sum3, n) in sums.items() if n}


def bend_degrees(a, b, c):
    """Angle at b in the chain a-b-c, degrees: 180 is straight."""
    u = [b[i] - a[i] for i in range(3)]
    v = [c[i] - b[i] for i in range(3)]
    nu = math.sqrt(sum(x * x for x in u))
    nv = math.sqrt(sum(x * x for x in v))
    if nu < 1e-9 or nv < 1e-9:
        return 0.0
    dot = sum(u[i] * v[i] for i in range(3)) / (nu * nv)
    return math.degrees(math.acos(max(-1.0, min(1.0, dot))))


def hand_mesh(posed, picked):
    """Triangles with all three corners in the hand, keeping their colours."""
    verts = []
    tris = []
    for batch, keep in zip(posed, picked):
        index_map = {}
        for i in keep:
            index_map[i] = len(verts)
            verts.append(batch["vertices"][i])
        indices = batch["indices"]
        for t in range(0, len(indices), 3):
            a, b, c = indices[t], indices[t + 1], indices[t + 2]
            if a in index_map and b in index_map and c in index_map:
                tris.append((index_map[a], index_map[b], index_map[c]))
    return np.array(verts, dtype=np.float64), np.array(tris, dtype=np.int64)


def components(verts, tris):
    """Split a submesh into connected pieces (the model has two hands)."""
    parent = list(range(len(verts)))

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for a, b, c in tris:
        ra, rb, rc = find(a), find(b), find(c)
        parent[rb] = ra
        parent[find(rc)] = ra
    groups = {}
    for index in range(len(verts)):
        groups.setdefault(find(index), []).append(index)
    out = []
    for members in groups.values():
        lookup = {old: new for new, old in enumerate(members)}
        faces = []
        for a, b, c in tris:
            if a in lookup and b in lookup and c in lookup:
                faces.append((lookup[a], lookup[b], lookup[c]))
        if faces:
            out.append((verts[members], np.array(faces, dtype=np.int64)))
    out.sort(key=lambda pair: -len(pair[0]))
    return out


def contact_sheet(images, path):
    from PIL import Image

    height = max(im.height for im in images)
    width = sum(im.width for im in images)
    sheet = Image.new("RGBA", (width, height), (246, 249, 252, 255))
    x = 0
    for im in images:
        sheet.alpha_composite(im, (x, 0))
        x += im.width
    sheet.save(path)
    return path


def render_hand(verts, tris, yaws, size, out, colours, face=None):
    from PIL import Image

    vnormals = bt.vertex_normals(verts, tris)
    tiles = []
    for yaw in yaws:
        rgba = bt.render(verts, tris, colours, vnormals, yaw, size, size, face=face)
        # render() already returns 8-bit RGBA; scaling it again washed the tiles
        # out to white, which made every hand look featureless.
        pixels = rgba if rgba.dtype == np.uint8 else \
            (np.clip(rgba, 0.0, 1.0) * 255.0).astype(np.uint8)
        tiles.append(Image.fromarray(pixels))
    return tiles


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("pack")
    parser.add_argument("clip")
    parser.add_argument("--asset", default="MaleBody")
    parser.add_argument("--frame", type=int, default=0)
    parser.add_argument("--clip-asset", default="")
    parser.add_argument("--out", default=os.path.join(HERE, "..", "hand_probe.png"))
    parser.add_argument("--size", type=int, default=200)
    args = parser.parse_args()

    clip = pack_clip.resolve(args.pack, args.clip, args.clip_asset, "/tmp")
    index = am.load_pack_index(args.pack)
    joints = sk.read_skeleton()

    payload = [b for b in am.strb_blocks(open(clip, "rb").read()) if b[0] == 1]
    poses, frames = ap.read_animation_poses(payload[0][3], args.frame)
    print("%s frame %d/%d" % (os.path.basename(clip), args.frame, frames))

    print("finger joints and the clip's rotation of each (degrees off bind):")
    for joint, wrist, depth in finger_joints(joints):
        angle = quaternion_angle_degrees(poses[joint][1]) if joint < len(poses) else 0.0
        print("  joint %2d (wrist %d, depth %d): %5.1f" % (joint, wrist, depth, angle))

    batches = []
    for block in am.strb_blocks(am.asset_bytes(args.pack, index, args.asset)):
        if block[0] == 3:
            batches += am.read_model(am.decompress(block[3]))
    picked = hand_vertices(batches, joints)
    total = sum(len(p) for p in picked)
    print("%d hand vertices of %d" % (total, sum(len(b["vertices"]) for b in batches)))
    for batch, keep in zip(batches, picked):
        if keep:
            print("  batch %d: %d of %d vertices" % (batch["shader_id"], len(keep),
                                                      len(batch["vertices"])))

    # The bind pose, for the same measurement: a zero delta on every joint.
    chains = []
    for joint, wrist, depth in finger_joints(joints):
        if depth != 2:
            continue
        kids = [i for i, info in enumerate(joints) if info["parent"] == joint]
        if kids:
            chains.append((joint, kids[0]))
    bend_joints = set(entry[0] for entry in finger_joints(joints))
    knuckle_of = {}
    for entry_joint, entry_wrist, entry_depth in finger_joints(joints):
        if entry_depth == 1:
            knuckle_of[entry_joint] = entry_joint
        else:
            parent = joints[entry_joint]["parent"]
            knuckle_of[entry_joint] = knuckle_of.get(parent, parent)
    identity = [((0.0, 0.0, 0.0), (0.0, 0.0, 0.0, 1.0), (1.0, 1.0, 1.0))] * len(joints)

    def bends_for(poses_used):
        posed = ap.posed_positions(batches, joints, poses_used)
        centres = joint_centroids(posed, batches, joints, bend_joints)
        out = {}
        for mid, tip in chains:
            root = knuckle_of.get(mid)
            if root is None or mid not in centres or tip not in centres \
                    or root not in centres:
                continue
            out[(root, mid)] = bend_degrees(centres[root], centres[mid], centres[tip])
        return out

    saved = os.environ.get("AVATAR_FINGER_POSE")
    os.environ["AVATAR_FINGER_POSE"] = "0"
    import importlib
    importlib.reload(ap)
    bind_bend = bends_for(identity)
    clip_bend = bends_for(poses)
    os.environ["AVATAR_FINGER_POSE"] = "1"
    importlib.reload(ap)
    curl_bend = bends_for(poses)
    os.environ["AVATAR_FINGER_POSE"] = "0"
    importlib.reload(ap)
    print("finger bend, straight = 180 degrees (knuckle-mid-tip):")
    for key in sorted(clip_bend):
        print("  knuckle %2d: bind %5.1f  clip %5.1f (%+.1f)  +curl %5.1f (%+.1f)"
              % (key[0], bind_bend.get(key, 0.0), clip_bend[key],
                 clip_bend[key] - bind_bend.get(key, 0.0),
                 curl_bend.get(key, 0.0),
                 curl_bend.get(key, 0.0) - bind_bend.get(key, 0.0)))
    if saved is not None:
        os.environ["AVATAR_FINGER_POSE"] = saved

    rows = []
    for label, finger_pose in (("clip", False), ("clip + curl", True)):
        os.environ["AVATAR_FINGER_POSE"] = "1" if finger_pose else "0"
        import importlib
        importlib.reload(ap)
        posed = ap.posed_positions(batches, joints, poses)
        verts, tris = hand_mesh(posed, picked)
        if len(verts) == 0:
            print("%s: no hand triangles" % label)
            continue
        hands = components(verts, tris)
        print("%s: %d hand triangles in %d pieces" % (label, len(tris), len(hands)))
        # Frame each hand on its own: two hands in one frame leaves the close-up
        # half empty and makes stray parts look like torn geometry.
        tiles = []
        for hand_verts, hand_tris in hands[:2]:
            lo = hand_verts.min(axis=0)
            hi = hand_verts.max(axis=0)
            span = max(hi[1] - lo[1], 1e-6)
            local = (hand_verts - np.array([(lo[0] + hi[0]) * 0.5, lo[1],
                                           (lo[2] + hi[2]) * 0.5])) / span
            # render() takes one colour per triangle, not per vertex.
            colours = np.tile(np.array([0.42, 0.31, 0.22]), (len(hand_tris), 1))
            tiles += render_hand(local, hand_tris,
                                 (0.0, math.pi * 0.5, math.pi, math.pi * 1.5),
                                 args.size, args.out, colours)
        rows.append(tiles)

    if rows:
        from PIL import Image

        columns = max(len(tiles) for tiles in rows)
        sheet = Image.new("RGBA", (args.size * columns, args.size * len(rows)),
                          (246, 249, 252, 255))
        for row, tiles in enumerate(rows):
            for col, tile in enumerate(tiles):
                sheet.alpha_composite(tile, (col * args.size, row * args.size))
        sheet.save(args.out)
        print("wrote %s (%d views x %d poses)" % (args.out, columns, len(rows)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
