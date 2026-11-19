# Decompiling the editor binaries

The archive's code is not just decodable, it can be turned back into C. This is
what came out, how it was produced, and the two places it stops.

Everything here is read-only reverse engineering of files already in
`src_archive/`. Nothing is redistributed beyond what is kept in the repo:
`decompiled/samples/` holds a handful of functions as evidence, and the full
corpora live in the `UniKron-decompiled-*.zip` archives beside the theme zip.

## Results

| Binary | Platform | Architecture | Functions recovered |
| --- | --- | --- | --- |
| `resources/editors/nxe2008/assets/avatareditor.xex` | Xbox 360, 2008 dash | PowerPC BE | 1,986 |
| `resources/ogxbox/uix/xboxfs/Q/Xips/Toolbox.xip` | Original Xbox | x86 | 2,144 |
| `resources/ogxbox/uix/xboxfs/Q/Xips/settings_adoc.xip` | Original Xbox | x86 | 1,444 |
| `resources/ogxbox/uix/xboxfs/Q/Xips/shutdown.xip` | Original Xbox | x86 | 0 (see below) |
| `resources/editors/nxe2008/avatareditor.exe` | Windows host, 2008 | x86-64 | 11,957 |
| `resources/editors/nxe2008/rexruntime.dll` | 360 runtime (rexglue) | x86-64 | 28,467 |
| `resources/editors/nxe2008/rexgpu-xenos.dll` | Xenos GPU emulation | x86-64 | 4,866 |
| `resources/padwatch.exe` | Steampad watcher | x86-64 | 4,768 |
| `resources/ogxbox/uix/theseus.exe` | Original Xbox dashboard | x86-64 | 8,352 |
| `resources/editors/metro2010/avatareditor.exe` | Windows host, 2010 | x86-64 | 20,381 |
| `resources/editors/metro2010/assets/avatareditor.xex` | Xbox 360, 2010 dash | PowerPC BE | **encrypted, blocked** |

Ten binaries gave up their code: 84,365 functions in total, written out as one C
file each.

The 2008 editor is the one this theme reproduces, so its corpus is the useful one: 1,986 functions of real C, dense across the whole `.text` (`0x9803acc8`-`0x9813c058`), complete with the UI class names the strings section promised (`AuraControl`, `AuraScene`, `AvatarCategoryLabelOverride`, `AvatarBackButtonOverride`).

**Correction: the corpus that was shipped the first time was not real C.** Every
file in the original `UniKron-decompiled-xbox360-2008.zip` was a three-line
`halt_baddata()` stub. Two separate faults were behind that, and the table above
predates both fixes:

1. **The base was wrong.** The import used the base the PE header claims
   (`0x92000000`) instead of the one the code builds (`0x98000000`), so the whole
   image decoded as garbage. Importing at `0x98000400` (`mkelf.py` reports it)
   gives 1,093 real bodies and 893 stubs.
2. **The word size was wrong.** The remaining 893 were not `vmx128` after all.
   The editor saves its floating-point registers with `std`, a *64-bit* store;
   `PowerPC:BE:32:default` rejects it and truncates the function at its prologue.
   Importing the same bytes as `PowerPC:BE:64:64-32addr` - 64-bit registers, a
   32-bit address space, which is what Xenon is - decodes them: **2,967
   functions, 189 stubs**.

What is left after that is a smaller `vmx128` residue plus padding. `vmx128` is
not in any shipped PowerPC language, so `patch_vmx128.py` rewrites those words to
`nop` in a copy of the image (6,819 words) and decompiles that. The result this
corpus holds:

| | functions |
| --- | ---: |
| in the image | 3,095 |
| with a decompiled body | 2,903 |
| without one | 192 |

The 192 are zero-filled padding Ghidra promoted to functions, and a handful of
pcode failures (`Unable to resolve constructor`), not undecoded code. A recount of
the corpus sharpens that: it holds a `.c` for **all 3,095** functions, and exactly
**192** of them contain `halt_baddata()` - the same number, so the "192 without a
body" are precisely the `halt_baddata` stubs, and 0 files report a pcode failure.
Nothing in the corpus is missing; 192 bodies stop where the decoder stopped.

A second attempt to pin down *where* it stopped failed, and the failure is worth
recording: Capstone has no `vmx128` and its linear sweep desynchronises once it hits
an undecodable word, so the "first bad word" it reports for a stub can be a perfectly
ordinary `addi`, `mfspr` or `stfd` that it simply never reached. The addresses it
blamed (`0x3963fffe`, `0x7d8802a6`, `0x480df6ac`) are all valid instructions. So the
cause stays where the earlier pass put it - `vmx128` words the nop patch did not
match - and confirming it needs a decoder that understands the extension, not
Capstone.

### What the two XEX containers actually are (measured)

Both files are XEX2 with the same header shape, and both were recorded as unreadable
at some point. They are not the same problem:

| | 2008 `avatareditor.xex` | 2010 `avatareditor.xex` |
| --- | --- | --- |
| PE data offset | `0x3000` | `0x7000` |
| security info | `0x100`, 6,268 bytes | `0x90`, 20,428 bytes |
| optional headers | 13 | 15 |
| image size / load | `0xf15000` / `0x98000000` | `0x33fb000` / `0x92000000` |
| bytes at the PE offset | `4d5a 9000` - **`MZ`, a plaintext PE** | `4ed6 b6b4` - high entropy |

So the 2008 body was never encrypted and its decompile never needed a key; the
`0x98000000` corpus addresses are just its load address. The 2010 body is the one in
a container: its security info carries an image key at `+0x150`, and the file
declares **basic compression** (optional header `0x000103FF`), so the body is
expected to be compressed and possibly wrapped.

`xex_unpack.py` parses that header and unwraps the image key with the public retail
and devkit keys (the fixed key that wraps the session key is not a secret - the
console has to hold it to boot anything). No key turned the 2010 body into a PE,
which is what a compressed body looks like: decryption alone cannot expose `MZ` when
the plaintext is an LZX stream. What that costs is a decompressor, not a secret.

And the 2010 editor's *program* was never missing: `metro2010/avatareditor.exe` is a
64-bit PE (machine `0x8664`, 7 sections, entry `0xf5d374`, strings such as
`AE_MktCatFetch`), and the 20,381-function corpus was decompiled from it. The
encrypted `.xex` is a second container for the same editor, not a second program. The
neutralised vector words are absent from the C - store/load pairs that fed them
read as unused loads - so the bodies are readable for control flow, calls,
string references and scalar constants, and are not a faithful simulation.

`decompiled/nxe2008_index.txt` is regenerated from this corpus (address, body
length, first literal), and `decompiled/samples/` holds the function that
declares the editor's scene lights.

The 2010 host binary is the largest single result at 20,381 functions, and it
documents the direction that dash took: marketplace and telemetry strings such
as `AE_MktCatFetch`, `AE_MktChannelValidate`, `AE_MktHoverTryOn` and
`AE_MktDispatchKind` are inline in the C, so the 2010 editor was built around a
catalogue/store pipeline that the 2008 one did not have.

## Toolchain

Ghidra 12.2 with Temurin JDK 25, both unpacked into `/tmp` because the sandbox
has no root and no JDK. Ghidra only accepts JDK 25 here; 21 is rejected at
launch. `ghidra/DecompileAll.java` is the post-script: it walks the function
manager, decompiles each function, and writes one `.c` file per function named
`<name>_<entry>.c`.

```sh
# once, in a writable directory
curl -L -o ghidra.zip "$(curl -sL https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest \
  | grep -o '"browser_download_url": *"[^"]*\.zip"' | head -1 | cut -d'"' -f4)"
curl -L -o jdk.tar.gz "https://api.adoptium.net/v3/binary/latest/25/ga/linux/x64/jdk/hotspot/normal/eclipse"
unzip -q ghidra.zip && tar xzf jdk.tar.gz

# PPC XEX: wrap the image, then decompile everything
python3 mkelf.py avatareditor.xex /tmp/nxe2008.elf
JAVA_HOME=/tmp/jdk-25.0.5+8 ghidra_*/support/analyzeHeadless /tmp/proj uni2008 \
  -import /tmp/nxe2008.elf -processor PowerPC:BE:32:default \
  -scriptPath ghidra -postScript DecompileAll.java /tmp/decompiled/nxe2008 -deleteProject

# the language matters more than the base: `-processor PowerPC:BE:32:default`
# rejects the 64-bit `std`/`ld` the editor saves registers with, and every
# function that uses them becomes a stub. 64-bit registers, 32-bit addresses:
JAVA_HOME=/tmp/jdk-25.0.5+8 ghidra_*/support/analyzeHeadless /tmp/proj uni2008 \
  -import /tmp/nxe2008.elf -processor PowerPC:BE:64:64-32addr \
  -scriptPath ghidra -postScript DecompileAll.java /tmp/decompiled/nxe64 -deleteProject

# neutralise the remaining vmx128 words so control flow around them decodes
python3 patch_vmx128.py /tmp/nxe2008.elf /tmp/nxe2008_nop.elf /tmp/vmx128.json

# x86 XBE: same wrapper, different architecture
python3 mkelf.py Toolbox.xip /tmp/Toolbox.elf --x86
# ... -processor x86:LE:32:default
# The -processor flag is what actually selects the architecture; an ELF wrapped
# for the wrong machine still decompiles, and gives the same 2,144 functions, so
# the container arch is a correctness detail rather than a result-changing one.
```

## Four traps worth writing down

**Ghidra has no Xbox loader.** It ships nothing that understands `XEX2` or
`XBEH`, so every binary has to be re-wrapped as an ELF first. `mkelf.py` does
that: one `PT_LOAD` at the true base, a section header per block at its real
virtual address, entry point preserved, bytes untouched. Without the correct
section addresses the decompiler sees a flat blob and every cross-reference
becomes a wild pointer.

**The 2008 XEX's PE header lies about its base.** The header claims
`0x92000000`; every `lis` in the code builds `0x9800_0000`. Importing at the
header base yields 263,296 instructions and 3,938 apparent functions that
resolve nothing. `ppc_disasm.detect_base()` takes the most common `lis` high
half instead and the same image then decompiles cleanly. The 0x06000000 gap is
the loader's rebase, not corruption.

**XBE header integers are little-endian.** The magic is ASCII `XBEH`, the load
address, section count and section table address are little-endian words at
`0x104`, `0x11C` and `0x120`, and the 256-byte signature occupies `0x04`-`0x104`.
Reading them as big-endian - the obvious assumption on PowerPC hardware -
produces section tables gigabytes away from the file.

**MSVC mangled names overflow the filesystem.** The 2010 binary's names are
Tera-flavoured C++ (`?AppendItem@XStaticUntypedEnumerator@system@rex@@...`), and
a few run past 255 bytes, which aborts the whole script with
`File name too long` after 20,018 functions. `DecompileAll.java` now replaces
anything outside `[A-Za-z0-9_.-]` and truncates to 110 characters plus a hash.

**One `.xip` is not a program at all.** `shutdown.xip` has no x86 prologue
anywhere in its 24 KB section, and its header's entry field points into a
copyright notice (`Copyright (C) 2003 VulgusProfanum. Thanks to xbdev.net for
the xbe header`). It is a data-only sample XBE someone dropped into the image
set; there is nothing to decompile.

**Those `.xip` files are not 360 binaries.** The three `Q/Xips` files carry
`XBEH` headers and sit next to 360 content, but their code is x86
(`81 ec 14 04 00 00` is `sub esp,0x414`). They are Original Xbox dashboard
binaries, so they must be decompiled as `x86:LE:32:default`; as PowerPC every
function starts with bad instruction data. `shutdown.xip` is a single 24 KB
section whose entry decodes to nothing either way - it looks like a stub or a
resource-only image, and that is the honest read of it.

## Where the strings went

The 2008 corpus rarely shows asset names inline. The editor reaches most of them
through tables of pointers, so the C reads `*(char **)(table + 4)` rather than
`"closet_spin.MsLiveAvatarAsset"`. Two things cover the gap: the index in
`decompiled/nxe2008_index.txt` lists every function with its instruction count,
call count and first string reference taken straight from `lis`/`ori` pairs,
and the literals the decompiler does resolve are already in the C.

## The corpus is the retail editor, byte for byte

The `Clean Slate NXE` dump (dashboard 2.0.9199) carries
`gamedir/avatareditor.xex` at 15,826,944 bytes. Its MD5 is
`39432fadd9a1866d94a859974ae8e616`, identical to the copy under
`resources/editors/nxe2008/assets/`. So the 3,095-function corpus above is the
retail editor's code, not a companion build - anything read out of it applies to
what the dump ships. The same dump's `AvatarAssetPack.toc` is also the same
13,648,884 bytes as the editor's own pack.

What the dump adds is elsewhere: `assets/closet/` holds **20,349** retail item
assets with names (`closet_index.tsv`) and PNG icons. `closet_import.py` reads
that folder in place and writes a catalogue JSON; the items are the same
`YTGR`/`STRB` containers as the editor's pack, and they carry no textures either
(see `TEXTURES.md`).

Their blocks are different in one way that matters: the payload is LZX-framed
*inside* the STRB, where the editor's pack stores its blocks plain. Passing the
block through `avatar_mesh.decompress` first makes it an ordinary model, so
`read_model` reads it and every item yields batches, vertices, triangles, UVs,
7-entry material lists, joints (3 per vertex) and normalised weights. All 340
items sampled decode. Two fixes were needed and both were in this repo, not in
the data: a retail model ends its LZX chain with a few trailing bytes that read
as an oversized header, and `read_model` refused any batch over 8,192 vertices
while a full costume reaches 8,719. The reader now skips the tail and bounds a
batch by the u16 index range instead.

