import QtQuick 2.15

// The 3D view: a baked turntable of the avatar mesh, spun by dragging or left
// to idle-turn the way the dashboard's avatar does.
//
// The theme cannot load a mesh — Pegasus has no 3D scene module, and the source
// geometry is LZX-compressed STRB that only AvatarEditorRecomp decodes — so the
// frames are baked ahead of time by avatar_tools/bake_turntable.py from the
// model Avatar Aura exports. Everything here is plain Image, so it works on any
// Qt the theme runs on.
Item {
    id: stage

    Style { id: style }

    property string baseFolder: ""    // .../assets/3d/turntable/
    // Which baked set to play, from the hairstyle the player picked. Empty means
    // the default set directly in baseFolder; a name that has no frames (or no
    // bake for that hairstyle) falls back to it too.
    property string variant: ""
    readonly property string folder: baseFolder + (variant !== "" ? variant + "/" : "")
    property int frameCount: 0
    property int frame: 0
    property bool available: false
    property bool spinning: true

    onFolderChanged: {
        frameCount = 0
        frame = 0
        available = false
        probe.loadNext()
    }

    // Same contract as AvatarStage: the portrait is grabbed from whatever the
    // player is actually looking at.
    function capture(callback) {
        holder.grabToImage(function (result) {
            callback(result)
        }, Qt.size(512, 768))
    }

    function framePath(index) {
        return stage.folder + "frame_" + (index < 10 ? "0" : "") + index + ".png"
    }

    // Probe the folder one frame at a time: the frames are numbered from 00 with
    // no gaps, so the first missing index is the count. Asking for each frame
    // only once the last one loaded means a 24-frame set costs a single failed
    // load instead of 24 warnings in the log.
    Image {
        id: probe
        visible: false
        cache: false
        // Set by hand, not bound: assigning a bound source from its own status
        // handler is a binding loop.
        function loadNext() {
            if (stage.frameCount < 512)
                source = stage.framePath(stage.frameCount)
        }
        Component.onCompleted: loadNext()
        onStatusChanged: {
            if (status === Image.Ready) {
                stage.available = true
                stage.frameCount += 1
                loadNext()
            } else if (status === Image.Error && stage.frameCount === 0 && stage.variant !== "") {
                // Nothing baked for this hairstyle: show the default set.
                stage.variant = ""
            }
        }
    }

    Item {
        id: holder
        anchors.fill: parent

        Image {
            anchors.fill: parent
            source: stage.available ? stage.framePath(stage.frame) : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            cache: true
        }
    }

    // Same idle bob as the 2D stage, so the two modes read as one editor.
    SequentialAnimation {
        running: stage.available
        loops: Animation.Infinite
        NumberAnimation { target: holder; property: "y"; to: -6; duration: 1900; easing.type: Easing.InOutSine }
        NumberAnimation { target: holder; property: "y"; to: 0; duration: 1900; easing.type: Easing.InOutSine }
    }

    Timer {
        interval: 90
        running: stage.available && stage.spinning
        repeat: true
        onTriggered: if (stage.frameCount > 1)
                         stage.frame = (stage.frame + 1) % stage.frameCount
    }

    MouseArea {
        anchors.fill: parent
        enabled: stage.available
        property int pressFrame: 0
        property real pressX: 0
        onPressed: { pressFrame = stage.frame; pressX = mouse.x; stage.spinning = false }
        onPositionChanged: {
            var step = stage.width / Math.max(stage.frameCount, 1) * 1.4
            var delta = Math.round((pressX - mouse.x) / Math.max(step, 1))
            stage.frame = ((pressFrame + delta) % stage.frameCount + stage.frameCount) % stage.frameCount
        }
        onReleased: stage.spinning = true
    }

    Rectangle {
        visible: !stage.available
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.74, 470)
        height: hint.implicitHeight + 30
        radius: 12
        color: "#1b2634"
        opacity: 0.92

        Text {
            id: hint
            anchors.centerIn: parent
            width: parent.width - 32
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "No 3D frames yet\n"
                  + "Export the avatar as OBJ from Avatar Aura, then bake it into "
                  + "assets/3d/turntable with avatar_tools/bake_turntable.py."
            color: "#f4f7fa"
            font.family: style.titleFamily
            font.pixelSize: 14
            lineHeight: 1.25
        }
    }
}
