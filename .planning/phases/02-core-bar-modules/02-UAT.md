---
status: testing
phase: 02-core-bar-modules
source: 02-01-SUMMARY.md, 02-02-SUMMARY.md, 02-03-SUMMARY.md, 02-04-SUMMARY.md, 02-05-SUMMARY.md, 02-06-SUMMARY.md, 02-07-SUMMARY.md, 02-08-SUMMARY.md, 02-09-SUMMARY.md, 02-10-SUMMARY.md, 02-11-SUMMARY.md, 02-12-SUMMARY.md, 02-13-SUMMARY.md, 02-VERIFICATION.md
started: 2026-07-21T17:34:11Z
updated: 2026-07-23T04:36:42Z
---

## Current Test

number: 16
name: Left sidebar opens only on button click (retest after 02-12)
expected: |
  Click empty space on the left half of the bar → left sidebar stays closed.
  Hover/enter top-left corner → left sidebar stays closed.
  Click the left-sidebar button (distro icon) → left sidebar opens; click again → closes.
awaiting: user response

## Tests

### A1. Live config assert script encodes D-01..D-03, D-05, D-13, D-14, D-16 predicates
expected: Live config assert script encodes D-01..D-03, D-05, D-13, D-14, D-16 predicates
result: pass
source: automated
coverage_id: 02-01-D1

### A2. VALIDATION.md Wave 0 complete with task ID map and assert command
expected: VALIDATION.md Wave 0 complete with task ID map and assert command
result: pass
source: automated
coverage_id: 02-01-D2

### A3. Clock format and secondPrecision in Config + live JSON
expected: Clock format and secondPrecision in Config + live JSON
result: pass
source: automated
coverage_id: 02-02-D1

### A4. Full-color tray + pin policy dual-written
expected: Full-color tray + pin policy dual-written
result: pass
source: automated
coverage_id: 02-02-D2

### A5. Workspace appearance + weather-off locked
expected: Workspace appearance + weather-off locked
result: pass
source: automated
coverage_id: 02-02-D3

### A6. Left L→R LeftSidebar ActiveWindow Workspaces Resources
expected: Left L→R LeftSidebar ActiveWindow Workspaces Resources
result: pass
source: automated
coverage_id: 02-03-D1

### A7. Center clock with showDate false + UtilButtons
expected: Center clock with showDate false + UtilButtons
result: pass
source: automated
coverage_id: 02-03-D2

### A8. Right module order Media Battery SysTray Indicators
expected: Right module order Media Battery SysTray Indicators
result: pass
source: automated
coverage_id: 02-04-D1

### A9. Network.materialSymbol icon-only + D-19 indicator order
expected: Network.materialSymbol icon-only + D-19 indicator order
result: pass
source: automated
coverage_id: 02-04-D2

### A10. Stock workspace click/wheel dispatch (D-04); no plugin focus dispatcher
expected: Stock workspace click/wheel dispatch (D-04); no plugin focus dispatcher
result: pass
source: automated
coverage_id: 02-05-D1

### A11. ClockWidgetPopup path; showDate false; no external calendar URL
expected: ClockWidgetPopup path; showDate false; no external calendar URL
result: pass
source: automated
coverage_id: 02-05-D2

### A12. SysTray present; live tray monochrome false + pin policy
expected: SysTray present; live tray monochrome false + pin policy
result: pass
source: automated
coverage_id: 02-05-D3

### A13. Network.materialSymbol icon-only; D-19 indicator order; smoke load
expected: Network.materialSymbol icon-only; D-19 indicator order; smoke load
result: pass
source: automated
coverage_id: 02-05-D4

### 1. Click workspace switches focus
expected: Click workspace N on the bar; active Hyprland workspace changes to N
result: pass


### 2. Wheel cycles workspaces
expected: Scroll on the workspaces strip; workspace cycles with workspace r±1 behavior
result: pass


### 3. Clock updates each second
expected: Bar clock shows weekday, date, 12-hour time with seconds and AM/PM; seconds tick each second
result: pass


### 4. Clock click opens ClockWidgetPopup
expected: Click clock; popup shows date/uptime/todos — not Google Calendar
result: pass
retest_of: pending_retest
fix_plan: 02-06


### 5. Tray icons full-color + interactive
expected: Tray icons full-color (e.g. Discord/Steam); left-click activates; right-click opens menu
result: pass


### 6. Network icon state + SSID via sidebar
expected: Toggle wifi; network icon glyph changes; open right sidebar to see SSID/signal (no SSID text on bar)
result: pass


