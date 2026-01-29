#!/bin/bash
# 🎵 MPD Skip Tracker — Records when you skip songs
# Bind this to your "next track" keybind to track skips automatically

DB="$HOME/.local/share/mpd_playcount.db"
SKIP_DB="$HOME/.local/share/mpd_skip_count.db"

# Get currently playing song
CURRENT_SONG=$(mpc --format "%file%" current 2>/dev/null)

if [ -n "$CURRENT_SONG" ]; then
    # Record skip
    touch "$SKIP_DB"
    
    # Increment skip count
    awk -F'|' -v song="$CURRENT_SONG" '
    BEGIN {OFS="|"}
    $1==song {$2+=1; found=1}
    {print}
    END {if (!found) print song "|1"}
    ' "$SKIP_DB" > "$SKIP_DB.tmp" && mv "$SKIP_DB.tmp" "$SKIP_DB"
    
    echo "⏭ Skipped: $(basename "$CURRENT_SONG")"
fi

# Skip to next track
mpc next
