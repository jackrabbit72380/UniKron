.pragma library

// Shared look and small helpers for the avatar editor.

var accent = "#a4d21c"
var accentDeep = "#5f8a0c"
var ink = "#ffffff"
var inkDim = "#cbd8bc"
var card = "#22ffffff"
var cardHover = "#33ffffff"
var cardActive = "#f2ffffff"
var inkOnCard = "#1f2b0a"

var titleFamily = "Segoe UI"

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
    n = n.replace(/[_\-]+/g, " ").replace(/\s+/g, " ").trim()
    return n.replace(/\b\w/g, function (c) { return c.toUpperCase() })
}

// "facial-hair" -> "Facial Hair"
function titleCase(name) {
    return itemLabel(name)
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
