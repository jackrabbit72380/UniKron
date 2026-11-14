import QtQuick 2.8
import "../../components"

// ═══════════════════════════════════════════════════════════════════════
// ClockOverlay.qml
//
// Drop this anywhere in your theme root — it renders the clock and FPS
// counter as a full-screen transparent overlay, reading every setting
// live from api.memory so changes in SettingsPage take effect immediately
// without needing a restart.
//
// Usage in theme.qml / Main.qml:
//   ClockOverlay { anchors.fill: parent; z: 100 }
//
// Settings keys read from api.memory:
//   cfg.showClock       "true"/"false"
//   cfg.clockOnDash     "true"/"false"   — show on dashboard/library page
//   cfg.useSkinClock    "true"/"false"   — mutually exclusive with clockOnDash
//   cfg.clock24         "true"/"false"
//   cfg.clockPosX       0.0 – 1.0       normalised screen X
//   cfg.clockPosY       0.0 – 1.0       normalised screen Y
//   cfg.clockFontSize   integer px
//   cfg.clockOpacity    0.0 – 1.0
//   cfg.showFPS         "true"/"false"
//   cfg.fpsOnDash       "true"/"false"
//   cfg.fpsPosX         0.0 – 1.0
//   cfg.fpsPosY         0.0 – 1.0
//   cfg.fpsFontSize     integer px
//   cfg.fpsOpacity      0.0 – 1.0
// ═══════════════════════════════════════════════════════════════════════

