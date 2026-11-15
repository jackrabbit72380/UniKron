# What is inside the Avatar Editor recomp builds

Inventory and decode results for both editor builds shipped in
`src_archive/XBOX HUB/resources/editors`. Everything below was verified by
reading the files, not inferred.

## Inventory

| file | nxe2008 | metro2010 |
|---|---|---|
| `avatareditor.exe` | 8,651,264 | 17,567,232 |
| `assets/avatareditor.xex` | 15,826,944 | 15,507,456 |
| `rexruntime.dll` | 10,657,280 | 10,657,280 (`bin/`) |
| `rexgpu-xenos.dll` | 2,822,144 | absent |
| `bin/dxcompiler.dll`, `bin/dxil.dll` | absent | 17,972,656 / 1,462,704 |
| `msvcp140.dll`, `vcruntime140*.dll` | shared CRT | shared CRT |

Byte-identical between the two builds (SHA-1):

    AvatarAssetPack.toc          2a08dba1303f0a97a4c5795cd5879191ed22aba9
    AvatarAssetPackLegacyV1.toc  692b3de68e1c41dd392d637a57f72fc2e0277cce
    msvcp140.dll, vcruntime140.dll, vcruntime140_1.dll, msvcp140_atomic_wait.dll

So the 2008 and 2010 **asset data is the same data**. Only the executables,
the guest `.xex` and the GPU module differ. Both `avatareditor.toml` files are
identical apart from line endings.

## Asset directory (both builds)

    Avatar6400/6404/6411.Avatar        1000 B  saved avatar manifests
    AvatarAssetPack.toc        13,648,884 B  1,079 assets
    AvatarAssetPackLegacyV1.toc 1,252,000 B  44 assets
    IdleOffScreen/Cheer/Look/Salute/Gift/RunIn/RunOut*.AvatarAnimation
    ae.png, icon.png, fonts/XenonCLatin.xtt, fonts/XenonJKLatin.xtt

The standalone `.AvatarAnimation` files are STRB containers: block 8 (15 bytes
of metadata) plus block 1 (the animation). Header is `skeleton_count`,
`duration` as a **float**, `pose_count` (71), then the serialiser table.

## Binaries

No symbol tables in any of them (`objdump -t` and `-T` both come back empty for
`avatareditor.exe`, `rexruntime.dll`, `rexgpu-xenos.dll`). What is recoverable is
C++ RTTI, which names the avatar module's classes:

    rex::avatars::Model, Skeleton, Animation, Texture, Prop, BlendShape
    rex::kernel::xam::XamAvatarInitialize_entry, XamAvatarGetAssets_entry,
    XamAvatarGetAssetsResultSize_entry, XamAvatarManifestGetBodyType_entry,
    XamAvatarShutdown_entry, XamAvatarGetManifestLocalUser_entry

`rexgpu-xenos.dll` carries a long human-written note about the guest interrupt
handler offset (11028 for the Metro dashboard, **10900 for the Avatar Editor**),
which is a recomp authoring note, not game data.

### Not present anywhere

  * **Joint names.** None of `SC_BASE, LF_E, LF_S, LF_W, RT_E, RT_S, RT_W,
    NECK, HEAD, BASE, BACKA, LF_H, RT_H, FINGA, THUMB, TWIST, SC_NECK,
    LF_PROP, LF_SPECIAL` occur in either `.exe`, either `.xex`, or
    `rexruntime.dll`, in ASCII or UTF-16. The rig's bone names are therefore not
    recoverable from these files, and any names in `avatar_pose.py` are guesses.
  * **A float vertex buffer.** `Model`'s header advertises `vertex_buffer_offset`
    12288 / `vertex_buffer_size` 45568 and `index_buffer_offset` 57856, but those
    are GPU-space addresses: 57856 exceeds the 49,014-byte payload. Scanning the
    payload for float regions that look like positions (fraction of values in
    [-3, 3]) finds **none** above 90%. The quantised serialiser array is the only
    vertex data in the file, which is exactly what the reference reader decodes.

## Saved avatar manifest

