# Quickshell Desktop Shell

## Current State

**Shipped:** v0.6 Top Status Bar Layout, Pill Styling & Component Customization (2026-09-20)  
**Status:** All 4 phases of v0.6 (Phases 31–34) complete, 20/20 requirements satisfied, verified, and archived

Desktop shell is fully unified under upstream dots-hyprland Material You / Matugen dynamic theming generated from wallpaper with modular 3-zone rounded-rectangle pill geometry. Delivery model is **upstream dots-hyprland as a managed dependency**: personal fork, git submodule pin, thin Arch wrapper, live installed `ii` shell, personal overlays under three-tree capture (`stow/`, `restow/`, `capture/`), guarded theme contracts (`guard-paths.tsv`), and one-command idempotent bootstrap (`./bootstrap.sh`).

**v0.6 delivered:** Modern rounded-rectangle pill geometry (12–16px radius, 4–6px internal padding) with fluid 250ms Material 3 emphasized deceleration width resizing animation across all bar containers, definite gigabyte memory reporting (`X.X GB / Y.Y GB`), custom CPU indicators, non-glyph Clock spacer, balanced System Tray spacing (4px), unattended package updates with cache cleaning (`yay -Syu --noconfirm && yay -Sc --noconfirm`), media title clamping with text ellipsis, reactive screen recording alerts (`wf-recorder`), modular 3-zone status bar layout with dead-center Workspaces flanked symmetrically by Weather and Clock & Date, full dynamic Material You palette adaptability across wallpaper switches with zero git working tree churn, and strict repository cleanliness (`arch/dots-hyprland.sh verify --strict` 0 findings).

**Stats at v0.6 ship:** 4 phases · 12 plans · 37 tasks · 79 files changed (+15.8k / −45) · 14.9k LOC shell scripts and QML

**Product surface:**
- Fork: `humam-hossain/dots-hyprland` (upstream = end-4)
- Submodule: `vendor/dots-hyprland` @ `1a9ffb78`
- Install entry: `arch/dots-hyprland.sh` → vendored `./setup`; one install path (full) — no profile to choose, no wrapper backup gate, no package re-marking
- Bootstrap entry: `./bootstrap.sh` — one-command fresh-machine orchestrator with resumable JSON state and strict verification gate
- Live path: real `~/.config/quickshell` (not symlink into git)
- Session: ii Lua entry `~/.config/hypr/hyprland.lua` is authoritative (Phase 14) and owns the venv env plus `exec-once = qs -c ii`; personal overrides ride in `~/.config/hypr/custom/`; Waybar, rofi and swaync are retired from the session
- Theming pipeline: `switchwall.sh` triggers Matugen synchronously for GTK CSS, Hyprland `colors.lua`, Quickshell `colors.json`, Fuzzel `fuzzel_theme.ini`, and Kitty `kitty-theme.conf` (SIGUSR1), plus background `kde-material-you-colors` for Qt/KDE `kdeglobals`. All outputs guarded via `guard-paths.tsv` with zero working tree drift.
- Personal bar overlays: `restow/quickshell/` deployed via GNU Stow leaf symlinks to `~/.config/quickshell/ii/` without touching `vendor/dots-hyprland`.
- Rollback: clean reinstall from the pinned `vendor/dots-hyprland` submodule; runbook `docs/phase14-adopt-runbook.md` §14
- Playbook: `docs/dots-hyprland-workflow.md`
- Inventory SoT: `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md`
- Collision Map: `collision-map.tsv` (machine-asserted)
- Guard Paths: `guard-paths.tsv` (machine-asserted)

## Next Milestone Goals (v0.7)

**Current focus:** Planning next milestone via `/gsd-new-milestone`. Potential areas:
- Porting remaining Waybar custom features (e.g. disk usage pill with partition popup, ping telemetry, multi-day forecast popup)
- Notification system polish and OSD integration
- Application launcher styling and workflow optimization

## Prior Milestones

