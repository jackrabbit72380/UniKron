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
| `10_body` | 11 | 1 | 1 | 9 |
| `12_eyebrows` | 27 | 0 | 0 | 27 |
| `15_face` | 64 | 0 | 0 | 64 |
| `16_face-paint` | 26 | 0 | 0 | 26 |
| `17_eye-shadow` | 45 | 0 | 0 | 45 |
| `20_pants` | 54 | 27 | 27 | 0 |
| `30_shoes` | 36 | 18 | 18 | 0 |
| `40_shirt` | 137 | 71 | 66 | 0 |
| `45_facial-hair` | 17 | 17 | 0 | 0 |
| `46_gloves` | 16 | 8 | 8 | 0 |
| `50_hair` | 178 | 0 | 0 | 178 |
| `60_hat` | 34 | 17 | 17 | 0 |
| `70_glasses` | 34 | 17 | 17 | 0 |
| `75_earrings` | 34 | 15 | 19 | 0 |
| `76_rings` | 16 | 8 | 8 | 0 |
| `77_wristwear` | 16 | 8 | 8 | 0 |
| `80_dress` | 15 | 0 | 15 | 0 |
| `81_formal` | 7 | 5 | 2 | 0 |
| `82_coat` | 4 | 4 | 0 | 0 |
| `83_dress-formal` | 1 | 0 | 1 | 0 |

`12_eyebrows` is not one of the pack's own masks: the eyebrow sheets carry the
body bit (0x0200), so they filed under `10_body` beside `MaleBody`/`FemaleBody`
and were unreachable there, because the editor draws `10_body` as a single base
plate. The retail editor gives them a button of their own
(`EyebrowsCreateButton`), so `asset_catalog.refine_category` splits them out and
keeps the pack's category in `slot_category`. Their plates come from
`bake_pack_face.py --categories 12_eyebrows`, which paints the brow mask onto
the head exactly as it does for the eye and face-paint sheets; the stock brow is
compared against `Shaved Eyebrows` because a sheet compared with itself changes
nothing.

`17_eye-shadow` is split out the same way. Its 45 sheets carry the hair bit
(0x0400) and so filed under `50_hair`, where they were listed as hairstyles; they
paint the eyelid, and the retail editor has an `Eye Shadow` button. Their UV set
was measured rather than guessed - set 5 brackets the eye band, wider than the
lash sheet - so `bake_pack_face.py` renders them through that set (mask in
alpha). 50_hair keeps its 178 real hairstyles.

### Face shape, split into Nose / Ears / Head Shape

The 36 shape overrides divide exactly as their names do, and as the retail
buttons do: **18 `*nose`, 9 `*ears`, 9 `*chin`**. They are now three folders -
`71_nose`, `72_ears`, `73_head-shape` - with the retail labels out of the XUI
(`nose`, `ears`, `faceshape`), so the rail reads Nose, Ears, Head Shape instead of
one "Face Shape" list of noses, ears and chins together.

The art caveat stands and is why this stayed one list for so long: these items
have no geometry of their own (block-4 overrides), so their pictures are the
per-item renders in `pack_art/71_nose/` etc., and those are **head close-ups
framed on the item** (`large-chin.png` fills its canvas with a face) rather than
plates registered to the body frame the stage stacks. Splitting them does not
change that: a shape is a geometry morph, which a layer stack cannot express, and
the 3D sets (`assets/3d/turntable/angled-nose/` and friends, all 266 shapes have
one) are what actually show it. A 2D plate would have to be a full head render in
`bake_pack_plates.reference_frame`, not a difference plate: a morph moves the
silhouette both ways and a difference can only add pixels.

The other 307 assets have a zero slot mask: they are the 41 named animations plus
hiding templates and other non-wearable records.

## The retail buttons, read from the editor's own strings

