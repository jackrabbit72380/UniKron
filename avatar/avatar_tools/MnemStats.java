// Count instruction mnemonics and, for the six constructor families that the
// fork leaves as altv pcodeops, print sample addresses with raw bytes.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.*;
import java.util.*;
public class MnemStats extends GhidraScript {
    public void run() throws Exception {
        Map<String,Integer> counts = new TreeMap<>();
        Address start = currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(0x9803a000L);
        Address end   = currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(0x9813b200L);
        InstructionIterator it = currentProgram.getListing().getInstructions(
            currentProgram.getAddressFactory().getAddressSet(start, end), true);
        Map<String,String> samples = new LinkedHashMap<>();
        while (it.hasNext()) {
            Instruction i = it.next();
            String m = i.getMnemonicString();
            counts.merge(m, 1, Integer::sum);
            StringBuilder hex = new StringBuilder();
            for (byte b : i.getBytes()) hex.append(String.format("%02x", b));
            if (m.startsWith("vcmp") && !samples.containsKey(m)) {
                samples.put(m, i.getAddress() + " " + hex + "  " + i.toString());
            }
        }
        counts.entrySet().stream().filter(e -> e.getKey().startsWith("vcmp"))
              .forEach(e -> println("COUNT " + e.getKey() + " = " + e.getValue()));
        for (Map.Entry<String,String> e : samples.entrySet())
            println("SAMPLE " + e.getKey() + " | " + e.getValue());
    }
}
