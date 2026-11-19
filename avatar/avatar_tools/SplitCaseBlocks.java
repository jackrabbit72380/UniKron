// Give every recovered switch case block its own function.
//
// The 91 no-body functions are dispatchers whose case blocks live in a neighbour's
// body: `FUN_98067a50` ends at a `bctr` at 0x98067ba0 and its eight cases are at
// 0x98066fa4..0x98067174, inside `FUN_98066e38`. Following them from the dispatcher
// is what runs the decompiler past its instruction limit ("Bad instruction count
// exceeded"), and adding the targets as COMPUTED_JUMP references did not change
// that, so the ownership itself is the thing to change: split each case block out
// as a function of its own. The dispatcher then jumps to other functions instead of
// walking into its own body's tail.
//
// Only addresses from `switch_tables.py` are used - every one of them is a table
// word the code itself indexes, nothing is invented.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSpace;
import ghidra.program.model.listing.Function;
import java.io.*;
import java.util.*;
public class SplitCaseBlocks extends GhidraScript {
    public void run() throws Exception {
        String tsv = System.getenv("SWITCH_TSV");
        if (tsv == null) { println("SWITCH_TSV not set"); return; }
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();
        Set<Long> targets = new TreeSet<>();
        BufferedReader br = new BufferedReader(new FileReader(tsv));
        String line;
        while ((line = br.readLine()) != null) {
            String[] f = line.trim().split("\t");
            if (f.length < 7) continue;
            for (String t : f[6].split(",")) {
                if (!t.trim().isEmpty()) {
                    targets.add(Long.parseLong(t.trim().replace("0x", ""), 16));
                }
            }
        }
        br.close();
        println("CASES distinct_targets=" + targets.size());
        int entry = 0, insideBody = 0, made = 0, failed = 0;
        for (long t : targets) {
            Address a = sp.getAddress(t);
            if (getFunctionAt(a) != null) { entry++; continue; }
            if (getFunctionContaining(a) == null) continue;
            insideBody++;
            try {
                Function f = createFunction(a, "case_" + Long.toHexString(t));
                if (f != null) made++; else { failed++; println("no function at 0x" + Long.toHexString(t)); }
            } catch (Exception e) {
                failed++;
                println("failed at 0x" + Long.toHexString(t) + ": " + e.getMessage());
            }
        }
        println("CASES already_entries=" + entry + " inside_body=" + insideBody
                + " split=" + made + " failed=" + failed);
    }
}
