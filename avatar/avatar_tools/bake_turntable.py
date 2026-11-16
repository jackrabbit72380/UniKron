#!/usr/bin/env python3
"""Bake an orbiting turntable of PNG frames from an OBJ model.

The theme cannot load meshes: Pegasus ships Qt Quick without a 3D scene module,
and the original avatar geometry arrives as LZX-compressed STRB blobs that only
the recomp (AvatarEditorRecomp) decodes. So 3D is baked ahead of time into the
frames AvatarStage3D.png plays, and this is what bakes them.

    # Export the avatar from Avatar Aura (Export tab -> OBJ, or avatarextract),
    # then:
    python3 bake_turntable.py avatar.obj ../../assets/3d/turntable --frames 24

Frames are written as frame_00.png, frame_01.png, ... in yaw order, RGBA with a
transparent background, with the feet at the bottom of the frame.

Rendering is a flat-shaded painter with a z-buffer: enough to read the shapes of
a stylised avatar, and it uses nothing but numpy and zlib, so it runs anywhere
the theme is built.
"""

import argparse
import math
import os
import struct
import zlib

import numpy as np


def parse_mtl(path):
    """Kd r g b per material name, straight out of a .mtl next to the .obj."""
    colours = {}
    name = None
    if not path or not os.path.exists(path):
        return colours
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            parts = line.split()
            if not parts:
                continue
            if parts[0] == "newmtl" and len(parts) > 1:
                name = parts[1]
            elif parts[0] == "Kd" and name and len(parts) >= 4:
                try:
                    colours[name] = tuple(float(v) for v in parts[1:4])
                except ValueError:
                    pass
    return colours


def read_obj(path):
    """Vertices, triangles and a per-triangle colour, from an .obj file."""
    verts = []
    vert_colours = []
    tris = []
    tri_colours = []
    mtl_colours = {}
    current = (0.72, 0.63, 0.55)  # skin-ish, used when the model has no material

    base = os.path.dirname(os.path.abspath(path))
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            parts = line.split()
            if not parts:
                continue
            tag = parts[0]
            if tag == "v" and len(parts) >= 4:
                verts.append(tuple(float(v) for v in parts[1:4]))
                # Extended form "v x y z r g b": baked vertex colours.
                vert_colours.append(tuple(float(v) for v in parts[4:7])
                                    if len(parts) >= 7 else None)
            elif tag == "mtllib" and len(parts) > 1:
                mtl_colours.update(parse_mtl(os.path.join(base, parts[1])))
            elif tag == "usemtl" and len(parts) > 1:
                current = mtl_colours.get(parts[1], current)
            elif tag == "f" and len(parts) >= 4:
                idx = []
                for token in parts[1:]:
                    raw = token.split("/")[0]
                    if not raw:
                        continue
                    i = int(raw)
                    idx.append(i - 1 if i > 0 else len(verts) + i)
                # Fan triangulation: quads are common in exported models.
                for k in range(1, len(idx) - 1):
                    tris.append((idx[0], idx[k], idx[k + 1]))
                    # Per-vertex colours win over the material: a baked avatar
                    # carries its skin and hair tone in the OBJ itself.
                    corner = [vert_colours[i] for i in idx[k - 1:k + 2]]
                    if all(c is not None for c in corner):
                        tri_colours.append(tuple(sum(c[j] for c in corner) / 3.0
                                                 for j in range(3)))
                    else:
                        tri_colours.append(current)

    if not tris:
        raise SystemExit("no faces in " + path)
    return np.array(verts, dtype=np.float64), np.array(tris, dtype=np.int64), np.array(
        tri_colours, dtype=np.float64
    )


def normalise(verts):
    """Centre on x/z, feet at y=0, one unit tall: the frame is a fixed camera.

    x and z are centred on the median, not on the bounding box: an avatar in its
    bind pose has one arm held out sideways, and box-centring that puts the body
    itself hard against the edge of the frame.
    """
    lo = verts.min(axis=0)
    hi = verts.max(axis=0)
    verts = verts - np.array([np.median(verts[:, 0]), lo[1], np.median(verts[:, 2])])
    height = max(hi[1] - lo[1], 1e-6)
    verts /= height
    return verts


