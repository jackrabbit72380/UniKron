import QtQuick 2.15

// Shared look and small helpers for the avatar editor.
//
// This used to be Style.js; a QML component keeps the same values but stays in
// the same language as everything that reads it. Put one inside a component
// with `Style { id: style }` and use `style.accent` and friends.
QtObject {
    // Real pack names for the art files that were baked from an asset.
    readonly property ItemNames itemNames: ItemNames {}

    readonly property string accent: "#a4d21c"
    readonly property string accentDeep: "#5f8a0c"
    readonly property string ink: "#ffffff"
    readonly property string inkDim: "#cbd8bc"
    readonly property string card: "#22ffffff"
    readonly property string cardHover: "#33ffffff"
    readonly property string cardActive: "#f2ffffff"
    readonly property string inkOnCard: "#1f2b0a"

    readonly property string titleFamily: "Segoe UI"

    // ---- the closet mirror, measured off the art and the bakes -------------
    //
    // Every plate and every turntable frame puts the soles at 0.932 of its own
    // canvas and the top of a full figure at 0.073 (alpha bounding boxes:
    // pack_plates/10_body/malebody.png is y 28..358 of 384, and
    // assets/3d/turntable/frame_00.png is y 52..626 of 672 - the two bakes agree
    // to a thousandth, which is what makes one set of numbers serve both stages).
    readonly property real soleFraction: 0.932
    readonly property real figureTopFraction: 0.073
    // closet_mirror_border.png is 512x512 and its transparent opening runs
    // y 65..446, i.e. 0.127..0.871 of the art. Both stages draw that art at
    // 1.12x the holder (anchors.margins -frame.width * 0.06), so the opening
    // lands at -0.06 + 0.127 * 1.12 = 0.082 and -0.06 + 0.871 * 1.12 = 0.915 here.
    readonly property real mirrorTop: 0.082
    readonly property real mirrorBottom: 0.915
    // The figure spans 0.859 of its canvas and the opening only 0.833, which is
    // why the head and the feet used to cross the frame rails: the avatar was
    // drawn at its baked size instead of being fitted to the mirror it stands in.
    // 98% of the opening leaves the head clear of the top rail and puts the soles
    // on the bottom one.
    readonly property real figureScale: Math.min(1.0,
        (mirrorBottom - mirrorTop) * 0.98 / (soleFraction - figureTopFraction))

    // A filesystem path turned into something an Image can load.
    function fileUrl(path) {
        var p = String(path).replace(/\\/g, "/")
        var url = p
        if (/^[A-Za-z]:\//.test(p))
            url = "file:///" + p
        else if (p.charAt(0) === "/")
            url = "file://" + p
        return encodeURI(url)
    }

    // "jeans_indigo.png" -> "Jeans Indigo"
    function itemLabel(fileName) {
        if (!fileName)
            return ""
        var n = String(fileName)
        var dot = n.lastIndexOf(".")
        if (dot > 0)
            n = n.substring(0, dot)
        // A wardrobe file named for a colour (tee_blue) was baked from a real
        // pack asset; show that asset's own name instead of the art stem.
        var real = itemNames.of(n)
        if (real !== "")
            return real
        n = n.replace(/[_\-]+/g, " ").replace(/\s+/g, " ").trim()
        return n.replace(/\b\w/g, function (c) { return c.toUpperCase() })
    }

    // "facial-hair" -> "Facial Hair"
    function titleCase(name) {
        return itemLabel(name)
    }

    // The rail title for a slot folder. Where the retail editor names the
    // button, its own wording wins over anything derived from the folder name -
    // these eight are the pairs avatar_tools/editor_categories.json read out of
    // the editor's XUI strings (button -> label -> theme folder), so "40_shirt"
    // is "Tops" and "50_hair" is "Hairstyles", not "Shirt" and "Hair".
    // Slots the 2008 scene has no button for keep the derived name rather than
    // borrowing a retail label that belongs to something else.
    readonly property var slotLabels: ({
        "10_body": "Skin Color and Body",
        "12_eyebrows": "Eyebrows",
        "15_face": "Eyes",
        "17_eye-shadow": "Eye Shadow",
        "20_pants": "Bottoms",
        "30_shoes": "Shoes",
        "40_shirt": "Tops",
        "45_facial-hair": "Facial Hair",
        "50_hair": "Hairstyles",
        "60_hat": "Headwear",
        "70_glasses": "Glasses",
        // The three the editor's XUI names separately for the 36 shape
        // overrides: nose, ears and faceshape.
        "71_nose": "Nose",
        "72_ears": "Ears",
        "73_head-shape": "Head Shape"
    })

    function slotLabel(folderName) {
        var key = String(folderName)
        return slotLabels[key] !== undefined ? slotLabels[key] : titleCase(cleanFolderName(key))
    }

    // Layer order from the folder name: "20_pants" -> 20, "pants" -> 1000
    function layerOrder(folderName) {
        var m = /^(\d+)[\-_ ]+(.+)$/.exec(String(folderName))
        return m ? parseInt(m[1], 10) : 1000
    }

    // Folder name without its ordering prefix.
    function cleanFolderName(folderName) {
        var m = /^(\d+)[\-_ ]+(.+)$/.exec(String(folderName))
        return m ? m[2] : String(folderName)
    }

    // Directory URL for one category folder, given the editor's assetsFolder.
    function dirUrl(assetsFolder, folderName) {
        return String(assetsFolder).replace(/\/+$/, "") + "/" + encodeURIComponent(folderName)
    }

    // Full URL for one item inside a category folder.
    function itemUrl(dir, fileName) {
        return String(dir).replace(/\/+$/, "") + "/" + encodeURI(fileName)
    }
}
