---
phase: 32-component-representation-formatting-customization
plan: "03"
subsystem: ui
tags: [quickshell, qml, dots-hyprland, updates, media, utilbuttons, gap-closure]

requires:
  - phase: 32-component-representation-formatting-customization
    plan: "01"
    provides: Phase 32 Nyquist assertion harness & native Tier 1 config
  - phase: 32-component-representation-formatting-customization
    plan: "02"
    provides: Tier 2 personal QML overlays and initial BarContent integration
provides:
  - Resolved triple microphone toggle redundancy by setting showMicToggle false
  - Restored upstream dots-hyprland media widget visibility on pause
  - Dynamic system update launcher script (system-update.sh) with terminal hold semantics
  - UpdatesButton refactored to root MouseArea with explicit geometric bounds
affects: [quickshell, dots-hyprland, updates]

actuals:
  tokens: 8500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns: [Terminal dynamic hold semantics, root MouseArea layout hit testing, upstream visual parity]

key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/scripts/system-update.sh
  modified:
    - capture/ii/.config/illogical-impulse/config.json
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml
    - scripts/phase32-component-formatting-assert.sh

key-decisions:
  - "Set showMicToggle: false under .bar.utilButtons to eliminate triple mic clutter (Option A)."
  - "Revert Media visibility in BarContent.qml to root.useShortenedForm < 2 matching upstream dots-hyprland defaults."
  - "Create system-update.sh to inspect dots-hyprland terminal preferences and execute yay -Syu with appropriate hold flags."
  - "Refactor UpdatesButton.qml to root MouseArea with 16px row padding for reliable hit testing in BarGroup."

patterns-established:
  - "Root MouseArea for bar button components inside GridLayout to prevent hit testing collapse."

requirements-completed: [COMP-04, COMP-06, COMP-07]

coverage:
  - id: D1
    description: "Disable redundant microphone toggle in utility buttons (Option A) to prevent triple-mic icons"
    requirement: COMP-06
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Restore upstream dots-hyprland Media stability on pause without isPlaying auto-collapse"
    requirement: COMP-04
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 4"
        status: pass
    human_judgment: false
  - id: D3
    description: "Implement system-update.sh launcher and refactor UpdatesButton to root MouseArea with dynamic terminal resolution"
    requirement: COMP-07
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 3"
        status: pass
    human_judgment: false

duration: 12 min
completed: "2026-09-20T10:27:00+06:00"
---

# Phase 32 Plan 03: Gap Closure for Top Bar Controls & Update Launcher Summary

Eliminated triple microphone redundancy, restored upstream dots-hyprland Media pause stability, and implemented dynamic terminal update launcher for the top status bar pill.

## Accomplishments

1. **Microphone Redundancy Fix (COMP-06, Option A):**
   - Configured `"showMicToggle": false` under `.bar.utilButtons` in `capture/ii/.config/illogical-impulse/config.json` and synchronized with live `~/.config/illogical-impulse/config.json`.
   - Eliminated the redundant third microphone icon from utility buttons while preserving the active recording alert (`Privacy.micActive`) and the mute indicator (`Audio.source.muted`).

2. **Media Player Stability on Pause (COMP-04):**
   - Reverted `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` Media visibility to `visible: root.useShortenedForm < 2`.
   - Removed the `isPlaying` auto-collapse condition so pausing audio/video keeps controls visible per upstream dots-hyprland design.
   - Updated Section 4 of `scripts/phase32-component-formatting-assert.sh` to assert upstream visibility.

3. **Terminal-Aware Updates Launcher (COMP-07):**
   - Created executable `restow/quickshell/.config/quickshell/ii/scripts/system-update.sh` (mode 0755) resolving terminal preference via CLI argument, `~/.config/illogical-impulse/config.json` `.apps.terminal`, `$TERMINAL`, or installed fallbacks (`kitty`, `alacritty`, `foot`, `wezterm`).
   - Dispatches `yay -Syu` with appropriate terminal hold flags (`--hold`, `-H`).
   - Refactored `restow/quickshell/.config/quickshell/ii/modules/ii/bar/UpdatesButton.qml` to be a root `MouseArea` with explicit layout bounds (`implicitWidth: rowLayout.implicitWidth + 16`) and pointing hand cursor.
   - Updated `apps.update` in `config.json` to launch `yay -Syu`.
   - Deployed symlinks via GNU Stow `--no-folding` and verified clean live Quickshell operation.

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `scripts/phase32-component-formatting-assert.sh`: Exited 0 with `FAIL=0 FINDINGS=0` across all 4 sections.
- `arch/dots-hyprland.sh verify --strict`: Exited 0 with 0 findings.
- Live Quickshell process running with active overlays.

## Self-Check: PASSED
