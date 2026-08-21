# Codebase Concerns

**Analysis Date:** 2026-08-21

## Tech Debt

**`arch/dots-hyprland.sh` size and dual ownership:**
- Issue: Wrapper is ~1533 lines (`arch/dots-hyprland.sh`) covering allowlist, backup gate, uninstall, protect, hook editing, and pacman `--asexplicit` healing. Product UI still lives in upstream `vendor/dots-hyprland`; first-party safety logic is concentrated in one file.
- Files: `arch/dots-hyprland.sh`, `docs/dots-hyprland-workflow.md`
- Impact: Hard to review changes; uninstall/protect bugs can cascade-delete personal packages if `--upstream-dangerous` is used.
- Fix approach: Split wrapper into sourced modules (`install.sh`, `uninstall.sh`, `protect.sh`, `hooks.sh`) under `arch/lib/` without changing the public `arch/dots-hyprland.sh` CLI.

**Debian/Ubuntu installer duplication:**
- Issue: Near-copy scripts exist in `debian/` and `ubuntu/` (nvim, wezterm, zsh, docker, tools, fonts). Docs state Arch is primary (`docs/dots-hyprland-workflow.md`).
- Files: `debian/*.sh`, `ubuntu/*.sh`
- Impact: Fixes land on one distro only (e.g. `debian/system_monitor.sh` vs `ubuntu/monitor_system.sh` naming).
- Fix approach: Treat `arch/` as source of truth; extract shared curl/stow helpers or freeze Debian/Ubuntu as unsupported copies.

**Hypr vs stow split:**
- Issue: Hyprland configs live in repo-root `.config/hypr/` and are copied with `cp -rf`, while most apps use GNU Stow from `stow/`. Waybar uses a custom `install` sync in `arch/waybar.sh` instead of `stow waybar`.
- Files: `arch/hyprland.sh`, `.config/hypr/hyprland.conf`, `stow/waybar/`, `arch/waybar.sh`
- Impact: Three deploy mechanisms; easy to edit the wrong tree.
- Fix approach: Stow hypr too, or document “hypr is copy, rest is stow” in `arch/README.md`. Keep waybar file-sync if stow cannot replace `STALE_MANAGED_*` cleanup.

**Commented-out debug noise in weather scripts:**
- Issue: Hundreds of `: # echo ... >>"$LOG_FILE"` no-ops remain in weather modules.
- Files: `stow/waybar/.config/waybar/scripts/weather/forcast_weather.sh`, `stow/waybar/.config/waybar/scripts/weather/functions.sh`, `stow/waybar/.config/waybar/scripts/weather/curr_weather.sh`
- Impact: Hard to read; typo in filename `forcast_weather.sh` is baked into `arch/waybar.sh` `MANAGED_FILES`.
- Fix approach: Delete no-ops; rename forecast files in lockstep with `arch/waybar.sh`.

**Hardcoded machine identity in docs and configs:**
- Issue: `arch/README.md` embeds a specific root UUID and `useradd … pera`. `stow/qbittorrent/.config/qBittorrent/qBittorrent.conf` hardcodes `/home/pera/Downloads` and Qt binary state blobs.
- Files: `arch/README.md`, `stow/qbittorrent/.config/qBittorrent/qBittorrent.conf`
- Impact: Blind copy on another machine points bootloader/root or torrent paths at the wrong user.
- Fix approach: Replace UUID with `blkid` placeholders; stow only a minimal qBittorrent template (ports, theme), not GUI state.

**Submodule fork pin:**
- Issue: `vendor/dots-hyprland` is a personal fork (`git@github.com:humam-hossain/dots-hyprland.git` in `.gitmodules`), not end-4 upstream. Vendor tree also contains built `pkg/`, `.pkg.tar.zst`, and compile artifacts under `vendor/dots-hyprland/sdata/dist-arch/` (upstream cache, not first-party).
- Files: `.gitmodules`, `vendor/dots-hyprland/`
- Impact: Pin drift vs end-4; large working tree if submodule is dirty.
- Fix approach: Follow `docs/dots-hyprland-workflow.md` pin-bump only; never edit vendor as first-party product.

