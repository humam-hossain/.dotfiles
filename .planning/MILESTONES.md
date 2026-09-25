# Milestones

## v0.8 Notification Experience & Shell Interaction Polish (Shipped: 2026-09-25)

**Closeout type:** `verified_closeout`  
**Phases completed:** 5 phases, 9 plans, 26 tasks (Phases 38–41, including Phase 40.1)  
**Git range:** `553afb8` → `fa496f4` (2026-09-22 → 2026-09-25) · 97 commits  
**Diffstat:** 89 files changed, +16,813 / −1,011  

**Delivered:** Comprehensive shell interaction refinements, notification ergonomics, and system power integrations across Quickshell ii and Hyprland on Arch Linux. Integrated `power-profiles-daemon` into systemd and package manifests, connecting it to Quickshell's power profile quick-toggle with zero local QML overrides. Implemented dynamic coordinate anchoring and screen boundary clamping for `MediaControls.qml` relative to the top status bar's `Media` pill via a clean `GlobalStates` coordinate bridge. Delivered enhanced notification ergonomics in `restow/quickshell/`: an always-visible 'X' close button on sidebar cards, smart body click routing invoking sending application D-Bus default actions with web URL fallback, and QV4-safe regex OTP verification code extraction with a 1-click "Copy [Code]" Material 3 quick-action chip. Restored 10px horizontal breathing room to `ClockWidget.qml` matching adjacent pills, established a single source of truth for the 150% (1.5) volume ceiling across Hyprland keybinds (`custom/keybinds.lua`), Quickshell services (`Config.qml`, `Audio.qml`), and right sidebar slider (`QuickSliders.qml` with 100% stop notch) and mouse scroll. Verified all capabilities under a consolidated automated assertion engine (`scripts/phase41-interactions-assert.sh`) orchestrating all milestone test harnesses with zero working-tree churn and strict repository integrity.

### Key accomplishments

1. Integrated `power-profiles-daemon` system service into Arch Linux, tracked in package manifests (`arch/pkglist-native.txt`, `arch/dots-hyprland.sh`, `bootstrap.sh`), and verified live Quickshell UPower D-Bus binding with strict zero local QML overrides and clean repository integrity (Phase 38 / POWER-01..03).
2. Dynamic media popup positioning (`MediaControls.qml`) directly beneath the top status bar's `Media` pill across active monitors with robust horizontal screen boundary clamping (`Math.min` / `Math.max`) via `GlobalStates` coordinate bridge and HoverHandler event isolation (Phase 39 / MEDIA-01..02).
3. Notification Center quick-dismiss and smart routing in `restow/quickshell/`: 1-click 'X' close button on single sidebar cards (`NotificationGroup.qml`), smart body click routing to app D-Bus default action and web links, and QV4-safe regex OTP code extraction with 1-click "Copy [Code]" action chip (`NotificationItem.qml`, `NotificationUtils.qml`) (Phase 40 / NOTIF-01..02, NAV-01..02, OTP-01..02).
4. Restored 10px horizontal breathing room to status bar clock/date pill (`ClockWidget.qml`) matching adjacent pills, and unified the 150% volume ceiling from a single source of truth (`config.json`) consumed by Hyprland keybinds (`custom/keybinds.lua`), Quickshell audio services (`Config.qml`, `Audio.qml`), right sidebar volume slider (`QuickSliders.qml` with 100% stop notch), and bar mouse scroll (Phase 40.1 / CLOCK-01, VOL-01..02).
5. Consolidated test runner and regression harness (`scripts/phase41-interactions-assert.sh`) orchestrating all milestone sub-harnesses (Phases 38, 39, 40, 40.1), verifying non-invasive leaf symlinks under `restow/quickshell/`, and asserting strict zero git churn (`arch/dots-hyprland.sh verify --strict` with `FAIL=0 FINDINGS=0`) (Phase 41 / INTG-01..03).

**Known verification overrides:** 0 (all phases verified, 17/17 requirements satisfied, verified closeout)

**Archives:**

- [milestones/v0.8-ROADMAP.md](milestones/v0.8-ROADMAP.md)
- [milestones/v0.8-REQUIREMENTS.md](milestones/v0.8-REQUIREMENTS.md)
- [milestones/v0.8-phases/](milestones/v0.8-phases/)
- [milestones/v0.8-MILESTONE-AUDIT.md](milestones/v0.8-MILESTONE-AUDIT.md)

