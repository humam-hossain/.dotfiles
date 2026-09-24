# Phase 40: Notification Center Quick-Dismiss & Smart Interaction - Pattern Map

**Mapped:** 2026-09-24  
**Files analyzed:** 4 (3 QML overlays, 1 assertion test harness)  
**Analogs found:** 4 / 4 (100% coverage)  

---

## File Classification

| New / Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml` | utility / singleton | transform / extraction | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml` | exact |
| `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` | component / card container | event-driven / composite | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` & `vendor/.../widgets/NotificationGroupExpandButton.qml` | exact |
| `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` | component / notification row | event-driven / transform | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` & `vendor/.../widgets/NotificationActionButton.qml` | exact |
| `scripts/phase40-notification-interaction-assert.sh` | test / verification harness | batch / assert runner | `scripts/phase39-media-popup-assert.sh` & `scripts/phase38-power-profiles-assert.sh` | role-match |

---

## Pattern Assignments

### 1. `restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml` (utility / singleton, transform)

**Analog:** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml` (lines 1-5, 88-111)

**Upstream Singleton Structure Pattern** (`NotificationUtils.qml` lines 1-5, 88-111):
```qml
1: pragma Singleton
2: import Quickshell
3: 
4: Singleton {
5:     id: root
...
88:     function processNotificationBody(body, appName) {
89:         let processedBody = body
90:         
91:         // Clean Chromium-based browsers notifications - remove first line
92:         if (appName) {
93:             const lowerApp = appName.toLowerCase()
94:             const chromiumBrowsers = [
95:                 "brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge"
96:             ]
97: 
98:             if (chromiumBrowsers.some(name => lowerApp.includes(name))) {
99:                 const lines = body.split('\n\n')
100: 
101:                 if (lines.length > 1 && lines[0].startsWith('<a')) {
102:                     processedBody = lines.slice(1).join('\n\n')
103:                 }
104:             }
105:         }
106: 
107:         processedBody = processedBody.replace(/<img/gi, '\n\n<img');
108:         
109:         return processedBody
110:     }
111: }
```

**Pattern Application for Phase 40:**
Seed `NotificationUtils.qml` from upstream preserving `findSuitableMaterialSymbol`, `getFriendlyNotifTimeString`, and `processNotificationBody`. Add two new pure extraction methods (`extractOtpCode` and `extractUrl`) adhering to D-05 and D-07:

```javascript
    /**
     * Extracts 4-8 digit verification code, hyphenated code, or service-prefixed code
     * anchored to security keywords.
     * @param { string } body
     * @param { string } summary
     * @returns { string }
     */
    function extractOtpCode(body = "", summary = "") {
        const fullText = (summary ? summary + " " : "") + (body || "");
        if (!fullText) return "";
        const cleaned = fullText.replace(/<[^>]*>/g, " ");

        const keywords = "code|otp|verify|verification|pin|auth|2fa|security|one-time|password|passcode";
        const codePattern = "(?:[A-Za-z]{1,2}-\\d{4,8}|\\d{3,4}-\\d{3,4}|\\b\\d{4,8}\\b)";

        // 1. Keyword before code (e.g. "verification code is 482910", "code: G-123456")
        const reKeywordBefore = new RegExp("(?:\\b(?:" + keywords + ")\\b)[^\\w\\r\\n]{0,30}?(?:is\\s+|:\\s*|\\s+)?(" + codePattern + ")(?![-/0-9])", "i");
        const m1 = cleaned.match(reKeywordBefore);
        if (m1 && m1[1]) return m1[1].trim();

        // 2. Code before keyword (e.g. "123-456 is your verification code")
        const reCodeBefore = new RegExp("(?:(?<![-/0-9])(" + codePattern + ")[^\\w\\r\\n]{0,30}?(?:is\\s+|for\\s+|as\\s+|to\\s+)?(?:\\b(?:" + keywords + ")\\b))", "i");
        const m2 = cleaned.match(reCodeBefore);
        if (m2 && m2[1]) return m2[1].trim();

        // 3. Proximity within sentence (e.g. "Your Google code is 839201. Sent on...")
        const reProximity = new RegExp("(?:\\b(?:" + keywords + ")\\b)[^\\r\\n]{1,60}?(?<![-/0-9])(" + codePattern + ")(?![-/0-9])", "i");
        const m3 = cleaned.match(reProximity);
        if (m3 && m3[1]) return m3[1].trim();

        const reProximityReverse = new RegExp("(?<![-/0-9])(" + codePattern + ")[^\\r\\n]{1,60}?(?:\\b(?:" + keywords + ")\\b)", "i");
        const m4 = cleaned.match(reProximityReverse);
        if (m4 && m4[1]) return m4[1].trim();

        return "";
    }

    /**
     * Extracts destination URL from Chromium HTML anchor (<a href="...">) or raw http(s) URL.
     * @param { string } body
     * @returns { string }
     */
    function extractUrl(body = "") {
        if (!body) return "";

        // 1. HTML anchor tag href (Chromium notifications)
        const aMatch = body.match(/<a\s+[^>]*href=["']([^"']+)["']/i);
        if (aMatch && aMatch[1]) {
            return aMatch[1].replace(/&amp;/g, "&").trim();
        }

        // 2. Standalone raw URL (strip trailing punctuation)
        const urlMatch = body.match(/\bhttps?:\/\/[^\s<>"'()]+[^\s<>"'().,;:!?]/i);
        if (urlMatch && urlMatch[0]) {
            return urlMatch[0].replace(/&amp;/g, "&").trim();
        }

        return "";
    }
```

---

### 2. `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` (component / card container, composite)

**Analog 1 (Group Header & Layout):** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` (lines 18-20, 35-40, 81-97, 138-141, 175-227)  
**Analog 2 (Button Styling & Visual Feedback):** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationGroupExpandButton.qml` (lines 7-22)

**Upstream Header & Button Structure** (`NotificationGroup.qml` lines 175-227):
```qml
175:                 Item { // App name (or summary when there's only 1 notif) and time
176:                     id: topRow
177:                     // spacing: 0
178:                     Layout.fillWidth: true
179:                     property real fontSize: Appearance.font.pixelSize.smaller
180:                     property bool showAppName: root.multipleNotifications
181:                     implicitHeight: Math.max(topTextRow.implicitHeight, expandButton.implicitHeight)
182: 
183:                     RowLayout {
184:                         id: topTextRow
185:                         anchors.left: parent.left
186:                         anchors.right: expandButton.left
187:                         anchors.verticalCenter: parent.verticalCenter
188:                         spacing: 5
...
212:                     }
213:                     NotificationGroupExpandButton {
214:                         id: expandButton
215:                         anchors.right: parent.right
216:                         anchors.verticalCenter: parent.verticalCenter
217:                         count: root.notificationCount
218:                         expanded: root.expanded
219:                         fontSize: topRow.fontSize
220:                         onClicked: { root.toggleExpanded() }
221:                         altAction: () => { root.toggleExpanded() }
222: 
223:                         StyledToolTip {
224:                             text: Translation.tr("Tip: right-clicking a group\nalso expands it")
225:                         }
226:                     }
227:                 }
```

**Upstream Button Styling Tokens** (`NotificationGroupExpandButton.qml` lines 11-22):
```qml
11:     property real fontSize: Appearance?.font.pixelSize.small ?? 12
12:     property real iconSize: Appearance?.font.pixelSize.normal ?? 16
13:     implicitHeight: fontSize + 4 * 2
14:     implicitWidth: Math.max(contentItem.implicitWidth + 5 * 2, 30)
15:     Layout.alignment: Qt.AlignVCenter
16:     Layout.fillHeight: false
17: 
18:     buttonRadius: Appearance.rounding.full
19:     colBackground: ColorUtils.mix(Appearance?.colors.colLayer2, Appearance?.colors.colLayer2Hover, 0.5)
20:     colBackgroundHover: Appearance?.colors.colLayer2Hover ?? "#E5DFED"
21:     colRipple: Appearance?.colors.colLayer2Active ?? "#D6CEE2"
```

**Pattern Application for Phase 40:**
1. **Single Notification Close Button (D-01, NOTIF-01, NOTIF-02):**
   - Add a `RippleButton` with `id: closeButton` in `topRow`.
   - Set visibility to `visible: !root.multipleNotifications && !root.popup`.
   - Style with `buttonRadius: Appearance.rounding.full`, matching `expandButton` token styling.
   - Anchor `closeButton` to `anchors.right: parent.right` and `anchors.verticalCenter: parent.verticalCenter`.
   - Update `expandButton.visible` to `visible: root.multipleNotifications || root.popup` (D-02, D-03).
   - Dynamically bind `topTextRow.anchors.right`:
     `anchors.right: expandButton.visible ? expandButton.left : (closeButton.visible ? closeButton.left : parent.right)`
   - Dynamically calculate `topRow.implicitHeight`:
     `Math.max(topTextRow.implicitHeight, expandButton.visible ? expandButton.implicitHeight : closeButton.implicitHeight)`.
   - On click, execute `root.destroyWithAnimation()`.
2. **Card Height Expansion Clamping Fix (Pitfall 3):**
   - Update `background.implicitHeight` from:
     `implicitHeight: root.expanded ? row.implicitHeight + padding * 2 : Math.min(80, row.implicitHeight + padding * 2)`
   - To:
     `implicitHeight: (root.expanded || !root.multipleNotifications) ? row.implicitHeight + padding * 2 : Math.min(80, row.implicitHeight + padding * 2)`
   - This ensures single notification cards displaying the OTP pill chip or longer summary are not truncated at 80px.
3. **Smart Body Click Activation (D-04, D-05, D-06, NAV-01, NAV-02):**
   - In `dragManager.onClicked`:
     ```qml
     onClicked: (mouse) => {
         if (mouse.button === Qt.MiddleButton) {
             root.destroyWithAnimation();
         } else if (mouse.button === Qt.LeftButton) {
             if (root.multipleNotifications) {
                 root.toggleExpanded();
             } else {
                 root.activateNotification();
             }
         }
     }
     ```
   - Define `activateNotification()` on `root`:
     ```javascript
     function activateNotification() {
         if (root.notifications.length === 0) return;
         const notif = root.notifications[0];
         const hasDefaultAction = notif.actions?.some(a => a.identifier === "default");
         const extractedUrl = NotificationUtils.extractUrl(notif.body);

         if (hasDefaultAction) {
             Notifications.attemptInvokeAction(notif.notificationId, "default");
         } else if (extractedUrl) {
             Qt.openUrlExternally(extractedUrl);
             Notifications.discardNotification(notif.notificationId);
         } else {
             Notifications.discardNotification(notif.notificationId);
         }
         GlobalStates.sidebarRightOpen = false;
     }
     ```

---

### 3. `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` (component / notification row, event-driven)

**Analog 1 (Item Structure & Interaction):** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` (lines 14-20, 65-78, 140-181, 286-316)  
**Analog 2 (Action Button Styling):** `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationActionButton.qml` (lines 6-24)

**Upstream Clipboard Copy Pattern** (`NotificationItem.qml` lines 286-316):
```qml
286:                             NotificationActionButton {
287:                                 Layout.fillWidth: true
288:                                 urgency: notificationObject.urgency
289:                                 implicitWidth: (notificationObject.actions.length == 0) ? ((actionsFlickable.width - actionRowLayout.spacing) / 2) : 
290:                                     (contentItem.implicitWidth + leftPadding + rightPadding)
291: 
292:                                 onClicked: {
293:                                     Quickshell.clipboardText = notificationObject.body
294:                                     copyIcon.text = "inventory"
295:                                     copyIconTimer.restart()
296:                                 }
297: 
298:                                 Timer {
299:                                     id: copyIconTimer
300:                                     interval: 1500
301:                                     repeat: false
302:                                     onTriggered: {
303:                                         copyIcon.text = "content_copy"
304:                                     }
305:                                 }
...
316:                             }
```

**Upstream DragManager Interaction** (`NotificationItem.qml` lines 65-78):
```qml
65:     DragManager { // Drag manager
66:         id: dragManager
67:         anchors.fill: root
68:         anchors.leftMargin: root.expanded ? -notificationIcon.implicitWidth : 0
69:         interactive: expanded
70:         automaticallyReset: false
71:         acceptedButtons: Qt.LeftButton | Qt.MiddleButton
72: 
73:         onClicked: (mouse) => {
74:             if (mouse.button === Qt.MiddleButton) {
75:                 root.destroyWithAnimation();
76:             }
77:         }
```

**Pattern Application for Phase 40:**
1. **Property & Activation Routing (D-04, D-05, D-06):**
   - Declare `property string otpCode: NotificationUtils.extractOtpCode(notificationObject?.body, notificationObject?.summary)`.
   - Implement `activateNotification()` routing D-Bus `default` action first, URL fallback second, card discard and `GlobalStates.sidebarRightOpen = false` in all paths.
   - Update `dragManager.onClicked`:
     ```qml
     onClicked: (mouse) => {
         if (mouse.button === Qt.MiddleButton) {
             root.destroyWithAnimation();
         } else if (mouse.button === Qt.LeftButton) {
             root.activateNotification();
         }
     }
     ```
2. **Icon-Free Material 3 OTP Pill Chip (D-08, D-09, OTP-02):**
   - Render a dedicated `RippleButton` pill chip directly beneath the notification text in `contentColumn` (for collapsed preview) and inside `expandedContentColumn` (for expanded view).
   - **Styling Tokens:**
     - `buttonRadius: Appearance.rounding.full`
     - `implicitHeight: 28`
     - `implicitWidth: otpChipText.implicitWidth + 24`
     - `colBackground: Appearance.colors.colSecondaryContainer`
     - `colBackgroundHover: ColorUtils.mix(Appearance.colors.colSecondaryContainer, Appearance.colors.colOnSecondaryContainer, 0.15)`
     - `colRipple: ColorUtils.mix(Appearance.colors.colSecondaryContainer, Appearance.colors.colOnSecondaryContainer, 0.3)`
   - **Icon-Free Text Item:**
     - `StyledText { id: otpChipText; anchors.centerIn: parent; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: Appearance.colors.colOnSecondaryContainer; text: copied ? Translation.tr("Copied!") : Translation.tr("Copy %1").arg(root.otpCode) }`
   - **Click Handling:**
     - Copies `Quickshell.clipboardText = root.otpCode`.
     - Flips `copied = true`.
     - 1500ms `Timer` resets `copied = false`.
     - Mouse clicks are self-contained and do not trigger `activateNotification()` or close the sidebar.

---

### 4. `scripts/phase40-notification-interaction-assert.sh` (test / verification harness, assert runner)

**Analog:** `scripts/phase39-media-popup-assert.sh` (lines 1-118, 504-544) & `scripts/phase38-power-profiles-assert.sh` (lines 1-103)

**Harness Boilerplate & Execution Pattern** (`phase39-media-popup-assert.sh` lines 1-64, 526-544):
```bash
#!/usr/bin/env bash
set -euo pipefail

[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
cleanup() {
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true
  return 0
}
trap cleanup EXIT

# Section filtering (--section|-s <1-5>) and syntax only (--syntax|-c)
```

**Pattern Application for Phase 40:**
Build `scripts/phase40-notification-interaction-assert.sh` with 5 targeted sections:
- **Section 1 (Symlink & Packaging Integrity):**
  - Asserts `restow/quickshell/.../NotificationGroup.qml`, `NotificationItem.qml`, `NotificationUtils.qml` exist.
  - Asserts `~/.config/quickshell/ii/...` targets are valid leaf symlinks into `restow/quickshell/` with zero directory folding.
  - Asserts `vendor/dots-hyprland` working tree is 100% clean.
- **Section 2 (Static AST & QML Property Verification):**
  - Asserts `NotificationGroup.qml` declares `closeButton` with `visible: !root.multipleNotifications && !root.popup` and `root.destroyWithAnimation()`.
  - Asserts `NotificationItem.qml` declares `otpCode`, `activateNotification`, `colSecondaryContainer`, and `Quickshell.clipboardText`.
  - Asserts `NotificationUtils.qml` exports `extractOtpCode` and `extractUrl`.
- **Section 3 (OTP Code Regex Extraction Test Matrix):**
  - Runs headless Node.js or Quickshell execution against a 19-case test suite:
    - Positive: 4-digit PIN, 6-digit standard, 8-digit auth, hyphenated `123-456`, Google `G-123456`, proximity preceding/trailing code, keyword variations (`code`, `otp`, `verify`, `pin`, `auth`, `2fa`, `security`, `one-time`, `password`, `passcode`).
    - Negative: calendar dates (`2026-09-24`), timestamps (`14:30`), phone numbers (`+1-800-555-0199`), order IDs (`ORD-9482103`), counter metrics (`1048576 bytes`).
- **Section 4 (URL Extraction & Body Click Routing Execution):**
  - Runs headless validation against Chromium HTML anchors (`<a href="https://web.whatsapp.com">`), raw URLs (`https://github.com/pera`), and trailing punctuation exclusion (`https://example.com/api.`).
  - Verifies precedence: D-Bus `default` action invoked first; URL fallback invoked second; passive dismissal third; sidebar closed in all paths.
- **Section 5 (Repository Integrity & Strict Verification):**
  - Executes `./arch/dots-hyprland.sh verify --strict` requiring `FAIL=0 FINDINGS=0`.
  - Checks git porcelain status before and after execution to guarantee zero drift.

---

## Shared Design Tokens & Component Library

| Design Token / API | Source Provenance | Value / Expression | Usage in Phase 40 |
|---|---|---|---|
| `colSecondaryContainer` | `Appearance.qml:161` | `Appearance.colors.colSecondaryContainer` | OTP pill chip background color. |
| `colOnSecondaryContainer` | `Appearance.qml:164` | `Appearance.colors.colOnSecondaryContainer` | OTP pill chip text color. |
| `colLayer2` / `colLayer2Hover` | `Appearance.qml:150-151` | `Appearance.colors.colLayer2` | Close button idle background and hover state. |
| `rounding.full` | `Appearance.qml:369` | `Appearance.rounding.full` (9999) | Rounding for close button and OTP pill chip. |
| `fontSize.smaller` | `Appearance.qml:342` | `Appearance.font.pixelSize.smaller` | Header close button icon size and OTP chip font size. |
| `Quickshell.clipboardText` | Built-in Quickshell API | `Quickshell.clipboardText = code` | Synchronously copies OTP code to system clipboard. |
| `Notifications.attemptInvokeAction` | `Notifications.qml:239` | `Notifications.attemptInvokeAction(id, "default")` | Triggers D-Bus default action to focus sending application. |
| `Notifications.discardNotification` | `Notifications.qml:192` | `Notifications.discardNotification(id)` | Cleanly dismisses notification from tracking and disk. |
| `GlobalStates.sidebarRightOpen` | `GlobalStates.qml:16` | `GlobalStates.sidebarRightOpen = false` | Automatically closes Right Sidebar upon body activation. |
| `Qt.openUrlExternally` | Qt Quick API | `Qt.openUrlExternally(url)` | Opens extracted HTTP/HTTPS link in default browser via portal. |

---

## Architectural Constraints Checklist

- [x] **Zero Submodule Churn:** Upstream `vendor/dots-hyprland` must never be touched directly. All changes originate in `restow/quickshell/`.
- [x] **Leaf Symlinks Only:** Deployment through GNU Stow must use `--no-folding`, ensuring each modified `.qml` file is an independent leaf symlink.
- [x] **Toast Popup Upstream Purity (NOTIF-02):** The header close button must never appear on desktop toast popups (`popup: true`). Toast hover-to-dismiss and timeout lifecycles remain completely untouched.
- [x] **Multi-Group Upstream Parity (D-02):** Notification groups with multiple notifications must strictly display the upstream `NotificationGroupExpandButton` and notification count; no group close button is added.
- [x] **Gesture & Click Non-Interference:** DragManager gestures (swipe-to-dismiss) must not be blocked by full-card child MouseAreas.
- [x] **Dynamic Card Height Safety:** Clamping to 80px must be bypassed for single notifications and cards displaying the OTP chip to prevent visual clipping.
- [x] **Strict D-Bus Guard:** `attemptInvokeAction` must only be invoked when the `"default"` action actually exists in `notificationObject.actions`, avoiding unhandled TypeErrors.
- [x] **URL Protocol Sanitization:** Only valid HTTP/HTTPS schemes may be launched via `Qt.openUrlExternally`, preventing arbitrary scheme execution.
- [x] **No Decorative Icons on OTP Chip (D-08):** The OTP chip must strictly be a clean text-only pill (`Copy [Code]` / `Copied!`), with no key, lock, or clipboard icon.
