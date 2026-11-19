# The editor's categories, recovered from the editor itself

The category labels are not in the closet assets, not in the index, not in the
port's DLL and not in the dashboard - every one of those was checked and ruled
out. They **are** in `gamedir/avatareditor.xex`, in its own XUI scene data, as
UTF-16 strings. That file is the retail editor (MD5
`39432fadd9a1866d94a859974ae8e616`), so these are the real names, not invented
ones.

`editor_categories.json` is the machine-readable copy: one row per category
button with its label, the icon the scene pairs with it, the byte offset in the
XEX where the button name sits, and the theme folder that already implements it
where one does.

## The tree

From the button names, which encode their own nesting
(`ClosetBodyAccessoriesGlovesButton` is a child of `ClosetBodyAccessoriesButton`):

| label | button | icon | theme folder |
| --- | --- | --- | --- |
| Tops | `ClosetTopsButton` | `tops_unselected.png` | `40_shirt` |
| Bottoms | `ClosetBottomsButton` | `bottoms_unselected.png` | `20_pants` |
| Shoes | `ClosetShoesButton` | `shoes_unselected.png` | `30_shoes` |
| Headwear | `ClosetHeadgearButton` | `hat_unselected.png` | `60_hat` |
| Glasses | `ClosetHeadAccessoriesGlassesButton` | `glasses_unselected.png` | `70_glasses` |
| Hairstyles | `HairCreateButton` | `hair_unselected.png` | `50_hair` |
| Facial Hair | `FeaturesBeardCreateButton` | `facial_hair_male_unselected.png` | `45_facial-hair` |
| Skin Color and Body | `BodyCreateButton` | `body_unselected.png` | `10_body` |

Those eight are the whole of what the theme implements today, and each one has
a real counterpart in the editor.

## What the editor has that the theme does not

- **Body Accessories** (`ClosetBodyAccessoriesButton`, `body_access_unselected.png`)
  - Gloves (`ClosetBodyAccessoriesGlovesButton`, `gloves_unselected.png`)
  - Wristwear (`ClosetBodyAccessoriesWristButton`, `watch_unselected.png`)
  - Rings (`ClosetBodyAccessoriesRingButton`, `ring_unselected.png`)
- **Head Accessories** (`ClosetHeadAccessoriesButton`, `head_access_unselected.png`)
  - Earrings (`ClosetHeadAccessoriesEarringButton`, `earring_unselected.png`)
  - Glasses - the theme's `70_glasses` is this child
- **Makeup** (`ClosetMakeupButton`, `makeup_unselected.png`)
  - Eye Shadow (`ClosetMakeupEyeshadowButton`, `eyeshadow_unselected.png`)
  - Lip (`ClosetMakeupLipstickButton`, `lipstick_unselected.png`)
- **Carryables** (`ClosetCarryablesButton`, `dummy_button_carryables.png`)
- **Accessories** (`ClosetAccessoriesButton`, `dummy_button_accessories.png`)
- **My Outfits** (`ClosetLoadoutfitButton`, `dummy_button_loadoutfits.png`)
- **Costumes**, split by body type: `ClosetCostumesMaleButton`
  (`dummy_button_formalcostume.png`) and `ClosetCostumesFemaleButton`
- **Features** row: Skin Color (`FeaturesSkinCreateButton`, `facial_unselected.png`),
  Eyebrows, Eyes, Nose, Mouth, Ears, Head Shape
  (`faceshape_unselected.png`), Facial Features - each with its own
  `*_unselected.png`

The body-shape options are in the same scene and also recorded:
`OptionBodyNormalButton`, `OptionBodyTallButton`, `OptionBodySmallButton`,
`OptionBodyFatButton`, `OptionBodyThinButton` and the tall/small fat and thin
combinations, each paired with a `bodyshape_*` icon.

## How sure this is

- The button names and labels are read verbatim from the file at the recorded
  offsets, and each icon is only claimed where that exact png name exists in the
  file as a UTF-16 string (30 of the 42 buttons have one).
- The nesting is inferred from the button names, not from a decoded scene graph.
- The label-to-button pairing is by the string table's own ordering around each
  button plus the icon family; it is not read out of a parsed XUI structure.
