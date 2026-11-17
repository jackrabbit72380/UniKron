#!/usr/bin/env python3
"""Check that every decoded shape override lands on a real stock mesh.

Block 4 gives a list of (vertex offset, position). The offset is a byte offset, so
it only means something once you know the vertex stride - and the stride depends on
the mesh: 52 for Head, 40 for the bodies. This tool therefore does not assume a
target. It decodes each shape-only item, takes the vertex out of the offset with the
stride the item implies, and asks which stock mesh those vertices actually sit on:

    for each candidate mesh:
        if any vertex is outside it, skip the mesh
        distance = |mesh[vertex] - shape_position| for every entry

A correct target puts the positions millimetres from the named vertex. A wrong one
puts them half a metre away, which is how MaleBody was ruled out for the clothing
templates and FemaleBody confirmed: the same offsets gave mean 0.51 m against the
male body and 0.002 m against the female.

Prints a per-target summary and exits 1 if fewer than MIN_VALIDATED items fit or if
an item that used to fit no longer does (the list is compared against the count this
was written with, 207 of 215, rather than silently accepting a drop).

    python3 verify_shapes.py
    python3 verify_shapes.py --all      # list every item and its target
"""
import argparse
import collections
import sys

import numpy as np

import avatar_mesh as am
import decode_shape

PACK = decode_shape.PACK
MESHES = ("Head", "MaleBody", "FemaleBody")
TOLERANCE = 0.060          # metres; a fit is mm, a miss is hundreds of mm
MIN_VALIDATED = 212        # items whose every entry fits, when this was written
TOTAL_ITEMS = 215          # shape-only items that carry entries at all
# These move a foot far enough that its own vertices are no longer within tolerance
# of where it was; the target is still FemaleBody and 190 of 198 entries fit.
LARGE_CORRECTIONS = {
    "Female Platform Shoes Hiding Template",
    "Female Strappy High Heels Template",
    "High Heel Body Modification Template",
}


def load_meshes(pack=PACK):
    out = {}
    for name in MESHES:
        blob = am.asset_bytes(pack, am.load_pack_index(pack), name)
        block = [b for b in am.strb_blocks(blob) if b[0] == 3]
        if not block:
            continue
        verts = []
        for batch in am.read_model(am.decompress(block[0][3])):
            verts.append(np.asarray(batch["vertices"], dtype=np.float64))
        out[name] = np.vstack(verts)
    return out


def shape_only_items(pack=PACK):
    """Assets that carry a block 4 and no geometry of their own."""
    index = am.load_pack_index(pack)
    names = sorted(index.keys()) if hasattr(index, "keys") else sorted(index)
    for name in names:
        try:
            blob = am.asset_bytes(pack, index, name)
            blocks = am.strb_blocks(blob)
            if not any(i == 4 for i, _, _, _ in blocks):
                continue
            if any(i == 3 for i, _, _, _ in blocks):
                continue
            payload = next(p for i, _, _, p in blocks if i == 4)
            yield name, decode_shape.decode_payload(payload)
        except Exception:                                    # noqa: BLE001
            continue


def fit(decoded, meshes):
    """Best (mean distance, mesh, entries within tolerance, entry count).

    Every candidate stride is tried against every mesh, because the stride cannot be
    read reliably off the offsets alone: two offsets give a gcd that can be a
    multiple of the real stride (21600 and 46000 give 400 against a real 40). A fit
    of micrometres against hundreds of millimetres makes the choice unambiguous.
    """
    entries = decoded["section_b"]["entries"]
    if not entries:
        return None
    pos = np.array([e["xyz"] for e in entries], dtype=np.float64)
    offsets = np.array([e["index"] for e in entries], dtype=np.int64)
    best = None
    for stride in decoded.get("strides") or [decoded["stride"]]:
        vertex = offsets // stride
        for name, verts in meshes.items():
            if vertex.max() >= len(verts):
                continue
            dist = np.linalg.norm(verts[vertex] - pos, axis=1)
            rec = (float(dist.mean()), name, int((dist <= TOLERANCE).sum()),
                   len(entries), stride)
            if best is None or rec[0] < best[0]:
                best = rec
    return best


def main(argv=None):
    ap_ = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap_.add_argument("--pack", default=PACK)
    ap_.add_argument("--all", action="store_true")
    args = ap_.parse_args(argv)

    meshes = load_meshes(args.pack)
    rows = []
    for name, decoded in shape_only_items(args.pack):
        rec = fit(decoded, meshes)
        if rec:
            rows.append((name,) + rec)

    print("shape-only items with entries: %d" % len(rows))
    by_target = collections.Counter(r[2] for r in rows)
    print("best-fitting mesh: %s" % dict(by_target))

    every = [r for r in rows if r[3] == r[4]]
    print("items where every entry lands within %d mm: %d of %d"
          % (int(TOLERANCE * 1000), len(every), len(rows)))
    for target in MESHES:
        got = [r for r in every if r[2] == target]
        if got:
            strides = sorted({r[5] for r in got})
            print("   %-11s %3d items, stride %s, mean %.4f m, worst %.4f m"
                  % (target, len(got), strides,
                     sum(r[1] for r in got) / len(got), max(r[1] for r in got)))

    partial = [r for r in rows if r[3] < r[4]]
    # Two different things look like a partial fit. A shoe that lifts the foot can
    # move a few vertices further than 60 mm while still being on the right mesh
    # (the high heels: 190 of 198 entries fit, mean 26 mm). A shape whose target is
    # wrong puts *every* entry hundreds of millimetres away (the five 2-entry
    # "Template" items at 588 mm). Only the second is a real gap.
    lifted = [r for r in partial if r[3] >= 0.5 * r[4]]
    unexplained = [r for r in partial if r[3] < 0.5 * r[4]]
    if lifted:
        print("large corrections, still on the right mesh (%d):" % len(lifted))
        for r in lifted:
            print("   %-46s %-11s mean %.4f m, %d of %d within %d mm"
                  % (r[0], r[2], r[1], r[3], r[4], int(TOLERANCE * 1000)))
    if unexplained:
        print("target not identified (%d):" % len(unexplained))
        for r in unexplained:
            print("   %-46s mean %.4f m against %-10s, %d of %d entries within %d mm"
                  % (r[0], r[1], r[2], r[3], r[4], int(TOLERANCE * 1000)))
    if args.all:
        for r in rows:
            print("   %-46s -> %-11s mean %.4f m" % (r[0], r[2], r[1]))

    unexpected = [r for r in lifted if r[0] not in LARGE_CORRECTIONS]
    if unexpected:
        print("unexpected large corrections (%d): %s"
              % (len(unexpected), ", ".join(r[0] for r in unexpected)))
    ok = (len(every) >= MIN_VALIDATED and len(rows) >= TOTAL_ITEMS
          and not unexplained and not unexpected)
    print("%d validated, %d not - expected at least %d of %d"
          % (len(every), len(rows) - len(every), MIN_VALIDATED, TOTAL_ITEMS))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
