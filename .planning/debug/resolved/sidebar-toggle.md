---
status: resolved
updated: "2026-10-01T17:30:00+06:00"
---

# Debug Investigation: sidebar-toggle

**Issue:** Click Clock area and verify right sidebar toggles (Test 3 in 47-UAT.md)  
**Reported:** "nope it does not and it does need to do anything when i click on it"  
**Status:** Root cause identified  
**Date:** 2026-09-29  

---

## Symptoms & UAT Gap

- **Expected:** Clicking the Clock area in the top status bar toggles `GlobalStates.sidebarRightOpen`.
- **Actual:** Clicking the Clock area does nothing.
- **User Feedback:** "nope it does not and it does need to do anything when i click on it"

---

## Hypotheses & Evidence

### Hypothesis 1: Geometry / hit-testing failure on `leftCenterGroup`
- **Theory:** In `BarContent.qml`, `leftCenterGroup` sets `implicitWidth` and `implicitHeight` but lacks explicit `width`/`height` or width anchors, potentially collapsing its hit box to 0x0.
- **Test:** Evaluated `leftCenterGroup` dimensions and bounding box via QtQuick QML runtime and PySide6 offscreen tests.
- **Findings:** Falsified. In QtQuick, `leftCenterGroup` correctly resolves its width and height from `implicitWidth` and `implicitHeight` (e.g., ~150x40 to ~220x40). The hit box is fully sized and positioned at `anchors.right: middleCenterGroup.left`.

### Hypothesis 2: Inner `MouseArea` event consumption in `ClockWidget.qml`
- **Theory:** `ClockWidget.qml` instantiates a child `MouseArea` (`id: mouseArea`) with `anchors.fill: parent` for `ClockWidgetPopup` hover target tracking. Because QtQuick's `MouseArea` defaults to `acceptedButtons: Qt.LeftButton`, it consumes mouse press events before they can bubble to ancestor items.
- **Test:** Reconstructed the exact nesting hierarchy in a PySide6 test harness (`scratch/test_click_interception.py` and `scratch/test_mousearea.qml`) and dispatched synthetic mouse press events.
- **Findings:** Confirmed.
  - With default `ClockWidget.qml` structure, dispatching a left mouse press at the clock coordinates resulted in `outerClickCount = 0`. The outer `leftCenterGroup.onPressed` handler was never invoked.
  - In QtQuick, `MouseArea` has `acceptedButtons = Qt.LeftButton` by default. Even without an `onPressed` or `onClicked` signal handler, a `MouseArea` accepts the button press by default (`mouse.accepted = true`) and establishes an exclusive mouse grab.
  - Because `propagateComposedEvents` is not enabled and the event is accepted, QtQuick stops event propagation. The ancestor `leftCenterGroup` (MouseArea) is completely starved of press events.
  - When `acceptedButtons: Qt.NoButton` was configured on `ClockWidget.qml`'s inner `MouseArea`, hover detection remained 100% operational (`containsMouse: True`), while `outerClickCount` immediately fired (`outerClickCount = 1`).

### Hypothesis 3: Historical artifact & interaction design mismatch
- **Theory:** The expectation that the Clock toggles the *right* sidebar is an unadapted upstream holdover.
- **Findings:** Confirmed.
  - In upstream dots-hyprland, `ClockWidget` was hosted in `rightCenterGroup` (located to the right of Workspaces), which also contained `UtilButtons` and `BatteryIndicator`. Upstream placed `GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen` on `rightCenterGroup` because it was situated in the right section adjacent to `barRightSideMouseArea`.
  - In Phase 47, `ClockWidget` was moved to the left of Workspaces into `leftCenterGroup`. The implementation preserved the `MouseArea` wrapping with `sidebarRightOpen` toggle, and added an AST check in `scripts/phase47-center-layout-assert.sh:200`.
  - The assert harness only checked static text (`grep -q "GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen"`), which passed without validating actual runtime mouse click delivery.
  - Ergonomically, having a widget on the *left* of the center zone open a drawer on the *far right* edge of the screen is contradictory.

### Hypothesis 4: Semantic interpretation of user feedback
- **Feedback:** "nope it does not and it does need to do anything when i click on it"
- **Analysis:**
  - In English grammar, "anything" is a negative polarity item. The phrasing "it does need to do anything" is a colloquial typo for "it does [not] need to do anything" (or "doesn't need to do anything"). If affirmative, idiomatic English would state "it does need to do something".
  - The user is reporting:
    1. Clicking the clock does not toggle the sidebar.
    2. Clicking the clock does *not* need to trigger any action (the toggle can/should be removed).

---

## Root Cause

1. **Event Absorption Defect:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml` lines 42-50 instantiates an inner `MouseArea` with `anchors.fill: parent` to host `ClockWidgetPopup` (`hoverTarget: mouseArea`). By default, QtQuick's `MouseArea` sets `acceptedButtons: Qt.LeftButton` and accepts mouse press events unconditionally. Because it sits at the top of the visual stack, it intercepts and absorbs all clicks, preventing `leftCenterGroup.onPressed` in `BarContent.qml` from ever firing.
2. **Obsolete Interaction Design:** In `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` lines 148-170, `leftCenterGroup` was modeled as a `MouseArea` toggling `GlobalStates.sidebarRightOpen`. This was a historical remnant from when the clock resided in `rightCenterGroup` on the right side of the status bar. Wiring a left-positioned clock to toggle the right sidebar is ergonomically invalid, which the user noted during UAT.

---

## Files Involved

- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`:
  - `leftCenterGroup` is wrapped in a `MouseArea` with `GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen`, which is ergonomically obsolete and non-functional.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml`:
  - `MouseArea` (`id: mouseArea`) lacks `acceptedButtons: Qt.NoButton`, causing it to absorb all clicks despite having no click handler.
- `scripts/phase47-center-layout-assert.sh`:
  - Section 2 (lines 200-204) enforces `leftCenterGroup` toggles `GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen` via static grep.
- `.planning/phases/47-center-zone-layout-reorganization/47-UAT.md`:
  - Test 3 expects "Click Clock area and verify right sidebar toggles", marked as gap G-47-3.

---

## Suggested Fix Direction (for plan-phase --gaps)

Based on the user's feedback ("it does [not] need to do anything when i click on it"):
1. **Simplify `leftCenterGroup` in `BarContent.qml`:**
   - Remove the `MouseArea` wrapper around `leftCenterGroupContent`.
   - Make `leftCenterGroup` a plain `BarGroup` directly (mirroring `weatherGroup` on the right side), removing the `onPressed` toggle for `sidebarRightOpen`.
2. **Clean up `ClockWidget.qml` (optional hygiene):**
   - If clicks should pass through harmlessly, set `acceptedButtons: Qt.NoButton` on `ClockWidget.qml`'s `mouseArea` (or replace with `HoverHandler` if supported by `StyledPopup`).
3. **Update Test Harness & Documentation:**
   - Update `scripts/phase47-center-layout-assert.sh` Section 2 to reflect that `leftCenterGroup` is a static `BarGroup` without a sidebar toggle.
   - Update `47-UAT.md` / `47-VERIFICATION.md` to remove the obsolete click-toggle expectation.
