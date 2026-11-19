// For each address in FIND_BAD, walk instructions from the function entry and
// report the first undecodable word (mnemonic "??") or the last instruction.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.*;
public class FindBad extends GhidraScript {
    public void run() throws Exception {
        for (String s : System.getenv("FIND_BAD").split(",")) {
            Address a = currentProgram.getAddressFactory().getDefaultAddressSpace()
                            .getAddress(Long.parseLong(s.trim().replace("0x",""),16));
            Function f = getFunctionAt(a);
            println("== " + s.trim() + (f == null ? " (no function)" : " body=" + f.getBody().getNumAddresses()));
            if (f == null) continue;
            InstructionIterator it = currentProgram.getListing().getInstructions(f.getBody(), true);
            Instruction last = null; boolean found = false;
            while (it.hasNext()) {
                Instruction i = it.next();
                String m = i.getMnemonicString();
                if (m.equals("??") || i.getFlowType().isTerminal() && false) {
                    StringBuilder hex = new StringBuilder();
                    for (byte b : i.getBytes()) hex.append(String.format("%02x", b));
                    println("   UNDECODABLE at " + i.getAddress() + " bytes=" + hex);
                    found = true; break;
                }
                last = i;
            }
            if (!found && last != null) println("   last instruction: " + last.getAddress() + " " + last);
            // also report the word just past the function body
            Address end = f.getBody().getMaxAddress().add(4);
            Instruction n = getInstructionAt(end);
            println("   word after body at " + end + ": " + (n == null ? "(not code)" : n.toString()));
        }
    }
}
