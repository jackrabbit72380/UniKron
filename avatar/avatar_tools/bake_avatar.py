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

import numpy as np

import avatar_mesh as am
import decode_shape
import xnb_avatar
import xpr0_export as xpr
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


# The garments a stock avatar wears, and the colours they are drawn in.
#
# The source cannot supply these: a stock asset embeds no texture, and the
# .Avatar description carries skin, hair, mouth, eyes, brows, eye shadow and
# facial hair but no garment slot at all (checked against Avatar6400.Avatar -
# the last two slots are accessory tints, both the same pink). Rendering them
# untinted is what made the 3D avatar look like a grey mannequin, so the stock
# pieces get the palette the 2D wardrobe is drawn in.
CLOTHING_TINTS = {
    "jacket with sweater": (0x46, 0x51, 0x6b),
    "male flower print flares": (0x46, 0x55, 0x7f),
    "grunge trainers": (0x57, 0x5c, 0x63),
    "male power tee": (0x2f, 0x7f, 0xd4),
    "worn jeans": (0x3f, 0x5b, 0x8b),
    "formal shoes": (0x2b, 0x2f, 0x36),
}


# Per-item colour overrides from --tint=Asset=RRGGBB. bake_shirts.py uses these
# to bake one wardrobe piece at a time in the colour the 2D wardrobe draws it.
TINT_OVERRIDES = {}


def asset_colour(name, record, colours, slots, clothing):
    """RGB in 0..1 for one asset: skin and hair from the description, else neutral.

    A stock garment has no colour in the asset (models embed no textures) and no
    slot in the description, so it takes its entry from CLOTHING_TINTS. Anything
    unlisted still falls back to neutral.
    """
    tint = TINT_OVERRIDES.get(name.lower()) or CLOTHING_TINTS.get(name.lower())
    if tint is not None:
        return tuple(c / 255.0 for c in tint)
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


def _ray_hits(points, tris, direction):
    """How many triangles each ray from `points` along `direction` crosses.

    Moller-Trumbore, vectorised over every triangle for a chunk of points. An odd
    number of crossings means the point is inside the closed surface.
    """
    a = tris[:, 0, :]
    e1 = tris[:, 1, :] - a
    e2 = tris[:, 2, :] - a
    d = np.asarray(direction, dtype=np.float64)
    h = np.cross(d, e2)
    det = np.einsum("ij,ij->i", e1, h)
    keep = np.abs(det) > 1e-12
    if not keep.any():
        return np.zeros(len(points), dtype=np.int64)
    a, e1, e2, h, inv = a[keep], e1[keep], e2[keep], h[keep], 1.0 / det[keep]
    counts = np.zeros(len(points), dtype=np.int64)
    for start in range(0, len(points), 128):
        chunk = points[start:start + 128]
        s = chunk[:, None, :] - a[None, :, :]
        u = np.einsum("nmi,mi->nm", s, h) * inv
        q = np.cross(s, e1[None, :, :])
        v = np.einsum("nmi,i->nm", q, d) * inv
        t = np.einsum("nmi,mi->nm", q, e2) * inv
        cross = (u >= 0.0) & (u <= 1.0) & (v >= 0.0) & (u + v <= 1.0) & (t > 0.0)
        counts[start:start + len(chunk)] = cross.sum(axis=1)
    return counts


def enclosed_by(points, tris):
    """Which of `points` lie inside the closed surface `tris`.

    Three axes, majority vote: one ray grazes an edge often enough that a single
    parity test calls a surface vertex inside, and such a vertex would be left
    where it is - outside the cloth, which is the fault being fixed.
    """
    points = np.asarray(points, dtype=np.float64)
    if not len(points) or not len(tris):
        return np.zeros(len(points), dtype=bool)
    votes = np.zeros(len(points), dtype=np.int64)
    for direction in ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)):
        votes += (_ray_hits(points, tris, direction) % 2).astype(np.int64)
    return votes >= 2


