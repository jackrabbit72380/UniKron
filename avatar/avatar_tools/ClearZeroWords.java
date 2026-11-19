// Clear instructions that are zero words - they are padding, not code.
//
// 0x00000000 is not a PowerPC instruction. Where the disassembler created one
// anyway (a post-terminator run in MakeRunFunctions, or a record start that landed
// in alignment padding), every function whose flow reaches that address fails to
// decompile with "Unable to resolve constructor at <address>" and truncates with
// halt_baddata. Measured: 17 of the 24 functions still failing after the override
// jump tables all name the same address, 0x980670ec, whose bytes are 00000000 and
// which sits between a `b` and the next function's prologue.
//
// Clearing such a word is not a guess: there is no instruction there to lose.
//
//   analyzeHeadless ... -process nxe2008.elf -noanalysis -postScript ClearZeroWords.java
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.mem.MemoryAccessException;

public class ClearZeroWords extends GhidraScript {
    public void run() throws Exception {
        final long TEXT_START = 0x9803a000L, TEXT_END = 0x9813b1dcL;
        int scanned = 0, cleared = 0;
        for (long a = TEXT_START; a + 4 <= TEXT_END; a += 4) {
            Address ad = toAddr(a);
            Instruction ins = getInstructionAt(ad);
            if (ins == null || ins.getLength() != 4) {
                continue;
            }
            scanned++;
            int v;
            try {
                v = getInt(ad);
            } catch (MemoryAccessException e) {
                continue;
            }
            if (v != 0) {
                continue;
            }
            println("clear zero word at 0x" + Long.toHexString(a)
                    + " (in " + (getFunctionContaining(ad) == null ? "-" : getFunctionContaining(ad).getName()) + ")");
            clearListing(ad, ad);
            cleared++;
        }
        println("ZEROWORDS scanned=" + scanned + " cleared=" + cleared);
    }
}
