import QtQuick 2.15

// One face-feature tint mask, coloured at run time.
//
// The mask is baked by `bake_pack_face.py --mask`, which calls
// `bake_turntable.render(..., coverage=True, only=...)`: RGB is the lighting on the
// sheet alone and alpha is the sheet's own coverage, both straight. Premultiplying
// RGB by the palette colour and by alpha reproduces the plate the baker would have
// produced for that colour - measured on the brow, eye-shadow and facial-hair sets,
// plate / mask equals the slot colour with a spread under 1.3 % (avatar_tools/
// COLOURS.md). Doing it by differencing two tinted renders does not work, which is
// why the renderer emits coverage.
//
// The eye is the one sheet with a second term. The renderer shades `albedo * light`
// and adds a specular, and on the iris the specular is a fifth to a quarter of the
// pixel, so a mask carrying only the lighting reproduced the shipped plate to a mean
// of 28/255 and turned a blue iris grey. `specSource` is that second term, baked by
// avatar_tools/make_eye_masks.py; with it the plate comes back to 5.9/255. A mask
// without it samples a transparent texture and the result is the plain multiply.
Item {
    id: mask

    property url source: ""
    property url specSource: ""
    property color tint: "#ffffff"

    Image {
        id: art
        anchors.fill: parent
        source: mask.source
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: false
    }

    ShaderEffectSource {
        id: texture
        sourceItem: art
        hideSource: true
        live: true
    }

    // Empty for every mask that has no specular term, and then the sampler is
    // transparent black - adding zero, which is exactly the old behaviour.
    Image {
        id: specArt
        anchors.fill: parent
        source: mask.specSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: false
    }

    ShaderEffectSource {
        id: specTexture
        sourceItem: specArt
        hideSource: true
        live: true
    }

    ShaderEffect {
        anchors.fill: parent
        property variant tex: texture
        property variant spec: specTexture
        property color colour: mask.tint
        // The tint is applied in linear light, because the baker shaded in linear
        // light and only encoded the result to sRGB: multiplying the encoded bytes
        // would darken a dark colour and wash out a light one. The specular term is
        // added there too, where the renderer adds it. The result is written
        // premultiplied, which is what a ShaderEffect's output is taken to be, so
        // the stage composites it over the skin with the usual source-over.
        //
        // Qt 6 does not compile GLSL strings at run time. An inline `fragmentShader`
        // string is read as a file name and fails with "Failed to deserialize QShader",
        // so no tint was drawn at all until this pointed at a baked pack. The source
        // is shaders/tintedmask.frag; `python3 avatar_tools/make_shader.py` rebuilds
        // the .qsb beside it.
        fragmentShader: "shaders/tintedmask.frag.qsb"
    }
}
