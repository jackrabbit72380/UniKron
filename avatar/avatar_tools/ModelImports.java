// The region 0x9813b1dc..0x9813c000 is inside .text's virtual size but has NO bytes
// in the file, and .text tail-jumps into it: it is the loader-filled import
// trampoline area. Nothing there can be decoded from the PE.
//
// This script does NOT invent data. It models each referenced target as an
// unresolved import: an initialised block of `blr` placeholders is created so the
// targets become functions that return, and every function is named
// `unresolved_import_<addr>` so no reader mistakes it for recovered code.
import ghidra.app.script.GhidraScript;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.mem.*;
import java.util.*;
public class ModelImports extends GhidraScript {
    public void run() throws Exception {
        long GAP_START = 0x9813b1dcL, GAP_END = 0x9813c000L;
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();
        Set<Long> targets = new TreeSet<>();
        Address s = sp.getAddress(0x9803a000L), e = sp.getAddress(0x9813b1dcL);
        InstructionIterator it = currentProgram.getListing().getInstructions(
            currentProgram.getAddressFactory().getAddressSet(s, e), true);
        while (it.hasNext()) {
            for (Address t : it.next().getFlows()) {
                long v = t.getOffset();
                if (v >= GAP_START && v < GAP_END) targets.add(v);
            }
        }
        println("targets in the gap: " + targets.size());
        Memory mem = currentProgram.getMemory();
        Address start = sp.getAddress(GAP_START);
        MemoryBlock blk = mem.getBlock(start);
        if (blk == null) {
            blk = mem.createInitializedBlock("IMPORT_TRAMPOLINES", start,
                    GAP_END - GAP_START, (byte) 0, monitor, false);
            println("created block IMPORT_TRAMPOLINES");
        }
        // Write `blr` at every target only; everything else stays zero.
        for (long t : targets) {
            Address a = sp.getAddress(t);
            mem.setByte(a, (byte) 0x4e); mem.setByte(a.add(1), (byte) 0x80);
            mem.setByte(a.add(2), (byte) 0x00); mem.setByte(a.add(3), (byte) 0x20);
            new DisassembleCommand(a, null, false).applyTo(currentProgram, monitor);
            Function f = getFunctionAt(a);
            if (f == null) f = createFunction(a, "unresolved_import_" + Long.toHexString(t));
            if (f != null) { f.setName("unresolved_import_" + Long.toHexString(t), ghidra.program.model.symbol.SourceType.USER_DEFINED); f.setNoReturn(false); }
        }
        DecompInterface ifc = new DecompInterface(); ifc.openProgram(currentProgram);
        int clean = 0, bad = 0;
        String rl = System.getenv("RECHECK");
        for (String a : (rl == null ? "" : rl).split(",")) {
            if (a.trim().isEmpty()) continue;
            Address ad = sp.getAddress(Long.parseLong(a.trim().replace("0x",""),16));
            Function f = getFunctionAt(ad);
            if (f == null) { println("RECHECK " + a + " no function"); continue; }
            DecompileResults res = ifc.decompileFunction(f, 120, monitor);
            String c = res == null || res.getDecompiledFunction() == null ? "" : res.getDecompiledFunction().getC();
            boolean isBad = c.contains("halt_baddata");
            if (isBad) bad++; else clean++;
            println("RECHECK " + a + " stmts=" + (c.length() - c.replace(";","").length()) + " halt_baddata=" + isBad);
        }
        println("SUMMARY clean=" + clean + " bad=" + bad);
        ifc.dispose();
    }
}
