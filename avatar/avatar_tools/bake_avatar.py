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
import os
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


FACE_DEFAULT = ("Straight Eyebrows", "Happy Eyes", "Smirk Mouth")
# Eyebrow, eye and mouth UV sets on the head (verified by drawing: swapping
# the first two puts the eyes above the brows, which is backwards).
FACE_SETS = (2, 3, 4)


def load_face_textures(pack, index, names):
    """The three face-feature tint masks the head's UV sets expect."""
    out = []
    for name in names:
        blocks = am.strb_blocks(am.asset_bytes(pack, index, name))
        payload = [b for b in blocks if b[0] == 2]
        if not payload:
            raise SystemExit("%s has no texture" % name)
        data = am.decompress(payload[0][3])

        class Stream(object):
            def __init__(self):
                self.data = data
                self.offset = 33

            def read(self, bits):
                count = bits // 8
                chunk = self.data[self.offset:self.offset + count]
                self.offset += count
                return chunk

        texture = am.read_texture_header(data[:33], Stream())
        texture["_pixels"] = am.decode_dxt(texture["data"], texture["width"], texture["height"],
                                           texture["format"] == 0x14, swap=texture["endian"] == 1)
        out.append(texture)
    return out


def face_triangle_colours(batch, textures, colours):
    """One colour per triangle: skin, or the brow/eye/mouth mask that covers it.

    The head's UV sets 2 and 3 are the eyebrows and eyes (mirrored across the
    nose) and set 4 is the mouth. Sampling all four corners of each triangle
    keeps a mask that lands on a vertex from being missed by its centroid.
    """
    order = [(0, "eyebrows"), (1, "eyes"), (2, "mouth")]
    sets = FACE_SETS
    uvs = batch["uvs"]
    per_triangle = []
    indices = batch["indices"]
    skin = colours["skin"]
    for k in range(0, len(indices), 3):
        tri = indices[k:k + 3]
        points = [(0, 0, 0)] * 4
        for corner in tri:
            for j, si in enumerate(sets):
                u, v = uvs[corner][si] if si < len(uvs[corner]) else (0.0, 0.0)
                points[j] = (points[j][0] + u / 3.0, points[j][1] + v / 3.0, 0)
        best = skin
        for j, si in enumerate(sets):
            u, v = points[j][0], points[j][1]
            # Centroid only: letting one covered corner claim the whole
            # triangle smeared the brow and eye masks across half the face.
            if am.sample_texture(textures[j], u, v, clamp=True) is not None:
                best = colours[order[j][1]]
                break
        per_triangle.append(best)
    return per_triangle


def face_material(colour, colours):
    """A material name for one description colour, so the OBJ can name them."""
    for key in ("skin", "eyebrows", "eyes", "mouth"):
        if key in colours and tuple(colours[key]) == tuple(colour):
            return key
    return "face"


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    colour_args = [a for a in sys.argv if a.startswith("--colours=")]
    hair_args = [a for a in sys.argv if a.startswith("--hair=")]
    face_args = [a for a in sys.argv if a.startswith("--face")]
    if len(args) < 5:
        print(__doc__)
        return 1
    pack, clip, frame, out = args[0], args[1], int(args[2]), args[3]
    assets = args[4:]

    face_textures = None
    colours = slots = None
    if colour_args:
        colours, slots = read_description(colour_args[0].split("=", 1)[1])
    if hair_args:
        # A hairstyle can carry its own colour (blond, red, black): the
        # description only knows the colour of the style it was saved with.
        value = hair_args[0].split("=", 1)[1].lstrip("#")
        colours = dict(colours or {})
        colours.setdefault("skin", (215, 170, 113))
        colours["hair"] = (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))
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
    materials = {}
    face_names = FACE_DEFAULT
    if face_args and "=" in face_args[0]:
        face_names = tuple(face_args[0].split("=", 1)[1].split(","))
    if face_args and colours is not None:
        face_textures = load_face_textures(pack, index, face_names)

    for name in assets:
        batches = []
        for block in am.strb_blocks(am.asset_bytes(pack, index, name)):
            if block[0] == 3:
                batches += am.read_model(am.decompress(block[3]))
        rgb = None
        if colours is not None:
            rgb = asset_colour(name, records.get(name, -1), colours, slots, clothing)
        # The head gets its eyes, brows and mouth from the feature masks, one
        # colour per triangle; every other asset keeps one colour per vertex.
        face_tris = []
        if face_textures and colours is not None and name == "Head":
            for batch in batches:
                face_tris.extend(face_triangle_colours(batch, face_textures, colours))
            for colour in face_tris:
                materials[face_material(colour, colours)] = colour
        tri_cursor = 0
        last_face = None
        for batch in ap.posed_positions(batches, joints, poses):
            base = written
            plain = rgb is None or face_tris
            for v in batch["vertices"]:
                if plain:
                    lines.append("v %.6f %.6f %.6f" % tuple(v))
                else:
                    lines.append("v %.6f %.6f %.6f %.3f %.3f %.3f" % (tuple(v) + rgb))
                written += 1
            indices = batch["indices"]
            for t in range(0, len(indices), 3):
                if face_tris and tri_cursor < len(face_tris):
                    colour = face_tris[tri_cursor]
                    tri_cursor += 1
                    if colour != last_face:
                        lines.append("usemtl %s" % face_material(colour, colours))
                        last_face = colour
                lines.append("f %d %d %d" % (
                    indices[t] + base + 1, indices[t + 1] + base + 1, indices[t + 2] + base + 1))
        print("  posed %s" % name)

    if materials:
        mtl = out + ".mtl" if not out.endswith(".obj") else out[:-4] + ".mtl"
        rows = ["# face colours, from the avatar description"]
        for name, colour in materials.items():
            rows.append("newmtl %s" % name)
            rows.append("Kd %.4f %.4f %.4f" % tuple(c / 255.0 for c in colour))
        open(mtl, "w").write("\n".join(rows) + "\n")
        lines.insert(0, "mtllib %s" % os.path.basename(mtl))
    open(out, "w").write("\n".join(lines) + "\n")
    print("wrote %s, %d vertices" % (out, written))
    return 0


if __name__ == "__main__":
    sys.exit(main())
