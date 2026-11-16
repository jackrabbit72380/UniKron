"""Catalogue every asset in AvatarAssetPack from the toc's own records.

The toc record for an asset is 0xF8 bytes: thirteen locale name offsets, then
the offset of the asset's `STRB` blob, then the blob size, a count and a flag
word. `avatar-assets.json` (written by toc_parse.py) is that table flattened, so
this walks it and decodes each blob's Model block.

No chunk scanning is involved: the data lives in the blob the record points at,
which is why assembling "out_off == 0" chunk groups from a blind scan never
recovered the bodies.

    python3 asset_catalog.py /tmp/toc135.toc --json asset_catalog.json
"""

import argparse
import json
import os
import sys

import avatar_mesh
import toc_parse

# AssetMetadataVersioned (block 8) is 15 bytes, big-endian:
#
#   +0  u8   version (always 2)
#   +1  u8   gender: 1 male, 2 female, 3 both -- 127/127 Female-named assets read
#            2 and 111/111 Male-named assets read 1, so this is confirmed
#   +2  u8   asset class: 1 Model, 2 Texture, 3 ShapeOverrides, 4 Animation
#   +3  u8   zero
#   +4  u32  slot mask: which body slot(s) the item occupies
#   +8  7 B  version trailer (always 00000000000002)
GENDERS = {1: "male", 2: "female", 3: "both"}
CLASSES = {1: "model", 2: "texture", 3: "shape-overrides", 4: "animation"}

# Slot bits, named from the items that carry them. Every mask in the pack is a
# combination of these, and the theme's own folders (10_body, 20_pants, ...) are
# in the order the bits first appear.
SLOTS = (
    (0x0001, "glasses"),
    (0x0002, "wristwear"),
    (0x0004, "earrings"),
    (0x0008, "rings"),
    (0x0100, "head"),
    (0x0200, "body"),
    (0x0400, "hair"),
    (0x0800, "torso"),
    (0x1000, "legs"),
    (0x2000, "feet"),
    (0x4000, "hat"),
    (0x8000, "gloves"),
)

# The single theme folder an item files under, by its most specific slot. Items
# that set several slots (a dress sets legs+torso, a suit sets legs+torso+wrist)
# go to the slot that is unique to them.
CATEGORY_BY_SLOT = {
    "glasses": "70_glasses",
    "earrings": "75_earrings",
    "rings": "76_rings",
    "wristwear": "77_wristwear",
    "head": "15_face",
    "body": "10_body",
    "hair": "50_hair",
    "torso": "40_shirt",
    "legs": "20_pants",
    "feet": "30_shoes",
    "hat": "60_hat",
    "gloves": "46_gloves",
}

# A mask that is only some of these bits still names a category: 0x0300 is
# facial hair, 0x0500 face paint, 0x1800 a dress, 0x3802 a coat.
MASK_CATEGORIES = {
    0x0300: "45_facial-hair",
    0x0500: "16_face-paint",
    0x1800: "80_dress",
    0x1802: "81_formal",
    0x3802: "82_coat",
    0x980A: "83_dress-formal",
}


def read_metadata(payload):
    """AssetMetadataVersioned -> gender, class and slot bits."""
    if len(payload) < 8:
        return None
    mask = int.from_bytes(payload[4:8], "big")
    slots = [name for bit, name in SLOTS if mask & bit]
    if mask in MASK_CATEGORIES:
        category = MASK_CATEGORIES[mask]
    elif slots:
        # The last set slot is the most specific for combined masks.
        category = CATEGORY_BY_SLOT.get(slots[-1])
    else:
        category = None
    return {
        "version": payload[0],
        "gender": GENDERS.get(payload[1], "unknown"),
        "class": CLASSES.get(payload[2], "unknown"),
        "slot_mask": "0x%08x" % mask,
        "slots": slots,
        "category": category,
    }


def bounds(batches):
    xs = [v[0] for b in batches for v in b["vertices"]]
    ys = [v[1] for b in batches for v in b["vertices"]]
    zs = [v[2] for b in batches for v in b["vertices"]]
    if not xs:
        return None
    return {
        "x": [round(min(xs), 3), round(max(xs), 3)],
        "y": [round(min(ys), 3), round(max(ys), 3)],
        "z": [round(min(zs), 3), round(max(zs), 3)],
    }


