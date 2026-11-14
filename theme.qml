
import QtQuick 2.8
import QtQuick.Window 2.0
import QtMultimedia 5.15
import "components"
import "./js/utils.mjs" as Utils
import "./js/enums.mjs" as Enums

FocusScope {
  id: root

  readonly property var vpx: Utils.vpx(Screen.height)
  readonly property var delay: Utils.delay(root)
  readonly property var setAvailableActions: buttonActions.setAvailableActions
  readonly property var appendAdditionalAvailableActions: buttonActions.appendAdditionalAvailableActions
  readonly property var navigate: router.navigate

  // ── Live theme properties — written by ThemesDetails on Back/Apply ──
  // ThemesDetails calls api.memory.set() then sets these directly so the
  // dashboard updates instantly without needing a full reload.
  property string currentWallpaper: api.memory.get("theme.wallpaper") || "Xbox 360 SpecGlass Green"
  property string currentStage:     api.memory.get("theme.stage")     || "0003"
  property string currentTab:       api.memory.get("currentTab")      || "greenglass"
  property string currentIcon:      api.memory.get("currentIcon")     || "green"
  property string currentButton:    api.memory.get("currentButton")   || "default"
  property string currentAudio:     api.memory.get("currentAudio")    || "default"
  property string currentCanopy:    api.memory.get("currentCanopy")   || ""
  property bool   stageEnabled:     api.memory.get("stageEnabled")    !== "false"
  property bool   canopyEnabled:    api.memory.get("canopyEnabled")   !== "false"

  // ── UI Mode — switches between UniKron and UniBlades ─────────────────
  property string uiMode: api.memory.get("cfg.uiMode") || "unikron"

  Timer {
    id: uiModePoll
    interval: 500
    repeat: true
    running: true
    onTriggered: {
      var m = api.memory.get("cfg.uiMode") || "unikron"
      if (m !== root.uiMode) root.uiMode = m
    }
  }

  // ── Wallpaper appearance — set live by ThemesDetails via parent chain ─
  property bool   wpOn:      api.memory.get("theme.wpOn")      !== "false"
  property bool   wpDarkOn:  api.memory.get("theme.wpDark")    === "true"
  property bool   wpGradOn:  api.memory.get("theme.wpGrad")    === "true"
  property bool   wpRingsOn: api.memory.get("theme.wpRings")   !== "false"
  property int    wpOpacity: parseInt(api.memory.get("theme.wpOpacity") || "100")

  // ── Tabs appearance — set live by ThemesDetails via parent chain ──────
  property bool   tabsDarkOn:  api.memory.get("theme.tabsDark")    === "true"
  property bool   tabsGradOn:  api.memory.get("theme.tabsGrad")    !== "false"
  property int    tabsOpacity: parseInt(api.memory.get("theme.tabsOpacity") || "100")
  property bool   tabsRingsOn: api.memory.get("theme.tabsRings")   === "true"
  property bool   tabsBgOn:    api.memory.get("theme.tabsBg")      !== "false"

  SoundEffect {
    id: channelUpSound
    source: "assets/audio/channel-up.wav"
    volume: .5
  }

  SoundEffect {
    id: channelDownSound
    source: "assets/audio/channel-down.wav"
    volume: .5
  }

  SoundEffect {
    id: panelLeftSound
    source: "assets/audio/panel-left.wav"
    volume: .1
  }

  SoundEffect {
    id: panelRightSound
    source: "assets/audio/panel-right.wav"
    volume: .1
  }

  SoundEffect {
    id: panelUnfoldSound
    source: "assets/audio/panel-unfold.wav"
    volume: .01
  }

  SoundEffect {
    id: selectSound
    source: "assets/audio/select.wav"
    volume: .5
  }

  SoundEffect {
    id: focusSound
    source: "assets/audio/focus.wav"
    volume: .5
  }

  SoundEffect {
    id: backSound
    source: "assets/audio/back.wav"
    volume: .5
  }

  // ── Startup Sound & System Music ─────────────────────────────────
  property bool startupSoundEnabled: api.memory.get("cfg.startupSound") !== "false"
  property bool systemMusicEnabled:  api.memory.get("cfg.systemMusic")  !== "false"

  // audioPack: folder for the selected audio pack
  property string audioPack: Qt.resolvedUrl("assets/audio/" + currentAudio + "/").toString()

  // Filenames to try in order for startup sound, then loop music
  property var startupFiles: ["startup.wav","startup.mp3","startup.flac","startup.ogg",
                               "Startup.wav","Startup.mp3","Startup.flac","Startup.ogg"]
  property var musicFiles:   ["music.wav","music.mp3","music.flac","music.ogg",
                               "Music.wav","Music.mp3","Music.flac","Music.ogg"]

  property int  _sfIdx:      0   // index into startupFiles currently trying
  property int  _mfIdx:      0   // index into musicFiles currently trying
  property bool _startupDone: false  // true once startup sound has played/been skipped

  // Single MediaPlayer handles both startup sound (loops:1) and system music (loops:Infinite)
  MediaPlayer {
    id: themeMusic
    volume: parseFloat(api.memory.get("cfg.musicVol") || "0.6")

    onStatusChanged: {
      console.log("MUSIC: status=" + status + " src=" + source + " startupDone=" + root._startupDone)
      if (status === MediaPlayer.InvalidMedia) {
        // Try next file in the current list
        if (!root._startupDone) {
          root._sfIdx++
          if (root._sfIdx < root.startupFiles.length) {
            source = root.audioPack + root.startupFiles[root._sfIdx]
          } else {
            // No startup file found — skip to music
            console.log("MUSIC: no startup file found, skipping to loop music")
            root._startupDone = true
            if (root.systemMusicEnabled) root._tryLoopMusic()
          }
        } else {
          root._mfIdx++
          if (root._mfIdx < root.musicFiles.length) {
            source = root.audioPack + root.musicFiles[root._mfIdx]
          } else {
            console.log("MUSIC: no music file found either")
          }
        }
      } else if (status === MediaPlayer.Loaded) {
        console.log("MUSIC: loaded OK, playing")
        themeMusic.play()
      }
    }

    onStopped: {
      // Startup sound finished — start loop music
      if (!root._startupDone) {
        root._startupDone = true
        console.log("MUSIC: startup finished, starting loop music")
        if (root.systemMusicEnabled) root._tryLoopMusic()
      }
    }
  }

  function _tryStartupSound() {
    root._sfIdx = 0
    root._startupDone = false
    themeMusic.loops = 1
    themeMusic.source = root.audioPack + root.startupFiles[0]
    console.log("MUSIC: trying startup: " + themeMusic.source)
  }

  function _tryLoopMusic() {
    root._mfIdx = 0
    themeMusic.loops = MediaPlayer.Infinite
    themeMusic.source = root.audioPack + root.musicFiles[0]
    console.log("MUSIC: trying loop music: " + themeMusic.source)
  }

  // Kick off on startup
  Timer {
    id: startupMusicTimer
    interval: 800
    repeat: false
    running: true
    onTriggered: {
      var ss = api.memory.get("cfg.startupSound")
      var sm = api.memory.get("cfg.systemMusic")
      root.startupSoundEnabled = (ss === null || ss === "" || ss === "true")
      root.systemMusicEnabled  = (sm === null || sm === "" || sm === "true")
      console.log("MUSIC: startupEnabled=" + root.startupSoundEnabled + " musicEnabled=" + root.systemMusicEnabled + " pack=" + root.audioPack)
      if (root.startupSoundEnabled) {
        root._tryStartupSound()
      } else if (root.systemMusicEnabled) {
        root._startupDone = true
        root._tryLoopMusic()
      }
    }
  }

  // Restart when audio pack changes
  onCurrentAudioChanged: {
    themeMusic.stop()
    themeMusic.source = ""
    root._sfIdx = 0
    root._mfIdx = 0
    root._startupDone = false
    // Rebuild audioPack with new pack name
    root.audioPack = Qt.resolvedUrl("assets/audio/" + currentAudio + "/").toString()
    console.log("MUSIC: audio pack changed to " + root.audioPack)
    startupMusicTimer.restart()
  }

  // Dynamic wallpaper — shows WebP/GIF as animated background
  property string bgWallpaperPath: ""
  property bool   bgWallpaperOn:   false

  AnimatedImage {
    anchors.fill: parent
    z: 1
    visible: root.bgWallpaperOn
    source: root.bgWallpaperPath
    fillMode: Image.PreserveAspectCrop
    playing: true
    asynchronous: true
    cache: false
  }

  Background {
    wallpaperName: root.currentWallpaper
    wpOn:      root.wpOn
    // Hide static wallpaper when bg video OR animated wallpaper is active
    visible:   !root.bgWallpaperOn && !root.bgOutActive
    wpDarkOn:  root.wpDarkOn
    wpGradOn:  root.wpGradOn
    wpRingsOn: root.wpRingsOn
    wpOpacity: root.wpOpacity
  }

  Stage {
    id: stage
    stageName: root.currentStage
    visible: root.stageEnabled
  }

  Router {
    id: router
    focus: root.uiMode !== "uniblades"
    anchors.fill: parent
    z: 3
    visible: root.uiMode !== "uniblades"
    enabled: root.uiMode !== "uniblades"

    Component.onCompleted: {
      api.memory.set(Enums.MemoryKeys.LibraryChannelIndex, 0);
      api.memory.set(Enums.MemoryKeys.LibraryPanelIndex, 0);
      api.memory.set("cfg.videoBgPlaying",  "false");
      api.memory.set("cfg.videoBgMode",     "false");
      api.memory.set("cfg.videoMiniMode",   "false");
      api.memory.set("cfg.videoBgWallpaper","false");
      // Clear stale session flags so mini bar starts hidden and MusicPage open flag is clean
      api.memory.set("cfg.musicDashBar",  "false");
      api.memory.set("cfg.musicPageOpen", "false");
      api.memory.set("cfg.miniCmd",       "");
      // Stop bgPlayer to release DirectShow renderer from previous session
      console.log("THEME: startup — bgPlayer.source="+bgPlayer.source+" status="+bgPlayer.status)
      bgPlayer.stop();
      bgPlayer.source = "";
      console.log("THEME: bgPlayer stopped")
    }
  }

  // ── UniBlades theme loader — active when uiMode === "uniblades" ───────
  Loader {
    id: uniBladesLoader
    anchors.fill: parent
    z: 3
    active: root.uiMode === "uniblades"
    focus: root.uiMode === "uniblades"
    source: root.uiMode === "uniblades" ? "modules/UniBlades/theme.qml" : ""
  }

  Canopies {
    id: canopies
    anchors.fill: parent
    z: 4
    canopyName:    root.currentCanopy
    canopyVisible: root.canopyEnabled && stage.state === "Visible" && root.currentCanopy !== ""
  }

  ButtonActions {
    id: buttonActions
    z: 9000
    visible: root.uiMode !== "uniblades"
  }
Connections {
    target: buttonActions
    onActionTriggered: {
        console.log("DEBUG: actionTriggered =", key)
        if (router.currentItem && router.currentItem.onAction) {
            router.currentItem.onAction(key)
        }
    }
}

  // ══════════════════════════════════════════════════════════════════
  // CLOCK OVERLAY
  // Keys used (set by SettingsPage.qml):
  //   cfg.showClock      "true"/"false"
  //   cfg.clockOnDash    "true"/"false"
  //   cfg.useSkinClock   "true"/"false"
  //   cfg.clock24        "true"/"false"
  //   cfg.clockPosX      0.0–1.0
  //   cfg.clockPosY      0.0–1.0
  //   cfg.clockFontSize  integer
  //   cfg.clockOpacity   0.0–1.0
  // ══════════════════════════════════════════════════════════════════
  Item {
    id: clockOverlay
    z: 9000
    anchors.fill: parent

    property bool   showClock:    true
    property bool   clockOnDash:  true
    property bool   useSkinClock: false
    property bool   clock24:      false
    property real   posX:         0.97
    property real   posY:         0.02
    property int    fontSize:     18
    property real   opacity_val:  1.0
    property string timeText:     ""

    visible: showClock && clockOnDash && !useSkinClock

    Timer {
      interval: 1000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        var sc  = api.memory.get("cfg.showClock")
        var cod = api.memory.get("cfg.clockOnDash")
        var usc = api.memory.get("cfg.useSkinClock")
        var c24 = api.memory.get("cfg.clock24")
        var px  = api.memory.get("cfg.clockPosX")
        var py  = api.memory.get("cfg.clockPosY")
        var fs  = api.memory.get("cfg.clockFontSize")
        var op  = api.memory.get("cfg.clockOpacity")

        clockOverlay.showClock    = (sc  === null || sc  === "" || sc  === "true")
        clockOverlay.clockOnDash  = (cod === null || cod === "" || cod === "true")
        clockOverlay.useSkinClock = (usc === "true")
        clockOverlay.clock24      = (c24 === "true")
        clockOverlay.posX         = (px  !== null && px  !== "") ? parseFloat(px)  : 0.97
        clockOverlay.posY         = (py  !== null && py  !== "") ? parseFloat(py)  : 0.02
        clockOverlay.fontSize     = (fs  !== null && fs  !== "") ? parseInt(fs)    : 18
        clockOverlay.opacity_val  = (op  !== null && op  !== "") ? parseFloat(op)  : 1.0

        var d     = new Date()
        var use24 = clockOverlay.clock24
        var h     = d.getHours()
        var m     = d.getMinutes()
        var s     = d.getSeconds()
        var ampm  = ""
        if (!use24) {
          ampm = h >= 12 ? " PM" : " AM"
          h    = h % 12
          if (h === 0) h = 12
        }
        clockOverlay.timeText = (h < 10 && use24 ? "0" : "") + h
          + ":" + (m < 10 ? "0" : "") + m
          + ":" + (s < 10 ? "0" : "") + s
          + ampm
      }
    }

    Item {
      id: clockBg
      x: clockOverlay.posX * clockOverlay.width  - width  / 2
      y: clockOverlay.posY * clockOverlay.height - height / 2
      width:  clockLabel.implicitWidth  + vpx(8)
      height: clockLabel.implicitHeight + vpx(4)
      opacity: clockOverlay.opacity_val

      Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
      Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }

      StyledText {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: vpx(1)
        anchors.verticalCenterOffset:   vpx(1)
        text:           clockOverlay.timeText
        font.pixelSize: vpx(clockOverlay.fontSize)
        font.bold:      true
        color:          "#99000000"
        layer.enabled:  false
      }
      StyledText {
        id: clockLabel
        anchors.centerIn: parent
        text:           clockOverlay.timeText
        font.pixelSize: vpx(clockOverlay.fontSize)
        font.bold:      true
        color:          "#FFFFFF"
        layer.enabled:  false
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // DATE OVERLAY
  // Keys used (set by SettingsPage.qml):
  //   cfg.showDate       "true"/"false"
  //   cfg.dateOnDash     "true"/"false"
  //   cfg.useSkinDate    "true"/"false"
  //   cfg.dateFormat     "0" day+month name     e.g. "Wednesday, February"
  //                      "1" day+month number   e.g. "25 / 02"
  //                      "2" full name          e.g. "Wednesday, February 25, 2026"
  //                      "3" full numbers       e.g. "25 / 02 / 2026"
  //   cfg.datePosX       0.0–1.0
  //   cfg.datePosY       0.0–1.0
  //   cfg.dateFontSize   integer
  //   cfg.dateOpacity    0.0–1.0
  // ══════════════════════════════════════════════════════════════════
  Item {
    id: dateOverlay
    z: 8999
    anchors.fill: parent

    property bool   showDate:    false
    property bool   dateOnDash:  true
    property bool   useSkinDate: false
    property int    dateFormat:  0
    property real   posX:        0.97
    property real   posY:        0.07
    property int    fontSize:    14
    property real   opacity_val: 1.0
    property string dateText:    ""

    // Day / month name arrays — plain JS, no extra imports needed
    readonly property var dayNames:   ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    readonly property var monthNames: ["January","February","March","April","May","June",
                                       "July","August","September","October","November","December"]

    visible: showDate && dateOnDash && !useSkinDate

    Timer {
      interval: 1000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        var sd  = api.memory.get("cfg.showDate")
        var dod = api.memory.get("cfg.dateOnDash")
        var usd = api.memory.get("cfg.useSkinDate")
        var df  = api.memory.get("cfg.dateFormat")
        var px  = api.memory.get("cfg.datePosX")
        var py  = api.memory.get("cfg.datePosY")
        var fs  = api.memory.get("cfg.dateFontSize")
        var op  = api.memory.get("cfg.dateOpacity")

        dateOverlay.showDate    = (sd  === "true")
        dateOverlay.dateOnDash  = (dod === null || dod === "" || dod === "true")
        dateOverlay.useSkinDate = (usd === "true")
        dateOverlay.dateFormat  = (df  !== null && df  !== "") ? parseInt(df)    : 0
        dateOverlay.posX        = (px  !== null && px  !== "") ? parseFloat(px)  : 0.97
        dateOverlay.posY        = (py  !== null && py  !== "") ? parseFloat(py)  : 0.07
        dateOverlay.fontSize    = (fs  !== null && fs  !== "") ? parseInt(fs)    : 14
        dateOverlay.opacity_val = (op  !== null && op  !== "") ? parseFloat(op)  : 1.0

        var d   = new Date()
        var day = d.getDate()
        var mon = d.getMonth()       // 0-based
        var yr  = d.getFullYear()
        var dow = d.getDay()         // 0=Sunday
        var fmt = dateOverlay.dateFormat

        // Pad helper
        function pad2(n) { return n < 10 ? "0" + n : "" + n }

        if (fmt === 0) {
          // Day name + month name:  "Wednesday, February"
          dateOverlay.dateText = dateOverlay.dayNames[dow] + ", " + dateOverlay.monthNames[mon]
        } else if (fmt === 1) {
          // Day number + month number:  "25 / 02"
          dateOverlay.dateText = pad2(day) + " / " + pad2(mon + 1)
        } else if (fmt === 2) {
          // Full names:  "Wednesday, February 25, 2026"
          dateOverlay.dateText = dateOverlay.dayNames[dow] + ", " + dateOverlay.monthNames[mon]
                                 + " " + day + ", " + yr
        } else {
          // Full numbers:  "25 / 02 / 2026"
          dateOverlay.dateText = pad2(day) + " / " + pad2(mon + 1) + " / " + yr
        }
      }
    }

    Item {
      id: dateBg
      x: dateOverlay.posX * dateOverlay.width  - width  / 2
      y: dateOverlay.posY * dateOverlay.height - height / 2
      width:  dateLabel.implicitWidth  + vpx(8)
      height: dateLabel.implicitHeight + vpx(4)
      opacity: dateOverlay.opacity_val

      Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
      Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }

      StyledText {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: vpx(1)
        anchors.verticalCenterOffset:   vpx(1)
        text:           dateOverlay.dateText
        font.pixelSize: vpx(dateOverlay.fontSize)
        font.bold:      true
        color:          "#99000000"
        layer.enabled:  false
      }
      StyledText {
        id: dateLabel
        anchors.centerIn: parent
        text:           dateOverlay.dateText
        font.pixelSize: vpx(dateOverlay.fontSize)
        font.bold:      true
        color:          "#FFFFFF"
        layer.enabled:  false
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // FPS COUNTER OVERLAY
  // Keys used:
  //   cfg.showFPS      "true"/"false"
  //   cfg.fpsOnDash    "true"/"false"
  //   cfg.fpsPosX      0.0–1.0
  //   cfg.fpsPosY      0.0–1.0
  //   cfg.fpsFontSize  integer
  //   cfg.fpsOpacity   0.0–1.0
  // ══════════════════════════════════════════════════════════════════
  Item {
    id: fpsOverlay
    z: 9001
    anchors.fill: parent

    property bool   showFPS:    false
    property bool   fpsOnDash:  false
    property real   posX:       0.02
    property real   posY:       0.02
    property int    fontSize:   16
    property real   opacity_val: 1.0
    property int    frameCount: 0
    property int    fps:        0
    property string accentHex:  "#5d9809"

    visible: showFPS && fpsOnDash

    // Frame counter — SequentialAnimation fires every repaint
    SequentialAnimation {
      running: true
      loops: Animation.Infinite
      ScriptAction   { script: fpsOverlay.frameCount++ }
      PauseAnimation { duration: 1 }
    }

    // Refresh settings and compute FPS once per second
    Timer {
      interval: 1000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        var sf  = api.memory.get("cfg.showFPS")
        var fod = api.memory.get("cfg.fpsOnDash")
        var px  = api.memory.get("cfg.fpsPosX")
        var py  = api.memory.get("cfg.fpsPosY")
        var fs  = api.memory.get("cfg.fpsFontSize")
        var op  = api.memory.get("cfg.fpsOpacity")

        fpsOverlay.showFPS    = (sf  === "true")
        fpsOverlay.fpsOnDash  = (fod === null || fod === "" || fod === "true")
        fpsOverlay.posX       = (px  !== null && px  !== "") ? parseFloat(px)  : 0.02
        fpsOverlay.posY       = (py  !== null && py  !== "") ? parseFloat(py)  : 0.02
        fpsOverlay.fontSize   = (fs  !== null && fs  !== "") ? parseInt(fs)    : 16
        fpsOverlay.opacity_val = (op !== null && op  !== "") ? parseFloat(op)  : 1.0

        // Load accent color for FPS tint
        var accentColors = ["#5d9809","#0099CC","#FF5733","#8A2BE2","#FFAA00","#00BFA5","#E91E8C","#EEEEEE"]
        var fci = api.memory.get("cfg.fpsColor")
        var fciIdx = (fci !== null && fci !== "") ? parseInt(fci) : 0
        if (isNaN(fciIdx)) fciIdx = 0
        fpsOverlay.accentHex = accentColors[Math.max(0,Math.min(accentColors.length-1,fciIdx))]

        fpsOverlay.fps        = fpsOverlay.frameCount
        fpsOverlay.frameCount = 0
      }
    }

    Item {
      id: fpsBg
      x: fpsOverlay.posX * fpsOverlay.width  - width  / 2
      y: fpsOverlay.posY * fpsOverlay.height - height / 2
      width:  fpsLabel.implicitWidth  + vpx(8)
      height: fpsLabel.implicitHeight + vpx(4)
      opacity: fpsOverlay.opacity_val

      Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
      Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }

      StyledText {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: vpx(1)
        anchors.verticalCenterOffset:   vpx(1)
        text:           fpsOverlay.fps + " FPS"
        font.pixelSize: vpx(fpsOverlay.fontSize)
        font.bold:      true
        color:          "#99000000"
        layer.enabled:  false
      }

      StyledText {
        id: fpsLabel
        anchors.centerIn: parent
        text:           fpsOverlay.fps + " FPS"
        font.pixelSize: vpx(fpsOverlay.fontSize)
        font.bold:      true
        color:  fpsOverlay.fps >= 55 ? fpsOverlay.accentHex
              : fpsOverlay.fps >= 30 ? "#FFB800"
                                     : "#FF4444"
        layer.enabled: false
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // VIDEO BACKGROUND / MINI-FLOAT OVERLAY
  //
  // Layer plan:
  //   z:0  Background / Stage  (wallpaper)
  //   z:2  videoBgLayer        — VideoOutput + vignette in BG mode
  //                              (below Router so dashboard stays on top)
  //   z:3  Router              — dashboard UI
  //   z:50 videoUiLayer        — mini-float window (above dashboard, clickable)
  //
  // A single MediaPlayer (bgPlayer) + VideoOutput (sharedBgOut) is used
  // to avoid the Qt5 "neither renderer nor window control" crash.
  // ══════════════════════════════════════════════════════════════════

  // ── Shared state object (not visual) ─────────────────────────────
  QtObject {
    id: videoDashOverlay
    property bool   bgMode:    false
    property bool   miniMode:  false
    property string videoPath: ""
    property bool   playing:   false
  }

  MediaPlayer {
    id: bgPlayer
    volume: parseFloat(api.memory.get("cfg.videoVol") || "0.8")
    loops:  MediaPlayer.Infinite
    onError: {
      console.log("BG video error:", errorString, "src:", bgPlayer.source)
      bgPlayer.stop()
      bgPlayer.source = ""  // clear source prevents retry loop
      // Mark bg as inactive so VideoPage can reclaim renderer
      api.memory.set("cfg.videoBgMode",    "false")
      api.memory.set("cfg.videoBgPlaying", "false")
      root.bgOutActive = false
    }
    onStatusChanged: {
      if (status === MediaPlayer.Loaded && videoDashOverlay.playing)
        bgPlayer.play()
    }
  }

  // Debounce — wait 300ms after source change before calling play()
  Timer {
    id: bgPlayDebounce
    interval: 300; repeat: false; running: false
    onTriggered: {
      if (videoDashOverlay.playing && bgPlayer.source.toString() !== "")
        bgPlayer.play()
    }
  }

  // State poller — runs independently of any visual item
  Timer {
    interval: 500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      var bgMode = api.memory.get("cfg.videoBgMode") || "false"
      var bg   = bgMode === "true"
      var mini = api.memory.get("cfg.videoMiniMode")  === "true"
      var play = api.memory.get("cfg.videoBgPlaying") === "true"
      var path = api.memory.get("cfg.videoBgPath")    || ""

      // Handle animated wallpaper mode (WebP/GIF from Dynamics tab)
      var isWallpaper = bgMode === "wallpaper"
      root.bgWallpaperOn = isWallpaper
      if (isWallpaper) {
        var wp = api.memory.get("cfg.videoBgWallpaper") || ""
        var wpp = wp.split("\\").join("/")  // safe backslash replace — no regex
        if (wpp !== "" && wpp.indexOf("://") < 0)
          wpp = (wpp.charAt(1)===":") ? "file:///"+wpp : "file://"+wpp
        root.bgWallpaperPath = wpp
        // Still update overlay state even in wallpaper mode
        videoDashOverlay.bgMode  = false
        videoDashOverlay.miniMode= false
        videoDashOverlay.playing = false
      } else {
        if (root.bgWallpaperPath !== "") root.bgWallpaperPath = ""
      }

      if (isWallpaper) return  // wallpaper handled above — skip bgPlayer logic

      var wasBgActive = videoDashOverlay.bgMode || videoDashOverlay.miniMode
      videoDashOverlay.bgMode   = bg
      videoDashOverlay.miniMode = mini && !bg
      videoDashOverlay.playing  = play

      var isBgActive = bg || (mini && !bg)
      console.log("POLL: bg="+bg+" play="+play+" bgOutActive="+root.bgOutActive+" path="+(path.length>0?"yes":"no"))
      if (isBgActive && play && !root.bgOutActive) {
        if (!bgOutActivateTimer.running) {
          console.log("POLL: starting bgOutActivateTimer")
          bgOutActivateTimer.start()
        }
      } else if ((!isBgActive || !play) && root.bgOutActive) {
        // Immediately destroy VideoOutput and release renderer
        bgOutActivateTimer.stop()
        root.bgOutActive = false
        bgPlayer.stop()
        bgPlayer.source = ""
      }

      // Only drive bgPlayer when bg/mini mode is active and playing
      if (!isBgActive || !play) return

      var newUrl = ""
      if (path !== "") {
        var p = path.split("\\").join("/")
        newUrl = (p.indexOf("://") >= 0) ? p : (p.charAt(1)===":"?"file:///"+p:"file://"+p)
      }

      var curUrl = bgPlayer.source.toString()

      if (newUrl !== "" && curUrl !== newUrl) {
        bgPlayer.stop()
        bgPlayer.source = newUrl
        if (play) bgPlayDebounce.restart()
      } else if (play && bgPlayer.playbackState !== MediaPlayer.PlayingState && !bgPlayDebounce.running) {
        bgPlayer.play()
      } else if (!play && bgPlayer.playbackState === MediaPlayer.PlayingState) {
        bgPlayer.pause()
      }
    }
  }

  // bgOutActive: only true when bg/mini video should play.
  // Loader creates sharedBgOut only then — so no VideoOutput exists at startup
  // and no createBackend call is made until actually needed.
  property bool bgOutActive: false

  Timer {
    id: bgOutActivateTimer
    interval: 800; repeat: false; running: false
    onTriggered: {
      console.log("THEME: bgOutActivateTimer fired, playing="+videoDashOverlay.playing+" bgMode="+videoDashOverlay.bgMode)
      if (videoDashOverlay.playing && (videoDashOverlay.bgMode || videoDashOverlay.miniMode)) {
        root.bgOutActive = true
        console.log("THEME: bgOutActive=true, bgPlayer.source="+bgPlayer.source)
      }
    }
  }

  // ── z:2 — BG video layer (below Router/dashboard) ────────────────
  Item {
    id: videoBgLayer
    anchors.fill: parent
    z: 2
    visible: root.bgOutActive

    Loader {
      id: bgOutLoader
      anchors.fill: parent
      active: root.bgOutActive
      sourceComponent: Component {
        VideoOutput {
          id: sharedBgOut
          source: bgPlayer
          layer.enabled: false
          x:      videoDashOverlay.miniMode ? miniFloat.x + vpx(2)       : 0
          y:      videoDashOverlay.miniMode ? miniFloat.y + vpx(30)      : 0
          width:  videoDashOverlay.miniMode ? miniFloat.width  - vpx(4)  : videoBgLayer.width
          height: videoDashOverlay.miniMode ? miniFloat.height - vpx(32) : videoBgLayer.height
          fillMode: videoDashOverlay.bgMode ? VideoOutput.PreserveAspectCrop : VideoOutput.PreserveAspectFit
          z: 1
        }
      }
    }
  }

  // ── z:50 — UI controls (above Router/dashboard) ──────────────────
  Item {
    id: videoUiLayer
    anchors.fill: parent
    z: 50
    visible: videoDashOverlay.playing && (videoDashOverlay.bgMode || videoDashOverlay.miniMode)

    // BG mode: stop button removed — BG video stops via Video Settings panel

    // ── MINI MODE: draggable floating box shell ──────────────────────
    Item {
      id: miniFloat
      visible: videoDashOverlay.miniMode
      z: 55

      property int floatX: root.width  - vpx(364)
      property int floatY: root.height - vpx(230)

      x: floatX
      y: floatY
      width:  vpx(360)
      height: vpx(220)

      // Drop shadow
      Rectangle {
        anchors.fill:    parent
        anchors.margins: vpx(-4)
        radius:  vpx(12)
        color:   "#99000000"
        z: -1
      }

      // Border frame
      Rectangle {
        id: miniFrame
        anchors.fill: parent
        radius: vpx(10)
        color:  "transparent"
        z: 3
        border.width: vpx(2)
        border.color: Qt.rgba(
          parseInt((api.memory.get("cfg.accentHex")||"#0099CC").substr(1,2),16)/255,
          parseInt((api.memory.get("cfg.accentHex")||"#0099CC").substr(3,2),16)/255,
          parseInt((api.memory.get("cfg.accentHex")||"#0099CC").substr(5,2),16)/255, 0.7)

        // Title bar
        Rectangle {
          id: miniTitleBar
          anchors.top:   parent.top
          anchors.left:  parent.left
          anchors.right: parent.right
          height: vpx(28)
          radius: vpx(10)
          color: "#CC000000"
          z: 4

          // Rounded only on top — cover bottom corners with a rect
          Rectangle {
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            height: vpx(10)
            color:  "#CC000000"
          }

          Row {
            anchors.left:           parent.left
            anchors.leftMargin:     vpx(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: vpx(6)
            StyledText { text: "🎬"; font.pixelSize: vpx(12); layer.enabled: false }
            StyledText {
              text: (api.memory.get("cfg.videoBgPath")||"").split(/[/\\]/).pop().replace(/\.[^.]+$/,"") || "Video"
              font.pixelSize: vpx(11); color: "#CCCCDD"; layer.enabled: false
              width: vpx(220); elide: Text.ElideRight
            }
          }

          // Close button
          Rectangle {
            id: miniCloseBtn
            anchors.right:          parent.right
            anchors.rightMargin:    vpx(6)
            anchors.verticalCenter: parent.verticalCenter
            width: vpx(20); height: vpx(20); radius: vpx(4)
            color: miniCloseMA.containsMouse ? "#CC993333" : "transparent"
            Behavior on color { ColorAnimation { duration: 60 } }
            StyledText { anchors.centerIn: parent; text: "✕"; font.pixelSize: vpx(11); color: "#FF8888"; layer.enabled: false }
            MouseArea {
              id: miniCloseMA
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                bgPlayer.pause()
                api.memory.set("cfg.videoBgPlaying", "false")
                api.memory.set("cfg.videoBgMode",    "false")
                api.memory.set("cfg.videoMiniMode",  "false")
              }
            }
          }

          // Expand button
          Rectangle {
            anchors.right:          miniCloseBtn.left
            anchors.rightMargin:    vpx(4)
            anchors.verticalCenter: parent.verticalCenter
            width: vpx(20); height: vpx(20); radius: vpx(4)
            color: miniExpandMA.containsMouse ? "#44FFFFFF" : "transparent"
            Behavior on color { ColorAnimation { duration: 60 } }
            StyledText { anchors.centerIn: parent; text: "⬆"; font.pixelSize: vpx(11); color: "#AAAACC"; layer.enabled: false }
            MouseArea {
              id: miniExpandMA
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                api.memory.set("cfg.videoMiniMode",  "false")
                api.memory.set("cfg.videoBgPlaying", "false")
                router.navigate({ path: "Video/VideoDetails.qml", showStage: false })
              }
            }
          }

          // Drag area
          MouseArea {
            anchors.left:   parent.left
            anchors.right:  miniCloseBtn.left
            anchors.rightMargin: vpx(28)
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            cursorShape: Qt.SizeAllCursor
            property int dragStartX: 0
            property int dragStartY: 0
            property int itemStartX: 0
            property int itemStartY: 0
            onPressed: {
              dragStartX = mouse.x; dragStartY = mouse.y
              itemStartX = miniFloat.floatX; itemStartY = miniFloat.floatY
            }
            onPositionChanged: {
              if (pressed) {
                miniFloat.floatX = Math.max(0, Math.min(root.width  - miniFloat.width,  itemStartX + mouse.x - dragStartX))
                miniFloat.floatY = Math.max(0, Math.min(root.height - miniFloat.height, itemStartY + mouse.y - dragStartY))
              }
            }
          }
        }

        // Play/pause overlay (shown when paused or on hover)
        Rectangle {
          id: miniPlayBtn
          anchors.centerIn: parent
          anchors.verticalCenterOffset: vpx(14)
          width: vpx(44); height: vpx(44); radius: vpx(22)
          z: 5
          color: Qt.rgba(
            parseInt((api.memory.get("cfg.accentHex")||"#0099CC").substr(1,2),16)/255,
            parseInt((api.memory.get("cfg.accentHex")||"#0099CC").substr(3,2),16)/255,
            parseInt((api.memory.get("cfg.accentHex")||"#0099CC").substr(5,2),16)/255, 0.85)
          border.color: "#FFFFFF"; border.width: vpx(2)
          visible: bgPlayer.playbackState !== MediaPlayer.PlayingState || miniVideoMA.containsMouse
          StyledText {
            anchors.centerIn: parent
            text: bgPlayer.playbackState === MediaPlayer.PlayingState ? "⏸" : "▶"
            font.pixelSize: vpx(20); color: "#FFFFFF"; layer.enabled: false
          }
        }

        // Click-to-play/pause over the video area
        MouseArea {
          id: miniVideoMA
          anchors.top:    miniTitleBar.bottom
          anchors.left:   parent.left
          anchors.right:  parent.right
          anchors.bottom: parent.bottom
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          z: 4
          onClicked: {
            if (bgPlayer.playbackState === MediaPlayer.PlayingState) {
              bgPlayer.pause()
              api.memory.set("cfg.videoBgPlaying", "false")
              videoDashOverlay.playing = false
            } else {
              bgPlayer.play()
              api.memory.set("cfg.videoBgPlaying", "true")
              videoDashOverlay.playing = true
            }
          }
        }
      }
    }
  }



  // ══════════════════════════════════════════════════════════════════
  // MINI MUSIC BAR — persistent overlay, survives navigate()
  // Hidden while MusicPage is open (it has its own player bar).
  // Draggable, position saved like the clock overlay.
  // Button style: "emoji" | "styled" | "plain"
  // ══════════════════════════════════════════════════════════════════
  Item {
    id: miniMusicBar
    z: 100

    // Hidden when MusicPage is open — MusicPage has its own full player
    property bool barEnabled: false   // driven by timer, avoids constant api.memory.get in binding
    visible: barEnabled

    // ── Draggable position (like clock) ──────────────────────────────
    property real floatXpct: 0.5
    property real floatYpct: 0.92
    x: floatXpct * root.width  - width  / 2
    y: floatYpct * root.height - height / 2
    property string barMode: {
      var m = api.memory.get("cfg.miniBarMode") || "row1"
      if (m === "row1") return "row1"
      if (m === "row2") return "bar"
      if (m === "micro") return "micro"
      if (m === "toast") return "toast"
      return m  // "bar" | "row1" | "card" | "wide" | "toast" | "micro"
    }
    property int    artSize: barMode === "card" ? 80 : barMode === "wide" ? 72 : barMode === "micro" ? 54 : barMode === "row1" ? 26 : 32
    width:  barMode === "card" ? vpx(230) : barMode === "wide" ? vpx(390) : barMode === "toast" ? vpx(560) : barMode === "micro" ? vpx(260) : barMode === "row1" ? vpx(560) : vpx(560)
    height: barMode === "card" ? vpx(104) : barMode === "wide" ? vpx(160) : barMode === "toast" ? vpx(56)  : barMode === "micro" ? vpx(90)  : barMode === "row1" ? vpx(42)  : vpx(76)

    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

    // ── Appearance settings ───────────────────────────────────────────
    // btnStyle: "emoji" | "styled" | "plain"
    property string btnStyle:    "emoji"
    property bool   showOutline: true
    property bool   isShuffle:   false
    property bool   isRepeat:    false
    property bool   isRepeatAll: true

    // ── Colors ────────────────────────────────────────────────────────
    property string accentHex:   "#0099CC"
    property string themeHex:    "#111122"
    property color  accentColor: Qt.rgba(
      parseInt(accentHex.substr(1,2),16)/255,
      parseInt(accentHex.substr(3,2),16)/255,
      parseInt(accentHex.substr(5,2),16)/255, 1.0)
    property color  themeColor: Qt.rgba(
      parseInt(themeHex.substr(1,2),16)/255,
      parseInt(themeHex.substr(3,2),16)/255,
      parseInt(themeHex.substr(5,2),16)/255, 0.97)

    // ── Track state ───────────────────────────────────────────────────
    property string trackTitle:  "Not Playing"
    property string trackArtist: ""
    property string trackCover:  ""
    property bool   isPlaying:   false
    property real   progress:    0.0
    property real   volumeLevel: 0.8

    // ── Button label helpers ──────────────────────────────────────────
    function btnLabel(emoji, styled, plain) {
      if (btnStyle === "emoji")  return emoji
      if (btnStyle === "styled") return styled
      return plain
    }

    // ── Path normalizer ───────────────────────────────────────────────
    function normalizePath(rawPath) {
      if (!rawPath || rawPath === "") return ""
      var p = rawPath.split("\\").join("/")
      var i; var out = ""
      for (i = 0; i < p.length; i++) { var c = p.charAt(i); out += (c === "\\") ? "/" : c }
      p = out
      if (p.indexOf("://") < 0) {
        p = (p.length > 1 && p.charAt(1) === ":") ? "file:///" + p : "file://" + p
      } else if (p.indexOf("file:///") < 0 && p.indexOf("file://") === 0) {
        var after = p.substring(7)
        if (after.length > 0 && after.charAt(0) !== "/") p = "file:///" + after
      }
      return p
    }

    // ── THE AUDIO PLAYER — lives in theme.qml, never destroyed ───────
    Audio {
      id: miniPlayer
      volume: miniMusicBar.volumeLevel
      onStatusChanged: {
        if (status === Audio.EndOfMedia) {
          if (miniMusicBar.isRepeat) { miniPlayer.seek(0); miniPlayer.play(); return }
          api.memory.set("cfg.miniCmd", "next")
        }
      }
      onPlaybackStateChanged: {
        miniMusicBar.isPlaying = (playbackState === Audio.PlayingState)
        api.memory.set("cfg.miniPlaying", miniMusicBar.isPlaying ? "true" : "false")
      }
    }

    // ── Poll timer — slow when bar disabled, 600ms when active ─────
    // 600ms is fast enough for smooth UX, slow enough to avoid stutter.
    // All property writes are guarded against no-op so bindings don't fire unless value changes.
    Timer {
      interval: miniMusicBar.barEnabled ? 600 : 2000
      running: true; repeat: true
      onTriggered: {
        // Always check enabled state first — cheap read
        var dashOn  = api.memory.get("cfg.musicDashBar")  === "true"
        var pageOn  = api.memory.get("cfg.musicPageOpen") === "true"
        miniMusicBar.barEnabled = dashOn && !pageOn

        // Skip ALL expensive work when bar is disabled
        if (!dashOn) return

        // Colors — only assign when changed to avoid triggering bindings
        var ah = api.memory.get("cfg.accentHex")
        if (ah && ah.length === 7 && ah.charAt(0) === "#" && ah !== miniMusicBar.accentHex) miniMusicBar.accentHex = ah
        var th = api.memory.get("cfg.themeHex")
        if (th && th.length === 7 && th.charAt(0) === "#" && th !== miniMusicBar.themeHex) miniMusicBar.themeHex = th

        // Volume + appearance — guard all assigns against no-op writes
        var vol = parseFloat(api.memory.get("cfg.musicVol") || "0.8")
        if (!isNaN(vol) && vol !== miniMusicBar.volumeLevel) miniMusicBar.volumeLevel = vol

        var bs = api.memory.get("cfg.miniBarBtnStyle")
        if ((bs === "emoji" || bs === "styled" || bs === "plain") && bs !== miniMusicBar.btnStyle) miniMusicBar.btnStyle = bs
        var so = api.memory.get("cfg.miniBarOutline")
        var soVal = (so === null || so === "" || so === "true")
        if (soVal !== miniMusicBar.showOutline) miniMusicBar.showOutline = soVal
        var bm = api.memory.get("cfg.miniBarMode") || "row1"
        if (bm === "row2") bm = "bar"
        if ((bm === "row1" || bm === "bar" || bm === "card" || bm === "wide" || bm === "toast" || bm === "micro") && bm !== miniMusicBar.barMode) miniMusicBar.barMode = bm

        var sh = api.memory.get("cfg.musicShuffle")  === "true"
        var rp = api.memory.get("cfg.musicRepeat")    === "true"
        var ra = api.memory.get("cfg.musicRepeatAll") !== "false"
        if (sh !== miniMusicBar.isShuffle)   miniMusicBar.isShuffle   = sh
        if (rp !== miniMusicBar.isRepeat)    miniMusicBar.isRepeat    = rp
        if (ra !== miniMusicBar.isRepeatAll) miniMusicBar.isRepeatAll = ra

        // Position — threshold guard prevents re-triggering Behavior animations every tick
        var px = parseFloat(api.memory.get("cfg.miniBarPosX") || "0.5")
        var py = parseFloat(api.memory.get("cfg.miniBarPosY") || "0.92")
        if (!isNaN(px) && Math.abs(px - miniMusicBar.floatXpct) > 0.001) miniMusicBar.floatXpct = px
        if (!isNaN(py) && Math.abs(py - miniMusicBar.floatYpct) > 0.001) miniMusicBar.floatYpct = py

        // Track metadata — only assign on change
        var tt = api.memory.get("cfg.miniTitle")  || "Not Playing"
        var ta = api.memory.get("cfg.miniArtist") || ""
        var tc = api.memory.get("cfg.miniCover")  || ""
        if (tt !== miniMusicBar.trackTitle)  miniMusicBar.trackTitle  = tt
        if (ta !== miniMusicBar.trackArtist) miniMusicBar.trackArtist = ta
        if (tc !== miniMusicBar.trackCover)  miniMusicBar.trackCover  = tc

        // Write live state back only when playing — skip unnecessary writes
        if (miniMusicBar.isPlaying || miniPlayer.duration > 0) {
          var dur = miniPlayer.duration > 0 ? miniPlayer.duration : 1
          miniMusicBar.progress = miniPlayer.position / dur
          api.memory.set("cfg.miniProgress", miniMusicBar.progress.toString())
          api.memory.set("cfg.miniPlaying",  miniMusicBar.isPlaying ? "true" : "false")
        }

        // Command dispatch
        var cmd = api.memory.get("cfg.miniCmd")
        if (!cmd || cmd === "") return

        if (cmd === "play" || cmd === "resume") {
          api.memory.set("cfg.miniCmd", "")
          // Prefer miniLastSrc (written by MusicPage on Back) over miniSrc
          var src = api.memory.get("cfg.miniLastSrc") || api.memory.get("cfg.miniSrc") || ""
          if (src !== "") {
            var norm = miniMusicBar.normalizePath(src)
            var curSrc = miniPlayer.source.toString()
            if (curSrc !== norm) {
              miniPlayer.stop(); miniPlayer.source = ""; miniPlayer.source = norm
            }
          }
          // Restore saved position if this is a handoff from MusicPage
          var savedPos = parseInt(api.memory.get("cfg.miniLastPos") || "0")
          if (savedPos > 0 && miniPlayer.source.toString() !== "") {
            // Seek after a short delay so the source has loaded
            var resumeSeekTimer = Qt.createQmlObject('import QtQml 2.15; Timer { interval: 350; repeat: false; running: true }', miniMusicBar)
            resumeSeekTimer.triggered.connect(function() {
              miniPlayer.play()
              miniPlayer.seek(savedPos)
              api.memory.set("cfg.miniLastPos", "0")
            })
          } else {
            miniPlayer.play()
          }

        } else if (cmd === "pause") {
          api.memory.set("cfg.miniCmd", ""); miniPlayer.pause()

        } else if (cmd === "stop") {
          api.memory.set("cfg.miniCmd", ""); miniPlayer.stop()

        } else if (cmd === "seek0") {
          api.memory.set("cfg.miniCmd", ""); miniPlayer.seek(0)

        } else if (cmd === "prev" || cmd === "next") {
          api.memory.set("cfg.miniCmd", "")
          var listJson = api.memory.get("cfg.musicTrackList") || "[]"
          var trackList = []
          try { trackList = JSON.parse(listJson) } catch(e) {}
          if (trackList.length === 0) return
          var lastIdx = parseInt(api.memory.get("cfg.musicLastIdx") || "0")
          var shuffle = api.memory.get("cfg.musicShuffle") === "true"
          var newIdx
          if (shuffle) {
            newIdx = Math.floor(Math.random() * trackList.length)
          } else if (cmd === "prev") {
            newIdx = (lastIdx - 1 + trackList.length) % trackList.length
          } else {
            newIdx = (lastIdx + 1) % trackList.length
          }
          var t = trackList[newIdx]
          if (t && t.path) {
            api.memory.set("cfg.musicLastIdx", newIdx.toString())
            miniMusicBar.trackTitle  = t.title  || "Unknown"
            miniMusicBar.trackArtist = t.artist || ""
            miniMusicBar.trackCover  = t.cover  || ""
            api.memory.set("cfg.miniTitle",  miniMusicBar.trackTitle)
            api.memory.set("cfg.miniArtist", miniMusicBar.trackArtist)
            api.memory.set("cfg.miniCover",  miniMusicBar.trackCover)
            var np = miniMusicBar.normalizePath(t.path)
            miniPlayer.stop(); miniPlayer.source = ""; miniPlayer.source = np; miniPlayer.play()
          }
        }
      }
    }

    // ── Drag handler — bar mode: left 52%; card mode: top title strip ─
    MouseArea {
      id: dragArea
      anchors.left: parent.left; anchors.top: parent.top
      anchors.right: (miniMusicBar.barMode === "card" || miniMusicBar.barMode === "wide") ? parent.right : undefined
      anchors.bottom: (miniMusicBar.barMode === "card" || miniMusicBar.barMode === "wide") ? undefined : parent.bottom
      width:  (miniMusicBar.barMode === "card" || miniMusicBar.barMode === "wide") ? undefined : parent.width * 0.52
      height: (miniMusicBar.barMode === "card" || miniMusicBar.barMode === "wide") ? vpx(32) : undefined
      cursorShape: Qt.SizeAllCursor
      property real dragStartX: 0; property real dragStartY: 0
      property real itemStartXpct: 0; property real itemStartYpct: 0
      onPressed: {
        dragStartX = mouse.x; dragStartY = mouse.y
        itemStartXpct = miniMusicBar.floatXpct
        itemStartYpct = miniMusicBar.floatYpct
      }
      onPositionChanged: {
        if (!pressed) return
        var dx = (mouse.x - dragStartX) / root.width
        var dy = (mouse.y - dragStartY) / root.height
        var nx = Math.max(0.05, Math.min(0.95, itemStartXpct + dx))
        var ny = Math.max(0.02, Math.min(0.97, itemStartYpct + dy))
        miniMusicBar.floatXpct = nx
        miniMusicBar.floatYpct = ny
        api.memory.set("cfg.miniBarPosX", nx.toString())
        api.memory.set("cfg.miniBarPosY", ny.toString())
      }
    }

    // ── Placement arrows (shown on hover over drag area) ─────────────
    Item {
      id: placementArrows
      anchors.centerIn: parent
      width: vpx(120); height: vpx(120)
      visible: dragArea.containsMouse
      opacity: 0.7

      // Top
      Rectangle {
        width: vpx(28); height: vpx(22); radius: vpx(4)
        anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top
        color: topArrowMA.containsMouse ? miniMusicBar.accentColor : "#44FFFFFF"
        Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: vpx(12); color: "#FFFFFF" }
        MouseArea { id: topArrowMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: { miniMusicBar.floatYpct = 0.05; api.memory.set("cfg.miniBarPosY","0.05") } }
      }
      // Bottom
      Rectangle {
        width: vpx(28); height: vpx(22); radius: vpx(4)
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
        color: botArrowMA.containsMouse ? miniMusicBar.accentColor : "#44FFFFFF"
        Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: vpx(12); color: "#FFFFFF" }
        MouseArea { id: botArrowMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: { miniMusicBar.floatYpct = 0.92; api.memory.set("cfg.miniBarPosY","0.92") } }
      }
      // Left
      Rectangle {
        width: vpx(28); height: vpx(22); radius: vpx(4)
        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
        color: leftArrowMA.containsMouse ? miniMusicBar.accentColor : "#44FFFFFF"
        Text { anchors.centerIn: parent; text: "◄"; font.pixelSize: vpx(12); color: "#FFFFFF" }
        MouseArea { id: leftArrowMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: { miniMusicBar.floatXpct = 0.15; api.memory.set("cfg.miniBarPosX","0.15") } }
      }
      // Right
      Rectangle {
        width: vpx(28); height: vpx(22); radius: vpx(4)
        anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right
        color: rightArrowMA.containsMouse ? miniMusicBar.accentColor : "#44FFFFFF"
        Text { anchors.centerIn: parent; text: "►"; font.pixelSize: vpx(12); color: "#FFFFFF" }
        MouseArea { id: rightArrowMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: { miniMusicBar.floatXpct = 0.85; api.memory.set("cfg.miniBarPosX","0.85") } }
      }
      // Centre
      Rectangle {
        width: vpx(28); height: vpx(22); radius: vpx(4)
        anchors.centerIn: parent
        color: centreArrowMA.containsMouse ? miniMusicBar.accentColor : "#44FFFFFF"
        Text { anchors.centerIn: parent; text: "⊙"; font.pixelSize: vpx(11); color: "#FFFFFF" }
        MouseArea { id: centreArrowMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: { miniMusicBar.floatXpct = 0.5; miniMusicBar.floatYpct = 0.92
            api.memory.set("cfg.miniBarPosX","0.5"); api.memory.set("cfg.miniBarPosY","0.92") } }
      }
    }

    // ── Background card ───────────────────────────────────────────────
    Rectangle {
      anchors.fill: parent; radius: vpx(10)
      color: Qt.rgba(miniMusicBar.themeColor.r, miniMusicBar.themeColor.g, miniMusicBar.themeColor.b, 0.97)
      border.color: miniMusicBar.accentColor; border.width: vpx(1)
    }
    Rectangle {
      anchors.fill: parent; radius: vpx(10)
      color: Qt.rgba(miniMusicBar.accentColor.r, miniMusicBar.accentColor.g, miniMusicBar.accentColor.b, 0.10)
    }

    // ── Seek bar — hidden for row1 (row1 has its own inline seek) ────
    Rectangle {
      id: seekBar
      visible: miniMusicBar.barMode !== "row1"
      anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
      height: vpx(4); color: "#1AFFFFFF"
      Rectangle {
        id: seekFill
        width: Math.max(0, Math.min(1, miniMusicBar.progress)) * parent.width
        height: parent.height; color: miniMusicBar.accentColor
        Behavior on width { NumberAnimation { duration: 600 } }
      }
      MouseArea {
        anchors.fill: parent; anchors.margins: vpx(-6); cursorShape: Qt.SizeHorCursor
        onPressed: {
          var pct = Math.max(0, Math.min(1, mouse.x / seekBar.width))
          var dur = miniPlayer.duration > 0 ? miniPlayer.duration : 1
          miniPlayer.seek(pct * dur)
        }
        onPositionChanged: {
          if (!pressed) return
          var pct2 = Math.max(0, Math.min(1, mouse.x / seekBar.width))
          var dur2 = miniPlayer.duration > 0 ? miniPlayer.duration : 1
          miniPlayer.seek(pct2 * dur2)
        }
      }
    }

    // ── Content — switches between bar layout and card layout ────────
    // BAR MODE (slim horizontal strip)
    Row {
      visible: miniMusicBar.barMode === "bar"
      anchors.left: parent.left; anchors.right: parent.right
      anchors.top: parent.top; anchors.bottom: seekBar.top
      anchors.leftMargin: vpx(10); anchors.rightMargin: vpx(10)
      anchors.topMargin: vpx(6); anchors.bottomMargin: vpx(4)
      spacing: vpx(8)

      Rectangle {
        width: vpx(miniMusicBar.artSize); height: vpx(miniMusicBar.artSize)
        anchors.verticalCenter: parent.verticalCenter
        radius: vpx(6); color: "#1A1A2E"
        border.color: miniMusicBar.showOutline ? miniMusicBar.accentColor : "transparent"; border.width: vpx(1); clip: true
        Image { anchors.fill: parent; source: miniMusicBar.trackCover; fillMode: Image.PreserveAspectCrop; smooth: true; visible: status === Image.Ready }
        Text { anchors.centerIn: parent; text: "♪"; font.pixelSize: vpx(Math.round(miniMusicBar.artSize * 0.44)); color: miniMusicBar.accentColor; opacity: 0.6
          RotationAnimator on rotation { running: miniMusicBar.isPlaying; from: 0; to: 360; duration: 5000; loops: Animation.Infinite } }
      }
      Column {
        width: vpx(150); anchors.verticalCenter: parent.verticalCenter; spacing: vpx(2)
        Text { width: parent.width; text: miniMusicBar.trackTitle; font.pixelSize: vpx(13); font.bold: true; color: "#FFFFFF"; elide: Text.ElideRight }
        Text { width: parent.width; text: miniMusicBar.trackArtist; font.pixelSize: vpx(11); color: miniMusicBar.accentColor; elide: Text.ElideRight }
      }
      Item { width: vpx(4); height: 1; anchors.verticalCenter: parent.verticalCenter }
      // Shuffle
      Rectangle {
        property string lbl: miniMusicBar.btnLabel("🔀","Shuffle","Shuffle")
        height: vpx(26); width: barShufTxt.implicitWidth + vpx(miniMusicBar.showOutline ? 14 : 4)
        radius: miniMusicBar.showOutline ? vpx(5) : 0; anchors.verticalCenter: parent.verticalCenter
        color: miniMusicBar.isShuffle ? Qt.rgba(miniMusicBar.accentColor.r,miniMusicBar.accentColor.g,miniMusicBar.accentColor.b,0.30) : (miniMusicBar.showOutline?"#22FFFFFF":"transparent")
        border.color: miniMusicBar.showOutline?(miniMusicBar.isShuffle?miniMusicBar.accentColor:"#33FFFFFF"):"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
        Text { id: barShufTxt; anchors.centerIn: parent; text: parent.lbl; font.pixelSize: vpx(miniMusicBar.btnStyle==="emoji"?15:11); color: miniMusicBar.isShuffle?miniMusicBar.accentColor:"#888899" }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
          onClicked: { var v=!miniMusicBar.isShuffle; miniMusicBar.isShuffle=v; api.memory.set("cfg.musicShuffle",v?"true":"false") } }
      }
      // Previous
      Rectangle {
        property string lbl: miniMusicBar.btnLabel("⏮","Previous","Previous")
        height: vpx(26); width: barPrevTxt.implicitWidth + vpx(miniMusicBar.showOutline ? 14 : 4)
        radius: miniMusicBar.showOutline?vpx(5):0; anchors.verticalCenter: parent.verticalCenter
        color: miniMusicBar.showOutline?"#22FFFFFF":"transparent"
        border.color: miniMusicBar.showOutline?"#33FFFFFF":"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
        Text { id: barPrevTxt; anchors.centerIn: parent; text: parent.lbl; font.pixelSize: vpx(miniMusicBar.btnStyle==="emoji"?15:11); color: "#FFFFFF" }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: api.memory.set("cfg.miniCmd","prev") }
      }
      // Play/Pause
      Rectangle {
        property string lbl: miniMusicBar.isPlaying?miniMusicBar.btnLabel("⏸","Pause","Pause"):miniMusicBar.btnLabel("▶","Play","Play")
        height: vpx(26); width: barPlayTxt.implicitWidth + vpx(miniMusicBar.showOutline ? 18 : 4)
        radius: miniMusicBar.showOutline?vpx(5):0; anchors.verticalCenter: parent.verticalCenter
        color: miniMusicBar.showOutline?miniMusicBar.accentColor:"transparent"
        border.color: miniMusicBar.showOutline?"#FFFFFF":"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
        Text { id: barPlayTxt; anchors.centerIn: parent; text: parent.lbl; font.pixelSize: vpx(miniMusicBar.btnStyle==="emoji"?15:11); color: "#FFFFFF" }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: api.memory.set("cfg.miniCmd",miniMusicBar.isPlaying?"pause":"resume") }
      }
      // Next
      Rectangle {
        property string lbl: miniMusicBar.btnLabel("⏭","Next","Next")
        height: vpx(26); width: barNextTxt.implicitWidth + vpx(miniMusicBar.showOutline ? 14 : 4)
        radius: miniMusicBar.showOutline?vpx(5):0; anchors.verticalCenter: parent.verticalCenter
        color: miniMusicBar.showOutline?"#22FFFFFF":"transparent"
        border.color: miniMusicBar.showOutline?"#33FFFFFF":"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
        Text { id: barNextTxt; anchors.centerIn: parent; text: parent.lbl; font.pixelSize: vpx(miniMusicBar.btnStyle==="emoji"?15:11); color: "#FFFFFF" }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: api.memory.set("cfg.miniCmd","next") }
      }
      // Repeat
      Rectangle {
        property string lbl: miniMusicBar.isRepeat?miniMusicBar.btnLabel("🔂","Repeat One","Repeat One"):miniMusicBar.btnLabel("🔁","Repeat All","Repeat All")
        height: vpx(26); width: barRepTxt.implicitWidth + vpx(miniMusicBar.showOutline ? 14 : 4)
        radius: miniMusicBar.showOutline?vpx(5):0; anchors.verticalCenter: parent.verticalCenter
        color: (miniMusicBar.isRepeat||miniMusicBar.isRepeatAll)?Qt.rgba(miniMusicBar.accentColor.r,miniMusicBar.accentColor.g,miniMusicBar.accentColor.b,0.30):(miniMusicBar.showOutline?"#22FFFFFF":"transparent")
        border.color: miniMusicBar.showOutline?((miniMusicBar.isRepeat||miniMusicBar.isRepeatAll)?miniMusicBar.accentColor:"#33FFFFFF"):"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
        Text { id: barRepTxt; anchors.centerIn: parent; text: parent.lbl; font.pixelSize: vpx(miniMusicBar.btnStyle==="emoji"?14:11); color: (miniMusicBar.isRepeat||miniMusicBar.isRepeatAll)?miniMusicBar.accentColor:"#888899" }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (!miniMusicBar.isRepeat&&!miniMusicBar.isRepeatAll){miniMusicBar.isRepeatAll=true;api.memory.set("cfg.musicRepeatAll","true")}
            else if(miniMusicBar.isRepeatAll){miniMusicBar.isRepeatAll=false;miniMusicBar.isRepeat=true;api.memory.set("cfg.musicRepeatAll","false");api.memory.set("cfg.musicRepeat","true")}
            else{miniMusicBar.isRepeat=false;api.memory.set("cfg.musicRepeat","false")}
          }
        }
      }
    }

    // TOAST MODE — slim notification bar (560×56): small art | title+artist | ⏮▶⏭ | ✕
    Item {
      visible: miniMusicBar.barMode === "toast"
      anchors.fill: parent

      // Progress strip on bottom edge
      Rectangle {
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
        height: vpx(3); color: "#1AFFFFFF"
        Rectangle {
          width: Math.max(0, Math.min(1, miniMusicBar.progress)) * parent.width
          height: parent.height; color: miniMusicBar.accentColor
          Behavior on width { NumberAnimation { duration: 600 } }
        }
      }

      Row {
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: parent.top; anchors.bottom: parent.bottom
        anchors.leftMargin: vpx(10); anchors.rightMargin: vpx(10)
        anchors.topMargin: vpx(5); anchors.bottomMargin: vpx(8)
        spacing: vpx(8)

        // Small square art
        Rectangle {
          width: vpx(34); height: vpx(34); anchors.verticalCenter: parent.verticalCenter
          radius: vpx(4); color: "#1A1A2E"; clip: true
          border.color: miniMusicBar.showOutline ? miniMusicBar.accentColor : "transparent"; border.width: vpx(1)
          Image { anchors.fill: parent; source: miniMusicBar.trackCover; fillMode: Image.PreserveAspectCrop; smooth: true; visible: status === Image.Ready }
          StyledText { anchors.centerIn: parent; text: "♪"; font.pixelSize: vpx(13); color: miniMusicBar.accentColor; opacity: 0.6; layer.enabled: false
            RotationAnimator on rotation { running: miniMusicBar.isPlaying; from: 0; to: 360; duration: 5000; loops: Animation.Infinite } }
        }

        // Title + artist
        Column {
          width: vpx(200); anchors.verticalCenter: parent.verticalCenter; spacing: vpx(2)
          StyledText { width: parent.width; text: miniMusicBar.trackTitle;  font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF"; elide: Text.ElideRight; layer.enabled: false }
          StyledText { width: parent.width; text: miniMusicBar.trackArtist; font.pixelSize: vpx(10); color: miniMusicBar.accentColor; elide: Text.ElideRight; layer.enabled: false }
        }

        // Flexible spacer
        Item { width: parent.width - vpx(34) - vpx(200) - vpx(28+24+24+4*2) - vpx(22) - vpx(8)*5; height: 1; anchors.verticalCenter: parent.verticalCenter }

        // 3 transport buttons ⏮ ▶/⏸ ⏭
        Row {
          spacing: vpx(4); anchors.verticalCenter: parent.verticalCenter
          Rectangle {
            width: vpx(24); height: vpx(26); radius: miniMusicBar.showOutline?vpx(4):0
            color: miniMusicBar.showOutline?"#22FFFFFF":"transparent"
            border.color: miniMusicBar.showOutline?"#33FFFFFF":"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
            StyledText { anchors.centerIn: parent; text: miniMusicBar.btnLabel("⏮","Prev","Prev"); font.pixelSize: vpx(miniMusicBar.btnStyle==="emoji"?13:9); color: "#FFFFFF"; layer.enabled: false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: api.memory.set("cfg.miniCmd","prev") }
          }
          Rectangle {
            width: vpx(28); height: vpx(26); radius: miniMusicBar.showOutline?vpx(4):0
            color: miniMusicBar.showOutline?miniMusicBar.accentColor:"transparent"
            border.color: miniMusicBar.showOutline?"#FFFFFF":"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
            StyledText { anchors.centerIn: parent; text: miniMusicBar.isPlaying?miniMusicBar.btnLabel("⏸","Pause","Pause"):miniMusicBar.btnLabel("▶","Play","Play"); font.pixelSize: vpx(miniMusicBar.btnStyle==="emoji"?13:9); color: "#FFFFFF"; layer.enabled: false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: api.memory.set("cfg.miniCmd",miniMusicBar.isPlaying?"pause":"resume") }
          }
          Rectangle {
            width: vpx(24); height: vpx(26); radius: miniMusicBar.showOutline?vpx(4):0
            color: miniMusicBar.showOutline?"#22FFFFFF":"transparent"
            border.color: miniMusicBar.showOutline?"#33FFFFFF":"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
            StyledText { anchors.centerIn: parent; text: miniMusicBar.btnLabel("⏭","Next","Next"); font.pixelSize: vpx(miniMusicBar.btnStyle==="emoji"?13:9); color: "#FFFFFF"; layer.enabled: false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: api.memory.set("cfg.miniCmd","next") }
          }
        }

        // Dismiss ✕
        Rectangle {
          width: vpx(22); height: vpx(22); radius: vpx(4); anchors.verticalCenter: parent.verticalCenter
          color: tsCloseMA.containsMouse?"#44FFFFFF":"transparent"
          Behavior on color { ColorAnimation { duration: 60 } }
          StyledText { anchors.centerIn: parent; text: "✕"; font.pixelSize: vpx(11); color: "#667788"; layer.enabled: false }
          MouseArea { id: tsCloseMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
            onClicked: { api.memory.set("cfg.musicDashBar","false"); api.memory.set("cfg.miniCmd","stop"); miniMusicBar.barEnabled = false } }
        }
      }
    }

    // CARD MODE — ultra compact, artist/title stacked tight, buttons flush
    Column {
      visible: miniMusicBar.barMode === "card"
      anchors.fill: parent
      spacing: 0

      // Invisible drag spacer
      Item { width: parent.width; height: vpx(32) }

      // Artist — centred, accent, no extra padding
      StyledText {
        width: parent.width
        topPadding: vpx(4); leftPadding: vpx(6); rightPadding: vpx(6)
        text: miniMusicBar.trackArtist
        font.pixelSize: vpx(11); color: miniMusicBar.accentColor
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight; layer.enabled: false
      }

      // Title — centred, tight below artist
      StyledText {
        width: parent.width
        topPadding: vpx(1); bottomPadding: vpx(5); leftPadding: vpx(6); rightPadding: vpx(6)
        text: miniMusicBar.trackTitle
        font.pixelSize: vpx(12); font.bold: true; color: "#FFFFFF"
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight; layer.enabled: false
      }

      // Controls row — tight, no extra padding
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: vpx(5)

        Rectangle {
          width: vpx(28); height: vpx(26); radius: miniMusicBar.showOutline?vpx(4):0
          color: miniMusicBar.isShuffle?Qt.rgba(miniMusicBar.accentColor.r,miniMusicBar.accentColor.g,miniMusicBar.accentColor.b,0.30):(miniMusicBar.showOutline?"#22FFFFFF":"transparent")
          border.color: miniMusicBar.showOutline?(miniMusicBar.isShuffle?miniMusicBar.accentColor:"#33FFFFFF"):"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
          StyledText { anchors.centerIn: parent; text: miniMusicBar.btnLabel("🔀","Shuffle","Shuffle"); font.pixelSize: vpx(miniMusicBar.btnStyle==="emoji"?14:10); color: miniMusicBar.isShuffle?miniMusicBar.accentColor:"#888899"; layer.enabled: false }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: { var v=!miniMusicBar.isShuffle; miniMusicBar.isShuffle=v; api.memory.set("cfg.musicShuffle",v?"true":"false") } }
        }
        Rectangle {
          width: vpx(28); height: vpx(26); radius: miniMusicBar.showOutline?vpx(4):0
          color: miniMusicBar.showOutline?"#22FFFFFF":"transparent"
          border.color: miniMusicBar.showOutline?"#33FFFFFF":"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
          StyledText { anchors.centerIn: parent; text: "⏮"; font.pixelSize: vpx(14); color: "#FFFFFF"; layer.enabled: false }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: api.memory.set("cfg.miniCmd","prev") }
        }
        Rectangle {
          width: vpx(32); height: vpx(26); radius: miniMusicBar.showOutline?vpx(4):0
          color: miniMusicBar.showOutline?miniMusicBar.accentColor:"transparent"
          border.color: miniMusicBar.showOutline?"#FFFFFF":"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
          StyledText { anchors.centerIn: parent; text: miniMusicBar.isPlaying?"⏸":"▶"; font.pixelSize: vpx(14); color: "#FFFFFF"; layer.enabled: false }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: api.memory.set("cfg.miniCmd",miniMusicBar.isPlaying?"pause":"resume") }
        }
        Rectangle {
          width: vpx(28); height: vpx(26); radius: miniMusicBar.showOutline?vpx(4):0
          color: miniMusicBar.showOutline?"#22FFFFFF":"transparent"
          border.color: miniMusicBar.showOutline?"#33FFFFFF":"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
          StyledText { anchors.centerIn: parent; text: "⏭"; font.pixelSize: vpx(14); color: "#FFFFFF"; layer.enabled: false }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: api.memory.set("cfg.miniCmd","next") }
        }
        Rectangle {
          width: vpx(28); height: vpx(26); radius: miniMusicBar.showOutline?vpx(4):0
          color: (miniMusicBar.isRepeat||miniMusicBar.isRepeatAll)?Qt.rgba(miniMusicBar.accentColor.r,miniMusicBar.accentColor.g,miniMusicBar.accentColor.b,0.30):(miniMusicBar.showOutline?"#22FFFFFF":"transparent")
          border.color: miniMusicBar.showOutline?((miniMusicBar.isRepeat||miniMusicBar.isRepeatAll)?miniMusicBar.accentColor:"#33FFFFFF"):"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
          StyledText { anchors.centerIn: parent; text: miniMusicBar.isRepeat?"🔂":"🔁"; font.pixelSize: vpx(14); color: (miniMusicBar.isRepeat||miniMusicBar.isRepeatAll)?miniMusicBar.accentColor:"#888899"; layer.enabled: false }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (!miniMusicBar.isRepeat&&!miniMusicBar.isRepeatAll){miniMusicBar.isRepeatAll=true;api.memory.set("cfg.musicRepeatAll","true")}
              else if(miniMusicBar.isRepeatAll){miniMusicBar.isRepeatAll=false;miniMusicBar.isRepeat=true;api.memory.set("cfg.musicRepeatAll","false");api.memory.set("cfg.musicRepeat","true")}
              else{miniMusicBar.isRepeat=false;api.memory.set("cfg.musicRepeat","false")}
            }
          }
        }
      }
    }

    // WIDE CARD MODE — art left, title+artist+seek+controls right, like screenshot
    Item {
      visible: miniMusicBar.barMode === "wide"
      anchors.fill: parent

      // Invisible drag strip at top
      Item { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: vpx(32) }

      // Album art — left side, square
      Rectangle {
        id: wideArt
        anchors.left: parent.left; anchors.leftMargin: vpx(8)
        anchors.verticalCenter: parent.verticalCenter
        width: vpx(120); height: vpx(120); radius: vpx(6)
        color: "#1A1A2E"; clip: true
        border.color: miniMusicBar.showOutline ? miniMusicBar.accentColor : "transparent"; border.width: vpx(1)
        Image { anchors.fill: parent; source: miniMusicBar.trackCover; fillMode: Image.PreserveAspectCrop; smooth: true; visible: status === Image.Ready }
        Text { anchors.centerIn: parent; text: "♪"; font.pixelSize: vpx(36); color: miniMusicBar.accentColor; opacity: 0.5
          RotationAnimator on rotation { running: miniMusicBar.isPlaying; from: 0; to: 360; duration: 5000; loops: Animation.Infinite } }
      }

      // Right side — title, artist, seek, controls
      Column {
        anchors.left: wideArt.right; anchors.leftMargin: vpx(10)
        anchors.right: parent.right; anchors.rightMargin: vpx(8)
        anchors.top: parent.top; anchors.topMargin: vpx(36)
        spacing: 0

        // Title
        Text {
          width: parent.width; topPadding: vpx(4)
          text: miniMusicBar.trackTitle
          font.pixelSize: vpx(13); font.bold: true; color: "#FFFFFF"; elide: Text.ElideRight
        }
        // Artist
        Text {
          width: parent.width; topPadding: vpx(2); bottomPadding: vpx(6)
          text: miniMusicBar.trackArtist
          font.pixelSize: vpx(11); color: miniMusicBar.accentColor; elide: Text.ElideRight
        }
        // Seek bar
        Item {
          width: parent.width; height: vpx(14)
          Rectangle {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: vpx(3); radius: vpx(2); color: "#22FFFFFF"
            Rectangle {
              width: Math.max(0, Math.min(1, miniMusicBar.progress)) * parent.width
              height: parent.height; radius: parent.radius; color: miniMusicBar.accentColor
              Behavior on width { NumberAnimation { duration: 600 } }
            }
          }
          MouseArea {
            anchors.fill: parent; cursorShape: Qt.SizeHorCursor
            onPressed: { var p=Math.max(0,Math.min(1,mouse.x/parent.width)); miniPlayer.seek(p*(miniPlayer.duration>0?miniPlayer.duration:1)) }
            onPositionChanged: { if(!pressed)return; var p2=Math.max(0,Math.min(1,mouse.x/parent.width)); miniPlayer.seek(p2*(miniPlayer.duration>0?miniPlayer.duration:1)) }
          }
        }
        // Controls
        Row {
          topPadding: vpx(6); spacing: vpx(6)
          // Shuffle
          Rectangle {
            width: vpx(30); height: vpx(28); radius: miniMusicBar.showOutline?vpx(5):0
            color: miniMusicBar.isShuffle?Qt.rgba(miniMusicBar.accentColor.r,miniMusicBar.accentColor.g,miniMusicBar.accentColor.b,0.30):(miniMusicBar.showOutline?"#22FFFFFF":"transparent")
            border.color: miniMusicBar.showOutline?(miniMusicBar.isShuffle?miniMusicBar.accentColor:"#33FFFFFF"):"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
            StyledText { anchors.centerIn: parent; text: miniMusicBar.btnLabel("🔀","Shuffle","Shuffle"); font.pixelSize: vpx(miniMusicBar.btnStyle==="emoji"?14:10); color: miniMusicBar.isShuffle?miniMusicBar.accentColor:"#888899"; layer.enabled: false }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: { var v=!miniMusicBar.isShuffle; miniMusicBar.isShuffle=v; api.memory.set("cfg.musicShuffle",v?"true":"false") } }
          }
          // Prev
          Rectangle {
            width: vpx(30); height: vpx(28); radius: miniMusicBar.showOutline?vpx(5):0
            color: miniMusicBar.showOutline?"#22FFFFFF":"transparent"
            border.color: miniMusicBar.showOutline?"#33FFFFFF":"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
            Text { anchors.centerIn: parent; text: miniMusicBar.btnLabel("⏮","Previous","Previous"); font.pixelSize: vpx(miniMusicBar.btnStyle==="emoji"?14:11); color: "#FFFFFF" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: api.memory.set("cfg.miniCmd","prev") }
          }
          // Play/Pause
          Rectangle {
            width: vpx(36); height: vpx(28); radius: miniMusicBar.showOutline?vpx(5):0
            color: miniMusicBar.showOutline?miniMusicBar.accentColor:"transparent"
            border.color: miniMusicBar.showOutline?"#FFFFFF":"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
            Text { anchors.centerIn: parent; text: miniMusicBar.isPlaying?"⏸":"▶"; font.pixelSize: vpx(14); color: "#FFFFFF" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: api.memory.set("cfg.miniCmd",miniMusicBar.isPlaying?"pause":"resume") }
          }
          // Next
          Rectangle {
            width: vpx(30); height: vpx(28); radius: miniMusicBar.showOutline?vpx(5):0
            color: miniMusicBar.showOutline?"#22FFFFFF":"transparent"
            border.color: miniMusicBar.showOutline?"#33FFFFFF":"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
            Text { anchors.centerIn: parent; text: "⏭"; font.pixelSize: vpx(14); color: "#FFFFFF" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: api.memory.set("cfg.miniCmd","next") }
          }
          // Repeat
          Rectangle {
            width: vpx(30); height: vpx(28); radius: miniMusicBar.showOutline?vpx(5):0
            color: (miniMusicBar.isRepeat||miniMusicBar.isRepeatAll)?Qt.rgba(miniMusicBar.accentColor.r,miniMusicBar.accentColor.g,miniMusicBar.accentColor.b,0.30):(miniMusicBar.showOutline?"#22FFFFFF":"transparent")
            border.color: miniMusicBar.showOutline?((miniMusicBar.isRepeat||miniMusicBar.isRepeatAll)?miniMusicBar.accentColor:"#33FFFFFF"):"transparent"; border.width: miniMusicBar.showOutline?vpx(1):0
            Text { anchors.centerIn: parent; text: miniMusicBar.isRepeat?"🔂":"🔁"; font.pixelSize: vpx(14); color: (miniMusicBar.isRepeat||miniMusicBar.isRepeatAll)?miniMusicBar.accentColor:"#888899" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (!miniMusicBar.isRepeat&&!miniMusicBar.isRepeatAll){miniMusicBar.isRepeatAll=true;api.memory.set("cfg.musicRepeatAll","true")}
                else if(miniMusicBar.isRepeatAll){miniMusicBar.isRepeatAll=false;miniMusicBar.isRepeat=true;api.memory.set("cfg.musicRepeatAll","false");api.memory.set("cfg.musicRepeat","true")}
                else{miniMusicBar.isRepeat=false;api.memory.set("cfg.musicRepeat","false")}
              }
            }
          }
        }
      }
    }


    // ROW1 MODE — anchor-based so seek truly fills from art/title to buttons
    // [art][title+artist][══════════seek══════════][EQ][Shuf][⏮][▶][⏭][Rep][Vol][🎵][✕]
    Item {
      visible: miniMusicBar.barMode === "row1"
      anchors.fill: parent

      // Album art — anchored left
      Rectangle {
        id: r1Art
        anchors.left: parent.left; anchors.leftMargin: vpx(8)
        anchors.verticalCenter: parent.verticalCenter
        width: vpx(26); height: vpx(26); radius: vpx(3); color: "#1A1A2E"; clip: true
        border.color: miniMusicBar.showOutline ? miniMusicBar.accentColor : "transparent"; border.width: vpx(1)
        Image { anchors.fill: parent; source: miniMusicBar.trackCover; fillMode: Image.PreserveAspectCrop; smooth: true; visible: status === Image.Ready }
        StyledText { anchors.centerIn: parent; text: "♪"; font.pixelSize: vpx(10); color: miniMusicBar.accentColor; opacity: 0.6; layer.enabled: false
          RotationAnimator on rotation { running: miniMusicBar.isPlaying; from: 0; to: 360; duration: 5000; loops: Animation.Infinite } }
      }

      // Title + artist — anchored right of art
      Column {
        id: r1Info
        anchors.left: r1Art.right; anchors.leftMargin: vpx(7)
        anchors.verticalCenter: parent.verticalCenter
        width: vpx(130); spacing: vpx(1)
        StyledText { width: parent.width; text: miniMusicBar.trackTitle; font.pixelSize: vpx(10); font.bold: true; color: "#FFFFFF"; elide: Text.ElideRight; layer.enabled: false }
        StyledText { width: parent.width; text: miniMusicBar.trackArtist; font.pixelSize: vpx(9); color: miniMusicBar.accentColor; elide: Text.ElideRight; layer.enabled: false }
      }

      // All buttons — anchored to right edge
      Row {
        id: r1Btns
        anchors.right: parent.right; anchors.rightMargin: vpx(6)
        anchors.verticalCenter: parent.verticalCenter
        spacing: vpx(3)
        // EQ
        Rectangle { width:vpx(22);height:vpx(22);radius:vpx(4);color:"#22FFFFFF";border.color:"#33FFFFFF";border.width:miniMusicBar.showOutline?vpx(1):0
          StyledText{anchors.centerIn:parent;text:"🎚";font.pixelSize:vpx(10);layer.enabled:false}
          MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:api.memory.set("cfg.miniCmd","toggleEQ")} }
        // Shuffle
        Rectangle { width:vpx(22);height:vpx(22);radius:vpx(4)
          color:miniMusicBar.isShuffle?Qt.rgba(miniMusicBar.accentColor.r,miniMusicBar.accentColor.g,miniMusicBar.accentColor.b,0.30):"#22FFFFFF"
          border.color:miniMusicBar.isShuffle?miniMusicBar.accentColor:"#33FFFFFF";border.width:miniMusicBar.showOutline?vpx(1):0
          StyledText{anchors.centerIn:parent;text:"🔀";font.pixelSize:vpx(10);color:miniMusicBar.isShuffle?miniMusicBar.accentColor:"#888899";layer.enabled:false}
          MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{var v=!miniMusicBar.isShuffle;miniMusicBar.isShuffle=v;api.memory.set("cfg.musicShuffle",v?"true":"false")}} }
        // Prev
        Rectangle { width:vpx(22);height:vpx(22);radius:vpx(4);color:"#22FFFFFF";border.color:"#33FFFFFF";border.width:miniMusicBar.showOutline?vpx(1):0
          StyledText{anchors.centerIn:parent;text:miniMusicBar.btnLabel("⏮","Prev","Prev");font.pixelSize:vpx(miniMusicBar.btnStyle==="emoji"?11:8);color:"#FFFFFF";layer.enabled:false}
          MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:api.memory.set("cfg.miniCmd","prev")} }
        // Play/Pause
        Rectangle { width:vpx(22);height:vpx(22);radius:vpx(4);color:miniMusicBar.accentColor
          border.color:miniMusicBar.showOutline?"#FFFFFF":"transparent";border.width:miniMusicBar.showOutline?vpx(1):0
          StyledText{anchors.centerIn:parent;text:miniMusicBar.isPlaying?miniMusicBar.btnLabel("⏸","Pause","Pause"):miniMusicBar.btnLabel("▶","Play","Play");font.pixelSize:vpx(miniMusicBar.btnStyle==="emoji"?11:8);color:"#FFFFFF";layer.enabled:false}
          MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:api.memory.set("cfg.miniCmd",miniMusicBar.isPlaying?"pause":"resume")} }
        // Next
        Rectangle { width:vpx(22);height:vpx(22);radius:vpx(4);color:"#22FFFFFF";border.color:"#33FFFFFF";border.width:miniMusicBar.showOutline?vpx(1):0
          StyledText{anchors.centerIn:parent;text:miniMusicBar.btnLabel("⏭","Next","Next");font.pixelSize:vpx(miniMusicBar.btnStyle==="emoji"?11:8);color:"#FFFFFF";layer.enabled:false}
          MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:api.memory.set("cfg.miniCmd","next")} }
        // Repeat
        Rectangle { width:vpx(22);height:vpx(22);radius:vpx(4)
          color:(miniMusicBar.isRepeat||miniMusicBar.isRepeatAll)?Qt.rgba(miniMusicBar.accentColor.r,miniMusicBar.accentColor.g,miniMusicBar.accentColor.b,0.30):"#22FFFFFF"
          border.color:(miniMusicBar.isRepeat||miniMusicBar.isRepeatAll)?miniMusicBar.accentColor:"#33FFFFFF";border.width:miniMusicBar.showOutline?vpx(1):0
          StyledText{anchors.centerIn:parent;text:miniMusicBar.isRepeat?"🔂":"🔁";font.pixelSize:vpx(10);color:(miniMusicBar.isRepeat||miniMusicBar.isRepeatAll)?miniMusicBar.accentColor:"#888899";layer.enabled:false}
          MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{
            if(!miniMusicBar.isRepeat&&!miniMusicBar.isRepeatAll){miniMusicBar.isRepeatAll=true;api.memory.set("cfg.musicRepeatAll","true")}
            else if(miniMusicBar.isRepeatAll){miniMusicBar.isRepeatAll=false;miniMusicBar.isRepeat=true;api.memory.set("cfg.musicRepeatAll","false");api.memory.set("cfg.musicRepeat","true")}
            else{miniMusicBar.isRepeat=false;api.memory.set("cfg.musicRepeat","false")}
          }} }
        // Vol-
        Rectangle { id:r1VolDn; width:miniMusicBar.btnStyle==="emoji"?vpx(22):(r1VolDnTxt.implicitWidth+vpx(8));height:vpx(22);radius:vpx(4)
          color:r1VolDnMA.containsMouse?"#44FFFFFF":"#22FFFFFF"
          border.color:"#33FFFFFF";border.width:miniMusicBar.showOutline?vpx(1):0
          Behavior on color{ColorAnimation{duration:60}}
          StyledText{id:r1VolDnTxt;anchors.centerIn:parent;text:miniMusicBar.btnLabel("🔉","Vol-","Vol-");font.pixelSize:vpx(miniMusicBar.btnStyle==="emoji"?10:8);color:"#FFFFFF";layer.enabled:false}
          MouseArea{id:r1VolDnMA;anchors.fill:parent;cursorShape:Qt.PointingHandCursor;hoverEnabled:true
            onClicked:{var v=Math.max(0,miniMusicBar.volumeLevel-0.05);miniMusicBar.volumeLevel=v;api.memory.set("cfg.musicVol",v.toString())}
            onWheel:{var v=Math.max(0,Math.min(1,miniMusicBar.volumeLevel+(wheel.angleDelta.y>0?0.05:-0.05)));miniMusicBar.volumeLevel=v;api.memory.set("cfg.musicVol",v.toString())}} }
        // Mute
        Rectangle { id:r1Mute; width:miniMusicBar.btnStyle==="emoji"?vpx(22):(r1MuteTxt.implicitWidth+vpx(8));height:vpx(22);radius:vpx(4)
          color:miniMusicBar.volumeLevel<=0?miniMusicBar.accentColor:(r1MuteMA.containsMouse?"#44FFFFFF":"#22FFFFFF")
          border.color:miniMusicBar.volumeLevel<=0?miniMusicBar.accentColor:"#33FFFFFF";border.width:miniMusicBar.showOutline?vpx(1):0
          Behavior on color{ColorAnimation{duration:60}}
          property real _preVol: 0.8
          StyledText{id:r1MuteTxt;anchors.centerIn:parent;text:miniMusicBar.btnLabel(miniMusicBar.volumeLevel<=0?"🔇":"🔊","Mute","Mute");font.pixelSize:vpx(miniMusicBar.btnStyle==="emoji"?10:8);color:"#FFFFFF";layer.enabled:false}
          MouseArea{id:r1MuteMA;anchors.fill:parent;cursorShape:Qt.PointingHandCursor;hoverEnabled:true
            onClicked:{if(miniMusicBar.volumeLevel>0){r1Mute._preVol=miniMusicBar.volumeLevel;miniMusicBar.volumeLevel=0}else{miniMusicBar.volumeLevel=r1Mute._preVol>0?r1Mute._preVol:0.8};api.memory.set("cfg.musicVol",miniMusicBar.volumeLevel.toString())}} }
        // Vol+
        Rectangle { id:r1VolUp; width:miniMusicBar.btnStyle==="emoji"?vpx(22):(r1VolUpTxt.implicitWidth+vpx(8));height:vpx(22);radius:vpx(4)
          color:r1VolUpMA.containsMouse?"#44FFFFFF":"#22FFFFFF"
          border.color:"#33FFFFFF";border.width:miniMusicBar.showOutline?vpx(1):0
          Behavior on color{ColorAnimation{duration:60}}
          StyledText{id:r1VolUpTxt;anchors.centerIn:parent;text:miniMusicBar.btnLabel("🔊","Vol+","Vol+");font.pixelSize:vpx(miniMusicBar.btnStyle==="emoji"?10:8);color:"#FFFFFF";layer.enabled:false}
          MouseArea{id:r1VolUpMA;anchors.fill:parent;cursorShape:Qt.PointingHandCursor;hoverEnabled:true
            onClicked:{var v=Math.min(1,miniMusicBar.volumeLevel+0.05);miniMusicBar.volumeLevel=v;api.memory.set("cfg.musicVol",v.toString())}
            onWheel:{var v=Math.max(0,Math.min(1,miniMusicBar.volumeLevel+(wheel.angleDelta.y>0?0.05:-0.05)));miniMusicBar.volumeLevel=v;api.memory.set("cfg.musicVol",v.toString())}} }
        // Music icon — stops miniPlayer FIRST, then opens MusicPage (prevents dual audio)
        Rectangle { width:vpx(22);height:vpx(22);radius:vpx(3)
          color:r1MusicMA.containsMouse?Qt.rgba(miniMusicBar.accentColor.r,miniMusicBar.accentColor.g,miniMusicBar.accentColor.b,0.35):"#1AFFFFFF"
          border.color:miniMusicBar.accentColor;border.width:vpx(1)
          StyledText{anchors.centerIn:parent;text:"🎵";font.pixelSize:vpx(10);layer.enabled:false}
          MouseArea{id:r1MusicMA;anchors.fill:parent;cursorShape:Qt.PointingHandCursor;hoverEnabled:true
            onClicked:{
              // Save position so MusicPage can resume from here
              api.memory.set("cfg.miniLastPos", miniPlayer.position.toString())
              api.memory.set("cfg.miniLastSrc", miniPlayer.source.toString())
              // Stop miniPlayer before navigating — prevents dual audio with MusicPage's player
              miniPlayer.stop()
              miniMusicBar.isPlaying = false
              api.memory.set("cfg.miniPlaying", "false")
              router.navigate({path:"Music/MusicPage.qml",showStage:false})
            }
          }
        }
        // Dismiss ✕
        Rectangle { width:vpx(16);height:vpx(16);radius:vpx(3);color:"transparent"
          StyledText{anchors.centerIn:parent;text:"✕";font.pixelSize:vpx(9);color:"#667788";layer.enabled:false}
          MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor
            onClicked:{api.memory.set("cfg.musicDashBar","false");api.memory.set("cfg.miniCmd","stop");miniMusicBar.barEnabled=false}} }
      }

      // Seek bar — anchors between title and buttons so it fills exactly that gap
      Item {
        id: r1Seek
        anchors.left:  r1Info.right;  anchors.leftMargin:  vpx(8)
        anchors.right: r1Btns.left;   anchors.rightMargin: vpx(8)
        anchors.top:    parent.top
        anchors.bottom: parent.bottom

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width; height: vpx(3); radius: vpx(2); color: "#22FFFFFF"
          Rectangle {
            width: Math.max(0, Math.min(1, miniMusicBar.progress)) * parent.width
            height: parent.height; radius: parent.radius; color: miniMusicBar.accentColor
            Behavior on width { NumberAnimation { duration: 600 } }
          }
        }
        MouseArea {
          anchors.fill: parent; anchors.margins: vpx(-8); cursorShape: Qt.SizeHorCursor
          onPressed:        { var p =Math.max(0,Math.min(1,mouse.x/r1Seek.width)); miniPlayer.seek(p *(miniPlayer.duration>0?miniPlayer.duration:1)) }
          onPositionChanged:{ if(!pressed)return; var p2=Math.max(0,Math.min(1,mouse.x/r1Seek.width)); miniPlayer.seek(p2*(miniPlayer.duration>0?miniPlayer.duration:1)) }
        }
      }
    }

  }  // end miniMusicBar Item

  Keys.onPressed: {
    buttonActions.onPressed(event);
  }
}
