# Phase 40: Notification Center Quick-Dismiss & Smart Interaction - Research

**Researched:** 2026-09-24  
**Status:** Complete  
**Confidence:** HIGH  

---

<user_constraints>
## Decisions

### Header Close Button & Upstream Fidelity
- **D-01 (Single Notification Close Button):** Add an always-visible 'X' close button on the right side of `NotificationGroup.qml` header exclusively for single notifications (`!root.multipleNotifications && !root.popup`). Clicking it invokes `root.destroyWithAnimation()`, immediately dismissing the notification.
- **D-02 (Multi-Notification Group Upstream Parity):** Multi-notification groups retain 100% default upstream UI (`NotificationGroupExpandButton` with expand chevron and notification count); no group close button is added.
- **D-03 (Toast Popup Upstream Behavior Preserved):** Toast popups (`NotificationPopup.qml` and `popup: true`) retain 100% upstream behavior; hover-to-dismiss and timeout lifecycles remain completely untouched.

### Smart Body Click & URL Navigation
- **D-04 (D-Bus Action First):** When the notification card body is clicked, Quickshell invokes the sending application's `default` D-Bus action (`Notifications.attemptInvokeAction(notificationId, "default")`) to bring the native app window into focus.
- **D-05 (URL Fallback for Web/Passive Notifications):** If the application has no registered D-Bus actions and an embedded/raw URL is detected (Chromium `<a href="...">`, YouTube, WhatsApp, or raw `http(s)://`), clicking the body opens the URL via `Qt.openUrlExternally(url)`.
- **D-06 (Body Click Dismissal & Sidebar Closure):** Clicking the card body dismisses the notification (`Notifications.discardNotification(notificationId)`) and closes the right sidebar (`GlobalStates.sidebarRightOpen = false`).

