"""Linear hand-decoder for the `.text` holes Ghidra cannot decompile.

Why this exists
---------------
Ghidra truncates these bodies at Xenon VMX128 words (`altvNNN_M`) that no shipped
PowerPC language defines, and it writes `halt_baddata()` for the whole function.
Capstone is no help either: `md.disasm()` stops at the **first** word it cannot
decode, so a straight sweep returns four or five instructions and a blank.

So: walk the bytes one instruction at a time, decode each word on its own, and
emit a `vecXX` placeholder only for the words neither tool understands. The
scalar control flow of every hole then becomes readable, which is what the hand
decode needs; the vector arithmetic stays marked as unknown rather than invented.

Output
------
    artifacts/decomp/holes/<address>.txt   full listing per function
    artifacts/decomp/HOLES.md              summary table for all of them

Usage (from avatar_tools):
    PYTHONPATH=$PWD:<workspace>/.pyext python3 decomp_holes.py [--limit N]
"""

from __future__ import annotations

import argparse
import bisect
import collections
import os
import re
import struct

import capstone

import decomp_gaps as D

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_ROOT = os.path.normpath(os.path.join(HERE, "..", "artifacts", "decomp"))
DEFAULT_LIST = "/tmp/dump/text74.txt"
MAX_FUNCTION = 0x800          # stop scanning a hole past this much code
TEXT_END = 0x9803A000 + 0x101200

# Primary opcodes that only ever carry vector/unknown encodings on Xenon.
VECTOR_PRIMARY = {4: "VMX", 5: "VMX-5", 6: "VMX-6", 12: "VEC-LD", 13: "VEC-ST"}


def make_decoder():
    return capstone.Cs(capstone.CS_ARCH_PPC,
                       capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_32)


RDATA_START, RDATA_END = 0x98000000, 0x9802F000


def read_string(image, address, limit=64):
    """Return the NUL-terminated printable string at `address`, or None."""
    if not (RDATA_START <= address < RDATA_END):
        return None
    try:
        blob = image.read(address, limit)
    except Exception:
        return None
    end = blob.find(b"\0")
    if end < 3:
        return None
    text = blob[:end]
    if all(32 <= c < 127 for c in text):
        return text.decode("ascii")
    return None


def decode_function(md, image, start, size):
    """Decode `size` bytes from `start`, never stopping on an unknown word.

    Tracks `lis`/`addi` register pairs so a data reference becomes the string it
    points at: that is what makes these listings classifiable (`Grid3x2Button`,
    `tint`, layout names) instead of 3,000 anonymous move/add instructions.
    """
    blob = image.read(start, size)
    rows = []
    index = 0
    regs = {}
    while index < len(blob):
        address = start + index
        word = struct.unpack(">I", blob[index:index + 4])[0]
        if word == 0:
            rows.append((address, word, "nop-or-padding", 4))
            index += 4
            continue
        decoded = list(md.disasm(blob[index:index + 8], address, count=1))
        if decoded:
            insn = decoded[0]
            text = "%s %s" % (insn.mnemonic, insn.op_str)
            note = resolve_reference(insn, regs, image)
            if note:
                text = "%-38s ; %s" % (text, note)
            rows.append((address, word, text, insn.size))
            index += max(insn.size, 4)
            continue
        primary = word >> 26
        tag = VECTOR_PRIMARY.get(primary, "RAW")
        rows.append((address, word, "%s-p%02d(undecoded)" % (tag, primary), 4))
        index += 4
    return rows


MEM_OPERAND = re.compile(r"(-?0x[0-9a-fA-F]+|-?\d+)?\(r(\d+)\)")


def annotate_data(image, value):
    """Describe what lives at a resolved address: a string, or a float."""
    text = read_string(image, value)
    if text:
        return '"%s"' % text
    if RDATA_START <= value < RDATA_END:
        try:
            raw = image.read(value, 4)
        except Exception:
            return None
        number = struct.unpack(">f", raw)[0]
        if number == number and abs(number) not in (0.0,) and 1e-6 < abs(number) < 1e6:
            return "%g" % number
    return None


