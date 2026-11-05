<!-- refreshed: 2026-11-05 -->
# Architecture

**Analysis Date:** 2026-11-05

## System Overview

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Linux Operator / Wayland Session                      │
│                  Hyprland Compositor (`restow/hypr`, `stow/hypr`)            │
└──────────────┬───────────────────────────────┬───────────────────────────────┘
               │                               │
               ▼                               ▼
┌────────────────────────────────────────┐ ┌───────────────────────────────────┐
│     Desktop Shell Engine (Quickshell)  │ │      Cross-Desktop Theming        │
│          Command: `qs -c ii`           │ │             (Matugen)             │
│  Base: `vendor/dots-hyprland` (pinned) │ │  `restow/matugen/.config/matugen` │
│  Overlays: `restow/quickshell/ii/`     │ │  Generates: GTK, Qt, Fuzzel, Hypr │
└──────────────┬─────────────────────────┘ └───────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                    Personal Quickshell QML Component Hierarchy               │
│                                                                              │
│  Presentation Layer:                                                         │
│  ├── Top Bar (`modules/ii/bar/BarContent.qml`)                              │
│  │   ├── Weather Component (`WeatherBar.qml` -> `WeatherPopup.qml`)          │
│  │   ├── Hardware Pills (`CpuGpuPill.qml`, `MemoryStoragePill.qml`)          │
│  │   ├── Network & Media (`NetworkPingPill.qml`, `Media.qml`)               │
│  │   └── Clock, Updates, System Tray (`ClockWidget.qml`, `SysTray.qml`)      │
│  └── Canvas Render Engine (`modules/ii/bar/weather/WeatherGraphMath.js`)     │
│                                                                              │
│  Reactive Service Singletons (`restow/quickshell/.../services/`):            │
│  ├── `Weather.qml` (Watches tmpfs cache via `Quickshell.Io.FileView`)        │
│  ├── `HardwareTelemetry.qml` (Tiered procfs/sysfs sweeping)                  │
│  ├── `Audio.qml`, `NetworkUsage.qml`, `PingService.qml`, `StorageUsage.qml`  │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                       System Daemons & Volatile IPC State                    │
│                                                                              │
│  systemd user timers: `wwo-fetcher.timer` -> `wwo-fetcher.service`           │
│  Python daemon: `stow/weather/.config/weather/wwo-fetcher.py`                │
│  Volatile IPC cache: `$XDG_RUNTIME_DIR/weather/weather.json` (atomic swap)   │
│  Persistent backup: `$XDG_STATE_HOME/weather/last_known_weather.json`        │
│  System Telemetry: `/proc/stat`, `/proc/meminfo`, `/proc/net/dev`, `/sys/`    │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                     Dotfiles Storage & Symlink Farm Architecture             │
│                                                                              │
│  `stow/` (Installer-never-collides): nvim, weather, fish, tmux, systemd      │
│  `restow/` (Installer-overwrites): quickshell, hypr, matugen, kitty, fuzzel  │
│  Routing Contract: `collision-map.tsv` & `guard-paths.tsv`                   │
│  Deployment & Assertions: `bootstrap.sh`, `arch/dots-hyprland.sh verify`    │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| **Deployment Orchestrator** | Idempotent system bootstrap, transcript logging, non-root enforcement | `bootstrap.sh` |
| **Submodule Wrapper & Gate** | Wraps `vendor/dots-hyprland/setup`, runs strict verification, manages uninstall | `arch/dots-hyprland.sh` |
| **Collision Contract** | Formal TSV mapping defining stow vs restow classification based on installer primitives | `collision-map.tsv` |
| **Collision Generator** | AST parser that inspects upstream installer scripts and generates `collision-map.tsv` | `scripts/gen-collision-map.sh` |
| **Guard Path Contract** | Specifies files excluded from git tracking to prevent theme churn | `guard-paths.tsv` |
| **Weather Daemon** | Fetches WWO weather data, enforces daily quota pacing, writes atomic tmpfs cache | `stow/weather/.config/weather/wwo-fetcher.py` |
| **Weather Service Singleton** | Exposes reactive weather properties to QML without subshell execution | `restow/quickshell/.config/quickshell/ii/services/Weather.qml` |
| **Weather Glyphs Dictionary** | Maps 59 WWO condition codes, day/night states, AQI, and alerts to Material Symbols | `restow/quickshell/.config/quickshell/ii/services/WeatherGlyphs.qml` |
| **Weather Popup Inspector** | Modular multi-card weather inspector and graph visualization popup | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml` |
| **Weather Graph Engine** | Headless-testable Canvas drawing math for bezier curves, axes, and gradient fills | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraphMath.js` |
| **Hardware Telemetry** | Tiered polling of `/proc/stat` and `/proc/meminfo` (1s active / 3s idle) | `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml` |
| **Resource Usage Parser** | Python helper parsing system process trees without unbounded fork overhead | `restow/quickshell/.config/quickshell/ii/scripts/resource-usage/process_tree.py` |
| **Material You Theme Engine** | Wallhaven/swww wallpaper color extractor and template coordinator | `restow/matugen/.config/matugen/config.toml` |
| **Neovim Configuration** | Complete IDE setup with lazy.nvim, conform.nvim, and custom keymap registry | `stow/nvim/.config/nvim/init.lua` |