---

## v0.7 Voice Status Bar Component & Audio Telemetry (Shipped: 2026-09-21)

**Closeout type:** `override_closeout`  
**Phases completed:** 3 phases, 4 plans, 6 tasks (Phases 35–37)  
**Git range:** `356e74a` → `505ff11` (2026-09-21) · 59 commits  
**Diffstat:** 47 files changed, +9,206 / −62 · 460 LOC QML (Voice.qml + VoicePill.qml) + 1,767 LOC test harnesses  

**Delivered:** Non-blocking voice status bar component and telemetry architecture for Quickshell on Arch Linux / Hyprland, connecting to the local `voice` speech engine (`faster-whisper` STT and `Kokoro` TTS) via tmpfs IPC state files. Centralized `Voice.qml` Singleton service observing `$XDG_RUNTIME_DIR/voice-stt/` with adaptive polling (100ms active / 500ms idle), procfs process liveness verification with automated stale lock purging, drift-free wall-clock duration counting with reload recovery, and TTS voice metadata extraction. Dedicated `VoicePill.qml` status bar pill with `graphic_eq` Material Symbol iconography, breathing pulse animation, Sequential Linear Flow state transitions with 1.5s wrap-up linger, and fluid 250ms Material 3 emphasized deceleration width expansion. Integrated into both horizontal `BarContent.qml` and vertical `VerticalBarContent.qml` layouts with responsive multi-monitor adaptation, inert mouse isolation, and dynamic Material You palette adaptation with zero hardcoded hex colors or git churn.

### Key accomplishments

1. Centralized non-blocking Quickshell Singleton service (`Voice.qml`) with 6 `FileView` instances polling tmpfs state files, procfs `/proc/<pid>/cmdline` liveness verification, automated stale PID lock purging via `Quickshell.execDetached`, drift-free `Date.now()` wall-clock duration tracking with `/proc/<pid>/stat` start-tick reload recovery, and TTS voice/backend metadata extraction (Phase 35 / TELEM-01..05).
2. Dedicated `VoicePill.qml` status bar pill extending `BarGroup` with `graphic_eq` Material Symbol, direct content-bound `implicitWidth` bypassing Qt 6.11 GridLayout caching, breathing 1.0↔0.5 pulse animation with fail-safe reset, Sequential Linear Flow state engine with 1500ms wrap-up linger caching `lastRecordedDuration`, and dynamic `Appearance.colors.*` palette tokens with zero hardcoded hex (Phase 36 / VOICE-01..06).
3. Horizontal and vertical bar integration — `VoicePill` mounted in `BarContent.qml` Right zone immediately after `mediaLoader` and in `VerticalBarContent.qml` `bottomSectionColumnLayout` with `vertical: true` and `AlignHCenter`, responsive `useShortenedForm` suppression, and inert `MouseArea` event isolation (Phase 37 / INTG-01, G-37-2).
4. Hardened duration tracking against clock skew and procfs drift by clamping `elapsedSec` to `Math.max(0, ...)` and validating non-future `startTime` with `Math.min(Date.now(), ...)`, resolving live STT recording showing `0:00` (Phase 37 / G-37-6).
5. Deployed all managed QML files via GNU Stow leaf symlinks under `restow/quickshell/` without folding ancestor directories, maintaining `vendor/dots-hyprland` pristine and passing `arch/dots-hyprland.sh verify --strict` with `FAIL=0 FINDINGS=0` (Phase 37 / INTG-02..04).
6. Three automated assertion harnesses (`phase35-voice-telemetry-assert.sh`, `phase36-voice-pill-assert.sh`, `phase37-voice-pill-assert.sh`) covering state observation, liveness, duration, animation, layout, vertical integration, and strict repository verification.

**Known verification overrides:** 7 newly acknowledged (5 legacy debug sessions on retired bar surface + 2 v0.7 debug sessions resolved by gap closure), 0 carried forward (see STATE.md Deferred Items)

**Archives:**

- [milestones/v0.7-ROADMAP.md](milestones/v0.7-ROADMAP.md)
- [milestones/v0.7-REQUIREMENTS.md](milestones/v0.7-REQUIREMENTS.md)
- [milestones/v0.7-MILESTONE-AUDIT.md](milestones/v0.7-MILESTONE-AUDIT.md)

