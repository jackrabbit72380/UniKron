import QtQuick 2.8
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.12
import "../../components"

// ═══════════════════════════════════════════════════════════════════════
// PlacementEditor.qml — Full-screen WYSIWYG placement editor
//
// Set which = "clock" | "fps"
// Bind posX, posY, fontSize, textOpacity, edgePadding
// Pass presets array, connect presetsChanged and closed signals
//
// Features:
//   • Full-screen canvas — click anywhere or drag the label
//   • Alignment grid overlay + 9 snap-zone guide dots
//   • Magnet-snap near edges/center while dragging
//   • Separate X / Y sliders with ± buttons
//   • Three nudge steps: 1% · 0.2% · 0.05%  (Tab to cycle)
//   • 3×3 snap-to-zone grid with configurable edge padding
//   • Font size and text opacity sliders
//   • Named preset save / load / delete (stores size + opacity too)
//   • Manual X,Y % entry dialog
//   • Live text preview exactly as it appears in-game
// ═══════════════════════════════════════════════════════════════════════

Item {
  id: root
  anchors.fill: parent
  visible: false
  z: 500
  focus: visible

  // ── Public API ────────────────────────────────────────────────────
  property string which:        "clock"
  property string accentHex:    "#5d9809"
  property real   posX:         0.97
  property real   posY:         0.02
  property int    fontSize:     16
  property real   textOpacity:  1.0
  property int    edgePadding:  12

  property var    presets:      []
  property var pendingPresets: []
  signal editorClosed()

  // ── Persistence ───────────────────────────────────────────────────
  function mem(k, d) { return api.memory.get(k) || d }
  function sv(k, v)  { api.memory.set(k, v) }

  readonly property string prefX:   "cfg." + which + "PosX"
  readonly property string prefY:   "cfg." + which + "PosY"
  readonly property string prefFS:  "cfg." + which + "FontSize"
  readonly property string prefOp:  "cfg." + which + "Opacity"
  readonly property string prefPad: "cfg." + which + "Padding"

  function commitPos() { sv(prefX, posX.toString()); sv(prefY, posY.toString()) }

  // ── Snap logic ────────────────────────────────────────────────────
  function snapTo(zone) {
    var px = edgePadding / canvas.width
    var py = edgePadding / canvas.height
    if      (zone === "TL") { posX = px;     posY = py      }
    else if (zone === "TC") { posX = 0.5;    posY = py      }
    else if (zone === "TR") { posX = 1-px;   posY = py      }
    else if (zone === "ML") { posX = px;     posY = 0.5     }
    else if (zone === "MC") { posX = 0.5;    posY = 0.5     }
    else if (zone === "MR") { posX = 1-px;   posY = 0.5     }
    else if (zone === "BL") { posX = px;     posY = 1-py    }
    else if (zone === "BC") { posX = 0.5;    posY = 1-py    }
    else if (zone === "BR") { posX = 1-px;   posY = 1-py    }
    commitPos()
  }

  function magnetSnap(nx, ny) {
    var px = edgePadding / canvas.width
    var py = edgePadding / canvas.height
    var t  = 0.035
    var rx = nx, ry = ny
    if      (nx < t)                 rx = px
    else if (nx > 1-t)               rx = 1-px
    else if (Math.abs(nx-0.5) < t)   rx = 0.5
    if      (ny < t)                 ry = py
    else if (ny > 1-t)               ry = 1-py
    else if (Math.abs(ny-0.5) < t)   ry = 0.5
    return {x: rx, y: ry}
  }

  // ── Nudge step ────────────────────────────────────────────────────
  property int nudgeMode: 1
  readonly property var nudgeSteps: [0.01, 0.002, 0.0005]

  function nudge(dx, dy) {
    var s = nudgeSteps[nudgeMode]
    posX = Math.max(0, Math.min(0.999, posX + dx*s))
    posY = Math.max(0, Math.min(0.999, posY + dy*s))
    commitPos()
  }

  // ── Dialog state ──────────────────────────────────────────────────
  property bool   showSaveUI:    false
  property bool   showManualUI:  false
  property string newPresetName: ""
  property string manualXStr:    ""
  property string manualYStr:    ""

  readonly property string previewText:
    which === "clock"
      ? (mem("cfg.clock24","false") === "true" ? "14:32:07" : "2:32 PM")
      : "FPS  60"

  // ═══════════════════════════════════════════════════════════════
  // CANVAS
  // ═══════════════════════════════════════════════════════════════
  Rectangle {
    id: canvas
    anchors.fill: parent
    color: "#0A0A12"

    // Grid lines
    Repeater {
      model: Math.ceil(canvas.width / 50) + 1
      Rectangle { x:index*50; y:0; width:1; height:canvas.height; color:"#08FFFFFF" }
    }
    Repeater {
      model: Math.ceil(canvas.height / 50) + 1
      Rectangle { x:0; y:index*50; width:canvas.width; height:1; color:"#08FFFFFF" }
    }
    // Centre crosshairs
    Rectangle { x:canvas.width/2;    y:0;               width:1; height:canvas.height; color:"#18FFFFFF" }
    Rectangle { x:0;                 y:canvas.height/2;  width:canvas.width; height:1; color:"#18FFFFFF" }

    // Snap guide dots (9 zones)
    Repeater {
      model: [
        {nx:0,   ny:0  }, {nx:0.5, ny:0  }, {nx:1,   ny:0  },
        {nx:0,   ny:0.5}, {nx:0.5, ny:0.5}, {nx:1,   ny:0.5},
        {nx:0,   ny:1  }, {nx:0.5, ny:1  }, {nx:1,   ny:1  }
      ]
      delegate: Rectangle {
        property real gx: {
          var p = edgePadding / canvas.width
          if (modelData.nx === 0)   return p * canvas.width
          if (modelData.nx === 1)   return (1-p) * canvas.width
          return 0.5 * canvas.width
        }
        property real gy: {
          var p = edgePadding / canvas.height
          if (modelData.ny === 0)   return p * canvas.height
          if (modelData.ny === 1)   return (1-p) * canvas.height
          return 0.5 * canvas.height
        }
        x: gx-5; y: gy-5
        width:10; height:10; radius:5
        color: "#22FFFFFF"
        border.color: "#38FFFFFF"; border.width:1
      }
    }

    // Click anywhere to reposition
    MouseArea {
      anchors.fill: parent
      z: -1
      onClicked: {
        var s = magnetSnap(mouse.x / canvas.width, mouse.y / canvas.height)
        posX = Math.max(0, Math.min(0.999, s.x))
        posY = Math.max(0, Math.min(0.999, s.y))
        commitPos()
        root.forceActiveFocus()
      }
    }

    // ── Draggable label ─────────────────────────────────────────
    Item {
      id: dragItem
      x: posX * canvas.width  - width  / 2
      y: posY * canvas.height - height / 2

      Behavior on x { enabled: !dragMA.drag.active; NumberAnimation { duration:80; easing.type: Easing.OutQuad } }
      Behavior on y { enabled: !dragMA.drag.active; NumberAnimation { duration:80; easing.type: Easing.OutQuad } }

      width:  pill.width  + vpx(10)
      height: pill.height + vpx(16)

      // Glow ring while dragging
      Rectangle {
        anchors.centerIn: parent
        width: pill.width + vpx(22); height: pill.height + vpx(22)
        radius: vpx(10); color: "transparent"
        border.color: root.accentHex; border.width: vpx(2)
        opacity: dragMA.drag.active ? 0.7 : 0
        Behavior on opacity { NumberAnimation { duration:120 } }
      }

      // Pill
      Rectangle {
        id: pill
        anchors.centerIn: parent
        width:  previewLbl.width  + vpx(26)
        height: previewLbl.height + vpx(14)
        radius: vpx(5)
        color:  "#B0000000"
        border.color: dragMA.drag.active ? "#FFFFFF" : root.accentHex
        border.width: dragMA.drag.active ? vpx(2) : vpx(1.5)

        StyledText {
          id: previewLbl
          anchors.centerIn: parent
          text:           root.previewText
          font.pixelSize: vpx(root.fontSize)
          opacity:        root.textOpacity
          layer.enabled: false
        }
      }

      // Drag handle bar
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: vpx(44); height: vpx(5); radius: vpx(2.5)
        color: dragMA.containsMouse ? "#FFFFFF" : root.accentHex
        opacity: 0.85
      }

      MouseArea {
        id: dragMA
        anchors.fill: parent
        drag.target:   dragItem
        drag.minimumX: -dragItem.width  / 2
        drag.maximumX:  canvas.width  - dragItem.width  / 2
        drag.minimumY: -dragItem.height / 2
        drag.maximumY:  canvas.height - dragItem.height / 2
        hoverEnabled:  true
        cursorShape:   drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onPositionChanged: {
          if (drag.active) {
            var cx = (dragItem.x + dragItem.width  / 2) / canvas.width
            var cy = (dragItem.y + dragItem.height / 2) / canvas.height
            var s  = magnetSnap(cx, cy)
            posX = Math.max(0, Math.min(0.999, s.x))
            posY = Math.max(0, Math.min(0.999, s.y))
            commitPos()
          }
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CONTROL PANEL
  // ═══════════════════════════════════════════════════════════════
  Rectangle {
    id: panel
    anchors.right:        parent.right
    anchors.top:          parent.top
    anchors.bottom:       parent.bottom
    anchors.rightMargin:  vpx(14)
    anchors.topMargin:    vpx(14)
    anchors.bottomMargin: vpx(14)
    width: vpx(295)
    color:  "#F0101020"
    radius: vpx(8)
    border.color: "#28FFFFFF"; border.width: vpx(1)
    clip: true

    Flickable {
      id: fl
      anchors.fill: parent
      anchors.margins: vpx(14)
      contentHeight: col.implicitHeight
      clip: true

      Column {
        id: col
        width: fl.width
        spacing: vpx(8)

        // Title
        StyledText {
          text: (which === "clock" ? "🕐  Clock" : "📊  FPS") + " Placement"
          font.pixelSize: vpx(17); font.bold: true; layer.enabled: false
        }
        StyledText {
          text: "Drag label · Click screen · Arrow keys"
          font.pixelSize: vpx(11); color: "#666677"; layer.enabled: false
        }

        // ── POSITION ─────────────────────────────────────────────
        // Divider
        Rectangle { width: col.width; height: vpx(1); color: "#22FFFFFF" }
        StyledText { text: "POSITION"; font.pixelSize: vpx(10); color: "#445566"; layer.enabled: false }

        // X row
        Item {
          width: col.width; height: vpx(46)
          StyledText { id: xLbl; text:"X"; font.pixelSize:vpx(12); color:"#AAAAAA"; anchors.left:parent.left; anchors.verticalCenter:parent.verticalCenter; width:vpx(20); layer.enabled:false }
          Rectangle {
            id: xDecBtn
            anchors.left: xLbl.right; anchors.leftMargin: vpx(2); anchors.verticalCenter: parent.verticalCenter
            width: vpx(24); height: vpx(24); radius: vpx(3)
            color: xDecMA.pressed ? accentHex : "#33FFFFFF"
            StyledText { anchors.centerIn:parent; text:"−"; font.pixelSize:vpx(14); layer.enabled:false }
            MouseArea { id:xDecMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked: { posX=Math.max(0,posX-nudgeSteps[nudgeMode]); commitPos() } }
          }
          // Track
          Rectangle {
            id: xTrack
            anchors.left: xDecBtn.right; anchors.leftMargin: vpx(4)
            anchors.right: xIncBtn.left; anchors.rightMargin: vpx(4)
            anchors.verticalCenter: parent.verticalCenter
            height: vpx(6); radius: vpx(3); color: "#2AFFFFFF"
            Rectangle {
              width: Math.max(vpx(6), xTrack.width * posX)
              height: parent.height; radius: parent.radius; color: accentHex
              Behavior on width { NumberAnimation { duration:60 } }
            }
            Rectangle {
              id: xThumb
              width: vpx(14); height: vpx(14); radius: vpx(7)
              color: "#FFFFFF"; border.color: accentHex; border.width: vpx(2)
              x: Math.max(0, Math.min(xTrack.width-width, xTrack.width*posX - width/2))
              y: (xTrack.height-height)/2
              Behavior on x { NumberAnimation { duration:60 } }
            }
            MouseArea {
              anchors.fill: parent; cursorShape: Qt.SizeHorCursor
              onPressed:         { var r=Math.max(0,Math.min(1,mouse.x/xTrack.width)); posX=r; commitPos() }
              onPositionChanged: { if(pressed){ var r=Math.max(0,Math.min(1,mouse.x/xTrack.width)); posX=r; commitPos() } }
            }
          }
          Rectangle {
            id: xIncBtn
            anchors.right: xValLbl.left; anchors.rightMargin: vpx(4); anchors.verticalCenter: parent.verticalCenter
            width: vpx(24); height: vpx(24); radius: vpx(3)
            color: xIncMA.pressed ? accentHex : "#33FFFFFF"
            StyledText { anchors.centerIn:parent; text:"+"; font.pixelSize:vpx(14); layer.enabled:false }
            MouseArea { id:xIncMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked: { posX=Math.min(0.999,posX+nudgeSteps[nudgeMode]); commitPos() } }
          }
          StyledText {
            id: xValLbl; anchors.right:parent.right; anchors.verticalCenter:parent.verticalCenter
            width:vpx(52); horizontalAlignment:Text.AlignRight
            text: (Math.round(posX*1000)/10).toFixed(1)+"%"; font.pixelSize:vpx(12); font.bold:true; layer.enabled:false
          }
        }

        // Y row
        Item {
          width: col.width; height: vpx(46)
          StyledText { id: yLbl; text:"Y"; font.pixelSize:vpx(12); color:"#AAAAAA"; anchors.left:parent.left; anchors.verticalCenter:parent.verticalCenter; width:vpx(20); layer.enabled:false }
          Rectangle {
            id: yDecBtn
            anchors.left: yLbl.right; anchors.leftMargin: vpx(2); anchors.verticalCenter: parent.verticalCenter
            width: vpx(24); height: vpx(24); radius: vpx(3)
            color: yDecMA.pressed ? accentHex : "#33FFFFFF"
            StyledText { anchors.centerIn:parent; text:"−"; font.pixelSize:vpx(14); layer.enabled:false }
            MouseArea { id:yDecMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked: { posY=Math.max(0,posY-nudgeSteps[nudgeMode]); commitPos() } }
          }
          Rectangle {
            id: yTrack
            anchors.left: yDecBtn.right; anchors.leftMargin: vpx(4)
            anchors.right: yIncBtn.left; anchors.rightMargin: vpx(4)
            anchors.verticalCenter: parent.verticalCenter
            height: vpx(6); radius: vpx(3); color: "#2AFFFFFF"
            Rectangle {
              width: Math.max(vpx(6), yTrack.width * posY)
              height: parent.height; radius: parent.radius; color: accentHex
              Behavior on width { NumberAnimation { duration:60 } }
            }
            Rectangle {
              width: vpx(14); height: vpx(14); radius: vpx(7)
              color: "#FFFFFF"; border.color: accentHex; border.width: vpx(2)
              x: Math.max(0, Math.min(yTrack.width-width, yTrack.width*posY - width/2))
              y: (yTrack.height-height)/2
              Behavior on x { NumberAnimation { duration:60 } }
            }
            MouseArea {
              anchors.fill: parent; cursorShape: Qt.SizeHorCursor
              onPressed:         { var r=Math.max(0,Math.min(1,mouse.x/yTrack.width)); posY=r; commitPos() }
              onPositionChanged: { if(pressed){ var r=Math.max(0,Math.min(1,mouse.x/yTrack.width)); posY=r; commitPos() } }
            }
          }
          Rectangle {
            id: yIncBtn
            anchors.right: yValLbl.left; anchors.rightMargin: vpx(4); anchors.verticalCenter: parent.verticalCenter
            width: vpx(24); height: vpx(24); radius: vpx(3)
            color: yIncMA.pressed ? accentHex : "#33FFFFFF"
            StyledText { anchors.centerIn:parent; text:"+"; font.pixelSize:vpx(14); layer.enabled:false }
            MouseArea { id:yIncMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked: { posY=Math.min(0.999,posY+nudgeSteps[nudgeMode]); commitPos() } }
          }
          StyledText {
            id: yValLbl; anchors.right:parent.right; anchors.verticalCenter:parent.verticalCenter
            width:vpx(52); horizontalAlignment:Text.AlignRight
            text: (Math.round(posY*1000)/10).toFixed(1)+"%"; font.pixelSize:vpx(12); font.bold:true; layer.enabled:false
          }
        }

        // Nudge step row
        Item {
          width: col.width; height: vpx(30)
          RowLayout { anchors.fill:parent; spacing:vpx(3)
            StyledText { text:"Step:"; font.pixelSize:vpx(11); color:"#555577"; layer.enabled:false }
            Repeater {
              model: ["1%","0.2%","0.05%"]
              delegate: Rectangle {
                height: vpx(24); Layout.fillWidth:true; radius:vpx(3)
                color: index===nudgeMode ? accentHex : "#2AFFFFFF"
                Behavior on color { ColorAnimation { duration:80 } }
                StyledText { anchors.centerIn:parent; text:modelData; font.pixelSize:vpx(11); font.bold:index===nudgeMode; layer.enabled:false }
                MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:{ nudgeMode=index; root.forceActiveFocus() } }
              }
            }
          }
        }

        // Live coord readout
        StyledText {
          width: col.width; horizontalAlignment: Text.AlignHCenter
          text: "X " + (Math.round(posX*1000)/10).toFixed(1) + "%   ·   Y " + (Math.round(posY*1000)/10).toFixed(1) + "%"
          font.pixelSize: vpx(13); color: accentHex; font.bold: true; layer.enabled:false
        }

        // ── SNAP ZONES ───────────────────────────────────────────
        Rectangle { width: col.width; height: vpx(1); color: "#22FFFFFF" }
        StyledText { text: "SNAP TO ZONE"; font.pixelSize:vpx(10); color:"#445566"; layer.enabled:false }

        Grid {
          columns:3; rows:3; spacing:vpx(4)
          anchors.horizontalCenter: parent.horizontalCenter
          Repeater {
            model: [
              {z:"TL",s:"↖",l:"Top Left"},    {z:"TC",s:"↑",l:"Top Center"}, {z:"TR",s:"↗",l:"Top Right"},
              {z:"ML",s:"←",l:"Mid Left"},     {z:"MC",s:"·",l:"Center"},     {z:"MR",s:"→",l:"Mid Right"},
              {z:"BL",s:"↙",l:"Bot Left"},     {z:"BC",s:"↓",l:"Bot Center"}, {z:"BR",s:"↘",l:"Bot Right"}
            ]
            delegate: Rectangle {
              width:vpx(82); height:vpx(38); radius:vpx(4)
              color: szMA.containsMouse ? accentHex : "#2AFFFFFF"
              Behavior on color { ColorAnimation { duration:60 } }
              Column { anchors.centerIn:parent; spacing:vpx(1)
                StyledText { anchors.horizontalCenter:parent.horizontalCenter; text:modelData.s; font.pixelSize:vpx(14); layer.enabled:false }
                StyledText { anchors.horizontalCenter:parent.horizontalCenter; text:modelData.l; font.pixelSize:vpx(9); color:"#BBBBBB"; layer.enabled:false }
              }
              MouseArea { id:szMA; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:{ snapTo(modelData.z); root.forceActiveFocus() } }
            }
          }
        }

        // Edge padding slider
        Item {
          width: col.width; height: vpx(46)
          StyledText { id:padLbl; text:"Pad"; font.pixelSize:vpx(12); color:"#AAAAAA"; anchors.left:parent.left; anchors.verticalCenter:parent.verticalCenter; width:vpx(28); layer.enabled:false }
          Rectangle {
            id: padDecBtn; anchors.left:padLbl.right; anchors.leftMargin:vpx(2); anchors.verticalCenter:parent.verticalCenter
            width:vpx(24); height:vpx(24); radius:vpx(3); color:padDecMA.pressed?accentHex:"#33FFFFFF"
            StyledText { anchors.centerIn:parent; text:"−"; font.pixelSize:vpx(14); layer.enabled:false }
            MouseArea { id:padDecMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:{ edgePadding=Math.max(0,edgePadding-2); sv(prefPad,edgePadding.toString()) } }
          }
          Rectangle {
            id: padTrack
            anchors.left:padDecBtn.right; anchors.leftMargin:vpx(4)
            anchors.right:padIncBtn.left; anchors.rightMargin:vpx(4)
            anchors.verticalCenter:parent.verticalCenter
            height:vpx(6); radius:vpx(3); color:"#2AFFFFFF"
            Rectangle { width:Math.max(vpx(6),padTrack.width*(edgePadding/80)); height:parent.height; radius:parent.radius; color:accentHex; Behavior on width{NumberAnimation{duration:60}} }
            MouseArea {
              anchors.fill:parent; cursorShape:Qt.SizeHorCursor
              onPressed:{ edgePadding=Math.round(Math.max(0,Math.min(80,mouse.x/padTrack.width*80))); sv(prefPad,edgePadding.toString()) }
              onPositionChanged:{ if(pressed){ edgePadding=Math.round(Math.max(0,Math.min(80,mouse.x/padTrack.width*80))); sv(prefPad,edgePadding.toString()) } }
            }
          }
          Rectangle {
            id: padIncBtn; anchors.right:padValLbl.left; anchors.rightMargin:vpx(4); anchors.verticalCenter:parent.verticalCenter
            width:vpx(24); height:vpx(24); radius:vpx(3); color:padIncMA.pressed?accentHex:"#33FFFFFF"
            StyledText { anchors.centerIn:parent; text:"+"; font.pixelSize:vpx(14); layer.enabled:false }
            MouseArea { id:padIncMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:{ edgePadding=Math.min(80,edgePadding+2); sv(prefPad,edgePadding.toString()) } }
          }
          StyledText { id:padValLbl; anchors.right:parent.right; anchors.verticalCenter:parent.verticalCenter; width:vpx(44); horizontalAlignment:Text.AlignRight; text:edgePadding+"px"; font.pixelSize:vpx(12); font.bold:true; layer.enabled:false }
        }

        // ── APPEARANCE ───────────────────────────────────────────
        Rectangle { width: col.width; height: vpx(1); color: "#22FFFFFF" }
        StyledText { text: "APPEARANCE"; font.pixelSize:vpx(10); color:"#445566"; layer.enabled:false }

        // Font size
        Item {
          width: col.width; height: vpx(46)
          StyledText { id:fsLbl; text:"Size"; font.pixelSize:vpx(12); color:"#AAAAAA"; anchors.left:parent.left; anchors.verticalCenter:parent.verticalCenter; width:vpx(28); layer.enabled:false }
          Rectangle {
            id:fsDecBtn; anchors.left:fsLbl.right; anchors.leftMargin:vpx(2); anchors.verticalCenter:parent.verticalCenter
            width:vpx(24); height:vpx(24); radius:vpx(3); color:fsDecMA.pressed?accentHex:"#33FFFFFF"
            StyledText { anchors.centerIn:parent; text:"−"; font.pixelSize:vpx(14); layer.enabled:false }
            MouseArea { id:fsDecMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:{ fontSize=Math.max(8,fontSize-1); sv(prefFS,fontSize.toString()) } }
          }
          Rectangle {
            id:fsTrack
            anchors.left:fsDecBtn.right; anchors.leftMargin:vpx(4)
            anchors.right:fsIncBtn.left; anchors.rightMargin:vpx(4)
            anchors.verticalCenter:parent.verticalCenter
            height:vpx(6); radius:vpx(3); color:"#2AFFFFFF"
            Rectangle { width:Math.max(vpx(6),fsTrack.width*((fontSize-8)/44)); height:parent.height; radius:parent.radius; color:accentHex; Behavior on width{NumberAnimation{duration:60}} }
            MouseArea {
              anchors.fill:parent; cursorShape:Qt.SizeHorCursor
              onPressed:{ fontSize=Math.round(8+Math.max(0,Math.min(1,mouse.x/fsTrack.width))*44); sv(prefFS,fontSize.toString()) }
              onPositionChanged:{ if(pressed){ fontSize=Math.round(8+Math.max(0,Math.min(1,mouse.x/fsTrack.width))*44); sv(prefFS,fontSize.toString()) } }
            }
          }
          Rectangle {
            id:fsIncBtn; anchors.right:fsValLbl.left; anchors.rightMargin:vpx(4); anchors.verticalCenter:parent.verticalCenter
            width:vpx(24); height:vpx(24); radius:vpx(3); color:fsIncMA.pressed?accentHex:"#33FFFFFF"
            StyledText { anchors.centerIn:parent; text:"+"; font.pixelSize:vpx(14); layer.enabled:false }
            MouseArea { id:fsIncMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:{ fontSize=Math.min(52,fontSize+1); sv(prefFS,fontSize.toString()) } }
          }
          StyledText { id:fsValLbl; anchors.right:parent.right; anchors.verticalCenter:parent.verticalCenter; width:vpx(44); horizontalAlignment:Text.AlignRight; text:fontSize+"pt"; font.pixelSize:vpx(12); font.bold:true; layer.enabled:false }
        }

        // Opacity
        Item {
          width: col.width; height: vpx(46)
          StyledText { id:opLbl; text:"Alpha"; font.pixelSize:vpx(12); color:"#AAAAAA"; anchors.left:parent.left; anchors.verticalCenter:parent.verticalCenter; width:vpx(34); layer.enabled:false }
          Rectangle {
            id:opDecBtn; anchors.left:opLbl.right; anchors.leftMargin:vpx(2); anchors.verticalCenter:parent.verticalCenter
            width:vpx(24); height:vpx(24); radius:vpx(3); color:opDecMA.pressed?accentHex:"#33FFFFFF"
            StyledText { anchors.centerIn:parent; text:"−"; font.pixelSize:vpx(14); layer.enabled:false }
            MouseArea { id:opDecMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:{ textOpacity=Math.max(0.1,Math.round((textOpacity-0.05)*100)/100); sv(prefOp,textOpacity.toString()) } }
          }
          Rectangle {
            id:opTrack
            anchors.left:opDecBtn.right; anchors.leftMargin:vpx(4)
            anchors.right:opIncBtn.left; anchors.rightMargin:vpx(4)
            anchors.verticalCenter:parent.verticalCenter
            height:vpx(6); radius:vpx(3); color:"#2AFFFFFF"
            Rectangle { width:Math.max(vpx(6),opTrack.width*textOpacity); height:parent.height; radius:parent.radius; color:accentHex; Behavior on width{NumberAnimation{duration:60}} }
            MouseArea {
              anchors.fill:parent; cursorShape:Qt.SizeHorCursor
              onPressed:{ textOpacity=Math.round(Math.max(10,Math.min(100,mouse.x/opTrack.width*100)))/100; sv(prefOp,textOpacity.toString()) }
              onPositionChanged:{ if(pressed){ textOpacity=Math.round(Math.max(10,Math.min(100,mouse.x/opTrack.width*100)))/100; sv(prefOp,textOpacity.toString()) } }
            }
          }
          Rectangle {
            id:opIncBtn; anchors.right:opValLbl.left; anchors.rightMargin:vpx(4); anchors.verticalCenter:parent.verticalCenter
            width:vpx(24); height:vpx(24); radius:vpx(3); color:opIncMA.pressed?accentHex:"#33FFFFFF"
            StyledText { anchors.centerIn:parent; text:"+"; font.pixelSize:vpx(14); layer.enabled:false }
            MouseArea { id:opIncMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:{ textOpacity=Math.min(1.0,Math.round((textOpacity+0.05)*100)/100); sv(prefOp,textOpacity.toString()) } }
          }
          StyledText { id:opValLbl; anchors.right:parent.right; anchors.verticalCenter:parent.verticalCenter; width:vpx(44); horizontalAlignment:Text.AlignRight; text:Math.round(textOpacity*100)+"%"; font.pixelSize:vpx(12); font.bold:true; layer.enabled:false }
        }

        // ── PRESETS ──────────────────────────────────────────────
        Rectangle { width: col.width; height: vpx(1); color: "#22FFFFFF" }
        StyledText { text: "PRESETS"; font.pixelSize:vpx(10); color:"#445566"; layer.enabled:false }

        Column {
          width: col.width; spacing: vpx(3)
          Repeater {
            model: presets
            delegate: Rectangle {
              width: col.width; height: vpx(36); radius: vpx(3)
              color: prMA.containsMouse ? Qt.rgba(
                parseInt(accentHex.substr(1,2),16)/255,
                parseInt(accentHex.substr(3,2),16)/255,
                parseInt(accentHex.substr(5,2),16)/255, 0.28) : "#1EFFFFFF"
              RowLayout { anchors.fill:parent; anchors.leftMargin:vpx(10); anchors.rightMargin:vpx(10)
                StyledText { Layout.fillWidth:true; text:modelData.name; font.pixelSize:vpx(13); layer.enabled:false }
                StyledText { text:(Math.round(modelData.x*1000)/10).toFixed(1)+"%, "+(Math.round(modelData.y*1000)/10).toFixed(1)+"%"; font.pixelSize:vpx(11); color:"#777788"; layer.enabled:false }
              }
              Rectangle {
                anchors.right:parent.right; anchors.rightMargin:vpx(6); anchors.verticalCenter:parent.verticalCenter
                width:vpx(20); height:vpx(20); radius:vpx(3); color:dPrMA.containsMouse?"#60FF3333":"transparent"
                visible: presets.length > 1
                StyledText { anchors.centerIn:parent; text:"✕"; font.pixelSize:vpx(11); color:"#FF6666"; layer.enabled:false }
                MouseArea { id:dPrMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; hoverEnabled:true
                  onClicked:{ var c=presets.slice(); c.splice(index,1); presets=c; pendingPresets=c } }
              }
              MouseArea { id:prMA; anchors.fill:parent; z:-1; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
                onClicked:{
                  posX=modelData.x; posY=modelData.y
                  if(modelData.fontSize!==undefined)    fontSize=modelData.fontSize
                  if(modelData.textOpacity!==undefined) textOpacity=modelData.textOpacity
                  commitPos(); root.forceActiveFocus()
                }
              }
            }
          }
        }

        RowLayout {
          width: col.width; spacing: vpx(6)
          Rectangle {
            Layout.fillWidth:true; height:vpx(32); radius:vpx(4)
            color:svPrMA.containsMouse?accentHex:"#2AFFFFFF"
            StyledText { anchors.centerIn:parent; text:"💾  Save Here"; font.pixelSize:vpx(12); layer.enabled:false }
            MouseArea { id:svPrMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; hoverEnabled:true; onClicked:{ newPresetName=""; showSaveUI=true } }
          }
          Rectangle {
            Layout.fillWidth:true; height:vpx(32); radius:vpx(4)
            color:manPrMA.containsMouse?accentHex:"#2AFFFFFF"
            StyledText { anchors.centerIn:parent; text:"⌨  X,Y Entry"; font.pixelSize:vpx(12); layer.enabled:false }
            MouseArea { id:manPrMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; hoverEnabled:true
              onClicked:{ manualXStr=(Math.round(posX*1000)/10).toString(); manualYStr=(Math.round(posY*1000)/10).toString(); showManualUI=true } }
          }
        }

        Rectangle { width: col.width; height: vpx(1); color: "#22FFFFFF" }

        // Done button
        Rectangle {
          width: col.width; height: vpx(44); radius: vpx(4)
          color: doneMA.containsMouse ? accentHex : Qt.rgba(
            parseInt(accentHex.substr(1,2),16)/255,
            parseInt(accentHex.substr(3,2),16)/255,
            parseInt(accentHex.substr(5,2),16)/255, 0.5)
          Behavior on color { ColorAnimation { duration:100 } }
          Row { anchors.centerIn:parent; spacing:vpx(8)
            StyledText { text:"✔"; font.pixelSize:vpx(16); layer.enabled:false }
            StyledText { text:"Done"; font.pixelSize:vpx(16); font.bold:true; layer.enabled:false }
          }
          MouseArea { id:doneMA; anchors.fill:parent; cursorShape:Qt.PointingHandCursor; hoverEnabled:true; onClicked:{ root.visible=false; root.editorClosed() } }
        }

        StyledText {
          width:col.width; horizontalAlignment:Text.AlignHCenter
          text:"B / Esc to close · Tab for step size"
          font.pixelSize:vpx(10); color:"#333344"; layer.enabled:false
        }

        Item { height: vpx(8) }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SAVE PRESET DIALOG
  // ═══════════════════════════════════════════════════════════════
  Rectangle {
    anchors.fill:parent; color:"#CC000000"; z:10; visible:showSaveUI
    Rectangle {
      anchors.centerIn:parent; width:vpx(360); height:vpx(190)
      color:"#12121E"; radius:vpx(8); border.color:accentHex; border.width:vpx(2)
      Column {
        anchors.fill:parent; anchors.margins:vpx(22); spacing:vpx(14)
        StyledText { text:"Save Preset"; font.pixelSize:vpx(18); font.bold:true; layer.enabled:false }
        Rectangle {
          width:parent.width; height:vpx(40); radius:vpx(4)
          color:"#22FFFFFF"; border.color:accentHex; border.width:vpx(1)
          TextInput {
            id:presetTI; anchors.fill:parent; anchors.margins:vpx(10)
            text:newPresetName; color:"#FFFFFF"; font.pixelSize:vpx(15)
            focus:showSaveUI; selectByMouse:true; onTextChanged:newPresetName=text
          }
          StyledText { visible:presetTI.text.length===0; text:"Enter a name…"; color:"#555555"; font.pixelSize:vpx(15); anchors.verticalCenter:parent.verticalCenter; anchors.left:parent.left; anchors.leftMargin:vpx(10); layer.enabled:false }
        }
        RowLayout {
          width:parent.width; spacing:vpx(10)
          Rectangle { Layout.fillWidth:true; height:vpx(36); radius:vpx(4); color:"#2AFFFFFF"
            StyledText { anchors.centerIn:parent; text:"Cancel"; font.pixelSize:vpx(14); layer.enabled:false }
            MouseArea { anchors.fill:parent; onClicked:{ showSaveUI=false; root.forceActiveFocus() } }
          }
          Rectangle { Layout.fillWidth:true; height:vpx(36); radius:vpx(4); color:accentHex
            StyledText { anchors.centerIn:parent; text:"Save"; font.pixelSize:vpx(14); font.bold:true; layer.enabled:false }
            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
              onClicked:{
                var nm=newPresetName.trim()||("Preset "+(presets.length+1))
                var c=presets.slice(); c.push({name:nm,x:posX,y:posY,fontSize:fontSize,textOpacity:textOpacity})
                presets=c; pendingPresets=c; showSaveUI=false; root.forceActiveFocus()
              }
            }
          }
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MANUAL X/Y DIALOG
  // ═══════════════════════════════════════════════════════════════
  Rectangle {
    anchors.fill:parent; color:"#CC000000"; z:10; visible:showManualUI
    Rectangle {
      anchors.centerIn:parent; width:vpx(390); height:vpx(230)
      color:"#12121E"; radius:vpx(8); border.color:accentHex; border.width:vpx(2)
      Column {
        anchors.fill:parent; anchors.margins:vpx(22); spacing:vpx(12)
        StyledText { text:"Enter Position (0 – 100%)"; font.pixelSize:vpx(17); font.bold:true; layer.enabled:false }
        StyledText { text:"0% = left/top edge   100% = right/bottom edge"; font.pixelSize:vpx(12); color:"#888888"; layer.enabled:false }
        RowLayout {
          width:parent.width; spacing:vpx(16)
          Column { spacing:vpx(6)
            StyledText { text:"X  (left → right)"; font.pixelSize:vpx(12); color:"#AAAAAA"; layer.enabled:false }
            Rectangle {
              width:vpx(158); height:vpx(44); radius:vpx(4)
              color:"#22FFFFFF"; border.color:accentHex; border.width:vpx(1)
              TextInput { id:manXTI; anchors.fill:parent; anchors.margins:vpx(10); text:manualXStr; color:"#FFFFFF"; font.pixelSize:vpx(18); focus:showManualUI; inputMethodHints:Qt.ImhFormattedNumbersOnly; selectByMouse:true; onTextChanged:manualXStr=text }
              StyledText { visible:manXTI.text.length===0; text:"e.g. 95"; color:"#555555"; font.pixelSize:vpx(16); anchors.verticalCenter:parent.verticalCenter; anchors.left:parent.left; anchors.leftMargin:vpx(10); layer.enabled:false }
            }
          }
          Column { spacing:vpx(6)
            StyledText { text:"Y  (top → bottom)"; font.pixelSize:vpx(12); color:"#AAAAAA"; layer.enabled:false }
            Rectangle {
              width:vpx(158); height:vpx(44); radius:vpx(4)
              color:"#22FFFFFF"; border.color:accentHex; border.width:vpx(1)
              TextInput { id:manYTI; anchors.fill:parent; anchors.margins:vpx(10); text:manualYStr; color:"#FFFFFF"; font.pixelSize:vpx(18); inputMethodHints:Qt.ImhFormattedNumbersOnly; selectByMouse:true; onTextChanged:manualYStr=text }
              StyledText { visible:manYTI.text.length===0; text:"e.g. 5"; color:"#555555"; font.pixelSize:vpx(16); anchors.verticalCenter:parent.verticalCenter; anchors.left:parent.left; anchors.leftMargin:vpx(10); layer.enabled:false }
            }
          }
        }
        StyledText { text:"Current: X "+(Math.round(posX*1000)/10).toFixed(1)+"%   Y "+(Math.round(posY*1000)/10).toFixed(1)+"%"; font.pixelSize:vpx(12); color:"#888888"; layer.enabled:false }
        RowLayout {
          width:parent.width; spacing:vpx(10)
          Rectangle { Layout.fillWidth:true; height:vpx(36); radius:vpx(4); color:"#2AFFFFFF"
            StyledText { anchors.centerIn:parent; text:"Cancel"; font.pixelSize:vpx(14); layer.enabled:false }
            MouseArea { anchors.fill:parent; onClicked:{ showManualUI=false; root.forceActiveFocus() } }
          }
          Rectangle { Layout.fillWidth:true; height:vpx(36); radius:vpx(4); color:accentHex
            StyledText { anchors.centerIn:parent; text:"Apply"; font.pixelSize:vpx(14); font.bold:true; layer.enabled:false }
            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor
              onClicked:{
                var xv=Math.max(0,Math.min(99.9,parseFloat(manualXStr)||0))/100
                var yv=Math.max(0,Math.min(99.9,parseFloat(manualYStr)||0))/100
                posX=xv; posY=yv; commitPos(); showManualUI=false; root.forceActiveFocus()
              }
            }
          }
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // KEYBOARD
  // ═══════════════════════════════════════════════════════════════
  Keys.onUpPressed:    { if(!showSaveUI&&!showManualUI) nudge(0,-1); event.accepted=true }
  Keys.onDownPressed:  { if(!showSaveUI&&!showManualUI) nudge(0, 1); event.accepted=true }
  Keys.onLeftPressed:  { if(!showSaveUI&&!showManualUI) nudge(-1,0); event.accepted=true }
  Keys.onRightPressed: { if(!showSaveUI&&!showManualUI) nudge( 1,0); event.accepted=true }

  Keys.onPressed: {
    if (event.isAutoRepeat) return
    if (showSaveUI)   { if (api.keys.isCancel(event)) { showSaveUI=false;   event.accepted=true } return }
    if (showManualUI) { if (api.keys.isCancel(event)) { showManualUI=false; event.accepted=true } return }
    if (event.key === Qt.Key_Tab) { nudgeMode=(nudgeMode+1)%3; event.accepted=true; return }
    if (api.keys.isCancel(event)||api.keys.isAccept(event)) { root.visible=false; root.editorClosed(); event.accepted=true }
  }
}
