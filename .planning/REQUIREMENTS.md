# Requirements: Quickshell Desktop Shell

**Milestone:** v0.8 Notification Experience & Shell Interaction Polish  
**Defined:** 2026-09-22  
**Core Value:** Desktop capability via upstream dots-hyprland + personal overlays with unified system-wide Material You theming across GTK, Qt/KDE, Hyprland, Quickshell ii, and terminal/launcher tools with zero git churn.

## v0.8 Requirements

Requirements for milestone release. Each maps to roadmap phases.

### Media Popup Anchoring

- [x] **MEDIA-01**: `MediaControls.qml` popup dynamically anchors directly beneath the top status bar's `Media` pill across active monitors.
- [x] **MEDIA-02**: `MediaControls.qml` popup enforces horizontal boundary clamping (`Math.min` / `Math.max`) to prevent off-screen clipping.

### Power Profiles Management

- [x] **POWER-01**: `power-profiles-daemon` package installed and `power-profiles-daemon.service` enabled on Arch Linux.
- [x] **POWER-02**: Quickshell power profile quick-toggle (`PowerProfilesToggle.qml`) cycles through profiles (Power Saver, Balanced, Performance) with matching icons and live state feedback.
- [x] **POWER-03**: Package manifests (`arch/pkglist-native.txt`, `dots-hyprland.sh`, `bootstrap.sh`) updated to guarantee `power-profiles-daemon` on fresh machine installs.

### Notification Header & Dismissal

- [x] **NOTIF-01**: Notification card header in Right Sidebar (`NotificationGroup.qml`) displays an always-visible 'X' close button for immediate 1-click dismissal without dropdown expansion.
- [x] **NOTIF-02**: Toast notification popups (`NotificationPopup.qml`) strictly suppress the header 'X' close button (`visible: !root.popup`), preserving clean hover/timeout dismissal.

### Notification Body Click & URL Navigation

- [x] **NAV-01**: Clicking the notification card body invokes the sending application's `default` D-Bus action to focus/open the application.
- [x] **NAV-02**: Notification URL extraction parses links from Chromium notifications (`<a href="...">`), YouTube, WhatsApp, and raw URLs in body, opening them in the default browser.

### Smart OTP / 2FA Detection

- [x] **OTP-01**: Regex parser in `NotificationUtils.qml` scans incoming notification text for 4–8 digit verification codes anchored to security keywords (`code`, `otp`, `verification`, `pin`, `auth`).
- [x] **OTP-02**: Notification card in `NotificationItem.qml` renders a prominent "Copy [Code]" quick-action chip that copies the extracted code to clipboard with visual confirmation.

### Clock Pill Padding & Ergonomics

- [x] **CLOCK-01**: Top status bar clock/date pill provides comfortable horizontal padding matching adjacent pills while retaining custom second precision and full date string formatting.

### Unified Volume Ceiling

- [x] **VOL-01**: Single source of truth defines the desktop-wide volume ceiling (150% / 1.5) consumed consistently across Hyprland keybinds and Quickshell services without hardcoded magic numbers.
- [x] **VOL-02**: Right sidebar volume slider and mouse scroll volume increments allow reaching the 150% upper ceiling defined by the single source of truth.

### Integration & Repository Integrity

- [x] **INTG-01**: All QML modifications deployed via `restow/quickshell/` leaf symlinks without modifying `vendor/dots-hyprland`.
- [x] **INTG-02**: Automated assertion test harness validates media popup positioning, power profile cycling, notification dismissal, link opening, and OTP parsing.
- [x] **INTG-03**: `arch/dots-hyprland.sh verify --strict` passes with 0 findings and zero git working-tree churn.

## Future Requirements

### Waybar Custom Module Ports

- **CUST-01**: Port self-hosted ping monitor widget (`127.0.0.1:8765/api/status`) into Quickshell.
- **CUST-02**: Port weather widget with detailed multi-day forecast popup.
- **CUST-03**: Port earthquake real-time alert widget.

### Desktop Session & IPC Polish

- **POLISH-02**: Framework autostart refinement and bar toggle IPC keybindings under the upstream model.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Close button on screen toast popups | User explicitly requested toast popups remain clean and dismiss via hover/timeout. |
| Direct edits to `vendor/dots-hyprland` | Submodule must remain pristine to preserve reproducible upstream updates and pass strict verification. |
| Unanchored number matching as OTP | Matches years, timestamps, and package counts; strict keyword proximity is required. |
| Non-Arch power profile daemons | Arch Linux is the primary supported platform; `power-profiles-daemon` is standard. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| MEDIA-01 | Phase 39 | Complete |
| MEDIA-02 | Phase 39 | Complete |
| POWER-01 | Phase 38 | Complete |
| POWER-02 | Phase 38 | Complete |
| POWER-03 | Phase 38 | Complete |
| NOTIF-01 | Phase 40 | Complete |
| NOTIF-02 | Phase 40 | Complete |
| NAV-01 | Phase 40 | Complete |
| NAV-02 | Phase 40 | Complete |
| OTP-01 | Phase 40 | Complete |
| OTP-02 | Phase 40 | Complete |
| CLOCK-01 | Phase 40.1 | Complete |
| VOL-01 | Phase 40.1 | Complete |
| VOL-02 | Phase 40.1 | Complete |
| INTG-01 | Phase 41 | Complete |
| INTG-02 | Phase 41 | Complete |
| INTG-03 | Phase 41 | Complete |
