# The pack's own item catalogue

`asset_catalog.py` decodes all 1,079 assets and `pack_items.json` regroups them by
the slot each item occupies. Everything here comes from the pack: names from the
toc's per-locale string pointers, geometry from the `Model` block, and gender,
asset class and slots from the `AssetMetadataVersioned` block. Nothing is typed
in by hand except the *names of the slot bits*, which are read off the items that
carry them.

## AssetMetadataVersioned (STRB block 8), 15 bytes

| offset | size | meaning |
| --- | --- | --- |
| +0 | u8 | version, always 2 |
| +1 | u8 | gender: 1 male, 2 female, 3 both |
| +2 | u8 | class: 1 Model, 2 Texture, 3 ShapeOverrides, 4 Animation |
| +3 | u8 | zero |
| +4 | u32 | slot mask |
| +8 | 7 B | version trailer, always `00000000000002` |

The gender byte is confirmed rather than guessed: all 127 assets whose name starts
with `Female` read 2, and all 111 starting with `Male` read 1.

## Slot bits

| bit | slot | example item |
| --- | --- | --- |
| 0x0001 | glasses | `Metallic Carbon Shades` |
| 0x0002 | wristwear | `Slick Watch` |
| 0x0004 | earrings | `Male Gold Stud Earrings` |
| 0x0008 | rings | `Silver Ring` |
| 0x0100 | head | `Happy Eyes` |
| 0x0200 | body | `MaleBody` |
| 0x0400 | hair | `Bald`, `Fauxhawk` |
| 0x0800 | torso | `Male Power Tee` |
| 0x1000 | legs | `Chinos`, `Jeans` |
| 0x2000 | feet | `Moccasins`, `Flip Flops` |
| 0x4000 | hat | `Male Baseball Cap`, `Vintage Trilby` |
| 0x8000 | gloves | `Woolly Gloves` |

Multi-bit masks are real items that fill two slots: 0x1800 is a dress (legs +
torso), 0x1802 a formal outfit, 0x3802 a long coat, 0x0300 facial hair (head +
hair), 0x0500 face paint. The theme's existing folders line up with these bits
one for one, which is why the categories below reuse their names.

## Items per category

| category | items | male | female | both |
| --- | --- | --- | --- | --- |
| `10_body` | 38 | 1 | 1 | 36 |
| `15_face` | 64 | 0 | 0 | 64 |
| `16_face-paint` | 26 | 0 | 0 | 26 |
| `20_pants` | 54 | 27 | 27 | 0 |
| `30_shoes` | 36 | 18 | 18 | 0 |
| `40_shirt` | 137 | 71 | 66 | 0 |
| `45_facial-hair` | 17 | 17 | 0 | 0 |
| `46_gloves` | 16 | 8 | 8 | 0 |
| `50_hair` | 223 | 0 | 0 | 223 |
| `60_hat` | 34 | 17 | 17 | 0 |
| `70_glasses` | 34 | 17 | 17 | 0 |
| `75_earrings` | 34 | 15 | 19 | 0 |
| `76_rings` | 16 | 8 | 8 | 0 |
| `77_wristwear` | 16 | 8 | 8 | 0 |
| `80_dress` | 15 | 0 | 15 | 0 |
| `81_formal` | 7 | 5 | 2 | 0 |
| `82_coat` | 4 | 4 | 0 | 0 |
| `83_dress-formal` | 1 | 0 | 1 | 0 |

The other 307 assets have a zero slot mask: they are the 41 named animations plus
hiding templates and other non-wearable records.

## Thumbnails are renders, not restored art

Because there is no texture art to extract, `bake_pack_thumbs.py` renders one
thumbnail per item straight from that item's own mesh, using the same flat-shaded
painter the 3D stage uses. Output is `avatar/pack_art/<category>/<slug>.png`
(**583 items**, 16 categories) plus `avatar/PackIndex.qml`, which lists them in
the same shape as `AssetIndex.qml`. They live outside `assets/` so the hand-drawn
index is untouched.

The editor browses them when its `usePackArt` property is true; the category list
then comes from `PackIndex.qml` and each row points at `pack_art/`, so the
hand-drawn `assets/` tree stays the default. The 3D wardrobe is keyed on the
drawn art's file names, so it is the drawn mode that keeps 3D in step.

