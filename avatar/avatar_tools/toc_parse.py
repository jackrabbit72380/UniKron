#!/usr/bin/env python3
"""Read AvatarAssetPack.toc, the avatar asset catalogue shipped with both
avatareditor builds (nxe2008 and metro2010, byte-identical).

Format, as recovered here:

  * The file is an index followed by the asset blobs.
  * Every blob starts with the ASCII magic "STRB", then u16 version (1) and
    u16 0x59bd. The same header opens every *.AvatarAnimation file, so STRB is
    the shared body/animation record format, not a .toc-only wrapper.
  * The index is a fixed-stride array of 0xf8-byte records starting at 0xe0,
    one per asset, each holding:
        +0x00  u32                reserved
        +0x04  13 x u32           name pointer, one slot per language
        +0x38  u32 blob offset     absolute, points at the "STRB" magic
        +0x3c  u32 blob size       exact, the next blob starts right after it
        +0x40  u32 count
        +0x44  u32 packed flags
        +0x48..+0xf7               zero padding
  * Name pointers are absolute offsets into a UTF-16 string table that sits
    between the index and the first blob (around 0x4da00). The asset names are
    big-endian UTF-16 (`00 4d 00 61` = "Ma"); a second, little-endian table
    further in holds localised product names, which is why the pack carries
    French/German/Spanish/Portuguese/Russian/Japanese text. Both are
    NUL-terminated.

Nothing here interprets the blob bodies: they are mesh/animation records whose
layout needs the engine that consumed them (see xui_parse.py, which documents
why that engine is not present in these files).

Usage:
    python3 toc_parse.py AvatarAssetPack.toc                 # summary
    python3 toc_parse.py AvatarAssetPack.toc --json out.json # full manifest
    python3 toc_parse.py AvatarAssetPack.toc --extract dir   # write blobs
"""

import argparse
import json
import os
import re
import struct
import sys

MAGIC = b"STRB"


def read_utf16(data, ptr):
    """Decode a NUL-terminated UTF-16 asset name at ptr. The name table is
    big-endian; the localised table further in is little-endian, so try both
    and keep whichever decodes to real text."""
    if not (0 <= ptr < len(data)):
        return ""
    best = ""
    for encoding in ("utf-16-be", "utf-16-le"):
        text = data[ptr:ptr + 200].decode(encoding, "replace")
        text = text.split("\x00")[0]
        text = "".join(ch for ch in text if ch.isprintable())
        if len(text) > len(best):
            best = text
    return best.strip()


def parse(path):
    data = open(path, "rb").read()
    blobs = [m.start() for m in re.finditer(re.escape(MAGIC), data)]
    if not blobs:
        raise SystemExit("no STRB blobs found: is this an AvatarAssetPack.toc?")

    first = blobs[0]
    blobset = set(blobs)
    assets, unresolved = [], 0
    record, base, stride = 0x38, 0xE0, 0xF8

    rec = base
    while rec + record + 16 <= first:
        ptrs = struct.unpack(">13I", data[rec + 4:rec + 0x38])
        off, size, count, flags = struct.unpack(">IIII", data[rec + record:rec + record + 16])
        if off not in blobset:
            rec += stride
            continue

        names = []
        for ptr in ptrs:
            if not (0x1000 < ptr < first):
                continue
            s = read_utf16(data, ptr)
            if s and s not in names:
                names.append(s)
        if not names:
            unresolved += 1

        # The loader (`LoadAssetPackFromMemoryV2`, 0x140dbcbe0) puts the record's
        # real start 0xb8 before the anchor used above; from there it copies an
        # id, three bytes, a 145-byte field, a u32, two 16-byte component records
        # and the 13 language pointers. The component records are what a blend
        # shape refers to, so they are worth keeping: each is
        # { u32, u16, u16, 8-byte GUID } stored verbatim, not byte-swapped.
        start = rec - 0xB8
        assets.append({
            "name": names[0] if names else None,
            "names": names,
            "offset": off,
            "size": size,
            "count": count,
            "flags": "0x%08x" % flags,
            "id": struct.unpack_from(">I", data, start)[0],
            "kind": tuple(data[start + 4:start + 7]),
            "detail": struct.unpack_from(">I", data, start + 0x98)[0],
            "component": data[start + 0x9C:start + 0xAC].hex(),
            "component2": data[start + 0xAC:start + 0xBC].hex(),
        })
        rec += stride

    return data, assets, unresolved


def summarise(assets, path, unresolved):
    total = sum(a["size"] for a in assets)
    named = [a for a in assets if a["name"]]
    print("%s" % os.path.basename(path))
    print("  assets        %d" % len(assets))
    print("  named         %d" % len(named))
    print("  unresolved    %d" % unresolved)
    print("  blob bytes    %d" % total)

    langs = {}
    for a in assets:
        langs[len(a["names"])] = langs.get(len(a["names"]), 0) + 1
    print("  locales       %s" % ", ".join("%d names x%d" % (v, k) for k, v in sorted(langs.items(), reverse=True)[:5]))

    groups = {}
    for a in named:
        key = a["name"].split()[0].rstrip(":")
        groups.setdefault(key, []).append(a)
    print("\n  %-14s %5s %10s" % ("prefix", "count", "bytes"))
    for key, items in sorted(groups.items(), key=lambda kv: -len(kv[1]))[:14]:
        print("  %-14s %5d %10d" % (key[:14], len(items), sum(x["size"] for x in items)))

    print("\n  first 12 assets:")
    for a in assets[:12]:
        print("    0x%07x %7d  %s" % (a["offset"], a["size"], a["name"] or "<unresolved>"))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("toc")
    ap.add_argument("--json", metavar="PATH", help="write the full manifest here")
    ap.add_argument("--extract", metavar="DIR", help="write each STRB blob into DIR")
    args = ap.parse_args()

    data, assets, unresolved = parse(args.toc)
    summarise(assets, args.toc, unresolved)

    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump({"source": os.path.basename(args.toc),
                       "assets": assets}, fh, indent=1)
        print("\nmanifest -> %s" % args.json)

    if args.extract:
        os.makedirs(args.extract, exist_ok=True)
        for a in assets:
            label = (a["name"] or "asset").replace(os.sep, "_")[:60]
            safe = re.sub(r"[^A-Za-z0-9._ -]", "_", label).strip() or "asset"
            with open(os.path.join(args.extract, "%05x %s.strb" % (a["offset"], safe)), "wb") as fh:
                fh.write(data[a["offset"]:a["offset"] + a["size"]])
        print("blobs -> %s (%d files)" % (args.extract, len(assets)))


if __name__ == "__main__":
    main()
