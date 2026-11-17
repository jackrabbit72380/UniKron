# Every avatar folder in the archive

Inventory of what the shipped XBOX HUB actually contains for avatars, taken by
listing and opening the files rather than from memory. The point of writing it
down is that the earlier work only ever used two files out of it, and two of the
things listed here change what the decode has to do.

## What ships

Everything avatar-related lives under `src_archive/XBOX HUB/resources`. There is
one editor build per era, and the two asset sets are byte-identical.

| | metro2010 | nxe2008 |
|---|---|---|
| `assets/AvatarAssetPack.toc` | 13,648,884 B, 1,079 assets | same SHA-1 |
| `assets/AvatarAssetPackLegacyV1.toc` | 1,252,000 B, 44 assets | same SHA-1 |
| `assets/Avatar6400/6404/6411.Avatar` | 1,000 B each, saved manifests | same |
| `assets/*.AvatarAnimation` | 9 files: Cheer, Gift, IdleOffScreen, Look, RunIn, RunOut x4, Salute | same |
| `assets/avatareditor.xex` | 15,507,456 B | 15,826,944 B |
| `avatareditor.exe` | 17,567,232 B | 8,651,264 B |
| `assets/fonts/*.xtt` | XenonCLatin, XenonJKLatin | same |
| extra runtime | `bin/rexruntime.dll`, `bin/dxcompiler.dll`, `bin/dxil.dll` | `rexruntime.dll`, `rexgpu-xenos.dll` |

No further `.toc`, `.Avatar` or `.AvatarAnimation` exists anywhere else in the
archive: thirty files, all of the above. `resources/ogxbox/uix` is the original
Xbox file-system tool (theseus), not avatar content, and `resources/app` ships
only preview PNGs of the avatar games.

## The legacy pack is the base, not a second wardrobe

`AvatarAssetPackLegacyV1.toc` holds exactly 44 assets: `MaleBody`, `FemaleBody`,
`Head`, and all 41 clips - the same 41 animation names as the main pack, nothing
else. It is the minimum a saved avatar needs, which fits its name and the hub's
V1 loader.

It is *not* the same container as the main pack. Our `strb_blocks` reads the main
pack's STRB layout; pointed at the legacy file it fails, and the asset offsets in
`avatar-assets.json` describe the main pack only, so every lookup there was
reading the wrong bytes. Its own header states 44 at offset 0x18. Reading it
needs the V1 container format, not the V3 one.

## The executables carry names and source paths

`avatar-assets.json` was built from the pack alone. The recompiled editors were
never opened, and they are the closest thing to documentation this project has.
`strings` on `avatareditor.exe` yields a working map of the avatar system:

    rex::avatars::LoadAssetPackFromMemory
    rex::avatars::LoadAssetPackFromMemoryV1 / V2 / V3
    rex::avatars::Closet::InstallItem / Load / ReadItemBytes
    rex::kernel::xam::avatars::blend_shape_apply.cpp
    ?lzx_decompress@@YAHPEBX_KPEAX1I21@Z
    .?AV?$_Ref_count_obj2@VBlendShape@avatars@rex@@@std@@

and the messages that say what those do:

    Applied blend shape {} to asset {}.
    Failed to apply blend shape {} to asset {}!
    Failed to load avatar blend shape {}!
    Failed to load component blend shape {}!
    [avatar] failed to load embedded hiding shape {} for closet item {}
    [avatar] failed to load hiding shape {} for component {}
    [avatar] SetCustomAsset: no free component slot for {}
    [avatar] worn item {} is not in the closet, fetching it: {}

So there are three pack formats (V1/V2/V3), a closet of installed items, a
**blend shape** system that applies named shapes per component, and separate
"hiding" shapes that remove body under clothing - the last of which is the
mechanism behind the female hip gaps that have been sitting unexplained.

No COFF symbol table and no exports, but the strings give every function name and
the source file each came from, and `.pdata` gives every function's bounds, so a
named string plus a rip-relative xref lands inside the right function.
`re_pe.py` does that walk: find a string, find the instructions that load it,
disassemble around them.

## What block 4 is, as far as it has been measured

