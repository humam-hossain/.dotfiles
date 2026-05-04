# Roadmap: Cross-Platform Neovim Dotfiles

## Milestones

- ✅ **v1.0 Neovim Modernization** — shipped 2026-04-15
- ✅ **v1.1 Neovim Setup Bug Fixes** — shipped 2026-04-25
- 🔄 **v1.2 Waybar → Quickshell Migration** — in progress

## Phases

<details>
<summary>✅ v1.0 Neovim Modernization (Phases 1-5) — SHIPPED 2026-04-15</summary>

- [x] Phase 1: Reliability and Portability Baseline
- [x] Phase 2: Central Command and Keymap Architecture
- [x] Phase 3: Plugin Audit and Validation Harness
- [x] Phase 4: Tooling and Ecosystem Modernization
- [x] Phase 5: UX and Performance Polish

</details>

<details>
<summary>✅ v1.1 Neovim Setup Bug Fixes (Phases 6-11) — SHIPPED 2026-04-25</summary>

- [x] Phase 6: Runtime Failure Inventory and Reproduction (2/2 plans) — completed 2026-04-18
- [x] Phase 7: Keymap Reliability Fixes (2/2 plans) — completed 2026-04-21
- [x] Phase 8: Plugin Runtime Hardening (3/3 plans) — completed 2026-04-22
- [x] Phase 9: Health Signal Cleanup (2/2 plans) — completed 2026-04-23
- [x] Phase 10: Validation Harness Expansion (4/4 plans) — completed 2026-04-23
- [x] Phase 11: Milestone Verification and Rollout Confidence (2/2 plans) — completed 2026-04-24

</details>

<details open>
<summary>🔄 v1.2 Waybar → Quickshell Migration (Phases 12-16) — IN PROGRESS</summary>

- [ ] **Phase 12: Bar Skeleton and Theme** — visible PanelWindow with Colours.qml, pill layout, multi-monitor, install script, Waybar parallel deploy
- [ ] **Phase 13: Native API Widgets** — workspaces, volume, media, system tray; zero shell scripts; validates Hyprland/PipeWire/MPRIS/SystemTray APIs
- [ ] **Phase 14: Script-Backed Widgets** — full Waybar widget parity via existing scripts; CPU, memory, disk, network, ping, weather, clock, backlight, notifications, lock, power
- [ ] **Phase 15: Popup Panels** — calendar, network panel, volume OSD, notification center toggle
- [ ] **Phase 16: Animation Polish and Cutover** — Behavior blocks on all interactive modules and popups; pre-switch verification; Waybar disabled

</details>

## Phase Details

### Phase 12: Bar Skeleton and Theme
**Goal**: A visible, correctly themed bar docks at the top of all screens on Hyprland startup, Waybar continues to run in parallel
**Depends on**: Nothing (first v1.2 phase)
**Requirements**: BAR-01, BAR-02, BAR-03, BAR-04, BAR-05, BAR-06
**Success Criteria** (what must be TRUE):
  1. Running `quickshell` launches a bar pinned to the top of each connected monitor with exclusive zone — tiling windows do not overlap it
  2. On a dual-monitor setup, a second monitor connecting or disconnecting adds or removes its bar without restarting Quickshell
  3. The bar renders left/center/right sections with pill-shaped module containers in Catppuccin Mocha colors (Base background, Mauve accent) using JetBrainsMono Nerd Font
  4. `arch/quickshell.sh` runs to completion, installs quickshell/ddcutil/i2c-tools, adds user to i2c group, and persists i2c-dev in /etc/modules-load.d/
  5. Waybar continues to render and function normally alongside the running Quickshell bar
**Plans:** 2 plans
Plans:
- [ ] 12-01-PLAN.md — Theme singleton, shared QML components (BarGroup, ModulePill), shell/Bar/BarContent with three-section pill layout (BAR-01, BAR-02, BAR-03, BAR-04, BAR-06)
- [ ] 12-02-PLAN.md — `arch/quickshell.sh` install script: pacman packages, i2c kernel module + group, config symlink (BAR-05)
**UI hint**: yes

### Phase 13: Native API Widgets
**Goal**: Workspaces, volume, media, and system tray widgets are live with real Hyprland/PipeWire/MPRIS/SystemTray data — no shell scripts involved
**Depends on**: Phase 12
**Requirements**: WS-01, WS-02, WS-03, AUDIO-01, AUDIO-03, TRAY-01
**Success Criteria** (what must be TRUE):
  1. The workspaces widget shows all current Hyprland workspaces reactively; clicking a workspace activates it; scrolling cycles through workspaces; the active workspace is highlighted in Catppuccin Mauve; occupied workspaces are visually distinct from empty ones; urgent workspaces have a distinct indicator
  2. The volume widget shows the current PipeWire default sink volume percentage and mute state without any shell script; clicking it opens pavucontrol
  3. The music widget shows the current MPRIS player's artist and title; clicking toggles play/pause; the widget is hidden when no player is active
  4. The system tray renders SNI application icons; right-clicking an icon opens its context menu
