// Bound a function's body to an explicit last address.
//
// FUN_98066e38's body ends at 0x980670eb, three instructions into dead bytes:
// 0x980670e4 is an unconditional `b`, and what follows it is a `bl` word followed
// by 0x00000000. Ghidra keeps that tail in the body, so whenever the decompiler
// recurses into this function it tries to decode 0x980670ec, fails with "Unable to
// resolve constructor", and truncates the caller - which is why 17 small functions
// in the same page all report the same error address.
//
//   SETBODY="0x98066e38:0x980670e7" analyzeHeadless ... -postScript SetBodyRange.java
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSet;
import ghidra.program.model.listing.Function;

public class SetBodyRange extends GhidraScript {
    public void run() throws Exception {
        String spec = System.getenv("SETBODY");
        if (spec == null) {
            println("SETBODY not set");
            return;
        }
        for (String one : spec.split(",")) {
            String[] p = one.trim().split(":");
            if (p.length != 2) {
                continue;
            }
            Address min = toAddr(Long.parseLong(p[0].replace("0x", ""), 16));
            Address max = toAddr(Long.parseLong(p[1].replace("0x", ""), 16));
            Function f = getFunctionAt(min);
            if (f == null) {
                println("no function at " + p[0]);
                continue;
            }
            String before = f.getBody().getMinAddress() + ".." + f.getBody().getMaxAddress();
            f.setBody(new AddressSet(min, max));
            println("body " + p[0] + " " + before + " -> "
                    + f.getBody().getMinAddress() + ".." + f.getBody().getMaxAddress());
        }
    }
}
