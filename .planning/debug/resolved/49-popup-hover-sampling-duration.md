---
status: resolved
updated: "2026-10-01T17:30:00+06:00"
---

# Debug Session: Interactive Popup Hover Duration & Telemetry Stabilization

**Status:** Diagnosed
**Date:** 2026-09-30
**Component:** `scripts/profile-quickshell.sh`

## Symptoms
- User reports: "it has to take some time to record real changes, keep mouse hover for sometime"
- Popup telemetry sampling may prematurely capture transient open animations rather than steady-state component workload if warmup or sampling duration is too brief (e.g. under `--quick` or insufficient stabilization delay).

## Root Cause
In `scripts/profile-quickshell.sh`:
1. `navigate_and_sample_popup` moves the cursor once to the pill coordinates via `ydotool mousemove -a -x $tx -y $ty` and sleeps for 0.5s before calling `run_sample_window`.
2. Under quick profiling mode (`--quick`), `WARMUP_SEC=2` and `DURATION_SEC=5`.
3. In Wayland/Hyprland environments, complex popups (e.g., `popup_weather` requesting network weather JSON, `popup_cpugpu` loading multi-core thread telemetry, `popup_memstorage` spawning disk / process discovery) require sufficient steady-state hover time (minimum 5s stabilization and 15-30s sampling) to reflect true component workload rather than initial launch spikes or premature teardown.
4. Additionally, if the compositor drops hover state or pointer focus without continuous or periodic keep-alive nudge, the popup layer shell may dismiss or freeze updates mid-sample.

## Evidence Summary
- `POPUP_STAGES` navigation relies on a single initial `ydotool` jump without periodic keep-alive during the sample window.
- In quick mode (5s duration), steady-state metrics fail to capture true long-term resource impact.

## Files Involved
- `scripts/profile-quickshell.sh`: Popup navigation, hover hold logic, and stabilization duration configuration.

## Suggested Fix Direction
1. In `scripts/profile-quickshell.sh`, ensure hover navigation enforces adequate warm-up (minimum 5 seconds for interactive popups) and maintains steady cursor focus throughout the entire measurement duration before triggering neutral center dismissal.
2. Provide explicit user feedback during popup profiling that steady-state hover is actively being maintained for the full duration.
