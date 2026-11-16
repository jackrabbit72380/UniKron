"""Build a catalogue from a retail avatar closet folder.

The `Clean Slate NXE` build ships the dashboard's whole closet as
`assets/closet/`: one `YTGR`/`STRB` item per id, a PNG icon per id, and
`closet_index.tsv` with the names:

    00000008-001f-62f1-c10d-7afc354107d4  00000008  1  2014 Colombia Home Jersey

This reads that folder without copying it and writes one JSON file the theme
can consume, so a real 20,349-item closet can be addressed by name. It records
what each item actually contains (block ids and sizes) rather than assuming a
garment type.

The model block in a retail item is LZX-framed inside the STRB, where the
editor's own pack stores its blocks plain; `avatar_mesh.decompress` handles
the frame and then `read_model` reads it normally, giving batches, vertices,
triangles, UVs, materials, joints and weights. Neither the item id, the index
code, the joint binding nor the mesh position states a garment category, so
this catalogue does not claim one.

    python3 closet_import.py <closet_dir> <out.json>
"""

import json
import os
import sys

import avatar_mesh

INDEX = "closet_index.tsv"


def read_index(folder):
    """id -> (group, code, name) from the tab-separated index."""
    path = os.path.join(folder, INDEX)
    entries = {}
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 4:
                continue
            item, group, code, name = parts[0], parts[1], parts[2], parts[3]
            entries[item] = (group, code, name)
    return entries


def describe(folder, item):
    """What one item asset holds: block ids and sizes, and whether it parses."""
    path = os.path.join(folder, item + ".bin")
    if not os.path.exists(path):
        return None
    with open(path, "rb") as handle:
        data = handle.read()
    try:
        blocks = avatar_mesh.strb_blocks(data)
    except avatar_mesh.Malformed:
        return {"size": len(data), "blocks": [], "model": False}
    payload = next((block[3] for block in blocks if block[0] == 3), None)
    model = {"parses": False}
    if payload is not None:
        # Retail blocks are LZX-framed inside the STRB; the editor's pack stores
        # theirs plain, so this step is what makes a retail item readable.
        try:
            batches = avatar_mesh.read_model(avatar_mesh.decompress(payload))
        except avatar_mesh.Malformed:
            batches = None
        if batches:
            model = {
                "parses": True,
                "batches": len(batches),
                "vertices": sum(len(batch["vertices"]) for batch in batches),
                "triangles": sum(len(batch["indices"]) // 3 for batch in batches),
            }
    summary = [{"id": block[0], "size": block[1]} for block in blocks]
    return {"size": len(data), "blocks": summary, "model": model}


def main(argv):
    if len(argv) != 3:
        print(__doc__.strip())
        return 2
    folder, target = argv[1], argv[2]
    if not os.path.exists(os.path.join(folder, INDEX)):
        print(f"no {INDEX} in {folder}")
        return 1
    index = read_index(folder)
    items = []
    for item, (group, code, name) in sorted(index.items()):
        facts = describe(folder, item)
        if facts is None:
            continue
        icon = item + ".png"
        items.append({
            "id": item,
            "name": name,
            "group": group,
            "code": code,
            "icon": icon if os.path.exists(os.path.join(folder, "icons", icon)) else None,
            "bytes": facts["size"],
            "blocks": facts["blocks"],
            "model": facts["model"],
        })
    with open(target, "w", encoding="utf-8") as handle:
        json.dump({"folder": os.path.abspath(folder), "items": items}, handle, indent=1)
    named = sum(1 for item in items if item["name"])
    icons = sum(1 for item in items if item["icon"])
    parsed = sum(1 for item in items if item["model"]["parses"])
    print(f"{len(items)} items, {named} named, {icons} with icons, {parsed} models parse")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
