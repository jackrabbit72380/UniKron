// Count the control-flow references into a zero-filled region.
//
// The head of `.text` (0x9803a000-0x9803ac00) is all zeros in the shipped file
// and holds 25 `.pdata` function entries. If no instruction in `.text` flows
// there, they are dead table entries over absent code, not functions the
// decompiler failed on. RANGE_LO / RANGE_HI set the window.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import java.util.*;
public class ScanRangeRefs extends GhidraScript {
    public void run() throws Exception {
        long lo = Long.parseLong(System.getenv("RANGE_LO").replace("0x", ""), 16);
        long hi = Long.parseLong(System.getenv("RANGE_HI").replace("0x", ""), 16);
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();
        Address s = sp.getAddress(0x9803a000L), e = sp.getAddress(0x9813b1dcL);
        Set<Long> targets = new TreeSet<>();
        int insns = 0;
        InstructionIterator it = currentProgram.getListing().getInstructions(
            currentProgram.getAddressFactory().getAddressSet(s, e), true);
        while (it.hasNext()) {
            Instruction in = it.next();
            insns++;
            for (Address t : in.getFlows()) {
                long v = t.getOffset();
                if (v >= lo && v < hi) targets.add(v);
            }
        }
        println("SCAN insns=" + insns + " targets=" + targets.size());
        StringBuilder sb = new StringBuilder();
        for (long t : targets) sb.append(Long.toHexString(t)).append(' ');
        println("TARGETS " + sb);
    }
}
