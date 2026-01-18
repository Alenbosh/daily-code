#!/bin/bash

# Get all songs from MPD database
SONGS=$(mpc listall | sed 's/.*\///' | sed 's/\.[^.]*$//')

# Use tofi to select a song
SELECTED=$(echo "$SONGS" | tofi --prompt-text "Play: ")

if [ -n "$SELECTED" ]; then
    # Search for the song in MPD and play it
    mpc clear
    mpc search filename "$SELECTED" | head -1 | mpc add
    mpc play
fi
