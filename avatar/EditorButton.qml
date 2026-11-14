import QtQuick 2.15

// A rounded pill button used for the editor's actions.
Rectangle {
    id: button

    Style { id: style }

    property string label: ""
    property bool primary: false
    property color accentColor: style.accent
    property color accentInkColor: style.inkOnCard
    signal clicked()

    implicitWidth: caption.implicitWidth + 40
    implicitHeight: 40
    radius: height / 2
    color: primary
           ? (pointer.containsMouse ? Qt.lighter(accentColor, 1.12) : accentColor)
           : (pointer.containsMouse ? style.cardHover : style.card)
    border.width: primary ? 0 : 1
    border.color: "#4dffffff"

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: caption
        anchors.centerIn: parent
        text: button.label
        color: button.primary ? button.accentInkColor : style.ink
        font.family: style.titleFamily
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