- `ClosetCostumesFemaleButton` and the bare `ClosetButton` have no icon
  recorded, because no png with a matching name exists near them.

## Rail and 3D stage: three defects found by driving the component, 2026-11-19

The render sweep only counts QML warnings, so all three of these passed it:

**1. Empty rail pills.** The rail was built from every `PackIndex` category the
gender filter left, empties included. The pack marks every dress female and the
coats male, so a male avatar got `80_dress` and `83_dress-formal` pills that opened
onto nothing, and a female avatar got an empty `82_coat`. Measured, per gender,
counting the files that survive the `packGenders` filter:

| gender | categories | empty |
| --- | ---: | --- |
| male | 24 before / **22 now** | `80_dress`, `83_dress-formal` |
| female | 24 before / **23 now** | `82_coat` |

`rebuildCategories` now drops a category with no wearable file, and restores the
selected pill **by id** rather than by index, because the count differs per gender -
the old index would have pointed at the category next door.

**2. The 3D stage went blank and stayed blank.** Chosen an item with no baked set,
the stage assigned `variant = defaultVariant` from the fake-Image probe's
`onStatusChanged`. That is an assignment to a property the parent binds
(`variant: root.stageVariant`), so it killed the binding: every later item was
ignored. Measured before the fix, picking `20_pants/skinny-fit-jeans` (no baked set)
and then `20_pants/worn-jeans` (a real six-frame set):

```
before: frames=0  available=false  variant=turntable            after both picks
after:  frames=20 frame=10 available=true  variant=turntable    (stock fallback)
        frames=6  frame=0  available=true  variant=turntable/worn-jeans
```

The fallback is a `fellBack` flag now (`activeVariant = fellBack ? defaultVariant :
variant`), cleared when `variant` changes, and it is applied through `Qt.callLater`:
assigning the folder from inside the probe's own status handler set that probe's
`source` while Qt was delivering the change, and the new load was dropped.

**3. The 18-frame sets opened on the avatar's back.** `restFrame` was
`frameCount === 20 ? 10 : 0`, which was right for the six-frame item sets and the
twenty-frame outfits but wrong for `turntable/hair_bun_red` (18 frames). Read frame
by frame:

| set | frames | front frame |
| --- | ---: | ---: |
| `turntable/jacket-with-sweater` | 6 | **00** |
| `turntable/hair_long_blond` | 20 | **10** (frame 00 is the back) |
| `turntable/hair_bun_red` | 18 | **09** (frame 00 is the back) |

`restFrame` is now `frameCount > 6 ? frameCount / 2 : 0`, i.e. by bake shape: item
sets start at the front, whole-body turntables start at the back.

`research/rail_check.py` asserts all three, and `verify_qml_assets.py` checks that
every name in the six generated indexes (`PackIndex`, `PackPlates`,
`PackPlatesFemale`, `PackMasks`, `AssetIndex` - 2,242 entries - plus `StageIndex`,
983 sets / 6,290 frames) has a file behind it.

**4. A drawer switch asked the 2D stage for files that cannot exist.**
`rebuildCategories` assigned `categories` first and fixed the player's picks
(`pruneState`, `seedOutfit`) afterwards, but assigning `categories` fires
`onCategoriesChanged: rebuildLayers()` straight away. For that one rebuild the 2D
stack held the previous mode's picks against the new mode's folders: switching to
the pack asked for `assets/20_pants/male-flower-print-flares.png` - the drawn
folder with the pack's file name - and every seeded slot logged a failed load.
`pruneState(list)` and `seedOutfit(list)` now take the list being installed and run
**before** it replaces `categories`, so the rebuild only ever sees picks that exist
where they will be drawn from.

Measured with `research/rail_check.py`, which now counts the editor's failed loads
across a whole check cycle: **43 before, 1 after**. The one left is the 3D stage
probing a set the index does not name (`turntable/skinny-fit-jeans/frame_00.png`,
an item with no bake - how the stage falls back, see `assets/3d/README.md`).

## Art coverage: every offered item resolves

