# Quickshell Desktop Shell

## Current Milestone: v0.2 Adopt dots-hyprland

**Goal:** Stop owning a hand-rolled Quickshell product tree; install end-4/dots-hyprland properly as a personal fork + git submodule and wire it into the `.dotfiles` Arch install style.

**Target features:**
- Personal GitHub fork of end-4/dots-hyprland with `origin` = fork, `upstream` = end-4
- Git submodule at `vendor/dots-hyprland` inside `.dotfiles`
- Thin `arch/` wrapper that drives upstream `./setup` (install / deps / files)
- Session/install path uses the installed illogical-impulse shell (not local `.config/quickshell`)
- Remove v0.1 local Quickshell product: uninstall/stop shipping, delete the tree, retire `arch/quickshell.sh`
- Document how this fits the overall `.dotfiles` workflow

**Not this milestone:** Waybar custom module ports (ping, weather, earthquake, etc.), full Waybar/rofi/swaync cutover, deep theming beyond “install works and is managed.”

## Current State

**Shipped:** v0.1 Core Framework & Basic Bar (2026-07-25)

Usable Quickshell top bar dual-running with Waybar (Material-themed ii shell). That in-tree product path is being **retired in v0.2** in favor of installing and owning [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) via fork + submodule.

**Stats at v0.1 ship:** 4 phases · 31 plans · 39 tasks · ~589 QML files · ~57k LOC under `.config/quickshell/`

**Phase 8 complete (2026-07-28; UAT 2026-07-29):** Retired in-repo v0.1 product — deleted `.config/quickshell` (933 files, RET-01) and hard-deleted `arch/quickshell.sh` (RET-02, no stub). Live `~/.config/quickshell` ii install intact; sole Arch install entry is `arch/dots-hyprland.sh`. Human UAT **12/12 pass** (0 issues).

**Phase 7 complete (2026-07-27):** Live wrapper install + personal hypr hooks; dual-run waybar + `qs -c ii`; LIVE-01..04 verified (UAT 14/14, security threats_open 0, Nyquist compliant).

**Phase 6 complete (2026-07-26):** `arch/dots-hyprland.sh` thin wrapper with safe defaults + backup gate (WRAP-01..04).

**Phase 5 complete (2026-07-25):** Public fork `humam-hossain/dots-hyprland` + submodule pin at `vendor/dots-hyprland` (`1a9ffb78`, dual remotes, nested shapes).

## What This Is

A personal Hyprland desktop shell setup, part of the `.dotfiles` Linux environment. **v0.2+ delivery model:** adopt upstream **illogical-impulse** (dots-hyprland) as a managed dependency — fork for ownership, submodule for pin/repro, thin Arch install wrappers for the existing `.dotfiles` style — then customize later for Waybar-parity needs.

**v0.1** built a local Quickshell tree modeled on dots-hyprland `ii`. **v0.2** switches the product vehicle to the real upstream install rather than maintaining a vendored rewrite.

## Core Value

The desktop must keep (and eventually exceed) current Waybar-era capability — workspaces, system metrics, network, ping, weather, clock, music, volume, tray, notifications, power — while consolidating toward one themeable shell. Delivery is via **upstream dots-hyprland + personal overlays**, not a from-scratch QML rewrite.

## Requirements

### Validated

Existing infrastructure the shell builds on (not replaced by this project):

- ✓ Hyprland Wayland session (compositor, workspaces, keybinds, window rules) — existing
- ✓ Self-hosted ping monitor (Flask + SQLite, `127.0.0.1:8765`, `/api/status`) — existing; future shell modules consume it
- ✓ hyprlock screen lock — existing; intentionally kept (not replaced)
- ✓ hyprpaper wallpaper daemon — existing
- ✓ Catppuccin Mocha theme contract across Hyprland/swaync/rofi/cursors — existing (Material from ii may coexist or supersede later)
- ✓ Quickshell + ddcutil/i2c provisioning — existing path was `arch/quickshell.sh`; **retired in Phase 8** (RET-02 hard-delete; use `arch/dots-hyprland.sh`)
- ✓ Hyprland session bootstrap (`hyprland-session.service` → `graphical-session.target`) — existing

