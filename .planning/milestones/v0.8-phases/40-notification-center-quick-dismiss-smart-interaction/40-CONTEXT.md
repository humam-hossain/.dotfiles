# Phase 40: Notification Center Quick-Dismiss & Smart Interaction - Context

**Gathered:** 2026-09-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Enhance notification ergonomics across the Right Sidebar and Desktop Toasts in Quickshell (`restow/quickshell/`):
- Provide an immediate 1-click 'X' close button on sidebar notification cards exclusively for single notifications, bypassing unnecessary dropdown expansion.
- Strictly preserve 100% upstream default UI for grouped notifications (expand chevron, notification count) without adding a group close button.
- Strictly preserve 100% upstream default behavior for toast notifications (`NotificationPopup.qml`), leaving their hover-to-dismiss and timeout lifecycle untouched.
- Implement smart body click navigation with D-Bus `default` action prioritization to focus desktop apps (Telegram, Spotify, Discord, etc.), falling back to browser URL launching (`xdg-open` via `Qt.openUrlExternally`) for web links (Chromium, YouTube, WhatsApp, raw URLs), and closing the sidebar on invocation.
- Implement smart OTP / 2FA verification code detection via regex in `NotificationUtils.qml` supporting 4–8 digits, hyphenated codes, and service-prefixed codes anchored to security keywords.
- Render a clean, icon-free "Copy [Code]" action pill chip directly beneath notification text in `NotificationItem.qml`, copying the code to the clipboard with a 1.5s "Copied!" visual confirmation.
- Deploy all modifications cleanly via `restow/quickshell/` leaf symlinks without modifying `vendor/dots-hyprland`.

**In Scope:**
- `NotificationGroup.qml`: Add 'X' close button to card header visible only for single notifications in the sidebar (`!root.multipleNotifications && !root.popup`).
- `NotificationItem.qml`: Add smart body click area routing D-Bus `default` action / URL fallback, and icon-free OTP "Copy [Code]" pill chip beneath message text.
- `NotificationUtils.qml`: Implement OTP code extraction regex function and URL parser.
- Deployment via `restow/quickshell/` maintaining zero upstream churn.

**Out of Scope:**
- Modifying group notification headers (remains 100% upstream default).
- Altering toast popup hover/timeout behavior.
- Adding decorative icons (key icon, etc.) to the OTP chip.
- Modifying `vendor/dots-hyprland` directly.

</domain>

<decisions>
## Implementation Decisions

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

### the agent's Discretion
- Exact regex pattern boundaries and negative lookaheads (preventing false matches on dates, phone numbers, or hex colors).
- Material 3 container color styling and padding for the OTP action chip.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §Phase 40 — Goal, success criteria, and requirements.
- `.planning/REQUIREMENTS.md` §Notification Header & Dismissal, Notification Body Click & URL Navigation, Smart OTP / 2FA Detection (`NOTIF-01`, `NOTIF-02`, `NAV-01`, `NAV-02`, `OTP-01`, `OTP-02`).

### Upstream Notification Components
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationGroup.qml` — Upstream notification group card and header layout.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml` — Upstream notification item, body text, and action buttons.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/functions/NotificationUtils.qml` — Upstream notification body processing and helper functions.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/notificationPopup/NotificationPopup.qml` — Upstream toast popup window.
- `vendor/dots-hyprland/dots/.config/quickshell/ii/services/Notifications.qml` — Upstream notification service (`attemptInvokeAction`, `discardNotification`, `cancelTimeout`).

### Personal Overlays (Restow)
- `restow/quickshell/.config/quickshell/ii/` — Target directory for personal Quickshell leaf overlays.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Appearance.colors` and `Appearance.m3colors`: Material 3 colors (`colSecondaryContainer`, `colOnSecondaryContainer`, `colLayer2`, `colLayer3`).
- `Appearance.font.pixelSize`: Typography tokens (`small`, `smaller`, `normal`).
- `Appearance.rounding.small`: Standard radius for chips and buttons.
- `Quickshell.clipboardText`: Built-in Quickshell clipboard setter.
- `Notifications.attemptInvokeAction(id, identifier)`: Invokes registered D-Bus notification action.
- `Notifications.discardNotification(id)`: Removes notification from storage and list.

### Established Patterns
- **Three-Tree Overlay Model:** Personal QML overrides live in `restow/quickshell/` and are stowed as leaf symlinks into `~/.config/quickshell/ii/` without modifying `vendor/dots-hyprland`.
- **GlobalStates Bridge:** `GlobalStates.sidebarRightOpen` controls the right sidebar visibility.

### Integration Points
- `NotificationGroup.qml`: Header `topRow` hosts the single-notification 'X' button alongside existing text.
- `NotificationItem.qml`: `contentColumn` hosts the body click area and the OTP copy chip under `summaryRow` / `expandedContentColumn`.
- `NotificationUtils.qml`: Singleton provides `extractOtpCode(body, summary)` and `extractUrl(body)`.

</code_context>

<specifics>
## Specific Ideas

- **User Directives:**
  - Single notification close: *"when a single notification comes I have to like tick for each notification that is annoying for multi notification group card so I don't wanna do that... I want it for only single notification not for the group"*
  - Multi-notification groups: Keep 100% default upstream UI (standard expand chevron, no extra group X).
  - Toasts: Keep 100% default upstream toast behavior (hover-to-dismiss and timeout lifecycle untouched).
  - Body click priority: *"i would like d-bus first"* — D-Bus default action first to focus native apps, URL fallback for browser/passive notifications via `xdg-open`.
  - OTP Chip: *"in 3. don't use icon of key, no need any icon"* — Clean text-only pill chip: `Copy [Code]` and `Copied!`.

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed strictly within phase scope.

</deferred>

---

*Phase: 40-Notification Center Quick-Dismiss & Smart Interaction*
*Context gathered: 2026-09-24*
