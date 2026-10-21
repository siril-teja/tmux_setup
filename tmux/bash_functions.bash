# tmux setup -- shell side (sourced from ~/.bashrc by the line install.sh adds). Needs bash >= 4.

# tmux session picker (2026-10-21): a bare `tmux` asks for a name when no session exists yet, otherwise attaches
# and opens the session menu (every session + "New named session..."); inside tmux it just opens that menu.
# Anything with arguments (`tmux a`, `tmux ls`, ...) goes straight to tmux; `command tmux` is the plain binary.
tmux() {
    if [ $# -gt 0 ]; then command tmux "$@"; return; fi
    if [ -n "${TMUX-}" ]; then
        command tmux run-shell "~/.config/tmux/session_menu.sh menu '$(command tmux display-message -p '#{client_name}')'"
        return
    fi
    if command tmux has-session 2>/dev/null; then command tmux attach \; session-menu; return; fi
    local o=$'\e[38;2;217;119;87m' c=$'\e[38;2;240;238;230m' g=$'\e[38;2;138;136;128m' r=$'\e[0m'
    local def=${PWD##*/} name
    def=${def//[.:]/_}
    printf '%s◆ tmux%s %s· no sessions yet%s\n' "$o" "$r" "$g" "$r"
    while :; do
        # \001 \002 tell readline the colour codes take no space, so editing the name does not garble the line
        read -r -e -p $'\001'"$c"$'\002'"Name for the first session "$'\001'"$g"$'\002'"[$def]"$'\001'"$c"$'\002'": "$'\001'"$r"$'\002' name || { echo; return 1; }
        name=${name:-$def}
        [[ $name == *[.:]* ]] && { printf '%s  names cannot contain . or :%s\n' "$o" "$r"; continue; }
        break
    done
    command tmux new-session -s "$name"
}

# tmux-safe exit (2026-10-21): in a tmux pane's own shell, a bare `exit` detaches -- the session and everything
# running in it keep going (`tmux` brings it back). Outside tmux, in a shell started inside a pane, or with a
# status (`exit 1`) it is the normal exit. Closing a pane or a session for real: the ☰ / session menus (they ask first).
exit() {
    if [ $# -eq 0 ] && [ -n "${TMUX-}" ] &&
       [ "$BASHPID" = "$(command tmux display-message -p -t "${TMUX_PANE-}" '#{pane_pid}' 2>/dev/null)" ]; then
        command tmux detach-client
    else
        builtin exit "$@"
    fi
}

# tmux keyboard walk (2026-10-21): inside tmux, Tab on an EMPTY prompt moves to the next terminal (after the last
# one, into the bottom bar -- see ~/.tmux.conf), Shift+Tab to the previous one. Tab while typing still completes.
if [ -n "${TMUX-}" ] && [[ $- == *i* ]]; then
    shopt -s no_empty_cmd_completion   # Tab on an empty line no longer lists every command (it moves instead)
    _tmux_tab()  { [[ -n ${READLINE_LINE//[[:space:]]/} ]] || command tmux pane-tab-next; }
    _tmux_btab() { [[ -n ${READLINE_LINE//[[:space:]]/} ]] || command tmux pane-tab-prev; }
    # Tab = "move if the line is empty" followed by the normal completion (a no-op on an empty line)
    bind -x '"\e[9101~": _tmux_tab'
    bind '"\e[9102~": complete'
    bind '"\C-i": "\e[9101~\e[9102~"'
    bind -x '"\e[Z": _tmux_btab'
fi