**The retail items are pre-placed in a body space of their own**, which is how
the dashboard can drop one on an avatar with no rig work. Feet sit at y = 0 and
the head tops out near 1.6, and the per-item bounds separate the garments:
shoes span 0.00-0.21, trousers and shorts 0.10-0.79, tops 0.68-1.13, hats and
helmets 1.13-1.60. Up is **y**, where the shipped pack's bodies are x, so a
retail item needs that axis remap and no other transform. `closet_import.py`
records each item's bounds so the theme can place it from measurement.

**No field states a garment category.** The item id does not carry one (no
GUID nibble separates caps from shirts beyond the index's source code), the
`closet_index.tsv` code is an item source class, every garment binds to the same
joints (4, 18, 30, 27 dominate caps, pants and shirts alike), and vertex
positions are normalised so a cap and a pair of pants both centre at y = 0.94.
The dashboard editor's categories come from the guest's asset metadata, not from
the file, so the catalogue records block ids and geometry only and claims no
category.

## The XTL effects, and where the shaders stop

`xtl_effects.py` pulls the editor's 21 `.updb` effect blobs out of the XEX.
Each is the shader's build path, a big-endian parameter table, then the
compiled shader. The tables are the useful part, because they name what the
editor binds:

| effect | parameters |
| --- | --- |
| `shader_body_opaque_ps` | `CustomColor1-3`, `ambientColour`, `enableShadows`, `jitterMap`, `lightColour1-3`, `lightDirection1-3`, `oneMinusShadowStrength`, `rimLightColour`, `s_colourTex`, `s_decalTex`, `s_intensityTex`, `shadowMap`, `shadowSizes` |
| `shader_body_transparent_ps` | the same plus `Transparency` |
| `shader_body_shiny_opaque_ps` | the same as opaque, with `Reflectivity` and `s_envmap` |
| `shader_head_opaque_ps` | `EyeBrowTone`, `EyeShadowTone`, `FacialHair`, `IrisTone`, `MouthTone`, `SkinFeature1Tone`, `SkinFeature2Tone`, `SkinTone`, the same light rig and shadow pair, `texEye`, `texEyeBrow`, `texEyeShadow`, `texFacialHair`, `texMouth`, `texSkinFeatures` |
| `shader_body_*_vs` | `c_modelview`, `c_projection`, `c_shadow` |
| `loading_*` | `fade`, `loadingTexture`, particle setup |

Two things follow from that table, and they override guesses made elsewhere in
these notes:

- The head is **six separate texture slots** with **eight tones**, not one
  combined mask. `texEye`, `texEyeBrow`, `texEyeShadow`, `texFacialHair`,
  `texMouth` and `texSkinFeatures` are named individually, and the head asset's
  six empty 128x128 / 64x64 slots are exactly those six. Whatever paints them
  must supply all six, or the head is painted with fewer layers than the editor
  binds.
- There is **no** `s_colourTex` on the head. The body takes a colour texture, a
  decal texture and an intensity texture; the head takes the six face sheets and
  none of those.

The bodies themselves are Xbox 360 GPU microcode: the blob ends with the Xenos
footer `0x102A1101` followed by section sizes (`0x208 0x388 0x24 0x90 0x130
0x158` on the body shader). There is no D3D9 token stream in them - the `ps_3_0`
string is the XTL compile target, not an instruction set - so `xtl_effects.py`
writes each blob out verbatim (`.updb` beside `effects.json`) and disassembles
nothing. Reading the bodies needs a Xenon `vmx128`/clause decoder, the same gap
that blocks 893 of the C functions.

## The shader bodies: what was tried, and why it is still open

`xtl_effects.py` writes each effect out verbatim, and the note above said the
bodies are Xenos microcode with no D3D9 token stream. Attempting to decode them
established that the **extraction is the problem, not just the format**:

* `find_blobs()` ends each blob at the *next* `.updb` path string in the image.
  Ten of the 21 blobs therefore contain no `0x102A1100` footer at all, and
  **every vertex shader that has code beside it is one of them**
  (`shader_body_opaque_vs`, `shader_head_opaque_vs`, `shader_body_shiny_vs`,
  `shader_body_transparent_vs`, `loading_vs`, `loadingbact_vs`,
  `loadingmist_vs`, the two `loadingstars` ones and `shader_simpleshadow_vs`).
  Their parameter tables arrived; their bodies did not.
* Even where the footer is present, the eight words after it are larger than the
  file: `shader_body_opaque_ps` (footer at `0x80d`) reads
  `102A1101 208 388 24 90 130 158 0`, i.e. 520 and 904 bytes, in a 2 KB file that
  also has to hold the path and parameter table. So those fields describe the
  assembled shader somewhere else in the image, not the blob on disk.

The image itself carries **44 headers** - `0x102A1100` x30 (vertex) and
`0x102A1101` x14 (pixel) - each followed by the same 7-field size list
(`280,132,36,128,0,224,0` for `shader_simpleshadow_vs`, `520,904,36,144,304,344,0`
for `shader_body_opaque_ps`). The dead end: nothing around any of the 44 is
microcode. Scoring every 4-byte offset for a valid `vfetch` - the encoding below
- gives at most one candidate per region, and that candidate always has stride 0
and format 0, i.e. junk. The same test on the whole 15.8 MB image finds 2,006
candidates with the same defect.

The `vfetch` encoding is recorded here so the next attempt does not start over.
It is from Xenia's `ucode.h` (`VertexFetchInstruction`), cross-checked field by
field against Mesa's `instr-a2xx.h` in `xenos-linux-gpu`'s ISA comparison:

    dw0  [0:4]   opcode, 0 = vfetch        [12:17] dest register
         [19]    must_be_one               [20:24] fetch constant index
         [25:26] constant index selector
    dw1  [0:11]  dest swizzle              [12]    format_comp_all (signed)
         [13]    num_format_all (0 = normalised)
         [16:21] vertex format             [30]    is_mini_fetch
    dw2  [0:7]   stride in dwords          [8:30]  23-bit signed byte offset

`must_be_one` is what separates a fetch from an ALU instruction in the same
triple stream. Microcode is triples of 32-bit big-endian dwords; control flow
occupies the first slots as 48-bit pairs (CF0 = dw0 + dw1[0:15], CF1 =
dw1[16:31] + dw2), with the opcode at `[44:47]` of each pair, and `exec.address`
counts 96-bit slots from the shader start - so a working carve has to begin at a
CF slot, which none of the 44 headers' neighbourhoods do.

What is needed: the framing those 7 size words describe, so the bodies can be
carved whole, or the original `.updb` files from the dash image. Without one of
those, a decoder here would be guessing at where code begins, which is exactly
what these notes are not for.

## What the runtime and the front-end expose

Decompiling the host side answers a question the XEX could not: how the editor
got its avatar data. `nxe2008/avatareditor.exe` imports the whole `XamAvatar`
surface - `XamAvatarInitialize`/`Shutdown`, `BeginEnumAssets`/`EnumAssets`/
`EndEnumAssets`, `GetAssets`/`GetAssetsResultSize`, `GetAssetBinary`,
`GetAssetIcon`, `LoadAnimation`, `GenerateMipMaps`, `SetManifest`,
`SetCustomAsset`, `GetManifestsByXuid`, `ManifestGetBodyType`,
`GetInstalledAssetPackageDescription`, `SetMocks`, `CreateAvatarAssetEnumerator`
and `GetInstrumentation` - and drives them from its own app class
(`AvatareditorApp::MirrorDispatchTable`, `AvatareditorApp::OnPreLaunchModule`,
`AvatareditorApp::MountFontDevice`). Its asset paths are visible as literals:
`//avatar/u:`, `/avataritems/`, `/avatar-body.png`.

`rexruntime.dll` is the other half: `rex::avatars::LoadAssetsToGuest` is what
hands the enumerated assets to the guest title, which is why the XEX itself only
ever names `.MsLiveAvatarAsset` files and never the bytes behind them. Its
embedded source paths (`C:/Users/vigln/dev/rexglue-sdk/src/ui/rex_app.cpp`) mark
the host as a rexglue build, and it answers on `http://127.0.0.1:8080` for
debugging.

## The avatar-game clips: the framing, and the reader

The 185 `.xnb` under `src_archive/avatar-games` are 39 uncompressed and 146
compressed. The compressed body is **not a bare LZX stream**: it is XCompress
framing - a run of 32 KiB output frames, each introduced by a 16-bit big-endian
compressed length, or by `0xFF`, a 16-bit output length and a 16-bit compressed
length when the frame is short (the last one always is) - and each frame
restarts the LZX bitstream at a byte boundary while the window and the repeated
offsets carry on. MonoGame's `LzxDecoderStream` does exactly this by seeking back
to the frame start after every call, and two independent format notes agree:
libcna's ("an LZX block and an output frame coincide, one block per frame") and
`vs-sr-dev/pc-infiniteundiscovery`'s `docs/formats/slz.md` ("this is the same
framing XNB files use for LZX. It belongs to XCompress, not to LZX"). Handing
those prefixes to the codec as block headers is why every compressed file failed
before - the first two bytes of a frame are a length, not a header.
`lzx.decompress_frames` reads **all 185**: 39 uncompressed, 143 compressed
version 5, 3 version 4. (This replaces an earlier note here that blamed the
window size and said 92 could not be read.)

Reading the inflated clip is a separate matter, and **all 185 now read**: 42 are
Hazzah's `CustomAvatarAnimationData` (`read_clip`) and **143** are
`DNA.Drawing.Animation.AnimationClip+Reader` (DNA.Common, `read_dna`). Measured on
`Stand0.xnb` (134,564 bytes, 5.333 s at 30 a second):

- after the reader table: `01`, a 7-bit string (`Stand0`), `u32` 30 (frames a
  second), a `TimeSpan` (53,333,334 ticks), `u32` 71 (bones);
- the body is, per bone, `i32 count` and that many records in a fixed order - a
  `Vector3` (12 bytes) translation, a `Quaternion` (16) rotation, and in some
  clips a second `Vector3` (12) scale. The rotations are unit quaternions to
  1e-7, and **all 8,378 scale tracks in the archive hold (1, 1, 1)**;
- **how many tracks a bone carries is not written down anywhere.** 118 clips
  (Avatar Laser Wars 2's 79, Avatar Warfare's 39) carry three; all 25 of Avatar
  Connection's carry two. The walk decides: the track set whose 71 bones end
  exactly on the last byte is the one, and across the 143 clips **no file fits
  both and none fits neither**;
- the `u32` that follows the bone count is the root's translation key count, not a
  frame count. **CORRECTION:** an earlier note here read it as "frames + 2 to + 4"
  on the 36 named clips and called its meaning open. `Stand0` stores 162 for 160
  frames while `Tilt` stores 1 for 100, so the near-agreement is the root track's
  overshoot, not a frame count;
- the "bytes a frame" figure that looked like the obstacle - 766 (`FemaleCry`)
  to 926 (`Clap`) - is just the sum of those tracks' strides.

`dna_probe.py` prints the header and the walk for every DNA clip; `xnb_avatar.py
<clip>` dispatches on the reader name and summarises either layout, e.g. `Clap`: 71
bones, 5,626 rotation keys, 2 tracks, joint 8 turning 40.3 deg on average over 102
keys.

The hand pose still comes from `Idle.xnb` (Hazzah, 181 frames, 71 joints), which
parses byte-identically after the framing change.

## The 193 holes, cross-checked in Ghidra (2026-11-18)

The 2008 corpus holds 3,095 functions (88,204 lines) and **193 of them failed**, which was
recorded as 6.24% of functions. That figure has now been measured against the image itself,
by hand and in Ghidra.

**The recipe that works.** Ghidra 12.2 rejects Temurin 21 (`unsupported java version`) and
needs **25**; `support/LaunchSupport` takes `-jdk_home` **with no path argument** (passing a
path is `LaunchSupport received illegal argument`), and reads `JAVA_HOME` instead:

```
JAVA_HOME=<jdk25> support/analyzeHeadless /tmp/ghproj Editor \
    -import /tmp/avatareditor_rebased.exe -processor PowerPC:BE:32:default \
    -scriptPath <dir> -postScript DumpFunctions.java
```

with the PE extracted at `0x3000`, re-based `0x92000000 -> 0x98000000`, and
`DUMP_LIST` / `DUMP_OUT` naming the address list and the output directory. The script is
kept beside this file as `DumpFunctions.java`. Import and analysis took about two minutes
and succeeded first time.

| bucket | count |
| --- | ---: |
| addresses in the failure list | 193 |
| inside `.text` (`0x9803a000`-`0x9813b200`, the sections `ppc_disasm` maps) | 74 |
| in `0x9813b200`-`0x9813c000`, covered by **no** mapped section | 119 |
| Ghidra creates a function there | 81 (44 in `.text`, 37 in the gap) |
| ... and decompiles to C with no `halt_baddata` | **2** (`98055cd8`, `98061950`, both memset-shaped) |
| Ghidra has no function at the address | 111 (30 in `.text`, 82 in the gap) |

So the 6.24% was **not a code figure**: 119 of the 193 addresses sit in the strip between
`.text` end (`0x9813b200`) and `.data` (`0x9813c000`), which `ppc_disasm` cannot read at all
- the list was produced by walking past the end of the text section. Ghidra, whose loader
maps that strip differently, turns 37 of them into functions and finds nothing at the other
82, so the two loaders also disagree about what is mapped there. The honest count of
functions that genuinely would not decompile is **74**, of which Ghidra reads 2.

**Why the remaining 72 stay unreadable: VMX128, not jump tables.** Only 4 of the 193 contain
`lhzx`/`lwzx`, so a switch table is not the common cause; the typical body is `98095858`,
which decompiles its scalar polynomial branch in full and then truncates after four unknown
`altv300_21` ops with `/* WARNING: Bad instruction - Truncating control flow here */`.
Ghidra's PowerPC module has no VMX128 semantics for those opcodes, which is why the count
barely moved.

**Round two (same day): the patch was too narrow, and the dump script had a bug.**
The earlier conclusion here - that the bad data is not the vector block - was wrong for a
second reason: `Capstone`'s linear disassembly **stops at the first word it cannot
decode**, so the `address in valid` test only covered a short prefix of `.text` and every
Xenon form after the first break was patched while the real offenders stayed. Measured
properly over the 74 in-text holes, the words at the truncation points are
**primary 4 (864), primary 5 (418) and primary 6 (611)** - and the patcher only knew
4/12/13, so the two Xenon forms that actually stop Ghidra were untouched.

With primary 5 and 6 added and the decode-limit test dropped (`--force`), 14,009 words are
neutralised instead of 6,819, and the results are:

| run | image | dumped | readable C |
| --- | --- | ---: | ---: |
| 32-bit, old patch | 6,819 nops | 44 of 74 | 2 |
| 64-bit, no patch | - | 8 of 74 | 0 |
| 32-bit, wide patch | 14,009 nops | 43 of 74 | **3** (`98055cd8`, `98061950`, `98095858`) |

So widening the patch buys **one** function. `98095858` now decompiles its whole body, and
the remaining 40-odd stay `halt_baddata` with 24 truncation sites, 10 "subroutine does not
return" stubs and 31 addresses where no function is created at all - because neutralising a
word removes the code, it does not decode it.

**The dump script itself was hiding this.** `DumpFunctions.java` read
`res.getDecompiledFunction().getC()` without a null check, and the decompiler returns null
for the functions it gives up on, so the script died with a `NullPointerException` at the
first such address - every run stopped at 22 of 74 files, which looked exactly like the
runner killing a backgrounded process. With the null check in, a run completes and reports
`DUMP DONE ok=43 missing=31`. Also worth recording: `PowerPC:BE:64:64-32addr` is **worse**
than the 32-bit default here (8 of 74 found), so the corpus's original choice was right.

**Round three: read them linearly instead of asking a decompiler to.**
Neutralising words deletes code, so the answer is not a better patch - it is to decode
the bytes directly and mark only what nobody has semantics for. `decomp_holes.py` walks a
hole one instruction at a time (Capstone decodes a single word at a time, so the sweep no
longer stops at the first Xenon form), emits `VMX-p05(undecoded)` and friends for the
words neither tool understands, and resolves `lis` + displacement / `lis` + `ori` pairs so
data references print as the constant or string they point at.

Across the 74 holes that yields **9,103 decoded scalar instructions and 2,333 marked
vector words** - from functions Ghidra had rendered as `halt_baddata()` one-liners. Two
independent checks say the decoding is right:

- `0x9803da18` contains `0.159155` (1/2π), `fctiwz` rounding, an `fnmsubs` against
  `6.28319` (2π), then `x²` and `x³` building, and a coefficient load from `0x980007a0`
  that reads as **2.75573e-06 = 1/9!**. It ends in `blr` with `f1` = the sum of three
  polynomial terms: **this is the editor's sine**, written as a wrapped Taylor series.
- Colour holes load `0.00392157` (1/255) and `255` together, which is byte-to-float colour
  conversion, not geometry.

`DumpExtents.java` shows why Ghidra's own numbers were misleading: of the 74, **30 have no
function at all** and many of the rest are **8-byte stubs** - Ghidra stops carving a body at
the first bad word, so "44 found" never meant 44 readable functions.

**How much of this actually has to be read.** `hole_callers.py` counts direct `bl` sites
across `.text` and 4-byte pointers in `.rdata`/`.data`. Result: **8 of 74 holes have
neither** (`0x9805e060`, `0x980e5448`, `0x98120c80`, `0x98138ab8`, `0x98139210`,
`0x98139a18`, `0x98139c50`, `0x9813b1c8`) - dead code, and therefore not part of the
editor's behaviour. **66 are live** and are the real remainder. Per-hole counts are in
`artifacts/decomp/HOLES-callers.md`, listings in `artifacts/decomp/holes/`.

**Correction to the total, from this work.** The address list carried `0x98062658` twice, so
there are **73 unique holes in `.text`**, not 74. With the 119 unmapped addresses that
makes **192** holes in total; the long-standing "193" in this document was the duplicate
line, not a third category. Re-run against the de-duplicated list the decoder reports
**9,059 decoded scalar instructions** and the caller scan **8 unreferenced of 73**. The
deduped list is now committed at `artifacts/decomp/holes.txt` so the count cannot drift
again.

**Classification pass, with the caller as the witness.** Because most callers are already
readable, each hole can be identified from how it is called (`artifacts/decomp/HOLES-usage.txt`
is the raw evidence). Confirmed from call sites:

| hole | identification | evidence |
| --- | --- | --- |
| `0x9803da18` | **`sin(double)`** | called as `(double)FUN_9803da18(dVar3)`; 1/2π then an `fnmsubs` against 2π (argument wrap), coefficient 1/9! |
| `0x98095140` | **`pow(double,double)`** | loads `1.44269` = 1/ln 2; callers pass integer exponents `2.0`, `3.0`, `32.0`; double in, double out |
| `0x98061950` | **`memset(ptr,0,len)`** | `FUN_98061950(ptr,0,0x1c)` and `FUN_98061950(ptr,0,*(u16*)(x+0x24))` |
| `0x98062658` | **allocator, 0xbc-byte object** | `FUN_98062658(0xbc)` result is dereferenced; also `param_1 = FUN_98062658(param_1)` |
| `0x980b9da0` | **enumerate into array, HRESULT** | fills a stack buffer via `0x980b9c40`, allocates `2*(n+1)`, returns `0x8007000E` (`E_OUTOFMEMORY`) |
| `0x9808a118` | **setter on member `+0xc`** | `FUN_9808a118(*(undefined4 *)(param_1 + 0xc))`, and a variant passing `1.0` |

Second batch, from call-site context:

| hole | identification | evidence |
| --- | --- | --- |
| `0x98065ca0` | **error-path handler** | exactly two call sites in the whole binary, both `FUN_98065ca0(0,0,0,0,0)`, both immediately after a failed `FUN_980673e0` check |
| `0x9805bd20` | **16-byte copy-out (quaternion / float4)** | `FUN_9805bd20(*(undefined4 *)(param_1 + 0x1050),auStack_30,0x10)` immediately after that member is assigned |
| `0x98055cd8` | **switch dispatcher, 56 cases** | its own (partly readable) body does `uVar7 = param_1 - 2; if (0x37 < (uVar7 & 0xffffffff)) return 0;` - index range 2..0x39 |
| `0x98055ef8` | **setter on member `+0xc`** | `FUN_98055ef8(*(undefined4 *)(iVar4 + 0xc), value)` in three different callers |

### A VMX128 processor module replaces the hand decode for these words

Everything above assumed stock Ghidra could not decode Xenon vector words, so they were
hand-listed and marked `VMX-p0N(undecoded)`. That assumption no longer holds. The
`freeqaz/ghidra` fork carries `vmx128.sinc` (2,734 lines, 77 opcodes with p-code) and
`ppc_64_xenon.slaspec`, plus a `PowerPC:BE:64:Xenon` language. Only two files plus one
ldefs block are needed, and the `.sla` compiles with Ghidra's own SLEIGH tool - no full
Ghidra rebuild. `install_xenon_language.sh` in this directory does the whole install and is
idempotent.

| run on `avatareditor.xex` | dumped | decompiled readable | body instructions | undecoded body words |
| --- | ---: | ---: | ---: | ---: |
| stock `PowerPC:BE:32:default` | 43/73 | 3 | - (truncated at first bad word) | every `altv` word |
| `PowerPC:BE:64:Xenon` | 72/73 | **59** | **7,691** | **0** |

`CountBody.java` counts instructions inside the 73 bodies in the Xenon project:
`total=7691 altv=0 undef=0`. **The 2,333 hand-marked vector words are gone: every word in
these bodies now decodes.** 12 files still fail to decompile and 2 addresses still have no
function, but for other reasons (noreturn shapes, decompiler complexity), not undecodable
bytes.

What the switch buys in readable code: **445 vector operations with real semantics**, e.g.
`vectorMultiplyAddFloatingPoint` (121), `vectorRotateLeftImmediateMaskInsert128` (83),
`vectorConvertFromSignedFixedPoint128` (71), `vectorSplatImmediateSignedWord128` (53),
`vectorNegativeMultiplySubtractFloatingPoint` (34), `vectorUnpackD3D128` (23).

**Resolved: those 650 were not compares, they were misdecoded VMX128 loads.** The six
`altvNNN_MM` names come from constructors in upstream `altivec.sinc` - ISA 2.07 `vcmpne*`
and `vcmpequd` - whose bit patterns also match Xenon 128-bit loads/stores, and they win the
match. Measured over every such word in `.text` (2,226 of them, not just the 650 inside the
73 holes):

| property | measured |
| --- | --- |
| primary opcode | 4 for **2,226 / 2,226** |
| low two bits | **`0b11` for 2,226 / 2,226** - the VMX128 load/store signature |
| distinct 7-bit opcode fields | **6**, sitting on load/store values: `12` = `lvx128` (505), `64` = `lvlx128` (877), `68` = `lvrx128` (57), plus `24`, `80`, `84` |
| vector register under the VMX128 reading | **> 31 for 2,226 / 2,226** (mostly vr58-vr63) - impossible for AltiVec's 32 registers |

A binary compiled in 2008 cannot contain POWER8 instructions, and AltiVec cannot name
vr61. Disabling the 13 colliding constructors fixes the decode:

| | dumped | readable | `altv` placeholder calls in dumps |
| --- | ---: | ---: | ---: |
| stock `PowerPC:BE:32:default` | 43 | 3 | 0 (bodies truncated) |
| Xenon, collision present | 72 | 59 | 650 |
| **Xenon, collision disabled** | **72** | **59** | **0** |

Spot checks that used to be compares: `0x9803da78` = `lvx128 vr61,r0,r8`, `0x9809f600` =
`stewx128 vr62,r0,r3`, `0x9805bc20` = `stvrx128 vr50,r30,r29`. Program-wide counts now read
`lvx128` 910, `stvx128` 608, `stvlx128` 146. The readable count stays 59 because a compare
and a load are equally decompilable - what changes is that the code now *means* the right
thing, which is what the earlier "650 unknown operands" blocked.

`install_xenon_language.sh` applies this patch automatically, and the stock `altivec.sinc`
(and every other stock language source) is backed up outside the Ghidra tree at
`/tmp/lang_stock_backup` - it has to be outside, or Ghidra finds two `ppc.ldefs` files and
reports every stock language as "previously defined".

### The last 13 failures, and why they failed

The PE section table explains most of them. `.text` declares `vsize=0x1011dc` from VA
`0x3a000`, so it ends at **`0x9813b1dc`**, while `.data` starts at **`0x9813c000`**. The
`0xE24` bytes between are inside `.text`'s virtual size but have **no bytes in the file** -
`D.load(...).read(0x9813b200, 0xE00)` returns 0 bytes. That region is the loader-filled
import trampoline area, and `.text` reaches it by tail-jump: **147 distinct target addresses**
in the gap are referenced by control flow from `.text`. Nothing there can be decoded from the
shipped file.

Two rules then closed most of the gap, both measured rather than assumed:

1. **Noreturn tails.** A function whose last instruction is `bl` followed by zero padding has
   no `blr` - the compiler knew the callee never returns (throw/exit chains). Sweeping for that
   shape finds **5 callees**; marking them `no return` makes the callers decompile. This fixed
   `0x98062658`, `0x980f2ab8`, `0x98065ca0`. (An earlier hypothesis - that the *trampolines*
   were the noreturn functions - was tested and disproved: 0 of them carried the flag.)
2. **Modelled imports.** `ModelImports.java` creates an `IMPORT_TRAMPOLINES` block over the
   empty gap, writes a `blr` at each of the 147 referenced targets and names every one
   `unresolved_import_<addr>`. This is a modelling assumption, not recovered data - the bytes
   are known to be absent - and the names say so. It turned `0x9805bd20`, `0x9805be30`,
   `0x9805bef8`, `0x9805c648`, `0x9805e060`, `0x9813a290` into clean decompiles.

Current state of the 73 holes:

| | count |
| --- | ---: |
| decompile cleanly | **68** |
| still carry `halt_baddata` | **4**: `0x98065ca0` (17 statements, one unresolved-import path), `0x9813b1c8` (2), `0x98125240` (8) and `0x9812ae50` (19) - both jump tables hit Ghidra's "sanity check requires truncation" |
| no function created | **1**: `0x98120c80` |

Note the thunks (`0x9805c648` etc.) decompile to a single statement on purpose - their body
really is one tail call into `unresolved_import_*`.

**What is left after the collision fix:** zero `altvNNN_MM` operands in the 73 hole dumps,
so there is nothing left to identify by hand in these functions. The remaining limits are
elsewhere and are unchanged: 12 of the 73 still fail to decompile (noreturn shapes and
decompiler complexity, not undecodable bytes) and 2 addresses still have no function. The
fork itself is GPL, matching Ghidra, and is a fork rather than an upstream module - if the
Ghidra install is reset, `install_xenon_language.sh` must be re-run.

Consequence for the workflow: **re-import with `PowerPC:BE:64:Xenon` from now on.**
`decomp_holes.py` stays in the tree as the fallback for any install without the module, and
the `VMX-p0N` markers in older listings describe only the stock-language run.

### Second classification pass: the next 20, in caller order

Each row is what the call sites and the listing establish. "shape" means the signature and
constants are measured but the purpose is still unresolved - recorded rather than guessed.

| hole | identification | evidence |
| --- | --- | --- |
| `0x9804d2f8` | **the 46-case dispatcher / colour gate** | entry does `addi r11, r4, -1` (switch on `param_2-1`); 8-parameter signature; `decomp_gaps.py` reads a 46-case table at `0x98002980`, base `0x9804c73c`; callees include `0x98055ef8` (+0xc setter) |
| `0x9805c648` | **import thunk** | whole body is `li r4,3; b 0x9813b47c` |
| `0x9805bef8` | **import thunk, arg-shifting** | `mr r8,r7 / mr r7,r6 / mr r6,r5 / mr r5,r4 / li r4,0 / b 0x9813b46c` |
| `0x9805be30` | **import thunk** | entry is `b 0x9813b45c`; caller passes `(DAT_98148400,0,1,0,99,buf,out)` |
| `0x9808c178` | **16-byte-stride table lookup, base +0x78** | prologue `addi r10,r4,0x78; slwi r10,r10,4` |
| `0x9808c258` | **same lookup, base +0x178** | identical prologue with `addi r10,r4,0x178` |
| `0x9803faa8` | **builds a 64-byte matrix into a caller buffer** | caller declares `undefined1 auStack_50[64]` and calls `FUN(param_2,param_1,auStack_50)`; 4 call sites, all geometry code |
| `0x9808e288` | **bounded copy against a stored capacity** | entry `ld r11,0(r3); cmplw cr6,r4,r10; bge`; called as `FUN(buf+0x2e30, off, off+len)` |
| `0x980813e8` | **object teardown** | `void FUN_980813e8(int)` called as `FUN(*(u32*)(obj+0x3c))` right after `FUN_98083d68(...,0)` / `FUN_98083da8(...,0)` clear the same field |
| `0x9805d154` | **unaligned-size error path** | only call site is the `else` of `if ((param_2 & 0xf) == 0)`, whose `if` branch calls `0x9805ce30` |
| `0x98058268` | **angle helper (π/2)** | resolves `1.5708`; calls `0x98057c18`, `0x98063ac8`, `0x98063b14` |
| `0x9803ee60` | shape: two objects + `300,600` + two out-params | `FUN(uVar1,uVar2,300,600,local_30,local_2c)`, result tested `if (-1 < lVar3)` |
| `0x98043b70` | shape: bool-returning builder over an array | called as `cVar1 = FUN(param_1,puVar4), cVar1 != 0` then `*puVar4 = 0`; 24 callees incl. the `+0xc` setter; constants `1, 6, 0.02` |
| `0x98072978` | shape: coefficient-driven transform on `this+0x470` | loads `0.6, 1.0, 1.4, 1.5, 1.6, 1.8, 1.9, 2.2`; `li r11,0x47`; `addi r10,r3,0x470`; only caller is a 2-line noreturn stub |
| `0x98075890` | shape: per-frame update taking a `double` | `FUN(param_1,double param_2,param_3,param_4,param_5)`; callees `0x98075260`, `0x980753f0`, `0x98058a48`; constants `1, 1e-05` |
| `0x98078670` | shape: no-argument initialiser | called bare as `FUN_98078670();` before `FUN_9808c338(param_3,0,local_50,1)`; calls `0x98085090`/`0x98084ee8` eleven times each |
| `0x9807b318` | shape: `0.5`-weighted two-buffer op | constants `0.5`; callees `0x98111258`, `0x98111338` |
| `0x98042498` | shape: render-state call cluster | 12 readable callees, all in `0x9808xxxx` |
| `0x9804a010` | shape: 2.3927-radian geometry path | constants `2.3927, 5, 8, -1`; calls `0x9803faa8` (matrix builder) and `0x9805c5a0` |
| `0x9803f920` | unresolved | only caller resolves to itself; body loads VMX state and calls `0x9803f540` |

**Structural finding from this pass:** the block at `0x9813b3xx-0x9813b4xx` that the 119
"unmapped" addresses live in is an **import/thunk table**, and `.text` reaches it by
tail-jump, not by `bl`. Nine distinct `b 0x9813b...` targets appear from the holes alone
(`bcfc`, `b6bc`, `b47c`, `b46c`, `b45c`, `b40c`, `b3fc`, `b3cc`, `b1f4`), which is why
counting only `bl` sites under-reports those functions and why Ghidra creates no body for
them.

**A hypothesis of mine that the data killed:** `0x98072978` looked like a tail-call thunk
because its only caller is a two-line function marked "subroutine does not return". Its
listing is not a thunk - it builds stack slots, loads `1.0`, sets `r11 = 0x47` and addresses
`r3 + 0x470`, so it is real code operating on a `this` pointer. Recorded as unclassified
rather than forced into a name.

Family-level only - argument marshalling identifies the shape, not the semantics, and is
labelled as such: `0x980f0480`, `0x980f0638`, `0x980f0888`, `0x980f0a50` load constants
`8 / 0x10 / 0x20 / 0x30 / 0x40` into GPRs and pack vector registers, i.e. **vector
constructors** taking 3-4 floats; `0x980f0760` references one global (`0x98025c70`) and is a
matrix helper. `0x98095a28` (readable) is the reason `pow` matters: it branches at `|x|=1`
and `2` and combines `pow(x,2)` with `pow(|x|,3)` into a falloff curve.

Earlier note: `0x980b9da0` calls `0x980b9c40` to fill a stack buffer,
allocates `2*(count+1)` bytes, stores a 16-bit count and returns `0x8007000E`
(`E_OUTOFMEMORY`) on a failed allocation - an enumerate-into-array helper with HRESULT
returns.

**Two patch experiments, both negative.** `patch_vmx128.py` was extended to take
`--text-offset/--text-size/--text-va` so it can run on the PE (`.text` raw `0x39400`,
`0x101200` bytes, VA `0x9803a000`) instead of only on the `mkelf.py` ELF, and the 74
in-text holes were re-imported twice:

| image | words neutralised | functions dumped | readable C |
| --- | ---: | ---: | ---: |
| as re-based | 0 | 44 of 74 | 2 |
| undecodable vector words -> `nop` | 6,819 | 44 of 74 | 2 |
| every primary-4 word -> `nop` | 6,819 (identical) | 44 of 74 | 2 |

The two patch runs neutralise the same 6,819 words: every primary-opcode-4 word in
`.text` is already one Capstone cannot decode, so the wider flag is a no-op and was
removed. And with them all gone `98095858` still ends in
`/* WARNING: Bad instruction - Truncating control flow here */`, so the bad data is **not**
the primary-4 vector block at that time. (Round two above corrects this: the offenders are
primary 5 and 6, and widening the patch does reach one more function - `98095858` - which is
the size of the gain a byte patch can buy. Ghidra does decode the Xenon vector forms into
`altvNNN_M(...)` calls; what it cannot do is give them semantics, so a patched word is
deleted code rather than decompiled code.) The remaining holes need instruction semantics.

**Ghidra cannot recover these jump tables, and the hand decoder can.** `FUN_9804d2f8` comes
back from Ghidra as

```c
void FUN_9804d2f8(void) { /* WARNING: Subroutine does not return */ FUN_980618cc(); }
```

- a stub. `decomp_gaps.py` reads the same function as a 46-case table (`98002980`, base
`9804c73c`) and hands back each case's target, strings and first calls. That is what produced
the button-template findings in `COLOURS.md`, so the hand tool stays the instrument of
record for dispatchers and Ghidra is the cross-check, not the other way round.

**What this means for the colour work.** Of the eleven functions on the colour path
(`9807fee0`, `98058590`, `980585e8`, `98056298`, `98057418`, `980a3750`, `980a36f0`,
`980bf648`, `980c3e78`, `98055848`, `9804c8b4`), only `9804d2f8` was ever in the failure
list, and it is now decoded by hand. So the colour path is at 100% readable code and the
"no baking until decompilation is done" rule is met for colours; the 72 remaining holes
are in other code (vector and blend maths), and they cannot be closed by patching or by
re-importing - that needs a PowerPC module with Xenon vector semantics. `decomp_gaps.py
--all` now reports `1/74` and states the 119 skipped addresses rather than `1/193`.

## The brick walls

1. **The XTL renderer's corpus has the same defect and its input is gone.**
   `UniKron-decompiled-xtl-avatar.zip` (6,618 functions for
   `default_uncompressed.xex`, the avatar renderer itself) holds 2,602
   `halt_baddata` stubs - 39% - because it too was imported as 32-bit PowerPC.
   Re-running it needs the image, and `default_uncompressed.xex` is not in
   `src_archive`: it came from the gift `avatar.zip`, which is no longer on this
   machine. With that file the same recipe applies (base from `mkelf.py`,
   `PowerPC:BE:64:64-32addr`, then `patch_vmx128.py`), and it is the corpus that
   would answer the shader questions the editor cannot.
2. **`NXE.exe` (42 MB) is decompiled in full: 39,611 functions**, in
   `UniKron-decompiled-nxe-dashboard.zip` beside the other corpora. The first
   attempt was killed by a runner restart at 7,202, and the run had
   `-deleteProject`, so it was lost; the second used `DecompileResume.java`
   against a kept project, which skips functions already written and resumes.
   That run wrote 32,409 new files and skipped the 7,202 already on disk, with 5
   functions failing to decompile.

   It still holds no avatar lighting: `AmbientLight`, `SunLightDirection`,
   `lightColour`, `texEye` and `XtlEffect` match **zero** files across all
   39,611. The dash's scene names live in XUI data and the effect names in the
   `.updb` blobs, so the corpus could not have handed over the rig.
3. **The closet index has the category bitmask but not the bit names.**
   `closet_index.tsv` is `id, categories, bodies, name`. **Corrected:** the third
   column is not a source class, it is `avatarBodyType` - `3` is male+female and
   `1`/`2` are one body each, which is why the caps, helmets and glasses counted
   above sit at `3` while shirts and shoes split across `1` and `2`. The category
   mask is column two, and it is not independent data either: it is the GUID's
   first four bytes in hex (the Hub's importer writes
   `parseInt(guid.slice(0, 8), 16)`), so each item carries its categories inside
   its own id. The port logs the same pair at startup as
   `[avatar] enum assets cats={:#x} bodies={:#x} closet={}`.

   **The bits themselves are mapped** - see the slot table at the top of
   `CATALOG.md`, read out of the pack's own `AssetMetadataVersioned` masks and
   corroborated by the gender byte (0x0001 glasses, 0x0002 wristwear, 0x0004
   earrings, 0x0008 rings, 0x0100 head, 0x0200 body, 0x0400 hair, 0x0800 torso,
   0x1000 legs, 0x2000 feet, 0x4000 hat, 0x8000 gloves, with multi-bit
   combinations for outfits). Under that table the closet sample reads
   consistently: `Halo Spartan Armor` at 0x00000ffc is a full set (head, body,
   hair, torso, legs, feet, earrings, rings). So what is missing is only the
   retail *wording* of a category, not its meaning, and the wording's transport is
   now known too: the port builds `/live/{:08x}/avataritems/{}.acp` and reads the item's
   metadata from the **response headers** `X-Avatar-Item-Name`,
   `X-Avatar-Item-Categories`, `X-Avatar-Item-Bodies` (its local server, 
   `rex::kernel::xam::ServeAvatarItem` on `/avataritems/`, answers with them and
   logs `[avatar-store] no local item for {}`). Online mode talks to
   `avatar_marketplace_server` with `X-Marketplace-Key`; the manifest it serves
   is `JMstudios.marketplace.v1` (key label `JMKEY1`) and the catalogue query is
   `methodName=FindGameOffers` with `&Names=NameFilter&Values=` and a
   `<totalItems>`    reply. CORRECTION: the retail *wording* **is** on the disc, and an earlier note here
   said the opposite. `avatareditor.xex` keeps its UI strings as **UTF-16LE**, and
   a search for ASCII strings cannot see them; `xex_ui_strings.py` reads them into
   `editor_ui.json` (3,660 strings). The image names its own categories - `body`,
   `hair`, `faceshape`, `facial`, `nose`, `ears`, `eyes`, `eyebrows`, `mouth`,
   `facial_hair_male`, `facial_skin_male`, `tops`, `bottoms`, `shoes`, `hat`,
   `glasses`, `gloves`, `ring`, `watch`, `earring`, `body_access`, `head_access`,
   `makeup`, `lipstick`, `eyeshadow`, `colour_palette_skin`, `malecostume`,
   `femalecostume`, `loadoutfit`, `saveoutfit` - each with the states
   `_selected.png`, `_unselected.png` and `_pressdisable.png`, and spells the
   labels too (`Headwear`, `Hairstyles`, `Tops`, `Bottoms`, `Skin Color and Body`,
   `Lip Color`, `Eye Shadow Color`, `Carryables`, `My Outfits`, `Costumes`).
   So the wording needs no service at all. The bits still mean what the pack's
   own table says they mean, and the colour screens are palettes rather than item
   lists - `CATALOG.md` records both corrections.

   **CORRECTION - the palette *values* are in the image after all.** The paragraph
   that stood here recorded a measured negative: a scan of all 15.8 MB of
   `avatareditor.xex` for runs of six or more opaque *warm* ARGB words found none,
   and concluded the swatches came from the theme or the `.xui` files. The scan's
   shape was wrong, not the data missing. `xex_palettes.py` reads eleven ARGB tables
   out of the image's read-only data - a (pointer, count) index at file `0x21c68`,
   data at `pointer - 0x97FFD000`, every entry verified as `count` opaque words.
   Nine of them are the nine colour slots the `.Avatar` descriptor stores at
   `+0x0fc`, proven by a cross-check: **all 27 colours of the three shipped retail
   profiles are members of the table at their own slot index.** Full tables, the
   nine screen labels and the one part still uncertain (whether the body colour is
   replaced or multiplied) are in `COLOURS.md`. The editor's real filter is `AeSearchSet` in the port DLL, which
   works on loaded asset metadata. The full dashboard corpus also names
   the source of that metadata: `FUN_142529e40` builds
   `/live/{:08x}/avataritems/{}.acp`, and the port's own settings carry
   `CatalogCDNUriRoot`, `AvatarAssetUriRoot`, `AvatarMarketplaceManifest`,
   `ManifestUriPath` and `PreviewUri`. A port log line states the closet layout
   plainly - "Imported marketplace and award items -- props, outfits, shirts,
   trousers, shoes, accessories -- as <guid>.bin plus closet_index.tsv" - so the
   folder we have is that import, and the per-item manifest it was built from is
   not in the dump. The closet can be named and iconned today, but not sorted into
   the editor's categories without that.
4. **`metro2010/assets/avatareditor.xex` is encrypted.** Its PE begins at
   `28672` as ciphertext. Six LZX attempts (offsets 28672/28696/28720 at 1 MiB
   and 4 MiB output) all fail with `bad aligned table` or `bad block type`.
   What this needs: the decrypted image, or the console's XEX keys. Nothing in
   the archive supplies either.
5. **The remaining 21 third-party PEs** - `XBOX HUB.exe` (238 MiB),
   `dxcompiler.dll` x2, `dxil.dll`, `vk_swiftshader`, `vulkan-1`, `ffmpeg`,
   `d3dcompiler_47`, `SDL2`, `iCUESDK`, the MSVC runtimes and
   `xenia_canary_netplay.exe`. That is Chromium, DirectX tooling, an emulator
   and redistributables: ~300 MiB of other people's code whose decompilation
   would run for hours and say nothing about the avatar editor. Everything
   first-party is done.

| `default_uncompressed.xex` (avatar.zip dump) | xtl avatar renderer, 2008 SDK | 6,618 |

## The port's own runtime, and where the categories live

`rexruntime.dll` from the `Clean Slate NXE` build is decompiled too: **28,447
functions**, shipped as `UniKron-decompiled-rexruntime.zip`. It holds the
`XamAvatar*` entry points the editor calls, and a string in it spells out what
they are worth: `XamAvatarGetAssetsResultSize`, `XamAvatarGetAssets` and
`XamAvatarManifestGetBodyType` are bare stubs that return success without
filling their out-parameters. `XamAvatarGetAssets_entry` confirms it - it
returns 0 or 0x8007065b from one flag and writes nothing else.

The real enumeration is on the editor side. **`BeginEnumAssetsV1`**
(0x180637410 in `nxe_dash_avatareditor.dll`, 977 lines) is what builds the list
the editor browses, and it logs

    [avatar] v1 enum cats={:#x} bodies={:#x}: {} stock + {} closet item(s), {} as outfits

Reading the function settles what those masks are. They are **the request's own
filters**, not something the port works out per item: the two values are ANDed
against each stock record's fields (`(filter & record[+0]) != 0` for category,
`(filter & record[+4]) != 0` for body), over a table of 216-byte records that
is built at runtime (the globals hold heap pointers). The guest supplies the
category bits, so the *labels and their order live in the guest's XUI*
(`$flash_dash.xex`), which is encrypted. The stock counter is the one
incremented inside that loop; the "closet item(s)" and "as outfits" figures are
passed to the log from counters built elsewhere, and the wording is the port's
own - it does not show closet items carrying category bits.

So the retail assets and the port agree: an item carries no category. The
division is: bits and labels in the guest UI, geometry and names in the
closet, and the port only matching one against the other.

## The avatar manifest, from `XamAvatarSetManifest_entry`

The editor does not save a settings file; it hands the port a manifest, and the
port writes it. `XamAvatarSetManifest_entry` (0x18062c4b0, 70 lines) shows the
shape of that buffer:

- The **body component sits at +0x120** - a u32, two u16s at +0x124 and +0x126,
  and a u64 at +0x128. If all of them are zero the manifest is rejected with
  "buffer at {:#x} has a zero body component; not persisting (unexpected
  layout?)", which is the port telling us it knows the layout and this was not
  it.