`Avatar6400.Avatar` is 1,000 bytes of records following a small header, with a
fixed 8-byte marker `c1c8f109a19cb2e0` in every record. It says what an avatar
*wears* and what colours it uses; it contains no geometry. See "The `.Avatar`
manifest, read as big-endian" below for the field layout.

The header's two `bf000000` words read as **191** little-endian or **-0.5f**
big-endian, and the 360 itself is big-endian, so this file is quoted big-endian
below - but the difference does not change the conclusion: no pair of floats in
any plausible scale range exists anywhere in the three files.

## Editor config knobs worth keeping

`avatareditor.toml` documents options the theme does not model:

    content_root = "outfits"      # the clothing library the editor browses
    avatar_closet_dir = ""        # per-user closet, set by the hub
    avatar_eye_whites = false     # eye rendering variant
    model_shadows = true          # avatar casts a shadow

## The Hub's avatar system (`resources/app/avatars.js`)

The Xbox 360 Hub app ships as **plain readable JavaScript**, and `avatars.js`
documents the editor's data model in its header comment. This is the map that
was missing:

    <userData>/avatar editors/<nxe2008|metro2010>/
        closet/    closet_index.tsv, closet_titles.tsv, closet_awards.tsv,
                   <guid>.bin per item, icons/<guid>.png
        saves/     what the editor writes: the avatar, outfits, gamer picture

Before every launch the Hub rewrites four keys in `avatareditor.toml`:

    avatar_closet_dir = <closet>      content_root = <saves>
    user_name = <gamertag, 15 chars>  fullscreen = true

So the editor's own item library is ordinary user data, not something in the
pack; nothing of it ships, which is why the archive has no `closet/` folder.

An item is a `<guid>.bin` whose first four bytes are `YTGR` - the same container
family as the pack's assets, which is why a STRB scanner walks them. Rows are
`guid<TAB>categories<TAB>bodies<TAB>name`, where `categories` is the first four
bytes of the GUID read as a hex number. Icons are `<guid>.png` beside them, so a
closet is enough to show a real catalogue of item art if one is ever imported.

The Hub imports items from either an existing closet folder or from extracted
Xbox LIVE items (`ID*.TXT` holding the GUID, `asset_v2.bin`, `ICON.PNG`,
`<guid>.xml` with `reducedTitle` / `avatarBodyType`), verifying the `YTGR` header
before copying.

Finally, `apps.js` shows what a saved avatar is: the eighteen avatar games are
started with `--avatar <path>`, where the path is
`content/avatars/<xuid>/avatar_manifest.bin` and the file must be **exactly 1000
bytes** - the same manifest decoded below. So the manifest is the complete
portable definition of an avatar, and the item GUIDs in it are resolved against
the closet, not against the asset pack.

## The `.Avatar` manifest, read as big-endian

`Avatar6400/6404/6411.Avatar` are 1000 bytes each and differ from one another in
56 bytes, so they are three saved avatars, not a template. Read **big-endian**,
the file is a small header followed by GUID-tagged records:

    offset 0    u32 0
    offset 4    f32 -0.5      (6400: -0.5, 6411: -1.0)
    offset 8    f32 -0.5      (6411: -1.0)
    ...         u32 value | u16 <group> | u16 0x0003, then
                c1c8f109 a19cb2e0 (a fixed 8-byte marker)

The marker repeats 16 times, each preceded by an 8-byte tag whose value takes
forms like `0x00100000`, `0x00008000`, `0x031F0003`, `0x02EA0003` - the
`0x03xx0003` family are item ids, the `0x0000____` ones are flags. Around offset
240 sits a run of packed RGBA (`ffd7aa71`, `ff6e5326`, `ffb56157` ...), which
reads as the avatar's colours: skin, hair, eyes and so on.

The tail is the most informative part: a symmetric run of powers of two
(`1, 2, 4, 8, 0x10, 0x20` then back down `0x20, 0x10, 8, 4`), each pair carrying
an id. That is a set encoded as a bit path, i.e. which slots of the avatar are
filled - not geometry and not a transform.

