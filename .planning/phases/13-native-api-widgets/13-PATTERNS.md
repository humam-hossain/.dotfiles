# Phase 13: Native API Widgets — Pattern Map

**Mapped:** 2026-05-03
**Files analyzed:** 11 (10 new, 1 modified)
**Analogs found:** 9 / 11 (2 services have NO in-repo analog — see No Analog Found section)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.config/quickshell/services/qmldir` | qmldir manifest | static registration | `.config/quickshell/theme/qmldir` | exact |
| `.config/quickshell/services/AudioService.qml` | service singleton | PipeWire pub-sub (PwObjectTracker → reactive properties) | `.config/quickshell/theme/Colours.qml` | role-match (Singleton + pragma only; no PipeWire analog in-repo) |
| `.config/quickshell/services/MprisService.qml` | service singleton | MPRIS D-Bus → reactive `activePlayer` | `.config/quickshell/theme/Colours.qml` | role-match |
| `.config/quickshell/services/HyprWorkspaces.qml` | service singleton | Hyprland IPC + rawEvent → sorted/filtered list + urgent Set | `.config/quickshell/theme/Colours.qml` | role-match |
| `.config/quickshell/widgets/qmldir` | qmldir manifest (non-singleton) | static registration | `.config/quickshell/theme/qmldir` | role-match (qmldir form, but non-singleton entries) |
| `.config/quickshell/widgets/WorkspacesWidget.qml` | widget root | Hyprland IPC (read) + dispatch (write) | `.config/quickshell/BarContent.qml` (placeholder ModulePill block lines 50-59) | role-match (composes ModulePill + Text per Phase 12 pattern) |
| `.config/quickshell/widgets/VolumeWidget.qml` | widget root | PipeWire (read/write) + Process (pavucontrol) | `.config/quickshell/BarContent.qml` (placeholder ModulePill block lines 50-59) | role-match |
| `.config/quickshell/widgets/MusicWidget.qml` | widget root | MPRIS (read + togglePlaying) | `.config/quickshell/BarContent.qml` (placeholder ModulePill block lines 50-59) | role-match |
| `.config/quickshell/widgets/TrayWidget.qml` | widget root | SystemTray SNI (read) + QsMenuAnchor + HyprlandFocusGrab | `.config/quickshell/BarContent.qml` (placeholder ModulePill block lines 50-59) | role-match (no SNI/menu analog in-repo) |
| `.config/quickshell/BarContent.qml` (MODIFY) | layout composer | static composition | `.config/quickshell/BarContent.qml` (self — replace placeholder content) | exact (in-place edit) |

Quality legend:
- **exact** — same role AND same data flow.
- **role-match** — same role, different (or new) data flow. Use the analog for structure (imports, file shape, Singleton wrapping, ModulePill composition) and pull data-flow code from RESEARCH.md Patterns 1–7.
- Phase 13 is greenfield for service singletons that bind to Quickshell.Services.* — there is **no in-repo PipeWire/MPRIS/SystemTray usage today**. The closest singleton analog (`Colours.qml`) provides the singleton scaffolding only; the body of each new service is taken from RESEARCH.md.

---

## Pattern Assignments

### `.config/quickshell/services/qmldir` (qmldir manifest)

**Analog:** `.config/quickshell/theme/qmldir` (1 line, exact form)

**Existing analog content** (line 1):
```
singleton Colours Colours.qml
```

**Pattern to copy:** one line per singleton, form `singleton TypeName FileName.qml`. No version qualifier is used in the Phase 12 file (matches the in-repo convention). RESEARCH.md Example 1 includes a `1.0` version — **prefer the in-repo Phase 12 form (no version)** for consistency.

**Concrete content to write** (3 lines):
```
singleton AudioService AudioService.qml
singleton MprisService MprisService.qml
singleton HyprWorkspaces HyprWorkspaces.qml
```

---

### `.config/quickshell/services/AudioService.qml` (service singleton, PipeWire)

**Analog (structure only):** `.config/quickshell/theme/Colours.qml` lines 1-5 (`pragma Singleton` + `import` + `Singleton { ... }` body)

**Analog excerpt — Singleton scaffolding** (lines 1-5):
```qml
pragma Singleton
import Quickshell
import QtQuick

