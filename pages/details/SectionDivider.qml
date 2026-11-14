import QtQuick 2.8
import QtQuick.Layouts 1.1
import "../../components"

// A simple labelled divider line used inside PlacementEditor
Item {
  id: root
  property string label: ""
  width: parent ? parent.width : 240
  height: vpx(20)

  RowLayout {
    anchors.fill: parent
    spacing: vpx(6)

    Rectangle { height: vpx(1); Layout.fillWidth: true; color: "#33FFFFFF" }

    StyledText {
      visible: label.length > 0
      text: label
      font.pixelSize: vpx(10)
      color: "#555566"
      layer.enabled: false
    }

    Rectangle { height: vpx(1); Layout.fillWidth: true; color: "#33FFFFFF"; visible: label.length > 0 }
  }
}
