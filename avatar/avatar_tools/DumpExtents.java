// Print the real extent of each address in DUMP_LIST, so the linear decoder in
// decomp_holes.py bounds a function by its own body instead of by the next hole
// address (which over-ran 2 KB into the following function).
//
// Output, one line per address, to $DUMP_OUT/extents.txt:
//   <address> <body bytes>          function exists, this is its size
//   <address> MISSING              no function was created at that address
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import java.io.*;

public class DumpExtents extends GhidraScript {
    public void run() throws Exception {
        String listPath = System.getenv("DUMP_LIST");
        String outPath = System.getenv("DUMP_OUT");
        PrintWriter w = new PrintWriter(new File(outPath, "extents.txt"));
        BufferedReader br = new BufferedReader(new FileReader(listPath));
        String line;
        while ((line = br.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty()) continue;
            Address a = currentProgram.getAddressFactory().getDefaultAddressSpace()
                            .getAddress(Long.parseLong(line.replace("0x", ""), 16));
            Function f = getFunctionAt(a);
            if (f == null) { w.println(line + " MISSING"); continue; }
            w.println(line + " " + f.getBody().getNumAddresses());
        }
        br.close();
        w.close();
        // Ghidra truncates a hole's body at the bad word (many are 8-byte stubs),
        // so a listing cannot be bounded by the body it reports. Print every
        // function entry point instead: the next entry above a hole is the real
        // end of the code that belongs to it.
        PrintWriter all = new PrintWriter(new File(outPath, "allfuncs.txt"));
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            all.println(f.getEntryPoint());
        }
        all.close();
        println("EXTENTS DONE -> " + outPath);
    }
}
