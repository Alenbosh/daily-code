#!/bin/bash

# Custom Omarchy-style power menu with Suspend added
# Uses walker in pure dmenu mode for exact static menu look (no search bar)

entries=" Lock
󰒲 Screensaver
⏾ Suspend
 Restart
 Relaunch
 Shutdown"

chosen=$(printf "%b" "$entries" | walker --dmenu)

case "$chosen" in
  *Lock)       hyprlock ;;
  *Screensaver) omarchy-launch-screensaver ;;
  *Suspend)    systemctl suspend ;;
  *Restart)    systemctl reboot ;;
  *Relaunch)   hyprctl dispatch exit ; Hyprland ;;
  *Shutdown)   systemctl poweroff ;;
esac
