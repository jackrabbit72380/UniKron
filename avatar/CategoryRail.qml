import QtQuick 2.15
import "Style.js" as S

// Vertical list of the category folders found in assets/.
Item {
    id: rail

    property var categories: []
    property int currentIndex: 0
    property color accentColor: S.accent
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
            radius: 20
            color: index === rail.currentIndex
                   ? S.cardActive
                   : (pointer.containsMouse ? S.cardHover : S.card)
            border.width: index === rail.currentIndex ? 0 : 1
            border.color: "#33ffffff"

            Behavior on color { ColorAnimation { duration: 120 } }

            Rectangle {
                width: 6
                height: 20
                radius: 3
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                color: S.accent
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
                color: index === rail.currentIndex ? S.inkOnCard : S.ink
                font.family: S.titleFamily
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
