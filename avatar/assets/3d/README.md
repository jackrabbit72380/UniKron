# 3D frames

`AvatarStage3D` plays `turntable/frame_00.png` … `frame_23.png` in yaw order.
These are baked from the real mesh: the theme cannot decode geometry itself, so
the frames are the delivery format.

The set shipped here is a stock avatar — `MaleBody`, `Head`, "Left Parting" hair,
"Male Power Tee", "Worn Jeans" and "Formal Shoes" — posed with frame 0 of
`IdleOffScreen.AvatarAnimation` (standing, arms down) and baked at 512×768 RGBA
with a transparent background, which is what the stage and the portrait capture
expect.

## Rebaking

    cd avatar_tools
    A=../../../src_archive/XBOX HUB/resources/editors/nxe2008/assets
    python3 bake_avatar.py "$A/AvatarAssetPack.toc" \
        "$A/IdleOffScreen.AvatarAnimation" 0 /tmp/avatar.obj \
        MaleBody Head "Left Parting" "Male Power Tee" "Worn Jeans" "Formal Shoes"
    python3 bake_turntable.py /tmp/avatar.obj ../assets/3d/turntable --frames 24

`bake_avatar.py` skins every asset through the same 71-joint rig and concatenates
them, so body, head, hair and clothes hold one pose.

A facial shape can be applied on the way through, from the decoded block 4 rather
than a hand-made morph:

    python3 bake_avatar.py --shape="Large Chin" "$A/AvatarAssetPack.toc" \
        "$A/IdleOffScreen.AvatarAnimation" 0 /tmp/chin.obj \
        MaleBody Head "Left Parting" "Male Power Tee" "Worn Jeans" "Formal Shoes"

The shape moves the head in bind pose, before the rig poses it, so the skinning
carries the new geometry into the animation.

A whole avatar can also be posed from one of the avatar games' clips, which is the
only shipped data that carries a resting hand:

    python3 bake_avatar.py --xnb=/tmp/av/Idle.xnb:0 "$A/AvatarAssetPack.toc" \
        "$A/IdleOffScreen.AvatarAnimation" 0 /tmp/idle.obj \
        MaleBody Head "Left Parting" "Male Power Tee" "Worn Jeans" "Formal Shoes"

`--xnb=PATH[:FRAME]` reads the clip with `xnb_avatar.py` and overrides the pack
clip's pose. XNA stores those matrices for row vectors, so they are transposed
(the conjugate quaternion) on the way in; without that the idle stands with its
arms overhead. On the stock outfit Large Chin moves
110 of the assembled 3975 vertices by a mean of 14 mm (max 43 mm), all of them
inside the Head block. Pass any pack asset names
from `avatar-assets.json` to change the outfit; `bake_turntable.py` fits the
framing automatically.

Keep the count at 24 and the size at 512×768 so the spin and the portrait grab
stay in step with `AvatarStage3D`.


## One set per hairstyle

The 3D figure follows the hairstyle picked in the closet. `bake_outfits.py`
bakes one set per file in `assets/50_hair` and names the folder after that file:

    python3 bake_outfits.py "$A/AvatarAssetPack.toc" "$A/IdleOffScreen.AvatarAnimation" \
        "$A/Avatar6400.Avatar" ../assets/3d/turntable

`outfits.json` beside the script maps each art file to its pack hairstyle and
colour - `hair_short_brown` is "Left Parting" brown, `hair_long_blond` is "Long
Flick" blond, `hair_bun_red` is "Bun" red, `hair_spiky_black` is "Spiky on Top"
black. `AvatarStage3D` plays `turntable/<variant>/` when a hairstyle is picked
and falls back to the default set in `turntable/` when that folder has no
frames, so a theme with only the default set still works.

Sets are 20 frames at 448x672 (about 0.9 MB each) instead of 24 at 512x768: that
is what keeps four hairstyles affordable next to the 2D art. Clothes are the same
in every set - a stock garment stores no colour this pipeline can read, so baking
per garment would only multiply identical-looking figures.

## What the frames do and do not show

The face is painted too: `--face` samples the pack's eyebrow, eye and mouth
masks on the head's UV sets 2, 3 and 4 and gives each triangle that feature's
description colour, so the figure has brows, eyes and a mouth instead of a blank
head. It is per triangle on an 846-triangle head, so the shapes are as coarse as
the mesh is - a faithful silhouette of the mask, not the texture's detail.

Skin and hair come from the avatar's own description: `bake_avatar.py
--colours=...Avatar` reads the nine ARGB colours at 0xFC and paints the body,
head and hair with the real skin and hair tones. Clothes are a neutral grey on
purpose - a stock item's colour is not stored in its asset (models embed no
textures, see EDITOR_BINARIES.md) and this outfit has no custom colours, so
inventing one would be a guess. The pack does carry a per-item colour table in
block id 7, still to be pinned down.

## How the mesh is decoded

`avatar_tools/avatar_mesh.py` reads the STRB container, LZX-expands each model
block (each chunk is its own LZX stream), and decodes the quantised lattice as
`min + q * step * k` with `k = (2, 2/√1.5, √3)` and **`q` unsigned** — the
unsigned read is what makes the meshes solid instead of sheared into sheets; see
`avatar_tools/EDITOR_BINARIES.md`. `MaleBody` lands on x ±0.711,
y 0.005..1.167, z −0.103..0.149, which is the reference's own figure for it.

The 2008 and 2010 packs are byte-identical for `MaleBody`, `FemaleBody` and
`Head`, so either editor's pack produces the same mesh.

## Pack-mode turntables: measured coverage (2026-11-19)

`avatar_tools/bake_pack_turntables.py` writes one set per item the pack marks for a
gender, named by the item's slug. Both packs were re-measured after the last full
rebake rather than counted from a run log:

```
turntable/         466 dirs   462 expected from the pack   4 dirs with a second slug
turntable_female/  470 dirs   470 expected                  0
frames on disk     5,710      0 under 1 KB, 0 zero-length
frames per set     932 x 6, 1 x 18, 3 x 20
```

The four male extras are the hand-drawn sets `hair_bun_red` (18 frames),
`hair_long_blond`, `hair_short_brown` and `hair_spiky_black` (20 frames each) -
they are not pack slugs at all, and they are the only sets in either directory that
are not 6 frames. To re-measure, list the expected slugs the way the baker selects
them (category, gender tag, mesh or decal, `BASE_ASSETS` and the nose exclusion)
and diff that set against `os.listdir()` of each output directory; every expected
slug had `frame_00.png`.

An earlier note in this folder put the remaining work at 1,243 sets in total with
426 still on the old hand pose. That was a count of run-log arithmetic, not of the
pack: the selector yields 932 sets, all of them were rebaked with the current pose,
and 1,243 was never a set count for either gender.
