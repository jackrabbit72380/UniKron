import QtQuick 2.15

// The avatar editor.
//
// Point `assetsFolder` at a directory of category folders and it works out
// everything else by itself: each folder is a category, its images are the
// items, and a numeric prefix on the folder name is the layer order.
//
//   assets/10_body/      body_light.png ...
//   assets/20_pants/     jeans_indigo.png, shorts_khaki.png ...
//   assets/40_shirt/     tee_blue.png ...
//
// The folder contents come from AssetIndex.qml, which avatar_tools/
// watch_art.ps1 rewrites whenever the art folders change (install_watcher.bat
// starts it at login): Qt.labs.folderlistmodel is not part of the Pegasus
// builds, so nothing can list a directory at runtime. Add art, press F5.
// Folders whose name starts with _ or . are skipped, which is where the
// editor's own chrome lives, and a numeric prefix on the folder name is the
// layer order. Every drawing uses the same 512x768 canvas, so items never need
// position data.
Item {
    id: root

    AssetIndex { id: assetIndex }

    Style { id: style }

    // ---- what the host can set -------------------------------------------
    property url assetsFolder: Qt.resolvedUrl("assets/")
    property string gamerTag: "Player"
    // The original editor's own wording for this screen: the string table of
    // scnEditor in avatareditor.xex holds exactly this sentence.
    property string title: "Choose an avatar as a starting point"

    // The one colour the chrome takes from its host, so the editor can sit in
    // another theme's palette; items and the stage are unaffected.
    property color accentColor: style.accent
    property color accentInkColor: style.inkOnCard

    // category id -> chosen image file name, e.g. { "20_pants": "jeans_indigo.png" }
    property var state: ({})

    // ---- what the host can read ------------------------------------------
    property var categories: []          // [{ id, label, path, z }]
    property int categoryIndex: 0
    readonly property var currentCategory:
        categoryIndex >= 0 && categoryIndex < categories.length ? categories[categoryIndex] : null
    readonly property var layers: _layers
    readonly property var bodyCategory: categories.length > 0 ? categories[0] : null

    signal saveRequested(var state)
    signal portraitReady(var grabResult)
    signal backRequested()

    // Authored size of the original closet (avatareditor.xex, scnEditor DATA
    // stores 960x720); the page scales this whole item to the window.
    implicitWidth: 960
    implicitHeight: 720
    focus: true

    property var _layers: []
    property int _layerVersion: 0

    // ---- discovery -------------------------------------------------------
    // Nothing here reads a directory: Qt.labs.folderlistmodel is not part of
    // the Pegasus builds and QML has no other way to list a folder, so the
    // contents of assets/ ship as data in AssetIndex.qml.

    ListModel { id: items }

    function rebuildCategories() {
        var list = []
        for (var i = 0; i < assetIndex.folders.length; ++i) {
            var name = assetIndex.folders[i].id
            if (!name || name.charAt(0) === "." || name.charAt(0) === "_")
                continue
            list.push({
                id: name,
                label: style.titleCase(style.cleanFolderName(name)),
                path: style.dirUrl(root.assetsFolder, name),
                files: assetIndex.folders[i].files || [],
                z: style.layerOrder(name)
            })
        }
        list.sort(function (a, b) { return a.z - b.z })
        categories = list
        fillItems()
    }

    // The strip shows one category at a time. A ListModel keeps the tiles'
    // fileName / filePath roles exactly as they were with a folder listing.
    function fillItems() {
        items.clear()
        var cat = currentCategory
        if (!cat)
            return
        var files = cat.files || []
        for (var i = 0; i < files.length; ++i)
            items.append({ fileName: files[i], filePath: style.itemUrl(cat.path, files[i]) })
        fillBodyIfEmpty()
    }

    onCategoryIndexChanged: fillItems()
    onAssetsFolderChanged: rebuildCategories()

    function bodySource() {
        if (!bodyCategory)
            return ""
        var name = state[bodyCategory.id]
        return name ? style.itemUrl(bodyCategory.path, name) : ""
    }

    // ---- selection -------------------------------------------------------

    function setItem(categoryId, fileName) {
        var next = {}
        for (var key in state)
            next[key] = state[key]
        if (fileName) {
            next[categoryId] = fileName
        } else if (categoryId !== (bodyCategory ? bodyCategory.id : "")) {
            delete next[categoryId]
        }
        state = next
        rebuildLayers()
    }

    function selectCategory(index) {
        if (index < 0 || index >= categories.length || index === categoryIndex)
            return
        categoryIndex = index
    }

    function moveItem(delta) {
        if (!items.count)
            return
        var id = currentCategory ? currentCategory.id : ""
        var chosen = state[id] || ""
        var at = -1
        for (var i = 0; i < items.count; ++i) {
            if (items.get(i).fileName === chosen) {
                at = i
                break
            }
        }
        var next = at + delta
        if (next < -1)
            next = -1
        if (next > items.count - 1)
            next = items.count - 1
        setItem(id, next < 0 ? "" : items.get(next).fileName)
    }

    // The body is the base layer and is never optional, so pick one whenever
    // there is none: on first open, and again when a host re-opens the editor
    // with an empty state, which wipes whatever Component.onCompleted chose.
    // It reads bodyCategory.files, not the strip's model, so it works whichever
    // category happens to be showing.
    function fillBodyIfEmpty() {
        if (!bodyCategory || state[bodyCategory.id])
            return
        var files = bodyCategory.files || []
        for (var i = 0; i < files.length; ++i) {
            if (!files[i])
                continue
            setItem(bodyCategory.id, files[i])
            return
        }
    }

    function rebuildLayers() {
        var out = []
        for (var i = 0; i < categories.length; ++i) {
            var c = categories[i]
            var name = state[c.id]
            if (!name)
                continue
            out.push({ url: style.itemUrl(c.path, name), z: c.z, id: c.id })
        }
        out.sort(function (a, b) { return a.z - b.z })
        _layers = out
        _layerVersion++
    }

    onCategoriesChanged: rebuildLayers()

    // ---- whole-avatar actions -------------------------------------------

    function clearAll() {
        var next = {}
        if (bodyCategory && state[bodyCategory.id])
            next[bodyCategory.id] = state[bodyCategory.id]
        state = next
        rebuildLayers()
    }

    function randomize() {
        var next = {}
        for (var i = 0; i < categories.length; ++i) {
            var c = categories[i]
            if (bodyCategory && c.id === bodyCategory.id) {
                if (state[c.id])
                    next[c.id] = state[c.id]
                continue
            }
            var files = c.files || []
            if (!files.length)
                continue
            next[c.id] = files[Math.floor(Math.random() * files.length)]
        }
        state = next
        rebuildLayers()
    }

    function currentState() {
        var copy = {}
        for (var key in state)
            copy[key] = state[key]
        return copy
    }

    function loadState(saved) {
        var next = {}
        for (var key in saved)
            if (saved[key])
                next[key] = saved[key]
        state = next
        categoryIndex = 0
        fillBodyIfEmpty()
        rebuildLayers()
    }

    function save() {
        saveRequested(currentState())
    }

    function capturePortrait() {
        stage.capture(function (result) {
            if (result)
                portraitReady(result)
        })
    }

    // ---- input -----------------------------------------------------------

    Keys.onPressed: function (event) {
        // Inside Pegasus, controller and keyboard bindings are checked through
        // api.keys; outside it the raw keys below are used.
        if (typeof api !== "undefined" && api.keys) {
            if (api.keys.isCancel(event)) {
                backRequested()
                event.accepted = true
                return
            }
            if (api.keys.isAccept(event)) {
                event.accepted = true
                return
            }
        }

        var handled = true
        switch (event.key) {
        case Qt.Key_Right:   moveItem(1); break
        case Qt.Key_Left:    moveItem(-1); break
        case Qt.Key_Down:    selectCategory(categoryIndex + 1); break
        case Qt.Key_Up:      selectCategory(categoryIndex - 1); break
        case Qt.Key_Space:   randomize(); break
        case Qt.Key_S:       save(); break
        case Qt.Key_P:       capturePortrait(); break
        case Qt.Key_R:       clearAll(); break
        case Qt.Key_Escape:
        case Qt.Key_Backspace: backRequested(); break
        default:             handled = false
        }
        event.accepted = handled
    }

    // ---- chrome ----------------------------------------------------------

    // Artwork taken out of the original avatareditor.xex: the closet's dark
    // panel behind the avatar and the banner that sits under the item strip.
    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("assets/_ui/xex/closet_panel.png")
        fillMode: Image.PreserveAspectCrop
        smooth: true
        opacity: 0.5
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        anchors.topMargin: 16
        height: 40

        Text {
            id: headline
            text: root.title
            color: style.ink
            font.family: style.titleFamily
            font.pixelSize: 27
            font.weight: Font.DemiBold
            style: Text.Raised
            styleColor: "#40000000"
        }
    }

    Image {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: sourceSize.height * (width / sourceSize.width)
        source: Qt.resolvedUrl("assets/_ui/xex/banner_bottom.png")
        fillMode: Image.Stretch
        smooth: true
        opacity: 0.7
    }

    // The closet's own legend row. The A/B/X/Y art is the original editor's
    // (avatareditor.xex), and putting it down here also keeps our hints clear
    // of the button bar Pegasus draws along the bottom of the screen.
    Row {
        id: legend
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 26
        anchors.bottomMargin: 12
        spacing: 22

        // The source's control scheme, not a button bar: scnEditor registers an
        // A-button override and a refresh-random (X) override, and the legend
        // scene draws the A/B/X/Y glyphs. Each entry is also clickable, so a
        // mouse user keeps the same four actions.
        Repeater {
            model: [
                { glyph: "assets/_ui/xex/legend_a.png", label: "Save", action: "save" },
                { glyph: "assets/_ui/xex/legend_b.png", label: "Back", action: "back" },
                { glyph: "assets/_ui/xex/legend_x.png", label: "Randomize", action: "randomize" },
                { glyph: "assets/_ui/xex/legend_y.png", label: "Portrait", action: "portrait" }
            ]

            Item {
                width: entry.width
                height: entry.height

                Row {
                    id: entry
                    spacing: 8
                    opacity: hit.containsMouse ? 1.0 : 0.82
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    Image {
                        source: Qt.resolvedUrl(modelData.glyph)
                        height: 22
                        width: height
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                    Text {
                        text: modelData.label
                        color: style.ink
                        font.family: style.titleFamily
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: hit
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        switch (modelData.action) {
                        case "save":      root.save(); break
                        case "back":      root.backRequested(); break
                        case "randomize": root.randomize(); break
                        case "portrait":  root.capturePortrait(); break
                        }
                        root.forceActiveFocus()
                    }
                }
            }
        }
    }

    ItemStrip {
        id: strip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        anchors.bottom: legend.top
        anchors.bottomMargin: 10
        height: 172

        model: items
        bodySource: (root.bodyCategory && root.currentCategory
                     && root.currentCategory.id === root.bodyCategory.id)
                    ? "" : root.bodySource()
        allowNone: !(root.bodyCategory && root.currentCategory
                     && root.currentCategory.id === root.bodyCategory.id)
        selectedName: {
            void root._layerVersion
            var id = root.currentCategory ? root.currentCategory.id : ""
            return root.state[id] || ""
        }
        onPicked: function (fileName) {
            if (root.currentCategory)
                root.setItem(root.currentCategory.id, fileName)
            root.forceActiveFocus()
        }
    }

    CategoryRail {
        id: rail
        anchors.left: parent.left
        anchors.top: header.bottom
        anchors.bottom: strip.top
        anchors.leftMargin: 26
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        // Fixed, not left to implicitWidth: an implicit width can collapse to
        // the widest label and squeeze every pill on a small or odd host.
        width: Math.max(168, Math.min(232, Math.round(root.width * 0.15)))
        categories: root.categories
        currentIndex: root.categoryIndex
        accentColor: root.accentColor
        onActivated: root.selectCategory(index)
    }

    AvatarStage {
        id: stage
        anchors.left: rail.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 26
        anchors.top: header.bottom
        anchors.bottom: strip.top
        anchors.topMargin: 4
        anchors.bottomMargin: 6
        layers: root.layers
        emptyHint: root.categories.length === 0
                   ? "No item folders found in " + root.assetsFolder
                   : ""
    }


    Component.onCompleted: rebuildCategories()
}
