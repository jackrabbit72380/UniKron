#!/usr/bin/env python3
"""Recover the jump tables Ghidra gave up on, from the PowerPC itself.

Six per cent of `avatareditor.xex` decompiled to `halt_baddata()`: every function
whose `switch` the compiler turned into a jump table. Ghidra recovered the
surrounding code but not the table, so those functions read as a stub with a
"bad instruction data" warning (see DECOMPILE.md).

They can be read without a decompiler. A PowerPC jump table is always the same
shape:

    cmplwi cr6, r11, 0xNN      ; the case bound
    bgt    cr6, <default>
    lis    r12, <hi>           ; table address
    addi   r12, r12, <lo>
    slwi   r0, r11, 1          ; index * 2, i.e. halfword entries
    lhzx   r0, r12, r0         ; the case offset
    lis    r12, <base_hi>      ; the code base the offsets are from
    addi   r12, r12, <base_lo>
    add    r12, r12, r0
    mtctr  r12
    bctr                       ; dispatch

so the targets are `base + u16[table + 2 * i]` for `i` in `0 .. NN`. This reads
both halves straight from the image, then disassembles the first instructions of
each target and resolves the UTF-16BE string literals they load (the image's
names are UTF-16BE, not ASCII, which is why an ASCII reader finds nothing).

    python3 decomp_gaps.py --list                  # which functions are missing
    python3 decomp_gaps.py --func 0x9804d2f8       # one function's table + cases
    python3 decomp_gaps.py --all --out gaps.md     # every hole, to a report

`--all` reads the decompiled `.c` files only to find which addresses failed; the
recovery itself is from the XEX, so it is independent of the decompiler.
"""

import argparse
import glob
import json
import os
import re
import struct
import sys

import capstone

import ppc_disasm as P

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_XEX = os.path.join(HERE, "../../../src_archive/XBOX HUB/resources/editors/"
                           "nxe2008/assets/avatareditor.xex")
# The decompiled tree, when it has been unpacked next to the tools.
DEFAULT_DECOMP = os.path.join(HERE, "decompiled/nxenop")
FAILED = re.compile(r"halt_baddata|UNRECOVERED_JUMPTABLE")


def load(path):
    return P.load(path)


def u16(img, va):
    return struct.unpack(">H", img.read(va, 2))[0]


def u32(img, va):
    return struct.unpack(">I", img.read(va, 4))[0]


def s16(img, va):
    return struct.unpack(">h", img.read(va, 2))[0]


def u16_string(img, va, limit=64):
    out = b""
    for i in range(limit):
        pair = img.read(va + 2 * i, 2)
        if pair == b"\x00\x00":
            break
        out += pair
    return out.decode("utf-16-be", "replace")


def disassemble(img, va, count):
    md = capstone.Cs(capstone.CS_ARCH_PPC, capstone.CS_MODE_BIG_ENDIAN)
    md.detail = False
    return list(md.disasm(img.read(va, count * 4), va))


def find_tables(img, start, window=400):
    """Every jump table in a function, as (kind, table_va, base_va, count, targets).

    Two shapes occur in this image.  The offset table is the classic
    `lhzx`/`add base` form, whose entries are halfword offsets from a code base.
    The direct table is `lwzx rD, r12, r0` and holds **absolute 32-bit case
    addresses** - `0x98125240` and `0x9812ae50` both use it, and the first draft
    of this tool only knew the offset form, so it reported "no table" for both.
    """
    insns = disassemble(img, start, window)
    reg = {}
    bound = None
    tables = []
    table_va = None
    words_va = None
    for index, ins in enumerate(insns):
        ops = [o.strip() for o in ins.op_str.split(",")]
        # `lis` loads the high half, so its immediate is shifted, not masked: the
        # first draft of this masked it and every table address came out 0x9800.
        if ins.mnemonic == "lis" and len(ops) == 2:
            reg[ops[0]] = (int(ops[1], 0) & 0xFFFF) << 16
        elif ins.mnemonic in ("addi", "addis") and len(ops) == 3 and ops[1] in reg:
            value = reg[ops[1]]
            if ins.mnemonic == "addis":
                value = (value + ((int(ops[2], 0) & 0xFFFF) << 16)) & 0xFFFFFFFF
            else:
                value = (value + int(ops[2], 0)) & 0xFFFFFFFF
            reg[ops[0]] = value
        elif ins.mnemonic == "cmplwi" and len(ops) == 3:
            bound = int(ops[2], 0) & 0xFFFFFFFF
        elif ins.mnemonic == "lhzx" and table_va is None:
            # lhzx rD, rA, rB - rA holds the table address, computed just above.
            if len(ops) == 3 and ops[1] in reg:
                table_va = reg[ops[1]]
        elif ins.mnemonic == "add" and len(ops) == 3 and table_va is not None:
            if ops[1] in reg:
                base = reg[ops[1]]
                if bound is not None and bound < 4096:
                    count = bound + 1
                else:
                    count = 0
                tables.append((table_va, base, count))
                table_va = None
                bound = None
        elif ins.mnemonic == "lwzx" and table_va is None and words_va is None:
            # lwzx rD, rA, rB - rA holds the table address, computed just above.
            if len(ops) == 3 and ops[1] in reg:
                words_va = reg[ops[1]]
        elif ins.mnemonic == "bctr" and words_va is not None:
            count = bound + 1 if bound is not None and bound < 4096 else 64
            tables.append(("words", words_va, None, count))
            words_va = None
            bound = None
        elif ins.mnemonic in ("blr", "bctr") and table_va is not None:
            table_va = None
    out = []
    for kind, table, base, count in tables:
        if count == 0:
            count = 64
        targets = []
        for i in range(count):
            try:
                if kind == "words":
                    target = u32(img, table + 4 * i)
                else:
                    # The case bodies are not inside the dispatcher: `FUN_9804d2f8`
                    # jumps *back* to 0x9804c73c, 0xc00 bytes before its own entry, so
                    # a range check anchored on the entry drops every target. Only the
                    # image's own text range is enforced.
                    target = base + u16(img, table + 2 * i)
            except Exception:
                break
            if not (0x98000000 <= target < 0x98200000):
                break
            targets.append(target)
        if targets:
            out.append((kind, table, base, len(targets), targets))
    return out


