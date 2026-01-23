#!/usr/bin/env bash

# ===== CONFIGURATION =====
CACHE_FILE="$HOME/.cache/waybar/mlb_cache.json"
CACHE_DURATION=300 # 5 minutes (300 seconds)
SEASON=2025        # Update if needed

# ===== CACHE CHECK =====
if [ -f "$CACHE_FILE" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)))
    if [ "$CACHE_AGE" -lt "$CACHE_DURATION" ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# ===== FUNCTION: GET LIVE GAMES =====
get_live_games() {
    local TODAY=$(date +%Y-%m-%d)
    local GAMES_URL="https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=$TODAY&hydrate=team,linescore"
    local GAMES_RESPONSE=$(curl -s --fail "$GAMES_URL")

    if [ $? -ne 0 ] || [ -z "$GAMES_RESPONSE" ]; then
        echo ""
        return
    fi

    # Check for live or recent games
    local LIVE_COUNT=$(echo "$GAMES_RESPONSE" | jq -r '[.dates[0].games[]? | select(.status.statusCode == "I" or .status.statusCode == "IR")] | length' 2>/dev/null)

    if [ "$LIVE_COUNT" -gt 0 ]; then
        # Live games exist
        local FIRST_GAME=$(echo "$GAMES_RESPONSE" | jq -r '.dates[0].games[] | select(.status.statusCode == "I" or .status.statusCode == "IR") | @json' 2>/dev/null | head -1)

        local AWAY_TEAM=$(echo "$FIRST_GAME" | jq -r '.teams.away.team.abbreviation')
        local HOME_TEAM=$(echo "$FIRST_GAME" | jq -r '.teams.home.team.abbreviation')
        local AWAY_SCORE=$(echo "$FIRST_GAME" | jq -r '.teams.away.score // 0')
        local HOME_SCORE=$(echo "$FIRST_GAME" | jq -r '.teams.home.score // 0')
        local INNING=$(echo "$FIRST_GAME" | jq -r '.linescore.currentInning // "?"')
        local INNING_STATE=$(echo "$FIRST_GAME" | jq -r '.linescore.inningState // ""')

        local TEXT="⚾ LIVE: $AWAY_TEAM $AWAY_SCORE @ $HOME_TEAM $HOME_SCORE | ${INNING_STATE:0:1}$INNING"

        # Build tooltip with all live games
        local TOOLTIP="🔴 LIVE MLB GAMES\\n\\n"
        TOOLTIP+=$(echo "$GAMES_RESPONSE" | jq -r '.dates[0].games[]? | select(.status.statusCode == "I" or .status.statusCode == "IR") | 
            "📍 \(.teams.away.team.abbreviation) \(.teams.away.score // 0) @ \(.teams.home.team.abbreviation) \(.teams.home.score // 0)\\n   \(.linescore.inningState // "") \(.linescore.currentInning // "")\\n"' 2>/dev/null)

        echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"mlb-live\"}"
        return 0
    fi

    # Check for completed games today
    local COMPLETED_COUNT=$(echo "$GAMES_RESPONSE" | jq -r '[.dates[0].games[]? | select(.status.statusCode == "F")] | length' 2>/dev/null)

    if [ "$COMPLETED_COUNT" -gt 0 ]; then
        local RECENT_GAME=$(echo "$GAMES_RESPONSE" | jq -r '.dates[0].games[] | select(.status.statusCode == "F") | @json' 2>/dev/null | head -1)

        local AWAY_TEAM=$(echo "$RECENT_GAME" | jq -r '.teams.away.team.abbreviation')
        local HOME_TEAM=$(echo "$RECENT_GAME" | jq -r '.teams.home.team.abbreviation')
        local AWAY_SCORE=$(echo "$RECENT_GAME" | jq -r '.teams.away.score')
        local HOME_SCORE=$(echo "$RECENT_GAME" | jq -r '.teams.home.score')

        local TEXT="⚾ Final: $AWAY_TEAM $AWAY_SCORE @ $HOME_TEAM $HOME_SCORE"

        local TOOLTIP="✅ TODAY'S COMPLETED GAMES\\n\\n"
        TOOLTIP+=$(echo "$GAMES_RESPONSE" | jq -r '.dates[0].games[]? | select(.status.statusCode == "F") | 
            "📍 \(.teams.away.team.abbreviation) \(.teams.away.score) @ \(.teams.home.team.abbreviation) \(.teams.home.score) - Final\\n"' 2>/dev/null)

        echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"mlb-final\"}"
        return 0
    fi

    echo ""
}

# ===== FUNCTION: GET STANDINGS =====
get_standings() {
    local STANDINGS_URL="https://statsapi.mlb.com/api/v1/standings?leagueId=103,104&season=$SEASON"
    local STANDINGS_RESPONSE=$(curl -s --fail "$STANDINGS_URL")

    if [ $? -ne 0 ] || [ -z "$STANDINGS_RESPONSE" ]; then
        echo '{"text": "⚾ MLB API Error", "tooltip": "Failed to fetch standings", "class": "error"}'
        return
    fi

    # Check if we have data
    local RECORDS_COUNT=$(echo "$STANDINGS_RESPONSE" | jq -r '.records | length' 2>/dev/null)

    if [ "$RECORDS_COUNT" -eq 0 ]; then
        echo '{"text": "⚾ No MLB Data", "tooltip": "Season data not available yet", "class": "warning"}'
        return
    fi

    # Get division leaders (first place in each division)
    local AL_EAST=$(echo "$STANDINGS_RESPONSE" | jq -r '.records[] | select(.division.name == "American League East") | .teamRecords[0] | "\(.team.abbreviation) \(.wins)-\(.losses)"' 2>/dev/null)
    local NL_EAST=$(echo "$STANDINGS_RESPONSE" | jq -r '.records[] | select(.division.name == "National League East") | .teamRecords[0] | "\(.team.abbreviation) \(.wins)-\(.losses)"' 2>/dev/null)

    local TEXT="⚾ AL: $AL_EAST | NL: $NL_EAST"

    # Build comprehensive tooltip
    local TOOLTIP="📊 MLB STANDINGS ($SEASON)\\n\\n"
    TOOLTIP+=$(echo "$STANDINGS_RESPONSE" | jq -r '.records[] | 
        "\(.division.name):\\n" + 
        (.teamRecords[0:3] | map("  \(.divisionRank). \(.team.abbreviation): \(.wins)-\(.losses) (\(.winningPercentage))") | join("\\n")) + 
        "\\n"' 2>/dev/null)

    echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"mlb-standings\"}"
}

# ===== AUTO-DETECT SEASON =====
get_current_season() {
    local SEASONS_RESPONSE=$(curl -s "https://statsapi.mlb.com/api/v1/seasons/all?sportId=1")
    local CURRENT_YEAR=$(date +%Y)

    # Try to find current year's season
    local SEASON_ID=$(echo "$SEASONS_RESPONSE" | jq -r ".seasons[] | select(.seasonId == \"$CURRENT_YEAR\") | .seasonId" 2>/dev/null)

    if [ -z "$SEASON_ID" ]; then
        # Fallback to previous year if current year not found
        SEASON_ID=$((CURRENT_YEAR - 1))
    fi

    echo "$SEASON_ID"
}

# ===== MAIN LOGIC =====
# Try to get live games first
LIVE_OUTPUT=$(get_live_games)

if [ -n "$LIVE_OUTPUT" ]; then
    # Live or recent games found
    OUTPUT="$LIVE_OUTPUT"
else
    # No games today, show standings
    OUTPUT=$(get_standings)
fi

# ===== SAVE TO CACHE & OUTPUT =====
echo "$OUTPUT" | tee "$CACHE_FILE"
