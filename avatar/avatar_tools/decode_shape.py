#!/usr/bin/env python3
"""Decode block 4 (ShapeOverrides) of avatar pack assets.

The layout below is read straight out of avatareditor.exe, not guessed. Two
functions parse the block sequentially off the same bitstream:

    0x140dbe520   section A      -> out: u32 value, 16-byte record, vector<u32>
    0x140dbe760   section B      -> out: u32 value, 16-byte record, vector<32B>

and both are called from 0x140dbe9d0 with a stream built by 0x140dbe390
(buffer at +0, bit position at +8, bit length at +0x10; 0x140dbe9d0 passes
`len << 3`, which is why the length is in bits).

Section header, identical in both sections, all fields bit-packed little-endian
except the record (which is byte-aligned and byte-swapped, so it reads as the
raw descriptor):

    32 bits   entry count
    32 bits   a u32 written to out+0 (5076 / 33792 on every item checked)
    128 bits  the 16-byte component descriptor: 32 bits, 16, 16, 8 x 8
    32 bits   base
    32 bits   index bit width

Section A then emits `count` u32s, each `base + read(width)`.

Section B emits `count` 32-byte entries (the stride in 0x140dbe760 is 0x20).
Its parameter block comes from 0x140dbecb0:

    32 bits   base 0            -> +0x04
    32 bits   width 0           -> +0x08
    32 bits   b (a float)       -> +0x0c, scaled into +0x1c/+0x20/+0x24
    32 bits   offset 0          -> +0x10  (float)
    32 bits   offset 1          -> +0x14  (float)
    32 bits   offset 2          -> +0x18  (float)
    6 bits x3 widths            -> +0x28, +0x29, +0x2a
    64 bits   base 1 / width 1  -> +0x2c / +0x30
    64 bits   base 2 / width 2  -> +0x34 / +0x38
    64 bits   base 3 / width 3  -> +0x3c / +0x40
    64 bits   base 4 / width 4  -> +0x44 / +0x48

with scale 0 = b*2, scale 1 = b*2*sqrt(2/3), scale 2 = b*sqrt(3), and one entry
from 0x140dbee70 being:

    out+0x00  base 0 + read(width 0)
    out+0x04  offset 0 + scale 0 * read(width 1)
    out+0x08  offset 1 + scale 1 * read(width 2)
    out+0x0c  offset 2 + scale 2 * read(width 3)   (plus a bias when the read's
              low bit is set: scale 2 * 0.3333333)
    out+0x10  base 1 + read(width 1)   (sign-extended from 22 bits when param[0]==1)
    out+0x14  base 2 + read(width 2)
    out+0x18  base 3 + read(width 3)
    out+0x1c  base 4 + read(width 4)

Run on Large Chin this decoder consumes the payload **exactly**: entries start at
bit 914, there are 110 of them, and it finishes on bit 12904 of 12904. Soft Nose
finishes on 8948 of 8952. That is the strongest structural check available without
the retail applier, and it means the field set is complete - but three things are
still unverified, and this tool reports them instead of hiding them:

  * the index field. With base 0 / width 16 the values run past 64k, but the Head
    mesh has 648 vertices, so the u32 at out+0x00 is either not a vertex index or
    is masked downstream. Do not treat these as vertex indices yet.
  * b is 7.071e-06 (sqrt(0.5)*1e-5) on all five shapes checked, i.e. it does not
    vary per shape the way the offsets do. Either it is a fixed quantisation
    constant or the field is not b at all.
  * the last four base/width pairs decode to implausible values on every item
    checked (a base of 78 million, two zero widths, a base near 2^32). Their
    widths do add up so the payload is consumed exactly, but that is arithmetic
    agreeing with a coincidence, not proof: treat the final 51 bits of each entry
    as unconfirmed.

What IS solid: the section layout, the descriptor, the parameter block, the
32-byte entry stride, and the offsets - which land at the affected region
(about -0.11, 1.12, -0.01 for the chin, 1.21 for the nose and ears) on a
1.75 m avatar.

Usage:
    python3 decode_shape.py "Large Chin" [--entries 4]
    python3 decode_shape.py --all
"""
import argparse
import struct
import sys

import avatar_mesh as am
import bitstream

PACK = "../../../src_archive/XBOX HUB/resources/editors/metro2010/assets/AvatarAssetPack.toc"


def f32(u):
    return struct.unpack("<f", struct.pack("<I", u & 0xFFFFFFFF))[0]


def read_record(stream, pos):
    """32/16/16/8x8 bits, byte aligned, so this is the raw descriptor."""
    return bitstream.read_record(stream, pos)


