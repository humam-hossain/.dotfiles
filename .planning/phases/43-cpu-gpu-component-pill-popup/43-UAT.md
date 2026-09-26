---
status: diagnosed
phase: 43-cpu-gpu-component-pill-popup
source:
  - 43-01-SUMMARY.md
  - 43-02-SUMMARY.md
  - 43-03-SUMMARY.md
  - 43-04-SUMMARY.md
started: 2026-09-26T09:43:00+06:00
updated: 2026-09-26T10:50:00+06:00
---

## Current Test

[testing complete]

## Tests

### 1. Top Bar CPU/GPU Pill Readout
expected: The top status bar pill displays live CPU load % and package temp °C alongside Intel UHD 770 GPU load % with distinct Material Symbols icons ('planner_review' for CPU, 'speed' for GPU).
result: issue
reported: "ok we have some issues so now it is showing first a CPU icon then the percentage of the load and then the temperature in Celsius and then the GPU icon, I don't like the GPU icon so it has to change then the percentage of the GPU load but the problem is the CPU percentage is working I checked with vtop, it is matching with it but the temperature is showing 0 degree Celsius which should be 33-34 degree Celsius and the next thing is the GPU percentage load percentage is not accurate either it is showing, it is currently 30-40 around 30-40% load but it is showing 0% load, so that is the issue"
severity: major

### 2. Popup Hover Transit & Grace Bridge
expected: Hovering over the CPU/GPU pill triggers the inspector popup. Moving the mouse pointer across the gap between the pill and the popup window stays open smoothly without flickering or abrupt closing (200ms debounce bridge).
result: pass

### 3. Screen Clamping & Entrance Animation
expected: The popup smoothly slides down and fades in (150ms M3 entrance transition) and is clamped within the visible screen boundaries with gap offsets, never overflowing off-screen.
result: pass

### 4. CPU Inspector & Segregated Core Meters
expected: The left column of the popup displays overall CPU load, package temperature, scaling governor, unprivileged power fallback ('N/A (unprivileged)'), and segregated progress meters for 12 P-core threads and 8 E-core threads with active MHz clock speeds.
result: issue
reported: "popup missing top/left padding; 0 MHz clock speeds; package temp 0°C; requested individual core listings under P-cores and E-cores with per-core MHz/load and P/E average temps; GPU icon change to 'sports_esports'"
severity: major

### 5. GPU & Motherboard Platform Telemetry
expected: The right column displays Intel UHD 770 GPU load %, render clock MHz, thermal throttle badge ('Normal' or 'Throttling'), Gigabyte B760 VRM temperature, and Energy Performance Preference (EPP).
result: issue
reported: "ok so lets the right section the right section has the issue of IGPU load is 0% it should be around 30 to 35% right render clock 0Mhz showing 0Mhz thermal throttle normal platform ok then makes the platform be 760 vrm temperature 0C not showing full I think when I give you the like the chart right of the board temperatures lets if I look at sensors yeah like there should be 6 temperature yes you should show me the average platform temperature also the 6 all 6 temperature that should be there ok then next EPP balance performance ok can I change the balance performance thing I don't know like the governor is power save but EPP is balance performance why it is not like power save like when I'm using power profiles it is set to power save mode I think yes so it's not changing it to like EPP can I control it can I not control it let me know"
severity: major

### 6. Alert Thresholds & Critical Breathing Pulse
expected: Under normal load, pill text/icons resolve to standard layer colors. Elevated loads/thermals tint amber (70%/75°C warning) or red (90%/85°C critical) using Material You dynamic color tokens. Under critical red, a breathing pulse animation gently modulates icon opacity and resets to 1.0 when load normalizes.
result: pass

## Summary

total: 6
passed: 3
issues: 3
pending: 0
skipped: 0

## Gaps

