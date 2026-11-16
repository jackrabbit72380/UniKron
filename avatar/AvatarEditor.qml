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
    // The pack's own items: one render per real AvatarAssetPack asset, written by
    // avatar_tools/bake_pack_thumbs.py together with this index.
    PackIndex { id: packIndex }
    PackPlates { id: packPlates }

    Style { id: style }

    // ---- what the host can set -------------------------------------------
    property url assetsFolder: Qt.resolvedUrl("assets/")
    // Where the pack-derived thumbnails live, and whether the wardrobe browses
    // them instead of the hand-drawn art in assets/. Off by default: the drawn art
    // is what the 3D wardrobe is keyed against.
    property url packArtFolder: Qt.resolvedUrl("pack_art/")
    // Aligned 2D plates for the pack's items, baked by bake_pack_plates.py: one
    // render per item through the body's own frame, so layers stack into a single
    // avatar instead of each item being framed on its own.
    property url packPlateFolder: Qt.resolvedUrl("pack_plates/")
    property bool usePackArt: false
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

    // ---- screens ---------------------------------------------------------
    // The original editor opens on a menu: the avatar on the left and five
    // plates down the right — Change My Features, Change My Clothes, Gamer
    // Picture, Start Over, Save and Exit — with the selected plate in lime.
    // "Change My Clothes" opens the closet. The plate art is the editor's own,
    // taken out of avatareditor.xex as selected/unselected pairs, with the
    // icon already baked into the left side of each plate.
    property string screen: "menu"

    readonly property var menuItems: [
        { key: "features", label: "Change My Features" },
        { key: "clothes",  label: "Change My Clothes" },
        { key: "picture",  label: "Gamer Picture" },
        { key: "start",    label: "Start Over" },
        { key: "exit",     label: "Save and Exit" }
    ]
    property int menuIndex: 1

    // "Change My Features" is its own screen in the source: six 360x200 tiles,
    // each a rendered close-up of the thing you are changing, lime when picked
    // and grey-blue when not. The art is the editor's own out of the XEX.
    readonly property var featureItems: [
        { key: "earrings", label: "Earrings" },
        { key: "eyes",     label: "Eyes" },
        { key: "facial",   label: "Facial Hair" },
        { key: "skin",     label: "Skin" },
        { key: "glasses",  label: "Glasses" },
        { key: "lips",     label: "Lips" }
    ]
    property int featureIndex: 0

    // "Choose an avatar as a starting point": scnEditor registers ten avatar
    // buttons (AvatarButton1..10) and a refresh-random override, and its VECT
    // chunk puts nine of them on one row at 62.39, 152.28, 242.17, 332.06,
    // 420.94, 510.83, 600.72, 690.61 and 780.50 — 89.89 apart on the 960-wide
    // surface, with the tenth slot at the end. That row is what this screen is.
    property var presets: []
    property int chooseIndex: 0

    readonly property var chooseSlots: [
        62.39, 152.28, 242.17, 332.06, 420.94, 510.83, 600.72, 690.61, 780.50, 870.39
    ]

    function rebuildPresets() {
        var out = []
        var body = bodyCategory ? (bodyCategory.files || []) : []
        for (var i = 0; i < chooseSlots.length; ++i) {
            var preset = {}
            if (body.length)
                preset[bodyCategory.id] = body[i % body.length]
            // A few extra layers so the ten do not read as the same avatar.
            for (var c = 1; c < categories.length; ++c) {
                var files = categories[c].files || []
                if (files.length && Math.random() < 0.45)
                    preset[categories[c].id] = files[Math.floor(Math.random() * files.length)]
            }
            out.push(preset)
        }
        presets = out
    }

    function applyPreset(index) {
        var preset = presets[index]
        if (!preset)
            return
        var next = {}
        for (var key in preset)
            next[key] = preset[key]
        state = next
        rebuildLayers()
        setScreen("menu")
    }

    // The source draws one legend per screen: the menu offers A Select (the
    // preview screenshot shows exactly that), the closet needs its four.
    readonly property var legendModel: screen === "closet"
        ? [ { glyph: "assets/_ui/xex/legend_a.png", label: "Save", action: "save" },
            { glyph: "assets/_ui/xex/legend_b.png", label: "Back", action: "back" },
            { glyph: "assets/_ui/xex/legend_x.png", label: "Randomize", action: "randomize" },
            { glyph: "assets/_ui/xex/legend_y.png", label: "Portrait", action: "portrait" } ]
        : (screen === "choose"
           ? [ { glyph: "assets/_ui/xex/legend_a.png", label: "Select", action: "menuSelect" },
               { glyph: "assets/_ui/xex/legend_b.png", label: "Back", action: "back" },
               { glyph: "assets/_ui/xex/legend_x.png", label: "Refresh", action: "presets" } ]
           : [ { glyph: "assets/_ui/xex/legend_a.png", label: "Select", action: "menuSelect" },
               { glyph: "assets/_ui/xex/legend_b.png", label: "Back", action: "back" } ])

    function setScreen(name) { screen = name }

    // A feature tile only opens something when a folder covers it; the rest are
    // the source's tiles with no items to show, which is what it does too when
    // the player owns nothing.
    function categoryIndexFor(label) {
        for (var i = 0; i < categories.length; ++i) {
            if (String(categories[i].label).toLowerCase() === String(label).toLowerCase())
                return i
        }
        return -1
    }

    function activateFeature(index) {
        var item = featureItems[index]
        if (!item)
            return
        var at = categoryIndexFor(item.label)
        if (at < 0)
            return
        categoryIndex = at
        setScreen("closet")
    }

    function activateMenuItem(index) {
        var item = menuItems[index]
        if (!item)
            return
        switch (item.key) {
        case "features": setScreen("features"); break
        case "clothes":  setScreen("closet"); break
        case "picture": capturePortrait(); break
        case "start":   clearAll(); break
        case "exit":    save(); break
        }
    }
    // The hairstyle picked in the closet picks the baked 3D set: bake_outfits.py
    // writes one folder per file in assets/50_hair, named after that file.
    readonly property string hairVariant: {
        for (var i = 0; i < categories.length; ++i) {
            var c = categories[i]
            // 45_facial-hair also contains "hair": only the hairstyle category
            // names a baked set.
            if (!c || !c.id || c.id.indexOf("hair") < 0 || c.id.indexOf("facial") >= 0)
                continue
            var file = state[c.id] || ""
            if (file !== "")
                return file.replace(/\.png$/i, "")
        }
        return ""
    }

    // Every wardrobe item that has its own baked turntable, and the folder its
    // set lives in: bake_items.py writes one folder per entry in
    // avatar_tools/items_3d.json as assets/3d/<kind>/<stem>.
    readonly property var bakedItems: ({
        "tee_blue": "shirts", "tee_white": "shirts", "tee_red": "shirts", "tee_black": "shirts",
        "hoodie_grey": "shirts", "hoodie_navy": "shirts", "hoodie_olive": "shirts", "hoodie_plum": "shirts",
        "jersey_green": "shirts", "jersey_red": "shirts", "jersey_blue": "shirts", "jersey_white": "shirts",
        "tank_white": "shirts", "tank_black": "shirts", "tank_blue": "shirts", "tank_pink": "shirts",
        "coat_navy": "shirts", "coat_grey": "shirts", "coat_brown": "shirts", "coat_olive": "shirts",
        "jeans_indigo": "pants", "jeans_black": "pants", "jeans_grey": "pants",
        "joggers_black": "pants", "joggers_grey": "pants", "joggers_navy": "pants",
        "shorts_khaki": "pants", "shorts_black": "pants", "shorts_denim": "pants",
        "cargo_olive": "pants", "cargo_brown": "pants", "cargo_grey": "pants",
        "sneakers_white": "shoes", "sneakers_black": "shoes", "sneakers_navy": "shoes",
        "sneakers_green": "shoes", "trainers_red": "shoes",
        "boots_brown": "shoes", "boots_black": "shoes", "boots_tan": "shoes"
    })

    // The category the player last changed in the closet, so 3D shows the set for
    // the item they just picked rather than for whichever set sorts first.
    property string lastItemCategory: ""

    function categoryIdMatching(term) {
        for (var i = 0; i < categories.length; ++i) {
            var c = categories[i]
            if (!c || !c.id || c.id.indexOf(term) < 0 || c.id.indexOf("facial") >= 0)
                continue
            return c.id
        }
        return ""
    }

    // The baked set for whatever that category currently holds, or "" when there
    // is none - including the seeded default, which the stock bake already shows.
    function bakedSet(categoryId) {
        if (!categoryId)
            return ""
        // The body plates and face decals are the base layer and the skin, not
        // items: no set is baked for them, and picking one here would send the
        // stage to a folder that does not exist while a real garment is worn.
        if (categoryId.indexOf("body") >= 0 || categoryId.indexOf("face") >= 0)
            return ""
        var file = state[categoryId] || ""
        if (file === "")
            return ""
        for (var term in seedPicks) {
            if (categoryId.indexOf(term) >= 0 && seedPicks[term] === file)
                return ""
        }
        var stem = file.replace(/\.png$/i, "")
        var kind = bakedItems[stem]
        if (kind)
            return kind + "/" + stem
        // The pack's own items are baked as plain turntables under their slug
        // (bake_pack_turntables.py), not in items_3d.json. The stage probes for
        // frame_00 and falls back to the default set when a folder is missing,
        // so naming one here is safe even for the categories not baked yet.
        if (usePackArt)
            return "turntable/" + stem
        return ""
    }

    // Which baked folder the 3D stage plays, relative to assets/3d/. The item
    // sets carry the default hairstyle, so they only apply while the player keeps
    // that hair; any other hairstyle falls back to its own turntable.
    readonly property string stageVariant: {
        var keepHair = hairVariant === "" || hairVariant === defaultHairStem
        if (keepHair) {
            var picked = bakedSet(lastItemCategory)
            if (picked !== "")
                return picked
            var order = ["shirt", "pants", "shoes"]
            for (var i = 0; i < order.length; ++i) {
                picked = bakedSet(categoryIdMatching(order[i]))
                if (picked !== "")
                    return picked
            }
        }
        // No trailing slash: the stage appends one, and "turntable//frame_00"
        // only works by luck of Qt normalising the path.
        return hairVariant === "" ? "turntable" : "turntable/" + hairVariant
    }

    // The hairstyle seedOutfit fills in. bake_animated.py bakes the animated 3D
    // set for exactly this look, so those frames are only the right hair while
    // the player wears it (or has no hair picked at all).
    readonly property string defaultHairStem: {
        for (var i = 0; i < categories.length; ++i) {
            var c = categories[i]
            if (!c || !c.files || !c.files.length)
                continue
            if (c.id.indexOf("hair") < 0 || c.id.indexOf("facial") >= 0)
                continue
            // The stock hairstyle seedOutfit picks, which is also the one
            // bake_animated.py bakes the animated set in. It has to be the seed
            // for the mode in use, or pack mode would compare the hair it seeded
            // against a drawn hairstyle and never match. Falling back to the
            // first file keeps this working if that art is ever removed.
            var stem = (usePackArt ? packSeedPicks : seedPicks)["hair"]
            if (stem && c.files.indexOf(stem) >= 0)
                return stem.replace(/\.png$/i, "")
            return c.files[0].replace(/\.png$/i, "")
        }
        return ""
    }

    readonly property var currentCategory:
        categoryIndex >= 0 && categoryIndex < categories.length ? categories[categoryIndex] : null
    readonly property var layers: _layers
    readonly property var bodyCategory: categories.length > 0 ? categories[0] : null

    // 2D stacks the source's own art layers; 3D plays a baked turntable of the
    // real mesh (see AvatarStage3D and avatar_tools/bake_turntable.py).
    property string renderMode: "2d"

    // avatareditor.toml's model_shadows, which the source ships switched on: the
    // soft shadow the avatar stands on. Kept in api.memory so it survives a
    // reopen, the way the original keeps its config between starts.
    property bool modelShadows: true

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

    // The pack holds no body textures and no skin tones, so the body layer always
    // comes from the drawn plates even when the wardrobe browses the pack.
    function drawnBodyFolder() {
        for (var i = 0; i < assetIndex.folders.length; ++i) {
            if (assetIndex.folders[i].id === "10_body")
                return { path: style.dirUrl(root.assetsFolder, "10_body"),
                         files: assetIndex.folders[i].files || [] }
        }
        return null
    }

    function rebuildCategories() {
        var list = []
        var source = root.usePackArt ? packIndex.folders : assetIndex.folders
        var base = root.usePackArt ? root.packArtFolder : root.assetsFolder
        for (var i = 0; i < source.length; ++i) {
            var name = source[i].id
            if (!name || name.charAt(0) === "." || name.charAt(0) === "_")
                continue
            var folderPath = style.dirUrl(base, name)
            var folderFiles = source[i].files || []
            // The drawn body plates stand in for the pack's missing body art. Once
            // the pack has its own plates they win, because those are rendered
            // through the same frame as every item plate.
            if (root.usePackArt && name === "10_body") {
                if (hasPlates("10_body")) {
                    // Plate names have to be the ones the strip offers, or the
                    // chosen body is not in its own model and nothing highlights.
                    folderPath = style.dirUrl(root.packPlateFolder, name)
                    folderFiles = plateFiles(name)
                } else {
                    var drawn = drawnBodyFolder()
                    if (drawn) {
                        folderPath = drawn.path
                        folderFiles = drawn.files
                    }
                }
            }
            list.push({
                id: name,
                label: style.titleCase(style.cleanFolderName(name)),
                path: folderPath,
                files: folderFiles,
                z: style.layerOrder(name)
            })
        }
        list.sort(function (a, b) { return a.z - b.z })
        categories = list
        pruneState()
        seedOutfit()
        fillItems()
    }

    // Switching to the pack's items leaves picks behind that only exist as drawn
    // art ("hair_short_brown.png"), which would then be requested from
    // pack_art/ and fail. Drop those, but only where the category still exists,
    // so a wardrobe saved in one mode survives a round trip through the other.
    function pruneState() {
        var next = {}
        var changed = false
        for (var key in state) {
            var keep = state[key]
            for (var i = 0; i < categories.length; ++i) {
                if (categories[i].id !== key)
                    continue
                if ((categories[i].files || []).indexOf(keep) < 0)
                    keep = ""
                break
            }
            if (keep)
                next[key] = keep
            else
                changed = true
        }
        if (changed)
            state = next
    }

    // A fresh avatar wears a stock outfit, the way the dashboard's does: without
    // this the first visit shows a player standing in nothing but a body layer
    // until they pick every garment by hand. Only empty slots are filled, so a
    // saved wardrobe is never overwritten.
    // The stock look the 3D sets are baked in, so a fresh avatar reads the same
    // in both modes instead of the 2D wardrobe opening on one outfit and the 3D
    // turntable wearing another.
    // The stock look the 3D bake wears, so both modes open as the same avatar:
    // Avatar6400's outfit (jacket, flares, trainers), tinted as in
    // avatar_tools/bake_avatar.py.
    readonly property var seedPicks: ({
        "shirt": "coat_navy.png",
        "pants": "jeans_indigo.png",
        "shoes": "sneakers_black.png",
        "hair": "hair_short_brown.png"
    })

    // The same look in the pack's own items: Avatar6400's descriptor, read by
    // avatar_tools/avatar_desc.py. Its look block names MaleBody, Head, Short
    // with Left Curls (Hat), Jacket with Sweater, Male Flower Print Flares and
    // Grunge Trainers - so a fresh pack avatar dresses the way the console's
    // sample avatar is dressed rather than in the first file of each category.
    // The hairstyle is the one exception: Avatar6400 wears `Short with Left
    // Curls (Hat)`, but that asset is a 102-vertex shell that sits inside the
    // skull, so it renders as a bald head (see CATALOG.md). The stock style is
    // used instead until that asset draws properly.
    readonly property var packSeedPicks: ({
        "shirt": "jacket-with-sweater.png",
        "pants": "male-flower-print-flares.png",
        "shoes": "grunge-trainers.png",
        "hair": "left-parting.png"
    })

    function seedOutfit() {
        var picks = usePackArt ? packSeedPicks : seedPicks
        var wanted = ["shirt", "pants", "shoes", "hair"]
        var next = {}
        var changed = false
        for (var held in state)
            next[held] = state[held]
        for (var i = 0; i < categories.length; ++i) {
            var c = categories[i]
            if (!c || !c.files || !c.files.length)
                continue
            for (var w = 0; w < wanted.length; ++w) {
                // 45_facial-hair is not the hairstyle category.
                if (c.id.indexOf(wanted[w]) < 0 || c.id.indexOf("facial") >= 0)
                    continue
                if (!next[c.id]) {
                    var pick = picks[wanted[w]]
                    next[c.id] = c.files.indexOf(pick) >= 0 ? pick : c.files[0]
                    changed = true
                }
            }
        }
        if (changed)
            state = next
    }

    // The strip shows one category at a time. A ListModel keeps the tiles'
    // fileName / filePath roles exactly as they were with a folder listing.
    function fillItems() {
        items.clear()
        // Read the category straight off the array, not through currentCategory:
        // this runs from the categoryIndex change handler, where that binding has
        // not been re-evaluated yet, so it would still hold the previous category
        // and leave the strip showing the wrong items.
        var cat = (categoryIndex >= 0 && categoryIndex < categories.length)
                  ? categories[categoryIndex] : null
        if (!cat)
            return
        var files = cat.files || []
        for (var i = 0; i < files.length; ++i)
            items.append({ fileName: files[i], filePath: style.itemUrl(cat.path, files[i]) })
        fillBodyIfEmpty()
    }

    onCategoryIndexChanged: fillItems()
    onAssetsFolderChanged: rebuildCategories()
    onPackArtFolderChanged: rebuildCategories()
    onUsePackArtChanged: rebuildCategories()

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
        // Which set the 3D stage should show: the closet only has one baked
        // turntable per item, so it follows the piece the player just changed.
        lastItemCategory = categoryId
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
        // Every baked plate and set is posed on the male body, so that is the one
        // to open with when the body itself comes from a plate.
        if (usePackArt && files.indexOf("malebody.png") >= 0) {
            setItem(bodyCategory.id, "malebody.png")
            return
        }
        for (var i = 0; i < files.length; ++i) {
            if (!files[i])
                continue
            setItem(bodyCategory.id, files[i])
            return
        }
    }

    // The pack's facial hair and face paint are UV sheets (128x64, 128x128), not
    // body plates: the stage fits every layer to the whole frame, so one of these
    // would stretch into a blurry decal over the entire avatar. The drawn art
    // for the same categories is real plate art (1024x1536), so this only
    // applies to pack mode. Where the sheets sit on the face is still unknown -
    // see avatar_tools/DECALS.md.
    function isPackDecal(id) {
        return id === "15_face" || id === "16_face-paint" || id === "45_facial-hair"
    }

    function plateFiles(categoryId) {
        for (var i = 0; i < packPlates.folders.length; ++i) {
            if (packPlates.folders[i].id === categoryId)
                return packPlates.folders[i].files || []
        }
        return []
    }

    function hasPlates(categoryId) {
        for (var i = 0; i < packPlates.folders.length; ++i) {
            var f = packPlates.folders[i]
            if (f.id === categoryId && (f.files || []).length > 0)
                return true
        }
        return false
    }

    // A plate for this item, if one was baked. Empty means there is none, and the
    // strip's own art has to serve.
    function plateUrl(categoryId, name) {
        for (var i = 0; i < packPlates.folders.length; ++i) {
            if (packPlates.folders[i].id !== categoryId)
                continue
            if ((packPlates.folders[i].files || []).indexOf(name) >= 0)
                return style.itemUrl(style.dirUrl(root.packPlateFolder, categoryId), name)
            return ""
        }
        return ""
    }

    function rebuildLayers() {
        var out = []
        for (var i = 0; i < categories.length; ++i) {
            var c = categories[i]
            var name = state[c.id]
            if (!name)
                continue
            if (usePackArt && isPackDecal(c.id))
                continue
            var url = style.itemUrl(c.path, name)
            if (usePackArt) {
                var plate = plateUrl(c.id, name)
                if (plate !== "")
                    url = plate
            }
            out.push({ url: url, z: c.z, id: c.id })
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
        var hadAvatar = false
        for (var k in next)
            if (next[k])
                hadAvatar = true
        state = next
        categoryIndex = 0
        // loadState runs after rebuildCategories, so seedOutfit has already done
        // its pass - but this assignment may have just wiped it with a host's
        // empty state. Re-seed only in that case, so a fresh avatar opens on the
        // choose screen already dressed like the 3D turntable, and a saved
        // wardrobe is never touched.
        if (!hadAvatar)
            seedOutfit()
        fillBodyIfEmpty()
        rebuildLayers()
        // A player with nothing saved is choosing a starting point, which is
        // the screen the original opens on the first time.
        if (hadAvatar) {
            screen = "menu"
        } else {
            rebuildPresets()
            chooseIndex = 0
            screen = "choose"
        }
    }

    function save() {
        saveRequested(currentState())
    }

    function capturePortrait() {
        // Whichever view is live is the one worth saving; with no baked frames
        // the 3D stage has nothing to grab, so 2D still answers.
        var target = (renderMode === "3d" && stage3d.available) ? stage3d : stage
        target.capture(function (result) {
            if (result)
                portraitReady(result)
        })
    }

    // ---- input -----------------------------------------------------------

    Keys.onPressed: function (event) {
        // 3 toggles the render mode on every screen that shows the avatar.
        if (event.key === Qt.Key_3 && screen !== "choose") {
            renderMode = renderMode === "3d" ? "2d" : "3d"
            event.accepted = true
            return
        }

        // The menu is its own screen: up/down move between the five plates and
        // accept activates one. In the closet, cancel goes back to the menu.
        if (screen === "choose") {
            var chit = true
            switch (event.key) {
            case Qt.Key_Right: chooseIndex = Math.min(presets.length - 1, chooseIndex + 1); break
            case Qt.Key_Left:  chooseIndex = Math.max(0, chooseIndex - 1); break
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space: applyPreset(chooseIndex); break
            case Qt.Key_X:     rebuildPresets(); break
            case Qt.Key_Escape:
            case Qt.Key_Backspace: setScreen("menu"); break
            default: chit = false
            }
            event.accepted = chit
            return
        }

        if (screen === "features") {
            var fhit = true
            switch (event.key) {
            case Qt.Key_Right: featureIndex = Math.min(featureItems.length - 1, featureIndex + 1); break
            case Qt.Key_Left:  featureIndex = Math.max(0, featureIndex - 1); break
            case Qt.Key_Down:  featureIndex = Math.min(featureItems.length - 1, featureIndex + 2); break
            case Qt.Key_Up:    featureIndex = Math.max(0, featureIndex - 2); break
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space: activateFeature(featureIndex); break
            case Qt.Key_Escape:
            case Qt.Key_Backspace: setScreen("menu"); break
            default: fhit = false
            }
            event.accepted = fhit
            return
        }

        if (screen === "menu") {
            var hit = true
            switch (event.key) {
            case Qt.Key_Down:
                menuIndex = Math.min(menuItems.length - 1, menuIndex + 1); break
            case Qt.Key_Up:
                menuIndex = Math.max(0, menuIndex - 1); break
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                activateMenuItem(menuIndex); break
            case Qt.Key_Escape:
            case Qt.Key_Backspace:
                backRequested(); break
            default:
                hit = false
            }
            event.accepted = hit
            return
        }

        // Inside Pegasus, controller and keyboard bindings are checked through
        // api.keys; outside it the raw keys below are used.
        if (typeof api !== "undefined" && api.keys) {
            if (api.keys.isCancel(event)) {
                setScreen("menu")
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
        case Qt.Key_Backspace: setScreen("menu"); break
        default:             handled = false
        }
        event.accepted = handled
    }

    // ---- chrome ----------------------------------------------------------

    // Artwork taken out of the original avatareditor.xex: the closet's dark
    // panel behind the avatar and the banner that sits under the item strip.
    // The editor's own studio backdrops: the menu's plain one and the closet's
    // with the halo pattern, both 1280x720 out of avatareditor.xex.
    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl(root.screen === "menu"
                               ? "assets/_ui/xex/background_menu.png"
                               : "assets/_ui/xex/background_closet.png")
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    // Keeps the pale backdrop from washing out the plates and the legend.
    Rectangle {
        anchors.fill: parent
        color: root.screen === "menu" ? "#400b1320" : "#330b1320"
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
            // The menu shows whose avatar this is; each other screen names the
            // plate that opened it, which is what the original's labels say.
            text: root.screen === "menu" ? root.gamerTag
                  : (root.screen === "features" ? "Change My Features"
                  : (root.screen === "choose" ? root.title : "Change My Clothes"))
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
            model: root.legendModel

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
                        // Literals: style.* is not resolved on a delegate's first
                        // bind, which logs "Unable to assign [undefined]" for
                        // every entry of the Repeater.
                        color: "#ffffff"
                        font.family: "Segoe UI"
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
                        case "save":       root.save(); break
                        case "back":       if (root.screen !== "menu") root.setScreen("menu")
                                           else root.backRequested(); break
                        case "randomize":  root.randomize(); break
                        case "portrait":   root.capturePortrait(); break
                        case "menuSelect":
                            if (root.screen === "choose") root.applyPreset(root.chooseIndex)
                            else if (root.screen === "features") root.activateFeature(root.featureIndex)
                            else root.activateMenuItem(root.menuIndex)
                            break
                        case "presets":    root.rebuildPresets(); break
                        }
                        root.forceActiveFocus()
                    }
                }
            }
        }
    }

    ItemStrip {
        id: strip
        visible: root.screen === "closet"
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
        visible: root.screen === "closet"
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
        // The avatar keeps the left half on the menu and moves right of the
        // rail in the closet, exactly where each screen puts it.
        x: root.screen === "closet" ? rail.x + rail.width + 14 : (root.screen === "features" ? 14 : 40)
        y: 64
        width: root.screen === "closet" ? root.width - x - 26
             : (root.screen === "features" ? 286 : (root.screen === "choose" ? 0 : 470))
        height: root.screen === "closet" ? 430 : (root.screen === "choose" ? 0 : 592)
        // Hidden in 3D: the baked frames have a transparent background, so a
        // visible 2D stage would show through them as a ghost avatar.
        visible: root.screen !== "choose" && root.renderMode !== "3d"
        layers: root.layers
        showShadow: root.modelShadows
        emptyHint: root.categories.length === 0
                   ? "No item folders found in " + root.assetsFolder
                   : ""
    }

    AvatarStage3D {
        id: stage3d
        objectName: "stage3d"
        x: stage.x
        y: stage.y
        width: stage.width
        height: stage.height
        visible: root.screen !== "choose" && root.renderMode === "3d"
        baseFolder: root.assetsFolder + "3d/"
        // Baked for the stock outfit and default hairstyle only, so the animated
        // set is only the right picture while both of those still match.
        animatedFolder: (root.stageVariant === "turntable/" + root.defaultHairStem)
                        ? root.assetsFolder + "3d/animated/" : ""
        variant: root.stageVariant
        defaultVariant: "turntable"
    }

    // model_shadows switch, beside the 2D/3D one. Both stages draw the shadow
    // under the avatar's feet, so it stays available in either mode.
    Rectangle {
        id: shadowSwitch
        visible: root.screen !== "choose"
        anchors.right: modeSwitch.left
        anchors.rightMargin: 8
        y: modeSwitch.y
        height: modeSwitch.height
        width: shadowLabel.implicitWidth + 24
        radius: height / 2
        color: shadowHover.containsMouse ? "#2b3a4e" : "#1b2634"
        border.width: 1
        border.color: root.modelShadows ? root.accentColor : "#43546e"

        Text {
            id: shadowLabel
            anchors.centerIn: parent
            text: "Shadow"
            color: root.modelShadows ? root.accentColor : "#ffffff"
            font.family: "Segoe UI"
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: shadowHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleShadows()
        }
    }

    // 2D / 3D switch. It shows the live mode rather than an icon for the other
    // one, and stays hidden on the choose screen, which has no avatar.
    Rectangle {
        id: modeSwitch
        visible: root.screen !== "choose"
        anchors.right: parent.right
        anchors.rightMargin: 18
        y: 18
        width: 74
        height: 26
        radius: 13
        color: modeHover.containsMouse ? "#2b3a4e" : "#1b2634"
        border.width: 1
        border.color: root.renderMode === "3d" ? root.accentColor : "#43546e"

        Text {
            anchors.centerIn: parent
            text: root.renderMode === "3d" ? "3D" : "2D"
            color: root.renderMode === "3d" ? root.accentColor : "#ffffff"
            font.family: "Segoe UI"
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: modeHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.renderMode = root.renderMode === "3d" ? "2d" : "3d"
        }
    }


    // The ten starting avatars, on the row the source's VECT chunk lays out.
    Item {
        id: choose
        visible: root.screen === "choose"
        anchors.left: parent.left
        anchors.right: parent.right
        height: 220
        y: 150

        Item {
            anchors.fill: parent

            Repeater {
                model: root.presets

                Item {
                    x: root.chooseSlots[index]
                    y: 0
                    width: 86
                    height: 168

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: index === root.chooseIndex ? "#c6f473" : "#38485e"
                        border.width: index === root.chooseIndex ? 2 : 1
                        border.color: index === root.chooseIndex ? "#c6f473" : "#43546e"
                    }

                    AvatarThumb {
                        anchors.fill: parent
                        anchors.margins: 4
                        state: modelData
                        assetsFolder: root.assetsFolder
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.chooseIndex = index
                            root.applyPreset(index)
                            root.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }

    // Change My Features: the six tiles, two columns of three, on the right so
    // the avatar stays visible while you change it.
    Item {
        id: features
        visible: root.screen === "features"
        anchors.top: header.bottom
        anchors.topMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 20
        width: 620
        height: 510

        Grid {
            columns: 2
            spacing: 10

            Repeater {
                model: root.featureItems

                Item {
                    width: 300
                    height: 167

                    Image {
                        anchors.fill: parent
                        source: Qt.resolvedUrl("assets/_ui/xex/feature_" + modelData.key
                                               + (index === root.featureIndex
                                                  ? "_selected" : "_unselected") + ".png")
                        fillMode: Image.Stretch
                        smooth: true
                        // A tile with no folder behind it reads as unavailable,
                        // the way the source greys out what you do not own.
                        opacity: root.categoryIndexFor(modelData.label) >= 0 ? 1.0 : 0.55
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        text: modelData.label
                        color: index === root.featureIndex ? "#20300a" : "#f4f7fa"
                        font.family: "Segoe UI"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.featureIndex = index
                            root.activateFeature(index)
                            root.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }

    // The menu plates. 512x128 each, drawn at 400x100: the baked icon sits in
    // the left fifth, which is where the label starts.
    Item {
        id: menu
        visible: root.screen === "menu"
        anchors.top: header.bottom
        anchors.topMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 26
        width: 400
        height: menuColumn.height

        Column {
            id: menuColumn
            spacing: 4

            Repeater {
                model: root.menuItems

                Item {
                    width: 400
                    height: 100

                    Image {
                        anchors.fill: parent
                        source: Qt.resolvedUrl("assets/_ui/xex/plate_" + modelData.key
                                               + (index === root.menuIndex
                                                  ? "_selected" : "_unselected") + ".png")
                        fillMode: Image.Stretch
                        smooth: true
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 134
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: index === root.menuIndex ? "#20300a" : "#f4f7fa"
                        font.family: "Segoe UI"
                        font.pixelSize: 19
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.menuIndex = index
                            root.activateMenuItem(index)
                            root.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }

    function toggleShadows() {
        modelShadows = !modelShadows
        saveShadows()
    }

    function saveShadows() {
        if (typeof api === "undefined" || !api.memory)
            return
        api.memory.set("cfg.avatarShadows", modelShadows ? "1" : "0")
    }

    Component.onCompleted: {
        if (typeof api !== "undefined" && api.memory) {
            var saved = api.memory.get("cfg.avatarShadows")
            if (saved === "0") modelShadows = false
            else if (saved === "1") modelShadows = true
        }
        rebuildCategories()
    }
}
