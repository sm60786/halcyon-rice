#!/usr/bin/env bash
# Rofi web search: type a query, opens it in your default browser.

theme="$HOME/.config/rofi/search.rasi"

# Toggle: if rofi is already open, close it.
if pgrep -x rofi >/dev/null; then
    pkill rofi
    exit 0
fi

query=$(printf '' | rofi -dmenu -theme "$theme" -p "Search") || exit 0
[ -z "$query" ] && exit 0

# URL-encode spaces; let the browser handle the rest.
encoded=$(printf '%s' "$query" | sed 's/ /+/g')
xdg-open "https://www.google.com/search?q=${encoded}"
