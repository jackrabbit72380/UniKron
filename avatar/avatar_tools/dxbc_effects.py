"""Read DXBC shader containers and print their constant tables.

The 2010 host binary (`metro2010/avatareditor.exe`) embeds eleven DXBC blobs.
Each one's RDEF chunk names every shader constant, its type and, when the
compiler kept them, its default value - which is where a lighting rig's numbers
actually live.

    python3 dxbc_effects.py avatareditor.exe
"""

import struct
import sys

CONTAINER_MAGIC = b"DXBC"

CLASSES = {0: "scalar", 1: "vector", 2: "matrix_rows", 3: "matrix_cols",
           4: "object", 5: "struct"}
TYPES = {1: "bool", 2: "int", 3: "uint", 4: "float", 5: "string",
         6: "texture", 7: "texture1d", 8: "texture2d", 9: "texture3d",
         10: "texturecube", 11: "sampler", 12: "sampler1d", 13: "sampler2d",
         14: "sampler3d", 15: "samplercube", 16: "pixelshader",
         17: "vertexshader", 19: "texture2dms", 20: "texture2dmsarray",
         21: "texturecubearray", 22: "texture1darray", 23: "texture2darray"}
SHADER_KINDS = {0: "pixel", 1: "vertex", 2: "geometry", 3: "hull", 4: "domain",
                5: "compute"}
CATEGORIES = {0: "dword", 1: "immediate", 2: "cbuffer", 3: "tbuffer",
              4: "texture", 5: "sampler", 6: "uav", 7: "num"}


def find_containers(data):
    """Yield (offset, size) for every valid DXBC container in the image."""
    index = 0
    while True:
        offset = data.find(CONTAINER_MAGIC, index)
        if offset < 0:
            return
        index = offset + 1
        if offset + 32 > len(data):
            continue
        size, = struct.unpack_from("<I", data, offset + 24)
        count, = struct.unpack_from("<I", data, offset + 28)
        if not (32 <= size <= 4 << 20) or count > 32 or offset + size > len(data):
            continue
        valid = True
        for entry in range(count):
            if 32 + entry * 4 + 4 > len(data):
                valid = False
                break
            chunk_offset, = struct.unpack_from("<I", data, offset + 32 + entry * 4)
            if chunk_offset + 8 > size:
                valid = False
                break
            if not all(32 <= b < 127 for b in data[offset + chunk_offset:offset + chunk_offset + 4]):
                valid = False
                break
        if valid:
            yield offset, size


def chunks(data, offset, size):
    count, = struct.unpack_from("<I", data, offset + 28)
    result = {}
    for entry in range(count):
        chunk_offset, = struct.unpack_from("<I", data, offset + 32 + entry * 4)
        fourcc = data[offset + chunk_offset:offset + chunk_offset + 4].decode("latin-1")
        chunk_size, = struct.unpack_from("<I", data, offset + chunk_offset + 4)
        result[fourcc] = data[offset + chunk_offset + 8:offset + chunk_offset + 8 + chunk_size]
    return result


def cstring(blob, offset):
    end = blob.find(b"\x00", offset)
    return blob[offset:end].decode("latin-1") if end >= 0 else ""


def parse_rdef(blob):
    """Return the shader's target and constant buffers with their variables."""
    cb_count, cb_offset, bind_count, bind_offset = struct.unpack_from("<IIII", blob, 0)
    minor, major, kind = struct.unpack_from("<BBH", blob, 16)
    result = {
        "target": f"{SHADER_KINDS.get(kind, kind)}_{major}_{minor}",
        "buffers": [],
        "bound": [],
    }
    for index in range(cb_count):
        base = cb_offset + index * 24
        name_offset, var_count, var_offset, size, flags, cb_type = \
            struct.unpack_from("<IIIIII", blob, base)
        buffer = {"name": cstring(blob, name_offset), "size": size,
                  "variables": []}
        for var in range(var_count):
            var_base = cb_offset + var_offset + var * 24
            (name_off, start, var_size, var_flags, type_off,
             default_off) = struct.unpack_from("<IIIIII", blob, var_base)
            info = parse_type(blob, type_off) if type_off else {}
            entry = {
                "name": cstring(blob, name_off),
                "offset": start,
                "size": var_size,
                "type": info.get("text", "?"),
                "default": [],
            }
            if default_off and var_size and default_off + var_size <= len(blob):
                raw = blob[default_off:default_off + var_size]
                if info.get("scalar") == "float":
                    entry["default"] = [round(v, 6) for v in
                                        struct.unpack(f"<{var_size // 4}f", raw)]
                else:
                    entry["default"] = list(raw)
            buffer["variables"].append(entry)
        result["buffers"].append(buffer)
    for index in range(bind_count):
        base = bind_offset + index * 32
        name_off, bind_type, return_type, dimension, samples, bind_point, bind_count_, bind_flags = \
            struct.unpack_from("<IIIIIIII", blob, base)
        result["bound"].append({
            "name": cstring(blob, name_off),
            "type": TYPES.get(bind_type, bind_type),
            "register": bind_point,
            "count": bind_count_,
        })
    return result


def parse_type(blob, offset):
    cls, typ, rows, columns, elements, members, member_offset = \
        struct.unpack_from("<HHHHHHI", blob, offset)
    return {
        "text": f"{CLASSES.get(cls, cls)}<{TYPES.get(typ, typ)}>"
                f"{'' if rows == 1 and columns == 1 else f' {rows}x{columns}'}"
                f"{'' if elements <= 1 else f'[{elements}]'}",
        "scalar": TYPES.get(typ),
    }


def describe(data, offset, size):
    parts = chunks(data, offset, size)
    print(f"DXBC at {offset:#08x}  {size} bytes  chunks: {', '.join(sorted(parts))}")
    if b"RDEF" not in parts:
        return
    table = parse_rdef(parts[b"RDEF"])
    print(f"  target {table['target']}")
    for buffer in table["buffers"]:
        print(f"  buffer {buffer['name']!r} ({buffer['size']} bytes)")
        for variable in buffer["variables"]:
            printable = ""
            if variable["default"]:
                values = variable["default"]
                if all(isinstance(v, float) for v in values):
                    printable = " = " + ", ".join(f"{v:g}" for v in values)
                else:
                    printable = " = " + " ".join(f"{v:02x}" for v in values)
            print(f"    +{variable['offset']:>3}  {variable['type']:<22}"
                  f"{variable['name']}{printable}")
    for binding in table["bound"]:
        print(f"    bind {binding['type']} {binding['name']} -> {binding['register']}")


def main(argv):
    if len(argv) != 2:
        print(__doc__.strip())
        return 2
    data = open(argv[1], "rb").read()
    count = 0
    for offset, size in find_containers(data):
        describe(data, offset, size)
        count += 1
    print(f"{count} containers")
    return 0 if count else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