Singleton {
```

**Pattern to copy from analog:**
1. First line is `pragma Singleton` (no leading imports).
2. Imports are alphabetical-ish: `Quickshell` first, then `QtQuick`.
3. Root QML object is `Singleton { ... }` (capital S — Quickshell type).
4. Properties prefer `readonly property` for derived/exposed values (matches Colours.qml style throughout, e.g. lines 7-32).
5. No closing-comment / sentinel — file ends on the Singleton brace.

**Body pattern (NO in-repo analog — sourced from RESEARCH.md Pattern 1, lines 263-295):**
```qml
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

    PwObjectTracker {
        objects: root.defaultSink ? [root.defaultSink] : []
    }
}
```

**Null-guard pattern (D-04):** every derived `readonly property` short-circuits on `defaultSink` being null. Same idiom as Colours' computed aliases (e.g. line 35 `barBg: surface0` is unconditional because base values are guaranteed; PipeWire props need the guard because `defaultSink` is initially null on cold start).

**Pitfall to honor:** RESEARCH.md Pitfall 1 (PwObjectTracker must live inside the Singleton body, NOT inside a Loader/Component). The Pattern-1 excerpt above already places the tracker as a direct child of `Singleton { ... }`.

---

### `.config/quickshell/services/MprisService.qml` (service singleton, MPRIS D-Bus)

**Analog (structure only):** `.config/quickshell/theme/Colours.qml` lines 1-5

**Body pattern (NO in-repo analog — sourced from RESEARCH.md Pattern 2, lines 305-322 + Assumption A6 correction):**
```qml
pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    readonly property var activePlayer: {
        const list = Mpris.players.values
        if (!list || list.length === 0) return null
        const playing = list.find(p => p.playbackState === MprisPlaybackState.Playing)
        return playing ?? list[0]
    }
    readonly property bool hasPlayer: activePlayer !== null
}
```

**Critical corrections (RESEARCH.md Assumptions A1, A2, A6):**
- Use `MprisPlaybackState.Playing` (enum), NOT the string `'Playing'` from CONTEXT.md D-07.
- Widgets that consume this service must use `trackArtist` (singular) and `trackTitle`, not `artists` / `title` from CONTEXT.md D-29.
- Widgets must call `togglePlaying()`, not `playPause()` from CONTEXT.md D-31.

---

### `.config/quickshell/services/HyprWorkspaces.qml` (service singleton, Hyprland IPC)

**Analog (structure only):** `.config/quickshell/theme/Colours.qml` lines 1-5

**Body pattern (NO in-repo analog — sourced from RESEARCH.md Pattern 3, lines 334-379):**
```qml
pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    readonly property var workspaces: Hyprland.workspaces.values
        .slice()
        .sort((a, b) => a.id - b.id)
        .filter(w => w.id >= 0 && !(w.name && w.name.startsWith("special:")))

    property var urgentIds: ({})

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "urgent") {
                const id = parseInt(event.data, 10)
                if (!isNaN(id)) {
                    const next = Object.assign({}, root.urgentIds)
                    next[id] = true
                    root.urgentIds = next
                }
            } else if (event.name === "workspace" || event.name === "focusedmon") {
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

**Open question to resolve at implementation (RESEARCH.md A5 + Open Question 2):** `event.data` payload format for `urgent` is unverified. Add temporary `console.log` during first implementation pass to confirm. If the payload is a window address (not a workspace id), map via `Hyprland.toplevels` lookup. Treat the urgent indicator as best-effort for Phase 13 UAT.

---

### `.config/quickshell/widgets/qmldir` (qmldir manifest, non-singleton)

**Analog:** `.config/quickshell/theme/qmldir`

**Pattern to copy:** same form as theme/qmldir but WITHOUT the `singleton` keyword (widgets are instantiable, not singletons).

**Concrete content to write** (4 lines):
```
WorkspacesWidget WorkspacesWidget.qml
VolumeWidget VolumeWidget.qml
MusicWidget MusicWidget.qml
TrayWidget TrayWidget.qml
```

(RESEARCH.md Example 2 includes `1.0` version qualifiers; Phase 12 in-repo qmldir omits them — **omit them here for consistency**.)

---

### `.config/quickshell/widgets/WorkspacesWidget.qml` (widget root, Hyprland IPC + dispatch)

**Analog (visual + structural):** `.config/quickshell/BarContent.qml` lines 50-59 (the left placeholder ModulePill block)

**Analog excerpt — ModulePill + Text composition** (lines 50-59):
```qml
BarGroup {
    ModulePill {
        Text {
            text:           "Left"        // D-01 placeholder
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold:      true
            color:          Colours.textColor
        }
    }
}
```

**Patterns to copy from analog:**
1. **Font block** (every widget Text node) — `font.family: "JetBrainsMono Nerd Font"`, `font.pixelSize: 14`, `font.bold: true`. Copy verbatim.
2. **Color binding** — `color: Colours.<semanticAlias>`. Phase 13 uses three aliases for workspaces: `Colours.accent`, `Colours.textColor`, `Colours.subtextColor` (per UI-SPEC State Inventory and CONTEXT.md D-13).
3. **ModulePill as direct child of BarGroup** — Phase 13 widget IS the ModulePill (root component is `ModulePill { ... }` per RESEARCH.md Pattern 4).

**Imports pattern (RESEARCH.md Pattern 4 lines 387-390):**
```qml
import QtQuick
import Quickshell.Hyprland
import qs.theme
import qs.services
import "../" as Local   // for ModulePill — sibling-directory import
```

**Body pattern (sourced from RESEARCH.md Pattern 4, lines 392-430, with A4 nuance applied for the empty-vs-occupied color):**
```qml
Local.ModulePill {
    id: root
    Row {
        spacing: 8                            // UI-SPEC §Spacing — workspace-button gap
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
                         : Colours.textColor                      // A4(a): treat all listed as occupied
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

**Glyph codepoints (UI-SPEC §Typography table):** active = U+F444 (``), default = U+F4C3 (``).

**Per-monitor active highlight (D-12):** `modelData.active` already evaluates per-monitor (Hyprland's `active` is per-monitor). No additional logic needed in the widget.

---

### `.config/quickshell/widgets/VolumeWidget.qml` (widget root, PipeWire + Process)

**Analog (visual + structural):** `.config/quickshell/BarContent.qml` lines 65-73 (center placeholder ModulePill block — same shape as left)

**Patterns to copy from analog:**
- Same font block, ModulePill-as-root, Colours.* binding pattern as WorkspacesWidget.

**Imports pattern (RESEARCH.md Pattern 5 lines 437-442):**
```qml
import QtQuick
import Quickshell.Io                     // Process
import qs.theme
import qs.services
import "../" as Local
```

**Body pattern (sourced from RESEARCH.md Pattern 5, lines 444-498):**
```qml
Local.ModulePill {
    id: root
    visible: AudioService.defaultSink !== null

    Row {
        spacing: 4                              // UI-SPEC: icon ↔ text 4px tight pairing
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

**Volume-icon glyphs (UI-SPEC §Typography):** muted/0% = U+F026, <33% = U+F027, <66% = U+F027 (or U+FA7D — per UI-SPEC, default is the same low-volume glyph for visual continuity with Waybar), ≥66% = U+F028.

**Mute compound visual (D-22):** swap glyph AND drop opacity to 0.6 — both must apply simultaneously.

**Pavucontrol caveat (RESEARCH.md A8):** `startDetached()` ignores stdout/stderr; the `onExited` handler will NOT fire on detached processes. The handler is included here because the original Pattern includes it; pruning it is a planner discretion (CONTEXT.md D-48 logging policy applies to non-detached spawns).

---

### `.config/quickshell/widgets/MusicWidget.qml` (widget root, MPRIS)

**Analog (visual + structural):** `.config/quickshell/BarContent.qml` lines 78-87 (right placeholder ModulePill block)

**Imports pattern (RESEARCH.md Pattern 6 lines 504-508):**
```qml
import QtQuick
import qs.theme
import qs.services
import "../" as Local
```

**Body pattern (sourced from RESEARCH.md Pattern 6, lines 510-545; uses corrected `trackArtist`/`trackTitle`/`togglePlaying` per A1, A2):**
```qml
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

**Music glyph (UI-SPEC §Typography):** U+F1BC (``) — Spotify-style glyph used in Waybar's `custom/music` config.

**Truncation (D-30, UI-SPEC):** 30 chars with `Text.elide: Text.ElideRight`. The Pattern uses `substring(0, 29) + "…"` for the eager-truncate path; QML's `elide` handles the layout-based path. Both are present — keep both per the source pattern.

---

### `.config/quickshell/widgets/TrayWidget.qml` (widget root, SNI + QsMenuAnchor)

**Analog (visual scaffolding only):** `.config/quickshell/BarContent.qml` lines 78-87

**Body pattern (NO in-repo SNI/menu analog — sourced from RESEARCH.md Pattern 7, lines 552-611):**

**Imports pattern:**
```qml
import QtQuick
import Quickshell
import Quickshell.Widgets               // IconImage lives here (A3)
import Quickshell.Services.SystemTray
import Quickshell.Hyprland              // HyprlandFocusGrab
import qs.theme
import "../" as Local
```

**Body:**
```qml
Local.ModulePill {
    id: root
    visible: SystemTray.items.values.length > 0

    Row {
        spacing: 8                                 // UI-SPEC inter-icon gap
        Repeater {
            model: SystemTray.items
            delegate: Item {
                id: trayItem
                required property var modelData
                width: 21                          // UI-SPEC lg = 21px
                height: 21

                IconImage {
                    id: iconImg
                    anchors.fill: parent
                    source: trayItem.modelData.icon
                    asynchronous: true
                }
                // D-44 fallback: when iconImg.status === Image.Error, render Nerd Font  glyph

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            trayItem.modelData.activate(mouse.x, mouse.y)
                        } else if (mouse.button === Qt.RightButton) {
                            menuAnchor.menu = trayItem.modelData.menu
                            menuAnchor.open()
                        }
                    }
                }
            }
        }
    }

    QsMenuAnchor {
        id: menuAnchor
        anchor.window: Window.window
    }

    HyprlandFocusGrab {
        windows: [menuAnchor.visible ? Window.window : null].filter(w => w !== null)
        active: menuAnchor.visible
        onCleared: menuAnchor.close()
    }
}
```

**Anchor positioning (RESEARCH.md A7):** `menuAnchor.anchor.rect` must be set in window-space coordinates via `mapToItem(Window.window.contentItem, 0, 0)` on the icon's parent Item inside `onClicked`. Implementation detail per CONTEXT.md D-43 — planner picks the exact mapping call.

**Critical pitfall to honor (P-16, RESEARCH.md Pitfall 5):** `HyprlandFocusGrab` is mandatory; `grabFocus: true` is forbidden. The bar's `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None` in BarContent.qml line 22 is the prerequisite that makes outside-click dismiss safe.

**NeedsAttention tint (D-41):** apply `Colours.critical` when `trayItem.modelData.status === Status.NeedsAttention`. Implementation: ColorOverlay layer on IconImage, OR opacity layer + tint Rectangle. Planner picks. UI-SPEC State Inventory mandates the tint must render.

---

### `.config/quickshell/BarContent.qml` (MODIFY — layout composer)

**Self-analog (in-place replacement):** lines 50-88 — three placeholder `ModulePill { Text { ... } }` blocks become widget instances.

**Existing imports** (lines 1-6, KEEP):
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.theme
```

