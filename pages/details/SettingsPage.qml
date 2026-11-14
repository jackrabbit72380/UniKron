import QtQuick 2.8
import QtQuick.Window 2.0
import QtGraphicalEffects 1.12
import QtQml 2.15
import QtQuick.Layouts 1.1
import "../../js/enums.mjs" as Enums
import "../../components"

// ════════════════════════════════════════════════════════════════════
// SettingsPage.qml  — fixed for Qt 5.9 / QtQuick 2.8
// FIX: All `readonly property var` arrays of objects moved to plain
//      `property var` so Qt 5.9 does not silently fail to parse them.
// ════════════════════════════════════════════════════════════════════

Item {
  id: root
  focus: true
  Keys.priority: Keys.BeforeItem

  // ── Memory helpers ────────────────────────────────────────────────
  function mem(key, def) {
    var v = api.memory.get(key)
    return (v !== undefined && v !== null && v !== "") ? v : def
  }
  function save(key, val) { api.memory.set(key, val) }

  // ── Single ticking clock ─────────────────────────────────────────
  Timer {
    id: clockTick
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: {
      clockTimeString = Qt.formatTime(new Date(), clockFormat24 ? "HH:mm:ss" : "hh:mm:ss AP")
    }
  }
  property string clockTimeString: Qt.formatTime(new Date(), "hh:mm:ss AP")

  // ══ SETTINGS PROPERTIES ═══════════════════════════════════════════

  // Display
  property bool   fullscreen:            mem("cfg.fullscreen",    "true")  === "true"
  property int    brightness:            parseInt(mem("cfg.brightness",    "60"))
  property bool   smoothScaling:         mem("cfg.smoothScaling", "true")  === "true"
  property int    bgTypeIdx:             parseInt(mem("cfg.bgType",        "0"))

  // FIX: was `readonly property var bgTypeLabels: [...]` — plain property var is safe in Qt 5.9
  property var bgTypeLabels: ["Theme Wallpaper", "Skin Background", "Video"]

  // ── Video / Movies paths ──────────────────────────────────────────
  property string bgVideoPath:    mem("cfg.bgVideoPath", "assets\\videos")
  property string moviesPath:     mem("cfg.moviesPath",  "assets\\movies")

  property string videoFolder1:   mem("cfg.vf1",  "assets\\videos")
  property string videoFolder2:   mem("cfg.vf2",  "")
  property string videoFolder3:   mem("cfg.vf3",  "")
  property string videoFolder4:   mem("cfg.vf4",  "")
  property string videoFolder5:   mem("cfg.vf5",  "")
  property bool   videoFolder1En: mem("cfg.vf1en","true")  === "true"
  property bool   videoFolder2En: mem("cfg.vf2en","false") === "true"
  property bool   videoFolder3En: mem("cfg.vf3en","false") === "true"
  property bool   videoFolder4En: mem("cfg.vf4en","false") === "true"
  property bool   videoFolder5En: mem("cfg.vf5en","false") === "true"

  property bool   vtMp4:   mem("cfg.vt.mp4",  "true")  === "true"
  property bool   vtWebm:  mem("cfg.vt.webm", "true")  === "true"
  property bool   vtMkv:   mem("cfg.vt.mkv",  "true")  === "true"
  property bool   vtAvi:   mem("cfg.vt.avi",  "false") === "true"
  property bool   vtMov:   mem("cfg.vt.mov",  "false") === "true"

  function normPath(p) {
    if (!p) return ""
    return p.replace(/\\/g, "/")
  }

  function enabledExts() {
    var e = []
    if (vtMp4)  e.push(".mp4")
    if (vtWebm) e.push(".webm")
    if (vtMkv)  e.push(".mkv")
    if (vtAvi)  e.push(".avi")
    if (vtMov)  e.push(".mov")
    return e.length > 0 ? e.join("  ") : "(none)"
  }

  // Time
  property bool   showClock:             mem("cfg.showClock",     "true")  === "true"
  property bool   clockFormat24:         mem("cfg.clock24",       "false") === "true"
  property bool   useSkinClock:          mem("cfg.useSkinClock",  "false") === "true"
  property bool   clockOnDashboard:      mem("cfg.clockOnDash",   "true")  === "true"
  property real   clockPosX:             parseFloat(mem("cfg.clockPosX",   "0.97"))
  property real   clockPosY:             parseFloat(mem("cfg.clockPosY",   "0.02"))
  property int    clockFontSize:         parseInt(mem("cfg.clockFontSize",  "16"))
  property real   clockTextOpacity:      parseFloat(mem("cfg.clockOpacity", "1.0"))
  property int    clockOpacityPct:       Math.round(parseFloat(mem("cfg.clockOpacity","1.0")) * 100)
  property int    clockEdgePad:          parseInt(mem("cfg.clockPadding",   "12"))

  // ── Date overlay ──────────────────────────────────────────────────
  property bool   showDate:              mem("cfg.showDate",      "false") === "true"
  property bool   useSkinDate:           mem("cfg.useSkinDate",   "false") === "true"
  property bool   dateOnDashboard:       mem("cfg.dateOnDash",    "true")  === "true"
  property int    dateFormatIdx:         parseInt(mem("cfg.dateFormat",    "0"))
  property real   datePosX:              parseFloat(mem("cfg.datePosX",    "0.97"))
  property real   datePosY:              parseFloat(mem("cfg.datePosY",    "0.07"))
  property int    dateFontSize:          parseInt(mem("cfg.dateFontSize",   "14"))
  property real   dateTextOpacity:       parseFloat(mem("cfg.dateOpacity",  "1.0"))
  property int    dateOpacityPct:        Math.round(parseFloat(mem("cfg.dateOpacity","1.0")) * 100)
  property int    dateEdgePad:           parseInt(mem("cfg.datePadding",    "12"))
  property var    dateFormatLabels:      ["Day + Month Name", "Day + Month Number", "Full Date (Names)", "Full Date (Numbers)"]
  property var    datePresets: {
    var raw = mem("cfg.datePresets", "")
    try { return raw ? JSON.parse(raw) : [] } catch(e) { return [] }
  }
  function saveDatePresets() { save("cfg.datePresets", JSON.stringify(datePresets)) }

  property bool   showFPS:               mem("cfg.showFPS",       "false") === "true"
  property bool   fpsOnDashboard:        mem("cfg.fpsOnDash",     "false") === "true"
  property real   fpsPosX:               parseFloat(mem("cfg.fpsPosX",     "0.02"))
  property real   fpsPosY:               parseFloat(mem("cfg.fpsPosY",     "0.02"))
  property int    fpsFontSize:           parseInt(mem("cfg.fpsFontSize",    "16"))
  property real   fpsTextOpacity:        parseFloat(mem("cfg.fpsOpacity",   "1.0"))
  property int    fpsEdgePad:            parseInt(mem("cfg.fpsPadding",     "12"))
  property int    fpsColorIdx:           parseInt(mem("cfg.fpsColor",       "0"))

  property var clockPresets: {
    var raw = mem("cfg.clockPresets", "")
    if (raw.length > 0) { try { return JSON.parse(raw) } catch(e) {} }
    return [
      { name: "Top Right",    x: 0.97, y: 0.02 },
      { name: "Top Left",     x: 0.02, y: 0.02 },
      { name: "Bottom Right", x: 0.97, y: 0.94 },
      { name: "Bottom Left",  x: 0.02, y: 0.94 }
    ]
  }
  property var fpsPresets: {
    var raw = mem("cfg.fpsPresets", "")
    if (raw.length > 0) { try { return JSON.parse(raw) } catch(e) {} }
    return [
      { name: "Top Left",     x: 0.02, y: 0.02 },
      { name: "Top Right",    x: 0.97, y: 0.02 },
      { name: "Bottom Left",  x: 0.02, y: 0.94 },
      { name: "Bottom Right", x: 0.97, y: 0.94 }
    ]
  }
  function saveClockPresets() { save("cfg.clockPresets", JSON.stringify(clockPresets)) }
  function saveFpsPresets()   { save("cfg.fpsPresets",   JSON.stringify(fpsPresets)) }

  // Audio
  property int    masterVolume:          parseInt(mem("cfg.masterVol",   "80"))
  property int    musicVolume:           parseInt(mem("cfg.musicVol",    "60"))
  property int    sfxVolume:             parseInt(mem("cfg.sfxVol",      "80"))
  property bool   muteAll:               mem("cfg.muteAll",     "false") === "true"
  property bool   uiSounds:              mem("cfg.uiSounds",    "true")  === "true"
  property bool   systemMusic:           mem("cfg.systemMusic", "true")  === "true"
  property bool   startupSound:          mem("cfg.startupSound","true")  === "true"

  // Input
  property bool   vibration:             mem("cfg.vibration",   "true")  === "true"
  property int    repeatDelayIdx:        parseInt(mem("cfg.repeatDelay", "1"))
  property bool   mouseEnabled:          mem("cfg.mouse",       "true")  === "true"
  property bool   swapAB:                mem("cfg.swapAB",      "false") === "true"

  // Network
  property bool   checkUpdates:          mem("cfg.checkUpdates","true")  === "true"
  property bool   onlineFeatures:        mem("cfg.onlineFeat",  "true")  === "true"
  property string region:                mem("cfg.region",      "US")

  // Parental
  property bool   parentalEnabled:       mem("cfg.parental",    "false") === "true"
  property int    ratingLimitIdx:        parseInt(mem("cfg.ratingLimit", "4"))

  // Interface
  property int    interfaceTransparency: parseInt(mem("cfg.ifaceAlpha",    "80"))
  property int    accentTransparency:    parseInt(mem("cfg.accentAlpha",   "0"))
  property int    accentColorIdx:        parseInt(mem("cfg.accentColor",   "0"))
  property int    themeColorIdx:         parseInt(mem("cfg.themeColor",    "0"))
  // Separate border / fill pickers for Accent and Theme
  property int    accentBorderIdx:       parseInt(mem("cfg.accentBorder",  "6"))
  property int    accentFillIdx:         parseInt(mem("cfg.accentFill",    "0"))
  property int    themeBorderIdx:        parseInt(mem("cfg.themeBorder",   "6"))
  property int    themeFillIdx:          parseInt(mem("cfg.themeFill",     "2"))
  property bool   showLayoutBadge:       mem("cfg.showLayoutBadge","true") === "true"
  property bool   showPanelReflect:      mem("cfg.panelReflect", "true")  === "true"
  property bool   panelGradient:         mem("cfg.panelGradient","true")  === "true"
  property bool   gradAccentColor:       mem("cfg.gradAccent",   "true")  === "true"
  property bool   gradAccentOpacity:     mem("cfg.gradAccentOp", "true")  === "true"
  property bool   gradThemeColor:        mem("cfg.gradTheme",    "true")  === "true"
  property bool   gradThemeTransp:       mem("cfg.gradThemeTr",  "true")  === "true"
  property int    panelAnimIdx:          parseInt(mem("cfg.panelAnim",   "1"))

  // FIX: All colour tables moved from `readonly property var` to plain `property var`
  //      to avoid silent parse failures in Qt 5.9 with array-of-object literals.
  property var accentColors: [
        { name: "Burnt Red", hex: "#1B0202", tags: ["dark", "vibrant", "warm"] },
        { name: "Burgundy Red", hex: "#290505", tags: ["dark", "vibrant", "warm"] },
        { name: "Deep Maroon", hex: "#7B0000", tags: ["dark", "vibrant", "warm"] },
        { name: "Maroon", hex: "#800000", tags: ["mid", "vibrant", "warm"] },
        { name: "Dark Red", hex: "#8B0000", tags: ["mid", "vibrant", "warm"] },
        { name: "Deep Red", hex: "#990000", tags: ["mid", "vibrant", "warm"] },
        { name: "Brown Red", hex: "#A52A2A", tags: ["mid", "warm"] },
        { name: "Firebrick", hex: "#B22222", tags: ["mid", "vibrant", "warm"] },
        { name: "Vivid Red", hex: "#E51400", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Red", hex: "#FF0000", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Indian Red", hex: "#CD5C5C", tags: ["light", "warm"] },
        { name: "Rosy Brown", hex: "#BC8F8F", tags: ["light", "muted", "warm"] },
        { name: "Salmon", hex: "#FA8072", tags: ["light", "neon", "vibrant", "pastel", "warm"] },
        { name: "Light Coral", hex: "#F08080", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Misty Rose", hex: "#FFE4E1", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Snow", hex: "#FFFAFA", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Espresso", hex: "#1C0E07", tags: ["dark", "warm"] },
        { name: "Sienna", hex: "#A0522D", tags: ["mid", "warm"] },
        { name: "Orange Red", hex: "#FF4500", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Vivid Coral", hex: "#FF5733", tags: ["light", "neon", "vibrant", "warm"] },
        { name: "Tomato", hex: "#FF6347", tags: ["light", "neon", "vibrant", "warm"] },
        { name: "Coral", hex: "#FF7F50", tags: ["light", "neon", "vibrant", "pastel", "warm"] },
        { name: "Dark Salmon", hex: "#E9967A", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Light Salmon", hex: "#FFA07A", tags: ["light", "neon", "vibrant", "pastel", "warm"] },
        { name: "Dark Horse Brown", hex: "#170C01", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Umber", hex: "#2A1A0A", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Sienna", hex: "#3A1800", tags: ["dark", "vibrant", "warm"] },
        { name: "Horse Brown", hex: "#331B09", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Brown", hex: "#3B1F0A", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Sand", hex: "#504030", tags: ["mid", "muted", "warm"] },
        { name: "Saddle Dark Brown", hex: "#8B4513", tags: ["mid", "vibrant", "warm"] },
        { name: "Saddle Brown", hex: "#A05000", tags: ["mid", "vibrant", "warm"] },
        { name: "Boy Brown", hex: "#88511C", tags: ["mid", "vibrant", "warm"] },
        { name: "Warm Dark Brown", hex: "#8B5E1A", tags: ["mid", "vibrant", "warm"] },
        { name: "Burnt Orange", hex: "#CC5500", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Chocolate", hex: "#D2691E", tags: ["mid", "vibrant", "warm"] },
        { name: "Mango", hex: "#F09609", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Tangerine", hex: "#FA6800", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Dark Orange Alt", hex: "#FF8000", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Dark Orange", hex: "#FF8C00", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Orange UK", hex: "#FF6501", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Dark Tan", hex: "#B08050", tags: ["mid", "warm"] },
        { name: "Peru", hex: "#CD853F", tags: ["mid", "warm"] },
        { name: "Sandy Brown", hex: "#F4A460", tags: ["light", "neon", "vibrant", "pastel", "warm"] },
        { name: "Tan", hex: "#D2B48C", tags: ["light", "pastel", "warm"] },
        { name: "Navajo White", hex: "#FFDEAD", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Peach Puff", hex: "#FFDAB9", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Bisque", hex: "#FFE4C4", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Blanched Almond", hex: "#FFEBCD", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Antique White", hex: "#FAEBD7", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Papaya Whip", hex: "#FFEFD5", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Linen", hex: "#FAF0E6", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Sea Shell", hex: "#FFF5EE", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Dark Goldenrod", hex: "#B8860B", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Taupe", hex: "#87794E", tags: ["mid", "muted", "warm"] },
        { name: "Amber", hex: "#F0A70A", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Goldenrod", hex: "#DAA520", tags: ["mid", "vibrant", "warm"] },
        { name: "Orange", hex: "#FFA500", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Deep Amber", hex: "#FFAA00", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Gold", hex: "#FFD700", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Khaki Gold", hex: "#C8A850", tags: ["mid", "warm"] },
        { name: "Wheat", hex: "#F5DEB3", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Moccasin", hex: "#FFE4B5", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Cornsilk", hex: "#FFF8DC", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Old Lace", hex: "#FDF5E6", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Floral White", hex: "#FFFAF0", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Dark Olive", hex: "#3B3B00", tags: ["dark", "vibrant", "warm"] },
        { name: "Olive", hex: "#808000", tags: ["mid", "vibrant", "warm"] },
        { name: "Dark Chartreuse", hex: "#A3B500", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Nokia Yellow", hex: "#CDBC16", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Yellow", hex: "#FFFF00", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Dark Khaki", hex: "#BDB76B", tags: ["light", "warm"] },
        { name: "Khaki", hex: "#F0E68C", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Pale Goldenrod", hex: "#EEE8AA", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Light Goldenrod", hex: "#FAFAD2", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Lemon Chiffon", hex: "#FFFACD", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Beige", hex: "#F5F5DC", tags: ["light", "pastel", "warm"] },
        { name: "Light Yellow", hex: "#FFFFE0", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Ivory", hex: "#FFFFF0", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Seaweed Green", hex: "#0F1301", tags: ["dark", "vibrant", "warm"] },
        { name: "Weed Green", hex: "#1F2804", tags: ["dark", "vibrant", "warm"] },
        { name: "Avocado", hex: "#568203", tags: ["mid", "vibrant", "warm"] },
        { name: "Dark Olive Green", hex: "#556B2F", tags: ["mid", "warm"] },
        { name: "Olive Drab", hex: "#6B8E23", tags: ["mid", "vibrant", "warm"] },
        { name: "Limey Green", hex: "#7FBA00", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Yellow Lime", hex: "#A2C139", tags: ["mid", "warm"] },
        { name: "Yellow Green", hex: "#9ACD32", tags: ["mid", "vibrant", "warm"] },
        { name: "Pantone Lime", hex: "#CBFE33", tags: ["light", "neon", "vibrant", "warm"] },
        { name: "Dark Moss", hex: "#2A3A1A", tags: ["dark", "cool"] },
        { name: "Lime Green", hex: "#5D9809", tags: ["mid", "vibrant", "warm"] },
        { name: "Leaf Green", hex: "#69B40F", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Lawn Green", hex: "#7CFC00", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Chartreuse", hex: "#7FFF00", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Green Yellow", hex: "#ADFF2F", tags: ["light", "neon", "vibrant", "warm"] },
        { name: "Pistachio", hex: "#93C572", tags: ["light", "cool"] },
        { name: "Military Green", hex: "#6F8663", tags: ["mid", "muted"] },
        { name: "Marine Green", hex: "#052C05", tags: ["dark", "vibrant", "cool"] },
        { name: "Dark Jungle", hex: "#0A2A0A", tags: ["dark", "vibrant", "cool"] },
        { name: "Deep Forest", hex: "#1A3A1A", tags: ["dark", "cool"] },
        { name: "Dark Green", hex: "#006400", tags: ["dark", "vibrant", "cool"] },
        { name: "Green", hex: "#008000", tags: ["mid", "vibrant", "cool"] },
        { name: "Forest Green", hex: "#228B22", tags: ["mid", "vibrant", "cool"] },
        { name: "Hunter Green", hex: "#2A8A2A", tags: ["mid", "cool"] },
        { name: "Vivid Green", hex: "#339933", tags: ["mid", "cool"] },
        { name: "Lime", hex: "#00FF00", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Lime Bright", hex: "#32CD32", tags: ["mid", "vibrant", "cool"] },
        { name: "Light Green", hex: "#90EE90", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Pale Green", hex: "#98FB98", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Honeydew", hex: "#F0FFF0", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Hunter Dark Green", hex: "#355E3B", tags: ["mid", "muted", "cool"] },
        { name: "Emerald", hex: "#009E49", tags: ["mid", "vibrant", "cool"] },
        { name: "Sea Green", hex: "#2E8B57", tags: ["mid", "cool"] },
        { name: "Spring Lime", hex: "#00E060", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Medium Sea Green", hex: "#3CB371", tags: ["mid", "cool"] },
        { name: "Medium Spring Green", hex: "#00FA9A", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Spring Green", hex: "#00FF7F", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Mint Foam", hex: "#D5F9EA", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Mint Cream", hex: "#F5FFFA", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Vivid Teal", hex: "#00BFA5", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Cadet Blue", hex: "#0EB887", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Pearl Turquoise", hex: "#32C6A6", tags: ["mid", "cool"] },
        { name: "Medium Aquamarine", hex: "#66CDAA", tags: ["light", "cool"] },
        { name: "Aquamarine", hex: "#7FFFD4", tags: ["light", "neon", "vibrant", "pastel", "cool"] },
        { name: "Nessie Teal", hex: "#011212", tags: ["dark", "vibrant", "cool"] },
        { name: "Arial Teal", hex: "#042929", tags: ["dark", "vibrant", "cool"] },
        { name: "Dark Teal", hex: "#003333", tags: ["dark", "vibrant", "cool"] },
        { name: "Deep Teal", hex: "#004444", tags: ["dark", "vibrant", "cool"] },
        { name: "Deep Dark Cyan", hex: "#006666", tags: ["dark", "vibrant", "cool"] },
        { name: "Dark Slate Gray", hex: "#2F4F4F", tags: ["dark", "muted", "cool"] },
        { name: "Teal", hex: "#008080", tags: ["mid", "vibrant", "cool"] },
        { name: "Dark Cyan", hex: "#008B8B", tags: ["mid", "vibrant", "cool"] },
        { name: "Cyan Teal", hex: "#00ABA9", tags: ["mid", "vibrant", "cool"] },
        { name: "Light Turquoise", hex: "#00ABAB", tags: ["mid", "vibrant", "cool"] },
        { name: "Medium Cyan", hex: "#00CCCC", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Dark Turquoise", hex: "#00CED1", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Light Sea Green", hex: "#20B2AA", tags: ["mid", "vibrant", "cool"] },
        { name: "Aqua", hex: "#00FFFF", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Medium Turquoise", hex: "#48D1CC", tags: ["light", "cool"] },
        { name: "Turquoise", hex: "#40E0D0", tags: ["light", "vibrant", "cool"] },
        { name: "Powder Blue", hex: "#B0E0E6", tags: ["light", "pastel", "cool"] },
        { name: "Pale Turquoise", hex: "#AFEEEE", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Light Cyan", hex: "#E0FFFF", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Azure Blue", hex: "#F0FFFF", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Gunmetal", hex: "#2C3539", tags: ["dark", "muted"] },
        { name: "Southern Blue", hex: "#0084C9", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Cerulean Blue", hex: "#0099CC", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Matte Blue", hex: "#3D80A0", tags: ["mid", "cool"] },
        { name: "Vivid Blue", hex: "#1BA1E2", tags: ["mid", "vibrant", "cool"] },
        { name: "Deep Sky Blue", hex: "#00BFFF", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Light Matte Blue", hex: "#73B6D6", tags: ["light", "cool"] },
        { name: "Sky Periwinkle", hex: "#66CCFF", tags: ["light", "neon", "vibrant", "pastel", "cool"] },
        { name: "Sky Blue", hex: "#87CEEB", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Light Blue", hex: "#ADD8E6", tags: ["light", "pastel", "cool"] },
        { name: "Twilight Blue", hex: "#010B15", tags: ["dark", "vibrant", "cool"] },
        { name: "Marine Blue", hex: "#05182B", tags: ["dark", "vibrant", "cool"] },
        { name: "Deep Sea Blue", hex: "#062343", tags: ["dark", "vibrant", "cool"] },
        { name: "Twilight Gray", hex: "#1E2A3A", tags: ["dark", "muted", "cool"] },
        { name: "Steel Navy", hex: "#1C3A5A", tags: ["dark", "cool"] },
        { name: "Arctic Blue", hex: "#03417B", tags: ["dark", "vibrant", "cool"] },
        { name: "Nokia Blue", hex: "#004C9A", tags: ["mid", "vibrant", "cool"] },
        { name: "Denim Blue", hex: "#1B4F8A", tags: ["mid", "vibrant", "cool"] },
        { name: "Cobalt Blue", hex: "#0047AB", tags: ["mid", "vibrant", "cool"] },
        { name: "Azure", hex: "#007ACC", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Steel Gray", hex: "#647487", tags: ["mid", "muted"] },
        { name: "Steel Blue", hex: "#4682B4", tags: ["mid", "cool"] },
        { name: "Slate Gray", hex: "#708090", tags: ["mid", "muted"] },
        { name: "Light Slate Gray", hex: "#778899", tags: ["mid", "muted"] },
        { name: "Dodger Blue", hex: "#1E90FF", tags: ["light", "neon", "vibrant", "cool"] },
        { name: "Cornflower Azure", hex: "#3385FF", tags: ["light", "neon", "vibrant", "cool"] },
        { name: "Light Sky Blue", hex: "#87CEFA", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Light Steel Blue", hex: "#B0C4DE", tags: ["light", "pastel", "cool"] },
        { name: "Alice Blue", hex: "#F0F8FF", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Ink Blue", hex: "#0A1540", tags: ["dark", "vibrant", "cool"] },
        { name: "Deep Navy", hex: "#001F5B", tags: ["dark", "vibrant", "cool"] },
        { name: "Atlantic Blue", hex: "#01145E", tags: ["dark", "vibrant", "cool"] },
        { name: "Deep Royal Blue", hex: "#1040C0", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Facebook Blue", hex: "#3B5998", tags: ["mid", "cool"] },
        { name: "Cobalt Electric", hex: "#0050EF", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Royal Blue", hex: "#4169E1", tags: ["light", "vibrant", "cool"] },
        { name: "Cornflower Blue", hex: "#6495ED", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Periwinkle", hex: "#7B96DC", tags: ["light", "pastel", "cool"] },
        { name: "Abyss", hex: "#050520", tags: ["dark", "vibrant", "cool"] },
        { name: "Rich Black", hex: "#0D0D1E", tags: ["dark", "cool"] },
        { name: "Pacific Blue", hex: "#010942", tags: ["dark", "vibrant", "cool"] },
        { name: "Navy", hex: "#000080", tags: ["mid", "vibrant", "cool"] },
        { name: "Midnight Blue", hex: "#191970", tags: ["mid", "vibrant", "cool"] },
        { name: "Dark Blue", hex: "#00008B", tags: ["mid", "vibrant", "cool"] },
        { name: "Medium Blue", hex: "#0000CD", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Midnight", hex: "#3A3ABF", tags: ["mid", "cool"] },
        { name: "Blue", hex: "#0000FF", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Lavender", hex: "#E6E6FA", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Ghost White", hex: "#F8F8FF", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Dark Slate Blue", hex: "#483D8B", tags: ["mid", "cool"] },
        { name: "Ultramarine", hex: "#3F00FF", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Slate Blue", hex: "#6A5ACD", tags: ["light", "cool"] },
        { name: "Medium Purple", hex: "#9370DB", tags: ["light", "cool"] },
        { name: "Medium Slate Blue", hex: "#7B68EE", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Black Purple", hex: "#0B0111", tags: ["dark", "vibrant", "warm"] },
        { name: "Deep Indigo", hex: "#1A0033", tags: ["dark", "vibrant", "warm"] },
        { name: "Deep Dark Violet", hex: "#200040", tags: ["dark", "vibrant", "cool"] },
        { name: "Dusk Purple", hex: "#3A2A4A", tags: ["dark", "muted", "cool"] },
        { name: "Indigo", hex: "#4B0082", tags: ["mid", "vibrant", "warm"] },
        { name: "Electric Indigo", hex: "#6A00FF", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Blue Violet", hex: "#8A2BE2", tags: ["mid", "vibrant", "warm"] },
        { name: "Lavender Purple", hex: "#B57FDC", tags: ["light", "pastel", "warm"] },
        { name: "Deep Purple", hex: "#1C0429", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Violet", hex: "#9400D3", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Electric Violet", hex: "#9600EC", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Dark Orchid", hex: "#9932CC", tags: ["mid", "vibrant", "warm"] },
        { name: "Vivid Purple", hex: "#A200FF", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Medium Orchid", hex: "#BA55D3", tags: ["light", "warm"] },
        { name: "Dark Plum", hex: "#300030", tags: ["dark", "vibrant", "warm"] },
        { name: "Purple", hex: "#800080", tags: ["mid", "vibrant", "warm"] },
        { name: "Dark Magenta", hex: "#8B008B", tags: ["mid", "vibrant", "warm"] },
        { name: "Mauve", hex: "#8A608A", tags: ["mid", "muted"] },
        { name: "Fuchsia", hex: "#FF00FF", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Orchid", hex: "#DA70D6", tags: ["light", "warm"] },
        { name: "Violet", hex: "#EE82EE", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Plum", hex: "#DDA0DD", tags: ["light", "pastel", "warm"] },
        { name: "Thistle", hex: "#D8BFD8", tags: ["light", "muted", "warm"] },
        { name: "Medium Violet Red", hex: "#C71585", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Pretty Pink", hex: "#F472D0", tags: ["light", "neon", "vibrant", "pastel", "warm"] },
        { name: "Eggplant Magenta", hex: "#18020E", tags: ["dark", "vibrant", "warm"] },
        { name: "Turnip Magenta", hex: "#2B0417", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Mauve", hex: "#3A1A2A", tags: ["dark", "warm"] },
        { name: "Hot Pink Alt", hex: "#D80073", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "T-Mobile Pink", hex: "#E30083", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Formal Magenta", hex: "#EC008C", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Rose", hex: "#E91E8C", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Deep Pink", hex: "#FF1493", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Petal Pink", hex: "#E671B8", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Hot Pink", hex: "#FF69B4", tags: ["light", "neon", "vibrant", "pastel", "warm"] },
        { name: "Dark Maroon", hex: "#4A0010", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Crimson", hex: "#5C0020", tags: ["dark", "vibrant", "warm"] },
        { name: "Crimson Dark", hex: "#800020", tags: ["mid", "vibrant", "warm"] },
        { name: "Nokia Red", hex: "#9A002C", tags: ["mid", "vibrant", "warm"] },
        { name: "Vodafone Red", hex: "#EF001F", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Crimson", hex: "#DC143C", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Vermilion", hex: "#FF1852", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Pale Violet Red", hex: "#DB7093", tags: ["light", "warm"] },
        { name: "Pink", hex: "#FFB6C1", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Pink Blush", hex: "#FFC0CB", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Lavender Blush", hex: "#FFF0F5", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Virgin Mobile Red", hex: "#CC0001", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Dead Red", hex: "#E81123", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Black", hex: "#000000", tags: ["neutral", "dark"] },
        { name: "Coal Gray", hex: "#090909", tags: ["neutral", "dark"] },
        { name: "Jet Black", hex: "#0A0A0A", tags: ["neutral", "dark"] },
        { name: "Onyx", hex: "#1A1A1A", tags: ["neutral", "dark"] },
        { name: "Storm Gray", hex: "#2B2A2A", tags: ["neutral", "dark"] },
        { name: "Graphite", hex: "#383838", tags: ["neutral", "mid"] },
        { name: "Dark Grey", hex: "#404040", tags: ["neutral", "mid"] },
        { name: "Dark", hex: "#555555", tags: ["neutral", "mid"] },
        { name: "Charcoal", hex: "#606060", tags: ["neutral", "mid"] },
        { name: "Dim Gray", hex: "#696969", tags: ["neutral", "mid"] },
        { name: "Gray", hex: "#808080", tags: ["neutral", "mid"] },
        { name: "Dark Gray", hex: "#A9A9A9", tags: ["neutral", "mid"] },
        { name: "Silver", hex: "#C0C0C0", tags: ["neutral", "mid"] },
        { name: "Light Gray", hex: "#D3D3D3", tags: ["neutral", "light"] },
        { name: "Gainsboro", hex: "#DCDCDC", tags: ["neutral", "light"] },
        { name: "Off White", hex: "#EEEEEE", tags: ["neutral", "light"] },
        { name: "White Smoke", hex: "#F5F5F5", tags: ["neutral", "light"] },
        { name: "White", hex: "#FFFFFF", tags: ["neutral", "light"] }
  ]
  property var themeColors: [
        { name: "Burnt Red", hex: "#1B0202", tags: ["dark", "vibrant", "warm"] },
        { name: "Burgundy Red", hex: "#290505", tags: ["dark", "vibrant", "warm"] },
        { name: "Deep Maroon", hex: "#7B0000", tags: ["dark", "vibrant", "warm"] },
        { name: "Maroon", hex: "#800000", tags: ["mid", "vibrant", "warm"] },
        { name: "Dark Red", hex: "#8B0000", tags: ["mid", "vibrant", "warm"] },
        { name: "Deep Red", hex: "#990000", tags: ["mid", "vibrant", "warm"] },
        { name: "Brown Red", hex: "#A52A2A", tags: ["mid", "warm"] },
        { name: "Firebrick", hex: "#B22222", tags: ["mid", "vibrant", "warm"] },
        { name: "Vivid Red", hex: "#E51400", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Red", hex: "#FF0000", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Indian Red", hex: "#CD5C5C", tags: ["light", "warm"] },
        { name: "Rosy Brown", hex: "#BC8F8F", tags: ["light", "muted", "warm"] },
        { name: "Salmon", hex: "#FA8072", tags: ["light", "neon", "vibrant", "pastel", "warm"] },
        { name: "Light Coral", hex: "#F08080", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Misty Rose", hex: "#FFE4E1", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Snow", hex: "#FFFAFA", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Espresso", hex: "#1C0E07", tags: ["dark", "warm"] },
        { name: "Sienna", hex: "#A0522D", tags: ["mid", "warm"] },
        { name: "Orange Red", hex: "#FF4500", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Vivid Coral", hex: "#FF5733", tags: ["light", "neon", "vibrant", "warm"] },
        { name: "Tomato", hex: "#FF6347", tags: ["light", "neon", "vibrant", "warm"] },
        { name: "Coral", hex: "#FF7F50", tags: ["light", "neon", "vibrant", "pastel", "warm"] },
        { name: "Dark Salmon", hex: "#E9967A", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Light Salmon", hex: "#FFA07A", tags: ["light", "neon", "vibrant", "pastel", "warm"] },
        { name: "Dark Horse Brown", hex: "#170C01", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Umber", hex: "#2A1A0A", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Sienna", hex: "#3A1800", tags: ["dark", "vibrant", "warm"] },
        { name: "Horse Brown", hex: "#331B09", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Brown", hex: "#3B1F0A", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Sand", hex: "#504030", tags: ["mid", "muted", "warm"] },
        { name: "Saddle Dark Brown", hex: "#8B4513", tags: ["mid", "vibrant", "warm"] },
        { name: "Saddle Brown", hex: "#A05000", tags: ["mid", "vibrant", "warm"] },
        { name: "Boy Brown", hex: "#88511C", tags: ["mid", "vibrant", "warm"] },
        { name: "Warm Dark Brown", hex: "#8B5E1A", tags: ["mid", "vibrant", "warm"] },
        { name: "Burnt Orange", hex: "#CC5500", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Chocolate", hex: "#D2691E", tags: ["mid", "vibrant", "warm"] },
        { name: "Mango", hex: "#F09609", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Tangerine", hex: "#FA6800", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Dark Orange Alt", hex: "#FF8000", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Dark Orange", hex: "#FF8C00", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Orange UK", hex: "#FF6501", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Dark Tan", hex: "#B08050", tags: ["mid", "warm"] },
        { name: "Peru", hex: "#CD853F", tags: ["mid", "warm"] },
        { name: "Sandy Brown", hex: "#F4A460", tags: ["light", "neon", "vibrant", "pastel", "warm"] },
        { name: "Tan", hex: "#D2B48C", tags: ["light", "pastel", "warm"] },
        { name: "Navajo White", hex: "#FFDEAD", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Peach Puff", hex: "#FFDAB9", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Bisque", hex: "#FFE4C4", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Blanched Almond", hex: "#FFEBCD", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Antique White", hex: "#FAEBD7", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Papaya Whip", hex: "#FFEFD5", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Linen", hex: "#FAF0E6", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Sea Shell", hex: "#FFF5EE", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Dark Goldenrod", hex: "#B8860B", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Taupe", hex: "#87794E", tags: ["mid", "muted", "warm"] },
        { name: "Amber", hex: "#F0A70A", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Goldenrod", hex: "#DAA520", tags: ["mid", "vibrant", "warm"] },
        { name: "Orange", hex: "#FFA500", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Deep Amber", hex: "#FFAA00", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Gold", hex: "#FFD700", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Khaki Gold", hex: "#C8A850", tags: ["mid", "warm"] },
        { name: "Wheat", hex: "#F5DEB3", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Moccasin", hex: "#FFE4B5", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Cornsilk", hex: "#FFF8DC", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Old Lace", hex: "#FDF5E6", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Floral White", hex: "#FFFAF0", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Dark Olive", hex: "#3B3B00", tags: ["dark", "vibrant", "warm"] },
        { name: "Olive", hex: "#808000", tags: ["mid", "vibrant", "warm"] },
        { name: "Dark Chartreuse", hex: "#A3B500", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Nokia Yellow", hex: "#CDBC16", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Yellow", hex: "#FFFF00", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Dark Khaki", hex: "#BDB76B", tags: ["light", "warm"] },
        { name: "Khaki", hex: "#F0E68C", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Pale Goldenrod", hex: "#EEE8AA", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Light Goldenrod", hex: "#FAFAD2", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Lemon Chiffon", hex: "#FFFACD", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Beige", hex: "#F5F5DC", tags: ["light", "pastel", "warm"] },
        { name: "Light Yellow", hex: "#FFFFE0", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Ivory", hex: "#FFFFF0", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Seaweed Green", hex: "#0F1301", tags: ["dark", "vibrant", "warm"] },
        { name: "Weed Green", hex: "#1F2804", tags: ["dark", "vibrant", "warm"] },
        { name: "Avocado", hex: "#568203", tags: ["mid", "vibrant", "warm"] },
        { name: "Dark Olive Green", hex: "#556B2F", tags: ["mid", "warm"] },
        { name: "Olive Drab", hex: "#6B8E23", tags: ["mid", "vibrant", "warm"] },
        { name: "Limey Green", hex: "#7FBA00", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Yellow Lime", hex: "#A2C139", tags: ["mid", "warm"] },
        { name: "Yellow Green", hex: "#9ACD32", tags: ["mid", "vibrant", "warm"] },
        { name: "Pantone Lime", hex: "#CBFE33", tags: ["light", "neon", "vibrant", "warm"] },
        { name: "Dark Moss", hex: "#2A3A1A", tags: ["dark", "cool"] },
        { name: "Lime Green", hex: "#5D9809", tags: ["mid", "vibrant", "warm"] },
        { name: "Leaf Green", hex: "#69B40F", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Lawn Green", hex: "#7CFC00", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Chartreuse", hex: "#7FFF00", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Green Yellow", hex: "#ADFF2F", tags: ["light", "neon", "vibrant", "warm"] },
        { name: "Pistachio", hex: "#93C572", tags: ["light", "cool"] },
        { name: "Military Green", hex: "#6F8663", tags: ["mid", "muted"] },
        { name: "Marine Green", hex: "#052C05", tags: ["dark", "vibrant", "cool"] },
        { name: "Dark Jungle", hex: "#0A2A0A", tags: ["dark", "vibrant", "cool"] },
        { name: "Deep Forest", hex: "#1A3A1A", tags: ["dark", "cool"] },
        { name: "Dark Green", hex: "#006400", tags: ["dark", "vibrant", "cool"] },
        { name: "Green", hex: "#008000", tags: ["mid", "vibrant", "cool"] },
        { name: "Forest Green", hex: "#228B22", tags: ["mid", "vibrant", "cool"] },
        { name: "Hunter Green", hex: "#2A8A2A", tags: ["mid", "cool"] },
        { name: "Vivid Green", hex: "#339933", tags: ["mid", "cool"] },
        { name: "Lime", hex: "#00FF00", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Lime Bright", hex: "#32CD32", tags: ["mid", "vibrant", "cool"] },
        { name: "Light Green", hex: "#90EE90", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Pale Green", hex: "#98FB98", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Honeydew", hex: "#F0FFF0", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Hunter Dark Green", hex: "#355E3B", tags: ["mid", "muted", "cool"] },
        { name: "Emerald", hex: "#009E49", tags: ["mid", "vibrant", "cool"] },
        { name: "Sea Green", hex: "#2E8B57", tags: ["mid", "cool"] },
        { name: "Spring Lime", hex: "#00E060", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Medium Sea Green", hex: "#3CB371", tags: ["mid", "cool"] },
        { name: "Medium Spring Green", hex: "#00FA9A", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Spring Green", hex: "#00FF7F", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Mint Foam", hex: "#D5F9EA", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Mint Cream", hex: "#F5FFFA", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Vivid Teal", hex: "#00BFA5", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Cadet Blue", hex: "#0EB887", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Pearl Turquoise", hex: "#32C6A6", tags: ["mid", "cool"] },
        { name: "Medium Aquamarine", hex: "#66CDAA", tags: ["light", "cool"] },
        { name: "Aquamarine", hex: "#7FFFD4", tags: ["light", "neon", "vibrant", "pastel", "cool"] },
        { name: "Nessie Teal", hex: "#011212", tags: ["dark", "vibrant", "cool"] },
        { name: "Arial Teal", hex: "#042929", tags: ["dark", "vibrant", "cool"] },
        { name: "Dark Teal", hex: "#003333", tags: ["dark", "vibrant", "cool"] },
        { name: "Deep Teal", hex: "#004444", tags: ["dark", "vibrant", "cool"] },
        { name: "Deep Dark Cyan", hex: "#006666", tags: ["dark", "vibrant", "cool"] },
        { name: "Dark Slate Gray", hex: "#2F4F4F", tags: ["dark", "muted", "cool"] },
        { name: "Teal", hex: "#008080", tags: ["mid", "vibrant", "cool"] },
        { name: "Dark Cyan", hex: "#008B8B", tags: ["mid", "vibrant", "cool"] },
        { name: "Cyan Teal", hex: "#00ABA9", tags: ["mid", "vibrant", "cool"] },
        { name: "Light Turquoise", hex: "#00ABAB", tags: ["mid", "vibrant", "cool"] },
        { name: "Medium Cyan", hex: "#00CCCC", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Dark Turquoise", hex: "#00CED1", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Light Sea Green", hex: "#20B2AA", tags: ["mid", "vibrant", "cool"] },
        { name: "Aqua", hex: "#00FFFF", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Medium Turquoise", hex: "#48D1CC", tags: ["light", "cool"] },
        { name: "Turquoise", hex: "#40E0D0", tags: ["light", "vibrant", "cool"] },
        { name: "Powder Blue", hex: "#B0E0E6", tags: ["light", "pastel", "cool"] },
        { name: "Pale Turquoise", hex: "#AFEEEE", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Light Cyan", hex: "#E0FFFF", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Azure Blue", hex: "#F0FFFF", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Gunmetal", hex: "#2C3539", tags: ["dark", "muted"] },
        { name: "Southern Blue", hex: "#0084C9", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Cerulean Blue", hex: "#0099CC", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Matte Blue", hex: "#3D80A0", tags: ["mid", "cool"] },
        { name: "Vivid Blue", hex: "#1BA1E2", tags: ["mid", "vibrant", "cool"] },
        { name: "Deep Sky Blue", hex: "#00BFFF", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Light Matte Blue", hex: "#73B6D6", tags: ["light", "cool"] },
        { name: "Sky Periwinkle", hex: "#66CCFF", tags: ["light", "neon", "vibrant", "pastel", "cool"] },
        { name: "Sky Blue", hex: "#87CEEB", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Light Blue", hex: "#ADD8E6", tags: ["light", "pastel", "cool"] },
        { name: "Twilight Blue", hex: "#010B15", tags: ["dark", "vibrant", "cool"] },
        { name: "Marine Blue", hex: "#05182B", tags: ["dark", "vibrant", "cool"] },
        { name: "Deep Sea Blue", hex: "#062343", tags: ["dark", "vibrant", "cool"] },
        { name: "Twilight Gray", hex: "#1E2A3A", tags: ["dark", "muted", "cool"] },
        { name: "Steel Navy", hex: "#1C3A5A", tags: ["dark", "cool"] },
        { name: "Arctic Blue", hex: "#03417B", tags: ["dark", "vibrant", "cool"] },
        { name: "Nokia Blue", hex: "#004C9A", tags: ["mid", "vibrant", "cool"] },
        { name: "Denim Blue", hex: "#1B4F8A", tags: ["mid", "vibrant", "cool"] },
        { name: "Cobalt Blue", hex: "#0047AB", tags: ["mid", "vibrant", "cool"] },
        { name: "Azure", hex: "#007ACC", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Steel Gray", hex: "#647487", tags: ["mid", "muted"] },
        { name: "Steel Blue", hex: "#4682B4", tags: ["mid", "cool"] },
        { name: "Slate Gray", hex: "#708090", tags: ["mid", "muted"] },
        { name: "Light Slate Gray", hex: "#778899", tags: ["mid", "muted"] },
        { name: "Dodger Blue", hex: "#1E90FF", tags: ["light", "neon", "vibrant", "cool"] },
        { name: "Cornflower Azure", hex: "#3385FF", tags: ["light", "neon", "vibrant", "cool"] },
        { name: "Light Sky Blue", hex: "#87CEFA", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Light Steel Blue", hex: "#B0C4DE", tags: ["light", "pastel", "cool"] },
        { name: "Alice Blue", hex: "#F0F8FF", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Ink Blue", hex: "#0A1540", tags: ["dark", "vibrant", "cool"] },
        { name: "Deep Navy", hex: "#001F5B", tags: ["dark", "vibrant", "cool"] },
        { name: "Atlantic Blue", hex: "#01145E", tags: ["dark", "vibrant", "cool"] },
        { name: "Deep Royal Blue", hex: "#1040C0", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Facebook Blue", hex: "#3B5998", tags: ["mid", "cool"] },
        { name: "Cobalt Electric", hex: "#0050EF", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Royal Blue", hex: "#4169E1", tags: ["light", "vibrant", "cool"] },
        { name: "Cornflower Blue", hex: "#6495ED", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Periwinkle", hex: "#7B96DC", tags: ["light", "pastel", "cool"] },
        { name: "Abyss", hex: "#050520", tags: ["dark", "vibrant", "cool"] },
        { name: "Rich Black", hex: "#0D0D1E", tags: ["dark", "cool"] },
        { name: "Pacific Blue", hex: "#010942", tags: ["dark", "vibrant", "cool"] },
        { name: "Navy", hex: "#000080", tags: ["mid", "vibrant", "cool"] },
        { name: "Midnight Blue", hex: "#191970", tags: ["mid", "vibrant", "cool"] },
        { name: "Dark Blue", hex: "#00008B", tags: ["mid", "vibrant", "cool"] },
        { name: "Medium Blue", hex: "#0000CD", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Midnight", hex: "#3A3ABF", tags: ["mid", "cool"] },
        { name: "Blue", hex: "#0000FF", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Lavender", hex: "#E6E6FA", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Ghost White", hex: "#F8F8FF", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Dark Slate Blue", hex: "#483D8B", tags: ["mid", "cool"] },
        { name: "Ultramarine", hex: "#3F00FF", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Slate Blue", hex: "#6A5ACD", tags: ["light", "cool"] },
        { name: "Medium Purple", hex: "#9370DB", tags: ["light", "cool"] },
        { name: "Medium Slate Blue", hex: "#7B68EE", tags: ["light", "vibrant", "pastel", "cool"] },
        { name: "Black Purple", hex: "#0B0111", tags: ["dark", "vibrant", "warm"] },
        { name: "Deep Indigo", hex: "#1A0033", tags: ["dark", "vibrant", "warm"] },
        { name: "Deep Dark Violet", hex: "#200040", tags: ["dark", "vibrant", "cool"] },
        { name: "Dusk Purple", hex: "#3A2A4A", tags: ["dark", "muted", "cool"] },
        { name: "Indigo", hex: "#4B0082", tags: ["mid", "vibrant", "warm"] },
        { name: "Electric Indigo", hex: "#6A00FF", tags: ["mid", "neon", "vibrant", "cool"] },
        { name: "Blue Violet", hex: "#8A2BE2", tags: ["mid", "vibrant", "warm"] },
        { name: "Lavender Purple", hex: "#B57FDC", tags: ["light", "pastel", "warm"] },
        { name: "Deep Purple", hex: "#1C0429", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Violet", hex: "#9400D3", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Electric Violet", hex: "#9600EC", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Dark Orchid", hex: "#9932CC", tags: ["mid", "vibrant", "warm"] },
        { name: "Vivid Purple", hex: "#A200FF", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Medium Orchid", hex: "#BA55D3", tags: ["light", "warm"] },
        { name: "Dark Plum", hex: "#300030", tags: ["dark", "vibrant", "warm"] },
        { name: "Purple", hex: "#800080", tags: ["mid", "vibrant", "warm"] },
        { name: "Dark Magenta", hex: "#8B008B", tags: ["mid", "vibrant", "warm"] },
        { name: "Mauve", hex: "#8A608A", tags: ["mid", "muted"] },
        { name: "Fuchsia", hex: "#FF00FF", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Orchid", hex: "#DA70D6", tags: ["light", "warm"] },
        { name: "Violet", hex: "#EE82EE", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Plum", hex: "#DDA0DD", tags: ["light", "pastel", "warm"] },
        { name: "Thistle", hex: "#D8BFD8", tags: ["light", "muted", "warm"] },
        { name: "Medium Violet Red", hex: "#C71585", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Pretty Pink", hex: "#F472D0", tags: ["light", "neon", "vibrant", "pastel", "warm"] },
        { name: "Eggplant Magenta", hex: "#18020E", tags: ["dark", "vibrant", "warm"] },
        { name: "Turnip Magenta", hex: "#2B0417", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Mauve", hex: "#3A1A2A", tags: ["dark", "warm"] },
        { name: "Hot Pink Alt", hex: "#D80073", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "T-Mobile Pink", hex: "#E30083", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Formal Magenta", hex: "#EC008C", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Rose", hex: "#E91E8C", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Deep Pink", hex: "#FF1493", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Petal Pink", hex: "#E671B8", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Hot Pink", hex: "#FF69B4", tags: ["light", "neon", "vibrant", "pastel", "warm"] },
        { name: "Dark Maroon", hex: "#4A0010", tags: ["dark", "vibrant", "warm"] },
        { name: "Dark Crimson", hex: "#5C0020", tags: ["dark", "vibrant", "warm"] },
        { name: "Crimson Dark", hex: "#800020", tags: ["mid", "vibrant", "warm"] },
        { name: "Nokia Red", hex: "#9A002C", tags: ["mid", "vibrant", "warm"] },
        { name: "Vodafone Red", hex: "#EF001F", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Crimson", hex: "#DC143C", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Vermilion", hex: "#FF1852", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Pale Violet Red", hex: "#DB7093", tags: ["light", "warm"] },
        { name: "Pink", hex: "#FFB6C1", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Pink Blush", hex: "#FFC0CB", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Lavender Blush", hex: "#FFF0F5", tags: ["light", "vibrant", "pastel", "warm"] },
        { name: "Virgin Mobile Red", hex: "#CC0001", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Dead Red", hex: "#E81123", tags: ["mid", "neon", "vibrant", "warm"] },
        { name: "Black", hex: "#000000", tags: ["neutral", "dark"] },
        { name: "Coal Gray", hex: "#090909", tags: ["neutral", "dark"] },
        { name: "Jet Black", hex: "#0A0A0A", tags: ["neutral", "dark"] },
        { name: "Onyx", hex: "#1A1A1A", tags: ["neutral", "dark"] },
        { name: "Storm Gray", hex: "#2B2A2A", tags: ["neutral", "dark"] },
        { name: "Graphite", hex: "#383838", tags: ["neutral", "mid"] },
        { name: "Dark Grey", hex: "#404040", tags: ["neutral", "mid"] },
        { name: "Dark", hex: "#555555", tags: ["neutral", "mid"] },
        { name: "Charcoal", hex: "#606060", tags: ["neutral", "mid"] },
        { name: "Dim Gray", hex: "#696969", tags: ["neutral", "mid"] },
        { name: "Gray", hex: "#808080", tags: ["neutral", "mid"] },
        { name: "Dark Gray", hex: "#A9A9A9", tags: ["neutral", "mid"] },
        { name: "Silver", hex: "#C0C0C0", tags: ["neutral", "mid"] },
        { name: "Light Gray", hex: "#D3D3D3", tags: ["neutral", "light"] },
        { name: "Gainsboro", hex: "#DCDCDC", tags: ["neutral", "light"] },
        { name: "Off White", hex: "#EEEEEE", tags: ["neutral", "light"] },
        { name: "White Smoke", hex: "#F5F5F5", tags: ["neutral", "light"] },
        { name: "White", hex: "#FFFFFF", tags: ["neutral", "light"] }
  ]
  // Interface Style — switches between UniKron and UniBlades themes
  property var interfaceStyles: ["UniKron", "UniBlades"]
  property string uiMode: mem("cfg.uiMode", "unikron")
  property int interfaceStyleIdx: uiMode === "uniblades" ? 1 : 0

  onInterfaceStyleIdxChanged: {
    var mode = interfaceStyleIdx === 1 ? "uniblades" : "unikron"
    uiMode = mode
    save("cfg.uiMode", mode)
  }

  property string currentAccentHex: {
    var i = Math.max(0, Math.min(accentColors.length - 1, accentFillIdx))
    return accentColors[i].hex
  }
  onCurrentAccentHexChanged: save("cfg.accentHex", currentAccentHex)

  property color currentAccentColor: {
    var i = Math.max(0, Math.min(accentColors.length - 1, accentFillIdx))
    var hex = accentColors[i].hex
    return Qt.rgba(
      parseInt(hex.substr(1,2),16)/255,
      parseInt(hex.substr(3,2),16)/255,
      parseInt(hex.substr(5,2),16)/255,
      Math.max(0.05, Math.min(1.0, 1.0 - accentTransparency / 100)))
  }
  property string currentAccentBorderHex: {
    var i = Math.max(0, Math.min(accentColors.length - 1, accentBorderIdx))
    return accentColors[i].hex
  }
  property string currentThemeFillHex: {
    var i = Math.max(0, Math.min(themeColors.length - 1, themeFillIdx))
    return themeColors[i].hex
  }
  onCurrentThemeFillHexChanged: save("cfg.themeHex", currentThemeFillHex)

  property string currentThemeBorderHex: {
    var i = Math.max(0, Math.min(themeColors.length - 1, themeBorderIdx))
    return themeColors[i].hex
  }
  // Computed theme fill as a color (with ifaceAlpha) — used by panel gradients
  property color currentThemeFillColor: {
    var i = Math.max(0, Math.min(themeColors.length - 1, themeFillIdx))
    var h = themeColors[i].hex
    var alpha = Math.max(0.05, Math.min(0.92, (1.0 - interfaceTransparency / 100) * 0.85))
    return Qt.rgba(parseInt(h.substr(1,2),16)/255, parseInt(h.substr(3,2),16)/255, parseInt(h.substr(5,2),16)/255, alpha)
  }

  // Pegasus
  property bool   pegasusSortAsc:        mem("cfg.peg.sortAsc",    "true")  === "true"
  property int    pegasusSortByIdx:      parseInt(mem("cfg.peg.sortBy",     "0"))
  property bool   pegasusGameLogos:      mem("cfg.peg.gameLogos",  "true")  === "true"
  property bool   pegasusVideoSnaps:     mem("cfg.peg.videoSnaps", "true")  === "true"
  property bool   pegasusVideoMute:      mem("cfg.peg.videoMute",  "false") === "true"
  property int    pegasusVideoDelayIdx:  parseInt(mem("cfg.peg.videoDelay", "1"))
  property bool   pegasusMetadata:       mem("cfg.peg.metadata",   "true")  === "true"
  property bool   pegasusScreenSaver:    mem("cfg.peg.screensaver","true")  === "true"
  property int    pegasusSSDelayIdx:     parseInt(mem("cfg.peg.ssdelay",    "2"))
  property bool   pegasusLaunchAnim:     mem("cfg.peg.launchanim", "true")  === "true"
  property bool   pegasusShowBackg:      mem("cfg.peg.showbg",     "true")  === "true"
  property bool   pegasusGridView:       mem("cfg.peg.gridview",   "false") === "true"
  property int    pegasusThumbQual:      parseInt(mem("cfg.peg.thumbqual",  "1"))

  // FIX: Label lists also moved from readonly property var to plain property var
  property var repeatDelayLabels: ["Slow", "Medium", "Fast"]
  property var regionLabels:      ["US", "EU", "JP", "AU", "UK"]
  property var ratingLabels:      ["E", "E10+", "T", "M", "AO"]
  property var panelAnimLabels:   ["Off", "Normal", "Fast"]
  property var sortByLabels:      ["Title", "Last Played", "Play Time", "Rating", "Release Date"]
  property var videoDelayLabels:  ["No Delay", "1 sec", "2 sec", "3 sec", "5 sec"]
  property var ssDelayLabels:     ["1 min", "3 min", "5 min", "10 min", "15 min", "30 min"]
  property var thumbQualLabels:   ["Low", "Medium", "High"]

  // ══ NAVIGATION ════════════════════════════════════════════════════
  property int catIndex: 0
  property int rowIndex: 0

  property var catLabels: [
    "🖥️ Display", "🕐 Time", "🔊 Audio", "🎮 Input", "📶 Network", "🔒 Parental", "🖌 Interface", "🐴 Pegasus", "📋 About"
  ]

  property var rows: buildRows(catIndex)

  function buildRows(cat) {
    if (cat === 0) return [
      { label: "Fullscreen",            type: "toggle",   key: "fullscreen"                           },
      { label: "Smooth Scaling",        type: "toggle",   key: "smoothScaling"                        },
      { label: "Background Type",       type: "cycle",    key: "bgTypeIdx",     options: bgTypeLabels  },
      { label: "Video Manager",         type: "action",   action: "videomanager", vidOnly: true        },
      { label: "Preview Video",         type: "action",   action: "previewvideo", vidOnly: true        },
      { label: "FPS Counter",           type: "header"                                                },
      { label: "Show FPS Counter",      type: "toggle",   key: "showFPS"                              },
      { label: "FPS on Dashboard",      type: "toggle",   key: "fpsOnDashboard"                       },
      { label: "FPS Color",             type: "colorpick",key: "fpsColorIdx",   colors: accentColors   },
      { label: "FPS Placement",         type: "placement",key: "fps"                                  }
    ]
    if (cat === 1) return [
      { label: "Show Clock",            type: "toggle",   key: "showClock"                            },
      { label: "24-Hour Clock",         type: "toggle",   key: "clockFormat24"                        },
      { label: "Use Skin Clock",        type: "toggle",   key: "useSkinClock"                         },
      { label: "Clock on Dashboard",    type: "toggle",   key: "clockOnDashboard"                     },
      { label: "Clock Placement",       type: "placement",key: "clock"                                },
      { label: "Clock Font Size",       type: "slider",   key: "clockFontSize",   min: 10, max: 48, step: 1  },
      { label: "Clock Opacity",         type: "slider",   key: "clockOpacityPct", min: 10, max: 100, step: 5 },
      { label: "Date",                  type: "header"                                                },
      { label: "Show Date",             type: "toggle",   key: "showDate"                             },
      { label: "Use Skin Date",         type: "toggle",   key: "useSkinDate"                          },
      { label: "Date on Dashboard",     type: "toggle",   key: "dateOnDashboard"                      },
      { label: "Date Format",           type: "cycle",    key: "dateFormatIdx",   options: dateFormatLabels },
      { label: "Date Placement",        type: "placement",key: "date"                                 },
      { label: "Date Font Size",        type: "slider",   key: "dateFontSize",    min: 10, max: 48, step: 1  },
      { label: "Date Opacity",          type: "slider",   key: "dateOpacityPct",  min: 10, max: 100, step: 5 }
    ]
    if (cat === 2) return [
      { label: "Mute All",              type: "toggle",   key: "muteAll"                              },
      { label: "Master Volume",         type: "slider",   key: "masterVolume",  min: 0, max: 100, step: 5  },
      { label: "Music Volume",          type: "slider",   key: "musicVolume",   min: 0, max: 100, step: 5  },
      { label: "SFX Volume",            type: "slider",   key: "sfxVolume",     min: 0, max: 100, step: 5  },
      { label: "UI Sounds",             type: "toggle",   key: "uiSounds"                             },
      { label: "Startup Sound",         type: "toggle",   key: "startupSound"                         },
      { label: "System Music",          type: "toggle",   key: "systemMusic"                          }
    ]
    if (cat === 3) return [
      { label: "Controller Vibration",  type: "toggle",   key: "vibration"                            },
      { label: "Repeat Delay",          type: "cycle",    key: "repeatDelayIdx",options: repeatDelayLabels },
      { label: "Mouse / Touch",         type: "toggle",   key: "mouseEnabled"                         },
      { label: "Swap A / B",            type: "toggle",   key: "swapAB"                               }
    ]
    if (cat === 4) return [
      { label: "📡 Online Features",    type: "toggle",   key: "onlineFeatures"                       },
      { label: "🔄 Check for Updates", type: "toggle",   key: "checkUpdates"                         },
      { label: "🌍 Region",            type: "cycle",    key: "region",        options: regionLabels, isString: true }
    ]
    if (cat === 5) return [
      { label: "Parental Controls",     type: "toggle",   key: "parentalEnabled"                      },
      { label: "Max Rating",            type: "cycle",    key: "ratingLimitIdx",options: ratingLabels  }
    ]
    if (cat === 6) return [
      { label: "Interface Style",         type: "cycle",         key: "interfaceStyleIdx",  options: interfaceStyles },
      { label: "Show Layout Badge",       type: "toggle",        key: "showLayoutBadge"                       },
      { label: "Panel Reflections",       type: "toggle",        key: "showPanelReflect"                      },
      { label: "Panel Animation",         type: "cycle",         key: "panelAnimIdx",       options: panelAnimLabels },
      { label: "Colors",                  type: "unicolorpanel"                                                },
      { label: "Reset Colors",            type: "action",           action: "resetcolors"                       }
    ]
    if (cat === 7) return [
      { label: "General",               type: "pegheader",  secKey: "_pegSecGeneral"    },
      { label: "Sort Games By",         type: "cycle",    key: "pegasusSortByIdx", options: sortByLabels,  sec: "_pegSecGeneral"  },
      { label: "Sort Ascending",        type: "toggle",   key: "pegasusSortAsc",                           sec: "_pegSecGeneral"  },
      { label: "Grid View Default",     type: "toggle",   key: "pegasusGridView",                          sec: "_pegSecGeneral"  },
      { label: "Show Backgrounds",      type: "toggle",   key: "pegasusShowBackg",                         sec: "_pegSecGeneral"  },
      { label: "Thumbnail Quality",     type: "cycle",    key: "pegasusThumbQual", options: thumbQualLabels, sec: "_pegSecGeneral" },
      { label: "Media",                 type: "pegheader",  secKey: "_pegSecMedia"      },
      { label: "Show Game Logos",       type: "toggle",   key: "pegasusGameLogos",                         sec: "_pegSecMedia"    },
      { label: "Video Snaps",           type: "toggle",   key: "pegasusVideoSnaps",                        sec: "_pegSecMedia"    },
      { label: "Mute Video Snaps",      type: "toggle",   key: "pegasusVideoMute",                         sec: "_pegSecMedia"    },
      { label: "Video Snap Delay",      type: "cycle",    key: "pegasusVideoDelayIdx", options: videoDelayLabels, sec: "_pegSecMedia" },
      { label: "Load Metadata",         type: "toggle",   key: "pegasusMetadata",                          sec: "_pegSecMedia"    },
      { label: "Movies",                type: "pegheader",  secKey: "_pegSecMovies"     },
      { label: "Movies Path",           type: "moviespath",                                                sec: "_pegSecMovies"   },
      { label: "Screen Saver",          type: "pegheader",  secKey: "_pegSecScreenSave" },
      { label: "Screen Saver",          type: "toggle",   key: "pegasusScreenSaver",                       sec: "_pegSecScreenSave" },
      { label: "Screen Saver Delay",    type: "cycle",    key: "pegasusSSDelayIdx", options: ssDelayLabels, sec: "_pegSecScreenSave" },
      { label: "System",                type: "pegheader",  secKey: "_pegSecSystem"     },
      { label: "Launch Animation",      type: "toggle",   key: "pegasusLaunchAnim",                        sec: "_pegSecSystem"   },
      { label: "Restart Pegasus",       type: "action",   action: "restart",                               sec: "_pegSecSystem"   },
      { label: "Quit to Desktop",       type: "action",   action: "quit",                                  sec: "_pegSecSystem"   }
    ]
    if (cat === 8) return [
      { label: "Theme",   type: "info", value: "🦄 UniKron"     },
      { label: "Version", type: "info", value: "🏷️ 1.0.0"       },
      { label: "Pegasus", type: "info", value: "🐴 alpha16"     },
      { label: "Qt",      type: "info", value: "⚙️ 5.15"        },
      { label: "Author",  type: "info", value: "🐰 Jackrabbit72380" }
    ]
    return []
  }

  onClockOpacityPctChanged: {
    clockTextOpacity = clockOpacityPct / 100.0
    save("cfg.clockOpacity", clockTextOpacity.toString())
  }

  onDateOpacityPctChanged: {
    dateTextOpacity = dateOpacityPct / 100.0
    save("cfg.dateOpacity", dateTextOpacity.toString())
  }

  // Mutual exclusion: useSkinDate / dateOnDashboard
  property bool _dateMutexBusy: false
  onUseSkinDateChanged: {
    if (_dateMutexBusy) return
    _dateMutexBusy = true
    if (useSkinDate && dateOnDashboard) {
      dateOnDashboard = false
      save("cfg.dateOnDash", "false")
    }
    save("cfg.useSkinDate", useSkinDate ? "true" : "false")
    _dateMutexBusy = false
  }
  onDateOnDashboardChanged: {
    if (_dateMutexBusy) return
    _dateMutexBusy = true
    if (dateOnDashboard && useSkinDate) {
      useSkinDate = false
      save("cfg.useSkinDate", "false")
    }
    save("cfg.dateOnDash", dateOnDashboard ? "true" : "false")
    _dateMutexBusy = false
  }

  // Mutual exclusion: only one of useSkinClock / clockOnDashboard active at a time
  property bool _clockMutexBusy: false
  onUseSkinClockChanged: {
    if (_clockMutexBusy) return
    _clockMutexBusy = true
    if (useSkinClock && clockOnDashboard) {
      clockOnDashboard = false
      save("cfg.clockOnDash", "false")
    }
    save("cfg.useSkinClock", useSkinClock ? "true" : "false")
    _clockMutexBusy = false
  }
  onClockOnDashboardChanged: {
    if (_clockMutexBusy) return
    _clockMutexBusy = true
    if (clockOnDashboard && useSkinClock) {
      useSkinClock = false
      save("cfg.useSkinClock", "false")
    }
    save("cfg.clockOnDash", clockOnDashboard ? "true" : "false")
    _clockMutexBusy = false
  }

  // ── Row helpers ───────────────────────────────────────────────────
  function rowVisible(row) {
    if (!row) return false
    if (row.type === "header") return true
    if (row.type === "pegheader") return true
    if (row.vidOnly && bgTypeIdx !== 2) return false
    // Hide rows belonging to a collapsed Pegasus section
    if (row.sec && !root[row.sec]) return false
    return true
  }
  function rowFocusable(row) {
    if (!row) return false
    if (row.type === "header") return false
    if (row.type === "pegheader") return true
    if (row.type === "unicolorpanel") return false
    if (row.type === "themecolorpick") return true
    if (row.type === "sliderWithArrows" || row.type === "sliderWithGrad") return true
    if (row.type === "colorpickWithGrad") return true
    if (row.type === "sliderWithGrad") return true
    return rowVisible(row)
  }
  function nextFocusable(from, dir) {
    var r = from + dir
    while (r >= 0 && r < rows.length) {
      if (rowFocusable(rows[r])) return r
      r += dir
    }
    return from
  }

  function rowValue(row) {
    if (!row || row.type === "header") return ""
    if (row.type === "toggle")    return root[row.key] ? "On" : "Off"
    if (row.type === "info")      return row.value || ""
    if (row.type === "action")    return "▶"
    if (row.type === "videopath") return (bgVideoPath || "").length > 0 ? bgVideoPath.split("/").pop() : "(not set)"
    if (row.type === "moviespath") return (moviesPath || "").length > 0 ? normPath(moviesPath) : "assets/movies"
    if (row.type === "slider" || row.type === "sliderWithArrows" || row.type === "sliderWithGrad") return root[row.key] + "%"
    if (row.type === "placement") {
      var px = row.key === "clock" ? clockPosX : row.key === "date" ? datePosX : fpsPosX
      var py = row.key === "clock" ? clockPosY : row.key === "date" ? datePosY : fpsPosY
      return Math.round(px * 100) + "%, " + Math.round(py * 100) + "%"
    }
    if (row.type === "colorpick" || row.type === "themecolorpick") {
      var list = row.colors
      var idx  = root[row.key]
      return (list && idx >= 0 && idx < list.length) ? list[idx].name : "—"
    }
    if (row.type === "colorpickWithGrad") {
      var listG = row.colors
      var idxG  = root[row.key]
      if (listG && idxG >= 0 && idxG < listG.length) {
        return listG[idxG].name + "  " + listG[idxG].hex.toUpperCase()
      }
      return "—"
    }
    if (row.type === "cycle") {
      if (row.isString)  return root[row.key]
      if (row.isNumeric) return root[row.key] + "%"
      var opts = row.options
      var ci   = root[row.key]
      return (opts && ci >= 0 && ci < opts.length) ? opts[ci] : "—"
    }
    return "—"
  }

  function activateRow(row) {
    if (!row || !rowFocusable(row)) return
    if (row.type === "pegheader") {
      root[row.secKey] = !root[row.secKey]
      return
    }
    if (row.type === "toggle") {
      root[row.key] = !root[row.key]
      var tKey = row.key
      if (tKey === "clockOnDashboard")  tKey = "clockOnDash"
      if (tKey === "clockFormat24")     tKey = "clock24"
      if (tKey === "fpsOnDashboard")    tKey = "fpsOnDash"
      if (tKey === "dateOnDashboard")   tKey = "dateOnDash"
      if (tKey === "useSkinDate")       tKey = "useSkinDate"
      if (tKey === "pegasusLaunchAnim") tKey = "peg.launchanim"
      save("cfg." + tKey, root[row.key] ? "true" : "false")
    } else if (row.type === "cycle") {
      if (row.isString) {
        var si = row.options.indexOf(root[row.key])
        root[row.key] = row.options[(si + 1) % row.options.length]
        save("cfg." + row.key, root[row.key])
      } else if (row.isNumeric) {
        var ni = row.options.indexOf(root[row.key])
        if (ni < 0) ni = 0
        var nv = row.options[(ni + 1) % row.options.length]
        root[row.key] = nv
        save("cfg." + row.key, nv.toString())
      } else {
        root[row.key] = (root[row.key] + 1) % row.options.length
        var cKey = row.key
        if (cKey === "dateFormatIdx") cKey = "dateFormat"
        save("cfg." + cKey, root[row.key].toString())
      }
    } else if (row.type === "colorpick" || row.type === "themecolorpick" || row.type === "colorpickWithGrad") {
      root[row.key] = (root[row.key] + 1) % row.colors.length
      save(colorSaveKey(row.key), root[row.key].toString())
    } else if (row.type === "moviespath") {
      moviesPathEditBuf = normPath(moviesPath) || "assets/movies"
      showMoviesPathEdit = true
    } else if (row.type === "action") {
      if (row.action === "quit")           showQuitConfirm = true
      else if (row.action === "restart")   Qt.quit()
      else if (row.action === "videomanager") showVideoManager = true
      else if (row.action === "resetcolors") {
        accentFillIdx         = 0;  save("cfg.accentFill",    "0")
        themeFillIdx          = 2;  save("cfg.themeFill",     "2")
        accentTransparency    = 0;  save("cfg.accentAlpha",   "0")
        interfaceTransparency = 80; save("cfg.ifaceAlpha",    "80")
        panelGradient         = true; save("cfg.panelGradient","true")
        gradAccentColor       = true; save("cfg.gradAccent",   "true")
        gradAccentOpacity     = true; save("cfg.gradAccentOp", "true")
        gradThemeColor        = true; save("cfg.gradTheme",    "true")
        gradThemeTransp       = true; save("cfg.gradThemeTr",  "true")
      }
      else if (row.action === "previewvideo") {
        // No dedicated video player page — open Video Manager so the user
        // can verify the active path. Set bgVideoPath first so it is visible.
        api.memory.set("cfg.bgVideoPath", normPath(bgVideoPath))
        showVideoManager = true
      }
    }
  }

  function adjustSlider(row, delta) {
    if (row.type !== "slider" && row.type !== "sliderWithArrows" && row.type !== "sliderWithGrad" && row.type !== "sliderWithGrad") return
    var v = Math.max(row.min, Math.min(row.max, root[row.key] + delta * (row.step || 5)))
    root[row.key] = v
    var saveKey = row.key
    if (saveKey === "interfaceTransparency") saveKey = "ifaceAlpha"
    if (saveKey === "accentTransparency")    saveKey = "accentAlpha"
    if (saveKey === "clockOpacityPct")       saveKey = "clockOpacity"
    if (saveKey === "dateOpacityPct")        saveKey = "dateOpacity"
    if (saveKey === "fpsTextOpacity")        saveKey = "fpsOpacity"
    save("cfg." + saveKey, v.toString())
  }
  function colorSaveKey(propKey) {
    if (propKey === "accentColorIdx")    return "cfg.accentColor"
    if (propKey === "accentBorderIdx")   return "cfg.accentBorder"
    if (propKey === "accentFillIdx")     return "cfg.accentFill"
    if (propKey === "themeColorIdx")     return "cfg.themeColor"
    if (propKey === "themeBorderIdx")    return "cfg.themeBorder"
    if (propKey === "themeFillIdx")      return "cfg.themeFill"
    if (propKey === "interfaceColorIdx") return "cfg.ifaceColor"
    return "cfg." + propKey
  }
  function cycleColor(row, delta) {
    var n = (root[row.key] + delta + row.colors.length) % row.colors.length
    root[row.key] = n
    save(colorSaveKey(row.key), n.toString())
  }
  function nudgePlacement(which, dx, dy) {
    var s = 0.005
    if (which === "clock") {
      clockPosX = Math.max(0, Math.min(0.99, clockPosX + dx * s))
      clockPosY = Math.max(0, Math.min(0.99, clockPosY + dy * s))
      save("cfg.clockPosX", clockPosX.toString())
      save("cfg.clockPosY", clockPosY.toString())
    } else if (which === "date") {
      datePosX = Math.max(0, Math.min(0.99, datePosX + dx * s))
      datePosY = Math.max(0, Math.min(0.99, datePosY + dy * s))
      save("cfg.datePosX", datePosX.toString())
      save("cfg.datePosY", datePosY.toString())
    } else {
      fpsPosX = Math.max(0, Math.min(0.99, fpsPosX + dx * s))
      fpsPosY = Math.max(0, Math.min(0.99, fpsPosY + dy * s))
      save("cfg.fpsPosX", fpsPosX.toString())
      save("cfg.fpsPosY", fpsPosY.toString())
    }
  }

  // ── Pegasus accordion section collapse states (true = expanded) ──
  property bool   _pegSecGeneral:    true
  property bool   _pegSecMedia:      true
  property bool   _pegSecMovies:     true
  property bool   _pegSecScreenSave: true
  property bool   _pegSecSystem:     true

  // Dialog state
  property bool   showQuitConfirm:     false
  property bool   showVideoManager:    false
  property bool   showMoviesPathEdit:  false
  property string moviesPathEditBuf:   ""
  property string placementEditorFor:  "clock"

  Component.onCompleted: {
    setAvailableActions({
      [Enums.ActionKeys.Bottom]: { label: "Select", visible: true },
      [Enums.ActionKeys.Right]:  { label: "Back",   visible: true }
    })
    rowIndex = nextFocusable(-1, 1)
  }

  // ════════════════════════════════════════════════════════════════
  // HEADER BAR
  // ════════════════════════════════════════════════════════════════
  Item {
    id: pageHeader
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: vpx(70)

    Row {
      anchors.left: parent.left
      anchors.leftMargin: vpx(40)
      anchors.verticalCenter: parent.verticalCenter
      spacing: vpx(10)

      StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: "⚙"; font.pixelSize: vpx(28); color: currentAccentColor; layer.enabled: false
      }
      Rectangle {
        width: vpx(4); height: vpx(30); radius: vpx(2); color: currentAccentColor
        anchors.verticalCenter: parent.verticalCenter
      }
      StyledText {
        id: titleLabel
        anchors.verticalCenter: parent.verticalCenter
        text: "Settings"; font.pixelSize: vpx(32); font.bold: true; layer.enabled: false
      }
      StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: catLabels[catIndex]
        font.pixelSize: vpx(32); font.bold: true
        color: currentAccentColor; layer.enabled: false
      }
    }

    // X Close button
    Rectangle {
      id: closeBtn
      width: vpx(38)
      height: vpx(38)
      radius: vpx(6)
      anchors.right: parent.right
      anchors.rightMargin: vpx(20)
      anchors.verticalCenter: parent.verticalCenter
      color: closeBtnMA.containsMouse ? "#CC993333" : "#44FFFFFF"
      border.color: closeBtnMA.containsMouse ? "#FF6666" : "#66FFFFFF"
      border.width: vpx(1)
      Behavior on color { ColorAnimation { duration: 80 } }

      StyledText {
        anchors.centerIn: parent
        text: "✕"
        font.pixelSize: vpx(17)
        font.bold: true
        color: closeBtnMA.containsMouse ? "#FFFFFF" : "#CCCCCC"
        layer.enabled: false
      }
      MouseArea {
        id: closeBtnMA
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: navigate(pages.library)
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // CATEGORY PANEL
  // ════════════════════════════════════════════════════════════════
  Rectangle {
    id: catPanel
    anchors.top: pageHeader.bottom
    anchors.left: parent.left
    anchors.leftMargin: vpx(40)
    anchors.bottom: parent.bottom
    anchors.bottomMargin: vpx(70)
    width: vpx(190)
    color: "transparent"
    radius: vpx(4)
    clip: true
    border.color: currentAccentColor
    border.width: vpx(1)

    // Solid base (shown when gradient is off)
    Rectangle {
      anchors.fill: parent; anchors.margins: vpx(1); radius: vpx(3)
      color: currentThemeFillColor
      visible: !panelGradient
    }
    // Theme Color gradient
    LinearGradient {
      visible: panelGradient && gradThemeColor
      anchors.fill: parent
      start: Qt.point(0, 0); end: Qt.point(width, height)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(currentThemeFillColor.r, currentThemeFillColor.g, currentThemeFillColor.b, 0.97) }
        GradientStop { position: 0.6; color: Qt.rgba(currentThemeFillColor.r * 0.7, currentThemeFillColor.g * 0.7, currentThemeFillColor.b * 0.7, 0.97) }
        GradientStop { position: 1.0; color: Qt.rgba(currentThemeFillColor.r * 0.5, currentThemeFillColor.g * 0.5, currentThemeFillColor.b * 0.5, 0.97) }
      }
    }
    // Theme Transparency gradient
    LinearGradient {
      visible: panelGradient && gradThemeTransp
      anchors.fill: parent
      start: Qt.point(0, height); end: Qt.point(0, 0)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.18) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
      }
    }
    // Accent Color gradient
    LinearGradient {
      visible: panelGradient && gradAccentColor
      anchors.fill: parent
      start: Qt.point(0, 0); end: Qt.point(width, 0)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(currentAccentColor.r, currentAccentColor.g, currentAccentColor.b, 0.12) }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }
    // Accent Opacity gradient
    LinearGradient {
      visible: panelGradient && gradAccentOpacity
      anchors.fill: parent
      start: Qt.point(0, 0); end: Qt.point(0, height)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(currentAccentColor.r, currentAccentColor.g, currentAccentColor.b, 0.08) }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }

    Column {
      anchors.fill: parent
      anchors.margins: vpx(4)
      spacing: vpx(2)

      Repeater {
        model: catLabels
        delegate: Rectangle {
          property bool active: index === catIndex
          width: catPanel.width - vpx(8)
          height: vpx(42)
          radius: vpx(3)
          color: active ? currentAccentColor : (catHover.containsMouse ? "#22FFFFFF" : "transparent")
          Behavior on color { ColorAnimation { duration: 80 } }

          StyledText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: vpx(14)
            text: modelData
            font.pixelSize: vpx(16)
            font.bold: active
            layer.enabled: false
          }
          MouseArea {
            id: catHover
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
              catIndex = index
              rowIndex = nextFocusable(-1, 1)
              root.forceActiveFocus()
            }
          }
        }
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // ROW PANEL
  // ════════════════════════════════════════════════════════════════
  Rectangle {
    id: rowPanel
    anchors.top: pageHeader.bottom
    anchors.left: catPanel.right
    anchors.leftMargin: vpx(10)
    anchors.right: parent.right
    anchors.rightMargin: vpx(40)
    anchors.bottom: parent.bottom
    anchors.bottomMargin: vpx(70)
    color: "transparent"
    radius: vpx(4)
    clip: true
    border.color: currentAccentColor
    border.width: vpx(1)

    // Solid base (shown when gradient is off)
    Rectangle {
      anchors.fill: parent; anchors.margins: vpx(1); radius: vpx(3)
      color: currentThemeFillColor
      visible: !panelGradient
    }
    // Theme Color gradient
    LinearGradient {
      visible: panelGradient && gradThemeColor
      anchors.fill: parent
      start: Qt.point(0, 0); end: Qt.point(width, height)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(currentThemeFillColor.r, currentThemeFillColor.g, currentThemeFillColor.b, 0.97) }
        GradientStop { position: 0.6; color: Qt.rgba(currentThemeFillColor.r * 0.7, currentThemeFillColor.g * 0.7, currentThemeFillColor.b * 0.7, 0.97) }
        GradientStop { position: 1.0; color: Qt.rgba(currentThemeFillColor.r * 0.5, currentThemeFillColor.g * 0.5, currentThemeFillColor.b * 0.5, 0.97) }
      }
    }
    // Theme Transparency gradient
    LinearGradient {
      visible: panelGradient && gradThemeTransp
      anchors.fill: parent
      start: Qt.point(0, height); end: Qt.point(0, 0)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.18) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
      }
    }
    // Accent Color gradient
    LinearGradient {
      visible: panelGradient && gradAccentColor
      anchors.fill: parent
      start: Qt.point(0, 0); end: Qt.point(width, 0)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(currentAccentColor.r, currentAccentColor.g, currentAccentColor.b, 0.12) }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }
    // Accent Opacity gradient
    LinearGradient {
      visible: panelGradient && gradAccentOpacity
      anchors.fill: parent
      start: Qt.point(0, 0); end: Qt.point(0, height)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(currentAccentColor.r, currentAccentColor.g, currentAccentColor.b, 0.08) }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }

    ListView {
      id: rowList
      anchors.fill: parent
      anchors.margins: vpx(8)
      model: rows
      currentIndex: rowIndex
      clip: true
      interactive: true
      highlightMoveDuration: 100
      highlightFollowsCurrentItem: true

      highlight: Item { height: vpx(54) }

      delegate: Item {
        id: rowItem
        width: rowList.width
        height: {
          if (!rowVisible(modelData)) return 0
          if (modelData.type === "header") return vpx(34)
          if (modelData.type === "pegheader") return vpx(38)
          if (modelData.type === "unicolorpanel") return unicolorEmbed.height + vpx(8)
          return vpx(54)
        }
        clip: false
        visible: height > 0

        // ── Unicolor embedded panel ───────────────────────────────
        Loader {
          id: unicolorEmbed
          active: modelData.type === "unicolorpanel"
          visible: active
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: vpx(4)
          height: item ? item.implicitHeight : 0
          sourceComponent: active ? unicolorComponent : null
        }

        // Selection highlight — always exactly one row tall
        Rectangle {
          visible: index === rowIndex && modelData.type !== "header" && modelData.type !== "pegheader" && modelData.type !== "unicolorpanel"
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          height: vpx(54)
          color: Qt.rgba(
            currentAccentColor.r,
            currentAccentColor.g,
            currentAccentColor.b,
            0.18)
          radius: vpx(3)
          border.color: currentAccentColor
          border.width: vpx(1)
        }

        // ── Pegasus accordion section header ─────────────────────
        Rectangle {
          visible: modelData.type === "pegheader"
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          height: vpx(38)
          radius: vpx(4)
          color: Qt.rgba(currentAccentColor.r, currentAccentColor.g, currentAccentColor.b,
                         index === rowIndex ? 0.28 : 0.18)
          Behavior on color { ColorAnimation { duration: 80 } }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: vpx(10)
            anchors.rightMargin: vpx(10)
            spacing: vpx(8)
            // Accent left bar
            Rectangle {
              width: vpx(3); height: vpx(18); radius: vpx(2)
              color: currentAccentColor
            }
            StyledText {
              Layout.fillWidth: true
              text: modelData.label
              font.pixelSize: vpx(13)
              font.bold: true
              color: currentAccentColor
              layer.enabled: false
            }
            StyledText {
              text: (modelData.secKey && root[modelData.secKey]) ? "▲" : "▼"
              font.pixelSize: vpx(11)
              color: currentAccentColor
              layer.enabled: false
            }
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (modelData.secKey) root[modelData.secKey] = !root[modelData.secKey]
              rowIndex = index
              root.forceActiveFocus()
            }
          }
        }

        // ── Classic section header divider (non-Pegasus headers) ──
        Item {
          visible: modelData.type === "header"
          anchors.fill: parent

          // Divider line sits BELOW the label block
          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: vpx(8)
            anchors.rightMargin: vpx(8)
            height: vpx(1)
            color: "#2AFFFFFF"
          }
          Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: vpx(12)
            anchors.top: parent.top
            anchors.topMargin: vpx(6)
            color: "transparent"
            height: vpx(22)
            width: hdrLbl.width + vpx(12)

            StyledText {
              id: hdrLbl
              anchors.centerIn: parent
              text: modelData.label
              font.pixelSize: vpx(12)
              font.bold: true
              color: currentAccentColor
              layer.enabled: false
            }
          }
        }

        // Row separator line
        Rectangle {
          visible: modelData.type !== "header" && modelData.type !== "pegheader" && modelData.type !== "unicolorpanel"
          color: "#18FFFFFF"
          height: vpx(1)
          width: parent.width
          anchors.bottom: parent.bottom
        }

        // ══ STANDARD ROW ═════════════════════════════════════════
        // Always shown (label + arrows always visible); value text/swatch hidden when expanded
        RowLayout {
          visible: modelData.type !== "header" && modelData.type !== "pegheader" && modelData.type !== "unicolorpanel"
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: vpx(16)
          anchors.rightMargin: vpx(16)
          height: vpx(54)
          spacing: vpx(10)

          // Label
          StyledText {
            Layout.fillWidth: true
            text: (modelData.type !== "header" && modelData.type !== "pegheader") ? modelData.label : ""
            font.pixelSize: vpx(16)
            opacity: (modelData.type === "action") ? (index === rowIndex ? 1.0 : 0.65) : 1.0
            layer.enabled: false
          }

          // Slider track (plain slider OR sliderWithArrows)
          Item {
            id: sliderTrackItem
            visible: modelData.type === "slider" || modelData.type === "sliderWithArrows" || modelData.type === "sliderWithGrad"
            Layout.preferredWidth: vpx(200)
            height: vpx(28)
            Layout.alignment: Qt.AlignVCenter

            property var  slRow:  modelData
            property real slMin:  modelData.min  !== undefined ? modelData.min  : 0
            property real slMax:  modelData.max  !== undefined ? modelData.max  : 100
            property real slStep: modelData.step !== undefined ? modelData.step : 5

            function sliderSetFromX(mx) {
              var frac = Math.max(0, Math.min(1, mx / trackBg.width))
              var raw  = slMin + frac * (slMax - slMin)
              var snapped = Math.round(raw / slStep) * slStep
              var v = Math.max(slMin, Math.min(slMax, snapped))
              root[slRow.key] = v
              var saveKey = slRow.key
              if (saveKey === "interfaceTransparency") saveKey = "ifaceAlpha"
              if (saveKey === "accentTransparency")    saveKey = "accentAlpha"
              if (saveKey === "clockOpacityPct")       saveKey = "clockOpacity"
              if (saveKey === "dateOpacityPct")        saveKey = "dateOpacity"
              if (saveKey === "fpsTextOpacity")        saveKey = "fpsOpacity"
              save("cfg." + saveKey, v.toString())
            }

            Rectangle {
              id: trackBg
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.right: parent.right
              height: vpx(8)
              color: "#3CFFFFFF"
              radius: vpx(4)

              Rectangle {
                width: {
                  var rng = Math.max(1, sliderTrackItem.slMax - sliderTrackItem.slMin)
                  return parent.width * Math.max(0, Math.min(1,
                    (root[sliderTrackItem.slRow.key] - sliderTrackItem.slMin) / rng))
                }
                height: parent.height
                color: currentAccentColor
                radius: vpx(4)
                Behavior on width { NumberAnimation { duration: 60 } }
              }

              Rectangle {
                x: {
                  var rng = Math.max(1, sliderTrackItem.slMax - sliderTrackItem.slMin)
                  return (trackBg.width - vpx(14)) * Math.max(0, Math.min(1,
                    (root[sliderTrackItem.slRow.key] - sliderTrackItem.slMin) / rng))
                }
                anchors.verticalCenter: parent.verticalCenter
                width: vpx(14); height: vpx(14); radius: vpx(7)
                color: "#FFFFFF"
                border.color: currentAccentColor; border.width: vpx(2)
                Behavior on x { NumberAnimation { duration: 60 } }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.SizeHorCursor
              preventStealing: true
              onPressed:  sliderTrackItem.sliderSetFromX(mouse.x)
              onPositionChanged: { if (pressed) sliderTrackItem.sliderSetFromX(mouse.x) }
              onClicked: {
                rowIndex = index
                root.forceActiveFocus()
              }
            }
          }

          // ◀ arrow for sliderWithArrows
          Rectangle {
            id: slPrevBtn
            visible: modelData.type === "sliderWithArrows" || modelData.type === "sliderWithGrad"
            width: vpx(28); height: vpx(28); radius: vpx(5)
            property bool hov: false
            color: hov ? currentAccentColor : (index === rowIndex ? "#44FFFFFF" : "#1AFFFFFF")
            border.color: index === rowIndex ? currentAccentColor : "#22FFFFFF"; border.width: vpx(1)
            Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { anchors.centerIn: parent; text: "◀"; font.pixelSize: vpx(13); opacity: index === rowIndex ? 1.0 : 0.4; layer.enabled: false }
            MouseArea {
              anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onEntered: slPrevBtn.hov = true
              onExited:  slPrevBtn.hov = false
              onClicked: { adjustSlider(modelData, -1); rowIndex = index; root.forceActiveFocus() }
            }
          }

          // ▶ arrow for sliderWithArrows
          Rectangle {
            id: slNextBtn
            visible: modelData.type === "sliderWithArrows" || modelData.type === "sliderWithGrad"
            width: vpx(28); height: vpx(28); radius: vpx(5)
            property bool hov: false
            color: hov ? currentAccentColor : (index === rowIndex ? "#44FFFFFF" : "#1AFFFFFF")
            border.color: index === rowIndex ? currentAccentColor : "#22FFFFFF"; border.width: vpx(1)
            Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { anchors.centerIn: parent; text: "▶"; font.pixelSize: vpx(13); opacity: index === rowIndex ? 1.0 : 0.4; layer.enabled: false }
            MouseArea {
              anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onEntered: slNextBtn.hov = true
              onExited:  slNextBtn.hov = false
              onClicked: { adjustSlider(modelData, 1); rowIndex = index; root.forceActiveFocus() }
            }
          }

          // Placement mini-map
          Rectangle {
            visible: modelData.type === "placement"
            width: vpx(44)
            height: vpx(26)
            radius: vpx(3)
            color: "#33FFFFFF"
            border.color: "#55FFFFFF"
            border.width: vpx(1)

            Rectangle {
              width: vpx(6); height: vpx(6); radius: vpx(3)
              color: currentAccentColor
              x: (parent.width  - vpx(6)) * (modelData.key === "clock" ? clockPosX : modelData.key === "date" ? datePosX : fpsPosX)
              y: (parent.height - vpx(6)) * (modelData.key === "clock" ? clockPosY : modelData.key === "date" ? datePosY : fpsPosY)
            }
          }

          // Value text — always visible including when color grid is open
          StyledText {
            visible: true
            text: rowValue(modelData)
            font.pixelSize: vpx(15)
            font.bold: modelData.type !== "info"
            color: {
              if (modelData.type === "toggle")
                return root[modelData.key] ? currentAccentColor : "#777777"
              if (modelData.type === "action")
                return modelData.action === "quit" ? "#FF6666" : "#FFAA44"
              if (modelData.type === "colorpick") return currentAccentColor
              if (modelData.type === "themecolorpick") return currentThemeFillHex
              if (modelData.type === "colorpickWithGrad") return modelData.key === "themeFillIdx" ? currentThemeFillHex : currentAccentColor
              return "#CCCCCC"
            }
            elide: Text.ElideRight
            Layout.maximumWidth: vpx(180)
            layer.enabled: false
          }

          // Swatch — accent border ring + selected fill colour, always visible
          Item {
            visible: modelData.type === "colorpick" || modelData.type === "themecolorpick" || modelData.type === "colorpickWithGrad"
            width: vpx(30); height: vpx(30)
            // Border ring
            Rectangle {
              anchors.fill: parent; radius: vpx(6)
              color: "transparent"
              border.color: (modelData.type === "themecolorpick" || (modelData.type === "colorpickWithGrad" && modelData.key === "themeFillIdx")) ? currentThemeFillHex : currentAccentColor
              border.width: vpx(2)
            }
            // Fill
            Rectangle {
              anchors.fill: parent; anchors.margins: vpx(3); radius: vpx(4)
              color: {
                if (!modelData.colors) return "#444444"
                var ci = root[modelData.key]
                return (ci !== undefined && ci >= 0 && ci < modelData.colors.length)
                       ? modelData.colors[ci].hex : "#444444"
              }
            }
          }

          // ◀ button
          Rectangle {
            visible: modelData.type === "cycle" || modelData.type === "colorpick" || modelData.type === "themecolorpick" || modelData.type === "colorpickWithGrad"
            width: vpx(28); height: vpx(28); radius: vpx(5)
            property color rowAccent: modelData.type === "themecolorpick" ? currentThemeFillHex : currentAccentColor
            color: prevBtnMA.containsMouse ? rowAccent : (index === rowIndex ? "#44FFFFFF" : "#1AFFFFFF")
            border.color: index === rowIndex ? rowAccent : "#22FFFFFF"; border.width: vpx(1)
            Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { anchors.centerIn: parent; text: "◀"; font.pixelSize: vpx(13); opacity: index === rowIndex ? 1.0 : 0.4; layer.enabled: false }
            MouseArea {
              id: prevBtnMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (modelData.type === "colorpick" || modelData.type === "themecolorpick" || modelData.type === "colorpickWithGrad") cycleColor(modelData, -1)
                else if (modelData.type === "cycle") {
                  if (modelData.isString) {
                    var si = modelData.options.indexOf(root[modelData.key])
                    root[modelData.key] = modelData.options[(si - 1 + modelData.options.length) % modelData.options.length]
                    save("cfg." + modelData.key, root[modelData.key])
                  } else if (modelData.isNumeric) {
                    var nip = modelData.options.indexOf(root[modelData.key])
                    if (nip < 0) nip = 0
                    var nvp = modelData.options[(nip - 1 + modelData.options.length) % modelData.options.length]
                    root[modelData.key] = nvp
                    save("cfg." + modelData.key, nvp.toString())
                  } else {
                    root[modelData.key] = (root[modelData.key] - 1 + modelData.options.length) % modelData.options.length
                    save("cfg." + modelData.key, root[modelData.key].toString())
                  }
                }
                root.forceActiveFocus()
              }
            }
          }

          // ▶ button
          Rectangle {
            visible: modelData.type === "cycle" || modelData.type === "colorpick" || modelData.type === "themecolorpick" || modelData.type === "colorpickWithGrad"
            width: vpx(28); height: vpx(28); radius: vpx(5)
            property color rowAccent: modelData.type === "themecolorpick" ? currentThemeFillHex : currentAccentColor
            color: nextBtnMA.containsMouse ? rowAccent : (index === rowIndex ? "#44FFFFFF" : "#1AFFFFFF")
            border.color: index === rowIndex ? rowAccent : "#22FFFFFF"; border.width: vpx(1)
            Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { anchors.centerIn: parent; text: "▶"; font.pixelSize: vpx(13); opacity: index === rowIndex ? 1.0 : 0.4; layer.enabled: false }
            MouseArea {
              id: nextBtnMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (modelData.type === "colorpick" || modelData.type === "themecolorpick" || modelData.type === "colorpickWithGrad") cycleColor(modelData, 1)
                else if (modelData.type === "cycle") {
                  if (modelData.isString) {
                    var si2 = modelData.options.indexOf(root[modelData.key])
                    root[modelData.key] = modelData.options[(si2 + 1) % modelData.options.length]
                    save("cfg." + modelData.key, root[modelData.key])
                  } else if (modelData.isNumeric) {
                    var nin = modelData.options.indexOf(root[modelData.key])
                    if (nin < 0) nin = 0
                    var nvn = modelData.options[(nin + 1) % modelData.options.length]
                    root[modelData.key] = nvn
                    save("cfg." + modelData.key, nvn.toString())
                  } else {
                    root[modelData.key] = (root[modelData.key] + 1) % modelData.options.length
                    save("cfg." + modelData.key, root[modelData.key].toString())
                  }
                }
                root.forceActiveFocus()
              }
            }
          }

          // ── Gradient checkbox (colorpickWithGrad and sliderWithGrad only) ──
          Row {
            visible: modelData.type === "colorpickWithGrad" || modelData.type === "sliderWithGrad"
            spacing: vpx(8)
            Layout.alignment: Qt.AlignVCenter

            // "Gradient" label
            StyledText {
              anchors.verticalCenter: parent.verticalCenter
              text: "Gradient"
              font.pixelSize: vpx(15)
              color: modelData.gradKey && root[modelData.gradKey] ? currentAccentColor : "#555555"
              layer.enabled: false
            }

            // Checkbox
            Rectangle {
              id: gradCheckBox
              anchors.verticalCenter: parent.verticalCenter
              width: vpx(22); height: vpx(22); radius: vpx(4)
              property bool gradOn: modelData.gradKey ? root[modelData.gradKey] : false
              color: gradOn ? currentAccentColor : "#222222"
              border.color: gradOn ? currentAccentColor : "#555555"
              border.width: vpx(1)
              Behavior on color { ColorAnimation { duration: 80 } }

              StyledText {
                anchors.centerIn: parent
                text: "✓"
                font.pixelSize: vpx(13)
                font.bold: true
                color: "#FFFFFF"
                visible: gradCheckBox.gradOn
                layer.enabled: false
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (modelData.gradKey && modelData.gradSave) {
                    root[modelData.gradKey] = !root[modelData.gradKey]
                    save(modelData.gradSave, root[modelData.gradKey] ? "true" : "false")
                  }
                  rowIndex = index
                  root.forceActiveFocus()
                }
              }
            }
          }
        }  // RowLayout
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          propagateComposedEvents: true

          onClicked: {
            var row = rows[index]
            if (!rowFocusable(row)) {
              mouse.accepted = false
              return
            }
            rowIndex = index
            root.forceActiveFocus()

            if (row.type === "colorpick" || row.type === "themecolorpick" || row.type === "colorpickWithGrad") {
              mouse.accepted = false
              return
            }
            if (row.type === "placement") {
              placementEditorFor = row.key
              placementEditor.which = row.key
              if (row.key === "clock") {
                placementEditor.posX = clockPosX; placementEditor.posY = clockPosY
                placementEditor.fontSize = clockFontSize; placementEditor.textOpacity = clockTextOpacity
                placementEditor.edgePadding = clockEdgePad; placementEditor.presets = clockPresets
              } else if (row.key === "date") {
                placementEditor.posX = datePosX; placementEditor.posY = datePosY
                placementEditor.fontSize = dateFontSize; placementEditor.textOpacity = dateTextOpacity
                placementEditor.edgePadding = dateEdgePad; placementEditor.presets = datePresets
              } else {
                placementEditor.posX = fpsPosX; placementEditor.posY = fpsPosY
                placementEditor.fontSize = fpsFontSize; placementEditor.textOpacity = fpsTextOpacity
                placementEditor.edgePadding = fpsEdgePad; placementEditor.presets = fpsPresets
              }
              placementEditor.visible = true
              placementEditor.forceActiveFocus()
              mouse.accepted = true
              return
            }
            if (row.type !== "slider" && row.type !== "sliderWithArrows" && row.type !== "sliderWithGrad") {
              activateRow(row)
              mouse.accepted = true
            } else {
              mouse.accepted = false
            }
          }
        }

      } // delegate
    } // ListView


  } // rowPanel

  // ════════════════════════════════════════════════════════════════
  // VIDEO MANAGER DIALOG
  // ════════════════════════════════════════════════════════════════
  Rectangle {
    id: videoManagerOverlay
    anchors.fill: parent
    color: "#D0000000"
    visible: showVideoManager
    z: 150

    function accentRgba(a) {
      return Qt.rgba(
        parseInt(currentAccentHex.substr(1,2),16)/255,
        parseInt(currentAccentHex.substr(3,2),16)/255,
        parseInt(currentAccentHex.substr(5,2),16)/255, a)
    }

    MouseArea {
      anchors.fill: parent
      onClicked: { showVideoManager = false; root.forceActiveFocus() }
    }

    Rectangle {
      id: vmPanel
      anchors.centerIn: parent
      width: vpx(760)
      height: vpx(560)
      color: "#1A1A2E"
      radius: vpx(10)
      border.color: currentAccentHex
      border.width: vpx(2)
      clip: true

      MouseArea { anchors.fill: parent }

      Rectangle {
        id: vmTitleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: vpx(50)
        color: videoManagerOverlay.accentRgba(0.25)
        radius: vpx(10)
        Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: vpx(10); color: parent.color }

        StyledText {
          anchors.left: parent.left; anchors.leftMargin: vpx(20)
          anchors.verticalCenter: parent.verticalCenter
          text: "Video Background Manager"
          font.pixelSize: vpx(20); font.bold: true
          layer.enabled: false
        }

        Rectangle {
          anchors.right: parent.right; anchors.rightMargin: vpx(12)
          anchors.verticalCenter: parent.verticalCenter
          width: vpx(32); height: vpx(32); radius: vpx(6)
          color: vmCloseMA.containsMouse ? "#CC993333" : "#44FFFFFF"
          border.color: vmCloseMA.containsMouse ? "#FF6666" : "#44FFFFFF"
          border.width: vpx(1)
          StyledText { anchors.centerIn: parent; text: "✕"; font.pixelSize: vpx(15); font.bold: true; layer.enabled: false }
          MouseArea {
            id: vmCloseMA
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
            onClicked: { showVideoManager = false; root.forceActiveFocus() }
          }
        }
      }

      Flickable {
        id: vmFlick
        anchors.top: vmTitleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: vmFooter.top
        anchors.margins: vpx(4)
        contentHeight: vmContent.height
        clip: true
        flickableDirection: Flickable.VerticalFlick

        Column {
          id: vmContent
          width: vmFlick.width
          spacing: vpx(0)

          // File Types section header
          Item {
            width: parent.width; height: vpx(36)
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: vpx(16); anchors.rightMargin: vpx(16); height: vpx(1); color: "#33FFFFFF" }
            Rectangle { anchors.left: parent.left; anchors.leftMargin: vpx(16); anchors.verticalCenter: parent.verticalCenter; color: "#1A1A2E"; height: vpx(24); width: ftSecLabel.width + vpx(10)
              StyledText { id: ftSecLabel; anchors.centerIn: parent; text: "FILE TYPES"; font.pixelSize: vpx(11); font.bold: true; color: currentAccentHex; layer.enabled: false } }
          }

          Repeater {
            model: [
              { label: ".mp4",  key: "vtMp4",  desc: "MPEG-4 Video" },
              { label: ".webm", key: "vtWebm", desc: "WebM Video (VP8/VP9)" },
              { label: ".mkv",  key: "vtMkv",  desc: "Matroska Video" },
              { label: ".avi",  key: "vtAvi",  desc: "AVI Video" },
              { label: ".mov",  key: "vtMov",  desc: "QuickTime Movie" }
            ]
            delegate: Rectangle {
              width: vmContent.width; height: vpx(48)
              color: ftRowMA.containsMouse ? "#18FFFFFF" : "transparent"

              RowLayout {
                anchors.fill: parent; anchors.leftMargin: vpx(20); anchors.rightMargin: vpx(20); spacing: vpx(14)
                Rectangle {
                  width: vpx(22); height: vpx(22); radius: vpx(4)
                  color: root[modelData.key] ? currentAccentHex : "#22FFFFFF"
                  border.color: root[modelData.key] ? currentAccentHex : "#55FFFFFF"; border.width: vpx(1)
                  Behavior on color { ColorAnimation { duration: 80 } }
                  StyledText { anchors.centerIn: parent; text: root[modelData.key] ? "✔" : ""; font.pixelSize: vpx(13); color: "#FFFFFF"; layer.enabled: false }
                }
                StyledText { text: modelData.label; font.pixelSize: vpx(16); font.bold: true; color: root[modelData.key] ? "#FFFFFF" : "#888888"; Layout.preferredWidth: vpx(72); layer.enabled: false }
                StyledText { Layout.fillWidth: true; text: modelData.desc; font.pixelSize: vpx(14); color: root[modelData.key] ? "#AAAAAA" : "#555555"; layer.enabled: false }
                StyledText { text: root[modelData.key] ? "Enabled" : "Disabled"; font.pixelSize: vpx(13); font.bold: true; color: root[modelData.key] ? currentAccentHex : "#555555"; layer.enabled: false }
              }
              Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: vpx(16); anchors.rightMargin: vpx(16); height: vpx(1); color: "#14FFFFFF" }
              MouseArea { id: ftRowMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                onClicked: { root[modelData.key] = !root[modelData.key]; save("cfg." + modelData.key, root[modelData.key] ? "true" : "false") } }
            }
          }

          // Search Folders section header
          Item {
            width: parent.width; height: vpx(36)
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: vpx(16); anchors.rightMargin: vpx(16); height: vpx(1); color: "#33FFFFFF" }
            Rectangle { anchors.left: parent.left; anchors.leftMargin: vpx(16); anchors.verticalCenter: parent.verticalCenter; color: "#1A1A2E"; height: vpx(24); width: sfSecLabel.width + vpx(10)
              StyledText { id: sfSecLabel; anchors.centerIn: parent; text: "SEARCH FOLDERS  (1 level deep)"; font.pixelSize: vpx(11); font.bold: true; color: currentAccentHex; layer.enabled: false } }
          }

          StyledText { anchors.left: parent.left; anchors.leftMargin: vpx(20); text: "Windows paths (C:\\Videos\\Background) and forward slashes both work."; font.pixelSize: vpx(12); color: "#667788"; bottomPadding: vpx(6); layer.enabled: false }

          Repeater {
            model: [
              { slot: 1, pathKey: "videoFolder1", enableKey: "videoFolder1En" },
              { slot: 2, pathKey: "videoFolder2", enableKey: "videoFolder2En" },
              { slot: 3, pathKey: "videoFolder3", enableKey: "videoFolder3En" },
              { slot: 4, pathKey: "videoFolder4", enableKey: "videoFolder4En" },
              { slot: 5, pathKey: "videoFolder5", enableKey: "videoFolder5En" }
            ]
            delegate: Rectangle {
              id: folderSlot
              property var slotData: modelData
              width: vmContent.width; height: vpx(62); color: "transparent"
              Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: vpx(16); anchors.rightMargin: vpx(16); height: vpx(1); color: "#14FFFFFF" }
              RowLayout {
                anchors.fill: parent; anchors.leftMargin: vpx(16); anchors.rightMargin: vpx(16); anchors.topMargin: vpx(8); anchors.bottomMargin: vpx(8); spacing: vpx(10)
                Rectangle {
                  width: vpx(24); height: vpx(24); radius: vpx(4)
                  color: root[slotData.enableKey] ? currentAccentHex : "#22FFFFFF"
                  border.color: root[slotData.enableKey] ? currentAccentHex : "#55FFFFFF"; border.width: vpx(1)
                  Behavior on color { ColorAnimation { duration: 80 } }
                  StyledText { anchors.centerIn: parent; text: root[slotData.enableKey] ? "✔" : ""; font.pixelSize: vpx(13); color: "#FFFFFF"; layer.enabled: false }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { root[slotData.enableKey] = !root[slotData.enableKey]; save("cfg." + slotData.enableKey, root[slotData.enableKey] ? "true" : "false") } }
                }
                Rectangle {
                  width: vpx(28); height: vpx(28); radius: vpx(14)
                  color: root[slotData.enableKey] ? videoManagerOverlay.accentRgba(0.3) : "#22FFFFFF"
                  StyledText { anchors.centerIn: parent; text: slotData.slot.toString(); font.pixelSize: vpx(14); font.bold: true; color: root[slotData.enableKey] ? currentAccentHex : "#666666"; layer.enabled: false }
                }
                Rectangle {
                  Layout.fillWidth: true; height: vpx(38); radius: vpx(4)
                  color: "#22FFFFFF"; border.color: root[slotData.enableKey] ? videoManagerOverlay.accentRgba(0.6) : "#33FFFFFF"; border.width: vpx(1)
                  opacity: root[slotData.enableKey] ? 1.0 : 0.5
                  TextInput {
                    anchors.fill: parent; anchors.leftMargin: vpx(10); anchors.rightMargin: vpx(10); anchors.topMargin: vpx(2); anchors.bottomMargin: vpx(2)
                    text: root[slotData.pathKey]; color: "#FFFFFF"; font.pixelSize: vpx(13); selectByMouse: true; enabled: root[slotData.enableKey]; clip: true
                    onTextChanged: { root[slotData.pathKey] = text; save("cfg." + slotData.pathKey, text) }
                  }
                  StyledText { visible: root[slotData.pathKey].length === 0; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: vpx(10); text: "e.g.  assets\\videos   or   C:\\MyVideos\\Backgrounds"; color: "#444455"; font.pixelSize: vpx(12); layer.enabled: false }
                }
                Rectangle {
                  width: vpx(32); height: vpx(32); radius: vpx(4); color: clrMA.containsMouse ? "#884444" : "#33FFFFFF"; border.color: "#44FF6666"; border.width: vpx(1)
                  opacity: root[slotData.pathKey].length > 0 ? 1.0 : 0.3
                  StyledText { anchors.centerIn: parent; text: "✕"; font.pixelSize: vpx(13); color: "#FF8888"; layer.enabled: false }
                  MouseArea { id: clrMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                    onClicked: { root[slotData.pathKey] = ""; save("cfg." + slotData.pathKey, "") } }
                }
              }
            }
          }

          Item { width: 1; height: vpx(12) }
        }
      }

      Rectangle {
        id: vmFooter
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
        height: vpx(56); color: "#0D0D1E"; radius: vpx(10)
        Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: vpx(10); color: parent.color }
        Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: vpx(1); color: "#33FFFFFF" }

        RowLayout {
          anchors.fill: parent; anchors.leftMargin: vpx(20); anchors.rightMargin: vpx(20); spacing: vpx(12)
          StyledText { Layout.fillWidth: true; text: "Active: " + enabledExts(); font.pixelSize: vpx(13); color: "#AAAAAA"; layer.enabled: false }
          Rectangle {
            width: vpx(120); height: vpx(36); radius: vpx(6)
            color: vmDoneMA.containsMouse ? currentAccentHex : videoManagerOverlay.accentRgba(0.35)
            border.color: currentAccentHex; border.width: vpx(1)
            Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { anchors.centerIn: parent; text: "Done"; font.pixelSize: vpx(15); font.bold: true; layer.enabled: false }
            MouseArea { id: vmDoneMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
              onClicked: { showVideoManager = false; root.forceActiveFocus() } }
          }
        }
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // QUIT CONFIRM DIALOG
  // ════════════════════════════════════════════════════════════════
  Rectangle {
    anchors.fill: parent; color: "#CC000000"; visible: showQuitConfirm; z: 200
    Rectangle {
      anchors.centerIn: parent; width: vpx(420); height: vpx(180)
      color: "#1a1a1a"; radius: vpx(8); border.color: currentAccentHex; border.width: vpx(2)
      Column {
        anchors.centerIn: parent; spacing: vpx(20)
        StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: "Quit to Desktop?"; font.pixelSize: vpx(22); font.bold: true; layer.enabled: false }
        StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: "Press A to confirm, B to cancel"; font.pixelSize: vpx(16); color: "#AAAAAA"; layer.enabled: false }
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // MOVIES PATH DIALOG
  // ════════════════════════════════════════════════════════════════
  Rectangle {
    anchors.fill: parent; color: "#CC000000"; visible: showMoviesPathEdit; z: 200
    MouseArea { anchors.fill: parent; onClicked: { showMoviesPathEdit = false; root.forceActiveFocus() } }
    Rectangle {
      anchors.centerIn: parent; width: vpx(560); height: vpx(230)
      color: "#1A1A2E"; radius: vpx(10); border.color: currentAccentHex; border.width: vpx(2)
      MouseArea { anchors.fill: parent }
      Column {
        anchors.fill: parent; anchors.margins: vpx(24); spacing: vpx(14)
        StyledText { text: "🎬  Movies Collection Path"; font.pixelSize: vpx(18); font.bold: true; layer.enabled: false }
        StyledText { text: "Folder must contain movies.metadata.Pegasus.txt"; font.pixelSize: vpx(12); color: "#888888"; layer.enabled: false }
        Rectangle {
          width: parent.width; height: vpx(46); radius: vpx(5); color: "#22FFFFFF"; border.color: currentAccentHex; border.width: vpx(1)
          TextInput {
            id: moviesPathTI; anchors.fill: parent; anchors.margins: vpx(12)
            text: moviesPathEditBuf; color: "#FFFFFF"; font.pixelSize: vpx(15)
            focus: showMoviesPathEdit; selectByMouse: true; onTextChanged: moviesPathEditBuf = text
          }
          StyledText {
            visible: moviesPathTI.text.length === 0; text: "e.g. assets\\movies"; color: "#555555"; font.pixelSize: vpx(14)
            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: vpx(12); layer.enabled: false
          }
        }
        StyledText { text: "Supports .mp4  .webm  .mkv  .avi  .mov"; font.pixelSize: vpx(11); color: "#666688"; layer.enabled: false }
        Row {
          spacing: vpx(12)
          Rectangle { width: vpx(120); height: vpx(40); radius: vpx(5); color: "#2AFFFFFF"
            StyledText { anchors.centerIn: parent; text: "Cancel"; font.pixelSize: vpx(15); layer.enabled: false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { showMoviesPathEdit = false; root.forceActiveFocus() } } }
          Rectangle { width: vpx(120); height: vpx(40); radius: vpx(5); color: currentAccentHex
            StyledText { anchors.centerIn: parent; text: "Save"; font.pixelSize: vpx(15); font.bold: true; layer.enabled: false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { moviesPath = moviesPathEditBuf.trim() || "assets\\movies"; save("cfg.moviesPath", moviesPath); showMoviesPathEdit = false; root.forceActiveFocus() } } }
          Rectangle { width: vpx(140); height: vpx(40); radius: vpx(5); color: "#33FFFFFF"
            StyledText { anchors.centerIn: parent; text: "Reset Default"; font.pixelSize: vpx(13); layer.enabled: false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { moviesPath = "assets\\movies"; moviesPathEditBuf = "assets/movies"; save("cfg.moviesPath", moviesPath); showMoviesPathEdit = false; root.forceActiveFocus() } } }
        }
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // PLACEMENT EDITOR
  // ════════════════════════════════════════════════════════════════
  PlacementEditor {
    id: placementEditor
    accentHex: currentAccentHex

    onPendingPresetsChanged: {
      if (pendingPresets.length > 0) {
        if (which === "clock")     { clockPresets = pendingPresets; saveClockPresets() }
        else if (which === "date") { datePresets  = pendingPresets; saveDatePresets()  }
        else                       { fpsPresets   = pendingPresets; saveFpsPresets()   }
      }
    }
    onEditorClosed: {
      if (which === "clock") {
        clockPosX = posX; clockPosY = posY
        clockFontSize = fontSize; clockTextOpacity = textOpacity; clockEdgePad = edgePadding
        save("cfg.clockPosX", posX.toString()); save("cfg.clockPosY", posY.toString())
        save("cfg.clockFontSize", fontSize.toString()); save("cfg.clockOpacity", textOpacity.toString())
        save("cfg.clockPadding", edgePadding.toString())
      } else if (which === "date") {
        datePosX = posX; datePosY = posY
        dateFontSize = fontSize; dateTextOpacity = textOpacity; dateEdgePad = edgePadding
        save("cfg.datePosX", posX.toString()); save("cfg.datePosY", posY.toString())
        save("cfg.dateFontSize", fontSize.toString()); save("cfg.dateOpacity", textOpacity.toString())
        save("cfg.datePadding", edgePadding.toString())
      } else {
        fpsPosX = posX; fpsPosY = posY
        fpsFontSize = fontSize; fpsTextOpacity = textOpacity; fpsEdgePad = edgePadding
        save("cfg.fpsPosX", posX.toString()); save("cfg.fpsPosY", posY.toString())
        save("cfg.fpsFontSize", fontSize.toString()); save("cfg.fpsOpacity", textOpacity.toString())
        save("cfg.fpsPadding", edgePadding.toString())
      }
      root.forceActiveFocus()
    }
  }

  // ════════════════════════════════════════════════════════════════
  // KEYBOARD / GAMEPAD INPUT
  // ════════════════════════════════════════════════════════════════
  Keys.onUpPressed: {
    if (showVideoManager || showQuitConfirm || showMoviesPathEdit) { event.accepted = true; return }
    var r = rows[rowIndex]
    if (r && r.type === "placement") { nudgePlacement(r.key, 0, -1); event.accepted = true; return }
    rowIndex = nextFocusable(rowIndex, -1)
    event.accepted = true
  }

  Keys.onDownPressed: {
    if (showVideoManager || showQuitConfirm || showMoviesPathEdit) { event.accepted = true; return }
    var r2 = rows[rowIndex]
    if (r2 && r2.type === "placement") { nudgePlacement(r2.key, 0, 1); event.accepted = true; return }
    rowIndex = nextFocusable(rowIndex, 1)
    event.accepted = true
  }

  Keys.onLeftPressed: {
    if (showVideoManager || showQuitConfirm || showMoviesPathEdit) { event.accepted = true; return }
    var r3 = rows[rowIndex]
    if (!r3) {
      catIndex = (catIndex - 1 + catLabels.length) % catLabels.length
      rowIndex = nextFocusable(-1, 1)
      event.accepted = true; return
    }
    if (r3.type === "slider" || r3.type === "sliderWithArrows" || r3.type === "sliderWithGrad") { adjustSlider(r3, -1); event.accepted = true; return }
    if (r3.type === "placement") { nudgePlacement(r3.key, -1, 0); event.accepted = true; return }
    if (r3.type === "colorpick" || r3.type === "themecolorpick") { cycleColor(r3, -1); event.accepted = true; return }
    if (r3.type === "cycle") {
      if (r3.isString) {
        var si = r3.options.indexOf(root[r3.key])
        root[r3.key] = r3.options[(si - 1 + r3.options.length) % r3.options.length]
        save("cfg." + r3.key, root[r3.key])
      } else if (r3.isNumeric) {
        var ni3 = r3.options.indexOf(root[r3.key])
        if (ni3 < 0) ni3 = 0
        var nv3 = r3.options[(ni3 - 1 + r3.options.length) % r3.options.length]
        root[r3.key] = nv3
        save("cfg." + r3.key, nv3.toString())
      } else {
        root[r3.key] = (root[r3.key] - 1 + r3.options.length) % r3.options.length
        save("cfg." + r3.key, root[r3.key].toString())
      }
      event.accepted = true; return
    }
    catIndex = (catIndex - 1 + catLabels.length) % catLabels.length
    rowIndex = nextFocusable(-1, 1)
    event.accepted = true
  }

  Keys.onRightPressed: {
    if (showVideoManager || showQuitConfirm || showMoviesPathEdit) { event.accepted = true; return }
    var r4 = rows[rowIndex]
    if (!r4) {
      catIndex = (catIndex + 1) % catLabels.length
      rowIndex = nextFocusable(-1, 1)
      event.accepted = true; return
    }
    if (r4.type === "slider" || r4.type === "sliderWithArrows" || r4.type === "sliderWithGrad") { adjustSlider(r4, 1); event.accepted = true; return }
    if (r4.type === "placement") { nudgePlacement(r4.key, 1, 0); event.accepted = true; return }
    if (r4.type === "colorpick" || r4.type === "themecolorpick") { cycleColor(r4, 1); event.accepted = true; return }
    if (r4.type === "cycle") {
      if (r4.isString) {
        var si2 = r4.options.indexOf(root[r4.key])
        root[r4.key] = r4.options[(si2 + 1) % r4.options.length]
        save("cfg." + r4.key, root[r4.key])
      } else if (r4.isNumeric) {
        var ni4 = r4.options.indexOf(root[r4.key])
        if (ni4 < 0) ni4 = 0
        var nv4 = r4.options[(ni4 + 1) % r4.options.length]
        root[r4.key] = nv4
        save("cfg." + r4.key, nv4.toString())
      } else {
        root[r4.key] = (root[r4.key] + 1) % r4.options.length
        save("cfg." + r4.key, root[r4.key].toString())
      }
      event.accepted = true; return
    }
    catIndex = (catIndex + 1) % catLabels.length
    rowIndex = nextFocusable(-1, 1)
    event.accepted = true
  }

  Keys.onPressed: {
    if (event.isAutoRepeat) return

    if (showMoviesPathEdit) { if (api.keys.isCancel(event)) { showMoviesPathEdit = false; event.accepted = true }; return }
    if (showVideoManager)   { if (api.keys.isCancel(event)) { showVideoManager = false;   event.accepted = true }; return }
    if (showQuitConfirm) {
      if (api.keys.isAccept(event)) { Qt.quit(); event.accepted = true }
      else if (api.keys.isCancel(event)) { showQuitConfirm = false; event.accepted = true }
      return
    }

    if (api.keys.isAccept(event)) {
      var r5 = rows[rowIndex]
      if (!r5) { event.accepted = true; return }
      if (r5.type === "moviespath") {
        moviesPathEditBuf = normPath(moviesPath) || "assets/movies"
        showMoviesPathEdit = true
        event.accepted = true
        return
      }
      if (r5.type === "placement") {
        placementEditorFor = r5.key
        placementEditor.which = r5.key
        if (r5.key === "clock") {
          placementEditor.posX = clockPosX; placementEditor.posY = clockPosY
          placementEditor.fontSize = clockFontSize; placementEditor.textOpacity = clockTextOpacity
          placementEditor.edgePadding = clockEdgePad; placementEditor.presets = clockPresets
        } else if (r5.key === "date") {
          placementEditor.posX = datePosX; placementEditor.posY = datePosY
          placementEditor.fontSize = dateFontSize; placementEditor.textOpacity = dateTextOpacity
          placementEditor.edgePadding = dateEdgePad; placementEditor.presets = datePresets
        } else {
          placementEditor.posX = fpsPosX; placementEditor.posY = fpsPosY
          placementEditor.fontSize = fpsFontSize; placementEditor.textOpacity = fpsTextOpacity
          placementEditor.edgePadding = fpsEdgePad; placementEditor.presets = fpsPresets
        }
        placementEditor.visible = true
        placementEditor.forceActiveFocus()
      } else {
        activateRow(r5)
      }
      event.accepted = true
    } else if (api.keys.isCancel(event)) {
      navigate(pages.library)
      event.accepted = true
    } else if (api.keys.isNextPage(event)) {
      catIndex = (catIndex + 1) % catLabels.length
      rowIndex = nextFocusable(-1, 1)
      event.accepted = true
    } else if (api.keys.isPrevPage(event)) {
      catIndex = (catIndex - 1 + catLabels.length) % catLabels.length
      rowIndex = nextFocusable(-1, 1)
      event.accepted = true
    }
  }

  // ════════════════════════════════════════════════════════════════
  // UNICOLOR COMPONENT — inline color-picker panel (cat 6 / Interface)
  // ════════════════════════════════════════════════════════════════
  Component {
    id: unicolorComponent
    Unicolor {
      width: parent ? parent.width : 600
      accentFillIdx:         root.accentFillIdx
      themeFillIdx:          root.themeFillIdx
      accentTransparency:    root.accentTransparency
      interfaceTransparency: root.interfaceTransparency
      gradAccentColor:       root.gradAccentColor
      gradAccentOpacity:     root.gradAccentOpacity
      gradThemeColor:        root.gradThemeColor
      gradThemeTransp:       root.gradThemeTransp
      currentAccentColor:    root.currentAccentColor
      currentThemeFillHex:   root.currentThemeFillHex
      accentHex:             root.currentAccentHex
      saveFunc:              root.save

      onAccentFillIdxChanged:         root.accentFillIdx         = accentFillIdx
      onThemeFillIdxChanged:          root.themeFillIdx          = themeFillIdx
      onAccentTransparencyChanged:    root.accentTransparency    = accentTransparency
      onInterfaceTransparencyChanged: root.interfaceTransparency = interfaceTransparency
      onGradAccentColorChanged:       root.gradAccentColor       = gradAccentColor
      onGradAccentOpacityChanged:     root.gradAccentOpacity     = gradAccentOpacity
      onGradThemeColorChanged:        root.gradThemeColor        = gradThemeColor
      onGradThemeTranspChanged:       root.gradThemeTransp       = gradThemeTransp
    }
  }

}