`research/run_art_sweep.py` drives every item the strip offers through the real
editor - both bodies, both drawers - and checks the two things the indexes cannot:
that every layer the 2D stage resolves exists on disk (plate, tint mask, skin mask,
iris, mouth mask), and that the 3D stage has a set for the pick's own variant,
before its fallback to the stock turntable.

```
item checks          1,380    (1,204 pack-mode, 176 drawn-mode)
missing art          0
pack items with no 3D set   0   (196 before; see assets/3d/README.md)
drawn items with no 3D set  72  port fallback art, not retail content
```

The 1,179 sets behind those checks are also read frame by frame -
`research/run_3d_sanity.py`, 7,135 frames: no blank bake, no set whose turn never
moved, no front frame outside its set, no mixed frame sizes. See
`assets/3d/README.md`, which also records the turn rate the stage now keeps (one
turn per 1.8 s whatever the set's frame count).

The 196 pack items the sweep found without a set were fixed by rebaking them: the
eye-shadow pass had been looking for its sheets in `pack_art/50_hair` rather than
`pack_art/17_eye-shadow`, and the baker's `--gender` never chose the output tree,
so a female run overwrote male sets. Both are fixed in
`bake_pack_turntables.py`, the 98 polluted sets were rebaked, and brows, eye
shadows and mouths now have 27/45/26 sets in each tree.

**5. Four categories painted their strip cards over the avatar.** In pack mode a
layer is supposed to be a plate or a tint mask, but `rebuildLayers` fell back to
`c.path` when neither existed - and `c.path` in pack mode is `pack_art/<category>`,
which holds the strip's own **160x108 cards**, not stage art. So picking a mouth
painted `pack_art/18_mouth/curvy-mouth.png` across the avatar's chest, untinted;
the same for `71_nose`, `72_ears` and `73_head-shape`, whose art is framed on the
item (a nose fills its whole card) and which the pack gives no plates at all.

Measured: `run_art_sweep.py` grew a rule - *no stage layer may point into
`pack_art/`* - and immediately reported it for all four categories, once per pick,
1,336 of 1,380 checks while a shape was selected. In pack mode the stack now draws
only a mask (tinted) or a plate, and skips the category when neither exists; the
mouth is still drawn, as the stock smirk mask tinted with the lips colour, and the
shapes are still shown in 3D, where a geometry morph can be baked. Re-measured:
**0 strip-art layers**, `missing art 0`.

## Tinted layers: they were not drawing at all (fixed 2026-11-19)

The offscreen harness cannot paint a `ShaderEffect`, which hid a real defect rather
than merely limiting the screenshots. On a GL surface (Xvfb + Mesa `swrast`,
`QT_QPA_PLATFORM=xcb`) `TintedMask` still drew nothing, and the message explained why:
**Qt 6 refuses inline GLSL** and reads `fragmentShader` as a path -
`Failed to deserialize QShader ... shaders must be preprocessed using the Qt Shader
Tools infrastructure`. So no brow, eye-shadow, iris, lip or skin tint has ever been on
screen in any Qt 6 run of this editor.

Two more defects were behind that one. The std140 block must begin with `qt_Matrix`
and `qt_Opacity` (offsets 0 and 64) or custom members arrive as zero - declaring
`colour` first rendered black silently. And Qt Quick supplies sampler textures
premultiplied, so multiplying by coverage again squared alpha: a 177/255 eye shadow
rendered at 48 % of the plate instead of 69 %.

Now: `shaders/tintedmask.frag` -> `shaders/tintedmask.frag.qsb` (built by
`avatar_tools/make_shader.py`), `research/run_tint_check.py` renders four mask
families at two palette colours each and compares every pixel with the shader
arithmetic - **21 checks, 0 failures, worst channel off by 1** (table in
`COLOURS.md`). The editor itself renders 8/8 screens on that surface with 0 warnings,
and the 2D avatar now shows tinted brows, iris and lips.

`QSG_RENDER_LOOP=basic` is needed under llvmpipe: the threaded loop deadlocks the first
frame as soon as a `ShaderEffectSource` takes a snapshot. That is a property of the
software driver, not of the editor. The offscreen harnesses (`run_colour_check.py`,
`run_all_screens.py`, `rail_check.py`) still pass unchanged - they check wiring, not
pixels.
