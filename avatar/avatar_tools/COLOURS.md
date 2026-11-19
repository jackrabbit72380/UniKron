# CustomColorTable (STRB block 7)

Earlier work recorded item colours as missing because every garment's texture slot
is empty. That was looking in the wrong block: **405 of the 1,079 pack assets carry
a `CustomColorTable` (block 7)**, and three of them hold a real palette.

## The editor's own colour palettes: on the disc, extracted

**CORRECTION to a long-standing note in `DECOMPILE.md`:** the swatch colours *are* in
`avatareditor.xex`. An earlier scan looked for six or more consecutive *warm* opaque
ARGB words and found none, and concluded the values were not on the disc. They are,
plain and uncompressed, in the image's read-only data - the scan's shape was wrong,
not the data absent.

`xex_palettes.py` reads them:

* at file offset **0x21c68** there is a table of (pointer, count) pairs, eight bytes
  each - ten entries, a (0,0) terminator, two further entries, another terminator;
* the pointers are absolute image addresses and the data section maps at
  **vaddr = file offset + 0x97FFD000**, solved from the first entry
  (`0x9801e7c0` -> `0x217c0`); every entry is then checked, not assumed:
  `count` opaque ARGB words must sit exactly at `pointer - 0x97FFD000`;
* all eleven pass, and the tables are packed back to back from `0x217c0` to
  `0x21c64`.

**The nine tables are the nine colour slots of the `.Avatar` descriptor.** That is
measured, not inferred: the descriptor keeps **nine** ARGB words at `+0x0fc`, and for
all three shipped profiles every one of those 27 words is a member of the table at
the same slot index (27 of 27, `xex_palettes.py` prints the check).

| # | slot (image label) | colours | file offset | values |
| --- | --- | ---: | --- | --- |
| 0 | Skin Color | 18 | 0x217c0 | `6e4124 d7aa71 fceedd 64411b be8749 f8dbb9 40280e 98652f e6bc8e dbcab7 e3a976 d7b971 f0b393 de914d c7984c e3946b d3793d a87d3f` |
| 1 | Hair Color | 27 | 0x21838 | `fffcb5 e4d381 decfba feef7c dcb74f bfa783 f7d748 bd934b 988054 906636 85541a 6e5326 745131 553921 372116 493421 1f120b 0d0d0d e3802f 92340e e2dedd b85e22 682618 8e8274 753e1f 523436 4f463d` |
| 2 | Lips | 27 | 0x21ba0 | `fd6a68 e58995 d59282 d00e0e c65265 b56157 ad2d2d 9f5d69 83463f cf8562 eb7d80 efc28b 875741 f5686b eca853 5c3b2c cb6758 bc7535 d46552 da61d4 786dd5 b14a37 b93996 6e51a5 8a1a0e 8f2d5e 000000` |
| 3 | Eye Color | 18 | 0x21af0 | `92b2ca 88b049 ae9843 6381a7 727f35 82501d 2a72a4 37512a 5b351e 917a51 cececc 7b7b95 312114 595d5c 8f7497 212121 243f53 ab0207` |
| 4 | Facial Hair Color | 27 | 0x21838 | the hair table |
| 5 | Facial Feature Color | 26 | 0x21b38 | `ba72b6 aaa6c9 f75a87 9a2f7d 776dd3 c5496d 631a46 6e50a4 a9cef0 b2b05d ffe2a3 5395ca c1c335 fec854 195381 61701f e06e32 f3bc7b c1a590 ffffff c08950 b37d59 a2a89b 904f33 6a3919 000000` |
| 6 | Eyebrow Color | 27 | 0x21838 | the hair table |
| 7 | Eye Shadow Color | 27 | 0x21a80 | `e8c84f e673b8 66bcdc e18417 7f3979 2ab0ab d13927 5f4294 4265bc 8abf55 bcae89 ffffff 399251 8c603a 8b8b8b 4d5523 654428 616161 aa7c65 d75f47 ecb6be ad5f47 aa1d26 cf5969 59332f 81271f b24f7d` |
| 8 | Eyeliner Color | 27 | 0x21a80 | the eye-shadow table |

