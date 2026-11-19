// Dump every function with a raised bad-data budget.
//
// The 91 "no body" functions fail in FlowInfo::countBadData(), which throws once a
// function reaches Architecture::max_baddata - **4** by default
// (`architecture.cc:1426`). The counter goes up when the decompiler asks for p-code
// at an address that is not an instruction, which is what its own switch recovery
// produces for these tables. Ghidra's docs for the `baddatacount` option say the
// alternative to the fatal error is "artificial halts generated at addresses causing
// the BadDataError, allowing analysis to continue" - i.e. `halt_baddata()` markers.
//
// `DecompileOptions.setMaxBadData` exposes the knob, so this raises it and reports
// exactly what changes: bodies gained, halt markers gained, and the C for every
// function so nothing is silently dropped.
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.*;
import java.io.*;
public class DumpBadData extends GhidraScript {
    public void run() throws Exception {
        String out = System.getenv().getOrDefault("DUMP_OUT", "/tmp/out16");
        int max = Integer.parseInt(System.getenv().getOrDefault("BAD_MAX", "100"));
        String failOut = System.getenv("FAIL_OUT");
        new File(out).mkdirs();
        DecompInterface ifc = new DecompInterface();
        ifc.openProgram(currentProgram);
        DecompileOptions opts = new DecompileOptions();
        opts.grabFromProgram(currentProgram);
        opts.setMaxBadData(max);
        ifc.setOptions(opts);
        PrintWriter fail = failOut == null ? null : new PrintWriter(new File(failOut));
        println("BADMAX set to " + max + " (default is 4)");
        int total = 0, clean = 0, halt = 0, none = 0;
        FunctionIterator it = currentProgram.getFunctionManager().getFunctions(true);
        while (it.hasNext()) {
            monitor.checkCancelled();
            Function f = it.next();
            if (f.isExternal()) continue;
            total++;
            DecompileResults res = null;
            try { res = ifc.decompileFunction(f, 90, monitor); } catch (Exception e) { /* counted below */ }
            DecompiledFunction body = res == null ? null : res.getDecompiledFunction();
            String c = body == null ? null : body.getC();
            long stmts = c == null ? 0 : c.length() - c.replace(";", "").length();
            String why = c == null ? "no_body" : (c.contains("halt_baddata") ? "halt_baddata" : null);
            if (why == null) clean++;
            else if (why.equals("halt_baddata")) halt++;
            else none++;
            if (why != null && fail != null) {
                fail.println(String.format("0x%08x %-28s body=%s..%s stmts=%d %s",
                        f.getEntryPoint().getOffset(), f.getName(),
                        f.getBody().getMinAddress(), f.getBody().getMaxAddress(), stmts, why));
            }
            if (c != null) {
                String base = f.getName().replaceAll("[^A-Za-z0-9_.-]", "_");
                if (base.length() > 110) base = base.substring(0, 100) + "_" + Integer.toHexString(f.getName().hashCode());
                String name = String.format("%s_%08x.c", base, f.getEntryPoint().getOffset());
                PrintWriter pw = new PrintWriter(new File(out, name));
                pw.print(c);
                pw.close();
            }
        }
        if (fail != null) fail.close();
        println("BADMAX total=" + total + " clean=" + clean + " halt=" + halt + " no_body=" + none);
        ifc.dispose();
    }
}