**ADD one import** (after line 6):
```qml
import qs.widgets
```

**Replacement pattern (RESEARCH.md Example 3, lines 724-733):**
```qml
RowLayout {
    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 4 }
    spacing: 0

    BarGroup { WorkspacesWidget {} }                              // left
    Item { Layout.fillWidth: true }
    BarGroup { /* center empty — Phase 14 fills */ }
    Item { Layout.fillWidth: true }
    BarGroup { MusicWidget {}; VolumeWidget {}; TrayWidget {} }   // right (D-56)
}
```

**Unchanged sections (lines 1-49):** PanelWindow root, `WlrLayershell.keyboardFocus`, bgRect Rectangle + DropShadow, RowLayout anchor block. These survive the edit verbatim.

---

## Shared Patterns

### Singleton scaffolding
**Source:** `.config/quickshell/theme/Colours.qml` lines 1-5
**Apply to:** All three new service files (`AudioService.qml`, `MprisService.qml`, `HyprWorkspaces.qml`)
```qml
pragma Singleton
import Quickshell
import QtQuick

Singleton {
```
**Rules:**
- `pragma Singleton` is the very first line.
- Imports follow: `Quickshell` first, then `Quickshell.Services.*` or `Quickshell.Hyprland`, then `QtQuick`.
- Root QML object is `Singleton` (capital S — the Quickshell type, not lowercase).
- Use `readonly property` for derived/exposed values (matches Colours throughout).