### 7. Module L→R order (D-15)
expected: Left: sidebar → workspaces → resources (no ActiveWindow); Center: clock → utils; Right: media → battery → tray → indicators
result: pass
note: "Order OK. Sub-issues closed via retests 10–13 (spacing), 11 (indicators), 12 (media popup)."


### 8. Indicators pill order (D-19)
expected: Indicators order left-to-right: mute → mic → xkb → Bluetooth → Network → notif
result: pass
note: "Order/visibility accepted after 02-08; per-icon clicks verified in retest 11."


### 9. Dual-monitor workspaces 1–10
expected: If HDMI attached: DP-1 shows workspaces 1–5, HDMI-A-2 shows 6–10 (skip if single monitor)
result: skipped
reason: HDMI-A-2 is not connected at the moment


### 10. Left module spacing (retest)
expected: Left modules (sidebar → workspaces → resources) sit with tight, coherent spacing — no large dead gaps between them
result: pass
note: "Failed after 02-09; closed by 02-11 retest (test 13)."
retest_of: G-02-9
fix_plan: 02-09

### 11. Per-icon indicator clicks (retest)
expected: Click mute icon → toggles speaker mute; click mic icon → toggles mic mute; click Bluetooth/Network/notif → opens right sidebar
result: pass
retest_of: G-02-10
fix_plan: 02-09

### 12. Media popup position (retest)
expected: Click Media module on the right side of the bar; media controls popup opens aligned near/under the Media module (right side), not center-left
result: pass
retest_of: G-02-11
fix_plan: 02-10

### 13. Left module spacing (retest after 02-11)
expected: Left modules (sidebar → workspaces → resources) sit tight on the left edge with coherent spacing; no large dead gap between Resources and center clock
result: pass
retest_of: G-02-12
fix_plan: 02-11
note: "Spacing confirmed fine. New issues filed as tests 14–15."

### 14. Left sidebar opens only on button click
expected: Left sidebar opens only when clicking the left-sidebar button (distro icon); empty bar space and hover must not open it
result: issue
reported: "the left sidebar behavior: clicking on empty space in the top bar opens left sidebar no need and mouse hovering in the left top corner also opens the left sidebar. the left sidebar should open only when i click on it."
severity: major
note: "Fix plan 02-12 executed — retesting as test 16."

### 15. Workspaces shown count is 4
expected: Bar workspaces strip shows 4 workspace indicators (not 10)
result: issue
reported: "workspaces have 10 or something like that only 4 would be enough."
severity: minor
note: "Fix plan 02-13 executed — retesting as test 17."

### 16. Left sidebar opens only on button click (retest after 02-12)
expected: Empty left-bar click and top-left corner hover do not open left sidebar; only LeftSidebarButton click toggles it
result: [pending]
retest_of: G-02-13
fix_plan: 02-12

### 17. Workspaces shown count is 4 (retest after 02-13)
expected: Bar workspaces strip shows exactly 4 workspace indicators
result: [pending]
retest_of: G-02-14
fix_plan: 02-13


## Summary

total: 30
passed: 24
issues: 2
pending_retest: 0
pending: 2
skipped: 1
blocked: 0

## Gaps

- gap_id: G-02-4
  truth: "Click clock; popup shows date/uptime/todos — not Google Calendar"
  status: resolved
  reason: "Code fix shipped in 02-06 (forceActive + onClicked); re-UAT passed"
  severity: major
  test: 4
  fixed_by: 02-06
  resolved_by: 02-06
  resolved_at: 2026-07-22
  commits: [3a852d3, 14eea6e]
  debug_session: ".planning/debug/resolved/clock-click-no-op.md"

- gap_id: G-02-7a
  truth: "Left region has no ActiveWindow; workspaces have room"
  status: resolved
  reason: "ActiveWindow removed (02-07); user confirmed rest of left order works"
  severity: major
  test: 7
  fixed_by: 02-07
  resolved_by: 02-07
  resolved_at: 2026-07-22
  commits: [113b10a]
  debug_session: ".planning/debug/resolved/remove-active-window.md"

- gap_id: G-02-7b
  truth: "Indicators pill shows mute → mic → xkb → Bluetooth → Network → notif (D-19)"
  status: resolved
  reason: "Always-visible strip shipped (02-08); user moved on to per-icon interaction (new gap G-02-10)"
  severity: major
  test: 7
  fixed_by: 02-08
  resolved_by: 02-08
  resolved_at: 2026-07-22
  commits: [71022b9]
  debug_session: ".planning/debug/resolved/indicators-only-network.md"

