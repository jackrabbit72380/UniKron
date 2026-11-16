"""Extract the XTL effects (`.updb` blobs) from the 2008 editor's XEX.

Each blob starts with the shader's build path, then a big-endian table of the
effect's parameters, then the compiled shader itself, which is Xbox 360 GPU
microcode: it begins with the Xenos container magic `0x102A1100`, not with a
D3D9 token stream. That matters: the `ps_3_0` string in the table is the XTL
target the source was compiled for, not an instruction stream this project can
disassemble.

What is recovered here is the parameter table - names, in declaration order -
plus each shader binary, which is what identifies how the editor builds a body
and a head. The bodies are written out untouched for anyone with a Xenon
disassembler; nothing is guessed at.

    python3 xtl_effects.py avatareditor.xex out_dir
"""

import json
import os
import re
import struct
import sys

XENOS_MAGIC = b"\x10\x2a\x11\x01"          # 0x102A1100, big-endian
PATH_PATTERN = re.compile(rb"[A-Za-z0-9_.:/\\-]+\.updb\x00")
NAME_PATTERN = re.compile(rb"[A-Za-z_][A-Za-z0-9_]{2,}\x00")
TARGETS = {b"ps_3_0", b"vs_3_0"}


def is_text(data):
    return all(32 <= b < 127 for b in data)


def find_blobs(data):
    """Return [(offset, end, path)] for every `.updb` path string in the image."""
    hits = [(m.start(), m.end()) for m in PATH_PATTERN.finditer(data)]
    blobs = []
    for index, (start, end) in enumerate(hits):
        stop = hits[index + 1][0] if index + 1 < len(hits) else len(data)
        blobs.append((start, stop, data[start:end - 1].decode("latin-1")))
    return blobs


def parameters(block):
    """Identifiers declared between the effect's path and its target marker."""
    return re.findall(rb"[A-Za-z_][A-Za-z0-9_]{2,39}(?=\x00)", block) and \
        [m.decode("latin-1") for m in re.findall(rb"[A-Za-z_][A-Za-z0-9_]{2,39}(?=\x00)", block)]


def marker_offset(body, start=0):
    for target in (b"ps_3_0\x00", b"vs_3_0\x00"):
        found = body.find(target, start)
        if found >= 0:
            return found
    return -1


def extract(data, start, stop, path):
    body = data[start:min(stop, start + 0x4000)]
    names_end = body.find(b"\x00") + 1
    marker = marker_offset(body, names_end)
    magic = body.find(XENOS_MAGIC, marker if marker >= 0 else names_end)
    table = body[names_end:marker] if marker >= 0 else b""
    record = {
        "path": path,
        "name": os.path.basename(path.replace("\\", "/")),
        "offset": start,
        "size": stop - start,
        "parameters": parameters(table),
        "footer": [],
        "bytes": None,
    }
    if magic >= 0:
        record["footer"] = list(struct.unpack_from(">8I", body, magic))
    record["bytes"] = body
    return record


def main(argv):
    if len(argv) != 3:
        print(__doc__.strip())
        return 2
    source, out_dir = argv[1], argv[2]
    data = open(source, "rb").read()
    os.makedirs(out_dir, exist_ok=True)
    records = []
    for start, stop, path in find_blobs(data):
        record = extract(data, start, stop, path)
        stem = os.path.splitext(record["name"])[0]
        with open(os.path.join(out_dir, stem + ".updb"), "wb") as handle:
            handle.write(record["bytes"])
        del record["bytes"]
        records.append(record)
    with open(os.path.join(out_dir, "effects.json"), "w") as handle:
        json.dump(records, handle, indent=1)

    print(f"{len(records)} effects")
    for record in records:
        footer = " ".join(f"{v:#x}" for v in record["footer"][:3]) or "-"
        print(f"  {record['offset']:#08x}  {record['name']:<36} {record['size']:>6} B"
              f"  {len(record['parameters']):>2} params  [{footer}]")
        print("      " + ", ".join(record["parameters"]))
    return 0 if records else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
