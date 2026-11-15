#!/usr/bin/env python3
"""Read an Xbox 360 XEX2 whose PE image is not encrypted: sections and strings.

    python3 xex_strings.py IN.xex
    python3 xex_strings.py IN.xex --grep Tone
    python3 xex_strings.py IN.xex --out strings.txt

An XEX2 starts with a big-endian header: magic, module flags, PE offset,
reserved, security offset, optional header count, then that many (key, value)
pairs. The PE image at the PE offset is little-endian like any PE - `MZ`, a DOS
header whose `e_lfanew` points at `PE\\0\\0`, a COFF header, and a section table.

Some images have their whole PE encrypted (the 2010 editor does) and nothing
here applies; others ship the PE headers and their section data in the clear
(the 2008 editor does), which is how its .rdata yields the animation, shader and
tone-slot names the editor was built around.
"""
import re
import struct
import sys

STRING = re.compile(rb"[ -~\t]{5,}")


def read_pe(path):
    """({section: (bytes, offset)}, info) or raise ValueError if encrypted."""
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:4] != b"XEX2":
        raise ValueError("not a XEX2")
    flags, pe_offset, _, security, count = struct.unpack_from(">5I", data, 4)
    if pe_offset >= len(data) or data[pe_offset:pe_offset + 2] != b"MZ":
        raise ValueError("PE image at %d is not an MZ header - encrypted" % pe_offset)
    lfanew = struct.unpack_from("<I", data, pe_offset + 0x3C)[0]
    coff = pe_offset + lfanew
    if data[coff:coff + 4] != b"PE\x00\x00":
        raise ValueError("no PE signature at %d" % coff)
    machine, sections, stamp, _, _, opt_size = struct.unpack_from("<HHIIIH", data, coff + 4)
    table = coff + 24 + opt_size
    found = {}
    order = []
    for i in range(sections):
        at = table + i * 40
        if at + 40 > len(data):
            break
        name = data[at:at + 8].rstrip(b"\x00").decode("latin-1")
        _, _, raw_size, raw_ptr = struct.unpack_from("<IIII", data, at + 8)
        blob = data[pe_offset + raw_ptr:pe_offset + raw_ptr + raw_size]
        found[name] = blob
        order.append((name, raw_size, pe_offset + raw_ptr))
    info = {
        "flags": flags, "pe_offset": pe_offset, "security": security,
        "headers": count, "machine": machine, "timestamp": stamp,
        "sections": order,
    }
    return found, info


def strings(blob):
    return [m.group().decode("latin-1") for m in STRING.finditer(blob)]


def main(argv):
    if not argv:
        print(__doc__)
        return 1
    path = argv[0]
    try:
        sections, info = read_pe(path)
    except ValueError as error:
        print("%s: %s" % (path, error))
        return 1
    pattern = None
    out = None
    if "--grep" in argv:
        pattern = argv[argv.index("--grep") + 1]
    if "--out" in argv:
        out = argv[argv.index("--out") + 1]
    lines = ["# %s - PE at %d, machine %04x, %d optional headers, timestamp %08x" % (
        path, info["pe_offset"], info["machine"], info["headers"], info["timestamp"])]
    for name, size, offset in info["sections"]:
        lines.append("## %s (%d bytes at %d)" % (name, size, offset))
        lines.extend(strings(sections[name]))
    if pattern:
        hits = [line for line in lines if not line.startswith("#")
                and not line.startswith("##") and pattern in line]
        print("\n".join(hits[:200]))
        print("\n%d matches for %r" % (len(hits), pattern))
    elif out:
        open(out, "w").write("\n".join(lines) + "\n")
        print("%s -> %s (%d lines)" % (path, out, len(lines)))
    else:
        print("\n".join(lines[:40]))
        print("\n%d lines total; use --out or --grep" % len(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
