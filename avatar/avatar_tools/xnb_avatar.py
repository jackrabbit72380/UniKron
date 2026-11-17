"""Read the avatar animation clips the XNA avatar games ship as .xnb.

The Avatar Games archive carries 39 clips under `Content/Avatar Animations/`
that were authored by the game developers against the same 71-joint Xbox rig
the retail pack uses. They are the only hand-posed source outside the pack
itself, so they matter for anything the pack's clips never show - a resting
hand above all.

File layout, all little endian, XNB version 5, target 'x' (Xbox 360),
flags 0x00 (nothing compressed - the declared size equals the file size):

    0x00  'XNBx'
    0x04  u8  version = 5
    0x05  u8  flags   = 0
    0x06  u32 total file size
    0x0a  7-bit length, then for each type reader:
              7-bit length + name, i32 version
          7-bit shared resource count
          root object

The root is `Hazzah.Engine.CustomAvatarAnimationData`, written by XNA's
ReflectiveReader in field order:

    u8, u8                            two single byte fields, then
    7-bit length + name string        ("Take 001")
    i64 duration ticks                (3 s = 30,000,000)
    i32 count, then count records of
        i32 joint index               0..70
        i64 time ticks
        f32[16] 4x4 matrix            row major

The records are per joint, not per frame: count = frames * moving joints, and
they are interleaved. 181 frames at 60 fps gives 12,851 records, which is exactly
181 * 71 for `Idle`; joints that never move in a clip are simply absent, so `Fly`
carries 67 per frame. One byte is left after the last record (the expression
list's count), so a correct walk ends on size - 1.

Most clips store rotation only, so the bind positions from skeleton_nxe supply
the joint placement and the two compose without guessing where a joint sits.
Clips that move the character store the root's translation in the bottom row of
the root joint's matrix (`Run` does); every other joint stays rotation only.
"""

import argparse
import struct

import numpy as np

import lzx

DEFAULT = "Content/Avatar Animations/Idle.xnb"


def load(path):
    """File bytes, decompressed if the XNB carries an LZX stream.

    A compressed XNB keeps the file size at 6 and the decompressed size at 10,
    then the stream. Version 5 needs one byte skipped and a 64 KiB window: Avatar
    Laser Wars 2's 195 compressed files all read that way, and the result begins
    with an ordinary type-reader table. The 32 KiB window that the avatar pack
    uses does not decode them, which is the trap here - same LZX, different window.
    """
    data = open(path, "rb").read()
    if data[:4] not in (b"XNBx", b"XNBw", b"XNBm"):
        raise ValueError("not an XNB: %r" % data[:4])
    if not data[5] & 0x80:
        return data
    size = struct.unpack_from("<I", data, 10)[0]
    attempts = ((15, 0x10000), (14, 0x10000), (16, 0x10000),
                (14, 0x8000), (15, 0x8000))
    last = None
    for start, window in attempts:
        try:
            raw = lzx.decompress(data[start:], size, window)
        except lzx.LzxError as error:
            last = error
            continue
        if len(raw) == size:
            return raw
    # Avatar Boogie's five dances and Avatar Avenue's three clips are version 4
    # and still do not read: every offset above fails at the first block header.
    raise ValueError("compressed XNB this decoder cannot read yet (%s)" % last)


def _unpack_7bit(data, pos):
    value = 0
    shift = 0
    while True:
        byte = data[pos]
        pos += 1
        value |= (byte & 0x7F) << shift
        shift += 7
        if not byte & 0x80:
            return value, pos


def read_type_readers(data):
    """The XNB type-reader table, as (name, version) pairs.

    `load` strips the header when it decompresses, so a buffer without the magic
    is read as a bare payload starting at the reader count.
    """
    if data[:4] in (b"XNBx", b"XNBw", b"XNBm"):
        version = data[4]
        flags = data[5]
        size = struct.unpack_from("<I", data, 6)[0]
        pos = 10
    else:
        version = flags = size = 0
        pos = 0
    count, pos = _unpack_7bit(data, pos)
    readers = []
    for _ in range(count):
        length, pos = _unpack_7bit(data, pos)
        name = data[pos:pos + length].decode("utf-8", "replace")
        pos += length
        ver = struct.unpack_from("<i", data, pos)[0]
        pos += 4
        readers.append((name, ver))
    shared, pos = _unpack_7bit(data, pos)
    return dict(version=version, flags=flags, size=size,
                readers=readers, shared=shared, payload=pos)


def _is_affine(data, at, tol=2e-2):
    """A 4x4 that could be a joint transform, translation allowed."""
    if at + 64 > len(data):
        return False
    m = struct.unpack_from("<16f", data, at)
    if abs(m[15] - 1.0) > tol:
        return False
    if abs(m[3]) > tol or abs(m[7]) > tol or abs(m[11]) > tol:
        return False
    return all(abs(m[c] ** 2 + m[4 + c] ** 2 + m[8 + c] ** 2 - 1.0) < 0.2
               for c in range(3))


