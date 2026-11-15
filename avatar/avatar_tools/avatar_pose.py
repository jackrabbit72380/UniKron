#!/usr/bin/env python3
"""Pose an avatar mesh: sample a clip, run FK, skin, write OBJ.

MaleBody's vertices are stored in bind pose, where one arm is held out sideways,
so a bind-pose bake can never look like a standing avatar. Every clip poses the
rig away from that, so this samples a standing clip (STRB block 1, which is
stored uncompressed), walks the joint hierarchy, and applies linear blend skinning
with `world * inverse(bind_world)` - the same composition Avatar Aura's bake uses.

    python3 avatar_pose.py --pack <AvatarAssetPack.toc> --asset MaleBody \\
        --clip "Animation Generic Stand 1" --frame 1 --obj posed.obj

The clips that actually work are the standalone .AvatarAnimation files shipped
next to the pack (IdleOffScreen, Cheer, Look, Salute, RunIn/Out*, Gift). Pass one
with --anim, and use --conj: that pairing puts the wrist 1.45 below the shoulder
(arms hanging) and the ankle 0.52 below the hip (legs descending), which no
combination of the pack's own clips ever did. The pack's clips carry near-zero
translations and pose a different rig, which is why they skin into a heap.

Status after testing every convention this file supports (delta, delta2, local,
world, with and without conjugated rotations, with the pose elements taken in
stream order or reversed, and with the mesh mirrored across Z):

  * The mesh and the skeleton are provably in one space. Each bone's weighted
    vertices sit a median 0.095 from that bone's own joint position with no axis
    permutation or sign flip, which is the alignment a correct match produces.
  * The skeleton parse is exact: it consumes 4300 of the 538-byte array's 4304
    bits, decodes 71 joints with a sane parent chain, every bind rotation is
    identity, and positions are a 17/17/14-bit lattice.
  * The bind pose is deliberately non-anatomical (HEAD at y=-0.37 while BASE is
    at y=+0.76, one arm folded out at hip height), so it is not meant to be
    displayed and cannot be checked by eye.
  * No convention produced an anatomically correct figure, so the remaining error
    is in how clip tracks are applied - which the original engine's pose code
    would settle, and that code is not public (xenia's avatars module is not in
    its public tree, and AvatarEditorRecomp ships binaries).

Later checks confirmed the decode itself is faithful: the vertex loop matches
avatar-aura's model.rs statement for statement (five serialisers, per-vertex UVs),
the mesh is a clean closed manifold (3392 of 3400 edges shared by exactly two
triangles, 8 boundary edges), the skeleton parser consumes 4300 of 538 bytes'
4304 bits, and consecutive clip frames differ by 0.0000 in position and 1.47
degrees at most, so the frames are a real, smooth idle. What does not line up is
the placement of parts: rendered from all six axis orientations, MaleBody draws
as a pair of thin tubes with no torso volume, and the bind skeleton puts one
three-joint chain 1.7 units away from the shoulder. The reference applies a
per-model transform (its apply_scale / manifest height and weight factors) that
this port does not reproduce, and that is the missing piece.

What the pack's own numbers rule out (each checked, not assumed): the clip's
scale is exactly 1.0 on all 71 controls and its translations are ~0, so the pose
is pure rotation and needs no scaling; the bind skeleton's chain 20 -> 25 -> 33
is 1.7 units long on a 1.8-unit body, so those joints cannot be a shoulder,
elbow and wrist and the joint names in this file are guesses, not facts; and a
survey of all 583 mesh assets in the pack found the same proportions everywhere
(about 1.8 x 1.5 x 0.4) with zero decode failures, so no "real body" asset is
being missed.

For a correct posed avatar today, export the OBJ from Avatar Aura (Windows) and
bake it; this pipeline stays as the decode/measurement tooling.
"""
import argparse
import math

import avatar_mesh as am
import skeleton_nxe

MAX_POSE_ELEMENTS = 72
MODE = "delta"
CONJ = False
MIRROR_Z = False
BIND_CONJ = False


# ---------------------------------------------------------------- small maths

def mat_identity():
    return [[1.0, 0.0, 0.0, 0.0],
            [0.0, 1.0, 0.0, 0.0],
            [0.0, 0.0, 1.0, 0.0],
            [0.0, 0.0, 0.0, 1.0]]


def mat_quat(q):
    x, y, z, w = q
    n = math.sqrt(x * x + y * y + z * z + w * w)
    if n < 1e-12:
        return mat_identity()
    x, y, z, w = x / n, y / n, z / n, w / n
    return [
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w), 0.0],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w), 0.0],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y), 0.0],
        [0.0, 0.0, 0.0, 1.0],
    ]


