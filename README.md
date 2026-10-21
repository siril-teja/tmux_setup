# tmux setup — mouse-first, Claude-coloured

A tmux configuration you can drive almost entirely with the mouse, built for VS Code's integrated terminal
(local or Remote SSH). Colours follow Claude's palette: orange = active / pressed, cream = keyboard focus.

**What you get**

- **Typing `tmux`**: with no session yet it asks for a name; otherwise it opens your last session with a
  clickable list of all sessions plus *New named session…*. `tmux a`, `tmux ls`, … work as usual.
- **Every new session opens with three terminals**: one full height on the left, two stacked on the right.
- **Bottom bar**:
  - `◆ session ▾` (left): switch, create, rename, detach or close sessions.
  - Window tabs (middle-left): click to switch, right-click for actions.
  - Live readings (middle): `cpu % · ram % · gpu % · marc free/total free N YOU · claude <account> 5h% / week%`.
  - `☰ menu` (right): split, zoom, new/rename window, scroll, help, close.
  - The clock, plus a `✓ copied N lines` chip after each copy.
- **Mouse**:
  - Click a terminal to activate it, drag borders to resize, scroll with the wheel.
  - Drag to select (copies to the system clipboard), middle-click pastes.
  - Right-click a terminal for its menu.
- **Keyboard**:
  - Tab on an *empty* prompt moves to the next terminal, then along the bottom bar; Enter or ↑ opens a button.
  - Tab while typing still completes.
- **`exit` detaches** instead of closing the terminal, so the session and everything in it keep running.
  `Ctrl+B` then `d` also detaches.
- **Safety**: everything that closes something asks y/n first and names what it would stop.

---

## Install on another machine — step by step

### 1. Check the basics

tmux needs Linux. **On a Windows laptop, use WSL** (do this first, then continue inside WSL):

```powershell
# in Windows PowerShell (as administrator), once; then restart and open "Ubuntu" from the Start menu
wsl --install -d Ubuntu
```

Then, in the Linux (or WSL) terminal:

```bash
bash --version | head -1     # needs bash 4 or newer
git --version                # needs git
echo $PATH | tr : '\n' | grep -x "$HOME/.local/bin" || echo "~/.local/bin is NOT on PATH (fixed in step 2)"
```

### 2. Install tmux 3.8 or newer

Distribution packages are usually too old (Ubuntu 22.04 ships 3.2a, which cannot read this config).
The easiest route is conda-forge. If you have Miniforge/conda with a `tools` environment:

```bash
conda install -n tools -c conda-forge "tmux>=3.8"
mkdir -p ~/.local/bin
ln -sf ~/miniforge3/envs/tools/bin/tmux ~/.local/bin/tmux      # makes plain `tmux` use it everywhere
```

