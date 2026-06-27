#!/usr/bin/env bash
#
# audiopicker.sh - a smarter audio device switcher for Waybar (PipeWire/pactl).
#
# Works for both OUTPUT (sinks) and INPUT (sources):
#   audiopicker.sh            # pick an output device (default)
#   audiopicker.sh --input    # pick an input (microphone) device
#
# Features:
#   * Clean, friendly device names.
#   * Marks the currently-selected device with a ● bullet.
#   * Surfaces devices hidden behind another card PROFILE (e.g. laptop Speaker
#     vs Headphones) and switches the profile automatically when picked.
#   * Moves ALL active streams to the chosen device (instant switch).
#   * Hides physically-unavailable devices (empty HDMI / headphone jack) and
#     monitor sources.
#
# Extra flags: --list (debug dump), --pick "<label substring>" (non-interactive).
# Menu uses rofi, else wofi, else stdout.

set -uo pipefail

DELIM=$'\x1f'        # unit separator: hides metadata in menu lines
CUR=$'\u25cf'        # ● marker for the currently-selected device

# ---------------------------------------------------------------------------
# Parse args
# ---------------------------------------------------------------------------
MODE="output"; ACTION="menu"; PICKARG=""
while [ $# -gt 0 ]; do
    case "$1" in
        --input|-i)  MODE="input" ;;
        --output|-o) MODE="output" ;;
        --list)      ACTION="list" ;;
        --pick)      ACTION="pick"; PICKARG="${2:-}"; shift ;;
    esac
    shift
done

# ---------------------------------------------------------------------------
# Mode-specific configuration
# ---------------------------------------------------------------------------
if [ "$MODE" = "input" ]; then
    KIND="sources"; BLOCK="Source"; DIR="In"; NOUN="Input"; APP="Microphone"
    ICON=$'\uf130'                      # microphone glyph
    GET_DEFAULT="get-default-source"; SET_DEFAULT="set-default-source"
    STREAMS="source-outputs"; MOVE="move-source-output"; SETMUTE="set-source-mute"
    SKIP_MONITORS=1; UNMUTE=0
else
    KIND="sinks"; BLOCK="Sink"; DIR="Out"; NOUN="Output"; APP="Audio"
    ICON=$'\uf028'                      # speaker glyph
    GET_DEFAULT="get-default-sink"; SET_DEFAULT="set-default-sink"
    STREAMS="sink-inputs"; MOVE="move-sink-input"; SETMUTE="set-sink-mute"
    SKIP_MONITORS=0; UNMUTE=1
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
notify() {
    command -v notify-send >/dev/null || return 0
    ( timeout 1 notify-send "$@" >/dev/null 2>&1 & ) 2>/dev/null
}

current_default() { pactl "$GET_DEFAULT"; }

move_all_streams() {
    local target="$1" id
    for id in $(pactl list short "$STREAMS" | cut -f1); do
        pactl "$MOVE" "$id" "$target" 2>/dev/null
    done
}

activate_device() {
    local dev="$1" label="$2"
    pactl "$SET_DEFAULT" "$dev"
    [ "$UNMUTE" = 1 ] && pactl "$SETMUTE" "$dev" 0 2>/dev/null
    move_all_streams "$dev"
    notify -a "$APP" -t 2000 -r 9 "$NOUN switched" "$label"
}

# Find the real ALSA device of a card whose Description contains needle.
find_device_by_desc() {
    local needle="$1" card="${2:-}"
    local devid="${card#alsa_card.}"
    pactl list "$KIND" | awk -v n="$needle" -v dev="$devid" '
        /^\tName: /        { name=$2 }
        /^\tDescription: / { sub(/^\tDescription: /,"");
            if (index($0,n) && (dev=="" || index(name,dev))) { print name; exit } }'
}