### Validated — v0.1

- ✓ Material theme system (MaterialThemeLoader + scheme) — v0.1 Phase 1
- ✓ Quickshell foundation: directory structure, PanelLoader / panel families, service singletons, visible top bar — v0.1
- ✓ Core bar modules: workspaces, clock, system tray, network status — v0.1 Phase 2
- ✓ System metrics: CPU, RAM, disk rings with dual thresholds — v0.1 Phase 3
- ✓ Audio volume from bar (scroll, mute, 130% ceiling, auto-unmute) — v0.1 Phase 3
- ✓ IPC socket for bar open/close/toggle — v0.1 Phase 4
- ✓ Graceful soft reload without full restart (same PID, silent) — v0.1 Phase 4

*Note: v0.1 validated capabilities describe the retired local tree. v0.2 re-establishes a live shell via upstream install; parity of specific modules is re-verified against the installed product, not assumed from the deleted tree.*


### Validated — v0.2

- ✓ Personal public fork of end-4/dots-hyprland with dual remotes (origin=fork, upstream=end-4) — Validated in Phase 5: Fork & Submodule Pin
- ✓ Git submodule at `vendor/dots-hyprland` pinned in parent (mode 160000) — Validated in Phase 5
- ✓ Nested shapes submodule initializes recursively (OWN-03) — Validated in Phase 5

### Validated — v0.2 (Phase 6)

- ✓ Thin `arch/dots-hyprland.sh` wrapper around upstream `./setup` with safe dual-run defaults and backup gate — Validated in Phase 6

### Validated — v0.2 (Phase 7)

- ✓ Live session uses installed illogical-impulse shell (real `~/.config/quickshell` tree, not symlink into git) — LIVE-01
- ✓ Personal Hyprland hooks: `ILLOGICAL_IMPULSE_VIRTUAL_ENV` + `exec-once = qs -c ii` — LIVE-02
- ✓ Waybar dual-run preserved (session pieces policy) — LIVE-03
- ✓ Operator-visible ii/Quickshell chrome with `qs -c ii` + venv env — LIVE-04

### Validated — v0.2 (Phase 8)

- ✓ In-repo v0.1 `.config/quickshell` product tree removed from `.dotfiles` (no longer shipped) — RET-01 / Validated in Phase 8
- ✓ `arch/quickshell.sh` hard-deleted (no deprecation stub); sole install entry `arch/dots-hyprland.sh` — RET-02 / Validated in Phase 8
- ✓ Live session still runs ii from installed `~/.config/quickshell` after retirement (not symlink-at-repo) — Phase 8 success criterion 3

### Active (v0.2)

- [x] Document `.dotfiles` workflow for fork/submodule/install/update — **done:** [docs/dots-hyprland-workflow.md](../docs/dots-hyprland-workflow.md) (Phase 9, DOC-01/DOC-02)

### Active (carry-forward / later milestones)

- [ ] Port Waybar customs into ii: ping, weather (+ forecast), earthquake, etc.
- [ ] FWK-02 / IPC-02 style session integration as needed under upstream model
- [ ] Cutover: remove Waybar/rofi/swaync from Hyprland `exec-once` once parity is verified
- [ ] App launcher / clipboard / notification daemon productization if not satisfied by stock ii
- [ ] GUI settings app, quick toggles, productivity widgets as needed
- [ ] Open v0.1 debug polish items (only if still relevant after switch)

### Out of Scope

