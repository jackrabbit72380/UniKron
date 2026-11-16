"""Apply a decal texture on each of the head's UV sets and render the head.

The point is to identify, by eye, which UV set a facal-hair or face-paint sheet
belongs to. Set 2/3/4 are the brow, eye and mouth tint masks; the remaining sets
are candidates for the painted decals, and guessing one would be inventing data.

    python3 probe_decal_render.py ../pack_art/45_facial-hair/beard.png /tmp/head.png
"""

import os
import subprocess
import sys

import numpy as np

import avatar_mesh as am
import bake_turntable as bt

HERE = os.path.dirname(os.path.abspath(__file__))
PACK = os.path.join(HERE, "../../../src_archive/XBOX HUB/resources/editors/"
                    "metro2010/assets/AvatarAssetPack.toc")
CLIP = os.path.join(HERE, "../../../src_archive/XBOX HUB/resources/editors/"
                    "metro2010/assets/Cheer.AvatarAnimation")
DESC = os.path.join(HERE, "descriptors/Avatar6400.Avatar")
OBJ = "/tmp/probe_head.obj"


def head_obj():
    subprocess.run(
        [sys.executable, os.path.join(HERE, "bake_avatar.py"), PACK, CLIP, "0", OBJ,
         "--colours=" + DESC, "--hair=6e5326", "--face", "Head"],
        check=True, capture_output=True, text=True)
    return OBJ


def main():
    decal, out_path = sys.argv[1], sys.argv[2]
    decal_rgba = bt.read_png(decal) if hasattr(bt, "read_png") else None
    if decal_rgba is None:
        from PIL import Image
        decal_rgba = np.asarray(Image.open(decal).convert("RGBA"), dtype=np.float64) / 255.0
    if decal_rgba.dtype != np.float64:
        decal_rgba = decal_rgba.astype(np.float64)

    obj = head_obj()
    verts, tris, colours = bt.read_obj(obj)
    face = bt.load_face(obj)
    if face is None:
        raise SystemExit("bake_avatar wrote no face data")
    verts_n = bt.normalise(verts)
    vnormals = bt.vertex_normals(verts_n, tris)

    uvsets = face.get("uvsets")
    if uvsets is None:
        raise SystemExit("bake_avatar wrote no UV sets; rerun it after the update")
    sets = uvsets.shape[2]

    # The head alone, so a set that paints the whole skull is obvious.
    verts = verts_n
    tiles = [("plain", bt.render(verts, tris, colours, vnormals, 3.14159, 200, 200))]
    for si in range(sets):
        shaped = dict(face)
        # Only the decal: leaving the eye and mouth masks on buried it in tint.
        shaped["layers"] = []
        shaped["decals"] = [{"uvs": uvsets[:, :, si, :], "texture": decal_rgba}]
        tiles.append(("set %d" % si,
                      bt.render(verts, tris, colours, vnormals, 3.14159, 200, 200,
                                face=shaped)))

    width = 200 * len(tiles)
    sheet = np.zeros((200, width, 4), dtype=np.uint8)
    sheet[..., :3] = 32
    sheet[..., 3] = 255
    for i, (label, rgba) in enumerate(tiles):
        sub = sheet[:, i * 200:(i + 1) * 200]
        mask = rgba[..., 3] > 0
        sub[mask] = rgba[mask]
    bt.write_png(out_path, sheet)
    print("%s: %s" % (", ".join(t[0] for t in tiles), out_path))
    return 0


if __name__ == "__main__":
    sys.exit(main())
