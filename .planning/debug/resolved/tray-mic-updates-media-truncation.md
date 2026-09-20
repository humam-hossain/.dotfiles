---
status: resolved
started: "2026-09-20T12:42:00+06:00"
updated: "2026-09-20T12:54:00+06:00"
---

# Debug Session: Tray Mic Indicator, Updates Cleanup & Media Title Truncation

**Gap:** Re-enable center utility mic toggle, remove tray white mic_off indicator while retaining amber privacy mic, configure `--noconfirm` and cache cleanup in system updates, and clamp Media title text truncation per upstream dots-hyprland behavior.
**Severity:** major
**Status:** diagnosed

## Symptoms & User Feedback

1. **Microphone Redundancy Target Mismatch:**
   - Previous plan (32-03) set `"showMicToggle": false` under `.bar.utilButtons` in `config.json`.
   - User clarified: The center utility button mic toggle is wanted. The redundant mic is in the right sidebar status indicators / tray area where two mic icons appear: one is amber (active privacy recording indicator), and another is white (`mic_off` shown when muted). The white mute indicator in the status cluster should be removed.
2. **Updates Button Execution:**
   - `system-update.sh` currently runs `yay -Syu` interactively.
   - User requested: Add `--noconfirm` tag, and after installing pacman and yay packages, clean caches and old updates/installation files (`yay -Sc --noconfirm`).
3. **Media Widget Title Truncation:**
   - Media pill expands indefinitely displaying full un-truncated audio/video titles.
   - User noted: dots-hyprland originally truncated title text with ellipsis; when dynamic pill sizing was introduced, the explicit clamping was lost.

## Root Cause Analysis

### 1. Microphone Configuration & Status Cluster
- **Util Button Toggle:** In `capture/ii/.config/illogical-impulse/config.json` and live `~/.config/illogical-impulse/config.json`, `"showMicToggle"` is `false`. It should be `true`.
- **Status Indicator Revealer:** In `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` (lines 282-294), inside `indicatorsRowLayout`:
  ```qml
  Revealer {
      reveal: Audio.source?.audio?.muted ?? false
      Layout.fillHeight: true
      Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
      Behavior on Layout.rightMargin {
          animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
      }
      MaterialSymbol {
          text: "mic_off"
          iconSize: Appearance.font.pixelSize.larger
          color: rightSidebarButton.colText
      }
  }
  ```
  This revealer shows a white `mic_off` icon whenever the microphone is muted. Removing this `Revealer` eliminates the tray mic duplicate while preserving the amber PipeWire privacy alert (`Privacy.micActive`, lines 228-246).

### 2. Updates Script Flags & Post-Upgrade Cache Clean
- In `restow/quickshell/.config/quickshell/ii/scripts/system-update.sh`:
  Commands currently invoke `yay -Syu`.
- Needs update to:
  `yay -Syu --noconfirm && yay -Sc --noconfirm`
  This performs unattended package downloads/upgrades for repo and AUR packages, followed by cleaning old cached `.pkg.tar.zst` packages and uninstalled package files.
- In `capture/ii/.../config.json`, update `.apps.update` to align with the same flags.

### 3. Media Pill Width & Elision
- In upstream `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/BarContent.qml`, `leftCenterGroup` had `implicitWidth: root.centerSideModuleWidth` (360px in verbose mode).
- Inside `vendor/.../Media.qml`, `StyledText` uses `elide: Text.ElideRight` and `Layout.fillWidth: true`. Because the parent `leftCenterGroup` had a fixed width, `StyledText`'s available width was strictly bounded (~200px), causing long titles to truncate gracefully.
- In commit `c6270e2` (Phase 31 Plan 02), `implicitWidth: root.centerSideModuleWidth` was removed from `leftCenterGroup` to permit dynamic content-driven pill widths. However, without a width limit, `Media`'s `implicitWidth` defaults to `rowLayout.implicitWidth`, which expands to the full unbounded string width of the track title.
- **Fix:** In `BarContent.qml`, constrain `Media` with `Layout.maximumWidth: Math.round(root.centerSideModuleWidth * 0.6)` (or ~220px in standard verbose form, ~150px in shortened form) or deploy an overlay `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml` with `implicitWidth: Math.min(rowLayout.implicitWidth + rowLayout.spacing * 2, maxMediaWidth)` so `elide: Text.ElideRight` activates for long titles while still allowing shorter titles to shrink-wrap.

## Files Involved

- `capture/ii/.config/illogical-impulse/config.json`: Re-enable `showMicToggle: true` under `.bar.utilButtons`; update `.apps.update`.
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`:
  - Remove `Audio.source?.audio?.muted` `mic_off` Revealer from `indicatorsRowLayout`.
  - Constrain `Media` component layout width so title text truncates with `elide: Text.ElideRight`.
- `restow/quickshell/.config/quickshell/ii/scripts/system-update.sh`: Append `--noconfirm` to `yay -Syu` and chain `yay -Sc --noconfirm`.
- `scripts/phase32-component-formatting-assert.sh`: Update assertions in Section 1 (check `showMicToggle: true`), Section 3 (check tray mic_off removed), and Section 4 (check Media truncation constraint).
