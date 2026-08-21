# External Integrations

**Analysis Date:** 2026-08-21

## APIs & External Services

**Git hosting:**
- GitHub — origin `.dotfiles` clone (`git@github.com:humam-hossain/.dotfiles.git` per `docs/dots-hyprland-workflow.md`)
  - SDK/Client: `git`, `github-cli` (`gh`) via `arch/tools.sh`
  - Auth: SSH keys / `gh` login (never store tokens in repo)
- GitHub — personal fork submodule `vendor/dots-hyprland` (`.gitmodules`: `git@github.com:humam-hossain/dots-hyprland.git`; upstream conceptual source end-4/dots-hyprland)
  - Nested submodules inside vendor (shapes / rounded-polygon)
- AUR — `yay-bin` clone `https://aur.archlinux.org/yay-bin` (`arch/aur.sh`)

**Time tracking:**
- Wakapi / WakaTime-compatible API — `arch/wakatime.sh`, `debian/wakatime.sh`, `ubuntu/wakatime.sh`
  - SDK/Client: WakaTime editor plugins reading `~/.wakatime.cfg`
  - Auth: interactive `WAKATIME_API_KEY` written to `api_key=` (file gitignored by practice; do not commit)
  - Endpoint set in script: `api_url=https://wakapi.dev/api`

**AI CLIs (Debian/Ubuntu only):**
- Google Gemini CLI — `debian/gemini.sh` / `ubuntu/gemini.sh`: `npm install -g @google/gemini-cli` after `nodejs`/`npm`
  - Auth: Gemini/Google user login at runtime (not in-repo)

**Messaging automation:**
- hermit-msg — `arch/hermit.sh`: `pipx install git+https://github.com/MuTe43/hermit.git` + Playwright Chromium in pipx venv
  - Usage: `hermit login fb` / `hermit login wa` (session cookies live on machine)

**Package / release downloads:**
- GitHub Releases — Neovim tarball (`debian/nvim.sh`), WezTerm `.deb` (`debian/wezterm.sh` uses `https://api.github.com/repos/wez/wezterm/releases/latest`), Nerd Fonts zip (`debian/fonts.sh`)
- lazy.nvim bootstrap — `https://github.com/folke/lazy.nvim.git` (`stow/nvim/.config/nvim/init.lua`)
- Fisher plugin HTTP — `https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish` (`arch/fish.sh`)
- TPM — `https://github.com/tmux-plugins/tpm.git`

**Network / speed:**
- speedtest.net CLI — package `speedtest-cli` in `arch/tools.sh` (outbound bandwidth tests)

**Not applicable as product APIs:** Stripe, AWS SDK, Supabase — not used.

## Data Storage

**Databases:**
- InfluxDB (bundled inside Scrutiny omnibus container) — `arch/scrutiny.sh`
  - Connection: volume `/opt/scrutiny/influxdb`
  - Client: in-container Scrutiny; dashboard `http://localhost:9090`
- No application ORM. Neovim/lazy lock is JSON file, not a DB.

**File Storage:**
- Local filesystem only for dotfiles (GNU Stow → `$HOME`)
- Upstream ii backup dir `~/ii-original-dots-backup`
- Live Quickshell tree `~/.config/quickshell`; ii conf `~/.config/illogical-impulse`
- qBittorrent state under `stow/qbittorrent/.config/qBittorrent/` (lock/rss gitignored in `.gitignore`)

**Caching:**
- pacman / yay caches on host
- pipx venvs under `~/.local/share/pipx/`
- Quickshell venv `~/.local/state/quickshell/.venv`
- None as Redis/Memcached

## Authentication & Identity

**Auth Provider:**
- OS user + sudo/wheel (`arch/README.md` useradd `pera`)
- GitHub SSH for git/submodules
- `gh` for `scripts/clone_repo.sh` (`gh repo list --limit 1000 --json nameWithOwner,name`)
- WakaTime API key in `~/.wakatime.cfg`
- Docker Hub / GHCR pull for images (host docker credentials)
- VS Code: `gnome-keyring` + `libsecret` (`arch/vscode.sh`) for editor login
- Google Chrome as default browser (`arch/google_chrome.sh` + `xdg-settings` / `xdg-mime`)
- Custom: no OAuth app in this repo

## Monitoring & Observability

**Error Tracking:**
- None (no Sentry/etc.)