## Known Bugs

**`arch/hyprland.sh` copies hypr from CWD, not repo root:**
- Symptoms: `cp -rf .config/hypr/* ~/.config/hypr/` fails or copies the wrong tree if the script is not invoked with CWD = repo root.
- Files: `arch/hyprland.sh` (copy step after package install)
- Trigger: `cd arch && ./hyprland.sh` or run via absolute path from `$HOME`.
- Workaround: Always run from repo root. Fix: use `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` then `cp -rf "$REPO_ROOT/.config/hypr/"*`.

**`arch/wakatime.sh` prints the API key:**
- Symptoms: After writing `~/.wakatime.cfg`, the script `cat`s the file (key in terminal scrollback / `set -x` traces).
- Files: `arch/wakatime.sh`
- Trigger: Running the installer.
- Workaround: Do not share the terminal log. Fix: drop `cat`; use `read -s`.

**`stow/define/define.sh` checks `$?` after assignment:**
- Symptoms: `query=$(curl …)` then `[ $? -ne 0 ]` tests the assignment/`[[` status, not curl’s, so connection errors can look like “invalid word”.
- Files: `stow/define/define.sh`
- Trigger: Network failure to `api.dictionaryapi.dev`.
- Workaround: None. Fix: `if ! query=$(curl -fsS …); then`.

**`scripts/clone_repo.sh` clones into CWD with short names:**
- Symptoms: `gh repo clone "$repo"` uses the repo basename as directory in the current working directory; can collide or dump 1000 repos into an unexpected folder.
- Files: `scripts/clone_repo.sh`
- Trigger: Running from `$HOME` or `.dotfiles`.
- Workaround: `cd` to a dedicated clones dir first.

**Hypr `autogenerated` banner still present:**
- Symptoms: `.config/hypr/hyprland.conf` still starts with “AUTOGENERATED HYPRLAND CONFIG” even though `autogenerated = 0`.
- Files: `.config/hypr/hyprland.conf`
- Trigger: Cosmetic; confuses operators about whether this is the live personal config.
- Workaround: Ignore banner. Fix: replace header with a first-party comment pointing at dual-run hooks.

## Security Considerations

**Pipe-to-shell remote installers:**
- Risk: Unsigned remote scripts executed as the user (Oh My Zsh, fisher).
- Files: `arch/zsh_powerlevel.sh`, `debian/zsh.sh`, `ubuntu/zsh.sh`, `arch/fish.sh`
- Current mitigation: None (plain `curl | sh` / `curl | source`).
- Recommendations: Pin commit SHAs; vendor installers; or skip OMZ if Starship + plugins in `arch/zsh.sh` already cover the shell.

**Unattended `pacman`/`yay --noconfirm`:**
- Risk: Installers mutate the system without review; AUR (`yay` in `arch/hyprland.sh`) runs PKGBUILDs.
- Files: `arch/necessary.sh`, `arch/hyprland.sh`, `arch/*.sh`
- Current mitigation: Personal machine assumption; dots-hyprland wrapper injects `--skip-sysupdate` by default (`arch/dots-hyprland.sh`).
- Recommendations: Keep `--noconfirm` only on `pacman -S --needed`; never add unattended `yay -Rns` outside the documented `--upstream-dangerous` path.

**WakaTime / secrets in gitignore gaps:**
- Risk: `.gitignore` ignores `.config/system_monitor/ping/.env` (repo-root shaped) but **`stow/system_monitor/.config/system_monitor/ping/.env` is tracked** (`git ls-files`). `~/.wakatime.cfg` is a home file (not in repo) but `arch/wakatime.sh` cats it. qBittorrent lock/data files are ignored; the main conf with home paths is committed.
- Files: `.gitignore`, `stow/system_monitor/.config/system_monitor/ping/.env`, `arch/wakatime.sh`, `stow/qbittorrent/.config/qBittorrent/qBittorrent.conf`
- Current mitigation: Home-shaped ping `.env` listed in `.gitignore`; stow copy is not.
- Recommendations: Untrack/gitignore the stow `.env` (do not quote its contents); never commit API keys; keep `.wakatime.cfg` out of the repo; strip personal paths from qBittorrent; drop `cat` of the wakatime cfg.

