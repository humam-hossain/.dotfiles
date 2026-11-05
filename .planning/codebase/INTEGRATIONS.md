# External Integrations

**Analysis Date:** 2026-11-05

## APIs & External Services

**Weather Telemetry:**
- **WorldWeatherOnline (WWO) Premium API** — Provides current weather conditions, 24-hour hourly forecasts, 3-day astronomical metrics, air quality indices (AQI), and weather alerts.
  - Endpoint: `https://api.worldweatheronline.com/premium/v1/weather.ashx`
  - Implementation: `stow/weather/.config/weather/wwo-fetcher.py` (executed via user systemd timer `wwo-fetcher.timer` in `stow/weather/.config/systemd/user/wwo-fetcher.timer`).
  - Auth: `WWO_API_KEY` loaded from `$XDG_CONFIG_HOME/weather/.env` (template in `stow/weather/.config/weather/.env.example`).
  - Quota Governance: Enforces strict dynamic budget pacing (`(M_rem / max(1, 470 - calls)) >= 3.0 min`), hard ceiling of 500 requests/day, UTC midnight reset counter, and 25-second HTTP timeout with exponential backoff on failure.
  - UI Consumer: `restow/quickshell/.config/quickshell/ii/services/Weather.qml` and `modules/ii/bar/weather/WeatherBar.qml`.

**Git Hosting & Repositories:**
- **GitHub** — Hosts primary dotfiles repository and upstream fork:
  - Parent repository: `git@github.com:humam-hossain/.dotfiles.git`
  - Upstream submodule: `git@github.com:humam-hossain/dots-hyprland.git` pinned in `vendor/dots-hyprland`.
  - Client: `git` CLI, GitHub CLI (`gh` installed via `arch/tools.sh`).
  - Auth: SSH agent authentication (`id_ed25519` / `id_rsa`); no tokens stored in repository.

**Package & Plugin Repositories:**
- **Arch User Repository (AUR)** — Upstream PKGBUILD sources for foreign packages (`arch/pkglist-aur.txt`).
  - Client: `yay` (`arch/aur.sh`).
- **lazy.nvim / GitHub Plugin Ecosystem** — Fetches and manages Neovim plugin dependencies.
  - Source: `https://github.com/folke/lazy.nvim.git` bootstrapped in `stow/nvim/.config/nvim/init.lua`.
  - Lockfile: `stow/nvim/.config/nvim/lazy-lock.json`.
- **Fisher Plugin Registry** — Fish shell plugin management (`arch/fish.sh`).
- **Tmux Plugin Manager (TPM)** — Cloned from `https://github.com/tmux-plugins/tpm.git` (`arch/tmux.sh`).

**Developer Metrics & Time Tracking:**
- **Wakapi / WakaTime** — Activity telemetry tracking editor usage across Neovim.
  - Endpoint: `https://wakapi.dev/api` configured in `arch/wakatime.sh`.
  - Client: WakaTime Neovim plugin.
  - Auth: `api_key` written to `~/.wakatime.cfg` (local host configuration; excluded from git).

**Hardware & Messaging Automations:**
- **Hermit (Playwright / Chromium)** — Messaging automation client installed via pipx (`arch/hermit.sh`).
  - Auth: Local session cookies stored under user profile.

## Data Storage

**Databases:**
- None. The dotfiles codebase operates entirely without relational or NoSQL database servers.

**File Storage:**
- **Volatile IPC tmpfs Cache:**
  - Location: `$XDG_RUNTIME_DIR/weather/weather.json` (defaults to `/run/user/$UID/weather/weather.json`).
  - Pattern: `stow/weather/.config/weather/wwo-fetcher.py` writes to a temporary file in the same tmpfs directory and replaces it atomically via `os.replace` to eliminate race conditions with the QML UI thread.
- **Persistent State Mirror:**
  - Location: `$XDG_STATE_HOME/weather/last_known_weather.json` (`~/.local/state/weather/last_known_weather.json`).
  - Purpose: Survives reboots and system shutdowns, providing immediate offline cold-boot data to `Weather.qml` before the first network fetch completes.
- **Operational Transcripts & Logs:**
  - Location: `$XDG_STATE_HOME/dotfiles/logs/bootstrap-*.log`.
  - Retention: `bootstrap.sh` enforces automated FIFO cleanup retaining only the 5 most recent transcripts.

