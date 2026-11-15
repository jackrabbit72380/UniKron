#!/usr/bin/env python3
"""Assemble a posed avatar from pack assets and write it as one OBJ.

    python3 bake_avatar.py PACK CLIP FRAME OUT.obj ASSET [ASSET ...]
    python3 bake_avatar.py ../../../src_archive/.../AvatarAssetPack.toc \\
        ../../../src_archive/.../IdleOffScreen.AvatarAnimation 0 \\
        /tmp/avatar_full.obj MaleBody Head "Short Ties" "Male Power Tee" \\
        "Worn Jeans" "Formal Shoes"

Every asset is skinned through the same 71-joint rig with the given clip and
frame, then concatenated, so body, head, hair and clothes share one pose. Feed
the result to bake_turntable.py to make the frames AvatarStage3D plays.

Notes that cost real time to learn:
  * The clip is a standalone `.AvatarAnimation` file, not a pack block; its
    animation payload is block id 1 inside that file.
  * Frame 0 of IdleOffScreen with no --conj flag is the standing idle (arms
    down, y 0.003..1.149). Conjugating the rotations raises the arms into a
    cheer, which is the wrong pose for a preview.
"""
import struct
import sys

import avatar_mesh as am
import avatar_pose as ap
import skeleton_nxe as sk

# The nine ARGB colours at 0xFC of the 1000-byte description.
COLOUR_NAMES = ("skin", "hair", "mouth", "eyes", "eyebrows", "eye shadow",
                "facial hair", "feature 1", "feature 2")

# Slot bits in a description item entry: which part of the avatar an asset is.
SLOT_HEAD, SLOT_BODY, SLOT_HAIR = 0x01, 0x02, 0x04

# Name words that mark a hairstyle, for pieces the description does not list.
HAIR_WORDS = ("hair", "parting", "flick", "bun", "bob", "afro", "ponytail",
              "mohawk", "buzz", "braid", "curls", "crown", "chopsticks",
              "fringe", "topknot", "pigtail", "dreadlock", "mop", "mullet")


def read_description(path):
    """Colours and item->slot bits out of a 1000-byte `.Avatar` description."""
    data = open(path, "rb").read()
    if len(data) < 0x390:
        raise SystemExit("%s is not a 1000-byte avatar description" % path)
    colours = {}
    for i, name in enumerate(COLOUR_NAMES):
        v = struct.unpack_from(">I", data, 0xFC + 4 * i)[0]
        colours[name] = ((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF)
    slots = {}
    for base, count in ((0x120, 15), (0x300, 4)):
        for i in range(count):
            o = base + 32 * i
            mask = struct.unpack_from(">I", data, o)[0]
            idx = struct.unpack_from(">H", data, o + 4)[0]
            if mask:
                slots[idx] = mask
    return colours, slots


def asset_colour(name, record, colours, slots, clothing):
    """RGB in 0..1 for one asset: skin and hair from the description, else neutral.

    Clothes stay neutral on purpose: a stock item's colour is not in its own
    asset (models embed no textures) and the description only carries custom
    colours, which this outfit leaves empty. See EDITOR_BINARIES.md.
    """
    mask = slots.get(record, 0)
    if not mask:
        # The description names the outfit this avatar was saved with, not the
        # pieces a rebake swaps in, so fall back on the asset's own name.
        if name in ("MaleBody", "FemaleBody", "Head"):
            mask = SLOT_BODY
        elif any(word in name.lower() for word in HAIR_WORDS):
            mask = SLOT_HAIR
    if mask & (SLOT_BODY | SLOT_HEAD):
        pick = colours["skin"]
    elif mask & SLOT_HAIR:
        pick = colours["hair"]
    else:
        pick = clothing
    return tuple(c / 255.0 for c in pick)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    colour_args = [a for a in sys.argv if a.startswith("--colours=")]
    if len(args) < 5:
        print(__doc__)
        return 1
    pack, clip, frame, out = args[0], args[1], int(args[2]), args[3]
    assets = args[4:]

    colours = slots = None
    if colour_args:
        colours, slots = read_description(colour_args[0].split("=", 1)[1])
    # A neutral fabric: the honest colour for clothes whose colour is unknown.
    clothing = (0x8A, 0x8D, 0x93)

    index = am.load_pack_index(pack)
    records = am.record_indices(pack)
    joints = sk.read_skeleton()
    payload = [b for b in am.strb_blocks(open(clip, "rb").read()) if b[0] == 1]
    if not payload:
        raise SystemExit("no animation block in " + clip)
    poses, frames = ap.read_animation_poses(payload[0][3], frame)
    print("%s frame %d/%d" % (clip.split("/")[-1], frame, frames))

    lines = []
    written = 0
    for name in assets:
        batches = []
        for block in am.strb_blocks(am.asset_bytes(pack, index, name)):
            if block[0] == 3:
                batches += am.read_model(am.decompress(block[3]))
        rgb = None
        if colours is not None:
            rgb = asset_colour(name, records.get(name, -1), colours, slots, clothing)
        for batch in ap.posed_positions(batches, joints, poses):
            base = written
            for v in batch["vertices"]:
                if rgb is None:
                    lines.append("v %.6f %.6f %.6f" % tuple(v))
                else:
                    lines.append("v %.6f %.6f %.6f %.3f %.3f %.3f" % (tuple(v) + rgb))
                written += 1
            indices = batch["indices"]
            for t in range(0, len(indices), 3):
                lines.append("f %d %d %d" % (
                    indices[t] + base + 1, indices[t + 1] + base + 1, indices[t + 2] + base + 1))
        print("  posed %s" % name)

    open(out, "w").write("\n".join(lines) + "\n")
    print("wrote %s, %d vertices" % (out, written))
    return 0


if __name__ == "__main__":
    sys.exit(main())