**There is no height/weight pair in it.** Sweeping every 4-byte word of all three
files for big-endian floats in 0.2 to 4.0 yields exactly three hits per file:
the two header values at offsets 4 and 8 and a single `1.0f` in 6400. So the
manifest cannot supply the width factor that the NXE body and clothing disagree
by, and that earlier guess is now a checked, negative result.

## Every asset class in the pack, by STRB block id

All 1079 entries in `AvatarAssetPack.toc` were opened and classified by the block
ids they carry. There are only four signatures, and the block ids are a complete
class map:

| blocks | assets | class | first payload bytes |
| --- | --- | --- | --- |
| 3, 8 | 546 | model (geometry) | model header, see `read_model` |
| 4, 8 | 266 | blend shape / morph | `00000000 d4130000 01000000 02000300 c1c8f109…` |
| 2, 8 | 187 | blend shape variant | `aa090000 …` then float-looking deltas |
| 1, 8 | 41 | animation clip | `6c000000 0080a041 47000000 …` |
| 3, 7, 8 | 39 | model + colour table | 109-byte type 7 table |

Block 8 is always present and always 15 bytes - a fixed little header, not
geometry: `02 <class> <subclass>` then a small count and zero padding
(`02 01 01 00000002 … 02` for a model, `02 03 04 …` for an animation).

Block 7 appears only on the 39 sport-top models and is a colour table of
`u32` + RGBA pairs (`232323ff` grey, `b7630fb7…`), i.e. kit stripes.

**There are no texture assets in the pack.** The block ids present anywhere are
only `{1, 2, 3, 4, 7, 8}`, none of which carries image data, and no entry name
is a texture (the two matches for "texture" are item names, `Female Tartan
Skirt Re-textured` and a hiding template). What a model does carry is a
per-vertex colour field - `read_model` calls a colour serialiser once per vertex
and currently discards the result - plus, on the 39 sport tops, the type 7
colour table. So the item artwork is expressed as colour rather than as images,
which is why the theme's 2D art had to be drawn from the source's own UI art:
there are no item textures in this build to lift.

It also explains an earlier puzzle. The 41 `Animation Generic *` clips in the
pack are *item* animations (emotes such as Clap, Wave, Celebration); they carry
~0 translations and pose a different rig because they are not the body's idle.
The avatar itself is posed by the standalone `IdleOffScreen.AvatarAnimation`,
which is a separate file beside the pack.
## The decode bug that made every mesh a sheet - solved

Every earlier note in this file that called the body "flat", "a pair of thin
tubes" or "authored at a different width from its clothing" described corrupted
data, not the pack. The cause was one line: the quantised lattice values were
read **signed**.

`open-avatar-lib`'s `docs/FORMATS.md` 3.3 states the rule - position is
`min + q * step * k` with `k = (2, 2/sqrt(1.5), sqrt(3))` and `q` an **unsigned**
count - and gives `MaleBody`'s bounds as x +-0.711, y 0.005..1.167,
z -0.103..0.149. Sign-extending `q` shifted every mesh by half its quantisation
range, shearing each one into sheets and making it asymmetric.

With `VectorSerializer.read` reading unsigned:

| asset | before (signed) | after (unsigned) |
| --- | --- | --- |
| `MaleBody` | x -1.599..0.188, y -0.751..0.761, z -0.285..0.086 | **x -0.711..0.711, y 0.005..1.167, z -0.103..0.149** |
| `FemaleBody` | - | x -0.708..0.708, y 0.006..1.163, z -0.091..0.117 |
| `Head` | x -0.114..0.115, y 0.946..1.316 | x -0.147..0.147, y 1.131..1.497, z -0.167..0.167 |
| `Peak (Hat)` | x -0.363..0.089 | x -0.138..0.138, y 1.176..1.331 |

`MaleBody` now matches the reference exactly, and all 585 model blocks in the
pack still decode with zero failures. The head sits at y 1.13-1.50 above a body
0.005-1.167 tall, and the hat lands on the head, so the parts agree with each
other without any per-asset scale.

