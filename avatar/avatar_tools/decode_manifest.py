"""Read an `avatar_manifest.bin` and say which pack assets it wears.

The editor's save, recovered from a real profile in `%APPDATA%\\XBOX HUB\\
avatar profiles`: 1000 bytes, every integer big-endian like the pack, and every
outfit choice a 16-byte record of the same GUID family the pack's index uses:

    +0x000  u32     0
    +0x004  f32     two settings, -0.5 -0.5 on all three stock avatars
    +0x008  f32
    +0x00c  8 x 16  face slots: {u32 slot, u16 asset index, u16 kind, GUID}
    +0x08c  f32     1.0
    +0x090  108     zero
    +0x0fc  8 x u32 eight ARGB colours, alpha 0xff
    +0x120  1 x 32  body record, then 3 zero words
    +0x140  1 x 32  head record, then 3 zero words
    +0x160  13 x 32 worn items; a record is 16 bytes, then three zero words
    +0x300  4 x 32  a second copy of the last four worn items
    +0x380  16      trailer, `b13ebabe babebabe` then two more words

`u16 asset index` is the position in the pack's parsed asset list, so the name
comes straight out of `toc_parse`. The slot word is a bit: 1 head, 2 body, 4
hair, 8 shirt, 0x10 trousers, 0x20 shoes, and the larger ones are the accessory
and decal groups. 0x208 is not one bit - it is 0x200|8, a shirt in the outer
layer.

    python3 decode_manifest.py ../../avatarAPPDATA/avatar/profiles/*/avatar_manifest.bin
"""

import argparse
import json
import os
import struct
import sys

import toc_parse

HERE = os.path.dirname(os.path.abspath(__file__))
PACK = os.path.join(HERE, "..", "..", "..", "src_archive", "XBOX HUB", "resources",
                    "editors", "metro2010", "assets", "AvatarAssetPack.toc")
FAMILY = bytes.fromhex("c1c8f109a19cb2e0")
SLOTS = {1: "head", 2: "body", 4: "hair", 8: "shirt", 0x10: "trousers",
         0x20: "shoes", 0x8000: "face decal", 0x2000: "eye shadow",
         0x4000: "eye shadow", 0x10000: "face", 0x80000: "outer top",
         0x100000: "ears", 0x200000: "inner top", 0x208: "shirt (outer)"}


def records(blob, start, count, stride):
    for i in range(count):
        at = start + i * stride
        rec = blob[at:at + 16]
        if len(rec) < 16 or rec[8:] != FAMILY:
            return
        slot, index, kind = struct.unpack(">IHH", rec[:8])
        yield at, slot, index, kind


def decode(path, names):
    blob = open(path, "rb").read()
    if len(blob) != 1000:
        raise SystemExit("%s: %d bytes, expected 1000" % (path, len(blob)))
    a, b = struct.unpack_from(">ff", blob, 4)
    out = {"file": os.path.basename(os.path.dirname(path)), "size": len(blob),
           "settings": [a, b], "colours": [], "worn": [], "face": [],
           "body": [], "head": []}

    for label, start, count, stride in (("face", 0x0C, 8, 0x10),
                                        ("body", 0x120, 1, 0x20),
                                        ("head", 0x140, 1, 0x20),
                                        ("worn", 0x160, 13, 0x20),
                                        ("again", 0x300, 4, 0x20)):
        for at, slot, index, kind in records(blob, start, count, stride):
            name = names[index] if index < len(names) else "?"
            row = {"where": label, "at": "0x%03x" % at, "slot": "0x%x" % slot,
                   "slot_name": SLOTS.get(slot, "?"), "index": index,
                   "kind": kind, "name": name}
            out["worn" if label in ("worn", "again") else label].append(row)

    for i in range(8):
        argb = blob[0x0FC + i * 4]
        out["colours"].append({
            "index": i,
            "hex": blob[0x0FC + i * 4:0x100 + i * 4].hex(),
            "rgba": [blob[0x0FD + i * 4], blob[0x0FE + i * 4],
                     blob[0x0FF + i * 4], argb],
        })
    out["one"] = struct.unpack_from(">f", blob, 0x8C)[0]
    out["trailer"] = blob[0x380:0x390].hex()
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("manifests", nargs="+")
    ap.add_argument("--pack", default=PACK)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    _, assets, _ = toc_parse.parse(args.pack)
    names = [a["name"] or "?" for a in assets]
    reports = [decode(p, names) for p in args.manifests]
    if args.json:
        print(json.dumps(reports, indent=1))
        return 0

    for report in reports:
        print("== %s  %d bytes  settings %s  one %g"
              % (report["file"], report["size"],
                 " ".join("%g" % v for v in report["settings"]), report["one"]))
        for row in report["face"]:
            print("   face  +%s  %-12s idx %4d kind %d  %s"
                  % (row["at"], row["slot_name"], row["index"], row["kind"], row["name"]))
        for key in ("body", "head"):
            for row in report[key]:
                print("   %-5s +%s  idx %4d kind %d  %s"
                      % (key, row["at"], row["index"], row["kind"], row["name"]))
        for row in report["worn"]:
            print("   worn  +%s  %-12s idx %4d kind %d  %s"
                  % (row["at"], row["slot_name"], row["index"], row["kind"], row["name"]))
        print("   colours  %s" % " ".join(c["hex"] for c in report["colours"]))
        print("   trailer  %s" % report["trailer"])
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
