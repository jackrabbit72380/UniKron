"""Check every generated QML art index against the files on disk.

The editor reads six generated indexes, each a list of `{ id, files }` blocks
that name files under one art root:

    PackIndex.qml        pack_art/<id>/<file>
    PackPlates.qml       pack_plates/<id>/<file>
    PackPlatesFemale.qml pack_plates_female/<id>/<file>
    PackMasks.qml        pack_plates_mask/<id>/<file>
    AssetIndex.qml       assets/<id>/<file>

A name in an index with no file behind it is a broken tile in the editor - the
Image is asked for a path that does not exist, so the slot comes up empty. A file
with no entry is art nothing can ever show. Both are reported.

    python3 verify_qml_assets.py            # exit 1 if any index entry is missing
    python3 verify_qml_assets.py --orphans  # also list files no index names
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

INDEXES = [
    ("PackIndex.qml", "pack_art"),
    ("PackPlates.qml", "pack_plates"),
    ("PackPlatesFemale.qml", "pack_plates_female"),
    ("PackMasks.qml", "pack_plates_mask"),
    ("AssetIndex.qml", "assets"),
]

BLOCK = re.compile(r'\{\s*"id"\s*:\s*"([^"]+)"\s*,\s*"files"\s*:\s*\[(.*?)\]\s*\}', re.S)
NAME = re.compile(r'"([^"]+)"')


def read_index(path):
    with open(path, "r", encoding="utf-8") as fh:
        text = fh.read()
    return [(m.group(1), NAME.findall(m.group(2))) for m in BLOCK.finditer(text)]


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--orphans", action="store_true",
                    help="also list files on disk that no index names")
    args = ap.parse_args(argv)

    bad = 0
    total = 0
    for qml, root in INDEXES:
        path = os.path.join(ROOT, qml)
        base = os.path.join(ROOT, root)
        if not os.path.exists(path):
            print(f"{qml:22s} MISSING INDEX")
            bad += 1
            continue
        entries = read_index(path)
        missing, listed = [], set()
        for category, files in entries:
            for name in files:
                rel = os.path.join(category, name)
                listed.add(rel)
                if not os.path.exists(os.path.join(base, rel)):
                    missing.append(rel)
        total += len(listed)
        print(f"{qml:22s} categories={len(entries):3d} files={len(listed):5d} missing={len(missing)}")
        for rel in missing[:10]:
            print(f"    missing {root}/{rel}")
        if len(missing) > 10:
            print(f"    ... and {len(missing) - 10} more")
        bad += len(missing)

        if args.orphans:
            # Only categories the index actually lists. `assets/3d` sits under the
            # same root but is played by the 3D stage, not by the 2D index, so
            # calling its frames orphans would be wrong.
            orphans = []
            for category, _files in entries:
                cdir = os.path.join(base, category)
                if not os.path.isdir(cdir):
                    continue
                for name in sorted(os.listdir(cdir)):
                    if os.path.join(category, name) not in listed:
                        orphans.append(f"{category}/{name}")
            if orphans:
                print(f"    {len(orphans)} file(s) on disk with no index entry, e.g. {orphans[:5]}")

    print(f"VERIFY indexes={len(INDEXES)} entries={total} broken={bad}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
