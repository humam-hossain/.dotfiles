# Quickshell Desktop Shell

## Current State

**Shipped:** v0.2 Adopt dots-hyprland (2026-08-02)

Desktop shell is no longer a hand-rolled in-repo Quickshell product. Delivery model is **upstream dots-hyprland as a managed dependency**: personal fork, git submodule pin, thin Arch wrapper, live installed `ii` shell dual-running with Waybar, operator playbook for install and pin-bump updates.

**Stats at v0.2 ship:** 5 phases · 15 plans · ~38 tasks · 106 commits since v0.1 · 1025 files changed (+17.6k / −78k, mostly retired local QS tree)

**Product surface:**
- Fork: `humam-hossain/dots-hyprland` (upstream = end-4)
- Submodule: `vendor/dots-hyprland` @ `1a9ffb78`
- Install entry: `arch/dots-hyprland.sh` → vendored `./setup`
- Live path: real `~/.config/quickshell` (not symlink into git)
- Session: personal hypr hooks for `ILLOGICAL_IMPULSE_VIRTUAL_ENV` + `qs -c ii`; Waybar still dual-runs
- Playbook: `docs/dots-hyprland-workflow.md`

## Next Milestone Goals

Not yet defined — start with `/gsd-new-milestone`. Candidate direction from deferred requirements:

- Port Waybar customs into ii (ping @ `127.0.0.1:8765`, weather, earthquake, machine overlays)
- Cutover: remove Waybar/rofi/swaync from session once parity accepted
- Optional polish: wrapper `verify`, FWK-02/IPC-02-style integration under upstream model
- Re-evaluate open v0.1 debug polish only if still relevant on stock ii

## Current Milestone

*(none — awaiting `/gsd-new-milestone`)*

<details>
<summary>Prior milestone: v0.2 Adopt dots-hyprland (shipped 2026-08-02)</summary>

**Goal:** Stop owning a hand-rolled Quickshell product tree; install end-4/dots-hyprland properly as a personal fork + git submodule and wire it into the `.dotfiles` Arch install style.

**Shipped features:**
- Personal GitHub fork with `origin` = fork, `upstream` = end-4
- Git submodule at `vendor/dots-hyprland`
- Thin `arch/dots-hyprland.sh` driving upstream `./setup`
- Live installed illogical-impulse shell (not local `.config/quickshell`)
- Removed v0.1 local product tree and `arch/quickshell.sh`
- Documented clone/install/update dual-run workflow

**Not that milestone:** Waybar custom module ports, full Waybar/rofi/swaync cutover, deep theming beyond install works and is managed.

</details>

## What This Is

A personal Hyprland desktop shell setup, part of the `.dotfiles` Linux environment. **Delivery model (v0.2+):** adopt upstream **illogical-impulse** (dots-hyprland) as a managed dependency — fork for ownership, submodule for pin/repro, thin Arch install wrappers for the existing `.dotfiles` style — then customize for Waybar-parity needs.

**v0.1** built a local Quickshell tree modeled on dots-hyprland `ii` (learning vehicle; now retired). **v0.2** switched the product vehicle to the real upstream install.

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
- ✓ Hyprland session bootstrap (`hyprland-session.service` → `graphical-session.target`) — existing

### Validated — v0.1

- ✓ Material theme system (MaterialThemeLoader + scheme) — v0.1 Phase 1
- ✓ Quickshell foundation: directory structure, PanelLoader / panel families, service singletons, visible top bar — v0.1
- ✓ Core bar modules: workspaces, clock, system tray, network status — v0.1 Phase 2
- ✓ System metrics: CPU, RAM, disk rings with dual thresholds — v0.1 Phase 3
- ✓ Audio volume from bar (scroll, mute, 130% ceiling, auto-unmute) — v0.1 Phase 3
- ✓ IPC socket for bar open/close/toggle — v0.1 Phase 4
- ✓ Graceful soft reload without full restart (same PID, silent) — v0.1 Phase 4

*Note: v0.1 validated capabilities describe the retired local tree. Live shell is now upstream-installed ii; module parity is re-verified against the installed product, not assumed from the deleted tree.*

### Validated — v0.2