The 3D avatar therefore works end to end: skinned through the 71-joint rig with
frame 0 of `IdleOffScreen.AvatarAnimation` (standing, arms down), body, head,
hair, tee, jeans and shoes assemble into one figure, and `bake_turntable.py`
writes the 24 frames `AvatarStage3D` plays - they are in
`avatar/assets/3d/turntable/`.

Two conventions worth carrying forward. The clip must be passed with **no**
conjugate flag for the standing pose: conjugating the rotations raises the arms
into a cheer (y up to 1.481), which earlier notes mistook for the idle. And the
`Head` is not a special case needing bone-local placement; it skins like every
other mesh.

## Everything in the archive, audited

`decode_audit.py` walks the whole source archive, identifies each file by magic
rather than by extension, runs the matching decoder and writes
`DECODE_COVERAGE.md`. Current state: **2298 files, 767 MiB, none unidentified.**

| what it turned out to be | files |
| --- | ---: |
| text (meta, scripts, toml, ini, xap, json, xml, html) | 1766 |
| XPR0 textures (the dashboard's skins, in `.xbx`) | 136 |
| WAV | 92 |
| dashboard orb containers (`.xm`) | 74 |
| Chromium PAK resource bundles | 58 |
| PNG | 55 |
| PE images (`.dll`/`.exe`, PowerPC and x86) | 31 |
| XIP0 dashboard packages | 27 |
| STRB avatar assets | 20 |
| MP3 | 9 |
| avatar descriptions | 6 |
| TOC, XEX2, XBE, XTF, XTT, TTF, ICO, JPG, BMP, MP4, ICU, V8 snapshot | 1-4 each |

The archive is a CEF application wrapped around the original dashboard's file
system (`resources/ogxbox/uix/xboxfs/Q/...`), with the two avatar editors beside
it as `avatareditor.xex` plus their asset packs - which is why it holds Chromium
formats (PAK, ICU data, V8 snapshots) next to Xbox ones.

**Still short of a full decode, with the reason:**

* the two `avatareditor.xex` files - the body is LZX-compressed and
  title-encrypted, so only the XEX2 header reads without the console's keys;
* PE and the fonts decode their headers and tables; `DECODE_COVERAGE.md` says how
  deep each one goes.

## The animation library

The asset pack carries **41 animation clips, 5500 frames in total**, every one
decoded by `avatar_pose.py` at 71 joints. They are the editor's whole repertoire:

| group | clips | frames each |
| --- | --- | --- |
| `Closet Sleep` | 1 | 68 |
| `Creator Look *` (9 directions) | 9 | 108 |
| `Generic Stand 0`-`7` | 8 | 98 - 428 |
| `Generic Wave`, `Celebration`, `Clap` | 3 | 68 - 108 |
| `Male` / `Female` idles | 7 | 101 - 254 |
| emotes (`Angry`, `Laugh`, `Yawn`, `Confused`, `Sad Cry`, `Shocked Surprised`) | 12 | 64 - 128 |

The standing idle the theme bakes from is `IdleOffScreen`, which is **only 2
frames** - that is why 3D mode reads as a still picture while it turns. The pack's
real idles are far longer (`Male Idle Shifts Weight` 242, `Female Idle Looks
Around` 101, `Generic Stand 1` 428).

So 3D mode has two bakes. `bake_outfits.py` makes the static turntable - one
pose across 20 yaws, one set per hairstyle. `bake_animated.py` makes an animated
set for the default look: **12 yaw angles crossed with 6 poses** sampled evenly
across `Male Idle Shifts Weight` (clip frames 0, 40, 80, 120, 161, 201 of 242),
72 images, 3.1 MB, written as `yaw_YY_pose_PP.png` in `assets/3d/animated/`.
Twelve angles keep a turn at 30 degrees a step, close to the 20-frame
turntable's 18; eight angles read as stepping.

`AvatarStage3D` probes those names first and, if they are there, drives yaw from
its spin timer and pose from a second 200 ms timer, opening at the front angle
instead of the back. Because the set is baked for the default hairstyle, the
editor only offers it while the player wears that hair (or none picked); picking
another hairstyle falls back to that style's own static turntable. Baking all
five would have been ~10 MB on top of a 7 MB theme, so this is the trade.

Both stages frame the avatar the same way: the editor's own mirror border
(`assets/_ui/xex/closet_mirror_border.png`, lifted from `avatareditor.xex`) is
drawn 12% around the 2:3 canvas in 2D and around the baked frames in 3D, so
switching modes changes the avatar, not the framing. The portrait grab takes the
avatar alone, without the mirror.

The closet pose (`Closet Sleep` frame 0) turns out to be an ordinary stand with a
slight head tilt, so there is nothing to gain from swapping it in.

The four `RunOut` clips and `RunIn` carry root translation as well as limb
motion: `RunIn` walks its root 1.75 units during its 40 frames and settles at
about 0.02, which is an arrival rather than a loop. The theme does not play it,
because the clip only says how far the avatar moves - the camera that turned
that into the original's run-in shot is not in the file, and inventing one would
be guessing at the screen.

Ten more clips ship as standalone files beside the pack - `RunIn`, `RunOutShort`,
`RunOutMedium`, `RunOutLong`, `RunOutStandard`, `Look`, `Cheer`, `Gift`, `Salute`
and `IdleOffScreen`. Those are the editor's entry and exit business: the avatar
runs in when the editor opens and runs out when it closes, which is why the four
`RunOut` variants exist at 33-40 frames apiece.

## The two editors' XEX headers

`avatareditor.xex` in each editor is an Xbox 360 executable: `XEX2`, big-endian
header, PE image at 12288 (2008) and 28672 (2010), and 13 or 15 optional headers.
The 2010 image encrypts its whole PE, so only its XEX2 header reads. The 2008
image does **not**: its PE headers and section data are in the clear, so it gives
up its section table (`.rdata`, `.pdata`, `.text`, `.data`, `.XBMOVIE`, `.idata`,
`.XBLD`, `.reloc`) and the strings in them - see `XEX_NXE2008_STRINGS.txt`, made
by `xex_strings.py`. Both builds' header library lists are plaintext, and say
what each editor is built on:

| 2008 (nxe2008) | 2010 (metro2010) |
| --- | --- |
| XAPILIB, XBOXKRNL, LIBCMT | XAPILIB, XBOXKRNL, LIBCMT |
| **XAVATAR** | **XAVATAR** |
| XUIRUN, XUIRNDR (dashboard UI runtime + renderer) | XUIRUN, XUIRNDR |
| XGRAPHC, D3D9, D3DX9 | XGRAPHC, D3D9, D3DX9 |
| XAUD, XNETY, XONLINEP | XAUD, XNET, XHTTP, XONLINEP |
| | **NUIHNDL** (Kinect) |

So both are dashboard UI-run applications drawing their avatar through the
`XAVATAR` library on D3D9, and the 2010 build adds networking and the Kinect NUI
handle - which is why the archive also carries the Kinect Fun Labs packages. The
binary's own description string is `AvatarEditor.exe`, and the 2010 image carries
the path `$SEP\20312500\AvatarEditor.xex`.

The 2008 build's strings also name the pieces it was made of:

* **tone slots** - `SkinTone`, `EyeBrowTone`, `EyeShadowTone`, `IrisTone`,
  `MouthTone`, `SkinFeature1Tone`, `SkinFeature2Tone`, which is the naming behind
  the description's nine colours at 0xFC; `texSkinFeatures` is the texture those
  last two paint from;
* **shaders** - `shader_body_opaque`, `_shiny`, `_transparent`, `_shadow`,
  `shader_head_opaque`, `shader_head_shadow`, `shader_simpleshadow`, and the
  loading screen's `loading`, `loadingbact`, `loadingmist`, `loadingstars`;
* **animations** - nineteen `*.MsLiveAvatarAsset` entries: `closet_spin`,
  `closet_spin_mirrored`, `closet_examine_headgear`, `_upper_body`,
  `_lower_body`, `_shoes`, `closet_balance_left` with its `_into`/`_outof`
  transitions, and the `creator_*` set (`pick_me`, `run_on`-`run_on4`,
  `run_off`, `float`, `floating_celebrate`). These are separate animated assets
  and are not inside `AvatarAssetPack.toc`, which carries the idle and wardrobe
  clips instead;
* `AvatarPhotoBoothEnabled`, the flag behind the portrait capture.

## The orbs are plain meshes

An `.xm` holds no parts or animations, only geometry, and its layout closes
exactly on all 74 files in the archive:

    u32 version = 4
    u32 triangle count
    u32 unknown (a float bit pattern on some, a small integer on others)
    u32 vertex stride (24 or 32 bytes)
    u32 vertex count
    u32 index count
    vertices: position (3 floats), normal (3), and for the 32-byte stride a uv pair
    indices:  u16, values 0..count-1

The check that settles it is arithmetic: `24 + vertices * stride + indices * 2`
equals the file size for every mesh, header triangle count equals indices / 3,
and the largest index is always vertexCount - 1. `Deathstar.xm` decodes to 4338
vertices and 8334 triangles inside a unit sphere and renders as the orb sphere
with its dish, which is what an orb is: `xm_mesh.py` exports OBJ or a PNG
preview.

## The dashboard's screens are text

An XIP0 is a 12-byte header and then **uncompressed scene text** in a VRML/X3D
dialect - `DEF Music_Arm Transform { children [ Shape { appearance Appearance {
material MaxMaterial { name "DarkenBacking" } } geometry DEF ...-FACES Mesh {
url "...-FACES.xm" } } ] translation ... }`. `xip_scene.py` reads them:

* 27 packages parse; the 3 other `.xip` files are XBE executables, not scenes;
* 5659 node definitions, 2835 geometry references, 80-596 per screen;
* the meshes are the `.xm` files, one per node, in a folder named after the
  package (`music2.xip` + `music2/MU_backing_cd-FACES.xm`);
* only **175 of 2835** references resolve - the archive ships a few meshes and
  `.meta` sidecars for the rest, so most dashboard geometry simply was not
  included. That is a gap in the source, not a decoder failure.

So the dashboard screens are scene graphs referencing mesh files, and the
material names (`PanelBacking_01`, `XBOXgreen`, `GameHilite`) are the palette the
skin textures are painted with.

## The dashboard's own textures

`xpr0_export.py` turns the `.xbx` skins into PNGs: all 135 export, and the
images are clean (a skin's `dvd_button` comes out as its rounded bevel, the
`decept` background as its scanline graphic). Two layouts occur:

* **DXT1** at 512x512 or 128x128 - payload is `side * side / 2` bytes;
* **DXT5**, payload `side * side`;
* **a base image plus a mip tail** - `cellwall.xbx` is 256x256 DXT5 with its
  mip chain, every level allocated in whole 2048-byte sectors, so 32 + 8 + 2 + 1
  = 43 sectors and a 90112-byte file;
* **two stacked DXT1 planes**, also `side * side`. Guessing DXT5 for those
  decodes to block noise, and the first plane alone is a clean picture, so the
  exporter decodes both ways and keeps the smoother result (0.8 versus 14.7 for
  `decept.xbx`). The second plane is a separate layer, not an alpha mask: on
  `decept` it is a green scanline and spiderweb overlay.

All 135 textures now export. Nothing is per-pixel swizzled and no 8-in-16 swap is needed: the payload decodes
with the same DXT decoder as the avatar pack, byte order untouched. The only `.xbx` files that are
not textures are four INI playlists carrying that extension.

## The face: UVs are half floats, and the masks clamp

Two decode mistakes kept the head blank, both found while painting it:

* **Texture coordinates are IEEE binary16, not fixed point.** Reading the two
  halves of each coordinate as `u16 / 65535` squeezes the whole head into
  u 0.11..0.24, v 0.10..0.24 - a corner of the texture no face mask reaches, so
  every triangle sampled empty. Reinterpreting the same bits as half floats
  gives the ranges the reference describes: eyebrows and eyes in UV sets 2 and 3
  mirrored across the nose (u 0.01..1.30), the mouth in set 4 starting at u 0.50
  on the middle line. `avatar_mesh.half_to_float` is the conversion.
* **The head's eyebrow, eye and mouth slots clamp.** Sampling them with wrap
  copies the mouth mask onto both cheeks - the reference records these slots as
  address mode 0 for exactly this reason. `sample_texture(..., clamp=True)`.

With both fixed, the masks land where they should: brows at y 1.29..1.33, eyes
just below, the mouth at y 1.19. Swapping the first two sets puts the eyes above
the brows, which is how that mapping was ruled out.

The bake paints one colour per triangle from the masks: any triangle whose
centroid falls inside a mask takes that feature's description colour (eyebrows,
eyes, mouth) and the rest stay skin. Giving a triangle to a feature when only
one of its corners touched the mask smeared the brows and eyes across half the
face, so the centroid decides alone.