def mat_trs(pos, quat, scale=(1.0, 1.0, 1.0)):
    m = mat_quat(quat)
    for r in range(3):
        for c in range(3):
            m[r][c] *= scale[c]
        m[r][3] = pos[r]
    return m


def mat_mul(a, b):
    return [[sum(a[r][k] * b[k][c] for k in range(4)) for c in range(4)] for r in range(4)]


def mat_inverse_rigid(m):
    """Inverse of a rotation+translation matrix."""
    r = [[m[c][r] for c in range(3)] for r in range(3)]  # transpose of the rotation
    t = [m[0][3], m[1][3], m[2][3]]
    inv = mat_identity()
    for i in range(3):
        for j in range(3):
            inv[i][j] = r[i][j]
        inv[i][3] = -sum(r[i][k] * t[k] for k in range(3))
    return inv


def mat_apply(m, p):
    return (
        m[0][0] * p[0] + m[0][1] * p[1] + m[0][2] * p[2] + m[0][3],
        m[1][0] * p[0] + m[1][1] * p[1] + m[1][2] * p[2] + m[1][3],
        m[2][0] * p[0] + m[2][1] * p[1] + m[2][2] * p[2] + m[2][3],
    )


# ---------------------------------------------------------------- animation

class QuaternionSerializer:
    def __init__(self, stream):
        self.base = am.VectorSerializer(stream)

    def read(self, stream):
        x, y, z = self.base.read(stream)
        length = math.sqrt(x * x + y * y + z * z)
        if length < 1e-7:
            return (0.0, 0.0, 0.0, 1.0)
        s = math.sin(length)
        return (x * s / length, y * s / length, z * s / length, math.cos(length))


class PoseSerializer:
    """position, rotation, scale for one joint."""

    def __init__(self, stream):
        self.position = am.VectorSerializer(stream)
        self.rotation = QuaternionSerializer(stream)
        self.scale = am.VectorSerializer(stream)

    def bit_size(self):
        return (self.position.bit_count_x + self.position.bit_count_y + self.position.bit_count_z
                + self.rotation.base.bit_count_x + self.rotation.base.bit_count_y
                + self.rotation.base.bit_count_z
                + self.scale.bit_count_x + self.scale.bit_count_y + self.scale.bit_count_z)

    def read(self, stream):
        p = self.position.read(stream)
        q = self.rotation.read(stream)
        s = self.scale.read(stream)
        return p, q, s


