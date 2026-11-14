import QtQuick 2.8
import QtQuick.Layouts 1.1
import "../../components"

// ─────────────────────────────────────────────────────────────────
// SliderRow.qml  —  compact label + slider + value used in PlacementEditor
// ─────────────────────────────────────────────────────────────────
Item {
  id: root

  property string label:    "X"
  property real   value:    0        // displayed / current value
  property string unit:     "%"
  property real   min:      0
  property real   max:      100
  property string accentHex: "#5d9809"

  signal decrement()
  signal increment()
  signal slide(real val)   // emits the new raw value in [min,max]

  width:  parent ? parent.width : 240
  height: vpx(48)

  // Label
  StyledText {
    id: lbl
    text: root.label
    font.pixelSize: vpx(12); color: "#AAAAAA"
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: vpx(34)
    layer.enabled: false
  }

  // − button
  Rectangle {
    id: decBtn
    anchors.left: lbl.right; anchors.leftMargin: vpx(2)
    anchors.verticalCenter: parent.verticalCenter
    width: vpx(22); height: vpx(22); radius: vpx(3)
    color: decMA.pressed ? root.accentHex : "#44FFFFFF"
    StyledText { anchors.centerIn: parent; text: "−"; font.pixelSize: vpx(14); layer.enabled: false }
    MouseArea {
      id: decMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
      onClicked: root.decrement()
    }
  }

  // Slider track
  Rectangle {
    id: track
    anchors.left:  decBtn.right; anchors.leftMargin:  vpx(4)
    anchors.right: incBtn.left;  anchors.rightMargin: vpx(4)
    anchors.verticalCenter: parent.verticalCenter
    height: vpx(6); radius: vpx(3)
    color: "#33FFFFFF"

    // Fill
    Rectangle {
      width:  Math.max(vpx(6), track.width * (root.value - root.min) / (root.max - root.min))
      height: parent.height; radius: parent.radius
      color:  root.accentHex
      Behavior on width { NumberAnimation { duration: 60 } }
    }

    // Thumb
    Rectangle {
      id: thumb
      width: vpx(14); height: vpx(14); radius: vpx(7)
      color: "#FFFFFF"
      border.color: root.accentHex; border.width: vpx(2)
      x: Math.max(0, Math.min(track.width - width,
           track.width * (root.value - root.min) / (root.max - root.min) - width / 2))
      y: (track.height - height) / 2
      Behavior on x { NumberAnimation { duration: 60 } }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.SizeHorCursor
      onPressed:  { updateFromMouse(mouse.x) }
      onPositionChanged: { if (pressed) updateFromMouse(mouse.x) }
      function updateFromMouse(mx) {
        var ratio = Math.max(0, Math.min(1, mx / track.width))
        root.slide(root.min + ratio * (root.max - root.min))
      }
    }
  }

  // + button
  Rectangle {
    id: incBtn
    anchors.right: valLabel.left; anchors.rightMargin: vpx(4)
    anchors.verticalCenter: parent.verticalCenter
    width: vpx(22); height: vpx(22); radius: vpx(3)
    color: incMA.pressed ? root.accentHex : "#44FFFFFF"
    StyledText { anchors.centerIn: parent; text: "+"; font.pixelSize: vpx(14); layer.enabled: false }
    MouseArea {
      id: incMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
      onClicked: root.increment()
    }
  }

  // Value label
  StyledText {
    id: valLabel
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: vpx(50)
    horizontalAlignment: Text.AlignRight
    text: {
      var v = root.value
      if (root.unit === "%") return v.toFixed(1) + "%"
      return Math.round(v) + root.unit
    }
    font.pixelSize: vpx(12); font.bold: true
    layer.enabled: false
  }
}
