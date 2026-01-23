#!/bin/bash

# ===== CONFIGURATION =====
API_KEY="Your_API_KEY"  # Replace with your actual key
LEAGUE=1                # MLB
SEASON=2026             # Update Season as needed
TIMEZONE="Asia/Kolkata" # Your timezone
CACHE_FILE="$HOME/.cache/waybar/baseball_cache.json"
CACHE_DURATION=300 # 5 minutes (300 seconds)

# ===== SEASON CHECK =====
# Only show during MLB season (April 1 - October 31)
CURRENT_DATE=$(date +%Y-%m-%d)
SEASON_START="2026-04-01"
SEASON_END="2026-10-31"

# Check if current date is within season
if [[ "$CURRENT_DATE" < "$SEASON_START" ]] || [[ "$CURRENT_DATE" > "$SEASON_END" ]]; then
    # Outside season - show nothing or off-season message
    echo '{"text": "", "tooltip": "MLB Off-Season"}'
    exit 0
fi

# ===== CACHE CHECK =====
if [ -f "$CACHE_FILE" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)))
    if [ "$CACHE_AGE" -lt "$CACHE_DURATION" ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# ===== API CALL =====
DATE=$(date +%Y-%m-%d)
RESPONSE=$(curl -s -X GET "https://v1.baseball.api-sports.io/games?league=$LEAGUE&season=$SEASON&date=$DATE&timezone=$TIMEZONE" \
    -H "x-apisports-key: $API_KEY")

# ===== ERROR HANDLING =====
if [ -z "$RESPONSE" ]; then
    OUTPUT='{"text": "⚾ Connection Error", "tooltip": "Failed to reach API", "class": "error"}'
    echo "$OUTPUT" | tee "$CACHE_FILE"
    exit 0
fi

ERRORS=$(echo "$RESPONSE" | jq -r '.errors[]?' 2>/dev/null)
if [ -n "$ERRORS" ] && [ "$ERRORS" != "null" ]; then
    OUTPUT="{\"text\": \"⚾ API Error\", \"tooltip\": \"$ERRORS\", \"class\": \"error\"}"
    echo "$OUTPUT" | tee "$CACHE_FILE"
    exit 0
fi

# ===== DATA PARSING =====
LIVE_GAMES=$(echo "$RESPONSE" | jq '[.response[] | select(.status.short | test("IN[1-9]|HT"))]' 2>/dev/null)

if [ "$(echo "$LIVE_GAMES" | jq 'length')" -gt 0 ]; then
    # LIVE GAMES DETECTED
    FIRST_GAME=$(echo "$LIVE_GAMES" | jq '.[0]')
    HOME_TEAM=$(echo "$FIRST_GAME" | jq -r '.teams.home.name')
    AWAY_TEAM=$(echo "$FIRST_GAME" | jq -r '.teams.away.name')
    HOME_SCORE=$(echo "$FIRST_GAME" | jq -r '.scores.home.total // 0')
    AWAY_SCORE=$(echo "$FIRST_GAME" | jq -r '.scores.away.total // 0')
    STATUS=$(echo "$FIRST_GAME" | jq -r '.status.long')

    TEXT="⚾ $HOME_TEAM $HOME_SCORE - $AWAY_SCORE $AWAY_TEAM | $STATUS"
    TOOLTIP="🔴 LIVE MLB GAMES\\n\\n$(echo "$LIVE_GAMES" | jq -r '.[] | "📍 \(.teams.home.name) \(.scores.home.total) - \(.scores.away.total) \(.teams.away.name)\\n   Status: \(.status.long)\\n"')"
else
    # NO LIVE GAMES - Show recent/upcoming
    TOTAL_GAMES=$(echo "$RESPONSE" | jq '.response | length')

    if [ "$TOTAL_GAMES" -gt 0 ]; then
        RECENT_GAME=$(echo "$RESPONSE" | jq '.response[0]')
        HOME_TEAM=$(echo "$RECENT_GAME" | jq -r '.teams.home.name')
        AWAY_TEAM=$(echo "$RECENT_GAME" | jq -r '.teams.away.name')
        HOME_SCORE=$(echo "$RECENT_GAME" | jq -r '.scores.home.total // "–"')
        AWAY_SCORE=$(echo "$RECENT_GAME" | jq -r '.scores.away.total // "–"')
        STATUS=$(echo "$RECENT_GAME" | jq -r '.status.long')

        TEXT="⚾ No Live | $HOME_TEAM $HOME_SCORE - $AWAY_SCORE $AWAY_TEAM"
        TOOLTIP="📅 MLB GAMES TODAY\\n\\n$(echo "$RESPONSE" | jq -r '.response[] | "📍 \(.teams.home.name) \(.scores.home.total // "–") - \(.scores.away.total // "–") \(.teams.away.name)\\n   \(.status.long)\\n"')"
    else
        TEXT="⚾ No MLB Games Today"
        TOOLTIP="No scheduled MLB games for $(date +%B\ %d,\ %Y)"
    fi
fi

# ===== OUTPUT =====
OUTPUT="{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"baseball\"}"
echo "$OUTPUT" | tee "$CACHE_FILE"
