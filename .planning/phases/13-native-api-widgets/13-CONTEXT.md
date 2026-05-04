# Phase 13: Native API Widgets - Context

**Gathered:** 2026-05-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire four widgets to native Quickshell APIs — workspaces (Quickshell.Hyprland), volume (Quickshell.Services.Pipewire), music (Quickshell.Services.Mpris), system tray (Quickshell.Services.SystemTray). Replace Phase 12 placeholder labels with reactive widgets reading real desktop data. Zero shell scripts in this phase (those = Phase 14). No popups, no animations (those = Phases 15–16).

Foundational service singletons (`AudioService`, `MprisService`, `HyprWorkspaces`) are introduced here so the volume OSD (Phase 14) and popups (Phase 15) can reuse them without rebinding `PwObjectTracker` or re-implementing player-pick logic.

</domain>

<decisions>
## Implementation Decisions

### Service Layer
- **D-01:** Use service singleton wrappers (per `.planning/research/ARCHITECTURE.md`). Three new singletons: `AudioService.qml` (PipeWire default sink), `MprisService.qml` (active player selection), `HyprWorkspaces.qml` (sorted/filtered workspaces). Widgets import services, never the raw `Quickshell.Services.*` modules.
- **D-02:** Service files live under `.config/quickshell/services/` with `services/qmldir`. Imported via `import qs.services`. Mirrors Phase 12's `theme/Colours.qml` + `theme/qmldir` precedent.
- **D-03:** Each service uses `pragma Singleton` and is registered as `singleton ServiceName 1.0 ServiceName.qml` in `services/qmldir`. Singleton instance is shared across the whole shell.
- **D-04:** `AudioService` exposes derived properties only — `volume: real`, `muted: bool`, `volumePercent: int`. Internal `PwObjectTracker` and `defaultSink` reference are hidden behind the API. Helper methods: `setVolume(percent)`, `bumpVolume(delta)`, `toggleMute()`. All computed properties use null-guards (e.g. `volumePercent: defaultSink ? Math.round(defaultSink.audio.volume * 100) : 0`).
- **D-05:** `AudioService` re-binds `PwObjectTracker` when `Pipewire.defaultAudioSink` changes (default device switch on headphone plug). Tracker target list = `[Pipewire.defaultAudioSink]` only — `.audio` is auto-tracked when parent sink is tracked. `volumePercent` = `Math.round(volume * 100)`.
- **D-06:** `AudioService` scope is sink-only for Phase 13. Default source / microphone is out of scope (no v1.2 requirement).
- **D-07:** `MprisService` player selection: `Mpris.players.values.find(p => p.playbackState === 'Playing') ?? Mpris.players.values[0]`. First playing wins, fallback to first in list, hidden when list is empty.

