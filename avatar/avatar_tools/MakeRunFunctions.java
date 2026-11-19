// Create a function at every undecoded address that directly follows a terminator.
//
// The stretches of `.text` Ghidra's analysis left undefined are not data: 90.2% of
// their words decode, none are jump tables, and 92.4% of those bytes lie inside a
// `.pdata` record. What they have in common is where they start - 2,324 of the
// 2,331 runs begin right after `blr` (1,205) or `b` (1,041), i.e. at the first
// instruction of a function nothing calls directly.
//
// So the rule is the compiler's own: after a terminator, the next instruction can
// only be a function entry. This disassembles there and creates the function with
// a flow body, and only where no function contains the address, so existing bodies
// are never split.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSpace;
import ghidra.program.model.listing.*;
import java.util.*;
public class MakeRunFunctions extends GhidraScript {
    static final Set<String> TERM = new HashSet<>(Arrays.asList(
            "blr", "b", "bctr", "bctrl", "bclr", "rfi"));
    public void run() throws Exception {
        final long TEXT_START = 0x9803a000L, TEXT_END = 0x9813b1dcL;
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();
        int cand = 0, made = 0, failed = 0, noCode = 0, inBody = 0;
        for (long a = TEXT_START + 4; a < TEXT_END; a += 4) {
            Address ad = sp.getAddress(a);
            if (getInstructionAt(ad) != null) continue;
            Instruction prev = getInstructionBefore(ad);
            if (prev == null || !TERM.contains(prev.getMnemonicString())) continue;
            cand++;
            try { disassemble(ad); } catch (Exception e) { noCode++; continue; }
            if (getInstructionAt(ad) == null) { noCode++; continue; }
            if (getFunctionContaining(ad) != null) { inBody++; continue; }
            try {
                Function f = createFunction(ad, null);
                if (f != null) made++; else { failed++; println("no function at 0x" + Long.toHexString(a)); }
            } catch (Exception e) {
                failed++;
                println("failed at 0x" + Long.toHexString(a) + ": " + e.getMessage());
            }
        }
        println("RUNFN candidates=" + cand + " created=" + made + " in_existing_body=" + inBody
                + " no_code=" + noCode + " failed=" + failed);
    }
}
