# Milestones

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
