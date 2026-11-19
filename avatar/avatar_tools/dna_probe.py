"""Probe the DNA.Common `AnimationClip` body across the archive.

Prints one line per DNA clip: header fields, which track set the walk took
(three tracks a bone, or two for Avatar Connection), and how far short of the
last byte it stopped. Run with no arguments to scan `src_archive/avatar-games`;
pass a substring to narrow it.
"""

import collections
import os
import sys

import xnb_avatar

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                    "..", "..", "..", "src_archive", "avatar-games")


def clips(root=ROOT):
    for base, _, names in os.walk(root):
        for name in sorted(names):
            if name.lower().endswith(".xnb"):
                yield os.path.join(base, name)


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    seen = collections.Counter()
    ok = bad = 0
    for path in clips():
        rel = os.path.relpath(path, ROOT)
        if only and only not in rel:
            continue
        head = xnb_avatar.read_type_readers(xnb_avatar.load(path))
        if "DNA" not in head["readers"][0][0]:
            continue
        game = rel.split("/Content")[0].rsplit("/", 1)[-1]
        try:
            clip = xnb_avatar.read_dna(path)
        except Exception as error:  # noqa: BLE001 - probe
            print("ERR %-52s %s" % (rel, error))
            bad += 1
            continue
        gap = clip["size"] - clip["end"]
        keys = [len(b.get("rotation", ())) for b in clip["bones"]]
        seen[(game, clip["tracks"])] += 1
        ok += gap == 0
        bad += gap != 0
        print("%s %-24s %-18r %2d tracks  %4d fps  %5.3f s  %2d bones  "
              "rot keys %d..%d  flag %d  gap %d"
              % ("ok " if gap == 0 else "BAD", game, clip["name"], clip["tracks"],
                 clip["fps"], clip["duration"], len(clip["bones"]),
                 min(keys), max(keys), clip["flag"], gap))
    print()
    for (game, tracks), count in sorted(seen.items()):
        print("  %-18s %d clips, %d tracks a bone" % (game, count, tracks))
    print("%d land on the last byte, %d do not" % (ok, bad))


if __name__ == "__main__":
    main()
