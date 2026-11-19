// Use `.pdata` as a code map, not as a function table.
//
// The records are not one-per-function (a record can span several prologues and
// several `blr`s), but every record start is a code address, and 89.1% of the
// `.text` bytes Ghidra's analysis never disassembled lie inside some record. So
// this disassembles from each record start and reports what that recovers,
// including how much of the new code lands inside an existing function body.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSpace;
import ghidra.program.model.listing.*;
import java.io.*;
public class DisassembleRecords extends GhidraScript {
    public void run() throws Exception {
        final long TEXT_START = 0x9803a000L, TEXT_END = 0x9813b1dcL;
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();
        BufferedReader br = new BufferedReader(new FileReader(System.getenv("DUMP_LIST")));
        String line;
        int had = 0, made = 0;
        while ((line = br.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty()) continue;
            Address a = sp.getAddress(Long.parseLong(line.replace("0x", ""), 16));
            if (getInstructionAt(a) != null) { had++; continue; }
            try { disassemble(a); made++; } catch (Exception e) { println("undecodable " + line); }
        }
        br.close();
        println("DISREC already=" + had + " newly_disassembled=" + made);

        long insn = 0, inFunc = 0;
        InstructionIterator it = currentProgram.getListing().getInstructions(
                currentProgram.getAddressFactory().getAddressSet(sp.getAddress(TEXT_START), sp.getAddress(TEXT_END)),
                true);
        while (it.hasNext()) {
            Instruction i = it.next();
            insn++;
            if (getFunctionContaining(i.getAddress()) != null) inFunc++;
        }
        println("DISREC instructions=" + insn + " inside_a_function=" + inFunc
                + " orphan=" + (insn - inFunc));
    }
}
