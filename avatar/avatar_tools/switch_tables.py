#!/usr/bin/env python3
"""Recover the case targets of every `lhzx`/`lwzx` + `bctr` dispatcher by hand.

The shape, measured at 0x98067b7c..0x98067ba0:

    lis   r12, -0x6800          ; hi of the table
    addi  r12, r12, 0x65a0      ; table  = 0x980065a0
    rlwinm r0, r11, 1, 0, 0x1e  ; index  = case * 2
    lhzx  r0, r12, r0           ; u16 offset from the table
    lis   r12, -0x67fa
    addi  r12, r12, 0x6fa4      ; base   = 0x98066fa4
    add   r12, r12, r0
    mtspr CTR, r12
    bctr

Reading the same table as u32, or with the wrong base, is what produces the
decompiler's bogus targets (`0x98067b8e` sits 2 bytes into an instruction). This
script recomputes the table the way the code does and prints each dispatcher with
its case count and targets, so they can be handed back to Ghidra as computed jumps.

  python3 switch_tables.py > /tmp/dispatchers.tsv
"""
import struct
import sys

from capstone import Cs, CS_ARCH_PPC, CS_MODE_32, CS_MODE_BIG_ENDIAN

EXE = "/tmp/avatareditor_rebased.exe"
RDATA_RAW, RDATA_VA, RDATA_SIZE = 0x400, 0x98000400, 0x32650
TEXT_RAW, TEXT_VA, TEXT_SIZE = 0x39400, 0x9803A000, 0x1011DC

data = open(EXE, "rb").read()
TEXT = data[TEXT_RAW:TEXT_RAW + TEXT_SIZE]
RDATA = data[RDATA_RAW:RDATA_RAW + RDATA_SIZE]
MD = Cs(CS_ARCH_PPC, CS_MODE_32 | CS_MODE_BIG_ENDIAN)
MD.detail = True


def read(va, size):
    """Read big-endian data at an image VA, or None if it is not in .rdata."""
    if not (RDATA_VA <= va <= RDATA_VA + RDATA_SIZE - size):
        return None
    off = va - RDATA_VA
    return int.from_bytes(RDATA[off:off + size], "big")


def disasm(va):
    off = va - TEXT_VA
    if off < 0 or off + 4 > len(TEXT):
        return None
    for ins in MD.disasm(TEXT[off:off + 4], va):
        return ins
    return None


def regs(ins):
    return [o.reg for o in ins.operands if o.type == 1]


def imm(ins, i=0):
    ops = [o for o in ins.operands if o.type == 2]
    return ops[i].imm if len(ops) > i else None


def dispatcher_at(bctr, window=12):
    """Read the dispatcher shape forward, from `bctr - 4*window` to `bctr`.

    Forward order is what makes the register tracking correct: the table pointer
    and the target base are built in that order, and the same register is often
    reused for both (r12 here), so a backwards walk assigns the wrong constant.
    """
    insns = []
    for i in range(window, 0, -1):
        ins = disasm(bctr - 4 * i)
        if ins is not None:
            insns.append(ins)
    consts = {}
    table = base = None
    scale = None
    count = None
    for ins in insns:
        m = ins.mnemonic
        r = regs(ins)
        if m == "lis" and r:
            v = imm(ins)
            if v is not None:
                consts[r[0]] = (v << 16) & 0xFFFFFFFF
        elif m == "addi" and len(r) == 2 and r[0] == r[1]:
            v = imm(ins)
            if v is not None and r[0] in consts:
                consts[r[0]] = (consts[r[0]] + v) & 0xFFFFFFFF
        elif m in ("lhzx", "lwzx") and len(r) == 3:
            table = consts.get(r[1])
            scale = 2 if m == "lhzx" else 4
        elif m == "rlwinm" and len(r) >= 2:
            sh = imm(ins, 1)
            if sh is not None and sh < 4:
                scale = 1 << sh
        elif m == "add" and len(r) == 3:
            b = consts.get(r[1])
            if b is None:
                b = consts.get(r[2])
            if b is not None:
                base = b
        elif m == "cmplwi":
            v = imm(ins)
            if v is not None:
                count = v + 1
    return table, base, scale, count


def main():
    found = []
    for a in range(TEXT_VA, TEXT_VA + TEXT_SIZE, 4):
        ins = disasm(a)
        if ins is None or ins.mnemonic != "bctr":
            continue
        table, base, scale, count = dispatcher_at(a)
        if table is None or base is None:
            continue
        n = count if count else 32
        targets = []
        for i in range(n):
            v = read(table + scale * i, scale)
            if v is None:
                break
            t = base + v
            if not (TEXT_VA <= t < TEXT_VA + TEXT_SIZE):
                break
            targets.append(t)
        if not targets:
            continue
        aligned = all(t % 4 == 0 for t in targets)
        found.append((a, table, base, scale, len(targets), aligned, targets))
    for a, table, base, scale, n, aligned, targets in found:
        print("0x%08x\t0x%08x\t0x%08x\t%d\t%d\t%s\t%s" % (
            a, table, base, scale, n, aligned,
            ",".join("0x%08x" % t for t in targets)))
    sys.stderr.write("dispatchers=%d aligned=%d\n" % (
        len(found), sum(1 for f in found if f[5])))


if __name__ == "__main__":
    main()
