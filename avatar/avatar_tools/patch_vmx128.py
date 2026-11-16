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

import json
import struct
import sys

from capstone import Cs, CS_ARCH_PPC, CS_MODE_BIG_ENDIAN

NOP = 0x60000000
TEXT_VA = 0x9803A000
TEXT_OFFSET = 0x39C54
TEXT_SIZE = 0x101200

# Primary opcodes that carry vector instructions on Xenon. 4 is the VMX/Altivec
# block; 12/13 are the vector load/store forms.
VECTOR_PRIMARY = {4, 12, 13}


def main(argv):
    if len(argv) != 4:
        print(__doc__.strip())
        return 2
    source, target, report = argv[1], argv[2], argv[3]
    data = bytearray(open(source, "rb").read())
    decoder = Cs(CS_ARCH_PPC, CS_MODE_BIG_ENDIAN)
    patched = []
    text = bytes(data[TEXT_OFFSET:TEXT_OFFSET + TEXT_SIZE])
    valid = set()
    for instruction in decoder.disasm(text, TEXT_VA):
        valid.add(instruction.address)
    for index in range(0, len(text), 4):
        address = TEXT_VA + index
        if address in valid:
            continue
        word, = struct.unpack_from(">I", text, index)
        if word == 0:
            continue
        if (word >> 26) not in VECTOR_PRIMARY:
            continue
        struct.pack_into(">I", data, TEXT_OFFSET + index, NOP)
        patched.append(address)
    open(target, "wb").write(data)
    json.dump({"patched": patched, "count": len(patched)}, open(report, "w"), indent=1)
    print(f"{len(patched)} words neutralised -> {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
