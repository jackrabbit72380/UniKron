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
import sys

import avatar_mesh as am
import avatar_pose as ap
import skeleton_nxe as sk


def main():
    if len(sys.argv) < 6:
        print(__doc__)
        return 1
    pack, clip, frame, out = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
    assets = sys.argv[5:]

    index = am.load_pack_index(pack)
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
        for batch in ap.posed_positions(batches, joints, poses):
            base = written
            for v in batch["vertices"]:
                lines.append("v %.6f %.6f %.6f" % tuple(v))
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
