"""Summarise any AvatarAssetPack.toc, and diff its asset list against ours.

Written for comparing builds: the project's catalogues were built from one pack
revision, and another build may carry art this one lacks (texture pixels, colour
palettes, shape blocks). Pointing this at a new pack says, in one screen, whether
it is the same assets, a different revision, or something richer.

    python3 inspect_pack.py PATH/TO/AvatarAssetPack.toc [--compare avatar-assets.json]
"""

import argparse
import collections
import json
import os
import sys

import avatar_mesh as am
import asset_catalog as ac
import toc_parse

HERE = os.path.dirname(os.path.abspath(__file__))
BLOCK_NAMES = {2: "Texture", 3: "Model", 4: "ShapeOverrides", 7: "ColourTable", 8: "Metadata"}


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("toc")
    ap.add_argument("--compare", default=os.path.join(HERE, "avatar-assets.json"),
                    help="manifest to diff the names against")
    args = ap.parse_args()

    pack, assets, unresolved = toc_parse.parse(args.toc)
    print("%s: %d bytes, %d assets, %d without a blob"
          % (os.path.basename(args.toc), len(pack), len(assets), unresolved))

    blocks = collections.Counter()
    classes = collections.Counter()
    categories = collections.Counter()
    models = textured = palettes = shapes = failed = 0
    names = []
    for entry in assets:
        names.append(entry["name"])
        blob = pack[entry["offset"]:entry["offset"] + entry["size"]]
        try:
            found = am.strb_blocks(blob)
        except Exception:
            failed += 1
            continue
        for block in found:
            blocks[BLOCK_NAMES.get(block[0], "block %d" % block[0])] += 1
        meta = next((b[3] for b in found if b[0] == 8), None)
        if meta:
            parsed = ac.read_metadata(meta)
            classes[parsed["class"]] += 1
            categories[parsed.get("category") or "(none)"] += 1
        if any(b[0] == 4 for b in found):
            shapes += 1
        if any(b[0] == 7 for b in found):
            palettes += 1
        model = [b for b in found if b[0] == 3]
        if model:
            try:
                batches = am.read_model(am.decompress(model[0][3]))
            except Exception:
                failed += 1
                continue
            models += 1
            if any(t for b in batches for t in (b.get("textures") or [])
                   if not t.get("empty")):
                textured += 1

    print("blocks: %s" % dict(blocks))
    print("classes: %s" % dict(classes))
    print("models %d, with texture pixels %d, colour tables %d, shape overrides %d, "
          "unreadable %d" % (models, textured, palettes, shapes, failed))
    print("categories: %s" % dict(categories))

    if os.path.exists(args.compare):
        with open(args.compare, "r", encoding="utf-8") as fh:
            old = [a["name"] for a in json.load(fh)["assets"]]
        new = set(names)
        gone = [n for n in old if n not in new]
        extra = [n for n in names if n not in set(old)]
        print("\nvs %s: %d same, %d only there, %d only here"
              % (os.path.basename(args.compare),
                 len(set(old) & new), len(gone), len(extra)))
        for label, items in (("missing here", gone), ("new here", extra)):
            if items:
                print("  %s: %s%s" % (label, items[:8], " ..." if len(items) > 8 else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
