#!/bin/bash
# Rebuild every baked picture from the pack: plates, turntables, animated set.
#
# Run from anywhere; it cds to its own directory. Each stage fans out over eight
# processes because a turntable set is about nine seconds and there are close to
# a thousand of them. A stage is only as parallel as `nproc`; on fewer cores the
# fan-out still works, it just takes longer.
#
#     ./rebake_everything.sh              # everything
#     ./rebake_everything.sh plates       # 2D plates only
#     ./rebake_everything.sh turntables   # 3D sets only
#     ./rebake_everything.sh animated     # the animated 3D set
set -u
cd "$(dirname "$0")"
export PYTHONPATH="$PWD:${PYTHONPATH:-}"

PACK="../../../src_archive/XBOX HUB/resources/editors/metro2010/assets/AvatarAssetPack.toc"
# The gate. A bake is the expensive half of this project and the only thing it can
# discover at the end is that something was missing; audit_pack.py opens every
# asset and checks it in seconds, so a bake never starts on data that does not
# agree with itself. Known limitations are reported and do not stop it.
if [ "${SKIP_AUDIT:-0}" != "1" ]; then
    python3 audit_pack.py "$PACK" --json pack_audit.json || {
        echo "audit failed: fix the problems above before baking" >&2
        exit 1
    }
fi
CLIPS="../../../src_archive/XBOX HUB/resources/editors/metro2010/assets/Cheer.AvatarAnimation"
CATEGORIES="10_body,15_face,16_face-paint,20_pants,30_shoes,40_shirt,45_facial-hair,46_gloves,50_hair,60_hat,70_glasses,75_earrings,76_rings,77_wristwear,80_dress,81_formal,82_coat,83_dress-formal"
CLIP_ASSET="Animation Male Idle Shifts Weight"
JOBS="${JOBS:-8}"
STAGE="${1:-all}"

# The eyes, face paint and facial hair are UV sheets painted on the head rather
# than body plates, so bake_pack_plates.py skips them (they have no geometry) and
# bake_pack_face.py is the only thing that draws them. It was missing from this
# script: a rebuild from scratch left 88 plates absent and said nothing about it.
# One run covers both bodies - they share the Head asset, and the editor falls
# back to the male sheet for the female avatar (AvatarEditor.qml, hasPlates).
faces() {
  python3 bake_pack_face.py "$PACK" "$CLIPS" descriptors/Avatar6400.Avatar \
    --categories 15_face,16_face-paint,45_facial-hair \
    --outdir ../pack_plates --force --clip-asset "$CLIP_ASSET"
  echo "face plates done"
}

plates() {
  for gender in male female; do
    if [ "$gender" = female ]; then
      flags="--gender female"; desc=descriptors/Avatar6404.Avatar; out=../pack_plates_female
    else
      flags=""; desc=descriptors/Avatar6400.Avatar; out=../pack_plates
    fi
    for i in $(seq 0 $((JOBS - 1))); do
      python3 bake_pack_plates.py "$PACK" "$CLIPS" "$desc" --categories "$CATEGORIES" $flags \
        --outdir "$out" --start $((i * 50)) --limit 50 --force --clip-asset "$CLIP_ASSET" &
    done
    wait
    # The body plate is the base layer every garment is drawn over, and its hands
    # are the 2D avatar's hands. Without --include-base the body is skipped and
    # that layer keeps whatever pose it was first baked with, which is exactly
    # what happened: the plates were rebaked around a body plate from an older
    # pose, and nothing in a directory listing showed it.
    python3 bake_pack_plates.py "$PACK" "$CLIPS" "$desc" --categories 10_body --include-base $flags \
      --outdir "$out" --force --clip-asset "$CLIP_ASSET"
    echo "plates $gender done"
  done
  faces
}

turntables() {
  for gender in male female; do
    if [ "$gender" = female ]; then
      flags="--gender female"; desc=descriptors/Avatar6404.Avatar; out=../assets/3d/turntable_female
    else
      flags=""; desc=descriptors/Avatar6400.Avatar; out=../assets/3d/turntable
    fi
    for i in $(seq 0 $((JOBS - 1))); do
      python3 bake_pack_turntables.py "$PACK" "$CLIPS" "$desc" --categories "$CATEGORIES" $flags \
        --outdir "$out" --start $((i * 60)) --limit 60 --force --clip-asset "$CLIP_ASSET" &
    done
    wait
    echo "turntables $gender done"
  done
  # Anything a timeout left behind wears the previous pose and looks identical in
  # a listing, so it is repaired by timestamp rather than by eye. The age has to
  # be longer than this stage takes: at 60 seconds every set baked above counts as
  # stale and the whole sweep runs a second time.
  python3 rebake_stale.py --age 3600 --workers "$JOBS"
}

animated() {
  clip=$(python3 -c "import pack_clip; print(pack_clip.resolve('$PACK', '$CLIPS', '$CLIP_ASSET', '/tmp'))")
  python3 bake_animated.py "$PACK" "$clip" descriptors/Avatar6400.Avatar ../assets/3d/animated \
    --poses=10 --yaws=12
  python3 bake_outfits.py "$PACK" "$clip" ../assets/3d
}

case "$STAGE" in
  plates) plates ;;
  turntables) turntables ;;
  animated) animated ;;
  # Everything the plan asks for, or a non-zero exit: a bake that quietly left an
  # item out is the one failure a directory listing never shows.
  all) plates; turntables; animated; python3 verify_art.py ;;
  *) echo "usage: $0 [all|plates|turntables|animated]" >&2; exit 2 ;;
esac
echo "rebake complete: $STAGE"
