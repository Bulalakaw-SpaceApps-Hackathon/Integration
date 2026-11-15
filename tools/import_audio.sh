#!/bin/sh
# Builds assets/sfx from the team's Audio-Design pack (D8).
# Set 1 is the base; gaps are filled from "Set 1 - Unselected" (all Kenney CC0).
# Usage: sh tools/import_audio.sh <extracted Audio-Design-main dir> assets/sfx
set -e
SRC="$1"; OUT="$2"; S1="$SRC/Set 1"; UN="$SRC/Set 1 - Unselected"
for f in music_hub sfx_camera sfx_click sfx_dose_tick sfx_evacuate sfx_flare_alarm sfx_msg_sent sfx_recall \
         sfx_star sfx_static_loop sfx_step_1 sfx_sunrise sfx_thump sfx_upgrade sfx_wind_loop sfx_door_open_close_source; do
  cp "$S1/$f.ogg" "$OUT/$f.ogg"
done
FF="ffmpeg -hide_banner -loglevel error -y"
# airlock door source (Freesound 607265): the opening hiss, then the closing clunk
$FF -i "$S1/sfx_door_open_close_source.ogg" -af "atrim=0:2.2,asetpts=PTS-STARTPTS,volume=10dB,afade=t=out:st=1.9:d=0.3" -c:a libvorbis -q:a 4 "$OUT/sfx_door_open.ogg"
$FF -i "$S1/sfx_door_open_close_source.ogg" -af "atrim=5.75:8.6,asetpts=PTS-STARTPTS,afade=t=in:d=0.05,afade=t=out:st=2.5:d=0.35" -c:a libvorbis -q:a 4 "$OUT/sfx_door_close.ogg"
# more footsteps, message received, materials jingle
cp "$UN/footstep00.ogg" "$OUT/sfx_step_2.ogg"
cp "$UN/footstep02.ogg" "$OUT/sfx_step_3.ogg"
cp "$UN/confirmation_001.ogg" "$OUT/sfx_msg_received.ogg"
cp "$UN/powerUp2.ogg" "$OUT/sfx_materials.ogg"
# low battery: a power-up played backwards sounds like power running down
$FF -i "$UN/powerUp5.ogg" -af areverse -c:a libvorbis -q:a 4 "$OUT/sfx_low_battery.ogg"
echo done
