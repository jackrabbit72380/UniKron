// Remove functions that were invented outside .text.
//
// The function set is built from the .pdata model plus MakeRunFunctions, which
// creates a candidate at every word that follows a terminator. Past the end of
// .text (0x9813b1dc, measured from the rebased PE) that lands in a data region,
// and the result is one-word "functions" whose single word is not PowerPC code at
// all - 01000210, 010101f5, 010002f5. They can never decompile, so they are not
// failures of the decompiler, they are not functions.
//
//   TEXT_LO=0x9803a000 TEXT_HI=0x9813b1dc analyzeHeadless ... -postScript DeleteForeignFunctions.java
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;

public class DeleteForeignFunctions extends GhidraScript {
    public void run() throws Exception {
        long lo = Long.parseLong(System.getenv("TEXT_LO").replace("0x", ""), 16);
        long hi = Long.parseLong(System.getenv("TEXT_HI").replace("0x", ""), 16);
        int seen = 0, kept = 0, removed = 0;
        FunctionIterator it = currentProgram.getFunctionManager().getFunctions(true);
        java.util.List<Function> doomed = new java.util.ArrayList<>();
        while (it.hasNext()) {
            Function f = it.next();
            if (f.isExternal()) continue;
            long e = f.getEntryPoint().getOffset();
            if (e >= lo && e < hi) { kept++; continue; }
            seen++;
            doomed.add(f);
        }
        for (Function f : doomed) {
            println("foreign " + f.getEntryPoint() + " body="
                    + f.getBody().getMinAddress() + ".." + f.getBody().getMaxAddress());
            removeFunction(f);
            removed++;
        }
        println("FOREIGN outside=" + seen + " removed=" + removed + " in_text=" + kept);
    }
}
