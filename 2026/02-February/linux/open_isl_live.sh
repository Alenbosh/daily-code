#!/bin/bash

# ISL matches page
BASE_URL="https://www.fancode.com/football/tour/indian-super-league-2026-19377161/matches"

# Fetch page content
PAGE=$(curl -s "$BASE_URL")

# Extract first live match link
LIVE_LINK=$(echo "$PAGE" | grep -oP 'href="\K/football/tour/indian-super-league-2026-[^"]*live-match-info' | head -n 1)

# Check if found
if [ -n "$LIVE_LINK" ]; then
    FULL_LINK="https://www.fancode.com$LIVE_LINK"
    chromium --start-fullscreen "$FULL_LINK"
else
    # fallback: open matches page
    chromium "$BASE_URL"
fi
