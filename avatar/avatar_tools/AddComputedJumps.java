// Give the decompiler the switch's real case targets.
//
// `switch_tables.py` recomputes each `lhzx`/`lwzx` + `bctr` dispatcher the way the
// code does and writes one row per dispatcher:
//
//   bctr_address <tab> table <tab> base <tab> scale <tab> cases <tab> aligned <tab> targets
//
// Ghidra's own model of these tables lands on addresses like 0x98067b8e - two bytes
// into an instruction - which is what "Instruction at ... overlaps instruction at
// ..." and "Bad instruction count exceeded" report. This adds each recovered target
// as a COMPUTED_JUMP reference from the `bctr`, so the decompiler follows the real
// cases instead of its own table reading. Nothing is invented: every target comes
// from a table word the code itself indexes.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSpace;
import ghidra.program.model.symbol.RefType;
import ghidra.program.model.symbol.SourceType;
import java.io.*;
public class AddComputedJumps extends GhidraScript {
    public void run() throws Exception {
        String tsv = System.getenv("SWITCH_TSV");
        if (tsv == null) { println("SWITCH_TSV not set"); return; }
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();
        BufferedReader br = new BufferedReader(new FileReader(tsv));
        String line;
        int dispatchers = 0, refs = 0;
        while ((line = br.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty()) continue;
            String[] f = line.split("\t");
            if (f.length < 7) continue;
            Address from = sp.getAddress(Long.parseLong(f[0].replace("0x", ""), 16));
            int n = 0;
            for (String t : f[6].split(",")) {
                if (t.trim().isEmpty()) continue;
                Address to = sp.getAddress(Long.parseLong(t.trim().replace("0x", ""), 16));
                currentProgram.getReferenceManager().addMemoryReference(
                        from, to, RefType.COMPUTED_JUMP, SourceType.USER_DEFINED, 0);
                n++;
            }
            dispatchers++;
            refs += n;
            println(String.format("switch 0x%08x cases=%d table=%s base=%s",
                    from.getOffset(), n, f[1], f[2]));
        }
        br.close();
        println("SWITCH dispatchers=" + dispatchers + " computed_jumps=" + refs);
    }
}
