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
    then the stream. The stream is **XCompress framing, not a bare LZX stream**:
    a run of 32 KiB output frames, each introduced by a 16-bit big-endian
    compressed length, or by 0xFF, a 16-bit output length and a 16-bit compressed
    length when the frame is short (the last one always is). Each frame restarts
    the LZX bitstream at a byte boundary while the window and the repeated offsets
    carry on, which is what MonoGame's `LzxDecoderStream` does by seeking back to
    the frame start after every call. Stripping the prefixes and decoding frame by
    frame (`lzx.decompress_frames`) reads every compressed file in the archive.

    All 185 `.xnb` in `src_archive/avatar-games` now inflate: 39 uncompressed, 143
    compressed version 5, 3 compressed version 4. An earlier note here said 92
    failed and blamed the window size; that was this missing framing.

    Reading the inflated clip is a separate matter, and both layouts are now read:
    42 clips are Hazzah's `CustomAvatarAnimationData` (`read_clip`) and 143 are
    `DNA.Drawing.Animation.AnimationClip+Reader` (DNA.Common, `read_dna`). The DNA
    body is a per-bone run of tracks rather than the Hazzah 76-byte keyframe, and
    the archive splits cleanly: 118 clips carry translation, rotation and scale
    per bone, 25 (all of Avatar Connection) carry translation and rotation only.
    """
    data = open(path, "rb").read()
    if data[:4] not in (b"XNBx", b"XNBw", b"XNBm"):
        raise ValueError("not an XNB: %r" % data[:4])
    if not data[5] & 0x80:
        return data
    size = struct.unpack_from("<I", data, 10)[0]
    # The compressed body is XCompress framing, not a bare LZX stream: a sequence
    # of 32 KiB output frames, each preceded by a 16-bit big-endian compressed
    # length, or by 0xFF and then a 16-bit output length, a 16-bit compressed
    # length when the frame is short (the last one always is). Each frame is its
    # own LZX stream, so stripping the prefixes and joining the payloads gives one
    # stream that decodes frame by frame - which is why every plain offset failed
    # before: the first two bytes of a frame are a length, not a block header.
    frames, produced = _deframe(data[14:])
    last = None
    if produced == size:
        for window in (0x10000, 0x8000):
            try:
                raw = lzx.decompress_frames(frames, window)
            except lzx.LzxError as error:
                last = error
                continue
            if len(raw) == size:
                return raw
    joined = b"".join(payload for payload, _ in frames)
    for payload, window in ((joined, 0x10000), (data[15:], 0x10000),
                            (data[14:], 0x10000), (data[15:], 0x8000)):
        try:
            raw = lzx.decompress(payload, size, window)
        except lzx.LzxError as error:
            last = error
            continue
        if len(raw) == size:
            return raw
    # The version 4 files (Avatar Boogie's five dances, Avatar Avenue's three
    # clips) read through the same framing; nothing in the archive reaches here.
    raise ValueError("compressed XNB this decoder cannot read yet (%s)" % last)


def _deframe(data):
    """Split XCompress's frames: (payload, output size) pairs, and the total they claim.

    A frame is a 16-bit big-endian compressed length and decodes to 0x8000 bytes,
    unless the first byte is 0xFF: then the low byte just read is the high byte of
    a 16-bit output length followed by a 16-bit compressed length. The last frame
    is always short, so it always takes the 0xFF form.
    """
    frames = []
    pos = 0
    produced = 0
    while pos + 2 <= len(data):
        high, low = data[pos], data[pos + 1]
        pos += 2
        if high == 0xFF:
            if pos + 3 > len(data):
                break
            output = (low << 8) | data[pos]
            length = (data[pos + 1] << 8) | data[pos + 2]
            pos += 3
        else:
            output = 0x8000
            length = (high << 8) | low
        if length == 0 or output == 0 or pos + length > len(data):
            break
        frames.append((data[pos:pos + length], output))
        pos += length
        produced += output
    return frames, produced


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


_TRACKS_THREE = (("translation", 12), ("rotation", 16), ("scale", 12))
_TRACKS_TWO = (("translation", 12), ("rotation", 16))


def _dna_tracks(data, pos, bones, tracks):
    """Walk `bones` bone blocks of `tracks`, or None if the body does not fit.

    Each track is `i32 count` then that many records: 12 bytes for a Vector3
    (translation, scale) and 16 for a Quaternion (rotation).
    """
    out = []
    for _ in range(bones):
        bone = {}
        for name, stride in tracks:
            if pos + 4 > len(data):
                return None
            count = struct.unpack_from("<i", data, pos)[0]
            pos += 4
            if not 0 <= count <= len(data) // stride or pos + stride * count > len(data):
                return None
            width = stride // 4
            bone[name] = np.array(
                struct.unpack_from("<%df" % (width * count), data, pos),
                dtype=np.float64).reshape(-1, width)
            pos += stride * count
        out.append(bone)
    return out, pos


def read_dna(path):
    """Read a `DNA.Drawing.Animation.AnimationClip` (the Digital DNA games).

    Payload, little endian:

        u8   1              - a byte, 1 in all 143 clips of this archive
        u8   name length + the name, ASCII (`Stand0`, `Take 001`)
        i32  frames a second (30 everywhere here)
        i64  duration in TimeSpan ticks (53,333,334 = 5.333 s)
        i32  bone count (71 everywhere)
        then, per bone, the tracks in order `i32 count` + that many records:
             count x Vector3     (12 bytes)  translation
             count x Quaternion  (16 bytes)  rotation
             count x Vector3     (12 bytes)  scale, only in some clips

    The first `i32` of the body is the root bone's translation count, not a frame
    count: `Stand0` stores 162 there for 160 frames, `Tilt` 1 for 100. An earlier
    note in `DECOMPILE.md` read it as frames + 2 because the root of the 36 named
    clips carries two keys beyond the frames; `Tilt` disproves that.

    **The track count differs by game and is not flagged anywhere in the file.**
    The 118 clips from Avatar Laser Wars 2 and Avatar Warfare write three tracks a
    bone; the 25 from Avatar Connection write two. Nothing else in the archive has
    the shape, so the walk itself decides: the track count whose 71 bones end
    exactly on the last byte is the one, and no clip fits both (measured on all
    143). Where a scale track exists it is a no-op - all 8,378 of them in the
    archive hold (1, 1, 1) - so the two groups decode the same.

    Returns the bones in file order, each a dict of whichever tracks it has.
    """
    data = load(path)
    pos = read_type_readers(data)["payload"]
    flag = data[pos]
    pos += 1
    length = data[pos]
    pos += 1
    name = data[pos:pos + length].decode("ascii", "replace")
    pos += length
    fps = struct.unpack_from("<i", data, pos)[0]
    pos += 4
    ticks = struct.unpack_from("<q", data, pos)[0]
    pos += 8
    bone_count = struct.unpack_from("<i", data, pos)[0]
    pos += 4
    start = pos

    for tracks in (_TRACKS_THREE, _TRACKS_TWO):
        walked = _dna_tracks(data, start, bone_count, tracks)
        if walked and walked[1] == len(data):
            bones, pos = walked
            break
    else:
        raise ValueError(
            "%s: neither a 3-track nor a 2-track body of %d bones fits %d bytes"
            % (path, bone_count, len(data) - start))

    return dict(name=name, flag=flag, fps=fps, tracks=len(tracks),
                duration=ticks / 1e7, bones=bones,
                joints=list(range(bone_count)), end=pos, size=len(data),
                records=sum(len(b.get("rotation", ())) for b in bones))


def dna_poses(clip, frame=0, flip_y=False):
    """A DNA clip as avatar_pose tuples, one bone per rig joint.

    The rotation channel is a local rotation per bone, so the bind offsets from
    the skeleton supply placement and `delta` mode puts the rotation on top -
    bones the clip leaves at identity simply stay at bind.

    The quaternions are used as stored. Signs were tried all eight ways against
    two measurements that a right hand cannot fake at once - fingertip distance
    from the wrist, and the finger heights - and only the plain form curls the
    fingers: on `Laser Wars 2/intro_pose05` the fingertips sit at 0.33 of their
    bind distance with 0.021 of splay, against 0.49 and 0.026 for the best
    flipped variant, whose fingers fan apart instead of closing. `flip_y` is kept
    only so the wrong reading can be reproduced and seen.
    """
    out = []
    for bone in clip["bones"]:
        rotation = bone.get("rotation")
        translation = bone.get("translation")
        if rotation is None or not len(rotation):
            out.append(((0.0, 0.0, 0.0), (0.0, 0.0, 0.0, 1.0), (1.0, 1.0, 1.0)))
            continue
        index = min(frame, len(rotation) - 1)
        x, y, z, w = rotation[index]
        if translation is not None and len(translation):
            position = translation[min(index, len(translation) - 1)]
        else:
            position = (0.0, 0.0, 0.0)
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

    head = read_type_readers(load(args.clip))
    if "DNA" in head["readers"][0][0]:
        clip = read_dna(args.clip)
        print("%s: %r, %.3f s at %d fps, %d joints, %d rotation keys, %d tracks"
              % (args.clip, clip["name"], clip["duration"], clip["fps"],
                 len(clip["bones"]), clip["records"], clip["tracks"]))
        wanted = [int(v) for v in args.joints.split(",") if v.strip()]
        for joint in wanted:
            rotation = clip["bones"][joint].get("rotation")
            if rotation is None or not len(rotation):
                continue
            angles = [float(np.degrees(2.0 * np.arccos(min(1.0, abs(q[3])))))
                      for q in rotation]
            print("  joint %2d: %5.1f deg mean, %5.1f max over %d keys"
                  % (joint, sum(angles) / len(angles), max(angles), len(angles)))
        return

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
