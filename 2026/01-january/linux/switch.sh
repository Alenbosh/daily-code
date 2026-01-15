#!/usr/bin/env bash

# Waybar variant switcher with walker --dmenu

BASE="$HOME/.config/waybar"
VARIANTS="$BASE/variants"

switch_variant() {
    local VARIANT="$1"
    local TARGET="$VARIANTS/$VARIANT"

    [ ! -d "$TARGET" ] && {
        notify-send "Waybar Error" "Variant '$VARIANT' not found!" -u critical
        exit 1
    }

    rm -f "$BASE/active/config.jsonc" "$BASE/active/style.css" 2>/dev/null
    rm -rf "$BASE/modules" 2>/dev/null

    ln -sfn "$TARGET/config.jsonc" "$BASE/active/config.jsonc" || exit 1
    ln -sfn "$TARGET/style.css" "$BASE/active/style.css" || exit 1

    mkdir -p "$BASE/modules"
    if [ -d "$TARGET/modules" ]; then
        cp -r "$TARGET/modules/." "$BASE/modules/" 2>/dev/null || true
    fi

    pkill -x waybar 2>/dev/null
    sleep 0.15

    waybar >"$BASE/waybar-last-run.log" 2>&1 &
    disown

    notify-send "Waybar" "Switched to <b>$VARIANT</b>" -i "waybar" -t 2500
}

# ──────────────────────────────────────────────────────────────────────────────

if [ -z "$1" ]; then
    # Clean walker dmenu mode — no extra flags needed
    VARIANT=$(find "$VARIANTS" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | walker --dmenu)
else
    VARIANT="$1"
fi

[ -z "$VARIANT" ] && exit 0

switch_variant "$VARIANT"
