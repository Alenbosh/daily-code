#!/usr/bin/env bash



SINK=$(pactl list short sinks | sed -n '1s/^\([0-9]\+\).*/\1/p')

ACTIVE=$(pactl list sinks | awk '/Active Port:/ {print $3; exit}')

if [ "$ACTIVE" = "analog-output-speaker" ]; then
  pactl set-sink-port "$SINK" analog-output-headphones
  notify-send "Audio → Headphones"
else
  pactl set-sink-port "$SINK" analog-output-speaker
  notify-send "Audio → Speakers"
fi



# SINK=50
#
# ACTIVE=$(pactl list sinks | awk '/Active Port:/ {print $3; exit}')
#
# if [ "$ACTIVE" = "analog-output-speaker" ]; then
#   pactl set-sink-port $SINK analog-output-headphones
#   notify-send "Audio → Headphones"
# else
#   pactl set-sink-port $SINK analog-output-speaker
#   notify-send "Audio → Speakers"
# fi
