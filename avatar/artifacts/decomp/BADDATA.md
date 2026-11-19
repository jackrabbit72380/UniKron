# Why the decompiler gives up on the last functions (source-level)

Measured in Ghidra 12.2's own decompiler source (`Features/Decompiler/src/decompile/cpp`):

* `flow.cc:550` — `FlowInfo::countBadData()` throws `BadDataError` ("Bad instruction
  count exceeded") once `baddata_count >= glb->max_baddata`.
* `architecture.cc:1426` — `max_baddata = 4;` **by default**. That is the whole limit:
  four p-code requests at addresses the decompiler cannot use, and the function is
  abandoned with no body.
* `options.cc:807-810` — the `baddatacount` option raises it, and its documentation says
  what happens then: "artificial halts are generated at addresses causing the
  BadDataError, allowing analysis to continue" — that is exactly the `halt_baddata()`
  marker in the C.

## What the 5,224 functions show at `max_baddata = 100`

`DumpBadData.java`, same project and function set as `FAILURES-round4.txt`:

| | default (4) | raised (100) |
| --- | ---: | ---: |
| functions with a body | 5,133 | 5,223 |
| clean | 5,104 | 5,101 |
| `halt_baddata` | 29 | 122 |
| no body | 91 | 1 |

The knob converts 90 empty functions into bodies that stop at an artificial halt, and it
slightly *lowers* the clean count (5,104 → 5,101). It is not a route to 100%: the missing
thing is the flow the decompiler cannot compute, not the budget it is given.

## The addresses it cannot use

184 distinct addresses appear in `pcode error at …` lines: **177 misaligned, 7
aligned**. A misaligned address cannot be an instruction at all (PowerPC has no 2-byte
instruction), so these are the decompiler's own computed targets, not stored code.

What it reports, by event count:

| reason | events |
| --- | ---: |
| `Invalid instruction address (improperly aligned)` | 566 |
| `Unable to resolve constructor at <addr>` | 221 |
| `Could not follow disassembly flow into non-existing memory at <addr>` | 5 |

The worst repeats are 36 events at `0x98067b96`, 36 at `0x98067bd2`, 18 each at
`0x98112e4a`/`0x98112e56`/`0x98112e62`, and 17 at `0x9806700a` and `0x9806ba86`.

**They are scattered across every halfword offset, not a fixed shift**: of the 177
misaligned addresses, 75 are `mod 4 = 1`, 52 are `mod 4 = 2` and 50 are `mod 4 = 3`
(`0x98067b96` = `0x98067b94`+2 and `0x9803e922` = `0x9803e920`+2 are two of the 52). That
is what a halfword read produces: every 2-byte slot in a word can then be an offset, so
`base + entry` lands on any of the four phases. The reading is consistent with the
decompiler's switch recovery never resolving the table's base (the `lis`+`addi` pair
*after* the `lhzx` in these PPC dispatchers), so its entries end up being halves of code
words. The `Unable to resolve constructor` events are the same addresses asked for a
second time. That last step (entries are code halves) is an inference from the address
distribution, not something the log states.

`switch_tables.py` recovers the same tables correctly by construction — `lhzx` = u16
offsets, `rlwinm` = the scale, the second `lis`+`addi` = the base — which is why its 18
dispatchers come out with 4-aligned targets (14 exactly, the rest with a few shared
blocks). The decompiler's own recovery does not use that pattern.

## Consequence for closing the last 120

The decompiler skips its recovery entirely when a jump table is an **override**:
`JumpTable::sanityCheck` returns immediately `if (jmodel->isOverride())` (`jumptable.cc`).
So the route is not a bigger bad-data budget and not re-owning the case blocks (both
measured, both ineffective — see `DECOMPILE.md` round four), but recording the 18 tables
as explicit jump tables in the program so the override path is taken and its own
`lhzx`-unaware recovery never runs.