Plus three narrower lists: `skin-short` (12, entry 10), `lips-short` (21) and
`eye-short` (15). Each is a strict subset of its full table - `skin-short` drops
`fceedd f8dbb9 40280e dbcab7 e3946b d3793d`, `lips-short` drops
`da61d4 786dd5 b93996 6e51a5 8f2d5e 000000`, `eye-short` drops `7b7b95 8f7497
ab0207` - which is what a per-gender or reduced list looks like. Which of the two
it is cannot be told from the data, so they are recorded and not used.

**What is measured and what is inferred.** Measured: the eleven tables, their exact
values, their slot order, and the descriptor cross-check. Inferred: putting the
image's nine colour labels on slots 2-8. The reasoning is that the sharing pattern
is forced - the index repeats the hair table three times and the eye-shadow table
twice and uses every other table once, and the nine labels are exactly {Hair,
Facial Hair, Eyebrow} sharing one palette and {Eye Shadow, Eyeliner} sharing
another, with Skin, Lips, Eye and Facial Feature each having their own. Slot 0 as
Skin and slot 1 as Hair is independently established in this file (index 0 matches
the retail skin tone, index 1 matches `HAIR_COLOUR`).

**Still open: the rule, not the values.** Whether the game *replaces* the body's
material colour with slot 0 or *multiplies* the two is not established - the pack's
body material renders to about `#a7845b` and the retail skin is `#d7aa71`, and both
rules could produce that pair. Nothing is rebaked on the guess.

**The 3D stage cannot tint.** The editor's art is baked per item: a plate and a
six-frame turntable of that item already in colour, 846 of each. The 2D stage now
applies a palette colour over a coverage mask (below); the turntables are only baked
in colour, so a colour pick does not reach them yet.

### How a colour reaches the avatar (measured)

A colour screen is only worth having if a pick changes the avatar, and every face
plate is baked in colour. The route that works is a **coverage mask**: the renderer
emits the sheet's own paint, and the editor multiplies it by the palette colour at
run time.

* `bake_turntable.render(..., coverage=True, only="layer0")` writes RGB as the light
  rig on the sheet alone and alpha as the sheet's own coverage, both straight.
  `only` isolates one layer or decal, so a mask is *that item's* paint and not the
  rest of the face with it.
* `bake_pack_face.py --mask` drives it for the head sheets: **160 masks** in
  `pack_plates_mask/` - brows 27, eyes 45 of 64 (the 19 nose sheets have no UV set),
  face paint 26, eye shadow 45, facial hair 17. One gender only, because the head
  asset is shared.
* `bake_pack_plates.py --mask` is the same idea for a mesh, and gives **176 hairstyle
  masks**: `white=True` makes the item's whole silhouette the paint, so alpha is the
  outline and RGB the light rig. Those are in the male frame, which is the only frame
  `pack_plates_mask` holds.
* `make_colour_qml.py` turns those and `colour_palettes.json` into `Colours.qml` and
  `PackMasks.qml`; `TintedMask.qml` is the shader that applies a colour. It is
  `sRGB(linear(mask) x linear(tint)) x alpha`, premultiplied, so the stage's ordinary
  source-over gives `tint x shading x coverage + skin x (1 - coverage)`. The multiply
  is in linear light because the baker shaded in linear light.

**Checked.** Over fully covered pixels, `plate / mask` equals the colour the plate was
baked with - `#493421` for every brow, `#6e5326` for the facial hair, and a flat
grey `#8a8d93` for hair, which is the pack's untextured hair material and matches
to a spread of 0.2 %. On the face masks the spread is under 1.3 %. Composited the way the shader does it, the result matches the
baked plate to **mean 0.5-1.1 and p95 3.9-5.5 out of 255** on interior pixels (edges
differ because the plate's alpha is a difference ramp and the mask's is real
coverage). `artifacts/tinted_brows.png` is the same brow in four of the game's own
eyebrow colours.

