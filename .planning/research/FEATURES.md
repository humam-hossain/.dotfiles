# Feature Landscape: Quickshell/QML Hyprland Bar (v1.2)

**Domain:** QML-based Wayland status bar for Hyprland
**Researched:** 2026-05-02
**Replaces:** stale v1.1 Neovim research

---

## Table Stakes

Features users expect from a QML bar replacing Waybar. Missing = feels broken.

| Feature | Why Expected | Complexity | Quickshell Notes |
|---------|--------------|------------|-----------------|
| PanelWindow docked to top | Bar must reserve exclusive zone so windows don't overlap | Low | `PanelWindow { anchors { top:true; left:true; right:true }; exclusiveZone: height }` |
| Multi-monitor support | One bar instance per screen | Medium | `Variants { model: Quickshell.screens }` with `screen: modelData` |
| Hyprland workspaces | Core reason to use Quickshell for Hyprland | Medium | `Hyprland.workspaces` ObjectModel — reactive, no raw IPC |
| Clock (Asia/Dhaka, 1s) | Basic bar requirement | Low | `Timer { interval: 1000 }` + JS `Date` with timezone |
| CPU / memory / disk / network | Every Waybar user expects these | Medium | `Process` + `StdioCollector` + `Timer` — reuse existing scripts |
| Music (MPRIS) | Expected on desktop bars | Low | `Quickshell.Services.Mpris` — native, no playerctl |
| Volume (PipeWire) | Expected on desktop bars | Low | `Quickshell.Services.Pipewire` — native, `PwObjectTracker` required first |
| System tray | Many apps require tray | Medium | `Quickshell.Services.SystemTray` — native |
| Notification count (swaync) | Existing Waybar feature | Low | `Process { command: ["swaync-client", "-c"] }` + 5s timer |
| Ping monitor | Existing Waybar feature | Low | Reuse `ping_status.sh` via `Process`; parse JSON |
| Weather ×2 | Existing Waybar feature | Low | Reuse `curr_weather.sh` / `forcast_weather.sh` via `Process` |
| Popup dismiss on outside click | Popups that can't close are unusable | Medium | `HyprlandFocusGrab` — NOT `grabFocus: true` (steals keyboard) |

---

## Differentiators

What makes a polished QML bar stand apart from a Waybar port.

| Feature | Value | Complexity | Notes |
|---------|-------|------------|-------|
| Calendar popup (clock click) | Real interactive panel vs Waybar tooltip | High | Custom `Grid { columns: 7 }` + JS `Date` math. ~200 LOC. No native Qt Quick calendar. |
| Volume OSD (auto-hide) | Visual scroll feedback — Waybar has none | Medium | Separate `PanelWindow` at `WlrLayer.Overlay`; watch `Pipewire.defaultAudioSink.audio.volume`; `Timer { interval: 1500 }` to auto-hide |
| Network panel (click) | SSID list + IP info in a real panel | High | `nmcli -t` via `Process`, `ListView` in panel |
| Notification center (swaync toggle) | Full history via swaync panel | Low | `swaync-client -t` on click — one line |
| Workspace occupied/urgent dots | Richer state than icon-only | Low | `.toplevels.length > 0`, `.urgent`, `.focused` — colored dot rendering |
| Smooth animations | QML's native differentiator over CSS bars | Medium | `Behavior on opacity { NumberAnimation { duration: 150 } }` — popups, hover, width changes |
| Module hover transitions | Defines "polished" feel | Low | `Behavior on color { ColorAnimation { duration: 120 } }` |
| Backlight slider (ddcutil) | ddcutil needs debounce (300ms per call) | High | Debounce write via `Timer { interval: 300 }`; poll read at 30s |

---

## Anti-Features (Explicitly Out of Scope for v1.2)

| Anti-Feature | Why Avoid | Instead |
|--------------|-----------|---------|
| Raw Hyprland IPC socket for workspaces | `Quickshell.Hyprland` already wraps it reactively | Use `Hyprland.workspaces` model |
| Replace swaync as notification daemon | `NotificationServer` conflicts on D-Bus — separate milestone | Toggle swaync panel with `swaync-client -t` |
| CPU/memory polling < 1s | Binding churn, unnecessary load | Interval >= 1000ms |
| `grabFocus: true` on interactive popups | Steals keyboard from active app | `HyprlandFocusGrab` |
| `opacity: 0` to hide popups | Still intercepts input events | `visible: false` |
| ddcutil polling every second | 300ms per call saturates I2C bus | Poll at 30s; write with debounce |
| Native QML notification center | Requires removing swaync — scope/risk too high | Keep swaync; defer to future milestone |
| Bluetooth widget | Not in existing Waybar config | Out of scope |

---

## Widget-Specific Notes

**Workspaces:** `Hyprland.workspaces` sorted by ID. `activate()` switches via IPC. `WheelHandler` for scroll-to-switch via `HyprlandIpc.dispatch("workspace ±1")`.

**Volume OSD:** Official quickshell-examples pattern — `PanelWindow` at `WlrLayer.Overlay` anchored to screen bottom; watch `onVolumeChanged`; restart 1500ms hide timer. Pill progress bar: `Rectangle { width: parent.width * volume; radius: height/2 }`.

**Calendar Popup:** `PopupWindow` anchored to clock item. `Repeater` + `Grid { columns: 7 }`. JS `new Date(year, month-1, 1)` for weekday offset. `LazyLoader { loading: true }` pre-loads to avoid first-open jank.

**Popup Anchoring:** `anchor { item: moduleItem; edges: Edges.Top; gravity: Edges.Bottom }`. `HyprlandFocusGrab { windows: [popup]; active: popup.visible }` for dismiss.

**MPRIS:** Guard with `Mpris.players.length > 0`. `togglePlaying()`, `next()`, `previous()` — direct method calls.

**swaync:** Count via `swaync-client -c`; toggle via `swaync-client -t`. Do NOT use `Quickshell.Services.Notifications.NotificationServer` alongside swaync.

---

## MVP Build Order

1. Bar shell + layout (PanelWindow, BarGroup, Catppuccin Mocha, pills, font)
2. Workspaces (validates Hyprland IPC)
3. Native integrations (MPRIS, PipeWire, SystemTray)
4. Script-backed widgets (CPU/memory/disk/network, ping, weather, clock, backlight)
5. Volume OSD
6. Popup panels (calendar, network panel)
7. Notification center toggle + swaync count
8. Animation polish pass

---
*Research completed: 2026-05-02 — v1.2 Quickshell migration*