## Colour: what decodes and what is missing

`read_model` now keeps the two things it used to discard - each vertex's UV sets
and the material records - and decodes textures:

* **Materials** parse as documented: each mesh carries 24-byte records
  (`u32 type, u32 id, 16 bytes`). Ids 22/23/24/27 are float4s, id 1 is the base
  colour texture, id 2 the tint mask, each with its own UV set. `Male Power Tee`,
  `MaleBody` and `Worn Jeans` all bind id 1 -> texture 0 / UV set 0 and id 2 ->
  texture 1 / UV set 1.
* **DXT** decoding works. The 187 texture assets (block id 2) decode to clean
  pictures: `Straight Eyebrows` is a 128x64 DXT5, 5 frames, 8192 bytes a frame,
  and comes out as the eyebrow mask shape on transparent - the red tint mask the
  colour rule expects, not a scrambled mess.
* **Item models embed no textures at all.** Their texture count is 0, and the
  Head's six slots are all empty (`flags & 1`), which the reference also records.

* **Block id 7 is a per-item colour table**, and it is stored uncompressed, so
  `decompress` on it fails by design. `Male Power Tee` holds 109 bytes that read
  as a small count followed by RGB triples - charcoal `232323`, orange `b7630f`,
  pink `dd1c5d`, `dcdcdc`, `5d5d5d`, `f969dc`, `e605b4`, `ea6238` - most of them
  repeated three times, which matches the description's three custom-colour
  slots per item. The exact framing (where the first triple starts, what the
  leading word counts) is not pinned yet, so the bake does not use it.