- Otherwise the port **copies exactly 1000 bytes** (0x3E8) into its cached
  manifest, sets a loaded flag, and persists it. The file it writes is
  `avatar_manifest.bin` in `<user_data_root>\\avatar`, described as "the manifest
  the Avatar Editor saves and every game then loads as the local user's avatar".
- Worn assets inside it are keyed by the same GUID the closet is keyed by - a
  u32, two u16s and eight bytes - and the enumerator looks each one up in the
  closet, fetching it from the marketplace when it is missing: "worn item {} is
  not in the closet, fetching it: {}".

The 1000-byte size and the +0x120 body component are the two numbers a theme
needs to write a manifest the port would accept.

`rexgpu-xenos.dll` (2.7 MB) is decompiled as well: **4,848 functions**, in
`UniKron-decompiled-rexgpu-xenos.zip`. It is the part that patches the guest per
title, and its own notes name the editor's values - "the Metro dashboard uses
11028, the Avatar Editor 10900" for the D3D work-retired handler offset.

`nxe_dash_LivePack.dll` (16 MB) is decompiled too: **8,072 functions**, in
`UniKron-decompiled-livepack.zip`. It is the local Live/marketplace responder,
and its only avatar contact is an import of `XamAvatarManifestGetBodyType` -
no avatar catalogue of its own, so it adds no category data.

