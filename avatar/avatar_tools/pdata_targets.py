#!/usr/bin/env python3
"""Which `.pdata` entries are real function starts? Count how they are reached.

Two independent witnesses for an entry being a function start:
  * a `bl` somewhere in `.text` targets it (a call), or a pointer table holds it;
  * the instruction before it is a terminator, so its bytes are not mid-block.

For every entry this prints the second word of its `.pdata` record (the unwind
field) so the record layout can be checked, then a tally of `bl` / `b` targets
over the whole table.

  python3 pdata_targets.py            # summary
  python3 pdata_targets.py --list     # per-entry table
"""
import struct
import sys

from capstone import Cs, CS_ARCH_PPC, CS_MODE_32, CS_MODE_BIG_ENDIAN, CS_GRP_JUMP

EXE = "/tmp/avatareditor_rebased.exe"
PDATA_RAW, PDATA_SIZE = 0x32C00, 0x66F8
TEXT_RAW, TEXT_VA, TEXT_SIZE = 0x39400, 0x9803A000, 0x1011DC
TERMINATORS = {"b", "bc", "blr", "bctr", "bctrl", "bclr", "rfi", "trap"}

data = open(EXE, "rb").read()
TEXT = data[TEXT_RAW:TEXT_RAW + TEXT_SIZE]
PDATA = data[PDATA_RAW:PDATA_RAW + PDATA_SIZE]
ENTRIES = [struct.unpack(">II", PDATA[i:i + 8]) for i in range(0, len(PDATA), 8)]
MD = Cs(CS_ARCH_PPC, CS_MODE_32 | CS_MODE_BIG_ENDIAN)
MD.detail = True


def word(va):
    off = va - TEXT_VA
    if off < 0 or off + 4 > len(TEXT):
        return None
    return struct.unpack(">I", TEXT[off:off + 4])[0]


def decode(va):
    w = word(va)
    if w is None:
        return None
    for ins in MD.disasm(struct.pack(">I", w), va):
        return ins
    return None


def target(ins):
    if ins is None or not ins.operands or CS_GRP_JUMP not in (ins.groups or []):
        return None
    if ins.operands[0].type != 2:
        return None
    return ins.operands[0].imm


def main():
    called, jumped = {}, {}
    for a in range(TEXT_VA, TEXT_VA + TEXT_SIZE, 4):
        ins = decode(a)
        t = target(ins)
        if t is None:
            continue
        if ins.mnemonic.startswith("bl"):
            called.setdefault(t, []).append(a)
        else:
            jumped.setdefault(t, []).append(a)
    starts = [e[0] for e in ENTRIES]
    print("entries=%d called=%d jumped=%d" % (
        len(ENTRIES), len(set(starts) & set(called)), len(set(starts) & set(jumped))))
    mid = 0
    for i, (s, u) in enumerate(ENTRIES):
        before = decode(s - 4)
        falls = before is not None and before.mnemonic not in TERMINATORS
        if falls:
            mid += 1
    print("entries whose previous word falls through (mid-block): %d" % mid)
    # unwind field shape
    in_rdata = sum(1 for s, u in ENTRIES if u < TEXT_VA)
    in_text = sum(1 for s, u in ENTRIES if TEXT_VA <= u < TEXT_VA + TEXT_SIZE)
    print("unwind field < .text (rdata-ish): %d, inside .text: %d, zero: %d" % (
        in_rdata, in_text, sum(1 for s, u in ENTRIES if u == 0)))
    if "--list" in sys.argv:
        for s, u in ENTRIES:
            before = decode(s - 4)
            at = decode(s)
            falls = before is not None and before.mnemonic in TERMINATORS
            print("0x%08x unwind=0x%08x at=%-24s before=%-22s bl=%d b=%d" % (
                s, u,
                (at.mnemonic + " " + at.op_str) if at else "undecodable",
                (before.mnemonic + " " + before.op_str) if before else "undecodable",
                len(called.get(s, [])), len(jumped.get(s, []))))


if __name__ == "__main__":
    main()