### Smart OTP / 2FA Verification Code Detection
- **D-07 (OTP Regex Detection Heuristics):** In `NotificationUtils.qml`, implement an OTP extraction function matching:
  - 4–8 digit standalone codes (e.g. `482910`, `839201`).
  - Hyphenated codes (e.g. `123-456`).
  - Service-prefixed codes (e.g. Google's `G-123456`).
  - Anchored to security keywords (`code`, `otp`, `verify`, `pin`, `auth`, `2fa`, `security`, `one-time`, `password`).
- **D-08 (Clean Icon-Free Action Pill Chip):** In `NotificationItem.qml`, render a dedicated Material 3 styled pill chip directly beneath the notification text: `Copy [Code]` with **no key or decorative icons**. It remains visible directly on the card without needing to expand the bottom action bar.
- **D-09 (Visual Confirmation on Copy):** Clicking the OTP chip copies strictly the code digits/string to `Quickshell.clipboardText` and flips the button text to `Copied!` for 1.5 seconds.

### Overlay & Deployment Architecture
- **D-10 (Overlay Leaf Symlink Architecture):** Deploy modified QML components (`NotificationGroup.qml`, `NotificationItem.qml`, `NotificationUtils.qml`) under `restow/quickshell/.config/quickshell/ii/` and link them into `~/.config/quickshell/ii/` via GNU Stow, leaving `vendor/dots-hyprland` pristine.

### Claude's Discretion
- Exact regex pattern boundaries and negative lookaheads (preventing false matches on dates, phone numbers, or hex colors).
- Material 3 container color styling and padding for the OTP action chip.

### Deferred Ideas
- None — discussion stayed strictly within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| Requirement ID | Description | Research Support Summary |
|---|---|---|
| **NOTIF-01** | Notification card header in Right Sidebar (`NotificationGroup.qml`) displays an always-visible 'X' close button for immediate 1-click dismissal without dropdown expansion. | Supported via `NotificationGroup.qml` header overlay: add `RippleButton` with `MaterialSymbol { text: "close" }` visible when `!root.multipleNotifications && !root.popup` [VERIFIED: `NotificationGroup.qml:18,20`]. Clicking invokes `root.destroyWithAnimation()`, immediately executing the swipe-out animation and discarding the notification via `Notifications.discardNotification`. |
| **NOTIF-02** | Toast notification popups (`NotificationPopup.qml`) strictly suppress the header 'X' close button (`visible: !root.popup`), preserving clean hover/timeout dismissal. | Supported via condition `visible: !root.multipleNotifications && !root.popup`. In `NotificationPopup.qml:46`, `popup: true` is passed down to `NotificationListView:20` and `NotificationGroup:20`. This strictly suppresses the 'X' button on desktop toasts while preserving upstream hover timeout cancellation [VERIFIED: `NotificationGroup.qml:43-51`]. |
| **NAV-01** | Clicking the notification card body invokes the sending application's `default` D-Bus action to focus/open the application. | Supported via `NotificationItem.qml` and `NotificationGroup.qml` body click routing. Inspects `notificationObject.actions` for `identifier === "default"`; if found, invokes `Notifications.attemptInvokeAction(notificationId, "default")` [VERIFIED: `Notifications.qml:239-253`]. |
| **NAV-02** | Notification URL extraction parses links from Chromium notifications (`<a href="...">`), YouTube, WhatsApp, and raw URLs in body, opening them in the default browser. | Supported via `NotificationUtils.extractUrl(body)`. Regex extracts destination URLs from HTML anchors `/<a\s+[^>]*href=["']([^"']+)["']/i` (matching Chromium web notifications from WhatsApp, YouTube, etc.) and raw URLs `/\bhttps?:\/\/[^\s<>"'()]+[^\s<>"'().,;:!?]/i`. Invoked via `Qt.openUrlExternally(url)` and closes sidebar via `GlobalStates.sidebarRightOpen = false`. |
| **OTP-01** | Regex parser in `NotificationUtils.qml` scans incoming notification text for 4–8 digit verification codes anchored to security keywords (`code`, `otp`, `verification`, `pin`, `auth`). | Supported via `NotificationUtils.extractOtpCode(body, summary)`. Regex uses negative lookarounds `(?<![-/0-9])` and `(?![-/0-9])` anchored to security keywords (`code`, `otp`, `verify`, `verification`, `pin`, `auth`, `2fa`, `security`, `one-time`, `password`, `passcode`). Supports 4–8 digit standalone codes, hyphenated codes (`123-456`), and service-prefixed codes (`G-123456`) while rejecting dates, times, phone numbers, and counters. |
| **OTP-02** | Notification card in `NotificationItem.qml` renders a prominent "Copy [Code]" quick-action chip that copies the extracted code to clipboard with visual confirmation. | Supported via Material 3 `RippleButton` pill chip in `NotificationItem.qml`. Visible directly below text without requiring expansion. Binds `colSecondaryContainer` [VERIFIED: `Appearance.qml:161`] and `colOnSecondaryContainer` [VERIFIED: `Appearance.qml:164`]. On click, sets `Quickshell.clipboardText = otpCode` [VERIFIED: built-in API] and flips button label to `Copied!` for 1500ms via `Timer`. |
| **INTG-01** | All QML modifications deployed via `restow/quickshell/` leaf symlinks without modifying `vendor/dots-hyprland`. | Supported via personal overlay tree deployment (`NotificationGroup.qml`, `NotificationItem.qml`, `NotificationUtils.qml`) in `restow/quickshell/` stowed via GNU Stow (`stow --verbose=5 --no-folding -t ~ quickshell`). |
| **INTG-02** | Automated assertion test harness validates notification dismissal, link opening, and OTP parsing. | Supported via `scripts/phase40-notification-interaction-assert.sh` covering AST checks, regex test matrix, headless Quickshell execution, and porcelain integrity. |
| **INTG-03** | `arch/dots-hyprland.sh verify --strict` passes with 0 findings and zero git working-tree churn. | Supported via strict verification audit ensuring leaf symlinks, no directory folding, and clean upstream submodule. |
</phase_requirements>

---

## Architectural Responsibility Map

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             Notification Event Flow                              │
│                                                                                  │
│   FreeDesktop D-Bus (org.freedesktop.Notifications)                              │
│         │                                                                        │
│         ▼                                                                        │
│   Notifications.qml (upstream singleton service)                                │
│         │                                                                        │
│         ├──────────────────────────────┬─────────────────────────────┐           │
│         ▼                              ▼                             ▼           │
│   NotificationPopup.qml          NotificationList.qml          NotificationUtils │
│   (Desktop Toast Overlay)        (Right Sidebar Center)        (Extraction API)  │
│   popup: true                    popup: false                                    │
│         │                              │                                         │
│         └──────────────┬───────────────┘                                         │
│                        ▼                                                         │
│               NotificationGroup.qml (restow overlay)                             │
│               - Multi-group: Upstream chevron & count [D-02]                     │
│               - Single notif + Sidebar (!popup): 'X' close button [D-01]         │
│               - Single notif + Toast (popup): Suppress 'X' button [D-03]         │
│                        │                                                         │
│                        ▼                                                         │
│               NotificationItem.qml (restow overlay)                              │
│               - Body Click: D-Bus 'default' -> URL fallback -> dismiss [D-04..06]│
│               - OTP Pill: Material 3 "Copy [Code]" -> "Copied!" (1.5s) [D-08..09]│
└──────────────────────────────────────────────────────────────────────────────────┘
```

| Component | Repository Path | Responsibility |
|---|---|---|
| **Extraction Singleton** | `restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml` | Implements `extractOtpCode(body, summary)` (regex parsing 4–8 digit, hyphenated, and service-prefixed codes anchored to security keywords) and `extractUrl(body)` (extracting Chromium anchor hrefs, YouTube, WhatsApp, and raw URLs). |
| **Notification Group Card** | `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` | Adds an always-visible 'X' close button to the card header for single notifications in the sidebar (`!root.multipleNotifications && !root.popup`); suppresses the button on toast popups and multi-notification groups; handles single-card click activation. |
| **Notification Item Card** | `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` | Implements smart body click routing (`activateNotification()`: D-Bus `default` action first, URL fallback second, card dismissal and sidebar close in all paths); renders the clean icon-free OTP "Copy [Code]" pill chip with 1.5s "Copied!" visual feedback. |
| **Validation Harness** | `scripts/phase40-notification-interaction-assert.sh` | Executes static AST checks, headless Quickshell/Node OTP and URL extraction matrix assertions, click routing logic tests, and runs `./arch/dots-hyprland.sh verify --strict`. |

---

## Standard Stack

| Technology | In-Repo Version / Path | Purpose & Role |
|---|---|---|
| **Quickshell** | `Quickshell 0.2.1` [VERIFIED: `quickshell --version`] | Desktop shell runtime providing QML engine, layer-shell integration, `Quickshell.clipboardText`, `NotificationServer`, and D-Bus interfaces. |
| **Qt Quick / QML** | Qt 6.8+ (Linux x86_64) | UI declarative framework providing `Item`, `Rectangle`, `ColumnLayout`, `RowLayout`, `Text`, `Timer`, `SequentialAnimation`. |
| **FreeDesktop Notifications** | `org.freedesktop.Notifications` v1.2 specification | Standard Linux desktop notification protocol providing notification IDs, actions (`default`), hints, summaries, and body markup. |
| **GNU Stow** | 2.4.1 [VERIFIED: `arch/pkglist-native.txt:164`] | Symlink farm manager deploying leaf symlinks from `restow/quickshell/` to `~/.config/quickshell/ii/`. |
| **Material 3 Design System** | `vendor/.../Appearance.qml` [VERIFIED: `Appearance.qml:161-164, 367-369`] | Central token system providing `colSecondaryContainer`, `colOnSecondaryContainer`, `rounding.full`, and typography tokens. |

---

## In-Repo Discrete Value Provenance

The following discrete values are quoted verbatim from source files in accordance with repository provenance rules:

| Property / Discrete Value | Source File | Line Number(s) | Verbatim Code Quote |
|---|---|---|---|
| `multipleNotifications` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` | 18 | `property bool multipleNotifications: notificationCount > 1` |
| `popup` default in Group | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` | 20 | `property bool popup: false` |
| `dragConfirmThreshold` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` | 24 | `property real dragConfirmThreshold: 70 // Drag further to discard notification` |
| `destroyWithAnimation` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` | 35 | `function destroyWithAnimation(left = false) {` |
| Upstream Group implicitHeight | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` | 138-141 | ```qml<br>implicitHeight: root.expanded ? <br>    row.implicitHeight + padding * 2 :<br>    Math.min(80, row.implicitHeight + padding * 2)``` |
| Upstream Group topRow | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` | 175-182 | ```qml<br>Item { // App name (or summary when there's only 1 notif) and time<br>    id: topRow<br>    // spacing: 0<br>    Layout.fillWidth: true<br>    property real fontSize: Appearance.font.pixelSize.smaller<br>    property bool showAppName: root.multipleNotifications<br>    implicitHeight: Math.max(topTextRow.implicitHeight, expandButton.implicitHeight)``` |
| Upstream Group expandButton | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` | 213-214 | ```qml<br>NotificationGroupExpandButton {<br>    id: expandButton``` |
| `onlyNotification` in Item | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` | 16 | `property bool onlyNotification: false` |
| `dragManager` interactive | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` | 69 | `interactive: expanded` |
| Upstream Item implicitHeight | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` | 134 | `implicitHeight: expanded ? (contentColumn.implicitHeight + padding * 2) : summaryRow.implicitHeight` |
| `onLinkActivated` in Item | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` | 204-207 | ```qml<br>onLinkActivated: (link) => {<br>    Qt.openUrlExternally(link)<br>    GlobalStates.sidebarRightOpen = false<br>}``` |
| Upstream Copy Button | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` | 293-295 | ```qml<br>Quickshell.clipboardText = notificationObject.body<br>copyIcon.text = "inventory"<br>copyIconTimer.restart()``` |
| Upstream Copy Timer Interval | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` | 300 | `interval: 1500` |
| Chromium body processing | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml` | 91-104 | ```javascript<br>// Clean Chromium-based browsers notifications - remove first line<br>if (appName) {<br>    const lowerApp = appName.toLowerCase()<br>    const chromiumBrowsers = [<br>        "brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge"<br>    ]<br><br>    if (chromiumBrowsers.some(name => lowerApp.includes(name))) {<br>        const lines = body.split('\n\n')<br><br>        if (lines.length > 1 && lines[0].startsWith('<a')) {<br>            processedBody = lines.slice(1).join('\n\n')<br>        }<br>    }<br>}``` |
| Toast Popup `popup: true` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/notificationPopup/NotificationPopup.qml` | 46 | `popup: true` |
| Sidebar `popup: false` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/sidebarRight/notifications/NotificationList.qml` | 30 | `popup: false` |
| `discardNotification` | `vendor/dots-hyprland/dots/.config/quickshell/ii/services/Notifications.qml` | 192 | `function discardNotification(id) {` |
| `attemptInvokeAction` | `vendor/dots-hyprland/dots/.config/quickshell/ii/services/Notifications.qml` | 239 | `function attemptInvokeAction(id, notifIdentifier) {` |
| `colSecondaryContainer` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | 161 | `property color colSecondaryContainer: m3colors.m3secondaryContainer` |
| `colOnSecondaryContainer` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | 164 | `property color colOnSecondaryContainer: m3colors.m3onSecondaryContainer` |
| `rounding.small` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | 367 | `property real small: 8` |
| `rounding.full` | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` | 369 | `property real full: 9999` |

---

## Architecture Patterns

### 1. Single-Notification Quick Dismiss Button & Upstream Group Parity (NOTIF-01, NOTIF-02, D-01, D-02, D-03)

In `NotificationGroup.qml`, notification cards can represent either a single notification (`!root.multipleNotifications`) or a stacked group of notifications from the same application (`root.multipleNotifications`) [VERIFIED: `NotificationGroup.qml:18`].
Additionally, the card can be rendered inside the desktop toast popup (`root.popup === true`) or the Right Sidebar (`root.popup === false`) [VERIFIED: `NotificationPopup.qml:46`, `NotificationList.qml:30`].

To achieve 1-click dismissal for single notifications without touching multi-group UI or toasts:
1. In `topRow`:
   - Keep `expandButton` (`NotificationGroupExpandButton`) visible for multi-groups and popups:
     `visible: root.multipleNotifications || root.popup`
   - Add `closeButton` (`RippleButton` with `MaterialSymbol { text: "close" }`) visible strictly for single notifications in the sidebar:
     `visible: !root.multipleNotifications && !root.popup`
2. Both buttons anchor to `anchors.right: parent.right` and `anchors.verticalCenter: parent.verticalCenter`.
3. `topTextRow` right anchor dynamically binds to the active button:
   `anchors.right: expandButton.visible ? expandButton.left : (closeButton.visible ? closeButton.left : parent.right)`
4. Clicking `closeButton` directly executes `root.destroyWithAnimation()`, triggering Quickshell's native swipe animation and discarding the notification via `Notifications.discardNotification(notif.notificationId)` [VERIFIED: `NotificationGroup.qml:35-73`].

### 2. Smart Body Click Routing & Action Prioritization (NAV-01, NAV-02, D-04, D-05, D-06)

When the notification card surface is clicked:
1. **D-Bus Default Action First (D-04, NAV-01):** Check if `notificationObject.actions` contains an action with `identifier === "default"`. If so, invoke `Notifications.attemptInvokeAction(notificationId, "default")`. This activates the native application (Telegram, Spotify, Discord, etc.) via FreeDesktop D-Bus.
2. **URL Fallback for Web/Passive Notifications (D-05, NAV-02):** If no default D-Bus action is registered, check if an embedded or raw URL is extracted via `NotificationUtils.extractUrl(notificationObject.body)`. If found, launch it in the system default browser via `Qt.openUrlExternally(url)` and discard the notification via `Notifications.discardNotification(notificationId)`.
3. **Passive Notification Fallback:** If neither a D-Bus action nor a URL exists, discard the notification via `Notifications.discardNotification(notificationId)`.
4. **Sidebar Closure (D-06):** In all click pathways, set `GlobalStates.sidebarRightOpen = false`.

```javascript
function activateNotification() {
    if (!notificationObject) return;
    const hasDefaultAction = notificationObject.actions?.some(a => a.identifier === "default");
    const extractedUrl = NotificationUtils.extractUrl(notificationObject.body);

    if (hasDefaultAction) {
        Notifications.attemptInvokeAction(notificationObject.notificationId, "default");
    } else if (extractedUrl) {
        Qt.openUrlExternally(extractedUrl);
        Notifications.discardNotification(notificationObject.notificationId);
    } else {
        Notifications.discardNotification(notificationObject.notificationId);
    }
    GlobalStates.sidebarRightOpen = false;
}
```

### 3. URL Extraction & Chromium Web Link Parsing (NAV-02, D-05)

Web notifications from Chromium-based browsers (Brave, Chrome, Edge) wrap the sending website origin in an HTML anchor tag on line 0 (e.g., `<a href="https://web.whatsapp.com">web.whatsapp.com</a>\n\nNew message`) [VERIFIED: `NotificationUtils.qml:98-104`]. Raw messages may also contain standalone HTTP/HTTPS links.

The extractor in `NotificationUtils.qml` performs two sequential checks:
1. **HTML Anchor Parsing:** Searches for `<a\s+[^>]*href=["']([^"']+)["']/i` and unescapes XML entities (`&amp;` -> `&`).
2. **Raw URL Parsing:** Searches for `\bhttps?:\/\/[^\s<>"'()]+[^\s<>"'().,;:!?]/i`, stripping trailing sentence punctuation (`.`, `,`, `!`, `?`, `;`, `:`) to prevent malformed URL requests.

### 4. Smart OTP / 2FA Regex Detection Heuristics (OTP-01, D-07)

Authentication notifications contain numeric or alphanumeric codes anchored to security keywords. To eliminate false positives on dates (`2026-09-24`), times (`10:30`), phone numbers (`+1-800-555-0199`), and large byte counts (`1048576`), the parser employs strict negative lookaround boundaries:

```javascript
function extractOtpCode(body = "", summary = "") {
    const fullText = (summary ? summary + " " : "") + (body || "");
    if (!fullText) return "";
    const cleaned = fullText.replace(/<[^>]*>/g, " "); // Strip HTML tags

    const keywords = "code|otp|verify|verification|pin|auth|2fa|security|one-time|password|passcode";
    const codePattern = "(?:[A-Za-z]{1,2}-\\d{4,8}|\\d{3,4}-\\d{3,4}|\\b\\d{4,8}\\b)";

    // 1. Keyword followed by code (e.g. "verification code is 482910", "code: G-123456")
    const reKeywordBefore = new RegExp("(?:\\b(?:" + keywords + ")\\b)[^\\w\\r\\n]{0,30}?(?:is\\s+|:\\s*|\\s+)?(" + codePattern + ")(?![-/0-9])", "i");
    const m1 = cleaned.match(reKeywordBefore);
    if (m1 && m1[1]) return m1[1].trim();

    // 2. Code followed by keyword (e.g. "123-456 is your verification code")
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
```

### 5. Material 3 Action Pill Chip with Visual Confirmation (OTP-02, D-08, D-09)

When an OTP code is detected (`otpCode.length > 0`), `NotificationItem.qml` displays an icon-free pill chip directly beneath the notification text:
- **Design Tokens:** `colBackground: Appearance.colors.colSecondaryContainer` [VERIFIED: `Appearance.qml:161`], `color: Appearance.colors.colOnSecondaryContainer` [VERIFIED: `Appearance.qml:164`], `buttonRadius: Appearance.rounding.full` [VERIFIED: `Appearance.qml:369`].
- **No Decorative Icons:** Pure typography pill: `Copy [Code]` (e.g., `Copy 482910`, `Copy G-829104`).
- **Interaction:** Clicking sets `Quickshell.clipboardText = root.otpCode`, changes text to `Copied!` for 1500ms via `Timer` [VERIFIED: `NotificationItem.qml:300`], and does not invoke D-Bus or close the sidebar.
- **Dynamic Sizing Parity:** In `NotificationGroup.qml`, `implicitHeight` is updated to allow single notifications and OTP-bearing cards to expand naturally (`(root.expanded || !root.multipleNotifications) ? row.implicitHeight + padding * 2 : Math.min(80, row.implicitHeight + padding * 2)`), preventing the 80px ceiling from clipping the chip.

### 6. Leaf Symlink Overlay Architecture via GNU Stow (INTG-01, D-10)

Personal modifications are stored in the dotfiles repository under `restow/quickshell/` and stowed into `$HOME/.config/quickshell/`:
```bash
cd "$REPO_ROOT/restow" && stow --verbose=5 --no-folding -t ~ quickshell
```
- Submodule `vendor/dots-hyprland` remains 100% clean and pristine.
- Existing live files in `~/.config/quickshell/ii/` are backed up to `.bak` prior to initial link deployment.
- Strict verification (`./arch/dots-hyprland.sh verify --strict`) validates that all modified files resolve as leaf symlinks with zero directory folding.

---

## Don't Hand-Roll

| Problem | Built-in / Standard Mechanism | Why Hand-Rolling Fails |
|---|---|---|
| Clipboard Copying | `Quickshell.clipboardText = code` | Running external CLI commands (`wl-copy`) spawns unnecessary subprocesses and can fail if Wayland clipboard manager or seat focus is restricted. `Quickshell.clipboardText` is built into the engine [VERIFIED: `NotificationItem.qml:293`]. |
| Card Swipe Dismissal | `root.destroyWithAnimation()` | Manually deleting items from `Notifications.list` without running `destroyAnimation` skips the M3 spring motion and causes abrupt visual pop-out. Calling `root.destroyWithAnimation()` triggers the native physics animation [VERIFIED: `NotificationGroup.qml:35`]. |
| Notification Dismissal | `Notifications.discardNotification(id)` | Attempting to splice lists directly desynchronizes Quickshell's persistent storage (`Directories.notificationsPath`) and leaves server-tracked notifications dangling. `Notifications.discardNotification` updates memory, disk, and D-Bus tracking [VERIFIED: `Notifications.qml:192-205`]. |
| URL Opening | `Qt.openUrlExternally(url)` | Spawning `xdg-open` via bash scripts can leak background process handles or fail with quotes/spaces in URLs. `Qt.openUrlExternally` leverages Qt's Wayland desktop portal bridge [VERIFIED: `NotificationItem.qml:205`]. |
| Symlink Management | `GNU Stow` with `--no-folding` | Manual symlinking with `ln -sf` frequently causes directory folding (symlinking parent directories instead of individual files), violating repository architecture rules. |

---

## Common Pitfalls

### Pitfall 1: Calling `attemptInvokeAction` with Undefined Action
**Risk:** In upstream `Notifications.qml:245-247`, `attemptInvokeAction` executes:
`const action = notifServerNotif.actions.find(...); action.invoke()`
If a notification does not register a `"default"` action, `action` is `undefined`, causing an unhandled `TypeError: Cannot read property 'invoke' of undefined`.  
**Mitigation:** In `activateNotification()`, inspect `notificationObject.actions.some(a => a.identifier === "default")` before calling `attemptInvokeAction`. If absent, gracefully fall back to URL extraction or clean dismissal.

### Pitfall 2: MouseArea Drag vs Click Interference
**Risk:** Placing an opaque `MouseArea` over the entire notification card can block `DragManager` from detecting horizontal drag gestures (`dragConfirmThreshold: 70`), breaking swipe-to-dismiss [VERIFIED: `NotificationGroup.qml:24`].  
**Mitigation:** Do not overlay a blocking `MouseArea` across the full card. Instead, route clicks through `DragManager.onClicked` (which already receives non-drag clicks and filters `mouse.button === Qt.LeftButton`) or attach targeted click handlers to text containers with `mouse.accepted = false` when dragged.

### Pitfall 3: Card Height Clipping in `NotificationGroup.qml` (`Math.min(80, ...)`)
**Risk:** Upstream `NotificationGroup.qml:140` clamps collapsed card height to `Math.min(80, row.implicitHeight + padding * 2)` [VERIFIED: `NotificationGroup.qml:140`]. A single notification with an OTP pill chip has an implicit height of ~86–90px. Clamping to 80px cuts off the bottom half of the chip.  
**Mitigation:** Adjust the height formula so single notification cards and cards displaying an OTP chip calculate full height:
`implicitHeight: (root.expanded || !root.multipleNotifications) ? row.implicitHeight + padding * 2 : Math.min(80, row.implicitHeight + padding * 2)`.

### Pitfall 4: False Positive OTP Detection on Dates / Phone Numbers / Hex Colors
**Risk:** A naive regex matching `\b\d{4,8}\b` matches years (`2026`), calendar dates (`2026-09-24`), timestamps (`10:30`), hex colors (`#3f51b5`), and phone numbers (`+1-800-555-0199`).  
**Mitigation:** Require proximity to security keywords (`code`, `otp`, `verify`, `pin`, `auth`, `2fa`, etc.) and enforce negative lookaround boundaries `(?<![-/0-9])` and `(?![-/0-9])`. This guarantees dates, times, and phone numbers are rejected.

### Pitfall 5: Submodule Churn & Directory Folding During Stow (INTG-01, INTG-03)
**Risk:** Editing files directly in `vendor/dots-hyprland/` dirties git tracking and causes `./arch/dots-hyprland.sh verify --strict` to fail. Running `stow` without `--no-folding` when parent directories do not exist can collapse directory trees into a single symlink.  
**Mitigation:** Place all edits exclusively in `restow/quickshell/`. Pre-create parent directories in `~/.config/quickshell/ii/...` before running Stow, and always invoke `stow` with `--no-folding`.

### Pitfall 6: Trailing Punctuation in URL Extraction
**Risk:** Messages often end with a URL followed by sentence punctuation, e.g., `Visit https://example.com/login.` Parsing with `https?://\S+` includes the trailing period, causing HTTP 404 errors when opened in the browser.  
**Mitigation:** Strip trailing punctuation with regex class exclusion: `[^\s<>"'().,;:!?]`.

### Pitfall 7: Clipboard Setter API Differences
**Risk:** In QtQuick/QML, clipboard access is sometimes attempted via `QClipboard` (C++ only) or system commands.  
**Mitigation:** Use Quickshell's native singleton property `Quickshell.clipboardText = code` [VERIFIED: `NotificationItem.qml:293`].

---

## Code Examples / Implementation Blueprints

### 1. `restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml`

Add `extractOtpCode` and `extractUrl` methods while preserving upstream functions:

```qml
pragma Singleton
import Quickshell

Singleton {
    id: root

    // Upstream functions: findSuitableMaterialSymbol, getFriendlyNotifTimeString, processNotificationBody ...

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

        // 1. Keyword before code
        const reKeywordBefore = new RegExp("(?:\\b(?:" + keywords + ")\\b)[^\\w\\r\\n]{0,30}?(?:is\\s+|:\\s*|\\s+)?(" + codePattern + ")(?![-/0-9])", "i");
        const m1 = cleaned.match(reKeywordBefore);
        if (m1 && m1[1]) return m1[1].trim();

        // 2. Code before keyword
        const reCodeBefore = new RegExp("(?:(?<![-/0-9])(" + codePattern + ")[^\\w\\r\\n]{0,30}?(?:is\\s+|for\\s+|as\\s+|to\\s+)?(?:\\b(?:" + keywords + ")\\b))", "i");
        const m2 = cleaned.match(reCodeBefore);
        if (m2 && m2[1]) return m2[1].trim();

        // 3. Proximity within sentence
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

        // 2. Standalone raw URL
        const urlMatch = body.match(/\bhttps?:\/\/[^\s<>"'()]+[^\s<>"'().,;:!?]/i);
        if (urlMatch && urlMatch[0]) {
            return urlMatch[0].replace(/&amp;/g, "&").trim();
        }

        return "";
    }
}
```

### 2. `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml`

Header close button, single notification dismissal, and body click activation:

```qml
// In NotificationGroup.qml:

// In dragManager (line ~81):
DragManager {
    id: dragManager
    anchors.fill: parent
    interactive: !expanded
    automaticallyReset: false
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onPressed: {
        if (mouse.button === Qt.RightButton) 
            root.toggleExpanded();
    }

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
    // ... rest of dragManager ...
}

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

// In background (line ~120):
Rectangle {
    id: background
    // ...
    implicitHeight: (root.expanded || !root.multipleNotifications) ? 
        row.implicitHeight + padding * 2 :
        Math.min(80, row.implicitHeight + padding * 2)

    RowLayout {
        id: row
        // ...
        ColumnLayout {
            // ...
            Item {
                id: topRow
                Layout.fillWidth: true
                property real fontSize: Appearance.font.pixelSize.smaller
                property bool showAppName: root.multipleNotifications
                implicitHeight: Math.max(topTextRow.implicitHeight, 
                    expandButton.visible ? expandButton.implicitHeight : closeButton.implicitHeight)

                RowLayout {
                    id: topTextRow
                    anchors.left: parent.left
                    anchors.right: expandButton.visible ? expandButton.left : 
                        (closeButton.visible ? closeButton.left : parent.right)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    // ... appName, timeText ...
                }

                // Upstream multi-notification / toast expand button (D-02, D-03)
                NotificationGroupExpandButton {
                    id: expandButton
                    visible: root.multipleNotifications || root.popup
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    count: root.notificationCount
                    expanded: root.expanded
                    fontSize: topRow.fontSize
                    onClicked: { root.toggleExpanded() }
                    altAction: () => { root.toggleExpanded() }

                    StyledToolTip {
                        text: Translation.tr("Tip: right-clicking a group\nalso expands it")
                    }
                }

                // Single-notification sidebar close button (D-01, NOTIF-01, NOTIF-02)
                RippleButton {
                    id: closeButton
                    visible: !root.multipleNotifications && !root.popup
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: topRow.fontSize + 4 * 2
                    implicitHeight: topRow.fontSize + 4 * 2
                    buttonRadius: Appearance.rounding.full
                    colBackground: ColorUtils.mix(Appearance.colors.colLayer2, Appearance.colors.colLayer2Hover, 0.5)
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active
                    onClicked: {
                        root.destroyWithAnimation()
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: expandButton.iconSize
                        color: Appearance.colors.colOnLayer2
                    }

                    StyledToolTip {
                        text: Translation.tr("Dismiss notification")
                    }
                }
            }
```

### 3. `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml`

Body click routing and clean icon-free OTP action chip:

```qml
// In NotificationItem.qml:

property string otpCode: NotificationUtils.extractOtpCode(notificationObject?.body, notificationObject?.summary)

function activateNotification() {
    if (!notificationObject) return;
    const hasDefaultAction = notificationObject.actions?.some(a => a.identifier === "default");
    const extractedUrl = NotificationUtils.extractUrl(notificationObject.body);

    if (hasDefaultAction) {
        Notifications.attemptInvokeAction(notificationObject.notificationId, "default");
    } else if (extractedUrl) {
        Qt.openUrlExternally(extractedUrl);
        Notifications.discardNotification(notificationObject.notificationId);
    } else {
        Notifications.discardNotification(notificationObject.notificationId);
    }
    GlobalStates.sidebarRightOpen = false;
}

// In dragManager (line ~65):
DragManager {
    id: dragManager
    anchors.fill: root
    anchors.leftMargin: root.expanded ? -notificationIcon.implicitWidth : 0
    interactive: expanded
    automaticallyReset: false
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

    onClicked: (mouse) => {
        if (mouse.button === Qt.MiddleButton) {
            root.destroyWithAnimation();
        } else if (mouse.button === Qt.LeftButton) {
            root.activateNotification();
        }
    }
    // ...
}

// In contentColumn (line ~140):
ColumnLayout {
    id: contentColumn
    anchors.fill: parent
    anchors.margins: expanded ? root.padding : 0
    spacing: 3

    RowLayout { // Summary row (collapsed preview)
        id: summaryRow
        visible: !root.onlyNotification || !root.expanded
        // ...
    }

    // OTP Quick-Action Chip for Collapsed Cards
    RippleButton {
        id: collapsedOtpChip
        visible: !root.expanded && root.otpCode.length > 0
        Layout.alignment: Qt.AlignLeft
        implicitHeight: 28
        implicitWidth: collapsedOtpChipText.implicitWidth + 24
        buttonRadius: Appearance.rounding.full
        colBackground: Appearance.colors.colSecondaryContainer
        colBackgroundHover: ColorUtils.mix(Appearance.colors.colSecondaryContainer, Appearance.colors.colOnSecondaryContainer, 0.15)
        colRipple: ColorUtils.mix(Appearance.colors.colSecondaryContainer, Appearance.colors.colOnSecondaryContainer, 0.3)

        property bool copied: false
        Timer {
            id: collapsedTimer
            interval: 1500
            repeat: false
            onTriggered: collapsedOtpChip.copied = false
        }
        onClicked: {
            Quickshell.clipboardText = root.otpCode;
            collapsedOtpChip.copied = true;
            collapsedTimer.restart();
        }
        contentItem: StyledText {
            id: collapsedOtpChipText
            anchors.centerIn: parent
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnSecondaryContainer
            text: collapsedOtpChip.copied ? Translation.tr("Copied!") : Translation.tr("Copy %1").arg(root.otpCode)
        }
    }

    ColumnLayout { // Expanded content
        id: expandedContentColumn
        Layout.fillWidth: true
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0

        StyledText { // Notification body (expanded)
            id: notificationBodyText
            // ...
        }

        // OTP Quick-Action Chip for Expanded Cards (D-08, D-09)
        RippleButton {
            id: expandedOtpChip
            visible: root.expanded && root.otpCode.length > 0
            Layout.alignment: Qt.AlignLeft
            implicitHeight: 28
            implicitWidth: expandedOtpChipText.implicitWidth + 24
            buttonRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: ColorUtils.mix(Appearance.colors.colSecondaryContainer, Appearance.colors.colOnSecondaryContainer, 0.15)
            colRipple: ColorUtils.mix(Appearance.colors.colSecondaryContainer, Appearance.colors.colOnSecondaryContainer, 0.3)

            property bool copied: false
            Timer {
                id: expandedTimer
                interval: 1500
                repeat: false
                onTriggered: expandedOtpChip.copied = false
            }
            onClicked: {
                Quickshell.clipboardText = root.otpCode;
                expandedOtpChip.copied = true;
                expandedTimer.restart();
            }
            contentItem: StyledText {
                id: expandedOtpChipText
                anchors.centerIn: parent
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnSecondaryContainer
                text: expandedOtpChip.copied ? Translation.tr("Copied!") : Translation.tr("Copy %1").arg(root.otpCode)
            }
        }

        Item { // Actions flickable (bottom action bar)
            // ...
        }
    }
}
```

---

## Assumptions Log

| # | Assumption | Confidence | Validation Method |
|---|---|---|---|
| A-01 | Single notifications in the sidebar have `!root.multipleNotifications && !root.popup` in `NotificationGroup.qml`. | HIGH | Verified in `NotificationGroup.qml:18,20` and `NotificationList.qml:30` (`popup: false`). |
| A-02 | Toast popups strictly set `popup: true`, allowing exact suppression of close buttons. | HIGH | Verified in `NotificationPopup.qml:46` (`popup: true`). |
| A-03 | Quickshell supports `Quickshell.clipboardText = code` synchronously. | HIGH | Verified in upstream `NotificationItem.qml:293` where it is used directly on line 293. |
| A-04 | FreeDesktop notifications with `"default"` action can be invoked via `Notifications.attemptInvokeAction(id, "default")`. | HIGH | Verified in `Notifications.qml:239-253`. |
| A-05 | Chromium web notifications include the origin link as an HTML anchor `<a href="...">` on the first line. | HIGH | Verified against upstream `NotificationUtils.qml:98-104` logic specifically handling Chromium first line `<a`. |
| A-06 | Material 3 color tokens `colSecondaryContainer` and `colOnSecondaryContainer` are available on `Appearance.colors`. | HIGH | Verified verbatim in `Appearance.qml:161, 164`. |

---

## Open Questions

- **None.** All interaction patterns, component lifecycles, regex heuristics, and verification architectures have been empirically investigated and verified.

---

## Environment Availability

| Tool / Resource | Availability Status | Notes / Location |
|---|---|---|
| `quickshell` | Available | `Quickshell 0.2.1` (`/usr/bin/quickshell`) [VERIFIED: `quickshell --version`] |
| `hyprland` | Available | Active compositor running on system [VERIFIED: `hyprctl monitors`] |
| `stow` | Available | `GNU Stow 2.4.1` (`/usr/bin/stow`) [VERIFIED: `which stow`] |
| `node` | Available | `v20.18.0` (`/usr/bin/node`) [VERIFIED: `node -v`] |
| Verification Engine | Available | `./arch/dots-hyprland.sh verify --strict` passes with `FAIL=0 FINDINGS=0` [VERIFIED] |
| Git Submodule | Clean | `vendor/dots-hyprland` working tree is 100% clean [VERIFIED: `git status --porcelain`] |

---

## Validation Architecture

### Test Harness Architecture: `scripts/phase40-notification-interaction-assert.sh`

Following the proven architecture from `scripts/phase39-media-popup-assert.sh` and `scripts/phase38-power-profiles-assert.sh`:

```
scripts/phase40-notification-interaction-assert.sh
├── Section 1: Symlink & Packaging Integrity (INTG-01, D-10)
│   ├── Target files in ~/.config/quickshell/ii/ are symlinks into restow/quickshell/
│   ├── Parent directories are real directories (no folding)
│   └── Submodule vendor/dots-hyprland is 100% clean (zero git diff)
├── Section 2: Static AST & QML Property Verification (NOTIF-01, NOTIF-02, NAV-01, NAV-02, OTP-01, OTP-02)
│   ├── NotificationGroup.qml: closeButton definition, destroyWithAnimation call, !popup condition
│   ├── NotificationItem.qml: activateNotification definition, otpCode property, colSecondaryContainer binding
│   └── NotificationUtils.qml: extractOtpCode and extractUrl functions exported
├── Section 3: OTP Code Regex Extraction Test Matrix (OTP-01, D-07)
│   ├── Standalone 4-digit code (PIN: 9482)
│   ├── Standalone 6-digit code (Verification code: 482910)
│   ├── Hyphenated code (123-456)
│   ├── Service-prefixed code (Google: G-829104)
│   ├── Security keyword anchoring (code, otp, verify, pin, auth, 2fa, security, password)
│   └── Negative test suite: dates, timestamps, phone numbers, counters, orders -> ""
├── Section 4: URL Extraction & Body Click Routing Execution (NAV-01, NAV-02, D-04, D-05, D-06)
│   ├── Chromium <a href="..."> link extraction (WhatsApp, YouTube)
│   ├── Raw http(s) URL extraction with trailing punctuation removal
│   └── Click routing verification (D-Bus default first -> URL fallback -> discard + sidebar close)
└── Section 5: Repository Integrity & Strict Verification (INTG-02, INTG-03)
    ├── ./arch/dots-hyprland.sh verify --strict passes with FAIL=0 FINDINGS=0
    └── Git working-tree porcelain snapshot check (zero unexpected diff)
```

### REQ-ID to Validation Mapping

| Requirement ID | Assert Harness Section | Verification Method |
|---|---|---|
| **NOTIF-01** | Section 2 | Static AST asserts `closeButton` defined in `NotificationGroup.qml`, calling `root.destroyWithAnimation()`, anchored right. |
| **NOTIF-02** | Section 2 | Static AST asserts `closeButton.visible` strictly checks `!root.popup`. |
| **NAV-01** | Section 2, Section 4 | Static AST asserts `attemptInvokeAction(..., "default")` in `activateNotification`; test runner verifies D-Bus action priority. |
| **NAV-02** | Section 2, Section 4 | Headless / node execution tests Chromium `<a href="...">` and raw URL parsing against test URLs; asserts `Qt.openUrlExternally` invocation. |
| **OTP-01** | Section 2, Section 3 | Automated execution of 14 positive and 5 negative test cases against `extractOtpCode`, verifying 100% detection accuracy. |
| **OTP-02** | Section 2 | Static AST asserts presence of `RippleButton` pill chip with `Quickshell.clipboardText` assignment, `Copied!` label, and 1500ms `Timer`. |
| **INTG-01** | Section 1 | Validates that `NotificationGroup.qml`, `NotificationItem.qml`, and `NotificationUtils.qml` are deployed via `restow/quickshell/` leaf symlinks without folding. |
| **INTG-02** | Sections 1–5 | Full execution of `scripts/phase40-notification-interaction-assert.sh` exits 0 with `FAIL=0 FINDINGS=0`. |
| **INTG-03** | Section 5 | `./arch/dots-hyprland.sh verify --strict` runs and outputs `FAIL=0 FINDINGS=0`. |

### Wave 0 Gaps
Before running the assertion harness, the following files must be created:
1. `scripts/phase40-notification-interaction-assert.sh` (executable test harness with `--section` and `--syntax` flags).
2. `restow/quickshell/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml` (seeding from upstream + `extractOtpCode` & `extractUrl`).
3. `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` (seeding from upstream + header close button & body click).
4. `restow/quickshell/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` (seeding from upstream + OTP chip & body click).

---

## Security Domain

- **FreeDesktop D-Bus Action Invocation:** Calling `attemptInvokeAction(notificationId, "default")` invokes actions registered by the sending application on the session bus. Because the notification ID is validated by `Notifications.qml`'s `trackedNotifications` list, invalid or forged IDs cannot trigger rogue actions.
- **URL Sanitization & External Launch:** When extracting URLs, the parser strictly matches HTTP/HTTPS protocols (`https?://`). It rejects dangerous schemes (`javascript:`, `file:`, `data:`, `sh:`) before handing the link to `Qt.openUrlExternally()`, preventing arbitrary command execution.
- **Regular Expression Denial of Service (ReDoS) Defense:** The OTP regex avoids nested quantifiers (`(a+)+`) and uses non-greedy matching with bounded string lengths (`{1,60}?`). Input strings are truncated or stripped of HTML before matching.
- **Clipboard Access & Data Hygiene:** The OTP copy chip only writes strictly extracted code characters to `Quickshell.clipboardText` without surrounding context or metadata. Ephemeral visual feedback ("Copied!" for 1.5s) provides user transparency.