<details>
<summary>v0.6 Top Status Bar Layout, Pill Styling & Component Customization (shipped 2026-09-20)</summary>

**Goal:** Create a modular, customizable top status bar with modern rounded rectangle pill styling (12–16px radius, 4–6px padding), systematic tier-1/tier-2 component audit and formatting enhancements (e.g. detailed RAM usage in GB), and live trial-and-error component rearrangement.

**Shipped features:**
- Personal Quickshell bar overlay (`restow/quickshell/`) deployed via GNU Stow leaf symlinks with live hot-reload without touching upstream `vendor/dots-hyprland`
- Standardized pill styling: modern rounded rectangle geometry (12–16px corner radius, 4–6px internal padding, dynamic width expansion with 250ms M3 emphasized deceleration animation)
- Detailed component formatting: definite gigabyte memory reporting (`X.X GB / Y.Y GB`), dynamic swap reveal, two-tier Amber/Red alerts, non-glyph clock spacer, balanced 4px tray spacing, unattended system updates (`yay -Syu --noconfirm && yay -Sc --noconfirm`), and reactive screen recording telemetry
- Modular 3-zone layout: decoupled Left, Center, and Right sections in `BarContent.qml` with clean 4px inter-pill gaps and zero vertical dividers, locking in dead-center Workspaces flanked symmetrically by Weather and Clock & Date
- Dynamic theming & zero drift: verified dynamic Material You palette adaptation across wallpaper switches, hardened `./bootstrap.sh` cold machine deployment, and verified strict repository integrity with zero working tree drift
- 100% automated test coverage: fail-closed multi-section assertion harnesses across all 4 phases (`scripts/phase31-overlay-pill-assert.sh`, `scripts/phase32-component-formatting-assert.sh`, `scripts/phase33-layout-assert.sh`, `scripts/phase34-verification-assert.sh`)

</details>

<details>
<summary>v0.5 System-wide Material You theming (shipped 2026-09-18)</summary>

**Goal:** Unify system-wide theming under upstream dots-hyprland Material You / Matugen dynamic colors generated from wallpaper, eliminating old Catppuccin conflicts and ensuring consistent styling across GTK, Qt/KDE, Hyprland, Quickshell ii, and terminal/launcher tools.

**Shipped features:**
- GTK 3 & 4 libadwaita integration: Catppuccin unlinking, `adw-gtk3-dark` base alignment, GNOME dark GSettings synchronization, and dynamic Matugen CSS generation
- Qt 6 & KDE application harmonization: Darkly style engine, native FileChooser portal, and dynamic `kdeglobals` generation via `kde-material-you-colors`
- Hyprland window decorations & Quickshell ii widget coordination: window borders bound to `colors.lua`, widget accents bound to `colors.json`, and live coordinated `switchwall.sh` pipeline
- Terminal & Launcher styling: Fuzzel launcher with M3 palette template and Kitty terminal emulator with dynamic theme include, 0.90 opacity, and SIGUSR1 signaling
- Data contracts & verification: `guard-paths.tsv` data contract protecting 8 theme outputs, `restow/` taxonomy relocation for colliding packages, hardened `./bootstrap.sh` fallback theming, and 100% Nyquist validation compliance across all 6 phases (25–30)

</details>

<details>
<summary>v0.4 Personal config layer (shipped 2026-09-16)</summary>

**Goal:** Own every personal config on top of the installed ii shell, captured in this repo automatically, reproducible on a fresh machine with one command.

