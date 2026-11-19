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
turntable/           564 dirs   466 pack items + 98 decal sets, + 20 stock frames
turntable_female/    568 dirs   470 pack items + 98 decal sets, + 20 stock frames
frames in the trees  6,886      0 under 1 KB, 0 zero-length
frames per set       1,128 x 6, 1 x 18, 3 x 20
```

The 98 decal sets per tree are the brows, eye shadows and mouths covered in the
next section. Four sets in `turntable/` are not pack slugs at all - the hand-drawn
`hair_bun_red` (18 frames), `hair_long_blond`, `hair_short_brown` and
`hair_spiky_black` (20 frames each) - and they are the only sets in either tree
that are not 6 frames. To re-measure, list the expected slugs the way the baker
selects them (category, gender tag, mesh or decal, `BASE_ASSETS` and the nose
exclusion) and diff that set against `os.listdir()` of each output directory;
every expected slug had `frame_00.png`.

An earlier note in this folder put the remaining work at 1,243 sets in total with
426 still on the old hand pose. That was a count of run-log arithmetic, not of the
pack: the selector yields 932 sets, all of them were rebaked with the current pose,
and 1,243 was never a set count for either gender.

## StageIndex.qml: the stage no longer counts frames (2026-11-19)

`avatar_tools/make_stage_index.py` measures every baked set and writes
`avatar/StageIndex.qml`, one entry per set with its frame count and the frame that
faces the camera. Measured from the tree:

```
sets                1,179      564 turntable/<stem> + 568 turntable_female/<stem>
                               + 40 drawn shirts/pants/shoes + 2 stock roots
                               (turntable, turntable_female) + 5 at assets/3d
                               (its own 20-frame set and four hair sets)
frames              7,466
sets by frame count 1,128 x 6      item bakes (bake_pack_turntables.bake_one)
                    40 x 12        the drawn per-item sets (bake_turntable via bake_items)
                    1 x 18         turntable/hair_bun_red
                    10 x 20        whole-body turntables and the stock sets
