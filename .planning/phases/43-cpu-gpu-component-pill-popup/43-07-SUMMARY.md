---
phase: 43-cpu-gpu-component-pill-popup
plan: "07"
subsystem: ui-bar-overlay
tags: [quickshell, popup, overlay, bar, telemetry, gap-closure, uat, optimization, gpu-clock, threadmeter, platform-sensors]
gap_closure: true
gap_ids:
  - G-43-5-2

requires:
  - phase: 43-06
    provides: "Gap closure 43-06 telemetry resource optimization, layout restructuring, amber warning & breathing pulse"
provides:
  - "Zero-animation static Rectangle progress bar (track and fill) in ThreadMeter eliminating 20 concurrent property animation loops and compositor redraw overhead"
  - "gt_cur_freq_mhz monitoring in HardwareTelemetry.qml providing stable GPU render clock operating frequency without dropping to 0 MHz during microsecond RC6 idle states"
  - "Removal of redundant interactive EPP button from CpuGpuPopup.qml"
  - "Reorganized 6 platform sensors into clean rows with labels on the left and °C temperatures on the right, matching CPU core typography (Appearance.font.pixelSize.smaller)"
  - "Dynamic warning and critical threshold colors retained across all 6 platform sensors"
affects:
  - 43-cpu-gpu-component-pill-popup

tech-stack:
  added: []
  patterns:
    - "Zero-animation static progress bar architecture for high-density repeaters"
    - "Dual-source sysfs frequency sampling (gt_act_freq_mhz with gt_cur_freq_mhz fallback)"
    - "Row-aligned platform sensor typography using Appearance.font.pixelSize.smaller"

key-files:
  created: []
  modified:
    - restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml
    - restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml
    - scripts/phase43-cpu-gpu-assert.sh

key-decisions:
  - "D-36: Replaced StyledProgressBar in ThreadMeter with static Item containing track and fill Rectangle, eliminating 20 concurrent Behavior on value animations and dropping Wayland GPU/CPU scene graph repaint overhead"
  - "D-37: Added fileGpuCurFreq FileView observing /sys/class/drm/card1/gt_cur_freq_mhz, falling back when gt_act_freq_mhz is 0 to ensure stable render clock reporting"
  - "D-38: Removed redundant interactive EPP power profile button from CpuGpuPopup.qml as requested by user"
  - "D-39: Replaced 2-column GridLayout for platform sensors with PlatformSensorRow single-column rows using Appearance.font.pixelSize.smaller and dynamic threshold colors"

requirements-completed:
  - CPUGPU-02
  - CPUGPU-03

coverage:
  - id: GAP-CLOSURE-43-07
    description: "Resolution of UAT gap G-43-5-2"
    requirement: CPUGPU-02, CPUGPU-03
    verification:
      - kind: other
        ref: "bash scripts/phase43-cpu-gpu-assert.sh && ./arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false

## Self-Check: PASSED
- `CpuGpuPopup.qml`: `ThreadMeter` uses lightweight static `Rectangle` progress bars without `Behavior on value` animations; redundant `eppButton` container removed; 6 platform sensors restructured into clean rows with `Appearance.font.pixelSize.smaller` and dynamic threshold colors.
- `HardwareTelemetry.qml`: `gpuCurFreqPath` and `fileGpuCurFreq` added to observe `/sys/class/drm/card1/gt_cur_freq_mhz`; `updateGpuMetrics()` falls back to `curFreq` when `actFreq` is 0 during microsecond RC6 idle states.
- `scripts/phase43-cpu-gpu-assert.sh`: updated to verify lightweight thread meters, absence of EPP button, platform sensor rows, and stable GPU frequency handling; all 5 sections pass cleanly with FAIL=0 FINDINGS=0.
- `./arch/dots-hyprland.sh verify --strict`: passes cleanly with FAIL=0 FINDINGS=0.
- Quickshell reloaded and running as a single daemon instance via `qs -d -c ii`.