**Caching:**
- **Quickshell Reactive In-Memory Cache:**
  - `restow/quickshell/.config/quickshell/ii/services/Weather.qml` binds `Quickshell.Io.FileView` to the tmpfs JSON file with a 60-second fallback poll timer. Eliminates all subshell child processes (`curl`/`wttr.in`), maintaining CPU usage <= 0.01%.

## Authentication & Identity

**Auth Provider:**
- **Linux PAM & Non-Root Operator Model:**
  - Managed by local OS (`/etc/passwd`, `/etc/shadow`).
  - Enforced Policy: All orchestrator scripts (`bootstrap.sh`, `arch/dots-hyprland.sh`, `scripts/phase*-assert.sh`) refuse execution as `root` (`EUID -eq 0`) to prevent privilege escalation and permissions corruption. Sudo is requested on-demand.

**Cloud Storage Authentication:**
- **Rclone:**
  - Configuration directory: `stow/rclone/` links generic service units.
  - Live configuration: `~/.config/rclone/rclone.conf` contains sensitive OAuth tokens and cloud remotes. Under strict repository confidentiality rules, rclone config files and tokens are never committed or inspected by automated tools.

**Secret Management:**
- Local secrets are isolated in gitignored files:
  - `$XDG_CONFIG_HOME/weather/.env` (for WWO weather API key).
  - `~/.wakatime.cfg` (for Wakapi token).
  - Repository-level detection: `.gitleaks.toml` scans for private keys, AWS tokens, and OAuth secrets.

## Monitoring & Observability

**System Telemetry Services:**
- **Quickshell Built-in Telemetry:**
  - CPU & Memory: `restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml` and `services/ResourceUsage.qml` parse `/proc/stat` and `/proc/meminfo` with tiered polling (1s active, 3s idle).
  - Storage: `services/StorageUsage.qml` monitors disk mount capacities.
  - Network: `services/NetworkUsage.qml` monitors `/proc/net/dev` throughput.
  - ICMP Latency: `services/PingService.qml` executes periodic background pings to verify gateway and internet reachability.
  - Process Tree Inspector: `restow/quickshell/.config/quickshell/ii/scripts/resource-usage/process_tree.py` provides top CPU/memory consumer hierarchy.

**Disk & Hardware Health:**
- `smartmontools` — Configured in `stow/smartmontools/.config/smartmontools/collector.yml` for NVMe/SATA drive health telemetry.

**Logs:**
- User Daemons: Inspected via `journalctl --user -u <service-name>` (e.g. `wwo-fetcher.service`).
- Bootstrap & Install Runs: Dual-stream logging via `exec > >(tee -a "$LOG_FILE") 2>&1` in `bootstrap.sh`.

## CI/CD & Deployment

**Hosting:**
- Self-hosted workstation environment. No cloud deployment targets.

**Deployment Engine:**
- **`bootstrap.sh`** — Master idempotent entry point executing preflight checks, package installations, Stow linking, and verification assertions.
- **GNU Stow Deployment Model:**
  - `stow/`: Packages where upstream never collides (`stow -t ~ <pkg>`).
  - `restow/`: Packages where upstream installer overwrites or conflicts (`stow --verbose=5 --no-folding -t ~ <pkg>`).
  - Routing contract: Defined in `collision-map.tsv` and enforced by `scripts/gen-collision-map.sh`.
- **Integrity Gate:**
  - `arch/dots-hyprland.sh verify --strict` validates that all live symlinks point to valid repo targets, no unmanaged files conflict, and no submodule drift exists.

## Environment Configuration

**Required Environment Variables:**
- `XDG_CONFIG_HOME` — Defaults to `$HOME/.config`.
- `XDG_DATA_HOME` — Defaults to `$HOME/.local/share`.
- `XDG_STATE_HOME` — Defaults to `$HOME/.local/state`.
- `XDG_RUNTIME_DIR` — Defaults to `/run/user/$UID`.
- `WWO_API_KEY` — Defined in `$XDG_CONFIG_HOME/weather/.env` for weather data retrieval.

**Secrets Location:**
- Weather API key: `$XDG_CONFIG_HOME/weather/.env`
- WakaTime key: `~/.wakatime.cfg`
- Cloud storage remotes: `~/.config/rclone/rclone.conf` (unmanaged, confidential)

## Webhooks & Callbacks

**Incoming:**
- None. Workstation shell client only; no public HTTP listener ports opened.

**Outgoing:**
- Desktop notification dispatch via `libnotify` (`notify-send`) in Quickshell shell scripts (`system-update.sh`, `record.sh`, `WeatherAlertBanner.qml`).

---

*Integration audit: 2026-11-05*