**Shipped features:**
- Universal stow flag correction (`--verbose=5 --no-folding`) and `safe_rm_path` repo containment clause
- Three-tree capture model (`stow/`, `restow/`, `capture/`) and checked-in collision map (`collision-map.tsv`)
- Link-aware `verify` asserting symlink identity before content, diffing capture paths, with strict exit codes (0/1/2) proven adversarially against `rsync -a --delete`
- Hypr custom overlays under repo SoT — all six of `custom/{env,execs,general,rules,keybinds,variables}.lua` stow-managed
- Quickshell ii bar config owned — `~/.config/illogical-impulse/config.json` copy-captured, surviving `switchwall.sh` wallpaper changes, with unattended 15-minute systemd timer sync
- Startup applications restored — `exec-once` entries in `custom/execs.lua`, closing D-38 by starting `hyprland-session.service` (`graphical-session.target`)
- Dolphin and KDE/GTK configs captured per file, with generated theme output guarded out via `guard-paths.tsv`
- One-command fresh-machine bootstrap — clone then `./bootstrap.sh` yields the exact setup, verified with strict exit code binding
- Technical debt reconciliation: 100% Nyquist compliance across all phases, 39/39 requirements traceability sync, repo hygiene (.gitignore, non-credential .env affirmation), and session keybinding cheatsheet alignment

</details>

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

### Validated — v0.5

- ✓ Dynamic Matugen GTK 3 & 4 CSS generation from active wallpaper without git working-tree churn — Phase 25 / GTK-01
- ✓ Legacy Catppuccin assets and symlinks unlinked from `~/.config/gtk-4.0/` to establish unfolded unprivileged user directory — Phase 25 / GTK-02
- ✓ GTK 3 and GTK 4 `settings.ini` aligned to `adw-gtk3-dark` and upstream dots-hyprland defaults with zero Catppuccin references — Phase 25 / GTK-03
- ✓ GNOME desktop interface GSettings keys aligned to dark Material You defaults — Phase 25 / GTK-04
- ✓ Dynamic theme outputs guarded by `guard-paths.tsv` and root `.gitignore` with strict verification engine pass — Phase 25 / INTG-01, INTG-02
- ✓ Qt style engine Darkly plugin loaded and `widgetStyle=Darkly` configured in `~/.config/kdeglobals` without Kvantum package dependency — Phase 26 / QT-01
- ✓ Dynamic Material You palette generation via `kde-material-you-colors` updating `kdeglobals` color tokens with dark luminance invariant (< 0.25) — Phase 26 / QT-02
- ✓ Desktop FileChooser portal mapped to KDE and target KDE applications (Dolphin, Gwenview) harmonized with unmanaged live configs — Phase 26 / QT-03
- ✓ Guard path registration for `$XDG_CONFIG_HOME/kde-material-you-colors` in `guard-paths.tsv` with zero upstream git churn — Phase 26 / INTG-01, INTG-02
- ✓ Active/inactive Hyprland borders and pinned accents bound to Material You palette via `colors.lua` — Phase 27 / SHELL-01
- ✓ Quickshell ii widget accents and token schema harmonized with `colors.json` — Phase 27 / SHELL-02
- ✓ Live wallpaper reload pipeline via `switchwall.sh` coordinates Matugen, compositor, and shell with zero session restarts — Phase 27 / SHELL-03
- ✓ Guard path registration for `$XDG_CONFIG_HOME/hypr/hyprland/colors.lua` with strict verification engine pass — Phase 27 / INTG-01, INTG-02
- ✓ Fuzzel launcher styled with dynamic Material You palette tokens via Matugen template with 8-digit hex and solid/border alpha — Phase 28 / TERM-01
- ✓ Kitty terminal emulator themes dynamically via included `kitty-theme.conf` and reloads via SIGUSR1 with 0.85 background opacity — Phase 28 / TERM-02
- ✓ Guard path registration for `$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini` in `guard-paths.tsv` — Phase 28 / INTG-01
- ✓ Strict verification engine & zero git drift compliance — Phase 28 / INTG-02
- ✓ Reconciled `guard-paths.tsv` documenting all 8 dynamic theme outputs with 1:1 `.gitignore` parity and zero git churn on live reload — Phase 29 / INTG-01
- ✓ Relocated `fuzzel` and `kitty` to `restow/` to honor `collision-map.tsv` derivation, regenerated recovery table, preserved `PAIR_COUNT == 18`, and hardened verifier with hierarchical guard matching — Phase 29 / INTG-02
- ✓ Hardened `./bootstrap.sh` orchestrator with hierarchical prefix matching, Catppuccin pruning, parent pre-creation, fail-soft theming with color fallback, and multi-phase regression sweep — Phase 29 / INTG-03
- ✓ Kitty background opacity aligned to 0.90 per Phase 28 UAT preference with native parser assert and live process signaling — Phase 30 / DEBT-05
- ✓ Bootstrap virtualenv fallback export and idempotent template sanitization hooks for headless and dynamic reload robustness — Phase 30 / DEBT-06
- ✓ Phase 29 validation sign-off and 100% Nyquist compliance across all Milestone v0.5 phases (25–30) — Phase 30 / DEBT-07
- ✓ Phase 30 assert harness with strict verifier gate and multi-phase regression sweep across Phases 25–29 with zero git drift — Phase 30 / DEBT-08

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

