# Architecture: Quickshell Bar Migration (v1.2)

**Project:** .dotfiles — Waybar to Quickshell migration  
**Researched:** 2026-05-02  
**Confidence:** HIGH (Quickshell official docs via Context7; waybar config and scripts read directly)

---

## 1. Directory Layout

```
.config/quickshell/
├── shell.qml                   # Entry point — Scope { Bar {} }
├── Bar.qml                     # Outer Scope; owns Variants over screens + shared services
├── BarContent.qml              # PanelWindow content root; RowLayout left/center/right
├── BarGroup.qml                # Reusable pill-row container (spacing, padding, radius)
│
├── theme/
│   └── Colours.qml             # pragma Singleton; all Catppuccin Mocha hex constants
│
├── services/                   # Singletons wrapping data sources; no UI
│   ├── Clock.qml               # pragma Singleton; Timer + date formatting (Asia/Dhaka)
│   ├── PingStatus.qml          # pragma Singleton; Process polling ping_status.sh
│   ├── Weather.qml             # pragma Singleton; Process polling curr_weather.sh
│   ├── Forecast.qml            # pragma Singleton; Process polling forcast_weather.sh
│   ├── MemoryStats.qml         # pragma Singleton; Process polling memory.sh
│   ├── AudioService.qml        # pragma Singleton; wraps Pipewire.defaultAudioSink
│   └── HyprWorkspaces.qml      # pragma Singleton; thin wrapper over Hyprland.workspaces
│
├── widgets/                    # Stateless visual components; bind to services or props
│   ├── WorkspacesWidget.qml    # Repeater over HyprWorkspaces; click → ws.activate()
│   ├── DiskWidget.qml          # Process + Timer (interval 30 s); df -h output
│   ├── CpuWidget.qml           # Process + Timer (interval 1 s); reads /proc/stat
│   ├── MemoryWidget.qml        # binds Memory.text / Memory.tooltip
│   ├── NetworkWidget.qml       # Hyprland-agnostic; Process reading ip/nmcli
│   ├── PingWidget.qml          # binds PingStatus.text; click opens localhost:8765
│   ├── ClockWidget.qml         # binds Clock.display; click toggles CalendarPopup
│   ├── WeatherWidget.qml       # binds Weather.text/.tooltip; click toggles WeatherPopup
│   ├── ForecastWidget.qml      # binds Forecast.text/.tooltip
│   ├── MediaWidget.qml         # Process playerctl metadata (interval 5 s)
│   ├── VolumeWidget.qml        # binds AudioService.volume; scroll changes volume
│   ├── BacklightWidget.qml     # Process ddcutil (interval 5 s)
│   ├── SysTrayWidget.qml       # Repeater over SystemTray.items
│   ├── NotificationWidget.qml  # Process swaync-client -swb; click toggles panel
│   ├── LockWidget.qml          # MouseArea → Process hyprlock
│   └── PowerWidget.qml         # MouseArea → Process systemctl poweroff
│
└── popups/
    ├── CalendarPopup.qml       # PopupWindow; Qt Calendar or text grid
    ├── WeatherPopup.qml        # PopupWindow; detailed current/forecast
    ├── VolumeOsd.qml           # PopupWindow; slider + mute toggle
    └── NetworkPopup.qml        # PopupWindow; ssid list, nmtui launcher
```

`arch/quickshell.sh` — install script parallel to `arch/waybar.sh`.  
No changes to `.config/waybar/` until v1.2 is verified.

---

## 2. Component Diagram

```
shell.qml
└── Bar (Scope)
    ├── [Singletons auto-instantiated on first reference]
    │   ├── Colours          (theme/Colours.qml)
    │   ├── Clock            (services/Clock.qml)
    │   ├── PingStatus       (services/PingStatus.qml)
    │   ├── Weather          (services/Weather.qml)
    │   ├── Forecast         (services/Forecast.qml)
    │   ├── MemoryStats      (services/MemoryStats.qml)
    │   ├── AudioService     (services/AudioService.qml)
    │   └── HyprWorkspaces   (services/HyprWorkspaces.qml)
    │
    └── Variants { model: Quickshell.screens }
        └── PanelWindow (per screen)
            └── BarContent
                └── RowLayout (full width, fill parent)
                    ├── BarGroup (left)   ← anchors.left
                    │   ├── WorkspacesWidget
                    │   ├── DiskWidget
                    │   ├── CpuWidget
                    │   ├── MemoryWidget
                    │   ├── NetworkWidget
                    │   └── PingWidget
                    │
                    ├── Item (Layout.fillWidth: true)  ← spacer
                    │
                    ├── BarGroup (center) ← anchors.horizontalCenter
                    │   ├── WeatherWidget
                    │   ├── ClockWidget    ─── PopupWindow (CalendarPopup)
                    │   └── ForecastWidget ─── PopupWindow (WeatherPopup)
                    │
                    ├── Item (Layout.fillWidth: true)  ← spacer
                    │
                    └── BarGroup (right)  ← anchors.right
                        ├── SysTrayWidget
                        ├── MediaWidget
                        ├── VolumeWidget   ─── PopupWindow (VolumeOsd)
                        ├── BacklightWidget
                        ├── LockWidget
                        ├── PowerWidget
                        └── NotificationWidget
```

