import QtQuick 2.15
import "../avatar/avatar_theme/avatar"

// Profiles Manager — owns a profile's avatar and is the one place the avatar
// editor is opened from: the "Choose Avatar" list ends with a "+ New Avatar…"
// row that opens AvatarEditorPage over this page.
//
// Router path (from theme.qml):  "Profiles/ProfilesPage.qml"
//   router.navigate({ path: "Profiles/ProfilesPage.qml", showStage: false })
FocusScope {
    id: page
    objectName: "profilesPage"

    property string profileName: "Rockstar"
    property var avatar: ({})
    property int presetIndex: -1
    property var presets: page.buildPresets()

    property color accentColor: "#57c7f2"
    property color accentInkColor: "#062033"
    property color panelColor: "#e60c1624"
    property color borderColor: "#3d6b86"
    property color rowColor: "#2a16232f"
    property color textColor: "#eaf4fb"
    property color dimColor: "#9fb3c4"

    // ── data ───────────────────────────────────────────────────────────────
    function preset(body, pants, shoes, shirt, hair, extra) {
        var s = { "10_body": body, "20_pants": pants, "30_shoes": shoes, "40_shirt": shirt }
        if (hair)
            s["50_hair"] = hair
        if (extra) {
            for (var k in extra)
                s[k] = extra[k]
        }
        return s
    }

    function buildPresets() {
        return [
            preset("body_tan.png", "jeans_indigo.png", "sneakers_white.png", "tee_blue.png", "hair_short_brown.png"),
            preset("body_pale.png", "shorts_khaki.png", "trainers_red.png", "jersey_green.png", "hair_bun_red.png"),
            preset("body_deep.png", "joggers_black.png", "boots_brown.png", "coat_navy.png", "hair_spiky_black.png", { "70_glasses": "shades_dark.png" }),
            preset("body_brown.png", "cargo_olive.png", "boots_brown.png", "hoodie_grey.png", "hair_long_blond.png", { "60_hat": "cap_blue.png" }),
            preset("body_light.png", "jeans_indigo.png", "sneakers_white.png", "tank_white.png", "hair_short_brown.png", { "45_facial-hair": "mustache_brown.png" }),
            preset("body_tan.png", "joggers_black.png", "trainers_red.png", "tank_white.png", "hair_bun_red.png", { "60_hat": "beanie_grey.png" }),
            preset("body_pale.png", "jeans_indigo.png", "boots_brown.png", "coat_navy.png", "hair_spiky_black.png", { "45_facial-hair": "beard_brown.png", "70_glasses": "glasses_round.png" }),
            preset("body_deep.png", "cargo_olive.png", "sneakers_white.png", "hoodie_grey.png", "hair_long_blond.png"),
            preset("body_brown.png", "shorts_khaki.png", "trainers_red.png", "tee_blue.png", "hair_short_brown.png"),
            preset("body_light.png", "cargo_olive.png", "boots_brown.png", "jersey_green.png", "hair_bun_red.png"),
            preset("body_tan.png", "jeans_indigo.png", "boots_brown.png", "hoodie_grey.png", "hair_spiky_black.png", { "60_hat": "beanie_grey.png" })
        ]
    }

    // ── persistence: api.memory when running in Pegasus, in memory otherwise ─
    function storedAvatar() {
        var saved = ""
        if (typeof api !== "undefined" && api.memory)
            saved = api.memory.get("profile.avatar") || ""
        if (!saved)
            return ({})
        try { return JSON.parse(saved) } catch (e) { return ({}) }
    }

    function storeAvatar(state) {
        avatar = state
        presetIndex = page.indexOfPreset(state)
        if (typeof api !== "undefined" && api.memory)
            api.memory.set("profile.avatar", JSON.stringify(state))
    }

    function indexOfPreset(state) {
        for (var i = 0; i < presets.length; ++i) {
            var same = true
            for (var k in presets[i])
                if (presets[i][k] !== state[k]) { same = false; break }
            if (same)
                return i
        }
        return -1
    }

    // ── the two actions the page offers ────────────────────────────────────
    function choosePreset(index) {
        if (index < 0 || index >= presets.length)
            return
        storeAvatar(presets[index])
        avatarMenu.close()
    }

    function editAvatar() {
        avatarMenu.close()
        editorPage.open(avatar)
    }

    function showAvatarMenu() {
        if (editorPage.opened)
            return
        avatarMenu.toggle()
    }

    Component.onCompleted: {
        avatar = storedAvatar()
        presetIndex = page.indexOfPreset(avatar)
        if (presetIndex < 0 && !Object.keys(avatar).length) {
            avatar = presets[0]
            presetIndex = 0
        }
    }

    // ── header + tabs ──────────────────────────────────────────────────────
    Rectangle {
        id: frame
        anchors.fill: parent
        radius: 12
        color: page.panelColor
        border.width: 1
        border.color: page.borderColor

        Column {
            id: body
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Row {
                spacing: 8

                Text {
                    text: "Profiles"
                    color: page.textColor
                    font.family: "Segoe UI"
                    font.pixelSize: 22
                    font.bold: true
                }
                Text {
                    text: "Manager"
                    color: page.accentColor
                    font.family: "Segoe UI"
                    font.pixelSize: 22
                }
            }

            Row {
                spacing: 6

                Repeater {
                    model: ["Info", "Stats", "Edit", "Create", "Appearance"]

                    delegate: Rectangle {
                        required property int index
                        required property string modelData

                        width: tabLabel.implicitWidth + 26
                        height: 28
                        radius: 6
                        color: index === 3 ? page.rowColor : "transparent"
                        border.width: index === 3 ? 1 : 0
                        border.color: page.accentColor

                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: parent.index === 3 ? page.textColor : page.dimColor
                            font.family: "Segoe UI"
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // ── option rows ────────────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 8

                Repeater {
                    id: rows
                    model: [
                        { label: "Gamer Pic", button: "Choose Gamer Pic" },
                        { label: "Gamer Tag", button: "Choose Gamer Tag" },
                        { label: "Colors", button: "Choose Color" },
                        { label: "Avatar", button: "Choose Avatar" },
                        { label: "Profile Shape", button: "Choose Shape" },
                        { label: "Top Border", button: "Choose Top Border" }
                    ]

                    delegate: Item {
                        required property var modelData
                        required property int index

                        width: parent ? parent.width : 0
                        height: 34

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: page.textColor
                            font.family: "Segoe UI"
                            font.pixelSize: 14
                        }

                        Rectangle {
                            id: optionButton
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 176
                            height: 30
                            radius: 6
                            color: buttonPointer.containsMouse ? "#33465f": page.rowColor
                            border.width: 1
                            border.color: index === 3 && avatarMenu.opened ? page.accentColor : page.borderColor

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.parent.modelData.button
                                color: page.textColor
                                font.family: "Segoe UI"
                                font.pixelSize: 12
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "▾"
                                color: page.accentColor
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: buttonPointer
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: index === 3
                                cursorShape: index === 3 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: page.showAvatarMenu()
                            }
                        }
                    }
                }
            }

            // ── avatar grid ────────────────────────────────────────────────
            Grid {
                spacing: 8
                columns: 6

                Repeater {
                    model: page.presets.length

                    delegate: Item {
                        required property int index
                        width: 78
                        height: 96

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: index === page.presetIndex ? "#33203c56" : "#2615202e"
                            border.width: index === page.presetIndex ? 2 : 1
                            border.color: index === page.presetIndex ? page.accentColor : page.borderColor
                        }

                        AvatarThumb {
                            anchors.fill: parent
                            anchors.margins: 5
                            state: page.presets[index]
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.choosePreset(index)
                        }
                    }
                }
            }

            Text {
                text: "A Select   B Back   Y Layout"
                color: page.dimColor
                font.family: "Segoe UI"
                font.pixelSize: 11
            }
        }

        // ── Choose Avatar menu, with the + entry at the bottom ─────────────
        Rectangle {
            id: avatarMenu
            property bool opened: false

            function toggle() { opened = !opened }
            function close() { opened = false }

            x: parent.width - width - 20
            y: 20 + 30 + 12 + 28 + 12 + 3 * 42 + 34
            width: 232
            height: avatarList.height + addRow.height + 12
            visible: opened
            radius: 8
            color: "#f20a1420"
            border.width: 1
            border.color: page.accentColor
            z: 50

            Column {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 0

                ListView {
                    id: avatarList
                    width: parent.width
                    height: page.presets.length * 30
                    clip: true
                    model: page.presets.length

                    delegate: Rectangle {
                        required property int index
                        width: avatarList.width
                        height: 30
                        radius: 4
                        color: rowPointer.containsMouse ? "#33465f" : "transparent"

                        AvatarThumb {
                            id: menuThumb
                            x: 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 24
                            state: page.presets[index]
                        }

                        Text {
                            anchors.left: menuThumb.right
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Avatar " + (index + 1)
                            color: index === page.presetIndex ? page.accentColor : page.textColor
                            font.family: "Segoe UI"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: rowPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.choosePreset(index)
                        }
                    }
                }

                // the new option
                Rectangle {
                    id: addRow
                    objectName: "addAvatarRow"
                    width: parent.width
                    height: 32
                    radius: 4
                    color: addPointer.containsMouse ? "#33465f" : "transparent"
                    border.width: 1
                    border.color: page.accentColor

                    Rectangle {
                        id: plusBarH
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -parent.width / 2 + 14
                        width: 12
                        height: 2
                        radius: 1
                        color: page.accentColor
                    }
                    Rectangle {
                        id: plusBarV
                        anchors.centerIn: plusBarH
                        width: 2
                        height: 12
                        radius: 1
                        color: page.accentColor
                    }

                    Text {
                        anchors.left: plusBarH.right
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "New Avatar…"
                        color: page.accentColor
                        font.family: "Segoe UI"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: addPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.editAvatar()
                    }
                }
            }
        }
    }

    // ── the editor, opened from the + row ──────────────────────────────────
    AvatarEditorPage {
        id: editorPage
        anchors.fill: parent
        gamerTag: page.profileName
        accentColor: page.accentColor
        accentInkColor: page.accentInkColor
        onAccepted: function (state) { page.storeAvatar(state) }
    }

    Keys.onPressed: function (event) {
        if (avatarMenu.opened) {
            avatarMenu.close()
            event.accepted = true
            return
        }
        if (editorPage.opened)
            return
        if (typeof api !== "undefined" && api.keys && api.keys.isCancel(event)) {
            event.accepted = true
        }
    }
}
