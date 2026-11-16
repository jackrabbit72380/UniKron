import QtQuick 2.8
import QtQuick.Window 2.0
import QtGraphicalEffects 1.0
import "../js/styling.mjs" as Styling

PathView {
  id: panelsList

  // ── Page namespace — set this to scope all memory keys to a specific page.
  // LibraryPage uses "" (default), GamerPage uses "gp_".
  // Every api.memory key is prefixed with this so each page has independent state.
  property string pageKey: ""
  // pageTitle: resolves the current panel's display name from the model.
  // Uses model.get() for ListModel (Dashboard), direct role read for Pegasus native models.
  property string pageTitle: {
    if (!model || currentIndex < 0) return ""
    if (model.get) {
      var item = model.get(currentIndex)
      if (item) {
        if (typeof item.title === "string" && item.title.length > 0) return item.title
        if (item.collection && item.collection.name) return item.collection.name
        if (typeof item.name  === "string" && item.name.length  > 0) return item.name
      }
      return ""
    }
    return ""
  }

  // Helper: namespace a memory key with the page prefix
  function mk(key) { return pageKey + key; }

  // Guard against Styling.accentColor being undefined during startup,
  // which causes Qt to crash when assigning undefined to a QColor property.
  readonly property color safeAccent: (Styling.accentColor !== undefined && Styling.accentColor !== null)
                                        ? Styling.accentColor : "#5d9809"

  property bool flatMode:      false
  property int  visibleBoxes:  7
  property int  edVisibleCount: 13  // 1-13: hides panels beyond this slot distance
  property real globalYOffset: 0

  property int  monitorCount:      1
  property real singleScreenWidth: edUseMonitorCount ? (width / monitorCount) : width

  // screenOriginX: set to the parent's anchors.leftMargin when PanelsList is
  // inset from the screen edge. Adds the offset back into center-relative
  // layout calculations so Uniflow/BigBox/FlatCenter land at true screen centre.
  // LibraryPage has no leftMargin so this stays 0. GamerPage sets it to vpx(98).
  property real screenOriginX: 0
  property bool edUseScreenOrigin: false  // adds screenOriginX into spacing/center calcs when enabled
  property bool edUseMonitorCount: false  // divides singleScreenWidth by monitorCount when enabled

  property real selectedX: vpx(220)
  property real cx: selectedX

  property real gapPx:       vpx(4)
  property real autoSpacing: (singleScreenWidth + (edUseScreenOrigin ? screenOriginX : 0)) / visibleBoxes
  property real flatSpacing: panelWidth + gapPx

  property real spacingOverride: -1

  property real curvedSpacing: spacingOverride >= 0 ? spacingOverride : autoSpacing
  property real currentSpacing: flatMode ? flatSpacing : curvedSpacing

  property real scaleStep:    0.06
  property real yDropPerSlot: vpx(0)

  property int layoutMode: 0  // 0=Editor, 1=Default, 2=Media Strip, 3=Card Stack, 4=Flat Center, 5=BigBox, 6=Uniflow
  property int _prevLayoutMode: 0   // tracks previous layout so we can save its channel settings on switch

  // ── Layout 4: Bigbox Center ──────────────────────────────────────
  readonly property real nxeSelectedX:  (singleScreenWidth + (edUseScreenOrigin ? screenOriginX : 0) - panelWidth) / 2
  readonly property real nxeScaleStep:  0.07
  readonly property real nxeSpacing:    vpx(130)

  // ── Layout 5: Uniflow ────────────────────────────────────────────
  readonly property real uniSelectedX:  (singleScreenWidth + (edUseScreenOrigin ? screenOriginX : 0) - panelWidth) / 2
  readonly property real uniScaleStep:  0.10
  readonly property real uniSpacing:    vpx(100)
  property real uniBaseScale:           0.55
  readonly property real uniBaseScaleDefault: 0.55

  // Writes saved slot values into the shared variables every layout renders with.
  // Works for any layout, no editor required.
  function applySlotToLayout(slotIdx) {
    var json = api.memory.get(pageKey + "uniSlotData_" + slotIdx) || "";
    if (json === "") return;
    try {
      var d = JSON.parse(json);
      if (d.sx   !== undefined) selectedX       = d.sx;
      if (d.sp   !== undefined) spacingOverride  = d.sp;
      if (d.arc  !== undefined) scaleStep        = d.arc;
      if (d.base !== undefined) uniBaseScale     = d.base;
      if (d.yd   !== undefined) yDropPerSlot     = d.yd;
      flatMode = d.flat ? true : false;
    } catch(e) { console.log("applySlotToLayout error:", e); }
  }

  // ── Layout 6: Editor — live-editable ────────────────────────────
  property real edSelectedX:  uniSelectedX
  property real edSelectedY:  vpx(0)
  property real edSpacing:    uniSpacing
  property real edScaleStep:  uniScaleStep
  property real edBaseScale:  uniBaseScale
  property real edCenterScale: 1.0
  property real edCenterZ:    999
  property real edSideZ:      20
  property bool edFlatMode:   false
  property real edYDrop:      vpx(0)

  // ── Flat-mode snapshot — saved before flat is enabled, restored on disable ──
  property real _preFlatSelectedX:  uniSelectedX
  property real _preFlatSpacing:    uniSpacing
  property real _preFlatScaleStep:  uniScaleStep
  property real _preFlatBaseScale:  uniBaseScale
  property bool _preFlatValid:      false   // true once a snapshot has been taken

  property int  edColorMode:  0
  readonly property color edTextColor: {
    if (edColorMode === 1 || edBgMode === 4 || edBgMode === 5) return "#000000";
    return "#ffffff";
  }

  property bool edShowBounds:          false
  property bool edShowWrapperBounds:   false
  property bool edShowPanelListDebug:  false
  property bool edShowBg:            true
  property int  edBgMode:            0   // 0=Dark BG, 1=Black BG, 2=Semi BG, 3=Clear, 4=White BG, 5=Gray BG
  property int  edBtnFocus:          0
  property int  edPreviewLayout:     0
  property bool editorOpen:          false
  property bool edSlotsOpen:         false
  property bool edResetOpen:         false
  property bool edMoveOpen:          false
  property bool edDebugOpen:         false
  property bool edWrapperOpen:       false
  property bool edTabsOpen:          false
  property bool edLibraryOpen:       false
  property bool edLayersOpen:        false   // Layers page in editor

  // ── Stage settings ──────────────────────────────────────────────
  property bool stageEnabled:        true    // stages visible

  // ── Canopy settings — driven by ThemesDetails via api.memory("currentCanopy") ──
  property string canopyName:    api.memory.get("currentCanopy") || ""
  property bool   canopyEnabled: api.memory.get("canopyEnabled") !== "false"
  property bool edDebugLayoutOpen:   false
  property bool edLayoutInfoOpen:    false   // floating layout info card (info ℹ button on slots)
  property bool edTemplateInfoOpen:   false   // floating template info card (info ℹ button on templates)
  property bool edCustomInfoOpen:     false   // floating custom info card (info ℹ button on customs)
  property bool edTemplatesOpen:     false   // Templates page in editor
  property bool edCustomsOpen:       false   // Customs page in editor

  // ── Library title text settings (panel overlay title) ───────────
  property bool  libTitleVisible:    true
  property real  libTitleSize:       27     // px before vpx (matches default vpx(27))
  property real  libTitleOffsetX:    0      // extra X offset applied to title
  property real  libTitleOffsetY:    0      // extra Y offset applied to title bottom anchor
  property int   libTitleColorMode:  0      // 0=white, 1=accent, 2=black

  // ── Channel / collection name settings (Dashboard, Backlog, …) ──
  property bool  libChanVisible:     true
  property real  libChanSize:        41     // px before vpx (matches default vpx(41))
  property bool  libChanBold:        true
  property real  libChanOffsetX:     0      // per-item nudge (moves selected item relative to list)
  property real  libChanOffsetY:     0      // per-item nudge (moves selected item relative to list)
  property real  libChanListX:       0      // moves entire channel list container left/right
  property real  libChanListY:       0      // moves entire channel list container up/down
  property int   libChanColorMode:   0      // 0=white, 1=accent, 2=black
  property int   libChanPathCount:   5      // pathItemCount for both platformsList PathViews
  property int   libChanMode:        0      // 0=Default (scale only), 1=Vertical (scale+slide), 2=Horizontal
  property bool  libChanFocusTitles: true   // true = input controls titles; false = input controls items
  property int   libChanScaleOrigin: 1      // path items scale origin: 0=center, 1=left, 2=right
  property int   libChanTextOrigin:  0      // text anchor within item: 0=left, 1=center, 2=right
  property bool  libChanEnabled:     true   // false = channel names section entirely disabled
  property bool  libChanDebug:       false  // show red outline around PathView + items
  property bool  libSquareEnabled:   true   // false = square icon position section disabled
  property bool  libItemBorder:      false  // border on selected panel item
  property bool  libTitleBorder:     false  // border on selected channel title text
  property bool  libTitleEnabled:    true   // false = tab title text section entirely disabled
  property real  libPathStartX:      0      // path start X offset (shifts where items begin on the path)
  property real  libPathStartY:      0      // path start Y offset
  property real  libPathEndX:        0      // path end X offset
  property real  libPathEndY:        0      // path end Y offset
  property bool  libPathEnabled:     true   // false = path start/end section entirely disabled

  // ▢ home square icon independent offsets
  property real  libSquareOffsetX:   -45    // nudge square icon left of channel name text
  property real  libSquareOffsetY:   0

  // ── Wrapper visual properties ────────────────────────────────────
  property real wrapCornerRadius:      7    // px before vpx
  property real wrapReflectionSize:    30   // px before vpx
  property real wrapReflectionOpacity: 0.2
  property real wrapReflectionBlur:    0    // GaussianBlur radius on reflection (0=off)
  property bool wrapShadowOn:          true
  property real wrapShadowOpacity:     1.0
  // wrapShadowMode: 0=bitmap (panel-shadow.png, right edge), 1=DropShadow (corner-aware)
  property int  wrapShadowMode:        0
  property real wrapShadowRadius:      16   // DropShadow blur radius (mode 1 only)
  property real wrapShadowOffsetX:     8    // DropShadow X offset px (mode 1 only)
  property real wrapShadowOffsetY:     4    // DropShadow Y offset px (mode 1 only)
  property string wrapShadowColor:     "#000000"
  property int  edDebugWallpaper:    -1   // -1=none, 0-3=wallpaper index
  property bool edDebugEnabled:      false
  property bool edCollapsed:         false
  property int  edResetLayout:       -1   // -1=not set (use Default), 0-6=layout to jump to on Reset
  property int  edForceStartup:      -1   // -1=off, 0-6=always boot to this layout
  property real edOverlayOffsetX:    0
  property real edOverlayOffsetY:    0

  // ── Per-side X correction ────────────────────────────────────────
  property real edLeftCorrectX:  0
  property real edRightCorrectX: 0

  // ── Per-side Y correction ────────────────────────────────────────
  property real edLeftCorrectY:  0
  property real edRightCorrectY: 0

  // ── Per-side independent arc (scale step) ───────────────────────
  property bool edAsymArc:        false
  property real edArcStepLeft:    uniScaleStep
  property real edArcStepRight:   uniScaleStep

  // ── Per-side independent base scale ─────────────────────────────
  property bool edAsymScale:      false
  property real edBaseScaleLeft:  uniBaseScale
  property real edBaseScaleRight: uniBaseScale

  // ── Per-side independent spacing ────────────────────────────────
  property bool edAsymSpacing:    false
  property real edSpacingLeft:    uniSpacing
  property real edSpacingRight:   uniSpacing

  // ── Per-side independent Y drop ─────────────────────────────────
  property bool edAsymYDrop:      false
  property real edYDropLeft:      vpx(0)
  property real edYDropRight:     vpx(0)

  // ── Arc In/Out curve bias (0=linear, +1=fast-in, -1=fast-out) ───
  property real edArcCurve:       0.0
  property bool edArcFlip:        false   // true = arc reverses (scale grows away from center)

  // ── Arc Up/Down: per-side Y curve multiplier ─────────────────────
  property bool edAsymYCurve:     false
  property real edYCurveLeft:     0.0
  property real edYCurveRight:    0.0

  // ── Custom default Center Z ──────────────────────────────────────
  property real edCustomDefaultZ: 999

  // ── Viewport / list vertical offset ─────────────────────────────
  property real edViewOffsetY: 0

  // ── Center panel nudge (independent X/Y offset for center slot only) ─
  property real edCenterOffsetX: 0
  property real edCenterOffsetY: 0

  // ── Per-side Y: independent start (near-center) and end (far-side) ─
  // When edAsymYStartEnd is true these override edYDrop for their slots
  property bool edAsymYStartEnd:    false
  property real edLeftYStart:       0      // Y extra at slot -1 (left nearest center)
  property real edLeftYMid:         0      // Y extra at slot -4 (left middle)
  property real edLeftYEnd:         0      // Y extra at slot -7 (left outermost)
  property real edRightYStart:      0      // Y extra at slot +1 (right nearest center)
  property real edRightYMid:        0      // Y extra at slot +4 (right middle)
  property real edRightYEnd:        0      // Y extra at slot +7 (right outermost)

  // ── Rotation: center + per-side start/end ───────────────────────
  property real edCenterRotation:   0      // degrees, center panel
  property bool edAsymRotation:     false  // enable per-side rotation
  property real edLeftRotStart:     0      // rotation at slot -1 (nearest center, left)
  property real edLeftRotEnd:       0      // rotation at slot -7 (outermost left)
  property real edRightRotStart:    0      // rotation at slot +1 (nearest center, right)
  property real edRightRotEnd:      0      // rotation at slot +7 (outermost right)
  property real edRotationBias:     0      // global clockwise bias added to all side rotations

  property bool edAsymTilt:        false  // enable per-side Y tilt
  property int  edPathVersion:     0      // bumped to force PathAttribute re-evaluation

  Timer {
    id: pathRefreshTimer
    interval: 50
    repeat: false
    onTriggered: { panelsList.edPathVersion = panelsList.edPathVersion + 1; }
  }

  // ── Auto-sync ed* geometry → live path properties on every change ──
  // When editorOpen=true but useEdPath=false (no slot loaded), slotX/slotScale/slotY
  // read the live props (selectedX, spacingOverride, scaleStep, uniBaseScale, etc.)
  // not the ed* props directly. edSyncLiveProps() pushes ed* → live props so the
  // panel list updates immediately on every step-button click.
  // edPathVersion bump ensures the PathView cache invalidates when useEdPath IS true.
  onEdSpacingChanged:        { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdSpacingLeftChanged:    { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdSpacingRightChanged:   { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdScaleStepChanged:      { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdBaseScaleChanged:      { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdBaseScaleLeftChanged:  { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdBaseScaleRightChanged: { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdSelectedXChanged:      { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdSelectedYChanged:      { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdCenterScaleChanged:    { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdYDropChanged:          { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdFlatModeChanged:       { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdArcFlipChanged:        { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdArcStepLeftChanged:    { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdArcStepRightChanged:   { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdAsymSpacingChanged:    { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdAsymScaleChanged:      { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdAsymArcChanged:        { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdVisibleCountChanged:   { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdSideZChanged:          { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdCenterZChanged:        { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }

  // ── Rotation / position properties (Rotation page) ──────────────
  onEdCenterRotationChanged: { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdRotationBiasChanged:   { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdLeftRotStartChanged:   { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdLeftRotEndChanged:     { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdRightRotStartChanged:  { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdRightRotEndChanged:    { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdAsymRotationChanged:   { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdCenterOffsetXChanged:  { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdCenterOffsetYChanged:  { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdLeftCorrectXChanged:   { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdLeftCorrectYChanged:   { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdRightCorrectXChanged:  { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdRightCorrectYChanged:  { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdLeftYStartChanged:     { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdLeftYMidChanged:       { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdLeftYEndChanged:       { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdRightYStartChanged:    { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdRightYMidChanged:      { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdRightYEndChanged:      { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdAsymYStartEndChanged:  { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }

  // ── Y-curve and wrapper asymmetric properties ────────────────────
  onEdArcCurveChanged:       { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdAsymYCurveChanged:     { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdYCurveLeftChanged:     { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdYCurveRightChanged:    { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdYDropLeftChanged:      { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdYDropRightChanged:     { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdViewOffsetYChanged:    { if (!_seedingEditor && editorOpen) { if (layoutMode !== 0) layoutMode = 0; edSyncLiveProps(); } edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }

  // ── Library properties — bump path so panel delegates re-evaluate ─
  onLibSquareOffsetXChanged: { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibSquareOffsetYChanged: { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibSquareEnabledChanged: { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibTitleVisibleChanged:  { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibTitleSizeChanged:     { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibTitleOffsetXChanged:  { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibTitleOffsetYChanged:  { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibTitleColorModeChanged:{ edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibTitleEnabledChanged:  { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibTitleBorderChanged:   { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanVisibleChanged:   { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanSizeChanged:      { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanBoldChanged:      { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanOffsetXChanged:   { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanOffsetYChanged:   { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanListXChanged:     { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanListYChanged:     { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanColorModeChanged: { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanPathCountChanged: { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanModeChanged:      { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanEnabledChanged:   { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanDebugChanged:     { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanScaleOriginChanged:{ edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibChanTextOriginChanged: { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibItemBorderChanged:    { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibPathEnabledChanged:   { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibPathStartXChanged:    { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibPathStartYChanged:    { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibPathEndXChanged:      { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onLibPathEndYChanged:      { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }

  // ── Tilt properties ──────────────────────────────────────────────
  onEdTiltCenterChanged:     { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdTiltNearChanged:       { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdTiltFarChanged:        { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdTiltLeftNearChanged:   { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdTiltLeftFarChanged:    { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdTiltRightNearChanged:  { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdTiltRightFarChanged:   { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onEdAsymTiltChanged:       { if (!_seedingEditor && editorOpen && layoutMode !== 0) layoutMode = 0; edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }

  // ── Wrapper properties ───────────────────────────────────────────
  onWrapCornerRadiusChanged:      { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onWrapReflectionSizeChanged:    { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onWrapReflectionOpacityChanged: { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onWrapReflectionBlurChanged:    { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onWrapShadowOnChanged:          { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onWrapShadowOpacityChanged:     { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onWrapShadowModeChanged:        { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onWrapShadowRadiusChanged:      { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onWrapShadowOffsetXChanged:     { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onWrapShadowOffsetYChanged:     { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }
  onWrapShadowColorChanged:       { edPathVersion = edPathVersion + 1; pathRefreshTimer.restart(); }

  property real edTiltCenter:      0      // Y-axis lean at center slot (0)
  property real edTiltNear:        0      // Y-axis lean at slot ±1 (nearest center)
  property real edTiltFar:         0      // Y-axis lean at slot ±7 (outermost)
  property real edTiltLeftNear:    0      // per-side overrides when edAsymTilt=true
  property real edTiltLeftFar:     0
  property real edTiltRightNear:   0
  property real edTiltRightFar:    0

  // ── Experimental page open flag ──────────────────────────────────
  property bool edExpOpen:          false
  property bool edTiltOpen:         false

  // ── Editor panel layout flip ─────────────────────────────────────
  property bool edPanelFlipped:   false
  // ── Experimental dpad mode: 0=Orthogonal, 1=Rotation ────────────
  property int edDpadMode: 0
  // ── Editor panel vertical dock: false=top, true=bottom ──────────
  property bool edPanelAtBottom:  false


  // ── Layout save/load slots ───────────────────────────────────────
  property int  edSlotRevision: 0   // bumped on every load to force delegate re-eval
  property var  edSavedSlots: [
    { name: "", data: "", layoutName: "" }, { name: "", data: "", layoutName: "" }, { name: "", data: "", layoutName: "" },
    { name: "", data: "", layoutName: "" }, { name: "", data: "", layoutName: "" }, { name: "", data: "", layoutName: "" },
    { name: "", data: "", layoutName: "" }, { name: "", data: "", layoutName: "" }, { name: "", data: "", layoutName: "" }
  ]
  property int  edActiveSlot: -1
  property bool _closingEditor: false   // true during closeEditor to prevent onLayoutModeChanged clearing the slot
  property bool _seedingEditor: false   // suppresses layoutMode=0 side-effects while seeding ed* props
  property bool _booting:       true    // true during Component.onCompleted; skips loadLayoutChanSettings so boot always uses factory defaults

  // ── Custom layouts + cycle control ───────────────────────────
  property bool cycleBuiltIn:    true
  property bool cycleCustom:     false
  property bool cycleSlots:      false   // include filled editor slots in Y cycle (200+idx)
  property bool cycleEditor:     false   // include layout 0 (Editor) in Y cycle — off by default
  property var  customLayouts:   []   // [{name, data}]
  property int  edActiveCustom:  -1
  property bool edTemplateStaged: false  // true once a template number has been selected, cleared on Load
  property int  edActiveCycleSlot: -1   // which slot is active via Y cycle (-1 = none)
  property int  customRevision:  0
  property bool importOpen:      false

  // ── Canopy preset list ───────────────────────────────────────────
  // Add new canopy folder names here as you create them.
  // Each name maps to two image files in assets/images/canopies/:
  //   <name>_banner.png  (top — slides in from top)
  //   <name>_footer.png  (bottom — slides in from bottom)
  function _canopyPresets() {
    return ["uniflow", "uniflow_glass"];
  }

  function loadCustomLayouts() {
    var arr = [];
    var i = 0;
    while (true) {
      var d = api.memory.get(pageKey + "customLayout_data_" + i) || "";
      if (d === "" && i >= 20) break;
      if (d !== "") {
        var n = api.memory.get(pageKey + "customLayout_name_" + i) || ("Custom " + i);
        arr.push({ name: n, data: d });
      }
      i++;
      if (i > 50) break;
    }
    customLayouts = arr;
    customRevision = customRevision + 1;
  }

  function saveCustomLayout(name, data) {
    // find first empty slot or append
    var idx = 0;
    while (true) {
      var existing = api.memory.get(pageKey + "customLayout_data_" + idx) || "";
      if (existing === "") break;
      idx++;
      if (idx > 50) return;
    }
    api.memory.set(pageKey + "customLayout_name_" + idx, name);
    api.memory.set(pageKey + "customLayout_data_" + idx, data);
    loadCustomLayouts();
  }

  function overwriteCustomLayout(idx, data) {
    api.memory.set(pageKey + "customLayout_data_" + idx, data);
    loadCustomLayouts();
  }

  function deleteCustomLayout(idx) {
    // shift all above down
    var i = idx;
    while (true) {
      var next = api.memory.get(pageKey + "customLayout_data_" + (i+1)) || "";
      var nextName = api.memory.get(pageKey + "customLayout_name_" + (i+1)) || "";
      api.memory.set(pageKey + "customLayout_data_" + i, next);
      api.memory.set(pageKey + "customLayout_name_" + i, nextName);
      if (next === "") break;
      i++;
      if (i > 50) break;
    }
    if (edActiveCustom === idx) edActiveCustom = -1;
    loadCustomLayouts();
  }

  function renameCustomLayout(idx, name) {
    api.memory.set(pageKey + "customLayout_name_" + idx, name);
    loadCustomLayouts();
  }

  function edPackLayout() {
    // lm records the actual layout being shown when Save is pressed.
    // lm >= 1-8  -> built-in layout; load restores it via applyLayoutMode.
    // lm === 0   -> pure editor/custom geometry; load unpacks all ed* values.
    var _lm = (edPreviewLayout >= 1 && edPreviewLayout <= 8) ? edPreviewLayout : 0;
    return JSON.stringify({
      v:   1,
      lm:  _lm,
      origLm: edPreviewLayout,
      sx:  edSelectedX,   sp:  edSpacing,    arc: edScaleStep, base: edBaseScale,
      yd:  edYDrop,       flat: edFlatMode ? 1 : 0,
      gap: gapPx,
      lcx: edLeftCorrectX, rcx: edRightCorrectX,
      aarc: edAsymArc ? 1 : 0,  larc: edArcStepLeft,   rarc: edArcStepRight,
      asc:  edAsymScale ? 1 : 0, lsc:  edBaseScaleLeft,  rsc:  edBaseScaleRight,
      asp:  edAsymSpacing ? 1 : 0, lsp: edSpacingLeft,  rsp: edSpacingRight,
      ayd:  edAsymYDrop ? 1 : 0,  lyd: edYDropLeft,     ryd: edYDropRight,
      acv:  edArcCurve,
      ayc:  edAsymYCurve ? 1 : 0, lycl: edYCurveLeft,   rycr: edYCurveRight,
      lyS: edLeftYStart,  lyM: edLeftYMid,  lyE: edLeftYEnd,
      ryS: edRightYStart, ryM: edRightYMid, ryE: edRightYEnd,
      ayse: edAsymYStartEnd ? 1 : 0,
      // ── Scale / position extras ────────────────────────────────
      csc:  edCenterScale,
      cz:   edCenterZ,
      sz:   edSideZ,
      sy:   edSelectedY,
      voy:  edViewOffsetY,
      cox:  edCenterOffsetX,
      coy:  edCenterOffsetY,
      lcy:  edLeftCorrectY,
      rcy:  edRightCorrectY,
      aflp: edArcFlip     ? 1 : 0,
      pflp: edPanelFlipped ? 1 : 0,
      patb: edPanelAtBottom ? 1 : 0,
      // ── Rotation ───────────────────────────────────────────────
      crot: edCenterRotation,
      arot: edAsymRotation  ? 1 : 0,
      lrs:  edLeftRotStart,
      lre:  edLeftRotEnd,
      rrs:  edRightRotStart,
      rre:  edRightRotEnd,
      rbias: edRotationBias,
      // ── Y-Tilt ────────────────────────────────────────────────
      atlt: edAsymTilt    ? 1 : 0,
      tltc: edTiltCenter,
      tltn: edTiltNear,   tltf: edTiltFar,
      tllN: edTiltLeftNear, tllF: edTiltLeftFar,
      tlrN: edTiltRightNear, tlrF: edTiltRightFar,
      // ── Channel names ──────────────────────────────────────────
      lcEn:  libChanEnabled   ? 1 : 0,
      lcVis: libChanVisible   ? 1 : 0,
      lcSz:  libChanSize,
      lcBld: libChanBold      ? 1 : 0,
      lcOx:  libChanOffsetX,
      lcOy:  libChanOffsetY,
      lcLx:  libChanListX,
      lcLy:  libChanListY,
      lcCol: libChanColorMode,
      lcPc:  libChanPathCount,
      lcMd:  libChanMode,
      lcFt:  libChanFocusTitles ? 1 : 0,
      lcSo:  libChanScaleOrigin,
      lcTo:  0,  // always save as left-aligned so restored layouts don't center
      // ── Title text ─────────────────────────────────────────────
      ltEn:  libTitleEnabled  ? 1 : 0,
      ltVis: libTitleVisible  ? 1 : 0,
      ltSz:  libTitleSize,
      ltOx:  libTitleOffsetX,
      ltOy:  libTitleOffsetY,
      ltCol: libTitleColorMode,
      ltBrd: libTitleBorder   ? 1 : 0,
      // ── Square icon ────────────────────────────────────────────
      lsEn:  libSquareEnabled ? 1 : 0,
      lsOx:  libSquareOffsetX,
      lsOy:  libSquareOffsetY,
      // ── Path ───────────────────────────────────────────────────
      lpEn:  libPathEnabled   ? 1 : 0,
      lpSx:  libPathStartX,
      lpSy:  libPathStartY,
      lpEx:  libPathEndX,
      lpEy:  libPathEndY,
      // ── Misc ───────────────────────────────────────────────────
      lcBrd: libItemBorder    ? 1 : 0,
      lcDbg: libChanDebug     ? 1 : 0
    });
  }

  function edUnpackLayout(json) {
    try {
      var d = JSON.parse(json);
      edSelectedX       = d.sx   !== undefined ? d.sx   : uniSelectedX;
      edSpacing         = d.sp   !== undefined ? d.sp   : uniSpacing;
      edScaleStep       = d.arc  !== undefined ? d.arc  : uniScaleStep;
      edBaseScale       = d.base !== undefined ? d.base : uniBaseScale;
      edYDrop           = d.yd   !== undefined ? d.yd   : 0;
      edFlatMode        = d.flat ? true : false;
      if (d.gap  !== undefined) { gapPx = d.gap; }
      else if (d.flat && d.sp !== undefined) { gapPx = Math.max(0, d.sp - panelWidth); }
      if (d.origLm !== undefined) { edPreviewLayout = d.origLm; }
      edLeftCorrectX    = d.lcx  || 0;
      edRightCorrectX   = d.rcx  || 0;
      edAsymArc         = d.aarc ? true : false;
      edArcStepLeft     = d.larc !== undefined ? d.larc : uniScaleStep;
      edArcStepRight    = d.rarc !== undefined ? d.rarc : uniScaleStep;
      edAsymScale       = d.asc  ? true : false;
      edBaseScaleLeft   = d.lsc  !== undefined ? d.lsc  : uniBaseScale;
      edBaseScaleRight  = d.rsc  !== undefined ? d.rsc  : uniBaseScale;
      edAsymSpacing     = d.asp  ? true : false;
      edSpacingLeft     = d.lsp  !== undefined ? d.lsp  : uniSpacing;
      edSpacingRight    = d.rsp  !== undefined ? d.rsp  : uniSpacing;
      edAsymYDrop       = d.ayd  ? true : false;
      edYDropLeft       = d.lyd  || 0;
      edYDropRight      = d.ryd  || 0;
      edArcCurve        = d.acv  !== undefined ? d.acv  : 0.0;
      edAsymYCurve      = d.ayc  ? true : false;
      edYCurveLeft      = d.lycl !== undefined ? d.lycl : 0.0;
      edYCurveRight     = d.rycr !== undefined ? d.rycr : 0.0;
      edAsymYStartEnd   = d.ayse ? true : false;
      edLeftYStart      = d.lyS  || 0;  edLeftYMid  = d.lyM || 0;  edLeftYEnd  = d.lyE || 0;
      edRightYStart     = d.ryS  || 0;  edRightYMid = d.ryM || 0;  edRightYEnd = d.ryE || 0;
      // ── Scale / position extras — reset to defaults first ────────
      edCenterScale   = 1.0;  edCenterZ = 999;  edSideZ = 20;
      edSelectedY     = 0;    edViewOffsetY = 0;
      edCenterOffsetX = 0;    edCenterOffsetY = 0;
      edLeftCorrectY  = 0;    edRightCorrectY = 0;
      edArcFlip = false;      edPanelFlipped = false;  edPanelAtBottom = false;
      if (d.csc  !== undefined) edCenterScale    = d.csc;
      if (d.cz   !== undefined) edCenterZ        = d.cz;
      if (d.sz   !== undefined) edSideZ          = d.sz;
      if (d.sy   !== undefined) edSelectedY      = d.sy;
      if (d.voy  !== undefined) edViewOffsetY    = d.voy;
      if (d.cox  !== undefined) edCenterOffsetX  = d.cox;
      if (d.coy  !== undefined) edCenterOffsetY  = d.coy;
      if (d.lcy  !== undefined) edLeftCorrectY   = d.lcy;
      if (d.rcy  !== undefined) edRightCorrectY  = d.rcy;
      if (d.aflp !== undefined) edArcFlip        = d.aflp ? true : false;
      if (d.pflp !== undefined) edPanelFlipped   = d.pflp ? true : false;
      if (d.patb !== undefined) edPanelAtBottom  = d.patb ? true : false;
      // ── Rotation — reset to defaults first ────────────────────────
      edCenterRotation = 0;  edAsymRotation = false;
      edLeftRotStart   = 0;  edLeftRotEnd   = 0;
      edRightRotStart  = 0;  edRightRotEnd  = 0;
      edRotationBias   = 0;
      if (d.crot  !== undefined) edCenterRotation = d.crot;
      if (d.arot  !== undefined) edAsymRotation   = d.arot  ? true : false;
      if (d.lrs   !== undefined) edLeftRotStart   = d.lrs;
      if (d.lre   !== undefined) edLeftRotEnd     = d.lre;
      if (d.rrs   !== undefined) edRightRotStart  = d.rrs;
      if (d.rre   !== undefined) edRightRotEnd    = d.rre;
      if (d.rbias !== undefined) edRotationBias   = d.rbias;
      // ── Y-Tilt — always reset first so missing keys mean no tilt ─
      edAsymTilt      = false;
      edTiltCenter    = 0; edTiltNear = 0; edTiltFar = 0;
      edTiltLeftNear  = 0; edTiltLeftFar = 0;
      edTiltRightNear = 0; edTiltRightFar = 0;
      if (d.atlt  !== undefined) edAsymTilt       = d.atlt  ? true : false;
      if (d.tltc  !== undefined) edTiltCenter     = d.tltc;
      if (d.tltn  !== undefined) edTiltNear       = d.tltn;
      if (d.tltf  !== undefined) edTiltFar        = d.tltf;
      if (d.tllN  !== undefined) edTiltLeftNear   = d.tllN;
      if (d.tllF  !== undefined) edTiltLeftFar    = d.tllF;
      if (d.tlrN  !== undefined) edTiltRightNear  = d.tlrN;
      if (d.tlrF  !== undefined) edTiltRightFar   = d.tlrF;
      // ── Channel names ──────────────────────────────────────────
      if (d.lcEn  !== undefined) libChanEnabled    = d.lcEn  ? true : false;
      if (d.lcVis !== undefined) libChanVisible    = d.lcVis ? true : false;
      if (d.lcSz  !== undefined) libChanSize       = d.lcSz;
      if (d.lcBld !== undefined) libChanBold       = d.lcBld ? true : false;
      if (d.lcOx  !== undefined) libChanOffsetX    = d.lcOx;
      if (d.lcOy  !== undefined) libChanOffsetY    = d.lcOy;
      if (d.lcLx  !== undefined) libChanListX      = d.lcLx;
      if (d.lcLy  !== undefined) libChanListY      = d.lcLy;
      if (d.lcCol !== undefined) libChanColorMode  = d.lcCol;
      if (d.lcPc  !== undefined) libChanPathCount  = d.lcPc;
      if (d.lcMd  !== undefined) libChanMode       = d.lcMd;
      if (d.lcFt  !== undefined) libChanFocusTitles = d.lcFt ? true : false;
      if (d.lcSo  !== undefined) libChanScaleOrigin = d.lcSo;
      // lcTo (text alignment) not restored — always left-aligned (0)
      // ── Title text ─────────────────────────────────────────────
      if (d.ltEn  !== undefined) libTitleEnabled   = d.ltEn  ? true : false;
      if (d.ltVis !== undefined) libTitleVisible   = d.ltVis ? true : false;
      if (d.ltSz  !== undefined) libTitleSize      = d.ltSz;
      if (d.ltOx  !== undefined) libTitleOffsetX   = d.ltOx;
      if (d.ltOy  !== undefined) libTitleOffsetY   = d.ltOy;
      if (d.ltCol !== undefined) libTitleColorMode = d.ltCol;
      if (d.ltBrd !== undefined) libTitleBorder    = d.ltBrd ? true : false;
      // ── Square icon ────────────────────────────────────────────
      if (d.lsEn  !== undefined) libSquareEnabled  = d.lsEn  ? true : false;
      if (d.lsOx  !== undefined) libSquareOffsetX  = d.lsOx;
      if (d.lsOy  !== undefined) libSquareOffsetY  = d.lsOy;
      // ── Path ───────────────────────────────────────────────────
      if (d.lpEn  !== undefined) libPathEnabled    = d.lpEn  ? true : false;
      if (d.lpSx  !== undefined) libPathStartX     = d.lpSx;
      if (d.lpSy  !== undefined) libPathStartY     = d.lpSy;
      if (d.lpEx  !== undefined) libPathEndX       = d.lpEx;
      if (d.lpEy  !== undefined) libPathEndY       = d.lpEy;
      // ── Misc ───────────────────────────────────────────────────
      if (d.lcBrd !== undefined) libItemBorder     = d.lcBrd ? true : false;
      if (d.lcDbg !== undefined) libChanDebug      = d.lcDbg ? true : false;
    } catch(e) { console.log("edUnpackLayout error:", e); }
  }

  function edLoadSlots() {
    var arr = [];
    for (var i = 0; i < Math.max(9, edSavedSlots.length); i++) {
      var n  = api.memory.get(pageKey + "uniSlotName_" + i) || "";
      var ln = api.memory.get(pageKey + "uniSlotLayoutName_" + i) || "";
      var d  = api.memory.get(pageKey + "uniSlotData_" + i) || "";
      // Seed slot 8 with RTL Default layout data if it has never been saved
      // Always re-seed slot 8 with built-in RTL Default data (lm:8)
      // so it always loads via the built-in path regardless of what was saved before.
      if (i === 8) {
        d = JSON.stringify({ v: 1, lm: 8 });
        n = "RTL Default"; ln = "RTL Default";
        api.memory.set(pageKey + "uniSlotData_" + i, d);
        api.memory.set(pageKey + "uniSlotName_" + i, n);
        api.memory.set(pageKey + "uniSlotLayoutType_" + i, ln);
      }      // If name is blank or still a generic "Preset N", promote the layout type name
      if (d !== "" && ln !== "" && (n === "" || n === ("Preset " + i))) {
        n = ln;
        api.memory.set(pageKey + "uniSlotName_" + i, n);
      }
      arr.push({ name: n || ln, data: d, layoutName: ln });
    }
    // Remove trailing empty slots beyond the default 8 (slots 1-8 always visible)
    while (arr.length > 9 && arr[arr.length-1].data === "" && arr[arr.length-1].name === "") {
      arr.pop();
    }
    // Always pad to at least 9 entries so slots 1-8 are always shown
    while (arr.length < 9) {
      arr.push({ name: "", data: "", layoutName: "" });
    }
    edSavedSlots = arr; // force new array reference for reactivity
    edSlotRevision = edSlotRevision + 1;  // force all delegates to re-read
  }

  function edSaveSlot(idx, nm) {
    // Use the live layoutMode as the authoritative lm for built-in layouts.
    // If layoutMode and edPreviewLayout agree on a built-in (1-8), use that.
    // If only edPreviewLayout is set (editor open with template staged), use it.
    // This ensures Load Template → Save Slot → Load Slot always round-trips faithfully.
    var lmNum = (layoutMode >= 1 && layoutMode <= 8) ? layoutMode : edPreviewLayout;
    var layoutLabel = lmNum === 0 ? "Editor"
                    : lmNum === 1 ? "Default"
                    : lmNum === 2 ? "Media Strip"
                    : lmNum === 3 ? "Card Stack"
                    : lmNum === 4 ? "Flat Center"
                    : lmNum === 5 ? "Big Box"
                    : lmNum === 6 ? "Uniflow"
                    : lmNum === 8 ? "RTL Default"
                    : "Carousel";
    // For built-in layouts save a clean lm reference.
    // For pure editor/custom layouts pack the full ed* geometry.
    var dataToSave;
    if (lmNum >= 1 && lmNum <= 8) {
      dataToSave = JSON.stringify({ v: 1, lm: lmNum, origLm: lmNum });
    } else {
      dataToSave = edPackLayout();
    }
    api.memory.set(pageKey + "uniSlotData_" + idx, dataToSave);
    api.memory.set(pageKey + "uniSlotName_" + idx, nm || ("Preset " + idx));
    api.memory.set(pageKey + "uniSlotLayoutType_" + idx, layoutLabel);
    edLoadSlots();
    edActiveSlot = idx;
  }

  function edSyncLiveProps() {
    // Mirror ed* values into all live PathView properties used by layouts 1-7.
    flatMode        = edFlatMode;
    selectedX       = edSelectedX;
    spacingOverride = edSpacing;
    scaleStep       = edScaleStep;
    yDropPerSlot    = edYDrop;
    // Sync gap so flatSpacing (panelWidth + gapPx) matches edSpacing in flat mode.
    if (edFlatMode) gapPx = Math.max(0, edSpacing - panelWidth);
    // Layout 6/7 (Uniflow/Carousel) render scale using uniBaseScale — sync it too.
    uniBaseScale    = edBaseScale;
    // Global Y offset drives vertical position for layouts 1-7.
    globalYOffset   = edSelectedY;
    // Force path re-evaluation: bump now and again after 50ms via timer.
    edPathVersion = edPathVersion + 1;
    pathRefreshTimer.restart();
    // ── Layers: restore stage + canopy state across reboots ──────
    var savedSE = api.memory.get("stageEnabled");
    if (savedSE !== null && savedSE !== undefined && savedSE !== "") stageEnabled = (savedSE !== "false");
    var savedCE = api.memory.get("canopyEnabled");
    if (savedCE !== null && savedCE !== undefined && savedCE !== "") canopyEnabled = (savedCE !== "false");
  }

  function edLoadSlot(idx) {
    var d = edSavedSlots[idx] ? edSavedSlots[idx].data : "";
    if (d) {
      var lm = -1;
      try {
        var parsed = JSON.parse(d);
        lm = parsed.lm || -1;
        // Fallback: if lm is 0 (editor) but origLm points to a built-in layout,
        // treat it as built-in. This fixes slots saved before the edSaveSlot fix.
        if (lm === 0 && parsed.origLm >= 1 && parsed.origLm <= 8) {
          lm = parsed.origLm;
        }
      } catch(e) {}
      if (lm >= 1 && lm <= 8) {
        // Built-in layout — apply directly.
        // _seedingEditor prevents onEd*Changed handlers from forcing layoutMode=0
        // while applyLayoutMode writes its canonical ed* values.
        _seedingEditor = true;
        edActiveSlot = idx;
        api.memory.set(pageKey + "uniActiveSlot", idx);
        layoutMode = lm;
        var wasOpen = editorOpen;
        applyLayoutMode(true);
        editorOpen = wasOpen;
        _seedingEditor = false;
        edPreviewLayout = lm;
        edPreSlotLayout = lm;
        _slotLoadedLayout = lm;
        _slotEverLoaded = true;
        _slotLoadedCustom = false;
        edSlotIsLoaded = false;
        // Force PathView to re-evaluate path positions with the freshly applied layout.
        // Without this bump the PathView keeps stale positions from the previous layout.
        edPathVersion = edPathVersion + 1;
        pathRefreshTimer.restart();
      } else {
        // Custom editor layout — unpack and sync live props
        edUnpackLayout(d);
        edActiveSlot = idx;
        api.memory.set(pageKey + "uniActiveSlot", idx);
        _slotEverLoaded = true;
        console.log("edSlotIsLoaded=true SET at edLoadSlot custom path, idx="+idx);
        _slotLoadedCustom = true;
        edSlotIsLoaded = true;
        edSyncLiveProps();
      }
    }
  }

  function edDeleteSlot(idx) {
    api.memory.set(pageKey + "uniSlotData_" + idx, "");
    api.memory.set(pageKey + "uniSlotName_" + idx, "");
    api.memory.set(pageKey + "uniSlotLayoutType_" + idx, "");
    var savedActive = parseInt(api.memory.get(pageKey + "uniActiveSlot") || "-1");
    if (savedActive === idx) api.memory.set(pageKey + "uniActiveSlot", -1);
    edLoadSlots();
    if (edActiveSlot === idx) edActiveSlot = -1;
  }

  function triggerPressedAnimation(actionKey) { /* stub */ }

  // ── Swap two adjacent slots (used by ▲/▼ reorder buttons) ───────
  function edSwapSlots(idxA, idxB) {
    if (idxA < 1 || idxB < 1) return;
    var dA  = api.memory.get(pageKey + "uniSlotData_" + idxA) || "";
    var nA  = api.memory.get(pageKey + "uniSlotName_" + idxA) || "";
    var lnA = api.memory.get(pageKey + "uniSlotLayoutType_" + idxA) || "";
    var dB  = api.memory.get(pageKey + "uniSlotData_" + idxB) || "";
    var nB  = api.memory.get(pageKey + "uniSlotName_" + idxB) || "";
    var lnB = api.memory.get(pageKey + "uniSlotLayoutType_" + idxB) || "";
    api.memory.set(pageKey + "uniSlotData_" + idxA, dB);
    api.memory.set(pageKey + "uniSlotName_" + idxA, nB);
    api.memory.set(pageKey + "uniSlotLayoutType_" + idxA, lnB);
    api.memory.set(pageKey + "uniSlotData_" + idxB, dA);
    api.memory.set(pageKey + "uniSlotName_" + idxB, nA);
    api.memory.set(pageKey + "uniSlotLayoutType_" + idxB, lnA);
    if (edActiveSlot === idxA)      edActiveSlot = idxB;
    else if (edActiveSlot === idxB) edActiveSlot = idxA;
    edLoadSlots();
  }

  // ── Slot math helpers ────────────────────────────────────────────
  function slotArc(dist) {
    if (!edAsymArc) return edScaleStep;
    if (dist < 0) return edArcStepLeft;
    if (dist > 0) return edArcStepRight;
    return edScaleStep;
  }

  function slotBaseScale(dist) {
    if (!edAsymScale) return edBaseScale;
    if (dist < 0) return edBaseScaleLeft;
    if (dist > 0) return edBaseScaleRight;
    return edBaseScale;
  }

  // Apply arc curve bias: positive = faster falloff near center (In),
  // negative = faster falloff near edges (Out)
  function arcCurvedDist(absDist) {
    if (edArcCurve === 0.0) return absDist;
    if (edArcCurve > 0) return absDist * (1.0 + edArcCurve * absDist * 0.3);
    return Math.pow(absDist, 1.0 + (-edArcCurve) * 0.5);
  }

  // useEdPath: true when the editor OR an active slot should drive rendering.
  // Slots use the full ed* system — their rich geometry (asymmetric arc, center
  // scale, Y curves, spacing corrections etc.) only exists in ed* properties.
  property bool edSlotIsLoaded: false    // true only after Load is clicked (for saved slots)
  property bool edCustomIsLoaded: false  // true after a custom layout ⬆ Load is clicked
  property bool _slotEverLoaded: false   // true once any slot has been loaded this session
  property bool _slotLoadedCustom: false // true if last loaded slot was a custom (ed*) layout
  property int  _slotLoadedLayout: 1     // layoutMode at time of last Load
  property int  edPreSlotLayout: 1      // layout active before any slot was loaded
  onEdActiveSlotChanged: {
    // Do not reset edSlotIsLoaded here — selecting a slot should not shift the layout.
    // edSlotIsLoaded is only set true by edLoadSlot and false by applyLayoutMode/closeEditor.
    console.log("onEdActiveSlotChanged: edActiveSlot="+edActiveSlot+" layoutMode="+layoutMode+" _slotLoadedCustom="+_slotLoadedCustom);
  }
  readonly property bool useEdPath: (layoutMode === 0 || (edActiveSlot >= 1 && edSlotIsLoaded) || edCustomIsLoaded)

  // ── Layout 1 default path — replicates original styling.mjs GameCover cascade ──
  // X positions are cumulative (each panel placed at previousRight + xOffset).
  // Values derived from GameCover panelStyle in styling.mjs.
  readonly property var _l1X: [217, 434, 595, 722, 823, 906, 976, 1034, 1084, 1128, 1167, 1201, 1231, 1258]
  readonly property var _l1S: [1.0, 0.859375, 0.753125, 0.66875, 0.6, 0.546875, 0.503125, 0.465625, 0.43125, 0.403125, 0.375, 0.35625, 0.334375, 0.31875]
  readonly property var _l1Y: [0, -4, -7, -9, -11, -13, -14, -15, -15, -17, -17, -17, -19, -19]

  // Layout 8: RTL mirror of layout 1 — positions reflected about screen centre
  // _l1X values mirrored: screenRef(1280) - x - panelWidth(380) = [683, 466, 305, 178, 77, ...]
  readonly property var _l8X: [683, 466, 305, 178, 77, -6, -76, -134, -184, -228, -267, -301, -331, -358]

  // Declared as readonly properties so QML updates them atomically in its
  // deferred-binding cycle. Plain function calls are transparent to the binding
  // engine and can be evaluated mid-cycle when multiple reactive properties change
  // simultaneously (e.g. width fires → autoSpacing + useEdPath both update at once).
  // A readonly property bool is never seen in a half-updated state, eliminating
  // the transient stale evaluation that caused "panels jump left on first navigation".
  //
  // CRITICAL: These must NOT depend on useEdPath. layoutMode 1/3/8 always render
  // their hardcoded arc arrays — useEdPath is irrelevant for these layouts.
  // If useEdPath were included here, any transient true/false flip during binding
  // evaluation (e.g. on width change) could cause slotX/Y/Scale to pick the wrong
  // branch and bake stale zero-spacing positions into the PathView cache.
  readonly property bool _isDefaultArcLayout: !useEdPath && (layoutMode === 1 || layoutMode === 3)
  readonly property bool _isRTLArcLayout:     !useEdPath && layoutMode === 8

  // Thin wrappers kept so any remaining call-sites still compile.
  function isDefaultArcLayout() { return _isDefaultArcLayout; }
  function isRTLArcLayout()     { return _isRTLArcLayout; }

  function slotScale(dist) {
    // Arc layouts always use hardcoded arrays — check BEFORE useEdPath to prevent
    // transient useEdPath=true (during width-change binding cycles) from hijacking
    // these layouts and baking wrong positions into the PathView cache.
    if (_isDefaultArcLayout) {
      var _vArcS = edPathVersion;
      var absDistS = Math.abs(dist);
      return absDistS < _l1S.length ? _l1S[absDistS] : 0.108;
    }
    if (_isRTLArcLayout) {
      var _v8s = edPathVersion;
      if (dist > 0) return 0.0;
      if (dist === 0) return 1.0;
      var absDist8s = -dist;
      return absDist8s < _l1S.length ? _l1S[absDist8s] : 0.108;
    }
    if (useEdPath) {
      var _v = edPathVersion;
      if (Math.abs(dist) > edVisibleCount) return 0.0;
      if (dist === 0) return edCenterScale;
      if (edFlatMode) return edBaseScale;
      var effectiveDist = arcCurvedDist(Math.abs(dist));
      var step = slotArc(dist);
      if (edArcFlip) {
        return Math.min(2.0, slotBaseScale(dist) + effectiveDist * step);
      }
      return Math.max(0.10, slotBaseScale(dist) - effectiveDist * step);
    }
    if (flatMode) return slotVisible(dist) ? 1.0 : 0.0;
    if (layoutMode === 5) {
      if (dist < 0) return 0.0;
      return Math.max(0.25, 1.0 - dist * nxeScaleStep);
    }
    if (layoutMode === 6) return Math.max(0.20, uniBaseScale - Math.abs(dist) * scaleStep);
    return Math.max(0.5, 1.0 - Math.abs(dist) * scaleStep);
  }

  function slotY(dist) {
    // Arc layouts always use hardcoded arrays — check BEFORE useEdPath.
    if (_isDefaultArcLayout) {
      var _vArcY = edPathVersion;
      var absDistY = Math.abs(dist);
      var _yv = absDistY < _l1Y.length ? _l1Y[absDistY] : -19;
      return globalYOffset + vpx(_yv);
    }
    if (_isRTLArcLayout) {
      if (dist > 0) return globalYOffset;
      var absDist8y = -dist;
      var _yv8 = absDist8y < _l1Y.length ? _l1Y[absDist8y] : -19;
      return globalYOffset + vpx(_yv8);
    }
    if (useEdPath) {
      if (dist === 0) return edSelectedY;
      var yd = edAsymYDrop ? (dist < 0 ? edYDropLeft : edYDropRight) : edYDrop;
      var yc = edAsymYCurve ? (dist < 0 ? edYCurveLeft : edYCurveRight) : 0.0;
      var absDist = Math.abs(dist);
      var curveMult = yc !== 0.0 ? Math.pow(absDist, 1.0 + Math.abs(yc)) / absDist : 1.0;
      var yFromDrop = yd * absDist * curveMult;
      if (edAsymYStartEnd) {
        var t = Math.min(1.0, Math.max(0.0, (absDist - 1.0) / 6.0));
        var yS = dist < 0 ? edLeftYStart : edRightYStart;
        var yM = dist < 0 ? edLeftYMid   : edRightYMid;
        var yE = dist < 0 ? edLeftYEnd   : edRightYEnd;
        var yExtra = (1-t)*(1-t)*yS + 2*(1-t)*t*yM + t*t*yE;
        yFromDrop += yExtra;
      }
      return edSelectedY + yFromDrop + (dist < 0 ? edLeftCorrectY : edRightCorrectY);
    }
    return globalYOffset + Math.abs(dist) * yDropPerSlot;
  }

  function slotTiltY(dist) {
    if (!useEdPath && layoutMode !== 7) return 0;
    if (dist === 0) return edTiltCenter;
    var absD = Math.abs(dist);
    var t    = (absD - 1) / 6.0;
    var near, far;
    if (edAsymTilt) {
      near = dist < 0 ? edTiltLeftNear  : edTiltRightNear;
      far  = dist < 0 ? edTiltLeftFar   : edTiltRightFar;
    } else {
      near = dist < 0 ? -edTiltNear : edTiltNear;
      far  = dist < 0 ? -edTiltFar  : edTiltFar;
    }
    return near + t * (far - near);
  }

  function slotRotation(dist) {
    if (!useEdPath) return 0;
    if (dist === 0) return edCenterRotation;
    if (!edAsymRotation) return 0;
    var absDist = Math.abs(dist);
    var t = Math.min(1.0, Math.max(0.0, (absDist - 1.0) / 6.0));
    var base;
    if (dist < 0) base = edLeftRotStart  + t * (edLeftRotEnd  - edLeftRotStart);
    else          base = edRightRotStart + t * (edRightRotEnd - edRightRotStart);
    return base + edRotationBias;
  }

  function slotZ(dist) {
    // Arc layouts always use hardcoded Z — check BEFORE useEdPath.
    if (_isDefaultArcLayout) {
      if (dist === 0) return 999;
      if (dist < 0) return Math.max(1, 999 - (-dist) * 10);
      return Math.max(1, 999 - dist * 10);
    }
    if (_isRTLArcLayout) {
      if (dist === 0) return 999;
      if (dist > 0) return 0;
      return Math.max(1, 999 - (-dist) * 10);
    }
    if (useEdPath) {
      if (dist === 0) return edCenterZ;
      return Math.max(1, edSideZ - Math.abs(dist) * 3);
    }
    if (dist === 0) return 999;
    if (layoutMode === 5 && dist < 0) return 0;
    return Math.max(1, 20 - Math.abs(dist) * 3);
  }

  function slotVisible(dist) {
    if (!flatMode) return true;
    if (dist < 0) return true;
    return (cx + dist * flatSpacing + panelWidth) <= singleScreenWidth;
  }

  function slotX(dist) {
    // Arc layouts always use hardcoded arrays — check BEFORE useEdPath to prevent
    // transient useEdPath=true (e.g. during width-change binding cycles) from
    // hijacking these layouts and baking wrong zero-spacing positions into the PathView.
    if (_isDefaultArcLayout) {
      var _vArc = edPathVersion;
      if (dist === 0) return vpx(_l1X[0]);
      if (dist > 0)   return vpx(dist < _l1X.length ? _l1X[dist] : _l1X[_l1X.length-1]);
      // Mirror the right cascade symmetrically about _l1X[0] so left-side panels
      // animate in smoothly rather than flying 700px from -vpx(500).
      var absd = -dist;
      var mirrorX = 2 * _l1X[0] - (absd < _l1X.length ? _l1X[absd] : _l1X[_l1X.length-1]);
      return vpx(mirrorX);
    }
    if (_isRTLArcLayout) {
      var _v8 = edPathVersion;
      if (dist > 0) return singleScreenWidth + vpx(500);
      var absDist8 = -dist;
      var ltrX = absDist8 < _l1X.length ? _l1X[absDist8] : _l1X[_l1X.length-1];
      return vpx(1280 - ltrX) - panelWidth;
    }
    if (useEdPath) {
      var _v = edPathVersion;
      if (dist === 0) return edSelectedX;
      var sp = edAsymSpacing ? (dist < 0 ? edSpacingLeft : edSpacingRight) : edSpacing;
      return edSelectedX + dist * sp;
    }
    if (layoutMode === 5) return nxeSelectedX + dist * currentSpacing;
    return cx + dist * currentSpacing;
  }

  function applyLayoutMode(keepSlot) {
    switch (layoutMode) {
      case 0: // Editor — handled separately, no live prop reset needed
        if (!editorOpen) {
          var prevLayout = parseInt(api.memory.get(pageKey + "gameLayoutBeforeEdit") || "6");
          var seedX, seedSpacing, seedScaleStep, seedBaseScale, seedCenterScale, seedFlatMode;
          if (prevLayout === 1 || prevLayout === 2) {
            seedX = vpx(220); seedSpacing = autoSpacing; seedScaleStep = 0.06; seedBaseScale = uniBaseScale; seedCenterScale = 1.0; seedFlatMode = (prevLayout === 2);
          } else if (prevLayout === 3) {
            seedX = vpx(220); seedSpacing = autoSpacing; seedScaleStep = 0.06; seedBaseScale = uniBaseScale; seedCenterScale = 1.0; seedFlatMode = true;
          } else if (prevLayout === 4) {
            seedX = (singleScreenWidth + (edUseScreenOrigin ? screenOriginX : 0) - panelWidth) / 2; seedSpacing = autoSpacing; seedScaleStep = 0.06; seedBaseScale = uniBaseScale; seedCenterScale = 1.0; seedFlatMode = true;
          } else if (prevLayout === 5) {
            seedX = nxeSelectedX; seedSpacing = autoSpacing; seedScaleStep = nxeScaleStep; seedBaseScale = uniBaseScale; seedCenterScale = 1.0; seedFlatMode = false;
          } else {
            // Layout 6 (Uniflow) or fallback
            seedX = uniSelectedX; seedSpacing = autoSpacing; seedScaleStep = uniScaleStep; seedBaseScale = uniBaseScale; seedCenterScale = uniBaseScale; seedFlatMode = false;
          }
          edSelectedX      = seedX;          edSelectedY      = vpx(0);
          edViewOffsetY    = vpx(0);
          edSpacing        = seedSpacing;
          edScaleStep      = seedScaleStep;  edBaseScale      = seedBaseScale;
          edCenterScale    = seedCenterScale;
          edCenterZ        = edCustomDefaultZ;
          edSideZ          = 20;
          edCenterOffsetX  = 0;
          edCenterOffsetY  = 0;
          edFlatMode       = seedFlatMode;   edYDrop          = vpx(0);
          edLeftCorrectX   = 0;             edRightCorrectX  = 0;
          edLeftCorrectY   = 0;             edRightCorrectY  = 0;
          edAsymArc        = false;          edArcStepLeft    = seedScaleStep;  edArcStepRight   = seedScaleStep;
          edAsymScale      = false;          edBaseScaleLeft  = seedBaseScale;  edBaseScaleRight = seedBaseScale;
          edAsymSpacing    = false;          edSpacingLeft    = seedSpacing;    edSpacingRight   = seedSpacing;
          edAsymYDrop      = false;          edYDropLeft      = vpx(0);         edYDropRight     = vpx(0);
          edArcCurve       = 0.0;
          edAsymYCurve     = false;          edYCurveLeft     = 0.0;            edYCurveRight    = 0.0;
          edCenterRotation = 0;              edRotationBias   = 0;
          edTiltCenter = 0; edTiltNear = 0; edTiltFar = 0; edAsymTilt = false; edTiltLeftNear = 0; edTiltLeftFar = 0; edTiltRightNear = 0; edTiltRightFar = 0;
          edActiveSlot     = -1;
        }
        edLoadSlots();
        break;
      case 1:
        flatMode = false; selectedX = vpx(217); edSelectedX = vpx(217); edFlatMode = false;
        spacingOverride = -1; edSpacing = autoSpacing; scaleStep = 0.09; yDropPerSlot = vpx(0);
        uniBaseScale = uniBaseScaleDefault; globalYOffset = 0; edSelectedY = 0; edViewOffsetY = 0;
        edScaleStep = 0.09; edBaseScale = 1.0; edCenterScale = 1.0; edYDrop = 0; gapPx = vpx(4);
        edLeftCorrectX = 0; edRightCorrectX = 0; edLeftCorrectY = 0; edRightCorrectY = 0;
        edAsymArc = false; edArcStepLeft = 0.09; edArcStepRight = 0.09;
        edAsymScale = false; edBaseScaleLeft = 1.0; edBaseScaleRight = 1.0;
        edAsymSpacing = false; edSpacingLeft = autoSpacing; edSpacingRight = autoSpacing;
        edAsymYDrop = false; edYDropLeft = 0; edYDropRight = 0;
        edArcCurve = 0; edAsymYCurve = false; edYCurveLeft = 0; edYCurveRight = 0;
        edCenterOffsetX = 0; edCenterOffsetY = 0;
        edTiltCenter = 0; edTiltNear = 0; edTiltFar = 0; edAsymTilt = false;
        edTiltLeftNear = 0; edTiltLeftFar = 0; edTiltRightNear = 0; edTiltRightFar = 0;
        edCustomIsLoaded = false; edSlotIsLoaded = false;
        if (!keepSlot) edActiveSlot = -1;
        if (!_booting) loadLayoutChanSettings(1);
        break;
      case 2: flatMode = true;  selectedX = vpx(220); edSelectedX = vpx(220); edFlatMode = true;  spacingOverride = -1; edSpacing = autoSpacing; scaleStep = 0.06; yDropPerSlot = vpx(0); uniBaseScale = uniBaseScaleDefault; globalYOffset = 0; edTiltCenter = 0; edTiltNear = 0; edTiltFar = 0; edAsymTilt = false; edCustomIsLoaded = false; edSlotIsLoaded = false; if (!_booting) loadLayoutChanSettings(2); break;
      case 3: flatMode = false; selectedX = vpx(220); edSelectedX = vpx(220); edFlatMode = false; spacingOverride = -1; edSpacing = autoSpacing; scaleStep = 0.06; yDropPerSlot = vpx(0); uniBaseScale = uniBaseScaleDefault; globalYOffset = 0; edLeftCorrectX = 0; edRightCorrectX = 0; edAsymArc = false; edAsymScale = false; edAsymSpacing = false; edAsymYDrop = false; edArcCurve = 0; edCenterOffsetX = 0; edCenterOffsetY = 0; edTiltCenter = 0; edTiltNear = 0; edTiltFar = 0; edAsymTilt = false; edCustomIsLoaded = false; edSlotIsLoaded = false; if (!keepSlot) edActiveSlot = -1; if (!_booting) loadLayoutChanSettings(3); break;
      case 4: flatMode = true;  selectedX = (singleScreenWidth + (edUseScreenOrigin ? screenOriginX : 0) - panelWidth) / 2; spacingOverride = -1; scaleStep = 0.06; yDropPerSlot = vpx(0); uniBaseScale = uniBaseScaleDefault; globalYOffset = 0; edTiltCenter = 0; edTiltNear = 0; edTiltFar = 0; edAsymTilt = false; edCustomIsLoaded = false; edSlotIsLoaded = false; if (!_booting) loadLayoutChanSettings(4); break;
      case 5: flatMode = false; edFlatMode = false; selectedX = nxeSelectedX; edSelectedX = nxeSelectedX; spacingOverride = nxeSpacing; edSpacing = nxeSpacing; scaleStep = nxeScaleStep; yDropPerSlot = vpx(0); uniBaseScale = uniBaseScaleDefault; globalYOffset = 0; edLeftCorrectX = 0; edRightCorrectX = 0; edAsymArc = false; edAsymScale = false; edAsymSpacing = false; edAsymYDrop = false; edArcCurve = 0; edCenterOffsetX = 0; edCenterOffsetY = 0; edTiltCenter = 0; edTiltNear = 0; edTiltFar = 0; edAsymTilt = false; edCustomIsLoaded = false; edSlotIsLoaded = false; if (!keepSlot) edActiveSlot = -1; if (!_booting) loadLayoutChanSettings(5); break;
      case 6: flatMode = false; edFlatMode = false; selectedX = uniSelectedX; edSelectedX = uniSelectedX; spacingOverride = uniSpacing; edSpacing = uniSpacing; scaleStep = uniScaleStep; yDropPerSlot = vpx(0); uniBaseScale = uniBaseScaleDefault; globalYOffset = 0; edLeftCorrectX = 0; edRightCorrectX = 0; edAsymArc = false; edAsymScale = false; edAsymSpacing = false; edAsymYDrop = false; edArcCurve = 0; edCenterOffsetX = 0; edCenterOffsetY = 0; edTiltCenter = 0; edTiltNear = 0; edTiltFar = 0; edAsymTilt = false; edCustomIsLoaded = false; edSlotIsLoaded = false; if (!keepSlot) edActiveSlot = -1; if (!_booting) loadLayoutChanSettings(6); break;
      case 7: // Carousel — Uniflow base + Y-tilt to showcase tilt feature
        flatMode = false; selectedX = uniSelectedX; spacingOverride = uniSpacing; scaleStep = uniScaleStep; yDropPerSlot = vpx(0);
        uniBaseScale = uniBaseScaleDefault; globalYOffset = 0;
        edTiltCenter = 0; edTiltNear = 18; edTiltFar = 42; edAsymTilt = false;
        edTiltLeftNear = 0; edTiltLeftFar = 0; edTiltRightNear = 0; edTiltRightFar = 0;
        edCenterRotation = 0;
        edCustomIsLoaded = false; edSlotIsLoaded = false;
        if (!keepSlot) edActiveSlot = -1;
        if (!_booting) loadLayoutChanSettings(7);
        break;
      case 8: // RTL Default — mirror of layout 1, panels fan left from right edge
        flatMode = false;
        selectedX       = vpx(1280 - _l1X[0]) - panelWidth;
        edSelectedX     = selectedX;
        edFlatMode      = false;
        spacingOverride = -1;
        scaleStep       = 0.09;
        yDropPerSlot    = vpx(0);
        uniBaseScale    = uniBaseScaleDefault;
        globalYOffset   = 0;
        edTiltCenter = 0; edTiltNear = 0; edTiltFar = 0; edAsymTilt = false;
        edCustomIsLoaded = false; edSlotIsLoaded = false;
        if (!keepSlot) edActiveSlot = -1;
        if (!_booting) loadLayoutChanSettings(8);
        edPathVersion = edPathVersion + 1;
        pathRefreshTimer.restart();
        break;    }
    // Slot re-apply is handled explicitly by edLoadSlot and closeEditor, not here.
    // edActiveSlot managed per-case via keepSlot parameter.
  }

  // ── Per-layout channel name settings ────────────────────────────
  // Saves ONLY the ed* geometry for a layout — used when a slot is active so
  // channel name settings (which belong to the layout, not the slot) are not overwritten.
  function saveLayoutGeometry(layoutNum) {
    var existing = api.memory.get(pageKey + "layoutChan_" + layoutNum + "_data") || "";
    var d = existing !== "" ? JSON.parse(existing) : {};
    d.pg_sx    = edSelectedX;
    d.pg_sy    = edSelectedY;
    d.pg_sp    = edSpacing;
    d.pg_arc   = edScaleStep;
    d.pg_base  = edBaseScale;
    d.pg_csc   = edCenterScale;
    d.pg_flat  = edFlatMode   ? 1 : 0;
    d.pg_yd    = edYDrop;
    d.pg_goy   = globalYOffset;
    d.pg_cz    = edCenterZ;
    d.pg_sz    = edSideZ;
    d.pg_cox   = edCenterOffsetX;
    d.pg_coy   = edCenterOffsetY;
    d.pg_lcx   = edLeftCorrectX;
    d.pg_rcx   = edRightCorrectX;
    d.pg_lcy   = edLeftCorrectY;
    d.pg_rcy   = edRightCorrectY;
    d.pg_aarc  = edAsymArc    ? 1 : 0;
    d.pg_larc  = edArcStepLeft;
    d.pg_rarc  = edArcStepRight;
    d.pg_asc   = edAsymScale  ? 1 : 0;
    d.pg_lsc   = edBaseScaleLeft;
    d.pg_rsc   = edBaseScaleRight;
    d.pg_asp   = edAsymSpacing ? 1 : 0;
    d.pg_lsp   = edSpacingLeft;
    d.pg_rsp   = edSpacingRight;
    d.pg_ayd   = edAsymYDrop  ? 1 : 0;
    d.pg_lyd   = edYDropLeft;
    d.pg_ryd   = edYDropRight;
    d.pg_acv   = edArcCurve;
    d.pg_slot  = edActiveSlot;
    d.pg_gap   = gapPx;
    api.memory.set(pageKey + "layoutChan_" + layoutNum + "_data", JSON.stringify(d));
  }

  // Saves full layout state (panel geometry + channel/title/square/path settings)
  // for a given layout number so each layout remembers its own complete appearance.
  function saveLayoutChanSettings(layoutNum) {
    var d = {};
    // ── Full ed* geometry (covers both simple and slot-based rendering) ──
    d.pg_sx    = edSelectedX;
    d.pg_sy    = edSelectedY;
    d.pg_sp    = edSpacing;
    d.pg_arc   = edScaleStep;
    d.pg_base  = edBaseScale;
    d.pg_csc   = edCenterScale;
    d.pg_flat  = edFlatMode   ? 1 : 0;
    d.pg_yd    = edYDrop;
    d.pg_goy   = globalYOffset;
    d.pg_cz    = edCenterZ;
    d.pg_sz    = edSideZ;
    d.pg_cox   = edCenterOffsetX;
    d.pg_coy   = edCenterOffsetY;
    d.pg_lcx   = edLeftCorrectX;
    d.pg_rcx   = edRightCorrectX;
    d.pg_lcy   = edLeftCorrectY;
    d.pg_rcy   = edRightCorrectY;
    d.pg_aarc  = edAsymArc    ? 1 : 0;
    d.pg_larc  = edArcStepLeft;
    d.pg_rarc  = edArcStepRight;
    d.pg_asc   = edAsymScale  ? 1 : 0;
    d.pg_lsc   = edBaseScaleLeft;
    d.pg_rsc   = edBaseScaleRight;
    d.pg_asp   = edAsymSpacing ? 1 : 0;
    d.pg_lsp   = edSpacingLeft;
    d.pg_rsp   = edSpacingRight;
    d.pg_ayd   = edAsymYDrop  ? 1 : 0;
    d.pg_lyd   = edYDropLeft;
    d.pg_ryd   = edYDropRight;
    d.pg_acv   = edArcCurve;
    d.pg_slot  = edActiveSlot;
    d.pg_gap   = gapPx;
    // ── Channel names ──────────────────────────────────────────────
    d.lcEn  = libChanEnabled    ? 1 : 0;
    d.lcVis = libChanVisible    ? 1 : 0;
    d.lcSz  = libChanSize;
    d.lcBld = libChanBold       ? 1 : 0;
    d.lcOx  = libChanOffsetX;
    d.lcOy  = libChanOffsetY;
    d.lcLx  = libChanListX;
    d.lcLy  = libChanListY;
    d.lcCol = libChanColorMode;
    d.lcPc  = libChanPathCount;
    d.lcMd  = libChanMode;
    d.lcFt  = libChanFocusTitles ? 1 : 0;
    d.lcSo  = libChanScaleOrigin;
    d.lcTo  = 0;  // always save left-aligned — never bake center into JSON
    d.lcBrd = libItemBorder     ? 1 : 0;
    d.lcDbg = libChanDebug      ? 1 : 0;
    // ── Title text ─────────────────────────────────────────────────
    d.ltEn  = libTitleEnabled   ? 1 : 0;
    d.ltVis = libTitleVisible   ? 1 : 0;
    d.ltSz  = libTitleSize;
    d.ltOx  = libTitleOffsetX;
    d.ltOy  = libTitleOffsetY;
    d.ltCol = libTitleColorMode;
    d.ltBrd = libTitleBorder    ? 1 : 0;
    // ── Square / path ──────────────────────────────────────────────
    d.lsEn  = libSquareEnabled  ? 1 : 0;
    d.lsOx  = libSquareOffsetX;
    d.lsOy  = libSquareOffsetY;
    d.lpEn  = libPathEnabled    ? 1 : 0;
    d.lpSx  = libPathStartX;
    d.lpSy  = libPathStartY;
    d.lpEx  = libPathEndX;
    d.lpEy  = libPathEndY;
    api.memory.set(pageKey + "layoutChan_" + layoutNum + "_data", JSON.stringify(d));
  }

  // Restores ONLY channel/title/square/path display settings — never geometry.
  // applyLayoutMode() already set the correct canonical geometry.
  function loadLayoutChanSettings(layoutNum) {
    var json = api.memory.get(pageKey + "layoutChan_" + layoutNum + "_data") || "";
    if (json === "") { return; }
    try {
      var d = JSON.parse(json);
      // ── Full ed* geometry restore ────────────────────────────────
      // ── Channel names ────────────────────────────────────────────
      if (d.lcEn  !== undefined) { libChanEnabled    = d.lcEn  ? true : false; }
      if (d.lcVis !== undefined) { libChanVisible    = d.lcVis ? true : false; }
      if (d.lcSz  !== undefined) { libChanSize       = d.lcSz;  }
      if (d.lcBld !== undefined) { libChanBold       = d.lcBld ? true : false; }
      if (d.lcOx  !== undefined) { libChanOffsetX    = d.lcOx;  }
      if (d.lcOy  !== undefined) { libChanOffsetY    = d.lcOy;  }
      if (d.lcLx  !== undefined) { libChanListX      = d.lcLx;  }
      if (d.lcLy  !== undefined) { libChanListY      = d.lcLy;  }
      if (d.lcCol !== undefined) { libChanColorMode  = d.lcCol; }
      if (d.lcPc  !== undefined) { libChanPathCount  = d.lcPc;  }
      if (d.lcMd  !== undefined) { libChanMode       = d.lcMd;  }
      if (d.lcFt  !== undefined) { libChanFocusTitles = d.lcFt ? true : false; }
      if (d.lcSo  !== undefined) { libChanScaleOrigin = d.lcSo; }
      // lcTo (text alignment) intentionally not restored — always defaults to left (0) on boot
      if (d.lcBrd !== undefined) { libItemBorder     = d.lcBrd ? true : false; }
      if (d.lcDbg !== undefined) { libChanDebug      = d.lcDbg ? true : false; }
      // ── Title text ───────────────────────────────────────────────
      if (d.ltEn  !== undefined) { libTitleEnabled   = d.ltEn  ? true : false; }
      if (d.ltVis !== undefined) { libTitleVisible   = d.ltVis ? true : false; }
      if (d.ltSz  !== undefined) { libTitleSize      = d.ltSz;  }
      if (d.ltOx  !== undefined) { libTitleOffsetX   = d.ltOx;  }
      if (d.ltOy  !== undefined) { libTitleOffsetY   = d.ltOy;  }
      if (d.ltCol !== undefined) { libTitleColorMode = d.ltCol; }
      if (d.ltBrd !== undefined) { libTitleBorder    = d.ltBrd ? true : false; }
      // ── Square / path ────────────────────────────────────────────
      if (d.lsEn  !== undefined) { libSquareEnabled  = d.lsEn  ? true : false; }
      if (d.lsOx  !== undefined) { libSquareOffsetX  = d.lsOx;  }
      if (d.lsOy  !== undefined) { libSquareOffsetY  = d.lsOy;  }
      if (d.lpEn  !== undefined) { libPathEnabled    = d.lpEn  ? true : false; }
      if (d.lpSx  !== undefined) { libPathStartX     = d.lpSx;  }
      if (d.lpSy  !== undefined) { libPathStartY     = d.lpSy;  }
      if (d.lpEx  !== undefined) { libPathEndX       = d.lpEx;  }
      if (d.lpEy  !== undefined) { libPathEndY       = d.lpEy;  }
    } catch(e) { console.log("loadLayoutChanSettings error: " + e); }
  }

  function cycleLayout() {
    if (layoutMode !== 0) api.memory.set(pageKey + "gameLayoutBeforeEdit", layoutMode);

    // Build pool.
    // Ranges: builtins 1-7 | customs 100+idx | slots 200+idx | editor 0 (opt-in, last)
    var pool = [];
    if (cycleBuiltIn) { for (var i = 1; i <= 8; i++) pool.push(i); }
    if (cycleCustom)  { for (var j = 0; j < customLayouts.length; j++) pool.push(100 + j); }
    if (cycleSlots)   {
      for (var k = 1; k < edSavedSlots.length; k++) {
        if (edSavedSlots[k] && edSavedSlots[k].data !== "") pool.push(200 + k);
      }
    }
    if (cycleEditor) pool.push(0);
    if (pool.length === 0) pool = [1]; // safety fallback

    // Find current position in pool.
    // Priority: active cycle-slot (200+) > active custom (100+) > layoutMode.
    // When inside the editor and it is NOT in the pool, treat it as its pre-edit layout
    // so the first press advances cleanly rather than jumping to pool[0].
    var cur;
    if (layoutMode === 0 && !cycleEditor) {
      cur = parseInt(api.memory.get(pageKey + "gameLayoutBeforeEdit") || "1");
    } else if (edActiveCycleSlot >= 0) {
      cur = 200 + edActiveCycleSlot;
    } else if (edActiveCustom >= 0) {
      cur = 100 + edActiveCustom;
    } else {
      cur = layoutMode;
    }
    var pos = pool.indexOf(cur);
    // Not in pool (category toggled off etc.): clamp to last so next step is pool[0].
    if (pos < 0) pos = pool.length - 1;
    var next = pool[(pos + 1) % pool.length];

    if (next === 0) {
      // Editor — open via the standard path
      edActiveCycleSlot = -1;
      edActiveCustom    = -1;
      openEditor();
    } else if (next >= 200) {
      // Saved editor slot — unpack and sync live props so panels move immediately
      var sidx = next - 200;
      edActiveCycleSlot = sidx;
      edActiveCustom    = -1;
      var sd = edSavedSlots[sidx] ? edSavedSlots[sidx].data : "";
      if (sd) {
        var slm = -1;
        try { slm = JSON.parse(sd).lm || -1; } catch(e) {}
        if (slm >= 1 && slm <= 8) {
          layoutMode = slm;
          applyLayoutMode();
          editorOpen = false;
          _slotEverLoaded = true;
          _slotLoadedCustom = false;
          edSlotIsLoaded = false;
        } else {
          edUnpackLayout(sd); edSyncLiveProps();
          if (layoutMode === 0) { layoutMode = 1; applyLayoutMode(); editorOpen = false; }
        }
      }
      api.memory.set(pageKey + "gameLayout", String(layoutMode));
    } else if (next >= 100) {
      // Custom layout — unpack and sync live props so panels move immediately
      var cidx = next - 100;
      edActiveCustom    = cidx;
      edActiveCycleSlot = -1;
      var d = customLayouts[cidx] ? customLayouts[cidx].data : "";
      if (d) { edUnpackLayout(d); edSyncLiveProps(); }
      if (layoutMode === 0) { layoutMode = 1; applyLayoutMode(); editorOpen = false; }
      api.memory.set(pageKey + "gameLayout", String(layoutMode));
    } else {
      // Built-in layout
      edActiveCustom    = -1;
      edActiveCycleSlot = -1;
      layoutMode = next;
      applyLayoutMode();
      editorOpen = false;
      _slotEverLoaded = false;
      _slotLoadedCustom = false;
      edSlotIsLoaded = false;
      api.memory.set(pageKey + "gameLayout", String(layoutMode));
    }
  }

  function openEditor() {
    // Use current layoutMode directly — this is always the correct layout to show in editor.
    var prevLayout = layoutMode;
    api.memory.set(pageKey + "gameLayoutBeforeEdit", prevLayout);

    // Suppress onEd*Changed side-effects while seeding.
    _seedingEditor = true;

    // Seed ed* directly from live properties so the editor opens showing exactly
    // what is on screen — no slot auto-restore, no stale state from a previous session.
    edSelectedX     = selectedX;
    edSpacing       = spacingOverride >= 0 ? spacingOverride : autoSpacing;
    edScaleStep     = scaleStep;
    edFlatMode      = flatMode;
    edYDrop         = yDropPerSlot;
    edSelectedY     = vpx(0);
    edViewOffsetY   = vpx(0);
    // Seed center scale and base scale to exactly match what the current layout renders,
    // so neither the center panel nor side panels jump in size when the editor opens.
    // Layouts 1–4: center=1.0, sides arc down from 1.0 using scaleStep.
    //   edBaseScale must be 1.0 (not uniBaseScale=0.55) or side panels shrink on open.
    // Layout 5 (BigBox): center=1.0, sides not shown.
    // Layout 6/7 (Uniflow/Carousel): center=uniBaseScale, sides arc from uniBaseScale.
    if (prevLayout === 6 || prevLayout === 7) {
      edCenterScale = uniBaseScale;
      edBaseScale   = uniBaseScale;
    } else if (prevLayout === 5) {
      edCenterScale = 1.0;
      edBaseScale   = uniBaseScale;   // BigBox sides hidden; value doesn't matter, use default
    } else if (flatMode) {
      edCenterScale = 1.0;
      edBaseScale   = 1.0;
    } else {
      // Layouts 1–4: panels scale from 1.0 at center outward
      edCenterScale = 1.0;
      edBaseScale   = 1.0;
    }
    edCenterZ       = edCustomDefaultZ;
    edSideZ         = 20;
    edCenterOffsetX = 0;   edCenterOffsetY  = 0;
    edLeftCorrectX  = 0;   edRightCorrectX  = 0;
    edLeftCorrectY  = 0;   edRightCorrectY  = 0;
    edAsymArc       = false; edArcStepLeft  = scaleStep; edArcStepRight = scaleStep;
    edAsymScale     = false; edBaseScaleLeft = edBaseScale; edBaseScaleRight = edBaseScale;
    edAsymSpacing   = false; edSpacingLeft  = edSpacing;  edSpacingRight  = edSpacing;
    edAsymYDrop     = false; edYDropLeft    = vpx(0);     edYDropRight    = vpx(0);
    edArcCurve      = 0.0;
    edAsymYCurve    = false; edYCurveLeft   = 0.0;        edYCurveRight   = 0.0;
    edCenterRotation = 0;    edRotationBias = 0;
    // Carry tilt through for layout 7 (Carousel); for all other layouts zero tilt.
    // Also seed layout 7's canonical tilt values so they're correct even if the
    // props were left zeroed from a previous session or after cycling away.
    if (prevLayout === 7) {
      if (edTiltNear === 0 && edTiltFar === 0 && !edAsymTilt) {
        // Props are at defaults — restore layout 7's canonical tilt so the editor
        // opens showing the same tilt the Carousel was rendering.
        edTiltCenter = 0; edTiltNear = 18; edTiltFar = 42;
        edAsymTilt = false; edTiltLeftNear = 0; edTiltLeftFar = 0; edTiltRightNear = 0; edTiltRightFar = 0;
      }
      // else: non-zero tilt already in props (user customised it) — keep as-is.
    } else {
      edTiltCenter = 0; edTiltNear = 0; edTiltFar = 0;
      edAsymTilt = false; edTiltLeftNear = 0; edTiltLeftFar = 0; edTiltRightNear = 0; edTiltRightFar = 0;
    }
    edActiveSlot    = -1;
    edSlotIsLoaded  = false;
    edPreSlotLayout = layoutMode;
    _slotEverLoaded = false;
    _slotLoadedCustom = false;
    _slotLoadedLayout = layoutMode;  // snapshot layout before any slot loaded
    edPreviewLayout = prevLayout;  // header shows the layout you came from, not 0

    // Seeding complete — release guard then do one clean sync.
    _seedingEditor = false;
    edSyncLiveProps();

    editorOpen   = true;
    edLoadSlots();
    api.memory.set(pageKey + "gameLayout", String(layoutMode));
  }

  function closeEditor() {
    editorOpen = false;
    edSlotsOpen = false;
    edResetOpen = false;
    edMoveOpen = false;
    edDebugOpen = false;
    edCollapsed  = false;
    edExpOpen     = false;
    edTiltOpen    = false;
    edWrapperOpen = false;
    edTabsOpen = false;
    edLibraryOpen = false;
    edLayersOpen  = false;
    // Persist libChan/libTitle/libSquare visibility flags before applyLayoutMode resets them
    api.memory.set(pageKey + "libChanEnabled", libChanEnabled    ? "1" : "0");
    api.memory.set(pageKey + "libChanVisible", libChanVisible    ? "1" : "0");
    api.memory.set(pageKey + "libSquareEnabled", libSquareEnabled  ? "1" : "0");
    api.memory.set(pageKey + "libTitleEnabled", libTitleEnabled   ? "1" : "0");
    api.memory.set(pageKey + "libTitleVisible", libTitleVisible   ? "1" : "0");
    api.memory.set(pageKey + "libItemBorder", libItemBorder     ? "1" : "0");
    api.memory.set(pageKey + "libTitleBorder", libTitleBorder    ? "1" : "0");
    api.memory.set(pageKey + "libChanSize",       String(libChanSize));
    api.memory.set(pageKey + "libChanBold", libChanBold       ? "1" : "0");
    api.memory.set(pageKey + "libChanColorMode",  String(libChanColorMode));
    api.memory.set(pageKey + "libChanListX",      String(libChanListX));
    api.memory.set(pageKey + "libChanListY",      String(libChanListY));
    api.memory.set(pageKey + "libChanOffsetX",    String(libChanOffsetX));
    api.memory.set(pageKey + "libChanOffsetY",    String(libChanOffsetY));
    api.memory.set(pageKey + "libChanPathCount",  String(libChanPathCount));
    api.memory.set(pageKey + "libChanMode",       String(libChanMode));
    api.memory.set(pageKey + "libChanScaleOrigin", String(libChanScaleOrigin));
    api.memory.set(pageKey + "libChanTextOrigin", "0");  // always reset to left-aligned
    api.memory.set(pageKey + "libPathStartX",     String(libPathStartX));
    api.memory.set(pageKey + "libPathStartY",     String(libPathStartY));
    api.memory.set(pageKey + "libPathEndX",       String(libPathEndX));
    api.memory.set(pageKey + "libPathEndY",       String(libPathEndY));
    api.memory.set(pageKey + "libTitleSize",      String(libTitleSize));
    api.memory.set(pageKey + "libTitleOffsetX",   String(libTitleOffsetX));
    api.memory.set(pageKey + "libTitleOffsetY",   String(libTitleOffsetY));
    api.memory.set(pageKey + "libTitleColorMode", String(libTitleColorMode));
    api.memory.set(pageKey + "libSquareOffsetX",  String(libSquareOffsetX));
    api.memory.set(pageKey + "libSquareOffsetY",  String(libSquareOffsetY));
    // Return to the layout that was active before the editor was opened.
    // Clear stale cycle-tracking state so Y-cycle picks up cleanly from here.
    edActiveCycleSlot = -1;
    edActiveCustom    = -1;
    if (edActiveSlot >= 1) api.memory.set(pageKey + "edLastActiveSlot", String(edActiveSlot));
    else api.memory.set(pageKey + "edLastActiveSlot", "-1");
    // Determine which layout to return to.
    // If a slot is active, use the layout the slot was originally saved under.
    // Otherwise use edPreviewLayout (the header button selection).
    // Use current layoutMode if a slot was loaded (it was set by edLoadSlot).
    // Otherwise use edPreviewLayout (header button) or gameLayoutBeforeEdit.
    var targetLayout;
    if (_slotEverLoaded && _slotLoadedLayout >= 1 && _slotLoadedLayout <= 8) {
      targetLayout = _slotLoadedLayout;
    } else if (edPreviewLayout >= 1 && edPreviewLayout <= 8) {
      targetLayout = edPreviewLayout;
    } else {
      targetLayout = parseInt(api.memory.get(pageKey + "gameLayoutBeforeEdit") || "1");
    }
    if (targetLayout < 1 || targetLayout > 8) { targetLayout = 1; }

    // Return to the target layout — _seedingEditor prevents onEd*Changed from forcing layoutMode=0.
    _seedingEditor = true;
    _closingEditor = true;
    layoutMode = targetLayout;
    _closingEditor = false;
    if (_slotLoadedCustom) { edSlotIsLoaded = true; }
    _seedingEditor = false;
    edSyncLiveProps();
    if (edActiveSlot >= 1) {
      // Slot loaded — save ONLY geometry under this layout, not channel settings.
      // Channel name settings belong to the layout independently of the slot.
      saveLayoutGeometry(targetLayout);
    } else {
      // No slot — restore this layout's own previously saved settings.
      loadLayoutChanSettings(targetLayout);
    }
    api.memory.set(pageKey + "gameLayout", String(layoutMode));
  }

  Component.onCompleted: {
    // ── Reset Layout 1 (Default) channel settings on every boot ──
    // Layout 1 must always open with left-aligned titles and zero offsets.
    // Other layouts intentionally save their own channel settings (e.g. center).
    var _l1key = pageKey + "layoutChan_1_data";
    var _l1raw = api.memory.get(_l1key);
    if (_l1raw && _l1raw.length > 0) {
      try {
        var _l1d = JSON.parse(_l1raw);
        var _changed = false;
        if (_l1d.lcTo !== 0)  { _l1d.lcTo = 0;  _changed = true; }
        if (_l1d.lcLx !== 0)  { _l1d.lcLx = 0;  _changed = true; }
        if (_l1d.lcLy !== 0)  { _l1d.lcLy = 0;  _changed = true; }
        if (_l1d.lcOx !== 0)  { _l1d.lcOx = 0;  _changed = true; }
        if (_l1d.lcOy !== 0)  { _l1d.lcOy = 0;  _changed = true; }
        if (_l1d.lpSx !== 0)  { _l1d.lpSx = 0;  _changed = true; }
        if (_l1d.lpSy !== 0)  { _l1d.lpSy = 0;  _changed = true; }
        if (_l1d.lpEx !== 0)  { _l1d.lpEx = 0;  _changed = true; }
        if (_l1d.lpEy !== 0)  { _l1d.lpEy = 0;  _changed = true; }
        if (_changed) api.memory.set(_l1key, JSON.stringify(_l1d));
      } catch(e) {}
    }

    // Load reset layout preference
    var savedSL = parseInt(api.memory.get(pageKey + "edResetLayout") || "-1");
    if (!isNaN(savedSL) && savedSL >= 0 && savedSL <= 8) edResetLayout = savedSL;

    // Load force-startup override
    var savedFS = parseInt(api.memory.get(pageKey + "edForceStartup") || "-1");
    if (!isNaN(savedFS) && savedFS >= 0 && savedFS <= 8) edForceStartup = savedFS;

    // If a force-startup is set, it wins — write it as gameLayout so it's applied below
    if (edForceStartup >= 0) {
      api.memory.set(pageKey + "gameLayout", String(edForceStartup === 0 ? 0 : edForceStartup));
    }

    var raw = api.memory.get(pageKey + "gameLayout");
    var saved = (raw !== null && raw !== undefined && raw !== "") ? parseInt(raw) : -1;

    // Valid range is 1-7 (Default through Carousel). Editor (0) is never restored on boot —
    // always fall back to Default so the dashboard is always the first thing seen.
    if (!isNaN(saved) && saved >= 1 && saved <= 8) {
      layoutMode = saved;
    } else {
      // Stale/editor/missing value — use reset layout or Default
      layoutMode = (edResetLayout >= 1 && edResetLayout <= 8) ? edResetLayout : 1;
    }

    // Always re-save the correct value — never save editor (0) as the boot layout
    api.memory.set(pageKey + "gameLayout", String(layoutMode));

    var savedZ = parseFloat(api.memory.get(pageKey + "edCustomDefaultZ") || "999");
    if (!isNaN(savedZ)) edCustomDefaultZ = savedZ;
    var savedVB = parseInt(api.memory.get(pageKey + "visibleBoxes") || "7");
    if (!isNaN(savedVB) && savedVB >= 1 && savedVB <= 30) visibleBoxes = savedVB;
    var savedUSO = api.memory.get(pageKey + "edUseScreenOrigin");
    if (savedUSO !== null && savedUSO !== undefined) edUseScreenOrigin = (savedUSO === "true");
    var savedUMC = api.memory.get(pageKey + "edUseMonitorCount");
    if (savedUMC !== null && savedUMC !== undefined) edUseMonitorCount = (savedUMC === "true");
    var savedVC = parseInt(api.memory.get(pageKey + "edVisibleCount") || "7");
    if (!isNaN(savedVC) && savedVC >= 1 && savedVC <= 7) edVisibleCount = savedVC;
    applyLayoutMode();
    edLoadSlots();
    // Slot restoration is deferred to onWidthChanged so that uniSelectedX and
    // autoSpacing are computed from the real width, not 0 from Component.onCompleted.
    loadCustomLayouts();
    var savedCBI = api.memory.get(pageKey + "cycleBuiltIn");
    if (savedCBI !== null && savedCBI !== undefined) cycleBuiltIn = (savedCBI === "true");
    var savedCC = api.memory.get(pageKey + "cycleCustom");
    if (savedCC !== null && savedCC !== undefined) cycleCustom = (savedCC === "true");
    var savedCS = api.memory.get(pageKey + "cycleSlots");
    if (savedCS !== null && savedCS !== undefined) cycleSlots = (savedCS === "true");
    var savedCE = api.memory.get(pageKey + "cycleEditor");
    if (savedCE !== null && savedCE !== undefined) cycleEditor = (savedCE === "true");
    // Load wrapper properties
    var wCR = api.memory.get(pageKey + "wrapCornerRadius");     if (wCR !== null && wCR !== undefined) wrapCornerRadius = parseFloat(wCR);
    var wRS = api.memory.get(pageKey + "wrapReflectionSize");   if (wRS !== null && wRS !== undefined) wrapReflectionSize = parseFloat(wRS);
    var wRO = api.memory.get(pageKey + "wrapReflectionOpacity"); if (wRO !== null && wRO !== undefined) wrapReflectionOpacity = parseFloat(wRO);
    var wRB = api.memory.get(pageKey + "wrapReflectionBlur");   if (wRB !== null && wRB !== undefined) wrapReflectionBlur = parseFloat(wRB);
    var wSO  = api.memory.get(pageKey + "wrapShadowOn");        if (wSO  !== null && wSO  !== undefined) wrapShadowOn      = (wSO === "true");
    var wSOp = api.memory.get(pageKey + "wrapShadowOpacity");   if (wSOp !== null && wSOp !== undefined) wrapShadowOpacity = parseFloat(wSOp);
    var wSM  = api.memory.get(pageKey + "wrapShadowMode");      if (wSM  !== null && wSM  !== undefined) wrapShadowMode    = parseInt(wSM);
    var wSR  = api.memory.get(pageKey + "wrapShadowRadius");    if (wSR  !== null && wSR  !== undefined) wrapShadowRadius  = parseFloat(wSR);
    var wSOX = api.memory.get(pageKey + "wrapShadowOffsetX");   if (wSOX !== null && wSOX !== undefined) wrapShadowOffsetX = parseFloat(wSOX);
    var wSOY = api.memory.get(pageKey + "wrapShadowOffsetY");   if (wSOY !== null && wSOY !== undefined) wrapShadowOffsetY = parseFloat(wSOY);
    var wSC  = api.memory.get(pageKey + "wrapShadowColor");     if (wSC  !== null && wSC  !== undefined && wSC !== "") wrapShadowColor = wSC;
    // Safety: if both are false, reset built-in to true
    if (!cycleBuiltIn && !cycleCustom && !cycleSlots) { cycleBuiltIn = true; api.memory.set(pageKey + "cycleBuiltIn", "true"); }
    // Channel/title/path settings are loaded per-layout by applyLayoutMode()
    // above via loadLayoutChanSettings(). Do not re-read the global flat keys
    // here — they hold the last-closed layout's settings and would overwrite
    // the correct per-layout values just restored.
    libChanDebug = false;
    libPathEnabled = true;
    // Reset editor overlay position so it always opens at the top-left on boot
    edOverlayOffsetX   = 0;      edOverlayOffsetY   = 0;
    edPanelAtBottom    = false;
    // Force channel text alignment to left (0) on every boot.
    // lcTo=1 (center) can get baked into saved layout JSON and persist incorrectly.
    libChanTextOrigin = 0;
    _booting = false;  // from now on, applyLayoutMode restores saved channel settings
    // Force path re-evaluation after all boot state is settled.
    // Bumping now covers the case where width was already non-zero before onCompleted ran
    // (so onWidthChanged already fired and _widthReady is true but the bump never happened).
    edPathVersion = edPathVersion + 1;
    pathRefreshTimer.restart();
  }

  // Re-apply the layout once the real pixel width is known.
  // At Component.onCompleted width is 0, so autoSpacing/uniSelectedX are wrong.
  // This fires once after layout, corrects selectedX/spacing, and re-syncs live props.
  property bool _widthReady: false
  onWidthChanged: {
    if (width > 0 && !_widthReady) {
      _widthReady = true;
      // Re-apply the current layout with the real width so spacing/selectedX are correct.
      if (layoutMode >= 1 && layoutMode <= 8) {
        var _wasBooting = _booting;
        _booting = true;   // suppress loadLayoutChanSettings during this re-apply
        applyLayoutMode();
        _booting = _wasBooting;
      }
      // If a custom slot or custom layout was restored at boot (via syncPanelsLayout),
      // re-sync live props now that width is real. Any spacing values that were
      // computed when width=0 (autoSpacing=0) are corrected here so the path is
      // correct before the first navigation, not just after it.
      if (edSlotIsLoaded || edCustomIsLoaded) {
        edSyncLiveProps();
      }
      // Force PathView path to re-evaluate now that slotX/slotY/slotScale have correct values.
      // Without this bump the path is frozen at the values computed when width was 0.
      edPathVersion = edPathVersion + 1;
      pathRefreshTimer.restart();
    }
  }

  height:                  panelHeight + vpx(Styling.panelReflectionSize)
  highlightMoveDuration:   400
  pathItemCount:           27
  cacheItemCount:          33
  movementDirection:       PathView.Positive
  clip:                    false
  layer.enabled:           false
  highlightRangeMode:      PathView.StrictlyEnforceRange
  preferredHighlightBegin: 0.5
  preferredHighlightEnd:   0.5
  // Disable PathView drag/flick while editor is open so it stops eating editor mouse clicks.
  interactive:             !panelsList.editorOpen

  property int  previousIndex: 0
  property real panelWidth:    vpx(Styling.panelStyles[contentType].width  || 380)
  property real panelHeight:   vpx(Styling.panelStyles[contentType].height || 550)
  property var  panelContent
  property var  indexPersistenceKey
  property var  contentType

  function nextItem()                 { if (currentIndex < model.count - 1) incrementCurrentIndex(); }
  function previousItem()             { if (currentIndex > 0)               decrementCurrentIndex(); }
  function navigateForwardQuickly()   { currentIndex = Math.min(currentIndex + 10, model.count - 1); }
  function navigateBackwardsQuickly() { currentIndex = Math.max(currentIndex - 10, 0); }

  Keys.onPressed: {
    if (!event.isAutoRepeat && event.key === Qt.Key_Y) { console.log("Y pressed, layoutMode:", layoutMode, "cycleBuiltIn:", cycleBuiltIn, "cycleCustom:", cycleCustom, "customLayouts.length:", customLayouts.length); cycleLayout(); event.accepted = true; return; }
    // B button closes editor
    if (!event.isAutoRepeat && event.key === Qt.Key_B && layoutMode === 0) {
      closeEditor(); event.accepted = true; return;
    }
    if (layoutMode === 0 && !event.isAutoRepeat) {
      var step = vpx(5); var scStep = 0.01;
      switch (event.key) {

        case Qt.Key_Q:        edBaseScale = Math.min(1.0, edBaseScale + scStep); event.accepted = true; break;
        case Qt.Key_A:        edBaseScale = Math.max(0.05, edBaseScale - scStep); event.accepted = true; break;
        case Qt.Key_W:        edScaleStep = Math.min(0.3, edScaleStep + scStep); event.accepted = true; break;
        case Qt.Key_S:        edScaleStep = Math.max(0.0, edScaleStep - scStep); event.accepted = true; break;
        case Qt.Key_E:        edYDrop += vpx(2); event.accepted = true; break;
        case Qt.Key_D:        edYDrop = Math.max(0, edYDrop - vpx(2)); event.accepted = true; break;
        case Qt.Key_F:        edFlatMode = !edFlatMode; event.accepted = true; break;
        case Qt.Key_C:        edColorMode = (edColorMode + 1) % 4; event.accepted = true; break;
        case Qt.Key_B:        edShowBounds = !edShowBounds; event.accepted = true; break;
        case Qt.Key_G:        edShowBg = !edShowBg; event.accepted = true; break;
        default:              event.accepted = true; break;
      }
    }
  }

  onModelChanged:       { if (model && model.count > 1) panelUnfoldSound.play(); }
  onCurrentItemChanged: {
    if (currentIndex !== previousIndex) {
      if (currentIndex > previousIndex) panelRightSound.play();
      if (currentIndex < previousIndex) panelLeftSound.play();
      if (indexPersistenceKey !== undefined) api.memory.set(indexPersistenceKey, currentIndex);
    }
    previousIndex = currentIndex;
  }

  path: Path {
    startX: panelsList.slotX(-13)
    startY: panelsList.slotY(-13)

    PathLine      { x: panelsList.slotX(-13); y: panelsList.slotY(-13) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(-13) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(-13) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(-13) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(-13) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: -13 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(-13) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(-12) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(-12) }
    PathPercent   { value: 0.0000 }

    PathLine      { x: panelsList.slotX(-12); y: panelsList.slotY(-12) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(-12) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(-12) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(-12) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(-12) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: -12 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(-12) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(-11) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(-11) }
    PathPercent   { value: 0.0385 }

    PathLine      { x: panelsList.slotX(-11); y: panelsList.slotY(-11) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(-11) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(-11) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(-11) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(-11) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: -11 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(-11) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(-10) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(-10) }
    PathPercent   { value: 0.0769 }

    PathLine      { x: panelsList.slotX(-10); y: panelsList.slotY(-10) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(-10) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(-10) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(-10) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(-10) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: -10 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(-10) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(-9) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(-9) }
    PathPercent   { value: 0.1154 }

    PathLine      { x: panelsList.slotX(-9); y: panelsList.slotY(-9) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(-9) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(-9) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(-9) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(-9) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: -9 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(-9) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(-8) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(-8) }
    PathPercent   { value: 0.1538 }

    PathLine      { x: panelsList.slotX(-8); y: panelsList.slotY(-8) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(-8) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(-8) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(-8) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(-8) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: -8 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(-8) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(-7) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(-7) }
    PathPercent   { value: 0.1923 }

    PathLine      { x: panelsList.slotX(-7); y: panelsList.slotY(-7) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(-7) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(-7) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(-7) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(-7) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: -7 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(-7) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(-6) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(-6) }
    PathPercent   { value: 0.2308 }

    PathLine      { x: panelsList.slotX(-6); y: panelsList.slotY(-6) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(-6) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(-6) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(-6) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(-6) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: -6 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(-6) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(-5) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(-5) }
    PathPercent   { value: 0.2692 }

    PathLine      { x: panelsList.slotX(-5); y: panelsList.slotY(-5) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(-5) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(-5) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(-5) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(-5) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: -5 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(-5) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(-4) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(-4) }
    PathPercent   { value: 0.3077 }

    PathLine      { x: panelsList.slotX(-4); y: panelsList.slotY(-4) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(-4) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(-4) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(-4) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(-4) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: -4 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(-4) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(-3) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(-3) }
    PathPercent   { value: 0.3462 }

    PathLine      { x: panelsList.slotX(-3); y: panelsList.slotY(-3) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(-3) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(-3) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(-3) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(-3) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: -3 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(-3) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(-2) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(-2) }
    PathPercent   { value: 0.3846 }

    PathLine      { x: panelsList.slotX(-2); y: panelsList.slotY(-2) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(-2) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(-2) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(-2) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(-2) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: -2 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(-2) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(-1) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(-1) }
    PathPercent   { value: 0.4231 }

    PathLine      { x: panelsList.slotX(-1); y: panelsList.slotY(-1) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(-1) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(-1) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(-1) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(-1) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: -1 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(-1) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(0) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(0) }
    PathPercent   { value: 0.4615 }

    PathLine      { x: panelsList.slotX(0); y: panelsList.slotY(0) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(0) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(0) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(0) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(0) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 0 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(0) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(1) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(1) }
    PathPercent   { value: 0.5000 }

    PathLine      { x: panelsList.slotX(1); y: panelsList.slotY(1) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(1) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(1) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(1) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(1) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 1 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(1) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(2) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(2) }
    PathPercent   { value: 0.5385 }

    PathLine      { x: panelsList.slotX(2); y: panelsList.slotY(2) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(2) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(2) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(2) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(2) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 2 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(2) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(3) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(3) }
    PathPercent   { value: 0.5769 }

    PathLine      { x: panelsList.slotX(3); y: panelsList.slotY(3) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(3) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(3) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(3) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(3) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 3 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(3) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(4) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(4) }
    PathPercent   { value: 0.6154 }

    PathLine      { x: panelsList.slotX(4); y: panelsList.slotY(4) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(4) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(4) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(4) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(4) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 4 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(4) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(5) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(5) }
    PathPercent   { value: 0.6538 }

    PathLine      { x: panelsList.slotX(5); y: panelsList.slotY(5) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(5) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(5) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(5) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(5) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 5 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(5) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(6) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(6) }
    PathPercent   { value: 0.6923 }

    PathLine      { x: panelsList.slotX(6); y: panelsList.slotY(6) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(6) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(6) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(6) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(6) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 6 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(6) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(7) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(7) }
    PathPercent   { value: 0.7308 }

    PathLine      { x: panelsList.slotX(7); y: panelsList.slotY(7) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(7) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(7) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(7) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(7) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 7 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(7) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(8) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(8) }
    PathPercent   { value: 0.7692 }

    PathLine      { x: panelsList.slotX(8); y: panelsList.slotY(8) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(8) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(8) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(8) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(8) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 8 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(8) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(9) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(9) }
    PathPercent   { value: 0.8077 }

    PathLine      { x: panelsList.slotX(9); y: panelsList.slotY(9) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(9) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(9) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(9) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(9) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 9 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(9) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(10) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(10) }
    PathPercent   { value: 0.8462 }

    PathLine      { x: panelsList.slotX(10); y: panelsList.slotY(10) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(10) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(10) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(10) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(10) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 10 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(10) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(11) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(11) }
    PathPercent   { value: 0.8846 }

    PathLine      { x: panelsList.slotX(11); y: panelsList.slotY(11) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(11) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(11) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(11) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(11) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 11 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(11) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(12) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(12) }
    PathPercent   { value: 0.9231 }

    PathLine      { x: panelsList.slotX(12); y: panelsList.slotY(12) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(12) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(12) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(12) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(12) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 12 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(12) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(13) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(13) }
    PathPercent   { value: 0.9615 }

    PathLine      { x: panelsList.slotX(13); y: panelsList.slotY(13) }
    PathAttribute { name: "itemScale";         value: panelsList.slotScale(13) }
    PathAttribute { name: "itemZ";             value: panelsList.slotZ(13) }
    PathAttribute { name: "itemOffsetY";       value: 0 }
    PathAttribute { name: "itemRotation";      value: panelsList.slotRotation(13) }
    PathAttribute { name: "itemTiltY";         value: panelsList.slotTiltY(13) }
    PathAttribute { name: "itemCenterOffX";    value: 0 }
    PathAttribute { name: "itemCenterOffY";    value: 0 }
    PathAttribute { name: "screenIndex";       value: 13 }
    PathAttribute { name: "itemX";             value: panelsList.slotX(13) }
    PathAttribute { name: "previousItemX";     value: panelsList.slotX(13) }
    PathAttribute { name: "previousItemScale"; value: panelsList.slotScale(13) }
    PathPercent   { value: 1.0000 }

  }

  // ════════════════════════════════════════════════════════════════

  // ════════════════════════════════════════════════════════════════
  // DEBUG WALLPAPER OVERLAY — dynamically parented to scene root
  // so it sits above the theme background but behind panels/wrapper
  // ════════════════════════════════════════════════════════════════
  property var _dbgOverlay: null

  Component {
    id: debugOverlayComponent
    Image {
      fillMode: Image.Stretch
      smooth: true
    }
  }

  function _updateDebugOverlay() {
    var imgs = [
      "../assets/images/wallpapers/Checker Board.png",
      "../assets/images/wallpapers/Debug Border.png",
      "../assets/images/wallpapers/Edit Mod Vertical.png",
      "../assets/images/wallpapers/Edit Mode Horizonal.png",
      "../assets/images/wallpapers/Test Zone.png"
    ];
    var show = (editorOpen && edDebugEnabled && edDebugWallpaper >= 0 && edDebugWallpaper < 5);
    if (!_dbgOverlay && show && parent) {
      _dbgOverlay = debugOverlayComponent.createObject(parent, { z: -1 });
    }
    if (_dbgOverlay) {
      _dbgOverlay.visible = show;
      _dbgOverlay.source  = show ? imgs[edDebugWallpaper] : "";
      if (parent) {
        _dbgOverlay.x      = 0;
        _dbgOverlay.y      = 0;
        _dbgOverlay.width  = parent.width;
        _dbgOverlay.height = parent.height;
      }
    }
  }

  onEdDebugEnabledChanged:    _updateDebugOverlay()
  onEdDebugWallpaperChanged:  _updateDebugOverlay()
  onLayoutModeChanged: {
    if (_prevLayoutMode >= 1 && _prevLayoutMode <= 8) {
      // If a slot is driving the outgoing layout, save only geometry not channel settings.
      if (edActiveSlot >= 1) { saveLayoutGeometry(_prevLayoutMode); }
      else { saveLayoutChanSettings(_prevLayoutMode); }
    }
    // When cycling to a different layout (not via closeEditor), clear the active
    // slot so useEdPath stops using ed* values and the new layout renders with
    // its own settings. Skip this when closeEditor is changing layoutMode.
    if (!_closingEditor && _prevLayoutMode !== layoutMode && layoutMode !== 0) {
      edActiveSlot = -1;
      edCustomIsLoaded = false;
    }
    _prevLayoutMode = layoutMode;
    _updateDebugOverlay();
  }

  // ════════════════════════════════════════════════════════════════
  // LAYOUT EDITOR OVERLAY
  // ════════════════════════════════════════════════════════════════
  Rectangle {
    id: editorOverlay
    visible: panelsList.editorOpen
    y:      panelsList.edPanelAtBottom
              ? (-panelsList.y + (panelsList.parent ? panelsList.parent.height : 600) - (panelsList.edCollapsed ? vpx(24) : vpx(162)) + panelsList.edOverlayOffsetY)
              : (-panelsList.y + panelsList.edOverlayOffsetY)
    x:      -panelsList.x + panelsList.edOverlayOffsetX
    width:   panelsList.parent ? panelsList.parent.width : panelsList.width
    height:  panelsList.edCollapsed ? vpx(24) : vpx(162)
    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
    color: {
      if (panelsList.edBgMode === 1) return Qt.rgba(0, 0, 0, 0.99);
      if (panelsList.edBgMode === 2) return Qt.rgba(0.04, 0.04, 0.06, 0.60);
      if (panelsList.edBgMode === 3) return "transparent";
      if (panelsList.edBgMode === 4) return Qt.rgba(1, 1, 1, 0.97);
      if (panelsList.edBgMode === 5) return Qt.rgba(0.55, 0.55, 0.58, 0.97);
      return Qt.rgba(0.04, 0.04, 0.06, 0.97);
    }
    border.color: panelsList.edBgMode < 3 ? Qt.rgba(safeAccent.r, safeAccent.g, safeAccent.b, 0.30) : "transparent"
    border.width: vpx(1)
    clip: true
    z: 9999

    // ── Shared sub-components ──────────────────────────────────────
    component StepBtn: Rectangle {
      id: stepRoot
      property string label: "+"
      property color  btnColor: Qt.rgba(1,1,1,0.10)
      signal clicked()
      width: vpx(18); height: vpx(18); radius: vpx(3)
      property bool _darkText: panelsList.edColorMode === 1 || panelsList.edBgMode === 4 || panelsList.edBgMode === 5
      color: sMa.containsMouse
        ? (_darkText ? Qt.rgba(0,0,0,0.18) : Qt.rgba(1,1,1,0.28))
        : (_darkText ? Qt.rgba(0,0,0,0.10) : stepRoot.btnColor)
      border.color: _darkText ? Qt.rgba(0,0,0,0.30) : Qt.rgba(1,1,1,0.20); border.width: vpx(1)
      StyledText { anchors.centerIn: parent; text: stepRoot.label; font.pixelSize: vpx(9); font.bold: true
        color: _darkText ? "#000000" : "#ffffff" }
      MouseArea { id: sMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: stepRoot.clicked() }
    }

    component Pill: Rectangle {
      id: pillRoot
      property string label: ""
      property bool   on:    false
      property color  onCol: "#44cc66"
      signal toggled()
      height: vpx(16); radius: vpx(3)
      width: pillTxt.implicitWidth + vpx(16)
      color: on ? Qt.rgba(onCol.r, onCol.g, onCol.b, 0.25) : Qt.rgba(1,1,1,0.07)
      border.width: vpx(1); border.color: on ? onCol : Qt.rgba(1,1,1,0.18)
      anchors.verticalCenter: parent ? parent.verticalCenter : undefined
      Row { anchors.centerIn: parent; spacing: vpx(4)
        Rectangle { width: vpx(6); height: vpx(6); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
          color: pillRoot.on ? pillRoot.onCol : Qt.rgba(1,1,1,0.25) }
        StyledText { id: pillTxt; text: pillRoot.label; font.pixelSize: vpx(9); font.bold: true
          color: "#ffffff"; opacity: pillRoot.on ? 1.0 : 0.55 }
      }
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pillRoot.toggled() }
    }

    // ── Title Bar ──────────────────────────────────────────────────
    Rectangle {
      id: titleBar
      anchors { top: parent.top; left: parent.left; right: parent.right }
      height: vpx(24); color: "transparent"
      Rectangle { anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: vpx(1); color: safeAccent; opacity: 0.4 }

      // Left cluster: title + layout 6 badge + layout numbers
      Row {
        id: leftClusterRow
        anchors { left: parent.left; leftMargin: vpx(10); verticalCenter: parent.verticalCenter }
        spacing: vpx(6)
        Row { spacing: vpx(4); anchors.verticalCenter: parent.verticalCenter
          StyledText { text: "🦄"; font.pixelSize: vpx(12); anchors.verticalCenter: parent.verticalCenter }
          StyledText { text: "UniKron"; font.pixelSize: vpx(10); font.bold: true; color: "#ffffff"; anchors.verticalCenter: parent.verticalCenter }
          StyledText { text: " | "; font.pixelSize: vpx(10); font.bold: true; color: safeAccent; anchors.verticalCenter: parent.verticalCenter }
          StyledText { text: "Layout Manager"; font.pixelSize: vpx(10); font.bold: true; color: safeAccent; anchors.verticalCenter: parent.verticalCenter }
        }

      }

      // ── Collapse / Expand arrow — centered in title bar ─────────
      Rectangle {
        id: collapseArrow
        anchors.centerIn: parent
        width: vpx(24); height: vpx(16); radius: vpx(3)
        color: collapseMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.07)
        border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.22)
        StyledText { anchors.centerIn: parent; text: panelsList.edCollapsed ? "▼" : "▲"; font.pixelSize: vpx(10); color: "#ffffff" }
        MouseArea {
          id: collapseMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: {
            panelsList.edCollapsed = !panelsList.edCollapsed;
            if (panelsList.edCollapsed) {
              panelsList.edSlotsOpen = false; panelsList.edResetOpen = false;
              panelsList.edMoveOpen = false; panelsList.edDebugOpen = false;
              panelsList.edLibraryOpen = false;
            }
          }
        }
      }

      // ── Templates — sits left of Slots ────────────────────────────
      Pill {
        id: templatesBtn
        label: "Templates"
        on: panelsList.edTemplatesOpen
        onCol: "#55bbff"
        anchors.right: slotsBtn.left
        anchors.rightMargin: vpx(4)
        anchors.verticalCenter: parent.verticalCenter
        onToggled: {
          panelsList.edCollapsed       = false;
          panelsList.edTemplatesOpen   = !panelsList.edTemplatesOpen;
          if (panelsList.edTemplatesOpen) { panelsList.edCustomsOpen = false; panelsList.edLibraryOpen = false; panelsList.edMoveOpen = false; panelsList.edSlotsOpen = false; panelsList.edResetOpen = false; panelsList.edDebugOpen = false; panelsList.edExpOpen = false; panelsList.edTiltOpen = false; panelsList.edWrapperOpen = false; panelsList.edTabsOpen = false; panelsList.edLayersOpen = false; }
        }
      }

      // ── Slots — sits between Templates and Customs ───────────────
      Pill {
        id: slotsBtn
        label: "Slots"
        on: panelsList.edSlotsOpen
        onCol: "#44cc66"
        anchors.right: customsBtn.left
        anchors.rightMargin: vpx(4)
        anchors.verticalCenter: parent.verticalCenter
        onToggled: {
          panelsList.edCollapsed   = false;
          panelsList.edSlotsOpen   = !panelsList.edSlotsOpen;
          if (panelsList.edSlotsOpen) { panelsList.edResetOpen = false; panelsList.edMoveOpen = false; panelsList.edDebugOpen = false; panelsList.edExpOpen = false; panelsList.edTiltOpen = false; panelsList.edLibraryOpen = false; panelsList.edWrapperOpen = false; panelsList.edTabsOpen = false; panelsList.edTemplatesOpen = false; panelsList.edCustomsOpen = false; panelsList.edLayersOpen = false; }
        }
      }

      // ── Customs — sits left of Library ──────────────────────────
      Pill {
        id: customsBtn
        label: "Customs"
        on: panelsList.edCustomsOpen
        onCol: "#ee9933"
        anchors.right: libraryBtn.left
        anchors.rightMargin: vpx(4)
        anchors.verticalCenter: parent.verticalCenter
        onToggled: {
          panelsList.edCollapsed     = false;
          panelsList.edCustomsOpen   = !panelsList.edCustomsOpen;
          if (panelsList.edCustomsOpen) { panelsList.edTemplatesOpen = false; panelsList.edLibraryOpen = false; panelsList.edMoveOpen = false; panelsList.edSlotsOpen = false; panelsList.edResetOpen = false; panelsList.edDebugOpen = false; panelsList.edExpOpen = false; panelsList.edTiltOpen = false; panelsList.edWrapperOpen = false; panelsList.edTabsOpen = false; panelsList.edLayersOpen = false; }
        }
      }

      // ── Library — sits immediately left of Layers ──────────────────
      Pill {
        id: libraryBtn
        label: "Library"
        on: panelsList.edLibraryOpen
        onCol: "#44aaff"
        anchors.right: layersBtn.left
        anchors.rightMargin: vpx(4)
        anchors.verticalCenter: parent.verticalCenter
        onToggled: {
          panelsList.edCollapsed     = false;
          panelsList.edLibraryOpen   = !panelsList.edLibraryOpen;
          if (panelsList.edLibraryOpen) { panelsList.edTemplatesOpen = false; panelsList.edCustomsOpen = false; panelsList.edMoveOpen = false; panelsList.edSlotsOpen = false; panelsList.edResetOpen = false; panelsList.edDebugOpen = false; panelsList.edExpOpen = false; panelsList.edTiltOpen = false; panelsList.edWrapperOpen = false; panelsList.edTabsOpen = false; panelsList.edLayersOpen = false; }
        }
      }

      // ── Layers — sits immediately left of Tilt ──────────────────────
      Pill {
        id: layersBtn
        label: "Layers"
        on: panelsList.edLayersOpen
        onCol: "#ff7733"
        anchors.right: tiltBtn.left
        anchors.rightMargin: vpx(4)
        anchors.verticalCenter: parent.verticalCenter
        onToggled: {
          panelsList.edCollapsed    = false;
          panelsList.edLayersOpen   = !panelsList.edLayersOpen;
          if (panelsList.edLayersOpen) { panelsList.edTemplatesOpen = false; panelsList.edCustomsOpen = false; panelsList.edLibraryOpen = false; panelsList.edMoveOpen = false; panelsList.edSlotsOpen = false; panelsList.edResetOpen = false; panelsList.edDebugOpen = false; panelsList.edExpOpen = false; panelsList.edTiltOpen = false; panelsList.edWrapperOpen = false; panelsList.edTabsOpen = false; }
        }
      }

      // ── Tilt — sits immediately left of Reset ─────────────────────
      Rectangle {
        id: tiltBtn
        anchors.right: resetBtn.left
        anchors.rightMargin: vpx(4)
        anchors.verticalCenter: parent.verticalCenter
        height: vpx(16); radius: vpx(3); width: tiltBtnTxt.implicitWidth + vpx(16)
        color: panelsList.edTiltOpen ? Qt.rgba(0.05,0.55,0.50,0.40) : Qt.rgba(1,1,1,0.07)
        border.width: vpx(1)
        border.color: panelsList.edTiltOpen ? "#44ddcc" : Qt.rgba(1,1,1,0.22)
        Row { anchors.centerIn: parent; spacing: vpx(4)
          Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); anchors.verticalCenter: parent.verticalCenter
            color: panelsList.edTiltOpen ? "#44ddcc" : Qt.rgba(1,1,1,0.25) }
          StyledText { id: tiltBtnTxt; text: "Tilt"; font.pixelSize: vpx(9); font.bold: true
            color: "#ffffff"; opacity: panelsList.edTiltOpen ? 1.0 : 0.55 }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
          onClicked: {
            panelsList.edCollapsed = false;
            panelsList.edTiltOpen = !panelsList.edTiltOpen;
            if (panelsList.edTiltOpen) { panelsList.edSlotsOpen = false; panelsList.edResetOpen = false; panelsList.edMoveOpen = false; panelsList.edDebugOpen = false; panelsList.edExpOpen = false; panelsList.edLibraryOpen = false; panelsList.edWrapperOpen = false; panelsList.edTabsOpen = false; panelsList.edLayersOpen = false; }          }
        }
      }

      // ── Reset — sits immediately left of Move ────────────────────
      Rectangle {
        id: resetBtn
        anchors.right: moveBtn.left
        anchors.rightMargin: vpx(4)
        anchors.verticalCenter: parent.verticalCenter
        height: vpx(16); radius: vpx(3); width: startupBtnTxt.implicitWidth + vpx(16)
        color: panelsList.edResetOpen ? Qt.rgba(0.15,0.45,0.85,0.35) : (resetBtnMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.07))
        border.width: vpx(1); border.color: panelsList.edResetOpen ? "#44aaff" : Qt.rgba(1,1,1,0.22)
        Row { anchors.centerIn: parent; spacing: vpx(4)
          Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); anchors.verticalCenter: parent.verticalCenter
            color: panelsList.edResetOpen ? "#44aaff" : Qt.rgba(1,1,1,0.25) }
          StyledText { id: startupBtnTxt; text: "Reset"; font.pixelSize: vpx(9); font.bold: true
            color: "#ffffff"; opacity: panelsList.edResetOpen ? 1.0 : 0.55 }
        }
        MouseArea { id: resetBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: {
            panelsList.edCollapsed = false;
            panelsList.edResetOpen = !panelsList.edResetOpen;
            if (panelsList.edResetOpen) { panelsList.edSlotsOpen = false; panelsList.edMoveOpen = false; panelsList.edDebugOpen = false; panelsList.edExpOpen = false; panelsList.edTiltOpen = false; panelsList.edLibraryOpen = false; panelsList.edWrapperOpen = false; panelsList.edTabsOpen = false; panelsList.edLayersOpen = false; }
          }
        }
      }

      // ── Move — sits immediately left of the centered ▲ ──────────
      Rectangle {
        id: moveBtn
        anchors.right: collapseArrow.left
        anchors.rightMargin: vpx(4)
        anchors.verticalCenter: parent.verticalCenter
        height: vpx(16); radius: vpx(3)
        width: moveBtnLbl.implicitWidth + vpx(10)
        color: panelsList.edMoveOpen ? Qt.rgba(1,0.7,0.2,0.30) : (moveBtnMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.07))
        border.width: vpx(1); border.color: panelsList.edMoveOpen ? "#ffaa33" : Qt.rgba(1,1,1,0.22)
        StyledText { id: moveBtnLbl; anchors.centerIn: parent; text: "Move"; font.pixelSize: vpx(9); font.bold: panelsList.edMoveOpen; color: "#ffffff" }
        MouseArea { id: moveBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: {
            panelsList.edCollapsed = false;
            panelsList.edMoveOpen = !panelsList.edMoveOpen;
            if (panelsList.edMoveOpen) panelsList.edSlotsOpen   = false;
            if (panelsList.edMoveOpen) panelsList.edResetOpen   = false;
            if (panelsList.edMoveOpen) panelsList.edLibraryOpen = false;
            if (panelsList.edMoveOpen) panelsList.edExpOpen     = false;
            if (panelsList.edMoveOpen) panelsList.edTiltOpen    = false;
          }
        }
      }

      // Right cluster: view toggles + layout numbers + EDIT + close
      Row {
        anchors { right: parent.right; rightMargin: vpx(8); verticalCenter: parent.verticalCenter }
        spacing: vpx(3)

        Pill { label: "Flat"; on: panelsList.edFlatMode; onToggled: {
          if (!panelsList.edFlatMode) {
            // About to enable flat — snapshot current curved settings
            panelsList._preFlatSelectedX = panelsList.edSelectedX;
            panelsList._preFlatSpacing   = panelsList.edSpacing;
            panelsList._preFlatScaleStep = panelsList.edScaleStep;
            panelsList._preFlatBaseScale = panelsList.edBaseScale;
            panelsList._preFlatValid     = true;
            panelsList.edFlatMode        = true;
          } else {
            // Disabling flat — restore previous curved settings if snapshot exists
            panelsList.edFlatMode = false;
            if (panelsList._preFlatValid) {
              panelsList.edSelectedX  = panelsList._preFlatSelectedX;
              panelsList.edSpacing    = panelsList._preFlatSpacing;
              panelsList.edScaleStep  = panelsList._preFlatScaleStep;
              panelsList.edBaseScale  = panelsList._preFlatBaseScale;
              panelsList._preFlatValid = false;
            }
          }
        }}

        // BG cycle
        Rectangle {
          height: vpx(16); radius: vpx(3)
          width: bgCycleTxt.implicitWidth + vpx(16)
          color: panelsList.edBgMode < 3 ? Qt.rgba(1,1,1,0.14) : Qt.rgba(1,1,1,0.07)
          border.width: vpx(1)
          border.color: panelsList.edBgMode < 3 ? Qt.rgba(1,1,1,0.55) : Qt.rgba(1,1,1,0.18)
          anchors.verticalCenter: parent.verticalCenter
          Row { anchors.centerIn: parent; spacing: vpx(4)
            Rectangle { width: vpx(6); height: vpx(6); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
              color: ["#aaaaaa","#000000","#555555","transparent","#ffffff","#888888"][panelsList.edBgMode]
              border.color: Qt.rgba(1,1,1,0.35); border.width: vpx(1) }
            StyledText { id: bgCycleTxt; font.pixelSize: vpx(9); font.bold: true; color: "#ffffff"
              text: ["Dark BG","Black BG","Semi BG","Clear BG","White BG","Gray BG"][panelsList.edBgMode] }
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: panelsList.edBgMode = (panelsList.edBgMode + 1) % 6 }
        }

        // Text color
        Rectangle {
          height: vpx(16); radius: vpx(3); width: tColTxt.implicitWidth + vpx(16)
          color: Qt.rgba(1,1,1,0.07); border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.22)
          anchors.verticalCenter: parent.verticalCenter
          Row { anchors.centerIn: parent; spacing: vpx(4)
            Rectangle { width: vpx(6); height: vpx(6); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
              color: panelsList.edColorMode === 0 ? "#ffffff" : "#000000"
              border.color: Qt.rgba(1,1,1,0.35); border.width: vpx(1) }
            StyledText { id: tColTxt; font.pixelSize: vpx(9); font.bold: true; color: "#ffffff"
              text: panelsList.edColorMode === 0 ? "White" : "Black" }
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: panelsList.edColorMode = (panelsList.edColorMode + 1) % 2 }
        }

        Rectangle { width: vpx(1); height: vpx(14); color: Qt.rgba(1,1,1,0.14); anchors.verticalCenter: parent.verticalCenter }

        // ── Save button ───────────────────────────────────────────────
        Rectangle {
          height: vpx(16); radius: vpx(3); width: saveCentLbl.implicitWidth + vpx(14)
          anchors.verticalCenter: parent.verticalCenter
          color: saveCentMa.containsMouse ? Qt.rgba(0.15,0.55,0.15,0.65) : Qt.rgba(0.1,0.35,0.1,0.40)
          border.width: vpx(1); border.color: Qt.rgba(0.3,0.8,0.3,0.55)
          StyledText { id: saveCentLbl; anchors.centerIn: parent; text: "💾 Save"; font.pixelSize: vpx(9); font.bold: true; color: "#ffffff" }
          MouseArea { id: saveCentMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: {
              panelsList.edSlotsOpen = !panelsList.edSlotsOpen;
              if (panelsList.edSlotsOpen) panelsList.edMoveOpen = false;
              if (panelsList.edSlotsOpen) panelsList.edTiltOpen = false;
            }
          }
        }

        // DEBUG button
        Rectangle {
          height: vpx(16); radius: vpx(3); width: debugBtnTxt.implicitWidth + vpx(16)
          anchors.verticalCenter: parent.verticalCenter
          color: panelsList.edDebugOpen ? Qt.rgba(0.6,0.3,0.0,0.40) : Qt.rgba(1,1,1,0.07)
          border.width: vpx(1)
          border.color: panelsList.edDebugOpen ? "#ffaa33" : Qt.rgba(1,1,1,0.22)
          Row { anchors.centerIn: parent; spacing: vpx(4)
            StyledText { id: debugBtnTxt; text: "🐛 Debug"; font.pixelSize: vpx(9); font.bold: true
              color: "#ffffff"; opacity: panelsList.edDebugOpen ? 1.0 : 0.55 }
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: {
              panelsList.edCollapsed = false;
              panelsList.edDebugOpen = !panelsList.edDebugOpen;
              if (panelsList.edDebugOpen) { panelsList.edSlotsOpen = false; panelsList.edResetOpen = false; panelsList.edMoveOpen = false; panelsList.edExpOpen = false; panelsList.edTiltOpen = false; panelsList.edLibraryOpen = false; panelsList.edWrapperOpen = false; panelsList.edTabsOpen = false; panelsList.edLayersOpen = false; }
            }
          }
        }

        // EXPERIMENTAL button
        Rectangle {
          height: vpx(16); radius: vpx(3); width: expBtnTxt.implicitWidth + vpx(16)
          anchors.verticalCenter: parent.verticalCenter
          color: panelsList.edExpOpen ? Qt.rgba(0.5,0.1,0.8,0.40) : Qt.rgba(1,1,1,0.07)
          border.width: vpx(1)
          border.color: panelsList.edExpOpen ? "#cc55ff" : Qt.rgba(1,1,1,0.22)
          Row { anchors.centerIn: parent; spacing: vpx(4)
            Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); anchors.verticalCenter: parent.verticalCenter
              color: panelsList.edExpOpen ? "#cc55ff" : Qt.rgba(1,1,1,0.25) }
            StyledText { id: expBtnTxt; text: "⭕ Rotation"; font.pixelSize: vpx(9); font.bold: true
              color: "#ffffff"; opacity: panelsList.edExpOpen ? 1.0 : 0.55 }
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: {
              panelsList.edCollapsed = false;
              panelsList.edExpOpen = !panelsList.edExpOpen;
              if (panelsList.edExpOpen) { panelsList.edSlotsOpen = false; panelsList.edResetOpen = false; panelsList.edMoveOpen = false; panelsList.edDebugOpen = false; panelsList.edTiltOpen = false; panelsList.edLibraryOpen = false; panelsList.edWrapperOpen = false; panelsList.edTabsOpen = false; panelsList.edLayersOpen = false; }
            }
          }
        }

        // WRAPPER button
        Rectangle {
          height: vpx(16); radius: vpx(3); width: wrapBtnTxt.implicitWidth + vpx(16)
          anchors.verticalCenter: parent.verticalCenter
          color: panelsList.edWrapperOpen ? Qt.rgba(0.6,0.35,0.9,0.25) : Qt.rgba(1,1,1,0.07)
          border.width: vpx(1)
          border.color: panelsList.edWrapperOpen ? "#aa66ff" : Qt.rgba(1,1,1,0.22)
          Row { anchors.centerIn: parent; spacing: vpx(4)
            Rectangle { width: vpx(6); height: vpx(6); radius: vpx(1); anchors.verticalCenter: parent.verticalCenter
              color: panelsList.edWrapperOpen ? "#aa66ff" : Qt.rgba(1,1,1,0.25) }
            StyledText { id: wrapBtnTxt; text: "Wrapper"; font.pixelSize: vpx(9); font.bold: true
              color: "#ffffff"; opacity: panelsList.edWrapperOpen ? 1.0 : 0.55 }
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: {
              panelsList.edCollapsed = false;
              panelsList.edWrapperOpen = !panelsList.edWrapperOpen;
              if (panelsList.edWrapperOpen) { panelsList.edSlotsOpen = false; panelsList.edResetOpen = false; panelsList.edMoveOpen = false; panelsList.edDebugOpen = false; panelsList.edExpOpen = false; panelsList.edTiltOpen = false; panelsList.edLibraryOpen = false; panelsList.edLayersOpen = false; panelsList.edTabsOpen = false; }
            }
          }
        }

        Rectangle { width: vpx(1); height: vpx(14); color: Qt.rgba(1,1,1,0.14); anchors.verticalCenter: parent.verticalCenter }

        // ✕ Close
        Rectangle {
          width: vpx(24); height: vpx(16); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
          color: closeMa.containsMouse ? Qt.rgba(0.7,0.0,0.0,0.60) : Qt.rgba(0.45,0.0,0.0,0.35)
          border.width: vpx(1); border.color: Qt.rgba(1,0.30,0.30,0.55)
          StyledText { anchors.centerIn: parent; text: "✕"; font.pixelSize: vpx(11); font.bold: true; color: Qt.rgba(1,0.45,0.45,0.95) }
          MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: panelsList.closeEditor() }
        }
      }
    }

    // ── Slots Sub-Page (slot badges + actions only) ───────────────
    Rectangle {
      id: slotsPage
      visible: panelsList.edSlotsOpen && !panelsList.edMoveOpen
      anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
      color: "transparent"

      Rectangle { anchors.fill: parent; color: Qt.rgba(0.02, 0.02, 0.05, 0.60); radius: vpx(2) }

      // Hidden TextEdit for clipboard copy
      TextEdit {
        id: clipboardHelper; visible: false; width: 0; height: 0
        function copyText(txt) { text = txt; selectAll(); copy(); text = ""; }
      }

      // ── Load status toast — centered, never shifts buttons ────────
      Rectangle {
        visible: slotToastText.msg !== ""
        anchors.centerIn: parent
        width: slotToastText.implicitWidth + vpx(16); height: vpx(20); radius: vpx(4)
        color: slotToastText.msg.indexOf("failed") >= 0 ? Qt.rgba(0.55,0.05,0.05,0.92) : Qt.rgba(0.05,0.40,0.05,0.92)
        border.width: vpx(1)
        border.color: slotToastText.msg.indexOf("failed") >= 0 ? "#ff6666" : "#44cc44"
        z: 10
        StyledText {
          id: slotToastText
          property string msg: ""
          anchors.centerIn: parent
          text: msg
          font.pixelSize: vpx(9); font.bold: true; color: "#ffffff"
        }
        Timer { id: slotToastTimer; interval: 1800; onTriggered: slotToastText.msg = "" }
      }

      Column {
        anchors { top: parent.top; topMargin: vpx(4); left: parent.left; leftMargin: vpx(10); right: parent.right; rightMargin: vpx(10) }
        spacing: vpx(4)

        // ── Slots header: slot label + action buttons right ──────────
        Item {
          id: slotsHeaderRow
          width: parent.width
          height: vpx(16)

          // Left: "Slots" label + active slot info
          Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: vpx(6)
            StyledText {
              text: "Slots"
              font.pixelSize: vpx(8); font.bold: true; color: "#44cc66"
              anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
              visible: panelsList.edActiveSlot >= 1
              text: "· Active: Slot " + panelsList.edActiveSlot
              font.pixelSize: vpx(8); font.bold: true; color: safeAccent
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          // Right: Y-cycles checkboxes + action buttons (load, save, delete, new, export, import)
          Row {
            id: actionsRow
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: vpx(3)
            property int sel: panelsList.edActiveSlot
            property bool hasSel: sel >= 1 && sel < panelsList.edSavedSlots.length
            property var selData: hasSel ? (panelsList.edSavedSlots[sel] || { name: "", data: "", layoutName: "" }) : { name: "", data: "", layoutName: "" }
            property bool selFilled: hasSel && selData.data !== ""

            // Y cycles label
            StyledText { text: "Y cycles:"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.55); anchors.verticalCenter: parent.verticalCenter }
            // Built-in checkbox
            Row { spacing: vpx(4); anchors.verticalCenter: parent.verticalCenter
              Rectangle {
                width: vpx(14); height: vpx(14); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
                color: panelsList.cycleBuiltIn ? Qt.rgba(0.15,0.65,0.15,0.70) : Qt.rgba(1,1,1,0.07)
                border.width: vpx(1); border.color: panelsList.cycleBuiltIn ? "#55ee55" : Qt.rgba(1,1,1,0.30)
                StyledText { anchors.centerIn: parent; text: panelsList.cycleBuiltIn ? "✓" : ""; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { if (panelsList.cycleBuiltIn && !panelsList.cycleCustom && !panelsList.cycleSlots) return; panelsList.cycleBuiltIn = !panelsList.cycleBuiltIn; api.memory.set(pageKey + "cycleBuiltIn", String(panelsList.cycleBuiltIn)); }
                }
              }
              StyledText { text: "Templates"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.65); anchors.verticalCenter: parent.verticalCenter }
            }
            // Slots checkbox
            Row { spacing: vpx(4); anchors.verticalCenter: parent.verticalCenter
              Rectangle {
                width: vpx(14); height: vpx(14); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
                color: panelsList.cycleSlots ? Qt.rgba(0.25,0.45,0.80,0.70) : Qt.rgba(1,1,1,0.07)
                border.width: vpx(1); border.color: panelsList.cycleSlots ? "#6699ff" : Qt.rgba(1,1,1,0.30)
                StyledText { anchors.centerIn: parent; text: panelsList.cycleSlots ? "✓" : ""; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { if (panelsList.cycleSlots && !panelsList.cycleBuiltIn && !panelsList.cycleCustom) return; panelsList.cycleSlots = !panelsList.cycleSlots; api.memory.set(pageKey + "cycleSlots", String(panelsList.cycleSlots)); }
                }
              }
              StyledText { text: "Slots"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.65); anchors.verticalCenter: parent.verticalCenter }
            }
            // Custom checkbox
            Row { spacing: vpx(4); anchors.verticalCenter: parent.verticalCenter
              Rectangle {
                width: vpx(14); height: vpx(14); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
                color: panelsList.cycleCustom ? Qt.rgba(0.65,0.35,0.15,0.70) : Qt.rgba(1,1,1,0.07)
                border.width: vpx(1); border.color: panelsList.cycleCustom ? "#ee9933" : Qt.rgba(1,1,1,0.30)
                StyledText { anchors.centerIn: parent; text: panelsList.cycleCustom ? "✓" : ""; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { if (panelsList.cycleCustom && !panelsList.cycleBuiltIn && !panelsList.cycleSlots) return; panelsList.cycleCustom = !panelsList.cycleCustom; api.memory.set(pageKey + "cycleCustom", String(panelsList.cycleCustom)); }
                }
              }
              StyledText { text: "Custom"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.65); anchors.verticalCenter: parent.verticalCenter }
            }
            // Divider between checkboxes and buttons
            Rectangle { width: vpx(1); height: vpx(12); color: Qt.rgba(1,1,1,0.18); anchors.verticalCenter: parent.verticalCenter }

            // LOAD
            Rectangle {
              id: actLoadBtn
              width: vpx(60); height: vpx(16); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
              opacity: actionsRow.selFilled ? 1.0 : 0.25
              property bool loaded: false
              color: loaded ? Qt.rgba(0.10,0.55,0.10,0.80)
                   : actLoadMa.containsMouse && actionsRow.selFilled ? Qt.rgba(0.20,0.55,0.10,0.70)
                   : Qt.rgba(0.10,0.30,0.05,0.45)
              border.width: vpx(1); border.color: loaded ? "#44cc44" : "#88cc33"
              StyledText { anchors.centerIn: parent
                text: actLoadBtn.loaded ? "✓ Done" : "Load Slot"
                font.pixelSize: vpx(8); font.bold: true; color: actLoadBtn.loaded ? "#aaffaa" : "#cceeaa" }
              Timer { id: actLoadFlash; interval: 1200; onTriggered: actLoadBtn.loaded = false }
              MouseArea { id: actLoadMa; anchors.fill: parent; hoverEnabled: true
                cursorShape: actionsRow.selFilled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                  if (!actionsRow.selFilled) return;
                  panelsList.edLoadSlot(actionsRow.sel);
                  actLoadBtn.loaded = true;
                  actLoadFlash.restart();
                }
              }
            }

            // SAVE
            Rectangle {
              id: actSaveBtn
              width: vpx(60); height: vpx(16); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
              property bool saved: false
              color: saved ? Qt.rgba(0.10,0.65,0.10,0.80)
                   : actSaveMa.containsMouse ? Qt.rgba(0.15,0.55,0.15,0.70)
                   : Qt.rgba(0.05,0.30,0.05,0.45)
              border.width: vpx(1); border.color: saved ? "#88ff88" : "#44cc44"
              StyledText { anchors.centerIn: parent
                text: actSaveBtn.saved ? "✓ Saved" : "💾 Save"
                font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
              Timer { id: actSaveFlash; interval: 1200; onTriggered: actSaveBtn.saved = false }
              MouseArea { id: actSaveMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var idx = actionsRow.sel >= 1 ? actionsRow.sel : 1;
                  panelsList.edSaveSlot(idx, "");
                  panelsList.edLoadSlots();
                  actSaveBtn.saved = true;
                  actSaveFlash.restart();
                }
              }
            }

            // DELETE
            Rectangle {
              width: vpx(40); height: vpx(16); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
              opacity: actionsRow.selFilled ? 1.0 : 0.25
              color: actDelMa.containsMouse && actionsRow.selFilled ? Qt.rgba(0.8,0.1,0.1,0.80) : Qt.rgba(0.45,0.05,0.05,0.55)
              border.width: vpx(1); border.color: "#ff4444"
              StyledText { anchors.centerIn: parent; text: "Delete"; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
              MouseArea { id: actDelMa; anchors.fill: parent; hoverEnabled: true
                cursorShape: actionsRow.selFilled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: { if (actionsRow.selFilled) panelsList.edDeleteSlot(actionsRow.sel); }
              }
            }

            // NEW
            Rectangle { width: vpx(1); height: vpx(14); color: Qt.rgba(1,1,1,0.18); anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
              width: vpx(28); height: vpx(16); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
              color: actNewMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.30)
              StyledText { anchors.centerIn: parent; text: "+ New"; font.pixelSize: vpx(8); color: "#ffffff" }
              MouseArea { id: actNewMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var arr = panelsList.edSavedSlots.slice();
                  arr.push({ name: "Preset " + arr.length, data: "", layoutName: "" });
                  panelsList.edSavedSlots = arr;
                }
              }
            }

            // Divider
            Rectangle { width: vpx(1); height: vpx(14); color: Qt.rgba(1,1,1,0.18); anchors.verticalCenter: parent.verticalCenter }

            // EXPORT slot
            Rectangle {
              id: slotExportBtn
              height: vpx(16); radius: vpx(2); width: vpx(46)
              opacity: actionsRow.selFilled ? 1.0 : 0.25
              property bool exported: false
              color: exported ? Qt.rgba(0.10,0.55,0.10,0.80)
                   : slotExportMa.containsMouse && actionsRow.selFilled ? Qt.rgba(0.10,0.35,0.65,0.80)
                   : Qt.rgba(0.05,0.20,0.45,0.50)
              border.width: vpx(1); border.color: exported ? "#44cc44" : "#4477cc"
              anchors.verticalCenter: parent.verticalCenter
              StyledText { anchors.centerIn: parent
                text: slotExportBtn.exported ? "✓ Copied" : "⬆ Export"
                font.pixelSize: vpx(8); font.bold: true; color: slotExportBtn.exported ? "#aaffaa" : "#aaccff" }
              Timer { id: slotExportFlash; interval: 1500; onTriggered: slotExportBtn.exported = false }
              MouseArea { id: slotExportMa; anchors.fill: parent; hoverEnabled: true
                cursorShape: actionsRow.selFilled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                  if (!actionsRow.selFilled) return;
                  clipboardHelper.copyText(actionsRow.selData.data);
                  slotExportBtn.exported = true;
                  slotExportFlash.restart();
                }
              }
            }

            // Divider
            Rectangle { width: vpx(1); height: vpx(14); color: Qt.rgba(1,1,1,0.18); anchors.verticalCenter: parent.verticalCenter }

            // IMPORT
            Rectangle {
              height: vpx(16); radius: vpx(2); width: vpx(52)
              color: importMa.containsMouse ? Qt.rgba(0.10,0.35,0.65,0.70) : Qt.rgba(0.05,0.20,0.45,0.50)
              border.width: vpx(1); border.color: "#4477cc"
              anchors.verticalCenter: parent.verticalCenter
              StyledText { anchors.centerIn: parent; text: "⬇ Import"; font.pixelSize: vpx(8); font.bold: true; color: "#aaccff" }
              MouseArea { id: importMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  panelsList.importOpen = !panelsList.importOpen;
                  if (panelsList.importOpen) Qt.callLater(function() { importInput.forceActiveFocus(); });
                }
              }
            }
          }
        } // end slotsHeaderRow

        // ── Import paste (conditional) ────────────────────────────
        Row {
          visible: panelsList.importOpen
          spacing: vpx(6)
          StyledText { text: "Paste JSON:"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.55); anchors.verticalCenter: parent.verticalCenter }
          Rectangle {
            width: vpx(300); height: vpx(20); radius: vpx(2)
            color: Qt.rgba(0,0,0,0.50); border.width: vpx(1); border.color: "#4477cc"
            TextInput {
              id: importInput
              anchors { fill: parent; leftMargin: vpx(4); rightMargin: vpx(4) }
              verticalAlignment: TextInput.AlignVCenter
              font.pixelSize: vpx(8); color: "#ffffff"
              selectByMouse: true; clip: true
              Keys.onPressed: {
                if ((event.key === Qt.Key_V) && (event.modifiers & Qt.ControlModifier)) {
                  importInput.paste();
                  event.accepted = true;
                }
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: { importInput.forceActiveFocus(); importInput.selectAll(); }
              }
            }
          }
          Rectangle {
            height: vpx(20); radius: vpx(2); width: vpx(46)
            color: applyImportMa.containsMouse ? Qt.rgba(0.15,0.65,0.15,0.80) : Qt.rgba(0.05,0.35,0.05,0.55)
            border.width: vpx(1); border.color: "#44cc44"
            StyledText { anchors.centerIn: parent; text: "Apply"; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
            MouseArea { id: applyImportMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: {
                var txt = importInput.text.trim();
                if (txt === "") return;
                try {
                  var parsed = JSON.parse(txt);
                  var name = parsed.n || ("Import " + (panelsList.customLayouts.length + 1));
                  panelsList.saveCustomLayout(name, JSON.stringify(parsed));
                  importInput.text = "";
                  panelsList.importOpen = false;
                } catch(e) { importInput.text = "Invalid JSON!"; }
              }
            }
          }
        }

        // ── Row 2: Slot badges ────────────────────────────────────
        Row {
          id: slotBadgesRow
          spacing: vpx(6)

          // ── Slot badges ───────────────────────────────────────────
          Repeater {
            model: Math.max(0, panelsList.edSavedSlots.length - 1)
            delegate: Rectangle {
              id: slotRect
              property int  slotIndex: index + 1
              property var  slotData: {
                var _rev = panelsList.edSlotRevision;
                return panelsList.edSavedSlots[slotIndex] || { name: "", data: "", layoutName: "" };
              }
              property bool filled:     slotData.data !== ""
              property bool isActive:   panelsList.edActiveSlot === slotIndex
              property bool isRenaming: false
              // For empty slots, show the currently selected layout in the editor header
              property int  activeLayoutNum: panelsList.edPreviewLayout >= 1 ? panelsList.edPreviewLayout
                : parseInt(api.memory.get(pageKey + "gameLayout") || "1")
              property string currentLayoutName: activeLayoutNum === 1 ? "Default"
                : activeLayoutNum === 2 ? "Media Strip"
                : activeLayoutNum === 3 ? "Card Stack"
                : activeLayoutNum === 4 ? "Flat Center"
                : activeLayoutNum === 5 ? "Big Box"
                : activeLayoutNum === 6 ? "Uniflow"
                : activeLayoutNum === 7 ? "Carousel"
                : activeLayoutNum === 8 ? "RTL Default"
                : "Layout " + activeLayoutNum

              function commitRename() {
                var newName = renameInput.text.trim();
                if (newName === "") newName = "Preset " + slotIndex;
                api.memory.set(pageKey + "uniSlotName_" + slotIndex, newName);
                panelsList.edLoadSlots();
                isRenaming = false;
              }

              // Width fits content exactly — number badge + name + optional buttons + padding
              width: slotInnerRow.implicitWidth + vpx(8)
              height: vpx(20); radius: vpx(3)
              color: isRenaming ? Qt.rgba(0.10,0.10,0.30,0.60)
                   : isActive   ? Qt.rgba(0.15,0.65,0.15,0.15)
                   : filled     ? Qt.rgba(1,1,1,0.07)
                   :              Qt.rgba(1,1,1,0.03)
              border.width: vpx(1)
              border.color: isRenaming ? "#aaaaff"
                          : isActive   ? "#55ee55"
                          : filled     ? Qt.rgba(1,1,1,0.22)
                          :              Qt.rgba(1,1,1,0.10)

              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                enabled: !isRenaming
                onClicked: {
                  console.log("SLOT CLICK: slotIndex="+slotIndex+" edActiveSlot="+panelsList.edActiveSlot+" edSlotIsLoaded="+panelsList.edSlotIsLoaded+" layoutMode="+panelsList.layoutMode+" useEdPath="+panelsList.useEdPath);
                  panelsList.edActiveSlot = (panelsList.edActiveSlot === slotIndex ? -1 : slotIndex);
                  console.log("SLOT AFTER: edActiveSlot="+panelsList.edActiveSlot+" edSlotIsLoaded="+panelsList.edSlotIsLoaded+" useEdPath="+panelsList.useEdPath+" layoutMode="+panelsList.layoutMode);
                }
                onDoubleClicked: {
                  panelsList.edActiveSlot = slotIndex;
                  var currentName = slotData.name || slotData.layoutName || ("Preset " + slotIndex);
                  renameInput.text = currentName;
                  isRenaming = true;
                  renameInput.selectAll();
                  renameInput.forceActiveFocus();
                }
              }

              Row {
                id: slotInnerRow
                anchors { left: parent.left; leftMargin: vpx(4); right: parent.right; rightMargin: vpx(4); verticalCenter: parent.verticalCenter }
                spacing: vpx(3)

                // Number badge
                Rectangle {
                  width: vpx(16); height: vpx(16); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                  color: isRenaming ? Qt.rgba(0.40,0.40,0.90,0.70) : (isActive ? Qt.rgba(0.15,0.65,0.15,0.70) : Qt.rgba(1,1,1,0.15))
                  border.width: vpx(1); border.color: isRenaming ? "#aaaaff" : (isActive ? "#55ee55" : Qt.rgba(1,1,1,0.35))
                  StyledText { anchors.centerIn: parent; text: slotIndex; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
                }

                // Name label (normal view) — no fixed width, elide at 120px max
                StyledText {
                  visible: !isRenaming
                  anchors.verticalCenter: parent.verticalCenter
                  maximumLineCount: 1; elide: Text.ElideRight
                  width: Math.min(implicitWidth, vpx(120))
                  text: {
                    if (!filled) return "—";
                    if (slotData.name) return slotData.name;
                    if (slotData.layoutName) return slotData.layoutName;
                    return "Preset " + slotIndex;
                  }
                  font.pixelSize: vpx(9); font.bold: filled
                  color: filled ? "#ffffff" : Qt.rgba(1,1,1,0.25)
                }

                // Rename input + ✓ (shown while renaming)
                Row {
                  visible: isRenaming
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: vpx(3)
                  width: vpx(64)
                  Rectangle {
                    width: parent.width - vpx(21); height: vpx(16); radius: vpx(2)
                    color: Qt.rgba(0,0,0,0.40); border.width: vpx(1); border.color: "#aaaaff"
                    TextInput {
                      id: renameInput
                      anchors { fill: parent; leftMargin: vpx(3); rightMargin: vpx(3) }
                      verticalAlignment: TextInput.AlignVCenter
                      font.pixelSize: vpx(8); font.bold: true; color: "#ffffff"
                      selectByMouse: true; maximumLength: 32; clip: true
                      Keys.onReturnPressed: slotRect.commitRename()
                      Keys.onEnterPressed:  slotRect.commitRename()
                      Keys.onEscapePressed: { isRenaming = false; }
                    }
                  }
                  Rectangle {
                    width: vpx(18); height: vpx(16); radius: vpx(2)
                    color: confirmMa.containsMouse ? Qt.rgba(0.15,0.70,0.15,0.90) : Qt.rgba(0.05,0.45,0.05,0.70)
                    border.width: vpx(1); border.color: "#44dd44"
                    StyledText { anchors.centerIn: parent; text: "✓"; font.pixelSize: vpx(9); font.bold: true; color: "#ffffff" }
                    MouseArea { id: confirmMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                      onClicked: slotRect.commitRename()
                    }
                  }
                }

                // ✎ Rename button
                Rectangle {
                  width: vpx(14); height: vpx(14); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
                  visible: filled && !isRenaming
                  color: renameBtnMa.containsMouse ? Qt.rgba(0.30,0.30,0.80,0.80) : Qt.rgba(1,1,1,0.10)
                  border.width: vpx(1); border.color: renameBtnMa.containsMouse ? "#aaaaff" : Qt.rgba(1,1,1,0.25)
                  StyledText { anchors.centerIn: parent; text: "✎"; font.pixelSize: vpx(8); color: "#ccccff" }
                  MouseArea { id: renameBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      panelsList.edActiveSlot = slotIndex;
                      var nm = slotData.name || slotData.layoutName || ("Preset " + slotIndex);
                      renameInput.text = nm;
                      isRenaming = true;
                      renameInput.selectAll();
                      renameInput.forceActiveFocus();
                    }
                  }
                }

                // ℹ Layout info button
                Rectangle {
                  width: vpx(14); height: vpx(14); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
                  visible: filled && !isRenaming
                  color: infoBtnMa.containsMouse ? Qt.rgba(0.10,0.45,0.80,0.80) : Qt.rgba(1,1,1,0.10)
                  border.width: vpx(1); border.color: infoBtnMa.containsMouse ? "#55aaff" : Qt.rgba(1,1,1,0.25)
                  StyledText { anchors.centerIn: parent; text: "i"; font.pixelSize: vpx(8); font.bold: true; color: "#88ccff" }
                  MouseArea { id: infoBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      panelsList.edActiveSlot = slotIndex;
                      panelsList.edLayoutInfoOpen = !panelsList.edLayoutInfoOpen;
                    }
                  }
                }

                // ▲ Move up
                Rectangle {
                  width: vpx(11); height: vpx(14); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
                  visible: filled && !isRenaming && slotIndex > 1
                  color: moveUpMa.containsMouse ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.07)
                  border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.22)
                  StyledText { anchors.centerIn: parent; text: "▲"; font.pixelSize: vpx(6); color: "#cccccc" }
                  MouseArea { id: moveUpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: panelsList.edSwapSlots(slotIndex, slotIndex - 1)
                  }
                }

                // ▼ Move down
                Rectangle {
                  width: vpx(11); height: vpx(14); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
                  visible: filled && !isRenaming && slotIndex < panelsList.edSavedSlots.length - 1
                  color: moveDnMa.containsMouse ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.07)
                  border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.22)
                  StyledText { anchors.centerIn: parent; text: "▼"; font.pixelSize: vpx(6); color: "#cccccc" }
                  MouseArea { id: moveDnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: panelsList.edSwapSlots(slotIndex, slotIndex + 1)
                  }
                }
              }
            }
          }
        } // end slotBadgesRow

      } // end Column (slotsPage)
    } // end slotsPage

    // ── Layers Sub-Page ──────────────────────────────
    Rectangle {
      id: layersPage
      visible: panelsList.edLayersOpen
      anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
      color: "transparent"
      Rectangle { anchors.fill: parent; color: Qt.rgba(0.02, 0.02, 0.05, 0.85); radius: vpx(2) }

      Row {
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: vpx(12) }
        spacing: vpx(20)

        // Stage checkbox
        Row { spacing: vpx(8)
          Rectangle {
            width: vpx(14); height: vpx(14); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
            color: panelsList.stageEnabled ? Qt.rgba(1,0.55,0.0,0.40) : Qt.rgba(1,1,1,0.07)
            border.width: vpx(1); border.color: panelsList.stageEnabled ? "#ff8822" : Qt.rgba(1,1,1,0.30)
            StyledText { anchors.centerIn: parent; text: panelsList.stageEnabled ? "✓" : ""; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                panelsList.stageEnabled = !panelsList.stageEnabled;
                api.memory.set("stageEnabled", String(panelsList.stageEnabled));
                var r = panelsList.parent; while (r && r.parent) r = r.parent;
                if (typeof r.stageEnabled !== "undefined") r.stageEnabled = panelsList.stageEnabled;
              }
            }
          }
          StyledText {
            text: "Stage"; font.pixelSize: vpx(9); anchors.verticalCenter: parent.verticalCenter
            color: panelsList.stageEnabled ? "#ff8822" : Qt.rgba(1,1,1,0.35)
          }
        }

        // Canopies checkbox
        Row { spacing: vpx(8)
          Rectangle {
            width: vpx(14); height: vpx(14); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
            color: panelsList.canopyEnabled ? Qt.rgba(0.15,0.65,0.50,0.50) : Qt.rgba(1,1,1,0.07)
            border.width: vpx(1); border.color: panelsList.canopyEnabled ? "#33ddaa" : Qt.rgba(1,1,1,0.30)
            StyledText { anchors.centerIn: parent; text: panelsList.canopyEnabled ? "✓" : ""; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                panelsList.canopyEnabled = !panelsList.canopyEnabled;
                api.memory.set("canopyEnabled", String(panelsList.canopyEnabled));
                var r = panelsList.parent; while (r && r.parent) r = r.parent;
                if (typeof r.canopyEnabled !== "undefined") r.canopyEnabled = panelsList.canopyEnabled;
              }
            }
          }
          StyledText {
            text: "Canopies"; font.pixelSize: vpx(9); anchors.verticalCenter: parent.verticalCenter
            color: panelsList.canopyEnabled ? "#33ddaa" : Qt.rgba(1,1,1,0.35)
          }
        }
      }
    } // end layersPage


    // ── Templates Sub-Page ────────────────────────────────────────
    Rectangle {
      id: templatesPage
      visible: panelsList.edTemplatesOpen
      anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
      color: "transparent"
      Rectangle { anchors.fill: parent; color: Qt.rgba(0.02, 0.03, 0.08, 0.65); radius: vpx(2) }

      Column {
        anchors { top: parent.top; topMargin: vpx(6); left: parent.left; leftMargin: vpx(10); right: parent.right; rightMargin: vpx(10) }
        spacing: vpx(6)

        // ── Header row: title | Selected layout name + info button + Load ─
        Item {
          width: parent.width; height: vpx(20)
          Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: vpx(6)
            StyledText {
              text: "Layout Templates"
              font.pixelSize: vpx(8); font.bold: true; color: "#55bbff"
              anchors.verticalCenter: parent.verticalCenter
            }
          }
          // Right: selected layout name + info button + Load Template button
          Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: vpx(6)
            StyledText { text: "Selected:"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.45); anchors.verticalCenter: parent.verticalCenter }
            StyledText {
              text: panelsList.edPreviewLayout === 0 ? "Editor"
                  : panelsList.edPreviewLayout === 1 ? "Default"
                  : panelsList.edPreviewLayout === 2 ? "Media Strip"
                  : panelsList.edPreviewLayout === 3 ? "Card Stack"
                  : panelsList.edPreviewLayout === 4 ? "Flat Center"
                  : panelsList.edPreviewLayout === 5 ? "Big Box"
                  : panelsList.edPreviewLayout === 6 ? "Uniflow"
                  : panelsList.edPreviewLayout === 7 ? "Carousel"
                  : panelsList.edPreviewLayout === 8 ? "RTL Default"
                  : panelsList.edTemplateStaged ? "—" : "None"
              font.pixelSize: vpx(9); font.bold: true
              color: panelsList.edTemplateStaged ? safeAccent : Qt.rgba(1,1,1,0.35)
              anchors.verticalCenter: parent.verticalCenter
            }
            // ℹ Info button
            Rectangle {
              width: vpx(16); height: vpx(16); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
              color: tmplInfoBtnMa.containsMouse ? Qt.rgba(0.10,0.45,0.80,0.80) : Qt.rgba(1,1,1,0.10)
              border.width: vpx(1); border.color: tmplInfoBtnMa.containsMouse ? "#55aaff" : Qt.rgba(1,1,1,0.25)
              StyledText { anchors.centerIn: parent; text: "i"; font.pixelSize: vpx(8); font.bold: true; color: "#88ccff" }
              MouseArea { id: tmplInfoBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: panelsList.edTemplateInfoOpen = !panelsList.edTemplateInfoOpen
              }
            }
            // Load Template button
            Rectangle {
              id: loadTemplateBtn
              height: vpx(18); radius: vpx(3); width: loadTemplateLbl.implicitWidth + vpx(14)
              anchors.verticalCenter: parent.verticalCenter
              opacity: panelsList.edTemplateStaged ? 1.0 : 0.35
              property bool justLoaded: false
              color: justLoaded ? Qt.rgba(0.10,0.65,0.10,0.80)
                   : loadTemplateMa.containsMouse && panelsList.edTemplateStaged ? Qt.rgba(0.15,0.55,0.15,0.80)
                   : Qt.rgba(0.05,0.30,0.05,0.50)
              border.width: vpx(1); border.color: justLoaded ? "#88ff88" : "#44cc44"
              StyledText { id: loadTemplateLbl; anchors.centerIn: parent
                text: loadTemplateBtn.justLoaded ? "✓ Loaded" : "⬇ Load Template"
                font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
              Timer { id: loadTemplateFlash; interval: 1200; onTriggered: loadTemplateBtn.justLoaded = false }
              MouseArea {
                id: loadTemplateMa; anchors.fill: parent; hoverEnabled: true
                cursorShape: panelsList.edTemplateStaged ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                  if (!panelsList.edTemplateStaged) return;
                  var lm = panelsList.edPreviewLayout;
                  // Suppress all onEd*Changed side-effects while resetting.
                  panelsList._seedingEditor = true;
                  // Apply the template — resets selectedX, flatMode, scaleStep etc. to canonical defaults.
                  panelsList.layoutMode = lm;
                  panelsList.applyLayoutMode();
                  // Now fully re-seed ALL ed* from the freshly applied live props —
                  // exactly as openEditor() does. This clears every stale value
                  // (edBaseScaleLeft/Right, edArcStepLeft/Right, edSpacingLeft/Right, etc.)
                  // so the editor reflects the template, not the previous session's state.
                  panelsList.edSelectedX    = panelsList.selectedX;
                  panelsList.edSpacing      = panelsList.spacingOverride >= 0 ? panelsList.spacingOverride : panelsList.autoSpacing;
                  panelsList.edScaleStep    = panelsList.scaleStep;
                  panelsList.edFlatMode     = panelsList.flatMode;
                  panelsList.edYDrop        = panelsList.yDropPerSlot;
                  panelsList.edSelectedY    = 0;
                  panelsList.edViewOffsetY  = 0;
                  if (lm === 6 || lm === 7) {
                    panelsList.edCenterScale = panelsList.uniBaseScale;
                    panelsList.edBaseScale   = panelsList.uniBaseScale;
                  } else {
                    panelsList.edCenterScale = 1.0;
                    panelsList.edBaseScale   = 1.0;
                  }
                  panelsList.edCenterZ        = panelsList.edCustomDefaultZ;
                  panelsList.edSideZ          = 20;
                  panelsList.edCenterOffsetX  = 0;  panelsList.edCenterOffsetY  = 0;
                  panelsList.edLeftCorrectX   = 0;  panelsList.edRightCorrectX  = 0;
                  panelsList.edLeftCorrectY   = 0;  panelsList.edRightCorrectY  = 0;
                  panelsList.edAsymArc        = false;
                  panelsList.edArcStepLeft    = panelsList.edScaleStep;
                  panelsList.edArcStepRight   = panelsList.edScaleStep;
                  panelsList.edAsymScale      = false;
                  panelsList.edBaseScaleLeft  = panelsList.edBaseScale;
                  panelsList.edBaseScaleRight = panelsList.edBaseScale;
                  panelsList.edAsymSpacing    = false;
                  panelsList.edSpacingLeft    = panelsList.edSpacing;
                  panelsList.edSpacingRight   = panelsList.edSpacing;
                  panelsList.edAsymYDrop      = false;
                  panelsList.edYDropLeft      = 0;  panelsList.edYDropRight     = 0;
                  panelsList.edArcCurve       = 0.0;
                  panelsList.edAsymYCurve     = false;
                  panelsList.edYCurveLeft     = 0.0; panelsList.edYCurveRight   = 0.0;
                  panelsList.edAsymYStartEnd  = false;
                  panelsList.edLeftYStart     = 0;  panelsList.edLeftYMid       = 0;  panelsList.edLeftYEnd  = 0;
                  panelsList.edRightYStart    = 0;  panelsList.edRightYMid      = 0;  panelsList.edRightYEnd = 0;
                  panelsList.edArcFlip        = false;
                  panelsList.edCenterRotation = 0;  panelsList.edRotationBias   = 0;
                  panelsList.edAsymRotation   = false;
                  panelsList.edLeftRotStart   = 0;  panelsList.edLeftRotEnd     = 0;
                  panelsList.edRightRotStart  = 0;  panelsList.edRightRotEnd    = 0;
                  panelsList.edTiltCenter     = 0;  panelsList.edTiltNear       = 0;  panelsList.edTiltFar   = 0;
                  panelsList.edAsymTilt       = false;
                  panelsList.edTiltLeftNear   = 0;  panelsList.edTiltLeftFar    = 0;
                  panelsList.edTiltRightNear  = 0;  panelsList.edTiltRightFar   = 0;
                  panelsList.edActiveSlot     = -1;
                  panelsList.edSlotIsLoaded   = false;
                  panelsList.edCustomIsLoaded = false;
                  panelsList.edPreviewLayout  = lm;
                  panelsList._seedingEditor   = false;
                  panelsList.edSyncLiveProps();
                  panelsList.edTemplateStaged = false;
                  loadTemplateBtn.justLoaded  = true;
                  loadTemplateFlash.restart();
                }
              }
            }
          }
        }

        // ── Template buttons (wrapping Flow) ───────────────────────
        Flow {
          width: parent.width; spacing: vpx(4)
          Repeater {
            model: [
              { idx: 1, name: "Default"    },
              { idx: 2, name: "Media Strip"},
              { idx: 3, name: "Card Stack" },
              { idx: 4, name: "Flat Center"},
              { idx: 5, name: "Big Box"    },
              { idx: 6, name: "Uniflow"    },
              { idx: 7, name: "Carousel"   },
              { idx: 8, name: "RTL Default"}
            ]
            delegate: Rectangle {
              property int  internalIdx: modelData.idx
              property bool selected: panelsList.edPreviewLayout === internalIdx
              height: vpx(20); radius: vpx(3)
              width: tmplBtnInner.implicitWidth + vpx(12)
              color: selected ? Qt.rgba(0.10, 0.55, 0.12, 0.80) : (tmplMa.containsMouse ? Qt.rgba(1,1,1,0.14) : Qt.rgba(1,1,1,0.07))
              border.color: selected ? "#55ee55" : Qt.rgba(1,1,1,0.22); border.width: vpx(1)
              Row {
                id: tmplBtnInner
                anchors.centerIn: parent; spacing: vpx(5)
                Rectangle {
                  width: vpx(14); height: vpx(14); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
                  color: selected ? Qt.rgba(0.10,0.70,0.10,0.80) : Qt.rgba(1,1,1,0.15)
                  border.width: vpx(1); border.color: selected ? "#66ff66" : Qt.rgba(1,1,1,0.35)
                  StyledText { anchors.centerIn: parent; text: internalIdx; font.pixelSize: vpx(7); font.bold: true; color: "#ffffff" }
                }
                StyledText {
                  text: modelData.name; anchors.verticalCenter: parent.verticalCenter
                  font.pixelSize: vpx(8); font.bold: selected; color: selected ? "#ccffcc" : "#cccccc"
                }
              }
              MouseArea { id: tmplMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { panelsList.edPreviewLayout = internalIdx; panelsList.edTemplateStaged = true; }
              }
            }
          }
        }
      }
    } // end templatesPage

    // ── Customs Sub-Page ──────────────────────────────────────────
    Rectangle {
      id: customsPage
      visible: panelsList.edCustomsOpen
      anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
      color: "transparent"
      Rectangle { anchors.fill: parent; color: Qt.rgba(0.04, 0.03, 0.02, 0.65); radius: vpx(2) }

      Column {
        anchors { top: parent.top; topMargin: vpx(6); left: parent.left; leftMargin: vpx(10); right: parent.right; rightMargin: vpx(10) }
        spacing: vpx(4)

        // ── Custom header: Custom N  Name  |  buttons right ──────
        Item {
          id: customHeaderRow
          visible: panelsList.customLayouts.length > 0
          width: parent.width
          height: vpx(16)

          // Left: [Custom checkbox]  Custom N  Name
          Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: vpx(5)

            StyledText {
              text: {
                var idx = panelsList.edActiveCustom;
                if (idx >= 0 && idx < panelsList.customLayouts.length) {
                  var nm = panelsList.customLayouts[idx] ? panelsList.customLayouts[idx].name : "";
                  return "Custom " + (idx + 1) + "  " + (nm || ("Custom " + (idx + 1)));
                }
                return "Custom:";
              }
              font.pixelSize: vpx(9); font.bold: true; color: safeAccent
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          // Right: Load · Export · Save · Del — act on edActiveCustom
          Row {
            id: customActionsRow
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: vpx(3)
            property int sel: panelsList.edActiveCustom
            property bool hasSel: sel >= 0 && sel < panelsList.customLayouts.length
            property var selData: hasSel ? (panelsList.customLayouts[sel] || { name: "", data: "" }) : { name: "", data: "" }
            property bool selFilled: hasSel && selData.data !== ""

            // LOAD
            Rectangle {
              id: loadCustomBtn
              width: vpx(76); height: vpx(16); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
              opacity: customActionsRow.selFilled ? 1.0 : 0.25
              property bool loaded: false
              color: loaded ? Qt.rgba(0.10,0.55,0.10,0.80)
                   : loadCustomMa.containsMouse && customActionsRow.selFilled ? Qt.rgba(0.30,0.55,0.10,0.70)
                   : Qt.rgba(0.15,0.30,0.05,0.45)
              border.width: vpx(1); border.color: loaded ? "#44cc44" : "#88cc33"
              StyledText { anchors.centerIn: parent
                text: loadCustomBtn.loaded ? "✓ Done" : "Load Custom"
                font.pixelSize: vpx(8); font.bold: true; color: loadCustomBtn.loaded ? "#aaffaa" : "#cceeaa" }
              Timer { id: loadCustomFlash; interval: 1200; onTriggered: loadCustomBtn.loaded = false }
              MouseArea { id: loadCustomMa; anchors.fill: parent; hoverEnabled: true
                cursorShape: customActionsRow.selFilled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                  if (!customActionsRow.selFilled) return;
                  panelsList.edUnpackLayout(customActionsRow.selData.data);
                  panelsList.edSyncLiveProps();
                  panelsList.edCustomIsLoaded = true;
                  panelsList.edSlotIsLoaded = false;
                  loadCustomBtn.loaded = true;
                  loadCustomFlash.restart();
                }
              }
            }

            // EXPORT
            Rectangle {
              id: copyBtn
              width: vpx(46); height: vpx(16); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
              opacity: customActionsRow.selFilled ? 1.0 : 0.25
              property bool copied: false
              property bool savedToFile: false
              color: copied ? Qt.rgba(0.10,0.55,0.10,0.80)
                   : exportBadgeMa.containsMouse && customActionsRow.selFilled ? Qt.rgba(0.10,0.35,0.65,0.80)
                   : Qt.rgba(0.05,0.20,0.45,0.50)
              border.width: vpx(1); border.color: copied ? "#44cc44" : "#4477cc"
              StyledText { anchors.centerIn: parent
                text: copyBtn.copied ? (copyBtn.savedToFile ? "✓ Saved!" : "✓ Copied") : "⬆ Export"
                font.pixelSize: vpx(8); font.bold: true; color: copyBtn.copied ? "#aaffaa" : "#aaccff" }
              Timer { id: copyFlash; interval: 1500; onTriggered: { copyBtn.copied = false; copyBtn.savedToFile = false; } }
              MouseArea { id: exportBadgeMa; anchors.fill: parent; hoverEnabled: true
                cursorShape: customActionsRow.selFilled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                  if (!customActionsRow.selFilled) return;
                  try {
                    var obj = JSON.parse(customActionsRow.selData.data);
                    obj.n = customActionsRow.selData.name;
                    var json = JSON.stringify(obj, null, 2);
                    var safeName = customActionsRow.selData.name.replace(/[^a-zA-Z0-9_\-]/g, "_");
                    var fileUrl = Qt.resolvedUrl("../layouts/" + safeName + ".json");
                    var xhr = new XMLHttpRequest();
                    xhr.open("PUT", fileUrl, false);
                    xhr.send(json);
                    copyBtn.savedToFile = (xhr.status === 200 || xhr.status === 201);
                    copyBtn.copied = true;
                    if (!copyBtn.savedToFile) clipboardHelper.copyText(json);
                  } catch(e) {
                    clipboardHelper.copyText(customActionsRow.selData.data);
                    copyBtn.copied = true;
                  }
                  copyFlash.restart();
                }
              }
            }

            // SAVE (overwrite)
            Rectangle {
              id: saveCustomOverwriteBtn
              width: vpx(46); height: vpx(16); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
              opacity: customActionsRow.selFilled ? 1.0 : 0.25
              property bool saved: false
              color: saved ? Qt.rgba(0.10,0.65,0.10,0.80)
                   : saveOverwriteMa.containsMouse && customActionsRow.selFilled ? Qt.rgba(0.15,0.55,0.15,0.80)
                   : Qt.rgba(0.05,0.30,0.05,0.50)
              border.width: vpx(1); border.color: saved ? "#88ff88" : "#44aa44"
              StyledText { anchors.centerIn: parent
                text: saveCustomOverwriteBtn.saved ? "✓ Saved" : "💾 Save"
                font.pixelSize: vpx(8); font.bold: true; color: saveCustomOverwriteBtn.saved ? "#aaffaa" : "#aaddaa" }
              Timer { id: saveOverwriteFlash; interval: 1200; onTriggered: saveCustomOverwriteBtn.saved = false }
              MouseArea { id: saveOverwriteMa; anchors.fill: parent; hoverEnabled: true
                cursorShape: customActionsRow.selFilled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                  if (!customActionsRow.selFilled) return;
                  panelsList.overwriteCustomLayout(customActionsRow.sel, panelsList.edPackLayout());
                  saveCustomOverwriteBtn.saved = true;
                  saveOverwriteFlash.restart();
                }
              }
            }

            // DELETE
            Rectangle {
              width: vpx(40); height: vpx(16); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
              opacity: customActionsRow.selFilled ? 1.0 : 0.25
              color: delCustomMa.containsMouse && customActionsRow.selFilled ? Qt.rgba(0.8,0.1,0.1,0.80) : Qt.rgba(0.45,0.05,0.05,0.45)
              border.width: vpx(1); border.color: "#ff4444"
              StyledText { anchors.centerIn: parent; text: "Delete"; font.pixelSize: vpx(8); font.bold: true; color: "#ffaaaa" }
              MouseArea { id: delCustomMa; anchors.fill: parent; hoverEnabled: true
                cursorShape: customActionsRow.selFilled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: { if (customActionsRow.selFilled) panelsList.deleteCustomLayout(customActionsRow.sel); }
              }
            }
          }
        } // end customHeaderRow

        // ── Custom layout badges (number + name only, click to select) ─
        // Flow wraps onto a new row after 12 badges so 13+ are never cut off
        Flow {
          spacing: vpx(4)
          width: parent.width
          visible: panelsList.customLayouts.length > 0

          Repeater {
            model: { var _r = panelsList.customRevision; return panelsList.customLayouts.length; }
            delegate: Rectangle {
              id: customRect
              property var cData: { var _r = panelsList.customRevision; return panelsList.customLayouts[index] || { name: "", data: "" }; }
              property bool isActive: panelsList.edActiveCustom === index
              property bool isRenaming: false
              width: customInnerRow.implicitWidth + vpx(8); height: vpx(20); radius: vpx(3)
              color: isRenaming ? Qt.rgba(0.10,0.10,0.30,0.60)
                   : isActive   ? Qt.rgba(0.65,0.35,0.10,0.25)
                   :              Qt.rgba(1,1,1,0.07)
              border.width: vpx(1)
              border.color: isRenaming ? "#aaaaff"
                          : isActive   ? "#ee9933"
                          :              Qt.rgba(1,1,1,0.22)

              function commitRename() {
                var n = customRenameInput.text.trim();
                if (n === "") n = "Custom " + index;
                panelsList.renameCustomLayout(index, n);
                isRenaming = false;
              }

              // Selection MouseArea — must be BEFORE the inner row so buttons on top receive clicks
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                enabled: !isRenaming
                onClicked: {
                  panelsList.edActiveCustom = (panelsList.edActiveCustom === index) ? -1 : index;
                }
                onDoubleClicked: {
                  customRenameInput.text = cData.name;
                  isRenaming = true;
                  customRenameInput.selectAll();
                  customRenameInput.forceActiveFocus();
                }
              }

              Row {
                id: customInnerRow
                anchors { left: parent.left; leftMargin: vpx(4); right: parent.right; rightMargin: vpx(4); verticalCenter: parent.verticalCenter }
                spacing: vpx(4)

                // Index badge
                Rectangle {
                  width: vpx(16); height: vpx(16); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                  color: isActive ? Qt.rgba(0.65,0.35,0.10,0.70) : Qt.rgba(1,1,1,0.15)
                  border.width: vpx(1); border.color: isActive ? "#ee9933" : Qt.rgba(1,1,1,0.35)
                  StyledText { anchors.centerIn: parent; text: index + 1; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
                }

                // Name label / rename input
                StyledText {
                  visible: !isRenaming
                  text: (cData.name ? cData.name : "Unnamed"); elide: Text.ElideRight
                  width: Math.min(implicitWidth, vpx(120))
                  font.pixelSize: vpx(9); font.bold: isActive; color: "#ffffff"
                  anchors.verticalCenter: parent.verticalCenter
                }

                // Rename input + ✓
                Row {
                  visible: isRenaming
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: vpx(3)
                  width: vpx(58)
                  Rectangle {
                    width: parent.width - vpx(21); height: vpx(16); radius: vpx(2)
                    color: Qt.rgba(0,0,0,0.40); border.width: vpx(1); border.color: "#aaaaff"
                    TextInput {
                      id: customRenameInput
                      anchors { fill: parent; leftMargin: vpx(3); rightMargin: vpx(3) }
                      verticalAlignment: TextInput.AlignVCenter
                      font.pixelSize: vpx(8); font.bold: true; color: "#ffffff"
                      selectByMouse: true; maximumLength: 32; clip: true
                      Keys.onReturnPressed: customRect.commitRename()
                      Keys.onEnterPressed:  customRect.commitRename()
                      Keys.onEscapePressed: { isRenaming = false; }
                    }
                  }
                  Rectangle {
                    width: vpx(18); height: vpx(16); radius: vpx(2)
                    color: customConfirmMa.containsMouse ? Qt.rgba(0.15,0.70,0.15,0.90) : Qt.rgba(0.05,0.45,0.05,0.70)
                    border.width: vpx(1); border.color: "#44dd44"
                    StyledText { anchors.centerIn: parent; text: "✓"; font.pixelSize: vpx(9); font.bold: true; color: "#ffffff" }
                    MouseArea { id: customConfirmMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                      onClicked: customRect.commitRename()
                    }
                  }
                }

                // ✎ Rename button (visible when not renaming and filled)
                Rectangle {
                  width: vpx(14); height: vpx(14); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
                  visible: cData.data !== "" && !isRenaming
                  color: customRenameBtnMa.containsMouse ? Qt.rgba(0.30,0.30,0.80,0.80) : Qt.rgba(1,1,1,0.10)
                  border.width: vpx(1); border.color: customRenameBtnMa.containsMouse ? "#aaaaff" : Qt.rgba(1,1,1,0.25)
                  StyledText { anchors.centerIn: parent; text: "✎"; font.pixelSize: vpx(8); color: "#ccccff" }
                  MouseArea { id: customRenameBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      panelsList.edActiveCustom = index;
                      customRenameInput.text = cData.name;
                      isRenaming = true;
                      customRenameInput.selectAll();
                      customRenameInput.forceActiveFocus();
                    }
                  }
                }

                // ℹ Info button
                Rectangle {
                  width: vpx(14); height: vpx(14); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
                  visible: cData.data !== "" && !isRenaming
                  color: customInfoBtnMa.containsMouse ? Qt.rgba(0.10,0.45,0.80,0.80) : Qt.rgba(1,1,1,0.10)
                  border.width: vpx(1); border.color: customInfoBtnMa.containsMouse ? "#55aaff" : Qt.rgba(1,1,1,0.25)
                  StyledText { anchors.centerIn: parent; text: "i"; font.pixelSize: vpx(8); font.bold: true; color: "#88ccff" }
                  MouseArea { id: customInfoBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      panelsList.edActiveCustom = index;
                      panelsList.edCustomInfoOpen = !panelsList.edCustomInfoOpen;
                    }
                  }
                }
              }
            }
          }
        } // end Flow

      } // end Column (customsPage)
    } // end customsPage

    // ── Reset / Startup Sub-Page ──────────────────────────────────
    Rectangle {
      id: startupPage
      visible: panelsList.edResetOpen && !panelsList.edMoveOpen
      anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
      color: "transparent"

      Rectangle { anchors.fill: parent; color: Qt.rgba(0.02, 0.04, 0.08, 0.70); radius: vpx(2) }

      Column {
        anchors { top: parent.top; topMargin: vpx(6); left: parent.left; leftMargin: vpx(12) }
        spacing: vpx(6)

        // ── ROW 1: Reset Layout ───────────────────────────────────
        Row {
          spacing: vpx(10)

          StyledText {
            text: "Reset Layout:"
            font.pixelSize: vpx(9); font.bold: true; color: "#aaaaaa"
            anchors.verticalCenter: parent.verticalCenter
            width: vpx(82)
          }

          Repeater {
            model: 8
            delegate: Rectangle {
              property bool isSet: panelsList.edResetLayout === index
              width: vpx(28); height: vpx(22); radius: vpx(4)
              anchors.verticalCenter: parent.verticalCenter
              color: isSet ? Qt.rgba(0.15,0.45,0.85,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: isSet ? "#44aaff" : Qt.rgba(1,1,1,0.22)
              Column {
                anchors.centerIn: parent; spacing: vpx(1)
                StyledText { anchors.horizontalCenter: parent.horizontalCenter
                  text: index; font.pixelSize: vpx(9); font.bold: true; color: "#ffffff" }
                StyledText { anchors.horizontalCenter: parent.horizontalCenter
                  font.pixelSize: vpx(6); color: isSet ? "#88ccff" : Qt.rgba(1,1,1,0.35)
                  text: index === 0 ? "Editor" : index === 1 ? "Default" : index === 2 ? "Strip"
                      : index === 3 ? "Stack" : index === 4 ? "Flat" : index === 5 ? "Big Box" : index === 6 ? "Uniflow" : index === 7 ? "Carousel" : "RTL" }
              }
              Rectangle {
                visible: isSet
                width: vpx(10); height: vpx(10); radius: vpx(5)
                color: "#44aaff"; border.color: "#ffffff"; border.width: vpx(1)
                anchors { top: parent.top; right: parent.right; topMargin: vpx(-3); rightMargin: vpx(-3) }
                StyledText { anchors.centerIn: parent; text: "✓"; font.pixelSize: vpx(7); font.bold: true; color: "#ffffff" }
              }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  panelsList.edResetLayout = (panelsList.edResetLayout === index) ? -1 : index;
                  api.memory.set(pageKey + "edResetLayout", String(panelsList.edResetLayout));
                }
              }
            }
          }

          Rectangle { width: vpx(1); height: vpx(22); color: Qt.rgba(1,1,1,0.15); anchors.verticalCenter: parent.verticalCenter }

          // Reset action button
          Rectangle {
            height: vpx(22); radius: vpx(4); width: resetActLbl.implicitWidth + vpx(14)
            anchors.verticalCenter: parent.verticalCenter
            opacity: panelsList.edResetLayout >= 0 ? 1.0 : 0.30
            color: resetActMa.containsMouse && panelsList.edResetLayout >= 0 ? Qt.rgba(0.15,0.45,0.85,0.70) : Qt.rgba(0.08,0.25,0.55,0.50)
            border.width: vpx(1); border.color: "#4488ff"
            StyledText { id: resetActLbl; anchors.centerIn: parent; text: "Apply Now"; font.pixelSize: vpx(8); font.bold: true; color: "#aaccff" }
            MouseArea { id: resetActMa; anchors.fill: parent; hoverEnabled: true
              cursorShape: panelsList.edResetLayout >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: {
                if (panelsList.edResetLayout < 0) return;
                var target = panelsList.edResetLayout;
                panelsList.layoutMode = (target === 0) ? 0 : target;
                panelsList.applyLayoutMode();
                api.memory.set(pageKey + "gameLayout", String(target));
                panelsList.edResetOpen = false;
              }
            }
          }

          StyledText {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.35)
            text: panelsList.edResetLayout < 0 ? "Select a layout to jump to it" : "Jumps to the selected layout immediately"
          }
        }

        // Divider between sections
        Rectangle { width: vpx(600); height: vpx(1); color: Qt.rgba(1,1,1,0.08) }

        // ── ROW 2: Startup Override ───────────────────────────────
        Row {
          spacing: vpx(10)

          StyledText {
            text: "Always Boot To:"
            font.pixelSize: vpx(9); font.bold: true; color: safeAccent
            anchors.verticalCenter: parent.verticalCenter
            width: vpx(82)
          }

          Repeater {
            model: 8
            delegate: Rectangle {
              property bool isSet: panelsList.edForceStartup === index
              width: vpx(28); height: vpx(22); radius: vpx(4)
              anchors.verticalCenter: parent.verticalCenter
              color: isSet ? Qt.rgba(0.15,0.65,0.25,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: isSet ? "#44cc66" : Qt.rgba(1,1,1,0.22)
              Column {
                anchors.centerIn: parent; spacing: vpx(1)
                StyledText { anchors.horizontalCenter: parent.horizontalCenter
                  text: index; font.pixelSize: vpx(9); font.bold: true; color: "#ffffff" }
                StyledText { anchors.horizontalCenter: parent.horizontalCenter
                  font.pixelSize: vpx(6); color: isSet ? "#88ffaa" : Qt.rgba(1,1,1,0.35)
                  text: index === 0 ? "Editor" : index === 1 ? "Default" : index === 2 ? "Strip"
                      : index === 3 ? "Stack" : index === 4 ? "Flat" : index === 5 ? "Big Box" : index === 6 ? "Uniflow" : index === 7 ? "Carousel" : "RTL" }
              }
              Rectangle {
                visible: isSet
                width: vpx(10); height: vpx(10); radius: vpx(5)
                color: "#44cc66"; border.color: "#ffffff"; border.width: vpx(1)
                anchors { top: parent.top; right: parent.right; topMargin: vpx(-3); rightMargin: vpx(-3) }
                StyledText { anchors.centerIn: parent; text: "✓"; font.pixelSize: vpx(7); font.bold: true; color: "#ffffff" }
              }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  panelsList.edForceStartup = (panelsList.edForceStartup === index) ? -1 : index;
                  api.memory.set(pageKey + "edForceStartup", String(panelsList.edForceStartup));
                }
              }
            }
          }

          Rectangle { width: vpx(1); height: vpx(22); color: Qt.rgba(1,1,1,0.15); anchors.verticalCenter: parent.verticalCenter }

          StyledText {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.35)
            text: panelsList.edForceStartup < 0
                ? "Off — restores last used layout on boot"
                : ("Every boot opens layout " + panelsList.edForceStartup + " · reboot to test →")
          }

          // F5 hint — theme reload can only be triggered by Pegasus itself
          StyledText {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.35)
            text: "Press F5 to reload theme"
          }
        }
      }
    }

    // ── Wrapper Sub-Page ─────────────────────────────────────────
    Rectangle {
      id: wrapperPage
      visible: panelsList.edWrapperOpen
      anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
      color: "transparent"
      Rectangle { anchors.fill: parent; color: Qt.rgba(0.02, 0.02, 0.05, 0.85); radius: vpx(2) }

      // ── Left column title ──
      StyledText {
        anchors { top: parent.top; left: parent.left; topMargin: vpx(5); leftMargin: vpx(8) }
        text: "Reflection & Corner"; font.pixelSize: vpx(8); font.bold: true
        color: safeAccent; opacity: 0.85
      }

      // ── Left column: Corner Radius + Reflection + Shadow On/Opacity ──
      Column {
        id: wrapLeftCol
        anchors { top: parent.top; left: parent.left; topMargin: vpx(18); leftMargin: vpx(8) }
        spacing: vpx(5)

        // ── Corner Radius ──
        Row { spacing: vpx(6); height: vpx(18)
          StyledText { text: "Corner Radius"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.6); width: vpx(108); anchors.verticalCenter: parent.verticalCenter }
          StepBtn { label: "-"; onClicked: { panelsList.wrapCornerRadius = Math.max(0, panelsList.wrapCornerRadius - 1); api.memory.set(pageKey + "wrapCornerRadius", String(panelsList.wrapCornerRadius)); } }
          Rectangle { height: vpx(16); width: vpx(40); radius: vpx(2); color: Qt.rgba(1,1,1,0.08); anchors.verticalCenter: parent.verticalCenter
            StyledText { anchors.centerIn: parent; text: Math.round(panelsList.wrapCornerRadius) + " px"; font.pixelSize: vpx(8); color: "#ffffff" } }
          StepBtn { label: "+"; onClicked: { panelsList.wrapCornerRadius = Math.min(400, panelsList.wrapCornerRadius + 1); api.memory.set(pageKey + "wrapCornerRadius", String(panelsList.wrapCornerRadius)); } }
          Rectangle { height: vpx(16); width: vpx(36); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
            color: wrapCRReset.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06); border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.2)
            StyledText { anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(7); color: Qt.rgba(1,1,1,0.7) }
            MouseArea { id: wrapCRReset; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: { panelsList.wrapCornerRadius = 7; api.memory.set(pageKey + "wrapCornerRadius", "7"); } } }
        }

        // ── Reflection Height ──
        Row { spacing: vpx(6); height: vpx(18)
          StyledText { text: "Reflection Height"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.6); width: vpx(108); anchors.verticalCenter: parent.verticalCenter }
          StepBtn { label: "-"; onClicked: { panelsList.wrapReflectionSize = Math.max(0, panelsList.wrapReflectionSize - 5); api.memory.set(pageKey + "wrapReflectionSize", String(panelsList.wrapReflectionSize)); } }
          Rectangle { height: vpx(16); width: vpx(40); radius: vpx(2); color: Qt.rgba(1,1,1,0.08); anchors.verticalCenter: parent.verticalCenter
            StyledText { anchors.centerIn: parent; text: Math.round(panelsList.wrapReflectionSize) + " px"; font.pixelSize: vpx(8); color: "#ffffff" } }
          StepBtn { label: "+"; onClicked: { panelsList.wrapReflectionSize = Math.min(800, panelsList.wrapReflectionSize + 5); api.memory.set(pageKey + "wrapReflectionSize", String(panelsList.wrapReflectionSize)); } }
          Rectangle { height: vpx(16); width: vpx(36); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
            color: wrapRSReset.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06); border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.2)
            StyledText { anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(7); color: Qt.rgba(1,1,1,0.7) }
            MouseArea { id: wrapRSReset; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: { panelsList.wrapReflectionSize = 30; api.memory.set(pageKey + "wrapReflectionSize", "30"); } } }
        }

        // ── Reflection Opacity ──
        Row { spacing: vpx(6); height: vpx(18)
          StyledText { text: "Reflection Opacity"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.6); width: vpx(108); anchors.verticalCenter: parent.verticalCenter }
          StepBtn { label: "-"; onClicked: { panelsList.wrapReflectionOpacity = Math.max(0, Math.round((panelsList.wrapReflectionOpacity - 0.05) * 100) / 100); api.memory.set(pageKey + "wrapReflectionOpacity", String(panelsList.wrapReflectionOpacity)); } }
          Rectangle { height: vpx(16); width: vpx(40); radius: vpx(2); color: Qt.rgba(1,1,1,0.08); anchors.verticalCenter: parent.verticalCenter
            StyledText { anchors.centerIn: parent; text: Math.round(panelsList.wrapReflectionOpacity * 100) + "%"; font.pixelSize: vpx(8); color: "#ffffff" } }
          StepBtn { label: "+"; onClicked: { panelsList.wrapReflectionOpacity = Math.min(1.0, Math.round((panelsList.wrapReflectionOpacity + 0.05) * 100) / 100); api.memory.set(pageKey + "wrapReflectionOpacity", String(panelsList.wrapReflectionOpacity)); } }
          Rectangle { height: vpx(16); width: vpx(36); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
            color: wrapROReset.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06); border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.2)
            StyledText { anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(7); color: Qt.rgba(1,1,1,0.7) }
            MouseArea { id: wrapROReset; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: { panelsList.wrapReflectionOpacity = 0.2; api.memory.set(pageKey + "wrapReflectionOpacity", "0.2"); } } }
        }

        // ── Reflection Blur ──
        Row { spacing: vpx(6); height: vpx(18)
          StyledText { text: "Reflection Blur"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.6); width: vpx(108); anchors.verticalCenter: parent.verticalCenter }
          StepBtn { label: "-"; onClicked: { panelsList.wrapReflectionBlur = Math.max(0, panelsList.wrapReflectionBlur - 2); api.memory.set(pageKey + "wrapReflectionBlur", String(panelsList.wrapReflectionBlur)); } }
          Rectangle { height: vpx(16); width: vpx(40); radius: vpx(2); color: Qt.rgba(1,1,1,0.08); anchors.verticalCenter: parent.verticalCenter
            StyledText { anchors.centerIn: parent; text: panelsList.wrapReflectionBlur > 0 ? Math.round(panelsList.wrapReflectionBlur) + " px" : "Off"; font.pixelSize: vpx(8); color: "#ffffff" } }
          StepBtn { label: "+"; onClicked: { panelsList.wrapReflectionBlur = Math.min(256, panelsList.wrapReflectionBlur + 2); api.memory.set(pageKey + "wrapReflectionBlur", String(panelsList.wrapReflectionBlur)); } }
          Rectangle { height: vpx(16); width: vpx(36); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
            color: wrapRBReset.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06); border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.2)
            StyledText { anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(7); color: Qt.rgba(1,1,1,0.7) }
            MouseArea { id: wrapRBReset; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: { panelsList.wrapReflectionBlur = 0; api.memory.set(pageKey + "wrapReflectionBlur", "0"); } } }
        }

        // ── Shadow: On/Off + Opacity ──
        Row { spacing: vpx(6); height: vpx(18)
          StyledText { text: "Shadow"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.6); width: vpx(108); anchors.verticalCenter: parent.verticalCenter }
          Rectangle {
            width: vpx(14); height: vpx(14); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
            color: panelsList.wrapShadowOn ? Qt.rgba(0.15,0.65,0.15,0.70) : Qt.rgba(1,1,1,0.07)
            border.width: vpx(1); border.color: panelsList.wrapShadowOn ? "#55ee55" : Qt.rgba(1,1,1,0.30)
            StyledText { anchors.centerIn: parent; text: panelsList.wrapShadowOn ? "✓" : ""; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { panelsList.wrapShadowOn = !panelsList.wrapShadowOn; api.memory.set(pageKey + "wrapShadowOn", String(panelsList.wrapShadowOn)); } }
          }
          StyledText { text: "On"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.45); anchors.verticalCenter: parent.verticalCenter }
          StepBtn { label: "-"; onClicked: { panelsList.wrapShadowOpacity = Math.max(0, Math.round((panelsList.wrapShadowOpacity - 0.05) * 100) / 100); api.memory.set(pageKey + "wrapShadowOpacity", String(panelsList.wrapShadowOpacity)); } }
          Rectangle { height: vpx(16); width: vpx(40); radius: vpx(2); color: Qt.rgba(1,1,1,0.08); anchors.verticalCenter: parent.verticalCenter
            StyledText { anchors.centerIn: parent; text: Math.round(panelsList.wrapShadowOpacity * 100) + "%"; font.pixelSize: vpx(8); color: "#ffffff" } }
          StepBtn { label: "+"; onClicked: { panelsList.wrapShadowOpacity = Math.min(1.0, Math.round((panelsList.wrapShadowOpacity + 0.05) * 100) / 100); api.memory.set(pageKey + "wrapShadowOpacity", String(panelsList.wrapShadowOpacity)); } }
        }
      }

      // ── Thin divider ──
      Rectangle {
        id: wrapDivider
        anchors { top: parent.top; bottom: parent.bottom; left: wrapLeftCol.right; leftMargin: vpx(8); topMargin: vpx(4); bottomMargin: vpx(4) }
        width: vpx(1); color: Qt.rgba(1,1,1,0.07)
      }

      // ── Right column title ──
      StyledText {
        anchors { top: parent.top; left: wrapDivider.right; topMargin: vpx(5); leftMargin: vpx(8) }
        text: "Shadow"; font.pixelSize: vpx(8); font.bold: true
        color: safeAccent; opacity: 0.85
      }

      // ── Right column: Shadow Type + DropShadow detail controls ────
      Column {
        id: wrapRightCol
        anchors { top: parent.top; left: wrapDivider.right; topMargin: vpx(18); leftMargin: vpx(8) }
        spacing: vpx(5)

        // ── Shadow type ──
        Row { spacing: vpx(6); height: vpx(18)
          StyledText { text: "Shadow Type"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.6); width: vpx(80); anchors.verticalCenter: parent.verticalCenter }
          Repeater {
            model: [
              { label: "Off",                      val: -1 },
              { label: "Bitmap (right edge)",      val:  0 },
              { label: "DropShadow (corner-aware)", val:  1 }
            ]
            delegate: Rectangle {
              property bool sel: panelsList.wrapShadowMode === modelData.val
              height: vpx(16); radius: vpx(3); width: shadowModeLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
              color: sel ? Qt.rgba(0.27,0.67,1.0,0.35) : (shadowModeMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.07))
              border.width: vpx(1); border.color: sel ? "#44aaff" : Qt.rgba(1,1,1,0.18)
              StyledText { id: shadowModeLbl; anchors.centerIn: parent; text: modelData.label; font.pixelSize: vpx(8); color: "#ffffff" }
              MouseArea { id: shadowModeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  panelsList.wrapShadowMode = modelData.val;
                  // Off (-1) also forces wrapShadowOn false so the bitmap path hides too
                  if (modelData.val === -1) { panelsList.wrapShadowOn = false; api.memory.set(pageKey + "wrapShadowOn", "false"); }
                  else                      { panelsList.wrapShadowOn = true;  api.memory.set(pageKey + "wrapShadowOn", "true"); }
                  api.memory.set(pageKey + "wrapShadowMode", String(modelData.val));
                }
              }
            }
          }
        }

        // ── DropShadow Blur (mode 1 only) ──
        Row { spacing: vpx(6); height: vpx(18); opacity: panelsList.wrapShadowMode === 1 ? 1.0 : 0.3
          StyledText { text: "Blur"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.6); width: vpx(80); anchors.verticalCenter: parent.verticalCenter }
          StepBtn { label: "-"; onClicked: { if (panelsList.wrapShadowMode === 1) { panelsList.wrapShadowRadius = Math.max(0, panelsList.wrapShadowRadius - 1); api.memory.set(pageKey + "wrapShadowRadius", String(panelsList.wrapShadowRadius)); } } }
          Rectangle { height: vpx(16); width: vpx(40); radius: vpx(2); color: Qt.rgba(1,1,1,0.08); anchors.verticalCenter: parent.verticalCenter
            StyledText { anchors.centerIn: parent; text: Math.round(panelsList.wrapShadowRadius) + " px"; font.pixelSize: vpx(8); color: "#ffffff" } }
          StepBtn { label: "+"; onClicked: { if (panelsList.wrapShadowMode === 1) { panelsList.wrapShadowRadius = Math.min(256, panelsList.wrapShadowRadius + 1); api.memory.set(pageKey + "wrapShadowRadius", String(panelsList.wrapShadowRadius)); } } }
        }

        // ── DropShadow Offset X / Y (mode 1 only) ──
        Row { spacing: vpx(6); height: vpx(18); opacity: panelsList.wrapShadowMode === 1 ? 1.0 : 0.3
          StyledText { text: "Offset X / Y"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.6); width: vpx(80); anchors.verticalCenter: parent.verticalCenter }
          StepBtn { label: "-"; onClicked: { if (panelsList.wrapShadowMode === 1) { panelsList.wrapShadowOffsetX -= 1; api.memory.set(pageKey + "wrapShadowOffsetX", String(panelsList.wrapShadowOffsetX)); } } }
          Rectangle { height: vpx(16); width: vpx(40); radius: vpx(2); color: Qt.rgba(1,1,1,0.08); anchors.verticalCenter: parent.verticalCenter
            StyledText { anchors.centerIn: parent; text: Math.round(panelsList.wrapShadowOffsetX); font.pixelSize: vpx(8); color: "#ffffff" } }
          StepBtn { label: "+"; onClicked: { if (panelsList.wrapShadowMode === 1) { panelsList.wrapShadowOffsetX += 1; api.memory.set(pageKey + "wrapShadowOffsetX", String(panelsList.wrapShadowOffsetX)); } } }
          StyledText { text: "/"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.35); anchors.verticalCenter: parent.verticalCenter }
          StepBtn { label: "-"; onClicked: { if (panelsList.wrapShadowMode === 1) { panelsList.wrapShadowOffsetY -= 1; api.memory.set(pageKey + "wrapShadowOffsetY", String(panelsList.wrapShadowOffsetY)); } } }
          Rectangle { height: vpx(16); width: vpx(40); radius: vpx(2); color: Qt.rgba(1,1,1,0.08); anchors.verticalCenter: parent.verticalCenter
            StyledText { anchors.centerIn: parent; text: Math.round(panelsList.wrapShadowOffsetY); font.pixelSize: vpx(8); color: "#ffffff" } }
          StepBtn { label: "+"; onClicked: { if (panelsList.wrapShadowMode === 1) { panelsList.wrapShadowOffsetY += 1; api.memory.set(pageKey + "wrapShadowOffsetY", String(panelsList.wrapShadowOffsetY)); } } }
        }

        // ── DropShadow Color (mode 1 only) ──
        Row { spacing: vpx(6); height: vpx(18); opacity: panelsList.wrapShadowMode === 1 ? 1.0 : 0.3
          StyledText { text: "Color"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.6); width: vpx(80); anchors.verticalCenter: parent.verticalCenter }
          Repeater {
            model: [
              { label: "Black",  col: "#000000" },
              { label: "Dark",   col: "#111122" },
              { label: "Blue",   col: "#001133" },
              { label: "White",  col: "#ffffff" },
              { label: "Accent", col: "accent"  },
              { label: "Theme",  col: "theme"   }
            ]
            delegate: Rectangle {
              // Resolve the actual hex string: special tokens read directly from
              // the UniColor memory keys that SettingsPage saves via onCurrentAccentHexChanged
              // / onCurrentThemeFillHexChanged. These are always clean #rrggbb strings.
              property string resolvedCol: {
                if (modelData.col === "accent") return api.memory.get("cfg.accentHex") || "#5d9809";
                if (modelData.col === "theme")  return api.memory.get("cfg.themeHex")  || "#1a1a2e";
                return modelData.col;
              }
              property bool sel: panelsList.wrapShadowColor === resolvedCol
              height: vpx(16); radius: vpx(3); width: wSCLbl.implicitWidth + vpx(12); anchors.verticalCenter: parent.verticalCenter
              color: sel ? Qt.rgba(0.3,0.7,1.0,0.35) : (wSCMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.07))
              border.width: vpx(1); border.color: sel ? "#44aaff" : Qt.rgba(1,1,1,0.18)
              Row { anchors.centerIn: parent; spacing: vpx(4)
                Rectangle { width: vpx(8); height: vpx(8); radius: vpx(1); anchors.verticalCenter: parent.verticalCenter
                  color: resolvedCol; border.color: Qt.rgba(1,1,1,0.3); border.width: vpx(1) }
                StyledText { id: wSCLbl; text: modelData.label; font.pixelSize: vpx(8); color: "#ffffff" }
              }
              MouseArea { id: wSCMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { if (panelsList.wrapShadowMode === 1) { panelsList.wrapShadowColor = resolvedCol; api.memory.set(pageKey + "wrapShadowColor", resolvedCol); } } }
            }
          }
        }

      }

      // ── Second vertical divider — after Shadow ───────────────
      Rectangle {
        id: wrapDivider2
        anchors { top: parent.top; bottom: parent.bottom; left: wrapRightCol.right; leftMargin: vpx(8); topMargin: vpx(4); bottomMargin: vpx(4) }
        width: vpx(1); color: Qt.rgba(1,1,1,0.07)
      }

      // ── Third column title ────────────────────────────────────
      StyledText {
        anchors { top: parent.top; left: wrapDivider2.right; topMargin: vpx(5); leftMargin: vpx(8) }
        text: "Tabs"; font.pixelSize: vpx(8); font.bold: true
        color: safeAccent; opacity: 0.85
      }

      // ── Third column: Tabs Editor button ─────────────────────
      Column {
        id: wrapTabsCol
        anchors { top: parent.top; left: wrapDivider2.right; topMargin: vpx(18); leftMargin: vpx(8) }
        spacing: vpx(5)

        Rectangle {
          id: tabsEditorBtn
          height: vpx(20); width: tabsEditorBtnLbl.implicitWidth + vpx(16); radius: vpx(4)
          color: tabsEditorBtnMa.containsMouse ? Qt.rgba(safeAccent.r, safeAccent.g, safeAccent.b, 0.35) : Qt.rgba(safeAccent.r, safeAccent.g, safeAccent.b, 0.18)
          border.width: vpx(1); border.color: Qt.rgba(safeAccent.r, safeAccent.g, safeAccent.b, 0.55)
          Behavior on color { ColorAnimation { duration: 80 } }
          StyledText {
            id: tabsEditorBtnLbl
            anchors.centerIn: parent
            text: "✦  Tabs Editor"
            font.pixelSize: vpx(9); font.bold: true; color: "#ffffff"
          }
          MouseArea {
            id: tabsEditorBtnMa
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: { panelsList.editorOpen = false; panelsList.edWrapperOpen = false; panelsList.edTabsOpen = true }
          }
        }
      }
    }


    // ── Tabs Editor Blade — moved outside editorOverlay (see sibling Rectangle below) ──

    // ── Debug Sub-Page ───────────────────────────────────────────
    Rectangle {
      id: debugPage
      visible: panelsList.edDebugOpen && !panelsList.edSlotsOpen && !panelsList.edMoveOpen
      anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
      color: "transparent"

      Rectangle { anchors.fill: parent; color: Qt.rgba(0.02, 0.02, 0.05, 0.85); radius: vpx(2) }

      // ── Debug button strip — single unified Row, no gaps ──────────
      Row {
        anchors { top: parent.top; topMargin: vpx(6); left: parent.left; leftMargin: vpx(8) }
        spacing: vpx(6)

        // Overlay ON/OFF
        Rectangle {
          height: vpx(20); radius: vpx(4); width: dbEnableTxt.implicitWidth + vpx(20); anchors.verticalCenter: parent.verticalCenter
          color: panelsList.edDebugEnabled ? Qt.rgba(1,0.55,0.0,0.30) : Qt.rgba(1,1,1,0.07)
          border.width: vpx(1); border.color: panelsList.edDebugEnabled ? "#ffaa33" : Qt.rgba(1,1,1,0.25)
          Row { anchors.centerIn: parent; spacing: vpx(6)
            Rectangle { width: vpx(8); height: vpx(8); radius: vpx(4); anchors.verticalCenter: parent.verticalCenter
              color: panelsList.edDebugEnabled ? "#ffaa33" : Qt.rgba(1,1,1,0.30) }
            StyledText { id: dbEnableTxt; text: panelsList.edDebugEnabled ? "Overlay ON" : "Overlay OFF"
              font.pixelSize: vpx(9); font.bold: true; color: "#ffffff"
              opacity: panelsList.edDebugEnabled ? 1.0 : 0.60 }
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: panelsList.edDebugEnabled = !panelsList.edDebugEnabled }
        }

        // Debug Layout
        Rectangle {
          height: vpx(20); radius: vpx(4); width: dbgLayoutTxt.implicitWidth + vpx(20); anchors.verticalCenter: parent.verticalCenter
          color: panelsList.edDebugLayoutOpen ? Qt.rgba(0.3,0.5,1.0,0.35) : Qt.rgba(1,1,1,0.07)
          border.width: vpx(1); border.color: panelsList.edDebugLayoutOpen ? "#44aaff" : Qt.rgba(1,1,1,0.25)
          Row { anchors.centerIn: parent; spacing: vpx(6)
            Rectangle { width: vpx(8); height: vpx(8); radius: vpx(4); anchors.verticalCenter: parent.verticalCenter
              color: panelsList.edDebugLayoutOpen ? "#44aaff" : Qt.rgba(1,1,1,0.30) }
            StyledText { id: dbgLayoutTxt; text: "Debug Layout"
              font.pixelSize: vpx(9); font.bold: true; color: "#ffffff"
              opacity: panelsList.edDebugLayoutOpen ? 1.0 : 0.60 }
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: panelsList.edDebugLayoutOpen = !panelsList.edDebugLayoutOpen }
        }

        // Panel Bounds (red — content Item inside PanelWrapper)
        Rectangle {
          height: vpx(20); radius: vpx(4); width: dbgBoundsTxt.implicitWidth + vpx(20); anchors.verticalCenter: parent.verticalCenter
          color: panelsList.edShowBounds ? Qt.rgba(1,0.2,0.2,0.35) : Qt.rgba(1,1,1,0.07)
          border.width: vpx(1); border.color: panelsList.edShowBounds ? "#ff4444" : Qt.rgba(1,1,1,0.25)
          Row { anchors.centerIn: parent; spacing: vpx(6)
            Rectangle { width: vpx(8); height: vpx(8); radius: vpx(1); anchors.verticalCenter: parent.verticalCenter
              color: panelsList.edShowBounds ? "#ff4444" : Qt.rgba(1,1,1,0.30) }
            StyledText { id: dbgBoundsTxt; text: "Panel Bounds"; font.pixelSize: vpx(9); font.bold: true; color: "#ffffff"; opacity: panelsList.edShowBounds ? 1.0 : 0.60 }
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edShowBounds = !panelsList.edShowBounds }
        }

        // Wrap Bounds (orange — FocusScope outer boundary)
        Rectangle {
          height: vpx(20); radius: vpx(4); width: dbgWrapTxt.implicitWidth + vpx(20); anchors.verticalCenter: parent.verticalCenter
          color: panelsList.edShowWrapperBounds ? Qt.rgba(1,0.6,0.1,0.35) : Qt.rgba(1,1,1,0.07)
          border.width: vpx(1); border.color: panelsList.edShowWrapperBounds ? "#ff9933" : Qt.rgba(1,1,1,0.25)
          Row { anchors.centerIn: parent; spacing: vpx(6)
            Rectangle { width: vpx(8); height: vpx(8); radius: vpx(1); anchors.verticalCenter: parent.verticalCenter
              color: panelsList.edShowWrapperBounds ? "#ff9933" : Qt.rgba(1,1,1,0.30) }
            StyledText { id: dbgWrapTxt; text: "Wrap Bounds"; font.pixelSize: vpx(9); font.bold: true; color: "#ffffff"; opacity: panelsList.edShowWrapperBounds ? 1.0 : 0.60 }
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edShowWrapperBounds = !panelsList.edShowWrapperBounds }
        }

        // Debug Channel Names
        Rectangle {
          height: vpx(20); radius: vpx(4); width: dbgChanNamesTxt.implicitWidth + vpx(20); anchors.verticalCenter: parent.verticalCenter
          color: panelsList.libChanDebug ? Qt.rgba(0.8,0.1,0.1,0.35) : Qt.rgba(1,1,1,0.07)
          border.width: vpx(1); border.color: panelsList.libChanDebug ? "#ff4444" : Qt.rgba(1,1,1,0.25)
          Row { anchors.centerIn: parent; spacing: vpx(6)
            Rectangle { width: vpx(8); height: vpx(8); radius: vpx(1); anchors.verticalCenter: parent.verticalCenter
              color: panelsList.libChanDebug ? "#ff4444" : Qt.rgba(1,1,1,0.30) }
            StyledText { id: dbgChanNamesTxt; text: "Debug Channel Names"; font.pixelSize: vpx(9); font.bold: true; color: "#ffffff"; opacity: panelsList.libChanDebug ? 1.0 : 0.60 }
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libChanDebug = !panelsList.libChanDebug }
        }

        // Debug Panel Wrapper (red box — PanelsList/PathView debug overlay)
        Rectangle {
          height: vpx(20); radius: vpx(4); width: dbgWrapBndsTxt.implicitWidth + vpx(20); anchors.verticalCenter: parent.verticalCenter
          color: panelsList.edShowPanelListDebug ? Qt.rgba(0.6,0.1,0.8,0.35) : Qt.rgba(1,1,1,0.07)
          border.width: vpx(1); border.color: panelsList.edShowPanelListDebug ? "#cc44ff" : Qt.rgba(1,1,1,0.25)
          Row { anchors.centerIn: parent; spacing: vpx(6)
            Rectangle { width: vpx(8); height: vpx(8); radius: vpx(1); anchors.verticalCenter: parent.verticalCenter
              color: panelsList.edShowPanelListDebug ? "#cc44ff" : Qt.rgba(1,1,1,0.30) }
            StyledText { id: dbgWrapBndsTxt; text: "Debug Panel Wrapper"; font.pixelSize: vpx(9); font.bold: true; color: "#ffffff"; opacity: panelsList.edShowPanelListDebug ? 1.0 : 0.60 }
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edShowPanelListDebug = !panelsList.edShowPanelListDebug }
        }
      }

      // 5 wallpaper thumbnails — fills full width edge to edge
      Row {
        anchors { top: parent.top; topMargin: vpx(30); left: parent.left; leftMargin: vpx(4); right: parent.right; rightMargin: vpx(4) }
        spacing: vpx(4)

        Repeater {
          model: [
            { label: "Checker Board",       file: "../assets/images/wallpapers/Checker Board.png" },
            { label: "Debug Border",        file: "../assets/images/wallpapers/Debug Border.png" },
            { label: "Edit Mod Vertical",   file: "../assets/images/wallpapers/Edit Mod Vertical.png" },
            { label: "Edit Mode Horizonal", file: "../assets/images/wallpapers/Edit Mode Horizonal.png" },
            { label: "Test Zone",           file: "../assets/images/wallpapers/Test Zone.png" }
          ]
          delegate: Rectangle {
            property bool isSelected: panelsList.edDebugWallpaper === index
            // 5 tiles across full row: (parent.width - 4*spacing) / 5
            width: (debugPage.width - vpx(8) - vpx(16)) / 5
            height: vpx(100); radius: vpx(5)
            color: isSelected ? Qt.rgba(1,0.55,0.0,0.22) : Qt.rgba(1,1,1,0.05)
            border.width: vpx(2)
            border.color: isSelected ? "#ffaa33" : Qt.rgba(1,1,1,0.15)

            // Thumbnail image
            Image {
              anchors { top: parent.top; left: parent.left; right: parent.right; bottom: nameBar.top }
              anchors.margins: vpx(3)
              source: modelData.file
              fillMode: Image.PreserveAspectFit
              smooth: true
            }

            // Name bar at bottom
            Rectangle {
              id: nameBar
              anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
              height: vpx(18); radius: vpx(4)
              color: isSelected ? Qt.rgba(1,0.55,0.0,0.50) : Qt.rgba(0,0,0,0.65)
              StyledText {
                anchors.centerIn: parent
                text: modelData.label
                font.pixelSize: vpx(8); font.bold: isSelected
                color: isSelected ? "#ffffff" : Qt.rgba(1,1,1,0.85)
                elide: Text.ElideRight; width: parent.width - vpx(6)
                horizontalAlignment: Text.AlignHCenter
              }
            }

            // Selected checkmark badge
            Rectangle {
              visible: isSelected
              anchors { top: parent.top; right: parent.right; margins: vpx(3) }
              width: vpx(14); height: vpx(14); radius: vpx(7)
              color: "#ffaa33"
              StyledText { anchors.centerIn: parent; text: "✓"; font.pixelSize: vpx(9); font.bold: true; color: "#000000" }
            }

            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                panelsList.edDebugWallpaper = (panelsList.edDebugWallpaper === index) ? -1 : index;
                if (panelsList.edDebugWallpaper >= 0) panelsList.edDebugEnabled = true;
              }
            }
          }
        }
      }
    }

    // ── Move Editor Sub-Page ──────────────────────────────────────
    Rectangle {
      id: movePage
      visible: panelsList.edMoveOpen
      anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
      color: "transparent"
      z: 100   // sit above all other sub-pages so nothing shows through

      Rectangle { anchors.fill: parent; color: Qt.rgba(0.02, 0.02, 0.05, 0.98); radius: vpx(2) }

      Column {
        anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter }
        spacing: vpx(4)

        Grid {
          id: movePageGrid
          columns: 3; rows: 3; spacing: vpx(5)
          anchors.horizontalCenter: parent.horizontalCenter

          Item { width: vpx(32); height: vpx(32) }
          Rectangle {
            width: vpx(32); height: vpx(32); radius: vpx(5)
            color: mpU.containsMouse ? Qt.rgba(0.15,0.50,0.08,0.55) : Qt.rgba(0.10,0.30,0.05,0.35)
            border.color: mpU.containsMouse ? "#55dd44" : Qt.rgba(0.3,0.7,0.2,0.45); border.width: vpx(1)
            StyledText { anchors.centerIn: parent; text: "▲"; font.pixelSize: vpx(14); color: "#88ee66" }
            MouseArea { id: mpU; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: panelsList.edOverlayOffsetY = Math.max(0, panelsList.edOverlayOffsetY - vpx(10)) }
          }
          Item { width: vpx(32); height: vpx(32) }

          Rectangle {
            width: vpx(32); height: vpx(32); radius: vpx(5)
            color: mpL.containsMouse ? Qt.rgba(0.15,0.50,0.08,0.55) : Qt.rgba(0.10,0.30,0.05,0.35)
            border.color: mpL.containsMouse ? "#55dd44" : Qt.rgba(0.3,0.7,0.2,0.45); border.width: vpx(1)
            StyledText { anchors.centerIn: parent; text: "◄"; font.pixelSize: vpx(14); color: "#88ee66" }
            MouseArea { id: mpL; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: panelsList.edOverlayOffsetX -= vpx(10) }
          }
          Rectangle {
            width: vpx(32); height: vpx(32); radius: vpx(5)
            color: mpH.containsMouse ? Qt.rgba(0.25,0.55,1.0,0.45) : Qt.rgba(1,1,1,0.06)
            border.color: mpH.containsMouse ? Qt.rgba(0.4,0.7,1.0,0.70) : Qt.rgba(1,1,1,0.20); border.width: vpx(1)
            Column { anchors.centerIn: parent; spacing: vpx(0)
              StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: panelsList.edPanelAtBottom ? "↑" : "↓"
                font.pixelSize: vpx(12); color: "#ffffff"
              }
              StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: panelsList.edPanelAtBottom ? "Up" : "Down"
                font.pixelSize: vpx(7); font.bold: true; color: "#aaddff"
              }
            }
            MouseArea { id: mpH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: { panelsList.edPanelAtBottom = !panelsList.edPanelAtBottom; } }
          }
          Rectangle {
            width: vpx(32); height: vpx(32); radius: vpx(5)
            color: mpR.containsMouse ? Qt.rgba(0.15,0.50,0.08,0.55) : Qt.rgba(0.10,0.30,0.05,0.35)
            border.color: mpR.containsMouse ? "#55dd44" : Qt.rgba(0.3,0.7,0.2,0.45); border.width: vpx(1)
            StyledText { anchors.centerIn: parent; text: "►"; font.pixelSize: vpx(14); color: "#88ee66" }
            MouseArea { id: mpR; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: panelsList.edOverlayOffsetX += vpx(10) }
          }

          Item { width: vpx(32); height: vpx(32) }
          Rectangle {
            width: vpx(32); height: vpx(32); radius: vpx(5)
            color: mpD.containsMouse ? Qt.rgba(0.15,0.50,0.08,0.55) : Qt.rgba(0.10,0.30,0.05,0.35)
            border.color: mpD.containsMouse ? "#55dd44" : Qt.rgba(0.3,0.7,0.2,0.45); border.width: vpx(1)
            StyledText { anchors.centerIn: parent; text: "▼"; font.pixelSize: vpx(14); color: "#88ee66" }
            MouseArea { id: mpD; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: panelsList.edOverlayOffsetY += vpx(10) }
          }
          Item { width: vpx(32); height: vpx(32) }
        }

        StyledText {
          text: Math.round(panelsList.edOverlayOffsetX) + ", " + Math.round(panelsList.edOverlayOffsetY) + " px"
          font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.35)
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }
    }

    // ── Library Settings Sub-Page ─────────────────────────────────
    Rectangle {
      id: libraryPage
      visible: panelsList.edLibraryOpen
      anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
      color: "transparent"

      Rectangle {
        anchors.fill: parent; radius: vpx(2)
        color: {
          if (panelsList.edBgMode === 3) return "transparent";
          if (panelsList.edBgMode === 4) return Qt.rgba(1, 1, 1, 0.10);
          if (panelsList.edBgMode === 5) return Qt.rgba(0.55, 0.55, 0.58, 0.10);
          return Qt.rgba(0.01, 0.04, 0.10, 0.60);
        }
      }

      // ── Three columns side-by-side, left-anchored ─────────────────
      Row {
        anchors { top: parent.top; topMargin: vpx(7); left: parent.left; leftMargin: vpx(10) }
        spacing: vpx(18)

        // ══ COL 1: Square Icon Position ══════════════════════════
        Column {
          spacing: vpx(4)

          // Title row with Reset All + Enabled toggle
          Row {
            spacing: vpx(6)
            StyledText {
              text: "▢  Square Icon Position"
              font.pixelSize: vpx(8); font.bold: true; color: "#44aaff"
              anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
              height: vpx(14); radius: vpx(3); width: libRstSqAllLbl.implicitWidth + vpx(8); anchors.verticalCenter: parent.verticalCenter
              color: libRstSqAllMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: libRstSqAllLbl; anchors.centerIn: parent; text: "Reset All"; font.pixelSize: vpx(7); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: libRstSqAllMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { panelsList.libSquareOffsetX = 0; panelsList.libSquareOffsetY = 0 }
              }
            }
            Rectangle {
              height: vpx(14); radius: vpx(3); width: libSqEnLbl.implicitWidth + vpx(8); anchors.verticalCenter: parent.verticalCenter
              color: panelsList.libSquareEnabled ? Qt.rgba(0.1,0.6,0.2,0.35) : Qt.rgba(0.5,0.1,0.1,0.35)
              border.width: vpx(1); border.color: panelsList.libSquareEnabled ? "#44cc66" : "#cc4444"
              StyledText { id: libSqEnLbl; anchors.centerIn: parent
                text: panelsList.libSquareEnabled ? "Enabled" : "Disabled"
                font.pixelSize: vpx(7); font.bold: true
                color: panelsList.libSquareEnabled ? "#88ffaa" : "#ff8888" }
              MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: panelsList.libSquareEnabled = !panelsList.libSquareEnabled }
            }
          }

          // X row
          Row {
            spacing: vpx(3)
            StyledText { text: "X"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(8); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libSquareOffsetX -= vpx(10) }
            StepBtn { label: "−";  onClicked: panelsList.libSquareOffsetX -= vpx(2) }
            StyledText { text: Math.round(panelsList.libSquareOffsetX) + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(38); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "+";  onClicked: panelsList.libSquareOffsetX += vpx(2) }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libSquareOffsetX += vpx(10) }
            Rectangle {
              height: vpx(16); radius: vpx(3); width: libRstSqXLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
              color: libRstSqXMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: libRstSqXLbl; anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: libRstSqXMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libSquareOffsetX = 0 }
            }
          }

          // Y row (below X)
          Row {
            spacing: vpx(3)
            StyledText { text: "Y"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(8); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libSquareOffsetY -= vpx(10) }
            StepBtn { label: "−";  onClicked: panelsList.libSquareOffsetY -= vpx(2) }
            StyledText { text: Math.round(panelsList.libSquareOffsetY) + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(38); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "+";  onClicked: panelsList.libSquareOffsetY += vpx(2) }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libSquareOffsetY += vpx(10) }
            Rectangle {
              height: vpx(16); radius: vpx(3); width: libRstSqYLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
              color: libRstSqYMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: libRstSqYLbl; anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: libRstSqYMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libSquareOffsetY = 0 }
            }
          }

        }

        // ── Vertical divider ──────────────────────────────────────
        Rectangle {
          width: vpx(1); height: vpx(120)
          color: Qt.rgba(1,1,1,0.12)
          anchors.verticalCenter: undefined
        }

        // ══ COL 2: Tab Title Text ═════════════════════════════════
        Column {
          spacing: vpx(5)

          // Title row with Reset All + Enabled toggle
          Row {
            spacing: vpx(6)
            StyledText {
              text: "Tab Title Text"
              font.pixelSize: vpx(8); font.bold: true; color: "#44aaff"
              anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
              height: vpx(14); radius: vpx(3); width: libRstAllLbl.implicitWidth + vpx(8); anchors.verticalCenter: parent.verticalCenter
              color: libRstAllMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: libRstAllLbl; anchors.centerIn: parent; text: "Reset All"; font.pixelSize: vpx(7); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: libRstAllMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { panelsList.libTitleVisible = true; panelsList.libTitleSize = 27; panelsList.libTitleOffsetX = 0; panelsList.libTitleOffsetY = 0; panelsList.libTitleColorMode = 0; panelsList.libTitleEnabled = true; }
              }
            }
            Rectangle {
              height: vpx(14); radius: vpx(3); width: libTitleEnLbl.implicitWidth + vpx(8); anchors.verticalCenter: parent.verticalCenter
              color: panelsList.libTitleEnabled ? Qt.rgba(0.1,0.6,0.2,0.35) : Qt.rgba(0.5,0.1,0.1,0.35)
              border.width: vpx(1); border.color: panelsList.libTitleEnabled ? "#44cc66" : "#cc4444"
              StyledText { id: libTitleEnLbl; anchors.centerIn: parent
                text: panelsList.libTitleEnabled ? "Enabled" : "Disabled"
                font.pixelSize: vpx(7); font.bold: true
                color: panelsList.libTitleEnabled ? "#88ffaa" : "#ff8888" }
              MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: panelsList.libTitleEnabled = !panelsList.libTitleEnabled }
            }
          }

          // Visible + Size
          Row {
            spacing: vpx(6)
            Pill {
              label: panelsList.libTitleVisible ? "Visible: ON" : "Visible: OFF"
              on: panelsList.libTitleVisible; onCol: "#44aaff"
              onToggled: panelsList.libTitleVisible = !panelsList.libTitleVisible
            }
            Row {
              spacing: vpx(3); anchors.verticalCenter: parent.verticalCenter
              StyledText { text: "Size"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(22); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libTitleSize = Math.max(8,  panelsList.libTitleSize - 4) }
              StepBtn { label: "−";  onClicked: panelsList.libTitleSize = Math.max(8,  panelsList.libTitleSize - 1) }
              StyledText { text: panelsList.libTitleSize + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(32); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "+";  onClicked: panelsList.libTitleSize = Math.min(64, panelsList.libTitleSize + 1) }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libTitleSize = Math.min(64, panelsList.libTitleSize + 4) }
            }
          }

          // Y Offset
          Row {
            spacing: vpx(3)
            StyledText { text: "Y Offset"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(38); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libTitleOffsetY -= vpx(10) }
            StepBtn { label: "−";  onClicked: panelsList.libTitleOffsetY -= vpx(2) }
            StyledText { text: Math.round(panelsList.libTitleOffsetY) + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(38); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "+";  onClicked: panelsList.libTitleOffsetY += vpx(2) }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libTitleOffsetY += vpx(10) }
            Rectangle {
              height: vpx(16); radius: vpx(3); width: libRstYLbl.implicitWidth + vpx(8); anchors.verticalCenter: parent.verticalCenter
              color: libRstYMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: libRstYLbl; anchors.centerIn: parent; text: "Reset Y"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: libRstYMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libTitleOffsetY = 0 }
            }
          }

          // X Offset
          Row {
            spacing: vpx(3)
            StyledText { text: "X Offset"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(38); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libTitleOffsetX -= vpx(10) }
            StepBtn { label: "−";  onClicked: panelsList.libTitleOffsetX -= vpx(2) }
            StyledText { text: Math.round(panelsList.libTitleOffsetX) + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(38); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "+";  onClicked: panelsList.libTitleOffsetX += vpx(2) }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libTitleOffsetX += vpx(10) }
            Rectangle {
              height: vpx(16); radius: vpx(3); width: libRstXLbl.implicitWidth + vpx(8); anchors.verticalCenter: parent.verticalCenter
              color: libRstXMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: libRstXLbl; anchors.centerIn: parent; text: "Reset X"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: libRstXMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libTitleOffsetX = 0 }
            }
          }

          // Color
          Row {
            spacing: vpx(4)
            StyledText { text: "Color"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(28); anchors.verticalCenter: parent.verticalCenter }
            Repeater {
              model: ["White", "Accent", "Black"]
              delegate: Rectangle {
                height: vpx(16); radius: vpx(3); width: libColLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
                color: panelsList.libTitleColorMode === index ? Qt.rgba(0.27,0.67,1.0,0.50) : (libColMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.07))
                border.width: vpx(1); border.color: panelsList.libTitleColorMode === index ? Qt.rgba(0.4,0.75,1.0,0.80) : Qt.rgba(1,1,1,0.18)
                StyledText { id: libColLbl; anchors.centerIn: parent; text: modelData; font.pixelSize: vpx(8); color: "#ffffff" }
                MouseArea { id: libColMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libTitleColorMode = index }
              }
            }
          }
        }

        // ── Vertical divider ──────────────────────────────────────
        Rectangle {
          width: vpx(1); height: vpx(120)
          color: Qt.rgba(1,1,1,0.12)
          anchors.verticalCenter: undefined
        }

        // ══ COL 3: Channel Names ══════════════════════════════════
        Column {
          spacing: vpx(4)

          // Title row with Reset All + Enabled toggle + Debug
          Row {
            spacing: vpx(6)
            StyledText {
              text: "Channel Names"
              font.pixelSize: vpx(8); font.bold: true; color: "#44aaff"
              anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
              height: vpx(14); radius: vpx(3); width: libRstChanLbl.implicitWidth + vpx(8); anchors.verticalCenter: parent.verticalCenter
              color: libRstChanMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: libRstChanLbl; anchors.centerIn: parent; text: "Reset All"; font.pixelSize: vpx(7); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: libRstChanMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  panelsList.libChanVisible    = true;
                  panelsList.libChanSize       = 41;
                  panelsList.libChanBold       = true;
                  panelsList.libChanOffsetX    = 0;
                  panelsList.libChanOffsetY    = 0;
                  panelsList.libChanListX      = 0;
                  panelsList.libChanListY      = 0;
                  panelsList.libChanColorMode  = 0;
                  panelsList.libChanPathCount  = 5;
                  panelsList.libChanMode       = 0;
                  panelsList.libChanScaleOrigin = 1;
                  panelsList.libChanTextOrigin  = 0;
                  panelsList.libChanEnabled    = true;
                  panelsList.libChanDebug      = false;
                  panelsList.libItemBorder     = false;
                  panelsList.libTitleBorder    = false;
                  panelsList.libPathStartX     = 0;
                  panelsList.libPathStartY     = 0;
                  panelsList.libPathEndX       = 0;
                  panelsList.libPathEndY       = 0;
                }
              }
            }
            // Enabled / Disabled toggle
            Rectangle {
              height: vpx(14); radius: vpx(3); width: libChanEnLbl.implicitWidth + vpx(8); anchors.verticalCenter: parent.verticalCenter
              color: panelsList.libChanEnabled ? Qt.rgba(0.1,0.6,0.2,0.35) : Qt.rgba(0.5,0.1,0.1,0.35)
              border.width: vpx(1); border.color: panelsList.libChanEnabled ? "#44cc66" : "#cc4444"
              StyledText { id: libChanEnLbl; anchors.centerIn: parent
                text: panelsList.libChanEnabled ? "Enabled" : "Disabled"
                font.pixelSize: vpx(7); font.bold: true
                color: panelsList.libChanEnabled ? "#88ffaa" : "#ff8888" }
              MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: panelsList.libChanEnabled = !panelsList.libChanEnabled }
            }

          }

          // Row 1: Visible + Bold + mode pills
          Row {
            spacing: vpx(5)
            Pill {
              label: panelsList.libChanVisible ? "Visible: ON" : "Visible: OFF"
              on: panelsList.libChanVisible; onCol: "#44aaff"
              onToggled: panelsList.libChanVisible = !panelsList.libChanVisible
            }
            Pill {
              label: panelsList.libChanBold ? "Bold: ON" : "Bold: OFF"
              on: panelsList.libChanBold; onCol: "#88ccff"
              onToggled: panelsList.libChanBold = !panelsList.libChanBold
            }
            // Default / Vertical / Horizontal mode — mutually exclusive
            Pill {
              label: "Default"
              on: panelsList.libChanMode === 0; onCol: "#ffaa33"
              onToggled: panelsList.libChanMode = 0
            }
            Pill {
              label: "Vertical"
              on: panelsList.libChanMode === 1; onCol: "#ffaa33"
              onToggled: panelsList.libChanMode = 1
            }
            Pill {
              label: "Horizontal"
              on: panelsList.libChanMode === 2; onCol: "#ffaa33"
              onToggled: panelsList.libChanMode = 2
            }
          }

          // Row 2: Item Border + Title Border + Chan Origin
          Row {
            spacing: vpx(5)
            Pill {
              label: panelsList.libItemBorder ? "Item Border: ON" : "Item Border: OFF"
              on: panelsList.libItemBorder; onCol: safeAccent
              onToggled: panelsList.libItemBorder = !panelsList.libItemBorder
            }
            Pill {
              label: panelsList.libTitleBorder ? "Title Border: ON" : "Title Border: OFF"
              on: panelsList.libTitleBorder; onCol: safeAccent
              onToggled: panelsList.libTitleBorder = !panelsList.libTitleBorder
            }
            Rectangle { width: vpx(1); height: vpx(16); color: Qt.rgba(1,1,1,0.18); anchors.verticalCenter: parent.verticalCenter }
            StyledText { text: "Chan Origin:"; font.pixelSize: vpx(9); color: panelsList.edTextColor; anchors.verticalCenter: parent.verticalCenter }
            Repeater {
              model: [{ label: "◄ Left", val: 0 }, { label: "● Center", val: 1 }, { label: "Right ►", val: 2 }]
              delegate: Rectangle {
                property bool sel: panelsList.libChanTextOrigin === modelData.val
                height: vpx(16); radius: vpx(3); width: chanOrigLbl.implicitWidth + vpx(10)
                anchors.verticalCenter: parent.verticalCenter
                color: sel ? Qt.rgba(0.27,0.67,1.0,0.35) : (chanOrigMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.07))
                border.width: vpx(1); border.color: sel ? "#44aaff" : Qt.rgba(1,1,1,0.18)
                StyledText { id: chanOrigLbl; anchors.centerIn: parent; text: modelData.label; font.pixelSize: vpx(8); font.bold: sel; color: "#ffffff" }
                MouseArea { id: chanOrigMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: panelsList.libChanTextOrigin = modelData.val }
              }
            }
          }

          // Row 3: Size + Path Items + Color
          Row {
            spacing: vpx(6)
            Row {
              spacing: vpx(3); anchors.verticalCenter: parent.verticalCenter
              StyledText { text: "Size"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(22); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libChanSize = Math.max(8,  panelsList.libChanSize - 4) }
              StepBtn { label: "−";  onClicked: panelsList.libChanSize = Math.max(8,  panelsList.libChanSize - 1) }
              StyledText { text: panelsList.libChanSize + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(32); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "+";  onClicked: panelsList.libChanSize = Math.min(80, panelsList.libChanSize + 1) }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libChanSize = Math.min(80, panelsList.libChanSize + 4) }
            }
            Row {
              spacing: vpx(3); anchors.verticalCenter: parent.verticalCenter
              StyledText { text: "Path Items"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(40); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−"; onClicked: panelsList.libChanPathCount = Math.max(1, panelsList.libChanPathCount - 1) }
              StyledText { text: panelsList.libChanPathCount; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(20); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "+"; onClicked: panelsList.libChanPathCount = Math.min(20, panelsList.libChanPathCount + 1) }
            }
            Row {
              spacing: vpx(4); anchors.verticalCenter: parent.verticalCenter
              StyledText { text: "Color"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(28); anchors.verticalCenter: parent.verticalCenter }
              Repeater {
                model: ["White", "Accent", "Black"]
                delegate: Rectangle {
                  height: vpx(16); radius: vpx(3); width: libChanColLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
                  color: panelsList.libChanColorMode === index ? Qt.rgba(0.27,0.67,1.0,0.50) : (libChanColMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.07))
                  border.width: vpx(1); border.color: panelsList.libChanColorMode === index ? Qt.rgba(0.4,0.75,1.0,0.80) : Qt.rgba(1,1,1,0.18)
                  StyledText { id: libChanColLbl; anchors.centerIn: parent; text: modelData; font.pixelSize: vpx(8); color: "#ffffff" }
                  MouseArea { id: libChanColMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libChanColorMode = index }
                }
              }
            }
          }

          // Row 4: PathView X + PathView Y (moves entire container)
          Row {
            spacing: vpx(10)
            Row {
              spacing: vpx(3)
              StyledText { text: "PathView X"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(52); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libChanListX -= vpx(10) }
              StepBtn { label: "−";  onClicked: panelsList.libChanListX -= vpx(2) }
              StyledText { text: Math.round(panelsList.libChanListX) + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(38); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "+";  onClicked: panelsList.libChanListX += vpx(2) }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libChanListX += vpx(10) }
              Rectangle {
                height: vpx(16); radius: vpx(3); width: libRstLXLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
                color: libRstLXMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
                border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
                StyledText { id: libRstLXLbl; anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
                MouseArea { id: libRstLXMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libChanListX = 0 }
              }
            }
            Row {
              spacing: vpx(3)
              StyledText { text: "PathView Y"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(52); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libChanOffsetY -= vpx(10) }
              StepBtn { label: "−";  onClicked: panelsList.libChanOffsetY -= vpx(2) }
              StyledText { text: Math.round(panelsList.libChanOffsetY) + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(38); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "+";  onClicked: panelsList.libChanOffsetY += vpx(2) }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libChanOffsetY += vpx(10) }
              Rectangle {
                height: vpx(16); radius: vpx(3); width: libRstLYLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
                color: libRstLYMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
                border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
                StyledText { id: libRstLYLbl; anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
                MouseArea { id: libRstLYMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libChanOffsetY = 0 }
              }
            }
          }

          // Row 5: Item X + Item Y (per-item nudge relative to list)
          Row {
            spacing: vpx(10)
            Row {
              spacing: vpx(3)
              StyledText { text: "Item X"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(28); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libChanOffsetX -= vpx(10) }
              StepBtn { label: "−";  onClicked: panelsList.libChanOffsetX -= vpx(2) }
              StyledText { text: Math.round(panelsList.libChanOffsetX) + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(38); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "+";  onClicked: panelsList.libChanOffsetX += vpx(2) }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libChanOffsetX += vpx(10) }
              Rectangle {
                height: vpx(16); radius: vpx(3); width: libRstCXLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
                color: libRstCXMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
                border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
                StyledText { id: libRstCXLbl; anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
                MouseArea { id: libRstCXMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libChanOffsetX = 0 }
              }
            }
            Row {
              spacing: vpx(3)
              StyledText { text: "Item Y"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(28); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libChanListY -= vpx(10) }
              StepBtn { label: "−";  onClicked: panelsList.libChanListY -= vpx(2) }
              StyledText { text: Math.round(panelsList.libChanListY) + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(38); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "+";  onClicked: panelsList.libChanListY += vpx(2) }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libChanListY += vpx(10) }
              Rectangle {
                height: vpx(16); radius: vpx(3); width: libRstCYLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
                color: libRstCYMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
                border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
                StyledText { id: libRstCYLbl; anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
                MouseArea { id: libRstCYMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libChanListY = 0 }
              }
            }
          }

        }

        // ── Vertical divider ──────────────────────────────────────
        Rectangle {
          width: vpx(1); height: vpx(120)
          color: Qt.rgba(1,1,1,0.12)
          anchors.verticalCenter: undefined
        }

        // ══ COL 4: Path Start / End ═══════════════════════════════
        Column {
          spacing: vpx(4)

          // Title row with Reset All
          Row {
            spacing: vpx(6)
            StyledText {
              text: "Path Start / End"
              font.pixelSize: vpx(8); font.bold: true; color: "#44aaff"
              anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
              height: vpx(14); radius: vpx(3); width: libRstPathAllLbl.implicitWidth + vpx(8); anchors.verticalCenter: parent.verticalCenter
              color: libRstPathAllMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: libRstPathAllLbl; anchors.centerIn: parent; text: "Reset All"; font.pixelSize: vpx(7); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: libRstPathAllMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  panelsList.libPathStartX = 0; panelsList.libPathStartY = 0;
                  panelsList.libPathEndX   = 0; panelsList.libPathEndY   = 0;
                  panelsList.libPathEnabled = true; panelsList.libChanScaleOrigin = 1;
                }
              }
            }
            Rectangle {
              height: vpx(14); radius: vpx(3); width: libPathEnLbl.implicitWidth + vpx(8); anchors.verticalCenter: parent.verticalCenter
              color: panelsList.libPathEnabled ? Qt.rgba(0.1,0.6,0.2,0.35) : Qt.rgba(0.5,0.1,0.1,0.35)
              border.width: vpx(1); border.color: panelsList.libPathEnabled ? "#44cc66" : "#cc4444"
              StyledText { id: libPathEnLbl; anchors.centerIn: parent
                text: panelsList.libPathEnabled ? "Enabled" : "Disabled"
                font.pixelSize: vpx(7); font.bold: true
                color: panelsList.libPathEnabled ? "#88ffaa" : "#ff8888" }
              MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: panelsList.libPathEnabled = !panelsList.libPathEnabled }
            }
          }

          Row {
            spacing: vpx(3)
            StyledText { text: "Path SX"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(38); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libPathStartX -= vpx(10) }
            StepBtn { label: "−";  onClicked: panelsList.libPathStartX -= vpx(2) }
            StyledText { text: Math.round(panelsList.libPathStartX) + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(38); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "+";  onClicked: panelsList.libPathStartX += vpx(2) }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libPathStartX += vpx(10) }
            Rectangle {
              height: vpx(16); radius: vpx(3); width: libRstPSXLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
              color: libRstPSXMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: libRstPSXLbl; anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: libRstPSXMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libPathStartX = 0 }
            }
          }
          Row {
            spacing: vpx(3)
            StyledText { text: "Path SY"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(38); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libPathStartY -= vpx(10) }
            StepBtn { label: "−";  onClicked: panelsList.libPathStartY -= vpx(2) }
            StyledText { text: Math.round(panelsList.libPathStartY) + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(38); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "+";  onClicked: panelsList.libPathStartY += vpx(2) }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libPathStartY += vpx(10) }
            Rectangle {
              height: vpx(16); radius: vpx(3); width: libRstPSYLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
              color: libRstPSYMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: libRstPSYLbl; anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: libRstPSYMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libPathStartY = 0 }
            }
          }
          Row {
            spacing: vpx(3)
            StyledText { text: "Path EX"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(38); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libPathEndX -= vpx(10) }
            StepBtn { label: "−";  onClicked: panelsList.libPathEndX -= vpx(2) }
            StyledText { text: Math.round(panelsList.libPathEndX) + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(38); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "+";  onClicked: panelsList.libPathEndX += vpx(2) }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libPathEndX += vpx(10) }
            Rectangle {
              height: vpx(16); radius: vpx(3); width: libRstPEXLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
              color: libRstPEXMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: libRstPEXLbl; anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: libRstPEXMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libPathEndX = 0 }
            }
          }
          Row {
            spacing: vpx(3)
            StyledText { text: "Path EY"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(38); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libPathEndY -= vpx(10) }
            StepBtn { label: "−";  onClicked: panelsList.libPathEndY -= vpx(2) }
            StyledText { text: Math.round(panelsList.libPathEndY) + " px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor; width: vpx(38); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "+";  onClicked: panelsList.libPathEndY += vpx(2) }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.libPathEndY += vpx(10) }
            Rectangle {
              height: vpx(16); radius: vpx(3); width: libRstPEYLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
              color: libRstPEYMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: libRstPEYLbl; anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: libRstPEYMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.libPathEndY = 0 }
            }
          }

          // Path Items Origin row
          Row {
            spacing: vpx(6)
            StyledText { text: "Path Items Origin:"; font.pixelSize: vpx(9); color: panelsList.edTextColor; anchors.verticalCenter: parent.verticalCenter }
            Repeater {
              model: [{ label: "◄ Left", val: 1 }, { label: "● Center", val: 0 }, { label: "Right ►", val: 2 }]
              delegate: Rectangle {
                property bool sel: panelsList.libChanScaleOrigin === modelData.val
                height: vpx(16); radius: vpx(3); width: pathOrigLbl.implicitWidth + vpx(10)
                anchors.verticalCenter: parent.verticalCenter
                color: sel ? Qt.rgba(1.0, 0.53, 0.27, 0.35) : (pathOrigMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.07))
                border.width: vpx(1); border.color: sel ? "#ff8844" : Qt.rgba(1,1,1,0.18)
                StyledText { id: pathOrigLbl; anchors.centerIn: parent; text: modelData.label; font.pixelSize: vpx(8); font.bold: sel; color: "#ffffff" }
                MouseArea { id: pathOrigMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: panelsList.libChanScaleOrigin = modelData.val }
              }
            }
          }
        }

      }
    }
    Rectangle {
      id: expPage
      visible: panelsList.edExpOpen
      anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
      color: "transparent"

      Rectangle {
        anchors.fill: parent; radius: vpx(2)
        color: {
          if (panelsList.edBgMode === 1) return Qt.rgba(0, 0, 0, 0.99);
          if (panelsList.edBgMode === 2) return Qt.rgba(0.04, 0.04, 0.06, 0.60);
          if (panelsList.edBgMode === 3) return "transparent";
          if (panelsList.edBgMode === 4) return Qt.rgba(1, 1, 1, 0.97);
          if (panelsList.edBgMode === 5) return Qt.rgba(0.55, 0.55, 0.58, 0.97);
          return Qt.rgba(0.04, 0.01, 0.08, 0.80);
        }
      }

      // ── Shared slider component (compact, fits 160px columns) ──
      component SliderRow: Item {
        id: slRoot
        property string label:    ""
        property real   value:    0
        property real   minVal:  -180
        property real   maxVal:   180
        property real   stepSm:   1
        property real   stepLg:   10
        signal edited(real v)
        width: parent ? parent.width : vpx(150); height: vpx(20)

        Row {
          anchors.fill: parent; spacing: vpx(3)
          // Step − button
          Rectangle {
            height: vpx(16); width: vpx(16); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
            color: slMinus.containsMouse ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.10)
            border.color: Qt.rgba(1,1,1,0.20); border.width: vpx(1)
            StyledText { anchors.centerIn: parent; text: "−"; font.pixelSize: vpx(9); color: "#ffffff" }
            MouseArea { id: slMinus; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: slRoot.edited(Math.max(slRoot.minVal, slRoot.value - slRoot.stepSm)) }
          }
          // Slider track
          Item {
            id: slTrack; width: vpx(58); height: vpx(12); anchors.verticalCenter: parent.verticalCenter
            Rectangle {
              anchors.fill: parent; radius: vpx(6)
              color: Qt.rgba(1,1,1,0.10); border.color: Qt.rgba(1,1,1,0.22); border.width: vpx(1)
            }
            // Fill bar
            Rectangle {
              x: slRoot.value >= 0
                   ? slTrack.width / 2
                   : slTrack.width / 2 + (slRoot.value / (slRoot.maxVal - slRoot.minVal)) * slTrack.width
              width: Math.abs(slRoot.value) / (slRoot.maxVal - slRoot.minVal) * slTrack.width
              anchors.top: parent.top; anchors.bottom: parent.bottom; radius: vpx(6)
              color: "#cc55ff"; opacity: 0.75
            }
            // Thumb
            Rectangle {
              x: ((slRoot.value - slRoot.minVal) / (slRoot.maxVal - slRoot.minVal)) * (slTrack.width - vpx(10))
              anchors.verticalCenter: parent.verticalCenter
              width: vpx(10); height: vpx(10); radius: vpx(5)
              color: "#cc55ff"
            }
            // Zero line
            Rectangle {
              x: (-slRoot.minVal / (slRoot.maxVal - slRoot.minVal)) * slTrack.width - vpx(1)
              width: vpx(2); height: parent.height; color: Qt.rgba(1,1,1,0.35)
            }
            MouseArea {
              anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.SizeHorCursor
              onPositionChanged: {
                if (pressed) {
                  var t = Math.max(0, Math.min(1, mouseX / slTrack.width));
                  var v = slRoot.minVal + t * (slRoot.maxVal - slRoot.minVal);
                  v = Math.round(v / slRoot.stepSm) * slRoot.stepSm;
                  slRoot.edited(v);
                }
              }
              onClicked: {
                var t = Math.max(0, Math.min(1, mouseX / slTrack.width));
                var v = slRoot.minVal + t * (slRoot.maxVal - slRoot.minVal);
                v = Math.round(v / slRoot.stepSm) * slRoot.stepSm;
                slRoot.edited(v);
              }
            }
          }
          // Step + button
          Rectangle {
            height: vpx(16); width: vpx(16); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
            color: slPlus.containsMouse ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.10)
            border.color: Qt.rgba(1,1,1,0.20); border.width: vpx(1)
            StyledText { anchors.centerIn: parent; text: "+"; font.pixelSize: vpx(9); color: "#ffffff" }
            MouseArea { id: slPlus; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: slRoot.edited(Math.min(slRoot.maxVal, slRoot.value + slRoot.stepSm)) }
          }
          // Value readout
          StyledText {
            text: slRoot.value.toFixed(0) + "°"
            font.pixelSize: vpx(8); font.bold: true; color: panelsList.edTextColor
            width: vpx(28); horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
          }
          // Reset to 0
          Rectangle {
            height: vpx(14); radius: vpx(3); width: vpx(14); anchors.verticalCenter: parent.verticalCenter
            color: slRst.containsMouse ? Qt.rgba(1,1,1,0.20) : Qt.rgba(1,1,1,0.07)
            border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.20)
            StyledText { anchors.centerIn: parent; text: "0"; font.pixelSize: vpx(7); font.bold: true; color: "#ffffff" }
            MouseArea { id: slRst; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: slRoot.edited(0) }
          }
        }
      }

      // ── Fixed content ────────────────────────────────────────────
      Item {
        id: expPageItem
        anchors { fill: parent; topMargin: vpx(2); bottomMargin: vpx(2); leftMargin: vpx(4); rightMargin: vpx(4) }

        readonly property color _dpLeftBtnCol:  panelsList.edDpadMode === 1 ? Qt.rgba(0.35,0.05,0.50,0.35) : Qt.rgba(0.35,0.05,0.05,0.35)
        readonly property color _dpLeftBtnHov:  panelsList.edDpadMode === 1 ? Qt.rgba(0.55,0.10,0.75,0.55) : Qt.rgba(0.60,0.10,0.10,0.55)
        readonly property color _dpLeftBorder:  panelsList.edDpadMode === 1 ? "#bb55ff" : "#ff5555"
        readonly property color _dpLeftLbl:     panelsList.edDpadMode === 1 ? "#cc88ff" : "#ff8888"
        readonly property color _dpCtrBtnCol:   panelsList.edDpadMode === 1 ? Qt.rgba(0.40,0.20,0.05,0.35) : Qt.rgba(0.10,0.30,0.05,0.35)
        readonly property color _dpCtrBtnHov:   panelsList.edDpadMode === 1 ? Qt.rgba(0.60,0.35,0.08,0.55) : Qt.rgba(0.15,0.50,0.08,0.55)
        readonly property color _dpCtrBorder:   panelsList.edDpadMode === 1 ? "#ffaa33" : "#55dd44"
        readonly property color _dpCtrLbl:      panelsList.edDpadMode === 1 ? "#ffcc77" : "#88ee66"
        readonly property color _dpRgtBtnCol:   panelsList.edDpadMode === 1 ? Qt.rgba(0.40,0.05,0.25,0.35) : Qt.rgba(0.05,0.10,0.40,0.35)
        readonly property color _dpRgtBtnHov:   panelsList.edDpadMode === 1 ? Qt.rgba(0.60,0.10,0.40,0.55) : Qt.rgba(0.08,0.15,0.65,0.55)
        readonly property color _dpRgtBorder:   panelsList.edDpadMode === 1 ? "#ff55bb" : "#5588ff"
        readonly property color _dpRgtLbl:      panelsList.edDpadMode === 1 ? "#ff99cc" : "#88aaff"

        // ── LEFT column ───────────────────────────────────────────
        Column {
          id: leftRotCol
          width: vpx(155); spacing: vpx(1)
          anchors { left: parent.left; top: parent.top; topMargin: vpx(7) }
          Row { spacing: vpx(3); height: vpx(18)
            StyledText { text: "◄ Rot Near"; font.pixelSize: vpx(8); color: "#88aaff"; width: vpx(58); anchors.verticalCenter: parent.verticalCenter }
            SliderRow { value: panelsList.edLeftRotStart; width: vpx(94); minVal: -180; maxVal: 180; stepSm: 1; stepLg: 10; onEdited: function(v) { panelsList.edLeftRotStart = v } }
          }
          Row { spacing: vpx(3); height: vpx(18)
            StyledText { text: "◄ Rot Far"; font.pixelSize: vpx(8); color: "#88aaff"; width: vpx(58); anchors.verticalCenter: parent.verticalCenter }
            SliderRow { value: panelsList.edLeftRotEnd; width: vpx(94); minVal: -180; maxVal: 180; stepSm: 1; stepLg: 10; onEdited: function(v) { panelsList.edLeftRotEnd = v } }
          }
          Row { spacing: vpx(3); height: vpx(18)
            StyledText { text: "↻ Center Rot"; font.pixelSize: vpx(8); color: "#cc55ff"; width: vpx(58); anchors.verticalCenter: parent.verticalCenter }
            SliderRow { value: panelsList.edCenterRotation; width: vpx(94); minVal: -180; maxVal: 180; stepSm: 1; stepLg: 10; onEdited: function(v) { panelsList.edCenterRotation = v } }
          }
          Row { spacing: vpx(3); height: vpx(18)
            StyledText { text: "↻ Rot Bias"; font.pixelSize: vpx(8); color: "#aa44dd"; width: vpx(58); anchors.verticalCenter: parent.verticalCenter }
            SliderRow { value: panelsList.edRotationBias; width: vpx(94); minVal: -180; maxVal: 180; stepSm: 1; stepLg: 10; onEdited: function(v) { panelsList.edRotationBias = v } }
          }
        }

        // ── D-pads — centered ─────────────────────────────────────
        Row {
          id: expDpadRow; spacing: vpx(4)
          anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: vpx(2) }

            // ── LEFT END (outer tab slot −7) ──────────────────────
            Column {
              spacing: vpx(0)
              Row {
                spacing: vpx(4); anchors.horizontalCenter: parent.horizontalCenter; height: vpx(14)
                StyledText { text: "outer (−7)"; font.pixelSize: vpx(7); color: expPageItem._dpLeftLbl; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                  width: vpx(44); height: vpx(14); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                  color: rstMa0.containsMouse ? Qt.rgba(0.6,0.08,0.08,0.55) : Qt.rgba(0.35,0.05,0.05,0.35)
                  border.width: vpx(1); border.color: rstMa0.containsMouse ? "#ff7777" : "#ff4444"
                  StyledText { anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(7); color: Qt.rgba(1,0.6,0.6,0.85) }
                  MouseArea { id: rstMa0; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { panelsList.edLeftYEnd=0; panelsList.edLeftCorrectX=0; } }
                }
              }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpEU.containsMouse ? expPageItem._dpLeftBtnHov : expPageItem._dpLeftBtnCol; border.color: expPageItem._dpLeftBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▲"; font.pixelSize: vpx(14); color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpEU; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftYEnd -= vpx(5) } } }
              Row { spacing: vpx(2)
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpEL.containsMouse ? expPageItem._dpLeftBtnHov : expPageItem._dpLeftBtnCol; border.color: expPageItem._dpLeftBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "◄"; font.pixelSize: vpx(14); color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpEL; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftCorrectX -= vpx(5) } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpEC.containsMouse ? expPageItem._dpLeftBtnHov : Qt.rgba(0.3,0.05,0.05,0.35); border.color: lpEC.containsMouse ? expPageItem._dpLeftBorder : Qt.rgba(1,1,1,0.30); border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "◄ End"; font.pixelSize: vpx(7); font.bold: true; color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpEC; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { panelsList.edLeftYEnd=0; panelsList.edLeftCorrectX=0; } } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpERt.containsMouse ? expPageItem._dpLeftBtnHov : expPageItem._dpLeftBtnCol; border.color: expPageItem._dpLeftBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "►"; font.pixelSize: vpx(14); color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpERt; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftCorrectX += vpx(5) } } }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpED.containsMouse ? expPageItem._dpLeftBtnHov : expPageItem._dpLeftBtnCol; border.color: expPageItem._dpLeftBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▼"; font.pixelSize: vpx(14); color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpED; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftYEnd += vpx(5) } } }
            }

            // ── LEFT MID (middle tab slot −4) ─────────────────────
            Column {
              spacing: vpx(0)
              Row {
                spacing: vpx(4); anchors.horizontalCenter: parent.horizontalCenter; height: vpx(14)
                StyledText { text: "middle (−4)"; font.pixelSize: vpx(7); color: expPageItem._dpLeftLbl; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                  width: vpx(44); height: vpx(14); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                  color: rstMa1.containsMouse ? Qt.rgba(0.6,0.08,0.08,0.55) : Qt.rgba(0.35,0.05,0.05,0.35)
                  border.width: vpx(1); border.color: rstMa1.containsMouse ? "#ff7777" : "#ff4444"
                  StyledText { anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(7); color: Qt.rgba(1,0.6,0.6,0.85) }
                  MouseArea { id: rstMa1; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { panelsList.edLeftYMid=0; panelsList.edLeftCorrectX=0; panelsList.edLeftCorrectY=0; } }
                }
              }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpMU.containsMouse ? expPageItem._dpLeftBtnHov : expPageItem._dpLeftBtnCol; border.color: expPageItem._dpLeftBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▲"; font.pixelSize: vpx(14); color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpMU; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftCorrectY -= vpx(5) } } }
              Row { spacing: vpx(2)
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpML.containsMouse ? expPageItem._dpLeftBtnHov : expPageItem._dpLeftBtnCol; border.color: expPageItem._dpLeftBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "◄"; font.pixelSize: vpx(14); color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpML; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftCorrectX -= vpx(5) } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpMC.containsMouse ? expPageItem._dpLeftBtnHov : Qt.rgba(0.3,0.05,0.05,0.35); border.color: lpMC.containsMouse ? expPageItem._dpLeftBorder : Qt.rgba(1,1,1,0.30); border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "◄ Mid"; font.pixelSize: vpx(7); font.bold: true; color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpMC; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { panelsList.edLeftYMid=0; panelsList.edLeftCorrectX=0; panelsList.edLeftCorrectY=0; } } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpMR.containsMouse ? expPageItem._dpLeftBtnHov : expPageItem._dpLeftBtnCol; border.color: expPageItem._dpLeftBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "►"; font.pixelSize: vpx(14); color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpMR; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftCorrectX += vpx(5) } } }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpMD.containsMouse ? expPageItem._dpLeftBtnHov : expPageItem._dpLeftBtnCol; border.color: expPageItem._dpLeftBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▼"; font.pixelSize: vpx(14); color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpMD; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftCorrectY += vpx(5) } } }
            }

            // ── LEFT START (inner tab slot −1) ────────────────────
            Column {
              spacing: vpx(0)
              Row {
                spacing: vpx(4); anchors.horizontalCenter: parent.horizontalCenter; height: vpx(14)
                StyledText { text: "inner (−1)"; font.pixelSize: vpx(7); color: expPageItem._dpLeftLbl; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                  width: vpx(44); height: vpx(14); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                  color: rstMa2.containsMouse ? Qt.rgba(0.6,0.08,0.08,0.55) : Qt.rgba(0.35,0.05,0.05,0.35)
                  border.width: vpx(1); border.color: rstMa2.containsMouse ? "#ff7777" : "#ff4444"
                  StyledText { anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(7); color: Qt.rgba(1,0.6,0.6,0.85) }
                  MouseArea { id: rstMa2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { panelsList.edLeftYStart=0; panelsList.edLeftYEnd=0; panelsList.edLeftCorrectX=0; } }
                }
              }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpSU.containsMouse ? expPageItem._dpLeftBtnHov : expPageItem._dpLeftBtnCol; border.color: expPageItem._dpLeftBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▲"; font.pixelSize: vpx(14); color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpSU; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftYStart -= vpx(5) } } }
              Row { spacing: vpx(2)
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpSL.containsMouse ? expPageItem._dpLeftBtnHov : expPageItem._dpLeftBtnCol; border.color: expPageItem._dpLeftBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "◄"; font.pixelSize: vpx(14); color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpSL; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftCorrectX -= vpx(5) } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpSC.containsMouse ? expPageItem._dpLeftBtnHov : Qt.rgba(0.3,0.05,0.05,0.35); border.color: lpSC.containsMouse ? expPageItem._dpLeftBorder : Qt.rgba(1,1,1,0.30); border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "◄ Start"; font.pixelSize: vpx(7); font.bold: true; color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpSC; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { panelsList.edLeftYStart=0; panelsList.edLeftYEnd=0; panelsList.edLeftCorrectX=0; } } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpSR.containsMouse ? expPageItem._dpLeftBtnHov : expPageItem._dpLeftBtnCol; border.color: expPageItem._dpLeftBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "►"; font.pixelSize: vpx(14); color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpSR; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftCorrectX += vpx(5) } } }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: lpSD.containsMouse ? expPageItem._dpLeftBtnHov : expPageItem._dpLeftBtnCol; border.color: expPageItem._dpLeftBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▼"; font.pixelSize: vpx(14); color: expPageItem._dpLeftLbl }
                  MouseArea { id: lpSD; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftYStart += vpx(5) } } }
            }

            // ── DIVIDER ───────────────────────────────────────────
            // ── CENTER (panel offset) ─────────────────────────────
            Column {
              spacing: vpx(0)
              Row {
                spacing: vpx(4); anchors.horizontalCenter: parent.horizontalCenter; height: vpx(14)
                StyledText { text: "panel offset"; font.pixelSize: vpx(7); color: expPageItem._dpCtrLbl; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                  width: vpx(44); height: vpx(14); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                  color: rstMa3.containsMouse ? Qt.rgba(0.6,0.08,0.08,0.55) : Qt.rgba(0.35,0.05,0.05,0.35)
                  border.width: vpx(1); border.color: rstMa3.containsMouse ? "#ff7777" : "#ff4444"
                  StyledText { anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(7); color: Qt.rgba(1,0.6,0.6,0.85) }
                  MouseArea { id: rstMa3; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { panelsList.edCenterOffsetX=0; panelsList.edCenterOffsetY=0; } }
                }
              }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: cpU.containsMouse ? expPageItem._dpCtrBtnHov : expPageItem._dpCtrBtnCol; border.color: expPageItem._dpCtrBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▲"; font.pixelSize: vpx(14); color: expPageItem._dpCtrLbl }
                  MouseArea { id: cpU; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edCenterOffsetY -= vpx(5) } } }
              Row { spacing: vpx(2)
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: cpL.containsMouse ? expPageItem._dpCtrBtnHov : expPageItem._dpCtrBtnCol; border.color: expPageItem._dpCtrBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "◄"; font.pixelSize: vpx(14); color: expPageItem._dpCtrLbl }
                  MouseArea { id: cpL; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edCenterOffsetX -= vpx(5) } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: cpC.containsMouse ? expPageItem._dpCtrBtnHov : Qt.rgba(0.15,0.15,0.05,0.35); border.color: cpC.containsMouse ? expPageItem._dpCtrBorder : Qt.rgba(1,1,1,0.30); border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "Center"; font.pixelSize: vpx(7); font.bold: true; color: expPageItem._dpCtrLbl }
                  MouseArea { id: cpC; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { panelsList.edCenterOffsetX=0; panelsList.edCenterOffsetY=0; } } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: cpR.containsMouse ? expPageItem._dpCtrBtnHov : expPageItem._dpCtrBtnCol; border.color: expPageItem._dpCtrBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "►"; font.pixelSize: vpx(14); color: expPageItem._dpCtrLbl }
                  MouseArea { id: cpR; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edCenterOffsetX += vpx(5) } } }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: cpD.containsMouse ? expPageItem._dpCtrBtnHov : expPageItem._dpCtrBtnCol; border.color: expPageItem._dpCtrBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▼"; font.pixelSize: vpx(14); color: expPageItem._dpCtrLbl }
                  MouseArea { id: cpD; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edCenterOffsetY += vpx(5) } } }
            }

            // ── DIVIDER ───────────────────────────────────────────
            Rectangle { width: vpx(1); height: vpx(72); color: Qt.rgba(1,1,1,0.12) }

            // ── RIGHT START (inner tab slot +1) ───────────────────
            Column {
              spacing: vpx(0)
              Row {
                spacing: vpx(4); anchors.horizontalCenter: parent.horizontalCenter; height: vpx(14)
                StyledText { text: "inner (+1)"; font.pixelSize: vpx(7); color: expPageItem._dpRgtLbl; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                  width: vpx(44); height: vpx(14); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                  color: rstMa4.containsMouse ? Qt.rgba(0.6,0.08,0.08,0.55) : Qt.rgba(0.35,0.05,0.05,0.35)
                  border.width: vpx(1); border.color: rstMa4.containsMouse ? "#ff7777" : "#ff4444"
                  StyledText { anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(7); color: Qt.rgba(1,0.6,0.6,0.85) }
                  MouseArea { id: rstMa4; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { panelsList.edRightYStart=0; panelsList.edRightYEnd=0; panelsList.edRightCorrectX=0; } }
                }
              }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpSU.containsMouse ? expPageItem._dpRgtBtnHov : expPageItem._dpRgtBtnCol; border.color: expPageItem._dpRgtBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▲"; font.pixelSize: vpx(14); color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpSU; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightYStart -= vpx(5) } } }
              Row { spacing: vpx(2)
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpSL.containsMouse ? expPageItem._dpRgtBtnHov : expPageItem._dpRgtBtnCol; border.color: expPageItem._dpRgtBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "◄"; font.pixelSize: vpx(14); color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpSL; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightCorrectX -= vpx(5) } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpSC.containsMouse ? expPageItem._dpRgtBtnHov : Qt.rgba(0.05,0.05,0.30,0.35); border.color: rpSC.containsMouse ? expPageItem._dpRgtBorder : Qt.rgba(1,1,1,0.30); border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "Start ►"; font.pixelSize: vpx(7); font.bold: true; color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpSC; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { panelsList.edRightYStart=0; panelsList.edRightYEnd=0; panelsList.edRightCorrectX=0; } } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpSR.containsMouse ? expPageItem._dpRgtBtnHov : expPageItem._dpRgtBtnCol; border.color: expPageItem._dpRgtBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "►"; font.pixelSize: vpx(14); color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpSR; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightCorrectX += vpx(5) } } }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpSD.containsMouse ? expPageItem._dpRgtBtnHov : expPageItem._dpRgtBtnCol; border.color: expPageItem._dpRgtBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▼"; font.pixelSize: vpx(14); color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpSD; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightYStart += vpx(5) } } }
            }

            // ── RIGHT MID (middle tab slot +4) ────────────────────
            Column {
              spacing: vpx(0)
              Row {
                spacing: vpx(4); anchors.horizontalCenter: parent.horizontalCenter; height: vpx(14)
                StyledText { text: "middle (+4)"; font.pixelSize: vpx(7); color: expPageItem._dpRgtLbl; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                  width: vpx(44); height: vpx(14); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                  color: rstMa5.containsMouse ? Qt.rgba(0.6,0.08,0.08,0.55) : Qt.rgba(0.35,0.05,0.05,0.35)
                  border.width: vpx(1); border.color: rstMa5.containsMouse ? "#ff7777" : "#ff4444"
                  StyledText { anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(7); color: Qt.rgba(1,0.6,0.6,0.85) }
                  MouseArea { id: rstMa5; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { panelsList.edRightYMid=0; panelsList.edRightCorrectX=0; panelsList.edRightCorrectY=0; } }
                }
              }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpMU.containsMouse ? expPageItem._dpRgtBtnHov : expPageItem._dpRgtBtnCol; border.color: expPageItem._dpRgtBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▲"; font.pixelSize: vpx(14); color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpMU; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightCorrectY -= vpx(5) } } }
              Row { spacing: vpx(2)
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpML.containsMouse ? expPageItem._dpRgtBtnHov : expPageItem._dpRgtBtnCol; border.color: expPageItem._dpRgtBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "◄"; font.pixelSize: vpx(14); color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpML; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightCorrectX -= vpx(5) } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpMC.containsMouse ? expPageItem._dpRgtBtnHov : Qt.rgba(0.05,0.05,0.30,0.35); border.color: rpMC.containsMouse ? expPageItem._dpRgtBorder : Qt.rgba(1,1,1,0.30); border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "Mid ►"; font.pixelSize: vpx(7); font.bold: true; color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpMC; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { panelsList.edRightYMid=0; panelsList.edRightCorrectX=0; panelsList.edRightCorrectY=0; } } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpMR.containsMouse ? expPageItem._dpRgtBtnHov : expPageItem._dpRgtBtnCol; border.color: expPageItem._dpRgtBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "►"; font.pixelSize: vpx(14); color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpMR; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightCorrectX += vpx(5) } } }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpMD.containsMouse ? expPageItem._dpRgtBtnHov : expPageItem._dpRgtBtnCol; border.color: expPageItem._dpRgtBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▼"; font.pixelSize: vpx(14); color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpMD; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightCorrectY += vpx(5) } } }
            }

            // ── RIGHT END (outer tab slot +7) ─────────────────────
            Column {
              spacing: vpx(0)
              Row {
                spacing: vpx(4); anchors.horizontalCenter: parent.horizontalCenter; height: vpx(14)
                StyledText { text: "outer (+7)"; font.pixelSize: vpx(7); color: expPageItem._dpRgtLbl; anchors.verticalCenter: parent.verticalCenter }
                Rectangle {
                  width: vpx(44); height: vpx(14); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                  color: rstMa6.containsMouse ? Qt.rgba(0.6,0.08,0.08,0.55) : Qt.rgba(0.35,0.05,0.05,0.35)
                  border.width: vpx(1); border.color: rstMa6.containsMouse ? "#ff7777" : "#ff4444"
                  StyledText { anchors.centerIn: parent; text: "Reset"; font.pixelSize: vpx(7); color: Qt.rgba(1,0.6,0.6,0.85) }
                  MouseArea { id: rstMa6; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { panelsList.edRightYEnd=0; panelsList.edRightCorrectX=0; } }
                }
              }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpEU.containsMouse ? expPageItem._dpRgtBtnHov : expPageItem._dpRgtBtnCol; border.color: expPageItem._dpRgtBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▲"; font.pixelSize: vpx(14); color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpEU; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightYEnd -= vpx(5) } } }
              Row { spacing: vpx(2)
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpEL.containsMouse ? expPageItem._dpRgtBtnHov : expPageItem._dpRgtBtnCol; border.color: expPageItem._dpRgtBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "◄"; font.pixelSize: vpx(14); color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpEL; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightCorrectX -= vpx(5) } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpEC.containsMouse ? expPageItem._dpRgtBtnHov : Qt.rgba(0.05,0.05,0.30,0.35); border.color: rpEC.containsMouse ? expPageItem._dpRgtBorder : Qt.rgba(1,1,1,0.30); border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "End ►"; font.pixelSize: vpx(7); font.bold: true; color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpEC; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { panelsList.edRightYEnd=0; panelsList.edRightCorrectX=0; } } }
                Rectangle { width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpER.containsMouse ? expPageItem._dpRgtBtnHov : expPageItem._dpRgtBtnCol; border.color: expPageItem._dpRgtBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "►"; font.pixelSize: vpx(14); color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpER; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightCorrectX += vpx(5) } } }
              Item { width: vpx(100); height: vpx(32)
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: vpx(32); height: vpx(32); radius: vpx(5)
                  color: rpED.containsMouse ? expPageItem._dpRgtBtnHov : expPageItem._dpRgtBtnCol; border.color: expPageItem._dpRgtBorder; border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: "▼"; font.pixelSize: vpx(14); color: expPageItem._dpRgtLbl }
                  MouseArea { id: rpED; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightYEnd += vpx(5) } } }
            }

            } // end expDpadRow

        // ── Buttons below d-pads ──────────────────────────────────────
        Row {
          spacing: vpx(4)
          anchors { top: expDpadRow.bottom; topMargin: vpx(4); horizontalCenter: expDpadRow.horizontalCenter }

          Rectangle {
            width: vpx(64); height: vpx(16); radius: vpx(4)
            property bool active: panelsList.edDpadMode === 0
            color: active ? Qt.rgba(0.60,0.08,0.08,0.55) : (orthoMa.containsMouse ? Qt.rgba(0.35,0.05,0.05,0.35) : Qt.rgba(1,1,1,0.05))
            border.color: active ? "#ff5555" : (orthoMa.containsMouse ? "#ff7777" : Qt.rgba(1,1,1,0.20))
            border.width: active ? vpx(2) : vpx(1)
            anchors.verticalCenter: parent.verticalCenter
            StyledText { anchors.centerIn: parent; text: "Directional"; font.pixelSize: vpx(8); font.bold: true
              color: parent.active ? "#ffaaaa" : Qt.rgba(1,1,1,0.60) }
            MouseArea { id: orthoMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edDpadMode = 0 }
          }
          Rectangle {
            width: vpx(66); height: vpx(16); radius: vpx(4)
            property bool active: panelsList.edDpadMode === 1
            color: active ? Qt.rgba(0.40,0.08,0.55,0.55) : (rotModeMa.containsMouse ? Qt.rgba(0.25,0.05,0.35,0.35) : Qt.rgba(1,1,1,0.05))
            border.color: active ? "#cc55ff" : (rotModeMa.containsMouse ? "#bb44ee" : Qt.rgba(1,1,1,0.20))
            border.width: active ? vpx(2) : vpx(1)
            anchors.verticalCenter: parent.verticalCenter
            StyledText { anchors.centerIn: parent; text: "3D Rotation"; font.pixelSize: vpx(8); font.bold: true
              color: parent.active ? "#dd99ff" : Qt.rgba(1,1,1,0.60) }
            MouseArea { id: rotModeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edDpadMode = 1 }
          }
          Pill {
            label: panelsList.edAsymRotation ? "Side Rot: ON" : "Side Rot: OFF"
            on: panelsList.edAsymRotation; onCol: "#cc55ff"
            onToggled: panelsList.edAsymRotation = !panelsList.edAsymRotation }

          Rectangle {
            height: vpx(16); radius: vpx(3); width: tbRstRotLbl.implicitWidth + vpx(8)
            anchors.verticalCenter: parent.verticalCenter
            color: tbRstRotMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
            border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
            StyledText { id: tbRstRotLbl; anchors.centerIn: parent; text: "Reset All Rotation"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
            MouseArea { id: tbRstRotMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: { panelsList.edCenterRotation=0; panelsList.edLeftRotStart=0; panelsList.edLeftRotEnd=0; panelsList.edRightRotStart=0; panelsList.edRightRotEnd=0; } }
          }

          Rectangle {
            height: vpx(16); radius: vpx(3); width: tbRstPosLbl.implicitWidth + vpx(8)
            anchors.verticalCenter: parent.verticalCenter
            color: tbRstPosMa.containsMouse ? Qt.rgba(0.1,0.4,0.7,0.45) : Qt.rgba(1,1,1,0.07)
            border.width: vpx(1); border.color: Qt.rgba(0.2,0.5,1.0,0.30)
            StyledText { id: tbRstPosLbl; anchors.centerIn: parent; text: "Reset All Position"; font.pixelSize: vpx(8); color: Qt.rgba(0.6,0.8,1.0,0.85) }
            MouseArea { id: tbRstPosMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: { panelsList.edCenterOffsetX=0; panelsList.edCenterOffsetY=0; panelsList.edLeftCorrectX=0; panelsList.edRightCorrectX=0; } }
          }
        }

        // ── RIGHT column ──────────────────────────────────────────────
        Column {
          id: rightRotCol
          width: vpx(235); spacing: vpx(1)
          anchors { right: parent.right; top: parent.top; topMargin: vpx(2) }
          property real _yOp: panelsList.edAsymYStartEnd ? 1.0 : 0.35

          // Rot sliders — label inline to save height
          Row { spacing: vpx(3); height: vpx(18)
            StyledText { text: "► Rot Near"; font.pixelSize: vpx(8); color: "#ffbb66"; width: vpx(60); anchors.verticalCenter: parent.verticalCenter }
            SliderRow { value: panelsList.edRightRotStart; width: vpx(170); minVal: -180; maxVal: 180; stepSm: 1; stepLg: 10; onEdited: function(v) { panelsList.edRightRotStart = v } }
          }
          Row { spacing: vpx(3); height: vpx(18)
            StyledText { text: "► Rot Far"; font.pixelSize: vpx(8); color: "#ffbb66"; width: vpx(60); anchors.verticalCenter: parent.verticalCenter }
            SliderRow { value: panelsList.edRightRotEnd; width: vpx(170); minVal: -180; maxVal: 180; stepSm: 1; stepLg: 10; onEdited: function(v) { panelsList.edRightRotEnd = v } }
          }

          // Y Start/End toggle + reset
          Row { spacing: vpx(4); height: vpx(16); topPadding: vpx(1)
            Pill { label: panelsList.edAsymYStartEnd ? "Y Start/End ON" : "Y Start/End OFF"
              on: panelsList.edAsymYStartEnd; onCol: "#cc55ff"
              onToggled: panelsList.edAsymYStartEnd = !panelsList.edAsymYStartEnd }
            Rectangle {
              height: vpx(15); radius: vpx(3); width: yseRstLbl.implicitWidth + vpx(8); anchors.verticalCenter: parent.verticalCenter
              color: yseRstMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: yseRstLbl; anchors.centerIn: parent; text: "Reset Y"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: yseRstMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { panelsList.edLeftYStart=0; panelsList.edLeftYMid=0; panelsList.edLeftYEnd=0;
                             panelsList.edRightYStart=0; panelsList.edRightYMid=0; panelsList.edRightYEnd=0; } }
            }
          }

          // Y rows — all 4 compact
          Row { spacing: vpx(3); height: vpx(16); opacity: parent._yOp
            StyledText { text: "◄L Near"; font.pixelSize: vpx(8); color: "#88aaff"; width: vpx(45); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edLeftYStart -= vpx(2) } }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edLeftYStart -= vpx(10) } }
            StyledText { text: Math.round(panelsList.edLeftYStart)+"px"; font.pixelSize: vpx(8); color: panelsList.edTextColor; width: vpx(34); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edLeftYStart += vpx(10) } }
            StepBtn { label: "+";  onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edLeftYStart += vpx(2) } }
            Rectangle { height: vpx(13); radius: vpx(3); width: vpx(16); anchors.verticalCenter: parent.verticalCenter
              color: Qt.rgba(1,1,1,0.08); border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.22)
              StyledText { anchors.centerIn: parent; text: "0"; font.pixelSize: vpx(7); color: "#fff" }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftYStart = 0 } }
          }
          Row { spacing: vpx(3); height: vpx(16); opacity: parent._yOp
            StyledText { text: "◄L Far"; font.pixelSize: vpx(8); color: "#88aaff"; width: vpx(45); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edLeftYEnd -= vpx(2) } }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edLeftYEnd -= vpx(10) } }
            StyledText { text: Math.round(panelsList.edLeftYEnd)+"px"; font.pixelSize: vpx(8); color: panelsList.edTextColor; width: vpx(34); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edLeftYEnd += vpx(10) } }
            StepBtn { label: "+";  onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edLeftYEnd += vpx(2) } }
            Rectangle { height: vpx(13); radius: vpx(3); width: vpx(16); anchors.verticalCenter: parent.verticalCenter
              color: Qt.rgba(1,1,1,0.08); border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.22)
              StyledText { anchors.centerIn: parent; text: "0"; font.pixelSize: vpx(7); color: "#fff" }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edLeftYEnd = 0 } }
          }
          Row { spacing: vpx(3); height: vpx(16); opacity: parent._yOp
            StyledText { text: "►R Near"; font.pixelSize: vpx(8); color: "#ffbb66"; width: vpx(45); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edRightYStart -= vpx(2) } }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edRightYStart -= vpx(10) } }
            StyledText { text: Math.round(panelsList.edRightYStart)+"px"; font.pixelSize: vpx(8); color: panelsList.edTextColor; width: vpx(34); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edRightYStart += vpx(10) } }
            StepBtn { label: "+";  onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edRightYStart += vpx(2) } }
            Rectangle { height: vpx(13); radius: vpx(3); width: vpx(16); anchors.verticalCenter: parent.verticalCenter
              color: Qt.rgba(1,1,1,0.08); border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.22)
              StyledText { anchors.centerIn: parent; text: "0"; font.pixelSize: vpx(7); color: "#fff" }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightYStart = 0 } }
          }
          Row { spacing: vpx(3); height: vpx(16); opacity: parent._yOp
            StyledText { text: "►R Far"; font.pixelSize: vpx(8); color: "#ffbb66"; width: vpx(45); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edRightYEnd -= vpx(2) } }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edRightYEnd -= vpx(10) } }
            StyledText { text: Math.round(panelsList.edRightYEnd)+"px"; font.pixelSize: vpx(8); color: panelsList.edTextColor; width: vpx(34); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edRightYEnd += vpx(10) } }
            StepBtn { label: "+";  onClicked: { if (panelsList.edAsymYStartEnd) panelsList.edRightYEnd += vpx(2) } }
            Rectangle { height: vpx(13); radius: vpx(3); width: vpx(16); anchors.verticalCenter: parent.verticalCenter
              color: Qt.rgba(1,1,1,0.08); border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.22)
              StyledText { anchors.centerIn: parent; text: "0"; font.pixelSize: vpx(7); color: "#fff" }
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: panelsList.edRightYEnd = 0 } }
          }
        } // end rightRotCol

      } // end expPage Item
    }


    // ── Tilt page ─────────────────────────────────────────────────
    Item {
      id: tiltPage
      visible: panelsList.edTiltOpen
      anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }

      Rectangle {
        anchors.fill: parent; radius: vpx(2)
        color: {
          if (panelsList.edBgMode === 1) return Qt.rgba(0, 0, 0, 0.99);
          if (panelsList.edBgMode === 2) return Qt.rgba(0.04, 0.04, 0.06, 0.60);
          if (panelsList.edBgMode === 3) return "transparent";
          if (panelsList.edBgMode === 4) return Qt.rgba(1, 1, 1, 0.97);
          if (panelsList.edBgMode === 5) return Qt.rgba(0.55, 0.55, 0.58, 0.97);
          return Qt.rgba(0.05, 0.05, 0.08, 0.88);
        }
        opacity: panelsList.edBgMode === 3 ? 0 : 1
      }

      Item {
        anchors { fill: parent; topMargin: vpx(6); bottomMargin: vpx(4); leftMargin: vpx(10); rightMargin: vpx(10) }

        // ── LEFT col: Center / Near / Far + toggle ────────────────
        Column {
          id: tiltLeftCol
          width: vpx(210); spacing: vpx(1)
          anchors { left: parent.left; top: parent.top }

          Row { spacing: vpx(3); height: vpx(18)
            StyledText { text: "Tilt Center (0)"; font.pixelSize: vpx(8); color: "#88ffee"; width: vpx(80); anchors.verticalCenter: parent.verticalCenter }
            SliderRow { value: panelsList.edTiltCenter; width: vpx(128); minVal: -89; maxVal: 89; stepSm: 1; stepLg: 5; onEdited: function(v) { panelsList.edTiltCenter = v } }
          }
          Row { spacing: vpx(3); height: vpx(18)
            StyledText { text: "Tilt Near (±1)"; font.pixelSize: vpx(8); color: "#44ddcc"; width: vpx(80); anchors.verticalCenter: parent.verticalCenter }
            SliderRow { value: panelsList.edTiltNear; width: vpx(128); minVal: -89; maxVal: 89; stepSm: 1; stepLg: 5; onEdited: function(v) { panelsList.edTiltNear = v } }
          }
          Row { spacing: vpx(3); height: vpx(18)
            StyledText { text: "Tilt Far (±7)"; font.pixelSize: vpx(8); color: "#44ddcc"; width: vpx(80); anchors.verticalCenter: parent.verticalCenter }
            SliderRow { value: panelsList.edTiltFar; width: vpx(128); minVal: -89; maxVal: 89; stepSm: 1; stepLg: 5; onEdited: function(v) { panelsList.edTiltFar = v } }
          }

          Item { width: 1; height: vpx(6) }

          Row { spacing: vpx(6); height: vpx(18)
            Pill { label: panelsList.edAsymTilt ? "Asym Tilt: ON" : "Asym Tilt: OFF"
              on: panelsList.edAsymTilt; onCol: "#44ddcc"
              onToggled: panelsList.edAsymTilt = !panelsList.edAsymTilt }
            Rectangle {
              height: vpx(15); radius: vpx(3); width: tiltRstLbl.implicitWidth + vpx(8); anchors.verticalCenter: parent.verticalCenter
              color: tiltRstMa.containsMouse ? Qt.rgba(0.1,0.5,0.5,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(0.2,0.8,0.8,0.30)
              StyledText { id: tiltRstLbl; anchors.centerIn: parent; text: "Reset Tilt"; font.pixelSize: vpx(8); color: Qt.rgba(0.5,1.0,1.0,0.85) }
              MouseArea { id: tiltRstMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { panelsList.edTiltCenter=0; panelsList.edTiltNear=0; panelsList.edTiltFar=0;
                             panelsList.edTiltLeftNear=0; panelsList.edTiltLeftFar=0;
                             panelsList.edTiltRightNear=0; panelsList.edTiltRightFar=0; } }
            }
          }

          Item { width: 1; height: vpx(4) }

          StyledText { text: "Y-Tilt rotates panels around their vertical axis.\nNear = slot ±1  ·  Far = slot ±7  ·  Center = slot 0\nEnable Asym for independent left/right control."
            font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.38); lineHeight: 1.5; lineHeightMode: Text.ProportionalHeight; wrapMode: Text.WordWrap; width: vpx(210) }
        }

        // ── RIGHT col: Asym per-side sliders ─────────────────────
        Column {
          id: tiltRightCol
          width: vpx(210); spacing: vpx(1)
          anchors { left: tiltLeftCol.right; leftMargin: vpx(24); top: tiltLeftCol.top }
          opacity: panelsList.edAsymTilt ? 1.0 : 0.30

          StyledText { text: "Asymmetric overrides"; font.pixelSize: vpx(8); color: Qt.rgba(1,1,1,0.45); height: vpx(18) }

          Row { spacing: vpx(3); height: vpx(18)
            StyledText { text: "◄ Left Near"; font.pixelSize: vpx(8); color: "#88aaff"; width: vpx(80); anchors.verticalCenter: parent.verticalCenter }
            SliderRow { value: panelsList.edTiltLeftNear; width: vpx(128); minVal: -89; maxVal: 89; stepSm: 1; stepLg: 5; onEdited: function(v) { if (panelsList.edAsymTilt) panelsList.edTiltLeftNear = v } }
          }
          Row { spacing: vpx(3); height: vpx(18)
            StyledText { text: "◄ Left Far"; font.pixelSize: vpx(8); color: "#88aaff"; width: vpx(80); anchors.verticalCenter: parent.verticalCenter }
            SliderRow { value: panelsList.edTiltLeftFar; width: vpx(128); minVal: -89; maxVal: 89; stepSm: 1; stepLg: 5; onEdited: function(v) { if (panelsList.edAsymTilt) panelsList.edTiltLeftFar = v } }
          }
          Row { spacing: vpx(3); height: vpx(18)
            StyledText { text: "► Right Near"; font.pixelSize: vpx(8); color: "#ffbb66"; width: vpx(80); anchors.verticalCenter: parent.verticalCenter }
            SliderRow { value: panelsList.edTiltRightNear; width: vpx(128); minVal: -89; maxVal: 89; stepSm: 1; stepLg: 5; onEdited: function(v) { if (panelsList.edAsymTilt) panelsList.edTiltRightNear = v } }
          }
          Row { spacing: vpx(3); height: vpx(18)
            StyledText { text: "► Right Far"; font.pixelSize: vpx(8); color: "#ffbb66"; width: vpx(80); anchors.verticalCenter: parent.verticalCenter }
            SliderRow { value: panelsList.edTiltRightFar; width: vpx(128); minVal: -89; maxVal: 89; stepSm: 1; stepLg: 5; onEdited: function(v) { if (panelsList.edAsymTilt) panelsList.edTiltRightFar = v } }
          }
        }
      }
    }

    // ── Body (hidden when slots or move editor page is open) ──────
    Item {
      id: bodyArea
      visible: !panelsList.edSlotsOpen && !panelsList.edResetOpen && !panelsList.edMoveOpen && !panelsList.edDebugOpen && !panelsList.edExpOpen && !panelsList.edTiltOpen && !panelsList.edWrapperOpen && !panelsList.edTabsOpen && !panelsList.edLibraryOpen && !panelsList.edTemplatesOpen && !panelsList.edCustomsOpen && !panelsList.edLayersOpen
      anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
      anchors.leftMargin: panelsList.edPanelFlipped ? vpx(0) : vpx(8)
      anchors.rightMargin: panelsList.edPanelFlipped ? vpx(0) : vpx(8)
      anchors.topMargin: vpx(3); anchors.bottomMargin: vpx(3)

      // ══ Panel List + Panel Wrapper block (left when normal, right when flipped) ══
      Item {
        id: leftBlock
        anchors {
          top: parent.top; bottom: parent.bottom
          left: panelsList.edPanelFlipped ? rightBlock.right : parent.left
          leftMargin: panelsList.edPanelFlipped ? vpx(0) : vpx(0)
        }
        width: vpx(635)

        // ── COL 1: PANEL LIST MOUSE CONTROLS ─────────────────────────
        Item {
          id: col1
          anchors { top: parent.top; left: parent.left; bottom: parent.bottom }
          width: vpx(415)

          StyledText {
            id: plHdr
            text: "Panel List Mouse Controls"; font.pixelSize: vpx(8); font.bold: true
            color: panelsList.edColorMode === 1 ? "#444444" : safeAccent
            anchors { top: parent.top; left: parent.left }
          }

          // Left sub-col: Center Item
          Column {
            id: colCenter
            anchors { top: plHdr.bottom; topMargin: vpx(1); left: parent.left }
            width: vpx(200); spacing: vpx(2)

            Row { spacing: vpx(6); height: vpx(16)
              StyledText { text: "— Center Item —"; font.pixelSize: vpx(10); color: panelsList.edTextColor; anchors.verticalCenter: parent.verticalCenter }
              Rectangle {
                height: vpx(14); radius: vpx(3); width: vpx(28); anchors.verticalCenter: parent.verticalCenter
                color: sxCtrMa.containsMouse ? Qt.rgba(0.3,0.6,1.0,0.35) : Qt.rgba(1,1,1,0.08)
                border.width: vpx(1); border.color: sxCtrMa.containsMouse ? Qt.rgba(0.4,0.7,1.0,0.6) : Qt.rgba(1,1,1,0.22)
                StyledText { anchors.centerIn: parent; text: "Left"; font.pixelSize: vpx(8); font.bold: true; color: "#aaccff" }
                MouseArea { id: sxCtrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    // Left edge: vpx(10) margin, or screenOriginX when offset is active
                    var v = panelsList.edUseScreenOrigin && panelsList.screenOriginX > 0
                            ? panelsList.screenOriginX : vpx(10);
                    panelsList.edSelectedX = v; panelsList.selectedX = v;
                  } }
              }
              Rectangle {
                height: vpx(14); radius: vpx(3); width: vpx(38); anchors.verticalCenter: parent.verticalCenter
                color: sxHalfMa.containsMouse ? Qt.rgba(0.7,0.4,1.0,0.35) : Qt.rgba(1,1,1,0.08)
                border.width: vpx(1); border.color: sxHalfMa.containsMouse ? Qt.rgba(0.8,0.5,1.0,0.6) : Qt.rgba(1,1,1,0.22)
                StyledText { anchors.centerIn: parent; text: "Center"; font.pixelSize: vpx(8); font.bold: true; color: "#ddaaff" }
                MouseArea { id: sxHalfMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    // True screen center — uniSelectedX already incorporates edUseScreenOrigin
                    var v = panelsList.uniSelectedX;
                    panelsList.edSelectedX = v; panelsList.selectedX = v;
                  } }
              }
              Rectangle {
                height: vpx(14); radius: vpx(3); width: vpx(28); anchors.verticalCenter: parent.verticalCenter
                color: sx933Ma.containsMouse ? Qt.rgba(0.3,0.8,0.3,0.35) : Qt.rgba(1,1,1,0.08)
                border.width: vpx(1); border.color: sx933Ma.containsMouse ? Qt.rgba(0.4,1.0,0.4,0.6) : Qt.rgba(1,1,1,0.22)
                StyledText { anchors.centerIn: parent; text: "Right"; font.pixelSize: vpx(8); font.bold: true; color: "#aaffaa" }
                MouseArea { id: sx933Ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    // Right edge: mirror of Left around screen center
                    var leftVal = panelsList.edUseScreenOrigin && panelsList.screenOriginX > 0
                                  ? panelsList.screenOriginX : vpx(10);
                    var v = panelsList.singleScreenWidth - panelsList.panelWidth - leftVal;
                    panelsList.edSelectedX = v; panelsList.selectedX = v;
                  } }
              }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Selected X"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(61); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−";  onClicked: panelsList.edSelectedX -= vpx(5) }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edSelectedX -= vpx(20) }
              StyledText { text: Math.round(panelsList.edSelectedX)+"px"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edSelectedX += vpx(20) }
              StepBtn { label: "+";  onClicked: panelsList.edSelectedX += vpx(5) }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Selected Y"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(61); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−";  onClicked: panelsList.edSelectedY -= vpx(2) }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edSelectedY -= vpx(10) }
              StyledText { text: Math.round(panelsList.edSelectedY)+"px"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edSelectedY += vpx(10) }
              StepBtn { label: "+";  onClicked: panelsList.edSelectedY += vpx(2) }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Y Layout"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(61); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−";  onClicked: panelsList.edViewOffsetY -= vpx(2) }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edViewOffsetY -= vpx(10) }
              StyledText { text: Math.round(panelsList.edViewOffsetY)+"px"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edViewOffsetY += vpx(10) }
              StepBtn { label: "+";  onClicked: panelsList.edViewOffsetY += vpx(2) }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Center Scale"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(61); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−";  onClicked: panelsList.edCenterScale = Math.max(0.05, panelsList.edCenterScale - 0.01) }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edCenterScale = Math.max(0.05, panelsList.edCenterScale - 0.05) }
              StyledText { text: panelsList.edCenterScale.toFixed(3); font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edCenterScale = Math.min(2.0, panelsList.edCenterScale + 0.05) }
              StepBtn { label: "+";  onClicked: panelsList.edCenterScale = Math.min(2.0, panelsList.edCenterScale + 0.01) }
            }
            // Center Z — label is a clickable reset-to-999 button
            Row { spacing: vpx(4)
              Rectangle {
                height: vpx(16); radius: vpx(3); width: vpx(61); anchors.verticalCenter: parent.verticalCenter
                color: czLblMa.containsMouse ? Qt.rgba(0.2,0.7,0.3,0.35) : Qt.rgba(1,1,1,0.07)
                border.width: vpx(1); border.color: czLblMa.containsMouse ? Qt.rgba(0.3,0.8,0.4,0.50) : Qt.rgba(1,1,1,0.15)
                StyledText { anchors.centerIn: parent; text: "Center Z"; font.pixelSize: vpx(9)
                  color: czLblMa.containsMouse ? Qt.rgba(0.5,1.0,0.6,1.0) : panelsList.edTextColor }
                MouseArea { id: czLblMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: panelsList.edCenterZ = 999 }
              }
              StepBtn { label: "−";  onClicked: panelsList.edCenterZ = Math.max(1, panelsList.edCenterZ - 1) }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edCenterZ = Math.max(1, panelsList.edCenterZ - 10) }
              StyledText { text: Math.round(panelsList.edCenterZ); font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edCenterZ += 10 }
              StepBtn { label: "+";  onClicked: panelsList.edCenterZ += 1 }
            }
          }

          // Vertical divider between Center / Side sub-cols
          Rectangle {
            anchors { top: plHdr.bottom; bottom: parent.bottom; left: colCenter.right; leftMargin: vpx(4) }
            width: vpx(1); color: Qt.rgba(1,1,1,0.07)
          }

          // Right sub-col: Side Items
          Column {
            id: colSide
            anchors { top: parent.top; left: colCenter.right; leftMargin: vpx(10) }
            spacing: vpx(2)

            Row { spacing: vpx(6); height: vpx(14)
              StyledText { text: "— Side Items —"; font.pixelSize: vpx(10); color: panelsList.edTextColor; anchors.verticalCenter: parent.verticalCenter }
              Pill { label: panelsList.edArcFlip ? "Arc: Grow Out ↑" : "Arc: Shrink Out ↓"; on: panelsList.edArcFlip
                onCol: "#ff9933"
                onToggled: panelsList.edArcFlip = !panelsList.edArcFlip }
            }

            Row { spacing: vpx(4)
              StyledText { text: "Side Y Drop"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(61); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−";  onClicked: panelsList.edYDrop = Math.max(-vpx(200), panelsList.edYDrop - vpx(2)) }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edYDrop = Math.max(-vpx(200), panelsList.edYDrop - vpx(10)) }
              StyledText { text: Math.round(panelsList.edYDrop)+"px"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edYDrop += vpx(10) }
              StepBtn { label: "+";  onClicked: panelsList.edYDrop += vpx(2) }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Spacing "; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(61); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−";  onClicked: panelsList.edSpacing = Math.max(vpx(10), panelsList.edSpacing - vpx(5)) }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edSpacing = Math.max(vpx(10), panelsList.edSpacing - vpx(20)) }
              StyledText { text: Math.round(panelsList.edSpacing)+"px"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edSpacing += vpx(20) }
              StepBtn { label: "+";  onClicked: panelsList.edSpacing += vpx(5) }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Base Scale"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(61); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−";  onClicked: panelsList.edBaseScale = Math.max(0.05, panelsList.edBaseScale - 0.01) }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edBaseScale = Math.max(0.05, panelsList.edBaseScale - 0.05) }
              StyledText { text: panelsList.edBaseScale.toFixed(3); font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edBaseScale = Math.min(2.0, panelsList.edBaseScale + 0.05) }
              StepBtn { label: "+";  onClicked: panelsList.edBaseScale = Math.min(2.0, panelsList.edBaseScale + 0.01) }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Side Z"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(61); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−";  onClicked: panelsList.edSideZ = Math.max(1, panelsList.edSideZ - 1) }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edSideZ = Math.max(1, panelsList.edSideZ - 10) }
              StyledText { text: Math.round(panelsList.edSideZ); font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edSideZ += 10 }
              StepBtn { label: "+";  onClicked: panelsList.edSideZ += 1 }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Arc Step"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(61); anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "−";  onClicked: panelsList.edScaleStep = Math.max(0.0, panelsList.edScaleStep - 0.005) }
              StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edScaleStep = Math.max(0.0, panelsList.edScaleStep - 0.02) }
              StyledText { text: panelsList.edScaleStep.toFixed(3); font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
              StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edScaleStep = Math.min(0.40, panelsList.edScaleStep + 0.02) }
              StepBtn { label: "+";  onClicked: panelsList.edScaleStep = Math.min(0.40, panelsList.edScaleStep + 0.005) }
            }
          }
        }

        // Divider between col1 and colWrap
        Rectangle {
          id: divInner
          anchors { top: parent.top; bottom: parent.bottom; left: col1.right; leftMargin: vpx(5) }
          width: vpx(1); color: Qt.rgba(1,1,1,0.07)
        }

        // ── COL 2: PANEL WRAPPER MOUSE CONTROLS ──────────────────────
        Column {
          id: colWrapLeft
          anchors { left: divInner.right; leftMargin: vpx(6); top: parent.top }
          width: vpx(199); spacing: vpx(2)

          StyledText { text: "Panel Wrapper Mouse Controls"; font.pixelSize: vpx(7); font.bold: true
            color: panelsList.edColorMode === 1 ? "#444444" : safeAccent }

          Row { spacing: vpx(4)
            StyledText { text: "◄ Left Offset"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(65); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: panelsList.edLeftCorrectX -= vpx(5) }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edLeftCorrectX -= vpx(20) }
            StyledText { text: Math.round(panelsList.edLeftCorrectX)+"px"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edLeftCorrectX += vpx(20) }
            StepBtn { label: "+";  onClicked: panelsList.edLeftCorrectX += vpx(5) }
          }
          Row { spacing: vpx(4)
            StyledText { text: "► Right Offset"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(65); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: panelsList.edRightCorrectX -= vpx(5) }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edRightCorrectX -= vpx(20) }
            StyledText { text: Math.round(panelsList.edRightCorrectX)+"px"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edRightCorrectX += vpx(20) }
            StepBtn { label: "+";  onClicked: panelsList.edRightCorrectX += vpx(5) }
          }
          Row { spacing: vpx(4); opacity: panelsList.edAsymArc ? 1.0 : 0.42
            StyledText { text: "◄ Left Arc"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(65); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: { if (panelsList.edAsymArc) panelsList.edArcStepLeft = Math.max(0.0, panelsList.edArcStepLeft - 0.005) } }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymArc) panelsList.edArcStepLeft = Math.max(0.0, panelsList.edArcStepLeft - 0.02) } }
            StyledText { text: panelsList.edArcStepLeft.toFixed(3); font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymArc) panelsList.edArcStepLeft = Math.min(0.40, panelsList.edArcStepLeft + 0.02) } }
            StepBtn { label: "+";  onClicked: { if (panelsList.edAsymArc) panelsList.edArcStepLeft = Math.min(0.40, panelsList.edArcStepLeft + 0.005) } }
          }
          Row { spacing: vpx(4); opacity: panelsList.edAsymArc ? 1.0 : 0.42
            StyledText { text: "► Right Arc"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(65); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: { if (panelsList.edAsymArc) panelsList.edArcStepRight = Math.max(0.0, panelsList.edArcStepRight - 0.005) } }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymArc) panelsList.edArcStepRight = Math.max(0.0, panelsList.edArcStepRight - 0.02) } }
            StyledText { text: panelsList.edArcStepRight.toFixed(3); font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymArc) panelsList.edArcStepRight = Math.min(0.40, panelsList.edArcStepRight + 0.02) } }
            StepBtn { label: "+";  onClicked: { if (panelsList.edAsymArc) panelsList.edArcStepRight = Math.min(0.40, panelsList.edArcStepRight + 0.005) } }
          }
          // Arc Sym pill + Reset Panel Wrapper
          Row { spacing: vpx(3); topPadding: vpx(1)
            Pill { label: panelsList.edAsymArc ? "Arc Left/Right" : "Arc Symmetric"; on: panelsList.edAsymArc
              onToggled: { panelsList.edAsymArc = !panelsList.edAsymArc;
                if (panelsList.edAsymArc) { panelsList.edArcStepLeft = panelsList.edScaleStep; panelsList.edArcStepRight = panelsList.edScaleStep; } } }
            Rectangle {
              height: vpx(16); radius: vpx(3); width: rstLbl.implicitWidth + vpx(16); anchors.verticalCenter: parent.verticalCenter
              color: rstMa.containsMouse ? Qt.rgba(0.6,0.1,0.1,0.45) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,0.3,0.3,0.30)
              StyledText { id: rstLbl; anchors.centerIn: parent; text: "Reset Panel Wrapper"; font.pixelSize: vpx(8); color: Qt.rgba(1,0.6,0.6,0.85) }
              MouseArea { id: rstMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  panelsList.edLeftCorrectX = 0; panelsList.edRightCorrectX = 0;
                  panelsList.edAsymArc = false; panelsList.edArcStepLeft = panelsList.edScaleStep; panelsList.edArcStepRight = panelsList.edScaleStep;
                  panelsList.edAsymScale = false; panelsList.edBaseScaleLeft = panelsList.edBaseScale; panelsList.edBaseScaleRight = panelsList.edBaseScale;
                  panelsList.edAsymSpacing = false; panelsList.edSpacingLeft = panelsList.edSpacing; panelsList.edSpacingRight = panelsList.edSpacing;
                  panelsList.edArcCurve = 0.0;
                  panelsList.edAsymYCurve = false; panelsList.edYCurveLeft = 0.0; panelsList.edYCurveRight = 0.0;
                }
              }
            }
          }
          // Mirror L>R + Mirror R>L + Switch L>R
          Row { spacing: vpx(3)
            // Mirror Offsets Left → Right
            Rectangle {
              height: vpx(16); radius: vpx(3); width: mirTxt.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
              color: mirMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.20)
              StyledText { id: mirTxt; anchors.centerIn: parent; text: "Mirror L→R"; font.pixelSize: vpx(8); color: "#ffffff" }
              MouseArea { id: mirMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  panelsList.edRightCorrectX = -panelsList.edLeftCorrectX;
                  if (panelsList.edAsymArc)     panelsList.edArcStepRight   = panelsList.edArcStepLeft;
                  if (panelsList.edAsymScale)   panelsList.edBaseScaleRight = panelsList.edBaseScaleLeft;
                  if (panelsList.edAsymSpacing) panelsList.edSpacingRight   = panelsList.edSpacingLeft;
                  if (panelsList.edAsymYDrop)   panelsList.edYDropRight     = panelsList.edYDropLeft;
                }
              }
            }
            // Mirror Offsets Right → Left
            Rectangle {
              height: vpx(16); radius: vpx(3); width: mirRTxt.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
              color: mirRMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.20)
              StyledText { id: mirRTxt; anchors.centerIn: parent; text: "Mirror R→L"; font.pixelSize: vpx(8); color: "#ffffff" }
              MouseArea { id: mirRMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  panelsList.edLeftCorrectX = -panelsList.edRightCorrectX;
                  if (panelsList.edAsymArc)     panelsList.edArcStepLeft    = panelsList.edArcStepRight;
                  if (panelsList.edAsymScale)   panelsList.edBaseScaleLeft  = panelsList.edBaseScaleRight;
                  if (panelsList.edAsymSpacing) panelsList.edSpacingLeft    = panelsList.edSpacingRight;
                  if (panelsList.edAsymYDrop)   panelsList.edYDropLeft      = panelsList.edYDropRight;
                }
              }
            }
            // Switch L>R — swap all asymmetric left/right values
            Rectangle {
              height: vpx(16); radius: vpx(3); width: swLRLbl.implicitWidth + vpx(10); anchors.verticalCenter: parent.verticalCenter
              color: swLRMa.containsMouse ? Qt.rgba(0.6,0.4,0.9,0.30) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: swLRMa.containsMouse ? Qt.rgba(0.7,0.5,1.0,0.70) : Qt.rgba(1,1,1,0.22)
              StyledText { id: swLRLbl; anchors.centerIn: parent; text: "⇄ Switch L>R"; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
              MouseArea { id: swLRMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var tmp;
                  tmp = panelsList.edLeftCorrectX;   panelsList.edLeftCorrectX   = panelsList.edRightCorrectX;  panelsList.edRightCorrectX  = tmp;
                  tmp = panelsList.edArcStepLeft;    panelsList.edArcStepLeft    = panelsList.edArcStepRight;   panelsList.edArcStepRight   = tmp;
                  tmp = panelsList.edBaseScaleLeft;  panelsList.edBaseScaleLeft  = panelsList.edBaseScaleRight; panelsList.edBaseScaleRight = tmp;
                  tmp = panelsList.edSpacingLeft;    panelsList.edSpacingLeft    = panelsList.edSpacingRight;   panelsList.edSpacingRight   = tmp;
                  tmp = panelsList.edYDropLeft;      panelsList.edYDropLeft      = panelsList.edYDropRight;     panelsList.edYDropRight     = tmp;
                  tmp = panelsList.edYCurveLeft;     panelsList.edYCurveLeft     = panelsList.edYCurveRight;    panelsList.edYCurveRight    = tmp;
                }
              }
            }
          }
        }
      }

      // ══ Scale / Spacing + Live Values block (right when normal, left when flipped) ══
      Item {
        id: rightBlock
        anchors {
          top: parent.top; bottom: parent.bottom
          left:  panelsList.edPanelFlipped ? parent.left : leftBlock.right
          leftMargin: panelsList.edPanelFlipped ? vpx(0) : vpx(6)
        }
        width: vpx(655)

        // Divider
        Rectangle {
          id: divOuter
          anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
          width: vpx(1); color: Qt.rgba(1,1,1,0.07)
        }

        // ── COL 3: SCALE / SPACING ────────────────────────────────────
        Column {
          id: colWrapRight
          anchors { left: divOuter.right; leftMargin: vpx(4); top: parent.top }
          width: vpx(205); spacing: vpx(2)

          StyledText { text: "Scale / Spacing"; font.pixelSize: vpx(8); font.bold: true
            color: panelsList.edColorMode === 1 ? "#444444" : safeAccent }

          Row { spacing: vpx(4)
            StyledText { text: "◄ Left Scale"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(69); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: panelsList.edBaseScaleLeft = Math.max(0.05, panelsList.edBaseScaleLeft - 0.01) }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edBaseScaleLeft = Math.max(0.05, panelsList.edBaseScaleLeft - 0.05) }
            StyledText { text: panelsList.edBaseScaleLeft.toFixed(3); font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edBaseScaleLeft = Math.min(2.0, panelsList.edBaseScaleLeft + 0.05) }
            StepBtn { label: "+";  onClicked: panelsList.edBaseScaleLeft = Math.min(2.0, panelsList.edBaseScaleLeft + 0.01) }
          }
          Row { spacing: vpx(4)
            StyledText { text: "► Right Scale"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(69); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: panelsList.edBaseScaleRight = Math.max(0.05, panelsList.edBaseScaleRight - 0.01) }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edBaseScaleRight = Math.max(0.05, panelsList.edBaseScaleRight - 0.05) }
            StyledText { text: panelsList.edBaseScaleRight.toFixed(3); font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edBaseScaleRight = Math.min(2.0, panelsList.edBaseScaleRight + 0.05) }
            StepBtn { label: "+";  onClicked: panelsList.edBaseScaleRight = Math.min(2.0, panelsList.edBaseScaleRight + 0.01) }
          }
          Row { spacing: vpx(4); opacity: panelsList.edAsymSpacing ? 1.0 : 0.42
            StyledText { text: "◄ Left Spacing"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(69); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: { if (panelsList.edAsymSpacing) panelsList.edSpacingLeft = Math.max(vpx(10), panelsList.edSpacingLeft - vpx(5)) } }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymSpacing) panelsList.edSpacingLeft = Math.max(vpx(10), panelsList.edSpacingLeft - vpx(20)) } }
            StyledText { text: Math.round(panelsList.edSpacingLeft)+"px"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymSpacing) panelsList.edSpacingLeft += vpx(20) } }
            StepBtn { label: "+";  onClicked: { if (panelsList.edAsymSpacing) panelsList.edSpacingLeft += vpx(5) } }
          }
          Row { spacing: vpx(4); opacity: panelsList.edAsymSpacing ? 1.0 : 0.42
            StyledText { text: "► Right Spacing"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(69); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: { if (panelsList.edAsymSpacing) panelsList.edSpacingRight = Math.max(vpx(10), panelsList.edSpacingRight - vpx(5)) } }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymSpacing) panelsList.edSpacingRight = Math.max(vpx(10), panelsList.edSpacingRight - vpx(20)) } }
            StyledText { text: Math.round(panelsList.edSpacingRight)+"px"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: { if (panelsList.edAsymSpacing) panelsList.edSpacingRight += vpx(20) } }
            StepBtn { label: "+";  onClicked: { if (panelsList.edAsymSpacing) panelsList.edSpacingRight += vpx(5) } }
          }
          Row { spacing: vpx(4); topPadding: vpx(1)
            Pill { label: panelsList.edAsymScale ? "Scale Left/Right" : "Scale Symmetric"; on: panelsList.edAsymScale
              onToggled: { panelsList.edAsymScale = !panelsList.edAsymScale;
                if (panelsList.edAsymScale) { panelsList.edBaseScaleLeft = panelsList.edBaseScale; panelsList.edBaseScaleRight = panelsList.edBaseScale; } } }
            Pill { label: panelsList.edAsymSpacing ? "Spacing Left/Right" : "Spacing Symmetric"; on: panelsList.edAsymSpacing
              onToggled: { panelsList.edAsymSpacing = !panelsList.edAsymSpacing;
                if (panelsList.edAsymSpacing) { panelsList.edSpacingLeft = panelsList.edSpacing; panelsList.edSpacingRight = panelsList.edSpacing; } } }
          }

          // ── Visible Count + Reset Density ────────────────────────
          Row { spacing: vpx(8); topPadding: vpx(2)

            // Visible Count ticker
            // Space ticker
            Row { spacing: vpx(0)
              StyledText {
                text: panelsList.edFlatMode ? "Space (flat)" : "Space"
                font.pixelSize: vpx(9); color: panelsList.edTextColor
                width: vpx(54); anchors.verticalCenter: parent.verticalCenter
              }
              Row { spacing: vpx(4)
                StepBtn { label: "−"
                  onClicked: {
                    if (panelsList.edFlatMode) {
                      var minSpacing = panelsList.panelWidth + vpx(1);
                      var nextSp = Math.max(minSpacing, panelsList.edSpacing - vpx(5));
                      panelsList.edSpacing      = nextSp;
                      panelsList.edSpacingLeft  = nextSp;
                      panelsList.edSpacingRight = nextSp;
                      panelsList.gapPx          = Math.max(0, nextSp - panelsList.panelWidth);
                    } else {
                      var cur = Math.round(panelsList.singleScreenWidth / panelsList.edSpacing);
                      var nextVis = Math.max(1, cur - 1);
                      panelsList.visibleBoxes = nextVis;
                      panelsList.edSpacing = panelsList.singleScreenWidth / nextVis;
                      panelsList.edSpacingLeft = panelsList.edSpacing;
                      panelsList.edSpacingRight = panelsList.edSpacing;
                      api.memory.set(pageKey + "visibleBoxes", String(nextVis));
                    }
                  }
                }
                Rectangle {
                  width: vpx(18); height: vpx(18); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                  color: Qt.rgba(1,1,1,0.06); border.color: Qt.rgba(1,1,1,0.18); border.width: vpx(1)
                  StyledText { anchors.centerIn: parent
                    text: panelsList.edFlatMode
                          ? Math.round(panelsList.edSpacing - panelsList.panelWidth)
                          : Math.round(panelsList.singleScreenWidth / panelsList.edSpacing)
                    font.pixelSize: vpx(9); font.bold: true; color: safeAccent }
                }
                StepBtn { label: "+"
                  onClicked: {
                    if (panelsList.edFlatMode) {
                      var nextSp = panelsList.edSpacing + vpx(5);
                      panelsList.edSpacing      = nextSp;
                      panelsList.edSpacingLeft  = nextSp;
                      panelsList.edSpacingRight = nextSp;
                      panelsList.gapPx          = nextSp - panelsList.panelWidth;
                    } else {
                      var cur = Math.round(panelsList.singleScreenWidth / panelsList.edSpacing);
                      var nextVis = Math.min(30, cur + 1);
                      panelsList.visibleBoxes = nextVis;
                      panelsList.edSpacing = panelsList.singleScreenWidth / nextVis;
                      panelsList.edSpacingLeft = panelsList.edSpacing;
                      panelsList.edSpacingRight = panelsList.edSpacing;
                      api.memory.set(pageKey + "visibleBoxes", String(nextVis));
                    }
                  }
                }
              }
            }

            // Row Count ticker
            Row { spacing: vpx(0)
              StyledText {
                text: "Row Count"
                font.pixelSize: vpx(9); color: panelsList.edTextColor
                width: vpx(58); anchors.verticalCenter: parent.verticalCenter
              }
              Row { spacing: vpx(4)
                StepBtn { label: "−"
                  onClicked: {
                    panelsList.edVisibleCount = Math.max(1, panelsList.edVisibleCount - 1);
                    api.memory.set(pageKey + "edVisibleCount", String(panelsList.edVisibleCount));
                  }
                }
                Rectangle {
                  width: vpx(18); height: vpx(18); radius: vpx(3); anchors.verticalCenter: parent.verticalCenter
                  color: Qt.rgba(1,1,1,0.06); border.color: Qt.rgba(1,1,1,0.18); border.width: vpx(1)
                  StyledText { anchors.centerIn: parent; text: panelsList.edVisibleCount
                    font.pixelSize: vpx(9); font.bold: true; color: safeAccent }
                }
                StepBtn { label: "+"
                  onClicked: {
                    panelsList.edVisibleCount = Math.min(7, panelsList.edVisibleCount + 1);
                    api.memory.set(pageKey + "edVisibleCount", String(panelsList.edVisibleCount));
                  }
                }
              }
            }

            // ── -98px Offset toggle (GamerPage / themes with leftMargin inset) ──────
            Row { spacing: vpx(5); height: vpx(18)
              Rectangle {
                width: vpx(12); height: vpx(12); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
                color: panelsList.edUseScreenOrigin ? Qt.rgba(1,0.7,0.2,0.45) : Qt.rgba(1,1,1,0.07)
                border.width: vpx(1); border.color: panelsList.edUseScreenOrigin ? "#ffaa33" : Qt.rgba(1,1,1,0.30)
                StyledText { anchors.centerIn: parent; text: panelsList.edUseScreenOrigin ? "✓" : ""; font.pixelSize: vpx(7); font.bold: true; color: "#ffffff" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    panelsList.edUseScreenOrigin = !panelsList.edUseScreenOrigin;
                    api.memory.set(panelsList.pageKey + "edUseScreenOrigin", panelsList.edUseScreenOrigin ? "true" : "false");
                  }
                }
              }
              StyledText { text: "−98px Offset"; font.pixelSize: vpx(8); anchors.verticalCenter: parent.verticalCenter
                color: panelsList.edUseScreenOrigin ? "#ffaa33" : Qt.rgba(1,1,1,0.40) }
            }

            // ── Multi-Monitor toggle ──────────────────────────────────
            Row { spacing: vpx(5); height: vpx(18)
              Rectangle {
                width: vpx(12); height: vpx(12); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
                color: panelsList.edUseMonitorCount ? Qt.rgba(0.2,0.7,1.0,0.45) : Qt.rgba(1,1,1,0.07)
                border.width: vpx(1); border.color: panelsList.edUseMonitorCount ? "#33aaff" : Qt.rgba(1,1,1,0.30)
                StyledText { anchors.centerIn: parent; text: panelsList.edUseMonitorCount ? "✓" : ""; font.pixelSize: vpx(7); font.bold: true; color: "#ffffff" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    panelsList.edUseMonitorCount = !panelsList.edUseMonitorCount;
                    api.memory.set(panelsList.pageKey + "edUseMonitorCount", panelsList.edUseMonitorCount ? "true" : "false");
                  }
                }
              }
              StyledText { text: "Multi-Monitor"; font.pixelSize: vpx(8); anchors.verticalCenter: parent.verticalCenter
                color: panelsList.edUseMonitorCount ? "#33aaff" : Qt.rgba(1,1,1,0.40) }
            }

            // Reset Density button
            Rectangle {
              height: vpx(18); radius: vpx(3); width: resetDensityLbl.implicitWidth + vpx(10)
              anchors.verticalCenter: parent.verticalCenter
              color: resetDensityMa.containsMouse ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.07)
              border.width: vpx(1); border.color: Qt.rgba(1,1,1,0.22)
              StyledText { id: resetDensityLbl; anchors.centerIn: parent; text: "Reset Density"
                font.pixelSize: vpx(8); color: panelsList.edTextColor }
              MouseArea { id: resetDensityMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                  panelsList.visibleBoxes = 7;
                  panelsList.edVisibleCount = 7;
                  panelsList.edSpacing = panelsList.singleScreenWidth / 7;
                  panelsList.edSpacingLeft = panelsList.edSpacing;
                  panelsList.edSpacingRight = panelsList.edSpacing;
                  api.memory.set(pageKey + "visibleBoxes", "7");
                  api.memory.set(pageKey + "edVisibleCount", "7");
                }
              }
            }
          }
        }

        // Divider after col 3
        Rectangle {
          id: div3
          anchors { top: parent.top; bottom: parent.bottom; left: colWrapRight.right; leftMargin: vpx(4) }
          width: vpx(1); color: Qt.rgba(1,1,1,0.07)
        }

        // ── COL 3b: ARC IN/OUT + Y CURVES ────────────────────────────
        Column {
          id: colArcCurves
          anchors { left: div3.right; leftMargin: vpx(5); top: parent.top }
          width: vpx(205); spacing: vpx(2)

          StyledText { text: "Arc / Y Curves"; font.pixelSize: vpx(8); font.bold: true
            color: panelsList.edColorMode === 1 ? "#444444" : safeAccent }

          // Arc In/Out curve
          Row { spacing: vpx(4)
            StyledText { text: "Arc In/Out"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(69); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: panelsList.edArcCurve = Math.max(-3.0, panelsList.edArcCurve - 0.05) }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edArcCurve = Math.max(-3.0, panelsList.edArcCurve - 0.20) }
            StyledText {
              text: panelsList.edArcCurve === 0.0 ? "Linear"
                  : (panelsList.edArcCurve > 0 ? "In +" : "Out ") + Math.abs(panelsList.edArcCurve).toFixed(2)
              font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edArcCurve = Math.min(3.0, panelsList.edArcCurve + 0.20) }
            StepBtn { label: "+";  onClicked: panelsList.edArcCurve = Math.min(3.0, panelsList.edArcCurve + 0.05) }
          }
          // Arc Up/Down (per-side Y curve) — requires Side Y Drop ≠ 0 to take effect
          Row { spacing: vpx(4)
            StyledText { text: "◄ Y Curve L"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(69); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: panelsList.edYCurveLeft = Math.max(-3.0, panelsList.edYCurveLeft - 0.05) }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edYCurveLeft = Math.max(-3.0, panelsList.edYCurveLeft - 0.20) }
            StyledText { text: panelsList.edYCurveLeft.toFixed(2); font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edYCurveLeft = Math.min(3.0, panelsList.edYCurveLeft + 0.20) }
            StepBtn { label: "+";  onClicked: panelsList.edYCurveLeft = Math.min(3.0, panelsList.edYCurveLeft + 0.05) }
          }
          Row { spacing: vpx(4)
            StyledText { text: "► Y Curve R"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(69); anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "−";  onClicked: panelsList.edYCurveRight = Math.max(-3.0, panelsList.edYCurveRight - 0.05) }
            StepBtn { label: "−−"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edYCurveRight = Math.max(-3.0, panelsList.edYCurveRight - 0.20) }
            StyledText { text: panelsList.edYCurveRight.toFixed(2); font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(37); horizontalAlignment: Text.AlignHCenter; anchors.verticalCenter: parent.verticalCenter }
            StepBtn { label: "++"; btnColor: Qt.rgba(1,1,1,0.06); onClicked: panelsList.edYCurveRight = Math.min(3.0, panelsList.edYCurveRight + 0.20) }
            StepBtn { label: "+";  onClicked: panelsList.edYCurveRight = Math.min(3.0, panelsList.edYCurveRight + 0.05) }
          }
          Row { spacing: vpx(4); topPadding: vpx(1)
            Pill { label: panelsList.edAsymYCurve ? "Y-Curve Left/Right" : "Y-Curve Symmetric"; on: panelsList.edAsymYCurve
              onToggled: { panelsList.edAsymYCurve = !panelsList.edAsymYCurve;
                if (panelsList.edAsymYCurve) { panelsList.edYCurveLeft = 0.0; panelsList.edYCurveRight = 0.0; } } }
          }
          // Reminder: Y Curve only has effect when Side Y Drop ≠ 0
          StyledText {
            text: "↑ Y Curve needs Side Y Drop ≠ 0"
            font.pixelSize: vpx(7); color: panelsList.edYDrop === 0 ? "#ff9944" : Qt.rgba(1,1,1,0.30)
            opacity: panelsList.edYDrop === 0 ? 1.0 : 0.6
          }
        }

        // Divider after col 3b
        Rectangle {
          id: div3b
          anchors { top: parent.top; bottom: parent.bottom; left: colArcCurves.right; leftMargin: vpx(4) }
          width: vpx(1); color: Qt.rgba(1,1,1,0.07)
        }

        // ── COL 4: LIVE VALUES ────────────────────────────────────────
        Row {
          id: colLive
          anchors { left: div3b.right; leftMargin: vpx(6); top: parent.top }
          spacing: vpx(16)

          Column {
            spacing: vpx(2)
            StyledText { text: "Live Values"; font.pixelSize: vpx(8); font.bold: true
              color: panelsList.edColorMode === 1 ? "#444444" : safeAccent }
            Row { spacing: vpx(4)
              StyledText { text: "Selected X";   font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: Math.round(panelsList.edSelectedX)+" px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Selected Y";   font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: Math.round(panelsList.edSelectedY)+" px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Selected Z";   font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: Math.round(panelsList.edCenterZ); font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Center Scale"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: panelsList.edCenterScale.toFixed(3); font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Center Z";     font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: Math.round(panelsList.edCenterZ); font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Spacing";      font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: Math.round(panelsList.edSpacing)+" px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Base Scale";   font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: panelsList.edBaseScale.toFixed(3); font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Arc Curve";    font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: panelsList.edArcCurve.toFixed(2); font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
          }

          Column {
            spacing: vpx(2)
            StyledText { text: " "; font.pixelSize: vpx(8) }
            Row { spacing: vpx(4)
              StyledText { text: "Side Z";       font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: Math.round(panelsList.edSideZ); font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Arc Step";     font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: panelsList.edScaleStep.toFixed(3); font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Side Y Drop";  font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: Math.round(panelsList.edYDrop)+" px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Left Offset";  font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: Math.round(panelsList.edLeftCorrectX)+" px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Right Offset"; font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: Math.round(panelsList.edRightCorrectX)+" px"; font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Y Curve L";    font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText { text: panelsList.edYCurveLeft.toFixed(2); font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor }
            }
            Row { spacing: vpx(4)
              StyledText { text: "Active Slot";  font.pixelSize: vpx(9); color: panelsList.edTextColor; width: vpx(50) }
              StyledText {
                text: panelsList.edActiveSlot >= 0 ? ("Preset "+(panelsList.edActiveSlot+1)) : "—"
                font.pixelSize: vpx(9); font.bold: true; color: panelsList.edTextColor
              }
            }
          }
        }
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // TABS EDITOR BLADE — full-screen right-side panel (genredetails style)
  // Opened from the Wrapper section's "Tabs Editor" button.
  // Closes the layout manager and slides in from the right edge of the screen.
  // ════════════════════════════════════════════════════════════════
  Rectangle {
    id: tabsEditorBlade
    visible: panelsList.edTabsOpen || tabsBladeSlideOut.running
    // Break out of PathView coordinate space to cover the full screen,
    // mirroring the same trick editorOverlay uses.
    y: -panelsList.y
    x: -panelsList.x
    width:  panelsList.parent ? panelsList.parent.width  : panelsList.width
    height: panelsList.parent ? panelsList.parent.height : panelsList.height
    color: "transparent"
    z: 10000

    // ── Transparent click-to-close area — left portion ───────────
    Rectangle {
      anchors { top: parent.top; bottom: parent.bottom; left: parent.left; right: bladePanel.left }
      color: "transparent"
      MouseArea { anchors.fill: parent; onClicked: { tabsBladeSlideOut.start() } }
    }

    // ── Panel — right 45% of screen ──────────────────────────────
    Rectangle {
      id: bladePanel
      anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
      width: parent.width * 0.45
      radius: vpx(16)
      clip: true
      color: Qt.rgba(0,0,0,0)
      border.color: ((bladePanel.bp_bgMode === 7 || bladePanel.bp_bgMode === 0) && bladePanel.bp_guideBgOn) ? Qt.rgba(0,0,0,0) : bladePanel.bp_editorAccentColor
      border.width: ((bladePanel.bp_bgMode === 7 || bladePanel.bp_bgMode === 0) && bladePanel.bp_guideBgOn) ? 0 : vpx(3)

      property real slideX: 0
      transform: Translate { x: bladePanel.slideX }

      NumberAnimation {
        id: tabsBladeSlideIn
        target: bladePanel; property: "slideX"
        from: bladePanel.width; to: 0
        duration: 220; easing.type: Easing.OutCubic
      }
      NumberAnimation {
        id: tabsBladeSlideOut
        target: bladePanel; property: "slideX"
        from: 0; to: bladePanel.width
        duration: 180; easing.type: Easing.InCubic
        onStopped: { panelsList.edTabsOpen = false }
      }

      onVisibleChanged: {
        if (visible) {
          bladePanel.slideX = bladePanel.width
          tabsBladeSlideIn.start()
          bladePanel.bp_loadGuideImages()
          bladePanel.bp_loadIconImages()
          // Force re-read of all live state from memory on every open
          bladePanel.currentTab = api.memory.get("currentTab") || ""
          bladePanel.bp_currentIcon = api.memory.get("currentIcon") || api.memory.get("cfg.currentIcon") || "Green Glass"
          // Read title: check for saved custom name first, then fall back to model
          var idx = panelsList.currentIndex
          var saved = api.memory.get("panelTitle." + idx)
          if (saved && saved.length > 0) {
            bladePanel.bp_panelTitle = saved
          } else {
            var t = ""
            var m = panelsList.model
            if (m && idx >= 0) {
              var itm = m.get ? m.get(idx) : null
              if (itm) {
                if (typeof itm.title === "string" && itm.title.length > 0) t = itm.title
                else if (itm.collection && itm.collection.name) t = itm.collection.name
                else if (typeof itm.name === "string" && itm.name.length > 0) t = itm.name
              }
            }
            bladePanel.bp_panelTitle = t
          }
          // Also refresh on next frame in case model wasn't ready yet
          bp_titleRefreshTimer.restart()
        }
      }

      Timer {
        id: bp_titleRefreshTimer
        interval: 50; repeat: false
        onTriggered: {
          var t = ""
          var idx = panelsList.currentIndex
          var m = panelsList.model
          if (m && idx >= 0) {
            var itm = m.get ? m.get(idx) : null
            if (itm) {
              if (typeof itm.title === "string" && itm.title.length > 0) t = itm.title
              else if (itm.collection && itm.collection.name) t = itm.collection.name
              else if (typeof itm.name === "string" && itm.name.length > 0) t = itm.name
            }
          }
          if (t.length > 0) bladePanel.bp_panelTitle = t
        }
      }

      // ── Live tab state (read from memory, written on toggle) ────
      property bool tabsGradOn:       (api.memory.get("theme.tabsGrad")       || "true")  !== "false"
      property bool tabsDarkOn:       (api.memory.get("theme.tabsDark")       || "false") === "true"
      property bool tabsBgOn:         (api.memory.get("theme.tabsBg")         || "true")  !== "false"
      property bool tabsRingsOn:      (api.memory.get("theme.tabsRings")      || "false") === "true"
      property bool tabBorderOn:      (api.memory.get("theme.tabBorder")      || "false") === "true"
      property bool tabTitleAccentOn: (api.memory.get("theme.tabTitleAccent") || "false") === "true"
      property bool tabTitleGradOn:   (api.memory.get("theme.tabTitleGrad")   || "true")  !== "false"
      property int  tabsOpacity:      parseInt(api.memory.get("theme.tabsOpacity") || "100")
      property string currentTab:     api.memory.get("currentTab") || ""
      property string currentTabTitle: bladePanel.currentTab
      property string bp_panelTitle:   ""  // set imperatively on open and on index change
      // Keep title in sync when user navigates panels while blade is open
      Connections {
        target: panelsList
        function onCurrentIndexChanged() {
          if (!bladePanel.visible) return
          var idx = panelsList.currentIndex
          var saved = api.memory.get("panelTitle." + idx)
          if (saved && saved.length > 0) { bladePanel.bp_panelTitle = saved; return }
          var t = ""
          var m = panelsList.model
          if (m && idx >= 0) {
            var itm = m.get ? m.get(idx) : null
            if (itm) {
              if (typeof itm.title === "string" && itm.title.length > 0) t = itm.title
              else if (itm.collection && itm.collection.name) t = itm.collection.name
              else if (typeof itm.name === "string" && itm.name.length > 0) t = itm.name
            }
          }
          bladePanel.bp_panelTitle = t
        }
      }
      // currentTabIcon: re-evaluates when panelsList.currentIndex OR bp_currentIcon changes.
      // Extracts the icon filename from item.iconSrce (e.g. "Buddy.png") so the
      // preview shows the correct per-panel icon, not always Controller.png.
      property string currentTabIcon: {
        var _idx = panelsList.currentIndex   // reactive dependency on panel change
        var _ico = bp_currentIcon            // reactive dependency on icon-set change
        if (_ico.length === 0) return ""
        // Try to get the specific icon filename from the model item's iconSrce.
        // Handle both ListModel (.get) and Pegasus native models (direct index access).
        var iconFile = "Controller.png"
        if (panelsList.model) {
          var item = panelsList.model.get
                     ? panelsList.model.get(_idx)
                     : panelsList.model[_idx]
          if (item && item.iconSrce && item.iconSrce.length > 0) {
            // iconSrce is a full path like "../../assets/images/icons/Green Glass/icons/Buddy.png"
            // Extract just the filename (last segment after the final "/")
            var parts = item.iconSrce.toString().split("/")
            var fname = parts[parts.length - 1]
            if (fname.length > 0) iconFile = fname
          }
        }
        return "../assets/images/icons/" + _ico + "/icons/" + iconFile
      }

      // Mode 0: Tab Background
      Image {
        visible: bladePanel.bp_bgMode === 0 && !(bladePanel.bp_guideBgOn && bladePanel.bp_guideBackground.length > 0)
        anchors.fill: parent
        opacity: bladePanel.tabsOpacity / 100
        source: bladePanel.currentTab.length > 0 ? "../assets/images/tabs/" + bladePanel.currentTab + "/backgrounds/1.png" : ""
        fillMode: Image.PreserveAspectCrop; asynchronous: true
      }
      Image {
        visible: bladePanel.bp_bgMode === 0 && !(bladePanel.bp_guideBgOn && bladePanel.bp_guideBackground.length > 0)
        anchors.fill: parent; opacity: 0.55
        source: "../assets/images/misc/panel-reflection.png"
        fillMode: Image.PreserveAspectCrop; asynchronous: true
      }

      // Mode 0 + guideBgOn: Guide Background on panel
      Image {
        visible: bladePanel.bp_bgMode === 0 && bladePanel.bp_guideBgOn && bladePanel.bp_guideBackground.length > 0
        anchors.fill: parent
        source: bladePanel.bp_guideBackground.length > 0 ? "../assets/images/guides/" + bladePanel.bp_guideBackground + ".png" : ""
        fillMode: Image.PreserveAspectCrop; asynchronous: true
      }

      // Mode 7: Guide Background
      Image {
        visible: bladePanel.bp_bgMode === 7 && bladePanel.bp_guideBackground.length > 0
        anchors.fill: parent
        source: bladePanel.bp_guideBackground.length > 0 ? "../assets/images/guides/" + bladePanel.bp_guideBackground + ".png" : ""
        fillMode: Image.PreserveAspectCrop; asynchronous: true
      }

      // Modes 1-5: inlined PanelBg (component not in scope here)
      Item {
        anchors.fill: parent
        visible: bladePanel.bp_bgMode !== 0 && bladePanel.bp_bgMode !== 6 && bladePanel.bp_bgMode !== 7

        // DARK branch
        Rectangle {
          anchors.fill: parent
          color: bladePanel.bp_themeDark
          visible: bladePanel.bp_themeDarkOn && !bladePanel.bp_activePanelGradient
        }
        LinearGradient {
          visible: bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradThemeColor
          anchors.fill: parent
          start: Qt.point(0,0); end: Qt.point(width,height)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(bladePanel.bp_themeDark.r,bladePanel.bp_themeDark.g,bladePanel.bp_themeDark.b,0.97) }
            GradientStop { position:0.6; color:Qt.rgba(bladePanel.bp_themeDark.r*.7,bladePanel.bp_themeDark.g*.7,bladePanel.bp_themeDark.b*.7,0.97) }
            GradientStop { position:1.0; color:Qt.rgba(bladePanel.bp_themeDark.r*.5,bladePanel.bp_themeDark.g*.5,bladePanel.bp_themeDark.b*.5,0.97) }
          }
        }
        LinearGradient {
          visible: bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradThemeTransp
          anchors.fill: parent
          start: Qt.point(0,height); end: Qt.point(0,0)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(0,0,0,0.18) }
            GradientStop { position:1.0; color:Qt.rgba(0,0,0,0.0) }
          }
        }
        LinearGradient {
          visible: bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradAccentColor
          anchors.fill: parent
          start: Qt.point(0,0); end: Qt.point(width,0)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.12) }
            GradientStop { position:1.0; color:"transparent" }
          }
        }
        LinearGradient {
          visible: bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradAccentOpacity
          anchors.fill: parent
          start: Qt.point(0,0); end: Qt.point(0,height)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.08) }
            GradientStop { position:1.0; color:"transparent" }
          }
        }

        // LIGHT/COLOR branch
        Rectangle {
          anchors.fill: parent
          color: bladePanel.bp_editorThemeFillColor
          visible: !bladePanel.bp_themeDarkOn && !bladePanel.bp_activePanelGradient
        }
        LinearGradient {
          visible: !bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradThemeColor
          anchors.fill: parent
          start: Qt.point(0,0); end: Qt.point(width,height)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(bladePanel.bp_editorThemeFillColor.r,bladePanel.bp_editorThemeFillColor.g,bladePanel.bp_editorThemeFillColor.b,bladePanel.bp_panelAlpha) }
            GradientStop { position:0.6; color:Qt.rgba(bladePanel.bp_editorThemeFillColor.r*.7,bladePanel.bp_editorThemeFillColor.g*.7,bladePanel.bp_editorThemeFillColor.b*.7,bladePanel.bp_panelAlpha) }
            GradientStop { position:1.0; color:Qt.rgba(bladePanel.bp_editorThemeFillColor.r*.5,bladePanel.bp_editorThemeFillColor.g*.5,bladePanel.bp_editorThemeFillColor.b*.5,bladePanel.bp_panelAlpha) }
          }
        }
        LinearGradient {
          visible: !bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradThemeTransp
          anchors.fill: parent
          start: Qt.point(0,height); end: Qt.point(0,0)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(0,0,0,0.18) }
            GradientStop { position:1.0; color:Qt.rgba(0,0,0,0.0) }
          }
        }
        LinearGradient {
          visible: !bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradAccentColor
          anchors.fill: parent
          start: Qt.point(0,0); end: Qt.point(width,0)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.12) }
            GradientStop { position:1.0; color:"transparent" }
          }
        }
        LinearGradient {
          visible: !bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradAccentOpacity
          anchors.fill: parent
          start: Qt.point(0,0); end: Qt.point(0,height)
          gradient: Gradient {
            GradientStop { position:0.0; color:Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.08) }
            GradientStop { position:1.0; color:"transparent" }
          }
        }
      }

      // Mode 0: bottom gradient
      LinearGradient {
        visible: bladePanel.tabTitleGradOn && bladePanel.bp_bgMode === 0 && !(bladePanel.bp_guideBgOn && bladePanel.bp_guideBackground.length > 0)
        anchors.left: parent.left; anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * 0.45
        start: Qt.point(0, 0); end: Qt.point(0, height)
        gradient: Gradient {
          GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0) }
          GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.75) }
        }
      }

      // ── Header — matches genredetails headerBlock exactly ────────
      Column {
        id: tabsBladeHeader
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        anchors.topMargin: vpx(4); anchors.leftMargin: vpx(110); anchors.rightMargin: vpx(16)
        spacing: vpx(12)

        Row {
          spacing: vpx(10)
          Rectangle {
            width: vpx(4); radius: vpx(2); height: vpx(28); color: bladePanel.bp_editorAccentColor
            anchors.verticalCenter: parent.verticalCenter
          }
          StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: "Tab: " + bladePanel.bp_panelTitle
            font.pixelSize: vpx(panelsList.libTitleSize); font.bold: true; color: "#ffffff"
          }
        }
        Rectangle { width: parent.width; height: vpx(1); color: bladePanel.bp_editorAccentColor }
      }

      // ── Theme state — mirrors genredetails.qml (same memory keys) ─
      property bool bp_panelGradient:     (api.memory.get("cfg.panelGradient")  || "true")  !== "false"
      property bool bp_gradAccentColor:   (api.memory.get("cfg.gradAccent")     || "true")  !== "false"
      property bool bp_gradAccentOpacity: (api.memory.get("cfg.gradAccentOp")   || "true")  !== "false"
      property bool bp_gradThemeColor:    (api.memory.get("cfg.gradTheme")      || "true")  !== "false"
      property bool bp_gradThemeTransp:   (api.memory.get("cfg.gradThemeTr")    || "true")  !== "false"
      property bool bp_themeGradOn:       (api.memory.get("theme.themeGrad")    || "true")  !== "false"
      property bool bp_accentGradOn:      (api.memory.get("theme.accentGrad")   || "true")  !== "false"
      property bool bp_pageBgGradOn:      (api.memory.get("theme.pageBgGrad")   || "true")  !== "false"
      property bool bp_themeDarkOn:       (api.memory.get("theme.themeDark")    || "true")  !== "false"
      property bool bp_hideLibBg:         (api.memory.get("theme.hideLibBg")    || "false") === "true"
      property bool bp_libGradOn:         (api.memory.get("theme.libGrad")      || "true")  !== "false"

      // ── Editor background mode (same as genredetails cfg key) ───
      property int  bp_bgMode:   parseInt(api.memory.get("cfg.genreEditorBackgroundMode") || "0")
      readonly property var bp_bgModes: [
        { label: "Tab Background" }, { label: "Accent & Theme Color" },
        { label: "Accent & Theme Preset" }, { label: "Legacy" },
        { label: "Dark" }, { label: "Accent & Theme Profile" },
        { label: "Clear" }, { label: "Guide Background" }
      ]

      // ── Guide Background picker ──────────────────────────────────
      property bool   bp_guideBgPickerOpen: false
      property bool   bp_appearanceOpen:   false
      property bool   bp_tabPreviewOpen:    false
      property bool   bp_tabRenameOpen:     false
      property bool   bp_tabBgPickerOpen:   false
      property bool   bp_tabIconPickerOpen: false
      property string bp_tabRenameText:     ""
      property string bp_guideBackground:  api.memory.get("cfg.guideBackground") || ""
      property bool   bp_guideBgOn:        (api.memory.get("cfg.guideBgOn") || "true") !== "false"
      property string bp_currentIcon: api.memory.get("currentIcon") || api.memory.get("cfg.currentIcon") || "Green Glass"
      ListModel { id: bp_iconModel }
      function bp_loadIconImages() {
        bp_iconModel.clear()
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("../assets/images/icons/icons.metadata.pegasus.txt"), true)
        xhr.onreadystatechange = function() {
          if (xhr.readyState !== XMLHttpRequest.DONE) return
          if (xhr.status === 200 || xhr.status === 0) {
            var lines = xhr.responseText.split("\n")
            for (var i = 0; i < lines.length; i++) {
              var line = lines[i].trim()
              if (line.toLowerCase().indexOf("icons:") === 0) {
                var name = line.substring(6).trim()
                if (name.length > 0) bp_iconModel.append({ itemName: name })
              }
            }
          }
        }
        xhr.send()
      }
      ListModel { id: bp_guideModel }
      function bp_loadGuideImages() {
        bp_guideModel.clear()
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("../assets/images/guides/guides.metadata.pegasus.txt"), true)
        xhr.onreadystatechange = function() {
          if (xhr.readyState !== XMLHttpRequest.DONE) return
          if (xhr.status === 200 || xhr.status === 0) {
            var lines = xhr.responseText.split("\n")
            for (var i = 0; i < lines.length; i++) {
              var line = lines[i].trim()
              if (line.toLowerCase().indexOf("guides:") === 0) {
                var name = line.substring(7).trim()
                if (name.length > 0) bp_guideModel.append({ itemName: name })
              }
            }
          }
        }
        xhr.send()
      }
      ListModel { id: bp_tabBgModel }
      function bp_loadTabBgImages() {
        bp_tabBgModel.clear()
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("../assets/images/tabs/tabs.metadata.pegasus.txt"), true)
        xhr.onreadystatechange = function() {
          if (xhr.readyState !== XMLHttpRequest.DONE) return
          if (xhr.status === 200 || xhr.status === 0) {
            var lines = xhr.responseText.split("\n")
            for (var i = 0; i < lines.length; i++) {
              var line = lines[i].trim()
              if (line.toLowerCase().indexOf("tabs:") === 0) {
                var name = line.substring(5).trim()
                if (name.length > 0) bp_tabBgModel.append({ itemName: name })
              }
            }
          }
        }
        xhr.send()
      }

      // ── Color values read from memory ───────────────────────────
      property string bp_accentHex: api.memory.get("cfg.accentHex") || "#5d9809"
      property string bp_themeHex:  api.memory.get("cfg.themeHex")  || "#3A3ABF"
      property int    bp_accentAlpha: parseInt(api.memory.get("cfg.accentAlpha") || "0")
      property int    bp_ifaceAlpha:  parseInt(api.memory.get("cfg.ifaceAlpha")  || "80")
      property string bp_accentName: api.memory.get("cfg.accentName") || ""
      property string bp_themeName:  api.memory.get("cfg.themeName")  || ""
      property string bp_presetName: api.memory.get("theme.presetName") || ""

      function bp_colorNameFromHex(hex) {
        var h = hex.toLowerCase()
        var t = [
          ["#5d9809","Lime Green"],["#5588aa","Glass"],["#339933","Vivid Green"],
          ["#6a00ff","Electric Indigo"],["#8a2be2","Blue Violet"],["#9600ec","Electric Violet"],
          ["#800080","Purple"],["#8b008b","Dark Magenta"],["#4b0082","Indigo"],
          ["#3a3abf","Midnight"],["#0000ff","Blue"],["#1ba1e2","Vivid Blue"],
          ["#00bfff","Deep Sky Blue"],["#1e90ff","Dodger Blue"],["#4169e1","Royal Blue"],
          ["#ff0000","Red"],["#e51400","Vivid Red"],["#ff4500","Orange Red"],
          ["#ff6347","Tomato"],["#ff7f50","Coral"],["#ffa500","Orange"],
          ["#ff8c00","Dark Orange"],["#ffd700","Gold"],["#ffff00","Yellow"],
          ["#00ff00","Lime"],["#008000","Green"],["#32cd32","Lime Green"],
          ["#00ffff","Aqua"],["#008080","Teal"],["#ffffff","White"],
          ["#000000","Black"],["#808080","Gray"],["#c0c0c0","Silver"],
          ["#ff69b4","Hot Pink"],["#ff1493","Deep Pink"],["#ff00ff","Fuchsia"],
          ["#d2691e","Chocolate"],["#a52a2a","Brown Red"],["#f0a70a","Amber"],
          ["#daa520","Goldenrod"],["#b8860b","Dark Goldenrod"],["#404040","Dark Gray"]
        ]
        for (var i = 0; i < t.length; i++) { if (t[i][0] === h) return t[i][1] }
        return ""
      }
      property string bp_displayAccentName: {
        var n = bp_accentName !== "" ? bp_accentName : bp_colorNameFromHex(bp_accentHex)
        return n !== "" ? n : bp_accentHex.toUpperCase()
      }
      property string bp_displayThemeName: {
        var n = bp_themeName !== "" ? bp_themeName : bp_colorNameFromHex(bp_themeHex)
        return n !== "" ? n : bp_themeHex.toUpperCase()
      }

      property color bp_accentColor: Qt.rgba(
        parseInt(bp_accentHex.substr(1,2),16)/255,
        parseInt(bp_accentHex.substr(3,2),16)/255,
        parseInt(bp_accentHex.substr(5,2),16)/255,
        Math.max(0.05, Math.min(1.0, 1.0 - bp_accentAlpha/100)))

      property real   bp_panelAlpha: Math.max(0.0, Math.min(0.92, (1.0 - parseInt(api.memory.get("theme.libTransp") || "20")/100) * 0.85))

      property color bp_themeDark: Qt.rgba(
        parseInt(bp_themeHex.substr(1,2),16)/255,
        parseInt(bp_themeHex.substr(3,2),16)/255,
        parseInt(bp_themeHex.substr(5,2),16)/255,
        Math.max(0.05, Math.min(0.92, (1.0 - bp_ifaceAlpha/100) * 0.85)))

      property color bp_themeFillColor: Qt.rgba(
        parseInt(bp_themeHex.substr(1,2),16)/255,
        parseInt(bp_themeHex.substr(3,2),16)/255,
        parseInt(bp_themeHex.substr(5,2),16)/255,
        Math.max(0.05, Math.min(0.92, (1.0 - bp_ifaceAlpha/100) * 0.85)))

      // Active computed colors — match genredetails exactly
      property color bp_editorThemeFillColor: {
        if (bp_bgMode === 0) return Qt.rgba(0,0,0,0)
        if (bp_bgMode === 3 || bp_bgMode === 4) return bp_themeFillColor
        var r = parseInt(bp_themeHex.substr(1,2),16)/255
        var g = parseInt(bp_themeHex.substr(3,2),16)/255
        var b = parseInt(bp_themeHex.substr(5,2),16)/255
        var a = Math.max(0.05, Math.min(0.92, (1.0 - bp_ifaceAlpha/100) * 0.85))
        return Qt.rgba(r, g, b, a)
      }
      property color bp_editorAccentColor: Qt.rgba(
        parseInt(bp_accentHex.substr(1,2),16)/255,
        parseInt(bp_accentHex.substr(3,2),16)/255,
        parseInt(bp_accentHex.substr(5,2),16)/255,
        Math.max(0.05, Math.min(1.0, 1.0 - bp_accentAlpha/100)))

      property bool bp_activePanelGradient:
        bp_bgMode === 0 ? false :
        (bp_bgMode === 3 || bp_bgMode === 4) ? bp_panelGradient : bp_panelGradient
      property bool bp_activeGradThemeColor:
        bp_bgMode === 0 ? false :
        (bp_bgMode === 3 || bp_bgMode === 4) ? bp_themeGradOn : bp_gradThemeColor
      property bool bp_activeGradThemeTransp:
        bp_bgMode === 0 ? false :
        (bp_bgMode === 3 || bp_bgMode === 4) ? bp_pageBgGradOn : bp_gradThemeTransp
      property bool bp_activeGradAccentColor:
        (bp_bgMode === 0 || bp_bgMode === 4) ? false :
        bp_bgMode === 3 ? bp_accentGradOn : bp_gradAccentColor
      property bool bp_activeGradAccentOpacity:
        (bp_bgMode === 0 || bp_bgMode === 4) ? false :
        bp_bgMode === 3 ? bp_themeGradOn : bp_gradAccentOpacity

      // ── Scrollable content area ──────────────────────────────────
      Flickable {
        visible: !bladePanel.bp_guideBgPickerOpen && !bladePanel.bp_tabPreviewOpen
        anchors { top: tabsBladeHeader.bottom; left: parent.left; right: parent.right; bottom: bp_themeInfoHud.top; leftMargin: vpx(104); rightMargin: vpx(6) }
        anchors.topMargin: vpx(6)
        contentHeight: bladeContent.implicitHeight + vpx(20)
        clip: true
        flickableDirection: Flickable.VerticalFlick

        // ── ChipBtn component — matches genredetails style ─────────
        component ChipBtn: Rectangle {
          id: _chip
          property bool   isOn: false
          property string lbl:  ""
          property real   w:    vpx(110)
          width: w; height: vpx(24); radius: vpx(6)
          color: isOn ? Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30) : Qt.rgba(1,1,1,0.08)
          border.color: isOn ? bladePanel.bp_editorAccentColor : Qt.rgba(1,1,1,0.22); border.width: vpx(1)
          Behavior on color { ColorAnimation { duration: 80 } }
          Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: vpx(6)
            anchors.right: parent.right; anchors.rightMargin: vpx(5)
            spacing: vpx(5)
            Rectangle {
              width: vpx(12); height: vpx(12); radius: vpx(2)
              anchors.verticalCenter: parent.verticalCenter
              color: _chip.isOn ? Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.5) : Qt.rgba(1,1,1,0.06)
              border.color: _chip.isOn ? bladePanel.bp_editorAccentColor : Qt.rgba(1,1,1,0.40); border.width: vpx(1)
              StyledText { anchors.centerIn: parent; text: _chip.isOn ? "✓" : ""; font.pixelSize: vpx(8); color: "#fff"; layer.enabled: false }
            }
            StyledText { text: _chip.lbl; font.pixelSize: vpx(10); layer.enabled: false; elide: Text.ElideRight; width: parent.width - vpx(17) }
          }
        }

        Column {
          id: bladeContent
          visible: !bladePanel.bp_appearanceOpen
          anchors { left: parent.left; right: parent.right; top: parent.top; margins: vpx(10); topMargin: vpx(5) }
          spacing: vpx(6)

          // ── Panel title ──────────────────────────────────────────
          Row {
            spacing: vpx(6)
            Rectangle { width: vpx(4); height: vpx(20); radius: vpx(2); color: bladePanel.bp_editorAccentColor; anchors.verticalCenter: parent.verticalCenter }
            StyledText { text: "Tabs"; font.pixelSize: vpx(18); font.bold: true; color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter }
            StyledText { text: "Editor"; font.pixelSize: vpx(15); color: Qt.rgba(1,1,1,0.50); anchors.verticalCenter: parent.verticalCenter }
          }
          Rectangle { width: parent.width; height: vpx(1); color: Qt.rgba(1,1,1,0.14) }

          // ══ SECTION: ACCENT ═════════════════════════════════════
          Column { spacing: vpx(4)
            StyledText { text: "Accent"; font.pixelSize: vpx(11); font.bold: true; color: bladePanel.bp_editorAccentColor }
            Row { spacing: vpx(4)
              ChipBtn { isOn: bladePanel.bp_gradAccentColor;   lbl: "Accent Gradient";        w: vpx(116)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.bp_gradAccentColor = !bladePanel.bp_gradAccentColor; api.memory.set("cfg.gradAccent", bladePanel.bp_gradAccentColor ? "true" : "false") } } }
              ChipBtn { isOn: bladePanel.bp_gradAccentOpacity; lbl: "Accent Opacity";          w: vpx(104)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.bp_gradAccentOpacity = !bladePanel.bp_gradAccentOpacity; api.memory.set("cfg.gradAccentOp", bladePanel.bp_gradAccentOpacity ? "true" : "false") } } }
              ChipBtn { isOn: bladePanel.bp_accentGradOn;      lbl: "Accent Opacity Gradient"; w: vpx(150)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.bp_accentGradOn = !bladePanel.bp_accentGradOn; api.memory.set("theme.accentGrad", bladePanel.bp_accentGradOn ? "true" : "false") } } }
            }
          }

          // ══ SECTION: THEME ══════════════════════════════════════
          Column { spacing: vpx(4)
            StyledText { text: "Theme"; font.pixelSize: vpx(11); font.bold: true; color: "#DDDDDD" }
            Row { spacing: vpx(4)
              ChipBtn { isOn: bladePanel.bp_gradThemeColor;  lbl: "Theme Gradient";              w: vpx(116)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.bp_gradThemeColor = !bladePanel.bp_gradThemeColor; api.memory.set("cfg.gradTheme", bladePanel.bp_gradThemeColor ? "true" : "false") } } }
              ChipBtn { isOn: bladePanel.bp_gradThemeTransp; lbl: "Theme Transparency";          w: vpx(130)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.bp_gradThemeTransp = !bladePanel.bp_gradThemeTransp; api.memory.set("cfg.gradThemeTr", bladePanel.bp_gradThemeTransp ? "true" : "false") } } }
              ChipBtn { isOn: bladePanel.bp_themeGradOn;     lbl: "Theme Transparency Gradient"; w: vpx(180)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.bp_themeGradOn = !bladePanel.bp_themeGradOn; api.memory.set("theme.themeGrad", bladePanel.bp_themeGradOn ? "true" : "false") } } }
            }
            Row { spacing: vpx(4)
              ChipBtn { isOn: bladePanel.bp_pageBgGradOn; lbl: "Page BG Gradient"; w: vpx(126)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.bp_pageBgGradOn = !bladePanel.bp_pageBgGradOn; api.memory.set("theme.pageBgGrad", bladePanel.bp_pageBgGradOn ? "true" : "false") } } }
              ChipBtn { isOn: bladePanel.bp_themeDarkOn;  lbl: "Original Dark";    w: vpx(104)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.bp_themeDarkOn = !bladePanel.bp_themeDarkOn; api.memory.set("theme.themeDark", bladePanel.bp_themeDarkOn ? "true" : "false") } } }
            }
          }

          // ══ SECTION: PANELS ═════════════════════════════════════
          Column { spacing: vpx(4)
            StyledText { text: "Panels"; font.pixelSize: vpx(11); font.bold: true; color: "#DDDDDD" }
            Row { spacing: vpx(4)
              ChipBtn { isOn: bladePanel.bp_panelGradient; lbl: "Panel Gradient";   w: vpx(112)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.bp_panelGradient = !bladePanel.bp_panelGradient; api.memory.set("cfg.panelGradient", bladePanel.bp_panelGradient ? "true" : "false") } } }
              ChipBtn { isOn: !bladePanel.bp_hideLibBg;   lbl: "Page Background";  w: vpx(122)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.bp_hideLibBg = !bladePanel.bp_hideLibBg; api.memory.set("theme.hideLibBg", bladePanel.bp_hideLibBg ? "true" : "false") } } }
              ChipBtn { isOn: bladePanel.bp_libGradOn;    lbl: "Panel Background"; w: vpx(130)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.bp_libGradOn = !bladePanel.bp_libGradOn; api.memory.set("theme.libGrad", bladePanel.bp_libGradOn ? "true" : "false") } } }
            }
          }

          // ══ SECTION: TABS ═══════════════════════════════════════
          Column { spacing: vpx(4)
            StyledText { text: "Tabs"; font.pixelSize: vpx(11); font.bold: true; color: "#DDDDDD" }
            Row { spacing: vpx(4)
              ChipBtn { isOn: bladePanel.tabsGradOn;       lbl: "Tabs Gradient";   w: vpx(106)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.tabsGradOn = !bladePanel.tabsGradOn; api.memory.set("theme.tabsGrad", bladePanel.tabsGradOn ? "true" : "false") } } }
              ChipBtn { isOn: bladePanel.tabsDarkOn;       lbl: "Tabs Dark";       w: vpx(84)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.tabsDarkOn = !bladePanel.tabsDarkOn; api.memory.set("theme.tabsDark", bladePanel.tabsDarkOn ? "true" : "false") } } }
              ChipBtn { isOn: bladePanel.tabsBgOn;         lbl: "Tabs Background"; w: vpx(118)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.tabsBgOn = !bladePanel.tabsBgOn; api.memory.set("theme.tabsBg", bladePanel.tabsBgOn ? "true" : "false") } } }
              ChipBtn { isOn: bladePanel.tabsRingsOn;      lbl: "Tabs Rings";      w: vpx(90)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.tabsRingsOn = !bladePanel.tabsRingsOn; api.memory.set("theme.tabsRings", bladePanel.tabsRingsOn ? "true" : "false") } } }
            }
            Row { spacing: vpx(4)
              ChipBtn { isOn: bladePanel.tabBorderOn;      lbl: "Tab Border";      w: vpx(90)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.tabBorderOn = !bladePanel.tabBorderOn; api.memory.set("theme.tabBorder", bladePanel.tabBorderOn ? "true" : "false") } } }
              ChipBtn { isOn: bladePanel.tabTitleAccentOn; lbl: "Title Accent";    w: vpx(96)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.tabTitleAccentOn = !bladePanel.tabTitleAccentOn; api.memory.set("theme.tabTitleAccent", bladePanel.tabTitleAccentOn ? "true" : "false") } } }
              ChipBtn { isOn: bladePanel.tabTitleGradOn;   lbl: "Title Gradient";  w: vpx(104)
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                  onClicked: { bladePanel.tabTitleGradOn = !bladePanel.tabTitleGradOn; api.memory.set("theme.tabTitleGrad", bladePanel.tabTitleGradOn ? "true" : "false") } } }

            }
          }

          // ── Tabs Opacity slider ────────────────────────────────
          Row {
            spacing: vpx(8)
            Item { width: vpx(4); height: 1 }
            StyledText { text: "Tabs Opacity"; font.pixelSize: vpx(9); color: "#888"; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
              id: tabsOpacityTrack
              width: vpx(160); height: vpx(4); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
              color: Qt.rgba(1,1,1,0.15)
              Rectangle { width: parent.width * (bladePanel.tabsOpacity/100); height: parent.height; radius: parent.radius; color: bladePanel.bp_editorAccentColor }
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(parent.width-width, parent.width*(bladePanel.tabsOpacity/100)-width/2))
                width: vpx(12); height: vpx(12); radius: vpx(6); color: bladePanel.bp_editorAccentColor; border.color: "#fff"; border.width: vpx(2); z: 1
              }
              MouseArea {
                anchors.fill: parent; cursorShape: Qt.SizeHorCursor
                onPressed: _setOp(mouse.x); onPositionChanged: if (pressed) _setOp(mouse.x)
                function _setOp(mx) {
                  bladePanel.tabsOpacity = Math.max(10, Math.min(100, Math.round(mx / tabsOpacityTrack.width * 100)))
                  api.memory.set("theme.tabsOpacity", String(bladePanel.tabsOpacity))
                }
              }
            }
            StyledText { text: bladePanel.tabsOpacity + "%"; font.pixelSize: vpx(10); color: "#ccc"; anchors.verticalCenter: parent.verticalCenter }
          }

          Rectangle { width: parent.width; height: vpx(1); color: Qt.rgba(1,1,1,0.08) }

          // ══ SECTION: MODES ══════════════════════════════════════
          Column { spacing: vpx(4); width: parent.width
            StyledText { text: "Modes"; font.pixelSize: vpx(11); font.bold: true; color: "#DDDDDD" }
            Row { spacing: vpx(3)
              Repeater {
                model: 4
                delegate: Rectangle {
                  property bool isActive: index === bladePanel.bp_bgMode
                  height: vpx(22); width: _ml1.implicitWidth + vpx(12); radius: vpx(4)
                  color: isActive ? bladePanel.bp_editorAccentColor : Qt.rgba(0,0,0,0.42)
                  border.color: isActive ? bladePanel.bp_editorAccentColor : Qt.rgba(1,1,1,0.18); border.width: vpx(1)
                  Behavior on color { ColorAnimation { duration: 80 } }
                  StyledText { id: _ml1; anchors.centerIn: parent; text: bladePanel.bp_bgModes[index].label
                    font.pixelSize: vpx(9); font.bold: parent.isActive
                    color: parent.isActive ? "#FFFFFF" : "#999999"; layer.enabled: false }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { bladePanel.bp_bgMode = index; api.memory.set("cfg.genreEditorBackgroundMode", String(index)) } }
                }
              }
            }
            Row { spacing: vpx(3)
              Repeater {
                model: 3
                delegate: Rectangle {
                  property int  modeIdx: index + 4
                  property bool isActive: modeIdx === bladePanel.bp_bgMode
                  height: vpx(22); width: _ml2.implicitWidth + vpx(12); radius: vpx(4)
                  color: isActive ? bladePanel.bp_editorAccentColor : Qt.rgba(0,0,0,0.42)
                  border.color: isActive ? bladePanel.bp_editorAccentColor : Qt.rgba(1,1,1,0.18); border.width: vpx(1)
                  Behavior on color { ColorAnimation { duration: 80 } }
                  StyledText { id: _ml2; anchors.centerIn: parent; text: bladePanel.bp_bgModes[modeIdx].label
                    font.pixelSize: vpx(9); font.bold: parent.isActive
                    color: parent.isActive ? "#FFFFFF" : "#999999"; layer.enabled: false }
                  MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { bladePanel.bp_bgMode = modeIdx; api.memory.set("cfg.genreEditorBackgroundMode", String(modeIdx)) } }
                }
              }
            }
          }

          Rectangle { width: parent.width; height: vpx(1); color: Qt.rgba(1,1,1,0.08) }

          Item { width: 1; height: vpx(10) }
        }
      }

      // ── Bottom footer bar — pinned to bottom of blade panel ───────
      Item {
        id: tabsBladeFooter
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: vpx(84) }
        height: vpx(68)

        // ── All footer buttons — left-aligned row ─────────────────
        Row {
          anchors { left: parent.left; leftMargin: vpx(26); bottom: parent.bottom; bottomMargin: vpx(5) }
          spacing: vpx(6)

          // Close
          Rectangle {
            height: vpx(26); width: _footCloseLbl.implicitWidth + vpx(16); radius: vpx(6)
            color: _footCloseMA.containsMouse ? Qt.rgba(0.2,0.2,0.8,0.8) : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.18)
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1)
            Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { id: _footCloseLbl; anchors.centerIn: parent; text: "B  Close"; font.pixelSize: vpx(11); font.bold: true; color: "#fff"; layer.enabled: false }
            MouseArea { id: _footCloseMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: { tabsBladeSlideOut.start() } }
          }

          // Tab
          Rectangle {
            height: vpx(26); width: _footTabLbl.implicitWidth + vpx(12); radius: vpx(6)
            color: bladePanel.bp_tabPreviewOpen ? bladePanel.bp_editorAccentColor : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30)
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1)
            Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { id: _footTabLbl; anchors.centerIn: parent; text: "Tab"; font.pixelSize: vpx(10); font.bold: true; color: "#fff"; layer.enabled: false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { bladePanel.bp_tabPreviewOpen = !bladePanel.bp_tabPreviewOpen; bladePanel.bp_appearanceOpen = false } }
          }

          // Guide BG
          Rectangle {
            height: vpx(26); width: vpx(72); radius: vpx(6)
            color: (bladePanel.bp_bgMode === 7) ? bladePanel.bp_editorAccentColor : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.22)
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1)
            Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { anchors.centerIn: parent; text: "Guide BG"; font.pixelSize: vpx(10); font.bold: true; color: "#fff"; layer.enabled: false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { bladePanel.bp_bgMode = 7; api.memory.set("cfg.genreEditorBackgroundMode", "7"); bladePanel.bp_guideBgPickerOpen = true; bladePanel.bp_appearanceOpen = false } }
          }

          // CHECKBOX Guide
          Rectangle {
            id: footGuideCbBtn
            height: vpx(26); width: vpx(70); radius: vpx(6)
            color: bladePanel.bp_guideBgOn ? bladePanel.bp_editorAccentColor : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.18)
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1)
            Behavior on color { ColorAnimation { duration: 80 } }
            Row { anchors.centerIn: parent; spacing: vpx(4)
              Rectangle { width: vpx(10); height: vpx(10); radius: vpx(2); anchors.verticalCenter: parent.verticalCenter
                color: bladePanel.bp_guideBgOn ? "#fff" : Qt.rgba(1,1,1,0.25); border.color: "#fff"; border.width: vpx(1)
                StyledText { anchors.centerIn: parent; text: bladePanel.bp_guideBgOn ? "✓" : ""; font.pixelSize: vpx(7); color: Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,1.0); layer.enabled: false } }
              StyledText { text: "Guide"; font.pixelSize: vpx(11); font.bold: true; color: "#fff"; layer.enabled: false; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { bladePanel.bp_guideBgOn = !bladePanel.bp_guideBgOn; api.memory.set("cfg.guideBgOn", bladePanel.bp_guideBgOn ? "true" : "false") } }
          }

          // Settings Guide
          Rectangle {
            id: footGuideSettingsBtn
            height: vpx(26); width: vpx(80); radius: vpx(6)
            color: (bladePanel.bp_appearanceOpen || footGuideSettingsMA.containsMouse) ? bladePanel.bp_editorAccentColor : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30)
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1)
            Behavior on color { ColorAnimation { duration: 80 } }
            Row { anchors.centerIn: parent; spacing: vpx(5)
              StyledText { text: bladePanel.bp_appearanceOpen ? "✕" : "⚙"; font.pixelSize: vpx(12); color: "#fff"; layer.enabled: false; anchors.verticalCenter: parent.verticalCenter }
              StyledText { text: "Guide"; font.pixelSize: vpx(11); font.bold: true; color: "#fff"; layer.enabled: false; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { id: footGuideSettingsMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: { bladePanel.bp_appearanceOpen = !bladePanel.bp_appearanceOpen; bladePanel.bp_tabPreviewOpen = false } }
          }
        }
      }

      // ── Theme Info HUD — pinned direct child of bladePanel (matches genredetails) ──
      Rectangle {
        id: bp_themeInfoHud
        visible: !bladePanel.bp_guideBgPickerOpen
        anchors.left: parent.left
        anchors.bottom: tabsBladeFooter.top
        anchors.bottomMargin: vpx(25)
        anchors.leftMargin: vpx(104)
        width: parent.width - vpx(110)
        height: vpx(140)
        radius: vpx(10)
        color: Qt.rgba(0,0,0,0)
        border.color: Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.40); border.width: vpx(1)

        Column {
          anchors { left: parent.left; right: parent.right; top: parent.top; margins: vpx(8) }
          spacing: vpx(3)

          Row { width: parent.width; height: vpx(16); spacing: vpx(8)
            Rectangle { width: vpx(3); height: vpx(12); radius: vpx(2); color: bladePanel.bp_editorAccentColor; anchors.verticalCenter: parent.verticalCenter }
            StyledText { text: "Theme Info"; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: vpx(1); height: vpx(12); color: Qt.rgba(1,1,1,0.25); anchors.verticalCenter: parent.verticalCenter }
            StyledText {
              text: "Mode: " + bladePanel.bp_bgModes[Math.min(bladePanel.bp_bgMode,7)].label + "  |  Preset: " + (bladePanel.bp_presetName !== "" ? bladePanel.bp_presetName : "None")
              font.pixelSize: vpx(10); color: "#AAAAAA"; anchors.verticalCenter: parent.verticalCenter
              elide: Text.ElideRight; width: parent.width - vpx(120)
            }
          }

          Rectangle { width: parent.width; height: vpx(1); color: Qt.rgba(1,1,1,0.12) }

          Row { width: parent.width; spacing: vpx(0)
            // ACCENT COLUMN
            Column { width: (parent.width - vpx(1)) / 2; spacing: vpx(2)
              StyledText { text: "Accent Color"; font.pixelSize: vpx(10); font.bold: true; color: "#AAAAAA" }
              Row { spacing: vpx(8)
                Rectangle { width: vpx(28); height: vpx(28); radius: vpx(6)
                  color: bladePanel.bp_accentColor
                  border.color: Qt.rgba(1,1,1,0.30); border.width: vpx(1) }
                Column { spacing: vpx(2); anchors.verticalCenter: parent.verticalCenter
                  StyledText { text: bladePanel.bp_displayAccentName
                    font.pixelSize: vpx(11); color: bladePanel.bp_editorAccentColor; font.bold: true; elide: Text.ElideRight; width: vpx(125) }
                  StyledText { text: bladePanel.bp_accentHex.toUpperCase()
                    font.pixelSize: vpx(9); color: "#AAAAAA" }
                }
              }
              StyledText { text: "Opacity: " + (100 - bladePanel.bp_accentAlpha) + "%"; font.pixelSize: vpx(10); color: "#CCCCCC" }
              StyledText { text: "Color Gradient: "   + (bladePanel.bp_gradAccentColor   ? "On" : "Off"); font.pixelSize: vpx(10); color: bladePanel.bp_gradAccentColor   ? "#888888" : "#777777" }
              StyledText { text: "Opacity Gradient: " + (bladePanel.bp_gradAccentOpacity ? "On" : "Off"); font.pixelSize: vpx(10); color: bladePanel.bp_gradAccentOpacity ? "#888888" : "#777777" }
            }

            Rectangle { width: vpx(1); height: vpx(100); color: Qt.rgba(1,1,1,0.12); anchors.verticalCenter: parent.verticalCenter }
            Item { width: vpx(8); height: 1 }

            // THEME COLUMN
            Column { width: (parent.width - vpx(1)) / 2 - vpx(8); spacing: vpx(2)
              StyledText { text: "Theme Color"; font.pixelSize: vpx(10); font.bold: true; color: "#AAAAAA" }
              Row { spacing: vpx(8)
                Rectangle { width: vpx(28); height: vpx(28); radius: vpx(6)
                  color: bladePanel.bp_themeFillColor
                  border.color: Qt.rgba(1,1,1,0.30); border.width: vpx(1) }
                Column { spacing: vpx(2); anchors.verticalCenter: parent.verticalCenter
                  StyledText { text: bladePanel.bp_displayThemeName
                    font.pixelSize: vpx(11); color: "#DDDDDD"; font.bold: true; elide: Text.ElideRight; width: vpx(125) }
                  StyledText { text: bladePanel.bp_themeHex.toUpperCase()
                    font.pixelSize: vpx(9); color: "#AAAAAA" }
                }
              }
              StyledText { text: "Transparency: " + bladePanel.bp_ifaceAlpha + "%"; font.pixelSize: vpx(10); color: "#CCCCCC" }
              StyledText { text: "Color Gradient: "        + (bladePanel.bp_gradThemeColor  ? "On" : "Off"); font.pixelSize: vpx(10); color: bladePanel.bp_gradThemeColor  ? "#888888" : "#777777" }
              StyledText { text: "Transparent. Gradient: " + (bladePanel.bp_gradThemeTransp ? "On" : "Off"); font.pixelSize: vpx(10); color: bladePanel.bp_gradThemeTransp ? "#888888" : "#777777" }
            }
          }
        }
      }

      // ── Tab Preview — pinned direct child of bladePanel (matches genredetails) ──
      Rectangle {
        id: bp_tabPreviewPanel
        visible: bladePanel.bp_tabPreviewOpen && !bladePanel.bp_guideBgPickerOpen
        anchors.top: tabsBladeHeader.bottom; anchors.topMargin: vpx(8)
        anchors.bottom: bp_themeInfoHud.top; anchors.bottomMargin: vpx(8)
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: vpx(100); anchors.rightMargin: vpx(10)
        radius: vpx(10)
        color: Qt.rgba(0,0,0,0)
        border.color: bladePanel.bp_editorAccentColor; border.width: vpx(2)
        clip: true
        z: 8

        // Tab title label
        StyledText {
          id: bp_tabPanelTitle
          anchors.top: parent.top; anchors.topMargin: vpx(6)
          anchors.left: parent.left; anchors.leftMargin: vpx(10)
          text: "Tab"; font.pixelSize: vpx(11); font.bold: true; color: "#FFFFFF"
        }

        // ── Tab preview — exact clone of the live panel card ────────
        Item {
          id: bp_tabPreviewInner
          anchors.top: bp_tabPanelTitle.bottom; anchors.topMargin: vpx(4)
          anchors.bottom: bp_tabBtnRow.top; anchors.bottomMargin: vpx(8)
          anchors.left: parent.left; anchors.right: parent.right
          anchors.margins: vpx(6)
          visible: !bladePanel.bp_tabRenameOpen && !bladePanel.bp_tabBgPickerOpen && !bladePanel.bp_tabIconPickerOpen
          z: 0
          // OpacityMask clips ALL children (including LinearGradients) to rounded corners
          layer.enabled: true
          layer.effect: OpacityMask {
            maskSource: Rectangle {
              width: bp_tabPreviewInner.width; height: bp_tabPreviewInner.height
              radius: vpx(panelsList.wrapCornerRadius)
            }
          }

          // ── 1. Tab background image (same as fallbackBackground in live panel) ──
          Image {
            id: bp_tabBgImg
            anchors.fill: parent
            source: bladePanel.currentTab.length > 0
                    ? "../assets/images/tabs/" + bladePanel.currentTab + "/backgrounds/1.png" : ""
            fillMode: Image.PreserveAspectCrop
            opacity: bladePanel.tabsOpacity / 100
            asynchronous: true; cache: false
          }

          // ── 2. Theme colour / gradient layers (matches live panel exactly) ──
          // Dark mode flat fill
          Rectangle {
            anchors.fill: parent; radius: vpx(panelsList.wrapCornerRadius)
            color: bladePanel.bp_themeDark
            visible: bladePanel.bp_themeDarkOn && !bladePanel.bp_activePanelGradient
          }
          // Dark mode gradient
          LinearGradient {
            visible: bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradThemeColor
            anchors.fill: parent; cached: false
            start: Qt.point(0,0); end: Qt.point(width,height)
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(bladePanel.bp_themeDark.r,bladePanel.bp_themeDark.g,bladePanel.bp_themeDark.b,0.97) }
              GradientStop { position:0.6; color:Qt.rgba(bladePanel.bp_themeDark.r*.7,bladePanel.bp_themeDark.g*.7,bladePanel.bp_themeDark.b*.7,0.97) }
              GradientStop { position:1.0; color:Qt.rgba(bladePanel.bp_themeDark.r*.5,bladePanel.bp_themeDark.g*.5,bladePanel.bp_themeDark.b*.5,0.97) }
            }
          }
          // Dark mode transparency gradient
          LinearGradient {
            visible: bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradThemeTransp
            anchors.fill: parent; cached: false
            start: Qt.point(0,height); end: Qt.point(0,0)
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(0,0,0,0.18) }
              GradientStop { position:1.0; color:Qt.rgba(0,0,0,0.0) }
            }
          }
          // Dark mode accent gradient
          LinearGradient {
            visible: bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradAccentColor
            anchors.fill: parent; cached: false
            start: Qt.point(0,0); end: Qt.point(width,0)
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.12) }
              GradientStop { position:1.0; color:"transparent" }
            }
          }
          // Dark mode accent opacity gradient
          LinearGradient {
            visible: bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradAccentOpacity
            anchors.fill: parent; cached: false
            start: Qt.point(0,0); end: Qt.point(0,height)
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.08) }
              GradientStop { position:1.0; color:"transparent" }
            }
          }
          // Light mode flat fill
          Rectangle {
            anchors.fill: parent; radius: vpx(panelsList.wrapCornerRadius)
            color: bladePanel.bp_editorThemeFillColor
            visible: !bladePanel.bp_themeDarkOn && !bladePanel.bp_activePanelGradient
          }
          // Light mode gradient
          LinearGradient {
            visible: !bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradThemeColor
            anchors.fill: parent; cached: false
            start: Qt.point(0,0); end: Qt.point(width,height)
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(bladePanel.bp_editorThemeFillColor.r,bladePanel.bp_editorThemeFillColor.g,bladePanel.bp_editorThemeFillColor.b,bladePanel.bp_panelAlpha) }
              GradientStop { position:0.6; color:Qt.rgba(bladePanel.bp_editorThemeFillColor.r*.7,bladePanel.bp_editorThemeFillColor.g*.7,bladePanel.bp_editorThemeFillColor.b*.7,bladePanel.bp_panelAlpha) }
              GradientStop { position:1.0; color:Qt.rgba(bladePanel.bp_editorThemeFillColor.r*.5,bladePanel.bp_editorThemeFillColor.g*.5,bladePanel.bp_editorThemeFillColor.b*.5,bladePanel.bp_panelAlpha) }
            }
          }
          // Light mode theme-transparency gradient
          LinearGradient {
            visible: !bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradThemeTransp
            anchors.fill: parent; cached: false
            start: Qt.point(0,height); end: Qt.point(0,0)
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(0,0,0,0.18) }
              GradientStop { position:1.0; color:Qt.rgba(0,0,0,0.0) }
            }
          }
          // Light mode accent gradient
          LinearGradient {
            visible: !bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradAccentColor
            anchors.fill: parent; cached: false
            start: Qt.point(0,0); end: Qt.point(width,0)
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.12) }
              GradientStop { position:1.0; color:"transparent" }
            }
          }
          // Light mode accent opacity gradient
          LinearGradient {
            visible: !bladePanel.bp_themeDarkOn && bladePanel.bp_activePanelGradient && bladePanel.bp_activeGradAccentOpacity
            anchors.fill: parent; cached: false
            start: Qt.point(0,0); end: Qt.point(0,height)
            gradient: Gradient {
              GradientStop { position:0.0; color:Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.08) }
              GradientStop { position:1.0; color:"transparent" }
            }
          }

          // ── 3. Icon — same as live panel: anchors.fill with vpx(30) margins ──
          Image {
            id: bp_tabIconImg
            anchors.fill: parent
            anchors.leftMargin: vpx(30); anchors.rightMargin: vpx(30)
            anchors.topMargin: vpx(30); anchors.bottomMargin: vpx(30)
            fillMode: Image.PreserveAspectFit
            source: bladePanel.currentTabIcon
            sourceSize.width: width; sourceSize.height: height
            asynchronous: true; cache: false
            visible: bladePanel.currentTabIcon.length > 0
          }

          // ── 4. Bottom gradient + title — identical to genericPanelOverlay ──
          LinearGradient {
            anchors.fill: parent
            start: Qt.point(0, 0); end: Qt.point(0, parent.height)
            gradient: Gradient {
              GradientStop { position: 0.64; color: "#00000000" }
              GradientStop { position: 1;    color: "#DD000000" }
            }
          }
          StyledText {
            id: bp_previewSummary
            font.pixelSize: vpx(21); text: ""
            anchors.bottom: parent.bottom
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: vpx(18); anchors.rightMargin: vpx(18)
            anchors.bottomMargin: vpx(15)
            opacity: 0; visible: false  // no summary in preview, keeps layout intact
          }
          StyledText {
            font.pixelSize: vpx(panelsList.libTitleSize)
            text: bladePanel.bp_panelTitle
            visible: panelsList.libTitleVisible
            anchors.bottom: bp_previewSummary.top
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: vpx(18) + panelsList.libTitleOffsetX
            anchors.rightMargin: vpx(18) - panelsList.libTitleOffsetX
            anchors.bottomMargin: vpx(4) + panelsList.libTitleOffsetY
            elide: Text.ElideRight; font.bold: true
            color: panelsList.libTitleColorMode === 1 ? bladePanel.bp_editorAccentColor
                 : panelsList.libTitleColorMode === 2 ? "#000000"
                 : "#ffffff"
          }

          // ── 5. Accent border (same as live panel selected state) ──
          Rectangle {
            anchors.fill: parent; color: "transparent"
            visible: bladePanel.tabBorderOn
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(3)
            radius: vpx(panelsList.wrapCornerRadius)
          }
        }

        // ── Rename overlay ────────────────────────────────────────
        Item {
          anchors.top: bp_tabPanelTitle.bottom; anchors.topMargin: vpx(4)
          anchors.bottom: bp_tabBtnRow.top; anchors.bottomMargin: vpx(8)
          anchors.left: parent.left; anchors.right: parent.right
          anchors.margins: vpx(10)
          z: 1
          visible: bladePanel.bp_tabRenameOpen

          Column {
            anchors.centerIn: parent; spacing: vpx(10); width: parent.width
            StyledText {
              text: "Rename Tab"
              font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF"
              anchors.horizontalCenter: parent.horizontalCenter
            }
            Rectangle {
              width: parent.width; height: vpx(32); radius: vpx(6)
              color: Qt.rgba(1,1,1,0.10); border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1)
              TextInput {
                id: bp_renameInput
                anchors.fill: parent; anchors.margins: vpx(6)
                text: bladePanel.bp_tabRenameText
                color: "#ffffff"; font.pixelSize: vpx(13); font.bold: true
                selectionColor: bladePanel.bp_editorAccentColor; cursorVisible: true
                focus: bladePanel.bp_tabRenameOpen
                onTextChanged: bladePanel.bp_tabRenameText = text
              }
            }
            Row {
              anchors.horizontalCenter: parent.horizontalCenter; spacing: vpx(8)
              Rectangle {
                height: vpx(24); width: bp_renameSaveLbl.implicitWidth + vpx(16); radius: vpx(5)
                color: bp_renameSaveMA.containsMouse ? bladePanel.bp_editorAccentColor : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30)
                border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1)
                Behavior on color { ColorAnimation { duration: 80 } }
                StyledText { id: bp_renameSaveLbl; anchors.centerIn: parent; text: "Save"; font.pixelSize: vpx(10); font.bold: true; color: "#fff"; layer.enabled: false }
                MouseArea { id: bp_renameSaveMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    // Save the new panel display name and update bp_panelTitle
                    bladePanel.bp_panelTitle = bladePanel.bp_tabRenameText
                    api.memory.set("panelTitle." + panelsList.currentIndex, bladePanel.bp_tabRenameText)
                    bladePanel.bp_tabRenameOpen = false
                  } }
              }
              Rectangle {
                height: vpx(24); width: bp_renameCancelLbl.implicitWidth + vpx(16); radius: vpx(5)
                color: bp_renameCancelMA.containsMouse ? Qt.rgba(0.6,0.2,0.2,0.7) : Qt.rgba(1,1,1,0.10)
                border.color: Qt.rgba(1,1,1,0.25); border.width: vpx(1)
                Behavior on color { ColorAnimation { duration: 80 } }
                StyledText { id: bp_renameCancelLbl; anchors.centerIn: parent; text: "Cancel"; font.pixelSize: vpx(10); font.bold: true; color: "#fff"; layer.enabled: false }
                MouseArea { id: bp_renameCancelMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: bladePanel.bp_tabRenameOpen = false }
              }
            }
          }
        }

        // ── Icon picker overlay — icon sets from assets/images/icons/ ───────
        Item {
          anchors.top: bp_tabPanelTitle.bottom; anchors.topMargin: vpx(4)
          anchors.bottom: bp_tabBtnRow.top; anchors.bottomMargin: vpx(8)
          anchors.left: parent.left; anchors.right: parent.right
          anchors.margins: vpx(6)
          z: 1
          visible: bladePanel.bp_tabIconPickerOpen
          clip: true
          onVisibleChanged: { if (visible && bp_iconModel.count === 0) bladePanel.bp_loadIconImages() }

          property real tileW: (width - 3*vpx(4)) / 4
          property real tileH: tileW

          Flickable {
            anchors.fill: parent
            contentHeight: Math.ceil(bp_iconModel.count / 4) * (parent.tileH + vpx(4) + vpx(14))
            clip: true; flickableDirection: Flickable.VerticalFlick; interactive: true
            Repeater {
              model: bp_iconModel
              delegate: Item {
                property string setName: itemName
                property bool isSel: bladePanel.bp_currentIcon === setName
                property int col: index % 4
                property int row: Math.floor(index / 4)
                x: col * (parent.parent.tileW + vpx(4))
                y: row * (parent.parent.tileH + vpx(4) + vpx(14))
                width: parent.parent.tileW; height: parent.parent.tileH + vpx(14)

                Rectangle {
                  anchors.fill: parent; radius: vpx(4)
                  color: isSel ? Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30) : Qt.rgba(0,0,0,0.25)
                  border.color: isSel ? bladePanel.bp_editorAccentColor : Qt.rgba(1,1,1,0.15)
                  border.width: isSel ? vpx(2) : vpx(1)
                  Image {
                    anchors.top: parent.top; anchors.topMargin: vpx(3)
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - vpx(6); height: parent.height - vpx(18)
                    fillMode: Image.PreserveAspectFit; asynchronous: true
                    source: "../assets/images/icons/" + setName + "/icons/Controller.png"
                  }
                  StyledText {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: vpx(2)
                    anchors.left: parent.left; anchors.right: parent.right
                    text: setName; font.pixelSize: vpx(7); color: "#fff"
                    horizontalAlignment: Text.AlignHCenter; layer.enabled: false
                    elide: Text.ElideRight
                  }
                  Rectangle {
                    visible: isSel
                    anchors.top: parent.top; anchors.right: parent.right; anchors.margins: vpx(2)
                    width: vpx(12); height: vpx(12); radius: vpx(6); color: bladePanel.bp_editorAccentColor
                    StyledText { anchors.centerIn: parent; text: "✓"; font.pixelSize: vpx(7); color: "#fff"; layer.enabled: false }
                  }
                }
                MouseArea { anchors.fill: parent; z: 1; cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    bladePanel.bp_currentIcon = setName
                    api.memory.set("cfg.currentIcon", setName)
                    api.memory.set("currentIcon", setName)
                    bladePanel.bp_tabIconPickerOpen = false
                  }
                }
              }
            }
          }
        }

        // ── Background picker overlay — pick tab background from available tabs ─────
        Item {
          anchors.top: bp_tabPanelTitle.bottom; anchors.topMargin: vpx(4)
          anchors.bottom: bp_tabBtnRow.top; anchors.bottomMargin: vpx(8)
          anchors.left: parent.left; anchors.right: parent.right
          anchors.margins: vpx(6)
          z: 1
          visible: bladePanel.bp_tabBgPickerOpen
          clip: true

          property real tileW: (width - 3*vpx(4)) / 4
          property real tileH: tileW * 1.3

          Flickable {
            anchors.fill: parent
            contentHeight: Math.ceil(bp_tabBgModel.count / 4) * (parent.tileH + vpx(4) + vpx(12))
            clip: true; flickableDirection: Flickable.VerticalFlick; interactive: true
            Repeater {
              model: bp_tabBgModel
              delegate: Item {
                property string tabName: itemName || ""
                property bool isSel: bladePanel.currentTab === tabName
                property int col: index % 4
                property int row: Math.floor(index / 4)
                x: col * (parent.parent.tileW + vpx(4))
                y: row * (parent.parent.tileH + vpx(4) + vpx(12))
                width: parent.parent.tileW; height: parent.parent.tileH + vpx(12)
                Rectangle {
                  anchors.fill: parent; radius: vpx(4)
                  color: Qt.rgba(0,0,0,0)
                  border.color: isSel ? bladePanel.bp_editorAccentColor : Qt.rgba(1,1,1,0.20)
                  border.width: isSel ? vpx(2) : vpx(1)
                  clip: true
                  Image {
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                    anchors.bottom: bgLabel.top; anchors.margins: vpx(2)
                    source: tabName.length > 0 ? "../assets/images/tabs/" + tabName + "/backgrounds/1.png" : ""
                    fillMode: Image.PreserveAspectCrop; asynchronous: true; smooth: true
                  }
                  StyledText {
                    id: bgLabel
                    anchors.bottom: parent.bottom; anchors.bottomMargin: vpx(2)
                    anchors.left: parent.left; anchors.right: parent.right
                    text: tabName; font.pixelSize: vpx(7); color: "#fff"
                    style: Text.Outline; styleColor: "#000"
                    horizontalAlignment: Text.AlignHCenter; layer.enabled: false; elide: Text.ElideRight
                  }
                  Rectangle {
                    visible: isSel
                    anchors.top: parent.top; anchors.right: parent.right; anchors.margins: vpx(2)
                    width: vpx(12); height: vpx(12); radius: vpx(6); color: bladePanel.bp_editorAccentColor
                    StyledText { anchors.centerIn: parent; text: "✓"; font.pixelSize: vpx(7); color: "#fff"; layer.enabled: false }
                  }
                }
                MouseArea {
                  anchors.fill: parent; z: 1; cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    bladePanel.currentTab = tabName
                    api.memory.set("currentTab", tabName)
                    bladePanel.bp_tabBgPickerOpen = false
                  }
                }
              }
            }
          }
        }

        // ── Button row ────────────────────────────────────────────
        Row {
          id: bp_tabBtnRow
          anchors.bottom: parent.bottom; anchors.bottomMargin: vpx(8)
          anchors.left: parent.left; anchors.leftMargin: vpx(8)
          spacing: vpx(5)

          // Create
          Rectangle {
            height: vpx(22); width: bp_tabCreateLbl.implicitWidth + vpx(12); radius: vpx(5)
            color: bp_tabCreateMA.containsMouse ? bladePanel.bp_editorAccentColor : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30)
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1); Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { id: bp_tabCreateLbl; anchors.centerIn: parent; text: "Create"; font.pixelSize: vpx(10); font.bold: true; color: "#fff"; layer.enabled: false }
            MouseArea { id: bp_tabCreateMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
          }
          // Edit
          Rectangle {
            height: vpx(22); width: bp_tabEditLbl.implicitWidth + vpx(12); radius: vpx(5)
            color: bp_tabEditMA.containsMouse ? bladePanel.bp_editorAccentColor : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30)
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1); Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { id: bp_tabEditLbl; anchors.centerIn: parent; text: "Edit"; font.pixelSize: vpx(10); font.bold: true; color: "#fff"; layer.enabled: false }
            MouseArea { id: bp_tabEditMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
          }
          // Rename
          Rectangle {
            height: vpx(22); width: bp_tabRenameLbl.implicitWidth + vpx(12); radius: vpx(5)
            color: bladePanel.bp_tabRenameOpen ? bladePanel.bp_editorAccentColor : (bp_tabRenameBtnMA.containsMouse ? bladePanel.bp_editorAccentColor : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30))
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1); Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { id: bp_tabRenameLbl; anchors.centerIn: parent; text: "Rename"; font.pixelSize: vpx(10); font.bold: true; color: "#fff"; layer.enabled: false }
            MouseArea { id: bp_tabRenameBtnMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: { bladePanel.bp_tabRenameText = bladePanel.bp_panelTitle; bladePanel.bp_tabBgPickerOpen = false; bladePanel.bp_tabIconPickerOpen = false; bladePanel.bp_tabRenameOpen = !bladePanel.bp_tabRenameOpen } }
          }
          // Delete
          Rectangle {
            height: vpx(22); width: bp_tabDeleteLbl.implicitWidth + vpx(12); radius: vpx(5)
            color: bp_tabDeleteMA.containsMouse ? Qt.rgba(0.8,0.2,0.2,0.8) : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30)
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1); Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { id: bp_tabDeleteLbl; anchors.centerIn: parent; text: "Delete"; font.pixelSize: vpx(10); font.bold: true; color: "#fff"; layer.enabled: false }
            MouseArea { id: bp_tabDeleteMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
          }
          // Icon
          Rectangle {
            height: vpx(22); width: bp_tabIconLbl.implicitWidth + vpx(12); radius: vpx(5)
            color: bladePanel.bp_tabIconPickerOpen ? bladePanel.bp_editorAccentColor : (bp_tabIconBtnMA.containsMouse ? bladePanel.bp_editorAccentColor : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30))
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1); Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { id: bp_tabIconLbl; anchors.centerIn: parent; text: "Icon"; font.pixelSize: vpx(10); font.bold: true; color: "#fff"; layer.enabled: false }
            MouseArea { id: bp_tabIconBtnMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: {
                bladePanel.bp_tabBgPickerOpen = false; bladePanel.bp_tabRenameOpen = false
                if (bp_iconModel.count === 0) bladePanel.bp_loadIconImages()
                bladePanel.bp_tabIconPickerOpen = !bladePanel.bp_tabIconPickerOpen
              } }
          }
          // Background
          Rectangle {
            height: vpx(22); width: bp_tabBgLbl.implicitWidth + vpx(12); radius: vpx(5)
            color: bladePanel.bp_tabBgPickerOpen ? bladePanel.bp_editorAccentColor : (bp_tabBgBtnMA.containsMouse ? bladePanel.bp_editorAccentColor : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30))
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1); Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { id: bp_tabBgLbl; anchors.centerIn: parent; text: "Background"; font.pixelSize: vpx(10); font.bold: true; color: "#fff"; layer.enabled: false }
            MouseArea { id: bp_tabBgBtnMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: {
                bladePanel.bp_tabRenameOpen = false; bladePanel.bp_tabIconPickerOpen = false
                if (bp_tabBgModel.count === 0) bladePanel.bp_loadTabBgImages()
                bladePanel.bp_tabBgPickerOpen = !bladePanel.bp_tabBgPickerOpen
              } }
          }
          // Save
          Rectangle {
            height: vpx(22); width: bp_tabSaveLbl.implicitWidth + vpx(12); radius: vpx(5)
            color: bp_tabSaveMA.containsMouse ? bladePanel.bp_editorAccentColor : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30)
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1); Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { id: bp_tabSaveLbl; anchors.centerIn: parent; text: "Save"; font.pixelSize: vpx(10); font.bold: true; color: "#fff"; layer.enabled: false }
            MouseArea { id: bp_tabSaveMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (bladePanel.bp_tabRenameOpen) {
                  bladePanel.bp_panelTitle = bladePanel.bp_tabRenameText
                  api.memory.set("panelTitle." + panelsList.currentIndex, bladePanel.bp_tabRenameText)
                  bladePanel.bp_tabRenameOpen = false
                }
                if (bladePanel.bp_tabBgPickerOpen) { api.memory.set("cfg.guideBackground", bladePanel.bp_guideBackground); bladePanel.bp_tabBgPickerOpen = false }
              }
            }
          }
          // Close
          Rectangle {
            height: vpx(22); width: bp_tabCloseLbl.implicitWidth + vpx(12); radius: vpx(5)
            color: bp_tabCloseMA.containsMouse ? Qt.rgba(0.2,0.2,0.8,0.8) : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30)
            border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1); Behavior on color { ColorAnimation { duration: 80 } }
            StyledText { id: bp_tabCloseLbl; anchors.centerIn: parent; text: "Close"; font.pixelSize: vpx(10); font.bold: true; color: "#fff"; layer.enabled: false }
            MouseArea { id: bp_tabCloseMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (bladePanel.bp_tabRenameOpen)     { bladePanel.bp_tabRenameOpen = false; return }
                if (bladePanel.bp_tabBgPickerOpen)   { bladePanel.bp_tabBgPickerOpen = false; return }
                if (bladePanel.bp_tabIconPickerOpen) { bladePanel.bp_tabIconPickerOpen = false; return }
                bladePanel.bp_tabPreviewOpen = false
              }
            }
          }
        }
      }

      // ── Guide Background Picker — overlays full blade when open ──
      Rectangle {
        id: bp_guidePicker
        visible: bladePanel.bp_guideBgPickerOpen
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.02, 0.05, 0.98)
        radius: vpx(16)
        clip: true
        z: 10

        // Header
        Item {
          id: bp_pickerHdr
          anchors { top: parent.top; left: parent.left; right: parent.right }
          height: vpx(52)

          Row {
            anchors { left: parent.left; leftMargin: vpx(14); verticalCenter: parent.verticalCenter }
            spacing: vpx(10)
            Rectangle { width: vpx(4); height: vpx(26); radius: vpx(2); color: bladePanel.bp_editorAccentColor; anchors.verticalCenter: parent.verticalCenter }
            StyledText { text: "Guide Background"; font.pixelSize: vpx(14); font.bold: true; color: "#ffffff"; anchors.verticalCenter: parent.verticalCenter }
            Item { width: vpx(10); height: 1 }
            // Save button
            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              height: vpx(26); width: vpx(56); radius: vpx(6)
              color: bp_pickerSaveMA.containsMouse ? bladePanel.bp_editorAccentColor : Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.30)
              border.color: bladePanel.bp_editorAccentColor; border.width: vpx(1)
              Behavior on color { ColorAnimation { duration: 80 } }
              StyledText { anchors.centerIn: parent; text: "Save"; font.pixelSize: vpx(11); font.bold: true; color: "#fff"; layer.enabled: false }
              MouseArea { id: bp_pickerSaveMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { api.memory.set("cfg.guideBackground", bladePanel.bp_guideBackground); bladePanel.bp_guideBgPickerOpen = false } }
            }
            // Back button
            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              height: vpx(26); width: vpx(56); radius: vpx(6)
              color: bp_pickerBackMA.containsMouse ? Qt.rgba(0.8,0.2,0.2,0.8) : Qt.rgba(1,1,1,0.12)
              border.color: Qt.rgba(1,1,1,0.25); border.width: vpx(1)
              Behavior on color { ColorAnimation { duration: 80 } }
              StyledText { anchors.centerIn: parent; text: "Back"; font.pixelSize: vpx(11); font.bold: true; color: "#fff"; layer.enabled: false }
              MouseArea { id: bp_pickerBackMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: bladePanel.bp_guideBgPickerOpen = false }
            }
          }

          Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: vpx(14); rightMargin: vpx(14) }
            height: vpx(1); color: bladePanel.bp_editorAccentColor
          }
        }

        // 3-column scrollable image grid
        Item {
          id: bp_pickerGrid
          anchors.top: bp_pickerHdr.bottom
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.topMargin: vpx(8)
          anchors.bottomMargin: vpx(8)
          anchors.leftMargin: vpx(10)
          anchors.rightMargin: vpx(10)
          clip: true

          property real tileW: (width - vpx(12)) / 3
          property real tileH: tileW * 1.4

          Flickable {
            anchors.fill: parent
            contentHeight: Math.ceil(bp_guideModel.count / 3) * (bp_pickerGrid.tileH + vpx(6))
            clip: true; interactive: true; flickableDirection: Flickable.VerticalFlick

            Repeater {
              model: bp_guideModel
              delegate: Item {
                property string imgName:    itemName
                property bool   isSelected: bladePanel.bp_guideBackground === imgName
                property int    col:        index % 3
                property int    row:        Math.floor(index / 3)
                x: col * (bp_pickerGrid.tileW + vpx(6))
                y: row * (bp_pickerGrid.tileH + vpx(6))
                width: bp_pickerGrid.tileW; height: bp_pickerGrid.tileH

                // Selection highlight border
                Rectangle {
                  anchors.fill: parent; radius: vpx(6)
                  color: isSelected ? Qt.rgba(bladePanel.bp_editorAccentColor.r,bladePanel.bp_editorAccentColor.g,bladePanel.bp_editorAccentColor.b,0.35) : Qt.rgba(0,0,0,0)
                  border.color: isSelected ? bladePanel.bp_editorAccentColor : Qt.rgba(1,1,1,0.25)
                  border.width: isSelected ? vpx(3) : vpx(1)
                }

                // Image thumbnail
                Rectangle {
                  anchors { fill: parent; margins: vpx(3) }
                  radius: vpx(4); clip: true; color: Qt.rgba(0,0,0,0)
                  Image {
                    anchors.fill: parent
                    source: "../assets/images/guides/" + imgName + ".png"
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true; smooth: true
                  }
                }

                // Name label
                StyledText {
                  anchors { top: parent.top; topMargin: vpx(6); left: parent.left; leftMargin: vpx(6); right: parent.right; rightMargin: vpx(6) }
                  text: imgName; font.pixelSize: vpx(9); font.bold: true; color: "#ffffff"
                  style: Text.Outline; styleColor: "#000000"
                  elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; layer.enabled: false
                }

                // Checkmark badge
                Rectangle {
                  visible: isSelected
                  anchors { top: parent.top; right: parent.right; topMargin: vpx(5); rightMargin: vpx(5) }
                  width: vpx(18); height: vpx(18); radius: vpx(9); color: bladePanel.bp_editorAccentColor
                  StyledText { anchors.centerIn: parent; text: "✓"; font.pixelSize: vpx(10); font.bold: true; color: "#fff"; layer.enabled: false }
                }

                MouseArea {
                  anchors.fill: parent; cursorShape: Qt.PointingHandCursor; z: 1
                  onClicked: { bladePanel.bp_guideBackground = imgName; api.memory.set("cfg.guideBackground", imgName) }
                }
              }
            }
          }
        }
      }
    }
  }

  // LAYOUT INFO CARD — shows info for the active slot (ℹ button on slots)
  Rectangle {
    id: layoutInfoWin
    visible: panelsList.edLayoutInfoOpen
    width: vpx(420)
    height: infoMainCol.implicitHeight + vpx(12)
    x: 80; y: 80
    color: Qt.rgba(0.04, 0.06, 0.12, 0.96)
    border.width: vpx(1); border.color: Qt.rgba(0.3,0.6,1.0,0.35)
    radius: vpx(6)
    z: 99998

    TextEdit { id: infoCopyClip; visible: false; width: 0; height: 0
      function copyText(t) { text = t; selectAll(); copy(); text = ""; } }

    property var activeSlotData: {
      var idx = panelsList.edActiveSlot;
      if (idx >= 1 && idx < panelsList.edSavedSlots.length) return panelsList.edSavedSlots[idx];
      return { name: "", data: "", layoutName: "" };
    }

    Column {
      id: infoMainCol
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: vpx(6) }
      spacing: vpx(3)

      // Title bar
      Item {
        width: parent.width; height: vpx(16)
        Row { anchors.verticalCenter: parent.verticalCenter; spacing: vpx(4)
          StyledText { text: "i"; font.pixelSize: vpx(9); font.bold: true; color: "#88ccff" }
          StyledText { text: "|"; font.pixelSize: vpx(8); color: Qt.rgba(0.4,0.6,1.0,0.4) }
          StyledText { text: "Slot Info"; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
          StyledText {
            text: panelsList.edActiveSlot >= 1 ? ("  · Slot " + panelsList.edActiveSlot) : ""
            font.pixelSize: vpx(8); font.bold: true; color: bladePanel.bp_editorAccentColor
          }
        }
        Rectangle { id: closeInfoBtn; width: vpx(16); height: vpx(16); radius: vpx(3)
          anchors { verticalCenter: parent.verticalCenter; right: parent.right }
          color: Qt.rgba(0.8,0.3,0.3,0.6); border.color: "#cc5555"; border.width: vpx(1)
          StyledText { anchors.centerIn: parent; text: "X"; font.pixelSize: vpx(7); font.bold: true; color: "#ffffff" }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: panelsList.edLayoutInfoOpen = false }
        }
        MouseArea {
          anchors { left: parent.left; right: closeInfoBtn.left; top: parent.top; bottom: parent.bottom }
          drag.target: layoutInfoWin; drag.axis: Drag.XandYAxis
        }
      }

      Rectangle { width: parent.width; height: vpx(1); color: Qt.rgba(0.3,0.6,1.0,0.25) }

      // Slot name + layout type
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "NAME:"; font.pixelSize: vpx(7); font.bold: true; color: "#88ccff"; width: vpx(46) }
        StyledText {
          text: layoutInfoWin.activeSlotData.name || "—"
          font.pixelSize: vpx(7); font.bold: true; color: bladePanel.bp_editorAccentColor; width: parent.width - vpx(46)
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "TYPE:"; font.pixelSize: vpx(7); font.bold: true; color: "#88ccff"; width: vpx(46) }
        StyledText {
          text: layoutInfoWin.activeSlotData.layoutName || "—"
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46)
        }
      }

      // Parse and display key values from JSON data
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "DATA:"; font.pixelSize: vpx(7); font.bold: true; color: "#88ccff"; width: vpx(46) }
        StyledText {
          text: {
            var d = layoutInfoWin.activeSlotData.data;
            if (!d || d === "") return "empty";
            try {
              var o = JSON.parse(d);
              var parts = [];
              if (o.lm  !== undefined) parts.push("lm="   + o.lm);
              if (o.sx  !== undefined) parts.push("selX=" + Math.round(o.sx));
              if (o.sp  !== undefined) parts.push("sp="   + Math.round(o.sp));
              if (o.arc !== undefined) parts.push("arc="  + o.arc.toFixed(3));
              if (o.base!== undefined) parts.push("base=" + o.base.toFixed(3));
              if (o.flat!== undefined && o.flat) parts.push("flat");
              if (o.yd  !== undefined) parts.push("yd="   + Math.round(o.yd));
              if (o.vb  !== undefined) parts.push("vis="  + o.vb);
              if (o.vc  !== undefined) parts.push("visC=" + o.vc);
              return parts.length > 0 ? parts.join(" | ") : "v=" + (o.v || "?");
            } catch(e) { return "parse error"; }
          }
          font.pixelSize: vpx(7); color: "#ccffcc"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "LIVE:"; font.pixelSize: vpx(7); font.bold: true; color: "#88ff88"; width: vpx(46) }
        StyledText {
          text: "selX=" + Math.round(panelsList.selectedX) + " | sp=" + Math.round(panelsList.spacingOverride)
              + " | arc=" + panelsList.scaleStep.toFixed(3) + " | base=" + panelsList.uniBaseScale.toFixed(3)
              + " | flat=" + panelsList.flatMode + " | yd=" + Math.round(panelsList.yDropPerSlot)
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "ED*:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffcc44"; width: vpx(46) }
        StyledText {
          text: "edSelX=" + Math.round(panelsList.edSelectedX) + " | edFlat=" + panelsList.edFlatMode
              + " | edArc=" + panelsList.edScaleStep.toFixed(3) + " | edSp=" + Math.round(panelsList.edSpacing)
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "SCALE:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffaaaa"; width: vpx(46) }
        StyledText {
          text: "uniBase=" + panelsList.uniBaseScale.toFixed(3) + " | edBase=" + panelsList.edBaseScale.toFixed(3)
              + " | edCenter=" + panelsList.edCenterScale.toFixed(3) + " | globalY=" + Math.round(panelsList.globalYOffset)
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "MODE:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffcc88"; width: vpx(46) }
        StyledText {
          text: "layoutMode=" + panelsList.layoutMode + " | activeSlot=" + panelsList.edActiveSlot
              + " | slotLoaded=" + panelsList.edSlotIsLoaded + " | useEdPath=" + panelsList.useEdPath
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "STATE:"; font.pixelSize: vpx(7); font.bold: true; color: "#cc88ff"; width: vpx(46) }
        StyledText {
          text: "customLoaded=" + panelsList.edCustomIsLoaded + " | tmplStaged=" + panelsList.edTemplateStaged
              + " | _slotEver=" + panelsList._slotEverLoaded + " | _closing=" + panelsList._closingEditor
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }

      // Separator + action buttons row (inside card, above border)
      Rectangle { width: parent.width; height: vpx(1); color: Qt.rgba(0.3,0.6,1.0,0.18) }

      Item {
        width: parent.width; height: vpx(18)
        Row {
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          spacing: vpx(4)

          // EXPORT current live layout as packed JSON
          Rectangle {
            id: infoExportLayoutBtn; height: vpx(14); radius: vpx(3); width: vpx(90)
            color: Qt.rgba(0.4,0.2,0.7,0.5); border.color: "#9955ff"; border.width: vpx(1)
            property bool exported: false
            StyledText { anchors.centerIn: parent
              text: infoExportLayoutBtn.exported ? "✓ Exported" : "⬆ Export Layout"
              font.pixelSize: vpx(7); font.bold: true; color: infoExportLayoutBtn.exported ? "#ccffcc" : "#ddaaff" }
            Timer { id: infoExportLayoutTimer; interval: 1500; onTriggered: infoExportLayoutBtn.exported = false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                var sd = layoutInfoWin.activeSlotData;
                var name = sd.name || ("Slot " + panelsList.edActiveSlot);
                var raw = panelsList.edPackLayout();
                try {
                  var obj = JSON.parse(raw);
                  obj.n = name;
                  var json = JSON.stringify(obj, null, 2);
                  var safeName = name.replace(/[^a-zA-Z0-9_\-]/g, "_");
                  var fileUrl = Qt.resolvedUrl("../layouts/" + safeName + ".json");
                  var xhr = new XMLHttpRequest();
                  xhr.open("PUT", fileUrl, false);
                  xhr.send(json);
                  if (xhr.status !== 200 && xhr.status !== 201) infoCopyClip.copyText(json);
                } catch(e) { infoCopyClip.copyText(raw); }
                infoExportLayoutBtn.exported = true;
                infoExportLayoutTimer.restart();
              }
            }
          }

          // EXPORT slot JSON
          Rectangle {
            id: infoExportBtn; height: vpx(14); radius: vpx(3); width: vpx(80)
            color: Qt.rgba(0.4,0.2,0.7,0.5); border.color: "#9955ff"; border.width: vpx(1)
            property bool exported: false
            StyledText { anchors.centerIn: parent
              text: infoExportBtn.exported ? "✓ Exported" : "⬆ Export JSON"
              font.pixelSize: vpx(7); font.bold: true; color: infoExportBtn.exported ? "#ccffcc" : "#ddaaff" }
            Timer { id: infoExportTimer; interval: 1500; onTriggered: infoExportBtn.exported = false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                var sd = layoutInfoWin.activeSlotData;
                if (!sd.data || sd.data === "") return;
                try {
                  var obj = JSON.parse(sd.data);
                  obj.n = sd.name || ("Slot " + panelsList.edActiveSlot);
                  var json = JSON.stringify(obj, null, 2);
                  var safeName = (sd.name || "slot" + panelsList.edActiveSlot).replace(/[^a-zA-Z0-9_\-]/g, "_");
                  var fileUrl = Qt.resolvedUrl("../layouts/" + safeName + ".json");
                  var xhr = new XMLHttpRequest();
                  xhr.open("PUT", fileUrl, false);
                  xhr.send(json);
                  if (xhr.status !== 200 && xhr.status !== 201) infoCopyClip.copyText(json);
                } catch(e) { infoCopyClip.copyText(sd.data); }
                infoExportBtn.exported = true;
                infoExportTimer.restart();
              }
            }
          }

          // COPY debug info
          Rectangle {
            id: infoCopyBtn; width: vpx(80); height: vpx(14); radius: vpx(3)
            color: Qt.rgba(0.3,0.5,1.0,0.5); border.color: "#4488ff"; border.width: vpx(1)
            property bool copied: false
            StyledText { anchors.centerIn: parent
              text: infoCopyBtn.copied ? "✓ Copied" : "Copy Debug Info"
              font.pixelSize: vpx(7); font.bold: true; color: infoCopyBtn.copied ? "#ccffcc" : "#ffffff" }
            Timer { id: infoCopyTimer; interval: 1500; onTriggered: infoCopyBtn.copied = false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                var sd = layoutInfoWin.activeSlotData;
                var info = "=== Slot " + panelsList.edActiveSlot + " Info ==="
                  + "\nNAME:  " + (sd.name || "—") + "  |  TYPE: " + (sd.layoutName || "—")
                  + "\nDATA:  " + (sd.data || "empty")
                  + "\nLIVE:  selX=" + Math.round(panelsList.selectedX) + " sp=" + Math.round(panelsList.spacingOverride)
                  + " arc=" + panelsList.scaleStep.toFixed(3) + " base=" + panelsList.uniBaseScale.toFixed(3)
                  + " flat=" + panelsList.flatMode + " yd=" + Math.round(panelsList.yDropPerSlot)
                  + "\nED*:   edSelX=" + Math.round(panelsList.edSelectedX) + " edFlat=" + panelsList.edFlatMode
                  + " edArc=" + panelsList.edScaleStep.toFixed(3) + " edSp=" + Math.round(panelsList.edSpacing)
                  + "\nSCALE: uniBase=" + panelsList.uniBaseScale.toFixed(3) + " edBase=" + panelsList.edBaseScale.toFixed(3)
                  + " edCenter=" + panelsList.edCenterScale.toFixed(3) + " globalY=" + Math.round(panelsList.globalYOffset)
                  + "\nMODE:  layoutMode=" + panelsList.layoutMode + " slotLoaded=" + panelsList.edSlotIsLoaded
                  + " useEdPath=" + panelsList.useEdPath
                  + "\nSTATE: customLoaded=" + panelsList.edCustomIsLoaded + " tmplStaged=" + panelsList.edTemplateStaged
                  + " _slotEver=" + panelsList._slotEverLoaded + " _closing=" + panelsList._closingEditor;
                infoCopyClip.copyText(info);
                infoCopyBtn.copied = true;
                infoCopyTimer.restart();
              }
            }
          }
        }
      }
    }
  }

  // CUSTOM INFO CARD — shows info for the selected custom layout (ℹ button on customs)
  Rectangle {
    id: customInfoWin
    visible: panelsList.edCustomInfoOpen
    width: vpx(420)
    height: customInfoMainCol.implicitHeight + vpx(12)
    x: 100; y: 110
    color: Qt.rgba(0.06, 0.04, 0.02, 0.96)
    border.width: vpx(1); border.color: Qt.rgba(1.0,0.6,0.2,0.35)
    radius: vpx(6)
    z: 99998

    TextEdit { id: customInfoCopyClip; visible: false; width: 0; height: 0
      function copyText(t) { text = t; selectAll(); copy(); text = ""; } }

    property var activeCustData: {
      var idx = panelsList.edActiveCustom;
      if (idx >= 0 && idx < panelsList.customLayouts.length)
        return panelsList.customLayouts[idx] || { name: "", data: "" };
      return { name: "", data: "" };
    }

    Column {
      id: customInfoMainCol
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: vpx(6) }
      spacing: vpx(3)

      // Title bar
      Item {
        width: parent.width; height: vpx(16)
        Row { anchors.verticalCenter: parent.verticalCenter; spacing: vpx(4)
          StyledText { text: "i"; font.pixelSize: vpx(9); font.bold: true; color: "#ffbb55" }
          StyledText { text: "|"; font.pixelSize: vpx(8); color: Qt.rgba(1.0,0.6,0.2,0.5) }
          StyledText { text: "Custom Info"; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
          StyledText {
            text: panelsList.edActiveCustom >= 0
              ? ("  · Custom " + (panelsList.edActiveCustom + 1) + " — " + (customInfoWin.activeCustData.name || "Unnamed"))
              : "  · None selected"
            font.pixelSize: vpx(8); font.bold: true; color: "#ee9933"
          }
        }
        Rectangle { id: closeCustomInfoBtn; width: vpx(16); height: vpx(16); radius: vpx(3)
          anchors { verticalCenter: parent.verticalCenter; right: parent.right }
          color: Qt.rgba(0.8,0.3,0.3,0.6); border.color: "#cc5555"; border.width: vpx(1)
          StyledText { anchors.centerIn: parent; text: "X"; font.pixelSize: vpx(7); font.bold: true; color: "#ffffff" }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: panelsList.edCustomInfoOpen = false }
        }
        MouseArea {
          anchors { left: parent.left; right: closeCustomInfoBtn.left; top: parent.top; bottom: parent.bottom }
          drag.target: customInfoWin; drag.axis: Drag.XandYAxis
        }
      }

      Rectangle { width: parent.width; height: vpx(1); color: Qt.rgba(1.0,0.6,0.2,0.25) }

      // Name
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "NAME:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffbb55"; width: vpx(46) }
        StyledText {
          text: customInfoWin.activeCustData.name || "—"
          font.pixelSize: vpx(7); font.bold: true; color: "#ee9933"; width: parent.width - vpx(46)
        }
      }

      // Parse and show key values from the saved JSON
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "DATA:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffbb55"; width: vpx(46) }
        StyledText {
          text: {
            var d = customInfoWin.activeCustData.data;
            if (!d || d === "") return "empty";
            try {
              var o = JSON.parse(d);
              var parts = [];
              if (o.lm   !== undefined) parts.push("lm="   + o.lm);
              if (o.sx   !== undefined) parts.push("selX=" + Math.round(o.sx));
              if (o.sp   !== undefined) parts.push("sp="   + Math.round(o.sp));
              if (o.arc  !== undefined) parts.push("arc="  + Number(o.arc).toFixed(3));
              if (o.base !== undefined) parts.push("base=" + Number(o.base).toFixed(3));
              if (o.flat !== undefined) parts.push("flat=" + o.flat);
              if (o.yd   !== undefined) parts.push("yd="   + Math.round(o.yd));
              if (o.csc  !== undefined) parts.push("csc="  + Number(o.csc).toFixed(3));
              if (o.coy  !== undefined) parts.push("coy="  + Math.round(o.coy));
              if (o.tltc !== undefined) parts.push("tltC=" + o.tltc);
              if (o.tltn !== undefined) parts.push("tltN=" + o.tltn);
              if (o.tltf !== undefined) parts.push("tltF=" + o.tltf);
              return parts.length > 0 ? parts.join(" | ") : "v=" + (o.v || "?");
            } catch(e) { return "parse error"; }
          }
          font.pixelSize: vpx(7); color: "#ffddaa"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }

      // Live state
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "LIVE:"; font.pixelSize: vpx(7); font.bold: true; color: "#88ff88"; width: vpx(46) }
        StyledText {
          text: "selX=" + Math.round(panelsList.selectedX) + " | sp=" + Math.round(panelsList.spacingOverride)
              + " | arc=" + panelsList.scaleStep.toFixed(3) + " | base=" + panelsList.uniBaseScale.toFixed(3)
              + " | flat=" + panelsList.flatMode + " | yd=" + Math.round(panelsList.yDropPerSlot)
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "ED*:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffcc44"; width: vpx(46) }
        StyledText {
          text: "edSelX=" + Math.round(panelsList.edSelectedX) + " | edFlat=" + panelsList.edFlatMode
              + " | edArc=" + panelsList.edScaleStep.toFixed(3) + " | edSp=" + Math.round(panelsList.edSpacing)
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "SCALE:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffaaaa"; width: vpx(46) }
        StyledText {
          text: "uniBase=" + panelsList.uniBaseScale.toFixed(3) + " | edBase=" + panelsList.edBaseScale.toFixed(3)
              + " | edCenter=" + panelsList.edCenterScale.toFixed(3) + " | globalY=" + Math.round(panelsList.globalYOffset)
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "TILT:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffcc88"; width: vpx(46) }
        StyledText {
          text: "center=" + panelsList.edTiltCenter + " | near=" + panelsList.edTiltNear
              + " | far=" + panelsList.edTiltFar + " | asym=" + panelsList.edAsymTilt
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "MODE:"; font.pixelSize: vpx(7); font.bold: true; color: "#cc88ff"; width: vpx(46) }
        StyledText {
          text: "layoutMode=" + panelsList.layoutMode + " | activeCustom=" + panelsList.edActiveCustom
              + " | customLoaded=" + panelsList.edCustomIsLoaded + " | useEdPath=" + panelsList.useEdPath
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }

      Rectangle { width: parent.width; height: vpx(1); color: Qt.rgba(1.0,0.6,0.2,0.18) }

      Item {
        width: parent.width; height: vpx(18)
        Row {
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          spacing: vpx(4)

          // EXPORT current live layout
          Rectangle {
            id: custExportLayoutBtn; height: vpx(14); radius: vpx(3); width: vpx(90)
            color: Qt.rgba(0.4,0.2,0.7,0.5); border.color: "#9955ff"; border.width: vpx(1)
            property bool exported: false
            StyledText { anchors.centerIn: parent
              text: custExportLayoutBtn.exported ? "✓ Exported" : "⬆ Export Layout"
              font.pixelSize: vpx(7); font.bold: true; color: custExportLayoutBtn.exported ? "#ccffcc" : "#ddaaff" }
            Timer { id: custExportLayoutTimer; interval: 1500; onTriggered: custExportLayoutBtn.exported = false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                var name = customInfoWin.activeCustData.name || ("Custom " + (panelsList.edActiveCustom + 1));
                var raw = panelsList.edPackLayout();
                try {
                  var obj = JSON.parse(raw);
                  obj.n = name;
                  var json = JSON.stringify(obj, null, 2);
                  var safeName = name.replace(/[^a-zA-Z0-9_\-]/g, "_");
                  var fileUrl = Qt.resolvedUrl("../layouts/" + safeName + ".json");
                  var xhr = new XMLHttpRequest();
                  xhr.open("PUT", fileUrl, false);
                  xhr.send(json);
                  if (xhr.status !== 200 && xhr.status !== 201) customInfoCopyClip.copyText(json);
                } catch(e) { customInfoCopyClip.copyText(raw); }
                custExportLayoutBtn.exported = true;
                custExportLayoutTimer.restart();
              }
            }
          }

          // EXPORT saved JSON (what's stored in the custom slot)
          Rectangle {
            id: custExportJsonBtn; height: vpx(14); radius: vpx(3); width: vpx(80)
            color: Qt.rgba(0.10,0.35,0.65,0.50); border.color: "#4477cc"; border.width: vpx(1)
            property bool exported: false
            opacity: customInfoWin.activeCustData.data !== "" ? 1.0 : 0.30
            StyledText { anchors.centerIn: parent
              text: custExportJsonBtn.exported ? "✓ Exported" : "⬆ Export JSON"
              font.pixelSize: vpx(7); font.bold: true; color: custExportJsonBtn.exported ? "#ccffcc" : "#aaccff" }
            Timer { id: custExportJsonTimer; interval: 1500; onTriggered: custExportJsonBtn.exported = false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                var d = customInfoWin.activeCustData.data;
                if (!d || d === "") return;
                var name = customInfoWin.activeCustData.name || ("Custom " + (panelsList.edActiveCustom + 1));
                try {
                  var obj = JSON.parse(d);
                  obj.n = name;
                  var json = JSON.stringify(obj, null, 2);
                  var safeName = name.replace(/[^a-zA-Z0-9_\-]/g, "_");
                  var fileUrl = Qt.resolvedUrl("../layouts/" + safeName + ".json");
                  var xhr = new XMLHttpRequest();
                  xhr.open("PUT", fileUrl, false);
                  xhr.send(json);
                  if (xhr.status !== 200 && xhr.status !== 201) customInfoCopyClip.copyText(json);
                } catch(e) { customInfoCopyClip.copyText(d); }
                custExportJsonBtn.exported = true;
                custExportJsonTimer.restart();
              }
            }
          }

          // COPY debug info
          Rectangle {
            id: custInfoCopyBtn; width: vpx(80); height: vpx(14); radius: vpx(3)
            color: Qt.rgba(0.3,0.5,1.0,0.5); border.color: "#4488ff"; border.width: vpx(1)
            property bool copied: false
            StyledText { anchors.centerIn: parent
              text: custInfoCopyBtn.copied ? "✓ Copied" : "Copy Debug Info"
              font.pixelSize: vpx(7); font.bold: true; color: custInfoCopyBtn.copied ? "#ccffcc" : "#ffffff" }
            Timer { id: custInfoCopyTimer; interval: 1500; onTriggered: custInfoCopyBtn.copied = false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                var cd = customInfoWin.activeCustData;
                var info = "=== Custom " + (panelsList.edActiveCustom + 1) + ": " + (cd.name || "Unnamed") + " ==="
                  + "\nDATA:  " + (cd.data || "empty")
                  + "\nLIVE:  selX=" + Math.round(panelsList.selectedX) + " sp=" + Math.round(panelsList.spacingOverride)
                  + " arc=" + panelsList.scaleStep.toFixed(3) + " base=" + panelsList.uniBaseScale.toFixed(3)
                  + " flat=" + panelsList.flatMode + " yd=" + Math.round(panelsList.yDropPerSlot)
                  + "\nED*:   edSelX=" + Math.round(panelsList.edSelectedX) + " edFlat=" + panelsList.edFlatMode
                  + " edArc=" + panelsList.edScaleStep.toFixed(3) + " edSp=" + Math.round(panelsList.edSpacing)
                  + "\nSCALE: uniBase=" + panelsList.uniBaseScale.toFixed(3) + " edBase=" + panelsList.edBaseScale.toFixed(3)
                  + " edCenter=" + panelsList.edCenterScale.toFixed(3) + " globalY=" + Math.round(panelsList.globalYOffset)
                  + "\nTILT:  center=" + panelsList.edTiltCenter + " near=" + panelsList.edTiltNear
                  + " far=" + panelsList.edTiltFar + " asym=" + panelsList.edAsymTilt
                  + "\nMODE:  layoutMode=" + panelsList.layoutMode + " activeCustom=" + panelsList.edActiveCustom
                  + " customLoaded=" + panelsList.edCustomIsLoaded + " useEdPath=" + panelsList.useEdPath;
                customInfoCopyClip.copyText(info);
                custInfoCopyBtn.copied = true;
                custInfoCopyTimer.restart();
              }
            }
          }
        }
      }
    }
  }

    // TEMPLATE INFO CARD — shows info for the selected template (ℹ button on templates)
  Rectangle {
    id: templateInfoWin
    visible: panelsList.edTemplateInfoOpen
    width: vpx(420)
    height: tmplInfoMainCol.implicitHeight + vpx(12)
    x: 120; y: 100
    color: Qt.rgba(0.04, 0.06, 0.12, 0.96)
    border.width: vpx(1); border.color: Qt.rgba(0.3,0.6,1.0,0.35)
    radius: vpx(6)
    z: 99998

    TextEdit { id: tmplInfoCopyClip; visible: false; width: 0; height: 0
      function copyText(t) { text = t; selectAll(); copy(); text = ""; } }

    // Derive static defaults for the selected template index
    property int  tmplIdx:  panelsList.edPreviewLayout
    property string tmplName: tmplIdx === 1 ? "Default"
                             : tmplIdx === 2 ? "Media Strip"
                             : tmplIdx === 3 ? "Card Stack"
                             : tmplIdx === 4 ? "Flat Center"
                             : tmplIdx === 5 ? "Big Box"
                             : tmplIdx === 6 ? "Uniflow"
                             : tmplIdx === 7 ? "Carousel"
                             : tmplIdx === 8 ? "RTL Default"
                             : "None"
    property bool tmplFlat: tmplIdx === 2 || tmplIdx === 4
    property string tmplSelX: tmplIdx === 4 ? "center" : tmplIdx === 1 || tmplIdx === 8 ? "217" : "220"
    property string tmplSpacing: (tmplIdx === 5 || tmplIdx === 6 || tmplIdx === 7) ? "Uniflow preset" : "auto"
    property string tmplArc: (tmplIdx === 1 || tmplIdx === 8) ? "0.090"
                            : (tmplIdx === 5 || tmplIdx === 6 || tmplIdx === 7) ? "Uniflow preset"
                            : "0.060"
    property string tmplTilt: tmplIdx === 7 ? "near=18  far=42" : "none"
    property string tmplDesc: tmplIdx === 1 ? "Standard curved fan, panels arc from left anchor."
                            : tmplIdx === 2 ? "Flat horizontal strip — all panels same scale, no arc."
                            : tmplIdx === 3 ? "Gentle curve, tighter arc than Default."
                            : tmplIdx === 4 ? "Flat, selected panel centred on screen."
                            : tmplIdx === 5 ? "Large selected panel (NXE style), curved, zoomed base."
                            : tmplIdx === 6 ? "Uniflow fan — wider spacing, lower base scale."
                            : tmplIdx === 7 ? "Carousel — Uniflow base with Y-axis tilt applied."
                            : tmplIdx === 8 ? "RTL mirror of Default — fans right from right edge."
                            : "No template selected."

    Column {
      id: tmplInfoMainCol
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: vpx(6) }
      spacing: vpx(3)

      // Title bar
      Item {
        width: parent.width; height: vpx(16)
        Row { anchors.verticalCenter: parent.verticalCenter; spacing: vpx(4)
          StyledText { text: "i"; font.pixelSize: vpx(9); font.bold: true; color: "#88ccff" }
          StyledText { text: "|"; font.pixelSize: vpx(8); color: Qt.rgba(0.4,0.6,1.0,0.4) }
          StyledText { text: "Template Info"; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
          StyledText {
            text: templateInfoWin.tmplIdx >= 1 ? ("  · " + templateInfoWin.tmplName) : "  · None selected"
            font.pixelSize: vpx(8); font.bold: true; color: bladePanel.bp_editorAccentColor
          }
        }
        Rectangle { id: closeTmplInfoBtn; width: vpx(16); height: vpx(16); radius: vpx(3)
          anchors { verticalCenter: parent.verticalCenter; right: parent.right }
          color: Qt.rgba(0.8,0.3,0.3,0.6); border.color: "#cc5555"; border.width: vpx(1)
          StyledText { anchors.centerIn: parent; text: "X"; font.pixelSize: vpx(7); font.bold: true; color: "#ffffff" }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: panelsList.edTemplateInfoOpen = false }
        }
        MouseArea {
          anchors { left: parent.left; right: closeTmplInfoBtn.left; top: parent.top; bottom: parent.bottom }
          drag.target: templateInfoWin; drag.axis: Drag.XandYAxis
        }
      }

      Rectangle { width: parent.width; height: vpx(1); color: Qt.rgba(0.3,0.6,1.0,0.25) }

      // Description
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "DESC:"; font.pixelSize: vpx(7); font.bold: true; color: "#88ccff"; width: vpx(46) }
        StyledText {
          text: templateInfoWin.tmplDesc
          font.pixelSize: vpx(7); color: "#aaddff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }

      // Template static defaults
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "TMPL:"; font.pixelSize: vpx(7); font.bold: true; color: "#88ccff"; width: vpx(46) }
        StyledText {
          text: "idx=" + templateInfoWin.tmplIdx
              + " | flat=" + templateInfoWin.tmplFlat
              + " | selX=" + templateInfoWin.tmplSelX
              + " | spacing=" + templateInfoWin.tmplSpacing
              + " | arc=" + templateInfoWin.tmplArc
              + " | tilt=" + templateInfoWin.tmplTilt
          font.pixelSize: vpx(7); color: "#ccffcc"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }

      // Current live values
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "LIVE:"; font.pixelSize: vpx(7); font.bold: true; color: "#88ff88"; width: vpx(46) }
        StyledText {
          text: "selX=" + Math.round(panelsList.selectedX)
              + " | sp=" + Math.round(panelsList.spacingOverride)
              + " | arc=" + panelsList.scaleStep.toFixed(3)
              + " | base=" + panelsList.uniBaseScale.toFixed(3)
              + " | flat=" + panelsList.flatMode
              + " | yd=" + Math.round(panelsList.yDropPerSlot)
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "ED*:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffcc44"; width: vpx(46) }
        StyledText {
          text: "edSelX=" + Math.round(panelsList.edSelectedX)
              + " | edFlat=" + panelsList.edFlatMode
              + " | edArc=" + panelsList.edScaleStep.toFixed(3)
              + " | edSp=" + Math.round(panelsList.edSpacing)
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "SCALE:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffaaaa"; width: vpx(46) }
        StyledText {
          text: "uniBase=" + panelsList.uniBaseScale.toFixed(3)
              + " | edBase=" + panelsList.edBaseScale.toFixed(3)
              + " | edCenter=" + panelsList.edCenterScale.toFixed(3)
              + " | globalY=" + Math.round(panelsList.globalYOffset)
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "TILT:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffcc88"; width: vpx(46) }
        StyledText {
          text: "center=" + panelsList.edTiltCenter
              + " | near=" + panelsList.edTiltNear
              + " | far=" + panelsList.edTiltFar
              + " | asym=" + panelsList.edAsymTilt
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "MODE:"; font.pixelSize: vpx(7); font.bold: true; color: "#cc88ff"; width: vpx(46) }
        StyledText {
          text: "layoutMode=" + panelsList.layoutMode
              + " | staged=" + panelsList.edTemplateStaged
              + " | useEdPath=" + panelsList.useEdPath
              + " | slotLoaded=" + panelsList.edSlotIsLoaded
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(46); wrapMode: Text.WordWrap
        }
      }

      // Separator + Copy button
      Rectangle { width: parent.width; height: vpx(1); color: Qt.rgba(0.3,0.6,1.0,0.18) }

      Item {
        width: parent.width; height: vpx(18)
        Row {
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          spacing: vpx(4)
          // Export current live layout as JSON
          Rectangle {
            id: tmplExportLayoutBtn; height: vpx(14); radius: vpx(3); width: vpx(90)
            color: Qt.rgba(0.4,0.2,0.7,0.5); border.color: "#9955ff"; border.width: vpx(1)
            property bool exported: false
            StyledText { anchors.centerIn: parent
              text: tmplExportLayoutBtn.exported ? "✓ Exported" : "⬆ Export Layout"
              font.pixelSize: vpx(7); font.bold: true; color: tmplExportLayoutBtn.exported ? "#ccffcc" : "#ddaaff" }
            Timer { id: tmplExportLayoutTimer; interval: 1500; onTriggered: tmplExportLayoutBtn.exported = false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                var name = templateInfoWin.tmplName;
                var raw = panelsList.edPackLayout();
                try {
                  var obj = JSON.parse(raw);
                  obj.n = name;
                  var json = JSON.stringify(obj, null, 2);
                  var safeName = name.replace(/[^a-zA-Z0-9_\-]/g, "_");
                  var fileUrl = Qt.resolvedUrl("../layouts/" + safeName + ".json");
                  var xhr = new XMLHttpRequest();
                  xhr.open("PUT", fileUrl, false);
                  xhr.send(json);
                  if (xhr.status !== 200 && xhr.status !== 201) tmplInfoCopyClip.copyText(json);
                } catch(e) { tmplInfoCopyClip.copyText(raw); }
                tmplExportLayoutBtn.exported = true;
                tmplExportLayoutTimer.restart();
              }
            }
          }

          Rectangle {
            id: tmplInfoCopyBtn; width: vpx(80); height: vpx(14); radius: vpx(3)
            color: Qt.rgba(0.3,0.5,1.0,0.5); border.color: "#4488ff"; border.width: vpx(1)
            property bool copied: false
            StyledText { anchors.centerIn: parent
              text: tmplInfoCopyBtn.copied ? "✓ Copied" : "Copy Debug Info"
              font.pixelSize: vpx(7); font.bold: true; color: tmplInfoCopyBtn.copied ? "#ccffcc" : "#ffffff" }
            Timer { id: tmplInfoCopyTimer; interval: 1500; onTriggered: tmplInfoCopyBtn.copied = false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                var info = "=== Template " + templateInfoWin.tmplIdx + ": " + templateInfoWin.tmplName + " ==="
                  + "\nDESC:  " + templateInfoWin.tmplDesc
                  + "\nTMPL:  idx=" + templateInfoWin.tmplIdx + " flat=" + templateInfoWin.tmplFlat
                  + " selX=" + templateInfoWin.tmplSelX + " spacing=" + templateInfoWin.tmplSpacing
                  + " arc=" + templateInfoWin.tmplArc + " tilt=" + templateInfoWin.tmplTilt
                  + "\nLIVE:  selX=" + Math.round(panelsList.selectedX) + " sp=" + Math.round(panelsList.spacingOverride)
                  + " arc=" + panelsList.scaleStep.toFixed(3) + " base=" + panelsList.uniBaseScale.toFixed(3)
                  + " flat=" + panelsList.flatMode + " yd=" + Math.round(panelsList.yDropPerSlot)
                  + "\nED*:   edSelX=" + Math.round(panelsList.edSelectedX) + " edFlat=" + panelsList.edFlatMode
                  + " edArc=" + panelsList.edScaleStep.toFixed(3) + " edSp=" + Math.round(panelsList.edSpacing)
                  + "\nSCALE: uniBase=" + panelsList.uniBaseScale.toFixed(3) + " edBase=" + panelsList.edBaseScale.toFixed(3)
                  + " edCenter=" + panelsList.edCenterScale.toFixed(3) + " globalY=" + Math.round(panelsList.globalYOffset)
                  + "\nTILT:  center=" + panelsList.edTiltCenter + " near=" + panelsList.edTiltNear
                  + " far=" + panelsList.edTiltFar + " asym=" + panelsList.edAsymTilt
                  + "\nMODE:  layoutMode=" + panelsList.layoutMode + " staged=" + panelsList.edTemplateStaged
                  + " useEdPath=" + panelsList.useEdPath + " slotLoaded=" + panelsList.edSlotIsLoaded;
                tmplInfoCopyClip.copyText(info);
                tmplInfoCopyBtn.copied = true;
                tmplInfoCopyTimer.restart();
              }
            }
          }
        }
      }
    }
  }

    // LAYOUT DEBUG WINDOW (outside editorOverlay)
  Rectangle {
    id: layoutDebugWin
    visible: panelsList.edDebugLayoutOpen
    width: vpx(440)
    height: dbgMainCol.implicitHeight + vpx(12)
    x: 50; y: 50
    color: Qt.rgba(0.05, 0.05, 0.10, 0.95)
    border.width: 0
    radius: vpx(6)
    z: 99999

    TextEdit { id: dbgClip; visible: false; width: 0; height: 0
      function copyText(t) { text = t; selectAll(); copy(); text = ""; } }

    Column {
      id: dbgMainCol
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: vpx(6) }
      spacing: vpx(2)

      // ── Title bar ──────────────────────────────────────────────
      Item {
        width: parent.width; height: vpx(16)
        Row { anchors.verticalCenter: parent.verticalCenter; spacing: 0
          StyledText { text: "🐛"; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
          StyledText { text: " | "; font.pixelSize: vpx(8); font.bold: true; color: bladePanel.bp_editorAccentColor }
          StyledText { text: "Debug"; font.pixelSize: vpx(8); font.bold: true; color: "#ffffff" }
          StyledText { text: " Layout"; font.pixelSize: vpx(8); font.bold: true; color: bladePanel.bp_editorAccentColor }
        }
        Rectangle { id: closeDebugBtn; width: vpx(16); height: vpx(16); radius: vpx(3)
          anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right
          color: Qt.rgba(0.8, 0.3, 0.3, 0.6); border.color: "#cc5555"; border.width: vpx(1)
          z: 2
          StyledText { anchors.centerIn: parent; text: "X"; font.pixelSize: vpx(7); font.bold: true; color: "#ffffff" }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: panelsList.edDebugLayoutOpen = false }
        }
        MouseArea {
          anchors { left: parent.left; right: closeDebugBtn.left; top: parent.top; bottom: parent.bottom }
          drag.target: layoutDebugWin; drag.axis: Drag.XandYAxis
        }
      }

      // ── Top blue separator line (below title) ──────────────────
      Rectangle { width: parent.width; height: vpx(1); color: Qt.rgba(0.4,0.6,1.0,0.25) }

      // ── Data rows ─────────────────────────────────────────────
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "LAYOUT:"; font.pixelSize: vpx(7); font.bold: true; color: "#88ccff"; width: vpx(42) }
        StyledText { text: "layoutMode="+panelsList.layoutMode+" | previewLm="+panelsList.edPreviewLayout+" | activeSlot="+panelsList.edActiveSlot+" | activeCustom="+panelsList.edActiveCustom
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(42) }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "PATH:"; font.pixelSize: vpx(7); font.bold: true; color: "#88ccff"; width: vpx(42) }
        StyledText { text: "useEdPath="+panelsList.useEdPath+" | edSlotLoaded="+panelsList.edSlotIsLoaded+" | edCustomLoaded="+panelsList.edCustomIsLoaded+" | tmplStaged="+panelsList.edTemplateStaged
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(42) }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "LIVE:"; font.pixelSize: vpx(7); font.bold: true; color: "#88ff88"; width: vpx(42) }
        StyledText { text: "selectedX="+Math.round(panelsList.selectedX)+" | flat="+panelsList.flatMode+" | scaleStep="+panelsList.scaleStep.toFixed(3)+" | spacing="+Math.round(panelsList.spacingOverride)
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(42) }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "ED*:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffcc44"; width: vpx(42) }
        StyledText { text: "edSelX="+Math.round(panelsList.edSelectedX)+" | edFlat="+panelsList.edFlatMode+" | edArc="+panelsList.edScaleStep.toFixed(3)+" | edSp="+Math.round(panelsList.edSpacing)
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(42) }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "SCALE:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffaaaa"; width: vpx(42) }
        StyledText { text: "uniBase="+panelsList.uniBaseScale.toFixed(3)+" | edBase="+panelsList.edBaseScale.toFixed(3)+" | edCenter="+panelsList.edCenterScale.toFixed(3)+" | globalY="+Math.round(panelsList.globalYOffset)
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(42) }
      }
      Row { width: parent.width; spacing: vpx(3)
        StyledText { text: "SLOT:"; font.pixelSize: vpx(7); font.bold: true; color: "#ffcc88"; width: vpx(42) }
        StyledText { text: "_slotEver="+panelsList._slotEverLoaded+" | _slotCustom="+panelsList._slotLoadedCustom+" | _closingEd="+panelsList._closingEditor+" | editorOpen="+panelsList.editorOpen
          font.pixelSize: vpx(7); color: "#ffffff"; width: parent.width - vpx(42) }
      }

      // ── Bottom blue separator + action buttons row ─────────────
      Item {
        width: parent.width; height: vpx(18)

        // Blue separator line
        Rectangle {
          anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
          height: vpx(1); color: Qt.rgba(0.4,0.6,1.0,0.20)
        }

        // COPY + EXPORT — pinned bottom-right
        Row {
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          spacing: vpx(4)

          // EXPORT button
          Rectangle {
            id: dbgExportBtn; width: vpx(44); height: vpx(14); radius: vpx(3)
            color: Qt.rgba(0.4, 0.2, 0.7, 0.5); border.color: "#9955ff"; border.width: vpx(1)
            StyledText { anchors.centerIn: parent; text: "EXPORT"; font.pixelSize: vpx(7); font.bold: true; color: "#ddaaff" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                var info = "LAYOUT: layoutMode=" + panelsList.layoutMode + " previewLm=" + panelsList.edPreviewLayout + " activeSlot=" + panelsList.edActiveSlot + " activeCustom=" + panelsList.edActiveCustom
                  + "\nPATH: useEdPath=" + panelsList.useEdPath + " edSlotLoaded=" + panelsList.edSlotIsLoaded + " edCustomLoaded=" + panelsList.edCustomIsLoaded + " tmplStaged=" + panelsList.edTemplateStaged
                  + "\nLIVE: selectedX=" + Math.round(panelsList.selectedX) + " flat=" + panelsList.flatMode + " scaleStep=" + panelsList.scaleStep.toFixed(3) + " spacing=" + Math.round(panelsList.spacingOverride)
                  + "\nED*: edSelX=" + Math.round(panelsList.edSelectedX) + " edFlat=" + panelsList.edFlatMode + " edArc=" + panelsList.edScaleStep.toFixed(3) + " edSp=" + Math.round(panelsList.edSpacing)
                  + "\nSCALE: uniBase=" + panelsList.uniBaseScale.toFixed(3) + " edBase=" + panelsList.edBaseScale.toFixed(3) + " edCenter=" + panelsList.edCenterScale.toFixed(3) + " globalY=" + Math.round(panelsList.globalYOffset)
                  + "\nSLOT: _slotEver=" + panelsList._slotEverLoaded + " _slotCustom=" + panelsList._slotLoadedCustom + " _closingEd=" + panelsList._closingEditor + " editorOpen=" + panelsList.editorOpen;
                dbgClip.copyText(info);
                dbgExportBtn.color = Qt.rgba(0.6, 0.8, 0.4, 0.8);
                dbgExportTimer.restart();
              }
            }
            Timer { id: dbgExportTimer; interval: 200; onTriggered: dbgExportBtn.color = Qt.rgba(0.4, 0.2, 0.7, 0.5) }
          }

          // COPY button
          Rectangle {
            id: dbgCopyBtn; width: vpx(36); height: vpx(14); radius: vpx(3)
            color: Qt.rgba(0.3, 0.5, 1.0, 0.5); border.color: "#4488ff"; border.width: vpx(1)
            StyledText { anchors.centerIn: parent; text: "COPY"; font.pixelSize: vpx(7); font.bold: true; color: "#ffffff" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                var info = "LAYOUT: layoutMode=" + panelsList.layoutMode + " previewLm=" + panelsList.edPreviewLayout + " activeSlot=" + panelsList.edActiveSlot + " activeCustom=" + panelsList.edActiveCustom
                  + "\nPATH: useEdPath=" + panelsList.useEdPath + " edSlotLoaded=" + panelsList.edSlotIsLoaded + " edCustomLoaded=" + panelsList.edCustomIsLoaded + " tmplStaged=" + panelsList.edTemplateStaged
                  + "\nLIVE: selectedX=" + Math.round(panelsList.selectedX) + " flat=" + panelsList.flatMode + " scaleStep=" + panelsList.scaleStep.toFixed(3) + " spacing=" + Math.round(panelsList.spacingOverride)
                  + "\nED*: edSelX=" + Math.round(panelsList.edSelectedX) + " edFlat=" + panelsList.edFlatMode + " edArc=" + panelsList.edScaleStep.toFixed(3) + " edSp=" + Math.round(panelsList.edSpacing)
                  + "\nSCALE: uniBase=" + panelsList.uniBaseScale.toFixed(3) + " edBase=" + panelsList.edBaseScale.toFixed(3) + " edCenter=" + panelsList.edCenterScale.toFixed(3) + " globalY=" + Math.round(panelsList.globalYOffset)
                  + "\nSLOT: _slotEver=" + panelsList._slotEverLoaded + " _slotCustom=" + panelsList._slotLoadedCustom + " _closingEd=" + panelsList._closingEditor + " editorOpen=" + panelsList.editorOpen;
                dbgClip.copyText(info);
                dbgCopyBtn.color = Qt.rgba(0.8, 1.0, 0.8, 0.8);
                dbgCopyTimer.restart();
              }
            }
            Timer { id: dbgCopyTimer; interval: 200; onTriggered: dbgCopyBtn.color = Qt.rgba(0.3, 0.5, 1.0, 0.5) }
          }
        }
      }
    }
  }

  // ── PanelsList Debug overlay — red border + stats readout ────────
  // Driven by edShowPanelListDebug ("Debug Panel Wrapper" button in Debug page).
  // Mirrors the style shown in the reference screenshot: red border around the
  // PathView with "PanelList Debug / Items / Current / pathItemCount" text.
  Rectangle {
    id: panelsListDebugOverlay
    visible: panelsList.edShowPanelListDebug
    anchors.fill: panelsList
    color: "transparent"
    border.color: "#ff3333"
    border.width: vpx(2)
    opacity: 0.85
    z: 10002

    // Stats readout — top-left corner
    Rectangle {
      anchors { top: parent.top; left: parent.left; topMargin: vpx(4); leftMargin: vpx(4) }
      width: plDbgCol.implicitWidth + vpx(12)
      height: plDbgCol.implicitHeight + vpx(8)
      color: Qt.rgba(0, 0, 0, 0.70)
      border.color: "#ff3333"; border.width: vpx(1)
      radius: vpx(3)

      Column {
        id: plDbgCol
        anchors { left: parent.left; top: parent.top; margins: vpx(4) }
        spacing: vpx(2)

        StyledText {
          text: "PanelList Debug"
          font.pixelSize: vpx(10); font.bold: true; color: "#ff3333"
        }
        StyledText {
          text: "Items: " + panelsList.count
          font.pixelSize: vpx(10); font.bold: true; color: "#ff3333"
        }
        StyledText {
          text: "Current: " + (panelsList.currentIndex + 1)
          font.pixelSize: vpx(10); font.bold: true; color: "#ff3333"
        }
        StyledText {
          text: "pathItemCount: " + panelsList.pathItemCount
          font.pixelSize: vpx(10); font.bold: true; color: "#ff3333"
        }
      }
    }
  }
}