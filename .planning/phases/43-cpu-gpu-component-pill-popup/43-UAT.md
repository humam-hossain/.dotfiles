---
status: diagnosed
phase: 43-cpu-gpu-component-pill-popup
source:
  - 43-01-SUMMARY.md
  - 43-02-SUMMARY.md
  - 43-03-SUMMARY.md
  - 43-04-SUMMARY.md
  - 43-05-SUMMARY.md
started: 2026-09-26T12:24:00+06:00
updated: 2026-09-26T13:22:30+06:00
---

## Current Test

[testing complete]

## Tests

### 1. Top Bar CPU/GPU Pill Readout & Circular Meters
expected: The top status bar pill displays live CPU load % and package temp °C alongside Intel UHD 770 GPU load % with distinct Material Symbols icons ('planner_review' for CPU, 'sports_esports' for GPU). Both icons are framed by circular progress percentage indicator rings (ClippedFilledCircularProgress) matching legacy styling. Values are non-zero (temp ~30-40°C, GPU load matches activity).
result: issue
reported: "yeah everything is showing fine but I think for the the pulsing motion it is not present when the when the load spikes it's not present when CPU load is high or the GPU load is high I think it's not it's not also the temperature does not change like it doesn't change color I think it should have some more thresholds and like that like to like throw so it needs also thresholds for coloring and also yes the the GPU has like a sky blue type of color when it is like 76% I don't know why that is the case it shouldn't be it should be the like the warning color the red color something like that like the dots hyperlend the color from the palette of the color the warning or critical those kind of colors should be"
severity: major

### 2. Popup Hover Transit & Grace Bridge
expected: Hovering over the CPU/GPU pill triggers the inspector popup. Moving the mouse pointer across the gap between the pill and the popup window stays open smoothly without flickering or abrupt closing (200ms debounce bridge).
result: pass

### 3. Screen Clamping & Entrance Animation
expected: The popup smoothly slides down and fades in (150ms M3 entrance transition) and is clamped within the visible screen boundaries with gap offsets, never overflowing off-screen.
result: pass

### 4. CPU Inspector: P/E Core Breakdown & Temperatures
expected: The left column of the popup displays symmetric padding around content, overall CPU load %, package temp °C, P-core and E-core average temperatures, scaling governor, unprivileged power fallback ('N/A (unprivileged)'), and segregated progress meters listing all 12 individual P-core threads (C0-C11) and 8 individual E-core threads (C12-C19) with active MHz clock speeds and thread load.
result: issue
reported: "P-core/E-core average temperature text is overlapping due to width; remove redundant standalone package temp and P/E average rows; reorganize hierarchy into [MHz] [Load %] [Temp °C] across overall CPU, P-cores, E-cores and individual threads; widen popup; ensure warning/critical colors are applied to temperatures and percentages; investigate resource overhead (GPU showing 70-80% on bar vs 33-34% in btop, and CPU spiking to 5% when popup is open)"
severity: major

### 5. GPU Inspector, 6 Motherboard Sensors & Power Profile Switcher
expected: The right column displays Intel UHD 770 GPU load %, render clock MHz, thermal throttle badge ('Normal' or 'Throttling'), all 6 Gigabyte B760 platform sensor temperatures plus average platform temperature, and an interactive power profile switcher button that cycles through power-saver, balanced, and performance profiles via powerprofilesctl.
result: issue
reported: "GPU unhovered spikes to 70-80% on pill but drops to 30-37% (matching btop) when popup opens; all temperatures/sensors need unified warning/critical threshold colors; platform 6 sensors font is too small and style is not eye-catching; replace muted gray text color with crisp white/on-layer color"
severity: major

### 6. Alert Thresholds & Critical Breathing Pulse
expected: Under normal load, pill text/icons resolve to standard layer colors. Elevated loads/thermals tint amber (70%/75°C warning) or red (90%/85°C critical) using Material You dynamic color tokens. Under critical red, a breathing pulse animation gently modulates icon opacity and resets to 1.0 when load normalizes.
result: issue
reported: "Icon breathing pulse is too subtle because it is inside the circle ring; text (percentage, temperature) and GPU in pill also need to pulse when critical; and critical elements inside the popup should also have the consistent breathing pulse effect"
severity: minor

## Summary

total: 6
passed: 2
issues: 4
pending: 0
skipped: 0

## Gaps

- gap_id: G-43-1
  truth: "The top status bar pill displays live CPU load % and package temp °C alongside Intel UHD 770 GPU load % with distinct Material Symbols icons ('planner_review' for CPU, 'sports_esports' for GPU). Both icons are framed by circular progress percentage indicator rings (ClippedFilledCircularProgress) matching legacy styling. Values are non-zero (temp ~30-40°C, GPU load matches activity)."
  status: failed
  reason: "User reported: pulsing motion not working when CPU/GPU load is high; temperature does not change color with thresholds; GPU circular meter or text has sky blue color at 76% instead of dots-hyprland warning/critical palette color"
  severity: major
  test: 1
  root_cause: "Warning color mapped to Appearance.colors.colTertiary which resolves to sky blue in user's dynamic palette instead of amber/warning; temperature thresholds (75°C/85°C) are too high for normal/moderate operating range; breathing pulse was restricted to icons only and not running at 70-80% loads."
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml"
      issue: "Uses colTertiary for warning instead of amber/warning token; pulse only animates inner icon"
  missing:
    - "Map warning color state to #FFA000 / warning color token and critical to colError"
    - "Add responsive multi-tier temperature color thresholds"
    - "Extend pulse animation to pill labels and circular progress indicators"
  debug_session: .planning/debug/phase43-telemetry-ui-gaps-v2.md

