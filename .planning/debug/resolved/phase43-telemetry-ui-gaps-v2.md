---
status: resolved
updated: "2026-10-01T17:30:00+06:00"
---

# Debug Session: Phase 43 Telemetry & UI Gaps (Cycle 2)

**Timestamp:** 2026-09-26T13:22:00+06:00
**Phase:** 43-cpu-gpu-component-pill-popup
**Status:** Diagnosed

## Symptom Overview
1. **G-43-1 (Pill Colors & Breathing Animation):**
   - User reported GPU meter turned sky blue at 76% load instead of warning/critical palette color.
   - Breathing pulse was not noticeably active when load spiked.
   - Package temperature did not change color with elevated thermals.
2. **G-43-4 (CPU Inspector Layout, Hierarchy & Polling Overhead):**
   - Text "P-Core / E-Core Avg" and values overlapped due to constrained 230px column width.
   - Redundant rows for "Package Temp" and "P-Core / E-Core Avg".
   - Need unified inline format `[MHz] [Load %] [Temp °C]` followed by bar across overall CPU, P-cores, E-cores, and individual threads.
   - Need dynamic warning/critical threshold colors on temperatures and percentages.
   - Quickshell telemetry causes unnecessary resource overhead (GPU reported 70-80% on bar vs 33-34% in btop, and CPU spiking to 5% when popup is open).
3. **G-43-5 (GPU Telemetry Discrepancy & Motherboard Sensors Styling):**
   - Unhovered GPU load spikes to 70-80% on the bar pill and drops to 30-37% when popup opens.
   - Platform sensors 1-6 are displayed in small font with muted gray color (`colSubtext`) without visual impact.
   - VRM and platform sensors lack dynamic warning/critical threshold coloring.
4. **G-43-6 (Breathing Pulse Motion Extensibility):**
   - Icon breathing pulse is too subtle within the circular progress ring.
   - Pill text (percentage and temperature) does not pulse when critical.
   - Popup elements have no breathing pulse effect when in critical state.

## Root Causes & Evidence

### Gap 1 (G-43-1): Color Token Mismatch & Inactive Thresholds
- **Evidence:** `CpuGpuPill.qml` lines 30-32 set `cpuWarning ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer1`. In the user's active Material You palette generated from wallpaper, `colTertiary` resolves to sky blue/cyan. The standard dots-hyprland warning color is amber (`#FFA000` / warning token), while critical is `colError` (red).
- **Thresholds:** Warning threshold for temperature is hardcoded at 75°C and critical at 85°C, meaning normal and moderately elevated operating temperatures (35°C–70°C) show no color change.
- **Pulse Target:** The `SequentialAnimation` only targeted `cpuIcon` and `gpuIcon` with `to: 0.6`, which is rendered inside `ClippedFilledCircularProgress` and barely visible.

### Gap 2 (G-43-4): Constrained Column Width, Redundant Rows, & Background Polling Churn
- **Evidence (Layout):** `ColumnLayout` in `CpuGpuPopup.qml` has `Layout.preferredWidth: 230`. `StyledPopupValueRow` displays "P-Core / E-Core Avg:" (18 chars) and "32°C / 34°C" (10 chars), causing text bounding boxes to collide and wrap/overlap.
- **Evidence (Information Architecture):** Redundant standalone rows consume vertical space while users want inline compact metrics `[MHz] [Load %] [Temp °C]` followed by progress bars for Overall CPU, P-Cores, and E-Cores.
- **Evidence (Telemetry Overhead):** `HardwareTelemetry.qml` sets `fastPolling: fastPollingRequests > 0 || overallCpuLoad > 0.15 || gpuLoad > 0.15`. Because `gpuLoad` is ~0.30, `fastPolling` is permanently active (1000ms interval). Every 1000ms, `pollAll()` executes `Process { command: ["powerprofilesctl", "get"] }`, re-reads and regexes `/proc/cpuinfo`, and re-reads 22 sysfs files even when the popup is closed. When the popup opens, rendering 20 live thread rows exacerbates CPU consumption to 5%.

### Gap 3 (G-43-5): RC6 Residency Jitter & Platform Sensor Typography
- **Evidence (GPU Jitter):** RC6 residency delta in `updateGpuMetrics()` evaluates `(1.0 - (dRc6 / dt))` without smoothing or filtering against timing jitter between timer intervals.
- **Evidence (Typography & Styling):** Platform sensors in `CpuGpuPopup.qml` use `font.pixelSize: Appearance.font.pixelSize.smaller` and `color: Appearance.colors.colSubtext` (gray). They should match the core font sizes (`Appearance.font.pixelSize.small`), use crisp white (`Appearance.colors.colOnLayer1`), and include temperature threshold coloring.

### Gap 4 (G-43-6): Pulse Scope Limitation
- **Evidence:** Pulse animations exist only on `cpuIcon` and `gpuIcon` inside `CpuGpuPill.qml`. Neither `cpuText`, `tempText`, `gpuText`, nor any meter in `CpuGpuPopup.qml` are bound to opacity pulse animations during critical state.

## Resolution Plan
1. **`HardwareTelemetry.qml`:**
   - Decouple background polling: When popup is closed (`fastPollingRequests === 0`), do not fork `powerprofilesctl get` or re-parse `/proc/cpuinfo` every second.
   - Smooth GPU load calculation with an exponential moving average or low-pass filter to prevent RC6 sampling jitter.
   - Expose individual core temperatures for P-cores and E-cores to allow thread/core temperature rendering.
2. **`CpuGpuPill.qml`:**
   - Map warning color to `#FFA000` (amber/warning token) and critical to `Appearance.colors.colError` (red).
   - Adjust temperature alert thresholds (e.g. Warning >= 65°C, Critical >= 80°C, or tiered).
   - Extend breathing pulse animation to modulate opacity of both the icon/circular ring and the text labels (`cpuText`, `tempText`, `gpuText`).
3. **`CpuGpuPopup.qml`:**
   - Widen popup columns from 230px to 300–320px.
   - Unify layout into `[MHz] [Load %] [Temp °C]` followed by progress bar across Overall CPU, P-Core group & threads, and E-Core group & threads.
   - Remove redundant standalone "Package Temp" and "P-Core / E-Core Avg" rows.
   - Restyle 6 platform sensors with larger typography, crisp white/on-layer text, and threshold colors.
   - Add breathing pulse animation to critical metrics in the popup.
