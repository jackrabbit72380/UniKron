import QtQuick 2.15

// The avatar itself: every chosen item, stacked in layer order over a shadow.
Item {
    id: stage

    Style { id: style }

    property var layers: []          // [{ url: ..., z: ... }]
    property string emptyHint: ""
    property real bob: 0

    onLayersChanged: pop.restart()

    function capture(callback) {
        frame.grabToImage(function (result) {
            callback(result)
        }, Qt.size(512, 768))
    }

    // soft shadow on the floor
    Image {
        source: Qt.resolvedUrl("assets/_ui/shadow.png")
        anchors.horizontalCenter: frame.horizontalCenter
        width: frame.width * 0.95
        height: width * 0.30
        y: frame.y + frame.height * 0.925 - height / 2
        fillMode: Image.PreserveAspectFit
        opacity: 0.85
    }

    Item {
        id: frame
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        readonly property real fit: Math.min(stage.width / 512, stage.height / 768)
        width: 512 * fit
        height: 768 * fit

        Item {
            id: body
            width: frame.width
            height: frame.height

            // The closet's own mirror frame, lifted from avatareditor.xex.
            Image {
                anchors.fill: parent
                anchors.margins: -frame.width * 0.06
                source: Qt.resolvedUrl("assets/_ui/xex/closet_mirror_border.png")
                // Cropped, not fitted: the frame art is square but a standing
                // avatar is taller, so the mirror has to stretch with it.
                fillMode: Image.PreserveAspectCrop
                smooth: true
                opacity: 0.9
                z: -1
            }

            transform: [
                Translate { y: stage.bob },
                Scale {
                    origin.x: body.width / 2
                    origin.y: body.height
                    xScale: pop.scale
                    yScale: pop.scale
                }
            ]

            Repeater {
                model: stage.layers

                delegate: Image {
                    required property var modelData

                    anchors.fill: parent
                    z: modelData.z
                    source: modelData.url
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    sourceSize.height: 1400
                }
            }
        }
    }

    // gentle idle bob, the way the dashboard avatars breathe
    SequentialAnimation {
        running: true
        loops: Animation.Infinite
        NumberAnimation { target: stage; property: "bob"; to: -5; duration: 1900; easing.type: Easing.InOutSine }
        NumberAnimation { target: stage; property: "bob"; to: 0; duration: 1900; easing.type: Easing.InOutSine }
    }

    SequentialAnimation {
        id: pop
        property real scale: 1
        NumberAnimation { target: pop; property: "scale"; to: 1.04; duration: 110 }
        NumberAnimation { target: pop; property: "scale"; to: 1.0; duration: 150 }
    }

    Text {
        anchors.centerIn: parent
        visible: stage.layers.length === 0 && stage.emptyHint !== ""
        text: stage.emptyHint
        color: style.inkDim
        font.family: style.titleFamily
        font.pixelSize: 17
    }
}
