---
phase: 43-cpu-gpu-component-pill-popup
plan: "06"
subsystem: ui-bar-overlay
tags: [quickshell, popup, overlay, bar, telemetry, gap-closure, uat, optimization, amber-warning, breathing-pulse]
gap_closure: true
gap_ids:
  - G-43-1
  - G-43-4
  - G-43-5
  - G-43-6

requires:
  - phase: 43-05
    provides: "Gap closure 43-05 telemetry binding, icons, and thread meters"
provides:
  - "Decoupled fast polling in HardwareTelemetry.qml reserving 1000ms cadence strictly for active popup or high CPU load (> 0.50)"
  - "Eliminated continuous subprocess forking of powerprofilesctl get during background idle"
  - "EMA-filtered Intel UHD 770 GPU load calculation eliminating RC6 timer sampling jitter"
  - "Individual P-core and E-core temperature arrays (pCoreTemps, eCoreTemps) in HardwareTelemetry.qml"
  - "Dots-hyprland amber warning color fallback (#FFA000) for CPU, GPU, and temperature in CpuGpuPill.qml"
  - "Multi-tier temperature warning (>= 65°C) and critical (>= 80°C) alert thresholds"
  - "Breathing pulse animation modulating opacity between 1.0 and 0.4 across pill circular rings, text labels, and popup badges"
  - "Widened 320px dual-column layout in CpuGpuPopup.qml eliminating text clipping and label wrapping"
  - "Unified [MHz] [Load %] [Temp °C] metric header layout followed by progress bars for Overall CPU, P-Cores, and E-Cores"
  - "Individual 20-thread meters displaying C{n}, load bar, %, MHz, and per-core temp °C"
  - "Modernized platform sensors with small typography, crisp white on-layer color, and dynamic temperature alert colors"
affects:
  - 43-cpu-gpu-component-pill-popup

tech-stack:
  added: []
  patterns:
    - "Exponential moving average (alpha 0.4) on GPU RC6 residency sleep delta"
    - "Dynamic amber warning color token fallback (#FFA000) compatible with Material You"
    - "ParallelAnimation within SequentialAnimation modulating multi-target critical pulse opacity"
    - "Unified inline telemetry header row architecture [MHz] [Load %] [Temp °C]"

key-files:
  created: []
  modified:
    - restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml
    - scripts/phase43-cpu-gpu-assert.sh

key-decisions:
  - "D-30: Decoupled fastPolling from baseline gpuLoad, triggering 1000ms polling strictly when fastPollingRequests > 0 or overallCpuLoad > 0.50, and gating powerprofilesctl get"
  - "D-31: Applied 0.4/0.6 exponential moving average filter to gpuLoad, eliminating RC6 sampling jitter spikes during desktop idle"
  - "D-32: Exposed individual pCoreTemps and eCoreTemps arrays and routed per-thread temperatures to C0–C19 thread meters in CpuGpuPopup"
  - "D-33: Replaced colTertiary with dots-hyprland amber warning color fallback (#FFA000) and lowered temperature warning to >= 65°C and critical to >= 80°C"
  - "D-34: Expanded breathing pulse animation to modulate opacity (1.0 to 0.4) across circular indicator rings, percentage text, temperature text, and popup critical badges"
  - "D-35: Widen popup columns to 320px and restructured CPU column into unified [MHz] [Load %] [Temp °C] headers over progress bars, removing redundant standalone rows"

requirements-completed:
  - CPUGPU-01
  - CPUGPU-02
  - CPUGPU-03
  - CPUGPU-04

coverage:
  - id: GAP-CLOSURE-43-06
    description: "Resolution of UAT gaps G-43-1, G-43-4, G-43-5, and G-43-6"
    requirement: CPUGPU-01, CPUGPU-02, CPUGPU-03, CPUGPU-04
    verification:
      - kind: other
        ref: "bash scripts/phase43-cpu-gpu-assert.sh && ./arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false

## Self-Check: PASSED
- `HardwareTelemetry.qml`: `fastPolling` decoupled from baseline GPU load, `powerprofilesctl get` gated from idle polling, EMA applied to `gpuLoad`, and `pCoreTemps`/`eCoreTemps` arrays populated.
- `CpuGpuPill.qml`: amber warning color `#FFA000` applied to warning states, tiered temperature thresholds (65°C/80°C), and breathing pulse modulating opacity of `cpuCircProg`, `cpuText`, `tempText`, `gpuCircProg`, and `gpuText`.
- `CpuGpuPopup.qml`: columns widened to 320px, unified `[MHz] [Load %] [Temp °C]` header layout for Overall, P-Cores, and E-Cores, individual thread meters with per-core temperature readouts, redundant standalone rows removed, platform sensors restyled with crisp white and dynamic threshold alerts, and breathing pulse on critical metrics.
- `scripts/phase43-cpu-gpu-assert.sh`: updated for 320px width and amber warning color, all 5 sections passing with FAIL=0 FINDINGS=0.
- `./arch/dots-hyprland.sh verify --strict`: passes with 0 drift.
- Live Quickshell loaded and running cleanly via `qs -c ii -d`.
