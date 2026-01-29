#!/bin/bash
# 🎵 MPD Stats Viewer — See your listening intelligence

DB="$HOME/.local/share/mpd_playcount.db"
SKIP_DB="$HOME/.local/share/mpd_skip_count.db"
LASTPLAY_DB="$HOME/.local/share/mpd_lastplayed.db"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎵  MPD LISTENING INTELLIGENCE REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Total stats
TOTAL_SONGS=$(wc -l < "$DB" 2>/dev/null || echo 0)
TOTAL_PLAYS=$(awk -F'|' '{sum+=$2} END {print sum}' "$DB" 2>/dev/null || echo 0)
TOTAL_SKIPS=$(awk -F'|' '{sum+=$2} END {print sum}' "$SKIP_DB" 2>/dev/null || echo 0)
NEVER_PLAYED=$(grep -c '|0$' "$DB" 2>/dev/null || echo 0)

echo "📊 Overview"
echo "   Total Songs: $TOTAL_SONGS"
echo "   Total Plays: $TOTAL_PLAYS"
echo "   Total Skips: $TOTAL_SKIPS"
echo "   Never Played: $NEVER_PLAYED"
echo

# Most played
echo "🔥 Top 10 Most Played"
sort -t'|' -k2 -rn "$DB" | head -10 | while IFS='|' read -r song plays; do
    printf "   [%3d plays] %s\n" "$plays" "$(basename "$song")"
done
echo

# Most skipped
echo "⏭  Top 10 Most Skipped"
if [ -s "$SKIP_DB" ]; then
    sort -t'|' -k2 -rn "$SKIP_DB" | head -10 | while IFS='|' read -r song skips; do
        [ "$skips" -gt 0 ] && printf "   [%3d skips] %s\n" "$skips" "$(basename "$song")"
    done
else
    echo "   (No skip data yet)"
fi
echo

# Least played (candidates for next play)
echo "✨ Top 10 Least Played (Should Play Next)"
sort -t'|' -k2 -n "$DB" | head -10 | while IFS='|' read -r song plays; do
    printf "   [%3d plays] %s\n" "$plays" "$(basename "$song")"
done
echo

# Recently played
echo "🕐 Last 5 Played Songs"
if [ -s "$LASTPLAY_DB" ]; then
    sort -t'|' -k2 -rn "$LASTPLAY_DB" | head -5 | while IFS='|' read -r song timestamp; do
        if [ "$timestamp" -gt 0 ]; then
            time_ago=$(( ($(date +%s) - timestamp) / 60 ))
            if [ $time_ago -lt 60 ]; then
                printf "   [%2d min ago] %s\n" "$time_ago" "$(basename "$song")"
            elif [ $time_ago -lt 1440 ]; then
                printf "   [%2d hrs ago] %s\n" "$((time_ago / 60))" "$(basename "$song")"
            else
                printf "   [%2d days ago] %s\n" "$((time_ago / 1440))" "$(basename "$song")"
            fi
        fi
    done
else
    echo "   (No timestamp data yet)"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Use mpd-smart-launcher.sh or mpd-intelligent-launcher.sh to play"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
