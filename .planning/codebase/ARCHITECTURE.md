# ARCHITECTURE

> Architectural patterns and design decisions of the `.dotfiles` repository.

## Nature of the System

This is a **declarative personal desktop environment**, not a runtime application. There is no build artifact, no deploy target beyond the user's home directory, and no long-running process except the self-hosted ping monitor. The architecture is best understood as three layers:

1. **Provisioning layer** — per-distro Bash scripts that install packages and deploy configs
2. **Configuration layer** — declarative config files under `.config/` consumed by their respective applications at runtime
3. **Service layer** — a small set of daemons/containers (ping monitor, systemd user units, desktop services)

## Provisioning Architecture

### Per-distro script sets
Three parallel script trees mirror the same intent for different package managers:

```
arch/    (32 scripts)  — pacman + yay (AUR)        [most complete]
debian/  (20 scripts)  — apt                       [subset]
ubuntu/  (20 scripts)  — apt                       [subset, ~= debian]
```

Each tree contains a `define.sh` (copies the dictionary script to `~/`) and topical installers (`necessary.sh`, `fonts.sh`, `hyprland.sh`, `nvim.sh`, `waybar.sh`, `rofi.sh`, `kitty.sh`, etc.). Arch has the fullest set (adds `audio.sh`, `aur.sh`, `bluetooth.sh`, `wifi.sh`, `google_chrome.sh`, `vscode.sh`, `wakatime.sh`, `zsh_powerlevel.sh`, `scrutiny.sh`, `nautilus.sh`, `obs_studio.sh`, `python3.sh`, `quickshell.sh`, `system_monitor.sh`).

### Two script generations

| Generation | Example | Style |
|------------|---------|-------|
| **Legacy** | `arch/nvim.sh`, `arch/hyprland.sh`, `arch/tools.sh` | Linear top-to-bottom; `set -euo pipefail` + `set -x`; `[LABEL] message` echos; inline `cp -rf .config/<app>/* ~/.config/<app>/` |
| **Structured** | `arch/quickshell.sh`, `arch/system_monitor.sh` | `REPO_ROOT` resolved via `BASH_SOURCE`; `PACKAGES` array; `main()` dispatcher calling `install_*` / `setup_*` / `sync_*` / `verify` / `print_summary` functions |

The structured generation adds an explicit **verify step** that asserts the install succeeded (command-in-PATH, file/symlink existence, HTTP endpoint responding, JSON schema checks).

### Config deployment mechanisms (mixed)
- **Per-file copy**: `cp -rf .config/<app>/* ~/.config/<app>/` (hypr, swaync, etc.)
- **rsync with delete**: `rsync -a --delete .config/nvim/ ~/.config/nvim/` (nvim — mirror exactly)
- **Single-directory symlink**: `ln -s $QS_SRC $QS_DST` (quickshell — live-edits the repo)
- **Single-file copy**: `cp .config/define.sh ~`

## Neovim Config Architecture (most complex subsystem)

```
.config/nvim/
├── init.lua                 — bootstrap: options, keymaps, TSNode guard, lazy.nvim clone+setup
├── .luarc.json              — LuaJIT, vim global
├── lazy-lock.json           — pinned plugin versions
└── lua/
    ├── core/
    │   ├── options.lua      — editor defaults
    │   ├── keymaps.lua      — loads the keymap subsystem
    │   ├── keymaps/         — declarative keymap registry (see below)
    │   ├── health.lua       — core.health.snapshot() → health.json
    │   └── open.lua         — external open (vim.ui.open)
    ├── config/
    │   └── health.lua       — :checkhealth config interactive provider
    └── plugins/             — 13 lazy.nvim specs (lsp, blink-cmp, conform, treesitter,
                               git, colortheme, lualine, ufo, snacks, misc, bufferline,
                               project, vim-indent-object)
```

### Central keymap architecture
A declarative registry is the single source of truth for all user mappings:

```
lua/core/keymaps/
├── registry.lua   — declarations: {id, lhs, mode, desc, domain, scope, plugin, action}
├── apply.lua      — applies global mappings at startup
├── lazy.lua       — compiles lazy.nvim keys specs from the registry
├── attach.lua     — applies buffer-local mappings on LSP attach
└── whichkey.lua   — registers which-key groups
```

