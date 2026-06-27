#!/usr/bin/env bash
#
# audiopicker.sh - a smarter audio-output switcher for Waybar (PipeWire/pactl).
#
# Improvements over a plain "set-default-sink" picker:
#   * Clean, friendly device names (strips the long controller prefix).
#   * Surfaces outputs that are hidden behind another card PROFILE
#     (e.g. laptop Speaker vs Headphones that are mutually exclusive),
#     switching the profile automatically when you pick one.
#   * Moves ALL currently-playing streams to the chosen device, so sound
#     switches immediately instead of only for new apps.
#   * Unmutes the target so you actually hear it.
#
# Menu uses rofi if available, otherwise wofi, otherwise prints to stdout.

set -uo pipefail

DELIM=$'\x1f' # unit separator, used to hide metadata in menu lines

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Non-blocking notification: backgrounded + capped, so a missing/unresponsive
# notification daemon can never hang the switcher.
notify() {
    command -v notify-send >/dev/null || return 0
    ( timeout 1 notify-send "$@" >/dev/null 2>&1 & ) 2>/dev/null
}

# Friendly label: strip the card's controller description prefix if present.
clean_name() {
    local desc="$1" prefix="$2"
    [ -n "$prefix" ] && desc="${desc#"$prefix" }"
    echo "$desc"
}

current_default() { pactl get-default-sink; }

move_all_streams() {
    local sink="$1" id
    for id in $(pactl list short sink-inputs | cut -f1); do
        pactl move-sink-input "$id" "$sink" 2>/dev/null
    done
}

activate_sink() {
    local sink="$1" label="$2"
    pactl set-default-sink "$sink"
    pactl set-sink-mute "$sink" 0 2>/dev/null
    move_all_streams "$sink"
    notify -a "Audio" -t 2000 -r 9 "Output switched" "$label"
}

# Find the real ALSA sink belonging to a card whose Description contains needle.
# Restricting to the card's device id avoids matching virtual sinks like
# "Balanced Headphones" when looking for the "Headphones" port.
find_sink_by_desc() {
    local needle="$1" card="${2:-}"
    local devid="${card#alsa_card.}"
    pactl list sinks | awk -v n="$needle" -v dev="$devid" '
        /^\tName: /        { name=$2 }
        /^\tDescription: / { sub(/^\tDescription: /,"");
            if (index($0,n) && (dev=="" || index(name,dev))) { print name; exit } }'
}

# ---------------------------------------------------------------------------
# Build the menu
# ---------------------------------------------------------------------------
# Each menu line:  "<icon> <label>"  with hidden metadata appended after DELIM:
#   sink<DELIM><sink-name>
#   prof<DELIM><card-name><DELIM><profile-name><DELIM><port-desc>

