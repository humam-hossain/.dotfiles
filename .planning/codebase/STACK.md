# Technology Stack

**Analysis Date:** 2026-11-05

## Languages

**Primary:**
- Bash (`GNU bash 5.x+`, `#!/usr/bin/env bash`, `set -euo pipefail`) — Used across all system installers (`arch/*.sh`, `debian/*.sh`, `ubuntu/*.sh`), core orchestrator `bootstrap.sh`, wrapper `arch/dots-hyprland.sh`, collision generator `scripts/gen-collision-map.sh`, and 50+ test assertion suites (`scripts/phase*-assert.sh`).
- QML / QtQuick / JavaScript (Qt 6 / Quickshell runtime) — Personal desktop shell overlays in `restow/quickshell/.config/quickshell/ii/`:
  - Component views: `modules/ii/bar/weather/WeatherPopup.qml`, `modules/ii/bar/weather/WeatherGraph.qml`, `modules/ii/bar/CpuGpuPopup.qml`, `modules/ii/bar/MemoryStoragePopup.qml`.
  - Services: `services/Weather.qml`, `services/HardwareTelemetry.qml`, `services/Audio.qml`, `services/NetworkUsage.qml`.
  - Pure JS canvas math: `modules/ii/bar/weather/WeatherGraphMath.js` (evaluated both in QML Canvas and in headless Node.js vm test harnesses).
- Python 3 (CPython 3.12–3.14, standard library only) — Core background services and telemetry:
  - Background daemon: `stow/weather/.config/weather/wwo-fetcher.py` (zero pip dependencies; enforces strict API pacing, tmpfs atomic writes, and offline fallback).
  - Telemetry parser: `restow/quickshell/.config/quickshell/ii/scripts/resource-usage/process_tree.py`.
  - Terminal extensions: `restow/kitty/.config/kitty/scroll_mark.py`, `search.py`.
  - Test assertions: `scripts/phase02-config-assert.py`, `scripts/phase03-config-assert.py`, `scripts/phase04-ipc-reload-assert.py`.
- Lua 5.1 / LuaJIT — Neovim IDE configuration in `stow/nvim/.config/nvim/` (`init.lua`, `lua/core/`, `lua/plugins/`); WezTerm config in `stow/wezterm/.config/wezterm/wezterm.lua`; Hyprland dynamic theming output `hyprland/colors.lua`.

**Secondary:**
- Fish Shell — `stow/fish/.config/fish/config.fish` with Fisher package manager (`arch/fish.sh`).
- TOML / YAML / CSS — Configurations for Matugen (`restow/matugen/.config/matugen/config.toml`), Starship (`restow/starship/.config/starship.toml`), Fuzzel (`restow/fuzzel/.config/fuzzel/fuzzel.ini`), Kitty (`restow/kitty/.config/kitty/kitty.conf`), GTK 3/4 CSS templates (`restow/matugen/.config/matugen/templates/gtk-*/gtk.css`), and smartmontools (`stow/smartmontools/.config/smartmontools/collector.yml`).
- JSON — Neovim plugin lockfile `stow/nvim/.config/nvim/lazy-lock.json`; runtime weather cache schemas in `tests/fixtures/weather/*.json`.

**Explicitly Excluded / Not Present in Repo Root:**
- No root `package.json`, `Cargo.toml`, `go.mod`, or `pyproject.toml`. Node.js and Go are system-installed tools for linters/formatters, not project build runtimes.

## Runtime

**Environment:**
- Target OS: Arch Linux x86_64 (sole supported production target enforced in `bootstrap.sh` and `arch/dots-hyprland.sh`).
- Window Manager / Compositor: Hyprland (Wayland compositor) with `xdg-desktop-portal-hyprland`.
- Desktop Shell Engine: Quickshell (`qs -c ii`) executing personal QML overlays in `restow/quickshell/.config/quickshell/ii/` over upstream submodule `vendor/dots-hyprland`.
- Init & Process Management: systemd user session (`systemctl --user`), managing user daemons such as `wwo-fetcher.service` / `wwo-fetcher.timer` (`stow/weather/.config/systemd/user/`) and PipeWire audio services.
- Audio Architecture: PipeWire (`pipewire`, `wireplumber`, `pipewire-pulse`, `pipewire-alsa`) configured in `arch/audio.sh`.
- Legacy / Secondary OS Mirrors: Debian and Ubuntu compatibility scripts in `debian/*.sh` and `ubuntu/*.sh` (CLI tooling and nvim only; no Quickshell or Hyprland support).