## Pattern Overview

**Overall:** Submodule Fork with Dual-Tree Stow Overlays and Reactive IPC Caching.

**Key Characteristics:**
- **Zero Git Churn in Submodule:** Upstream desktop shell is tracked as a clean git submodule in `vendor/dots-hyprland`. No first-party modifications occur inside the submodule tree.
- **Two-Tree Stow Partitioning:** Configurations are split into `stow/` (isolated packages that upstream installer never collides with) and `restow/` (packages that upstream installer overwrites, requiring re-stowing).
- **Atomic File-Based IPC:** Background daemons (Python) write data to tmpfs files using temporary names and rename them via `os.replace`. Frontend UI (Quickshell QML) observes these files reactively using `Quickshell.Io.FileView`, avoiding blocking subshell execution.
- **Fail-Closed Verification:** All deployment and phase changes are validated against strict bash/python test harnesses with non-zero exit codes on failure.

## Layers

**1. Compositor & Display Layer:**
- Purpose: Wayland window management, input dispatch, screen configuration, and keybindings.
- Location: `stow/hypr/`, `restow/hypr/`
- Contains: Hyprland configuration, window rules, keybinding definitions, hypridle, hyprlock.
- Depends on: Linux DRM/KMS, Vulkan, proprietary/open GPU drivers.
- Used by: All graphical applications and Quickshell.

**2. Shell & Presentation Layer:**
- Purpose: Status bar, system popups, notifications, and application launcher.
- Location: `restow/quickshell/.config/quickshell/ii/`, `restow/fuzzel/`
- Contains: QML components (`BarContent.qml`, `WeatherBar.qml`, `CpuGpuPopup.qml`), Canvas math scripts.
- Depends on: Quickshell runtime, QtQuick 6, PipeWire, system telemetry.
- Used by: Desktop operator.

**3. Services & Telemetry Layer:**
- Purpose: Reactive data ingestion, system resource monitoring, and background polling.
- Location: `restow/quickshell/.../services/`, `stow/weather/`
- Contains: `Weather.qml`, `HardwareTelemetry.qml`, `wwo-fetcher.py`.
- Depends on: Linux `/proc` and `/sys` filesystems, external WWO API.
- Used by: Presentation layer QML components.

**4. Theming & Styling Layer:**
- Purpose: System-wide dynamic Material You color synchronization.
- Location: `restow/matugen/`
- Contains: `config.toml`, templates for GTK 3/4, Qt/KDE, Fuzzel, Hyprland.
- Depends on: `matugen` binary, current desktop wallpaper.
- Used by: GTK apps, Qt apps, terminal emulators, Hyprland window borders.

**5. Dotfile Management & Packaging Layer:**
- Purpose: Automated symlink deployment, package installation, and hardware bootstrapping.
- Location: `stow/`, `restow/`, `arch/`, `bootstrap.sh`
- Contains: Package manifests, Stow symlink structures, bash installer scripts.
- Depends on: GNU Stow, Pacman, Yay.
- Used by: System administrator / developer during installation and updates.

