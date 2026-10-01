---
phase: 49-quickshell-resource-profiling-component-performance-audit
plan: 02
subsystem: profiling
tags:
  - quickshell
  - performance
  - profiling
  - telemetry
  - popup
  - ydotool
  - ipc
requires:
  - 49-01
provides:
  - popup-telemetry-suite
  - interactive-popup-attribution
affects:
  - scripts/profile-quickshell.sh
  - .planning/phases/49-quickshell-resource-profiling-component-performance-audit/benchmark-latest.json
  - .planning/phases/49-quickshell-resource-profiling-component-performance-audit/BENCHMARK.md
tech-stack:
  added: []
  patterns:
    - wayland-2x-uinput-navigation
    - quickshell-ipc-overlay-control
    - hyprland-layer-shell-verification
key-files:
  created: []
  modified:
    - scripts/profile-quickshell.sh
    - .planning/phases/49-quickshell-resource-profiling-component-performance-audit/benchmark-latest.json
    - .planning/phases/49-quickshell-resource-profiling-component-performance-audit/BENCHMARK.md
key-decisions:
  - "D-49-04: Implemented declarative POPUP_STAGES mapping across all 8 interactive popup components with calibrated Wayland 2x uinput cursor navigation and Quickshell IPC triggers"
  - "D-49-05: Implemented navigate_and_sample_popup with hyprctl layers verification and teardown cleanup, ensuring zero hanging popup surfaces"
  - "D-49-06: Added Interactive Popup Attribution matrix to BENCHMARK.md and verified all 8 popup stages via phase49-audit-assert.sh Section 3"
requirements-completed:
  - AUDIT-02
duration: 7 min
completed: 2026-09-30
coverage:
  - deliverable: "Interactive Popup Profiling Engine (scripts/profile-quickshell.sh)"
    verification:
      kind: "command"
      ref: "scripts/phase49-audit-assert.sh"
      status: "pass"
    human_judgment: false
  - deliverable: "Component & Popup Telemetry Coverage (AUDIT-02)"
    verification:
      kind: "command"
      ref: "scripts/phase49-audit-assert.sh"
      status: "pass"
    human_judgment: false
---

# Phase 49 Plan 02: Component Popup Profiling & Empirical Telemetry Summary

Automated interactive popup and component profiling engine utilizing calibrated Wayland $2\times$ uinput coordinates on `DP-1` and Quickshell IPC, verified active layer shell surfaces via `hyprctl layers`, and executed full empirical benchmark suite across all 8+ popups and status bar components satisfying AUDIT-02.

## Accomplishments

1. **Automated Interactive Popup Profiling Engine (`scripts/profile-quickshell.sh`)**:
   - Added declarative `POPUP_STAGES` table covering all 8 interactive status bar popups and overlay sidebars: `popup_cpugpu`, `popup_memstorage`, `popup_netping`, `popup_clock`, `popup_weather`, `popup_mediacontrols`, `popup_sidebarleft`, and `popup_sidebarright`.
   - Implemented `navigate_and_sample_popup` handling both `hover` (via `ydotool mousemove`) and `ipc` (`qs -c ii ipc call <target> open/close`).
   - Integrated layer shell presence verification via `hyprctl layers` (`quickshell:popup`, `quickshell:mediaControls`, `quickshell:sidebarLeft`, `quickshell:sidebarRight`).
   - Implemented clean teardown restoring cursor to neutral center `(860, 360)` and closing IPC overlays with zero hanging surfaces.
   - Added `--popups` CLI flag and single-stage popup selection.

2. **Empirical Popup Benchmark Suite Execution (AUDIT-02)**:
   - Evaluated all 8 interactive popup components:
     - `popup_mediacontrols`: **22.80%** CPU (avg) / **24.06%** CPU (peak), **29.02%** iGPU render load, **650 MHz** active GPU clock (highest CPU/GPU consumer).
     - `popup_netping`: **14.42%** CPU (avg) / **16.35%** CPU (peak), **24.11%** iGPU load, **1073.7** read syscalls/s (highest syscall churn).
     - `popup_sidebarleft`: **13.56%** CPU (avg), **30.98%** iGPU load.
     - `popup_memstorage`: **12.49%** CPU (avg), **23.68%** iGPU load.
     - `popup_cpugpu`: **7.22%** CPU (avg), **25.23%** iGPU load.
     - `popup_sidebarright`: **7.25%** CPU (avg), **11.64%** iGPU load.
     - `popup_clock`: **5.90%** CPU (avg), **9.49%** iGPU load.
     - `popup_weather`: **5.70%** CPU (avg), **8.67%** iGPU load.
   - Recorded all 8 stages into `benchmark-latest.json`.
   - Generated `Interactive Popup Attribution` reporting section in `BENCHMARK.md`.

3. **Assertion Verification**:
   - `bash scripts/phase49-audit-assert.sh -s 3` PASSED with 0 failures and 0 findings, confirming complete AUDIT-02 telemetry coverage across all 8 popup stages.

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

- `scripts/phase49-audit-assert.sh`: Section 1 PASSED (0 failures, 0 findings)
- `scripts/phase49-audit-assert.sh`: Section 2 PASSED (0 failures, 0 findings)
- `scripts/phase49-audit-assert.sh`: Section 3 PASSED (0 failures, 0 findings)
- Invariants asserted:
  - All 8 required popup stages recorded in telemetry (PASS)
  - BENCHMARK.md contains Master Attribution Matrix and Interactive Popup Attribution (PASS)
  - Zero working tree drift during assert execution (PASS)

## Self-Check: PASSED
