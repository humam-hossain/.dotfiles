---
phase: 13-native-api-widgets
verified: 2026-05-04T16:30:13Z
status: gaps_found
score: 21/26 must-haves verified
overrides_applied: 0
gaps:
  - truth: "The workspaces widget shows all current Hyprland workspaces reactively; clicking a workspace activates it; scrolling cycles through workspaces; the active workspace is highlighted in Catppuccin Mauve; occupied workspaces are visually distinct from empty ones; urgent workspaces have a distinct indicator"
    status: failed
    reason: "Workspace rendering is wired, but empty-vs-occupied distinction is not implemented and urgent workspace state is tracked from raw event data instead of the native workspace urgent property."
    artifacts:
      - path: ".config/quickshell/widgets/WorkspacesWidget.qml"
        issue: "Non-active workspaces always render with Colours.textColor; no occupied/empty branch or workspace.toplevels/lastIpcObject check exists."
      - path: ".config/quickshell/services/HyprWorkspaces.qml"
        issue: "Urgency is derived from parseInt(event.data, 10) on raw Hyprland urgent events, while the installed Quickshell type exposes HyprlandWorkspace.urgent directly."
    missing:
      - "Use a real occupied/empty signal, such as HyprlandWorkspace.toplevels or another verified native workspace field, to render occupied workspaces distinctly from empty ones."
      - "Use cell.modelData.urgent or expose HyprlandWorkspace.urgent through HyprWorkspaces instead of parsing raw urgent event data as a workspace id."
  - truth: "HyprWorkspaces.isUrgent(id) returns true after an `urgent` rawEvent for that id and false after the workspace is focused (urgent cleared)"
    status: failed
    reason: "The implementation stores parseInt(event.data, 10), but Quickshell's installed HyprlandWorkspace type already exposes an urgent property; the raw event payload is not verified as a workspace id."
    artifacts:
      - path: ".config/quickshell/services/HyprWorkspaces.qml"
        issue: "Lines 19-24 parse raw event data into urgentIds instead of binding to workspace.urgent."
    missing:
      - "Replace urgentIds raw-event parsing with native workspace urgent state or prove the raw event data is the workspace id for this Quickshell/Hyprland version."
  - truth: "Phase 13 widgets are live and visible in BarContent.qml"
    status: failed
    reason: "BarContent.qml wires the widgets, but the PanelWindow still has no height or implicitHeight binding, so the content can collapse to height 0 and exclusiveZone can remain 0."
    artifacts:
      - path: ".config/quickshell/BarContent.qml"
        issue: "exclusiveZone is bound to height, but no height/implicitHeight is assigned; anchored RowLayout children do not establish parent implicit height."
    missing:
      - "Bind PanelWindow implicitHeight/height to the content row's implicit height plus margins, then keep exclusiveZone bound to that height."
  - truth: "TrayWidget left/right click and outside dismissal"
    status: partial
    reason: "Tray icon rendering and menu anchoring exist, but click handling does not match the installed SystemTrayItem API or menu-state properties."
    artifacts:
      - path: ".config/quickshell/widgets/TrayWidget.qml"
        issue: "Calls activate(mouse.x, mouse.y) even though installed qmltypes expose activate() with no parameters; right-click opens modelData.menu without hasMenu guard and left-click does not handle onlyMenu items."
    missing:
      - "Use item.activate() for normal left-click actions, use item.display(root.hostWindow, x, y) or menu opening for onlyMenu items, and guard right-click menu opening with hasMenu."
---

# Phase 13: Native API Widgets Verification Report

