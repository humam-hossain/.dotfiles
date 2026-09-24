# DEBUG: Notification Interaction Gaps & Toast Rendering Lag (G-40-10)

**Status:** root_cause_found  
**Phase:** 40-notification-center-quick-dismiss-smart-interaction  
**Gap:** G-40-10  
**Discovered:** Phase 40 UAT (Test 10)  

## Symptoms

- **Expected:** Single notification shows 'X' cancel button on desktop toasts, OTP copy pill button renders and copies code, body click behaves correctly without toast rendering lag or freeze.
- **Actual:** D-Bus works on click, but there is no cancel notification button "X" on the desktop toast, no OTP copy button renders, clicking the body does not copy the number, and there is a noticeable lag/freeze before rendering where the toast appears small, pauses/stops for a couple of seconds, and then expands.
- **Reproduction:** Dispatch notifications via `notify-send "Verification Code" "Your code is 123456"`. Observe the desktop toast popup in the top-right corner.

---

## Root Causes

### 1. Missing 'X' Close Button on Desktop Toast Popups
- **File:** `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` (L239, L254)
- **Root Cause:**
  - `closeButton.visible` is defined as:
    ```qml
    visible: !root.multipleNotifications && !root.popup
    ```
  - `expandButton.visible` is defined as:
    ```qml
    visible: root.multipleNotifications || root.popup
    ```
  - In `NotificationPopup.qml`, `NotificationListView` sets `popup: true`, which passes `popup: true` to `NotificationGroup`.
  - Because `root.popup` is `true`, `!root.popup` evaluates to `false`, explicitly suppressing the 'X' `closeButton` on desktop toast popups. Instead, `expandButton` is rendered even for single notifications.
  - Phase 40 specification REQ NOTIF-02 incorrectly assumed the user only wanted the 'X' button in the Right Sidebar and that desktop toasts should strictly suppress 'X'. In actual usage, the user expects an 'X' button on desktop notification toasts for direct 1-click dismissal.

---

### 2. Missing OTP Copy Pill Chip & Body Click Does Not Copy
- **Files:**
  - `restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml` (L128, L133, L138, L142)
  - `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` (L15, L202, L267)
  - `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` (L95)
- **Root Causes:**
  1. **Qt QML Engine Regex Incompatibility (`SyntaxError`):**
     - `NotificationUtils.extractOtpCode` uses JavaScript RegExp negative lookbehind assertions `(?<![-/0-9])`.
     - While V8 (Node.js) supports lookbehinds, Qt Quick's QML JavaScript engine (QV4) **does not support RegExp lookbehinds**.
     - When `NotificationItem.qml` binds `property string otpCode: NotificationUtils.extractOtpCode(...)`, the engine throws:
       ```
       WARN scene: @modules/common/functions/NotificationUtils.qml[128:-1]: SyntaxError: Invalid regular expression
       ```
     - Consequently, `otpCode` fails to bind and evaluates to `""` (empty string).
     - Both `collapsedOtpChip` and `expandedOtpChip` check `visible: ... && root.otpCode.length > 0`. Because `otpCode` is empty, the OTP copy pill chip **never renders at all**.
     - Note: The test harness `scripts/phase40-notification-interaction-assert.sh` evaluated `extractOtpCode` using `node` (V8) rather than Quickshell (QV4), masking this engine incompatibility.
  2. **Body Click Does Not Copy Code by Design:**
     - Because the OTP copy chip was missing due to the `SyntaxError`, the user attempted to click the notification body expecting it to copy the OTP code.
     - However, `activateNotification()` in `NotificationItem.qml` and `NotificationGroup.qml` only executes D-Bus default action invocation (`Notifications.attemptInvokeAction(..., "default")`) or URL external opening (`Qt.openUrlExternally`), falling back to card discard. It contains no clipboard copy functionality.
  3. **Missing `import qs` in `NotificationGroup.qml`:**
     - In `NotificationGroup.qml` L95, `activateNotification()` executes `GlobalStates.sidebarRightOpen = false;`.
     - However, `import qs` was omitted from `NotificationGroup.qml`, causing:
       ```
       WARN scene: @modules/common/widgets/NotificationGroup.qml[95:-1]: ReferenceError: GlobalStates is not defined
       ```
     - Clicking the body executes the D-Bus action, but then crashes with an uncaught `ReferenceError`.
  4. **DragManager Event Capture:**
     - In `NotificationGroup.qml`, `DragManager` spans `anchors.fill: parent` with `acceptedButtons: Qt.LeftButton`. When `expanded` is false, it intercepts clicks across the entire card body. While child items with their own MouseArea (like `RippleButton`) can receive clicks if stacked above it, non-interactive areas are captured by `DragManager` at the group level rather than `NotificationItem`.

---

### 3. Toast Rendering Lag, Initial Small Size, and Freeze
- **Files:**
  - `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` (L153-156)
  - `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` (L162-169)
  - `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/notificationPopup/NotificationPopup.qml` (L29-31)
