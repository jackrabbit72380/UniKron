"""Which head UV set does a face decal texture belong to?

For each of the head's six UV sets, rasterise the head's triangles in that set's
UV space and ask how much of the decal's non-transparent art lands inside the
covered region. The set that covers the art is the decal's mapping.
"""

import os
import sys

import numpy as np

import avatar_mesh as am

HERE = os.path.dirname(os.path.abspath(__file__))
PACK = os.path.join(HERE, "../../../src_archive/XBOX HUB/resources/editors/"
                    "metro2010/assets/AvatarAssetPack.toc")


def load_head():
    index = am.load_pack_index(PACK)
    blob = am.asset_bytes(PACK, index, "Head")
    blocks = am.strb_blocks(blob)
    model = [b for b in blocks if b[0] == 3][0]
    return am.read_model(am.decompress(model[3]))


def read_rgba(path):
    from PIL import Image
    return np.asarray(Image.open(path).convert("RGBA"), dtype=np.float32) / 255.0


def coverage(uvs, indices, width, height, flip_v=True):
    """Boolean grid of texels touched by the head's triangles in this UV set."""
    grid = np.zeros((height, width), dtype=bool)
    for k in range(0, len(indices) - 2, 3):
        tri = indices[k:k + 3]
        pts = []
        for corner in tri:
            uv = uvs[corner]
            if len(uv) < 2:
                pts = []
                break
            u, v = uv[0], uv[1]
            if not (0.0 <= u <= 1.0 and 0.0 <= v <= 1.0):
                # A triangle straddling the seam is skipped rather than wrapped.
                pts = []
                break
            if flip_v:
                v = 1.0 - v
            pts.append((u, v))
        if len(pts) != 3:
            continue
        xs = [p[0] * (width - 1) for p in pts]
        ys = [p[1] * (height - 1) for p in pts]
        x0, x1 = int(min(xs)), int(np.ceil(max(xs))) + 1
        y0, y1 = int(min(ys)), int(np.ceil(max(ys))) + 1
        if x1 <= x0 or y1 <= y0:
            continue
        yy, xx = np.mgrid[y0:min(y1, height), x0:min(x1, width)]
        if yy.size == 0:
            continue
        px, py = xx.ravel().astype(np.float32), yy.ravel().astype(np.float32)
        # Barycentric test against the triangle in pixel space.
        ax, ay = xs[0], ys[0]
        bx, by = xs[1], ys[1]
        cx, cy = xs[2], ys[2]
        det = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(det) < 1e-6:
            continue
        w0 = ((by - cy) * (px - cx) + (cx - bx) * (py - cy)) / det
        w1 = ((cy - ay) * (px - cx) + (ax - cx) * (py - cy)) / det
        w2 = 1.0 - w0 - w1
        inside = (w0 >= -0.02) & (w1 >= -0.02) & (w2 >= -0.02)
        grid[yy.ravel()[inside], xx.ravel()[inside]] = True
    return grid


def main():
    decals = sys.argv[1:]
    batches = load_head()
    uvs, indices = batches[0]["uvs"], batches[0]["indices"]
    print("head UV sets:", len(uvs[0]), "verts", len(uvs), "tris", len(indices) // 3)
    sets = {}
    for name in decals:
        rgba = read_rgba(name)
        h, w = rgba.shape[:2]
        art = rgba[:, :, 3] > 0.5
        print("\n%s  %dx%d art texels %d" % (os.path.basename(name), w, h, art.sum()))
        for si in range(len(uvs[0])):
            per_vert = [v[si] if si < len(v) else () for v in uvs]
            grid = coverage(per_vert, indices, w, h)
            hit = art & grid
            print("  set %d covers %5.1f%% of the art, %4.1f%% of the sheet"
                  % (si, 100.0 * hit.sum() / max(art.sum(), 1),
                     100.0 * grid.sum() / (w * h)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
