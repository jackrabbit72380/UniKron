"""Check the baked art against the build plan, without baking anything.

Bakes are the expensive step and the only thing one can discover at the end is
that something was missing. `audit_pack.py` answers that for the *data*; this
answers it for the *files*: for every item in the plan it looks for the plate and
the turntable set that item should have produced, and reports what is absent,
what is empty, and what disagrees about frame counts.

    python3 verify_art.py                  # summary
    python3 verify_art.py --list-missing   # every missing artefact

Exit status is 0 when the art matches the plan exactly.
"""

import argparse
import glob
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
AVATAR = os.path.dirname(HERE)

# Categories whose art is a UV sheet on the shared Head asset: the female avatar
# deliberately reuses the male plate (AvatarEditor.qml, hasPlates/isPackDecal).
SHARED_SHEETS = {"12_eyebrows", "15_face", "16_face-paint", "45_facial-hair"}

PLATES = {"male": os.path.join(AVATAR, "pack_plates"),
          "female": os.path.join(AVATAR, "pack_plates_female")}
TURNTABLES = {"male": os.path.join(AVATAR, "assets", "3d", "turntable"),
              "female": os.path.join(AVATAR, "assets", "3d", "turntable_female")}
ANIMATED = os.path.join(AVATAR, "assets", "3d", "animated")


def slug(name):
    out = []
    for ch in name.lower():
        if ch.isalnum():
            out.append(ch)
        elif out and out[-1] != "-":
            out.append("-")
    return "".join(out).strip("-")


def frames(folder, pattern="frame_*.png"):
    return sorted(glob.glob(os.path.join(folder, pattern)))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--audit", default=os.path.join(HERE, "pack_audit.json"))
    parser.add_argument("--list-missing", action="store_true")
    args = parser.parse_args()

    with open(args.audit, "r", encoding="utf-8") as fh:
        plan = json.load(fh)["build_plan"]
    items = plan["items"]

    missing = []
    counts = {"plate": 0, "set": 0, "set_ok": 0, "plate_ok": 0}
    frame_counts = {}
    for row in items:
        gender, category, name, _kind, needs, _flag = row
        stem = slug(name)
        plate = os.path.join(PLATES[gender], category, stem + ".png")
        # A female face/face-paint/facial-hair plate is not expected: both bodies
        # share the one Head asset, and the editor falls back to the male sheet
        # (AvatarEditor.qml hasPlates). Everything else is expected for both.
        if not (gender == "female" and category in SHARED_SHEETS):
            counts["plate"] += 1
            if os.path.exists(plate):
                counts["plate_ok"] += 1
            else:
                missing.append(("plate", gender, category, name, plate))

        if category == "10_body" or needs == "sheet":
            continue
        folder = os.path.join(TURNTABLES[gender], stem)
        counts["set"] += 1
        shots = frames(folder)
        if shots:
            counts["set_ok"] += 1
            frame_counts.setdefault(len(shots), []).append((gender, name))
        else:
            missing.append(("set", gender, category, name, folder))

    animated = frames(ANIMATED, "yaw_*_pose_*.png")
    print("plan items        %d" % len(items))
    print("plates            %d/%d present" % (counts["plate_ok"], counts["plate"]))
    print("turntable sets    %d/%d present" % (counts["set_ok"], counts["set"]))
    print("animated frames   %d" % len(animated))
    for count, who in sorted(frame_counts.items()):
        print("  sets with %d frames: %d" % (count, len(who)))
    if missing:
        print("\nmissing %d artefact(s)" % len(missing))
        if args.list_missing:
            for kind, gender, category, name, path in missing:
                print("  %-5s %-6s %-14s %-34s %s"
                      % (kind, gender, category, name, os.path.relpath(path, AVATAR)))
        else:
            kinds = {}
            for kind, gender, category, name, path in missing:
                kinds.setdefault((kind, gender, category), []).append(name)
            for key, names in sorted(kinds.items()):
                print("  %-5s %-6s %-14s %d (%s)"
                      % (key[0], key[1], key[2], len(names), ", ".join(names[:3])))
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