def resolve_reference(insn, regs, image):
    """Track lis/bases in registers, then annotate references this code makes.

    The editor forms its data references three ways: `lis r9,-0x6800` followed by
    a displacement load (`lfs f0,0x18d8(r9)`), the same with `addi`, and plain
    `lis`+`ori` pairs that build a float bit pattern in a GPR. All three are
    handled, otherwise the listings stay anonymous.
    """
    mnemonic, operands = insn.mnemonic, insn.op_str
    parts = [p.strip() for p in operands.split(",")]
    try:
        if mnemonic == "lis" and len(parts) == 2:
            regs[parts[0]] = (int(parts[1], 0) & 0xFFFF) << 16
            return None
        if mnemonic in ("addi", "addis") and len(parts) == 3 and parts[1] == parts[0]:
            base = regs.get(parts[0])
            if base is None:
                return None
            delta = int(parts[2], 0)
            if mnemonic == "addis":
                delta = (delta & 0xFFFF) << 16
            regs[parts[0]] = (base + delta) & 0xFFFFFFFF
            return annotate_data(image, regs[parts[0]])
        match = MEM_OPERAND.search(operands)
        if match:
            base = regs.get("r" + match.group(2))
            if base is None:
                return None
            displacement = int(match.group(1), 0) if match.group(1) else 0
            return annotate_data(image, (base + displacement) & 0xFFFFFFFF)
    except (ValueError, struct.error):
        return None
    return None


def summarise(rows):
    """Counts and the call/branch targets a reader needs first."""
    kinds = collections.Counter()
    calls, targets, returns = [], [], 0
    for address, word, text, size in rows:
        if "undecoded" in text:
            kinds["unknown"] += 1
        elif text.startswith("bl ") or text.startswith("bctrl"):
            kinds["call"] += 1
            if text.startswith("bl "):
                calls.append(text.split()[1])
        elif text.startswith("b") and text.split()[0] in ("b", "bc", "bcl", "bclr"):
            kinds["branch"] += 1
            if text.split()[0] in ("b", "bc", "bcl") and text.split()[1:]:
                targets.append(text.split()[1])
        elif text in ("blr", "bclr 20,0", "bclr 20,1"):
            returns += 1
        else:
            kinds["scalar"] += 1
    return kinds, calls, targets, returns


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--list", default=DEFAULT_LIST,
                        help="address list, one hex value per line")
    parser.add_argument("--limit", type=int, default=0,
                        help="only process the first N addresses")
    parser.add_argument("--starts", default="/tmp/dump/out5/allfuncs.txt",
                        help="all Ghidra function entry points; a hole is bounded by "
                             "the next entry, because Ghidra's own body for a hole "
                             "stops at the bad word (often an 8-byte stub)")
    parser.add_argument("--extents", default="/tmp/dump/out5/extents.txt",
                        help="DumpExtents output, recorded alongside for comparison")
    args = parser.parse_args(argv)

    image = D.load("../../../src_archive/XBOX HUB/resources/editors/nxe2008/assets/"
                   "avatareditor.xex")
    addresses = [int(line, 16) for line in open(args.list) if line.strip()]
    addresses.sort()
    if args.limit:
        addresses = addresses[:args.limit]

    starts = []
    if args.starts and os.path.exists(args.starts):
        for line in open(args.starts):
            line = line.strip()
            if line:
                starts.append(int(line.replace("0x", ""), 16))
        starts.sort()

    ghidra_body = {}
    if args.extents and os.path.exists(args.extents):
        for line in open(args.extents):
            parts = line.split()
            if len(parts) == 2 and parts[1] != "MISSING":
                ghidra_body[int(parts[0], 16)] = int(parts[1])

    md = make_decoder()
    out_dir = os.path.join(OUT_ROOT, "holes")
    os.makedirs(out_dir, exist_ok=True)

    summary = []
    fingerprints = []
    for address in addresses:
        # The next function entry above this hole is the true end of its code.
        size = MAX_FUNCTION
        if starts:
            index = bisect.bisect_right(starts, address)
            if index < len(starts):
                size = min(starts[index] - address, MAX_FUNCTION)
        size = min(size, TEXT_END - address)
        if size <= 0:
            continue
        rows = decode_function(md, image, address, size)
        kinds, calls, targets, returns = summarise(rows)

        path = os.path.join(out_dir, "0x%08x.txt" % address)
        with open(path, "w") as handle:
            handle.write("# 0x%08x  %d bytes  %d decoded rows\n" % (address, size, len(rows)))
            handle.write("# unknown=%d scalar=%d call=%d branch=%d returns=%d\n" % (
                kinds["unknown"], kinds["scalar"], kinds["call"],
                kinds["branch"], returns))
            handle.write("# calls: %s\n" % (" ".join(calls) or "-"))
            handle.write("# branches: %s\n\n" % (" ".join(targets[:40]) or "-"))
            for row_address, word, text, width in rows:
                handle.write("%08x  %08x  %-38s %s\n" % (
                    row_address, word, text, "" if width == 4 else "=8b"))

        summary.append((address, size, kinds, len(calls), len(targets), returns,
                        ghidra_body.get(address)))
        fingerprints.append((address, rows))

    report = os.path.join(OUT_ROOT, "HOLES.md")
    with open(report, "w") as handle:
        handle.write("# The `.text` holes, decoded linearly\n\n")
        handle.write("Generated by `decomp_holes.py`. `unknown` counts words that are\n")
        handle.write("Xenon VMX128/vector encodings with no published semantics - they are\n")
        handle.write("marked, never guessed. `scalar` is everything that decoded.\n\n")
        handle.write("| # | function | bytes | ghidra body | unknown | scalar | "
                     "calls | branch targets | returns |\n")
        handle.write("| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n")
        for number, (address, size, kinds, call_count, target_count, returns,
                     body) in enumerate(summary, 1):
            handle.write("| %d | `0x%08x` | %d | %s | %d | %d | %d | %d | %d |\n" % (
                number, address, size, "missing" if body is None else body,
                kinds["unknown"], kinds["scalar"], call_count, target_count, returns))
        total_unknown = sum(k["unknown"] for _, _, k, _, _, _, _ in summary)
        total_scalar = sum(k["scalar"] for _, _, k, _, _, _, _ in summary)
        handle.write("\nTotal: %d functions, %d decoded scalar instructions, "
                     "%d unmarked-vector words.\n" % (
                         len(summary), total_scalar, total_unknown))
    write_fingerprints(fingerprints, ghidra_body,
                       os.path.join(OUT_ROOT, "HOLES-fingerprints.md"))
    print("wrote %d listings to %s" % (len(summary), out_dir))
    print("summary: %s" % report)
    print("scalar=%d unknown=%d" % (total_scalar, total_unknown))
    return 0


