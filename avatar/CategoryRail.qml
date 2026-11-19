import QtQuick 2.15

// Vertical list of the category folders found in assets/.
//
// The rows are filled pills in the closet's own colours — #c6f473 selected,
// #38485e / #43546e unselected, sampled from its 512x128 button plates in
// avatareditor.xex.
//
// Using the plates themselves here was tried and is worse: border_long_nofill_*
// is an outline frame with a baked drop shadow, so at a 168x42 row it reads as a
// faint offset box with the label crossing its edge. The plates are drawn for a
// 4:1 slot about three times this size.
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

            color: index === rail.currentIndex
                   ? "#c6f473"
                   : (pointer.containsMouse ? "#43546e" : "#38485e")

            Behavior on color { ColorAnimation { duration: 120 } }

            // "Skin Color and Body" is the longest label the retail scene has
            // (CATEGORIES.md), and at 168 px - the rail's width at 960x720 - a
            // 15 px label elided mid-word. 14 px with these margins fits it with
            // room to spare, measured on the rendered closet.
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: pill.modelData ? pill.modelData.label : ""
                // Literals, not style.*: inside a ListView delegate the Style
                // object of the root is not resolved when these first bind, and
                // Qt then logs "Unable to assign [undefined]" once per row.
                color: index === rail.currentIndex ? "#1f2b0a" : "#ffffff"
                font.family: "Segoe UI"
                font.pixelSize: 13
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
