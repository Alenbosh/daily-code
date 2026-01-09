#!/bin/bash

# =========================
# Paths / State
# =========================
STATE_DIR="$HOME/.local/state/pomodoro"
STATE_FILE="$STATE_DIR/state"
END_FILE="$STATE_DIR/end"
PAUSE_FILE="$STATE_DIR/paused"
ALERT_FILE="$STATE_DIR/alerted"
LOG_FILE="$STATE_DIR/log.csv"
PID_FILE="$STATE_DIR/pid"

mkdir -p "$STATE_DIR"

# =========================
# Timings (seconds)
# =========================
FOCUS=1500
BAR=12
URGENT_AT=120

# =========================
# Helpers
# =========================
notify() {
  notify-send "Pomodoro" "$1"
  paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
}

log_focus() {
  echo "$(date +%F),25" >> "$LOG_FILE"
}

# =========================
# Core actions
# =========================
cancel_timer() {
  [ -f "$PID_FILE" ] && kill "$(cat "$PID_FILE")" 2>/dev/null
  rm -f "$PID_FILE" "$END_FILE" "$PAUSE_FILE" "$ALERT_FILE"
  echo idle > "$STATE_FILE"
  notify "Pomodoro stopped"
}

start_timer() {
  local duration=$1
  local now

  now=$(date +%s)

  echo focus > "$STATE_FILE"
  echo $((now + duration)) > "$END_FILE"
  rm -f "$PAUSE_FILE" "$ALERT_FILE"

  (
    sleep "$duration"
    notify "Focus finished"
    rm -f "$PID_FILE" "$END_FILE"
    echo idle > "$STATE_FILE"
    log_focus
  ) &

  echo $! > "$PID_FILE"
}

restart_timer() {
  cancel_timer
  start_timer "$FOCUS"
  notify "Pomodoro restarted (25 min)"
}

toggle() {
  local state now remain

  state=$(cat "$STATE_FILE" 2>/dev/null || echo idle)
  now=$(date +%s)

  case "$state" in
    idle)
      start_timer "$FOCUS"
      notify "Focus started (25 min)"
      ;;

    focus)
      # Pause
      kill "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null
      remain=$(( $(cat "$END_FILE") - now ))
      echo "$remain" > "$PAUSE_FILE"
      echo paused > "$STATE_FILE"
      notify "Paused"
      ;;

    paused)
      # Resume
      remain=$(cat "$PAUSE_FILE")
      echo $((now + remain)) > "$END_FILE"
      rm -f "$PAUSE_FILE"
      echo focus > "$STATE_FILE"
      notify "Resumed"
      ;;

    *)
      cancel_timer
      ;;
  esac
}

# =========================
# Argument handler
# =========================
case "$1" in
  toggle)  toggle; exit 0 ;;
  cancel)  cancel_timer; exit 0 ;;
  restart) restart_timer; exit 0 ;;
esac

# =========================
# Waybar display
# =========================
state=$(cat "$STATE_FILE" 2>/dev/null || echo idle)

if [ "$state" = "idle" ]; then
  echo '{"text":"🍅 Start","tooltip":"Click / Super+Shift+P to start"}'
  exit 0
fi

if [ "$state" = "paused" ]; then
  echo '{"text":"⏸ Paused","tooltip":"Paused — toggle to resume"}'
  exit 0
fi

# Running (focus)
now=$(date +%s)

[ ! -f "$END_FILE" ] && echo '{"text":"🍅 Start"}' && exit 0

end=$(cat "$END_FILE")
remain=$((end - now))
(( remain < 0 )) && remain=0

# Urgency alert (once)
if (( remain <= URGENT_AT )) && [ ! -f "$ALERT_FILE" ]; then
  notify "⏰ Less than 2 minutes left!"
  touch "$ALERT_FILE"
fi

min=$((remain / 60))
sec=$((remain % 60))

done=$(( (FOCUS - remain) * BAR / FOCUS ))
bar=$(printf "%0.s█" $(seq 1 $done))
bar+=$(printf "%0.s░" $(seq 1 $((BAR - done))))

tooltip="Time left: ${min}m ${sec}s"

echo "{\"text\":\"🍅 $bar\",\"tooltip\":\"$tooltip\",\"class\":\"focus\"}"