- gap_id: G-02-8
  truth: "Indicators order left-to-right: mute → mic → xkb → Bluetooth → Network → notif"
  status: resolved
  reason: "Order/visibility accepted after 02-08; remaining work is per-icon click (G-02-10)"
  severity: major
  test: 8
  fixed_by: 02-08
  resolved_by: 02-08
  resolved_at: 2026-07-22
  commits: [71022b9]
  debug_session: ".planning/debug/resolved/indicators-only-network.md"

- gap_id: G-02-9
  truth: "Left modules (sidebar → workspaces → resources) sit with coherent, tight spacing"
  status: resolved
  resolved_by: 02-09-SUMMARY.md
  resolved_at: 2026-07-23
  fixed_by: 02-09
  reason: "User reported: the spacing between sidebar, workspaces and resources are not coherent. they are spaced too long between each other which looks odd."
  severity: cosmetic
  test: 7
  root_cause: "Left cluster is a bare RowLayout with anchors.fill over the full left half of the bar; margins are uneven (screenRounding on outer edges, Layout.leftMargin: 10 on Workspaces) and modules are not grouped. After ActiveWindow (fillWidth spacer) was removed, the three remaining modules keep ad-hoc margins tuned for the old four-module layout, so inter-module rhythm looks sparse/incoherent."
  artifacts:
    - path: ".config/quickshell/modules/ii/bar/BarContent.qml"
      issue: "leftSectionRowLayout spacing:0 + uneven Layout margins; no BarGroup wrapper; fill-to-center mouse area"
  missing:
    - "Uniform small inter-item spacing (e.g. 4–8) for left cluster"
    - "Optional BarGroup wrap so left modules read as one compact unit"
    - "Drop leftover ActiveWindow-era leftMargin:10 if it creates a dead gap"
  debug_session: ".planning/debug/left-module-spacing.md"

- gap_id: G-02-12
  truth: "Left modules (sidebar → workspaces → resources) sit with coherent, tight spacing"
  status: resolved
  resolved_by: 02-11-SUMMARY.md
  resolved_at: 2026-07-23
  fixed_by: 02-11
  reason: "User reported: no the spacing hasn't change (retest of G-02-9 after fix plan 02-09). Fix plan 02-11 executed — retesting."
  severity: cosmetic
  test: 10
  root_cause: "The spacing:6 fix on leftSectionRowLayout IS applied, but the RowLayout has anchors.fill:parent which fills the entire FocusedScrollMouseArea (anchored from parent.left to middleSection.left). The three modules don't use Layout.fillWidth, so they cluster at their natural sizes in a container that spans half the screen. The visual dead space is between Resources (last left module) and the center clock — not between the modules themselves. The fix needs to either (a) remove anchors.fill and let the RowLayout be implicitWidth-sized, or (b) NOT use anchors.fill on leftSectionRowLayout so modules hug left edge tightly."
  artifacts:
    - path: ".config/quickshell/modules/ii/bar/BarContent.qml"
      lines: "80-114"
      issue: "leftSectionRowLayout anchors.fill:parent stretches across full left half; spacing:6 correct but modules float in oversized container"
  missing:
    - "Change leftSectionRowLayout from anchors.fill to anchors.left+verticalCenter (or top+bottom+left) so it sizes to content"
    - "Verify barLeftSideMouseArea still covers the left region for scroll/click events"

- gap_id: G-02-10
  truth: "Mute and mic icons toggle mute on click; Bluetooth/Network/notif open right sidebar"
  status: resolved
  resolved_by: 02-09-SUMMARY.md
  resolved_at: 2026-07-23
  fixed_by: 02-09
  reason: "User reported: indicators click thing need to be individual — audio output and input toggle mute; bluetooth, wifi, notif open right sidebar as usual"
  severity: major
  test: 8
  root_cause: "D-19 icons are pure MaterialSymbol children inside one RippleButton whose onPressed always toggles GlobalStates.sidebarRightOpen. barRightSideMouseArea also opens the sidebar on any left-click in the right half. Mute/mic have no MouseArea and never call Audio.toggleMute()/toggleMicMute(). No per-icon hit targets exist."
  artifacts:
    - path: ".config/quickshell/modules/ii/bar/BarContent.qml"
      issue: "indicatorsRowLayout icons are display-only; whole pill is one sidebar toggle"
    - path: ".config/quickshell/services/Audio.qml"
      issue: "toggleMute/toggleMicMute exist but are not wired to bar icons"
  missing:
    - "MouseArea (or clickable wrapper) on mute → Audio.toggleMute()"
    - "MouseArea on mic → Audio.toggleMicMute()"
    - "Bluetooth/Network/notif keep sidebar open (or whole-pill fallback for non-audio icons)"
    - "Stop parent RippleButton / barRightSideMouseArea from swallowing mute/mic clicks"
  debug_session: ".planning/debug/indicator-per-icon-clicks.md"