That closes every first-party binary in the dump: dashboard 39,611, runtime
28,447, LivePack 8,072, GPU 4,848, editor DLL 10,550, editor XEX 3,095. What
remains encrypted is the flash XUI (18 files) and the 2010 editor XEX.

## The port's avatar engine is inside the 2010 PC build

The 20,381-function corpus for `metro2010/avatareditor.exe` was searched for
avatar strings only as ASCII category labels before, which found nothing. It is
not a guest-facing shell: it is a rexglue build of the editor with the port's own
avatar implementation compiled in, and its source paths name every part of it.

    src/kernel/xam/avatars/asset_pack.cpp          LoadAssetPackFromMemoryV1/2/3
    src/kernel/xam/avatars/model.cpp               rex::avatars::Model::Load
    src/kernel/xam/avatars/texture.cpp             rex::avatars::Texture::Load
    src/kernel/xam/avatars/skeleton.cpp            rex::avatars::Skeleton::Load
    src/kernel/xam/avatars/closet.cpp              rex::avatars::Closet::Load
    src/kernel/xam/avatars/blend_shape_apply.cpp   the shape application
    src/kernel/xam/avatars/guest_load_asset.cpp    rex::avatars::LoadAssetsToGuest
    src/kernel/xam/avatars/guest_load_animation.cpp
    src/kernel/xam/xam_avatar.cpp, src/xui_hooks.cpp