---

## 3. Catppuccin Mocha Colors as QML Constants

Use a `pragma Singleton` QtObject (not a JS module). This is idiomatic Quickshell — any QML file in the same directory can reference `Colours.base` by name, with no import statement needed.

```qml
// theme/Colours.qml
pragma Singleton
import Quickshell

Singleton {
  // Catppuccin Mocha palette (hex values from mocha.css)
  readonly property color rosewater: "#f5e0dc"
  readonly property color flamingo:  "#f2cdcd"
  readonly property color pink:      "#f5c2e7"
  readonly property color mauve:     "#cba6f7"
  readonly property color red:       "#f38ba8"
  readonly property color maroon:    "#eba0ac"
  readonly property color peach:     "#fab387"
  readonly property color yellow:    "#f9e2af"
  readonly property color green:     "#a6e3a1"
  readonly property color teal:      "#94e2d5"
  readonly property color sky:       "#89dceb"
  readonly property color sapphire:  "#74c7ec"
  readonly property color blue:      "#89b4fa"
  readonly property color lavender:  "#b4befe"
  readonly property color text:      "#cdd6f4"
  readonly property color subtext1:  "#bac2de"
  readonly property color subtext0:  "#a6adc8"
  readonly property color overlay2:  "#9399b2"
  readonly property color overlay1:  "#7f849c"
  readonly property color overlay0:  "#6c7086"
  readonly property color surface2:  "#585b70"
  readonly property color surface1:  "#45475a"
  readonly property color surface0:  "#313244"
  readonly property color base:      "#1e1e2e"
  readonly property color mantle:    "#181825"
  readonly property color crust:     "#11111b"

  // Semantic aliases matching waybar widget assignments
  readonly property color workspaceActive: mauve
  readonly property color diskColor:       blue
  readonly property color cpuColor:        sapphire
  readonly property color memoryColor:     sky
  readonly property color networkColor:    teal
  readonly property color pingGood:        blue
  readonly property color pingMedium:      yellow
  readonly property color pingBad:         peach
  readonly property color pingCritical:    red
  readonly property color pingDead:        mauve
  readonly property color clockColor:      rosewater
  readonly property color musicColor:      pink
  readonly property color volumeColor:     flamingo
  readonly property color backlightColor:  rosewater
  readonly property color notifColor:      lavender
  readonly property color pillBg:          surface0
  readonly property color pillBgHover:     surface1
  readonly property color barBg:           "transparent"
}
```

Note: `surface0` in the repo's `mocha.css` is overridden to `#000000` (pure black). Keep that as-is; QML `color` literals accept hex strings.

---

## 4. Reusing Existing Shell Scripts via Process

All five existing scripts output JSON to stdout. QML consumes them through `Process` + `StdioCollector` inside `pragma Singleton` services. A `Timer` re-runs the process at the same interval Waybar used.

### Pattern (identical for all script-backed services)

```qml
// services/PingStatus.qml
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  // Exposed to widgets
  property string text:    "..."
  property string cssClass: ""

  // Re-poll every 5 s (matches waybar interval: 5)
  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: proc.running = true
  }

  Process {
    id: proc
    // Script path must be absolute; $HOME expansion does not happen here
    command: ["/bin/bash", Qt.resolvedUrl("../../waybar/scripts/network/ping_status.sh")]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const obj = JSON.parse(this.text.trim())
          root.text     = obj.text  ?? "err"
          root.cssClass = obj.class ?? ""
        } catch (e) {
          root.text = "err"
        }
      }
    }
  }
}
```

### Script path strategy

Scripts live at `.config/waybar/scripts/…`. From QML files at `.config/quickshell/services/`, the relative path resolves to `../../waybar/scripts/…`. Using `Qt.resolvedUrl()` converts this to an absolute `file://` URL; strip the scheme with `.toString().replace("file://","")` or use `$HOME` via environment expansion in the command array:

