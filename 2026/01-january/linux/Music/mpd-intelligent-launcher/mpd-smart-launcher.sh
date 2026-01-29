#!/bin/bash
# 🎵 MPD Smart Launcher — Surfaces least-played songs naturally
# Tracks play counts, shows least-played first, updates automatically

DB="$HOME/.local/share/mpd_playcount.db"
SKIP_DB="$HOME/.local/share/mpd_skip_count.db"

# Ensure databases exist
mkdir -p "$(dirname "$DB")"
touch "$DB" "$SKIP_DB"

# Get all songs from MPD
echo "🔍 Loading library..."
ALL_SONGS=$(mpc listall)

# Initialize missing songs with 0 plays
while IFS= read -r song; do
    if ! grep -qF "$song|" "$DB"; then
        echo "$song|0" >> "$DB"
    fi
done <<< "$ALL_SONGS"

# Sort by play count (ascending = least played first)
SORTED=$(sort -t'|' -k2 -n "$DB" | cut -d'|' -f1)

# Format for rofi with play counts visible
ROFI_LIST=""
while IFS= read -r song; do
    # Get play count
    COUNT=$(grep -F "$song|" "$DB" | cut -d'|' -f2)
    [ -z "$COUNT" ] && COUNT=0
    
    # Format: [plays: 3] artist - song.mp3
    ROFI_LIST+="[♪ $COUNT] $song"$'\n'
done <<< "$SORTED"

# Show rofi menu
SELECTED=$(echo -n "$ROFI_LIST" | rofi -dmenu -i \
    -p "🎵 Play (Sorted: Least → Most Played)" \
    -mesg "Tip: Your least-played songs appear first. New tracks = 0 plays." \
    -theme-str 'window {width: 85%; height: 65%;}' \
    -theme-str 'listview {columns: 1; lines: 18;}' \
    -theme-str 'element-text {horizontal-align: 0.0;}')

[ -z "$SELECTED" ] && exit 0

# Extract actual song path (remove [♪ N] prefix)
SONG_PATH=$(echo "$SELECTED" | sed 's/^\[♪ [0-9]*\] //')

# Play the selected song
mpc clear
mpc add "$SONG_PATH"
mpc play

# Update play count (+1)
awk -F'|' -v song="$SONG_PATH" '
BEGIN {OFS="|"}
$1==song {$2+=1; found=1}
{print}
END {if (!found) print song "|1"}
' "$DB" > "$DB.tmp" && mv "$DB.tmp" "$DB"

# Get current track info for notification
CURRENT=$(mpc --format "%artist% - %title%" current 2>/dev/null)
[ -z "$CURRENT" ] && CURRENT=$(basename "$SONG_PATH")

# Show notification
notify-send -u normal -t 4000 "▶ Now Playing" "$CURRENT"
echo "▶ Now Playing: $CURRENT"

# Optional: Track skips (run this separately if you want skip tracking)
# To use: bind a key to run: mpd-track-skip.sh
