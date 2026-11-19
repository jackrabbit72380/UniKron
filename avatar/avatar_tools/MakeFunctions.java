// Create a function at every address in DUMP_LIST that has none.
//
// The list is the PE's `.pdata` table - the compiler's own function start table,
// 3,295 entries in `.text`. Ghidra's analysis creates only 112 of them as
// functions: it merges a body into its predecessor when the entry is reached by
// fallthrough and has no prologue, and it never creates a body for a function it
// only reaches by tail-jump (`b`, not `bl`). Both are analysis choices, not
// missing code, so the entries are created here from the table and then dumped.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import java.io.*;
public class MakeFunctions extends GhidraScript {
    public void run() throws Exception {
        String list = System.getenv("DUMP_LIST");
        BufferedReader br = new BufferedReader(new FileReader(list));
        String line;
        int made = 0, had = 0, failed = 0;
        while ((line = br.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty()) continue;
            Address a = currentProgram.getAddressFactory().getDefaultAddressSpace()
                            .getAddress(Long.parseLong(line.replace("0x", ""), 16));
            if (getFunctionAt(a) != null) { had++; continue; }
            try {
                if (getInstructionAt(a) == null) disassemble(a);
                Function f = createFunction(a, null);
                if (f != null) made++; else { failed++; println("no function at " + line); }
            } catch (Exception e) {
                failed++;
                println("failed at " + line + ": " + e.getMessage());
            }
        }
        br.close();
        println("MAKEFUNC made=" + made + " existing=" + had + " failed=" + failed);
    }
}
