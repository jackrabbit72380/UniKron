#!/usr/bin/env python3
"""Read an XIP0 dashboard package: header, then a VRML/X3D scene as plain text.

    python3 xip_scene.py IN.xip
    python3 xip_scene.py --all SRCDIR

An XIP0 is a 12-byte header (magic, header size, dimensions, data size) followed
by uncompressed scene text in the dashboard's X3D dialect:

    DEF Music_Arm Transform
    {
        children [ Shape { appearance Appearance { material MaxMaterial
                   { name "DarkenBacking" } }
                   geometry DEF MU_backing_cd-FACES Mesh
                   { url "MU_backing_cd-FACES.xm" } } ]
        translation -0.2488 -0.6646 -1.2100
    }

The geometry urls point at the `.xm` meshes sitting beside the package, which is
what those files are: one mesh each, named `<node>-FACES.xm`.
"""
import os
import re
import struct
import sys

DEF = re.compile(r"DEF\s+([A-Za-z0-9_.\-]+)\s+(\w+)")
URL = re.compile(r'url\s+"([^"]+)"')
MATERIAL = re.compile(r'name\s+"([^"]+)"')
NODE_TYPES = ("Transform", "Shape", "Appearance", "Mesh", "Material", "Group",
              "Viewpoint", "DirectionalLight", "PointLight", "Texture",
              "ImageTexture", "Script")


def read_scene(path):
    """(scene text, header fields, error) for one package."""
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:4] != b"XIP0":
        return None, None, "not an XIP0"
    header, dims, size = struct.unpack_from("<3I", data, 4)
    if header >= len(data):
        return None, None, "header %d larger than file" % header
    body = data[header:header + size]
    return body.decode("latin-1"), (header, dims, size), None


def summarise(path):
    text, fields, error = read_scene(path)
    if error:
        return {"path": path, "error": error}
    defs = DEF.findall(text)
    nodes = {}
    for _, kind in defs:
        if kind in NODE_TYPES:
            nodes[kind] = nodes.get(kind, 0) + 1
    urls = URL.findall(text)
    materials = MATERIAL.findall(text)
    base = os.path.dirname(path)
    # Meshes sit in a folder named after the package, beside it: music2.xip
    # resolves its geometry from music2/MU_backing_cd-FACES.xm.
    stem = os.path.splitext(os.path.basename(path))[0]
    dirs = [base, os.path.join(base, stem)]
    missing = [u for u in urls
               if not any(os.path.exists(os.path.join(d, u)) for d in dirs)]
    return {
        "path": path,
        "header": fields[0],
        "dimensions": "%dx%d" % (fields[1] & 0xFFFF, fields[1] >> 16),
        "bytes": fields[2],
        "defs": len(defs),
        "nodes": nodes,
        "urls": urls,
        "materials": sorted(set(materials)),
        "missing": missing,
        "lines": text.count("\n") + 1,
    }


def main(argv):
    if len(argv) == 1 and argv[0] != "--all":
        info = summarise(argv[0])
        if "error" in info:
            print("%s: %s" % (info["path"], info["error"]))
            return 1
        print("%s  %s  %d bytes  %d definitions  %d lines" % (
            os.path.basename(info["path"]), info["dimensions"], info["bytes"],
            info["defs"], info["lines"]))
        print("  nodes:", ", ".join("%s %d" % kv for kv in sorted(info["nodes"].items())))
        print("  materials:", ", ".join(info["materials"]))
        print("  geometry: %d references" % len(info["urls"]))
        for url in info["urls"]:
            flag = "MISSING" if url in info["missing"] else "ok"
            print("    %-40s %s" % (url, flag))
        return 0

    if len(argv) == 2 and argv[0] == "--all":
        source = argv[1]
        packages = []
        for base, _, files in os.walk(source):
            for name in sorted(files):
                if name.lower().endswith(".xip"):
                    packages.append(os.path.join(base, name))
        total_urls = total_missing = total_defs = 0
        for path in sorted(packages):
            info = summarise(path)
            if "error" in info:
                print("%-44s %s" % (os.path.basename(path), info["error"]))
                continue
            total_urls += len(info["urls"])
            total_missing += len(info["missing"])
            total_defs += info["defs"]
            print("%-44s %-9s %7d B %5d defs %3d refs %s" % (
                os.path.basename(path), info["dimensions"], info["bytes"],
                info["defs"], len(info["urls"]),
                "" if not info["missing"] else "MISSING %d" % len(info["missing"])))
        print("\n%d packages, %d definitions, %d geometry references, %d missing" % (
            len(packages), total_defs, total_urls, total_missing))
        return 0

    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