def describe_case(img, target, scan=24):
    """The string literals and calls a case body makes, before it branches away."""
    strings, calls = [], []
    reg = {}
    for ins in disassemble(img, target, scan):
        ops = [o.strip() for o in ins.op_str.split(",")]
        if ins.mnemonic == "lis" and len(ops) == 2:
            reg[ops[0]] = (int(ops[1], 0) & 0xFFFF) << 16
        elif ins.mnemonic in ("addi", "ori") and len(ops) == 3 and ops[1] in reg:
            immediate = int(ops[2], 0) & (0xFFFF if ins.mnemonic == "ori" else 0xFFFFFFFF)
            reg[ops[0]] = (reg[ops[1]] + immediate) & 0xFFFFFFFF
            value = reg[ops[0]]
            if 0x98000000 <= value <= 0x981FFFFF:
                text = u16_string(img, value)
                if text and text.isprintable():
                    strings.append((ops[0], text))
        if ins.mnemonic in ("bl", "b") and ins.op_str.startswith("0x"):
            calls.append(int(ins.op_str, 16))
        if ins.mnemonic == "b" and not ins.op_str.startswith("0x"):
            break
    return strings, calls


def failed_addresses(decomp):
    out = []
    for path in sorted(glob.glob(os.path.join(decomp, "*.c"))):
        try:
            text = open(path, encoding="utf-8", errors="ignore").read()
        except OSError:
            continue
        if FAILED.search(text):
            match = re.search(r"FUN_([0-9a-fA-F]{8})", os.path.basename(path))
            if match:
                out.append(int(match.group(1), 16))
    return out


def report(img, address, out):
    tables = find_tables(img, address)
    out.append("\n### `%08x`\n" % address)
    if not tables:
        out.append("No table found in the first %d instructions.\n" % 400)
        return 0
    total = 0
    for kind, table, base, count, targets in tables:
        if kind == "words":
            out.append("direct table `%08x`, %d cases (absolute addresses)\n\n"
                       % (table, count))
        else:
            out.append("table `%08x`, base `%08x`, %d cases\n\n" % (table, base, count))
        out.append("| # | target | strings | first calls |\n| ---: | --- | --- | --- |\n")
        for i, target in enumerate(targets):
            strings, calls = describe_case(img, target)
            names = ", ".join("`%s`" % s for _, s in strings[:4]) or "-"
            called = ", ".join("`%08x`" % c for c in calls[:3]) or "-"
            out.append("| %d | `%08x` | %s | %s |\n" % (i, target, names, called))
        total += len(targets)
    return total


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--xex", default=DEFAULT_XEX)
    ap.add_argument("--decomp", default=DEFAULT_DECOMP)
    ap.add_argument("--func", default="", help="one address, e.g. 0x9804d2f8")
    ap.add_argument("--list", action="store_true", help="the functions that failed")
    ap.add_argument("--all", action="store_true", help="recover every failed function")
    ap.add_argument("--out", default="", help="write the report here")
    args = ap.parse_args()

    if not os.path.exists(args.xex):
        raise SystemExit("no XEX at %s" % args.xex)
    img = load(args.xex)

    if args.list:
        addresses = failed_addresses(args.decomp)
        print("%d functions failed to decompile in %s" % (len(addresses), args.decomp))
        for address in addresses:
            print("  %08x" % address)
        return 0

    addresses = []
    if args.func:
        addresses = [int(args.func, 0)]
    elif args.all:
        addresses = failed_addresses(args.decomp)
        if not addresses:
            raise SystemExit("no failed functions under %s" % args.decomp)
    else:
        raise SystemExit("nothing to do: --list, --func or --all")

    # A failed function is only worth decoding if the image actually maps code
    # there.  119 of the 193 sit in the strip between .text end (0x9813b200) and
    # .data (0x9813c000), which no section covers, so the old "1/193" recovery
    # rate mixed real holes with addresses that are not in the image at all.
    unreadable = [a for a in addresses if not img.read(a, 4)]
    addresses = [a for a in addresses if img.read(a, 4)]

    out = ["# Jump tables recovered from the 2008 image\n\n",
           "%d function(s) of %d failed; %d more are not covered by any mapped "
           "section (`0x9813b200`-`0x9813c000`) and are skipped.\n"
           % (len(addresses), len(addresses) + len(unreadable), len(unreadable))]
    recovered = cases = 0
    for address in addresses:
        found = report(img, address, out)
        if found:
            recovered += 1
            cases += found
    text = "".join(out)
    if args.out:
        with open(args.out, "w") as fh:
            fh.write(text)
        print("wrote %s: %d/%d functions, %d cases"
              % (args.out, recovered, len(addresses), cases))
    else:
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
