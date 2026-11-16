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
`halt_baddata()` stub - the import had been made at the base the PE header
claims (`0x92000000`) rather than the one the code builds (`0x98000000`), so
the whole image decoded as garbage. The numbers in the table above describe the
re-run, not that archive. The re-run imports at `0x98000400` (`mkelf.py` reports
it), and the result is:

| | functions |
| --- | ---: |
| in the image | 1,986 |
| with a decompiled body | 1,093 |
| still `halt_baddata` | 893 |

The 893 are not a bad import. They are the functions whose first block contains
a Xenon `vmx128` instruction - the 360's 128-bit vector extension, which
Ghidra's PowerPC module does not model, so decoding stops at the first one.
Nothing in Ghidra 12.2's language list covers it (`4xx`, `e500`, `QUICC`,
`default`), which means the vector maths and most of the rendering path are
still unreadable as C. Everything that gates on it - the light rig's numbers,
the stage camera - is plausibly in that 45%.

`decompiled/nxe2008_index.txt` is regenerated from this corpus (address, body
length, first literal), and `decompiled/samples/` holds a real function from it.

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

## The brick walls

1. **`metro2010/assets/avatareditor.xex` is encrypted.** Its PE begins at
   `28672` as ciphertext. Six LZX attempts (offsets 28672/28696/28720 at 1 MiB
   and 4 MiB output) all fail with `bad aligned table` or `bad block type`.
   What this needs: the decrypted image, or the console's XEX keys. Nothing in
   the archive supplies either.
2. **The remaining 21 third-party PEs** - `XBOX HUB.exe` (238 MiB),
   `dxcompiler.dll` x2, `dxil.dll`, `vk_swiftshader`, `vulkan-1`, `ffmpeg`,
   `d3dcompiler_47`, `SDL2`, `iCUESDK`, the MSVC runtimes and
   `xenia_canary_netplay.exe`. That is Chromium, DirectX tooling, an emulator
   and redistributables: ~300 MiB of other people's code whose decompilation
   would run for hours and say nothing about the avatar editor. Everything
   first-party is done.

| `default_uncompressed.xex` (avatar.zip dump) | xtl avatar renderer, 2008 SDK | 6,618 |
