# Kinect Fun Labs (`Kinect_Fun_Labs.zip`)

A 256 MB MediaFire archive, 276 entries, 292 MB uncompressed. It is a Unreal
Engine 3 build (Flint engine, Xenon cooked packages) of the Kinect Fun Labs apps:
Kinect Me (`kme_*`), Googly Eyes (`gbl_*`), MiniMe / MiniVs and friends.

## What is in it

| group | size | files | what |
| --- | --- | --- | --- |
| `app0/default.xex` | 32.5 MB | 1 | the executable |
| `app0/flintGame/CookedXenon` | 209.8 MB | 178 | UE3 packages, `CharTextures.tfc`, 24 `Coalesced_*.bin` localisation files, ogg/wav/bnk audio |
| `app0/Engine/Splash/Xbox360` | 18.4 MB | 8 | splash bitmaps |
| `app0/flintGame/FaceData` | 14.1 MB | 9 | Kinect face-tracking models (`AAMModelData_*.bin`, `NuiIdentityNN.bin.be`) |
| `app0/flintGame/FaceData/MorphData` | 2.5 MB | 26 | **OBJ head meshes**, the only directly readable geometry in the archive |

## The MorphData meshes (readable, and used)

26 files named `<feature>.obj_`, which are plain Wavefront OBJ written by
"3ds Max Wavefront OBJ Exporter v0.97b" in March 2011:

    base, chinHi, chinLo, chinNarrow, chinWide,
    eyesHi, eyesLo, eyesNarrow, eyesWide,
    noseHi, noseLo, noseNarrow, noseWide,      (each also with a Scalp copy)

Each mesh is 560 verts / 1062 tris, **Y-up as authored** (80 x 96 x 52 units,
symmetric to +-39.986), with `headFace` and scalp as separate objects.

So this is a base head plus one morph per facial feature, for each of two
values - the same idea as the pack's 453 blend-shape assets (`Large Chin`,
`Thin Chin`, `Wide Nose` ...), which is what makes the set useful as a reference.

## What it settles

`bake_turntable.py` was run on `base.obj_` + `baseScalp.obj_` (merged, 1226
verts, 2336 tris) and produced a correct 8-frame turntable: solid volume, correct
eye sockets, nose, mouth and ears, correct occlusion between face and scalp,
correct framing. Frames are in `research/shots/kfl/` (`raw-04.png` is the face).

That matters because it separates two things that were tangled:

* the **bake pipeline is correct** - OBJ read, Z-buffer, shading, orthographic
  fit and PNG output all behave on real geometry, so nothing in
  `bake_turntable.py` needs changing;
* the **NXE body mesh is the problem** - the same pipeline renders a head from a
  different art system perfectly while `MaleBody` comes out as flat sheets.

An earlier attempt converted the OBJ from Z-up and pitched the head onto its
back; the raw extents (80 wide, 96 tall, 52 deep) show the file is already Y-up
and must be baked as authored.

## What it does not give

There is no Xbox avatar body here. This is a different art system: a
photogrammetry-style Kinect Me head with morph targets, not the NXE avatar's
rigid-part body and clothing. The UE3 packages that would hold character meshes
are **compressed** - every `.xxx` is a multiple of 32 KiB and `strings` returns
no asset names in either ASCII or UTF-16 - so extracting a `SkeletalMesh` from
them needs a UE3 Xenon chunk decompressor first, and it is not known yet whether
one exists in this build.

Until such a mesh is extracted, this archive cannot calibrate the NXE width
anomaly: it has no body, and its head is not authored in the pack's coordinate
space.
