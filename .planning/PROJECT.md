# Quickshell Desktop Shell

## Current State

**Shipped:** v0.2 Adopt dots-hyprland (2026-08-02)  
**In progress:** v0.3 Full ii install — Phase 10 complete (UAT 2026-08-07); next is Phase 11 dispositions

Desktop shell is no longer a hand-rolled in-repo Quickshell product. Delivery model is **upstream dots-hyprland as a managed dependency**: personal fork, git submodule pin, thin Arch wrapper, live installed `ii` shell dual-running with Waybar, operator playbook for install and pin-bump updates.

**Phase 10 delivered:** Neutral full-install impact inventory (`10-INVENTORY.md`) covering SAFE_DEFAULTS residual, drop-`--skip-hyprland` hypr effects, drop-`--core` misc collisions, and package/sysupdate blast radius — with Wave 0 assert harness. No live full install; SAFE_DEFAULTS still default.

**Stats at v0.2 ship:** 5 phases · 15 plans · ~38 tasks · 106 commits since v0.1 · 1025 files changed (+17.6k / −78k, mostly retired local QS tree)

**Product surface:**
- Fork: `humam-hossain/dots-hyprland` (upstream = end-4)
- Submodule: `vendor/dots-hyprland` @ `1a9ffb78`
- Install entry: `arch/dots-hyprland.sh` → vendored `./setup`
- Live path: real `~/.config/quickshell` (not symlink into git)
- Session: personal hypr hooks for `ILLOGICAL_IMPULSE_VIRTUAL_ENV` + `qs -c ii`; Waybar still dual-runs
- Playbook: `docs/dots-hyprland-workflow.md`
- Inventory SoT: `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md`

## Current Milestone: v0.3 Full ii install

**Goal:** Identify everything a full dots-hyprland install (no `--skip-hyprland` / `--skip-sysupdate` / `--core` protection) would replace or change — especially personal `.config/hypr` and other colliding configs — then decide dispositions and only then perform the full install safely.

**Target features:**
- Impact inventory: dry-run / diff map of full install vs personal configs (hypr entry, hyprland tree, hyprlock/idle, misc configs skipped by `--core`, package/sysupdate side effects, backup behavior)
- Disposition decisions: per surface keep personal, migrate into `hypr/custom/`, accept upstream, merge, or defer
- Safe full-install path: wrapper/playbook opt-in out of SAFE_DEFAULTS; backup gate preserved
- Execute full adopt: apply agreed dispositions, run full install, verify session boots on ii hypr model without orphaning personal must-keeps
- Document: playbook update for full vs dual-run/safe profiles

**Not this milestone:** Waybar custom module ports (CUST-01..04), Waybar/rofi/swaync dual-run removal as a pure bar cutover (may follow after full hypr adopt if still dual-running chrome)

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

**Not that milestone:** Waybar custom module ports, full Waybar/rofi/swaync cutover, deep theming beyond install works and is managed. Full hypr install blocked by SAFE_DEFAULTS (`--core --skip-hyprland --skip-sysupdate`).

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

### Validated — v0.3 (in progress)

- ✓ Full-install impact inventory: filesystem + package/sysupdate effects without `--skip-hyprland`, and separately for dropping `--core` / `--skip-sysupdate` — Phase 10 / INV-01
- ✓ Personal hypr vs upstream install behavior (conf→`.old`, hyprland sync, lua, lock/idle auto_backup, custom ignore_existing) — Phase 10 / INV-02
- ✓ Non-hypr clash candidates if `--core` dropped (fish, kitty, starship, fontconfig, other present misc) — Phase 10 / INV-03
- ✓ SAFE_DEFAULTS residual documented; safe dual-run install remains default after Phase 10 — Phase 10 / INV-04

### Active

- [ ] Per-surface disposition plan for personal configs that full install would replace
- [ ] Safe opt-in full-install path (out of SAFE_DEFAULTS) with backup gate
- [ ] Execute full ii install per dispositions; session boots on ii hypr model
- [ ] Playbook: full vs safe/dual-run install profiles

### Carry-forward candidates (not yet committed requirements)

- [ ] Port Waybar customs into ii: ping, weather (+ forecast), earthquake, etc. (CUST-01..03)
- [ ] Machine-specific overlays as documented fork layer (CUST-04) — may overlap with hypr/custom migration this milestone
- [ ] Cutover: remove Waybar/rofi/swaync from Hyprland `exec-once` once parity is verified (CUT-01)
- [ ] Wrapper `verify` subcommand (qs binary, config path, submodule SHA) (POLISH-01)
- [ ] FWK-02 / IPC-02 style session integration under upstream model (POLISH-02)
- [ ] Open v0.1 debug polish items (only if still relevant after switch) (POLISH-03)

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
- Live session uses personal hypr + `qs -c ii` hooks; SAFE_DEFAULTS still inject `--core --skip-hyprland --skip-sysupdate`.
- Waybar still dual-runs; customs remain a later backlog (CUST-*).
- Operator path is documented in `docs/dots-hyprland-workflow.md` (README Desktop shell link).

**v0.3 focus:**
- Full install without skip flags will rename `hyprland.conf` → `.old`, sync ii `hypr/hyprland` Lua tree, install `hyprland.lua`, backup/replace hyprlock/hypridle, and (without `--core`) touch fish/kitty/starship/misc.
- Discovery first: inventory impact, decide dispositions, then adopt — not a blind full install.

**Why this project:**
- Consolidate desktop shell tooling via a proven upstream, not a second maintenance surface.
- Keep personal control (fork) and reproducibility (submodule pin) inside `.dotfiles`.
- Move from protected dual-run adopt toward full ii session ownership when personal must-keeps are mapped.

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
| Defer Waybar custom ports | Install foundation first; customs need live shell | — Deferred past full hypr adopt |
| v0.3: Full install after impact inventory | Drop SAFE_DEFAULTS only with known dispositions for replaced configs | ✓ Phase 10 inventory + UAT done; dispositions Phase 11 |
| Phase 10: Single multi-section `10-INVENTORY.md` SoT | One inventory file for residual + axes A/B/C + host snapshot | ✓ INV-01..04 |
| Phase 10: Neutral effects only (no dispositions) | Phase 11 owns keep/migrate/accept/defer | ✓ D-12 lint + assert |
| Phase 10: Assert harness with word-boundary D-15 lint | Avoid false positives (`profile` ⊃ `rofi`) | ✓ `phase10-inventory-assert.sh` |
| Phase 10: Full misc catalog from pin `find`, not named-four-only | Complete `--core` clash map | ✓ INV-03 |
| Phase 10: Coarse illogical-impulse metas from install-deps (no full depends expand) | Enough for blast radius without live Syu | ✓ INV-01 |
| Phase 10: hyprlock/ dir gap retained UNKNOWN | Honest residual for Phase 11 | ✓ D-04 |
| Skip brightness/backlight (no ddcutil) | iGPU crash risk per `2026-07-16` post-mortem | ✓ Good |
| Keep hyprlock (no Quickshell lock screen) | hyprlock works; lock screen panel not wanted as replacement | ✓ Good — re-check vs ii hyprlock on full install |
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
*Last updated: 2026-08-07 after Phase 10 UAT complete (7/7 pass) — transition to Phase 11*
