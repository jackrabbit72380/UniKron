import QtQuick 2.8
import QtQuick.Window 2.0
import QtGraphicalEffects 1.12
import QtQml 2.15
import QtQuick.Layouts 1.1
import "../../js/enums.mjs" as Enums
import "../../js/utils.mjs" as Utils
import "../../js/styling.mjs" as Styling

import "../../components"
import "./components"
import "../../Lists"

Item {
  id: root
  focus: true

  // ── Accent / Theme colours ────────────────────────────────────────
  // Keys match SettingsPage.qml exactly:
  //   cfg.accentFill   — accent colour index (default 0 = Lime Green)
  //   cfg.themeFill    — theme colour index  (default 2 = Midnight)
  //   cfg.accentAlpha  — accent transparency 0=opaque, 100=transparent (default 0)
  //   cfg.ifaceAlpha   — interface transparency 0=opaque, 100=transparent (default 80)
  property var _accentPalette: [
    "#5d9809","#0099CC","#FF5733","#8A2BE2","#FFAA00","#00BFA5","#E91E8C","#EEEEEE"
  ]
  property var _themePalette: [
    "#555555","#1B4F8A","#3A3ABF","#606060","#8B5E1A","#2A8A2A"
  ]
  property string accentHex:        _accentPalette[0]
  property string themeHex:         _themePalette[2]   // default 2 = Midnight
  property real   accentAlphaPct:   0                  // 0=opaque, 100=transparent
  property real   ifaceTransparency: 80                // 0=opaque, 100=transparent
  property bool   panelGradient:    true               // gradient on by default
  property bool   gradAccentColor:  true
  property bool   gradAccentOpacity: true
  property bool   gradThemeColor:   true
  property bool   gradThemeTransp:  true

  // Derived colours — same formulas as SettingsPage.qml
  property color  accentColor: Qt.rgba(
    parseInt(accentHex.substr(1,2),16)/255,
    parseInt(accentHex.substr(3,2),16)/255,
    parseInt(accentHex.substr(5,2),16)/255,
    Math.max(0.05, Math.min(1.0, 1.0 - accentAlphaPct / 100)))

  property color  themeColor: Qt.rgba(
    parseInt(themeHex.substr(1,2),16)/255,
    parseInt(themeHex.substr(3,2),16)/255,
    parseInt(themeHex.substr(5,2),16)/255,
    Math.max(0.05, Math.min(0.92, (1.0 - ifaceTransparency / 100) * 0.85)))

  // Panel gradient shades derived from theme (kept for any gradient use)
  property color panelGrad0: Qt.rgba(
    parseInt(themeHex.substr(1,2),16)/255 * 0.60 + 0.18,
    parseInt(themeHex.substr(3,2),16)/255 * 0.60 + 0.18,
    parseInt(themeHex.substr(5,2),16)/255 * 0.60 + 0.18, 1)
  property color panelGrad1: Qt.rgba(
    parseInt(themeHex.substr(1,2),16)/255 * 0.25 + 0.08,
    parseInt(themeHex.substr(3,2),16)/255 * 0.25 + 0.08,
    parseInt(themeHex.substr(5,2),16)/255 * 0.25 + 0.08, 1)

  function hexToColor(hex, alpha) {
    return Qt.rgba(
      parseInt(hex.substr(1,2),16)/255,
      parseInt(hex.substr(3,2),16)/255,
      parseInt(hex.substr(5,2),16)/255,
      alpha)
  }

  function reloadColors() {
    // Read the accent hex that SettingsPage already resolved and saved
    var savedHex = api.memory.get("cfg.accentHex") || "#5d9809"
    var savedThemeHex = api.memory.get("cfg.themeHex") || "#3A3ABF"
    root.accentHex         = savedHex
    root.themeHex          = savedThemeHex
    root.accentAlphaPct    = parseInt(api.memory.get("cfg.accentAlpha") || "0")
    root.ifaceTransparency = parseInt(api.memory.get("cfg.ifaceAlpha")  || "80")
    root.accentColor = hexToColor(root.accentHex, Math.max(0.05, Math.min(1.0, 1.0 - root.accentAlphaPct / 100)))
    root.themeColor  = hexToColor(root.themeHex,  Math.max(0.05, Math.min(0.92, (1.0 - root.ifaceTransparency / 100) * 0.85)))
    var pg = api.memory.get("cfg.panelGradient")
    root.panelGradient      = (pg === null || pg === undefined || pg === "" || pg === "true")
    var ga = api.memory.get("cfg.gradAccent");   root.gradAccentColor   = (ga === null || ga === undefined || ga === "" || ga === "true")
    var go = api.memory.get("cfg.gradAccentOp"); root.gradAccentOpacity = (go === null || go === undefined || go === "" || go === "true")
    var gt = api.memory.get("cfg.gradTheme");    root.gradThemeColor    = (gt === null || gt === undefined || gt === "" || gt === "true")
    var gr = api.memory.get("cfg.gradThemeTr");  root.gradThemeTransp   = (gr === null || gr === undefined || gr === "" || gr === "true")
  }

  Timer {
    interval: 500; running: true; repeat: true; triggeredOnStart: true
    onTriggered: root.reloadColors()
  }

  // ── Lists ─────────────────────────────────────────────────────────
  ListLastPlayed  { id: listRecent }

  // ── State ─────────────────────────────────────────────────────────
  // panelIndex: 0 = Recent Games, 1 = Collections, 2 = Games-in-collection
  property int  panelIndex:      0
  property int  recentIndex:     0
  property int  collectionIndex: 0
  property int  gameIndex:       0

  // Currently focused collection
  property var  currentCollection: api.collections.count > 0
                                   ? api.collections.get(collectionIndex) : null
  // Games for current collection
  property var  currentCollGames:  currentCollection ? currentCollection.games : null

  // ── Navigation helpers ────────────────────────────────────────────
  function openGameDetails(game) {
    api.memory.set(Enums.MemoryKeys.CurrentGame, game)
    navigate(pages.gameDetails)
  }

  // ── Page Title ────────────────────────────────────────────────────
  Row {
    id: pageTitle
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: vpx(18)
    anchors.leftMargin: vpx(10)
    spacing: vpx(8)
    height: vpx(40)

    // Library emoji
    StyledText {
      text: "📚"
      font.pixelSize: vpx(28)
      anchors.verticalCenter: parent.verticalCenter
      layer.enabled: false
    }

    // Accent-coloured separator pipe
    Rectangle {
      width: vpx(3)
      height: vpx(30)
      anchors.verticalCenter: parent.verticalCenter
      color: root.accentColor
      radius: vpx(1)
    }

    // "Game" in white
    StyledText {
      text: "Game"
      font.pixelSize: vpx(32)
      font.bold: true
      anchors.verticalCenter: parent.verticalCenter
      color: "#FFFFFF"
      layer.effect: DropShadow {
        verticalOffset: vpx(1); horizontalOffset: vpx(1)
        color: "#88000000"; radius: vpx(4); samples: vpx(5)
      }
    }

    // "Library" in accent colour
    StyledText {
      text: "Library"
      font.pixelSize: vpx(32)
      font.bold: true
      anchors.verticalCenter: parent.verticalCenter
      color: root.accentColor
      layer.effect: DropShadow {
        verticalOffset: vpx(1); horizontalOffset: vpx(1)
        color: "#88000000"; radius: vpx(4); samples: vpx(5)
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // PANELS ROW — Recent Games | Collections | Downloads/Sub-list
  // ══════════════════════════════════════════════════════════════════
  Row {
    id: panelsRow
    anchors.top: pageTitle.bottom
    anchors.topMargin: vpx(12)
    anchors.left: parent.left
    anchors.leftMargin: vpx(10)
    anchors.right: parent.right
    anchors.rightMargin: vpx(10)
    anchors.bottom: parent.bottom
    anchors.bottomMargin: vpx(70)
    spacing: vpx(6)

    // ── Panel 0: Recent Games ───────────────────────────────────────
    Rectangle {
      id: recentPanel
      width: vpx(320)
      height: parent.height
      color: "transparent"
      clip: true

      // Solid base background (always visible — fixes transparent panel bug)
      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(root.themeColor.r, root.themeColor.g, root.themeColor.b, 0.82)
        visible: !root.panelGradient
      }

      // Theme Color gradient layer
      LinearGradient {
        visible: root.panelGradient && root.gradThemeColor
        anchors.fill: parent
        start: Qt.point(0, 0); end: Qt.point(parent.width, parent.height)
        gradient: Gradient {
          GradientStop { position: 0.0; color: panelIndex === 0 ? Qt.rgba(root.themeColor.r, root.themeColor.g, root.themeColor.b, 0.97) : "#BB50616e" }
          GradientStop { position: 0.6; color: panelIndex === 0 ? Qt.rgba(root.themeColor.r * 0.7, root.themeColor.g * 0.7, root.themeColor.b * 0.7, 0.97) : "#CC283743" }
          GradientStop { position: 1.0; color: panelIndex === 0 ? Qt.rgba(root.themeColor.r * 0.5, root.themeColor.g * 0.5, root.themeColor.b * 0.5, 0.97) : "#CC29333d" }
        }
      }

      // Theme Transparency gradient layer
      LinearGradient {
        visible: root.panelGradient && root.gradThemeTransp
        anchors.fill: parent
        start: Qt.point(0, parent.height); end: Qt.point(0, 0)
        gradient: Gradient {
          GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.18) }
          GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
        }
      }

      // Accent Color gradient layer
      LinearGradient {
        visible: root.panelGradient && root.gradAccentColor
        anchors.fill: parent
        start: Qt.point(0, 0); end: Qt.point(parent.width, 0)
        gradient: Gradient {
          GradientStop { position: 0.0; color: panelIndex === 0 ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12) : "transparent" }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }

      // Accent Opacity gradient layer
      LinearGradient {
        visible: root.panelGradient && root.gradAccentOpacity
        anchors.fill: parent
        start: Qt.point(0, 0); end: Qt.point(0, parent.height)
        gradient: Gradient {
          GradientStop { position: 0.0; color: panelIndex === 0 ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.08) : "transparent" }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }

      // Left accent bar when focused
      Rectangle {
        width: vpx(3)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: root.accentColor
        visible: panelIndex === 0
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: vpx(14)
        spacing: vpx(8)

        StyledText {
          text: "Recent Games"
          font.pixelSize: vpx(20)
          font.bold: true
          Layout.fillWidth: true
          color: "#FFFFFF"
          layer.enabled: false
        }

        // Divider
        Rectangle {
          Layout.fillWidth: true
          height: vpx(1)
          color: "#44FFFFFF"
        }

        ListView {
          id: recentList
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: listRecent.games
          clip: true
          currentIndex: recentIndex
          highlightMoveDuration: 100
          highlightFollowsCurrentItem: true

          highlight: Rectangle {
            color: root.accentColor
            radius: vpx(2)
          }

          delegate: Item {
            width: recentList.width
            height: vpx(52)

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: vpx(8)
              anchors.rightMargin: vpx(10)
              anchors.topMargin: vpx(4)
              anchors.bottomMargin: vpx(4)
              spacing: vpx(8)

              // Game thumbnail
              Image {
                Layout.preferredWidth: vpx(38)
                Layout.preferredHeight: vpx(38)
                Layout.alignment: Qt.AlignVCenter
                source: modelData.assets.logo || modelData.assets.boxFront || modelData.assets.poster || ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
                Rectangle {
                  anchors.fill: parent
                  color: "#33000000"
                  visible: parent.status !== Image.Ready
                }
              }

              ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: vpx(1)

                StyledText {
                  Layout.fillWidth: true
                  text: modelData.title
                  font.pixelSize: vpx(14)
                  font.bold: index === recentIndex && panelIndex === 0
                  elide: Text.ElideRight
                  layer.enabled: false
                }
                StyledText {
                  Layout.fillWidth: true
                  text: modelData.collections.get(0).name
                  font.pixelSize: vpx(12)
                  color: "#AAFFFFFF"
                  elide: Text.ElideRight
                  layer.enabled: false
                }
              }

              // Gamerscore style
              Row {
                spacing: vpx(3)
                Layout.alignment: Qt.AlignVCenter
                StyledText {
                  text: modelData.playTime > 0
                        ? Utils.formatPlayTime(modelData.playTime) : "0/200"
                  font.pixelSize: vpx(12)
                  color: "#AAFFFFFF"
                  layer.enabled: false
                }
                Image {
                  width: vpx(14); height: vpx(14)
                  anchors.verticalCenter: parent.verticalCenter
                  source: "../../assets/images/system/gscore.png"
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                  visible: status === Image.Ready
                }
              }
            }

            // Bottom divider
            Rectangle {
              anchors.bottom: parent.bottom
              width: parent.width
              height: vpx(1)
              color: "#22FFFFFF"
              visible: index < recentList.count - 1
            }
          }
        }

        // Scroll arrows
        Row {
          Layout.alignment: Qt.AlignHCenter
          spacing: vpx(10)
          visible: recentList.count > 0

          Image {
            width: vpx(22); height: vpx(16)
            source: "../../assets/images/system/up-default.png"
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            opacity: recentList.atYBeginning ? 0.3 : 0.9
          }
          Image {
            width: vpx(22); height: vpx(16)
            source: "../../assets/images/system/down-default.png"
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            opacity: recentList.atYEnd ? 0.3 : 0.9
          }
        }
      }
    }

    // ── Panel 1: Collections ────────────────────────────────────────
    Rectangle {
      id: collectionsPanel
      width: vpx(340)
      height: parent.height
      color: "transparent"
      clip: true
      visible: panelIndex >= 1

      // Solid base background (always visible — fixes transparent panel bug)
      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(root.themeColor.r, root.themeColor.g, root.themeColor.b, 0.82)
        visible: !root.panelGradient
      }

      // Theme Color gradient layer
      LinearGradient {
        visible: root.panelGradient && root.gradThemeColor
        anchors.fill: parent
        start: Qt.point(0, 0); end: Qt.point(parent.width, parent.height)
        gradient: Gradient {
          GradientStop { position: 0.0; color: panelIndex === 1 ? Qt.rgba(root.themeColor.r, root.themeColor.g, root.themeColor.b, 0.97) : "#BB50616e" }
          GradientStop { position: 0.6; color: panelIndex === 1 ? Qt.rgba(root.themeColor.r * 0.7, root.themeColor.g * 0.7, root.themeColor.b * 0.7, 0.97) : "#CC283743" }
          GradientStop { position: 1.0; color: panelIndex === 1 ? Qt.rgba(root.themeColor.r * 0.5, root.themeColor.g * 0.5, root.themeColor.b * 0.5, 0.97) : "#CC29333d" }
        }
      }

      // Theme Transparency gradient layer
      LinearGradient {
        visible: root.panelGradient && root.gradThemeTransp
        anchors.fill: parent
        start: Qt.point(0, parent.height); end: Qt.point(0, 0)
        gradient: Gradient {
          GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.18) }
          GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
        }
      }

      // Accent Color gradient layer
      LinearGradient {
        visible: root.panelGradient && root.gradAccentColor
        anchors.fill: parent
        start: Qt.point(0, 0); end: Qt.point(parent.width, 0)
        gradient: Gradient {
          GradientStop { position: 0.0; color: panelIndex === 1 ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12) : "transparent" }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }

      // Accent Opacity gradient layer
      LinearGradient {
        visible: root.panelGradient && root.gradAccentOpacity
        anchors.fill: parent
        start: Qt.point(0, 0); end: Qt.point(0, parent.height)
        gradient: Gradient {
          GradientStop { position: 0.0; color: panelIndex === 1 ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.08) : "transparent" }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }

      Rectangle {
        width: vpx(3)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: root.accentColor
        visible: panelIndex === 1
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: vpx(14)
        spacing: vpx(8)

        StyledText {
          text: "Collections"
          font.pixelSize: vpx(20)
          font.bold: true
          Layout.fillWidth: true
          color: "#FFFFFF"
          layer.enabled: false
        }

        Rectangle {
          Layout.fillWidth: true
          height: vpx(1)
          color: "#44FFFFFF"
        }

        ListView {
          id: collectionList
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: api.collections
          clip: true
          currentIndex: collectionIndex
          highlightMoveDuration: 100
          highlightFollowsCurrentItem: true

          highlight: Rectangle {
            color: root.accentColor
            radius: vpx(2)
          }

          delegate: Item {
            width: collectionList.width
            height: vpx(44)

            StyledText {
              anchors.fill: parent
              anchors.leftMargin: vpx(10)
              verticalAlignment: Text.AlignVCenter
              text: modelData.name
              font.pixelSize: vpx(15)
              font.bold: index === collectionIndex && panelIndex === 1
              elide: Text.ElideRight
              layer.enabled: false
            }

            Rectangle {
              anchors.bottom: parent.bottom
              width: parent.width
              height: vpx(1)
              color: "#22FFFFFF"
              visible: index < collectionList.count - 1
            }
          }
        }
      }
    }

    // ── Panel 2: Games in selected collection ───────────────────────
    Rectangle {
      id: gamesPanel
      width: parent.width - recentPanel.width - collectionsPanel.width - vpx(12)
      height: parent.height
      color: "transparent"
      clip: true
      visible: panelIndex >= 2

      // Solid base background (always visible — fixes transparent panel bug)
      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(root.themeColor.r, root.themeColor.g, root.themeColor.b, 0.82)
        visible: !root.panelGradient
      }

      // Theme Color gradient layer
      LinearGradient {
        visible: root.panelGradient && root.gradThemeColor
        anchors.fill: parent
        start: Qt.point(0, 0); end: Qt.point(parent.width, parent.height)
        gradient: Gradient {
          GradientStop { position: 0.0; color: panelIndex === 2 ? Qt.rgba(root.themeColor.r, root.themeColor.g, root.themeColor.b, 0.97) : "#BB50616e" }
          GradientStop { position: 0.6; color: panelIndex === 2 ? Qt.rgba(root.themeColor.r * 0.7, root.themeColor.g * 0.7, root.themeColor.b * 0.7, 0.97) : "#CC283743" }
          GradientStop { position: 1.0; color: panelIndex === 2 ? Qt.rgba(root.themeColor.r * 0.5, root.themeColor.g * 0.5, root.themeColor.b * 0.5, 0.97) : "#CC29333d" }
        }
      }

      // Theme Transparency gradient layer
      LinearGradient {
        visible: root.panelGradient && root.gradThemeTransp
        anchors.fill: parent
        start: Qt.point(0, parent.height); end: Qt.point(0, 0)
        gradient: Gradient {
          GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.18) }
          GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
        }
      }

      // Accent Color gradient layer
      LinearGradient {
        visible: root.panelGradient && root.gradAccentColor
        anchors.fill: parent
        start: Qt.point(0, 0); end: Qt.point(parent.width, 0)
        gradient: Gradient {
          GradientStop { position: 0.0; color: panelIndex === 2 ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12) : "transparent" }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }

      // Accent Opacity gradient layer
      LinearGradient {
        visible: root.panelGradient && root.gradAccentOpacity
        anchors.fill: parent
        start: Qt.point(0, 0); end: Qt.point(0, parent.height)
        gradient: Gradient {
          GradientStop { position: 0.0; color: panelIndex === 2 ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.08) : "transparent" }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }

      Rectangle {
        width: vpx(3)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: root.accentColor
        visible: panelIndex === 2
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: vpx(14)
        spacing: vpx(8)

        StyledText {
          text: currentCollection ? currentCollection.name : ""
          font.pixelSize: vpx(20)
          font.bold: true
          Layout.fillWidth: true
          color: "#FFFFFF"
          elide: Text.ElideRight
          layer.enabled: false
        }

        Rectangle {
          Layout.fillWidth: true
          height: vpx(1)
          color: "#44FFFFFF"
        }

        ListView {
          id: gamesList
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: currentCollGames
          clip: true
          currentIndex: gameIndex
          highlightMoveDuration: 100
          highlightFollowsCurrentItem: true

          highlight: Rectangle {
            color: root.accentColor
            radius: vpx(2)
          }

          delegate: Item {
            width: gamesList.width
            height: vpx(52)

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: vpx(8)
              anchors.rightMargin: vpx(10)
              anchors.topMargin: vpx(4)
              anchors.bottomMargin: vpx(4)
              spacing: vpx(8)

              Image {
                Layout.preferredWidth: vpx(38)
                Layout.preferredHeight: vpx(38)
                Layout.alignment: Qt.AlignVCenter
                source: modelData.assets.logo || modelData.assets.boxFront || modelData.assets.poster || ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
                Rectangle {
                  anchors.fill: parent
                  color: "#33000000"
                  visible: parent.status !== Image.Ready
                }
              }

              ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: vpx(1)

                StyledText {
                  Layout.fillWidth: true
                  text: modelData.title
                  font.pixelSize: vpx(14)
                  font.bold: index === gameIndex && panelIndex === 2
                  elide: Text.ElideRight
                  layer.enabled: false
                }
                StyledText {
                  Layout.fillWidth: true
                  text: modelData.developer || modelData.publisher || "Game"
                  font.pixelSize: vpx(12)
                  color: "#AAFFFFFF"
                  elide: Text.ElideRight
                  layer.enabled: false
                }
              }
            }

            Rectangle {
              anchors.bottom: parent.bottom
              width: parent.width
              height: vpx(1)
              color: "#22FFFFFF"
              visible: index < gamesList.count - 1
            }
          }
        }
      }
    }
  }

  // ── Bottom status bar ─────────────────────────────────────────────
  Row {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.leftMargin: vpx(10)
    anchors.bottomMargin: vpx(14)
    spacing: vpx(6)

    StyledText {
      text: {
        if (panelIndex === 0)
          return (recentList.count > 0 ? (recentIndex + 1) + " of " + recentList.count : "0 of 0")
        else if (panelIndex === 1)
          return (collectionList.count > 0 ? (collectionIndex + 1) + " of " + collectionList.count : "0 of 0")
        else
          return (gamesList.count > 0 ? (gameIndex + 1) + " of " + gamesList.count : "0 of 0")
      }
      font.pixelSize: vpx(20)
      color: "#616161"
      layer.effect: DropShadow {
        verticalOffset: vpx(1); horizontalOffset: vpx(1)
        color: "#55FFFFFF"; radius: vpx(2); samples: vpx(1)
      }
    }
  }

  // ── Input ─────────────────────────────────────────────────────────
  Keys.onRightPressed: {
    if (!event.isAutoRepeat) {
      if (panelIndex === 0) {
        // Move from Recent to Collections
        panelIndex = 1
        collectionList.currentIndex = collectionIndex
      } else if (panelIndex === 1 && currentCollGames && currentCollGames.count > 0) {
        // Move from Collections to Games
        panelIndex = 2
        gameIndex = 0
        gamesList.currentIndex = 0
      }
    }
  }

  Keys.onLeftPressed: {
    if (!event.isAutoRepeat) {
      if (panelIndex === 2) {
        panelIndex = 1
      } else if (panelIndex === 1) {
        panelIndex = 0
      } else {
        navigate(pages.library)
      }
    }
  }

  Keys.onUpPressed: {
    if (!event.isAutoRepeat) {
      if (panelIndex === 0) {
        if (recentIndex > 0) { recentIndex--; recentList.currentIndex = recentIndex }
      } else if (panelIndex === 1) {
        if (collectionIndex > 0) {
          collectionIndex--
          collectionList.currentIndex = collectionIndex
          gameIndex = 0
        }
      } else if (panelIndex === 2) {
        if (gameIndex > 0) { gameIndex--; gamesList.currentIndex = gameIndex }
      }
    }
  }

  Keys.onDownPressed: {
    if (!event.isAutoRepeat) {
      if (panelIndex === 0) {
        if (recentIndex < recentList.count - 1) { recentIndex++; recentList.currentIndex = recentIndex }
      } else if (panelIndex === 1) {
        if (collectionIndex < api.collections.count - 1) {
          collectionIndex++
          collectionList.currentIndex = collectionIndex
          gameIndex = 0
        }
      } else if (panelIndex === 2) {
        if (gameIndex < gamesList.count - 1) { gameIndex++; gamesList.currentIndex = gameIndex }
      }
    }
  }

  Keys.onPressed: {
    if (!event.isAutoRepeat) {
      // X / Details — open game details for selected game
      if (api.keys.isDetails(event)) {
        var game = null
        if (panelIndex === 0 && listRecent.games.count > 0) {
          game = listRecent.games.get(recentIndex)
        } else if (panelIndex === 2 && currentCollGames && currentCollGames.count > 0) {
          game = currentCollGames.get(gameIndex)
        } else if (panelIndex === 1 && currentCollGames && currentCollGames.count > 0) {
          game = currentCollGames.get(0)
        }
        if (game) openGameDetails(game)
        event.accepted = true
      }
      // A / Accept — enter next panel or open details
      else if (api.keys.isAccept(event)) {
        if (panelIndex === 0) {
          panelIndex = 1
        } else if (panelIndex === 1 && currentCollGames && currentCollGames.count > 0) {
          panelIndex = 2
          gameIndex = 0
          gamesList.currentIndex = 0
        } else if (panelIndex === 2 && currentCollGames && currentCollGames.count > 0) {
          openGameDetails(currentCollGames.get(gameIndex))
        }
        event.accepted = true
      }
      // B / Cancel — go back
      else if (api.keys.isCancel(event)) {
        if (panelIndex > 0) {
          panelIndex--
        } else {
          navigate(pages.library)
        }
        event.accepted = true
      }
      else if (api.keys.isNextPage(event)) {
        if (panelIndex === 2) {
          var step = Math.max(1, Math.floor(gamesList.count / 5))
          gameIndex = Math.min(gamesList.count - 1, gameIndex + step)
          gamesList.currentIndex = gameIndex
        } else if (panelIndex === 1) {
          collectionIndex = Math.min(api.collections.count - 1, collectionIndex + 5)
          collectionList.currentIndex = collectionIndex
        }
        event.accepted = true
      }
      else if (api.keys.isPrevPage(event)) {
        if (panelIndex === 2) {
          var step2 = Math.max(1, Math.floor(gamesList.count / 5))
          gameIndex = Math.max(0, gameIndex - step2)
          gamesList.currentIndex = gameIndex
        } else if (panelIndex === 1) {
          collectionIndex = Math.max(0, collectionIndex - 5)
          collectionList.currentIndex = collectionIndex
        }
        event.accepted = true
      }
    }
  }

  Component.onCompleted: {
    root.reloadColors()
    setAvailableActions({
      [Enums.ActionKeys.Bottom]: { label: "Select",  visible: true },
      [Enums.ActionKeys.Right]:  { label: "Back",    visible: true },
      [Enums.ActionKeys.Left]:   { label: "Details", visible: true },
    })
  }
}
