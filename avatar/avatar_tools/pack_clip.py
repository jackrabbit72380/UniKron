"""Get an animation clip out of the pack, as a file bake_avatar can read.

`Cheer.AvatarAnimation` ships as a file beside the pack, which is why the bakes
were posed with it. But it is a *cheerleading* clip: frame 0 has the arms out with
the fingers fanned, which is what made every baked avatar stand there with
splayed hands. The pack ships its own standing idles, and they are the right pose
for a wardrobe preview:

    Animation Male Idle Shifts Weight      242 frames
    Animation Female Idle Shifts Weight
    Animation Male Idle Looks Around

A pack animation is a STRB container with a block 1 payload, exactly the shape
bake_avatar reads from a clip file, so extracting the asset's bytes to disk is all
that is needed.

    python3 pack_clip.py PACK "Animation Male Idle Shifts Weight" OUT
"""

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MALE_IDLE = "Animation Male Idle Shifts Weight"
FEMALE_IDLE = "Animation Female Idle Shifts Weight"


def extract(pack, name, out_path):
    """Write the named animation asset out as a clip file, and return the path."""
    sys.path.insert(0, HERE)
    import avatar_mesh as am
    index = am.load_pack_index(pack)
    data = am.asset_bytes(pack, index, name)
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "wb") as fh:
        fh.write(data)
    return out_path


def resolve(pack, clip_path, asset_name, workdir):
    """The clip a bake should use: the named pack asset if one is given."""
    if asset_name:
        return extract(pack, asset_name, os.path.join(workdir, "clip.animation"))
    return clip_path


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 1
    print(extract(sys.argv[1], sys.argv[2], sys.argv[3]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
