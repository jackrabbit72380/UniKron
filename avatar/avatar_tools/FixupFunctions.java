// Rebuild function bodies from their own flow.
//
// A body can keep instructions that its own control flow cannot reach: after a
// `b` (unconditional) the bytes may be a table or padding, yet the body still
// lists them, and the decompiler then follows a call in that dead tail into
// undefined memory ("Unable to resolve constructor at 980670ec") and truncates
// every caller that recurses into it. `CreateFunctionCmd.fixupFunctionBody`
// recomputes the body from flow alone, which drops the unreachable tail.
//
//   FIXUP_ADDRS=0x98066e38,0x98067ba4 analyzeHeadless ... -postScript FixupFunctions.java
import ghidra.app.cmd.function.CreateFunctionCmd;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;

public class FixupFunctions extends GhidraScript {
    public void run() throws Exception {
        String list = System.getenv("FIXUP_ADDRS");
        if (list == null) {
            println("FIXUP_ADDRS not set");
            return;
        }
        int fixed = 0, missing = 0;
        for (String a : list.split(",")) {
            a = a.trim();
            if (a.isEmpty()) {
                continue;
            }
            Address ad = toAddr(Long.parseLong(a.replace("0x", ""), 16));
            Function f = getFunctionAt(ad);
            if (f == null) {
                missing++;
                println("no function at " + a);
                continue;
            }
            String before = f.getBody().getMinAddress() + ".." + f.getBody().getMaxAddress();
            CreateFunctionCmd.fixupFunctionBody(currentProgram, f, monitor);
            String after = f.getBody().getMinAddress() + ".." + f.getBody().getMaxAddress();
            println("fixup " + a + " " + before + " -> " + after);
            fixed++;
        }
        println("FIXUP fixed=" + fixed + " missing=" + missing);
    }
}
