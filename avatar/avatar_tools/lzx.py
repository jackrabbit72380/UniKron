"""LZX decompression, for the shape-override payloads.

STATUS: written, not verified. No payload decodes under any framing tried so far
(stream start anywhere in bytes 56-72, 16- and 32-bit words, both bit orders,
windows 15/16/21, with and without the leading block-type flag), and there is no
reference LZX stream in this workspace to test the decoder against. Treat it as
unproven: do not use it to decide anything about the art until a known-good
stream confirms it.

What the payloads themselves say: each ShapeOverrides block opens with a flags
word, a size word that is a multiple of 12 in all 266 cases (423, 1132 or 1227
three-float records), and a 16-byte component descriptor ending in the constant
GUID c1c8f109a19cb2e0. The data past byte 64 has an entropy of 7.3 to 7.6 bits
per byte, so it is compressed rather than stored; the binary that ships with the
pack contains an lzx_decompress, which is why this exists.
"""

import struct


class LzxError(Exception):
    pass


POSITION_SLOTS = {15: 30, 16: 32, 17: 34, 18: 36, 19: 38, 20: 42, 21: 50}
NUM_CHARS = 256
PRETREE_ELEMENTS = 20
ALIGNED_ELEMENTS = 8
LENGTH_ELEMENTS = 249
MIN_MATCH = 2
NUM_PRIMARY_LENGTHS = 7


class Bits:
    """Bits out of 16-bit big-endian words, most significant first."""

    def __init__(self, data):
        self.data = data
        self.pos = 0
        self.buffer = 0
        self.left = 0

    def ensure(self, count):
        while self.left < count:
            hi = self.data[self.pos] if self.pos < len(self.data) else 0
            lo = self.data[self.pos + 1] if self.pos + 1 < len(self.data) else 0
            self.buffer |= ((hi << 8) | lo) << (16 - self.left)
            self.pos += 2
            self.left += 16
        self.buffer &= 0xFFFFFFFF

    def read(self, count):
        if count == 0:
            return 0
        self.ensure(count)
        value = (self.buffer >> (32 - count)) & ((1 << count) - 1)
        self.buffer = (self.buffer << count) & 0xFFFFFFFF
        self.left -= count
        return value

    def align16(self):
        """Drop the partial word, as the uncompressed block type requires."""
        if self.left % 16:
            drop = self.left % 16
            self.buffer = (self.buffer << drop) & 0xFFFFFFFF
            self.left -= drop


def build(lengths):
    """Canonical Huffman table: {(length, code): symbol}, and the max length."""
    table = {}
    code = 0
    max_len = max(lengths) if lengths else 0
    for size in range(1, max_len + 1):
        for symbol, length in enumerate(lengths):
            if length == size:
                table[(size, code)] = symbol
                code += 1
        code <<= 1
    return table, max_len


def decode_symbol(bits, table, max_len):
    code = 0
    for size in range(1, max_len + 1):
        code = (code << 1) | bits.read(1)
        symbol = table.get((size, code))
        if symbol is not None:
            return symbol
    raise LzxError("no symbol in tree")


def read_lengths(bits, lengths, first, last):
    """The pretree-coded run-length scheme LZX uses for tree code lengths."""
    pretree_lengths = [bits.read(4) for _ in range(PRETREE_ELEMENTS)]
    pretree, pretree_max = build(pretree_lengths)
    index = first
    while index < last:
        symbol = decode_symbol(bits, pretree, pretree_max)
        if symbol == 17:
            run = 4 + bits.read(4)
            value = 0
        elif symbol == 18:
            run = 20 + bits.read(5)
            value = 0
        elif symbol == 19:
            run = 4 + bits.read(1)
            value = lengths[index - 1] if index else 0
        else:
            run = 1
            previous = lengths[index - 1] if index else 0
            value = (previous - symbol) % 17
        for _ in range(run):
            if index < last:
                lengths[index] = value
            index += 1