**Not checked by any render here.** `TintedMask` is a `ShaderEffect`, and this
project's harnesses run on `QT_QPA_PLATFORM=offscreen`, where nothing with a
`ShaderEffect` in it draws: measured 2026-11-19, a `ShaderEffect` whose fragment
shader returns solid lime leaves the background untouched, and `TintedMask` over a
black rectangle leaves every sampled pixel at the background, with no message
(`minimalegl` and `eglfs` do not start). Every screenshot in this repo is therefore
plates only: no brow, eye-shadow, iris, lip or skin tint is in it. What is checked
instead: `research/run_colour_check.py` - the mask exists for every mapped
category and the layer's tint equals the palette entry, 17 checks - plus the offline
arithmetic above, and `Colours.qml` compared entry by entry against
`colour_palettes.json`.

**On now:** eyebrows, eyes, eye shadow, facial hair, hairstyles (male), skin and lips.
Two are left alone, on purpose:

* **Face paint.** Painted art, not a tint mask, so a colour must not replace it.
* **Eyeliner** has a table (the eye-shadow one) and a screen ("Eyeliner Color") but
  nothing in the pack to put it on. See the eyeliner note below.
* **Skin** is the body plate itself, and its 11 items are not masked yet. It also
  hits the replace-vs-multiply question below: the plate carries a baked skin colour
  (`#a7845b`) while a descriptor colour is `#d7aa71`, and the data at hand cannot say
  whether the game substitutes the colour or modulates the material with it.

**Ruled out, for the record.** The cheap shortcut was to re-bake with every tint
white and multiply afterwards. It fails because a plate's alpha is a *colour
difference* (rendered twice, 6/255..24/255 ramp), so it moves when the tint does:
measured on three brows, 9-12 px of coverage disagreed and the plate/mask ratio's
median spread reached 0.60 (p95 1.7). `--mask` no longer takes that route.

## What the block contains

| assets | payload | shape |
| --- | --- | --- |
| 402 | 28 bytes | `u32 count = 1`, then 6 × RGBA: opaque black, clear, opaque black, clear, opaque black, clear |
| 3 | 109 bytes | `u32 count = 9`, then 24 bytes of base colour, then 9 colours × 9 bytes |

The 402 standard items therefore hold only **placeholder** colours (black and
clear), which is consistent with their empty texture slots: for those items the
colour is not in the pack.

## The three items that do carry a palette

`Male Power Tee`, `Female Power Tee` and `Tight Tee`. Each palette colour is
stored as **three identical RGB triples** (9 bytes); the middle/interpolation
role of the repeats is not established, so the reader takes the first triple.

| Male Power Tee / Female Power Tee | Tight Tee |
| --- | --- |
| `#232323` base | `#A65D0F` base |
| `#B7630F` | `#7DC513` |
| `#DCDCDC` | `#C18952` |
| `#C5D5D5` | `#59A2F0` |
| `#5D5D5D` | `#5AA1F0` |
| `#DD1C5D` | `#762FF0` |
| `#DDDBDC` | `#5AA2C9` |
| `#F969DC` | `#355AF0` |
| `#E605B4` | `#B7B196` |
| `#EA6238` | — |

The Male and Female Power Tee tables are byte-identical.

## The `.Avatar` descriptors carry the real thing

`Avatar Games.zip` (the avatar-games collection) ships `Avatar6400.Avatar`,
`Avatar6404.Avatar` and `Avatar6411.Avatar` - the 1,000-byte descriptions the
console hands the avatar system. Each holds **nine colour slots at 0x0fc**,
stored as A, R, G, B with alpha always 0xff. (Earlier notes said eight at 0x100;
reading the files byte by byte fixes both numbers, and finds a ninth colour that
was being dropped.)

| file | nine colours in order |
| --- | --- |
| Avatar6400 | `#d7aa71` `#6e5326` `#b56157` `#6381a7` `#493421` `#5395ca` `#493421` `#cf5969` `#cf5969` |
| Avatar6404 | `#98652f` `#553921` `#875741` `#727f35` `#553921` `#a2a89b` `#0d0d0d` `#81271f` `#81271f` |
| Avatar6411 | `#d7aa71` `#1f120b` `#cf8562` `#5b351e` `#1f120b` `#904f33` `#1f120b` `#ad5f47` `#ad5f47` |

Two of the nine can be named from evidence:

