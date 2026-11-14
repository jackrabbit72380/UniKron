#!/usr/bin/env python3
"""XUI bank/scene parser for avatareditor.xex.

What the file actually contains, and how far each part decodes:

  markers      "\\0XUI" + subtype. Most are module registration records, not
               scenes: \\0XUIS 01 01 00 00 00 0c 00 repeats 161 times, plus
               single \\0XUIRUN / \\0XUIRNDR / \\0XONLINEP / \\0XGRAPHC / \\0XAUD /
               \\0XNETY / \\0XACH / \\0XPBM ... entries. No element data.
  XUIB banks   7 of them; these are the scene banks. Fully decoded.
               Layout: NUL, "XUIB", u32 BE version (5), 12 unidentified bytes,
               u8 chunk count at +0x14, then 12-byte entries of
               (4-char tag, u32 BE offset, u32 BE size). Offsets are relative
               to the magic byte at +0x01.
               Chunk tags seen: STRN, VECT, QUAT, CUST, DATA.
  XUIZ zones   2 of them; media names only (Legend_A.png, ...).
  STRN         u16 BE length + UTF-16BE chars, repeated, no count field.
               Decodes to 100% of every chunk's bytes in all 7 banks.
  VECT         big-endian float3 table in a design space (values 0..~1280).
  QUAT/CUST    quaternion / custom value tables.
  DATA         packed property stream: variable-length records, no count or
               length table, mixing u16 ids with f32 values.

Verdict (see report_banks()): scene names, element names and the value tables
are recoverable, but element -> position attribution is NOT, because

  * DATA has no record framing, so property values cannot be delimited, and
  * the element count exceeds the vector count in every non-trivial bank
    (scnEditor: 20 element names vs 15 float3s), so ordinal pairing is wrong,
  * the property enum exists as an ordered UTF-16LE name list in the XEX
    (DesignTime, BlendMode, Show, Anchor, Opacity, Position, ...), but nothing
    in the file maps a DATA field to an index in that list.

So this tool reports what is certain and refuses to emit a guessed layout.

Hypotheses already tested and FALSIFIED, so they are not worth retrying:

  1. STRN starts with a u16 string count            -> no count; it is a
     repeated [u16 len][chars] run (a count read shifts every string).
  2. The 161 \0XUIS records are scene trees         -> identical 12-byte
     registration entries (01 01 00 00 00 0c 00), no element data.
  3. DATA records are [u32 propertyId][f32 x][f32 y], with ids indexing the
     88-name property enum recovered from the XEX (Position would be 62 in
     that run). Scanned every bank at both endiannesses: zero legitimate
     hits, only zero-valued coincidences in one bank.

Also checked: the recompiled avatareditor.exe carries none of the property
names (0 hits for Position/Opacity/BlendMode in UTF-16LE/BE and ASCII), so it
is a thin loader; the runtime that consumes DATA is the PowerPC code inside
the XEX itself.

  4. Locating that PowerPC code by reference, so it could be disassembled:
     blocked before the disassembler. The XEX only embeds a stub PE at 0x3000
     (MZ with 0 sections), and its 13 optional headers are unresolved beyond
     key 0x00010201, so there is no file->VA map. The enum strings are reached
     by virtual address, not by file offset: searching for each string's file
     offset as a BE or LE u32 pointer yields zero hits, and no consecutive
     pointer run exists either. Without VAs the code cannot be found, which is
     what stops the disassembly route (capstone 5.0.7 is available and ready).

Usage:
    python xui_parse.py avatareditor.xex            # JSON summary
    python xui_parse.py avatareditor.xex --report   # human-readable analysis
    python xui_parse.py avatareditor.xex --dump     # hexdump chunks + floats
"""

import json
import re
import struct
import sys

MAGIC_NUL = b"\x00XUI"


def find_banks(data):
    """Return offsets of \\0XUIB banks, \\0XUIZ media zones, other markers."""
    banks, zones, others = [], [], []
    pos = 0
    while True:
        i = data.find(MAGIC_NUL, pos)
        if i < 0:
            break
        kind = data[i + 1:i + 5]                 # magic starts after the NUL
        if kind == b"XUIB":
            banks.append(i)
        elif kind == b"XUIZ":
            zones.append(i)
        else:
            others.append((i, data[i + 1:i + 9]))
        pos = i + 4
    return banks, zones, others