def vertex_normals(verts, tris):
    """Smooth per-vertex normals from welded positions.

    The rasteriser used to shade per face, which turned every curved surface into
    facets - fingers read as spikes and the whole figure looked chiselled rather
    than soft, the way the XTL renderer draws it. Welding by position first is
    what makes shared vertices share one normal.
    """
    welded, inverse = np.unique(np.round(verts, 5), axis=0, return_inverse=True)
    corner = inverse[tris]
    face_n = np.cross(
        verts[tris[:, 1]] - verts[tris[:, 0]],
        verts[tris[:, 2]] - verts[tris[:, 0]],
    )
    length = np.linalg.norm(face_n, axis=1)
    length[length == 0] = 1.0
    face_n = face_n / length[:, None]
    total = np.zeros((len(welded), 3), dtype=np.float64)
    for k in range(3):
        np.add.at(total, corner[:, k], face_n)
    length = np.linalg.norm(total, axis=1)
    length[length == 0] = 1.0
    # Un-weld back to one normal per original vertex, so indices stay valid.
    return (total / length[:, None])[inverse]


def rotation_y(angle):
    c, s = math.cos(angle), math.sin(angle)
    return np.array([[c, 0.0, s], [0.0, 1.0, 0.0], [-s, 0.0, c]])


def rotation_x(angle):
    c, s = math.cos(angle), math.sin(angle)
    return np.array([[1.0, 0.0, 0.0], [0.0, c, -s], [0.0, s, c]])


def read_png(path):
    """RGBA 8-bit, non-interlaced PNG as a float array (h, w, 4) in 0..1.

    Only the files this toolchain writes (bake_avatar's mask sheets), so this
    implements exactly that subset: no palette, no 16-bit, no interlacing.
    """
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit("not a PNG: " + path)
    pos, width, height, channels = 8, 0, 0, 4
    payload = b""
    while pos + 8 <= len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        tag = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if tag == b"IHDR":
            width, height, depth, colour, _, _, interlace = struct.unpack(">IIBBBBB", body)
            if depth != 8 or colour != 6 or interlace:
                raise SystemExit("unsupported PNG: " + path)
        elif tag == b"IDAT":
            payload += body
        elif tag == b"IEND":
            break
    raw = zlib.decompress(payload)
    stride = width * channels
    out = np.zeros((height, stride), dtype=np.uint8)
    prev = np.zeros(stride, dtype=np.uint8)
    offset = 0
    for row in range(height):
        kind = raw[offset]
        line = np.frombuffer(raw[offset + 1:offset + 1 + stride], dtype=np.uint8).astype(np.int16)
        offset += 1 + stride
        if kind == 0:
            fixed = line
        elif kind == 2:
            fixed = (line + prev.astype(np.int16)) & 0xFF
        else:
            # Sub, Average and Paeth all need the reconstructed left pixel.
            fixed = line.copy()
            for i in range(stride):
                left = int(fixed[i - channels]) if i >= channels else 0
                up = int(prev[i])
                corner = int(prev[i - channels]) if i >= channels else 0
                if kind == 1:
                    value = line[i] + left
                elif kind == 3:
                    value = line[i] + ((left + up) >> 1)
                else:
                    p = left + up - corner
                    pa, pb, pc = abs(p - left), abs(p - up), abs(p - corner)
                    predictor = left if (pa <= pb and pa <= pc) else (up if pb <= pc else corner)
                    value = line[i] + predictor
                fixed[i] = value & 0xFF
        out[row] = fixed.astype(np.uint8)
        prev = out[row]
    return (out.reshape(height, width, channels).astype(np.float64) / 255.0)


def load_face(obj_path):
    """The head's mask sheets and per-corner UVs, if bake_avatar wrote them."""
    stem = obj_path[:-4] if obj_path.endswith(".obj") else obj_path
    path = stem + ".face.npz"
    if not os.path.exists(path):
        return None
    data = np.load(path, allow_pickle=False)
    base = os.path.dirname(os.path.abspath(obj_path))
    layers = []
    for i, name in enumerate(data["masks"]):
        layers.append({
            "mask": read_png(os.path.join(base, str(name))),
            "role": str(data["roles"][i]) if "roles" in data else "brow",
            "tint": np.power(np.clip(data["tints"][i], 0.0, 1.0), 2.2) if "tints" in data
                    else np.array([0.2, 0.12, 0.08]),
        })
    out = {"start": int(data["start"][0]), "uvs": data["uvs"], "layers": layers}
    if "uvsets" in data:
        out["uvsets"] = data["uvsets"]
    return out