**Phase Goal:** Workspaces, volume, media, and system tray widgets are live with real Hyprland/PipeWire/MPRIS/SystemTray data - no shell scripts involved
**Verified:** 2026-05-04T16:30:13Z
**Status:** gaps_found
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Roadmap SC1: Workspaces are reactive, clickable, scrollable, active Mauve, occupied distinct from empty, and urgent distinct | FAILED | `.config/quickshell/widgets/WorkspacesWidget.qml:14` uses `HyprWorkspaces.workspaces`, `:38` activates, and `:49-50` scroll-dispatches. Active Mauve is present at `:31`. Empty-vs-occupied has no implementation, and urgent depends on the failed raw-event service. |
| 2 | Roadmap SC2: Volume shows current PipeWire default sink percent and mute state without shell scripts; click opens pavucontrol | VERIFIED | `AudioService.qml:9-12` binds default sink, volume, muted, and percent through PipeWire; `VolumeWidget.qml:10,20-35,39-54` renders state and starts literal `pavucontrol`. |
| 3 | Roadmap SC3: Music shows current MPRIS artist/title, click toggles play/pause, hidden when no player active | VERIFIED | `MprisService.qml:9-15` selects active player; `MusicWidget.qml:9,11-17,27,35-36` renders, hides, and calls `togglePlaying()`. |
| 4 | Roadmap SC4: System tray renders SNI icons; right-click opens context menu | VERIFIED (code), needs UAT | `TrayWidget.qml:11,18,26-31,59-62,70-77` binds `SystemTray.items`, renders `IconImage`, opens `QsMenuAnchor`, and dismisses through `HyprlandFocusGrab`. Live SNI/menu behavior needs manual display-session UAT. |
| 5 | Importing `qs.services` resolves AudioService, MprisService, and HyprWorkspaces | VERIFIED | `services/qmldir:1-3` registers all three singletons; `qmllint -I .config/quickshell ...` exited 0. |
| 6 | AudioService volumePercent reflects default sink and recomputes with sink changes | VERIFIED | `AudioService.qml:9-12,25-26` binds `Pipewire.defaultAudioSink`, computes `Math.round(volume * 100)`, and tracks `root.defaultSink`. |
| 7 | AudioService muted and write methods update default sink audio | VERIFIED | `AudioService.qml:11,15-23` reads muted, clamps volume writes, bumps percent, and toggles `defaultSink.audio.muted`. |
| 8 | MprisService activePlayer prefers Playing, falls back to first, null when none | VERIFIED | `MprisService.qml:10-13` uses `Mpris.players.values`, `MprisPlaybackState.Playing`, null on empty, and first-player fallback. |
| 9 | HyprWorkspaces returns sorted, filtered Hyprland workspaces | VERIFIED | `HyprWorkspaces.qml:9-12` binds `Hyprland.workspaces.values`, sorts by id, filters `id < 0` and `special:*`. |
| 10 | HyprWorkspaces urgent tracking works for real urgent workspaces | FAILED | `HyprWorkspaces.qml:19-24` parses raw event data as an id. Installed Quickshell qmltypes expose `HyprlandWorkspace.urgent`, so the code is not wired to native urgent state. |
| 11 | Importing `qs.widgets` resolves all four widgets | VERIFIED | `widgets/qmldir:1-4` registers Workspaces, Volume, Music, Tray; all files exist and `BarContent.qml:7` imports `qs.widgets`. |
| 12 | WorkspacesWidget renders one glyph per HyprWorkspaces entry in id-sorted order | VERIFIED | `WorkspacesWidget.qml:10-16,23-32` uses one Repeater delegate per `HyprWorkspaces.workspaces` entry. Sorting is provided by the service. |
| 13 | Workspace active/non-active glyph/color and urgent override | FAILED | Active/non-active glyph and colors are present at `WorkspacesWidget.qml:29-32`; urgent override depends on failed `HyprWorkspaces.isUrgent`. |
| 14 | Left-clicking a workspace activates it | VERIFIED (code), needs UAT | `WorkspacesWidget.qml:35-39` calls `cell.modelData.activate()`. |
| 15 | Workspace wheel dispatches static next/previous workspace commands | VERIFIED | `WorkspacesWidget.qml:45-50` dispatches literal `workspace e+1` and `workspace e-1`; no interpolation found. |
| 16 | VolumeWidget renders icon plus percentage and hides without default sink | VERIFIED | `VolumeWidget.qml:10,15-35` binds visibility, icon, opacity, and percent to `AudioService`. |
| 17 | VolumeWidget glyph thresholds and mute opacity | VERIFIED | `VolumeWidget.qml:20-25,34` implements muted/0, low, mid, high glyphs and 0.6 opacity when muted. |
| 18 | VolumeWidget click/right-click/wheel actions | VERIFIED (code), needs UAT | `VolumeWidget.qml:39-58` uses literal `pavucontrol`, `AudioService.toggleMute()`, and `AudioService.bumpVolume(step)`. |
| 19 | MusicWidget renders metadata with 30-char truncation | VERIFIED | `MusicWidget.qml:11-17,27` builds artist/title display and truncates with `\u2026`; `Text.ElideRight` is set at `:26`. |
| 20 | MusicWidget no-track fallback and hidden no-player state | VERIFIED | `MusicWidget.qml:9,15` hides on no player and renders ` No track` when metadata is absent. |
| 21 | MusicWidget click/control-disabled behavior | VERIFIED (code), needs UAT | `MusicWidget.qml:19,30-36` sets opacity, disables MouseArea when `canControl` is false, and calls `togglePlaying()`. |
| 22 | MusicWidget tooltip skips empty metadata fields | VERIFIED | `MusicWidget.qml:39-47` builds tooltip lines from non-empty artist, title, album fields. |
| 23 | TrayWidget renders one IconImage per tray item and hides when empty | VERIFIED (code), needs UAT | `TrayWidget.qml:11,17-31` binds to `SystemTray.items`, one 21px delegate each, and hides on empty values. |
| 24 | TrayWidget left/right click and outside dismissal | PARTIAL | Right-click menu wiring and focus grab are present at `TrayWidget.qml:59-77`. Installed qmltypes show `SystemTrayItem.activate` has no parameters and `display(parentWindow,x,y)` exists, while code calls `activate(mouse.x, mouse.y)` and does not check `hasMenu` or `onlyMenu`. |
| 25 | Tray attention tint and icon fallback | VERIFIED | `TrayWidget.qml:34-48` renders fallback glyph `\uf128` and overlays `Colours.critical` for `Status.NeedsAttention`. |
| 26 | BarContent composes Workspaces left and Music/Volume/Tray right | VERIFIED (composition), FAILED (visibility risk) | `BarContent.qml:51,55,59-63` composes the planned widgets and leaves center empty for Phase 14. `BarContent.qml:15` lacks a height source for `exclusiveZone`. |