# ---------------------------------------------------------------------------
# Build the menu
# ---------------------------------------------------------------------------
build_menu() {
    local def; def="$(current_default)"

    # 1) Currently available devices
    pactl list "$KIND" | awk -v def="$def" -v D="$DELIM" -v dir="$DIR" \
                              -v icon="$ICON" -v cur="$CUR" -v block="$BLOCK" \
                              -v skipmon="$SKIP_MONITORS" '
        function flush() {
            if (name != "") {
                ismon = (skipmon && index(name,".monitor"))
                skip  = (activeport != "" && (activeport in pa) && pa[activeport]==0)
                if (!ismon && !skip) {
                    label = (nick != "") ? nick : desc
                    mark  = (name == def) ? (" " cur) : ""
                    printf "%s %s%s%s%s%s%s\n", icon, label, mark, D, "dev", D, name
                }
            }
            name=""; desc=""; nick=""; activeport=""; delete pa
        }
        $0 ~ ("^" block " #")            { flush() }
        /^\tName: /                      { name=$2 }
        /^\tDescription: /               { sub(/^\tDescription: /,""); desc=$0 }
        /node.nick = /                   { gsub(/.*node.nick = "|".*/,""); nick=$0 }
        $0 ~ ("^[[:space:]]+\\[" dir "\\] ") {
                                           l=$0; sub(".*\\[" dir "\\] ","",l);
                                           pn=l; sub(/:.*/,"",pn);
                                           pa[pn]=(index(l,"not available")>0)?0:1 }
        /Active Port: /                  { ap=$0; sub(".*\\[" dir "\\] ","",ap); activeport=ap }
        END { flush() }
    '

    # 2) Devices hidden behind a non-active profile
    pactl list cards | awk -v D="$DELIM" -v dir="$DIR" -v icon="$ICON" '
        function reset_card() { delete pname; delete pavail; np=0; card=""; active="" }
        /^Card #/            { reset_card() }
        /^\tName: /          { card=$2 }
        /^\t\t[^[]/ && /\(sinks: [0-9]/ {
                                line=$0; sub(/^\t\t/,"",line)
                                nm=line; sub(/: .*/,"",nm)
                                av=(index(line,"available: no")>0)?0:1
                                np++; pname[np]=nm; pavail[np]=av
                             }
        /Active Profile: /   { sub(/.*Active Profile: /,""); active=$0 }
        $0 ~ ("^\t\t\\[" dir "\\] ") {
                                line=$0; sub("^\t\t\\[" dir "\\] ","",line)
                                pdesc=line; sub(/^[^:]*: /,"",pdesc); sub(/ \(.*/,"",pdesc)
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
                                            printf "%s %s (switch)%s%s%s%s%s%s%s\n", \
                                                   icon, pdesc, D, "prof", D, card, D, target, D, pdesc
                                    }
                                    want=0
                                }
                             }
    '
}

# ---------------------------------------------------------------------------
# Show menu / act
# ---------------------------------------------------------------------------
menu="$(build_menu)"
[ -z "$menu" ] && { notify -a "$APP" "No $NOUN devices found"; exit 1; }

display="$(printf '%s\n' "$menu" | sed "s/${DELIM}.*//")"

case "$ACTION" in
list) printf '%s\n' "$menu" | cat -v; exit 0 ;;
pick) chosen="$(printf '%s\n' "$display" | grep -F -m1 "$PICKARG")" ;;
*)
    if command -v rofi >/dev/null; then
        chosen="$(printf '%s\n' "$display" | rofi -dmenu -i -p "$NOUN" -theme "$HOME/.config/rofi/audiopicker.rasi" 2>/dev/null)"
    elif command -v wofi >/dev/null; then
        chosen="$(printf '%s\n' "$display" | wofi --dmenu -p "$NOUN")"
    else
        printf '%s\n' "$display"; exit 0
    fi
    ;;
esac

[ -z "$chosen" ] && exit 0

line="$(printf '%s\n' "$menu" | grep -F -m1 "${chosen}${DELIM}")"
[ -z "$line" ] && exit 0

IFS="$DELIM" read -r _disp kind a b c <<<"$line"

case "$kind" in
dev)
    activate_device "$a" "$chosen"
    ;;
prof)
    pactl set-card-profile "$a" "$b" || { notify -a "$APP" -u critical "Profile switch failed"; exit 1; }
    sleep 0.6
    dev="$(find_device_by_desc "$c" "$a")"
    if [ -n "$dev" ]; then
        activate_device "$dev" "$c"
    else
        notify -a "$APP" -u critical "Switched profile but no device for: $c"
    fi
    ;;
esac