* **index 1 is hair.** `#6e5326` in Avatar6400 is the brown the bake scripts had
  been passing as `HAIR_COLOUR`, so these are the colours the retail avatar
  actually wears - the per-avatar answer to the tint values the pack omits.
* **index 0 is the skin tone.** Avatar6400 and Avatar6411 share `#d7aa71` while
  their hair differs, which is what a skin slot does and a garment slot does not.

The other seven are not named. They are recorded in order rather than guessed at.

## The skin the bakes actually use

This matters for fidelity and is currently a known difference. The pack's body
meshes carry a flat material colour, and a baked body plate converts to about
`#a7845b` under the baker's lighting; the retail avatars above wear `#d7aa71`.
The pack has no body texture to tint, so the game must be replacing or
multiplying that material colour with the descriptor's index 0 - and which of the
two it does is not established. Nothing is rebaked on that guess: the bodies are
rendered with the pack's own material colour, and this note is the record that the
retail skin tone is a different, known value.

## Reproducing

```python
import avatar_mesh

blocks = avatar_mesh.strb_blocks(blob)          # blob = pack[offset:offset+size]
table = next(p for i, _, _, p in blocks if i == 7)
```

`asset_catalog.py` records every asset's block list, so the colour table's
presence and size are in `asset_catalog.json`.

## What the 2008 code does with them (read from the decompile)

No inference here: these functions are in `UniKron-decompiled-xbox360-2008.zip`, found by
following the palette index instead of guessing names.

* `FUN_9807fee0(i)` - **the palette accessor**: `i < 10` returns `0x9801EC68 + i*8`, else 0.
  That is the index extracted above, so its ten used entries (skin, hair, lips, eye,
  facial_hair, facial_feature, eyebrow, eye_shadow, eyeliner, skin-short) are the complete
  set the runtime knows; ten is the hard limit in the branch.
* `FUN_98058548(i)` - a **second** index at `0x980050D8 + i*8`, gated by `DAT_9817bc90` and
  only for `i < 10` (or `i == 1` when the flag is set). Its region is zero in the image, so
  it is filled at run time - the likely home of the short lists the extraction found
  beside the full ones (lips 21, eye 15, skin 12).
* `FUN_98058590()` - how many tables a slot has; `FUN_980585e8(slot, i)` - table `i`.
* `FUN_98056298(slot, index)` - **how a colour is picked**: it walks a slot's tables
  subtracting each one's count from the flat index, so the UI presents one list that is the
  concatenation of that slot's tables. The value returned is a raw **ARGB word**,
  `0xffffffff` for nothing, and slot id **9 means "no colour"**.
* `FUN_98055848(control)` - a switch over control ids **0x18 to 0x21**, the colour rows:
  each case reads a value with `FUN_980a3750` and writes one with `FUN_980a36f0`; both
  resolve a handle through `FUN_980a1f10(..., DAT_98190394)` and then call
  `FUN_980bf648` / `FUN_980c3e78`. Those two are where the ARGB lands, and where the
  replace-vs-multiply question is answered.

So the model to copy is: nine slots plus `none`, raw ARGB words, and a picker that lists a
slot's tables back to back. That is what `colours` in `AvatarEditor.qml` already carries;
which slot a screen edits comes from this switch rather than from a name-based guess.

## The retail colour screens, named by the editor itself

The image carries the editor's localisation table, and it names the colour screens
outright. This is the mapping that was marked "inference" before; it is not inferred
any more:

| string in the image | slot |
| --- | --- |
| `Skin Color`, `Skin Color and Body` | skin |
| `Hair Color` | hair |
| `Lip Color` | lips |
| `Eye Color` | eye |
| `Eyebrow Color` | eyebrow |
| `Eye Shadow Color` | eye_shadow |
| `Eyeliner Color` | eyeliner |
| `Facial Hair Color` | facial_hair |
| `Facial Feature Color` | facial_feature |

Nine screens, and they line up with the nine slots the descriptor carries, in the same
order. The same table also gives the Italian and Spanish names (`Colore dei capelli`,
`Color de cejas`, ...), so the editor's strings can be localised from the game's own
text rather than retyped.

