"""Neutralise Xenon `vmx128` words so the rest of a function can be decompiled.

Ghidra's PowerPC module decodes the 64-bit integer instructions the 2008 editor
uses once the image is imported as `PowerPC:BE:64:64-32addr`, but it still stops
at `vmx128` - the Xenon 128-bit vector extension, which is not in any shipped
PowerPC language. A function whose first block holds one decompiles to
`halt_baddata()` and its body is lost.

This rewrites every word that neither Capstone nor a plain pattern test can
decode to `nop` (`0x60000000`) in a *copy* of the image, and writes the list of
patched addresses beside it. The result decompiles: calls, string references and
scalar code all survive, while the vector maths is simply absent. It is a reading
aid, never something to run - the patched image executes different code.

    python3 patch_vmx128.py IN.elf OUT.elf patches.json
"""

import argparse
import json
import struct
import sys

from capstone import Cs, CS_ARCH_PPC, CS_MODE_BIG_ENDIAN

NOP = 0x60000000
# Defaults are the `mkelf.py` ELF; pass --text-offset/--text-size for the raw
# PE that Ghidra imports for this editor (`.text` at 0x3400, 0x101200 bytes).
TEXT_VA = 0x9803A000
TEXT_OFFSET = 0x39C54
TEXT_SIZE = 0x101200

# Primary opcodes that carry vector instructions on Xenon. 4 is the VMX/Altivec
# block, 5 and 6 are the Xenon vperm/vA forms (`altv207_13`, `altv300_21` in
# Ghidra's C, which is what actually truncates the bodies), 12/13 are the vector
# load/store forms. Measured over the 74 unreadable `.text` functions: the words
# at the truncation points are primary 4 (864), 5 (418) and 6 (611), so patching
# only 4 - the old default - left the two forms that stop Ghidra in place.
VECTOR_PRIMARY = {4, 5, 6, 12, 13}


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("source")
    parser.add_argument("target")
    parser.add_argument("report")
    parser.add_argument("--text-offset", type=lambda s: int(s, 0), default=TEXT_OFFSET)
    parser.add_argument("--text-size", type=lambda s: int(s, 0), default=TEXT_SIZE)
    parser.add_argument("--text-va", type=lambda s: int(s, 0), default=TEXT_VA)
    parser.add_argument("--force", action="store_true",
                        help="ignore the decode limit: Capstone stops its linear "
                             "sweep at the first word it cannot decode, so every "
                             "word past that point looks undecodable - including "
                             "vector forms it does understand - and the already-valid "
                             "test would then let Xenon forms through untouched")
    args = parser.parse_args(argv[1:])
    source, target, report = args.source, args.target, args.report
    offset, size, text_va = args.text_offset, args.text_size, args.text_va
    data = bytearray(open(source, "rb").read())
    decoder = Cs(CS_ARCH_PPC, CS_MODE_BIG_ENDIAN)
    patched = []
    text = bytes(data[offset:offset + size])
    valid = set()
    for instruction in decoder.disasm(text, text_va):
        valid.add(instruction.address)
    for index in range(0, len(text), 4):
        address = text_va + index
        if address in valid and not args.force:
            continue
        word, = struct.unpack_from(">I", text, index)
        if word == 0:
            continue
        if (word >> 26) not in VECTOR_PRIMARY:
            continue
        struct.pack_into(">I", data, offset + index, NOP)
        patched.append(address)
    open(target, "wb").write(data)
    json.dump({"patched": patched, "count": len(patched)}, open(report, "w"), indent=1)
    print(f"{len(patched)} words neutralised -> {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
