# Pitfalls Research

**Domain:** Linux Desktop Shell (Quickshell / Qt 6 QML / Hyprland / D-Bus / Arch Linux)
**Researched:** 2026-09-22
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Coordinate Overflow in Dynamic Media Popup Anchoring

**What goes wrong:**
When calculating the popup's X position directly from the `Media` pill, the popup extends beyond the right screen edge on standard displays or narrow windows, causing part of the media player (album art, sliders, or buttons) to be clipped off-screen or rendered into invisible layer-shell space.

**Why it happens:**
The top bar's `Media` pill is located in the Right Zone. If the popup's width (`Appearance.sizes.mediaControlsWidth`, typically 360–400px) is anchored to the pill's left or center without edge clamping, `pill.x + popup.width` can exceed `screen.width - margins`.

**How to avoid:**
Implement strict boundary clamping:
```qml
readonly property real desiredLeft: Math.min(
    Math.max(screenMargin, calculatedPillLeft),
    panelWindow.screen.width - root.widgetWidth - screenMargin
)
```
Always clamp between the minimum screen margin and `screen.width - widgetWidth - screenMargin`.

**Warning signs:**
Popup buttons unreachable, horizontal scroll appearing, or media player opening half off-screen on the right edge.

**Phase to address:**
Phase addressing Media Popup Anchoring.

---

### Pitfall 2: Mouse Event Bleed and DragManager Conflict on Notification Cards

**What goes wrong:**
Adding a clickable MouseArea on `NotificationItem.qml` or `NotificationGroup.qml` interferes with `DragManager` swipe-to-dismiss gestures or prevents the child "Close" and "Copy" buttons from receiving click events. Alternatively, clicking the 'X' button or OTP chip accidentally triggers the body click (opening a browser or focusing an app).

**Why it happens:**
In Qt Quick / QML, nested `MouseArea` items steal or propagate events unless `mouse.accepted = true` or `stopPropagation()` is called, and `DragManager` relies on capturing mouse press/drag thresholds.

**How to avoid:**
1. Separate distinct click zones: The header 'X' button must reside in its own `RippleButton` on `topRow` with `acceptedButtons: Qt.LeftButton`, explicitly consuming the click.
2. The OTP chip must be a distinct interactive button that consumes clicks independently.
3. The body click target must only handle clicks that do not land on action chips, links, or dismiss buttons, and must not break `DragManager`'s swipe threshold check (`dragDistance > 70`).

**Warning signs:**
Clicking 'X' dismisses the notification but also opens a browser window, or swiping to dismiss becomes sticky and unresponsive.

**Phase to address:**
Phase addressing Notification Item & Group interactions.

---

### Pitfall 3: False Positive OTP Code Extraction

**What goes wrong:**
The regex parser mistakenly treats years (e.g. `2026`), timestamps (e.g. `143000`), port numbers (e.g. `8080`), or generic numerical values as verification codes, cluttering notifications with useless "Copy 2026" chips.

**Why it happens:**
Using an overly broad pattern like `/\b\d{4,8}\b/` matches any standalone 4–8 digit number in the text.

**How to avoid:**
Use contextual keyword anchoring in `NotificationUtils.qml`:
1. Search for verification-related keywords in the summary or body (`otp`, `code`, `verification`, `verify`, `pin`, `password`, `auth`, `2fa`, `login`).
2. If keywords exist, extract the 4–8 digit number closest to the keyword (e.g. `/(?:code|otp|verify|pin)[:\s]+([0-9]{4,8})\b/i` or `/\b([0-9]{4,8})\b/`).
3. Exclude years (e.g. numbers starting with `19xx` or `20xx` when 4 digits unless explicitly preceded by "code").

**Warning signs:**
System update notifications ("Updated 2048 packages") or calendar alerts ("Meeting at 1500") showing an OTP copy button.

**Phase to address:**
Phase addressing Notification Link & OTP extraction.

---

### Pitfall 4: `power-profiles-daemon` Service Inactivity Across Bootstraps

**What goes wrong:**
Installing the `power-profiles-daemon` package via pacman enables the binaries, but if `power-profiles-daemon.service` is not explicitly enabled and started via systemd, the D-Bus interface remains absent after reboot or on a freshly bootstrapped machine, causing the quick-toggle button to silently break again.

**Why it happens:**
Pacman installs package files but does not enable systemd services by default on Arch Linux (per Arch packaging policy).

**How to avoid:**
1. In the implementation phase, run `sudo systemctl enable --now power-profiles-daemon.service`.
2. Add `power-profiles-daemon` to `arch/pkglist-native.txt`.
3. Add an idempotent service activation check in `bootstrap.sh` and `arch/dots-hyprland.sh`.
4. Verify with `powerprofilesctl get` in the automated test harness.

**Warning signs:**
`PowerProfiles.profile` property remains undefined or null in QML, and `powerprofilesctl` reports "Failed to connect to bus".

**Phase to address:**
Phase addressing Power Profiles integration.

---

### Pitfall 5: Inadvertent Close Button Injection into Screen Toast Popups

**What goes wrong:**
The header close button appears on transient on-screen toast popups (`NotificationPopup.qml`), violating the user's explicit preference that toasts remain clean and dismiss via natural hover/timeout.

**Why it happens:**
`NotificationGroup.qml` is shared by both `NotificationPopup.qml` (toasts) and `SidebarRight.qml` (sidebar notification center) via `NotificationListView.qml`.

**How to avoid:**
`NotificationGroup.qml` already receives `property bool popup`. Strictly guard the close button visibility with `visible: !root.popup`. This guarantees the 'X' button only renders in the sidebar notification drawer.

**Warning signs:**
'X' icon appearing on transient toast notifications on the top-right corner of the desktop.

**Phase to address:**
Phase addressing Notification Group header UI.