**Score:** 21/26 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.config/quickshell/services/qmldir` | Register AudioService, MprisService, HyprWorkspaces singletons | VERIFIED | Exists, 3 lines, no version qualifier. |
| `.config/quickshell/services/AudioService.qml` | PipeWire default-sink wrapper with PwObjectTracker | VERIFIED | Exists, substantive, imported by VolumeWidget, source flows from `Pipewire.defaultAudioSink`. |
| `.config/quickshell/services/MprisService.qml` | Active-player selector | VERIFIED | Exists, substantive, imported by MusicWidget, source flows from `Mpris.players.values`. |
| `.config/quickshell/services/HyprWorkspaces.qml` | Sorted/filtered workspaces and urgent tracking | PARTIAL | Sorted/filtering verified; urgent tracking is not wired to native workspace urgent state. |
| `.config/quickshell/widgets/qmldir` | Register all four widgets | VERIFIED | Exists, 4 non-singleton lines, no version qualifier. |
| `.config/quickshell/widgets/WorkspacesWidget.qml` | Hyprland workspaces widget | PARTIAL | Rendering/click/wheel verified; occupied distinction missing and urgent source is wrong. |
| `.config/quickshell/widgets/VolumeWidget.qml` | PipeWire volume widget | VERIFIED | Exists, substantive, wired to AudioService and pavucontrol process. |
| `.config/quickshell/widgets/MusicWidget.qml` | MPRIS music widget | VERIFIED | Exists, substantive, wired to MprisService and player controls. |
| `.config/quickshell/widgets/TrayWidget.qml` | SystemTray widget | PARTIAL | Icon/menu/focus-grab code exists; click/menu edge semantics need correction or UAT. |
| `.config/quickshell/BarContent.qml` | Replace placeholders with real widgets | PARTIAL | Widgets are instantiated, but PanelWindow height/exclusiveZone can collapse to 0. |
| `.config/quickshell/ModulePill.qml` | Shared pill supports visual and non-visual widget children | VERIFIED | `default property alias content: inner.data` supports Process/QsMenuAnchor/FocusGrab and sizing still uses childrenRect. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `AudioService.qml` | `Pipewire.defaultAudioSink` | `PwObjectTracker { objects: root.defaultSink ? [root.defaultSink] : [] }` | VERIFIED | Lines 9 and 25-26. |
| `MprisService.qml` | `Mpris.players.values` | `find(p => p.playbackState === MprisPlaybackState.Playing)` | VERIFIED | Lines 10-13. |
| `HyprWorkspaces.qml` | `Hyprland.workspaces.values` | Direct reactive property binding | VERIFIED | Lines 9-12. |
| `HyprWorkspaces.qml` | Native urgent workspace state | Raw `urgent` event parsing | FAILED | Lines 19-24 parse event data; installed qmltypes expose `HyprlandWorkspace.urgent`. |
| `WorkspacesWidget.qml` | `HyprWorkspaces.workspaces` / `isUrgent` | `import qs.services` and Repeater model | PARTIAL | Workspace list wired; urgent source is failed. |
| `WorkspacesWidget.qml` | `Hyprland.dispatch` | MouseArea wheel static dispatch | VERIFIED | Lines 49-50. |
| `VolumeWidget.qml` | `AudioService` | Direct bindings and method calls | VERIFIED | Lines 10, 20-35, 54, 58, 63. |
| `MusicWidget.qml` | `MprisService` / `togglePlaying` | Direct bindings and click handler | VERIFIED | Lines 9, 11, 36. |
| `TrayWidget.qml` | `SystemTray.items` | Repeater model | VERIFIED | Lines 11 and 18. |
| `TrayWidget.qml` | `QsMenuAnchor` / `HyprlandFocusGrab` | Right-click sets menu and opens; focus grab closes | PARTIAL | Present at lines 59-77; lacks `hasMenu`/`onlyMenu` handling and left-click uses wrong activate signature. |
| `BarContent.qml` | All four widgets | `import qs.widgets` plus widget instances | VERIFIED | Lines 7, 51, 60-62. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `WorkspacesWidget.qml` | `HyprWorkspaces.workspaces` | `Hyprland.workspaces.values` | Yes | FLOWING |
| `WorkspacesWidget.qml` | `HyprWorkspaces.isUrgent(id)` | Raw `Hyprland.rawEvent` map | No, not proven for real urgent workspace id | HOLLOW |
| `VolumeWidget.qml` | `AudioService.volumePercent`, `muted`, `defaultSink` | `Pipewire.defaultAudioSink.audio` with `PwObjectTracker` | Yes | FLOWING |
| `MusicWidget.qml` | `MprisService.activePlayer` metadata | `Mpris.players.values` | Yes | FLOWING |
| `TrayWidget.qml` | `SystemTray.items` | `Quickshell.Services.SystemTray.SystemTray.items` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| QML syntax/import sanity for scoped files | `qmllint -I .config/quickshell ...` | Exit 0, no output | PASS |
| Quickshell live load in sandbox | `timeout 5 quickshell --no-color --path .config/quickshell` | Failed before app load: cannot create `/run/user/1000/quickshell`, Wayland/XCB unavailable | SKIP - needs user session |
| Phase artifact existence/substance | `gsd-tools verify artifacts` for 13-01, 13-02, 13-03 | 10/10 declared plan artifacts passed | PASS |
| Manual key-link grep | `rg` over `.config/quickshell` for service/widget API references | Expected references found; gsd-tools regex checks had false negatives on escaped patterns | PASS with noted failed links above |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| WS-01 | 13-01, 13-02 | Workspaces widget shows all Hyprland workspaces using `Quickshell.Hyprland` ObjectModel, reactive not raw IPC socket | SATISFIED | `HyprWorkspaces.qml:9` reads `Hyprland.workspaces.values`; `WorkspacesWidget.qml:14` renders it. |
| WS-02 | 13-02 | Active workspace highlighted Mauve; occupied distinct from empty; urgent distinct | BLOCKED | Active Mauve verified at `WorkspacesWidget.qml:31`, but occupied/empty is missing and urgent is based on failed raw-event parsing. |
| WS-03 | 13-02 | Click workspace activates it; scroll cycles workspaces via Hyprland dispatch | SATISFIED (code), needs UAT | `WorkspacesWidget.qml:38,49-50` calls `activate()` and static dispatch. |
| AUDIO-01 | 13-01, 13-02 | PipeWire default sink volume/mute through PwObjectTracker; click opens pavucontrol | SATISFIED (code), needs UAT | `AudioService.qml:9-26`; `VolumeWidget.qml:39-54`. |
| AUDIO-03 | 13-01, 13-03 | MPRIS artist/title; click toggles play/pause; hidden without player | SATISFIED (code), needs UAT | `MprisService.qml:10-13`; `MusicWidget.qml:9,11-17,36`. |
| TRAY-01 | 13-03 | System tray renders SNI icons; icons load correctly; right-click opens context menu | PARTIAL, needs UAT | `TrayWidget.qml:18,26-31,59-62`; click/menu edge semantics need correction or manual confirmation. |

All six Phase 13 requirement IDs are declared in PLAN frontmatter and cross-referenced against `.planning/REQUIREMENTS.md`. No additional Phase 13 requirement IDs are orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.config/quickshell/BarContent.qml` | 15 | `exclusiveZone: height` without any `height` or `implicitHeight` source | Blocker | Widgets may be correctly instantiated but invisible and reserve no panel space. |
| `.config/quickshell/services/HyprWorkspaces.qml` | 19-24 | Raw urgent event data parsed as workspace id | Blocker | Urgent workspace indicator is not wired to the installed native workspace urgent property. |
| `.config/quickshell/widgets/WorkspacesWidget.qml` | 30-32 | All non-active, non-urgent workspaces render the same color | Blocker | Requirement WS-02 occupied-vs-empty distinction is not achieved. |
| `.config/quickshell/widgets/TrayWidget.qml` | 55-62 | Tray click handling ignores `hasMenu` / `onlyMenu`; `activate` called with arguments despite no-arg qmltype | Warning | Tray edge interactions can no-op or error for menu-only/no-menu items; live UAT required. |
| `.config/quickshell/widgets/MusicWidget.qml` | 12 | Metadata concatenation can leave dangling separators when only one field is present | Info | Cosmetic issue; does not block stated artist+title requirement. |

