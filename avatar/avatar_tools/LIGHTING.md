# How XTL lights and frames an avatar

Extracted from the 2008 XTL avatar renderer (`default_uncompressed.xex`, 6,618
functions) and the editor that drives it (`nxe2008/avatareditor.xex`, 1,986
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

## What is still not in the archive

The **colours** (`ambientColour`, `lightColour1..3`, `rimLightColour`) and the
**shadow strength** have no stored defaults: the name table carries names and
types, the effect blobs carry directions, and every colour slot around the rig is
zero. They are supplied by the scene when the dashboard renders an avatar, and
that scene data is not in this dump - the same wall as the missing textures.

`bake_turntable.py` therefore names its constants after the recovered parameters
and uses this port's chosen colours, documented in the file, calibrated so the
three recovered directions read softly rather than as a hard top light.

## Camera

The camera is `c_projection` x `c_modelview` with `InvViewport` for
screen-space reconstruction, and no field of view is stored as a constant - the
host supplies the projection matrix. The bake therefore keeps the orthographic
2:3 framing it had, which is a display choice, not a recovered one.

If a future dump supplies the editor's scene settings, only the colour constants
need changing; the directions and the shading path already match the renderer.
