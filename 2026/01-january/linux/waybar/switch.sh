#!/usr/bin/env bash

BASE="$HOME/.config/waybar"
VARIANTS="$BASE/variants"

switch_variant() {
  local VARIANT="$1"
  local TARGET="$VARIANTS/$VARIANT"

  [ ! -d "$TARGET" ] && exit 0

  ln -sfn "$TARGET/config.jsonc" "$BASE/active/config.jsonc"
  ln -sfn "$TARGET/style.css" "$BASE/active/style.css"
  ln -sfn "$TARGET/modules" "$BASE/modules"

  pkill waybar
  sleep 0.15
  waybar & disown
}

# fzf picker if no argument
if [ -z "$1" ]; then
  VARIANT=$(ls "$VARIANTS" | fzf --prompt="Waybar variant > ")
else
  VARIANT="$1"
fi
[ -z "$VARIANT" ] && exit 0
switch_variant "$VARIANT"

notify-send "Waybar" "Switched to $VARIANT"

