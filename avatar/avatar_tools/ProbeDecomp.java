// Diagnostic for the few addresses Ghidra will not turn into C.
//
// For each address it prints what the listing thinks is there - the containing
// function, its entry, its full extent and whether it is flagged thunk or
// no-return - and then decompiles that function with a timeout the caller sets,
// reporting how long it took, the completion message and the first lines.
//
//   PROBE_ADDRS=0x98120c80,0x9804d2f8 PROBE_SECS=300 support/analyzeHeadless ...
//       -postScript ProbeDecomp.java
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import java.util.*;
public class ProbeDecomp extends GhidraScript {
    public void run() throws Exception {
        String addrs = System.getenv("PROBE_ADDRS");
        String secsS = System.getenv("PROBE_SECS");
        int secs = secsS == null ? 120 : Integer.parseInt(secsS);
        DecompInterface ifc = new DecompInterface();
        ifc.openProgram(currentProgram);
        for (String a : (addrs == null ? "" : addrs).split(",")) {
            if (a.trim().isEmpty()) continue;
            long v = Long.parseLong(a.trim().replace("0x", ""), 16);
            Address ad = currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
            println("=== " + a.trim());
            Function c = getFunctionContaining(ad);
            if (c == null) {
                println("  containing: none");
            } else {
                println("  containing: " + c.getName() + " entry=" + c.getEntryPoint()
                        + " body=" + c.getBody().getMinAddress() + ".." + c.getBody().getMaxAddress()
                        + " thunk=" + c.isThunk() + " noreturn=" + c.hasNoReturn());
            }
            Function f = getFunctionAt(ad);
            if (f == null) f = c;
            if (f == null) { println("  no function to decompile"); continue; }
            long t0 = System.currentTimeMillis();
            DecompileResults res = ifc.decompileFunction(f, secs, monitor);
            long ms = System.currentTimeMillis() - t0;
            DecompiledFunction body = res == null ? null : res.getDecompiledFunction();
            println("  decompiled=" + f.getName() + " in " + ms + " ms"
                    + " completed=" + (res != null && res.decompileCompleted())
                    + " body=" + (body != null));
            if (res != null) println("  message: " + res.getErrorMessage());
            if (body != null) {
                String[] lines = body.getC().split("\n");
                int stmts = body.getC().length() - body.getC().replace(";", "").length();
                println("  stmts=" + stmts + " halt=" + body.getC().contains("halt_baddata"));
                for (int i = 0; i < Math.min(6, lines.length); i++) println("  | " + lines[i]);
            }
        }
        ifc.dispose();
    }
}
