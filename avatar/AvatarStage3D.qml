import QtQuick 2.15

// The 3D view: a baked avatar, turned by dragging or left to idle-turn the way
// the dashboard's avatar does.
//
// The theme cannot load a mesh — Pegasus has no 3D scene module, and the source
// geometry is LZX-compressed STRB that only AvatarEditorRecomp decodes — so the
// frames are baked ahead of time by avatar_tools/bake_outfits.py (static) and
// avatar_tools/bake_animated.py (animated). Everything here is plain Image, so
// it works on any Qt the theme runs on.
//
// Two layouts are understood, and the animated one wins when it is present:
//
//   yaw_00_pose_00.png ...   angles crossed with poses from a real clip, so the
//                            avatar keeps moving while it turns
//   frame_00.png ...         one pose across many angles, used when no animated
//                            set was baked for this look
Item {
    id: stage

    Style { id: style }

    property string baseFolder: ""         // .../assets/3d/turntable/
    // Where the animated set lives, if one was baked. It is baked for the default
    // look only, so it does not follow the hairstyle the way the turntable does;
    // leave it empty to always use the static set.
    property string animatedFolder: ""     // .../assets/3d/animated/
    // Which turntable to play, from the hairstyle the player picked. Empty means
    // the default set directly under baseFolder; a name that has no frames (or no
    // bake for that hairstyle) falls back to it too.
    property string variant: ""
    readonly property string folder: baseFolder + (variant !== "" ? variant + "/" : "")
    // The static turntable: one pose, frameCount angles.
    property int frameCount: 0
    property int frame: 0
    // The animated set: yawCount angles crossed with poseCount poses.
    property bool animated: false
    property int yawCount: 0
    property int poseCount: 0
    property int yaw: 0
    property int pose: 0
    property bool available: false
    property bool spinning: true
    property bool showShadow: true

    onFolderChanged: reload()
    onAnimatedFolderChanged: reload()

    function reload() {
        frameCount = 0
        frame = 0
        animated = false
        yawCount = 0
        poseCount = 0
        yaw = 0
        pose = 0
        available = false
        animProbe.start()
    }

    // Same contract as AvatarStage: the portrait is grabbed from whatever the
    // player is actually looking at.
    function capture(callback) {
        // A portrait should face the player: the bake starts at the avatar's
        // back, so half the turn is the front. Snapping there first stops a grab
        // that catches the spin side-on from saving a picture of the back of
        // someone's head.
        if (animated && yawCount > 1) {
            yaw = Math.floor(yawCount / 2)
            pose = 0
        } else if (frameCount > 1) {
            frame = Math.floor(frameCount / 2)
        }
        holder.grabToImage(function (result) {
            callback(result)
        }, Qt.size(512, 768))
    }

    function padded(index) {
        return (index < 10 ? "0" : "") + index
    }

    function framePath(index) {
        return folder + "frame_" + padded(index) + ".png"
    }

    function animPath(turn, step) {
        return animatedFolder + "yaw_" + padded(turn) + "_pose_" + padded(step) + ".png"
    }

    readonly property string shown: animated
        ? animPath(yawCount > 0 ? yaw % yawCount : 0, poseCount > 0 ? pose % poseCount : 0)
        : (available ? framePath(frame) : "")

    // Probe the animated set first: poses at turn 0, then turns at pose 0, one
    // image at a time so a missing file costs a single failed load rather than a
    // log full of warnings. If the very first one is missing, fall through to the
    // static turntable.
    Image {
        id: animProbe
        visible: false
        cache: false
        property int phase: 0     // 0 = counting poses, 1 = counting turns, 2 = done
        property int seen: 0      // index currently being requested
        function start() {
            if (stage.animatedFolder === "") {
                probe.loadNext()
                return
            }
            phase = 0
            seen = 0
            source = stage.animPath(0, 0)
        }
        function step() {
            source = phase === 0 ? stage.animPath(0, seen) : stage.animPath(seen, 0)
        }
        onStatusChanged: {
            if (status === Image.Ready) {
                stage.animated = true
                stage.available = true
                if (phase === 0) {
                    stage.poseCount = seen + 1
                    seen += 1
                    step()
                } else if (phase === 1) {
                    stage.yawCount = seen + 1
                    seen += 1
                    step()
                }
            } else if (status === Image.Error) {
                if (phase === 0 && seen === 0) {
                    // No animated set for this look: use the turntable.
                    stage.animated = false
                    probe.loadNext()
                } else if (phase === 0) {
                    stage.poseCount = seen
                    phase = 1
                    seen = 1
                    step()
                } else if (phase === 1) {
                    stage.yawCount = seen
                    phase = 2
                    // Open facing the player: the bake starts at the avatar's
                    // back, so half a turn is the front.
                    stage.yaw = Math.floor(stage.yawCount / 2)
                }
            }
        }
    }

    // The static turntable: numbered from 00 with no gaps, so the first missing
    // index is the count.
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
        Component.onCompleted: if (stage.animatedFolder === "") loadNext()
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

    // The same mirror the 2D stage frames the avatar in, so the two modes sit in
    // one editor rather than two: the art is the closet's own frame, lifted from
    // avatareditor.xex, and the baked frames are 2:3 like the 2D stage's canvas.
    Image {
        anchors.centerIn: holder
        width: holder.width * 1.12
        height: holder.height * 1.12
        source: Qt.resolvedUrl("assets/_ui/xex/closet_mirror_border.png")
        // Cropped, not fitted, for the same reason as the 2D stage: the art is
        // square, a standing avatar is taller.
        fillMode: Image.PreserveAspectCrop
        smooth: true
        opacity: 0.9
        z: -1
    }

    // Soft shadow on the floor, the same one the 2D stage draws. The bake puts
    // the soles at 93.5% of the frame (bake_turntable's 0.86 fit plus the feet at
    // y = 0), so the shadow's centre has to sit on that line; at 92.5% the avatar
    // hovered a few pixels above its own shadow.
    Image {
        visible: stage.showShadow && stage.available
        source: Qt.resolvedUrl("assets/_ui/shadow.png")
        anchors.horizontalCenter: holder.horizontalCenter
        width: holder.width * 0.95
        height: width * 0.30
        y: holder.y + holder.height * 0.935 - height / 2
        fillMode: Image.PreserveAspectFit
        opacity: 0.85
    }

    // 2:3, centred: the baked frames' own shape. It is also the shape a portrait
    // wants, so a grab of this item needs no stretching either way.
    Item {
        id: holder
        anchors.centerIn: parent
        width: Math.min(stage.width, stage.height * 2 / 3)
        height: width * 3 / 2

        Image {
            anchors.fill: parent
            source: stage.shown
            fillMode: Image.PreserveAspectFit
            smooth: true
            cache: true
        }
    }

    // No bob here, unlike the 2D stage: these are frames of a real clip, so the
    // idle already moves and sliding the whole image against a fixed shadow made
    // the avatar look like it was floating over its own feet.

    Timer {
        // Fewer angles than the 20-frame turntable, so give each one longer.
        interval: stage.animated ? 130 : 90
        running: stage.available && stage.spinning
        repeat: true
        onTriggered: {
            if (stage.animated) {
                if (stage.yawCount > 1)
                    stage.yaw = (stage.yaw + 1) % stage.yawCount
            } else if (stage.frameCount > 1) {
                stage.frame = (stage.frame + 1) % stage.frameCount
            }
        }
    }

    // The clip's own motion, at a walking pace: the poses are even samples across
    // a standing clip, so this reads as weight shifting rather than an animation.
    Timer {
        interval: 200
        running: stage.available && stage.animated && stage.poseCount > 1
        repeat: true
        onTriggered: stage.pose = (stage.pose + 1) % stage.poseCount
    }

    MouseArea {
        anchors.fill: parent
        enabled: stage.available
        property int pressFrame: 0
        property int pressYaw: 0
        property real pressX: 0
        onPressed: {
            pressFrame = stage.frame
            pressYaw = stage.yaw
            pressX = mouse.x
            stage.spinning = false
        }
        onPositionChanged: {
            if (stage.animated) {
                if (stage.yawCount < 2)
                    return
                var yawStep = stage.width / stage.yawCount * 1.4
                var turned = Math.round((pressX - mouse.x) / Math.max(yawStep, 1))
                stage.yaw = ((pressYaw + turned) % stage.yawCount + stage.yawCount) % stage.yawCount
            } else {
                var step = stage.width / Math.max(stage.frameCount, 1) * 1.4
                var delta = Math.round((pressX - mouse.x) / Math.max(step, 1))
                stage.frame = ((pressFrame + delta) % stage.frameCount + stage.frameCount) % stage.frameCount
            }
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
                  + "Bake them with avatar_tools/bake_outfits.py or "
                  + "avatar_tools/bake_animated.py into assets/3d."
            color: "#f4f7fa"
            font.family: style.titleFamily
            font.pixelSize: 14
            lineHeight: 1.25
        }
    }
}
