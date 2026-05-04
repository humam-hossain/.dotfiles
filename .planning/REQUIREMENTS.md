# Requirements: v1.2 Waybar → Quickshell Migration

**Milestone:** v1.2
**Project:** Cross-Platform Dotfiles
**Created:** 2026-05-02

---

## v1.2 Requirements

### BAR — Bar Core

- [ ] **BAR-01**: Quickshell bar renders at top of screen on Hyprland startup with exclusive zone (tiling windows do not overlap the bar)
- [ ] **BAR-02**: One bar instance per monitor — Variants + Quickshell.screens; bars added/removed dynamically when monitors connect/disconnect
- [ ] **BAR-03**: Bar has left/center/right BarGroup layout matching current waybar section split
- [ ] **BAR-04**: Catppuccin Mocha theme: Colours.qml pragma Singleton with all 26 canonical hex values plus semantic aliases; pill-shaped modules (border-radius); JetBrainsMono Nerd Font
- [ ] **BAR-05**: `arch/quickshell.sh` install script — installs `quickshell`, `ddcutil`, `i2c-tools` via pacman; adds user to `i2c` group; loads `i2c-dev` module; adds persistence entry in `/etc/modules-load.d/`
- [ ] **BAR-06**: Waybar config remains untouched and functional in parallel during development; cutover is explicit and manual

### WS — Workspaces

- [x] **WS-01**: Workspaces widget shows all Hyprland workspaces using `Quickshell.Hyprland` module (`Hyprland.workspaces` ObjectModel) — reactive, not raw IPC socket
- [x] **WS-02**: Active workspace highlighted in Catppuccin Mauve; occupied workspaces visually distinct from empty; urgent workspace has distinct indicator
- [x] **WS-03**: Click workspace activates it via `workspace.activate()`; scroll cycles workspaces via `HyprlandIpc.dispatch`

### AUDIO — Audio & Media

- [x] **AUDIO-01**: Volume widget shows PipeWire default sink volume percentage and mute state via `Quickshell.Services.Pipewire` (`PwObjectTracker` bound before reading `.audio`); click opens pavucontrol
- [ ] **AUDIO-02**: Volume OSD auto-hide overlay (standalone `PanelWindow` at `WlrLayer.Overlay`) appears when default sink volume changes; auto-hides after 1.5s via `Timer`; shows pill progress bar with current volume
- [x] **AUDIO-03**: Music widget shows MPRIS current artist and title via `Quickshell.Services.Mpris`; click toggles play/pause; hidden when no player active

### TRAY — Tray & Notifications

- [x] **TRAY-01**: System tray renders SNI application indicators via `Quickshell.Services.SystemTray`; icons load correctly; right-click opens context menu
- [ ] **TRAY-02**: Notification count badge reflects swaync unread count via `swaync-client -c`; updates on a 5-second timer
- [ ] **TRAY-03**: Click notification badge toggles swaync panel via `swaync-client -t`

### SYS — System Monitor

- [ ] **SYS-01**: CPU widget shows current usage percentage; warning color at ≥50%, critical color at ≥90%
- [ ] **SYS-02**: Memory widget shows used/total via reused `scripts/memory.sh` (existing Waybar script); tooltip with breakdown
- [ ] **SYS-03**: Disk widget shows free/total storage for root filesystem
- [ ] **SYS-04**: Network widget shows WiFi SSID or ethernet interface name; disconnected state; click opens nmtui in kitty terminal

### CUST — Custom Widgets

- [ ] **CUST-01**: Ping widget fetches from `http://localhost:8765/api/status` via reused `scripts/network/ping_status.sh`; colored by status class (good/medium/bad/critical/dead); click opens `http://localhost:8765/`
- [ ] **CUST-02**: Weather current widget via reused `scripts/weather/curr_weather.sh`; 200s poll interval; tooltip with detail
- [ ] **CUST-03**: Weather forecast widget via reused `scripts/weather/forcast_weather.sh`; 200s poll interval; tooltip with forecast
- [ ] **CUST-04**: Clock widget shows current time in Asia/Dhaka timezone; date format matching current waybar format; updates every second