- gap_id: G-02-11
  truth: "Media controls popup opens aligned under/near the bar Media module (right side)"
  status: resolved
  resolved_by: 02-10-SUMMARY.md
  resolved_at: 2026-07-23
  fixed_by: 02-10
  reason: "User reported: clicking on the media opens popup not in the right place — position from before media was rearranged to right module order"
  severity: major
  test: 7
  root_cause: "MediaControls PanelWindow uses a hard-coded left margin formula that places the popup left-of-center: ((screen.width/2) - (osdWidth/2) - widgetWidth). That matched the old center-left media placement. After D-15, Media lives on the right (Media → Battery → SysTray → Indicators), but MediaControls.qml was never re-anchored to the Media widget or right edge."
  artifacts:
    - path: ".config/quickshell/modules/ii/mediaControls/MediaControls.qml"
      issue: "margins.left hard-coded to center-left; anchors.left true for horizontal bar"
    - path: ".config/quickshell/modules/ii/bar/Media.qml"
      issue: "only toggles GlobalStates.mediaControlsOpen; no position anchor for popup"
  missing:
    - "Reposition media popup under/near right-side Media module (right-edge or mapFromItem)"
    - "Keep vertical-bar path working"
  debug_session: ".planning/debug/media-popup-position.md"

- gap_id: G-02-13
  truth: "Left sidebar opens only when clicking the left-sidebar button; empty bar space and hover do not open it"
  status: resolved
  resolved_by: 02-12-SUMMARY.md
  resolved_at: 2026-07-23
  fixed_by: 02-12
  reason: "User reported: clicking on empty space in the top bar opens left sidebar no need and mouse hovering in the left top corner also opens the left sidebar. the left sidebar should open only when i click on it. Fix plan 02-12 executed — retesting."
  severity: major
  test: 14
  root_cause: "Two open paths besides LeftSidebarButton: (1) barLeftSideMouseArea.onPressed toggles sidebarLeftOpen on any left-click across the entire left half of the bar; (2) ScreenCorners TopLeft action + live sidebar.cornerOpen.clicklessCornerEnd=true fires the same toggle when the pointer enters the top-left corner edge (≤2px), without a button click. Logs from AiChat/Anime/ToolbarTabBar are load side-effects after open, not the trigger."
  artifacts:
    - path: ".config/quickshell/modules/ii/bar/BarContent.qml"
      lines: "65-68"
      issue: "barLeftSideMouseArea left-click toggles left sidebar on empty space"
    - path: ".config/quickshell/modules/ii/screenCorners/ScreenCorners.qml"
      lines: "16-17, 81-95"
      issue: "TopLeft/BottomLeft cornerOpen + clicklessCornerEnd hover toggle"
    - path: ".config/quickshell/modules/common/Config.qml"
      issue: "sidebar.cornerOpen.enable true, clicklessCornerEnd true defaults"
  missing:
    - "Remove sidebarLeftOpen toggle from barLeftSideMouseArea.onPressed (keep brightness scroll)"
    - "Disable corner-open path for left sidebar (enable false and/or clicklessCornerEnd false + dual-write)"
    - "LeftSidebarButton remains sole open/close control"
  debug_session: ".planning/debug/left-sidebar-empty-click-hover.md"

- gap_id: G-02-14
  truth: "Bar workspaces strip shows 4 workspace indicators (not 10)"
  status: resolved
  resolved_by: 02-13-SUMMARY.md
  resolved_at: 2026-07-23
  fixed_by: 02-13
  reason: "User reported: workspaces have 10 or something like that only 4 would be enough. Fix plan 02-13 executed — retesting."
  severity: minor
  test: 15
  root_cause: "bar.workspaces.shown is 10 by design (Phase 2 D-02 dual-written to Config.qml + live config.json; phase02-config-assert expects 10). WorkspaceModel.shownCount binds that value. Not a layout bug — UAT preference overrides D-02 to shown: 4."
  artifacts:
    - path: ".config/quickshell/modules/common/Config.qml"
      issue: "property int shown: 10"
    - path: "~/.config/illogical-impulse/config.json"
      issue: "bar.workspaces.shown: 10"
    - path: "scripts/phase02-config-assert.py"
      issue: "assert shown == 10"
  missing:
    - "Dual-write shown: 4 in Config.qml and live config.json"
    - "Update phase02-config-assert.py to expect 4"
    - "Document D-02 override from UAT preference"
  debug_session: ".planning/debug/workspaces-shown-count.md"
