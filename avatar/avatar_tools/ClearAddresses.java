// Clear specific instruction addresses, for words that are provably not code.
//
// `0x980670e8` is a `bl 0x98067318` word that nothing can reach: the instruction
// before it is an unconditional `b 0x980670a4`, and the word after it is
// 0x00000000. The callee does return (`blr` at 0x9806736c), so this cannot be a
// noreturn tail; it is a dead word the body still carries, and every function that
// recurses into FUN_98066e38 fails on the fallthrough past it.
//
//   CLEAR_ADDRS=0x980670e8 analyzeHeadless ... -postScript ClearAddresses.java
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;

public class ClearAddresses extends GhidraScript {
    public void run() throws Exception {
        String list = System.getenv("CLEAR_ADDRS");
        if (list == null) {
            println("CLEAR_ADDRS not set");
            return;
        }
        for (String a : list.split(",")) {
            a = a.trim();
            if (a.isEmpty()) {
                continue;
            }
            Address ad = toAddr(Long.parseLong(a.replace("0x", ""), 16));
            boolean had = getInstructionAt(ad) != null;
            clearListing(ad, ad.add(3));
            println("cleared " + a + " (instruction was there: " + had + ")");
        }
    }
}
