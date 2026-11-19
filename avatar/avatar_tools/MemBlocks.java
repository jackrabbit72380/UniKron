// List the program's memory blocks: name, extent, initialised, readable.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.mem.MemoryBlock;
public class MemBlocks extends GhidraScript {
    public void run() throws Exception {
        for (MemoryBlock b : currentProgram.getMemory().getBlocks()) {
            println(String.format("%-18s %s - %s init=%s read=%s write=%s size=%d",
                    b.getName(), b.getStart(), b.getEnd(), b.isInitialized(),
                    b.isRead(), b.isWrite(), b.getSize()));
        }
    }
}
