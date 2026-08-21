# Technology Stack

**Analysis Date:** 2026-08-21

## Languages

**Primary:**
- Bash (GNU bash, `#!/usr/bin/env bash`, `set -euo pipefail`) — first-party installers in `arch/*.sh`, `debian/*.sh`, `ubuntu/*.sh`; wrapper `arch/dots-hyprland.sh`; validation in `scripts/*.sh`
- Hyprland config language (`.conf` keywords) — personal compositor in `.config/hypr/hyprland.conf`, `hypridle.conf`, `hyprlock.conf`, `hyprpaper.conf`
- Lua 5.1 / LuaJIT (Neovim) — `stow/nvim/.config/nvim/` (`init.lua`, `lua/core/`, `lua/plugins/`)
- Lua (WezTerm) — `stow/wezterm/.config/wezterm/wezterm.lua`
- Hyprland Lua (ii session entry + `custom/*.lua` overlays) — **upstream** `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` requires `custom.env` / `custom.execs` / `custom.general` / `custom.rules` / `custom.keybinds` when those files exist under live `~/.config/hypr/custom/`. Parent-repo authoring tree `.config/hypr/custom/` is **not present** yet.

**Secondary:**
- Python 3 (stdlib-only asserts; CPython 3.14 bytecode present as `scripts/__pycache__/*.cpython-314.pyc`) — `scripts/phase02-config-assert.py`, `scripts/phase03-config-assert.py`, `scripts/phase04-ipc-reload-assert.py`
- JSON — Neovim lock `stow/nvim/.config/nvim/lazy-lock.json`; live ii config `~/.config/illogical-impulse/config.json` (asserted, not vendored as product)
- Fish shell — `stow/fish/.config/fish/` plus Fisher plugins installed by `arch/fish.sh`
- TOML / YAML / CSS — Alacritty, Kitty, Waybar, SwayNC, Rofi, smartmontools collector (`stow/smartmontools/.config/smartmontools/collector.yml`)
- QML / Quickshell — **upstream only** under `vendor/dots-hyprland` (illogical-impulse shell). Do not treat as first-party product code.

**Not present in first-party tree:**
- No `package.json`, `Cargo.toml`, `go.mod`, or `pyproject.toml` at repo root. Go/JDK/Node appear only as **packages installed by scripts** (`arch/tools.sh`, `debian/gemini.sh`), not as this repo’s build graph.

## Runtime

**Environment:**
- Arch Linux (primary): pacman + AUR helper `yay` (`arch/aur.sh` clones `https://aur.archlinux.org/yay-bin`)
- Hyprland Wayland session; dual-run bar: personal `waybar` + upstream `qs -c ii` (Quickshell)
- Debian / Ubuntu installer mirrors in `debian/` and `ubuntu/` (apt); Hyprland/ii wrapper is **Arch-only** (`docs/dots-hyprland-workflow.md`)
- systemd-boot / Limine documented in `arch/README.md` and `arch/necessary.sh` (`limine`, `efibootmgr`, `intel-ucode`)
- User systemd: `stow/systemd` deployed from `arch/hyprland.sh` (`systemctl --user daemon-reload`)
- PipeWire user services: `arch/audio.sh`

**Package Manager:**
- Arch: `pacman` (`-Sy --noconfirm --needed`; avoid unattended `-Syu` in targeted scripts) + `yay` for AUR
- Debian/Ubuntu: `apt` / `apt-get`
- Config deploy: **GNU Stow** from `stow/<package>` with `stow -v=5 -t ~ <pkg>` (pattern in `arch/nvim.sh`, `arch/hyprland.sh`, `arch/fish.sh`, `arch/define.sh`)
- Python tools: `pipx` (`arch/python3.sh`, `arch/hermit.sh`)
- Neovim plugins: **lazy.nvim** (`stow/nvim/.config/nvim/init.lua`)
- Fish plugins: **Fisher** (`arch/fish.sh`)
- tmux plugins: TPM (`debian/tmux.sh` clones `tmux-plugins/tpm`)
- Lockfile: Neovim `stow/nvim/.config/nvim/lazy-lock.json` present; no npm/pip lock for first-party code. Upstream Python deps live in `vendor/dots-hyprland/sdata/uv/requirements.txt` (submodule).

## Frameworks

**Core:**
- Hyprland + ecosystem (`hyprpaper`, `hyprlock`, `hypridle`, `hyprshot`, `hyprpicker`, `hyprsunset`, `hyprcursor`) — `arch/hyprland.sh`
- XDG desktop portals (`xdg-desktop-portal-hyprland`, `-wlr`, `-gtk`) — `arch/hyprland.sh`
- GNU Stow — config linking
- illogical-impulse / dots-hyprland — **submodule** `vendor/dots-hyprland` (fork `git@github.com:humam-hossain/dots-hyprland.git`); install only via `arch/dots-hyprland.sh` wrapping `vendor/dots-hyprland/setup`
- Quickshell (`qs -c ii`) — upstream desktop shell; hooks in personal hypr: `exec-once = qs -c ii` and `env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv`

