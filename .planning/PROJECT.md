# Quickshell Desktop Shell

## Current Milestone: v0.1 Core Framework & Basic Bar

**Goal:** Establish the Quickshell foundation and replace basic Waybar functionality.

**Target features:**
- Material theme system integration
- Custom Quickshell shell (Waybar replacement)
- Essential bar modules (workspaces, clock, tray, network)
- Global shortcuts / IPC (foundation)

## What This Is

A custom Quickshell (QML) desktop shell for the Hyprland Wayland session, built fresh and modeled on the `dots-hyprland` `ii` quickshell architecture. It replaces three separate tools — Waybar (status bar), rofi (launcher + clipboard manager), and swaync (notification daemon) — with one unified, themeable, runtime-configurable shell. It is part of the `.dotfiles` personal Linux desktop environment.

## Core Value

The shell must reproduce every current Waybar module's functionality (workspaces, system metrics, network, ping monitor, weather, clock, music, volume, tray, notifications, power) so the desktop loses no capability in the switch — while gaining a launcher, clipboard manager, OSDs, quick toggles, and a GUI settings app.

## Requirements

### Validated

Existing infrastructure the new shell builds on (not replaced by this project):

- ✓ Hyprland Wayland session (compositor, workspaces, keybinds, window rules) — existing
- ✓ Self-hosted ping monitor (Flask + SQLite, `127.0.0.1:8765`, `/api/status`) — existing; new shell consumes it
- ✓ hyprlock screen lock — existing; intentionally kept (not replaced)
- ✓ hyprpaper wallpaper daemon — existing
- ✓ Catppuccin Mocha theme contract across Hyprland/swaync/rofi/cursors — existing
- ✓ Quickshell + ddcutil/i2c provisioning (`arch/quickshell.sh`) — existing (ddcutil re-introduction risk; see Constraints)
- ✓ Hyprland session bootstrap (`hyprland-session.service` → `graphical-session.target`) — existing

### Validated (this milestone)

- ✓ Material theme system (MaterialThemeLoader + scheme) adopted from dots-hyprland — Phase 1
- ✓ Quickshell foundation: directory structure, PanelLoader / panel families, service singletons, visible top bar — Phase 1 (FWK-01/03/04/05, THM-01/02)

### Active

- [ ] Custom Quickshell shell that fully replaces Waybar as the status bar (parity + cutover still open)
- [ ] App launcher that replaces rofi's `drun` mode
- [ ] Clipboard manager that replaces rofi's clipboard history mode
- [ ] Notification daemon + control center that replaces swaync
- [ ] Switchable panel families (multiple bar layouts, runtime-switchable) — structure present; productized switching later
- [ ] GUI settings app to tweak the shell without editing files
- [ ] Waybar-parity bar modules: workspaces, disk, cpu, memory, network, ping, weather (current), clock, weather (forecast), tray, music, volume, notifications, power
- [ ] OSD + popups: volume OSD, calendar popup, network popup, notification popups/center
- [ ] Quick toggles: bluetooth, night-light (hyprsunset), idle inhibitor, easyeffects, power profiles
- [ ] Productivity widgets: emoji picker, timer/stopwatch, todo, system-updates checker
- [ ] Ping monitor integration (shell reads `localhost:8765/api/status`)
- [ ] Global shortcuts / IPC to trigger launcher, clipboard, emoji picker, toggles
- [ ] Cutover: remove Waybar/rofi/swaync from Hyprland `exec-once` once parity is verified

### Out of Scope

- Brightness/backlight widget — ddcutil DDC/CI polling caused the iGPU crash documented in `issues/2026-07-16_igpu-flickering-hang-no-display.md`; Waybar's backlight module is already disabled. No ddcutil polling in the new shell.
- Quickshell lock screen — keeping hyprlock; not porting dots-hyprland's `LockScreen.qml`.
- AI chat service (dots-hyprland `Ai` + OpenAI/Mistral/Gemini strategies) — niche, not wanted.
- Booru image board (`Booru`/`BooruResponseData`) — niche, not wanted.
- Song recognition (`SongRec`) — niche, not wanted.
- LaTeX renderer (`LatexRenderer`) — niche, not wanted.
- Google Cloud / Translation (`GoogleCloud`, `Translation`, gCloud Vision/Translate) — niche, not wanted.
- Anti-flashbang shader (`HyprlandAntiFlashbangShader`) — not wanted.
- First-run / welcome onboarding (`FirstRunExperience`, `welcome.qml`) — personal setup, not needed.
- Conflict killer (`ConflictKiller`), privacy indicators (`Privacy`), system info service (`SystemInfo`) — not wanted.
- Iterating on the old deleted Quickshell (git HEAD) — this is a fresh build; the old code is reference only, not a baseline.
- Debian/Ubuntu parity for the new shell — primary target is Arch; distro parity is a separate concern.

## Context