**Plans:** 3/3 plans complete
Plans:
- [x] 13-01-PLAN.md — Service singletons: AudioService, MprisService, HyprWorkspaces (WS-01 data, AUDIO-01 data, AUDIO-03 data)
- [x] 13-02-PLAN.md — WorkspacesWidget + VolumeWidget; widgets/qmldir registers all 4 widget types (WS-01, WS-02, WS-03, AUDIO-01)
- [x] 13-03-PLAN.md — MusicWidget + TrayWidget; wire BarContent.qml to import qs.widgets per D-56 layout (AUDIO-03, TRAY-01)
**UI hint**: yes

### Phase 14: Script-Backed Widgets
**Goal**: Every widget from the current Waybar config is present and live in the Quickshell bar — full widget parity achieved
**Depends on**: Phase 13
**Requirements**: SYS-01, SYS-02, SYS-03, SYS-04, CUST-01, CUST-02, CUST-03, CUST-04, CTRL-01, CTRL-02, CTRL-03, AUDIO-02, TRAY-02, TRAY-03
**Success Criteria** (what must be TRUE):
  1. CPU, memory, disk, and network widgets display live values; CPU and memory change color at warning (≥50%) and critical (≥90%) thresholds; clicking the network widget opens nmtui in a kitty terminal
  2. Ping, weather (current), weather (forecast), and clock widgets are live; each uses its existing Waybar script via Process with correct polling intervals; the clock shows Asia/Dhaka time and updates every second
  3. Backlight widget shows current external monitor brightness; the value updates every 30 seconds; clicks adjust brightness with a 300 ms debounced ddcutil write
  4. Lock and power buttons invoke hyprlock and wlogout respectively via Process.startDetached()
  5. The volume OSD overlay appears when the default sink volume changes, shows a pill progress bar with current volume, and auto-hides after 1.5 seconds
  6. The notification count badge reflects swaync unread count (updated every 5 seconds); clicking the badge toggles the swaync panel
**Plans**: TBD
**UI hint**: yes

### Phase 15: Popup Panels
**Goal**: Calendar, network panel, and notification center popups open from their trigger widgets, display correct data, and dismiss cleanly on outside click
**Depends on**: Phase 14
**Requirements**: POPUP-01, POPUP-02, POPUP-03
**Success Criteria** (what must be TRUE):
  1. Clicking the clock widget opens a calendar popup anchored near the clock; the popup shows the current month in a 7-column grid with today highlighted; prev/next month navigation works; clicking anywhere outside the popup closes it without stealing keyboard focus from the active application
  2. Clicking the network widget opens a network panel showing available networks and the current IP; clicking outside dismisses it without stealing keyboard focus
  3. Clicking the notification count widget opens and closes the swaync native notification panel
**Plans**: TBD
**UI hint**: yes

### Phase 16: Animation Polish and Cutover
**Goal**: All interactive bar modules and popups have smooth transitions; the bar passes a full pre-switch verification checklist and Waybar is disabled
**Depends on**: Phase 15
**Requirements**: ANIM-01, ANIM-02
**Success Criteria** (what must be TRUE):
  1. Hovering over any interactive bar module produces a smooth color transition (120 ms) rather than an instant color jump
  2. Opening and closing any popup panel fades in/out (150 ms); closed popups are fully removed from the input tree (not hidden with opacity) so no invisible hit areas intercept mouse clicks
  3. All 31 v1.2 requirements are verified against the running bar and documented in the cutover checklist; Waybar is disabled and the Quickshell bar is the sole active bar
**Plans**: TBD
**UI hint**: yes

---

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Reliability and Portability Baseline | v1.0 | — | ✅ Complete | 2026-04-15 |
| 2. Central Command and Keymap Architecture | v1.0 | — | ✅ Complete | 2026-04-15 |
| 3. Plugin Audit and Validation Harness | v1.0 | — | ✅ Complete | 2026-04-15 |
| 4. Tooling and Ecosystem Modernization | v1.0 | — | ✅ Complete | 2026-04-15 |
| 5. UX and Performance Polish | v1.0 | — | ✅ Complete | 2026-04-15 |
| 6. Runtime Failure Inventory and Reproduction | v1.1 | 2/2 | ✅ Complete | 2026-04-18 |
| 7. Keymap Reliability Fixes | v1.1 | 2/2 | ✅ Complete | 2026-04-21 |
| 8. Plugin Runtime Hardening | v1.1 | 3/3 | ✅ Complete | 2026-04-22 |
| 9. Health Signal Cleanup | v1.1 | 2/2 | ✅ Complete | 2026-04-23 |
| 10. Validation Harness Expansion | v1.1 | 4/4 | ✅ Complete | 2026-04-23 |
| 11. Milestone Verification and Rollout Confidence | v1.1 | 2/2 | ✅ Complete | 2026-04-24 |
| 12. Bar Skeleton and Theme | v1.2 | 0/2 | Not started | — |
| 13. Native API Widgets | v1.2 | 3/3 | Complete   | 2026-05-04 |
| 14. Script-Backed Widgets | v1.2 | 0/? | Not started | — |
| 15. Popup Panels | v1.2 | 0/? | Not started | — |
| 16. Animation Polish and Cutover | v1.2 | 0/? | Not started | — |
