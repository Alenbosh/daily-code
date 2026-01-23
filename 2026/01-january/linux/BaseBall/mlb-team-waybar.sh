#!/usr/bin/env bash

# ===== CONFIGURATION =====
TEAM_ID=133 # ← CHANGE THIS to your team's ID
CACHE_FILE="$HOME/.cache/waybar/mlb_team_${TEAM_ID}.json"
CACHE_DURATION=180 # 3 minutes for team-specific updates

# ===== CACHE CHECK =====
if [ -f "$CACHE_FILE" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)))
    if [ "$CACHE_AGE" -lt "$CACHE_DURATION" ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# ===== GET TEAM INFO =====
TEAM_INFO=$(curl -s "https://statsapi.mlb.com/api/v1/teams/$TEAM_ID")
TEAM_NAME=$(echo "$TEAM_INFO" | jq -r '.teams[0].abbreviation')

# ===== CHECK TODAY'S GAME =====
TODAY=$(date +%Y-%m-%d)
GAME_URL="https://statsapi.mlb.com/api/v1/schedule?sportId=1&teamId=$TEAM_ID&date=$TODAY&hydrate=team,linescore"
GAME_RESPONSE=$(curl -s --fail "$GAME_URL")

if [ $? -eq 0 ] && [ "$(echo "$GAME_RESPONSE" | jq -r '.dates[0].games | length' 2>/dev/null)" -gt 0 ]; then
    # Game found today
    GAME=$(echo "$GAME_RESPONSE" | jq -r '.dates[0].games[0]')

    AWAY_TEAM=$(echo "$GAME" | jq -r '.teams.away.team.abbreviation')
    HOME_TEAM=$(echo "$GAME" | jq -r '.teams.home.team.abbreviation')
    AWAY_SCORE=$(echo "$GAME" | jq -r '.teams.away.score // "–"')
    HOME_SCORE=$(echo "$GAME" | jq -r '.teams.home.score // "–"')
    STATUS=$(echo "$GAME" | jq -r '.status.detailedState')
    INNING=$(echo "$GAME" | jq -r '.linescore.currentInning // ""')
    INNING_STATE=$(echo "$GAME" | jq -r '.linescore.inningState // ""')

    # Determine if game is live
    STATUS_CODE=$(echo "$GAME" | jq -r '.status.statusCode')
    if [[ "$STATUS_CODE" == "I" || "$STATUS_CODE" == "IR" ]]; then
        CLASS="mlb-live"
        TEXT="⚾ $AWAY_TEAM $AWAY_SCORE @ $HOME_TEAM $HOME_SCORE | ${INNING_STATE:0:1}$INNING"
    elif [[ "$STATUS_CODE" == "F" ]]; then
        CLASS="mlb-final"
        TEXT="⚾ Final: $AWAY_TEAM $AWAY_SCORE @ $HOME_TEAM $HOME_SCORE"
    else
        CLASS="mlb-upcoming"
        TEXT="⚾ Today: $AWAY_TEAM @ $HOME_TEAM | $STATUS"
    fi

    TOOLTIP="$TEAM_NAME Game\\n\\n$AWAY_TEAM $AWAY_SCORE\\n$HOME_TEAM $HOME_SCORE\\n\\n$STATUS"
else
    # No game today - show team record
    STANDINGS_URL="https://statsapi.mlb.com/api/v1/standings?teamId=$TEAM_ID"
    STANDINGS=$(curl -s --fail "$STANDINGS_URL")

    if [ $? -eq 0 ]; then
        RECORD=$(echo "$STANDINGS" | jq -r '.records[0].teamRecords[0]')
        WINS=$(echo "$RECORD" | jq -r '.wins')
        LOSSES=$(echo "$RECORD" | jq -r '.losses')
        PCT=$(echo "$RECORD" | jq -r '.winningPercentage')
        DIV_RANK=$(echo "$RECORD" | jq -r '.divisionRank')
        DIV_NAME=$(echo "$STANDINGS" | jq -r '.records[0].division.name')

        TEXT="⚾ $TEAM_NAME: $WINS-$LOSSES ($PCT)"
        TOOLTIP="$TEAM_NAME Record\\n\\n$WINS-$LOSSES\\nWin %: $PCT\\n$DIV_RANK in $DIV_NAME"
        CLASS="mlb-standings"
    else
        TEXT="⚾ $TEAM_NAME - No Data"
        TOOLTIP="No game data available"
        CLASS="mlb-warning"
    fi
fi

# ===== OUTPUT =====
OUTPUT="{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS\"}"
echo "$OUTPUT" | tee "$CACHE_FILE"