def sample_mask(mask, u, v):
    """Bilinear sample of an RGBA sheet, clamped to its edge."""
    height, width = mask.shape[:2]
    x = np.clip(u, 0.0, 1.0) * (width - 1)
    y = np.clip(v, 0.0, 1.0) * (height - 1)
    x0 = np.floor(x).astype(np.int64)
    y0 = np.floor(y).astype(np.int64)
    x1 = np.minimum(x0 + 1, width - 1)
    y1 = np.minimum(y0 + 1, height - 1)
    fx = (x - x0)[..., None]
    fy = (y - y0)[..., None]
    top = mask[y0, x0] * (1 - fx) + mask[y0, x1] * fx
    bottom = mask[y1, x0] * (1 - fx) + mask[y1, x1] * fx
    return top * (1 - fy) + bottom * fy


def write_png(path, rgba):
    """Minimal RGBA PNG writer: 8-bit, no interlacing, one IDAT."""
    height, width, _ = rgba.shape
    raw = b"".join(b"\x00" + rgba[row].tobytes() for row in range(height))

    def chunk(tag, data):
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    with open(path, "wb") as fh:
        fh.write(b"\x89PNG\r\n\x1a\n")
        fh.write(chunk(b"IHDR", header))
        fh.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        fh.write(chunk(b"IEND", b""))


# The XTL avatar renderer's own light rig, taken from its shader parameter table.
#
# `xtl_constants.py strings` on the renderer's ELF prints the names it binds per
# avatar draw call, packed in one blob at 0x92125f16:
#
#     ambientColour / enableShadows / jitterMap / lightColour1..3 /
#     lightDirection1..3 / oneMinusShadowStrength / rimLightColour /
#     shadowMap / shadowSizes
#
# so the model is: one ambient colour, THREE directional lights each with its own
# colour and direction, plus a rim term and a shadow strength. That is the
# structure below, and it is why this file no longer shades with one light.
#
# The numbers are this port's, not the binary's: the renderer is handed light
# values by whatever scene drives it, and none are stored as constants in the
# image (see LIGHTING_NOTES below). They are picked to read like the reference
# avatars' matte, softly lit look: a warm key, a cool fill, a low back light and
# a dim rim.
XTL_AMBIENT_COLOUR = np.array([0.34, 0.34, 0.36])
XTL_LIGHT_COLOUR = (
    np.array([1.00, 0.96, 0.90]),     # lightColour1 - warm key, front left above
    np.array([0.55, 0.62, 0.78]),     # lightColour2 - cool fill, front right
    np.array([0.30, 0.30, 0.34]),     # lightColour3 - back light, fills the silhouette
)
# Recovered, not chosen. These three unit vectors are the first three of a run of
# five that appears, byte for byte, in the effect blobs of all three avatar pixel
# shaders in the editor (`shader_body_opaque_ps.updb` at 0x98019cdc,
# `..._body_transparent_ps.updb` at 0x9801aacc, `..._head_opaque_ps.updb` at
# 0x9801b990 - same values at the same offset inside each blob). They are the
# shader's lightDirection1..3 defaults: an overhead key slightly toward camera, a
# front-right fill and a back-left rim.
XTL_LIGHT_DIRECTION = (
    np.array([0.000, 1.000, -0.040]),     # lightDirection1
    np.array([0.440, 0.528, -0.757]),     # lightDirection2
    np.array([-0.670, -0.419, 0.575]),    # lightDirection3
)
XTL_RIM_COLOUR = np.array([0.16, 0.16, 0.18])
# Every avatar shader in the pack multiplies its shadow term by this, so the rig
# is not meant to be lit at full strength head-on; a little of it keeps the fold
# shading from going flat.
XTL_ONE_MINUS_SHADOW_STRENGTH = 0.85

LIGHTING_NOTES = """
Where the numbers are not
-------------------------
The renderer defines the rig but carries no default values for it, checked
three ways: no pointer to the parameter-name blob exists anywhere in the image
(every section searched for its address), .data holds only seven runs of three
unit-length vectors and none is a light rig with colours, and the 2,320 float
loads the code makes from .rdata land on matrices, zeros and NaN padding rather
than a contiguous rig. The values arrive from the scene that drives the
renderer, which is the editor, and the editor's own decompilation (1,986
functions) contains no float literals either - it ships as code, not data.
"""


def _unit(v):
    return v / np.linalg.norm(v)


