# Project Research Summary

**Project:** Quickshell Desktop Shell (Milestone v0.8)
**Domain:** Linux Desktop Shell (Quickshell / Qt 6 QML / Hyprland / D-Bus / Arch Linux)
**Researched:** 2026-09-22
**Confidence:** HIGH

## Executive Summary

Milestone v0.8 focuses on ergonomic interactions and desktop polish across three primary surfaces: the status bar media popup, system power management toggling, and the notification subsystem. Investigation of the current implementation revealed clear root causes for each issue: the media popup currently relies on a legacy hardcoded horizontal offset from stock dots-hyprland that does not track the moved Right-Zone media pill; the power profile quick-toggle silently fails because the system-level `power-profiles-daemon` D-Bus service is missing on the host; and the notification subsystem lacks direct sidebar dismissal, clickable link routing, and OTP extraction.

The recommended engineering approach leverages Quickshell's modular architecture via personal overlays deployed under `restow/quickshell/`, ensuring that the upstream `vendor/dots-hyprland` submodule remains completely untouched and pristine. System-level requirements will be satisfied by installing `power-profiles-daemon`, activating its systemd unit, and persisting it into `arch/pkglist-native.txt` and `bootstrap.sh`. The notification pipeline will be refined by augmenting `NotificationGroup.qml` with an always-visible 'X' button strictly in the sidebar (`!popup`), enabling smart body clicks and link delegation in `NotificationItem.qml`, and adding microsecond-latency regex OTP/link parsing in `NotificationUtils.qml`.

Key operational risks—such as media popup off-screen clipping, event propagation stealing between nested MouseAreas, false-positive OTP matching, and accidental close button leakage onto on-screen toast popups—are addressed by deterministic coordinate clamping, clear click-zone boundaries, keyword-anchored regex patterns, and strict `!popup` visibility guards.

## Key Findings

### Recommended Stack

All changes are implemented natively within the existing desktop stack without introducing heavy dependencies or background daemons.

**Core technologies:**
- `power-profiles-daemon` (0.30+): Standard Freedesktop D-Bus daemon providing `net.hadess.PowerProfiles` for CPU performance profile switching across Power Saver, Balanced, and Performance.
- `Quickshell` / `QtQuick 6.11`: Wayland layer-shell UI toolkit hosting `PanelWindow` popups, `BarGroup` pills, and reactive state bindings.
- `Quickshell.Services.Notifications`: D-Bus notification server tracking and action invocation (`attemptInvokeAction()`, `discardNotification()`).
- `Qt.openUrlExternally` / `xdg-open`: High-reliability URL dispatching to the system default browser.
- JavaScript RegExp (Qt QML engine): In-process pattern matching for OTP verification codes and Chromium notification link extraction.

### Expected Features

**Must have (table stakes):**
- **Dynamic Media Popup Anchoring**: `MediaControls.qml` dynamically anchors beneath the top bar's `Media` pill across active monitors with safe screen boundary clamping.
- **Power Profiles Daemon Integration**: `power-profiles-daemon` installed, enabled, and functioning with the Quickshell `PowerProfilesToggle.qml` UI component.
- **Sidebar Quick-Close Button**: Direct, always-visible 'X' close button on notification cards strictly in the Right Sidebar (no dropdown required).
- **Smart Notification Body Click**: Clicking notification body invokes the app's `default` action or opens extracted URLs in the default browser.

**Should have (differentiators):**
- **Smart OTP / 2FA Code Extraction**: Automated detection of 4–8 digit verification codes with a prominent "Copy [123456]" action chip on the notification card.
- **Bootstrap & Package Reproducibility**: `power-profiles-daemon` registered in `arch/pkglist-native.txt` and `bootstrap.sh` to ensure fresh machine portability.

**Anti-features (what to avoid):**
- Adding close buttons to screen toast popups (`NotificationPopup.qml`) — user explicitly wants toasts to remain clean and dismiss via hover/timeout.
- Modifying `vendor/dots-hyprland` directly — all QML overrides must reside under `restow/quickshell/`.

