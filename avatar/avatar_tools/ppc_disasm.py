#!/usr/bin/env python3
"""Disassemble the PowerPC code inside the readable Xbox images.

    python3 ppc_disasm.py XEX_OR_XBE --index            # one line per function
    python3 ppc_disasm.py XEX_OR_XBE --func 0x8210a3b4  # one function's listing
    python3 ppc_disasm.py XEX_OR_XBE --stats

Handles two containers:

* **XEX2** with an unencrypted PE image (the 2008 editor): the PE is
  little-endian, the code big-endian PowerPC.
* **XBE** (the three dashboard executables): header at 0, section table at
  `base + headerSize`, each section with virtual address, size and file offset.

Functions are found from `bl` targets plus the entry point; a function runs until
the next start. Strings are resolved from the usual `lis`/`ori` or `lis`/`addi`
pair, so a listing shows which literal a call is passing.

This is a disassembler, not a decompiler: it shows machine instructions with
their operands, and the string table makes them readable. Turning PowerPC into C
needs a decompiler, which is not available here (see EDITOR_BINARIES.md).
"""
import struct
import sys

import capstone

MASK = 0xFFFFFFFF


class Image:
    """Address space of a loaded image: virtual address -> bytes."""

    def __init__(self, name, base, sections, entry):
        self.name = name
        self.base = base
        self.sections = sections          # [(name, vaddr, bytes)]
        self.entry = entry

    def read(self, addr, size):
        for name, vaddr, blob in self.sections:
            if vaddr <= addr < vaddr + len(blob):
                start = addr - vaddr
                return blob[start:start + size]
        return b""

    def u32(self, addr):
        raw = self.read(addr, 4)
        return struct.unpack(">I", raw)[0] if len(raw) == 4 else None

    def cstring(self, addr, limit=120):
        raw = self.read(addr, limit)
        end = raw.find(b"\x00")
        if end >= 0:
            raw = raw[:end]
        text = raw.decode("latin-1", "replace")
        printable = sum(1 for c in text if 32 <= ord(c) < 127 or c in "\t")
        if not text or printable < len(text) * 0.9:
            return ""
        return text

    def section_of(self, addr):
        for name, vaddr, blob in self.sections:
            if vaddr <= addr < vaddr + len(blob):
                return name
        return ""

    def text(self):
        for name, vaddr, blob in self.sections:
            if name == ".text":
                return vaddr, blob
        return None, b""


def load_xex(path):
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:4] != b"XEX2":
        raise ValueError("not a XEX2")
    _, pe_offset, _, _, _ = struct.unpack_from(">5I", data, 4)
    if data[pe_offset:pe_offset + 2] != b"MZ":
        raise ValueError("PE image at %d is encrypted" % pe_offset)
    lfanew = struct.unpack_from("<I", data, pe_offset + 0x3C)[0]
    coff = pe_offset + lfanew
    machine, count, _, _, _, opt_size = struct.unpack_from("<HHIIIH", data, coff + 4)
    opt = coff + 24
    entry_rva = struct.unpack_from("<I", data, opt + 16)[0]
    image_base = struct.unpack_from("<I", data, opt + 28)[0]
    table = opt + opt_size
    sections = []
    for i in range(count):
        at = table + i * 40
        name = data[at:at + 8].rstrip(b"\x00").decode("latin-1")
        vsize, vaddr, raw_size, raw_ptr = struct.unpack_from("<IIII", data, at + 8)
        blob = data[pe_offset + raw_ptr:pe_offset + raw_ptr + raw_size]
        sections.append((name, image_base + vaddr, blob))
    return Image(path.split("/")[-3] + "/" + path.split("/")[-1], image_base, sections,
                 image_base + entry_rva)


def load_xbe(path):
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:4] != b"XBEH":
        raise ValueError("not an XBE")
    # The XBE magic is ASCII but its header integers are little-endian, and 0x04
    # starts the 256-byte signature: load address at 0x104, section count at
    # 0x11C, section header table (a virtual address) at 0x120.
    base = struct.unpack_from("<I", data, 0x104)[0]
    count = struct.unpack_from("<I", data, 0x11C)[0]
    table = struct.unpack_from("<I", data, 0x120)[0]
    entry = struct.unpack_from("<I", data, 0x12C)[0]
    table_off = table - base
    sections = []
    for i in range(count):
        flags, vaddr, vsize, raw_ptr, raw_size = struct.unpack_from(
            "<5I", data, table_off + i * 0x38)
        # XBE section flags: 0x4 executable, 0x2 writable.
        name = b".text" if flags & 6 else (b".data" if flags & 2 else b".rdata")
        sections.append((name.decode("latin-1"), vaddr, data[raw_ptr:raw_ptr + raw_size]))
    return Image(path.split("/")[-3] + "/" + path.split("/")[-1], base, sections, entry)


