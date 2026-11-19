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
    // How many frames each baked set has and which one faces the camera, measured
    // from the bakers' own yaw loops by avatar_tools/make_stage_index.py.
    StageIndex { id: index }

    property string baseFolder: ""         // .../assets/3d/turntable/
    // Where the animated set lives, if one was baked. It is baked for the default
    // look only, so it does not follow the hairstyle the way the turntable does;
    // leave it empty to always use the static set.
    property string animatedFolder: ""     // .../assets/3d/animated/
    // Which turntable to play, from the hairstyle or wardrobe item the player
    // picked: "turntable/<stem>" or "shirts/<stem>", appended to baseFolder.
    property string variant: ""
    // What to play when variant has no frames at all - normally "turntable/",
    // the stock set, so a missing item bake never leaves an empty stage.
    property string defaultVariant: ""
    // Set when `variant` has no frames and the stock set is shown instead. It is
    // a flag rather than an assignment to `variant`, because assigning to a
    // bound property from here broke the parent's `variant: root.stageVariant`
    // binding: after one item with no baked set, the stage ignored every later
    // item and stayed blank for the rest of the session (measured: pick
    // `skinny-fit-jeans`, then `worn-jeans`, and `variant` never changed again).
    property bool fellBack: false
    onVariantChanged: if (fellBack) fellBack = false
    readonly property string activeVariant: fellBack ? defaultVariant : variant
    readonly property string folder: baseFolder + (activeVariant !== "" ? activeVariant + "/" : "")
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
    // The frame that looks at the camera. StageIndex names it for every shipped
    // set; a set baked after the index was last written is counted by `probe`
    // instead and falls back to restFrame.
    property int frontFrame: 0
    // True once StageIndex answered for this variant, which is what stops the
    // probe from counting the same set a second time and overwriting the count.
    property bool indexed: false
    // The baked sets are one pose from twenty angles, and only frame 10 of the
    // 20 (measured: see the contact sheet in research/shots/turntable_sheet.png)
    // looks at the camera - frames 0-2 are the back, 3-6 the right profile,
    // 7-9 the three-quarter. Spinning by default therefore opened the closet on
    // the avatar's back or side, which read as a broken mirror. The stage now
    // holds the front frame and turns only while you drag.
    property bool spinning: false
    property bool showShadow: true
    // Holds the pose timer, for a host that needs two grabs of one pose.
    property bool idle: true

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
        frontFrame = 0
        available = false
        indexed = false

        // The shipped sets are all described by StageIndex.qml, so a switch is
        // answered without touching the filesystem: no probe, no "Cannot open"
        // line per switch, and - the reason this exists - no moment where the
        // stage is still on frame 0 while the probe counts. For a whole-body
        // turntable frame 0 is the avatar's back, so that moment was a visible
        // flash of the back of its head on every item change.
        //
        // The animated set is a picture of one outfit, and set.json records which
        // set folder that outfit is (`turntable/jacket-with-sweater`). It plays
        // only while the player is wearing exactly that look; anything else uses
        // the set baked for the item picked.
        var anim = index.animated
        if (animatedFolder !== "" && anim && anim.variant === activeVariant) {
            animated = true
            yawCount = anim.yaws
            poseCount = anim.poses
            yaw = Math.floor(yawCount / 2)
            pose = 0
            indexed = true
            available = true
            return
        }
        var entry = index.sets[activeVariant]
        if (entry) {
            frameCount = entry.frames
            frontFrame = entry.front
            frame = entry.front
            indexed = true
            available = true
            return
        }

        // Not in the index: a set baked since it was last generated. Count it the
        // old way, one image at a time. An animated folder with no set.json is the
        // one case where its counts still have to be found by probing.
        if (animatedFolder !== "" && !anim)
            animProbe.start()
        else
            probe.loadNext()
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
            frame = frontFrame
        }
        holder.grabToImage(function (result) {
            callback(result)
        }, Qt.size(512, 768))
    }

    // Where the front is, for a set StageIndex does not name (baked after the
    // index was last written). The two bakers do not start at the same angle:
    //   six-frame item sets   (bake_pack_turntables.py)  yaw starts at pi, frame 00 front
    //   whole-body turntables (bake_turntable.py)        yaw starts at 0, frame 00 back
    // Three sets read frame by frame on 2026-11-19 agree with that:
    //   turntable/jacket-with-sweater  6 frames  frame_00 front
    //   turntable/hair_long_blond     20 frames  frame_00 back, frame_10 front
    //   turntable/hair_bun_red        18 frames  frame_00 back, frame_09 front
    // "Half the frames" was wrong for the item sets, which is why the closet opened
    // on the avatar's back; keying on `frameCount === 20` then left the 18-frame
    // hair set opening on the back instead. The split is the bake shape: six-frame
    // item sets start at the front, anything longer is a whole-body turntable that
    // starts at the back. For every shipped set the index states this outright
    // (make_stage_index.py checks these three measurements before writing it), so
    // this rule now only decides the first angle of a freshly baked set.
    readonly property int restFrame: frameCount > 6 ? Math.floor(frameCount / 2) : 0

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
            if (stage.indexed)
                return
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
            // A set the index already described must not be counted again: the
            // probe's own Ready would add to frameCount and break `shown`.
            if (stage.indexed)
                return
            if (stage.frameCount < 512)
                source = stage.framePath(stage.frameCount)
        }
        Component.onCompleted: if (stage.animatedFolder === "" && !stage.indexed) loadNext()
        onStatusChanged: {
            if (status === Image.Ready) {
                stage.available = true
                stage.frameCount += 1
                loadNext()
            } else if (status === Image.Error && stage.frameCount > 0) {
                // Open facing the player, from the measured rest frame for this
                // bake shape (see restFrame above).
                stage.frontFrame = stage.restFrame
                stage.frame = stage.frontFrame
            } else if (status === Image.Error && stage.frameCount === 0
                       && !stage.fellBack && stage.defaultVariant !== "") {
                // Nothing baked for this look: show the stock set rather than
                // an empty stage. Deferred, because changing the folder from
                // inside this handler assigned the probe's own `source` while Qt
                // was still delivering that source's status change, and the new
                // load was dropped - the probe stayed on the missing file.
                Qt.callLater(function () { stage.fellBack = true })
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
    // the soles at 93.2% of the frame (bake_turntable's 0.86 fit plus the feet at
    // y = 0) and the figure is fitted to the mirror opening below, so the shadow's
    // centre sits on the opening's bottom rail - the line the soles land on.
    // (The female bake puts them at 93.5%; the 0.3% is two pixels at stage size.)
    Image {
        visible: stage.showShadow && stage.available
        source: Qt.resolvedUrl("assets/_ui/shadow.png")
        anchors.horizontalCenter: holder.horizontalCenter
        width: holder.width * 0.95
        height: width * 0.30
        y: holder.y + holder.height * style.mirrorBottom - height / 2
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

        // The frames, fitted to the mirror's opening the same way the 2D stage
        // fits its plates (Style.qml holds the measured numbers): the baked frame
        // puts the soles at 0.932 of its canvas, and the opening's bottom rail is
        // at 0.915 of the holder, so the figure is scaled about its own sole line
        // and moved until that line sits on the rail.
        Item {
            id: figure
            width: holder.width * style.figureScale
            height: holder.height * style.figureScale
            // Child of holder: its coordinates are already in holder's space, so
            // adding holder.x/y again would push the figure off the mirror.
            x: (holder.width - width) / 2
            y: holder.height * style.mirrorBottom - height * style.soleFraction

            Image {
                anchors.fill: parent
                source: stage.shown
                fillMode: Image.PreserveAspectFit
                smooth: true
                cache: true
            }
        }
    }

    // No bob here, unlike the 2D stage: these are frames of a real clip, so the
    // idle already moves and sliding the whole image against a fixed shadow made
    // the avatar look like it was floating over its own feet.

    // How long one frame of the turn lasts. Every bake is exactly one turn:
    // bake_pack_turntables.py steps `yaw = pi + 2*pi*i/frames` and bake_turntable.py
    // the same, so a six-frame item set is 60 degrees per frame and the 20-frame
    // body turntable 18. A flat 90 ms per frame therefore spun the item sets - 1,128
    // of the 1,179 baked sets, everything the closet shows - 3.3 times faster than
    // the whole-body turn, and the animated set (12 yaws) had its own one-off 130.
    // The rate kept here is the one the 20-frame turntable already ran at, 90 ms x
    // 20 frames = 1.8 s per turn; the shorter sets get longer frames instead.
    readonly property int turnMillis: 1800
    readonly property int spinInterval: {
        var steps = animated ? yawCount : frameCount
        return steps > 1 ? Math.round(turnMillis / steps) : 0
    }

    Timer {
        interval: Math.max(16, stage.spinInterval)
        running: stage.available && stage.spinning && stage.spinInterval > 0
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
        running: stage.available && stage.animated && stage.poseCount > 1 && stage.idle
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
        // Released: keep the angle the player chose. The original editor does
        // not drift back to the front on its own either.
        onReleased: stage.spinning = false
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