### qmldir registration
**Source:** `.config/quickshell/theme/qmldir`
**Apply to:** `services/qmldir`, `widgets/qmldir`
```
singleton TypeName FileName.qml    # for singletons
TypeName FileName.qml              # for non-singleton widget components
```
**Rules:**
- One line per type.
- No version qualifier (Phase 12 in-repo convention).
- `singleton` keyword only for `pragma Singleton` files.

### Bar font block
**Source:** `.config/quickshell/BarContent.qml` lines 54-57 (the placeholder Text)
**Apply to:** Every Text node in WorkspacesWidget, VolumeWidget, MusicWidget (NOT TrayWidget — tray uses IconImage)
```qml
font.family:    "JetBrainsMono Nerd Font"
font.pixelSize: 14
font.bold:      true
color:          Colours.textColor   // baseline; override per-state per UI-SPEC color table
```

### ModulePill composition
**Source:** `.config/quickshell/ModulePill.qml` (`default property alias content: inner.children`, line 5)
**Apply to:** All four widget files
**Pattern:** widget root is `Local.ModulePill { ... }`; child Items / Rows / Texts go directly inside the braces and are auto-aliased into `inner.children`.
```qml
Local.ModulePill {
    id: root
    Row { /* widget content */ }
    MouseArea { anchors.fill: parent; /* full-pill hit area per D-46 */ }
}
```

