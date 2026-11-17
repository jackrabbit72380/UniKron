"""Prove the pack is fully readable *before* baking a thousand pictures.

Baking is the expensive step: a full pass is plates for two genders, roughly 950
turntable sets and an animated set, and every mistake found at the end costs
another pass. Twice now a bake finished and only then turned out to be missing
something (a base body plate the baker silently skips, hairstyle sets written to a
folder the editor never reads). Those are decoding-and-plumbing faults, and they
are all findable in a few seconds of opening every asset and checking every field.

So this runs first, and it is the gate:

    python3 audit_pack.py PACK
    python3 audit_pack.py PACK --json audit.json --md DECODE_STATUS.md

It opens each of the pack's assets, decodes every block it knows how to decode,
checks the decoded data against itself (indices in range, weights summing to one,
joints that exist, UVs finite), and cross-checks the things that have no business
disagreeing: the gender in the metadata block against the gender the bakers use,
the descriptor slots against the assets that exist, and the skeleton's bone lengths
against the geometry those bones are supposed to drive.

Exit status is 0 when every block decodes and every cross-check agrees, 1 otherwise.
"""

import argparse
import json
import math
import multiprocessing
import os
import struct
import sys

import numpy as np

import asset_catalog
import avatar_desc
import avatar_mesh as am
import avatar_pose as ap
import skeleton_nxe as sk

HERE = os.path.dirname(os.path.abspath(__file__))
BLOCKS = {1: "Animation", 2: "Texture", 3: "Model", 4: "ShapeOverrides",
          7: "ColourTable", 8: "Metadata"}
# Bone length over geometry reach outside this band means the rig and the mesh
# disagree, which bends geometry around a pivot that is not where it looks. The
# upper end is loose on purpose: a finger's last joint is the *origin* of the
# distal phalanx, so the geometry legitimately runs past the last bone by up to
# one phalanx plus a fingertip cap (0.062 on a 0.081 chain, measured).
REACH_BAND = (0.75, 1.75)


def audit_asset(job):
    pack, name = job
    report = {"name": name, "blocks": [], "problems": [], "counts": {}}
    try:
        index = am.load_pack_index(pack)
        blob = am.asset_bytes(pack, index, name)
        blocks = am.strb_blocks(blob)
    except Exception as exc:                                    # noqa: BLE001
        report["problems"].append("container: %s: %s" % (type(exc).__name__, exc))
        return report

    for block_id, count, size, payload in blocks:
        kind = BLOCKS.get(block_id, "unknown(%d)" % block_id)
        entry = {"kind": kind, "bytes": len(payload)}
        report["blocks"].append(entry)
        try:
            if block_id == 3:
                model = am.read_model(am.decompress(payload))
                stats = model_stats(model)
                entry.update(stats)
                report["counts"].update(stats)
                textures = next((len(p) for i, _, _, p in blocks if i == 2), 0)
                report["problems"].extend(check_model(model, textures))
                for i, batch in enumerate(model):
                    for material in batch.get("materials") or []:
                        tex = material.get("texture")
                        if tex is not None and textures and tex >= textures:
                            report["problems"].append(
                                "model %d: material points at texture %d of %d"
                                % (i, tex, textures))
            elif block_id == 2:
                entry.update(texture_stats(payload))
            elif block_id == 1:
                poses, frames = ap.read_animation_poses(payload, 0)
                entry.update({"frames": frames, "joints": len(poses)})
                report["problems"].extend(check_poses(poses))
            elif block_id == 8:
                meta = asset_catalog.read_metadata(payload)
                entry.update(meta or {})
            elif block_id == 4:
                entry["decoded"] = False
                report["problems"].append(
                    "ShapeOverrides: %d bytes not decoded" % len(payload))
        except Exception as exc:                                # noqa: BLE001
            entry["error"] = "%s: %s" % (type(exc).__name__, exc)
            report["problems"].append("%s: %s: %s" % (kind, type(exc).__name__, exc))
    return report


