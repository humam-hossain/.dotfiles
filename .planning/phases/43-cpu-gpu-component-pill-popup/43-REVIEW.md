---
phase: 43-cpu-gpu-component-pill-popup
status: clean
depth: standard
files_reviewed: 4
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
---

# Phase 43 Code Review Report

**Reviewed Files:**
- `scripts/phase43-cpu-gpu-assert.sh`
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml`
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml`
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml`

## Executive Summary

A comprehensive code review was performed on all Phase 43 implementation files:

1. **Automated Assertion Test Harness (`scripts/phase43-cpu-gpu-assert.sh`)**:
   - Strict bash error handling with `set -euo pipefail`.
   - Root privilege escalation guard `[[ "${EUID:-$(id -u)}" -ne 0 ]]` failing closed on sudo/root execution (ASVS L1).
   - Clean CLI parameter handling supporting sections 1–5, `--quick`, `--syntax`, and help.
   - Comprehensive test assertions covering QML AST bindings, threshold properties, geometry clamping math, and GNU Stow packaging.

2. **Base Overlay Container (`restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml`)**:
   - Declares `pragma ComponentBehavior: Bound`.
   - Seamless cursor tracking bridge implemented via single-shot `Timer` (`interval: 200`, `repeat: false`) and `HoverHandler` tracking `popupHovered` across window boundaries (D-18).
   - Horizontal and vertical screen boundary clamping math enforcing `minX = Appearance.sizes.hyprlandGapsOut` and `maxX = screenWidth - popupBackground.implicitWidth - minX`, eliminating negative `wlr-layer-shell` margins (D-19).
   - Material 3 expressive entrance transition: 150ms `ParallelAnimation` animating opacity (0.0 to 1.0) and vertical translation (-4 to 0) with `Appearance.animationCurves.expressiveEffects` (D-20).
   - 100% backward compatibility preserved for existing bar components.

3. **Status Bar Telemetry Pill (`restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml`)**:
   - Declares `pragma ComponentBehavior: Bound`.
   - Root inherits `BarGroup` (D-07), leveraging upstream 250ms `emphasizedDecel` width resizing animation (D-04).
   - Encapsulates re-parented `MouseArea` (`parent: root`) to avoid creating phantom grid cells in `gridLayout`, consuming clicks inertly (`acceptedButtons: Qt.AllButtons`) and exporting `hoverArea` alias (D-17).
   - Live telemetry readouts for CPU load %, package temp °C, and Intel UHD 770 GPU load % with distinct Material Symbols `planner_review` and `speed` (D-01, D-02).
   - Responsive `useShortenedForm` hides package temp on narrow viewports while preserving load percentages (D-03).
   - Independent two-tier alert thresholds for CPU, GPU, and thermals mapped dynamically to Material You tokens `colTertiary` (amber warning) and `colError` (red critical) with zero hardcoded hex colors (D-09, D-10, D-11).
   - Breathing pulse `SequentialAnimation` for critical alert state with guaranteed opacity reset to `1.0` via `onRunningChanged` (D-12).
   - Robust null coalescing (`|| 0.0`) on all sysfs telemetry bindings.

4. **Telemetry Inspector Overlay (`restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml`)**:
   - Declares `pragma ComponentBehavior: Bound`.
   - Inherits `StyledPopup` as root container (D-17).
   - Adaptive fast-polling lifecycle management incrementing `fastPollingRequests` on popup open and decrementing on close and `Component.onDestruction`, preventing polling timer leaks.
   - Dual-column 230px layout: Left column CPU, Right column Top GPU, Right column Bottom Motherboard & Platform (D-13).
   - Segregated P-cores (12T) and E-cores (8T) progress meters with active clock MHz (D-14).
   - Intel UHD 770 iGPU load, render clock MHz, and thermal throttle status badge (D-15).
   - Platform B760 VRM temperature and energy performance preference (EPP) (D-16).
   - Zero-root defense against CVE-2020-8694 Platypus side-channel attack: renders static fallback string `"N/A (unprivileged)"` with zero privileged file probing (D-05).

## Verification Results
- `scripts/phase43-cpu-gpu-assert.sh`: PASSED (FAIL=0 FINDINGS=0 across all 5 sections)
- `./arch/dots-hyprland.sh verify --strict`: PASSED (FAIL=0 FINDINGS=0)
- Upstream submodule status: Clean
