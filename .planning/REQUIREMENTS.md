# Requirements: Quickshell Desktop Shell

**Defined:** 2026-07-20
**Core Value:** The shell must reproduce every current Waybar module's functionality so the desktop loses no capability in the switch — while gaining a unified, themeable, runtime-configurable shell.

## v1 Requirements

Requirements for milestone v0.1: Core Framework & Basic Bar.

### Framework

- [x] **FWK-01**: User can launch a Quickshell shell that renders a top bar on each connected monitor
- [ ] **FWK-02**: User sees Quickshell auto-start via Hyprland exec-once at login
- [x] **FWK-03**: Shell uses service-singleton pattern (services expose state, widgets render it)
- [x] **FWK-04**: Shell entry point (shell.qml) loads panel families via PanelLoader architecture
- [x] **FWK-05**: Shell directory structure follows dots-hyprland conventions (modules/, services/, scripts/, defaults/, assets/, qmldir manifests)

### Theme

- [x] **THM-01**: User sees a Material color scheme applied shell-wide on startup via MaterialThemeLoader
- [x] **THM-02**: Theme tokens (primary, secondary, surface, etc.) are exposed as QML properties usable by all widgets

### Bar Modules

- [x] **BAR-01**: User can see and click Hyprland workspace indicators to switch workspaces
- [x] **BAR-02**: User sees current date and time in the bar
- [x] **BAR-03**: User sees system tray icons from running applications
- [x] **BAR-04**: User sees network connection status (wifi/ethernet/disconnected)
- [x] **BAR-05**: User sees current CPU utilization in the bar
- [x] **BAR-06**: User sees current RAM utilization in the bar
- [x] **BAR-07**: User sees disk space information in the bar
- [x] **BAR-08**: User can see and adjust audio volume from the bar (scroll to change, click to mute)

### IPC & Shortcuts

- [x] **IPC-01**: Shell exposes an IPC socket for external commands (show/hide bar, reload)
- [ ] **IPC-02**: User can toggle bar visibility via a Hyprland keybind
- [ ] **IPC-03**: Shell supports graceful reload without full restart (preserves runtime state)

## v2 Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### Custom Modules

- **CMOD-01**: User sees current weather conditions in the bar (via weather script)
- **CMOD-02**: User sees weather forecast in the bar (via forecast script)
- **CMOD-03**: User sees ping monitor status in the bar (reads localhost:8765/api/status)
- **CMOD-04**: User sees earthquake alert notifications in the bar

### Theme Extensions

- **THMX-01**: User can configure Catppuccin Mocha colors via Material scheme adapter (matches existing desktop)

### Launcher & Clipboard

- **LNCH-01**: User can open an app launcher that replaces rofi drun mode
- **CLIP-01**: User can open a clipboard manager that replaces rofi clipboard history

### Notifications

- **NOTF-01**: Shell acts as notification daemon replacing swaync
- **NOTF-02**: User sees notification popups and a control center

### Advanced Features

- **ADV-01**: User can switch between panel families at runtime
- **ADV-02**: User can configure shell via a GUI settings app
- **ADV-03**: User can access quick toggles (bluetooth, night-light, idle inhibitor, etc.)
- **ADV-04**: User can access productivity widgets (emoji picker, timer, todo, updates checker)
- **ADV-05**: User can access OSD popups (volume OSD, calendar popup, network popup)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Brightness/backlight widget | ddcutil DDC/CI polling caused iGPU crash (2026-07-16 post-mortem) |
| Quickshell lock screen | Keeping hyprlock; user decision |
| AI chat service | Niche dots-hyprland feature, not wanted |
| Booru image board | Niche, not wanted |
| Song recognition (SongRec) | Niche, not wanted |
| LaTeX renderer | Niche, not wanted |
| Google Cloud / Translation | Niche, not wanted |
| Anti-flashbang shader | Not wanted |
| First-run / welcome onboarding | Personal setup, not needed |
| ConflictKiller / Privacy / SystemInfo | Not wanted |
| Iterating on old deleted Quickshell | Fresh build; old code is reference only |
| Debian/Ubuntu parity | Primary target is Arch; separate concern |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FWK-01 | Phase 1 | Complete |
| FWK-02 | Phase 4 | Pending |
| FWK-03 | Phase 1 | Complete |
| FWK-04 | Phase 1 | Complete |
| FWK-05 | Phase 1 | Complete |
| THM-01 | Phase 1 | Complete |
| THM-02 | Phase 1 | Complete |
| BAR-01 | Phase 2 | Complete |
| BAR-02 | Phase 2 | Complete |
| BAR-03 | Phase 2 | Complete |
| BAR-04 | Phase 2 | Complete |
| BAR-05 | Phase 3 | Complete |
| BAR-06 | Phase 3 | Complete |
| BAR-07 | Phase 3 | Complete |
| BAR-08 | Phase 3 | Complete |
| IPC-01 | Phase 4 | Complete |
| IPC-02 | Phase 4 | Pending |
| IPC-03 | Phase 4 | Pending |

**Coverage:**

- v1 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-20*
*Last updated: 2026-07-20 after initial definition*
