#!/usr/bin/env python3
"""Load the avatar editor offscreen, let it settle, and save a PNG.

    python3 render_editor.py QML OUT.png [--width 1280 --height 800] [--wait 1200]

`qml_check.py` proves the QML creates without errors; this proves what it looks
like, which is the only way to check a screen without a desktop. It needs the
same Qt the editor needs (`PyQt5`), and on a bare image the libraries Qt's
platform plugin depends on (fontconfig, freetype, EGL, X11) can be unpacked
beside the workspace instead of installed.

The window is grabbed after `--wait` milliseconds of event processing, because
the stage loads a wall of images and an early grab catches it half drawn.
"""

import argparse
import os
import sys

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

from PyQt5.QtCore import QMetaObject, QSize, QTimer, QUrl  # noqa: E402
from PyQt5.QtGui import QGuiApplication  # noqa: E402
from PyQt5.QtQml import QQmlComponent, QQmlEngine  # noqa: E402
from PyQt5.QtQuick import QQuickWindow  # noqa: E402


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("qml")
    ap.add_argument("out")
    ap.add_argument("--width", type=int, default=1280)
    ap.add_argument("--height", type=int, default=800)
    ap.add_argument("--wait", type=int, default=1200)
    ap.add_argument("--set", action="append", default=[], metavar="NAME=VALUE",
                    help="set a property on the AvatarEditor before grabbing, e.g. screen=closet")
    ap.add_argument("--start", action="append", default=[], metavar="NAME=VALUE",
                    help="start the editor with this property already set, e.g. gender=female; "
                         "changing gender or usePackArt after load leaves the old seeds")
    ap.add_argument("--screen", default="", help="open this screen on startup")
    ap.add_argument("--category", default="",
                    help="with screen=closet, select the category with this id")
    args = ap.parse_args()

    source = os.path.abspath(args.qml)
    temporary = ""
    if args.start or args.screen:
        # Some properties are read while the editor seeds itself, so setting them
        # afterwards leaves the previous picks in `state` and the stage asks for
        # art that belongs to the other gender or the other art set. This writes a
        # throwaway wrapper that starts the editor with them already in place.
        props = list(args.start)
        if args.screen:
            props.append("screen=" + args.screen)
        qml = ["import QtQuick 2.15", "import QtQuick.Window 2.15", 'import ".."', "",
               "Window {", "    width: %d" % args.width, "    height: %d" % args.height,
               "    visible: true", '    color: "#0f1a05"',
               '    Image {', '        anchors.fill: parent',
               '        source: "../assets/_ui/background.png"',
               "        fillMode: Image.PreserveAspectCrop", "    }",
               "    AvatarEditor {", "        id: editor", "        anchors.fill: parent"]
        for pair in props:
            name, _, value = pair.partition("=")
            if value in ("true", "false") or value.isdigit():
                qml.append("        %s: %s" % (name, value))
            else:
                qml.append('        %s: "%s"' % (name, value))
        qml += ["    }", "}"]
        temporary = os.path.join(os.path.dirname(source), "_render_start.qml")
        with open(temporary, "w", encoding="utf-8") as fh:
            fh.write("\n".join(qml) + "\n")
        source = temporary

    app = QGuiApplication(sys.argv[:1])
    engine = QQmlEngine()
    component = QQmlComponent(engine, QUrl.fromLocalFile(source))
    obj = component.create()
    if component.isError():
        for err in component.errors():
            print("ERROR %s:%s: %s" % (err.url().toString(), err.line(), err.toString()))
    if temporary:
        os.remove(temporary)
    if obj is None:
        return 1

    window = obj if isinstance(obj, QQuickWindow) else None
    if window is None:
        for child in obj.findChildren(QQuickWindow):
            window = child
            break
    if window is None:
        print("no window in %s" % args.qml)
        return 1

    window.resize(args.width, args.height)
    window.show()

    # The editor object is the one that carries `screen`; the harness wraps it in
    # a Window so its properties cannot be set from the command line otherwise.
    editor = None
    for child in obj.findChildren(object):
        if child is not None and hasattr(child, "property") and child.property("screen") is not None:
            editor = child
            break
    if editor is not None:
        for pair in args.set:
            name, _, value = pair.partition("=")
            if value in ("true", "false"):
                editor.setProperty(name, value == "true")
            else:
                try:
                    editor.setProperty(name, int(value))
                except ValueError:
                    editor.setProperty(name, value)
        if args.set:
            # Switching to the pack's art is a startup flag, and the category list
            # is built once from it, so the rebuild has to be asked for.
            QMetaObject.invokeMethod(editor, "rebuildCategories")
        if args.category:
            categories = editor.property("categories")
            if hasattr(categories, "toVariant"):
                categories = categories.toVariant()
            ids = []
            for entry in categories:
                try:
                    ids.append(str(entry["id"]))
                except Exception:
                    ids.append(str(entry))
            if args.category in ids:
                editor.setProperty("categoryIndex", ids.index(args.category))
                print("category %s at index %d" % (args.category, ids.index(args.category)))
            else:
                print("no category %r; have %s" % (args.category, ids))

    def shoot():
        # `QQuickWindow.grabWindow()` comes back 0x0 on the offscreen platform, so
        # grab the scene's content item instead - that path renders in software.
        # PyQt5 exposes only the overload that returns a grab result, whose
        # `ready` signal fires when the image exists.
        def done():
            ok = result.saveToFile(args.out)
            image = result.image()
            print("%s %s (%dx%d)" % ("saved" if ok else "FAILED", args.out,
                                     image.width(), image.height()))
            app.quit()

        result = window.contentItem().grabToImage(QSize(args.width, args.height))
        result.ready.connect(done)

    QTimer.singleShot(args.wait, shoot)
    return app.exec_()


if __name__ == "__main__":
    sys.exit(main())
