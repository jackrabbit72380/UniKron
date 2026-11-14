import QtQuick 2.15
import "Style.js" as S

// A rounded pill button used for the editor's actions.
Rectangle {
    id: button

    property string label: ""
    property bool primary: false
    property color accentColor: S.accent
    property color accentInkColor: S.inkOnCard
    signal clicked()

    implicitWidth: caption.implicitWidth + 40
    implicitHeight: 40
    radius: height / 2
    color: primary
           ? (pointer.containsMouse ? Qt.lighter(accentColor, 1.12) : accentColor)
           : (pointer.containsMouse ? S.cardHover : S.card)
    border.width: primary ? 0 : 1
    border.color: "#4dffffff"

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: caption
        anchors.centerIn: parent
        text: button.label
        color: button.primary ? button.accentInkColor : S.ink
        font.family: S.titleFamily
        font.pixelSize: 15
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