**The screens are a 16-swatch grid plus a bonus set.** The image names the controls:
`OptionColourButton`, `OptionColourSkinButton` (a second style for skin), the element
`Color0` … `Color15`, and `BonusColors` / `BonusColorsEnd`. Sixteen, then bonus. Every
extracted table fits that exactly:

| table | count | 16 + |
| --- | ---: | ---: |
| skin | 18 | 2 |
| eye | 18 | 2 |
| facial_feature | 26 | 10 |
| hair / lips / eyebrow / eye_shadow / eyeliner / facial_hair | 27 | 11 |

So a colour screen is a 4x4 grid of sixteen, followed by two to eleven bonus colours -
and the "short" tables found beside the full ones (skin 12, eye 15, lips 21) are what is
left once the bonus colours are removed. The swatch art is named in the same table:
`colour_palette_skin_selected.png` / `colour_palette_skin_unselected.png`.

### The palette art, found (2026-11-18)

Both files are in the image's second `XUIZ` zone and are now extracted to
`assets/_ui/xex/named/`:

| file | file offset | size |
| --- | --- | --- |
| `colour_palette_skin_selected.png` | `0x3E181E` | 128 x 128 |
| `colour_palette_skin_unselected.png` | `0x3E4405` | 128 x 128 |
| `option_colour_selected.png` | `0x5F00BE` | 128 x 128 |
| `option_colour_unselected.png` | `0x5F255B` | 128 x 128 |

**How the names were recovered.** The two `XUIZ` zones begin at `0x19AD80` (27 media
names) and `0x1E9C80` (424 media names), each a run of UTF-16LE `.png` names ahead of
the bitmaps. `editor_xui_media_names.json` holds all 451 name records (321 unique) with
their file offsets. The zones do not carry a decodable index, so a name is paired with a
stream by position; that pairing was checked against the art and holds for the start of
the list -- `Abutton.png` -> a 64x64 green A button, `arrow_downleft_selected.png` -> a
128x128 green arrow, `arrow_downleft_unselected.png` -> the same arrow in cream,
`body_access_selected.png` / `..._unselected.png` -> the same hand in green and grey,
`colour_palette_skin_selected.png` -> the green-framed chip grid. The counts differ
(27 names vs 12 streams in zone 1, 424 vs 280 in zone 2) because some names have no
embedded PNG, so positional pairing drifts where one is missing; the palette entries sit
at zone-2 indices 55 and 56 and pair correctly there.

**What the art is.** A 3 x 3 page of nine chips inside the frame, the chip box being
(22,22)-(106,104) of the 128 px sheet -- 28 x 27.33 px pitch. Selected and unselected
differ only in the frame colour (green vs grey-blue).

**The chips are placeholder art, not the palette.** Measured chip colours, upper-left to
lower-right, taking the most common pixel inside each chip:

| sheet | chips |
| --- | --- |
| `colour_palette_skin_selected` | `#e8dcdd` `#e5cab9` `#d4ad8e` / `#c69d71` `#af7d49` `#8c5d2e` / `#5c3c1a` `#3b240d` `#653923` |
| `option_colour_selected` | `#00bff3` `#5574b9` `#bc8cbf` / `#f26522` `#f7941d` `#fff200` / - - `#c69c6d` |

Those are design-tool constants (`00BFF3`, `F26522`, `F7941D`, `FFF200`, `C69C6D` are
the familiar web/Illustrator swatches), and each sits **18 to 284** away from the nearest
entry in the skin or eye-shadow table. They are not the game's palette.

**CORRECTION.** The earlier plan in this file -- map the extracted radial-gradient blobs
one by one onto palette entries and use them as swatch faces -- is dropped. The chips in
the shipped art are mock colours that no table entry matches, so there is nothing to map;
the 32 distinct blob colours are more stand-in art of the same kind. What the art *is*
good for is the frame, the disc and the chip geometry, which is how the editor's colour
panel now draws them (`AvatarEditor.qml`, `colourRow`): the green `..._selected.png` frame
with the chips painted from `Colours.qml`.

