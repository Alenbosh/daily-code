#!/bin/bash
# 🎵 MPD INTELLIGENT Launcher — Advanced weighted scoring
# Considers: play count, skip rate, and time since last played
# Lower score = appears first (more likely to be played)

DB="$HOME/.local/share/mpd_playcount.db"
SKIP_DB="$HOME/.local/share/mpd_skip_count.db"
LASTPLAY_DB="$HOME/.local/share/mpd_lastplayed.db"

# Ensure databases exist
mkdir -p "$(dirname "$DB")"
touch "$DB" "$SKIP_DB" "$LASTPLAY_DB"

echo "🔍 Analyzing library intelligence..."

# Get all songs
ALL_SONGS=$(mpc listall)

# Initialize missing songs
while IFS= read -r song; do
    grep -qF "$song|" "$DB" || echo "$song|0" >> "$DB"
    grep -qF "$song|" "$SKIP_DB" || echo "$song|0" >> "$SKIP_DB"
    grep -qF "$song|" "$LASTPLAY_DB" || echo "$song|0" >> "$LASTPLAY_DB"
done <<< "$ALL_SONGS"

# Calculate scores for each song
SCORED_LIST=$(awk -F'|' -v now="$(date +%s)" '
BEGIN {OFS="|"}
FNR==NR {plays[$1]=$2; next}
FNR==NR {skips[$1]=$2; next}
{
    song = $1
    lastplay = $2
    
    play_count = plays[song] + 0
    skip_count = skips[song] + 0
    
    # Scoring algorithm (lower = better = appears first)
    # Base: play count
    score = play_count * 10
    
    # Penalty for skips
    score += skip_count * 5
    
    # Bonus for songs not played recently (decay over time)
    if (lastplay > 0) {
        days_ago = (now - lastplay) / 86400
        if (days_ago > 7) score -= 10   # Played over a week ago
        if (days_ago > 30) score -= 20  # Played over a month ago
    } else {
        score -= 25  # Never played before (prioritize!)
    }
    
    # Never let score go negative
    if (score < 0) score = 0
    
    print score "|" song
}
' "$DB" "$SKIP_DB" "$LASTPLAY_DB" | sort -t'|' -k1 -n)

# Format for rofi with intelligence metrics
ROFI_LIST=""
while IFS='|' read -r score song; do
    plays=$(grep -F "$song|" "$DB" | cut -d'|' -f2)
    skips=$(grep -F "$song|" "$SKIP_DB" | cut -d'|' -f2)
    [ -z "$plays" ] && plays=0
    [ -z "$skips" ] && skips=0
    
    # Format display
    ROFI_LIST+="[♪$plays ⏭$skips] $song"$'\n'
done <<< "$SCORED_LIST"

# Show rofi
SELECTED=$(echo -n "$ROFI_LIST" | rofi -dmenu -i \
    -p "🎵 Smart Play (AI-Sorted)" \
    -mesg "♪=plays | ⏭=skips | Sorted by intelligence score" \
    -theme-str 'window {width: 90%; height: 70%;}' \
    -theme-str 'listview {columns: 1; lines: 20;}' \
    -theme-str 'element-text {horizontal-align: 0.0;}')

[ -z "$SELECTED" ] && exit 0

# Extract song path
SONG_PATH=$(echo "$SELECTED" | sed 's/^\[♪[0-9]* ⏭[0-9]*\] //')

# Play it
mpc clear
mpc add "$SONG_PATH"
mpc play

# Update play count
awk -F'|' -v song="$SONG_PATH" '
BEGIN {OFS="|"}
$1==song {$2+=1; found=1}
{print}
END {if (!found) print song "|1"}
' "$DB" > "$DB.tmp" && mv "$DB.tmp" "$DB"

# Update last played timestamp
NOW=$(date +%s)
awk -F'|' -v song="$SONG_PATH" -v now="$NOW" '
BEGIN {OFS="|"}
$1==song {$2=now; found=1}
{print}
END {if (!found) print song "|" now}
' "$LASTPLAY_DB" > "$LASTPLAY_DB.tmp" && mv "$LASTPLAY_DB.tmp" "$LASTPLAY_DB"

# Notification
CURRENT=$(mpc --format "%artist% - %title%" current 2>/dev/null)
[ -z "$CURRENT" ] && CURRENT=$(basename "$SONG_PATH")
notify-send -u normal -t 4000 "▶ Now Playing" "$CURRENT"
echo "▶ $CURRENT"
