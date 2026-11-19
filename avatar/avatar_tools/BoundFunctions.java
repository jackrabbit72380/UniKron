// Create every `.pdata` function with a body bounded by the next `.pdata` entry.
//
// MakeFunctions created the 3,182 entries Ghidra's analysis missed, but with no
// body hint, so Ghidra computed each body from flow alone. Where an entry is
// reached by fallthrough the flow runs *backwards* into the preceding function
// (`FUN_980690e0` came back with body 0x980618e0..0x98069167 while its entry is
// 0x980690e0), and where an entry is a cold or mid-block start the body runs into
// the next function. The decompiler then sees overlapping instructions, which is
// exactly the two symptoms the 42 remaining failures show: `halt_baddata` and
// `Bad instruction count exceeded`.
//
// `.pdata` is the compiler's own function table: entry i's function runs from
// `starts[i]` up to, but not including, `starts[i + 1]`. That bound is measured
// from the file, not chosen, so each body is created as the set of already
// disassembled instructions inside [start, next start). No body can then overlap
// another entry, which is the overlap `RebuildFunctions` could not remove.
//
// `no return` flags are captured before the functions are removed and re-applied
// afterwards, so the SweepNoreturn result does not have to be re-derived.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.SourceType;
import java.io.*;
import java.util.*;
public class BoundFunctions extends GhidraScript {
    public void run() throws Exception {
        final long TEXT_START = 0x9803a000L, TEXT_END = 0x9813b1dcL;
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();

        List<Long> starts = new ArrayList<>();
        BufferedReader br = new BufferedReader(new FileReader(System.getenv("DUMP_LIST")));
        String line;
        while ((line = br.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty()) continue;
            starts.add(Long.parseLong(line.replace("0x", ""), 16));
        }
        br.close();
        Collections.sort(starts);

        // Keep the measured noreturn set across the rebuild.
        Set<Long> noReturn = new HashSet<>();
        List<Function> doomed = new ArrayList<>();
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            long e = f.getEntryPoint().getOffset();
            if (e >= TEXT_START && e < TEXT_END) {
                doomed.add(f);
                if (f.hasNoReturn()) noReturn.add(e);
            }
        }
        for (Function f : doomed) removeFunction(f);
        println("BOUND removed=" + doomed.size() + " pdata=" + starts.size()
                + " noreturn_carried=" + noReturn.size());

        int made = 0, noCode = 0, failed = 0, empty = 0;
        for (int i = 0; i < starts.size(); i++) {
            long s = starts.get(i);
            long e = (i + 1 < starts.size()) ? starts.get(i + 1) : TEXT_END;
            Address a = sp.getAddress(s);
            if (getInstructionAt(a) == null) {
                try { disassemble(a); } catch (Exception ex) { /* no code here */ }
            }
            if (getInstructionAt(a) == null) { noCode++; continue; }
            AddressSet body = new AddressSet();
            InstructionIterator it = currentProgram.getListing().getInstructions(
                    currentProgram.getAddressFactory().getAddressSet(a, sp.getAddress(e - 1)), true);
            int n = 0;
            while (it.hasNext()) { body.add(it.next().getAddress()); n++; }
            if (n == 0) { empty++; continue; }
            try {
                // FlatProgramAPI only offers createFunction(Address,String), which
                // recomputes the body from flow; the FunctionManager call takes the
                // bounded body `.pdata` gives us.
                Function f = currentProgram.getFunctionManager().createFunction(
                        "FUN_" + Long.toHexString(s), a, body, SourceType.IMPORTED);
                if (f == null) { failed++; println("no function at " + Long.toHexString(s)); continue; }
                if (noReturn.contains(s)) f.setNoReturn(true);
                made++;
            } catch (Exception ex) {
                failed++;
                println("failed at " + Long.toHexString(s) + ": " + ex.getMessage());
            }
        }
        println("BOUND created=" + made + " no_code=" + noCode
                + " empty_body=" + empty + " failed=" + failed);

        // Re-derive the noreturn shape on the bounded bodies: last instruction is
        // `bl` and the next instruction is not code (padding or the next entry).
        int marked = 0;
        List<Function> markedFns = new ArrayList<>();
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            long e = f.getEntryPoint().getOffset();
            if (e < TEXT_START || e >= TEXT_END) continue;
            Instruction last = null;
            InstructionIterator it = currentProgram.getListing().getInstructions(f.getBody(), true);
            while (it.hasNext()) last = it.next();
            if (last == null || !last.getMnemonicString().equals("bl")) continue;
            Address[] fl = last.getFlows();
            if (fl.length != 1) continue;
            Function target = getFunctionAt(fl[0]);
            if (target != null && !target.hasNoReturn()) markedFns.add(target);
        }
        for (Function f : markedFns) { f.setNoReturn(true); marked++; }
        println("BOUND noreturn_swept=" + marked);
    }
}