Items with no Model block carry a `Texture` block instead, and `bake_pack_tex.py`
extracts those as PNGs (`DXT5`, linear - see `TEXTURES.md`), so they are not
missing either. `pack_art/` now holds **743 images**: 583 mesh renders plus 160
textures, covering 18 categories. `16_face-paint` (26) and `45_facial-hair` (17)
are art-only and get their pictures from the textures; 27 texture-bearing assets
have no slot category in their metadata, so they are extracted but not filed.

## What the pack does not carry

- **No texture pixels.** All 585 decoded models report empty texture slots, so
  there is no retail thumbnail or garment art to be had from this file.
- **Almost no colours.** 402 of the 405 `CustomColorTable` blocks hold only
  black/clear placeholders; the three that do not are `Male Power Tee`,
  `Female Power Tee` and `Tight Tee` (see `COLOURS.md`).

So the pack gives real names, real geometry, real categories, real genders and
real slot assignment - but the editor's 2D item art and per-item colours cannot
be recovered from it.

## Which items have a 3D set

`bake_pack_turntables.py` writes `assets/3d/turntable/<slug>/`, six frames each,
opens facing the player, stock avatar wearing that one item. Audited against this
catalogue: **583 of 1,079 records carry a mesh, and 580 of those have a set**. The
three without are `MaleBody`, `FemaleBody` and `Head` — the base layer and the
skin, which are not items and never appear as a stage variant.

Categories with no sets and no meshes: `15_face`, `16_face-paint`,
`45_facial-hair`. Those records are texture sheets only; see `DECALS.md`.

Caveat: `80_dress`, `81_formal` and `83_dress-formal` are female-only items baked
on the male stock body, because the descriptor fixes gender and the female seed
outfit is not established anywhere in the data. They render, but the body under
the garment is the wrong one.

## Blocks the tools still ignore

* **Block 4, `ShapeOverrides`.** All 18 nose items (`Boxer's Nose`, `Curved Nose`,
  …) carry one and nothing else: no model, no texture. So a nose is a **head shape
  override**, not art, and no set is baked for those 18.

  What the bytes show, and what they refuse to show: the payload starts with two
  nested headers of the same shape, `u32 0, u32 0x13d4, u32 1, u16 2, u16 3`, then
  the same 8-byte id (`c1c8f109 a19cb2e0`) that repeats in every `.Avatar` entry,
  then a second copy of that header at +32. Length varies per nose (1,505 for
  `Defined Nose`, 1,608 for `Boxer's Nose`) and everything from +32 differs, so the
  shape data lives after the headers. Reading it as an array of little-endian
  floats gives exponent garbage and NaNs (`2053219840.0`, `nan`), so it is not a
  plain delta or matrix buffer; it is more likely another chunked/compressed
  serialisation like the model blocks. Decoding it is the open task, and until it
  is done the 18 noses have no 3D set.
* `45_facial-hair` and `16_face-paint` are textures only (block 2), which is why
  they bake as decals; `15_face` is 43 eye sheets (block 2) plus those 18 noses.

## Shape overrides: the biggest undecoded block

`inspect_pack.py` counts **266 assets whose only payload is block 4,
`ShapeOverrides`** — chins, noses and their relatives (`Large Chin`, `Boxer's
Nose`, `Chiseled Chin`, …). They are not art and not meshes; they are morphs, and
without them the pack's body and face shapes cannot be shown.

What has been ruled out, by test rather than by eye:

* **Not an LZX chain.** Exhaustive search over the first 96 bytes of `Defined Nose`,
  all six field orderings of the 12-byte header and three readings of the output
  size produced 0 successful decompressions; every model block decodes on the same
  call.
* **Not a flat float array.** Reading from +64 as little-endian float triples gives
  `2053219840.0` and `nan` where vertex deltas should be.
* **Not fixed-stride.** Payload lengths are irregular (`length % 12` spreads across
  every residue), so it is not `count + n × entry`.

The header repeats: `u32 0, u32 0x13d4, u32 1, u16 2, u16 3`, the same 8-byte id
(`c1c8f109 a19cb2e0`) that every `.Avatar` entry repeats, then a second copy of that
header 32 bytes in.

That id is **constant** - `Defined Nose`, `Curved Nose`, `Large Chin`, `Thin Chin`
and `Chiseled Chin` all carry it, and so does every 16-byte `.Avatar` entry
(`031f 0003 c1c8f109 a19cb2e0 00080000`). So it is a type GUID shared by the shape
objects and the description entries, not a per-item id, and it cannot be used to
match a shape to an item. The `u16 3` inside both headers does line up with the
class byte (3 = ShapeOverrides).