def render(verts, tris, tri_colours, vnormals, yaw, width, height, ss=2, face=None):
    """One frame: yaw the model, project, rasterise with a z-buffer.

    Normals are interpolated across each triangle and lit per pixel, so curved
    surfaces stay smooth at any frame size.
    """
    w, h = width * ss, height * ss
    # Normalised space has the feet at y = 0 and the head at y = 1. An
    # orthographic fit keeps the whole figure the same size in every frame and
    # cannot clip it the way a fixed focal length did.
    rot = rotation_x(math.radians(-6.0)) @ rotation_y(yaw)
    model = verts @ rot.T
    normals = vnormals @ rot.T
    z = model[:, 2]
    k = 0.86 * h
    sx = model[:, 0] * k + w * 0.5
    sy = (0.5 - model[:, 1]) * k + h * 0.5

    colour = np.zeros((h, w, 3), dtype=np.float64)
    depth = np.full((h, w), np.inf)
    alpha = np.zeros((h, w), dtype=bool)

    light_dirs = [_unit(d) for d in XTL_LIGHT_DIRECTION]
    light_colours = [c * XTL_ONE_MINUS_SHADOW_STRENGTH for c in XTL_LIGHT_COLOUR]
    view_dir = np.array([0.0, 0.0, -1.0])

    # Lighting happens in linear light: sRGB-encoded colours shaded directly come
    # out chalky in the highlights and muddy in the folds.
    linear = np.power(np.clip(tri_colours, 0.0, 1.0), 2.2)

    for t in range(len(tris)):
        x0, x1, x2 = sx[tris[t, 0]], sx[tris[t, 1]], sx[tris[t, 2]]
        y0, y1, y2 = sy[tris[t, 0]], sy[tris[t, 1]], sy[tris[t, 2]]
        minx = max(int(math.floor(min(x0, x1, x2))), 0)
        maxx = min(int(math.ceil(max(x0, x1, x2))), w - 1)
        miny = max(int(math.floor(min(y0, y1, y2))), 0)
        maxy = min(int(math.ceil(max(y0, y1, y2))), h - 1)
        if minx > maxx or miny > maxy:
            continue
        area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
        if abs(area) < 1e-9:
            continue
        xs = np.arange(minx, maxx + 1) + 0.5
        ys = np.arange(miny, maxy + 1) + 0.5
        px, py = np.meshgrid(xs, ys)
        w0 = ((x1 - px) * (y2 - py) - (x2 - px) * (y1 - py)) / area
        w1 = ((x2 - px) * (y0 - py) - (x0 - px) * (y2 - py)) / area
        w2 = 1.0 - w0 - w1
        inside = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
        if not inside.any():
            continue

        # Barycentric interpolation of the vertex normals, then per-pixel light.
        n = (
            w0[..., None] * normals[tris[t, 0]]
            + w1[..., None] * normals[tris[t, 1]]
            + w2[..., None] * normals[tris[t, 2]]
        )
        length = np.linalg.norm(n, axis=2)
        length[length == 0] = 1.0
        n = n / length[..., None]
        facing = n @ view_dir
        flip = facing > 0.0
        n[flip] *= -1.0
        # Three directional lights plus ambient, exactly the terms the shader
        # parameter table names, with the rim added on top of the albedo.
        light = np.broadcast_to(XTL_AMBIENT_COLOUR, n.shape).copy()
        for direction, light_colour in zip(light_dirs, light_colours):
            lambert = np.clip(n @ direction, 0.0, 1.0)[..., None]
            light += lambert * light_colour
        rim = np.power(np.clip(1.0 - np.abs(n @ view_dir), 0.0, 1.0), 3.0)[..., None]
        light += rim * XTL_RIM_COLOUR
        # The head composites its brow, eye and mouth sheets per pixel. Mask
        # alpha over skin, then the same light rig as everything else: sampling
        # per triangle instead turned the smirk line and the eye art into a
        # mosaic of blocks, which is what made the face look wrong.
        albedo = linear[t]
        if face is not None and face["start"] <= t < face["start"] + len(face["uvs"]):
            corners = face["uvs"][t - face["start"]]
            albedo = np.broadcast_to(linear[t], (w0.shape[0], w0.shape[1], 3)).copy()
            for m, layer in enumerate(face["layers"]):
                u = w0 * corners[m][0][0] + w1 * corners[m][1][0] + w2 * corners[m][2][0]
                v = w0 * corners[m][0][1] + w1 * corners[m][1][1] + w2 * corners[m][2][1]
                texel = sample_mask(layer["mask"], u, v)
                # The sheets are tint masks: alpha is the shape, R the tinted
                # zone (brow hair, iris) and B the secondary one (sclera, lip
                # line). Painting the raw channels drew red brows and a red
                # iris, which is what made the face look wrong.
                coverage = texel[..., 3:4]
                if layer["role"] == "eye":
                    sclera = np.array([0.90, 0.90, 0.93]) ** 2.2
                    albedo = sclera * (coverage * texel[..., 2:3]) + albedo * (1.0 - coverage * texel[..., 2:3])
                    iris = coverage * texel[..., 0:1]
                    albedo = layer["tint"] * iris + albedo * (1.0 - iris)
                else:
                    albedo = layer["tint"] * coverage + albedo * (1.0 - coverage)
            # Decal sheets (beard, face paint) are painted art rather than tint
            # masks: composite their colour over the skin by their own alpha.
            for decal in face.get("decals") or []:
                corners_d = decal["uvs"][t - face["start"]]
                u = (w0 * corners_d[0][0] + w1 * corners_d[1][0]
                     + w2 * corners_d[2][0])
                v = (w0 * corners_d[0][1] + w1 * corners_d[1][1]
                     + w2 * corners_d[2][1])
                texel = sample_mask(decal["texture"], u, v)
                art = np.power(np.clip(texel[..., :3], 0.0, 1.0), 2.2)
                cover = texel[..., 3:4] * decal.get("gain", 1.0)
                albedo = art + albedo * (1.0 - cover)
        shaded = np.power(
            np.clip(albedo * light, 0.0, 1.0), 1.0 / 2.2
        )

        zz = (
            w0 * (z[tris[t, 0]]) + w1 * (z[tris[t, 1]]) + w2 * (z[tris[t, 2]])
        )
        if miny > maxy or minx > maxx:
            continue
        sub_depth = depth[miny : maxy + 1, minx : maxx + 1]
        sub_colour = colour[miny : maxy + 1, minx : maxx + 1]
        sub_alpha = alpha[miny : maxy + 1, minx : maxx + 1]
        if sub_depth.shape != inside.shape:
            # A sliver clipped at the frame edge can leave an empty window.
            continue
        nearer = inside & (zz < sub_depth)
        sub_depth[nearer] = zz[nearer]
        sub_colour[nearer] = shaded[nearer]
        sub_alpha[nearer] = True

    if ss > 1:
        colour = colour.reshape(height, ss, width, ss, 3).mean(axis=(1, 3))
        alpha = alpha.reshape(height, ss, width, ss).mean(axis=(1, 3)) > 0.5

    rgba = np.zeros((height, width, 4), dtype=np.uint8)
    rgba[..., :3] = np.clip(colour * 255.0, 0, 255).astype(np.uint8)
    rgba[..., 3] = np.where(alpha, 255, 0).astype(np.uint8)
    return rgba