def read_clip(path):
    """Decode a clip into (name, duration_seconds, frames, joints).

    frames is a list of (time_seconds, {joint: 4x4 rotation}).
    """
    data = load(path)
    head = read_type_readers(data)
    pos = head["payload"]

    # Two single byte fields come first and their meaning is not established,
    # so the name is found by shape: a length whose bytes are printable text.
    name = ""
    for lead in range(pos, pos + 8):
        length, after = _unpack_7bit(data, lead)
        if not 0 < length < 64 or after + length + 8 > len(data):
            continue
        text = data[after:after + length]
        if all(32 <= b < 127 for b in text):
            ticks = struct.unpack_from("<q", data, after + length)[0]
            if 0 < ticks < 3600 * 10 ** 7:
                name = text.decode("ascii")
                pos = after + length
                break
    else:
        raise ValueError("no name/duration found in %s" % path)
    ticks = struct.unpack_from("<q", data, pos)[0]
    pos += 8

    # The count that precedes the first record is written by the list reader;
    # rather than trust an offset guess, walk records until they stop looking
    # like records. 76 bytes each, and the walk ends on the last byte.
    start = None
    for probe in range(pos, pos + 64):
        if _is_affine(data, probe + 12):
            index = struct.unpack_from("<i", data, probe)[0]
            if 0 <= index <= 70:
                start = probe
                break
    if start is None:
        raise ValueError("no keyframe records found in %s" % path)

    at = start
    by_time = {}
    moved = False
    while at + 76 <= len(data) and _is_affine(data, at + 12):
        index = struct.unpack_from("<i", data, at)[0]
        if not 0 <= index <= 70:
            break
        time = struct.unpack_from("<q", data, at + 4)[0]
        rot = np.array(struct.unpack_from("<16f", data, at + 12),
                       dtype=np.float64).reshape(4, 4)
        if np.abs(rot[3, :3]).max() > 1e-4:
            moved = True
        by_time.setdefault(time, {})[index] = rot
        at += 76

    frames = [(t / 1e7, by_time[t]) for t in sorted(by_time)]
    joints = sorted({j for _, frame in frames for j in frame})
    return dict(name=name, duration=ticks / 1e7, frames=frames, joints=joints,
                records=len(by_time and [r for f in by_time.values()
                                        for r in f]), moved=moved,
                end=at, size=len(data))


def read_dna(path):
    """Read a `DNA.Drawing.Animation.AnimationClip` (the Digital DNA games).

    Payload, little endian:

        u8 flag, u8 name length + name
        i32   30            - frame count seen in every clip so far
        i64   duration ticks (3,166,666 = 1/3 s)
        i32   bone count    (71)
        then per bone, three channels, each `i32 count` followed by that many
        elements:
            count x Vector3  (12 bytes)  translation
            count x Quaternion (16)      rotation
            count x Vector3  (12)        scale

    That is 52 bytes a bone while every channel holds a single key, which is what
    the small clips in this archive do: `GenericIdle` is 71 * 52 bytes exactly and
    the walk ends on the last byte. A clip with real motion carries several keys
    per channel, and the same walk still covers the file.
    """
    data = load(path)
    pos = read_type_readers(data)["payload"]
    pos += 1
    length = data[pos]
    pos += 1
    name = data[pos:pos + length].decode("ascii", "replace")
    pos += length
    frame_count = struct.unpack_from("<i", data, pos)[0]
    pos += 4
    ticks = struct.unpack_from("<q", data, pos)[0]
    pos += 8
    bone_count = struct.unpack_from("<i", data, pos)[0]
    pos += 4

    bones = []
    for _ in range(bone_count):
        count = struct.unpack_from("<i", data, pos)[0]
        pos += 4
        translation = np.array(struct.unpack_from("<%df" % (3 * count), data, pos),
                               dtype=np.float64).reshape(-1, 3)
        pos += 12 * count
        count = struct.unpack_from("<i", data, pos)[0]
        pos += 4
        rotation = np.array(struct.unpack_from("<%df" % (4 * count), data, pos),
                            dtype=np.float64).reshape(-1, 4)
        pos += 16 * count
        count = struct.unpack_from("<i", data, pos)[0]
        pos += 4
        scale = np.array(struct.unpack_from("<%df" % (3 * count), data, pos),
                         dtype=np.float64).reshape(-1, 3)
        pos += 12 * count
        bones.append(dict(translation=translation, rotation=rotation, scale=scale))

    return dict(name=name, frame_count=frame_count, duration=ticks / 1e7,
                bones=bones, joints=list(range(bone_count)), end=pos, size=len(data),
                records=sum(len(b["rotation"]) for b in bones))


