# Codebase Structure

**Analysis Date:** 2026-11-05

## Directory Layout

```
.dotfiles/                                      # Repository root (Arch Linux / Quickshell environment)
├── arch/                                       # Arch Linux package installers and system configuration scripts
│   ├── dots-hyprland.sh                        # Thin wrapper & strict verification gate for upstream submodule
│   ├── pkglist-native.txt                      # Explicit native pacman package inventory (208 packages)
│   ├── pkglist-aur.txt                         # Explicit foreign AUR package inventory (56 packages)
│   ├── README.md                               # Arch system bootstrap and manual setup guide
│   └── *.sh                                    # Modular package installation scripts (audio, hyprland, nvim, etc.)
├── bootstrap.sh                                # Master non-root deployment orchestrator with dual-stream logging
├── collision-map.tsv                           # Formal machine contract routing packages to stow/ or restow/
├── guard-paths.tsv                             # Specification of dynamic generated theme paths excluded from git
├── restow/                                     # GNU Stow tree for packages where upstream installer overwrites configs
│   ├── chrome-flags/                           # Chrome Wayland flags (.config/chrome-flags.conf)
│   ├── dolphinrc/                              # KDE Dolphin file manager configuration
│   ├── fuzzel/                                 # Fuzzel Wayland application launcher config
│   ├── hypr/                                   # Hyprland session configs (hypridle.conf, hyprlock.conf, scripts)
│   ├── kitty/                                  # Kitty terminal config and Python helper scripts
│   ├── matugen/                                # Material You theme generator config and templates
│   ├── quickshell/                             # Personal Quickshell QML overlays (ii status bar, popups, services)
│   ├── starship/                               # Starship prompt configuration
│   └── README.md                               # Contract and exact recovery commands for restow packages
├── stow/                                       # GNU Stow tree for packages that never collide with upstream
│   ├── alacritty/, btop/, coredump/, fish/     # User application and shell configurations
│   ├── gtk/, hypr/, kde/, nvim/, qbittorrent/  # Editor, GUI themes, window manager overlays
│   ├── rclone/                                 # Rclone user services (credentials strictly isolated)
│   ├── smartmontools/                          # Drive health monitoring collector configuration
│   ├── systemd/                                # User systemd units and environment generators
│   ├── system_monitor/, tmux/, waybar/, yazi/  # System tools, terminal multiplexer, file manager
│   ├── weather/                                # Python WWO weather fetcher daemon and systemd timer
│   └── README.md                               # Contract and safe stow linking guidelines
├── scripts/                                    # Assertion harnesses, generators, and profiling tools
│   ├── phase*-assert.sh                        # 50+ fail-closed test assertion suites enforcing phase invariants
│   ├── gen-collision-map.sh                    # AST generator that parses installer primitives into collision-map.tsv
│   ├── nvim-validate.sh                        # Headless Neovim validation and plugin smoke suite
│   ├── profile-quickshell.sh                   # Quickshell CPU, context-switch, and GPU profiling tool
│   └── clone_repo.sh                           # Git helper script
├── tests/                                      # Test fixtures and mock data
│   └── fixtures/weather/                       # Mock WWO weather JSON payloads (nominal, severe alerts, offline, etc.)
├── vendor/                                     # Pinned git submodules
│   └── dots-hyprland/                          # Upstream illogical-impulse desktop shell repository
├── docs/                                       # Operator playbooks and architecture guides
│   ├── dots-hyprland-workflow.md               # Upstream workflow, pin bumps, and wrapper reference
│   ├── config-redistribution.md                # Config distribution documentation
│   └── phase14-adopt-runbook.md                # Desktop shell adoption history and procedures
├── issues/                                     # Post-mortem incident logs and hardware diagnostics
│   ├── 2026-07-16_igpu-flickering-hang-no-display.md
│   ├── 2026-09-30_keyboard-lag-kitty-freeze-investigation.md
│   └── 2026-10-19_usb-port-enumeration-failures-mouse-wifi-ddcutil.md
├── debian/                                     # Debian compatibility installer scripts (CLI / nvim parity)
├── ubuntu/                                     # Ubuntu compatibility installer scripts (CLI / nvim parity)
├── .planning/                                  # GSD project state, phase roadmaps, and codebase maps
├── .gitleaks.toml                              # Secret scanning patterns and detection rules
├── CLAUDE.md / AGENTS.md / GEMINI.md           # AI assistant instructions, boundaries, and safety rules
└── README.md                                   # Repository introduction and desktop shell overview
```