```qml
command: ["bash", "-c", "$HOME/.config/waybar/scripts/network/ping_status.sh"]
```

The second form is simpler and avoids the URL scheme conversion. Either works.

### Per-script polling intervals (matching waybar config)

| Script | Waybar interval | QML Timer interval |
|--------|-----------------|--------------------|
| `ping_status.sh` | 5 s | 5000 ms |
| `curr_weather.sh` | 200 s | 200000 ms |
| `forcast_weather.sh` | 200 s | 200000 ms |
| `memory.sh` | 5 s | 5000 ms |
| `backlight` (ddcutil) | 5 s | 5000 ms |

### Native Quickshell APIs (no script needed)

| Waybar widget | Quickshell native |
|---------------|------------------|
| `hyprland/workspaces` | `Hyprland.workspaces` (ObjectModel), `ws.active`, `ws.focused`, `ws.activate()` |
| `pulseaudio` volume | `Pipewire.defaultAudioSink.audio.volume` + `.muted` |
| `tray` | `SystemTray.items` (ObjectModel), `item.activate()`, `item.display()` |
| `clock` (formatting) | `Qt.formatDateTime(new Date(), "ddd yyyy-MM-dd hh:mm:ss AP")` in a Timer |
| `cpu` + `disk` | Process reading `/proc/stat` and `df -h`; no external script needed |
| `network` (display) | Process reading `ip route` / `nmcli -t -f active,ssid dev wifi`; or keep a script |

---

## 5. Popup Architecture

### Which window type to use

Quickshell provides two window types relevant to popups:

- **`PanelWindow`** — anchored to screen edges, reserves exclusive zone. Use only for the bar itself.
- **`PopupWindow`** — floats relative to another window or Item. Use for all popup panels.

**Do not create a second `PanelWindow` for popups.** A second PanelWindow with `exclusiveZone` would shift Hyprland's tiling layout. Use `PopupWindow` with `WlrLayershell.layer: WlrLayer.Overlay` so popups render above normal windows without occupying space.

### Popup placement pattern

Each popup is declared inside the `PanelWindow` (or in `Bar.qml` scope with a reference to the panel window id). Visibility is toggled by a boolean property on the parent widget.

```qml
// Inside BarContent.qml or ClockWidget.qml
PanelWindow {
  id: barWindow
  // ... bar setup

  PopupWindow {
    id: calendarPopup
    visible: false                      // toggled by ClockWidget click

    anchor.window: barWindow
    anchor.rect.x: clockWidget.x        // align to clock widget X
    anchor.rect.y: barWindow.height     // drop below the bar
    width: 300
    height: 340

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // content
    Rectangle {
      anchors.fill: parent
      color: Colours.base
      radius: 10
      // ... calendar content
    }
  }
}
```

### Dismiss on click-outside: use HyprlandFocusGrab

`PopupWindow.grabFocus: true` works but hides the popup when any outside click occurs. For finer control on Hyprland, use `HyprlandFocusGrab`:

```qml
HyprlandFocusGrab {
  id: focusGrab
  windows: [calendarPopup]
  active: calendarPopup.visible
  onCleared: calendarPopup.visible = false
}
```

This allows the popup to stay open while interacting with it, and closes it only when clicking outside — matching expected desktop UX.

### Visibility state management

Keep a single `property bool open: false` on each widget or on a shared state singleton. Toggle on click. Do not use `Loader`/`LazyLoader` unless the popup content is genuinely expensive; for calendar/weather popups, static `visible: false` is sufficient and simpler. Use `LazyLoader` only for the system tray menu, which involves platform menus and may be heavy.

### Popup summary table

| Popup | Trigger | Anchor | Dismiss |
|-------|---------|--------|---------|
| `CalendarPopup` | ClockWidget click | below clock widget | HyprlandFocusGrab |
| `WeatherPopup` | WeatherWidget click | below weather widget | HyprlandFocusGrab |
| `VolumeOsd` | scroll on VolumeWidget | below volume widget | auto-hide timer (2 s) |
| `NetworkPopup` | NetworkWidget click | below network widget | HyprlandFocusGrab |

---

## 6. BarGroup Component

`BarGroup.qml` is a thin visual container: a `Rectangle` with pill radius, surface0 background, and a `RowLayout` child. It accepts widgets as default children.

