// Count, inside the bodies of the listed functions, how many instructions decode
// and how many still come back as Xenon placeholders (altv*) or undefined bytes.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.*;
import java.io.*;
public class CountBody extends GhidraScript {
    public void run() throws Exception {
        String list = System.getenv("DUMP_LIST");
        BufferedReader br = new BufferedReader(new FileReader(list));
        long total = 0, altv = 0, undef = 0, dict = 0;
        String line;
        while ((line = br.readLine()) != null) {
            line = line.trim(); if (line.isEmpty()) continue;
            Address a = currentProgram.getAddressFactory().getDefaultAddressSpace()
                            .getAddress(Long.parseLong(line.replace("0x",""),16));
            Function f = getFunctionAt(a);
            if (f == null) continue;
            InstructionIterator it = currentProgram.getListing().getInstructions(f.getBody(), true);
            while (it.hasNext()) {
                Instruction i = it.next(); total++;
                String m = i.getMnemonicString();
                if (m.startsWith("altv") || m.startsWith("vmx")) altv++;
                else if (m.equals("??") || m.startsWith("<UNDEF")) undef++;
                if (i.getFlowType().isComputed() || i.getFlowType().isJump()) dict++;
            }
        }
        br.close();
        println("BODY total=" + total + " altv=" + altv + " undef=" + undef + " branchy=" + dict);
    }
}