## v0.6 Top Status Bar Layout, Pill Styling & Component Customization (Shipped: 2026-09-20)

**Closeout type:** `verified_closeout`  
**Phases completed:** 4 phases, 12 plans, 37 tasks (Phases 31–34)  
**Git range:** `997e895` → `28303b7` (2026-09-20) · 80 commits  
**Diffstat:** 79 files changed, +15,822 / −45 · 14.9k LOC shell scripts and QML  

**Delivered:** Modern modular 3-zone top status bar layout under Quickshell with rounded rectangle pill geometry (12–16px radius, 4–6px internal padding), fluid 250ms Material 3 emphasized deceleration width resizing animation across all bar containers, definite gigabyte memory reporting (`X.X GB / Y.Y GB`), custom CPU indicators, non-glyph Clock spacer, balanced System Tray spacing (4px), unattended package updates with cache cleaning (`yay -Syu --noconfirm && yay -Sc --noconfirm`), media title clamping with text ellipsis, reactive screen recording alerts (`wf-recorder`), dead-center Workspaces flanked symmetrically by Weather and Clock & Date, full dynamic Material You palette adaptability across wallpaper switches with zero git working tree churn, and strict repository cleanliness (`arch/dots-hyprland.sh verify --strict` 0 findings).

### Key accomplishments

1. Personal Quickshell overlay infrastructure established under `restow/quickshell/` deployed via GNU Stow leaf symlinks without folding ancestor directories, updating `restow/README.md`, with hot-reloading on save and zero modifications to `vendor/dots-hyprland` (Phase 31 / PILL-01).
2. Unlocked dynamic content-driven status bar pill widths in `BarContent.qml`, with modern rounded-rectangle geometry (12–16px radius, 4–6px padding) and fluid 250ms Material 3 emphasized deceleration width resizing animation in `BarGroup.qml` (Phase 31 / PILL-02..04).
3. Systematic Tier 1 and Tier 2 component audit and formatting enhancements: definite GB RAM format (`X.X GB / Y.Y GB`), dynamic swap reveal, two-tier Amber/Red resource alerts, non-glyph clock spacer, balanced 4px tray spacing, unattended system updates (`yay -Syu --noconfirm && yay -Sc --noconfirm`), media title width clamping with ellipsis, and reactive screen recording indicators (`wf-recorder`) (Phase 32 / COMP-01..10).
4. Decoupled `BarContent.qml` into modular Left, Center, and Right zones with clean 4px inter-pill gaps and zero vertical dividers, locking in dead-center Workspaces flanked symmetrically by Weather on the left and Clock & Date on the right, verified across dual monitors (`DP-1` ultrawide and `HDMI-A-1`) (Phase 33 / LAYOUT-01..03).
5. Dynamic Material You palette adaptation across wallpaper switches verified with zero visual defects, `./bootstrap.sh` hardened with sensitive directory pre-creation and color priming, and repository integrity verified with `arch/dots-hyprland.sh verify --strict` (0 findings, zero working tree drift) (Phase 34 / INTG-01..03).
6. 100% automated test coverage across four fail-closed multi-section assertion harnesses (`phase31-overlay-pill-assert.sh`, `phase32-component-formatting-assert.sh`, `phase33-layout-assert.sh`, `phase34-verification-assert.sh`).

**Known verification overrides:** 0 newly acknowledged, 5 carried forward from a prior close (see STATE.md Deferred Items)

**Archives:**

- [milestones/v0.6-ROADMAP.md](milestones/v0.6-ROADMAP.md)
- [milestones/v0.6-REQUIREMENTS.md](milestones/v0.6-REQUIREMENTS.md)
- [milestones/v0.6-phases/](milestones/v0.6-phases/)
- [milestones/v0.6-MILESTONE-AUDIT.md](milestones/v0.6-MILESTONE-AUDIT.md)

---

## v0.5 System-wide Material You theming (Shipped: 2026-09-18)

**Closeout type:** `override_closeout`  
**Phases completed:** 6 phases, 17 plans, 32 tasks (Phases 25–30)  
**Git range:** `v0.4` → `v0.5` (2026-09-16 → 2026-09-18) · 125 commits  
**Diffstat:** 111 files changed, +19,398 / −75

