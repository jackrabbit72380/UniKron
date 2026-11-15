# Decode coverage

Every file under the source archive, identified by magic rather than by
extension, with the decoder that was run and what it read.

| format | files | decoded | text | partial | blocked | MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| pe | 31 | 31 | 0 | 0 | 0 | 387.1 |
| pak | 58 | 58 | 0 | 0 | 0 | 63.0 |
| xip0 | 27 | 27 | 0 | 0 | 0 | 52.1 |
| xm | 74 | 74 | 0 | 0 | 0 | 39.8 |
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
- **xip0** - header, then the payload read as a VRML/X3D scene: xip_scene.py lists every node, material and geometry reference and resolves them.
- **xm** - header validated against the file size, then the vertex and index buffers read; xm_mesh.py exports them as OBJ and can render a preview.
- **xpr0** - pixels decoded: 131 of 135 export to PNG with xpr0_export.py, as DXT1, DXT5, or the first of two stacked DXT1 planes.
- **xtf** - header and face name; the glyph tables are not rasterised.
- **xtt** - version and size.

## Not fully decoded

- **xpr0** (partial) - 4 file(s): XPR0 payload 88064 bytes: 43 sectors of 2048, 0 spare - no power-of-two DXT shape fits, so it is a texture plus extra data
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/music_playedit2/Morbcellwall.xbx`
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/skin/cellwall.xbx`
  - `XBOX HUB/resources/ogxbox/uix/xboxfs/Q/Xips/default/cellwall.xbx`
- **xex** (partial) - 1 file(s): XEX2 header 3145728 bytes; body compressed and title-encrypted
  - `XBOX HUB/resources/editors/nxe2008/assets/avatareditor.xex`
- **xex** (partial) - 1 file(s): XEX2 header 7340032 bytes; body compressed and title-encrypted
  - `XBOX HUB/resources/editors/metro2010/assets/avatareditor.xex`