### Human Verification Required

These do not change the `gaps_found` status, but they remain necessary after gaps are fixed:

1. **Quickshell live reload and panel visibility**
   **Test:** Launch `quickshell --no-color --path .config/quickshell` inside the real Hyprland user session.
   **Expected:** Bar appears on screen with nonzero height and no QML warnings/errors.
   **Why human:** Sandbox cannot initialize Wayland/XCB or create the Quickshell runtime directory.

2. **Workspace interactions**
   **Test:** Create empty and occupied workspaces, trigger urgency on an unfocused workspace, click workspace glyphs, and scroll over the workspace pill.
   **Expected:** Occupied/empty/active/urgent states are visually distinct; click activates; wheel cycles.
   **Why human:** Requires live Hyprland state and pointer input.

3. **Volume interactions**
   **Test:** Change PipeWire default sink volume/mute externally, click the volume widget, right-click it, and scroll it.
   **Expected:** Percent/mute update reactively; pavucontrol opens; mute toggles; wheel adjusts by 5%.
   **Why human:** Requires live PipeWire and GUI interaction.

4. **Music interactions**
   **Test:** Run an MPRIS player with metadata, no metadata, long title, and no player; click and hover the widget.
   **Expected:** Visibility, text, truncation, tooltip, and togglePlaying behavior match the contract.
   **Why human:** Requires a live MPRIS provider and pointer input.

5. **Tray interactions**
   **Test:** Use SNI apps with a context menu, no menu, and only-menu behavior.
   **Expected:** Icons render, right-click menu opens when present, left-click honors only-menu items, outside click dismisses without focus theft.
   **Why human:** Requires live SNI apps and pointer/menu interaction.

### Gaps Summary

Phase 13 has substantive native Quickshell services and widgets, and most data paths are wired to real APIs. The phase goal is not fully achieved yet because one workspace requirement is incomplete, urgent workspaces are not wired to the native urgent property, and the composed bar can still collapse to height 0. Tray behavior is mostly wired but has native API edge-risk that should be fixed or manually accepted after UAT.

---

_Verified: 2026-05-04T16:30:13Z_
_Verifier: Claude (gsd-verifier)_