## Data Flow

### Primary Weather Telemetry Path

1. **Systemd Trigger:** `wwo-fetcher.timer` fires on user session schedule (`stow/weather/.config/systemd/user/wwo-fetcher.timer:1`).
2. **API Pacing & Fetch:** `wwo-fetcher.py` validates time elapsed against dynamic formula `(M_rem / max(1, 470 - calls)) >= 3.0 min`, loads API key from `$XDG_CONFIG_HOME/weather/.env`, and queries WWO endpoint (`stow/weather/.config/weather/wwo-fetcher.py:120`).
3. **Atomic Cache Write:** `wwo-fetcher.py` writes payload to `$XDG_RUNTIME_DIR/weather/weather.tmp.*` and renames to `weather.json` via `os.replace` (`stow/weather/.config/weather/wwo-fetcher.py:285`).
4. **Persistent Mirror:** Mirror copy is written to `$XDG_STATE_HOME/weather/last_known_weather.json`.
5. **Reactive QML Update:** `Weather.qml` `FileView` detects file modification, parses JSON into reactive properties, and updates `WeatherBar.qml` and `WeatherPopup.qml` without launching any subprocess (`restow/quickshell/.../services/Weather.qml:45`).
6. **Canvas Rendering:** `WeatherPopup.qml` passes hourly metrics to `WeatherGraphMath.js` to render temperature/AQI curves onto an HTML5-style QML Canvas (`restow/quickshell/.../weather/WeatherGraph.qml:80`).

### Hardware Telemetry Path

1. **Timer Event:** `HardwareTelemetry.qml` triggers on 1000ms (active popup) or 3000ms (idle pill) cadence (`restow/quickshell/.../services/HardwareTelemetry.qml:30`).
2. **Procfs Reading:** Reads `/proc/stat` and `/proc/meminfo` directly via Quickshell file streams.
3. **Pill & Popup Bindings:** Updates `CpuGpuPill.qml` and `MemoryStoragePill.qml`. When popups open, tiered sweeps expand to inspect individual CPU cores and top process consumers.

### Dynamic Theming Path

1. **Wallpaper Change:** Operator selects wallpaper via `swww` or `switchwall.sh`.
2. **Matugen Generation:** `matugen image <wallpaper>` reads image palette and evaluates templates in `restow/matugen/.config/matugen/templates/`.
3. **File Output:** Generated themes are written directly to `$XDG_CONFIG_HOME/{gtk-3.0,gtk-4.0,fuzzel,hypr}/` (guarded by `guard-paths.tsv`).
4. **Live Reload:** Hyprland reloads `colors.lua`, GTK applications reload CSS, and Fuzzel reloads color definitions immediately.

## Key Abstractions

- **Reactive Singleton Pattern:**
  - Implemented in QML via `pragma Singleton` and `pragma ComponentBehavior: Bound`.
  - Ensures a single system-wide source of truth for telemetry states (`Weather.qml`, `HardwareTelemetry.qml`, `Audio.qml`, `GlobalStates.qml`).
- **Two-Tree Stow Partitioning:**
  - `stow/`: Guaranteed zero-conflict packages.
  - `restow/`: Overwrite-handled packages with explicit recovery instructions.
  - Governed by machine-generated `collision-map.tsv`.
- **Pure Math Rendering Engine:**
  - `WeatherGraphMath.js`: Encapsulates all Canvas scaling, bezier control point calculations, grid boundaries, and label positions in pure JS functions with zero QML or DOM dependencies.
  - Enables 100% headless unit testing in Node.js VM (`scripts/phase54.4-weather-assert.sh`).

## Entry Points

- **`bootstrap.sh`:**
  - Location: `/home/pera/github_repo/.dotfiles/bootstrap.sh`
  - Triggers: Manual invocation during fresh workstation setup or disaster recovery.
  - Responsibilities: Preflights Arch release, enforces non-root execution, establishes dual-stream logging, runs installer scripts in sequence, links Stow packages, and runs test assertions.