## Directory Purposes

**`arch/`:**
- Purpose: Primary package installation, hardware driver configuration, and system initialization for Arch Linux.
- Contains: Standalone shell scripts invoked by `bootstrap.sh`.
- Key files: `arch/dots-hyprland.sh`, `arch/pkglist-native.txt`, `arch/pkglist-aur.txt`, `arch/README.md`.

**`stow/`:**
- Purpose: GNU Stow packages for applications and configurations that upstream `dots-hyprland` installer never touches.
- Contains: Discrete XDG directory trees (`.config/`, `.local/share/`).
- Key files: `stow/weather/.config/weather/wwo-fetcher.py`, `stow/nvim/.config/nvim/init.lua`, `stow/systemd/.config/systemd/user/`.

**`restow/`:**
- Purpose: GNU Stow packages for configurations where upstream `dots-hyprland` installer overwrites files or replaces symlinks.
- Contains: First-party Quickshell QML overlays, Matugen theme templates, Hyprland custom scripts, Kitty terminal configurations.
- Key files: `restow/quickshell/.config/quickshell/ii/services/Weather.qml`, `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml`, `restow/matugen/.config/matugen/config.toml`, `restow/README.md`.

**`scripts/`:**
- Purpose: Test execution, regression assertion, performance measurement, and metadata generation.
- Contains: Automated phase assertion scripts (`phase*-assert.sh`), Neovim validation harness, and collision map generator.
- Key files: `scripts/phase54.4-weather-assert.sh`, `scripts/gen-collision-map.sh`, `scripts/nvim-validate.sh`, `scripts/profile-quickshell.sh`.

**`tests/fixtures/`:**
- Purpose: Static sample payloads used by assertion harnesses to test JSON parsers and headless math functions without active network connections.
- Key files: `tests/fixtures/weather/nominal.json`, `tests/fixtures/weather/severe_alerts.json`, `tests/fixtures/weather/heavy_rain.json`.

**`vendor/dots-hyprland/`:**
- Purpose: Upstream desktop shell baseline repository tracked as a submodule.
- Contains: Upstream Quickshell setup, scripts, assets, and base configurations.

## Key File Locations

**Entry Points:**
- `bootstrap.sh`: Primary system-wide bootstrap and state reproduction.
- `arch/dots-hyprland.sh`: Desktop shell installation, verification (`verify --strict`), and clean uninstallation.
- `stow/weather/.config/weather/wwo-fetcher.py`: CLI and background weather fetching daemon.

**Configuration:**
- `collision-map.tsv`: Authoritative specification governing Stow package partitioning.
- `guard-paths.tsv`: Authoritative specification of untracked dynamic theme files.
- `restow/matugen/.config/matugen/config.toml`: Matugen dynamic theme configuration and template declarations.
- `stow/nvim/.config/nvim/init.lua`: Neovim entry point and Lazy plugin configuration.