**Delivered:** Unified system-wide Material You dynamic theming generated from wallpaper across GTK 3/4 (libadwaita and adw-gtk3-dark), Qt 6 / KDE applications (Darkly style engine, FileChooser portal, kdeglobals), Hyprland window borders (`colors.lua`), Quickshell ii widgets (`colors.json`), Fuzzel launcher (`fuzzel_theme.ini`), and Kitty terminal emulator (`kitty-theme.conf` / `sequences.txt`), backed by strict data contracts (`guard-paths.tsv`), three-tree taxonomy reconciliation (`restow/`), hardened `./bootstrap.sh`, and 100% Nyquist validation compliance with zero git churn.

### Key accomplishments

1. Retired legacy root-pointing Catppuccin symlinks in `~/.config/gtk-4.0/`, aligned GTK 3 & 4 `settings.ini` to `adw-gtk3-dark`, synchronized GNOME GSettings keys, and verified dynamic Matugen GTK CSS generation with GTK 4 `:disabled` syntax — GTK-01..04, INTG-01..02
2. Qt 6 Darkly style engine integration, KDE applications (Dolphin, Kate, Gwenview) harmonized, native desktop FileChooser portal mapped to KDE, and dynamic `kdeglobals` generation via `kde-material-you-colors` with dark luminance invariant (<0.25) — QT-01..03, INTG-01
3. Bound Hyprland active, inactive, and group window borders to Matugen `colors.lua`, coordinated Quickshell ii widget tokens and appearance with `colors.json`, and established live coordinated wallpaper reload via `switchwall.sh` — SHELL-01..03, INTG-01..02
4. Fuzzel launcher styled with dynamic Material You palette tokens via Matugen template with 8-digit hex, and Kitty terminal emulator dynamic theming via included `kitty-theme.conf` with SIGUSR1 live signaling and 0.90 background opacity — TERM-01..02, DEBT-05
5. Relocated `fuzzel` and `kitty` to `restow/` honoring collision map derivation, reconciled `guard-paths.tsv` documenting all 8 dynamic theme outputs with 1:1 `.gitignore` parity, and hardened `./bootstrap.sh` with sensitive directory pre-creation, Catppuccin pruning, and fail-soft fallback theming — INTG-01..03
6. Technical debt resolution and validation sign-off: 100% Nyquist validation compliance across all 6 milestone phases (25–30), virtualenv fallback exports, idempotent template sanitization hooks, and multi-phase regression stability across Phases 25–29 with zero git drift — DEBT-05..08

### Known Gaps / Deferred Items

| ID / Item | Description | Disposition |
|-----------|-------------|-------------|
| debug: DEBUG-gtk-visual-theming-pink-accent | GTK visual theming pink accent investigation | Acknowledged; root causes (Qt app launch and Dracula icon theme) resolved in Phase 26 |
| debug: cpu-warning-color-missing | Open debug session (v0.1 local bar) | Re-acknowledged; product tree retired in Phase 8 |
| debug: keyboard-volume-ceiling | Open debug session (v0.1 local bar) | Re-acknowledged; product tree retired in Phase 8 |
| debug: pavucontrol-launch-broken | Open debug session (v0.1 local bar) | Re-acknowledged; product tree retired in Phase 8 |
| debug: ram-label-spacing | Open debug session (v0.1 local bar) | Re-acknowledged; product tree retired in Phase 8 |
| CUST-01..04 | Waybar custom ports (ping, weather, earthquake) | Future milestone |
| POLISH-02..03 | FWK-02 / IPC-02 style session integration; v0.1 debug re-eval | Future milestone |

**Known verification overrides:** 5 newly acknowledged, 0 carried forward from a prior close (see STATE.md Deferred Items)

**Archives:**

- [milestones/v0.5-ROADMAP.md](milestones/v0.5-ROADMAP.md)
- [milestones/v0.5-REQUIREMENTS.md](milestones/v0.5-REQUIREMENTS.md)
- [milestones/v0.5-phases/](milestones/v0.5-phases/)
- [milestones/v0.5-MILESTONE-AUDIT.md](milestones/v0.5-MILESTONE-AUDIT.md)

---

## v0.4 Personal config layer (Shipped: 2026-09-16)

