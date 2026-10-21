#!/usr/bin/env bash
# Clickable session menu for tmux (opened from the status bar and the ☰ menu, see ~/.tmux.conf).
#   session_menu.sh menu CLIENT         open the session menu on CLIENT
#   session_menu.sh new  CLIENT NAME    move CLIENT to session NAME; create it only if no session has that name
set -u
action=$1 client=$2
self=$(readlink -f "$0")

# quote a value for a tmux double-quoted string
tq() { local s=${1//\\/\\\\}; s=${s//\"/\\\"}; s=${s//\$/\\\$}; printf '%s' "$s"; }

case $action in
menu)
    current=$(tmux display-message -p -c "$client" '#{client_session}')
    items=()
    while IFS=$'\t' read -r name windows attached; do
        label=${name//#/##}                                   # '#' would be read as a format
        [[ $name == "$current" ]] && label="> $label" || label="  $label"
        label+="   ($windows window$([[ $windows == 1 ]] || echo s)$([[ $attached -gt 0 && $name != "$current" ]] && echo ', open elsewhere'))"
        items+=("$label" "" "switch-client -t \"=$(tq "$name")\"")
    done < <(tmux list-sessions -F '#{session_name}	#{session_windows}	#{session_attached}')
    items+=(""
        "New named session..." "" "command-prompt -p \"New session name:\" { run-shell \"$(tq "$self") new $(tq "$client") '%%'\" }"
        "Rename this session..." "" "command-prompt -I \"#S\" -p \"Session name:\" { rename-session -- \"%%\" }"
        "Browse with preview..." "" "choose-tree -Zs"
        "Detach (session keeps running)" "" "detach-client"
        ""
        "Close session #S..." "" "confirm-before -p \"Close session #S? Stops everything running in its #{session_windows} window(s). (y/n)\" kill-session")
    tmux display-menu -O -M -c "$client" -T "#[align=centre] sessions " -x 0 -y "#{e|-:#{popup_status_line_y},1}" "${items[@]}"
    ;;
new)
    name=${3-}
    if [[ -z $name || $name == *[.:]* || $name == *"'"* ]]; then
        tmux display-message -c "$client" "Session name must not be empty or contain . : or '"
    elif tmux has-session -t "=$name" 2>/dev/null; then
        tmux switch-client -c "$client" -t "=$name"
        tmux display-message -c "$client" "Session '$name' already exists: switched to it"
    else
        dir=$(tmux display-message -p -c "$client" '#{pane_current_path}')
        tmux new-session -d -s "$name" -c "$dir" && tmux switch-client -c "$client" -t "=$name"
    fi
    ;;
esac
