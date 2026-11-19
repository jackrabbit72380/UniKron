// Remove candidates that sit inside a `.pdata` record instead of at its start.
//
// MakeRunFunctions creates a candidate at every word after a terminator, but only
// where no function contains the address at that moment. A branch target inside a
// function whose body flow had not yet reached it therefore became a function of
// its own, and the decompiler is then handed a body whose entry is not a function
// start: a branch flow that starts before the entry, a body that walks into the
// next record, a `blr` in the middle of a switch case.
//
// All 33 remaining failures are exactly that. Measured against `.pdata`:
//
//   every failing address is absent from the record list, and
//   every failing address is strictly inside the span between two record starts
//   (nearest previous record start 0x98067a08 +412 .. +1828 for the 17-cluster).
//
// So the compiler did not record a function there, and no function was recorded
// before the first record either. This removes only addresses supplied in
// INTERIOR_LIST, and refuses any that turns out to be a record start, so the
// recorded functions are never touched.
//
//   DUMP_LIST=<pdata_funcs.txt> INTERIOR_LIST=<addresses> \
//       analyzeHeadless <proj> AE -process nxe2008.elf -noanalysis \
//       -scriptPath . -postScript DeleteInteriorFunctions.java
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSpace;
import ghidra.program.model.listing.Function;
import java.io.*;
import java.util.*;

public class DeleteInteriorFunctions extends GhidraScript {
    private static long parse(String s) {
        return Long.parseLong(s.trim().replace("0x", ""), 16);
    }

    public void run() throws Exception {
        AddressSpace sp = currentProgram.getAddressFactory().getDefaultAddressSpace();

        List<Long> records = new ArrayList<>();
        BufferedReader br = new BufferedReader(new FileReader(System.getenv("DUMP_LIST")));
        String line;
        while ((line = br.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty()) continue;
            records.add(parse(line));
        }
        br.close();
        Collections.sort(records);
        Set<Long> recordSet = new HashSet<>(records);

        List<Long> targets = new ArrayList<>();
        br = new BufferedReader(new FileReader(System.getenv("INTERIOR_LIST")));
        while ((line = br.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty() || !line.startsWith("0x")) continue;
            targets.add(parse(line.split("\\s+")[0]));
        }
        br.close();

        int asked = 0, removed = 0, isRecord = 0, noFunction = 0, beforeFirst = 0, notInterior = 0;
        for (long a : targets) {
            asked++;
            if (recordSet.contains(a)) {
                isRecord++;
                println("kept record start 0x" + Long.toHexString(a));
                continue;
            }
            int i = Collections.binarySearch(records, a);
            int at = i >= 0 ? i : -(i + 1);
            if (at == 0) {
                beforeFirst++;
                println("kept before first record 0x" + Long.toHexString(a));
                continue;
            }
            long prev = records.get(at - 1);
            long next = at < records.size() ? records.get(at) : 0;
            if (a <= prev || (next != 0 && a >= next)) {
                notInterior++;
                println("kept outside a span 0x" + Long.toHexString(a));
                continue;
            }
            Address ad = sp.getAddress(a);
            Function f = getFunctionAt(ad);
            if (f == null) {
                noFunction++;
                println("missing function at 0x" + Long.toHexString(a));
                continue;
            }
            Function enclosing = getFunctionAt(sp.getAddress(prev));
            println("interior 0x" + Long.toHexString(a) + " body=" + f.getBody().getMinAddress()
                    + ".." + f.getBody().getMaxAddress() + " in_record=0x" + Long.toHexString(prev)
                    + (enclosing == null ? "" : " (" + enclosing.getName() + ")"));
            removeFunction(f);
            removed++;
        }
        println("INTERIOR asked=" + asked + " removed=" + removed + " is_record=" + isRecord
                + " before_first=" + beforeFirst + " outside=" + notInterior
                + " no_function=" + noFunction);
    }
}