def decode(name, pack=PACK, wanted=4):
    index = am.load_pack_index(pack)
    blob = am.asset_bytes(pack, index, name)
    payload = next(p for i, _, _, p in am.strb_blocks(blob) if i == 4)

    pos = 0
    out = {"payload": payload, "name": name}

    # ---- section A (0x140dbe520) -------------------------------------
    count_a, pos = bitstream.read_bits(payload, pos, 32)
    value_a, pos = bitstream.read_bits(payload, pos, 32)
    rec_a, pos = read_record(payload, pos)
    base_a, pos = bitstream.read_bits(payload, pos, 32)
    width_a, pos = bitstream.read_bits(payload, pos, 32)
    entries_a = []
    for _ in range(count_a):
        v, pos = bitstream.read_bits(payload, pos, width_a)
        entries_a.append(base_a + v)

    # ---- section B (0x140dbe760 + 0x140dbecb0) -----------------------
    count_b, pos = bitstream.read_bits(payload, pos, 32)
    value_b, pos = bitstream.read_bits(payload, pos, 32)
    rec_b, pos = read_record(payload, pos)
    base0, pos = bitstream.read_bits(payload, pos, 32)
    width0, pos = bitstream.read_bits(payload, pos, 32)
    b, pos = bitstream.read_bits(payload, pos, 32)
    o = []
    for _ in range(3):
        u, pos = bitstream.read_bits(payload, pos, 32)
        o.append(f32(u))
    w = []
    for _ in range(3):
        v, pos = bitstream.read_bits(payload, pos, 6)
        w.append(v)
    pairs = []
    for _ in range(4):
        base, pos = bitstream.read_bits(payload, pos, 32)
        width, pos = bitstream.read_bits(payload, pos, 32)
        pairs.append((base, width))

    scale = (f32(b) * 2.0, f32(b) * 2.0 * (2.0 / 3.0) ** 0.5, f32(b) * 3.0 ** 0.5)
    start = pos
    entries_b = []
    for _ in range(count_b):
        i0, pos = bitstream.read_bits(payload, pos, width0)
        v1, pos = bitstream.read_bits(payload, pos, w[0])
        v2, pos = bitstream.read_bits(payload, pos, w[1])
        v3, pos = bitstream.read_bits(payload, pos, w[2])
        extra = []
        for base, width in pairs:
            e, pos = bitstream.read_bits(payload, pos, width)
            extra.append(base + e)
        entries_b.append({
            "index": base0 + i0,
            "xyz": (o[0] + scale[0] * v1,
                    o[1] + scale[1] * v2,
                    o[2] + scale[2] * v3),
            "extra": extra,
        })

    out.update({
        "section_a": {"count": count_a, "base": base_a, "width": width_a,
                      "value": value_a, "record": rec_a, "entries": entries_a},
        "section_b": {"count": count_b, "base": base0, "width": width0,
                      "value": value_b, "record": rec_b, "b": f32(b),
                      "offsets": o, "widths": w, "pairs": pairs,
                      "entries": entries_b},
        "start_bit": start,
        "end_bit": pos,
        "bits": len(payload) * 8,
        "_wanted": wanted,
    })
    return out


def show(r):
    a, b = r["section_a"], r["section_b"]
    print("%s: %d-byte block 4" % (r["name"], len(r["payload"])))
    print("  A: count %d, base %d, width %d, value %d, record %08x-%04x-%04x %s"
          % (a["count"], a["base"], a["width"], a["value"],
             a["record"]["slot"], a["record"]["index"], a["record"]["kind"],
             a["record"]["guid"].hex()))
    print("  B: count %d, base %d, width %d, value %d, record %08x-%04x-%04x %s"
          % (b["count"], b["base"], b["width"], b["value"],
             b["record"]["slot"], b["record"]["index"], b["record"]["kind"],
             b["record"]["guid"].hex()))
    print("     b %.6g  offsets %s  widths %s  pairs %s"
          % (b["b"], ["%.4f" % x for x in b["offsets"]], b["widths"], b["pairs"]))
    print("     entries start bit %d, end bit %d of %d"
          % (r["start_bit"], r["end_bit"], r["bits"]))
    for e in b["entries"][:r["_wanted"]]:
        print("       index %6d  xyz (%9.5f, %9.5f, %9.5f)  extra %s"
              % (e["index"], e["xyz"][0], e["xyz"][1], e["xyz"][2], e["extra"]))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("name", nargs="?")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--entries", type=int, default=4)
    ap.add_argument("--pack", default=PACK)
    args = ap.parse_args(argv)

    if args.all:
        index = am.load_pack_index(args.pack)
        names = sorted(index.keys()) if hasattr(index, "keys") else sorted(index)
        for n in names:
            try:
                blob = am.asset_bytes(args.pack, index, n)
                if any(i == 4 for i, _, _, _ in am.strb_blocks(blob)):
                    show(decode(n, args.pack, args.entries))
            except Exception:
                continue
        return 0

    if not args.name:
        ap.error("give an asset name or --all")
    show(decode(args.name, args.pack, args.entries))
    return 0


if __name__ == "__main__":
    sys.exit(main())
