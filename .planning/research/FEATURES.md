# Feature Research

**Domain:** Linux Desktop Shell (Quickshell / Qt 6 QML / Hyprland / D-Bus / Arch Linux)
**Researched:** 2026-09-22
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete or broken.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Dynamic Media Popup Placement | Clicking a status bar icon should open its popup directly beneath it, not off in another section of the screen. | MEDIUM | Compute dynamic `x` anchor from the Media pill's global coordinates on the active monitor, clamping to screen edges. |
| Working Power Profiles Toggle | A quick-toggle button in the control panel must cycle through power profiles (Power Saver ↔ Balanced ↔ Performance) when clicked. | LOW | Install and enable `power-profiles-daemon.service` on Arch Linux; verify Quickshell D-Bus listener updates UI state. |
| One-Click Notification Dismissal | In a notification drawer/center (Right Sidebar), dismissing a notification should be a direct 1-click action without expanding a sub-menu. | LOW | Add an always-visible 'X' button on the notification card header beside the expand chevron, strictly in `sidebarRight`. |
| Notification Body Click Navigation | Clicking a notification should either open the relevant URL in the default browser or trigger the sending app's `default` action to focus the window. | MEDIUM | Connect `MouseArea.onClicked` on the card body to `Notifications.attemptInvokeAction(id, "default")` and URL launch fallback. |
| Embedded URL Extraction | Notifications from YouTube, WhatsApp Web, or Chromium contain links that users expect to open immediately upon clicking. | MEDIUM | Extract URLs from Chromium's `<a href="...">` headers or body text and pass them to `Qt.openUrlExternally()`. |

### Differentiators (Competitive Advantage)

Features that set the desktop experience apart and deliver exceptional usability.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Smart OTP / 2FA Code Auto-Extraction | Eliminates manual text selection or copying entire multi-line SMS/email notifications just to paste a 6-digit verification code. | MEDIUM | Regex parser scans notification text for patterns like `\b\d{4,8}\b` associated with keywords ("code", "otp", "verification", "pin", "login"). |
| Dedicated "Copy [Code]" Quick Action Chip | A visually distinct, styled chip displaying the extracted code with a one-click clipboard copy and toast confirmation. | LOW | Material 3 tonal button rendering the code with a clipboard icon and 1.5s visual feedback on copy. |
| Dual-Monitor Adaptive Clamping | Ensures the media popup stays strictly within monitor bounds regardless of whether the bar is on an ultrawide or standard display. | LOW | Clamp popup `x` between `padding` and `screen.width - popup.width - padding`. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Close Button on Screen Toast Popups | Consistency across popup and sidebar. | Clutters small temporary toast cards, causes accidental clicks when aiming to hover-dismiss or interact. | Keep toast popups clean; preserve mouse-hover timeout cancellation and natural expiration as requested by the user. |
| Modifying `vendor/dots-hyprland` directly | Quickest way to edit QML. | Modifies git submodule working tree, breaks `git diff` reproducibility, fails `arch/dots-hyprland.sh verify --strict`. | Deploy all changes as leaf symlinks via `restow/quickshell/`. |
| Aggressive OTP regex matching any number | Catch every possible verification code. | High false-positive rate (matches years like 2026, timestamps, phone numbers, quantities). | Require keyword context or strict boundary heuristics to ensure only genuine verification codes trigger the chip. |

## Feature Dependencies

```
[power-profiles-daemon] ──enables──> [PowerProfilesToggle Quick Action]

[Media pill coordinates in BarContent] ──positions──> [MediaControls Popup]

[NotificationUtils URL/OTP parser]
    ├──powers──> [Smart Body Click / Link Dispatch]
    └──powers──> [OTP "Copy Code" Action Chip]

[NotificationGroup Header X Button] ──strictly scoped to──> [Right Sidebar]
```

### Dependency Notes

- **`power-profiles-daemon` enables `PowerProfilesToggle`:** Without the system daemon running on `/run/dbus/system_bus_socket`, the D-Bus interface does not exist and calls fail silently.
- **Media pill coordinates position `MediaControls`:** `MediaControls.qml` runs as a top-level `PanelWindow`. It must read the `Media` pill's screen-relative position or monitor layout to position itself accurately.
- **`NotificationUtils` powers both Link Opening and OTP Extraction:** Centralizing text parsing in `NotificationUtils.qml` ensures consistent sanitization and extraction logic.
