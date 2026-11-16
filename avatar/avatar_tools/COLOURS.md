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

## Reproducing

```python
import avatar_mesh

blocks = avatar_mesh.strb_blocks(blob)          # blob = pack[offset:offset+size]
table = next(p for i, _, _, p in blocks if i == 7)
```

`asset_catalog.py` records every asset's block list, so the colour table's
presence and size are in `asset_catalog.json`.
