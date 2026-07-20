# STACK

> Technology stack for the `.dotfiles` repository — a personal Linux desktop configuration and provisioning toolkit.

## Overview

This is **not an application** — it is a declarative personal computing environment for Arch/Debian/Ubuntu Linux, built around a Hyprland (Wayland) desktop. The "stack" is the collection of installed tools, the shell/terminal/editor ecosystem, and a small set of self-hosted services. Provisioning is driven by per-distro Bash install scripts; configuration is centralized under `.config/`.

## Languages

Tracked file distribution (≈200 files):

| Language | Count | Role |
|----------|-------|------|
| Bash | 82 | Install/provisioning scripts, helper utilities |
| QML | 37 | Quickshell desktop shell (bar/widgets/services) |
| Lua | 25 | Neovim config (core, plugins, keymaps, health) |
| Markdown | 8 | Documentation, post-mortems, PRDs |
| conf | 7 | Hyprland, btop, swaync, kitty configs |
| TOML | 5 | alacritty, yazi, starship configs |
| Python | 3 | Ping monitor server + DB migrations |
| CSS | 4 | Waybar/swaync theming (Catppuccin Mocha) |
| JSON/JSONC | 4 | Waybar, swaync, nvim luarc |
| Fish | 2 | Fish shell config |
| RASI | 2 | Rofi theme |
| YAML | 2 | smartmontools, docker-compose |

## Operating Systems

- **Primary**: Arch Linux (rolling) — most complete script set (`arch/`, 32 scripts)
- **Secondary**: Debian (`debian/`, 20 scripts) and Ubuntu (`ubuntu/`, 20 scripts) — subset feature parity
- **Kernel**: Linux 7.x (issue post-mortem references `7.1.3-arch1-3`); Intel iGPU (UHD 770) on i915 driver
- **Display server**: Wayland (Hyprland); XWayland for legacy clients

## Package Management

| Manager | Scope | Notes |
|---------|-------|-------|
| `pacman` | Arch official repos | Primary installer; always `-Sy --noconfirm --needed` |
| `yay` | AUR (Arch User Repository) | Used for non-official packages (discord, zoom, durdraw, webcamize, gnome-network-displays) |
| `apt` | Debian/Ubuntu | Used in `debian/` and `ubuntu/` scripts |
| `docker` / `docker compose` | Ping monitor service | Self-hosted containerized service |
| `pip` / `requirements.txt` | Python deps for ping monitor | Flask, etc. |
| `lazy.nvim` | Neovim plugins | Git-cloned, locked via `lazy-lock.json` |
| `Mason` | Neovim LSP/formatters | First-party provisioning with system-binary fallback |
| `luarocks` | Lua packages | Installed for nvim tooling |
| `cargo` | Rust tools (stylua) | Referenced in tool install hints |

## Shell & Terminal

- **Login shell**: Zsh via Oh My Zsh + **Powerlevel10k** prompt (`.zshrc`, `.p10k.zsh`, `.zprofile`)
  - Plugins: git, zsh-autosuggestions, zsh-syntax-highlighting, sudo
  - Starship is configured (`starship.toml`) but **disabled** in `.zshrc`
  - fzf keybindings (`eval "$(fzf --zsh)"`)
  - Conda aliases (`darkconda`, `baseconda`) referencing `~/miniconda3`
- **Alternate shell**: Fish (`config.fish`, `auto-Hypr.fish`)
- **Terminals**: kitty (primary, `$terminal`), alacritty, wezterm, xterm
- **Multiplexer**: tmux (`.tmux.conf`); nvim lualine integrates via vim-tpipeline

## Editor

- **Neovim** (0.11+ baseline) with Lua config and `lazy.nvim`
  - LSP: native `vim.lsp.config()`/`vim.lsp.enable()` (lua_ls, ty, ts_ls, rust_analyzer, gopls, clangd, marksman, bashls, jsonls, html, cssls, yamlls)
  - Completion: blink.cmp
  - Formatting: conform.nvim (format-on-save with filetype exclusions)
  - UI: snacks.nvim (notifier, dashboard, picker, lazygit, indent, scroll)
  - Statusline: lualine; tabs: bufferline; folding: ufo; git: gitsigns
  - Treesitter, which-key, render-markdown
- **Auxiliary editors**: micro, nano

## Desktop / Compositor

- **Compositor**: Hyprland (dwindle layout, Catppuccin Mocha theme, dual-monitor DP-1 + HDMI-A-2)
- **Idle/screenlock**: hypridle, hyprlock
- **Wallpaper**: hyprpaper
- **Screenshots**: hyprshot (Print Screen keybinds)
- **Status bars**: **Waybar** (primary, custom modules) and **Quickshell** (QML shell — see CONCERNS)
- **Notifications**: swaync (control center + notification daemon)
- **Launcher**: rofi (drun + clipboard history + dmenu)
- **File managers**: yazi (TUI), nautilus (GUI)
- **System monitor**: btop, fastfetch
- **Clipboard**: wl-clip-persist + cliphist (text + image)

## Self-Hosted Services

- **Ping monitor**: Dockerized Python (Flask) server with SQLite history and browser UI
  - Listens on `127.0.0.1:8765` (Arch) / `0.0.0.0:8765` (Debian/Ubuntu)
  - Waybar fetches `/api/status`; browser UI at `/`
- **systemd user units**: `hyprland-session.service` (bootstraps `graphical-session.target` for screen-share/xdg-desktop-portal)
- **smartmontools**: collector config + wrapper script

## Theming

- **Catppuccin Mocha** is the pervasive theme: Hyprland borders, cursors (`catppuccin-mocha-dark-cursors`), Waybar CSS (`mocha.css`), swaync, rofi (`catppuccin-lavrent-mocha.rasi`)

## Tooling / Developer Tools

- `git`, `lazygit`, `gh` (GitHub CLI — used by `scripts/clone_repo.sh`)
- `fzf`, `ripgrep` (rg), `fd`, `jq`, `curl`, `wget`
- `task` (taskwarrior), `dysk`, `memtester`, `caligula`, `pastel`, `wikiman`
- `distrobox`, `docker`
- `wakatime` (activity tracking) — has its own install script
- `obs-studio`, `vlc`, `libreoffice-fresh`, `qutebrowser`, `torbrowser-launcher`
- `fonts.sh` installs Nerd Fonts for the glyph-heavy bars/prompts

## Key Dependencies on External Services / APIs

- `api.dictionaryapi.dev` — `define.sh` dictionary lookup (pasted word → notification)
- GitHub (`gh`) — bulk repo cloning
- `ip route` shell expansion — ping monitor gateway target resolution
- Docker Hub / container registry — ping monitor base image