def _closest_on_triangles(points, tris):
    """Exact distance from each point to the nearest triangle.

    Vertex-vertex distance was tried first and is not good enough: on a coarse
    garment mesh its nearest corner can be a whole sleeve radius from the surface,
    so the body was pushed by centimetres and the wrist pinched where the cuff met
    it. This is the standard barycentric clamp - project onto the triangle's plane
    and fold the projection back onto the nearest edge when it falls outside.
    """
    a = tris[:, 0, :]
    ab = tris[:, 1, :] - a
    ac = tris[:, 2, :] - a
    bc = tris[:, 2, :] - tris[:, 1, :]
    d00 = np.einsum("mi,mi->m", ab, ab)
    d01 = np.einsum("mi,mi->m", ab, ac)
    d11 = np.einsum("mi,mi->m", ac, ac)
    bc_len = np.einsum("mi,mi->m", bc, bc)
    denom = d00 * d11 - d01 * d01
    denom = np.where(np.abs(denom) < 1e-14, 1e-14, denom)
    best = np.full(len(points), np.inf)
    for start in range(0, len(points), 128):
        chunk = np.asarray(points[start:start + 128], dtype=np.float64)
        rel = chunk[:, None, :] - a[None, :, :]
        d20 = np.einsum("nmi,mi->nm", rel, ab)
        d21 = np.einsum("nmi,mi->nm", rel, ac)
        v = (d11[None, :] * d20 - d01[None, :] * d21) / denom[None, :]
        w = (d00[None, :] * d21 - d01[None, :] * d20) / denom[None, :]
        u = 1.0 - v - w
        inside = (u >= 0.0) & (v >= 0.0) & (w >= 0.0)
        # Plane distance, valid where the projection landed inside the triangle.
        plane = np.abs(u * (1.0 / np.maximum(denom, 1e-14)) *
                       (d00[None, :] * d21 - d01[None, :] * d20) * 0.0)  # placeholder
        # Fold onto the three edges for the rest, which is exact for the outside case.
        t_ab = np.clip(d20 / np.maximum(d00, 1e-14)[None, :], 0.0, 1.0)
        t_ac = np.clip(d21 / np.maximum(d11, 1e-14)[None, :], 0.0, 1.0)
        bp = chunk[:, None, :] - tris[None, :, 1, :]
        d_bc = np.einsum("nmi,mi->nm", bp, bc)
        t_bc = np.clip(d_bc / np.maximum(bc_len, 1e-14)[None, :], 0.0, 1.0)
        gap_ab = np.linalg.norm(chunk[:, None, :] - (a[None] + t_ab[..., None] * ab[None]), axis=2)
        gap_ac = np.linalg.norm(chunk[:, None, :] - (a[None] + t_ac[..., None] * ac[None]), axis=2)
        gap_bc = np.linalg.norm(chunk[:, None, :] - (tris[None, :, 1, :] + t_bc[..., None] * bc[None]), axis=2)
        edge = np.minimum(np.minimum(gap_ab, gap_ac), gap_bc)
        # Inside the triangle: the distance is the component of the offset along the
        # plane normal.
        n = np.cross(ab, ac)
        n_len = np.linalg.norm(n, axis=1)
        n_hat = n / np.maximum(n_len, 1e-14)[:, None]
        flat = np.abs(np.einsum("nmi,mi->nm", rel, n_hat))
        gap = np.where(inside, flat, edge)
        best[start:start + len(chunk)] = gap.min(axis=1)
    return best


def vertex_normals(vertices, indices):
    """Area-weighted vertex normals of one skinned batch."""
    v = np.asarray(vertices, dtype=np.float64)
    idx = np.asarray(indices, dtype=np.int64)
    idx = idx[:len(idx) - len(idx) % 3].reshape(-1, 3)
    tri = v[idx]
    face = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    normals = np.zeros_like(v)
    for corner in range(3):
        np.add.at(normals, idx[:, corner], face)
    length = np.linalg.norm(normals, axis=1)
    length[length < 1e-12] = 1.0
    return normals / length[:, None]


