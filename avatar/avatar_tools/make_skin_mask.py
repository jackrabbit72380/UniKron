"""Build the skin tint mask from the body silhouette minus the face features.

The body plate is baked with one skin tone already in it, and the retail editor's
skin screen replaces that tone rather than multiplying it, so the skin colour needs
a mask whose RGB is the light rig over a white albedo - the same shape as every
other mask here (bake_pack_plates.py --mask, COLOURS.md).

A silhouette of the whole body is not that mask: it covers the eyes, brows and
mouth as well, and tinting those with a skin colour would paint over the face. The
feature sheets have masks of their own, so they are taken out of the silhouette -
each pixel keeps `1 - feature coverage` of its skin coverage. What is left is skin:
body, head, hands and ears, with the face left for its own layers to draw.

    python3 make_skin_mask.py                 # reads and writes pack_plates_mask
    python3 make_skin_mask.py --check         # report, change nothing

The output is `pack_plates_mask/10_body/skin.png`, beside the silhouette it came
from (`10_body/malebody.png`, bake_pack_plates.py --mask --include-base).
"""

import argparse
import glob
import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
MASK_DIR = os.path.join(os.path.dirname(HERE), "pack_plates_mask")
BODY_MASK = os.path.join(MASK_DIR, "10_body", "malebody.png")
OUT = os.path.join(MASK_DIR, "10_body", "skin.png")
# The sheets that paint the face: brows, eyes and the head's own mouth. Eye shadow
# and face paint are decals on top of skin, so they are not excluded - their own
# layers draw over the tint, exactly as they do over the plate.
FEATURE_FOLDERS = ("12_eyebrows", "15_face", "18_mouth")


def read_alpha(path):
    return np.array(Image.open(path).convert("RGBA"), dtype=np.float64)[..., 3] / 255.0


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="report only, write nothing")
    args = ap.parse_args()

    if not os.path.exists(BODY_MASK):
        raise SystemExit("missing %s - run bake_pack_plates.py --categories 10_body "
                         "--mask --include-base first" % BODY_MASK)

    body = np.array(Image.open(BODY_MASK).convert("RGBA"), dtype=np.float64) / 255.0
    body_alpha = body[..., 3]
    feature = np.zeros_like(body_alpha)
    counted = 0
    for folder in FEATURE_FOLDERS:
        for path in sorted(glob.glob(os.path.join(MASK_DIR, folder, "*.png"))):
            feature = np.maximum(feature, read_alpha(path))
            counted += 1

    skin_alpha = np.clip(body_alpha * (1.0 - feature), 0.0, 1.0)
    out = body.copy()
    out[..., 3] = skin_alpha

    covered = float((body_alpha > 0.02).sum())
    kept = float((skin_alpha > 0.02).sum())
    print("body silhouette  %6.0f px" % covered)
    print("feature masks    %6d files, %6.0f px removed" % (counted, covered - kept))
    print("skin mask        %6.0f px (%.1f%% of the silhouette)" % (kept, 100.0 * kept / covered))
    if args.check:
        return
    Image.fromarray((np.clip(out, 0.0, 1.0) * 255).astype(np.uint8)).save(OUT)
    print("wrote %s" % os.path.relpath(OUT, os.path.dirname(HERE)))


if __name__ == "__main__":
    main()
