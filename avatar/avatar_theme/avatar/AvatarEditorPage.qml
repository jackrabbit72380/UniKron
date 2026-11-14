import QtQuick 2.15
import "Style.js" as S

// The avatar editor as a page the theme opens on top of itself.
//
//   AvatarEditorPage {
//       id: avatarEditor
//       onAccepted: function (state) { profile.avatar = state; saveProfile() }
//   }
//   ...
//   avatarEditor.open(profile.avatar)
//
// Save in the editor closes the page with the new state; B / Esc / the editor's
// back request closes it without saving. The host keeps `opened` in sync, so
// its own controller navigation is untouched while the page is closed.
Item {
    id: page

    property bool opened: false
    property url assetsFolder: Qt.resolvedUrl("../assets/avatar/")
    property string gamerTag: "Player"
    property string title: "Avatar Editor"

    property color accentColor: "#57c7f2"
    property color accentInkColor: "#062033"
    property color scrimColor: "#cc05101c"
    property color panelColor: "#e60d1b2a"
    property color borderColor: "#3d6b86"

    signal accepted(var state)
    signal cancelled()
    signal portraitReady(var grabResult)

    visible: opened
    enabled: opened
    opacity: opened ? 1 : 0
    z: 100

    Behavior on opacity { NumberAnimation { duration: 160 } }

    function open(state) {
        if (state)
            editor.loadState(state)
        opened = true
        editor.forceActiveFocus()
    }

    function close() {
        opened = false
    }

    // Save grabs the stage once, so a host can keep the picture (a PNG for the
    // profile) as well as the state map, then closes.
    property var _pendingState: null

    function accept() {
        _pendingState = editor.currentState()
        editor.capturePortrait()
        acceptFallback.restart()
    }

    function finishAccept(grab) {
        acceptFallback.stop()
        if (grab)
            page.portraitReady(grab)
        if (_pendingState === null)
            return
        var state = _pendingState
        _pendingState = null
        close()
        accepted(state)
    }

    Timer {
        id: acceptFallback
        interval: 1500
        onTriggered: page.finishAccept(null)
    }

    function cancel() {
        close()
        cancelled()
    }

    Rectangle {
        anchors.fill: parent
        color: page.scrimColor
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.margins: 16
        radius: 14
        color: page.panelColor
        border.width: 1
        border.color: page.borderColor

        scale: page.opened ? 1.0 : 0.985
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        AvatarEditor {
            id: editor
            anchors.fill: parent
            anchors.margins: 4
            assetsFolder: page.assetsFolder
            gamerTag: page.gamerTag
            title: page.title
            accentColor: page.accentColor
            accentInkColor: page.accentInkColor
            onBackRequested: page.cancel()
            onSaveRequested: page.accept()
            onPortraitReady: function (grab) { page.finishAccept(grab) }
        }
    }
}
