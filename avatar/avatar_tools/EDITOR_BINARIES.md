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

`Avatar6400.Avatar` is 1,000 bytes of 16-byte records following a small header:
`u32 flags, u32 191, u32 191, u32 4096`, then records of

    u32 value | u16 0x03xx | u16 0x0003 | u64 c1c8f109a19cb2e0

with the trailing 8 bytes constant across every record. The `u32 value` field
takes small powers-of-two-like numbers (0x10, 0x08, 0x20, ...) and the middle
u32 varies per equipped item, so the manifest is a list of asset ids plus a
value. It says what an avatar *wears*; it contains no geometry.

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

## What this rules out for the 3D avatar

The flat-shell body cannot be explained by: a different pack version (identical
SHA-1), a hidden float buffer (none exists), derived bone orientations (tested,
no change), a stale clip (the idle's joints move ~0.00 from bind), a missing
limb asset (all 583 meshes share the same proportions), or a wrong serialiser
(verified term-by-term against `serializers.rs`).