animated            12 yaws x 10 poses, 120 frames, set.json names its variant
```

**Why.** The stage used to request `frame_00.png`, `frame_01.png`, ... until one
failed to load. That cost one failed load per set switch, and - the part that was
visible - the count was only known after the last probe came back, so for the first
frames of every switch the stage still showed frame 0. For a whole-body turntable
frame 0 is the avatar's **back**, so switching items flashed the back of the
avatar's head before the front frame came up.

**Where `front` comes from.** Not from a guess about frame counts: each set was
written by one of two bakers, and each one's first frame is fixed by its own render
loop.

| baker | yaw of frame *i* | front frame |
| --- | --- | --- |
| `bake_pack_turntables.bake_one` | `pi + 2*pi*i/frames` | 0 (a half turn) |
| `bake_turntable.main` | `radians(start) + 2*pi*i/frames`, start 0 | `frames/2` (the back first) |

Six-frame sets are the item bakes (`rebake_stale.py` also calls `bake_one` with
frames=6); longer sets are whole-body turntables. The three sets read frame by
frame - `turntable/jacket-with-sweater` 6/0, `turntable/hair_long_blond` 20/10,
`turntable/hair_bun_red` 18/9 - are checked before the script writes anything, so
if the rule ever stops matching them the index is not written. `--check` reports
whether the file on disk still matches the tree; `bake_pack_turntables.py`,
`rebake_stale.py` and `bake_animated.py` refresh it at the end of a run, so a bake
and its index do not drift apart.

**Measured effect.** `research/rail_check.py` counts the failed loads the editor
produces across a full check cycle (both genders, a mode switch, four item
switches): **43 before, 1 after**. The one left is the stage probing
`turntable/skinny-fit-jeans/frame_00.png`, an item the pack marks wearable but
which has no bake - the stage cannot tell "never baked" from "baked after the
index was written" without asking.

## The animated set was baked but never played

`bake_animated.py` pictures the stock look: `MaleBody`, `Head`, `Left Parting`,
`Jacket with Sweater`, `Male Flower Print Flares`, `Grunge Trainers` - the same
outfit `Avatar6400.Avatar` wears and the same one the pack seeds a new avatar
with. That look resolves to the set folder `turntable/jacket-with-sweater`.

The stage only played the animated frames when the variant equaled
`turntable/<default hairstyle>`, and the stock outfit's own set always outranks the
hairstyle set, so the condition never held in pack mode: 120 baked frames that
nothing showed. `assets/3d/animated/set.json` now records which set folder the bake
is a picture of (`"variant": "turntable/jacket-with-sweater"`), `StageIndex.qml`
carries it, and `AvatarStage3D` plays the animated frames while the worn look is
that one - and only then.

Measured after the change: `animated=true yaw=6/12 pose=4/10
variant=turntable/jacket-with-sweater indexed=true`. `set.json` is written by the
baker (`--metadata-only=1` rewrites just that file, so the 120 existing frames did
not need re-rendering).

## Brows, eye shadows and mouths: the 196 items with no 3D set (2026-11-19)

`research/run_art_sweep.py` drives every item the strip offers through the real
editor - both bodies, both drawers, 1,380 item checks - and asks two questions per
check: does every layer the 2D stage resolves exist on disk, and does the 3D stage
have a set for the pick's *own* variant (before its fallback)? The 2D answer was
clean from the first run. The 3D answer was not: 196 pack items had no set at all -
all 27 eyebrows, all 45 eye shadows and all 26 mouths, for each body - so picking
one in 3D fell back to the stock turntable and the change was invisible.

Both causes were bugs in the baker, not missing data:

* **The eye-shadow sheets were looked up in the wrong folder.** `bake_one` built
  the sheet path as `pack_art/50_hair/<slug>.png`, which is where the sheets lived
  before `asset_catalog.refine_category` split them into `17_eye-shadow`. Every set
  in the pass failed with `no decal sheet for Eye shadow 001` - 45 of them, three
  times over. The lookup now tries the item's own category folder first and
  `50_hair` second.
* **`--gender` did not choose the output tree.** `--outdir` defaulted to
  `turntable/` for both bodies, so the female runs wrote into the male tree: 98
  male sets were replaced with female-body renders. The default now follows
  `--gender` (`turntable_female/` for female), and the 98 polluted folders were
  deleted and rebaked rather than left in place.

Measured after the rebake: 27/27 brows, 45/45 eye shadows, 26/26 mouths in both
trees; `StageIndex.qml` 1,179 sets / 7,466 frames; the sweep reports **0 missing
art** and 0 pack items without a set. The frames were also looked at: a brow set
flattens the brow line, a mouth set paints the lips, an eye-shadow set darkens the
lids, and `turntable_female/eye-shadow-012` renders the female body with the female
stock hairstyle, so the two trees are not the same pictures.

What the sweep still reports is the port's own fallback art, not retail content: 72
drawn items (8 body plates, 1 drawn pair of jeans, 35 drawn hairstyles, 16 drawn
hats, 12 drawn glasses) have no set of their own, so in 3D those picks show the
stock turntable.

## Every baked set, checked pixel by pixel (2026-11-19)

`research/run_3d_sanity.py` asks a different question from the art sweep: not
whether an item has a set, but whether the frames inside it are usable. Per set it
reads the frames (every frame under eight, a stride of the 20-frame body turns),
downscales them and measures alpha coverage, frame-to-frame difference, the
declared front frame and frame sizes.

```
checked 1,179 set(s), 7,135 frame(s)
short 0   blank 0   full 0   static 0   front 0   shape 0
```

So none of the 1,179 sets has a missing frame file, a frame that rendered nothing
(coverage under 0.5 %), a frame with no transparent margin (over 98 %), a set whose
yaw loop never moved, a front index outside the set, or frames of two sizes. The
check was run against a deliberately broken copy as well (a blank frame and a
repeated one) and both were reported, so a pass means something.

## The turn rate did not depend on the set (fixed 2026-11-19)

Both bakers sweep exactly one revolution: `bake_pack_turntables.py` steps
`yaw = pi + 2*pi*i/frames` and `bake_turntable.py` the same. So a six-frame item
set is 60 degrees per frame and the 20-frame body turntable 18 - and the stage
advanced one frame per fixed 90 ms tick, which spun the item sets 3.3 times faster
than the whole-body turn. That covers 1,128 of the 1,179 sets: everything the
closet shows. The animated set had a third rate of its own (130 ms per yaw).

`AvatarStage3D` now derives the interval from the set: one turn every 1,800 ms,
which is the rate the 20-frame turntable already ran at (90 ms x 20), so the
shorter sets get longer frames instead. `research/run_spin_check.py` loads both a
six-frame and a 20-frame set, turns them and counts:

| set | frames | turn |
| --- | ---: | ---: |
| `turntable/50-s-glasses` | 6 | **1.80 s** |
| `hair_bun_red` | 20 | **1.78 s** |
| same check, old fixed 90 ms | | |
| `turntable/50-s-glasses` | 6 | 0.53 s |
| `hair_bun_red` | 20 | 1.78 s |

Note that nothing in the editor sets `spinning` - the closet turntable turns only
while dragged, and a drag is already frame-count independent (it maps a drag across
the stage width to one full turn). The timer is the path a host turns on, and
`research/harness-shadow.qml` does.
