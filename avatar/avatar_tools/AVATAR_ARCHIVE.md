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

## Block 4: every framing tried, so none is repeated

A shape asset is small: block 8 (15 bytes of metadata) and block 4, nothing else.
A model has block 3 instead, whose payload *is* a chain of `(compressed,
out_offset, out_size)` headers - `Head` declares `comp 18502, out 0, size 28581`
at its first 12 bytes. Block 4 has no such header anywhere in it: the only place
the declared size appears is offset 4.

Tried, and failed, on the working decoder:

| what | result |
|---|---|
| LZX at offsets 0, 24, 32, 40, 56, 64, 68, 72 | bad block type / bad pretree / out of input |
| LZX at **every** offset 0..1605, both 16-bit word orders | no success; deepest failures reach "out of input bytes", i.e. it consumes the whole payload and produces nothing |
| window 4K, 8K, 16K, 32K, 64K, 128K | no success |
| a `(comp, out_off, out_size)` chain at every offset | no header carries the declared size except the field at +4 |
| zlib, raw deflate, lzma, bz2 from every offset 0..200 | no match |

So the payload is LZX-family compressed but is not a bare stream and does not use
the model frame wrapper. The remaining places the wrapper can be described are
`LoadAssetPackFromMemoryV2`'s per-asset load path (it already owns the buffer the
asset is loaded into) and the guest `.xex`. Both are code reading, not byte
guessing - which is why the byte guessing stopped here.

## What `LoadAssetPackFromMemoryV2` actually does (0x140dbcbe0)

Read from the disassembly, not inferred. It is 1,470 bytes and starts with a
version gate, then copies every record into a runtime entry.

    +0x40 of the pack object      version;  > 4 is rejected outright
    version >= 5                  a further check on the object at +0x88, and
                                  the load fails if it returns false
    +0x1c (big-endian)            record count, 1282 in this pack
    +0x28, stride 0xf8            the records themselves

Per record it builds a 216-byte (0xd8) entry and memcpys 0xd8 of it:

    +0x00  u32   id, big-endian                   (1 Head, 2 MaleBody, 0x2000
                                                   Happy Eyes, 0x100000 Large Chin)
    +0x04  u8 x3 kind
    +0x07  0x91  a 145-byte field, copied verbatim
    +0x98  u32   another id, big-endian           (20001, 10004 ...)
    +0x9c  16    component record, verbatim
    +0xac  16    a second one, all zero in this pack
    +0xbc  13 x u32   language name pointers      (read here as +0x04 from a
                                                   base 0xb8 further on)
    +0xf0  u32   blob offset, big-endian
    +0xf4  u32   blob size, big-endian

`toc_parse.py` was reading the same bytes all along - its anchor of 0xe0 is
0x28 + 0xb8 - so nothing it produced needed correcting. It now also exposes `id`,
`kind`, `detail` (+0x98), `component` (+0x9c) and `component2` (+0xac).

Two things this settles:

* **1,079 of the 1,282 records point at an `STRB` blob** - exactly the asset count
  the audit sees. The other 203 have no blob at all: they are the alias/alias-only
  entries, which is why nothing was ever missing.
* **678 of the 1,079 carry an all-zero component record**, and the 401 that do not
  carry 361 distinct 16-byte values, every one ending in `c1c8f109a19cb2e0`.

## The component record is a type tag the blend-shape code tests

`{ u32, u16, u16, 8-byte GUID }`, stored **verbatim** while every other integer
field in the pack is big-endian. That GUID is not decoration:

    movabs $0xe0b29ca109f1c8c1,%rax     # the GUID, at 0x140dd7ebd
    mov    %rax,0x2c8(%rbp)
    cmpl   $0x02000000,0x120(%rcx)      # u32 of the descriptor
    movzwl 0x124(%rcx),%eax             # u16, must be 0
    movzwl 0x126(%rcx),%r9d             # u16, must be 0x100
    mov    0x128(%rcx),%rax             # the 8 GUID bytes
    cmp    0x2c8(%rbp),%rax
    sete   %sil

So `0x140dd7e60` - the function I already had as the blend-shape applier - takes an
object whose `+0x120` block is one of these records, and wants exactly
`(0x02000000, 0, 0x100, that GUID)`.

Large Chin, though, has an **all-zero** component record and `detail` 10004, so a
shape asset's block-4 descriptors do not come from its own record. That rules out
the shortcut I was hoping for: the descriptor is built by whatever parses the blob,
which is one level deeper.

## Why no decompressor call is visible in the pack loader

The per-asset load at `0x140e2b2f0` is a single instruction:

    call *0x10(%rax)

One virtual call, slot 2. The decoding is polymorphic - which is consistent with
`VBlendShape` being a class - so there is no direct `lzx_decompress` call to find
from the pack loader. Any further progress on block 4 has to come from the concrete
class behind that vtable, or from your save pair.

## The 16-byte descriptor is a GUID, and the GUID is the key

`0x140dc7000` settles what the block-4 header fields are. It reads a 16-byte
descriptor the same way I recorded earlier (bswap the u32, `rol $8` the two u16s,
then eight single bytes), formats it, and hashes the result:

    lea    0x1d2396(%rip),%rax        # 0x140f9945f, the format
    movq   $0x46,0x90(%rbp)           # 70 characters
    call   0x140e496b0                # format it
    movabs $0x100000001b3,%rcx        # FNV-1a prime
    movabs $0xcbf29ce484222325,%r8    # FNV-1a offset basis
    ...
    and    0x78(%rsi),%r8             # mask by the table size -> bucket

and the format at `0x140f9945f` is

    {:08x}-{:04x}-{:04x}-{:02x}{:02x}-{:02x}{:02x}{:02x}{:02x}{:02x}{:02x}

That is a GUID string. So the 16 bytes are a Windows `GUID` - `{u32, u16, u16,
u8[6]}` - with its words stored **big-endian**, which is why reading one needs a
bswap plus two `rol $8`. It is not a size or an offset, and the pack is not
describing geometry with it: it is naming a type.

Everything lines up with what was measured before:

* the record's component field and block 4's own header fields are the same kind of
  value, and every one of them ends in the same 8 bytes - `c1c8f109a19cb2e0` - so
  that tail is the family marker, not the identity;
* `0x140dc7000` and `0x140dd7e60` both `movabs $0xe0b29ca109f1c8c1` and compare it
  against descriptor `+0x8`, i.e. they test membership of that family rather than a
  specific type;
