// What is at an address, and what points at it?
//
// For every 4-byte slot in RANGE_LO..RANGE_HI prints the instruction (or
// "undefined"), the function containing it, and every reference to it with the
// referring address and reference type. This is the evidence for deciding whether
// an address the decompiler complains about is code, data, or a misaligned entry
// in a table.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSpace;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.Reference;
public class Around extends GhidraScript {
    public void run() throws Exception {
        long lo = Long.parseLong(System.getenv().getOrDefault("RANGE_LO", "0x98067b70").replace("0x", ""), 16);
        long hi = Long.parseLong(System.getenv().getOrDefault("RANGE_HI", "0x98067bb0").replace("0x", ""), 16);
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();
        for (long a = lo; a < hi; a += 4) {
            Address ad = sp.getAddress(a);
            Instruction i = getInstructionAt(ad);
            Function f = getFunctionContaining(ad);
            StringBuilder refs = new StringBuilder();
            for (Reference r : getReferencesTo(ad)) {
                refs.append(" <- ").append(r.getFromAddress())
                    .append("(").append(r.getReferenceType()).append(")");
            }
            StringBuilder out = new StringBuilder();
            for (Reference r : getReferencesFrom(ad)) {
                out.append(" -> ").append(r.getToAddress())
                   .append("(").append(r.getReferenceType()).append(")");
            }
            println(String.format("0x%08x %-24s %-24s%s%s", a,
                    i == null ? "undefined" : i.toString(),
                    f == null ? "-" : f.getName() + "@" + f.getEntryPoint(),
                    refs, out));
        }
    }
}
