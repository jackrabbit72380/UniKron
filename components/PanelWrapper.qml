import QtQuick 2.8
import QtQuick.Window 2.0
import QtGraphicalEffects 1.0
import "../js/styling.mjs" as Styling

FocusScope {
  id: panel
  width: parent.panelWidth
  height: parent.panelHeight
  scale: PathView.itemScale
  // Scale from left for right-side panels, right for left-side, center for slot 0
  transformOrigin: {
    var si = Math.round(panel.PathView.screenIndex);
    if (si < 0) return Item.Right;
    if (si > 0) return Item.Left;
    return Item.Center;
  }
  rotation: panel.PathView.itemRotation || 0
  opacity: 0
  z: PathView.itemZ
  anchors.top: parent.top
  property int screenIndex: Math.max(0, Math.round(panel.PathView.screenIndex))
  property int itemIndex: index
  default property alias content: wrapper.data
  // Helper properties — read wrapper settings from PanelsList (PathView parent)
  property var  pv:              panel.PathView.view
  property real wCornerRadius:   pv && pv.wrapCornerRadius      !== undefined ? vpx(pv.wrapCornerRadius)      : vpx(7)
  property real wReflSize:       pv && pv.wrapReflectionSize    !== undefined ? vpx(pv.wrapReflectionSize)    : vpx(30)
  property real wReflOpacity:    pv && pv.wrapReflectionOpacity !== undefined ? pv.wrapReflectionOpacity      : 0.2
  property real wReflBlur:       pv && pv.wrapReflectionBlur    !== undefined ? pv.wrapReflectionBlur         : 0
  property bool wShadowOn:       pv && pv.wrapShadowOn          !== undefined ? pv.wrapShadowOn               : true
  property real wShadowOpacity:  pv && pv.wrapShadowOpacity     !== undefined ? pv.wrapShadowOpacity          : 1.0
  // wShadowMode: 0=bitmap (panel-shadow.png, right edge), 1=DropShadow (corner-aware)
  property int  wShadowMode:     pv && pv.wrapShadowMode        !== undefined ? pv.wrapShadowMode             : 0
  property real wShadowRadius:   pv && pv.wrapShadowRadius      !== undefined ? pv.wrapShadowRadius           : 16
  property real wShadowOffsetX:  pv && pv.wrapShadowOffsetX     !== undefined ? pv.wrapShadowOffsetX          : 8
  property real wShadowOffsetY:  pv && pv.wrapShadowOffsetY     !== undefined ? pv.wrapShadowOffsetY          : 4
  property color wShadowColor:   (pv && pv.wrapShadowColor !== undefined && pv.wrapShadowColor !== "")
                                    ? pv.wrapShadowColor : "#000000"

  transform: [
    Translate {
      y: {
        var pv = panel.PathView.view;
        var si = Math.round(panel.PathView.screenIndex);
        var baseY = panel.PathView.itemOffsetY + (panel.PathView.itemCenterOffY || 0);
        if (!pv) return baseY;
        if (si < 0) return baseY + (pv.edLeftCorrectY  || 0);
        if (si > 0) return baseY + (pv.edRightCorrectY || 0);
        return baseY;
      }
      // Per-side X correction
      x: {
        var pv = panel.PathView.view;
        if (!pv) return (panel.PathView.itemCenterOffX || 0);
        var si = Math.round(panel.PathView.screenIndex);
        if (si < 0) return pv.edLeftCorrectX  || 0;
        if (si > 0) return pv.edRightCorrectX || 0;
        return panel.PathView.itemCenterOffX || 0;
      }

      SequentialAnimation on x  {
        PauseAnimation { duration: 50 * screenIndex }
        NumberAnimation {
          from: -(panel.PathView.itemX - panel.PathView.previousItemX)
          to: 0
          duration: 300
          easing.type: Easing.OutCubic
        }
      }
    },
    // Y-axis carousel tilt — driven by itemTiltY PathAttribute
    Rotation {
      angle: panel.PathView.itemTiltY || 0
      axis.x: 0; axis.y: 1; axis.z: 0
      origin.x: panel.width  / 2
      origin.y: panel.height / 2
    }
  ]

  SequentialAnimation on opacity  {
    PauseAnimation { duration: 50 * screenIndex }
    NumberAnimation {
      from: 0
      to: 1
      duration: 300
      easing.type: Easing.OutCubic
    }
  }

  SequentialAnimation on scale  {
    PauseAnimation { duration: 50 * screenIndex }
    NumberAnimation {
      from: panel.PathView.previousItemScale
      to: panel.PathView.itemScale
      duration: 300
      easing.type: Easing.OutCubic
    }
  }

  // ── DropShadow shadow source (mode 1) — a rounded rect matching the panel shape ──
  // Placed at z:0, invisible as a direct child (used only as DropShadow source).
  Item {
    id: shadowSource
    anchors.fill: content
    visible: false
    Rectangle {
      anchors.fill: parent
      radius: wCornerRadius
      color: wShadowColor
    }
  }

  // ── DropShadow (mode 1) — sits behind content at z:0 ──
  DropShadow {
    visible: wShadowOn && wShadowMode === 1
    anchors.fill: content
    z: 0
    source: shadowSource
    transparentBorder: true
    horizontalOffset: wShadowOffsetX
    verticalOffset:   wShadowOffsetY
    radius:           wShadowRadius
    samples:          Math.min(32, Math.round(wShadowRadius) * 2 + 1)
    color:            wShadowColor
    opacity:          wShadowOpacity
  }

  // ── Content — masked panel, rendered above shadow at z:1 ──
  Item {
    id: content
    width: parent.width
    height: parent.height
    z: 1

    Item {
      id: wrapper
      width: parent.width
      height: parent.height
    }

    Rectangle {
      id: mask
      anchors.fill: parent
      radius: wCornerRadius
      visible: false
    }

    layer.enabled: true
    layer.effect: OpacityMask {
      maskSource: mask
    }
  }

  // ── Bitmap shadow — original right-edge panel-shadow.png (mode 0) ──
  Image {
    anchors.left: content.right
    height: parent.height
    width: height * 0.09
    visible: wShadowOn && wShadowMode === 0
    opacity: wShadowOpacity
    source: "../assets/images/misc/panel-shadow.png"
  }

  Item {
    id: reflection
    width: content.width
    height: content.height
    anchors.top: content.bottom
    anchors.horizontalCenter: parent.horizontalCenter

    Rectangle {
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: wReflSize
      radius: wCornerRadius

      gradient: Gradient {
        GradientStop { position: 0; color: Qt.rgba(1,1,1, wReflOpacity) }
        GradientStop { position: 1; color: Qt.rgba(1,1,1,0) }
      }
    }
  }

  ShaderEffect
  {
    id: reflShader
    property variant mask: ShaderEffectSource
    {
      sourceItem: reflection
      hideSource: true
    }

    property variant source: ShaderEffectSource
    {
      sourceItem: content
      hideSource: false
    }

    width: parent.width
    height: parent.height
    anchors.top: content.bottom
    visible: wReflBlur <= 0
    fragmentShader: `
    varying highp vec2 qt_TexCoord0;
    uniform sampler2D source;
    uniform sampler2D mask;
    void main(void)
    {
      gl_FragColor = texture2D(source, vec2(qt_TexCoord0.s, 1.0 - qt_TexCoord0.t)) * texture2D(mask, qt_TexCoord0).a;
    }
    `
  }

  // ── Blurred reflection (when wReflBlur > 0) ──────────────────────
  Item {
    id: reflBlurContainer
    width: parent.width
    height: parent.height
    anchors.top: content.bottom
    visible: wReflBlur > 0

    ShaderEffect {
      id: reflShaderBlurred
      property variant mask: ShaderEffectSource { sourceItem: reflection; hideSource: false }
      property variant source: ShaderEffectSource { sourceItem: content; hideSource: false }
      anchors.fill: parent
      fragmentShader: `
      varying highp vec2 qt_TexCoord0;
      uniform sampler2D source;
      uniform sampler2D mask;
      void main(void)
      {
        gl_FragColor = texture2D(source, vec2(qt_TexCoord0.s, 1.0 - qt_TexCoord0.t)) * texture2D(mask, qt_TexCoord0).a;
      }
      `
    }

    FastBlur {
      anchors.fill: parent
      source: reflShaderBlurred
      radius: wReflBlur
      transparentBorder: true
    }
  }

  // ── Debug bounds overlay (visible when editor edShowBounds is ON) ─
  // Reads edShowBounds from the PathView parent (PanelsList).
  // Shows a red dashed border + corner markers + size/position readout.
  Item {
    id: boundsOverlay
    anchors.fill: content
    visible: {
      // Walk up to PanelsList (PathView) and read edShowBounds
      var pv = panel.PathView.view;
      return pv ? pv.edShowBounds : false;
    }
    z: 10000

    // Outer border
    Rectangle {
      anchors.fill: parent
      color: "transparent"
      border.color: "#ff3333"
      border.width: vpx(2)
      opacity: 0.85
    }

    // Corner markers
    Repeater {
      model: [
        {ax: 0, ay: 0, xo: 0,    yo: 0    },
        {ax: 1, ay: 0, xo: -8,   yo: 0    },
        {ax: 0, ay: 1, xo: 0,    yo: -8   },
        {ax: 1, ay: 1, xo: -8,   yo: -8   }
      ]
      delegate: Rectangle {
        x: modelData.ax * boundsOverlay.width  + vpx(modelData.xo)
        y: modelData.ay * boundsOverlay.height + vpx(modelData.yo)
        width: vpx(8); height: vpx(8)
        color: "#ff3333"; opacity: 0.9
      }
    }

    // Center crosshair
    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter:   parent.verticalCenter
      width: vpx(20); height: vpx(2)
      color: "#ff3333"; opacity: 0.6
    }
    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter:   parent.verticalCenter
      width: vpx(2); height: vpx(20)
      color: "#ff3333"; opacity: 0.6
    }

    // Size + slot readout
    Rectangle {
      anchors.bottom:      parent.top
      anchors.left:        parent.left
      anchors.bottomMargin: vpx(3)
      width:  sizeLabel.contentWidth + vpx(10)
      height: vpx(18)
      color:  Qt.rgba(0,0,0,0.7)
      border.color: "#ff3333"; border.width: vpx(1)
      radius: vpx(2)

      Text {
        id: sizeLabel
        anchors.centerIn: parent
        font.pixelSize: vpx(10)
        color: "#ff9999"
        font.family: "monospace"
        text: {
          var w = Math.round(panel.width);
          var h = Math.round(panel.height);
          var sc = panel.PathView.itemScale;
          var slot = panel.PathView.screenIndex ? Math.round(panel.PathView.screenIndex) : 0;
          var side = slot < 0 ? "L" : (slot > 0 ? "R" : "C");
          var orig = slot < 0 ? "⊣" : (slot > 0 ? "⊢" : "⊕");
          return w + "×" + h + "  sc:" + (sc ? sc.toFixed(2) : "?") + "  [" + slot + "]  " + orig;
        }
      }
    }

    // Scale indicator bar at bottom
    Rectangle {
      anchors.bottom: parent.bottom
      anchors.bottomMargin: vpx(4)
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width * 0.6
      height: vpx(3)
      color: Qt.rgba(1,1,1,0.1)
      radius: vpx(2)

      Rectangle {
        anchors.left: parent.left
        anchors.top:  parent.top
        anchors.bottom: parent.bottom
        width: parent.width * Math.min(1.0, panel.PathView.itemScale || 0)
        color: "#ff3333"
        opacity: 0.7
        radius: vpx(2)
      }
    }
  }

  // ── Wrapper-level debug bounds (edShowWrapperBounds) ─────────────
  // Shows the FocusScope panel boundary — the actual outer container
  // including transform origin. Orange color to distinguish from content bounds.
  Item {
    id: wrapBoundsOverlay
    anchors.fill: panel
    visible: {
      var pv = panel.PathView.view;
      return pv ? pv.edShowWrapperBounds : false;
    }
    z: 10001

    // Outer border — orange
    Rectangle {
      anchors.fill: parent
      color: "transparent"
      border.color: "#ff9933"
      border.width: vpx(2)
      opacity: 0.85
    }

    // Corner dots
    Repeater {
      model: [
        {ax: 0, ay: 0, xo: 0,  yo: 0 },
        {ax: 1, ay: 0, xo: -8, yo: 0 },
        {ax: 0, ay: 1, xo: 0,  yo: -8},
        {ax: 1, ay: 1, xo: -8, yo: -8}
      ]
      delegate: Rectangle {
        x: modelData.ax * wrapBoundsOverlay.width  + vpx(modelData.xo)
        y: modelData.ay * wrapBoundsOverlay.height + vpx(modelData.yo)
        width: vpx(8); height: vpx(8)
        color: "#ff9933"; opacity: 0.9
      }
    }

    // Transform origin indicator at bottom right
    Rectangle {
      anchors.top: parent.bottom
      anchors.right: parent.right
      anchors.topMargin: vpx(3)
      width: wrapLbl.contentWidth + vpx(10); height: vpx(16)
      color: Qt.rgba(0,0,0,0.72)
      border.color: "#ff9933"; border.width: vpx(1)
      radius: vpx(2)
      Text {
        id: wrapLbl
        anchors.centerIn: parent
        font.pixelSize: vpx(9); color: "#ffbb66"
        font.family: "monospace"
        text: {
          var pv = panel.PathView.view;
          var si = Math.round(panel.PathView.screenIndex);
          var orig = si < 0 ? "Right" : (si > 0 ? "Left" : "Center");
          var cx = pv ? Math.round(pv.edLeftCorrectX)  : 0;
          var rx = pv ? Math.round(pv.edRightCorrectX) : 0;
          var cy = pv ? Math.round(pv.edLeftCorrectY)  : 0;
          var ry = pv ? Math.round(pv.edRightCorrectY) : 0;
          var offX = si < 0 ? cx : (si > 0 ? rx : 0);
          var offY = si < 0 ? cy : (si > 0 ? ry : 0);
          return "wrap [" + si + "] orig:" + orig + "  Δx:" + offX + "  Δy:" + offY;
        }
      }
    }
  }
}
