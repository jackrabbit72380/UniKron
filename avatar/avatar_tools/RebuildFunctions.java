// Rebuild the .text function set from `.pdata` alone.
//
// `MakeFunctions` created the 3,182 missing entries on top of Ghidra's own
// analysis, so a new entry often landed inside a body Ghidra had already
// swallowed - two overlapping functions over the same bytes, which is what the
// decompiler then reports as "overlapping instruction" and "Bad instruction
// count exceeded". This removes every function whose entry is in `.text` and
// recreates them all, in ascending order, from the `.pdata` list, so no body
// can overlap another entry.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSpace;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import java.io.*;
import java.util.*;
public class RebuildFunctions extends GhidraScript {
    public void run() throws Exception {
        final long TEXT_START = 0x9803a000L, TEXT_END = 0x9813b1dcL;
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();

        List<Long> starts = new ArrayList<>();
        BufferedReader br = new BufferedReader(new FileReader(System.getenv("DUMP_LIST")));
        String line;
        while ((line = br.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty()) continue;
            starts.add(Long.parseLong(line.replace("0x", ""), 16));
        }
        br.close();
        Collections.sort(starts);

        List<Function> doomed = new ArrayList<>();
        FunctionIterator it = currentProgram.getFunctionManager().getFunctions(true);
        while (it.hasNext()) {
            Function f = it.next();
            long e = f.getEntryPoint().getOffset();
            if (e >= TEXT_START && e < TEXT_END) doomed.add(f);
        }
        for (Function f : doomed) removeFunction(f);
        println("REBUILD removed=" + doomed.size() + " pdata=" + starts.size());

        int made = 0, failed = 0;
        for (long s : starts) {
            Address a = sp.getAddress(s);
            try {
                if (getInstructionAt(a) == null) disassemble(a);
                Function f = getFunctionAt(a);
                if (f == null) f = createFunction(a, null);
                if (f != null) made++; else failed++;
            } catch (Exception e) {
                failed++;
                println("failed at " + Long.toHexString(s) + ": " + e.getMessage());
            }
        }
        println("REBUILD created=" + made + " failed=" + failed);
    }
}