**Closeout type:** `override_closeout`  
**Phases completed:** 8 phases, 41 plans, 91 tasks (Phases 17–24)  
**Git range:** `v0.3` → `v0.4` (2026-09-12 → 2026-09-16) · 263 commits  
**Diffstat:** 241 files changed, +54,309 / −692

**Delivered:** Personal config layer — three-tree capture model (`stow/`, `restow/`, `capture/`), machine-asserted installer collision map (`collision-map.tsv`), link-aware `verify` suite with strict exit codes (0/1/2), personal `hypr/custom` Lua overlays and startup autostart restoration (`graphical-session.target`), Quickshell ii bar `config.json` copy-capture with unattended systemd user timer, KDE/GTK per-file capture with guarded theme outputs (`guard-paths.tsv`), one-command idempotent bootstrap (`./bootstrap.sh`), and comprehensive technical debt reconciliation with 100% Nyquist validation.

### Key accomplishments

1. Universal stow flag correction (`--verbose=5 --no-folding`), `safe_rm_path` repository containment clause, secret scan, and `graphical-session.target` restoration via `custom/execs.lua` — FIX-01..06, CAP-04, START-02..03
2. Three-tree capture model (`stow/`, `restow/`, `capture/`), checked-in installer collision map with anti-rot assertions, and first-class `verify` and `capture` wrapper CLI subcommands — CAP-01..08, FIX-03, FIX-05
3. Link-aware `verify` asserting symlink identity before content, diffing capture paths, with strict exit codes (0/1/2) proven adversarially against `rsync -a --delete` — VER-01..04
4. Personal Hyprland overlays under repo SoT (all six `custom/*.lua`), personal keybinds via `hl.unbind`, launcher variables, and autostart `exec-once` application restoration — HYPR-01..03, START-01, SAFE-01
5. Quickshell ii bar `config.json` atomic copy-capture surviving `switchwall.sh`, and unattended synchronization on a 15-minute systemd user timer (`dotfiles-capture.timer`) — BAR-01..02, CAP-06
6. Dolphin, KDE, and GTK per-file capture with unfolded parent directories, `guard-paths.tsv` data contract excluding theme artifacts, and cp-through live recovery — KDE-01..03
7. One-command idempotent bootstrap (`./bootstrap.sh`) with resumable JSON state, guarded stub de-linking with SHA-256 backup manifests, relogin boundary guidance, and package snapshots — BOOT-01..05
8. Technical debt reconciliation: 100% Nyquist compliance across all phases, 39/39 requirements traceability sync, repo hygiene (.gitignore, non-credential .env affirmation), and session keybinding cheatsheet alignment — DEBT-01..04

### Known Gaps / Deferred Items

| ID / Item | Description | Disposition |
|-----------|-------------|-------------|
| debug: cpu-warning-color-missing | Open debug session (v0.1 local bar) | Re-acknowledged; product tree retired in Phase 8 |
| debug: keyboard-volume-ceiling | Open debug session (v0.1 local bar) | Re-acknowledged; product tree retired in Phase 8 |
| debug: pavucontrol-launch-broken | Open debug session (v0.1 local bar) | Re-acknowledged; product tree retired in Phase 8 |
| debug: ram-label-spacing | Open debug session (v0.1 local bar) | Re-acknowledged; product tree retired in Phase 8 |
| CUST-01..04 | Waybar custom ports (ping, weather, earthquake) | Future milestone |
| POLISH-02..03 | FWK-02 / IPC-02 style session integration; v0.1 debug re-eval | Future milestone |

**Known verification overrides:** 4 (open debug sessions on retired local bar; see STATE.md Deferred Items)

**Archives:**

- [milestones/v0.4-ROADMAP.md](milestones/v0.4-ROADMAP.md)
- [milestones/v0.4-REQUIREMENTS.md](milestones/v0.4-REQUIREMENTS.md)
- [milestones/v0.4-phases/](milestones/v0.4-phases/)
- [milestones/v0.4-MILESTONE-AUDIT.md](milestones/v0.4-MILESTONE-AUDIT.md)

---

## v0.3 Full ii install (Shipped: 2026-09-09)

**Closeout type:** `standard`  
**Phases completed:** 7 phases, 33 plans (Phases 10–16)  
**Git range:** `v0.2` → `v0.3` (2026-08-02 → 2026-09-09) · 264 commits  
**Diffstat:** 290 files changed, +50,448 / −3,942

