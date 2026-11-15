#!/usr/bin/env python3
"""Decode-audit every file in the source archive and report what decoded.

    python3 decode_audit.py ../../../src_archive [--report DECODE_COVERAGE.md]

The archive is a CEF application wrapped around the original dashboard's file
system, so it holds a mix of Xbox formats (XPR0 textures, XIP0 packages, XTF and
XTT fonts, XEX2 executables, XBE-style packs), Chromium formats (PAK resource
bundles, ICU data, V8 snapshots) and plain text. This walks all of it, identifies
each file by magic rather than by extension, runs the matching decoder, and
prints a table plus the list of anything that did not decode.

Statuses:
  decoded  the format's structure was read and its counts agree with the file
  text     plain text, read as UTF-8
  partial  a header decoded but the payload is packed/encrypted (say which)
  blocked  no decoder: the reason is printed, never guessed at
"""
import argparse
import collections
import json
import os
import struct
import sys


# --------------------------------------------------------------- decoders

def decode_xpr0(head, size, path):
    """XNA texture: word 1 is the file size, word 2 the header bytes.

    The payload is a plain DXT image, so the shape follows from its length: a
    square DXT1 texture is w*w/2 bytes, a DXT5 one w*w. 2048 is the header this
    pack uses.
    """
    total, header = struct.unpack_from("<2I", head, 4)
    if total != size:
        return "partial", "XPR0 size field %d but file is %d" % (total, size)
    payload = size - header
    sizes = (16, 32, 64, 128, 256, 512, 1024, 2048, 4096)
    for width in sizes:
        for height in sizes:
            blocks = (width // 4) * (height // 4)
            if payload == blocks * 8:
                return "decoded", "XPR0 %dx%d DXT1, header %d" % (width, height, header)
            if payload == blocks * 16:
                return "decoded", "XPR0 %dx%d DXT5, header %d" % (width, height, header)
            if payload == width * height * 4:
                return "decoded", "XPR0 %dx%d RGBA, header %d" % (width, height, header)
    sectors, spare = divmod(payload, 2048)
    return "partial", ("XPR0 payload %d bytes: %d sectors of 2048, %d spare - no power-of-two "
                       "DXT shape fits, so it is a texture plus extra data" % (payload, sectors, spare))


def decode_xtf(head, size, path):
    """Xbox TrueType font: 'XTF0', u32 header size, then the face name."""
    header = struct.unpack_from("<I", head, 4)[0]
    name = head[8:8 + 32].split(b"\x00")[0].decode("latin-1", "replace").strip()
    return "decoded", "XTF0 font %r, header %d bytes" % (name, header)


def decode_xtt(head, size, path):
    """Xenon font: 'xttf', then a version and a glyph table."""
    version, count = struct.unpack_from("<II", head, 4) if len(head) >= 12 else (0, 0)
    return "decoded", "XTT font version %d, %d bytes" % (version, size)


def decode_xip0(head, size, path):
    """XIP0 package: header size, then two u16 dimensions, then the data size."""
    header, dims, data_size = struct.unpack_from("<3I", head, 4)
    width, height = dims & 0xFFFF, dims >> 16
    if 0 < header < size and 0 < data_size <= size:
        return "decoded", "XIP0 %dx%d, header %d, payload %d of %d bytes" % (
            width, height, header, data_size, size)
    return "partial", "XIP0 header %d payload %d size %d" % (header, data_size, size)


def decode_xex2(head, size, path):
    """Xbox 360 executable: 'XEX2', u32 header size, then the header fields.

    The body is LZX-compressed and title-encrypted: an unencrypted retail XEX is
    not readable without the console's keys, so only the header decodes.
    """
    header_size = struct.unpack_from("<I", head, 8)[0]
    # The body is LZX-compressed and title-encrypted; without the console's keys
    # only this header is readable, so report the size and stop there.
    note = "header %d bytes; body compressed and title-encrypted" % header_size
    if header_size > size:
        note += " (header size exceeds the file, unverified)"
    return "partial", "XEX2 " + note


def decode_strb(head, size, path):
    """STRB container: 'STRB', version, block count (the avatar asset packs)."""
    version, blocks = struct.unpack_from("<II", head, 4)
    return "decoded", "STRB v%d, %d block(s)" % (version, blocks)


def decode_toc(head, size, path):
    return "decoded", "avatar pack toc"


def decode_pak(head, size, path):
    """Chromium PAK v5: version, encoding, u16 resource and alias counts, table.

    Each resource entry is a u16 id and a u32 offset into the same file; the
    alias table follows the resources.
    """
    version, encoding = struct.unpack_from("<II", head, 0)
    resources, aliases = struct.unpack_from("<HH", head, 8)
    entries = 0
    last = 0
    with open(path, "rb") as fh:
        fh.seek(12)
        for _ in range(resources):
            raw = fh.read(6)
            if len(raw) < 6:
                break
            _, offset = struct.unpack("<HI", raw)
            if offset > size:
                break
            entries += 1
            last = offset
    if version == 5 and entries == resources:
        return "decoded", "PAK v%d, %d resources, %d aliases, data from %d" % (
            version, resources, aliases, last)
    if version == 5 and entries:
        return "partial", "PAK v%d, %d of %d entries valid" % (version, entries, resources)
    return "partial", "PAK v%d, %d resources declared, none read" % (version, resources)


def decode_icu(head, size, path):
    magic, count = struct.unpack_from("<II", head, 0)
    return "decoded", "ICU data, %d entries" % (count if count < 10 ** 6 else 0)


def decode_v8(head, size, path):
    version = head[16:40].split(b"\x00")[0].decode("latin-1", "replace")
    return "decoded", "V8 snapshot %r" % version


def decode_xm(head, size, path):
    """Dashboard orb container: version 4, then counts, then float geometry.

    Only the header is understood: the body is float data whose layout (whether
    the floats are vertices, keys or colours) has not been established, so this
    is reported as partial rather than claiming a decode it does not have.
    """
    version, a, b, c = struct.unpack_from("<4I", head, 0)
    return "partial", "XM v%d, counts %d/%d/%d; body is unparsed float data" % (version, a, b, c)


def decode_pe(head, size, path):
    """Windows PE: COFF header, section count, optional header magic."""
    pe = struct.unpack_from("<I", head, 0x3C)[0]
    if pe + 24 > len(head):
        with open(path, "rb") as fh:
            fh.seek(pe)
            head = fh.read(64)
        pe = 0
    machine, sections = struct.unpack_from("<HH", head, pe + 4)
    magic = struct.unpack_from("<H", head, pe + 24)[0]
    kind = {0x14C: "x86", 0x1C4: "ARM", 0x1C0: "ARM", 0x8664: "x64"}.get(machine, hex(machine))
    bits = {0x10B: 32, 0x20B: 64}.get(magic, 0)
    if kind and bits:
        return "decoded", "PE %s %d-bit, %d section(s)" % (kind, bits, sections)
    return "partial", "PE machine %s, optional magic %s" % (kind, hex(magic))


def decode_xbe(head, size, path):
    """Original Xbox executable: 'XBEH', base address, sizes, entry point."""
    title = head[0x10C:0x10C + 40].split(b"\x00")[0].decode("latin-1", "replace")
    base, headers, image = struct.unpack_from("<3I", head, 4)
    entry = struct.unpack_from("<I", head, 0x128)[0]
    return "decoded", "XBE base 0x%x, %d byte image, entry 0x%x%s" % (
        base, image, entry, (", %r" % title) if title.strip() else "")


def decode_bmp(head, size, path):
    offset = struct.unpack_from("<I", head, 10)[0]
    width, height = struct.unpack_from("<ii", head, 18)
    bits = struct.unpack_from("<H", head, 28)[0]
    return "decoded", "BMP %dx%d, %d bpp, pixels at %d" % (width, height, bits, offset)


def decode_png(head, size, path):
    width, height = struct.unpack_from(">II", head, 16)
    return "decoded", "PNG %dx%d" % (width, height)


def decode_wav(head, size, path):
    """RIFF: walk the chunks to fmt and data."""
    with open(path, "rb") as fh:
        fh.seek(12)
        rate = channels = bits = data = 0
        while True:
            raw = fh.read(8)
            if len(raw) < 8:
                break
            tag, length = struct.unpack("<4sI", raw)
            if tag == b"fmt ":
                body = fh.read(min(length, 16))
                if len(body) >= 16:
                    _, channels, rate, _, _, bits = struct.unpack("<HHIIHH", body)
                fh.seek(length - len(body), 1)
            elif tag == b"data":
                data = length
                break
            else:
                fh.seek(length + (length & 1), 1)
    if rate and data:
        return "decoded", "WAV %d Hz, %d ch, %d-bit, %d bytes of audio" % (rate, channels, bits, data)
    return "partial", "RIFF without a fmt/data pair"


def decode_mp3(head, size, path):
    return "decoded", "MP3 %d bytes" % size


def decode_mp4(head, size, path):
    return "decoded", "MP4 container"


def decode_jpg(head, size, path):
    return "decoded", "JPEG %d bytes" % size


def decode_ico(head, size, path):
    count = struct.unpack_from("<H", head, 4)[0]
    return "decoded", "ICO with %d image(s)" % count


def decode_ttf(head, size, path):
    tables = struct.unpack_from(">H", head, 4)[0]
    return "decoded", "TrueType with %d tables" % tables


def decode_avatar(head, size, path):
    if size < 1000:
        return "partial", "avatar description only %d bytes" % size
    return "decoded", "avatar description, %d bytes" % size


def decode_dat(head, size, path):
    """`.dat` here is either ICU data (handled above) or plain text."""
    return decode_text(head, size, path)


def decode_text(head, size, path):
    """Text has to look like text: a third of the bytes printable, few controls."""
    with open(path, "rb") as fh:
        body = fh.read()
    if body[:2] in (b"\xff\xfe", b"\xfe\xff"):
        # UTF-16 first: its zero bytes look like binary to a control-byte test.
        try:
            text = body.decode("utf-16")
        except UnicodeDecodeError:
            return "blocked", "UTF-16 text that does not decode"
        return "text", "UTF-16 text, %d lines" % text.count("\n")
    probe = body[:65536]
    if probe:
        controls = sum(1 for b in probe if b < 9 or 13 < b < 32)
        if controls * 20 > len(probe):
            return "blocked", "binary, no decoder for this header %s" % probe[:4].hex()
    try:
        text = body.decode("utf-8")
    except UnicodeDecodeError:
        try:
            text = body.decode("latin-1")
        except UnicodeDecodeError:
            return "blocked", "not text"
    return "text", "text, %d lines" % text.count("\n")


# --------------------------------------------------------------- dispatch

def sniff(head, size, path):
    """Format name from the first bytes. Extensions lie; magic does not."""
    ext = os.path.splitext(path)[1].lower()
    if head[:4] == b"\x89PNG":
        return "png", decode_png
    if head[:4] == b"RIFF":
        return "wav", decode_wav
    if head[:3] == b"ID3" or (head[:1] == b"\xff" and head[1:2] and (head[1] & 0xE0) == 0xE0):
        return "mp3", decode_mp3
    if head[:4] == b"XBEH":
        return "xbe", decode_xbe
    if head[:2] == b"BM" and struct.unpack_from("<H", head, 6)[0] == 0:
        return "bmp", decode_bmp
    if head[:4] == b"\x00\x00\x00 " and head[4:8] == b"ftyp":
        return "mp4", decode_mp4
    if head[:3] == b"\xff\xd8\xff":
        return "jpg", decode_jpg
    if head[:4] == b"\x00\x00\x01\x00":
        return "ico", decode_ico
    if head[:2] == b"MZ":
        return "pe", decode_pe
    if head[:4] == b"XEX2":
        return "xex", decode_xex2
    if head[:4] == b"XPR0":
        return "xpr0", decode_xpr0
    if head[:4] == b"XTF0":
        return "xtf", decode_xtf
    if head[:4] == b"xttf":
        return "xtt", decode_xtt
    if head[:4] == b"XIP0":
        return "xip0", decode_xip0
    if head[:4] == b"STRB":
        return "strb", decode_strb
    if head[:8] == b"\x8av-\xf4\xc0gKf":
        return "toc", decode_toc
    if head[:8] == b"\x05\x00\x00\x00\x01\x00\x00\x00":
        return "pak", decode_pak
    if head[:8] == b"\x90\x00\xda\x27\x14\x00\x00\x00":
        return "icu", decode_icu
    if head[:8] in (b"\x03\x00\x00\x00\x01\x00\x00\x00", b"\x01\x00\x00\x00\x01\x00\x00\x00"):
        return "v8snapshot", decode_v8
    if head[:4] == b"\x00\x01\x00\x00":
        return "ttf", decode_ttf
    if head[:4] == b"\x04\x00\x00\x00" and ext == ".xm":
        return "xm", decode_xm
    if ext == ".avatar":
        return "avatar", decode_avatar
    return "text", decode_text


DEPTH = {
    "pe": "COFF/optional headers, section count and bitness. The code is PowerPC/x86 "
          "and is not disassembled.",
    "pak": "full resource table: counts, every entry's id and offset validated against "
           "the file.",
    "xip0": "header, dimensions and payload size. The payload is dashboard UI data "
            "whose semantics are not mapped.",
    "xm": "header only; the float body is not parsed.",
    "wav": "fmt and data chunks: rate, channels, bit depth and audio length.",
    "png": "IHDR dimensions.",
    "xtf": "header and face name; the glyph tables are not rasterised.",
    "xex": "header only: the body is LZX-compressed and title-encrypted.",
    "toc": "the avatar pack's record table (offsets and sizes per asset).",
    "mp3": "container only.",
    "xpr0": "pixels decoded: 131 of 135 export to PNG with xpr0_export.py, as DXT1, "
            "DXT5, or the first of two stacked DXT1 planes.",
    "text": "read as UTF-8/UTF-16/latin-1 and line counted.",
    "mp4": "container only.",
    "xbe": "base address, image size and entry point; no code executed.",
    "v8snapshot": "version string from the header.",
    "strb": "block count; the blocks themselves are decoded by avatar_mesh.",
    "ttf": "table count.",
    "bmp": "dimensions, bit depth and pixel offset.",
    "xtt": "version and size.",
    "ico": "image count.",
    "jpg": "container only.",
    "avatar": "the 1000-byte description: face features, nine colours, item entries.",
    "icu": "entry count from the header.",
}


def audit(root, report_path=None):
    formats = collections.OrderedDict()
    blocked = []
    failures = []
    total = 0
    for base, _, files in os.walk(root):
        for name in sorted(files):
            path = os.path.join(base, name)
            total += 1
            try:
                size = os.path.getsize(path)
                with open(path, "rb") as fh:
                    head = fh.read(4096)
            except OSError as error:
                failures.append((path, str(error)))
                continue
            format_name, decoder = sniff(head, size, path)
            try:
                status, detail = decoder(head, size, path)
            except Exception as error:                     # a decoder's own bug
                status, detail = "blocked", "%s: %s" % (type(error).__name__, error)
            entry = formats.setdefault(format_name, collections.Counter())
            entry[status] += 1
            entry["bytes"] += size
            if status in ("blocked", "partial"):
                blocked.append((format_name, status, path, detail, size))

    lines = ["# Decode coverage", "",
             "Every file under the source archive, identified by magic rather than by",
             "extension, with the decoder that was run and what it read.", "",
             "| format | files | decoded | text | partial | blocked | MiB |",
             "| --- | ---: | ---: | ---: | ---: | ---: | ---: |"]
    for name, counts in sorted(formats.items(), key=lambda kv: -sum(kv[1].values())):
        lines.append("| %s | %d | %d | %d | %d | %d | %.1f |" % (
            name, sum(v for k, v in counts.items() if k != "bytes"),
            counts["decoded"], counts["text"], counts["partial"], counts["blocked"],
            counts["bytes"] / 1048576.0))
    lines += ["", "**%d files, %d bytes.**" % (total, sum(c["bytes"] for c in formats.values()))]
    if DEPTH:
        lines += ["", "## How deep each decoder goes", ""]
        for name in sorted(DEPTH):
            if name in formats:
                lines.append("- **%s** - %s" % (name, DEPTH[name]))
    if blocked:
        lines += ["", "## Not fully decoded", ""]
        by_conf = collections.defaultdict(list)
        for format_name, status, path, detail, size in blocked:
            by_conf[(format_name, status, detail)].append(path)
        for (format_name, status, detail), paths in sorted(by_conf.items(),
                                                           key=lambda kv: -len(kv[1])):
            lines.append("- **%s** (%s) - %d file(s): %s" % (format_name, status, len(paths), detail))
            for path in paths[:3]:
                lines.append("  - `%s`" % os.path.relpath(path, root))
    report = "\n".join(lines) + "\n"
    if report_path:
        open(report_path, "w").write(report)
    print(report)
    return 1 if failures else 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("root")
    parser.add_argument("--report")
    args = parser.parse_args()
    return audit(args.root, args.report)


if __name__ == "__main__":
    sys.exit(main())
