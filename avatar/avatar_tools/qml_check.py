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

    # Go through the editor's own setItem: poking `state` leaves _layers stale,
    # which made this check report a stack the editor never showed.
    from PyQt5.QtCore import Q_ARG as _QARG, QMetaObject as _QMO, Qt as _Qt

    for decal_id in ("15_face", "16_face-paint", "45_facial-hair"):
        decal = next((c for c in v if c.get("id") == decal_id), None)
        files = (decal or {}).get("files") or []
        if not files:
            continue
        obj.setProperty("usePackArt", True)
        _QMO.invokeMethod(obj, "setItem", _Qt.DirectConnection,
                          _QARG("QVariant", decal_id), _QARG("QVariant", files[0]))
        QTimer.singleShot(0, app.quit)
        app.exec_()
        shown = layer_ids()
        print("  pack mode, %s chosen -> layers %s%s"
              % (decal_id, shown, "" if decal_id in shown else "  (not a layer)"))
        if decal_id in shown:
            row = next(r for r in (obj.property("_layers").toVariant()) if r.get("id") == decal_id)
            print("    its url: %s" % row.get("url"))

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
        rows = obj.property("_layers")
        rows = rows.toVariant() if hasattr(rows, "toVariant") else rows
        for row in (rows or [])[:6]:
            if row.get("id") == "40_shirt":
                print("    shirt layer url: %s" % row.get("url"))

    # A real pack item, so the plate path is exercised rather than the fallback.
    plate_dir = os.path.join(os.path.dirname(path), "pack_plates", "40_shirt")
    if os.path.isdir(plate_dir):
        plate = sorted(f for f in os.listdir(plate_dir) if f.endswith(".png"))
        if plate:
            obj.setProperty("usePackArt", True)
            # setItem is the editor's own path: it updates state *and* rebuilds
            # the layer stack, which a property poke does not.
            from PyQt5.QtCore import QMetaObject, Q_ARG, Qt
            QMetaObject.invokeMethod(obj, "setItem", Qt.DirectConnection,
                                     Q_ARG("QVariant", "40_shirt"),
                                     Q_ARG("QVariant", plate[0]))
            QTimer.singleShot(0, app.quit)
            app.exec_()
            rows = obj.property("_layers")
            rows = rows.toVariant() if hasattr(rows, "toVariant") else rows
            for row in (rows or []):
                if row.get("id") == "40_shirt":
                    print("  pack item %s -> plate url %s" % (plate[0], row.get("url")))

    # Female mode: its own body, its own seeds, its own plate and set trees, and
    # a strip without the male-only items.
    obj.setProperty("gender", "female")
    QTimer.singleShot(0, app.quit)
    app.exec_()
    st = obj.property("state")
    st = st.toVariant() if hasattr(st, "toVariant") else st
    print("  female: state %s" % (st,))
    print("  female: plate folder %s" % obj.property("packPlateFolder").toLocalFile())
    print("  female: turntable root %r" % obj.property("turntableRoot"))
    cats = obj.property("categories")
    cats = cats.toVariant() if hasattr(cats, "toVariant") else cats
    male_only = ["malebody.png", "grunge-trainers.png", "jacket-with-sweater.png"]
    seen = [f for c in (cats or []) for f in (c.get("files") or [])]
    leaked = [f for f in male_only if f in seen]
    if leaked:
        problems.append("female strip still offers %s" % leaked)
    print("  female: male-only items in the strip: %s" % (leaked or "none"))
    for c in (cats or []):
        if c.get("id") == "40_shirt":
            print("  female: 40_shirt has %d items, first %r"
                  % (len(c.get("files") or []), (c.get("files") or [None])[0]))
    rows = obj.property("_layers")
    rows = rows.toVariant() if hasattr(rows, "toVariant") else rows
    for row in (rows or []):
        print("    female layer %s -> %s" % (row.get("id"), row.get("url")))
    print("  female: stageVariant %r" % obj.property("stageVariant"))

sys.exit(1 if problems else 0)
