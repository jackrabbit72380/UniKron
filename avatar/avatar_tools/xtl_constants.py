#!/usr/bin/env python3
"""Name the data Ghidra left as DAT_ in the XTL avatar renderer's decompilation.

Ghidra imported the renderer as a flat ELF and never defined its string table, so
the decompiled C is full of `DAT_921a1b2c` where a shader parameter name should
be. This reads the same ELF, rebuilds a virtual-address map from its section
headers, and can then

  strings   list every printable string with its VA, optionally filtered
  resolve   rewrite DAT_<va> in the decompiled C to the string it points at
  floats    list runs of plausible float constants (light rigs, colours, FOV)

    python3 xtl_constants.py strings  /tmp/xtlavatar.elf --grep light
    python3 xtl_constants.py resolve  /tmp/xtlavatar.elf /tmp/xtl_corpus/xtl_avatar
    python3 xtl_constants.py floats   /tmp/xtlavatar.elf --grep 0.7
"""
import os
import re
import struct
import sys

SHT_PROGBITS = 1
SHF_ALLOC = 2
PRINTABLE = re.compile(rb"[\x20-\x7e]{4,}")


def sections(elf_path):
    """[(name, vaddr, bytes)] for every allocated section with contents."""
    data = open(elf_path, "rb").read()
    if data[:4] != b"\x7fELF":
        raise SystemExit("%s is not an ELF" % elf_path)
    big = data[5] == 2
    endian = ">" if big else "<"
    shoff, = struct.unpack_from(endian + "I", data, 0x20)
    shentsize, shnum, shstrndx = struct.unpack_from(endian + "HHH", data, 0x2E)
    raw = []
    for i in range(shnum):
        off = shoff + i * shentsize
        name, stype, flags, addr, offset, size = struct.unpack_from(endian + "IIIIII", data, off)
        raw.append((name, stype, flags, addr, offset, size))
    strtab_off = raw[shstrndx][4]
    out = []
    for name_off, stype, flags, addr, offset, size in raw:
        end = data.index(b"\x00", strtab_off + name_off)
        name = data[strtab_off + name_off:end].decode("latin-1")
        if stype != SHT_PROGBITS or not (flags & SHF_ALLOC) or size == 0:
            continue
        out.append((name, addr, data[offset:offset + size]))
    return out


def string_table(elf_path):
    """{vaddr: text} for every printable run of four or more characters."""
    table = {}
    for _, base, blob in sections(elf_path):
        for m in PRINTABLE.finditer(blob):
            table[base + m.start()] = m.group().decode("latin-1")
    return table


def cmd_strings(elf_path, grep):
    table = string_table(elf_path)
    pattern = re.compile(grep, re.I) if grep else None
    for va in sorted(table):
        text = table[va]
        if pattern and not pattern.search(text):
            continue
        print("0x%08x  %s" % (va, text))
    print("# %d strings total" % len(table))


def cmd_resolve(elf_path, corpus):
    table = string_table(elf_path)
    # A string can be referenced at its first byte or a few bytes in; resolve any
    # DAT_ that lands inside a string, not just on its start.
    starts = sorted(table)
    rewritten = resolved = 0
    for name in sorted(os.listdir(corpus)):
        if not name.endswith(".c"):
            continue
        path = os.path.join(corpus, name)
        text = open(path, encoding="utf-8", errors="replace").read()
        changed = False
        for m in list(re.finditer(r"DAT_([0-9a-f]{8})", text)):
            pass
        def swap(match):
            nonlocal resolved, changed
            va = int(match.group(1), 16)
            text_at = table.get(va)
            if text_at is None:
                # nearest string starting before this address
                lo, hi = 0, len(starts) - 1
                best = None
                while lo <= hi:
                    mid = (lo + hi) // 2
                    if starts[mid] <= va:
                        best = starts[mid]
                        lo = mid + 1
                    else:
                        hi = mid - 1
                if best is None or va - best > 96:
                    return match.group(0)
                candidate = table[best]
                offset = va - best
                if offset >= len(candidate) or not candidate[:offset].strip():
                    return match.group(0)
                text_at = candidate[offset:]
                if not text_at:
                    return match.group(0)
            resolved += 1
            changed = True
            safe = text_at.replace("\\", "\\\\").replace('"', '\\"')
            return '"%s"' % safe
        new = re.sub(r"DAT_([0-9a-f]{8})", swap, text)
        if changed:
            open(path, "w", encoding="utf-8").write(new)
            rewritten += 1
    print("resolved %d references across %d files" % (resolved, rewritten))


def cmd_floats(elf_path, grep):
    """Runs of three or more floats that could be a direction, colour or FOV."""
    want = float(grep) if grep else None
    for name, base, blob in sections(elf_path):
        if name.lower() not in (".rdata", ".data", ".rodata"):
            continue
        count = len(blob) // 4
        values = struct.unpack(">%df" % count, blob[:count * 4])
        run = []
        for i, value in enumerate(values):
            plausible = (value == value and abs(value) < 4096.0
                         and (abs(value) >= 0.01 or value == 0.0))
            if plausible:
                run.append((base + i * 4, value))
                continue
            if len(run) >= 3:
                emit(run, want)
            run = []
        if len(run) >= 3:
            emit(run, want)


def emit(run, want):
    values = [v for _, v in run]
    if want is not None and not any(abs(abs(v) - want) < 0.02 for v in values):
        return
    text = " ".join("%g" % v for v in values)
    print("0x%08x  %s" % (run[0][0], text))


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    command, elf_path = sys.argv[1], sys.argv[2]
    grep = None
    for i, a in enumerate(sys.argv):
        if a == "--grep" and i + 1 < len(sys.argv):
            grep = sys.argv[i + 1]
        elif a.startswith("--grep="):
            grep = a.split("=", 1)[1]
    if command == "strings":
        cmd_strings(elf_path, grep)
    elif command == "resolve" and len(sys.argv) > 3:
        cmd_resolve(elf_path, sys.argv[3])
    elif command == "floats":
        cmd_floats(elf_path, grep)
    else:
        print(__doc__)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
