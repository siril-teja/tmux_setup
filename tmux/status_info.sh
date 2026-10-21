#!/usr/bin/env bash
# Live readings for the middle of the tmux status bar (status-format[0] in ~/.tmux.conf), run every status-interval.
# Grey chips; a chip turns orange when it needs attention. The licence server and cswap are asked at most once a
# minute (cached in ~/.cache/tmux_status); CPU, RAM and GPU are read fresh each time (a few ms).
set -u

# Machine settings. Override any of them in ~/.config/tmux/status_info.local (plain `NAME=value` lines, not in git).
# A reading whose source is missing on a machine is simply left out of the bar.
LMUTIL=$(command -v lmutil || echo /msc/MSC.Software/MSC_Licensing/Beryllium/lmutil)   # MSC FlexLM tool
MARC_LICENSE=27500@sv-lux-rd-001                                                       # port@host of the licence server
NVML_LIB=$HOME/miniforge3/envs/tools/opt/nvml_535.288.01/lib   # only if nvidia-smi reports a driver/library mismatch
PYTHON=$(command -v python3 || echo python3)                   # reads cswap's JSON
[ -f "$HOME/.config/tmux/status_info.local" ] && . "$HOME/.config/tmux/status_info.local"

cache=${XDG_CACHE_HOME:-$HOME/.cache}/tmux_status
mkdir -p "$cache"
grey='#[fg=#8a8880]' hot='#[fg=#d97757,bold]' dot='#[fg=#3d3d3a]  ·  '

chip() { [ "$1" = 1 ] && printf '%s%s#[default]' "$hot" "$2" || printf '%s%s#[default]' "$grey" "$2"; }
# cached NAME SECONDS CMD... : CMD's output, re-run only when the cached copy is older than SECONDS
cached() {
    local f=$cache/$1 max=$2; shift 2
    if [ ! -s "$f" ] || [ $(( $(date +%s) - $(stat -c %Y "$f") )) -ge "$max" ]; then
        "$@" > "$f.tmp" 2>/dev/null && mv "$f.tmp" "$f"
    fi
    cat "$f" 2>/dev/null
}

# CPU: share of all cores busy since the previous run (from /proc/stat); RAM: share in use (MemAvailable
# counts reclaimable cache as free)
read -r _ u n s i w q sq st _ < /proc/stat
busy=$(( u + n + s + q + sq + st )); total=$(( busy + i + w ))
read -r pbusy ptotal < "$cache/cpu_prev" 2>/dev/null || { pbusy=0; ptotal=0; }
echo "$busy $total" > "$cache/cpu_prev"
cpu=$(( total > ptotal ? (busy - pbusy) * 100 / (total - ptotal) : 0 ))
ram=$(awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {printf "%d", (t-a)*100/t}' /proc/meminfo)
out="$(chip "$([ "$cpu" -gt 90 ] && echo 1)" "cpu $cpu%")"
out+="$dot$(chip "$([ "$ram" -gt 90 ] && echo 1)" "ram $ram%")"

# GPU: plain nvidia-smi; if that fails (driver/library mismatch), retry with the NVML library in NVML_LIB
q=(--query-gpu=utilization.gpu --format=csv,noheader,nounits)
g=$(nvidia-smi "${q[@]}" 2>/dev/null) ||
    g=$(LD_LIBRARY_PATH=$NVML_LIB nvidia-smi "${q[@]}" 2>/dev/null) || g=
g=${g%%$'\n'*}
[ -n "$g" ] && out+="$dot$(chip "$([ "$g" -gt 80 ] && echo 1)" "gpu $g%")"

# Marc: free MARC seats, and how many of them are held by me (my running jobs), e.g. "marc 4/4 free 0 SDI"
[ -x "$LMUTIL" ] && lm=$(cached marc 60 "$LMUTIL" lmstat -f MARC -c "$MARC_LICENSE") || lm=
if [[ $lm =~ Total\ of\ ([0-9]+)\ licenses?\ issued\;\ +Total\ of\ ([0-9]+)\ licenses?\ in\ use ]]; then
    free=$(( BASH_REMATCH[1] - BASH_REMATCH[2] ))
    mine=$(grep -cE "^ +$USER " <<< "$lm")
    out+="$dot$(chip "$([ "$free" -eq 0 ] && echo 1)" "marc $free/${BASH_REMATCH[1]} free $mine ${USER^^}")"
fi

# Claude: active cswap account alias with 5-hour / weekly usage, e.g. "claude work  36% / 98%"
if command -v cswap > /dev/null; then
    c=$(cached claude 60 cswap status --json | "$PYTHON" -I -c '
import json, sys
a = json.load(sys.stdin)["active"]
u = a.get("usage") or {}
pct = lambda w: "" if (u.get(w) or {}).get("pct") is None else str(int(u[w]["pct"]))
print(a.get("alias") or a["email"].split("@")[0], pct("fiveHour"), pct("sevenDay"), sep="\t")' 2>/dev/null)
    if [ -n "$c" ]; then
        IFS=$'\t' read -r name h5 d7 <<< "$c"
        # only a percentage at 90% or more turns orange, not the whole chip
        out+="$dot${grey}claude $name  $(chip "$([ "${h5:-0}" -ge 90 ] && echo 1)" "${h5:-?}%")${grey} / $(chip "$([ "${d7:-0}" -ge 90 ] && echo 1)" "${d7:-?}%")"
    fi
fi

printf '%s' "$out"
