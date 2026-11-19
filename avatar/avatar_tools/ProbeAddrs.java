// Print the decoded instruction at specific addresses, and count the altv-stub
// mnemonics that should no longer exist.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.*;
import java.util.*;
public class ProbeAddrs extends GhidraScript {
    public void run() throws Exception {
        for (String s : System.getenv("PROBE_ADDRS").split(",")) {
            Address a = currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(Long.parseLong(s.trim(),16));
            Instruction i = getInstructionAt(a);
            println("AT " + s.trim() + " -> " + (i == null ? "(no instruction)" : i.toString()));
        }
        Map<String,Integer> c = new TreeMap<>();
        Address st = currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(0x9803a000L);
        Address en = currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(0x9813b200L);
        InstructionIterator it = currentProgram.getListing().getInstructions(
            currentProgram.getAddressFactory().getAddressSet(st, en), true);
        while (it.hasNext()) {
            String m = it.next().getMnemonicString();
            if (m.startsWith("lv") || m.startsWith("stv") || m.startsWith("vcmpne") || m.equals("vcmpequd"))
                c.merge(m, 1, Integer::sum);
        }
        c.forEach((k,v) -> println("MN " + k + " = " + v));
    }
}
