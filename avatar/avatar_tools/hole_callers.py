"""Count call sites and data references for each Ghidra-truncated hole.

Why: a hole that nothing calls and nothing points at is dead code, and saying so
with a count is a measurement, not a guess. This walks `.text` one word at a time
(the same trick `decomp_holes.py` uses), records every direct branch-with-link
target, then scans `.data`/`.rdata` for 4-byte words equal to a hole address
(vtable slots and function-pointer tables are the realistic non-call references).

Usage (from avatar_tools):
    python3 hole_callers.py [--list /tmp/dump/text74.txt]
"""

import argparse
import bisect
import collections
import os
import struct

import capstone

import decomp_gaps as D

TEXT_OFFSET, TEXT_SIZE, TEXT_VA = 0x39400, 0x101200, 0x9803A000
XEX = ("../../../src_archive/XBOX HUB/resources/editors/nxe2008/assets/"
       "avatareditor.xex")
DATA_SCAN = [(0x98000000, 0x3000),      # .rdata / read-only
             (0x9813C000, 0x4000)]      # .data


def scan_calls(image, md):
    """target -> list of call-site addresses, for every direct `bl` in `.text`."""
    text = image.read(TEXT_VA, TEXT_SIZE)
    calls = collections.defaultdict(list)
    for index in range(0, len(text), 4):
        word = struct.unpack(">I", text[index:index + 4])[0]
        # Direct branch with link: primary 18, AA=0, LK=1.
        if (word >> 26) == 18 and (word & 3) == 1:
            displacement = word & 0x03FFFFFC
            if displacement & 0x02000000:
                displacement -= 0x04000000
            calls[(TEXT_VA + index + displacement) & 0xFFFFFFFF].append(TEXT_VA + index)
    return calls


def scan_pointers(image, holes):
    found = collections.Counter()
    for start, size in DATA_SCAN:
        blob = image.read(start, size)
        for index in range(0, len(blob) - 3, 4):
            value = struct.unpack(">I", blob[index:index + 4])[0]
            if value in holes:
                found[value] += 1
    return found


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--list", default="/tmp/dump/text74.txt")
    parser.add_argument("--starts", default="/tmp/dump/out5/allfuncs.txt",
                        help="function entries, used to name the function that "
                             "contains each call site")
    args = parser.parse_args(argv)

    image = D.load(XEX)
    md = capstone.Cs(capstone.CS_ARCH_PPC,
                     capstone.CS_MODE_BIG_ENDIAN | capstone.CS_MODE_32)
    addresses = sorted(int(line, 16) for line in open(args.list) if line.strip())
    holes = set(addresses)

    calls = scan_calls(image, md)
    pointers = scan_pointers(image, holes)

    # A call site address is not a function entry; resolve it to the function that
    # contains it, so a hole can be named by its callers instead of by site offsets.
    starts = []
    for line in open(args.starts):
        line = line.strip()
        if line:
            starts.append(int(line.replace("0x", ""), 16))
    starts.sort()

    def container(site):
        index = bisect.bisect_right(starts, site) - 1
        return starts[index] if index >= 0 else None

    def label(site):
        owner = container(site)
        if owner is None:
            return "0x%08x" % site
        raw = "%08x" % owner
        known = os.path.join("/tmp/dc_all/nxenop", "FUN_%s_%s.c" % (raw, raw))
        return "0x%s%s" % (raw, "(readable)" if os.path.exists(known) else "")

    out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "..", "artifacts", "decomp", "HOLES-callers.md")
    out = os.path.normpath(out)
    unreferenced = []
    with open(out, "w") as handle:
        handle.write("# Who references the %d `.text` holes\n\n" % len(addresses))
        handle.write("Direct `bl` sites anywhere in `.text`, plus 4-byte pointers in\n")
        handle.write("`.rdata` (0x98000000+0x3000) and `.data` (0x9813c000+0x4000).\n")
        handle.write("A hole with both counts at zero is dead code.\n\n")
        handle.write("| function | bl call sites | data pointers | callers (readable = has C) |\n")
        handle.write("| --- | ---: | ---: | --- |\n")
        for address in addresses:
            call_count = len(calls.get(address, ()))
            pointer_count = pointers.get(address, 0)
            if not call_count and not pointer_count:
                unreferenced.append(address)
            callers = sorted({label(site) for site in calls.get(address, ())})
            tags = callers[:4]
            handle.write("| `0x%08x` | %d | %d | %s |\n" % (
                address, call_count, pointer_count, " ".join(tags) or "-"))
        handle.write("\n%d of %d holes have neither a caller nor a data pointer: %s\n" % (
            len(unreferenced), len(addresses),
            " ".join("0x%08x" % a for a in unreferenced) or "none"))
    print("wrote %s" % out)
    print("unreferenced: %d of %d" % (len(unreferenced), len(addresses)))
    for address in unreferenced:
        print("  0x%08x" % address)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
