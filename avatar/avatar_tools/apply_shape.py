#!/usr/bin/env python3
"""Apply a decoded block-4 shape to a mesh, and optionally render it.

decode_shape.py proves the format: an entry is a vertex and that vertex's new
position. This tool does something with it - it moves the vertices - so the shape
can be checked against the thing the editor shows rather than against itself.

    python3 apply_shape.py "Large Chin"                  # report the displacement
    python3 apply_shape.py "Large Chin" --obj out.obj    # also write the mesh
    python3 apply_shape.py "Large Chin" --png out.png    # also render a front view
    python3 apply_shape.py "Large Chin" --base-png base.png

`--base-png` renders the same mesh without the shape, so the two images can be
compared and a shape that does nothing is obvious.

The mesh is the asset the shape targets - Head for facial shapes - and the vertex
in each entry is `offset // 52`, the vertex stride.
"""
import argparse
import math
import sys

import numpy as np

import avatar_mesh as am
import decode_shape


def load_mesh(pack, index, name):
    """Vertices and triangles of an asset's geometry, concatenated over batches."""
    asset = am.asset_bytes(pack, index, name)
    blocks = [b for b in am.strb_blocks(asset) if b[0] == 3]
    if not blocks:
        raise SystemExit("%s has no geometry block" % name)
    verts, tris, base = [], [], 0
    for batch in am.read_model(am.decompress(blocks[0][3])):
        v = np.asarray(batch["vertices"], dtype=np.float64)
        t = np.asarray(batch["indices"], dtype=np.int64).reshape(-1, 3) + base
        verts.append(v)
        tris.append(t)
        base += len(v)
    return np.vstack(verts), np.vstack(tris)


def apply_shape(verts, entries, stride=decode_shape.VERTEX_STRIDE):
    """Move each entry's vertex to the position the shape gives it."""
    moved = verts.copy()
    applied = skipped = 0
    worst = 0.0
    for e in entries:
        if e["vertex"] is None or e["vertex"] >= len(verts):
            skipped += 1
            continue
        old = moved[e["vertex"]].copy()
        new = np.asarray(e["xyz"], dtype=np.float64)
        worst = max(worst, float(np.linalg.norm(new - old)))
        moved[e["vertex"]] = new
        applied += 1
    return moved, {"applied": applied, "skipped": skipped, "worst": worst}


def render_png(verts, tris, path, yaw=0.0, width=384, height=512):
    """Front view, using the same renderer the bake tools use."""
    import bake_turntable as bt

    nv = verts - verts.mean(axis=0)
    span = max(float(np.ptp(nv[:, 0])), float(np.ptp(nv[:, 1]))) or 1.0
    nv = nv / span
    nv[:, 1] += 0.5          # feet at 0, head at 1
    vn = bt.vertex_normals(nv, tris)
    colours = np.tile(np.array([0.72, 0.68, 0.62]), (len(tris), 1))
    frame = bt.render(nv, tris, colours, vn, yaw, width, height)
    bt.write_png(path, frame)
    return path


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("shape")
    ap.add_argument("--mesh", default="Head")
    ap.add_argument("--pack", default=decode_shape.PACK)
    ap.add_argument("--obj")
    ap.add_argument("--png")
    ap.add_argument("--base-png")
    ap.add_argument("--yaw", type=float, default=0.0)
    args = ap.parse_args(argv)

    index = am.load_pack_index(args.pack)
    verts, tris = load_mesh(args.pack, index, args.mesh)
    r = decode_shape.decode(args.shape, args.pack, 0)
    entries = r["section_b"]["entries"]
    moved, stats = apply_shape(verts, entries)

    print("%s on %s: %d vertices, %d triangles" % (args.shape, args.mesh,
                                                   len(verts), len(tris)))
    print("  entries %d, applied %d, skipped %d, largest move %.4f m"
          % (len(entries), stats["applied"], stats["skipped"], stats["worst"]))
    if stats["applied"]:
        d = np.linalg.norm(moved - verts, axis=1)
        moving = d > 1e-6
        print("  moved %d vertices, mean move %.5f m, max %.5f m"
              % (moving.sum(), d[moving].mean() if moving.any() else 0.0, d.max()))
        before, after = verts[moving], moved[moving]
        print("  affected region before: x %.3f..%.3f y %.3f..%.3f z %.3f..%.3f"
              % (before[:, 0].min(), before[:, 0].max(), before[:, 1].min(),
                 before[:, 1].max(), before[:, 2].min(), before[:, 2].max()))
        print("  affected region after : x %.3f..%.3f y %.3f..%.3f z %.3f..%.3f"
              % (after[:, 0].min(), after[:, 0].max(), after[:, 1].min(),
                 after[:, 1].max(), after[:, 2].min(), after[:, 2].max()))

    if args.obj:
        with open(args.obj, "w") as fh:
            for v in moved:
                fh.write("v %.6f %.6f %.6f\n" % (v[0], v[1], v[2]))
            for t in tris:
                fh.write("f %d %d %d\n" % (t[0] + 1, t[1] + 1, t[2] + 1))
        print("  wrote %s" % args.obj)

    if args.base_png:
        print("  wrote %s" % render_png(verts, tris, args.base_png, args.yaw))
    if args.png:
        print("  wrote %s" % render_png(moved, tris, args.png, args.yaw))
    return 0


if __name__ == "__main__":
    sys.exit(main())
