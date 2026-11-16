"""Render one thumbnail per pack item, from the item's own geometry.

The pack carries no textures at all, so there is no retail thumbnail art to
extract. What it does carry is every item's mesh, so the thumbnails here are
renders of that mesh with the same flat-shaded painter `bake_turntable.py` uses
for the 3D stage - real geometry, no invented shapes.

Pack meshes are already Y-up (the bodies measure 0.005..1.167 along y), so no
axis swap is applied: `up_axis="y"`.

    python3 bake_pack_thumbs.py PACK [--outdir ../assets/pack] [--size 128] [--limit N]

Writes OUTDIR/<category>/<slug>.png, one per item, skipping files that already
exist so an interrupted run can be resumed.
"""

import argparse
import json
import math
import os
import re
import sys

import numpy as np

import avatar_mesh as am
import bake_turntable as bt

HERE = os.path.dirname(os.path.abspath(__file__))


def slug(name):
    s = name.lower()
    s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
    return s or "item"


def fit(verts):
    """Frame one item by its own bounding box.

    `bake_turntable.normalise` scales by height alone, which is right for a
    standing avatar but throws an item that is wider than it is tall - a pair of
    shoes - completely outside the frame. Scaling by the largest extent instead
    keeps every item inside it, and shifting y into 0..1 matches the camera's
    assumption that a model stands on y=0.
    """
    lo = verts.min(axis=0)
    hi = verts.max(axis=0)
    verts = verts - (lo + hi) * 0.5
    extent = max(float((hi - lo).max()), 1e-6)
    verts = verts / extent
    verts[:, 1] += 0.5
    return verts


def model_arrays(pack, entry):
    blob = pack[entry["offset"]:entry["offset"] + entry["size"]]
    batches = []
    for block_id, _, _, payload in am.strb_blocks(blob):
        if block_id == 3:
            batches.extend(am.read_model(am.decompress(payload)))
    if not batches:
        return None
    verts = []
    tris = []
    colours = []
    base = 0
    for batch in batches:
        for v in batch["vertices"]:
            verts.append((v[0], v[1], v[2]))
        idx = batch["indices"]
        for i in range(0, len(idx) - 2, 3):
            tris.append((base + idx[i], base + idx[i + 1], base + idx[i + 2]))
            colours.append((0.72, 0.70, 0.66))
        base += len(batch["vertices"])
    if not verts or not tris:
        return None
    return (np.array(verts, dtype=np.float64), np.array(tris, dtype=np.int64),
            np.array(colours, dtype=np.float64))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("pack")
    ap.add_argument("--catalog", default=os.path.join(HERE, "asset_catalog.json"))
    ap.add_argument("--outdir", default=os.path.join(os.path.dirname(HERE), "pack_art"),
                    help="thumbnails go here, outside assets/ so the hand-drawn index is untouched")
    ap.add_argument("--index", metavar="PATH", help="also write a PackIndex.qml for these folders")
    ap.add_argument("--size", type=int, default=128)
    ap.add_argument("--limit", type=int, default=0, help="only the first N items")
    args = ap.parse_args()

    with open(args.catalog, "r", encoding="utf-8") as fh:
        catalog = json.load(fh)["assets"]
    with open(args.pack, "rb") as fh:
        pack = fh.read()

    items = [r for r in catalog if r.get("vertices") and (r.get("metadata") or {}).get("category")]
    if args.limit:
        items = items[:args.limit]
    print("%d items to render" % len(items))

    written = skipped = failed = 0
    for record in items:
        category = record["metadata"]["category"]
        folder = os.path.join(args.outdir, category)
        path = os.path.join(folder, slug(record["name"]) + ".png")
        if os.path.exists(path):
            skipped += 1
            continue
        try:
            arrays = model_arrays(pack, record)
            if arrays is None:
                failed += 1
                continue
            verts, tris, colours = arrays
            verts = fit(verts)
            vnormals = bt.vertex_normals(verts, tris)
            # A three-quarter view reads better than dead-on for clothing.
            rgba = bt.render(verts, tris, colours, vnormals, math.radians(30.0),
                             args.size, args.size, face=None)
            os.makedirs(folder, exist_ok=True)
            bt.write_png(path, rgba)
            written += 1
            if written % 50 == 0:
                print("  %d written" % written)
        except Exception as exc:
            failed += 1
            print("  failed %s: %s" % (record["name"], exc))

    print("wrote %d, skipped %d, failed %d into %s" % (written, skipped, failed, args.outdir))

    if args.index:
        write_index(args.outdir, args.index)
    return 0


def write_index(outdir, path):
    """A PackIndex.qml in the same shape as AssetIndex.qml, but for pack_art."""
    folders = []
    for name in sorted(os.listdir(outdir)):
        folder = os.path.join(outdir, name)
        if not os.path.isdir(folder):
            continue
        files = sorted(f for f in os.listdir(folder) if f.lower().endswith(".png"))
        if files:
            folders.append((name, files))
    lines = [
        "import QtQuick 2.15",
        "",
        "// Generated by avatar_tools/bake_pack_thumbs.py - do not edit by hand.",
        "// One entry per AvatarAssetPack slot category, holding a render of each",
        "// real item's own mesh; the pack carries no texture art of its own.",
        "QtObject {",
        "    readonly property var folders: [",
    ]
    for index, (name, files) in enumerate(folders):
        listing = ", ".join('"%s"' % f for f in files)
        comma = "," if index + 1 < len(folders) else ""
        lines.append('        { "id": "%s", "files": [%s] }%s' % (name, listing, comma))
    lines += ["    ]", "}", ""]
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))
    print("index -> %s (%d folders)" % (path, len(folders)))


if __name__ == "__main__":
    sys.exit(main())
