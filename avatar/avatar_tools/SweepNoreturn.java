// A function whose last instruction is `bl` and which is followed by zero padding
// has no `blr`: the compiler knew the callee never returns (throw/exit chains).
// Mark each such callee `no return` so its callers stop falling off the end, then
// report whether the listed functions still carry halt_baddata.
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.*;
import java.util.*;
public class SweepNoreturn extends GhidraScript {
    public void run() throws Exception {
        List<Function> callees = new ArrayList<>();
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            InstructionIterator it = currentProgram.getListing().getInstructions(f.getBody(), true);
            Instruction last = null;
            while (it.hasNext()) last = it.next();
            if (last == null) continue;
            if (!last.getMnemonicString().equals("bl")) continue;
            Address[] fl = last.getFlows();
            if (fl.length != 1) continue;
            Function target = getFunctionAt(fl[0]);
            if (target != null && !target.hasNoReturn()) callees.add(target);
        }
        Set<Function> uniq = new LinkedHashSet<>(callees);
        for (Function f : uniq) { f.setNoReturn(true); }
        println("marked noreturn: " + uniq.size());
        DecompInterface ifc = new DecompInterface();
        ifc.openProgram(currentProgram);
        int clean = 0, bad = 0;
        String rl = System.getenv("RECHECK");
        for (String s : (rl == null ? "" : rl).split(",")) {
            if (s.trim().isEmpty()) continue;
            Address a = currentProgram.getAddressFactory().getDefaultAddressSpace()
                            .getAddress(Long.parseLong(s.trim().replace("0x",""),16));
            Function f = getFunctionAt(a);
            if (f == null) { println("RECHECK " + s.trim() + " no function"); continue; }
            DecompileResults res = ifc.decompileFunction(f, 120, monitor);
            DecompiledFunction body = res == null ? null : res.getDecompiledFunction();
            String c = body == null ? "" : body.getC();
            boolean isBad = c.contains("halt_baddata");
            if (isBad) bad++; else clean++;
            println("RECHECK " + s.trim() + " stmts=" + (c.length() - c.replace(";","").length()) + " halt_baddata=" + isBad);
        }
        println("SUMMARY clean=" + clean + " bad=" + bad);
        ifc.dispose();
    }
}
