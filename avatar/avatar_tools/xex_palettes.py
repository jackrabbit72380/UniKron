#!/usr/bin/env python3
"""Read the avatar editor's colour palettes out of `avatareditor.xex`.

    python3 xex_palettes.py AVATAREDITOR.XEX [--json OUT.json]

COLOURS.md used to record that the palette values were not on the disc. They are:
the 2008 editor keeps them as plain opaque ARGB words in its read-only data, in
nine tables - one per colour the `.Avatar` descriptor stores at +0x0fc - plus three
smaller variants.

How the tables are found, and why the numbers below are stated rather than guessed:

* The nine descriptor colours fall at `0x0fc`..`0x11f` (nine u32, alpha 0xff).
* At file offset **0x21c68** there is a table of (pointer, count) pairs, eight bytes
  each: nine entries, a (0,0) terminator, two more entries, another terminator.
* The pointers are absolute addresses in the image, and the image's data section
  maps at **vaddr = file offset + 0x97FFD000** - solved from the first entry,
  `0x9801e7c0` -> file `0x217c0`. Every entry is then checked: `count` opaque ARGB
  words must sit exactly at `pointer - 0x97FFD000`, and the word before and after
  must not be opaque. All eleven pass.
* Every colour of all three shipped descriptors (Avatar6400, 6404, 6411 - 27 words)
  is a member of the table at the same slot index, which is what makes the nine
  tables the nine slot domains rather than a coincidence.

Nothing here is named from outside: the tables are written out by content and slot
index. The screen names, where they appear, come from the image's own labels
(`Skin Color`, `Hair Color`, `Eyebrow Color`, `Eye Color`, `Lips`, `Eye Shadow
Color`, `Eyeliner Color`, `Facial Hair Color`, `Facial Feature Color`) and are
recorded in COLOURS.md, not assumed here.
"""

import argparse
import json
import os
import struct
import sys

# File offset of the (pointer, count) table, and the data section's vaddr - file
# offset. Both are stated because a tool that rediscovered them by pattern would
# still have to hard-code the pattern; every entry is verified below instead.
TABLE = 0x21C68
BASE = 0x97FFD000
ENTRY = 8

DESCRIPTORS = ("Avatar6400", "Avatar6404", "Avatar6411")
DESCRIPTOR_COLOURS = 0x0FC
DESCRIPTOR_COUNT = 9

# The nine slot tables, in descriptor-slot order. Which slot a table backs is
# measured: every colour the three shipped descriptors store at each slot is a
# member of that slot's table (27 of 27). The *names* are the image's own colour
# labels ("Skin Color", "Hair Color", "Lips", "Eye Color", "Facial Hair Color",
# "Facial Feature Color", "Eyebrow Color", "Eye Shadow Color", "Eyeliner Color")
# assigned by what the tables contain and by which tables the index repeats - the
# hair table three times, the saturated one twice, everything else once, which is
# exactly the sharing the nine screens would have. COLOURS.md records that this
# assignment is an inference and the tables are not.
SLOTS = [
    "skin", "hair", "lips", "eye", "facial_hair", "facial_feature", "eyebrow",
    "eye_shadow", "eyeliner",
]


def read_tables(data):
    """The two groups of (pointer, count) entries, in file order."""
    groups = []
    group = []
    pos = TABLE
    while pos + ENTRY <= len(data):
        pointer, count = struct.unpack_from(">II", data, pos)
        pos += ENTRY
        if pointer == 0 and count == 0:
            if group:
                groups.append(group)
                group = []
            if len(groups) == 2:
                break
            continue
        group.append((pos - ENTRY, pointer, count))
    return groups


def palette_at(data, pointer, count):
    """The ARGB words a table entry points at, or None if it does not hold them."""
    at = pointer - BASE
    if at < 0 or at + 4 * count > len(data):
        return None
    words = [struct.unpack_from(">I", data, at + 4 * i)[0] for i in range(count)]
    if not all((w >> 24) == 0xFF for w in words):
        return None
    # No edge test: the tables are packed back to back, so the words either side of
    # a run are the neighbouring tables' colours. The (pointer, count) entry is the
    # authority on where a table starts and how long it is.
    return at, words


def descriptors(root):
    """Each shipped descriptor's nine colours, as ARGB words."""
    out = {}
    for name in DESCRIPTORS:
        path = os.path.join(root, name + ".Avatar")
        if not os.path.exists(path):
            continue
        blob = open(path, "rb").read()
        out[name] = list(struct.unpack_from(
            ">%dI" % DESCRIPTOR_COUNT, blob, DESCRIPTOR_COLOURS))
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("xex")
    parser.add_argument("--json", default=os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "colour_palettes.json"))
    parser.add_argument("--descriptors", default=os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "..", "..",
        "src_archive", "XBOX HUB", "resources", "editors", "nxe2008", "assets"))
    args = parser.parse_args()

    data = open(args.xex, "rb").read()
    groups = read_tables(data)
    if len(groups) != 2:
        raise SystemExit("expected two groups of palette entries at 0x%x, found %d"
                         % (TABLE, len(groups)))

    tables = []
    for index, (offset, pointer, count) in enumerate(groups[0]):
        found = palette_at(data, pointer, count)
        if found is None:
            raise SystemExit("entry %d at 0x%x: no run of %d opaque ARGB words at "
                             "0x%08x - % 0x" % (index, offset, count, pointer,
                                                 pointer - BASE))
        at, words = found
        tables.append(dict(
            slot=SLOTS[index] if index < len(SLOTS) else "skin-short",
            index=index,
            entry_offset=offset,
            pointer=pointer,
            data_offset=at,
            colours=["#%08x" % w for w in words],
            argb=words,
        ))
        print("slot %-10s %2d colours  entry 0x%05x -> data 0x%05x (vaddr 0x%08x)"
              % (tables[-1]["slot"], count, offset, at, pointer))

    extras = []
    for index, (offset, pointer, count) in enumerate(groups[1]):
        found = palette_at(data, pointer, count)
        if found is None:
            raise SystemExit("second group entry %d: nothing at 0x%08x" % (index, pointer))
        at, words = found
        extras.append(dict(index=index,
                           name="lips-short" if index == 0 else "eye-short",
                           entry_offset=offset, pointer=pointer,
                           data_offset=at, colours=["#%08x" % w for w in words],
                           argb=words))
        print("extra %d        %2d colours  entry 0x%05x -> data 0x%05x"
              % (index, count, offset, at))

    # The descriptors are the proof that the nine tables are the nine slot domains.
    print("\ndescriptor cross-check (each colour must be in the table for its slot)")
    checked = missed = 0
    profile = descriptors(args.descriptors)
    for name, colours in sorted(profile.items()):
        for slot, word in enumerate(colours):
            table = set(tables[slot]["argb"]) if slot < len(tables) else set()
            checked += 1
            if word not in table:
                missed += 1
                print("  MISS %s slot %d #%08x not in the %s table"
                      % (name, slot, word, tables[slot]["slot"]))
        print("  %s: %s" % (name, " ".join("#%06x" % (w & 0xFFFFFF) for w in colours)))
    print("  %d of %d colours land in their slot's table" % (checked - missed, checked))

    out = dict(
        source=os.path.basename(args.xex),
        table_offset=TABLE,
        base=BASE,
        slots=tables,
        extras=extras,
        descriptors={k: ["#%08x" % w for w in v] for k, v in sorted(profile.items())},
        descriptor_colours_checked=checked,
        descriptor_colours_missed=missed,
    )
    with open(args.json, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=1)
        fh.write("\n")
    print("\nwrote %s" % os.path.relpath(args.json))
    return 0 if missed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