**Current state (from `.planning/codebase/`):**
- The repo is a Hyprland (Wayland) personal desktop with per-distro Bash provisioning (arch/debian/ubuntu) and declarative configs under `.config/`.
- Waybar is the active status bar (`config.jsonc` + `style.css` + `mocha.css` + custom scripts: `system/memory.sh`, `alerts/earthquake.sh`, `weather/{curr_weather,forcast_weather,functions}.sh`, `network/ping_status.sh`).
- rofi handles app launching (`drun`) and clipboard history; swaync handles notifications + control center.
- An earlier Quickshell attempt exists in git HEAD (14 services, 15 widgets, 3 popups) but is **deleted in the working tree** (39 unstaged deletions). It is treated as reference only.
- `dots-hyprland` (`../dots-hyprland/`, a separate repo) is the inspiration source: its quickshell lives at `dots/.config/quickshell/ii/` — 586 QML files, 46 services, organized as `modules/{common,ii,settings,waffle}`, `panelFamilies/`, `services/`, `scripts/`, `defaults/`, `assets/`, plus `shell.qml`, `settings.qml`, `GlobalStates.qml`, `killDialog.qml`, `ReloadPopup.qml`. Entry point `shell.qml` loads panel families via `PanelLoader`, applies Material theme on startup, and wires global shortcuts/IPC.

**Why this project:**
- Consolidate three separate tools (waybar + rofi + swaync) into one coherent, customizable shell.
- Gain a richer shell (launcher, clipboard, OSDs, quick toggles, productivity widgets, GUI settings) that waybar/rofi/swaync don't provide unified.
- Adopt dots-hyprland's proven QML architecture (services singletons, panel families, Material theming, settings UI) rather than hand-rolling.

**Inspiration source specifics (dots-hyprland `ii/`):**
- Services pattern: singletons expose state; widget components render it; `qmldir` manifests per directory.
- Panel families: `IllogicalImpulseFamily` (ii) and `WaffleFamily` (waffle), switchable via `Config.options.panelFamily` + `PanelLoader` (LazyLoader).
- Theming: `MaterialThemeLoader.reapplyTheme()` on startup; `AdaptedMaterialScheme` model.
- Settings: `settings.qml` (22k chars) + `Config.qml` + `Persistent.qml`.
- Quick toggles model: `modules/common/models/quickToggles/` (Audio, Bluetooth, ColorPicker, DarkMode, EasyEffects, GameMode, IdleInhibitor, Mic, NightLight, Notification, PowerProfiles, ScreenSnip, ...).

## Constraints

- **Tech stack**: QML + Quickshell on Qt/Wayland; Hyprland compositor. Inspiration source is dots-hyprland's `ii` quickshell. — The shell must run under the existing Hyprland session.
- **Parity floor**: Every current Waybar module must have a working equivalent before Waybar is removed. — No functionality regression in the cutover.
- **No ddcutil polling**: No brightness/backlight widget using DDC/CI. — The `2026-07-16` post-mortem shows ddcutil bus hammering caused an iGPU hang/flicker; `arch/quickshell.sh` re-introduces ddcutil so any future backlight work must follow the post-mortem mitigation (sane polling interval + failure backoff), but this project skips backlight entirely.
- **Keep hyprlock**: Do not replace the screen lock. — User decision; hyprlock is working and stays.
- **Catppuccin vs Material theming**: The existing desktop is Catppuccin Mocha everywhere; dots-hyprland's Material theme system is being adopted. Whether to preserve Catppuccin colors via the Material scheme or move to Material defaults is a planning-phase decision. — Affects the entire look and must be resolved before widget styling.
- **Working-tree state**: 39 unstaged deletions under `.config/quickshell/` (the old attempt). GSD must not stage or revert these without explicit confirmation; planning docs commit only `.planning/` artifacts. — Prevents clobbering in-progress/uncommitted state.
- **Personal / machine-specific**: Hardcoded monitor names (DP-1, HDMI-A-2), timezone (Asia/Dhaka), ping monitor bind host, conda paths. — Acceptable for a personal dotfiles repo; document machine-specific knobs in the shell config.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Fresh build, not iterating on old Quickshell | Old attempt deleted in working tree; adopt dots-hyprland architecture cleanly rather than refactor | Done — wholesale ii tree (Phase 1) |
| Replace waybar + rofi + swaync with one Quickshell shell | Consolidate tools; gain unified richer shell | In progress — foundation up; Waybar still coexists |
| Adopt Material theme + panel families + GUI settings app | Maximalist "broad desktop shell" per user choice | Theme + families done (Phase 1); settings app later |
| Skip brightness/backlight (no ddcutil) | iGPU crash risk per `2026-07-16` post-mortem | Accepted — ddcutil still in packages; no Phase 1 backlight goal |
| Keep hyprlock (no Quickshell lock screen) | hyprlock works; lock screen panel not wanted | Held |
| Theming: Material vibrant dark seed #7aa2f7 | Static theme gen for MaterialThemeLoader | Done Phase 1 — user confirmed colors applied |
| Font fallbacks: Noto Sans + Material Symbols | Google Sans Flex / missing Material Symbols broke bar icons | Done Phase 1 gap 01-04 |
| Stock Hyprland `workspace` dispatch | `hl.dsp.focus` needs plugin not installed | Done Phase 1 gap 01-04 |
| Primary target Arch only | debian/ubuntu parity is a separate concern | Held |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-07-21 after Phase 1*
