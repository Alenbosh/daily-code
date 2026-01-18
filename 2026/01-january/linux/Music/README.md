# MPD + Waybar Setup

## Overview
Custom MPD (Music Player Daemon) setup with Waybar integration for full music playback control, queue management, and display.

## Components

### 1. Waybar Modules
- **`custom/mpd`**: Dedicated MPD status and controls
- **`mpris`**: Universal media player widget (ignores MPD, shows Spotify/browser/mpv)

### 2. Scripts

#### `~/.config/waybar/scripts/mpd-status.sh`
Displays current MPD track in Waybar
- Shows filename-based display (since metadata is poor)
- Icons: 󰐊 playing, 󰏤 paused
- Auto-truncates long names to 40 characters

#### `~/.local/bin/mpd-search-play`
Search and play songs from MPD library using tofi
- Clears queue and plays selected song immediately
- Uses filenames instead of metadata
- Cleans up common patterns (Official, mp3.pm, PagalNew, 320 Kbps)
- Max display length: 50 characters
- Sends notification on playback

#### `~/.local/bin/mpd-queue-add`
Add songs to queue without clearing current playlist
- Search and add multiple songs
- Queue continues playing
- Shows notification when song is added

#### `~/.local/bin/mpd-queue-view`
Interactive queue manager with full control
- View all songs in queue
- Play any song from queue
- Move songs up/down one position
- Move songs to specific position (manual entry)
- Remove songs from queue
- Shuffle entire queue
- Clear entire queue
- Loops back after actions for continuous management

#### `~/.local/bin/mpd-control`
Comprehensive MPD control menu
- Play/Pause, Next, Previous, Stop
- Search & Play, Add to Queue, View Queue
- Clear Queue, Shuffle Queue
- Volume Up/Down
- Open rmpc TUI client

#### `~/.local/bin/mpd-toggle`
Simple play/pause toggle with notification
- Shows current track and status
- Quick keyboard control

#### `~/.local/bin/mpd-stop`
Stop playback and clear queue
- Completely stops music
- Clears all queued songs

#### `~/.local/bin/clean-music-filenames`
Batch rename music files to clean format
- Removes underscores, quality tags, site names
- Usage: `clean-music-filenames ~/Music`
- **Remember to run `mpc update` after renaming!**

## Waybar Controls

### Custom MPD Module
- **Left click**: Play/Pause
- **Middle click**: Open MPD control menu
- **Right click**: Open rmpc (TUI client)
- **Scroll up**: Next song
- **Scroll down**: Previous song

### MPRIS Module (Non-MPD players)
- **Left click**: Play/Pause
- **Right click**: Next track
- **Scroll**: Volume control

## Keyboard Shortcuts (Hyprland)

### Basic Playback
- **Super + P**: Play/Pause toggle
- **Super + ]**: Next song
- **Super + [**: Previous song
- **Super + Shift + X**: Stop & clear queue

### Search & Queue Management
- **Super + S**: Search and play (clears queue)
- **Super + A**: Add to queue (keeps current queue)
- **Super + Q**: View and manage queue
- **Super + Shift + P**: Open full MPD control menu

### Queue Manager Actions
When in queue manager:
- Select song → Show action menu
  - ▶ Play This Song
  - ⬆ Move Up (one position)
  - ⬇ Move Down (one position)
  - 🔢 Move to Position (manual entry)
  - 🗑️ Remove from Queue
  - ← Back
- Top menu options:
  - ▶ Play Selected
  - 🔀 Shuffle Queue
  - 🗑️ Clear Queue

## Services
- **`mpd-mpris`**: Bridges MPD to MPRIS for system-wide integration
  - Enabled: `systemctl --user status mpd-mpris`
  - Allows `playerctl` to control MPD

## Music Library Management

### Update MPD database after changes:
```bash
mpc update
```

### Clean music filenames:
```bash
clean-music-filenames ~/Music
mpc update
```

### Check what's in library:
```bash
mpc listall | head -20
```

## File Locations
```
~/.config/waybar/config                      # Waybar configuration
~/.config/waybar/scripts/mpd-status.sh       # MPD status display
~/.local/bin/mpd-search-play                 # Search and play (clears queue)
~/.local/bin/mpd-queue-add                   # Add to queue
~/.local/bin/mpd-queue-view                  # Queue manager
~/.local/bin/mpd-control                     # Full control menu
~/.local/bin/mpd-toggle                      # Play/pause toggle
~/.local/bin/mpd-stop                        # Stop and clear
~/.local/bin/clean-music-filenames           # Filename cleanup tool
~/.config/tofi/config                        # Tofi launcher config
~/.config/mpd/mpd.conf                       # MPD configuration
~/.config/hypr/binds.conf                    # Hyprland keybindings
```

## Tips
- Music files work best with format: `Artist - Title.mp3`
- Avoid underscores, use spaces
- Remove quality tags (320 Kbps) and site names
- Keep filenames under 50 characters for best display
- Run `mpc update` after adding/renaming files

## Troubleshooting

### Songs don't show in Waybar
```bash
mpc update
killall waybar && waybar &
```

### Search shows wrong songs
```bash
# Update MPD database
mpc update

# Check if files are readable
ls ~/Music/*.mp3
```

### Tofi config errors
Remove inline comments (`#`) from `~/.config/tofi/config` - comments must be on separate lines

## Quick Commands
```bash
# Play/pause
mpc toggle

# Next/previous
mpc next
mpc prev

# Search and play
~/.local/bin/mpd-search-play

# Open rmpc TUI
rmpc

# Clean filenames
clean-music-filenames ~/Music
```
