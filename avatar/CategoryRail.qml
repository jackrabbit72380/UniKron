import QtQuick 2.15

// Vertical list of the category folders found in assets/.
Item {
    id: rail

    Style { id: style }

    property var categories: []
    property int currentIndex: 0
    property color accentColor: style.accent
    signal activated(int index)

    implicitWidth: 208
    clip: true

    onCurrentIndexChanged: railList.positionViewAtIndex(currentIndex, ListView.Contain)

    ListView {
        id: railList
        anchors.fill: parent
        spacing: 5
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: rail.categories
        currentIndex: rail.currentIndex

        delegate: Rectangle {
            id: pill
            required property var modelData
            required property int index

            width: railList.width
            height: 40
            radius: 8

            // The closet's own selected/unselected button colours, sampled from
            // its 512x128 plates in avatareditor.xex (#c6f473 / #38485e). The
            // plates themselves are outline frames and look wrong stretched
            // into a pill this shape, so only their palette is used here.
            color: index === rail.currentIndex
                   ? "#c6f473"
                   : (pointer.containsMouse ? "#43546e" : "#38485e")

            Behavior on color { ColorAnimation { duration: 120 } }

            Rectangle {
                width: 6
                height: 20
                radius: 3
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                color: style.accent
                opacity: index === rail.currentIndex ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 26
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: pill.modelData.label
                color: index === rail.currentIndex ? style.inkOnCard : style.ink
                font.family: style.titleFamily
                font.pixelSize: 15
                font.weight: index === rail.currentIndex ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }

            MouseArea {
                id: pointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: rail.activated(index)
            }
        }
    }
}
