import QtQuick 2.15
import QtQuick.Window 2.15
import ".."

// The same window as avatar_preview.qml, but browsing the pack's own items from
// the first frame.
//
// `usePackArt` is read once while seeding, so flipping it after load leaves the
// theme's picks in `state` and the stage then asks pack_art/ for names like
// `jeans_indigo.png`, which do not exist there. Starting in pack mode is how the
// editor is meant to be used, and this harness is the way to see it.
Window {
    id: window

    width: 1180
    height: 700
    minimumWidth: 900
    minimumHeight: 560
    visible: true
    title: "Avatar Editor (pack items)"
    color: "#0f1a05"

    Image {
        anchors.fill: parent
        source: "../assets/_ui/background.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    AvatarEditor {
        id: editor
        anchors.fill: parent
        usePackArt: true

        gamerTag: typeof backend !== "undefined" ? backend.gamerTag : "Player"

        onSaveRequested: function (state) {
            if (typeof backend !== "undefined")
                backend.saveAvatar(state)
        }

        onPortraitReady: function (grab) {
            if (typeof backend !== "undefined" && grab)
                grab.saveToFile(backend.portraitPath())
        }
    }
}
