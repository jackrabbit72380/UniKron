#!/usr/bin/env python3
"""What are the stretches of `.text` Ghidra never disassembled?

Reads the `undefined 0xADDR len=N` lines Coverage.java prints and, for each run,
reports which `.pdata` records cover it, how many 4-byte pointers in `.rdata` point
into it, and whether the bytes look like function code (a prologue or `blr`).

  Coverage.java output > runs.txt
  python3 undef_runs.py runs.txt
"""
import struct
import sys
from collections import Counter

from capstone import Cs, CS_ARCH_PPC, CS_MODE_32, CS_MODE_BIG_ENDIAN

EXE = "/tmp/avatareditor_rebased.exe"
PDATA_RAW, PDATA_SIZE = 0x32C00, 0x66F8
TEXT_RAW, TEXT_VA, TEXT_SIZE = 0x39400, 0x9803A000, 0x1011DC
RDATA_RAW, RDATA_VA, RDATA_SIZE = 0x400, 0x98000400, 0x32650

data = open(EXE, "rb").read()
TEXT = data[TEXT_RAW:TEXT_RAW + TEXT_SIZE]
RDATA = data[RDATA_RAW:RDATA_RAW + RDATA_SIZE]
PD = data[PDATA_RAW:PDATA_RAW + PDATA_SIZE]
RECS = [struct.unpack(">II", PD[i:i + 8]) for i in range(0, len(PD), 8)]
MD = Cs(CS_ARCH_PPC, CS_MODE_32 | CS_MODE_BIG_ENDIAN)


def decode(va):
    off = va - TEXT_VA
    if off < 0 or off + 4 > len(TEXT):
        return None
    for ins in MD.disasm(TEXT[off:off + 4], va):
        return ins
    return None


def words(va, n):
    off = va - TEXT_VA
    return [struct.unpack(">I", TEXT[off + 4 * i:off + 4 * i + 4])[0] for i in range(n)]


def rec_for(va):
    best = None
    for s, u in RECS:
        if s <= va:
            best = (s, ((u >> 8) & 0x3FFFFF) * 4)
        else:
            break
    return best


def main():
    runs = []
    for line in open(sys.argv[1]):
        parts = line.split()
        if len(parts) >= 3:
            runs.append((int(parts[1], 16), int(parts[2].split("=")[1])))
    ptrs = Counter()
    for o in range(0, len(RDATA) - 4, 4):
        v = struct.unpack(">I", RDATA[o:o + 4])[0]
        if TEXT_VA <= v < TEXT_VA + TEXT_SIZE:
            ptrs[v] += 1
    covered = 0
    inside_rec = 0
    with_ptr = 0
    shaped = 0
    for addr, ln in runs:
        covered += ln
        r = rec_for(addr)
        rec_end = r[0] + r[1] if r else 0
        if r and addr < rec_end:
            inside_rec += ln
        hits = sum(1 for a in range(addr, addr + ln, 4) if a in ptrs)
        if hits:
            with_ptr += ln
        # shape: any prologue-looking word at a 4-aligned offset, and a blr
        ws = words(addr, min(ln // 4, 64))
        mflr = any((w >> 26) == 31 and ((w >> 1) & 0x3FF) == 0x2A6 for w in ws[:8])
        blr = 0x4E800020 in ws
        if mflr or blr:
            shaped += ln
    total = sum(ln for _, ln in runs)
    print("runs=%d bytes=%d" % (len(runs), total))
    print("  inside a .pdata record: %d bytes (%.1f%%)" % (inside_rec, 100.0 * inside_rec / total))
    print("  addressed by an .rdata pointer: %d bytes (%.1f%%)" % (with_ptr, 100.0 * with_ptr / total))
    print("  contains mflr prologue or blr in first 64 words: %d bytes (%.1f%%)" % (
        shaped, 100.0 * shaped / total))
    print("largest runs:")
    for addr, ln in sorted(runs, key=lambda x: -x[1])[:12]:
        r = rec_for(addr)
        hits = sum(1 for a in range(addr, addr + ln, 4) if a in ptrs)
        ws = words(addr, min(ln // 4, 16))
        nbl = ws.count(0x4E800020)
        first = decode(addr)
        print("  0x%08x len=%-5d ptr_in_run=%-3d blr_in_first_16=%-2d rec=0x%08x+%d first=%s" % (
            addr, ln, hits, nbl, r[0], r[1],
            (first.mnemonic + " " + first.op_str) if first else "undecodable"))


if __name__ == "__main__":
    main()