**System monitor HTTP surface:**
- Risk: `stow/system_monitor/.config/system_monitor/ping/server.py` is a custom ThreadingHTTPServer. Default bind is `127.0.0.1:8765` (`BIND_HOST` env). Mis-set bind exposes ping/status JSON on LAN.
- Files: `stow/system_monitor/.config/system_monitor/ping/server.py`, `arch/system_monitor.sh`, `debian/system_monitor.sh`
- Current mitigation: Default loopback bind; host sanitization regex `_SHELL_META`.
- Recommendations: Keep default 127.0.0.1; do not document 0.0.0.0 without auth.

**Dictionary lookup interpolates clipboard into URL:**
- Risk: `stow/define/define.sh` sends clipboard text to a public API. Slash-only filter; other injection is URL-path based.
- Files: `stow/define/define.sh`
- Current mitigation: Reject empty/`/` words; curl timeouts.
- Recommendations: URL-encode with `jq -sRr @uri`; cap length.

## Performance Bottlenecks

**Waybar weather + forecast on a timer:**
- Problem: `forcast_weather.sh` is large (~368 lines) and shells out to `bc`, `date`, `jq`, and Open-Meteo (coords in `stow/waybar/.config/waybar/scripts/weather/functions.sh`: `LATITUDE=23.758492`, `LONGITUDE=90.390055`). Cache is 900s.
- Files: `stow/waybar/.config/waybar/scripts/weather/*.sh`
- Cause: Bash JSON + icon mapping on every module tick if cache misses.
- Improvement path: Keep cache; fail closed to last JSON; avoid spawning `bc` per field.

**Ping collector interval:**
- Problem: `server.py` default `COLLECTION_INTERVAL=5` with `ping -c3` per target on a thread pool.
- Files: `stow/system_monitor/.config/system_monitor/ping/server.py`
- Cause: Continuous ICMP + SQLite writes.
- Improvement path: Raise interval on battery/idle; WAL mode already implied by sqlite usage—keep bind local.

**Dual-run desktop shell:**
- Problem: Hyprland starts **both** `waybar` and `qs -c ii` (`exec-once` in `.config/hypr/hyprland.conf`). Two bars, two QML/GTK stacks.
- Files: `.config/hypr/hyprland.conf`, `docs/dots-hyprland-workflow.md`
- Cause: Intentional dual-run during ii adoption.
- Improvement path: After ii is trusted, drop `waybar` from `exec-once` via a documented flag in the wrapper—not by editing vendor.

## Fragile Areas

**Personal Hyprland session + ii hooks:**
- Files: `.config/hypr/hyprland.conf`, `arch/dots-hyprland.sh`, `arch/hyprland.sh`
- Why fragile: Monitor names `DP-1` / `HDMI-A-2`, workspace splits, `exec-once = qs -c ii`, and `env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv` are machine-specific. Wrapper uninstall edits these lines in **both** `$HOME/.config/hypr` and repo `.config/hypr`.
- Safe modification: Change hooks only through `arch/dots-hyprland.sh uninstall` / install backup gate. Do not pass `--full` unless you accept hypr overwrite. Never call `vendor/dots-hyprland/./setup uninstall` without `--upstream-dangerous`.
- Test coverage: `scripts/phase07-live-smoke.sh`, `scripts/phase12-full-smoke.sh`, `scripts/phase04-ipc-reload-assert.py` — live session required; not a substitute for a cold-machine dry-run.

