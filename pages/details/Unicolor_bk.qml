import QtQuick 2.8
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.12
import "../../components"

// ════════════════════════════════════════════════════════════════════
// Unicolor.qml  —  Color-picker panel for Settings > Interface
// ════════════════════════════════════════════════════════════════════

Item {
    id: unicolor

    // ── Bound properties (set by parent SettingsPage) ────────────
    property int    accentFillIdx:         0
    property int    themeFillIdx:          0
    property int    accentTransparency:    0
    property int    interfaceTransparency: 80
    property bool   gradAccentColor:       true
    property bool   gradAccentOpacity:     true
    property bool   gradThemeColor:        true
    property bool   gradThemeTransp:       true
    property color  currentAccentColor:    "#5d9809"
    property string currentThemeFillHex:   "#555555"
    property string accentHex:             "#5d9809"
    property var    saveFunc:              null

    function doSave(k, v) { if (saveFunc) saveFunc(k, v) }

    // ── Panel state ───────────────────────────────────────────────
    property bool accentExpanded: false
    property bool themeExpanded:  false
    property bool horizontalView: true

    // ── Fixed height for the scrollable list panel ───────────────
    readonly property int listPanelHeight: vpx(400)
    readonly property int rowH:            vpx(38)

    // ── Shared palette (263 colours) ──────────────────────────────
    property var accentColors: [
        { name: "Burnt Red",            num:   1, hex: "#1B0202" },
        { name: "Burgundy Red",         num:   2, hex: "#290505" },
        { name: "Deep Maroon",          num:   3, hex: "#7B0000" },
        { name: "Maroon",               num:   4, hex: "#800000" },
        { name: "Dark Red",             num:   5, hex: "#8B0000" },
        { name: "Deep Red",             num:   6, hex: "#990000" },
        { name: "Brown Red",            num:   7, hex: "#A52A2A" },
        { name: "Firebrick",            num:   8, hex: "#B22222" },
        { name: "Vivid Red",            num:   9, hex: "#E51400" },
        { name: "Red",                  num:  10, hex: "#FF0000" },
        { name: "Indian Red",           num:  11, hex: "#CD5C5C" },
        { name: "Rosy Brown",           num:  12, hex: "#BC8F8F" },
        { name: "Salmon",               num:  13, hex: "#FA8072" },
        { name: "Light Coral",          num:  14, hex: "#F08080" },
        { name: "Misty Rose",           num:  15, hex: "#FFE4E1" },
        { name: "Snow",                 num:  16, hex: "#FFFAFA" },
        { name: "Espresso",             num:  17, hex: "#1C0E07" },
        { name: "Sienna",               num:  18, hex: "#A0522D" },
        { name: "Orange Red",           num:  19, hex: "#FF4500" },
        { name: "Vivid Coral",          num:  20, hex: "#FF5733" },
        { name: "Tomato",               num:  21, hex: "#FF6347" },
        { name: "Coral",                num:  22, hex: "#FF7F50" },
        { name: "Dark Salmon",          num:  23, hex: "#E9967A" },
        { name: "Light Salmon",         num:  24, hex: "#FFA07A" },
        { name: "Dark Horse Brown",     num:  25, hex: "#170C01" },
        { name: "Dark Umber",           num:  26, hex: "#2A1A0A" },
        { name: "Dark Sienna",          num:  27, hex: "#3A1800" },
        { name: "Horse Brown",          num:  28, hex: "#331B09" },
        { name: "Dark Brown",           num:  29, hex: "#3B1F0A" },
        { name: "Dark Sand",            num:  30, hex: "#504030" },
        { name: "Saddle Dark Brown",    num:  31, hex: "#8B4513" },
        { name: "Saddle Brown",         num:  32, hex: "#A05000" },
        { name: "Boy Brown",            num:  33, hex: "#88511C" },
        { name: "Warm Dark Brown",      num:  34, hex: "#8B5E1A" },
        { name: "Burnt Orange",         num:  35, hex: "#CC5500" },
        { name: "Chocolate",            num:  36, hex: "#D2691E" },
        { name: "Mango",                num:  37, hex: "#F09609" },
        { name: "Tangerine",            num:  38, hex: "#FA6800" },
        { name: "Dark Orange Alt",      num:  39, hex: "#FF8000" },
        { name: "Dark Orange",          num:  40, hex: "#FF8C00" },
        { name: "Orange UK",            num:  41, hex: "#FF6501" },
        { name: "Dark Tan",             num:  42, hex: "#B08050" },
        { name: "Peru",                 num:  43, hex: "#CD853F" },
        { name: "Sandy Brown",          num:  44, hex: "#F4A460" },
        { name: "Tan",                  num:  45, hex: "#D2B48C" },
        { name: "Navajo White",         num:  46, hex: "#FFDEAD" },
        { name: "Peach Puff",           num:  47, hex: "#FFDAB9" },
        { name: "Bisque",               num:  48, hex: "#FFE4C4" },
        { name: "Blanched Almond",      num:  49, hex: "#FFEBCD" },
        { name: "Antique White",        num:  50, hex: "#FAEBD7" },
        { name: "Papaya Whip",          num:  51, hex: "#FFEFD5" },
        { name: "Linen",                num:  52, hex: "#FAF0E6" },
        { name: "Sea Shell",            num:  53, hex: "#FFF5EE" },
        { name: "Dark Goldenrod",       num:  54, hex: "#B8860B" },
        { name: "Taupe",                num:  55, hex: "#87794E" },
        { name: "Amber",                num:  56, hex: "#F0A70A" },
        { name: "Goldenrod",            num:  57, hex: "#DAA520" },
        { name: "Orange",               num:  58, hex: "#FFA500" },
        { name: "Deep Amber",           num:  59, hex: "#FFAA00" },
        { name: "Gold",                 num:  60, hex: "#FFD700" },
        { name: "Khaki Gold",           num:  61, hex: "#C8A850" },
        { name: "Wheat",                num:  62, hex: "#F5DEB3" },
        { name: "Moccasin",             num:  63, hex: "#FFE4B5" },
        { name: "Cornsilk",             num:  64, hex: "#FFF8DC" },
        { name: "Old Lace",             num:  65, hex: "#FDF5E6" },
        { name: "Floral White",         num:  66, hex: "#FFFAF0" },
        { name: "Dark Olive",           num:  67, hex: "#3B3B00" },
        { name: "Olive",                num:  68, hex: "#808000" },
        { name: "Dark Chartreuse",      num:  69, hex: "#A3B500" },
        { name: "Nokia Yellow",         num:  70, hex: "#CDBC16" },
        { name: "Yellow",               num:  71, hex: "#FFFF00" },
        { name: "Dark Khaki",           num:  72, hex: "#BDB76B" },
        { name: "Khaki",                num:  73, hex: "#F0E68C" },
        { name: "Pale Goldenrod",       num:  74, hex: "#EEE8AA" },
        { name: "Light Goldenrod",      num:  75, hex: "#FAFAD2" },
        { name: "Lemon Chiffon",        num:  76, hex: "#FFFACD" },
        { name: "Beige",                num:  77, hex: "#F5F5DC" },
        { name: "Light Yellow",         num:  78, hex: "#FFFFE0" },
        { name: "Ivory",                num:  79, hex: "#FFFFF0" },
        { name: "Seaweed Green",        num:  80, hex: "#0F1301" },
        { name: "Weed Green",           num:  81, hex: "#1F2804" },
        { name: "Avocado",              num:  82, hex: "#568203" },
        { name: "Dark Olive Green",     num:  83, hex: "#556B2F" },
        { name: "Olive Drab",           num:  84, hex: "#6B8E23" },
        { name: "Limey Green",          num:  85, hex: "#7FBA00" },
        { name: "Yellow Lime",          num:  86, hex: "#A2C139" },
        { name: "Yellow Green",         num:  87, hex: "#9ACD32" },
        { name: "Pantone Lime",         num:  88, hex: "#CBFE33" },
        { name: "Dark Moss",            num:  89, hex: "#2A3A1A" },
        { name: "Lime Green",           num:  90, hex: "#5D9809" },
        { name: "Leaf Green",           num:  91, hex: "#69B40F" },
        { name: "Lawn Green",           num:  92, hex: "#7CFC00" },
        { name: "Chartreuse",           num:  93, hex: "#7FFF00" },
        { name: "Green Yellow",         num:  94, hex: "#ADFF2F" },
        { name: "Pistachio",            num:  95, hex: "#93C572" },
        { name: "Military Green",       num:  96, hex: "#6F8663" },
        { name: "Marine Green",         num:  97, hex: "#052C05" },
        { name: "Dark Jungle",          num:  98, hex: "#0A2A0A" },
        { name: "Deep Forest",          num:  99, hex: "#1A3A1A" },
        { name: "Dark Green",           num: 100, hex: "#006400" },
        { name: "Green",                num: 101, hex: "#008000" },
        { name: "Forest Green",         num: 102, hex: "#228B22" },
        { name: "Hunter Green",         num: 103, hex: "#2A8A2A" },
        { name: "Vivid Green",          num: 104, hex: "#339933" },
        { name: "Lime",                 num: 105, hex: "#00FF00" },
        { name: "Lime Bright",          num: 106, hex: "#32CD32" },
        { name: "Light Green",          num: 107, hex: "#90EE90" },
        { name: "Pale Green",           num: 108, hex: "#98FB98" },
        { name: "Honeydew",             num: 109, hex: "#F0FFF0" },
        { name: "Hunter Dark Green",    num: 110, hex: "#355E3B" },
        { name: "Emerald",              num: 111, hex: "#009E49" },
        { name: "Sea Green",            num: 112, hex: "#2E8B57" },
        { name: "Spring Lime",          num: 113, hex: "#00E060" },
        { name: "Medium Sea Green",     num: 114, hex: "#3CB371" },
        { name: "Medium Spring Green",  num: 115, hex: "#00FA9A" },
        { name: "Spring Green",         num: 116, hex: "#00FF7F" },
        { name: "Mint Foam",            num: 117, hex: "#D5F9EA" },
        { name: "Mint Cream",           num: 118, hex: "#F5FFFA" },
        { name: "Vivid Teal",           num: 119, hex: "#00BFA5" },
        { name: "Cadet Blue",           num: 120, hex: "#0EB887" },
        { name: "Pearl Turquoise",      num: 121, hex: "#32C6A6" },
        { name: "Medium Aquamarine",    num: 122, hex: "#66CDAA" },
        { name: "Aquamarine",           num: 123, hex: "#7FFFD4" },
        { name: "Nessie Teal",          num: 124, hex: "#011212" },
        { name: "Arial Teal",           num: 125, hex: "#042929" },
        { name: "Dark Teal",            num: 126, hex: "#003333" },
        { name: "Deep Teal",            num: 127, hex: "#004444" },
        { name: "Deep Dark Cyan",       num: 128, hex: "#006666" },
        { name: "Dark Slate Gray",      num: 129, hex: "#2F4F4F" },
        { name: "Teal",                 num: 130, hex: "#008080" },
        { name: "Dark Cyan",            num: 131, hex: "#008B8B" },
        { name: "Cyan Teal",            num: 132, hex: "#00ABA9" },
        { name: "Light Turquoise",      num: 133, hex: "#00ABAB" },
        { name: "Medium Cyan",          num: 134, hex: "#00CCCC" },
        { name: "Dark Turquoise",       num: 135, hex: "#00CED1" },
        { name: "Light Sea Green",      num: 136, hex: "#20B2AA" },
        { name: "Aqua",                 num: 137, hex: "#00FFFF" },
        { name: "Medium Turquoise",     num: 138, hex: "#48D1CC" },
        { name: "Turquoise",            num: 139, hex: "#40E0D0" },
        { name: "Powder Blue",          num: 140, hex: "#B0E0E6" },
        { name: "Pale Turquoise",       num: 141, hex: "#AFEEEE" },
        { name: "Light Cyan",           num: 142, hex: "#E0FFFF" },
        { name: "Azure Blue",           num: 143, hex: "#F0FFFF" },
        { name: "Gunmetal",             num: 144, hex: "#2C3539" },
        { name: "Southern Blue",        num: 145, hex: "#0084C9" },
        { name: "Cerulean Blue",        num: 146, hex: "#0099CC" },
        { name: "Matte Blue",           num: 147, hex: "#3D80A0" },
        { name: "Vivid Blue",           num: 148, hex: "#1BA1E2" },
        { name: "Deep Sky Blue",        num: 149, hex: "#00BFFF" },
        { name: "Light Matte Blue",     num: 150, hex: "#73B6D6" },
        { name: "Sky Periwinkle",       num: 151, hex: "#66CCFF" },
        { name: "Sky Blue",             num: 152, hex: "#87CEEB" },
        { name: "Light Blue",           num: 153, hex: "#ADD8E6" },
        { name: "Twilight Blue",        num: 154, hex: "#010B15" },
        { name: "Marine Blue",          num: 155, hex: "#05182B" },
        { name: "Deep Sea Blue",        num: 156, hex: "#062343" },
        { name: "Twilight Gray",        num: 157, hex: "#1E2A3A" },
        { name: "Steel Navy",           num: 158, hex: "#1C3A5A" },
        { name: "Arctic Blue",          num: 159, hex: "#03417B" },
        { name: "Nokia Blue",           num: 160, hex: "#004C9A" },
        { name: "Denim Blue",           num: 161, hex: "#1B4F8A" },
        { name: "Cobalt Blue",          num: 162, hex: "#0047AB" },
        { name: "Azure",                num: 163, hex: "#007ACC" },
        { name: "Steel Gray",           num: 164, hex: "#647487" },
        { name: "Steel Blue",           num: 165, hex: "#4682B4" },
        { name: "Slate Gray",           num: 166, hex: "#708090" },
        { name: "Light Slate Gray",     num: 167, hex: "#778899" },
        { name: "Dodger Blue",          num: 168, hex: "#1E90FF" },
        { name: "Cornflower Azure",     num: 169, hex: "#3385FF" },
        { name: "Light Sky Blue",       num: 170, hex: "#87CEFA" },
        { name: "Light Steel Blue",     num: 171, hex: "#B0C4DE" },
        { name: "Alice Blue",           num: 172, hex: "#F0F8FF" },
        { name: "Ink Blue",             num: 173, hex: "#0A1540" },
        { name: "Deep Navy",            num: 174, hex: "#001F5B" },
        { name: "Atlantic Blue",        num: 175, hex: "#01145E" },
        { name: "Deep Royal Blue",      num: 176, hex: "#1040C0" },
        { name: "Facebook Blue",        num: 177, hex: "#3B5998" },
        { name: "Cobalt Electric",      num: 178, hex: "#0050EF" },
        { name: "Royal Blue",           num: 179, hex: "#4169E1" },
        { name: "Cornflower Blue",      num: 180, hex: "#6495ED" },
        { name: "Periwinkle",           num: 181, hex: "#7B96DC" },
        { name: "Abyss",                num: 182, hex: "#050520" },
        { name: "Rich Black",           num: 183, hex: "#0D0D1E" },
        { name: "Pacific Blue",         num: 184, hex: "#010942" },
        { name: "Navy",                 num: 185, hex: "#000080" },
        { name: "Midnight Blue",        num: 186, hex: "#191970" },
        { name: "Dark Blue",            num: 187, hex: "#00008B" },
        { name: "Medium Blue",          num: 188, hex: "#0000CD" },
        { name: "Midnight",             num: 189, hex: "#3A3ABF" },
        { name: "Blue",                 num: 190, hex: "#0000FF" },
        { name: "Lavender",             num: 191, hex: "#E6E6FA" },
        { name: "Ghost White",          num: 192, hex: "#F8F8FF" },
        { name: "Dark Slate Blue",      num: 193, hex: "#483D8B" },
        { name: "Ultramarine",          num: 194, hex: "#3F00FF" },
        { name: "Slate Blue",           num: 195, hex: "#6A5ACD" },
        { name: "Medium Purple",        num: 196, hex: "#9370DB" },
        { name: "Medium Slate Blue",    num: 197, hex: "#7B68EE" },
        { name: "Black Purple",         num: 198, hex: "#0B0111" },
        { name: "Deep Indigo",          num: 199, hex: "#1A0033" },
        { name: "Deep Dark Violet",     num: 200, hex: "#200040" },
        { name: "Dusk Purple",          num: 201, hex: "#3A2A4A" },
        { name: "Indigo",               num: 202, hex: "#4B0082" },
        { name: "Electric Indigo",      num: 203, hex: "#6A00FF" },
        { name: "Blue Violet",          num: 204, hex: "#8A2BE2" },
        { name: "Lavender Purple",      num: 205, hex: "#B57FDC" },
        { name: "Deep Purple",          num: 206, hex: "#1C0429" },
        { name: "Dark Violet",          num: 207, hex: "#9400D3" },
        { name: "Electric Violet",      num: 208, hex: "#9600EC" },
        { name: "Dark Orchid",          num: 209, hex: "#9932CC" },
        { name: "Vivid Purple",         num: 210, hex: "#A200FF" },
        { name: "Medium Orchid",        num: 211, hex: "#BA55D3" },
        { name: "Dark Plum",            num: 212, hex: "#300030" },
        { name: "Purple",               num: 213, hex: "#800080" },
        { name: "Dark Magenta",         num: 214, hex: "#8B008B" },
        { name: "Mauve",                num: 215, hex: "#8A608A" },
        { name: "Fuchsia",              num: 216, hex: "#FF00FF" },
        { name: "Orchid",               num: 217, hex: "#DA70D6" },
        { name: "Violet",               num: 218, hex: "#EE82EE" },
        { name: "Plum",                 num: 219, hex: "#DDA0DD" },
        { name: "Thistle",              num: 220, hex: "#D8BFD8" },
        { name: "Medium Violet Red",    num: 221, hex: "#C71585" },
        { name: "Pretty Pink",          num: 222, hex: "#F472D0" },
        { name: "Eggplant Magenta",     num: 223, hex: "#18020E" },
        { name: "Turnip Magenta",       num: 224, hex: "#2B0417" },
        { name: "Dark Mauve",           num: 225, hex: "#3A1A2A" },
        { name: "Hot Pink Alt",         num: 226, hex: "#D80073" },
        { name: "T-Mobile Pink",        num: 227, hex: "#E30083" },
        { name: "Formal Magenta",       num: 228, hex: "#EC008C" },
        { name: "Rose",                 num: 229, hex: "#E91E8C" },
        { name: "Deep Pink",            num: 230, hex: "#FF1493" },
        { name: "Petal Pink",           num: 231, hex: "#E671B8" },
        { name: "Hot Pink",             num: 232, hex: "#FF69B4" },
        { name: "Dark Maroon",          num: 233, hex: "#4A0010" },
        { name: "Dark Crimson",         num: 234, hex: "#5C0020" },
        { name: "Crimson Dark",         num: 235, hex: "#800020" },
        { name: "Nokia Red",            num: 236, hex: "#9A002C" },
        { name: "Vodafone Red",         num: 237, hex: "#EF001F" },
        { name: "Crimson",              num: 238, hex: "#DC143C" },
        { name: "Vermilion",            num: 239, hex: "#FF1852" },
        { name: "Pale Violet Red",      num: 240, hex: "#DB7093" },
        { name: "Pink",                 num: 241, hex: "#FFB6C1" },
        { name: "Pink Blush",           num: 242, hex: "#FFC0CB" },
        { name: "Lavender Blush",       num: 243, hex: "#FFF0F5" },
        { name: "Virgin Mobile Red",    num: 244, hex: "#CC0001" },
        { name: "Dead Red",             num: 245, hex: "#E81123" },
        { name: "Black",                num: 246, hex: "#000000" },
        { name: "Coal Gray",            num: 247, hex: "#090909" },
        { name: "Jet Black",            num: 248, hex: "#0A0A0A" },
        { name: "Onyx",                 num: 249, hex: "#1A1A1A" },
        { name: "Storm Gray",           num: 250, hex: "#2B2A2A" },
        { name: "Graphite",             num: 251, hex: "#383838" },
        { name: "Dark Grey",            num: 252, hex: "#404040" },
        { name: "Dark",                 num: 253, hex: "#555555" },
        { name: "Charcoal",             num: 254, hex: "#606060" },
        { name: "Dim Gray",             num: 255, hex: "#696969" },
        { name: "Gray",                 num: 256, hex: "#808080" },
        { name: "Dark Gray",            num: 257, hex: "#A9A9A9" },
        { name: "Silver",               num: 258, hex: "#C0C0C0" },
        { name: "Light Gray",           num: 259, hex: "#D3D3D3" },
        { name: "Gainsboro",            num: 260, hex: "#DCDCDC" },
        { name: "Off White",            num: 261, hex: "#EEEEEE" },
        { name: "White Smoke",          num: 262, hex: "#F5F5F5" },
        { name: "White",                num: 263, hex: "#FFFFFF" }
    ]

    property var themeColors: accentColors

    implicitWidth:  parent ? parent.width : 600
    implicitHeight: mainCol.implicitHeight

    // ═══════════════════════════════════════════════════════════════
    // MAIN COLUMN
    // ═══════════════════════════════════════════════════════════════
    Column {
        id: mainCol
        width: parent.width
        spacing: vpx(4)

        // ══════════════════════════════════════════════════════════
        // TITLE BAR
        // ══════════════════════════════════════════════════════════
        Item {
            width: parent.width
            height: vpx(38)

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(unicolor.currentAccentColor.r, unicolor.currentAccentColor.g, unicolor.currentAccentColor.b, 0.14)
                border.color: Qt.rgba(unicolor.currentAccentColor.r, unicolor.currentAccentColor.g, unicolor.currentAccentColor.b, 0.40)
                border.width: vpx(1); radius: vpx(4)
            }
            StyledText {
                id: titleIcon
                anchors.left: parent.left; anchors.leftMargin: vpx(12)
                anchors.verticalCenter: parent.verticalCenter
                text: "🎨"; font.pixelSize: vpx(16); layer.enabled: false
            }
            StyledText {
                anchors.left: titleIcon.right; anchors.leftMargin: vpx(6)
                anchors.verticalCenter: parent.verticalCenter
                text: "Unicolor"; font.pixelSize: vpx(15); font.bold: true; color: "#FFFFFF"; layer.enabled: false
            }
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: vpx(8)
                anchors.verticalCenter: parent.verticalCenter
                width: vpx(72); height: vpx(26); radius: vpx(4)
                color: hvMA.containsMouse ? Qt.rgba(unicolor.currentAccentColor.r, unicolor.currentAccentColor.g, unicolor.currentAccentColor.b, 0.40) : "#33FFFFFF"
                border.color: unicolor.currentAccentColor; border.width: vpx(1)
                Behavior on color { ColorAnimation { duration: 80 } }
                Row {
                    anchors.centerIn: parent; spacing: vpx(6)
                    StyledText { text: "⇔"; font.pixelSize: vpx(14); font.bold: unicolor.horizontalView; color: unicolor.horizontalView ? "#FFFFFF" : "#777777"; layer.enabled: false }
                    Rectangle { width: vpx(1); height: vpx(16); color: "#555555"; anchors.verticalCenter: parent.verticalCenter }
                    StyledText { text: "⇕"; font.pixelSize: vpx(14); font.bold: !unicolor.horizontalView; color: !unicolor.horizontalView ? "#FFFFFF" : "#777777"; layer.enabled: false }
                }
                MouseArea { id: hvMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: unicolor.horizontalView = !unicolor.horizontalView }
            }
        }

        // ══════════════════════════════════════════════════════════
        // ACCENT COLOUR SECTION
        // ══════════════════════════════════════════════════════════
        Column {
            id: accentSectionCol
            width: parent.width; spacing: 0

            // ── Accent header ─────────────────────────────────────
            // Fixed layout: label | info-text(fills) | swatches | ◀▶▼(pinned right)
            Item {
                width: parent.width; height: vpx(52)

                Rectangle {
                    anchors.fill: parent; anchors.margins: vpx(2); radius: vpx(3)
                    color: Qt.rgba(unicolor.currentAccentColor.r, unicolor.currentAccentColor.g, unicolor.currentAccentColor.b, 0.12)
                    border.color: unicolor.currentAccentColor; border.width: vpx(1)
                }

                // "Accent Color" label — fixed left
                StyledText {
                    id: accentLabel
                    anchors.left: parent.left; anchors.leftMargin: vpx(14)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Accent Color"; font.pixelSize: vpx(15); font.bold: true; color: "#FFFFFF"; layer.enabled: false
                }

                // Buttons: ◀ ▶ ▼ — PINNED to right, never moves
                // Width = 24+4+24+4+28 = 84
                Item {
                    id: acBtns
                    anchors.right: parent.right; anchors.rightMargin: vpx(8)
                    anchors.verticalCenter: parent.verticalCenter
                    width: vpx(84); height: vpx(28)

                    Rectangle {
                        id: acExpandBtn; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: vpx(28); height: vpx(24); radius: vpx(4)
                        color: expAccMA.containsMouse ? unicolor.currentAccentColor : "#2AFFFFFF"
                        border.color: unicolor.currentAccentColor; border.width: vpx(1)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        StyledText { anchors.centerIn: parent; text: unicolor.accentExpanded ? "▲" : "▼"; font.pixelSize: vpx(11); font.bold: true; layer.enabled: false }
                        MouseArea { id: expAccMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: unicolor.accentExpanded = !unicolor.accentExpanded }
                    }
                    Rectangle {
                        id: acNextBtn; anchors.right: acExpandBtn.left; anchors.rightMargin: vpx(4); anchors.verticalCenter: parent.verticalCenter
                        width: vpx(24); height: vpx(24); radius: vpx(4)
                        color: aNextMA.containsMouse ? unicolor.currentAccentColor : "#2AFFFFFF"
                        border.color: unicolor.currentAccentColor; border.width: vpx(1)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        StyledText { anchors.centerIn: parent; text: "▶"; font.pixelSize: vpx(11); layer.enabled: false }
                        MouseArea { id: aNextMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: { var n=(unicolor.accentFillIdx+1)%unicolor.accentColors.length; unicolor.accentFillIdx=n; unicolor.doSave("cfg.accentFill",n.toString()) } }
                    }
                    Rectangle {
                        id: acPrevBtn; anchors.right: acNextBtn.left; anchors.rightMargin: vpx(4); anchors.verticalCenter: parent.verticalCenter
                        width: vpx(24); height: vpx(24); radius: vpx(4)
                        color: aPrevMA.containsMouse ? unicolor.currentAccentColor : "#2AFFFFFF"
                        border.color: unicolor.currentAccentColor; border.width: vpx(1)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        StyledText { anchors.centerIn: parent; text: "◀"; font.pixelSize: vpx(11); layer.enabled: false }
                        MouseArea { id: aPrevMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: { var n=(unicolor.accentFillIdx-1+unicolor.accentColors.length)%unicolor.accentColors.length; unicolor.accentFillIdx=n; unicolor.doSave("cfg.accentFill",n.toString()) } }
                    }
                }

                // 8 neighbor swatches — anchored to LEFT of the button block, never moves
                Row {
                    id: accentSwatches
                    visible: !unicolor.accentExpanded
                    anchors.right: acBtns.left; anchors.rightMargin: vpx(6)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(3)
                    Repeater {
                        model: 8
                        delegate: Item {
                            // -3,-2,-1, 0(sel), +1,+2,+3,+4
                            property int offset:   index - 3
                            property int colorIdx: (unicolor.accentFillIdx + offset + unicolor.accentColors.length) % unicolor.accentColors.length
                            property bool isSel:   colorIdx === unicolor.accentFillIdx
                            width: vpx(24); height: vpx(24)
                            Rectangle {
                                anchors.fill: parent; radius: vpx(4)
                                color: unicolor.accentColors[colorIdx].hex
                                border.color: isSel ? "#FFFFFF" : "#33FFFFFF"
                                border.width: isSel ? vpx(2) : vpx(1)
                                opacity: isSel ? 1.0 : 0.75
                            }
                            StyledText { anchors.centerIn: parent; text: isSel ? "✔" : ""; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"; layer.enabled: false }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { unicolor.accentFillIdx=colorIdx; unicolor.doSave("cfg.accentFill",colorIdx.toString()) } }
                        }
                    }
                }

                // Info text — fills the gap between label and swatches, elides cleanly
                StyledText {
                    visible: !unicolor.accentExpanded
                    anchors.left: accentLabel.right; anchors.leftMargin: vpx(10)
                    anchors.right: accentSwatches.left; anchors.rightMargin: vpx(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        var c = unicolor.accentColors[unicolor.accentFillIdx]
                        return c ? c.name + "   #" + c.num + "   " + c.hex.toUpperCase() : ""
                    }
                    font.pixelSize: vpx(12); color: unicolor.currentAccentColor
                    elide: Text.ElideRight; layer.enabled: false
                }
            }

            // ── Accent expanded panel ─────────────────────────────
            Item {
                id: accentExpandedPanel
                width: parent.width
                height: unicolor.accentExpanded
                       ? (unicolor.horizontalView ? accentGridFlow.implicitHeight + vpx(16) : unicolor.listPanelHeight + vpx(8))
                       : 0
                clip: true
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Rectangle { anchors.fill: parent; anchors.margins: vpx(3); radius: vpx(4); color: "#14FFFFFF"
                    border.color: Qt.rgba(unicolor.currentAccentColor.r, unicolor.currentAccentColor.g, unicolor.currentAccentColor.b, 0.22); border.width: vpx(1) }

                Flow {
                    id: accentGridFlow
                    visible: unicolor.horizontalView && unicolor.accentExpanded
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: vpx(8)
                    spacing: vpx(3)
                    Repeater { model: unicolor.accentColors.length; delegate: accentTileComp }
                }

                Item {
                    visible: !unicolor.horizontalView && unicolor.accentExpanded
                    anchors.fill: parent; anchors.margins: vpx(4)

                    Rectangle {
                        id: acUpBtn; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                        width: vpx(60); height: vpx(22); radius: vpx(4)
                        color: acUpMA.containsMouse ? unicolor.currentAccentColor : "#33FFFFFF"
                        border.color: unicolor.currentAccentColor; border.width: vpx(1)
                        visible: accentFlick.contentY > 0; z: 2
                        Behavior on color { ColorAnimation { duration: 80 } }
                        StyledText { anchors.centerIn: parent; text: "▲"; font.pixelSize: vpx(11); layer.enabled: false }
                        MouseArea { id: acUpMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: accentFlick.contentY = Math.max(0, accentFlick.contentY - unicolor.rowH * 5) }
                    }
                    Flickable {
                        id: accentFlick
                        anchors.top: acUpBtn.visible ? acUpBtn.bottom : parent.top
                        anchors.bottom: acDownBtn.visible ? acDownBtn.top : parent.bottom
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.topMargin: acUpBtn.visible ? vpx(2) : 0
                        anchors.bottomMargin: acDownBtn.visible ? vpx(2) : 0
                        clip: true; contentHeight: accentDualCol.implicitHeight
                        flickableDirection: Flickable.VerticalFlick; interactive: true
                        Grid { id: accentDualCol; width: accentFlick.width; columns: 2; columnSpacing: vpx(4); rowSpacing: vpx(2)
                            Repeater { model: unicolor.accentColors.length; delegate: accentListRowComp } }
                    }
                    Rectangle {
                        id: acDownBtn; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                        width: vpx(60); height: vpx(22); radius: vpx(4)
                        color: acDownMA.containsMouse ? unicolor.currentAccentColor : "#33FFFFFF"
                        border.color: unicolor.currentAccentColor; border.width: vpx(1)
                        visible: accentFlick.contentY < (accentFlick.contentHeight - accentFlick.height - 1); z: 2
                        Behavior on color { ColorAnimation { duration: 80 } }
                        StyledText { anchors.centerIn: parent; text: "▼"; font.pixelSize: vpx(11); layer.enabled: false }
                        MouseArea { id: acDownMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: accentFlick.contentY = Math.min(accentFlick.contentHeight-accentFlick.height, accentFlick.contentY+unicolor.rowH*5) }
                    }
                }
            }

            // ── Accent gradient toggle ────────────────────────────
            Item {
                width: parent.width; height: vpx(36)
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: vpx(14); anchors.rightMargin: vpx(14); spacing: vpx(8)
                    StyledText { text: "Gradient"; font.pixelSize: vpx(13); color: unicolor.gradAccentColor ? unicolor.currentAccentColor : "#555555"; layer.enabled: false }
                    Rectangle { width: vpx(20); height: vpx(20); radius: vpx(4); color: unicolor.gradAccentColor ? unicolor.currentAccentColor : "#222222"; border.color: unicolor.gradAccentColor ? unicolor.currentAccentColor : "#555555"; border.width: vpx(1); Behavior on color{ColorAnimation{duration:80}}
                        StyledText { anchors.centerIn: parent; text: unicolor.gradAccentColor ? "✓" : ""; font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF"; layer.enabled: false }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { unicolor.gradAccentColor=!unicolor.gradAccentColor; unicolor.doSave("cfg.gradAccent",unicolor.gradAccentColor?"true":"false") } }
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }

        // ── Accent Opacity slider ─────────────────────────────────
        Item {
            width: parent.width; height: vpx(50)
            Rectangle { anchors.fill: parent; anchors.margins: vpx(2); radius: vpx(3); color: "#0AFFFFFF"; border.color: "#22FFFFFF"; border.width: vpx(1) }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: vpx(14); anchors.rightMargin: vpx(14); spacing: vpx(8)
                StyledText { text: "Accent Opacity"; font.pixelSize: vpx(15); color: "#FFFFFF"; Layout.fillWidth: true; layer.enabled: false }
                Item {
                    id: acSlider; Layout.preferredWidth: vpx(160); height: vpx(24); Layout.alignment: Qt.AlignVCenter
                    function setVal(mx) { var v=Math.max(0,Math.min(100,Math.round(Math.max(0,Math.min(1,mx/trackAc.width))*100/5)*5)); unicolor.accentTransparency=v; unicolor.doSave("cfg.accentAlpha",v.toString()) }
                    Rectangle { id: trackAc; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; height: vpx(7); color: "#3CFFFFFF"; radius: vpx(4)
                        Rectangle { width: parent.width*(1.0-unicolor.accentTransparency/100); height: parent.height; color: unicolor.currentAccentColor; radius: vpx(4); Behavior on width{NumberAnimation{duration:60}} }
                        Rectangle { x: (trackAc.width-vpx(12))*(1.0-unicolor.accentTransparency/100); anchors.verticalCenter: parent.verticalCenter; width: vpx(12); height: vpx(12); radius: vpx(6); color: "#FFFFFF"; border.color: unicolor.currentAccentColor; border.width: vpx(2); Behavior on x{NumberAnimation{duration:60}} }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.SizeHorCursor; preventStealing: true; onPressed: acSlider.setVal(mouse.x); onPositionChanged: { if(pressed) acSlider.setVal(mouse.x) } }
                }
                Rectangle { width: vpx(24); height: vpx(24); radius: vpx(4); color: acDecMA.containsMouse?unicolor.currentAccentColor:"#2AFFFFFF"; border.color: unicolor.currentAccentColor; border.width: vpx(1); Behavior on color{ColorAnimation{duration:80}}
                    StyledText { anchors.centerIn: parent; text: "◀"; font.pixelSize: vpx(11); layer.enabled: false }
                    MouseArea { id: acDecMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: { var v=Math.max(0,unicolor.accentTransparency-5); unicolor.accentTransparency=v; unicolor.doSave("cfg.accentAlpha",v.toString()) } }
                }
                Rectangle { width: vpx(24); height: vpx(24); radius: vpx(4); color: acIncMA.containsMouse?unicolor.currentAccentColor:"#2AFFFFFF"; border.color: unicolor.currentAccentColor; border.width: vpx(1); Behavior on color{ColorAnimation{duration:80}}
                    StyledText { anchors.centerIn: parent; text: "▶"; font.pixelSize: vpx(11); layer.enabled: false }
                    MouseArea { id: acIncMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: { var v=Math.min(100,unicolor.accentTransparency+5); unicolor.accentTransparency=v; unicolor.doSave("cfg.accentAlpha",v.toString()) } }
                }
                StyledText { text: (100-unicolor.accentTransparency)+"%"; font.pixelSize: vpx(14); font.bold: true; color: unicolor.currentAccentColor; Layout.minimumWidth: vpx(38); layer.enabled: false }
                StyledText { text: "Gradient"; font.pixelSize: vpx(13); color: unicolor.gradAccentOpacity?unicolor.currentAccentColor:"#555555"; layer.enabled: false }
                Rectangle { width: vpx(20); height: vpx(20); radius: vpx(4); color: unicolor.gradAccentOpacity?unicolor.currentAccentColor:"#222222"; border.color: unicolor.gradAccentOpacity?unicolor.currentAccentColor:"#555555"; border.width: vpx(1); Behavior on color{ColorAnimation{duration:80}}
                    StyledText { anchors.centerIn: parent; text: unicolor.gradAccentOpacity?"✓":""; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"; layer.enabled: false }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { unicolor.gradAccentOpacity=!unicolor.gradAccentOpacity; unicolor.doSave("cfg.gradAccentOp",unicolor.gradAccentOpacity?"true":"false") } }
                }
            }
        }

        // ══════════════════════════════════════════════════════════
        // THEME COLOUR SECTION
        // ══════════════════════════════════════════════════════════
        Column {
            id: themeSectionCol
            width: parent.width; spacing: 0

            // ── Theme header ──────────────────────────────────────
            Item {
                width: parent.width; height: vpx(52)

                Rectangle {
                    anchors.fill: parent; anchors.margins: vpx(2); radius: vpx(3)
                    color: Qt.rgba(parseInt(unicolor.currentThemeFillHex.substr(1,2),16)/255*0.4, parseInt(unicolor.currentThemeFillHex.substr(3,2),16)/255*0.4, parseInt(unicolor.currentThemeFillHex.substr(5,2),16)/255*0.4, 0.30)
                    border.color: unicolor.currentThemeFillHex; border.width: vpx(1)
                }

                StyledText {
                    id: themeLabel
                    anchors.left: parent.left; anchors.leftMargin: vpx(14)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Theme Color"; font.pixelSize: vpx(15); font.bold: true; color: "#FFFFFF"; layer.enabled: false
                }

                // Buttons: ◀ ▶ ▼ — PINNED to right
                Item {
                    id: thBtns
                    anchors.right: parent.right; anchors.rightMargin: vpx(8)
                    anchors.verticalCenter: parent.verticalCenter
                    width: vpx(84); height: vpx(28)

                    Rectangle {
                        id: thExpandBtn; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: vpx(28); height: vpx(24); radius: vpx(4)
                        color: expThMA.containsMouse ? unicolor.currentThemeFillHex : "#2AFFFFFF"
                        border.color: unicolor.currentThemeFillHex; border.width: vpx(1)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        StyledText { anchors.centerIn: parent; text: unicolor.themeExpanded?"▲":"▼"; font.pixelSize: vpx(11); font.bold: true; layer.enabled: false }
                        MouseArea { id: expThMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: unicolor.themeExpanded=!unicolor.themeExpanded }
                    }
                    Rectangle {
                        id: thNextBtn; anchors.right: thExpandBtn.left; anchors.rightMargin: vpx(4); anchors.verticalCenter: parent.verticalCenter
                        width: vpx(24); height: vpx(24); radius: vpx(4)
                        color: tNextMA.containsMouse ? unicolor.currentThemeFillHex : "#2AFFFFFF"
                        border.color: unicolor.currentThemeFillHex; border.width: vpx(1)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        StyledText { anchors.centerIn: parent; text: "▶"; font.pixelSize: vpx(11); layer.enabled: false }
                        MouseArea { id: tNextMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: { var n=(unicolor.themeFillIdx+1)%unicolor.themeColors.length; unicolor.themeFillIdx=n; unicolor.doSave("cfg.themeFill",n.toString()) } }
                    }
                    Rectangle {
                        id: thPrevBtn; anchors.right: thNextBtn.left; anchors.rightMargin: vpx(4); anchors.verticalCenter: parent.verticalCenter
                        width: vpx(24); height: vpx(24); radius: vpx(4)
                        color: tPrevMA.containsMouse ? unicolor.currentThemeFillHex : "#2AFFFFFF"
                        border.color: unicolor.currentThemeFillHex; border.width: vpx(1)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        StyledText { anchors.centerIn: parent; text: "◀"; font.pixelSize: vpx(11); layer.enabled: false }
                        MouseArea { id: tPrevMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: { var n=(unicolor.themeFillIdx-1+unicolor.themeColors.length)%unicolor.themeColors.length; unicolor.themeFillIdx=n; unicolor.doSave("cfg.themeFill",n.toString()) } }
                    }
                }

                // 8 neighbor swatches — anchored to left of buttons
                Row {
                    id: themeSwatches
                    visible: !unicolor.themeExpanded
                    anchors.right: thBtns.left; anchors.rightMargin: vpx(6)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(3)
                    Repeater {
                        model: 8
                        delegate: Item {
                            property int offset:   index - 3
                            property int colorIdx: (unicolor.themeFillIdx + offset + unicolor.themeColors.length) % unicolor.themeColors.length
                            property bool isSel:   colorIdx === unicolor.themeFillIdx
                            width: vpx(24); height: vpx(24)
                            Rectangle {
                                anchors.fill: parent; radius: vpx(4)
                                color: unicolor.themeColors[colorIdx].hex
                                border.color: isSel ? "#FFFFFF" : "#33FFFFFF"
                                border.width: isSel ? vpx(2) : vpx(1)
                                opacity: isSel ? 1.0 : 0.75
                            }
                            StyledText { anchors.centerIn: parent; text: isSel?"✔":""; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"; layer.enabled: false }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { unicolor.themeFillIdx=colorIdx; unicolor.doSave("cfg.themeFill",colorIdx.toString()) } }
                        }
                    }
                }

                // Info text — fills gap between label and swatches
                StyledText {
                    visible: !unicolor.themeExpanded
                    anchors.left: themeLabel.right; anchors.leftMargin: vpx(10)
                    anchors.right: themeSwatches.left; anchors.rightMargin: vpx(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: { var c=unicolor.themeColors[unicolor.themeFillIdx]; return c?c.name+"   #"+c.num+"   "+c.hex.toUpperCase():"" }
                    font.pixelSize: vpx(12); color: unicolor.currentThemeFillHex
                    elide: Text.ElideRight; layer.enabled: false
                }
            }

            // ── Theme expanded panel ──────────────────────────────
            Item {
                id: themeExpandedPanel
                width: parent.width
                height: unicolor.themeExpanded
                       ? (unicolor.horizontalView ? themeGridFlow.implicitHeight + vpx(16) : unicolor.listPanelHeight + vpx(8))
                       : 0
                clip: true
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Rectangle { anchors.fill: parent; anchors.margins: vpx(3); radius: vpx(4); color: "#14FFFFFF"
                    border.color: Qt.rgba(parseInt(unicolor.currentThemeFillHex.substr(1,2),16)/255, parseInt(unicolor.currentThemeFillHex.substr(3,2),16)/255, parseInt(unicolor.currentThemeFillHex.substr(5,2),16)/255, 0.25); border.width: vpx(1) }

                Flow {
                    id: themeGridFlow
                    visible: unicolor.horizontalView && unicolor.themeExpanded
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: vpx(8)
                    spacing: vpx(3)
                    Repeater { model: unicolor.themeColors.length; delegate: themeTileComp }
                }

                Item {
                    visible: !unicolor.horizontalView && unicolor.themeExpanded
                    anchors.fill: parent; anchors.margins: vpx(4)

                    Rectangle {
                        id: thUpBtn; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                        width: vpx(60); height: vpx(22); radius: vpx(4)
                        color: thUpMA.containsMouse ? unicolor.currentThemeFillHex : "#33FFFFFF"
                        border.color: unicolor.currentThemeFillHex; border.width: vpx(1)
                        visible: themeFlick.contentY > 0; z: 2
                        Behavior on color { ColorAnimation { duration: 80 } }
                        StyledText { anchors.centerIn: parent; text: "▲"; font.pixelSize: vpx(11); layer.enabled: false }
                        MouseArea { id: thUpMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: themeFlick.contentY = Math.max(0, themeFlick.contentY - unicolor.rowH * 5) }
                    }
                    Flickable {
                        id: themeFlick
                        anchors.top: thUpBtn.visible ? thUpBtn.bottom : parent.top
                        anchors.bottom: thDownBtn.visible ? thDownBtn.top : parent.bottom
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.topMargin: thUpBtn.visible ? vpx(2) : 0
                        anchors.bottomMargin: thDownBtn.visible ? vpx(2) : 0
                        clip: true; contentHeight: themeDualCol.implicitHeight
                        flickableDirection: Flickable.VerticalFlick; interactive: true
                        Grid { id: themeDualCol; width: themeFlick.width; columns: 2; columnSpacing: vpx(4); rowSpacing: vpx(2)
                            Repeater { model: unicolor.themeColors.length; delegate: themeListRowComp } }
                    }
                    Rectangle {
                        id: thDownBtn; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                        width: vpx(60); height: vpx(22); radius: vpx(4)
                        color: thDownMA.containsMouse ? unicolor.currentThemeFillHex : "#33FFFFFF"
                        border.color: unicolor.currentThemeFillHex; border.width: vpx(1)
                        visible: themeFlick.contentY < (themeFlick.contentHeight - themeFlick.height - 1); z: 2
                        Behavior on color { ColorAnimation { duration: 80 } }
                        StyledText { anchors.centerIn: parent; text: "▼"; font.pixelSize: vpx(11); layer.enabled: false }
                        MouseArea { id: thDownMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: themeFlick.contentY = Math.min(themeFlick.contentHeight-themeFlick.height, themeFlick.contentY+unicolor.rowH*5) }
                    }
                }
            }

            // ── Theme gradient toggle ─────────────────────────────
            Item {
                width: parent.width; height: vpx(36)
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: vpx(14); anchors.rightMargin: vpx(14); spacing: vpx(8)
                    StyledText { text: "Gradient"; font.pixelSize: vpx(13); color: unicolor.gradThemeColor?unicolor.currentThemeFillHex:"#555555"; layer.enabled: false }
                    Rectangle { width: vpx(20); height: vpx(20); radius: vpx(4); color: unicolor.gradThemeColor?unicolor.currentThemeFillHex:"#222222"; border.color: unicolor.gradThemeColor?unicolor.currentThemeFillHex:"#555555"; border.width: vpx(1); Behavior on color{ColorAnimation{duration:80}}
                        StyledText { anchors.centerIn: parent; text: unicolor.gradThemeColor?"✓":""; font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF"; layer.enabled: false }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { unicolor.gradThemeColor=!unicolor.gradThemeColor; unicolor.doSave("cfg.gradTheme",unicolor.gradThemeColor?"true":"false") } }
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }

        // ── Theme Transparency slider ─────────────────────────────
        Item {
            width: parent.width; height: vpx(50)
            Rectangle { anchors.fill: parent; anchors.margins: vpx(2); radius: vpx(3); color: "#0AFFFFFF"; border.color: "#22FFFFFF"; border.width: vpx(1) }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: vpx(14); anchors.rightMargin: vpx(14); spacing: vpx(8)
                StyledText { text: "Theme Transparency"; font.pixelSize: vpx(15); color: "#FFFFFF"; Layout.fillWidth: true; layer.enabled: false }
                Item {
                    id: thSlider; Layout.preferredWidth: vpx(160); height: vpx(24); Layout.alignment: Qt.AlignVCenter
                    function setVal(mx) { var v=Math.max(0,Math.min(100,Math.round(Math.max(0,Math.min(1,mx/trackTh.width))*100/5)*5)); unicolor.interfaceTransparency=v; unicolor.doSave("cfg.ifaceAlpha",v.toString()) }
                    Rectangle { id: trackTh; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; height: vpx(7); color: "#3CFFFFFF"; radius: vpx(4)
                        Rectangle { width: parent.width*(1.0-unicolor.interfaceTransparency/100); height: parent.height; color: unicolor.currentThemeFillHex; radius: vpx(4); Behavior on width{NumberAnimation{duration:60}} }
                        Rectangle { x: (trackTh.width-vpx(12))*(1.0-unicolor.interfaceTransparency/100); anchors.verticalCenter: parent.verticalCenter; width: vpx(12); height: vpx(12); radius: vpx(6); color: "#FFFFFF"; border.color: unicolor.currentThemeFillHex; border.width: vpx(2); Behavior on x{NumberAnimation{duration:60}} }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.SizeHorCursor; preventStealing: true; onPressed: thSlider.setVal(mouse.x); onPositionChanged: { if(pressed) thSlider.setVal(mouse.x) } }
                }
                Rectangle { width: vpx(24); height: vpx(24); radius: vpx(4); color: thDecMA.containsMouse?unicolor.currentThemeFillHex:"#2AFFFFFF"; border.color: unicolor.currentThemeFillHex; border.width: vpx(1); Behavior on color{ColorAnimation{duration:80}}
                    StyledText { anchors.centerIn: parent; text: "◀"; font.pixelSize: vpx(11); layer.enabled: false }
                    MouseArea { id: thDecMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: { var v=Math.max(0,unicolor.interfaceTransparency-5); unicolor.interfaceTransparency=v; unicolor.doSave("cfg.ifaceAlpha",v.toString()) } }
                }
                Rectangle { width: vpx(24); height: vpx(24); radius: vpx(4); color: thIncMA.containsMouse?unicolor.currentThemeFillHex:"#2AFFFFFF"; border.color: unicolor.currentThemeFillHex; border.width: vpx(1); Behavior on color{ColorAnimation{duration:80}}
                    StyledText { anchors.centerIn: parent; text: "▶"; font.pixelSize: vpx(11); layer.enabled: false }
                    MouseArea { id: thIncMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: { var v=Math.min(100,unicolor.interfaceTransparency+5); unicolor.interfaceTransparency=v; unicolor.doSave("cfg.ifaceAlpha",v.toString()) } }
                }
                StyledText { text: (100-unicolor.interfaceTransparency)+"%"; font.pixelSize: vpx(14); font.bold: true; color: unicolor.currentThemeFillHex; Layout.minimumWidth: vpx(38); layer.enabled: false }
                StyledText { text: "Gradient"; font.pixelSize: vpx(13); color: unicolor.gradThemeTransp?unicolor.currentThemeFillHex:"#555555"; layer.enabled: false }
                Rectangle { width: vpx(20); height: vpx(20); radius: vpx(4); color: unicolor.gradThemeTransp?unicolor.currentThemeFillHex:"#222222"; border.color: unicolor.gradThemeTransp?unicolor.currentThemeFillHex:"#555555"; border.width: vpx(1); Behavior on color{ColorAnimation{duration:80}}
                    StyledText { anchors.centerIn: parent; text: unicolor.gradThemeTransp?"✓":""; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"; layer.enabled: false }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { unicolor.gradThemeTransp=!unicolor.gradThemeTransp; unicolor.doSave("cfg.gradThemeTr",unicolor.gradThemeTransp?"true":"false") } }
                }
            }
        }

        // ══════════════════════════════════════════════════════════
        // COLOR PRESETS SECTION
        // ══════════════════════════════════════════════════════════
        UnicolorPresets {
            id: presets
            width: parent.width
            accentFillIdx:  unicolor.accentFillIdx
            themeFillIdx:   unicolor.themeFillIdx
            accentColor:    unicolor.currentAccentColor
            saveFunc:       unicolor.saveFunc
            accentColors:   unicolor.accentColors
            themeColors:    unicolor.themeColors
            horizontalView: unicolor.horizontalView
            onPresetApplied: function(accentIdx, themeIdx) {
                unicolor.accentFillIdx = accentIdx
                unicolor.themeFillIdx  = themeIdx
                unicolor.doSave("cfg.accentFill", accentIdx.toString())
                unicolor.doSave("cfg.themeFill",  themeIdx.toString())
            }
        }

    } // mainCol

    // ═══════════════════════════════════════════════════════════════
    // DELEGATE COMPONENTS
    // ═══════════════════════════════════════════════════════════════

    Component {
        id: accentTileComp
        Item {
            property var  cdata:      unicolor.accentColors[index]
            property bool isSelected: index === unicolor.accentFillIdx
            width: vpx(130); height: vpx(44)
            Rectangle { anchors.fill: parent; anchors.margins: vpx(2); radius: vpx(5)
                color: aTileMA.containsMouse ? Qt.rgba(parseInt(cdata.hex.substr(1,2),16)/255,parseInt(cdata.hex.substr(3,2),16)/255,parseInt(cdata.hex.substr(5,2),16)/255,0.28) : (isSelected?"#1EFFFFFF":"transparent")
                border.color: isSelected?"#CCFFFFFF":(aTileMA.containsMouse?"#55FFFFFF":"#22FFFFFF"); border.width: vpx(1)
                Behavior on color { ColorAnimation { duration: 80 } } }
            RowLayout { anchors.fill: parent; anchors.margins: vpx(4); spacing: vpx(5)
                Rectangle { width: vpx(28); height: vpx(28); radius: vpx(4); color: cdata.hex; border.color: isSelected?"#FFFFFF":"transparent"; border.width: vpx(2)
                    StyledText { anchors.centerIn: parent; text: isSelected?"✔":""; font.pixelSize: vpx(13); font.bold: true; color: "#FFFFFF"; layer.enabled: false } }
                Column { Layout.fillWidth: true; spacing: vpx(1)
                    StyledText { text: cdata.name; font.pixelSize: vpx(11); font.bold: isSelected; color: isSelected?"#FFFFFF":"#CCCCCC"; elide: Text.ElideRight; width: parent.width; layer.enabled: false }
                    Row { spacing: vpx(4)
                        StyledText { text: "#"+cdata.num; font.pixelSize: vpx(9); color: "#888888"; layer.enabled: false }
                        StyledText { text: cdata.hex.toUpperCase(); font.pixelSize: vpx(9); color: "#888888"; layer.enabled: false } } } }
            MouseArea { id: aTileMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                onClicked: { unicolor.accentFillIdx=index; unicolor.doSave("cfg.accentFill",index.toString()) } }
        }
    }

    Component {
        id: accentListRowComp
        Item {
            property var  cdata:      unicolor.accentColors[index]
            property bool isSelected: index === unicolor.accentFillIdx
            width: (accentDualCol.width - accentDualCol.columnSpacing) / 2; height: unicolor.rowH
            Rectangle { anchors.fill: parent; anchors.margins: vpx(1); radius: vpx(4)
                color: aRowMA.containsMouse ? Qt.rgba(parseInt(cdata.hex.substr(1,2),16)/255,parseInt(cdata.hex.substr(3,2),16)/255,parseInt(cdata.hex.substr(5,2),16)/255,0.22) : (isSelected?"#18FFFFFF":"transparent")
                border.color: isSelected?"#88FFFFFF":"transparent"; border.width: vpx(1)
                Behavior on color { ColorAnimation { duration: 80 } } }
            RowLayout { anchors.fill: parent; anchors.leftMargin: vpx(6); anchors.rightMargin: vpx(4); spacing: vpx(6)
                Rectangle { width: vpx(22); height: vpx(22); radius: vpx(3); color: cdata.hex; border.color: isSelected?"#FFFFFF":"transparent"; border.width: vpx(2)
                    StyledText { anchors.centerIn: parent; text: isSelected?"✔":""; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"; layer.enabled: false } }
                StyledText { text: cdata.name; font.pixelSize: vpx(12); font.bold: isSelected; color: isSelected?"#FFFFFF":"#CCCCCC"; Layout.preferredWidth: vpx(90); elide: Text.ElideRight; layer.enabled: false }
                StyledText { text: "#"+cdata.num; font.pixelSize: vpx(10); color: "#777777"; Layout.preferredWidth: vpx(26); layer.enabled: false }
                StyledText { text: cdata.hex.toUpperCase(); font.pixelSize: vpx(10); color: isSelected?cdata.hex:"#666666"; Layout.fillWidth: true; elide: Text.ElideRight; layer.enabled: false } }
            MouseArea { id: aRowMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                onClicked: { unicolor.accentFillIdx=index; unicolor.doSave("cfg.accentFill",index.toString()) } }
        }
    }

    Component {
        id: themeTileComp
        Item {
            property var  cdata:      unicolor.themeColors[index]
            property bool isSelected: index === unicolor.themeFillIdx
            width: vpx(130); height: vpx(44)
            Rectangle { anchors.fill: parent; anchors.margins: vpx(2); radius: vpx(5)
                color: tTileMA.containsMouse?"#1EFFFFFF":(isSelected?"#18FFFFFF":"transparent")
                border.color: isSelected?"#CCFFFFFF":(tTileMA.containsMouse?"#44FFFFFF":"#22FFFFFF"); border.width: vpx(1)
                Behavior on color { ColorAnimation { duration: 80 } } }
            RowLayout { anchors.fill: parent; anchors.margins: vpx(4); spacing: vpx(5)
                Rectangle { width: vpx(28); height: vpx(28); radius: vpx(4); color: cdata.hex; border.color: isSelected?"#FFFFFF":"#33FFFFFF"; border.width: vpx(2)
                    StyledText { anchors.centerIn: parent; text: isSelected?"✔":""; font.pixelSize: vpx(13); font.bold: true; color: "#FFFFFF"; layer.enabled: false } }
                Column { Layout.fillWidth: true; spacing: vpx(1)
                    StyledText { text: cdata.name; font.pixelSize: vpx(11); font.bold: isSelected; color: isSelected?"#FFFFFF":"#CCCCCC"; elide: Text.ElideRight; width: parent.width; layer.enabled: false }
                    Row { spacing: vpx(4)
                        StyledText { text: "#"+cdata.num; font.pixelSize: vpx(9); color: "#888888"; layer.enabled: false }
                        StyledText { text: cdata.hex.toUpperCase(); font.pixelSize: vpx(9); color: "#888888"; layer.enabled: false } } } }
            MouseArea { id: tTileMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                onClicked: { unicolor.themeFillIdx=index; unicolor.doSave("cfg.themeFill",index.toString()) } }
        }
    }

    Component {
        id: themeListRowComp
        Item {
            property var  cdata:      unicolor.themeColors[index]
            property bool isSelected: index === unicolor.themeFillIdx
            width: (themeDualCol.width - themeDualCol.columnSpacing) / 2; height: unicolor.rowH
            Rectangle { anchors.fill: parent; anchors.margins: vpx(1); radius: vpx(4)
                color: tRowMA.containsMouse?"#18FFFFFF":(isSelected?"#14FFFFFF":"transparent")
                border.color: isSelected?"#66FFFFFF":"transparent"; border.width: vpx(1)
                Behavior on color { ColorAnimation { duration: 80 } } }
            RowLayout { anchors.fill: parent; anchors.leftMargin: vpx(6); anchors.rightMargin: vpx(4); spacing: vpx(6)
                Rectangle { width: vpx(22); height: vpx(22); radius: vpx(3); color: cdata.hex; border.color: isSelected?"#FFFFFF":"#33FFFFFF"; border.width: vpx(2)
                    StyledText { anchors.centerIn: parent; text: isSelected?"✔":""; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"; layer.enabled: false } }
                StyledText { text: cdata.name; font.pixelSize: vpx(12); font.bold: isSelected; color: isSelected?"#FFFFFF":"#CCCCCC"; Layout.preferredWidth: vpx(90); elide: Text.ElideRight; layer.enabled: false }
                StyledText { text: "#"+cdata.num; font.pixelSize: vpx(10); color: "#777777"; Layout.preferredWidth: vpx(26); layer.enabled: false }
                StyledText { text: cdata.hex.toUpperCase(); font.pixelSize: vpx(10); color: isSelected?cdata.hex:"#666666"; Layout.fillWidth: true; elide: Text.ElideRight; layer.enabled: false } }
            MouseArea { id: tRowMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                onClicked: { unicolor.themeFillIdx=index; unicolor.doSave("cfg.themeFill",index.toString()) } }
        }
    }

}
