import QtQuick 2.15
import "Style.js" as S

// Horizontal strip of the items in one category folder.
Item {
    id: strip

    property var model: null
    property string selectedName: ""
    property url bodySource
    property bool allowNone: true
    property string emptyHint: "No items in this folder yet"

    signal picked(string fileName)

    clip: true

    function revealSelection() {
        if (!model)
            return
        if (selectedName !== "") {
            for (var i = 0; i < model.count; ++i) {
                if (model.get(i).fileName === selectedName) {
                    list.positionViewAtIndex(i, ListView.Center)
                    return
                }
            }
        }
        list.positionViewAtBeginning()
    }

    onSelectedNameChanged: revealSelection()

    Connections {
        target: strip.model ? strip.model : null
        function onCountChanged() { strip.revealSelection() }
    }

    ListView {
        id: list
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: 12
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: strip.model

        header: Item {
            width: strip.allowNone ? 132 : 0
            height: 186
            visible: strip.allowNone
            ItemTile {
                anchors.bottom: parent.bottom
                width: 132
                height: 186
                label: "None"
                noneTile: true
                selected: strip.selectedName === ""
                onPicked: strip.picked("")
            }
        }

        delegate: ItemTile {
            label: S.itemLabel(fileName)
            imageSource: filePath
            bodySource: strip.bodySource
            selected: strip.selectedName === fileName
            onPicked: strip.picked(fileName)
        }
    }

    Text {
        anchors.centerIn: parent
        visible: (!model || model.count === 0)
        text: strip.emptyHint
        color: S.inkDim
        font.family: S.titleFamily
        font.pixelSize: 15
    }
}
