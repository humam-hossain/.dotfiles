---
status: testing
phase: 03-system-audio-modules
source:
  - 03-VERIFICATION.md
  - 03-VALIDATION.md
started: 2026-07-23T12:30:00Z
updated: 2026-07-23T12:30:00Z
---

## Current Test

number: 1
name: CPU % updates live under load
expected: |
  Ring fill and percent label move with load within ~1–2s under stress
  (e.g. `yes > /dev/null &`).
awaiting: user response

## Tests

### 1. CPU % updates live under load
expected: Ring/label react within ~1–2s under CPU stress
result: [pending]
why_human: Real-time visual timing (roadmap SC1)

### 2. RAM GB label sensible vs free -h
expected: used/total GB (not bare %); roughly matches `free -h`
result: [pending]
why_human: Units and live values (roadmap SC2)

### 3. Disk free/total for / matches df -h /
expected: hard_drive icon + free/total capacity for root; ring tracks used %
result: [pending]
why_human: Visual comparison to host df (roadmap SC3)

### 4. Scroll right bar changes volume
expected: Level, % in indicators, and stock OSD update
result: [pending]
why_human: Input path + Pipewire (roadmap SC4)

### 5. Left-click mute toggles; % hides when muted
expected: volume_off only when muted; % returns when unmuted
result: [pending]
why_human: UI state transition (D-18)

### 6. Volume while muted auto-unmutes (scroll or keyboard)
expected: Mute clears when volume changes (scroll or XF86)
result: [pending]
why_human: D-21 runtime path

### 7. Volume can reach ~130%
expected: Scroll/keyboard raise past 100% up to ~130%
result: [pending]
why_human: D-22 live Pipewire ceiling

### 8. Middle/right on mute or mic opens pavucontrol
expected: volumeMixer launches mixer window
result: [pending]
why_human: D-23/D-26 process UX

### 9. No resource hover popup
expected: Hover CPU/RAM/Disk does not open ResourcesPopup
result: [pending]
why_human: Negative UI check (D-09/D-25)

### 10. Mic % tracks input gain
expected: Mic icon + input % update with source volume
result: [pending]
why_human: Source volume binding live (D-19)

## Summary

total: 10
passed: 0
issues: 0
pending: 10
skipped: 0
blocked: 0

## Gaps

(none yet — fill during `/gsd-verify-work 3`)