### Architecture Approach

The architecture maintains strict separation of concerns across four modules:
1. `MediaControls.qml`: Exposes and binds dynamic coordinates to the active monitor's `Media` pill position, clamping horizontal bounds between `screenMargin` and `screen.width - popup.width - screenMargin`.
2. `power-profiles-daemon`: Systemd system service communicating over system D-Bus, transparently consumed by Quickshell's existing `PowerProfiles` model.
3. `NotificationGroup.qml`: Adds `RippleButton` with `"close"` glyph to `topRow` with `visible: !root.popup`.
4. `NotificationItem.qml` & `NotificationUtils.qml`: Implements interactive body click handler, regex OTP detection (`extractOTPCode`), and dedicated copy chip.

### Critical Pitfalls

1. **Media Popup Edge Overflow**: Unclamped anchoring causes the popup to bleed off the right screen boundary on narrow or scaled displays. Avoid by using `Math.min(Math.max(...))` clamping.
2. **Event Stealing between MouseAreas**: Adding card click handlers could break `DragManager` swipe-to-dismiss. Avoid by assigning explicit interactive bounds and ensuring child buttons (`X`, `Copy OTP`) stop event bubbling.
3. **False Positive OTP Codes**: Unanchored `\d{4,8}` matches years (2026) or timestamps. Avoid by requiring context keywords (`code`, `otp`, `verification`, `pin`).
4. **Toast Popup Close Button Clutter**: Forgetting to check `!root.popup` renders 'X' on toasts. Avoid by strictly conditioning on `!root.popup`.

## Implications for Roadmap

Suggested phase structure for Milestone v0.8:

### Phase 38: Power Profiles Daemon System Integration
**Rationale:** Independent system service requirement with zero UI risk. Resolves the non-functional toggle immediately.
**Delivers:** `power-profiles-daemon` package installed, systemd unit enabled, added to `arch/pkglist-native.txt` and `bootstrap.sh`, verified via `powerprofilesctl` and Quickshell toggle.
**Addresses:** `POWER-01`, `POWER-02`, `POWER-03`.
**Avoids:** Inactive service across reboots and bootstrap drift.

### Phase 39: Dynamic Media Popup Anchoring
**Rationale:** Isolates the top status bar and layer-shell coordinate calculation without touching the notification subsystem.
**Delivers:** `restow/quickshell/.../modules/ii/mediaControls/MediaControls.qml` with dynamic anchoring relative to `Media.qml` in `BarContent.qml`, complete with dual-monitor screen boundary clamping.
**Addresses:** `MEDIA-01`.
**Avoids:** Coordinate overflow and off-screen rendering.

### Phase 40: Notification Center Quick-Dismiss & Smart Interaction
**Rationale:** Builds the UI and logic enhancements for notifications in `restow/quickshell/`.
**Delivers:** Right sidebar 'X' close button on notification cards (`NotificationGroup.qml`), smart body click with app `default` action trigger and link opening (`NotificationItem.qml`), and regex OTP/link extraction helper functions in `NotificationUtils.qml` with dedicated "Copy [Code]" action chips.
**Addresses:** `NOTIF-01`, `NOTIF-02`, `NOTIF-03`, `NOTIF-04`, `NOTIF-05`.
**Avoids:** Toast popup clutter, event propagation stealing, and false-positive OTP extraction.

### Phase 41: End-to-End Verification & Repository Integrity
**Rationale:** Comprehensive validation across all new features, regression sweep, and strict repository verification.
**Delivers:** Multi-section automated test harness validating power profile toggling, media popup positioning, notification dismissal, link opening, and OTP copying; verification that `arch/dots-hyprland.sh verify --strict` exits 0 with zero git churn.
**Addresses:** `INTG-01`, `INTG-02`.

## Sources

- Quickshell QML source: `~/.config/quickshell/ii/`
- dots-hyprland submodule: `vendor/dots-hyprland/`
- Freedesktop Notifications Specification: `org.freedesktop.Notifications`
- Freedesktop Power Profiles Specification: `net.hadess.PowerProfiles`