Ruled out since, by test:

* **Not an LZX chain either.** Every 4-byte offset from 0 to 96 was tried with all
  six orderings of the three header fields as (compressed, out offset, out size),
  constrained only by the payload length, and not one decompressed. So the block is
  not the chunked-and-compressed scheme the model blocks use.
* **Not a byte-aligned array.** Every shape's payload length is odd (`Boxer's Nose`
  1608, `Large Chin` 1613, `Sharp Chin` 1763) and there is no constant stride: after
the 64-byte header the sizes are 1549, 1277, 1522, 1359, 1699 - none divisible by
the head's 648 vertices, by 6 or by 12. An odd length after an even header means
the data is **bit-packed**, like the animation stream, so the next thing to try is
`BitStream` rather than `struct`.
* **A constant footer.** All three shapes end `... 03fc0000 00000000`, and the first
  word after the header is the same `36ed4402` in all of them - so the stream has a
  fixed prologue and epilogue that a decoder can key on once the body is understood.

What the header says, word for word (`Defined Nose`): `0, 0x13d4, 1, u16 2, u16 3,
GUID, 0, 0` then the same shape again with `0x6c` and `0x8400` where the first had
`0x13d4` and `1`. 0x6c is 108, 0x74 is 116, 0x6e is 110 - those track the payload
size closely enough to be a byte count, and `0x8400` (33,792) is constant across all
three, so it is a size for something the shape does not change.

## `.Avatar` descriptors: the avatars' own outfits

The `descriptors/Avatar####.Avatar` files are 1,000-byte descriptions the games
hand the avatar system. All three in the repo decode the same way, and
`avatar_desc.py` reads them:

    +0x000  4 x u32       header (as float32 the first two are -0.5)
    +0x010  n x record    shape overrides, variable length
    +0x0fc  9 x ARGB      colours
    +0x120  6 x record    look 1
    +0x300  6 x record    look 2 (cut short in these samples)

An override record is `u16 id, u16 class, 8-byte GUID`, plus a word or two; a look
record is `u32 slot, u16 id, u16 class, 8-byte GUID, u32 slot`. Both ids are
**big-endian** and index the asset catalog, so every entry has a name.

`MaleBody` in slot 2 is `MaleBody`, `Short with Left Curls (Hat)` in slot 4 is a
hair-with-hat, `Jacket with Sweater` in slot 8 is a shirt, `Male Flower Print
Flares` in slot 16 is trousers, `Grunge Trainers` in slot 32 is footwear. The six
slot values are the same in all three files, in the same order, so they are a
fixed mask and the position is what names the slot:

    2 body, 1 head, 4 hair/hat, 8 torso, 16 legs, 32 feet

Avatar6400's look, in full, is therefore **MaleBody, Head, Short with Left Curls
(Hat), Jacket with Sweater, Male Flower Print Flares, Grunge Trainers**, with
Elven Ears, two hiding templates, Skull Facepaint and two eye shadows applied as
shape overrides, and nine colours (hair `#6e5326`, as the bake scripts use).
Avatar6404 is the female equivalent: **FemaleBody, Head, Shaved Pattern (Hat),
Sweater with Shirt, Formal Trouser Suit, Female Jelly Clogs** with Round Ears,
Rosy Cheeks and a Comb Moustache.

The editor seeds a fresh pack avatar from Avatar6400's outfit for that reason -
it is the one look the console's own sample avatar wears, not a choice of ours.

**Unresolved:** Avatar6411 puts `Blue Fingerless Gloves` (46_gloves) in slot 16
and `Snowboarding Jacket` (82_coat) in slot 32, which no wardrobe allows. The
records parse cleanly and the other four slots of that file are ordinary
(`FemaleBody`, `Head`, `Combed Right`, `V Neck Top`), so this is not an alignment
error we can see - it may be a deliberately random or corrupt test fixture. Its
data is noted here but not used for anything.

## 2D plates: what the frame has to contain

The first plates framed each item against `MaleBody` alone, which produced two
visible faults that are worth writing down because both were only found by
looking at the result:

* **No head.** The pack keeps the head in its own asset - the descriptors equip
  `Head` in slot 1 next to `MaleBody` in slot 2 - so a body plate was a body with
  a neck stump. The reference frame is now measured on `MaleBody` + `Head`
  together (1.4756 tall instead of 1.1458), and a body plate is baked from both.
  Every plate had to be re-baked in the new frame, since the frame sets the scale.