**i915 vs experimental `xe` GPU driver:**
- Files: `issues/2026-07-16_igpu-flickering-hang-no-display.md`
- Why fragile: Kernel cmdline `i915.force_probe=!4680 xe.force_probe=4680` caused hangs/no-display on Intel UHD 770. Resolved by leaving `xe` off.
- Safe modification: Do not add `xe.force_probe` to loader entries in `arch/README.md` or hypr env.
- Test coverage: Hardware-only; no automated test.

**Stow vs live `~/.config` drift:**
- Files: `stow/*`, `arch/*.sh`
- Why fragile: Stow packages assume empty targets; existing files cause stow conflicts. Waybar bypasses stow with `install -D` so live edits in `~/.config/waybar` are overwritten on next `arch/waybar.sh`.
- Safe modification: Edit `stow/waybar/.config/waybar/…` then re-run `arch/waybar.sh`. Do not edit only the live copy.
- Test coverage: `arch/waybar.sh` has `[VERIFY]` presence checks only.

**`set -x` on almost all Arch installers:**
- Files: `arch/*.sh` (except `arch/dots-hyprland.sh`, `arch/scrutiny.sh`)
- Why fragile: Every command is printed; secrets (wakatime) leak; CI logs explode.
- Safe modification: Drop `set -x` from production installers; keep labeled `echo "[INSTALL]"`.

## Scaling Limits

**GitHub clone helper:**
- Current capacity: `gh repo list --limit 1000` then sequential clone (`scripts/clone_repo.sh`).
- Limit: API rate limits; disk; notification spam (`notify-send` per repo).
- Scaling path: Filter by topic; clone in parallel with a cap; skip notify except summary.

**Vendor submodule working tree:**
- Current capacity: Full dots-hyprland including `sdata/dist-arch` build outputs.
- Limit: Clone size and `git status` noise if those artifacts are dirty inside the submodule.
- Scaling path: Sparse checkout or ensure submodule gitignore (upstream) covers `pkg/` and `*.pkg.tar.zst`. Do not add first-party cleanups that rewrite vendor.

**Pacman `-Sy` per script:**
- Current capacity: Each `arch/*.sh` refreshes sync DBs (`pacman -Sy --noconfirm --needed`).
- Limit: Partial upgrades if scripts are mixed with skipped `-Syu`; many round-trips on a full bootstrap.
- Scaling path: One `necessary.sh`/`pacman -Syu` then `-S --needed` without `-y` in leaf scripts.

## Dependencies at Risk

**AUR `yay` + gnome-network-displays:**
- Risk: AUR package build can break independently of Arch official repos.
- Impact: `arch/hyprland.sh` fails at the `yay` line after official packages are already installed.
- Migration plan: Gate AUR behind an optional function; official packages first.

**Oh My Zsh remote installer:**
- Risk: Upstream install.sh changes; conflicts with first-party `stow/zsh` + Starship (`arch/zsh.sh` already installs starship).
- Impact: Duplicate plugin managers (`arch/zsh.sh` clones autosuggestions/syntax-highlighting; OMZ does too).
- Migration plan: Pick one: plugin git clones **or** OMZ, not both (`arch/zsh.sh` vs `arch/zsh_powerlevel.sh`).

**illogical-impulse meta packages:**
- Risk: Upstream `./setup uninstall` uses `yay -Rns` and can cascade `hyprland`/CLI tools.
- Impact: Session death if someone bypasses the wrapper.
- Migration plan: Documented in wrapper help — only `arch/dots-hyprland.sh uninstall`; treat vendor uninstall as dangerous.

**Dictionary / seismic / weather third parties:**
- Risk: `api.dictionaryapi.dev`, `seismicportal.eu`, Open-Meteo can rate-limit or change JSON.
- Impact: Waybar modules show error JSON; define.sh notifications fail.
- Migration plan: Cache + static fallback strings (weather already caches 900s).

## Missing Critical Features