* the identity is the leading `u32, u16, u16`. Large Chin's block 4 carries
  `01000000, 0200, 0300` under those rules; the 361 distinct record components are
  361 distinct leading triples in the same family.

So block 4's header is a GUID-keyed component record followed by its payload. The
payload's framing is still the open question, and the save pair is still the fastest
way to pin it.

## Correction: block 4 is not entropy-coded

I recorded earlier that the block-4 payload must be compressed because its entropy
is 7.3-7.6 bits/byte. That inference was wrong, and the measurement that refutes it
is simple: encode two *different* shapes and see how much survives.

Large Chin and Rounded Chin both declare 5076 and are both 1613 bytes. From 0x40 on
they share **296 of 1549 bytes (19%)**, including a 21-byte identical run:

    00 00 fc 03 00 00 00 00 4c 00 00 00 00 00 00 00 e0 e3 e3 ff 4f 00 00 00 10 15

Two independently compressed streams cannot share that. The payload is structured
data with long identical regions, and the high entropy is in the bit-packed parts of
it, not in the whole block.

It is not a float array either, which was the other easy guess: scanning every
4-byte window from 0x44 as a little-endian float finds only 3 plausible values in a
row before the pattern breaks, and over the whole payload only 56-59% of words parse
as finite floats with |v| < 10 - which is chance, not a format.

So the open question is narrower than before but still open: **the payload is a
packed encoding of 5076 bytes' worth of something - 423 records at 12 bytes -
stored in 1613**, and the 3.15x is bit-width packing rather than compression. The
families make this concrete:

| declared | /12 | items | what they are |
|---|---|---|---|
| 5076 | 423 | 36 | chins, noses, ears |
| 13584 | 1132 | 115 | smaller hiding templates |
| 14724 | 1227 | 115 | larger hiding templates |

The 5076 family's header is 0x40 bytes and 36 items share its first 32; the hiding
templates' header is 0x20 and none of them share a prefix because the count is in
it. Both headers end just before the packed region.

What I did **not** find: the loop that unpacks it. The per-asset load is a virtual
call (`call *0x10(%rax)` at 0x140e2b2f0), so the parser is behind a vtable rather
than reachable from the pack loader by following calls.

## The blend-shape pipeline, located end to end

Every blend-shape message in the binary - "Failed to load avatar blend shape {}!",
"Failed to load component blend shape {}!", "Failed to apply blend shape {} to
asset {}!", "failed to load hiding shape {} for component {}" - resolves to the
*same* function, `0x140dd7e60`. I had read that function once and concluded it held
"only logging and distance maths". That was wrong: it is the whole pipeline, and its
size (20,867 bytes) is why the first read missed the parts that matter.

The loop at `0x140dd8200`:

    inc    %r13
    cmp    $0x3,%r13                     ; three component slots, then done
    jae    0x140dd85aa
    shl    $0x4,%rax                     ; each record is 16 bytes
    cmpl   $0x0,(%rsi,%rax,1)            ; u32 == 0  \
    cmpw   $0x0,0x4(...)                 ; u16 == 0   > empty record: skip it
    cmpw   $0x0,0x6(...)                 ; u16 == 0  /
    mov    0x8(%r14),%rax
    cmp    0x2c8(%rbp),%rax              ; GUID tail == c1c8f109a19cb2e0 else
                                         ;   it is not our family, fall through
    call   0x140ddea10

and the call it makes is a 204-byte wrapper:

    0x140ddea10  calls 0x140ddeb30 (fills two out-params) then 0x140dbec50
    0x140ddeb30  the loader: 1,460 bytes, resolves the item and yields
                 a pointer and a size; calls 0x140dc9d80, 0x140dc1ba0,
                 0x140dcde50, 0x140dbde80, 0x140d29df0
    0x140dbec50  the apply step: 90 bytes, a thunk

So the shape data is decoded **between** `0x140ddeb30` and `0x140dbec50`. That is
where the packed payload of the previous section has to be unpacked, and it is a much
smaller place to search than the 20,867-byte function I had been reading.

What I did not manage this round: the unpacker itself. Of the candidates,
`0x140dc9d80` is the only one with byte-at-a-time reads (21 `movzbl`), but none of
them contains a bit-unpacking loop, and two of the callees (`0x140dbde80`,
`0x140dc1ba0`) have no `.pdata` entry at all, so their bounds are not available yet
and they have not been read.

Side finding while looking: the two functions that compare the `STRB` magic
(`0x140dea1a0`, `0x140dea540`) are size calculators, not parsers. They read the
header's flag byte at `+4` and the byte counts at `+0x16`, `+0x17`, `+0x1a`, then
round `a + 2b + c` up to an alignment. Those are the fields `strb_blocks()` already
relies on, which is a useful independent confirmation of the container header.

## Block 4 decoded: it is a bitstream, and here is the reader

This is the answer the whole investigation was for, and it came from following the
vtable rather than from more guesses about bytes.

`0x140dbe460` is a variable-width **bit reader** - the only unpacking code in the
binary:

    mov 0x8(%rcx),%rsi          ; position, held in BITS
    mov (%r8),%rdi              ; buffer
  loop:
    r11 = pos & 7               ; bit offset in the current byte
    r10 = min(8 - r11, left)    ; bits this byte can still give
    ebp = ~(-1 << r10)          ; mask
    part = (data[pos >> 3] >> r11) & ebp
    value |= part << got        ; assembled low bits first
    got += r10; pos += r10; left -= r10
  ; then the stream position advances by the number of bits consumed

Its two callers give the format:

**`0x140dbe690` - a component record**: 32 bits, 16, 16, then eight single bytes,
with `bswap` on the 32 and `rol $8` on each 16. Since every field is byte aligned,
that lands on exactly the same bytes as the unpacked record. Decoding Large Chin,
Soft Nose, Elven Ears and Thin Chin from offset 0x40 returns
`01000000-0200-0300` and the family GUID every time - which is the check that pins
the bit order. It is `bitstream.py` in this directory.

**`0x140dbee70` - a quantised value**:

    v     = base (+0x04 of a parameter block) + read_bits(width at +0x08)
    then three more reads, at widths (+0x28), (+0x29), (+0x2a)
    float = offset (+0x10 / +0x18 / +0x14) + scale (+0x1c / +0x20 / +0x24) * v
    and one read is signed: `and $1`, and when set it adds a constant to flip it

