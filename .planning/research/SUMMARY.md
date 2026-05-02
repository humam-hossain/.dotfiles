# Project Research Summary

**Project:** Cross-Platform Dotfiles — Waybar to Quickshell Migration
**Domain:** QML-based Wayland status bar for Hyprland (Arch Linux)
**Milestone:** v1.2
**Researched:** 2026-05-02
**Confidence:** HIGH

---

## Executive Summary

Quickshell is the correct tool for a native Hyprland bar on Arch. It ships in `[extra]` (0.2.1-6) with all required modules compiled in — Hyprland IPC, PipeWire, MPRIS, system tray, and networking — eliminating the shell-script layer that Waybar modules relied on for those data sources. The migration strategy is additive: the existing `.config/waybar/` tree remains untouched and fully functional in parallel while the Quickshell config is built incrementally under `.config/quickshell/`. A flag-day cutover only happens after all widgets are verified.

The architecture centers on a strict separation between `services/` (pragma Singleton QML files that own data) and `widgets/` (stateless visual components that bind to services). Seven native integrations — workspaces, volume, MPRIS, system tray, network state, clock, and disk/CPU reads — replace their Waybar equivalents with direct QML API calls. Five existing bash scripts (ping, weather x2, memory, backlight via ddcutil) are reused unchanged via the `Process + StdioCollector + Timer` pattern. Widget parity with Waybar is achievable before any new-feature work begins.

The primary risks cluster around two areas: D-Bus conflicts and input-event traps. Quickshell's `NotificationServer` and swaync both claim `org.freedesktop.Notifications` — instantiating `NotificationServer` silently breaks all notifications. Popup visibility managed with `opacity: 0` instead of `visible: false` leaves invisible hit-areas that eat mouse clicks. Both are silent failures with no compile-time error. The mitigation is established in ARCHITECTURE.md: use `PopupWindow` (not a second `PanelWindow`), `HyprlandFocusGrab` (not `grabFocus: true`), and `visible: false` (not `opacity: 0`). Follow those three rules and the risk profile is low.

---

## Key Findings

### Stack Additions

Three new packages; all in `[extra]`, no AUR required.

| Package | Purpose |
|---------|---------|
| `quickshell` | QML shell framework — includes all required modules |
| `ddcutil` | External monitor brightness via DDC/CI |
| `i2c-tools` | i2c bus access for ddcutil |

The install script (`arch/quickshell.sh`) must do more than `pacman -S`: it must `modprobe i2c-dev`, add the user to the `i2c` group, and add `i2c-dev` to `/etc/modules-load.d/` for persistence. These cannot be deferred to runtime — ddcutil fails silently without them (P-13).

**Native QML integrations (no script needed):**
- `Quickshell.Hyprland` — workspaces model, focused client title, IPC dispatch
- `Quickshell.Services.Pipewire` — default audio sink volume/mute (`PwObjectTracker` binding required first)
- `Quickshell.Services.Mpris` — media players over D-Bus (replaces `playerctl`)
- `Quickshell.Services.SystemTray` — tray items model (replaces Waybar `tray` module)
- `Quickshell.Networking` — NetworkManager backend
- Qt built-in — `Qt.formatDateTime(new Date(), ...)` for clock

**Script-backed via `Process + StdioCollector + Timer`:**
- `ping_status.sh` — 5 s interval
- `curr_weather.sh` — 200 s interval
- `forcast_weather.sh` — 200 s interval
- `memory.sh` — 5 s interval
- `ddcutil getvcp 10` — 5 s poll read, 300 ms debounce on write

**Critical:** `Process.command` does not expand `~` or `$HOME`. Use `["bash", "-c", "$HOME/.config/waybar/scripts/..."]` for all script paths (P-06).

---

### Feature Table Stakes

Must-have — missing any of these means the bar feels broken as a Waybar replacement.

| Widget | Implementation | Complexity |
|--------|---------------|------------|
| PanelWindow docked top, exclusive zone | `PanelWindow { anchors { top; left; right }; exclusiveZone: height }` | Low |
| Multi-monitor (one bar per screen) | `Variants { model: Quickshell.screens }` | Medium |
| Hyprland workspaces | `Hyprland.workspaces` ObjectModel; `ws.activate()` on click | Medium |
| Clock (Asia/Dhaka, 1 s) | `Timer { interval: 1000 }` + `Qt.formatDateTime` | Low |
| CPU / memory / disk | Process + Timer; reuse scripts or `/proc/stat` + `df -h` | Medium |
| Volume (PipeWire) | `Pipewire.defaultAudioSink.audio.volume` + PwObjectTracker | Low |
| MPRIS media | `Mpris.players` model — native, no playerctl | Low |
| System tray | `SystemTray.items` model | Medium |
| Ping monitor | Reuse `ping_status.sh` via Process; parse JSON output | Low |
| Weather x2 | Reuse `curr_weather.sh` / `forcast_weather.sh` via Process | Low |
| Notification count (swaync) | `Process { command: ["swaync-client", "-c"] }` + 5 s timer | Low |
| Popup dismiss on outside click | `HyprlandFocusGrab { windows: [popup]; active: popup.visible }` | Medium |

