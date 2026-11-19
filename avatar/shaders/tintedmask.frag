#version 440

// Tinted mask fragment stage, Qt 6 ShaderEffect form.
//
// Qt 6 no longer compiles GLSL strings at run time: `fragmentShader` must point
// at a .qsb pack built by `qsb`, and the source has to be Vulkan-flavoured GLSL.
// Qt 5 spelled this shader with `varying`/`texture2D`/`gl_FragColor`; the maths
// below is unchanged.
//
// The std140 block at binding 0 is shared with the default vertex shader, so it
// has to start with qt_Matrix (offset 0) and qt_Opacity (offset 64) even though
// this stage uses neither: Qt writes one buffer for both stages and puts custom
// members after those two. Declaring `colour` first put it at offset 0 and it
// arrived as zero - a black mask with no error. `colour` is TintedMask's `tint`.
// Samplers take their own bindings, starting at 1.
//
// The mask's RGB is the sheet's lighting, its alpha the sheet's coverage, both
// straight. Multiplying by the palette colour in linear light and re-encoding
// reproduces the plate the baker would have produced for that colour; see
// avatar_tools/COLOURS.md for the measured agreement.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 colour;
};

layout(binding = 1) uniform sampler2D tex;
layout(binding = 2) uniform sampler2D spec;

void main() {
    // Qt Quick hands Image and ShaderEffectSource textures over premultiplied
    // (see "Shader Inputs and Resources" in the ShaderEffect documentation), but
    // the masks store straight lighting and straight coverage. Multiplying the
    // premultiplied value by coverage again squared the alpha: an eye-shadow mask
    // at 177/255 came out at 48 % of the plate instead of 69 %. Divide it back
    // out first.
    vec4 c = texture(tex, qt_TexCoord0);
    vec4 s = texture(spec, qt_TexCoord0);
    vec3 mask = c.a > 0.0 ? c.rgb / c.a : vec3(0.0);
    vec3 spec = s.a > 0.0 ? s.rgb / s.a : vec3(0.0);
    vec3 lin = pow(mask, vec3(2.2)) * pow(colour.rgb, vec3(2.2))
               + pow(spec, vec3(2.2));
    fragColor = vec4(pow(lin, vec3(1.0 / 2.2)) * c.a, c.a);
}
