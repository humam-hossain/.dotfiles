---
phase: 43-cpu-gpu-component-pill-popup
plan: "04"
subsystem: ui-bar-overlay
tags: [quickshell, popup, overlay, bar, telemetry, gap-closure, uat]
gap_closure: true
gap_ids:
  - G-43-1
  - G-43-2
  - G-43-3
  - G-43-4
  - G-43-5
  - G-43-6

requires:
  - phase: 43-01
    provides: "Enhanced StyledPopup.qml base container"
  - phase: 43-02
    provides: "CpuGpuPill.qml status bar component"
  - phase: 43-03
    provides: "CpuGpuPopup.qml telemetry inspector overlay"
provides:
  - "Qualified identifier resolution for closeTimer in StyledPopup.qml under Bound ComponentBehavior"
  - "CpuGpuPopup instantiation bound to CpuGpuPill hoverArea"
  - "CpuGpuPill mounted in BarContent.qml Left Zone"
affects:
  - 46-left-zone-integration (pre-mounted CpuGpuPill in BarContent)

tech-stack:
  added: []
  patterns:
    - "Qualified property access via root.closeTimer under pragma ComponentBehavior: Bound"
    - "Self-encapsulated popup overlay instantiation inside pill MouseArea matching upstream ClockWidget/Resources pattern"
    - "BarContent.qml Left Zone component mounting with useShortenedForm binding"

key-files:
  created: []
  modified:
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml

key-decisions:
  - "D-21: Qualified Timer declaration and call sites on root in StyledPopup.qml to prevent runtime ReferenceErrors under Bound component behavior"
  - "D-22: Self-encapsulate CpuGpuPopup within CpuGpuPill's inertMouseArea anchored to root.hoverArea"
  - "D-23: Mount CpuGpuPill directly into BarContent.qml Left Zone preceding legacy resourcesGroup for live user testing"

requirements-completed:
  - CPUGPU-01
  - CPUGPU-02
  - CPUGPU-03
  - CPUGPU-04

coverage:
  - id: GAP-CLOSURE-43
    description: "Resolution of UAT gaps G-43-1 through G-43-6 via timer qualification, popup anchoring, and bar mounting"
    requirement: CPUGPU-01, CPUGPU-02, CPUGPU-03, CPUGPU-04
    verification:
      - kind: other
        ref: "bash scripts/phase43-cpu-gpu-assert.sh && ./arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false

## Self-Check: PASSED
- `StyledPopup.qml` qualifies `root.closeTimer.stop()` / `root.closeTimer.restart()` with `readonly property Timer closeTimer`
- `CpuGpuPill.qml` instantiates `CpuGpuPopup { hoverTarget: root.hoverArea }`
- `BarContent.qml` mounts `CpuGpuPill` with `useShortenedForm: root.useShortenedForm`
- All 5 sections of `scripts/phase43-cpu-gpu-assert.sh` pass cleanly with FAIL=0 FINDINGS=0
- `./arch/dots-hyprland.sh verify --strict` passes cleanly with FAIL=0 FINDINGS=0
- Quickshell session reloaded live via `qs -c ii`