**Delivered:** Full dots-hyprland install path — impact inventory, per-surface dispositions, personal `hypr/custom` Lua overlays, live full adopt with session running via ii Lua entry, safe profile retired (no SAFE_DEFAULTS, no flags to choose), full-only playbook with bare commands end-to-end.

### Key accomplishments

1. Full-install impact inventory (`10-INVENTORY.md`) mapping every path/flag/package effect of full install vs personal configs, with Wave 0 assert harness — INV-01..04
2. Per-surface disposition decisions (`11-DISPOSITIONS.md`) covering keep/migrate/accept/defer for all high-risk surfaces, staged flag choices, chrome accept-remove — DISP-01..04
3. Personal `hypr/custom` Lua overlays: `general.lua` dual-head + 11 workspace pins, empty `env.lua`/`execs.lua` require slots, SoT fence and D-19 adversarial assert — OVL-01..03
4. Live full adopt: `install --full` behind preflight gate; session loads via ii Lua entry (`hyprland.lua`); overlays applied byte-identical; Waybar/rofi/swaync accept-removed — ADOPT-01..03
5. Safe profile retirement: `SAFE_DEFAULTS` removed, bare `install`/`install-files` is the full behavior, `--full` is announced no-op alias, all assertion suites green — FULL-01, FULL-02, FULL-04
6. Full-only playbook `docs/dots-hyprland-workflow.md` rewritten end-to-end with bare commands — DOC-03, DOC-04

### Known Gaps / Tech Debt

| ID / Item | Description | Disposition |
|-----------|-------------|-------------|
| D-38 | `graphical-session.target` autostart lost at adopt | Unowned; no closing phase assigned |
| WR-02 | Three roles of repo `hyprland.conf` — two live roles remain | Open in `14-REVIEW.md`; low exposure |
| D-40 | Human re-login after Phase 16 changes | Pending operator confirmation |
| Process | Phases 11, 15 missing SECURITY.md / UAT.md | Defensible — documentation-only phases |
| CUST-01..04 | Waybar custom ports (ping, weather, earthquake) | Future milestone |
| POLISH-01..03 | Wrapper verify; FWK-02/IPC-02; v0.1 debug re-eval | Future milestone |

**Known verification overrides:** 0 (milestone audit passed with `tech_debt` status)

**Archives:**

- [milestones/v0.3-ROADMAP.md](milestones/v0.3-ROADMAP.md)
- [milestones/v0.3-REQUIREMENTS.md](milestones/v0.3-REQUIREMENTS.md)
- [milestones/v0.3-phases/](milestones/v0.3-phases/)
- [milestones/v0.3-MILESTONE-AUDIT.md](milestones/v0.3-MILESTONE-AUDIT.md)

---

## v0.2 Adopt dots-hyprland (Shipped: 2026-08-02)

**Closeout type:** `override_closeout`  
**Phases completed:** 5 phases, 15 plans, ~38 tasks (SUMMARY roll-up reported 29)  
**Git range:** `v0.1` → HEAD (2026-07-25 → 2026-08-02) · 106 commits  
**Diffstat:** 1025 files changed, +17,663 / −78,068 (dominated by retiring in-repo `.config/quickshell`)

**Delivered:** dots-hyprland adopted as managed dependency — personal fork + `vendor/dots-hyprland` pin, thin `arch/dots-hyprland.sh` wrapper, live `qs -c ii` dual-running with Waybar, v0.1 local Quickshell product retired, operator install/update playbook shipped.

### Key accomplishments

1. Personal public fork `humam-hossain/dots-hyprland` + `vendor/dots-hyprland` recursive submodule pin (`1a9ffb78`, dual remotes, nested shapes) — OWN-01..03
2. Thin `arch/dots-hyprland.sh` around upstream `./setup` with SAFE_DEFAULTS (`--core --skip-hyprland`), backup gate, flag passthrough — WRAP-01..04
3. Live wrapper install + personal hypr hooks (`ILLOGICAL_IMPULSE_VIRTUAL_ENV`, `qs -c ii`); Waybar dual-run preserved — LIVE-01..04 (UAT 14/14)
4. Retired in-repo v0.1 product: deleted `.config/quickshell` (933 files) and hard-deleted `arch/quickshell.sh` — RET-01/02 (UAT 12/12)
5. Canonical playbook `docs/dots-hyprland-workflow.md` — cold-clone install/adopt + pin-bump update; exp-merge/online cache non-primary — DOC-01/02 (UAT 9/9)