```qml
// BarGroup.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
  default property alias children: layout.data
  property color groupColor: Colours.pillBg

  color:  groupColor
  radius: 8
  implicitHeight: layout.implicitHeight + 12   // 6px vertical padding
  implicitWidth:  layout.implicitWidth  + 16   // 8px horizontal padding

  Behavior on color { ColorAnimation { duration: 150 } }

  RowLayout {
    id: layout
    anchors.centerIn: parent
    spacing: 4
  }
}
```

In `BarContent.qml`:

```qml
// BarContent.qml
import QtQuick
import QtQuick.Layouts

Item {
  anchors.fill: parent

  RowLayout {
    anchors {
      left:   parent.left
      right:  parent.right
      top:    parent.top
      bottom: parent.bottom
      margins: 4
    }
    spacing: 0

    BarGroup {
      // left group
      WorkspacesWidget {}
      DiskWidget {}
      CpuWidget {}
      MemoryWidget {}
      NetworkWidget {}
      PingWidget {}
    }

    Item { Layout.fillWidth: true }   // flexible spacer

    BarGroup {
      // center group
      WeatherWidget {}
      ClockWidget {}
      ForecastWidget {}
    }

    Item { Layout.fillWidth: true }   // flexible spacer

    BarGroup {
      // right group
      SysTrayWidget {}
      MediaWidget {}
      VolumeWidget {}
      BacklightWidget {}
      LockWidget {}
      PowerWidget {}
      NotificationWidget {}
    }
  }
}
```

---

## 7. Data Flow Summary

```
Shell scripts (bash)
  ping_status.sh  ──► PingStatus singleton ──► PingWidget (text, cssClass)
  curr_weather.sh ──► Weather singleton    ──► WeatherWidget (text, tooltip)
  forcast_weather.sh ► Forecast singleton  ──► ForecastWidget (text, tooltip)
  memory.sh       ──► MemoryStats singleton ──► MemoryWidget (text, tooltip)
  ddcutil         ──► BacklightWidget (inline Process)

Quickshell native APIs
  Hyprland.workspaces ──► WorkspacesWidget (active, focused, activate())
  Pipewire.defaultAudioSink.audio ──► VolumeWidget (volume, muted)
  SystemTray.items    ──► SysTrayWidget (icon, activate(), display())
  Qt Timer + Date     ──► ClockWidget (formatted string, Asia/Dhaka)

Process (inline, no singleton needed)
  playerctl metadata  ──► MediaWidget (artist - title, play-pause on click)
  df -h               ──► DiskWidget (free/total)
  /proc/stat          ──► CpuWidget (usage %)
  ip/nmcli            ──► NetworkWidget (ssid, signal strength)
  swaync-client -swb  ──► NotificationWidget (count, DND state)
```

---

## 8. Suggested Build Order

Build in dependency order — get a visible, themed bar on screen before adding individual widgets, then add services, then popups last.

### Phase 1 — Skeleton bar renders (BAR-01, BAR-02)
1. `shell.qml` — `Scope { Bar {} }`
2. `Bar.qml` — `Variants { model: Quickshell.screens }` wrapping a `PanelWindow` (anchors: top/left/right, height 36)
3. `BarContent.qml` — empty RowLayout with two fill spacers; renders a blank bar
4. `BarGroup.qml` — Rectangle + RowLayout pill container
5. `theme/Colours.qml` — all Catppuccin Mocha constants
6. `arch/quickshell.sh` — installs `quickshell` package, symlinks `.config/quickshell`

**Deliverable:** bar visible at top of Hyprland, correct background color, no widgets yet.

### Phase 2 — Native-API widgets (WS-01, partial MEDIA-01, partial NOTIF-01)
1. `WorkspacesWidget.qml` — Hyprland.workspaces, active highlight in Mauve
2. `SysTrayWidget.qml` — SystemTray.items Repeater
3. `VolumeWidget.qml` — Pipewire sink volume + mute (no popup yet)
4. `MediaWidget.qml` — playerctl Process inline
5. `ClockWidget.qml` — Qt.formatDateTime + Asia/Dhaka + Timer (no popup yet)

**Deliverable:** right and center partly filled; native data confirmed live.

### Phase 3 — Script-backed services (SYS-01, CUST-01, CUST-02)
1. `services/PingStatus.qml` → `PingWidget.qml`
2. `services/MemoryStats.qml` → `MemoryWidget.qml`
3. `services/Weather.qml` → `WeatherWidget.qml`
4. `services/Forecast.qml` → `ForecastWidget.qml`
5. `DiskWidget.qml` (inline Process, df -h)
6. `CpuWidget.qml` (inline Process, /proc/stat)
7. `NetworkWidget.qml` (inline Process or nmcli script)

