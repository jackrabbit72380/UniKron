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

    # A pack decal sheet must not become a full-frame layer; a drawn beard must.
    def layer_ids():
        ids = obj.property("_layers")
        ids = ids.toVariant() if hasattr(ids, "toVariant") else ids
        return [row.get("id") for row in (ids or [])]

    for decal_id in ("15_face", "16_face-paint", "45_facial-hair"):
        decal = next((c for c in v if c.get("id") == decal_id), None)
        files = (decal or {}).get("files") or []
        if not files:
            continue
        obj.setProperty("usePackArt", True)
        obj.setProperty("state", dict(obj.property("state").toVariant(), **{decal_id: files[0]}))
        QTimer.singleShot(0, app.quit)
        app.exec_()
        leaked = [i for i in layer_ids() if i == decal_id]
        print("  pack mode, %s chosen -> layers %s%s"
              % (decal_id, layer_ids(), "  LEAKED" if leaked else ""))

    # A pack item with a baked set must name it, and the folder must exist.
    shirt = next((c for c in v if c.get("id") == "40_shirt"), None)
    root3d = os.path.join(os.path.dirname(path), "assets", "3d")
    picked = next((f for f in ((shirt or {}).get("files") or [])
                   if os.path.isdir(os.path.join(root3d, "turntable", f[:-4]))), None)
    if picked:
        obj.setProperty("usePackArt", True)
        obj.setProperty("state", dict(obj.property("state").toVariant(),
                                      **{"40_shirt": picked}))
        QTimer.singleShot(0, app.quit)
        app.exec_()
        variant = obj.property("stageVariant")
        frames = os.path.join(root3d, str(variant), "frame_00.png")
        print("  pack mode, 40_shirt=%s -> stageVariant %r, frames %s"
              % (picked, variant, os.path.exists(frames)))
        for name in ("hairVariant", "defaultHairStem", "lastItemCategory"):
            print("    %s = %r" % (name, obj.property(name)))

sys.exit(1 if problems else 0)