### CTRL — Controls

- [ ] **CTRL-01**: Backlight widget shows external monitor brightness via `ddcutil getvcp 10`; 30s poll; click-to-adjust with 300ms debounced write via `ddcutil setvcp 10`
- [ ] **CTRL-02**: Lock button triggers `hyprlock` via `Process.startDetached()`
- [ ] **CTRL-03**: Power button triggers `wlogout` via `Process.startDetached()`

### POPUP — Popup Panels

- [ ] **POPUP-01**: Calendar popup opens on clock click via `PopupWindow` anchored to clock widget; month grid (7-column Repeater) with today highlighted; month navigation; outside-click dismiss via `HyprlandFocusGrab` (not `grabFocus: true`)
- [ ] **POPUP-02**: Network panel opens on network widget click; shows available networks and current IP via nmcli via `Process`; outside-click dismiss via `HyprlandFocusGrab`
- [ ] **POPUP-03**: Notification center toggle: click notification widget calls `swaync-client -t` to open/close swaync's native panel

### ANIM — Animations

- [ ] **ANIM-01**: Module hover color transitions — `Behavior on color { ColorAnimation { duration: 120 } }` on all interactive bar modules
- [ ] **ANIM-02**: Popup open/close fade — `Behavior on opacity { NumberAnimation { duration: 150 } }` on popup panels; `visible: false` (not opacity 0) to fully remove from input tree

---

## Future Requirements

- Native QML notification center (requires removing swaync — D-Bus conflict; separate milestone)
- Bluetooth widget (not in current Waybar config)
- Application launcher popup
- Battery widget (laptop support — not needed for desktop)
- CI-based multi-OS validation (AUTO-01, AUTO-02 — deferred from v1.1)
- Machine-role optional plugin profiles (PROF-01 — deferred from v1.1)

---

## Out of Scope

- Replacing swaync as notification daemon in v1.2 — `NotificationServer` conflicts on D-Bus; migration is a separate project
- Windows support for Quickshell — Wayland/Linux only
- Bluetooth / battery widgets — not in current Waybar config
- Neovim tech debt cleanup — deferred items from v1.1 carry forward separately

---

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| BAR-01 | Phase 12 | Pending |
| BAR-02 | Phase 12 | Pending |
| BAR-03 | Phase 12 | Pending |
| BAR-04 | Phase 12 | Pending |
| BAR-05 | Phase 12 | Pending |
| BAR-06 | Phase 12 | Pending |
| WS-01 | Phase 13 | Complete |
| WS-02 | Phase 13 | Complete |
| WS-03 | Phase 13 | Complete |
| AUDIO-01 | Phase 13 | Complete |
| AUDIO-03 | Phase 13 | Complete |
| TRAY-01 | Phase 13 | Complete |
| SYS-01 | Phase 14 | Pending |
| SYS-02 | Phase 14 | Pending |
| SYS-03 | Phase 14 | Pending |
| SYS-04 | Phase 14 | Pending |
| CUST-01 | Phase 14 | Pending |
| CUST-02 | Phase 14 | Pending |
| CUST-03 | Phase 14 | Pending |
| CUST-04 | Phase 14 | Pending |
| CTRL-01 | Phase 14 | Pending |
| CTRL-02 | Phase 14 | Pending |
| CTRL-03 | Phase 14 | Pending |
| AUDIO-02 | Phase 14 | Pending |
| TRAY-02 | Phase 14 | Pending |
| TRAY-03 | Phase 14 | Pending |
| POPUP-01 | Phase 15 | Pending |
| POPUP-02 | Phase 15 | Pending |
| POPUP-03 | Phase 15 | Pending |
| ANIM-01 | Phase 16 | Pending |
| ANIM-02 | Phase 16 | Pending |

---
*Last updated: 2026-05-02 — v1.2 roadmap created; traceability table populated*