- Brightness/backlight widget — ddcutil DDC/CI polling caused the iGPU crash documented in `issues/2026-07-16_igpu-flickering-hang-no-display.md`; Waybar's backlight module is already disabled. No ddcutil polling in the shell.
- Quickshell lock screen — keeping hyprlock; not porting dots-hyprland's `LockScreen.qml` as a replacement for hyprlock.
- AI chat service, Booru, SongRec, LaTeX renderer, Google Cloud/Translation, Anti-flashbang, First-run onboarding — niche / not wanted (may exist upstream; do not invest in enabling them).
- Continuing the hand-rolled local Quickshell product tree as the primary shell — retired in v0.2.
- Waybar custom module ports in v0.2 — deferred to a later milestone.
- Full Waybar/rofi/swaync cutover in v0.2 — dual-run acceptable until later.
- Debian/Ubuntu parity for the new shell path — primary target is Arch.

## Context

**Strategic pivot (v0.2):**
- Upstream [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) “works good enough”; prefer install + customize over maintaining a forked-in-spirit local rewrite.
- Layout: submodule at `vendor/dots-hyprland`; personal fork + `upstream` remote; thin wrapper calls `./setup`.
- Existing clone at `~/github_repo/dots-hyprland` may seed fork/submodule work.
- `.dotfiles` style: `arch/*.sh` install scripts, REPO_ROOT-relative, labeled echos — wrappers must match that feel.
- Waybar still runs; customs (ping @ `127.0.0.1:8765`, weather, earthquake, music, memory) remain the long-term customization backlog.

**Why this project (updated):**
- Consolidate desktop shell tooling via a proven upstream, not a second maintenance surface.
- Keep personal control (fork) and reproducibility (submodule pin) inside `.dotfiles`.
- Customize later for machine-specific Waybar-era needs.

## Constraints

- **Tech stack**: QML + Quickshell on Qt/Wayland; Hyprland; illogical-impulse via dots-hyprland.
- **Install model**: Upstream `./setup` is source of truth for install steps; `.dotfiles` only wraps it.
- **Repo model**: Submodule path fixed at `vendor/dots-hyprland`; fork owns custom commits; pull/rebase from `upstream` as needed.
- **Parity floor (later milestones)**: Waybar-era capabilities before removing Waybar.
- **No ddcutil polling**: No brightness/backlight widget using DDC/CI.
- **Keep hyprlock**: Do not replace the screen lock.
- **Personal / machine-specific**: Hardcoded monitor names, timezone (Asia/Dhaka), ping monitor bind host, conda paths — apply as overlays after install.
- **Primary target Arch only**.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Fresh build, not iterating on old Quickshell | Old attempt deleted; adopt dots-hyprland architecture cleanly | ✓ Good for v0.1 learning |
| v0.2: Adopt real dots-hyprland (fork + submodule) instead of local rewrite | Upstream good enough; reduce maintenance; customize later | ✓ Phases 5–8 product path; DOC Phase 9 |
| Submodule at `vendor/dots-hyprland` | Clear third-party boundary inside `.dotfiles` | ✓ Phase 5 |
| Thin wrapper around `./setup` | Keep end-4 installer as source of truth; match `arch/*.sh` style | ✓ Phase 6 |
| Live install via wrapper only; personal hypr hooks (no full ii hypr tree) | D-05/D-09/D-10 — one-shot install + inline env/exec-once; dual-run OK | ✓ Phase 7 |
| Delete local `.config/quickshell` product this milestone | Single live shell path; avoid dual product confusion | ✓ Phase 8 (RET-01/02) |
| Personal fork + upstream remote | Own customizations; still pull end-4 updates | ✓ Phase 5 |
| Defer Waybar custom ports | Install foundation first; customs need live shell | — Explicit |
| Skip brightness/backlight (no ddcutil) | iGPU crash risk per `2026-07-16` post-mortem | ✓ Good |
| Keep hyprlock (no Quickshell lock screen) | hyprlock works; lock screen panel not wanted as replacement | ✓ Good |
| Primary target Arch only | debian/ubuntu parity is a separate concern | ✓ Good |
| Replace waybar + rofi + swaync long-term | Consolidate tools; gain unified richer shell | ⚠️ Revisit — dual-run until later cutover |

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
*Last updated: 2026-08-01 — Phase 9 docs: operator playbook `docs/dots-hyprland-workflow.md` (DOC-01/DOC-02)*