**Resolved: nine chips a page.** The open question here was whether the screen shows
nine chips (what the art draws) or sixteen (`Color0` … `Color15`). It is nine, and the
geometry is the evidence: the image ships exactly **four** palette sheets - a skin pair
and an option pair, selected and unselected - and every one of them draws a 3 x 3 page
in a box 84 x 82 px with a 28 x 27.33 px pitch. There is no 4 x 4 chip art anywhere in
the image's 294 extracted PNG streams, and a sixteen-chip screen would need one.

The seventeen names `Color0` … `Color15` plus `BonusColors` are therefore element names
from the image's string pool, not this screen's grid; the same pool also carries
`OptionColourButton` and `Grid1x1OneColourButton`, which belong to the item-colour
picker rather than the face screens. What the tables' sizes say about it is
inconclusive on their own - 18 is 2 x 9 *and* 16 + 2 - so the art settles it: the panel
pages nine at a time, and skin and eye (18 entries each) are exactly two pages, hair,
lips, brows, eye shadow, eyeliner and facial hair (27) exactly three.

Still unexplained, and recorded rather than guessed at: why the string pool holds
exactly sixteen `ColorN` names. "Bonus colours" has no art and no offset in the tables
that marks where the bonus block starts, so nothing in the editor treats them
specially.

### The colour-slot dispatcher, and the button templates (2026-11-18)

`FUN_9804d2f8` - the one unreadable function on the colour path - was recovered by hand
(see `DECOMPILE.md`), and its case 30/35 bodies led to `FUN_9804c8b4`, which is fully
readable and is the function that picks a layout for an id:

```
id = *(obj + 0x1c)                  ; 0 when the pointer is null
0x24 -> compare a 16-byte block against 0x98015b88, equal ? Grid1x1Button_deleteitem
                                                        : Grid1x1ItemButton
0x26 -> 0x29 <= obj->0xc <= 0x2a ? FUN_98056298(obj->0x10, FUN_98056680(...)) -> ARGB
                                   0 -> Grid1x1OneColourButton  else Grid1x1ItemButton
0x2b -> Grid1x1Button
0x2e -> string at 0x98001290 (empty)
else -> k = FUN_98055570(obj->0xc); k > 9 -> 0; otherwise a 10-entry byte table
```

The table is at **`98002968`, base `9804bd2c`, ten bytes**, guarded by `cmplwi r3, 9`
at `9804c8fc` - a *second, independent* ten-slot table beside `FUN_9807fee0`'s `i < 10`.
Two readers with a ten-entry bound is the strongest evidence so far that the descriptor
carries ten colours with `none` last, not sixteen.

**The layout templates.** A scan of the whole `.rdata` for UTF-16BE `Grid` returns seven
names (plus the bare word `Grid` at `98027e62`), all in one run:

| offset | name |
| --- | --- |
| `98002a34` | `Grid1x3Button` |
| `98002a50` | `Grid1x1Button_deleteitem` |
| `98002a84` | `Grid1x1OneColourButton` |
| `98002ab4` | `Grid1x1ItemButton` |
| `98002ad8` | `Grid1x1Button` |
| `98002af4` | `Grid3x2Button` |
| `98002b10` | `Grid3x1Button` |

**There is no `Grid3x3Button`.** That is a real tension with the nine-chip answer below and
it is recorded rather than smoothed over: the shipped palette sheets draw a 3 x 3 tray of
nine chips (pixel measurement, 28 x 27.33 px pitch in an 84 x 82 box), while the only
multi-cell *button* lattices this build names are 3 x 2, 3 x 1 and 1 x 3 - at most six cells.
The two are therefore not the same object. The entry counts still favour nine (18 = 2 x 9,
27 = 3 x 9, and 27 is not a multiple of six), so the nine-chip reading is unchanged; what
is now certain is that the sheet's tray is not one of these button templates, and which
lattice pages the palette is still open. `Grid1x1OneColourButton` is the one template
already tied to a single colour entry (the ARGB read above), so the palette is presumably
built from `Grid1x1OneColourButton` cells placed by a lattice that is not in the pool
under a `Grid` name.

### The mouth mask (18_mouth), and why there is only one

