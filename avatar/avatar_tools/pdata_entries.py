#!/usr/bin/env python3
"""What is really at a `.pdata` entry: a function start, or a chunk of the one before?

For each address given it prints the `.pdata` entry that precedes it, the word just
before it, whether that word falls through (so the address is inside a basic block)
and how many branches inside [previous entry, address) target the address exactly.
Decoding is one word at a time with Capstone so an undecodable Xenon vector word
cannot desynchronise the walk.

  python3 pdata_entries.py 0x980690e0 0x9804ed18 ...
"""
import struct
import sys

from capstone import Cs, CS_ARCH_PPC, CS_MODE_32, CS_MODE_BIG_ENDIAN, CS_GRP_JUMP

EXE = "/tmp/avatareditor_rebased.exe"
PDATA_RAW, PDATA_SIZE = 0x32C00, 0x66F8
TEXT_RAW, TEXT_VA, TEXT_SIZE = 0x39400, 0x9803A000, 0x1011DC

TERMINATORS = {"b", "bc", "blr", "bctr", "bctrl", "bclr", "rfi", "trap"}


def load():
    data = open(EXE, "rb").read()
    text = data[TEXT_RAW:TEXT_RAW + TEXT_SIZE]
    pdata = data[PDATA_RAW:PDATA_RAW + PDATA_SIZE]
    starts = [struct.unpack(">I", pdata[i:i + 4])[0] for i in range(0, len(pdata), 8)]
    return text, starts


TEXT, STARTS = load()
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


def branch_target(ins):
    """Absolute target of a direct branch, or None."""
    if ins is None or not ins.groups or CS_GRP_JUMP not in ins.groups:
        return None
    if not ins.operands:
        return None
    op = ins.operands[0]
    if op.type == 2:  # IMM
        return op.imm
    return None


def classify(va):
    prev = max(s for s in STARTS if s < va)
    nxt = min((s for s in STARTS if s > va), default=None)
    before = decode(va - 4)
    at = decode(va)
    into = 0
    into_src = []
    a = prev
    while a < va:
        ins = decode(a)
        t = branch_target(ins)
        if t == va:
            into += 1
            into_src.append(a)
        a += 4
    return dict(prev=prev, nxt=nxt, before=before, at=at, into=into, into_src=into_src)


def fmt(ins):
    if ins is None:
        return "undecodable"
    return ins.mnemonic + " " + ins.op_str


def main():
    addrs = [int(a, 16) for a in sys.argv[1:]]
    for va in addrs:
        c = classify(va)
        falls = c["before"] is not None and c["before"].mnemonic not in TERMINATORS
        print("0x%08x prev=0x%08x next=%s" % (
            va, c["prev"], ("0x%08x" % c["nxt"]) if c["nxt"] else "-"))
        print("   before: %-28s falls_through=%s" % (fmt(c["before"]), falls))
        print("   at    : %s" % fmt(c["at"]))
        print("   branches into it from [prev, it): %d %s" % (
            c["into"], " ".join("0x%08x" % s for s in c["into_src"][:6])))
        print("   reading: %s" % (
            "entry reached by fallthrough -> inside a block" if falls else
            "preceded by a terminator -> a block start"))


if __name__ == "__main__":
    main()
