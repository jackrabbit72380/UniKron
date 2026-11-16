# CustomColorTable (STRB block 7)

Earlier work recorded item colours as missing because every garment's texture slot
is empty. That was looking in the wrong block: **405 of the 1,079 pack assets carry
a `CustomColorTable` (block 7)**, and three of them hold a real palette.

## What the block contains

| assets | payload | shape |
| --- | --- | --- |
| 402 | 28 bytes | `u32 count = 1`, then 6 × RGBA: opaque black, clear, opaque black, clear, opaque black, clear |
| 3 | 109 bytes | `u32 count = 9`, then 24 bytes of base colour, then 9 colours × 9 bytes |

The 402 standard items therefore hold only **placeholder** colours (black and
clear), which is consistent with their empty texture slots: for those items the
colour is not in the pack.

## The three items that do carry a palette

`Male Power Tee`, `Female Power Tee` and `Tight Tee`. Each palette colour is
stored as **three identical RGB triples** (9 bytes); the middle/interpolation
role of the repeats is not established, so the reader takes the first triple.

| Male Power Tee / Female Power Tee | Tight Tee |
| --- | --- |
| `#232323` base | `#A65D0F` base |
| `#B7630F` | `#7DC513` |
| `#DCDCDC` | `#C18952` |
| `#C5D5D5` | `#59A2F0` |
| `#5D5D5D` | `#5AA1F0` |
| `#DD1C5D` | `#762FF0` |
| `#DDDBDC` | `#5AA2C9` |
| `#F969DC` | `#355AF0` |
| `#E605B4` | `#B7B196` |
| `#EA6238` | — |

The Male and Female Power Tee tables are byte-identical.

## The `.Avatar` descriptors carry the real thing

`Avatar Games.zip` (the avatar-games collection) ships `Avatar6400.Avatar`,
`Avatar6404.Avatar` and `Avatar6411.Avatar` - the 1,000-byte descriptions the
console hands the avatar system. Each holds **nine colour slots at 0x0fc**,
stored as A, R, G, B with alpha always 0xff. (Earlier notes said eight at 0x100;
reading the files byte by byte fixes both numbers, and finds a ninth colour that
was being dropped.)

| file | nine colours in order |
| --- | --- |
| Avatar6400 | `#d7aa71` `#6e5326` `#b56157` `#6381a7` `#493421` `#5395ca` `#493421` `#cf5969` `#cf5969` |
| Avatar6404 | `#98652f` `#553921` `#875741` `#727f35` `#553921` `#a2a89b` `#0d0d0d` `#81271f` `#81271f` |
| Avatar6411 | `#d7aa71` `#1f120b` `#cf8562` `#5b351e` `#1f120b` `#904f33` `#1f120b` `#ad5f47` `#ad5f47` |

Two of the nine can be named from evidence:

* **index 1 is hair.** `#6e5326` in Avatar6400 is the brown the bake scripts had
  been passing as `HAIR_COLOUR`, so these are the colours the retail avatar
  actually wears - the per-avatar answer to the tint values the pack omits.
* **index 0 is the skin tone.** Avatar6400 and Avatar6411 share `#d7aa71` while
  their hair differs, which is what a skin slot does and a garment slot does not.

The other seven are not named. They are recorded in order rather than guessed at.

## The skin the bakes actually use

This matters for fidelity and is currently a known difference. The pack's body
meshes carry a flat material colour, and a baked body plate converts to about
`#a7845b` under the baker's lighting; the retail avatars above wear `#d7aa71`.
The pack has no body texture to tint, so the game must be replacing or
multiplying that material colour with the descriptor's index 0 - and which of the
two it does is not established. Nothing is rebaked on that guess: the bodies are
rendered with the pack's own material colour, and this note is the record that the
retail skin tone is a different, known value.

## Reproducing

```python
import avatar_mesh

blocks = avatar_mesh.strb_blocks(blob)          # blob = pack[offset:offset+size]
table = next(p for i, _, _, p in blocks if i == 7)
```

`asset_catalog.py` records every asset's block list, so the colour table's
presence and size are in `asset_catalog.json`.