Rule: **plugin specs must NOT define inline `keys = {}`** — they consume the registry via `require("core.keymaps.lazy").*_keys()`. Domain prefixes (`<leader>f` search, `c` code, `g` git, `e` explorer, `b` buffers, `w` windows, `t` toggles, `s` save) organize mappings.

### Validation-as-architecture
The nvim config treats headless validation as a first-class architectural concern:
- `scripts/nvim-validate.sh` orchestrates 7 subcommands (`startup`, `sync`, `smoke`, `health`, `checkhealth`, `keymaps`, `formats`, `all`) against the repo config via `--cmd "set rtp^=$REPO_ROOT/.config/nvim"`
- `core.health.snapshot()` emits a JSON schema (neovim_version, plugins[], tools[], lazy) to `.planning/tmp/nvim-validate/health.json`
- Regression probes (`keymaps`, `formats`) directly call extracted functions with synthetic buffers to catch Phase 7/10 class bugs
- Policy: missing tools degrade **silently** at runtime; surfaced only via the health command (graceful degradation, D-07)

## Quickshell Architecture (QML desktop shell)

> **Status**: tracked in git HEAD but currently **deleted in the working tree** (39 unstaged deletions). Described here from the committed state. See CONCERNS.

```
.config/quickshell/
├── shell.qml          — Scope { Bar {} } entry point
├── Bar.qml            — Variants over screens → BarContent
├── BarContent.qml, BarGroup.qml, ModulePill.qml
├── theme/Colours.qml  — singleton (Catppuccin)
├── services/          — 14 singletons (Audio, Mpris, HyprWorkspaces, Cpu, Memory, Disk,
│                        Network, Ping, Weather, Forecast, Clock, Backlight, Notification, Calendar)
├── widgets/           — 15 widgets consuming services (Workspaces, Volume, Music, Tray, Cpu, ...)
└── popups/            — CalendarPopup, NetworkPopup, VolumeOsd
```

Pattern: **singleton services** expose state; **widget components** render it; `qmldir` manifests declare the singletons/components per directory. The bar renders per-screen via `Quickshell.screens` Variants.

## System Monitor Architecture

```
.config/system_monitor/ping/
├── server.py                 — Flask app: /api/status, /api/today, /api/pings, /
├── docker-compose.yml        — ping-viz service
├── Dockerfile                — iproute2 included for gateway target resolution
├── ping.config               — targets: host [label] t1 t2 t3 (thresholds); hot-reloaded each cycle
├── ping_plot.html            — browser history UI
├── requirements.txt          — Python deps
├── migrate_csv_to_sqlite.py  — DB migration
├── migrate_add_target_host.py
├── .env / .env.example       — BIND_HOST, PORT, COLLECTION_INTERVAL, STALE_AFTER_SECONDS
└── data/                     — SQLite history (gitignored)
```

Data flow: `server.py` pings targets on a cycle → writes SQLite (`data/system.db`) → Waybar fetches `/api/status` JSON → browser UI reads `/api/today` + `/api/pings`. Bind host differs by distro (loopback on Arch, LAN on Debian/Ubuntu).

## Desktop Session Architecture

Bare Hyprland started from TTY (no uwsm/systemd session manager) creates a gap: `xdg-desktop-portal` requires `graphical-session.target`, which won't start manually. The `hyprland-session.service` user unit bridges this:

```
hyprland.conf: exec-once = systemctl --user start hyprland-session.service
   └─ [Service] oneshot /usr/bin/true, RemainAfterExit=yes
      └─ Wants=graphical-session.target, Before=graphical-session.target
         └─ pulls up graphical-session.target as a dependency
            └─ xdg-desktop-portal-hyprland (ScreenCast/screen-share) starts
```

This is a documented fix for screen-share on bare Hyprland sessions.

## Cross-Cutting Patterns

- **Catppuccin Mocha theming** is applied consistently across Hyprland, Waybar, swaync, rofi, cursors, and the Quickshell Colours singleton — a de facto theme contract.
- **`[LABEL] message` echo convention** gives every provisioning script a consistent progress vocabulary (`[INSTALL]`, `[CONFIG]`, `[COPY]`, `[VERIFY]`, `[DONE]`, `[SKIP]`).
- **Graceful degradation** in nvim: missing external tools never nag at startup; the health command is the single source of truth.
- **Repo-relative path resolution** (`REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`) makes scripts runnable from any CWD in the structured generation.
