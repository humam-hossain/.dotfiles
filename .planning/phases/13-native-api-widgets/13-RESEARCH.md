# Phase 13: Native API Widgets — Research

**Researched:** 2026-05-03
**Domain:** Quickshell QML widgets bound to Hyprland / PipeWire / MPRIS / SystemTray native APIs
**Confidence:** HIGH

## Summary

Phase 13 wires four widgets (workspaces, volume, music, tray) to Quickshell's built-in service modules. All four APIs are documented and available in the installed Quickshell 0.2.1 build [VERIFIED: `pacman -Q quickshell` → `quickshell 0.2.1-6`]. The dominant pattern is service-singleton wrappers in `services/` that hide raw API binding behind a stable property surface, consumed by stateless QML widgets in `widgets/` that already use `ModulePill` and `Colours` from Phase 12.

Two CONTEXT.md decisions reference outdated method/property names that do not exist on the current Quickshell API surface and MUST be corrected during planning: D-31 says `player.playPause()` — the current method is `togglePlaying()`; D-29 says `MprisService.activePlayer.{title,artists}` — the current properties are `trackTitle` and `trackArtist` (singular; `trackArtists` is the deprecated plural form). These are surface naming corrections, not architectural changes — the intent of CONTEXT.md is preserved.

**Primary recommendation:** Implement three thin singleton wrappers (`AudioService`, `MprisService`, `HyprWorkspaces`) that expose pre-validated, null-guarded properties; build four widgets that consume them; swap `BarContent.qml` placeholder pills last. Use `togglePlaying()` and `trackArtist`. Use `IconImage` from `Quickshell.Widgets` (not `Quickshell`) for tray icons. Use `Hyprland.dispatch("workspace e+1")` (not a separate `HyprlandIpc` import — the dispatch method lives on the `Hyprland` singleton itself).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Service Layer**
- **D-01:** Use service singleton wrappers (per `.planning/research/ARCHITECTURE.md`). Three new singletons: `AudioService.qml` (PipeWire default sink), `MprisService.qml` (active player selection), `HyprWorkspaces.qml` (sorted/filtered workspaces). Widgets import services, never the raw `Quickshell.Services.*` modules.
- **D-02:** Service files live under `.config/quickshell/services/` with `services/qmldir`. Imported via `import qs.services`. Mirrors Phase 12's `theme/Colours.qml` + `theme/qmldir` precedent.
- **D-03:** Each service uses `pragma Singleton` and is registered as `singleton ServiceName 1.0 ServiceName.qml` in `services/qmldir`. Singleton instance is shared across the whole shell.
- **D-04:** `AudioService` exposes derived properties only — `volume: real`, `muted: bool`, `volumePercent: int`. Internal `PwObjectTracker` and `defaultSink` reference are hidden behind the API. Helper methods: `setVolume(percent)`, `bumpVolume(delta)`, `toggleMute()`. All computed properties use null-guards (e.g. `volumePercent: defaultSink ? Math.round(defaultSink.audio.volume * 100) : 0`).
- **D-05:** `AudioService` re-binds `PwObjectTracker` when `Pipewire.defaultAudioSink` changes (default device switch on headphone plug). Tracker target list = `[Pipewire.defaultAudioSink]` only — `.audio` is auto-tracked when parent sink is tracked. `volumePercent` = `Math.round(volume * 100)`.
- **D-06:** `AudioService` scope is sink-only for Phase 13. Default source / microphone is out of scope (no v1.2 requirement).
- **D-07:** `MprisService` player selection: `Mpris.players.values.find(p => p.playbackState === 'Playing') ?? Mpris.players.values[0]`. First playing wins, fallback to first in list, hidden when list is empty.

