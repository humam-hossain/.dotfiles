# Phase 15: Popup Panels - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Three popup panels — calendar, network panel, and notification center — that open from their trigger widgets in the Quickshell bar, display correct data, and dismiss cleanly on outside click. Calendar and network panel are new QML popups. Notification center is already implemented (Phase 14 D-54 — NotificationWidget toggles swaync via `swaync-client -t`).

No animations (Phase 16), no weather popup (deferred), no lock/power widgets (explicitly dropped v1.2).

Phase 15 must wait for Phase 14 to fully close (14-06 and 14-07 gap closure plans) before starting.

</domain>

<decisions>
## Implementation Decisions

### Calendar Popup (POPUP-01)
- **D-01:** Create `CalendarService.qml` — `pragma Singleton` in `services/` exposing current month/year, day grid data, prev/next month navigation, today reference. Reusable by Phase 16 animations.
- **D-02:** Day-of-week header row shown above the day grid (Mon–Sun). Monday is first day of week (ISO standard).
- **D-03:** Month navigation via Nerd Font arrow icons (/), not text buttons.
- **D-04:** Compact cell grid — cells approximately 36x36px. Matches bar aesthetic.
- **D-05:** Day cells are clickable with visual highlight (accent color). Click does NOT close the popup — visual only, sets up for future date-jump features.
- **D-06:** Adjacent-month days shown grayed out (`Colours.subtextColor`) to fill first/last week gaps.
- **D-07:** Weekend days (Saturday, Sunday) get a subtle background tint (`Colours.subtext0` at low opacity).
- **D-08:** Week numbers shown in first column (ISO week number).
- **D-09:** No month navigation range limit — prev/next wraps indefinitely.
- **D-10:** Grid auto-adjusts between 5 and 6 rows depending on month layout. Popup uses fixed height sufficient for 6 rows so size does not jump between months.
- **D-11:** Month header format: `"May 2026"` (natural language, month-first).
- **D-12:** Month header font: same 14px bold as day cells (no size hierarchy).
- **D-13:** Today highlighted with `Colours.accent` (mauve) background, not just text color.

### Network Panel (POPUP-02)
- **D-14:** Full WiFi scan via `nmcli dev wifi` — shows available networks list, not just current connection.
- **D-15:** Info-panel structured layout: Section 1 (Connection Status) on top, Section 2 (Available Networks) below.
- **D-16:** Connection status section shows: SSID, IP address (IPv4 + IPv6), gateway, DNS servers, connection type (WiFi/ethernet), signal strength, and a **Disconnect** button.
- **D-17:** Available networks list shows each network with Nerd Font signal bars (same thresholds as NetworkWidget: 󰤯 󰤟 󰤢 󰤥 󰤨), SSID name, and lock icon () for secured networks.
- **D-18:** Connected network in scan list highlighted with background color (not checkmark/icon).
- **D-19:** Click a secured SSID → inline password prompt sits above the network list (does not replace it). Prompt has: masked password field, eye icon toggle (󰛐/󰛑) for visibility, Cancel button, Connect button. Full keyboard navigation: Tab between fields, Enter submits.
- **D-20:** Connection attempt shows loading spinner. On success, highlight SSID as connected. On wrong password, show inline error message.
- **D-21:** WiFi scan Process lives inside `NetworkPopup.qml` (self-contained Timer + Process for scanning). Does NOT extend `NetworkService` — keeps widget concern separate from popup concern.
- **D-22:** Scan list auto-refreshes every 10s while panel is visible.
- **D-23:** Network list is scrollable (`Flickable` / `ScrollView`) for dense urban areas with many networks.
- **D-24:** Panel width is content-driven (adjusts to longest SSID), not fixed.
- **D-25:** Empty state: detailed message based on nmcli error (no adapter detected vs no networks found vs disabled).
- **D-26:** Old open network panel: click open Connection in nmtui via `Process { command: ["kitty", "-e", "nmtui"]; running: false }` (Phase 14 D-24 already handles this on the widget).

### Notification Center (POPUP-03)
- **D-27:** Pre-built. NotificationWidget Phase 14 D-54 already calls `swaync-client -t` to toggle swaync's native panel on click. No new QML popup file needed. Phase 15 verifies this works correctly in the end-to-end bar.

