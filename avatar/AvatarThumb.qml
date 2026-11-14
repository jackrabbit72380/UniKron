import QtQuick 2.15

// A small layered preview of a saved avatar, for grids and profile cards.
//
//   AvatarThumb { state: { "10_body": "body_tan.png", "20_pants": "jeans_indigo.png" } }
//
// It reads the same assets folder as the editor and draws whatever the state
// names, in layer order, so a thumbnail always matches the editor exactly.
Item {
    id: thumb

    AssetIndex { id: assetIndex }

    Style { id: style }

    property var state: ({})
    property url assetsFolder: Qt.resolvedUrl("assets/")
    property int sourceHeight: 420

    property var categories: []
    property var layers: []

    // Same data the editor uses; see AssetIndex.qml.
    function rebuildCategories() {
        var list = []
        for (var i = 0; i < assetIndex.folders.length; ++i) {
            var name = assetIndex.folders[i].id
            if (!name || name.charAt(0) === "." || name.charAt(0) === "_")
                continue
            list.push({ id: name, path: style.dirUrl(thumb.assetsFolder, name), z: style.layerOrder(name) })
        }
        list.sort(function (a, b) { return a.z - b.z })
        categories = list
    }

    Component.onCompleted: rebuildCategories()
    onAssetsFolderChanged: rebuildCategories()

    function rebuildLayers() {
        var out = []
        for (var i = 0; i < categories.length; ++i) {
            var c = categories[i]
            var name = state[c.id]
            if (!name)
                continue
            out.push({ url: style.itemUrl(c.path, name), z: c.z })
        }
        out.sort(function (a, b) { return a.z - b.z })
        layers = out
    }

    onCategoriesChanged: rebuildLayers()
    onStateChanged: rebuildLayers()

    Repeater {
        model: thumb.layers

        delegate: Image {
            required property var modelData

            anchors.fill: parent
            z: modelData.z
            source: modelData.url
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            sourceSize.height: thumb.sourceHeight
        }
    }
}
