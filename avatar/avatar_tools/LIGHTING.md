# How XTL lights and frames an avatar

Extracted from the 2008 XTL avatar renderer (`default_uncompressed.xex`, 6,618
functions) and the editor that drives it (`nxe2008/avatareditor.xex`, 3,095
functions). Reproducible with `xtl_constants.py`, which needs no Ghidra run -
only the ELF `mkelf.py` writes from the same XEX.

    python3 mkelf.py default_uncompressed.xex /tmp/xtlavatar.elf
    python3 xtl_constants.py strings /tmp/xtlavatar.elf --grep "light|shadow|camera"

## The rig, from the shader's parameter table

One packed name blob at **0x92125f16** in the renderer, and repeated per effect
in the editor at **0x98019b0e** (body opaque), **0x9801a8ff** (body transparent)
and **0x9801b797** (head opaque):

    ambientColour
    enableShadows
    jitterMap
    lightColour1   lightColour2   lightColour3
    lightDirection1 lightDirection2 lightDirection3
    oneMinusShadowStrength
    rimLightColour
    shadowMap
    shadowSizes

The body effects also name `CustomColor1..3`; the head effect names the skin
tones (`SkinTone`, `IrisTone`, `EyeBrowTone`, `EyeShadowTone`, `MouthTone`,
`FacialHair`, `SkinFeature1Tone`, `SkinFeature2Tone`) and `texEye`, `texEyeBrow`,
`texEyeShadow`, `texMouth`, `texSkinFeatures`. Vertex shaders take
`c_modelview`, `c_projection`, `c_shadow`; the older shader variant adds
`WorldViewProj`, `InvViewport`, `ShadowOffset`, `ShadowColor`.

So the model is: **one ambient colour + three directional lights, each with its
own colour and direction, a rim colour, and a shadow-strength scale.** Not one
key light, and not a studio two-point.

## The three light directions - recovered

Each avatar pixel shader's effect blob holds a run of five unit vectors, and the
first three are the same bytes at the same offset in all three blobs:

| | x | y | z |
|---|---|---|---|
| lightDirection1 | 0.000 | 1.000 | -0.040 |
| lightDirection2 | 0.440 | 0.528 | -0.757 |
| lightDirection3 | -0.670 | -0.419 | 0.575 |

(0x98019cdc in `shader_body_opaque_ps.updb`, 0x9801aacc in
`shader_body_transparent_ps.updb`, 0x9801b990 in `shader_head_opaque_ps.updb`.)

An overhead key leaning toward the camera, a front-right fill and a back-left
rim - which is why reference avatars read evenly lit from above rather than lit
from one side. `bake_turntable.py` now uses exactly these three vectors.

## The editor's own scene lights - recovered

Those colours are not in the effect blobs, but they are in the editor. Its UI
scene registers four elements in one table (`FUN_980b3c40` in the corpus), each
with a name and a getter:

| element | type | getter | value |
| --- | --- | --- | --- |
| `CameraElement` | 5 | `FUN_980b0e08` | index 0 |
| `AmbientLight` | 6 | `FUN_980b0718` | `0xFF202020` |
| `SunLightDirection` | 7 | `FUN_980b0680` | `(1.0, 0.0, 0.0)` |
| `SunLightColor` | 6 | `FUN_980b0788` | `0xFFFFFFFF` |

So the editor's scene is **one ambient at 32/255 grey (0.1255, 0.1255, 0.1255),
one white directional light pointing along +x**, and no rim light of its own.
The direction is three floats lifted from `.rdata`: `1.0` at `0x9800162c` and
`0.0` twice at `0x980013e0`.

This is the scene the avatar is drawn in, and it is a single sun - not the three
directional colours the effect declares. The shader takes three because XTL lights
are generic; the editor feeds it one white sun plus ambient, which is why the
reference renders read as bright and flat rather than three-point lit.

## What is still not in the archive

The **per-slot colours** (`lightColour1..3`, `rimLightColour`) and the **shadow
strength** still have no stored values: every colour slot around the rig is zero
in the effect blobs, and the scene above supplies one sun colour and one ambient
for the whole UI. How the editor folds white into three slots is a runtime
mapping that the decompiled code does not spell out.

`bake_turntable.py` names its constants after the recovered parameters and uses
this port's chosen colours; they are **not** the editor's. With the scene values
now known, the honest next step is to replace its ambient with `0.1255` grey and
feed the recovered sun direction, rather than keep the calibrated picks.

## Camera

The camera is `c_projection` x `c_modelview` with `InvViewport` for
screen-space reconstruction, and no field of view is stored as a constant - the
host supplies the projection matrix. The bake therefore keeps the orthographic
2:3 framing it had, which is a display choice, not a recovered one.

If a future dump supplies the editor's scene settings, only the colour constants
need changing; the directions and the shading path already match the renderer.