`18_mouth` is the one face slot with names but no textures. `PackIndex.qml` lists 26 of them
(`smirk-mouth.png`, `grin-mouth.png`, …) and the pack has none: `asset_catalog.json` holds
**zero** records with category `18_mouth`, because the mouth on the head is the descriptor's
own face - the third sheet of the three the head composites, alongside the brows and eyes.
So the mouth that can be tinted is the one this build actually draws,
`FACE_DEFAULT[2]` = **Smirk Mouth**.

`bake_pack_face.py` grew a `MOUTH_CATEGORY` branch for it: `COVER_ONLY = "layer2"` isolates
the mouth sheet, and since the catalog contributes no items for the category the default
mouth is added explicitly. One mask came out:

| file | size | painted pixels | box |
| --- | --- | ---: | --- |
| `pack_plates_mask/18_mouth/smirk-mouth.png` | 256 x 384 | 44 (alpha > 8) | x 118-136, y 96-99 |

That box is the mouth line on the head plate, below the eyes (y 71-80) and above the chin,
which is where the composite shows it. Mask count was **337** at that point; the skin
mask (one) and the eye masks (two per eye, below) take the total to **429**.

The editor wires it as `"18_mouth": "lips"` in `colourSlots`, and since the mouth is part of
the head rather than an item in the wardrobe, `rebuildLayers` pushes it as a fixed layer at
its own slot order - 18, above the eye shadow (17) and below facial hair (45) - instead of
walking it with the categories.

Checked on the real ship data (`UniKron/artifacts/lips_tint.png`): the mask composited over
`pack_plates/10_body/malebody.png` with the shader's linear-light maths
(`mask.rgb * tint`, alpha = coverage, over the plate) reproduces the mouth line in
lips[0] `#fd6a68`, lips[3] `#d00e0e`, lips[13] `#f5686b` and lips[25] `#8f2d5e`, in place.

**Limit, stated rather than hidden:** only this mouth can be tinted. Per-mouth lip colour
needs mouth textures the pack does not ship, and the 26 names in `PackIndex.qml` come from
the item list, not from assets.

### Skin: the replace rule, measured (10_body)

The open question in this file was whether the retail editor *multiplies* a skin tone
into the body texture or *replaces* it. It replaces it, and the measurement is direct.

`bake_pack_plates.py --categories 10_body --mask --include-base` renders the body and head
with a **white** albedo (coverage in alpha, light rig in RGB): a full silhouette, 20,179 px
of the 256 x 384 plate. `make_skin_mask.py` then takes the face out of it - the brows, eyes
and mouth sheets at their own masks, `skin = silhouette * (1 - feature coverage)` - leaving
19,623 px (97.2 %), which is body, head, hands and ears with the face left for its own
layers. That is `pack_plates_mask/10_body/skin.png`.

Compositing that mask over the shipped plate with the shader's maths
(`mask.rgb * tint`, alpha = coverage, linear light) gives one entry that reproduces the
plate and seventeen that do not:

| skin entry | mean abs diff | p95 |
| --- | ---: | ---: |
| **[1] `#d7aa71`** | **2.82** | **5.00** |
| [11] `#d7b971` | 5.98 | 13.07 |
| [10] `#e3a976` | 6.23 | 10.81 |
| [8] `#e6bc8e` | 17.02 | 25.76 |
| [12] `#f0b393` | 18.63 | 30.23 |
| [0] `#6e4124` | 76.06 | 95.28 |
| [6] `#40280e` | 100.06 | 131.44 |

Two things follow. The mask is the right one - a wrong mask could not land within 3/255 of
the plate for any colour. And the stock body is **skin index 1**, not 0, which is why the
editor's `colourDefaults` starts the skin slot at 1: with 0 the stock avatar would be drawn
dark brown the moment the skin layer exists.

The skin layer is pushed at `10_body` + 0.5, over the plate and under everything else; the
pixels the mask leaves out keep the plate's own face, and the brow, eye and mouth layers
repaint on top. `maskUrl` deliberately answers "" for `10_body` so the generic path does not
swap the plate for the silhouette.

Checked: `UniKron/artifacts/skin_tint.png` (six panels - no tint, skin[0], [1], [2], [9],
[17]) shows the shading holding and the eyes, brows and mouth unchanged in every tone.

### Eyes: the iris, split out of a sheet that also paints the whites (15_face)