def texture_summary(batches):
    textures = []
    for batch in batches:
        textures.extend(batch.get("textures") or [])
    return {
        "slots": len(textures),
        "with_pixels": sum(1 for t in textures if not t.get("empty")),
        "sizes": sorted({(t.get("width"), t.get("height")) for t in textures}),
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("toc", help="AvatarAssetPack.toc")
    ap.add_argument("--json", default="asset_catalog.json", help="catalogue to write")
    ap.add_argument("--items", metavar="PATH",
                    help="also write the items grouped by slot category, for the editor")
    args = ap.parse_args()

    # Read the records out of the pack we were handed. Taking them from
    # avatar-assets.json instead silently decodes another build's offsets the
    # moment someone passes a different AvatarAssetPack.toc, which is what
    # happened with the metro2010 pack.
    pack, assets, unresolved = toc_parse.parse(args.toc)
    if unresolved:
        print("%d records without a blob" % unresolved)

    catalog = []
    with_model = 0
    textured = 0
    failed = []
    for entry in assets:
        name = entry["name"]
        blob = pack[entry["offset"]:entry["offset"] + entry["size"]]
        record = {
            "name": name,
            "names": entry.get("names", [name]),
            "offset": entry["offset"],
            "size": entry["size"],
            "flags": entry.get("flags"),
        }
        try:
            blocks = avatar_mesh.strb_blocks(blob)
        except Exception as exc:
            record["error"] = "STRB: %s" % exc
            failed.append(name)
            catalog.append(record)
            continue
        record["blocks"] = [{"id": b[0], "name": avatar_mesh.BLOCK_NAMES.get(b[0], "Other"),
                             "count": b[1], "entry": b[2], "bytes": len(b[3])} for b in blocks]
        meta = next((p for i, _, _, p in blocks if i == 8), None)
        if meta:
            record["metadata"] = read_metadata(meta)
        record["has_color_table"] = any(b[0] == 7 for b in blocks)
        models = [b for b in blocks if b[0] == 3]
        if not models:
            catalog.append(record)
            continue
        batches = []
        try:
            for _, _, _, payload in models:
                batches.extend(avatar_mesh.read_model(avatar_mesh.decompress(payload)))
        except Exception as exc:
            record["error"] = "Model: %s" % exc
            failed.append(name)
            catalog.append(record)
            continue
        with_model += 1
        tex = texture_summary(batches)
        if tex["with_pixels"]:
            textured += 1
        record.update({
            "vertices": sum(len(b["vertices"]) for b in batches),
            "triangles": sum(len(b["indices"]) // 3 for b in batches),
            "batches": len(batches),
            "bounds": bounds(batches),
            "textures": tex,
        })
        catalog.append(record)

    with open(args.json, "w", encoding="utf-8") as fh:
        json.dump({"_comment": "Decoded from AvatarAssetPack.toc; every row is a real poc asset.",
                   "pack": os.path.basename(args.toc),
                   "assets": catalog}, fh, indent=1)

    print("%d assets, %d decoded models, %d with texture pixels, %d failed"
          % (len(catalog), with_model, textured, len(failed)))
    for name in failed[:10]:
        print("  failed:", name)
    bodies = [r for r in catalog if r["name"] in ("MaleBody", "FemaleBody", "Head")]
    for r in bodies:
        print("  %-12s %5d verts %5d tris  y=%s" % (
            r["name"], r.get("vertices", 0), r.get("triangles", 0),
            (r.get("bounds") or {}).get("y")))
    by_category = {}
    for r in catalog:
        meta = r.get("metadata") or {}
        by_category.setdefault(meta.get("category") or "(none)", []).append(r)
    if args.items:
        grouped = {}
        for r in catalog:
            meta = r.get("metadata") or {}
            category = meta.get("category")
            if not category:
                continue
            grouped.setdefault(category, []).append({
                "name": r["name"],
                "gender": meta.get("gender"),
                "slots": meta.get("slots"),
                "offset": r["offset"],
                "size": r["size"],
                "vertices": r.get("vertices"),
                "triangles": r.get("triangles"),
                "has_color_table": r.get("has_color_table"),
            })
        with open(args.items, "w", encoding="utf-8") as fh:
            json.dump({"_comment": "Pack items by slot category; names, genders and "
                                    "slots come from the toc records and the STRB "
                                    "AssetMetadataVersioned blocks.",
                       "categories": grouped}, fh, indent=1)
        print("\nitems -> %s (%d categories)" % (args.items, len(grouped)))

    print("\ncategory                          items  male female both")
    for category, items in sorted(by_category.items()):
        genders = [((r.get("metadata") or {}).get("gender")) for r in items]
        print("  %-30s %5d %5d %6d %4d" % (
            category, len(items), genders.count("male"), genders.count("female"),
            genders.count("both")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
