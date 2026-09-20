---
phase: 32-component-representation-formatting-customization
plan: "04"
subsystem: ui
tags: [quickshell, qml, dots-hyprland, updates, media, utilbuttons, resources, gap-closure]

requires:
  - phase: 32-component-representation-formatting-customization
    plan: "01"
    provides: Phase 32 Nyquist assertion harness & native Tier 1 config
  - phase: 32-component-representation-formatting-customization
    plan: "02"
    provides: Tier 2 personal QML overlays and initial BarContent integration
  - phase: 32-component-representation-formatting-customization
    plan: "03"
    provides: Initial gap closure fixes for top bar controls and update launcher
provides:
  - Center utility buttons mic toggle retained and redundant muted status indicator removed (Option B)
  - Unattended system update script and config with pacman and yay cache cleanups
  - 6px icon-to-text progress spacing in Resource and 8px inter-resource margins in Resources
  - Media layout width clamping with Layout.maximumWidth for text truncation
affects: [quickshell, dots-hyprland, updates]

actuals:
  tokens: 11000
  tasks: 4
  commits: 4

tech-stack:
  added: []
  patterns: [Layout.maximumWidth text eliding, pacman and yay cache purging, visual spacing calibration]

key-files:
  created: []
  modified:
    - capture/ii/.config/illogical-impulse/config.json
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml
    - restow/quickshell/.config/quickshell/ii/scripts/system-update.sh
    - scripts/phase32-component-formatting-assert.sh

key-decisions:
  - "Restore showMicToggle: true under .bar.utilButtons while removing the redundant white mic_off Revealer from BarContent.qml right status cluster (Option B)."
  - "Update system-update.sh and config.json .apps.update to run yay -Syu --noconfirm && sudo pacman -Sc --noconfirm && yay -Sc --noconfirm."
  - "Increase spacing inside Resource.qml resourceRowLayout from 2px to 6px and set Resources.qml inter-resource margins to 8px."
  - "Apply Layout.maximumWidth: (root.useShortenedForm === 1) ? 140 : 200 to Media widget in BarContent.qml to enable text truncation on long media titles."

patterns-established:
  - "Layout.maximumWidth clamping on Media widget inside RowLayout to ensure downstream Text elision triggers."

requirements-completed: [COMP-01, COMP-02, COMP-04, COMP-06, COMP-07]

coverage:
  - id: D1
    description: "Retain center utility mic toggle and remove redundant muted mic indicator from status cluster (Option B)"
    requirement: COMP-06
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 1"
        status: pass
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D2
    description: "Update system-update.sh and config.json with unattended --noconfirm flags and pacman + yay cache cleanups"
    requirement: COMP-07
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 3"
        status: pass
    human_judgment: false
  - id: D3
    description: "Add 6px icon-to-text spacing in Resource.qml and 8px inter-resource margins in Resources.qml"
    requirement: COMP-01
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 2"
        status: pass
    human_judgment: false
  - id: D4
    description: "Clamp Media layout width in BarContent.qml with Layout.maximumWidth for title truncation"
    requirement: COMP-04
    verification:
      - kind: integration
        ref: "scripts/phase32-component-formatting-assert.sh --section 4"
        status: pass
    human_judgment: false

duration: 10 min
completed: "2026-09-20T12:55:00+06:00"
---

# Phase 32 Plan 04: Visual Refinement & UAT Gap Closure Summary

Resolved UAT gap G-32-2 by retaining utility mic toggle while pruning redundant status mic indicator, adding unattended upgrade and cache cleanup flags, increasing Resource icon-to-text spacing, and clamping Media layout width for long title truncation.

## Accomplishments

1. **Microphone Redundancy Refinement (COMP-06, Option B):**
   - Re-enabled `"showMicToggle": true` under `.bar.utilButtons` in `capture/ii/.config/illogical-impulse/config.json` and synchronized with live `~/.config/illogical-impulse/config.json`.
   - Removed the redundant white `mic_off` `Revealer` from `indicatorsRowLayout` in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`.
   - Preserved the critical amber `Privacy.micActive` recording alert in the status cluster, achieving clean separation of concerns: toggling in center utilities, active recording alert in status indicators.

2. **Unattended Update & Cache Purge (COMP-07):**
   - Updated `restow/quickshell/.config/quickshell/ii/scripts/system-update.sh` to execute `yay -Syu --noconfirm && sudo pacman -Sc --noconfirm && yay -Sc --noconfirm`.
   - Updated `.apps.update` in `config.json` to match with the same unattended update and dual cache purge pipeline.

3. **System Resource Spacing & Margins (COMP-01, COMP-02):**
   - Increased `spacing` from 2px to 6px inside `RowLayout { id: resourceRowLayout }` in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resource.qml`, providing comfortable visual separation between the circular progress meter and the metric text across RAM, Swap, and CPU.
   - Set `Layout.leftMargin: shown ? 8 : 0` on Swap and CPU in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Resources.qml` for balanced pill separation.

4. **Media Player Width Clamping (COMP-04):**
   - Added `Layout.maximumWidth: (root.useShortenedForm === 1) ? 140 : 200` to the `Media` component in `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`.
   - Enabled proper `Text.ElideRight` truncation for long media titles while preserving dynamic sizing for shorter titles.
   - Updated `scripts/phase32-component-formatting-assert.sh` across Sections 1, 2, 3, and 4 to enforce all new visual and functional contracts.

## Task Commits

1. **Task 1: Re-enable utility mic toggle and remove status cluster muted mic indicator** - `10ccb8e` (fix)
2. **Task 2: Update system-update.sh with unattended flags and pacman + yay cache cleanups** - `e410444` (feat)
3. **Task 3: Add icon-to-text spacing in Resource.qml and verify inter-resource margins** - `48d0576` (feat)
4. **Task 4: Clamp Media layout width for text truncation and update test assertions** - `d1dcdca` (feat)

## Deviations from Plan

None - plan executed exactly as written.

## Verification & Self-Check

- `scripts/phase32-component-formatting-assert.sh`: Exited 0 with `FAIL=0 FINDINGS=0` across all 4 sections.
- `arch/dots-hyprland.sh verify --strict`: Exited 0 with 0 findings.
- Live Quickshell process running with all updated overlays stowed without folding.

## Self-Check: PASSED
