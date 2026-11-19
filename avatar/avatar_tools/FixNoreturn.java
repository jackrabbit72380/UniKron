// Import trampolines tail-jump into the virtual-only gap at 0x9813b1dc..0x9813c000,
// so the analyser marks them "does not return" and truncates every caller at the
// call site. Clear that flag for those callees and re-decompile the callers.
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.FlowType;
import java.util.*;
public class FixNoreturn extends GhidraScript {
    public void run() throws Exception {
        long GAP = 0x9813b1dcL;
        List<Function> tramps = new ArrayList<>();
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            Address e = f.getEntryPoint();
            if (e.getOffset() < 0x9803a000L || e.getOffset() > GAP) continue;
            InstructionIterator it = currentProgram.getListing().getInstructions(f.getBody(), true);
            boolean jumps = false;
            while (it.hasNext()) {
                Instruction i = it.next();
                if (!i.getFlowType().isJump()) continue;
                Address[] fl = i.getFlows();
                for (Address t : fl) if (t.getOffset() >= GAP && t.getOffset() < 0x9813c000L) jumps = true;
            }
            if (jumps && f.hasNoReturn()) tramps.add(f);
        }
        println("trampolines marked noreturn: " + tramps.size());
        for (Function f : tramps) {
            f.setNoReturn(false);
            println("  cleared " + f.getEntryPoint());
        }
        DecompInterface ifc = new DecompInterface();
        ifc.openProgram(currentProgram);
        for (String s : System.getenv("RECHECK").split(",")) {
            Address a = currentProgram.getAddressFactory().getDefaultAddressSpace()
                            .getAddress(Long.parseLong(s.trim().replace("0x",""),16));
            Function f = getFunctionAt(a);
            if (f == null) { println("RECHECK " + s.trim() + " no function"); continue; }
            DecompileResults res = ifc.decompileFunction(f, 120, monitor);
            DecompiledFunction body = res == null ? null : res.getDecompiledFunction();
            String c = body == null ? "(null)" : body.getC();
            boolean bad = c.contains("halt_baddata");
            println("RECHECK " + s.trim() + " stmts=" + (c.length() - c.replace(";","").length())
                    + " halt_baddata=" + bad);
        }
        ifc.dispose();
    }
}
