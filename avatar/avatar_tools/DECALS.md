# The face, and the decals that sit on it

The head is a single mesh with **six UV sets**, and its material list binds one
texture slot to each of them. That list is what settled which sheet goes where:

| UV set | texture slot | size | role |
| --- | --- | --- | --- |
| 0 | 5 | 128×128 | skin, and **face paint** |
| 1 | 6 | 128×64 | **facial hair** |
| 2 | 7 / 8 | 64×64 | brow tint mask |
| 3 | 9 / 10 | 64×64 | eye tint mask |
| 4 | 12 | 64×64 | mouth tint mask |
| 5 | 11 | 128×64 | not used by anything tested |

(Batches 0 and 1 both bind six slots; they differ in ids 7/8 and 9/10, so the head
carries two passes.)

## Established by rendering

`probe_decal_render.py` applies a sheet on one set at a time and renders the head.
Three independent checks agree:

* `calm-eyes.png` on **set 3** draws two eyes in the eye sockets — the control, and
  it matches `FACE_SETS` (2, 3, 4 = brow, eye, mouth).
* `beard.png` on **set 1** covers the jaw and chin and leaves the lips clear.
* `comb-moustache.png` on **set 1** draws a bar exactly above the lip.
* `butterfly-facepaint.png` on **set 0** spreads across the cheeks and brow.

Two sheets of the same kind landing correctly is the evidence; a single lucky
placement would not be.

## The two kinds of sheet

* **Facial hair is a tint mask, not colour art.** `beard.png` is red where the hair
  goes, black elsewhere. Compositing it as colour painted the face red; tinting it
  with the hair colour from the description is what makes it a beard.
* **Face paint composites by alpha, and its colour is red.**
  `butterfly-facepaint.png` is red line art on a transparent background, and it
  renders red across the cheeks and brow. Whether that red is meant to be tinted
  by a per-item colour slot is **not established**: the pack carries palettes for
  three items only (`Male Power Tee`, `Female Power Tee`, `Tight Tee`), so nothing
  names a paint colour. It is drawn as authored rather than recoloured.
* `camo-facepaint` is fully opaque — zero texels under 0.5 alpha — so its shape
  comes from the RGB, not from transparency.

## What is baked and what is not

`bake_pack_turntables.py` applies both kinds while baking (`DECAL_SETS`), so every
`45_facial-hair` and `16_face-paint` item has a six-frame set with the decal on the
avatar's face.

The 43 `15_face` eye sheets are baked the same way: `bake_pack_turntables.py`
passes each one as the middle of `bake_avatar.py`'s three-mask triple
(`--face=Straight Eyebrows,<item>,Smirk Mouth`), so the pack's eye art replaces the
built-in sheet and the brow and mouth stay. `Soft Lashes` and `Soothing` go
through the same path. **Not done:** the 18 noses, which are not art at all - they
carry a `ShapeOverrides` blob and are head shape morphs (see CATALOG.md).

## The 2D editor's copy of these sheets

The editor cannot use a sheet directly, so `bake_pack_face.py` bakes one overlay
plate per item: it renders the pose frame with and without the sheet on the head
and keeps the difference, feathered between `6/255` and `24/255` so the sheet's own
antialiased border does not leave a rectangle. 87 plates came out
(44 eye sheets, 26 face paints, 17 facial hair; the noses are morphs and `Happy
Eyes` matches the default head, so neither has a plate). They composite above the
body plate and below the hair, in category order. See CATALOG.md for the blend fix
this turned up - the art term now carries the sheet's own alpha.

## Re-running the probes

```
python3 probe_decal_uv.py ../pack_art/45_facial-hair/beard.png
python3 probe_decal_render.py ../pack_art/45_facial-hair/beard.png:1 /tmp/head.png
python3 probe_decal_render.py ../pack_art/45_facial-hair/beard.png /tmp/all.png
```

Passing `PATH:SET` pairs picks sets explicitly; passing a bare sheet tries every
set in turn.
