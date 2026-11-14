import QtQuick 2.8
import QtQuick.Window 2.0
import QtGraphicalEffects 1.12
import QtQml 2.15
import QtQuick.Layouts 1.1
import "../../js/enums.mjs" as Enums
import "../../js/utils.mjs" as Utils
import "../../components"
import "../../Lists"

// ════════════════════════════════════════════════════════════════════
// SystemPage.qml  —  Pegasus info, play stats, and collection overview
// Opened from the "System" dashboard tab
// ════════════════════════════════════════════════════════════════════

Item {
  id: root
  focus: true
  Keys.priority: Keys.BeforeItem

  // ── Accent / Theme colours from Settings ─────────────────────────
  function mem(k, d) { var v = api.memory.get(k); return (v!==undefined&&v!==null&&v!=="") ? v : d }

  readonly property var accentColors: [
    "#5d9809","#0099CC","#FF5733","#8A2BE2","#FFAA00","#00BFA5","#E91E8C","#EEEEEE"
  ]
  readonly property var themeColors: [
    "#555555","#1B4F8A","#3A3ABF","#606060","#8B5E1A","#2A8A2A"
  ]
  property string accentHex: {
    var i = parseInt(mem("cfg.accentColor","0"))
    return accentColors[Math.max(0,Math.min(accentColors.length-1,i))]
  }
  property string themeHex: {
    var i = parseInt(mem("cfg.themeColor","0"))
    return themeColors[Math.max(0,Math.min(themeColors.length-1,i))]
  }
  property real panelAlpha: {
    var a = parseInt(mem("cfg.ifaceAlpha","80"))
    return Math.max(0.08, Math.min(0.92, (1.0 - a/100) * 0.88))
  }
  function themeRgba(alpha) {
    return Qt.rgba(
      parseInt(themeHex.substr(1,2),16)/255 * 0.4,
      parseInt(themeHex.substr(3,2),16)/255 * 0.4,
      parseInt(themeHex.substr(5,2),16)/255 * 0.4,
      alpha)
  }

  // Refresh accent/theme every second
  Timer {
    interval: 1000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: {
      var ai = parseInt(root.mem("cfg.accentColor","0"))
      root.accentHex = root.accentColors[Math.max(0,Math.min(root.accentColors.length-1,ai))]
      var ti = parseInt(root.mem("cfg.themeColor","0"))
      root.themeHex  = root.themeColors[Math.max(0,Math.min(root.themeColors.length-1,ti))]
    }
  }


  ListPlayTime  { id: listPlayTime;  max: api.allGames.count }
  ListLastPlayed  { id: listRecent }
  ListFavorites   { id: listFavorites }

  property int totalPlayTime: {
    var t = 0
    for (var i = 0; i < api.allGames.count; i++) t += api.allGames.get(i).playTime
    return t
  }

  // ── Category tabs ─────────────────────────────────────────────────
  readonly property var catLabels: ["Overview", "Play Time", "Collections"]
  property int catIndex: 0

  Component.onCompleted: {
    setAvailableActions({
      [Enums.ActionKeys.Right]:  { label: "Back",    visible: true },
      [Enums.ActionKeys.Bottom]: { label: "Select",  visible: true }
    })
  }

  // ════════════════════════════════════════════════════════════════
  // HEADER — renamed to "Pegasus"
  // ════════════════════════════════════════════════════════════════
  StyledText {
    id: pageTitle
    text: "System"
    font.pixelSize: vpx(32)
    font.bold: true
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: vpx(28)
    anchors.leftMargin: vpx(40)
    layer.enabled: false
  }

  // X Close button — top right
  Rectangle {
    id: closeBtn
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: vpx(24)
    anchors.rightMargin: vpx(20)
    width: vpx(38); height: vpx(38); radius: vpx(6)
    color: closeBtnMA.containsMouse ? "#CC993333" : Qt.rgba(1,1,1,0.15)
    border.color: closeBtnMA.containsMouse ? "#FF6666" : Qt.rgba(1,1,1,0.3)
    border.width: vpx(1)
    z: 10
    Behavior on color { ColorAnimation { duration: 80 } }
    StyledText { anchors.centerIn: parent; text: "✕"; font.pixelSize: vpx(17); font.bold: true
      color: closeBtnMA.containsMouse ? "#FFFFFF" : "#CCCCCC"; layer.enabled: false }
    MouseArea { id: closeBtnMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
      onClicked: navigate(pages.library) }
  }

  // ── Category tab bar ──────────────────────────────────────────────
  Row {
    id: tabBar
    anchors.top: parent.top
    anchors.right: closeBtn.left
    anchors.topMargin: vpx(28)
    anchors.rightMargin: vpx(12)
    spacing: vpx(0)

    Repeater {
      model: catLabels
      delegate: Rectangle {
        property bool isActive: index === catIndex
        width: vpx(140); height: vpx(36)
        color: isActive ? root.accentHex : "transparent"
        radius: index === 0 ? vpx(4) : (index === catLabels.length - 1 ? vpx(4) : 0)
        StyledText {
          anchors.centerIn: parent
          text: modelData
          font.pixelSize: vpx(17)
          font.bold: isActive
          layer.enabled: false
        }
        MouseArea {
          anchors.fill: parent; cursorShape: Qt.PointingHandCursor
          onClicked: { catIndex = index; root.forceActiveFocus() }
        }
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // CONTENT AREA
  // ════════════════════════════════════════════════════════════════
  Rectangle {
    id: contentArea
    anchors.top: pageTitle.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.topMargin: vpx(14)
    anchors.leftMargin: vpx(40)
    anchors.rightMargin: vpx(40)
    anchors.bottomMargin: vpx(70)
    color: root.themeRgba(root.panelAlpha)
    radius: vpx(4)
    clip: true

    // ── OVERVIEW ───────────────────────────────────────────────────
    Column {
      id: overviewView
      visible: catIndex === 0
      anchors.fill: parent
      anchors.margins: vpx(30)
      spacing: vpx(0)

      StyledText {
        text: "Pegasus Overview"
        font.pixelSize: vpx(20); font.bold: true
        color: root.accentHex
        bottomPadding: vpx(16)
        layer.enabled: false
      }

      Repeater {
        model: [
          { label: "Collections",        value: api.collections.count.toString() },
          { label: "Total Games",         value: api.allGames.count.toString() },
          { label: "Favorites / Backlog", value: listFavorites.games.count.toString() },
          { label: "Total Play Time",     value: Utils.formatPlayTime(totalPlayTime) },
          { label: "Most Played",         value: listPlayTime.games.count > 0 ? listPlayTime.games.get(0).title : "—" },
          { label: "Last Played",         value: listRecent.games.count > 0 ? listRecent.games.get(0).title : "—" },
        ]
        delegate: Rectangle {
          width: overviewView.width
          height: vpx(46)
          color: index % 2 === 0 ? "#10FFFFFF" : "transparent"
          radius: vpx(3)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: vpx(12)
            anchors.rightMargin: vpx(12)

            StyledText {
              text: modelData.label
              color: "#AAAAAA"
              font.pixelSize: vpx(16)
              layer.enabled: false
            }
            Item { Layout.fillWidth: true }
            StyledText {
              text: modelData.value
              font.pixelSize: vpx(16)
              font.bold: true
              layer.enabled: false
            }
          }
        }
      }
    }

    // ── PLAY TIME ──────────────────────────────────────────────────
    Item {
      id: playTimeView
      visible: catIndex === 1
      anchors.fill: parent
      anchors.margins: vpx(8)

      StyledText {
        id: playTimeTitle
        text: "Play Time — Top " + listPlayTime.games.count
        font.pixelSize: vpx(16); font.bold: true; color: root.accentHex
        anchors.top: parent.top; anchors.left: parent.left
        anchors.margins: vpx(8)
        layer.enabled: false
      }

      ListView {
        id: playTimeList
        anchors.top: playTimeTitle.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: vpx(6)
        model: listPlayTime.games
        clip: true
        highlightMoveDuration: 80
        highlight: Rectangle { color: Qt.rgba(parseInt(root.accentHex.substr(1,2),16)/255,parseInt(root.accentHex.substr(3,2),16)/255,parseInt(root.accentHex.substr(5,2),16)/255,0.25); radius: vpx(3) }

        delegate: Item {
          width: playTimeList.width; height: vpx(40)
          Rectangle {
            color: "transparent"
            anchors.fill: parent

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: vpx(12)
              anchors.rightMargin: vpx(12)

              StyledText {
                text: (index + 1) + "."
                color: "#888888"; font.pixelSize: vpx(14)
                Layout.preferredWidth: vpx(28)
                layer.enabled: false
              }
              StyledText {
                Layout.fillWidth: true
                text: title
                font.pixelSize: vpx(15)
                elide: Text.ElideRight
                layer.enabled: false
              }
              StyledText {
                text: Utils.formatPlayTime(playTime)
                color: root.accentHex; font.pixelSize: vpx(15); font.bold: true
                layer.enabled: false
              }
            }
          }
          Rectangle { color: "#15FFFFFF"; height: vpx(1); width: parent.width; anchors.bottom: parent.bottom }
        }
      }
    }

    // ── COLLECTIONS ────────────────────────────────────────────────
    Item {
      id: collectionsView
      visible: catIndex === 2
      anchors.fill: parent
      anchors.margins: vpx(8)

      StyledText {
        id: colTitle
        text: "Collections  (" + api.collections.count + ")"
        font.pixelSize: vpx(16); font.bold: true; color: root.accentHex
        anchors.top: parent.top; anchors.left: parent.left
        anchors.margins: vpx(8)
        layer.enabled: false
      }

      ListView {
        id: colList
        anchors.top: colTitle.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: vpx(6)
        model: api.collections
        clip: true
        highlightMoveDuration: 80
        highlight: Rectangle { color: Qt.rgba(parseInt(root.accentHex.substr(1,2),16)/255,parseInt(root.accentHex.substr(3,2),16)/255,parseInt(root.accentHex.substr(5,2),16)/255,0.25); radius: vpx(3) }

        delegate: Item {
          width: colList.width; height: vpx(40)
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: vpx(12)
            anchors.rightMargin: vpx(12)

            StyledText {
              Layout.fillWidth: true
              text: name
              font.pixelSize: vpx(15); elide: Text.ElideRight
              layer.enabled: false
            }
            StyledText {
              text: games.count + " games"
              color: "#AAAAAA"; font.pixelSize: vpx(14)
              layer.enabled: false
            }
          }
          Rectangle { color: "#15FFFFFF"; height: vpx(1); width: parent.width; anchors.bottom: parent.bottom }
        }
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // INPUT
  // ════════════════════════════════════════════════════════════════
  Keys.onLeftPressed: {
    catIndex = (catIndex - 1 + catLabels.length) % catLabels.length
    event.accepted = true
  }

  Keys.onRightPressed: {
    catIndex = (catIndex + 1) % catLabels.length
    event.accepted = true
  }

  Keys.onUpPressed: {
    var lv = catIndex === 1 ? playTimeList : catIndex === 2 ? colList : null
    if (lv && lv.currentIndex > 0) { lv.currentIndex--; event.accepted = true }
  }

  Keys.onDownPressed: {
    var lv2 = catIndex === 1 ? playTimeList : catIndex === 2 ? colList : null
    if (lv2 && lv2.currentIndex < lv2.count - 1) { lv2.currentIndex++; event.accepted = true }
  }

  Keys.onPressed: {
    if (event.isAutoRepeat) return
    if (api.keys.isCancel(event)) {
      navigate(pages.library)
      event.accepted = true
    } else if (api.keys.isNextPage(event)) {
      catIndex = (catIndex + 1) % catLabels.length
      event.accepted = true
    } else if (api.keys.isPrevPage(event)) {
      catIndex = (catIndex - 1 + catLabels.length) % catLabels.length
      event.accepted = true
    }
  }
}