def main():
    parser = argparse.ArgumentParser(description="Bake a turntable of PNG frames from an OBJ.")
    parser.add_argument("obj", help="model to bake (OBJ, with an optional MTL)")
    parser.add_argument("outdir", help="folder to write frame_00.png ... into")
    parser.add_argument("--frames", type=int, default=24, help="frames around the circle")
    parser.add_argument("--width", type=int, default=512)
    parser.add_argument("--height", type=int, default=768)
    parser.add_argument("--start", type=float, default=0.0, help="starting yaw in degrees")
    parser.add_argument("--flip-y", action="store_true",
                        help="negate y first (the pack's bodies are Y-down)")
    args = parser.parse_args()

    verts, tris, tri_colours = read_obj(args.obj)
    face = load_face(args.obj)
    if args.flip_y:
        verts[:, 1] = -verts[:, 1]
    verts = normalise(verts)
    vnormals = vertex_normals(verts, tris)
    os.makedirs(args.outdir, exist_ok=True)

    for i in range(args.frames):
        yaw = math.radians(args.start) + 2.0 * math.pi * i / args.frames
        rgba = render(verts, tris, tri_colours, vnormals, yaw, args.width, args.height, face=face)
        path = os.path.join(args.outdir, "frame_%02d.png" % i)
        write_png(path, rgba)
        print(path, rgba.shape[1], "x", rgba.shape[0])

    print("baked %d frames from %d triangles into %s" % (args.frames, len(tris), args.outdir))


if __name__ == "__main__":
    main()
