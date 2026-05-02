# Pitfalls: Quickshell/QML Hyprland Bar (v1.2)

**Domain:** Replacing Waybar with Quickshell on Hyprland (Arch Linux)
**Researched:** 2026-05-02
**Replaces:** stale v1.1 Neovim research

---

## Pitfall Reference

| # | Pitfall | Risk | Prevention | Phase |
|---|---------|------|------------|-------|
| P-01 | `grabFocus: true` on interactive popup steals keyboard from active app | HIGH | Use `HyprlandFocusGrab { windows: [popup]; active: popup.visible }` instead | Popup phase |
| P-02 | `NotificationServer` conflicts with swaync on `org.freedesktop.Notifications` D-Bus name | HIGH | Never instantiate `NotificationServer` while swaync runs. Use `swaync-client` shell calls only | Bar shell phase |
| P-03 | `opacity: 0` hidden popup still intercepts mouse/touch input | HIGH | Always use `visible: false` to fully remove popup from input tree | Popup phase |
| P-04 | `PwObjectTracker` binding skipped → PipeWire `.audio` properties are invalid/null | HIGH | Bind `PwObjectTracker { objects: [Pipewire.defaultAudioSink] }` before reading `.audio.volume` | Volume widget phase |
| P-05 | ddcutil called every second saturates I2C bus (~300ms per call) | HIGH | Poll read at 30s interval; debounce writes with `Timer { interval: 300 }` — never write on every slider `onValueChanged` | Backlight widget phase |
| P-06 | `Process` command array doesn't expand `~` or `$HOME` | HIGH | Use `["bash", "-c", "~/.config/..."]` wrapper for scripts with home-relative paths | All Process-backed widgets |
| P-07 | Two bars running simultaneously (waybar + quickshell) fight for exclusive zone | MEDIUM | Waybar and Quickshell use separate PanelWindows; both can coexist if both request same exclusive zone edge — test on target machine before claiming parity | Parallel deploy phase |
| P-08 | QML property binding loop: writing a bound property triggers re-evaluation that writes it again | MEDIUM | Separate display state (bound) from user-input state (explicit set). Use `Qt.binding()` carefully around slider values | Volume / backlight widgets |
| P-09 | Hyprland IPC socket path changes on compositor reload — `Quickshell.Hyprland` module handles reconnect; raw socket reads do not | MEDIUM | Use `Quickshell.Hyprland` module exclusively — do NOT open the IPC socket directly | Workspaces phase |
| P-10 | `ScriptModel` / inline JS `.filter()` on `ObjectModel` discards delegates → no add/remove animations | MEDIUM | Use `ScriptModel` (Quickshell) or `DelegateModel` with `filterOnGroup` for filtered lists with animations | Workspaces / tray |
| P-11 | `StdioCollector` buffers full output — streaming processes (e.g. `swaync-client -sw`) must use `StdioLineParser` | MEDIUM | For long-running streaming processes, use `StdioLineParser` + `onLine` handler. Reserve `StdioCollector` for one-shot commands | swaync count widget |
| P-12 | SNI tray icons: `icon.name` resolves from current icon theme; `icon.image` is a `QImage` — need `Image { source: item.icon.image }` not `source: item.icon.name` when theme lookup fails | MEDIUM | Test with apps that use both icon paths. Fall back to `icon.image` when `icon.name` is empty | Tray widget phase |
| P-13 | ddcutil fails silently when `i2c-dev` module not loaded or user not in `i2c` group | MEDIUM | `arch/quickshell.sh` install script must: `sudo modprobe i2c-dev`, `sudo usermod -aG i2c $USER`, add `i2c-dev` to `/etc/modules-load.d/` for persistence | Install script phase |
| P-14 | JavaScript in hot paths (e.g. `onVolumeChanged` that calls array `.filter()`) causes frequent GC pauses visible as animation stutter | MEDIUM | Precompute in QML properties; avoid JS object allocation in bindings. Profile with `QML_PROFILER` if stuttering occurs | Animation phase |
| P-15 | `Variants { model: Quickshell.screens }` — screen model mutates when monitor connected/disconnected; delegates must handle `Component.onDestruction` cleanly | LOW | Ensure popup windows and timers inside Variants delegates are stopped in `Component.onDestruction` | Bar shell phase |
| P-16 | `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None` missing on bar → bar steals keyboard focus from Hyprland windows | LOW | Set `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None` on the main bar `PanelWindow`. Only set `OnDemand`/`Exclusive` on popups that need keyboard input | Bar shell phase |
| P-17 | `LazyLoader` content not pre-loaded → first popup open has visible jank as QML component is compiled | LOW | Set `LazyLoader { loading: true }` (not deferred) for popups opened frequently (clock calendar, volume OSD) | Popup phase |
| P-18 | `Process` with `running: true` in `Component.onCompleted` fires before `Quickshell.screens` resolves — bar content flickers | LOW | Use `Timer { interval: 0; onTriggered: proc.running = true }` as a deferred start instead of `Component.onCompleted` direct assignment | All Process-backed widgets |

---

## Pre-Switch Verification Checklist

Before disabling Waybar and making Quickshell the sole bar:

- [ ] All 15 widgets render with correct values on primary monitor
- [ ] Multi-monitor: second bar appears on second screen
- [ ] Workspaces: click switches workspace; scroll cycles workspaces
- [ ] Volume OSD: appears on scroll, auto-hides after 1.5s
- [ ] Calendar popup: opens on clock click, closes on outside click
- [ ] Network panel: opens on network click, shows SSID and IP
- [ ] swaync: notification count updates; toggle opens swaync panel
- [ ] System tray: all tray apps show icons; right-click opens context menu
- [ ] MPRIS: music widget shows current track; click toggles play/pause
- [ ] Ping widget: shows colored latency from `localhost:8765`
- [ ] Backlight: shows current brightness; up/down adjusts (ddcutil)
- [ ] Lock button: triggers `hyprlock`
- [ ] Power button: triggers `wlogout`
- [ ] Exclusive zone: Hyprland windows do not overlap the bar
- [ ] Keyboard focus: bar does not steal focus when Waybar did not

---
*Research completed: 2026-05-02 — v1.2 Quickshell migration*