**Should-have (differentiators for v1.2):**
- Volume OSD (auto-hide after 1.5 s) — `PanelWindow` at `WlrLayer.Overlay`, scroll-triggered
- Calendar popup on clock click — custom `Grid { columns: 7 }` + JS Date math (~200 LOC)
- Network panel (SSID list, IP info) — `nmcli -t` via Process in a PopupWindow
- Notification center toggle — `swaync-client -t` on click, one line
- Workspace occupied/urgent dot rendering — `.toplevels.length`, `.urgent`, `.focused` state
- Smooth open/close animations — `Behavior on opacity { NumberAnimation { duration: 150 } }`
- Module hover color transitions — `Behavior on color { ColorAnimation { duration: 120 } }`
- Backlight slider (ddcutil) — debounced write at 300 ms, 30 s poll read

**Explicitly out of scope for v1.2:**
- Native QML notification center (D-Bus conflict with swaync — separate milestone)
- Replace swaync as notification daemon
- Bluetooth widget (not in existing Waybar config)
- CPU/memory polling interval < 1 s

---

### Architecture Approach

The QML tree follows a service/widget split enforced by directory structure. `services/` holds `pragma Singleton` QML files that own data sources (timers, Process instances, native API bindings) and expose clean properties. `widgets/` holds stateless visual components that bind to those properties. `popups/` holds `PopupWindow` components. `theme/Colours.qml` is a `pragma Singleton` with all Catppuccin Mocha constants plus semantic aliases that map directly to the existing Waybar widget color assignments.

**Directory layout:**
```
.config/quickshell/
├── shell.qml
├── Bar.qml
├── BarContent.qml
├── BarGroup.qml
├── theme/
│   └── Colours.qml          # pragma Singleton; all Catppuccin Mocha hex constants
├── services/                 # pragma Singleton; data only, no UI
│   ├── Clock.qml
│   ├── PingStatus.qml
│   ├── Weather.qml
│   ├── Forecast.qml
│   ├── MemoryStats.qml
│   ├── AudioService.qml
│   └── HyprWorkspaces.qml
├── widgets/                  # stateless visual; bind to services or inline Process
│   └── (16 widget files)
└── popups/
    ├── CalendarPopup.qml
    ├── WeatherPopup.qml
    ├── VolumeOsd.qml
    └── NetworkPopup.qml
```

**Key patterns to follow:**

- **Colours singleton:** `pragma Singleton` QtObject referenced by name with no import statement. `surface0` override is `#000000` (not canonical `#313244`) — preserve to match existing Waybar screenshots.
- **PopupWindow vs PanelWindow:** `PanelWindow` only for the bar itself. All popups use `PopupWindow` with `WlrLayershell.layer: WlrLayer.Overlay`. A second `PanelWindow` with `exclusiveZone` shifts Hyprland tiling.
- **Process pattern:** `Timer { triggeredOnStart: true; onTriggered: proc.running = true }` + `Process { stdout: StdioCollector { onStreamFinished: { /* parse JSON */ } } }`. One-shot scripts use `StdioCollector`; long-running streaming processes (e.g. `swaync-client -sw`) must use `StdioLineParser` + `onLine`.
- **Multi-monitor:** `Variants { model: Quickshell.screens }` creates one `PanelWindow` per screen automatically. Popup windows must anchor to their own screen's panel window id.
- **PwObjectTracker prerequisite:** Must bind `PwObjectTracker { objects: [Pipewire.defaultAudioSink] }` before reading `.audio.volume` — omitting it gives null properties with no error.
- **Keyboard focus:** `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None` on the bar PanelWindow is mandatory — bar must not steal keyboard focus.

---

### Watch Out For

Top pitfalls ranked by risk. The top 6 are HIGH — all have silent failure modes.

