"""Find a string in a PE and disassemble the code that uses it.

The Recomp builds of the avatar editor ship without a COFF symbol table but with
their format strings intact, plus full C++ mangled names in .rdata. That is
enough to get from "which code reads a blend shape" to its instructions:
locate the string, scan .text for a rip-relative reference to it, disassemble a
window around the hit.

    python3 re_pe.py avatareditor.exe "Failed to load avatar blend shape"
    python3 re_pe.py avatareditor.exe --at 0x1400f1234 --bytes 400
    python3 re_pe.py avatareditor.exe --strings "blend"
"""

import argparse
import re
import struct
import subprocess
import sys

BASE = 0x140000000


def sections(path):
    """(name, file offset, virtual address, size) for every section."""
    with open(path, "rb") as fh:
        data = fh.read(0x400)
    pe = struct.unpack_from("<I", data, 0x3C)[0]
    assert data[pe:pe + 4] == b"PE\0\0", "not a PE"
    count = struct.unpack_from("<H", data, pe + 6)[0]
    opt_size = struct.unpack_from("<H", data, pe + 20)[0]
    table = pe + 24 + opt_size
    out = []
    for i in range(count):
        off = table + i * 40
        name = data[off:off + 8].rstrip(b"\0").decode("ascii", "replace")
        vsize, vaddr, rawsize, rawptr = struct.unpack_from("<IIII", data, off + 8)
        out.append((name, rawptr, BASE + vaddr, vsize or rawsize))
    return out


def read_section(path, name):
    with open(path, "rb") as fh:
        blob = fh.read()
    for sec, rawptr, va, size in sections(path):
        if sec == name:
            return blob[rawptr:rawptr + size], va
    raise SystemExit("no section %s" % name)


def find_string(path, needle):
    """Every virtual address where the string occurs."""
    rdata, rdata_va = read_section(path, ".rdata")
    hits = []
    start = 0
    while True:
        at = rdata.find(needle.encode(), start)
        if at < 0:
            break
        hits.append(rdata_va + at)
        start = at + 1
    return hits


def xrefs(path, target):
    """Where .text loads the address `target` with a rip-relative instruction."""
    text, text_va = read_section(path, ".text")
    out = []
    for i in range(len(text) - 7):
        # REX.W lea r64, [rip+disp32]: 48 8d 05/0d/15/1d/25/2d/35/3d
        if text[i] == 0x48 and text[i + 1] == 0x8D and (text[i + 2] & 0xC7) == 0x05:
            disp = struct.unpack_from("<i", text, i + 3)[0]
            if text_va + i + 7 + disp == target:
                out.append(text_va + i)
    return out


def functions(path):
    """(begin, end) virtual addresses from .pdata, sorted."""
    with open(path, "rb") as fh:
        blob = fh.read()
    for name, rawptr, va, size in sections(path):
        if name != ".pdata":
            continue
        out = []
        for off in range(0, size - 11, 12):
            begin, end, _unwind = struct.unpack_from("<III", blob, rawptr + off)
            if begin and end > begin:
                out.append((BASE + begin, BASE + end))
        return sorted(out)
    return []


def function_at(path, va):
    """The (begin, end) of the function containing va, or None."""
    for begin, end in functions(path):
        if begin <= va < end:
            return begin, end
    return None


def disassemble(path, va, size):
    out = subprocess.run(["objdump", "-d", "--no-show-raw-insn",
                          "--start-address=0x%x" % va,
                          "--stop-address=0x%x" % (va + size), path],
                         capture_output=True, text=True)
    return out.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("exe")
    parser.add_argument("string", nargs="?")
    parser.add_argument("--at", type=lambda s: int(s, 0), help="disassemble at this address")
    parser.add_argument("--function", type=lambda s: int(s, 0),
                        help="disassemble the whole function containing this address")
    parser.add_argument("--bytes", type=int, default=600)
    parser.add_argument("--strings", help="list strings containing this text")
    parser.add_argument("--sections", action="store_true")
    args = parser.parse_args()

    if args.sections:
        for name, raw, va, size in sections(args.exe):
            print("%-10s file 0x%08x va 0x%x size 0x%x" % (name, raw, va, size))
        return 0
    if args.strings:
        rdata, _ = read_section(args.exe, ".rdata")
        text = rdata.decode("latin-1")
        for m in re.finditer(re.escape(args.strings.encode().decode()), text, re.I):
            chunk = text[m.start():m.start() + 90].split("\0")[0]
            print("0x%x  %s" % (find_string(args.exe, chunk)[0], chunk))
        return 0
    if args.at:
        print(disassemble(args.exe, args.at, args.bytes))
        return 0
    if args.function:
        bounds = function_at(args.exe, args.function)
        if not bounds:
            print("no function contains 0x%x" % args.function)
            return 1
        begin, end = bounds
        print("function 0x%x..0x%x (%d bytes)" % (begin, end, end - begin))
        print(disassemble(args.exe, begin, end - begin))
        return 0

    hits = find_string(args.exe, args.string)
    print("%d string occurrence(s)" % len(hits))
    for va in hits:
        refs = xrefs(args.exe, va)
        print("\nstring at 0x%x, %d xref(s): %s"
              % (va, len(refs), " ".join("0x%x" % r for r in refs)))
        for ref in refs:
            start = max(BASE, ref - 0x180)
            print(disassemble(args.exe, start, args.bytes))
    return 0


if __name__ == "__main__":
    sys.exit(main())
