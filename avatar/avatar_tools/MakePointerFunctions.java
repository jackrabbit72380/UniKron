// Create a function at every `.rdata` pointer that addresses `.text` and has no
// function yet.
//
// Ghidra's analysis created 3,474 functions, which matches the 3,346 distinct `bl`
// targets closely - so the functions it did find are the directly-called ones.
// What it did not do is turn the remaining code pointers (vtables and callback
// tables in `.rdata`) into function starts, which is why 27,346 decoded
// instructions sit outside every body.
//
// This only creates a function where `getFunctionContaining` is null, so an
// existing body is never split and no overlap is introduced (the mistake that
// broke the `.pdata` round).
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSpace;
import ghidra.program.model.listing.Function;
import ghidra.program.model.mem.Memory;
import ghidra.program.model.mem.MemoryBlock;
import java.util.*;
public class MakePointerFunctions extends GhidraScript {
    public void run() throws Exception {
        final long TEXT_START = 0x9803a000L, TEXT_END = 0x9813b1dcL;
        final long RDATA_START = 0x98000400L, RDATA_END = 0x98032a50L;
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();
        Memory mem = currentProgram.getMemory();
        Set<Long> targets = new TreeSet<>();
        for (long a = RDATA_START; a + 4 <= RDATA_END; a += 4) {
            Address ad = sp.getAddress(a);
            if (getInstructionAt(ad) != null) continue;   // keep code out of this
            long v = mem.getInt(ad) & 0xffffffffL;        // big-endian by language
            if (v >= TEXT_START && v < TEXT_END) targets.add(v);
        }
        println("PTRFN .rdata code pointers into .text: " + targets.size());
        int already = 0, insideBody = 0, made = 0, noCode = 0, failed = 0;
        for (long t : targets) {
            Address a = sp.getAddress(t);
            if (getFunctionAt(a) != null) { already++; continue; }
            if (getFunctionContaining(a) != null) { insideBody++; continue; }
            if (getInstructionAt(a) == null) {
                try { disassemble(a); } catch (Exception e) { noCode++; continue; }
            }
            try {
                Function f = createFunction(a, null);
                if (f != null) made++; else { failed++; println("no function at 0x" + Long.toHexString(t)); }
            } catch (Exception e) {
                failed++;
                println("failed at 0x" + Long.toHexString(t) + ": " + e.getMessage());
            }
        }
        println("PTRFN already=" + already + " inside_existing_body=" + insideBody
                + " created=" + made + " no_code=" + noCode + " failed=" + failed);
    }
}