So block 4 is quantised floats: per-field bit widths with per-field scale and
offset, plus a zig-zag sign bit. That is why 5076 bytes of data fit in 1613: the
values are 9-16 bit integers, not 32-bit floats. The 3.15x ratio is the quantisation,
exactly as the shared 21-byte runs suggested and as compression never could.

What is still open is only the parameter block: `+0x04` (base), `+0x08` (bit
width), `+0x10`-`+0x24` (scales and offsets) and `+0x28`-`+0x2a` (three more
widths). Something fills it from the block-4 header before the values are read,
and that function is the last piece. The header fields already measured are the
candidates: the per-item count at `+0x20` (110, 78, 46) and the small values at
`+0x3c` (16, 15, 16) look exactly like a value count and a bit width.

### Correction, then the parameter block

The check above returns bit position 64, **which is byte 8**, not offset 0x40: bit
positions throughout this reader are bit-granular. Byte 8 of the block-4 payload is
where the first component record sits (`01000000-0200-0300` + family GUID), so the
bit order is still confirmed - the annotation was off by a factor of eight, the code
was not.

With that fixed, the last piece, `0x140dbecb0`, fills the parameter block from the
same bitstream, all 32-bit fields except three 6-bit widths:

    +0x04  u32   base                  (read 1)
    +0x08  u32   bit width             (read 2)
    +0x0c  u32   b                      (read 3) - the quantisation step
    +0x10  u32   offset 0               (read 4, used as a float)
    +0x14  u32   offset 1               (read 5)
    +0x18  u32   offset 2               (read 6)
    +0x1c  f32   scale 0 = b * 2                (read 7..9 are six bits each)
    +0x20  f32   scale 1 = b * 1.632993  (= 2 * sqrt(2/3))
    +0x24  f32   scale 2 = b * 1.732051  (= sqrt(3))
    +0x28  u8    width 1, +0x29 width 2, +0x2a width 3   (six bits each)
    +0x2c  u64   a second base/width pair

and `0x140dbee70` then decodes one entry per call:

    out[0] = base + read_bits(width)                 ; an integer, the vertex index
    f0 = offset0 + scale0 * read_bits(width1)
    f1 = offset1 + scale1 * read_bits(width2)
    f2 = offset2 + scale2 * read_bits(width3)  +  (read & 1 ? 0.3333333 * scale2 : 0)

so an entry is **a vertex index and three quantised deltas** - a blend-shape
displacement, 32 bytes once padded, which is exactly what the applier wanted and
what the shared 21-byte runs implied.

`0x140dbe760` is the reader that drives it: two 32-bit fields, then a 16-byte
component record, then the parameter block, then a loop emitting those 32-byte
entries. What is **not** yet pinned is where that loop's bound comes from: reading
the payload from bit 0 gives 0 and 5076 for those first two fields, so the caller
clearly positions the stream past the block header, and the bound is probably the
per-item count already measured in the header (`+0x20`: 110, 78, 46). That is the
next thing to check, and it is a two-line change to the decoder rather than a new
investigation.

## The block-4 decoder, and what it does and does not prove

`decode_shape.py` now parses block 4 the way the binary does: two sequential
sections off one bitstream, both reading `count, u32, 16-byte record, base, width`.

* **Section A** (`0x140dbe520`) emits `count` u32s, each `base + read(width)`.
  Geometry overrides have count 0. Hiding templates do not: 330/258/364 entries at
  12 bits each, and their descriptor reads `02000000-0100-0200` instead of the
  geometry form `01000000-0200-0300`.
* **Section B** (`0x140dbe760`) emits `count` entries on a 32-byte stride: a u32,
  three quantised floats, then four more u32. Geometry: 110 entries for Large Chin
  (16-bit first field, 14-bit floats), 46 for Elven Ears, 78 for Soft Nose.

The strongest evidence so far: on Large Chin the parse starts its entries at bit
914 and **finishes exactly on bit 12904 of 12904**. Soft Nose lands on 8948 of 8952,
the three hiding templates on 7976/7966/6472 of 7976/7968/6472. The field set is
therefore complete - nothing is being skipped.

What the values say, and what they do not:

* The three "offset" floats are per-shape and land in the right place: chin
  (-0.109, 1.120, -0.012), nose (-0.025, 1.212, 0.130), ears (-0.146, 1.218,
  -0.065), and for clothing (-0.256, 0.036, -0.062) at the torso instead. They
  really are the affected region.
* `b` is 7.071e-06 = sqrt(0.5)*1e-5 on **every** item checked, geometry and
  clothing alike, so it is a fixed quantisation constant and not per-shape data.
  With it, a 14-bit value spans about 0.23 m, which is a sane chin displacement.
* The first field of an entry is not yet a vertex index: base 0 and width 16 give
  values up to 64k against a 648-vertex Head. Either it is masked downstream or it
  is not a mesh index.
* The four trailing base/width pairs decode to nonsense on every item (base 78
  million, two zero widths, a base near 2^32). Their widths happen to sum so the
  payload is consumed exactly, but Angled Nose exposes the flaw: it has no entries,
  so the parameter block alone must be 920 bits, and this parse stops 6 bits short
  at 914. There is at least one more 6-bit field in the parameter block, and the
  tail is not understood yet.

So: section layout, descriptor, entry stride and region offsets are established;
the entry's first field and the 51 trailing bits are not. No bake should claim
shape overrides until those two are settled.

### Correction: the spare bits are padding

The last section claimed Angled Nose proved a missing 6-bit field in the parameter
block. It does not. Decoding all 258 block-4 items gives this distribution of
unconsumed bits:

    spare 0-7 bits: 254 items      spare 10 bits: 4 items

0-7 spare bits is byte padding - 914 bits of content in a 115-byte block is the
clearest case, and Large Chin lands on 12904 of 12904 with none at all. So the
parameter block is complete as parsed, and the "one more 6-bit field" was an
inference from a single item that the whole pack contradicts.

The four ten-bit outliers (Formal Shoes, Hiking Shoes, Rainbow Gloves and one more)
are the only items where the parse is more than a byte out, and they are worth a
look later, but they are 4 items in 258 rather than a structural fault.

What remains genuinely unread is only the meaning of the four trailing base/width
pairs inside each entry: 51 bits for Large Chin. Their lengths are right - that is
what makes the payload totals come out - but the values they produce are not
believable, so they are lengths that fit rather than fields that are understood.

