# Milestones

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
