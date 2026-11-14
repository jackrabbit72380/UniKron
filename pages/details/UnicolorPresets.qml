import QtQuick 2.8
import QtQuick.Layouts 1.1
import "../../components"

// ════════════════════════════════════════════════════════════════════
// UnicolorPresets.qml  —  Preset accent+theme color combos
//
// Usage in Unicolor.qml:
//   UnicolorPresets {
//       id: presets
//       accentFillIdx:             unicolor.accentFillIdx
//       themeFillIdx:              unicolor.themeFillIdx
//       accentColor:               unicolor.currentAccentColor
//       saveFunc:                  unicolor.saveFunc
//       // Live setting bindings — captured at save time:
//       accentOpacity:             unicolor.accentOpacity
//       accentGradient:            unicolor.accentGradient
//       accentGradientStrength:    unicolor.accentGradientStrength
//       themeIdx:                  unicolor.themeFillIdx
//       themeOpacity:              unicolor.themeOpacity
//       themeGradient:             unicolor.themeGradient
//       themeTransparency:         unicolor.themeTransparency
//       themeTransparencyStrength: unicolor.themeTransparencyStrength
//       panelGradient:             unicolor.panelGradient
//       onPresetApplied: function(accentIdx, themeIdx) {
//           unicolor.accentFillIdx      = accentIdx
//           unicolor.themeFillIdx       = themeIdx
//           var p = presets.lastAppliedPreset
//           if (p) {
//               unicolor.accentTransparency    = p.accentOpacity
//               unicolor.gradAccentColor       = p.gradAccentColor
//               unicolor.gradAccentOpacity     = p.gradAccentOpacity
//               unicolor.interfaceTransparency = p.themeOpacity
//               unicolor.gradThemeColor        = p.gradThemeColor
//               // themeTransparency, gradThemeTransp, panelGradient as needed
//           }
//       }
//   }
// ════════════════════════════════════════════════════════════════════

