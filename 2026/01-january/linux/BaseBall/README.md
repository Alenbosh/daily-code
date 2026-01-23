# MLB Stats API Integration for Waybar

A comprehensive Waybar module that displays live MLB games, scores, and standings directly in your status bar using the official free MLB Stats API.

![MLB Waybar Module](https://img.shields.io/badge/MLB-Waybar-blue)
![No API Key Required](https://img.shields.io/badge/API%20Key-Not%20Required-green)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## ✨ Features

- 🔴 **Live Game Scores** - Real-time updates with pulsing red indicator
- ✅ **Final Scores** - Completed game results
- 📊 **Division Standings** - Current MLB standings when no games are active
- 🎯 **Team-Specific Tracking** - Follow your favorite team exclusively
- 💾 **Smart Caching** - Efficient API usage with configurable cache durations
- 🎨 **Dynamic Styling** - Different colors for live/final/standings states
- 🆓 **Completely Free** - No API key required, uses official MLB Stats API

---

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Script Variations](#script-variations)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [API Reference](#api-reference)
- [Contributing](#contributing)

---

## 🔧 Prerequisites

### Required Dependencies
```bash
# Arch Linux / Manjaro
sudo pacman -S curl jq waybar

# Debian / Ubuntu
sudo apt install curl jq waybar

# Fedora
sudo dnf install curl jq waybar
```

### System Requirements
- **Wayland Compositor** (Hyprland, Sway, etc.)
- **Waybar** installed and configured
- **Internet connection** for API access

---

## 📦 Installation

### Quick Setup (5 minutes)

#### 1. Create Directory Structure
```bash
mkdir -p ~/.scripts
mkdir -p ~/.cache/waybar
mkdir -p ~/.config/waybar
```

#### 2. Download the Main Script
```bash
curl -o ~/.scripts/mlb-waybar.sh https://raw.githubusercontent.com/YOUR_REPO/mlb-waybar.sh
chmod +x ~/.scripts/mlb-waybar.sh
```

**Or create manually:**
```bash
nano ~/.scripts/mlb-waybar.sh
```

Paste the [Combined MLB Script](#combined-script-live--standings) and save.

#### 3. Configure Waybar

Add to `~/.config/waybar/config.jsonc`:

```jsonc
{
    "modules-right": [
        "custom/mlb",
        // ... other modules
    ],
    
    "custom/mlb": {
        "exec": "~/.scripts/mlb-waybar.sh",
        "interval": 300,
        "return-type": "json",
        "tooltip": true,
        "format": "{}",
        "on-click": "xdg-open https://www.mlb.com"
    }
}
```

#### 4. Add Styling

Add to `~/.config/waybar/style.css`:

```css
#custom-mlb {
    color: #ffffff;
    background-color: #1a1a1a;
    padding: 0 12px;
    margin: 0 4px;
    border-radius: 4px;
}

#custom-mlb.mlb-live {
    color: #ffffff;
    background-color: #ff0000;
    animation: pulse 2s ease-in-out infinite;
}

#custom-mlb.mlb-final {
    color: #90ee90;
    background-color: #1a1a1a;
}

#custom-mlb.mlb-standings {
    color: #87ceeb;
    background-color: #1a1a1a;
}

#custom-mlb.error {
    color: #ff5555;
    background-color: #2a0000;
}

#custom-mlb.warning {
    color: #ffaa00;
    background-color: #2a1a00;
}

@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.7; }
}
```

#### 5. Restart Waybar
```bash
pkill waybar && waybar &
```

---

## 📝 Configuration

### Main Configuration Variables

Edit `~/.scripts/mlb-waybar.sh`:

```bash
# Cache settings
CACHE_FILE="$HOME/.cache/waybar/mlb_cache.json"
CACHE_DURATION=300  # 5 minutes (in seconds)

# Season (auto-detected or manual)
SEASON=2025  # Or use auto-detection
```

### Recommended Intervals

| Use Case | Waybar Interval | Cache Duration | Description |
|----------|----------------|----------------|-------------|
| **Live Games** | 60 | 60 | Frequent updates during games |
| **Balanced** | 300 | 300 | Good for general use (recommended) |
| **Standings Only** | 1800 | 1800 | Standings change slowly |
| **Battery Saving** | 600 | 600 | Minimal API calls |

Update in Waybar config:
```jsonc
"interval": 300,  // seconds
```

---

## 🎭 Script Variations

### Combined Script (Live + Standings)

**File:** `~/.scripts/mlb-waybar.sh`

**Features:**
- Shows live games when available
- Falls back to standings when no games
- Auto-switches based on game status

**Best for:** General MLB fans who want everything

<details>
<summary>View Full Script</summary>

```bash
#!/usr/bin/env bash

# ===== CONFIGURATION =====
CACHE_FILE="$HOME/.cache/waybar/mlb_cache.json"
CACHE_DURATION=300
SEASON=2025

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
    
    local LIVE_COUNT=$(echo "$GAMES_RESPONSE" | jq -r '[.dates[0].games[]? | select(.status.statusCode == "I" or .status.statusCode == "IR")] | length' 2>/dev/null)
    
    if [ "$LIVE_COUNT" -gt 0 ]; then
        local FIRST_GAME=$(echo "$GAMES_RESPONSE" | jq -r '.dates[0].games[] | select(.status.statusCode == "I" or .status.statusCode == "IR") | @json' 2>/dev/null | head -1)
        
        local AWAY_TEAM=$(echo "$FIRST_GAME" | jq -r '.teams.away.team.abbreviation')
        local HOME_TEAM=$(echo "$FIRST_GAME" | jq -r '.teams.home.team.abbreviation')
        local AWAY_SCORE=$(echo "$FIRST_GAME" | jq -r '.teams.away.score // 0')
        local HOME_SCORE=$(echo "$FIRST_GAME" | jq -r '.teams.home.score // 0')
        local INNING=$(echo "$FIRST_GAME" | jq -r '.linescore.currentInning // "?"')
        local INNING_STATE=$(echo "$FIRST_GAME" | jq -r '.linescore.inningState // ""')
        
        local TEXT="⚾ LIVE: $AWAY_TEAM $AWAY_SCORE @ $HOME_TEAM $HOME_SCORE | ${INNING_STATE:0:1}$INNING"
        local TOOLTIP="🔴 LIVE MLB GAMES\\n\\n"
        TOOLTIP+=$(echo "$GAMES_RESPONSE" | jq -r '.dates[0].games[]? | select(.status.statusCode == "I" or .status.statusCode == "IR") | 
            "📍 \(.teams.away.team.abbreviation) \(.teams.away.score // 0) @ \(.teams.home.team.abbreviation) \(.teams.home.score // 0)\\n   \(.linescore.inningState // "") \(.linescore.currentInning // "")\\n"' 2>/dev/null)
        
        echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"mlb-live\"}"
        return 0
    fi
    
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
    
    local RECORDS_COUNT=$(echo "$STANDINGS_RESPONSE" | jq -r '.records | length' 2>/dev/null)
    
    if [ "$RECORDS_COUNT" -eq 0 ]; then
        echo '{"text": "⚾ No MLB Data", "tooltip": "Season data not available yet", "class": "warning"}'
        return
    fi
    
    local AL_EAST=$(echo "$STANDINGS_RESPONSE" | jq -r '.records[] | select(.division.name == "American League East") | .teamRecords[0] | "\(.team.abbreviation) \(.wins)-\(.losses)"' 2>/dev/null)
    local NL_EAST=$(echo "$STANDINGS_RESPONSE" | jq -r '.records[] | select(.division.name == "National League East") | .teamRecords[0] | "\(.team.abbreviation) \(.wins)-\(.losses)"' 2>/dev/null)
    
    local TEXT="⚾ AL: $AL_EAST | NL: $NL_EAST"
    local TOOLTIP="📊 MLB STANDINGS ($SEASON)\\n\\n"
    TOOLTIP+=$(echo "$STANDINGS_RESPONSE" | jq -r '.records[] | 
        "\(.division.name):\\n" + 
        (.teamRecords[0:3] | map("  \(.divisionRank). \(.team.abbreviation): \(.wins)-\(.losses) (\(.winningPercentage))") | join("\\n")) + 
        "\\n"' 2>/dev/null)
    
    echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"mlb-standings\"}"
}

# ===== MAIN LOGIC =====
LIVE_OUTPUT=$(get_live_games)

if [ -n "$LIVE_OUTPUT" ]; then
    OUTPUT="$LIVE_OUTPUT"
else
    OUTPUT=$(get_standings)
fi

echo "$OUTPUT" | tee "$CACHE_FILE"
```
</details>

---

### Standings Only Script

**File:** `~/.scripts/mlb-standings-only.sh`

**Features:**
- Shows division leaders
- Lower refresh rate (30 min recommended)
- Minimal API usage

**Best for:** Off-season tracking, battery conservation

<details>
<summary>View Script</summary>

```bash
#!/usr/bin/env bash

CACHE_FILE="$HOME/.cache/waybar/mlb_standings.json"
CACHE_DURATION=1800

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
    AL_LEADER=$(echo "$RESPONSE" | jq -r '[.records[] | select(.league.id == 103) | .teamRecords[]] | max_by(.wins) | "\(.team.abbreviation) \(.wins)-\(.losses)"' 2>/dev/null)
    NL_LEADER=$(echo "$RESPONSE" | jq -r '[.records[] | select(.league.id == 104) | .teamRecords[]] | max_by(.wins) | "\(.team.abbreviation) \(.wins)-\(.losses)"' 2>/dev/null)
    
    TEXT="⚾ AL: $AL_LEADER | NL: $NL_LEADER"
    TOOLTIP="📊 MLB DIVISION LEADERS\\n\\n"
    TOOLTIP+=$(echo "$RESPONSE" | jq -r '.records[] | "\(.division.name): \(.teamRecords[0].team.abbreviation) \(.teamRecords[0].wins)-\(.teamRecords[0].losses)\\n"')
    
    OUTPUT="{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"mlb\"}"
fi

echo "$OUTPUT" | tee "$CACHE_FILE"
```
</details>

---

### Team-Specific Script

**File:** `~/.scripts/mlb-team-waybar.sh`

**Features:**
- Track one specific team
- Shows team's games only
- Displays team record when no game

**Best for:** Die-hard fans of a single team

**Setup:**
```bash
# Find your team ID
curl -s "https://statsapi.mlb.com/api/v1/teams?sportId=1" | jq '.teams[] | {id, name, abbreviation}'

# Common team IDs:
# Yankees: 147, Red Sox: 111, Dodgers: 119
# Cubs: 112, Giants: 137, Astros: 117
```

<details>
<summary>View Script</summary>

```bash
#!/usr/bin/env bash

TEAM_ID=147  # ← CHANGE THIS
CACHE_FILE="$HOME/.cache/waybar/mlb_team_${TEAM_ID}.json"
CACHE_DURATION=180

if [ -f "$CACHE_FILE" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)))
    if [ "$CACHE_AGE" -lt "$CACHE_DURATION" ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

TEAM_INFO=$(curl -s "https://statsapi.mlb.com/api/v1/teams/$TEAM_ID")
TEAM_NAME=$(echo "$TEAM_INFO" | jq -r '.teams[0].abbreviation')

TODAY=$(date +%Y-%m-%d)
GAME_URL="https://statsapi.mlb.com/api/v1/schedule?sportId=1&teamId=$TEAM_ID&date=$TODAY&hydrate=team,linescore"
GAME_RESPONSE=$(curl -s --fail "$GAME_URL")

if [ $? -eq 0 ] && [ "$(echo "$GAME_RESPONSE" | jq -r '.dates[0].games | length' 2>/dev/null)" -gt 0 ]; then
    GAME=$(echo "$GAME_RESPONSE" | jq -r '.dates[0].games[0]')
    
    AWAY_TEAM=$(echo "$GAME" | jq -r '.teams.away.team.abbreviation')
    HOME_TEAM=$(echo "$GAME" | jq -r '.teams.home.team.abbreviation')
    AWAY_SCORE=$(echo "$GAME" | jq -r '.teams.away.score // "–"')
    HOME_SCORE=$(echo "$GAME" | jq -r '.teams.home.score // "–"')
    STATUS=$(echo "$GAME" | jq -r '.status.detailedState')
    INNING=$(echo "$GAME" | jq -r '.linescore.currentInning // ""')
    INNING_STATE=$(echo "$GAME" | jq -r '.linescore.inningState // ""')
    
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

OUTPUT="{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS\"}"
echo "$OUTPUT" | tee "$CACHE_FILE"
```
</details>

---

## 🎨 Customization

### Auto Season Detection

Add this to any script to automatically use the current MLB season:

```bash
# Add after configuration section
get_current_season() {
    local SEASONS_RESPONSE=$(curl -s "https://statsapi.mlb.com/api/v1/seasons/all?sportId=1")
    local CURRENT_YEAR=$(date +%Y)
    local SEASON_ID=$(echo "$SEASONS_RESPONSE" | jq -r ".seasons[] | select(.seasonId == \"$CURRENT_YEAR\") | .seasonId" 2>/dev/null)
    
    if [ -z "$SEASON_ID" ]; then
        SEASON_ID=$((CURRENT_YEAR - 1))
    fi
    
    echo "$SEASON_ID"
}

SEASON=$(get_current_season)
```

### Custom Team Icons

Replace `⚾` with team-specific icons using Nerd Fonts:

```bash
# In script, add team icon mapping
case "$TEAM_NAME" in
    "NYY") ICON="" ;;
    "BOS") ICON="" ;;
    "LAD") ICON="" ;;
    *) ICON="⚾" ;;
esac

TEXT="$ICON $AWAY_TEAM $AWAY_SCORE @ $HOME_TEAM $HOME_SCORE"
```

### Advanced Styling Examples

**Gradient Background:**
```css
#custom-mlb {
    background: linear-gradient(90deg, #1a1a1a 0%, #2a2a2a 100%);
}
```

**Team Color Themes:**
```css
#custom-mlb.yankees {
    background-color: #003087;
    color: #ffffff;
}

#custom-mlb.redsox {
    background-color: #BD3039;
    color: #ffffff;
}
```

---

## 🔍 Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| Module not appearing | Check Waybar config syntax: `jsonlint ~/.config/waybar/config.jsonc` |
| "No MLB Data" message | Check if season has started, try previous year: `SEASON=2024` |
| Permission denied | Make script executable: `chmod +x ~/.scripts/mlb-waybar.sh` |
| Old data showing | Clear cache: `rm ~/.cache/waybar/mlb_*.json` |
| API connection error | Check internet connection, test API manually |
| Empty tooltip | Increase verbosity, check API response directly |

### Testing Commands

```bash
# Test MLB API directly
curl -s "https://statsapi.mlb.com/api/v1/standings?leagueId=103,104" | jq

# Test today's games
curl -s "https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=$(date +%Y-%m-%d)" | jq

# Test script output
~/.scripts/mlb-waybar.sh

# Watch script updates in real-time
watch -n 5 ~/.scripts/mlb-waybar.sh

# View cached data
cat ~/.cache/waybar/mlb_cache.json | jq

# Clear all MLB caches
rm ~/.cache/waybar/mlb_*.json

# Restart Waybar
pkill waybar && waybar &

# Check Waybar logs (if using systemd)
journalctl --user -u waybar -f
```

### Debug Mode

Add to script for verbose output:

```bash
# At top of script
set -x  # Enable debug mode
# Your script here
set +x  # Disable debug mode
```

---

## 📚 API Reference

### MLB Stats API Endpoints

#### Standings
```bash
# All MLB standings
https://statsapi.mlb.com/api/v1/standings?leagueId=103,104&season=2025

# Specific team
https://statsapi.mlb.com/api/v1/standings?teamId=147

# American League only
https://statsapi.mlb.com/api/v1/standings?leagueId=103
```

#### Games/Schedule
```bash
# Today's games
https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=2025-01-23

# Team-specific games
https://statsapi.mlb.com/api/v1/schedule?teamId=147&season=2025

# Games with detailed info
https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=2025-01-23&hydrate=team,linescore
```

#### Teams
```bash
# All MLB teams
https://statsapi.mlb.com/api/v1/teams?sportId=1

# Specific team
https://statsapi.mlb.com/api/v1/teams/147
```

#### Seasons
```bash
# All available seasons
https://statsapi.mlb.com/api/v1/seasons/all?sportId=1
```

### Status Codes

| Code | Meaning |
|------|---------|
| `S` | Scheduled |
| `P` | Pre-Game |
| `I` | In Progress |
| `IR` | In Progress (Delayed) |
| `F` | Final |
| `FR` | Final (Rescheduled) |
| `FT` | Final (Tied) |
| `DR` | Delayed/Rain |
| `PP` | Postponed |

### League IDs

| ID | League |
|----|--------|
| 103 | American League (AL) |
| 104 | National League (NL) |

---

## 📂 File Structure

```
~/.scripts/
├── mlb-waybar.sh              # Combined script (recommended)
├── mlb-standings-only.sh      # Standings only
└── mlb-team-waybar.sh         # Team-specific
(Additional one uses api)
└──baseball-waybar.sh          # API from dashboardapifootball.com

~/.config/waybar/
├── config.jsonc               # Waybar configuration
└── style.css                  # Waybar styling

~/.cache/waybar/
├── mlb_cache.json            # Combined script cache
├── mlb_standings.json        # Standings cache
├── mlb_team_147.json         # Team-specific cache
└── mlb_season.txt            # Season cache (if using auto-detection)
```

---

## 🚀 Performance Tips

1. **Optimize Cache Duration**
   - Live games: 60-180 seconds
   - Standings: 1800-3600 seconds
   - Off-season: 3600+ seconds

2. **Reduce API Calls**
   - Enable caching for all scripts
   - Use appropriate intervals
   - Cache season detection (24 hours)

3. **Memory Usage**
   - Periodically clear old caches: `find ~/.cache/waybar -name "mlb_*.json" -mtime +7 -delete`
   - Keep cache duration reasonable

---

## 🎯 Advanced Features

### Multiple Teams

Add multiple team modules to your Waybar:

```jsonc
"custom/mlb-yankees": {
    "exec": "~/.scripts/mlb-yankees.sh",
    "interval": 180
},
"custom/mlb-dodgers": {
    "exec": "~/.scripts/mlb-dodgers.sh",
    "interval": 180
}
```

### Conditional Display

Only show module during baseball season:

```bash
# Add to script
MONTH=$(date +%m)
if [ "$MONTH" -lt 3 ] || [ "$MONTH" -gt 10 ]; then
    echo '{"text": "", "tooltip": "Off-season"}'
    exit 0
fi
```

### Desktop Notifications

Add to script when game starts/ends:

```bash
# When live game detected
notify-send "⚾ MLB" "$AWAY_TEAM @ $HOME_TEAM is LIVE!"

# When game ends
notify-send "⚾ MLB" "Final: $AWAY_TEAM $AWAY_SCORE - $HOME_TEAM $HOME_SCORE"
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Ideas for Contribution
- Add playoff bracket tracking
- Player statistics display
- Game highlights integration
- Multi-league support (MiLB, international)
- Weather delay notifications

---

## 📄 License

MIT License - Feel free to use and modify as needed.

---

## 🙏 Acknowledgments

- **MLB Stats API** - Official free API from Major League Baseball
- **Waybar** - Highly customizable Wayland bar
- **jq** - Command-line JSON processor

---

## 📞 Support

If you encounter issues:

1. Check [Troubleshooting](#troubleshooting) section
2. Test API endpoints manually
3. Verify script permissions and paths
4. Check Waybar logs
5. Open an issue with debug output

---

## 🔗 Useful Links

- [MLB Stats API Documentation](https://github.com/toddrob99/MLB-StatsAPI)
- [Waybar Wiki](https://github.com/Alexays/Waybar/wiki)
- [jq Manual](https://stedolan.github.io/jq/manual/)

---

**Last Updated:** January 2026  
**Version:** 1.0.0  
**Maintained by:** Alen

---

⭐ If you found this helpful, consider starring the repository!