build_menu() {
    local def
    def="$(current_default)"

    # 1) Currently available sinks ------------------------------------------
    #    (use node.nick when present for a short clean name)
    pactl list sinks | awk -v def="$def" -v D="$DELIM" '
        function flush() {
            if (name != "") {
                # skip sinks whose active port is physically unavailable
                # (e.g. HDMI outputs with no monitor/cable connected)
                skip = (activeport != "" && (activeport in pa) && pa[activeport]==0)
                if (!skip) {
                    label = (nick != "") ? nick : desc
                    icon = (name == def) ? "\xef\x80\xa8" : "\xef\x80\xa6"   # default vs speaker glyph
                    printf "%s %s%s%s%s%s\n", icon, label, D, "sink", D, name
                }
            }
            name=""; desc=""; nick=""; activeport=""; delete pa
        }
        /^Sink #/                 { flush() }
        /^\tName: /               { name=$2 }
        /^\tDescription: /        { sub(/^\tDescription: /,""); desc=$0 }
        /node.nick = /            { gsub(/.*node.nick = "|".*/,""); nick=$0 }
        /^[[:space:]]+\[Out\] /   { l=$0; sub(/.*\[Out\] /,"",l); pn=l; sub(/:.*/,"",pn);
                                    pa[pn]=(index(l,"not available")>0)?0:1 }
        /Active Port: /           { ap=$0; sub(/.*\[Out\] /,"",ap); activeport=ap }
        END { flush() }
    '

    # 2) Outputs hidden behind a non-active profile -------------------------
    #    For every [Out] port whose "Part of profile(s)" line does NOT contain
    #    the active profile, offer a profile-switch entry. Profile names contain
    #    commas, so we match whole collected profile names as substrings rather
    #    than splitting on commas.
    pactl list cards | awk -v D="$DELIM" '
        function reset_card() { delete pname; delete pavail; np=0; card=""; active="" }
        /^Card #/            { reset_card() }
        /^\tName: /          { card=$2 }
        # profile header lines: 2 tabs deep and carrying "(sinks: N"
        /^\t\t[^[]/ && /\(sinks: [0-9]/ {
                                line=$0; sub(/^\t\t/,"",line)
                                nm=line; sub(/: .*/,"",nm)        # name before first ": "
                                av=(index(line,"available: no")>0)?0:1
                                np++; pname[np]=nm; pavail[np]=av
                             }
        /Active Profile: /   { sub(/.*Active Profile: /,""); active=$0 }
        /^\t\t\[Out\] /      {
                                line=$0; sub(/^\t\t\[Out\] /,"",line)
                                pdesc=line; sub(/^[^:]*: /,"",pdesc); sub(/ \(.*/,"",pdesc)
                                # skip ports that are physically unavailable (e.g. headphone jack empty)
                                want = (index(line,"not available")>0) ? 0 : 1
                             }
        /Part of profile\(s\): / {
                                if (want) {
                                    profs=$0; sub(/.*Part of profile\(s\): /,"",profs)
                                    if (index(profs, active)==0) {
                                        target=""
                                        for (i=1;i<=np;i++)
                                            if (pname[i]!=active && pavail[i] && index(profs,pname[i])>0) {
                                                target=pname[i]; break
                                            }
                                        if (target!="")
                                            printf "\xef\x80\xa6 %s (switch)%s%s%s%s%s%s%s%s\n", \
                                                   pdesc, D, "prof", D, card, D, target, D, pdesc
                                    }
                                    want=0
                                }
                             }
    '
}

# ---------------------------------------------------------------------------
# Show menu
# ---------------------------------------------------------------------------
menu="$(build_menu)"
[ -z "$menu" ] && { notify -a "Audio" "No output devices found"; exit 1; }

# strip metadata for display, keep mapping
display="$(printf '%s\n' "$menu" | sed "s/${DELIM}.*//")"

# Debug: print the raw menu (with metadata visible) and exit.
if [ "${1:-}" = "--list" ]; then
    printf '%s\n' "$menu" | cat -v
    exit 0
fi

if [ "${1:-}" = "--pick" ]; then
    # Non-interactive: match a device by substring of its label (e.g. "Speaker").
    chosen="$(printf '%s\n' "$display" | grep -F -m1 "${2:-}")"
elif command -v rofi >/dev/null; then
    chosen="$(printf '%s\n' "$display" | rofi -dmenu -i -p "Output" -theme notification 2>/dev/null)"
elif command -v wofi >/dev/null; then
    chosen="$(printf '%s\n' "$display" | wofi --dmenu -p "Output")"
else
    printf '%s\n' "$display"; exit 0
fi

[ -z "$chosen" ] && exit 0

# Find the full (metadata-bearing) line for the chosen display text.
line="$(printf '%s\n' "$menu" | grep -F -m1 "${chosen}${DELIM}")"
[ -z "$line" ] && exit 0

# Split metadata.
IFS="$DELIM" read -r _disp kind a b c <<<"$line"

case "$kind" in
sink)
    activate_sink "$a" "$chosen"
    ;;
prof)
    # a=card  b=profile  c=port-desc
    pactl set-card-profile "$a" "$b" || { notify -a "Audio" -u critical "Profile switch failed"; exit 1; }
    sleep 0.6
    sink="$(find_sink_by_desc "$c" "$a")"
    if [ -n "$sink" ]; then
        activate_sink "$sink" "$c"
    else
        notify -a "Audio" -u critical "Switched profile but no sink for: $c"
    fi
    ;;
esac