`xex_ui_strings.py` pulls the 2008 editor's UI vocabulary out of
`avatareditor.xex` (UTF-16LE, `editor_ui.json`) and writes its embedded button
art to `assets/_ui/xex/` (293 PNGs). The editor names its categories itself:

    body hair faceshape facial nose ears eyes eyebrows mouth mouth_male
    facial_hair_male facial_skin_male facial_female tops bottoms shoes hat
    glasses gloves gloves_female ring watch earring body_access head_access
    makeup makeup_male lipstick eyeshadow colour_palette_skin option_colour
    malecostume femalecostume loadoutfit saveoutfit takephoto photobooth
    bodyshape_normalthin bodyshape_normalnormal bodyshape_normalfat
    bodyshape_tallnormal bodyshape_smallnormal

each with `_selected.png`, `_unselected.png` and `_pressdisable.png`. Two things
this corrects:

* **The accessory buttons are not missing content.** `Gloves`, `Rings`,
  `Wristwear` and `Earrings` are all in the pack and already in the rail
  (`46_gloves` 16 items, `75_earrings` 34, `76_rings` 16, `77_wristwear` 16;
  half as many after the gender filter). An earlier note in this folder claimed
  these screens had no content because the search looked for *accessory* words;
  the items are called `Woolly Gloves`, `Slick Watch`, `Male Diamond Stud
  Earrings`, `Gold Bracelet`, `Gold Ring with Emeralds`.
* **`Skin Color`, `Lip`, `Eye Shadow` and `Makeup` are colour screens, not item
  lists.** The image carries `colour_palette_skin`, `lipstick`, `eyeshadow`,
  `makeup`, `option_colour` and the slots `Color0`...`Color15` with
  `BonusColors`/`BonusColorsEnd` and the `Color%d` name format. They paint the
  descriptor's nine ARGB colours (`avatar_desc.py`, `+0x0f8`) instead of picking
  items, which is why the pack contains no lipstick item and never would.

There is also a **body shape** control with five options
(`bodyshape_normalthin`, `_normalnormal`, `_normalfat`, `_tallnormal`,
`_smallnormal`), which `10_body` does not yet offer.

What is left of that list, with the reason each is where it is:

* **`nose`, `ears` and `faceshape` are done** - the 36 shape overrides are now
  `71_nose` (18), `72_ears` (9) and `73_head-shape` (9), labelled Nose, Ears and
  Head Shape.
* **`body_access`, `head_access`, `Carryables` and `Neckwear` have no content in
  this pack.** Measured over all 585 records: no record carries an accessory,
  carryable or neckwear category, and no name contains `accessor` or `carry` -
  the only "neck" names are garments (`V Neck Tee`, `Open Neck Cardigan`). The
  pack's accessories are the four slots already in the rail: gloves, rings,
  wristwear, earrings. A button with no items behind it would be an empty screen,
  so these are not built.
* **`facial` (Facial Features)** is the hub the feature buttons live under; its
  content is the shape and colour screens, covered above.
* **`malecostume`/`femalecostume` (Costumes)** map onto the four formal
  categories already in the rail. `81_formal` (5) and `82_coat` (4) have items;
  `80_dress` and `83_dress-formal` are empty, which is the pack's coverage, not a
  missing baker.
* **`loadoutfit`/`saveoutfit` (My Outfits)** need somewhere to store an outfit.
  `AvatarEditor.qml` emits `saveRequested(state)` and nothing in the port
  consumes it, and there is no settings store in the theme; the retail strings
  (`Save Outfit`, `My Outfits`, `You have no outfits.`, `Outfits storage is
  full.`, `AvatarDeleteOutfitButtonOverride`) are read but the screen needs a
  storage decision this port has not made.
* **`takephoto`/`photobooth`** are the retail camera path; the port has its own
  portrait grab (`AvatarEditorPage.portraitReady`) instead.
* **The five body shapes** (`bodyshape_normalthin` ... `bodyshape_smallnormal`)
  are a geometry control over the same body, not a list of items: they need the
  body scale the retail editor applies, which is not yet located in the pack or
  the descriptor.

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

## Block 4, `ShapeOverrides`: decoded, all 266 of them