def decompress(data, out_size, window_bits=15, first_block_has_type=True,
               verbose=False):
    """LZX stream -> out_size bytes.

    `first_block_has_type` says whether the first block starts with its 3-bit
    type or with the 1-bit "type follows" flag that later blocks use.
    """
    if window_bits not in POSITION_SLOTS:
        raise LzxError("bad window bits %r" % window_bits)
    window_size = 1 << window_bits
    position_slots = POSITION_SLOTS[window_bits]
    main_elements = NUM_CHARS + position_slots * 8
    bits = Bits(data)

    out = bytearray()
    window = bytearray(window_size)
    window_pos = 0
    r0 = r1 = r2 = 1
    main_lengths = [0] * main_elements
    length_lengths = [0] * LENGTH_ELEMENTS
    aligned_lengths = [0] * ALIGNED_ELEMENTS
    main_table = length_table = aligned_table = {}
    main_max = length_max = aligned_max = 0
    block_type = 0
    block_remaining = 0
    first = True

    while len(out) < out_size:
        if block_remaining == 0:
            if block_type == 3:
                bits.align16()
            if not first or not first_block_has_type:
                if bits.read(1):
                    block_type = bits.read(3)
            else:
                block_type = bits.read(3)
            block_length = bits.read(16)
            block_length = (block_length << 8) | bits.read(8)
            if verbose:
                print("  block type %d length %d at out %d"
                      % (block_type, block_length, len(out)))
            if block_length <= 0 or block_length > out_size + window_size:
                raise LzxError("implausible block length %d" % block_length)
            block_remaining = block_length
            if block_type == 3:
                bits.align16()
                values = []
                for _ in range(3):
                    raw = bytes(bits.read(8) for _ in range(4))
                    values.append(struct.unpack("<I", raw)[0])
                r0, r1, r2 = values
            elif block_type in (1, 2):
                read_lengths(bits, main_lengths, 0, NUM_CHARS)
                read_lengths(bits, main_lengths, NUM_CHARS, main_elements)
                main_table, main_max = build(main_lengths)
                read_lengths(bits, length_lengths, 0, LENGTH_ELEMENTS)
                length_table, length_max = build(length_lengths)
                if block_type == 2:
                    for i in range(ALIGNED_ELEMENTS):
                        aligned_lengths[i] = bits.read(3)
                    aligned_table, aligned_max = build(aligned_lengths)
            else:
                raise LzxError("bad block type %d" % block_type)
            first = False

        if block_type in (1, 2):
            symbol = decode_symbol(bits, main_table, main_max)
            if symbol < NUM_CHARS:
                out.append(symbol)
                window[window_pos] = symbol
                window_pos = (window_pos + 1) % window_size
                block_remaining -= 1
                continue

            symbol -= NUM_CHARS
            length_header = symbol & NUM_PRIMARY_LENGTHS
            position_slot = symbol >> 3
            if length_header == NUM_PRIMARY_LENGTHS:
                match_length = MIN_MATCH + NUM_PRIMARY_LENGTHS + \
                    decode_symbol(bits, length_table, length_max)
            else:
                match_length = MIN_MATCH + length_header

            if position_slot == 0:
                match_offset = r0
            elif position_slot == 1:
                match_offset = r1
                r1 = r0
                r0 = match_offset
            elif position_slot == 2:
                match_offset = r2
                r2 = r0
                r0 = match_offset
            else:
                extra = position_slot // 2 - 1
                match_offset = (1 << extra) if extra > 0 else 1
                if extra > 3:
                    match_offset += bits.read(extra - 3) << 3
                    match_offset += decode_symbol(bits, aligned_table, aligned_max) \
                        if block_type == 2 else bits.read(3)
                elif extra > 0:
                    match_offset += bits.read(extra)
                match_offset -= 1
                r2, r1, r0 = r1, r0, match_offset + 1

            for _ in range(match_length):
                if match_offset > len(out):
                    break
                byte = out[len(out) - match_offset]
                out.append(byte)
                window[window_pos] = byte
                window_pos = (window_pos + 1) % window_size
                if len(out) >= out_size:
                    break
            block_remaining -= match_length
        else:
            byte = bits.read(8)
            out.append(byte)
            window[window_pos] = byte
            window_pos = (window_pos + 1) % window_size
            block_remaining -= 1

    return bytes(out[:out_size])
