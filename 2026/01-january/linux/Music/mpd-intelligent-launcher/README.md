# 🎵 MPD Intelligent Music Launcher

**Anti-algorithm music player that surfaces your least-played songs naturally.**

Instead of replaying the same 5 songs forever, this system:
- Tracks play counts per song
- Prioritizes least-played tracks
- Records skips (optional)
- Considers recency (advanced mode)
- Builds a natural rotation through your library

---

## 📦 What's Included

### 1. **mpd-smart-launcher.sh** (Simple Mode)
- Sorts by play count only
- Shows least-played songs first
- Displays `[♪ N]` play count in rofi
- Perfect for basic "rotate my library" use

### 2. **mpd-intelligent-launcher.sh** (Advanced Mode)
- **Weighted scoring algorithm**
- Considers: plays, skips, recency
- Shows `[♪N ⏭M]` (plays & skips) in rofi
- Prioritizes songs you haven't heard in a while
- Penalizes songs you skip frequently

### 3. **mpd-track-skip.sh** (Optional Skip Tracker)
- Records when you skip songs
- Bind to your "next" keybind
- Feeds data into advanced launcher

### 4. **mpd-stats.sh** (Stats Viewer)
- View your listening patterns
- See most/least played songs
- Track skip statistics
- Check recently played tracks

---

## 🚀 Installation

```bash
# Copy scripts to your bin directory
cp mpd-*.sh ~/.local/bin/

# Make executable
chmod +x ~/.local/bin/mpd-*.sh
```

---

## ⚙️ Setup

### Bind to a Keybind (i3/sway example)
```
# Simple launcher
bindsym $mod+m exec --no-startup-id ~/.local/bin/mpd-smart-launcher.sh

# OR intelligent launcher
bindsym $mod+m exec --no-startup-id ~/.local/bin/mpd-intelligent-launcher.sh
```

### Optional: Track Skips
Bind your "next track" key to the skip tracker:
```
# Replace your normal "mpc next" with this:
bindsym $mod+n exec --no-startup-id ~/.local/bin/mpd-track-skip.sh
```

---

## 📊 How Scoring Works (Intelligent Mode)

```
Score = (plays × 10) + (skips × 5) - (recency_bonus)

Recency bonuses:
- Never played: -25 points (HIGH priority)
- >30 days ago: -20 points
- >7 days ago:  -10 points
- Recent:        0 bonus

Lower score = appears first in rofi
```

### Example Scenarios:

| Song | Plays | Skips | Last Played | Score | Priority |
|------|-------|-------|-------------|-------|----------|
| new-album.mp3 | 0 | 0 | never | **-25** | ⭐ HIGHEST |
| forgotten-gem.mp3 | 2 | 0 | 35 days ago | **0** | High |
| recent-banger.mp3 | 5 | 0 | 2 days ago | **50** | Medium |
| annoying-song.mp3 | 3 | 8 | 5 days ago | **70** | Low (skipped often) |

---

## 📁 Data Storage

All data stored in `~/.local/share/`:

```
mpd_playcount.db    — Play counts per song
mpd_skip_count.db   — Skip counts (optional)
mpd_lastplayed.db   — Timestamps (intelligent mode)
```

Format: `song/path.mp3|count`

---

## 📈 View Your Stats

```bash
~/.local/bin/mpd-stats.sh
```

Example output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎵  MPD LISTENING INTELLIGENCE REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Overview
   Total Songs: 1,247
   Total Plays: 8,432
   Total Skips: 312
   Never Played: 89

🔥 Top 10 Most Played
   [ 87 plays] favorite-song.mp3
   [ 63 plays] another-banger.mp3
   ...

✨ Top 10 Least Played (Should Play Next)
   [  0 plays] new-discovery.mp3
   [  1 plays] forgotten-album.mp3
   ...
```

---

## 🎯 Use Cases

### 1. **Rediscovery Mode** (Smart Launcher)
Perfect for:
- Finding forgotten albums
- Exploring your full library
- Breaking listening habits
- Natural rotation

### 2. **Intelligence Mode** (Intelligent Launcher)
Perfect for:
- Advanced curation
- Avoiding songs you skip
- Prioritizing fresh content
- Time-aware rotation

### 3. **Stats Analysis**
Perfect for:
- Understanding listening patterns
- Finding your most-skipped songs
- Tracking discovery progress

---

## 🔧 Customization

### Change Rofi Appearance
Edit the `-theme-str` lines in the scripts:
```bash
-theme-str 'window {width: 85%; height: 65%;}'
-theme-str 'listview {columns: 1; lines: 18;}'
```

### Adjust Scoring Algorithm
In `mpd-intelligent-launcher.sh`, modify:
```awk
score = play_count * 10      # Weight of play count
score += skip_count * 5      # Skip penalty
if (days_ago > 7) score -= 10   # Recency bonus
```

### Change Notification Style
Edit the `notify-send` line:
```bash
notify-send -u normal -t 4000 "▶ Now Playing" "$CURRENT"
```

---

## 🧠 Philosophy

**Problem:** Spotify/YouTube algorithms create filter bubbles.

**Solution:** Surface your own forgotten music naturally.

Instead of algorithmic recommendations based on "engagement metrics," this system:
- Prioritizes **variety** over repetition
- Values **your whole library** not just favorites
- Uses **negative feedback** (skips) intelligently
- Considers **temporal diversity** (when you last heard it)

You built the library. This helps you actually *use* it.

---

## 🚀 Advanced Ideas

Want to go deeper? Consider:

1. **Skip decay** — Old skips matter less
2. **Genre balancing** — Rotate between genres
3. **Mood tagging** — Filter by energy/mood
4. **Collaborative filtering** — Learn from similar users
5. **Time-of-day patterns** — Morning vs night preferences

---

## 📝 Requirements

- `mpc` (MPD client)
- `rofi` (menu system)
- `notify-send` (notifications)
- `awk`, `grep`, `sort` (standard Unix tools)

---

## 🐛 Troubleshooting

**Songs not updating?**
- Check `~/.local/share/mpd_*.db` exists
- Ensure scripts are executable

**Rofi not showing?**
- Test: `echo "test" | rofi -dmenu`
- Check your rofi config

**Notifications not working?**
- Test: `notify-send "test" "message"`
- Install `libnotify` if missing

---

## 📜 License

Do whatever you want with it. Public domain. No warranty.

Built with spite for algorithmic recommendation systems.

---

**Enjoy your anti-algorithm music experience.** 🎵