def read_animation_poses(data, frame):
    """Pose elements of `frame` from an uncompressed animation block."""
    s = am.BitStream(data)
    frame_count = s.read_u32()
    fps = s.read_f32()
    pose_count_0 = s.read_u32()
    pose_count_1 = s.read_u32()
    s.read_u32()  # motion count
    s.read_u32()  # texture count
    pose2_offset = s.read_u32()
    s.read_u32()  # textures offset
    s.read_u32()  # motions offset
    compressed_size = s.read_u32()
    s.align_to_next_byte()
    if frame >= frame_count:
        raise SystemExit("frame %d outside clip of %d frames" % (frame, frame_count))

    local = am.BitStream(data[s.offset // 8:])
    local.offset = 0
    _ = pose2_offset
    count = pose_count_0
    if count > MAX_POSE_ELEMENTS:
        raise SystemExit("pose count above 72")
    if local.read_u32() != frame_count:
        raise SystemExit("frame count mismatch")
    if local.read_u32() != count:
        raise SystemExit("element count mismatch")

    serializers = [None] * MAX_POSE_ELEMENTS
    for i in range(count):
        serializers[count - 1 - i] = PoseSerializer(local)
    # Unused elements still carry their serializers: three vector-shaped ones
    # (position, rotation, scale), 146 bits each, so 438.
    unused_serializer_bits = 146 * 3
    for _ in range(count, MAX_POSE_ELEMENTS):
        local.advance(unused_serializer_bits)

    frame_bits = sum(serializers[i].bit_size() for i in range(count))
    local.advance(frame_bits * frame)
    poses = [serializers[i].read(local) for i in range(count)]
    return poses, frame_count


# ---------------------------------------------------------------- skinning

def conj(q):
    return (-q[0], -q[1], -q[2], q[3])


def posed_positions(batches, joints_rig, poses):
    """Joint world matrices, then linear blend skinning of every vertex."""
    bind = []
    for joint in joints_rig:
        rotation = conj(joint["rotation"]) if BIND_CONJ else joint["rotation"]
        bind.append(mat_trs(joint["position"], rotation))

    # Parent-relative bind transforms, then the clip's per-joint delta on top:
    # with identity deltas this reproduces the bind pose exactly.
    bind_local = []
    for i, joint in enumerate(joints_rig):
        parent = joint["parent"]
        if parent == 255 or parent >= i:
            bind_local.append(bind[i])
        else:
            bind_local.append(mat_mul(mat_inverse_rigid(bind[parent]), bind[i]))

    locals_ = []
    for i in range(len(joints_rig)):
        if i < len(poses):
            p, q, sc = poses[i]
            delta = mat_trs(p, conj(q) if CONJ else q, sc)
            if MODE == "delta":
                locals_.append(mat_mul(bind_local[i], delta))
            elif MODE == "delta2":
                locals_.append(mat_mul(delta, bind_local[i]))
            else:
                locals_.append(delta)
        else:
            locals_.append(bind_local[i] if MODE == "delta" else bind[i])

    worlds = []
    for i, joint in enumerate(joints_rig):
        parent = joint["parent"]
        if MODE == "world":
            # Some clips store joint transforms in model space; composing those
            # through the hierarchy a second time stretches the figure into a spike.
            worlds.append(locals_[i])
        elif parent == 255 or parent >= i:
            worlds.append(locals_[i])
        else:
            worlds.append(mat_mul(worlds[parent], locals_[i]))

    skin = [mat_mul(worlds[i], mat_inverse_rigid(bind[i])) for i in range(len(joints_rig))]

    out = []
    for batch in batches:
        verts = []
        for index, pos in enumerate(batch["vertices"]):
            names = batch["joints"][index]
            weights = batch["weights"][index]
            acc = [0.0, 0.0, 0.0]
            total = 0.0
            for j, w in zip(names, weights):
                if w <= 0.0 or j >= len(skin):
                    continue
                p = mat_apply(skin[j], (pos[0], pos[1], -pos[2]) if MIRROR_Z else pos)
                for k in range(3):
                    acc[k] += p[k] * w
                total += w
            if total <= 0.0:
                acc = list(pos)
            else:
                acc = [v / total for v in acc]
            verts.append(tuple(acc))
        out.append({"shader_id": batch["shader_id"], "vertices": verts, "indices": batch["indices"]})
    return out


def main():
    parser = argparse.ArgumentParser(description="Pose an avatar mesh with a clip and write OBJ.")
    parser.add_argument("--pack", required=True)
    parser.add_argument("--asset", default="MaleBody")
    parser.add_argument("--clip", default="Animation Generic Stand 1")
    parser.add_argument("--anim",
                        help="standalone .AvatarAnimation file (IdleOffScreen, Cheer, Look, ...). "
                             "These are the clips the editor really plays; the pack's own clips are "
                             "pose data for a different rig and skin into a heap.")
    parser.add_argument("--frame", type=int, default=1)
    parser.add_argument("--conj", action="store_true", help="conjugate pose rotations")
    parser.add_argument("--mirror-z", action="store_true", help="mirror the mesh across Z (INVERT)")
    parser.add_argument("--bind-conj", action="store_true", help="conjugate bind rotations")
    parser.add_argument("--obj", required=True)
    parser.add_argument("--mode", default="delta", choices=("delta", "delta2", "local", "world"))
    args = parser.parse_args()
    global MODE, CONJ, MIRROR_Z, BIND_CONJ
    MODE = args.mode
    CONJ = args.conj
    MIRROR_Z = args.mirror_z
    BIND_CONJ = args.bind_conj

    index = am.load_pack_index(args.pack)
    body = am.strb_blocks(am.asset_bytes(args.pack, index, args.asset))
    model = am.read_model(am.decompress([b for b in body if b[0] == 3][0][3]))

    clip_blocks = am.strb_blocks(am.asset_bytes(args.pack, index, args.clip))
    if args.anim:
        with open(args.anim, "rb") as fh:
            clip_blocks = am.strb_blocks(fh.read())
        args.clip = args.anim.split("/")[-1]
    anim_blocks = [b for b in clip_blocks if b[0] == 1]
    if not anim_blocks:
        raise SystemExit("no Animation block in " + args.clip)
    poses, frames = read_animation_poses(anim_blocks[0][3], args.frame)

    rig = skeleton_nxe.read_skeleton()
    posed = posed_positions(model, rig, poses)
    am.write_obj(args.obj, posed, "y")

    verts = [v for b in posed for v in b["vertices"]]
    xs = [v[0] for v in verts]
    ys = [v[1] for v in verts]
    zs = [v[2] for v in verts]
    print("%s clipped by %s frame %d/%d: %d joints, %d vertices"
          % (args.asset, args.clip, args.frame, frames, len(rig), len(verts)))
    print("posed bbox x %.3f..%.3f y %.3f..%.3f z %.3f..%.3f"
          % (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
    print("wrote", args.obj)


if __name__ == "__main__":
    main()
