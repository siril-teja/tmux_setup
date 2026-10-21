#!/usr/bin/env bash
# Install this tmux setup for the current user by linking the repo files into place, so a later `git pull` updates
# them directly. Safe to re-run. A file it would replace is first moved to <file>.bak_<timestamp>.
#   ./install.sh               install (or repair)
#   ./install.sh --uninstall   remove the links and the ~/.bashrc line (backups are left where they are)
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
stamp=$(date +%Y%m%d_%H%M%S)
links=(
    "tmux.conf:$HOME/.tmux.conf"
    "tmux/session_menu.sh:$HOME/.config/tmux/session_menu.sh"
    "tmux/status_info.sh:$HOME/.config/tmux/status_info.sh"
    "tmux/bash_functions.bash:$HOME/.config/tmux/bash_functions.bash"
)
hook='[ -f ~/.config/tmux/bash_functions.bash ] && . ~/.config/tmux/bash_functions.bash   # tmux setup (keep last)'

if [ "${1-}" = --uninstall ]; then
    for pair in "${links[@]}"; do
        dst=${pair#*:}
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$repo/${pair%%:*}" ]; then rm "$dst" && echo "removed  $dst"; fi
    done
    if grep -qxF "$hook" "$HOME/.bashrc" 2>/dev/null; then
        grep -vxF "$hook" "$HOME/.bashrc" > "$HOME/.bashrc.tmp_$stamp" && mv "$HOME/.bashrc.tmp_$stamp" "$HOME/.bashrc"
        echo "removed  the tmux line from ~/.bashrc"
    fi
    echo "Done. Any earlier files are still there as *.bak_<timestamp>."
    exit 0
fi

# tmux 3.8 or newer is required (older versions reject parts of tmux.conf)
if ! command -v tmux > /dev/null; then
    echo "WARNING: tmux is not installed -- see README.md, step 2." >&2
else
    v=$(tmux -V | grep -oE '[0-9]+\.[0-9]+' | head -1)
    if [ "$(printf '%s\n3.8\n' "$v" | sort -V | head -1)" != 3.8 ]; then
        echo "WARNING: tmux $v found, this setup needs 3.8 or newer -- see README.md, step 2." >&2
    fi
fi

mkdir -p "$HOME/.config/tmux"
chmod 755 "$repo/tmux/session_menu.sh" "$repo/tmux/status_info.sh"
for pair in "${links[@]}"; do
    src=$repo/${pair%%:*} dst=${pair#*:}
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then echo "ok       $dst"; continue; fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then mv "$dst" "$dst.bak_$stamp" && echo "backup   $dst -> $dst.bak_$stamp"; fi
    ln -s "$src" "$dst" && echo "linked   $dst -> $src"
done

if grep -qxF "$hook" "$HOME/.bashrc" 2>/dev/null; then
    echo "ok       ~/.bashrc already loads the tmux functions"
else
    cp -p "$HOME/.bashrc" "$HOME/.bashrc.bak_$stamp" 2>/dev/null && echo "backup   ~/.bashrc -> ~/.bashrc.bak_$stamp" || true
    printf '\n%s\n' "$hook" >> "$HOME/.bashrc" && echo "added    the tmux line at the end of ~/.bashrc"
fi

cat <<EOF

Installed. Next:
  - open a NEW terminal (so ~/.bashrc is re-read), then type:  tmux
  - if tmux was already running:  tmux source-file ~/.tmux.conf
  - machine-specific settings for the status readings: ~/.config/tmux/status_info.local (see README.md)
EOF