| # | Pitfall | Risk | Prevention |
|---|---------|------|------------|
| P-02 | `NotificationServer` conflicts with swaync on `org.freedesktop.Notifications` D-Bus | HIGH | Never instantiate `NotificationServer`; use `swaync-client` shell calls only |
| P-01 | `grabFocus: true` on interactive popup steals keyboard from active app | HIGH | Use `HyprlandFocusGrab { windows: [popup]; active: popup.visible }` |
| P-03 | `opacity: 0` hidden popup still intercepts mouse input | HIGH | Always `visible: false`; never hide with opacity alone |
| P-04 | Skipping `PwObjectTracker` binding causes PipeWire `.audio` properties to be null | HIGH | Bind tracker before any volume property reads |
| P-05 | ddcutil every 5 s saturates I2C bus (~300 ms/call) | HIGH | Poll read at 30 s; debounce slider writes at 300 ms |
| P-06 | `Process.command` does not expand `~` or `$HOME` | HIGH | Wrap: `["bash", "-c", "$HOME/.config/waybar/scripts/..."]` |
| P-07 | Waybar + Quickshell fight for exclusive zone during parallel deploy | MEDIUM | Both can coexist (different process, same edge); verify on target machine before cutover |
| P-08 | QML binding loop on volume/backlight slider | MEDIUM | Separate display state (bound) from user-input state (explicit set) |
| P-11 | `StdioCollector` buffers full output — streaming process (`swaync-client -sw`) hangs | MEDIUM | Use `StdioLineParser` + `onLine` for streaming; `StdioCollector` only for one-shot |
| P-16 | Missing `WlrKeyboardFocus.None` on bar PanelWindow steals keyboard focus | LOW | Set unconditionally on the bar PanelWindow |

---

## Implications for Roadmap

Research is unanimous on build order: get a visible, themed bar on screen first; validate native APIs next; add script-backed widgets to reach parity; popups after; polish last. Popup and animation phases cannot be tested until the bar renders and IPC is confirmed live.

### Phase 1: Bar Skeleton + Theme

**Rationale:** Every subsequent phase needs a visible surface to render into. Establishing `Colours.qml` here prevents color magic-string proliferation across all widget files written later.
**Delivers:** Blank themed bar docked at the top of all screens; correct background, pill containers, font, exclusive zone confirmed working.
**Implements:** `shell.qml`, `Bar.qml`, `BarContent.qml`, `BarGroup.qml`, `theme/Colours.qml`, `arch/quickshell.sh`
**Avoids:** P-07 (parallel deploy — Waybar still running), P-16 (set `WlrKeyboardFocus.None` from day one)
**Research flag:** Standard pattern — no phase research needed.

### Phase 2: Native API Widgets

**Rationale:** Native integrations have zero external dependencies beyond Quickshell itself. Validating them first confirms IPC, D-Bus, and PipeWire bindings work before introducing script complexity.
**Delivers:** Workspaces, clock, system tray, volume indicator, media widget — all live with real data.
**Implements:** `WorkspacesWidget`, `ClockWidget`, `SysTrayWidget`, `VolumeWidget`, `MediaWidget`; `services/AudioService.qml` with PwObjectTracker
**Avoids:** P-04 (PwObjectTracker must bind before volume reads), P-09 (use `Quickshell.Hyprland`, not raw IPC socket)
**Research flag:** Standard pattern — no phase research needed.

### Phase 3: Script-Backed Widgets (Waybar Parity)

**Rationale:** All five existing scripts are reused unchanged. This phase reaches full widget parity with the current Waybar config and constitutes the minimum viable bar.
**Delivers:** Ping, memory, weather x2, disk, CPU, network, backlight, notification count all live; bar is functionally equivalent to Waybar.
**Implements:** All `services/*.qml` singletons; `PingWidget`, `MemoryWidget`, `WeatherWidget`, `ForecastWidget`, `DiskWidget`, `CpuWidget`, `NetworkWidget`, `BacklightWidget`, `NotificationWidget`, `LockWidget`, `PowerWidget`
**Avoids:** P-06 (bash wrapper for `$HOME` expansion), P-05 (ddcutil polling rate), P-13 (i2c group/module in install script), P-11 (StdioLineParser for swaync streaming)
**Research flag:** Standard pattern — script reuse is fully specified.

### Phase 4: Popup Panels

**Rationale:** Popups depend on working widgets (clock must exist before calendar popup is useful). All four use the same `PopupWindow + HyprlandFocusGrab` pattern.
**Delivers:** Calendar popup, weather detail popup, volume OSD, network panel.
**Implements:** `popups/CalendarPopup.qml`, `popups/WeatherPopup.qml`, `popups/VolumeOsd.qml`, `popups/NetworkPopup.qml`
**Avoids:** P-01 (HyprlandFocusGrab), P-03 (visible: false), P-02 (no NotificationServer)
**Research flag:** Calendar JS date math and network panel nmcli parsing are the two areas with room for error — consider a focused research spike before implementation.

