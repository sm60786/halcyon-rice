#!/usr/bin/env bash
# Toggle HyDE's "paper" reading-mode screen shader on/off.
# Uses HyDE's own shader pipeline so it survives theme reloads.

conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/shaders.conf"
current=$(awk -F'"' '/^\$SCREEN_SHADER /{print $2}' "$conf")

if [ "$current" = "paper" ]; then
    name="disable"; state="OFF"
else
    name="paper"; state="ON"
fi

sed -i \
    -e "s|^\$SCREEN_SHADER .*|\$SCREEN_SHADER = \"$name\"|" \
    -e "s|^\$SCREEN_SHADER_PATH .*|\$SCREEN_SHADER_PATH = \"\$XDG_CONFIG_HOME/hypr/shaders/$name.frag\"|" \
    "$conf"

hyde-shell shaders.sh --reload >/dev/null 2>&1
notify-send -a "HyDE Notify" -r 20 -t 1200 -i preferences-desktop-display "Reading mode: $state" 2>/dev/null
