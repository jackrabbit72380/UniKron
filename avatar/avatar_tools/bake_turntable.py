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


def rotation_y(angle):
    c, s = math.cos(angle), math.sin(angle)
    return np.array([[c, 0.0, s], [0.0, 1.0, 0.0], [-s, 0.0, c]])


def rotation_x(angle):
    c, s = math.cos(angle), math.sin(angle)
    return np.array([[1.0, 0.0, 0.0], [0.0, c, -s], [0.0, s, c]])


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


def render(verts, tris, tri_colours, yaw, width, height, ss=2):
    """One frame: yaw the model, project, rasterise with a z-buffer."""
    w, h = width * ss, height * ss
    model = verts @ rotation_y(yaw).T
    # Normalised space has the feet at y = 0 and the head at y = 1. An
    # orthographic fit keeps the whole figure the same size in every frame and
    # cannot clip it the way a fixed focal length did.
    model = model @ rotation_x(math.radians(-6.0)).T
    z = model[:, 2]
    k = 0.86 * h
    sx = model[:, 0] * k + w * 0.5
    sy = (0.5 - model[:, 1]) * k + h * 0.5

    colour = np.zeros((h, w, 3), dtype=np.float64)
    depth = np.full((h, w), np.inf)
    alpha = np.zeros((h, w), dtype=bool)

    light = np.array([-0.35, 0.55, -0.75])
    light /= np.linalg.norm(light)

    p0 = model[tris[:, 0]]
    p1 = model[tris[:, 1]]
    p2 = model[tris[:, 2]]
    face_n = np.cross(p1 - p0, p2 - p0)
    lengths = np.linalg.norm(face_n, axis=1)
    lengths[lengths == 0] = 1.0
    face_n = face_n / lengths[:, None]
    lambert = 0.34 + 0.66 * np.abs(face_n @ light)
    colours = np.clip(tri_colours * lambert[:, None], 0.0, 1.0)

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
        zz = (
            w0 * (z[tris[t, 0]]) + w1 * (z[tris[t, 1]]) + w2 * (z[tris[t, 2]])
        )
        sub_depth = depth[miny : maxy + 1, minx : maxx + 1]
        sub_colour = colour[miny : maxy + 1, minx : maxx + 1]
        sub_alpha = alpha[miny : maxy + 1, minx : maxx + 1]
        nearer = inside & (zz < sub_depth)
        sub_depth[nearer] = zz[nearer]
        sub_colour[nearer] = colours[t]
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
    if args.flip_y:
        verts[:, 1] = -verts[:, 1]
    verts = normalise(verts)
    os.makedirs(args.outdir, exist_ok=True)

    for i in range(args.frames):
        yaw = math.radians(args.start) + 2.0 * math.pi * i / args.frames
        rgba = render(verts, tris, tri_colours, yaw, args.width, args.height)
        path = os.path.join(args.outdir, "frame_%02d.png" % i)
        write_png(path, rgba)
        print(path, rgba.shape[1], "x", rgba.shape[0])

    print("baked %d frames from %d triangles into %s" % (args.frames, len(tris), args.outdir))


if __name__ == "__main__":
    main()
