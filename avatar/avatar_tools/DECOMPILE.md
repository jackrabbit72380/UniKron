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
| `resources/editors/metro2010/avatareditor.exe` | Windows host | x86 | see below |
| `resources/editors/metro2010/assets/avatareditor.xex` | Xbox 360, 2010 dash | PowerPC BE | **encrypted, blocked** |

The 2008 editor is the one this theme reproduces, so its corpus is the useful
one: 1,986 functions of real C, dense across the whole `.text`
(`0x9803acc8`-`0x9813c058`), complete with the UI class names the strings
section promised (`AuraControl`, `AuraScene`, `AvatarCategoryLabelOverride`,
`AvatarBackButtonOverride`).

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

## The brick walls

1. **`metro2010/assets/avatareditor.xex` is encrypted.** Its PE begins at
   `28672` as ciphertext. Six LZX attempts (offsets 28672/28696/28720 at 1 MiB
   and 4 MiB output) all fail with `bad aligned table` or `bad block type`.
   What this needs: the decrypted image, or the console's XEX keys. Nothing in
   the archive supplies either.
2. **The host-side `XBOX HUB.exe` (238 MiB) and the third-party PE DLLs.**
   `dxcompiler.dll`, the CEF binaries and the rest total 387 MiB of other
   people's code. They are not the avatar editor and decompiling them would take
   hours of CPU for gigabytes of output that says nothing about the editor.
