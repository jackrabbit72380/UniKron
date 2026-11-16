// Decompile every function in the current program, skipping ones already written,
// so a run that is killed can be resumed against the same project.
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import java.io.File;
import java.io.PrintWriter;

public class DecompileResume extends GhidraScript {
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String out = args.length > 0 ? args[0] : "/tmp/decompiled";
        new File(out).mkdirs();
        DecompInterface ifc = new DecompInterface();
        ifc.openProgram(currentProgram);
        int ok = 0, skip = 0, fail = 0;
        FunctionIterator it = currentProgram.getFunctionManager().getFunctions(true);
        while (it.hasNext()) {
            monitor.checkCancelled();
            Function f = it.next();
            String base = f.getName().replaceAll("[^A-Za-z0-9_.-]", "_");
            if (base.length() > 110) {
                base = base.substring(0, 100) + "_" + Integer.toHexString(f.getName().hashCode());
            }
            String name = String.format("%s_%08x.c", base, f.getEntryPoint().getOffset());
            File target = new File(out, name);
            if (target.exists() && target.length() > 0) {
                skip++;
                continue;
            }
            DecompileResults res = null;
            try {
                res = ifc.decompileFunction(f, 60, monitor);
            } catch (Exception e) {
                fail++;
                continue;
            }
            if (res != null && res.decompileCompleted()) {
                PrintWriter pw = new PrintWriter(target);
                pw.print(res.getDecompiledFunction().getC());
                pw.close();
                ok++;
            } else {
                fail++;
            }
            if ((ok + skip) % 500 == 0) {
                println("PROGRESS " + ok + " written, " + skip + " already there, " + fail + " failed");
            }
        }
        println("DECOMPILED " + ok + " new, " + skip + " skipped, " + fail + " failed, into " + out);
    }
}
