#!/usr/bin/env bash
selected=$(tofi-run)
if [ -n "$selected" ]; then
    # Check if it's a terminal app that needs a terminal
    case "$selected" in
    nvim | rmpc | btop | yazi | vim | nano)
        uwsm-app -- xdg-terminal-exec -- $selected
        ;;
    *)
        uwsm-app -- $selected
        ;;
    esac
fi