### Validated — v0.6

- ✓ Personal Quickshell overlay under `restow/quickshell/` hot-reloads live on save without modifying `vendor/dots-hyprland` — Phase 31 / PILL-01
- ✓ Bar groups/pills rendered with modern rounded rectangle geometry (12–16px corner radius) — Phase 31 / PILL-02
- ✓ Consistent, balanced internal padding (4–6px) and fluid expansion/contraction animation across pill containers — Phase 31 / PILL-03
- ✓ Subtle pill borders and transparent/borderless container backgrounds preserved and verified — Phase 31 / PILL-04
- ✓ Memory usage formatted as definite gigabytes (`X.X/Y.Y GB (ZZ%)`) with dynamic swap reveal — Phase 32 / COMP-01
- ✓ CPU usage with custom formatting, warning thresholds, and clean visual indicators — Phase 32 / COMP-02
- ✓ Clock & Date widget representation, date pattern, 12h format with seconds, and non-glyph spacer — Phase 32 / COMP-03
- ✓ Media Player pill with track title, playback controls, and dynamic idle auto-collapse — Phase 32 / COMP-04
- ✓ Weather pill displaying temperature, conditions glyph, and interactive forecast popup — Phase 32 / COMP-05
- ✓ Utility buttons pill providing shortcuts for Screen Snip, Color Picker, and Screen Record — Phase 32 / COMP-06
- ✓ Pending Pacman and AUR package updates count via dedicated status pill — Phase 32 / COMP-07
- ✓ Privacy in-use alerts for active microphone (Amber) and screen recording (Red) — Phase 32 / COMP-08
- ✓ System Tray icons with balanced 4px spacing, monochrome tinting, and overflow menu — Phase 32 / COMP-09
- ✓ Audio/mic mute states, network connectivity, bluetooth status, and unread notification counter — Phase 32 / COMP-10
- ✓ Modular Left, Center, and Right sections in `BarContent.qml` with standalone pills and auto-collapsing Loaders — Phase 33 / LAYOUT-01
- ✓ Live interactive evaluation and trial-and-error layout locking on active monitors — Phase 33 / LAYOUT-02
- ✓ Responsive scaling across dual monitors (`DP-1` ultrawide and `HDMI-A-1`) with dynamic space defense and media width clamping — Phase 33 / LAYOUT-03
- ✓ Dynamic Material You palette adaptation across wallpaper switches with zero visual drift — Phase 34 / INTG-01
- ✓ Repository integrity verified with `arch/dots-hyprland.sh verify --strict` (0 findings, zero git drift) — Phase 34 / INTG-02
- ✓ Fresh-machine bootstrap (`./bootstrap.sh`) deploys customized bar and pill configurations cleanly — Phase 34 / INTG-03

### Active

(None currently active — milestone v0.6 complete. Use `/gsd-new-milestone` to plan next milestone.)

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

