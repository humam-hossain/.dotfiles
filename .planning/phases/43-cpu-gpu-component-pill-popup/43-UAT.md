---
status: diagnosed
phase: 43-cpu-gpu-component-pill-popup
source:
  - 43-01-SUMMARY.md
  - 43-02-SUMMARY.md
  - 43-03-SUMMARY.md
started: 2026-09-26T09:08:15+06:00
updated: 2026-09-26T09:19:00+06:00
---

## Current Test

[testing complete]

## Tests

### 1. Top Bar CPU/GPU Pill Readout
expected: The top status bar pill displays live CPU load % and package temp °C alongside Intel UHD 770 GPU load % with distinct Material Symbols icons ('planner_review' for CPU, 'speed' for GPU).
result: issue
reported: "no they don't. that's the issue, it remains the same as before this phase"
severity: major

### 2. Popup Hover Transit & Grace Bridge
expected: Hovering over the CPU/GPU pill triggers the inspector popup. Moving the mouse pointer across the gap between the pill and the popup window stays open smoothly without flickering or abrupt closing (200ms debounce bridge).
result: issue
reported: "no popup shows up on hover other than media. like datetime, weather they also don't show popup and the memory cpu single component from before also don't show popup"
severity: major

### 3. Screen Clamping & Entrance Animation
expected: The popup smoothly slides down and fades in (150ms M3 entrance transition) and is clamped within the visible screen boundaries with gap offsets, never overflowing off-screen.
result: issue
reported: "well the popup does not showing up so there is no ay to know"
severity: major

### 4. CPU Inspector & Segregated Core Meters
expected: The left column of the popup displays overall CPU load, package temperature, scaling governor, unprivileged power fallback ('N/A (unprivileged)'), and segregated progress meters for 12 P-core threads and 8 E-core threads with active MHz clock speeds.
result: issue
reported: "same there is no way i can know as it does not exists yet"
severity: major

### 5. GPU & Motherboard Platform Telemetry
expected: The right column displays Intel UHD 770 GPU load %, render clock MHz, thermal throttle badge ('Normal' or 'Throttling'), Gigabyte B760 VRM temperature, and Energy Performance Preference (EPP).
result: issue
reported: "same question i told you these verification all should fail as the popup does not show up"
severity: major

### 6. Alert Thresholds & Critical Breathing Pulse
expected: Under normal load, pill text/icons resolve to standard layer colors. Elevated loads/thermals tint amber (70%/75°C warning) or red (90%/85°C critical) using Material You dynamic color tokens. Under critical red, a breathing pulse animation gently modulates icon opacity and resets to 1.0 when load normalizes.
result: issue
reported: "don't work"
severity: major

## Summary

total: 6
passed: 0
issues: 6
pending: 0
skipped: 0

## Gaps

- gap_id: G-43-1
  truth: "The top status bar pill displays live CPU load % and package temp °C alongside Intel UHD 770 GPU load % with distinct Material Symbols icons ('planner_review' for CPU, 'speed' for GPU)."
  status: failed
  reason: "User reported: no they don't. that's the issue, it remains the same as before this phase"
  severity: major
  test: 1
  root_cause: "CpuGpuPill and CpuGpuPopup are not instantiated in BarContent.qml; BarContent still hosts legacy Resources.qml"
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
      issue: "Hosts legacy Resources.qml instead of CpuGpuPill; does not instantiate CpuGpuPopup"
  missing:
    - "Mount CpuGpuPill in BarContent.qml with useShortenedForm binding"
    - "Instantiate CpuGpuPopup and anchor to CpuGpuPill hoverArea"
  debug_session: ".planning/debug/cpu-gpu-pill-popup-not-rendered.md"

- gap_id: G-43-2
  truth: "Hovering over the CPU/GPU pill triggers the inspector popup. Moving the mouse pointer across the gap between the pill and the popup window stays open smoothly without flickering or abrupt closing (200ms debounce bridge)."
  status: failed
  reason: "User reported: no popup shows up on hover other than media. like datetime, weather they also don't show popup and the memory cpu single component from before also don't show popup"
  severity: major
  test: 2
  root_cause: "CpuGpuPill and CpuGpuPopup are not instantiated in BarContent.qml; BarContent still hosts legacy Resources.qml"
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
      issue: "Hosts legacy Resources.qml instead of CpuGpuPill; does not instantiate CpuGpuPopup"
  missing:
    - "Mount CpuGpuPill in BarContent.qml with useShortenedForm binding"
    - "Instantiate CpuGpuPopup and anchor to CpuGpuPill hoverArea"
  debug_session: ".planning/debug/cpu-gpu-pill-popup-not-rendered.md"