* **No face.** `bake_pack_plates.py` did not pass `--face`, so the head came out
  as a blank skin shell. It now asks for the same brow/eye/mouth masks the 3D
  turntables are baked with, and the face is drawn per pixel from the sheets.
* **Hair covered the face.** A hairstyle is an open shell; rendered on its own,
  the inside of its far side faces the camera and fills the silhouette. Hair is
  now rendered with the head and body drawn into the depth buffer first
  (`bake_turntable.render(occluders=...)`), so only hair in front of the head
  survives. The same reason the 3D sets never showed the fault: the head is
  already there.

**The `(Hat)` hairstyles are damaged assets.** `Short with Left Curls (Hat)` is
102 vertices sitting between y 1.176 and 1.35 - a shell inside the skull rather
than around it - so its 3D set renders as a bald head. `Shaved Pattern (Hat)` is
the same shape of asset (171 vertices, y 1.176-1.347). Avatar6400 wears one of
these, so the editor's seed uses the stock `Left Parting` instead and this note
is the record of why the seed differs from the descriptor.

## Two avatars: the gender byte, and what it costs to bake both

Every asset's metadata says which avatar it is for (`+1`: 1 male, 2 female, 3 both),
so `avatar_tools/pack_genders.json` is a straight dump of that for all 585 models,
and the bakers take `--gender`. A female item baked on `MaleBody` is simply the
wrong picture, so the female half of the pack has its own trees:

| tree | contents |
| --- | --- |
| `pack_plates_female/<category>/<slug>.png` | 384 plates, posed on FemaleBody |
| `assets/3d/turntable_female/<slug>/` | the same 384 items, six frames each |
| `PackGenders.qml` | item slug -> gender, so the strip only offers what fits |
| `PackPlatesFemale.qml` | the female plate index |

Both seeds are the pack's own descriptors: Avatar6400 dresses the male avatar
(Jacket with Sweater, Male Flower Print Flares, Grunge Trainers) and Avatar6404 the
female one (Sweater with Shirt, Formal Trouser Suit, Female Jelly Clogs). Two
caveats, both data:

- Avatar6404's legs item is `Formal Trouser Suit`, a formal outfit (`81_formal`),
  not a `20_pants` item. The female seed names it anyway; since it is not in the
  pants list the slot falls back to that category's first item.
- The hair seeds are the stock styles (`Left Parting`, `Shaved Pattern`) rather
  than the descriptors' `(Hat)` shells, which render bald for the reason given
  further down.

The female body shows small gaps at the hips under trousers (`formal-trouser-suit`,
`female-baggy-jeans` and `twin-set` all do, so it is the body under cloth and not
one garment). That is very likely what the 266 undecoded `ShapeOverrides` blocks
are for - they are the only per-item block left that could move the body under
clothing - so it is left as a defect rather than patched by hand.

## Face overlays in the 2D editor: a rendered difference, not a cutout

The pack's face items are UV sheets, not body plates, so they cannot be baked like
a shirt: there is no mesh to pose, only paint on the head. What the editor needed
was the same thing the 3D bake produces, a flat picture of the head wearing the
item, and `bake_pack_face.py` makes it by subtraction. It renders the pose's frame
once with the default head and once with the item in place, and keeps the pixels
that changed:

```
alpha = clamp((|painted - plain| - 6/255) / (24/255), 0, 1) * painted_alpha
```

The lower bound drops colour rounding, and the band up to `24/255` feathers the
edge, because a sheet's border is antialiased. A hard cutoff at `4/255` drew a
faint rectangle around the eyes where the sheet's own edge is. An item that changes
nothing (`Happy Eyes` against the default head) fails rather than baking an empty
plate, and `Head` has no texture at all and is skipped.

Result: **44** `15_face` plates (the 18 noses have no art to draw - they are
`ShapeOverrides` morphs), **26** `16_face-paint`, **17** `45_facial-hair` - 87
plates, each composited above `10_body` and below `50_hair` by its category's own
number. `AvatarEditor.qml` used to drop all three categories in pack mode
(`isPackDecal`); it now drops them only when the category has no plates.

