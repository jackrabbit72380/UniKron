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

That conclusion was wrong, and the fix was not in this file: `avatar_mesh`
read the quantised lattice counts signed, which sheared every mesh. Reading them
unsigned (position = min + q * step * k, q in 0..2^width-1) puts `MaleBody` on
the reference's own bounds (x +-0.711, y 0.005..1.167, z -0.103..0.149) and this
file then poses a correct figure. Frame 0 of `IdleOffScreen.AvatarAnimation`
with **no** conjugation is the standing idle; `--conj` raises the arms into a
cheer. `bake_avatar.py` uses that to assemble whole avatars.
"""
import argparse
import math
import os

import avatar_mesh as am
import skeleton_nxe

MAX_POSE_ELEMENTS = 72
MODE = "delta"
CONJ = False
MIRROR_Z = False
BIND_CONJ = False
IGNORE_SCALE = os.environ.get("AVATAR_IGNORE_SCALE") == "1"


# ---------------------------------------------------------------- finger pose
#
# CORRECTION (2026-11-19): the hand does not need a second animation clip, and
# never had one. `MaleIdleShiftWeight.xnb` - the clip `bake_avatar.py` grafted
# finger joints from - is the same animation as the pack's own "Animation Male
# Idle Shifts Weight", re-exported for the avatar games: grafting its 30 finger
# joints into the editor's pose changes 0 of the 256x384 plate's 98,304 pixels
# (and 1 pixel, by one level, when the wrist roll is on). So the "measured" hand
# was the editor's hand all along, and everything that made it look like a hand
# was the authored pose below. Measured by `research/hand_variants.py`.
#
# The hand now comes from the clip, with one correction at the wrist that is
# measured from the retail editor's own avatar (`ref_hands.png`): the fingers
# hang vertically while the forearm above them runs down and slightly in, so
# `align_hands_to_arms` rotates the wrist until the middle finger is vertical.
# The clip leaves a 22-29 degree bend instead, which is what swung the hand out
# and away from the leg. Rotating the wrist cannot change a finger's own angle.
#
# The fingers are then brought together (FINGER_ADDUCT) and not curled: the
# reference's fingers are straight with only a slight bend at the tips, and the
# 12/18/12 degree curl that shipped before folded them into a fist.
#
# Kept for reproducing the earlier comparison:
#
#   pack idle + this pose  -> the fingers turn inward and the wrist pinches; the
#                             hand reads as a claw (artifacts/hand3.png, row 1)
#   pack idle, no pose     -> straight splayed fingers, a rake (row 2)
#   game Idle.xnb fingers  -> fingers together and slightly curled, which is a
#                             hand (row 3), and is measured, not authored
#
# CORRECTION (2026-11-18): defaulting this to 0 left the shipped hand as a fan of
# separated prongs - the baked frame showed four fingers with visible gaps
# between them, which is the "claws" the hand has always read as. Rendering the
# hand at four yaws in four settings (show_hand.py) showed the pack's bind hand
# is modelled open and fanned and that the clip does not close it: the clip's own
# finger deltas are 11-34 degrees and mostly twist, which fans it further. So the
# pose is on now, tuned against the bake itself rather than the hand in isolation,
# and the measurement that settled it is that the *editor's* clip fans the hand:
# its finger deltas are 11-34 degrees and mostly twist, so each phalanx is spun
# about its own axis and the four fingers spread into a rake - the claw the bakes
# have always shown. Two changes fix it and both are data, not angles:
#
#   * the fingers come from a retail avatar idle (`MaleIdleShiftWeight.xnb`, read
#     through bake_avatar's AVATAR_FINGER_XNB), so the editor's twist is replaced
#     by a pose that was actually authored for this skeleton by the console team;
#   * adduction 0.85 brings each finger across the palm by that fraction of the
#     angle to the hand's midline, which closes the gaps without stacking the
#     digits on top of each other (1.0 did, and the hand lumped).
#
# AVATAR_FINGER_CURL therefore defaults to 0,0,0: the authored curl is no longer
# needed and was making the fingertips arc away from the palm. Comparison sheets:
# hand_compare.png, hand_compare2.png, hand_final.png and hand_clip_adduct.png
# (the last is this setting across the whole 20-frame turn).
#
# The pack models the hand open and fanned, and nothing in the archive bends it:
# the idle clip leaves every finger at its bind delta, and forcing the hand
# joints back to those deltas changes no vertex (tested - see
# EDITOR_BINARIES.md). So the reference avatars' relaxed, half-closed hand is
# not present in any data this port has.
#
# These angles are therefore hand-authored to read like the reference hand:
# a loose curl through each phalanx, the thumb at half strength, and a small
# inward yaw at the finger bases to close the fan into a rake-free hand. They
# are deliberately modest - a full fist looks nothing like a standing avatar.
# The numbers can be overridden from the environment so a hand can be compared
# against another without editing the file between renders: the values are a
# look, and a look has to be chosen by looking.
#
#   AVATAR_FINGER_CURL="20,28,16"
#   AVATAR_FINGER_ADDUCT="0.6"
#
FINGER_CURL_DEGREES = tuple(
    float(v) for v in os.environ.get("AVATAR_FINGER_CURL", "0,0,0").split(",")
)                                            # per phalanx, base to tip
# How far each finger is brought across the palm, as a fraction of the angle
# that would land its tip on the hand's midline. 1.0 stacks every finger on the
# centre line; a little under leaves them touching but stacked, which is what a
# relaxed hand looks like. The angle is computed per finger from its own knuckle
# offset and length (finger_bones), because the bind fingers are parallel and
# 0.03 apart - there is no fan angle to take back, only a gap to close.
FINGER_ADDUCT = float(os.environ.get("AVATAR_FINGER_ADDUCT", "1.4"))
# Which way the curl folds. Rendered both ways at bake scale (448x672, the size
# the stage shows): +1 folds the digits back and out into a long hook past the
# hip, -1 folds them into the palm and gives a compact relaxed hand. So -1. The
# adduction direction is separate and unchanged by this sign.
FINGER_SIGN = float(os.environ.get("AVATAR_FINGER_SIGN", "-1"))
# On by default - see the note above.
FINGER_POSE = os.environ.get("AVATAR_FINGER_POSE", "1") == "1"
# Wrist and forearm roll, in degrees. Both default to 0 because both were an
# invention that made the hand worse: rolling the wrist 45 and the forearm 180
# turned the hand out to the side, and the reference's hand hangs straight down.
# The vertical hang now comes from `align_hands_to_arms`, below, which measures
# the angle instead of naming one.
WRIST_ROLL_DEGREES = float(os.environ.get("AVATAR_WRIST_ROLL", "0"))
# Forearm pronation, in degrees about the forearm's own axis. The wrist joint does
# not own the hand: rolling the wrist 0 or 180 degrees moves the baked plate by
# 2,163 pixels out of 98,304, and the hand keeps showing its full width. Turning
# the forearm's parent joint instead is the rotation that works - measured on
# MaleBody with the same clip (research/hand_axis_probe.py), the two hands' span
# goes 0.75 -> 0.60 at 120 degrees and 0.50 at 180 degrees, with the hand's height
# unchanged at 0.22, i.e. the palm turns toward the thigh and the hand keeps
# hanging. Negative turns the palms the other way.
FOREARM_ROLL_DEGREES = float(os.environ.get("AVATAR_FOREARM_ROLL", "0"))
FINGER_THUMB_SCALE = 0.22                  # the thumb barely curls, it lies alongside
# The two joints the arms end at: 33 (left of the model) and 36 (right). Each
# owns seven finger bones, which own the middle and tip phalanges.
WRIST_JOINTS = (33, 36)
# Diagnostic only: joint indices whose clip delta is dropped, so they keep the
# bind orientation. Used to find out whether the bend at the wrist is the clip's
# doing or ours; never set in a shipped bake.
ZERO_JOINTS = tuple(int(v) for v in os.environ.get("AVATAR_ZERO_JOINTS", "").split(",")
                    if v.strip())


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


def mat_axis_angle(axis, degrees):
    """Rotation matrix about a unit axis, right-handed, for mat_mul."""
    length = math.sqrt(sum(c * c for c in axis)) or 1.0
    x, y, z = (c / length for c in axis)
    angle = math.radians(degrees)
    c, s = math.cos(angle), math.sin(angle)
    t = 1.0 - c
    return [
        [t * x * x + c, t * x * y - s * z, t * x * z + s * y, 0.0],
        [t * x * y + s * z, t * y * y + c, t * y * z - s * x, 0.0],
        [t * x * z - s * y, t * y * z + s * x, t * z * z + c, 0.0],
        [0.0, 0.0, 0.0, 1.0],
    ]


def _normalise(v):
    length = math.sqrt(sum(c * c for c in v)) or 1.0
    return [c / length for c in v]


def _cross(u, v):
    return [u[1] * v[2] - u[2] * v[1],
            u[2] * v[0] - u[0] * v[2],
            u[0] * v[1] - u[1] * v[0]]


def _rotate_about(point, origin, matrix):
    offset = [point[i] - origin[i] for i in range(3)]
    rotated = [sum(matrix[r][c] * offset[c] for c in range(3)) for r in range(3)]
    return [rotated[i] + origin[i] for i in range(3)]


def _distance(a, b):
    return math.sqrt(sum((a[i] - b[i]) ** 2 for i in range(3)))


def finger_bones(joints_rig, bind):
    """Every finger phalanx, with the axes and signs that make it curl inward.

    Each entry is (joint, bend axis, swing axis, depth, is_thumb, direction) with
    both axes in the joint's own frame. A finger bends about the axis
    perpendicular to its own length and the palm normal - rotating about the
    normal itself just sweeps the finger sideways, which is what the fanned bind
    pose already looks like. Which of the two perpendicular directions closes the
    hand is not a constant: it is chosen per hand by rotating the fingertip and
    keeping the sign that moves it closer to the palm.
    """
    out = []
    for wrist in WRIST_JOINTS:
        kids = [i for i, j in enumerate(joints_rig) if j["parent"] == wrist]
        if len(kids) < 5:
            continue
        local = [mat_apply(mat_inverse_rigid(bind[wrist]), joints_rig[k]["position"])
                 for k in kids]
        # The thumb sits far off the finger plane (large |y| in wrist space);
        # including it tilts the normal, so the plane is fitted to the rest.
        palm = [k for k, p in zip(kids, local) if abs(p[1]) < 0.15]
        if len(palm) < 3:
            palm = kids[:-1]
        p0, p1, p2 = (joints_rig[palm[0]]["position"],
                      joints_rig[palm[1]]["position"],
                      joints_rig[palm[-1]]["position"])
        normal = _normalise(_cross([p1[i] - p0[i] for i in range(3)],
                                   [p2[i] - p0[i] for i in range(3)]))
        palm_centre = [sum(joints_rig[k]["position"][i] for k in palm) / len(palm)
                       for i in range(3)]
        # The finger nearest the palm's centre gives the direction the others
        # should swing toward; a single sign for every finger cannot close a fan.
        middle = min(kids, key=lambda k: _distance(joints_rig[k]["position"], palm_centre))
        middle_children = [c for c, info in enumerate(joints_rig) if info["parent"] == middle]
        middle_dir = None
        if middle_children:
            nxt = joints_rig[middle_children[0]]["position"]
            middle_dir = _normalise([nxt[i] - joints_rig[middle]["position"][i] for i in range(3)])

        # The thumb is the knuckle whose root sits *on the wrist*. Measured in
        # the rig: joints 43 and 50 sit 0.0099 out from wrist 33/36, while every
        # other child of a wrist is 0.107 or further. Two earlier tests were
        # wrong and both left the thumb unposed: |y| in wrist space, and
        # "furthest off the palm's own plane" - which cannot work, because a
        # thumb root back at the wrist is very nearly *in* that plane, so the max
        # landed on an ordinary finger and no joint was ever flagged as a thumb.
        # `finger_bones` returned 30 entries and not one of them a thumb, which is
        # why scaling the thumb's curl and adduction changed no pixel at all.
        wrist_at = joints_rig[wrist]["position"]
        thumb_root = min(kids, key=lambda k: _distance(joints_rig[k]["position"], wrist_at))
        # Which way the palm faces. The thumb is the landmark: it lies on the
        # palm's side of the hand, so the side of the palm plane it sits on is
        # the side the fingers close toward. This has to use the thumb's *tip*,
        # not its root - with 43/50 identified as the thumbs, the root is back at
        # the wrist, and a direction from the knuckles to the wrist is not the
        # palm normal at all. Using the root made the fingers curl backwards,
        # away from the palm, which is the "long prongs" look.
        thumb_tip = thumb_root
        while True:
            nxt = [c for c, info in enumerate(joints_rig) if info["parent"] == thumb_tip]
            if not nxt:
                break
            thumb_tip = nxt[0]
        thumb_offset = [joints_rig[thumb_tip]["position"][i] - palm_centre[i] for i in range(3)]
        facing = sum(thumb_offset[i] * normal[i] for i in range(3))
        palm_side = [normal[i] * (1.0 if facing >= 0.0 else -1.0) for i in range(3)]

        for root in kids:
            # 43 and 50 look degenerate - their root sits exactly on the wrist,
            # 0.0099 out - but each carries a three-joint chain out to
            # (0.098, -0.055, 0.079) in wrist space. That is the thumb: a real
            # thumb's base joint sits back at the wrist, not out at the knuckles.
            # They were being filtered out as helpers, which is why the thumb has
            # been a rigid stub this whole time.
            chain = [root]
            while True:
                children = [c for c, info in enumerate(joints_rig)
                            if info["parent"] == chain[-1]]
                if not children or len(chain) >= 3:
                    break
                chain.append(children[0])
            if len(chain) < 2:
                continue
            here = joints_rig[root]["position"]
            ahead = joints_rig[chain[1]]["position"]
            direction = _normalise([ahead[i] - here[i] for i in range(3)])
            bend = _normalise(_cross(direction, normal))

            rotation = [[bind[root][r][c] for c in range(3)] for r in range(3)]
            to_local = lambda v: [sum(rotation[r][c] * v[r] for r in range(3)) for c in range(3)]
            bend_model = bend
            tip = joints_rig[chain[-1]]["position"]
            if not any(i["parent"] == chain[-1] for i in joints_rig):
                tip = [2.0 * tip[i] - joints_rig[chain[-2]]["position"][i] for i in range(3)]
            plus = _rotate_about(tip, here, mat_axis_angle(bend_model, 15.0))
            toward_palm = sum((plus[i] - tip[i]) * palm_side[i] for i in range(3))
            sign = 1.0 if toward_palm > 0.0 else -1.0

            def lateral(point):
                if middle_dir is None:
                    return _distance(point, palm_centre)
                offset = [point[i] - palm_centre[i] for i in range(3)]
                along = sum(offset[i] * middle_dir[i] for i in range(3))
                return math.sqrt(max(0.0, sum(c * c for c in offset) - along * along))

            # A positive angle about the palm normal is the inward direction when
            # it brings the tip closer to the hand's midline, so it needs +1, not
            # -1: the earlier -1 turned every adduction into an abduction and the
            # stronger the value the wider the hand splayed (measured: 0.85 fanned,
            # 1.4 fanned further).
            swung = _rotate_about(tip, here, mat_axis_angle(normal, 15.0))
            swing_sign = 1.0 if lateral(swung) < lateral(tip) else -1.0

            # Fingers have to come together, not just curl. In wrist space the
            # four knuckles sit at z +0.042, +0.011, -0.019, -0.047 and their
            # tips at z +0.043, +0.011, -0.019, -0.047: the bones are parallel
            # and 0.03 apart, so no fan angle exists to take back (measured
            # 0.1-0.9 degrees). Rotating each finger about the palm normal at
            # its knuckle is what closes the gaps between the tubes; the angle
            # that lands the tip on the hand's midline is atan2(spread, length).
            spread = lateral(here)
            length = max(_distance(tip, here), 1e-6)
            adduct = math.degrees(math.atan2(spread, length))

            for depth, joint in enumerate(chain, 1):
                joint_here = joints_rig[joint]["position"]
                kids_here = [c for c, info in enumerate(joints_rig) if info["parent"] == joint]
                if kids_here:
                    nxt = joints_rig[kids_here[0]]["position"]
                    own_dir = _normalise([nxt[i] - joint_here[i] for i in range(3)])
                else:
                    own_dir = direction
                own_bend = _normalise(_cross(own_dir, normal))
                own_rot = [[bind[joint][r][c] for c in range(3)] for r in range(3)]
                own_to_local = lambda v, m=own_rot: [sum(m[r][c] * v[r] for r in range(3))
                                                    for c in range(3)]
                out.append((joint, own_to_local(own_bend), own_to_local(normal),
                            depth, root == thumb_root, sign, swing_sign,
                            adduct if depth == 1 else 0.0))
    return out


HAND_WRIST_SHARE = 0.35


def _share_hand_weight(names, weights, blend):
    """Move HAND_WRIST_SHARE of a finger-base weight onto the wrist, if present."""
    wrists = set(blend.values())
    moved = 0.0
    names = list(names)
    weights = list(weights)
    for i, joint in enumerate(names):
        if joint in blend and weights[i] > 0.0:
            give = weights[i] * HAND_WRIST_SHARE
            weights[i] -= give
            moved += give
    if moved <= 0.0:
        return names, weights
    targets = [i for i, joint in enumerate(names) if joint in wrists]
    if not targets:
        return names, weights  # no wrist influence on this vertex: leave it alone
    share = moved / len(targets)
    for i in targets:
        weights[i] += share
    return names, weights


def _smoothed_hand_weights(batches, joints_rig,
                           # Off by default: the rings reach up the forearm and
                           # the curl dragged the arm with it, and the tearing it
                           # was meant to fix is not what the bakes showed.
                           iterations=int(os.environ.get("AVATAR_HAND_SMOOTH", "0")),
                           amount=float(os.environ.get("AVATAR_HAND_SMOOTH_AMOUNT", "0.35")),
                           rings=2):
    """Weights for every vertex, with the hand's own weights blurred.

    The pack weights each finger's base ring entirely to that finger and its
    neighbour to the palm, so a knuckle rotation tears the ring off the hand: the
    baked hand had fingertips floating beside the palm. Averaging each hand
    vertex's weights with its neighbours over the triangle graph removes the
    step, and the bind pose is unaffected because every joint's transform is the
    identity there.
    """
    fingers = set(WRIST_JOINTS)
    for joint, info in enumerate(joints_rig):
        if info["parent"] in WRIST_JOINTS:
            fingers.add(joint)
            for kid, kinfo in enumerate(joints_rig):
                if kinfo["parent"] == joint:
                    fingers.add(kid)

    out = []
    for batch in batches:
        count = len(batch["vertices"])
        maps = []
        touched = set()
        for index in range(count):
            entry = {}
            for joint, weight in zip(batch["joints"][index], batch["weights"][index]):
                if weight > 0.0:
                    entry[int(joint)] = float(weight)
            if any(j in fingers for j in entry):
                touched.add(index)
            maps.append(entry)
        if not touched:
            out.append([dict(m) for m in maps])
            continue

        neighbours = [set() for _ in range(count)]
        indices = batch["indices"]
        for t in range(0, len(indices), 3):
            a, b, c = int(indices[t]), int(indices[t + 1]), int(indices[t + 2])
            for u, v in ((a, b), (b, c), (c, a)):
                neighbours[u].add(v)
                neighbours[v].add(u)

        # Only the hand and the ring of vertices it meets: smoothing the whole
        # model would drag the forearm into the wrist.
        # Two rings out from the vertices that sit on a finger: enough to bridge
        # the knuckle, not enough to reach the middle of the palm, which has to
        # stay rigid or the whole hand curls into a hook.
        region = set(touched)
        for _ in range(rings):
            edge = set(region)
            for index in region:
                edge |= neighbours[index]
            region = edge

        for _ in range(iterations):
            updated = []
            for index in range(count):
                if index not in region:
                    updated.append(maps[index])
                    continue
                acc = {j: w * (1.0 - amount) for j, w in maps[index].items()}
                near = neighbours[index]
                if near:
                    share = amount / len(near)
                    for other in near:
                        for j, w in maps[other].items():
                            acc[j] = acc.get(j, 0.0) + w * share
                updated.append(acc)
            maps = updated

        cleaned = []
        for entry in maps:
            total = sum(entry.values())
            if total <= 0.0:
                cleaned.append(entry)
            else:
                cleaned.append({j: w / total for j, w in entry.items()})
        out.append(cleaned)
    return out


def hand_weight_blend(joints_rig):
    """{finger root: wrist} for the joints whose base ring meets the palm.

    The pack weights each finger's base ring entirely to the finger, with no
    blend into the hand, so rotating a knuckle tears the finger off the palm and
    leaves a visible notch - the "separated prongs" the hand showed at close
    range. Sharing a little of the wrist's weight with the base ring closes the
    notch without changing the bind pose (the blend only matters once the finger
    rotates).
    """
    blend = {}
    for wrist in WRIST_JOINTS:
        for joint, info in enumerate(joints_rig):
            if info["parent"] == wrist:
                blend[joint] = wrist
    return blend


def apply_wrist_roll(joints_rig, locals_):
    """Pronate each forearm so the palm faces the thigh instead of outward.

    The idle clips swing the arm down from the T-pose without any twist, so the
    palm - which faces down in the bind pose - ends up facing sideways. Every
    hand then shows the camera its full width, and a 69-vertex hand at full width
    is a fan of thin prongs. The retail editor's avatar has its palms facing the
    thighs, which stacks the fingers behind one another and reads as a hand.

    The rotation is about the forearm axis, which is the wrist joint's local X
    (the bind fingers run along X). Zero turns it off.
    """
    if FOREARM_ROLL_DEGREES and os.environ.get("AVATAR_ROLL_DEBUG") == "1":
        print("roll debug: %d joints, wrists %s, parents %s"
              % (len(joints_rig), WRIST_JOINTS,
                 [joints_rig[w]["parent"] for w in WRIST_JOINTS if w < len(joints_rig)]))
    for wrist in WRIST_JOINTS:
        if wrist >= len(locals_):
            continue
        sign = -1.0 if wrist == WRIST_JOINTS[1] else 1.0
        if WRIST_ROLL_DEGREES:
            # mat_axis_angle takes degrees and converts internally. This call used
            # to pass math.radians(...) into it, so every "70 degree" roll was
            # really 1.2 degrees and the hand never turned: that is why rolling the
            # wrist 0 or 180 moved the plate by nothing (CORRECTION, 2026-11-19).
            locals_[wrist] = mat_mul(locals_[wrist],
                                     mat_axis_angle((1.0, 0.0, 0.0),
                                                    WRIST_ROLL_DEGREES * sign))
        if FOREARM_ROLL_DEGREES:
            # The hand is skinned to the wrist and its knuckles, but the turn that
            # reads as a palm is the forearm's: see FOREARM_ROLL_DEGREES above.
            forearm = joints_rig[wrist]["parent"]
            if forearm < len(locals_):
                locals_[forearm] = mat_mul(
                    locals_[forearm],
                    mat_axis_angle((1.0, 0.0, 0.0),
                                   FOREARM_ROLL_DEGREES * sign))
    return locals_


ALIGN_HAND = os.environ.get("AVATAR_ALIGN_HAND", "1") == "1"


def _digits(joints_rig, wrist):
    """Every chain that starts at a child of `wrist`, walked two joints down."""
    chains = []
    for root in [i for i, j in enumerate(joints_rig) if j["parent"] == wrist]:
        chain = [root]
        while True:
            nxt = [c for c, j in enumerate(joints_rig) if j["parent"] == chain[-1]]
            if not nxt or len(chain) >= 3:
                break
            chain.append(nxt[0])
        chains.append(chain)
    return chains


def _middle_finger(joints_rig, wrist, at):
    """The digit whose direction is the mean of the four fingers, and its tip.

    The thumb's root sits back on the wrist (0.0099 out, against 0.10 or more
    for every finger), so it is the one to leave out of the mean.
    """
    chains = _digits(joints_rig, wrist)
    if len(chains) < 4:
        return None
    near = sorted(chains, key=lambda c: _distance(at[c[0]], at[wrist]))
    thumb = near[0]
    fingers = [c for c in chains if c is not thumb and len(c) >= 2] or chains
    dirs = [_normalise([at[c[-1]][i] - at[wrist][i] for i in range(3)]) for c in fingers]
    mean = _normalise([sum(d[i] for d in dirs) for i in range(3)])
    best = max(range(len(dirs)), key=lambda i: sum(dirs[i][k] * mean[k] for k in range(3)))
    return fingers[best], at[fingers[best][-1]]


def align_hands_to_arms(joints_rig, locals_, worlds):
    """Hang each hand straight down, as the retail editor's avatar does.

    Measured on `ref_hands.png` (the retail editor, 3x): both hands hang with the
    fingers vertical, while the forearm above them runs down and slightly inward
    - the wrist bends, the hand does not follow the arm. The idle clip leaves a
    22-29 degree wrist bend instead, which swings the hand out and fans the
    fingers away from the body, and that is the whole of the "wrong hands": the
    hand is not detached or mis-skinned, it is hanging at the wrong angle.

    So the correction is the rotation that carries the middle finger onto
    straight down, applied at the wrist. It is measured from the pose, not
    chosen: the target is vertical because the reference's hands are vertical.
    Rotating the wrist cannot change any finger's own angle.
    """
    target = (0.0, -1.0, 0.0)
    for wrist in WRIST_JOINTS:
        if wrist >= len(locals_):
            continue
        at = [(w[0][3], w[1][3], w[2][3]) for w in worlds]
        found = _middle_finger(joints_rig, wrist, at)
        if found is None:
            continue
        finger, tip = found
        hand = _normalise([tip[i] - at[wrist][i] for i in range(3)])
        bend = math.degrees(math.acos(max(-1.0, min(1.0, sum(
            target[i] * hand[i] for i in range(3))))))
        if bend <= 0.01:
            continue
        axis = _cross(hand, target)       # turns `hand` onto straight down
        if math.sqrt(sum(c * c for c in axis)) < 1e-9:
            continue
        axis = _normalise(axis)
        world = worlds[wrist]
        # The wrist's own rotation maps a local axis into the world, so the
        # world axis comes back through its transpose.
        local_axis = [sum(world[r][c] * axis[r] for r in range(3)) for c in range(3)]
        locals_[wrist] = mat_mul(locals_[wrist],
                                 mat_axis_angle(local_axis, bend))
    return locals_


def apply_finger_pose(joints_rig, bind, locals_):
    """Close the fingers on top of the clip's pose, in place.

    The curl is 0 by default (the reference's fingers are straight); what this
    still does every bake is the adduction that brings the four digits together.
    """
    for joint, bend, swing, depth, thumb, sign, swing_sign, adduct in finger_bones(joints_rig, bind):
        if joint >= len(locals_):
            continue
        degrees = FINGER_CURL_DEGREES[min(depth, len(FINGER_CURL_DEGREES)) - 1]
        if thumb:
            degrees *= FINGER_THUMB_SCALE
        locals_[joint] = mat_mul(locals_[joint], mat_axis_angle(bend, FINGER_SIGN * sign * degrees))
        if depth == 1:
            # Bring the fingers together across the palm. The angle is the one
            # that lands this finger's tip on the hand's midline, scaled by how
            # far to go; the thumb closes a little as well, since it too hangs
            # out to the side in the bind pose.
            inward = adduct * FINGER_ADDUCT * swing_sign
            if thumb:
                inward *= FINGER_THUMB_SCALE
            locals_[joint] = mat_mul(locals_[joint], mat_axis_angle(swing, inward))
    return locals_


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


def posed_joint_positions(joints_rig, poses):
    """Where every joint ends up, without skinning any mesh.

    The finger question is a joint question: whether a clip curls a hand shows in
    the joint positions before a single vertex is skinned, and this makes it
    cheap enough to ask about all 41 clips in the pack.
    """
    bind = []
    for joint in joints_rig:
        rotation = conj(joint["rotation"]) if BIND_CONJ else joint["rotation"]
        bind.append(mat_trs(joint["position"], rotation))

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
            if IGNORE_SCALE:
                sc = (1.0, 1.0, 1.0)
            delta = mat_trs(p, conj(q) if CONJ else q, sc)
            locals_.append(mat_mul(bind_local[i], delta) if MODE == "delta" else
                          (mat_mul(delta, bind_local[i]) if MODE == "delta2" else delta))
        else:
            locals_.append(bind_local[i] if MODE == "delta" else bind[i])

    worlds = []
    for i, joint in enumerate(joints_rig):
        parent = joint["parent"]
        if MODE == "world" or parent == 255 or parent >= i:
            worlds.append(locals_[i])
        else:
            worlds.append(mat_mul(worlds[parent], locals_[i]))
    return [(w[0][3], w[1][3], w[2][3]) for w in worlds]


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
            if IGNORE_SCALE:
                # Diagnostic: the scale triplet is decoded from the same lattice as
                # the translation, and a wrong lattice stretches whatever joint it
                # lands on (the hands, when the wrist is the joint). Setting it to
                # one shows whether that is what is happening.
                sc = (1.0, 1.0, 1.0)
            delta = mat_trs(p, conj(q) if CONJ else q, sc)
            if MODE == "delta":
                locals_.append(mat_mul(bind_local[i], delta))
            elif MODE == "delta2":
                locals_.append(mat_mul(delta, bind_local[i]))
            else:
                locals_.append(delta)
        else:
            locals_.append(bind_local[i] if MODE == "delta" else bind[i])

    if ZERO_JOINTS:
        for i in ZERO_JOINTS:
            if i < len(locals_):
                locals_[i] = bind_local[i] if MODE == "delta" else bind[i]

    # The pack models the hand open and straight, and the idle clip's 11-34
    # degrees on the finger joints is nearly all twist - the knuckle bend only
    # goes from 17.9 to 23 degrees - so the relaxed hand is added here (see the
    # ART CHOICE note at the top of this file). `AVATAR_FINGER_POSE=0` shows the
    # clip's own hand, and probe_hand.py / show_hand.py render either.
    apply_wrist_roll(joints_rig, locals_)
    if FINGER_POSE:
        apply_finger_pose(joints_rig, bind, locals_)

    def compose():
        out = []
        for i, joint in enumerate(joints_rig):
            parent = joint["parent"]
            if MODE == "world":
                # Some clips store joint transforms in model space; composing those
                # through the hierarchy a second time stretches the figure into a spike.
                out.append(locals_[i])
            elif parent == 255 or parent >= i:
                out.append(locals_[i])
            else:
                out.append(mat_mul(out[parent], locals_[i]))
        return out

    worlds = compose()
    if ALIGN_HAND:
        align_hands_to_arms(joints_rig, locals_, worlds)
        worlds = compose()

    skin = [mat_mul(worlds[i], mat_inverse_rigid(bind[i])) for i in range(len(joints_rig))]

    smoothed = _smoothed_hand_weights(batches, joints_rig)
    out = []
    for batch, weight_maps in zip(batches, smoothed):
        verts = []
        for index, pos in enumerate(batch["vertices"]):
            items = weight_maps[index].items()
            acc = [0.0, 0.0, 0.0]
            total = 0.0
            for j, w in items:
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
