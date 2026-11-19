// Which functions still do not decompile, and why?
//
// Walks the whole function manager, decompiles each function, and prints a line
// for every one that does not complete or whose C carries `halt_baddata`, with
// the decompiler's own message, the body extent and statement count. This is the
// evidence for whatever the remaining failure count is.
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import java.io.*;
public class FailList extends GhidraScript {
    public void run() throws Exception {
        String out = System.getenv("FAIL_OUT");
        PrintWriter w = out == null ? null : new PrintWriter(new File(out));
        DecompInterface ifc = new DecompInterface();
        ifc.openProgram(currentProgram);
        int total = 0, halt = 0, none = 0, clean = 0;
        FunctionIterator it = currentProgram.getFunctionManager().getFunctions(true);
        while (it.hasNext()) {
            monitor.checkCancelled();
            Function f = it.next();
            if (f.isExternal()) continue;
            total++;
            DecompileResults res = null;
            String msg = "";
            try { res = ifc.decompileFunction(f, 60, monitor); }
            catch (Exception e) { msg = "exception: " + e.getMessage(); }
            DecompiledFunction body = res == null ? null : res.getDecompiledFunction();
            String c = body == null ? null : body.getC();
            String why = null;
            if (c == null) {
                why = "no_body " + (msg.isEmpty() && res != null ? res.getErrorMessage() : msg);
                none++;
            } else if (c.contains("halt_baddata")) {
                why = "halt_baddata";
                halt++;
            } else {
                clean++;
            }
            if (why != null) {
                long stmts = c == null ? 0 : c.length() - c.replace(";", "").length();
                String line = String.format("0x%08x %-40s body=%s..%s stmts=%d %s",
                        f.getEntryPoint().getOffset(), f.getName(),
                        f.getBody().getMinAddress(), f.getBody().getMaxAddress(), stmts, why);
                println("FAIL " + line);
                if (w != null) w.println(line);
            }
        }
        println("FAILLIST total=" + total + " clean=" + clean + " halt=" + halt + " no_body=" + none);
        if (w != null) w.close();
        ifc.dispose();
    }
}