The 266 ShapeOverrides payloads are not one stream and not an LZX chain from
offset 0. Measured over all 266:

- every payload begins `u32 flags, u32 size, ...` where `size` is **divisible by
  12 in all 266 cases**, and takes exactly three values: 5,076 (36 blocks),
  13,584 (115) and 14,724 (115) - i.e. 423, 1,132 and 1,227 three-float records;
- the flags word is 0 in 46 blocks and small counts otherwise (518, 486, 470...);
- a 16-byte descriptor ending in the same eight bytes,
  `c1 c8 f1 09 a1 9c b2 e0`, appears twice in each payload;
- the compressed data starts at offset 64 with `02 44 ed 36` and the payload ends
  with `03 fc 00 00 00 00 00 00`.

That GUID is not incidental: the binary hard-codes it as a 64-bit `movabs`
immediately after reading a big-endian u32 (`bswap`), a big-endian u16 (`rol $8`)
and a byte that defaults to 3 - the same field order the payload shows. It is a
component descriptor, written by the same code that the pack was made with.

The payload is 3x to 128x smaller than its declared size, and the binary contains
an `lzx_decompress`, so the records are almost certainly LZX-compressed. No LZX
decoder is available in this environment (no `lzxd`, no `cabextract`, no network
to install one), so decoding block 4 means writing one or reading the loader's
exact expectations out of the disassembly first.

## Not in the archive

- `assets/closet` in either editor: the hub reads `closet_index.tsv` plus
  `<guid>.bin` items from the user's data folder, and ships none.
- any avatar game's `avatar/closet` folder. `features.js` looks for one, and the
  preview PNGs of dozens of avatar games are present, but the games themselves
  are not part of this archive.
- any save file with an edited face, which is what a before/after pair would need
  to settle the shape semantics empirically.

## What this changes

The decode work should not be "guess at block 4 from the bytes". The binary names
the system, the strings name the operations, and the field order of the component
descriptor is already visible in it. The order is: read the loader
(`LoadAssetPackFromMemoryV3`) and `blend_shape_apply`, get the record layout from
the instructions, then write the LZX decoder the payloads need. That is a decode
with a known target rather than a search.

## Block 4: what has been established, and where it stopped

Established by measurement, not assumption:

- all 266 payloads open `flags u32, size u32`; `size` is divisible by 12 in every
  one of the 266 and takes three values, 5,076 / 13,584 / 14,724 - i.e. 423,
  1,132 or 1,227 three-float records per shape;
- a 16-byte component descriptor ending in `c1 c8 f1 09 a1 9c b2 e0` appears in
  the payload and the same GUID is written by a `movabs` in the manifest parser;
- the data past byte 64 has 7.3-7.6 bits of entropy per byte, so it is compressed
  rather than stored (raw vertex data of this size would be far lower).

The `.Avatar` manifests are the useful discovery here. They are plain arrays of
16- and 32-byte records in the same shape: a type byte, an index, a constant
`0x0003`, the eight GUID bytes, then a value - and one of those values is
`3f 80 00 00`, a **big-endian** 1.0f. So the descriptor fields are big-endian and
the manifest is a list of component settings, which is what the parser
(`XamAvatarSetManifest`, 2,648 bytes at `0x140d5d380`) reads and the string
"buffer at {:#x} has a zero body component" belongs to.

Where it stopped: `lzx.py` implements LZX, but no payload decodes under any
framing tried - stream start anywhere in bytes 56-72, 16- and 32-bit words, both
bit orders, windows 15/16/21, with and without the leading block-type flag - and
none of the 4 x 2 x 2 x 2 x 120 combinations produces a 5,076-byte block header
either. Either the framing is XCompress-specific (the 4 bytes at offset 64,
`02 44 ed 36`, are not a standard LZX block header), or the decoder's tree
handling is wrong. With no reference LZX stream in the workspace, there is no way
to tell those apart by experiment, so the next step is the binary: the loader
(`LoadAssetPackFromMemoryV3`) and `rex::kernel::xam::avatars::blend_shape_apply`
is a 20,867-byte function at `0x140dd7e60` whose call graph and constants will
give the exact arguments the decompressor is called with.

