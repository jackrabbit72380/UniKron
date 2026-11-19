// Emit "address hexbytes mnemonic" for every vector instruction in .text whose
// p-code calls one of the altv stubs, so the encodings can be tested numerically.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.*;
import java.io.*;
import java.util.*;
public class DumpVcmp extends GhidraScript {
    public void run() throws Exception {
        Set<String> wanted = new HashSet<>(Arrays.asList(
            "vcmpequd","vcmpneb.","vcmpneh.","vcmpnezb.","vcmpnezh.","vcmpnezw"));
        PrintWriter w = new PrintWriter(new File("/tmp/vcmp.txt"));
        Address s = currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(0x9803a000L);
        Address e = currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(0x9813b200L);
        InstructionIterator it = currentProgram.getListing().getInstructions(
            currentProgram.getAddressFactory().getAddressSet(s, e), true);
        while (it.hasNext()) {
            Instruction i = it.next();
            String m = i.getMnemonicString();
            if (!wanted.contains(m)) continue;
            StringBuilder hex = new StringBuilder();
            for (byte b : i.getBytes()) hex.append(String.format("%02x", b));
            w.println(i.getAddress() + " " + hex + " " + m + " " + i.toString());
        }
        w.close();
        println("VCMP DUMPED");
    }
}
