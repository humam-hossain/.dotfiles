# Quickshell Desktop Shell

## Current State

**Shipped:** v0.4 Personal config layer (2026-09-16)  
**Status:** All 8 phases of v0.4 (Phases 17–24) complete and verified

Desktop shell is no longer a hand-rolled in-repo Quickshell product. Delivery model is **upstream dots-hyprland as a managed dependency**: personal fork, git submodule pin, thin Arch wrapper, live installed `ii` shell, operator playbook for install and pin-bump updates. As of Phase 14 the session runs the full ii model — the Lua entry is authoritative and Waybar/rofi/swaync no longer dual-run.

**Phase 10 delivered:** Neutral full-install impact inventory (`10-INVENTORY.md`) covering SAFE_DEFAULTS residual, drop-`--skip-hyprland` hypr effects, drop-`--core` misc collisions, and package/sysupdate blast radius — with Wave 0 assert harness. No live full install; SAFE_DEFAULTS still default. **[superseded by Phase 16]** — the safe profile and its machinery were retired.

**Phase 11 delivered:** Per-surface dispositions (`11-DISPOSITIONS.md`) — first full-adopt drops all three SAFE_DEFAULTS residuals; default install still injects them. **[superseded by Phase 16]** — the safe profile and its machinery were retired.

**Phase 12 delivered:** Wrapper-owned `--full` on `install` / `install-files` only. Full dry-run omits the triple residual and still hits the backup gate; default install still injects SAFE_DEFAULTS. Evidence: `./scripts/phase12-full-smoke.sh` exit 0 on 2026-08-18 (FAIL=0). No live full install this phase. **[superseded by Phase 16]** — the safe profile and its machinery were retired.

**Phase 13 delivered:** Parent-repo `.config/hypr/custom/` overlays — `general.lua` dual-head + eleven workspace pins, empty `env.lua`/`execs.lua` require slots, `13-SOT-APPLY.md` authoring SoT + D-18 `cp -a` (documented, not run) + D-19 fence (exit 0). Live `$HOME/.config/hypr/custom/` still absent. Apply is Phase 14.

**Phase 14 delivered:** The live full adopt. `install --full` ran on 2026-09-04 behind the preflight gate; upstream renamed `hyprland.conf` to `.old` and the session now loads through `hyprland.lua` (`hyprctl -j status` reports `configProvider: lua`, where the pre-adopt baseline recorded `hyprlang`), surviving a re-login. The Phase 13 overlay is applied — `general.lua`/`env.lua`/`execs.lua` byte-identical to the repo SoT, dual-head DP-1 + HDMI-A-2 and eleven workspace rules live, `qs -c ii` running. Waybar/rofi/swaync are stopped per D-11 accept-remove with their trees still archived under `stow/` per D-12. Rollback is `docs/phase14-adopt-runbook.md` §14 (three tiers, never upstream `./setup uninstall`). Evidence: `14-LIVE-VERIFY.md`, the committed `script(1)` transcript, and `14-VERIFICATION.md` (passed 4/4). **[superseded by Phase 16]** — the safe profile and its machinery were retired.

**Phase 16 delivered:** Retired the safe profile entirely. `arch/dots-hyprland.sh` no longer injects `SAFE_DEFAULTS` — bare `install`/`install-files` runs the full behavior with no profile to choose. `--full` survives as an announced no-op alias. Backup gate, protect machinery, ii-hook conditional injection, and `SAFE_DEFAULTS` array all removed. `uninstall` survives stripped. `docs/dots-hyprland-workflow.md` rewritten full-only end-to-end with bare commands; `docs/phase14-adopt-runbook.md` swept to match. Planning artifacts amended for the same falsehoods. v0.3 coverage dropped from 22 to 19. Closes v0.3 audit leftovers IN-11, W-1, W-2, W-3. Evidence: `scripts/phase16-retire-assert.sh` FAIL=0; all prior-phase assert suites green; `16-VERIFICATION.md` (passed 13/13).
 
**Phase 24 delivered:** Technical debt bookkeeping reconciliation, Nyquist validation contract cleanup across all v0.4 phases, `.gitignore` socket un-ignore scoping (`!stow/systemd/**`), repository hygiene triage documentation in `STATE.md`, desktop session keybinding realignment in `custom/keybinds.lua` (`SUPER + Scroll_Lock` for sleep, `SUPER + SHIFT + Scroll_Lock` for logout, unbinding upstream `SUPER + SHIFT + L` sleep chord), and the comprehensive automated 5-section assertion harness `scripts/phase24-tech-debt-assert.sh`. Strict system verification passed with zero findings and zero drift across milestone v0.4 (`FAIL=0 FINDINGS=0`).

