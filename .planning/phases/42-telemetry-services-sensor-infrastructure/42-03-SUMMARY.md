---
phase: 42-telemetry-services-sensor-infrastructure
plan: "03"
subsystem: verification
tags: [verification, assert-harness, stow, dots-hyprland, strict, smoke]

requires:
  - phase: 42-01
    provides: "HardwareTelemetry.qml and StorageUsage.qml"
  - phase: 42-02
    provides: "PingService.qml, ResourceUsage.qml, and server.py clean targets JSON"
provides:
  - "Full passing test assertion suite scripts/phase42-telemetry-services-assert.sh"
  - "Strict stow symlink verification via ./arch/dots-hyprland.sh verify --strict"
affects:
  - 43-cpu-gpu-component (ready for UI pills and popups)
  - 44-memory-storage-component (ready for UI pills and popups)
  - 45-network-ping-component (ready for UI pills and popups)

tech-stack:
  added: []
  patterns:
    - "Automated smoke and regression test pipeline"
    - "GNU Stow symlink integrity verification with zero working tree drift"

key-files:
  created: []
  modified:
    - scripts/phase42-telemetry-services-assert.sh

key-decisions:
  - "Stow symlinks verified in ~/.config/quickshell/ii/services/ with upstream backup artifacts (.bak)"
  - "Full test suite automated execution passing with FAIL=0 FINDINGS=0"

requirements-completed:
  - Foundation for CPUGPU-01
  - Foundation for CPUGPU-02
  - Foundation for CPUGPU-03
  - Foundation for CPUGPU-04
  - Foundation for MEMDSK-01
  - Foundation for MEMDSK-02
  - Foundation for MEMDSK-03
  - Foundation for MEMDSK-04
  - Foundation for NETPING-01
  - Foundation for NETPING-02
  - Foundation for NETPING-03
  - Foundation for NETPING-04
  - Foundation for NETPING-05

coverage:
  - id: VERIFY-01
    description: "Full Phase 42 assertion harness and strict dots verification"
    requirement: "Full Phase 42 verification contract"
    verification:
      - kind: other
        ref: "scripts/phase42-telemetry-services-assert.sh"
        status: pass
    human_judgment: false

## Self-Check: PASSED
- `bash scripts/phase42-telemetry-services-assert.sh` PASSED (all 6 sections green, FAIL=0, FINDINGS=0)
- `./arch/dots-hyprland.sh verify --strict` PASSED (FAIL=0, FINDINGS=0)