The eye was the screen with no honest answer. One eye sheet paints the iris *and* the
sclera, and only the iris takes the eye colour - the whites are a fixed near-white
(`0.90, 0.90, 0.93` in `bake_turntable.render`, applied to the sheet's B zone, while
the slot-3 colour goes on its R zone). Multiplying the sheet's coverage mask by a
colour would paint the whites, so the eye screen stayed off rather than wrong.

**Where the iris is, measured.** `make_eye_masks.py` renders the same eye sheet three
times - eye colour white, pure red, pure green (descriptor slot 3), nothing else
touched - and takes the pixels that move between the red and the green render. On
"Happy Eyes" that is **88 pixels in the box x 114-143, y 72-81**: the two irises, and
not one pixel of the whites or of the lash line.

**What the iris looks like under a colour is two terms.** The renderer shades
`albedo * light` and adds a specular, and on this sheet the specular is a fifth to a
quarter of the pixel. A mask carrying only the lighting therefore reproduces the
shipped plate badly: mean **28.3**, p95 **73.2** out of 255 when the plate's own colour
is used, and a blue iris comes out grey. The three renders separate the terms exactly,
because a tint of (1,0,0) leaves only the specular in G and B and a tint of (0,1,0)
leaves only the specular in R:

    light = lin(white) - spec        spec = ( green.R, red.G, red.B )

With both terms the plate comes back to mean **5.9**, p95 **15.8** over the 51 iris
pixels, and of the eighteen eye colours the one that reproduces it best is **`#6381a7`
- the descriptor's own slot 3**, which is an independent confirmation of both the model
and the stock eye colour. That is why `colourDefaults` starts the eye slot at index 3
and not 0.

So an eye mask is two files, both straight RGB with the iris coverage in alpha:

| folder | 45 files each | contents |
| --- | --- | --- |
| `pack_plates_mask/15_face_iris/` | one per eye sheet | the lighting term |
| `pack_plates_mask/15_face_iris_spec/` | one per eye sheet | the specular term |

`TintedMask.qml` gained a `specSource` for it and writes
`pow(lin(light) * lin(tint) + lin(spec), 1/2.2) * alpha`. Every other mask leaves
`specSource` empty; the sampler is then transparent black, which adds zero, so their
result is unchanged.

The iris is drawn as its own layer at `15_face` + 0.5 **over** the eye plate, not
instead of it: the whites, the lashes and the stock iris are on the plate, and only the
iris changes. `maskUrl` deliberately answers "" for `15_face` so the generic path cannot
swap the plate for the iris.

Checked over the whole table (`UniKron/artifacts/eye_tint.png`: `#6381a7`, `#92b2ca`,
`#88b049`, `#ab0207`, `#212121`, `#82501d`) - the iris changes colour in every one and
the whites, lashes and skin do not move.

**Not verified on screen.** Qt Quick's software renderer has no GL surface here, so a
`ShaderEffect` layer draws nothing in an offscreen grab. The layer stack was read out of
the running editor instead (`15_face` plate at 15, `15_face_iris` at 15.5 with the
table's colour and its `_spec` URL), and the shader's maths was checked against the
plate in numpy. The GLSL itself has not been compiled in this workspace (`qsb` is not
in the PySide6 wheel, no GL context is available), so the first run on a real GPU is the
outstanding check.

### Eyeliner: a screen with nothing under it

"Eyeliner Color" is one of the nine screens and its table is the eye-shadow table
(measured: both slots point at `0x21a80`). There is no eyeliner asset in the pack and no
category for one, so the editor has nothing to apply it to.

The pack's 45 eye-shadow sheets reach the eye region on UV set 5, which is what is
baked. The head mesh has six UV sets, and a sweep of one sheet over all six shows set 3
landing on nearly the same box (x 114-144, y 71-77 against set 5's x 111-147, y 70-78),
set 2 above the eyes (y 61-69), set 1 below them (y 87-108) and set 4 on the mouth. Set
3 is a plausible eyeliner and set 5 the shadow, but the boxes are too close to tell a
liner from a wash and nothing in the pack names either; a guess here would be the kind
of invented data this file keeps out. The screen stays unpainted until something on the
disc says which zone is the liner.