**Workspaces Widget**
- **D-08:** Visual style = Waybar dot icons. Active workspace renders ``, default renders ``. JetBrainsMono Nerd Font 14px (matches Phase 12 text size).
- **D-09:** Show only existing workspaces (iterate `Hyprland.workspaces.values`); no fixed 1-10 slots.
- **D-10:** Repeater model = `Hyprland.workspaces.values.slice().sort((a,b) => a.id - b.id).filter(w => w.id >= 0 && !w.name.startsWith('special:'))`. Filter strips Hyprland special / scratchpad workspaces. Sort by id keeps stable left-to-right ordering.
- **D-11:** One pill containing all workspace buttons — single `ModulePill` wrapping a `Repeater` of buttons. Buttons styled inline (color only); no nested pills.
- **D-12:** Mauve highlight tracks `ws.active` (per-monitor visible workspace), not `ws.focused`. On dual-monitor, each bar highlights its own monitor's active workspace.
- **D-13:** Three-state coloring by `Colours`: `accent` (mauve) for active, `textColor` for occupied (has toplevels), `subtextColor` for empty.
- **D-14:** Urgent indicator = override icon color to `Colours.critical` (red). No animation in Phase 13.
- **D-15:** `urgent` source: prefer `ws.urgent` if Quickshell exposes it; else derive `ws.toplevels.values.some(t => t.urgent)`. Researcher confirms which API path is current.
- **D-16:** Activation = `workspace.activate()` (QML-native method, not `HyprlandIpc.dispatch`). Cross-monitor click uses native `.activate()` behavior (no manual `focusmonitor` pre-dispatch).
- **D-17:** Each bar (every monitor) renders the same global workspace list — not per-monitor filtered. Click any workspace from any bar.
- **D-18:** Scroll behavior: wheel-down = next workspace, wheel-up = previous. Wraps at edges. Implemented via `Hyprland.dispatch("workspace e+1")` / `e-1` (Hyprland's empty-aware/wrap dispatchers).
- **D-19:** Initial-paint race: bind reactively to `Hyprland.workspaces.values`; render empty until populated (~1 frame). No explicit placeholder.

**Volume Widget**
- **D-20:** Format = icon + percentage text. Width is content-driven.
- **D-21:** Icon thresholds — `0%` or muted = ``, `<33%` = ``, `<66%` = ``, `≥66%` = ``. Volume = 0% (not muted) is intentionally rendered as muted ``.
- **D-22:** Mute visual = swap icon to `` AND drop text opacity to 60%.
- **D-23:** Click → launch pavucontrol via inline `Process { command: ["pavucontrol"]; running: false }` invoked with `.startDetached()`. No `pgrep` dedup. No `hyprctl focuswindow` post-launch.
- **D-24:** Right-click toggles mute via `AudioService.toggleMute()`.
- **D-25:** Wheel adjusts volume in ±5% steps via `step = 5 * Math.sign(wheel.angleDelta.y)`. Each detent = 120 angle-delta units. No debounce.
- **D-26:** Single `MouseArea` with `acceptedButtons: AllButtons` handles both `onWheel` and `onClicked`. `onClicked` filters `Qt.LeftButton` for pavucontrol vs `Qt.RightButton` for mute.
- **D-27:** Tooltip = sink display name + percentage.
- **D-28:** Hidden when `AudioService.defaultSink === null`.

**Music Widget (MPRIS)**
- **D-29:** Format = icon + `"artist - title"`. Matches existing Waybar `custom/music` exec format. *(Naming corrected: see Assumptions Log A1 — uses `trackArtist` and `trackTitle`, not `artists`/`title`.)*
- **D-30:** Truncation = fixed 30 characters. `Text.elide: Text.ElideRight`. `Layout.maximumWidth` derived from font metrics.
- **D-31:** Click toggles play/pause. *(Method-name corrected: see Assumptions Log A2 — `togglePlaying()`, not `playPause()`. Click works in `Stopped` state too.)*
- **D-32:** When `player.canControl === false` → `MouseArea.enabled = false` and dim opacity (60%).
- **D-33:** Player exists but no metadata loaded yet → show ` No track`.
- **D-34:** Tooltip on hover = full untruncated `"Artist\nTitle\nAlbum"` via `ToolTip`.
- **D-35:** Hidden when `MprisService.activePlayer === null`.

**System Tray**
- **D-36:** Icon rendering = Quickshell `IconImage { source: item.icon }`. *(Import path: `import Quickshell.Widgets`, not `import Quickshell`. See A3.)*
- **D-37:** Original icon colors preserved (no monochrome tint).
- **D-38:** All icons live inside ONE `ModulePill`.
- **D-39:** Icon size = 21px.
- **D-40:** Pill hidden when tray is empty.
- **D-41:** Render all SNI status states. NeedsAttention items get a `Colours.critical` color tint.
- **D-42:** Left-click → `item.activate(x, y)`. Right-click → opens `QsMenuOpener`/`QsMenuAnchor` context menu against `item.menu`.
- **D-43:** Tray context menu uses `QsMenuAnchor` (not `item.display()`). Anchored below bar, top-aligned to clicked icon. Menu dismiss via `HyprlandFocusGrab`. NOT `grabFocus: true`.
- **D-44:** Icon load failure fallback = render Nerd Font glyph as Text.

**Cross-Cutting**
- **D-45:** Pointer cursor on every clickable widget.
- **D-46:** Click hit area = full `ModulePill`.
- **D-47:** Click-handler `Process` instances live inline inside the consuming widget.
- **D-48:** Logging policy: `Process { onExited: code => code !== 0 ? console.warn(...) : null }`.
- **D-49:** Tooltips in Phase 13: volume widget + music widget only.
- **D-50:** No hover animations or transitions in Phase 13. Static color states only.
- **D-51:** Hidden widgets collapse layout via QML default `visible: false` semantics.

**File Layout**
- **D-52:** `<Name>Widget.qml` naming.
- **D-53:** Widgets under `.config/quickshell/widgets/` with `widgets/qmldir`. Imported as `import qs.widgets`.
- **D-54:** Widgets stand alone — they import only `qs.theme` and `qs.services`.
- **D-55:** `shell.qml` and `Bar.qml` unchanged in Phase 13. Service singletons auto-instantiate on first import.
- **D-56:** `BarContent.qml` placeholder labels replaced. Final layout: left=`WorkspacesWidget`. Right=`MusicWidget`, `VolumeWidget`, `TrayWidget`. Center BarGroup empty.

**UAT**
- **D-57:** Verification = manual checklist per widget. No automated QML test harness in Phase 13.

### Claude's Discretion
- Exact Repeater vs ListView vs RowLayout-of-Items inside ModulePill for the workspace row.
- Internal spacing values inside the workspace pill (between buttons).
- Detailed `IconImage` props for SNI icons (sourceSize, smooth, mipmap, asynchronous).
- Internal property names inside `AudioService` / `MprisService` / `HyprWorkspaces` beyond the public API documented in D-04 / D-07 / D-10.
- Exact tooltip strings and capitalization.
- QML import order, ID naming, internal Item structure.
- Right BarGroup widget order.

### Deferred Ideas (OUT OF SCOPE)
- **Volume OSD overlay** (AUDIO-02) — Phase 14.
- **Notification count badge** (TRAY-02) + **swaync toggle** (TRAY-03) — Phase 14.
- **Hover animations** (`Behavior on color`) — Phase 16 (ANIM-01).
- **Workspace tooltips**.
- **Tray-item explicit tooltips** — DBus tooltips suffice.
- **Mic/source volume widget** — Not in v1.2.
- **Multi-player UI affordance** (cycle players, show all simultaneously).
- **Music next/previous track buttons or scroll**.
- **Tray-icon monochrome theme tint**.
- **Always-show 1-10 workspace slots**.
- **Per-button workspace pill**.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WS-01 | Workspaces widget shows all Hyprland workspaces using `Quickshell.Hyprland` (`Hyprland.workspaces` ObjectModel) — reactive, not raw IPC socket | `Hyprland.workspaces` is an `ObjectModel` of `HyprlandWorkspace` objects sorted by id [VERIFIED: quickshell.org/docs/types/Quickshell.Hyprland/Hyprland]. Iteration via `.values` array — see Code Example 1. |
| WS-02 | Active workspace highlighted in Catppuccin Mauve; occupied vs empty distinct; urgent has distinct indicator | `HyprlandWorkspace.active` boolean is documented [VERIFIED]. Occupied detection: per A4 — researcher could not verify a `toplevels` property on `HyprlandWorkspace` in current docs; planner must verify against runtime introspection. Urgent: see A5 — no documented `urgent` property; the canonical Hyprland event channel is `urgent <workspace>` IPC, surfaced via `Hyprland.rawEvent`. Recommend listening to `rawEvent` and tracking urgent IDs in `HyprWorkspaces` service. |
| WS-03 | Click activates via `workspace.activate()`; scroll cycles via `Hyprland.dispatch` | `HyprlandWorkspace.activate()` is documented [VERIFIED]. `Hyprland.dispatch("workspace e+1")` is documented [VERIFIED] — note: dispatch lives on the `Hyprland` singleton, not a separate `HyprlandIpc` namespace. |
| AUDIO-01 | Volume widget shows PipeWire default sink %+mute via `Quickshell.Services.Pipewire`; `PwObjectTracker` bound before reading `.audio`; click opens pavucontrol | `Pipewire.defaultAudioSink` + `PwObjectTracker { objects: [...] }` pattern [VERIFIED]. `.audio.volume` and `.audio.muted` are writable directly via property assignment, no setter methods [VERIFIED]. `Process { command: ["pavucontrol"] }.startDetached()` documented [VERIFIED]. |
| AUDIO-03 | Music widget shows MPRIS artist+title via `Quickshell.Services.Mpris`; click toggles play/pause; hidden when no player active | `Mpris.players` is `ObjectModel<MprisPlayer>` [VERIFIED]. Properties are `trackTitle`, `trackArtist`, `trackAlbum` [VERIFIED — `trackArtist` singular is canonical; `trackArtists` is deprecated]. Method is `togglePlaying()` [VERIFIED — `playPause()` does not exist]. |
| TRAY-01 | System tray renders SNI icons via `Quickshell.Services.SystemTray`; right-click opens context menu | `SystemTray.items` is an ObjectModel [VERIFIED]. `SystemTrayItem.icon` is a string source usable directly in Image/IconImage [VERIFIED]. `item.menu` is a `QsMenuHandle` consumable by `QsMenuAnchor` [VERIFIED]. `IconImage` lives in `Quickshell.Widgets` module [VERIFIED]. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Workspace state read | Service singleton (`HyprWorkspaces`) | Quickshell.Hyprland module | Reactive ObjectModel binding centralized; widgets never touch raw IPC |
| Workspace activation | Widget (MouseArea → `ws.activate()`) | — | Object-level method on the workspace object itself; no service indirection needed |
| Workspace cycling (scroll) | Widget (MouseArea → `Hyprland.dispatch`) | Quickshell.Hyprland | Direct dispatch is idiomatic; no benefit to wrapping |
| Audio sink read | Service singleton (`AudioService`) | Quickshell.Services.Pipewire + PwObjectTracker | `PwObjectTracker` lifecycle and re-bind logic is non-trivial; centralize |
| Audio sink write (volume/mute) | Service helper methods | Pipewire `.audio.volume = x` | `.audio.volume` and `.audio.muted` are writable; service exposes safer setter API |
| pavucontrol launch | Inline Process in `VolumeWidget` | Process.startDetached | One-liner; no centralized ProcessService per D-47 |
| MPRIS player selection | Service singleton (`MprisService`) | Quickshell.Services.Mpris | "First playing else first" heuristic is shared logic; D-07 |
| MPRIS playback control | Widget (MouseArea → `player.togglePlaying()`) | — | Object-level method; no service indirection |
| Tray item enumeration | Widget (Repeater over `SystemTray.items`) | Quickshell.Services.SystemTray | Direct binding is idiomatic; no shared filtering logic across widgets |
| Tray icon rendering | Quickshell.Widgets.IconImage | — | Built-in component handles SNI icon URI resolution |
| Tray context menu | `QsMenuAnchor` + `HyprlandFocusGrab` | Quickshell + Quickshell.Hyprland | Native menu rendering with Hyprland-specific outside-click dismiss |
| Layout composition | `BarContent.qml` | BarGroup, ModulePill | Widgets stand alone; BarContent positions them — D-54 |

## Standard Stack

### Core (already installed and verified)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `quickshell` | 0.2.1-6 (Arch [extra]) | QML shell framework | Only mature QML shell with Hyprland/PipeWire/MPRIS/SystemTray bindings [VERIFIED: `pacman -Q quickshell`] |
| Quickshell.Hyprland | bundled | Hyprland workspace/IPC binding | Avoids raw socket reads (P-09) [VERIFIED: docs] |
| Quickshell.Services.Pipewire | bundled | Audio sink read/write | Native binding, no shell scripts [VERIFIED: docs] |
| Quickshell.Services.Mpris | bundled | Media player control over D-Bus | Replaces playerctl polling [VERIFIED: docs] |
| Quickshell.Services.SystemTray | bundled | StatusNotifierItem tray model | Replaces Waybar tray module [VERIFIED: docs] |
| Quickshell.Widgets | bundled | `IconImage` component | Handles SNI icon URI scheme correctly [VERIFIED: docs] |
| `pavucontrol` | installed | Click-to-open audio mixer | Industry standard PipeWire-pulse mixer [VERIFIED: `command -v pavucontrol`] |

**Version verification done 2026-05-03:**
- `quickshell --version` → `quickshell 0.2.1, distributed by: Arch Linux`
- `pacman -Q quickshell` → `quickshell 0.2.1-6`
- `pgrep pipewire` → process 1601 running
- `pgrep wireplumber` → process 1602 running
- `command -v pavucontrol` → `/usr/bin/pavucontrol`
- `command -v hyprctl` → `/usr/bin/hyprctl`; Hyprland 0.54.3

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `QtQuick` | bundled | Item, MouseArea, Text, ToolTip | Every widget |
| `QtQuick.Layouts` | bundled | RowLayout (already used in BarContent) | When `Layout.fillWidth` / `Layout.maximumWidth` is needed |
| `Qt5Compat.GraphicalEffects` | bundled | Already used by BarContent for DropShadow | Not added here; mentioned for completeness |

### Alternatives Considered (rejected per CONTEXT.md)

| Instead of | Could Use | Why Rejected |
|------------|-----------|--------------|
| `Process { command: ["playerctl", ...] }` | MPRIS native binding | D-29 ships native; playerctl polling deprecated by Mpris singleton |
| `hyprctl dispatch workspace e+1` via Process | `Hyprland.dispatch("workspace e+1")` | D-18 specifies native dispatch; Process spawn is slower and adds bash dependency |
| Raw `~/.config/hypr/hyprland-X.sock` socket reads | `Hyprland.workspaces` ObjectModel | P-09: socket path changes on compositor reload |
| `item.display()` for tray menu fallback | `QsMenuAnchor` with `item.menu` | D-43 specifies QsMenuAnchor; `display()` is a fallback for compositors that lack menu rendering, not needed on Hyprland |

**Installation:** No new packages. All capabilities are bundled in `quickshell 0.2.1-6` already installed.

## Architecture Patterns

### System Architecture Diagram

```
                Hyprland IPC          PipeWire             MPRIS D-Bus           StatusNotifier D-Bus
                     │                    │                     │                          │
                     ▼                    ▼                     ▼                          ▼
            Quickshell.Hyprland   Quickshell.Services      Quickshell.Services     Quickshell.Services
                                  .Pipewire +              .Mpris                  .SystemTray
                                  PwObjectTracker
                     │                    │                     │                          │
                     ▼                    ▼                     ▼                          │
        ┌──────────────────────┐ ┌────────────────────┐ ┌──────────────────────┐           │
        │ HyprWorkspaces.qml   │ │ AudioService.qml   │ │ MprisService.qml     │           │
        │ (singleton)          │ │ (singleton)        │ │ (singleton)          │           │
        │ .workspaces[] sorted │ │ .volume/muted/...  │ │ .activePlayer        │           │
        │ .urgentIds Set       │ │ .toggleMute()      │ │   (first-playing     │           │
        │ rawEvent listener    │ │ .setVolume(p)      │ │    heuristic)        │           │
        └──────────────────────┘ └────────────────────┘ └──────────────────────┘           │
                     │                    │                     │                          │
                     │                    │                     │                          │
                     ▼                    ▼                     ▼                          ▼
        ┌──────────────────────┐ ┌────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐
        │ WorkspacesWidget.qml │ │ VolumeWidget.qml   │ │ MusicWidget.qml      │ │ TrayWidget.qml       │
        │ (Repeater + buttons) │ │ (icon+text+wheel)  │ │ (icon+text+click)    │ │ (Repeater+IconImage) │
        │ click→ws.activate()  │ │ click→Process pav. │ │ click→togglePlaying  │ │ L-click: activate    │
        │ wheel→Hyprland.dispatch│ wheel→setVolume(±5)│ │ tooltip: full meta   │ │ R-click: QsMenuAnchor│
        └──────────────────────┘ └────────────────────┘ └──────────────────────┘ └──────────────────────┘
                     │                    │                     │                          │
                     └────────────────────┴─────────────────────┴──────────────────────────┘
                                                       │
                                                       ▼
                                          ┌──────────────────────────────┐
                                          │   BarContent.qml (Phase 12)  │
                                          │   left=Workspaces            │
                                          │   right=Music+Volume+Tray    │
                                          └──────────────────────────────┘
```

Data flow direction:
1. External events (Hyprland workspace change, sink default change, MPRIS metadata, SNI item registration) trigger property updates in Quickshell native modules.
2. Service singletons re-emit a stable, null-safe property surface.
3. Widgets bind reactively; user input flows back through MouseArea → method call on the service or directly on the underlying object (workspace.activate(), player.togglePlaying()).

### Recommended Project Structure

```
.config/quickshell/
├── shell.qml                # unchanged in Phase 13
├── Bar.qml                  # unchanged in Phase 13
├── BarContent.qml           # MODIFIED — placeholder labels swapped for widget instances
├── BarGroup.qml             # unchanged
├── ModulePill.qml           # unchanged
├── theme/
│   ├── qmldir               # singleton Colours 1.0 Colours.qml  (already present)
│   └── Colours.qml          # unchanged
├── services/                # NEW directory
│   ├── qmldir               # NEW — registers three singletons
│   ├── AudioService.qml     # NEW
│   ├── MprisService.qml     # NEW
│   └── HyprWorkspaces.qml   # NEW
└── widgets/                 # NEW directory
    ├── qmldir               # NEW — registers four widget components (non-singleton)
    ├── WorkspacesWidget.qml # NEW
    ├── VolumeWidget.qml     # NEW
    ├── MusicWidget.qml      # NEW
    └── TrayWidget.qml       # NEW
```

### Pattern 1: Service Singleton with PwObjectTracker

**What:** Centralize PipeWire binding so widgets never touch `PwObjectTracker` directly.
**When to use:** Any time PipeWire `.audio.*` properties are read.
**Example:**
```qml
// services/AudioService.qml
// Source: quickshell.org/docs/types/Quickshell.Services.Pipewire/PwObjectTracker [VERIFIED]
pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property real volume:    defaultSink && defaultSink.audio ? defaultSink.audio.volume : 0
    readonly property bool muted:     defaultSink && defaultSink.audio ? defaultSink.audio.muted  : false
    readonly property int  volumePercent: Math.round(volume * 100)
    readonly property string sinkName: defaultSink ? (defaultSink.description || defaultSink.name || "Audio") : ""

    function setVolume(percent) {
        if (!defaultSink || !defaultSink.audio) return
        defaultSink.audio.volume = Math.max(0, Math.min(1, percent / 100))
    }
    function bumpVolume(delta) { setVolume(volumePercent + delta) }
    function toggleMute() {
        if (!defaultSink || !defaultSink.audio) return
        defaultSink.audio.muted = !defaultSink.audio.muted
    }

    // PwObjectTracker MUST be alive whenever .audio is accessed (P-04).
    // The tracker re-binds automatically when defaultAudioSink changes
    // because `objects` is bound to a reactive expression.
    PwObjectTracker {
        objects: root.defaultSink ? [root.defaultSink] : []
    }
}
```

### Pattern 2: Service Singleton with Player Selection Heuristic

**What:** Pick a single "active" MPRIS player from the live `Mpris.players` ObjectModel.
**When to use:** Music widget, future media OSD popup.
**Example:**
```qml
// services/MprisService.qml
// Source: quickshell.org/docs/types/Quickshell.Services.Mpris/MprisPlayer [VERIFIED]
pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    // D-07: first Playing else first in list
    readonly property var activePlayer: {
        const list = Mpris.players.values
        if (!list || list.length === 0) return null
        const playing = list.find(p => p.playbackState === MprisPlaybackState.Playing)
        return playing ?? list[0]
    }
    readonly property bool hasPlayer: activePlayer !== null
}
```

### Pattern 3: Workspaces Wrapper with Sort + Filter + Urgent Tracking

**What:** Expose a stable, sorted, filtered workspace list and a Set of urgent workspace ids.
**When to use:** Any workspaces widget.
**Example:**
```qml
// services/HyprWorkspaces.qml
// Source: quickshell.org/docs/types/Quickshell.Hyprland/Hyprland [VERIFIED];
//         quickshell.org/docs/types/Quickshell.Hyprland/HyprlandWorkspace [VERIFIED]
pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    // D-10: sorted, filtered list of HyprlandWorkspace objects.
    readonly property var workspaces: Hyprland.workspaces.values
        .slice()
        .sort((a, b) => a.id - b.id)
        .filter(w => w.id >= 0 && !(w.name && w.name.startsWith("special:")))

    // Urgent workspace ids tracked via rawEvent listener.
    // Hyprland emits "urgent>>WORKSPACEID" when a window in a non-focused
    // workspace requests attention. Cleared when the workspace becomes focused.
    property var urgentIds: ({})

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            // event.name === "urgent", event.data is the workspace id (string)
            if (event.name === "urgent") {
                const id = parseInt(event.data, 10)
                if (!isNaN(id)) {
                    const next = Object.assign({}, root.urgentIds)
                    next[id] = true
                    root.urgentIds = next
                }
            } else if (event.name === "workspace" || event.name === "focusedmon") {
                // Clear urgent flag for workspace becoming focused.
                if (Hyprland.focusedWorkspace) {
                    const id = Hyprland.focusedWorkspace.id
                    if (root.urgentIds[id]) {
                        const next = Object.assign({}, root.urgentIds)
                        delete next[id]
                        root.urgentIds = next
                    }
                }
            }
        }
    }

    function isUrgent(id) { return !!urgentIds[id] }
}
```

### Pattern 4: Widget — Workspace Repeater Inside ModulePill

**Example:**
```qml
// widgets/WorkspacesWidget.qml
import QtQuick
import qs.theme
import qs.services
import "../" as Local // for ModulePill

Local.ModulePill {
    id: root
    Row {
        spacing: 6
        Repeater {
            model: HyprWorkspaces.workspaces
            delegate: Item {
                required property var modelData
                width: glyph.implicitWidth
                height: glyph.implicitHeight
                Text {
                    id: glyph
                    anchors.centerIn: parent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    text: modelData.active ? "" : ""
                    color: HyprWorkspaces.isUrgent(modelData.id) ? Colours.critical
                         : modelData.active                       ? Colours.accent
                         : modelData.hasFullscreen                ? Colours.textColor
                         /* occupied detection via toplevels TBD */: Colours.subtextColor
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.activate()
                }
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.angleDelta.y < 0) Hyprland.dispatch("workspace e+1")
            else                        Hyprland.dispatch("workspace e-1")
        }
    }
}
```

### Pattern 5: Volume Widget — All-Buttons MouseArea

**Example:**
```qml
// widgets/VolumeWidget.qml
import QtQuick
import Quickshell.Io
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root
    visible: AudioService.defaultSink !== null

    Row {
        spacing: 6
        Text {
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
            color: Colours.textColor
            opacity: AudioService.muted ? 0.6 : 1.0
            text: {
                if (AudioService.muted || AudioService.volumePercent === 0) return ""
                if (AudioService.volumePercent < 33) return ""
                if (AudioService.volumePercent < 66) return ""
                return ""
            }
        }
        Text {
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
            color: Colours.textColor
            opacity: AudioService.muted ? 0.6 : 1.0
            text: AudioService.volumePercent + "%"
        }
    }

    Process {
        id: pavucontrolProc
        command: ["pavucontrol"]
        running: false
        onExited: code => { if (code !== 0) console.warn("pavucontrol exited", code) }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)       pavucontrolProc.startDetached()
            else if (mouse.button === Qt.RightButton) AudioService.toggleMute()
        }
        onWheel: wheel => {
            const step = 5 * Math.sign(wheel.angleDelta.y)
            AudioService.bumpVolume(step)
        }
    }

    ToolTip.visible: hover.hovered
    ToolTip.text:    "Default sink: " + AudioService.sinkName + " — " + AudioService.volumePercent + "%"
    HoverHandler { id: hover }
}
```

### Pattern 6: Music Widget with Truncation + Tooltip

**Example:**
```qml
// widgets/MusicWidget.qml
import QtQuick
import qs.theme
import qs.services
import "../" as Local

Local.ModulePill {
    id: root
    visible: MprisService.hasPlayer

    readonly property var p: MprisService.activePlayer
    readonly property string raw: p ? ((p.trackArtist || "") + " - " + (p.trackTitle || "")).trim() : ""
    readonly property string display: {
        if (!p) return ""
        if (!p.trackTitle && !p.trackArtist) return " No track"
        return " " + (raw.length > 30 ? raw.substring(0, 29) + "…" : raw)
    }

    opacity: (p && p.canControl) ? 1.0 : 0.6

    Text {
        anchors.centerIn: parent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        font.bold: true
        color: Colours.textColor
        elide: Text.ElideRight
        text: root.display
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: p ? p.canControl : false
        onClicked: { if (p) p.togglePlaying() }
    }

    ToolTip.visible: hover.hovered && p
    ToolTip.text: p ? ((p.trackArtist || "?") + "\n" + (p.trackTitle || "?") + "\n" + (p.trackAlbum || "")) : ""
    HoverHandler { id: hover }
}
```

### Pattern 7: Tray with QsMenuAnchor + HyprlandFocusGrab

**Example:**
```qml
// widgets/TrayWidget.qml
import QtQuick
import Quickshell
import Quickshell.Widgets         // IconImage lives here
import Quickshell.Services.SystemTray
import Quickshell.Hyprland        // HyprlandFocusGrab
import qs.theme
import "../" as Local

Local.ModulePill {
    id: root
    visible: SystemTray.items.values.length > 0

    Row {
        spacing: 8
        Repeater {
            model: SystemTray.items
            delegate: Item {
                id: trayItem
                required property var modelData
                width: 21
                height: 21

                IconImage {
                    id: iconImg
                    anchors.fill: parent
                    source: trayItem.modelData.icon
                    asynchronous: true
                    // NeedsAttention tint via opacity layer or fallback Text per D-44
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            trayItem.modelData.activate(mouse.x, mouse.y)
                        } else if (mouse.button === Qt.RightButton) {
                            menuAnchor.menu = trayItem.modelData.menu
                            // anchor.window/rect set via property bindings below
                            menuAnchor.open()
                        }
                    }
                }
            }
        }
    }

    QsMenuAnchor {
        id: menuAnchor
        anchor.window: Window.window      // the bar's PanelWindow
        // anchor.rect set imperatively in onClicked above using mapToItem
    }

    HyprlandFocusGrab {
        windows: [menuAnchor.visible ? Window.window : null].filter(w => w !== null)
        active: menuAnchor.visible
        onCleared: menuAnchor.close()
    }
}
```

> Note: `QsMenuAnchor.anchor.rect` positioning needs to be computed from the clicked icon's bounding rectangle in the parent window's coordinate space. Use `mapToItem(Window.window.contentItem, 0, 0)` on the icon's parent Item inside `onClicked` to get the (x, y) for `anchor.rect.x/y`. This is implementation detail per D-43.

### Anti-Patterns to Avoid

- **Don't import `Quickshell.Services.*` from widgets** — D-54: widgets only import `qs.theme` and `qs.services`. Service singletons are the single chokepoint.
- **Don't read `defaultSink.audio.volume` without an active `PwObjectTracker`** — P-04: the property returns invalid/null without tracker binding. The `AudioService` singleton holds the tracker; widgets read through `AudioService.volume`.
- **Don't use `playPause()` on MprisPlayer** — does not exist. Use `togglePlaying()`.
- **Don't use `trackArtists` (plural)** — deprecated. Use `trackArtist` (singular).
- **Don't import `IconImage` from `Quickshell`** — it lives in `Quickshell.Widgets`.
- **Don't open the Hyprland IPC socket directly** — P-09. Use `Hyprland.workspaces`, `Hyprland.dispatch`, `Hyprland.rawEvent`.
- **Don't use `grabFocus: true`** — P-01. Use `HyprlandFocusGrab` for tray menu dismiss.
- **Don't use `opacity: 0` to hide widgets** — P-03. Use `visible: false` (D-51). This is already the convention; flagged for completeness.
- **Don't call `Hyprland.dispatch("workspace 1")` for activation** — D-16: prefer the workspace-object's `.activate()` because it is monitor-aware.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| MPRIS metadata polling | `Process { command: ["playerctl", "metadata", ...] }` + Timer | `Quickshell.Services.Mpris` | D-Bus signals; zero polling latency; deprecation of playerctl in favor of native binding |
| Workspace state watcher | Raw socket reads on `~/.config/hypr/hyprland-X.sock` | `Hyprland.workspaces` | P-09: socket path changes on compositor reload |
| Audio sink reader | `Process { command: ["pactl", "get-sink-volume", ...] }` | `Pipewire.defaultAudioSink.audio.volume` | Async polling vs sync property; P-04 covers correct binding |
| SNI tray bridging | DBus IPC parsing of `org.kde.StatusNotifierWatcher` | `SystemTray.items` ObjectModel | Quickshell handles full SNI spec including category/status enums |
| Native context menu rendering | Custom QML menu composing `MenuItem`s from `item.menu` recursively | `QsMenuAnchor` | Handles submenus, separators, icons, keyboard nav for free |
| Outside-click popup dismiss | `MouseArea { anchors.fill: parent }` overlay or Hyprland `bind` | `HyprlandFocusGrab` | P-01: native protocol-level dismiss; doesn't steal keyboard focus |
| Wheel-event step quantization | Custom debounce timer | `Math.sign(wheel.angleDelta.y) * step` | D-25: Qt already quantizes detents to 120 units |

**Key insight:** Every native API in this phase has a Quickshell-side wrapper that hides the messy parts (D-Bus reconnection, socket-path discovery, PipeWire object lifecycle, SNI menu marshalling). Bypassing them to use raw IPC or Process recreates bugs that Quickshell already solved.

## Common Pitfalls

### Pitfall 1: PwObjectTracker not alive when widget reads .audio
**What goes wrong:** `AudioService.volume` returns 0/false/undefined silently; UI shows "0%" forever.
**Why it happens:** The `PwObjectTracker` was placed inside a Loader or Component that hasn't instantiated; or the tracker was destroyed before the property read.
**How to avoid:** Place `PwObjectTracker` directly inside the `Singleton` body so it lives as long as the singleton (P-04). Bind `objects` to a reactive expression that follows `defaultSink` — including the empty-array fallback `[]` when `defaultSink` is null, so the tracker stays alive but tracks nothing.
**Warning signs:** `volume` and `muted` always read identical default values; clicking volume widget does nothing.

### Pitfall 2: `Hyprland.dispatch` returns synchronously but state read is stale
**What goes wrong:** Right after `Hyprland.dispatch("workspace e+1")`, `Hyprland.workspaces.values` may not yet reflect the new active workspace.
**Why it happens:** Dispatch is fire-and-forget; the workspace-changed event arrives asynchronously.
**How to avoid:** Bind UI to `ws.active` reactively; never read state synchronously after dispatch. Trust the event loop.
**Warning signs:** A workspace highlight visibly lags behind the dispatch by one frame — that's expected and acceptable.

### Pitfall 3: `IconImage` source = `item.icon` shows blank for some apps
**What goes wrong:** Some SNI apps (notably older ones) provide only `iconPixmap` (a raw RGBA blob), not `iconName` (a freedesktop icon theme name). Quickshell's `item.icon` should expose a `image://` URI that handles both, but specific theme misses can occur.
**Why it happens:** Icon theme lookup miss; missing `Pixmap` decoding for legacy apps. P-12 covers this.
**How to avoid:** Set `IconImage.asynchronous: true` (avoids blocking); implement D-44 fallback (Nerd Font glyph as Text on `IconImage.status === Image.Error`). Test with the actual tray apps you run.
**Warning signs:** Icon area is empty but `item.title` renders fine; check `iconImg.status` for `Image.Error`.

### Pitfall 4: P-15 Variants delegate cleanup
**What goes wrong:** Per Phase 12 already-merged code, `BarContent.qml` is the Variants delegate. When a monitor disconnects, the delegate is destroyed — any `Process` instance, Timer, or popup in Phase 13 widgets must clean up.
**Why it happens:** Quickshell uses standard QML object lifecycle; nothing magic.
**How to avoid:** No long-running Timers in Phase 13 widgets (none planned). The `Process` instances in widgets are short-lived (`startDetached` returns immediately). `QsMenuAnchor` and `HyprlandFocusGrab` are owned by their parent widget — they're cleaned up automatically on widget destruction. No explicit `Component.onDestruction` hooks needed for Phase 13.
**Warning signs:** Hot-unplug a monitor; check `quickshell` stderr for warnings about dangling QObjects.

### Pitfall 5: P-16 keyboard focus stolen by tray menu
**What goes wrong:** When the tray menu opens, it can steal keyboard focus from the focused application (e.g. user typing in Neovim hits Esc and Esc lands in the menu instead).
**Why it happens:** `grabFocus: true` was historically the only way to dismiss-on-outside-click; it grabs keyboard.
**How to avoid:** D-43 mandates `HyprlandFocusGrab` (NOT `grabFocus: true`). The bar PanelWindow already has `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None` (Phase 12, BarContent.qml:22). The menu opens via `QsMenuAnchor.open()` and dismisses via `HyprlandFocusGrab.cleared`.
**Warning signs:** Open tray menu, then press Esc with focused app expected to receive the keystroke — if Esc closes the menu instead of the app, focus was stolen.

### Pitfall 6: P-18 Process firing in Component.onCompleted
**What goes wrong:** `Process { running: true }` declared statically would fire before bar fully initializes.
**Why it happens:** Phase 13 widgets DO declare inline `Process` instances (D-47), but they all use `running: false` + imperative `.startDetached()` triggered by user click — never `running: true`. So P-18 does not apply directly here. Flagged because the pattern is template-similar.
**How to avoid:** Always set `running: false` in declaration; trigger via `.startDetached()` or `.running = true` from a handler.

### Pitfall 7: ObjectModel iteration uses `.values`, not direct array access
**What goes wrong:** `Mpris.players.find(...)` or `Hyprland.workspaces.filter(...)` throws or returns wrong type.
**Why it happens:** ObjectModel is a Qt model, not a JS array. The `.values` getter returns a JS array snapshot.
**How to avoid:** Always use `.values` for `.find` / `.filter` / `.slice` / `.length`. For Repeater, model can take the ObjectModel directly. CONTEXT.md D-07 and D-10 already use `.values` correctly.
**Warning signs:** TypeError "X is not a function" in QML console.

## Runtime State Inventory

> Phase 13 is greenfield (creates new files; modifies one). No rename/refactor/migration scope. Section omitted per template.

## Code Examples

### Example 1: services/qmldir registration
```
# .config/quickshell/services/qmldir
# Source: matches Phase 12 .config/quickshell/theme/qmldir pattern [VERIFIED]
singleton AudioService     1.0 AudioService.qml
singleton MprisService     1.0 MprisService.qml
singleton HyprWorkspaces   1.0 HyprWorkspaces.qml
```

### Example 2: widgets/qmldir registration (non-singleton)
```
# .config/quickshell/widgets/qmldir
WorkspacesWidget 1.0 WorkspacesWidget.qml
VolumeWidget     1.0 VolumeWidget.qml
MusicWidget      1.0 MusicWidget.qml
TrayWidget       1.0 TrayWidget.qml
```

### Example 3: BarContent.qml — Phase 13 placeholder swap
```qml
// BarContent.qml (modified — replace placeholder ModulePill blocks)
// Source: existing file at .config/quickshell/BarContent.qml lines 50-88 [VERIFIED via Read]
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.theme
import qs.widgets         // NEW

PanelWindow {
    // … D-04, D-05, D-11, D-12, P-16 unchanged …

    RowLayout {
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 4 }
        spacing: 0

        BarGroup { WorkspacesWidget {} }                    // left
        Item { Layout.fillWidth: true }
        BarGroup { /* center empty — Phase 14 fills */ }
        Item { Layout.fillWidth: true }
        BarGroup { MusicWidget {}; VolumeWidget {}; TrayWidget {} }   // right (D-56)
    }
}
```

### Example 4: ModulePill `default property alias` usage
```qml
// ModulePill.qml exposes `default property alias content: inner.children`
// Source: .config/quickshell/ModulePill.qml [VERIFIED via Read].
// Usage in widgets: drop content directly inside the ModulePill braces.
ModulePill {
    Row { /* this Row becomes the pill's child */ }
}
```

### Example 5: Hyprland.dispatch syntax for scroll
```qml
// Source: quickshell.org/docs/types/Quickshell.Hyprland/Hyprland [VERIFIED]
import Quickshell.Hyprland
// …
onWheel: wheel => {
    // angleDelta.y > 0 means wheel-up; y < 0 means wheel-down.
    // D-18: wheel-down = next, wheel-up = previous; e+1 / e-1 wraps around empty.
    if (wheel.angleDelta.y < 0) Hyprland.dispatch("workspace e+1")
    else                        Hyprland.dispatch("workspace e-1")
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `playerctl metadata` polling via Process every 5s | `Mpris.players` reactive ObjectModel | Quickshell pre-0.2.0 | D-Bus signals replace polling — instant updates |
| Raw Hyprland socket reads | `Quickshell.Hyprland` module | Quickshell 0.1.x → 0.2.x | Auto-reconnect on compositor restart; no socket path discovery |
| `pactl get-sink-volume` Process | `Pipewire.defaultAudioSink.audio.volume` direct read | Quickshell 0.2.0 added Pipewire service | Property binding replaces polling; PwObjectTracker required |
| `MprisPlayer.playPause()` (legacy) | `MprisPlayer.togglePlaying()` | At/before 0.1.0 | Method renamed; CONTEXT.md D-31 needs the corrected name |
| `MprisPlayer.trackArtists` (plural) | `MprisPlayer.trackArtist` (singular) | Pre-0.2.0 | The plural form is documented as deprecated in favor of singular [VERIFIED]; CONTEXT.md D-29 needs the corrected property |
| `IconImage` in `Quickshell` namespace (some examples online) | `IconImage` in `Quickshell.Widgets` | Reorganization at some 0.2.x point | Import path is `import Quickshell.Widgets` |

**Deprecated/outdated:**
- `playerctl` for MPRIS in QML shells.
- Direct Hyprland socket reads.
- `playPause()` (use `togglePlaying()`).
- `trackArtists` plural (use `trackArtist`).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CONTEXT.md D-29 references `activePlayer.{title, artists}`; the canonical Quickshell API uses `trackTitle` and `trackArtist`. The intent (display artist + title) is preserved by mapping property names | User Constraints D-29; Pattern 6 | Implementation would not compile if D-29 is taken literally; planner must use the corrected names. Source: [VERIFIED quickshell.org/docs/v0.2.1/types/Quickshell.Services.Mpris/MprisPlayer] — `trackArtists` is documented as deprecated in favor of `trackArtist`. |
| A2 | CONTEXT.md D-31 references `player.playPause()`; the canonical method is `togglePlaying()` | User Constraints D-31; Pattern 6 | Implementation would not compile. Source: [VERIFIED] — only `play()`, `pause()`, `stop()`, `togglePlaying()`, `next()`, `previous()` are exposed. |
| A3 | CONTEXT.md D-36 says `Quickshell IconImage`; the import path is `import Quickshell.Widgets` (not `import Quickshell`) | User Constraints D-36; Pattern 7 | Compile failure. Source: [VERIFIED quickshell.org/docs/master/types/Quickshell.Widgets/IconImage]. |
| A4 | D-13 implies an "occupied" state distinct from "active" requires reading `.toplevels` on `HyprlandWorkspace`. The `HyprlandWorkspace` documentation page lists only `id, name, lastIpcObject, active, focused, hasFullscreen, monitor` — no `toplevels` property surfaced. `hasFullscreen` is documented but is not a true "has any toplevels" signal | Phase Requirements WS-02 | Without a documented `toplevels` accessor, the planner has three options: (a) treat all listed workspaces as "occupied" (simplest, since `Hyprland.workspaces` only includes workspaces with at least one client per Hyprland convention), (b) parse `lastIpcObject` after `Hyprland.refreshWorkspaces()`, (c) maintain a count via rawEvent listening (`openwindow`/`closewindow` events). Recommend (a) for Phase 13: in Hyprland, an empty workspace that is not the focused one is automatically destroyed by the compositor — so any workspace appearing in the model is by definition occupied OR is the currently-focused workspace. Implication: subtextColor for empty effectively only applies to the focused-but-empty workspace. The planner should pick (a) and document this nuance. |
| A5 | D-15 says "prefer `ws.urgent` if Quickshell exposes it; else derive from toplevels". The HyprlandWorkspace documentation does not surface a `urgent` property. Therefore the canonical path is `Hyprland.rawEvent` listening to the `urgent` event channel, with a Set of urgent ids stored in the `HyprWorkspaces` service. Cleared when the workspace becomes focused | Phase Requirements WS-02; Pattern 3 | If the rawEvent payload format differs from `urgent>>WORKSPACE_ID`, the parser breaks. Hyprland documents this event format as `urgent>>WINDOW_ADDRESS` (window, not workspace) — researcher could not verify final shape against runtime. Planner should sanity-check by adding a `console.log` on rawEvent during testing, then map window address to workspace via `Hyprland.toplevels` lookup if needed. Treat the urgent indicator as best-effort for Phase 13 UAT; defer to post-UAT iteration if event mapping is wrong. |
| A6 | CONTEXT.md says `MprisPlayer.playbackState === 'Playing'` (string compare). The current API returns a `MprisPlaybackState` enum, not a string | Pattern 2 | Comparison would fail. Use `MprisPlaybackState.Playing` (or rely on the convenience `isPlaying` property). Source: [VERIFIED quickshell.org/docs/v0.2.1/types/Quickshell.Services.Mpris/MprisPlayer] — `playbackState` is `MprisPlaybackState` enum; `isPlaying` is a boolean convenience. |
| A7 | `QsMenuAnchor.anchor.rect` requires explicit (x, y, width, height) computation against the bar window's content item. The clicked tray icon must `mapToItem(Window.window.contentItem, 0, 0)` to produce coords | Pattern 7 | If anchor is computed in widget-local coordinates, menu appears at wrong location. Source: [CITED quickshell.org/docs/types/Quickshell/QsMenuAnchor — anchor.rect is in window space]. |
| A8 | `Process.startDetached()` for pavucontrol is non-blocking and ignores stdout/stderr | Pattern 5 | If the user wants to surface "pavucontrol not installed" warnings, the inline Process pattern with `running: true` + `onExited` handler must be used instead of `.startDetached()`. D-23 chooses startDetached + the `onExited` on a non-detached helper would not fire — accept that pavucontrol failure will be silent. |
| A9 | Each `BarContent` Variants delegate instantiates its own `TrayWidget`, meaning each monitor has its own `QsMenuAnchor` and its own `HyprlandFocusGrab` instance. The menu opens against the bar of the clicked monitor only | Pattern 7 | Per-monitor menu instances are correct; no shared state needed. Confirm by visual UAT D-57. |

## Open Questions

1. **What signals an "occupied" workspace beyond active/focused?**
   - What we know: `HyprlandWorkspace` documentation surfaces `hasFullscreen` but not a `toplevels` count or `windowCount`.
   - What's unclear: whether reading `lastIpcObject.windows` (after a `refreshWorkspaces()` call) is the canonical approach, or whether tracking via `Hyprland.toplevels` ObjectModel + filter is preferred.
   - Recommendation: Adopt A4 path (a) — every listed workspace is treated as occupied; subtextColor only renders for the focused-but-empty workspace. Quickest path to Phase 13 UAT; acceptable visual fidelity. Defer richer occupancy to a Phase 16 polish ticket if user reports inadequate distinction.

2. **What is the exact rawEvent format for urgent?**
   - What we know: `Hyprland.rawEvent` is the canonical channel for events; the Hyprland IPC `urgent` event includes a window address.
   - What's unclear: whether Quickshell pre-parses the address or if the workspace id must be derived via `toplevels` mapping.
   - Recommendation: During Phase 13 implementation, add temporary `console.log` on rawEvent to verify payload shape before finalizing `HyprWorkspaces.urgentIds` logic. If complex, accept that the urgent indicator may be approximate for v1.2 UAT.

3. **Is `Mpris.players` ObjectModel iterable inside a binding without `.values`?**
   - What we know: `Repeater { model: Mpris.players }` works directly (ObjectModel is a Qt model). `.values` is required for `.find` / `.filter`.
   - Confirmed via [VERIFIED] docs. No further action needed.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `quickshell` | All four widgets | ✓ | 0.2.1-6 | none |
| Quickshell.Hyprland module | WorkspacesWidget | ✓ | bundled | none |
| Quickshell.Services.Pipewire module | VolumeWidget, AudioService | ✓ | bundled | none |
| Quickshell.Services.Mpris module | MusicWidget, MprisService | ✓ | bundled | none |
| Quickshell.Services.SystemTray module | TrayWidget | ✓ | bundled | none |
| Quickshell.Widgets module (IconImage) | TrayWidget | ✓ | bundled | Fallback to `Image { source: item.icon }` if needed |
| `pipewire` daemon | AudioService runtime | ✓ | running (PID 1601) | none |
| `wireplumber` | PipeWire session manager | ✓ | running (PID 1602) | pipewire-media-session (not present) |
| `pavucontrol` | Volume click handler | ✓ | installed at `/usr/bin/pavucontrol` | If absent, click is a no-op + `console.warn` |
| `hyprctl` / Hyprland compositor | Workspaces widget context | ✓ | Hyprland 0.54.3 | none |
| `swaync` | NOT required by Phase 13 | ✓ (running PID 1711) | — | n/a |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None — fully provisioned.

## Validation Architecture

> `nyquist_validation: true` in `.planning/config.json` — section included.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual visual UAT (D-57). No automated QML test harness. The repo has zero Quickshell/QML test infrastructure today. |
| Config file | `.planning/phases/13-native-api-widgets/13-HUMAN-UAT.md` (created during plan) |
| Quick run command | `quickshell &` (manual launch) — running from CLI to inspect stderr |
| Full suite command | `quickshell` + the manual D-57 checklist below |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| WS-01 | Workspaces widget shows all current workspaces; reactive | manual visual | n/a (visual) | UAT — Wave 0 |
| WS-02 | Active=Mauve; occupied vs empty distinct; urgent distinct | manual visual | n/a — observe color states across workspace switches; trigger urgent via `notify-send` from a non-focused workspace | UAT — Wave 0 |
| WS-03 | Click activates; scroll cycles | manual interactive | observe; verify `e+1`/`e-1` wrap | UAT — Wave 0 |
| AUDIO-01 | Volume %+mute reflect PipeWire default sink; click opens pavucontrol | manual interactive | scroll wheel adjusts; right-click toggles mute; left-click launches pavucontrol; `pactl set-sink-volume @DEFAULT_SINK@ 50%` external — bar widget updates | UAT — Wave 0 |
| AUDIO-03 | Music shows artist+title; click toggles play/pause; hidden when no player | manual interactive | open Spotify or any MPRIS source; widget appears; click toggles; close player; widget hides | UAT — Wave 0 |
| TRAY-01 | SNI icons render; right-click opens context menu | manual interactive | observe icons for running tray apps (swaync, network applet, etc.); right-click → menu opens; outside-click dismisses | UAT — Wave 0 |

**QML smoke test (planner discretion):** A minimal `quickshell --check` run during install in CI is not currently scoped, but a `qmllint` pass over the new files would catch syntax errors:
```bash
qmllint .config/quickshell/services/*.qml .config/quickshell/widgets/*.qml
```
qmllint is part of the Qt 6 SDK; verify availability before relying on it.

### Sampling Rate
- **Per task commit:** Visual sanity — relaunch quickshell, verify widget renders without QML console errors.
- **Per wave merge:** Run the D-57 manual checklist against the merged worktree.
- **Phase gate:** Full D-57 UAT pass before `/gsd-verify-work`. All 6 requirement IDs ✓.

### Wave 0 Gaps
- [ ] `13-HUMAN-UAT.md` — UAT checklist file derived from D-57 (per-widget verification steps).
- [ ] `qmllint` availability check — confirm `qmllint --version` exists in the dev environment; if not, no replacement.
- [ ] No new framework install needed — manual visual UAT is the only test mode for Phase 13.

## Project Constraints (from CLAUDE.md)

No `CLAUDE.md` exists in the repo root [VERIFIED: `ls /home/pera/github_repo/.dotfiles/CLAUDE.md` → not found]. No project-level skills directory found at `.claude/skills/` or `.agents/skills/`. Phase 13 is governed exclusively by CONTEXT.md decisions and `.planning/research/*.md`.

## Security Domain

> `security_enforcement` is not set in `.planning/config.json` — defaulting to enabled. Phase 13 is a UI/widget phase with limited attack surface; the relevant ASVS categories are minimal.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 13 has no auth flow. |
| V3 Session Management | no | No sessions. |
| V4 Access Control | no | All operations are local user actions on the user's own session. |
| V5 Input Validation | partial | `Process.command` arrays are static literals (no user-supplied input concatenated). `Hyprland.dispatch` argument is a static string `"workspace e+1"` / `"e-1"`. No injection risk. |
| V6 Cryptography | no | No crypto operations. |

### Known Threat Patterns for QML/Quickshell stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Command injection via `Process.command` | Tampering | All Process commands in Phase 13 are static literals (`["pavucontrol"]`). No interpolation of MPRIS metadata or workspace names into shell commands. |
| Untrusted MPRIS metadata in tooltip text | Information disclosure | Metadata is rendered via QML `Text { text: ... }` — no HTML/Pango interpretation by default. Verify `text` properties do NOT enable `textFormat: Text.RichText` (default is `Text.PlainText` which is safe). |
| SNI tray icon URI from untrusted DBus client | Tampering | `IconImage.source` accepts arbitrary URIs from SNI clients. Quickshell's icon resolution is sandboxed to `image://` providers; a malicious icon URI cannot read arbitrary local files. P-12 covers fallback. |
| HyprlandFocusGrab not engaged → tray menu becomes "phantom" hit-area | Repudiation/UX | D-43: HyprlandFocusGrab is mandatory; covered by Pattern 7. |

## Sources

### Primary (HIGH confidence)
- `https://quickshell.org/docs/types/Quickshell.Hyprland/Hyprland/` — Hyprland singleton properties + `dispatch()` example [VERIFIED]
- `https://quickshell.org/docs/types/Quickshell.Hyprland/HyprlandWorkspace/` — workspace properties + `activate()` [VERIFIED]
- `https://quickshell.org/docs/types/Quickshell.Hyprland/HyprlandFocusGrab/` — windows + active + cleared() signal [VERIFIED]
- `https://quickshell.org/docs/types/Quickshell.Services.Pipewire/PwObjectTracker/` — usage pattern, objects array [VERIFIED]
- `https://quickshell.org/docs/types/Quickshell.Services.Pipewire/` (Pipewire singleton) — defaultAudioSink, ready, tracker requirement [VERIFIED]
- `https://quickshell.org/docs/v0.2.1/types/Quickshell.Services.Mpris/MprisPlayer/` — full property list and method names; `togglePlaying`, `trackArtist` [VERIFIED]
- `https://quickshell.org/docs/types/Quickshell.Services.Mpris/Mpris/` — `players` is `ObjectModel<MprisPlayer>` readonly [VERIFIED]
- `https://quickshell.org/docs/types/Quickshell.Services.SystemTray/SystemTrayItem/` — properties + methods [VERIFIED]
- `https://quickshell.org/docs/types/Quickshell/QsMenuAnchor/` — anchor.window/rect, open()/close() [VERIFIED]
- `https://quickshell.org/docs/master/types/Quickshell.Widgets/IconImage/` — source, implicitSize, asynchronous, backer; lives in `Quickshell.Widgets` [VERIFIED]
- `https://quickshell.org/docs/types/Quickshell.Io/Process/` — startDetached, command array literal, P-06 absence note [VERIFIED]
- Local: `/home/pera/github_repo/.dotfiles/.config/quickshell/{shell,Bar,BarContent,BarGroup,ModulePill}.qml` and `theme/Colours.qml`, `theme/qmldir` — Phase 12 carryover [VERIFIED via Read]
- Local: `/home/pera/github_repo/.dotfiles/.planning/research/{ARCHITECTURE,PITFALLS,SUMMARY}.md` — established project patterns [VERIFIED via Read]
- Runtime: `pacman -Q quickshell` → 0.2.1-6; `pgrep pipewire wireplumber` → running; `command -v pavucontrol` → installed [VERIFIED]

### Secondary (MEDIUM confidence)
- `https://deepwiki.com/quickshell-mirror/quickshell/5.3-mpris-media-player-control` — confirms `trackArtist` is the canonical property and joins the `xesam:artist` array internally [CITED]
- `https://wiki.archlinux.org/title/MPRIS` — MPRIS spec context for D-Bus interface [CITED]

### Tertiary (LOW confidence)
- Hyprland `urgent` rawEvent payload shape — researcher could not verify whether the event carries a window address or workspace id directly. A5 flags this; planner should add temporary `console.log` during implementation to confirm before finalizing the urgent-id parsing logic in `HyprWorkspaces`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every package and module verified via runtime probe + official docs.
- Architecture: HIGH — directly extends Phase 12 patterns (theme/qmldir, pragma Singleton); service/widget split is established in `.planning/research/ARCHITECTURE.md`.
- Pitfalls: HIGH — pitfalls cross-referenced to `.planning/research/PITFALLS.md` P-01, P-04, P-09, P-12, P-15, P-16, P-18.
- API method/property names: HIGH for current API — but contradicts CONTEXT.md D-29 (artists vs trackArtist) and D-31 (playPause vs togglePlaying). Both flagged in Assumptions Log A1, A2 for planner correction.
- Workspace urgent + occupied detection: MEDIUM — see A4, A5; runtime verification needed.

**Research date:** 2026-05-03
**Valid until:** 2026-06-03 (30 days; Quickshell 0.2.x is stable, Hyprland 0.54.x is stable)