### Workspaces Widget
- **D-08:** Visual style = Waybar dot icons. Active workspace renders ``, default renders ``. JetBrainsMono Nerd Font 14px (matches Phase 12 text size).
- **D-09:** Show only existing workspaces (iterate `Hyprland.workspaces.values`); no fixed 1-10 slots.
- **D-10:** Repeater model = `Hyprland.workspaces.values.slice().sort((a,b) => a.id - b.id).filter(w => w.id >= 0 && !w.name.startsWith('special:'))`. Filter strips Hyprland special / scratchpad workspaces. Sort by id keeps stable left-to-right ordering.
- **D-11:** One pill containing all workspace buttons — single `ModulePill` wrapping a `Repeater` of buttons. Buttons styled inline (color only); no nested pills.
- **D-12:** Mauve highlight tracks `ws.active` (per-monitor visible workspace), not `ws.focused`. On dual-monitor, each bar highlights its own monitor's active workspace.
- **D-13:** Three-state coloring by `Colours`: `accent` (mauve) for active, `textColor` for occupied (has toplevels), `subtextColor` for empty. **AMENDED 2026-05-04 (planner verification):** Reduced to two-state — `accent` for active, `textColor` for non-active. The `subtextColor` empty branch is unreachable in practice because HyprlandWorkspace API does not expose toplevel count and Hyprland auto-destroys empty non-focused workspaces. User confirmed two-state acceptable; richer occupancy (rawEvent-based window tracking, option c) deferred to a Phase 16 polish ticket if UAT flags inadequate distinction.
- **D-14:** Urgent indicator = override icon color to `Colours.critical` (red). No animation in Phase 13.
- **D-15:** `urgent` source: prefer `ws.urgent` if Quickshell exposes it; else derive `ws.toplevels.values.some(t => t.urgent)`. Researcher confirms which API path is current.
- **D-16:** Activation = `workspace.activate()` (QML-native method, not `HyprlandIpc.dispatch`). Cross-monitor click uses native `.activate()` behavior (no manual `focusmonitor` pre-dispatch).
- **D-17:** Each bar (every monitor) renders the same global workspace list — not per-monitor filtered. Click any workspace from any bar.
- **D-18:** Scroll behavior: wheel-down = next workspace, wheel-up = previous. Wraps at edges. Implemented via `Hyprland.dispatch("workspace e+1")` / `e-1` (Hyprland's empty-aware/wrap dispatchers).
- **D-19:** Initial-paint race: bind reactively to `Hyprland.workspaces.values`; render empty until populated (~1 frame). No explicit placeholder.

### Volume Widget
- **D-20:** Format = icon + percentage text (e.g. ` 75%`). Width is content-driven (1-2px shift between `5%` ↔ `100%` is acceptable).
- **D-21:** Icon thresholds — `0%` or muted = ``, `<33%` = ``, `<66%` = ``, `≥66%` = ``. Volume = 0% (not muted) is intentionally rendered as muted `` per user preference.
- **D-22:** Mute visual = swap icon to `` AND drop text opacity to 60%. Two signals so it reads at glance.
- **D-23:** Click → launch pavucontrol via inline `Process { command: ["pavucontrol"]; running: false }` invoked with `.startDetached()`. No `pgrep` dedup — pavucontrol's own DBus single-instance handles re-focus. No `hyprctl focuswindow` post-launch — Hyprland window rules govern.
- **D-24:** Right-click toggles mute via `AudioService.toggleMute()`.
- **D-25:** Wheel adjusts volume in ±5% steps via `step = 5 * Math.sign(wheel.angleDelta.y)`. Each detent = 120 angle-delta units; sign-only would over-trigger on smooth-scroll trackpads. No debounce — PipeWire handles rapid writes.
- **D-26:** Single `MouseArea` with `acceptedButtons: AllButtons` handles both `onWheel` and `onClicked`. `onClicked` filters `Qt.LeftButton` for pavucontrol vs `Qt.RightButton` for mute.
- **D-27:** Tooltip = sink display name + percentage (`"Default sink: <name> — 75%"`).
- **D-28:** Hidden when `AudioService.defaultSink === null` (no audio device). `visible: false` collapses bar layout cleanly.

### Music Widget (MPRIS)
- **D-29:** Format = icon + `"artist - title"` (e.g. ` Pink Floyd - Money`). Matches existing Waybar `custom/music` exec format `'  {}'`.
- **D-30:** Truncation = fixed 30 characters. `Text.elide: Text.ElideRight`. `Layout.maximumWidth` derived from font metrics for 30 chars.
- **D-31:** Click toggles play/pause via `player.playPause()`. No scroll, middle-click, or right-click action in Phase 13. Click works in `Stopped` state too (player resumes last track).
- **D-32:** When `player.canControl === false` → `MouseArea.enabled = false` and dim opacity (60%). Avoids silent click failures.
- **D-33:** Player exists but no metadata loaded yet → show ` No track`. Avoids show/hide flicker between tracks when metadata briefly empties.
- **D-34:** Tooltip on hover = full untruncated `"Artist\nTitle\nAlbum"` via `ToolTip`. Compensates for 30-char display truncation.
- **D-35:** Hidden when `MprisService.activePlayer === null` (no player). `visible: false` collapses layout.

### System Tray
- **D-36:** Icon rendering = Quickshell `IconImage { source: item.icon }` (handles SNI Pixmap + iconName fallbacks automatically).
- **D-37:** Original icon colors preserved (no monochrome tint). Apps ship branded icons; users expect them.
- **D-38:** All icons live inside ONE `ModulePill` (single wrapper around `Repeater` of `SystemTray.items`). Compact tray group.
- **D-39:** Icon size = 21px (matches Waybar `tray.icon-size: 21`).
- **D-40:** Pill hidden (`visible: SystemTray.items.length > 0`) when tray is empty. Bar layout collapses.
- **D-41:** Render all SNI status states (Active + Passive + NeedsAttention). NeedsAttention items get a `Colours.critical` color tint to draw attention.
- **D-42:** Left-click → `item.activate(x, y)` (default app action). Right-click → opens `QsMenuOpener` context menu against `item.menu`.
- **D-43:** Tray context menu uses `QsMenuOpener` + `QsMenuAnchor` (not `item.display()` fallback). Anchored below bar, top-aligned to clicked icon. Menu dismiss via `HyprlandFocusGrab` (per Phase 12 carryover and pitfall P-16). NOT `grabFocus: true`.
- **D-44:** Icon load failure fallback = render Nerd Font glyph (`` chip or `` question-mark) as Text. User sees something is wrong but tray remains usable.

### Cross-Cutting
- **D-45:** Pointer cursor (`MouseArea.cursorShape: Qt.PointingHandCursor`) on every clickable widget — workspace buttons, volume, music, tray icons, tray menu items.
- **D-46:** Click hit area = full `ModulePill` (`MouseArea { anchors.fill: parent }` placed inside the pill). Better Fitts' law; matches Waybar feel.
- **D-47:** Click-handler `Process` instances live inline inside the consuming widget (e.g. `VolumeWidget.qml` declares its own pavucontrol Process). No centralized `ProcessService.qml` for one-line spawns.
- **D-48:** Logging policy: `Process { onExited: code => code !== 0 ? console.warn(...) : null }`. Silent on success; surfaces missing binaries (e.g. pavucontrol uninstalled) without noise.
- **D-49:** Tooltips in Phase 13: volume widget (sink + %) + music widget (full metadata). Workspaces and tray skip explicit ToolTip — workspaces are self-evident, tray items have their own DBus tooltips. Re-evaluate during Phase 16 polish if needed.
- **D-50:** No hover animations or transitions in Phase 13. ANIM-01 (`Behavior on color { ColorAnimation { duration: 120 } }`) is explicitly Phase 16. Static color states only.
- **D-51:** Hidden widgets collapse layout via QML default `visible: false` semantics (zero size, removed from layout). Never use `opacity: 0` to hide — Phase 12 prior decision (input-tree cleanliness, P-16).

### File Layout
- **D-52:** New widget files use `<Name>Widget.qml` naming — `WorkspacesWidget.qml`, `VolumeWidget.qml`, `MusicWidget.qml`, `TrayWidget.qml`. Matches `.planning/research/ARCHITECTURE.md` examples (`SysTrayWidget.qml`).
- **D-53:** Widgets live under `.config/quickshell/widgets/` with `widgets/qmldir`. Imported as `import qs.widgets`. Mirrors `theme/` and `services/` pattern.
- **D-54:** Widgets stand alone — they import only `qs.theme` and `qs.services`, never other widgets. `BarContent.qml` composes widgets together.
- **D-55:** `shell.qml` and `Bar.qml` unchanged in Phase 13. Service singletons auto-instantiate on first import — no explicit init needed.
- **D-56:** `BarContent.qml` placeholder labels replaced. Final Phase 13 layout: left BarGroup = `WorkspacesWidget`. Right BarGroup = `MusicWidget`, `VolumeWidget`, `TrayWidget` (in that order — matches Waybar `tray, music, pulseaudio` reversed for readability — researcher confirms final order with planner). Center BarGroup empty (Phase 14 fills with weather + clock + weather2).

### UAT
- **D-57:** Verification = manual checklist per widget. UAT.md lists: switch workspace via mouse-click and via wheel-scroll, mute via right-click, scroll-to-adjust volume by ±5%, click music to pause Spotify (or any MPRIS source), right-click tray icon shows native context menu, all states render correctly with Catppuccin colors. No automated QML test harness in Phase 13.

### Claude's Discretion
- Exact Repeater vs ListView vs RowLayout-of-Items inside ModulePill for the workspace row.
- Internal spacing values inside the workspace pill (between buttons) — planner picks coherent value, likely matching Phase 12 D-03 inter-pill 8px or ModulePill internal padding 6/14.
- Detailed `IconImage` props for SNI icons (sourceSize, smooth, mipmap) — implementation detail.
- Internal property names inside `AudioService` / `MprisService` / `HyprWorkspaces` beyond the public API documented in D-04 / D-07 / D-10.
- Exact tooltip strings and capitalization (e.g. `"Default sink: HDA Intel — 75%"` vs other phrasings).
- QML import order, ID naming, internal Item structure.
- Right BarGroup widget order — may be `MusicWidget, VolumeWidget, TrayWidget` or `TrayWidget, MusicWidget, VolumeWidget` — planner decides for visual balance.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Architecture and Patterns
- `.planning/research/ARCHITECTURE.md` — Service singleton pattern (`AudioService`, `HyprWorkspaces` examples at lines 27-28, 43); native API mappings (lines 244-246, 424-426); WorkspacesWidget / SysTrayWidget / VolumeWidget specs (lines 454-456); PipeWire vs PulseAudio note (line 532).
- `.planning/research/SUMMARY.md` — Stack additions (`Quickshell.Services.Pipewire`, `.Mpris`, `.SystemTray`, `Quickshell.Hyprland`), `PwObjectTracker` requirement, watch-out list.
- `.planning/research/PITFALLS.md` — P-15 (Variants cleanup on monitor disconnect — relevant for any per-bar state), P-16 (`WlrKeyboardFocus.None` and `HyprlandFocusGrab`), P-18 (`Process` deferred start). PwObjectTracker binding before reading `.audio` (must precede property access).
- `.planning/research/FEATURES.md` — Feature parity table for native API widgets.

### Phase 12 Carryover
- `.planning/phases/12-bar-skeleton-and-theme/12-CONTEXT.md` — `ModulePill` API (D-07, D-10), `BarGroup` default-children (D-09), `Colours` semantic aliases (D-08: `accent`, `textColor`, `subtextColor`, `critical`), color overrides (`barBg=#000000`, `moduleBg=#1e1e2e`).
- `.config/quickshell/BarContent.qml` — Current placeholder structure that Phase 13 will edit.
- `.config/quickshell/ModulePill.qml` — Pill wrapper Phase 13 widgets compose into.
- `.config/quickshell/BarGroup.qml` — `default property alias children: row.children` — Phase 13 widgets become direct children.
- `.config/quickshell/theme/Colours.qml` — Color tokens used by every Phase 13 widget.

### Waybar Reference (behavior to match)
- `.config/waybar/config.jsonc` §`hyprland/workspaces` (line 26) — format-icons reference (`""` active, `""` default).
- `.config/waybar/config.jsonc` §`tray` (line 33) — `icon-size: 21`, spacing.
- `.config/waybar/config.jsonc` §`custom/music` (line 37) — playerctl exec, click toggle play/pause, max-length 50 (Phase 13 uses 30 instead per D-30).
- `.config/waybar/config.jsonc` §`pulseaudio` (line 135) — current volume widget reference.

### Requirements
- `.planning/REQUIREMENTS.md` §WS — WS-01, WS-02, WS-03 (workspaces).
- `.planning/REQUIREMENTS.md` §AUDIO — AUDIO-01 (volume), AUDIO-03 (music).
- `.planning/REQUIREMENTS.md` §TRAY — TRAY-01 (system tray icons + right-click menu).
- `.planning/ROADMAP.md` §"Phase 13: Native API Widgets" — success criteria for the four widgets.

### Quickshell API Docs (for researcher)
- `Quickshell.Hyprland` — `Hyprland.workspaces` ObjectModel, `workspace.activate()`, `Hyprland.dispatch()`.
- `Quickshell.Services.Pipewire` — `Pipewire.defaultAudioSink`, `PwObjectTracker`, `.audio.volume`, `.audio.muted`.
- `Quickshell.Services.Mpris` — `Mpris.players` ObjectModel, `player.playbackState`, `player.canControl`, `player.playPause()`.
- `Quickshell.Services.SystemTray` — `SystemTray.items` ObjectModel, `item.icon`, `item.activate()`, `item.menu`, `QsMenuOpener`, `QsMenuAnchor`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.config/quickshell/ModulePill.qml` — Phase 13 widgets wrap themselves in this. Single source of pill geometry (radius 8, padding 6/14, `Colours.moduleBg`).
- `.config/quickshell/BarGroup.qml` — `default property alias children: row.children` + 8px spacing. Phase 13 widgets are placed directly as children: `BarGroup { WorkspacesWidget {} }`.
- `.config/quickshell/theme/Colours.qml` — Semantic aliases (`accent`, `textColor`, `subtextColor`, `critical`, `warning`, `success`, `moduleBg`, `barBg`) cover every Phase 13 color need without adding new tokens.
- `.config/quickshell/BarContent.qml:42-79` — Current three placeholder `ModulePill { Text { ... } }` blocks; Phase 13 swaps each block for the corresponding widget component.

### Established Patterns (Phase 12)
- `pragma Singleton` + `qmldir` registration (theme/Colours.qml) — Phase 13 reuses the pattern for service singletons.
- `WlrKeyboardFocus.None` on `PanelWindow` (Phase 12 P-16) — already set in `BarContent.qml`; Phase 13 adds no new keyboard focus.
- `JetBrainsMono Nerd Font` 14px bold for all bar text — Phase 13 widgets inherit.
- Three-section `RowLayout` with flexible spacers (`Item { Layout.fillWidth: true }`) — already wired; widgets just slot into existing BarGroups.

### Integration Points
- New imports added to `BarContent.qml`: `import qs.widgets`. Existing imports (`qs.theme`, `Quickshell`, `Quickshell.Wayland`, `QtQuick`, `QtQuick.Layouts`, `Qt5Compat.GraphicalEffects`) untouched.
- Service singletons auto-instantiate on first `import qs.services` — no explicit registration needed in `shell.qml` or `Bar.qml`.
- Widget files import `qs.theme` (for Colours) + `qs.services` (for AudioService, MprisService, HyprWorkspaces). Cross-widget imports avoided.

### Greenfield Areas
- No existing services/, widgets/ directories — Phase 13 creates both with their qmldir files.
- No existing usage of `Quickshell.Services.*` or `Quickshell.Hyprland` modules in repo — research must confirm exact API shapes (especially `ws.urgent` location and `PwObjectTracker` rebind pattern).

</code_context>

<specifics>
## Specific Ideas

- Workspace dot icons must be exactly Waybar's: `""` (active) and `""` (default) — visual continuity with the live Waybar instance running in parallel.
- Volume %=0 is rendered as muted `` (per user preference, deviates from "show 0% with low icon" recommendation). Conflates non-mute-zero with mute, which the user accepts.
- Music truncation = fixed 30 chars (user preference, tighter than Waybar's 50). Right-elide with `…`. Compensated by full-text tooltip on hover.
- Tray menu must use `QsMenuOpener` + `QsMenuAnchor` for native-styled DBus menu rendering, NOT `item.display()` fallback. Anchored below bar, opens downward.
- `HyprlandFocusGrab` is mandatory for tray menu dismiss. `grabFocus: true` is forbidden by Phase 12 prior decision (steals keyboard focus from active app).
- Service singletons exist primarily to enable Phase 14 OSD reuse — `AudioService.volumePercent` change signal drives the volume OSD without re-binding `PwObjectTracker`. Don't strip the indirection in service of "simplicity"; the indirection is the point.
- `volumePercent` rounding = `Math.round` (not floor/ceil). Symmetric, matches Waybar.

</specifics>

<deferred>
## Deferred Ideas

- **Volume OSD overlay** (AUDIO-02) — Phase 14. Reuses `AudioService.volumePercent` change signal; standalone `PanelWindow` at `WlrLayer.Overlay` with auto-hide Timer.
- **Notification count badge** (TRAY-02) + **swaync toggle** (TRAY-03) — Phase 14. Both require `swaync-client` Process spawns.
- **Hover animations** (`Behavior on color`) — Phase 16 (ANIM-01). Phase 13 ships static states.
- **Workspace tooltips** showing window count or workspace name — re-evaluate during Phase 16 polish.
- **Tray-item explicit tooltips** — DBus tooltips (built into SNI items) are sufficient for Phase 13.
- **Mic/source volume widget** — Not in v1.2 scope. AudioService is sink-only by D-06.
- **Multi-player UI affordance** (cycle players, show all simultaneously) — Phase 13 picks first-playing automatically; no UI for switching.
- **Music next/previous track buttons or scroll** — Not in v1.2 requirements; defer to future milestone if requested.
- **Tray-icon monochrome theme tint** — Not chosen; original icon colors preserved per D-37.
- **Always-show 1-10 workspace slots** — Rejected per D-09; only existing workspaces render.
- **Per-button workspace pill** — Rejected per D-11; one pill wraps all buttons.

</deferred>

---

*Phase: 13-native-api-widgets*
*Context gathered: 2026-05-03*