**Stats at v0.2 ship:** 5 phases · 15 plans · ~38 tasks · 106 commits since v0.1 · 1025 files changed (+17.6k / −78k, mostly retired local QS tree)

**Product surface:**
- Fork: `humam-hossain/dots-hyprland` (upstream = end-4)
- Submodule: `vendor/dots-hyprland` @ `1a9ffb78`
- Install entry: `arch/dots-hyprland.sh` → vendored `./setup`; one install path (full) — no profile to choose, no wrapper backup gate, no package re-marking
- Live path: real `~/.config/quickshell` (not symlink into git)
- Session: ii Lua entry `~/.config/hypr/hyprland.lua` is authoritative (Phase 14) and owns the venv env plus `exec-once = qs -c ii`; personal must-keeps ride in `~/.config/hypr/custom/`; Waybar, rofi and swaync are retired from the session
- Rollback: clean reinstall from the pinned `vendor/dots-hyprland` submodule; runbook `docs/phase14-adopt-runbook.md` §14
- Playbook: `docs/dots-hyprland-workflow.md`
- Inventory SoT: `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md`

## Current Milestone: v0.4 Personal config layer

**Goal:** Own every personal config on top of the installed ii shell, captured in this repo automatically, reproducible on a fresh machine with one command.

**Target features:** (revised 2026-09-12 after research — see `.planning/research/SUMMARY.md`)
- Hypr custom overlays under repo SoT — all six of `custom/{env,execs,general,rules,keybinds,variables}.lua` stow-managed. `custom/scripts/` is dropped: it holds generated output, and `hyprland.lua` never sources it.
- Quickshell ii bar config owned — `~/.config/illogical-impulse/config.json` copy-captured, because `switchwall.sh` renames over the path on every wallpaper change. Bar *widget composition* is out of scope; it requires editing QML the installer replaces wholesale.
- Startup applications restored — seven `exec-once` entries in `custom/execs.lua`, closing D-38 by starting `hyprland-session.service`. XDG `~/.config/autostart` is dropped: nothing in this session reads it.
- Dolphin and KDE/GTK configs captured — `dolphinrc`, `chrome-flags.conf`, `kiorc`, `ktrashrc`, `kservicemenurc`, and `gtk-{3,4}.0/settings.ini` per file. `kdeglobals`, `Kvantum/` and both `gtk.css` files are dropped: they are generated theme output, and capturing them means a diff on every wallpaper change.
- Capture mechanism live — three trees (`stow/`, `restow/`, `capture/`) keyed to installer collision class, a checked-in collision map, and a link-aware `verify` drift check (folds in POLISH-01)
- One-command fresh-machine bootstrap — clone then one command yields the exact setup, verified

**Capture decision (D-41, corrected 2026-09-12):** Stow symlinks (`--no-folding`, always) are the default capture path — live *is* the repo, no manual sync. The original exception was stated as "any file an app rewrites atomically". That premise is disproven: Qt's `QSaveFile`, which backs both Quickshell's `FileView` and every KDE `KConfig` write, resolves the symlink chain before renaming onto the resolved target, so the symlink survives and the repo file is correctly updated. Atomic writing is the *best* case for symlink capture. The real exceptions are two, both reproduced empirically on this host: a writer performing a bare `rename(2)`/`mv` onto the link path (`switchwall.sh` on `config.json`), and the ii installer, whose `rsync -a --delete` destroys the symlink outright and whose `cp -f` writes through it and overwrites the repo copy. Capture is therefore organised by installer collision class and write primitive, not by atomicity. A link-aware `verify` backstops all three trees — asserting link identity *before* content, because both destroying primitives leave the repo file untouched and a content-only check reports green in exactly the case that matters.

**Scope note:** No upfront inventory of every config dots-hyprland installs. Capture as touched — and a full `diff -rq vendor/dots-hyprland/dots/.config ~/.config` against the pin returns five drifted files, so the pin itself is the inventory, computed on demand.

## Prior Milestones

<details>
<summary>v0.3 Full ii install (shipped 2026-09-09)</summary>

