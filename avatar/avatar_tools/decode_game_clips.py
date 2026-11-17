#!/usr/bin/env python3
"""Decode the avatar-game animation clips out of their XNB files.

The games ship `DNA.Drawing.Animation.AnimationClip` assets (see AVATAR_ARCHIVE.md
for how the layout was first read off `GenericIdle`). This walks a whole folder of
`.xnb` and writes one JSON per clip.

Framing, measured on the Avatar_Games dump (platform byte 'x', Windows):

    uncompressed (flags & 0x80 == 0)   payload starts at 10
    compressed                          u32 @ 6  file size       (little-endian)
                                        u32 @ 10 decompressed   (little-endian)
                                        one byte at 14
                                        LZX from 15, 64 KiB window

Payload: a type-reader table naming the clip's own reader, then

    u8 length + ASCII clip name      ("Take 001" in the first builds read)
    i32 frame count
    i64 duration
    i32 bone count
    per bone: i32 count + count x Vector3 (12 B)   translation
              i32 count + count x Quaternion (16 B) rotation
              i32 count + count x Vector3 (12 B)   scale

The clip name is discovered rather than assumed: any offset where a length byte is
followed by that many printable characters and the next 16 bytes read as a sane
frame count, duration and bone count. That finds the clips the games renamed.
"""

import glob
import json
import os
import struct
import sys

import lzx


def payload(data):
    flags = data[5]
    if flags & 0x80:
        out_len, = struct.unpack_from("<I", data, 10)
        # Two stream starts occur in the shipped files: most begin at 15, but 20 of
        # the 88 carry four extra bytes there and only decode from 19. Try the
        # common case first, then the variant.
        for start in (15, 19):
            try:
                return lzx.decompress(data[start:], out_len, 0x10000)
            except Exception:
                if start == 19:
                    raise
    return data[10:]


def find_clip(p):
    """(name, frame count, duration, bone count, data offset) or None."""
    for i in range(1, len(p) - 24):
        n = p[i - 1]
        if not (3 <= n <= 40):
            continue
        name = p[i:i + n]
        if not all(32 <= c < 127 for c in name):
            continue
        o = i + n
        frames, dur, bones = struct.unpack_from("<iq i", p, o)
        if not (1 <= frames <= 600 and 1 <= dur <= 10 ** 9 and 1 <= bones <= 200):
            continue
        if p.find(b"AnimationClip", 0, i) < 0:
            continue
        return name.decode("ascii"), frames, dur, bones, o + 16
    return None


def read_clip(p, offset, bones):
    out = []
    o = offset
    for _ in range(bones):
        channels = {}
        for label, size, count in (("translation", 12, 3), ("rotation", 16, 4),
                                   ("scale", 12, 3)):
            keys, = struct.unpack_from("<i", p, o)
            o += 4
            if not (0 <= keys <= 600):
                raise ValueError("key count %d out of range" % keys)
            values = []
            for _ in range(keys):
                values.append(list(struct.unpack_from("<%df" % count, p, o)))
                o += size
            channels[label] = values
        out.append(channels)
    return out, o


def main(argv):
    if len(argv) not in (2, 3):
        print(__doc__.strip().splitlines()[0])
        print("usage: decode_game_clips.py SRC_DIR [OUT_DIR]")
        return 2
    source = argv[1]
    out_dir = argv[2] if len(argv) == 3 else "assets/game_clips"
    files = sorted(glob.glob(os.path.join(source, "**", "*.xnb"), recursive=True))
    written = 0
    refused = []
    for path in files:
        data = open(path, "rb").read()
        try:
            p = payload(data)
        except Exception:
            continue
        found = find_clip(p)
        if not found:
            continue
        name, frames, dur, bones, offset = found
        try:
            channels, end = read_clip(p, offset, bones)
        except Exception as error:
            refused.append((os.path.basename(path), str(error)))
            continue
        exact = end == len(p)
        if not exact:
            refused.append((os.path.basename(path), "walk ended %d of %d" % (end, len(p))))
            continue
        # .../<game>/Content/AvatarAnimation[s]/<file>.xnb - three levels up is the
        # game folder. Four was one too many and put every clip in the same
        # output folder, where same-named clips from different games overwrote
        # each other.
        game = os.path.basename(os.path.dirname(os.path.dirname(
            os.path.dirname(path))))
        target = os.path.join(out_dir, game)
        os.makedirs(target, exist_ok=True)
        stem = os.path.splitext(os.path.basename(path))[0]
        with open(os.path.join(target, stem + ".json"), "w") as handle:
            json.dump({
                "source": path,
                "game": game,
                "clip": name,
                "frames": frames,
                "duration": dur,
                "bones": bones,
                "bones_data": channels,
            }, handle)
        written += 1
    print("wrote %d clips to %s" % (written, out_dir))
    if refused:
        print("refused %d:" % len(refused))
        for row in refused[:10]:
            print("   %s: %s" % row)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
