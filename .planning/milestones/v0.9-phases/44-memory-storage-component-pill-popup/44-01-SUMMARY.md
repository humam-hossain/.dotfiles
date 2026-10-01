---
phase: "44"
plan: "01"
subsystem: memory-storage-telemetry
tags: [quickshell, qml, telemetry, memory, storage, pill, test-harness]

requires:
  - phase: 43-cpu-gpu-component-pill-popup
    provides: Status bar pill and popup component architectural patterns
provides:
  - Wave 0 test harness scripts/phase44-memory-storage-assert.sh
  - Hardened ResourceUsage.qml service exposing distinct MemFree
  - Hardened StorageUsage.qml service with dynamic deviceToMount mapping and 30s background fallback polling
  - Top status bar MemoryStoragePill.qml widget with dual circular progress rings and Material Symbols
affects: [44-02]

actuals:
  tokens: 45000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns: [Dual Circular Progress Indicators, Two-Tier Alert Thresholds, Dynamic Device Mapping, Fallback Polling]

key-files:
  created:
    - scripts/phase44-memory-storage-assert.sh
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml
  modified:
    - restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml
    - restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml

key-decisions:
  - "D-01: ResourceUsage.qml parses MemFree distinctly from /proc/meminfo while preserving memoryUsed calculation formula."
  - "D-02: StorageUsage.qml resolves deviceToMount dynamically by inspecting the mounts array, resolving NVMe drive inversion."
  - "D-03: StorageUsage.qml implements 30s background fallback polling alongside I/O delta triggers to ensure periodic discovery during idle."
  - "D-04: MemoryStoragePill.qml inherits BarGroup, declares Bound component behavior, encapsulates re-parented inert MouseArea, and renders dual circular progress rings with Material Symbols 'memory' and 'storage'."
  - "D-05: MemoryStoragePill.qml retains both RAM and Storage indicators unconditionally without hiding when useShortenedForm > 0."

requirements-completed:
  - MEMDSK-01
  - MEMDSK-04

duration: 10 min
completed: 2026-09-28
status: complete
---

# Phase 44 Plan 01: Wave 0 Test Harness, Telemetry Services Hardening & MemoryStoragePill Widget Summary

**Established automated assertion suite `scripts/phase44-memory-storage-assert.sh`, hardened `ResourceUsage.qml` and `StorageUsage.qml` kernel procfs telemetry services, and built the top status bar `MemoryStoragePill.qml` widget.**

## Performance & Execution Metrics

- **Duration:** 10 min
- **Completed:** 2026-09-28
- **Tasks:** 3
- **Files created:** 2 (`scripts/phase44-memory-storage-assert.sh`, `MemoryStoragePill.qml`)
- **Files modified:** 2 (`ResourceUsage.qml`, `StorageUsage.qml`)
- **Commits:** `4304040`, `a39b22b`, `575d71e`

## Accomplishments

1. **Created Wave 0 Assertion Suite (`scripts/phase44-memory-storage-assert.sh`):**
   - Implemented 5 test sections covering telemetry services hardening, status bar pill component logic, popup layout and bindings, formatting helpers, and GNU Stow symlink integrity.
   - Verified command-line flags (`[1-5]`, `--section` / `-s`, `--quick`, `--syntax`, `--help`) and root fail-closed enforcement.

2. **Hardened Telemetry Singleton Services:**
   - **`ResourceUsage.qml`:** Fixed `MemFree` parsing using dedicated regex match against `/proc/meminfo` distinct from `MemAvailable`, preserving standard Linux `free -m` calculation for `memoryUsed`.
   - **`StorageUsage.qml`:** Replaced hardcoded NVMe device mapping with dynamic matching against the `mounts` array, resolving inverted mount assignments. Added 30s background fallback polling to `updateDiskIo()` guaranteeing periodic updates during disk idle.

3. **Built Top Status Bar Widget (`MemoryStoragePill.qml`):**
   - Implemented `BarGroup` root with `pragma ComponentBehavior: Bound`.
   - Encapsulated re-parented inert `MouseArea` covering root (`parent: root`, `anchors.fill: parent`, `acceptedButtons: Qt.AllButtons`) exposing `hoverArea` alias for popup anchoring.
   - Built dual `ClippedFilledCircularProgress` rings (implicit size 20, unsharpened line width) displaying Material Symbols `memory` and `storage`.
   - Configured two-tier alert states (70% warning, 90% critical) with dots-hyprland amber fallback (`#FFA000`) and 600ms infinite breathing pulse animations (`ramPulseAnimation`, `storagePulseAnimation`).
   - Ensured both RAM and Storage indicators remain visible unconditionally regardless of `useShortenedForm`.
   - Kept status bar pill dedicated strictly to capacity percentages without disk I/O metrics.

## Verification Results

- `scripts/phase44-memory-storage-assert.sh 1` PASSED: All service assertions verified.
- `scripts/phase44-memory-storage-assert.sh 2` PASSED: All status bar pill assertions verified.

## Self-Check: PASSED
- [x] scripts/phase44-memory-storage-assert.sh exists and is executable
- [x] restow/quickshell/.config/quickshell/ii/services/ResourceUsage.qml verified
- [x] restow/quickshell/.config/quickshell/ii/services/StorageUsage.qml verified
- [x] restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml verified
- [x] Commits `4304040`, `a39b22b`, `575d71e` present in git history
