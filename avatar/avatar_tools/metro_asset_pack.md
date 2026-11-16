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