def parse_bank(data, offset):
    """Parse one \\0XUIB bank: header fields and chunk table."""
    if data[offset + 1:offset + 5] != b"XUIB":
        raise ValueError(f"not a XUIB bank at 0x{offset:x}")
    base = offset + 1
    version = struct.unpack(">I", data[base + 4:base + 8])[0]
    count = data[offset + 0x14]
    chunks = []
    for k in range(count):
        entry = base + 0x14 + k * 12
        tag = data[entry:entry + 4].decode("latin-1")
        rel_off, size = struct.unpack(">II", data[entry + 4:entry + 12])
        start = base + rel_off
        chunks.append({
            "tag": tag,
            "rel_offset": rel_off,
            "file_offset": start,
            "size": size,
            "payload": data[start:start + size],
        })
    return {
        "offset": offset,
        "version": version,
        "header_tail": data[base + 8:base + 0x13].hex(),
        "chunk_count": count,
        "chunks": chunks,
    }


def parse_strn(payload):
    """STRN: repeated [u16 BE length][UTF-16BE chars]; no count field.

    Verified: 00 09 'XuiCanvas', 00 0d 'MobyRootScene', ... and the loop
    consumes exactly the chunk size in all 7 banks. Zero padding ends it;
    undecodable text raises instead of producing mojibake.
    """
    out, pos = [], 0
    while pos + 2 <= len(payload):
        length = struct.unpack(">H", payload[pos:pos + 2])[0]
        if length == 0:
            break
        if length > 512 or pos + 2 + length * 2 > len(payload):
            raise ValueError(f"string length {length} at 0x{pos:x} escapes the chunk")
        text = payload[pos + 2:pos + 2 + length * 2].decode("utf-16-be", "strict")
        if any(ord(c) < 0x20 and c not in "\t\r\n" for c in text):
            raise ValueError(f"non-text string {text!r} at 0x{pos:x}")
        out.append(text)
        pos += 2 + length * 2
    return out, pos


def vect_floats(payload):
    return [struct.unpack(">f", payload[k:k + 4])[0]
            for k in range(0, len(payload) - 3, 4)]


def parse_property_enum(data):
    """The XUI property names, as an ordered UTF-16LE NUL-terminated list.

    Located by the winner string 'Position'; the surrounding run is
    DesignTime, BlendMode, Show, Anchor, Opacity, Position, Nav*...
    """
    hit = data.find("Position".encode("utf-16-le"))
    if hit < 0:
        return []
    # +/-0x300 only reaches 40 of the names; the full ordered run is 88,
    # from Value .. EndTransTo, so the window has to be wider.
    window = data[max(0, hit - 0x600):hit + 0x600]
    names = []
    for m in re.finditer(rb"(?:[\x20-\x7e]\x00){2,}(?=\x00\x00)", window):
        text = m.group().decode("utf-16-le")
        if re.fullmatch(r"[A-Z][A-Za-z0-9]*", text):
            names.append(text)
    return names


def classify(strings):
    scenes = [s for s in strings if s.startswith("scn") or s.endswith("Scene")]
    types = [s for s in strings if s.startswith("Xui")]
    elems = [s for s in strings if s not in scenes and s not in types]
    return scenes, types, elems


def report_banks(data):
    banks, zones, others = find_banks(data)
    rows = []
    for offset in banks:
        bank = parse_bank(data, offset)
        strings, vect, datsz = [], b"", 0
        strn_left = None
        for chunk in bank["chunks"]:
            if chunk["tag"] == "STRN":
                strings, used = parse_strn(chunk["payload"])
                strn_left = chunk["size"] - used
            elif chunk["tag"] == "VECT":
                vect = chunk["payload"]
            elif chunk["tag"] == "DATA":
                datsz = chunk["size"]
        scenes, types, elems = classify(strings)
        rows.append({
            "offset": offset,
            "strings": len(strings),
            "strn_padding_left": strn_left,
            "scenes": scenes,
            "types": types,
            "elements": elems,
            "vec3": len(vect) // 12,
            "data_bytes": datsz,
            "chunks": [c["tag"] for c in bank["chunks"]],
        })
    return rows, zones, others


