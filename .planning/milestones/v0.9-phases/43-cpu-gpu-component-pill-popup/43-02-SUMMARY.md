---
phase: 43-cpu-gpu-component-pill-popup
plan: "02"
subsystem: ui-bar-components
tags: [quickshell, pill, telemetry, cpu, gpu, thermals, animation, m3, thresholds]

requires:
  - phase: 43-01
    provides: "StyledPopup.qml base container and phase43-cpu-gpu-assert.sh test harness"
provides:
  - "CpuGpuPill.qml top bar status pill displaying live CPU load %, package temp, and Intel UHD 770 iGPU load %"
affects:
  - 43-03 (anchors CpuGpuPopup overlay to hoverArea of CpuGpuPill)
  - 46-left-zone-integration (integrates CpuGpuPill into Bar.qml)

tech-stack:
  added: []
  patterns:
    - "Inherits BarGroup root component with built-in 250ms emphasizedDecel width resizing animation (D-04, D-07)"
    - "Re-parented inert MouseArea (parent: root) consuming all clicks inertly with Qt.AllButtons and exporting hoverArea alias (D-17)"
    - "Two-tier independent alert threshold evaluation (Warning: 70%/75°C, Critical: 90%/85°C) mapped to dynamic M3 color tokens (D-09, D-10, D-11)"
    - "Breathing pulse SequentialAnimation on critical red with onRunningChanged opacity reset to 1.0 (D-12)"
    - "Responsive narrow-screen adaptability: useShortenedForm hides package temp while retaining CPU/GPU loads (D-03)"

key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml
  modified: []

key-decisions:
  - "D-01: Displays live CPU load %, package temp °C, and Intel UHD 770 iGPU load %"
  - "D-02: Distinct Material Symbols icons planner_review (CPU) and speed (GPU) with 6px cluster separation"
  - "D-03: Responsive useShortenedForm hides package temp on narrow viewports"
  - "D-07: Inherits BarGroup to leverage upstream bar styling and 250ms width resizing"
  - "D-09 & D-10: Independent two-tier alert thresholds for CPU and GPU"
  - "D-11: Dynamic Material You palette mapping: colTertiary (amber warning), colError (red critical), colOnLayer1 (normal)"
  - "D-12: Critical breathing pulse animation modulating opacity between 1.0 and 0.6 with explicit onRunningChanged reset"
  - "D-17: Re-parented inert MouseArea with acceptedButtons: Qt.AllButtons and hoverArea alias for popup anchoring"

requirements-completed:
  - CPUGPU-01
  - CPUGPU-04

coverage:
  - id: PILL-LOGIC
    description: "CpuGpuPill.qml component structure, alert thresholds, animations, and inert mouse handling"
    requirement: CPUGPU-01, CPUGPU-04
    verification:
      - kind: other
        ref: "./scripts/phase43-cpu-gpu-assert.sh -s 2"
        status: pass
    human_judgment: false

## Self-Check: PASSED
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml` exists
- `./scripts/phase43-cpu-gpu-assert.sh -s 2` PASSED with 0 failures and 0 findings