**Package Manager:**
- System Packages: `pacman` (`arch/pkglist-native.txt`) + AUR helper `yay` (`arch/pkglist-aur.txt`).
- Dotfile Symlink Manager: **GNU Stow** (`stow --verbose=5 --no-folding -t ~ <pkg>`), separating non-colliding configs (`stow/`) from upstream-colliding configs (`restow/`).
- Python Runtime Management: System Python 3 (`/usr/bin/python3`) for system daemons; `pipx` for isolated CLI tools (`arch/python3.sh`, `arch/hermit.sh`); upstream Python venv managed by `vendor/dots-hyprland`.
- Editor Packages: `lazy.nvim` (`stow/nvim/.config/nvim/lazy-lock.json`) for Neovim; `fisher` for Fish shell; `tpm` for tmux.
- Lockfile Status:
  - `stow/nvim/.config/nvim/lazy-lock.json`: Present and pinned.
  - Submodule lock: `.gitmodules` pinning `vendor/dots-hyprland` commit SHA.
  - No npm/pip lockfile at repo root.

## Frameworks

**Core:**
- **Quickshell** (Qt 6 Quick / QML) — Wayland desktop shell framework providing reactive singletons (`Quickshell.Io.FileView`, `Quickshell.Io.Process`), window/layer-shell management, and UI rendering.
- **Hyprland** — Dynamic tiling Wayland compositor handling window management, input dispatch, and workspace routing.
- **GNU Stow 2.3+** — Symlink farm manager with discrete file linking policy (`--no-folding`).
- **Matugen** — Material You cross-desktop color palette generator reading wallpaper colors and outputting templates for GTK 3/4, Qt/KDE, Hyprland, Fuzzel, and Quickshell (`restow/matugen/`).
- **dots-hyprland** (upstream git submodule `vendor/dots-hyprland`) — Upstream desktop baseline wrapped by `arch/dots-hyprland.sh`.

**Testing:**
- **Custom Bash Assertion Framework** — Fail-closed test runners (`scripts/phase*-assert.sh`) enforcing invariant checks, AST grep validation, TAP version 13 reporting (`--tap`), and repository integrity checks.
- **Headless Node.js VM Sandbox** — Executes and asserts QML math logic (`WeatherGraphMath.js`) without requiring a display server (`scripts/phase54.4-weather-assert.sh`).
- **Headless Neovim Validator** — Automated smoke and health testing suite in `scripts/nvim-validate.sh` (`nvim --headless`).

**Build/Dev Tools:**
- `scripts/gen-collision-map.sh` — AST generator parsing installer primitives to generate `collision-map.tsv`.
- `arch/dots-hyprland.sh` — Verification engine (`verify --strict`) enforcing file boundaries and symlink validity.
- `scripts/profile-quickshell.sh` — Performance profiling suite evaluating CPU, context switches, and GPU metrics.

## Key Dependencies

**Critical System Packages:**
- `quickshell-git` / `illogical-impulse-quickshell-git` — Desktop shell runtime.
- `hyprland` — Wayland compositor.
- `matugen` (`matugen-bin`) — Cross-application color generation.
- `stow` — Symlink deployment.
- `yay` — AUR package installation.
- `python` (>= 3.11) — Telemetry fetchers and process inspectors.
- `kitty` / `alacritty` — Terminal emulators.
- `fuzzel` — Application launcher.

**Infrastructure & System Integration:**
- `brightnessctl` — Screen backlight control.
- `wireplumber` / `pipewire` — Audio stream management.
- `bluez` / `blueman` — Bluetooth management.
- `networkmanager` — Network interfaces and connection monitoring.
- `ddcutil` — External display DDC/CI hardware control.
- `systemd` — Service supervision and user timers.

## Configuration

**Environment:**
- Follows XDG Base Directory specification strictly:
  - `$XDG_CONFIG_HOME` (`~/.config`): Application configuration root.
  - `$XDG_DATA_HOME` (`~/.local/share`): Persistent application state and assets.
  - `$XDG_STATE_HOME` (`~/.local/state`): Persistent operational state (e.g. `weather/last_known_weather.json`, `dotfiles/logs/`).
  - `$XDG_RUNTIME_DIR` (`/run/user/$UID`): High-speed tmpfs for volatile IPC caches (e.g. `weather/weather.json`).
- Guarded dynamic outputs: Paths listed in `guard-paths.tsv` are excluded from repository tracking to avoid wallpaper/theme churn.

**Build / Deploy Configuration:**
- `bootstrap.sh` — Master idempotent deployment orchestrator with non-root gating and dual-stream transcript logging.
- `collision-map.tsv` — Machine-generated mapping governing whether packages live in `stow/` or `restow/`.
- `guard-paths.tsv` — Machine-enforced boundary specification excluding dynamic theme files from git.
- `.gitleaks.toml` — Secret scanning rules preventing accidental credential commits.

## Platform Requirements

**Development:**
- Arch Linux workstation with non-root sudo access.
- Git with submodule support (`git submodule update --init --recursive`).
- Node.js (for headless math assertion execution) and Python 3.

**Production:**
- Linux kernel 6.x / 7.x on Arch Linux x86_64.
- Wayland session under Hyprland.
- Intel / AMD / NVIDIA GPU with Vulkan/OpenGL acceleration for Quickshell QML rendering.

---

*Stack analysis: 2026-11-05*
