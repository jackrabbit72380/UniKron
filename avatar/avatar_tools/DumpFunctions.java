import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import java.io.*;
public class DumpFunctions extends GhidraScript {
    public void run() throws Exception {
        String list = System.getenv("DUMP_LIST");
        String out = System.getenv("DUMP_OUT");
        DecompInterface ifc = new DecompInterface();
        ifc.openProgram(currentProgram);
        new File(out).mkdirs();
        BufferedReader br = new BufferedReader(new FileReader(list));
        String line;
        int ok = 0, bad = 0;
        while ((line = br.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty()) continue;
            Address a = currentProgram.getAddressFactory().getDefaultAddressSpace()
                            .getAddress(Long.parseLong(line.replace("0x", ""), 16));
            Function f = getFunctionAt(a);
            if (f == null) { println("no function at " + line); bad++; continue; }
            DecompileResults res = ifc.decompileFunction(f, 90, monitor);
            // A function the decompiler gives up on returns null from
            // getDecompiledFunction(); reading through it threw an NPE and
            // aborted the whole run at the first such address (the dump always
            // stopped at 22 of 74), which looked like the runner killing it.
            DecompiledFunction body = res == null ? null : res.getDecompiledFunction();
            PrintWriter w = new PrintWriter(new File(out, line + ".c"));
            if (body == null) {
                w.println("/* decompiler returned no body */");
                w.close();
                println("no body at " + line);
                bad++;
                continue;
            }
            w.println(body.getC());
            w.close();
            ok++;
        }
        br.close();
        ifc.dispose();
        println("DUMP DONE ok=" + ok + " missing=" + bad);
    }
}
