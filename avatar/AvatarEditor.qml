import QtQuick 2.15
import Qt.labs.folderlistmodel 2.15
import "Style.js" as S

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
// Drop a new PNG into a folder and it shows up the next time the folder is
// read; add a folder and it becomes a new category. Folders whose name starts
// with _ or . are skipped, which is where the editor's own chrome lives.
// Every drawing uses the same 512x768 canvas, so items never need position
// data.
Item {
    id: root

    // ---- what the host can set -------------------------------------------
    property url assetsFolder: Qt.resolvedUrl("assets/")
    property string gamerTag: "Player"
    property string title: "Avatar Editor"
    property var itemFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.svg"]

    // The one colour the chrome takes from its host, so the editor can sit in
    // another theme's palette; items and the stage are unaffected.
    property color accentColor: S.accent
    property color accentInkColor: S.inkOnCard

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

    implicitWidth: 1180
    implicitHeight: 700
    focus: true

    property var _layers: []
    property var _catalog: ({})
    property int _catalogVersion: 0
    property int _layerVersion: 0

    // ---- discovery -------------------------------------------------------

    FolderListModel {
        id: dirs
        folder: root.assetsFolder
        showDirs: true
        showFiles: false
        sortField: FolderListModel.Name
        onCountChanged: root.rebuildCategories()
        onStatusChanged: root.rebuildCategories()
    }

    // One listing per category, so randomize can reach items in folders the
    // strip is not showing right now.
    Component {
        id: categoryScan
        FolderListModel {
            showDirs: false
            showFiles: true
            sortField: FolderListModel.Name
        }
    }

    Repeater {
        model: root.categories
        delegate: Loader {
            required property var modelData
            sourceComponent: categoryScan
            onLoaded: {
                item.folder = S.fileUrl(modelData.path)
                item.nameFilters = root.itemFilters
                root._catalog[modelData.id] = item
                root._catalogVersion++
            }
        }
    }

    // The category the strip is showing.
    FolderListModel {
        id: items
        folder: root.currentCategory ? S.fileUrl(root.currentCategory.path) : ""
        showDirs: false
        showFiles: true
        nameFilters: root.itemFilters
        sortField: FolderListModel.Name
        onCountChanged: root.fillBodyIfEmpty()
        onStatusChanged: root.fillBodyIfEmpty()
    }

    function rebuildCategories() {
        var list = []
        for (var i = 0; i < dirs.count; ++i) {
            var name = dirs.get(i, "fileName")
            var path = dirs.get(i, "filePath")
            if (!name || !path || name.charAt(0) === "." || name.charAt(0) === "_")
                continue
            list.push({
                id: name,
                label: S.titleCase(S.cleanFolderName(name)),
                path: String(path),
                z: S.layerOrder(name)
            })
        }
        list.sort(function (a, b) { return a.z - b.z })
        categories = list
        fillBodyIfEmpty()
    }

    function bodySource() {
        if (!bodyCategory)
            return ""
        var name = state[bodyCategory.id]
        return name ? S.fileUrl(bodyCategory.path + "/" + name) : ""
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
            if (items.get(i, "fileName") === chosen) {
                at = i
                break
            }
        }
        var next = at + delta
        if (next < -1)
            next = -1
        if (next > items.count - 1)
            next = items.count - 1
        setItem(id, next < 0 ? "" : items.get(next, "fileName"))
    }

    function fillBodyIfEmpty() {
        if (!bodyCategory || state[bodyCategory.id])
            return
        if (!currentCategory || currentCategory.id !== bodyCategory.id || items.count === 0)
            return
        var first = ""
        for (var i = 0; i < items.count; ++i) {
            if (String(items.get(i, "filePath")) === "")
                continue
            first = items.get(i, "fileName")
            break
        }
        if (first)
            setItem(bodyCategory.id, first)
    }

    function rebuildLayers() {
        var out = []
        for (var i = 0; i < categories.length; ++i) {
            var c = categories[i]
            var name = state[c.id]
            if (!name)
                continue
            out.push({ url: S.fileUrl(c.path + "/" + name), z: c.z, id: c.id })
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
            var model = _catalog[c.id]
            if (!model || model.count === 0)
                continue
            next[c.id] = model.get(Math.floor(Math.random() * model.count), "fileName")
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

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        anchors.topMargin: 16
        height: 58

        Text {
            id: headline
            text: root.title
            color: S.ink
            font.family: S.titleFamily
            font.pixelSize: 27
            font.weight: Font.DemiBold
            style: Text.Raised
            styleColor: "#40000000"
        }

        Text {
            id: subline
            anchors.top: headline.bottom
            anchors.topMargin: 2
            text: root.gamerTag + "  \u00b7  " + root.categories.length + " categories"
            color: S.inkDim
            font.family: S.titleFamily
            font.pixelSize: 13
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            EditorButton {
                label: "Randomize"
                accentColor: root.accentColor; accentInkColor: root.accentInkColor
                onClicked: root.randomize()
            }
            EditorButton {
                label: "Reset"
                accentColor: root.accentColor; accentInkColor: root.accentInkColor
                onClicked: root.clearAll()
            }
            EditorButton {
                label: "Save"
                accentColor: root.accentColor; accentInkColor: root.accentInkColor
                onClicked: root.save()
            }
            EditorButton {
                label: "Portrait"; primary: true
                accentColor: root.accentColor; accentInkColor: root.accentInkColor
                onClicked: root.capturePortrait()
            }
        }
    }

    ItemStrip {
        id: strip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        anchors.bottomMargin: 16
        height: 196

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

    Text {
        anchors.horizontalCenter: stage.horizontalCenter
        anchors.bottom: strip.top
        anchors.bottomMargin: 2
        text: "\u2190 \u2192 item    \u2191 \u2193 category    space randomize    S save    P portrait    R reset"
        color: S.inkDim
        opacity: 0.65
        font.family: S.titleFamily
        font.pixelSize: 11
    }

    Component.onCompleted: rebuildCategories()
}
