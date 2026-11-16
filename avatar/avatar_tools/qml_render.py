"""Load a QML file offscreen, render it, and save a PNG."""

import os
import sys

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

from PyQt5.QtCore import QTimer, QUrl  # noqa: E402
from PyQt5.QtGui import QColor, QGuiApplication  # noqa: E402
from PyQt5.QtQuick import QQuickView  # noqa: E402

app = QGuiApplication(sys.argv[:1])

path = os.path.abspath(sys.argv[1])
out = os.path.abspath(sys.argv[2])
width = int(sys.argv[3]) if len(sys.argv) > 3 else 1280
height = int(sys.argv[4]) if len(sys.argv) > 4 else 720

view = QQuickView()
view.setResizeMode(QQuickView.SizeRootObjectToView)
view.setColor(QColor("black"))
view.resize(width, height)
view.setSource(QUrl.fromLocalFile(path))

errors = [e.toString() for e in view.errors()]
for err in errors:
    print("ERROR", err)
if not view.rootObject():
    print("no root object")
    sys.exit(1)

view.show()


def shoot():
    image = view.grabWindow()
    if image.isNull():
        print("grab returned a null image")
        app.quit()
        return
    image.save(out)
    print("wrote %s (%dx%d)" % (out, image.width(), image.height()))
    app.quit()


QTimer.singleShot(1200, shoot)
app.exec_()
