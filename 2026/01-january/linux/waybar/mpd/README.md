# MPD + Waybar Setup

## Overview
Custom MPD (Music Player Daemon) setup with Waybar integration for music playback control and display.

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
- Uses filenames instead of metadata
- Cleans up common patterns (Official, mp3.pm, PagalNew, 320 Kbps)
- Max display length: 50 characters
- Sends notification on playback

#### `~/.local/bin/clean-music-filenames`
Batch rename music files to clean format
- Removes underscores, quality tags, site names
- Usage: `clean-music-filenames ~/Music`
- **Remember to run `mpc update` after renaming!**

## Waybar Controls

### Custom MPD Module
- **Left click**: Play/Pause
- **Middle click**: Search and play song
- **Right click**: Open rmpc (TUI client)
- **Scroll up**: Next song
- **Scroll down**: Previous song

### MPRIS Module (Non-MPD players)
- **Left click**: Play/Pause
- **Right click**: Next track
- **Scroll**: Volume control

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
~/.config/waybar/config              # Waybar configuration
~/.config/waybar/scripts/mpd-status.sh    # MPD status display
~/.local/bin/mpd-search-play         # Search and play script
~/.local/bin/clean-music-filenames   # Filename cleanup tool
~/.config/tofi/config                # Tofi launcher config
~/.config/mpd/mpd.conf               # MPD configuration
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
