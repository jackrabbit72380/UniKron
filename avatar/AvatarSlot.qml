import QtQuick 2.15

// One tile in a profile manager's avatar grid. With addTile it is the "+" box
// that opens the avatar editor.
//
//   AvatarSlot { state: profile.avatar; selected: index === current }
//   AvatarSlot { addTile: true; onClicked: avatarEditor.open(profile.avatar) }
//
// Colours are properties so the tile can sit in any theme's palette.
Item {
    id: slot

    property var state: ({})
    property bool addTile: false
    property bool selected: false
    property url assetsFolder: Qt.resolvedUrl("assets/")

    property color panelColor: "#2a0b1626"
    property color panelHoverColor: "#3d14283e"
    property color selectedColor: "#33203c56"
    property color borderColor: "#3d6b86"
    property color accentColor: "#57c7f2"
    property color textColor: "#e6f4fb"

    signal clicked()

    implicitWidth: 104
    implicitHeight: 118

    Rectangle {
        id: box
        anchors.fill: parent
        radius: 10
        color: slot.selected
               ? slot.selectedColor
               : (pointer.containsMouse ? slot.panelHoverColor : slot.panelColor)
        border.width: slot.selected ? 2 : 1
        border.color: slot.selected ? slot.accentColor : slot.borderColor

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    AvatarThumb {
        anchors.fill: box
        anchors.margins: slot.selected ? 8 : 7
        visible: !slot.addTile
        state: slot.state
        assetsFolder: slot.assetsFolder
    }

    // the plus, drawn rather than typed so it never depends on a font
    Item {
        anchors.centerIn: box
        width: 34
        height: 34
        visible: slot.addTile

        Rectangle {
            anchors.centerIn: parent
            width: 30
            height: 3
            radius: 1.5
            color: slot.accentColor
        }
        Rectangle {
            anchors.centerIn: parent
            width: 3
            height: 30
            radius: 1.5
            color: slot.accentColor
        }
        scale: pointer.containsMouse ? 1.12 : 1.0
        Behavior on scale { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: slot.clicked()
    }
}
