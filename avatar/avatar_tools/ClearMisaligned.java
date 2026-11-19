// Remove instructions that sit at a non-4-byte-aligned address.
//
// PowerPC has no 2-byte instruction, so an instruction at an odd or half-word
// address cannot be code. A few of them exist in `.text` here, and they poison
// whole functions: the decompiler reports
//   Instruction at (ram,0x9803e922) overlaps instruction at (ram,0x9803e920)
//   No pcode could be generated at address: r0x98043c95
// and gives up on every function whose body reaches one. The failing functions in
// FailList all name addresses like that, so the fix is to clear them, not to
// change the decompiler.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSpace;
import ghidra.program.model.listing.*;
import java.util.*;
public class ClearMisaligned extends GhidraScript {
    public void run() throws Exception {
        final long TEXT_START = 0x9803a000L, TEXT_END = 0x9813bfffL;
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();
        List<Address> bad = new ArrayList<>();
        InstructionIterator it = currentProgram.getListing().getInstructions(
                currentProgram.getAddressFactory().getAddressSet(
                        sp.getAddress(TEXT_START), sp.getAddress(TEXT_END)), true);
        while (it.hasNext()) {
            Instruction i = it.next();
            if ((i.getAddress().getOffset() & 3L) != 0) bad.add(i.getAddress());
        }
        println("MISALIGNED found=" + bad.size());
        for (Address a : bad) {
            println("  clearing 0x" + Long.toHexString(a.getOffset()));
            Function f = getFunctionContaining(a);
            if (f != null) removeFunction(f);
            clearListing(a, a.add(3));
        }
        println("MISALIGNED cleared=" + bad.size());
    }
}