def dna_poses(clip, frame=0, flip_y=True):
    """A DNA clip as avatar_pose tuples, one bone per rig joint.

    The rotation channel is a local rotation per bone, so the bind offsets from
    the skeleton supply placement and `delta` mode puts the rotation on top -
    bones the clip leaves at identity simply stay at bind.

    `flip_y` negates the quaternion's y. The DNA engine's rotations are in the
    opposite handedness, and without the flip the arms end up above the head: on
    `Laser Wars 2/GenericIdle` the wrists sit at y 0.856 unflipped and 0.768
    flipped, against 0.642 for the pack's own idle. Flipping is the only one of
    the sixteen axis-sign choices that lands the hands at shoulder height with
    the feet on the floor.
    """
    out = []
    for bone in clip["bones"]:
        index = min(frame, len(bone["rotation"]) - 1)
        x, y, z, w = bone["rotation"][index]
        position = bone["translation"][min(frame, len(bone["translation"]) - 1)]
        if flip_y:
            y = -y
        out.append((tuple(float(v) for v in position),
                    (float(x), float(y), float(z), float(w)), (1.0, 1.0, 1.0)))
    return out


def rotation_degrees(m):
    """Angle of a rotation matrix, in degrees."""
    trace = m[0, 0] + m[1, 1] + m[2, 2]
    return float(np.degrees(np.arccos(max(-1.0, min(1.0, (trace - 1.0) / 2.0)))))


def quat_from_matrix(r):
    """Quaternion (x, y, z, w) of the 3x3 rotation part of `r`."""
    trace = r[0, 0] + r[1, 1] + r[2, 2]
    if trace > 0.0:
        s = np.sqrt(trace + 1.0) * 2.0
        w = 0.25 * s
        x = (r[2, 1] - r[1, 2]) / s
        y = (r[0, 2] - r[2, 0]) / s
        z = (r[1, 0] - r[0, 1]) / s
    elif r[0, 0] > r[1, 1] and r[0, 0] > r[2, 2]:
        s = np.sqrt(1.0 + r[0, 0] - r[1, 1] - r[2, 2]) * 2.0
        w = (r[2, 1] - r[1, 2]) / s
        x = 0.25 * s
        y = (r[0, 1] + r[1, 0]) / s
        z = (r[0, 2] + r[2, 0]) / s
    elif r[1, 1] > r[2, 2]:
        s = np.sqrt(1.0 + r[1, 1] - r[0, 0] - r[2, 2]) * 2.0
        w = (r[0, 2] - r[2, 0]) / s
        x = (r[0, 1] + r[1, 0]) / s
        y = 0.25 * s
        z = (r[1, 2] + r[2, 1]) / s
    else:
        s = np.sqrt(1.0 + r[2, 2] - r[0, 0] - r[1, 1]) * 2.0
        w = (r[1, 0] - r[0, 1]) / s
        x = (r[0, 2] + r[2, 0]) / s
        y = (r[1, 2] + r[2, 1]) / s
        z = 0.25 * s
    return (float(x), float(y), float(z), float(w))


def poses(clip, frame=0, joints=71):
    """A clip frame in the avatar_pose tuple form: (position, quaternion, scale).

    The matrices are the joints' own local rotations, so the position stays zero
    and avatar_pose's `delta` mode puts the rotation on top of the bind offset -
    a joint that does not move in the clip keeps its bind transform exactly.
    Root motion, when a clip has it, rides in the root matrix's bottom row.

    XNA's Matrix multiplies row vectors, so the rotation to apply here is the
    transpose of the stored one - the conjugate quaternion. Getting that wrong is
    visible rather than subtle: on frame 0 of `Idle` the wrists sit at y 1.235
    (arms overhead) as stored and 0.670 transposed, while the pack's own idle clip
    puts them at 0.642.
    """
    frames = clip["frames"]
    index = max(0, min(frame, len(frames) - 1))
    data = frames[index][1]
    out = []
    for joint in range(joints):
        matrix = data.get(joint)
        if matrix is None:
            out.append(((0.0, 0.0, 0.0), (0.0, 0.0, 0.0, 1.0), (1.0, 1.0, 1.0)))
            continue
        x, y, z, w = quat_from_matrix(matrix[:3, :3])
        out.append((tuple(float(v) for v in matrix[3, :3]),
                    (-x, -y, -z, w), (1.0, 1.0, 1.0)))
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("clip", nargs="?", default=DEFAULT)
    parser.add_argument("--joints", default="",
                        help="comma separated joint indices to report")
    args = parser.parse_args()

    clip = read_clip(args.clip)
    frames = clip["frames"]
    print("%s: %r, %.3f s, %d frames, %d joints, %d records%s"
          % (args.clip, clip["name"], clip["duration"], len(frames),
             len(clip["joints"]), clip["records"],
             ", carries root motion" if clip["moved"] else ""))
    if clip["end"] < clip["size"] - 8:
        print("  warning: walk ended at %d of %d bytes"
              % (clip["end"], clip["size"]))
    wanted = [int(v) for v in args.joints.split(",") if v.strip()]
    if wanted:
        for joint in wanted:
            angles = [rotation_degrees(f[joint]) for _, f in frames if joint in f]
            if angles:
                print("  joint %2d: %5.1f deg mean, %5.1f max over %d frames"
                      % (joint, sum(angles) / len(angles), max(angles),
                         len(angles)))


if __name__ == "__main__":
    main()