### Phase 5: Animation Polish + Cutover Verification

**Rationale:** `Behavior` blocks are a non-destructive final layer applied to finished components. Animation before stability obscures bugs.
**Delivers:** Hover color transitions, popup open/close animations, volume OSD pill; then full 15-item pre-switch verification checklist pass, README updated, Waybar disabled.
**Implements:** `Behavior on color`, `Behavior on opacity`, `NumberAnimation` across all widgets and popups
**Avoids:** P-14 (JS in hot paths causes GC stutter — keep animations in QML properties), P-15 (screen add/remove cleanup in `Component.onDestruction`)
**Research flag:** Standard pattern.

### Phase Ordering Rationale

- Phase 1 before everything: QML components cannot render without a PanelWindow host and a valid theme singleton.
- Phase 2 before Phase 3: Native API validation catches Quickshell installation/version issues before the Process pattern is used at scale.
- Phase 3 before Phase 4: PopupWindow anchors target specific widget items — anchor targets must exist first.
- Phase 4 before Phase 5: Animating something that is not yet working wastes time and obscures bugs.
- Parallel deploy (Waybar running throughout Phases 1–4) is the explicit mitigation for P-07 — Quickshell is verified live before Waybar is disabled.

### Research Flags

Phases needing deeper research during planning:
- **Phase 4 (Popups):** Calendar date math (~200 LOC, JS `new Date` weekday offset) and network panel nmcli output parsing are fiddly. Recommend a focused research spike before calendar and network popup implementation.

Phases with standard patterns (skip research-phase):
- **Phase 1:** `PanelWindow` skeleton is trivially documented in Quickshell official docs.
- **Phase 2:** All native APIs are covered in detail in ARCHITECTURE.md and STACK.md.
- **Phase 3:** Script reuse via Process is fully specified; polling intervals match existing Waybar config.
- **Phase 5:** QML `Behavior` blocks are idiomatic and well-documented.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified against Quickshell official docs via Context7; repo scripts read directly |
| Features | HIGH | Derived from existing Waybar config.jsonc read directly; Quickshell widget patterns from official docs |
| Architecture | HIGH | Directory layout and patterns from Quickshell docs + quickshell-examples; repo structure read directly |
| Pitfalls | HIGH | Official docs warnings + known Wayland/QML interaction patterns; all HIGH-risk pitfalls have confirmed sources |

**Overall confidence:** HIGH

### Gaps to Address

- **ddcutil debounce threshold:** 300 ms is the recommended minimum per call. Whether the backlight slider UX feels responsive at that rate needs hands-on testing — may need tuning up to 500 ms.
- **SNI tray icon fallback (P-12):** `icon.name` vs `icon.image` fallback logic must be validated against the actual tray apps in use (network manager applet, clipboard manager, etc.).
- **Calendar popup scope:** ~200 LOC estimate assumes no week-number display or prev/next month navigation. Clarify desired scope before Phase 4 begins.
- **`surface0` override in mocha.css:** Repo sets `surface0: #000000`. Confirm no other palette overrides exist in `mocha.css` before porting the full palette to `Colours.qml`.

---

## Sources

### Primary (HIGH confidence)
- Quickshell official documentation (Context7 `/websites/quickshell_master`) — all QML APIs: Process/StdioCollector/StdioLineParser, PanelWindow/PopupWindow, HyprlandFocusGrab, WlrLayershell, Variants, Pipewire, Mpris, SystemTray, Hyprland module
- `.config/waybar/config.jsonc` (read directly from repo) — existing widget list, polling intervals, script names
- `.config/waybar/scripts/` (read directly from repo) — script output formats; confirmed JSON stdout for all five reused scripts
- `mocha.css` (read directly from repo) — Catppuccin Mocha hex values including `surface0: #000000` override

### Secondary (MEDIUM confidence)
- quickshell-examples repository patterns — Volume OSD pattern (`PanelWindow` at `WlrLayer.Overlay`), LazyLoader usage recommendations
- Arch Linux `[extra]` package metadata for `quickshell` 0.2.1-6 — confirmed no AUR dependency

### Tertiary (LOW confidence / needs runtime validation)
- ddcutil 300 ms per-call estimate — from ddcutil documentation; actual timing on target hardware may differ
- i2c group membership requirement — from ddcutil Arch wiki notes; needs verification on target machine at install time

---
*Research completed: 2026-05-02*
*Ready for roadmap: yes*
