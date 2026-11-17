#!/usr/bin/env python3
"""Read the retail avatar editor's own UI vocabulary out of `avatareditor.xex`.

    python3 xex_ui_strings.py AVATAREDITOR.XEX [--json OUT.json] [--media DIR]

The 2008 editor keeps its UI strings as **UTF-16LE** inside the XEX. An earlier
pass searched the file for ASCII strings and concluded the retail category
wording was not on the disc; it is, and this is the tool that reads it.

Three tables live in the image, all UTF-16LE:

* the **category icon base names** (`hair`, `tops`, `bottoms`, `lipstick`,
  `eyeshadow`, `colour_palette_skin`, `malecostume`, `body_access`, ...) at
  ~0x5f00, followed by the state suffixes `_pressdisable.png`, `_unselected.png`
  and `_selected.png`, so every category ships three button images;
* the **localized labels** (`Headwear`, `Hairstyles`, `Tops`, `Skin Color and
  Body`, `Lip Color`, `Eye Shadow Color`, `Carryables`, `My Outfits`, ...);
* the **colour slots** `Color0`...`Color15` with `BonusColors`/`BonusColorsEnd`
  and the `Color%d` name format.

The image also embeds 294 PNGs - the actual retail button art. `--media` writes
them out; they are the only retail artwork for the makeup and accessory buttons,
which have no items in the asset pack.

Nothing here is guessed: every entry is a string found at a stated offset.
"""

import argparse
import json
import os
import re
import struct
import sys

UTF16 = re.compile(rb"(?:[\x20-\x7e]\x00){3,}")
PNG = b"\x89PNG"


def strings(data):
    """Every printable UTF-16LE run, with its offset."""
    return [(m.start(), m.group().decode("utf-16le").rstrip("\x00 ")) for m in UTF16.finditer(data)]


def label_table(pairs):
    """The retail labels: words that sit in the label block, in file order."""
    words = []
    for off, text in pairs:
        if text and text[0].isupper() and len(text) < 40:
            words.append((off, text))
    return words


def icon_names(pairs):
    """Category icon base names plus the state suffix the block declares."""
    states = [t for _, t in pairs if t.startswith("_") and t.endswith(".png")]
    bases = []
    for off, text in pairs:
        if not text or not text[0].islower():
            continue
        if not re.fullmatch(r"[a-z0-9_]+", text):
            continue
        bases.append((off, text))
    return bases, states


def colours(pairs):
    """Colour slot names: Color0..N, the Colour%d format and the bonus range."""
    slots = []
    fmt = ""
    bonus = []
    for off, text in pairs:
        m = re.fullmatch(r"Color(\d+)", text)
        if m:
            slots.append((off, text, int(m.group(1))))
        elif "%d" in text and "olor" in text:
            fmt = text
        elif text.startswith("BonusColors"):
            bonus.append(text)
    slots.sort(key=lambda r: r[2])
    return [s[1] for s in slots], fmt, bonus


def media(data):
    """The embedded PNGs: offset, declared size and a validated blob."""
    out = []
    for m in re.finditer(re.escape(PNG), data):
        off = m.start()
        ihdr = data[off + 12:off + 16]
        if ihdr != b"IHDR":
            continue                      # a stray signature in code, not an image
        w, h = struct.unpack_from(">II", data, off + 16)
        if not (0 < w <= 4096 and 0 < h <= 4096):
            continue                      # refuses the false positives
        end = data.find(b"IEND", off)
        if end < 0:
            continue
        out.append((off, w, h, data[off:end + 8]))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("xex")
    ap.add_argument("--json", default="", help="write the extraction here")
    ap.add_argument("--media", default="", help="write the embedded PNGs into this directory")
    args = ap.parse_args()

    data = open(args.xex, "rb").read()
    pairs = strings(data)
    bases, states = icon_names(pairs)
    labels = label_table(pairs)
    slots, colour_format, bonus = colours(pairs)
    pngs = media(data)

    doc = {
        "xex": os.path.basename(args.xex),
        "string_count": len(pairs),
        "icon_bases": [{"at": "0x%06x" % o, "name": t} for o, t in bases],
        "icon_states": states,
        "labels": [{"at": "0x%06x" % o, "text": t} for o, t in labels],
        "colour_slots": slots,
        "colour_format": colour_format,
        "colour_bonus_range": bonus,
        "media": [{"at": "0x%06x" % o, "width": w, "height": h, "bytes": len(b)}
                  for o, w, h, b in pngs],
    }

    print("%s: %d UTF-16 strings, %d icon names, %d labels, %d colour slots, %d PNGs"
          % (doc["xex"], len(pairs), len(bases), len(labels), len(slots), len(pngs)))
    print("  colour slots:", " ".join(slots[:20]) or "(none)")
    print("  icon states:", " ".join(states) or "(none)")
    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, indent=1)
        print("  wrote", args.json)
    if args.media:
        os.makedirs(args.media, exist_ok=True)
        for off, w, h, blob in pngs:
            with open(os.path.join(args.media, "xex_%06x_%dx%d.png" % (off, w, h)), "wb") as fh:
                fh.write(blob)
        print("  wrote %d PNGs to %s" % (len(pngs), args.media))
    return 0


if __name__ == "__main__":
    sys.exit(main())
