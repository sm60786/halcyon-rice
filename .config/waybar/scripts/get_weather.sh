#!/usr/bin/env bash
# Waybar weather module via wttr.in. Optional $1 = location (defaults to IP geolocation).
for i in {1..5}; do
    text=$(curl -s "https://wttr.in/$1?format=1")
    if [[ $? == 0 && -n "$text" && "$text" != *"Unknown location"* ]]; then
        text=$(echo "$text" | sed -E "s/\s+/ /g")
        tooltip=$(curl -s "https://wttr.in/$1?format=4" | sed -E "s/\s+/ /g")
        echo "{\"text\":\"$text\", \"tooltip\":\"$tooltip\"}"
        exit
    fi
    sleep 2
done
echo "{\"text\":\"\", \"tooltip\":\"weather unavailable\"}"
