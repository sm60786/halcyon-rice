#!/usr/bin/env bash
# Automatic time-of-day night light, layered on HyDE's hyprsunset.
# Warm in the evening, neutral during the day. Only acts on transitions,
# so manual toggles from the Waybar module are respected in between.

export waybar_temperature_notification=false   # silence per-change popups

day_temp=6500       # neutral daylight
evening_temp=4000   # warm
evening_hour=18     # go warm at/after 18:00
morning_hour=7      # back to neutral at/after 07:00

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/hyde/auto-sunset.period"
mkdir -p "$(dirname "$state_file")"

apply() {
    local period="$1" temp="$2"
    [ "$(cat "$state_file" 2>/dev/null)" = "$period" ] && return
    hyde-shell hyprsunset --cm temp -s "$temp" -P waybar:19 >/dev/null 2>&1
    echo "$period" >"$state_file"
}

while true; do
    h=$(date +%-H)
    if [ "$h" -ge "$evening_hour" ] || [ "$h" -lt "$morning_hour" ]; then
        apply night "$evening_temp"
    else
        apply day "$day_temp"
    fi
    sleep 300
done