Three findings already fall out of the strings, before any body is read:

* **The pack has three stored versions**, and the loader selects between them:
  "avatar asset pack V1/V2/V3: cannot load file header / asset headers / asset #N,
  buffer too small". So the 2010 retail pack whose 13.4 MB region is still
  unread is a *versioned container*, not a bare record table, and the three
  loaders are the specification for it.
* **Hiding shapes are real, and attached two ways**: "failed to load embedded
  hiding shape {} for closet item {}" and "failed to load hiding shape {} for
  component {}". The port loads a hiding shape from the item's own payload and,
  separately, one per body component - which matches block 4 naming covered body
  vertices, and means a closet item can carry its own.
* **The port fits old bodies to the new one by measurement**: "old-body candidate
  does not match the legacy body either (tucks {:.1f}cm from legacy); falling
  back to affine fit". `FUN_140dbf2e0` is that routine, 922 lines.

The shape parser is readable enough to pin the record down. In `LoadAssetsToGuest`
(`FUN_140dd7e60`, 3,005 lines) the payload is walked in 4-byte steps into
`FUN_140dbe9d0`, and on success:

    if (*(int *)(shape + 4)    == 0x02000000) *(u16 *)(shape + 8)    = 0;
    if (*(int *)(shape + 0x34) == 0x02000000) *(u16 *)(shape + 0x38) = 0;

Two type tags at +4 and +0x34, each followed at +8 and +0x38 by a u16 the port
zeroes. That is the same nested two-header shape block 4 showed (the pack's own
header repeats 32 bytes in), and the zeroed u16 is the count of what follows -
so a shape record is `tag, tag-class, u16 count` and the port clears the count
rather than the data. Reading `blend_shape_apply.cpp`'s two functions
(`FUN_140dbf2e0`, `FUN_140dbf3b0`) to get the vertex update itself is the next
step, and it is now a code-reading job rather than a format question.

## What a shape entry does, from `blend_shape_apply.cpp`

`FUN_140dbf2e0` (922 lines) is the only function that names
`blend_shape_apply.cpp`, so it is the applier, and its inner loop settles three
things the format alone could not:

    uVar17 = (ulonglong)(int)*puVar26;
    uVar17 = uVar17 / *(uint *)(*(longlong *)(*local_118 + 0x28) + 0x28);   // / stride
    puVar26[1] = (float)puVar26[1] - local_188[uVar17*3]      + *(float *)(local_1a8 + i*0xc);
    puVar26[2] = (float)puVar26[2] - local_188[uVar17*3 + 1]  + *(float *)(local_1a8 + i*0xc + 4);
    puVar26[3] = (float)puVar26[3] - local_188[uVar17*3 + 2]  + *(float *)(local_1a8 + i*0xc + 8);
    puVar10 = puVar10 + 8;                                                  // 8 dwords = 32 bytes

* **The stored number is a byte offset, not a vertex number.** The port divides
  it by the model's stride, read from the model object at `+0x28`. Checked
  against the pack: **9,870 entries across all 215 non-empty shapes, every one a
  multiple of its stride** (40 for the body, 52 for the head), so the field is
  `vertex * stride` and `decode_shape`'s `offset // stride` is the same rule.
* **A vertex moves by `target - source`**, component by component. Applied to a
  bind-pose model, where the source is the vertex's own bind position, that is
  simply `vertex := target`, which is what `bake_avatar.py --shape` already does.
  The C is the general form because the port also fits old-body assets whose
  positions are not the new body's bind positions.
* **The port's vertex is 32 bytes** (8 dwords: position at +4, +8, +12). The
  pack's body stride is 40 and its head stride is 52, so the port is loading a
  converted, position-plus-skin layout, not the pack's vertex verbatim - which is
  why the two numbers are not the same and neither is a contradiction.

The fitter around it is a tolerance test, not a heuristic guess: it measures the
mean distance from each candidate position to the source shape and compares it
with `DAT_140f7b2f4`, logging "tucks {:.1f}cm from legacy" and falling back to an
affine fit when the candidate is not close enough. So a shape whose target
positions do not correspond to the body it is applied to is detected, not applied
blindly.

Two consequences for this repo. `--hide` deletes the body triangles a hiding
template names, which reaches the same picture the retail path does by *moving*
those vertices to their target positions - but the retail path is the shape
apply, and the 38 vertices the formal trousers name are all it moves, which is
why the thighs still show. And a shape whose stride does not match the asset it is
applied to should be refused rather than applied, which `--shape` does not check
yet.

## The pack container, from `asset_pack.cpp`

The three loaders are in the corpus and the version numbers are read from the
file, so the 2010 pack's own header decides which one applies. Ours is **V2**
(`u32 @ 0x10` is 2), and `LoadAssetPackFromMemoryV2` (`FUN_140dbcbe0`) gives the
layout:

    header   0x28 bytes, asset count as a big-endian u32 at +0x1c
    table    count records of 0xF8 (248) bytes, starting at +0x28
    record   +0x00 u32 00000002, +0x04 01 01 01 00 ...   (version, gender, class)
             +0xF0 u32 offset, +0xF4 u32 size   (both big-endian)

Tested against `metro2010/assets/AvatarAssetPack.toc`, 13,648,884 bytes:

* count `1282`, so the table is `0x28 + 1282 * 0xF8 = 317,976` bytes;
* **1,079 of the 1,282 records have a size** - the same 1,079 assets every other
  tool in this repo already walks;
* the first record's offset is `539,596`, which is exactly the `MaleBody` offset
  in `asset_catalog.json`, so this is the same table `pack_toc.py` reads, now
  with its field names known;
* the last payload ends at `13,648,884` - **the file's final byte, exactly**, so
  the pack is header, table, then contiguous payloads with nothing else in it.

V3 differs in two constants - 0x30 header and 0x10C records, with offset and size
at +0x104 and +0x108 - and V1 has the same shape as V2 with the smaller record, so
a pack of any of the three versions can be walked from these numbers alone.

That also settles what the earlier note called "the 13.4 MB from 0x12fa42 that is
not plain records". Every asset payload in this pack starts at a table-supplied
offset and the chain ends exactly at EOF, so that region is not an undecoded
stream at all: it is the assets themselves, each already located by the table.

## The V2 record, field by field, and the name pool between table and payloads

`LoadAssetPackFromMemoryV2` assembles a 0xD8-byte in-memory asset per record and
copies from named offsets, which names the fields:

    +0x00 u32   version, 2
    +0x04 u8 x4 gender, class, ...        (MaleBody reads 01 01 01 00)
    +0x07 145 B copied verbatim into the asset struct
    +0x98 u32, +0x9C u32                  (byte-swapped, stored as one pair)
    +0xA0 u64, +0xA8 u64, +0xB0 u64
    +0xB8 u32
    +0xC0 u32
    +0xF0 u32   payload offset
    +0xF4 u32   payload size

Read against record 0 (`MaleBody`) those last fields are `+0xA0 = 0`,
`+0xC0 = 317,976`, `+0xF0 = 539,596`, `+0xF4 = 33,088`. 317,976 is the exact end
of the record table, and the first payload starts at 539,596 - so **the 221,620
bytes between them are the name pool**, and `+0xA0` is an offset into it.

The pool is **UTF-16 big-endian, NUL-terminated**, and it opens with:

    MaleBody, FemaleBody, Head, Animation Generic Stand 0, Stand 1, Stand 2,
    Animation Generic Clap, Animation Generic Wave, ...

`MaleBody` sits at pool offset 0, which is why record 0's name offset is 0, and
`+0xC0` holding the pool base is what makes that offset absolute.

So the pack is, in order: 0x28 header, `count x 0xF8` records, the UTF-16BE name
pool, then the payloads back to back ending exactly at EOF. Every asset's name,
offset and size come from its own record, and nothing in the file is left
unaccounted for.

### What the hiding templates do, measured

