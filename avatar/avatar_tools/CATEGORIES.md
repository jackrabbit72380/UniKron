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
