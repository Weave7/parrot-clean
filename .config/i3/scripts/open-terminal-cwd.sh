#!/bin/bash
# Open a new alacritty terminal in the cwd of the currently focused terminal.
set -uo pipefail

wid=$(i3-msg -t get_tree | jq -r '.. | select(.focused? == true and .window != null) | .window' | head -1)

pid=""
if [ -n "$wid" ]; then
    hexid=$(printf '0x%x' "$wid")
    pid=$(xprop -id "$hexid" _NET_WM_PID 2>/dev/null | awk '{print $NF}')
fi

cwd=""
if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
    walk="$pid"
    if c=$(readlink -e "/proc/$walk/cwd" 2>/dev/null); then
        cwd="$c"
    fi
    for _ in 1 2 3 4 5 6 7 8; do
        child=$(pgrep -P "$walk" 2>/dev/null | tail -1)
        [ -z "$child" ] && break
        c=$(readlink -e "/proc/$child/cwd" 2>/dev/null) || break
        walk="$child"
        cwd="$c"
    done
fi

# No focused terminal window to read from (e.g. a fresh empty workspace) --
# fall back to the last cwd any terminal recorded via the zsh chpwd hook.
if [ -z "$cwd" ] && [ -r ~/.cache/i3/last_pwd ]; then
    c=$(cat ~/.cache/i3/last_pwd 2>/dev/null)
    [ -n "$c" ] && [ -d "$c" ] && cwd="$c"
fi

[ -z "$cwd" ] && cwd="$HOME"

exec alacritty --working-directory "$cwd"
