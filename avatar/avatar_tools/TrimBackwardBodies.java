// Trim function bodies that extend before their own entry point.
//
// Ghidra's analysis lets a body absorb the code that falls through into its entry,
// so a function can end up owning bytes *before* the address it starts at.
// `FUN_9804f728` is the measured example: entry 0x9804f728, body
// 0x9804cc18..0x9804f82b - 0x2B10 bytes of the neighbour's code, which is also
// why `FUN_9804d2f8` (body 0x9804d2f8..0x9804d33b) overlaps it and both fail with
// "Bad instruction count exceeded".
//
// A body cannot contain code before its own entry: everything earlier belongs to
// whatever function precedes it. This removes [body.min, entry) from each such
// body, reports how many functions and bytes that touches, and leaves the entry's
// own instructions alone.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSet;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import java.util.*;
public class TrimBackwardBodies extends GhidraScript {
    public void run() throws Exception {
        List<Function> hit = new ArrayList<>();
        long bytes = 0;
        FunctionIterator it = currentProgram.getFunctionManager().getFunctions(true);
        while (it.hasNext()) {
            Function f = it.next();
            if (f.isExternal()) continue;
            Address min = f.getBody().getMinAddress();
            Address entry = f.getEntryPoint();
            if (min != null && min.compareTo(entry) < 0) {
                hit.add(f);
                bytes += entry.subtract(min);
            }
        }
        println("TRIM backward_bodies=" + hit.size() + " bytes_before_entry=" + bytes);
        for (Function f : hit) {
            Address min = f.getBody().getMinAddress();
            AddressSet trimmed = new AddressSet(f.getBody());
            trimmed.delete(new AddressSet(min, f.getEntryPoint().subtract(1)));
            f.setBody(trimmed);
        }
        println("TRIM applied=" + hit.size());
    }
}
