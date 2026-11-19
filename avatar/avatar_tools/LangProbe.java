import ghidra.app.script.GhidraScript;
public class LangProbe extends GhidraScript {
    public void run() {
        println("LANG=" + currentProgram.getLanguageID() + " compiler=" + currentProgram.getCompilerSpec().getCompilerSpecID());
    }
}