- gap_id: G-43-4
  truth: "The left column of the popup displays overall CPU load %, package temp °C, P-core and E-core average temperatures, scaling governor, unprivileged power fallback ('N/A (unprivileged)'), and segregated progress meters listing all 12 individual P-core threads (C0-C11) and 8 individual E-core threads (C12-C19) with active MHz clock speeds and thread load."
  status: failed
  reason: "User reported: 1) Overlap in P-core/E-core average temperature text due to constrained column width; widen popup container. 2) Eliminate redundant standalone Package Temp and P/E Avg lines. 3) Unify format to [MHz] [Load %] [Temp °C] followed by bar across overall CPU, P-core group & individual threads, and E-core group & individual threads. 4) Apply dynamic threshold colors (warning/critical) to temperatures and percentages. 5) Investigate resource overhead (GPU showing 70-80% on bar vs 33-34% in btop, CPU spiking to 5% when popup opens)."
  severity: major
  test: 4
  root_cause: "Popup column width fixed at 230px causes text overlap on long labels; layout has separate redundant rows instead of inline [MHz] [Load %] [Temp °C]; background fastPolling runs at 1000ms permanently due to gpuLoad > 0.15 forking powerprofilesctl and parsing /proc/cpuinfo every second."
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml"
      issue: "Constrained 230px column width; redundant temperature rows; missing unified inline format"
    - path: "restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml"
      issue: "Permanent fastPolling and continuous Process forks for powerprofilesctl creating CPU/GPU overhead"
  missing:
    - "Widen popup column width to 300-320px for comfortable label breathing room"
    - "Restructure CPU column into unified inline [MHz] [Load %] [Temp °C] followed by bar across overall, P-cores, E-cores, and threads"
    - "Remove standalone Package Temp and P/E Avg rows"
    - "Gate heavy frequency and process polling strictly to when popup is open or relaxed cadence"
  debug_session: .planning/debug/phase43-telemetry-ui-gaps-v2.md

- gap_id: G-43-5
  truth: "The right column displays Intel UHD 770 GPU load %, render clock MHz, thermal throttle badge ('Normal' or 'Throttling'), all 6 Gigabyte B760 platform sensor temperatures plus average platform temperature, and an interactive power profile switcher button that cycles through power-saver, balanced, and performance profiles via powerprofilesctl."
  status: failed
  reason: "User reported: 1) GPU load calculation discrepancy (spikes to 70-80% on pill when unhovered, normalizes to 30-37% when hovered/opened). 2) All temperatures and platform sensors need unified threshold coloring (warning and critical colors from palette). 3) Platform sensors font size too small and styling lacks visual appeal; increase size to match CPU cores and modernize layout. 4) Avoid muted gray text, use crisp white/colOnLayer1 colors."
  severity: major
  test: 5
  root_cause: "Raw RC6 residency delta suffers from timer jitter without smoothing filter; platform sensors rendered with smaller font in muted colSubtext gray without threshold colors."
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml"
      issue: "GPU load lacks moving average/smoothing on RC6 delta"
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml"
      issue: "Small font size and muted gray styling on platform sensors; missing dynamic threshold coloring"
  missing:
    - "Add smoothing/moving average filter to RC6 residency delta calculation"
    - "Enlarge platform sensor typography to match CPU core meters"
    - "Replace muted gray text with crisp white/colOnLayer1 text"
    - "Apply unified warning and critical threshold colors across all 6 platform sensors"
  debug_session: .planning/debug/phase43-telemetry-ui-gaps-v2.md

- gap_id: G-43-6
  truth: "Under normal load, pill text/icons resolve to standard layer colors. Elevated loads/thermals tint amber (70%/75°C warning) or red (90%/85°C critical) using Material You dynamic color tokens. Under critical red, a breathing pulse animation gently modulates icon opacity and resets to 1.0 when load normalizes."
  status: failed
  reason: "User reported: Icon breathing pulse is too subtle within circle ring; animate text (percentage, temperature) and GPU in pill with breathing pulse when critical; extend breathing pulse effect to critical elements inside the popup"
  severity: minor
  test: 6
  root_cause: "Breathing pulse animation in CpuGpuPill.qml only bound to cpuIcon and gpuIcon opacity (0.6); text and circular progress rings do not pulse; no breathing animation exists in CpuGpuPopup.qml for critical metrics."
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml"
      issue: "Pulse restricted to inner icon with subtle opacity change"
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml"
      issue: "Lacks breathing pulse animation for critical metrics"
  missing:
    - "Modulate opacity of pill text labels and circular meters during critical state"
    - "Add breathing pulse animation to critical metrics in CpuGpuPopup.qml"
  debug_session: .planning/debug/phase43-telemetry-ui-gaps-v2.md