def write_fingerprints(fingerprints, ghidra_body, path):
    """One compact block per hole, for classifying many at a time.

    A full listing is 200 lines; classification only needs the prologue, the
    constants that resolved, the error codes returned, and whether callees are
    already readable in the existing corpus.
    """
    corpus = "/tmp/dc_all/nxenop"

    def corpus_file(name):
        # The corpus names files FUN_<addr>_<addr>.c with no 0x prefix.
        raw = name.replace("0x", "").lower()
        return os.path.join(corpus, "FUN_%s_%s.c" % (raw, raw))

    holes = {address for address, _ in fingerprints}
    with open(path, "w") as handle:
        handle.write("# Fingerprints of the holes\n\n")
        handle.write("Prologue, resolved constants, `0x8xxxxxxx` status codes "
                     "and callees.\n")
        handle.write("Callee tags: `read` = has a Ghidra C file in the corpus, "
                     "`hole` = another listed hole.\n\n")
        for address, rows in fingerprints:
            consts, errors, prologue, callees = [], [], [], []
            for row_address, word, text, width in rows:
                note = text.split(";", 1)[1].strip() if ";" in text else ""
                if note:
                    consts.append(note)
                if text.startswith("bl "):
                    callees.append(text.split()[1])
                if text.startswith(("lis", "ori")) and "0x8" in text:
                    matched = re.search(r"0x([89a-f][0-9a-f]{7})", text)
                    if matched:
                        errors.append("0x" + matched.group(1))
                if len(prologue) < 5 and row_address < address + 24:
                    prologue.append(text.split(";")[0].strip())
            unique_consts = []
            for value in consts:
                if value not in unique_consts:
                    unique_consts.append(value)
            tags = []
            for target in callees:
                if target in holes:
                    tags.append(target + "(hole)")
                elif os.path.exists(corpus_file(target)):
                    tags.append(target + "(read)")
                else:
                    tags.append(target)
            handle.write("\n## `%s`\n" % hex(address))
            handle.write("prologue: %s\n" % " | ".join(prologue))
            handle.write("consts: %s\n" % (" ".join(unique_consts) or "-"))
            handle.write("status: %s\n" % (" ".join(sorted(set(errors))) or "-"))
            handle.write("callees: %s\n" % (" ".join(tags[:24]) or "-"))


if __name__ == "__main__":
    raise SystemExit(main())
