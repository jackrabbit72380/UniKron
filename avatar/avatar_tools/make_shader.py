"""Rebuild the Qt 6 shader pack used by TintedMask.qml.

Qt 6 will not compile a GLSL string at run time: `ShaderEffect.fragmentShader`
must be a URL to a .qsb pack. The source is `shaders/tintedmask.frag` (Vulkan
GLSL) and the pack is `shaders/tintedmask.frag.qsb`; this script runs `qsb` over
it.

`qsb` comes with Qt's Shader Tools module. Set QSB to its path, or have it on
PATH:

    QSB=/usr/lib/qt6/bin/qsb python3 avatar_tools/make_shader.py

The pack carries GLSL 100 es / 120 / 150 / 330 (desktop OpenGL, GLES), HLSL 5.0
(Direct3D) and MSL 1.2 (Metal), so the same file serves every backend Qt Quick
may pick.
"""
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
AVATAR = os.path.dirname(HERE)
SOURCE = os.path.join(AVATAR, "shaders", "tintedmask.frag")
OUTPUT = os.path.join(AVATAR, "shaders", "tintedmask.frag.qsb")


def find_qsb():
    explicit = os.environ.get("QSB")
    if explicit:
        return explicit
    for name in ("qsb",):
        found = shutil.which(name)
        if found:
            return found
    for guess in ("/usr/lib/qt6/bin/qsb", "/usr/lib/qt5/bin/qsb", "/usr/lib/x86_64-linux-gnu/qt6/bin/qsb"):
        if os.path.exists(guess):
            return guess
    return None


def main():
    qsb = find_qsb()
    if qsb is None:
        print("qsb not found; set QSB=/path/to/qsb (Qt Shader Tools)")
        return 1
    command = [qsb,
               "--glsl", "100 es,120,150,330",
               "--hlsl", "50",
               "--msl", "12",
               "-o", OUTPUT,
               SOURCE]
    print(" ".join(command))
    result = subprocess.run(command, capture_output=True, text=True)
    if result.stdout.strip():
        print(result.stdout.strip())
    if result.returncode != 0:
        print(result.stderr.strip())
        return result.returncode
    print("%s: %d bytes" % (os.path.relpath(OUTPUT, AVATAR), os.path.getsize(OUTPUT)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