- **`arch/dots-hyprland.sh`:**
  - Location: `/home/pera/github_repo/.dotfiles/arch/dots-hyprland.sh`
  - Triggers: Invoked to install or verify the Quickshell desktop shell.
  - Responsibilities: Validates allowlisted subcommands, manages `vendor/dots-hyprland` submodule, executes `./setup`, runs `verify --strict`.
- **`stow/weather/.config/weather/wwo-fetcher.py`:**
  - Location: `$XDG_CONFIG_HOME/weather/wwo-fetcher.py`
  - Triggers: Scheduled systemd timer `wwo-fetcher.timer` or manual CLI execution.
  - Responsibilities: Paced weather fetching, tmpfs caching, offline recovery.

## Architectural Constraints

- **Non-Root Execution:** All deployment and test scripts MUST fail immediately if run as `root` (`EUID -eq 0`). Sudo is requested interactively only when installing system packages.
- **Zero Submodule Drift:** The `vendor/dots-hyprland` tree must remain clean at all times (`git status --porcelain` in vendor must be empty).
- **No `--adopt` with GNU Stow:** Using `stow --adopt` is strictly prohibited in all scripts because it silently destroys git repository contents with live filesystem state.
- **Strict Rclone Confidentiality:** `/home/pera/.config/rclone/rclone.conf` and all files matching `*rclone.conf*` are strictly forbidden from being read, parsed, printed, or processed by scripts or AI tools.
- **Resource Budgeting:** QML components must never spawn polling shell commands in timers. Telemetry must use Qt file streams or background daemons writing to tmpfs.

## Anti-Patterns

### Using `stow --adopt` to resolve conflicts
**What happens:** Running `stow --adopt` overwrites the repository files with whatever exists on disk.
**Why it's wrong:** It destroys git authoring source of truth without warning, importing uncommitted or corrupted live files into git.
**Do this instead:** Follow the manual recovery procedure in `stow/README.md`: simulate first with `stow -n -v`, back up conflicting live files, remove live files, and run standard `stow --no-folding`.

### Spawning child processes inside QML timers
**What happens:** Using `Quickshell.Io.Process` or `sh -c curl` inside periodic QML timers to fetch data.
**Why it's wrong:** Incurs huge CPU spikes, context switch storms (Phase 49 measured 453/s), and battery drain on idle systems.
**Do this instead:** Use persistent background daemons (e.g. `wwo-fetcher.py`) writing to tmpfs files, read via `Quickshell.Io.FileView` as done in `Weather.qml` (reduces CPU to <= 0.01%).

### Committing dynamic theme outputs to git
**What happens:** Adding files like `kdeglobals`, `gtk.css`, or `colors.lua` to git tracking.
**Why it's wrong:** Causes constant git dirty working tree churn every time wallpaper or theme colors change.
**Do this instead:** Exclude them via `guard-paths.tsv` and `.gitignore`, letting Matugen generate them on-the-fly from templates.

## Error Handling

**Strategy:** Fail-closed execution with automated cleanup traps.

**Patterns:**
- **Bash Scripts:** `set -euo pipefail` standard across all files; `trap cleanup EXIT` handles removal of temporary files and restoration of standard I/O descriptors.
- **Python Daemons:** Try/except blocks around network I/O with exponential backoff; writes to tmpfs files only replace cache if JSON deserialization succeeds; falls back to `is_stale: true` and persistent disk cache on network loss.
- **QML UI Components:** Safe fallback default objects (`tempC: "--"`, `desc: "Offline"`, `glyph: "cloud_off"`) ensure components never crash or render null references during cold boots or network outages.

## Cross-Cutting Concerns

- **Logging:** Dual-stream stdout/stderr teeing to `$XDG_STATE_HOME/dotfiles/logs/bootstrap-*.log` with automated log rotation keeping the last 5 runs.
- **Security & Secret Isolation:** `.gitleaks.toml` configuration preventing credential leaks; local `.env` files kept outside version control; strict rclone confidentiality barrier.
- **Assertion Gates:** Every phase and major subsystem is coupled with a dedicated assertion script in `scripts/` validating static structure, runtime contracts, and deployment invariants.

---

*Architecture analysis: 2026-11-05*