### Known Gaps / Overrides

| ID / Item | Description | Disposition |
|-----------|-------------|-------------|
| Milestone audit | No `v0.2-MILESTONE-AUDIT.md` | Acknowledged at close; phases 5–9 each verification-passed |
| debug: cpu-warning-color-missing | Open debug session (v0.1 local bar) | Re-acknowledged; product tree retired in Phase 8 — likely obsolete on stock ii |
| debug: keyboard-volume-ceiling | Open debug session (v0.1 local bar) | Re-acknowledged; likely obsolete on stock ii |
| debug: pavucontrol-launch-broken | Open debug session (v0.1 local bar) | Re-acknowledged; likely obsolete on stock ii |
| debug: ram-label-spacing | Open debug session (v0.1 local bar) | Re-acknowledged; likely obsolete on stock ii |
| CUST-01..04 | Waybar custom ports (ping, weather, earthquake, overlays) | Future milestone |
| CUT-01/02 | Waybar/rofi/swaync cutover; full ii hypr Lua cutover | Future milestone; dual-run intentional |
| POLISH-01..03 | Wrapper verify; FWK-02/IPC-02 under upstream; v0.1 debug re-eval | Future milestone |

**Known verification overrides:** 5 (missing formal milestone audit + 4 debug sessions; see STATE.md Deferred Items)

**Archives:**

- [milestones/v0.2-ROADMAP.md](milestones/v0.2-ROADMAP.md)
- [milestones/v0.2-REQUIREMENTS.md](milestones/v0.2-REQUIREMENTS.md)
- [milestones/v0.2-phases/](milestones/v0.2-phases/)

---

## v0.1 Core Framework & Basic Bar (Shipped: 2026-07-25)

**Closeout type:** `override_closeout`  
**Phases completed:** 4 phases, 31 plans, 39 tasks  
**Git range:** `feat(01-01)` → Phase 4 docs (2026-07-21 → 2026-07-25)  
**Codebase:** ~589 QML files / ~57k LOC under `.config/quickshell/`

**Delivered:** Usable Quickshell top bar with Material theme, core Waybar-parity modules (workspaces, clock, tray, network, CPU, RAM, disk, volume), stock bar IPC, and same-PID soft reload — dual-running beside Waybar.

### Key accomplishments

1. Wholesale dots-hyprland `ii` tree as foundation — PanelLoader, panel families, MaterialThemeLoader, service singletons
2. Core bar productized — D-15 L→R layout, D-19 indicator strip, dual-write Config.qml + live `config.json`
3. System & audio modules — CPU→RAM→Disk rings with dual thresholds; mute/mic icon+%; volume ceiling 130% with auto-unmute
4. Stock `qs ipc call bar {open,close,toggle}` verified multi-monitor; content-change soft reload same-PID silent
5. Wave 0 Nyquist assert harnesses for phases 2–4; FWK-02/IPC-02/Waybar cutover packaged as explicit backlog

### Known Gaps

| ID / Item | Description | Disposition |
|-----------|-------------|-------------|
| FWK-02 | Quickshell auto-start via Hyprland exec-once | Deferred finishing touch (`04-DEFERRED.md`) |
| IPC-02 | Hyprland keybind to toggle bar visibility | Deferred finishing touch (`04-DEFERRED.md`) |
| Waybar cutover | Remove Waybar from session once parity confirmed | Backlog; dual-run intentional |
| debug: cpu-warning-color-missing | Open debug session | Acknowledged at close |
| debug: keyboard-volume-ceiling | Open debug session | Acknowledged at close |
| debug: pavucontrol-launch-broken | Open debug session | Acknowledged at close |
| debug: ram-label-spacing | Open debug session | Acknowledged at close |

**Known verification overrides:** 6 (see STATE.md Deferred Items + gaps above)

**Archives:**

- [milestones/v0.1-ROADMAP.md](milestones/v0.1-ROADMAP.md)
- [milestones/v0.1-REQUIREMENTS.md](milestones/v0.1-REQUIREMENTS.md)
- [milestones/v0.1-phases/](milestones/v0.1-phases/)

---