This section used to say the block was undecoded. It is not: `decode_shape.py`
reads it, and the hint was already written down here - every payload length is
odd (`Boxer's Nose` 1,608, `Large Chin` 1,613, `Sharp Chin` 1,763), so the body
is **bit-packed** and wants `BitStream`, not `struct`. The LZX attempts failed
for the same reason: it was never compressed.

All 266 decode, with no failures, and they split three ways:

| kind | assets | target mesh | stride | non-empty |
| --- | ---: | --- | ---: | ---: |
| `* Hiding Template` | 202 | body | 40 | 163 |
| `* Nose` / `* Chin` / `* Ear` | 36 | head | 52 | 25 |
| body and garment templates | 28 | body and head | 40 / 52 | 18 |

The stride is the target mesh's own vertex size, so it says which asset a shape
moves without being told. Each entry is a vertex number and the position that
vertex takes, which is why the face shapes move the head in bind pose and carry
into the skinning.

**51 of the 266 are 115 bytes and hold zero entries.** They are the defaults -
`Small Chin`, `Angled Nose`, `Round Ears`, `Male Short Sleeved V Top Template` -
where the item *is* the shipped body, so there is nothing to decode and nothing
to apply. That is why 36 face shapes give 25 non-empty morphs.

**What a hiding template is.** It names the body vertices its garment covers, and
`bake_avatar.py --hide` drops the body triangles that use them so the cloth is the
only surface. It is not a complete list of the covered region: the formal
trousers name 38 vertices, and the thighs still show skin through them.

**What the body templates are.** 198 of the entries in `High Heel Body Modification
Template` and `Female Strappy High Heels Template` reshape the feet; the rest are
per-garment fit adjustments (`Female Medium Skirt Bottom Template`,
`Male Long Sleeved Top Template`, `Two Tone Tee Template`). None of them is applied
by the bakers yet.

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

**CORRECTION: the thumb was still never flagged.** `finger_bones` chose the thumb
as the knuckle sitting furthest off the palm's own plane, and that cannot work:
a thumb root back at the wrist is very nearly *in* that plane, so the maximum
landed on an ordinary finger and `is_thumb` was false for every entry - 30 entries
in the list, not one of them a thumb. The tell was that deleting the
`FINGER_THUMB_SCALE` on the adduction changed **0 pixels**. The rig separates the
two structurally instead: joints 43 and 50 sit 0.0099 from wrist 33/36, and every
other child of a wrist is 0.107 or further, so the thumb is the nearest one. With
that, 43/50 and their phalanges (55/65 and 60/70) are flagged, the thumb takes its
lighter curl and adduction, and the hand changes by 1.2% of the plate, all of it
in the two thumb regions.

**The fingers had to be brought together, not fanned back.** The four knuckles sit
at z +0.042, +0.011, -0.019, -0.047 and their tips at +0.043, +0.011, -0.019,
-0.047: the bind fingers are *parallel* and 0.03 apart, so there is no fan angle to
remove (measured 0.1-0.9°, which is why the earlier fan correction did nothing).
What closes the gaps is adduction - rotating each knuckle about the palm normal by
`atan2(spread, length)`, which lands the tip on the hand's midline - times
`FINGER_ADDUCT` (default 0.85).

**That adduction was inverted, and it was the fan.** `finger_bones` picks the
direction by rotating the tip 15° about the palm normal and asking whether that
brings it nearer the midline; the answer is the *inward* direction, so it needs
+1, but it was stored as -1 and every adduction came out as an abduction. The
measurement that shows it is a sweep of `AVATAR_FINGER_ADDUCT` on the idle pose:
before the fix 0.85 fanned the fingers a little and 1.4 fanned them *wider*, which
no amount of tuning could have fixed from the outside. With the sign corrected the
same values converge, and the bakes are rebaked with it - the plates, the 1,204
item sets, the four hairstyle sets, both default sets and the 120 animated frames.

What is left is the mesh, not the pose: a hand is 69 vertices and 100 triangles,
four tubes with no webbing, so at a close zoom the fingers still show as separate
prongs. At the size the closet draws them they read as one hand.

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

## Audit before baking

