# Quickshell Desktop Shell

## Current State

**Shipped:** v0.1 Core Framework & Basic Bar (2026-07-25)

Usable Quickshell top bar dual-running with Waybar. Material-themed IllogicalImpulseFamily shell with workspaces, clock, tray, network, CPU/RAM/disk rings, volume indicators, stock bar IPC, and same-PID soft reload. Finishing touches (exec-once, bar keybind) and full Waybar cutover remain for a later milestone.

**Stats at ship:** 4 phases · 31 plans · 39 tasks · ~589 QML files · ~57k LOC under `.config/quickshell/`

## Next Milestone Goals

Define via `/gsd-new-milestone`. Likely candidates (not locked):

- Finishing touches: FWK-02 exec-once + IPC-02 bar keybind
- Resolve open debug sessions (resource colors, volume ceiling, pavucontrol launch, RAM spacing)
- Waybar cutover when SC-5 parity is accepted
- Custom modules: weather, ping monitor, earthquake alerts
- Launcher / clipboard (rofi replacement)
- Notification daemon (swaync replacement)

## What This Is

A custom Quickshell (QML) desktop shell for the Hyprland Wayland session, built fresh and modeled on the `dots-hyprland` `ii` quickshell architecture. It replaces three separate tools — Waybar (status bar), rofi (launcher + clipboard manager), and swaync (notification daemon) — with one unified, themeable, runtime-configurable shell. It is part of the `.dotfiles` personal Linux desktop environment.

**v0.1 status:** Bar foundation and core modules ship; Waybar still coexists until cutover.

## Core Value

The shell must reproduce every current Waybar module's functionality (workspaces, system metrics, network, ping monitor, weather, clock, music, volume, tray, notifications, power) so the desktop loses no capability in the switch — while gaining a launcher, clipboard manager, OSDs, quick toggles, and a GUI settings app.

*Still correct after v0.1 — core value remains full parity before cutover, not feature sprawl.*

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

### Validated — v0.1

- ✓ Material theme system (MaterialThemeLoader + scheme) — v0.1 Phase 1
- ✓ Quickshell foundation: directory structure, PanelLoader / panel families, service singletons, visible top bar — v0.1 (FWK-01/03/04/05, THM-01/02)
- ✓ Core bar modules: workspaces, clock, system tray, network status — v0.1 Phase 2 (BAR-01..04)
- ✓ System metrics: CPU, RAM, disk rings with dual thresholds — v0.1 Phase 3 (BAR-05..07)
- ✓ Audio volume from bar (scroll, mute, 130% ceiling, auto-unmute) — v0.1 Phase 3 (BAR-08)
- ✓ IPC socket for bar open/close/toggle — v0.1 Phase 4 (IPC-01)
- ✓ Graceful soft reload without full restart (same PID, silent) — v0.1 Phase 4 (IPC-03)

### Active (carry-forward / next milestones)

- [ ] FWK-02: Quickshell auto-start via Hyprland exec-once (deferred from v0.1)
- [ ] IPC-02: Hyprland keybind to toggle bar visibility (deferred from v0.1)
- [ ] Cutover: remove Waybar/rofi/swaync from Hyprland `exec-once` once parity is verified
- [ ] Custom Quickshell shell that fully replaces Waybar as the status bar (parity + cutover still open)
- [ ] App launcher that replaces rofi's `drun` mode
- [ ] Clipboard manager that replaces rofi's clipboard history mode
- [ ] Notification daemon + control center that replaces swaync
- [ ] Switchable panel families (structure present; productized switching later)
- [ ] GUI settings app to tweak the shell without editing files
- [ ] Remaining Waybar-parity modules: ping, weather (current + forecast), music, notifications, power
- [ ] OSD + popups productization beyond stock surfaces
- [ ] Quick toggles: bluetooth, night-light (hyprsunset), idle inhibitor, easyeffects, power profiles
- [ ] Productivity widgets: emoji picker, timer/stopwatch, todo, system-updates checker
- [ ] Ping monitor integration (shell reads `localhost:8765/api/status`)
- [ ] Global shortcuts / IPC for launcher, clipboard, emoji picker, toggles

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

