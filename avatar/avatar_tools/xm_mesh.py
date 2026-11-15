#!/usr/bin/env python3
"""Decode an `.xm` dashboard mesh: a header, a vertex buffer, an index buffer.

    python3 xm_mesh.py IN.xm OUT.obj
    python3 xm_mesh.py IN.xm --stats
    python3 xm_mesh.py IN.xm --render OUT.png
    python3 xm_mesh.py --all SRCDIR OUTDIR

Layout, verified against all 74 meshes in the archive (every one satisfies
`24 + vertices * stride + indices * 2 == file size` exactly):

    u32 version = 4
    u32 triangle count (index count / 3 - an independent cross-check)
    u32 unknown (a float bit pattern on some meshes, a small integer on others)
    u32 vertex stride in bytes (24 or 32)
    u32 vertex count
    u32 index count
    vertices: count * stride bytes of f32, position in the first three
    indices:  u16 triangle list, values 0 .. count-1 (triangle strips in the
              scene's terms, but the values form plain triangles)

A 24-byte stride is position + normal; a 32-byte stride adds one uv pair. The
dashboard's `.xm` names come from the scene files that reference them, `DEF
<node> Mesh { url "<node>-FACES.xm" }`, so each file is one flat-shaded part
of a screen's orb.
"""
import os
import struct
import sys


def read(path):
    """(positions, normals, uvs, indices, header) or raise ValueError."""
    with open(path, "rb") as fh:
        data = fh.read()
    if len(data) < 24:
        raise ValueError("shorter than the 24-byte header")
    version, spare1, spare2, stride, vcount, icount = struct.unpack_from("<6I", data, 0)
    if version != 4:
        raise ValueError("version %d, expected 4" % version)
    if stride % 4 or stride < 12:
        raise ValueError("stride %d is not a whole number of floats" % stride)
    expected = 24 + vcount * stride + icount * 2
    if expected != len(data):
        raise ValueError("header says %d bytes, file is %d" % (expected, len(data)))
    width = stride // 4
    floats = struct.unpack_from("<%df" % (vcount * width), data, 24)
    stride_pos = [i * width for i in range(vcount)]
    positions = [(floats[o], floats[o + 1], floats[o + 2]) for o in stride_pos]
    # 24 bytes of position and normal; 32 bytes add uv after the normal. A
    # shorter stride carries the position alone.
    if width >= 6:
        normals = [(floats[o + 3], floats[o + 4], floats[o + 5]) for o in stride_pos]
    else:
        normals = [(0.0, 1.0, 0.0)] * vcount
    uvs = ([(floats[o + 6], floats[o + 7]) for o in stride_pos]
           if width >= 8 else [(0.0, 0.0)] * vcount)
    offset = 24 + vcount * stride
    indices = struct.unpack_from("<%dH" % icount, data, offset)
    if any(i >= vcount for i in indices):
        raise ValueError("an index points past the vertex buffer")
    return positions, normals, uvs, indices, (version, spare1, spare2, stride, vcount, icount)


def write_obj(path, positions, normals, uvs, indices):
    with open(path, "w") as fh:
        fh.write("# decoded from an Xbox dashboard .xm mesh\n")
        for x, y, z in positions:
            fh.write("v %.6f %.6f %.6f\n" % (x, y, z))
        for u, v in uvs:
            fh.write("vt %.6f %.6f\n" % (u, 1.0 - v))
        for x, y, z in normals:
            fh.write("vn %.6f %.6f %.6f\n" % (x, y, z))
        for t in range(0, len(indices) - 2, 3):
            a, b, c = indices[t], indices[t + 1], indices[t + 2]
            fh.write("f %d/%d/%d %d/%d/%d %d/%d/%d\n" % (
                a + 1, a + 1, a + 1, b + 1, b + 1, b + 1, c + 1, c + 1, c + 1))


