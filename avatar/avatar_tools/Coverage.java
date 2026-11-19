// How much of `.text` is actually decoded?
//
// Walks [COV_LO, COV_HI) one address at a time and reports how many addresses lie
// inside a defined instruction and how many are still undefined (padding, or a
// stretch the disassembler never reached), with every undefined run listed.
// This is the measurement behind any "the whole section decodes" claim: it talks
// about bytes, not functions, so it cannot be inflated by function boundaries.
//
// CORRECTION: the first version asked getInstructionAt(), which only answers for an
// instruction's *first* byte, so 3 of every 4 bytes looked undefined (21.5%). The
// containment test is the one that means anything.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSpace;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
public class Coverage extends GhidraScript {
    public void run() throws Exception {
        long lo = Long.parseLong(System.getenv().getOrDefault("COV_LO", "0x9803a000").replace("0x", ""), 16);
        long hi = Long.parseLong(System.getenv().getOrDefault("COV_HI", "0x9813b1dc").replace("0x", ""), 16);
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();
        long total = hi - lo, defined = 0, runs = 0, runLen = 0, runStart = -1;
        for (long a = lo; a < hi; a++) {
            boolean ok = getInstructionContaining(sp.getAddress(a)) != null;
            if (ok) {
                defined++;
                if (runStart >= 0) { println("undefined 0x" + Long.toHexString(runStart) + " len=" + runLen); runStart = -1; runLen = 0; }
            } else {
                if (runStart < 0) { runStart = a; runs++; }
                runLen++;
            }
        }
        if (runStart >= 0) println("undefined 0x" + Long.toHexString(runStart) + " len=" + runLen);
        long insn = 0, inFunc = 0;
        InstructionIterator ii = currentProgram.getListing().getInstructions(
                currentProgram.getAddressFactory().getAddressSet(sp.getAddress(lo), sp.getAddress(hi - 1)), true);
        while (ii.hasNext()) {
            Instruction i = ii.next();
            insn++;
            if (getFunctionContaining(i.getAddress()) != null) inFunc++;
        }
        println("COVERAGE instructions=" + insn + " inside_a_function=" + inFunc + " orphan=" + (insn - inFunc));
        println("COVERAGE bytes=" + total + " decoded=" + defined
                + " undefined=" + (total - defined) + " runs=" + runs
                + " pct=" + String.format("%.4f", 100.0 * defined / total));
    }
}