def detect_base(image):
    """Rebase the image to where its own `lis` constants point.

    The 2008 editor's PE header claims 0x92000000, but every address the code
    builds points at 0x9800_0000: a 0x06000000 difference the loader must make up
    for. Rather than trust the header, take the most common `lis` high half, which
    is the address space the code actually uses.
    """
    vaddr, blob = image.text()
    if not blob:
        return image
    cs = build()
    highs = {}
    for ins in cs.disasm(blob, 0):
        if ins.mnemonic == "lis":
            try:
                half = int(ins.op_str.split(",")[1], 0) & 0xFFFF
            except (ValueError, IndexError):
                continue
            key = half << 16
            highs[key] = highs.get(key, 0) + 1
    if not highs:
        return image
    best = max(highs, key=highs.get)
    current = image.base & 0xFFFF0000
    if best == current:
        return image
    delta = best - current
    image.sections = [(name, (vaddr + delta) & MASK, blob)
                      for name, vaddr, blob in image.sections]
    image.base = (image.base + delta) & MASK
    image.entry = (image.entry + delta) & MASK
    return image


def load(path):
    with open(path, "rb") as fh:
        magic = fh.read(4)
    if magic == b"XEX2":
        return detect_base(load_xex(path))
    if magic == b"XBEH":
        # An XBE's own base/entry/section addresses agree with each other, so it
        # is used as-is; only the XEX's PE header lies about the base.
        return load_xbe(path)
    raise ValueError("neither XEX2 nor XBE")


def build():
    cs = capstone.Cs(capstone.CS_ARCH_PPC, capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_32)
    # Sections carry zero padding between blocks, and capstone stops at the
    # first word it cannot decode; skipdata keeps the walk going.
    cs.skipdata = True
    return cs


def disassemble(image):
    """(instructions, function starts) for the whole .text section."""
    vaddr, blob = image.text()
    if not blob:
        raise ValueError("no .text section")
    cs = build()
    cs.detail = True
    insns = list(cs.disasm(blob, vaddr))
    starts = {image.entry}
    for ins in insns:
        if ins.mnemonic.startswith("bl"):
            try:
                target = ins.operands[0].imm if ins.operands else None
            except capstone.CsError:
                target = None
            if target is not None:
                target &= MASK
                if image.text()[0] <= target < image.text()[0] + len(blob):
                    starts.add(target)
    starts = sorted(starts)
    return insns, starts


def string_refs(insns, image):
    """Map instruction address -> literal it loads.

    Tracks `lis` plus `ori`/`addi` per register, because the pair often lands the
    address in a different register than the one `lis` wrote (`lis r11, X;
    addi r3, r11, Y`). A constant that points into a data section is followed one
    level: the dashboard keeps tables of string pointers, and the pointer is what
    the code loads.
    """
    refs = {}
    const = {}
    for ins in insns:
        parts = ins.op_str.replace(",", " ").split()
        try:
            if ins.mnemonic == "lis" and len(parts) >= 2:
                const[parts[0]] = (int(parts[1], 0) << 16) & MASK
                continue
            if ins.mnemonic in ("ori", "addi") and len(parts) >= 3 and parts[1] in const:
                low = int(parts[2], 0)
                if ins.mnemonic == "addi" and low >= 0x8000:
                    low -= 0x10000
                value = (const[parts[1]] + (low if ins.mnemonic == "addi" else low & 0xFFFF)) & MASK
                const[parts[0]] = value
            elif len(parts) >= 1 and parts[0] in const:
                value = const[parts[0]]
            else:
                continue
        except (ValueError, IndexError):
            continue
        text = image.cstring(value)
        if not text:
            pointer = image.u32(value)
            if pointer is not None:
                text = image.cstring(pointer)
        if text:
            refs[ins.address] = text
    return refs


def group(insns, starts):
    """[(start, [insns])] with each function running to the next start."""
    functions = []
    index = 0
    for position, start in enumerate(starts):
        end = starts[position + 1] if position + 1 < len(starts) else None
        body = []
        while index < len(insns) and (end is None or insns[index].address < end):
            body.append(insns[index])
            index += 1
        if body:
            functions.append((start, body))
    return functions


def describe(body, refs):
    strings = [refs[i.address] for i in body if i.address in refs]
    calls = [i for i in body if i.mnemonic.startswith("bl")]
    return len(body), len(calls), strings


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 1
    path, mode = argv[0], argv[1]
    image = load(path)
    insns, starts = disassemble(image)
    functions = group(insns, starts)
    refs = string_refs(insns, image)

    if mode == "--stats":
        print("%s  base 0x%08x  %d sections  entry 0x%08x" % (
            image.name, image.base, len(image.sections), image.entry))
        for name, vaddr, blob in image.sections:
            print("  %-9s 0x%08x  %8d bytes" % (name, vaddr, len(blob)))
        print("  %d instructions disassembled, %d functions, %d string references" % (
            len(insns), len(functions), len(refs)))
        return 0

    if mode == "--index":
        for start, body in functions:
            count, calls, strings = describe(body, refs)
            print("0x%08x  %5d insn  %4d calls  %-24s %s" % (
                start, count, calls, (strings[0][:24] if strings else ""),
                image.section_of(start)))
        print("%d functions" % len(functions))
        return 0

    if mode == "--func":
        want = int(argv[2], 0)
        for start, body in functions:
            if start != want:
                continue
            for ins in body:
                note = refs.get(ins.address, "")
                raw = ins.bytes.hex()
                print("0x%08x  %-8s  %-8s %-32s %s" % (
                    ins.address, raw, ins.mnemonic, ins.op_str, note))
            return 0
        print("no function at 0x%08x" % want)
        return 1

    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