**Testing:**
- No Jest/Vitest/pytest project. Validation is **bash/python assert scripts** in `scripts/` (phase smoke, nvim validate). Use `python3` stdlib (`json`, `pathlib`) for config asserts.

**Build/Dev:**
- Neovim 0.12-style LSP: `vim.lsp.config()` / `vim.lsp.enable()` + `nvim-lspconfig` + Mason (`stow/nvim/.config/nvim/lua/plugins/lsp.lua`)
- tree-sitter-cli + luarocks + python-pynvim — `arch/nvim.sh`
- Docker / docker-compose / buildx — `arch/tools.sh`, `debian/docker.sh`
- CMake, Go, Gradle, JDK 8 — optional toolchain via `arch/tools.sh`
- TeX Live (XeTeX) — `arch/latex.sh`

## Key Dependencies

**Critical (session / dual-run — keep explicit; listed in `arch/dots-hyprland.sh` `PROTECT_EXPLICIT`):**
- `hyprland` and hypr-* tools — compositor
- `waybar`, `kitty`, `swaync`, `fish`, `starship`, `eza` — personal stack
- `cliphist`, `wl-clipboard`, `jq`, `bc`, `python`, `playerctl`, `pavucontrol`, `networkmanager`, `btop`, `nautilus`
- `pipewire` / `wireplumber` — audio
- `bluez` / `blueman` — bluetooth (`arch/bluetooth.sh`)
- Nerd fonts (`ttf-jetbrains-mono-nerd`, Font Awesome, Material Symbols, Noto) — `arch/fonts.sh` / protect list

**Infrastructure:**
- `stow`, `git`, `rsync`, `fd`, `fzf`, `ripgrep`, `neovim` — core CLI
- `docker` — Scrutiny (`arch/scrutiny.sh`) and ping-viz (`debian/system_monitor.sh`)
- `github-cli` (`gh`) — `arch/tools.sh`, `scripts/clone_repo.sh`
- `yay` — AUR (`google-chrome`, `visual-studio-code-bin`, `gnome-network-displays`, etc.)

**Editors / terminals (stow packages):**
- Neovim lazy specs: blink.cmp, bufferline, conform, treesitter, lualine, snacks, ufo, mason — `stow/nvim/.config/nvim/lua/plugins/`
- Alacritty, Kitty, WezTerm, xterm — matching `arch/*.sh` + `stow/`
- Rofi, Yazi, btop, qBittorrent, system_monitor — `stow/`

## Configuration

**Environment:**
- XDG: `XDG_CONFIG_HOME` (default `~/.config`), `XDG_DATA_HOME`, `XDG_STATE_HOME` — used by `arch/dots-hyprland.sh`
- `II_CONFDIR` = `$XDG_CONFIG_HOME/illogical-impulse`
- `BACKUP_DIR` / `~/ii-original-dots-backup` — upstream file backup on install
- `ILLOGICAL_IMPULSE_VIRTUAL_ENV=~/.local/state/quickshell/.venv` — Quickshell Python venv (upstream)
- WakaTime: `$HOME/.wakatime.cfg` written by `arch/wakatime.sh` (do not commit keys)
- `.gitignore` ignores `.config/system_monitor/ping/.env`, `.claude/`, `.commandcode/`, qBittorrent state
- No first-party `.env` committed; note existence of ignored ping `.env` only

**Build:**
- No compiler project at root
- Nested submodule init required: `git submodule update --init --recursive` (vendor has nested shapes/rounded-polygon)
- Wrapper safe defaults for `install` / `install-files`: `--core --skip-hyprland --skip-sysupdate` unless `--full`

## Platform Requirements

**Development:**
- Arch Linux (documented primary); git + **SSH to GitHub** for origin and submodule fork
- AUR helper `yay` for upstream ii setup
- Running Hyprland session with personal `~/.config/hypr` owned by this repo’s `.config/hypr` (wrapper default `--skip-hyprland` does not replace `hyprland.conf`)
- `sudo` for pacman; user in `wheel`, plus `i2c` for ddcutil (`arch/hyprland.sh`)
- Stow from `stow/` with `$HOME` as target

**Production:**
- Personal workstation (not a deployed SaaS). Live ii product is **real files** under `~/.config/quickshell`, not a symlink into this repo (`docs/dots-hyprland-workflow.md`)
- Debian/Ubuntu scripts for non-Hypr tooling only
- Intel graphics stack in `arch/necessary.sh` (`intel-media-driver`, `libva-intel-driver`); microcode `intel-ucode`

---

*Stack analysis: 2026-08-21*
