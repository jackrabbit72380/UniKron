"""Rebake only the sets that missed the last pose change.

A full turntable pass is 9 seconds a set, so a run cut short by a timeout leaves
a scattering of sets baked with the old pose - invisible in a directory listing,
where every folder still has a `frame_00.png`. This finds them by timestamp and
bakes just those.

    python3 rebake_stale.py --gender male
    python3 rebake_stale.py --gender female --age 1800 --workers 8
"""

import argparse
import json
import multiprocessing
import os
import sys
import time

import bake_pack_turntables as bt

HERE = os.path.dirname(os.path.abspath(__file__))
PACK = os.path.join(HERE, "../../../src_archive/XBOX HUB/resources/editors/metro2010/assets/"
                          "AvatarAssetPack.toc")
CLIP = os.path.join(HERE, "../../../src_archive/XBOX HUB/resources/editors/metro2010/assets/"
                          "Cheer.AvatarAnimation")
DESCRIPTIONS = {"male": "descriptors/Avatar6400.Avatar",
                "female": "descriptors/Avatar6404.Avatar"}
OUTDIRS = {"male": os.path.join(HERE, "..", "assets", "3d", "turntable"),
           "female": os.path.join(HERE, "..", "assets", "3d", "turntable_female")}


def stale_sets(outdir, age):
    """Set folders whose newest frame is older than `age` seconds."""
    now = time.time()
    out = []
    for name in sorted(os.listdir(outdir)):
        folder = os.path.join(outdir, name)
        if not os.path.isdir(folder):
            continue
        frames = [os.path.join(folder, f) for f in os.listdir(folder)
                  if f.startswith("frame_") and f.endswith(".png")]
        if not frames:
            out.append(name)
            continue
        if now - max(os.path.getmtime(f) for f in frames) > age:
            out.append(name)
    return out


def _bake(job):
    name, kind, category, gender = job
    # Bake on the body of the tree the set lives in: the tree is what the editor
    # reads, so whatever it already holds should keep its gender.
    body = gender
    from bake_pack_thumbs import slug
    error = bt.bake_one(PACK, CLIP, DESCRIPTIONS[body], name, kind,
                        os.path.join(OUTDIRS[body], slug(name)), 6, 192, 288,
                        category=category, gender=body)
    return name, error


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--gender", choices=("male", "female"), action="append")
    parser.add_argument("--age", type=int, default=3600,
                        help="seconds; frames older than this count as stale")
    parser.add_argument("--workers", type=int, default=8)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    genders = args.gender or ["male", "female"]
    from bake_pack_thumbs import slug
    with open(os.path.join(HERE, "asset_catalog.json"), "r", encoding="utf-8") as fh:
        # Folders are named by slug, the catalog by the pack's own asset name.
        catalog = {slug(r["name"]): r for r in json.load(fh)["assets"]}

    jobs = []
    for gender in genders:
        folders = stale_sets(OUTDIRS[gender], args.age)
        print("%s: %d stale set(s) in %s" % (gender, len(folders), OUTDIRS[gender]))
        for folder in folders:
            record = catalog.get(folder)
            if record is None:
                print("  %-40s not in the catalog, skipped" % folder)
                continue
            category = (record.get("metadata") or {}).get("category")
            kind = bt.CATEGORY_KIND.get(category)
            jobs.append((record["name"], kind, category, gender))
    if args.dry_run:
        for name, kind, category, gender in jobs:
            print("  %-12s %-20s %s" % (gender, category, name))
        return 0
    if not jobs:
        print("nothing to do")
        return 0

    failed = 0
    with multiprocessing.Pool(min(args.workers, len(jobs))) as pool:
        for name, error in pool.imap_unordered(_bake, jobs):
            if error:
                failed += 1
                print("  failed %s: %s" % (name, error))
            else:
                print("  baked %s" % name)
    print("%d baked, %d failed" % (len(jobs) - failed, failed))
    try:
        import make_stage_index
        sets, frames = make_stage_index.refresh()
        print("StageIndex.qml: %d sets, %d frames" % (sets, frames))
    except Exception as error:
        print("could not refresh StageIndex.qml: %s" % error)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
