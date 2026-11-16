# Where the avatar textures are (and are not)

Every archive and dump in this workspace, searched end to end for image payloads.
The short answer: **the face sheets exist — 187 of them, with pixels — and the
garment maps do not exist anywhere, because this pack's clothing carries no
texture slots at all.**

## Search coverage

| dump | what was done | result |
|---|---|---|
| `AvatarAssetPack.toc` (nxe2008 **and** metro2010, md5 `2b58915d809332b23ecff1669acdccee`, byte-identical) | every one of the 1,079 assets opened, every STRB block decompressed with LZX and scanned | **187 Texture blocks, all with pixels** |
| `AvatarAssetPackLegacyV1.toc` (44 assets) | same | no Texture blocks; Head still has its six empty slots; MaleBody zero |
| `Avatar6400/6404/6411.Avatar` (1,000 bytes each) | inspected | colour/description tables, no container, no image data |
| `*.AvatarAnimation` (41 clips) | same | no Texture blocks |
| model inline texture arrays | all 583 decodable models parsed | 7 slots in the whole pack, **0 non-empty** |
| `avatareditor.xex` (both builds), `avatareditor.exe` (both), rex DLLs | signature sweep (`XPR0`, `DDS `, `TXTR`, `XGXD`, `DXT1/5`) | no image payloads |
| `default.xex` / `default_uncompressed.xex` (gift dump) | sweep + LZX | no image payloads |
| `oscarui`, `ctrlpack`, `xplayrui` (XUIZ) | decompressed structure | uncompressed XUI banks; media is referenced **by name only** (`Legend_A.png`, …), nothing shipped |
| `resources.pak` (13.4 MB) | sweep | 0 hits for `.dds`, `.png`, `XPR0`, `DDS ` |
| OG Xbox UI (`theseus.exe`, `Q/Xips`, `Q/Skins`) | sweep | 187 XPR0 textures — real, but they are the **original Xbox dashboard**, not avatar art |
| `xex_pngs/` (285 extracted PNGs) | dimension census | 128×128 UI icons, 512×128 banners, 32×32, … — no 128×64 face sheets |
| gift `closet/*.bin` (Halo Spartan Armor, Baby Po) | YTGR parsed | Model with **0 slots**, colour table, animation — no textures |
| `/tmp/clip-Weight.bin` and other clip bins | sweep | animation only |

## The face sheets: they exist

Block id **2 is "Texture"** in the STRB block table, and 187 assets in the pack
carry one. Each decompresses to a 33-byte texture header plus DXT5 data:

* 161 are **128×64**, 26 are **128×128**, format `0x14` (DXT5), endian mode 1.
* All 187 have `flags & 1 == 0` and a full pixel payload — none is a placeholder.
* Names: 27 eyebrow sets, 45 eye shapes + `Eye shadow 001..00n`, 26 mouths,
  15 facial-hair items, and the rest lashes, facepaint, moles, wrinkles, scars
  and marks (`Freckles`, `Rosy Cheeks`, `Warrior Scar`, `Monobrow`, …).

Decoding `Straight Eyebrows` gives a clean 128×64 sheet — the red tint mask the
colour rule expects, shape on transparent. These are the sheets the 2D portrait
uses today; the theme currently paints only three of them (`Straight Eyebrows`,
`Happy Eyes`, `Smirk Mouth`).

## The binding slots: present but empty

The `Head` model declares **six** texture slots, and their dimensions are the
face-sheet dimensions:

| slot | size | format | empty |
|---|---|---|---|
| 0 | 128×128 | DXT5 | yes |
| 1 | 128×64 | DXT5 | yes |
| 2 | 64×64 | DXT5 | yes |
| 3 | 64×64 | DXT5 | yes |
| 4 | 64×64 | DXT5 | yes |
| 5 | 128×64 | DXT5 | yes |

That is the whole point of the split: the **texture payload lives in each face
feature's own asset** (block 2), and the head's slots are the bind points the
renderer fills per selection. Only one other model in the pack has a slot at all
— `Black Shutter Shades`, 32×32 DXT1, also empty. Across all 583 models there
are seven slots and none carries data.

## The garment maps: nowhere, by design

581 of 583 models have **zero texture slots**. No jacket, hoodie, jeans, shoe,
hat or glasses asset in either pack carries a Texture block, and neither do the
two imported closet items (the Halo Spartan armour included). Clothing in this
format is expressed as **colour**: a per-vertex colour field plus the type 7
colour table on the 39 sport tops.

So a garment map would have to be added in one of two places that this build
does not use:

1. a new block id 2 on the garment asset, bound to a slot the model would also
   have to declare (it declares none), or
2. a filled inline slot in the garment's Model block (there are none).

There is no external texture directory, no sidecar `.dds`/`.xpr`/`.png`, and no
download cache in any dump: the PC port's `/avatar-body.png` string is an
**XStorage upload endpoint** (`avatar-body.png upload accepted and discarded`),
not a file it reads.

Conclusion: the theme's garment colours are not a stand-in for missing maps —
they are the same mechanism the source uses.

## The retail closet confirms it: 1,454 items, no textures

A full retail closet dump (`Clean Slate NXE`, dashboard 2.0.9199) carries
**20,349 item assets** under `assets/closet/`, each a `YTGR` wrapper around a
`STRB` container - the format `avatar_mesh.strb_blocks()` already reads, with
zero parse failures across every item sampled.

Block ids across a 1,454-item sample:

| id | items | size | what it is |
| --- | ---: | --- | --- |
| 3 | 1,454 | 17.7-48.4 KB | the mesh |
| 4 | 1,274 | 0.7-3.4 KB | per-item extras |
| 7 | 1,171 | 28-109 B | the colour table |
| 8 | 1,454 | 15 B | header/footer |
| 1 | 188 | 95-163 KB | animation (a float 15.0 duration sits at +4) |
| 5 | 188 | 144-276 B | animation header |

**No id 2 anywhere, and not one block of 8/16/32/64 KiB** - the sizes a DXT5
sheet would take. So the retail item set carries no garment maps either: what a
garment looks like is geometry plus the colour table, exactly as in the editor's
own pack. The theme's vertex-colour clothing is not a substitute for missing
art; it is the mechanism.