def render(path, positions, normals, indices, size=384):
    """Flat-shaded z-buffered preview, front view along -z, scaled to fit."""
    import numpy as np
    p = np.array(positions, np.float64)
    n = np.array(normals, np.float64)
    tri = np.array(indices, np.int32)[:len(indices) // 3 * 3].reshape(-1, 3)
    if len(tri) == 0:
        return
    centre = (p.max(axis=0) + p.min(axis=0)) / 2.0
    extent = float((p.max(axis=0) - p.min(axis=0)).max()) or 1.0
    p = (p - centre) / extent * 1.7
    # y up, x right, looking down -z: screen x = px, screen y = py.
    sx = (p[:, 0] * 0.5 + 0.5) * (size - 1)
    sy = (0.5 - p[:, 1] * 0.5) * (size - 1)
    depth = p[:, 2]
    image = np.full((size, size, 3), 24, np.uint8)
    zbuf = np.full((size, size), -1e9)
    light = np.array([0.3, 0.6, -0.75])
    light = light / np.linalg.norm(light)
    for a, b, c in tri:
        x0, y0, x1, y1, x2, y2 = sx[a], sy[a], sx[b], sy[b], sx[c], sy[c]
        area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
        if abs(area) < 1e-9:
            continue
        xmin = max(int(min(x0, x1, x2)), 0); xmax = min(int(max(x0, x1, x2)) + 1, size - 1)
        ymin = max(int(min(y0, y1, y2)), 0); ymax = min(int(max(y0, y1, y2)) + 1, size - 1)
        if xmin > xmax or ymin > ymax:
            continue
        xn = np.arange(xmin, xmax + 1)
        yn = np.arange(ymin, ymax + 1)
        gx, gy = np.meshgrid(xn, yn)
        w0 = ((x1 - gx) * (y2 - gy) - (x2 - gx) * (y1 - gy)) / area
        w1 = ((x2 - gx) * (y0 - gy) - (x0 - gx) * (y2 - gy)) / area
        w2 = 1.0 - w0 - w1
        inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        if not inside.any():
            continue
        z = w0 * depth[a] + w1 * depth[b] + w2 * depth[c]
        window = zbuf[ymin:ymax + 1, xmin:xmax + 1]
        closer = inside & (z > window)
        if not closer.any():
            continue
        window[closer] = z[closer]
        normal = n[a] + n[b] + n[c]
        length = np.linalg.norm(normal) or 1.0
        shade = 0.22 + 0.78 * max(0.0, float(np.dot(normal / length, light)))
        tint = np.array([0.42, 0.78, 0.35]) if False else np.array([0.55, 0.83, 0.45])
        px = image[ymin:ymax + 1, xmin:xmax + 1]
        px[closer] = (np.clip(tint * shade, 0, 1) * 255).astype(np.uint8)
    write_png(path, image)


def write_png(path, rgb):
    import zlib
    height, width = rgb.shape[:2]
    raw = b"".join(b"\x00" + rgb[row].tobytes() for row in range(height))
    def chunk(tag, body):
        return (struct.pack(">I", len(body)) + tag + body
                + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF))
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n"
                           + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 9))
                           + chunk(b"IEND", b""))


def main(argv):
    if len(argv) == 3 and argv[1] == "--render":
        positions, normals, uvs, indices, _ = read(argv[0])
        render(argv[2], positions, normals, indices)
        print("%s -> %s" % (argv[0], argv[2]))
        return 0
    if len(argv) == 2 and argv[1] == "--stats":
        positions, normals, uvs, indices, hdr = read(argv[0])
        tris = len(indices) // 3
        print("%s  v=%d  tris=%d (header says %d)  stride=%d" % (
            os.path.basename(argv[0]), hdr[4], tris, hdr[1], hdr[3]))
        for axis, name in enumerate("xyz"):
            values = [p[axis] for p in positions]
            print("  %s %7.3f .. %7.3f" % (name, min(values), max(values)))
        return 0
    if len(argv) == 3 and argv[0] != "--all":
        positions, normals, uvs, indices, _ = read(argv[0])
        write_obj(argv[1], positions, normals, uvs, indices)
        print("%s -> %s  (%d vertices, %d triangles)" % (
            argv[0], argv[1], len(positions), len(indices) // 3))
        return 0
    if len(argv) == 3 and argv[0] == "--all":
        source, outdir = argv[1], argv[2]
        os.makedirs(outdir, exist_ok=True)
        done = failed = 0
        for base, _, files in os.walk(source):
            for name in sorted(files):
                if not name.lower().endswith(".xm"):
                    continue
                path = os.path.join(base, name)
                try:
                    positions, normals, uvs, indices, _ = read(path)
                except ValueError as error:
                    failed += 1
                    print("  %-40s %s" % (name, error))
                    continue
                write_obj(os.path.join(outdir, name[:-3] + ".obj"),
                          positions, normals, uvs, indices)
                done += 1
        print("decoded %d meshes to %s, %d failed" % (done, outdir, failed))
        return 0
    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
