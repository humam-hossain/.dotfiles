---
phase: 43-cpu-gpu-component-pill-popup
plan: "05"
subsystem: ui-bar-overlay
tags: [quickshell, popup, overlay, bar, telemetry, gap-closure, uat]
gap_closure: true
gap_ids:
  - G-43-1
  - G-43-4
  - G-43-5

requires:
  - phase: 43-04
    provides: "Gap closure 43-04 bar mounting and popup encapsulation"
provides:
  - "Regex loop frequency parsing in HardwareTelemetry.qml eliminating matchAll exception"
  - "Full 6-sensor Gigabyte WMI platform temperature binding and platform average calculation"
  - "Coretemp segregated P-core and E-core average temperature calculation"
  - "Interactive power profile switching via powerprofilesctl"
  - "Circular progress indicator rings for CPU and GPU in CpuGpuPill.qml"
  - "Sports_esports GPU icon in CpuGpuPill.qml and CpuGpuPopup.qml"
  - "Symmetric container padding in CpuGpuPopup.qml"
  - "Expanded 20-thread individual core load and frequency inspector in CpuGpuPopup.qml"
affects:
  - 43-cpu-gpu-component-pill-popup

tech-stack:
  added: []
  patterns:
    - "Standard RegExp.prototype.exec loop in QML JS engine replacing unsupported matchAll"
    - "Try/catch failure isolation across sub-update routines in pollAll"
    - "ClippedFilledCircularProgress integration around MaterialSymbol icons"
    - "Centered popup layout solving symmetric boundary padding"
    - "Interactive EPP and powerprofilesctl profile cycling"

key-files:
  created: []
  modified:
    - restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml
    - scripts/phase43-cpu-gpu-assert.sh

key-decisions:
  - "D-24: Replaced unsupported String.matchAll with standard RegExp exec loop in HardwareTelemetry.qml, unblocking GPU and thermal polling"
  - "D-25: Wrapped pollAll subroutines in individual try/catch blocks for fault isolation across hardware telemetry sources"
  - "D-26: Bound all 6 gigabyte_wmi platform sensors (temp1..temp6) and computed platformTempAvg, plus pCoreTempAvg and eCoreTempAvg from coretemp"
  - "D-27: Changed GPU icon from 'speed' to 'sports_esports' and wrapped CPU/GPU icons in ClippedFilledCircularProgress rings in CpuGpuPill"
  - "D-28: Fixed CpuGpuPopup container padding by anchoring content to parent center, and expanded CPU column to list all 12 P-core threads and 8 E-core threads"
  - "D-29: Added interactive power-profile switcher button in CpuGpuPopup cycling power-saver, balanced, and performance via powerprofilesctl"

requirements-completed:
  - CPUGPU-01
  - CPUGPU-02
  - CPUGPU-03
  - CPUGPU-04

coverage:
  - id: GAP-CLOSURE-43-05
    description: "Resolution of UAT gaps G-43-1, G-43-4, and G-43-5"
    requirement: CPUGPU-01, CPUGPU-02, CPUGPU-03, CPUGPU-04
    verification:
      - kind: other
        ref: "bash scripts/phase43-cpu-gpu-assert.sh && ./arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false

## Self-Check: PASSED
- `HardwareTelemetry.qml` uses `while ((match = regex.exec(text)) !== null)` without `matchAll`
- `pollAll()` wraps all subroutines in try/catch blocks
- All 6 platform sensors and P/E core average temperatures exposed
- `CpuGpuPill.qml` uses `'sports_esports'` icon and `ClippedFilledCircularProgress`
- `CpuGpuPopup.qml` provides symmetric padding, 20 individual core thread meters with MHz, all 6 platform sensors, and interactive power profile switcher
- All 5 sections of `scripts/phase43-cpu-gpu-assert.sh` pass cleanly with FAIL=0 FINDINGS=0
- `./arch/dots-hyprland.sh verify --strict` passes cleanly with FAIL=0 FINDINGS=0
- Quickshell session reloaded live via `qs -c ii`