**Deliverable:** all waybar widget equivalents visible and live. Full widget parity reached.

### Phase 4 — Remaining right-side widgets (MEDIA-01, NOTIF-01)
1. `BacklightWidget.qml` — ddcutil inline Process
2. `NotificationWidget.qml` — swaync-client Process
3. `LockWidget.qml` — hyprlock on click
4. `PowerWidget.qml` — systemctl poweroff on click

**Deliverable:** complete bar, widget parity with Waybar.

### Phase 5 — Popups (POPUP-01, CUST-03)
1. `CalendarPopup.qml` — wired to ClockWidget click + HyprlandFocusGrab
2. `WeatherPopup.qml` — wired to WeatherWidget click
3. `VolumeOsd.qml` — scroll-triggered, auto-hide timer
4. `NetworkPopup.qml` — nmtui launcher or inline ssid list

**Deliverable:** all popup panels functional.

### Phase 6 — Animations (ANIM-01) + hardening (DEPLOY-01)
1. `Behavior on color` + `NumberAnimation` on opacity for hover states
2. `NumberAnimation` on popup y/opacity for open/close
3. End-to-end test on both monitors (Variants multi-screen)
4. Confirm Waybar still starts correctly (parallel deploy intact)
5. Update README with quickshell launch/debug instructions

**Deliverable:** polished bar ready to replace Waybar.

---

## 9. New vs Reused

| Item | Status | Notes |
|------|--------|-------|
| `ping_status.sh` | **Reused** | Called via Process; no changes needed |
| `curr_weather.sh` | **Reused** | Called via Process; logs to `~/.config/waybar/logs/` (harmless) |
| `forcast_weather.sh` | **Reused** | Called via Process |
| `memory.sh` | **Reused** | Called via Process; requires `smem` for tooltip |
| `waybar/scripts/weather/functions.sh` | **Reused** (indirect) | Sourced by weather scripts |
| `.config/waybar/` (all) | **Untouched** | Parallel deploy; waybar remains functional |
| `mocha.css` hex values | **Ported** to `Colours.qml` | Surface0 override (`#000000`) preserved |
| `arch/quickshell.sh` | **New** | Installs quickshell, symlinks quickshell config |
| `.config/quickshell/` | **New** | All QML files listed in section 1 |
| Hyprland workspaces | **New (native)** | No waybar equivalent script; uses Quickshell.Hyprland |
| Volume (Pipewire) | **New (native)** | Replaces pulseaudio waybar module |
| System tray | **New (native)** | Replaces waybar tray module |
| All popup panels | **New** | No waybar equivalents (waybar had only tooltip-based popups) |

---

## 10. Architecture Constraints and Gotchas

**Exclusive zone:** The bar's `PanelWindow` should leave `exclusionMode` at `ExclusionMode.Auto` (default) so Hyprland tiles windows below the bar. Popup `PopupWindow`s must not set an exclusive zone — they should float above everything.

**Multi-monitor:** `Variants { model: Quickshell.screens }` creates one `PanelWindow` per monitor automatically. Each PanelWindow is independent; the popup for one screen should be anchored to that screen's panel window, not a global id.

**Script path in QML:** `Process.command` does not do shell variable expansion. Do not write `command: ["~/.config/waybar/scripts/ping_status.sh"]`. Either use the full `$HOME` expansion via `["bash", "-c", "$HOME/..."]` or construct the path from `StandardPaths.home` at runtime.

**Waybar log paths in weather scripts:** `curr_weather.sh` and `forcast_weather.sh` hardcode `LOG_FILE="$HOME/.config/waybar/logs/..."`. These log writes will continue working when called from QML (bash inherits `$HOME`). This is harmless; do not touch the scripts.

**`surface0` override:** The repo's `mocha.css` sets `surface0: #000000` (pure black), not the canonical Catppuccin `#313244`. The `Colours.qml` file should match this override to preserve visual consistency with waybar tooltips and existing screenshots.

**Pipewire vs PulseAudio:** Quickshell's audio service is `Quickshell.Services.Pipewire`, not a PulseAudio binding. On modern Arch with PipeWire-pulse, `Pipewire.defaultAudioSink` works transparently. `pavucontrol` on click can still be launched via an inline `Process`.

**playerctl in QML:** `playerctl` is a one-shot command, not a daemon. Use the `Timer + Process.running = true` pattern (interval 5000 ms) to re-poll — identical to how waybar's `interval: 5` works.

---

*Sources: Quickshell official documentation (Context7 /websites/quickshell_master), waybar config.jsonc and scripts read directly from repo.*
