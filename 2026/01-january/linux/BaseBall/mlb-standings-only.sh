#!/usr/bin/env bash

CACHE_FILE="$HOME/.cache/waybar/mlb_standings.json"
CACHE_DURATION=1800 # 30 minutes - standings change slowly

if [ -f "$CACHE_FILE" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)))
    if [ "$CACHE_AGE" -lt "$CACHE_DURATION" ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

URL="https://statsapi.mlb.com/api/v1/standings?leagueId=103,104"
RESPONSE=$(curl -s --fail "$URL")

if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
    OUTPUT='{"text": "⚾ API Error", "tooltip": "Failed to fetch standings", "class": "error"}'
else
    # Get top team from each league
    AL_LEADER=$(echo "$RESPONSE" | jq -r '[.records[] | select(.league.id == 103) | .teamRecords[]] | max_by(.wins) | "\(.team.abbreviation) \(.wins)-\(.losses)"' 2>/dev/null)
    NL_LEADER=$(echo "$RESPONSE" | jq -r '[.records[] | select(.league.id == 104) | .teamRecords[]] | max_by(.wins) | "\(.team.abbreviation) \(.wins)-\(.losses)"' 2>/dev/null)

    TEXT="⚾ AL: $AL_LEADER | NL: $NL_LEADER"

    TOOLTIP="📊 MLB DIVISION LEADERS\\n\\n"
    TOOLTIP+=$(echo "$RESPONSE" | jq -r '.records[] | "\(.division.name): \(.teamRecords[0].team.abbreviation) \(.teamRecords[0].wins)-\(.teamRecords[0].losses)\\n"')

    OUTPUT="{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"mlb\"}"
fi

echo "$OUTPUT" | tee "$CACHE_FILE"
