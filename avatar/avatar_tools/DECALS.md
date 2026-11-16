# Face decals: what is established, what is not

The head's eyes, brows and mouth are done: `bake_avatar.py` bundles the three tint
sheets and the renderer composites them per pixel, so a baked face has real eyes
and a mouth. The **painted decals** — the `45_facial-hair` beards and
`16_face-paint` sheets — are still unresolved, and nothing in the project should
pretend otherwise.

## Established

* The head mesh carries **six UV sets** (`uvs[vertex][0..5]`).
* Sets **2, 3 and 4** are the brow, eye and mouth tint sheets (`FACE_SETS` in
  `bake_avatar.py`).
* The decal sheets are RGBA art at the pack's own sizes: facial hair is 128×64,
  face paint 128×128. They are not tint masks — their colour is the art.
* Set 0 is the skin layout (it covers a single corner of the sheet, u 0.50–0.99).
* Set 1 and set 5 each span nearly the whole sheet (u 0.01–0.99, v 0.01–0.99),
  which is the shape a full-face decal sheet would need.

## Not established

**Which UV set the beard and face-paint sheets are painted through.** Two attempts
failed to decide it:

* `probe_decal_uv.py` reports what fraction of a decal's painted pixels fall
  inside each set's covered region. It does not discriminate: for `calm-eyes.png`
  — a sheet whose set is *known* to be 3 — sets 2 and 5 both score 100% and set 3
  scores 88.9%, so a high score proves nothing.
* `probe_decal_render.py` renders the head with the beard applied on each set in
  turn. Looking at all seven images, none puts the beard on a jaw: each set
  smears the art across the skull or the cheeks. There is no set that is
  obviously right, and choosing the least-wrong one would be inventing placement.

The `16_face-paint` sheets also render with **no alpha at all** (`camo-facepaint`
has zero texels below 0.5 alpha), so their shape has to come from something other
than transparency — possibly a second texture in the item, or a channel.

## Consequence

* No 3D set is baked for these categories, and the 2D strip must not draw them:
  `AvatarStage.qml` fits every layer to the whole 512×768 frame, so a 128×64
  sheet shown as a layer becomes a blurry decal over the entire body.
* What would settle it: the retail editor's own face art for a bearded avatar
  (which would show where the beard sits), or any dump naming the per-slot
  texture a facial-hair item binds.

## Re-running the probes

The committed catalogues now describe the pack that ships in `src_archive`, so
both probes run as they are:

```
python3 probe_decal_uv.py ../pack_art/45_facial-hair/beard.png
python3 probe_decal_render.py ../pack_art/45_facial-hair/beard.png /tmp/head.png
```

If a different pack revision ever needs testing, re-derive the catalogues from it
first - `toc_parse.py`, then `asset_catalog.py`, both pointed at that pack - rather
than editing offsets by hand.