- ✓ Personal public fork of end-4/dots-hyprland with dual remotes (origin=fork, upstream=end-4) — Phase 5 / OWN-01
- ✓ Git submodule at `vendor/dots-hyprland` pinned in parent (mode 160000) — Phase 5 / OWN-02
- ✓ Nested shapes submodule initializes recursively — Phase 5 / OWN-03
- ✓ Thin `arch/dots-hyprland.sh` wrapper around upstream `./setup` with safe dual-run defaults and backup gate — Phase 6 / WRAP-01..04
- ✓ Live session uses installed illogical-impulse shell (real `~/.config/quickshell` tree, not symlink into git) — Phase 7 / LIVE-01
- ✓ Personal Hyprland hooks: `ILLOGICAL_IMPULSE_VIRTUAL_ENV` + `exec-once = qs -c ii` — Phase 7 / LIVE-02
- ✓ Waybar dual-run preserved — Phase 7 / LIVE-03
- ✓ Operator-visible ii/Quickshell chrome with `qs -c ii` + venv env — Phase 7 / LIVE-04
- ✓ In-repo v0.1 `.config/quickshell` product tree removed from `.dotfiles` — Phase 8 / RET-01
- ✓ `arch/quickshell.sh` hard-deleted; sole install entry `arch/dots-hyprland.sh` — Phase 8 / RET-02
- ✓ Operator playbook: clone → recursive submodule → wrapper install → hypr hooks → dual-run — Phase 9 / DOC-01
- ✓ Operator playbook: pin-bump update; exp-merge / online cache non-primary — Phase 9 / DOC-02

### Active

*(none — define next milestone requirements via `/gsd-new-milestone`)*

### Carry-forward candidates (not yet committed requirements)

- [ ] Port Waybar customs into ii: ping, weather (+ forecast), earthquake, etc.
- [ ] Machine-specific overlays (monitors, Asia/Dhaka, paths) as documented fork layer
- [ ] FWK-02 / IPC-02 style session integration as needed under upstream model
- [ ] Cutover: remove Waybar/rofi/swaync from Hyprland `exec-once` once parity is verified
- [ ] Wrapper `verify` subcommand (qs binary, config path, submodule SHA)
- [ ] Open v0.1 debug polish items (only if still relevant after switch)

### Out of Scope

- Brightness/backlight widget — ddcutil DDC/CI polling caused the iGPU crash documented in `issues/2026-07-16_igpu-flickering-hang-no-display.md`; Waybar's backlight module is already disabled. No ddcutil polling in the shell.
- Quickshell lock screen — keeping hyprlock; not porting dots-hyprland's `LockScreen.qml` as a replacement for hyprlock.
- AI chat service, Booru, SongRec, LaTeX renderer, Google Cloud/Translation, Anti-flashbang, First-run onboarding — niche / not wanted (may exist upstream; do not invest in enabling them).
- Continuing the hand-rolled local Quickshell product tree as the primary shell — retired in v0.2.
- Reimplement ii package install in `arch/` without `./setup` — upstream setup is SoT.
- Debian/Ubuntu parity for the new shell path — primary target is Arch.
- Auto-bump submodule on every parent pull — breaks reproducibility.
- `exp-merge` / `exp-update` as primary update — experimental; document only.

## Context

**Post-v0.2 reality:**
- Upstream [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) is the product vehicle; personal fork owns custom commits; parent pins SHA in `vendor/dots-hyprland`.
- Install SoT remains vendored `./setup`; `.dotfiles` only wraps it (`arch/dots-hyprland.sh`).
- Waybar still runs; customs (ping @ `127.0.0.1:8765`, weather, earthquake, music, memory) remain the long-term customization backlog.
- Operator path is documented in `docs/dots-hyprland-workflow.md` (README Desktop shell link).

**Why this project:**
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
| v0.2: Adopt real dots-hyprland (fork + submodule) instead of local rewrite | Upstream good enough; reduce maintenance; customize later | ✓ Shipped v0.2 |
| Canonical playbook `docs/dots-hyprland-workflow.md` | Single SoT for install/update; wrapper help stays flag SoT | ✓ Phase 9 DOC-01/DOC-02 |
| Pin-bump as sole primary update; exp-merge/online cache non-primary | Avoid tribal/experimental paths as default | ✓ Phase 9 DOC-02 |
| Submodule at `vendor/dots-hyprland` | Clear third-party boundary inside `.dotfiles` | ✓ Phase 5 |
| Thin wrapper around `./setup` | Keep end-4 installer as source of truth; match `arch/*.sh` style | ✓ Phase 6 |
| Live install via wrapper only; personal hypr hooks (no full ii hypr tree) | One-shot install + inline env/exec-once; dual-run OK | ✓ Phase 7 |
| Delete local `.config/quickshell` product this milestone | Single live shell path; avoid dual product confusion | ✓ Phase 8 (RET-01/02) |
| Personal fork + upstream remote | Own customizations; still pull end-4 updates | ✓ Phase 5 |
| Defer Waybar custom ports | Install foundation first; customs need live shell | — Explicit next |
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
*Last updated: 2026-08-02 after v0.2 milestone*