def tuck_under_clothes(batches, tris, limit=0.02, margin=0.002):
    """Push the parts of the body that stand outside a garment back inside it.

    The body and the garment are skinned separately, so at the shoulder the body's
    surface crosses outside the sleeve's and a tan patch shows in the middle of the
    cloth. Deleting the covered body triangles was tried first: it does remove the
    patch, but a garment is a shell with seams, and where a seam is the only thing
    between the two surfaces the deletion opens a see-through sliver down the leg
    and the side of the jacket. Moving the body in keeps the surface under the
    cloth and leaves nothing to see through.

    Two rules were tried and are wrong. Tucking every vertex within reach pulled
    the forearm out to the sleeve it was already inside of; tucking everything
    outside and within 5 cm caught the wrist hanging below the cuff and pinched the
    hand onto the sleeve. What is left is the narrow band that matters: outside the
    garment, and within 2 cm of it.
    """
    moved = 0
    out = []
    for batch in batches:
        v = np.asarray(batch["vertices"], dtype=np.float64).copy()
        if not len(tris):
            out.append(batch)
            continue
        normals = vertex_normals(v, batch["indices"])
        gap = _closest_on_triangles(v, tris)
        hit = (~enclosed_by(v, tris)) & (gap > 0.0) & (gap < limit)
        if hit.any():
            v[hit] -= (gap[hit] + margin)[:, None] * normals[hit]
            moved += int(hit.sum())
        out.append(dict(batch, vertices=v))
    return out, moved


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


def face_triangle_uvs(batch):
    """Per triangle, the UV triple of every face mask, one entry per corner.

    The masks are drawn art, not flat tint regions: the mouth sheet is a thin
    smirk line, the eye sheet carries a lash line, sclera and iris, the brow
    sheet its own hair colour. Painting a triangle with one colour from a mask
    lookup turned all three into blocks with zig-zag edges, so the OBJ now
    carries the UVs and `bake_turntable.py` samples the sheets per pixel.
    """
    uvs = batch["uvs"]
    indices = batch["indices"]
    out = []
    for k in range(0, len(indices), 3):
        tri = indices[k:k + 3]
        per_mask = []
        for si in FACE_SETS:
            per_mask.append([uvs[corner][si] if si < len(uvs[corner]) else (0.0, 0.0)
                             for corner in tri])
        out.append(per_mask)
    return out


