---
status: complete
phase: 03-system-audio-modules
source:
  - 03-VERIFICATION.md
  - 03-VALIDATION.md
started: 2026-07-23T12:30:00Z
updated: 2026-07-23T14:37:41Z
---

## Current Test

[testing complete]

## Tests

### 1. CPU % updates live under load
expected: Ring/label react within ~1–2s under CPU stress
result: issue
reported: "works above 80% color changes to redish, there is no warning color"
severity: major
why_human: Real-time visual timing (roadmap SC1)

### 2. RAM GB label sensible vs free -h
expected: used/total GB (not bare %); roughly matches `free -h`
result: issue
reported: "working but some minor issues - no need GB / GB just used/total GB or (auto human); the spacing with the ring is not right - the spacing in the cpu part is better, spacing between ring and text, also after cpu text and ram ring spacing is also perfect. for ram and disk these spacing need to be fixed"
severity: minor
why_human: Units and live values (roadmap SC2)

### 3. Disk free/total for / matches df -h /
expected: hard_drive icon + free/total capacity for root; ring tracks used %
result: pass
why_human: Visual comparison to host df (roadmap SC3)

### 4. Scroll right bar changes volume
expected: Level, % in indicators, and stock OSD update
result: pass
note: "Keyboard wheel unmute works; keyboard wheel cannot raise volume above 100% (tracked as G-03-4 / test 7)"
why_human: Input path + Pipewire (roadmap SC4)

### 5. Left-click mute toggles; % hides when muted
expected: volume_off only when muted; % returns when unmuted
result: pass
why_human: UI state transition (D-18)

### 6. Volume while muted auto-unmutes (scroll or keyboard)
expected: Mute clears when volume changes (scroll or XF86)
result: pass
why_human: D-21 runtime path

### 7. Volume can reach ~130%
expected: Scroll/keyboard raise past 100% up to ~130%
result: issue
reported: "mouse scroll works but keyboard wheel does not increase above 100%"
severity: major
why_human: D-22 live Pipewire ceiling

### 8. Middle/right on mute or mic opens pavucontrol
expected: volumeMixer launches mixer window
result: issue
reported: "no neither middle/right click on mute or mic opens pavucontrol. from the right sidebar, if i go inside audio input/output by right clicking then click details button it does not opens up anything"
severity: major
why_human: D-23/D-26 process UX

### 9. No resource hover popup
expected: Hover CPU/RAM/Disk does not open ResourcesPopup
result: pass
why_human: Negative UI check (D-09/D-25)

### 10. Mic % tracks input gain
expected: Mic icon + input % update with source volume
result: pass
why_human: Source volume binding live (D-19)

## Summary

total: 10
passed: 6
issues: 4
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-03-1
  truth: "CPU ring/label update live under load; two-step colors per D-07 (warning ≥40%, error ≥80%)"
  status: failed
  reason: "User reported: works above 80% color changes to redish, there is no warning color"
  severity: major
  test: 1
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- gap_id: G-03-2
  truth: "RAM used/total as single unit suffix (e.g. 12.3/31.2 GB or auto-human); ring↔label spacing matches CPU; RAM/disk spacing matches CPU rhythm"
  status: failed
  reason: "User reported: working but some minor issues - no need GB / GB just used/total GB or (auto human); the spacing with the ring is not right - the spacing in the cpu part is better, spacing between ring and text, also after cpu text and ram ring spacing is also perfect. for ram and disk these spacing need to be fixed"
  severity: minor
  test: 2
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- gap_id: G-03-4
  truth: "Keyboard volume wheel can raise past 100% up to ~130% (D-22); mouse scroll already can"
  status: failed
  reason: "User reported (test 4): keyboard wheel cannot increase volume above 100% (unmute via wheel works). Confirmed (test 7): mouse scroll works but keyboard wheel does not increase above 100%"
  severity: major
  test: 7
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- gap_id: G-03-8
  truth: "Middle/right-click on mute or mic launches volumeMixer/pavucontrol; sidebar audio details also open mixer"
  status: failed
  reason: "User reported: no neither middle/right click on mute or mic opens pavucontrol. from the right sidebar, if i go inside audio input/output by right clicking then click details button it does not opens up anything"
  severity: major
  test: 8
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
