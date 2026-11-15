#!/usr/bin/env python3
"""Assemble a posed avatar (body + head) from the asset pack, write OBJ.

The two assets are stored in different spaces, which is what kept the earlier
attempts from producing a figure:

  * MaleBody is in model space. Its vertices sit a median 0.111 from the joint
    that dominates them, and a rigid fit of vertices onto those joints is the
    identity (R ~= I, t ~= [0.04, -0.15, 0]), so it skins as W * inverse(bind).
  * Head is bone-local. Every one of its vertices is weighted to a single joint
    (joint 19), so it takes that bone's world transform directly - applying the
    inverse-bind term as well would place it twice.

The mesh is a rigid-part rig, not a smooth-skin rig: the torso hangs off one
bone (74 vertices spanning 1.51 vertically), the upper arms off 7 and 9, and so
on. Some bones are helpers with no skinned vertices at all - joint 25 carries a
1.68-unit bind length and zero vertices - so a long bone in the bind rig is not
a stretched limb.

Use the standalone .AvatarAnimation files for the pose and conjugate their
rotations; that is the only combination that hangs the arms and lowers the legs.

    python3 avatar_assemble.py --pack <AvatarAssetPack.toc> \\
        --anim <IdleOffScreen.AvatarAnimation> --frame 0 --obj avatar.obj
"""

import argparse

import numpy as np

import avatar_mesh as am
import avatar_pose as ap
import skeleton_nxe as sk


def apply(M, v):
    return (M[0][0] * v[0] + M[0][1] * v[1] + M[0][2] * v[2] + M[0][3],
            M[1][0] * v[0] + M[1][1] * v[1] + M[1][2] * v[2] + M[1][3],
            M[2][0] * v[0] + M[2][1] * v[1] + M[2][2] * v[2] + M[2][3])


def world_matrices(rig, poses, conjugate=True):
    bind = [ap.mat_trs(j["position"], j["rotation"]) for j in rig]
    bind_local = []
    for i, joint in enumerate(rig):
        parent = joint["parent"]
        if parent == 255 or parent >= i:
            bind_local.append(bind[i])
        else:
            bind_local.append(ap.mat_mul(ap.mat_inverse_rigid(bind[parent]), bind[i]))

    worlds = []
    for i, joint in enumerate(rig):
        p, q, s = poses[i]
        if conjugate:
            q = (-q[0], -q[1], -q[2], q[3])
        local = ap.mat_mul(bind_local[i], ap.mat_trs(p, q, s))
        parent = joint["parent"]
        if parent == 255 or parent >= i:
            worlds.append(local)
        else:
            worlds.append(ap.mat_mul(worlds[parent], local))
    return bind, worlds


def dominant_bones(model):
    """The bones each vertex is mostly weighted to - a rigid-part rig uses one."""
    bones = set()
    for joints, weights in zip(model["joints"], model["weights"]):
        best = weights.index(max(weights))
        if weights[best] > 0:
            bones.add(joints[best])
    return bones


def load_model(pack, index, asset):
    blobs = am.strb_blocks(am.asset_bytes(pack, index, asset))
    models = [b for b in blobs if b[0] == 3]
    if not models:
        raise SystemExit("no Model block in " + asset)
    return am.read_model(am.decompress(models[0][3]))[0]


def main():
    parser = argparse.ArgumentParser(description="Assemble a posed avatar into an OBJ.")
    parser.add_argument("--pack", required=True)
    parser.add_argument("--anim", required=True, help="standalone .AvatarAnimation file")
    parser.add_argument("--frame", type=int, default=0)
    parser.add_argument("--obj", required=True)
    parser.add_argument("--assets", nargs="+", default=["MaleBody", "Head"])
    parser.add_argument("--no-conj", action="store_true")
    args = parser.parse_args()

    with open(args.anim, "rb") as fh:
        clips = am.strb_blocks(fh.read())
    anim = [b for b in clips if b[0] == 1]
    if not anim:
        raise SystemExit("no Animation block in " + args.anim)
    poses, frame_count = ap.read_animation_poses(anim[0][3], args.frame)

    rig = sk.read_skeleton()
    bind, worlds = world_matrices(rig, poses, conjugate=not args.no_conj)
    skin = [ap.mat_mul(worlds[i], ap.mat_inverse_rigid(bind[i])) for i in range(len(rig))]

    index = am.load_pack_index(args.pack)
    verts = []
    faces = []
    for asset in args.assets:
        model = load_model(args.pack, index, asset)
        bones = dominant_bones(model)
        # One bone for the whole asset, and that bone sits far from the vertices,
        # means bone-local geometry: it takes the bone transform alone.
        bone_local = len(bones) == 1 and all(
            np.linalg.norm(np.array(v) - np.array(rig[b]["position"])) > 0.5
            for v, b in ((bb, sorted(bones)[0]) for bb in model["vertices"][:32]))
        base = len(verts)
        for pos, joints, weights in zip(model["vertices"], model["joints"], model["weights"]):
            if bone_local:
                j = joints[0] if weights[0] > 0 else joints[weights.index(max(weights))]
                verts.append(apply(worlds[j], pos))
                continue
            acc = [0.0, 0.0, 0.0]
            total = 0.0
            for j, w in zip(joints, weights):
                if w <= 0 or j >= len(skin):
                    continue
                p = apply(skin[j], pos)
                for k in range(3):
                    acc[k] += p[k] * w
                total += w
            verts.append(tuple(v / max(total, 1e-9) for v in acc))
        idx = model["indices"]
        for i in range(0, len(idx) - 2, 3):
            faces.append((base + idx[i], base + idx[i + 1], base + idx[i + 2]))
        print("%-10s %4d verts, %s" % (asset, len(model["vertices"]),
                                       "bone-local" if bone_local else "model space"))

    V = np.array(verts)
    with open(args.obj, "w", encoding="utf-8") as fh:
        for v in verts:
            fh.write("v %.6f %.6f %.6f\n" % v)
        for f in faces:
            fh.write("f %d %d %d\n" % (f[0] + 1, f[1] + 1, f[2] + 1))
    print("assembled %d verts, %d tris from %s frame %d/%d"
          % (len(verts), len(faces), args.anim.split("/")[-1], args.frame, frame_count))
    print("bbox x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f"
          % (V[:, 0].min(), V[:, 0].max(), V[:, 1].min(), V[:, 1].max(),
             V[:, 2].min(), V[:, 2].max()))
    print("wrote", args.obj)


if __name__ == "__main__":
    main()
