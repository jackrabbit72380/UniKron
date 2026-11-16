"""Read a `.Avatar` descriptor: the colours and the equipped item list.

The 1,000-byte `Avatar####.Avatar` files that ship with the avatar games are the
description the console hands the avatar system. Layout, from Avatar6400:

    +0x000  4 x u32     header words (0, 0xbf or 0xbf80, 0x10)
    +0x010  15 x 16 B   equipped-item entries
    +0x100  8 x 4 B     colour slots, stored as A, R, G, B (A is always 0xff)
    +0x120  ...         two more words, then zero padding to 1,000

Each entry is two u16, then an 8-byte id that repeats in every entry and every
file, then a word. The word's byte order is not settled - 0x0800 and 0x2000 show
up both ways round - so the entries are reported verbatim rather than guessed at.

The colours are the interesting part: `6e5326` is the hair colour the bake
scripts had been using, which is where it came from.

    python3 avatar_desc.py Avatar6400.Avatar [...]
"""

import argparse
import struct
import sys

COLOUR_OFFSET = 0x100
COLOUR_COUNT = 8
ENTRY_OFFSET = 0x010
ENTRY_SIZE = 16
ENTRY_COUNT = 15

SLOTS = {
    0x0001: "glasses", 0x0002: "wristwear", 0x0004: "earrings", 0x0008: "rings",
    0x0100: "head", 0x0200: "body", 0x0400: "hair", 0x0800: "torso",
    0x1000: "legs", 0x2000: "feet", 0x4000: "hat", 0x8000: "gloves",
}


def read(path):
    data = open(path, "rb").read()
    if len(data) < COLOUR_OFFSET + 4 * COLOUR_COUNT:
        raise SystemExit("%s is too short to be an .Avatar" % path)

    header = list(struct.unpack_from("<4I", data, 0))

    entries = []
    for i in range(ENTRY_COUNT):
        at = ENTRY_OFFSET + i * ENTRY_SIZE
        if at + ENTRY_SIZE > len(data):
            break
        a, b = struct.unpack_from("<HH", data, at)
        ident = data[at + 4:at + 12].hex()
        word = data[at + 12:at + 16].hex()
        entries.append({"id": a, "kind": b, "ident": ident, "word": word})

    colours = []
    for i in range(COLOUR_COUNT):
        at = COLOUR_OFFSET + 4 * i
        alpha, r, g, b = data[at], data[at + 1], data[at + 2], data[at + 3]
        colours.append({"argb": "%02x%02x%02x%02x" % (alpha, r, g, b),
                        "rgb": "#%02x%02x%02x" % (r, g, b), "alpha": alpha})

    return {"header": ["0x%08x" % w for w in header], "entries": entries,
            "colours": colours}


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("files", nargs="+")
    args = ap.parse_args()
    for path in args.files:
        doc = read(path)
        print(path)
        print("  header:", " ".join(doc["header"]))
        for i, entry in enumerate(doc["entries"]):
            if not any(entry["ident"].strip("0")) and entry["word"] == "00000000":
                continue
            print("  entry %d  id=0x%04x kind=0x%04x word=%s"
                  % (i, entry["id"], entry["kind"], entry["word"]))
        print("  colours:", " ".join(c["rgb"] for c in doc["colours"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