- **Root Causes:**
  1. **Compound Height Animations on Component Mount:**
     - In upstream `NotificationItem.qml`, collapsed implicitHeight was statically bound to `summaryRow.implicitHeight` (~18px from font metrics, known synchronously).
     - In Phase 40, `NotificationItem.qml` was changed to bind:
       ```qml
       implicitHeight: expanded ? (contentColumn.implicitHeight + padding * 2) : contentColumn.implicitHeight
       ```
     - When `NotificationItem` is created, `contentColumn` has not yet completed its layout pass, so its implicit height starts at 0.
     - `NotificationItem` has an active `Behavior on implicitHeight` using `Appearance.animation.elementMove` (**500ms duration**, Bezier curve `[0.38, 1.21, 0.22, 1.00, 1, 1]` with expressive bounce/overshoot).
     - `NotificationGroup` also has an active `Behavior on implicitHeight` using `Appearance.animation.elementMoveFast` (**200ms duration**).
     - When the toast appears, `NotificationItem` animates its height from 0 to target over 500ms. On each animation frame, `ListView.contentHeight` increases, which in turn continuously changes the target of `NotificationGroup.implicitHeight`.
     - Because `NotificationGroup` has `clip: true`, the toast content is initially squished into a tiny height, pauses during the Bezier inflection, and slowly pops open over 500ms–1000ms.
     - Upstream `NotificationGroup.qml` had `toggleExpanded()` toggle `implicitHeightAnim.enabled`, intending the animation only for expand/collapse actions, but `implicitHeightAnim` defaults to `enabled: true` on initial mount.
  2. **Wayland Surface Mask Reconfiguration:**
     - In `NotificationPopup.qml`, `mask: Region { item: listview.contentItem }` binds the Wayland layer-shell surface input/render mask directly to the animating list item.
     - As the compound height animation runs, the Wayland compositor receives surface damage and mask resize requests on every frame, producing noticeable visual stutter and perceived freeze.
  3. **Synchronous QV4 Exception Logging:**
     - The `SyntaxError` from `extractOtpCode` throws synchronously during the delegate's initial property binding evaluation, triggering engine warnings and binding recalculation on the UI thread at the exact moment the popup window is mapped.

---

## Evidence Summary

1. **Quickshell Runtime Logs (`/run/user/1000/quickshell/by-id/2le7zzoult/log.log`):**
   ```
   WARN scene: @modules/common/functions/NotificationUtils.qml[128:-1]: SyntaxError: Invalid regular expression
   WARN scene: @modules/common/widgets/NotificationGroup.qml[95:-1]: ReferenceError: GlobalStates is not defined
   ```
2. **Quickshell Headless Regex Probe:**
   - Evaluated `new RegExp("(?<![0-9])123")` inside Quickshell:
     ```
     ERROR qml: FAIL: lookbehind SyntaxError: Invalid regular expression
     ```
   - Proves QV4 engine rejects regex lookbehinds.
3. **`NotificationGroup.qml` Line 254:**
   - `visible: !root.multipleNotifications && !root.popup` explicitly hides `closeButton` when `root.popup === true`.
4. **`NotificationItem.qml` Line 154 & `NotificationGroup.qml` Line 166:**
   - Both components define nested `Behavior on implicitHeight` animations (500ms and 200ms) that animate from 0 on initial creation instead of snapping synchronously.

---

## Files Involved

- `restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml`:
  - Replace RegExp lookbehinds `(?<!...)` in `extractOtpCode` with QV4-compatible standard regex boundaries / capture groups.
- `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml`:
  - Add missing `import qs` to resolve `GlobalStates` ReferenceError.
  - Enable `closeButton` on single desktop toast popups (`visible: !root.multipleNotifications`).
  - Adjust `expandButton.visible` to `root.multipleNotifications` so it does not replace the close button on single popups.
  - Prevent initial mount height animation by disabling `implicitHeightAnim` until an explicit expansion toggle occurs.
- `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml`:
  - Ensure `implicitHeight` does not animate from 0 on initial mount (or disable `Behavior on implicitHeight` during initial component creation).
- `scripts/phase40-notification-interaction-assert.sh`:
  - Update Section 3 to execute regex tests inside Quickshell runtime (`run_qs_test`) rather than `node` to prevent engine divergence.
  - Update Section 2 AST checks to match updated `closeButton.visible` and `expandButton.visible` conditions.

---

## Suggested Fix Direction

1. **Fix `NotificationUtils.extractOtpCode` Regex for QV4:**
   - Remove `(?<![-/0-9])` and replace with word boundary `\b`, non-digit delimiter capture `(^|[^0-9\-])`, or post-match string inspection to ensure 100% QV4 compatibility without `SyntaxError`.
2. **Fix Close Button Visibility in `NotificationGroup.qml`:**
   - Update `closeButton.visible: !root.multipleNotifications`.
   - Update `expandButton.visible: root.multipleNotifications`.
   - Add `import qs` at the top of `NotificationGroup.qml`.
3. **Eliminate Initial Toast Animation / Height Stutter:**
   - Set `implicitHeightAnim.enabled: false` by default in `NotificationGroup.qml`, enabling it only inside `toggleExpanded()`.
   - In `NotificationItem.qml`, disable `Behavior on implicitHeight` during initial component creation, or ensure initial height resolves immediately without animating from 0.
4. **Deploy & Reassert:**
   - Restow quickshell dotfiles via `stow --verbose=5 --no-folding -d restow quickshell`.
   - Update `scripts/phase40-notification-interaction-assert.sh` to test with Quickshell and verify all 5 sections pass with FAIL=0 FINDINGS=0.
