import QtQuick 2.8
import QtQuick.Layouts 1.1
import "../../components"

// ════════════════════════════════════════════════════════════════════
// SettingsDetails.qml  —  Detail panel for a single settings entry
// Supports: toggle · cycle · slider · action · info · placement · colorpick
// ════════════════════════════════════════════════════════════════════

ColumnLayout {
  id: root

  property string settingLabel:  ""
  property string settingValue:  ""
  property string settingType:   ""
  property string description:   ""
  property string hint:          ""
  property string accentHex:     "#5d9809"

  spacing: vpx(20)

  // ── Icon area ────────────────────────────────────────────────────
  Rectangle {
    Layout.maximumWidth: vpx(80)
    Layout.minimumWidth: vpx(80)
    height: vpx(80)
    color: accentHex
    radius: vpx(8)
    Layout.alignment: Qt.AlignHCenter

    StyledText {
      anchors.centerIn: parent
      text: {
        if (settingType === "toggle")    return settingValue === "On" ? "✔" : "✘"
        if (settingType === "action")    return "▶"
        if (settingType === "placement") return "✛"
        if (settingType === "colorpick") return "🎨"
        if (settingType === "slider")    return "◈"
        return "⚙"
      }
      font.pixelSize: vpx(32)
      layer.enabled: false
    }
  }

  // ── Label ────────────────────────────────────────────────────────
  ColumnLayout {
    Layout.fillWidth: true
    spacing: vpx(4)

    StyledText {
      text: "Setting"
      font.weight: Font.Black
      color: "#AAAAAA"
      font.pixelSize: vpx(13)
      layer.enabled: false
    }
    StyledText {
      Layout.fillWidth: true
      text: settingLabel || "—"
      font.weight: Font.Black
      font.pixelSize: vpx(20)
      wrapMode: Text.Wrap
      layer.enabled: false
    }
  }

  // ── Current value ────────────────────────────────────────────────
  ColumnLayout {
    Layout.fillWidth: true
    spacing: vpx(4)

    StyledText {
      text: "Current Value"
      font.weight: Font.Black
      color: "#AAAAAA"
      font.pixelSize: vpx(13)
      layer.enabled: false
    }
    StyledText {
      Layout.fillWidth: true
      text: settingValue || "—"
      font.weight: Font.Black
      color: settingType === "toggle"
        ? (settingValue === "On" ? accentHex : "#888888")
        : settingType === "action" ? "#FF6666" : "#FFFFFF"
      font.pixelSize: vpx(18)
      wrapMode: Text.Wrap
      layer.enabled: false
    }
  }

  // ── Type hint ────────────────────────────────────────────────────
  ColumnLayout {
    Layout.fillWidth: true
    spacing: vpx(4)
    visible: settingType === "placement" || settingType === "colorpick"
             || settingType === "slider"

    StyledText {
      text: "Controls"
      font.weight: Font.Black
      color: "#AAAAAA"
      font.pixelSize: vpx(13)
      layer.enabled: false
    }
    StyledText {
      Layout.fillWidth: true
      text: {
        if (settingType === "placement")
          return "← → ↑ ↓ to nudge position\nA to open preset menu\nDrag dot on mini-screen\nSave/load named presets\nManual X,Y % entry"
        if (settingType === "colorpick")
          return "← → to cycle colors\nClick swatch to pick"
        if (settingType === "slider")
          return "← → to adjust value\nHold for faster change"
        return ""
      }
      color: "#CCFFFFFF"
      font.pixelSize: vpx(14)
      wrapMode: Text.Wrap
      layer.enabled: false
    }
  }

  // ── Description ──────────────────────────────────────────────────
  ColumnLayout {
    Layout.fillWidth: true
    spacing: vpx(4)
    visible: description.length > 0

    StyledText {
      text: "Description"
      font.weight: Font.Black
      color: "#AAAAAA"
      font.pixelSize: vpx(13)
      layer.enabled: false
    }
    StyledText {
      Layout.fillWidth: true
      text: description
      color: "#CCFFFFFF"
      font.pixelSize: vpx(15)
      wrapMode: Text.Wrap
      layer.enabled: false
    }
  }

  // ── Hint ─────────────────────────────────────────────────────────
  StyledText {
    Layout.fillWidth: true
    text: hint
    color: "#80FFFFFF"
    font.pixelSize: vpx(13)
    wrapMode: Text.Wrap
    layer.enabled: false
    visible: hint.length > 0
  }

  Item { Layout.fillHeight: true }
}
