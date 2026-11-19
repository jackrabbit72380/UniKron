// Which instructions produce no p-code, and which functions are made of them?
//
// Ghidra's decompiler throws "Bad instruction count exceeded" from
// FlowInfo::countBadData() when a function reaches `max_baddata` instructions that
// yield no p-code - it is not a size limit for large functions. So the functions it
// refuses are the ones dense in un-implemented instructions, and the useful
// measurement is which mnemonics those are and how many each function carries.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import java.io.*;
import java.util.*;
public class BadInsns extends GhidraScript {
    public void run() throws Exception {
        String out = System.getenv("BAD_OUT");
        PrintWriter w = out == null ? null : new PrintWriter(new File(out));
        Map<String, Integer> mnemonics = new TreeMap<>();
        int functions = 0, withBad = 0, badTotal = 0;
        FunctionIterator it = currentProgram.getFunctionManager().getFunctions(true);
        while (it.hasNext()) {
            Function f = it.next();
            if (f.isExternal()) continue;
            functions++;
            int bad = 0;
            InstructionIterator ii = currentProgram.getListing().getInstructions(f.getBody(), true);
            while (ii.hasNext()) {
                Instruction i = ii.next();
                int n;
                try { n = i.getPcode().length; }
                catch (Exception e) { n = 0; }
                if (n == 0) {
                    bad++;
                    mnemonics.merge(i.getMnemonicString(), 1, Integer::sum);
                }
            }
            if (bad > 0) {
                withBad++;
                badTotal += bad;
                if (w != null) {
                    w.println(String.format("0x%08x %-28s bad=%d", f.getEntryPoint().getOffset(),
                            f.getName(), bad));
                }
            }
        }
        println("BADINSN functions=" + functions + " with_bad=" + withBad + " bad_instructions=" + badTotal);
        List<Map.Entry<String, Integer>> top = new ArrayList<>(mnemonics.entrySet());
        top.sort((a, b) -> b.getValue() - a.getValue());
        for (int i = 0; i < Math.min(25, top.size()); i++) {
            println("BADINSN mnemonic " + top.get(i).getKey() + " = " + top.get(i).getValue());
        }
        if (w != null) { w.close(); println("BADINSN wrote " + out); }
    }
}
