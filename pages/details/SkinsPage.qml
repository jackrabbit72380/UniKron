import QtQuick 2.8
import QtQuick.Window 2.0
import QtGraphicalEffects 1.12
import QtQml 2.15
import QtQuick.Layouts 1.1
import "../../js/enums.mjs" as Enums
import "../../components"

Item {
  id: root
  focus: true

  // ── Accent / Theme colours (keys match SettingsPage exactly) ────────
  property var _accentPalette: [
    "#5d9809","#0099CC","#FF5733","#8A2BE2","#FFAA00","#00BFA5","#E91E8C","#EEEEEE"
  ]
  property var _themePalette: [
    "#555555","#1B4F8A","#3A3ABF","#606060","#8B5E1A","#2A8A2A"
  ]
  property string accentHex:        _accentPalette[0]
  property string themeHex:         _themePalette[2]
  property real   accentAlphaPct:   0
  property real   ifaceTransparency: 80

  property color  accentColor: Qt.rgba(
    parseInt(accentHex.substr(1,2),16)/255,
    parseInt(accentHex.substr(3,2),16)/255,
    parseInt(accentHex.substr(5,2),16)/255,
    Math.max(0.05, Math.min(1.0, 1.0 - accentAlphaPct / 100)))

  property color  themeColor: Qt.rgba(
    parseInt(themeHex.substr(1,2),16)/255,
    parseInt(themeHex.substr(3,2),16)/255,
    parseInt(themeHex.substr(5,2),16)/255,
    Math.max(0.05, Math.min(0.92, (1.0 - ifaceTransparency / 100) * 0.85)))

  // kept for buttons/bottom bar that used these names
  property color  themeDark: themeColor
  property color  themeMid:  Qt.rgba(
    parseInt(themeHex.substr(1,2),16)/255,
    parseInt(themeHex.substr(3,2),16)/255,
    parseInt(themeHex.substr(5,2),16)/255,
    Math.max(0.05, Math.min(0.92, (1.0 - ifaceTransparency / 100) * 0.70)))

  // Gradient flags
  property bool   panelGradient:     true
  property bool   gradAccentColor:   true
  property bool   gradAccentOpacity: true
  property bool   gradThemeColor:    true
  property bool   gradThemeTransp:   true

  function reloadColors() {
    var ai = parseInt(api.memory.get("cfg.accentFill") || "0")
    var ti = parseInt(api.memory.get("cfg.themeFill")  || "2")
    root.accentHex         = root._accentPalette[Math.max(0, Math.min(root._accentPalette.length-1, ai))]
    root.themeHex          = root._themePalette [Math.max(0, Math.min(root._themePalette.length-1,  ti))]
    root.accentAlphaPct    = parseInt(api.memory.get("cfg.accentAlpha") || "0")
    root.ifaceTransparency = parseInt(api.memory.get("cfg.ifaceAlpha")  || "80")
    var pg = api.memory.get("cfg.panelGradient")
    root.panelGradient      = (pg === null || pg === undefined || pg === "" || pg === "true")
    var ga = api.memory.get("cfg.gradAccent");   root.gradAccentColor   = (ga === null || ga === undefined || ga === "" || ga === "true")
    var go = api.memory.get("cfg.gradAccentOp"); root.gradAccentOpacity = (go === null || go === undefined || go === "" || go === "true")
    var gt = api.memory.get("cfg.gradTheme");    root.gradThemeColor    = (gt === null || gt === undefined || gt === "" || gt === "true")
    var gr = api.memory.get("cfg.gradThemeTr");  root.gradThemeTransp   = (gr === null || gr === undefined || gr === "" || gr === "true")
  }

  Timer {
    interval: 500; running: true; repeat: true; triggeredOnStart: true
    onTriggered: root.reloadColors()
  }

  // ── Base path ─────────────────────────────────────────────────────
  readonly property url _skinsBase: Qt.resolvedUrl("../../skins/")
  readonly property string skinsBase: _skinsBase.toString()

  property int    selectedIndex:  0
  property string activeSkinName: api.memory.get(Enums.MemoryKeys.CurrentTheme) || ""
  property string selectedSkinName: ""
  property string selectedPreview:  ""

  property string iniAuthor:  "—"
  property string iniVersion: "—"
  property string iniDate:    "—"

  property string focusArea: "list"
  property bool fullScreenVisible: false

  ListModel { id: skinListModel }
  property int skinCount: skinListModel.count

  function encodeFileUrl(url) { return url.split(" ").join("%20") }
  function skinFileUrl(skinName, filename) {
    return encodeFileUrl(skinsBase + skinName + "/" + filename)
  }

  function populateSkins() {
    skinListModel.clear()
    var metaUrl = encodeFileUrl(skinsBase + "metadata.pegasus.txt")
    var xhr = new XMLHttpRequest()
    xhr.open("GET", metaUrl, true)
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== 4) return
      var found = []
      if (xhr.status === 200 && xhr.responseText.length > 0) {
        var lines = xhr.responseText.split("\n")
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim()
          if (line.toLowerCase().indexOf("skin:") === 0) {
            var name = line.substring(5).trim()
            if (name.length > 0) found.push(name)
          }
        }
      }
      if (found.length === 0) {
        var xhr2 = new XMLHttpRequest()
        xhr2.open("GET", skinsBase, true)
        xhr2.onreadystatechange = function() {
          if (xhr2.readyState !== 4) return
          var re = /href="([^"./][^"]*)\//g
          var m
          while ((m = re.exec(xhr2.responseText)) !== null) {
            if (m[1] && m[1].charAt(0) !== ".") found.push(decodeURIComponent(m[1]))
          }
          if (found.length === 0) found = ["360", "Xbox 360 Spectrum Green"]
          populateModel(found)
        }
        xhr2.send()
        return
      }
      populateModel(found)
    }
    xhr.send()
  }

  function populateModel(names) {
    skinListModel.clear()
    for (var i = 0; i < names.length; i++)
      skinListModel.append({ skinName: names[i] })
    restoreSelection()
  }

  function restoreSelection() {
    if (activeSkinName !== "") {
      for (var i = 0; i < skinListModel.count; i++) {
        if (skinListModel.get(i).skinName === activeSkinName) {
          selectedIndex = i
          skinList.currentIndex = i
          updateSelection()
          return
        }
      }
    }
    updateSelection()
  }

  onSelectedIndexChanged: updateSelection()

  function updateSelection() {
    if (skinListModel.count === 0) return
    var idx = Math.min(selectedIndex, skinListModel.count - 1)
    selectedSkinName = skinListModel.get(idx).skinName
    selectedPreview  = skinFileUrl(selectedSkinName, "preview.png")
    loadInfo(selectedSkinName)
  }

  function loadInfo(skinName) {
    iniAuthor = "—"; iniVersion = "—"; iniDate = "—"
    var iniUrl = skinFileUrl(skinName, "info.ini")
    var xhr = new XMLHttpRequest()
    xhr.open("GET", iniUrl, true)
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== 4) return
      if (xhr.status === 200 && xhr.responseText.length > 0)
        parseIniText(xhr.responseText)
    }
    xhr.send()
  }

  function parseIniText(text) {
    var lines = text.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line === "" || line.charAt(0) === "[" || line.charAt(0) === "#") continue
      var sep = line.indexOf("=")
      if (sep === -1) sep = line.indexOf(":")
      if (sep === -1) continue
      var key = line.substring(0, sep).trim().toLowerCase()
      var val = line.substring(sep + 1).trim()
      if      (key === "author")  iniAuthor  = val
      else if (key === "version") iniVersion = val
      else if (key === "date")    iniDate    = val
    }
  }

  Component.onCompleted: {
    populateSkins()
    setAvailableActions({
      [Enums.ActionKeys.Bottom]: { label: "Apply",    visible: true },
      [Enums.ActionKeys.Right]:  { label: "Back",     visible: true },
      [Enums.ActionKeys.Left]:   { label: "Preview",  visible: true },
    })
  }

  // ══════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════
  StyledText {
    id: pageTitle
    text: "Choose Skin"
    font.pixelSize: vpx(32)
    font.bold: true
    color: root.accentHex
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: vpx(28)
    anchors.leftMargin: vpx(40)
  }

  StyledText {
    id: skinNameTitle
    text: selectedSkinName || "—"
    font.pixelSize: vpx(28)
    font.bold: true
    color: "#FFFFFF"
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.leftMargin: vpx(396)
    anchors.right: exitBtn.left
    anchors.rightMargin: vpx(10)
    anchors.topMargin: vpx(28)
    elide: Text.ElideRight
    layer.enabled: false
  }

  // ── X Close button — top right ────────────────────────────────────
  Item {
    id: exitBtn
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: vpx(22)
    anchors.rightMargin: vpx(40)
    width: vpx(32); height: vpx(32)

    Rectangle {
      anchors.fill: parent
      radius: vpx(4)
      color: exitMouse.containsMouse ? root.accentHex : "transparent"
      border.color: exitMouse.containsMouse ? root.accentHex : "#88FFFFFF"
      border.width: vpx(1)

      StyledText {
        anchors.centerIn: parent
        text: "✕"
        font.pixelSize: vpx(16)
        font.bold: true
        color: "#FFFFFF"
        layer.enabled: false
      }
    }

    MouseArea {
      id: exitMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: navigate(pages.library)
    }
  }

  Item {
    id: headerRow
    anchors.top: parent.top
    anchors.topMargin: vpx(28)
    anchors.left: parent.left
    anchors.right: parent.right
    height: vpx(42)
  }

  // ══════════════════════════════════════════════════════════════════
  // BOTTOM BAR — Apply button | metadata bar | View Full Screen
  // ══════════════════════════════════════════════════════════════════
  Item {
    id: bottomBar
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.leftMargin: vpx(40)
    anchors.rightMargin: vpx(40)
    anchors.bottomMargin: vpx(70)
    height: vpx(46)

    Rectangle {
      id: applySkinBtn
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: vpx(340)
      color: focusArea === "applyBtn" ? root.accentHex : root.themeDark
      radius: vpx(4)
      border.color: focusArea === "applyBtn" ? root.accentHex : "#44FFFFFF"
      border.width: vpx(1)
      Behavior on color { ColorAnimation { duration: 100 } }

      StyledText {
        anchors.centerIn: parent
        text: "Apply Skin"
        font.pixelSize: vpx(16)
        font.bold: focusArea === "applyBtn"
        layer.enabled: false
      }
    }

    Item {
      anchors.left: applySkinBtn.right
      anchors.leftMargin: vpx(16)
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.bottom: parent.bottom

      Rectangle {
        id: viewFullBtn
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: vpx(200)
        color: focusArea === "fullscreenBtn" ? root.accentHex : root.themeDark
        radius: vpx(4)
        border.color: focusArea === "fullscreenBtn" ? root.accentHex : "#44FFFFFF"
        border.width: vpx(1)
        Behavior on color { ColorAnimation { duration: 100 } }

        StyledText {
          anchors.centerIn: parent
          text: "Full Screen"
          font.pixelSize: vpx(16)
          font.bold: focusArea === "fullscreenBtn"
          layer.enabled: false
        }
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: viewFullBtn.left
        anchors.rightMargin: vpx(16)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: root.themeDark
        radius: vpx(4)
        border.color: "#33FFFFFF"
        border.width: vpx(1)

        Row {
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: vpx(20)
          spacing: vpx(28)

          Row {
            spacing: vpx(6)
            StyledText { text: "Author:";  color: "#AAAAAA"; font.pixelSize: vpx(15); layer.enabled: false }
            StyledText { text: iniAuthor;  font.pixelSize: vpx(15); font.bold: true;  color: "#FFFFFF"; layer.enabled: false }
          }
          Row {
            spacing: vpx(6)
            StyledText { text: "Version:"; color: "#AAAAAA"; font.pixelSize: vpx(15); layer.enabled: false }
            StyledText { text: iniVersion; font.pixelSize: vpx(15); font.bold: true;  color: "#FFFFFF"; layer.enabled: false }
          }
          Row {
            spacing: vpx(6)
            StyledText { text: "Date:";    color: "#AAAAAA"; font.pixelSize: vpx(15); layer.enabled: false }
            StyledText { text: iniDate;    font.pixelSize: vpx(15); font.bold: true;  color: "#FFFFFF"; layer.enabled: false }
          }
        }
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // LEFT PANEL — skin list
  // ══════════════════════════════════════════════════════════════════
  Rectangle {
    id: listPanel
    anchors.top: headerRow.bottom
    anchors.left: parent.left
    anchors.bottom: bottomBar.top
    anchors.topMargin: vpx(10)
    anchors.bottomMargin: vpx(10)
    anchors.leftMargin: vpx(40)
    width: vpx(340)
    color: "transparent"
    radius: vpx(4)
    clip: true

    border.color: focusArea === "list" ? root.accentHex : "#33FFFFFF"
    border.width: focusArea === "list" ? vpx(2) : vpx(1)

    // Solid base (when gradient off)
    Rectangle {
      anchors.fill: parent; anchors.margins: vpx(1); radius: vpx(3)
      color: root.themeColor
      visible: !root.panelGradient
    }
    // Theme Color gradient
    LinearGradient {
      visible: root.panelGradient && root.gradThemeColor
      anchors.fill: parent
      start: Qt.point(0, 0); end: Qt.point(width, height)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(root.themeColor.r, root.themeColor.g, root.themeColor.b, 0.97) }
        GradientStop { position: 0.6; color: Qt.rgba(root.themeColor.r * 0.7, root.themeColor.g * 0.7, root.themeColor.b * 0.7, 0.97) }
        GradientStop { position: 1.0; color: Qt.rgba(root.themeColor.r * 0.5, root.themeColor.g * 0.5, root.themeColor.b * 0.5, 0.97) }
      }
    }
    // Theme Transparency gradient
    LinearGradient {
      visible: root.panelGradient && root.gradThemeTransp
      anchors.fill: parent
      start: Qt.point(0, height); end: Qt.point(0, 0)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.18) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
      }
    }
    // Accent Color gradient
    LinearGradient {
      visible: root.panelGradient && root.gradAccentColor
      anchors.fill: parent
      start: Qt.point(0, 0); end: Qt.point(width, 0)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12) }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }
    // Accent Opacity gradient
    LinearGradient {
      visible: root.panelGradient && root.gradAccentOpacity
      anchors.fill: parent
      start: Qt.point(0, 0); end: Qt.point(0, height)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.08) }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }

    // Accent bar top when focused
    Rectangle {
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: vpx(3)
      radius: vpx(2)
      color: root.accentHex
      visible: focusArea === "list"
    }

    StyledText {
      anchors.centerIn: parent
      text: "No skins found"
      color: "#80FFFFFF"
      font.pixelSize: vpx(15)
      horizontalAlignment: Text.AlignHCenter
      layer.enabled: false
      visible: skinCount === 0
    }

    ListView {
      id: skinList
      anchors.fill: parent
      anchors.margins: vpx(6)
      model: skinListModel
      clip: true
      currentIndex: selectedIndex
      highlightMoveDuration: 120
      visible: skinCount > 0

      highlight: Rectangle {
        color: root.accentHex
        radius: vpx(3)
      }
      highlightFollowsCurrentItem: true

      delegate: Item {
        width: skinList.width
        height: vpx(44)

        Rectangle {
          id: cb
          width: vpx(18); height: vpx(18); radius: vpx(3)
          border.color: "white"; border.width: vpx(2)
          color: "transparent"
          anchors.left: parent.left
          anchors.leftMargin: vpx(12)
          anchors.verticalCenter: parent.verticalCenter
          Rectangle {
            anchors.fill: parent; anchors.margins: vpx(3)
            radius: vpx(1); color: "white"
            visible: skinName === activeSkinName
          }
        }

        StyledText {
          text: skinName
          font.pixelSize: vpx(17)
          font.bold: index === selectedIndex
          anchors.left: cb.right; anchors.leftMargin: vpx(10)
          anchors.right: parent.right; anchors.rightMargin: vpx(8)
          anchors.verticalCenter: parent.verticalCenter
          elide: Text.ElideRight
          layer.enabled: false
        }

        Rectangle {
          anchors.bottom: parent.bottom
          width: parent.width; height: vpx(1)
          color: "#22FFFFFF"
          visible: index < skinList.count - 1
        }
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // RIGHT PANEL — preview image
  // ══════════════════════════════════════════════════════════════════
  Rectangle {
    id: previewRect
    anchors.top: headerRow.bottom
    anchors.left: listPanel.right
    anchors.right: parent.right
    anchors.bottom: bottomBar.top
    anchors.topMargin: vpx(10)
    anchors.bottomMargin: vpx(10)
    anchors.leftMargin: vpx(16)
    anchors.rightMargin: vpx(40)
    color: "transparent"
    radius: vpx(4)
    clip: true

    border.color: focusArea === "fullscreenBtn" ? root.accentHex : "#33FFFFFF"
    border.width: focusArea === "fullscreenBtn" ? vpx(2) : vpx(1)

    // Solid base (when gradient off)
    Rectangle {
      anchors.fill: parent; anchors.margins: vpx(1); radius: vpx(3)
      color: root.themeColor
      visible: !root.panelGradient
    }
    // Theme Color gradient
    LinearGradient {
      visible: root.panelGradient && root.gradThemeColor
      anchors.fill: parent
      start: Qt.point(0, 0); end: Qt.point(width, height)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(root.themeColor.r, root.themeColor.g, root.themeColor.b, 0.97) }
        GradientStop { position: 0.6; color: Qt.rgba(root.themeColor.r * 0.7, root.themeColor.g * 0.7, root.themeColor.b * 0.7, 0.97) }
        GradientStop { position: 1.0; color: Qt.rgba(root.themeColor.r * 0.5, root.themeColor.g * 0.5, root.themeColor.b * 0.5, 0.97) }
      }
    }
    // Theme Transparency gradient
    LinearGradient {
      visible: root.panelGradient && root.gradThemeTransp
      anchors.fill: parent
      start: Qt.point(0, height); end: Qt.point(0, 0)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.18) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
      }
    }
    // Accent Color gradient
    LinearGradient {
      visible: root.panelGradient && root.gradAccentColor
      anchors.fill: parent
      start: Qt.point(0, 0); end: Qt.point(width, 0)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12) }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }
    // Accent Opacity gradient
    LinearGradient {
      visible: root.panelGradient && root.gradAccentOpacity
      anchors.fill: parent
      start: Qt.point(0, 0); end: Qt.point(0, height)
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.08) }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }

    Image {
      id: previewImg
      anchors.fill: parent
      anchors.margins: vpx(4)
      source: selectedPreview
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      cache: false
    }

    StyledText {
      anchors.centerIn: parent
      text: "No Preview Available"
      color: "#80FFFFFF"
      font.pixelSize: vpx(16)
      layer.enabled: false
      visible: previewImg.status !== Image.Ready
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // FULL-SCREEN OVERLAY
  // ══════════════════════════════════════════════════════════════════
  Rectangle {
    id: fullScreenOverlay
    anchors.fill: parent
    color: "#EE000000"
    visible: fullScreenVisible
    z: 100

    Image {
      anchors.fill: parent
      anchors.margins: vpx(40)
      source: selectedPreview
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      cache: false
    }

    StyledText {
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottomMargin: vpx(30)
      text: "Press B to close"
      color: "#AAAAAA"
      font.pixelSize: vpx(16)
      layer.enabled: false
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // INPUT
  // ══════════════════════════════════════════════════════════════════
  Keys.onRightPressed: {
    if (fullScreenVisible) { event.accepted = true; return }
    if (focusArea === "list") focusArea = "fullscreenBtn"
    else if (focusArea === "applyBtn") focusArea = "fullscreenBtn"
    event.accepted = true
  }

  Keys.onLeftPressed: {
    if (fullScreenVisible) { event.accepted = true; return }
    if (focusArea === "fullscreenBtn") focusArea = "list"
    else if (focusArea === "applyBtn") focusArea = "list"
    event.accepted = true
  }

  Keys.onDownPressed: {
    if (fullScreenVisible) { event.accepted = true; return }
    if (focusArea === "list" && selectedIndex < skinListModel.count - 1) {
      selectedIndex++
      skinList.currentIndex = selectedIndex
    } else if (focusArea === "list") {
      focusArea = "applyBtn"
    }
    event.accepted = true
  }

  Keys.onUpPressed: {
    if (fullScreenVisible) { event.accepted = true; return }
    if (focusArea === "list" && selectedIndex > 0) {
      selectedIndex--
      skinList.currentIndex = selectedIndex
    } else if (focusArea === "applyBtn") {
      focusArea = "list"
    }
    event.accepted = true
  }

  Keys.onPressed: {
    if (!event.isAutoRepeat) {
      if (fullScreenVisible) {
        if (api.keys.isCancel(event)) {
          fullScreenVisible = false
          event.accepted = true
        }
        return
      }

      if (api.keys.isAccept(event)) {
        if (focusArea === "fullscreenBtn") {
          fullScreenVisible = true
        } else if (focusArea === "applyBtn" || focusArea === "list") {
          activeSkinName = selectedSkinName
          api.memory.set(Enums.MemoryKeys.CurrentTheme, selectedSkinName)
        }
        event.accepted = true
      } else if (api.keys.isCancel(event)) {
        if (focusArea === "fullscreenBtn" || focusArea === "applyBtn") {
          focusArea = "list"
        } else {
          navigate(pages.library)
        }
        event.accepted = true
      }
      // X — close/back (same as B when at list)
      else if (api.keys.isDetails(event)) {
        navigate(pages.library)
        event.accepted = true
      }
    }
  }
}