def all_uv_sets(batch):
    """Per triangle, every UV set of every corner.

    The face masks use sets 2, 3 and 4, but the head carries six. The rest are
    the ones a beard or face-paint sheet would be painted through, and which is
    which is a question for `probe_decal_render.py`, not for a guess.
    """
    uvs = batch["uvs"]
    indices = batch["indices"]
    sets = max(len(v) for v in uvs) if uvs else 0
    out = []
    for k in range(0, len(indices), 3):
        tri = indices[k:k + 3]
        corners = []
        for corner in tri:
            per_vertex = [uvs[corner][si] if si < len(uvs[corner]) else (0.0, 0.0)
                          for si in range(sets)]
            corners.append(per_vertex)
        out.append(corners)
    return out


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    colour_args = [a for a in sys.argv if a.startswith("--colours=")]
    hair_args = [a for a in sys.argv if a.startswith("--hair=")]
    face_args = [a for a in sys.argv if a.startswith("--face")]
    tint_args = [a for a in sys.argv if a.startswith("--tint=")]
    # --shape="Large Chin" reshapes the Head before skinning, from the decoded
    # block 4. The vertices are the ones the block names, so nothing is guessed.
    shape_args = [a for a in sys.argv if a.startswith("--shape=")]
    # --hide="Hoodie Hiding Template" collapses the body vertices a garment
    # covers, which is what the block-4 hiding templates are for. Without it the
    # skin pokes through trousers and sleeves - visible at the thighs and armpits.
    hide_args = [a for a in sys.argv if a.startswith("--hide=")]
    # --no-tuck turns off the cover pass below. It is on by default because
    # otherwise the skin shows through every sleeve: the body and the garment are
    # skinned separately, so at the shoulder the body's surface crosses outside the
    # sleeve's and a tan patch appears in the middle of the cloth.
    tuck_body = "--no-tuck" not in sys.argv
    # --xnb=PATH[:FRAME] poses the whole avatar from an avatar game's clip
    # instead of the pack's .AvatarAnimation file. Those clips are the only
    # shipped poses that include a resting hand.
    xnb_args = [a for a in sys.argv if a.startswith("--xnb=")]
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

    for value in tint_args:
        asset, _, hexv = value.split("=", 1)[1].rpartition("=")
        hexv = hexv.lstrip("#")
        TINT_OVERRIDES[asset.lower()] = (int(hexv[0:2], 16), int(hexv[2:4], 16),
                                        int(hexv[4:6], 16))

    index = am.load_pack_index(pack)
    hidden_by_batch = []
    hide_entries = []
    if hide_args:
        for spec in hide_args:
            for one in spec.split("=", 1)[1].split(","):
                one = one.strip()
                if not one:
                    continue
                decoded = decode_shape.decode(one, pack, 0)
                hide_entries.extend(decoded["section_b"]["entries"])
        print("hiding %d body vertices for %s"
              % (len(hide_entries), ", ".join(a.split("=", 1)[1] for a in hide_args)))

    shape_entries = None
    shape_name = None
    if shape_args:
        shape_name = shape_args[0].split("=", 1)[1]
        decoded = decode_shape.decode(shape_name, pack, 0)
        shape_entries = decoded["section_b"]["entries"]
        print("shape %s: %d vertices, stride %s"
              % (shape_name, len(shape_entries), decoded["strides"]))
    records = am.record_indices(pack)
    joints = sk.read_skeleton()
    payload = [b for b in am.strb_blocks(open(clip, "rb").read()) if b[0] == 1]
    if not payload:
        raise SystemExit("no animation block in " + clip)
    poses, frames = ap.read_animation_poses(payload[0][3], frame)
    print("%s frame %d/%d" % (clip.split("/")[-1], frame, frames))

    if xnb_args:
        value = xnb_args[0].split("=", 1)[1]
        path, _, wanted = value.partition(":")
        wanted = int(wanted) if wanted else frame
        try:
            game = xnb_avatar.read_clip(path)
            poses = xnb_avatar.poses(game, wanted)
            print("xnb %s: %d frames, using frame %d"
                  % (os.path.basename(path), len(game["frames"]), wanted))
        except ValueError:
            # The Digital DNA games (Laser Wars 2, Warfare, Connection) use a
            # different reader and a static pose per bone.
            game = xnb_avatar.read_dna(path)
            poses = xnb_avatar.dna_poses(game, 0)
            print("dna %s: %d bones, static pose"
                  % (os.path.basename(path), len(game["bones"])))

    lines = []
    written = 0
    materials = {}
    face_start = 0
    face_uvs = []
    face_uvex = []
    face_total = 0
    face_names = FACE_DEFAULT
    if face_args and "=" in face_args[0]:
        face_names = tuple(face_args[0].split("=", 1)[1].split(","))
    if face_args and colours is not None:
        face_textures = load_face_textures(pack, index, face_names)

    # Garment triangles in posed space, for the cover test. They are posed once
    # here, before the body is written, because the body is first in the parts
    # list and its triangles have to be decided before they are emitted.
    garment_tris = []
    if tuck_body:
        for garment in assets:
            if garment in ("MaleBody", "FemaleBody", "Head"):
                continue
            gbatches = []
            for block in am.strb_blocks(am.asset_bytes(pack, index, garment)):
                if block[0] == 3:
                    gbatches += am.read_model(am.decompress(block[3]))
            if not gbatches:
                continue
            for gbatch in ap.posed_positions(gbatches, joints, poses):
                v = np.asarray(gbatch["vertices"], dtype=np.float64)
                idx = np.asarray(gbatch["indices"], dtype=np.int64)
                if len(idx) >= 3:
                    tri = idx[:len(idx) - len(idx) % 3].reshape(-1, 3)
                    garment_tris.append(v[tri])

    for name in assets:
        # Vertex numbers restart with every asset, so the hidden set does too; kept
        # across assets it deleted the same indices from the head and the clothes.
        hidden_by_batch = []
        batches = []
        for block in am.strb_blocks(am.asset_bytes(pack, index, name)):
            if block[0] == 3:
                batches += am.read_model(am.decompress(block[3]))
        rgb = None
        if colours is not None:
            rgb = asset_colour(name, records.get(name, -1), colours, slots, clothing)
        # The head gets its eyes, brows and mouth from the feature masks, one
        # colour per triangle; every other asset keeps one colour per vertex.
        # The head is textured with the face sheets by the renderer, so its
        # geometry stays flat-coloured and carries UVs in a sidecar instead.
        if face_textures and name == "Head":
            face_start = face_total
            for batch in batches:
                face_uvs.extend(face_triangle_uvs(batch))
                face_uvex.extend(all_uv_sets(batch))
        # A shape moves the head in bind pose, before the rig poses it, so the
        # skinning carries the new geometry into the animation rather than the
        # animation overriding it. Vertex numbers run across the batches in order.
        if shape_entries and name == "Head":
            offset = 0
            moved = 0
            for batch in batches:
                v = np.asarray(batch["vertices"], dtype=np.float64).copy()
                for e in shape_entries:
                    if e["vertex"] is None:
                        continue
                    i = e["vertex"] - offset
                    if 0 <= i < len(v):
                        v[i] = e["xyz"]
                        moved += 1
                batch["vertices"] = v
                offset += len(v)
            print("  shaped %s: %d of %d vertices" % (name, moved, offset))
        # A hiding template names the body vertices its garment covers and gives
        # their position; the vertices themselves are collapsed to one point, so
        # the triangles under the cloth disappear instead of poking through it.
        hidden_by_batch = [set() for _ in batches]
        if hide_entries and name in ("MaleBody", "FemaleBody"):
            # Collapsing the covered vertices to one point was tried and produced
            # spikes: the triangles that survive stretch from that point out to the
            # surface. Hiding means dropping every triangle that uses them, so the
            # cloth is the only surface there.
            offset = 0
            hidden = 0
            for batch_index, batch in enumerate(batches):
                count = len(batch["vertices"])
                inside = set()
                for e in hide_entries:
                    if e["vertex"] is None:
                        continue
                    i = e["vertex"] - offset
                    if 0 <= i < count:
                        inside.add(i)
                hidden_by_batch[batch_index] |= inside
                hidden += len(inside)
                offset += count
            print("  hiding %d of %d vertices on %s" % (hidden, offset, name))
        skipped = 0
        posed = ap.posed_positions(batches, joints, poses)
        if tuck_body and garment_tris and name in ("MaleBody", "FemaleBody"):
            posed, tucked = tuck_under_clothes(posed, np.concatenate(garment_tris))
            print("  tucked %d body vertices under %d garment batch(es)"
                  % (tucked, len(garment_tris)))
        for batch_index, batch in enumerate(posed):
            base = written
            plain = rgb is None
            for v in batch["vertices"]:
                if plain:
                    lines.append("v %.6f %.6f %.6f" % tuple(v))
                else:
                    lines.append("v %.6f %.6f %.6f %.3f %.3f %.3f" % (tuple(v) + rgb))
                written += 1
            indices = batch["indices"]
            gone = hidden_by_batch[batch_index] if batch_index < len(hidden_by_batch) else set()
            for t in range(0, len(indices), 3):
                tri = (indices[t], indices[t + 1], indices[t + 2])
                if gone and (tri[0] in gone or tri[1] in gone or tri[2] in gone):
                    skipped += 1
                    continue
                lines.append("f %d %d %d" % (tri[0] + base + 1, tri[1] + base + 1, tri[2] + base + 1))
                face_total += 1
        print("  posed %s%s" % (name, " (hid %d triangles)" % skipped if skipped else ""))

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

    if face_uvs:
        # Mask sheets plus the per-corner UVs the renderer samples them with.
        # A separate file keeps the OBJ a plain OBJ and keeps this optional.
        stem = out[:-4] if out.endswith(".obj") else out
        names = []
        for i, texture in enumerate(face_textures):
            path = "%s.mask%d.png" % (stem, i)
            xpr.write_png(path, texture["_pixels"])
            names.append(os.path.basename(path))
        # Roles and tints: the sheets are channel masks, not final art. Green
        # is unused; R marks the tinted zone (brow hair, iris), B the secondary
        # one (sclera, lip line). The colours come from the .Avatar description,
        # which is where the editor keeps brow, eye and mouth tone.
        roles = np.array(["brow", "eye", "mouth"])
        tints = np.array([colours["eyebrows"], colours["eyes"], colours["mouth"]],
                         dtype=np.float32) / 255.0
        np.savez(stem + ".face.npz",
                 start=np.array([face_start], dtype=np.int64),
                 uvs=np.array(face_uvs, dtype=np.float32),
                 masks=np.array(names), roles=roles, tints=tints,
                 uvsets=np.array(face_uvex, dtype=np.float32) if face_uvex else
                 np.zeros((0, 3, 0, 2), dtype=np.float32))
        print("wrote %s (%d face triangles, %d mask sheets)"
              % (stem + ".face.npz", len(face_uvs), len(names)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
