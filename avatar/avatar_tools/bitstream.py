"""The bit reader the editor uses for block 4, ported from its own code.

`0x140dbe460` is a variable-width bit reader and it is the only place in the
binary that unpacks anything. Read off the disassembly:

    mov 0x8(%rcx),%rsi          ; the position is in BITS, held in the stream
    mov (%r8),%rdi              ; the buffer
  loop:
    r11 = pos & 7               ; bit offset inside the current byte
    r10 = min(8 - r11, left)    ; how many bits this byte can still give
    ebp = ~(-1 << r10)          ; mask of that many bits
    byte = data[pos >> 3]
    part = (byte >> r11) & ebp  ; low bits first
    value |= part << got        ; and assembled low bits first
    got += r10; pos += r10; left -= r10
  ... until `left` runs out, then the stream's position advances by `bits`

So: least-significant bit first inside each byte, and the first bit read becomes
the least-significant bit of the result. For byte-aligned fields this is the same
as a little-endian read.

Two callers give the layout, and both were checked against the pack:

`0x140dbe690` reads a component record - 32 bits, 16, 16, then eight single bytes
- and applies `bswap` to the 32 and `rol $8` to each 16. Because the fields are
byte aligned, that comes back to exactly the same bytes as the unpacked record:
decoding Large Chin, Soft Nose and Elven Ears from 0x40 yields
`01000000-0200-0300` and the family GUID every time.

`0x140dbee70` reads a quantised value:

    v = base (+0x04 of the parameter block) + read(width at +0x08)
    ... then three more reads at widths (+0x28), (+0x29), (+0x2a)
    float = offset (+0x10, +0x18, +0x14) + scale (+0x1c, +0x20, +0x24) * int
    and the low bit of one of the reads is a sign: `and $1`, and if set it adds
    a constant (0x140f7b138) to flip it - a zig-zag signed quantisation

The parameter block is filled from the block-4 header, which is what
`decode_shape.py` would need next.
"""


def read_bits(data, position, count):
    """(value, new_position) - `position` and the result are bit-granular."""
    value = 0
    got = 0
    while got < count:
        offset = position & 7
        take = min(8 - offset, count - got)
        part = (data[position >> 3] >> offset) & ((1 << take) - 1)
        value |= part << got
        got += take
        position += take
    return value, position


def read_record(data, position):
    """The 16-byte component record `0x140dbe690` reads: slot, index, kind, GUID."""
    word, position = read_bits(data, position, 32)
    word = int.from_bytes(word.to_bytes(4, "little"), "big")
    index, position = read_bits(data, position, 16)
    index = ((index & 0xFF) << 8) | (index >> 8)
    kind, position = read_bits(data, position, 16)
    kind = ((kind & 0xFF) << 8) | (kind >> 8)
    guid = bytearray()
    for _ in range(8):
        byte, position = read_bits(data, position, 8)
        guid.append(byte)
    return {"slot": word, "index": index, "kind": kind, "guid": bytes(guid)}, position
