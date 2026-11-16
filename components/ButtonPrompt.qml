import QtQuick 2.8
import QtGraphicalEffects 1.0

Item {
  id: prompt
  property string button
  property string text
  property var sound

  // NEW: This signal is what allows the button to notify the page
  signal buttonTriggered(string key)

  // Button theme handling
  property string buttonTheme: api.memory.get("currentButton") || "default"
  property string buttonBase:  "../assets/images/buttons/" + buttonTheme + "/"

  Timer {
    interval: 1000; running: true; repeat: true
    onTriggered: {
      var t = api.memory.get("currentButton") || "default"
      if (t !== parent.buttonTheme) parent.buttonTheme = t
    }
  }

  width: icon.width + label.contentWidth + label.anchors.leftMargin
  height: icon.height
  property bool stateVisible: true

  function onPressed(event) {
    if (enabled) {
      event.accepted = true
      ringAnimation.start()
      sound.play()

      // NEW: Forward the button press upward
      prompt.buttonTriggered(prompt.button)
    }
  }

  SequentialAnimation {
    id: ringAnimation
    ParallelAnimation {
      NumberAnimation { target: icon; property: "scale"; from: 1; to: 1.1; duration: 120 }
      NumberAnimation { target: ring; property: "opacity"; from: 0; to: 1; duration: 120 }
    }
    ParallelAnimation {
      NumberAnimation { target: icon; property: "scale"; from: 1.1; to: 1; duration: 120 }
      NumberAnimation { target: ring; property: "scale"; from: 1; to: 1.3; duration: 120 }
      NumberAnimation { target: ring; property: "opacity"; from: 1; to: 0; duration: 120 }
    }
    NumberAnimation { target: ring; property: "scale"; to: 1; duration: 0 }
    NumberAnimation { target: icon; property: "scale"; to: 1; duration: 0 }
  }

  Image {
    id: icon
    source: buttonBase + button + ".png"
    width: vpx(32)
    height: vpx(32)
  }

  Image {
    id: ring
    source: buttonBase + "ring.png"
    width: vpx(32)
    height: vpx(32)
    opacity: 0
    scale: 1
  }

  StyledText {
    id: label
    anchors.left: icon.right
    anchors.verticalCenter: icon.verticalCenter
    anchors.leftMargin: vpx(4)
    text: parent.text
    font.pixelSize: vpx(19)
    transform: Translate { y: vpx(1) }
  }

  MouseArea {
    id: promptMouseArea
    x: 0; y: 0
    width: Math.max(prompt.width, vpx(44))
    height: vpx(44)
    anchors.verticalCenter: icon.verticalCenter
    cursorShape: Qt.PointingHandCursor
    z: 10
    onClicked: {
      mouse.accepted = true
      if (prompt.enabled) {
        ringAnimation.start()
        sound.play()
        prompt.buttonTriggered(prompt.button)
      }
    }
  }

  states: [
    State { name: "Visible"; when: enabled },
    State { name: "Invisible"; when: !enabled }
  ]

  transitions: [
    Transition {
      to: "Visible"
      SequentialAnimation {
        NumberAnimation { target: prompt; property: "width"; to: icon.width + label.contentWidth + label.anchors.leftMargin; duration: 100 }
        ParallelAnimation {
          NumberAnimation { target: icon; property: "scale"; to: 1; duration: 300; easing.type: Easing.OutBounce }
          NumberAnimation { target: label; property: "opacity"; to: 1; duration: 300 }
        }
      }
    },
    Transition {
      to: "Invisible"
      SequentialAnimation {
        ParallelAnimation {
          NumberAnimation { target: icon; property: "scale"; to: 0; duration: 300; easing.type: Easing.InBack }
          NumberAnimation { target: label; property: "opacity"; to: 0; duration: 300 }
        }
        NumberAnimation { target: prompt; property: "width"; to: 0; duration: 100 }
      }
    }
  ]
}