## Block 4 is solved: the first field is a byte offset, and the shape works

The last open question was the entry's first field: 16 bits with base 0 gave values
up to 64k against a 648-vertex Head, so it could not be a vertex index. It is not.
It is a **byte offset**, and dividing by the vertex stride recovers the vertex.

The path to it was geometric rather than disassembly. Decoding Large Chin's 110
entries and comparing each entry's three floats against the real Head mesh put
every position within millimetres of *some* vertex, so the floats are positions.
Then the offsets 17732, 17784, 17888, 18044 ... differ by 52, 104, 156, by 52 and
its multiples, and 17732 = 52 x 341 while the vertex nearest that position is
vertex 341. 52 is the Head vertex stride: 32-byte base plus five 4-byte UV sets.

Checked across five shapes, 434 entries in total:

    shape          entries  all multiples of 52  vertex range   dist to that vertex
    Large Chin       110    yes                   17..641        mean 14.2 mm, max 43.0
    Soft Nose         78    yes                    0..574        mean  3.9 mm, max  7.5
    Elven Ears        46    yes                  296..647        mean  7.7 mm, max 12.9
    Thin Chin         90    yes                   72..641        mean  4.9 mm, max 14.2
    Rounded Chin     110    yes                   17..641        mean  6.2 mm, max 12.2

Every value is an exact multiple of 52, every recovered vertex is inside 0..647
with no masking needed, and every position is a few millimetres from that vertex.
That is the whole thing: **an entry is (vertex, new position)**, a facial blend
shape expressed as absolute target positions rather than deltas, quantised at
7.071e-06 per unit.

Two supporting details, both consequences of this reading rather than separate
findings:

* vertices 341 and 344 of Large Chin carry the same position, because the Head mesh
  splits vertices at UV seams; different vertices, one position, is exactly what a
  seam looks like.
* the positions are symmetric in x (the centroid is -0.0000 on all three shapes
  checked), which a face should be.

The three header floats are still an anchor of some kind, not the offsets they were
first called: Angled Nose, which has no entries, stores exactly Head vertex 0
(0.0121, 1.2473, 0.1458), and the value is not the centroid of the entries (3.6 cm
off for Soft Nose, 15.8 cm for Elven Ears). Anchoring the shape to a vertex would
explain both facts; that is a hypothesis, not something this evidence forces.

## Applying a shape, and looking at the result

`apply_shape.py` turns a decoded block 4 into geometry: it moves each entry's vertex
to the position the shape gives, then reports what moved. Large Chin on Head:

    entries 110, applied 110, skipped 0, largest move 0.0430 m
    moved 110 vertices, mean move 0.01416 m, max 0.04302 m
    region before: x -0.102..0.102  y 1.131..1.213  z -0.012..0.117
    region after : x -0.109..0.109  y 1.120..1.213  z -0.012..0.119

That is the jaw and chin band, and it widens and drops slightly - which is what a
shape called Large Chin should do. Rendered with the bake tools' rasteriser at yaw
180, with every triangle touching a moved vertex tinted red, the red covers the
chin and both sides of the jaw up to the ears and nothing else: 172 of 846
triangles, symmetric about x. That is the check that matters - the decoded data
moves the anatomy the name claims, on the real mesh, without any hand-tuned
mapping.

The silhouette change is real but subtle (mean 14 mm on a head about 22 cm tall),
so it reads as a variation rather than a caricature, which is what these sliders
are for.

## The eight that would not decode: section headers are byte aligned

Eight hiding templates (Daisy Print Dress, 70's Full-zip Jacket, 60's Dress,
Plimsolls, 70's Leather Platforms, Formal Trouser Suit, Surfer Shorts, Surfer
Hotpants) came back with a section B header of "count 992, index width 256" inside
a 13136-bit block - impossible. The reader failed loudly on them rather than reading
past the end, and the audit named all eight.

The fix came from an anchor rather than a guess. `b`, the quantisation constant, is
0x36ed4402 on every single item, so searching for that 32-bit value locates the
parameter block exactly, and the parameter block starts 64 bits into it. Working back
256 bits gives the section B header start:

    60's Boots       b at 4472 -> section B at 4216 = 256 + 330 x 12   exact
    Surfer Shorts    b at 2256 -> section B at 2000 = 256 + 145 x 12 + 4
    Plimsolls        b at 2280 -> section B at 2024 = 256 + 147 x 12 + 4

Four bits out, and four was the clue: 1996 bits is not a byte boundary (249.5
bytes), 2000 is. Section headers are byte aligned and the writer pads the gap. 60's
Boots needed no padding because 330 x 12 = 3960 already landed on a byte.

The decoder now aligns before reading section B, and all 266 shape overrides parse:
109032 entries, every payload consumed to within a byte, no problem assets. The same
alignment explains the 0-7 spare bits seen across the whole pack.

## What the clothing entries point at is still open

Section A of a hiding template is a plain 12-bit index list (0, 1, 2, 3 ... - the
vertices to hide), not offsets. Section B's leading field is an offset, but its
stride differs from the faces: the gcd of the offsets is 40 against 52 for head
shapes, and 40 is MaleBody's vertex stride (32-byte base plus two 4-byte UV sets).