Item {
    id: presetsRoot

    // ── Bound from parent ─────────────────────────────────────────
    property int   accentFillIdx:  0
    property int   themeFillIdx:   0
    property color accentColor:    "#5d9809"
    property var   saveFunc:       null
    property var   accentColors:   []
    property var   themeColors:    []
    property bool  horizontalView: true

    // ── Live setting bindings (read at save time) ─────────────────
    property real  accentOpacity:            0
    property bool  gradAccentColor:          false
    property bool  gradAccentOpacity:        false
    property real  accentGradientStrength:   0
    property int   themeIdx:                 0
    property real  themeOpacity:             0
    property bool  gradThemeColor:           false
    property bool  themeTransparency:        false
    property real  themeTransparencyStrength:0
    property bool  gradThemeTransp:          false
    property bool  panelGradient:            false

    // ── Signals ───────────────────────────────────────────────────
    signal presetApplied(int accentIdx, int themeIdx)

    // Full preset object of the last applied preset — read in onPresetApplied
    property var lastAppliedPreset: null

    // ── Helpers ────────────────────────────────────────────────────
    function findColorIdx(colorArray, hex) {
        var h = hex.toUpperCase()
        for (var i = 0; i < colorArray.length; i++) {
            if (colorArray[i].hex.toUpperCase() === h) return i
        }
        return 0
    }
    function accentDataForPreset(p) {
        var idx = findColorIdx(accentColors, p.accent)
        return accentColors.length > 0 ? accentColors[idx] : { name: p.accent, num: "?", hex: p.accent }
    }
    function themeDataForPreset(p) {
        var idx = findColorIdx(themeColors, p.theme)
        return themeColors.length > 0 ? themeColors[idx] : { name: p.theme, num: "?", hex: p.theme }
    }



    // ── Panel state ───────────────────────────────────────────────
    property bool expanded:    false
    property bool usePresets:  api.memory.get("cfg.usePresets") === "true"
    property int  selectedIdx: { var v = api.memory.get("cfg.selectedPreset"); return (v !== null && v !== undefined && v !== "") ? parseInt(v) : -1 }

    // ── Built-in presets ─────────────────────────────────────────
    // Each entry: { name, accent, theme }
    // accent/theme = hex strings matched against UniAccents color list.
    // You can also store these as palette index numbers directly.
    //
    // Console color palettes sourced from official brand references:
    //   Xbox One   — black chassis, green accent  (#107C10 Microsoft green)
    //   Xbox 360   — white/silver, lime accent     (#52B043)
    //   SNES (US)  — grey/purple, purple+red       (#8B0082 / #CC0000)
    //   SNES (JP)  — light grey, colorful buttons  (#E4000F Famicom red)
    //   NES        — grey/black, red accent        (#E60012)
    //   Famicom    — red/gold                      (#CC0000 / #D4A017)
    //   Game Boy   — dark green/black              (#3B5323 / #000000)
    //   PlayStation — grey/dark, blue accent       (#003087)
    //   Sega Saturn — dark grey, blue              (#17408B)

    property var builtinPresets: [
        // ── Windows ──────────────────────────────────────────────
        { name: "Windows 11 Dark",  accent: "#007ACC", theme: "#1A1A1A", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Windows 11 Light", accent: "#007ACC", theme: "#F5F5F5", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        // ── Xbox ─────────────────────────────────────────────────
        { name: "Xbox One",         accent: "#008000", theme: "#1A1A1A", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Xbox 360",         accent: "#339933", theme: "#F5F5F5", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        // ── Nintendo ─────────────────────────────────────────────
        { name: "NES",              accent: "#EF001F", theme: "#383838", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "SNES (US)",        accent: "#8B008B", theme: "#808080", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Nintendo 64",      accent: "#0099CC", theme: "#F5F5F5", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Game Boy",         accent: "#355E3B", theme: "#0A0A0A", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Nintendo Wii",     accent: "#C0C0C0", theme: "#F5F5F5", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Nintendo Wii U",   accent: "#0099CC", theme: "#1A1A1A", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Nintendo Switch",  accent: "#EF001F", theme: "#1A1A1A", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        // ── PlayStation / Sega ───────────────────────────────────
        { name: "PlayStation",      accent: "#03417B", theme: "#696969", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Sega Saturn",      accent: "#1B4F8A", theme: "#2F4F4F", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        // ── Mobile / OS ──────────────────────────────────────────
        { name: "iOS",              accent: "#1E90FF", theme: "#F5F5F5", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Android",          accent: "#32C6A6", theme: "#1A1A1A", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Samsung",          accent: "#0047AB", theme: "#F5F5F5", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        // ── Gaming brands ────────────────────────────────────────
        { name: "Razer",            accent: "#00FF00", theme: "#0A0A0A", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        // ── Halo series ──────────────────────────────────────────
        { name: "Halo 1",           accent: "#339933", theme: "#383838", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Halo 2",           accent: "#007ACC", theme: "#1A1A1A", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Halo 3",           accent: "#339933", theme: "#1A1A1A", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Halo 4",           accent: "#007ACC", theme: "#290505", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Halo 5",           accent: "#007ACC", theme: "#383838", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false },
        { name: "Halo Infinite",    accent: "#339933", theme: "#0A1540", accentIdx: 0, accentOpacity: 1, gradAccentColor: false, gradAccentOpacity: false, themeIdx: 0, themeOpacity: 1, gradThemeColor: false, themeTransparency: false, themeTransparencyStrength: 0, gradThemeTransp: false, panelGradient: false }
    ]

    // ── User presets (runtime list — save/load via saveFunc) ──────
    property var userPresets: { var raw = api.memory.get("cfg.presets"); try { return (raw && raw !== "") ? JSON.parse(raw) : [] } catch(e) { return [] } }

    // Combined view list
    property var allPresets: {
        var list = []
        for (var i = 0; i < builtinPresets.length; i++) {
            var b = builtinPresets[i]
            list.push({
                name:                     b.name,
                accent:                   b.accent,
                theme:                    b.theme,
                accentIdx:                b.accentIdx                 !== undefined ? b.accentIdx                 : 0,
                accentOpacity:            b.accentOpacity             !== undefined ? b.accentOpacity             : 1,
                gradAccentColor:          b.gradAccentColor           !== undefined ? b.gradAccentColor           : false,
                gradAccentOpacity:        b.gradAccentOpacity         !== undefined ? b.gradAccentOpacity         : false,
                themeIdx:                 b.themeIdx                  !== undefined ? b.themeIdx                  : 0,
                themeOpacity:             b.themeOpacity              !== undefined ? b.themeOpacity              : 1,
                gradThemeColor:           b.gradThemeColor            !== undefined ? b.gradThemeColor            : false,
                themeTransparency:        b.themeTransparency         !== undefined ? b.themeTransparency         : false,
                themeTransparencyStrength:b.themeTransparencyStrength !== undefined ? b.themeTransparencyStrength : 0,
                gradThemeTransp:          b.gradThemeTransp           !== undefined ? b.gradThemeTransp           : false,
                panelGradient:            b.panelGradient             !== undefined ? b.panelGradient             : false,
                builtin: true, idx: i
            })
        }
        for (var j = 0; j < userPresets.length; j++) {
            var u = userPresets[j]
            list.push({
                name:                     u.name,
                accent:                   u.accent  || "",
                theme:                    u.theme   || "",
                accentIdx:                u.accentIdx                 || 0,
                accentOpacity:            u.accentOpacity             !== undefined ? u.accentOpacity             : 1,
                gradAccentColor:          u.gradAccentColor           || false,
                gradAccentOpacity:        u.gradAccentOpacity         || false,
                themeIdx:                 u.themeIdx                  || 0,
                themeOpacity:             u.themeOpacity              !== undefined ? u.themeOpacity              : 1,
                gradThemeColor:           u.gradThemeColor            || false,
                themeTransparency:        u.themeTransparency         || false,
                themeTransparencyStrength:u.themeTransparencyStrength || 0,
                gradThemeTransp:          u.gradThemeTransp           || false,
                panelGradient:            u.panelGradient             || false,
                builtin: false, idx: j
            })
        }
        return list
    }

    // ── Save helpers ──────────────────────────────────────────────
    function doSave(k, v) { if (saveFunc) saveFunc(k, v) }

    function saveUserPresets() {
        doSave("cfg.presets", JSON.stringify(userPresets))
    }

    // ⭐ OPTION‑B EXTENDED SAVE FUNCTION — INSERTED HERE ⭐
    function saveFullPresetState(presetName) {
        doSave("theme.presetName",   presetName)
        doSave("cfg.accentFill",     accentFillIdx.toString())
        doSave("cfg.themeFill",      themeFillIdx.toString())
        doSave("cfg.accentAlpha",    api.memory.get("cfg.accentAlpha"))
        doSave("cfg.ifaceAlpha",     api.memory.get("cfg.ifaceAlpha"))
        doSave("cfg.gradAccent",     api.memory.get("cfg.gradAccent"))
        doSave("cfg.gradAccentOp",   api.memory.get("cfg.gradAccentOp"))
        doSave("cfg.gradTheme",      api.memory.get("cfg.gradTheme"))
        doSave("cfg.gradThemeTr",    api.memory.get("cfg.gradThemeTr"))
        doSave("cfg.panelGradient",  api.memory.get("cfg.panelGradient"))
    }

    function addCurrentAsPreset(name) {
        var n = name.trim() === "" ? "Preset " + (userPresets.length + 1) : name.trim()
        var aHex = (accentColors.length > 0 && accentFillIdx < accentColors.length) ? accentColors[accentFillIdx].hex : ""
        var tHex = (themeColors.length  > 0 && themeFillIdx  < themeColors.length)  ? themeColors[themeFillIdx].hex   : ""
        var p = {
            name:                     n,
            accent:                   aHex,
            theme:                    tHex,
            accentIdx:                accentFillIdx,
            accentOpacity:            parseFloat(api.memory.get("cfg.accentAlpha"))      || 0,
            gradAccentColor:          api.memory.get("cfg.gradAccent")    === "true",
            gradAccentOpacity:        api.memory.get("cfg.gradAccentOp")  === "true",
            themeIdx:                 themeFillIdx,
            themeOpacity:             parseFloat(api.memory.get("cfg.ifaceAlpha"))       || 0,
            gradThemeColor:           api.memory.get("cfg.gradTheme")     === "true",
            themeTransparency:        api.memory.get("cfg.themeTransparency") === "true",
            themeTransparencyStrength:parseFloat(api.memory.get("cfg.themeTransparencyStrength")) || 0,
            gradThemeTransp:          api.memory.get("cfg.gradThemeTr")   === "true",
            panelGradient:            api.memory.get("cfg.panelGradient") === "true"
        }
        userPresets.push(p)
        userPresetsChanged()
        saveUserPresets()
    }

    function deleteUserPreset(idx) {
        userPresets.splice(idx, 1)
        userPresetsChanged()
        saveUserPresets()
    }

    function renameUserPreset(idx, newName) {
        if (idx >= 0 && idx < userPresets.length) {
            userPresets[idx].name = newName.trim()
            userPresetsChanged()
            saveUserPresets()
        }
    }

    onSelectedIdxChanged: doSave("cfg.selectedPreset", selectedIdx.toString())

    implicitWidth:  parent ? parent.width : 600
    implicitHeight: presetsCol.implicitHeight
    height:         presetsCol.implicitHeight

    // ── Rename input state ────────────────────────────────────────
    property int  renamingIdx: -1     // user preset index being renamed
    property bool addingNew:   false  // showing "new preset name" input

    Column {
        id: presetsCol
        width: parent.width
        spacing: 0

        // ── Header row ────────────────────────────────────────────
        Item {
            width: parent.width
            height: vpx(52)

            Rectangle {
                anchors.fill: parent; anchors.margins: vpx(2); radius: vpx(3)
                color: Qt.rgba(presetsRoot.accentColor.r, presetsRoot.accentColor.g, presetsRoot.accentColor.b, 0.12)
                border.color: presetsRoot.accentColor; border.width: vpx(1)
            }

            // "Color Presets" label
            StyledText {
                id: presetsLabel
                anchors.left: parent.left; anchors.leftMargin: vpx(14)
                anchors.verticalCenter: parent.verticalCenter
                text: "Color Presets"
                font.pixelSize: vpx(15); font.bold: true; color: "#FFFFFF"
                layer.enabled: false
            }

            // "Use Presets" checkbox  — pinned left of right zone
            Item {
                id: usePresetsCheck
                anchors.left: presetsLabel.right; anchors.leftMargin: vpx(16)
                anchors.verticalCenter: parent.verticalCenter
                width: vpx(120); height: vpx(24)

                Rectangle {
                    id: checkBox
                    width: vpx(20); height: vpx(20); radius: vpx(4)
                    anchors.verticalCenter: parent.verticalCenter
                    color: presetsRoot.usePresets ? presetsRoot.accentColor : "#222222"
                    border.color: presetsRoot.usePresets ? presetsRoot.accentColor : "#555555"
                    border.width: vpx(1)
                    Behavior on color { ColorAnimation { duration: 80 } }
                    StyledText {
                        anchors.centerIn: parent
                        text: presetsRoot.usePresets ? "✓" : ""
                        font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF"
                        layer.enabled: false
                    }
                }
                StyledText {
                    anchors.left: checkBox.right; anchors.leftMargin: vpx(7)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Use Presets"
                    font.pixelSize: vpx(12)
                    color: presetsRoot.usePresets ? "#FFFFFF" : "#888888"
                    layer.enabled: false
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        presetsRoot.usePresets = !presetsRoot.usePresets
                        presetsRoot.doSave("cfg.usePresets", presetsRoot.usePresets ? "true" : "false")
                    }
                }
            }

            // Currently active preset name (when usePresets on and something selected)
            StyledText {
                visible: presetsRoot.usePresets && presetsRoot.selectedIdx >= 0 && !presetsRoot.expanded
                anchors.left: usePresetsCheck.right; anchors.leftMargin: vpx(8)
                anchors.right: presetsBtns.left; anchors.rightMargin: vpx(8)
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    var list = presetsRoot.allPresets
                    return (presetsRoot.selectedIdx >= 0 && presetsRoot.selectedIdx < list.length)
                        ? "▶ " + list[presetsRoot.selectedIdx].name : ""
                }
                font.pixelSize: vpx(12); color: presetsRoot.accentColor
                elide: Text.ElideRight; layer.enabled: false
            }

            // RIGHT BUTTONS — pinned, never moves: [−] [+] [▼/▲]
            Item {
                id: presetsBtns
                anchors.right: parent.right; anchors.rightMargin: vpx(8)
                anchors.verticalCenter: parent.verticalCenter
                width: vpx(92); height: vpx(28)

                // ▼/▲ expand
                Rectangle {
                    id: presExpBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: vpx(28); height: vpx(24); radius: vpx(4)
                    color: presExpMA.containsMouse ? presetsRoot.accentColor : "#2AFFFFFF"
                    border.color: presetsRoot.accentColor; border.width: vpx(1)
                    Behavior on color { ColorAnimation { duration: 80 } }
                    StyledText {
                        anchors.centerIn: parent
                        text: presetsRoot.expanded ? "▲" : "▼"
                        font.pixelSize: vpx(11); font.bold: true; layer.enabled: false
                    }
                    MouseArea {
                        id: presExpMA; anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onClicked: presetsRoot.expanded = !presetsRoot.expanded
                    }
                }

                // [+] save current colors as new preset
                Rectangle {
                    id: addBtn
                    anchors.right: presExpBtn.left; anchors.rightMargin: vpx(4)
                    anchors.verticalCenter: parent.verticalCenter
                    width: vpx(24); height: vpx(24); radius: vpx(4)
                    color: addMA.containsMouse ? presetsRoot.accentColor : "#2AFFFFFF"
                    border.color: presetsRoot.accentColor; border.width: vpx(1)
                    Behavior on color { ColorAnimation { duration: 80 } }
                    StyledText { anchors.centerIn: parent; text: "+"; font.pixelSize: vpx(14); font.bold: true; layer.enabled: false }
                    MouseArea {
                        id: addMA; anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onClicked: {
                            presetsRoot.expanded  = true
                            presetsRoot.addingNew = true
                            presetsRoot.renamingIdx = -1
                        }
                    }
                }

                // [−] delete selected user preset
                Rectangle {
                    id: delSelBtn
                    anchors.right: addBtn.left; anchors.rightMargin: vpx(4)
                    anchors.verticalCenter: parent.verticalCenter
                    width: vpx(24); height: vpx(24); radius: vpx(4)
                    property bool canDelete: {
                        var idx = presetsRoot.selectedIdx - presetsRoot.builtinPresets.length
                        return idx >= 0 && idx < presetsRoot.userPresets.length
                    }
                    color: delSelMA.containsMouse && canDelete ? "#AA440000" : "#22FFFFFF"
                    border.color: delSelMA.containsMouse && canDelete ? "#880000" : "#33FFFFFF"
                    border.width: vpx(1)
                    Behavior on color { ColorAnimation { duration: 80 } }
                    StyledText { anchors.centerIn: parent; text: "−"; font.pixelSize: vpx(14); font.bold: true; color: delSelBtn.canDelete ? (delSelMA.containsMouse ? "#FF6666" : "#AAAAAA") : "#444444"; layer.enabled: false }
                    MouseArea {
                        id: delSelMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!delSelBtn.canDelete) return
                            var userIdx = presetsRoot.selectedIdx - presetsRoot.builtinPresets.length
                            presetsRoot.selectedIdx = -1
                            presetsRoot.deleteUserPreset(userIdx)
                        }
                    }
                }
            }
        }

        // ── Expanded panel ────────────────────────────────────────
        Item {
            width: parent.width
            height: presetsRoot.expanded ? expandedContent.implicitHeight + vpx(16) : 0
            clip: true
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.fill: parent; anchors.margins: vpx(3); radius: vpx(4)
                color: "#14FFFFFF"
                border.color: Qt.rgba(presetsRoot.accentColor.r, presetsRoot.accentColor.g, presetsRoot.accentColor.b, 0.22)
                border.width: vpx(1)
            }

            Column {
                id: expandedContent
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.margins: vpx(8)
                spacing: vpx(4)

                // ── Section heading: My Presets ────────────────────
                StyledText {
                    leftPadding: vpx(8)
                    text: "My Presets"
                    font.pixelSize: vpx(11); color: "#888888"
                    layer.enabled: false
                }

                // User presets
                Flow {
                    id: userFlow
                    width: parent.width
                    spacing: vpx(3)
                    Repeater {
                        model: presetsRoot.userPresets.length
                        delegate: presetRowUser
                    }
                }

                // Empty state
                StyledText {
                    visible: presetsRoot.userPresets.length === 0 && !presetsRoot.addingNew
                    leftPadding: vpx(14)
                    text: "No saved presets yet. Press + to save current colors."
                    font.pixelSize: vpx(11); color: "#666666"
                    layer.enabled: false
                }

                // ── "New preset" input row ─────────────────────────
                Item {
                    id: newPresetRow
                    visible: presetsRoot.addingNew
                    width: parent.width
                    height: vpx(40)
                    onVisibleChanged: {
                        if (visible) {
                            newNameInput.text = "My Preset"
                            newNameInput.forceActiveFocus()
                            newNameInput.selectAll()
                        }
                    }

                    Rectangle {
                        anchors.fill: parent; anchors.margins: vpx(2); radius: vpx(4)
                        color: "#1EFFFFFF"
                        border.color: presetsRoot.accentColor; border.width: vpx(1)
                    }

                    // Accent swatch
                    Rectangle {
                        id: newAccentSwatch
                        anchors.left: parent.left; anchors.leftMargin: vpx(10)
                        anchors.verticalCenter: parent.verticalCenter
                        width: vpx(22); height: vpx(22); radius: vpx(4)
                        color: presetsRoot.accentColor
                        border.color: "#55FFFFFF"; border.width: vpx(1)
                    }
                    StyledText {
                        anchors.left: newAccentSwatch.right; anchors.leftMargin: vpx(4)
                        anchors.verticalCenter: parent.verticalCenter
                        text: "A"; font.pixelSize: vpx(9); color: "#888888"; layer.enabled: false
                    }

                    // Text input for name
                    Rectangle {
                        id: newNameField
                        anchors.left: newAccentSwatch.right; anchors.leftMargin: vpx(18)
                        anchors.right: newCancelBtn.left; anchors.rightMargin: vpx(6)
                        anchors.verticalCenter: parent.verticalCenter
                        height: vpx(26); radius: vpx(4)
                        color: "#33FFFFFF"
                        border.color: presetsRoot.accentColor; border.width: vpx(1)

                        TextInput {
                            id: newNameInput
                            anchors.fill: parent; anchors.margins: vpx(6)
                            color: "#FFFFFF"; font.pixelSize: vpx(12)
                            selectByMouse: true
                            text: "My Preset"
                            selectionColor: Qt.rgba(presetsRoot.accentColor.r, presetsRoot.accentColor.g, presetsRoot.accentColor.b, 0.5)
                            onAccepted: {
                                presetsRoot.addCurrentAsPreset(text)
                                presetsRoot.addingNew = false
                                text = "My Preset"
                            }
                            Keys.onEscapePressed: { presetsRoot.addingNew = false; text = "My Preset" }
                        }
                    }

                    // Cancel button
                    Rectangle {
                        id: newCancelBtn
                        anchors.right: newSaveBtn.left; anchors.rightMargin: vpx(4)
                        anchors.verticalCenter: parent.verticalCenter
                        width: vpx(24); height: vpx(24); radius: vpx(4)
                        color: newCancelMA.containsMouse ? "#AA333333" : "#33FFFFFF"
                        border.color: "#555555"; border.width: vpx(1)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        StyledText { anchors.centerIn: parent; text: "✕"; font.pixelSize: vpx(11); color: "#AAAAAA"; layer.enabled: false }
                        MouseArea {
                            id: newCancelMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { presetsRoot.addingNew = false; newNameInput.text = "My Preset" }
                        }
                    }

                    // Save button
                    Rectangle {
                        id: newSaveBtn
                        anchors.right: parent.right; anchors.rightMargin: vpx(8)
                        anchors.verticalCenter: parent.verticalCenter
                        width: vpx(44); height: vpx(24); radius: vpx(4)
                        color: newSaveMA.containsMouse ? presetsRoot.accentColor : "#2AFFFFFF"
                        border.color: presetsRoot.accentColor; border.width: vpx(1)
                        Behavior on color { ColorAnimation { duration: 80 } }
                        StyledText { anchors.centerIn: parent; text: "Save"; font.pixelSize: vpx(10); font.bold: true; layer.enabled: false }
                        MouseArea {
                            id: newSaveMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                presetsRoot.addCurrentAsPreset(newNameInput.text)
                                presetsRoot.addingNew = false
                                newNameInput.text = "My Preset"
                            }
                        }
                    }
                }

                Item { width: 1; height: vpx(4) }  // bottom padding

                // ── Divider ───────────────────────────────────────
                Rectangle {
                    width: parent.width - vpx(16); height: vpx(1)
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#33FFFFFF"
                }

                // ── Section heading: Built-in presets ─────────────
                StyledText {
                    leftPadding: vpx(8)
                    text: "Built-in Presets"
                    font.pixelSize: vpx(11); color: "#888888"
                    layer.enabled: false
                }

                // Built-in presets
                Flow {
                    id: builtinFlow
                    width: parent.width
                    spacing: vpx(3)
                    Repeater {
                        model: presetsRoot.builtinPresets.length
                        delegate: presetRowBuiltin
                    }
                }

                Item { width: 1; height: vpx(4) }  // bottom padding
            }
        }
    }

    // ── Delegate: built-in preset row ─────────────────────────────
    Component {
        id: presetRowBuiltin
        Item {
            property var  pdata:       presetsRoot.builtinPresets[index]
            property bool isSel:       presetsRoot.usePresets && presetsRoot.selectedIdx === index
            property var  adata:       presetsRoot.accentDataForPreset(pdata)
            property var  tdata:       presetsRoot.themeDataForPreset(pdata)
            property bool hasExtended: pdata ? (pdata.accentGradient || pdata.themeGradient || pdata.themeTransparency || pdata.panelGradient) : false

            width:  presetsRoot.horizontalView ? vpx(200) : parent.width
            height: presetsRoot.horizontalView ? vpx(260) : vpx(52)

            Rectangle {
                anchors.fill: parent; anchors.margins: vpx(2); radius: vpx(5)
                color: rowMA.containsMouse ? "#1EFFFFFF" : (isSel ? "#1CFFFFFF" : "transparent")
                border.color: isSel ? presetsRoot.accentColor : (rowMA.containsMouse ? "#44FFFFFF" : "#22FFFFFF")
                border.width: vpx(1)
                Behavior on color { ColorAnimation { duration: 80 } }
            }

            // ── GRID layout ───────────────────────────────────────
            Column {
                visible: presetsRoot.horizontalView
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.bottom: parent.bottom
                anchors.margins: vpx(6)
                spacing: vpx(2)

                // Title row — name only
                Row {
                    width: parent.width; spacing: vpx(5)
                    StyledText { text: isSel ? "▶" : ""; font.pixelSize: vpx(9); color: presetsRoot.accentColor; width: vpx(10); anchors.verticalCenter: parent.verticalCenter; layer.enabled: false }
                    StyledText { text: pdata.name; font.pixelSize: vpx(11); font.bold: isSel; color: isSel ? "#FFFFFF" : "#CCCCCC"; elide: Text.ElideRight; width: parent.width - vpx(10) - vpx(5); anchors.verticalCenter: parent.verticalCenter; layer.enabled: false }
                }
                // Accent section
                Column {
                    width: parent.width
                    spacing: vpx(1)
                    Row { spacing: vpx(6)
                        Item { width: vpx(4); height: 1 }
                        Rectangle { width: vpx(20); height: vpx(20); radius: vpx(3); color: pdata.accent; border.color: "#55FFFFFF"; border.width: vpx(1); anchors.verticalCenter: parent.verticalCenter }
                        StyledText { text: adata.name; font.pixelSize: vpx(11); color: pdata.accent; layer.enabled: false; elide: Text.ElideRight; width: vpx(140); anchors.verticalCenter: parent.verticalCenter }
                    }
                    Row { Item { width: vpx(30); height: 1 }
                        StyledText { text: pdata.accent.toUpperCase(); font.pixelSize: vpx(8); color: "#666666"; layer.enabled: false }
                    }
                    Row { Item { width: vpx(30); height: 1 }
                        StyledText { text: "Index: #" + adata.num; font.pixelSize: vpx(8); color: "#666666"; layer.enabled: false }
                    }
                    Row { Item { width: vpx(30); height: 1 }
                        StyledText { text: "Accent Opacity: " + Math.round(pdata.accentOpacity * 100) + "%"; font.pixelSize: vpx(8); color: "#888888"; layer.enabled: false }
                    }
                    Row { Item { width: vpx(30); height: 1 }
                        StyledText { text: "Accent Color Gradient: " + (pdata.gradAccentColor ? "On" : "None"); font.pixelSize: vpx(8); color: pdata.gradAccentColor ? "#8888AA" : "#444444"; layer.enabled: false }
                    }
                    Row { Item { width: vpx(30); height: 1 }
                        StyledText { text: "Accent Opacity Gradient: " + (pdata.gradAccentOpacity ? "On" : "None"); font.pixelSize: vpx(8); color: pdata.gradAccentOpacity ? "#8888AA" : "#444444"; layer.enabled: false }
                    }
                }
                // Theme section
                Column {
                    width: parent.width
                    spacing: vpx(1)
                    Row { spacing: vpx(6)
                        Item { width: vpx(4); height: 1 }
                        Rectangle { width: vpx(20); height: vpx(20); radius: vpx(3); color: pdata.theme; border.color: "#33FFFFFF"; border.width: vpx(1); anchors.verticalCenter: parent.verticalCenter }
                        StyledText { text: tdata.name; font.pixelSize: vpx(11); color: (pdata.theme === "#FFFFFF" || pdata.theme === "#F5F5F5") ? "#AAAAAA" : pdata.theme; layer.enabled: false; elide: Text.ElideRight; width: vpx(140); anchors.verticalCenter: parent.verticalCenter }
                    }
                    Row { Item { width: vpx(30); height: 1 }
                        StyledText { text: pdata.theme.toUpperCase(); font.pixelSize: vpx(8); color: "#666666"; layer.enabled: false }
                    }
                    Row { Item { width: vpx(30); height: 1 }
                        StyledText { text: "Index: #" + tdata.num; font.pixelSize: vpx(8); color: "#666666"; layer.enabled: false }
                    }
                    Row { Item { width: vpx(30); height: 1 }
                        StyledText { text: "Theme Opacity: " + Math.round(pdata.themeOpacity * 100) + "%"; font.pixelSize: vpx(8); color: "#888888"; layer.enabled: false }
                    }
                    Row { Item { width: vpx(30); height: 1 }
                        StyledText { text: "Theme Color Gradient: " + (pdata.gradThemeColor ? "On" : "None"); font.pixelSize: vpx(8); color: pdata.gradThemeColor ? "#8888AA" : "#444444"; layer.enabled: false }
                    }
                    Row { Item { width: vpx(30); height: 1 }
                        StyledText { text: "Theme Transparency: " + (pdata.themeTransparency ? Math.round(pdata.themeTransparencyStrength * 100) + "%" : "None"); font.pixelSize: vpx(8); color: pdata.themeTransparency ? "#88AAAA" : "#444444"; layer.enabled: false }
                    }
                    Row { Item { width: vpx(30); height: 1 }
                        StyledText { text: "Theme Transp. Gradient: " + (pdata.gradThemeTransp ? "On" : "None"); font.pixelSize: vpx(8); color: pdata.gradThemeTransp ? "#8888AA" : "#444444"; layer.enabled: false }
                    }
                    Row { Item { width: vpx(30); height: 1 }
                        StyledText { text: "Panel Gradient: " + (pdata.panelGradient ? "On" : "None"); font.pixelSize: vpx(8); color: pdata.panelGradient ? "#7788AA" : "#444444"; layer.enabled: false }
                    }
                }
            }

            // ── LIST layout ───────────────────────────────────────
            Item {
                visible: !presetsRoot.horizontalView
                anchors.fill: parent

                Rectangle {
                    visible: isSel
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: vpx(3); radius: vpx(2); color: presetsRoot.accentColor
                }

                Column {
                    anchors.left: parent.left; anchors.leftMargin: vpx(14)
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.horizontalCenter
                    spacing: vpx(1)
                    Row {
                        spacing: vpx(5)
                        StyledText { text: isSel ? "▶" : " "; font.pixelSize: vpx(9); color: presetsRoot.accentColor; layer.enabled: false }
                        Rectangle { width: vpx(18); height: vpx(18); radius: vpx(3); color: pdata.accent; border.color: "#44FFFFFF"; border.width: vpx(1) }
                        Column {
                            spacing: vpx(1)
                            StyledText { text: adata.name; font.pixelSize: vpx(11); font.bold: isSel; color: isSel ? "#FFFFFF" : "#CCCCCC"; elide: Text.ElideRight; width: vpx(90); layer.enabled: false }
                            Row {
                                spacing: vpx(3)
                                StyledText { text: "#" + adata.num + " " + pdata.accent.toUpperCase(); font.pixelSize: vpx(8); color: "#666666"; layer.enabled: false }
                                StyledText { text: "  Opacity " + Math.round(pdata.accentOpacity * 100) + "%"; font.pixelSize: vpx(8); color: "#777777"; layer.enabled: false }
                                StyledText { text: "  Gradient: " + (pdata.accentGradient ? Math.round(pdata.accentGradientStrength * 100) + "%" : "None"); font.pixelSize: vpx(8); color: pdata.accentGradient ? "#8888AA" : "#444444"; layer.enabled: false }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: vpx(1); height: parent.height - vpx(12); color: "#22FFFFFF"
                }

                Column {
                    anchors.left: parent.horizontalCenter; anchors.leftMargin: vpx(8)
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right; anchors.rightMargin: vpx(8)
                    spacing: vpx(1)
                    Row {
                        spacing: vpx(5)
                        Rectangle { width: vpx(18); height: vpx(18); radius: vpx(3); color: pdata.theme; border.color: "#33FFFFFF"; border.width: vpx(1) }
                        Column {
                            spacing: vpx(1)
                            StyledText { text: tdata.name; font.pixelSize: vpx(11); color: "#BBBBBB"; elide: Text.ElideRight; width: vpx(90); layer.enabled: false }
                            Row {
                                spacing: vpx(3)
                                StyledText { text: "#" + tdata.num + " " + pdata.theme.toUpperCase(); font.pixelSize: vpx(8); color: "#666666"; layer.enabled: false }
                                StyledText { text: "  Opacity " + Math.round(pdata.themeOpacity * 100) + "%"; font.pixelSize: vpx(8); color: "#777777"; layer.enabled: false }
                                StyledText { text: "  Gradient: " + (pdata.themeGradient ? "On" : "None"); font.pixelSize: vpx(8); color: pdata.themeGradient ? "#8888AA" : "#444444"; layer.enabled: false }
                                StyledText { text: "  Transparency: " + (pdata.themeTransparency ? Math.round(pdata.themeTransparencyStrength * 100) + "%" : "None"); font.pixelSize: vpx(8); color: pdata.themeTransparency ? "#88AAAA" : "#444444"; layer.enabled: false }
                                StyledText { text: "  Panel Gradient: " + (pdata.panelGradient ? "On" : "None"); font.pixelSize: vpx(8); color: pdata.panelGradient ? "#7788AA" : "#444444"; layer.enabled: false }
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: rowMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var p = presetsRoot.allPresets[index]
                    var aIdx = presetsRoot.findColorIdx(presetsRoot.accentColors, p.accent)
                    var tIdx = presetsRoot.findColorIdx(presetsRoot.themeColors,  p.theme)
                    presetsRoot.lastAppliedPreset = p
                    presetsRoot.selectedIdx = index
                    presetsRoot.presetApplied(aIdx, tIdx)
                    presetsRoot.doSave("cfg.activePreset", index.toString())
                    if (presetsRoot.usePresets) presetsRoot.saveFullPresetState(p.name)
                }
            }
        }
    }

    // ── Delegate: user preset row ──────────────────────────────────
    Component {
        id: presetRowUser
        Item {
            property var  pdata:      presetsRoot.userPresets[index]
            property int  gIdx:       presetsRoot.builtinPresets.length + index
            property bool isSel:      presetsRoot.usePresets && presetsRoot.selectedIdx === gIdx
            property bool isRenaming: presetsRoot.renamingIdx === index
            property var  adata:      (pdata && presetsRoot.accentColors.length > 0) ? presetsRoot.accentColors[Math.min(pdata.accentIdx, presetsRoot.accentColors.length - 1)] : { name: "", num: "0", hex: "#5D9809" }
            property var  tdata:      (pdata && presetsRoot.themeColors.length  > 0) ? presetsRoot.themeColors [Math.min(pdata.themeIdx,  presetsRoot.themeColors.length  - 1)] : { name: "", num: "0", hex: "#555555" }
            // true only when at least one extended setting was saved
            property bool hasExtended: pdata ? (pdata.accentGradient || pdata.themeGradient || pdata.themeTransparency || pdata.panelGradient) : false

            width:  presetsRoot.horizontalView ? vpx(200) : parent.width
            height: isRenaming ? vpx(48) : (presetsRoot.horizontalView ? vpx(260) : vpx(52))

            Rectangle {
                anchors.fill: parent; anchors.margins: vpx(2); radius: vpx(5)
                color: (uRowMA.containsMouse && !isRenaming) ? "#1EFFFFFF" : (isSel ? "#1CFFFFFF" : "transparent")
                border.color: isSel ? presetsRoot.accentColor : (isRenaming ? presetsRoot.accentColor : "#22FFFFFF")
                border.width: vpx(1)
                Behavior on color { ColorAnimation { duration: 80 } }
            }

            // Normal display
            Item {
                visible: !isRenaming
                anchors.fill: parent

                // GRID
                Column {
                    visible: presetsRoot.horizontalView
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: parent.top; anchors.bottom: parent.bottom
                    anchors.margins: vpx(6)
                    spacing: vpx(2)

                    // Title row — name only
                    Row {
                        width: parent.width; spacing: vpx(5)
                        StyledText { text: isSel ? "▶" : ""; font.pixelSize: vpx(9); color: presetsRoot.accentColor; width: vpx(10); anchors.verticalCenter: parent.verticalCenter; layer.enabled: false }
                        StyledText { text: pdata ? pdata.name : ""; font.pixelSize: vpx(11); font.bold: isSel; color: isSel ? "#FFFFFF" : "#CCCCCC"; elide: Text.ElideRight; width: parent.width - vpx(10) - vpx(5); anchors.verticalCenter: parent.verticalCenter; layer.enabled: false }
                    }
                    // Accent section
                    Column {
                        width: parent.width
                        spacing: vpx(1)
                        Row { spacing: vpx(6)
                            Item { width: vpx(4); height: 1 }
                            Rectangle { width: vpx(20); height: vpx(20); radius: vpx(3); color: adata.hex; border.color: "#55FFFFFF"; border.width: vpx(1); anchors.verticalCenter: parent.verticalCenter }
                            StyledText { text: adata.name; font.pixelSize: vpx(11); color: adata.hex; elide: Text.ElideRight; width: vpx(140); anchors.verticalCenter: parent.verticalCenter; layer.enabled: false }
                        }
                        Row { Item { width: vpx(30); height: 1 }
                            StyledText { text: adata.hex.toUpperCase(); font.pixelSize: vpx(8); color: "#666666"; layer.enabled: false }
                        }
                        Row { Item { width: vpx(30); height: 1 }
                            StyledText { text: "Index: #" + adata.num; font.pixelSize: vpx(8); color: "#666666"; layer.enabled: false }
                        }
                        Row { Item { width: vpx(30); height: 1 }
                            StyledText { text: "Accent Opacity: " + Math.round((pdata && pdata.accentOpacity !== undefined ? pdata.accentOpacity : 1) * 100) + "%"; font.pixelSize: vpx(8); color: "#888888"; layer.enabled: false }
                        }
                        Row { Item { width: vpx(30); height: 1 }
                            StyledText { text: "Accent Color Gradient: " + (pdata && pdata.gradAccentColor ? "On" : "None"); font.pixelSize: vpx(8); color: (pdata && pdata.gradAccentColor) ? "#8888AA" : "#444444"; layer.enabled: false }
                        }
                        Row { Item { width: vpx(30); height: 1 }
                            StyledText { text: "Accent Opacity Gradient: " + (pdata && pdata.gradAccentOpacity ? "On" : "None"); font.pixelSize: vpx(8); color: (pdata && pdata.gradAccentOpacity) ? "#8888AA" : "#444444"; layer.enabled: false }
                        }
                    }
                    // Theme section
                    Column {
                        width: parent.width
                        spacing: vpx(1)
                        Row { spacing: vpx(6)
                            Item { width: vpx(4); height: 1 }
                            Rectangle { width: vpx(20); height: vpx(20); radius: vpx(3); color: tdata.hex; border.color: "#33FFFFFF"; border.width: vpx(1); anchors.verticalCenter: parent.verticalCenter }
                            StyledText { text: tdata.name; font.pixelSize: vpx(11); color: (tdata.hex === "#FFFFFF" || tdata.hex === "#F5F5F5") ? "#AAAAAA" : tdata.hex; elide: Text.ElideRight; width: vpx(140); anchors.verticalCenter: parent.verticalCenter; layer.enabled: false }
                        }
                        Row { Item { width: vpx(30); height: 1 }
                            StyledText { text: tdata.hex.toUpperCase(); font.pixelSize: vpx(8); color: "#666666"; layer.enabled: false }
                        }
                        Row { Item { width: vpx(30); height: 1 }
                            StyledText { text: "Index: #" + tdata.num; font.pixelSize: vpx(8); color: "#666666"; layer.enabled: false }
                        }
                        Row { Item { width: vpx(30); height: 1 }
                            StyledText { text: "Theme Opacity: " + Math.round((pdata && pdata.themeOpacity !== undefined ? pdata.themeOpacity : 1) * 100) + "%"; font.pixelSize: vpx(8); color: "#888888"; layer.enabled: false }
                        }
                        Row { Item { width: vpx(30); height: 1 }
                            StyledText { text: "Theme Color Gradient: " + (pdata && pdata.gradThemeColor ? "On" : "None"); font.pixelSize: vpx(8); color: (pdata && pdata.gradThemeColor) ? "#8888AA" : "#444444"; layer.enabled: false }
                        }
                        Row { Item { width: vpx(30); height: 1 }
                            StyledText { text: "Theme Transparency: " + (pdata && pdata.themeTransparency ? Math.round(pdata.themeTransparencyStrength * 100) + "%" : "None"); font.pixelSize: vpx(8); color: (pdata && pdata.themeTransparency) ? "#88AAAA" : "#444444"; layer.enabled: false }
                        }
                        Row { Item { width: vpx(30); height: 1 }
                            StyledText { text: "Theme Transp. Gradient: " + (pdata && pdata.gradThemeTransp ? "On" : "None"); font.pixelSize: vpx(8); color: (pdata && pdata.gradThemeTransp) ? "#8888AA" : "#444444"; layer.enabled: false }
                        }
                        Row { Item { width: vpx(30); height: 1 }
                            StyledText { text: "Panel Gradient: " + (pdata && pdata.panelGradient ? "On" : "None"); font.pixelSize: vpx(8); color: (pdata && pdata.panelGradient) ? "#7788AA" : "#444444"; layer.enabled: false }
                        }
                    }
                }

                // LIST
                Item {
                    visible: !presetsRoot.horizontalView
                    anchors.fill: parent

                    Rectangle {
                        visible: isSel
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        width: vpx(3); radius: vpx(2); color: presetsRoot.accentColor
                    }

                    Column {
                        anchors.left: parent.left; anchors.leftMargin: vpx(14)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.horizontalCenter
                        spacing: vpx(1)
                        Row {
                            spacing: vpx(5)
                            StyledText { text: isSel ? "▶" : " "; font.pixelSize: vpx(9); color: presetsRoot.accentColor; layer.enabled: false }
                            Rectangle { width: vpx(18); height: vpx(18); radius: vpx(3); color: adata.hex; border.color: "#44FFFFFF"; border.width: vpx(1) }
                            Column {
                                spacing: vpx(1)
                                StyledText { text: adata.name; font.pixelSize: vpx(11); font.bold: isSel; color: isSel ? "#FFFFFF" : "#CCCCCC"; elide: Text.ElideRight; width: vpx(90); layer.enabled: false }
                                Row {
                                    spacing: vpx(3)
                                    StyledText { text: "#" + adata.num + " " + adata.hex.toUpperCase(); font.pixelSize: vpx(8); color: "#666666"; layer.enabled: false }
                                    StyledText { text: "  Opacity " + Math.round((pdata && pdata.accentOpacity !== undefined ? pdata.accentOpacity : 1) * 100) + "%"; font.pixelSize: vpx(8); color: "#777777"; layer.enabled: false }
                                    StyledText { text: "  Gradient: " + (pdata && pdata.accentGradient ? Math.round(pdata.accentGradientStrength * 100) + "%" : "None"); font.pixelSize: vpx(8); color: (pdata && pdata.accentGradient) ? "#8888AA" : "#444444"; layer.enabled: false }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: vpx(1); height: parent.height - vpx(12); color: "#22FFFFFF"
                    }

                    Column {
                        anchors.left: parent.horizontalCenter; anchors.leftMargin: vpx(8)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: uActionBtns.left; anchors.rightMargin: vpx(4)
                        spacing: vpx(1)
                        Row {
                            spacing: vpx(5)
                            Rectangle { width: vpx(18); height: vpx(18); radius: vpx(3); color: tdata.hex; border.color: "#33FFFFFF"; border.width: vpx(1) }
                            Column {
                                spacing: vpx(1)
                                StyledText { text: tdata.name; font.pixelSize: vpx(11); color: "#BBBBBB"; elide: Text.ElideRight; width: vpx(90); layer.enabled: false }
                                Row {
                                    spacing: vpx(3)
                                    StyledText { text: "Opacity " + Math.round((pdata && pdata.themeOpacity !== undefined ? pdata.themeOpacity : 1) * 100) + "%"; font.pixelSize: vpx(8); color: "#777777"; layer.enabled: false }
                                    StyledText { text: "  Gradient: " + (pdata && pdata.themeGradient ? "On" : "None"); font.pixelSize: vpx(8); color: (pdata && pdata.themeGradient) ? "#8888AA" : "#444444"; layer.enabled: false }
                                    StyledText { text: "  Transparency: " + (pdata && pdata.themeTransparency ? Math.round(pdata.themeTransparencyStrength * 100) + "%" : "None"); font.pixelSize: vpx(8); color: (pdata && pdata.themeTransparency) ? "#88AAAA" : "#444444"; layer.enabled: false }
                                    StyledText { text: "  Panel Gradient: " + (pdata && pdata.panelGradient ? "On" : "None"); font.pixelSize: vpx(8); color: (pdata && pdata.panelGradient) ? "#7788AA" : "#444444"; layer.enabled: false }
                                }
                            }
                        }
                    }

                    Row {
                        id: uActionBtns
                        anchors.right: parent.right; anchors.rightMargin: vpx(6)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: vpx(4)

                        Rectangle {
                            width: vpx(28); height: vpx(28); radius: vpx(4)
                            color: renMA.containsMouse ? "#55FFFFFF" : "#22FFFFFF"
                            border.color: "#33FFFFFF"; border.width: vpx(1)
                            Behavior on color { ColorAnimation { duration: 80 } }
                            StyledText { anchors.centerIn: parent; text: "✎"; font.pixelSize: vpx(12); color: "#AAAAAA"; layer.enabled: false }
                            MouseArea { id: renMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { presetsRoot.renamingIdx = index; presetsRoot.addingNew = false }
                            }
                        }

                        Rectangle {
                            width: vpx(28); height: vpx(28); radius: vpx(4)
                            color: delMA.containsMouse ? "#AA440000" : "#22FFFFFF"
                            border.color: delMA.containsMouse ? "#880000" : "#33FFFFFF"; border.width: vpx(1)
                            Behavior on color { ColorAnimation { duration: 80 } }
                            StyledText { anchors.centerIn: parent; text: "✕"; font.pixelSize: vpx(11); color: delMA.containsMouse ? "#FF6666" : "#888888"; layer.enabled: false }
                            MouseArea { id: delMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: presetsRoot.deleteUserPreset(index)
                            }
                        }
                    }
                }
            }

            // Rename input
            Item {
                visible: isRenaming
                anchors.fill: parent; anchors.margins: vpx(4)
                onVisibleChanged: {
                    if (visible) {
                        renInput.forceActiveFocus()
                        renInput.selectAll()
                    }
                }

                Rectangle {
                    id: renField
                    anchors.left: parent.left; anchors.right: renCancelBtn.left
                    anchors.rightMargin: vpx(4); anchors.verticalCenter: parent.verticalCenter
                    height: vpx(28); radius: vpx(4)
                    color: "#33FFFFFF"; border.color: presetsRoot.accentColor; border.width: vpx(1)
                    TextInput {
                        id: renInput
                        anchors.fill: parent; anchors.margins: vpx(6)
                        color: "#FFFFFF"; font.pixelSize: vpx(12); selectByMouse: true
                        text: pdata ? pdata.name : ""
                        selectionColor: Qt.rgba(presetsRoot.accentColor.r, presetsRoot.accentColor.g, presetsRoot.accentColor.b, 0.5)
                        onAccepted: { presetsRoot.renameUserPreset(index, renInput.text); presetsRoot.renamingIdx = -1 }
                        Keys.onEscapePressed: presetsRoot.renamingIdx = -1
                    }
                }

                Rectangle {
                    id: renCancelBtn
                    anchors.right: renSaveBtn.left; anchors.rightMargin: vpx(4)
                    anchors.verticalCenter: parent.verticalCenter
                    width: vpx(24); height: vpx(24); radius: vpx(4)
                    color: rcMA.containsMouse ? "#AA333333" : "#22FFFFFF"
                    border.color: "#555555"; border.width: vpx(1)
                    Behavior on color { ColorAnimation { duration: 80 } }
                    StyledText { anchors.centerIn: parent; text: "✕"; font.pixelSize: vpx(11); color: "#AAAAAA"; layer.enabled: false }
                    MouseArea { id: rcMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: presetsRoot.renamingIdx = -1
                    }
                }

                Rectangle {
                    id: renSaveBtn
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    width: vpx(44); height: vpx(24); radius: vpx(4)
                    color: rsMA.containsMouse ? presetsRoot.accentColor : "#2AFFFFFF"
                    border.color: presetsRoot.accentColor; border.width: vpx(1)
                    Behavior on color { ColorAnimation { duration: 80 } }
                    StyledText { anchors.centerIn: parent; text: "Save"; font.pixelSize: vpx(10); font.bold: true; layer.enabled: false }
                    MouseArea { id: rsMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { presetsRoot.renameUserPreset(index, renInput.text); presetsRoot.renamingIdx = -1 }
                    }
                }
            }

            MouseArea {
                id: uRowMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                enabled: !isRenaming
                onClicked: {
                    if (!pdata) return
                    var p = presetsRoot.allPresets[gIdx]
                    var aIdx = (p.accent && p.accent !== "")
                        ? presetsRoot.findColorIdx(presetsRoot.accentColors, p.accent)
                        : p.accentIdx
                    var tIdx = (p.theme && p.theme !== "")
                        ? presetsRoot.findColorIdx(presetsRoot.themeColors, p.theme)
                        : p.themeIdx
                    presetsRoot.lastAppliedPreset = p
                    presetsRoot.selectedIdx = gIdx
                    presetsRoot.presetApplied(aIdx, tIdx)
                    presetsRoot.doSave("cfg.activePreset", gIdx.toString())
                    if (presetsRoot.usePresets) presetsRoot.saveFullPresetState(p.name)
                }
            }
        }
    }

}