### Sibling-directory import for ModulePill
**Source:** RESEARCH.md Patterns 4–7 (consistent across all four widget patterns, e.g. line 390)
**Apply to:** All four widget files
```qml
import "../" as Local   // ModulePill lives at .config/quickshell/ root, widgets live one level down
```
**Rationale:** ModulePill, BarGroup live at `.config/quickshell/` root (no qmldir); widgets/services live in subdirectories. The relative `import "../" as Local` is the documented Quickshell pattern for sibling files outside a qmldir module. Without it, widgets would have to use the bare Quickshell `Rectangle`-based pill inline.

### MouseArea click hit area
**Source:** RESEARCH.md Patterns 4–7 (CONTEXT.md D-46 — "click hit area = full ModulePill")
**Apply to:** All four widget files
```qml
MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor   // D-45
    acceptedButtons: Qt.LeftButton | Qt.RightButton    // or AllButtons / NoButton per widget
    onClicked: mouse => { /* per-widget routing */ }
}
```

### Visibility / hidden-collapse pattern
**Source:** RESEARCH.md Patterns 5, 6, 7 (CONTEXT.md D-28, D-35, D-40, D-51)
**Apply to:** VolumeWidget, MusicWidget, TrayWidget
```qml
visible: <service-derived condition>   // false collapses layout cleanly; never `opacity: 0`
```
- VolumeWidget: `visible: AudioService.defaultSink !== null`
- MusicWidget: `visible: MprisService.hasPlayer`
- TrayWidget: `visible: SystemTray.items.values.length > 0`