This also exposed a bug in the shared decal blend, which affected the 3D sets too:
`art + albedo * (1 - cover)` added the sheet's colour even where its alpha was
zero, so a sheet with white transparent pixels washed the whole face out. It is
`art * cover + albedo * (1 - cover)` now, and the 43 face-paint and facial-hair
sets were rebaked with it.

## The pose: an idle, not a cheer, and hands that had to be curled by hand

Every static bake used frame 0 of `Cheer.AvatarAnimation`, the one clip that ships
as a file beside the pack. Frame 0 of a cheerleading clip is a cheer: arms out,
fingers fanned. That is what "his hands don't look like that" was.

The pack carries its own standing idles, so the bakes now pose frame 0 of
`Animation Male Idle Shifts Weight` (242 frames), extracted from the pack by
`pack_clip.py`. Both bakers take `--clip-asset "Animation Male Idle Shifts Weight"`.

**The hands: measured, then fixed.** `probe_hand.py` renders a hand close-up and
prints two numbers that settle the question: the clip's rotation of each finger
joint, and the *geometric* bend at each knuckle (the angle between knuckle, middle
and tip, which is what a viewer sees).

| | before | after |
| --- | --- | --- |
| knuckle bend, bind pose | 1-14° (straight) | - |
| knuckle bend, idle clip | 6-12° | - |
| knuckle bend, clip + curl | - | 16-25° |

**Every clip was asked, not just the idle.** `scan_clips.py` measures the knuckle
bend for all 41 animations in the pack. All of them sit at 17.9° - the bind
geometry's own angle, the fingers straight - at frame 0, and only the expressive
clips close a hand at all: `Angry` reaches 114° (a fist), `Clap` and
`Idle Checks Hand` about 45°, `Idle Shifts Weight` 23°. The nine
`Animation Creator Look *` clips are head-only: the fingers never leave 17.5°.
There is **no relaxed-hand pose in the pack** to copy, so the pose has to be built.

**The thumbs were missing entirely.** Joints 43 and 50 look degenerate - their root
sits exactly on the wrist, 0.010 out - but each carries a three-joint chain ending
at (0.098, -0.055, 0.079) in wrist space: out from the wrist, down, and forward.
That is a thumb, and a real thumb's base joint sits back at the wrist like that.
They had been filtered out as helper bones, so the thumb was a rigid stub. The
childless joints 41/42 and 48/49 are the ones with nothing attached.

**The fingers had to be brought together, not fanned back.** The four knuckles sit
at z +0.042, +0.011, -0.019, -0.047 and their tips at +0.043, +0.011, -0.019,
-0.047: the bind fingers are *parallel* and 0.03 apart, so there is no fan angle to
remove (measured 0.1-0.9°, which is why the earlier fan correction did nothing).
What closes the gaps is adduction - rotating each knuckle about the palm normal by
`atan2(spread, length)`, which lands the tip on the hand's midline - times
`FINGER_ADDUCT` (default 0.85).

**The wrists needed 90° of pronation, which no clip has.** The idle swings the arm
down from the T-pose without any twist, so the palm - down in bind - ends up facing
sideways, showing the camera the hand's full width. A 69-vertex hand at full width
is a fan of thin prongs. The retail editor's own preview
(`resources/app/app/assets/previews/editor-metro2010.png`) shows palms facing the
thighs, which stacks the fingers behind one another and reads as a hand.
`apply_wrist_roll` turns each forearm about its own axis (`AVATAR_WRIST_ROLL`,
default -90°); the two signs were rendered side by side and -90° chosen.

Curl is 8/10/6 degrees per phalanx. `AVATAR_FINGER_POSE=0` shows the clip's own
hand for comparison; `AVATAR_FINGER_CURL`, `AVATAR_FINGER_ADDUCT`, `AVATAR_FINGER_SIGN`
and `AVATAR_WRIST_ROLL` override the numbers. `show_hand.py` draws one hand from
eight angles against the bind pose, and `probe_hand.py` prints joint and knuckle
angles.

The hand is small: 69 vertices and 100 triangles, selected by skin weight (the palm
rides the wrist joint, not a finger). Its finger bones cover the inner two thirds of
the geometry - bones 0.082 long, geometry 0.120 from the knuckle - so the tips ride
rigidly on the last joint. That is the mesh, not a decode error; both packs in the
archive carry the same 1,137-vertex `MaleBody`.

Also ruled out while looking: the clip's joint *scale* is not what stretched the
hand (`AVATAR_IGNORE_SCALE=1` renders identically; the scales are 1.0).