**Logs:**
- Installer `echo "[INSTALL]|[CONFIG]|[FAIL]|[DONE]"` prefixes (`arch/dots-hyprland.sh`, `arch/*.sh`)
- `set -x` on most `arch/*.sh` (trace to terminal)
- systemd journal for user/session services (`pipewire`, NetworkManager)
- udev logger line in `arch/wifi.sh` Realtek modeswitch rule
- Scrutiny health: `curl http://localhost:9090/api/health`

**Disk SMART:**
- Scrutiny container `ghcr.io/analogj/scrutiny:master-omnibus` (`arch/scrutiny.sh`)
  - Devices: `/dev/sda`, `/dev/nvme0`, `/dev/nvme1`; cap `SYS_RAWIO`
  - Wrapper: `stow/smartmontools/.config/smartmontools/smartctl-wrapper.sh` → `/usr/local/bin/smartctl-wrapper`
  - Config: `collector.yml` → `/opt/scrutiny/config`

**Ping / network viz:**
- `debian/system_monitor.sh` / `ubuntu/monitor_system.sh` + `stow/system_monitor` docker compose (`ping-viz`); ping `.env` gitignored

## CI/CD & Deployment

**Hosting:**
- Local machine only. No cloud app host.

**CI Pipeline:**
- None in first-party tree (no `.github/workflows` at repo root). Vendor submodule may contain `.github/` — ignore as upstream.

**Container images:**
- `ghcr.io/analogj/scrutiny:master-omnibus`
- Docker CE from `https://download.docker.com/linux/debian` on Debian (`debian/docker.sh`)

## Environment Configuration

**Required env vars:**
- `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME` — optional; wrapper defaults to `~/.config`, `~/.local/share`, `~/.local/state`
- `BACKUP_DIR` — optional override for ii backup path
- `ILLOGICAL_IMPULSE_VIRTUAL_ENV` — injected into Hyprland conf by wrapper install hooks
- WakaTime key — prompted, not an exported env var
- System monitor ping `.env` — local only (`.gitignore`)

**Secrets location:**
- `~/.wakatime.cfg` (created by `arch/wakatime.sh`)
- SSH keys for GitHub (user home, not repo)
- Docker credentials on host
- `.gitignore` ignores `.config/system_monitor/ping/.env` (repo-root shaped path) and ping `data/`
- Tracked file: `stow/system_monitor/.config/system_monitor/ping/.env` is **in git** (gitignore does not cover the stow path). Do not quote contents. Treat as a secret-location bug, not a required env var for this repo.

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- WakaTime heartbeats to `https://wakapi.dev/api`
- `gh` / git HTTPS/SSH to GitHub
- pacman/AUR mirrors; Docker registry pulls
- speedtest-cli to speedtest.net
- Fisher/lazy.nvim git clones on first install

## First-party vs vendor boundary

**Use these as product/install code:**
- `arch/dots-hyprland.sh` — only supported ii install entry
- `arch/*.sh`, `debian/*.sh`, `ubuntu/*.sh`
- `stow/*`, `.config/hypr/`
- `scripts/*`, `docs/dots-hyprland-workflow.md`

**Do not implement features inside:**
- `vendor/dots-hyprland` — pin-bump submodule; run `vendor/dots-hyprland/./setup` only for non-allowlisted experiments (`exp-update`, `virtmon`, …)
- Retired: in-repo `.config/quickshell` and `arch/quickshell.sh` (removed; live tree is `~/.config/quickshell`)

## Package sources (Arch personal stack)

| Area | Script | Notable packages / remotes |
|------|--------|----------------------------|
| Base | `arch/necessary.sh` | base-devel, linux, NetworkManager, limine, Intel VA-API |
| Compositor | `arch/hyprland.sh` | hyprland ecosystem, swaync, blueman; AUR `gnome-network-displays` |
| ii shell | `arch/dots-hyprland.sh` | `illogical-impulse-*` meta pkgs via upstream `./setup` |
| Bar | `arch/waybar.sh` | waybar + jq/bc/python dual-run |
| Audio | `arch/audio.sh` | PipeWire, espeak-ng, festival |
| AUR helper | `arch/aur.sh` | yay-bin |
| Browser | `arch/google_chrome.sh` | AUR `google-chrome` |
| Editor GUI | `arch/vscode.sh` | AUR `visual-studio-code-bin` |

---

*Integration audit: 2026-08-21*