### Console-warn error logging
**Source:** RESEARCH.md (CONTEXT.md D-48)
**Apply to:** Inline `Process` instances (currently only VolumeWidget)
```qml
Process {
    id: <name>Proc
    command: [...]
    running: false
    onExited: code => { if (code !== 0) console.warn("<binary> exited", code) }
}
```
**Caveat:** `startDetached()` does NOT trigger `onExited` (RESEARCH.md A8). The handler is harmless but inert for detached spawns.

### Color tokens
**Source:** `.config/quickshell/theme/Colours.qml` lines 35-42 (semantic aliases)
**Apply to:** All four widget files + service consumers
| Token | Hex | Phase 13 usage |
|-------|-----|----------------|
| `Colours.barBg` | `#000000` | bar background (already wired in BarContent.qml line 28) |
| `Colours.moduleBg` | `#1e1e2e` | pill background (already wired in ModulePill.qml line 7) |
| `Colours.accent` (mauve) | `#cba6f7` | active workspace ONLY (D-13) |
| `Colours.textColor` | `#cdd6f4` | volume %, music text, occupied workspaces, tray fallback |
| `Colours.subtextColor` | `#bac2de` | empty workspaces (D-13) — narrowly applies per A4 |
| `Colours.critical` (red) | `#f38ba8` | urgent workspace tint, NeedsAttention tray tint (D-14, D-41) |
| `Colours.warning` | `#f9e2af` | NOT USED in Phase 13 (reserved for Phase 14) |
| `Colours.success` | `#a6e3a1` | NOT USED in Phase 13 |

---

## No Analog Found

Files where the in-repo codebase has no close match. Planner uses RESEARCH.md patterns (cited above) instead.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `services/AudioService.qml` body | service singleton | PipeWire pub-sub | No existing PipeWire/PwObjectTracker usage in repo — entire body sourced from RESEARCH.md Pattern 1 |
| `services/MprisService.qml` body | service singleton | MPRIS D-Bus | No existing MPRIS usage in repo — entire body sourced from RESEARCH.md Pattern 2 |
| `services/HyprWorkspaces.qml` body | service singleton | Hyprland IPC + rawEvent | No existing Hyprland binding in repo — entire body sourced from RESEARCH.md Pattern 3 |
| `widgets/TrayWidget.qml` (SNI + QsMenuAnchor + HyprlandFocusGrab parts) | widget root | SNI + native menu | No existing tray/menu widget in repo — sourced from RESEARCH.md Pattern 7 |

For all four cases above, the **structural** scaffolding (Singleton wrapper for services; ModulePill + MouseArea for widgets) DOES have an analog (Colours.qml and BarContent.qml respectively); only the data-flow body is greenfield.

---

## Metadata

**Analog search scope:**
- `.config/quickshell/` (5 QML files: shell.qml, Bar.qml, BarContent.qml, BarGroup.qml, ModulePill.qml)
- `.config/quickshell/theme/` (Colours.qml, qmldir)
- `.planning/research/ARCHITECTURE.md` (referenced for service-singleton pattern; already cited in CONTEXT.md canonical refs)
- `.config/waybar/config.jsonc` and `.config/waybar/style.css` (visual continuity benchmark only — Waybar JSON config is not a code analog for QML)

**Files scanned:** 7 (entire `.config/quickshell/` tree)
**Greenfield ratio:** 4 of 11 files have no in-repo body analog (all Quickshell.Services.* bindings); the other 7 reuse the Phase 12 ModulePill/Singleton/qmldir scaffolding 1:1.
**Pattern extraction date:** 2026-05-03

*Phase: 13-native-api-widgets*