`re_pe.py --function 0xADDR` resolves a function's exact bounds from `.pdata` and
disassembles it, which is how both of those sizes are known.

## Corrections, after reading the binaries

**The project already had an LZX decoder.** `lzx.py` was written in `70fb6dfd`,
ported from libmspack's `lzxd.c`, and every model and animation in the pack is
decoded through it (`avatar_mesh.decompress`, 32 KiB window, 8 KiB frames, 12-byte
`(compressed, out_offset, out_size)` headers). While working on block 4 I replaced
it with a fresh, unverified implementation and committed that, which broke model
decoding outright - `am.decompress` raised `bad window bits 32768` on every
model. It is restored byte-for-byte here; `MaleBody` decodes to 1,137 vertices
again and the audit passes.

That mistake is worth naming: I reported "there is no LZX decoder in this
environment" after checking pip, without checking the repository I was standing
in. The tool existed and worked.

**The legacy pack is the same container, not a different one.** `toc_parse.py`
reads `AvatarAssetPackLegacyV1.toc` without changes: 44 assets, offsets from
13,284, same STRB layout, same loader (both packs share the 16-byte magic at
`0x140f7b240`, which the version dispatcher at `0x140dbd940` sends to
`0x140dbcbe0`). The earlier "different container" note was wrong: the failure was
passing it the *main* pack's offsets, and the one asset that "parsed" parsed by
accident.

**Block 4 is still not decoded.** With the working decoder, no offset in the first
400 bytes of a payload decodes, and neither do zlib, raw deflate, lzma or bz2 -
while the data is definitely compressed (7.3-7.6 bits per byte). So the wrapper is
not the model framing and not a bare LZX stream: the payload interleaves
something before or between the compressed chunks, and the loader
(`0x140dbcbe0`, 1,470 bytes) is where that layout is written down.

## What the version dispatcher proves

`0x140dbd940` compares the pack's first 16 bytes against three constants
(`0x140f7b230`, `0x140f7b240`, `0x140f7b250`) and jumps to one of three loaders
(`0x140dbc530`, `0x140dbcbe0`, `0x140dbd290`), each 1,470 bytes. Both packs in
this archive match the middle constant. That is the V1/V2/V3 split: three pack
generations, one magic each - not three files in the folder.

## What the V2 loader and the applier prove

`0x140dbcbe0` is `rex::avatars::LoadAssetPackFromMemoryV2` - the strings it uses
name it, and give its source file as `kernel/xam/avatars/asset_pack.cpp`. It
validates the file header, then a table of **0xf8-byte asset headers**, then loads
each asset with a size check ("avatar asset pack V2: cannot load asset #{}, buffer
too small"). So the pack's index is richer than the name/offset pairs our
`avatar-assets.json` keeps: 248 bytes per asset, with room for block tables.

The blend-shape applier reads a component descriptor as

    mov (%rsi),%edx ; bswap          ; u32 big-endian  at +0
    movzwl 0x4(%rsi),%ecx ; rol $8   ; u16 big-endian  at +4
    movzwl 0x6(%rsi),%eax ; rol $8   ; u16 big-endian  at +6
    eight movzbl from 0x8(%rsi)      ; the 8 GUID bytes at +8

which is exactly the 16 bytes at offset 40 of every block-4 payload, and with the
guest's word order the values are 1, 2 and 3. So the payload opens:

    u32 flags = 0
    u32 declared size (5076 / 13584 / 14724, always a multiple of 12)
    descriptor: u32 1, u16 2, u16 3, GUID c1c8f109a19cb2e0
    ...a second descriptor near offset 40...
    u32 0, u32 16
    compressed blob from offset 64

Still open, and the only thing standing between us and the 266 face shapes: the
blob's codec. It is not LZX from any offset under the working decoder, not the
model framing (no `(compressed, out_offset, out_size)` header anywhere in the
payload), and not zlib, deflate, lzma or bz2.

The fastest way to close it now is not more disassembly: it is one retail save
whose face has been edited. The `.Avatar` manifests already store component
settings (with values like big-endian 1.0f), so a before/after pair would show
which component the shape drives and what a non-default value looks like, and
that pins the blob's meaning without having to trace 4,412 instructions.
