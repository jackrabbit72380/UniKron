# Avatar award items (awards.zip)

`awards.zip` (186 MB) is a Joy Ride Turbo content pack. Five of its files are
avatar **award item** packages, each named by the item's GUID:

| file | item | mesh |
| --- | --- | --- |
| `00000008-0008-1192-c4df-c23c5841125e.a` | JR Turbo T | 803 verts, y 0.709-1.124 |
| `00000008-0008-11f1-c274-919f5841125e.a` | JR Turbo T | 765 verts, y 0.678-1.134 |
| `00000010-0007-01f2-cf00-85285841125e.a` | JR Victory Pants | 844 verts, y 0.025-0.812 |
| `00000010-0007-91b1-c785-72955841125e.a` | JR Victory Pants | 767 verts, y 0.061-0.789 |
| `00000544-0006-9113-c2d6-99055841125e.a` | Cacti Cap | 1,282 verts, y 1.150-1.607 |

The pairs are the two body types of the same item. `award_items.json` holds each
item's GUID, every localized string in the package and the parsed mesh.

## What a package is

It is a `PIRS` XContent package (title ID `0x5841125E`, Joy Ride Turbo) whose
single file is `asset_V2.bin` at `0xc000`. Layout:

- `0x00` `PIRS`, then a 20-byte SHA-1.
- `0x3e2` **the item GUID** in the manifest's own form - a u32, two u16s and
  eight bytes: `00 00 08 00 | 08 11 | 92 c4 | df c2 3c 58 41 12 5e` for the
  first item above. It matches the filename exactly.
- `0x412` onward: fixed-size UTF-16 slots - the name, then the description, per
  language. For the T-shirt: `JR Turbo T`, `Joy Ride Turbo T`,
  `Camiseta de JR Turbo`, and
  "Wear the official T shirt of the unofficial Joy Ride Turbo fan club".
  The Cacti Cap carries "This cap is surprisingly comfortable, seriously!".
- `0xd048` the asset: the same 12-byte-headered LZX chunks as the closet, here
  two of them (`0x8000` then `0x5909`), giving 55,561 bytes of model.

## The model

The decompressed asset is the same avatar model format as everything else:

```
cpu 0x290  gpu 0x10484  texture buffer 0x7000  vertices 0x7d80  indices 0x1704
batches 1  textures 3  vertex buffer 0x7000  index buffer 0xed80  scratch 0x4000
```

The mesh parses into 803 vertices, 2,946 indices and 7 materials.

## Textures

Every garment declares a **32 x 32 texture, 2,048 bytes per frame**, and the
model reserves a `0x7000`-byte texture buffer with `0x4000` bytes of scratch
after the header. The parser reports the slot as empty (zero bytes of pixel
data) - the same answer the NXE closet gave - so the colours are still not read
out. The Cacti Cap declares no textures at all.

That is the remaining question for this pack: whether the 32 x 32 is a real
palette stored in the scratch region at `0x4000`, which is not zero-filled, or
another declared-but-absent slot.
