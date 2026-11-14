import QtQuick 2.15
import "Style.js" as S

// One entry in the item strip: the item drawn over the current body so you can
// see what it will look like, plus its name.
Item {
    id: tile

    property url imageSource
    property url bodySource
    property string label: ""
    property bool selected: false
    property bool noneTile: false

    signal picked()

    implicitWidth: 132
    implicitHeight: 186

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 16
        color: tile.selected ? S.cardActive
                             : (pointer.containsMouse ? S.cardHover : S.card)
        border.width: tile.selected ? 0 : 1
        border.color: "#33ffffff"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Image {
        id: underlay
        anchors.fill: parent
        anchors.margins: 8
        source: tile.noneTile ? "" : tile.bodySource
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        opacity: 0.4
        visible: !tile.noneTile && String(tile.bodySource).length > 0
    }

    Image {
        anchors.fill: parent
        anchors.margins: 8
        source: tile.noneTile ? "" : tile.imageSource
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        sourceSize.height: 360
        visible: !tile.noneTile
    }

    Text {
        anchors.centerIn: parent
        visible: tile.noneTile
        text: "\u2715"
        color: S.ink
        opacity: 0.55
        font.pixelSize: 34
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        width: parent.width - 16
        text: tile.label
        color: tile.selected ? S.inkOnCard : S.ink
        font.family: S.titleFamily
        font.pixelSize: 12
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.picked()
    }
}
