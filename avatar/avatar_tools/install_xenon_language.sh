#!/usr/bin/env bash
# Install a Xenon / VMX128 PowerPC language into an existing Ghidra install.
#
# Why: stock Ghidra has no VMX128, so any body that touches it decodes as
# `altvNNN` and the decompiler truncates the function at the first such word.
# The freeqaz Ghidra fork ships `vmx128.sinc` + `ppc_64_xenon.slaspec` with
# semantics for the VMX128 opcodes, and a `PowerPC:BE:64:Xenon` language entry.
# This script adds those files to an unmodified Ghidra (12.2 verified) and compiles
# the .sla with Ghidra's own SLEIGH compiler - no full Ghidra rebuild needed.
#
# Measured on avatareditor.xex (73 truncated .text holes):
#   stock PowerPC:BE:32:default   3 of 43 dumped readable
#   PowerPC:BE:64:Xenon          59 of 72 dumped readable, 445 named vector ops
#
# Usage:
#   GHIDRA_DIR=/tmp/ghidra_12.2_PUBLIC JAVA_HOME=/tmp/jdk25 ./install_xenon_language.sh
#
set -euo pipefail

GHIDRA_DIR="${GHIDRA_DIR:-/tmp/ghidra_12.2_PUBLIC}"
JAVA_HOME="${JAVA_HOME:-/tmp/jdk25}"
FORK_URL="${FORK_URL:-https://github.com/freeqaz/ghidra}"
FORK_DIR="${FORK_DIR:-/tmp/fork}"

LANG_DIR="$GHIDRA_DIR/Ghidra/Processors/PowerPC/data/languages"
FORK_LANG="$FORK_DIR/Ghidra/Processors/PowerPC/data/languages"

[ -d "$LANG_DIR" ] || { echo "no Ghidra install at $GHIDRA_DIR" >&2; exit 1; }
[ -x "$JAVA_HOME/bin/java" ] || { echo "no JDK at $JAVA_HOME" >&2; exit 1; }

# 1. Sparse checkout: only the PowerPC language files, not the whole Ghidra tree.
if [ ! -d "$FORK_LANG" ]; then
  rm -rf "$FORK_DIR"
  git clone --depth 1 --filter=blob:none --sparse "$FORK_URL" "$FORK_DIR"
  git -C "$FORK_DIR" sparse-checkout set Ghidra/Processors/PowerPC/data/languages
fi

# 2. Back up the stock language sources once, so the change is reversible.
#    The backup must live OUTSIDE the Ghidra tree: anything left in a sibling
#    directory is still scanned, and Ghidra then reports every stock language as
#    "previously defined" because it finds two ppc.ldefs files.
BACKUP_DIR="${BACKUP_DIR:-/tmp/lang_stock_backup}"
if [ ! -d "$BACKUP_DIR" ]; then
  cp -a "$LANG_DIR" "$BACKUP_DIR"
  echo "backed up stock languages to $BACKUP_DIR"
fi

# 3. Copy the fork's whole source set except ppc.ldefs. Mixing the fork's
#    ppc_common.sinc with a newer upstream ppc_instructions.sinc fails to compile
#    (undefined symbols IMM4 / CYex / DRM / RM / LBIT), so the set must be
#    self-consistent. ppc.ldefs is kept from the local install and only the Xenon
#    <language> block is added to it, so the other languages keep their entries.
cp -f "$FORK_LANG"/*.sinc "$FORK_LANG"/*.slaspec "$LANG_DIR"/
python3 - "$LANG_DIR/ppc.ldefs" "$FORK_LANG/ppc.ldefs" <<'PY'
import re, sys
ours_path, fork_path = sys.argv[1], sys.argv[2]
ours, fork = open(ours_path).read(), open(fork_path).read()
if 'id="PowerPC:BE:64:Xenon"' in ours:
    print("Xenon language entry already present")
    sys.exit(0)
block = re.search(r'\s*<language[^>]*id="PowerPC:BE:64:Xenon".*?</language>', fork, re.S)
if not block:
    sys.exit("fork's ppc.ldefs has no Xenon entry")
ours = ours.replace("</language_definitions>", block.group(0) + "\n</language_definitions>")
open(ours_path, "w").write(ours)
print("added PowerPC:BE:64:Xenon to ppc.ldefs")
PY

# 3b. Disable the POWER8 compare constructors that collide with Xenon loads.
#     Upstream altivec.sinc gained ISA 2.07 `vcmpne*` / `vcmpequd` constructors whose
#     bit patterns also match VMX128 128-bit loads/stores; they win the match and the
#     words come out as compares calling the altv pcodeop stubs. Measured on this
#     binary: all 2,226 such words have primary opcode 4, low two bits 0b11 (the
#     VMX128 load/store signature) and registers above vr31 - they are loads/stores.
#     With these constructors disabled, e.g. 0x9803da78 decodes as `lvx128 vr61,r0,r8`
#     and the 650 altv placeholder calls in the hole dumps fall to zero.
python3 - "$LANG_DIR/altivec.sinc" <<'PY'
import re, sys
path = sys.argv[1]
lines = open(path).read().split("\n")
out, i, removed = [], 0, []
while i < len(lines):
    m = re.match(r':(vcmpne\w*\.?|vcmpequd\.?)\s', lines[i])
    if m and not lines[i].lstrip().startswith("#"):
        out.append("# VMX128 collision: " + lines[i].strip())
        depth, j = 0, i
        while j < len(lines):
            out.append("# " + lines[j])
            depth += lines[j].count("{") - lines[j].count("}")
            if depth <= 0 and "}" in lines[j]:
                break
            j += 1
        removed.append(m.group(1)); i = j + 1; continue
    out.append(lines[i]); i += 1
open(path, "w").write("\n".join(out))
print("disabled VMX128-colliding constructors: %s" % (" ".join(sorted(set(removed))) or "none left"))
PY

# 4. Compile the language. Ghidra's sleigh takes the .slaspec and writes the .sla
#    next to it; it does not accept -o in 12.x.
cd "$LANG_DIR"
JAVA_HOME="$JAVA_HOME" "$GHIDRA_DIR/support/sleigh" ppc_64_xenon.slaspec 2>&1 \
  | grep -v "^INFO\|^openjdk\|^OpenJDK" || true

[ -f "$LANG_DIR/ppc_64_xenon.sla" ] \
  && echo "OK: $LANG_DIR/ppc_64_xenon.sla ($(stat -c%s "$LANG_DIR/ppc_64_xenon.sla") bytes)" \
  || { echo "FAILED: no ppc_64_xenon.sla produced" >&2; exit 1; }

echo "import with: -processor \"PowerPC:BE:64:Xenon\""