So an item's colour is not in its own asset: the base and tint mask come from
the description's colours (the packed RGBA run in the `.Avatar` manifest) applied
by the rule in open-avatar-lib's FORMATS.md 3.6 - `lerp(base, mask.r*C1 +
mask.g*C2 + mask.b*C3, mask.a)`. Colouring the bake properly therefore needs the
manifest colours wired to the material ids, not more geometry work. Until then
the baked frames are deliberately one clay colour.

## What is still open for the 3D avatar

The geometry is solved; what remains is two smaller things.

* **The theme's items have no 3D counterpart yet.** The closet's clothes are the
  theme's own 2D art, not pack assets, so a chosen tee cannot change the baked
  figure. Mapping each theme item to a pack asset id is the missing piece; the
  tunable path is `avatar_tools/bake_avatar.py`.
* **Joint names.** The rig is now known from the XNA Game Studio 4.1 reference
  (`AvatarBone`): Root 0, BackLower 1, HipLeft 2, HipRight 3, Head 19,
  ShoulderLeft 20, ElbowLeft 25, WristLeft 33, fingers 37-70, with the unnamed
  indices being helper bones that carry the skin. This port's hand-written names
  predate that and should be replaced by the published list before any bone-level
  claim is made again.

Earlier hypotheses that are now settled and wrong: a per-asset scale, a hidden
float buffer, derived bone orientations, a stale clip and a broken serialiser.
The meshes were being sheared by a signed read of an unsigned lattice count.
