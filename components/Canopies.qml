import QtQuick 2.8

Item {
  id: canopiesRoot

  property string canopyName:    ""
  property bool   canopyVisible: false
  property bool   _bootDone:     false

  anchors.fill: parent
  z: 500

  Timer {
    interval: 2500; repeat: false; running: true
    onTriggered: {
      canopiesRoot._bootDone = true
      if (canopiesRoot.canopyVisible) showAnim.start()
    }
  }

  ParallelAnimation {
    id: showAnim
    NumberAnimation { target: topBanner;    property: "anchors.topMargin";    from: vpx(-300); to: 0; duration: 320; easing.type: Easing.OutQuad }
    NumberAnimation { target: topBanner;    property: "opacity";              from: 0;         to: 1; duration: 80;  easing.type: Easing.OutQuad }
    NumberAnimation { target: bottomFooter; property: "anchors.bottomMargin"; from: vpx(-300); to: 0; duration: 320; easing.type: Easing.OutQuad }
    NumberAnimation { target: bottomFooter; property: "opacity";              from: 0;         to: 1; duration: 80;  easing.type: Easing.OutQuad }
  }

  ParallelAnimation {
    id: hideAnim
    NumberAnimation { target: topBanner;    property: "anchors.topMargin";    to: vpx(-300); duration: 280; easing.type: Easing.InQuad }
    NumberAnimation { target: topBanner;    property: "opacity";              to: 0;         duration: 280; easing.type: Easing.InQuad }
    NumberAnimation { target: bottomFooter; property: "anchors.bottomMargin"; to: vpx(-300); duration: 280; easing.type: Easing.InQuad }
    NumberAnimation { target: bottomFooter; property: "opacity";              to: 0;         duration: 280; easing.type: Easing.InQuad }
  }

  onCanopyVisibleChanged: {
    if (!_bootDone) return
    if (canopyVisible) { hideAnim.stop(); showAnim.start() }
    else               { showAnim.stop(); hideAnim.start() }
  }

  // ── Top banner ───────────────────────────────────────────────────
  Image {
    id: topBanner
    visible: canopiesRoot._bootDone
    source: canopiesRoot.canopyName !== ""
              ? ("../assets/images/canopies/" + canopiesRoot.canopyName + "/banner.png")
              : ""
    fillMode: Image.PreserveAspectFit
    width:    parent.width
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    opacity: 0
    anchors.topMargin: vpx(-300)
  }

  // ── Bottom footer ────────────────────────────────────────────────
  Image {
    id: bottomFooter
    visible: canopiesRoot._bootDone
    source: canopiesRoot.canopyName !== ""
              ? ("../assets/images/canopies/" + canopiesRoot.canopyName + "/footer.png")
              : ""
    fillMode: Image.PreserveAspectFit
    width:    parent.width
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    opacity: 0
    anchors.bottomMargin: vpx(-300)
  }
}
