#!/bin/bash

# Check if MPD is running
if ! pgrep -x mpd >/dev/null; then
    echo ""
    exit
fi

# Get MPD status
STATUS=$(mpc status 2>/dev/null | grep -o '\[.*\]' | tr -d '[]')

# Get current song using FILENAME (not metadata)
CURRENT=$(mpc current 2>/dev/null)

# If nothing is playing
if [ -z "$CURRENT" ]; then
    echo ""
    exit
fi

# Clean up the filename for display
CURRENT=$(echo "$CURRENT" | sed 's/\.mp3$//' | sed 's/.*\///')

# Set icon based on status
case "$STATUS" in
playing)
    ICON=""
    ;;
paused)
    ICON=""
    ;;
*)
    ICON=""
    ;;
esac

# Truncate to fit
MAX_LENGTH=40
if [ ${#CURRENT} -gt $MAX_LENGTH ]; then
    TRUNCATED="${CURRENT:0:$((MAX_LENGTH - 3))}..."
else
    TRUNCATED="$CURRENT"
fi

echo "$ICON $TRUNCATED"
