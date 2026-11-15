# Decode coverage

Every file under the source archive, identified by magic rather than by
extension, with the decoder that was run and what it read.

| format | files | decoded | text | partial | blocked | MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| pe | 31 | 31 | 0 | 0 | 0 | 387.1 |
| pak | 58 | 58 | 0 | 0 | 0 | 63.0 |
| xip0 | 27 | 27 | 0 | 0 | 0 | 52.1 |
| xm | 74 | 0 | 0 | 74 | 0 | 39.8 |
| wav | 92 | 92 | 0 | 0 | 0 | 34.3 |
| png | 55 | 55 | 0 | 0 | 0 | 31.8 |
| xtf | 2 | 2 | 0 | 0 | 0 | 31.2 |
| xex | 2 | 0 | 0 | 2 | 0 | 29.9 |
| toc | 4 | 4 | 0 | 0 | 0 | 28.4 |
| mp3 | 9 | 9 | 0 | 0 | 0 | 19.1 |
| xpr0 | 136 | 132 | 0 | 4 | 0 | 16.1 |
| icu | 1 | 1 | 0 | 0 | 0 | 10.3 |
| text | 1766 | 0 | 1766 | 0 | 0 | 9.3 |
| mp4 | 1 | 1 | 0 | 0 | 0 | 6.7 |
| xbe | 3 | 3 | 0 | 0 | 0 | 5.6 |
| v8snapshot | 2 | 2 | 0 | 0 | 0 | 1.1 |
| strb | 20 | 20 | 0 | 0 | 0 | 0.4 |
| ttf | 2 | 2 | 0 | 0 | 0 | 0.4 |
| bmp | 1 | 1 | 0 | 0 | 0 | 0.3 |
| xtt | 4 | 4 | 0 | 0 | 0 | 0.2 |
| ico | 1 | 1 | 0 | 0 | 0 | 0.1 |
| jpg | 1 | 1 | 0 | 0 | 0 | 0.1 |
| avatar | 6 | 6 | 0 | 0 | 0 | 0.0 |

**2298 files, 804464298 bytes.**

## How deep each decoder goes

- **avatar** - the 1000-byte description: face features, nine colours, item entries.
- **bmp** - dimensions, bit depth and pixel offset.
- **ico** - image count.
- **icu** - entry count from the header.
- **jpg** - container only.
- **mp3** - container only.
- **mp4** - container only.
- **pak** - full resource table: counts, every entry's id and offset validated against the file.
- **pe** - COFF/optional headers, section count and bitness. The code is PowerPC/x86 and is not disassembled.
- **png** - IHDR dimensions.
- **strb** - block count; the blocks themselves are decoded by avatar_mesh.
- **text** - read as UTF-8/UTF-16/latin-1 and line counted.
- **toc** - the avatar pack's record table (offsets and sizes per asset).
- **ttf** - table count.
- **v8snapshot** - version string from the header.
- **wav** - fmt and data chunks: rate, channels, bit depth and audio length.
- **xbe** - base address, image size and entry point; no code executed.
- **xex** - header only: the body is LZX-compressed and title-encrypted.
- **xip0** - header, dimensions and payload size. The payload is dashboard UI data whose semantics are not mapped.
- **xm** - header only; the float body is not parsed.
- **xpr0** - pixels decoded: 131 of 135 export to PNG with xpr0_export.py, as DXT1, DXT5, or the first of two stacked DXT1 planes.
- **xtf** - header and face name; the glyph tables are not rasterised.
- **xtt** - version and size.

## Not fully decoded

