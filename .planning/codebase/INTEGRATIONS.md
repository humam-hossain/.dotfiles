# INTEGRATIONS

> How the components of the `.dotfiles` environment connect to each other and to external systems.

## Integration Map (high level)

```
arch/*.sh  ──install──▶  ~/.config/<app>/  ──read by──▶  Hyprland session
   │                         │
   │                         ├─ hyprland.conf ─exec-once─▶ waybar, swaync, hyprpaper, polkit, cliphist
   │                         ├─ waybar ──custom exec──▶ scripts/{network,system,weather,alerts}
   │                         ├─ waybar ──custom/ping──▶ ping_status.sh ──curl──▶ ping monitor (8765)
   │                         ├─ quickshell ──symlink──▶ ~/.config/quickshell (QML shell)
   │                         └─ systemd/user ──wants──▶ graphical-session.target ──▶ xdg-desktop-portal
   │
nvim ──rsync──▶ ~/.config/nvim ──lazy.nvim──▶ plugins + Mason tools
scripts/nvim-validate.sh ──headless──▶ nvim + health.json + checkhealth.txt
```

## Internal Integrations

### Hyprland ↔ Desktop services
`hyprland.conf` drives the whole session via `exec-once`:
- Boots `waybar`, `swaync`, `hyprpaper`, polkit-kde auth agent, `wl-clip-persist`, `cliphist` watchers
- Starts `hyprland-session.service` (systemd user unit) to pull up `graphical-session.target` so `xdg-desktop-portal-hyprland` (screen-share/ScreenCast) can start on a bare Hyprland TTY session
- Launches workspace-pinned apps: `google-chrome`, `kitty -e tmux`, `btop`, `vesktop`/`discord`
- Keybind `SUPER+d` invokes `~/define.sh` (dictionary); `SUPER+N` toggles swaync; `SUPER+V` opens cliphist via rofi
- `hyprshot` bound to Print Screen (window) and Shift+Print Screen (region), saving to `~/Pictures/Screenshots/`

### Waybar ↔ Ping monitor
- `arch/waybar.sh` deploys `~/.config/waybar/scripts/network/ping_status.sh`
- The `custom/ping` module polls every 5s, `curl`ing `http://127.0.0.1:8765/api/status` and returning JSON `{"text","class"}`
- CSS classes `good/medium/bad/critical/dead` color the latency
- `arch/system_monitor.sh` stands up the Docker ping server and verifies the waybar fetcher returns valid JSON
- `on-click` opens the browser UI at `http://127.0.0.1:8765/`

### Waybar ↔ Other custom modules
`~/.config/waybar/scripts/` is organized into four domains:
- `network/` — ping_status.sh
- `system/` — system metrics
- `weather/` — weather
- `alerts/` — alert notifications
- A `history.sh` is aliased as `waybar_history` in `.zshrc`
- Config: `config.jsonc` + `style.css` + `mocha.css` (Catppuccin); `PRD.md` documents the ping module

### Quickshell ↔ Hyprland / ddcutil
- `arch/quickshell.sh` symlinks `~/.config/quickshell` → repo `.config/quickshell` (single-dir symlink, unlike per-file copies elsewhere)
- Installs `quickshell`, `ddcutil`, `i2c-tools`; loads `i2c-dev` module and adds user to `i2c` group (for DDC/CI monitor control)
- `shell.qml` renders a `Bar` per screen; services (singletons) expose CPU/mem/disk/network/ping/weather/mpris/clock/backlight/workspaces/notifications/calendar; widgets consume them
- **Note**: ddcutil was implicated in the documented iGPU crash (see CONCERNS) — re-introducing it via Quickshell revives a previously problematic dependency

### Neovim ↔ External tools (Mason + system fallback)
- LSP servers provisioned Mason-first, with system-binary fallback (degrades silently if a binary is absent)
- `conform.nvim` formatters: stylua, black, isort, prettierd/prettier, clang-format, shfmt — each has an install hint surfaced only via `./scripts/nvim-validate.sh health`
- Required tools that crash on use: `git`, `rg` (enforced as failures in health check); all others are warnings

### Neovim ↔ tmux
- lualine `globalstatus = true` with `laststatus` guarded on `$TMUX`: inside tmux, nvim hides its own statusline and vim-tpipeline forwards the render to the tmux status bar; outside tmux, nvim shows its own statusline

### Shell ↔ define.sh
- `.zshrc` defines `alias define="bash $HOME/define.sh"`; `arch/define.sh` (and debian/ubuntu equivalents) copy `.config/define.sh` to `~/define.sh`
- `define.sh` reads the clipboard (`wl-paste`), queries `api.dictionaryapi.dev`, and shows definitions via `notify-send` (swaync)

### Fish ↔ Hyprland
- `auto-Hypr.fish` provides a Hyprland auto-start helper for the fish shell

## External Integrations

| Integration | Direction | Mechanism |
|-------------|-----------|-----------|
| dictionaryapi.dev | outbound | `curl` from `define.sh` |
| GitHub | outbound | `gh repo list` / `gh repo clone` in `scripts/clone_repo.sh` (bulk clones all user repos with `notify-send` progress) |
| Docker registry | outbound | `docker compose up --build` for ping monitor |
| AUR | outbound | `yay -Sy` for community packages |
| pacman / apt | outbound | distro package installs |
| xdg-desktop-portal (ScreenCast) | local IPC | systemd `graphical-session.target` bootstrap |
| wpctl (PipeWire) | local IPC | Hyprland media-key binds for volume/mute |
| playerctl | local IPC | Hyprland media-key binds for play/next/prev |
| brightnessctl | local IPC | Hyprland brightness keys |
| ddcutil / i2c | local hardware | Quickshell monitor control (brightness via DDC/CI) |
| sqlite3 | local | ping monitor history (`data/system.db`) |
| wl-paste / wl-copy / cliphist | local IPC | clipboard management |

## Provisioning Order (implicit dependency chain)

1. `necessary.sh` → base system + `define.sh` copy
2. `fonts.sh` → Nerd Fonts (needed by bars/prompts glyphs)
3. `hyprland.sh` → compositor + hyprpaper/hyprshot/hyprlock/swaync + systemd unit + swaync config
4. `waybar.sh` → bar + custom scripts (including ping_status.sh)
5. `system_monitor.sh` → Docker ping server (Waybar `custom/ping` depends on this)
6. `quickshell.sh` → alternative QML shell (symlink + ddcutil/i2c)
7. `nvim.sh` → editor + `rsync` config; then `./scripts/nvim-validate.sh all`
8. App scripts: `rofi.sh`, `kitty.sh`, `alacritty.sh`, `wezterm.sh`, `yazi.sh`, `btop.sh`, `fish.sh`, `zsh.sh`, etc.
9. `tools.sh` → misc utilities (lazygit, fastfetch, smartmontools, etc.)

Scripts are individually idempotent but **not ordered automatically** — the user runs them selectively.
