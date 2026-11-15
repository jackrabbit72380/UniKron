#!/usr/bin/env python3
"""Wrap a readable XEX/XBE image in an ELF32 so Ghidra can decompile it.

    python3 mkelf.py IN.xex OUT.elf

Ghidra 12 ships no Xbox 360 XEX or XBE loader, so the image cannot be imported
directly. It does decompile PowerPC, so this writes a minimal big-endian ELF32
that puts every section where the code expects it: one PT_LOAD at the image base
the code itself uses (ppc_disasm detects that, since the header lies by
0x06000000), section headers naming each block, and the entry point.

The result is an import vehicle only - it carries the original bytes unchanged,
which is what matters for reading the code.
"""
import struct
import sys

import ppc_disasm

EM_PPC = 20
PT_LOAD = 1
SHT_PROGBITS = 1
SHT_NOBITS = 8
SHT_STRTAB = 3
SHF_WRITE = 1
SHF_ALLOC = 2
SHF_EXECINSTR = 4


ARCHES = {
    "ppc": ("PowerPC", 20, ">", 2),
    "x86": ("x86", 3, "<", 1),
}


def build_elf(image, out_path, arch="ppc"):
    machine, endian, elf_data = ARCHES[arch][1], ARCHES[arch][2], ARCHES[arch][3]
    sections = sorted(image.sections, key=lambda s: s[1])
    base = sections[0][1]
    end = max(vaddr + len(blob) for _, vaddr, blob in sections)
    span = end - base

    data = bytearray(span)
    placed = []
    for name, vaddr, blob in sections:
        offset = vaddr - base
        data[offset:offset + len(blob)] = blob
        placed.append((name, offset, vaddr, len(blob)))

    shstr = b"\x00"
    name_offsets = {}
    for name, _, _, _ in placed:
        name_offsets[name] = len(shstr)
        shstr += name.encode("latin-1") + b"\x00"
    name_offsets[".shstrtab"] = len(shstr)
    shstr += b".shstrtab\x00"

    ehsize = 52
    phentsize = 32
    shentsize = 40
    phoff = ehsize
    data_offset = phoff + phentsize
    # Keep the payload 4-byte aligned after the one program header.
    body = bytearray(data_offset) + bytes(data)
    shstr_off = len(body)
    body += shstr
    shoff = len(body)
    shcount = len(placed) + 2         # null + sections + shstrtab

    ident = b"\x7fELF" + bytes([1, elf_data, 1, 0]) + b"\x00" * 8
    header = ident + struct.pack(
        endian + "HHIIIIIHHHHHH",
        2,                      # e_type = ET_EXEC
        machine,                # e_machine
        1,                      # e_version
        image.entry,
        phoff,
        shoff,
        0,                      # e_flags
        ehsize,
        phentsize,
        1,                      # e_phnum
        shentsize,
        shcount,
        len(placed) + 1,        # e_shstrndx
    )
    phdr = struct.pack(
        endian + "IIIIIIII",
        PT_LOAD, data_offset, base, base,
        len(data), len(data), 5, 0x1000,
    )

    shdrs = [b"\x00" * shentsize]     # SHT_NULL
    for name, offset, vaddr, size in placed:
        flags = SHF_ALLOC | (SHF_EXECINSTR if name == ".text" else 0)
        if name in (".data", ".bss"):
            flags |= SHF_WRITE
        shdrs.append(struct.pack(
            endian + "IIIIIIIIII",
            name_offsets[name], SHT_PROGBITS, flags, vaddr,
            data_offset + offset, size, 0, 0, 4, 0))
    shdrs.append(struct.pack(
        endian + "IIIIIIIIII",
        name_offsets[".shstrtab"], SHT_STRTAB, 0, 0, shstr_off, len(shstr),
        0, 0, 1, 0))

    out = bytearray(header) + phdr
    out += b"\x00" * (data_offset - len(out))
    out += bytes(data) + shstr
    out += b"".join(shdrs)
    with open(out_path, "wb") as fh:
        fh.write(out)
    return base, span, len(placed)


def main(argv):
    if len(argv) != 2:
        print(__doc__)
        return 1
    arch = "x86" if "--x86" in argv else "ppc"
    image = ppc_disasm.load(argv[0])
    base, span, count = build_elf(image, argv[1], arch)
    print("%s -> %s  %s  base 0x%08x  %d sections  %d bytes of address space" % (
        argv[0], argv[1], arch, base, count, span))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