**Core Desktop UI Logic:**
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`: Status bar layout and component positioning.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml`: Multi-card weather inspector dialog.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraphMath.js`: Canvas math and drawing calculations.
- `restow/quickshell/.config/quickshell/ii/services/Weather.qml`: Reactive weather data singleton.
- `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml`: Hardware resource polling singleton.

**Testing & Verification:**
- `scripts/phase54.4-weather-assert.sh`: Weather popup and canvas math assertion harness.
- `scripts/nvim-validate.sh`: Headless Neovim test harness.
- `arch/dots-hyprland.sh verify --strict`: Live symlink and submodule integrity checker.

## Naming Conventions

**Files:**
- Arch installers: `arch/<tool_name>.sh` (lowercase, underscore for multi-word, e.g. `google_chrome.sh`, `system_monitor.sh`).
- Test assertion scripts: `scripts/phase<phase_number>-<topic>-assert.sh` (e.g. `phase54.4-weather-assert.sh`).
- QML components: `PascalCase.qml` (e.g. `WeatherPopup.qml`, `CpuGpuPill.qml`, `BarContent.qml`).
- JavaScript helper modules: `PascalCase.js` (e.g. `WeatherGraphMath.js`).
- Python scripts: `kebab-case.py` for standalone executables (`wwo-fetcher.py`), `snake_case.py` for embedded libraries (`process_tree.py`).
- Issue post-mortems: `issues/YYYY-MM-DD_<topic-description>.md`.

**Directories:**
- Stow packages: kebab-case or tool name matching installed application (e.g. `chrome-flags`, `smartmontools`, `system_monitor`).
- QML modules: structured according to Quickshell module taxonomy (`modules/ii/bar/`, `modules/ii/mediaControls/`, `services/`).

## Where to Add New Code

**New Quickshell UI Component:**
- Implementation: `restow/quickshell/.config/quickshell/ii/modules/ii/bar/<subsystem>/<ComponentName>.qml`
- Placement in Bar: Include in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`
- Reactive Data Source: Add singleton in `restow/quickshell/.config/quickshell/ii/services/<ServiceName>.qml`
- Verification Test: Add assertion block or new test harness in `scripts/phase<N>-<subsystem>-assert.sh`

**New Application Configuration:**
1. Determine collision disposition: Check if upstream `vendor/dots-hyprland/setup` writes to the target path.
2. If upstream touches target path: Add package under `restow/<app_name>/.config/...` and update `collision-map.tsv`.
3. If upstream NEVER touches target path: Add package under `stow/<app_name>/.config/...`.
4. Deploy package: `cd stow && stow --verbose=5 --no-folding -t ~ <app_name>` (or `restow`).

**New System Package / Tool:**
- Installer: Create or update `arch/<tool_name>.sh`.
- Package List: Add package name to `arch/pkglist-native.txt` or `arch/pkglist-aur.txt`.
- Orchestrator: Register invocation inside `bootstrap.sh`.

**New Shared Utility / Helper Script:**
- Standalone CLI utility: Place in `stow/<app_name>/.local/bin/` or `arch/`.
- Developer test/validation tool: Place in `scripts/<utility_name>.sh`.

## Special Directories

**`restow/`:**
- Purpose: Contains dotfiles that collide with or are overwritten by upstream `dots-hyprland` installer.
- Generated: No (hand-authored personal overlays).
- Committed: Yes (tracked in git).
- Recovery idiom: Re-stowed manually or verified via `arch/dots-hyprland.sh verify`.

**`stow/`:**
- Purpose: Contains dotfiles completely isolated from upstream installer actions.
- Generated: No (hand-authored personal dotfiles).
- Committed: Yes (tracked in git).
- Recovery idiom: Linked once on bootstrap; never disturbed by upstream updates.

**`vendor/dots-hyprland/`:**
- Purpose: Upstream submodule containing base desktop shell source code.
- Generated: Managed via `git submodule`.
- Committed: Pinned gitlink commit SHA tracked in `.gitmodules`. Working tree is NEVER edited directly.

**`.planning/`:**
- Purpose: Project roadmap, milestone specifications, requirements contracts, and codebase state documents.
- Generated: Managed by GSD tooling.
- Committed: Yes (tracked in git for state synchronization).

---

*Structure analysis: 2026-11-05*
