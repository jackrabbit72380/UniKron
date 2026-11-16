"""Read a `.Avatar` descriptor: the shape overrides, the colours and the looks.

The 1,000-byte `Avatar####.Avatar` files that ship with the avatar games are the
description the console hands the avatar system. Reading Avatar6400 byte by byte
gives this layout, and every claim below was checked against that file:

    +0x000  4 x u32        header; as float32 the first two are -0.5
    +0x010  n x record     shape overrides, variable length (see below)
    +0x0f8  9 x ARGB       colours, alpha 0xff
    +0x120  6 x record     look 1: which item sits in which slot
    +0x300  ...            look 2, same record shape, cut short in this sample

An override record is `u16 id, u16 class, 8-byte GUID`, then a 4-byte word; some
carry one or more extra 4-byte words before the next record. A look record is
`u32 slot, u16 id, u16 class, 8-byte GUID, u32 slot` - the slot is written twice,
once before the item and once after it.

Both id fields are **big-endian u16** and they index the asset catalog, which is
how the items below are named: id 0x01b2 = 434 = `Short with Left Curls (Hat)`,
0x0058 = 88 = `Jacket with Sweater`, 0x0090 = 144 = `Male Flower Print Flares`,
0x0031 = 49 = `Grunge Trainers`. The `class` field matches the pack's own class
byte: 1 = model, 3 = shape override.

The slot numbers are the ones those items landed in, so they are evidence rather
than a guess: `MaleBody` in 2, `Head` in 1, a hat in 4, a jacket in 8, trousers in
0x10, shoes in 0x20.

    python3 avatar_desc.py descriptors/Avatar6400.Avatar [...]
"""

import argparse
import json
import os
import struct
import sys

GUID = bytes.fromhex("c1c8f109a19cb2e0")
HERE = os.path.dirname(os.path.abspath(__file__))

# Slot numbers as they appear in look records, read off the items found in them.
SLOTS = {
    0x01: "head", 0x02: "body", 0x04: "hat", 0x08: "torso",
    0x10: "legs", 0x20: "feet", 0x40: "hair", 0x80: "gloves",
}

# The pack's own class byte, from the metadata block of each asset.
CLASSES = {0: "animation", 1: "model", 2: "texture", 3: "shape-overrides"}


def _catalog_names():
    path = os.path.join(HERE, "avatar-assets.json")
    if not os.path.exists(path):
        return []
    with open(path, "r", encoding="utf-8") as fh:
        return [a["name"] for a in json.load(fh)["assets"]]


def _colour_offset(data):
    """First run of nine ARGB values that all carry alpha 0xff."""
    for off in range(0x10, len(data) - 36):
        if data[off] != 0xFF:
            continue
        if all(data[off + 4 * i] == 0xFF for i in range(9)):
            return off
    return -1


def _name(names, ident):
    return names[ident] if 0 <= ident < len(names) else "id %d" % ident


def read(path, names=None):
    data = open(path, "rb").read()
    if names is None:
        names = _catalog_names()

    header = struct.unpack_from("<4I", data, 0)
    colours_at = _colour_offset(data)
    if colours_at < 0:
        raise SystemExit("%s has no colour table; not an .Avatar" % path)

    guids = [p for p in range(len(data)) if data[p:p + 8] == GUID]

    overrides = []
    for pos in guids:
        if pos >= colours_at:
            continue
        at = pos - 4
        ident, cls = struct.unpack_from(">HH", data, at)
        # The word after the GUID, and any further words before the next record.
        overrides.append({"id": ident, "class": cls, "name": _name(names, ident),
                          "at": at})

    colours = []
    for i in range(9):
        at = colours_at + 4 * i
        a, r, g, b = data[at], data[at + 1], data[at + 2], data[at + 3]
        colours.append({"argb": "%02x%02x%02x%02x" % (a, r, g, b),
                        "rgb": "#%02x%02x%02x" % (r, g, b), "alpha": a})

    looks = []
    for pos in guids:
        if pos < colours_at:
            continue
        slot, ident, cls = struct.unpack_from(">IHH", data, pos - 8)
        after = struct.unpack_from(">I", data, pos + 8)[0]
        # The slot is written on both sides of the item - before it plainly, and
        # after it shifted up by 16 bits (`00020000` for slot 2). A record where
        # the two disagree is not one of these records.
        if slot != (after >> 16):
            continue
        looks.append({"slot": slot, "slot_name": SLOTS.get(slot, "0x%02x" % slot),
                      "id": ident, "class": cls, "name": _name(names, ident),
                      "at": pos - 8})

    return {"path": path, "header": ["0x%08x" % w for w in header],
            "colours_at": colours_at, "overrides": overrides,
            "colours": colours, "looks": looks}


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("files", nargs="+")
    ap.add_argument("--json", action="store_true", help="emit as JSON")
    args = ap.parse_args()

    out = []
    for path in args.files:
        doc = read(path)
        out.append(doc)
        if args.json:
            continue
        print(path)
        print("  header:", " ".join(doc["header"]),
              "  colours at 0x%x" % doc["colours_at"])
        print("  overrides (%d):" % len(doc["overrides"]))
        for o in doc["overrides"]:
            print("    %-34s class %d (%s)"
                  % (o["name"], o["class"], CLASSES.get(o["class"], "?")))
        print("  colours:", " ".join(c["rgb"] for c in doc["colours"]))
        print("  looks (%d):" % len(doc["looks"]))
        for look in doc["looks"]:
            print("    %-7s %-34s class %d"
                  % (look["slot_name"], look["name"], look["class"]))

    if args.json:
        print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
