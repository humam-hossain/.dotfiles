# Milestones

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
