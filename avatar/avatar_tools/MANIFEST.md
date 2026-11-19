# The avatar save: `avatar_manifest.bin`

Recovered from a real profile in `%APPDATA%\XBOX HUB\avatar profiles\<xuid>\`.
1000 bytes, every integer **big-endian** like the pack, and every choice a 16-byte
record of the same GUID family the pack index uses. `decode_manifest.py` reads one
and resolves every record to an asset name.

## Layout

    +0x000  u32      0
    +0x004  f32  \   two settings; -0.5 -0.5 on the stock male
    +0x008  f32  /
    +0x00c  8 x 16   appearance slots: {u32 slot, u16 asset index, u16 kind, GUID}
    +0x08c  f32      1.0 on the stock male, 0.0 on both stock females
    +0x090  108      zero
    +0x0fc  9 x u32  ARGB colours, alpha always 0xff (0x0fc..0x11f; this said
                     eight - the ninth word at 0x11c equals the eighth on all
                     three shipped profiles, which is how it was missed)
    +0x120  32       body record + 3 zero words
    +0x140  32       head record + 3 zero words
    +0x160  13 x 32  worn items; a record is 16 bytes, then three zero words
    +0x300  4 x 32   a second copy of the last four worn items
    +0x380  16       trailer; `b13ebabe babebabe` and two more words on the
                     profile the hub had written, all zero on the shipped files

The `u16` in a record is the **index into the pack's own asset list**, not a
component id: index 434 is Short with Left Curls (Hat), 571 is Teased Spikes (Hat),
0 is MaleBody, 2 is Head. That is why these can be checked rather than guessed.

## What the four files decoded to

| slot | Avatar6400 (male) | Avatar6404 (female) | Avatar6411 (female) | the uploaded profile |
|---|---|---|---|---|
| ears | Elven Ears | Round Ears | Soft Nose | Elven Ears |
| outer top | Green Hoodie Hiding Template | Baggy Jeans Hiding Template | Blue Full-zip Hoodie Hiding Template | Green Hoodie Hiding Template |
| inner top | Male Sport Top Hiding Template | Male Sport Top Hiding Template | Boots Hiding Template | Male Sport Top Hiding Template |
| face decal | Skull Facepaint | Rosy Cheeks | Stressed Wrinkles | Left Cheek Mole |
| body | MaleBody | FemaleBody | FemaleBody | MaleBody |
| head | Head | Head | Head | Head |
| hair | Short with Left Curls (Hat) | Shaved Pattern (Hat) | Combed Right | Teased Spikes (Hat) |
| shirt | Jacket with Sweater | Sweater with Shirt | V Neck Top | Polo Shirt1 |
| trousers | Male Flower Print Flares | Formal Trouser Suit | Blue Fingerless Gloves | Male Diamond Stud Earrings |
| shoes | Grunge Trainers | Female Jelly Clogs | Snowboarding Jacket | Goth Boots |

Two things fall out of this.

**The appearance slots are the shape-override items.** Elven Ears, Soft Nose, the
hiding templates, the face paint - these are the ones the audit calls "shape
override only", the 266 with no mesh of their own. They are not dead weight: an
avatar *selects* them, which is why they exist. Their geometry has to come from
block 4, since they have no model block.

**The slot word is a bit, not an index:** 1 head, 2 body, 4 hair, 8 shirt,
0x10 trousers, 0x20 shoes, 0x8000 face decal, 0x2000/0x4000 eye shadow, 0x8000
ears, 0x100000 ears... and `0x208` is `0x200|8`, a shirt in the outer layer. The
trousers row above reads "Male Diamond Stud Earrings" because the slot word is what
the *item* declares, and that item was worn in that position - the pack is the
authority on what belongs where, so the labels in `SLOTS` are mostly hints.

## Still unknown

The two settings at `+0x004`. Stock male -0.5, -0.5; the uploaded profile
-0.55, -0.515; stock female 0, -0.5 and -0.5, -1. Two floats that move when the
avatar is edited are the shape sliders, but one sample cannot say which control
each one is, and no pack data refers to them: block 4's declared size is
5,076 = 423 x 12 bytes, while Head has 648 vertices and MaleBody 1,137, so it is
not one float per vertex and not one record per vertex either.
