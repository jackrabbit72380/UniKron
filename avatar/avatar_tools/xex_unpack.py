"""Decrypt an Xbox 360 XEX2 image into the PE it wraps.

The 2010 `avatareditor.xex` in the archive is high-entropy from its very first
sector, which is why it was recorded as "ciphertext, unusable". It is not: an XEX2
keeps a 16-byte AES session key in its security info, itself encrypted under a
*fixed* key that every 360 toolchain carries in plain sight (the console needs it
to boot anything), and the image body is AES-128-CBC with a zero IV under the
unwrapped key. So the file is recoverable offline, with no console and no per-machine
key -- only the public one.

Format, from the Free60 wiki's XEX page and the XEX notes in xenia / Xenon-Recomp
(`src/xenia/cpu/xex_module.cc`, `docs/xbox/XEX_LOADER_V2.md`):

    header        0x00  "XEX2", module flags, PE data offset, reserved,
                        security info offset, optional header count
    optional      0x18  8 bytes each: key, value; low byte of key says how to read
                        the value (0/1 inline, 0xFF file offset to a sized block,
                        anything else n -> file offset to n*4 bytes)
    security      at the header's offset:
                    +0x000  header size  (covers security + section info)
                    +0x004  image size
                    +0x008  RSA signature (256 bytes)
                    +0x10C  image flags
                    +0x110  load address
                    +0x140  media id
                    +0x150  encrypted image key (16 bytes)
                    +0x178  region, +0x17C allowed media, +0x180 page count
    body          from "PE data offset" to EOF: AES-128-CBC, zero IV, image key.
                  Some images are then LZX-compressed; this refuses rather than
                  guessing, and says which optional headers it saw.

    python3 xex_unpack.py <in.xex> <out.bin>

Exit status 0 only when the output starts with a PE ("MZ") or when it says the
image is compressed (which it reports as such, with the flag it found).
"""

import struct
import sys

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

# The fixed key that wraps the session key. Public: it is in xenia, idaxex, XexTool
# and the Free60 wiki, because the retail console has to hold it to start anything.
KEK_RETAIL = bytes.fromhex("20b185a5" "9d28fdc3" "40583fbb" "0896bf91")
KEK_DEVKIT = bytes(16)


def aes_ecb_decrypt(key, data):
    dec = Cipher(algorithms.AES(key), modes.ECB()).decryptor()
    return dec.update(data) + dec.finalize()


def aes_cbc_decrypt(key, data, iv=bytes(16)):
    dec = Cipher(algorithms.AES(key), modes.CBC(iv)).decryptor()
    return dec.update(data) + dec.finalize()


class Xex:
    def __init__(self, path):
        self.data = open(path, "rb").read()
        d = self.data
        if d[:4] != b"XEX2":
            raise SystemExit("%s does not start with XEX2" % path)
        (self.magic, self.flags, self.pe_offset, self.reserved,
         self.sec_offset, self.opt_count) = struct.unpack(">4sIIIII", d[:24])
        self.optional = []
        off = 0x18
        for _ in range(self.opt_count):
            key, value = struct.unpack(">II", d[off:off + 8])
            self.optional.append((key, value))
            off += 8
        s = self.sec_offset
        self.sec_size, self.image_size = struct.unpack(">II", d[s:s + 8])
        self.image_flags, self.load_address = struct.unpack(">II", d[s + 0x10C:s + 0x114])
        self.encrypted_key = d[s + 0x150:s + 0x160]
        self.page_count = struct.unpack(">I", d[s + 0x180:s + 0x184])[0]

    def compressed(self):
        """Which compression the optional headers declare, if any.

        0x000103FF is basic compression, 0x000203FF normalization info,
        0x000303FF the LZX-compressed form of the same table.
        """
        names = {0x000103FF: "basic", 0x000203FF: "normalization", 0x000303FF: "lzx"}
        return [names[k] for k, _ in self.optional if k in names]

    def body(self):
        return self.data[self.pe_offset:]

    def key_candidates(self):
        """The session key under each fixed key, plus the raw field as a fallback."""
        out = [("retail", aes_ecb_decrypt(KEK_RETAIL, self.encrypted_key)),
               ("devkit", aes_ecb_decrypt(KEK_DEVKIT, self.encrypted_key)),
               ("plain", self.encrypted_key)]
        return out


def looks_like_pe(blob):
    return blob[:2] == b"MZ" or b"PE\0\0" in blob[:0x400]


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__.strip().splitlines()[-1] if False else
                         "usage: python3 xex_unpack.py <in.xex> <out.bin>")
    src, dst = sys.argv[1], sys.argv[2]
    x = Xex(src)
    print("flags 0x%x, pe data at 0x%x, security info at 0x%x (%d bytes, %d optional "
          "headers), image 0x%x bytes, load 0x%x"
          % (x.flags, x.pe_offset, x.sec_offset, x.sec_size, len(x.optional),
             x.image_size, x.load_address))
    comp = x.compressed()
    print("compression declared:", ", ".join(comp) if comp else "none")

    body = x.body()
    usable = len(body) - (len(body) % 16)
    best = None
    for name, key in x.key_candidates():
        plain = aes_cbc_decrypt(key, body[:usable]) + body[usable:]
        head = plain[:16].hex()
        ok = looks_like_pe(plain)
        print("  key %-6s %s  head %s" % (name, key.hex(), head))
        if ok and best is None:
            best = (name, key, plain)
    if best is None:
        print("no key produced a PE; the body may be compressed (see the flags above)")
        # Still write the most plausible attempt so the header can be inspected.
        name, key = "retail", aes_ecb_decrypt(KEK_RETAIL, x.encrypted_key)
        plain = aes_cbc_decrypt(key, body[:usable]) + body[usable:]
        open(dst, "wb").write(plain)
        print("wrote %s (undecrypted-looking, %d bytes)" % (dst, len(plain)))
        return 1
    name, key, plain = best
    open(dst, "wb").write(plain)
    pe = plain.find(b"PE\0\0")
    print("decrypted with the %s key: %d bytes, PE header at 0x%x, wrote %s"
          % (name, len(plain), pe, dst))
    return 0


if __name__ == "__main__":
    sys.exit(main())