*Out-of-scope reasons still valid after v0.1.*

## Context

**Shipped v0.1 (2026-07-25):**
- `.config/quickshell/` is a live dots-hyprland-derived shell (~589 QML files, ~57k LOC).
- Dual-write config: `Config.qml` + `~/.config/illogical-impulse/config.json`.
- Bar layout: left sidebar button → workspaces → resources; center clock+utils; right indicators + tray.
- Waybar still runs in parallel; Quickshell is not yet on `exec-once`.
- Soft reload: content-change file-watch (Quickshell 0.3.0 has no `qs reload` CLI).
- Open polish items tracked as deferred debug sessions + FWK-02/IPC-02 finishing touches.

**Why this project:**
- Consolidate three separate tools (waybar + rofi + swaync) into one coherent, customizable shell.
- Gain a richer shell (launcher, clipboard, OSDs, quick toggles, productivity widgets, GUI settings).
- Adopt dots-hyprland's proven QML architecture rather than hand-rolling.

## Constraints

- **Tech stack**: QML + Quickshell on Qt/Wayland; Hyprland compositor. Inspiration source is dots-hyprland's `ii` quickshell.
- **Parity floor**: Every current Waybar module must have a working equivalent before Waybar is removed.
- **No ddcutil polling**: No brightness/backlight widget using DDC/CI.
- **Keep hyprlock**: Do not replace the screen lock.
- **Catppuccin vs Material theming**: Desktop was Catppuccin Mocha; v0.1 ships Material vibrant dark seed `#7aa2f7`. Further Catppuccin adapter is optional later work.
- **Personal / machine-specific**: Hardcoded monitor names (DP-1, HDMI-A-2), timezone (Asia/Dhaka), ping monitor bind host, conda paths.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Fresh build, not iterating on old Quickshell | Old attempt deleted in working tree; adopt dots-hyprland architecture cleanly | ✓ Good — wholesale ii tree (v0.1 P1) |
| Replace waybar + rofi + swaync with one Quickshell shell | Consolidate tools; gain unified richer shell | ⚠️ Revisit — foundation up; Waybar still coexists |
| Adopt Material theme + panel families + GUI settings app | Maximalist "broad desktop shell" per user choice | ✓ Theme + families done; settings app later |
| Skip brightness/backlight (no ddcutil) | iGPU crash risk per `2026-07-16` post-mortem | ✓ Good |
| Keep hyprlock (no Quickshell lock screen) | hyprlock works; lock screen panel not wanted | ✓ Good |
| Theming: Material vibrant dark seed #7aa2f7 | Static theme gen for MaterialThemeLoader | ✓ Good |
| Font fallbacks: Noto Sans + Material Symbols | Missing fonts broke bar icons | ✓ Good |
| Stock Hyprland `workspace` dispatch | `hl.dsp.focus` needs plugin not installed | ✓ Good |
| Dual-write Config.qml + live config.json | Runtime-active defaults without losing QML defaults | ✓ Good |
| Always-visible indicator strip (not hide-when-idle) | UAT: empty network-only pill was confusing | ✓ Good |
| Volume ceiling 130% + auto-unmute all paths | Match desired desktop behavior; no silent 100% cap | ✓ Good (debug: keyboard ceiling polish open) |
| Phase 4: verify stock IPC/reload only; defer keybind/exec-once | Avoid hyprland.conf product edits until ready | ✓ Good — packaged in 04-DEFERRED.md |
| Soft reload = file-watch content change | QS 0.3.0 has no reload CLI | ✓ Good |
| Primary target Arch only | debian/ubuntu parity is a separate concern | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-07-25 after v0.1 milestone*
