"""Pull every PNG out of avatareditor.xex and write a manifest.

The 2008 editor draws its UI from XUI resources compiled into the image, and the art
those resources use is stored as plain PNG streams - 294 of them - from 16x16 glyphs
up to 1280x720 backdrops. They are not listed anywhere the parser can reach
(`xui_parse.py` decodes the scene banks' names and value tables, but the image
chunks carry no name of their own), so this walks the file for the PNG signature and
takes each stream up to its `IEND`.

Small squares matter for the colour screens: the set includes the A/B/X/Y glyphs and
a family of radial-gradient colour blobs, which is the swatch face the colour grid
draws. `--min`/`--max` filter on the shorter side so a run can ask for just those.

    python3 extract_xex_pngs.py avatareditor.xex outdir [--min 8] [--max 96]

Writes `<outdir>/<index>_<w>x<h>_<fileoffset>.png` and `<outdir>/manifest.json` with
width, height, byte length, md5 and file offset for each, so a later pass can find
the same stream again without guessing.
"""

import hashlib
import json
import os
import struct
import sys

SIGNATURE = b"\x89PNG\r\n\x1a\n"


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    if not args:
        print(__doc__.strip().splitlines()[-2])
        return 2
    source, outdir = args[0], args[1]
    lo = int(argv[argv.index("--min") + 1]) if "--min" in argv else 0
    hi = int(argv[argv.index("--max") + 1]) if "--max" in argv else 1 << 16

    data = open(source, "rb").read()
    offsets = []
    start = 0
    while True:
        i = data.find(SIGNATURE, start)
        if i < 0:
            break
        offsets.append(i)
        start = i + len(SIGNATURE)

    os.makedirs(outdir, exist_ok=True)
    manifest = []
    written = 0
    for index, off in enumerate(offsets):
        end = data.find(b"IEND", off)
        if end < 0:
            continue
        blob = data[off:end + 8]
        if len(blob) < 33:
            continue
        width, height = struct.unpack(">II", blob[16:24])
        if not (lo <= min(width, height) <= hi):
            continue
        name = "%03d_%dx%d_%x.png" % (index, width, height, off)
        with open(os.path.join(outdir, name), "wb") as fh:
            fh.write(blob)
        manifest.append({
            "name": name,
            "file_offset": off,
            "width": width,
            "height": height,
            "bytes": len(blob),
            "md5": hashlib.md5(blob).hexdigest(),
        })
        written += 1

    with open(os.path.join(outdir, "manifest.json"), "w") as fh:
        json.dump({"source": source, "streams": len(offsets), "written": written,
                   "images": manifest}, fh, indent=1)
    print("%d PNG streams in %s, %d written to %s" % (len(offsets), source, written, outdir))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
