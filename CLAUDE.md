# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for an Arch Linux (Hyprland/Wayland) system. It contains:
- **`.config/`** — Config files to be copied into `~/.config/` (and home dir)
- **`arch/`** — Bash install/setup scripts for Arch Linux
- **`ubuntu/`** — Bash install/setup scripts for Ubuntu

## How Install Scripts Work

Each script in `arch/` or `ubuntu/` is standalone and follows a consistent pattern:
1. Install packages via `sudo pacman -Sy --noconfirm --needed <pkg>` (arch) or `apt` (ubuntu)
2. Copy config files from `.config/` to the appropriate `~/` location

To run a script: `cd /home/pera/github_repo/.dotfiles && bash arch/<script>.sh`

The scripts use `set -euo pipefail` and `set -x` for strict error handling and verbose output.

Some scripts also use `yay` for AUR packages (e.g. `arch/tools.sh`, `arch/waybar.sh`).

## Config Files and Their Destinations

| Source | Destination | Status |
|--------|-------------|--------|
| `.config/nvim/` | `~/.config/nvim/` | Active |
| `.config/hypr/` | `~/.config/hypr/` | Active |
| `.config/waybar/` | `~/.config/waybar/` | Active |
| `.config/swaync/` | `~/.config/swaync/` | Active |
| `.config/kitty/kitty.conf` | `~/.config/kitty/` | Active |
| `.config/rofi/` | `~/.config/rofi/` | Active |
| `.config/btop/` | `~/.config/btop/` | Active |
| `.config/yazi/` | `~/.config/yazi/` | Active (TUI file manager) |
| `.config/.zshrc` | `~/.zshrc` | Active |
| `.config/.zprofile` | `~/.zprofile` | Active |
| `.config/.p10k.zsh` | `~/.p10k.zsh` | Active |
| `.config/.tmux.conf` | `~/.tmux.conf` | Active |
| `.config/starship.toml` | `~/.config/starship.toml` | Archived (disabled in .zshrc) |
| `.config/define.sh` | `~/define.sh` | Active |
| `.config/fish/` | `~/.config/fish/` | Archived (experimental, not default shell) |
| `.config/alacritty/` | `~/.config/alacritty/` | Archived (alternative terminal) |
| `.config/wezterm/` | `~/.config/wezterm/` | Archived (alternative terminal) |
| `.config/.Xresources` | `~/.Xresources` | Archived (xterm) |

## Hyprland Setup

- `$mainMod = SUPER` (Windows key)
- Terminal: `kitty`, File manager: `nautilus` (GUI), Launcher: `rofi -show drun`
- No display manager — `.zprofile` auto-launches Hyprland via `exec start-hyprland` on TTY1 login
- Dual monitor: DP-1 (primary, workspaces 1–5) and HDMI-A-2 (secondary, 1.5x scale, rotated 90°, workspaces 6–10)
- Cursor: `catppuccin-mocha-dark-cursors`, size 30
- Layout engine: dwindle

### Autostart
- `waybar`, `swaync`, `hyprpaper` — status bar, notifications, wallpaper
- `wl-clip-persist` + `cliphist` — clipboard persistence (text and image stored separately)
- `polkit-kde-authentication-agent-1` — GUI sudo authentication
- `gnome-keyring-daemon` — libsecret/keyring (fixes Gemini/libsecret crash)
- `google-chrome-stable` → workspace 1
- `kitty -e tmux` → workspace 1
- `kitty --class btop -e btop` → special workspace `btop`
- `discord` → special workspace `social`

### Key Bindings
| Binding | Action |
|---------|--------|
| `SUPER + Return` | Open kitty terminal |
| `SUPER + C` | Kill active window |
| `SUPER + SPACE` | Open rofi launcher |
| `SUPER + E` | Open nautilus |
| `SUPER + F` | Fullscreen |
| `SUPER + S` | Toggle floating |
| `SUPER + V` | Clipboard history (cliphist + rofi) |
| `SUPER + D` | Dictionary lookup (`~/define.sh`) |
| `SUPER + N` | Toggle swaync notification panel |
| `SUPER + W` | Restart waybar |
| `SUPER + h/j/k/l` | Move focus (vim-style) |
| `SUPER + 1–5` | Switch to workspace 1–5 (DP-1) |
| `SUPER + 6–0` | Switch to workspace 6–10 (HDMI-A-2) |
| `SUPER + ~` | Toggle special workspace: social (Discord) |
| `SUPER + -` | Toggle special workspace: btop |
| `Scroll_Lock` | Lock screen (hyprlock) |
| `PAUSE` | Screenshot window (hyprshot) |
| `SHIFT + PAUSE` | Screenshot region (hyprshot) |
| `CTRL+SUPER + h/l` | Switch to prev/next workspace |

### Window Rules
- Python GUI windows (`main.py`, `python3` class) are forced to float
- `PYOPENGL_PLATFORM=x11` set globally for Python OpenGL compatibility

## Neovim Config Architecture

The Neovim config (`~/.config/nvim/`) uses **lazy.nvim** as plugin manager:

- `init.lua` — Entry point: loads `core.options`, `core.keymaps`, then lazy.nvim which auto-discovers `lua/plugins/`
- `lua/core/options.lua` — Vim options
- `lua/core/keymaps.lua` — Global keymaps (leader = `<Space>`)
- `lua/plugins/` — One file per plugin or plugin group

### Colorscheme
- Active: **catppuccin mocha** (`catppuccin/nvim`)
- Archived alternative: `hackerman.nvim`

