---
status: resolved
updated: "2026-09-20T10:27:00+06:00"
---

# Debug Session: Bar Controls, Media Auto-Collapse & Updates Terminal

**Gap:** Bar components behave cleanly without redundant controls, media remains stable on pause per dots-hyprland defaults, and updates button launches system update in configured default terminal
**Severity:** Major
**Test:** 1 (Phase 32 Automated Deliverables Confirmation)

## Symptoms
1. **Triple mic situation:** Three microphone icons appear simultaneously on the bar (Utility button toggle, Privacy active capture revealer, and Audio source mute indicator).
2. **Media player auto-collapses on pause:** Pausing a video/audio stream immediately collapses the Media pill from the top bar instead of remaining visible with playback controls as in default dots-hyprland.
3. **Updates button click does nothing:** Clicking the 58 updates pill in the top bar produces no visible action; it does not launch the default terminal or execute package updates.

## Root Cause Analysis

### 1. Redundant Microphone Toggle
- **Files:** `capture/ii/.config/illogical-impulse/config.json`, `~/.config/illogical-impulse/config.json`
- **Finding:** `bar.utilButtons.showMicToggle` is set to `true`. This causes `UtilButtons.qml` to render an always-visible mic toggle button in the center-right group, while `BarContent.qml` also renders `Privacy.micActive` (amber in-use indicator) and `Audio.source.muted` (mic_off status indicator).
- **Diagnosis:** During Phase 32 discussion, Option A recommended disabling `showMicToggle: false` to prevent the triple-mic redundancy. User has confirmed Option A is required.

### 2. Media Player Auto-Collapse on Pause
- **Files:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`, `scripts/phase32-component-formatting-assert.sh`
- **Finding:** Line 101 of `BarContent.qml` specifies `visible: (root.useShortenedForm < 2) && (MprisController.activePlayer?.isPlaying ?? false)`. Whenever media is paused (`isPlaying` becomes false), the pill collapses.
- **Diagnosis:** Upstream dots-hyprland specifies `visible: root.useShortenedForm < 2` without checking `isPlaying`. The user explicitly requested keeping upstream default behavior where the media pill remains visible when paused.

### 3. Updates Button Click Failure & Hardcoded Terminal
- **Files:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml`, `restow/quickshell/.config/quickshell/ii/scripts/system-update.sh` (to create), `capture/ii/.config/illogical-impulse/config.json`
- **Finding:** `UpdatesButton.qml` was implemented as an `Item` containing a child `MouseArea`. Inside `BarGroup`'s `GridLayout`, the `Item` did not get a layout-assigned width, causing the child `MouseArea` to have 0 width and clicks to fail or bubble to `barRightSideMouseArea`. Furthermore, `UpdatesButton.qml` hardcoded `kitty` instead of reading the user's default terminal from dots-hyprland (`Config.options.apps.terminal` / `config.json` `apps.terminal`).
- **Diagnosis:** `UpdatesButton` needs to be a root `MouseArea` (like `WeatherBar.qml`) so hit testing has explicit geometric bounds on the bar, and it should delegate to a robust update launcher script (`system-update.sh`) that dynamically resolves the configured dots-hyprland terminal with appropriate hold flags.

## Suggested Fix Direction
1. In `capture/ii/.config/illogical-impulse/config.json` and `~/.config/illogical-impulse/config.json`, set `"showMicToggle": false`.
2. In `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`, change Media visibility back to `visible: root.useShortenedForm < 2`.
3. In `scripts/phase32-component-formatting-assert.sh`, adjust Section 4 assertion for Media to reflect upstream default visibility.
4. Author `restow/quickshell/.config/quickshell/ii/scripts/system-update.sh` (executable) to resolve terminal from argument / `config.json` / `$TERMINAL` and launch `yay -Syu`.
5. In `restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml`, convert root to `MouseArea` with `implicitWidth: rowLayout.implicitWidth + 16` and invoke `system-update.sh "${Config.options.apps.terminal}"`.
6. Re-stow `quickshell` package, reload live shell, and run all 4 assert sections.
