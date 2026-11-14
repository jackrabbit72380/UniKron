import QtQuick 2.8

// ════════════════════════════════════════════════════════════════════
// UniAccents.qml  —  Master color palette (297 entries)
//
// NAMING STANDARD:
//   Every color whose hex value appears verbatim in the official X11
//   rgb.txt (sourced from /etc/X11/rgb.txt) uses the canonical X11
//   name, title-cased with spaces.  Colors whose hex does NOT appear
//   in X11 use plain descriptive names marked [custom].
//
//   The CSS4 / W3C named-color list is a subset of X11 for most
//   colors but differs on a few values (noted inline).
//
// KEY CORRECTIONS vs your previous list:
//   "Brown Red"       #A52A2A → "Brown"              (X11 exact)
//   "Cadet Blue"      #0EB887 → "Cadet Teal" [custom] (X11 Cadet Blue = #5F9EA0)
//   "Maroon"          #800000 → "Web Maroon" [custom] (X11 Maroon = #B03060)
//   "Light Goldenrod" #FAFAD2 → "Light Goldenrod Yellow" (X11 exact)
//   "Azure"           #007ACC → "Azure Blue" [custom] (X11 Azure = #F0FFFF)
//   "Sea Shell"               → "Seashell"            (X11 one word)
//   Added: true X11 Maroon (#B03060), Cadet Blue (#5F9EA0),
//          Light Goldenrod (#EEDD82), Gray (#BEBEBE), Dark Sea Green,
//          Burlywood, Light Goldenrod, Light Slate Blue, DebianRed
// ════════════════════════════════════════════════════════════════════