**No single Arch bootstrap orchestrator:**
- Problem: `arch/` is a bag of scripts with no `install-all` order (necessary → hyprland → waybar → dots-hyprland → stow packages).
- Blocks: Cold-machine reproducibility without reading `docs/dots-hyprland-workflow.md` plus tribal script order.

**Debian/Ubuntu Hyprland path:**
- Problem: Workflow explicitly out of scope; `debian/`/`ubuntu/` have no dots-hyprland wrapper.
- Blocks: Non-Arch machines cannot follow the dual-run playbook.

**No automated non-interactive full install test:**
- Problem: Phase scripts (`scripts/phase*.sh`, `scripts/phase*.py`) assert configs and smoke flags; they do not provision a VM.
- Blocks: Catching `arch/hyprland.sh` CWD bug and stow conflicts before they hit the live session.

**Parent `hypr/custom` overlay tree missing:**
- Problem: Upstream `hyprland.lua` requires `custom/*.lua` from live `~/.config/hypr/custom/` (`vendor/dots-hyprland/dots/.config/hypr/hyprland.lua`). Parent authoring SoT `.config/hypr/custom/` does not exist. Dual-run still uses `.config/hypr/hyprland.conf` only.
- Blocks: Full hypr files adopt cannot apply machine monitors/workspace pins from this repo until `general.lua` (and empty `env.lua` / `execs.lua` slots) exist here.

## Test Coverage Gaps

**Installer scripts (Arch):**
- What's not tested: `arch/hyprland.sh` copy-from-CWD, `arch/zsh.sh` chsh, AUR `yay` path, `arch/wakatime.sh` secret handling.
- Files: `arch/*.sh`
- Risk: Destructive `pacman`/`cp -rf` on the only workstation.
- Priority: High for hypr copy and dots-hyprland uninstall; Medium for leaf package scripts.

**Waybar modules:**
- What's not tested: weather `jq`/`bc` paths, earthquake JSON empty features, ping_status.
- Files: `stow/waybar/.config/waybar/scripts/`
- Risk: Bar modules print invalid JSON and break Waybar custom modules.
- Priority: Medium — add `jq` fixture tests in `scripts/`.

**System monitor server:**
- What's not tested: HTTP handlers, SQL schema, host sanitization beyond regex presence.
- Files: `stow/system_monitor/.config/system_monitor/ping/server.py`
- Risk: Crash loop of the systemd user unit; empty Waybar status.
- Priority: Medium.

**Neovim:**
- What's not tested: Runtime plugin health is scanned by `scripts/nvim-validate.sh` / `scripts/nvim-audit-failures.sh` (TODO/FIXME in Lua), not unit tests. Harness `-u "$REPO_ROOT/.config/nvim/init.lua"` points at a path that **does not exist**; SoT is `stow/nvim/.config/nvim/init.lua`.
- Files: `stow/nvim/`, `scripts/nvim-validate.sh`
- Risk: Harness cannot start against the repo as laid out; broken LSP on new machines is undetected.
- Priority: High for the harness path; Low for ii phases (nvim is stow product, not ii).

**Retired in-repo Quickshell fixture:**
- What's not tested: `scripts/phase04-ipc-reload-assert.py` reads `REPO_ROOT/.config/quickshell/modules/ii/bar/Bar.qml` (and `shell.qml`, `GlobalStates.qml`). Those files are **not in the repo**; live product is `~/.config/quickshell`.
- Files: `scripts/phase04-ipc-reload-assert.py`
- Risk: Phase 04 assert fails or is skipped on a clean clone; IPC contract is only checkable against a live install.
- Priority: High before treating phase04 as an in-tree gate.

**Vendor upstream:**
- What's not tested (first-party): Do not add tests that execute `vendor/dots-hyprland/./setup uninstall` without the wrapper.
- Files: `vendor/dots-hyprland/` (upstream)
- Risk: Cascade package removal.
- Priority: High — keep using `arch/dots-hyprland.sh --dry-run` only.

---

*Concerns audit: 2026-08-21*