### LSP & Completion
- LSP managed via **mason** + mason-lspconfig + mason-tool-installer (multi-language, see `lsp.lua` for full server list)
- Completion: **blink.cmp** (replaces nvim-cmp)
- Formatting: conform.nvim (formatters installed via mason: stylua, black, isort, prettierd, clang-format, shfmt, etc.)
- **fzf-lua is used instead of Telescope** for all fuzzy finding and LSP navigation (`<leader>ff`, `<leader>fg`, `<leader>cd`, `<leader>cr`, etc.)

### Key Neovim Keymaps
| Keymap | Action |
|--------|--------|
| `<C-s>` | Save + format (conform.nvim) |
| `<C-q>` | Smart quit (close window / buffer / nvim) |
| `<C-_>` | Toggle comment |
| `jk` | Exit insert/visual mode |
| `<Tab>` / `<S-Tab>` | Next / previous buffer |
| `<leader>x` | Force close buffer |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep (includes hidden files, excludes `.git`) |
| `<leader>fc` | Find in nvim config |
| `<leader>cd` | LSP: go to definition |
| `<leader>cr` | LSP: references |
| `<leader>ca` | LSP: code action |
| `<leader>cn` | LSP: rename |
| `gl` | Open diagnostics float |
| `<leader>gp` | Gitsigns: preview hunk |
| `<leader>gt` | Gitsigns: toggle line blame |
| `<leader>v` / `<leader>h` | Split window vertically / horizontally |
| `<C-h/j/k/l>` | Navigate between splits |
| `<C-d>` / `<C-u>` | Scroll half page + center |
| `<leader>sn` | Save without formatting |
| `<C-S-o>` | Open file with default application |
| Arrow keys | Resize splits |

### Auto-save
Triggers on: FocusLost, BufLeave, InsertLeave, TextChanged (1s delay)

### Notable Plugins
- `fzf-lua` — fuzzy finder (replaces Telescope)
- `blink.cmp` — completion
- `conform.nvim` — formatting
- `nvim-lspconfig` + mason — LSP
- `gitsigns.nvim` + `vim-fugitive` + `vim-rhubarb` — git
- `neo-tree` — file tree
- `bufferline.nvim` — buffer tabs
- `lualine.nvim` — statusline
- `nvim-treesitter` — syntax/highlighting
- `nvim-ufo` — folding
- `which-key.nvim` — keymap hints
- `render-markdown.nvim` — markdown rendering
- `csvview.nvim` — CSV viewer with Excel-like navigation
- `todo-comments.nvim` — highlight TODOs
- `nvim-autopairs` — auto-close brackets/quotes
- `vim-tmux-navigator` — seamless tmux/nvim split navigation
- `alpha.nvim` — dashboard
- `comfy-line-numbers.nvim` — custom relative line numbers

## Shell (Zsh)

- Framework: **Oh My Zsh** with **Powerlevel10k** theme (active)
- Starship is installed by `arch/zsh.sh` but **disabled** in `.zshrc` — archived, not in use
- Custom plugin path: `~/.zsh/plugins/` (`$ZSH_CUSTOM=$HOME/.zsh`)
- Plugins: `git`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `sudo`
- FZF shell integration: `eval "$(fzf --zsh)"` (keybindings active)
- Fish shell config exists in `.config/fish/` — **archived/experimental**, not the default shell

### Key Aliases
| Alias | Command |
|-------|---------|
| `define` | `bash ~/define.sh` (dictionary lookup via API + notify-send) |
| `darkconda` | Activate `darkconda` conda env (miniconda3) |
| `baseconda` | Activate base conda env (miniconda3) |
| `waybar_history` | `~/.config/waybar/history.sh` |
| `ll` / `l` | `ls -lh` |
| `la` | `ls -lah` |

### PATH additions
- `~/.cargo/bin` (Rust/cargo)

### `.zprofile`
- Sets XDG env vars for Wayland/Hyprland
- Auto-launches Hyprland on TTY1: `exec start-hyprland`

## Waybar

Custom modules beyond standard waybar:
- `custom/weather` + `custom/weather2` — current and forecast weather (open-meteo API)
- `custom/ping` — network latency with history plot (gnuplot + Python)
- `custom/memory` — memory usage script
- `custom/music` — playerctl metadata (artist - title)
- `custom/backlight`, `custom/lock`, `custom/power`, `custom/notification` — controls
- Clock timezone: set in waybar config (see `config.jsonc`)
- Style: catppuccin mocha CSS (`mocha.css`)

Scripts in `.config/waybar/`: `curr_weather.sh`, `forcast_weather.sh`, `history.sh`, `memory.sh`, `ping.sh`, `earthquake.sh`, `plot_history.gp`, `plot_ping_history.py`

## Other Tools

- **btop** — system monitor (catppuccin mocha theme), launched in special workspace
- **yazi** — TUI file manager (active, used in terminal alongside nautilus)
- **tmux** — terminal multiplexer (config: `.config/.tmux.conf`), auto-started with kitty on WS1
- **rofi** — launcher + clipboard UI (catppuccin mocha theme)
- **hyprlock** — screen locker; **hypridle** — idle daemon; **hyprpaper** — wallpaper
- **lazygit** — TUI git client (installed via `arch/tools.sh`)
- **taskwarrior** — task management CLI

## Commit Convention

Commits use the format: `[UPDATE] description` (based on existing git history).