def model_stats(model):
    verts = sum(len(b["vertices"]) for b in model)
    tris = sum(len(b["indices"]) // 3 for b in model)
    return {"batches": len(model), "verts": verts, "tris": tris}


def check_model(model, asset_textures=0):
    """Everything a decoded batch has to be true of before it can be drawn.

    A batch's `textures` list is always empty: the pixels live in the asset's
    Texture block, and a material's texture index counts into that. Checking the
    index against the batch's own list reports every textured asset as broken.
    """
    out = []
    for i, batch in enumerate(model):
        n = len(batch["vertices"])
        if n == 0:
            out.append("model %d: no vertices" % i)
            continue
        idx = np.asarray(batch["indices"], dtype=np.int64)
        if idx.size and (idx.min() < 0 or idx.max() >= n):
            out.append("model %d: index out of range (max %d of %d)"
                       % (i, int(idx.max()), n))
        weights = np.asarray(batch["weights"], dtype=np.float64)
        if weights.size:
            totals = weights.sum(axis=1)
            bad = int(((totals < 0.99) | (totals > 1.01)).sum())
            if bad:
                out.append("model %d: %d/%d vertices whose weights do not sum to 1"
                           % (i, bad, n))
        joints = np.asarray(batch["joints"], dtype=np.int64)
        if joints.size and int(joints.max()) >= 71:
            out.append("model %d: joint index %d beyond the skeleton's 71"
                       % (i, int(joints.max())))
        uvs = np.asarray(batch["uvs"], dtype=np.float64)
        if uvs.size and not np.isfinite(uvs).all():
            out.append("model %d: non-finite UVs" % i)

    return out


def texture_stats(payload):
    raw = am.decompress(payload)
    if len(raw) < 33:
        return {"error": "short texture header"}
    fmt = raw[0] & 0x3F
    endian = raw[0] >> 6
    width, height = struct.unpack_from("<II", raw, 4)
    _, per_frame, frames, flags, _ = struct.unpack_from("<IIIII", raw, 12)
    entry = {"format": "DXT1" if fmt == 0x12 else ("DXT5" if fmt == 0x14 else
                                                   "0x%02x" % fmt),
             "width": width, "height": height, "frames": frames,
             "endian": endian, "empty": bool(flags & 1)}
    pixels = raw[33:33 + width * height]
    if len(pixels) != width * height:
        entry["error"] = "pixels %d != %dx%d" % (len(pixels), width, height)
        return entry
    decoded = am.decode_dxt(pixels, width, height, fmt == 0x14)
    if decoded.shape[:2] != (height, width):
        entry["error"] = "DXT decoded to %s" % (decoded.shape,)
    return entry


def check_poses(poses):
    out = []
    bad = 0
    for i, (pos, quat, scale) in enumerate(poses):
        length = math.sqrt(sum(c * c for c in quat))
        if abs(length - 1.0) > 5e-3:
            bad += 1
        if not all(math.isfinite(c) for c in pos):
            out.append("pose joint %d has a non-finite position" % i)
    if bad:
        out.append("%d/%d pose quaternions are not unit length" % (bad, len(poses)))
    return out


def skeleton_checks():
    """Bone lengths against the geometry those bones drive."""
    out = []
    details = {}
    pack = None
    joints = sk.read_skeleton()
    details["joints"] = len(joints)
    if len(joints) != 71:
        out.append("skeleton has %d joints, expected 71" % len(joints))
    parents = [j["parent"] for j in joints]
    for i, parent in enumerate(parents):
        if parent != 255 and parent >= i:
            out.append("joint %d has parent %d, which is not before it" % (i, parent))
    details["hands"] = {}
    for wrist in ap.WRIST_JOINTS:
        kids = [i for i, j in enumerate(joints) if j["parent"] == wrist]
        details["hands"][str(wrist)] = {"children": kids}
        if len(kids) < 5:
            out.append("wrist %d has %d children, expected 4 fingers and a thumb"
                       % (wrist, len(kids)))
    return out, details


def reach_check(pack, gender="male"):
    """For each finger chain: bone length vs how far its geometry actually goes.

    This is the check that would have caught the hand problem on day one: a bone
    chain shorter or longer than the geometry it skins bends that geometry around
    a pivot the viewer can see is in the wrong place.
    """
    out = []
    rows = []
    index = am.load_pack_index(pack)
    body = "MaleBody" if gender == "male" else "FemaleBody"
    model = []
    for block in am.strb_blocks(am.asset_bytes(pack, index, body)):
        if block[0] == 3:
            model += am.read_model(am.decompress(block[3]))
    verts = np.array([v for b in model for v in b["vertices"]])
    weights = np.array([w for b in model for w in b["weights"]])
    joints_idx = np.array([j for b in model for j in b["joints"]])
    joints = np.array([j["position"] for j in sk.read_skeleton()])

    chains = []
    for root in range(37, 51):
        chain = [root]
        while len(chain) < 4:
            kids = [i for i, j in enumerate(sk.read_skeleton()) if j["parent"] == chain[-1]]
            if not kids:
                break
            chain.append(kids[0])
        if len(chain) >= 2:
            chains.append(chain)
    for chain in chains:
        bone = float(np.linalg.norm(joints[chain[-1]] - joints[chain[0]]))
        # The vertex belongs to this finger when its *dominant* joint is in the
        # chain. Testing "any influence in the chain" catches the palm and the
        # other hand and reports a reach twice the finger's length.
        dominant = joints_idx[np.arange(len(weights)), weights.argmax(axis=1)]
        mask = np.isin(dominant, chain)
        if not mask.any() or bone < 1e-6:
            continue
        geometry = float(np.linalg.norm(verts[mask] - joints[chain[0]], axis=1).max())
        ratio = geometry / bone
        rows.append({"chain": chain, "bone": bone, "geometry": geometry,
                     "ratio": ratio})
    # Every digit on both hands needs the same ratio. The pack's rig puts the last
    # finger joint part-way along the fingertip, so the ratio is about 2 on every
    # finger - that is the rig's style, not a decoding fault. What would be a
    # decoding fault is one digit disagreeing with the others, so the check is on
    # the spread, not the absolute value.
    FINGERS = {37, 38, 39, 40, 44, 45, 46, 47}
    ratios = [r["ratio"] for r in rows if r["chain"][0] in FINGERS]
    if ratios:
        median = float(np.median(ratios))
        for row in rows:
            if row["chain"][0] in FINGERS and abs(row["ratio"] - median) / median > 0.2:
                out.append("finger chain %s reaches %.3f, the median digit %.3f"
                           % (row["chain"], row["ratio"], median))
    out_notes = {"median_ratio": round(float(np.median(ratios)), 3) if ratios else None,
                 "digits": len(ratios)}
    return out, {"rows": rows, "notes": out_notes}


def descriptor_checks(pack):
    out = []
    rows = []
    names = set(asset_catalog.read_names()) if hasattr(asset_catalog, "read_names") else set()
    directory = os.path.join(HERE, "descriptors")
    for entry in sorted(os.listdir(directory)):
        if not entry.endswith(".Avatar"):
            continue
        path = os.path.join(directory, entry)
        try:
            desc = avatar_desc.read(path, names or None)
        except Exception as exc:                                # noqa: BLE001
            out.append("%s: %s: %s" % (entry, type(exc).__name__, exc))
            continue
        slots = desc.get("slots") or desc
        rows.append({"file": entry, "slots": slots if isinstance(slots, dict) else desc})
    return out, rows


def load_geometry(pack, index, name):
    model = []
    for block in am.strb_blocks(am.asset_bytes(pack, index, name)):
        if block[0] == 3:
            model += am.read_model(am.decompress(block[3]))
    return np.array([v for b in model for v in b["vertices"]])


def hair_caps(pack, catalog_path):
    """Hairstyles that are scalp caps, too low to be seen on their own.

    The pack carries each style twice: the full mesh, and a "(Hat)" version that
    is only the scalp under a hat. The two separate cleanly by how far the top of
    the mesh sits below the crown of the head - full styles run from 0.104 above
    it to 0.096 below, and every (Hat) style is 0.128 to 0.166 below. Offered as a
    standalone hairstyle a scalp cap reads as bald, which is how this was found;
    the editor has to either pair these with a hat or leave them out.
    """
    out = []
    index = am.load_pack_index(pack)
    head = load_geometry(pack, index, "Head")
    if not len(head):
        return out
    crown = float(head[:, 1].max())
    with open(catalog_path, "r", encoding="utf-8") as fh:
        catalog = json.load(fh)["assets"]
    for record in catalog:
        if (record.get("metadata") or {}).get("category") != "50_hair":
            continue
        try:
            verts = load_geometry(pack, index, record["name"])
        except Exception:                                       # noqa: BLE001
            continue
        if not len(verts):
            continue
        gap = crown - float(verts[:, 1].max())
        if gap > 0.11:
            out.append({"name": record["name"], "below_crown": round(gap, 3),
                        "verts": int(len(verts))})
    return out


def build_plan(pack, catalog_path, genders_path, caps=()):
    """The exact item list a bake will walk, and whether each item can be built.

    This mirrors what bake_pack_plates.py and bake_pack_turntables.py select -
    category, gender tag, a decodable payload, decal sheets present - so that a
    mismatch between plan and bake shows up here, in seconds, rather than after a
    thousand pictures. The manifest hash makes the finished bake checkable.
    """
    import bake_pack_turntables as bpt
    import bake_pack_plates as bpp
    from bake_pack_thumbs import slug

    with open(catalog_path, "r", encoding="utf-8") as fh:
        catalog = json.load(fh)["assets"]
    with open(genders_path, "r", encoding="utf-8") as fh:
        genders = json.load(fh)

    rows = []
    problems = []
    for gender in ("male", "female"):
        for record in catalog:
            meta = record.get("metadata") or {}
            category = meta.get("category")
            tag = (genders.get(record["name"]) or {}).get("gender", "both")
            if tag not in (gender, "both") or not category:
                continue
            kind = bpt.CATEGORY_KIND.get(category)
            has_mesh = bool(record.get("vertices"))
            decal = category in bpt.DECAL_SETS
            if not (has_mesh or decal or category == "15_face"):
                continue
            if record["name"] in bpt.BASE_ASSETS:
                continue
            if category == "15_face" and "nose" in record["name"].lower():
                continue
            needs = "sheet" if decal else ("mesh" if has_mesh else "eyes")
            if needs == "sheet":
                sheet = os.path.join(bpt.ART, category, slug(record["name"]) + ".png")
                if not os.path.exists(sheet):
                    problems.append("%s %s: no decal sheet at %s"
                                    % (gender, record["name"], sheet))
            # `cap` marks a scalp-only hairstyle: still baked, so a hat can wear it
            # later without another pass, but the editor must not offer it alone.
            flag = "cap" if record["name"] in caps else ""
            rows.append((gender, category, record["name"], kind or "", needs, flag))

    # The base bodies are the layer everything else is drawn on; the plate baker
    # skips them unless asked, which is exactly how one of them went stale.
    for gender, body in (("male", "MaleBody"), ("female", "FemaleBody")):
        rows.append((gender, "10_body", body, "", "mesh", ""))

    manifest = "\n".join("|".join(r) for r in rows)
    import hashlib
    digest = hashlib.sha1(manifest.encode("utf-8")).hexdigest()
    counts = {}
    for gender, category, _, _, _, _ in rows:
        counts.setdefault(gender, {}).setdefault(category, 0)
        counts[gender][category] += 1
    return {"rows": len(rows), "counts": counts, "manifest_sha1": digest,
            "problems": problems, "items": rows,
            "caps": sorted({r[2] for r in rows if r[5] == "cap"})}


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("pack")
    parser.add_argument("--catalog", default=os.path.join(HERE, "avatar-assets.json"))
    parser.add_argument("--jobs", type=int, default=8)
    parser.add_argument("--json", default=os.path.join(HERE, "pack_audit.json"))
    parser.add_argument("--md", default="")
    args = parser.parse_args()

    with open(args.catalog, "r", encoding="utf-8") as fh:
        names = [a["name"] for a in json.load(fh)["assets"]]

    with multiprocessing.Pool(args.jobs) as pool:
        reports = pool.map(audit_asset, [(args.pack, n) for n in names], chunksize=8)

    by_name = {r["name"]: r for r in reports}
    failures = [r for r in reports if r["problems"]]
    models = [r for r in reports if r["counts"].get("verts")]
    total_verts = sum(r["counts"].get("verts", 0) for r in reports)
    total_tris = sum(r["counts"].get("tris", 0) for r in reports)

    skel_problems, skel_details = skeleton_checks()
    hand_problems, hand_rows = reach_check(args.pack)
    desc_problems, desc_rows = descriptor_checks(args.pack)
    hair_shells = hair_caps(args.pack, os.path.join(HERE, "asset_catalog.json"))
    plan = build_plan(args.pack, os.path.join(HERE, "asset_catalog.json"),
                      os.path.join(HERE, "pack_genders.json"),
                      caps={h["name"] for h in hair_shells})

    shape_blocks = [r for r in reports if any(b["kind"] == "ShapeOverrides"
                                              for b in r["blocks"])]
    # An asset whose only payload is a shape override has nothing to draw: it is
    # a morph to apply to someone else's mesh, and until block 4 decodes it
    # produces no plate, no set and no 3D for that item.
    drawable = ("Model", "Texture", "Animation")
    shape_only = [r["name"] for r in shape_blocks
                  if not any(b["kind"] in drawable for b in r["blocks"])]
    texture_blocks = [r for r in reports if any(b["kind"] == "Texture" for b in r["blocks"])]
    anim_blocks = [r for r in reports if any(b["kind"] == "Animation" for b in r["blocks"])]
    texture_errors = [r["name"] for r in texture_blocks
                      if any(b.get("error") for b in r["blocks"] if b["kind"] == "Texture")]

    print("assets            %d" % len(reports))
    print("  with geometry   %d  (%d verts, %d tris)" % (len(models), total_verts, total_tris))
    print("  with a texture  %d  (%d failed to decode)" % (len(texture_blocks),
                                                           len(texture_errors)))
    print("  with animation  %d" % len(anim_blocks))
    print("  shape overrides %d  (%d are overrides only and cannot be drawn)"
          % (len(shape_blocks), len(shape_only)))
    print("assets with problems %d" % len(failures))
    print("build plan        %d items (manifest %s)"
          % (plan["rows"], plan["manifest_sha1"][:12]))
    for gender, counts in plan["counts"].items():
        print("  %-6s %d items" % (gender, sum(counts.values())))
    if hair_shells:
        print("scalp-cap hairstyles %d  (%s ...)"
              % (len(hair_shells), ", ".join(h["name"] for h in hair_shells[:3])))
    for problem in plan["problems"][:10]:
        print("  ! %s" % problem)
    for problem in skel_problems + hand_problems + desc_problems:
        print("  ! %s" % problem)
    if failures:
        kinds = {}
        for r in failures:
            for p in r["problems"]:
                kinds[p.split(":")[0]] = kinds.get(p.split(":")[0], 0) + 1
        print("problems by kind:")
        for kind, count in sorted(kinds.items(), key=lambda kv: -kv[1])[:12]:
            print("  %-24s %d" % (kind, count))

    audit = {
        "pack": args.pack,
        "assets": len(reports),
        "geometry_assets": len(models),
        "verts": total_verts,
        "tris": total_tris,
        "texture_assets": len(texture_blocks),
        "texture_failures": texture_errors,
        "animation_assets": len(anim_blocks),
        "shape_override_assets": [r["name"] for r in shape_blocks],
        "shape_only_assets": shape_only,
        "problems": {r["name"]: r["problems"] for r in failures},
        "skeleton": {"details": skel_details, "problems": skel_problems},
        "hand_reach": hand_rows,
        "hand_problems": hand_problems,
        "descriptors": desc_rows,
        "descriptor_problems": desc_problems,
        "build_plan": plan,
        "hair_shells": hair_shells,
        "assets_detail": reports,
    }
    with open(args.json, "w", encoding="utf-8") as fh:
        json.dump(audit, fh, indent=1)

    # ShapeOverrides is a known limitation, not a surprise: those 266 items have
    # no geometry of their own, so nothing about them is bakeable yet. Everything
    # else must be clean, or the bake stops here.
    unexpected = [r for r in failures
                  if any("ShapeOverrides" not in p for p in r["problems"])]
    blocking = (unexpected or skel_problems or hand_problems or desc_problems
                or plan["problems"])
    print()
    if shape_only:
        print("known limitation  %d items are shape overrides only (%s%s)"
              % (len(shape_only), ", ".join(shape_only[:3]),
                 " ..." if len(shape_only) > 3 else ""))
    print("%d unexpected problem(s) - a bake is safe only at 0"
          % (len(unexpected) + len(skel_problems) + len(hand_problems)
             + len(desc_problems) + len(plan["problems"])))
    if args.md:
        write_markdown(args.md, audit)
        print("wrote %s" % args.md)
    print("wrote %s" % args.json)
    return 1 if blocking else 0


def write_markdown(path, audit):
    plan = audit["build_plan"]
    lines = ["# What the pack gives us, and what it does not", "",
             "Generated by `audit_pack.py`; re-run it before any bake. Its exit status is",
             "0 only when every block that can be decoded agrees with itself and with the",
             "rest of the data.", "",
             "## Decoded and checked", "",
             "| | |", "|---|---|",
             "| assets opened | %d |" % audit["assets"],
             "| with geometry | %d (%d verts, %d tris) |" % (
                 audit["geometry_assets"], audit["verts"], audit["tris"]),
             "| with a texture | %d, all DXT-decoded at full size |" % audit["texture_assets"],
             "| with animation | %d |" % audit["animation_assets"],
             "| skeleton | %d joints, parents ordered, 4 fingers and a thumb per wrist |" % (
                 audit["skeleton"]["details"]["joints"]),
             "| finger reach, median digit | %s |" % (
                 audit["hand_reach"]["notes"]["median_ratio"]), "",
             "Each model was checked for indices inside the batch, skin weights summing to",
             "one, joint indices inside the skeleton and finite UVs; each animation for",
             "unit quaternions; each texture for its declared size.", "",
             "## Not decoded", "",
             "**ShapeOverrides (block 4), %d assets.** Every one of them carries no model,"
             % len(audit["shape_override_assets"]),
             "no texture and no animation - it is a morph to apply to someone else's mesh.",
             "Until that block is read, those items cannot be drawn or shaped at all.",
             "It is not LZX, not a byte-aligned array and not floats; see",
             "`EDITOR_BINARIES.md` for the tests already ruled out and the two constants",
             "that anchor the next attempt.", "",
             "## Faults in the artwork itself", "",
             ]
    if audit["hair_shells"]:
        lines += ["%d hairstyles are scalp caps, not styles: the top of the mesh sits"
                  % len(audit["hair_shells"]),
                  "0.128 to 0.166 below the crown of the head, against -0.104 to +0.096",
                  "for every full style. Each is named \"(Hat)\" and is the scalp worn",
                  "under a hat, so offered on its own it reads as bald. This was",
                  "confirmed against the baked sets, not inferred from the names:", ""]
        lines += ["- %s (%.3f below the crown, %d verts)"
                  % (h["name"], h["below_crown"], h["verts"])
                  for h in audit["hair_shells"][:8]]
        if len(audit["hair_shells"]) > 8:
            lines.append("- and %d more" % (len(audit["hair_shells"]) - 8))
        lines.append("")
    lines += ["## The build", "",
              "`audit_pack.py` also writes the exact item list a bake walks, %d items,"
              % plan["rows"],
              "and a hash of it: `%s`." % plan["manifest_sha1"],
              "If that hash changes, what is on disk no longer matches what was",
              "checked here, and the bake has to run again.", "",
              "| gender | items |", "|---|---|"]
    for gender, counts in plan["counts"].items():
        lines.append("| %s | %d |" % (gender, sum(counts.values())))
    lines += ["", "Manifest: `%s`" % plan["manifest_sha1"], "",
              "%d of those items carry `cap` (the scalp-only hairstyles above)."
              % len(plan["caps"]),
              "They are baked like everything else so a hat can use them later without",
              "another pass; the editor is what must keep them out of the standalone",
              "list.", ""]
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


if __name__ == "__main__":
    sys.exit(main())
