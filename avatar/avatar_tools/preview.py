#!/usr/bin/env python3
"""Runs the avatar editor standalone and gives it somewhere to save to.

    python avatar_tools/preview.py

Saved avatars go to saved/avatar.json, portraits to saved/portrait-<time>.png.
The editor itself is pure QML: this file only provides the window and the two
small file operations.  In Pegau, replace this with your own backend that
answers `saveAvatar`, `loadAvatar` and `portraitPath`, or drop the editor in
with `import "avatar_theme/avatar"` and wire `onSaveRequested` / `onPortraitReady`.
"""
import datetime
import json
import os
import sys

from PySide6.QtCore import Property, QObject, QUrl, Signal, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SAVED = os.path.join(ROOT, "saved")
AVATAR_FILE = os.path.join(SAVED, "avatar.json")


class Backend(QObject):
    lastSavedChanged = Signal()

    def __init__(self):
        super().__init__()
        self._last_saved = ""
        os.makedirs(SAVED, exist_ok=True)

    @Property(str, notify=lastSavedChanged)
    def gamerTag(self):
        return os.environ.get("PEGA_GAMERTAG", "Player")

    @Slot("QVariant")
    def saveAvatar(self, state):
        data = state.toVariant() if hasattr(state, "toVariant") else dict(state or {})
        data = {str(k): str(v) for k, v in data.items()}
        try:
            with open(AVATAR_FILE, "w", encoding="utf-8") as fh:
                json.dump(data, fh, indent=2)
            self._last_saved = "saved avatar.json"
        except OSError as exc:
            self._last_saved = f"save failed: {exc}"
        self.lastSavedChanged.emit()

    @Slot(result="QVariant")
    def loadAvatar(self):
        try:
            with open(AVATAR_FILE, encoding="utf-8") as fh:
                return json.load(fh)
        except (OSError, ValueError):
            return {}

    @Slot(result=str)
    def portraitPath(self):
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        path = os.path.join(SAVED, f"portrait-{stamp}.png")
        self._last_saved = f"saved {os.path.basename(path)}"
        self.lastSavedChanged.emit()
        return QUrl.fromLocalFile(path).toString()


def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Avatar Editor")
    engine = QQmlApplicationEngine()
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)
    engine.addImportPath(ROOT)
    engine.load(QUrl.fromLocalFile(os.path.join(ROOT, "avatar.qml")))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
