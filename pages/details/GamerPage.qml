import QtQuick 2.8
import QtQuick.Window 2.0
import QtGraphicalEffects 1.12
import QtQml 2.15
import QtQuick.Layouts 1.1
import "../../js/enums.mjs" as Enums
import "../../js/utils.mjs" as Utils
import "../../js/styling.mjs" as Styling

import "../../components"
import "./components"
import "../../Lists"

// ════════════════════════════════════════════════════════════════════
// GamerPage.qml  —  Profile hub: Generals | Profile | Avatar Scene
//
// Panel 1 — Generals       : system-themed stats (collections, games,
//                             play time, most/last played, etc.)
// Panel 2 — Profile        : 3 tabs — Info | Stats | Edit
//                             Edit tab: live name/motto/bio editing,
//                             9-avatar grid picker, gamer pic path,
//                             gamerscore, status, region, color picker
// Panel 3 — Avatar Scene   : 2× width cinematic stage; Avatar*Full.png
//                             stands bottom-right; ◀ ▶ cycle avatars
//
// All edits persist via api.memory so they survive restarts.
// ════════════════════════════════════════════════════════════════════

Item {
  id: root
  focus: true
  Keys.priority: Keys.BeforeItem

  // ── Helpers ───────────────────────────────────────────────────────
  function mem(k, d) {
    var v = api.memory.get(k)
    return (v !== undefined && v !== null && v !== "") ? v : d
  }

  // ── Theme colours — identical keys + formulas to ThemesDetails.qml ──
  // cfg.accentHex / cfg.themeHex are hex strings saved by SettingsPage.
  property string accentHex:         "#5d9809"
  property string themeHex:          "#3A3ABF"
  property real   accentAlphaPct:    0
  property real   ifaceTransparency: 80
  property bool   panelGradient:     true
  property bool   gradAccentOn:      true
  property bool   gradThemeOn:       true
  property bool   themeDarkOn:       true
  property int    libTransp:         20
  // Avatar panel appearance controls (Appearance tab — do NOT affect edit panel)
  property real   panelBaseAlpha:       75    // base fill opacity 0–100
  property real   gradientStrength:     97    // diagonal theme gradient opacity 0–100
  property real   accentGradAlpha:      12    // accent left-edge glow opacity 0–100
  property real   themeGradAlpha:       8     // theme top-edge glow opacity 0–100
  property real   accentTransparency:   0     // accent color transparency 0–100
  property real   accentOpacity:        100   // accent color opacity 0–100
  property real   accentGradTransp:     0     // accent gradient transparency 0–100
  property real   accentGradOpacity:    100   // accent gradient opacity 0–100
  property real   accentGlowColorMix:   100   // glow color: 0=black → 100=profile accent
  property bool   avatarSystemGradOn:   true  // avatar scene: system theme gradient on/off
  property bool   avatarProfileGradOn:  true  // avatar scene: profile accent gradient on/off
  property bool   avatarPanelGradOn:    true  // avatar scene: panel gradient master switch
  property bool   avatarDarkOn:         true  // avatar scene: dark mode (independent of profile panel)
  property bool   profileDropShadow:    false  // profile panel: drop shadows on text
  property bool   avatarDropShadow:     false  // avatar scene panel: drop shadows on text
  property real   globalShadowRadius:   4     // global drop shadow radius 1–12
  property bool   avatarAccentGradOn:   true  // avatar scene: accent glow gradient
  property bool   avatarThemeGradOn:    true  // avatar scene: theme glow gradient
  property bool   avatarHideBg:         false // avatar scene: hide base fill (full transparency)
  property real   avatarBgOpacity:      100   // avatar scene: base fill opacity 0=transparent 100=full
  property bool   avatarVignette:       true  // avatar scene: bottom-up dark vignette gradient
  property real   avatarGlowColorMix:   100   // avatar scene glow color: 0=black → 100=profile accent
  property bool   avatarShapesOn:       true  // avatar scene: animated floating shapes
  property bool   avatarAvatarOn:       true  // avatar scene: show full avatar image
  property bool   avatarGamerpicOn:     true  // avatar scene: show gamerpic + membership pill
  property bool   avatarGamerscoreOn:   true  // avatar scene: show gamerscore badge
  property bool   avatarSpotlightOn:    true  // avatar scene: radial spotlight glow
  property bool   avatarStatsOn:        true  // avatar scene: show stat pills
  property bool   avatarGamertagOn:     true  // avatar scene: show gamertag name bar
  property bool   avatarBordersOn:      true  // avatar scene: show accent border lines + emoji strips
  property bool   avatarLatestGamesOn:  true  // avatar scene: show latest games strip bottom-right
  property bool   profileShapeOn:       false  // profile panel: show profile picture shape clipping
  property bool   profileVignette:      true  // profile panel: bottom vignette gradient
  property bool   profileAccentGradOn:  true  // profile panel: accent glow gradient layer
  property bool   profileThemeGradOn:   true  // profile panel: theme glow gradient layer
  property bool   profileHideBg:        false // profile panel: hide base fill
  property real   profileBgOpacity:     100   // profile panel: base fill opacity 0–100
  property real   profileGlowColorMix:  100   // profile panel: glow color 0=black→100=accent
  property bool   profileGamerpicOn:    true  // profile panel: show gamerpic on info cards
  property bool   profileGamerscoreOn:  true  // profile panel: show gamerscore badge on cards
  property bool   profileGamertagOn:    true  // profile panel: show gamertag name on cards
  property bool   profileBordersOn:     true  // profile panel: show accent border lines on cards
  property bool   profileStatsOn:       true  // profile panel: show stat pills on cards
  property bool   profileSpotlightOn:   true  // profile panel: radial spotlight glow
  property real   profileShapeOpacity:  60    // profile panel: animated shapes opacity 0–100
  property real   profileShapeScale:    100   // profile panel: animated shapes scale 0–100

  // Avatar Scene Controller drawer — toggled from Edit Profile > Avatar Scene Panel section
  property bool   avatarSceneDrawerOpen: false

  // Sync & Color mode options for Avatar Scene Controller
  property bool   avatarSyncDark:         true   // sync Original Dark with avatarDarkOn
  property bool   avatarSyncThemes:       false  // sync Original Dark with ThemesDetails panels
  property bool   avatarUseSystemColors:  true   // use system theme colour for avatar scene bg
  property bool   avatarUseProfileColors: true   // use profile accent colour for avatar scene glow
  property int    containerIndex:         0      // 0=none 1=BlackGloss 2=GlassLeft 3=GlassRight 4=GlassDirty 5=Shine 6=Shadow 7=Wave 8=Uni
  property bool   containersOn:           true   // global containers on/off

  readonly property var containerImages: [
    "",
    "../../assets/images/gamerpic/Containers/panel_button.png",
    "../../assets/images/gamerpic/Containers/rectangleglass0.png",
    "../../assets/images/gamerpic/Containers/rectangleglass1.png",
    "../../assets/images/gamerpic/Containers/rectangleglass2.png",
    "../../assets/images/gamerpic/Containers/rectangleglass3.png",
    "../../assets/images/gamerpic/Containers/thumbmask.png",
    "../../assets/images/gamerpic/Containers/rectanglekin0.png",
    "../../assets/images/gamerpic/Containers/smallwhiteblok.png",
    "../../assets/images/gamerpic/Containers/panel_list_square.png",
    "../../assets/images/gamerpic/Containers/rectangleglass2.png",
    "../../assets/images/gamerpic/Containers/rectangleglass4.png"
  ]

  // Derived colours — same formulas as ThemesDetails
  property color accentColor: Qt.rgba(
    parseInt(accentHex.substr(1,2),16)/255,
    parseInt(accentHex.substr(3,2),16)/255,
    parseInt(accentHex.substr(5,2),16)/255,
    Math.max(0.05, Math.min(1.0, 1.0 - accentAlphaPct / 100)))

  property real panelAlpha: Math.max(0.0, Math.min(0.92, (1.0 - libTransp / 100) * 0.85))

  property color themeFill: Qt.rgba(
    parseInt(themeHex.substr(1,2),16)/255,
    parseInt(themeHex.substr(3,2),16)/255,
    parseInt(themeHex.substr(5,2),16)/255,
    panelAlpha)

  property color themeDark: themeDarkOn ? Qt.rgba(
    parseInt(themeHex.substr(1,2),16)/255,
    parseInt(themeHex.substr(3,2),16)/255,
    parseInt(themeHex.substr(5,2),16)/255,
    Math.max(0.05, Math.min(0.92, (1.0 - ifaceTransparency / 100) * 0.85)))
    : Qt.rgba(0,0,0,0.0)

  function accentRgba(a) {
    return Qt.rgba(
      parseInt(accentHex.substr(1,2),16)/255,
      parseInt(accentHex.substr(3,2),16)/255,
      parseInt(accentHex.substr(5,2),16)/255, a)
  }

  // Live refresh every 500 ms — same as ThemesDetails colourRefresh timer
  Timer {
    interval: 500; running: true; repeat: true; triggeredOnStart: true
    onTriggered: {
      function nb(k,d){ var v=api.memory.get(k); return (v===null||v===undefined||v==="")?d:v }
      var ah=nb("cfg.accentHex",""); var th=nb("cfg.themeHex","")
      root.accentHex         = ah !== "" ? ah : "#5d9809"
      root.themeHex          = th !== "" ? th : "#3A3ABF"
      root.accentAlphaPct    = parseInt(nb("cfg.accentAlpha","0"))
      root.ifaceTransparency = parseInt(nb("cfg.ifaceAlpha","80"))
      root.panelGradient     = nb("cfg.panelGradient","true")  !== "false"
      root.gradAccentOn      = nb("cfg.gradAccent","true")     !== "false"
      root.gradThemeOn       = nb("cfg.gradTheme","true")      !== "false"
      root.themeDarkOn       = nb("theme.themeDark","true")    !== "false"
      root.libTransp         = parseInt(nb("theme.libTransp","20"))
      root.panelBaseAlpha    = parseFloat(nb("cfg.panelBaseAlpha","75"))
      root.gradientStrength  = parseFloat(nb("cfg.gradientStrength","97"))
      root.accentGradAlpha   = parseFloat(nb("cfg.accentGradAlpha","12"))
      root.themeGradAlpha    = parseFloat(nb("cfg.themeGradAlpha","8"))
      root.accentTransparency  = parseFloat(nb("cfg.accentTransparency","0"))
      root.accentOpacity       = parseFloat(nb("cfg.accentOpacity","100"))
      root.accentGradTransp    = parseFloat(nb("cfg.accentGradTransp","0"))
      root.accentGradOpacity   = parseFloat(nb("cfg.accentGradOpacity","100"))
      root.accentGlowColorMix  = parseFloat(nb("cfg.accentGlowColorMix","100"))
      root.avatarSystemGradOn  = nb("cfg.avatarSystemGrad","true")  !== "false"
      root.avatarProfileGradOn = nb("cfg.avatarProfileGrad","true") !== "false"
      root.avatarPanelGradOn   = nb("cfg.avatarPanelGrad","true")   !== "false"
      root.avatarDarkOn        = nb("cfg.avatarDark","true")        !== "false"
      root.profileDropShadow   = nb("cfg.profileDropShadow","true") !== "false"
      root.avatarDropShadow    = nb("cfg.avatarDropShadow","true")  !== "false"
      root.globalShadowRadius  = parseFloat(nb("cfg.shadowRadius","4"))
      root.avatarAccentGradOn  = nb("cfg.avatarAccentGrad","true")  !== "false"
      root.avatarThemeGradOn   = nb("cfg.avatarThemeGrad","true")   !== "false"
      root.avatarHideBg        = nb("cfg.avatarHideBg","false")     === "true"
      root.avatarBgOpacity     = parseFloat(nb("cfg.avatarBgOpacity","100"))
      root.avatarVignette      = nb("cfg.avatarVignette","true")    !== "false"
      root.avatarGlowColorMix  = parseFloat(nb("cfg.avatarGlowColorMix","100"))
      root.avatarShapesOn      = nb("cfg.avatarShapes","true")      !== "false"
      root.avatarAvatarOn      = nb("cfg.avatarAvatar","true")      !== "false"
      root.avatarGamerpicOn    = nb("cfg.avatarGamerpic","true")    !== "false"
      root.avatarGamerscoreOn  = nb("cfg.avatarGamerscore","true")  !== "false"
      root.avatarSpotlightOn   = nb("cfg.avatarSpotlight","true")   !== "false"
      root.avatarStatsOn       = nb("cfg.avatarStats","true")       !== "false"
      root.avatarGamertagOn    = nb("cfg.avatarGamertag","true")   !== "false"
      root.avatarBordersOn     = nb("cfg.avatarBorders","true")    !== "false"
      root.avatarLatestGamesOn = nb("cfg.avatarLatestGames","true") !== "false"
      root.profileShapeOn      = nb("cfg.profileShapeOn","true")    !== "false"
      root.profileVignette     = nb("cfg.profileVignette","true")   !== "false"
      root.profileAccentGradOn = nb("cfg.profileAccentGrad","true") !== "false"
      root.profileThemeGradOn  = nb("cfg.profileThemeGrad","true")  !== "false"
      root.profileHideBg       = nb("cfg.profileHideBg","false")    === "true"
      root.profileBgOpacity    = parseFloat(nb("cfg.profileBgOpacity","100"))
      root.profileGlowColorMix = parseFloat(nb("cfg.profileGlowColorMix","100"))
      root.profileGamerpicOn   = nb("cfg.profileGamerpic","true")   !== "false"
      root.profileGamerscoreOn = nb("cfg.profileGamerscore","true") !== "false"
      root.profileGamertagOn   = nb("cfg.profileGamertag","true")   !== "false"
      root.profileBordersOn    = nb("cfg.profileBorders","true")    !== "false"
      root.profileStatsOn      = nb("cfg.profileStats","true")      !== "false"
      root.profileSpotlightOn  = nb("cfg.profileSpotlight","true")  !== "false"
      root.profileShapeOpacity = parseFloat(nb("cfg.profileShapeOpacity","60"))
      root.profileShapeScale   = parseFloat(nb("cfg.profileShapeScale","100"))
      var ap = parseInt(nb("cfg.avatarActivePreset","-1"))
      if (avatarSceneDrawer.activePreset !== ap) avatarSceneDrawer.activePreset = ap
      root.avatarSyncDark         = nb("cfg.avatarSyncDark","true")         !== "false"
      root.avatarSyncThemes       = nb("cfg.avatarSyncThemes","false")      === "true"
      root.avatarUseSystemColors  = nb("cfg.avatarUseSystemColors","true")  !== "false"
      root.avatarUseProfileColors = nb("cfg.avatarUseProfileColors","true") !== "false"
      root.containersOn           = nb("cfg.containersOn","true")           !== "false"
      root.containerIndex         = parseInt(nb("cfg.containerIndex","0"))
    }
  }

  // ── Lists ─────────────────────────────────────────────────────────
  ListPlayTime  { id: listPlayTime;  max: api.allGames.count }
  ListLastPlayed  { id: listRecent }
  ListFavorites   { id: listFavorites }

  property int totalPlayTime: {
    var t = 0
    for (var i = 0; i < api.allGames.count; i++) t += api.allGames.get(i).playTime
    return t
  }

  // ── Profile persistent state ──────────────────────────────────────
  property string profileName:        mem("profile.name",        "Jackrabbit72380")
  property string profileMotto:       mem("profile.motto",       "")
  property string profileBio:         mem("profile.bio",         "")
  property string profileAvatar:      mem("profile.avatar",      "Avatar1.png")
  property string profilePic:         mem("profile.pic",         "")
  property string profileGamerpic:    mem("profile.gamerpic", "").replace(/.*Halo\/.*/, "")
  property string profileStatus:      mem("profile.status",      "Signed In")
  property string profileSubStatus:   mem("profile.substatus",   "Xbox LIVE Gold")
  property string profileRegion:      mem("profile.region",      "")
  property int    profileGamerscore:  parseInt(mem("profile.gamerscore", "999999"))
  property string profileColor:       mem("profile.color",       "#0099CC")
  property string profileShape:       mem("profile.shape",       "circle")

  // Avatar helpers
  readonly property int    avatarCount:    9
  readonly property string avatarBase:     "../../assets/images/avatars/"
  property string avatarThumbUrl: avatarBase + profileAvatar
  property string avatarFullUrl:  avatarBase + profileAvatar.replace(/\.png$/i, "") + "Full.png"

  // ── Custom avatar built in the avatar editor (avatar/avatar_theme) ────────
  // The editor hands back its state map (kept in memory) and one 512×768 grab,
  // which is written as the two PNGs the rest of the theme already expects:
  // avatars/Custom.png for tiles and avatars/CustomFull.png for the scene.
  readonly property string customAvatarName: "Custom.png"
  property int  customAvatarVersion: api.memory.get("profile.avatar.state") ? 1 : 0
  readonly property bool hasCustomAvatar: customAvatarVersion > 0
  property bool customPngSaved: false
  property bool avatarLoaderFailed: false
  readonly property bool avatarEditorOpen: avatarEditorLoader.item ? avatarEditorLoader.item.opened : false

  function storedAvatarState() {
    var s = api.memory.get("profile.avatar.state")
    if (!s) return ({})
    try { return JSON.parse(s) } catch (e) { return ({}) }
  }

  function applyCustomAvatar(state) {
    api.memory.set("profile.avatar.state", JSON.stringify(state))
    if (root.customPngSaved) {
      root.profileAvatar = root.customAvatarName
      api.memory.set("profile.avatar", root.customAvatarName)
    }
    root.customPngSaved = false
  }

  // TEMPORARY: on-screen trace of the "+" click, set avatarDebug:false to remove.
  property bool avatarDebug: true
  property string avatarDebugText: ""

  function loaderStatusName(st) {
    if (st === Loader.Null)    return "Null (no source)"
    if (st === Loader.Loading) return "Loading"
    if (st === Loader.Ready)   return "Ready"
    if (st === Loader.Error)   return "Error (module failed to load)"
    return String(st)
  }

  function openAvatarEditor() {
    if (avatarEditorLoader.item)
      avatarEditorLoader.item.open(root.storedAvatarState())
    root.tracePlusClick()
  }

  function tracePlusClick() {
    if (!root.avatarDebug) return
    var lines = []
    lines.push("source:  " + avatarEditorLoader.source)
    lines.push("status:  " + root.loaderStatusName(avatarEditorLoader.status))
    lines.push("item:    " + (avatarEditorLoader.item ? "yes" : "null"))
    if (avatarEditorLoader.item) {
      lines.push("size:    " + Math.round(avatarEditorLoader.item.width) + " x " + Math.round(avatarEditorLoader.item.height))
      lines.push("open():  opened = " + avatarEditorLoader.item.opened)
    } else {
      lines.push("")
      lines.push("The editor file above was not loaded. If status is Error, the")
      lines.push("folder/file is not where source says, or a QML import inside")
      lines.push("it is missing from this build (the log names it).")
    }
    root.avatarDebugText = lines.join("\n")
  }

  function saveCustomAvatarPng(grab) {
    var ok = false
    try { ok = grab.saveToFile(Qt.resolvedUrl("../../assets/images/avatars/Custom.png")) } catch (e) { ok = false }
    try { ok = grab.saveToFile(Qt.resolvedUrl("../../assets/images/avatars/CustomFull.png")) && ok } catch (e) { ok = false }
    root.customPngSaved = ok
    if (ok) root.customAvatarVersion++
  }

  // ── Signed-in slot ────────────────────────────────────────────────
  property int signedInSlot: parseInt(mem("profile.signedSlot", "1"))

  // ── Profile tab state ─────────────────────────────────────────────
  readonly property var profileTabs: ["ℹ Info", "📊 Stats", "🛠 Edit", "✨ Create", "🎨 Appearance"]
  property int profileTabIndex: 0

  // ── Saved profile slots ────────────────────────────────────────────
  property var profileSlots: []
  ListModel { id: infoSlotsModel }

  function saveSlot(num, name, avatar, gamerpic, gamerscore, status, substatus, motto, bio, region, color, shape) {
    var k = "profile.slot." + num + "."
    api.memory.set(k+"name",       name)
    api.memory.set(k+"avatar",     avatar)
    api.memory.set(k+"gamerpic",   gamerpic)
    api.memory.set(k+"gamerscore", gamerscore.toString())
    api.memory.set(k+"status",     status)
    api.memory.set(k+"substatus",  substatus)
    api.memory.set(k+"motto",      motto)
    api.memory.set(k+"bio",        bio)
    api.memory.set(k+"region",     region)
    api.memory.set(k+"color",      color)
    api.memory.set(k+"shape",      shape || "circle")
  }

  function clearSlot(num) {
    var k = "profile.slot." + num + "."
    var fields = ["name","avatar","gamerpic","gamerscore","status","substatus","motto","bio","region","color","shape","borderTop","borderBottom"]
    for (var f = 0; f < fields.length; f++) api.memory.set(k + fields[f], "")
  }

  // Apply shape to the Profiles panel only (root.profileShape / profile.shape).
  // Per-slot memory (profile.slot.N.shape) is intentionally NOT touched so
  // avatar scene panels and other slot cards are unaffected.
  function applyShapeToAllSlots(shape) {
    root.profileShape = shape
    api.memory.set("profile.shape", shape)
  }

  function nextFreeSlot() {
    for (var i = 1; i <= 9; i++) {
      var n = api.memory.get("profile.slot." + i + ".name")
      if (!n || n === "") return i
    }
    return -1
  }

  function getSlot(num) {
    var k = "profile.slot." + num + "."
    return {
      slotNum:    num,
      name:       api.memory.get(k+"name")       || "",
      avatar:     api.memory.get(k+"avatar")     || "Avatar1.png",
      gamerpic:   (api.memory.get(k+"gamerpic") || "").replace(/.*Halo\/.*/, ""),
      gamerscore: parseInt(api.memory.get(k+"gamerscore") || "0"),
      status:     api.memory.get(k+"status")     || "Signed In",
      substatus:  api.memory.get(k+"substatus")  || "Xbox LIVE Gold",
      motto:      api.memory.get(k+"motto")      || "",
      bio:        api.memory.get(k+"bio")        || "",
      region:     api.memory.get(k+"region")     || "",
      color:      api.memory.get(k+"color")      || "#0099CC",
      shape:      api.memory.get(k+"shape")      || "circle"
    }
  }

  function rebuildPanels() {
    var m = panelsList.model
    var occupied = []
    for (var s = 1; s <= 9; s++) {
      var n = api.memory.get("profile.slot." + s + ".name")
      if (n && n !== "") occupied.push(s)
    }
    profileSlots = occupied
    for (var ri = m.count - 1; ri >= 1; ri--) {
      var re = m.get(ri)
      if (re.type === "avatarscene") {
        var still = false
        for (var oi = 0; oi < occupied.length; oi++) { if (occupied[oi] === re.slotNum) { still = true; break } }
        if (!still) m.remove(ri)
      }
    }
    for (var k = 0; k < occupied.length; k++) {
      var there = false
      for (var ci = 1; ci < m.count; ci++) { if (m.get(ci).slotNum === occupied[k]) { there = true; break } }
      if (!there) m.append({ type: "avatarscene", slotNum: occupied[k] })
    }
    infoSlotsModel.clear()
    // Build ordered list: signed-in slot first, then others in display order
    var displayOrder = []
    var orderStr = api.memory.get("profile.displayOrder") || ""
    var storedOrder = orderStr !== "" ? orderStr.split(",").map(function(x){return parseInt(x)}) : []
    // Collect all occupied slots
    var occupied2 = []
    for (var si2 = 1; si2 <= 9; si2++) {
      if ((api.memory.get("profile.slot." + si2 + ".name") || "") !== "") occupied2.push(si2)
    }
    // Build display order: stored order filtered to occupied, then any remaining
    var used = {}
    storedOrder.forEach(function(n){ if (occupied2.indexOf(n) >= 0) { displayOrder.push(n); used[n] = true } })
    occupied2.forEach(function(n){ if (!used[n]) displayOrder.push(n) })
    // Put signed-in slot at front
    var sig = root.signedInSlot
    var sigIdx = displayOrder.indexOf(sig)
    if (sigIdx > 0) { displayOrder.splice(sigIdx, 1); displayOrder.unshift(sig) }
    for (var di = 0; di < displayOrder.length; di++) {
      var si = displayOrder[di]
      infoSlotsModel.append({
        slotNum: si, slotName: api.memory.get("profile.slot." + si + ".name") || "",
        slotAv:  api.memory.get("profile.slot." + si + ".avatar")     || "Avatar1.png",
        slotGp:  (api.memory.get("profile.slot." + si + ".gamerpic") || "").replace(/.*Halo\/.*/, ""),
        slotGs:  api.memory.get("profile.slot." + si + ".gamerscore") || "0",
        slotSub: api.memory.get("profile.slot." + si + ".substatus")  || "",
        slotMot: api.memory.get("profile.slot." + si + ".motto")      || "",
        slotCol: api.memory.get("profile.slot." + si + ".color")      || "#0099CC",
        slotShape: api.memory.get("profile.slot." + si + ".shape")    || "circle"
      })
    }
  }

  // ── Sync panelsList layout state from memory ─────────────────────
  // Mirrors LibraryPage's active layout into GamerPage's panelsList so
  // both pages show the same layout when navigating between them.
  function syncPanelsLayout() {
    // Read LibraryPage's current layout (pageKey "" → no prefix)
    var raw = api.memory.get("gameLayout");
    var saved = (raw !== null && raw !== undefined && raw !== "") ? parseInt(raw) : 1;
    // Editor mode (0) is never mirrored — use the pre-edit layout instead
    if (saved === 0) {
      var be = api.memory.get("gameLayoutBeforeEdit");
      saved = (be !== null && be !== undefined && be !== "") ? parseInt(be) : 1;
    }
    if (isNaN(saved) || saved < 1 || saved > 8) { saved = 1; }
    // Mirror to gp_ space so PanelsList.onCompleted and badge reads are correct
    api.memory.set("gp_gameLayout", String(saved));
    // Restore GamerPage's own active slot for this layout (gp_ prefixed)
    var lastSlot = parseInt(api.memory.get("gp_edLastActiveSlot") || "-1");
    if (lastSlot >= 1) {
      panelsList.edLoadSlots();
      panelsList.edActiveSlot = lastSlot;
      panelsList.edLoadSlot(lastSlot);
    }
    // Guard _closingEditor so onLayoutModeChanged does not clear edActiveSlot
    panelsList._closingEditor = true;
    panelsList.layoutMode = saved;
    panelsList._closingEditor = false;
    panelsList.applyLayoutMode();
  }

  Component.onCompleted: {
    // Only seed slot 1 if nothing has ever been saved (truly first run)
    var anySlot = false
    for (var s = 1; s <= 9; s++) {
      var n = api.memory.get("profile.slot." + s + ".name")
      if (n && n !== "") { anySlot = true; break }
    }
    if (!anySlot) {
      // First ever run — create Player 1 as the one default profile
      var name1 = "Player 1"
      root.profileName = name1
      api.memory.set("profile.name", name1)
      api.memory.set("profile.count", "1")
      saveSlot(1, name1, root.profileAvatar, root.profileGamerpic,
               root.profileGamerscore, root.profileStatus, root.profileSubStatus,
               root.profileMotto, root.profileBio, root.profileRegion, root.profileColor, root.profileShape)
    }
    Qt.callLater(rebuildPanels)
    Qt.callLater(syncPanelsLayout)
  }

  // Re-sync layout every time GamerPage becomes visible or gains focus.
  // Both hooks are used because Pegasus may trigger one or the other depending
  // on how navigation is implemented.
  onFocusChanged:       { if (focus)       { Qt.callLater(syncPanelsLayout) } }
  onActiveFocusChanged: { if (activeFocus) { Qt.callLater(syncPanelsLayout) } }
  onVisibleChanged:     { if (visible)     { Qt.callLater(syncPanelsLayout) } }

  // ── Keyboard navigation ───────────────────────────────────────────
  property var infoTabRef: null
  // ── Button action functions (shared by keyboard + mouse) ─────────
  function doAccept() {
    if (panelsList.currentIndex === 0) {
      if (root.infoTabRef) {
        var sel = root.infoTabRef.selectedSlot
        for (var pi = 1; pi < panelsModel.count; pi++) {
          if (panelsModel.get(pi).slotNum === sel) {
            panelsList.currentIndex = pi
            break
          }
        }
      }
    } else {
      var curIdx = panelsList.currentIndex
      if (curIdx >= 1 && curIdx < panelsModel.count) {
        var sn = panelsModel.get(curIdx).slotNum
        if (sn > 0) {
          var sk = "profile.slot." + sn + "."
          api.memory.set("profile.name",       api.memory.get(sk+"name")       || "")
          api.memory.set("profile.avatar",     api.memory.get(sk+"avatar")     || "Avatar1.png")
          api.memory.set("profile.gamerpic",   api.memory.get(sk+"gamerpic")   || "")
          api.memory.set("profile.gamerscore", api.memory.get(sk+"gamerscore") || "0")
          api.memory.set("profile.substatus",  api.memory.get(sk+"substatus")  || "Xbox LIVE Gold")
          api.memory.set("profile.motto",      api.memory.get(sk+"motto")      || "")
          api.memory.set("profile.bio",        api.memory.get(sk+"bio")        || "")
          api.memory.set("profile.color",      api.memory.get(sk+"color")      || "#0099CC")
        }
      }
      navigate(pages.profileScene)
    }
  }
  function doCancel()  { navigate(pages.library) }
  function doLayout()  { panelsList.cycleLayout() }

  Keys.onLeftPressed:  { if (root.avatarEditorOpen) return; if (!event.isAutoRepeat) panelsList.previousItem() }
  Keys.onRightPressed: { if (root.avatarEditorOpen) return; if (!event.isAutoRepeat) panelsList.nextItem() }
  Keys.onPressed: {
    // The avatar editor handles its own keys while it is open
    if (root.avatarEditorOpen) return
    // Held Y (auto-repeat) → open Layout Editor, matching LibraryPage behaviour
    if (event.isAutoRepeat && (event.key === Qt.Key_Y || api.keys.isFilters(event))) {
      if (panelsList.layoutMode !== 0) {
        panelsList.openEditor();
        event.accepted = true;
        return;
      }
    }
    if (!event.isAutoRepeat) {
      if (api.keys.isCancel(event))           { doCancel(); event.accepted = true }
      else if (api.keys.isAccept(event))      { doAccept(); event.accepted = true }
      else if (event.key === Qt.Key_Y || api.keys.isFilters(event)) { doLayout(); event.accepted = true }
      else if (api.keys.isNextPage(event))    { panelsList.navigateForwardQuickly();   event.accepted = true }
      else if (api.keys.isPrevPage(event))    { panelsList.navigateBackwardsQuickly(); event.accepted = true }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // AVATAR EDITOR — opened by the "+" tile in Choose Avatar.
  // Loaded at runtime: if avatar/ is not at the theme root this page still
  // opens, the "+" just logs instead of doing anything.
  // ════════════════════════════════════════════════════════════════
  Loader {
    id: avatarEditorLoader
    anchors.fill: parent
    z: 5000
    source: Qt.resolvedUrl("../../avatar/avatar_theme/avatar/AvatarEditorPage.qml")

    onLoaded: {
      item.accentColor    = root.accentHex
      item.accentInkColor = "#062033"
      item.gamerTag       = root.profileName
      item.portraitReady.connect(root.saveCustomAvatarPng)
      item.accepted.connect(root.applyCustomAvatar)
    }

    onStatusChanged: {
      if (status === Loader.Error) {
        root.avatarLoaderFailed = true
        console.log("AVATAR: could not load " + source)
      } else if (status === Loader.Ready) {
        root.avatarLoaderFailed = false
      }
    }
  }

  // TEMPORARY ─ trace of the "+" click, visible instead of log-only.
  Rectangle {
    visible: root.avatarDebugText !== ""
    anchors.centerIn: parent
    width: Math.min(root.width - vpx(80), vpx(680))
    height: traceColumn.implicitHeight + vpx(20)
    radius: vpx(6)
    color: "#F2000000"
    border.color: root.accentHex; border.width: vpx(2)
    z: 9999

    Column {
      id: traceColumn
      anchors.fill: parent
      anchors.margins: vpx(10)
      spacing: vpx(4)

      Text {
        text: "AVATAR + TRACE  (click to close)"
        color: root.accentHex; font.pixelSize: vpx(13); font.bold: true
      }
      Text {
        text: root.avatarDebugText
        width: traceColumn.width
        color: "#FFFFFF"; font.pixelSize: vpx(11)
        wrapMode: Text.WrapAnywhere
      }
    }

    MouseArea { anchors.fill: parent; onClicked: root.avatarDebugText = "" }
  }

  // ════════════════════════════════════════════════════════════════
  // SHARED DELEGATES
  // ════════════════════════════════════════════════════════════════
  Component {
    id: sectionDelegate2
    RowLayout {
      width: parent.width
      StyledText { text: title;                          font.pixelSize: vpx(15); wrapMode: Text.WordWrap }
      StyledText { Layout.fillWidth: true; text: "" }
      StyledText { text: Utils.formatPlayTime(playTime); font.pixelSize: vpx(15); wrapMode: Text.WordWrap }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // PANEL 1 — GENERALS
  // ════════════════════════════════════════════════════════════════
  Component {
    id: generalsPanel

    Item {
      anchors.fill: parent

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: vpx(20)
        spacing: vpx(0)

        // Header
        Row {
          spacing: vpx(8); Layout.bottomMargin: vpx(10)
          Rectangle { width: vpx(4); height: vpx(26); radius: vpx(2); color: root.accentHex; anchors.verticalCenter: parent.verticalCenter }
          StyledText { text: "Generals"; font.pixelSize: vpx(21); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
        }

        // Accent divider
        Rectangle { Layout.fillWidth: true; height: vpx(1); color: root.accentRgba(0.5); Layout.bottomMargin: vpx(10) }

        // Scrollable pill list
        Item {
          Layout.fillWidth: true; Layout.fillHeight: true

          Flickable {
            id: generalsFlick
            anchors.fill: parent
            contentHeight: generalsCol.implicitHeight
            clip: true

            Column {
              id: generalsCol
              width: parent.width
              spacing: vpx(5)

              Column {
                width: parent.width; spacing: vpx(5)
                Repeater {
                model: [
                  { icon: "🏆", label: "Most Played",     value: listPlayTime.games.count > 0 ? listPlayTime.games.get(0).title : "—" },
                  { icon: "🕐", label: "Last Played",     value: listRecent.games.count > 0   ? listRecent.games.get(0).title   : "—" },
                  { icon: "📊", label: "Sessions",        value: listRecent.games.count + " tracked" },
                  { icon: "🌍", label: "Region",          value: root.profileRegion !== "" ? root.profileRegion : "Not Set" }
                ]
                delegate: Item {
                  width: parent.width; height: vpx(28)
                  Rectangle {
                    anchors.left: parent.left
                    width: genPillRow.implicitWidth + vpx(16); height: vpx(28)
                    radius: vpx(14)
                    color: index % 2 === 0 ? root.accentRgba(0.18) : "#14FFFFFF"
                    border.color: index % 2 === 0 ? root.accentRgba(0.35) : "#18FFFFFF"
                    border.width: vpx(1)
                    Row {
                      id: genPillRow; anchors.centerIn: parent; spacing: vpx(5)
                      StyledText { text: modelData.icon; font.pixelSize: vpx(12) }
                      StyledText { text: modelData.label; color: "#AAAAAA"; font.pixelSize: vpx(11) }
                      StyledText { text: modelData.value; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF" }
                    }
                  }
                }
                }
              }
            }
          }

          Image {
            source: "../../assets/images/system/up-default.png"
            width: vpx(22); height: vpx(18)
            anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: vpx(2); anchors.rightMargin: vpx(2)
            fillMode: Image.PreserveAspectFit; asynchronous: true
            opacity: generalsFlick.atYBeginning ? 0 : 0.8
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }
          Image {
            source: "../../assets/images/system/down-default.png"
            width: vpx(22); height: vpx(18)
            anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.bottomMargin: vpx(2); anchors.rightMargin: vpx(2)
            fillMode: Image.PreserveAspectFit; asynchronous: true
            opacity: generalsFlick.atYEnd ? 0 : 0.8
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }
        }

        // Footer
        Rectangle { Layout.fillWidth: true; height: vpx(1); color: "#20FFFFFF"; Layout.topMargin: vpx(6) }
        StyledText { text: "UniKron  •  " + api.collections.count + " Collections  •  " + api.allGames.count + " Games"; font.pixelSize: vpx(10); color: "#444444"; Layout.topMargin: vpx(5) }
      }

      // ── Avatar overlay (front) ────────────────────────────────
      Image {
        source: root.avatarBase + root.profileAvatar
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: vpx(0)
        height: parent.height * 1.15
        width: height * 0.65
        fillMode: Image.PreserveAspectFit
        smooth: true; asynchronous: true
        opacity: 0.55
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // PANEL 2 — PROFILE  (Info | Stats | Edit)
  // ════════════════════════════════════════════════════════════════
  Component {
    id: profilePanel

    Item {
      anchors.fill: parent

      // ── Animated background shapes (Appearance tab — Profile Shape On/Off) ──
      Item {
        visible: root.profileShapeOn
        anchors.fill: parent; z: 0; clip: true
        opacity: root.profileShapeOpacity / 100
        scale: root.profileShapeScale / 100
        transformOrigin: Item.Center

        Repeater {
          model: [
            { xp:.50, yp:.46, sp:.68, a:.07, f:true,  dur:9000, dx:.00, dy:-.04, se:1.18 },
            { xp:.50, yp:.46, sp:.68, a:.26, f:false, dur:9000, dx:.00, dy:-.04, se:1.18 },
            { xp:.72, yp:.20, sp:.20, a:.18, f:false, dur:7000, dx:.04, dy:-.06, se:1.30 },
            { xp:.28, yp:.76, sp:.16, a:.14, f:true,  dur:8500, dx:-.03,dy:-.05, se:1.22 },
            { xp:.82, yp:.62, sp:.13, a:.20, f:false, dur:6500, dx:.05, dy:-.07, se:1.35 },
            { xp:.15, yp:.28, sp:.10, a:.16, f:true,  dur:7500, dx:-.04,dy:-.06, se:1.28 },
            { xp:.62, yp:.84, sp:.09, a:.22, f:false, dur:5800, dx:.03, dy:-.08, se:1.40 },
            { xp:.38, yp:.12, sp:.07, a:.12, f:true,  dur:9500, dx:-.02,dy:-.03, se:1.15 },
            { xp:.88, yp:.38, sp:.06, a:.18, f:false, dur:6200, dx:.06, dy:-.05, se:1.32 },
            { xp:.10, yp:.58, sp:.11, a:.10, f:true,  dur:8000, dx:-.05,dy:-.04, se:1.25 },
            { xp:.55, yp:.30, sp:.05, a:.15, f:false, dur:5500, dx:.02, dy:-.09, se:1.45 },
            { xp:.92, yp:.72, sp:.08, a:.12, f:true,  dur:7200, dx:.04, dy:-.06, se:1.30 },
            { xp:.22, yp:.88, sp:.14, a:.09, f:false, dur:8800, dx:-.03,dy:-.05, se:1.20 },
            { xp:.68, yp:.55, sp:.04, a:.20, f:true,  dur:5200, dx:.07, dy:-.10, se:1.50 },
            { xp:.35, yp:.42, sp:.17, a:.08, f:false, dur:9200, dx:-.04,dy:-.03, se:1.16 }
          ]
          delegate: Item {
            property real bx:    parent.width  * modelData.xp
            property real by:    parent.height * modelData.yp
            property real bsize: Math.min(parent.width, parent.height) * modelData.sp
            property real endX:  parent.width  * (modelData.xp + modelData.dx)
            property real endY:  parent.height * (modelData.yp + modelData.dy)
            x: bx - bsize/2; y: by - bsize/2
            width: bsize; height: bsize
            opacity: modelData.a
            transformOrigin: Item.Center

            Canvas {
              anchors.fill: parent
              property string shapeType: root.profileShape
              property string accentCol: root.accentHex
              property string themeCol:  root.themeHex
              onShapeTypeChanged: requestPaint()
              onAccentColChanged: requestPaint()
              onThemeColChanged:  requestPaint()
              Component.onCompleted: Qt.callLater(requestPaint)
              onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                if (!accentCol || accentCol.length < 7) { Qt.callLater(requestPaint); return }
                var h = accentCol.replace("#","")
                var r = parseInt(h.slice(0,2),16), g = parseInt(h.slice(2,4),16), b = parseInt(h.slice(4,6),16)
                var filled = modelData.f
                ctx.strokeStyle = "rgba("+r+","+g+","+b+",1)"
                ctx.fillStyle   = "rgba("+r+","+g+","+b+",1)"
                ctx.lineWidth = Math.max(1.5, width * 0.04)
                var cx = width/2, cy = height/2, s = Math.min(width,height)/2 - 1
                var i, a, a1, a2, t2, ir2, or3, p, pa, gap, pw, offs, c2, si, sang, srad, starR
                if(shapeType==="circle"){ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="square"){ctx.beginPath();ctx.rect(cx-s,cy-s,s*2,s*2);if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="triangle"){ctx.beginPath();ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.87,cy+s*.5);ctx.lineTo(cx-s*.87,cy+s*.5);ctx.closePath();if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="diamond"){ctx.beginPath();ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.65,cy);ctx.lineTo(cx,cy+s);ctx.lineTo(cx-s*.65,cy);ctx.closePath();if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="hexagon"){ctx.beginPath();for(i=0;i<6;i++){a=Math.PI/180*(60*i-30);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}ctx.closePath();if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="octagon"){ctx.beginPath();for(i=0;i<8;i++){a=Math.PI/180*(45*i+22.5);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}ctx.closePath();if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="rectangle"){ctx.beginPath();ctx.rect(cx-s,cy-s*.6,s*2,s*1.2);if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="star"){ctx.beginPath();for(i=0;i<10;i++){a=Math.PI/180*(36*i-90);starR=i%2===0?s:s*.45;if(i===0)ctx.moveTo(cx+starR*Math.cos(a),cy+starR*Math.sin(a));else ctx.lineTo(cx+starR*Math.cos(a),cy+starR*Math.sin(a))}ctx.closePath();if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="plus"){var arm=s*.36;ctx.beginPath();ctx.moveTo(cx-arm,cy-s);ctx.lineTo(cx+arm,cy-s);ctx.lineTo(cx+arm,cy-arm);ctx.lineTo(cx+s,cy-arm);ctx.lineTo(cx+s,cy+arm);ctx.lineTo(cx+arm,cy+arm);ctx.lineTo(cx+arm,cy+s);ctx.lineTo(cx-arm,cy+s);ctx.lineTo(cx-arm,cy+arm);ctx.lineTo(cx-s,cy+arm);ctx.lineTo(cx-s,cy-arm);ctx.lineTo(cx-arm,cy-arm);ctx.closePath();if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="cross_x"){ctx.lineWidth=s*.36;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx-s*.7,cy-s*.7);ctx.lineTo(cx+s*.7,cy+s*.7);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.7,cy-s*.7);ctx.lineTo(cx-s*.7,cy+s*.7);ctx.stroke()}
                else if(shapeType==="heart"){ctx.beginPath();ctx.moveTo(cx,cy+s*.80);ctx.bezierCurveTo(cx-s*.10,cy+s*.60,cx-s*.90,cy+s*.30,cx-s*.90,cy-s*.10);ctx.bezierCurveTo(cx-s*.90,cy-s*.55,cx-s*.50,cy-s*.80,cx,cy-s*.35);ctx.bezierCurveTo(cx+s*.50,cy-s*.80,cx+s*.90,cy-s*.55,cx+s*.90,cy-s*.10);ctx.bezierCurveTo(cx+s*.90,cy+s*.30,cx+s*.10,cy+s*.60,cx,cy+s*.80);ctx.closePath();if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="spade"){ctx.beginPath();ctx.moveTo(cx,cy-s*.78);ctx.bezierCurveTo(cx+s*.10,cy-s*.58,cx+s*.90,cy-s*.28,cx+s*.90,cy+s*.12);ctx.bezierCurveTo(cx+s*.90,cy+s*.54,cx+s*.50,cy+s*.76,cx,cy+s*.32);ctx.bezierCurveTo(cx-s*.50,cy+s*.76,cx-s*.90,cy+s*.54,cx-s*.90,cy+s*.12);ctx.bezierCurveTo(cx-s*.90,cy-s*.28,cx-s*.10,cy-s*.58,cx,cy-s*.78);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();ctx.lineWidth=s*.16;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx,cy+s*.32);ctx.lineTo(cx,cy+s*.78);ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.38,cy+s*.78);ctx.bezierCurveTo(cx-s*.12,cy+s*.58,cx+s*.12,cy+s*.58,cx+s*.38,cy+s*.78);ctx.stroke()}
                else if(shapeType==="club"){var cPo=[{cx2:cx,cy2:cy-s*.30},{cx2:cx-s*.34,cy2:cy+s*.12},{cx2:cx+s*.34,cy2:cy+s*.12}];for(p=0;p<3;p++){ctx.beginPath();ctx.arc(cPo[p].cx2,cPo[p].cy2,s*.34,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke()}ctx.lineWidth=s*.16;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx,cy+s*.30);ctx.lineTo(cx,cy+s*.78);ctx.stroke();ctx.lineWidth=s*.18;ctx.beginPath();ctx.moveTo(cx-s*.38,cy+s*.78);ctx.bezierCurveTo(cx-s*.12,cy+s*.58,cx+s*.12,cy+s*.58,cx+s*.38,cy+s*.78);ctx.stroke()}
                else if(shapeType==="moon"){ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke();ctx.globalCompositeOperation="destination-out";ctx.beginPath();ctx.arc(cx+s*.40,cy-s*.20,s*.74,0,Math.PI*2);ctx.fillStyle="rgba(0,0,0,1)";ctx.fill();ctx.globalCompositeOperation="source-over"}
                else if(shapeType==="waterdrop"){ctx.beginPath();ctx.moveTo(cx,cy-s*.92);ctx.bezierCurveTo(cx+s*.50,cy-s*.30,cx+s*.82,cy+s*.22,cx,cy+s*.92);ctx.bezierCurveTo(cx-s*.82,cy+s*.22,cx-s*.50,cy-s*.30,cx,cy-s*.92);ctx.closePath();if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="spiral"){ctx.lineWidth=Math.max(1.5,width*.04);ctx.lineCap="round";ctx.beginPath();var turns=3,steps=80;for(var si2=0;si2<=steps;si2++){var theta=turns*Math.PI*2*(si2/steps);var rad3=(s*.92)*(si2/steps);var sx2=cx+rad3*Math.cos(theta-Math.PI/2);var sy2=cy+rad3*Math.sin(theta-Math.PI/2);if(si2===0)ctx.moveTo(sx2,sy2);else ctx.lineTo(sx2,sy2)}ctx.stroke()}
                else if(shapeType==="sparkle"){ctx.beginPath();for(var sp2=0;sp2<8;sp2++){var sa2=Math.PI/4*sp2-Math.PI/2;var rr2=sp2%2===0?s:s*.12;if(sp2===0)ctx.moveTo(cx+rr2*Math.cos(sa2),cy+rr2*Math.sin(sa2));else ctx.lineTo(cx+rr2*Math.cos(sa2),cy+rr2*Math.sin(sa2))}ctx.closePath();if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="smile"){ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke();ctx.fillStyle="rgba("+r+","+g+","+b+",1)";ctx.beginPath();ctx.arc(cx-s*.30,cy-s*.20,s*.11,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx+s*.30,cy-s*.20,s*.11,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx,cy+s*.10,s*.38,Math.PI*0.12,Math.PI*0.88);ctx.stroke()}
                else if(shapeType==="flower"){for(p=0;p<6;p++){pa=Math.PI/180*(60*p);ctx.beginPath();ctx.arc(cx+s*.5*Math.cos(pa),cy+s*.5*Math.sin(pa),s*.42,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke()}ctx.beginPath();ctx.arc(cx,cy,s*.28,0,Math.PI*2);ctx.fill()}
                else if(shapeType==="daisy"){var np3=10;for(p=0;p<np3;p++){pa=Math.PI*2/np3*p;ctx.save();ctx.translate(cx+s*.52*Math.cos(pa),cy+s*.52*Math.sin(pa));ctx.rotate(pa);ctx.beginPath();ctx.save();ctx.scale(s*.22,s*.42);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(filled)ctx.fill();else ctx.stroke();ctx.restore()}ctx.beginPath();ctx.arc(cx,cy,s*.28,0,Math.PI*2);ctx.fill()}
                else if(shapeType==="hexagram"){ctx.beginPath();ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.87,cy+s*.5);ctx.lineTo(cx-s*.87,cy+s*.5);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.moveTo(cx,cy+s);ctx.lineTo(cx+s*.87,cy-s*.5);ctx.lineTo(cx-s*.87,cy-s*.5);ctx.closePath();if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="quatrefoil"){var qr2=s*.50,qd2=s*.36;var qpos2=[{x:cx,y:cy-qd2},{x:cx+qd2,y:cy},{x:cx,y:cy+qd2},{x:cx-qd2,y:cy}];for(p=0;p<4;p++){ctx.beginPath();ctx.arc(qpos2[p].x,qpos2[p].y,qr2,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke()}}
                else if(shapeType==="triquetra"){ctx.lineWidth=s*.16;ctx.lineCap="round";ctx.lineJoin="round";var tr3=s*.66;for(p=0;p<3;p++){var ta=Math.PI*2/3*p-Math.PI/2;var tx2=cx+tr3*Math.cos(ta),ty2=cy+tr3*Math.sin(ta);ctx.save();ctx.translate(tx2,ty2);ctx.rotate(ta+Math.PI/2);ctx.beginPath();ctx.arc(0,0,tr3,Math.PI*0.62,Math.PI*1.38);ctx.stroke();ctx.restore()}}
                else if(shapeType==="gear"){ir2=s*.44;or3=s*.70;ctx.beginPath();for(t2=0;t2<10;t2++){a1=Math.PI*2/10*t2-Math.PI/10*.5;a2=Math.PI*2/10*t2+Math.PI/10*.5;ctx.lineTo(cx+or3*Math.cos(a1),cy+or3*Math.sin(a1));ctx.lineTo(cx+s*Math.cos(a1+Math.PI/10*.25),cy+s*Math.sin(a1+Math.PI/10*.25));ctx.lineTo(cx+s*Math.cos(a2-Math.PI/10*.25),cy+s*Math.sin(a2-Math.PI/10*.25));ctx.lineTo(cx+or3*Math.cos(a2),cy+or3*Math.sin(a2))}ctx.closePath();if(filled)ctx.fill();else ctx.stroke();ctx.globalCompositeOperation="destination-out";ctx.beginPath();ctx.arc(cx,cy,ir2,0,Math.PI*2);ctx.fillStyle="rgba(0,0,0,1)";ctx.fill();ctx.globalCompositeOperation="source-over"}
                else if(shapeType==="windows"){gap=s*.08;pw=(s-gap)*.85;ctx.beginPath();ctx.rect(cx-pw-gap/2,cy-pw-gap/2,pw,pw);if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.rect(cx+gap/2,cy-pw-gap/2,pw,pw);if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.rect(cx-pw-gap/2,cy+gap/2,pw,pw);if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.rect(cx+gap/2,cy+gap/2,pw,pw);if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="chevron"){ctx.lineWidth=s*.22;ctx.lineCap="square";offs=[-s*.38,0,s*.38];for(c2=0;c2<3;c2++){ctx.beginPath();ctx.moveTo(cx-s*.85,cy+s*.45+offs[c2]);ctx.lineTo(cx,cy-s*.05+offs[c2]);ctx.lineTo(cx+s*.85,cy+s*.45+offs[c2]);ctx.stroke()}}
                else if(shapeType==="splat"){for(si=0;si<14;si++){sang=Math.PI*2/14*si;srad=si%2===0?s*(0.7+Math.sin(si*1.7)*.18):s*(0.38+Math.cos(si*2.3)*.12);if(si===0)ctx.moveTo(cx+srad*Math.cos(sang),cy+srad*Math.sin(sang));else ctx.lineTo(cx+srad*Math.cos(sang),cy+srad*Math.sin(sang))}ctx.closePath();if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="music"){ctx.lineWidth=s*.13;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx+s*.18,cy-s*.68);ctx.lineTo(cx+s*.18,cy+s*.28);ctx.stroke();ctx.save();ctx.translate(cx,cy+s*.42);ctx.rotate(-Math.PI/7);ctx.scale(1.4,0.82);ctx.beginPath();ctx.arc(0,0,s*.26,0,Math.PI*2);ctx.fill();ctx.restore()}
                else if(shapeType==="music2"){ctx.lineWidth=s*.12;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx-s*.28,cy-s*.60);ctx.lineTo(cx-s*.28,cy+s*.28);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.28,cy-s*.60);ctx.lineTo(cx+s*.28,cy+s*.28);ctx.stroke();ctx.lineWidth=s*.14;ctx.beginPath();ctx.moveTo(cx-s*.28,cy-s*.60);ctx.lineTo(cx+s*.28,cy-s*.60);ctx.stroke();ctx.save();ctx.translate(cx-s*.28,cy+s*.44);ctx.rotate(-Math.PI/7);ctx.scale(1.4,0.82);ctx.beginPath();ctx.arc(0,0,s*.25,0,Math.PI*2);ctx.fill();ctx.restore();ctx.save();ctx.translate(cx+s*.28,cy+s*.44);ctx.rotate(-Math.PI/7);ctx.scale(1.4,0.82);ctx.beginPath();ctx.arc(0,0,s*.25,0,Math.PI*2);ctx.fill();ctx.restore()}
                else if(shapeType==="cat"){ctx.beginPath();ctx.arc(cx,cy+s*.08,s*.72,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.52,cy-s*.42);ctx.lineTo(cx-s*.22,cy-s*.78);ctx.lineTo(cx-s*.06,cy-s*.38);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.52,cy-s*.42);ctx.lineTo(cx+s*.22,cy-s*.78);ctx.lineTo(cx+s*.06,cy-s*.38);ctx.closePath();if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="bunny"){ctx.save();ctx.translate(cx-s*.28,cy-s*.28);ctx.rotate(-0.14);ctx.beginPath();ctx.save();ctx.scale(s*.20,s*.60);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(filled)ctx.fill();else ctx.stroke();ctx.restore();ctx.save();ctx.translate(cx+s*.28,cy-s*.28);ctx.rotate(0.14);ctx.beginPath();ctx.save();ctx.scale(s*.20,s*.60);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(filled)ctx.fill();else ctx.stroke();ctx.restore();ctx.beginPath();ctx.arc(cx,cy+s*.24,s*.54,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke()}
                else if(shapeType==="android"){ctx.lineWidth=s*.09;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx-s*.28,cy-s*.52);ctx.lineTo(cx-s*.48,cy-s*.88);ctx.stroke();ctx.beginPath();ctx.arc(cx-s*.48,cy-s*.88,s*.06,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.moveTo(cx+s*.28,cy-s*.52);ctx.lineTo(cx+s*.48,cy-s*.88);ctx.stroke();ctx.beginPath();ctx.arc(cx+s*.48,cy-s*.88,s*.06,0,Math.PI*2);ctx.fill();var hr2=s*.14,hx=cx-s*.60,hy=cy-s*.52,hw=s*1.20,hh=s*.76;ctx.beginPath();ctx.moveTo(hx+hr2,hy);ctx.lineTo(hx+hw-hr2,hy);ctx.arc(hx+hw-hr2,hy+hr2,hr2,-Math.PI/2,0);ctx.lineTo(hx+hw,hy+hh-hr2);ctx.arc(hx+hw-hr2,hy+hh-hr2,hr2,0,Math.PI/2);ctx.lineTo(hx+hr2,hy+hh);ctx.arc(hx+hr2,hy+hh-hr2,hr2,Math.PI/2,Math.PI);ctx.lineTo(hx,hy+hr2);ctx.arc(hx+hr2,hy+hr2,hr2,Math.PI,Math.PI*1.5);ctx.closePath();if(filled)ctx.fill();else ctx.stroke()}
                else { ctx.beginPath(); ctx.arc(cx,cy,s,0,Math.PI*2); if(filled)ctx.fill(); else ctx.stroke() }
              }
            }

            SequentialAnimation on x { loops: Animation.Infinite
              NumberAnimation { to: endX - bsize/2; duration: modelData.dur; easing.type: Easing.InOutSine }
              NumberAnimation { to: bx   - bsize/2; duration: modelData.dur; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y { loops: Animation.Infinite
              NumberAnimation { to: endY - bsize/2; duration: modelData.dur; easing.type: Easing.InOutSine }
              NumberAnimation { to: by   - bsize/2; duration: modelData.dur; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on scale { loops: Animation.Infinite
              NumberAnimation { to: modelData.se; duration: modelData.dur; easing.type: Easing.InOutSine }
              NumberAnimation { to: 1.0;          duration: modelData.dur; easing.type: Easing.InOutSine }
            }
          }
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: vpx(18)
        spacing: vpx(0)

        // Header
        Row {
          spacing: vpx(2); Layout.bottomMargin: vpx(8)
          StyledText {
            text: "♟"; font.pixelSize: vpx(26); color: root.accentHex
            anchors.verticalCenter: parent.verticalCenter
            layer.enabled: false
          }
          Rectangle {
            width: vpx(4); height: vpx(30); radius: vpx(2); color: root.accentHex
            anchors.verticalCenter: parent.verticalCenter
          }
          StyledText {
            text: " Profiles "; font.pixelSize: vpx(26); font.bold: true; color: "#FFFFFF"
            anchors.verticalCenter: parent.verticalCenter
            layer.enabled: false
          }
          StyledText {
            text: "Manager"; font.pixelSize: vpx(26); font.bold: true; color: root.accentHex
            anchors.verticalCenter: parent.verticalCenter
            layer.enabled: false
          }
        }

        // Tab bar — small fixed tabs + Appearance fills rest
        Item {
          Layout.fillWidth: true; height: vpx(28); Layout.bottomMargin: vpx(10)
          Row {
            anchors.fill: parent; spacing: vpx(3)
            // Info
            Rectangle {
              property bool active: root.profileTabIndex === 0
              width: (parent.width - vpx(16)) / 5; height: vpx(28); radius: vpx(5)
              color: active ? root.accentHex : root.themeFill

              StyledText { anchors.centerIn: parent; text: "ℹ Info"; font.pixelSize: vpx(11); font.bold: active; color: active ? "#FFFFFF" : "#DDDDDD"; horizontalAlignment: Text.AlignHCenter
 }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.profileTabIndex = 0 }
            }
            // Stats
            Rectangle {
              property bool active: root.profileTabIndex === 1
              width: (parent.width - vpx(16)) / 5; height: vpx(28); radius: vpx(5)
              color: active ? root.accentHex : root.themeFill

              StyledText { anchors.centerIn: parent; text: "📊 Stats"; font.pixelSize: vpx(11); font.bold: active; color: active ? "#FFFFFF" : "#DDDDDD"; horizontalAlignment: Text.AlignHCenter
 }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.profileTabIndex = 1 }
            }
            // Edit
            Rectangle {
              property bool active: root.profileTabIndex === 2
              width: (parent.width - vpx(16)) / 5; height: vpx(28); radius: vpx(5)
              color: active ? root.accentHex : root.themeFill

              StyledText { anchors.centerIn: parent; text: "🛠 Edit"; font.pixelSize: vpx(11); font.bold: active; color: active ? "#FFFFFF" : "#DDDDDD"; horizontalAlignment: Text.AlignHCenter
 }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.profileTabIndex = 2 }
            }
            // Create
            Rectangle {
              property bool active: root.profileTabIndex === 3
              width: (parent.width - vpx(16)) / 5; height: vpx(28); radius: vpx(5)
              color: active ? root.accentHex : root.themeFill

              StyledText { anchors.centerIn: parent; text: "✨ Create"; font.pixelSize: vpx(11); font.bold: active; color: active ? "#FFFFFF" : "#DDDDDD"; horizontalAlignment: Text.AlignHCenter
 }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.profileTabIndex = 3 }
            }
            // Appearance — fills all remaining space
            Rectangle {
              property bool active: root.profileTabIndex === 4
              width: vpx(82)
              height: vpx(28); radius: vpx(5)
              color: active ? root.accentHex : root.themeFill

              StyledText { anchors.centerIn: parent; text: "🎨 Appearance"; font.pixelSize: vpx(11); font.bold: active; color: active ? "#FFFFFF" : "#DDDDDD"; horizontalAlignment: Text.AlignHCenter
 }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.profileTabIndex = 4 }
            }
          }
        }

        Rectangle { Layout.fillWidth: true; height: vpx(1); color: root.accentRgba(0.4); Layout.bottomMargin: vpx(10) }

        Item { Layout.fillWidth: true; Layout.fillHeight: true
        // ── TAB 0: INFO ──────────────────────────────────────────
        Item {
          visible: root.profileTabIndex === 0
          anchors.fill: parent
          id: infoTab
          property int selectedSlot: 0   // 0 = none selected yet

          Component.onCompleted: {
            // Pre-select the slot matching the active profile
            for (var s = 1; s <= 9; s++) {
              var n = api.memory.get("profile.slot." + s + ".name")
              if (n === root.profileName) { selectedSlot = s; break }
            }
            root.infoTabRef = infoTab
          }

          Flickable {
            anchors.fill: parent
            contentHeight: infoListCol.implicitHeight + vpx(10)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
              id: infoListCol
              width: parent.width; spacing: vpx(8)


              // Profile cards — one per occupied slot
              Repeater {
              model: infoSlotsModel
              delegate: Item {
                property int    sn:   model.slotNum
                property string k:    "profile.slot." + sn + "."
                property string name: model.slotName
                property string av:   model.slotAv
                property string gs:   model.slotGs
                property string sub:  model.slotSub
                property string mot:  model.slotMot
                property string col:  model.slotCol
                property string shp:  model.slotShape
                property bool   sel:  infoTab.selectedSlot === sn
                property bool   hov:  false
                width: parent.width; height: vpx(66); visible: true

                function slotAccentRgba(a) {
                  var h = col.replace("#","")
                  return Qt.rgba(parseInt(h.slice(0,2),16)/255, parseInt(h.slice(2,4),16)/255, parseInt(h.slice(4,6),16)/255, a)
                }

                Rectangle {
                  anchors.fill: parent; anchors.bottomMargin: vpx(4)
                  radius: vpx(4)
                  color: sel ? parent.slotAccentRgba(0.22) : parent.hov ? parent.slotAccentRgba(0.12) : "#10FFFFFF"
                  border.color: sel ? parent.col : parent.hov ? parent.col : "#20FFFFFF"
                  border.width: sel ? vpx(2) : parent.hov ? vpx(2) : vpx(1)

                  // Container background image — z:0, below all content
                  Image {
                    visible: root.containersOn && root.containerIndex > 0
                    anchors.fill: parent; anchors.margins: vpx(1)
                    source: (root.containersOn && root.containerIndex > 0) ? root.containerImages[root.containerIndex] : ""
                    fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                    z: 0; opacity: 0.55
                  }

                  Item {
                    anchors.fill: parent; anchors.leftMargin: vpx(6); anchors.rightMargin: vpx(6)
                    z: 1

                    // ── LEFT: accent line + gamerpic ─────────────────
                    Rectangle {
                      id: infoAccentLine
                      width: vpx(3); height: vpx(34); radius: vpx(2); color: col
                      anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter

                    }
                    Rectangle {
                      id: infoGamerpicBox
                      width: vpx(46); height: vpx(46); radius: vpx(4)
                      anchors.left: infoAccentLine.right; anchors.leftMargin: vpx(6)
                      anchors.verticalCenter: parent.verticalCenter
                      color: "#18FFFFFF"; border.color: col; border.width: vpx(1); clip: true
                      Image {
                        anchors.fill: parent; anchors.margins: vpx(2)
                        source: model.slotGp !== "" ? model.slotGp : "../../assets/images/gamerpic/MissingGamerPic.png"
                        fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                        onStatusChanged: if (status === Image.Error) source = "../../assets/images/gamerpic/MissingGamerPic.png"
                      }
                    }

                    // ── RIGHT: avatar shape + slot badge ─────────────
                    Item {
                      id: infoAvatarItem
                      width: vpx(46); height: vpx(46)
                      anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                      property string cardShp: shp
                      property string cardCol: col
                      Canvas {
                        anchors.fill: parent; z: 0
                        property string watchShp: parent.cardShp
                        property string watchCol: parent.cardCol
                        onWatchShpChanged: requestPaint(); onWatchColChanged: requestPaint()
                        Component.onCompleted: Qt.callLater(requestPaint)
                        onPaint: {
                          var ctx = getContext("2d")
                          if(!ctx||width<=0||height<=0){Qt.callLater(requestPaint);return}
                          ctx.clearRect(0,0,width,height)
                          var sk=parent.cardShp, ac2=parent.cardCol
                          var cx=width/2, cy=height/2, s=Math.min(width,height)/2-2
                          var h2=ac2.replace("#","")
                          var r=parseInt(h2.slice(0,2),16),g=parseInt(h2.slice(2,4),16),b=parseInt(h2.slice(4,6),16)
                          var fa="rgba("+r+","+g+","+b+",0.18)",sa="rgba("+r+","+g+","+b+",0.90)"
                          ctx.strokeStyle=sa; ctx.fillStyle=fa; ctx.lineWidth=1.5
                          if(sk==="circle"){ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);ctx.fill();ctx.stroke()
                          }else if(sk==="square"){ctx.beginPath();ctx.rect(cx-s,cy-s,s*2,s*2);ctx.fill();ctx.stroke()
                          }else if(sk==="diamond"){ctx.beginPath();ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.65,cy);ctx.lineTo(cx,cy+s);ctx.lineTo(cx-s*.65,cy);ctx.closePath();ctx.fill();ctx.stroke()
                          }else if(sk==="hexagon"){ctx.beginPath();for(var i=0;i<6;i++){var a=Math.PI/180*(60*i-30);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}ctx.closePath();ctx.fill();ctx.stroke()
                          }else if(sk==="star"){ctx.beginPath();for(var i=0;i<10;i++){var a=Math.PI/180*(36*i-90);var sr=i%2===0?s:s*.42;if(i===0)ctx.moveTo(cx+sr*Math.cos(a),cy+sr*Math.sin(a));else ctx.lineTo(cx+sr*Math.cos(a),cy+sr*Math.sin(a))}ctx.closePath();ctx.fill();ctx.stroke()
                          }else{ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);ctx.fill();ctx.stroke()}
                        }
                      }
                      Image {
                        anchors.centerIn: parent; width: parent.width-vpx(4); height: parent.height-vpx(4)
                        source: root.avatarBase + av; fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true; z: 2
                      }
                      // Slot number badge
                      Rectangle {
                        width: vpx(16); height: vpx(16); radius: vpx(8); color: col
                        anchors.bottom: parent.bottom; anchors.right: parent.right; z: 3

                        StyledText { anchors.centerIn: parent; text: sn.toString(); font.pixelSize: vpx(8); font.bold: true; color: "#FFFFFF"; layer.enabled: false }
                      }
                    }

                    // ── CENTER: name + signed-in badge + action buttons ─
                    Item {
                      anchors.left: infoGamerpicBox.right; anchors.leftMargin: vpx(8)
                      anchors.right: infoAvatarItem.left; anchors.rightMargin: vpx(6)
                      anchors.top: parent.top; anchors.bottom: parent.bottom

                      Row {
                        anchors.left: parent.left
                        anchors.right: infoActionRow.left; anchors.rightMargin: vpx(4)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: vpx(5); clip: true
                        StyledText {
                          id: infoCardName
                          text: name; font.pixelSize: vpx(14); font.bold: true
                          elide: Text.ElideRight; maximumLineCount: 1
                        }
                        Rectangle {
                          visible: root.signedInSlot === sn
                          anchors.verticalCenter: infoCardName.verticalCenter
                          height: vpx(13); width: signedInLbl.implicitWidth + vpx(10); radius: vpx(6)
                          color: "#44FF44"; opacity: 0.85
                          StyledText {
                            id: signedInLbl; anchors.centerIn: parent
                            text: "Signed in!"; font.pixelSize: vpx(8); font.bold: true; color: "#003300"
                            layer.enabled: false
                          }
                        }
                      }

                      Row {
                        id: infoActionRow
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        spacing: vpx(5)

                        Rectangle {
                          id: signInBtn
                          width: vpx(22); height: vpx(22); radius: vpx(11)
                          color: root.signedInSlot === sn ? col : Qt.rgba(1,1,1,0.10)
                          border.color: root.signedInSlot === sn ? col : Qt.rgba(1,1,1,0.35); border.width: vpx(1)
                          StyledText { anchors.centerIn: parent; text: "✓"; font.pixelSize: vpx(12); font.bold: true; color: root.signedInSlot === sn ? "#FFFFFF" : "#888888"; layer.enabled: false }
                          MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              root.signedInSlot = sn
                              api.memory.set("profile.signedSlot", sn.toString())
                              var sk = "profile.slot." + sn + "."
                              root.profileName       = api.memory.get(sk+"name")       || root.profileName
                              root.profileAvatar     = api.memory.get(sk+"avatar")     || "Avatar1.png"
                              root.profileGamerpic   = api.memory.get(sk+"gamerpic")   || ""
                              root.profileGamerscore = parseInt(api.memory.get(sk+"gamerscore") || "0")
                              root.profileStatus     = api.memory.get(sk+"status")     || "Signed In"
                              root.profileSubStatus  = api.memory.get(sk+"substatus")  || "Xbox LIVE Gold"
                              root.profileMotto      = api.memory.get(sk+"motto")      || ""
                              root.profileBio        = api.memory.get(sk+"bio")        || ""
                              root.profileRegion     = api.memory.get(sk+"region")     || ""
                              root.profileColor      = api.memory.get(sk+"color")      || "#0099CC"
                              root.profileShape      = api.memory.get(sk+"shape")      || "circle"
                              api.memory.set("profile.name", root.profileName)
                              for (var cs = 1; cs <= 9; cs++)
                                api.memory.set("profile.slot." + cs + ".showOnDashboard", cs === sn ? "true" : "false")
                              api.memory.set(sk + "showLatestGames", "true")
                              root.rebuildPanels()
                            }
                          }
                        }
                        Rectangle {
                          width: vpx(22); height: vpx(22); radius: vpx(4)
                          color: Qt.rgba(1,1,1,0.08); border.color: Qt.rgba(1,1,1,0.25); border.width: vpx(1)
                          visible: index > 0
                          StyledText { anchors.centerIn: parent; text: "▲"; font.pixelSize: vpx(9); color: "#CCCCCC"; layer.enabled: false }
                          MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              if (index <= 0) return
                              infoSlotsModel.move(index, index - 1, 1)
                              var order = []
                              for (var oi = 0; oi < infoSlotsModel.count; oi++) order.push(infoSlotsModel.get(oi).slotNum)
                              api.memory.set("profile.displayOrder", order.join(","))
                            }
                          }
                        }
                        Rectangle {
                          width: vpx(22); height: vpx(22); radius: vpx(4)
                          color: Qt.rgba(1,1,1,0.08); border.color: Qt.rgba(1,1,1,0.25); border.width: vpx(1)
                          visible: index < infoSlotsModel.count - 1
                          StyledText { anchors.centerIn: parent; text: "▼"; font.pixelSize: vpx(9); color: "#CCCCCC"; layer.enabled: false }
                          MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              if (index >= infoSlotsModel.count - 1) return
                              infoSlotsModel.move(index, index + 1, 1)
                              var order = []
                              for (var oi = 0; oi < infoSlotsModel.count; oi++) order.push(infoSlotsModel.get(oi).slotNum)
                              api.memory.set("profile.displayOrder", order.join(","))
                            }
                          }
                        }
                      }
                    }
                  }

                  MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    z: -1
                    hoverEnabled: true
                    onEntered: parent.parent.hov = true
                    onExited:  parent.parent.hov = false
                    onClicked: {
                      infoTab.selectedSlot = sn
                      for (var ci = 1; ci < panelsModel.count; ci++) {
                        if (panelsModel.get(ci).slotNum === sn) {
                          panelsList.currentIndex = ci; break
                        }
                      }
                    }
                  }
                }
              }
            }
          } // infoListCol Column
          } // Flickable
        }

        // ── TAB 1: STATS ─────────────────────────────────────────
        Item {
          visible: root.profileTabIndex === 1
          anchors.fill: parent

          ListView {
            id: statsRowList
            anchors.fill: parent; anchors.rightMargin: vpx(2)
            clip: true; highlightMoveDuration: 0
            model: [
              { label: "📁  Collections",  value: api.collections.count.toString(),              pct: -1 },
              { label: "🎮  Total Games",  value: api.allGames.count.toString(),                  pct: -1 },
              { label: "⭐  Favorites",    value: listFavorites.games.count.toString(),            pct: Math.min(1, listFavorites.games.count / Math.max(1,api.allGames.count)) },
              { label: "⏱  Play Time",    value: Utils.formatPlayTime(root.totalPlayTime),        pct: -1 },
              { label: "🏆  Most Played",  value: listPlayTime.games.count > 0 ? listPlayTime.games.get(0).title : "—", pct: -1 },
              { label: "🕐  Last Played",  value: listRecent.games.count   > 0 ? listRecent.games.get(0).title   : "—", pct: -1 },
              { label: "📊  Tracked",      value: listRecent.games.count + " sessions",           pct: Math.min(1, listRecent.games.count / Math.max(1,api.allGames.count)) },
              { label: "🎯  Gamerscore",   value: root.profileGamerscore.toString() + " G",       pct: -1 }
            ]
            delegate: Rectangle {
              width: statsRowList.width; height: vpx(34)
              color: index % 2 === 0 ? root.accentRgba(0.08) : "transparent"; radius: vpx(3)
              Column {
                anchors.fill: parent; anchors.leftMargin: vpx(10); anchors.rightMargin: vpx(10); anchors.topMargin: vpx(4); spacing: vpx(2)
                RowLayout {
                  width: parent.width
                  StyledText { text: modelData.label; color: root.accentHex; font.pixelSize: vpx(12); font.bold: true; Layout.fillWidth: true;
 }
                  StyledText { text: modelData.value; font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF"; elide: Text.ElideRight; Layout.preferredWidth: vpx(120); horizontalAlignment: Text.AlignRight;
 }
                }
                Rectangle {
                  visible: modelData.pct >= 0
                  width: parent.width; height: vpx(3); radius: vpx(2); color: root.accentRgba(0.18)
                  Rectangle { width: parent.width * modelData.pct; height: parent.height; radius: parent.radius; color: root.accentHex; Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } } }
                }
              }
              Rectangle { height: vpx(1); width: parent.width; anchors.bottom: parent.bottom; color: root.accentRgba(0.15) }
            }
          }
          Image {
            source: "../../assets/images/system/up-default.png"
            width: vpx(22); height: vpx(18)
            anchors.top: parent.top; anchors.right: parent.right; anchors.margins: vpx(2)
            fillMode: Image.PreserveAspectFit; asynchronous: true
            opacity: statsRowList.atYBeginning ? 0 : 0.8
          }
          Image {
            source: "../../assets/images/system/down-default.png"
            width: vpx(22); height: vpx(18)
            anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: vpx(2)
            fillMode: Image.PreserveAspectFit; asynchronous: true
            opacity: statsRowList.atYEnd ? 0 : 0.8
          }
        }

        // ── TAB 2: EDIT ──────────────────────────────────────────
        Item {
          id: editTab
          property int editingSlot: 0
          property bool profileListExpanded: true
          property bool colorListExpanded: false
          property bool gamerpicListExpanded: false
          property bool avatarListExpanded: false
          property bool shapeListExpanded: false
          property bool borderTopExpanded: false
          property bool borderBottomExpanded: false
          property bool gamerTagExpanded: false
          visible: root.profileTabIndex === 2
          anchors.fill: parent

          function refreshEditInputs() {
            nameInput.text     = root.profileName
            gsInput.text       = root.profileGamerscore.toString()
            statusInput.text   = root.profileStatus
            subInput.text      = root.profileSubStatus
            mottoInput.text    = root.profileMotto
            bioInput.text      = root.profileBio
            regionInput.text   = root.profileRegion
            gpPathInput.text   = root.profileGamerpic
          }
          onEditingSlotChanged: Qt.callLater(refreshEditInputs)

          Flickable {
            id: editFlick
            anchors.fill: parent
            anchors.bottomMargin: vpx(48)
            anchors.rightMargin: vpx(26)
            contentHeight: editCol.implicitHeight + vpx(40)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
              id: editCol
              width: parent.width
              spacing: vpx(10)


              // ── Select Profile Slot ────────────────────────────
              Item {
                width: parent.width; height: vpx(28)

                // Left: accent bar + "Editing Profile" title
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.rightMargin: chooseProfileRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Editing Profile"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                // Right: "Choose Profile ▾" dropdown toggle
                Rectangle {
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24)
                  width: chooseProfileRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)

                  Row {
                    id: chooseProfileRow
                    spacing: vpx(5)
                    anchors.centerIn: parent
                    StyledText {
                      text: "Choose Profile"
                      font.pixelSize: vpx(11); color: "#FFFFFF"
                    }
                    StyledText {
                      text: editTab.profileListExpanded ? "▲" : "▼"
                      font.pixelSize: vpx(10); color: "#FFFFFF"
                    }
                  }
                  MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: editTab.profileListExpanded = !editTab.profileListExpanded
                  }
                }
              }

              Repeater {
                model: editTab.profileListExpanded ? infoSlotsModel : null
                delegate: Item {
                  property int    esn:  model.slotNum
                  property string ename: model.slotName
                  property string eav:  model.slotAv
                  property string egp:  model.slotGp
                  property string ecol: model.slotCol
                  property string eshp: model.slotShape
                  property bool   esel: editTab.editingSlot === esn
                  property bool   ehov: false
                  width: parent.width; height: vpx(66)

                  function eSlotAccentRgba(a) {
                    var h = ecol.replace("#","")
                    return Qt.rgba(parseInt(h.slice(0,2),16)/255, parseInt(h.slice(2,4),16)/255, parseInt(h.slice(4,6),16)/255, a)
                  }

                  Rectangle {
                    anchors.fill: parent; anchors.bottomMargin: vpx(4)
                    radius: vpx(4)
                    color: esel ? parent.eSlotAccentRgba(0.22) : parent.ehov ? parent.eSlotAccentRgba(0.12) : "#10FFFFFF"
                    border.color: esel ? parent.ecol : parent.ehov ? parent.ecol : "#20FFFFFF"
                    border.width: esel ? vpx(2) : parent.ehov ? vpx(2) : vpx(1)

                    // Container background image — z:0, below all content
                    Image {
                      visible: root.containersOn && root.containerIndex > 0
                      anchors.fill: parent; anchors.margins: vpx(1)
                      source: (root.containersOn && root.containerIndex > 0) ? root.containerImages[root.containerIndex] : ""
                      fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                      z: 0; opacity: 0.55
                    }

                    Item {
                      anchors.fill: parent; anchors.leftMargin: vpx(8); anchors.rightMargin: vpx(8)
                      z: 1

                      Rectangle {
                        id: editCardAccentLine
                        width: vpx(3); height: vpx(34); radius: vpx(2); color: ecol
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter

                      }

                      // Gamerpic on the LEFT (after accent line)
                      Rectangle {
                        id: editCardGamerpic
                        width: vpx(52); height: vpx(52); radius: vpx(4)
                        anchors.left: editCardAccentLine.right; anchors.leftMargin: vpx(8)
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#18FFFFFF"
                        border.color: ecol; border.width: vpx(1)
                        clip: true
                        Image {
                          anchors.fill: parent; anchors.margins: vpx(2)
                          source: egp !== "" ? egp : "../../assets/images/gamerpic/MissingGamerPic.png"
                          fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                          onStatusChanged: if (status === Image.Error) source = "../../assets/images/gamerpic/MissingGamerPic.png"
                        }
                      }

                      StyledText {
                        anchors.left: editCardGamerpic.right; anchors.leftMargin: vpx(8)
                        anchors.right: editCardButtons.left; anchors.rightMargin: vpx(8)
                        anchors.verticalCenter: parent.verticalCenter
                        text: ename; font.pixelSize: vpx(15); font.bold: true
                        elide: Text.ElideRight

                      }

                      // Edit + Delete buttons — always shown
                      Row {
                        id: editCardButtons
                        visible: true
                        spacing: vpx(4)
                        anchors.right: editCardAvatarItem.left; anchors.rightMargin: vpx(8)
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                          implicitWidth: editEditLabel.implicitWidth + vpx(14); height: vpx(22); radius: vpx(4)
                          color: root.accentRgba(0.28)
                          border.color: root.accentRgba(0.55); border.width: vpx(1)
                          StyledText { id: editEditLabel; anchors.centerIn: parent; text: "✎ Edit"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF";
 }
                          MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              var sk = "profile.slot." + esn + "."
                              root.profileName       = api.memory.get(sk+"name")       || root.profileName
                              root.profileAvatar     = api.memory.get(sk+"avatar")     || "Avatar1.png"
                              root.profileGamerpic   = api.memory.get(sk+"gamerpic")   || ""
                              root.profileGamerscore = parseInt(api.memory.get(sk+"gamerscore") || "0")
                              root.profileStatus     = api.memory.get(sk+"status")     || "Signed In"
                              root.profileSubStatus  = api.memory.get(sk+"substatus")  || "Xbox LIVE Gold"
                              root.profileMotto      = api.memory.get(sk+"motto")      || ""
                              root.profileBio        = api.memory.get(sk+"bio")        || ""
                              root.profileRegion     = api.memory.get(sk+"region")     || ""
                              root.profileColor      = api.memory.get(sk+"color")      || "#0099CC"
                              root.profileShape      = api.memory.get(sk+"shape")      || "circle"
                              api.memory.set("profile.name",       root.profileName)
                              api.memory.set("profile.avatar",     root.profileAvatar)
                              api.memory.set("profile.gamerpic",   root.profileGamerpic)
                              api.memory.set("profile.gamerscore", root.profileGamerscore.toString())
                              api.memory.set("profile.status",     root.profileStatus)
                              api.memory.set("profile.substatus",  root.profileSubStatus)
                              api.memory.set("profile.motto",      root.profileMotto)
                              api.memory.set("profile.bio",        root.profileBio)
                              api.memory.set("profile.region",     root.profileRegion)
                              api.memory.set("profile.color",      root.profileColor)
                              api.memory.set("profile.shape",      root.profileShape)
                              editTab.editingSlot = esn
                              editTab.profileListExpanded = false
                              Qt.callLater(editTab.refreshEditInputs)
                            }
                          }
                        }
                        Rectangle {
                          implicitWidth: editDeleteLabel.implicitWidth + vpx(14); height: vpx(22); radius: vpx(4)
                          color: Qt.rgba(1,1,1,0.10)
                          border.color: Qt.rgba(1,1,1,0.30); border.width: vpx(1)
                          StyledText { id: editDeleteLabel; anchors.centerIn: parent; text: "🗑 Delete"; font.pixelSize: vpx(10); font.bold: true; color: "#DDDDDD";
 }
                          MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              var sk = "profile.slot." + esn + "."
                              api.memory.set(sk+"name",       "")
                              api.memory.set(sk+"avatar",     "")
                              api.memory.set(sk+"gamerpic",   "")
                              api.memory.set(sk+"gamerscore", "")
                              api.memory.set(sk+"status",     "")
                              api.memory.set(sk+"substatus",  "")
                              api.memory.set(sk+"motto",      "")
                              api.memory.set(sk+"bio",        "")
                              api.memory.set(sk+"region",     "")
                              api.memory.set(sk+"color",      "")
                              api.memory.set(sk+"shape",      "")
                              api.memory.set(sk+"showOnDashboard", "")
                              editTab.editingSlot = 0
                              root.rebuildPanels()
                            }
                          }
                        }
                      }

                      // Avatar + shape on the RIGHT
                      Item {
                        id: editCardAvatarItem
                        width: vpx(52); height: vpx(52)
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        property string cardShp: eshp
                        property string cardCol: ecol

                        Canvas {
                          anchors.fill: parent; z: 0
                          property string watchShp: parent.cardShp
                          property string watchCol: parent.cardCol
                          onWatchShpChanged: requestPaint()
                          onWatchColChanged: requestPaint()
                          Component.onCompleted: Qt.callLater(requestPaint)
                          onPaint: {
                            var ctx = getContext("2d")
                            if(!ctx||width<=0||height<=0){Qt.callLater(requestPaint);return}
                            ctx.clearRect(0, 0, width, height)
                            var sk = parent.cardShp, ac2 = parent.cardCol
                            var cx = width/2, cy = height/2, s = Math.min(width,height)/2 - 2
                            var h2 = ac2.replace("#","")
                            var r=parseInt(h2.slice(0,2),16), g=parseInt(h2.slice(2,4),16), b=parseInt(h2.slice(4,6),16)
                            var fa="rgba("+r+","+g+","+b+",0.18)", sa="rgba("+r+","+g+","+b+",0.90)"
                            ctx.strokeStyle=sa; ctx.fillStyle=fa; ctx.lineWidth=1.5
                            if(sk==="circle"){ ctx.beginPath(); ctx.arc(cx,cy,s,0,Math.PI*2); ctx.fill(); ctx.stroke()
                            }else if(sk==="square"){ ctx.beginPath(); ctx.rect(cx-s,cy-s,s*2,s*2); ctx.fill(); ctx.stroke()
                            }else if(sk==="diamond"){ ctx.beginPath(); ctx.moveTo(cx,cy-s); ctx.lineTo(cx+s*.65,cy); ctx.lineTo(cx,cy+s); ctx.lineTo(cx-s*.65,cy); ctx.closePath(); ctx.fill(); ctx.stroke()
                            }else if(sk==="hexagon"){ ctx.beginPath(); for(var i=0;i<6;i++){var a=Math.PI/180*(60*i-30);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))} ctx.closePath(); ctx.fill(); ctx.stroke()
                            }else if(sk==="star"){ ctx.beginPath(); for(var i=0;i<10;i++){var a=Math.PI/180*(36*i-90);var sr=i%2===0?s:s*.42;if(i===0)ctx.moveTo(cx+sr*Math.cos(a),cy+sr*Math.sin(a));else ctx.lineTo(cx+sr*Math.cos(a),cy+sr*Math.sin(a))} ctx.closePath(); ctx.fill(); ctx.stroke()
                            }else{ ctx.beginPath(); ctx.arc(cx,cy,s,0,Math.PI*2); ctx.fill(); ctx.stroke() }
                          }
                        }
                        Image {
                          anchors.centerIn: parent
                          width: parent.width-vpx(4); height: parent.height-vpx(4)
                          source: root.avatarBase + eav
                          fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true; z: 2
                        }
                        // Slot number badge
                        Rectangle {
                          width: vpx(16); height: vpx(16); radius: vpx(8)
                          color: ecol
                          anchors.bottom: parent.bottom; anchors.left: parent.left
                          z: 3
                          StyledText {
                            anchors.centerIn: parent
                            text: esn.toString(); font.pixelSize: vpx(8); font.bold: true; color: "#FFFFFF"
                            layer.enabled: false
                          }
                        }
                      }
                    }

                    MouseArea {
                      anchors.fill: parent; cursorShape: Qt.PointingHandCursor; z: -1
                      hoverEnabled: true
                      onEntered: parent.parent.ehov = true
                      onExited:  parent.parent.ehov = false
                      onClicked: {
                        var k = "profile.slot." + esn + "."
                        root.profileName       = api.memory.get(k+"name")       || root.profileName
                        root.profileAvatar     = api.memory.get(k+"avatar")     || "Avatar1.png"
                        root.profileGamerpic   = api.memory.get(k+"gamerpic")   || ""
                        root.profileGamerscore = parseInt(api.memory.get(k+"gamerscore") || "0")
                        root.profileStatus     = api.memory.get(k+"status")     || "Signed In"
                        root.profileSubStatus  = api.memory.get(k+"substatus")  || "Xbox LIVE Gold"
                        root.profileMotto      = api.memory.get(k+"motto")      || ""
                        root.profileBio        = api.memory.get(k+"bio")        || ""
                        root.profileRegion     = api.memory.get(k+"region")     || ""
                        root.profileColor      = api.memory.get(k+"color")      || "#0099CC"
                        root.profileShape      = api.memory.get(k+"shape")      || "circle"
                        api.memory.set("profile.name",       root.profileName)
                        api.memory.set("profile.avatar",     root.profileAvatar)
                        api.memory.set("profile.gamerpic",   root.profileGamerpic)
                        api.memory.set("profile.gamerscore", root.profileGamerscore.toString())
                        api.memory.set("profile.status",     root.profileStatus)
                        api.memory.set("profile.substatus",  root.profileSubStatus)
                        api.memory.set("profile.motto",      root.profileMotto)
                        api.memory.set("profile.bio",        root.profileBio)
                        api.memory.set("profile.region",     root.profileRegion)
                        api.memory.set("profile.color",      root.profileColor)
                        api.memory.set("profile.shape",      root.profileShape)
                        editTab.editingSlot = esn
                        Qt.callLater(editTab.refreshEditInputs)
                      }
                    }
                  }
                }
              }
              Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }

              // Selected profile gamertag display — shown when a slot is picked
              Item {
                width: parent.width
                height: editTab.editingSlot > 0 ? vpx(44) : 0
                visible: editTab.editingSlot > 0
                clip: true

                Rectangle {
                  anchors.fill: parent; anchors.bottomMargin: vpx(6)
                  radius: vpx(4)
                  color: root.accentRgba(0.12)
                  border.color: root.accentRgba(0.35); border.width: vpx(1)

                  Row {
                    anchors.left: parent.left; anchors.leftMargin: vpx(10)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(8)

                    // Small avatar thumbnail
                    Rectangle {
                      width: vpx(30); height: vpx(30); radius: vpx(4)
                      color: root.accentRgba(0.15)
                      border.color: root.accentRgba(0.4); border.width: vpx(1)
                      clip: true
                      anchors.verticalCenter: parent.verticalCenter
                      Image {
                        anchors.fill: parent; anchors.margins: vpx(2)
                        source: root.profileGamerpic !== "" ? root.profileGamerpic : "../../assets/images/gamerpic/MissingGamerPic.png"
                        fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                        onStatusChanged: if (status === Image.Error) source = "../../assets/images/gamerpic/MissingGamerPic.png"
                      }
                    }

                    StyledText {
                      text: root.profileName
                      anchors.verticalCenter: parent.verticalCenter
                      font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF"
                    }
                  }

                  // Slot number badge — bottom-right
                  Rectangle {
                    width: vpx(18); height: vpx(18); radius: vpx(9)
                    color: root.accentHex
                    anchors.bottom: parent.bottom; anchors.bottomMargin: vpx(6)
                    anchors.right: parent.right; anchors.rightMargin: vpx(8)
                    StyledText {
                      anchors.centerIn: parent
                      text: editTab.editingSlot.toString()
                      font.pixelSize: vpx(9); font.bold: true; color: "#FFFFFF"
                      layer.enabled: false
                    }
                  }
                }
              }

              Item {
                width: parent.width; height: vpx(28)

                // Left: accent bar + "Colors" title
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.rightMargin: editChooseColorRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Colors"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                // Right: "Choose Color ▾" button
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: editChooseColorRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: editChooseColorRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Color"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: editTab.colorListExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: editTab.colorListExpanded = !editTab.colorListExpanded }
                }
              }
              Column {
                width: parent.width; spacing: vpx(6)
                visible: editTab.colorListExpanded

                // Accent swatches
                StyledText { text: "Accent Color"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Flow {
                  width: parent.width; spacing: vpx(6)
                  Repeater {
                    model: ["#0099CC","#5d9809","#FF5733","#8A2BE2","#FFAA00","#00BFA5","#E91E8C","#FF4500","#1E90FF","#FFD700","#EEEEEE","#DC143C"]
                    delegate: Rectangle {
                      width: vpx(26); height: vpx(26); radius: vpx(13)
                      color: modelData
                      border.color: root.profileColor === modelData ? root.accentRgba(0.85) : "transparent"
                      border.width: vpx(2)
                      MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.profileColor = modelData; api.memory.set("profile.color", modelData) }
                      }
                    }
                  }
                }

                // Theme swatches
                StyledText { text: "Theme Color"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Flow {
                  width: parent.width; spacing: vpx(6)
                  Repeater {
                    model: ["#1E4D8C","#1A6633","#7A1515","#3D1575","#7A5200","#007A66","#454545","#7A1545","#006680","#6B4D00","#1A3D80","#6B0030"]
                    delegate: Rectangle {
                      width: vpx(26); height: vpx(26); radius: vpx(13); color: modelData
                      border.color: (api.memory.get("profile.themeColor") || "") === modelData ? root.accentRgba(0.85) : "transparent"
                      border.width: vpx(2)
                      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: api.memory.set("profile.themeColor", modelData)
                      }
                    }
                  }
                }
              }

              // ── Gamer Pic ──────────────────────────────────────
              Item {
                width: parent.width; height: vpx(28)
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left; anchors.right: parent.right
                  anchors.rightMargin: editChooseGpRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Gamer Pic"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: editChooseGpRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: editChooseGpRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Gamer Pic"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: editTab.gamerpicListExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: editTab.gamerpicListExpanded = !editTab.gamerpicListExpanded }
                }
              }

              Column {
                width: parent.width; spacing: vpx(8)
                visible: editTab.gamerpicListExpanded

                Row {
                  width: parent.width; spacing: vpx(8)
                  Column {
                    id: gpLeftCol
                    width: vpx(60); spacing: vpx(4)
                    Rectangle {
                      id: editGamerpicPreview
                      width: vpx(60); height: vpx(60); radius: vpx(4)
                      color: "#18FFFFFF"; border.color: root.accentHex; border.width: vpx(2); clip: true
                      Image {
                        anchors.fill: parent; anchors.margins: vpx(2)
                        source: root.profileGamerpic !== "" ? root.profileGamerpic : "../../assets/images/gamerpic/MissingGamerPic.png"
                        fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                        onStatusChanged: if (status === Image.Error) source = "../../assets/images/gamerpic/MissingGamerPic.png"
                      }
                    }
                    Rectangle {
                      width: vpx(60); height: vpx(24); radius: vpx(4)
                      color: "#CC000000"; border.color: gsInput.activeFocus ? root.accentHex : "#30FFFFFF"; border.width: vpx(1)
                      Row {
                        anchors.fill: parent; anchors.margins: vpx(4); spacing: vpx(3)
                        StyledText { text: "G"; font.pixelSize: vpx(9); color: root.accentHex; font.bold: true; anchors.verticalCenter: parent.verticalCenter;
 }
                        TextInput {
                          id: gsInput
                          width: parent.width - vpx(14); height: parent.height
                          verticalAlignment: TextInput.AlignVCenter
                          text: root.profileGamerscore.toString(); font.pixelSize: vpx(11); color: "#FFFFFF"
                          selectionColor: root.accentHex; selectByMouse: true; inputMethodHints: Qt.ImhDigitsOnly
                          onEditingFinished: { var n = parseInt(text); if (!isNaN(n)) { root.profileGamerscore = n; api.memory.set("profile.gamerscore", n.toString()) } }
                        }
                      }
                    }
                  }
                  Rectangle {
                    width: parent.width - gpLeftCol.width - vpx(8)
                    height: vpx(28); anchors.verticalCenter: parent.verticalCenter
                    color: "#CC000000"; radius: vpx(4)
                    border.color: "#30FFFFFF"; border.width: vpx(1)
                    Row {
                      anchors.fill: parent; anchors.margins: vpx(5); spacing: vpx(4)
                      Text { text: "🔍"; font.pixelSize: vpx(11); anchors.verticalCenter: parent.verticalCenter }
                      TextInput {
                        id: gpPathInput
                        width: parent.width - vpx(20); height: parent.height
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.profileGamerpic; font.pixelSize: vpx(11); color: "#CCCCCC"
                        selectionColor: root.accentHex; selectByMouse: true
                        onEditingFinished: { root.profileGamerpic = text; api.memory.set("profile.gamerpic", text) }
                        StyledText { visible: parent.text === ""; text: "Browse for Gamer Pic…"; font.pixelSize: vpx(11); color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter;
 }
                      }
                    }
                  }
                }

                Flow {
                  id: gamerpicCatRow
                  property int catIndex: 0
                  width: parent.width; spacing: vpx(5)
                  Repeater {
                    model: ["Default", "Cool Kids"]
                    delegate: Rectangle {
                      property bool active: gamerpicCatRow.catIndex === index
                      width: catLabel.implicitWidth + vpx(16); height: vpx(24); radius: vpx(3)
                      color: active ? root.accentHex : "#14FFFFFF"
                      border.color: active ? root.accentHex : "#25FFFFFF"; border.width: vpx(1)
                      StyledText { id: catLabel; anchors.centerIn: parent; text: modelData; font.pixelSize: vpx(14); font.bold: active; color: active ? "#FFFFFF" : root.accentHex;
 }
                      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: gamerpicCatRow.catIndex = index }
                    }
                  }
                }

                Flow {
                  visible: gamerpicCatRow.catIndex === 0
                  width: parent.width; spacing: vpx(4)
                  Repeater {
                    model: ["MissingGamerPic.png", "Kitkat.png", "Avatar91.png", "GamerPic.png"]
                    delegate: Rectangle {
                      property string fullPath: "../../assets/images/gamerpic/" + modelData
                      property bool selected: root.profileGamerpic === fullPath
                      width: vpx(32); height: vpx(32); radius: vpx(3)
                      color: selected ? root.accentRgba(0.4) : "#14FFFFFF"
                      border.color: selected ? root.accentHex : "#25FFFFFF"; border.width: vpx(1)
                      Image { anchors.fill: parent; anchors.margins: vpx(1); source: fullPath; fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true }
                      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.profileGamerpic = fullPath; api.memory.set("profile.gamerpic", fullPath) } }
                    }
                  }
                }



                Flow {
                  visible: gamerpicCatRow.catIndex === 1
                  width: parent.width; spacing: vpx(4)
                  Repeater {
                    model: [
                      { file: "BubbleKid360.png",    nm: "360" },
                      { file: "BubbleKidBlue.png",   nm: "Blue" },
                      { file: "BubbleKidGreen.png",  nm: "Green" },
                      { file: "BubbleKidRed.png",    nm: "Red" },
                      { file: "BubbleKidSnes.png",   nm: "SNES" },
                      { file: "BubbleKidSwitch.png", nm: "Switch" },
                      { file: "BubbleKidXbOne.png",  nm: "XbOne" }
                    ]
                    delegate: Item {
                      property string fullPath: "../../assets/images/gamerpic/CoolKids/" + modelData.file
                      property bool selected: root.profileGamerpic === fullPath
                      width: vpx(42); height: vpx(52)
                      Rectangle {
                        id: ckBox
                        width: vpx(40); height: vpx(40); radius: vpx(3)
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: selected ? root.accentRgba(0.4) : "#14FFFFFF"
                        border.color: selected ? root.accentHex : "#25FFFFFF"; border.width: vpx(1)
                        Image { anchors.fill: parent; anchors.margins: vpx(2); source: fullPath; fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true }
                      }
                      Text {
                        text: modelData.nm
                        anchors.top: ckBox.bottom; anchors.topMargin: vpx(1)
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: vpx(7); color: selected ? root.accentHex : "#666666"
                        horizontalAlignment: Text.AlignHCenter
                      }
                      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.profileGamerpic = fullPath; api.memory.set("profile.gamerpic", fullPath) } }
                    }
                  }
                }
              } // end gamerpic collapsible

              // ── Gamer Tag ──────────────────────────────────────
              Item {
                width: parent.width; height: vpx(28)
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left; anchors.right: parent.right
                  anchors.rightMargin: editChooseGamerTagRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Gamer Tag"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: editChooseGamerTagRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: editChooseGamerTagRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Gamer Tag"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: editTab.gamerTagExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: editTab.gamerTagExpanded = !editTab.gamerTagExpanded }
                }
              }
              Column {
                visible: editTab.gamerTagExpanded
                width: parent.width; spacing: vpx(10)

                // ── Gamer Tag ──
                Rectangle {
                  width: parent.width; height: vpx(36)
                  color: "#CC000000"; radius: vpx(5)
                  border.color: nameInput.activeFocus ? root.accentHex : "#30FFFFFF"; border.width: vpx(1)
                  TextInput {
                    id: nameInput
                    anchors.fill: parent; anchors.margins: vpx(9)
                    text: root.profileName; font.pixelSize: vpx(14); color: "#FFFFFF"
                    selectionColor: root.accentHex; selectByMouse: true
                    onEditingFinished: { root.profileName = text; api.memory.set("profile.name", text) }
                  }
                }

                // ── Status ──
                StyledText { text: "Status"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Rectangle {
                  width: parent.width; height: vpx(36)
                  color: "#CC000000"; radius: vpx(5)
                  border.color: statusInput.activeFocus ? root.accentHex : "#30FFFFFF"; border.width: vpx(1)
                  TextInput {
                    id: statusInput
                    anchors.fill: parent; anchors.margins: vpx(9)
                    text: root.profileStatus; font.pixelSize: vpx(14); color: "#FFFFFF"
                    selectionColor: root.accentHex; selectByMouse: true
                    onEditingFinished: { root.profileStatus = text; api.memory.set("profile.status", text) }
                  }
                }

                // ── Membership ──
                StyledText { text: "Membership / Sub-status"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Flow {
                  width: parent.width; spacing: vpx(5)
                  Repeater {
                    model: ["Xbox LIVE Gold", "Game Pass Ultimate", "Xbox LIVE Silver", "EA Play", "Game Pass PC", "Steam", "Online", "None"]
                    delegate: Rectangle {
                      property bool active: subInput.text === modelData
                      height: vpx(22); radius: vpx(11)
                      width: subPillLabel.implicitWidth + vpx(16)
                      color: active ? root.accentHex : "#18FFFFFF"
                      border.color: active ? root.accentHex : "#30FFFFFF"; border.width: vpx(1)
                      StyledText {
                        id: subPillLabel
                        anchors.centerIn: parent
                        text: modelData; font.pixelSize: vpx(10)
                        color: active ? "#FFFFFF" : "#AAAAAA";

                      }
                      MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { subInput.text = modelData; root.profileSubStatus = modelData; api.memory.set("profile.substatus", modelData) }
                      }
                    }
                  }
                }
                Rectangle {
                  width: parent.width; height: vpx(36)
                  color: "#CC000000"; radius: vpx(5)
                  border.color: subInput.activeFocus ? root.accentHex : "#30FFFFFF"; border.width: vpx(1)
                  TextInput {
                    id: subInput
                    anchors.fill: parent; anchors.margins: vpx(9)
                    text: root.profileSubStatus; font.pixelSize: vpx(14); color: "#FFFFFF"
                    selectionColor: root.accentHex; selectByMouse: true
                    onEditingFinished: { root.profileSubStatus = text; api.memory.set("profile.substatus", text) }
                  }
                }

                // ── Motto ──
                StyledText { text: "Motto"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Rectangle {
                  width: parent.width; height: vpx(36)
                  color: "#CC000000"; radius: vpx(5)
                  border.color: mottoInput.activeFocus ? root.accentHex : "#30FFFFFF"; border.width: vpx(1)
                  TextInput {
                    id: mottoInput
                    anchors.fill: parent; anchors.margins: vpx(9)
                    text: root.profileMotto; font.pixelSize: vpx(14); color: "#FFFFFF"
                    selectionColor: root.accentHex; selectByMouse: true
                    onEditingFinished: { root.profileMotto = text; api.memory.set("profile.motto", text) }
                  }
                }

                // ── Bio ──
                StyledText { text: "Bio"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Rectangle {
                  width: parent.width; height: vpx(58)
                  color: "#CC000000"; radius: vpx(5)
                  border.color: bioInput.activeFocus ? root.accentHex : "#30FFFFFF"; border.width: vpx(1)
                  TextEdit {
                    id: bioInput
                    anchors.fill: parent; anchors.margins: vpx(9)
                    text: root.profileBio; font.pixelSize: vpx(13); color: "#FFFFFF"
                    selectionColor: root.accentHex; selectByMouse: true; wrapMode: Text.WordWrap
                    onTextChanged: { root.profileBio = text; api.memory.set("profile.bio", text) }
                  }
                }

                // ── Region ──
                StyledText { text: "Region"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Rectangle {
                  width: parent.width; height: vpx(36)
                  color: "#CC000000"; radius: vpx(5)
                  border.color: regionInput.activeFocus ? root.accentHex : "#30FFFFFF"; border.width: vpx(1)
                  TextInput {
                    id: regionInput
                    anchors.fill: parent; anchors.margins: vpx(9)
                    text: root.profileRegion; font.pixelSize: vpx(14); color: "#FFFFFF"
                    selectionColor: root.accentHex; selectByMouse: true
                    onEditingFinished: { root.profileRegion = text; api.memory.set("profile.region", text) }
                  }
                }
              } // end gamerTag collapsible Column

              // ── Choose Avatar (8 items, wrapping Flow) ──────
              Item {
                width: parent.width; height: vpx(28)
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left; anchors.right: parent.right
                  anchors.rightMargin: editChooseAvatarRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Avatar"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: editChooseAvatarRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: editChooseAvatarRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Avatar"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: editTab.avatarListExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: editTab.avatarListExpanded = !editTab.avatarListExpanded }
                }
              }
              Flow {
                visible: editTab.avatarListExpanded
                spacing: vpx(5); width: parent.width
                Repeater {
                  model: root.avatarCount
                  delegate: Rectangle {
                    property string av: "Avatar" + (index+1) + ".png"
                    property bool   selected: root.profileAvatar === av
                    width: vpx(60); height: vpx(60); radius: vpx(4)
                    color:        selected ? root.accentRgba(0.35) : "#22FFFFFF"
                    border.color: selected ? root.accentHex        : "#30FFFFFF"
                    border.width: selected ? vpx(3) : vpx(1)
                    Image { anchors.fill: parent; anchors.margins: vpx(3); source: root.avatarBase + "Avatar" + (index+1) + ".png"; fillMode: Image.PreserveAspectFit; smooth: true }
                    MouseArea {
                      anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { root.profileAvatar = av; api.memory.set("profile.avatar", av) }
                    }
                  }
                }

                // the avatar made in the editor
                Rectangle {
                  visible: root.hasCustomAvatar
                  property bool selected: root.profileAvatar === root.customAvatarName
                  width: vpx(60); height: vpx(60); radius: vpx(4)
                  color:        selected ? root.accentRgba(0.35) : "#22FFFFFF"
                  border.color: selected ? root.accentHex        : "#30FFFFFF"
                  border.width: selected ? vpx(3) : vpx(1)
                  Image {
                    anchors.fill: parent; anchors.margins: vpx(3)
                    source: root.avatarBase + root.customAvatarName + "?v=" + root.customAvatarVersion
                    fillMode: Image.PreserveAspectFit; smooth: true
                  }
                  MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { root.profileAvatar = root.customAvatarName; api.memory.set("profile.avatar", root.customAvatarName) }
                  }
                }

                // "+" — open the avatar editor
                Rectangle {
                  width: vpx(60); height: vpx(60); radius: vpx(4)
                  color:        plusHoverEdit.containsMouse ? root.accentRgba(0.30) : "#22FFFFFF"
                  border.color: root.accentRgba(0.75); border.width: vpx(2)
                  Rectangle { width: vpx(24); height: vpx(3); radius: vpx(1.5); color: "#FFFFFF"; anchors.centerIn: parent }
                  Rectangle { width: vpx(3); height: vpx(24); radius: vpx(1.5); color: "#FFFFFF"; anchors.centerIn: parent }
                  MouseArea {
                    id: plusHoverEdit
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.openAvatarEditor()
                  }
                }

              StyledText {
                visible: root.avatarLoaderFailed
                text: "⚠ avatar editor missing — copy the avatar/ folder into the theme root"
                font.pixelSize: vpx(11); color: "#FF9977"
                width: parent.width; wrapMode: Text.WordWrap
              }
              }

              // ── Save Profile ────────────────────────────────────
              Item { height: vpx(4); width: parent.width }

              // ── Profile Shape + Save button on same row ─────────
              Item {
                width: parent.width; height: vpx(28)
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left; anchors.right: parent.right
                  anchors.rightMargin: editChooseShapeRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Profile Shape"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: editChooseShapeRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: editChooseShapeRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Shape"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: editTab.shapeListExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: editTab.shapeListExpanded = !editTab.shapeListExpanded }
                }
              }

              // ── Shape picker — Flow layout, 10 per row, with name labels ──
              Flow {
                visible: editTab.shapeListExpanded
                spacing: vpx(4); width: parent.width
                Repeater {
                  model: [
                    { key:"circle",     nm:"Circle"    },
                    { key:"square",     nm:"Square"    },
                    { key:"triangle",   nm:"Triangle"  },
                    { key:"diamond",    nm:"Diamond"   },
                    { key:"hexagon",    nm:"Hexagon"   },
                    { key:"octagon",    nm:"Octagon"   },
                    { key:"rectangle",  nm:"Rect"      },
                    { key:"star",       nm:"Star"      },
                    { key:"plus",       nm:"Plus"      },
                    { key:"cross_x",    nm:"X Cross"   },
                    { key:"heart",      nm:"Heart"     },
                    { key:"spade",      nm:"Spade"     },
                    { key:"club",       nm:"Club"      },
                    { key:"moon",       nm:"Moon"      },
                    { key:"waterdrop",  nm:"Drop"      },
                    { key:"spiral",     nm:"Spiral"    },
                    { key:"sparkle",    nm:"Sparkle"   },
                    { key:"smile",      nm:"Smile"     },
                    { key:"flower",     nm:"Flower"    },
                    { key:"daisy",      nm:"Daisy"     },
                    { key:"hexagram",   nm:"Hexagram"  },
                    { key:"quatrefoil", nm:"Quatrefoil"},
                    { key:"triquetra",  nm:"Triquetra" },
                    { key:"gear",       nm:"Gear"      },
                    { key:"windows",    nm:"Windows"   },
                    { key:"chevron",    nm:"Chevron"   },
                    { key:"splat",      nm:"Splat"     },
                    { key:"music",      nm:"Note"      },
                    { key:"music2",     nm:"Beamed"    },
                    { key:"cat",        nm:"Cat"       },
                    { key:"bunny",      nm:"Bunny"     },
                    { key:"android",    nm:"Android"   }
                  ]
                  delegate: Item {
                    property bool sel: root.profileShape === modelData.key
                    width: vpx(43); height: vpx(51)
                    Rectangle {
                      id: shpBox
                      width: vpx(39); height: vpx(39); radius: vpx(4)
                      anchors.horizontalCenter: parent.horizontalCenter
                      color: sel ? root.accentRgba(0.35) : "#14FFFFFF"
                      border.color: sel ? root.accentHex : "#28FFFFFF"
                      border.width: sel ? vpx(2) : vpx(1)
                      Canvas {
                        anchors.fill: parent; anchors.margins: vpx(4)
                        property string sk: modelData.key
                        property string col: root.accentHex
                        property bool isSel: root.profileShape === modelData.key
                        onColChanged:   requestPaint()
                        onIsSelChanged: requestPaint()
                        Component.onCompleted: Qt.callLater(requestPaint)
                        onPaint: {
                          var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                          var h=col.replace("#","")
                          var r=parseInt(h.slice(0,2),16),g=parseInt(h.slice(2,4),16),b=parseInt(h.slice(4,6),16)
                          var fa="rgba("+r+","+g+","+b+",0.32)", sa="rgba("+r+","+g+","+b+",0.9)"
                          ctx.strokeStyle=sa; ctx.fillStyle=isSel ? "rgba("+r+","+g+","+b+",0.65)" : fa; ctx.lineWidth=isSel ? 2.5 : 1.5
                          var cx=width/2, cy=height/2, s=Math.min(width,height)/2-1
                          var i,a,a1,a2,t,teeth,ir,or2,tr,gap,pw,p,pa
                          if(sk==="circle"){
                            ctx.beginPath(); ctx.arc(cx,cy,s,0,Math.PI*2); ctx.fill(); ctx.stroke()

                          }else if(sk==="square"){
                            ctx.beginPath(); ctx.rect(cx-s,cy-s,s*2,s*2); ctx.fill(); ctx.stroke()

                          }else if(sk==="triangle"){
                            ctx.beginPath(); ctx.moveTo(cx,cy-s); ctx.lineTo(cx+s*.87,cy+s*.5); ctx.lineTo(cx-s*.87,cy+s*.5); ctx.closePath(); ctx.fill(); ctx.stroke()

                          }else if(sk==="diamond"){
                            ctx.beginPath(); ctx.moveTo(cx,cy-s); ctx.lineTo(cx+s*.65,cy); ctx.lineTo(cx,cy+s); ctx.lineTo(cx-s*.65,cy); ctx.closePath(); ctx.fill(); ctx.stroke()

                          }else if(sk==="hexagon"){
                            ctx.beginPath()
                            for(i=0;i<6;i++){a=Math.PI/180*(60*i-30);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}
                            ctx.closePath(); ctx.fill(); ctx.stroke()

                          }else if(sk==="octagon"){
                            ctx.beginPath()
                            for(i=0;i<8;i++){a=Math.PI/180*(45*i+22.5);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}
                            ctx.closePath(); ctx.fill(); ctx.stroke()

                          }else if(sk==="rectangle"){
                            ctx.beginPath(); ctx.rect(cx-s,cy-s*.6,s*2,s*1.2); ctx.fill(); ctx.stroke()

                          }else if(sk==="star"){
                            ctx.beginPath()
                            for(i=0;i<10;i++){a=Math.PI/180*(36*i-90);var sr=i%2===0?s:s*.42;if(i===0)ctx.moveTo(cx+sr*Math.cos(a),cy+sr*Math.sin(a));else ctx.lineTo(cx+sr*Math.cos(a),cy+sr*Math.sin(a))}
                            ctx.closePath(); ctx.fill(); ctx.stroke()

                          }else if(sk==="plus"){
                            var arm=s*.36
                            ctx.beginPath()
                            ctx.moveTo(cx-arm,cy-s); ctx.lineTo(cx+arm,cy-s); ctx.lineTo(cx+arm,cy-arm)
                            ctx.lineTo(cx+s,cy-arm); ctx.lineTo(cx+s,cy+arm); ctx.lineTo(cx+arm,cy+arm)
                            ctx.lineTo(cx+arm,cy+s); ctx.lineTo(cx-arm,cy+s); ctx.lineTo(cx-arm,cy+arm)
                            ctx.lineTo(cx-s,cy+arm); ctx.lineTo(cx-s,cy-arm); ctx.lineTo(cx-arm,cy-arm)
                            ctx.closePath(); ctx.fill(); ctx.stroke()

                          }else if(sk==="cross_x"){
                            ctx.lineWidth=s*.36; ctx.lineCap="round"; ctx.strokeStyle=sa
                            ctx.beginPath(); ctx.moveTo(cx-s*.7,cy-s*.7); ctx.lineTo(cx+s*.7,cy+s*.7); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx+s*.7,cy-s*.7); ctx.lineTo(cx-s*.7,cy+s*.7); ctx.stroke()

                          }else if(sk==="heart"){
                            // Clean symmetrical heart using bezier curves
                            ctx.beginPath()
                            ctx.moveTo(cx, cy+s*.80)
                            ctx.bezierCurveTo(cx-s*.10, cy+s*.60, cx-s*.90, cy+s*.30, cx-s*.90, cy-s*.10)
                            ctx.bezierCurveTo(cx-s*.90, cy-s*.55, cx-s*.50, cy-s*.80, cx, cy-s*.35)
                            ctx.bezierCurveTo(cx+s*.50, cy-s*.80, cx+s*.90, cy-s*.55, cx+s*.90, cy-s*.10)
                            ctx.bezierCurveTo(cx+s*.90, cy+s*.30, cx+s*.10, cy+s*.60, cx, cy+s*.80)
                            ctx.closePath(); ctx.fill(); ctx.stroke()

                          }else if(sk==="spade"){
                            // Clean spade: inverted heart top + stem + base bar
                            ctx.beginPath()
                            ctx.moveTo(cx, cy-s*.78)
                            ctx.bezierCurveTo(cx+s*.10, cy-s*.58, cx+s*.90, cy-s*.28, cx+s*.90, cy+s*.12)
                            ctx.bezierCurveTo(cx+s*.90, cy+s*.54, cx+s*.50, cy+s*.76, cx, cy+s*.32)
                            ctx.bezierCurveTo(cx-s*.50, cy+s*.76, cx-s*.90, cy+s*.54, cx-s*.90, cy+s*.12)
                            ctx.bezierCurveTo(cx-s*.90, cy-s*.28, cx-s*.10, cy-s*.58, cx, cy-s*.78)
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                            // Stem
                            ctx.lineWidth=s*.16; ctx.lineCap="round"; ctx.strokeStyle=sa
                            ctx.beginPath(); ctx.moveTo(cx,cy+s*.32); ctx.lineTo(cx,cy+s*.78); ctx.stroke()
                            // Base bar
                            ctx.lineWidth=s*.18
                            ctx.beginPath(); ctx.moveTo(cx-s*.38,cy+s*.78); ctx.bezierCurveTo(cx-s*.12,cy+s*.58,cx+s*.12,cy+s*.58,cx+s*.38,cy+s*.78); ctx.stroke()

                          }else if(sk==="club"){
                            var cPos=[{x:cx,y:cy-s*.30},{x:cx-s*.34,y:cy+s*.12},{x:cx+s*.34,y:cy+s*.12}]
                            for(p=0;p<3;p++){ctx.beginPath();ctx.arc(cPos[p].x,cPos[p].y,s*.34,0,Math.PI*2);ctx.fill();ctx.stroke()}
                            ctx.lineWidth=s*.16; ctx.lineCap="round"
                            ctx.beginPath(); ctx.moveTo(cx,cy+s*.30); ctx.lineTo(cx,cy+s*.78); ctx.stroke()
                            ctx.lineWidth=s*.18
                            ctx.beginPath(); ctx.moveTo(cx-s*.38,cy+s*.78); ctx.bezierCurveTo(cx-s*.12,cy+s*.58,cx+s*.12,cy+s*.58,cx+s*.38,cy+s*.78); ctx.stroke()

                          }else if(sk==="moon"){
                            ctx.beginPath(); ctx.arc(cx,cy,s,0,Math.PI*2); ctx.fill(); ctx.stroke()
                            ctx.globalCompositeOperation="destination-out"
                            ctx.beginPath(); ctx.arc(cx+s*.40,cy-s*.20,s*.74,0,Math.PI*2); ctx.fillStyle="rgba(0,0,0,1)"; ctx.fill()
                            ctx.globalCompositeOperation="source-over"
                            ctx.beginPath(); ctx.arc(cx,cy,s, -Math.PI*.52, Math.PI*.70); ctx.strokeStyle=sa; ctx.stroke()

                          }else if(sk==="waterdrop"){
                            ctx.beginPath()
                            ctx.moveTo(cx, cy-s*.92)
                            ctx.bezierCurveTo(cx+s*.50, cy-s*.30, cx+s*.82, cy+s*.22, cx, cy+s*.92)
                            ctx.bezierCurveTo(cx-s*.82, cy+s*.22, cx-s*.50, cy-s*.30, cx, cy-s*.92)
                            ctx.closePath(); ctx.fill(); ctx.stroke()

                          }else if(sk==="spiral"){
                            ctx.strokeStyle=sa; ctx.lineWidth=1.5; ctx.lineCap="round"
                            ctx.beginPath()
                            var turns=3, steps=120
                            for(i=0;i<=steps;i++){
                              var theta=turns*Math.PI*2*(i/steps)
                              var rad2=(s*.92)*(i/steps)
                              var sx2=cx+rad2*Math.cos(theta-Math.PI/2)
                              var sy2=cy+rad2*Math.sin(theta-Math.PI/2)
                              if(i===0) ctx.moveTo(sx2,sy2); else ctx.lineTo(sx2,sy2)
                            }
                            ctx.stroke()

                          }else if(sk==="sparkle"){
                            ctx.beginPath()
                            for(i=0;i<8;i++){
                              a=Math.PI/4*i-Math.PI/2
                              var rr=i%2===0?s:s*.12
                              if(i===0)ctx.moveTo(cx+rr*Math.cos(a),cy+rr*Math.sin(a)); else ctx.lineTo(cx+rr*Math.cos(a),cy+rr*Math.sin(a))
                            }
                            ctx.closePath(); ctx.fill(); ctx.stroke()

                          }else if(sk==="smile"){
                            ctx.beginPath(); ctx.arc(cx,cy,s,0,Math.PI*2); ctx.fill(); ctx.stroke()
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"
                            ctx.beginPath(); ctx.arc(cx-s*.30,cy-s*.20,s*.11,0,Math.PI*2); ctx.fill()
                            ctx.beginPath(); ctx.arc(cx+s*.30,cy-s*.20,s*.11,0,Math.PI*2); ctx.fill()
                            ctx.beginPath(); ctx.strokeStyle=sa; ctx.lineWidth=1.6; ctx.lineCap="round"
                            ctx.arc(cx, cy+s*.10, s*.38, Math.PI*0.12, Math.PI*0.88); ctx.stroke()

                          }else if(sk==="flower"){
                            for(p=0;p<6;p++){pa=Math.PI/180*(60*p);var px=cx+s*.50*Math.cos(pa),py=cy+s*.50*Math.sin(pa);ctx.beginPath();ctx.arc(px,py,s*.40,0,Math.PI*2);ctx.fill();ctx.stroke()}
                            ctx.beginPath(); ctx.arc(cx,cy,s*.26,0,Math.PI*2); ctx.fillStyle="rgba("+r+","+g+","+b+",0.75)"; ctx.fill()

                          }else if(sk==="daisy"){
                            var np=10
                            for(p=0;p<np;p++){
                              pa=Math.PI*2/np*p
                              ctx.save(); ctx.translate(cx+s*.52*Math.cos(pa),cy+s*.52*Math.sin(pa)); ctx.rotate(pa)
                              ctx.save(); ctx.scale(s*.22,s*.42); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore()
                              ctx.fill(); ctx.stroke(); ctx.restore()
                            }
                            ctx.beginPath(); ctx.arc(cx,cy,s*.26,0,Math.PI*2); ctx.fillStyle="rgba("+r+","+g+","+b+",0.85)"; ctx.fill()

                          }else if(sk==="hexagram"){
                            ctx.beginPath(); ctx.moveTo(cx,cy-s); ctx.lineTo(cx+s*.87,cy+s*.5); ctx.lineTo(cx-s*.87,cy+s*.5); ctx.closePath(); ctx.fill(); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx,cy+s); ctx.lineTo(cx+s*.87,cy-s*.5); ctx.lineTo(cx-s*.87,cy-s*.5); ctx.closePath(); ctx.fill(); ctx.stroke()

                          }else if(sk==="quatrefoil"){
                            var qr=s*.50, qd=s*.36
                            var qpos=[{x:cx,y:cy-qd},{x:cx+qd,y:cy},{x:cx,y:cy+qd},{x:cx-qd,y:cy}]
                            for(p=0;p<4;p++){ctx.beginPath();ctx.arc(qpos[p].x,qpos[p].y,qr,0,Math.PI*2);ctx.fill();ctx.stroke()}
                            ctx.beginPath(); ctx.arc(cx,cy,s*.20,0,Math.PI*2); ctx.fillStyle="rgba("+r+","+g+","+b+",0.75)"; ctx.fill()

                          }else if(sk==="triquetra"){
                            ctx.strokeStyle=sa; ctx.lineWidth=s*.16; ctx.lineCap="round"; ctx.lineJoin="round"
                            var tr2=s*.66
                            for(p=0;p<3;p++){
                              a=Math.PI*2/3*p-Math.PI/2
                              var tx=cx+tr2*Math.cos(a), ty=cy+tr2*Math.sin(a)
                              ctx.save(); ctx.translate(tx,ty); ctx.rotate(a+Math.PI/2)
                              ctx.beginPath(); ctx.arc(0,0,tr2,Math.PI*0.62,Math.PI*1.38); ctx.stroke()
                              ctx.restore()
                            }

                          }else if(sk==="gear"){
                            teeth=10; ir=s*.44; or2=s*.70; tr=s*.90
                            ctx.beginPath()
                            for(t=0;t<teeth;t++){
                              a1=Math.PI*2/teeth*t-Math.PI/teeth*.5; a2=Math.PI*2/teeth*t+Math.PI/teeth*.5
                              ctx.lineTo(cx+or2*Math.cos(a1),cy+or2*Math.sin(a1))
                              ctx.lineTo(cx+tr*Math.cos(a1+Math.PI/teeth*.25),cy+tr*Math.sin(a1+Math.PI/teeth*.25))
                              ctx.lineTo(cx+tr*Math.cos(a2-Math.PI/teeth*.25),cy+tr*Math.sin(a2-Math.PI/teeth*.25))
                              ctx.lineTo(cx+or2*Math.cos(a2),cy+or2*Math.sin(a2))
                            }
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                            ctx.globalCompositeOperation="destination-out"
                            ctx.beginPath(); ctx.arc(cx,cy,ir,0,Math.PI*2); ctx.fillStyle="rgba(0,0,0,1)"; ctx.fill()
                            ctx.globalCompositeOperation="source-over"

                          }else if(sk==="windows"){
                            gap=s*.10; pw=(s-gap)*.86
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.55)"; ctx.strokeStyle=sa
                            ctx.beginPath(); ctx.rect(cx-pw-gap/2,cy-pw-gap/2,pw,pw); ctx.fill(); ctx.stroke()
                            ctx.beginPath(); ctx.rect(cx+gap/2,cy-pw-gap/2,pw,pw); ctx.fill(); ctx.stroke()
                            ctx.beginPath(); ctx.rect(cx-pw-gap/2,cy+gap/2,pw,pw); ctx.fill(); ctx.stroke()
                            ctx.beginPath(); ctx.rect(cx+gap/2,cy+gap/2,pw,pw); ctx.fill(); ctx.stroke()

                          }else if(sk==="chevron"){
                            ctx.lineWidth=s*.19; ctx.lineCap="square"; ctx.lineJoin="miter"; ctx.strokeStyle=sa
                            var offsets=[-s*.34,0,s*.34]
                            for(var c=0;c<3;c++){
                              var yo=offsets[c]
                              ctx.beginPath(); ctx.moveTo(cx-s*.80,cy+s*.40+yo); ctx.lineTo(cx,cy-s*.08+yo); ctx.lineTo(cx+s*.80,cy+s*.40+yo); ctx.stroke()
                            }

                          }else if(sk==="splat"){
                            ctx.beginPath()
                            var pts=14
                            for(i=0;i<pts;i++){
                              var ang=Math.PI*2/pts*i
                              var srad=i%2===0?s*(0.70+Math.sin(i*1.7)*.18):s*(0.38+Math.cos(i*2.3)*.12)
                              if(i===0)ctx.moveTo(cx+srad*Math.cos(ang),cy+srad*Math.sin(ang)); else ctx.lineTo(cx+srad*Math.cos(ang),cy+srad*Math.sin(ang))
                            }
                            ctx.closePath(); ctx.fill(); ctx.stroke()

                          }else if(sk==="music"){
                            // Single eighth note: vertical stem + curved flag + tilted filled notehead
                            ctx.strokeStyle=sa; ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"
                            // Notehead — filled oval bottom-left, tilted
                            ctx.save(); ctx.translate(cx-s*.10, cy+s*.36); ctx.rotate(-0.40)
                            ctx.save(); ctx.scale(s*.30,s*.20); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore()
                            ctx.fill(); ctx.restore()
                            // Stem — right edge of notehead upward
                            ctx.lineWidth=s*.11; ctx.lineCap="round"
                            ctx.beginPath(); ctx.moveTo(cx+s*.18,cy+s*.26); ctx.lineTo(cx+s*.18,cy-s*.68); ctx.stroke()
                            // Flag — curves right from top of stem
                            ctx.lineWidth=s*.09
                            ctx.beginPath()
                            ctx.moveTo(cx+s*.18, cy-s*.68)
                            ctx.bezierCurveTo(cx+s*.60,cy-s*.52, cx+s*.60,cy-s*.28, cx+s*.18,cy-s*.16)
                            ctx.stroke()

                          }else if(sk==="music2"){
                            // Two beamed eighth notes
                            ctx.strokeStyle=sa; ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"
                            var n1x=cx-s*.28, n2x=cx+s*.26, stemTop=cy-s*.70, stemBot=cy+s*.30
                            // Noteheads
                            ctx.save(); ctx.translate(n1x-s*.08,stemBot); ctx.rotate(-0.38)
                            ctx.save(); ctx.scale(s*.26,s*.18); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            ctx.save(); ctx.translate(n2x-s*.08,stemBot); ctx.rotate(-0.38)
                            ctx.save(); ctx.scale(s*.26,s*.18); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            // Stems
                            ctx.lineWidth=s*.10; ctx.lineCap="round"
                            ctx.beginPath(); ctx.moveTo(n1x,stemBot); ctx.lineTo(n1x,stemTop); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(n2x,stemBot); ctx.lineTo(n2x,stemTop); ctx.stroke()
                            // Beam bars
                            ctx.lineWidth=s*.14
                            ctx.beginPath(); ctx.moveTo(n1x,stemTop); ctx.lineTo(n2x,stemTop); ctx.stroke()
                            ctx.lineWidth=s*.12
                            ctx.beginPath(); ctx.moveTo(n1x,stemTop+s*.17); ctx.lineTo(n2x,stemTop+s*.17); ctx.stroke()

                          }else if(sk==="cat"){
                            ctx.beginPath(); ctx.arc(cx,cy+s*.08,s*.70,0,Math.PI*2); ctx.fill(); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx-s*.50,cy-s*.40); ctx.lineTo(cx-s*.22,cy-s*.76); ctx.lineTo(cx-s*.06,cy-s*.36); ctx.closePath(); ctx.fillStyle="rgba("+r+","+g+","+b+",0.45)"; ctx.fill(); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx+s*.50,cy-s*.40); ctx.lineTo(cx+s*.22,cy-s*.76); ctx.lineTo(cx+s*.06,cy-s*.36); ctx.closePath(); ctx.fill(); ctx.stroke()
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"
                            // Eyes — use arc instead of ellipse
                            ctx.save(); ctx.translate(cx-s*.26,cy-s*.04); ctx.save(); ctx.scale(s*.12,s*.15); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            ctx.save(); ctx.translate(cx+s*.26,cy-s*.04); ctx.save(); ctx.scale(s*.12,s*.15); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            ctx.beginPath(); ctx.moveTo(cx,cy+s*.18); ctx.lineTo(cx-s*.08,cy+s*.28); ctx.lineTo(cx+s*.08,cy+s*.28); ctx.closePath(); ctx.fillStyle="rgba("+r+","+g+","+b+",0.8)"; ctx.fill()
                            ctx.lineWidth=0.9; ctx.strokeStyle="rgba("+r+","+g+","+b+",0.65)"
                            ctx.beginPath(); ctx.moveTo(cx-s*.16,cy+s*.24); ctx.lineTo(cx-s*.76,cy+s*.18); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx-s*.16,cy+s*.30); ctx.lineTo(cx-s*.76,cy+s*.32); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx+s*.16,cy+s*.24); ctx.lineTo(cx+s*.76,cy+s*.18); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx+s*.16,cy+s*.30); ctx.lineTo(cx+s*.76,cy+s*.32); ctx.stroke()

                          }else if(sk==="bunny"){
                            // Big round head
                            ctx.beginPath(); ctx.arc(cx, cy+s*.22, s*.54, 0, Math.PI*2); ctx.fill(); ctx.stroke()
                            // Big tall left ear
                            ctx.save(); ctx.translate(cx-s*.28, cy-s*.30); ctx.rotate(-0.14)
                            ctx.save(); ctx.scale(s*.20, s*.58); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.stroke(); ctx.restore()
                            // Big tall right ear
                            ctx.save(); ctx.translate(cx+s*.28, cy-s*.30); ctx.rotate(0.14)
                            ctx.save(); ctx.scale(s*.20, s*.58); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.stroke(); ctx.restore()
                            // Inner ear left (hollow)
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.28)"
                            ctx.save(); ctx.translate(cx-s*.28, cy-s*.30); ctx.rotate(-0.14)
                            ctx.save(); ctx.scale(s*.10, s*.42); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            // Inner ear right (hollow)
                            ctx.save(); ctx.translate(cx+s*.28, cy-s*.30); ctx.rotate(0.14)
                            ctx.save(); ctx.scale(s*.10, s*.42); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            // Eyes
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"
                            ctx.save(); ctx.translate(cx-s*.20,cy+s*.12); ctx.save(); ctx.scale(s*.10,s*.12); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            ctx.save(); ctx.translate(cx+s*.20,cy+s*.12); ctx.save(); ctx.scale(s*.10,s*.12); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            // Nose
                            ctx.beginPath(); ctx.arc(cx, cy+s*.30, s*.06, 0, Math.PI*2); ctx.fill()

                          }else if(sk==="android"){
                            // Android robot head silhouette
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.32)"; ctx.strokeStyle=sa; ctx.lineWidth=1.5
                            // Left antenna
                            ctx.lineWidth=s*.09; ctx.lineCap="round"
                            ctx.beginPath(); ctx.moveTo(cx-s*.28,cy-s*.52); ctx.lineTo(cx-s*.48,cy-s*.88); ctx.stroke()
                            ctx.beginPath(); ctx.arc(cx-s*.48,cy-s*.88,s*.06,0,Math.PI*2); ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"; ctx.fill()
                            // Right antenna
                            ctx.beginPath(); ctx.moveTo(cx+s*.28,cy-s*.52); ctx.lineTo(cx+s*.48,cy-s*.88); ctx.stroke()
                            ctx.beginPath(); ctx.arc(cx+s*.48,cy-s*.88,s*.06,0,Math.PI*2); ctx.fill()
                            // Head — rounded rect (arc corners)
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.32)"; ctx.lineWidth=1.5
                            var hr2=s*.16, hx=cx-s*.62, hy=cy-s*.52, hw=s*1.24, hh=s*.78
                            ctx.beginPath()
                            ctx.moveTo(hx+hr2,hy); ctx.lineTo(hx+hw-hr2,hy); ctx.arc(hx+hw-hr2,hy+hr2,hr2,-Math.PI/2,0)
                            ctx.lineTo(hx+hw,hy+hh-hr2); ctx.arc(hx+hw-hr2,hy+hh-hr2,hr2,0,Math.PI/2)
                            ctx.lineTo(hx+hr2,hy+hh); ctx.arc(hx+hr2,hy+hh-hr2,hr2,Math.PI/2,Math.PI)
                            ctx.lineTo(hx,hy+hr2); ctx.arc(hx+hr2,hy+hr2,hr2,Math.PI,Math.PI*1.5)
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                            // Eyes
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"
                            ctx.beginPath(); ctx.arc(cx-s*.24,cy-s*.20,s*.10,0,Math.PI*2); ctx.fill()
                            ctx.beginPath(); ctx.arc(cx+s*.24,cy-s*.20,s*.10,0,Math.PI*2); ctx.fill()
                            // Body
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.22)"; ctx.lineWidth=1.5
                            var bx2=cx-s*.55, by2=cy+s*.32, bw=s*1.10, bh=s*.60, br=s*.10
                            ctx.beginPath()
                            ctx.moveTo(bx2+br,by2); ctx.lineTo(bx2+bw-br,by2); ctx.arc(bx2+bw-br,by2+br,br,-Math.PI/2,0)
                            ctx.lineTo(bx2+bw,by2+bh-br); ctx.arc(bx2+bw-br,by2+bh-br,br,0,Math.PI/2)
                            ctx.lineTo(bx2+br,by2+bh); ctx.arc(bx2+br,by2+bh-br,br,Math.PI/2,Math.PI)
                            ctx.lineTo(bx2,by2+br); ctx.arc(bx2+br,by2+br,br,Math.PI,Math.PI*1.5)
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                          }
                        }
                      }
                    }
                    Text {
                      text: modelData.nm
                      anchors.top: shpBox.bottom; anchors.topMargin: vpx(1)
                      anchors.horizontalCenter: parent.horizontalCenter
                      font.pixelSize: vpx(7); color: sel ? root.accentHex : "#666666"
                      horizontalAlignment: Text.AlignHCenter
                    }
                    MouseArea {
                      anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { root.profileShape=modelData.key; api.memory.set("profile.shape",modelData.key) }
                    }
                  }
                }
              }

              // ── Profile Top Border Emojis ─────────────────────────
              Item {
                width: parent.width; height: vpx(28)
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left; anchors.right: parent.right
                  anchors.rightMargin: editChooseBdrTopRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Top Border"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: editChooseBdrTopRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: editChooseBdrTopRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Top Border"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: editTab.borderTopExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: editTab.borderTopExpanded = !editTab.borderTopExpanded }
                }
              }
              Flow {
                visible: editTab.borderTopExpanded
                spacing: vpx(4); width: parent.width
                Repeater {
                  model: [
                    { key:"▀▄▀▄▀▄",                  nm:"Blocks"   },
                    { key:"⫘⫘⫘⫘⫘⫘",                nm:"Lines"    },
                    { key:"⸝⸝⸝⸝⸝⸝",             nm:"Waves"    },
                    { key:"*ੈ✩‧₊˚༺☆༻*ੈ✩‧₊˚",       nm:"Stars"    },
                    { key:":･ﾟ✧:･.☽˚｡･ﾟ✧:･.:",     nm:"Moon"     },
                    { key:"﹌﹌﹌﹌﹌",               nm:"Squig"    },
                    { key:"⋆༺𓆩☠︎︎𓆪༻⋆",              nm:"Skull"    },
                    { key:"✩♬ ₊˚.♪⋆☾⋆⁺₊✧",          nm:"Music"    },
                    { key:"✪ ✪ ✪ ✪ ✪",              nm:"Stars2"   },
                    { key:"▄︻デ══━一 ▄︻デ══━一",      nm:"Guns"     },
                    { key:"✦ ✧ ✦ ✧ ✦ ✧ ✦",          nm:"Diamond"  },
                    { key:"≋≋≋≋≋≋≋≋≋",              nm:"Ripple"   },
                    { key:"◈ ◈ ◈ ◈ ◈ ◈",            nm:"Compass"  },
                    { key:"⬡ ⬡ ⬡ ⬡ ⬡ ⬡",            nm:"Hex"      },
                    { key:"✶ ✶ ✶ ✶ ✶ ✶",            nm:"Burst"    },
                    { key:"❖ ❖ ❖ ❖ ❖ ❖",            nm:"Ornament" },
                    { key:"⁕ ⁕ ⁕ ⁕ ⁕ ⁕ ⁕",          nm:"Flower"   },
                    { key:"╔══════╗",                nm:"Frame"    },
                    { key:"◄◄◄◄◄◄◄◄◄",              nm:"Arrows"   },
                    { key:"░▒▓▓▒░",                  nm:"Fade"     },
                    { key:"",                         nm:"None"     }
                  ]
                  delegate: Item {
                    property bool sel: editTab.editingSlot > 0 ? ((api.memory.get("profile.slot." + editTab.editingSlot + ".borderTop") || "") === modelData.key) : ((api.memory.get("profile.borderTop") || "") === modelData.key)
                    width: (parent.width - vpx(4)*5) / 6; height: vpx(52)
                    Rectangle {
                      id: bdrTopBox
                      anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                      width: vpx(58); height: vpx(30); radius: vpx(4)
                      color: sel ? root.accentRgba(0.35) : "#14FFFFFF"
                      border.color: sel ? root.accentHex : "#28FFFFFF"
                      border.width: sel ? vpx(2) : vpx(1)
                      StyledText {
                        anchors.centerIn: parent
                        width: parent.width - vpx(6)
                        text: modelData.key !== "" ? modelData.key : "— None —"
                        font.pixelSize: vpx(11); color: sel ? root.accentHex : "#FFFFFF"
                        elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                      }
                    }
                    Text {
                      anchors.top: bdrTopBox.bottom; anchors.topMargin: vpx(2)
                      anchors.horizontalCenter: parent.horizontalCenter
                      width: parent.width
                      text: modelData.nm
                      font.pixelSize: vpx(8); color: sel ? root.accentHex : "#AAAAAA"
                      horizontalAlignment: Text.AlignHCenter
                    }
                    MouseArea {
                      anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { var k = editTab.editingSlot > 0 ? "profile.slot." + editTab.editingSlot + ".borderTop" : "profile.borderTop"; api.memory.set(k, modelData.key) }
                    }
                  }
                }
              }

              // ── Profile Bottom Border Emojis ──────────────────────
              Item {
                width: parent.width; height: vpx(28)
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left; anchors.right: parent.right
                  anchors.rightMargin: editChooseBdrBotRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Bottom Border"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: editChooseBdrBotRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: editChooseBdrBotRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Bottom Border"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: editTab.borderBottomExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: editTab.borderBottomExpanded = !editTab.borderBottomExpanded }
                }
              }
              Flow {
                visible: editTab.borderBottomExpanded
                spacing: vpx(4); width: parent.width
                Repeater {
                  model: [
                    { key:"▀▄▀▄▀▄",                  nm:"Blocks"   },
                    { key:"⫘⫘⫘⫘⫘⫘",                nm:"Lines"    },
                    { key:"⸝⸝⸝⸝⸝⸝",             nm:"Waves"    },
                    { key:"*ੈ✩‧₊˚༺☆༻*ੈ✩‧₊˚",       nm:"Stars"    },
                    { key:":･ﾟ✧:･.☽˚｡･ﾟ✧:･.:",     nm:"Moon"     },
                    { key:"﹌﹌﹌﹌﹌",               nm:"Squig"    },
                    { key:"⋆༺𓆩☠︎︎𓆪༻⋆",              nm:"Skull"    },
                    { key:"✩♬ ₊˚.♪⋆☾⋆⁺₊✧",          nm:"Music"    },
                    { key:"✪ ✪ ✪ ✪ ✪",              nm:"Stars2"   },
                    { key:"▄︻デ══━一 ▄︻デ══━一",      nm:"Guns"     },
                    { key:"✦ ✧ ✦ ✧ ✦ ✧ ✦",          nm:"Diamond"  },
                    { key:"≋≋≋≋≋≋≋≋≋",              nm:"Ripple"   },
                    { key:"◈ ◈ ◈ ◈ ◈ ◈",            nm:"Compass"  },
                    { key:"⬡ ⬡ ⬡ ⬡ ⬡ ⬡",            nm:"Hex"      },
                    { key:"✶ ✶ ✶ ✶ ✶ ✶",            nm:"Burst"    },
                    { key:"❖ ❖ ❖ ❖ ❖ ❖",            nm:"Ornament" },
                    { key:"⁕ ⁕ ⁕ ⁕ ⁕ ⁕ ⁕",          nm:"Flower"   },
                    { key:"╔══════╗",                nm:"Frame"    },
                    { key:"◄◄◄◄◄◄◄◄◄",              nm:"Arrows"   },
                    { key:"░▒▓▓▒░",                  nm:"Fade"     },
                    { key:"",                         nm:"None"     }
                  ]
                  delegate: Item {
                    property bool sel: editTab.editingSlot > 0 ? ((api.memory.get("profile.slot." + editTab.editingSlot + ".borderBottom") || "") === modelData.key) : ((api.memory.get("profile.borderBottom") || "") === modelData.key)
                    width: (parent.width - vpx(4)*5) / 6; height: vpx(52)
                    Rectangle {
                      id: bdrBotBox
                      anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                      width: vpx(58); height: vpx(30); radius: vpx(4)
                      color: sel ? root.accentRgba(0.35) : "#14FFFFFF"
                      border.color: sel ? root.accentHex : "#28FFFFFF"
                      border.width: sel ? vpx(2) : vpx(1)
                      StyledText {
                        anchors.centerIn: parent
                        width: parent.width - vpx(6)
                        text: modelData.key !== "" ? modelData.key : "— None —"
                        font.pixelSize: vpx(11); color: sel ? root.accentHex : "#FFFFFF"
                        elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                      }
                    }
                    Text {
                      anchors.top: bdrBotBox.bottom; anchors.topMargin: vpx(2)
                      anchors.horizontalCenter: parent.horizontalCenter
                      width: parent.width
                      text: modelData.nm
                      font.pixelSize: vpx(8); color: sel ? root.accentHex : "#AAAAAA"
                      horizontalAlignment: Text.AlignHCenter
                    }
                    MouseArea {
                      anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { var k = editTab.editingSlot > 0 ? "profile.slot." + editTab.editingSlot + ".borderBottom" : "profile.borderBottom"; api.memory.set(k, modelData.key) }
                    }
                  }
                }
              }

              Item { height: vpx(8); width: parent.width }

              // ── Latest Games strip ─────────────────────────────────
              Item {
                width: parent.width; height: vpx(28)
                Row {
                  spacing: vpx(6); anchors.left: parent.left
                  anchors.right: lgToggleRow.left; anchors.rightMargin: vpx(8)
                  anchors.verticalCenter: parent.verticalCenter; clip: true
                  Rectangle { width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex; anchors.verticalCenter: parent.verticalCenter }
                  StyledText { text: "Latest Games"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter }
                }
                Row {
                  id: lgToggleRow
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: vpx(4)
                  Repeater {
                    model: ["On", "Off"]
                    delegate: Rectangle {
                      property bool isOn: modelData === "On"
                      property string stored: editTab.editingSlot > 0 ? (api.memory.get("profile.slot." + editTab.editingSlot + ".showLatestGames") || "") : ""
                      property bool active: isOn ? (stored !== "false") : (stored === "false")
                      width: vpx(38); height: vpx(24); radius: vpx(4)
                      color: active ? root.accentRgba(0.40) : Qt.rgba(1,1,1,0.08)
                      border.color: active ? root.accentHex : Qt.rgba(1,1,1,0.22); border.width: vpx(1)
                      StyledText { anchors.centerIn: parent; text: modelData; font.pixelSize: vpx(11); font.bold: true; color: active ? "#FFFFFF" : "#AAAAAA" }
                      MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          if (editTab.editingSlot <= 0) return
                          api.memory.set("profile.slot." + editTab.editingSlot + ".showLatestGames", isOn ? "true" : "false")
                        }
                      }
                    }
                  }
                }
              }

              Item { height: vpx(20); width: parent.width }
            }
          }

          Image {
            source: "../../assets/images/system/up-default.png"
            width: vpx(22); height: vpx(18)
            anchors.top: parent.top; anchors.right: parent.right
            anchors.topMargin: vpx(2); anchors.rightMargin: vpx(2)
            fillMode: Image.PreserveAspectFit; asynchronous: true
            opacity: editFlick.atYBeginning ? 0 : 0.8
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }
          Image {
            source: "../../assets/images/system/down-default.png"
            width: vpx(22); height: vpx(18)
            anchors.bottom: saveBar.top; anchors.right: parent.right
            anchors.bottomMargin: vpx(2); anchors.rightMargin: vpx(2)
            fillMode: Image.PreserveAspectFit; asynchronous: true
            opacity: editFlick.atYEnd ? 0 : 0.8
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }

          // ── Save button — pinned to bottom ─────────────────────
          Rectangle {
            id: saveBar
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: parent.bottom; anchors.rightMargin: vpx(26)
            height: vpx(40)
            color: root.themeFill
            Rectangle {
              anchors.top: parent.top; width: parent.width; height: vpx(1)
              color: root.accentRgba(0.3)
            }
            Rectangle {
              anchors.centerIn: parent
              width: parent.width; height: vpx(34); radius: vpx(4)
              color: root.accentHex
              StyledText {
                anchors.centerIn: parent; text: "💾  Save Profile"; font.pixelSize: vpx(13); font.bold: true; color: "#FFFFFF"
              }
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var name = nameInput.text.trim() !== "" ? nameInput.text.trim() : root.profileName
                  var gs   = parseInt(gsInput.text) || root.profileGamerscore
                  var targetSlot = -1
                  if (editTab.editingSlot > 0) {
                    targetSlot = editTab.editingSlot
                  } else if (root.infoTabRef && root.infoTabRef.selectedSlot > 0) {
                    targetSlot = root.infoTabRef.selectedSlot
                  } else {
                    var origName = root.profileName
                    for (var i = 1; i <= 9; i++) {
                      var sn = api.memory.get("profile.slot." + i + ".name")
                      if (sn && sn !== "" && sn === origName) { targetSlot = i; break }
                    }
                  }
                  if (targetSlot === -1) targetSlot = root.nextFreeSlot()
                  root.profileName       = name
                  root.profileGamerscore = gs
                  root.profileStatus     = statusInput.text
                  root.profileSubStatus  = subInput.text
                  root.profileMotto      = mottoInput.text
                  root.profileBio        = bioInput.text
                  root.profileRegion     = regionInput.text
                  api.memory.set("profile.name",       name)
                  api.memory.set("profile.gamerscore",  gs.toString())
                  api.memory.set("profile.status",      statusInput.text)
                  api.memory.set("profile.substatus",   subInput.text)
                  api.memory.set("profile.motto",       mottoInput.text)
                  api.memory.set("profile.bio",         bioInput.text)
                  api.memory.set("profile.region",      regionInput.text)
                  if (targetSlot !== -1) {
                    root.saveSlot(targetSlot, name, root.profileAvatar, root.profileGamerpic,
                                  gs, statusInput.text, subInput.text, mottoInput.text,
                                  bioInput.text, regionInput.text, root.profileColor, root.profileShape)
                    editTab.editingSlot = targetSlot
                  }
                  root.rebuildPanels()
                  var navSlot = targetSlot
                  Qt.callLater(function() {
                    for (var ni = 1; ni < panelsModel.count; ni++) {
                      if (panelsModel.get(ni).slotNum === navSlot) {
                        panelsList.currentIndex = ni; break
                      }
                    }
                  })
                }
              }
            }
          }
        }
        Item {
          visible: root.profileTabIndex === 3
          anchors.fill: parent
          id: createTab
          property string newColor:  "#0099CC"
          property string newShape:  "circle"
          property string newAvatar: "Avatar1.png"
          property string newGamerpic: ""
          property bool colorListExpanded: false
          property bool avatarListExpanded: false
          property bool shapeListExpanded: false
          property bool borderTopExpanded: false
          property bool borderBottomExpanded: false
          property bool gamerpicListExpanded: false
          property bool gamerTagExpanded: false

          Flickable {
            anchors.fill: parent; anchors.rightMargin: vpx(26)
            id: createFlick
            contentHeight: createCol.implicitHeight + vpx(40)
            clip: true; boundsBehavior: Flickable.StopAtBounds

            Column {
              id: createCol; width: parent.width; spacing: vpx(10)

              // ── Gamer Pic ─────────────────────────────────────
              Item {
                width: parent.width; height: vpx(28)
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left; anchors.right: parent.right
                  anchors.rightMargin: createChooseGpRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Gamer Pic"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: createChooseGpRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: createChooseGpRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Gamer Pic"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: createTab.gamerpicListExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: createTab.gamerpicListExpanded = !createTab.gamerpicListExpanded }
                }
              }
              Column {
                visible: createTab.gamerpicListExpanded
                width: parent.width; spacing: vpx(8)
                Row {
                width: parent.width; spacing: vpx(10)
                Rectangle {
                  width: vpx(64); height: vpx(64); radius: vpx(4)
                  color: "#18FFFFFF"; border.color: createTab.newColor; border.width: vpx(2)
                  Image {
                    anchors.fill: parent; anchors.margins: vpx(3)
                    source: createTab.newGamerpic !== "" ? createTab.newGamerpic : "../../assets/images/gamerpic/MissingGamerPic.png"
                    fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                  }
                }
                Column {
                  width: parent.width - vpx(74); spacing: vpx(6); anchors.verticalCenter: parent.verticalCenter
                  // Gamer Pic Path field — top row
                  Rectangle {
                    width: parent.width; height: vpx(24)
                    color: "#18FFFFFF"; radius: vpx(4)
                    border.color: "#30FFFFFF"; border.width: vpx(1)
                    Row {
                      anchors.fill: parent; anchors.margins: vpx(4); spacing: vpx(4)
                      Text { text: "🔍"; font.pixelSize: vpx(11); anchors.verticalCenter: parent.verticalCenter }
                      TextInput {
                        width: parent.width - vpx(20); height: parent.height
                        verticalAlignment: TextInput.AlignVCenter
                        text: ""; font.pixelSize: vpx(11); color: "#CCCCCC"
                        selectionColor: createTab.newColor; selectByMouse: true
                        onEditingFinished: { createTab.newGamerpic = text }
                        StyledText { visible: parent.text === ""; text: "Browse for Gamer Pic…"; font.pixelSize: vpx(11); color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter;
 }
                      }
                    }
                  }
                  // Category buttons — second row
                  Flow {
                    spacing: vpx(4); id: cGamerpicCatRow; property int catIndex: 0
                    width: parent.width
                    Repeater {
                      model: ["Default", "Cool Kids"]
                      delegate: Rectangle {
                        property bool active: cGamerpicCatRow.catIndex === index
                        width: cCatLabel.implicitWidth + vpx(16)
                        height: vpx(24); radius: vpx(4)
                        color: active ? createTab.newColor : "#14FFFFFF"
                        border.color: active ? createTab.newColor : "#25FFFFFF"; border.width: vpx(1)
                        StyledText { id: cCatLabel; anchors.centerIn: parent; text: modelData; font.pixelSize: vpx(14); font.bold: active; color: active ? "#FFFFFF" : root.accentHex;
 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cGamerpicCatRow.catIndex = index }
                      }
                    }
                  }
                  Flow {
                    visible: cGamerpicCatRow.catIndex === 0; width: parent.width; spacing: vpx(4)
                    Repeater {
                      model: ["MissingGamerPic.png", "Kitkat.png", "Avatar91.png", "GamerPic.png"]
                      delegate: Rectangle {
                        property string fullPath: "../../assets/images/gamerpic/" + modelData
                        property bool selected: createTab.newGamerpic === fullPath
                        width: vpx(36); height: vpx(36); radius: vpx(3)
                        color: selected ? Qt.rgba(parseInt(createTab.newColor.slice(1,3),16)/255,parseInt(createTab.newColor.slice(3,5),16)/255,parseInt(createTab.newColor.slice(5,7),16)/255,0.4) : "#14FFFFFF"
                        border.color: selected ? createTab.newColor : "#25FFFFFF"; border.width: vpx(1)
                        Image { anchors.fill: parent; anchors.margins: vpx(2); source: fullPath; fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: createTab.newGamerpic = fullPath }
                      }
                    }
                  }
                  Flow {
                    visible: cGamerpicCatRow.catIndex === 1; width: parent.width; spacing: vpx(4)
                    Repeater {
                      model: [
                        { file: "BubbleKid360.png",    nm: "360" },
                        { file: "BubbleKidBlue.png",   nm: "Blue" },
                        { file: "BubbleKidGreen.png",  nm: "Green" },
                        { file: "BubbleKidRed.png",    nm: "Red" },
                        { file: "BubbleKidSnes.png",   nm: "SNES" },
                        { file: "BubbleKidSwitch.png", nm: "Switch" },
                        { file: "BubbleKidXbOne.png",  nm: "XbOne" }
                      ]
                      delegate: Item {
                        property string fullPath: "../../assets/images/gamerpic/CoolKids/" + modelData.file
                        property bool selected: createTab.newGamerpic === fullPath
                        width: vpx(42); height: vpx(52)
                        Rectangle {
                          id: cCkBox
                          width: vpx(40); height: vpx(40); radius: vpx(3)
                          anchors.horizontalCenter: parent.horizontalCenter
                          color: selected ? Qt.rgba(parseInt(createTab.newColor.slice(1,3),16)/255,parseInt(createTab.newColor.slice(3,5),16)/255,parseInt(createTab.newColor.slice(5,7),16)/255,0.4) : "#14FFFFFF"
                          border.color: selected ? createTab.newColor : "#25FFFFFF"; border.width: vpx(1)
                          Image { anchors.fill: parent; anchors.margins: vpx(2); source: fullPath; fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true }
                        }
                        Text {
                          text: modelData.nm
                          anchors.top: cCkBox.bottom; anchors.topMargin: vpx(1)
                          anchors.horizontalCenter: parent.horizontalCenter
                          font.pixelSize: vpx(7); color: selected ? createTab.newColor : "#666666"
                          horizontalAlignment: Text.AlignHCenter
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: createTab.newGamerpic = fullPath }
                      }
                    }
                  }
                }
              }
              } // end gamerpic collapsible Column

              // ── Gamer Tag ─────────────────────────────────────
              Item {
                width: parent.width; height: vpx(28)
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left; anchors.right: parent.right
                  anchors.rightMargin: createChooseGamerTagRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Gamer Tag"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: createChooseGamerTagRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: createChooseGamerTagRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Gamer Tag"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: createTab.gamerTagExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: createTab.gamerTagExpanded = !createTab.gamerTagExpanded }
                }
              }
              Column {
                visible: createTab.gamerTagExpanded
                width: parent.width; spacing: vpx(10)

                // ── Gamer Tag ──
                Rectangle {
                  width: parent.width; height: vpx(36); color: "#CC000000"; radius: vpx(5)
                  border.color: cNameInput.activeFocus ? createTab.newColor : "#30FFFFFF"; border.width: vpx(1)
                  TextInput { id: cNameInput; anchors.fill: parent; anchors.margins: vpx(9); font.pixelSize: vpx(14); color: "#FFFFFF"; selectionColor: createTab.newColor; selectByMouse: true }
                }

                // ── Gamerscore ──
                StyledText { text: "Gamerscore"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Rectangle {
                  width: parent.width; height: vpx(36); color: "#CC000000"; radius: vpx(5)
                  border.color: cGsInput.activeFocus ? createTab.newColor : "#30FFFFFF"; border.width: vpx(1)
                  TextInput { id: cGsInput; anchors.fill: parent; anchors.margins: vpx(9); text: "0"; font.pixelSize: vpx(14); color: "#FFFFFF"; selectionColor: createTab.newColor; selectByMouse: true; inputMethodHints: Qt.ImhDigitsOnly }
                }

                // ── Status ──
                StyledText { text: "Status"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Rectangle {
                  width: parent.width; height: vpx(36); color: "#CC000000"; radius: vpx(5)
                  border.color: cStatusInput.activeFocus ? createTab.newColor : "#30FFFFFF"; border.width: vpx(1)
                  TextInput { id: cStatusInput; anchors.fill: parent; anchors.margins: vpx(9); text: "Signed In"; font.pixelSize: vpx(14); color: "#FFFFFF"; selectionColor: createTab.newColor; selectByMouse: true }
                }

                // ── Membership ──
                StyledText { text: "Membership / Sub-status"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Flow {
                  width: parent.width; spacing: vpx(5)
                  Repeater {
                    model: ["Xbox LIVE Gold", "Game Pass Ultimate", "Xbox LIVE Silver", "EA Play", "Game Pass PC", "Steam", "Online", "None"]
                    delegate: Rectangle {
                      property bool active: cSubInput.text === modelData
                      height: vpx(22); radius: vpx(11)
                      width: cSubPillLabel.implicitWidth + vpx(16)
                      color: active ? createTab.newColor : "#18FFFFFF"
                      border.color: active ? createTab.newColor : "#30FFFFFF"; border.width: vpx(1)
                      StyledText {
                        id: cSubPillLabel
                        anchors.centerIn: parent
                        text: modelData; font.pixelSize: vpx(10)
                        color: active ? "#FFFFFF" : "#AAAAAA";

                      }
                      MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { cSubInput.text = modelData }
                      }
                    }
                  }
                }
                Rectangle {
                  width: parent.width; height: vpx(36); color: "#CC000000"; radius: vpx(5)
                  border.color: cSubInput.activeFocus ? createTab.newColor : "#30FFFFFF"; border.width: vpx(1)
                  TextInput { id: cSubInput; anchors.fill: parent; anchors.margins: vpx(9); text: "Xbox LIVE Gold"; font.pixelSize: vpx(14); color: "#FFFFFF"; selectionColor: createTab.newColor; selectByMouse: true }
                }

                // ── Motto ──
                StyledText { text: "Motto"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Rectangle {
                  width: parent.width; height: vpx(36); color: "#CC000000"; radius: vpx(5)
                  border.color: cMottoInput.activeFocus ? createTab.newColor : "#30FFFFFF"; border.width: vpx(1)
                  TextInput { id: cMottoInput; anchors.fill: parent; anchors.margins: vpx(9); font.pixelSize: vpx(14); color: "#FFFFFF"; selectionColor: createTab.newColor; selectByMouse: true }
                }

                // ── Bio ──
                StyledText { text: "Bio"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Rectangle {
                  width: parent.width; height: vpx(58); color: "#CC000000"; radius: vpx(5)
                  border.color: cBioInput.activeFocus ? createTab.newColor : "#30FFFFFF"; border.width: vpx(1)
                  TextEdit { id: cBioInput; anchors.fill: parent; anchors.margins: vpx(9); font.pixelSize: vpx(13); color: "#FFFFFF"; selectionColor: createTab.newColor; selectByMouse: true; wrapMode: Text.WordWrap }
                }

                // ── Region ──
                StyledText { text: "Region"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Rectangle {
                  width: parent.width; height: vpx(36); color: "#CC000000"; radius: vpx(5)
                  border.color: cRegionInput.activeFocus ? createTab.newColor : "#30FFFFFF"; border.width: vpx(1)
                  TextInput { id: cRegionInput; anchors.fill: parent; anchors.margins: vpx(9); font.pixelSize: vpx(14); color: "#FFFFFF"; selectionColor: createTab.newColor; selectByMouse: true }
                }
              } // end gamerTag collapsible Column

              // ── Accent Color ─────────────────────────────────
              Item {
                width: parent.width; height: vpx(28)

                // Left: accent bar + "Colors" title
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.rightMargin: createChooseColorRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Colors"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                // Right: "Choose Color ▾" button
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: createChooseColorRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: createChooseColorRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Color"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: createTab.colorListExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: createTab.colorListExpanded = !createTab.colorListExpanded }
                }
              }
              Column {
                width: parent.width; spacing: vpx(6)
                visible: createTab.colorListExpanded

                // Accent swatches
                StyledText { text: "Accent Color"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Flow {
                  width: parent.width; spacing: vpx(6)
                  Repeater {
                    model: ["#0099CC","#5d9809","#FF5733","#8A2BE2","#FFAA00","#00BFA5","#E91E8C","#FF4500","#1E90FF","#FFD700","#EEEEEE","#DC143C"]
                    delegate: Rectangle {
                      width: vpx(26); height: vpx(26); radius: vpx(13); color: modelData
                      border.color: createTab.newColor === modelData ? root.accentRgba(0.85) : "transparent"; border.width: vpx(2)
                      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: createTab.newColor = modelData }
                    }
                  }
                }

                // Theme swatches
                StyledText { text: "Theme Color"; font.pixelSize: vpx(14); font.bold: true; color: "#FFFFFF";
 }
                Flow {
                  width: parent.width; spacing: vpx(6)
                  Repeater {
                    model: ["#1E4D8C","#1A6633","#7A1515","#3D1575","#7A5200","#007A66","#454545","#7A1545","#006680","#6B4D00","#1A3D80","#6B0030"]
                    delegate: Rectangle {
                      width: vpx(26); height: vpx(26); radius: vpx(13); color: modelData
                      border.color: (api.memory.get("profile.themeColor") || "") === modelData ? root.accentRgba(0.85) : "transparent"
                      border.width: vpx(2)
                      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: api.memory.set("profile.themeColor", modelData)
                      }
                    }
                  }
                }
              }


              // ── Choose Avatar (one row, small) ─────────────────
              Item {
                width: parent.width; height: vpx(28)
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left; anchors.right: parent.right
                  anchors.rightMargin: createChooseAvatarRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Avatar"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: createChooseAvatarRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: createChooseAvatarRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Avatar"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: createTab.avatarListExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: createTab.avatarListExpanded = !createTab.avatarListExpanded }
                }
              }
              Flow {
                visible: createTab.avatarListExpanded
                spacing: vpx(5); width: parent.width
                Repeater {
                  model: root.avatarCount
                  delegate: Rectangle {
                    property string av: "Avatar" + (index+1) + ".png"
                    property bool sel: createTab.newAvatar === av
                    width: vpx(60); height: vpx(60); radius: vpx(4)
                    color: sel ? Qt.rgba(parseInt(createTab.newColor.slice(1,3),16)/255,parseInt(createTab.newColor.slice(3,5),16)/255,parseInt(createTab.newColor.slice(5,7),16)/255,0.35) : "#22FFFFFF"
                    border.color: sel ? createTab.newColor : "#30FFFFFF"; border.width: sel ? vpx(3) : vpx(1)
                    Image { anchors.fill: parent; anchors.margins: vpx(3); source: root.avatarBase + "Avatar" + (index+1) + ".png"; fillMode: Image.PreserveAspectFit; smooth: true }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: createTab.newAvatar = av }
                  }
                }

                Rectangle {
                  visible: root.hasCustomAvatar
                  property bool selected: createTab.newAvatar === root.customAvatarName
                  width: vpx(60); height: vpx(60); radius: vpx(4)
                  color:        selected ? Qt.rgba(parseInt(createTab.newColor.slice(1,3),16)/255,parseInt(createTab.newColor.slice(3,5),16)/255,parseInt(createTab.newColor.slice(5,7),16)/255,0.35) : "#22FFFFFF"
                  border.color: selected ? createTab.newColor : "#30FFFFFF"; border.width: selected ? vpx(3) : vpx(1)
                  Image {
                    anchors.fill: parent; anchors.margins: vpx(3)
                    source: root.avatarBase + root.customAvatarName + "?v=" + root.customAvatarVersion
                    fillMode: Image.PreserveAspectFit; smooth: true
                  }
                  MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: createTab.newAvatar = root.customAvatarName
                  }
                }

                Rectangle {
                  width: vpx(60); height: vpx(60); radius: vpx(4)
                  color:        plusHoverCreate.containsMouse ? root.accentRgba(0.30) : "#22FFFFFF"
                  border.color: root.accentRgba(0.75); border.width: vpx(2)
                  Rectangle { width: vpx(24); height: vpx(3); radius: vpx(1.5); color: "#FFFFFF"; anchors.centerIn: parent }
                  Rectangle { width: vpx(3); height: vpx(24); radius: vpx(1.5); color: "#FFFFFF"; anchors.centerIn: parent }
                  MouseArea {
                    id: plusHoverCreate
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.openAvatarEditor()
                  }
                }

              StyledText {
                visible: root.avatarLoaderFailed
                text: "⚠ avatar editor missing — copy the avatar/ folder into the theme root"
                font.pixelSize: vpx(11); color: "#FF9977"
                width: parent.width; wrapMode: Text.WordWrap
              }
              }

              // ── Create button moved to bottom of tab ──────────

              // ── Profile Shape ────────────────────────────────
              Item {
                width: parent.width; height: vpx(28)
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left; anchors.right: parent.right
                  anchors.rightMargin: createChooseShapeRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Profile Shape"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: createChooseShapeRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: createChooseShapeRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Shape"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: createTab.shapeListExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: createTab.shapeListExpanded = !createTab.shapeListExpanded }
                }
              }
              Flow {
                visible: createTab.shapeListExpanded
                spacing: vpx(4); width: parent.width
                Repeater {
                  model: [
                    { key:"circle",     nm:"Circle"    },
                    { key:"square",     nm:"Square"    },
                    { key:"triangle",   nm:"Triangle"  },
                    { key:"diamond",    nm:"Diamond"   },
                    { key:"hexagon",    nm:"Hexagon"   },
                    { key:"octagon",    nm:"Octagon"   },
                    { key:"rectangle",  nm:"Rect"      },
                    { key:"star",       nm:"Star"      },
                    { key:"plus",       nm:"Plus"      },
                    { key:"cross_x",    nm:"X Cross"   },
                    { key:"heart",      nm:"Heart"     },
                    { key:"spade",      nm:"Spade"     },
                    { key:"club",       nm:"Club"      },
                    { key:"moon",       nm:"Moon"      },
                    { key:"waterdrop",  nm:"Drop"      },
                    { key:"spiral",     nm:"Spiral"    },
                    { key:"sparkle",    nm:"Sparkle"   },
                    { key:"smile",      nm:"Smile"     },
                    { key:"flower",     nm:"Flower"    },
                    { key:"daisy",      nm:"Daisy"     },
                    { key:"hexagram",   nm:"Hexagram"  },
                    { key:"quatrefoil", nm:"Quatrefoil"},
                    { key:"triquetra",  nm:"Triquetra" },
                    { key:"gear",       nm:"Gear"      },
                    { key:"windows",    nm:"Windows"   },
                    { key:"chevron",    nm:"Chevron"   },
                    { key:"splat",      nm:"Splat"     },
                    { key:"music",      nm:"Note"      },
                    { key:"music2",     nm:"Beamed"    },
                    { key:"cat",        nm:"Cat"       },
                    { key:"bunny",      nm:"Bunny"     },
                    { key:"android",    nm:"Android"   }
                  ]
                  delegate: Item {
                    property bool sel: createTab.newShape === modelData.key
                    function ncRgba(a) { var h = createTab.newColor.replace("#",""); return Qt.rgba(parseInt(h.slice(0,2),16)/255, parseInt(h.slice(2,4),16)/255, parseInt(h.slice(4,6),16)/255, a) }
                    width: vpx(43); height: vpx(51)
                    Rectangle {
                      id: cShpBox
                      width: vpx(39); height: vpx(39); radius: vpx(4)
                      anchors.horizontalCenter: parent.horizontalCenter
                      color: sel ? parent.ncRgba(0.35) : "#14FFFFFF"
                      border.color: sel ? createTab.newColor : "#28FFFFFF"
                      border.width: sel ? vpx(2) : vpx(1)
                      Canvas {
                        anchors.fill: parent; anchors.margins: vpx(4)
                        property string sk: modelData.key
                        property string col: createTab.newColor
                        property string shp: createTab.newShape
                        onColChanged: requestPaint()
                        onShpChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        Component.onCompleted: Qt.callLater(requestPaint)
                        onPaint: {
                          var ctx=getContext("2d"); if(!ctx||width<=0||height<=0){Qt.callLater(requestPaint);return} ctx.clearRect(0,0,width,height)
                          var h=col.replace("#",""); var r=parseInt(h.slice(0,2),16),g=parseInt(h.slice(2,4),16),b=parseInt(h.slice(4,6),16)
                          var fa="rgba("+r+","+g+","+b+",0.32)",sa="rgba("+r+","+g+","+b+",0.9)"
                          ctx.strokeStyle=sa; ctx.fillStyle=fa; ctx.lineWidth=1.5
                          var cx=width/2,cy=height/2,s=Math.min(width,height)/2-1
                          var i,a,p,pa,t,teeth,ir,or2,tr,gap,pw,a1,a2
                          if(sk==="circle"){ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);ctx.fill();ctx.stroke()}
                          else if(sk==="square"){ctx.beginPath();ctx.rect(cx-s,cy-s,s*2,s*2);ctx.fill();ctx.stroke()}
                          else if(sk==="triangle"){ctx.beginPath();ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.87,cy+s*.5);ctx.lineTo(cx-s*.87,cy+s*.5);ctx.closePath();ctx.fill();ctx.stroke()}
                          else if(sk==="diamond"){ctx.beginPath();ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.65,cy);ctx.lineTo(cx,cy+s);ctx.lineTo(cx-s*.65,cy);ctx.closePath();ctx.fill();ctx.stroke()}
                          else if(sk==="hexagon"){ctx.beginPath();for(i=0;i<6;i++){a=Math.PI/180*(60*i-30);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}ctx.closePath();ctx.fill();ctx.stroke()}
                          else if(sk==="octagon"){ctx.beginPath();for(i=0;i<8;i++){a=Math.PI/180*(45*i+22.5);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}ctx.closePath();ctx.fill();ctx.stroke()}
                          else if(sk==="rectangle"){ctx.beginPath();ctx.rect(cx-s,cy-s*.6,s*2,s*1.2);ctx.fill();ctx.stroke()}
                          else if(sk==="star"){ctx.beginPath();for(i=0;i<10;i++){a=Math.PI/180*(36*i-90);var sr=i%2===0?s:s*.42;if(i===0)ctx.moveTo(cx+sr*Math.cos(a),cy+sr*Math.sin(a));else ctx.lineTo(cx+sr*Math.cos(a),cy+sr*Math.sin(a))}ctx.closePath();ctx.fill();ctx.stroke()}
                          else if(sk==="plus"){var arm=s*.36;ctx.beginPath();ctx.moveTo(cx-arm,cy-s);ctx.lineTo(cx+arm,cy-s);ctx.lineTo(cx+arm,cy-arm);ctx.lineTo(cx+s,cy-arm);ctx.lineTo(cx+s,cy+arm);ctx.lineTo(cx+arm,cy+arm);ctx.lineTo(cx+arm,cy+s);ctx.lineTo(cx-arm,cy+s);ctx.lineTo(cx-arm,cy+arm);ctx.lineTo(cx-s,cy+arm);ctx.lineTo(cx-s,cy-arm);ctx.lineTo(cx-arm,cy-arm);ctx.closePath();ctx.fill();ctx.stroke()}
                          else if(sk==="cross_x"){ctx.lineWidth=s*.36;ctx.lineCap="round";ctx.strokeStyle=sa;ctx.beginPath();ctx.moveTo(cx-s*.7,cy-s*.7);ctx.lineTo(cx+s*.7,cy+s*.7);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.7,cy-s*.7);ctx.lineTo(cx-s*.7,cy+s*.7);ctx.stroke()}
                          else if(sk==="heart"){ctx.beginPath();ctx.moveTo(cx,cy+s*.80);ctx.bezierCurveTo(cx-s*.10,cy+s*.60,cx-s*.90,cy+s*.30,cx-s*.90,cy-s*.10);ctx.bezierCurveTo(cx-s*.90,cy-s*.55,cx-s*.50,cy-s*.80,cx,cy-s*.35);ctx.bezierCurveTo(cx+s*.50,cy-s*.80,cx+s*.90,cy-s*.55,cx+s*.90,cy-s*.10);ctx.bezierCurveTo(cx+s*.90,cy+s*.30,cx+s*.10,cy+s*.60,cx,cy+s*.80);ctx.closePath();ctx.fill();ctx.stroke()}
                          else if(sk==="spade"){ctx.beginPath();ctx.moveTo(cx,cy-s*.78);ctx.bezierCurveTo(cx+s*.10,cy-s*.58,cx+s*.90,cy-s*.28,cx+s*.90,cy+s*.12);ctx.bezierCurveTo(cx+s*.90,cy+s*.54,cx+s*.50,cy+s*.76,cx,cy+s*.32);ctx.bezierCurveTo(cx-s*.50,cy+s*.76,cx-s*.90,cy+s*.54,cx-s*.90,cy+s*.12);ctx.bezierCurveTo(cx-s*.90,cy-s*.28,cx-s*.10,cy-s*.58,cx,cy-s*.78);ctx.closePath();ctx.fill();ctx.stroke();ctx.lineWidth=s*.16;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx,cy+s*.32);ctx.lineTo(cx,cy+s*.78);ctx.stroke();ctx.lineWidth=s*.18;ctx.beginPath();ctx.moveTo(cx-s*.38,cy+s*.78);ctx.bezierCurveTo(cx-s*.12,cy+s*.58,cx+s*.12,cy+s*.58,cx+s*.38,cy+s*.78);ctx.stroke()}
                          else if(sk==="club"){var cP=[{x:cx,y:cy-s*.30},{x:cx-s*.34,y:cy+s*.12},{x:cx+s*.34,y:cy+s*.12}];for(p=0;p<3;p++){ctx.beginPath();ctx.arc(cP[p].x,cP[p].y,s*.34,0,Math.PI*2);ctx.fill();ctx.stroke()}ctx.lineWidth=s*.16;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx,cy+s*.30);ctx.lineTo(cx,cy+s*.78);ctx.stroke();ctx.lineWidth=s*.18;ctx.beginPath();ctx.moveTo(cx-s*.38,cy+s*.78);ctx.bezierCurveTo(cx-s*.12,cy+s*.58,cx+s*.12,cy+s*.58,cx+s*.38,cy+s*.78);ctx.stroke()}
                          else if(sk==="moon"){ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.globalCompositeOperation="destination-out";ctx.beginPath();ctx.arc(cx+s*.40,cy-s*.20,s*.74,0,Math.PI*2);ctx.fillStyle="rgba(0,0,0,1)";ctx.fill();ctx.globalCompositeOperation="source-over"}
                          else if(sk==="waterdrop"){ctx.beginPath();ctx.moveTo(cx,cy-s*.92);ctx.bezierCurveTo(cx+s*.50,cy-s*.30,cx+s*.82,cy+s*.22,cx,cy+s*.92);ctx.bezierCurveTo(cx-s*.82,cy+s*.22,cx-s*.50,cy-s*.30,cx,cy-s*.92);ctx.closePath();ctx.fill();ctx.stroke()}
                          else if(sk==="spiral"){ctx.strokeStyle=sa;ctx.lineWidth=1.5;ctx.lineCap="round";ctx.beginPath();var turns=3,steps=120;for(i=0;i<=steps;i++){var theta=turns*Math.PI*2*(i/steps);var rad2=(s*.92)*(i/steps);if(i===0)ctx.moveTo(cx+rad2*Math.cos(theta-Math.PI/2),cy+rad2*Math.sin(theta-Math.PI/2));else ctx.lineTo(cx+rad2*Math.cos(theta-Math.PI/2),cy+rad2*Math.sin(theta-Math.PI/2))}ctx.stroke()}
                          else if(sk==="sparkle"){ctx.beginPath();for(i=0;i<8;i++){a=Math.PI/4*i-Math.PI/2;var rr=i%2===0?s:s*.12;if(i===0)ctx.moveTo(cx+rr*Math.cos(a),cy+rr*Math.sin(a));else ctx.lineTo(cx+rr*Math.cos(a),cy+rr*Math.sin(a))}ctx.closePath();ctx.fill();ctx.stroke()}
                          else if(sk==="smile"){ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.fillStyle=sa;ctx.beginPath();ctx.arc(cx-s*.30,cy-s*.20,s*.11,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx+s*.30,cy-s*.20,s*.11,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.strokeStyle=sa;ctx.lineWidth=1.6;ctx.lineCap="round";ctx.arc(cx,cy+s*.10,s*.38,Math.PI*0.12,Math.PI*0.88);ctx.stroke()}
                          else if(sk==="flower"){for(p=0;p<6;p++){pa=Math.PI/180*(60*p);ctx.beginPath();ctx.arc(cx+s*.50*Math.cos(pa),cy+s*.50*Math.sin(pa),s*.40,0,Math.PI*2);ctx.fill();ctx.stroke()}ctx.beginPath();ctx.arc(cx,cy,s*.26,0,Math.PI*2);ctx.fillStyle="rgba("+r+","+g+","+b+",0.75)";ctx.fill()}
                          else if(sk==="daisy"){for(p=0;p<10;p++){pa=Math.PI*2/10*p;ctx.save();ctx.translate(cx+s*.52*Math.cos(pa),cy+s*.52*Math.sin(pa));ctx.rotate(pa);ctx.save();ctx.scale(s*.22,s*.42);ctx.beginPath();ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.stroke();ctx.restore()}ctx.beginPath();ctx.arc(cx,cy,s*.26,0,Math.PI*2);ctx.fillStyle="rgba("+r+","+g+","+b+",0.85)";ctx.fill()}
                          else if(sk==="hexagram"){ctx.beginPath();ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.87,cy+s*.5);ctx.lineTo(cx-s*.87,cy+s*.5);ctx.closePath();ctx.fill();ctx.stroke();ctx.beginPath();ctx.moveTo(cx,cy+s);ctx.lineTo(cx+s*.87,cy-s*.5);ctx.lineTo(cx-s*.87,cy-s*.5);ctx.closePath();ctx.fill();ctx.stroke()}
                          else if(sk==="quatrefoil"){var qr=s*.50,qd=s*.36;var qp=[{x:cx,y:cy-qd},{x:cx+qd,y:cy},{x:cx,y:cy+qd},{x:cx-qd,y:cy}];for(p=0;p<4;p++){ctx.beginPath();ctx.arc(qp[p].x,qp[p].y,qr,0,Math.PI*2);ctx.fill();ctx.stroke()}ctx.beginPath();ctx.arc(cx,cy,s*.20,0,Math.PI*2);ctx.fillStyle="rgba("+r+","+g+","+b+",0.75)";ctx.fill()}
                          else if(sk==="triquetra"){ctx.strokeStyle=sa;ctx.lineWidth=s*.16;ctx.lineCap="round";ctx.lineJoin="round";var tr2=s*.66;for(p=0;p<3;p++){a=Math.PI*2/3*p-Math.PI/2;var tx=cx+tr2*Math.cos(a),ty=cy+tr2*Math.sin(a);ctx.save();ctx.translate(tx,ty);ctx.rotate(a+Math.PI/2);ctx.beginPath();ctx.arc(0,0,tr2,Math.PI*0.62,Math.PI*1.38);ctx.stroke();ctx.restore()}}
                          else if(sk==="gear"){teeth=10;ir=s*.44;or2=s*.70;tr=s*.90;ctx.beginPath();for(t=0;t<teeth;t++){a1=Math.PI*2/teeth*t-Math.PI/teeth*.5;a2=Math.PI*2/teeth*t+Math.PI/teeth*.5;ctx.lineTo(cx+or2*Math.cos(a1),cy+or2*Math.sin(a1));ctx.lineTo(cx+tr*Math.cos(a1+Math.PI/teeth*.25),cy+tr*Math.sin(a1+Math.PI/teeth*.25));ctx.lineTo(cx+tr*Math.cos(a2-Math.PI/teeth*.25),cy+tr*Math.sin(a2-Math.PI/teeth*.25));ctx.lineTo(cx+or2*Math.cos(a2),cy+or2*Math.sin(a2))}ctx.closePath();ctx.fill();ctx.stroke();ctx.globalCompositeOperation="destination-out";ctx.beginPath();ctx.arc(cx,cy,ir,0,Math.PI*2);ctx.fillStyle="rgba(0,0,0,1)";ctx.fill();ctx.globalCompositeOperation="source-over"}
                          else if(sk==="windows"){gap=s*.10;pw=(s-gap)*.86;ctx.fillStyle="rgba("+r+","+g+","+b+",0.55)";ctx.strokeStyle=sa;ctx.beginPath();ctx.rect(cx-pw-gap/2,cy-pw-gap/2,pw,pw);ctx.fill();ctx.stroke();ctx.beginPath();ctx.rect(cx+gap/2,cy-pw-gap/2,pw,pw);ctx.fill();ctx.stroke();ctx.beginPath();ctx.rect(cx-pw-gap/2,cy+gap/2,pw,pw);ctx.fill();ctx.stroke();ctx.beginPath();ctx.rect(cx+gap/2,cy+gap/2,pw,pw);ctx.fill();ctx.stroke()}
                          else if(sk==="chevron"){ctx.lineWidth=s*.19;ctx.lineCap="square";ctx.lineJoin="miter";ctx.strokeStyle=sa;var offs=[-s*.34,0,s*.34];for(var c2=0;c2<3;c2++){ctx.beginPath();ctx.moveTo(cx-s*.80,cy+s*.40+offs[c2]);ctx.lineTo(cx,cy-s*.08+offs[c2]);ctx.lineTo(cx+s*.80,cy+s*.40+offs[c2]);ctx.stroke()}}
                          else if(sk==="splat"){ctx.beginPath();for(i=0;i<14;i++){var ang=Math.PI*2/14*i;var srad=i%2===0?s*(0.70+Math.sin(i*1.7)*.18):s*(0.38+Math.cos(i*2.3)*.12);if(i===0)ctx.moveTo(cx+srad*Math.cos(ang),cy+srad*Math.sin(ang));else ctx.lineTo(cx+srad*Math.cos(ang),cy+srad*Math.sin(ang))}ctx.closePath();ctx.fill();ctx.stroke()}
                          else if(sk==="music"){ctx.strokeStyle=sa;ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)";ctx.save();ctx.translate(cx-s*.10,cy+s*.36);ctx.rotate(-0.40);ctx.save();ctx.scale(s*.30,s*.20);ctx.beginPath();ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.restore();ctx.lineWidth=s*.11;ctx.lineCap="round";ctx.strokeStyle=sa;ctx.beginPath();ctx.moveTo(cx+s*.18,cy+s*.26);ctx.lineTo(cx+s*.18,cy-s*.68);ctx.stroke();ctx.lineWidth=s*.09;ctx.beginPath();ctx.moveTo(cx+s*.18,cy-s*.68);ctx.bezierCurveTo(cx+s*.60,cy-s*.52,cx+s*.60,cy-s*.28,cx+s*.18,cy-s*.16);ctx.stroke()}
                          else if(sk==="music2"){ctx.strokeStyle=sa;ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)";var n1x=cx-s*.28,n2x=cx+s*.26,stemTop=cy-s*.70,stemBot=cy+s*.30;ctx.save();ctx.translate(n1x-s*.08,stemBot);ctx.rotate(-0.38);ctx.save();ctx.scale(s*.26,s*.18);ctx.beginPath();ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.restore();ctx.save();ctx.translate(n2x-s*.08,stemBot);ctx.rotate(-0.38);ctx.save();ctx.scale(s*.26,s*.18);ctx.beginPath();ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.restore();ctx.lineWidth=s*.10;ctx.lineCap="round";ctx.strokeStyle=sa;ctx.beginPath();ctx.moveTo(n1x,stemBot);ctx.lineTo(n1x,stemTop);ctx.stroke();ctx.beginPath();ctx.moveTo(n2x,stemBot);ctx.lineTo(n2x,stemTop);ctx.stroke();ctx.lineWidth=s*.14;ctx.beginPath();ctx.moveTo(n1x,stemTop);ctx.lineTo(n2x,stemTop);ctx.stroke();ctx.lineWidth=s*.12;ctx.beginPath();ctx.moveTo(n1x,stemTop+s*.17);ctx.lineTo(n2x,stemTop+s*.17);ctx.stroke()}
                          else if(sk==="cat"){ctx.beginPath();ctx.arc(cx,cy+s*.08,s*.70,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.50,cy-s*.40);ctx.lineTo(cx-s*.22,cy-s*.76);ctx.lineTo(cx-s*.06,cy-s*.36);ctx.closePath();ctx.fillStyle="rgba("+r+","+g+","+b+",0.45)";ctx.fill();ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.50,cy-s*.40);ctx.lineTo(cx+s*.22,cy-s*.76);ctx.lineTo(cx+s*.06,cy-s*.36);ctx.closePath();ctx.fill();ctx.stroke();ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)";ctx.save();ctx.translate(cx-s*.26,cy-s*.04);ctx.save();ctx.scale(s*.12,s*.15);ctx.beginPath();ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.restore();ctx.save();ctx.translate(cx+s*.26,cy-s*.04);ctx.save();ctx.scale(s*.12,s*.15);ctx.beginPath();ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.restore();ctx.beginPath();ctx.moveTo(cx,cy+s*.18);ctx.lineTo(cx-s*.08,cy+s*.28);ctx.lineTo(cx+s*.08,cy+s*.28);ctx.closePath();ctx.fillStyle="rgba("+r+","+g+","+b+",0.8)";ctx.fill();ctx.lineWidth=0.9;ctx.strokeStyle="rgba("+r+","+g+","+b+",0.65)";ctx.beginPath();ctx.moveTo(cx-s*.16,cy+s*.24);ctx.lineTo(cx-s*.76,cy+s*.18);ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.16,cy+s*.30);ctx.lineTo(cx-s*.76,cy+s*.32);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.16,cy+s*.24);ctx.lineTo(cx+s*.76,cy+s*.18);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.16,cy+s*.30);ctx.lineTo(cx+s*.76,cy+s*.32);ctx.stroke()}
                          else if(sk==="bunny"){ctx.save();ctx.translate(cx-s*.26,cy-s*.28);ctx.rotate(-0.14);ctx.beginPath();ctx.save();ctx.scale(s*.20,s*.60);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.stroke();ctx.restore();ctx.save();ctx.translate(cx+s*.26,cy-s*.28);ctx.rotate(0.14);ctx.beginPath();ctx.save();ctx.scale(s*.20,s*.60);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.stroke();ctx.restore();ctx.beginPath();ctx.arc(cx,cy+s*.24,s*.54,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.fillStyle="rgba("+r+","+g+","+b+",0.28)";ctx.save();ctx.translate(cx-s*.26,cy-s*.28);ctx.rotate(-0.14);ctx.save();ctx.scale(s*.10,s*.42);ctx.beginPath();ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.restore();ctx.save();ctx.translate(cx+s*.26,cy-s*.28);ctx.rotate(0.14);ctx.save();ctx.scale(s*.10,s*.42);ctx.beginPath();ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.restore();ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)";ctx.beginPath();ctx.arc(cx-s*.20,cy+s*.14,s*.09,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx+s*.20,cy+s*.14,s*.09,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx,cy+s*.30,s*.06,0,Math.PI*2);ctx.fill()}
                          else if(sk==="android"){ctx.lineWidth=s*.09;ctx.lineCap="round";ctx.strokeStyle=sa;ctx.beginPath();ctx.moveTo(cx-s*.28,cy-s*.52);ctx.lineTo(cx-s*.48,cy-s*.88);ctx.stroke();ctx.beginPath();ctx.arc(cx-s*.48,cy-s*.88,s*.06,0,Math.PI*2);ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)";ctx.fill();ctx.beginPath();ctx.moveTo(cx+s*.28,cy-s*.52);ctx.lineTo(cx+s*.48,cy-s*.88);ctx.stroke();ctx.beginPath();ctx.arc(cx+s*.48,cy-s*.88,s*.06,0,Math.PI*2);ctx.fill();ctx.fillStyle="rgba("+r+","+g+","+b+",0.32)";var hr2=s*.16,hx2=cx-s*.62,hy2=cy-s*.52,hw2=s*1.24,hh2=s*.78;ctx.beginPath();ctx.moveTo(hx2+hr2,hy2);ctx.lineTo(hx2+hw2-hr2,hy2);ctx.arc(hx2+hw2-hr2,hy2+hr2,hr2,-Math.PI/2,0);ctx.lineTo(hx2+hw2,hy2+hh2-hr2);ctx.arc(hx2+hw2-hr2,hy2+hh2-hr2,hr2,0,Math.PI/2);ctx.lineTo(hx2+hr2,hy2+hh2);ctx.arc(hx2+hr2,hy2+hh2-hr2,hr2,Math.PI/2,Math.PI);ctx.lineTo(hx2,hy2+hr2);ctx.arc(hx2+hr2,hy2+hr2,hr2,Math.PI,Math.PI*1.5);ctx.closePath();ctx.fill();ctx.stroke();ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)";ctx.beginPath();ctx.arc(cx-s*.24,cy-s*.22,s*.09,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx+s*.24,cy-s*.22,s*.09,0,Math.PI*2);ctx.fill()}
                        }
                      }
                    }
                    Text {
                      text: modelData.nm
                      anchors.top: cShpBox.bottom; anchors.topMargin: vpx(1)
                      anchors.horizontalCenter: parent.horizontalCenter
                      font.pixelSize: vpx(7); color: sel ? createTab.newColor : "#666666"
                      horizontalAlignment: Text.AlignHCenter
                    }
                    MouseArea {
                      anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { createTab.newShape=modelData.key }
                    }
                  }
                }
              }

                            Item { height: vpx(8); width: parent.width }

              // ── Profile Top Border Emojis ─────────────────────────
              Item {
                width: parent.width; height: vpx(28)
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left; anchors.right: parent.right
                  anchors.rightMargin: createChooseBdrTopRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Top Border"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: createChooseBdrTopRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: createChooseBdrTopRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Top Border"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: createTab.borderTopExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: createTab.borderTopExpanded = !createTab.borderTopExpanded }
                }
              }
              Flow {
                visible: createTab.borderTopExpanded
                spacing: vpx(4); width: parent.width
                Repeater {
                  model: [
                    { key:"▀▄▀▄▀▄",                  nm:"Blocks"   },
                    { key:"⫘⫘⫘⫘⫘⫘",                nm:"Lines"    },
                    { key:"⸝⸝⸝⸝⸝⸝",             nm:"Waves"    },
                    { key:"*ੈ✩‧₊˚༺☆༻*ੈ✩‧₊˚",       nm:"Stars"    },
                    { key:":･ﾟ✧:･.☽˚｡･ﾟ✧:･.:",     nm:"Moon"     },
                    { key:"﹌﹌﹌﹌﹌",               nm:"Squig"    },
                    { key:"⋆༺𓆩☠︎︎𓆪༻⋆",              nm:"Skull"    },
                    { key:"✩♬ ₊˚.♪⋆☾⋆⁺₊✧",          nm:"Music"    },
                    { key:"✪ ✪ ✪ ✪ ✪",              nm:"Stars2"   },
                    { key:"▄︻デ══━一 ▄︻デ══━一",      nm:"Guns"     },
                    { key:"✦ ✧ ✦ ✧ ✦ ✧ ✦",          nm:"Diamond"  },
                    { key:"≋≋≋≋≋≋≋≋≋",              nm:"Ripple"   },
                    { key:"◈ ◈ ◈ ◈ ◈ ◈",            nm:"Compass"  },
                    { key:"⬡ ⬡ ⬡ ⬡ ⬡ ⬡",            nm:"Hex"      },
                    { key:"✶ ✶ ✶ ✶ ✶ ✶",            nm:"Burst"    },
                    { key:"❖ ❖ ❖ ❖ ❖ ❖",            nm:"Ornament" },
                    { key:"⁕ ⁕ ⁕ ⁕ ⁕ ⁕ ⁕",          nm:"Flower"   },
                    { key:"╔══════╗",                nm:"Frame"    },
                    { key:"◄◄◄◄◄◄◄◄◄",              nm:"Arrows"   },
                    { key:"░▒▓▓▒░",                  nm:"Fade"     },
                    { key:"",                         nm:"None"     }
                  ]
                  delegate: Item {
                    property bool sel: (api.memory.get("profile.slot." + root.nextFreeSlot() + ".borderTop") || "") === modelData.key
                    width: (parent.width - vpx(4)*5) / 6; height: vpx(52)
                    Rectangle {
                      id: cBdrTopBox
                      anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                      width: vpx(58); height: vpx(30); radius: vpx(4)
                      color: sel ? Qt.rgba(parseInt(createTab.newColor.slice(1,3),16)/255,parseInt(createTab.newColor.slice(3,5),16)/255,parseInt(createTab.newColor.slice(5,7),16)/255,0.35) : "#14FFFFFF"
                      border.color: sel ? createTab.newColor : "#28FFFFFF"
                      border.width: sel ? vpx(2) : vpx(1)
                      StyledText {
                        anchors.centerIn: parent
                        width: parent.width - vpx(6)
                        text: modelData.key !== "" ? modelData.key : "— None —"
                        font.pixelSize: vpx(11); color: sel ? createTab.newColor : "#FFFFFF"
                        elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                      }
                    }
                    Text {
                      anchors.top: cBdrTopBox.bottom; anchors.topMargin: vpx(2)
                      anchors.horizontalCenter: parent.horizontalCenter
                      width: parent.width
                      text: modelData.nm
                      font.pixelSize: vpx(8); color: sel ? createTab.newColor : "#AAAAAA"
                      horizontalAlignment: Text.AlignHCenter
                    }
                    MouseArea {
                      anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { var s = root.nextFreeSlot(); if(s > 0) api.memory.set("profile.slot." + s + ".borderTop", modelData.key) }
                    }
                  }
                }
              }

              // ── Profile Bottom Border Emojis ──────────────────────
              Item {
                width: parent.width; height: vpx(28)
                Row {
                  spacing: vpx(6)
                  anchors.left: parent.left; anchors.right: parent.right
                  anchors.rightMargin: createChooseBdrBotRow.implicitWidth + vpx(32)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  Rectangle {
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: root.accentHex
                    anchors.verticalCenter: parent.verticalCenter
                  }
                  StyledText {
                    text: "Bottom Border"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
                Rectangle {
                  anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                  height: vpx(24); width: createChooseBdrBotRow.implicitWidth + vpx(16)
                  radius: vpx(4)
                  color: root.accentRgba(0.25)
                  border.color: root.accentRgba(0.55); border.width: vpx(1)
                  Row {
                    id: createChooseBdrBotRow
                    spacing: vpx(5); anchors.centerIn: parent
                    StyledText { text: "Choose Bottom Border"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: createTab.borderBottomExpanded ? "▲" : "▼"; font.pixelSize: vpx(10); color: "#FFFFFF";
 }
                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: createTab.borderBottomExpanded = !createTab.borderBottomExpanded }
                }
              }
              Flow {
                visible: createTab.borderBottomExpanded
                spacing: vpx(4); width: parent.width
                Repeater {
                  model: [
                    { key:"▀▄▀▄▀▄",                  nm:"Blocks"   },
                    { key:"⫘⫘⫘⫘⫘⫘",                nm:"Lines"    },
                    { key:"⸝⸝⸝⸝⸝⸝",             nm:"Waves"    },
                    { key:"*ੈ✩‧₊˚༺☆༻*ੈ✩‧₊˚",       nm:"Stars"    },
                    { key:":･ﾟ✧:･.☽˚｡･ﾟ✧:･.:",     nm:"Moon"     },
                    { key:"﹌﹌﹌﹌﹌",               nm:"Squig"    },
                    { key:"⋆༺𓆩☠︎︎𓆪༻⋆",              nm:"Skull"    },
                    { key:"✩♬ ₊˚.♪⋆☾⋆⁺₊✧",          nm:"Music"    },
                    { key:"✪ ✪ ✪ ✪ ✪",              nm:"Stars2"   },
                    { key:"▄︻デ══━一 ▄︻デ══━一",      nm:"Guns"     },
                    { key:"✦ ✧ ✦ ✧ ✦ ✧ ✦",          nm:"Diamond"  },
                    { key:"≋≋≋≋≋≋≋≋≋",              nm:"Ripple"   },
                    { key:"◈ ◈ ◈ ◈ ◈ ◈",            nm:"Compass"  },
                    { key:"⬡ ⬡ ⬡ ⬡ ⬡ ⬡",            nm:"Hex"      },
                    { key:"✶ ✶ ✶ ✶ ✶ ✶",            nm:"Burst"    },
                    { key:"❖ ❖ ❖ ❖ ❖ ❖",            nm:"Ornament" },
                    { key:"⁕ ⁕ ⁕ ⁕ ⁕ ⁕ ⁕",          nm:"Flower"   },
                    { key:"╔══════╗",                nm:"Frame"    },
                    { key:"◄◄◄◄◄◄◄◄◄",              nm:"Arrows"   },
                    { key:"░▒▓▓▒░",                  nm:"Fade"     },
                    { key:"",                         nm:"None"     }
                  ]
                  delegate: Item {
                    property bool sel: (api.memory.get("profile.slot." + root.nextFreeSlot() + ".borderBottom") || "") === modelData.key
                    width: (parent.width - vpx(4)*5) / 6; height: vpx(52)
                    Rectangle {
                      id: cBdrBox
                      anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                      width: parent.width - vpx(2); height: vpx(34); radius: vpx(4)
                      color: sel ? Qt.rgba(parseInt(createTab.newColor.slice(1,3),16)/255,parseInt(createTab.newColor.slice(3,5),16)/255,parseInt(createTab.newColor.slice(5,7),16)/255,0.35) : "#14FFFFFF"
                      border.color: sel ? createTab.newColor : "#28FFFFFF"
                      border.width: sel ? vpx(2) : vpx(1)
                      StyledText {
                        anchors.centerIn: parent
                        width: parent.width - vpx(6)
                        text: modelData.key !== "" ? modelData.key : "— None —"
                        font.pixelSize: vpx(11); color: sel ? createTab.newColor : "#FFFFFF"
                        elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                      }
                    }
                    Text {
                      anchors.top: cBdrBox.bottom; anchors.topMargin: vpx(2)
                      anchors.horizontalCenter: parent.horizontalCenter
                      width: parent.width
                      text: modelData.nm
                      font.pixelSize: vpx(8); color: sel ? createTab.newColor : "#AAAAAA"
                      horizontalAlignment: Text.AlignHCenter
                    }
                    MouseArea {
                      anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { var s = root.nextFreeSlot(); if(s > 0) api.memory.set("profile.slot." + s + ".borderBottom", modelData.key) }
                    }
                  }
                }
              }

                            Item { height: vpx(12); width: parent.width }

                            // ── Create Profile button (pinned to bottom) ────────
                            Rectangle {
                              width: parent.width; height: vpx(40); radius: vpx(6)
                              color: root.nextFreeSlot() === -1 ? "#22444444" : root.accentHex
                              border.color: root.nextFreeSlot() === -1 ? "#40FFFFFF" : root.accentRgba(0.5); border.width: vpx(1)
                              StyledText {
                                anchors.centerIn: parent
                                text: root.nextFreeSlot() === -1 ? "All 9 slots are full" : "✨  Create Profile"
                                font.pixelSize: vpx(13); font.bold: true
                                color: root.nextFreeSlot() === -1 ? "#555555" : "#FFFFFF"

                              }
                              MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: root.nextFreeSlot() !== -1
                                onClicked: {
                                  var currentSlot = -1
                                  for (var i = 1; i <= 9; i++) {
                                    var sn = api.memory.get("profile.slot." + i + ".name")
                                    if (sn === root.profileName) { currentSlot = i; break }
                                  }
                                  if (currentSlot === -1) currentSlot = root.nextFreeSlot()
                                  if (currentSlot !== -1) {
                                    root.saveSlot(currentSlot, root.profileName, root.profileAvatar,
                                                  root.profileGamerpic, root.profileGamerscore,
                                                  root.profileStatus, root.profileSubStatus,
                                                  root.profileMotto, root.profileBio,
                                                  root.profileRegion, root.profileColor, root.profileShape)
                                  }
                                  var newSlot = root.nextFreeSlot()
                                  if (newSlot === -1) return
                                  var newName = cNameInput.text.trim() !== "" ? cNameInput.text.trim() : ("Player" + (parseInt(api.memory.get("profile.count") || "1") + 1))
                                  var count = parseInt(api.memory.get("profile.count") || "1") + 1
                                  api.memory.set("profile.count", count.toString())
                                  var gs = parseInt(cGsInput.text) || 0
                                  root.saveSlot(newSlot, newName, createTab.newAvatar, createTab.newGamerpic, gs,
                                                cStatusInput.text, cSubInput.text, cMottoInput.text,
                                                cBioInput.text, cRegionInput.text, createTab.newColor, createTab.newShape)
                                  root.profileName       = newName
                                  root.profileGamerscore = gs
                                  root.profileStatus     = cStatusInput.text
                                  root.profileSubStatus  = cSubInput.text
                                  root.profileMotto      = cMottoInput.text
                                  root.profileBio        = cBioInput.text
                                  root.profileRegion     = cRegionInput.text
                                  root.profileAvatar     = createTab.newAvatar
                                  root.profileGamerpic   = createTab.newGamerpic
                                  root.profileColor      = createTab.newColor
                                  root.profileShape      = createTab.newShape
                                  api.memory.set("profile.name",       newName)
                                  api.memory.set("profile.gamerscore",  gs.toString())
                                  api.memory.set("profile.status",      cStatusInput.text)
                                  api.memory.set("profile.substatus",   cSubInput.text)
                                  api.memory.set("profile.motto",       cMottoInput.text)
                                  api.memory.set("profile.bio",         cBioInput.text)
                                  api.memory.set("profile.region",      cRegionInput.text)
                                  api.memory.set("profile.avatar",      createTab.newAvatar)
                                  api.memory.set("profile.gamerpic",    createTab.newGamerpic)
                                  api.memory.set("profile.color",       createTab.newColor)
                                  api.memory.set("profile.shape",       createTab.newShape)
                                  root.rebuildPanels()
                                  root.profileTabIndex = 0
                                  var createdSlot = newSlot
                                  Qt.callLater(function() {
                                    for (var nci = 1; nci < panelsModel.count; nci++) {
                                      if (panelsModel.get(nci).slotNum === createdSlot) {
                                        panelsList.currentIndex = nci; break
                                      }
                                    }
                                  })
                                }
                              }
                            }
                            Item { height: vpx(8); width: parent.width }
            }
          }

          Image {
            source: "../../assets/images/system/up-default.png"
            width: vpx(22); height: vpx(18)
            anchors.top: parent.top; anchors.right: parent.right
            anchors.topMargin: vpx(2); anchors.rightMargin: vpx(2)
            fillMode: Image.PreserveAspectFit; asynchronous: true
            opacity: editFlick.atYBeginning ? 0 : 0.8
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }
          Image {
            source: "../../assets/images/system/down-default.png"
            width: vpx(22); height: vpx(18)
            anchors.bottom: parent.bottom; anchors.right: parent.right
            anchors.bottomMargin: vpx(2); anchors.rightMargin: vpx(2)
            fillMode: Image.PreserveAspectFit; asynchronous: true
            opacity: editFlick.atYEnd ? 0 : 0.8
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }
        }

        // ── TAB 4: APPEARANCE ─────────────────────────────────────
        // Controls ONLY the avatar scene panels. Edit profile panel is unaffected.
        Item {
          visible: root.profileTabIndex === 4
          anchors.fill: parent

          Flickable {
            id: appearFlick
            anchors.fill: parent
            anchors.rightMargin: vpx(26)
            contentHeight: appearCol.implicitHeight + vpx(40)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
              id: appearCol
              width: parent.width
              spacing: vpx(8)

              // ── ✦ Avatar Scene Controller button ─────────────────────
              Item { width: parent.width; height: vpx(8) }
              Rectangle {
                width: parent.width; height: vpx(26); radius: vpx(5)
                color: root.avatarSceneDrawerOpen ? root.accentRgba(0.40) : root.accentRgba(0.12)
                border.color: root.avatarSceneDrawerOpen ? root.accentHex : root.accentRgba(0.40)
                border.width: vpx(1)
                Row {
                  anchors.centerIn: parent; spacing: vpx(6)
                  StyledText { text: "✦"; font.pixelSize: vpx(11); color: root.avatarSceneDrawerOpen ? "#FFFFFF" : root.accentHex

                  }
                  StyledText { text: "Avatar Scene Controller"; font.pixelSize: vpx(11); font.bold: root.avatarSceneDrawerOpen; color: root.avatarSceneDrawerOpen ? "#FFFFFF" : root.accentHex

                  }
                }
                MouseArea {
                  anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: root.avatarSceneDrawerOpen = !root.avatarSceneDrawerOpen
                }
              }

              // ── Spacer ───────────────────────────────────────────
              Item { width: parent.width; height: vpx(10) }

              // ══════════════════════════════════════════════════════
              // SECTION: PROFILE PANEL  (collapsible)
              // ══════════════════════════════════════════════════════
              Item {
                id: ppSection
                property bool expanded: true
                width: parent.width
                height: expanded ? ppHeader.height + ppBody.implicitHeight + vpx(6) : ppHeader.height
                clip: true
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                // ── Header ──────────────────────────────────────────
                Item {
                  id: ppHeader
                  width: parent.width; height: vpx(28)
                  Rectangle {
                    anchors.fill: parent; radius: vpx(4)
                    color: root.accentRgba(ppSection.expanded ? 0.25 : 0.15)
                    border.color: root.accentRgba(0.55); border.width: vpx(1)
                  }
                  Row {
                    id: ppHeaderRow
                    anchors.centerIn: parent
                    spacing: vpx(5)
                    StyledText {
                      text: "Profile Panel Controller"
                      font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"
                    }
                    StyledText {
                      text: ppSection.expanded ? "▲" : "▼"
                      font.pixelSize: vpx(10); color: "#FFFFFF"
                    }
                  }
                  MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: ppSection.expanded = !ppSection.expanded
                  }
                }

                // ── Body ────────────────────────────────────────────
                Column {
                  id: ppBody
                  anchors.top: ppHeader.bottom; anchors.topMargin: vpx(6)
                  width: parent.width; spacing: vpx(8)

              // ── Theme Transparency (Dark mode panel opacity) ────────
              Item {
                width: parent.width; height: vpx(20)
                Rectangle { anchors.fill: parent; anchors.leftMargin: vpx(-2); radius: vpx(3); color: "#22FFFFFF" }
                Row { anchors.fill: parent; spacing: vpx(6)
                  StyledText { anchors.verticalCenter: parent.verticalCenter; text: "Theme Transparency"; font.pixelSize: vpx(12); font.bold: true; color: root.accentHex;
 }
                  StyledText { anchors.verticalCenter: parent.verticalCenter; text: Math.round(root.ifaceTransparency) + "%"; font.pixelSize: vpx(11); color: "#FFFFFF" }
                }
              }
              Row {
                width: parent.width; height: vpx(32); spacing: vpx(6)
                Rectangle {
                  width: vpx(28); height: vpx(28); radius: vpx(14); anchors.verticalCenter: parent.verticalCenter
                  color: root.accentHex; border.color: "#55FFFFFF"; border.width: vpx(1)

                  StyledText { anchors.centerIn: parent; text: "−"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF" }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked:     { var v=Math.max(0,root.ifaceTransparency-1);  root.ifaceTransparency=v;  api.memory.set("cfg.ifaceAlpha",v.toString()) }
                    onPressAndHold:{ var v=Math.max(0,root.ifaceTransparency-5);  root.ifaceTransparency=v;  api.memory.set("cfg.ifaceAlpha",v.toString()) }
                  }
                }
                Item {
                  width: parent.width - vpx(70); height: parent.height; anchors.verticalCenter: parent.verticalCenter
                  Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: vpx(6); radius: vpx(3); color: "#30FFFFFF"
                    Rectangle { width: parent.width*(root.ifaceTransparency/100); height: parent.height; radius: parent.radius; color: root.accentHex }
                  }
                  Rectangle {
                    width: vpx(20); height: vpx(20); radius: vpx(10); color: root.accentHex; border.color: "#FFFFFF"; border.width: vpx(2)
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width-vpx(20), (root.ifaceTransparency/100)*(parent.width-vpx(20))))

                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked:        { var v=Math.max(0,Math.min(100,Math.round(mouseX/width*100))); root.ifaceTransparency=v; api.memory.set("cfg.ifaceAlpha",v.toString()) }
                    onPositionChanged:{ if(pressed){ var v=Math.max(0,Math.min(100,Math.round(mouseX/width*100))); root.ifaceTransparency=v; api.memory.set("cfg.ifaceAlpha",v.toString()) } }
                  }
                }
                Rectangle {
                  width: vpx(28); height: vpx(28); radius: vpx(14); anchors.verticalCenter: parent.verticalCenter
                  color: root.accentHex; border.color: "#55FFFFFF"; border.width: vpx(1)

                  StyledText { anchors.centerIn: parent; text: "+"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF" }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked:     { var v=Math.min(100,root.ifaceTransparency+1); root.ifaceTransparency=v; api.memory.set("cfg.ifaceAlpha",v.toString()) }
                    onPressAndHold:{ var v=Math.min(100,root.ifaceTransparency+5); root.ifaceTransparency=v; api.memory.set("cfg.ifaceAlpha",v.toString()) }
                  }
                }
              }

              Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }

              // ── Theme Opacity (Light mode panel opacity) ────────────
              Item {
                width: parent.width; height: vpx(20)
                Rectangle { anchors.fill: parent; anchors.leftMargin: vpx(-2); radius: vpx(3); color: "#22FFFFFF" }
                Row { anchors.fill: parent; spacing: vpx(6)
                  StyledText { anchors.verticalCenter: parent.verticalCenter; text: "Theme Opacity"; font.pixelSize: vpx(12); font.bold: true; color: root.accentHex;
 }
                  StyledText { anchors.verticalCenter: parent.verticalCenter; text: Math.round(root.libTransp) + "%"; font.pixelSize: vpx(11); color: "#FFFFFF" }
                }
              }
              Row {
                width: parent.width; height: vpx(32); spacing: vpx(6)
                Rectangle {
                  width: vpx(28); height: vpx(28); radius: vpx(14); anchors.verticalCenter: parent.verticalCenter
                  color: root.accentHex; border.color: "#55FFFFFF"; border.width: vpx(1)

                  StyledText { anchors.centerIn: parent; text: "−"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF" }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked:     { var v=Math.max(0,root.libTransp-1);  root.libTransp=v;  api.memory.set("theme.libTransp",v.toString()) }
                    onPressAndHold:{ var v=Math.max(0,root.libTransp-5);  root.libTransp=v;  api.memory.set("theme.libTransp",v.toString()) }
                  }
                }
                Item {
                  width: parent.width - vpx(70); height: parent.height; anchors.verticalCenter: parent.verticalCenter
                  Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: vpx(6); radius: vpx(3); color: "#30FFFFFF"
                    Rectangle { width: parent.width*(root.libTransp/100); height: parent.height; radius: parent.radius; color: root.accentHex }
                  }
                  Rectangle {
                    width: vpx(20); height: vpx(20); radius: vpx(10); color: root.accentHex; border.color: "#FFFFFF"; border.width: vpx(2)
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width-vpx(20), (root.libTransp/100)*(parent.width-vpx(20))))

                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked:        { var v=Math.max(0,Math.min(100,Math.round(mouseX/width*100))); root.libTransp=v; api.memory.set("theme.libTransp",v.toString()) }
                    onPositionChanged:{ if(pressed){ var v=Math.max(0,Math.min(100,Math.round(mouseX/width*100))); root.libTransp=v; api.memory.set("theme.libTransp",v.toString()) } }
                  }
                }
                Rectangle {
                  width: vpx(28); height: vpx(28); radius: vpx(14); anchors.verticalCenter: parent.verticalCenter
                  color: root.accentHex; border.color: "#55FFFFFF"; border.width: vpx(1)

                  StyledText { anchors.centerIn: parent; text: "+"; font.pixelSize: vpx(16); font.bold: true; color: "#FFFFFF" }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked:     { var v=Math.min(100,root.libTransp+1); root.libTransp=v; api.memory.set("theme.libTransp",v.toString()) }
                    onPressAndHold:{ var v=Math.min(100,root.libTransp+5); root.libTransp=v; api.memory.set("theme.libTransp",v.toString()) }
                  }
                }
              }

              Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }

              // ── Dark Mode On/Off ────────────────────────────────────
              Item {
                width: parent.width; height: vpx(20)
                Rectangle { anchors.fill: parent; anchors.leftMargin: vpx(-2); radius: vpx(3); color: "#22FFFFFF" }
                StyledText { anchors.verticalCenter: parent.verticalCenter; text: "Dark Mode"; font.pixelSize: vpx(12); font.bold: true; color: root.accentHex;
 }
              }
              Row {
                spacing: vpx(8)
                Repeater {
                  model: ["On", "Off"]
                  delegate: Rectangle {
                    property bool active: index === 0 ? root.themeDarkOn : !root.themeDarkOn
                    width: vpx(56); height: vpx(28); radius: vpx(14)
                    color: active ? root.accentHex : "#22FFFFFF"
                    border.color: active ? root.accentHex : "#44FFFFFF"; border.width: vpx(1)

                    StyledText { anchors.centerIn: parent; text: modelData; font.pixelSize: vpx(12); font.bold: active; color: "#FFFFFF";
 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { var val = index===0 ? "true":"false"; api.memory.set("theme.themeDark",val); root.themeDarkOn=(val!=="false") }
                    }
                  }
                }
              }

              Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }

              // ── Panel Gradient On/Off ───────────────────────────────
              Item {
                width: parent.width; height: vpx(20)
                Rectangle { anchors.fill: parent; anchors.leftMargin: vpx(-2); radius: vpx(3); color: "#22FFFFFF" }
                StyledText { anchors.verticalCenter: parent.verticalCenter; text: "Panel Gradient"; font.pixelSize: vpx(12); font.bold: true; color: root.accentHex;
 }
              }
              Row {
                spacing: vpx(8)
                Repeater {
                  model: ["On", "Off"]
                  delegate: Rectangle {
                    property bool active: index === 0 ? root.panelGradient : !root.panelGradient
                    width: vpx(56); height: vpx(28); radius: vpx(14)
                    color: active ? root.accentHex : "#22FFFFFF"
                    border.color: active ? root.accentHex : "#44FFFFFF"; border.width: vpx(1)

                    StyledText { anchors.centerIn: parent; text: modelData; font.pixelSize: vpx(12); font.bold: active; color: "#FFFFFF";
 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { var val = index===0 ? "true":"false"; api.memory.set("cfg.panelGradient",val); root.panelGradient=(val!=="false") }
                    }
                  }
                }
              }

              Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }

              // ── Accent Gradient On/Off ──────────────────────────────
              Item {
                width: parent.width; height: vpx(20)
                Rectangle { anchors.fill: parent; anchors.leftMargin: vpx(-2); radius: vpx(3); color: "#22FFFFFF" }
                StyledText { anchors.verticalCenter: parent.verticalCenter; text: "Accent Gradient"; font.pixelSize: vpx(12); font.bold: true; color: root.accentHex;
 }
              }
              Row {
                spacing: vpx(8)
                Repeater {
                  model: ["On", "Off"]
                  delegate: Rectangle {
                    property bool active: index === 0 ? root.gradAccentOn : !root.gradAccentOn
                    width: vpx(56); height: vpx(28); radius: vpx(14)
                    color: active ? root.accentHex : "#22FFFFFF"
                    border.color: active ? root.accentHex : "#44FFFFFF"; border.width: vpx(1)

                    StyledText { anchors.centerIn: parent; text: modelData; font.pixelSize: vpx(12); font.bold: active; color: "#FFFFFF";
 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { var val = index===0 ? "true":"false"; api.memory.set("cfg.gradAccent",val); root.gradAccentOn=(val!=="false") }
                    }
                  }
                }
              }

              Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }

              // ── Theme Gradient On/Off ───────────────────────────────
              Item {
                width: parent.width; height: vpx(20)
                Rectangle { anchors.fill: parent; anchors.leftMargin: vpx(-2); radius: vpx(3); color: "#22FFFFFF" }
                StyledText { anchors.verticalCenter: parent.verticalCenter; text: "Theme Gradient"; font.pixelSize: vpx(12); font.bold: true; color: root.accentHex;
 }
              }
              Row {
                spacing: vpx(8)
                Repeater {
                  model: ["On", "Off"]
                  delegate: Rectangle {
                    property bool active: index === 0 ? root.gradThemeOn : !root.gradThemeOn
                    width: vpx(56); height: vpx(28); radius: vpx(14)
                    color: active ? root.accentHex : "#22FFFFFF"
                    border.color: active ? root.accentHex : "#44FFFFFF"; border.width: vpx(1)

                    StyledText { anchors.centerIn: parent; text: modelData; font.pixelSize: vpx(12); font.bold: active; color: "#FFFFFF";
 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { var val = index===0 ? "true":"false"; api.memory.set("cfg.gradTheme",val); root.gradThemeOn=(val!=="false") }
                    }
                  }
                }
              }

              Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }

              // ── Drop Shadow On/Off ──────────────────────────────────
              Item {
                width: parent.width; height: vpx(20)
                Rectangle { anchors.fill: parent; anchors.leftMargin: vpx(-2); radius: vpx(3); color: "#22FFFFFF" }
                StyledText { anchors.verticalCenter: parent.verticalCenter; text: "Drop Shadow"; font.pixelSize: vpx(12); font.bold: true; color: root.accentHex;
 }
              }
              Row {
                spacing: vpx(8)
                Repeater {
                  model: ["On", "Off"]
                  delegate: Rectangle {
                    property bool active: index === 0 ? root.profileDropShadow : !root.profileDropShadow
                    width: vpx(56); height: vpx(28); radius: vpx(14)
                    color: active ? root.accentHex : "#22FFFFFF"
                    border.color: active ? root.accentHex : "#44FFFFFF"; border.width: vpx(1)

                    StyledText { anchors.centerIn: parent; text: modelData; font.pixelSize: vpx(12); font.bold: active; color: "#FFFFFF";
 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { var val = index===0 ? "true":"false"; api.memory.set("cfg.profileDropShadow",val); root.profileDropShadow=(val!=="false") }
                    }
                  }
                }
              }

              Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }

              // ── Profile Shape On/Off ────────────────────────────────
              Item {
                width: parent.width; height: vpx(20)
                Rectangle { anchors.fill: parent; anchors.leftMargin: vpx(-2); radius: vpx(3); color: "#22FFFFFF" }
                StyledText { anchors.verticalCenter: parent.verticalCenter; text: "Profile Shape"; font.pixelSize: vpx(12); font.bold: true; color: root.accentHex;
 }
              }
              Row {
                spacing: vpx(8)
                Repeater {
                  model: ["On", "Off"]
                  delegate: Rectangle {
                    property bool active: index === 0 ? root.profileShapeOn : !root.profileShapeOn
                    width: vpx(56); height: vpx(28); radius: vpx(14)
                    color: active ? root.accentHex : "#22FFFFFF"
                    border.color: active ? root.accentHex : "#44FFFFFF"; border.width: vpx(1)

                    StyledText { anchors.centerIn: parent; text: modelData; font.pixelSize: vpx(12); font.bold: active; color: "#FFFFFF";
 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { var val = index===0 ? "true":"false"; api.memory.set("cfg.profileShapeOn",val); root.profileShapeOn=(val!=="false") }
                    }
                  }
                }
              }

              Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }

              // ── Choose Shape ────────────────────────────────────────
              Item {
                width: parent.width; height: vpx(20)
                visible: root.profileShapeOn
                Rectangle { anchors.fill: parent; anchors.leftMargin: vpx(-2); radius: vpx(3); color: "#22FFFFFF" }
                StyledText { anchors.verticalCenter: parent.verticalCenter; text: "Choose Shape"; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
              }
              Flow {
                visible: root.profileShapeOn
                spacing: vpx(4); width: parent.width
                Repeater {
                  model: [
                    { key:"circle",     nm:"Circle"    },
                    { key:"square",     nm:"Square"    },
                    { key:"triangle",   nm:"Triangle"  },
                    { key:"diamond",    nm:"Diamond"   },
                    { key:"hexagon",    nm:"Hexagon"   },
                    { key:"octagon",    nm:"Octagon"   },
                    { key:"rectangle",  nm:"Rect"      },
                    { key:"star",       nm:"Star"      },
                    { key:"plus",       nm:"Plus"      },
                    { key:"cross_x",    nm:"X Cross"   },
                    { key:"heart",      nm:"Heart"     },
                    { key:"spade",      nm:"Spade"     },
                    { key:"club",       nm:"Club"      },
                    { key:"moon",       nm:"Moon"      },
                    { key:"waterdrop",  nm:"Drop"      },
                    { key:"spiral",     nm:"Spiral"    },
                    { key:"sparkle",    nm:"Sparkle"   },
                    { key:"smile",      nm:"Smile"     },
                    { key:"flower",     nm:"Flower"    },
                    { key:"daisy",      nm:"Daisy"     },
                    { key:"hexagram",   nm:"Hexagram"  },
                    { key:"quatrefoil", nm:"Quatrefoil"},
                    { key:"triquetra",  nm:"Triquetra" },
                    { key:"gear",       nm:"Gear"      },
                    { key:"windows",    nm:"Windows"   },
                    { key:"chevron",    nm:"Chevron"   },
                    { key:"splat",      nm:"Splat"     },
                    { key:"music",      nm:"Note"      },
                    { key:"music2",     nm:"Beamed"    },
                    { key:"cat",        nm:"Cat"       },
                    { key:"bunny",      nm:"Bunny"     },
                    { key:"android",    nm:"Android"   }
                  ]
                  delegate: Item {
                    property bool sel: root.profileShape === modelData.key
                    width: vpx(43); height: vpx(51)
                    Rectangle {
                      id: appShpBox
                      width: vpx(39); height: vpx(39); radius: vpx(4)
                      anchors.horizontalCenter: parent.horizontalCenter
                      color: sel ? root.accentRgba(0.35) : "#14FFFFFF"
                      border.color: sel ? root.accentHex : "#28FFFFFF"
                      border.width: sel ? vpx(2) : vpx(1)
                      Canvas {
                        anchors.fill: parent; anchors.margins: vpx(4)
                        property string sk: modelData.key
                        property string col: root.accentHex
                        property bool isSel: root.profileShape === modelData.key
                        onColChanged:   requestPaint()
                        onIsSelChanged: requestPaint()
                        Component.onCompleted: Qt.callLater(requestPaint)
                        onPaint: {
                          var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                          var h=col.replace("#","")
                          var r=parseInt(h.slice(0,2),16),g=parseInt(h.slice(2,4),16),b=parseInt(h.slice(4,6),16)
                          var fa="rgba("+r+","+g+","+b+",0.32)", sa="rgba("+r+","+g+","+b+",0.9)"
                          ctx.strokeStyle=sa; ctx.fillStyle=fa; ctx.lineWidth=1.5
                          var cx=width/2, cy=height/2, s=Math.min(width,height)/2-1
                          var i,a,a1,a2,t,teeth,ir,or2,tr,gap,pw,p,pa
                          if(sk==="circle"){
                            ctx.beginPath(); ctx.arc(cx,cy,s,0,Math.PI*2); ctx.fill(); ctx.stroke()
                          }else if(sk==="square"){
                            ctx.beginPath(); ctx.rect(cx-s,cy-s,s*2,s*2); ctx.fill(); ctx.stroke()
                          }else if(sk==="triangle"){
                            ctx.beginPath(); ctx.moveTo(cx,cy-s); ctx.lineTo(cx+s*.87,cy+s*.5); ctx.lineTo(cx-s*.87,cy+s*.5); ctx.closePath(); ctx.fill(); ctx.stroke()
                          }else if(sk==="diamond"){
                            ctx.beginPath(); ctx.moveTo(cx,cy-s); ctx.lineTo(cx+s*.65,cy); ctx.lineTo(cx,cy+s); ctx.lineTo(cx-s*.65,cy); ctx.closePath(); ctx.fill(); ctx.stroke()
                          }else if(sk==="hexagon"){
                            ctx.beginPath()
                            for(i=0;i<6;i++){a=Math.PI/180*(60*i-30);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                          }else if(sk==="octagon"){
                            ctx.beginPath()
                            for(i=0;i<8;i++){a=Math.PI/180*(45*i+22.5);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                          }else if(sk==="rectangle"){
                            ctx.beginPath(); ctx.rect(cx-s,cy-s*.6,s*2,s*1.2); ctx.fill(); ctx.stroke()
                          }else if(sk==="star"){
                            ctx.beginPath()
                            for(i=0;i<10;i++){a=Math.PI/180*(36*i-90);var sr=i%2===0?s:s*.42;if(i===0)ctx.moveTo(cx+sr*Math.cos(a),cy+sr*Math.sin(a));else ctx.lineTo(cx+sr*Math.cos(a),cy+sr*Math.sin(a))}
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                          }else if(sk==="plus"){
                            var arm=s*.36
                            ctx.beginPath()
                            ctx.moveTo(cx-arm,cy-s); ctx.lineTo(cx+arm,cy-s); ctx.lineTo(cx+arm,cy-arm)
                            ctx.lineTo(cx+s,cy-arm); ctx.lineTo(cx+s,cy+arm); ctx.lineTo(cx+arm,cy+arm)
                            ctx.lineTo(cx+arm,cy+s); ctx.lineTo(cx-arm,cy+s); ctx.lineTo(cx-arm,cy+arm)
                            ctx.lineTo(cx-s,cy+arm); ctx.lineTo(cx-s,cy-arm); ctx.lineTo(cx-arm,cy-arm)
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                          }else if(sk==="cross_x"){
                            ctx.lineWidth=s*.36; ctx.lineCap="round"; ctx.strokeStyle=sa
                            ctx.beginPath(); ctx.moveTo(cx-s*.7,cy-s*.7); ctx.lineTo(cx+s*.7,cy+s*.7); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx+s*.7,cy-s*.7); ctx.lineTo(cx-s*.7,cy+s*.7); ctx.stroke()
                          }else if(sk==="heart"){
                            ctx.beginPath()
                            ctx.moveTo(cx, cy+s*.80)
                            ctx.bezierCurveTo(cx-s*.10, cy+s*.60, cx-s*.90, cy+s*.30, cx-s*.90, cy-s*.10)
                            ctx.bezierCurveTo(cx-s*.90, cy-s*.55, cx-s*.50, cy-s*.80, cx, cy-s*.35)
                            ctx.bezierCurveTo(cx+s*.50, cy-s*.80, cx+s*.90, cy-s*.55, cx+s*.90, cy-s*.10)
                            ctx.bezierCurveTo(cx+s*.90, cy+s*.30, cx+s*.10, cy+s*.60, cx, cy+s*.80)
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                          }else if(sk==="spade"){
                            ctx.beginPath()
                            ctx.moveTo(cx, cy-s*.78)
                            ctx.bezierCurveTo(cx+s*.10, cy-s*.58, cx+s*.90, cy-s*.28, cx+s*.90, cy+s*.12)
                            ctx.bezierCurveTo(cx+s*.90, cy+s*.54, cx+s*.50, cy+s*.76, cx, cy+s*.32)
                            ctx.bezierCurveTo(cx-s*.50, cy+s*.76, cx-s*.90, cy+s*.54, cx-s*.90, cy+s*.12)
                            ctx.bezierCurveTo(cx-s*.90, cy-s*.28, cx-s*.10, cy-s*.58, cx, cy-s*.78)
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                            ctx.lineWidth=s*.16; ctx.lineCap="round"; ctx.strokeStyle=sa
                            ctx.beginPath(); ctx.moveTo(cx,cy+s*.32); ctx.lineTo(cx,cy+s*.78); ctx.stroke()
                            ctx.lineWidth=s*.18
                            ctx.beginPath(); ctx.moveTo(cx-s*.38,cy+s*.78); ctx.bezierCurveTo(cx-s*.12,cy+s*.58,cx+s*.12,cy+s*.58,cx+s*.38,cy+s*.78); ctx.stroke()
                          }else if(sk==="club"){
                            var cPos=[{x:cx,y:cy-s*.30},{x:cx-s*.34,y:cy+s*.12},{x:cx+s*.34,y:cy+s*.12}]
                            for(p=0;p<3;p++){ctx.beginPath();ctx.arc(cPos[p].x,cPos[p].y,s*.34,0,Math.PI*2);ctx.fill();ctx.stroke()}
                            ctx.lineWidth=s*.16; ctx.lineCap="round"
                            ctx.beginPath(); ctx.moveTo(cx,cy+s*.30); ctx.lineTo(cx,cy+s*.78); ctx.stroke()
                            ctx.lineWidth=s*.18
                            ctx.beginPath(); ctx.moveTo(cx-s*.38,cy+s*.78); ctx.bezierCurveTo(cx-s*.12,cy+s*.58,cx+s*.12,cy+s*.58,cx+s*.38,cy+s*.78); ctx.stroke()
                          }else if(sk==="moon"){
                            ctx.beginPath(); ctx.arc(cx,cy,s,0,Math.PI*2); ctx.fill(); ctx.stroke()
                            ctx.globalCompositeOperation="destination-out"
                            ctx.beginPath(); ctx.arc(cx+s*.40,cy-s*.20,s*.74,0,Math.PI*2); ctx.fillStyle="rgba(0,0,0,1)"; ctx.fill()
                            ctx.globalCompositeOperation="source-over"
                            ctx.beginPath(); ctx.arc(cx,cy,s,-Math.PI*.52,Math.PI*.70); ctx.strokeStyle=sa; ctx.stroke()
                          }else if(sk==="waterdrop"){
                            ctx.beginPath()
                            ctx.moveTo(cx, cy-s*.92)
                            ctx.bezierCurveTo(cx+s*.50, cy-s*.30, cx+s*.82, cy+s*.22, cx, cy+s*.92)
                            ctx.bezierCurveTo(cx-s*.82, cy+s*.22, cx-s*.50, cy-s*.30, cx, cy-s*.92)
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                          }else if(sk==="spiral"){
                            ctx.strokeStyle=sa; ctx.lineWidth=1.5; ctx.lineCap="round"
                            ctx.beginPath()
                            var turns=3, steps=120
                            for(i=0;i<=steps;i++){
                              var theta=turns*Math.PI*2*(i/steps)
                              var rad2=(s*.92)*(i/steps)
                              var sx2=cx+rad2*Math.cos(theta-Math.PI/2)
                              var sy2=cy+rad2*Math.sin(theta-Math.PI/2)
                              if(i===0) ctx.moveTo(sx2,sy2); else ctx.lineTo(sx2,sy2)
                            }
                            ctx.stroke()
                          }else if(sk==="sparkle"){
                            ctx.beginPath()
                            for(i=0;i<8;i++){
                              a=Math.PI/4*i-Math.PI/2
                              var rr=i%2===0?s:s*.12
                              if(i===0)ctx.moveTo(cx+rr*Math.cos(a),cy+rr*Math.sin(a)); else ctx.lineTo(cx+rr*Math.cos(a),cy+rr*Math.sin(a))
                            }
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                          }else if(sk==="smile"){
                            ctx.beginPath(); ctx.arc(cx,cy,s,0,Math.PI*2); ctx.fill(); ctx.stroke()
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"
                            ctx.beginPath(); ctx.arc(cx-s*.30,cy-s*.20,s*.11,0,Math.PI*2); ctx.fill()
                            ctx.beginPath(); ctx.arc(cx+s*.30,cy-s*.20,s*.11,0,Math.PI*2); ctx.fill()
                            ctx.beginPath(); ctx.strokeStyle=sa; ctx.lineWidth=1.6; ctx.lineCap="round"
                            ctx.arc(cx, cy+s*.10, s*.38, Math.PI*0.12, Math.PI*0.88); ctx.stroke()
                          }else if(sk==="flower"){
                            for(p=0;p<6;p++){pa=Math.PI/180*(60*p);var px=cx+s*.50*Math.cos(pa),py=cy+s*.50*Math.sin(pa);ctx.beginPath();ctx.arc(px,py,s*.40,0,Math.PI*2);ctx.fill();ctx.stroke()}
                            ctx.beginPath(); ctx.arc(cx,cy,s*.26,0,Math.PI*2); ctx.fillStyle="rgba("+r+","+g+","+b+",0.75)"; ctx.fill()
                          }else if(sk==="daisy"){
                            var np=10
                            for(p=0;p<np;p++){
                              pa=Math.PI*2/np*p
                              ctx.save(); ctx.translate(cx+s*.52*Math.cos(pa),cy+s*.52*Math.sin(pa)); ctx.rotate(pa)
                              ctx.save(); ctx.scale(s*.22,s*.42); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore()
                              ctx.fill(); ctx.stroke(); ctx.restore()
                            }
                            ctx.beginPath(); ctx.arc(cx,cy,s*.26,0,Math.PI*2); ctx.fillStyle="rgba("+r+","+g+","+b+",0.85)"; ctx.fill()
                          }else if(sk==="hexagram"){
                            ctx.beginPath(); ctx.moveTo(cx,cy-s); ctx.lineTo(cx+s*.87,cy+s*.5); ctx.lineTo(cx-s*.87,cy+s*.5); ctx.closePath(); ctx.fill(); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx,cy+s); ctx.lineTo(cx+s*.87,cy-s*.5); ctx.lineTo(cx-s*.87,cy-s*.5); ctx.closePath(); ctx.fill(); ctx.stroke()
                          }else if(sk==="quatrefoil"){
                            var qr=s*.50, qd=s*.36
                            var qpos=[{x:cx,y:cy-qd},{x:cx+qd,y:cy},{x:cx,y:cy+qd},{x:cx-qd,y:cy}]
                            for(p=0;p<4;p++){ctx.beginPath();ctx.arc(qpos[p].x,qpos[p].y,qr,0,Math.PI*2);ctx.fill();ctx.stroke()}
                            ctx.beginPath(); ctx.arc(cx,cy,s*.20,0,Math.PI*2); ctx.fillStyle="rgba("+r+","+g+","+b+",0.75)"; ctx.fill()
                          }else if(sk==="triquetra"){
                            ctx.strokeStyle=sa; ctx.lineWidth=s*.16; ctx.lineCap="round"; ctx.lineJoin="round"
                            var tr2=s*.66
                            for(p=0;p<3;p++){
                              a=Math.PI*2/3*p-Math.PI/2
                              var tx=cx+tr2*Math.cos(a), ty=cy+tr2*Math.sin(a)
                              ctx.save(); ctx.translate(tx,ty); ctx.rotate(a+Math.PI/2)
                              ctx.beginPath(); ctx.arc(0,0,tr2,Math.PI*0.62,Math.PI*1.38); ctx.stroke()
                              ctx.restore()
                            }
                          }else if(sk==="gear"){
                            teeth=10; ir=s*.44; or2=s*.70; tr=s*.90
                            ctx.beginPath()
                            for(t=0;t<teeth;t++){
                              a1=Math.PI*2/teeth*t-Math.PI/teeth*.5; a2=Math.PI*2/teeth*t+Math.PI/teeth*.5
                              ctx.lineTo(cx+or2*Math.cos(a1),cy+or2*Math.sin(a1))
                              ctx.lineTo(cx+tr*Math.cos(a1+Math.PI/teeth*.25),cy+tr*Math.sin(a1+Math.PI/teeth*.25))
                              ctx.lineTo(cx+tr*Math.cos(a2-Math.PI/teeth*.25),cy+tr*Math.sin(a2-Math.PI/teeth*.25))
                              ctx.lineTo(cx+or2*Math.cos(a2),cy+or2*Math.sin(a2))
                            }
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                            ctx.globalCompositeOperation="destination-out"
                            ctx.beginPath(); ctx.arc(cx,cy,ir,0,Math.PI*2); ctx.fillStyle="rgba(0,0,0,1)"; ctx.fill()
                            ctx.globalCompositeOperation="source-over"
                          }else if(sk==="windows"){
                            gap=s*.10; pw=(s-gap)*.86
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.55)"; ctx.strokeStyle=sa
                            ctx.beginPath(); ctx.rect(cx-pw-gap/2,cy-pw-gap/2,pw,pw); ctx.fill(); ctx.stroke()
                            ctx.beginPath(); ctx.rect(cx+gap/2,cy-pw-gap/2,pw,pw); ctx.fill(); ctx.stroke()
                            ctx.beginPath(); ctx.rect(cx-pw-gap/2,cy+gap/2,pw,pw); ctx.fill(); ctx.stroke()
                            ctx.beginPath(); ctx.rect(cx+gap/2,cy+gap/2,pw,pw); ctx.fill(); ctx.stroke()
                          }else if(sk==="chevron"){
                            ctx.lineWidth=s*.19; ctx.lineCap="square"; ctx.lineJoin="miter"; ctx.strokeStyle=sa
                            var offsets=[-s*.34,0,s*.34]
                            for(var c=0;c<3;c++){
                              var yo=offsets[c]
                              ctx.beginPath(); ctx.moveTo(cx-s*.80,cy+s*.40+yo); ctx.lineTo(cx,cy-s*.08+yo); ctx.lineTo(cx+s*.80,cy+s*.40+yo); ctx.stroke()
                            }
                          }else if(sk==="splat"){
                            ctx.beginPath()
                            var pts=14
                            for(i=0;i<pts;i++){
                              var ang=Math.PI*2/pts*i
                              var srad=i%2===0?s*(0.70+Math.sin(i*1.7)*.18):s*(0.38+Math.cos(i*2.3)*.12)
                              if(i===0)ctx.moveTo(cx+srad*Math.cos(ang),cy+srad*Math.sin(ang)); else ctx.lineTo(cx+srad*Math.cos(ang),cy+srad*Math.sin(ang))
                            }
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                          }else if(sk==="music"){
                            ctx.strokeStyle=sa; ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"
                            ctx.save(); ctx.translate(cx-s*.10, cy+s*.36); ctx.rotate(-0.40)
                            ctx.save(); ctx.scale(s*.30,s*.20); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore()
                            ctx.fill(); ctx.restore()
                            ctx.lineWidth=s*.11; ctx.lineCap="round"
                            ctx.beginPath(); ctx.moveTo(cx+s*.18,cy+s*.26); ctx.lineTo(cx+s*.18,cy-s*.68); ctx.stroke()
                            ctx.lineWidth=s*.09
                            ctx.beginPath()
                            ctx.moveTo(cx+s*.18, cy-s*.68)
                            ctx.bezierCurveTo(cx+s*.60,cy-s*.52, cx+s*.60,cy-s*.28, cx+s*.18,cy-s*.16)
                            ctx.stroke()
                          }else if(sk==="music2"){
                            ctx.strokeStyle=sa; ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"
                            var n1x=cx-s*.28, n2x=cx+s*.26, stemTop=cy-s*.70, stemBot=cy+s*.30
                            ctx.save(); ctx.translate(n1x-s*.08,stemBot); ctx.rotate(-0.38)
                            ctx.save(); ctx.scale(s*.26,s*.18); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            ctx.save(); ctx.translate(n2x-s*.08,stemBot); ctx.rotate(-0.38)
                            ctx.save(); ctx.scale(s*.26,s*.18); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            ctx.lineWidth=s*.10; ctx.lineCap="round"
                            ctx.beginPath(); ctx.moveTo(n1x,stemBot); ctx.lineTo(n1x,stemTop); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(n2x,stemBot); ctx.lineTo(n2x,stemTop); ctx.stroke()
                            ctx.lineWidth=s*.14
                            ctx.beginPath(); ctx.moveTo(n1x,stemTop); ctx.lineTo(n2x,stemTop); ctx.stroke()
                            ctx.lineWidth=s*.12
                            ctx.beginPath(); ctx.moveTo(n1x,stemTop+s*.17); ctx.lineTo(n2x,stemTop+s*.17); ctx.stroke()
                          }else if(sk==="cat"){
                            ctx.beginPath(); ctx.arc(cx,cy+s*.08,s*.70,0,Math.PI*2); ctx.fill(); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx-s*.50,cy-s*.40); ctx.lineTo(cx-s*.22,cy-s*.76); ctx.lineTo(cx-s*.06,cy-s*.36); ctx.closePath(); ctx.fillStyle="rgba("+r+","+g+","+b+",0.45)"; ctx.fill(); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx+s*.50,cy-s*.40); ctx.lineTo(cx+s*.22,cy-s*.76); ctx.lineTo(cx+s*.06,cy-s*.36); ctx.closePath(); ctx.fill(); ctx.stroke()
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"
                            ctx.save(); ctx.translate(cx-s*.26,cy-s*.04); ctx.save(); ctx.scale(s*.12,s*.15); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            ctx.save(); ctx.translate(cx+s*.26,cy-s*.04); ctx.save(); ctx.scale(s*.12,s*.15); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            ctx.beginPath(); ctx.moveTo(cx,cy+s*.18); ctx.lineTo(cx-s*.08,cy+s*.28); ctx.lineTo(cx+s*.08,cy+s*.28); ctx.closePath(); ctx.fillStyle="rgba("+r+","+g+","+b+",0.8)"; ctx.fill()
                            ctx.lineWidth=0.9; ctx.strokeStyle="rgba("+r+","+g+","+b+",0.65)"
                            ctx.beginPath(); ctx.moveTo(cx-s*.16,cy+s*.24); ctx.lineTo(cx-s*.76,cy+s*.18); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx-s*.16,cy+s*.30); ctx.lineTo(cx-s*.76,cy+s*.32); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx+s*.16,cy+s*.24); ctx.lineTo(cx+s*.76,cy+s*.18); ctx.stroke()
                            ctx.beginPath(); ctx.moveTo(cx+s*.16,cy+s*.30); ctx.lineTo(cx+s*.76,cy+s*.32); ctx.stroke()
                          }else if(sk==="bunny"){
                            ctx.beginPath(); ctx.arc(cx, cy+s*.22, s*.54, 0, Math.PI*2); ctx.fill(); ctx.stroke()
                            ctx.save(); ctx.translate(cx-s*.28, cy-s*.30); ctx.rotate(-0.14)
                            ctx.save(); ctx.scale(s*.20, s*.58); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.stroke(); ctx.restore()
                            ctx.save(); ctx.translate(cx+s*.28, cy-s*.30); ctx.rotate(0.14)
                            ctx.save(); ctx.scale(s*.20, s*.58); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.stroke(); ctx.restore()
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.28)"
                            ctx.save(); ctx.translate(cx-s*.28, cy-s*.30); ctx.rotate(-0.14)
                            ctx.save(); ctx.scale(s*.10, s*.42); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            ctx.save(); ctx.translate(cx+s*.28, cy-s*.30); ctx.rotate(0.14)
                            ctx.save(); ctx.scale(s*.10, s*.42); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"
                            ctx.save(); ctx.translate(cx-s*.20,cy+s*.12); ctx.save(); ctx.scale(s*.10,s*.12); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            ctx.save(); ctx.translate(cx+s*.20,cy+s*.12); ctx.save(); ctx.scale(s*.10,s*.12); ctx.beginPath(); ctx.arc(0,0,1,0,Math.PI*2); ctx.restore(); ctx.fill(); ctx.restore()
                            ctx.beginPath(); ctx.arc(cx, cy+s*.30, s*.06, 0, Math.PI*2); ctx.fill()
                          }else if(sk==="android"){
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.32)"; ctx.strokeStyle=sa; ctx.lineWidth=1.5
                            ctx.lineWidth=s*.09; ctx.lineCap="round"
                            ctx.beginPath(); ctx.moveTo(cx-s*.28,cy-s*.52); ctx.lineTo(cx-s*.48,cy-s*.88); ctx.stroke()
                            ctx.beginPath(); ctx.arc(cx-s*.48,cy-s*.88,s*.06,0,Math.PI*2); ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"; ctx.fill()
                            ctx.beginPath(); ctx.moveTo(cx+s*.28,cy-s*.52); ctx.lineTo(cx+s*.48,cy-s*.88); ctx.stroke()
                            ctx.beginPath(); ctx.arc(cx+s*.48,cy-s*.88,s*.06,0,Math.PI*2); ctx.fill()
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.32)"; ctx.lineWidth=1.5
                            var hr2=s*.16, hx=cx-s*.62, hy=cy-s*.52, hw=s*1.24, hh=s*.78
                            ctx.beginPath()
                            ctx.moveTo(hx+hr2,hy); ctx.lineTo(hx+hw-hr2,hy); ctx.arc(hx+hw-hr2,hy+hr2,hr2,-Math.PI/2,0)
                            ctx.lineTo(hx+hw,hy+hh-hr2); ctx.arc(hx+hw-hr2,hy+hh-hr2,hr2,0,Math.PI/2)
                            ctx.lineTo(hx+hr2,hy+hh); ctx.arc(hx+hr2,hy+hh-hr2,hr2,Math.PI/2,Math.PI)
                            ctx.lineTo(hx,hy+hr2); ctx.arc(hx+hr2,hy+hr2,hr2,Math.PI,Math.PI*1.5)
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.9)"
                            ctx.beginPath(); ctx.arc(cx-s*.24,cy-s*.20,s*.10,0,Math.PI*2); ctx.fill()
                            ctx.beginPath(); ctx.arc(cx+s*.24,cy-s*.20,s*.10,0,Math.PI*2); ctx.fill()
                            ctx.fillStyle="rgba("+r+","+g+","+b+",0.22)"; ctx.lineWidth=1.5
                            var bx2=cx-s*.55, by2=cy+s*.32, bw=s*1.10, bh=s*.60, br=s*.10
                            ctx.beginPath()
                            ctx.moveTo(bx2+br,by2); ctx.lineTo(bx2+bw-br,by2); ctx.arc(bx2+bw-br,by2+br,br,-Math.PI/2,0)
                            ctx.lineTo(bx2+bw,by2+bh-br); ctx.arc(bx2+bw-br,by2+bh-br,br,0,Math.PI/2)
                            ctx.lineTo(bx2+br,by2+bh); ctx.arc(bx2+br,by2+bh-br,br,Math.PI/2,Math.PI)
                            ctx.lineTo(bx2,by2+br); ctx.arc(bx2+br,by2+br,br,Math.PI,Math.PI*1.5)
                            ctx.closePath(); ctx.fill(); ctx.stroke()
                          }
                        }
                      }
                    }
                    Text {
                      text: modelData.nm
                      anchors.top: appShpBox.bottom; anchors.topMargin: vpx(1)
                      anchors.horizontalCenter: parent.horizontalCenter
                      font.pixelSize: vpx(7); color: sel ? root.accentHex : "#666666"
                      horizontalAlignment: Text.AlignHCenter
                    }
                    MouseArea {
                      anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: root.applyShapeToAllSlots(modelData.key)
                    }
                  }
                }
              }

              Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }

              // ── Profile Panel: Toggle Chips ─────────────────────────
              Item {
                width: parent.width; height: vpx(20)
                Rectangle { anchors.fill: parent; anchors.leftMargin: vpx(-2); radius: vpx(3); color: "#22FFFFFF" }
                StyledText { anchors.verticalCenter: parent.verticalCenter; text: "Panel Features"; font.pixelSize: vpx(12); font.bold: true; color: root.accentHex;
 }
              }
              Flow {
                width: parent.width; spacing: vpx(5)
                Repeater {
                  model: [
                    { label:"Vignette",    key:"cfg.profileVignette",    prop:"profileVignette"     },
                    { label:"Accent Glow", key:"cfg.profileAccentGrad",  prop:"profileAccentGradOn" },
                    { label:"Theme Glow",  key:"cfg.profileThemeGrad",   prop:"profileThemeGradOn"  },
                    { label:"Spotlight",   key:"cfg.profileSpotlight",   prop:"profileSpotlightOn"  },
                    { label:"Hide Bg",     key:"cfg.profileHideBg",      prop:"profileHideBg"       },
                    { label:"Gamerpic",    key:"cfg.profileGamerpic",    prop:"profileGamerpicOn"   },
                    { label:"Gamerscore",  key:"cfg.profileGamerscore",  prop:"profileGamerscoreOn" },
                    { label:"Gamertag",    key:"cfg.profileGamertag",    prop:"profileGamertagOn"   },
                    { label:"Borders",     key:"cfg.profileBorders",     prop:"profileBordersOn"    },
                    { label:"Stat Pills",  key:"cfg.profileStats",       prop:"profileStatsOn"      }
                  ]
                  delegate: Rectangle {
                    property bool chipOn: root[modelData.prop]
                    height: vpx(26); radius: vpx(13)
                    width: ppChipLbl.implicitWidth + vpx(22)
                    color: chipOn ? root.accentRgba(0.45) : root.accentRgba(0.10)
                    border.color: chipOn ? root.accentHex : root.accentRgba(0.30); border.width: vpx(1)

                    Row {
                      anchors.centerIn: parent; spacing: vpx(5)
                      Rectangle { width: vpx(7); height: vpx(7); radius: vpx(4); color: parent.parent.chipOn ? "#44FF44" : root.accentRgba(0.35); anchors.verticalCenter: parent.verticalCenter

                      }
                      StyledText { id: ppChipLbl; text: modelData.label; font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF";
 }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                      onClicked: { root[modelData.prop]=!root[modelData.prop]; api.memory.set(modelData.key,root[modelData.prop]?"true":"false") }
                    }
                  }
                }
              }

              Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }

              // ── Profile Panel: Sliders ───────────────────────────────
              Item {
                width: parent.width; height: vpx(20)
                Rectangle { anchors.fill: parent; anchors.leftMargin: vpx(-2); radius: vpx(3); color: "#22FFFFFF" }
                StyledText { anchors.verticalCenter: parent.verticalCenter; text: "Panel Levels"; font.pixelSize: vpx(12); font.bold: true; color: root.accentHex;
 }
              }

              Component {
                id: ppSliderCell
                Item {
                  property string lbl: ""; property string key: ""; property string prop: ""
                  Column {
                    anchors.fill: parent; spacing: vpx(2)
                    Row { spacing: vpx(4)
                      StyledText { text: lbl; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF";
 }
                      StyledText { text: prop !== "" ? Math.round(root[prop])+"%" : ""; font.pixelSize: vpx(11); color: root.accentHex; font.bold: true;
 }
                    }
                    Row {
                      width: parent.width; height: vpx(20); spacing: vpx(3)
                      Rectangle {
                        width: vpx(18); height: vpx(18); radius: vpx(9); anchors.verticalCenter: parent.verticalCenter
                        color: root.accentHex; border.color: root.accentRgba(0.55); border.width: vpx(1)
                        StyledText { anchors.centerIn: parent; text: "−"; font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                          onClicked:      { if(prop!==""){var v=Math.max(0,root[prop]-1); root[prop]=v; api.memory.set(key,v.toString())} }
                          onPressAndHold: { if(prop!==""){var v=Math.max(0,root[prop]-5); root[prop]=v; api.memory.set(key,v.toString())} }
                        }
                      }
                      Item {
                        width: parent.width-vpx(46); height: parent.height; anchors.verticalCenter: parent.verticalCenter
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: vpx(4); radius: vpx(2); color: root.accentRgba(0.22)
                          Rectangle { width: prop!==""?parent.width*(root[prop]/100):0; height: parent.height; radius: parent.radius; color: root.accentHex }
                        }
                        Rectangle {
                          width: vpx(12); height: vpx(12); radius: vpx(6); color: root.accentHex; border.color: "#FFFFFF"; border.width: vpx(2)
                          anchors.verticalCenter: parent.verticalCenter
                          x: prop!==""?Math.max(0,Math.min(parent.width-vpx(12),(root[prop]/100)*(parent.width-vpx(12)))):0

                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                          onClicked:        { if(prop!==""){var v=Math.max(0,Math.min(100,Math.round(mouseX/width*100))); root[prop]=v; api.memory.set(key,v.toString())} }
                          onPositionChanged:{ if(pressed&&prop!==""){var v=Math.max(0,Math.min(100,Math.round(mouseX/width*100))); root[prop]=v; api.memory.set(key,v.toString())} }
                        }
                      }
                      Rectangle {
                        width: vpx(18); height: vpx(18); radius: vpx(9); anchors.verticalCenter: parent.verticalCenter
                        color: root.accentHex; border.color: root.accentRgba(0.55); border.width: vpx(1)
                        StyledText { anchors.centerIn: parent; text: "+"; font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                          onClicked:      { if(prop!==""){var v=Math.min(100,root[prop]+1); root[prop]=v; api.memory.set(key,v.toString())} }
                          onPressAndHold: { if(prop!==""){var v=Math.min(100,root[prop]+5); root[prop]=v; api.memory.set(key,v.toString())} }
                        }
                      }
                    }
                  }
                }
              }

              // Slider row 1: Bg Opacity | Glow Color Mix | Accent Glow | Theme Glow
              Row {
                width: parent.width; height: vpx(38); spacing: vpx(4)
                Loader { sourceComponent: ppSliderCell; width: (parent.width-vpx(12))/4; height: parent.height; onLoaded: { item.lbl="Bg Opacity";      item.key="cfg.profileBgOpacity";    item.prop="profileBgOpacity"    } }
                Loader { sourceComponent: ppSliderCell; width: (parent.width-vpx(12))/4; height: parent.height; onLoaded: { item.lbl="Glow Mix";        item.key="cfg.profileGlowColorMix"; item.prop="profileGlowColorMix" } }
                Loader { sourceComponent: ppSliderCell; width: (parent.width-vpx(12))/4; height: parent.height; onLoaded: { item.lbl="Accent Glow";     item.key="cfg.accentGradAlpha";     item.prop="accentGradAlpha"     } }
                Loader { sourceComponent: ppSliderCell; width: (parent.width-vpx(12))/4; height: parent.height; onLoaded: { item.lbl="Theme Glow";      item.key="cfg.themeGradAlpha";      item.prop="themeGradAlpha"      } }
              }
              // Slider row 2: Panel Fill | Gradient Strength | Accent Transp | Accent Opacity
              Row {
                width: parent.width; height: vpx(38); spacing: vpx(4)
                Loader { sourceComponent: ppSliderCell; width: (parent.width-vpx(12))/4; height: parent.height; onLoaded: { item.lbl="Panel Fill";      item.key="cfg.panelBaseAlpha";      item.prop="panelBaseAlpha"      } }
                Loader { sourceComponent: ppSliderCell; width: (parent.width-vpx(12))/4; height: parent.height; onLoaded: { item.lbl="Grad Strength";   item.key="cfg.gradientStrength";    item.prop="gradientStrength"    } }
                Loader { sourceComponent: ppSliderCell; width: (parent.width-vpx(12))/4; height: parent.height; onLoaded: { item.lbl="Accent Transp";   item.key="cfg.accentTransparency";  item.prop="accentTransparency"  } }
                Loader { sourceComponent: ppSliderCell; width: (parent.width-vpx(12))/4; height: parent.height; onLoaded: { item.lbl="Accent Opacity";  item.key="cfg.accentOpacity";       item.prop="accentOpacity"       } }
              }
              // Slider row 3: Grad Transp | Grad Opacity | Shape Opacity | Shape Scale
              Row {
                width: parent.width; height: vpx(38); spacing: vpx(4)
                Loader { sourceComponent: ppSliderCell; width: (parent.width-vpx(12))/4; height: parent.height; onLoaded: { item.lbl="Grad Transp";    item.key="cfg.accentGradTransp";    item.prop="accentGradTransp"    } }
                Loader { sourceComponent: ppSliderCell; width: (parent.width-vpx(12))/4; height: parent.height; onLoaded: { item.lbl="Grad Opacity";    item.key="cfg.accentGradOpacity";   item.prop="accentGradOpacity"   } }
                Loader { sourceComponent: ppSliderCell; width: (parent.width-vpx(12))/4; height: parent.height; onLoaded: { item.lbl="Shape Opacity";   item.key="cfg.profileShapeOpacity"; item.prop="profileShapeOpacity" } }
                Loader { sourceComponent: ppSliderCell; width: (parent.width-vpx(12))/4; height: parent.height; onLoaded: { item.lbl="Shape Scale";     item.key="cfg.profileShapeScale";   item.prop="profileShapeScale"   } }
              }

                } // end ppBody Column
              } // end ppSection Item



            }
          }

          Image {
            source: "../../assets/images/system/up-default.png"
            width: vpx(22); height: vpx(18)
            anchors.top: parent.top; anchors.right: parent.right
            anchors.topMargin: vpx(2); anchors.rightMargin: vpx(2)
            fillMode: Image.PreserveAspectFit; asynchronous: true
            opacity: appearFlick.atYBeginning ? 0 : 0.8
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }
          Image {
            source: "../../assets/images/system/down-default.png"
            width: vpx(22); height: vpx(18)
            anchors.bottom: parent.bottom; anchors.right: parent.right
            anchors.bottomMargin: vpx(2); anchors.rightMargin: vpx(2)
            fillMode: Image.PreserveAspectFit; asynchronous: true
            opacity: appearFlick.atYEnd ? 0 : 0.8
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }
        }
      }
        } // end tab content wrapper
      Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.bottomMargin: vpx(22); height: vpx(1)
        color: root.accentRgba(0.20)
      }
      Text {
        anchors.left: parent.left; anchors.bottom: parent.bottom
        anchors.leftMargin: vpx(10); anchors.bottomMargin: vpx(8)
        text: "Profiles Manager"; font.pixelSize: vpx(9); color: "#555555"
      }
      // ── Accent border (4-sided) ───────────────────────────────
      Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: vpx(2); color: root.accentHex; opacity: 0.75; z: 10 }
      Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: vpx(2); color: root.accentHex; opacity: 0.75; z: 10 }
      Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: vpx(2); color: root.accentHex; opacity: 0.75; z: 10 }
      Rectangle { anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: vpx(2); color: root.accentHex; opacity: 0.75; z: 10 }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // PANEL 3 — AVATAR SCENE  (2× width)
  // ════════════════════════════════════════════════════════════════
  Component {
    id: avatarScenePanel

    Item {
      anchors.fill: parent
      property int slotNum: 0
      property int resolvedSlot: slotNum > 0 ? slotNum : root.signedInSlot
      property var sd: root.getSlot(resolvedSlot)
      property string pName:       sd ? (sd.name       || root.profileName)      : root.profileName
      property string pAvatar:     sd ? (sd.avatar     || root.profileAvatar)    : root.profileAvatar
      property string pGamerpic:   sd ? (sd.gamerpic   || root.profileGamerpic) : root.profileGamerpic
      property int    pGamerscore: sd ? (sd.gamerscore !== undefined ? sd.gamerscore : root.profileGamerscore) : root.profileGamerscore
      property string pSubStatus:  sd ? (sd.substatus  || root.profileSubStatus) : root.profileSubStatus
      property string pMotto:      sd ? (sd.motto      || root.profileMotto)     : root.profileMotto
      property string pBio:        sd ? (sd.bio        || root.profileBio)       : root.profileBio
      property string pRegion:     sd ? (sd.region     || root.profileRegion)    : root.profileRegion
      property string pColor:      sd ? (sd.color      || root.profileColor)     : root.profileColor
      // Refresh sd every 300ms since api.memory is not reactive
      Timer { interval: 300; running: true; repeat: true; onTriggered: { sd = root.getSlot(resolvedSlot) }}
      property string pAvatarUrl:  "../../assets/images/avatars/" + pAvatar
      property string pAccentHex:  pColor
      function pAccentRgba(a) { var h=(pColor && pColor.length===7) ? pColor : "#0099CC"; return Qt.rgba(parseInt(h.slice(1,3),16)/255,parseInt(h.slice(3,5),16)/255,parseInt(h.slice(5,7),16)/255,a) }

      property string pBorderTop:    api.memory.get("profile.slot." + resolvedSlot + ".borderTop")    || ""
      property string pBorderBottom: api.memory.get("profile.slot." + resolvedSlot + ".borderBottom") || ""
      Timer { interval: 300; running: true; repeat: true; onTriggered: {
        pBorderTop    = api.memory.get("profile.slot." + resolvedSlot + ".borderTop")    || ""
        pBorderBottom = api.memory.get("profile.slot." + resolvedSlot + ".borderBottom") || ""
      }}

      // Spotlight glow — uses saved accent colour
      RadialGradient {
        visible: root.avatarSpotlightOn
        anchors.fill: parent
        horizontalOffset: 0; verticalOffset: parent.height * 0.1
        gradient: Gradient {
          GradientStop { position: 0.0; color: pAccentRgba(0.15) }
          GradientStop { position: 0.6; color: pAccentRgba(0.04) }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }

      property string pShape:      sd ? (sd.shape || "circle") : root.profileShape

      // ── Animated scattered accent shapes ─────────────────────
      Item {
        visible: root.avatarShapesOn
        anchors.fill: parent; z: 1; clip: false

        Repeater {
          model: [
            // x%, y%, size%, alpha, filled, dur(ms), driftX%, driftY%, scaleEnd
            { xp:.50, yp:.46, sp:.68, a:.07, f:true,  dur:9000, dx:.00, dy:-.04, se:1.18 },
            { xp:.50, yp:.46, sp:.68, a:.26, f:false, dur:9000, dx:.00, dy:-.04, se:1.18 },
            { xp:.72, yp:.20, sp:.20, a:.18, f:false, dur:7000, dx:.04, dy:-.06, se:1.30 },
            { xp:.28, yp:.76, sp:.16, a:.14, f:true,  dur:8500, dx:-.03,dy:-.05, se:1.22 },
            { xp:.82, yp:.62, sp:.13, a:.20, f:false, dur:6500, dx:.05, dy:-.07, se:1.35 },
            { xp:.15, yp:.28, sp:.10, a:.16, f:true,  dur:7500, dx:-.04,dy:-.06, se:1.28 },
            { xp:.62, yp:.84, sp:.09, a:.22, f:false, dur:5800, dx:.03, dy:-.08, se:1.40 },
            { xp:.38, yp:.12, sp:.07, a:.12, f:true,  dur:9500, dx:-.02,dy:-.03, se:1.15 },
            { xp:.88, yp:.38, sp:.06, a:.18, f:false, dur:6200, dx:.06, dy:-.05, se:1.32 },
            { xp:.10, yp:.58, sp:.11, a:.10, f:true,  dur:8000, dx:-.05,dy:-.04, se:1.25 },
            { xp:.55, yp:.30, sp:.05, a:.15, f:false, dur:5500, dx:.02, dy:-.09, se:1.45 },
            { xp:.92, yp:.72, sp:.08, a:.12, f:true,  dur:7200, dx:.04, dy:-.06, se:1.30 },
            { xp:.22, yp:.88, sp:.14, a:.09, f:false, dur:8800, dx:-.03,dy:-.05, se:1.20 },
            { xp:.68, yp:.55, sp:.04, a:.20, f:true,  dur:5200, dx:.07, dy:-.10, se:1.50 },
            { xp:.35, yp:.42, sp:.17, a:.08, f:false, dur:9200, dx:-.04,dy:-.03, se:1.16 }
          ]
          delegate: Item {
            id: shapeDelegate
            property real bx: parent.width  * modelData.xp
            property real by: parent.height * modelData.yp
            property real bsize: Math.min(parent.width, parent.height) * modelData.sp
            property real endX: parent.width  * (modelData.xp + modelData.dx)
            property real endY: parent.height * (modelData.yp + modelData.dy)
            x: bx - bsize/2; y: by - bsize/2
            width: bsize; height: bsize
            opacity: modelData.a
            transformOrigin: Item.Center

            Canvas {
              anchors.fill: parent
              property string shapeType: pShape
              property string accentCol: pAccentHex
              onShapeTypeChanged: requestPaint(); onAccentColChanged: requestPaint()
              Component.onCompleted: Qt.callLater(requestPaint)
              onPaint: {
                var ctx=getContext("2d"); if(!ctx||width<=0||height<=0){Qt.callLater(requestPaint);return} ctx.clearRect(0,0,width,height)
                if(!accentCol || accentCol.length < 7) { Qt.callLater(requestPaint); return }
                var h=accentCol.replace("#",""); var r=parseInt(h.slice(0,2),16),g=parseInt(h.slice(2,4),16),b=parseInt(h.slice(4,6),16)
                var filled=modelData.f
                ctx.strokeStyle="rgba("+r+","+g+","+b+",1)"; ctx.fillStyle="rgba("+r+","+g+","+b+",1)"
                ctx.lineWidth=Math.max(1.5,width*.04); ctx.beginPath()
                var cx=width/2,cy=height/2,s=Math.min(width,height)/2-1
                var i,a,r2,starR,p,pa,px,py,gap,pw,t2,a1,a2,ir2,or3,offs,c2,spts,si,sang,srad
                if(shapeType==="circle"){ctx.arc(cx,cy,s,0,Math.PI*2)}
                else if(shapeType==="square"){ctx.rect(cx-s,cy-s,s*2,s*2)}
                else if(shapeType==="triangle"){ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.87,cy+s*.5);ctx.lineTo(cx-s*.87,cy+s*.5);ctx.closePath()}
                else if(shapeType==="diamond"){ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.65,cy);ctx.lineTo(cx,cy+s);ctx.lineTo(cx-s*.65,cy);ctx.closePath()}
                else if(shapeType==="hexagon"){for(i=0;i<6;i++){a=Math.PI/180*(60*i-30);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}ctx.closePath()}
                else if(shapeType==="octagon"){for(i=0;i<8;i++){a=Math.PI/180*(45*i);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}ctx.closePath()}
                else if(shapeType==="rectangle"){ctx.rect(cx-s,cy-s*.6,s*2,s*1.2)}
                else if(shapeType==="star"){for(i=0;i<10;i++){a=Math.PI/180*(36*i-90);starR=i%2===0?s:s*.45;if(i===0)ctx.moveTo(cx+starR*Math.cos(a),cy+starR*Math.sin(a));else ctx.lineTo(cx+starR*Math.cos(a),cy+starR*Math.sin(a))}ctx.closePath()}
                else if(shapeType==="flower"){for(p=0;p<6;p++){pa=Math.PI/180*(60*p);ctx.beginPath();ctx.arc(cx+s*.5*Math.cos(pa),cy+s*.5*Math.sin(pa),s*.42,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke()}ctx.beginPath();ctx.arc(cx,cy,s*.28,0,Math.PI*2);ctx.fill();return}
                else if(shapeType==="daisy"){var np3=10;for(p=0;p<np3;p++){pa=Math.PI*2/np3*p;ctx.save();ctx.translate(cx+s*.52*Math.cos(pa),cy+s*.52*Math.sin(pa));ctx.rotate(pa);ctx.beginPath();ctx.save();ctx.scale(s*.22,s*.42);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(filled)ctx.fill();else ctx.stroke();ctx.restore()}ctx.beginPath();ctx.arc(cx,cy,s*.28,0,Math.PI*2);ctx.fill();return}
                else if(shapeType==="orchid"){var upAo=[-Math.PI/2,-Math.PI/2-Math.PI*2/3,-Math.PI/2+Math.PI*2/3];for(p=0;p<3;p++){ctx.save();ctx.translate(cx+s*.42*Math.cos(upAo[p]),cy+s*.42*Math.sin(upAo[p]));ctx.rotate(upAo[p]+Math.PI/2);ctx.beginPath();ctx.save();ctx.scale(s*.25,s*.48);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(filled)ctx.fill();else ctx.stroke();ctx.restore()}var loAo=[Math.PI/2-Math.PI/5,Math.PI/2+Math.PI/5];for(p=0;p<2;p++){ctx.save();ctx.translate(cx+s*.45*Math.cos(loAo[p]),cy+s*.45*Math.sin(loAo[p]));ctx.rotate(loAo[p]+Math.PI/2);ctx.beginPath();ctx.save();ctx.scale(s*.32,s*.38);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(filled)ctx.fill();else ctx.stroke();ctx.restore()}ctx.beginPath();ctx.moveTo(cx,cy+s*.08);ctx.bezierCurveTo(cx-s*.55,cy+s*.22,cx-s*.45,cy+s*.82,cx,cy+s*.75);ctx.bezierCurveTo(cx+s*.45,cy+s*.82,cx+s*.55,cy+s*.22,cx,cy+s*.08);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.arc(cx,cy,s*.16,0,Math.PI*2);ctx.fill();return}
                else if(shapeType==="heart"){ctx.beginPath();ctx.moveTo(cx,cy+s*.80);ctx.bezierCurveTo(cx-s*.10,cy+s*.60,cx-s*.90,cy+s*.30,cx-s*.90,cy-s*.10);ctx.bezierCurveTo(cx-s*.90,cy-s*.55,cx-s*.50,cy-s*.80,cx,cy-s*.35);ctx.bezierCurveTo(cx+s*.50,cy-s*.80,cx+s*.90,cy-s*.55,cx+s*.90,cy-s*.10);ctx.bezierCurveTo(cx+s*.90,cy+s*.30,cx+s*.10,cy+s*.60,cx,cy+s*.80);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();return}
                else if(shapeType==="spade"){ctx.beginPath();ctx.moveTo(cx,cy-s*.78);ctx.bezierCurveTo(cx+s*.10,cy-s*.58,cx+s*.90,cy-s*.28,cx+s*.90,cy+s*.12);ctx.bezierCurveTo(cx+s*.90,cy+s*.54,cx+s*.50,cy+s*.76,cx,cy+s*.32);ctx.bezierCurveTo(cx-s*.50,cy+s*.76,cx-s*.90,cy+s*.54,cx-s*.90,cy+s*.12);ctx.bezierCurveTo(cx-s*.90,cy-s*.28,cx-s*.10,cy-s*.58,cx,cy-s*.78);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();ctx.lineWidth=Math.max(1.5,width*.04);ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx,cy+s*.32);ctx.lineTo(cx,cy+s*.78);ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.38,cy+s*.78);ctx.bezierCurveTo(cx-s*.12,cy+s*.58,cx+s*.12,cy+s*.58,cx+s*.38,cy+s*.78);ctx.stroke();return}
                else if(shapeType==="club"){var cPo=[{cx2:cx,cy2:cy-s*.38},{cx2:cx-s*.38,cy2:cy+s*.14},{cx2:cx+s*.38,cy2:cy+s*.14}];for(p=0;p<3;p++){ctx.beginPath();ctx.arc(cPo[p].cx2,cPo[p].cy2,s*.36,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke()}ctx.lineWidth=Math.max(1.5,width*.04)*1.5;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx,cy+s*.35);ctx.lineTo(cx,cy+s*.78);ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.42,cy+s*.78);ctx.lineTo(cx+s*.42,cy+s*.78);ctx.stroke();return}
                else if(shapeType==="cat"){ctx.beginPath();ctx.arc(cx,cy+s*.08,s*.72,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.52,cy-s*.42);ctx.lineTo(cx-s*.22,cy-s*.78);ctx.lineTo(cx-s*.06,cy-s*.38);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.52,cy-s*.42);ctx.lineTo(cx+s*.22,cy-s*.78);ctx.lineTo(cx+s*.06,cy-s*.38);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.save();ctx.translate(cx-s*.26,cy-s*.04);ctx.scale(s*.12,s*.16);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.beginPath();ctx.save();ctx.translate(cx+s*.26,cy-s*.04);ctx.scale(s*.12,s*.16);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();return}
                else if(shapeType==="bunny"){ctx.save();ctx.translate(cx-s*.26,cy-s*.28);ctx.rotate(-0.14);ctx.beginPath();ctx.save();ctx.scale(s*.20,s*.60);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(filled)ctx.fill();else ctx.stroke();ctx.restore();ctx.save();ctx.translate(cx+s*.26,cy-s*.28);ctx.rotate(0.14);ctx.beginPath();ctx.save();ctx.scale(s*.20,s*.60);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(filled)ctx.fill();else ctx.stroke();ctx.restore();ctx.beginPath();ctx.arc(cx,cy+s*.24,s*.54,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.arc(cx-s*.20,cy+s*.14,s*.09,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx+s*.20,cy+s*.14,s*.09,0,Math.PI*2);ctx.fill();return}
                else if(shapeType==="android"){ctx.lineWidth=Math.max(1.5,width*.04);ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx-s*.26,cy-s*.52);ctx.lineTo(cx-s*.46,cy-s*.88);ctx.stroke();ctx.beginPath();ctx.arc(cx-s*.46,cy-s*.88,s*.06,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.moveTo(cx+s*.26,cy-s*.52);ctx.lineTo(cx+s*.46,cy-s*.88);ctx.stroke();ctx.beginPath();ctx.arc(cx+s*.46,cy-s*.88,s*.06,0,Math.PI*2);ctx.fill();var hr2=s*.14,hx=cx-s*.60,hy=cy-s*.52,hw=s*1.20,hh=s*.76;ctx.beginPath();ctx.moveTo(hx+hr2,hy);ctx.lineTo(hx+hw-hr2,hy);ctx.arc(hx+hw-hr2,hy+hr2,hr2,-Math.PI/2,0);ctx.lineTo(hx+hw,hy+hh-hr2);ctx.arc(hx+hw-hr2,hy+hh-hr2,hr2,0,Math.PI/2);ctx.lineTo(hx+hr2,hy+hh);ctx.arc(hx+hr2,hy+hh-hr2,hr2,Math.PI/2,Math.PI);ctx.lineTo(hx,hy+hr2);ctx.arc(hx+hr2,hy+hr2,hr2,Math.PI,Math.PI*1.5);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.arc(cx-s*.24,cy-s*.22,s*.09,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx+s*.24,cy-s*.22,s*.09,0,Math.PI*2);ctx.fill();return}
                else if(shapeType==="cross_x"){ctx.lineWidth=s*.38;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx-s*.7,cy-s*.7);ctx.lineTo(cx+s*.7,cy+s*.7);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.7,cy-s*.7);ctx.lineTo(cx-s*.7,cy+s*.7);ctx.stroke();return}
                else if(shapeType==="windows"){gap=s*.08;pw=(s-gap)*.85;ctx.beginPath();ctx.rect(cx-pw-gap/2,cy-pw-gap/2,pw,pw);if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.rect(cx+gap/2,cy-pw-gap/2,pw,pw);if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.rect(cx-pw-gap/2,cy+gap/2,pw,pw);if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.rect(cx+gap/2,cy+gap/2,pw,pw);if(filled)ctx.fill();else ctx.stroke();return}
                else if(shapeType==="gear"){ir2=s*.45;or3=s*.75;for(t2=0;t2<10;t2++){a1=Math.PI*2/10*t2-Math.PI/10*.5;a2=Math.PI*2/10*t2+Math.PI/10*.5;ctx.lineTo(cx+or3*Math.cos(a1),cy+or3*Math.sin(a1));ctx.lineTo(cx+s*Math.cos(a1+Math.PI/10*.25),cy+s*Math.sin(a1+Math.PI/10*.25));ctx.lineTo(cx+s*Math.cos(a2-Math.PI/10*.25),cy+s*Math.sin(a2-Math.PI/10*.25));ctx.lineTo(cx+or3*Math.cos(a2),cy+or3*Math.sin(a2))}ctx.closePath();if(filled)ctx.fill();else ctx.stroke();ctx.globalCompositeOperation="destination-out";ctx.beginPath();ctx.arc(cx,cy,ir2,0,Math.PI*2);ctx.fillStyle="rgba(0,0,0,1)";ctx.fill();ctx.globalCompositeOperation="source-over";return}
                else if(shapeType==="chevron"){ctx.lineWidth=s*.22;ctx.lineCap="square";offs=[-s*.38,0,s*.38];for(c2=0;c2<3;c2++){ctx.beginPath();ctx.moveTo(cx-s*.85,cy+s*.45+offs[c2]);ctx.lineTo(cx,cy-s*.05+offs[c2]);ctx.lineTo(cx+s*.85,cy+s*.45+offs[c2]);ctx.stroke()}return}
                else if(shapeType==="splat"){for(si=0;si<14;si++){sang=Math.PI*2/14*si;srad=si%2===0?s*(0.7+Math.sin(si*1.7)*.18):s*(0.38+Math.cos(si*2.3)*.12);if(si===0)ctx.moveTo(cx+srad*Math.cos(sang),cy+srad*Math.sin(sang));else ctx.lineTo(cx+srad*Math.cos(sang),cy+srad*Math.sin(sang))}ctx.closePath()}
                else if(shapeType==="music"){ctx.lineWidth=s*.13;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx+s*.18,cy-s*.68);ctx.lineTo(cx+s*.18,cy+s*.28);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.18,cy-s*.68);ctx.bezierCurveTo(cx+s*.75,cy-s*.50,cx+s*.72,cy-s*.15,cx+s*.18,cy-s*.18);ctx.fill();ctx.stroke();ctx.save();ctx.translate(cx,cy+s*.42);ctx.rotate(-Math.PI/7);ctx.scale(1.4,0.82);ctx.beginPath();ctx.arc(0,0,s*.26,0,Math.PI*2);ctx.fill();ctx.restore();return}
                else if(shapeType==="music2"){ctx.lineWidth=s*.12;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx-s*.28,cy-s*.60);ctx.lineTo(cx-s*.28,cy+s*.28);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.28,cy-s*.60);ctx.lineTo(cx+s*.28,cy+s*.28);ctx.stroke();ctx.lineWidth=s*.14;ctx.beginPath();ctx.moveTo(cx-s*.28,cy-s*.60);ctx.lineTo(cx+s*.28,cy-s*.60);ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.28,cy-s*.40);ctx.lineTo(cx+s*.28,cy-s*.40);ctx.stroke();ctx.save();ctx.translate(cx-s*.28,cy+s*.44);ctx.rotate(-Math.PI/7);ctx.scale(1.4,0.82);ctx.beginPath();ctx.arc(0,0,s*.25,0,Math.PI*2);ctx.fill();ctx.restore();ctx.save();ctx.translate(cx+s*.28,cy+s*.44);ctx.rotate(-Math.PI/7);ctx.scale(1.4,0.82);ctx.beginPath();ctx.arc(0,0,s*.25,0,Math.PI*2);ctx.fill();ctx.restore();return}
                else if(shapeType==="plus"){var arm=s*.36;ctx.beginPath();ctx.moveTo(cx-arm,cy-s);ctx.lineTo(cx+arm,cy-s);ctx.lineTo(cx+arm,cy-arm);ctx.lineTo(cx+s,cy-arm);ctx.lineTo(cx+s,cy+arm);ctx.lineTo(cx+arm,cy+arm);ctx.lineTo(cx+arm,cy+s);ctx.lineTo(cx-arm,cy+s);ctx.lineTo(cx-arm,cy+arm);ctx.lineTo(cx-s,cy+arm);ctx.lineTo(cx-s,cy-arm);ctx.lineTo(cx-arm,cy-arm);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();return}
                else if(shapeType==="moon"){ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke();ctx.globalCompositeOperation="destination-out";ctx.beginPath();ctx.arc(cx+s*.40,cy-s*.20,s*.74,0,Math.PI*2);ctx.fillStyle="rgba(0,0,0,1)";ctx.fill();ctx.globalCompositeOperation="source-over";return}
                else if(shapeType==="waterdrop"){ctx.beginPath();ctx.moveTo(cx,cy-s*.92);ctx.bezierCurveTo(cx+s*.50,cy-s*.30,cx+s*.82,cy+s*.22,cx,cy+s*.92);ctx.bezierCurveTo(cx-s*.82,cy+s*.22,cx-s*.50,cy-s*.30,cx,cy-s*.92);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();return}
                else if(shapeType==="spiral"){ctx.lineWidth=Math.max(1.5,width*.04);ctx.lineCap="round";ctx.beginPath();var turns=3,steps=80;for(var si2=0;si2<=steps;si2++){var theta=turns*Math.PI*2*(si2/steps);var rad3=(s*.92)*(si2/steps);var sx2=cx+rad3*Math.cos(theta-Math.PI/2);var sy2=cy+rad3*Math.sin(theta-Math.PI/2);if(si2===0)ctx.moveTo(sx2,sy2);else ctx.lineTo(sx2,sy2)}ctx.stroke();return}
                else if(shapeType==="sparkle"){ctx.beginPath();for(var sp2=0;sp2<8;sp2++){var sa2=Math.PI/4*sp2-Math.PI/2;var rr2=sp2%2===0?s:s*.12;if(sp2===0)ctx.moveTo(cx+rr2*Math.cos(sa2),cy+rr2*Math.sin(sa2));else ctx.lineTo(cx+rr2*Math.cos(sa2),cy+rr2*Math.sin(sa2))}ctx.closePath();if(filled)ctx.fill();else ctx.stroke();return}
                else if(shapeType==="smile"){ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.arc(cx-s*.30,cy-s*.20,s*.11,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx+s*.30,cy-s*.20,s*.11,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx,cy+s*.10,s*.38,Math.PI*0.12,Math.PI*0.88);ctx.stroke();return}
                else if(shapeType==="hexagram"){ctx.beginPath();ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.87,cy+s*.5);ctx.lineTo(cx-s*.87,cy+s*.5);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.moveTo(cx,cy+s);ctx.lineTo(cx+s*.87,cy-s*.5);ctx.lineTo(cx-s*.87,cy-s*.5);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();return}
                else if(shapeType==="quatrefoil"){var qr2=s*.50,qd2=s*.36;var qpos2=[{x:cx,y:cy-qd2},{x:cx+qd2,y:cy},{x:cx,y:cy+qd2},{x:cx-qd2,y:cy}];for(p=0;p<4;p++){ctx.beginPath();ctx.arc(qpos2[p].x,qpos2[p].y,qr2,0,Math.PI*2);if(filled)ctx.fill();else ctx.stroke()};return}
                else if(shapeType==="triquetra"){ctx.lineWidth=s*.16;ctx.lineCap="round";ctx.lineJoin="round";var tr3=s*.66;for(p=0;p<3;p++){var ta=Math.PI*2/3*p-Math.PI/2;var tx2=cx+tr3*Math.cos(ta),ty2=cy+tr3*Math.sin(ta);ctx.save();ctx.translate(tx2,ty2);ctx.rotate(ta+Math.PI/2);ctx.beginPath();ctx.arc(0,0,tr3,Math.PI*0.62,Math.PI*1.38);ctx.stroke();ctx.restore()};return}
                if(filled)ctx.fill();else ctx.stroke()
              }
            }

            SequentialAnimation on x {
              loops: Animation.Infinite
              NumberAnimation { to: endX - bsize/2; duration: modelData.dur; easing.type: Easing.InOutSine }
              NumberAnimation { to: bx  - bsize/2; duration: modelData.dur; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
              loops: Animation.Infinite
              NumberAnimation { to: endY - bsize/2; duration: modelData.dur; easing.type: Easing.InOutSine }
              NumberAnimation { to: by  - bsize/2; duration: modelData.dur; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on scale {
              loops: Animation.Infinite
              NumberAnimation { to: modelData.se; duration: modelData.dur; easing.type: Easing.InOutSine }
              NumberAnimation { to: 1.0;          duration: modelData.dur; easing.type: Easing.InOutSine }
            }
          }
        }
      }

      Item {
        id: avatarClip
        visible: root.avatarAvatarOn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: vpx(18)
        anchors.bottom: parent.bottom; anchors.bottomMargin: vpx(20)
        width: parent.width * 0.56
        height: parent.height - vpx(30)
        clip: true
        z: 2

        Image {
          id: avatarFullImg
          source: pAvatarUrl
          fillMode: Image.PreserveAspectFit
          smooth: true; antialiasing: true
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          width: parent.width
          height: parent.height

          Behavior on source {
            SequentialAnimation {
              NumberAnimation { target: avatarFullImg; property: "opacity"; to: 0; duration: 160 }
              NumberAnimation { target: avatarFullImg; property: "opacity"; to: 1; duration: 280 }
            }
          }
        }
      }

      // ── Full-width title bar — sits above left/right columns ────
      Item {
        id: sceneTitleBar
        visible: root.avatarGamertagOn
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.leftMargin: vpx(14); anchors.rightMargin: vpx(14); anchors.topMargin: vpx(10)
        height: root.avatarGamertagOn ? (sceneTitleText.implicitHeight + vpx(12)) : 0
        z: 4

        // Left accent bar
        Rectangle {
          anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
          width: vpx(2); color: pAccentHex
        }
        StyledText {
          id: sceneTitleText
          anchors.left: parent.left; anchors.leftMargin: vpx(12)
          anchors.right: parent.right; anchors.rightMargin: vpx(8)
          anchors.top: parent.top; anchors.topMargin: vpx(4)
          text: pName; font.pixelSize: vpx(26); font.bold: true
          wrapMode: Text.NoWrap
          elide: Text.ElideRight
        }
        // Accent underline
        Rectangle {
          anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
          height: vpx(2); radius: vpx(1); color: pAccentHex; opacity: 0.7
        }
      }

      // ── Left info overlay — floats over avatar ────────────────
      Flickable {
        anchors.left: parent.left; anchors.top: sceneTitleBar.bottom; anchors.bottom: parent.bottom
        anchors.leftMargin: vpx(22); anchors.topMargin: vpx(10); anchors.bottomMargin: vpx(20)
        width: parent.width * 0.46
        contentHeight: leftInfoCol.implicitHeight
        clip: true; z: 3

      Column {
        id: leftInfoCol
        width: parent.width; spacing: vpx(8)

        // Gamerpic + membership pill (stacked) + score/motto
        Row {
          spacing: vpx(10); width: parent.width

          // Gamerpic with Xbox LIVE pill directly below it
          Column {
            visible: root.avatarGamerpicOn
            spacing: vpx(5); anchors.verticalCenter: parent.verticalCenter
            Rectangle {
              width: vpx(90); height: vpx(90); radius: vpx(6)
              color: "#18FFFFFF"; border.color: pAccentHex; border.width: vpx(2)
              Image {
                anchors.fill: parent; anchors.margins: vpx(2)
                source: pGamerpic !== "" ? pGamerpic : "../../assets/images/gamerpic/MissingGamerPic.png"
                fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true

              }
            }
            Rectangle {
              width: subStatusRow1.implicitWidth + vpx(16); height: vpx(20); radius: vpx(10)
              color: pAccentRgba(0.35); border.color: pAccentHex; border.width: vpx(1)

              Row {
                id: subStatusRow1; anchors.centerIn: parent; spacing: vpx(4)
                Rectangle { width: vpx(6); height: vpx(6); radius: vpx(3); color: "#44FF44"; anchors.verticalCenter: parent.verticalCenter }
                StyledText { text: pSubStatus; font.pixelSize: vpx(10); color: "#FFFFFF" }
              }
            }
          }

          // Score badge + motto
          Column {
            anchors.verticalCenter: parent.verticalCenter; spacing: vpx(5)
            width: parent.width - vpx(106)
            Rectangle {
              visible: root.avatarGamerscoreOn
              height: vpx(24); width: scoreBadge.implicitWidth + vpx(18); radius: vpx(12)
              color: pAccentRgba(0.25); border.color: pAccentHex; border.width: vpx(1)
              StyledText { id: scoreBadge; anchors.centerIn: parent; text: pGamerscore + " \u24AD"; font.pixelSize: vpx(13); color: pAccentHex;
 }
            }
            StyledText { visible: pMotto !== ""; text: "\"" + pMotto + "\""; font.pixelSize: vpx(11); font.italic: true; color: "#FFFFFF"; width: parent.width; wrapMode: Text.WordWrap;
 }
          }
        }

        StyledText { visible: pBio !== ""; text: pBio; font.pixelSize: vpx(11); color: "#FFFFFF"; width: parent.width; wrapMode: Text.WordWrap;
 }

        Item { height: vpx(4) }

        // Stat pills
        Column {
          visible: root.avatarStatsOn
          width: parent.width; spacing: vpx(5)
          Repeater {
              model: [
                { icon: "🗂", label: "Collections",  value: api.collections.count.toString() },
                { icon: "🎮", label: "Total Games",   value: api.allGames.count.toString() },
                { icon: "⭐", label: "Favorites",     value: listFavorites.games.count.toString() },
                { icon: "⏱", label: "Play Time",     value: Utils.formatPlayTime(root.totalPlayTime) },
                { icon: "🏆", label: "Most Played",   value: listPlayTime.games.count > 0 ? listPlayTime.games.get(0).title : "—" },
                { icon: "🕐", label: "Last Played",   value: listRecent.games.count   > 0 ? listRecent.games.get(0).title   : "—" },
                { icon: "📊", label: "Sessions",      value: listRecent.games.count + " tracked" },
                { icon: "🌍", label: "Region",        value: pRegion !== "" ? pRegion : "Not Set" }
              ]
              delegate: Item {
                width: parent.width; height: vpx(26)
                Rectangle {
                  anchors.left: parent.left
                  width: avatarPillRow.implicitWidth + vpx(16); height: vpx(26)
                  radius: vpx(13)
                  color: pAccentRgba(index % 2 === 0 ? 0.20 : 0.10)
                  border.color: pAccentRgba(index % 2 === 0 ? 0.55 : 0.30)
                  border.width: vpx(1)
                  Row {
                    id: avatarPillRow; anchors.centerIn: parent; spacing: vpx(5)
                    StyledText { text: modelData.icon;  font.pixelSize: vpx(11);
 }
                    StyledText { text: modelData.label; font.pixelSize: vpx(11); color: "#FFFFFF";
 }
                    StyledText { text: modelData.value; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF";
 }
                  }
                }
              }
            }
        }

      }
      } // Flickable

      // ── Accent border lines (left + right sides) ────────────
      Rectangle {
        visible: root.avatarBordersOn
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: vpx(2); color: pAccentHex; opacity: 0.75; z: 10
      }
      Rectangle {
        visible: root.avatarBordersOn
        anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: vpx(2); color: pAccentHex; opacity: 0.75; z: 10
      }

      // ── Top accent line + emoji border ───────────────────────
      Rectangle {
        visible: root.avatarBordersOn
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: vpx(2); color: pAccentHex; opacity: 0.75; z: 10
      }
      Item {
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.topMargin: vpx(2)
        height: vpx(20); z: 12
        visible: root.avatarBordersOn && pBorderTop !== ""
        Rectangle { anchors.fill: parent; color: pAccentHex; opacity: 0.12 }
        StyledText {
          anchors.centerIn: parent
          text: [pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop].join(" ")
          font.pixelSize: vpx(13); color: pAccentHex
          clip: true

          width: parent.width - vpx(8); horizontalAlignment: Text.AlignHCenter
        }
      }

      // ── Bottom accent line + emoji border ────────────────────
      Rectangle {
        visible: root.avatarBordersOn
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: vpx(2); color: pAccentHex; opacity: 0.75; z: 10
      }
      Item {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.bottomMargin: vpx(2)
        height: vpx(20); z: 12
        visible: root.avatarBordersOn && pBorderBottom !== ""
        Rectangle { anchors.fill: parent; color: pAccentHex; opacity: 0.18 }
        StyledText {
          anchors.centerIn: parent
          text: [pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom].join(" ")
          font.pixelSize: vpx(13); color: pAccentHex
          clip: true

          width: parent.width - vpx(8); horizontalAlignment: Text.AlignHCenter
        }
      }

      Text {
        anchors.left: parent.left; anchors.bottom: parent.bottom
        anchors.leftMargin: vpx(10); anchors.bottomMargin: vpx(26)
        text: "Profile " + (slotNum > 0 ? slotNum : root.signedInSlot)
        font.pixelSize: vpx(10); color: "#FFFFFF"; z: 11
      }

      // ── Latest Games — bottom right ───────────────────────────
      Item {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.rightMargin: vpx(12); anchors.bottomMargin: vpx(28)
        width: vpx(226); height: vpx(72)
        visible: root.avatarLatestGamesOn && api.memory.get("profile.slot." + resolvedSlot + ".showLatestGames") !== "false"
        ListView {
          anchors.fill: parent
          orientation: ListView.Horizontal
          spacing: vpx(5); clip: true; interactive: false
          cacheBuffer: 0
          model: listRecent.games
          delegate: Rectangle {
            width: vpx(72); height: vpx(72); radius: vpx(6)
            color: pAccentRgba(0.18)
            border.color: pAccentRgba(0.50); border.width: vpx(1)
            clip: true
            Image {
              anchors.fill: parent; anchors.margins: vpx(2)
              source: assets.tile || assets.logo || assets.poster || assets.boxFront || ""
              fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
            }
          }
        }
      }
    }
  }
  // ════════════════════════════════════════════════════════════════
  Component {
    id: profileCardPanel

    Item {
      anchors.fill: parent
      property int slotNum: 0
      // When slotNum is not explicitly set, always display the signed-in profile
      property int resolvedSlot: slotNum > 0 ? slotNum : root.signedInSlot
      property var sd: root.getSlot(resolvedSlot)
      property string pName:       sd ? (sd.name       || root.profileName)      : root.profileName
      property string pAvatar:     sd ? (sd.avatar     || root.profileAvatar)    : root.profileAvatar
      property string pGamerpic:   sd ? (sd.gamerpic   || root.profileGamerpic) : root.profileGamerpic
      property int    pGamerscore: sd ? (sd.gamerscore !== undefined ? sd.gamerscore : root.profileGamerscore) : root.profileGamerscore
      property string pSubStatus:  sd ? (sd.substatus  || root.profileSubStatus) : root.profileSubStatus
      property string pStatus:     sd ? (sd.status     || root.profileStatus)    : root.profileStatus
      property string pMotto:      sd ? (sd.motto      || root.profileMotto)     : root.profileMotto
      property string pBio:        sd ? (sd.bio        || root.profileBio)       : root.profileBio
      property string pRegion:     sd ? (sd.region     || root.profileRegion)    : root.profileRegion
      property string pColor:      sd ? (sd.color      || root.profileColor)     : root.profileColor
      property string pShape:      sd ? (sd.shape      || "circle")              : root.profileShape
      property string pThemeColor: api.memory.get("profile.themeColor") || ""
      Timer { interval: 300; running: true; repeat: true; onTriggered: {
        sd          = root.getSlot(resolvedSlot)
        pThemeColor = api.memory.get("profile.themeColor") || ""
      }}
      property string pAvatarUrl:  "../../assets/images/avatars/" + pAvatar
      property string pAccentHex:  pColor
      function pAccentRgba(a) { var h=(pColor && pColor.length===7) ? pColor : "#0099CC"; return Qt.rgba(parseInt(h.slice(1,3),16)/255,parseInt(h.slice(3,5),16)/255,parseInt(h.slice(5,7),16)/255,a) }
      function pThemeRgba(a) {
        var h = pThemeColor !== "" ? pThemeColor : "#000000"
        return Qt.rgba(parseInt(h.slice(1,3),16)/255,parseInt(h.slice(3,5),16)/255,parseInt(h.slice(5,7),16)/255,a)
      }
      property string pBorderTop:    slotNum > 0 ? (api.memory.get("profile.slot." + slotNum + ".borderTop")    || "") : (api.memory.get("profile.borderTop")    || "")
      property string pBorderBottom: slotNum > 0 ? (api.memory.get("profile.slot." + slotNum + ".borderBottom") || "") : (api.memory.get("profile.borderBottom") || "")
      Timer { interval: 300; running: true; repeat: true; onTriggered: {
        pBorderTop    = slotNum > 0 ? (api.memory.get("profile.slot." + slotNum + ".borderTop")    || "") : (api.memory.get("profile.borderTop")    || "")
        pBorderBottom = slotNum > 0 ? (api.memory.get("profile.slot." + slotNum + ".borderBottom") || "") : (api.memory.get("profile.borderBottom") || "")
      }}

      Rectangle { anchors.fill: parent; color: pThemeColor !== "" ? pThemeRgba(0.65) : "transparent"; z: 0 }

      RadialGradient {
        z: 1; anchors.fill: parent; horizontalOffset: -parent.width*.1; verticalOffset: parent.height*.1
        gradient: Gradient {
          GradientStop { position: 0.0; color: pAccentRgba(0.15) }
          GradientStop { position: 0.6; color: pAccentRgba(0.04) }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }

      // ── Full-panel animated shapes (z:1, behind avatar) ──────
      Item {
        anchors.fill: parent; z: 1; clip: false
        Repeater {
          model: [
            { xp:.50, yp:.48, sp:.80, a:.07, f:true,  dur:10000, dx:.00, dy:-.03, se:1.14 },
            { xp:.50, yp:.48, sp:.80, a:.24, f:false, dur:10000, dx:.00, dy:-.03, se:1.14 },
            { xp:.78, yp:.18, sp:.22, a:.16, f:false, dur:7200,  dx:.04, dy:-.06, se:1.32 },
            { xp:.22, yp:.80, sp:.18, a:.13, f:true,  dur:8800,  dx:-.03,dy:-.05, se:1.24 },
            { xp:.88, yp:.60, sp:.14, a:.19, f:false, dur:6600,  dx:.05, dy:-.07, se:1.36 },
            { xp:.10, yp:.25, sp:.11, a:.15, f:true,  dur:7800,  dx:-.04,dy:-.06, se:1.28 },
            { xp:.65, yp:.88, sp:.09, a:.20, f:false, dur:6000,  dx:.03, dy:-.08, se:1.42 },
            { xp:.92, yp:.38, sp:.06, a:.14, f:false, dur:5400,  dx:.06, dy:-.05, se:1.38 },
            { xp:.38, yp:.12, sp:.08, a:.12, f:true,  dur:9200,  dx:-.02,dy:-.04, se:1.18 },
            { xp:.72, yp:.70, sp:.05, a:.18, f:false, dur:5800,  dx:.03, dy:-.09, se:1.44 },
            { xp:.18, yp:.50, sp:.12, a:.10, f:true,  dur:8400,  dx:-.05,dy:-.03, se:1.22 }
          ]
          delegate: Item {
            property real bx:    parent.width  * modelData.xp
            property real by:    parent.height * modelData.yp
            property real bsize: Math.min(parent.width, parent.height) * modelData.sp
            property real endX:  parent.width  * (modelData.xp + modelData.dx)
            property real endY:  parent.height * (modelData.yp + modelData.dy)
            x: bx-bsize/2; y: by-bsize/2; width: bsize; height: bsize
            opacity: modelData.a; transformOrigin: Item.Center
            Canvas {
              anchors.fill: parent
              property string shapeType: pShape; property string accentCol: pAccentHex
              onShapeTypeChanged: requestPaint(); onAccentColChanged: requestPaint()
              Component.onCompleted: Qt.callLater(requestPaint)
              onPaint: {
                var ctx=getContext("2d"); if(!ctx||width<=0||height<=0){Qt.callLater(requestPaint);return} ctx.clearRect(0,0,width,height)
                if(!accentCol || accentCol.length < 7) { Qt.callLater(requestPaint); return }
                var h=accentCol.replace("#",""); var r=parseInt(h.slice(0,2),16),g=parseInt(h.slice(2,4),16),b=parseInt(h.slice(4,6),16)
                ctx.strokeStyle="rgba("+r+","+g+","+b+",1)"; ctx.fillStyle="rgba("+r+","+g+","+b+",1)"
                ctx.lineWidth=Math.max(1.5,width*.04); ctx.beginPath()
                var cx=width/2,cy=height/2,s=Math.min(width,height)/2-1
                var i,a,r2,starR,p,pa,px,py,gap,pw,t2,a1,a2,ir2,or3,offs,c2,spts,si,sang,srad
                if(shapeType==="circle"){ctx.arc(cx,cy,s,0,Math.PI*2)}
                else if(shapeType==="square"){ctx.rect(cx-s,cy-s,s*2,s*2)}
                else if(shapeType==="triangle"){ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.87,cy+s*.5);ctx.lineTo(cx-s*.87,cy+s*.5);ctx.closePath()}
                else if(shapeType==="diamond"){ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.65,cy);ctx.lineTo(cx,cy+s);ctx.lineTo(cx-s*.65,cy);ctx.closePath()}
                else if(shapeType==="hexagon"){for(i=0;i<6;i++){a=Math.PI/180*(60*i-30);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}ctx.closePath()}
                else if(shapeType==="octagon"){for(i=0;i<8;i++){a=Math.PI/180*(45*i);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}ctx.closePath()}
                else if(shapeType==="rectangle"){ctx.rect(cx-s,cy-s*.6,s*2,s*1.2)}
                else if(shapeType==="star"){for(i=0;i<10;i++){a=Math.PI/180*(36*i-90);starR=i%2===0?s:s*.45;if(i===0)ctx.moveTo(cx+starR*Math.cos(a),cy+starR*Math.sin(a));else ctx.lineTo(cx+starR*Math.cos(a),cy+starR*Math.sin(a))}ctx.closePath()}
                else if(shapeType==="flower"){for(p=0;p<6;p++){pa=Math.PI/180*(60*p);ctx.beginPath();ctx.arc(cx+s*.5*Math.cos(pa),cy+s*.5*Math.sin(pa),s*.42,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke()}ctx.beginPath();ctx.arc(cx,cy,s*.28,0,Math.PI*2);ctx.fill();return}
                else if(shapeType==="daisy"){var np4=10;for(p=0;p<np4;p++){pa=Math.PI*2/np4*p;ctx.save();ctx.translate(cx+s*.52*Math.cos(pa),cy+s*.52*Math.sin(pa));ctx.rotate(pa);ctx.beginPath();ctx.save();ctx.scale(s*.22,s*.42);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(modelData.f)ctx.fill();else ctx.stroke();ctx.restore()}ctx.beginPath();ctx.arc(cx,cy,s*.28,0,Math.PI*2);ctx.fill();return}
                else if(shapeType==="orchid"){var upAc=[-Math.PI/2,-Math.PI/2-Math.PI*2/3,-Math.PI/2+Math.PI*2/3];for(p=0;p<3;p++){ctx.save();ctx.translate(cx+s*.42*Math.cos(upAc[p]),cy+s*.42*Math.sin(upAc[p]));ctx.rotate(upAc[p]+Math.PI/2);ctx.beginPath();ctx.save();ctx.scale(s*.25,s*.48);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(modelData.f)ctx.fill();else ctx.stroke();ctx.restore()}var loAc=[Math.PI/2-Math.PI/5,Math.PI/2+Math.PI/5];for(p=0;p<2;p++){ctx.save();ctx.translate(cx+s*.45*Math.cos(loAc[p]),cy+s*.45*Math.sin(loAc[p]));ctx.rotate(loAc[p]+Math.PI/2);ctx.beginPath();ctx.save();ctx.scale(s*.32,s*.38);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(modelData.f)ctx.fill();else ctx.stroke();ctx.restore()}ctx.beginPath();ctx.moveTo(cx,cy+s*.08);ctx.bezierCurveTo(cx-s*.55,cy+s*.22,cx-s*.45,cy+s*.82,cx,cy+s*.75);ctx.bezierCurveTo(cx+s*.45,cy+s*.82,cx+s*.55,cy+s*.22,cx,cy+s*.08);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.arc(cx,cy,s*.16,0,Math.PI*2);ctx.fill();return}
                else if(shapeType==="heart"){ctx.beginPath();ctx.moveTo(cx,cy+s*.80);ctx.bezierCurveTo(cx-s*.10,cy+s*.60,cx-s*.90,cy+s*.30,cx-s*.90,cy-s*.10);ctx.bezierCurveTo(cx-s*.90,cy-s*.55,cx-s*.50,cy-s*.80,cx,cy-s*.35);ctx.bezierCurveTo(cx+s*.50,cy-s*.80,cx+s*.90,cy-s*.55,cx+s*.90,cy-s*.10);ctx.bezierCurveTo(cx+s*.90,cy+s*.30,cx+s*.10,cy+s*.60,cx,cy+s*.80);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();return}
                else if(shapeType==="spade"){ctx.beginPath();ctx.moveTo(cx,cy-s*.78);ctx.bezierCurveTo(cx+s*.10,cy-s*.58,cx+s*.90,cy-s*.28,cx+s*.90,cy+s*.12);ctx.bezierCurveTo(cx+s*.90,cy+s*.54,cx+s*.50,cy+s*.76,cx,cy+s*.32);ctx.bezierCurveTo(cx-s*.50,cy+s*.76,cx-s*.90,cy+s*.54,cx-s*.90,cy+s*.12);ctx.bezierCurveTo(cx-s*.90,cy-s*.28,cx-s*.10,cy-s*.58,cx,cy-s*.78);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();ctx.lineWidth=Math.max(1.5,width*.04);ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx,cy+s*.32);ctx.lineTo(cx,cy+s*.78);ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.38,cy+s*.78);ctx.bezierCurveTo(cx-s*.12,cy+s*.58,cx+s*.12,cy+s*.58,cx+s*.38,cy+s*.78);ctx.stroke();return}
                else if(shapeType==="club"){var cPc=[{cx2:cx,cy2:cy-s*.38},{cx2:cx-s*.38,cy2:cy+s*.14},{cx2:cx+s*.38,cy2:cy+s*.14}];for(p=0;p<3;p++){ctx.beginPath();ctx.arc(cPc[p].cx2,cPc[p].cy2,s*.36,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke()}ctx.lineWidth=Math.max(1.5,width*.04)*1.5;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx,cy+s*.35);ctx.lineTo(cx,cy+s*.78);ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.42,cy+s*.78);ctx.lineTo(cx+s*.42,cy+s*.78);ctx.stroke();return}
                else if(shapeType==="cat"){ctx.beginPath();ctx.arc(cx,cy+s*.08,s*.72,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.52,cy-s*.42);ctx.lineTo(cx-s*.22,cy-s*.78);ctx.lineTo(cx-s*.06,cy-s*.38);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.52,cy-s*.42);ctx.lineTo(cx+s*.22,cy-s*.78);ctx.lineTo(cx+s*.06,cy-s*.38);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.save();ctx.translate(cx-s*.26,cy-s*.04);ctx.scale(s*.12,s*.16);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.beginPath();ctx.save();ctx.translate(cx+s*.26,cy-s*.04);ctx.scale(s*.12,s*.16);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();return}
                else if(shapeType==="bunny"){ctx.save();ctx.translate(cx-s*.26,cy-s*.28);ctx.rotate(-0.14);ctx.beginPath();ctx.save();ctx.scale(s*.20,s*.60);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(modelData.f)ctx.fill();else ctx.stroke();ctx.restore();ctx.save();ctx.translate(cx+s*.26,cy-s*.28);ctx.rotate(0.14);ctx.beginPath();ctx.save();ctx.scale(s*.20,s*.60);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(modelData.f)ctx.fill();else ctx.stroke();ctx.restore();ctx.beginPath();ctx.arc(cx,cy+s*.24,s*.54,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.arc(cx-s*.20,cy+s*.14,s*.09,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx+s*.20,cy+s*.14,s*.09,0,Math.PI*2);ctx.fill();return}
                else if(shapeType==="android"){ctx.lineWidth=Math.max(1.5,width*.04);ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx-s*.26,cy-s*.52);ctx.lineTo(cx-s*.46,cy-s*.88);ctx.stroke();ctx.beginPath();ctx.arc(cx-s*.46,cy-s*.88,s*.06,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.moveTo(cx+s*.26,cy-s*.52);ctx.lineTo(cx+s*.46,cy-s*.88);ctx.stroke();ctx.beginPath();ctx.arc(cx+s*.46,cy-s*.88,s*.06,0,Math.PI*2);ctx.fill();var hr2=s*.14,hx=cx-s*.60,hy=cy-s*.52,hw=s*1.20,hh=s*.76;ctx.beginPath();ctx.moveTo(hx+hr2,hy);ctx.lineTo(hx+hw-hr2,hy);ctx.arc(hx+hw-hr2,hy+hr2,hr2,-Math.PI/2,0);ctx.lineTo(hx+hw,hy+hh-hr2);ctx.arc(hx+hw-hr2,hy+hh-hr2,hr2,0,Math.PI/2);ctx.lineTo(hx+hr2,hy+hh);ctx.arc(hx+hr2,hy+hh-hr2,hr2,Math.PI/2,Math.PI);ctx.lineTo(hx,hy+hr2);ctx.arc(hx+hr2,hy+hr2,hr2,Math.PI,Math.PI*1.5);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.arc(cx-s*.24,cy-s*.22,s*.09,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx+s*.24,cy-s*.22,s*.09,0,Math.PI*2);ctx.fill();return}
                else if(shapeType==="cross_x"){ctx.lineWidth=s*.38;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx-s*.7,cy-s*.7);ctx.lineTo(cx+s*.7,cy+s*.7);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.7,cy-s*.7);ctx.lineTo(cx-s*.7,cy+s*.7);ctx.stroke();return}
                else if(shapeType==="windows"){gap=s*.08;pw=(s-gap)*.85;ctx.beginPath();ctx.rect(cx-pw-gap/2,cy-pw-gap/2,pw,pw);if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.rect(cx+gap/2,cy-pw-gap/2,pw,pw);if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.rect(cx-pw-gap/2,cy+gap/2,pw,pw);if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.rect(cx+gap/2,cy+gap/2,pw,pw);if(modelData.f)ctx.fill();else ctx.stroke();return}
                else if(shapeType==="gear"){ir2=s*.45;or3=s*.75;for(t2=0;t2<10;t2++){a1=Math.PI*2/10*t2-Math.PI/10*.5;a2=Math.PI*2/10*t2+Math.PI/10*.5;ctx.lineTo(cx+or3*Math.cos(a1),cy+or3*Math.sin(a1));ctx.lineTo(cx+s*Math.cos(a1+Math.PI/10*.25),cy+s*Math.sin(a1+Math.PI/10*.25));ctx.lineTo(cx+s*Math.cos(a2-Math.PI/10*.25),cy+s*Math.sin(a2-Math.PI/10*.25));ctx.lineTo(cx+or3*Math.cos(a2),cy+or3*Math.sin(a2))}ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();ctx.globalCompositeOperation="destination-out";ctx.beginPath();ctx.arc(cx,cy,ir2,0,Math.PI*2);ctx.fillStyle="rgba(0,0,0,1)";ctx.fill();ctx.globalCompositeOperation="source-over";return}
                else if(shapeType==="chevron"){ctx.lineWidth=s*.22;ctx.lineCap="square";offs=[-s*.38,0,s*.38];for(c2=0;c2<3;c2++){ctx.beginPath();ctx.moveTo(cx-s*.85,cy+s*.45+offs[c2]);ctx.lineTo(cx,cy-s*.05+offs[c2]);ctx.lineTo(cx+s*.85,cy+s*.45+offs[c2]);ctx.stroke()}return}
                else if(shapeType==="splat"){for(si=0;si<14;si++){sang=Math.PI*2/14*si;srad=si%2===0?s*(0.7+Math.sin(si*1.7)*.18):s*(0.38+Math.cos(si*2.3)*.12);if(si===0)ctx.moveTo(cx+srad*Math.cos(sang),cy+srad*Math.sin(sang));else ctx.lineTo(cx+srad*Math.cos(sang),cy+srad*Math.sin(sang))}ctx.closePath()}
                else if(shapeType==="music"){ctx.lineWidth=s*.13;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx+s*.18,cy-s*.68);ctx.lineTo(cx+s*.18,cy+s*.28);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.18,cy-s*.68);ctx.bezierCurveTo(cx+s*.75,cy-s*.50,cx+s*.72,cy-s*.15,cx+s*.18,cy-s*.18);ctx.fill();ctx.stroke();ctx.save();ctx.translate(cx,cy+s*.42);ctx.rotate(-Math.PI/7);ctx.scale(1.4,0.82);ctx.beginPath();ctx.arc(0,0,s*.26,0,Math.PI*2);ctx.fill();ctx.restore();return}
                else if(shapeType==="music2"){ctx.lineWidth=s*.12;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx-s*.28,cy-s*.60);ctx.lineTo(cx-s*.28,cy+s*.28);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.28,cy-s*.60);ctx.lineTo(cx+s*.28,cy+s*.28);ctx.stroke();ctx.lineWidth=s*.14;ctx.beginPath();ctx.moveTo(cx-s*.28,cy-s*.60);ctx.lineTo(cx+s*.28,cy-s*.60);ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.28,cy-s*.40);ctx.lineTo(cx+s*.28,cy-s*.40);ctx.stroke();ctx.save();ctx.translate(cx-s*.28,cy+s*.44);ctx.rotate(-Math.PI/7);ctx.scale(1.4,0.82);ctx.beginPath();ctx.arc(0,0,s*.25,0,Math.PI*2);ctx.fill();ctx.restore();ctx.save();ctx.translate(cx+s*.28,cy+s*.44);ctx.rotate(-Math.PI/7);ctx.scale(1.4,0.82);ctx.beginPath();ctx.arc(0,0,s*.25,0,Math.PI*2);ctx.fill();ctx.restore();return}

                else if(shapeType==="plus"){var arm=s*.36;ctx.beginPath();ctx.moveTo(cx-arm,cy-s);ctx.lineTo(cx+arm,cy-s);ctx.lineTo(cx+arm,cy-arm);ctx.lineTo(cx+s,cy-arm);ctx.lineTo(cx+s,cy+arm);ctx.lineTo(cx+arm,cy+arm);ctx.lineTo(cx+arm,cy+s);ctx.lineTo(cx-arm,cy+s);ctx.lineTo(cx-arm,cy+arm);ctx.lineTo(cx-s,cy+arm);ctx.lineTo(cx-s,cy-arm);ctx.lineTo(cx-arm,cy-arm);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();return}
                else if(shapeType==="moon"){ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke();ctx.globalCompositeOperation="destination-out";ctx.beginPath();ctx.arc(cx+s*.40,cy-s*.20,s*.74,0,Math.PI*2);ctx.fillStyle="rgba(0,0,0,1)";ctx.fill();ctx.globalCompositeOperation="source-over";return}
                else if(shapeType==="waterdrop"){ctx.beginPath();ctx.moveTo(cx,cy-s*.92);ctx.bezierCurveTo(cx+s*.50,cy-s*.30,cx+s*.82,cy+s*.22,cx,cy+s*.92);ctx.bezierCurveTo(cx-s*.82,cy+s*.22,cx-s*.50,cy-s*.30,cx,cy-s*.92);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();return}
                else if(shapeType==="spiral"){ctx.lineWidth=Math.max(1.5,width*.04);ctx.lineCap="round";ctx.beginPath();var turns=3,steps=80;for(var si2=0;si2<=steps;si2++){var theta=turns*Math.PI*2*(si2/steps);var rad3=(s*.92)*(si2/steps);var sx2=cx+rad3*Math.cos(theta-Math.PI/2);var sy2=cy+rad3*Math.sin(theta-Math.PI/2);if(si2===0)ctx.moveTo(sx2,sy2);else ctx.lineTo(sx2,sy2)}ctx.stroke();return}
                else if(shapeType==="sparkle"){ctx.beginPath();for(var sp2=0;sp2<8;sp2++){var sa2=Math.PI/4*sp2-Math.PI/2;var rr2=sp2%2===0?s:s*.12;if(sp2===0)ctx.moveTo(cx+rr2*Math.cos(sa2),cy+rr2*Math.sin(sa2));else ctx.lineTo(cx+rr2*Math.cos(sa2),cy+rr2*Math.sin(sa2))}ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();return}
                else if(shapeType==="smile"){ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke();ctx.fillStyle="rgba("+r+","+g+","+b+",1)";ctx.beginPath();ctx.arc(cx-s*.30,cy-s*.20,s*.11,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx+s*.30,cy-s*.20,s*.11,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx,cy+s*.10,s*.38,Math.PI*0.12,Math.PI*0.88);ctx.stroke();return}
                else if(shapeType==="hexagram"){ctx.beginPath();ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.87,cy+s*.5);ctx.lineTo(cx-s*.87,cy+s*.5);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.moveTo(cx,cy+s);ctx.lineTo(cx+s*.87,cy-s*.5);ctx.lineTo(cx-s*.87,cy-s*.5);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();return}
                else if(shapeType==="quatrefoil"){var qr2=s*.50,qd2=s*.36;var qpos2=[{x:cx,y:cy-qd2},{x:cx+qd2,y:cy},{x:cx,y:cy+qd2},{x:cx-qd2,y:cy}];for(p=0;p<4;p++){ctx.beginPath();ctx.arc(qpos2[p].x,qpos2[p].y,qr2,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke()};return}
                else if(shapeType==="triquetra"){ctx.lineWidth=s*.16;ctx.lineCap="round";ctx.lineJoin="round";var tr3=s*.66;for(p=0;p<3;p++){var ta=Math.PI*2/3*p-Math.PI/2;var tx2=cx+tr3*Math.cos(ta),ty2=cy+tr3*Math.sin(ta);ctx.save();ctx.translate(tx2,ty2);ctx.rotate(ta+Math.PI/2);ctx.beginPath();ctx.arc(0,0,tr3,Math.PI*0.62,Math.PI*1.38);ctx.stroke();ctx.restore()};return}
                if(modelData.f)ctx.fill();else ctx.stroke()
              }
            }
            SequentialAnimation on x { loops: Animation.Infinite
              NumberAnimation { to: endX-bsize/2; duration: modelData.dur; easing.type: Easing.InOutSine }
              NumberAnimation { to: bx-bsize/2;   duration: modelData.dur; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y { loops: Animation.Infinite
              NumberAnimation { to: endY-bsize/2; duration: modelData.dur; easing.type: Easing.InOutSine }
              NumberAnimation { to: by-bsize/2;   duration: modelData.dur; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on scale { loops: Animation.Infinite
              NumberAnimation { to: modelData.se; duration: modelData.dur; easing.type: Easing.InOutSine }
              NumberAnimation { to: 1.0;          duration: modelData.dur; easing.type: Easing.InOutSine }
            }
          }
        }
      }

      // ── Avatar — left 54% of panel (z:2) ─────────────────────────
      Item {
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: parent.width * 0.54; z: 2
        Image {
          id: cardAvatarImg
          source: "../../assets/images/avatars/" + pAvatar
          fillMode: Image.PreserveAspectFit
          smooth: true; antialiasing: true
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width
          height: parent.height * 1.05
          Behavior on source {
            SequentialAnimation {
              NumberAnimation { target: cardAvatarImg; property: "opacity"; to: 0; duration: 160 }
              NumberAnimation { target: cardAvatarImg; property: "opacity"; to: 1; duration: 280 }
            }
          }
        }
      }

      // ── Info overlay — right 46% of panel (z:3) ──────────────────
      Rectangle {
        anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: parent.width * 0.46; z: 3
        color: "#CC0A0A0A"

        // Subtle left-edge accent line
        Rectangle {
          anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
          width: vpx(3); color: pAccentHex; opacity: 0.7
        }

        Column {
          anchors.fill: parent
          anchors.leftMargin: vpx(14); anchors.rightMargin: vpx(12)
          anchors.topMargin: vpx(16); anchors.bottomMargin: vpx(12)
          spacing: vpx(0)

          // Header — accent bar + Gamer Tag
          Item {
            width: parent.width; height: vpx(36)
            Rectangle { width: vpx(2); height: parent.height; color: pAccentHex; anchors.verticalCenter: parent.verticalCenter }
            StyledText {
              x: vpx(10)
              width: parent.width - vpx(10)
              anchors.verticalCenter: parent.verticalCenter
              text: pName; font.pixelSize: vpx(16); font.bold: true
              elide: Text.ElideRight
            }
          }

          Rectangle { width: parent.width; height: vpx(1); color: pAccentRgba(0.5) }
          Item { height: vpx(6); width: 1 }

          // Score badge
          Rectangle {
            height: vpx(20); width: gcBadge.implicitWidth + vpx(14); radius: vpx(10)
            color: pAccentRgba(0.28); border.color: pAccentHex; border.width: vpx(1)
            StyledText { id: gcBadge; anchors.centerIn: parent; text: pGamerscore + " \u24AD  •  " + pSubStatus; font.pixelSize: vpx(13); color: pAccentHex }
          }
          Item { height: vpx(6); width: 1 }
          Rectangle { width: parent.width; height: vpx(1); color: pAccentRgba(0.25) }
          Item { height: vpx(6); width: 1 }

          // Pills — accent-colored, left-aligned, one per row
          Column {
            width: parent.width; spacing: vpx(5)
            Repeater {
              model: [
                { icon: "🗂", label: "Collections",  value: api.collections.count.toString() },
                { icon: "🎮", label: "Total Games",   value: api.allGames.count.toString() },
                { icon: "⭐", label: "Favorites",     value: listFavorites.games.count.toString() },
                { icon: "⏱", label: "Play Time",     value: Utils.formatPlayTime(root.totalPlayTime) },
                { icon: "🏆", label: "Most Played",   value: listPlayTime.games.count > 0 ? listPlayTime.games.get(0).title : "—" },
                { icon: "🕐", label: "Last Played",   value: listRecent.games.count   > 0 ? listRecent.games.get(0).title   : "—" },
                { icon: "📊", label: "Sessions",      value: listRecent.games.count + " tracked" },
                { icon: "🌍", label: "Region",        value: pRegion !== "" ? pRegion : "Not Set" }
              ]
              delegate: Item {
                width: parent.width; height: vpx(26)
                Rectangle {
                  anchors.left: parent.left
                  width: pcPillRow.implicitWidth + vpx(16); height: vpx(26)
                  radius: vpx(13)
                  color: pAccentRgba(index % 2 === 0 ? 0.20 : 0.10)
                  border.color: pAccentRgba(index % 2 === 0 ? 0.55 : 0.30)
                  border.width: vpx(1)
                  Row {
                    id: pcPillRow; anchors.centerIn: parent; spacing: vpx(5)
                    StyledText { text: modelData.icon;  font.pixelSize: vpx(11) }
                    StyledText { text: modelData.label; font.pixelSize: vpx(13); color: pAccentHex; opacity: 0.80 }
                    StyledText { text: modelData.value; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF" }
                  }
                }
              }
            }
          }

          StyledText {
            visible: pMotto !== ""
            topPadding: vpx(6)
            text: "\"" + pMotto + "\""
            font.pixelSize: vpx(10); font.italic: true; color: "#FFFFFF"
            layer.enabled: false; width: parent.width; wrapMode: Text.WordWrap
          }

          // ── Latest Games strip ─────────────────────────────────
          Item {
            property bool showLatest: api.memory.get("profile.slot." + resolvedSlot + ".showLatestGames") !== "false"
            Timer { interval: 500; running: true; repeat: true; onTriggered: parent.showLatest = api.memory.get("profile.slot." + resolvedSlot + ".showLatestGames") !== "false" }
            visible: showLatest
            width: parent.width
            height: vpx(70)

            Column {
              anchors.fill: parent; spacing: vpx(4)
              topPadding: vpx(6)

              Rectangle { width: parent.width; height: vpx(1); color: pAccentRgba(0.30) }

              StyledText {
                text: "Latest Games"
                font.pixelSize: vpx(10); font.bold: true; color: pAccentHex; opacity: 0.85
                layer.enabled: false
              }

              ListView {
                id: profileLatestGamesList
                orientation: ListView.Horizontal
                width: parent.width
                height: vpx(44)
                spacing: vpx(6)
                clip: true
                model: listRecent.games
                delegate: Item {
                  width: vpx(40); height: vpx(40)
                  Rectangle {
                    anchors.fill: parent; radius: vpx(4)
                    color: pAccentRgba(0.18)
                    border.color: pAccentRgba(0.40); border.width: vpx(1)
                    clip: true
                    Image {
                      anchors.fill: parent; anchors.margins: vpx(2)
                      source: assets.tile || assets.logo || assets.poster || assets.boxFront || ""
                      fillMode: Image.PreserveAspectFit
                      smooth: true; asynchronous: true
                    }
                  }
                }
              }
            }
          }
        }
      }
      // ── Top emoji border line ────────────────────────────────
      Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: vpx(2); color: pAccentHex; opacity: 0.75; z: 10
      }
      Item {
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.topMargin: vpx(2)
        height: vpx(18); z: 12
        visible: pBorderTop !== ""
        Rectangle { anchors.fill: parent; color: pAccentHex; opacity: 0.10 }
        StyledText {
          anchors.centerIn: parent
          text: [pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop].join(" ")
          font.pixelSize: vpx(13); color: pAccentHex
          layer.enabled: false; clip: true
          width: parent.width - vpx(8); horizontalAlignment: Text.AlignHCenter
        }
      }

      // ── Bottom emoji border strip (right side, under info overlay) ──
      Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: vpx(2); color: pAccentHex; opacity: 0.75; z: 10
      }
      Item {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        width: parent.width * 0.46; height: vpx(18); z: 12
        visible: pBorderBottom !== ""
        Rectangle { anchors.fill: parent; color: pAccentHex; opacity: 0.18 }
        Rectangle {
          anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
          height: vpx(2); color: pAccentHex; opacity: 0.75
        }
        StyledText {
          anchors.centerIn: parent
          text: [pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom].join(" ")
          font.pixelSize: vpx(13); color: pAccentHex
          layer.enabled: false; clip: true
          width: parent.width - vpx(8); horizontalAlignment: Text.AlignHCenter
        }
      }

      Text {
        anchors.left: parent.left; anchors.bottom: parent.bottom
        anchors.leftMargin: vpx(10); anchors.bottomMargin: vpx(8)
        text: "Profile Card Panel"; font.pixelSize: vpx(10); color: "#FFFFFF"
      }
    }
  }
  // ════════════════════════════════════════════════════════════════
  Component {
    id: profileInfoCardPanel

    Item {
      anchors.fill: parent
      property int slotNum: 0
      property int resolvedSlot: slotNum > 0 ? slotNum : root.signedInSlot
      property var sd: root.getSlot(resolvedSlot)
      property string pName:       sd ? (sd.name       || root.profileName)      : root.profileName
      property string pAvatar:     sd ? (sd.avatar     || root.profileAvatar)    : root.profileAvatar
      property string pGamerpic:   sd ? (sd.gamerpic   || root.profileGamerpic) : root.profileGamerpic
      property int    pGamerscore: sd ? (sd.gamerscore !== undefined ? sd.gamerscore : root.profileGamerscore) : root.profileGamerscore
      property string pSubStatus:  sd ? (sd.substatus  || root.profileSubStatus) : root.profileSubStatus
      property string pStatus:     sd ? (sd.status     || root.profileStatus)    : root.profileStatus
      property string pMotto:      sd ? (sd.motto      || root.profileMotto)     : root.profileMotto
      property string pBio:        sd ? (sd.bio        || root.profileBio)       : root.profileBio
      property string pRegion:     sd ? (sd.region     || root.profileRegion)    : root.profileRegion
      property string pColor:      sd ? (sd.color      || root.profileColor)     : root.profileColor
      property string pShape:      sd ? (sd.shape      || root.profileShape || "circle") : (root.profileShape || "circle")
      property string pThemeColor: api.memory.get("profile.themeColor") || ""
      Timer { interval: 300; running: true; repeat: true; onTriggered: {
        sd          = root.getSlot(resolvedSlot)
        pThemeColor = api.memory.get("profile.themeColor") || ""
      }}
      property string pAvatarUrl:  "../../assets/images/avatars/" + pAvatar
      property string pAccentHex:  pColor
      function pAccentRgba(a) { var h=(pColor && pColor.length===7) ? pColor : "#0099CC"; return Qt.rgba(parseInt(h.slice(1,3),16)/255,parseInt(h.slice(3,5),16)/255,parseInt(h.slice(5,7),16)/255,a) }
      function pThemeRgba(a) {
        var h = pThemeColor !== "" ? pThemeColor : "#000000"
        return Qt.rgba(parseInt(h.slice(1,3),16)/255,parseInt(h.slice(3,5),16)/255,parseInt(h.slice(5,7),16)/255,a)
      }
      property string pBorderTop:    api.memory.get("profile.slot." + resolvedSlot + ".borderTop")    || ""
      property string pBorderBottom: api.memory.get("profile.slot." + resolvedSlot + ".borderBottom") || ""
      Timer { interval: 300; running: true; repeat: true; onTriggered: {
        pBorderTop    = api.memory.get("profile.slot." + resolvedSlot + ".borderTop")    || ""
        pBorderBottom = api.memory.get("profile.slot." + resolvedSlot + ".borderBottom") || ""
      }}

      Rectangle { anchors.fill: parent; color: pThemeColor !== "" ? pThemeRgba(0.65) : "transparent"; z: 0 }

      RadialGradient {
        z: 1; anchors.fill: parent; horizontalOffset: -parent.width*.1; verticalOffset: parent.height*.1
        gradient: Gradient {
          GradientStop { position: 0.0; color: pAccentRgba(0.15) }
          GradientStop { position: 0.6; color: pAccentRgba(0.04) }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }

      // Left half: avatar + animated shapes
      Item {
        id: infoCardAvatarHalf; anchors.left: parent.left; anchors.top: parent.top
        anchors.bottom: parent.bottom; width: parent.width * 0.52

        Item {
          anchors.fill: parent; z: 1; clip: false
          Repeater {
            model: [
              { xp:.50, yp:.50, sp:.78, a:.07, f:true,  dur:9500, dx:.00, dy:-.03, se:1.15 },
              { xp:.50, yp:.50, sp:.78, a:.24, f:false, dur:9500, dx:.00, dy:-.03, se:1.15 },
              { xp:.76, yp:.20, sp:.17, a:.17, f:false, dur:7400, dx:.04, dy:-.06, se:1.30 },
              { xp:.24, yp:.78, sp:.14, a:.14, f:true,  dur:8600, dx:-.03,dy:-.05, se:1.22 },
              { xp:.83, yp:.65, sp:.10, a:.20, f:false, dur:6800, dx:.05, dy:-.07, se:1.34 },
              { xp:.16, yp:.30, sp:.08, a:.15, f:true,  dur:7600, dx:-.04,dy:-.06, se:1.26 },
              { xp:.63, yp:.84, sp:.07, a:.20, f:false, dur:5900, dx:.03, dy:-.08, se:1.40 },
              { xp:.88, yp:.44, sp:.05, a:.14, f:false, dur:5600, dx:.06, dy:-.05, se:1.36 }
            ]
            delegate: Item {
              property real bx: parent.width  * modelData.xp
              property real by: parent.height * modelData.yp
              property real bsize: Math.min(parent.width, parent.height) * modelData.sp
              property real endX: parent.width  * (modelData.xp + modelData.dx)
              property real endY: parent.height * (modelData.yp + modelData.dy)
              x: bx-bsize/2; y: by-bsize/2; width: bsize; height: bsize
              opacity: modelData.a; transformOrigin: Item.Center
              Canvas {
                anchors.fill: parent
                property string shapeType: pShape; property string accentCol: pAccentHex
                onShapeTypeChanged: requestPaint(); onAccentColChanged: requestPaint()
                Component.onCompleted: Qt.callLater(requestPaint)
                onPaint: {
                  var ctx=getContext("2d"); if(!ctx||width<=0||height<=0){Qt.callLater(requestPaint);return} ctx.clearRect(0,0,width,height)
                  if(!accentCol || accentCol.length < 7) { Qt.callLater(requestPaint); return }
                  var h=accentCol.replace("#",""); var r=parseInt(h.slice(0,2),16),g=parseInt(h.slice(2,4),16),b=parseInt(h.slice(4,6),16)
                  ctx.strokeStyle="rgba("+r+","+g+","+b+",1)"; ctx.fillStyle="rgba("+r+","+g+","+b+",1)"
                  ctx.lineWidth=Math.max(1.5,width*.04); ctx.beginPath()
                  var cx=width/2,cy=height/2,s=Math.min(width,height)/2-1
                  var i,a,r2,starR,p,pa,px,py,gap,pw,t2,a1,a2,ir2,or3,offs,c2,spts,si,sang,srad
                  if(shapeType==="circle"){ctx.arc(cx,cy,s,0,Math.PI*2)}
                  else if(shapeType==="square"){ctx.rect(cx-s,cy-s,s*2,s*2)}
                  else if(shapeType==="triangle"){ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.87,cy+s*.5);ctx.lineTo(cx-s*.87,cy+s*.5);ctx.closePath()}
                  else if(shapeType==="diamond"){ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.65,cy);ctx.lineTo(cx,cy+s);ctx.lineTo(cx-s*.65,cy);ctx.closePath()}
                  else if(shapeType==="hexagon"){for(i=0;i<6;i++){a=Math.PI/180*(60*i-30);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}ctx.closePath()}
                  else if(shapeType==="octagon"){for(i=0;i<8;i++){a=Math.PI/180*(45*i);if(i===0)ctx.moveTo(cx+s*Math.cos(a),cy+s*Math.sin(a));else ctx.lineTo(cx+s*Math.cos(a),cy+s*Math.sin(a))}ctx.closePath()}
                  else if(shapeType==="rectangle"){ctx.rect(cx-s,cy-s*.6,s*2,s*1.2)}
                  else if(shapeType==="star"){for(i=0;i<10;i++){a=Math.PI/180*(36*i-90);starR=i%2===0?s:s*.45;if(i===0)ctx.moveTo(cx+starR*Math.cos(a),cy+starR*Math.sin(a));else ctx.lineTo(cx+starR*Math.cos(a),cy+starR*Math.sin(a))}ctx.closePath()}
                  else if(shapeType==="flower"){for(p=0;p<6;p++){pa=Math.PI/180*(60*p);ctx.beginPath();ctx.arc(cx+s*.5*Math.cos(pa),cy+s*.5*Math.sin(pa),s*.42,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke()}ctx.beginPath();ctx.arc(cx,cy,s*.28,0,Math.PI*2);ctx.fill();return}
                  else if(shapeType==="heart"){ctx.beginPath();ctx.moveTo(cx,cy+s*.80);ctx.bezierCurveTo(cx-s*.10,cy+s*.60,cx-s*.90,cy+s*.30,cx-s*.90,cy-s*.10);ctx.bezierCurveTo(cx-s*.90,cy-s*.55,cx-s*.50,cy-s*.80,cx,cy-s*.35);ctx.bezierCurveTo(cx+s*.50,cy-s*.80,cx+s*.90,cy-s*.55,cx+s*.90,cy-s*.10);ctx.bezierCurveTo(cx+s*.90,cy+s*.30,cx+s*.10,cy+s*.60,cx,cy+s*.80);ctx.closePath();if(filled)ctx.fill();else ctx.stroke();return}
                  else if(shapeType==="cross_x"){ctx.lineWidth=s*.38;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx-s*.7,cy-s*.7);ctx.lineTo(cx+s*.7,cy+s*.7);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.7,cy-s*.7);ctx.lineTo(cx-s*.7,cy+s*.7);ctx.stroke();return}
                  else if(shapeType==="windows"){gap=s*.08;pw=(s-gap)*.85;ctx.beginPath();ctx.rect(cx-pw-gap/2,cy-pw-gap/2,pw,pw);if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.rect(cx+gap/2,cy-pw-gap/2,pw,pw);if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.rect(cx-pw-gap/2,cy+gap/2,pw,pw);if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.rect(cx+gap/2,cy+gap/2,pw,pw);if(modelData.f)ctx.fill();else ctx.stroke();return}
                  else if(shapeType==="gear"){ir2=s*.45;or3=s*.75;for(t2=0;t2<10;t2++){a1=Math.PI*2/10*t2-Math.PI/10*.5;a2=Math.PI*2/10*t2+Math.PI/10*.5;ctx.lineTo(cx+or3*Math.cos(a1),cy+or3*Math.sin(a1));ctx.lineTo(cx+s*Math.cos(a1+Math.PI/10*.25),cy+s*Math.sin(a1+Math.PI/10*.25));ctx.lineTo(cx+s*Math.cos(a2-Math.PI/10*.25),cy+s*Math.sin(a2-Math.PI/10*.25));ctx.lineTo(cx+or3*Math.cos(a2),cy+or3*Math.sin(a2))}ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();ctx.globalCompositeOperation="destination-out";ctx.beginPath();ctx.arc(cx,cy,ir2,0,Math.PI*2);ctx.fillStyle="rgba(0,0,0,1)";ctx.fill();ctx.globalCompositeOperation="source-over";return}
                  else if(shapeType==="chevron"){ctx.lineWidth=s*.22;ctx.lineCap="square";offs=[-s*.38,0,s*.38];for(c2=0;c2<3;c2++){ctx.beginPath();ctx.moveTo(cx-s*.85,cy+s*.45+offs[c2]);ctx.lineTo(cx,cy-s*.05+offs[c2]);ctx.lineTo(cx+s*.85,cy+s*.45+offs[c2]);ctx.stroke()}return}
                  else if(shapeType==="splat"){for(si=0;si<14;si++){sang=Math.PI*2/14*si;srad=si%2===0?s*(0.7+Math.sin(si*1.7)*.18):s*(0.38+Math.cos(si*2.3)*.12);if(si===0)ctx.moveTo(cx+srad*Math.cos(sang),cy+srad*Math.sin(sang));else ctx.lineTo(cx+srad*Math.cos(sang),cy+srad*Math.sin(sang))}ctx.closePath()}
                  else if(shapeType==="music"){ctx.lineWidth=s*.15;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx+s*.25,cy-s*.65);ctx.lineTo(cx+s*.25,cy+s*.25);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.25,cy-s*.65);ctx.bezierCurveTo(cx+s*.85,cy-s*.45,cx+s*.85,cy-s*.05,cx+s*.25,cy-s*.1);ctx.fill();ctx.stroke();ctx.save();ctx.translate(cx+s*.05,cy+s*.38);ctx.rotate(-Math.PI/6);ctx.scale(1.35,0.85);ctx.beginPath();ctx.arc(0,0,s*.28,0,Math.PI*2);ctx.fill();ctx.restore();return}

                  else if(shapeType==="plus"){var arm=s*.36;ctx.beginPath();ctx.moveTo(cx-arm,cy-s);ctx.lineTo(cx+arm,cy-s);ctx.lineTo(cx+arm,cy-arm);ctx.lineTo(cx+s,cy-arm);ctx.lineTo(cx+s,cy+arm);ctx.lineTo(cx+arm,cy+arm);ctx.lineTo(cx+arm,cy+s);ctx.lineTo(cx-arm,cy+s);ctx.lineTo(cx-arm,cy+arm);ctx.lineTo(cx-s,cy+arm);ctx.lineTo(cx-s,cy-arm);ctx.lineTo(cx-arm,cy-arm);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();return}
                  else if(shapeType==="moon"){ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke();ctx.globalCompositeOperation="destination-out";ctx.beginPath();ctx.arc(cx+s*.40,cy-s*.20,s*.74,0,Math.PI*2);ctx.fillStyle="rgba(0,0,0,1)";ctx.fill();ctx.globalCompositeOperation="source-over";return}
                  else if(shapeType==="waterdrop"){ctx.beginPath();ctx.moveTo(cx,cy-s*.92);ctx.bezierCurveTo(cx+s*.50,cy-s*.30,cx+s*.82,cy+s*.22,cx,cy+s*.92);ctx.bezierCurveTo(cx-s*.82,cy+s*.22,cx-s*.50,cy-s*.30,cx,cy-s*.92);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();return}
                  else if(shapeType==="spiral"){ctx.lineWidth=Math.max(1.5,width*.04);ctx.lineCap="round";ctx.beginPath();var turns=3,steps=80;for(var si2=0;si2<=steps;si2++){var theta=turns*Math.PI*2*(si2/steps);var rad3=(s*.92)*(si2/steps);var sx2=cx+rad3*Math.cos(theta-Math.PI/2);var sy2=cy+rad3*Math.sin(theta-Math.PI/2);if(si2===0)ctx.moveTo(sx2,sy2);else ctx.lineTo(sx2,sy2)}ctx.stroke();return}
                  else if(shapeType==="sparkle"){ctx.beginPath();for(var sp2=0;sp2<8;sp2++){var sa2=Math.PI/4*sp2-Math.PI/2;var rr2=sp2%2===0?s:s*.12;if(sp2===0)ctx.moveTo(cx+rr2*Math.cos(sa2),cy+rr2*Math.sin(sa2));else ctx.lineTo(cx+rr2*Math.cos(sa2),cy+rr2*Math.sin(sa2))}ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();return}
                  else if(shapeType==="smile"){ctx.beginPath();ctx.arc(cx,cy,s,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke();ctx.fillStyle="rgba("+r+","+g+","+b+",1)";ctx.beginPath();ctx.arc(cx-s*.30,cy-s*.20,s*.11,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx+s*.30,cy-s*.20,s*.11,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx,cy+s*.10,s*.38,Math.PI*0.12,Math.PI*0.88);ctx.stroke();return}
                  else if(shapeType==="hexagram"){ctx.beginPath();ctx.moveTo(cx,cy-s);ctx.lineTo(cx+s*.87,cy+s*.5);ctx.lineTo(cx-s*.87,cy+s*.5);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.moveTo(cx,cy+s);ctx.lineTo(cx+s*.87,cy-s*.5);ctx.lineTo(cx-s*.87,cy-s*.5);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();return}
                  else if(shapeType==="quatrefoil"){var qr2=s*.50,qd2=s*.36;var qpos2=[{x:cx,y:cy-qd2},{x:cx+qd2,y:cy},{x:cx,y:cy+qd2},{x:cx-qd2,y:cy}];for(p=0;p<4;p++){ctx.beginPath();ctx.arc(qpos2[p].x,qpos2[p].y,qr2,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke()};return}
                  else if(shapeType==="triquetra"){ctx.lineWidth=s*.16;ctx.lineCap="round";ctx.lineJoin="round";var tr3=s*.66;for(p=0;p<3;p++){var ta=Math.PI*2/3*p-Math.PI/2;var tx2=cx+tr3*Math.cos(ta),ty2=cy+tr3*Math.sin(ta);ctx.save();ctx.translate(tx2,ty2);ctx.rotate(ta+Math.PI/2);ctx.beginPath();ctx.arc(0,0,tr3,Math.PI*0.62,Math.PI*1.38);ctx.stroke();ctx.restore()};return}
                  else if(shapeType==="spade"){ctx.beginPath();ctx.moveTo(cx,cy-s*.78);ctx.bezierCurveTo(cx+s*.10,cy-s*.58,cx+s*.90,cy-s*.28,cx+s*.90,cy+s*.12);ctx.bezierCurveTo(cx+s*.90,cy+s*.54,cx+s*.50,cy+s*.76,cx,cy+s*.32);ctx.bezierCurveTo(cx-s*.50,cy+s*.76,cx-s*.90,cy+s*.54,cx-s*.90,cy+s*.12);ctx.bezierCurveTo(cx-s*.90,cy-s*.28,cx-s*.10,cy-s*.58,cx,cy-s*.78);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();ctx.lineWidth=Math.max(1.5,width*.04);ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx,cy+s*.32);ctx.lineTo(cx,cy+s*.78);ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.38,cy+s*.78);ctx.bezierCurveTo(cx-s*.12,cy+s*.58,cx+s*.12,cy+s*.58,cx+s*.38,cy+s*.78);ctx.stroke();return}
                  else if(shapeType==="heart"){ctx.beginPath();ctx.moveTo(cx,cy+s*.80);ctx.bezierCurveTo(cx-s*.10,cy+s*.60,cx-s*.90,cy+s*.30,cx-s*.90,cy-s*.10);ctx.bezierCurveTo(cx-s*.90,cy-s*.55,cx-s*.50,cy-s*.80,cx,cy-s*.35);ctx.bezierCurveTo(cx+s*.50,cy-s*.80,cx+s*.90,cy-s*.55,cx+s*.90,cy-s*.10);ctx.bezierCurveTo(cx+s*.90,cy+s*.30,cx+s*.10,cy+s*.60,cx,cy+s*.80);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();return}
                  else if(shapeType==="club"){var cPi=[{cx2:cx,cy2:cy-s*.38},{cx2:cx-s*.38,cy2:cy+s*.14},{cx2:cx+s*.38,cy2:cy+s*.14}];for(p=0;p<3;p++){ctx.beginPath();ctx.arc(cPi[p].cx2,cPi[p].cy2,s*.36,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke()}ctx.lineWidth=Math.max(1.5,width*.04);ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx,cy+s*.35);ctx.lineTo(cx,cy+s*.78);ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.38,cy+s*.78);ctx.bezierCurveTo(cx-s*.12,cy+s*.58,cx+s*.12,cy+s*.58,cx+s*.38,cy+s*.78);ctx.stroke();return}
                  else if(shapeType==="cat"){ctx.beginPath();ctx.arc(cx,cy+s*.08,s*.72,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.52,cy-s*.42);ctx.lineTo(cx-s*.22,cy-s*.78);ctx.lineTo(cx-s*.06,cy-s*.38);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.52,cy-s*.42);ctx.lineTo(cx+s*.22,cy-s*.78);ctx.lineTo(cx+s*.06,cy-s*.38);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();ctx.fillStyle="rgba("+r+","+g+","+b+",1)";ctx.beginPath();ctx.save();ctx.translate(cx-s*.26,cy-s*.04);ctx.save();ctx.scale(s*.12,s*.16);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.restore();ctx.beginPath();ctx.save();ctx.translate(cx+s*.26,cy-s*.04);ctx.save();ctx.scale(s*.12,s*.16);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();ctx.fill();ctx.restore();return}
                  else if(shapeType==="daisy"){var np4=10;for(p=0;p<np4;p++){pa=Math.PI*2/np4*p;ctx.save();ctx.translate(cx+s*.52*Math.cos(pa),cy+s*.52*Math.sin(pa));ctx.rotate(pa);ctx.beginPath();ctx.save();ctx.scale(s*.22,s*.42);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(modelData.f)ctx.fill();else ctx.stroke();ctx.restore()}ctx.beginPath();ctx.arc(cx,cy,s*.28,0,Math.PI*2);ctx.fill();return}
                  else if(shapeType==="bunny"){ctx.save();ctx.translate(cx-s*.26,cy-s*.28);ctx.rotate(-0.14);ctx.beginPath();ctx.save();ctx.scale(s*.20,s*.60);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(modelData.f)ctx.fill();else ctx.stroke();ctx.restore();ctx.save();ctx.translate(cx+s*.26,cy-s*.28);ctx.rotate(0.14);ctx.beginPath();ctx.save();ctx.scale(s*.20,s*.60);ctx.arc(0,0,1,0,Math.PI*2);ctx.restore();if(modelData.f)ctx.fill();else ctx.stroke();ctx.restore();ctx.beginPath();ctx.arc(cx,cy+s*.24,s*.54,0,Math.PI*2);if(modelData.f)ctx.fill();else ctx.stroke();ctx.fillStyle="rgba("+r+","+g+","+b+",1)";ctx.beginPath();ctx.arc(cx-s*.20,cy+s*.14,s*.09,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx+s*.20,cy+s*.14,s*.09,0,Math.PI*2);ctx.fill();return}
                  else if(shapeType==="android"){ctx.lineWidth=Math.max(1.5,width*.04);ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx-s*.26,cy-s*.52);ctx.lineTo(cx-s*.46,cy-s*.88);ctx.stroke();ctx.beginPath();ctx.arc(cx-s*.46,cy-s*.88,s*.06,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.moveTo(cx+s*.26,cy-s*.52);ctx.lineTo(cx+s*.46,cy-s*.88);ctx.stroke();ctx.beginPath();ctx.arc(cx+s*.46,cy-s*.88,s*.06,0,Math.PI*2);ctx.fill();var hr2=s*.14,hx=cx-s*.60,hy=cy-s*.52,hw=s*1.20,hh=s*.76;ctx.beginPath();ctx.moveTo(hx+hr2,hy);ctx.lineTo(hx+hw-hr2,hy);ctx.arc(hx+hw-hr2,hy+hr2,hr2,-Math.PI/2,0);ctx.lineTo(hx+hw,hy+hh-hr2);ctx.arc(hx+hw-hr2,hy+hh-hr2,hr2,0,Math.PI/2);ctx.lineTo(hx+hr2,hy+hh);ctx.arc(hx+hr2,hy+hh-hr2,hr2,Math.PI/2,Math.PI);ctx.lineTo(hx,hy+hr2);ctx.arc(hx+hr2,hy+hr2,hr2,Math.PI,Math.PI*1.5);ctx.closePath();if(modelData.f)ctx.fill();else ctx.stroke();ctx.fillStyle="rgba("+r+","+g+","+b+",1)";ctx.beginPath();ctx.arc(cx-s*.24,cy-s*.22,s*.09,0,Math.PI*2);ctx.fill();ctx.beginPath();ctx.arc(cx+s*.24,cy-s*.22,s*.09,0,Math.PI*2);ctx.fill();return}
                  else if(shapeType==="music2"){ctx.lineWidth=s*.12;ctx.lineCap="round";ctx.beginPath();ctx.moveTo(cx-s*.28,cy-s*.60);ctx.lineTo(cx-s*.28,cy+s*.28);ctx.stroke();ctx.beginPath();ctx.moveTo(cx+s*.28,cy-s*.60);ctx.lineTo(cx+s*.28,cy+s*.28);ctx.stroke();ctx.lineWidth=s*.14;ctx.beginPath();ctx.moveTo(cx-s*.28,cy-s*.60);ctx.lineTo(cx+s*.28,cy-s*.60);ctx.stroke();ctx.beginPath();ctx.moveTo(cx-s*.28,cy-s*.40);ctx.lineTo(cx+s*.28,cy-s*.40);ctx.stroke();ctx.save();ctx.translate(cx-s*.28,cy+s*.44);ctx.rotate(-Math.PI/7);ctx.scale(1.4,0.82);ctx.beginPath();ctx.arc(0,0,s*.25,0,Math.PI*2);ctx.fillStyle="rgba("+r+","+g+","+b+",1)";ctx.fill();ctx.restore();ctx.save();ctx.translate(cx+s*.28,cy+s*.44);ctx.rotate(-Math.PI/7);ctx.scale(1.4,0.82);ctx.beginPath();ctx.arc(0,0,s*.25,0,Math.PI*2);ctx.fill();ctx.restore();return}
                  if(modelData.f)ctx.fill();else ctx.stroke()
                }
              }
              SequentialAnimation on x { loops: Animation.Infinite
                NumberAnimation { to: endX-bsize/2; duration: modelData.dur; easing.type: Easing.InOutSine }
                NumberAnimation { to: bx-bsize/2;   duration: modelData.dur; easing.type: Easing.InOutSine }
              }
              SequentialAnimation on y { loops: Animation.Infinite
                NumberAnimation { to: endY-bsize/2; duration: modelData.dur; easing.type: Easing.InOutSine }
                NumberAnimation { to: by-bsize/2;   duration: modelData.dur; easing.type: Easing.InOutSine }
              }
              SequentialAnimation on scale { loops: Animation.Infinite
                NumberAnimation { to: modelData.se; duration: modelData.dur; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0;          duration: modelData.dur; easing.type: Easing.InOutSine }
              }
            }
          }
        }

        Item {
          id: infoCardAvatarClip
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom; anchors.bottomMargin: vpx(30)
          width: parent.width * 0.90; height: parent.height - vpx(50)
          clip: true; z: 2
          Image {
            id: infoCardAvatarImg; source: pAvatarUrl
            fillMode: Image.PreserveAspectFit; smooth: true; antialiasing: true
            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width; height: parent.height
            Behavior on source {
              SequentialAnimation {
                NumberAnimation { target: infoCardAvatarImg; property: "opacity"; to: 0; duration: 160 }
                NumberAnimation { target: infoCardAvatarImg; property: "opacity"; to: 1; duration: 280 }
              }
            }
          }
        }

        Row {
          anchors.left: parent.left; anchors.top: parent.top
          anchors.leftMargin: vpx(18); anchors.topMargin: vpx(18)
          spacing: vpx(8); z: 3
          Rectangle { width: vpx(2); height: vpx(22); color: pAccentHex; anchors.verticalCenter: parent.verticalCenter }
          StyledText { text: "Profile Card"; font.pixelSize: vpx(16); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
        }
      }

      // Right half: profile info
      Item {
        anchors.left: infoCardAvatarHalf.right; anchors.right: parent.right
        anchors.top: parent.top; anchors.bottom: parent.bottom
        anchors.topMargin: vpx(18); anchors.bottomMargin: vpx(18); anchors.rightMargin: vpx(18)

        Column {
          anchors.left: parent.left; anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter; spacing: vpx(10)

          Row {
            spacing: vpx(12); width: parent.width

            // Gamerpic + membership pill stacked vertically
            Column {
              spacing: vpx(6); anchors.verticalCenter: parent.verticalCenter
              Rectangle {
                width: vpx(80); height: vpx(80); radius: vpx(6)
                color: "#18FFFFFF"; border.color: pAccentHex; border.width: vpx(2)
                Image {
                  anchors.fill: parent; anchors.margins: vpx(3)
                  source: pGamerpic !== "" ? pGamerpic : "../../assets/images/gamerpic/MissingGamerPic.png"
                  fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                  layer.enabled: false
                }
              }
              Rectangle {
                width: subStatusRow2.implicitWidth + vpx(16); height: vpx(20); radius: vpx(10)
                color: pAccentRgba(0.35); border.color: pAccentHex; border.width: vpx(1)

                Row {
                  id: subStatusRow2; anchors.centerIn: parent; spacing: vpx(4)
                  Rectangle { width: vpx(6); height: vpx(6); radius: vpx(3); color: "#44FF44"; anchors.verticalCenter: parent.verticalCenter }
                  StyledText { text: pSubStatus; font.pixelSize: vpx(10); color: "#FFFFFF" }
                }
              }
            }

            // Name + gamerscore badge
            Column {
              anchors.verticalCenter: parent.verticalCenter; spacing: vpx(4); width: parent.width - vpx(98)
              StyledText {
                text: pName; font.pixelSize: vpx(20); font.bold: true;
                width: parent.width; elide: Text.ElideRight
              }
              Rectangle {
                height: vpx(22); width: infoScoreBadge.implicitWidth + vpx(16); radius: vpx(11)
                color: pAccentRgba(0.25); border.color: pAccentHex; border.width: vpx(1)
                StyledText { id: infoScoreBadge; anchors.centerIn: parent; text: pGamerscore + " \u24AD"; font.pixelSize: vpx(13); color: pAccentHex }
              }
            }
          }

          Rectangle { width: parent.width; height: vpx(1); color: pAccentRgba(0.3) }

          StyledText { visible: pMotto !== ""; text: "\"" + pMotto + "\""; font.pixelSize: vpx(12); font.italic: true; color: "#FFFFFF"; width: parent.width; wrapMode: Text.WordWrap }

          Repeater {
            model: [
              { label: "Status",     value: pStatus },
              { label: "Membership", value: pSubStatus },
              { label: "Region",     value: pRegion !== "" ? pRegion : "Not set" },
              { label: "Bio",        value: pBio    !== "" ? pBio    : "—" }
            ]
            delegate: Rectangle {
              width: parent.width; height: vpx(34)
              color: index % 2 === 0 ? "#0CFFFFFF" : "transparent"; radius: vpx(3)
              RowLayout {
                anchors.fill: parent; anchors.leftMargin: vpx(8); anchors.rightMargin: vpx(8)
                StyledText { text: modelData.label; color: "#888888"; font.pixelSize: vpx(11); Layout.preferredWidth: vpx(72) }
                Rectangle { width: vpx(1); height: vpx(16); color: "#20FFFFFF" }
                StyledText { Layout.fillWidth: true; text: modelData.value; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"; elide: Text.ElideRight; leftPadding: vpx(8) }
              }
            }
          }

        }
      }
      // ── Top emoji border line ────────────────────────────────
      Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: vpx(2); color: pAccentHex; opacity: 0.75; z: 10
      }
      Item {
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: vpx(18); z: 12
        visible: pBorderTop !== ""
        Rectangle { anchors.fill: parent; color: pAccentHex; opacity: 0.10 }
        StyledText {
          anchors.centerIn: parent
          text: [pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop,pBorderTop].join(" ")
          font.pixelSize: vpx(13); color: pAccentHex
          layer.enabled: false; clip: true
          width: parent.width - vpx(8); horizontalAlignment: Text.AlignHCenter
        }
      }

      // ── Bottom emoji border strip (right side, under info half) ──
      Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: vpx(2); color: pAccentHex; opacity: 0.75; z: 10
      }
      Item {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        width: parent.width * 0.48; height: vpx(18); z: 12
        visible: pBorderBottom !== ""
        Rectangle { anchors.fill: parent; color: pAccentHex; opacity: 0.18 }
        Rectangle {
          anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
          height: vpx(2); color: pAccentHex; opacity: 0.75
        }
        StyledText {
          anchors.centerIn: parent
          text: [pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom,pBorderBottom].join(" ")
          font.pixelSize: vpx(13); color: pAccentHex
          layer.enabled: false; clip: true
          width: parent.width - vpx(8); horizontalAlignment: Text.AlignHCenter
        }
      }

      Text {
        anchors.left: parent.left; anchors.bottom: parent.bottom
        anchors.leftMargin: vpx(10); anchors.bottomMargin: vpx(8)
        text: "Profile Info Card Panel"; font.pixelSize: vpx(10); color: "#FFFFFF"
      }
    }
  }
  // ════════════════════════════════════════════════════════════════
  // ════════════════════════════════════════════════════════════════
  // AVATAR SCENE CONTROLLER — slides down from top of screen
  // Full redesign: rounded border, ℹ help overlay, grouped chips,
  // half-width sliders filling title row, Original Dark + ThemesDetails
  // settings parity. Info button top-right replaces controls with
  // descriptions page. All shared globals marked ⬡.
  // ════════════════════════════════════════════════════════════════
  Item {
    id: avatarSceneDrawer
    anchors.left: parent.left; anchors.right: parent.right
    anchors.leftMargin: vpx(8); anchors.rightMargin: vpx(8)
    anchors.top: parent.top; anchors.topMargin: vpx(4)
    // title(20) + sep(9) + controls(110) + padding(13) — expands for help overlay
    height: showHelp ? vpx(560) : (showContainers ? vpx(20+9+140+13) : vpx(20+9+110+13))
    z: 100
    clip: false

    property bool showHelp: false
    property bool showPresets: false
    property bool showContainers: false
    property int  activePreset: -1   // -1=custom, 0-6=preset index

    // ── Apply a full preset — writes all relevant cfg keys + root props ──
    function applyPreset(p) {
      activePreset = p
      api.memory.set("cfg.avatarActivePreset", String(p))

      // preset data: [darkOn, panelGrad, systemGrad, profileGrad, accentGrad, themeGrad,
      //               vignette, hideBg, dropShadow, spotlight, shapes,
      //               bgOpacity, glowMix, panelFill, gradStrength, accentGlow, themeGlow]
      var presets = [
        // 0 Green Classic — img1 style: green, dark overlay, gradients on
        [true,  true,  true,  true,  true,  true,  true,  false, true,  true,  false, 100, 100, 75,  97,  12,  8  ],
        // 1 Neon Teal — img2 style: teal panels, full info, bright
        [false, true,  true,  true,  true,  false, false, false, true,  true,  true,  85,  80,  60,  80,  20,  5  ],
        // 2 Biohazard Red — img3 left / img5 left: deep red bg, circles, high opacity
        [true,  true,  true,  false, true,  false, true,  false, false, false, true,  100, 60,  90,  100, 8,   4  ],
        // 3 Cortana Blue — img4 / img6 blue: purple-blue gradient, hexagons
        [false, true,  true,  true,  true,  true,  true,  false, true,  true,  true,  90,  70,  65,  88,  18,  10 ],
        // 4 Hot Pink — img3 right / img5 pink: magenta, hexagons, vivid
        [false, true,  false, true,  true,  true,  false, false, true,  false, true,  80,  100, 50,  75,  25,  12 ],
        // 5 Dark Slate — img5 blue Windows panel: near-black, minimal, clean
        [true,  false, false, false, false, false, false, false, true,  false, false, 100, 20,  85,  40,  4,   2  ],
        // 6 Profile Orange — img7 edit panel: warm purple-orange, shapes off, spotlight on
        [false, true,  false, true,  false, true,  true,  false, true,  true,  false, 95,  90,  55,  70,  6,   15 ],
        // 7 Cortana Gallery — translucent glassy panels, system blue, per-profile accent glow, spotlight, no shapes
        [false, true,  true,  true,  true,  true,  true,  false, true,  true,  false, 58,  88,  52,  92,  15,  12 ],
        // 8 Dark Showcase — heavy dark panels, bold per-profile tint, strong gradient, no spotlight/shapes
        [true,  true,  true,  true,  true,  true,  true,  false, true,  false, false, 90,  70,  80,  95,  20,  14 ],
        // 9 Airy Light — bright near-transparent panels, profile accent tint, no system/vignette/spotlight/shapes
        [false, true,  false, true,  true,  false, false, false, true,  false, false, 45,  60,  40,  75,  18,  4  ],
        // 10 Xbox Blade — near-black flat panels, no gradients/glow/shapes, classic 360 dashboard style
        [true,  false, false, false, false, false, false, false, true,  false, false, 95,  10,  88,  20,  2,   2  ],
        // 11 NXE Warm — dark charcoal panels, warm diagonal gradient, theme top bloom, vignette, no accent/shapes/spotlight
        [true,  true,  false, false, false, true,  true,  false, true,  false, false, 92,  15,  85,  60,  3,   18 ],
        // 12 Military Ops — dark olive panels, strong system diagonal, floating shapes, theme bloom, vignette, no spotlight/accent
        [true,  true,  true,  false, false, true,  true,  false, true,  false, true,  88,  25,  78,  92,  4,   22 ],
      ]

      if (p < 0 || p >= presets.length) return
      var d = presets[p]

      function setBool(key, prop, val) { root[prop]=val; api.memory.set(key, val?"true":"false") }
      function setNum(key, prop, val)  { root[prop]=val; api.memory.set(key, val.toString()) }

      setBool("cfg.avatarDark",        "avatarDarkOn",        d[0])
      setBool("cfg.avatarPanelGrad",   "avatarPanelGradOn",   d[1])
      setBool("cfg.avatarSystemGrad",  "avatarSystemGradOn",  d[2])
      setBool("cfg.avatarProfileGrad", "avatarProfileGradOn", d[3])
      setBool("cfg.avatarAccentGrad",  "avatarAccentGradOn",  d[4])
      setBool("cfg.avatarThemeGrad",   "avatarThemeGradOn",   d[5])
      setBool("cfg.avatarVignette",    "avatarVignette",      d[6])
      setBool("cfg.avatarHideBg",      "avatarHideBg",        d[7])
      setBool("cfg.avatarDropShadow",  "avatarDropShadow",    d[8])
      setBool("cfg.avatarSpotlight",   "avatarSpotlightOn",   d[9])
      setBool("cfg.avatarShapes",      "avatarShapesOn",      d[10])
      setNum("cfg.avatarBgOpacity",    "avatarBgOpacity",     d[11])
      setNum("cfg.avatarGlowColorMix", "avatarGlowColorMix",  d[12])
      setNum("cfg.panelBaseAlpha",     "panelBaseAlpha",      d[13])
      setNum("cfg.gradientStrength",   "gradientStrength",    d[14])
      setNum("cfg.accentGradAlpha",    "accentGradAlpha",     d[15])
      setNum("cfg.themeGradAlpha",     "themeGradAlpha",      d[16])
    }

    // ── Reset ALL settings (avatar scene + profile panel) to factory defaults ──
    function resetToDefaults() {
      activePreset = -1
      api.memory.set("cfg.avatarActivePreset", "-1")
      function setBool(key, prop, val) { root[prop]=val; api.memory.set(key, val?"true":"false") }
      function setNum(key, prop, val)  { root[prop]=val; api.memory.set(key, val.toString()) }

      // ── Avatar Scene defaults ──────────────────────────────────────
      setBool("theme.themeDark",       "themeDarkOn",        true)
      setBool("cfg.avatarDark",        "avatarDarkOn",        true)
      setBool("cfg.avatarPanelGrad",   "avatarPanelGradOn",   true)
      setBool("cfg.avatarSystemGrad",  "avatarSystemGradOn",  true)
      setBool("cfg.avatarProfileGrad", "avatarProfileGradOn", true)
      setBool("cfg.avatarAccentGrad",  "avatarAccentGradOn",  true)
      setBool("cfg.avatarThemeGrad",   "avatarThemeGradOn",   true)
      setBool("cfg.avatarVignette",    "avatarVignette",      true)
      setBool("cfg.avatarHideBg",      "avatarHideBg",        false)
      setBool("cfg.avatarDropShadow",  "avatarDropShadow",    true)
      setBool("cfg.avatarSpotlight",   "avatarSpotlightOn",   true)
      setBool("cfg.avatarShapes",      "avatarShapesOn",      true)
      setBool("cfg.avatarAvatar",      "avatarAvatarOn",      true)
      setBool("cfg.avatarGamerpic",    "avatarGamerpicOn",    true)
      setBool("cfg.avatarGamerscore",  "avatarGamerscoreOn",  true)
      setBool("cfg.avatarStats",       "avatarStatsOn",       true)
      setBool("cfg.avatarGamertag",    "avatarGamertagOn",    true)
      setBool("cfg.avatarBorders",     "avatarBordersOn",     true)
      setBool("cfg.avatarUseSystemColors",  "avatarUseSystemColors",  true)
      setBool("cfg.avatarUseProfileColors", "avatarUseProfileColors", true)
      setBool("cfg.avatarSyncDark",    "avatarSyncDark",      true)
      setBool("cfg.avatarSyncThemes",  "avatarSyncThemes",    false)
      setNum("cfg.avatarBgOpacity",    "avatarBgOpacity",     100)
      setNum("cfg.avatarGlowColorMix", "avatarGlowColorMix",  100)

      // ── Shared global panel defaults ───────────────────────────────
      setNum("cfg.panelBaseAlpha",     "panelBaseAlpha",      75)
      setNum("cfg.gradientStrength",   "gradientStrength",    97)
      setNum("cfg.accentGradAlpha",    "accentGradAlpha",     12)
      setNum("cfg.themeGradAlpha",     "themeGradAlpha",      8)
      setNum("cfg.accentTransparency", "accentTransparency",  0)
      setNum("cfg.accentOpacity",      "accentOpacity",       100)
      setNum("cfg.accentGradTransp",   "accentGradTransp",    0)
      setNum("cfg.accentGradOpacity",  "accentGradOpacity",   100)
      setNum("cfg.shadowRadius",       "globalShadowRadius",  4)

      // ── Profile panel defaults ──────────────────────────────────────
      setBool("cfg.profileDropShadow",   "profileDropShadow",   true)
      setBool("cfg.profileShape",        "profileShapeOn",      true)
      setBool("cfg.profileVignette",     "profileVignette",     true)
      setBool("cfg.profileAccentGrad",   "profileAccentGradOn", true)
      setBool("cfg.profileThemeGrad",    "profileThemeGradOn",  true)
      setBool("cfg.profileHideBg",       "profileHideBg",       false)
      setBool("cfg.profileGamerpic",     "profileGamerpicOn",   true)
      setBool("cfg.profileGamerscore",   "profileGamerscoreOn", true)
      setBool("cfg.profileGamertag",     "profileGamertagOn",   true)
      setBool("cfg.profileBorders",      "profileBordersOn",    true)
      setBool("cfg.profileStats",        "profileStatsOn",      true)
      setBool("cfg.profileSpotlight",    "profileSpotlightOn",  true)
      setNum("cfg.profileBgOpacity",     "profileBgOpacity",    100)
      setNum("cfg.profileGlowColorMix",  "profileGlowColorMix", 100)
      setNum("cfg.profileShapeOpacity",  "profileShapeOpacity", 60)
    }

    transform: Translate {
      y: root.avatarSceneDrawerOpen ? 0 : -(avatarSceneDrawer.height + vpx(20))
      Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    }
    opacity: root.avatarSceneDrawerOpen ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 180 } }

    // ── Rounded border outer shell ───────────────────────────────────
    Rectangle {
      anchors.fill: parent; radius: vpx(12)
      color: "transparent"
      border.color: root.accentRgba(0.55); border.width: vpx(1)
      z: 10
    }

    // ── Background fill (rounded + themed) ──────────────────────────
    Item {
      id: ascBgMask; anchors.fill: parent
      layer.effect: OpacityMask {
        maskSource: Rectangle { width: ascBgMask.width; height: ascBgMask.height; radius: vpx(12) }
      }
      Rectangle { anchors.fill: parent; color: root.themeDark; visible: root.themeDarkOn }
      LinearGradient {
        visible: root.themeDarkOn && root.panelGradient; anchors.fill: parent
        start: Qt.point(0,0); end: Qt.point(width,height)
        gradient: Gradient {
          GradientStop { position:0.0; color:Qt.rgba(root.themeDark.r,root.themeDark.g,root.themeDark.b,0.97) }
          GradientStop { position:0.6; color:Qt.rgba(root.themeDark.r*.7,root.themeDark.g*.7,root.themeDark.b*.7,0.97) }
          GradientStop { position:1.0; color:Qt.rgba(root.themeDark.r*.5,root.themeDark.g*.5,root.themeDark.b*.5,0.97) }
        }
      }
      LinearGradient {
        visible: root.themeDarkOn && root.panelGradient && root.gradAccentOn; anchors.fill: parent
        start: Qt.point(0,0); end: Qt.point(width,0)
        gradient: Gradient {
          GradientStop { position:0.0; color:Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.14) }
          GradientStop { position:1.0; color:"transparent" }
        }
      }
      LinearGradient {
        visible: root.themeDarkOn && root.panelGradient && root.gradThemeOn; anchors.fill: parent
        start: Qt.point(0,0); end: Qt.point(0,height)
        gradient: Gradient {
          GradientStop { position:0.0; color:Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.09) }
          GradientStop { position:1.0; color:"transparent" }
        }
      }
      Rectangle { anchors.fill: parent; color: root.themeFill; visible: !root.themeDarkOn && !root.panelGradient }
      LinearGradient {
        visible: !root.themeDarkOn && root.panelGradient && root.gradThemeOn; anchors.fill: parent
        start: Qt.point(0,0); end: Qt.point(width,height)
        gradient: Gradient {
          GradientStop { position:0.0; color:Qt.rgba(root.themeFill.r,root.themeFill.g,root.themeFill.b,root.panelAlpha) }
          GradientStop { position:0.6; color:Qt.rgba(root.themeFill.r*.7,root.themeFill.g*.7,root.themeFill.b*.7,root.panelAlpha) }
          GradientStop { position:1.0; color:Qt.rgba(root.themeFill.r*.5,root.themeFill.g*.5,root.themeFill.b*.5,root.panelAlpha) }
        }
      }
      LinearGradient {
        visible: !root.themeDarkOn && root.panelGradient && root.gradAccentOn; anchors.fill: parent
        start: Qt.point(0,0); end: Qt.point(width,0)
        gradient: Gradient {
          GradientStop { position:0.0; color:Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.14) }
          GradientStop { position:1.0; color:"transparent" }
        }
      }
      LinearGradient {
        visible: !root.themeDarkOn && root.panelGradient && root.gradThemeOn; anchors.fill: parent
        start: Qt.point(0,0); end: Qt.point(0,height)
        gradient: Gradient {
          GradientStop { position:0.0; color:Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.09) }
          GradientStop { position:1.0; color:"transparent" }
        }
      }
    }


    // ── Main content column ──────────────────────────────────────────
    Column {
      anchors.fill: parent
      anchors.leftMargin: vpx(12); anchors.rightMargin: vpx(12)
      anchors.topMargin: vpx(8); anchors.bottomMargin: vpx(8)
      spacing: vpx(0)

      // ══ ROW 1: Title bar ══ Left: title + element chips | Right: sync + color + controls ═══
      Item {
        width: parent.width; height: vpx(22)

        // Left: accent bar + title + Avatar Scene Only chips
        Row {
          anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: vpx(5)
          Rectangle { width: vpx(3); height: vpx(14); radius: vpx(2); color: root.accentHex; anchors.verticalCenter: parent.verticalCenter

          }
          StyledText { text: "✦  Avatar Scene Controller"; font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter

          }
          Rectangle { width: vpx(1); height: vpx(14); color: Qt.rgba(1,1,1,0.18); anchors.verticalCenter: parent.verticalCenter }
          StyledText {
            text: "Avatar Scene Only"; font.pixelSize: vpx(9); font.bold: true; color: root.accentHex
            anchors.verticalCenter: parent.verticalCenter

          }
          Rectangle {
            height: vpx(18); radius: vpx(9); width: hc_avatarAvatarOn.implicitWidth + vpx(12); anchors.verticalCenter: parent.verticalCenter
            color: root.avatarAvatarOn ? root.accentRgba(0.50) : root.accentRgba(0.12)
            border.color: root.avatarAvatarOn ? root.accentHex : root.accentRgba(0.28); border.width: vpx(1)

            Row { anchors.centerIn: parent; spacing: vpx(4)
              Rectangle { width: vpx(5); height: vpx(5); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                color: root.avatarAvatarOn ? "#44FF44" : root.accentRgba(0.35) }
              StyledText { id: hc_avatarAvatarOn; text: "Avatar"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF"

              }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { root.avatarAvatarOn=!root.avatarAvatarOn; api.memory.set("cfg.avatarAvatar",root.avatarAvatarOn?"true":"false") }
            }
          }
          Rectangle {
            height: vpx(18); radius: vpx(9); width: hc_avatarGamerpicOn.implicitWidth + vpx(12); anchors.verticalCenter: parent.verticalCenter
            color: root.avatarGamerpicOn ? root.accentRgba(0.50) : root.accentRgba(0.12)
            border.color: root.avatarGamerpicOn ? root.accentHex : root.accentRgba(0.28); border.width: vpx(1)

            Row { anchors.centerIn: parent; spacing: vpx(4)
              Rectangle { width: vpx(5); height: vpx(5); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                color: root.avatarGamerpicOn ? "#44FF44" : root.accentRgba(0.35) }
              StyledText { id: hc_avatarGamerpicOn; text: "Gamerpic"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF"

              }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { root.avatarGamerpicOn=!root.avatarGamerpicOn; api.memory.set("cfg.avatarGamerpic",root.avatarGamerpicOn?"true":"false") }
            }
          }
          Rectangle {
            height: vpx(18); radius: vpx(9); width: hc_avatarGamerscoreOn.implicitWidth + vpx(12); anchors.verticalCenter: parent.verticalCenter
            color: root.avatarGamerscoreOn ? root.accentRgba(0.50) : root.accentRgba(0.12)
            border.color: root.avatarGamerscoreOn ? root.accentHex : root.accentRgba(0.28); border.width: vpx(1)

            Row { anchors.centerIn: parent; spacing: vpx(4)
              Rectangle { width: vpx(5); height: vpx(5); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                color: root.avatarGamerscoreOn ? "#44FF44" : root.accentRgba(0.35) }
              StyledText { id: hc_avatarGamerscoreOn; text: "Gamerscore"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF"

              }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { root.avatarGamerscoreOn=!root.avatarGamerscoreOn; api.memory.set("cfg.avatarGamerscore",root.avatarGamerscoreOn?"true":"false") }
            }
          }
          Rectangle {
            height: vpx(18); radius: vpx(9); width: hc_avatarStatsOn.implicitWidth + vpx(12); anchors.verticalCenter: parent.verticalCenter
            color: root.avatarStatsOn ? root.accentRgba(0.50) : root.accentRgba(0.12)
            border.color: root.avatarStatsOn ? root.accentHex : root.accentRgba(0.28); border.width: vpx(1)

            Row { anchors.centerIn: parent; spacing: vpx(4)
              Rectangle { width: vpx(5); height: vpx(5); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                color: root.avatarStatsOn ? "#44FF44" : root.accentRgba(0.35) }
              StyledText { id: hc_avatarStatsOn; text: "Stat Pills"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF"

              }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { root.avatarStatsOn=!root.avatarStatsOn; api.memory.set("cfg.avatarStats",root.avatarStatsOn?"true":"false") }
            }
          }
          Rectangle {
            height: vpx(18); radius: vpx(9); width: hc_avatarGamertagOn.implicitWidth + vpx(12); anchors.verticalCenter: parent.verticalCenter
            color: root.avatarGamertagOn ? root.accentRgba(0.50) : root.accentRgba(0.12)
            border.color: root.avatarGamertagOn ? root.accentHex : root.accentRgba(0.28); border.width: vpx(1)

            Row { anchors.centerIn: parent; spacing: vpx(4)
              Rectangle { width: vpx(5); height: vpx(5); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                color: root.avatarGamertagOn ? "#44FF44" : root.accentRgba(0.35) }
              StyledText { id: hc_avatarGamertagOn; text: "Gamertag"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF"

              }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { root.avatarGamertagOn=!root.avatarGamertagOn; api.memory.set("cfg.avatarGamertag",root.avatarGamertagOn?"true":"false") }
            }
          }
          Rectangle {
            height: vpx(18); radius: vpx(9); width: hc_avatarBordersOn.implicitWidth + vpx(12); anchors.verticalCenter: parent.verticalCenter
            color: root.avatarBordersOn ? root.accentRgba(0.50) : root.accentRgba(0.12)
            border.color: root.avatarBordersOn ? root.accentHex : root.accentRgba(0.28); border.width: vpx(1)

            Row { anchors.centerIn: parent; spacing: vpx(4)
              Rectangle { width: vpx(5); height: vpx(5); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                color: root.avatarBordersOn ? "#44FF44" : root.accentRgba(0.35) }
              StyledText { id: hc_avatarBordersOn; text: "Borders"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF"

              }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { root.avatarBordersOn=!root.avatarBordersOn; api.memory.set("cfg.avatarBorders",root.avatarBordersOn?"true":"false") }
            }
          }
          Rectangle {
            height: vpx(18); radius: vpx(9); width: hc_avatarLatestGamesOn.implicitWidth + vpx(12); anchors.verticalCenter: parent.verticalCenter
            color: root.avatarLatestGamesOn ? root.accentRgba(0.50) : root.accentRgba(0.12)
            border.color: root.avatarLatestGamesOn ? root.accentHex : root.accentRgba(0.28); border.width: vpx(1)
            Row { anchors.centerIn: parent; spacing: vpx(4)
              Rectangle { width: vpx(5); height: vpx(5); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                color: root.avatarLatestGamesOn ? "#44FF44" : root.accentRgba(0.35) }
              StyledText { id: hc_avatarLatestGamesOn; text: "Latest Games"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF" }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { root.avatarLatestGamesOn=!root.avatarLatestGamesOn; api.memory.set("cfg.avatarLatestGames",root.avatarLatestGamesOn?"true":"false") }
            }
          }
        }

        // Right: System Colors | Profile Colors | Sync Dark | Sync Panels | ⇄ | ↺ | ☰ | ℹ | ✕
        Row {
          anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: vpx(4)

          // System Colors pill
          Rectangle {
            height: vpx(18); radius: vpx(9); width: hdrSysLbl.implicitWidth + vpx(14); anchors.verticalCenter: parent.verticalCenter
            color: root.avatarUseSystemColors ? root.accentRgba(0.40) : root.accentRgba(0.10)
            border.color: root.avatarUseSystemColors ? root.accentHex : root.accentRgba(0.25); border.width: vpx(1)

            Row { anchors.centerIn: parent; spacing: vpx(4)
              Rectangle { width: vpx(7); height: vpx(7); radius: vpx(4); anchors.verticalCenter: parent.verticalCenter
                color: root.themeHex; border.color: Qt.rgba(1,1,1,0.4); border.width: vpx(1) }
              StyledText { id: hdrSysLbl; text: "System Colors"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF"

              }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { root.avatarUseSystemColors=!root.avatarUseSystemColors; api.memory.set("cfg.avatarUseSystemColors",root.avatarUseSystemColors?"true":"false") }
            }
          }

          // Containers button
          Rectangle {
            height: vpx(18); radius: vpx(9); width: hdrContLbl.implicitWidth + vpx(14); anchors.verticalCenter: parent.verticalCenter
            color: avatarSceneDrawer.showContainers ? root.accentRgba(0.50) : root.accentRgba(0.10)
            border.color: avatarSceneDrawer.showContainers ? root.accentHex : root.accentRgba(0.25); border.width: vpx(1)

            Row { anchors.centerIn: parent; spacing: vpx(4)
              Rectangle { width: vpx(7); height: vpx(7); radius: vpx(4); anchors.verticalCenter: parent.verticalCenter
                color: root.containersOn ? root.accentHex : Qt.rgba(1,1,1,0.35); border.color: Qt.rgba(1,1,1,0.4); border.width: vpx(1) }
              StyledText { id: hdrContLbl; text: "Containers"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF"

              }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                avatarSceneDrawer.showContainers = !avatarSceneDrawer.showContainers
                if (avatarSceneDrawer.showContainers) { avatarSceneDrawer.showHelp = false; avatarSceneDrawer.showPresets = false }
              }
            }
          }

          // Profile Colors pill
          Rectangle {
            height: vpx(18); radius: vpx(9); width: hdrProfLbl.implicitWidth + vpx(14); anchors.verticalCenter: parent.verticalCenter
            color: root.avatarUseProfileColors ? root.accentRgba(0.40) : root.accentRgba(0.10)
            border.color: root.avatarUseProfileColors ? root.accentHex : root.accentRgba(0.25); border.width: vpx(1)

            Row { anchors.centerIn: parent; spacing: vpx(4)
              Rectangle { width: vpx(7); height: vpx(7); radius: vpx(4); anchors.verticalCenter: parent.verticalCenter
                color: root.accentHex; border.color: Qt.rgba(1,1,1,0.4); border.width: vpx(1) }
              StyledText { id: hdrProfLbl; text: "Profile Colors"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF"

              }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { root.avatarUseProfileColors=!root.avatarUseProfileColors; api.memory.set("cfg.avatarUseProfileColors",root.avatarUseProfileColors?"true":"false") }
            }
          }

          Rectangle { width: vpx(1); height: vpx(14); color: Qt.rgba(1,1,1,0.18); anchors.verticalCenter: parent.verticalCenter }

          // Sync Dark ✓/✕
          Component {
            id: syncToggleComp
            Row {
              property string lbl: ""; property string prop: ""; property string key: ""
              property color onColor: root.accentColor
              spacing: vpx(3); height: vpx(20)
              Rectangle {
                width: vpx(18); height: vpx(18); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                color: root[prop] ? Qt.rgba(onColor.r,onColor.g,onColor.b,0.28) : Qt.rgba(1,1,1,0.07)
                border.color: root[prop] ? onColor : Qt.rgba(1,1,1,0.22); border.width: vpx(1)

                StyledText { anchors.centerIn: parent; text: root[prop] ? "✓" : "✕"; font.pixelSize: vpx(10); font.bold: true
                  color: root[prop] ? onColor : "#888888"

                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { root[prop]=!root[prop]; api.memory.set(key, root[prop]?"true":"false") }
                }
              }
              StyledText { text: lbl; font.pixelSize: vpx(10); font.bold: true; color: "#CCCCCC"; anchors.verticalCenter: parent.verticalCenter

              }
            }
          }
          Loader { sourceComponent: syncToggleComp; onLoaded: { item.lbl="Sync Dark";   item.prop="avatarSyncDark";   item.key="cfg.avatarSyncDark" } }
          Rectangle { width: vpx(1); height: vpx(14); color: Qt.rgba(1,1,1,0.18); anchors.verticalCenter: parent.verticalCenter }
          Loader { sourceComponent: syncToggleComp; onLoaded: { item.lbl="Sync Panels"; item.prop="avatarSyncThemes"; item.key="cfg.avatarSyncThemes" } }
          Rectangle { width: vpx(1); height: vpx(14); color: Qt.rgba(1,1,1,0.18); anchors.verticalCenter: parent.verticalCenter }

          // ↺ Reset button
          Rectangle {
            width: vpx(20); height: vpx(20); radius: vpx(3)
            color: rstTitleMA.containsMouse ? Qt.rgba(0.8,0.1,0.1,0.50) : Qt.rgba(0.5,0.1,0.1,0.22)
            border.color: "#FF5555"; border.width: vpx(1)

            StyledText { anchors.centerIn: parent; text: "↺"; font.pixelSize: vpx(12); color: "#FF9999"; font.bold: true

            }
            MouseArea { id: rstTitleMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
              onClicked: avatarSceneDrawer.resetToDefaults()
            }
          }

          // Presets button
          Rectangle {
            width: presetsHdrLbl.implicitWidth + vpx(12); height: vpx(20); radius: vpx(3)
            color: avatarSceneDrawer.showPresets ? root.accentRgba(0.55) : root.accentRgba(0.15)
            border.color: avatarSceneDrawer.showPresets ? root.accentHex : root.accentRgba(0.45); border.width: vpx(1)

            StyledText { id: presetsHdrLbl; anchors.centerIn: parent; text: "Presets"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF"

            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { avatarSceneDrawer.showPresets = !avatarSceneDrawer.showPresets; avatarSceneDrawer.showHelp = false }
            }
          }

          // ℹ Info button
          Rectangle {
            width: vpx(20); height: vpx(20); radius: vpx(3)
            color: avatarSceneDrawer.showHelp ? root.accentRgba(0.45) : root.accentRgba(0.15)
            border.color: avatarSceneDrawer.showHelp ? root.accentHex : root.accentRgba(0.45); border.width: vpx(1)

            StyledText { anchors.centerIn: parent; text: "ℹ"; font.pixelSize: vpx(10); color: "#FFFFFF"; font.bold: true

            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { avatarSceneDrawer.showHelp = !avatarSceneDrawer.showHelp; avatarSceneDrawer.showPresets = false }
            }
          }

          // ✕ Close button
          Rectangle {
            width: vpx(20); height: vpx(20); radius: vpx(3)
            color: root.accentRgba(0.15); border.color: root.accentRgba(0.45); border.width: vpx(1)

            StyledText { anchors.centerIn: parent; text: "✕"; font.pixelSize: vpx(10); color: "#FFFFFF"; font.bold: true

            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.avatarSceneDrawerOpen = false }
          }
        }
      }
      Item { width: 1; height: vpx(3) }
      Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.35) }
      Item { width: 1; height: vpx(3) }

      // ── HELP OVERLAY ──────────────────────────────────────────────
      Item {
        width: parent.width
        height: avatarSceneDrawer.showHelp ? (avatarSceneDrawer.height - vpx(32)) : 0
        visible: avatarSceneDrawer.showHelp
        clip: true
        Flickable {
          anchors.fill: parent; contentHeight: helpCol.implicitHeight; clip: true
          boundsBehavior: Flickable.StopAtBounds
          Column {
            id: helpCol
            width: parent.width; spacing: vpx(5)
            Component {
              id: helpSection
              Item {
                property string title: ""; property string body: ""
                property string panelTag: ""
                width: parent ? parent.width : 200
                height: hRow.implicitHeight + vpx(4)
                Row {
                  id: hRow; width: parent.width; spacing: vpx(6)
                  Rectangle {
                    width: panelTag !== "" ? tagT.implicitWidth+vpx(8) : 0
                    height: vpx(14); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                    color: root.accentRgba(0.30); border.color: root.accentRgba(0.50); border.width: vpx(1)
                    visible: panelTag !== ""
                    StyledText { id: tagT; anchors.centerIn: parent; text: panelTag; font.pixelSize: vpx(9); font.bold: true; color: root.accentHex;
 }
                  }
                  StyledText {
                    text: "<b>" + title + "</b>  —  " + body
                    font.pixelSize: vpx(10); color: "#FFFFFF"; wrapMode: Text.WordWrap
                    width: parent.width - (panelTag !== "" ? tagT.implicitWidth+vpx(16)+vpx(6) : 0)

                  }
                }
              }
            }
            // Header legend pills
            Row { spacing: vpx(6)
              Rectangle {
                height: vpx(18); radius: vpx(4); width: line1Txt.implicitWidth + vpx(12)
                color: root.accentRgba(0.22); border.color: root.accentRgba(0.55); border.width: vpx(1)
                StyledText { id: line1Txt; anchors.centerIn: parent; text: "⬡ = Shared Global (affects both Avatar Scene AND Profile Panel)"; font.pixelSize: vpx(10); font.bold: true; color: root.accentHex;
 }
              }
            }
            Row { spacing: vpx(6)
              Rectangle {
                height: vpx(18); radius: vpx(4); width: line2Txt.implicitWidth + vpx(12)
                color: root.accentRgba(0.22); border.color: root.accentRgba(0.55); border.width: vpx(1)
                StyledText { id: line2Txt; anchors.centerIn: parent; text: "✓/✕ = Sync toggles  |  Color pills = independent toggles"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF";
 }
              }
            }
            Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Sync Original Dark → Avatar Scene"; item.body="When ✓, toggling Original Dark also flips avatarDarkOn so the Avatar Scene matches."; item.panelTag="Sync" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Sync with Themes Details Panels"; item.body="When ✓, toggling Original Dark also writes theme.themeGrad/accentGrad/libGrad so all panels update."; item.panelTag="Sync" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="System Colors"; item.body="Avatar Scene background uses the global system theme colour for fill, gradient and dark overlay layers."; item.panelTag="Color" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Profile Colors"; item.body="Avatar Scene uses the current profile accent colour for glow, border, spotlight and chip highlights."; item.panelTag="Color" } }
            Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Presets"; item.body="Apply a full preset to instantly set all Avatar Scene toggles and sliders. Tap again to deselect."; item.panelTag="Preset" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="↺ Reset"; item.body="Resets every Avatar Scene setting to factory defaults — all toggles on, all sliders default. Panels revert to using System Theme and Accent colours."; item.panelTag="Reset" } }
            Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.25) }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Original Dark";     item.body="Syncs theme dark overlay AND Avatar Scene dark mode together. Identical to toggling in Themes Details."; item.panelTag="⬡ Both" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Dark Mode";          item.body="Independent dark overlay for Avatar Scene only — doesn't affect Profile Panel.";              item.panelTag="Avatar" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Panel Gradient";     item.body="Master switch for the diagonal gradient fill behind Avatar Scene.";                          item.panelTag="Avatar" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="System Gradient";    item.body="Adds the system theme-colour diagonal gradient over the Avatar Scene background.";           item.panelTag="Avatar" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Profile Gradient";   item.body="Adds the profile accent-colour diagonal gradient over the Avatar Scene background.";         item.panelTag="Avatar" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Accent/Theme Glow";  item.body="Accent Glow = horizontal edge glow. Theme Glow = vertical top edge glow. Both use accent colour."; item.panelTag="Avatar" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Vignette";           item.body="Bottom-to-top dark gradient for contrast in the lower Avatar Scene.";                        item.panelTag="Avatar" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Hide Bg / Shadows";  item.body="Hide Bg removes the base fill rectangle. Drop Shadows enables text shadow effects.";         item.panelTag="Avatar" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Spotlight / Shapes"; item.body="Spotlight = radial glow behind the avatar. Shapes = animated floating accent shapes.";       item.panelTag="Avatar" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Avatar elements";    item.body="Avatar, Gamerpic, Gamerscore, Stat Pills, Gamertag, Borders — show or hide each element.";    item.panelTag="Avatar" } }
            Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.20) }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="Bg Opacity / Glow Mix"; item.body="Bg Opacity = opacity of solid base fill. Glow Mix = blends glow from black (0%) to accent (100%)."; item.panelTag="Avatar" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="⬡ Panel Fill / Grad Strength"; item.body="Panel Fill = base fill intensity globally. Grad Strength = diagonal theme gradient intensity globally."; item.panelTag="⬡ Both" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="⬡ Accent/Theme Glow Amt";    item.body="Sets intensity of accent glow (horizontal) and theme glow (vertical) on all panels globally.";     item.panelTag="⬡ Both" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="⬡ Accent Transp/Opac";       item.body="Transparency and Opacity of the accent colour globally — affects all panels.";                      item.panelTag="⬡ Both" } }
            Loader { sourceComponent: helpSection; width: parent.width; onLoaded: { item.title="⬡ Grad Transp/Opacity";      item.body="Transparency and Opacity of the accent gradient overlay on all panels globally.";                    item.panelTag="⬡ Both" } }
          }
        }
      }


      // ── CONTAINERS PAGE ──────────────────────────────────────────────
      Item {
        width: parent.width; height: vpx(200)
        visible: avatarSceneDrawer.showContainers
        clip: true

        Column {
          anchors.fill: parent; spacing: vpx(8)

          // Header row: On/Off + "None" clear
          Row {
            width: parent.width; height: vpx(22); spacing: vpx(8)
            StyledText {
              text: "Profile Card Container"; font.pixelSize: vpx(11); font.bold: true; color: root.accentHex
              anchors.verticalCenter: parent.verticalCenter

            }
            // On/Off toggle
            Rectangle {
              height: vpx(22); radius: vpx(11); width: contOnLbl.implicitWidth + vpx(16); anchors.verticalCenter: parent.verticalCenter
              color: root.containersOn ? root.accentRgba(0.45) : Qt.rgba(1,1,1,0.08)
              border.color: root.containersOn ? root.accentHex : Qt.rgba(1,1,1,0.20); border.width: vpx(1)

              Row { anchors.centerIn: parent; spacing: vpx(5)
                Rectangle { width: vpx(6); height: vpx(6); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                  color: root.containersOn ? "#44FF44" : "#888888" }
                StyledText { id: contOnLbl; text: root.containersOn ? "Enabled" : "Disabled"; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF"

                }
              }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: { root.containersOn = !root.containersOn; api.memory.set("cfg.containersOn", root.containersOn ? "true" : "false") }
              }
            }
            // None / Clear button
            Rectangle {
              height: vpx(22); radius: vpx(11); width: contNoneLbl.implicitWidth + vpx(16); anchors.verticalCenter: parent.verticalCenter
              color: root.containerIndex === 0 ? root.accentRgba(0.35) : Qt.rgba(1,1,1,0.08)
              border.color: root.containerIndex === 0 ? root.accentHex : Qt.rgba(1,1,1,0.20); border.width: vpx(1)

              StyledText { id: contNoneLbl; anchors.centerIn: parent; text: "✕  None"; font.pixelSize: vpx(10); font.bold: true
                color: root.containerIndex === 0 ? "#FFFFFF" : "#888888"

              }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: { root.containerIndex = 0; api.memory.set("cfg.containerIndex", "0") }
              }
            }
          }

          // Container thumbnail grid (2 rows of 6)
          Grid {
            columns: 6; width: parent.width; spacing: vpx(5)
            Repeater {
              model: [
                { idx:1,  lbl:"Panel Button" },
                { idx:2,  lbl:"Rect Glass 0" },
                { idx:3,  lbl:"Rect Glass 1" },
                { idx:4,  lbl:"Rect Glass 2" },
                { idx:5,  lbl:"Rect Glass 3" },
                { idx:6,  lbl:"Thumb Mask" },
                { idx:7,  lbl:"Rect Kin 0" },
                { idx:8,  lbl:"Panel Btn Wht" },
                { idx:9,  lbl:"Small Wht Blk" },
                { idx:10, lbl:"Panel List Sq" },
                { idx:11, lbl:"Rect Glass 2B" },
                { idx:12, lbl:"Rect Glass 4" }
              ]
              delegate: Item {
                property bool isSel: root.containerIndex === modelData.idx
                width: (parent.width - 5*vpx(5)) / 6; height: vpx(58)

                Rectangle {
                  anchors.fill: parent; radius: vpx(5)
                  color: isSel ? root.accentRgba(0.35) : Qt.rgba(1,1,1,0.06)
                  border.color: isSel ? root.accentHex : Qt.rgba(1,1,1,0.18)
                  border.width: isSel ? vpx(2) : vpx(1)
                  clip: true

                  // Thumbnail image
                  Image {
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: parent.top; height: vpx(40)
                    source: root.containerImages[modelData.idx]
                    fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                    opacity: 0.90
                  }

                  // Label below thumbnail — white, full title
                  StyledText {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: vpx(2)
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: vpx(2); anchors.rightMargin: vpx(2)
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData.lbl; font.pixelSize: vpx(9); font.bold: isSel
                    color: isSel ? root.accentHex : "#FFFFFF"
                    elide: Text.ElideNone; wrapMode: Text.NoWrap
                  }

                  // Selected accent dot top-right
                  Rectangle {
                    visible: isSel
                    width: vpx(6); height: vpx(6); radius: vpx(3); color: root.accentHex
                    anchors.top: parent.top; anchors.right: parent.right; anchors.margins: vpx(3)
                  }
                }

                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { root.containerIndex = modelData.idx; api.memory.set("cfg.containerIndex", modelData.idx.toString()) }
                }
              }
            }
          }
        }
      }


      // ── CONTROLS (visible when showHelp=false and showPresets=false) ────
      Column {
        width: parent.width
        height: vpx(110)
        spacing: vpx(4)
        visible: !avatarSceneDrawer.showHelp && !avatarSceneDrawer.showPresets && !avatarSceneDrawer.showContainers

        // ══ ROW 1: Toggle chips ══════════════════════════════════════
        Item {
          width: parent.width; height: vpx(26); clip: false
          Flow {
            anchors.top: parent.top; anchors.topMargin: vpx(0)
            anchors.left: parent.left; anchors.right: parent.right
            spacing: vpx(5)
            Repeater {
              model: [
                { label:"Original Dark",    key:"theme.themeDark",       prop:"themeDarkOn",      syncKey:"cfg.avatarDark", syncProp:"avatarDarkOn" },
                { label:"Dark Mode",        key:"cfg.avatarDark",        prop:"avatarDarkOn"        },
                { label:"Panel Gradient",   key:"cfg.avatarPanelGrad",   prop:"avatarPanelGradOn"   },
                { label:"System Gradient",  key:"cfg.avatarSystemGrad",  prop:"avatarSystemGradOn"  },
                { label:"Profile Gradient", key:"cfg.avatarProfileGrad", prop:"avatarProfileGradOn" },
                { label:"Accent Glow",      key:"cfg.avatarAccentGrad",  prop:"avatarAccentGradOn"  },
                { label:"Theme Glow",       key:"cfg.avatarThemeGrad",   prop:"avatarThemeGradOn"   },
                { label:"Vignette",         key:"cfg.avatarVignette",    prop:"avatarVignette"      },
                { label:"Hide Background",  key:"cfg.avatarHideBg",      prop:"avatarHideBg"        },
                { label:"Shadows",          key:"cfg.avatarDropShadow",  prop:"avatarDropShadow"    },
                { label:"Spotlight",        key:"cfg.avatarSpotlight",   prop:"avatarSpotlightOn"   },
                { label:"Shapes",           key:"cfg.avatarShapes",      prop:"avatarShapesOn"      }
              ]
              delegate: Rectangle {
                property bool chipOn: root[modelData.prop]
                height: vpx(20); radius: vpx(10); width: chipLbl.implicitWidth + vpx(16)
                color: chipOn ? root.accentRgba(0.50) : root.accentRgba(0.12)
                border.color: chipOn ? root.accentHex : root.accentRgba(0.28); border.width: vpx(1)

                Row { anchors.centerIn: parent; spacing: vpx(4)
                  Rectangle { width: vpx(5); height: vpx(5); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                    color: parent.parent.chipOn ? "#44FF44" : root.accentRgba(0.35) }
                  StyledText { id: chipLbl; text: modelData.label; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"

                  }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root[modelData.prop]=!root[modelData.prop]
                    api.memory.set(modelData.key,root[modelData.prop]?"true":"false")
                    if(typeof modelData.syncProp !== "undefined" && modelData.syncProp !== "") {
                      if(root.avatarSyncDark) {
                        root[modelData.syncProp]=root[modelData.prop]
                        api.memory.set(modelData.syncKey,root[modelData.prop]?"true":"false")
                      }
                      if(root.avatarSyncThemes) {
                        var v=root[modelData.prop]
                        api.memory.set("theme.themeGrad",  v?"true":"false")
                        api.memory.set("theme.accentGrad", v?"true":"false")
                        api.memory.set("theme.libGrad",    v?"true":"false")
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // ══ SLIDER COMPONENT ═══════════════════════════════════════════
        Component {
          id: ascSlider
          Item {
            property string lbl: ""; property string key: ""; property string prop: ""; property bool isGlobal: false
            Column { anchors.fill: parent; spacing: vpx(2)
              Row { spacing: vpx(4)
                StyledText { text: lbl; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"

                }
                StyledText { text: prop !== "" ? Math.round(root[prop])+"%" : ""; font.pixelSize: vpx(11); color: root.accentHex; font.bold: true

                }
              }
              Row { width: parent.width; height: vpx(20); spacing: vpx(3)
                Rectangle { width: vpx(18); height: vpx(18); radius: vpx(9); anchors.verticalCenter: parent.verticalCenter
                  color: root.accentHex; border.color: root.accentRgba(0.55); border.width: vpx(1)

                  StyledText { anchors.centerIn: parent; text: "−"; font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF"

                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked:      { if(prop!==""){var v=Math.max(0,root[prop]-1); root[prop]=v; api.memory.set(key,v.toString())} }
                    onPressAndHold: { if(prop!==""){var v=Math.max(0,root[prop]-5); root[prop]=v; api.memory.set(key,v.toString())} }
                  }
                }
                Item { width: parent.width-vpx(46); height: parent.height; anchors.verticalCenter: parent.verticalCenter
                  Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: vpx(4); radius: vpx(2); color: root.accentRgba(0.22)
                    Rectangle { width: prop!==""?parent.width*(root[prop]/100):0; height: parent.height; radius: parent.radius; color: root.accentHex }
                  }
                  Rectangle {
                    width: vpx(12); height: vpx(12); radius: vpx(6); color: root.accentHex; border.color: "#FFFFFF"; border.width: vpx(2)
                    anchors.verticalCenter: parent.verticalCenter
                    x: prop!==""?Math.max(0,Math.min(parent.width-vpx(12),(root[prop]/100)*(parent.width-vpx(12)))):0

                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked:        { if(prop!==""){var v=Math.max(0,Math.min(100,Math.round(mouseX/width*100))); root[prop]=v; api.memory.set(key,v.toString())} }
                    onPositionChanged:{ if(pressed&&prop!==""){var v=Math.max(0,Math.min(100,Math.round(mouseX/width*100))); root[prop]=v; api.memory.set(key,v.toString())} }
                  }
                }
                Rectangle { width: vpx(18); height: vpx(18); radius: vpx(9); anchors.verticalCenter: parent.verticalCenter
                  color: root.accentHex; border.color: root.accentRgba(0.55); border.width: vpx(1)

                  StyledText { anchors.centerIn: parent; text: "+"; font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF"

                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked:      { if(prop!==""){var v=Math.min(100,root[prop]+1); root[prop]=v; api.memory.set(key,v.toString())} }
                    onPressAndHold: { if(prop!==""){var v=Math.min(100,root[prop]+5); root[prop]=v; api.memory.set(key,v.toString())} }
                  }
                }
              }
            }
          }
        }

        // Row 3a — 5 sliders
        Row {
          width: parent.width; height: vpx(38); spacing: vpx(4)
          Loader { sourceComponent: ascSlider; width: (parent.width-vpx(16))/5; height: parent.height; onLoaded: { item.lbl="Bg Opacity";      item.key="cfg.avatarBgOpacity";    item.prop="avatarBgOpacity";    item.isGlobal=false } }
          Loader { sourceComponent: ascSlider; width: (parent.width-vpx(16))/5; height: parent.height; onLoaded: { item.lbl="Glow Mix";        item.key="cfg.avatarGlowColorMix"; item.prop="avatarGlowColorMix"; item.isGlobal=false } }
          Loader { sourceComponent: ascSlider; width: (parent.width-vpx(16))/5; height: parent.height; onLoaded: { item.lbl="⬡ Panel Fill";    item.key="cfg.panelBaseAlpha";     item.prop="panelBaseAlpha";     item.isGlobal=true  } }
          Loader { sourceComponent: ascSlider; width: (parent.width-vpx(16))/5; height: parent.height; onLoaded: { item.lbl="⬡ Grad Strength"; item.key="cfg.gradientStrength";   item.prop="gradientStrength";   item.isGlobal=true  } }
          Loader { sourceComponent: ascSlider; width: (parent.width-vpx(16))/5; height: parent.height; onLoaded: { item.lbl="⬡ Accent Glow";   item.key="cfg.accentGradAlpha";    item.prop="accentGradAlpha";    item.isGlobal=true  } }
        }
        // Row 3b — 5 sliders + shadow radius
        Row {
          width: parent.width; height: vpx(38); spacing: vpx(4)
          Loader { sourceComponent: ascSlider; width: (parent.width-vpx(20))/6; height: parent.height; onLoaded: { item.lbl="⬡ Theme Glow";   item.key="cfg.themeGradAlpha";     item.prop="themeGradAlpha";     item.isGlobal=true  } }
          Loader { sourceComponent: ascSlider; width: (parent.width-vpx(20))/6; height: parent.height; onLoaded: { item.lbl="⬡ Acc Transp";   item.key="cfg.accentTransparency"; item.prop="accentTransparency"; item.isGlobal=true  } }
          Loader { sourceComponent: ascSlider; width: (parent.width-vpx(20))/6; height: parent.height; onLoaded: { item.lbl="⬡ Acc Opacity";  item.key="cfg.accentOpacity";      item.prop="accentOpacity";      item.isGlobal=true  } }
          Loader { sourceComponent: ascSlider; width: (parent.width-vpx(20))/6; height: parent.height; onLoaded: { item.lbl="⬡ Grad Transp";  item.key="cfg.accentGradTransp";   item.prop="accentGradTransp";   item.isGlobal=true  } }
          Loader { sourceComponent: ascSlider; width: (parent.width-vpx(20))/6; height: parent.height; onLoaded: { item.lbl="⬡ Grad Opacity"; item.key="cfg.accentGradOpacity";  item.prop="accentGradOpacity";  item.isGlobal=true  } }
          // Shadow radius slider — same style, inline
          Item {
            width: (parent.width-vpx(20))/6; height: parent.height
            Column { anchors.fill: parent; spacing: vpx(2)
              Row { spacing: vpx(4)
                StyledText { text: "Shadows"; font.pixelSize: vpx(11); font.bold: true; color: root.accentHex

                }
                StyledText { text: Math.round(root.globalShadowRadius)+"px"; font.pixelSize: vpx(11); color: "#FFFFFF"; font.bold: true

                }
              }
              Row { width: parent.width; height: vpx(20); spacing: vpx(3)
                Rectangle { width: vpx(18); height: vpx(18); radius: vpx(9); anchors.verticalCenter: parent.verticalCenter
                  color: root.accentHex; border.color: root.accentRgba(0.55); border.width: vpx(1)

                  StyledText { anchors.centerIn: parent; text: "−"; font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF"

                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked:      { var v=Math.max(1,root.globalShadowRadius-1); root.globalShadowRadius=v; api.memory.set("cfg.shadowRadius",v.toString()) }
                    onPressAndHold: { var v=Math.max(1,root.globalShadowRadius-2); root.globalShadowRadius=v; api.memory.set("cfg.shadowRadius",v.toString()) }
                  }
                }
                Item { width: parent.width-vpx(46); height: parent.height; anchors.verticalCenter: parent.verticalCenter
                  Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: vpx(4); radius: vpx(2); color: root.accentRgba(0.22)
                    Rectangle { width: parent.width*((root.globalShadowRadius-1)/11); height: parent.height; radius: parent.radius; color: root.accentHex }
                  }
                  Rectangle {
                    width: vpx(12); height: vpx(12); radius: vpx(6); color: root.accentHex; border.color: "#FFFFFF"; border.width: vpx(2)
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0,Math.min(parent.width-vpx(12),((root.globalShadowRadius-1)/11)*(parent.width-vpx(12))))

                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked:        { var v=Math.max(1,Math.min(12,Math.round(mouseX/width*11)+1)); root.globalShadowRadius=v; api.memory.set("cfg.shadowRadius",v.toString()) }
                    onPositionChanged:{ if(pressed){ var v=Math.max(1,Math.min(12,Math.round(mouseX/width*11)+1)); root.globalShadowRadius=v; api.memory.set("cfg.shadowRadius",v.toString()) } }
                  }
                }
                Rectangle { width: vpx(18); height: vpx(18); radius: vpx(9); anchors.verticalCenter: parent.verticalCenter
                  color: root.accentHex; border.color: root.accentRgba(0.55); border.width: vpx(1)

                  StyledText { anchors.centerIn: parent; text: "+"; font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF"

                  }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked:      { var v=Math.min(12,root.globalShadowRadius+1); root.globalShadowRadius=v; api.memory.set("cfg.shadowRadius",v.toString()) }
                    onPressAndHold: { var v=Math.min(12,root.globalShadowRadius+2); root.globalShadowRadius=v; api.memory.set("cfg.shadowRadius",v.toString()) }
                  }
                }
              }
            }
          }
        }
      }

      // ── PRESETS PAGE ──────────────────────────────────────────────
      Item {
        id: presetsItem
        width: parent.width; height: vpx(178)
        visible: !avatarSceneDrawer.showHelp && avatarSceneDrawer.showPresets
        clip: true

        // Custom preset state — stored as JSON in api.memory
        property var customPresets: []
        property int editingIndex: -1       // -1 = none; ≥0 = renaming that custom index
        property string editingName: ""
        property bool showNameInput: false  // shows new preset name input row

        function loadCustomPresets() {
          var raw = api.memory.get("cfg.customPresets") || "[]"
          try { customPresets = JSON.parse(raw) } catch(e) { customPresets = [] }
        }
        function saveCustomPresets() {
          api.memory.set("cfg.customPresets", JSON.stringify(customPresets))
        }
        function captureCurrentState() {
          return {
            darkOn: root.avatarDarkOn, panelGrad: root.avatarPanelGradOn,
            systemGrad: root.avatarSystemGradOn, profileGrad: root.avatarProfileGradOn,
            accentGrad: root.avatarAccentGradOn, themeGrad: root.avatarThemeGradOn,
            vignette: root.avatarVignette, hideBg: root.avatarHideBg,
            dropShadow: root.avatarDropShadow, spotlight: root.avatarSpotlightOn,
            shapes: root.avatarShapesOn, bgOpacity: root.avatarBgOpacity,
            glowMix: root.avatarGlowColorMix, panelFill: root.panelBaseAlpha,
            gradStr: root.gradientStrength, accentGlow: root.accentGradAlpha,
            themeGlow: root.themeGradAlpha
          }
        }
        function applyCustomPreset(idx) {
          var d = customPresets[idx].state
          function s(key,prop,v){root[prop]=v; api.memory.set(key,v?"true":"false")}
          function n(key,prop,v){root[prop]=v; api.memory.set(key,v.toString())}
          s("cfg.avatarDark","avatarDarkOn",d.darkOn); s("cfg.avatarPanelGrad","avatarPanelGradOn",d.panelGrad)
          s("cfg.avatarSystemGrad","avatarSystemGradOn",d.systemGrad); s("cfg.avatarProfileGrad","avatarProfileGradOn",d.profileGrad)
          s("cfg.avatarAccentGrad","avatarAccentGradOn",d.accentGrad); s("cfg.avatarThemeGrad","avatarThemeGradOn",d.themeGrad)
          s("cfg.avatarVignette","avatarVignette",d.vignette); s("cfg.avatarHideBg","avatarHideBg",d.hideBg)
          s("cfg.avatarDropShadow","avatarDropShadow",d.dropShadow); s("cfg.avatarSpotlight","avatarSpotlightOn",d.spotlight)
          s("cfg.avatarShapes","avatarShapesOn",d.shapes)
          n("cfg.avatarBgOpacity","avatarBgOpacity",d.bgOpacity); n("cfg.avatarGlowColorMix","avatarGlowColorMix",d.glowMix)
          n("cfg.panelBaseAlpha","panelBaseAlpha",d.panelFill); n("cfg.gradientStrength","gradientStrength",d.gradStr)
          n("cfg.accentGradAlpha","accentGradAlpha",d.accentGlow); n("cfg.themeGradAlpha","themeGradAlpha",d.themeGlow)
        }
        Component.onCompleted: loadCustomPresets()

        Column {
          anchors.fill: parent; spacing: vpx(4)

          // ── Built-in presets ────────────────────────────────────────
          Flow {
            width: parent.width; spacing: vpx(5)
            Repeater {
              model: [
                { name:"Green Classic", col:"#1e5c12", idx:0 },
                { name:"Neon Teal",     col:"#0b6b60", idx:1 },
                { name:"Biohazard",     col:"#7a1212", idx:2 },
                { name:"Cortana",       col:"#2d2070", idx:3 },
                { name:"Hot Pink",      col:"#8c1558", idx:4 },
                { name:"Dark Slate",    col:"#141420", idx:5 },
                { name:"Profile Orange",col:"#7a3a0a", idx:6 },
                { name:"Cortana Gallery",col:"#1a2a5c", idx:7 },
                { name:"Dark Showcase",  col:"#0d1a3a", idx:8 },
                { name:"Airy Light",     col:"#3a6e3a", idx:9 },
                { name:"Xbox Blade",     col:"#1a1a1a", idx:10 },
                { name:"NXE Warm",       col:"#3a2800", idx:11 },
                { name:"Military Ops",   col:"#2a3a00", idx:12 }
              ]
              delegate: Rectangle {
                property bool isActive: avatarSceneDrawer.activePreset === modelData.idx
                height: vpx(24); radius: vpx(12); width: biLbl.implicitWidth + vpx(20)
                color: isActive ? root.accentRgba(0.55) : Qt.rgba(
                  parseInt(modelData.col.substr(1,2),16)/255,
                  parseInt(modelData.col.substr(3,2),16)/255,
                  parseInt(modelData.col.substr(5,2),16)/255, 0.88)
                border.color: isActive ? root.accentHex : Qt.rgba(1,1,1,0.22); border.width: vpx(1)

                Row { anchors.centerIn: parent; spacing: vpx(5)
                  Rectangle { width: vpx(6); height: vpx(6); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                    color: isActive ? "#44FF44" : Qt.rgba(1,1,1,0.40) }
                  StyledText { id: biLbl; text: modelData.name; font.pixelSize: vpx(11); font.bold: isActive; color: "#FFFFFF"

                  }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: avatarSceneDrawer.applyPreset(avatarSceneDrawer.activePreset === modelData.idx ? -1 : modelData.idx)
                }
              }
            }
          }

          // ── Separator ───────────────────────────────────────────────
          Rectangle { width: parent.width; height: vpx(1); color: root.accentRgba(0.30) }

          // ── Custom presets header row ────────────────────────────────
          Row { width: parent.width; height: vpx(22); spacing: vpx(6)
            StyledText { text: "My Presets"; font.pixelSize: vpx(11); font.bold: true; color: root.accentHex; anchors.verticalCenter: parent.verticalCenter

            }
            // Save current as new preset button
            Rectangle {
              height: vpx(22); radius: vpx(11); width: saveNewLbl.implicitWidth + vpx(18); anchors.verticalCenter: parent.verticalCenter
              color: presetsItem.showNameInput ? root.accentRgba(0.50) : root.accentRgba(0.18)
              border.color: root.accentHex; border.width: vpx(1)

              Row { anchors.centerIn: parent; spacing: vpx(4)
                StyledText { text: "+"; font.pixelSize: vpx(13); font.bold: true; color: root.accentHex; layer.enabled: false }
                StyledText { id: saveNewLbl; text: "Save Current"; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"

                }
              }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  presetsItem.editingIndex = -1
                  presetsItem.editingName = "My Preset " + (presetsItem.customPresets.length + 1)
                  presetsItem.showNameInput = !presetsItem.showNameInput
                }
              }
            }
          }

          // ── Name input row (save new / rename) ──────────────────────
          Row {
            width: parent.width; height: vpx(26); spacing: vpx(6)
            visible: presetsItem.showNameInput

            Rectangle {
              width: parent.width - vpx(100); height: vpx(24); radius: vpx(4)
              color: Qt.rgba(1,1,1,0.08); border.color: root.accentRgba(0.55); border.width: vpx(1)
              TextInput {
                anchors.fill: parent; anchors.margins: vpx(6)
                text: presetsItem.editingName
                font.pixelSize: vpx(11); color: "#FFFFFF"; selectionColor: root.accentHex
                onTextChanged: presetsItem.editingName = text
                Keys.onReturnPressed: confirmBtn.clicked()
                Keys.onEscapePressed: presetsItem.showNameInput = false
              }
            }
            Rectangle {
              id: confirmBtn
              property bool pressed2: false
              height: vpx(24); radius: vpx(12); width: confLbl.implicitWidth + vpx(18)
              color: root.accentRgba(0.55); border.color: root.accentHex; border.width: vpx(1)

              StyledText { id: confLbl; text: presetsItem.editingIndex >= 0 ? "Rename" : "Save"; anchors.centerIn: parent; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"

              }
              signal clicked()
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: confirmBtn.clicked() }
              onClicked: {
                var name = presetsItem.editingName.trim()
                if (name === "") return
                if (presetsItem.editingIndex >= 0) {
                  // Rename existing
                  var arr = presetsItem.customPresets.slice()
                  arr[presetsItem.editingIndex].name = name
                  presetsItem.customPresets = arr
                } else {
                  // Save new
                  var arr2 = presetsItem.customPresets.slice()
                  arr2.push({ name: name, state: presetsItem.captureCurrentState() })
                  presetsItem.customPresets = arr2
                }
                presetsItem.saveCustomPresets()
                presetsItem.showNameInput = false
                presetsItem.editingIndex = -1
              }
            }
            Rectangle {
              height: vpx(24); radius: vpx(12); width: cancelLbl.implicitWidth + vpx(18)
              color: Qt.rgba(0.4,0.1,0.1,0.30); border.color: Qt.rgba(1,0.3,0.3,0.55); border.width: vpx(1)
              StyledText { id: cancelLbl; text: "Cancel"; anchors.centerIn: parent; font.pixelSize: vpx(11); font.bold: true; color: "#FFAAAA"; layer.enabled: false }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: { presetsItem.showNameInput = false; presetsItem.editingIndex = -1 }
              }
            }
          }

          // ── Custom presets list ─────────────────────────────────────
          Flickable {
            width: parent.width
            height: vpx(60)
            contentHeight: customFlow.implicitHeight
            clip: true; boundsBehavior: Flickable.StopAtBounds
            Flow {
              id: customFlow
              width: parent.width; spacing: vpx(5)
              Repeater {
                model: presetsItem.customPresets
                delegate: Rectangle {
                  height: vpx(24); radius: vpx(12); width: cusRow.implicitWidth + vpx(10)
                  color: root.accentRgba(0.18)
                  border.color: root.accentRgba(0.45); border.width: vpx(1)

                  Row {
                    id: cusRow; anchors.centerIn: parent; spacing: vpx(4)
                    // Apply
                    StyledText { text: modelData.name; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"

                    }
                    // Rename pencil
                    Rectangle {
                      width: vpx(16); height: vpx(16); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                      color: Qt.rgba(1,1,1,0.10); border.color: Qt.rgba(1,1,1,0.25); border.width: vpx(1)
                      StyledText { anchors.centerIn: parent; text: "✎"; font.pixelSize: vpx(10); color: "#CCCCCC"; layer.enabled: false }
                      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          presetsItem.editingIndex = index
                          presetsItem.editingName = modelData.name
                          presetsItem.showNameInput = true
                        }
                      }
                    }
                    // Delete ✕
                    Rectangle {
                      width: vpx(16); height: vpx(16); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                      color: Qt.rgba(0.7,0.1,0.1,0.30); border.color: Qt.rgba(1,0.3,0.3,0.40); border.width: vpx(1)
                      StyledText { anchors.centerIn: parent; text: "✕"; font.pixelSize: vpx(9); color: "#FF9999"; layer.enabled: false }
                      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          var arr = presetsItem.customPresets.slice()
                          arr.splice(index, 1)
                          presetsItem.customPresets = arr
                          presetsItem.saveCustomPresets()
                        }
                      }
                    }
                  }
                  MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    // click the pill itself (not child buttons) to apply
                    onClicked: { if (!containsMouse) return; presetsItem.applyCustomPreset(index) }
                    propagateComposedEvents: true
                  }
                }
              }
            }
          }

          // Empty state
          StyledText {
            visible: presetsItem.customPresets.length === 0 && !presetsItem.showNameInput
            text: "No saved presets yet — click  + Save Current  to save your settings"
            font.pixelSize: vpx(10); color: "#888888"; width: parent.width; wrapMode: Text.WordWrap
            layer.enabled: false
          }
        }
      }


    }
  }

  // ════════════════════════════════════════════════════════════════

  // PANELS LIST
  // ════════════════════════════════════════════════════════════════
  PanelsList {
    id: panelsList
    pageKey: "gp_"
    contentType: Enums.PanelContentTypes.Content

    model: ListModel {
      id: panelsModel
      ListElement { type: "profile";  slotNum: 0 }
      // avatarscene entries added dynamically by rebuildPanels()
    }

    anchors.top: parent.top
    anchors.topMargin: root.avatarSceneDrawerOpen
                         ? avatarSceneDrawer.y + avatarSceneDrawer.height + vpx(8)
                         : vpx(105)
    Behavior on anchors.topMargin { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    anchors.bottomMargin: vpx(80)
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: vpx(98)
    // Tell PanelsList how much we are inset so center-relative layouts
    // (Uniflow, BigBox, Flat Center) compute the correct screen midpoint.
    screenOriginX: vpx(98)

    onCurrentIndexChanged: {
      if (currentIndex === 0) {
        // Profile panel — Select = jump to avatar scene
        setAvailableActions({
          [Enums.ActionKeys.Bottom]: { label: "Select", visible: true },
          [Enums.ActionKeys.Right]:  { label: "Back",   visible: true },
          [Enums.ActionKeys.Top]:    { label: "Layout",  visible: true }
        })
      } else {
        // Avatar scene panel — Select = enter profile scene, Y = back to profile list
        setAvailableActions({
          [Enums.ActionKeys.Bottom]: { label: "Select", visible: true  },
          [Enums.ActionKeys.Right]:  { label: "Back",   visible: true  },
          [Enums.ActionKeys.Top]:    { label: "Layout",  visible: true  }
        })
      }
    }

    Component.onCompleted: {
      // Ensure actions are set correctly on first load (index starts at 0)
      setAvailableActions({
        [Enums.ActionKeys.Bottom]: { label: "Select", visible: true },
        [Enums.ActionKeys.Right]:  { label: "Back",   visible: true },
        [Enums.ActionKeys.Top]:    { label: "Layout",  visible: true }
      })
    }

    delegate: PanelWrapper {
      // Avatar scene is 2× wider
      property bool isScene: (model.type === "avatarscene" || model.type === "profilecard")

      Rectangle {
        id: panelDelegateRoot
        width:  parent.width
        height: parent.height
        color: "transparent"

        // ── Staggered fade-in ─────────────────────────────────────────
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Timer {
          interval: 60 + (index * 80)
          running: true; repeat: false
          onTriggered: panelDelegateRoot.opacity = 1
        }

        // ── Shimmer placeholder — visible while Loader is still working ──
        Rectangle {
          id: shimmerPlaceholder
          anchors.fill: parent
          radius: vpx(6)
          color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.06)
          border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)
          border.width: vpx(1)
          opacity: loader.status !== Loader.Ready ? 1 : 0
          visible: opacity > 0
          Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.InCubic } }
          clip: true

          Item {
            id: shimmerBar
            width: parent.width * 0.45; height: parent.height; x: -width
            LinearGradient {
              anchors.fill: parent
              start: Qt.point(0, 0); end: Qt.point(width, 0)
              gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.10) }
                GradientStop { position: 1.0; color: "transparent" }
              }
            }
            SequentialAnimation on x {
              running: shimmerPlaceholder.visible; loops: Animation.Infinite
              NumberAnimation { to: shimmerPlaceholder.width; duration: 900; easing.type: Easing.InOutSine }
              PauseAnimation  { duration: 300 }
              PropertyAction  { value: -shimmerBar.width }
            }
          }

          Rectangle {
            width: vpx(6); height: vpx(6); radius: vpx(3)
            anchors.top: parent.top; anchors.topMargin: vpx(10)
            anchors.left: parent.left; anchors.leftMargin: vpx(10)
            color: root.accentHex
            SequentialAnimation on opacity {
              running: shimmerPlaceholder.visible; loops: Animation.Infinite
              NumberAnimation { to: 0.2; duration: 600; easing.type: Easing.InOutSine }
              NumberAnimation { to: 0.9; duration: 600; easing.type: Easing.InOutSine }
            }
          }
        }

        // ══════════════════════════════════════════════════════════════
        // EDIT PROFILE PANEL (slotNum=0) — system theme/accent, NEVER
        // affected by Appearance tab. Identical to original uploaded file.
        // ══════════════════════════════════════════════════════════════
        Rectangle { anchors.fill:parent; color:root.themeDark; visible: model.slotNum===0 && root.themeDarkOn }
        LinearGradient {
          visible: model.slotNum===0 && root.themeDarkOn && root.panelGradient; anchors.fill:parent
          start:Qt.point(0,0); end:Qt.point(width,height)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(root.themeDark.r,root.themeDark.g,root.themeDark.b,0.97) }
            GradientStop { position:0.6; color:Qt.rgba(root.themeDark.r*.7,root.themeDark.g*.7,root.themeDark.b*.7,0.97) }
            GradientStop { position:1.0; color:Qt.rgba(root.themeDark.r*.5,root.themeDark.g*.5,root.themeDark.b*.5,0.97) }
          }
        }
        LinearGradient {
          visible: model.slotNum===0 && root.themeDarkOn && root.panelGradient; anchors.fill:parent
          start:Qt.point(0,height); end:Qt.point(0,0)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(0,0,0,0.18) }
            GradientStop { position:1.0; color:Qt.rgba(0,0,0,0.0) }
          }
        }
        LinearGradient {
          visible: model.slotNum===0 && root.themeDarkOn && root.panelGradient && root.gradAccentOn; anchors.fill:parent
          start:Qt.point(0,0); end:Qt.point(width,0)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.12) }
            GradientStop { position:1.0; color:"transparent" }
          }
        }
        LinearGradient {
          visible: model.slotNum===0 && root.themeDarkOn && root.panelGradient && root.gradThemeOn; anchors.fill:parent
          start:Qt.point(0,0); end:Qt.point(0,height)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.08) }
            GradientStop { position:1.0; color:"transparent" }
          }
        }
        Rectangle { anchors.fill:parent; color:root.themeFill; visible: model.slotNum===0 && !root.themeDarkOn && !root.panelGradient }
        LinearGradient {
          visible: model.slotNum===0 && !root.themeDarkOn && root.panelGradient && root.gradThemeOn; anchors.fill:parent
          start:Qt.point(0,0); end:Qt.point(width,height)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(root.themeFill.r,root.themeFill.g,root.themeFill.b,root.panelAlpha) }
            GradientStop { position:0.6; color:Qt.rgba(root.themeFill.r*.7,root.themeFill.g*.7,root.themeFill.b*.7,root.panelAlpha) }
            GradientStop { position:1.0; color:Qt.rgba(root.themeFill.r*.5,root.themeFill.g*.5,root.themeFill.b*.5,root.panelAlpha) }
          }
        }
        LinearGradient {
          visible: model.slotNum===0 && !root.themeDarkOn && root.panelGradient; anchors.fill:parent
          start:Qt.point(0,height); end:Qt.point(0,0)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(0,0,0,0.18) }
            GradientStop { position:1.0; color:Qt.rgba(0,0,0,0.0) }
          }
        }
        LinearGradient {
          visible: model.slotNum===0 && !root.themeDarkOn && root.panelGradient && root.gradAccentOn; anchors.fill:parent
          start:Qt.point(0,0); end:Qt.point(width,0)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.12) }
            GradientStop { position:1.0; color:"transparent" }
          }
        }
        LinearGradient {
          visible: model.slotNum===0 && !root.themeDarkOn && root.panelGradient && root.gradThemeOn; anchors.fill:parent
          start:Qt.point(0,0); end:Qt.point(0,height)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.08) }
            GradientStop { position:1.0; color:"transparent" }
          }
        }

        // ══════════════════════════════════════════════════════════════
        // AVATAR SCENE PANELS (slotNum>0) — fully controlled by
        // Appearance tab sliders. Accent colour = profile saved color.
        // All visible conditions check model.slotNum > 0 at Item level
        // so model context property is always in scope.
        // ══════════════════════════════════════════════════════════════

        // Read avatar accent hex at Item level where model is in scope
        Item {
          anchors.fill: parent
          visible: model.slotNum > 0

          // Profile saved accent color — read from memory, refreshed by timer
          // avatarAccentHex is a reactive string — GradientStops reference it directly
          property string avatarAccentHex: {
            var c = api.memory.get("profile.slot." + model.slotNum + ".color") || ""
            return (c.length === 7 && c.charAt(0) === "#") ? c : root.accentHex
          }
          Timer {
            interval: 400; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
              var c = api.memory.get("profile.slot." + model.slotNum + ".color") || ""
              parent.avatarAccentHex = (c.length === 7 && c.charAt(0) === "#") ? c : root.accentHex
            }
          }

          // ── Dark mode ──
          Rectangle {
            anchors.fill: parent; visible: root.avatarDarkOn && !root.avatarHideBg && root.avatarBgOpacity > 0
            color: Qt.rgba(
              parseInt(root.themeHex.substr(1,2),16)/255,
              parseInt(root.themeHex.substr(3,2),16)/255,
              parseInt(root.themeHex.substr(5,2),16)/255,
              Math.max(0, Math.min(0.92, (root.panelBaseAlpha/100) * (root.avatarBgOpacity/100))))
          }
          // Accent color overlay — driven by Accent Transparency + Accent Opacity sliders
          Rectangle {
            anchors.fill: parent; visible: root.avatarDarkOn && !root.avatarHideBg && root.avatarBgOpacity > 0
            property string hex: parent.avatarAccentHex
            color: Qt.rgba(
              parseInt(hex.substr(1,2),16)/255,
              parseInt(hex.substr(3,2),16)/255,
              parseInt(hex.substr(5,2),16)/255,
              Math.max(0, Math.min(0.92,
                (1.0 - root.accentTransparency/100) * (root.accentOpacity/100) * 0.35 )))
          }
          LinearGradient {
            visible: root.avatarDarkOn && root.avatarPanelGradOn && root.avatarSystemGradOn; anchors.fill: parent
            start: Qt.point(0,0); end: Qt.point(width,height)
            property real tR: parseInt(root.themeHex.substr(1,2),16)/255
            property real tG: parseInt(root.themeHex.substr(3,2),16)/255
            property real tB: parseInt(root.themeHex.substr(5,2),16)/255
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(parent.tR,parent.tG,parent.tB, Math.max(0,Math.min(1,root.gradientStrength/100))) }
              GradientStop { position:0.6; color:Qt.rgba(parent.tR*.7,parent.tG*.7,parent.tB*.7, Math.max(0,Math.min(1,root.gradientStrength/100))*.85) }
              GradientStop { position:1.0; color:Qt.rgba(parent.tR*.5,parent.tG*.5,parent.tB*.5, Math.max(0,Math.min(1,root.gradientStrength/100))*.7) }
            }
          }
          LinearGradient {
            visible: root.avatarDarkOn && root.avatarPanelGradOn && root.avatarSystemGradOn && root.avatarVignette; anchors.fill: parent
            start: Qt.point(0,height); end: Qt.point(0,0)
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(0,0,0,0.18) }
              GradientStop { position:1.0; color:Qt.rgba(0,0,0,0.0) }
            }
          }
          LinearGradient {
            visible: root.avatarDarkOn && root.avatarPanelGradOn && root.avatarAccentGradOn && root.avatarProfileGradOn; anchors.fill: parent
            start: Qt.point(0,0); end: Qt.point(width,0)
            property string hex: parent.avatarAccentHex
            property real mixT: Math.max(0, Math.min(1, root.avatarGlowColorMix / 100))
            property real glowR: mixT * (parseInt(hex.substr(1,2),16)/255)
            property real glowG: mixT * (parseInt(hex.substr(3,2),16)/255)
            property real glowB: mixT * (parseInt(hex.substr(5,2),16)/255)
            property real glowA: Math.max(0,Math.min(1, (root.accentGradAlpha/100)
                                   * (1.0 - root.accentGradTransp/100)
                                   * (root.accentGradOpacity/100) ))
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(parent.glowR, parent.glowG, parent.glowB, parent.glowA) }
              GradientStop { position:1.0; color:"transparent" }
            }
          }
          LinearGradient {
            visible: root.avatarDarkOn && root.avatarPanelGradOn && root.avatarThemeGradOn && root.avatarProfileGradOn; anchors.fill: parent
            start: Qt.point(0,0); end: Qt.point(0,height)
            property string hex: parent.avatarAccentHex
            property real mixT: Math.max(0, Math.min(1, root.avatarGlowColorMix / 100))
            property real glowR: mixT * (parseInt(hex.substr(1,2),16)/255)
            property real glowG: mixT * (parseInt(hex.substr(3,2),16)/255)
            property real glowB: mixT * (parseInt(hex.substr(5,2),16)/255)
            property real glowA: Math.max(0,Math.min(1, (root.themeGradAlpha/100)
                                   * (1.0 - root.accentGradTransp/100)
                                   * (root.accentGradOpacity/100) ))
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(parent.glowR, parent.glowG, parent.glowB, parent.glowA) }
              GradientStop { position:1.0; color:"transparent" }
            }
          }

          // ── Light mode ──
          Rectangle {
            anchors.fill: parent; visible: !root.avatarDarkOn && !root.avatarPanelGradOn && !root.avatarHideBg && root.avatarBgOpacity > 0
            color: Qt.rgba(root.themeFill.r, root.themeFill.g, root.themeFill.b,
                           Math.max(0, Math.min(0.92, (root.panelBaseAlpha/100) * (root.avatarBgOpacity/100))))
          }
          // Accent color overlay — driven by Accent Transparency + Accent Opacity sliders
          Rectangle {
            anchors.fill: parent; visible: !root.avatarDarkOn && !root.avatarHideBg && root.avatarBgOpacity > 0
            property string hex: parent.avatarAccentHex
            color: Qt.rgba(
              parseInt(hex.substr(1,2),16)/255,
              parseInt(hex.substr(3,2),16)/255,
              parseInt(hex.substr(5,2),16)/255,
              Math.max(0, Math.min(0.92,
                (1.0 - root.accentTransparency/100) * (root.accentOpacity/100) * 0.35 )))
          }
          LinearGradient {
            visible: !root.avatarDarkOn && root.avatarPanelGradOn && root.avatarThemeGradOn && root.avatarSystemGradOn; anchors.fill: parent
            start: Qt.point(0,0); end: Qt.point(width,height)
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(root.themeFill.r,root.themeFill.g,root.themeFill.b, Math.max(0,Math.min(1,root.gradientStrength/100))) }
              GradientStop { position:0.6; color:Qt.rgba(root.themeFill.r*.7,root.themeFill.g*.7,root.themeFill.b*.7, Math.max(0,Math.min(1,root.gradientStrength/100))*.85) }
              GradientStop { position:1.0; color:Qt.rgba(root.themeFill.r*.5,root.themeFill.g*.5,root.themeFill.b*.5, Math.max(0,Math.min(1,root.gradientStrength/100))*.7) }
            }
          }
          LinearGradient {
            visible: !root.avatarDarkOn && root.avatarPanelGradOn && root.avatarSystemGradOn && root.avatarVignette; anchors.fill: parent
            start: Qt.point(0,height); end: Qt.point(0,0)
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(0,0,0,0.18) }
              GradientStop { position:1.0; color:Qt.rgba(0,0,0,0.0) }
            }
          }
          LinearGradient {
            visible: !root.avatarDarkOn && root.avatarPanelGradOn && root.avatarAccentGradOn && root.avatarProfileGradOn; anchors.fill: parent
            start: Qt.point(0,0); end: Qt.point(width,0)
            property string hex: parent.avatarAccentHex
            property real mixT: Math.max(0, Math.min(1, root.avatarGlowColorMix / 100))
            property real glowR: mixT * (parseInt(hex.substr(1,2),16)/255)
            property real glowG: mixT * (parseInt(hex.substr(3,2),16)/255)
            property real glowB: mixT * (parseInt(hex.substr(5,2),16)/255)
            property real glowA: Math.max(0,Math.min(1, (root.accentGradAlpha/100)
                                   * (1.0 - root.accentGradTransp/100)
                                   * (root.accentGradOpacity/100) ))
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(parent.glowR, parent.glowG, parent.glowB, parent.glowA) }
              GradientStop { position:1.0; color:"transparent" }
            }
          }
          LinearGradient {
            visible: !root.avatarDarkOn && root.avatarPanelGradOn && root.avatarThemeGradOn && root.avatarProfileGradOn; anchors.fill: parent
            start: Qt.point(0,0); end: Qt.point(0,height)
            property string hex: parent.avatarAccentHex
            property real mixT: Math.max(0, Math.min(1, root.avatarGlowColorMix / 100))
            property real glowR: mixT * (parseInt(hex.substr(1,2),16)/255)
            property real glowG: mixT * (parseInt(hex.substr(3,2),16)/255)
            property real glowB: mixT * (parseInt(hex.substr(5,2),16)/255)
            property real glowA: Math.max(0,Math.min(1, (root.themeGradAlpha/100)
                                   * (1.0 - root.accentGradTransp/100)
                                   * (root.accentGradOpacity/100) ))
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(parent.glowR, parent.glowG, parent.glowB, parent.glowA) }
              GradientStop { position:1.0; color:"transparent" }
            }
          }
        }

        Loader {
          id: loader
          asynchronous: false
          anchors.fill: parent
          opacity: 0
          Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
          property int panelSlotNum: model.slotNum || 0
          sourceComponent: {
            var t = model.type
            if (t === "profile")     return profilePanel
            if (t === "avatarscene") return avatarScenePanel
            if (t === "profilecard") return profileCardPanel
            return null
          }
          onLoaded: {
            opacity = 1
            if (item && "slotNum" in item) { item.slotNum = panelSlotNum; Qt.callLater(function(){ if(item) item.slotNum = panelSlotNum }) }
            // Re-apply correct actions after async load — focus shift can clear the action bar
            Qt.callLater(function() {
              if (panelsList.currentIndex === 0) {
                setAvailableActions({
                  [Enums.ActionKeys.Bottom]: { label: "Select", visible: true },
                  [Enums.ActionKeys.Right]:  { label: "Back",   visible: true },
                  [Enums.ActionKeys.Top]:    { label: "Layout",  visible: true }
                })
              } else {
                setAvailableActions({
                  [Enums.ActionKeys.Bottom]: { label: "Select", visible: true  },
                  [Enums.ActionKeys.Right]:  { label: "Back",   visible: true  },
                  [Enums.ActionKeys.Top]:    { label: "Layout",  visible: true  }
                })
              }
            })
          }
        }

        Component.onCompleted: {
          loader.forceActiveFocus()
        }
      }
    }
  }

    // ── Panel counter ──────────────────────────────────────────────────
  StyledText {
    text: (panelsList.currentIndex + 1) + " of " + panelsList.count
    anchors.bottom: parent.bottom
    anchors.bottomMargin: vpx(46)
    anchors.left: parent.left
    anchors.leftMargin: vpx(98)
    font.pixelSize: vpx(20)
    color: "#616161"
  }

  // ── Layout badge — shown when "Show On Profiles" is checked in ThemesDetails ──
  Row {
    id: gamerPageLayoutBadge
    visible: api.memory.get("showOnProfiles") === "true"
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: vpx(40)
    anchors.bottomMargin: vpx(30)
    height: vpx(32)
    spacing: vpx(10)
    z: 20

    property int    layoutNum:  parseInt(api.memory.get("gp_gameLayout") || "1")
    property string layoutName: {
      var names = ["Layout Editor","Default","Media Strip","Card Stack",
                   "Flat Center","Big Box","Uniflow","Carousel"]
      var m = layoutNum
      return (m >= 0 && m < names.length) ? names[m] : "Default"
    }

    Timer {
      interval: 500; running: true; repeat: true
      onTriggered: {
        gamerPageLayoutBadge.visible  = (api.memory.get("showOnProfiles") === "true")
        var m = parseInt(api.memory.get("gp_gameLayout") || "1")
        var names = ["Layout Editor","Default","Media Strip","Card Stack",
                     "Flat Center","Big Box","Uniflow","Carousel"]
        gamerPageLayoutBadge.layoutNum  = m
        gamerPageLayoutBadge.layoutName = (m >= 0 && m < names.length) ? names[m] : "Default"
      }
    }

    StyledText {
      text: "Layout " + gamerPageLayoutBadge.layoutNum + " \u2022 " + gamerPageLayoutBadge.layoutName
      font.pixelSize: vpx(19)
      anchors.verticalCenter: parent.verticalCenter
    }
  }

}