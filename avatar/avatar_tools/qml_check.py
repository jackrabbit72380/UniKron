"""Load a QML file offscreen and report every error Qt raises."""

import os
import sys

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

from PyQt5.QtCore import QUrl, QCoreApplication, QTimer  # noqa: E402
from PyQt5.QtGui import QGuiApplication  # noqa: E402
from PyQt5.QtQml import QQmlEngine, QQmlComponent  # noqa: E402

app = QGuiApplication(sys.argv)

path = os.path.abspath(sys.argv[1])
engine = QQmlEngine()
component = QQmlComponent(engine, QUrl.fromLocalFile(path))
obj = component.create()

problems = 0
if component.isError():
    for err in component.errors():
        problems += 1
        print("ERROR %s:%s: %s" % (err.url().toString() or path, err.line(), err.toString()))
if obj is None:
    print("FAILED to create %s" % path)
    sys.exit(1)

print("created %s (%s)" % (os.path.basename(path), obj.metaObject().className()))

# Report what the object actually exposes, when it exposes anything we know.
for name in ("categories", "usePackArt", "packArtFolder", "assetsFolder"):
    if obj.property(name) is not None:
        value = obj.property(name)
        try:
            shown = len(value) if hasattr(value, "__len__") else value
        except Exception:
            shown = value
        print("  %s = %s" % (name, shown))

if obj.property("usePackArt") is not None:
    obj.setProperty("usePackArt", True)
    QTimer.singleShot(0, app.quit)
    app.exec_()
    cats = obj.property("categories")
    v = cats.toVariant() if hasattr(cats, "toVariant") else cats
    print("  after usePackArt=true: %d categories" % (len(v) if v else -1))
    if v:
        for c in v[:4]:
            print("    %s (%d files)" % (c.get("id"), len(c.get("files") or [])))
    state = obj.property("state")
    state = state.toVariant() if hasattr(state, "toVariant") else state
    print("  state after switch: %s" % (state,))
    missing = []
    folder = obj.property("packArtFolder").toLocalFile()
    for key, name in (state or {}).items():
        cat = next((c for c in v if c.get("id") == key), None)
        if cat and name and not os.path.exists(os.path.join(folder, key, name)):
            missing.append((key, name))
    print("  picks that do not exist under pack_art/: %d %s" % (len(missing), missing[:4]))

sys.exit(1 if problems else 0)
