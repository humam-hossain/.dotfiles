# Debug Session: CPU/GPU Telemetry Polling, Layout, and Core/Platform Detail Gaps

**Date:** 2026-09-26
**Phase:** 43-cpu-gpu-component-pill-popup
**Status:** Diagnosed

## Symptoms
1. **0°C Package Temp, 0% GPU Load, 0 MHz CPU Frequencies:**
   - Pill and popup showed 0°C temperature, 0 MHz clock speeds, and 0% GPU load despite live load existing.
2. **Missing Popup Padding:**
   - Top and left edges of the popup window have no padding; content is flush against the border.
3. **Core Segregation Detail Missing:**
   - User requested individual listings for all P-core threads (C0-C11) and E-core threads (C12-C19) with MHz and load bars, plus P-core / E-core average temperatures.
4. **Motherboard Telemetry Incomplete:**
   - Only 1 VRM sensor was targeted instead of all 6 sensors reported by `gigabyte_wmi` in `sensors`, and average platform temperature was missing.
5. **EPP Profile & Interaction:**
   - EPP reported `balance_performance` instead of the active `power-saver` state (`power` in sysfs); user requested the ability to interactively toggle/control EPP/power profile.
6. **Pill Visual Enhancements:**
   - GPU icon requested to be changed to `'sports_esports'`.
   - Circular progress percentage rings requested around CPU and GPU icons in the top bar pill (matching legacy `Resources.qml`).

## Root Cause Analysis
1. **JavaScript TypeError `matchAll is not a function` in `HardwareTelemetry.qml`:**
   - Line 216: `const matches = [...text.matchAll(/cpu MHz\s*:\s*([0-9.]+)/g)];`
   - Qt's QML JS engine does not support `String.prototype.matchAll()`. On every timer tick, `updateFrequencies()` threw an unhandled TypeError.
   - Because `pollAll()` calls `updateCpuLoad -> updateFrequencies -> updateGovernors -> updateGpuMetrics -> updateThermals`, the exception halted execution. Consequently, `updateGovernors()`, `updateGpuMetrics()`, and `updateThermals()` never ran.
2. **Layout Padding Asymmetry in `CpuGpuPopup.qml`:**
   - The outer container margins or layout padding lacked explicit top/left padding, causing child columns to touch the top-left boundary.
3. **Single Aggregation vs Detailed Core List in `CpuGpuPopup.qml`:**
   - The UI displayed aggregate P-core and E-core progress bars instead of iterating through `perThreadLoads` (0-11 and 12-19) with per-thread MHz.
4. **Platform Sensor Coverage in `HardwareTelemetry.qml`:**
   - Only `temp1_input` was bound to `vrmTemp`. The other 5 sensors (`temp2_input` through `temp6_input`) from `gigabyte_wmi` were not bound.
5. **Interactive EPP Switching:**
   - EPP was rendered as static text. Changing power profile requires running `powerprofilesctl set` or invoking DBus `net.hadess.PowerProfiles`.

## Remediation Plan
1. **Fix `HardwareTelemetry.qml`:**
   - Replace `matchAll` with a regex `while ((match = regex.exec(text)) !== null)` loop.
   - Bind all 6 `temp[1-6]_input` sensors for `gigabyte_wmi` and expose `platformTemps` array + `platformTempAvg`.
   - Compute P-core average temp and E-core average temp from `coretemp` sensor inputs.
   - Ensure `energyPerformancePreference` accurately syncs with `/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference`.
2. **Update `CpuGpuPill.qml`:**
   - Change GPU icon to `'sports_esports'`.
   - Add circular progress indicator rings (progress arcs) around CPU and GPU icons.
3. **Update `CpuGpuPopup.qml`:**
   - Fix container padding on top and left.
   - Expand P-core section to show individual core threads (0-11) with MHz and load bars, plus P-core average temperature.
   - Expand E-core section to show individual core threads (12-19) with MHz and load bars, plus E-core average temperature.
   - Expand Motherboard section to display all 6 platform temperatures and platform average.
   - Add interactive click/action on EPP to switch power profiles via `powerprofilesctl`.