**Goal:** Identify everything a full dots-hyprland install (no `--skip-hyprland` / `--skip-sysupdate` / `--core` protection) would replace or change — especially personal `.config/hypr` and other colliding configs — then decide dispositions and only then perform the full install safely.

**Shipped features:**
- Full-install impact inventory mapping every path/flag/package effect
- Per-surface disposition decisions for all high-risk surfaces
- Personal `hypr/custom` Lua overlays (monitors, workspace pins, env/execs slots)
- Live full adopt — session loads via ii Lua entry, overlays applied, Waybar/rofi/swaync accept-removed
- Safe profile retired — one install path, no flags to choose, `--full` is no-op alias
- Full-only playbook `docs/dots-hyprland-workflow.md` with bare commands end-to-end

**Not that milestone:** Waybar custom module ports (CUST-01..04).

</details>

<details>
<summary>v0.2 Adopt dots-hyprland (shipped 2026-08-02)</summary>

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
- ✓ Thin `arch/dots-hyprland.sh` wrapper around upstream `./setup` with safe dual-run defaults and backup gate — Phase 6 / WRAP-01..04 **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- ✓ Live session uses installed illogical-impulse shell (real `~/.config/quickshell` tree, not symlink into git) — Phase 7 / LIVE-01
- ✓ Personal Hyprland hooks: `ILLOGICAL_IMPULSE_VIRTUAL_ENV` + `exec-once = qs -c ii` — Phase 7 / LIVE-02
- ✓ Waybar dual-run preserved — Phase 7 / LIVE-03 **[superseded by Phase 16]** — the dual-run session ended at the Phase 14 adopt.
- ✓ Operator-visible ii/Quickshell chrome with `qs -c ii` + venv env — Phase 7 / LIVE-04
- ✓ In-repo v0.1 `.config/quickshell` product tree removed from `.dotfiles` — Phase 8 / RET-01
- ✓ `arch/quickshell.sh` hard-deleted; sole install entry `arch/dots-hyprland.sh` — Phase 8 / RET-02
- ✓ Operator playbook: clone → recursive submodule → wrapper install → hypr hooks → dual-run — Phase 9 / DOC-01 **[superseded by Phase 16]** — the dual-run session ended at the Phase 14 adopt.
- ✓ Operator playbook: pin-bump update; exp-merge / online cache non-primary — Phase 9 / DOC-02

### Validated — v0.3 (shipped)

- ✓ Full-install impact inventory: filesystem + package/sysupdate effects without `--skip-hyprland`, and separately for dropping `--core` / `--skip-sysupdate` — Phase 10 / INV-01
- ✓ Personal hypr vs upstream install behavior (conf→`.old`, hyprland sync, lua, lock/idle auto_backup, custom ignore_existing) — Phase 10 / INV-02
- ✓ Non-hypr clash candidates if `--core` dropped (fish, kitty, starship, fontconfig, other present misc) — Phase 10 / INV-03
- ✓ SAFE_DEFAULTS residual documented; safe dual-run install remains default after Phase 10 — Phase 10 / INV-04 **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- ✓ Per-surface dispositions for high-risk inventory rows + staged flag profile (drop all three residuals on first full-adopt; default still injects) — Phase 11 / DISP-01..04
- ✓ Wrapper `--full` opt-in on install/install-files; meta stripped; no SAFE_DEFAULTS injection on full — Phase 12 / FULL-01 **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- ✓ Default `install` / `install-files` still inject `--core --skip-hyprland --skip-sysupdate` — Phase 12 / FULL-02 **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- ✓ Full path keeps type-yes backup gate; bare `--skip-backup` refused without `--allow-skip-backup` — Phase 12 / FULL-03 **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- ✓ `--full --dry-run` shows would-exec without residual injection — Phase 12 / FULL-04 **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- ✓ Full dry-run still plans PROTECT_EXPLICIT re-mark and ii hooks — Phase 12 / FULL-05 **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- ✓ Personal must-keeps as `hypr/custom` Lua overlays (monitors + workspace pins; empty env/execs slots) before live full hypr files — Phase 13 / OVL-01..03
- ✓ Live full install ran only after the INV-* / DISP-* artifacts were satisfied, enforced by `scripts/phase14-preflight.sh` — Phase 14 / ADOPT-01 **[superseded by Phase 16]** — the safe profile and its machinery were retired.
- ✓ Hyprland session loads via the ii Lua entry, not the pre-adopt personal conf — Phase 14 / ADOPT-02
- ✓ Monitors, workspace pins and `qs -c ii` verified live; dual-run chrome accept-removed per DISP-03's explicit-acceptance clause — Phase 14 / ADOPT-03 **[superseded by Phase 16]** — the dual-run session ended at the Phase 14 adopt.
- ✓ Rollback guidance in three tiers that never uses upstream `./setup uninstall` — Phase 14 / ADOPT-04 **[superseded by Phase 16]** — the safe profile and its machinery were retired.