### Popup Infrastructure (Cross-Cutting)
- **D-28:** All popups inherit Phase 12 established patterns: `PopupWindow` (not PanelWindow), `HyprlandFocusGrab` for outside-click dismiss, `visible: false` (not `opacity: 0`) for input tree removal.
- **D-29:** Popups are `static visible: false` (not LazyLoader). Per P-17 consideration — start simple, add LazyLoader only if open-jank is visible.
- **D-30:** Direct import pattern: `import "./popups/" as Popups` in BarContent.qml. No `popups/qmldir` file created. Consistent with existing VolumeOsd approach.
- **D-31:** Single popup at a time — opening a new popup (calendar or network) automatically closes any currently-open popup.
- **D-32:** Escape key closes the open popup in addition to outside-click via `HyprlandFocusGrab`.
- **D-33:** Popups anchor to BarContent PanelWindow with fixed horizontal offsets (approximate widget position). Matches VolumeOsd `anchor.rect.x: parentWindow.width / 2 - implicitWidth / 2` approach — a preset offset rather than per-widget coordinate calculation.
- **D-34:** Natural cleanup on monitor hotplug — PopupWindow is a child of BarContent, destroyed automatically when its parent Variants delegate is destroyed (P-15). No explicit `Component.onDestruction` needed.
- **D-35:** Full keyboard navigation in network panel: Tab between list → password field → buttons, arrow keys navigate the SSID list, Enter submits Connect.
- **D-36:** Calendar day cell click is visual-only — does not close the popup. User dismisses via Escape or outside-click.

### Phase Sequencing
- **D-37:** Phase 15 waits for Phase 14 to fully close (14-06 and 14-07 gap closure plans must complete before planning Phase 15). Calendar and network popups do not share code with Phase 14 gap areas (CPU/Disk err, Volume OSD wpctl), but depending on Phase 14 keeps the integration surface stable.

### Agent's Discretion
- Exact `CalendarService` property/method names beyond: `currentMonth`, `currentYear`, `today`, `prevMonth()`, `nextMonth()`, `dayGrid` (or individual property per day).
- Calendar day cell internal styling (border-radius, exact padding).
- Network panel exact Flickable dimensions and scrollbar style.
- Password prompt layout spacing and positioning details.
- Fixed horizontal offset values for each popup's anchor position.
- Calendar 6-row fixed height value.
- Detailed network info parsing from nmcli output (which fields, how to extract).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Architecture and Patterns
- `.planning/research/ARCHITECTURE.md` — PopupWindow pattern (lines 254-325), PopupWindow vs PanelWindow (lines 259-262), HyprlandFocusGrab pattern (lines 298-307), Visibility state management (lines 309-315), popup summary table (lines 319-325).
- `.planning/research/PITFALLS.md` — P-01 (grabFocus → HyprlandFocusGrab), P-03 (visible: false not opacity: 0), P-15 (Variants delegation cleanup), P-16 (WlrKeyboardFocus on bar), P-17 (LazyLoader for frequently-opened popups), P-18 (deferred Process start).
- `.planning/research/SUMMARY.md` — Stack additions, architecture approach, watch-out list.

### Phase 12–14 Carryover
- `.planning/phases/12-bar-skeleton-and-theme/12-CONTEXT.md` — PopupWindow mandate (carryover from P-01/P-03), HyprlandFocusGrab pattern (P-01), ModulePill API (D-07/D-10), Colours semantic aliases (D-08).
- `.planning/phases/13-native-api-widgets/13-CONTEXT.md` — Service singleton pattern, AudioService API, PopupWindow vs PanelWindow precedent.
- `.planning/phases/14-script-backed-widgets/14-CONTEXT.md` — VolumeOsd pattern (D-47–D-51), ClockService API (D-38/D-41), NetworkService API (D-19–D-25), NotificationWidget D-54 (swaync toggle), BarContent VolumesOsd import pattern.
- `.config/quickshell/popups/VolumeOsd.qml` — Existing popup implementation, the pattern Phase 15 popups follow.
- `.config/quickshell/BarContent.qml` — Current wiring: `import "./popups/" as Popups`, VolumeOsd usage. Phase 15 adds CalendarPopup and NetworkPopup here.

### Trigger Widgets and Services
- `.config/quickshell/services/ClockService.qml` — Provided `.text` (formatted) and `.rawDate` properties. CalendarService extends this with month state.
- `.config/quickshell/services/NetworkService.qml` — `.ssid`, `.iconText`, `.connected`, `.tooltipText` for current connection. Phase 15 NetworkPopup has its own scan Process.
- `.config/quickshell/widgets/ClockWidget.qml` — Clock click → CalendarPopup. Current widget wraps ModulePill + Text.
- `.config/quickshell/widgets/NetworkWidget.qml` — Network click → NetworkPopup. Currently opens nmtui in kitty on click (D-24). Phase 15 changes click to open NetworkPopup.