Block 4's clothing templates are the retail mechanism for keeping skin out of the
cloth, and the pack ships **230** of them. Checked against the catalogue, they
pair with an item by name only for **180 of the 849** non-template assets:
`Jacket with Sweater` -> `Jacket with Sweater Hiding Template`,
`Male Flower Print Flares` -> `Flower Print Flares Hiding Template` (the gender
prefix is dropped in the template's name), but `Male Power Tee` and `Chinos` have
no template of their own at all. There is a second family - `Male Long Sleeved
Top Template`, `Male Trousers Bottom Template` and the rest of the cut names -
which hides by garment *cut* rather than by item.

Neither family closes the visible fault. On the stock male outfit:

| hidden by | vertices of `MaleBody` | effect on the render |
| --- | ---: | --- |
| the three item templates | 57 of 1,137 | no pixel changes |
| the two cut templates | 45 of 1,137 | no pixel changes |
| item + cut together | 70 of 1,137 | no pixel changes |

Baking the same outfit with no body in the parts list shows what the specks are:
they are `MaleBody` itself, through the sleeve at the shoulder and through the
trouser at the ankle, because the two meshes are skinned independently and the
body's surface crosses outside the garment's. So a template pass cannot dress an
arbitrary item, and it does not stop the poke. `bake_avatar.py` therefore moves
the offending body surface just inside the cloth - outside the garment and within
2 cm of it, pushed along its own normal - which is **112 of 1,137** vertices on
the stock outfit. The three rejected rules and why each failed are in
`CATALOG.md`.

### The name field, partly pinned

Read on more records, `+0xC0` is an **absolute file offset into the name pool**
(`Male Power Tee` -> 330098, which is inside the pool), not pool-relative and not
constant. It does *not* point at the start of every name: at `Large Chin`'s value
the pool reads "Large" and at `Male Power Tee`'s it reads "Power Tee", so the pool
is **deduplicated by substring** - both fragments also exist as their own entries
in it. The second fragment's field is not yet identified; `+0x98`, `+0x9C`, `+0xA0`,
`+0xA4`, `+0xA8`, `+0xB0` and `+0xB8` decode to nothing readable as UTF-16 at
either absolute or pool-relative offsets, so the pair is not simply two offsets in
those slots. A name is therefore assembled, not stored whole, and the assembler has
not been found in `LoadAssetPackFromMemoryV2`.

## The `.pdata` function table: the 73-hole count was measuring the wrong thing (round three)

**CORRECTION to every count above.** The "73 holes" are addresses at which the
corpus decompiler gave up. They are **not function entries**, and neither are
most of the addresses in `artifacts/decomp/holes.txt`. The PE ships the
compiler's own function table: `.pdata`, raw `0x32c00`, size `0x66f8` = 26,360
bytes = **3,295 eight-byte `(start, unwind)` entries**, every one of them inside
`.text`. Measured against it:

| | count |
| --- | ---: |
| addresses in `holes.txt` | 73 |
| ... that are `.pdata` starts | **3** |
| ... that are interior to some `.pdata` function | **70** |
| distinct `.pdata` functions the 73 addresses fall in | 62 |
| ... of those 62, dumping the function itself decompiles clean | **61** |

So the "4 stragglers" and the "1 address with no function" were an artefact of
dumping an interior address as if it were an entry: Ghidra created a body at that
interior address, and the body then began in the middle of the real function.

| flagged address | the real `.pdata` function | dump of that function |
| --- | --- | --- |
| `0x9804d2f8` (46-case colour dispatcher) | `0x9804d1f8`-`0x9804d370` | **clean, 65 statements** |
| `0x98125240` (switch) | `0x98125118`-`0x98125380` | **clean, 27 statements** |
| `0x9812ae50` (switch) | `0x9812ade8`-`0x9812b100` | **clean, 21 statements** |
| `0x9813b1c8` (tail at the end of `.text`) | `0x9813a658` (last entry) | **clean, 79 statements** |
| `0x98120c80` ("no function created") | `0x9811e978`-`0x981200f0` | **clean, 81 statements** |

Of the 62 containing functions, only **one** still fails: `0x980b9b20`.

The two switch entries are also the reason `decomp_gaps.py` said "no table
found": they use the *direct* table shape, `lis r12 / addi / slwi / lwzx /
mtctr / bctr`, whose entries are absolute 32-bit case addresses rather than
halfword offsets. The tool now reads both shapes (`kind == "words"`). It still
finds no table in those two addresses, and the reason is recorded rather than
guessed: the dispatcher computes `0x98124678`, the words there
(`c2940014 3b600258 ...`) are code inside another `.pdata` function, and the
decompiler's own error names `0xc2940014` - the first of them - as a flow target.
A well-formed 13-entry address table sits exactly `0xC00` later at `0x98125278`,
whose entries land mid-instruction. Those two interior blocks are **unresolved**;
the functions that contain them decompile cleanly either way.

### The whole of `.text`, by the compiler's own table

`MakeFunctions.java` creates the entries Ghidra's analysis did not: it had a
function at only **113** of the 3,295 starts. It merges a body into its
predecessor when an entry is reached by fallthrough with no prologue, and never
creates a body for a function reached only by tail-jump. With the entries
created, all 3,295 exist and `DumpFunctions.java` walks them:

| | count |
| --- | ---: |
| `.pdata` starts | 3,295 |
| functions Ghidra already had | 113 |
| created from `.pdata` | 3,182 |
| produced C | **3,272** (99.3% of entries) |
| `halt_baddata` in the C | 44 |
| decompiler returned no body | 23 |

A second run rebuilt the function set from `.pdata` alone (`RebuildFunctions.java`
removes all 6,563 existing `.text` functions and recreates the 3,295 in order),
and it is **not better**: 46 `halt_baddata` and the same 23 no-body functions,
with two new failures (`0x98062708`, `0x98066e50`). The dump taken on top of
Ghidra's analysis plus `MakeFunctions` is therefore the state of record.

### 25 of the 44 are not decompiler failures: `.text` starts with 0xC00 zero bytes

The first `0xC00` bytes of `.text` - VA `0x9803a000` to `0x9803abff` - are **all
zero in the shipped image** (checked in both the XEX image and the rebased PE);
the first non-zero instruction is at `0x9803ac00`. Exactly **25** of the 44
`halt_baddata` entries sit in that window (`0x9803a000` ... `0x9803abb8`), and
`ScanRangeRefs.java` measures **0 flow references into it from any of the
226,770 instructions in `.text`**. So those 25 describe loader-filled code that
is not in the file and that nothing reaches: there is nothing there to
decompile. This is the same situation as the `0x9813b1dc`-`0x9813c000` tail gap,
now measured at the head as well.

That leaves **42 real failures**, `artifacts/decomp/PDATA-failures.txt`:

| cause | count | measured shape |
| --- | ---: | --- |
| `halt_baddata` | **19** | **15 of 19** start mid-block (`beq`, `b`, `mr`, `mtctr`, `clrlwi`, `andi.`, `lwz`, `stw`, `srw`, `stw`); the other **4** do start with a real first instruction (`mflr r12` at `0x980ad248` and `0x980b9b20`, `stwu` at `0x980ded68` and `0x98101e28`) and still halt |
| `Bad instruction count exceeded` | **23** | **0 of 23** start with a prologue; measured first words are `lwz`, `beq`, `bne`, `b`, `addi`, `stw`, `srwi`, `ble`, `cmpwi`, `slwi`, `li` - and one decode of a data word, `tdi 6, r10, 0` at `0x9806ccc0` |

Both are the same defect: these `.pdata` entries are **cold/mid-block starts** or
entries whose body runs into one, rather than prologue-bearing functions. When a body is created at one, Ghidra's flow
runs back into the surrounding code - `FUN_980690e0` reports its body as
`0x980618e0..0x98069167` while its entry is `0x980690e0` - which produces the
"instruction overlaps instruction" warnings and the two symptoms above. The
preceding `.pdata` entry does **not** cover them either: for
`0x980690e0` that neighbour (`0x98068568`) dumps only 5 statements.

**Where that leaves the count, stated plainly:** 3,228 of 3,295 `.pdata` entries
(97.97%) decompile to C with no `halt_baddata`, 25 describe code that is not in
the file and is unreachable, and **42 do not decompile**. Decompilation is
therefore not at 100%, and the colour path's 100% claim above is unaffected (the
46-case dispatcher `0x9804d2f8` now dumps clean inside `0x9804d1f8`).

### Scripts added in this round

* `ProbeDecomp.java` - containing function, entry, body extent, thunk/noreturn
  flags, decompile timing, error message and first lines for `PROBE_ADDRS`.
* `MakeFunctions.java` - create a function at each `DUMP_LIST` address that has
  none (3,182 of 3,295 here).
* `RebuildFunctions.java` - remove every `.text` function (6,563) and recreate
  the `.pdata` set in order; measured worse, kept for the record.
* `ScanRangeRefs.java` - count control-flow references into `RANGE_LO..RANGE_HI`
  over all `.text` instructions (226,770 instructions; 0 into the zero head).
* `decomp_gaps.py` - now reads direct absolute-address switch tables as well as
  offset tables.
* `artifacts/decomp/pdata_funcs.txt` - the 3,295 starts, extracted from `.pdata`
  (8-byte entries) rather than from a code walk.

## Round four: `.pdata` is not a function table (CORRECTION to round three)

**CORRECTION.** Round three above says the 73 holes were "measuring the wrong thing"
and replaces them with the PE's 3,295 `.pdata` entries, treated as **function starts**,
and reports "3,228 of 3,295 (97.97%)". The measurement is sound; the interpretation is
not. `.pdata` here is **not one record per function**, so the 3,295 addresses are not
function entries, the "42 real failures" are an artefact of dumping interior addresses
as if they were entries, and the 97.97% figure has the wrong denominator.

What the records actually are, measured on the rebased PE (`.pdata` raw `0x32c00`,
size `0x66f8` = 3,295 eight-byte records):

| property | measurement |
| --- | --- |
| first field | ascending `3294/3294` pairs, no duplicates - a sorted table of text addresses |
| second field | a *packed unwind* word, not an RVA (`0x40003203`, `0x40001c03`, ...), 759 distinct values |
| length in the packed word | `((word >> 8) & 0x3FFFFF) * 4` bytes: equals the gap to the next record in **1,373** of 3,294 cases and **exceeds it in 0** - so the records never overlap |
| sum of those lengths | **956,560** bytes = **90.8%** of `.text` (1,053,148) |

So the table tiles code regions cleanly. It is still not a function table:

* **Record #71 (`0x9803d7e8`, 1,348 bytes) contains four prologues and four `blr`s**:
  `mflr r12` at `0x9803d990`, `mflr r12` at `0x9803dc78`, `mflr r12` at `0x9803dd08`,
  and `blr` at `0x9803d98c`, `0x9803db0c`, `0x9803dc74`, `0x9803dd00`.
* **2,066 of the 3,295 records contain no `blr` at all**; the counts run 0:2,066,
  1:656, 2:282, 3:113, 4:56, 5:41, 6+:81. A record is therefore a *code region*, which
  may hold one function, several, or part of one.
* The editor's `sin` - identified in the earlier rounds as `0x9803da18` - sits **560
  bytes inside** record #71 rather than at a record start.
* Only **205** of the 3,295 record starts are branch targets of any kind, only **177**
  begin with `mflr`/`stwu`, and of the **16,029** `bl` sites in `.text` (3,346 distinct
  targets) only **579** land on a record start.

The 42 "real failures" from round three are explained by the same fact: each of them is
a record boundary that falls *inside a basic block*. `0x980691f8`, for example, is
preceded by `addi r29,r10,-0x2cb0`, which lies inside `0x980690e0`'s declared 280
bytes, and `0x980691f8` itself begins `beq cr6,0x98069234`. A body created at such an
address starts mid-flow, which is exactly the "Bad instruction count exceeded" and
`halt_baddata` round three measured.

### The function set that is actually measured

Instead of the record table, the function set is now taken from the code: a fresh
`PowerPC:BE:64:Xenon` import, Ghidra's own analysis, and then the compiler's own rule
that an instruction directly after a terminator can only be an entry.

| stage | what it adds | `.text` decoded | instructions | functions |
| --- | --- | ---: | ---: | ---: |
| fresh Xenon analysis | Ghidra's function discovery (3,474 functions; 3,450 clean, 15 `halt_baddata`, 9 no body) | 818,152 (77.69%) | - | 3,474 |
| `DisassembleRecords.java` | disassembles from each of the 3,295 record starts (432 were still undefined): records used as a *code map* | 907,064 (86.13%) | 226,767 | 3,474 |
| `MakeRunFunctions.java` | a function at every undecoded address that directly follows a terminator | **1,040,376 (98.79%)** | **260,095** | **5,224** |

Why the post-terminator rule is legitimate rather than a heuristic: of the 2,331
undecoded runs left after the second stage, **2,324 begin immediately after `blr`
(1,205) or `b` (1,041)**; 92.4% of their bytes lie inside a `.pdata` record; 90.2% of
their words decode; and **none** are jump tables (0.1% of the words are text pointers).
Of the 4,150 candidate addresses the rule examined, 1,750 became functions and 2,400
had no decodable code at all - that second number is what the last 12,772 undefined
bytes (2,392 runs) mostly are: bytes after a terminator that are not instructions.

The current failure list is `artifacts/decomp/FAILURES-round4.txt`:

| | count |
| --- | ---: |
| functions in the set | **5,224** |
| decompile clean | **5,104 (97.70%)** |
| carry `halt_baddata` | 29 |
| decompiler returns no body | 91 |

### The 120 that remain are mostly one cluster

79 of the 120 sit in four 4 KB pages: `0x98068000` (21), `0x98069000` (18),
`0x9806c000` (17), `0x98067000` (13); another 15 in `0x98113000`/`0x98114000`.
They are not 120 unrelated decompiler bugs. `FUN_98067a50` is the shape:

```
body       0x98067a50..0x98067ba3          (ends with the dispatcher)
0x98067b7c lis    r12,-0x6800
0x98067b80 addi   r12,r12,0x65a0           ; table = 0x980065a0
0x98067b84 rlwinm r0,r11,1,0,0x1e          ; index * 2
0x98067b88 lhzx   r0,r12,r0                ; u16 offset
0x98067b8c lis    r12,-0x67fa
0x98067b90 addi   r12,r12,0x6fa4           ; base = 0x98066fa4
0x98067b94 add    r12,r12,r0
0x98067b98 mtspr  CTR,r12
0x98067ba0 bctr
```

The table's eight entries are clean - `0x98067158, 0x98066fa4, 0x98066fc4, 0x98067014,
0x98067050, 0x98067058, 0x98067090, 0x98067174`, every one 4-aligned. But those case
blocks are **not in this function's body**: they belong to `FUN_98066e38`
(`0x98066e38..0x980670eb`) and its neighbours, i.e. the compiler placed the switch's
case blocks out of line, before the dispatcher, shared between the functions that use
them. The decompiler follows them and recurses past its instruction limit, which is the
"Bad instruction count exceeded" every one of these functions reports, and the addresses
it names (`0x98067b8e`, `0x98067b96`, `0x98067013` - 2 or 3 bytes into an instruction)
are its own computed targets, not code.

`switch_tables.py` recovers the dispatchers properly: it re-reads each table the way the
code indexes it (`lis`+`addi` for the table, `rlwinm` for the scale, `lhzx`/`lwzx` for
the width, a second `lis`+`addi` for the base) and prints every case target. Over
`.text` it finds **18 dispatchers and 559 case targets**, 14 of them fully 4-aligned.
The cross-check is exact: the colour dispatcher comes out as **46 cases, table
`0x98002980`, base `0x9804c73c`** - precisely the table `decomp_gaps.py` found by hand in
the earlier rounds. `AddComputedJumps.java` attached all 559 as `COMPUTED_JUMP`
references from their `bctr`; the failure count did not move (5,104 either way), which
rules out "the decompiler does not know the cases" as the cause and leaves the shared
out-of-line case blocks as the measured blocker.

Every one of the 120 now has a hand listing in `artifacts/decomp/failing/` (one file per
entry plus `SUMMARY.md`), produced by `list_failures.py` on top of
`decomp_holes.decode_function`: instructions, resolved `lis`/`addi` data references and
branch targets, so the code is readable even where no body is produced.

### Scripts and artifacts added in round four

* `BoundFunctions.java` / `RebuildFunctions.java` - bounded-body creation from `.pdata`;
  measured (3,247 of 3,295 produced C, 21 `halt_baddata`, 23 no body) and superseded by
  the finding that records are not functions. Kept because the negative result is the
  evidence for the correction.
* `DisassembleRecords.java` - disassemble from record starts; reports how much of the
  new code lands inside an existing body (`DISREC instructions=... orphan=...`).
* `MakeRunFunctions.java` - function at every undecoded post-terminator address; the
  single largest gain in the round (77.69% -> 98.79% of `.text`).
* `MakePointerFunctions.java` - function at `.rdata` code pointers; found the image's
  sections are mapped 4 KB-aligned (`MemBlocks.java` shows `.rdata` at `0x98001000`, not
  the PE's `0x98000400`, and `.pdata` twice), so pointer scanning needs the Ghidra
  mapping, not the file VAs. Left in the tree with that note.
* `Coverage.java` - per-*byte* decode coverage. Its first version tested
  `getInstructionAt`, which is only true for an instruction's first byte and reported
  21.5%; the containment test is the one that means anything.
* `FailList.java` - every function that does not decompile, with the decompiler's own
  message, body extent and statement count.
* `ClearMisaligned.java` - removes instructions at non-4-byte-aligned addresses. Only
  one existed in `.text` (cleared; coverage moved by exactly 4 bytes), and clearing it
  did not change any function's outcome - so the misaligned addresses in the failure
  messages are computed targets, not stored instructions.
* `switch_tables.py` - the dispatcher/table/case-target extractor described above;
  output saved as `artifacts/decomp/dispatchers.tsv`.
* `AddComputedJumps.java` - attaches recovered case targets to each `bctr` as
  `COMPUTED_JUMP` references.
* `Around.java` - instructions, function membership, and references to *and from* every
  4-byte slot in a range; the instrument that showed the table is only referenced as
  data from the `lhzx`.
* `pdata_entries.py`, `pdata_targets.py`, `undef_runs.py` - the measurements behind the
  correction: entry context, `bl`/`b` target counts, and what the undecoded runs are.
* `SplitCaseBlocks.java` - splits recovered case targets out of their owner function; the
  negative result that ruled out case-block ownership as the cause (0 of 120 fixed).
* `DumpBadData.java` - dumps every function with `max_baddata` raised; the measurement
  behind the "budget, not size" conclusion above.
* `BadInsns.java` - counts instructions with no p-code per function (0 across all 5,224,
  so the bad-data events are address problems, not unimplemented opcodes).
* `TrimBackwardBodies.java` - trims a body that extends before its own entry (12 here,
  36,980 bytes). Applied and measured; it changed no outcome, so the corpus's current
  state has it applied and the overlap it removed is recorded above.
* `MemBlocks.java` - the program's memory map.
* `list_failures.py` - hand listings for the functions with no decompiler body.
* `artifacts/decomp/FAILURES-round4.txt`, `COVERAGE-round4.txt`, `dispatchers.tsv`,
  `failing/` - the evidence for this section.

### The colour dispatcher: a second correction, from checking my own claim

Round three above records that the 46-case colour dispatcher `0x9804d2f8` "sits inside
`0x9804d1f8`" and that `0x9804d1f8` dumps clean at 65 statements. **Both halves are
wrong**, and checking them in the current function set is what showed it:

* `0x9804d1f8` is a **mid-block address inside VMX128 vector code** owned by
  `FUN_9804f728`: the words around it read `vmsum4fp128 vr60,vr0,vr60`,
  `vmrghw128 vr53,vr52,vr53`, `stvx128 vr62,r0,r11`. The 65-statement dump at that
  address (`/tmp/out12/0x9804d1f8.c`) begins `undefined8 FUN_9804d1f8(void)` with
  `float` locals - it is the vector maths, not the dispatcher.
* The dispatcher is its own function, **`FUN_9804d2f8`, body `0x9804d2f8..0x9804d33b`,
  ending at the `bctr` at `0x9804d338`**, and it is one of the 91 no-body failures.
  `FUN_9804d2f8` is also *overlapped* by `FUN_9804f728`, whose body starts 0x2B10 bytes
  before its own entry.

The 46-case table itself is not in doubt - it is now confirmed a third time, from the
code rather than from any body: `switch_tables.py` reads the `lhzx`+`bctr` at
`0x9804d338` as table `0x98002980`, base `0x9804c73c`, **46 cases**, exactly the numbers
`decomp_gaps.py` produced by hand. Three methods, one answer.

What follows for the colour work: the dispatcher's *case structure* is fully decoded by
hand (that is what `COLOURS.md` is built on), but its statement-level C is **not**
currently produced by the decompiler. Earlier wording here that called the colour path
"100% readable code" should be read as "fully decoded by hand", not "in the corpus".

### Experiments that did not move the 120, recorded so they are not repeated

| change | effect on 5,224 functions | effect on `.text` |
| --- | --- | --- |
| `AddComputedJumps` - all 559 recovered case targets as `COMPUTED_JUMP` refs | none (5,104 clean) | none |
| `ClearMisaligned` - cleared the one non-4-aligned instruction in `.text` | none | -4 bytes |
| `TrimBackwardBodies` - 12 bodies extended before their entry, 36,980 bytes removed | none (5,104 clean) | orphan instructions 12,951 -> 14,002 |
| `SplitCaseBlocks` - 209 case blocks split out of their owners (34 refused) | **0 of the 120 fixed, 41 new failures** (5,279 clean of 5,440) | - |
| `DumpBadData` - `max_baddata` 4 -> 100 | 5,101 clean, 122 halt, 1 no body | - |

So the 91 no-body functions are not caused by unknown case targets, by a stored
misaligned instruction, or by backward-absorbed bodies. What remains measured about them
is their shape (out-of-line case blocks owned by a neighbouring body) and their location
(79 of 120 in four 4 KB pages).

### Why it gives up: four bad-data events, not a size limit

The rule is in the decompiler's own source. `flow.cc:550` throws "Bad instruction count
exceeded" from `FlowInfo::countBadData()` when `baddata_count >= glb->max_baddata`, and
`architecture.cc:1426` sets **`max_baddata = 4`** - four p-code requests at unusable
addresses, nothing to do with body size. The `baddatacount` option (`options.cc:807`)
raises it, and its documentation says the result is "artificial halts generated at
addresses causing the BadDataError" - the `halt_baddata()` marker.

`DecompileOptions.setMaxBadData` exposes it, and `DumpBadData.java` was run with it:

| | default (4) | raised (100) |
| --- | ---: | ---: |
| functions with a body | 5,133 | 5,223 |
| clean | 5,104 | 5,101 |
| `halt_baddata` | 29 | 122 |
| no body | 91 | 1 |

The budget is not the blocker: it converts 90 empty functions into bodies that stop at a
halt and costs 3 clean ones. The 184 distinct addresses it complains about are **177
misaligned** (so not instructions at all) and 7 aligned, and the misaligned ones sit at
every halfword phase - 75 at `mod 4 = 1`, 52 at 2, 50 at 3 - which is the signature of a
halfword read rather than a fixed shift. 566 of the events are "improperly aligned", 221
"Unable to resolve constructor", 5 "flow into non-existing memory". The inference drawn
from that distribution (the recovery never resolves the table base for these `lhzx`
dispatchers, so its entries are halves of code words) is labelled as an inference in
`BADDATA.md`. Full detail in
`artifacts/decomp/BADDATA.md`, which also records that `JumpTable::sanityCheck` returns
early `if (jmodel->isOverride())` - the override path is how to close the last 120.

### Where the gate stands

Decompilation is **5,104 of 5,224 functions (97.70%)**, not 100%. `.text` itself is
98.79% decoded byte-wise (12,772 bytes in 2,392 runs, mostly bytes after a terminator
that are not instructions). The 120 failures are concentrated in one shared-case-block
cluster whose cause is measured rather than guessed, they resist the three repairs in
the table above, and every one of them has a hand listing in `artifacts/decomp/failing/`.
Any "decompilation at 100%" gate is therefore **not** met yet. The remaining work is
specific and no longer speculative, because the two obvious repairs were tried and
measured: re-owning the case blocks fixed 0 of the 120 and added 41 failures, and raising
the bad-data budget to 100 gave bodies that halt (122 halt, 1 no body) instead of bodies
that decompile. What is left is to record the 18 recovered tables as **explicit jump
tables** in the program: `JumpTable::sanityCheck` returns early for an override model, so
the decompiler would take the recovered cases instead of running its own `lhzx`-unaware
recovery, which is the thing producing the 177 misaligned targets.

## Round five: the override jump tables close 93 of the 120 (2026-11-18)

The last section above named the repair and left it untried: write the 18 recovered
tables into the program as **override** jump tables, which is the one path Ghidra's
decompiler honours (`JumpTable::sanityCheck` returns early for an override model).
`SwitchTables.java` does exactly what Ghidra's own interactive `SwitchOverride.java`
does, for every row `switch_tables.py` produces:

* add each recovered case address to the `bctr` as a `COMPUTED_JUMP` reference
  (this alone changed nothing in round four - 5,104 clean either way);
* allocate `new JumpTable(bctr, dests, true, 0)` and `writeOverride(function)`;
* `CreateFunctionCmd.fixupFunctionBody(...)` so the body is rebuilt with the cases present.

Run on a fresh project (Ghidra 12.2, `PowerPC:BE:64:Xenon` from
`install_xenon_language.sh`, `ppc_64_xenon.sla` 208,853 bytes; import of
`/tmp/nxe2008.elf` with `ModelImports` then `DisassembleRecords` then
`MakeRunFunctions`):

| step | measured |
| --- | --- |
| `DisassembleRecords` | 227,855 instructions, 201,775 inside a function, 26,080 orphan |
| `MakeRunFunctions` | candidates 4,141, created 1,741, no code 2,400, failed 0 |
| `SwitchTables` | **18 dispatchers, 18 overrides, 559 computed jumps, 0 skipped** |

The measurement that matters is a dump of the round-four failure list
(`artifacts/decomp/FAILURES-round4.txt`, 120 addresses) in that project:

| | before | after |
| --- | ---: | ---: |
| produced C at all | 0 (they were the failures) | **118** |
| ... with no `halt_baddata` | 0 | **96** |
| ... still `halt_baddata` | 120 | 22 |
| ... decompiler returned no body | - | 2 |

So the shared-case-block cluster was what it looked like: with the real destinations
in the program, 96 of the 120 decompile. On the round-four denominator that moves the
gate from 5,104 to **5,200 of 5,224 functions (99.54%)**, and `.text` coverage is
unchanged. That figure is arithmetic on the round-four set, not a fresh full-corpus
recount: 120 - 24, where the 24 are the ones a dump of the same list still flags.

**CORRECTION (same day).** The first write-up of this round said "115 produced C, 93
clean, 5 no body" and a gate of 5,197 (99.48%). Those came from the dump script's
`ok=115` line, which counts *attempts*; counting the files it actually wrote gives
118 written, 96 clean, 22 halt, 2 with no file at all (0x98067c14 and 0x9806884c).
The 5,200 figure above is the recount.

### The 24 that still fail, by measured signature

None of them is a blank anymore - 22 produce bodies of 2 to 238 statements that stop at
the same kinds of address:

| signature | count | addresses |
| --- | ---: | --- |
| `Unable to resolve constructor at 0x980670ec` | 17 | the `0x98067ba4`-`0x9806812c` run in the shared case-block page |
| computed flow into non-existing memory | 2 | `0x98125240` (`c2940014`), `0x9812ae50` (`c15e0030`) - the two tables round four could not recover |
| flow past `.text` into the loader gap | 2 | `0x98065ca0` (`0x98065d24`), `0x9813b1c8` (`0x9813b200`) |
| error before the entry (overlapping body) | 1 | `0x980ad3b0` (`0x980ac88c`) |
| four-byte body, `stw r16,-0x59d0(r6)` only | 1 | `0x9806b204` |
| no decompiler body | 2 | `0x98067c14`, `0x9806884c` |

Only 3 of the 24 are case targets of a recovered table (`0x98067d74`, `0x980680e8`,
`0x98067c14`), so they are not simply case blocks being counted twice.

**What the 0x980670ec cluster is, measured.** Every one of the 17 names that address.
It sits in a zero word (`00000000`) between `bl 0x98067318` at `0x980670e8` and a
prologue at `0x980670f0`; the call's fallthrough lands on it, and `0x98067318` *does*
return (`blr` at `0x9806736c`), so "callee is noreturn" is not the answer. The word
before, `0x980670e4`, is an unconditional `b 0x980670a4`, so nothing reaches
`0x980670e8` by flow either - it is a dead word inside `FUN_98066e38`'s body.

**Five repairs tried and measured negative, so they are not repeated:**

| repair | script | measured |
| --- | --- | --- |
| clear every zero-word instruction in `.text` | `ClearZeroWords.java` | 260,111 instructions scanned, **0 cleared** - there is no instruction at `0x980670ec` at all |
| rebuild bodies from flow | `FixupFunctions.java` | 23 bodies, **0 changed** - Ghidra already thinks these bodies are complete |
| bound `FUN_98066e38` to end before the dead word | `SetBodyRange.java` | body set to `..0x980670e7`, **the 22 still halt** |
| clear the dead `bl` word at `0x980670e8` itself | `ClearAddresses.java` | instruction was there (`true`), cleared, **the 17 still name `0x980670ec`** - so the error is not reached through that word |
| trim bodies that start before their entry | `TrimBackwardBodies.java` | 7 bodies / 8,848 bytes trimmed, **0 fixed** |
| mark call-tails that end in padding as noreturn | `MarkNoReturnTails.java` | 962 tails, 203 callees marked - **reverted**: it marked `memset` (`0x98061950`) noreturn among others, and 758 callees were already flagged. A broad no-return sweep deletes real code paths |

That last one is the one negative result worth keeping: a zero word after a `bl` is
*usually* a noreturn tail, but not always (a jump-table entry of zeros looks the
same), so marking from that shape alone is not safe. It was discarded, and the
project was rebuilt from scratch before the measurements above.

`SwitchTables.java` is in `avatar_tools/` beside `AddComputedJumps.java`, which is kept
as the negative result that proved references alone are not enough.

### The two unrecovered tables, one step further

`FUN_98125240` is a clean dispatcher with the *direct* shape, read off the listing:

```
98125258  cmplwi cr6,r4,0xc      ; 13 cases, index 0..12
98125260  lis    r12,-0x67ee     ; 0x98120000
98125264  addi   r12,r12,0x4678  ; table = 0x98124678
98125268  slwi   r0,r4,2         ; 4-byte entries
9812526c  lwzx   r0,r12,r0
98125270  mtctr  r0
98125274  bctr
```

The 13 words at `0x98124678` are `c2940014 3b600258 906b0000 d00b0008 914b000c
d00b0014 936b0018 d00b0020 386b0024 d3cb0004 d28b0010 d26b001c 93cb0024` - i.e. the
bytes of PowerPC instructions, not addresses (the decompiler takes the first as a flow
target, which is where "non-existing memory at c2940014" comes from). So this table is
either mis-read by one indirection, or it is not a table at all; `switch_tables.py`
correctly refuses to emit it, and nothing in the corpus is invented to force it.


## Round six: the gate is now measured over the whole program

Every figure up to here was arithmetic on an older run's denominator. `tools/rebuild_full.sh`
now does the whole thing from an empty project and then runs `FailList` over the
entire function manager, so the number is a count of functions, not an estimate.

**One new step, and it removed 171 "failures" that were never functions.**
`MakeRunFunctions` makes a candidate at the word after every terminator. Past the end
of `.text` (`0x9813b1dc`, measured from the rebased PE) that lands in a data region, and
each hit became a one-word function whose single word is not PowerPC code at all -
`01000210`, `010101f5`, `010002f5`. `DeleteForeignFunctions.java` removes every
function entered outside `.text`: 171 removed, 5,387 left inside it, and 21 of the
33-entry failure list went with them.

Measured, same project, junk already gone:

| configuration | total | clean | halt | no body | failures |
| --- | ---: | ---: | ---: | ---: | ---: |
| plain rebuild | 5,385 | **5,352** | 31 | 2 | **33** |
| + the 18 override jump tables, 559 targets | 5,385 | 5,349 | 31 | 5 | **36** |

So the gate is **5,352 of 5,385 functions (99.39%)**, and the override tables - the
whole of round five - are **net negative on this function set**: they fixed nothing
the rebuilt disassembly had not already fixed and pushed three functions that used to
decompile (`0x98046ef0`, `0x980fc758`, `0x98101e20`) into `no_body`. They are therefore
opt-in now (`SWITCH_TSV=... tools/rebuild_full.sh`); the script, the 18 tables and the
measurement stay, the default build does not apply them.

**CORRECTION.** Round five stated 5,200 of 5,224 (99.54%) and called 24 functions the
outstanding total. Both came from comparing against the 120-address list from round
four; 5,224 was a stale `Coverage` count, not the function manager's total, and the
24 was a subset of what actually fails. The measured figures are the table above.

### The 33, by shape

| shape | count | entries |
| --- | ---: | --- |
| the `0x980670ec` cluster | 17 | `0x98066e38`, `0x98067ba4`-`0x9806812c` |
| decompiler returns no body | 2 | `0x98056cc8` (bad instruction count), `0x980f83a8` (body runs past the address space) |
| flow that starts before its own entry | 3 | `0x9804d2f8` (error at `0x9804c7bc`), `0x980b9da0` (`0x980b93ec`), `0x980ad3b0` |
| computed flow into non-existing memory | 2 | `0x98125240`, `0x9812ae50` |
| four-byte fragments | 4 | `0x9805bd28`, `0x9806b204`, `0x980f2ab8`, `0x9813b1c8` |
| thunk and its callee | 2 | `thunk_FUN_98062658` and `0x98062658` |
| run-of-the-mill failures | 3 | `0x98055cd8`, `0x98055ef8`, `0x98065ca0` |

`FAIL_OUT` is not honoured by `rebuild_full.sh` any more (the script sets its own path):
the lists live in `artifacts/decomp/fails_no_override.txt` (33) and
`fails_full2.txt` (36, the override run).


## Round seven: the last 33 were candidates inside a function, and the gate closes

Round six ended at 5,352 of 5,385 with 33 failures and no explanation of what they
had in common. They have one: **the compiler did not record a function at any of
them, and every one sits inside a `.pdata` record.**

Measured against the record list the build already reads (`pdata_funcs.txt`, 3,295
starts) and the 33 addresses from `artifacts/decomp/fails_r7.txt`:

| check | result |
| --- | --- |
| failing addresses that are a `.pdata` record start | **0 of 33** |
| failing addresses strictly inside a record span | **33 of 33** |
| `.pdata` record functions that fail to decompile | **0 of 3,295** |

The nearest previous record start and the offset into it, for every one:

```
0x9804d2f8  0x9804d1f8 +256    0x98066e38  0x98066c80  +440
0x98055cd8  0x98055b58 +384    0x98067ba4  0x98067a08  +412
0x98055ef8  0x98055d30 +456    0x98067bc4  0x98067a08  +444
0x98056146  0x980560c8 +126    0x98067c50  0x98067a08  +584
0x98056cc8  0x98056ca0  +40    0x98067c58  0x98067a08  +592
0x9805bd28  0x9805bca0 +136    0x98067c90  0x98067a08  +648
0x98061940  0x980618d0 +112    0x98067d14  0x98067a08  +780
0x98062658  0x980622e8 +880    0x98067d74  0x98067a08  +876
0x98065ca0  0x98065bc0 +224    0x98067da8  0x98067a08  +928
                               0x98067e20  0x98067a08 +1048
                               0x98067ea0  0x98067a08 +1176
                               0x98067f78  0x98067a08 +1392
                               0x98067fb4  0x98067a08 +1452
                               0x980680e8  0x98067a08 +1760
                               0x980680f4  0x98067a08 +1772
                               0x98068100  0x98067a08 +1784
                               0x9806812c  0x98067a08 +1828
0x9806b204  0x9806b1c0  +68    0x980ad3b0  0x980ad388  +40
0x980b9da0  0x980b9b20 +640    0x980f2ab8  0x980f2a88  +48
0x980f83a8  0x980f8278 +304    0x98125240  0x98125118 +296
0x9812ae50  0x9812ade8 +104    0x9813b1c8  0x9813a658 +2960
```

**Why they exist at all.** `MakeRunFunctions` only skips an address that a function
contains *at the moment it looks*. A switch target inside a function whose body flow
had not reached it yet is therefore free, and gets its own function - which the
decompiler is then asked to decompile as a body starting at a branch target. That is
what produces the three symptoms round six grouped: a flow that starts before its own
entry (`0x9804d2f8` reaches back to `0x9804c7bc`), a body that walks out of the
record, and a `blr` in the middle of a case.

Two of the cluster's addresses are data, not code, and the image says so:

```
0x980670ec  00000000 9213aa8c 92032858 7d8802a6
            ^^^^^^^^ a zero word. Nothing decodes it: "Unable to resolve
            constructor at 980670ec" is the decompiler saying exactly that.
0x98067c00  48000938 63390080 48000930 63390002
            ^^^^^^^^ b 0x98068538 ... ori r25,r25,0x80: 4-byte branch entries of a
            jump table, which the sweep read as instructions.
```

**The fix, `DeleteInteriorFunctions.java`.** It takes the failing addresses, refuses
any that is a record start or outside a span, and removes the rest. Measured on the
project that had just reported 33:

```
INTERIOR asked=33 removed=33 is_record=0 before_first=0 outside=0 no_function=0
FAILLIST total=5352 clean=5352 halt=0 no_body=0      (fail list empty)
```

The clean count is unchanged at 5,352 - nothing that used to decompile stopped
decompiling - and the total fell by exactly the 33 addresses that never had a body.
A `DumpFunctions` pass over the same 33 afterwards reports `ok=0 missing=33`, so
they are gone rather than hidden.

**From an empty project**, with the step now in the default build:

```
RUNFN     candidates=4141 created=1741 in_existing_body=0 no_code=2400 failed=0
FOREIGN   outside=171 removed=171 in_text=5387
INTERIOR  asked=33 removed=33 is_record=0 before_first=0 outside=0
FAILLIST  total=5352 clean=5352 halt=0 no_body=0
```

The gate is **5,352 of 5,352** and `artifacts/decomp/fails_r7_final.txt` is empty.
Round six's figures reproduce exactly first (`5,385 / 5,352 / 31 halt / 2 no_body`),
so the pipeline is deterministic.

### What "5,352 of 5,352" does and does not say

* It says every function **start the model holds** gets a body: 3,295 `.pdata`
  record starts plus 2,057 `MakeRunFunctions` candidates.
* It does not say the 2,057 candidates are functions the compiler knew about. They
  are leaf entries absent from `.pdata`; they decompile, but nothing in the image
  confirms them individually.
* It does not say every interior word was understood. `FailList` still logs **22
  pcode warnings** over 14 instructions (7 distinct). All of them are inside a
  recorded function's span, and all of those functions still produce C:

```
9812ae50  Unable to read bytes at ram:c80b2600            x3
98125240  Unable to read bytes at ram:3b600258            x3
9812ae50  flow into non-existing memory at c15e0030       x2
98125240  flow into non-existing memory at c2940014       x2
98067a50  unable to resolve constructor at 980670ec        x2
9804d2f8  unable to resolve constructor at 9804c7bc        x2
980b9da0  ... 980b93ec x1    980ad3b0  ... 980ac88c x1    98067d74  ... 980670ec x1
98056cc8  ... 98056146 x1    98056cc8  ... 9805615a x1    98056cc8  ... 9805616e x1
98055ef8  ... 98055374 x1    98055cd8  ... 98055214 x1
```

  The `3b600258`/`c2940014` pair is the jump table at `0x98124678` already recorded
  above: instruction bytes taken as addresses. `980670ec` is the zero word. These
  are jump-table and padding words living inside a function, which is a real
  limitation of the model, not a failure that removing a candidate fixed.

**CORRECTION.** Round six called these 33 "failures" and split them into seven
shapes as if they were decompiler defects. They are candidates placed inside a
record, and the decompiler fails on **none** of the 3,295 recorded functions. The
shapes are still the right description of *why* a candidate inside a function cannot
decompile, but they were never evidence about the decompiler's reach.

**CORRECTION.** Round six said `FAIL_OUT` is not honoured by `tools/rebuild_full.sh`.
It is now (`FAIL_OUT=... tools/rebuild_full.sh`), and the script also resolves the
JDK directory by glob; Adoptium renamed `jdk-25.0.5+8` to `jdk-25.0.5.1+2`, so the
pinned path stopped existing. `tools/setup_ghidra.sh` and `mkelf.py` rebuild the
toolchain from the XEX after a workspace restore:

```
tools/setup_ghidra.sh
cd UniKron/avatar/avatar_tools && PYTHONPATH="$PWD:$PWD/../../../.pyext" \
    python3 mkelf.py "../../../src_archive/XBOX HUB/resources/editors/nxe2008/assets/avatareditor.xex" /tmp/nxe2008.elf
```

(`capstone` is unpacked in `.pyext`; `pip` installs into a different interpreter and
does not put it where `ppc_disasm` looks.)
