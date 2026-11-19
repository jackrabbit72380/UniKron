// Hand the decompiler each switch's real destinations as an override jump table.
//
// `AddComputedJumps.java` only added COMPUTED_JUMP references, and measured that it
// changed nothing (5,104 clean either way). Ghidra's own supported route is the one
// its `SwitchOverride.java` script takes interactively: put the case addresses on the
// `bctr` as computed jumps *and* write an override `JumpTable` into the function's
// namespace. `JumpTable::sanityCheck` returns early for an override model, so the
// decompiler then takes these destinations instead of running its own `lhzx`-unaware
// recovery - which is what produces the misaligned targets ("Instruction at 0x...b8e
// overlaps ...", "Bad instruction count exceeded") on the 120 functions that still
// fail.
//
// Input: `switch_tables.py > dispatchers.tsv`, one row per dispatcher:
//   bctr <tab> table <tab> base <tab> scale <tab> cases <tab> aligned <tab> targets
//
//   SWITCH_TSV=/tmp/dispatchers.tsv analyzeHeadless ... -postScript SwitchTables.java
import ghidra.app.cmd.function.CreateFunctionCmd;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSpace;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.pcode.JumpTable;
import ghidra.program.model.symbol.RefType;
import ghidra.program.model.symbol.SourceType;
import java.io.BufferedReader;
import java.io.FileReader;
import java.util.ArrayList;

public class SwitchTables extends GhidraScript {
    public void run() throws Exception {
        String tsv = System.getenv("SWITCH_TSV");
        if (tsv == null) {
            println("SWITCH_TSV not set");
            return;
        }
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();
        BufferedReader br = new BufferedReader(new FileReader(tsv));
        String line;
        int dispatchers = 0, overrides = 0, refs = 0, skipped = 0;
        while ((line = br.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty() || line.startsWith("#")) {
                continue;
            }
            String[] f = line.split("\t");
            if (f.length < 7) {
                continue;
            }
            Address from = sp.getAddress(Long.parseLong(f[0].replace("0x", ""), 16));
            Instruction instr = getInstructionAt(from);
            Function function = getFunctionContaining(from);
            if (instr == null || function == null) {
                println("skip 0x" + Long.toHexString(from.getOffset())
                        + (instr == null ? " (no instruction)" : " (no function)"));
                skipped++;
                continue;
            }
            ArrayList<Address> dests = new ArrayList<>();
            for (String t : f[6].split(",")) {
                if (t.trim().isEmpty()) {
                    continue;
                }
                Address to = sp.getAddress(Long.parseLong(t.trim().replace("0x", ""), 16));
                instr.addOperandReference(0, to, RefType.COMPUTED_JUMP, SourceType.USER_DEFINED);
                dests.add(to);
            }
            if (dests.isEmpty()) {
                skipped++;
                continue;
            }
            JumpTable table = new JumpTable(from, dests, true, 0);
            table.writeOverride(function);
            overrides++;
            refs += dests.size();
            // The body was built without these cases; rebuild it now that they exist.
            CreateFunctionCmd.fixupFunctionBody(currentProgram, function, monitor);
            println(String.format("switch 0x%08x fn %s cases=%d", from.getOffset(),
                    function.getName(), dests.size()));
            dispatchers++;
        }
        br.close();
        println("SWITCHTAB dispatchers=" + dispatchers + " overrides=" + overrides
                + " computed_jumps=" + refs + " skipped=" + skipped);
    }
}