QtObject {
    property var colors: [

        // ── Pinks (X11 group) ─────────────────────────────────────
        { num:   1, name: "Pink",                   hex: "#FFC0CB" },  // X11
        { num:   2, name: "Light Pink",             hex: "#FFB6C1" },  // X11
        { num:   3, name: "Hot Pink",               hex: "#FF69B4" },  // X11
        { num:   4, name: "Deep Pink",              hex: "#FF1493" },  // X11
        { num:   5, name: "Pale Violet Red",        hex: "#DB7093" },  // X11
        { num:   6, name: "Medium Violet Red",      hex: "#C71585" },  // X11
        { num:   7, name: "Violet Red",             hex: "#D02090" },  // X11

        // ── Reds (X11 group) ──────────────────────────────────────
        { num:   8, name: "Light Salmon",           hex: "#FFA07A" },  // X11
        { num:   9, name: "Salmon",                 hex: "#FA8072" },  // X11
        { num:  10, name: "Dark Salmon",            hex: "#E9967A" },  // X11
        { num:  11, name: "Light Coral",            hex: "#F08080" },  // X11
        { num:  12, name: "Indian Red",             hex: "#CD5C5C" },  // X11
        { num:  13, name: "Crimson",                hex: "#DC143C" },  // X11
        { num:  14, name: "Firebrick",              hex: "#B22222" },  // X11
        { num:  15, name: "Dark Red",               hex: "#8B0000" },  // X11
        { num:  16, name: "Red",                    hex: "#FF0000" },  // X11
        // Extra dark reds not in X11:
        { num:  17, name: "Vivid Red",              hex: "#E51400" },  // [custom]
        { num:  18, name: "Deep Red",               hex: "#990000" },  // [custom]
        { num:  19, name: "Web Maroon",             hex: "#800000" },  // [custom] — CSS "maroon"; X11 Maroon=#B03060
        { num:  20, name: "Deep Maroon",            hex: "#7B0000" },  // [custom]
        { num:  21, name: "Very Dark Red",          hex: "#290505" },  // [custom]
        { num:  22, name: "Near Black Red",         hex: "#1B0202" },  // [custom]

        // ── Oranges (X11 group) ───────────────────────────────────
        { num:  23, name: "Orange Red",             hex: "#FF4500" },  // X11
        { num:  24, name: "Tomato",                 hex: "#FF6347" },  // X11
        { num:  25, name: "Coral",                  hex: "#FF7F50" },  // X11
        { num:  26, name: "Dark Orange",            hex: "#FF8C00" },  // X11
        { num:  27, name: "Orange",                 hex: "#FFA500" },  // X11
        // Custom orange shades:
        { num:  28, name: "Vivid Coral",            hex: "#FF5733" },  // [custom]
        { num:  29, name: "Vivid Orange",           hex: "#FF8000" },  // [custom]  (≈ DarkOrange1 #FF7F00)
        { num:  30, name: "Burnt Orange",           hex: "#CC5500" },  // [custom]
        { num:  31, name: "Tangerine",              hex: "#FA6800" },  // [custom]
        { num:  32, name: "Amber",                  hex: "#FFAA00" },  // [custom]
        { num:  32, name: "Orange UK",              hex: "#FF6501" },  // [custom]

        // ── Yellows (X11 group) ───────────────────────────────────
        { num:  33, name: "Yellow",                 hex: "#FFFF00" },  // X11
        { num:  34, name: "Light Yellow",           hex: "#FFFFE0" },  // X11
        { num:  35, name: "Lemon Chiffon",          hex: "#FFFACD" },  // X11
        { num:  36, name: "Light Goldenrod Yellow", hex: "#FAFAD2" },  // X11  ← was "Light Goldenrod" in your list
        { num:  37, name: "Papaya Whip",            hex: "#FFEFD5" },  // X11
        { num:  38, name: "Moccasin",               hex: "#FFE4B5" },  // X11
        { num:  39, name: "Peach Puff",             hex: "#FFDAB9" },  // X11
        { num:  40, name: "Pale Goldenrod",         hex: "#EEE8AA" },  // X11
        { num:  41, name: "Khaki",                  hex: "#F0E68C" },  // X11
        { num:  42, name: "Dark Khaki",             hex: "#BDB76B" },  // X11
        { num:  43, name: "Gold",                   hex: "#FFD700" },  // X11
        // Custom yellows:
        { num:  44, name: "Nokia Yellow",           hex: "#CDBC16" },  // [custom]
        { num:  44, name: "Khaki Gold",             hex: "#C8A850" },  // [custom]
        { num:  45, name: "Dark Amber",             hex: "#F0A70A" },  // [custom]

        // ── Browns (X11 group) ────────────────────────────────────
        { num:  46, name: "Cornsilk",               hex: "#FFF8DC" },  // X11
        { num:  47, name: "Blanched Almond",        hex: "#FFEBCD" },  // X11
        { num:  48, name: "Bisque",                 hex: "#FFE4C4" },  // X11
        { num:  49, name: "Navajo White",           hex: "#FFDEAD" },  // X11
        { num:  50, name: "Wheat",                  hex: "#F5DEB3" },  // X11
        { num:  51, name: "Burlywood",              hex: "#DEB887" },  // X11  ← added, was missing
        { num:  52, name: "Tan",                    hex: "#D2B48C" },  // X11
        { num:  53, name: "Rosy Brown",             hex: "#BC8F8F" },  // X11
        { num:  54, name: "Sandy Brown",            hex: "#F4A460" },  // X11
        { num:  55, name: "Goldenrod",              hex: "#DAA520" },  // X11
        { num:  56, name: "Dark Goldenrod",         hex: "#B8860B" },  // X11
        { num:  57, name: "Light Goldenrod",        hex: "#EEDD82" },  // X11  ← added; different from LightGoldenrodYellow
        { num:  58, name: "Peru",                   hex: "#CD853F" },  // X11
        { num:  59, name: "Chocolate",              hex: "#D2691E" },  // X11
        { num:  60, name: "Saddle Brown",           hex: "#8B4513" },  // X11
        { num:  61, name: "Sienna",                 hex: "#A0522D" },  // X11
        { num:  62, name: "Brown",                  hex: "#A52A2A" },  // X11  ← was "Brown Red" in your list
        { num:  63, name: "Maroon",                 hex: "#B03060" },  // X11  ← true X11 Maroon (≠ #800000)
        // Custom browns:
        { num:  64, name: "Warm Brown",             hex: "#88511C" },  // [custom]
        { num:  64, name: "Warm Dark Brown",        hex: "#8B5E1A" },  // [custom]
        { num:  64, name: "Horse Brown",            hex: "#331B09" },  // [custom]
        { num:  64, name: "Espresso",               hex: "#1C0E07" },  // [custom]
        { num:  64, name: "Dark Tan",               hex: "#B08050" },  // [custom]
        { num:  64, name: "Medium Brown",           hex: "#A05000" },  // [custom] (your old "Saddle Brown" — real X11 Saddle Brown is #8B4513)
        { num:  65, name: "Dark Brown",             hex: "#3B1F0A" },  // [custom]
        { num:  66, name: "Dark Sienna",            hex: "#3A1800" },  // [custom]
        { num:  67, name: "Dark Umber",             hex: "#2A1A0A" },  // [custom]
        { num:  68, name: "Near Black Brown",       hex: "#170C01" },  // [custom]
        { num:  69, name: "Taupe",                  hex: "#87794E" },  // [custom]
        { num:  70, name: "Dark Sand",              hex: "#504030" },  // [custom]
        { num:  71, name: "Mango Orange",           hex: "#F09609" },  // [custom]

        // ── Whites / Off-whites (X11 group) ───────────────────────
        { num:  72, name: "Snow",                   hex: "#FFFAFA" },  // X11
        { num:  73, name: "Seashell",               hex: "#FFF5EE" },  // X11  ← was "Sea Shell" in your list
        { num:  74, name: "Old Lace",               hex: "#FDF5E6" },  // X11
        { num:  75, name: "Linen",                  hex: "#FAF0E6" },  // X11
        { num:  76, name: "Antique White",          hex: "#FAEBD7" },  // X11
        { num:  80, name: "Misty Rose",             hex: "#FFE4E1" },  // X11
        { num:  81, name: "Lavender Blush",         hex: "#FFF0F5" },  // X11
        { num:  82, name: "Floral White",           hex: "#FFFAF0" },  // X11
        { num:  83, name: "Ivory",                  hex: "#FFFFF0" },  // X11
        { num:  84, name: "Beige",                  hex: "#F5F5DC" },  // X11
        { num:  85, name: "Mint Cream",             hex: "#F5FFFA" },  // X11
        { num:  86, name: "Honeydew",               hex: "#F0FFF0" },  // X11
        { num:  87, name: "White Smoke",            hex: "#F5F5F5" },  // X11
        { num:  88, name: "Ghost White",            hex: "#F8F8FF" },  // X11
        { num:  89, name: "White",                  hex: "#FFFFFF" },  // X11
        { num:  90, name: "Off White",              hex: "#EEEEEE" },  // [custom]
        { num:  91, name: "Gainsboro",              hex: "#DCDCDC" },  // X11

        // ── Greens (X11 group) ────────────────────────────────────
        { num:  92, name: "Dark Olive Green",       hex: "#556B2F" },  // X11
        { num:  93, name: "Olive Drab",             hex: "#6B8E23" },  // X11
        { num:  94, name: "Yellow Green",           hex: "#9ACD32" },  // X11
        { num:  95, name: "Lime Green",             hex: "#32CD32" },  // X11
        { num:  96, name: "Green Yellow",           hex: "#ADFF2F" },  // X11
        { num:  97, name: "Chartreuse",             hex: "#7FFF00" },  // X11
        { num:  98, name: "Lawn Green",             hex: "#7CFC00" },  // X11
        { num:  99, name: "Green",                  hex: "#00FF00" },  // X11  (CSS "Lime"; X11 "Green" = #00FF00)
        { num: 100, name: "Forest Green",           hex: "#228B22" },  // X11
        { num: 101, name: "Sea Green",              hex: "#2E8B57" },  // X11
        { num: 102, name: "Light Sea Green",        hex: "#20B2AA" },  // X11
        { num: 103, name: "Medium Sea Green",       hex: "#3CB371" },  // X11
        { num: 104, name: "Medium Spring Green",    hex: "#00FA9A" },  // X11
        { num: 105, name: "Spring Green",           hex: "#00FF7F" },  // X11
        { num: 106, name: "Medium Aquamarine",      hex: "#66CDAA" },  // X11
        { num: 107, name: "Dark Sea Green",         hex: "#8FBC8F" },  // X11  ← added, was missing
        { num: 108, name: "Light Green",            hex: "#90EE90" },  // X11
        { num: 109, name: "Pale Green",             hex: "#98FB98" },  // X11
        { num: 110, name: "Dark Green",             hex: "#006400" },  // X11
        { num: 111, name: "Web Green",              hex: "#008000" },  // [custom] — CSS "green"; X11 green=#00FF00
        // Custom greens:
        { num: 112, name: "Emerald",                hex: "#009E49" },  // [custom]
        { num: 113, name: "Hunter Green",           hex: "#355E3B" },  // [custom]
        { num: 114, name: "Pistachio",              hex: "#93C572" },  // [custom]
        { num: 115, name: "Avocado",                hex: "#568203" },  // [custom]
        { num: 116, name: "Leaf Green",             hex: "#69B40F" },  // [custom]
        { num: 117, name: "Limey Green",            hex: "#7FBA00" },  // [custom]
        { num: 118, name: "Yellow Lime",            hex: "#A2C139" },  // [custom]
        { num: 119, name: "Spring Lime",            hex: "#00E060" },  // [custom]
        { num: 120, name: "Dark Chartreuse",       hex: "#A3B500" },  // [custom]
        { num: 120, name: "Pale Yellow Green",      hex: "#CBFE33" },  // [custom] (your "Pantone Lime" — Pantone names are trademarked)
        { num: 120, name: "Bright Lime Green",      hex: "#5D9809" },  // [custom] (your old "Lime Green" — X11 Lime Green is #32CD32)
        { num: 120, name: "Hunter Green",           hex: "#2A8A2A" },  // [custom]
        { num: 120, name: "Vivid Green",            hex: "#339933" },  // [custom]
        { num: 120, name: "Olive",                  hex: "#808000" },  // CSS4 (not in X11)
        { num: 121, name: "Military Green",         hex: "#6F8663" },  // [custom]
        { num: 122, name: "Dark Olive",             hex: "#3B3B00" },  // [custom]
        { num: 123, name: "Dark Moss",              hex: "#2A3A1A" },  // [custom]
        { num: 124, name: "Deep Forest Green",      hex: "#1A3A1A" },  // [custom]
        { num: 125, name: "Dark Jungle Green",      hex: "#0A2A0A" },  // [custom]
        { num: 126, name: "Marine Green",           hex: "#052C05" },  // [custom]
        { num: 127, name: "Seaweed Green",          hex: "#1F2804" },  // [custom]
        { num: 128, name: "Near Black Green",       hex: "#0F1301" },  // [custom]
        { num: 129, name: "Mint Foam",              hex: "#D5F9EA" },  // [custom]

        // ── Cyans / Teals (X11 group) ─────────────────────────────
        { num: 130, name: "Aquamarine",             hex: "#7FFFD4" },  // X11
        { num: 131, name: "Turquoise",              hex: "#40E0D0" },  // X11
        { num: 132, name: "Medium Turquoise",       hex: "#48D1CC" },  // X11
        { num: 133, name: "Dark Turquoise",         hex: "#00CED1" },  // X11
        { num: 134, name: "Cadet Blue",             hex: "#5F9EA0" },  // X11  ← true X11 Cadet Blue
        { num: 135, name: "Pale Turquoise",         hex: "#AFEEEE" },  // X11
        { num: 136, name: "Powder Blue",            hex: "#B0E0E6" },  // X11
        { num: 137, name: "Light Blue",             hex: "#ADD8E6" },  // X11
        { num: 138, name: "Light Cyan",             hex: "#E0FFFF" },  // X11
        { num: 139, name: "Cyan",                   hex: "#00FFFF" },  // X11
        { num: 140, name: "Dark Cyan",              hex: "#008B8B" },  // X11
        { num: 141, name: "Teal",                   hex: "#008080" },  // CSS4 (not in original X11 rgb.txt)
        { num: 142, name: "Dark Slate Gray",        hex: "#2F4F4F" },  // X11
        { num: 143, name: "Azure",                  hex: "#F0FFFF" },  // X11  ← true X11 Azure (very pale blue-white)
        // Custom teals:
        { num: 144, name: "Cadet Teal",             hex: "#0EB887" },  // [custom] — was "Cadet Blue" in your list (wrong)
        { num: 145, name: "Pearl Turquoise",        hex: "#32C6A6" },  // [custom]
        { num: 146, name: "Vivid Teal",             hex: "#00BFA5" },  // [custom]
        { num: 147, name: "Cyan Teal",              hex: "#00ABA9" },  // [custom]
        { num: 148, name: "Light Turquoise",        hex: "#00ABAB" },  // [custom]
        { num: 149, name: "Medium Cyan",            hex: "#00CCCC" },  // [custom]
        { num: 150, name: "Dark Teal",              hex: "#003333" },  // [custom]
        { num: 151, name: "Deep Teal",              hex: "#042929" },  // [custom]
        { num: 152, name: "Deep Teal",              hex: "#004444" },  // [custom]
        { num: 152, name: "Dark Cyan Green",        hex: "#006666" },  // [custom]
        { num: 152, name: "Near Black Teal",        hex: "#011212" },  // [custom]

        // ── Blues (X11 group) ─────────────────────────────────────
        { num: 153, name: "Light Sky Blue",         hex: "#87CEFA" },  // X11
        { num: 154, name: "Sky Blue",               hex: "#87CEEB" },  // X11
        { num: 155, name: "Cornflower Blue",        hex: "#6495ED" },  // X11
        { num: 156, name: "Deep Sky Blue",          hex: "#00BFFF" },  // X11
        { num: 157, name: "Dodger Blue",            hex: "#1E90FF" },  // X11
        { num: 158, name: "Royal Blue",             hex: "#4169E1" },  // X11
        { num: 159, name: "Medium Blue",            hex: "#0000CD" },  // X11
        { num: 160, name: "Blue",                   hex: "#0000FF" },  // X11
        { num: 161, name: "Dark Blue",              hex: "#00008B" },  // X11
        { num: 162, name: "Navy",                   hex: "#000080" },  // X11
        { num: 163, name: "Midnight Blue",          hex: "#191970" },  // X11
        { num: 164, name: "Steel Blue",             hex: "#4682B4" },  // X11
        { num: 165, name: "Light Steel Blue",       hex: "#B0C4DE" },  // X11
        { num: 166, name: "Slate Gray",             hex: "#708090" },  // X11
        { num: 167, name: "Light Slate Gray",       hex: "#778899" },  // X11
        { num: 168, name: "Alice Blue",             hex: "#F0F8FF" },  // X11
        { num: 169, name: "Lavender",               hex: "#E6E6FA" },  // X11
        // Custom blues:
        { num: 170, name: "Azure Blue",             hex: "#007ACC" },  // [custom] — not X11; was confused with X11 Azure
        { num: 171, name: "Cerulean",               hex: "#0099CC" },  // [custom]
        { num: 172, name: "Sky Periwinkle",         hex: "#66CCFF" },  // [custom]
        { num: 173, name: "Vivid Blue",             hex: "#1BA1E2" },  // [custom]
        { num: 174, name: "Southern Blue",          hex: "#0084C9" },  // [custom]
        { num: 175, name: "Matte Blue",             hex: "#3D80A0" },  // [custom]
        { num: 176, name: "Light Matte Blue",       hex: "#73B6D6" },  // [custom]
        { num: 177, name: "Steel Gray Blue",       hex: "#647487" },  // [custom]
        { num: 177, name: "Cornflower Azure",       hex: "#3385FF" },  // [custom]
        { num: 177, name: "Gunmetal",               hex: "#2C3539" },  // [custom]
        { num: 178, name: "Denim Blue",             hex: "#1B4F8A" },  // [custom]
        { num: 179, name: "Cobalt Blue",            hex: "#0047AB" },  // [custom]
        { num: 180, name: "Nokia Blue",             hex: "#004C9A" },  // [custom]
        { num: 181, name: "Deep Royal Blue",        hex: "#1040C0" },  // [custom]
        { num: 182, name: "Cobalt Electric",        hex: "#0050EF" },  // [custom]
        { num: 183, name: "Facebook Blue",          hex: "#3B5998" },  // [custom]
        { num: 184, name: "Steel Navy",             hex: "#1C3A5A" },  // [custom]
        { num: 185, name: "Arctic Blue",            hex: "#03417B" },  // [custom]
        { num: 186, name: "Deep Sea Blue",          hex: "#062343" },  // [custom]
        { num: 187, name: "Twilight Blue",          hex: "#1E2A3A" },  // [custom]
        { num: 188, name: "Marine Blue",            hex: "#05182B" },  // [custom]
        { num: 189, name: "Near Black Blue",        hex: "#010B15" },  // [custom]

        // ── Indigo / Violet (X11 group) ───────────────────────────
        { num: 190, name: "Medium Slate Blue",      hex: "#7B68EE" },  // X11
        { num: 191, name: "Slate Blue",             hex: "#6A5ACD" },  // X11
        { num: 192, name: "Dark Slate Blue",        hex: "#483D8B" },  // X11
        { num: 193, name: "Light Slate Blue",       hex: "#8470FF" },  // X11  ← added, was missing
        { num: 194, name: "Medium Purple",          hex: "#9370DB" },  // X11
        { num: 195, name: "Blue Violet",            hex: "#8A2BE2" },  // X11
        { num: 196, name: "Dark Violet",            hex: "#9400D3" },  // X11
        { num: 197, name: "Dark Orchid",            hex: "#9932CC" },  // X11
        { num: 198, name: "Medium Orchid",          hex: "#BA55D3" },  // X11
        { num: 199, name: "Purple",                 hex: "#A020F0" },  // X11  ← true X11 Purple (NOT #800080)
        { num: 200, name: "Thistle",                hex: "#D8BFD8" },  // X11
        { num: 201, name: "Plum",                   hex: "#DDA0DD" },  // X11
        { num: 202, name: "Violet",                 hex: "#EE82EE" },  // X11
        { num: 203, name: "Orchid",                 hex: "#DA70D6" },  // X11
        { num: 204, name: "Magenta",                hex: "#FF00FF" },  // X11  (CSS name: Fuchsia)
        { num: 205, name: "Dark Magenta",           hex: "#8B008B" },  // X11
        { num: 206, name: "Web Purple",             hex: "#800080" },  // [custom] — CSS "Purple"; X11 Purple=#A020F0
        { num: 207, name: "Indigo",                 hex: "#4B0082" },  // CSS4 (not in original X11)
        // Custom indigos/purples:
        { num: 208, name: "Ultramarine",            hex: "#3F00FF" },  // [custom]
        { num: 209, name: "Electric Indigo",        hex: "#6A00FF" },  // [custom]
        { num: 210, name: "Electric Violet",        hex: "#9600EC" },  // [custom]
        { num: 211, name: "Vivid Purple",           hex: "#A200FF" },  // [custom]
        { num: 212, name: "Lavender Purple",        hex: "#B57FDC" },  // [custom]
        { num: 213, name: "Periwinkle",             hex: "#7B96DC" },  // [custom]
        { num: 214, name: "Midnight",               hex: "#3A3ABF" },  // [custom]
        { num: 215, name: "Mauve",                  hex: "#8A608A" },  // [custom]
        { num: 216, name: "Deep Indigo",            hex: "#1A0033" },  // [custom]
        { num: 217, name: "Deep Dark Violet",       hex: "#200040" },  // [custom]
        { num: 218, name: "Dusk Purple",            hex: "#3A2A4A" },  // [custom]
        { num: 219, name: "Dark Plum",              hex: "#300030" },  // [custom]
        { num: 220, name: "Deep Purple",            hex: "#1C0429" },  // [custom]
        { num: 221, name: "Near Black Purple",      hex: "#0B0111" },  // [custom]

        // ── Magentas / Hot Pinks (custom brand/extra) ─────────────
        { num: 222, name: "T-Mobile Magenta",       hex: "#E30083" },  // [custom]
        { num: 223, name: "Deep Magenta",           hex: "#EC008C" },  // [custom]
        { num: 224, name: "Hot Pink Alt",           hex: "#D80073" },  // [custom]
        { num: 225, name: "Rose",                   hex: "#E91E8C" },  // [custom]
        { num: 226, name: "Petal Pink",             hex: "#E671B8" },  // [custom]
        { num: 227, name: "Pretty Pink",            hex: "#F472D0" },  // [custom]
        { num: 228, name: "Eggplant Magenta",       hex: "#18020E" },  // [custom]
        { num: 229, name: "Near Black Magenta",     hex: "#2B0417" },  // [custom]
        { num: 230, name: "Dark Mauve",             hex: "#3A1A2A" },  // [custom]

        // ── Dark Crimsons / Brand Reds ─────────────────────────────
        { num: 231, name: "Debian Red",             hex: "#D70751" },  // X11 (DebianRed)
        { num: 232, name: "Vermilion",              hex: "#FF1852" },  // [custom]
        { num: 233, name: "Dead Red",               hex: "#E81123" },  // [custom]
        { num: 234, name: "Vodafone Red",           hex: "#EF001F" },  // [custom]
        { num: 235, name: "Virgin Mobile Red",      hex: "#CC0001" },  // [custom]
        { num: 236, name: "Nokia Red",              hex: "#9A002C" },  // [custom]
        { num: 237, name: "Crimson Dark",           hex: "#800020" },  // [custom]
        { num: 238, name: "Dark Crimson",           hex: "#5C0020" },  // [custom]
        { num: 239, name: "Dark Rose Red",          hex: "#4A0010" },  // [custom]

        // ── Deep Blues / Navies (custom) ──────────────────────────
        { num: 240, name: "Atlantic Blue",          hex: "#01145E" },  // [custom]
        { num: 241, name: "Deep Navy",              hex: "#001F5B" },  // [custom]
        { num: 242, name: "Pacific Blue",           hex: "#010942" },  // [custom]
        { num: 243, name: "Very Dark Navy",         hex: "#0A1540" },  // [custom]
        { num: 244, name: "Abyss",                  hex: "#050520" },  // [custom]
        { num: 245, name: "Near Black Navy",        hex: "#0D0D1E" },  // [custom]

        // ── Grays (X11 group) ─────────────────────────────────────
        // Note: X11 Gray = #BEBEBE; CSS Gray = #808080 (different!)
        { num: 246, name: "Black",                  hex: "#000000" },  // X11
        { num: 247, name: "Dim Gray",               hex: "#696969" },  // X11
        { num: 248, name: "Gray",                   hex: "#BEBEBE" },  // X11  ← true X11 Gray (NOT #808080)
        { num: 249, name: "Web Gray",               hex: "#808080" },  // [custom] — CSS "gray"; X11 Gray=#BEBEBE
        { num: 250, name: "Dark Gray",              hex: "#A9A9A9" },  // X11/CSS4
        { num: 251, name: "Light Gray",             hex: "#D3D3D3" },  // X11
        { num: 255, name: "Silver",                 hex: "#C0C0C0" },  // CSS4
        // Custom grays:
        { num: 257, name: "Near Black",             hex: "#090909" },  // [custom]
        { num: 258, name: "Jet Black",              hex: "#0A0A0A" },  // [custom]
        { num: 259, name: "Onyx",                   hex: "#1A1A1A" },  // [custom]
        { num: 260, name: "Very Dark Gray",         hex: "#2B2A2A" },  // [custom]
        { num: 261, name: "Graphite",               hex: "#383838" },  // [custom]
        { num: 262, name: "Dark Grey",              hex: "#404040" },  // [custom]
        { num: 263, name: "Dark",                   hex: "#555555" },  // [custom]
        { num: 264, name: "Charcoal",               hex: "#606060" }   // [custom]
    ]
}
