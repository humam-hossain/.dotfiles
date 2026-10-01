---
phase: 43-cpu-gpu-component-pill-popup
plan: "01"
subsystem: ui-bar-overlay
tags: [quickshell, popup, debounce, geometry, clamping, animation, m3, testing]

requires:
  - phase: 42-01
    provides: "HardwareTelemetry.qml telemetry singleton"
provides:
  - "Automated 5-section regression assert harness scripts/phase43-cpu-gpu-assert.sh"
  - "Enhanced base overlay container restow/.../bar/StyledPopup.qml with cursor tracking debounce, boundary clamping, and M3 entrance animations"
affects:
  - 43-02 (consumes StyledPopup geometry and test harness section 2)
  - 43-03 (consumes StyledPopup overlay container and test harness sections 3, 5)

tech-stack:
  added: []
  patterns:
    - "Cursor tracking grace bridge via 200ms close debounce Timer and popup window HoverHandler (D-18)"
    - "Screen boundary clamping math: Math.round(Math.max(minX, Math.min(targetX, maxX))) preventing wlr-layer-shell margin overflow (D-19)"
    - "Material 3 expressive entrance transition: 150ms ParallelAnimation crossfade and 4px downward slide using expressiveEffects curve (D-20)"
    - "Fail-closed unprivileged test harness checking AST, threshold logic, geometry clamping, and Stow deployment (ASVS-L1)"

key-files:
  created:
    - scripts/phase43-cpu-gpu-assert.sh
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml
  modified: []

key-decisions:
  - "D-18: 200ms close debounce grace period in StyledPopup.qml bridging mouse transit across bar pill and popup window boundary"
  - "D-19: Screen boundary clamping math enforcing minX = Appearance.sizes.hyprlandGapsOut and maxX = screenWidth - implicitWidth - minX to eliminate negative margins"
  - "D-20: Material 3 expressive entrance transition animating opacity (0.0 to 1.0) and vertical translate (-4 to 0) over 150ms"

requirements-completed:
  - Foundation for CPUGPU-01

coverage:
  - id: ASSERT-43
    description: "Phase 43 automated 5-section assert harness"
    requirement: CPUGPU-01..04
    verification:
      - kind: other
        ref: "bash -n scripts/phase43-cpu-gpu-assert.sh && ./scripts/phase43-cpu-gpu-assert.sh --syntax"
        status: pass
    human_judgment: false
  - id: POPUP-BASE
    description: "Enhanced StyledPopup base overlay container with debounce, clamping, and animation"
    requirement: CPUGPU-01
    verification:
      - kind: other
        ref: "./scripts/phase43-cpu-gpu-assert.sh -s 4"
        status: pass
    human_judgment: false

## Self-Check: PASSED
- `scripts/phase43-cpu-gpu-assert.sh` exists and is executable
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml` exists
- `./scripts/phase43-cpu-gpu-assert.sh -s 4` PASSED with 0 failures and 0 findings
- `./scripts/phase43-cpu-gpu-assert.sh --syntax` PASSED with 0 failures and 0 findings