- gap_id: G-43-1
  truth: "The top status bar pill displays live CPU load % and package temp °C alongside Intel UHD 770 GPU load % with distinct Material Symbols icons ('planner_review' for CPU, 'speed' for GPU)."
  status: failed
  reason: "User reported: CPU package temp reads 0°C instead of ~34°C; GPU load reads 0% instead of active 30-40%; change GPU icon to 'sports_esports'; add circular progress percentage rings around CPU and GPU icons matching legacy Resources style"
  severity: major
  test: 1
  root_cause: "TypeError matchAll in HardwareTelemetry.qml halts pollAll() before updateGpuMetrics() and updateThermals() execute; CpuGpuPill lacks circular progress arcs and uses 'speed' icon instead of 'sports_esports'"
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml"
      issue: "matchAll is not supported in QML JS engine, throwing TypeError and aborting polling loop"
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPill.qml"
      issue: "Uses 'speed' icon; lacks circular progress rings around icons"
  missing:
    - "Replace matchAll with standard regex loop in HardwareTelemetry.qml"
    - "Change GPU icon in CpuGpuPill.qml to 'sports_esports'"
    - "Add circular progress percentage indicators around CPU and GPU icons in CpuGpuPill.qml"
  debug_session: .planning/debug/cpu-gpu-telemetry-and-ui-gaps.md

- gap_id: G-43-4
  truth: "The left column of the popup displays overall CPU load, package temperature, scaling governor, unprivileged power fallback ('N/A (unprivileged)'), and segregated progress meters for 12 P-core threads and 8 E-core threads with active MHz clock speeds."
  status: failed
  reason: "User reported: popup container missing top and left padding; 0 MHz clock speeds (TypeError matchAll in HardwareTelemetry); package temp 0°C; requested individual core listings under P-cores and E-cores with per-core MHz/load and P/E average temps; GPU icon change to 'sports_esports'"
  severity: major
  test: 4
  root_cause: "CpuGpuPopup layout lacks top/left padding; frequencies empty due to matchAll error; core meters only aggregated rather than detailing all 12 P-core threads and 8 E-core threads with live MHz and P/E average temperatures"
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml"
      issue: "Missing top/left padding; lacks detailed list of all 20 individual core threads and P/E average temps"
    - path: "restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml"
      issue: "Does not expose P-core and E-core average temperatures"
  missing:
    - "Add symmetric padding to CpuGpuPopup container"
    - "Render individual core meters for 12 P-core threads and 8 E-core threads with MHz readout"
    - "Compute and display average P-core and E-core temperatures"
  debug_session: .planning/debug/cpu-gpu-telemetry-and-ui-gaps.md

- gap_id: G-43-5
  truth: "The right column displays Intel UHD 770 GPU load %, render clock MHz, thermal throttle badge ('Normal' or 'Throttling'), Gigabyte B760 VRM temperature, and Energy Performance Preference (EPP)."
  status: failed
  reason: "User reported: iGPU load 0% (expected 30-35%); render clock 0 MHz; platform VRM temp 0°C; requested average platform temp and all 6 platform temps from gigabyte_wmi sensors; EPP showed balance_performance instead of active power-saver (sysfs 'power'); requested interactive EPP switching"
  severity: major
  test: 5
  root_cause: "updateGpuMetrics and updateGovernors blocked by matchAll error; HardwareTelemetry only binds 1 VRM sensor instead of all 6 gigabyte_wmi sensors; EPP is static readout without interactive switching via powerprofilesctl"
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/services/HardwareTelemetry.qml"
      issue: "Only reads temp1_input for VRM; misses temp2-temp6 inputs from gigabyte_wmi"
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/CpuGpuPopup.qml"
      issue: "Lacks readout for all 6 platform sensors + average platform temp; EPP is not interactive"
  missing:
    - "Bind all 6 gigabyte_wmi sensors and expose platformTemps + platformTempAvg in HardwareTelemetry.qml"
    - "Display all 6 platform sensors and average temp in CpuGpuPopup.qml"
    - "Add interactive power-profile switcher to toggle EPP / powerprofilesctl"
  debug_session: .planning/debug/cpu-gpu-telemetry-and-ui-gaps.md