**Post-v0.4 reality:**
- Delivery model is fully captured and reproducible: all personal configurations reside in the three-tree capture taxonomy (`stow/`, `restow/`, `capture/`).
- Checked-in `collision-map.tsv` maps installer destinations to repo sources and is machine-asserted against silent rot.
- Link-aware `arch/dots-hyprland.sh verify --strict` checks link identity first, content second, and guards against folded directories and cp-through overwrites.
- `./bootstrap.sh` provides a single idempotent entry point to bootstrap a fresh machine end-to-end, with state persistence and strict verification exit-code binding.
- Unattended drift capture runs every 15 minutes via `dotfiles-capture.timer` and `.service`.
- Live session runs authoritative ii Lua entry (`~/.config/hypr/hyprland.lua`), with custom overlays in `custom/*.lua` matching repo inodes.

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
| Phase 25: Unlink ~/.config/gtk-4.0/ Catppuccin symlinks directly without backup | Target files are static system packages in /usr/share/themes/; eliminates root write-locks (D-07, D-09) | ✓ Clean unfolded user dir, Section 1 FAIL=0 |
| Phase 25: Align GTK-3/4 settings.ini to adw-gtk3-dark and dots-hyprland defaults | Upstream end-4 defaults (Google Sans Flex 11, Bibata cursor 24) ensure consistent base before Matugen (D-01..D-04) | ✓ Repo clean of Catppuccin, Section 2 FAIL=0 |
| Phase 25: Non-interactive Matugen CLI invocation with source-color-index 0 | Prevents interactive stdin hangs; generates valid @define-color Material You palettes (D-12) | ✓ Section 4 FAIL=0, verify --strict 0 findings |
| Phase 25: Automated 5-section assert harness scripts/phase25-gtk-material-you-assert.sh | Fail-closed porcelain snapshot checks gating GTK-01..04 and INTG-01..02 (D-14) | ✓ 43 checks passed, FAIL=0 FINDINGS=0 |
| Phase 25: Replace :insensitive with :disabled in GTK 4 Matugen template | GTK 4 CssProvider rejects :insensitive with parser warnings; :disabled loads cleanly (D-15..D-18) | ✓ Section 4 parser check PASS, UAT G-25-5 resolved |
| Phase 26: Darkly style engine over Kvantum for Qt/KDE styling | Upstream dots-hyprland ships Darkly plugin (`darkly6.so`); eliminates Kvantum package dependency while matching upstream architecture (D-01..D-04) | ✓ Section 3 FAIL=0, QT-01 |
| Phase 26: Execute `kde-material-you-colors` from quickshell virtualenv | Standalone binary in `$XDG_STATE_HOME/quickshell/.venv/bin` updates `kdeglobals` dynamically on wallpaper switch without manual config editing (D-05..D-09) | ✓ Section 4 FAIL=0, QT-02 |
| Phase 26: Map desktop FileChooser portal to KDE | Ensures file picker dialogs use native KDE portal with Material You styling under Hyprland (D-10..D-12) | ✓ Section 5 FAIL=0, QT-03 |
| Phase 26: Strict tab-separated guard path for `kde-material-you-colors` | Excludes dynamic generator state directory from git tracking in `guard-paths.tsv` (D-04, INTG-01) | ✓ `arch/dots-hyprland.sh verify --strict` 0 findings |
| Phase 27: Active/inactive Hyprland window borders bound to Material You accent colors | Active: `outline_variant` @ 77% alpha, inactive: `surface_container_low` @ 33% alpha, pinned: primary accent gradient via `colors.lua` (SHELL-01, D-01..D-03, D-08) | ✓ Section 2 FAIL=0, SHELL-01 |
| Phase 27: Quickshell ii token schema and palette alignment | Consumes `colors.json` providing 8 Material 3 palette tokens, opaque container background, and warning thresholds (SHELL-02, D-13..D-15, D-18..D-20) | ✓ Section 3 FAIL=0, SHELL-02 |
| Phase 27: Live coordinated wallpaper reload pipeline via `switchwall.sh` | Runs Matugen synchronously, monotonically updating `colors.lua` and `colors.json` with inotify live reload without restarting compositor or shell (SHELL-03, D-21..D-27, D-32) | ✓ Section 4 FAIL=0, SHELL-03 |
| Phase 27: Strict guard path registration for `colors.lua` | Strictly guards `$XDG_CONFIG_HOME/hypr/hyprland/colors.lua` in `guard-paths.tsv`, maintaining 0 drift across `arch/dots-hyprland.sh verify --strict` (INTG-01, INTG-02) | ✓ Section 5 FAIL=0, INTG-01, INTG-02 |
| Phase 28: Fuzzel launcher single-instance terminal runner and M3 colors | Configured terminal=kitty -1, radius 17, and dynamic theme include; Matugen template binds 7 color tokens with 8-digit hex (D-12..D-16) | ✓ Section 2 FAIL=0, TERM-01 |
| Phase 28: Kitty upstream configuration layout with dynamic theme inclusion | Dynamic kitty-theme.conf inclusion, 0.85 opacity, shell zsh, claimed search.py and scroll_mark.py into stow/kitty/ (D-01..D-03, D-08, D-09) | ✓ Section 3 FAIL=0, TERM-02 |
| Phase 28: Seamless live dynamic reload via SIGUSR1 on switchwall.sh | Synchronous Matugen generation updates fuzzel_theme.ini, kitty-theme.conf, and sequences.txt with strictly monotonic timestamps and SIGUSR1 signal without session drop (D-05, D-18) | ✓ Section 4 FAIL=0, TERM-01, TERM-02 |
| Phase 28: Strict tab-separated guard path for fuzzel_theme.ini | Strictly guards $XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini in guard-paths.tsv, passing arch/dots-hyprland.sh verify --strict with 0 findings (INTG-01, INTG-02) | ✓ Section 5 FAIL=0, INTG-01, INTG-02 |
| Phase 29: Relocate fuzzel and kitty to restow/ | Honor collision-map.tsv derivation (DESTROYED symlink status from upstream directory sync) | ✓ restow/README.md Section 3 table regenerated, arch/kitty.sh stows from ../restow, PAIR_COUNT == 18 preserved (INTG-02) |
| Phase 29: Hierarchical ancestor traversal in guard matching | Flat path lookup failed for nested dynamic outputs inside guarded directories (Kvantum/, kde-material-you-colors/) | ✓ Enforced in arch/dots-hyprland.sh and bootstrap.sh is_guarded_path() (INTG-01, INTG-03) |
| Phase 29: Asynchronous kdeglobals polling in live reload drill | switchwall.sh dispatches handle_kde_material_you_colors & in background | ✓ Polled kdeglobals mtime with 3s timeout, eliminating race conditions and working-tree churn (INTG-01) |
| Phase 29: Fail-soft initial theme generation and sensitive parent pre-creation | Defeated GNU Stow directory folding and handled offline/headless fresh installs | ✓ bootstrap.sh Step 5 pre-creates directories; Step 6 falls back to #3f51b5 color seed on missing wallpaper (INTG-03) |
| Phase 30: Kitty background opacity aligned to 0.90 per Phase 28 UAT preference | Respects operator preference with native parser assertion in phase28 harness | ✓ Kitty config aligned, test suite green (DEBT-05) |
| Phase 30: Virtualenv fallback export and template sanitization hooks | Robustness for headless/TTY environments and GTK 4 `:disabled` syntax preservation | ✓ bootstrap.sh and applycolor.sh hardened (DEBT-06) |
| Phase 30: Reconciled 29-VALIDATION.md and signed off 100% Nyquist compliance | All 6 milestone phases (25–30) validated and Nyquist-compliant with zero gaps | ✓ 100% Nyquist compliance across v0.5 (DEBT-07) |
| Phase 30: Phase 30 assert harness and multi-phase regression sweep | Verified Sections 1–5 and full v0.5 regression suite with zero git drift | ✓ scripts/phase30-tech-debt-assert.sh passed, FAIL=0 (DEBT-08) |
| Phase 31: Personal Quickshell status bar overlay in restow/quickshell/ | Modifies BarContent.qml and BarGroup.qml while keeping vendor/dots-hyprland pristine (D-05, PILL-01) | ✓ Deployed via stow --no-folding as leaf symlinks, Section 1 FAIL=0 |
| Phase 31: Dynamic content-driven status bar pill widths in BarContent.qml | Removes artificial implicitWidth clamp from leftCenterGroup and rightCenterGroup, propagates dimensions to outer MouseArea (D-01, D-04, PILL-02, PILL-03) | ✓ Section 2 FAIL=0 |
| Phase 31: Fluid width resizing animation via Material 3 emphasized deceleration | Adds Behavior on implicitWidth with duration 250 and emphasizedDecel curve in BarGroup.qml while preserving 100% upstream visual tokens (D-02, D-03, PILL-03, PILL-04) | ✓ Section 3 FAIL=0 |
| Phase 31: Phase 31 assert harness and strict system verification | scripts/phase31-overlay-pill-assert.sh validates Sections 1–4, restow/README.md table sync, live shell reload, and arch/dots-hyprland.sh verify --strict with 0 findings (D-06, D-07, D-08, INTG-02) | ✓ 4/4 sections passed, FAIL=0 FINDINGS=0 |
| Phase 32: Format RAM as definite gigabytes and dynamic Swap reveal | Resource.qml / Resources.qml format memory as `X.X/Y.Y GB (ZZ%)` and reveal Swap only when usage > 0% (D-01, D-03, COMP-01) | ✓ Section 2 FAIL=0, COMP-01 |
| Phase 32: Synchronized two-tier visual alerting | Synchronous Amber warning / Red critical color change across circular progress ring, MaterialSymbol icon, and text label (D-04, D-05) | ✓ Section 2 FAIL=0, COMP-01, COMP-02 |
| Phase 32: ClockWidget non-glyph spacer item | Replaces unicode bullet dot glyph with clean 8px spacer item while preserving calendar popup and sidebar toggle (D-08, D-09, COMP-03) | ✓ Section 3 FAIL=0, COMP-03 |
| Phase 32: Dynamic Privacy in-use telemetry alerts | Connects PipeWire audio/video activity to animated Amber mic and Red screen share revealers in status cluster (D-13, COMP-08) | ✓ Section 3 FAIL=0, COMP-08 |
| Phase 32: Dedicated dynamic package updates pill | Aggregates official Arch and AUR updates non-blocking, revealing update count badge and launching Kitty yay update (D-18, COMP-07) | ✓ Section 3 FAIL=0, COMP-07 |
| Phase 32: BarContent uncluttering and scroll jitter removal | Omits ActiveWindow title and removes background scroll handlers from side mouse areas to eliminate accidental volume/brightness jitter (D-15, D-16) | ✓ Section 3 FAIL=0 |
| Phase 33: Modular 3-zone layout in BarContent.qml | Decouple Left, Center, Right into standalone pills with clean 4px gaps and zero vertical dividers | ✓ 33-02 (LAYOUT-01) |
| Phase 33: Option 1 Dynamic Spacing Defense | Clamp Media layout width to 200px with Text.ElideRight to guarantee >= 180px collision buffer on 1080p | ✓ 33-02 (LAYOUT-03) |
| Phase 33: Dead-center Workspaces with flanking Weather and Clock | Anchor Workspaces strictly to monitor horizontalCenter (50%), flanked by Weather on left and Clock on right | ✓ 33-03 User checkpoint sign-off (LAYOUT-02) |
| Phase 34: Bootstrap pre-creation and socket robustness | Pre-create ~/.config/quickshell/ii/modules/ii/bar to prevent stow directory folding; dynamic Hyprland socket detection | ✓ 34-01 (INTG-02, INTG-03) |
| Phase 34: Fail-soft color priming and 5-section test harness | Fall back to default color seed #3f51b5 on missing wallpaper; scaffold scripts/phase34-verification-assert.sh | ✓ 34-01, 34-02 (INTG-01..03) |

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
*Last updated: 2026-09-20 after v0.6 milestone*