No conda yet? Install Miniforge first (<https://github.com/conda-forge/miniforge>), then
`conda create -n tools -c conda-forge "tmux>=3.8"` and the same `ln -sf` line.

If `~/.local/bin` was not on your PATH in step 1, add this to `~/.bashrc` and open a new terminal:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Check — it must print 3.8 or higher:

```bash
hash -r; tmux -V
```

### 3. Get this repository

```bash
git clone git@github.com:<your-user>/<this-repo>.git ~/tmux_setup     # private repo: SSH key or `gh auth login`
cd ~/tmux_setup
```

### 4. Run the installer

```bash
./install.sh
```

It links the files into place (`~/.tmux.conf` and `~/.config/tmux/*`) and adds one line at the end of
`~/.bashrc`. Anything it would replace is kept as `<file>.bak_<timestamp>`. Running it again is harmless.

### 5. Machine-specific settings (status readings)

The readings in the middle of the bar find their sources automatically, and a reading whose source is missing
is simply not shown. To point them elsewhere, create `~/.config/tmux/status_info.local` (not part of the repo):

```bash
# ~/.config/tmux/status_info.local -- only the lines you need
MARC_LICENSE=27500@sv-lux-rd-001          # port@host of the MSC licence server (default shown)
LMUTIL=/path/to/MSC_Licensing/lmutil      # default: `lmutil` on PATH, else the MSC Beryllium install path
NVML_LIB=                                 # only for a driver/library mismatch; leave empty normally
PYTHON=python3                            # used to read cswap's output
```

| Reading | Needs |
|---|---|
| cpu, ram | nothing (Linux `/proc`) |
| gpu | `nvidia-smi` on PATH (NVIDIA driver; in WSL it comes from the Windows driver) |
| marc | MSC `lmutil` and a reachable licence server (VPN when off-site) |
| claude | `cswap` on PATH (`uv tool install claude-swap`) and `python3` |

### 6. VS Code (optional, recommended)

So that right-click opens tmux's menu instead of VS Code's copy/paste, set in VS Code *Settings (JSON)*:

```json
"terminal.integrated.rightClickBehavior": "nothing"
```

### 7. Try it

Open a **new** VS Code terminal and type `tmux`:

- [ ] it asks *Name for the first session* → type a name → three terminals appear, no error lines
- [ ] the bottom bar shows `◆ name ▾`, a tab, the readings, `☰ menu` and the time
- [ ] click `☰ menu` → menu opens above it; move the mouse onto an item → it stays open; click → it acts
- [ ] Tab on an empty prompt moves between the three terminals, then onto the bar
- [ ] drag over some text → `✓ copied 1 line` appears bottom right, and Ctrl+V pastes it elsewhere
- [ ] type `exit` → you are back in the plain terminal; `tmux` → the session is still there

---

## Update

```bash
cd ~/tmux_setup && git pull
tmux source-file ~/.tmux.conf      # applies to a running tmux; new terminals pick up the bash part themselves
```

## Uninstall

```bash
cd ~/tmux_setup && ./install.sh --uninstall
```

This removes the links and the `~/.bashrc` line; earlier files stay as `*.bak_<timestamp>`.

---

## Cheat sheet

| Do | How |
|---|---|
| start / come back | `tmux` (`tmux a` reattaches without the menu) |
| detach (all keeps running) | `exit`, or `Ctrl+B` then `d`, or session menu → *Detach* |
| close a terminal / window / session for real | ☰ menu → *Close terminal…* / *Close window…*; session menu → *Close session…* |
| switch terminal | click it, or Tab on an empty prompt |
| bottom bar by keyboard | Tab past the last terminal (or `Ctrl+B Tab`); Tab/arrows move, Enter or ↑ opens, Esc leaves |
| menu by keyboard | `Ctrl+B` then `o` |
| copy / paste | drag (or double/triple-click) to copy; middle-click or Ctrl+V to paste |
| plain Linux selection | hold Shift while dragging |
| help inside tmux | ☰ menu → *Help* |

## Files

| Repo file | Installed as | Role |
|---|---|---|
| `tmux.conf` | `~/.tmux.conf` | everything inside tmux: mouse, menus, colours, bar, layout, keys |
| `tmux/session_menu.sh` | `~/.config/tmux/session_menu.sh` | the session list menu; *New named session…* without duplicates |
| `tmux/status_info.sh` | `~/.config/tmux/status_info.sh` | the live readings in the middle of the bar |
| `tmux/bash_functions.bash` | `~/.config/tmux/bash_functions.bash` | `tmux` start-up menu, `exit` = detach, Tab between terminals |
| `install.sh` | — | links the above, adds the `~/.bashrc` line; `--uninstall` reverses it |

Generated at run time, safe to delete: `~/.cache/tmux_status/`.

## Troubleshooting

- **Lines like `~/.tmux.conf:NN: invalid option` or `unknown command` when tmux starts**: an old tmux is running.
  Check `tmux -V` (needs ≥ 3.8). If it is right but the error persists, run `hash -r` or open a new terminal
  (bash remembered the old path). Stop an old tmux server first: type `exit` in its terminals, or close its sessions.
- **A reading is missing from the bar**: its source is not found. See the table in step 5, then check e.g.
  `nvidia-smi`, `cswap status` or `lmutil lmstat -c <port@host>` by hand.
- **Tab no longer completes an empty command line**: intended — on an empty prompt Tab moves between terminals.
- **Right-click pastes instead of opening the menu**: VS Code setting in step 6, or use the `☰ menu` button.
- **Nothing in tmux works with the mouse**: make sure you are inside tmux (bottom bar visible) and on tmux ≥ 3.8.
