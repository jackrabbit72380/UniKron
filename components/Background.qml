import QtQuick.Particles 2.0
import QtQuick 2.8
import QtGraphicalEffects 1.0

Item {
  property string wallpaperName

  // ── Wallpaper controls — set by theme.qml from api.memory ────────
  property bool   wpOn:      true    // show/hide the wallpaper image
  property bool   wpDarkOn:  false   // black overlay (Original Dark)
  property bool   wpGradOn:  false   // bottom-fade gradient on the wallpaper
  property bool   wpRingsOn: true    // animated particle rings
  property int    wpOpacity: 100     // 0–100 overall wallpaper image opacity

  anchors.fill: parent

  // ── Base wallpaper image ─────────────────────────────────────────
  Image {
    id: backgroundImage
    fillMode: Image.PreserveAspectCrop
    anchors.fill: parent
    visible: wpOn
    opacity: wpOpacity / 100
    source: `../assets/images/wallpapers/${wallpaperName}.png`
  }

  // ── Original Dark overlay ────────────────────────────────────────
  Rectangle {
    anchors.fill: parent
    visible: wpDarkOn
    color: "#8C000000"   // 55% black over the wallpaper
  }

  // ── Wallpaper gradient (bottom-fade blend into theme) ────────────
  Rectangle {
    anchors.fill: parent
    visible: wpGradOn
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#00000000" }
      GradientStop { position: 0.45; color: "#22000000" }
      GradientStop { position: 1.0; color: "#CC000000" }
    }
  }

  // ── Particle rings ───────────────────────────────────────────────
  ParticleSystem {
    id: particleSystem
    running: wpRingsOn
  }

  Emitter {
    anchors.right: parent.right
    anchors.top: parent.top
    width: parent.width * .8
    height: parent.height * .8
    system: particleSystem
    enabled: wpRingsOn
    emitRate: 2
    lifeSpan: 10000
    lifeSpanVariation: 4000
    size: vpx(32)
    endSize: vpx(128)
    sizeVariation: vpx(128)
    velocity: AngleDirection {
      angle: 320
      angleVariation: 20
      magnitude: 25
      magnitudeVariation: 5
    }
  }

  ItemParticle {
    system: particleSystem
    opacity: wpRingsOn ? .15 : 0

    delegate: Image {
      width: vpx(256)
      height: width
      NumberAnimation on scale {
        from: Math.random() * 0.125;
        to: Math.random() * (1 - 0.125) + 0.125;
        duration: 14000;
      }
      source: `../assets/images/bgrings/bg_ring${Math.ceil(Math.random()*4)}.png`
    }
  }
}