- ✓ Playbook: single full-only install path with no profile to choose — DOC-03 / DOC-04 (Phase 15 authored it; Phase 16 made it full-only)

### Validated — v0.4 (shipped)

- ✓ Live `~/.config/hypr/custom/` tree fully under repo SoT (all six `*.lua`; `scripts/` excluded as generated and unsourced) — Phase 20 / HYPR-01, HYPR-02, HYPR-03, SAFE-01
- ✓ Quickshell ii bar config (`illogical-impulse/config.json`) copy-captured against `switchwall.sh`'s rename-over-link — Phase 21 / BAR-01, BAR-02, CAP-06
- ✓ Startup applications restored, including the `graphical-session.target` autostart lost at adopt (D-38) — Phase 20 / START-01, START-02
- ✓ Dolphin and KDE/Qt/GTK app configs captured in the repo — Phase 22 / KDE-01, KDE-02, KDE-03
- ✓ Capture mechanism operational — stow-symlink default, copy-capture exception, `verify` drift check (POLISH-01) — Phase 18, 19, 21, 22
- ✓ Fresh machine reproduces the exact setup from clone with one command — Phase 23 / BOOT-01..05
- ✓ Technical debt, bookkeeping normalization, Nyquist validation compliance, and session keybindings realigned — Phase 24 / DEBT-01..04

### Active — v0.4

- [x] All v0.4 requirements validated and shipped across Phases 17–24

### Carry-forward candidates (not yet committed requirements)

- [ ] Port Waybar customs into ii: ping, weather (+ forecast), earthquake, etc. (CUST-01..03)
- [ ] Machine-specific overlays as documented fork layer (CUST-04) — may overlap with hypr/custom migration this milestone
- [ ] Cutover: remove Waybar/rofi/swaync from Hyprland `exec-once` once parity is verified (CUT-01)
- [x] Wrapper `verify` subcommand (qs binary, config path, submodule SHA) (POLISH-01) — promoted into v0.4 as the drift check
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
- The session runs on ii's own Lua tree, which owns the venv env and the `qs -c ii` exec-once; the wrapper has one install path and injects no residual flags. `--full` survives only as an announced no-op alias (Phase 16).
- Waybar/rofi/swaync no longer dual-run — accept-removed at the Phase 14 full adopt (D-11); their configs stay archived under `stow/` (D-12). Customs remain a later backlog (CUST-*).
- Operator path is documented in `docs/dots-hyprland-workflow.md` (README Desktop shell link).

**v0.3 focus:**
- Full install without skip flags will rename `hyprland.conf` → `.old`, sync ii `hypr/hyprland` Lua tree, install `hyprland.lua`, backup/replace hyprlock/hypridle, and (without `--core`) touch fish/kitty/starship/misc.
- Discovery first: inventory impact, decide dispositions, then adopt — not a blind full install.

