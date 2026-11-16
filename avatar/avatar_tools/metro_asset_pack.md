# The retail avatar asset pack (from Clean Slate Metro)

`Clean Slate Metro.zip` (MVEALNG's Metro v0.05 beta) ships two files from the
console's own avatar system:

- `gamedir/AvatarAssetPack.toc` - 14,662,168 bytes
- `gamedir/AvatarAssetPackLegacyV1.toc` - 1,252,000 bytes

Both start with a 20-byte SHA-1 digest, then big-endian header words - Xbox 360
byte order, not the little-endian layout every NXE file uses. This is the
2010-era retail pack (Metro 2.0.17559), i.e. the pack the marketplace garments
belong to, not the 2008 editor pack.

`avatar_asset_names.txt` holds every name that is readable in it: **7,527
distinct strings**.

## What the pack contains by name

The first entries are the pack's own assets:

```
MaleBody
FemaleBody
Head
```

Then **41 animations**, whose names are the real ones - not the 16 ids the
editor DLL passes around:

- `Animation Generic Stand 0` .. `Stand 7`
- `Animation Generic Clap`, `Wave`, `Celebration`
- `Animation Female Idle Check Nails`, `Idle Looks Around`,
  `Idle Shifts Weight`, `Idle Fixes Shoe`
- `Animation Female Angry`, `Confused`, `Laugh`, `Sad Cry`,
  `Shocked Surprised`, `Yawn`
- the same six for `Male`, plus `Male Idle Looks Around`, `Idle Stretch`,
  `Idle Shifts Weight`, `Idle Checks Hand`
- `Animation Creator Look Down`, `Look Left`, `Look Neutral`, `Look Right`,
  `Look Up`, and the four diagonals `Look Down Left`, `Look Down Right`,
  `Look Up Left`, `Look Up Right` - the editor's nine look poses
- `Animation Closet Sleep`

Everything else is item names, and they come **in groups of about nine, one per
language, for the same item**:

```
Moccasins, Mokkasins, Mocassins, Mocasines, Mocassini, Mocassim, Mokasyny,
Mockasiner, Makosenler
Formal Shoes, Black Formal Shoes, Czarne pantofle, zowe pantofle, ...
```

Counting distinct keyword families: Shirt 173, Ring 165, Top 152, Hat 128,
Cap 59, Earring 50, Jacket 46, Pants 38, Dress 38, Gloves 34, Hoodie 29,
Skirt 26, Sweater 20, Glasses 20, Shoes 10, Watch 7, Costume 5. Divided by the
nine-locale grouping that is roughly 800-900 distinct items, and the groups
run in a stable order (shoes first), which is a pack order, not the editor's
category order.

## What is confirmed about the layout

- Header: 20-byte digest, then `00 00 00 02` (version), `00 00 05 02`,
  `00 00 00 02`, `00 00 00 00`, `00 00 00 12` (**18** - the locale count),
  `00 00 00 00`, `00 00 00 02`, `02 01 01 00`.
- The name pool starts at `0x53e49` and holds the names as UTF-16LE, each
  terminated by `00 00`. Offsets stored in the header point one byte before a
  name, so a stored offset `o` means the string begins at `o + 1`.
- The first asset's record repeats its name offset **18 times** - one slot per
  language, all identical for `MaleBody`, which is spelled the same everywhere.
- After the header the region `0xec`-`0x53e48` is mostly zeros with occasional
  runs of 18 repeated offsets; the run at `0x51c` (`0x53eae`) is the next
  asset.
- The 13.4 MB from `0x12fa42` to the end is **not** plain records: every
  stride from 4 to 260 was tested and none lines up, the bytes are
  high-entropy, and repeated sequences (`94 46 be 6c 5f`, `3c ae ff c4 fe`,
  `5e 00 4c 00 58 b1`) look like LZX match copies. It is compressed content,
  but it is **not** the 12-byte-headered block chain that the NXE closet uses -
  a probe at that offset with that header format found nothing.

## What this does and does not give

Gives: the retail pack's real asset names, the full animation list with names,
the body asset names (`MaleBody`, `FemaleBody`, `Head`) and the fact that
localized item names exist for every item.

Does not give, yet: the meshes and textures. `MaleBody` is a name, not a mesh;
the bytes that would be the body are inside the compressed 13.4 MB block whose
record format is not decoded. Neither file contains any texture artwork or
colour values in readable form.

The 2008 editor pack (`AvatarAssetPack.toc` in the NXE dump, 1,079 assets) is a
different, older pack; this one is the 2010+ retail set.

## The signed package (`AvatarAssetPack`, 13,799,424 bytes)

A second copy arrived as `AvatarAssetPack.zip` containing one file,
`AvatarAssetPack`, 13,799,424 bytes. It is not the toc: it starts with `PIRS`
and holds the toc **inside** it.

- `0x0000` `PIRS` - the Microsoft-signed XContent magic.
- `0x32c` a 20-byte SHA-1, then the header block; `0x360` carries the title ID
  `0xFFFE07DF` - the avatar content family, the same `FFFE07DF...` id that
  appears as a Metro gamedir file.
- `0xc000` the STFS file table. Entry 0: name `AvatarAssetPack.toc`, and the
  length field reads **135,069,697** bytes, which is 2,061 x 0x10000. The
  package on disk is 13.8 MB, so the toc inside is block-compressed roughly
  10:1.
- `0x5aa19` the same name pool as before - `MaleBody`, `FemaleBody`, `Head`,
  `Animation Generic Stand 0` and on - visible in the clear because those
  blocks are stored uncompressed.

So the retail payload is real and it is large: the 135 MB toc is the full pack,
not the 14.6 MB index that Metro ships. What is still missing is the STFS block
table - which blocks are LZX and where each one starts - so the 135 MB can be
rebuilt. The block bytes themselves are in this package; nothing else needs to
be found.

Two things would finish it: the extracted 135 MB `AvatarAssetPack.toc` (any tool
that unpacks STFS content can produce it), or the block table layout for this
package so it can be rebuilt here.

## The toc decompresses (13,661,900-byte copy)

The extracted `AvatarAssetPack.toc` arrived as 13,661,900 bytes - not 135 MB, so
the 135,069,697 in the package was a field I mis-read, not a length. Its header
starts `8a 76 2d f4 ... 00 00 00 02 00 00 05 02` and its name pool is at
`0x4da19`.

The 12.5 MB after the names is **LZX, in the same 12-byte-headered chunks the
NXE closet uses** - `u32 compressed, u32 output_offset, u32 output_size` - with
0x8000 output per chunk and a 0x8000 window. 423 chunks, every one of which
decompresses cleanly:

```
python3 pack_toc.py AvatarAssetPack.toc        # 327 assets out
```

327 assets, 162 of which parse straight through `avatar_mesh.read_model` into
vertices, indices, UVs, joints, weights and colours - real retail meshes, e.g.
block 0 is 884 vertices, 1,764 indices, 7 materials, spanning y 0.000-0.094
(a shoe, and the pack's name list starts with Moccasins and Formal Shoes). The
tallest single-chunk asset spans y 1.107-1.360, a hat.

The other 165 assets fail with `bit overrun at 262144`, i.e. they need 256 KB -
eight chunks - and one chunk each is all the grouping below gives them.

## The record table

Just after the header at `0xe4` the toc holds **930 records of 0xf8 bytes**, one
per asset, in asset order. `pack_records.tsv` is the dump.

Each record:

- `+0x00..+0x37` - **14 big-endian u32 name offsets**, one per language. The
offset points one byte before the string, so `0x4da18` is `MaleBody` at
  `0x4da19`. Locales that spell the name the same way share an offset.
- `+0x38` - the asset's data size (`MaleBody` 33,084; `FemaleBody` 38,560;
  `Head` 18,628).
- `+0x3c`, `+0x40` - two flag words (`0x00400000` on every animation,
  `0x01000000` on short accessory entries, `0x02020100` / `0x03031100` and
  similar elsewhere).

The order is the pack's own: `MaleBody`, `FemaleBody`, `Head`, then the 41
animations by name, then clothing - the last record is
`Female Right Feather Earring`.

## The mapping, resolved

Nothing was missing from the toc: the record for each asset points straight at
its data, and no chunk scanning is needed at all.

A record is 0xF8 bytes. The field at **+0x34** is the absolute offset of the
asset's `STRB` blob and the field at **+0x38** is its exact size, so the blobs
can be read one by one. Each blob is a `STRB` container (`avatar_mesh.strb_blocks`)
holding `AssetMetadataVersioned` (block 8) plus, per asset class, `Model` (3),
`CustomColorTable` (7), `ShapeOverrides` (4), `Texture` (2) or `Animation` (1).

Two earlier detours came from losing sight of this:

- Blind-scanning the file for 12-byte chunk headers and grouping "a new asset
  starts at every output offset 0" rebuilt 767 groups, none of which was a
  body, because the boundary between one asset's chunks and the next is not
  marked in the data - only the record table knows it.
- The committed `avatar-assets.json` was stale: its sizes were 4 bytes larger
  than the records', so its offsets drifted by 4 bytes per asset. Only the first
  asset (`MaleBody`) still opened, which is why every other name "failed" with
  "not a STRB container". Regenerating it with `toc_parse.py` fixes the drift.

With the manifest regenerated, `asset_catalog.py` decodes **585 models out of
1,079 assets with zero failures**:

| asset | vertices | triangles |
| --- | --- | --- |
| `MaleBody` | 1,137 | 2,264 |
| `FemaleBody` | 1,232 | 2,454 |
| `Head` | 648 | 846 |

The other 494 assets are the 41 animations plus items with no geometry block.
`avatar_mesh.py --pack AvatarAssetPack.toc --asset MaleBody --obj body.obj`
writes any of them out as OBJ.

Still true, and not a mapping problem: **textures are empty in every decoded
model** (`with_pixels: 0` across all 585), same as the NXE closet. Item colours
are a separate block - see `COLOURS.md`.
