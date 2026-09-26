---
phase: 43-cpu-gpu-component-pill-popup
plan: "03"
subsystem: ui-bar-overlay
tags: [quickshell, popup, overlay, telemetry, cpu, gpu, b760, stow, deployment]

requires:
  - phase: 43-01
    provides: "Enhanced StyledPopup.qml base container"
  - phase: 43-02
    provides: "CpuGpuPill.qml status bar component"
provides:
  - "CpuGpuPopup.qml dual-column telemetry inspector overlay"
  - "GNU Stow deployed leaf symlinks for CpuGpuPill, CpuGpuPopup, and StyledPopup"
affects:
  - 46-left-zone-integration (integrates popup anchoring and bar layout)

tech-stack:
  added: []
  patterns:
    - "Inherits StyledPopup container with dual 230px column layout (D-13, D-17)"
    - "Segregated P-core (12T) and E-core (8T) progress meters with active MHz frequency tracking (D-14)"
    - "Zero-root unprivileged power fallback 'N/A (unprivileged)' eliminating Platypus/RAPL attack surface (D-05, ASVS-L1)"
    - "Intel UHD 770 iGPU load meter, render clock MHz, and thermal throttle status badge (D-15)"
    - "Platform B760 VRM temperature and EPP telemetry readouts (D-16)"
    - "Leak-free adaptive fast-polling lifecycle management on active and Component.onDestruction"
    - "GNU Stow leaf deployment preserving upstream vendor/dots-hyprland cleanliness"

key-files:
  created:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml
  modified: []

key-decisions:
  - "D-05: Platypus/RAPL side-channel mitigation — strictly renders 'N/A (unprivileged)' fallback without root dependencies"
  - "D-13: Dual-column right-split layout (Left: CPU, Right Top: GPU, Right Bottom: Platform B760)"
  - "D-14: Segregated P-cores (12T) and E-cores (8T) with active clock MHz"
  - "D-15: Intel UHD 770 GPU telemetry including render clock MHz and throttle badge"
  - "D-16: Motherboard B760 VRM temperature and energy performance preference (EPP)"
  - "D-17: Inherits StyledPopup and anchors to hoverArea of CpuGpuPill"

requirements-completed:
  - CPUGPU-01
  - CPUGPU-02
  - CPUGPU-03
  - CPUGPU-04

coverage:
  - id: POPUP-LAYOUT
    description: "CpuGpuPopup.qml layout, segregated core meters, GPU/platform telemetry, and fast-polling lifecycle"
    requirement: CPUGPU-01, CPUGPU-02, CPUGPU-03, CPUGPU-04
    verification:
      - kind: other
        ref: "./scripts/phase43-cpu-gpu-assert.sh -s 3"
        status: pass
    human_judgment: false
  - id: STOW-DEPLOY
    description: "Stow deployment and upstream dots-hyprland strict verification"
    requirement: CPUGPU-01
    verification:
      - kind: other
        ref: "./scripts/phase43-cpu-gpu-assert.sh && ./arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false

## Self-Check: PASSED
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml` exists
- Stow leaf symlinks exist in `~/.config/quickshell/ii/modules/ii/bar/` for `CpuGpuPill.qml`, `CpuGpuPopup.qml`, and `StyledPopup.qml`
- `./scripts/phase43-cpu-gpu-assert.sh` passed all 5 sections with FAIL=0 FINDINGS=0
- `./arch/dots-hyprland.sh verify --strict` passed cleanly with FAIL=0 FINDINGS=0
- `vendor/dots-hyprland` git status is completely clean