- **xpr0** (partial) - 4 file(s): XPR0 payload 88064 bytes: 43 sectors of 2048, 0 spare - no power-of-two DXT shape fits, so it is a texture plus extra data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/music_playedit2/Morbcellwall.xbx`
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/skin/cellwall.xbx`
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/default/cellwall.xbx`
- **xm** (partial) - 3 file(s): XM v4, counts 2208/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Skins/Stock/Inner_cell-FACES.xm`
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Skins/Stock/cellwall.xm`
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Skins/GTA San Andreas/cellwall.xm`
- **xm** (partial) - 2 file(s): XM v4, counts 300/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_panel/ChamferBox01-FACES.xm`
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/passcodeverify/S_Home_panel_backing-FACES.xm`
- **xm** (partial) - 2 file(s): XM v4, counts 340/18/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_panel/Icon_live-FACES.xm`
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/passcodeverify/Icon_live-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 8334/18/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Orbs/DeathStar/Deathstar.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 78960/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/music_playedit2/GM_L2_Arm01_03-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 5034/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/music_playedit2/GM_L2_menubutton_01-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 3284/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/music_playedit2/MU_select_pod_inner-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 66418/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_timezone/S_Lang_pod_shell_01-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 428/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_timezone/message_metapanel_back-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 928/18/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/waitcursor/Tube02-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 94005/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_panel/Circle01-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 61906/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_panel/S_Home_pod_support_02-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 352/274/32; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/message/message_metapanel_back-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 24116/18/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/message/message_support_01-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 892/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/music2/MU_backing_cd-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 89738/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/music2/MU_pod_support_03-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 84168/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/memory2/MEM_L1_console_podshell_03-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 16939/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/memory2/controller1_MU_1_HL-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 113399/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_video/S_Vid__Arm_03-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 392/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_video/S_Vid__videopod_backing01-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 2076/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/dvd/text_panel-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 1956/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/dvd/texture_panel-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 71971/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/bg_mesh/Backing_dna.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 37119/274/32; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/bg_mesh/Backing_dna_SIDES_new.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 22340/18/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/bg_mesh/Backing_squigles.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 12760/18/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/bg_mesh/Backing_squigles_sides.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 44346/274/32; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/bg_mesh/Hearts.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 12760/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/bg_mesh/spirals.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 272/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/music_copy3/Sound_1_panel_back-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 76522/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/music_copy3/Sound_1_tube-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 196/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_language/S_Lang_languagepod_backing-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 72078/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_language/S_Lang_tube_04-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 40/18/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_language/arrow_up-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 26/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/skin/skin.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 12814/18/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/uix_settings/Arm02_01-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 28091/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/uix_settings/Circle01-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 36/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/uix_settings/MU_L3_panel_tracklist-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 268/274/32; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/uix_settings/standard_01-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 7687/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/memory_files2/MEM_L2_sc_pod_icon-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 82367/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/memory_files2/MU_back_probearm-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 2784/18/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/memory_files2/new_highlight-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 820/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_clock/Clock_panel_backing-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 111378/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_clock/Rectangle03-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 18412/18/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/livetoday/Cylinder02-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 20894/274/32; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/livetoday/footer-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 72/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/keyboard/Sound_2_panel_back-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 17780/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/keyboard/Sound_2_tube_04-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 2636/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/mainmenu5/gamepod_backing-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 79636/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/mainmenu5/games_panel_support-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 19892/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/mainmenu5/podsupport_3-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 1022/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_parental/Line11-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 58374/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_parental/S_P_GameModule_140-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 92/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/jkeyboard/Line01-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 16908/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/jkeyboard/Sound_2_tube_04-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 106311/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/passcodeverify/S_Home_GameModule_142-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 49600/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/passcodeverify/S_Vid__tv_screen01-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 63346/18/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/accountselection/Arm_01-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 144/274/32; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/accountselection/menubutton_01-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 644/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_list/S_Aud_panel_backing4-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 117097/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_list/S_Home_videopod-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 17674/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings_list/S_Vid__letterbox_letterbox-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 4724/18/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings3/Icon_live-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 200/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings3/S_Home_panel_backing-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 108733/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings3/S_Home_podsocket_outer-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 48218/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/settings3/S_Main_lock_keyhole-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 9724/18/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/BlackstormX/Arm02_05-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 28870/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/BlackstormX/Atom.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 42404/536870914/16; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/BlackstormX/Clock_clock_body01-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 6714/536871170/24; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/BlackstormX/TV-FACES.xm`
- **xm** (partial) - 1 file(s): XM v4, counts 56/274/32; body is unparsed float data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/BlackstormX/panel02_backing-FACES.xm`
- **xex** (partial) - 1 file(s): XEX2 header 3145728 bytes; body compressed and title-encrypted
  - `XBOX HUB/resources/editors/nxe2008/assets/avatareditor.xex`
- **xex** (partial) - 1 file(s): XEX2 header 7340032 bytes; body compressed and title-encrypted
  - `XBOX HUB/resources/editors/metro2010/assets/avatareditor.xex`