Item {
  id: root
  anchors.fill: parent

  // ── Settings read live from memory ───────────────────────────────
  function mem(k, d) {
    var v = api.memory.get(k)
    return (v !== undefined && v !== null && v !== "") ? v : d
  }

  // ── Reactive settings properties ─────────────────────────────────
  // These are updated every second by the refresh timer so they always
  // reflect whatever SettingsPage last saved.

  property bool   showClock:    mem("cfg.showClock",    "true")  === "true"
  property bool   clockOnDash:  mem("cfg.clockOnDash",  "true")  === "true"
  property bool   useSkinClock: mem("cfg.useSkinClock", "false") === "true"
  property bool   clock24:      mem("cfg.clock24",      "false") === "true"
  property real   clockX:       parseFloat(mem("cfg.clockPosX",  "0.97"))
  // FIX: clamp Y so the clock pill never overlaps the ButtonActions bar at the
  // bottom of the screen.  ButtonActions anchors to bottomMargin vpx(30) and is
  // ~vpx(32) tall, so anything above 0.88 normalised Y is safely clear.
  property real   clockY:       Math.min(parseFloat(mem("cfg.clockPosY", "0.02")), 0.88)
  property int    clockSize:    parseInt(mem("cfg.clockFontSize", "16"))
  property real   clockAlpha:   parseFloat(mem("cfg.clockOpacity","1.0"))

  property bool   showFPS:      mem("cfg.showFPS",      "false") === "true"
  property bool   fpsOnDash:    mem("cfg.fpsOnDash",    "false") === "true"
  property real   fpsX:         parseFloat(mem("cfg.fpsPosX",    "0.02"))
  property real   fpsY:         parseFloat(mem("cfg.fpsPosY",    "0.02"))
  property int    fpsSize:      parseInt(mem("cfg.fpsFontSize",   "16"))
  property real   fpsAlpha:     parseFloat(mem("cfg.fpsOpacity",  "1.0"))

  // ── Visibility rules ─────────────────────────────────────────────
  // Clock is visible when:
  //   showClock is true
  //   AND (clockOnDash is true OR useSkinClock is false)
  //   AND useSkinClock is false  (skin clock means the skin handles it, not us)
  property bool clockVisible: showClock && clockOnDash && !useSkinClock

  // FPS overlay visibility
  property bool fpsVisible: showFPS && fpsOnDash

  // ── Live time strings ─────────────────────────────────────────────
  property string timeString: Qt.formatTime(new Date(), clock24 ? "HH:mm:ss" : "hh:mm:ss AP")
  property string fpsString:  "FPS  --"   // updated by FPS timer below

  // ── FPS counter ───────────────────────────────────────────────────
  property int    _fpsFrames:    0
  property real   _fpsLastTime:  0
  property real   _fpsValue:     0

  // ── Master refresh timer — updates time and re-reads all settings ──
  Timer {
    id: refreshTimer
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: {
      // Re-read all settings from memory so changes in Settings take effect live
      root.showClock    = root.mem("cfg.showClock",    "true")  === "true"
      root.clockOnDash  = root.mem("cfg.clockOnDash",  "true")  === "true"
      root.useSkinClock = root.mem("cfg.useSkinClock", "false") === "true"
      root.clock24      = root.mem("cfg.clock24",      "false") === "true"
      root.clockX       = parseFloat(root.mem("cfg.clockPosX",  "0.97"))
      root.clockY       = Math.min(parseFloat(root.mem("cfg.clockPosY", "0.02")), 0.88)
      root.clockSize    = parseInt(root.mem("cfg.clockFontSize", "16"))
      root.clockAlpha   = parseFloat(root.mem("cfg.clockOpacity","1.0"))
      root.showFPS      = root.mem("cfg.showFPS",      "false") === "true"
      root.fpsOnDash    = root.mem("cfg.fpsOnDash",    "false") === "true"
      root.fpsX         = parseFloat(root.mem("cfg.fpsPosX",    "0.02"))
      root.fpsY         = parseFloat(root.mem("cfg.fpsPosY",    "0.02"))
      root.fpsSize      = parseInt(root.mem("cfg.fpsFontSize",   "16"))
      root.fpsAlpha     = parseFloat(root.mem("cfg.fpsOpacity",  "1.0"))

      // Update clock string
      root.timeString = Qt.formatTime(new Date(), root.clock24 ? "HH:mm:ss" : "hh:mm:ss AP")
    }
  }

  // ── FPS frame counter (16ms ≈ 60fps tick) ────────────────────────
  Timer {
    id: fpsTick
    interval: 16
    repeat: true
    running: root.showFPS && root.fpsOnDash
    onTriggered: {
      root._fpsFrames++
      var now = Date.now()
      if (root._fpsLastTime === 0) { root._fpsLastTime = now; return }
      var elapsed = now - root._fpsLastTime
      if (elapsed >= 1000) {
        root._fpsValue  = Math.round(root._fpsFrames * 1000 / elapsed)
        root.fpsString  = "FPS  " + root._fpsValue
        root._fpsFrames = 0
        root._fpsLastTime = now
      }
    }
  }

  // ══ CLOCK ════════════════════════════════════════════════════════
  Item {
    id: clockItem
    visible: root.clockVisible
    // Position: clockX/Y are normalised (0-1) screen fractions
    // We position the item so the text is centred on that point
    x: root.clockX * parent.width  - width  / 2
    y: root.clockY * parent.height - height / 2
    // Keep fully on-screen
    width:  clockLabel.width  + vpx(16)
    height: clockLabel.height + vpx(10)

    // Smooth position animation so drags look fluid
    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
    Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

    // Pill background
    Rectangle {
      anchors.fill: parent
      radius: vpx(6)
      color: "#88000000"
      border.color: "#33FFFFFF"
      border.width: vpx(1)
    }

    StyledText {
      id: clockLabel
      anchors.centerIn: parent
      text: root.timeString
      font.pixelSize: vpx(root.clockSize)
      font.bold: true
      opacity: root.clockAlpha
      color: "#FFFFFF"
      layer.enabled: false
    }
  }

  // ══ FPS COUNTER ══════════════════════════════════════════════════
  Item {
    id: fpsItem
    visible: root.fpsVisible
    x: root.fpsX * parent.width  - width  / 2
    y: root.fpsY * parent.height - height / 2
    width:  fpsLabel.width  + vpx(16)
    height: fpsLabel.height + vpx(10)

    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
    Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

    Rectangle {
      anchors.fill: parent
      radius: vpx(6)
      color: "#88000000"
      border.color: "#33FFFFFF"
      border.width: vpx(1)
    }

    StyledText {
      id: fpsLabel
      anchors.centerIn: parent
      text: root.fpsString
      font.pixelSize: vpx(root.fpsSize)
      font.bold: true
      opacity: root.fpsAlpha
      color: root._fpsValue >= 55 ? "#44FF88"
           : root._fpsValue >= 30 ? "#FFCC00"
                                  : "#FF5555"
      layer.enabled: false
    }
  }
}
