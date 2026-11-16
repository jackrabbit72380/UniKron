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
header 32 bytes in. That id is the one thing to chase: whatever table it names is
the same table the avatar descriptions use.