`audit_pack.py` is the gate for every bake, and `rebake_everything.sh` runs it
first. It opens all 1079 assets, decodes what it can, checks each model (indices,
weights, joint range, UVs), each animation (unit quaternions) and each texture
(declared size), then cross-checks the pieces that have no business disagreeing:
the skeleton's joints against the meshes, the descriptor slots against the assets,
and the pack against the item list a bake will walk.

`DECODE_STATUS.md` is its output, written by `--md`, and it is the honest answer
to "do we have everything": 583 assets with geometry, 187 textures, 41
animations, 71 joints, and two gaps it still names: the 87 scalp-cap hairstyles that
only work under a hat, and the body templates of block 4, which decode but are
not applied by any baker.
Anything unexpected makes it exit non-zero and stops the bake; `SKIP_AUDIT=1`
bypasses it, which is only for iterating on the bakers themselves.

## Verifying the art against the plan

`verify_art.py` answers, without baking, whether the files on disk are the ones
the plan asks for: one plate and one six-frame turntable per item, 120 animated
frames, and nothing missing. `rebake_everything.sh all` now ends with it, so a
rebuild that quietly skipped something exits non-zero instead of looking finished.

It expects two things that are easy to mistake for gaps. Female face, face-paint
and facial-hair plates are not expected: both bodies share the one `Head` asset and
the editor falls back to the male sheet. And an item with no geometry cannot have
a plate of its own, which is why the eyes are drawn by `bake_pack_face.py`.

## The body under the clothes

The 3D sets showed skin-coloured specks on the shoulders, the sleeve and the
ankle of an otherwise fully dressed avatar. Three tests settled what they were,
and the first two are recorded because they are the wrong answers:

* They are **not** the garment's own colour. Hiding every garment vertex named by
the stock outfit's block-4 hiding templates (`Jacket with Sweater Hiding
Template`, `Flower Print Flares Hiding Template`, `Grunge Trainers Hiding
Template`) removes 57 of `MaleBody`'s 1,137 vertices and changes no pixel.
* They are **not** the cut templates either: `Male Long Sleeved Top Template` plus
`Male Trousers Bottom Template` hide 45 vertices, and both together with the
item templates hide 70. The specks stay.
* They **are** `MaleBody`. Baking the same outfit without the body removes every
one of them, and nothing else changes.

So the body and the garment are skinned separately, and at the shoulder the
body's surface crosses outside the sleeve's. `bake_avatar.py` now settles it from
the garment's own geometry instead of from a template: a body vertex that is
outside the worn garments but within 2 cm of one is pushed along its own normal
until it sits just inside the cloth (`tuck_under_clothes`). On the stock male
outfit that is **112 of 1,137** body vertices, and the count is printed per bake
so a change in the meshes shows as a different number rather than as a silent
regression. `--no-tuck` turns it off.

Three simpler versions were tried and are recorded because each looked wrong in
the render, not in theory:

| rule | vertices moved | what it did |
| --- | ---: | --- |
| delete every enclosed body vertex | 504 | removed the specks and opened see-through slivers down the leg and the jacket's side, where a garment seam is the only surface |
| push every vertex within 5 cm of a garment | 155 | pinched the wrists: a hand hanging below a cuff was caught and pulled onto it |
| same, with a nearest-vertex distance | 638 | collapsed the forearm, because a coarse garment's nearest *corner* is a sleeve radius from its surface |

What the templates are worth is a separate measurement: only **180 of the 849**
catalog items ship a hiding template at all (the pack names one per wardrobe
piece it offered; `Male Power Tee` and `Chinos` have none), and the templates
that do exist name too few vertices to matter here - 57 for the whole stock
outfit. So the cover pass is computed from whatever garment is actually worn, and
the templates are not used by the bakers.

That difference bake had one hole of its own. The stock face is `Straight
Eyebrows, Happy Eyes, Smirk Mouth`, and the comparison starts from it, so the item
that *is* that face differed from itself by nothing and was dropped as "the sheet
changed nothing" - `pack_plates/15_face/happy-eyes.png` was the only plate in the
project that did not exist. That item is now compared against `Sharp Eyes`
instead, which differs only in the iris.