**Why this project:**
- Consolidate desktop shell tooling via a proven upstream, not a second maintenance surface.
- Keep personal control (fork) and reproducibility (submodule pin) inside `.dotfiles`.
- Full ii session ownership is in place since the Phase 14 adopt; personal must-keeps ride as `~/.config/hypr/custom/` Lua overlays.

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
| v0.3: Full install after impact inventory | Drop SAFE_DEFAULTS only with known dispositions for replaced configs | ✓ Phase 10 inventory + UAT; Phase 11 dispositions; Phase 12 `--full` path **[superseded by Phase 16]** — the safe profile and its machinery were retired. |
| Phase 12: `--full` is wrapper meta, never forwarded | Same strip pattern as `--dry-run` / `--allow-skip-backup` | ✓ smoke FULL-01 would-exec has no `--full` **[superseded by Phase 16]** — the safe profile and its machinery were retired. |
| Phase 12: default path still injects triple residual | Full must not become accidental (FULL-02 / D-10) | ✓ smoke FULL-02 / FULL-02b **[superseded by Phase 16]** — the safe profile and its machinery were retired. |
| Phase 12: full gate + dual-key skip-backup | Same type-yes token; refuse bare `--skip-backup` | ✓ smoke FULL-03 / FULL-03b; `printf no` exit 1 **[superseded by Phase 16]** — the safe profile and its machinery were retired. |
| Phase 12: protect + ii hooks unbranched on `full==1` | FULL-05; no `full==0` skip around post-setup arms | ✓ smoke FULL-05; live greps 2026-08-18 **[superseded by Phase 16]** — the safe profile and its machinery were retired. |
| Phase 13: authoring SoT is parent-repo `.config/hypr/custom/` | Vendor/fork stay product-only; live is applied copy | ✓ overlays committed only under parent custom/ |
| Phase 13: apply documented, not run (D-02/D-17) | Live full hypr files are Phase 14; no `$HOME/.config` mutation | ✓ live custom absent; D-18 is `cp -a` of three named files |
| Phase 13: empty `env.lua`/`execs.lua` are 1-byte require slots | `hyprland.lua` gates on `is_file_exists`; `test -f` only, never `test -s` | ✓ D-19 fence exit 0; `luac -p` on general.lua |
| Phase 13: D-19 in-repo fence is the OVL completion gate | CONTEXT/PLAN prose is not evidence (D-20) | ✓ OVL-01..03 Complete after D-19; 13-VERIFICATION.md status passed |
| Phase 13: UAT + security + Nyquist after disk re-run | Do not treat STATE complete as UAT; re-run D-19; empty slots are `test -f` only | ✓ 13-UAT.md 7/7; 13-SECURITY.md threats_open 0; 13-VALIDATION.md validated; `./scripts/phase13-d19-assert.sh` FAIL=0 |
| Phase 10: Single multi-section `10-INVENTORY.md` SoT | One inventory file for residual + axes A/B/C + host snapshot | ✓ INV-01..04 |
| Phase 10: Neutral effects only (no dispositions) | Phase 11 owns keep/migrate/accept/defer | ✓ D-12 lint + assert |
| Phase 10: Assert harness with word-boundary D-15 lint | Avoid false positives (`profile` ⊃ `rofi`) | ✓ `phase10-inventory-assert.sh` |
| Phase 10: Full misc catalog from pin `find`, not named-four-only | Complete `--core` clash map | ✓ INV-03 |
| Phase 10: Coarse illogical-impulse metas from install-deps (no full depends expand) | Enough for blast radius without live Syu | ✓ INV-01 |
| Phase 10: hyprlock/ dir gap retained UNKNOWN | Honest residual for Phase 11 | ✓ D-04 |
| Skip brightness/backlight (no ddcutil) | iGPU crash risk per `2026-07-16` post-mortem | ✓ Good |
| Keep hyprlock (no Quickshell lock screen) | hyprlock works; lock screen panel not wanted as replacement | ✓ Good — re-check vs ii hyprlock on full install |
| Primary target Arch only | debian/ubuntu parity is a separate concern | ✓ Good |
| Phase 14: adopt behind a non-mutating preflight gate, human pulls the trigger | An agent must never run the irreversible install; the gate proves INV/DISP satisfied first | ✓ backup rotated 17:11:28Z, install gate answered 17:13:41Z — 2m13s apart |
| Phase 14: rollback is a repo runbook, never upstream `./setup uninstall` | ADOPT-04; the upstream subcommand is a Phase 12 escape hatch behind a token gate, referenced by no Phase 14 guidance | ✓ `14-VERIFICATION.md` ADOPT-04; `grep -niE 'setup uninstall'` on the runbook → no matches |
| Phase 14: Hyprland conf-vs-Lua precedence left unresolved, and rollback written to be correct either way | The wiki and D-09 disagree on 0.56.2; the forward adopt is safe under both readings, the reverse is not | ✓ the runbook's first rollback step opened by moving `hyprland.lua` aside (CR-01) **[superseded by Phase 16]** — the safe profile and its machinery were retired. |
| Replace waybar + rofi + swaync long-term | Consolidate tools; gain unified richer shell | ✓ Phase 14 — accept-removed from the session (D-11); configs archived in repo (D-12) |
| Phase 16: Retire safe profile entirely — one install path, no profile choice | Full adopt is reality since Phase 14; safe machinery is dead code that blocks the playbook from describing bare commands | ✓ `SAFE_DEFAULTS` removed, `--full` is no-op alias, playbook full-only, all assertion suites green |
| Phase 21: Format-generic JSON validation and atomic copy-capture | `switchwall.sh` destroys symlinks on wallpaper switch; validate with `[[ -s ]]` and `jq empty`, replace atomically via temp-file rename, skip clean if `cmp -s` identical | ✓ Proven in scratch fixture and live desktop session (BAR-01, BAR-02) |
| Phase 21: Unattended drift capture via systemd user timer | 15-minute interval timer triggering oneshot service with `arch/dots-hyprland.sh capture --quiet --notify` | ✓ Stowed, enabled, active, zero UI frame drop (`Nice=19`), desktop notifications (CAP-06) |
| Phase 22: Dolphin, KIO, and GTK per-file capture with unfolded parent dirs | Capture `kiorc`, `ktrashrc`, `kservicemenurc` under `stow/kde/` and GTK-3/4 under `stow/gtk/` with parent dirs unfolded; gitignore `gtk-dark.css` and prove KConfig write-through | ✓ Proven in scratch fixtures and live desktop session (KDE-01, KDE-02) |
| Phase 22: GUARD contract and kdeglobals retirement | Retire `kdeglobals` to `docs/archive/` to stop wallpaper churn; check in `guard-paths.tsv` data contract tracking 7 theme outputs and integrate fail-closed verify gate | ✓ `guard-paths.tsv` active, `docs/archive/kdeglobals` archived, live unlinked to regular file (KDE-02) |
| Phase 22: Colliding desktop flags capture with live cp-through drill and recovery | Package `chrome-flags.conf` in `restow/chrome-flags/` tagged `cp-through`; regenerate `restow/README.md` table; verify `install-files` overwrite and git checkout recovery | ✓ Live drill passed end-to-end; strict verify gate 0 findings (KDE-03) |
| Phase 23: Root orchestrator with resumable JSON state and strict verification | `./bootstrap.sh` entry point with non-root/Arch gates, atomic JSON state machine at `$XDG_STATE_HOME/dotfiles/bootstrap-state`, `--from`/`--only` resume, and exit code bound 1-to-1 to `arch/dots-hyprland.sh verify --strict` | ✓ 5/5 assert sections passed, live verify 0 findings (BOOT-01, BOOT-04) |
| Phase 23: De-stubbing with guard protection and SHA-256 backup manifests | Resolve stow conflicts, preserve guarded theme outputs, archive stubs to `~/.dotfiles-backup.<epoch>/` with SHA-256 cryptographic `MANIFEST.txt`, unlink safely without `--adopt` | ✓ Verified in isolated scratch fixture and live host (BOOT-02) |
| Phase 23: Two-stage relogin boundary and deterministic package snapshots | Display formatted relogin instruction banner across compositor hop with session runtime probe (`HYPRLAND_INSTANCE_SIGNATURE` & Lua check); generate deterministic `arch/pkglist-{native,aur}.txt` via `--snapshot` with zero drift on standard runs | ✓ Verified across all test fixtures and assert harness (BOOT-03, BOOT-05) |
| Phase 24: Normalized summary frontmatter and reconciled REQUIREMENTS.md | Registered DEBT-01..04, reconciled 10 stale Pending markers, normalized 5 plan summaries for summary-extract | ✓ Phase 24 (DEBT-01) |
| Phase 24: Brought all v0.4 VALIDATION.md files to full Nyquist compliance | All 7 validation contracts closed as validated and nyquist_compliant true | ✓ Phase 24 (DEBT-02) |
| Phase 24: Scoped .gitignore and documented repository hygiene | Un-ignored systemd sockets (!stow/systemd/**); documented ping/.env and 12 gitleaks entries in STATE.md | ✓ Phase 24 (DEBT-03) |
| Phase 24: Realigned desktop session keybindings in custom/keybinds.lua | Unbound upstream SUPER + SHIFT + L, mapped Scroll_Lock combos, verified 36 binds taxonomy | ✓ Phase 24 (DEBT-04) |
| Phase 24: Automated 5-section assert harness scripts/phase24-tech-debt-assert.sh | Automated regression gating covering Sections 1–5 with FAIL=0 FINDINGS=0 | ✓ Phase 24 (DEBT-01..04) |

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
*Last updated: 2026-09-16 after Phase 24 — address-tech-debt-bookkeeping-and-validation-cleanup complete (DEBT-01..04)*
