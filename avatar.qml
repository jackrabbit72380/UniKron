import QtQuick 2.15
import QtQuick.Window 2.15
import "avatar_theme/avatar"

Window {
    id: window

    width: 1180
    height: 700
    minimumWidth: 900
    minimumHeight: 560
    visible: true
    title: "Avatar Editor"
    color: "#0f1a05"

    Image {
        anchors.fill: parent
        source: "avatar_theme/assets/avatar/_ui/background.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    AvatarEditor {
        id: editor
        anchors.fill: parent

        // `backend` is supplied by main.py; a plain `qml main.qml` run has none.
        gamerTag: typeof backend !== "undefined" ? backend.gamerTag : "Player"

        onSaveRequested: function (state) {
            if (typeof backend !== "undefined")
                backend.saveAvatar(state)
        }

        onPortraitReady: function (grab) {
            if (typeof backend !== "undefined" && grab)
                grab.saveToFile(backend.portraitPath())
        }

        Component.onCompleted: {
            if (typeof backend !== "undefined")
                loadState(backend.loadAvatar())
        }
    }
}