- gap_id: G-43-3
  truth: "The popup smoothly slides down and fades in (150ms M3 entrance transition) and is clamped within the visible screen boundaries with gap offsets, never overflowing off-screen."
  status: failed
  reason: "User reported: well the popup does not showing up so there is no ay to know"
  severity: major
  test: 3
  root_cause: "CpuGpuPill and CpuGpuPopup are not instantiated in BarContent.qml; BarContent still hosts legacy Resources.qml"
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
      issue: "Hosts legacy Resources.qml instead of CpuGpuPill; does not instantiate CpuGpuPopup"
  missing:
    - "Mount CpuGpuPill in BarContent.qml with useShortenedForm binding"
    - "Instantiate CpuGpuPopup and anchor to CpuGpuPill hoverArea"
  debug_session: ".planning/debug/cpu-gpu-pill-popup-not-rendered.md"

- gap_id: G-43-4
  truth: "The left column of the popup displays overall CPU load, package temperature, scaling governor, unprivileged power fallback ('N/A (unprivileged)'), and segregated progress meters for 12 P-core threads and 8 E-core threads with active MHz clock speeds."
  status: failed
  reason: "User reported: same there is no way i can know as it does not exists yet"
  severity: major
  test: 4
  root_cause: "CpuGpuPill and CpuGpuPopup are not instantiated in BarContent.qml; BarContent still hosts legacy Resources.qml"
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
      issue: "Hosts legacy Resources.qml instead of CpuGpuPill; does not instantiate CpuGpuPopup"
  missing:
    - "Mount CpuGpuPill in BarContent.qml with useShortenedForm binding"
    - "Instantiate CpuGpuPopup and anchor to CpuGpuPill hoverArea"
  debug_session: ".planning/debug/cpu-gpu-pill-popup-not-rendered.md"

- gap_id: G-43-5
  truth: "The right column displays Intel UHD 770 GPU load %, render clock MHz, thermal throttle badge ('Normal' or 'Throttling'), Gigabyte B760 VRM temperature, and Energy Performance Preference (EPP)."
  status: failed
  reason: "User reported: same question i told you these verification all should fail as the popup does not show up"
  severity: major
  test: 5
  root_cause: "CpuGpuPill and CpuGpuPopup are not instantiated in BarContent.qml; BarContent still hosts legacy Resources.qml"
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
      issue: "Hosts legacy Resources.qml instead of CpuGpuPill; does not instantiate CpuGpuPopup"
  missing:
    - "Mount CpuGpuPill in BarContent.qml with useShortenedForm binding"
    - "Instantiate CpuGpuPopup and anchor to CpuGpuPill hoverArea"
  debug_session: ".planning/debug/cpu-gpu-pill-popup-not-rendered.md"

- gap_id: G-43-6
  truth: "Under normal load, pill text/icons resolve to standard layer colors. Elevated loads/thermals tint amber (70%/75°C warning) or red (90%/85°C critical) using Material You dynamic color tokens. Under critical red, a breathing pulse animation gently modulates icon opacity and resets to 1.0 when load normalizes."
  status: failed
  reason: "User reported: don't work"
  severity: major
  test: 6
  root_cause: "CpuGpuPill and CpuGpuPopup are not instantiated in BarContent.qml; BarContent still hosts legacy Resources.qml"
  artifacts:
    - path: "restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
      issue: "Hosts legacy Resources.qml instead of CpuGpuPill; does not instantiate CpuGpuPopup"
  missing:
    - "Mount CpuGpuPill in BarContent.qml with useShortenedForm binding"
    - "Instantiate CpuGpuPopup and anchor to CpuGpuPill hoverArea"
  debug_session: ".planning/debug/cpu-gpu-pill-popup-not-rendered.md"
