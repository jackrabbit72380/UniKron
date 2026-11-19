#!/usr/bin/env python3
"""Hand listings for the functions Ghidra will not decompile.

The corpus's decompiler produces 5,104 of 5,224 function bodies. For the rest this
writes a linear listing using `decomp_holes.decode_function`, which walks one word
at a time (Capstone stops at the first Xenon word it cannot decode) and resolves
`lis`/`addi` data references. The point is to have the instructions and their data
references readable for every function, so nothing in `.text` is left as an
unread blob while the decompiler question stays open.

  FAIL_ENTRIES=/tmp/fail_entries.txt python3 list_failures.py
"""
import glob
import os
import sys

import decomp_holes as H
import decomp_gaps as D

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "artifacts", "decomp", "failing"))
DUMP_DIR = os.environ.get("DUMP_DIR", "/tmp/out15")


def function_starts():
    starts = []
    for path in glob.glob(os.path.join(DUMP_DIR, "*.c")):
        stem = os.path.basename(path)[:-2]
        try:
            starts.append(int(stem.rsplit("_", 1)[1], 16))
        except (IndexError, ValueError):
            continue
    return sorted(starts)


def main():
    entries = [line for line in sys.argv[1:] if line.strip()]
    if not entries:
        sys.stderr.write("usage: list_failures.py <address> [address...]\n")
        return 1
    image = D.load("../../../src_archive/XBOX HUB/resources/editors/nxe2008/assets/"
                   "avatareditor.xex")
    starts = function_starts()
    md = H.make_decoder()
    os.makedirs(OUT, exist_ok=True)
    summary = []
    for text in entries:
        address = int(text, 16)
        size = H.MAX_FUNCTION
        later = [s for s in starts if s > address]
        if later:
            size = min(later[0] - address, H.MAX_FUNCTION)
        size = min(size, H.TEXT_END - address)
        rows = H.decode_function(md, image, address, size)
        kinds, calls, targets, returns = H.summarise(rows)
        path = os.path.join(OUT, "0x%08x.txt" % address)
        with open(path, "w") as handle:
            handle.write("# 0x%08x  %d bytes  %d rows  (hand listing; the decompiler "
                         "gave no body)\n" % (address, size, len(rows)))
            handle.write("# unknown=%d scalar=%d call=%d branch=%d returns=%d\n" % (
                kinds["unknown"], kinds["scalar"], kinds["call"], kinds["branch"], returns))
            handle.write("# calls: %s\n" % (" ".join(calls) or "-"))
            handle.write("# branches: %s\n\n" % (" ".join(targets[:40]) or "-"))
            for row_address, word, text2, width in rows:
                handle.write("%08x  %08x  %-38s %s\n" % (
                    row_address, word, text2, "" if width == 4 else "=8b"))
        summary.append((address, size, len(rows), kinds["unknown"], kinds["scalar"],
                        kinds["call"], kinds["branch"]))
        print("0x%08x size=%d rows=%d unknown=%d" % (
            address, size, len(rows), kinds["unknown"]))
    with open(os.path.join(OUT, "SUMMARY.md"), "w") as handle:
        handle.write("# Hand listings for the functions with no decompiler body\n\n")
        handle.write("| entries | %d |\n| --- | ---: |\n" % len(summary))
        handle.write("\n| address | bytes | rows | unknown words | scalar | call | branch |\n")
        handle.write("| --- | ---: | ---: | ---: | ---: | ---: | ---: |\n")
        for address, size, rows, unknown, scalar, call, branch in summary:
            handle.write("| `0x%08x` | %d | %d | %d | %d | %d | %d |\n" % (
                address, size, rows, unknown, scalar, call, branch))
    return 0


if __name__ == "__main__":
    sys.exit(main())