def hexdump(blob, limit=192):
    lines = []
    for row in range(0, min(len(blob), limit), 16):
        b = blob[row:row + 16]
        lines.append("  %04x  %s  %s" % (
            row, b.hex(" "), "".join(chr(c) if 32 <= c < 127 else "." for c in b)))
    if len(blob) > limit:
        lines.append(f"  ... {len(blob) - limit} more bytes")
    return "\n".join(lines)


def main(argv):
    do_report = "--report" in argv
    do_dump = "--dump" in argv
    paths = [a for a in argv[1:] if not a.startswith("--")]
    if not paths:
        print(__doc__)
        return 2
    data = open(paths[0], "rb").read()
    rows, zones, others = report_banks(data)

    if do_report:
        print(f"banks: {len(rows)}   media zones: {len(zones)}   other markers: {len(others)}")
        print(f"\n{'bank':<11}{'strs':>5}{'pad':>5}{'scenes':>7}{'types':>6}{'elems':>6}"
              f"{'vec3':>6}{'data':>7}  chunks")
        for r in rows:
            print(f"0x{r['offset']:<9x}{r['strings']:5d}{r['strn_padding_left'] or 0:5d}"
                  f"{len(r['scenes']):7d}{len(r['types']):6d}{len(r['elements']):6d}"
                  f"{r['vec3']:6d}{r['data_bytes']:7d}  {','.join(r['chunks'])}")
        for r in rows:
            print(f"\nbank 0x{r['offset']:x}")
            print("  scenes  :", ", ".join(r["scenes"]))
            print("  elements:", ", ".join(r["elements"]) or "-")
            if r["elements"] and r["vec3"]:
                verdict = ("1:1 possible" if len(r["elements"]) == r["vec3"]
                           else f"AMBIGUOUS: {len(r['elements'])} elements vs {r['vec3']} vec3s")
                print("  mapping :", verdict)
        props = parse_property_enum(data)
        print(f"\nproperty enum ({len(props)} names, ordered, UTF-16LE):")
        print("  " + ", ".join(props))
        print("\nverdict: names and value tables decode; element->position does not,")
        print("because DATA carries no record framing and the element/vector counts")
        print("differ, so no pairing can be justified from the file alone.")
        return 0

    report = {"banks": [], "media_zones": [], "marker_counts": {}, "property_enum": parse_property_enum(data)}
    for _, kind in others:
        key = kind[:4].decode("latin-1", "replace").rstrip("\x00")
        report["marker_counts"][key] = report["marker_counts"].get(key, 0) + 1
    for offset in [r["offset"] for r in rows]:
        bank = parse_bank(data, offset)
        info = {"offset": offset, "version": bank["version"],
                "header_tail": bank["header_tail"], "chunks": []}
        for chunk in bank["chunks"]:
            entry = {"tag": chunk["tag"], "size": chunk["size"],
                     "file_offset": chunk["file_offset"]}
            if chunk["tag"] == "STRN":
                try:
                    strings, used = parse_strn(chunk["payload"])
                    entry["strings"] = strings
                    entry["strn_bytes_used"] = used
                    entry["strn_bytes_left"] = chunk["size"] - used
                except Exception as exc:                        # noqa: BLE001
                    entry["strn_error"] = str(exc)
            elif chunk["tag"] == "VECT":
                entry["floats"] = vect_floats(chunk["payload"])
            info["chunks"].append(entry)
        report["banks"].append(info)
    for offset in zones:
        report["media_zones"].append({"offset": offset,
                                      "head": data[offset + 1:offset + 0x21].hex()})
    print(json.dumps(report, indent=2))

    if do_dump:
        for offset in [r["offset"] for r in rows]:
            bank = parse_bank(data, offset)
            for chunk in bank["chunks"]:
                if chunk["tag"] in ("VECT", "DATA", "QUAT", "CUST"):
                    print(f"\n=== bank 0x{offset:x} {chunk['tag']} size 0x{chunk['size']:x}")
                    print(hexdump(chunk["payload"]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
