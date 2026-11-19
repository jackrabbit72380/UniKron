// Mark callees that never return, from the shape the compiler left behind.
//
// A noreturn call is compiled as a `bl` whose following word is zero padding: no
// `blr`, no return path, because the callee (a throw/exit chain) cannot come back.
// Ghidra has no way to know that from the call alone, so it keeps flowing past the
// `bl` into the padding, fails to decode it ("Unable to resolve constructor at
// 980670ec") and truncates every caller with halt_baddata.
//
// Earlier rounds found five of these by hand and fixed three functions with them.
// This sweeps the whole .text for the shape instead: a function whose last
// instruction is `bl`/`b` and whose next four bytes are zero marks its target as
// no-return. Nothing is guessed - a zero word after a call cannot be code.
//
//   analyzeHeadless ... -process nxe2008.elf -noanalysis -postScript MarkNoReturnTails.java
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.symbol.Reference;
import java.util.*;

public class MarkNoReturnTails extends GhidraScript {
    public void run() throws Exception {
        final long TEXT_START = 0x9803a000L, TEXT_END = 0x9813b1dcL;
        int tails = 0, marked = 0, already = 0, unknown = 0;
        Set<Long> seen = new HashSet<>();
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            long entry = f.getEntryPoint().getOffset();
            if (entry < TEXT_START || entry >= TEXT_END) {
                continue;
            }
            Instruction last = null;
            for (Instruction ins : currentProgram.getListing().getInstructions(f.getBody(), true)) {
                last = ins;
            }
            if (last == null) {
                continue;
            }
            String m = last.getMnemonicString();
            if (!m.equals("bl") && !m.equals("b")) {
                continue;
            }
            Address next = last.getAddress().add(last.getLength());
            if (next.getOffset() + 4 > TEXT_END) {
                continue;
            }
            if (getInt(next) != 0) {
                continue;
            }
            tails++;
            Address target = null;
            for (Reference r : last.getReferencesFrom()) {
                if (r.getReferenceType().isCall() || r.getReferenceType().isJump()) {
                    target = r.getToAddress();
                    break;
                }
            }
            if (target == null) {
                for (Address a : last.getFlows()) {
                    target = a;
                    break;
                }
            }
            if (target == null) {
                unknown++;
                continue;
            }
            Function callee = getFunctionAt(target);
            if (callee == null) {
                callee = getFunctionContaining(target);
            }
            if (callee == null) {
                println("tail at 0x" + Long.toHexString(last.getAddress().getOffset())
                        + " -> 0x" + Long.toHexString(target.getOffset()) + " (no function)");
                unknown++;
                continue;
            }
            if (callee.hasNoReturn()) {
                already++;
                continue;
            }
            callee.setNoReturn(true);
            marked++;
            println("noreturn 0x" + Long.toHexString(callee.getEntryPoint().getOffset())
                    + " (tail at 0x" + Long.toHexString(last.getAddress().getOffset()) + ")");
        }
        println("NORETURN tails=" + tails + " marked=" + marked + " already=" + already
                + " unknown=" + unknown);
    }
}