### Requirements
- `.planning/REQUIREMENTS.md` §POPUP — POPUP-01 (calendar), POPUP-02 (network panel), POPUP-03 (notification toggle).
- `.planning/ROADMAP.md` §"Phase 15: Popup Panels" — Success criteria 1-3.

### Waybar Reference (behavior context)
- No Waybar popup equivalent — these are Quickshell-exclusive features. Waybar had only tooltip-based interactions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.config/quickshell/popups/VolumeOsd.qml` — Established PopupWindow pattern: `visible: false`, `show()`/`close()` functions, `PopupWindow` + anchor approach. Phase 15 popups follow this exactly.
- `.config/quickshell/services/ClockService.qml` — `.text` (formatted clock) and `.rawDate` (JS Date). CalendarService adds month/year state + day grid.
- `.config/quickshell/services/NetworkService.qml` — Connection status data. Phase 15 NetworkPopup uses its own Process for WiFi scanning (per D-21).
- `.config/quickshell/widgets/NotificationWidget.qml:32-42` — Existing `Process { command: ["swaync-client", "-t"]; running: false }` click handler (D-54). POPUP-03 is pre-built.
- `.config/quickshell/BarContent.qml:82-85` — Existing `Popups.VolumeOsd` instantiation pattern. Phase 15 adds CalendarPopup and NetworkPopup alongside it.

### Established Patterns
- `import "./popups/" as Popups` in BarContent.qml — Direct import, no qmldir needed.
- `Popups.<Name> { anchor.window: root }` — PopupWindow child of BarContent PanelWindow.
- `visible: false` + `HyprlandFocusGrab` for dismiss — Phase 12/Phase 14 established.
- Process pattern: `Timer { interval; running: true; repeat: true; triggeredOnStart: true; onTriggered: proc.running = true }` + `Process { command; stdout: StdioCollector { ... } }` — for NetworkPopup WiFi scan.
- `ModulePill` wrapping all widgets — ClockWidget and NetworkWidget are wrapped for click-to-open-popup.

### Integration Points
- `BarContent.qml` — Phase 15 adds `CalendarPopup` and `NetworkPopup` alongside existing `Popups.VolumeOsd`.
- `ClockWidget.qml` — Currently displays text only. Phase 15 adds MouseArea click handler to open CalendarPopup.
- `NetworkWidget.qml` — Currently opens nmtui on click. Phase 15 changes click to toggle NetworkPopup (nmtui remains available inside the panel).
- `services/qmldir` — Phase 15 adds `CalendarService` entry.
- `Colours.qml` — Phase 15 uses existing semantic aliases. No new colour tokens needed.
- `popups/` directory — Currently contains only `VolumeOsd.qml`. Phase 15 adds `CalendarPopup.qml` and `NetworkPopup.qml`.

### New Files
- `.config/quickshell/popups/CalendarPopup.qml` — PopupWindow with month grid, day headers, week numbers, prev/next nav, today highlight.
- `.config/quickshell/popups/NetworkPopup.qml` — PopupWindow with connection status section, available networks list, inline password prompt.
- `.config/quickshell/services/CalendarService.qml` — pragma Singleton: month/year state, prev/next month, day grid data, today reference.

</code_context>

<specifics>
## Specific Ideas

- Calendar adjacent-month days grayed (subtextColor), weekend subtle tint (subtext0), today solid accent (mauve) — three distinct visual layers.
- Network panel connection header includes disconnect button (not inline in network list row).
- Password prompt sits above the network list rather than replacing it — user sees both the form and available networks context.
- Single-popup-at-a-time: cleaner UI than multiple overlapping popups. Calendar or network, never both.
- Escape closes popup — added to HyprlandFocusGrab behavior for keyboard-first users.
- Phase sequencing: let Phase 14 fully close before Phase 15 starts. No shared code dependencies block this, but stable base preferred.
- Notification center POPUP-03 is genuinely pre-built — no QML popup file needed. The swaync-client -t toggle was already implemented as the NotificationWidget click handler in Phase 14.

</specifics>

<deferred>
## Deferred Ideas

- Weather popup (detailed current + forecast on WeatherWidget click) — mentioned in ARCHITECTURE.md but not in Phase 15 requirements. Defer to future milestone if requested.
- Calendar date-jump (click a future date → navigate to that date in system apps) — Day cells are clickable with highlight (D-05), but no navigation action is wired. Future feature.
- Hover/popup animations — Phase 16 (ANIM-01, ANIM-02).
- VPN status in network panel — not in current Waybar config, no v1.2 requirement.

</deferred>

---

*Phase: 15-popup-panels*
*Context gathered: 2026-05-22*