It does not fit, though. Mapping those offsets onto MaleBody's vertices puts the
positions a mean of 0.51 m (Surfer Shorts) and 0.61 m (60's Boots) away from the
vertex the offset names - not millimetres. So the clothing templates decode
structurally but their target is not MaleBody: it could be the garment's own mesh,
another body, or a different coordinate space. Their vertex numbers should not be
used until that is settled, and the docstring and DECODE_STATUS.md both say so.

## Which mesh a shape targets - and how that was found

The clothing templates decode, but their 40-stride offsets did not fit MaleBody: the
positions sat a mean of 0.51 m away. Testing the same offsets against every stock
mesh answered it in one step - the distance to FemaleBody's vertex was 0.002 m, and
the nearest-vertex index minus the stored vertex was **0 for every entry**. The
templates were never wrong; the assumed target was.

`verify_shapes.py` now does that test for every shape-only item rather than trusting
a constant. It derives the stride with a gcd, takes the vertex out of the offset,
and asks which of Head / MaleBody / FemaleBody the vertices sit on:

    shape-only items with entries: 215
    every entry within 60 mm:      207 of 215   (mean 8 mm)
        Head          33 items, mean 0.0080 m, worst 0.0170 m
        MaleBody      84 items, mean 0.0077 m, worst 0.0195 m
        FemaleBody    90 items, mean 0.0078 m, worst 0.0260 m

A wrong target misses by hundreds of millimetres and a right one by millimetres, so
there is no grey area and nothing to tune: the exit status is 1 if fewer than 207
items fit or if the item count drops.

Eight do not fit completely, and they are two different things:

* three high heels - Female Platform Shoes, Female Strappy High Heels, High Heel
  Body Modification - are on FemaleBody with 190 of 198 entries inside 60 mm and a
  26 mm mean. That is a shoe lifting the foot, not a wrong target.
* five 2-entry "Template" items (Chinos with Belt, Female Cargo Pants, Female
  Tracksuit Pants, Female Trousers Bottom, Denim Jacket with Tee) land 0.28-0.59 m
  from every stock mesh. With two or three entries there is nothing to fit them
  against, so they stay unexplained rather than being forced to fit something.

## A stride trap in my own code, not in the data

Five 2-entry "Template" items had been left unexplained: their positions sat
0.59 m from every stock mesh. Dumping them next to a healthy template showed the
error was mine. Their offsets are 21600 and 46000, and this module was taking the
gcd of the offsets - 400 - as the stride. 400 is a multiple of the real 40, so two
entries that happen to share a factor sent every vertex to the wrong place:

    stride 400 -> vertices  54, 115   mean 0.5883 m from every mesh
    stride  40 -> vertices 540, 1150  mean 0.0000017 m from FemaleBody
    stride  80 -> vertices 270, 575   mean 0.4024 m

1.7 micrometres. The templates were always fine; the stride inference was not. A gcd
is only trustworthy when there are enough offsets to constrain it, and these items
have two or three.

The fix is to stop inferring and start choosing: the strides in this pack are 52
(Head) and 40 (the bodies), so those are the candidates, and whichever one puts the
vertices in range *and* the positions millimetres from the mesh they claim is the
right one - a wrong stride misses by hundreds of millimetres, so the choice is never
close. decode_shape exposes the candidates, verify_shapes tries them against every
mesh, and apply_shape picks the one that fits the mesh it was handed.

With that, 212 of the 215 items validate completely, up from 207, and the remaining
three are the high heels - on FemaleBody with 190 of 198 entries inside tolerance,
because a heel lifts a foot further than a face moves.

## The trailing pairs, measured but not understood

Each entry spends 51 bits (Large Chin) or 59 (Soft Nose) on four more fields, read
with per-field bases and widths like the rest of the parameter block. Measured over
whole shapes:

    field 1   width 31-32   varies per entry: 69 distinct values of 110 on Large Chin
    field 2   width 0       constant 255
    field 3   width 0       constant 19
    field 4   width 19-20   base near -329000, so the result straddles zero

Fields 2 and 3 are constants, which is why their widths are zero - the loader writes
255 and 19 as defaults. Field 1 varies per vertex but is not a float (0.0 and 6e6
from the same field). Field 4's base of -328966 is 0.6274 x 2^19, which hints at a
signed fixed-point range but nothing verifies that yet.

So the block is decoded far enough to use and not far enough to explain: the vertex
and its target position are established and validated against the meshes, and these
51-59 bits per entry are not. They are not needed to apply a shape - apply_shape
moves the vertex to the position and the mesh changes correctly - but they are
recorded here as unread rather than assumed to be padding.

## Five shapes, one picture

Rendering the base head and five decoded shapes side by side, tinting every triangle
that touches a moved vertex, puts each shape on the anatomy it is named after:
Large Chin and Rounded Chin light up the jaw and chin, Thin Chin the lower jaw,
Soft Nose the nose, Elven Ears the ear. Nothing else on the head moves. That is the
end-to-end check: bitstream in, vertex positions out, correct anatomy, no manual
mapping anywhere in between.

## A shape through the real bake

`bake_avatar.py --shape="Large Chin"` reshapes the head in bind pose, before the rig
poses it, so skinning carries the new geometry into the animation instead of the
animation overriding it. On the stock outfit, comparing the baked OBJ against the
same bake without a shape:

    3975 vertices in both
    110 differ, mean 0.0142 m, max 0.0430 m
    indices 1154..1778, and MaleBody ends at 1137 - so every changed vertex is Head
    and nothing else in the figure moved

That is the whole chain in one command: pack bytes, bit reader, quantised positions,
vertex stride, bind-pose reshape, 71-joint skinning, OBJ, turntable frames. The
frames render a complete posed figure, which is what AvatarStage3D plays.

## There are two avatar builds, and the dashboard's own poses were in the pack all along

Asked whether every avatar game in the archive has been looked at: there are exactly
two, `resources/editors/metro2010` and `resources/editors/nxe2008`, and they are the
same content in two builds.

    AvatarAssetPack.toc      md5 2b58915d809332b23ecff1669acdccee   identical
    10 .AvatarAnimation      md5 identical, all ten
    avatareditor.toml        identical
    avatareditor.exe         17,567,232 bytes  vs  8,651,264 bytes   different build

The nxe2008 binary is the smaller one and it is Rex-hosted with C++ RTTI left in,
including a source path: `NXE/avatar_editor_7357/src/kernel/xam/avatars/skeleton.cpp`.
So there is no third game hiding avatar data here - only a second build of the same
editor, which is still worth having because of the symbols.

What that build's string table gives us is the animation names, and they matter:

    Animation Generic Stand 0 .. 7
    Animation Male Idle Checks Hand / Looks Around / Shifts Weight / Stretch
    Animation Female Idle Check Nails / Fixes Shoe / Looks Around / Shifts Weight

Every one of those is **in the pack**, as block-1 assets, and `show_hand.py
--clip-asset` already resolves them (`Generic Stand 0`: 108 frames; `Male Idle Shifts
Weight`: 242). `Generic Stand 0..7` are the dashboard's own standing poses.

This contradicts the earlier note in CATALOG.md that "there is no relaxed-hand pose in
the pack to copy, so the pose has to be built": the bakes were using
`IdleOffScreen.AvatarAnimation`, an editor clip, and adding a hand-invented curl on
top of it. The retail stand poses were sitting in the pack unused. Whatever the right
hand turn out to be, they should come from these clips rather than from
`AVATAR_FINGER_CURL`.

Rendering the isolated hand from `Generic Stand 0` and from the idle clip at eight
angles each shows the same problem in both: the fingers read as one fused paddle
rather than separate digits. So the shape of the hand is not being decided by which
clip is loaded - the isolation or the skinning of the 15 finger joints needs to be
checked before the pose is tuned again.

## The Avatar Games archive: 19 games, and 31 authentic hand-posed clips

The Avatar Games zip holds two folders of XNA avatar games - Avatar Golf, Avatar
Punch, Avatar Miner Paintball, Avatar Survival Games, Avatar Bowling, Avatar Karting
2, Avatar Laser Wars 2 and the rest - and each carries an `avatar/assets` folder:

    AvatarAssetPack.toc   md5 2b58915d809332b23ecff1669acdccee
    the same pack these tools have been using, byte for byte

So the games add no new pack, no new skeleton and no new meshes. What they do add is
content the pack never had:

    avatar/closet/closet_index.tsv     00000ffc-c6d1-72d2-c96e-82df4d5309cf  Halo Spartan Armor - Steel
                                       00001000-a7a2-a223-c4a8-d4e454510874  Baby Po Animation
    Content/Avatar Animations/*.xnb    31 clips: Idle, Dance, Run, walk, Jump, Climb,
                                       Swim, Faint, BowIdle, BowFire, the gun idles,
                                       AttackBat/Club/Hammer, GrenadeThrow, Throw

The closet index is the file name the nxe2008 executable asks for (the string
`-closet_index.tsv` is in its binary), so the editor's closet can read these entries.

### `xnb_avatar.py` reads those clips

Uncompressed XNB (`XNBx`, version 5, flags 0), root object
`Hazzah.Engine.CustomAvatarAnimationData`: two single-byte fields, a name, an i64
duration in ticks, then a flat list of 76-byte records - `i32 joint index`,
`i64 time`, `4x4 matrix` - one per moving joint per frame. Joints that never move in
a clip are absent (`Fly` carries 67 of the 71). A correct walk ends one byte short of
the file size, that byte being the expression list's count.

All 31 clips decode. `Idle` is 181 frames over 3.00 s - 60 fps, 12,851 records,
exactly 181 * 71 - and `Dance` is 540 frames over 9 s, 38,340 records.

### What they say about the hands

These are the only hand-posed data outside the pack, and they disagree with what this
project had been doing. Mean rotation of our 30 finger phalanges across each clip:

    Idle         26.8 deg   (per joint 2 to 38, thumb lowest)
    IdlePistol   37.8 deg
    Dance        67.7 deg   (every finger uniform: a fist)
    WalkCrouch    0.0 deg   (straight fingers)

Against `FINGER_CURL_DEGREES = (8, 10, 6)` and `FINGER_THUMB_SCALE = 0.22`: the
invented curl is roughly a quarter of what the games use for a resting hand. That is
consistent with the hands reading as open and straight rather than relaxed, and it is
the strongest evidence yet that the curl should not be invented at all - `Idle.xnb`
already is the resting hand, curl included, for this exact 71-joint rig.

Unproven: the joint index space of these clips is assumed equal to the skeleton's
(the values are anatomically sensible if so - uniform fist in Dance, near-zero thumb,
zero for every finger in WalkCrouch - but that is agreement, not proof).

### All of it, game by game

The first pass only opened Avatar Miner Paintball's clips. Scanning every one of the
4,484 `.xnb` in the archive for `CustomAvatarAnimationData` finds **88 avatar clips
across 7 of the 19 games** (81 unique contents; the games reuse each other's clips -
`walk` is byte-identical in Paintball, Deathmatch, Maze Game and Deadly Tomb):

    Miner Paintball    37   Idle, Dance, Run, walk, Jump, Climb, Swim, Faint x3,
                            BowIdle, BowFire, GrenadeThrow, Throw, AttackBat/Club/
                            Hammer + the gun idles (duplicated in a Gun Anims folder)
    Survival Games     24   idle, run/back/left/right, jump, fall, bow_aim/idle/reload,
                            crossbow_*, catapult_aim, sword_block/idle/swing,
                            throwingknife_*, blowpipe_idle, item_eat/plant, holster
    and the Deadly Tomb 12  walk, run, run_org, Jump, Fall, Faint, Fail, Kick, Punch,
                            Push, OnWall, hang
    Deathmatch          9   Run, walk, Faint, Shooting, CrouchForward, CrossBowAnimation,
                            HandGunPos, ShotGunPos, UzziPos
    Maze Game           3   Walk, Run, PickUp
    Air Wars            2   Plane, Helicopter (3 frames each)
    Karting 2           1   steer

The other twelve games (Golf, Punch, QuizCall, Avenue, Boogie, Bowling, Connection,
Blackjack, Hangman, Laser Wars 2, Warfare) ship no avatar clip at all: they drive the
avatar through `Microsoft.Xna.Framework.GamerServices.AvatarAnimation`, the platform's
own preset library, which is not a file in the archive.

### Every clip's hand, measured

Mean rotation of the 30 finger phalanges, all 88 clips:

    lowest   0.0   Paintball IdleCrouch and WalkCrouch - fingers not animated at all
           14.2   SwimUnderwater
           22.1   every walk
           26.8   Paintball Idle          <- the standing rest pose
           29.5   Survival Games idle
           38.6   Deathmatch ShotGunPos / CrossBowAnimation
           45.9   every run
           46.8   Deathmatch HandGunPos
           60.8   Deadly Tomb Punch
           67.7   Paintball Dance         <- fist

Nothing shipped is as open as `FINGER_CURL_DEGREES = (8, 10, 6)` except the two crouch
idles where the fingers carry no rotation at all. The weapon poses are the most
useful oddity: `HandGunPos`, `ShotGunPos`, `UzziPos` and `CrossBowAnimation` are 201
frame holds at 3.33 s - a grip, not a shake - so they pin down how the fingers wrap an
object, which no pack clip does.

## Driving the rig from a game clip

`xnb_avatar.poses()` turns a decoded clip into avatar_pose's `(position, quaternion,
scale)` tuples, and both `show_hand.py --xnb` and `bake_avatar.py --xnb=PATH[:FRAME]`
use it. Two things had to be established to make it usable.

**Row-vector convention.** XNA's Matrix multiplies row vectors, so the rotation to
apply is the transpose of the stored one. Measured on frame 0 of Paintball's `Idle`,
by posing the rig and reading the wrist heights:

    as stored     wrists y = 1.235   head y = 0.755   arms overhead
    transposed    wrists y = 0.670   head y = 0.755
    pack's own    wrists y = 0.642   head y = 0.742   "Animation Male Idle Shifts Weight"

The pack's own idle is the arbiter: 0.670 against 0.642 is an idle, 1.235 is a
celebration. `poses()` therefore conjugates.

**Frame-filling.** A joint absent from a clip keeps an identity delta, which in
`delta` mode leaves it exactly at its bind transform - no guessed angles, and the
finger joints that a clip does animate override it.

With that, the avatar stands with its arms down and the hand reads as a closed,
relaxed grip rather than the open paddle the pack clip produces. The remaining
weakness is resolution: the hand is 69 vertices and 100 triangles, drawn flat, so
separate digits only show at the silhouettes.

## Boogie and Survival Games, opened properly

Both were extracted whole rather than surveyed from the zip listing.

**Avatar Survival Games** (432 files): 211 `.xnb`, 90 of them version 4 with flags
0x80 (compressed). Its 24 avatar clips are uncompressed version 5 and were already
decoded - `xnb_avatar.read_clip` reads them.

**Avatar Boogie** (276 files): has no `Content/Avatar Animations` folder at all, which
is why the first sweep called it empty. It keeps its dances somewhere else:

    Content/AnimationDataCustom/CountryCircle.xnb          1.2 MB
    Content/AnimationDataCustom/DanceHipHopSequence.xnb    2.8 MB
    Content/AnimationDataCustom/Disco.xnb                  2.0 MB
    Content/AnimationDataCustom/Hardcore.xnb               1.7 MB
    Content/AnimationDataCustom/IrishJigging.xnb           1.7 MB
    AvatarCustomAnimation.dll        (the game's own animation type)
    ColladaReader.dll

All five are XNB **version 4, flags 0x80** - compressed - and **this project cannot read
them yet**. What was tried on `CountryCircle`:

    payload entropy                     7.95 bits/byte, so genuinely compressed
    header u32 at 6                     1,209,050 = the file size
    header u32 at 10                    4,527,994 = the decompressed size
    lzx.decompress from bytes 6..40     "bad block type" at every offset
    with a 64 KiB window                same
    at the 24 bit-shifted candidate
      block headers the scan found      "bad block type" / "bad aligned table"
    zlib, raw deflate, gzip             all refuse

So XNA's XCompress framing is not the kernel XMemCompress framing that lzx.py
implements for the avatar pack, and the five Boogie dances stay unread until that
framing is worked out - most likely from `AvatarBoogie.exe`'s own decompressor, which
ships with the game. Boogie's clips are dances in any case, not the resting hand.

## Compressed XNB: the blocker, and what it was hiding

Every earlier count was wrong in one specific way: a compressed XNB hides its type
names, so the sweep that classified files by looking for `CustomAvatarAnimationData`
in the first 8 KB silently filed them as "other". Avatar Laser Wars 2's whole
`Content/AvatarAnimation/` folder - 79 files - was invisible that way.

The format, settled by experiment on `Laser Wars 2/.../GenericIdle.xnb`:

    u32 @ 6     file size
    u32 @ 10    decompressed size
    byte @ 14   skipped
    @ 15        LZX stream, **64 KiB window**

The 32 KiB window that `lzx.py` uses for the avatar pack does not decode it
("bad block type"), which is why this looked unreadable for so long. With 64 KiB and
one byte skipped the stream decodes exactly, and what comes out is an ordinary
type-reader table - no XNB header, so `read_type_readers` now accepts a bare payload.

Those clips are **not** the Hazzah format. Their root reader is
`DNA.Drawing.Animation.AnimationClip+Reader`, a different engine (Digital DNA), so
`read_clip` does not read them yet.

### The corrected inventory

Scanning all 609 animation-named `.xnb` in the archive with decompression in place:

    Miner Paintball      37 Hazzah clips   + 2 unread
    Survival Games       11 (of 24 files)
    Warfare              51 DNA clips (25 names)  + 110 unread
    Laser Wars 2         37 DNA clips       + 44 unread
    Punch               192 compressed, unread - the game's whole content
    Connection            1 DNA clip        + 24 unread
    Bowling              13 unread,  Blackjack 3, Hangman 2, Golf 4
    Avenue                2 unread,  Boogie 6 unread

So the games hold at least **118 distinct avatar clip names**, not the 88 earlier
counted, and 89 of those (`Warfare`, `Laser Wars 2`, `Connection`) are in the DNA
format and still unparsed.

### Still unread

* **version 4 compressed** files - Avatar Avenue's 3 clips, Avatar Boogie's 5 dances,
  Avatar Punch's 192 files. They do not decode at any of the offsets and windows
  that work for version 5, so the v4 framing is a separate question.
* **the DNA clip layout** - `DNA.Drawing.Animation.AnimationClip`. Its payload starts
  with a byte, the name ("Take 001"), an i32, an i64, then 71, then per-bone records of
  roughly 36-52 bytes. Not decoded yet, so no frames or joints come out of it.

## The DNA clip format, decoded

`DNA.Drawing.Animation.AnimationClip` (the Digital DNA games) turned out to be simple
once measured. Payload:

    u8   flag, then u8 length + name ("Take 001")
    i32  frame count   (30)
    i64  duration ticks (3,166,666 = 1/3 s)
    i32  bone count    (71)
    per bone, three channels, each `i32 count` then that many elements:
        count x Vector3     (12 bytes)  translation
        count x Quaternion  (16 bytes)  rotation
        count x Vector3     (12 bytes)  scale

With one key per channel that is 52 bytes a bone, and `GenericIdle` is exactly
71 x 52 bytes from the header to the last byte - the walk ends on the file's final
byte, which is how the layout was confirmed. Bone order matches the retail rig: the
finger groups land on 37-40, 51-54, 58, 66-69, the same indices `finger_bones` finds.

**The quaternions are used as stored - no sign flips.** An earlier pass negated y
because that lowered the wrists, and it was wrong: all eight axis-sign variants were
then measured on two things a right hand cannot fake at the same time, fingertip
distance from the wrist and the spread between fingertips. On `intro_pose05`:

    plain (x,y,z,w)   fingertips at 0.33 of bind distance, splay 0.021   curled
    y negated         fingertips at 0.49, splay 0.026                     fanned

The flipped form fixes the arm height and fans the fingers. `dna_poses(flip_y=True)`
is kept only so the wrong reading can be reproduced and seen.

**82 clips decode** across Warfare (51 files), Laser Wars 2 (37) and Connection (1),
every one landing exactly on its file size. Mean finger rotation spans 27.6 deg
(`intro_pose05`, the most relaxed) to 58 deg (`Warfare/Idle`, a weapon grip).

### What the hands actually are

Measuring the MaleBody's weights settles the resolution question: **210 vertices are
driven by finger joints** (about 105 a hand) across 42 distinct influence sets, so the
model has real fingers - 69 vertices was only what `show_hand.py` was selecting, not
what exists. The visible coarseness is 100 triangles for the whole hand, not a lack of
data.

Rendered from `intro_pose05`, the hand reads as separate curled digits with the thumb
across the palm; from the pack's own clip it reads as a flat paddle. The pose was the
problem, and the pose now comes from shipped data in every case.

### The hands were being rendered as a hole-punched fragment

The reason every hand image looked mangled, including in bind pose, was not the pose
and not the mesh: `show_hand.py` selected vertices by walking each influencing joint
up to a wrist, and walked the wrong way - it searched for joints whose *parent* was
the current node, which descends into the children. Most vertices never resolved to a
wrist and were dropped, and every triangle with a dropped corner went with them:

    69 of 129 vertices, 100 of 222 triangles, white holes through the palm

Following `joints[node]["parent"]` instead selects the whole hand. The same rig poses
that read as a fused paddle now show four fingers and a thumb, in bind pose and in
every clip, which also means the earlier judgements about hand poses were made on
broken geometry and have to be re-read.

### Confirming the hand is whole

After both selection fixes, the surface is closed and the skeleton supplies real finger
bones rather than a fan of zero-length joints:

    finger joints          30 (37-40, 43-47, 50 proximal; 51-60 middle; 61-70 distal)
    phalanx lengths        0.047 and 0.034 m along 37 -> 51 -> 61
    selected per hand      267 vertices, 523 triangles
    boundary edges         9, every one on the wrist cut (y 1.006..1.045)

Rendered in context at 700x1000 and cropped, the fingers of `intro_pose05` hook at the
first knuckle and the thumb sits along the palm; the pack clip's own hand, rendered the
same way, fans into a thin paddle. The remaining coarseness is the mesh: 523 triangles
for the hand and no textures or normals in this renderer, not a data or pose fault.

## The Avatar_Games.zip dump, and the Windows XNB framing

The archive arrived as a 1.9 GB zip with 4,484 `.xnb` in it, of which **185 are
avatar clips** under `Content/AvatarAnimation(s)/`: Miner Paintball 37, Laser Wars 2
79, Warfare 39, Connection 25, Deluxe Blackjack 3, Air Wars 2. The 185 are kept in
`src_archive/avatar-games/`; the rest of the zip is UI textures and the PC builds.

The framing in these files is **not** the console one documented above. The platform
byte is `x` (Windows) and the two size words are **little-endian**:

    u32 @ 6    file size            (LE)
    u32 @ 10   decompressed size    (LE)
    @ 14       one byte
    @ 15       LZX stream, 64 KiB window

Decoding all 185 with that: **58 decode**, leaving the payload starting
`01 6d 44 4e 41 2e 44 72 61 77 69 6e ...` - a length-prefixed
`mDNA.Drawing.Animation.AnimationClip+Reader`, so the DNA clip layout already
decoded here applies directly. **39 are uncompressed** (flags 0) and their payload
begins at 10 with the same reader table. **88 still fail**, and they are the
candidates for the version-4 framing: that is now a bounded difference to chase
against 58 known-good streams rather than a cold start.

### The 88 streams that will not open, and what is ruled out

Of the 185 clips, 58 decode with the Windows framing and 54 walk cleanly to JSON.
The remaining 88 are genuinely compressed - no reader name and no `Take 001`
anywhere in the file in the clear - and these are ruled out by test, not by guessing:

* **zlib** (wbits 15, -15, 31), **lzma** and **bz2** at offsets 8-23: only 1-8 byte
  "decodes", i.e. coincidences.
* **LZX** at every offset 12-25 with 32 KiB and 64 KiB windows: rejected.
* A wrong output length is not it: 39,562 (declared), 39,682, 1 MiB and 107,824 all
  fail identically.

The one structural clue is where the error changes kind on `LMGShoulderWalk`:

    off 14 (0x2c)  bad aligned table      off 16 (0x09)  out of input bytes (64 KiB)
    off 15 (0xd2)  bad block type         off 17 (0x20)  bad block type

Offset 16 is the only one the decoder accepts the block header at and then runs dry,
so the next pass belongs in `lzx.py`'s header handling rather than in the offset.
The good files carry **0xff at offset 14** and start at 15; these carry
0x2c/0x5e/0x58/0x42/0x60 there, so the two groups differ systematically in exactly
that byte.

Both groups parse identically up to byte 14, so the container is not in doubt:

    good  RifleIdle         58 4e 42 78 05 81 | 00 05 00 00 | fa 0e 00 00 | ff | stream...
    bad   LMGShoulderWalk   58 4e 42 78 05 81 | a6 34 00 00 | 8a 9a 00 00 | 2c | stream...

size-LE@6 and decompressed-LE@10 are correct for both (1280/3834 and 13478/39562),
`XNBx` + version 5 + flags 0x81 match, and byte 14 is 0xff only in the group that
decodes. That single byte is the whole difference: whatever consumes it is a block
marker, and the aligned/verbatim/uncompressed attempt belongs in `lzx.py`'s first
header read (line ~296), not in the offset sweep.

#### Calibrating the bit reader (the earlier offset sweeps were invalid)

`lzx.py` packs *16-bit little-endian words* and reads them MSB-first, so any
hand-modelled header that walks bytes MSB- or LSB-first will misparse both groups.
Traced through the real `Decoder`:

    RifleIdle (off 15): intel=1, sizes 62493/53256, block type 2, length 3834 = full output
    LMGShoulderWalk (off 15): intel=0, block type 0 -> invalid

That means the 58 files that "decode" are **uncompressed blocks inside an LZX wrapper** -
their length exactly equals the declared output - so the 54 extracted clips are raw
payloads, not decompressed ones. The 88 are the genuinely compressed streams, and the
header model has to be calibrated on the real reader before any offset is judged.
