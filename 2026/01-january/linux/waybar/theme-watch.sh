#!/usr/bin/env bash

THEME_LINK="$HOME/.config/omarchy/current/theme"
SWITCH="$HOME/.config/waybar/switch.sh"

# Initialize to current theme (prevents first duplicate reload)
if [ -L "$THEME_LINK" ]; then
  last="$(basename "$(readlink "$THEME_LINK")")"
else
  last=""
fi

while true; do
  if [ -L "$THEME_LINK" ]; then
    current="$(basename "$(readlink "$THEME_LINK")")"
    if [ "$current" != "$last" ]; then
      "$SWITCH" "$current"
      last="$current"
    fi
  fi
  sleep 1
done

