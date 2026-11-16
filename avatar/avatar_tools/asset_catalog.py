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
    args = ap.parse_args()

    here = os.path.dirname(os.path.abspath(__file__))
    index_path = os.path.join(here, "avatar-assets.json")
    with open(index_path, "r", encoding="utf-8") as fh:
        index = json.load(fh)
    assets = index.get("assets", index)

    with open(args.toc, "rb") as fh:
        pack = fh.read()

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
    tall = sorted((r for r in catalog if r.get("bounds")),
                  key=lambda r: -r["bounds"]["y"][1])[:5]
    print("highest assets:", [(r["name"], r["bounds"]["y"]) for r in tall])
    return 0


if __name__ == "__main__":
    sys.exit(main())
