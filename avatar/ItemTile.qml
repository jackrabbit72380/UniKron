import QtQuick 2.15

// One entry in the item strip: the closet's own 128x128 card art — lime when
// chosen, grey when not, and a red/blue cross for "None" — with the item drawn
// over the current body so you can see what it will look like, plus its name.
//
// The card art came out of avatareditor.xex as four 128x128 PNGs: the empty
// selected/unselected slots and the selected/unselected None crosses.
Item {
    id: tile

    Style { id: style }

    property url imageSource
    property url bodySource
    property string label: ""
    property bool selected: false
    property bool noneTile: false

    signal picked()

    implicitWidth: 112
    implicitHeight: 152

    readonly property url cardSource: Qt.resolvedUrl(
        noneTile
        ? "assets/_ui/xex/item_none_" + (selected ? "selected" : "unselected") + ".png"
        : "assets/_ui/xex/item_slot_" + (selected ? "selected" : "unselected") + ".png")

    Image {
        id: card
        width: parent.width
        height: width
        source: tile.cardSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        scale: pointer.containsMouse ? 1.03 : 1.0
        Behavior on scale { NumberAnimation { duration: 90 } }
    }

    Image {
        anchors.fill: card
        anchors.margins: 12
        source: tile.noneTile ? "" : tile.bodySource
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        opacity: 0.4
        visible: !tile.noneTile && String(tile.bodySource).length > 0
    }

    Image {
        anchors.fill: card
        anchors.margins: 12
        source: tile.noneTile ? "" : tile.imageSource
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        sourceSize.height: 360
        visible: !tile.noneTile
    }

    Text {
        anchors.top: card.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        text: tile.noneTile ? "None" : tile.label
        color: style.ink
        font.family: style.titleFamily
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
