---
status: resolved
updated: "2026-10-01T17:30:00+06:00"
---

# Debug Session: Phase 43 Telemetry & UI Gaps (Cycle 3)

**Timestamp:** 2026-09-26T16:12:00+06:00
**Phase:** 43-cpu-gpu-component-pill-popup
**Status:** Diagnosed

## Symptom Overview
1. **G-43-5-2 (GPU Resource Overhead, Render Clock Jitter & Platform Sensor Hierarchy):**
   - **Resource Overhead:** User observed that opening the popup consumes 30-40% GPU processing, asking why Quickshell popup takes significant GPU resources.
   - **Render Clock Reading:** Render clock frequently displays 0 MHz or 15 MHz while GPU load is reported as 30-40%, leading to confusion on reading accuracy.
   - **EPP Button Redundancy:** User already has a dedicated power profile switcher and requests complete removal of the interactive EPP button.
   - **Platform Sensors Layout & Styling:** The 2-column, 3-row layout lacks consistency. Typography is too large compared to CPU cores; sensors should match CPU core small font size (`Appearance.font.pixelSize.smaller`) and follow standard row styling with sensor labels on the left and °C temperatures on the right.
   - **Scaling Governor Behavior:** User noted that changing power profiles does not change the scaling governor.

## Root Causes & Evidence

### 1. High GPU Resource Usage during Popup Active
- **Evidence:** `CpuGpuPopup.qml` instantiated 20 individual `StyledProgressBar` controls for thread meters (plus 4 metric progress bars). `StyledProgressBar.qml` contains an active `Behavior on value` that instantiates `Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)`. Every 1000ms, all 20 threads update, launching 20 concurrent QtQuick property animations that force continuous 60 FPS repaints across the Wayland scene graph.
- **Fix:** Replace heavy animated `StyledProgressBar` in the 20 `ThreadMeter` rows with a lightweight, zero-animation `Rectangle` fill bar (`width: parent.width * tMeter.load`), eliminating continuous frame redraws and reducing GPU/CPU compositor overhead.

### 2. GPU Render Clock Fluctuating to 0 MHz
- **Evidence:** Hardware telemetry currently reads `/sys/class/drm/card1/gt_act_freq_mhz`. On the Intel Xe/i915 driver for Intel UHD 770, `gt_act_freq_mhz` measures instantaneous hardware frequency, which drops to `0` whenever the execution units enter RC6 power-saving sleep (even for microseconds during poll). Conversely, `/sys/class/drm/card1/gt_cur_freq_mhz` (and `/sys/class/drm/card1/gt/gt0/rps_cur_freq_mhz`) correctly reports the active operating frequency (e.g. 1433 MHz).
- **Fix:** Update `HardwareTelemetry.qml` to read `gt_cur_freq_mhz` (or fallback to `gt_cur_freq_mhz` when `gt_act_freq_mhz` is 0) so the live render clock displays the actual operating frequency instead of dropping to 0 MHz.

### 3. Redundant EPP Switcher Button
- **Evidence:** `CpuGpuPopup.qml` lines 416-476 render an interactive `Rectangle { id: eppButton ... }` for cycling power profiles. The user already has a system power profile button and requested its complete removal.
- **Fix:** Remove the EPP button container from `CpuGpuPopup.qml`.

### 4. Platform Sensors Layout and Typography Mismatch
- **Evidence:** Platform sensors 1-6 in `CpuGpuPopup.qml` use a 2-column `GridLayout` with `Appearance.font.pixelSize.small`. The CPU core meters use `Appearance.font.pixelSize.smaller`. The layout has labels and temperatures together without consistent alignment.
- **Fix:** Reorganize the 6 platform sensors into clean rows matching the rest of the popup (`StyledPopupValueRow` or inline flex rows with label on left and °C on right) with `Appearance.font.pixelSize.smaller` and dynamic threshold colors.

### 5. Scaling Governor Permanence
- **Evidence:** System uses `intel_pstate` in active mode with `powersave` governor. On 13th Gen Intel CPUs, the scaling governor remains `powersave` while `powerprofilesctl` toggles `energy_performance_preference` (`epp`: `power`, `balance_performance`, `performance`). This is expected Linux kernel behavior.

## Resolution Plan
1. **`HardwareTelemetry.qml`:**
   - Update GPU frequency reader to check `/sys/class/drm/card1/gt_cur_freq_mhz` or fallback from `gt_act_freq_mhz` when 0.
2. **`CpuGpuPopup.qml`:**
   - Optimize `ThreadMeter` progress bar to use a lightweight static `Rectangle` without `Behavior on value` animations.
   - Remove interactive EPP button completely.
   - Restructure 6 platform sensors to single column / clean rows with label on left and °C on right, using `Appearance.font.pixelSize.smaller` and threshold colors.
3. Verify Quickshell reload and test assertions.
