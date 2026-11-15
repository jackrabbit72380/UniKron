// Decompile every function in the current program to a .c file.
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import java.io.File;
import java.io.PrintWriter;

public class DecompileAll extends GhidraScript {
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String out = args.length > 0 ? args[0] : "/tmp/decompiled";
        new File(out).mkdirs();
        DecompInterface ifc = new DecompInterface();
        ifc.openProgram(currentProgram);
        int ok = 0, fail = 0;
        FunctionIterator it = currentProgram.getFunctionManager().getFunctions(true);
        while (it.hasNext()) {
            monitor.checkCancelled();
            Function f = it.next();
            DecompileResults res = null;
            try {
                res = ifc.decompileFunction(f, 60, monitor);
            } catch (Exception e) {
                fail++;
                continue;
            }
            if (res != null && res.decompileCompleted()) {
                String name = String.format("%s_%08x.c", f.getName(), f.getEntryPoint().getOffset());
                PrintWriter pw = new PrintWriter(new File(out, name));
                pw.print(res.getDecompiledFunction().getC());
                pw.close();
                ok++;
            } else {
                fail++;
            }
        }
        println("DECOMPILED " + ok + " functions, " + fail + " failed, into " + out);
    }
}
