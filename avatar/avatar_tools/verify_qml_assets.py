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

# The 3D stage's index has a different shape: one entry per baked frame set with
# its frame count and which frame faces the camera (make_stage_index.py).
STAGE_INDEX = "StageIndex.qml"
STAGE_ROOT = os.path.join(ROOT, "assets", "3d")
STAGE_ENTRY = re.compile(
    r'"([^"]+)"\s*:\s*\{\s*"frames"\s*:\s*(\d+)\s*,\s*"front"\s*:\s*(\d+)\s*\}')
STAGE_ANIMATED = re.compile(r'"yaws"\s*:\s*(\d+)\s*,\s*"poses"\s*:\s*(\d+)')
FRAME_FILE = re.compile(r"^frame_(\d+)\.png$")
ANIM_FILE = re.compile(r"^yaw_(\d+)_pose_(\d+)\.png$")


def read_index(path):
    with open(path, "r", encoding="utf-8") as fh:
        text = fh.read()
    return [(m.group(1), NAME.findall(m.group(2))) for m in BLOCK.finditer(text)]


def check_stage():
    """Check StageIndex.qml against the frames on disk.

    A set whose index entry disagrees with the folder is worse than no entry: the
    stage trusts the index and would play a frame that is not there, or stop the
    spin early. An unindexed set is only a warning - the stage falls back to
    probing for it - so it is reported separately from a broken entry.
    """
    path = os.path.join(ROOT, STAGE_INDEX)
    if not os.path.exists(path):
        print(f"{STAGE_INDEX:22s} MISSING INDEX")
        return 1
    with open(path, "r", encoding="utf-8") as fh:
        text = fh.read()

    broken = 0
    entries = {}
    for key, frames, front in STAGE_ENTRY.findall(text):
        frames, front = int(frames), int(front)
        entries[key] = frames
        folder = os.path.join(STAGE_ROOT, key)
        have = sorted(int(FRAME_FILE.match(n).group(1)) for n in os.listdir(folder)
                      if FRAME_FILE.match(n)) if os.path.isdir(folder) else []
        if len(have) != frames:
            print(f"    {key}: index says {frames} frames, disk has {len(have)}")
            broken += 1
        elif have != list(range(frames)):
            print(f"    {key}: frames are not numbered 0..{frames - 1}")
            broken += 1
        if not 0 <= front < max(frames, 1):
            print(f"    {key}: front {front} is outside 0..{frames - 1}")
            broken += 1

    # Sets on disk that the index does not name (a bake since the last run).
    stale = []
    for dirpath, _dirnames, filenames in os.walk(STAGE_ROOT):
        if os.path.basename(dirpath) == "animated":
            continue
        if any(FRAME_FILE.match(n) for n in filenames):
            rel = os.path.relpath(dirpath, STAGE_ROOT).replace(os.sep, "/")
            if rel not in entries:
                stale.append(rel)

    animated = STAGE_ANIMATED.search(text)
    anim_dirs = os.path.join(STAGE_ROOT, "animated")
    if animated and os.path.isdir(anim_dirs):
        yaws = poses = 0
        for name in os.listdir(anim_dirs):
            m = ANIM_FILE.match(name)
            if m:
                yaws = max(yaws, int(m.group(1)) + 1)
                poses = max(poses, int(m.group(2)) + 1)
        if (int(animated.group(1)), int(animated.group(2))) != (yaws, poses):
            print(f"    animated: index says {animated.group(1)}x{animated.group(2)}, "
                  f"disk has {yaws}x{poses}")
            broken += 1

    print(f"{STAGE_INDEX:22s} sets={len(entries):5d} frames={sum(entries.values()):5d} "
          f"broken={broken} unindexed={len(stale)}")
    for rel in stale[:10]:
        print(f"    unindexed {rel}")
    if len(stale) > 10:
        print(f"    ... and {len(stale) - 10} more")
    return broken


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

    bad += check_stage()

    print(f"VERIFY indexes={len(INDEXES) + 1} entries={total} broken={bad}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
