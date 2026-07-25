---
phase: 03-system-audio-modules
plan: 07
subsystem: audio
tags: [quickshell, qml, pipewire, volume, mute, mic, pavucontrol, bar-08, indicators]

requires:
  - phase: 03-system-audio-modules
    provides: Audio.qml toggleMute/toggleMicMute + maxVolume 1.30 + auto-unmute (03-04)
  - phase: 02-core-bar-modules
    provides: D-19 indicators pill with per-icon mute/mic MouseAreas in BarContent.qml
provides:
  - Mute indicator Row with volume icon + sink volume % when unmuted; volume_off only when muted (D-18)
  - Mic indicator Row with mic icon + source volume % when unmuted; mic_off only when muted (D-19)
  - Multi-button MouseArea: left toggle mute/mic; middle/right open Config volumeMixer (D-23, D-26)
  - Right-bar FocusedScrollMouseArea scroll path preserved (D-20)
affects:
  - 03-08 (nyquist/validation gates for mute % visibility + volumeMixer click map)
  - Phase 3 UAT BAR-08 visual/interaction checks

tech-stack:
  added: []
  patterns:
    - "Indicator Item wraps RowLayout (icon + optional %) with z:10 MouseArea fill"
    - "Trusted mixer launch: Quickshell.execDetached bash -c Config.options.apps.volumeMixer only"
    - "Percent = Math.round(volume * 100); hide StyledText when muted"

key-files:
  created: []
  modified:
    - .config/quickshell/modules/ii/bar/BarContent.qml

key-decisions:
  - "Keep mute/mic inside indicators pill — no dedicated volume module (D-17)"
  - "Mic % uses PipeWire source.audio.volume level, not VU peak"
  - "Both middle and right open volumeMixer (D-23/D-26 both allowed)"
  - "Wheel left unhandled on indicator MouseArea so right-bar scroll habit remains"

patterns-established:
  - "Audio indicator Item + RowLayout + multi-button MouseArea with mouse.accepted=true"
  - "Config.options.apps.volumeMixer is sole trusted mixer command string"

requirements-completed: [BAR-08]

coverage:
  - id: D1
    description: "Output unmuted shows volume_up + sink volume %; muted shows volume_off only (D-18)"
    requirement: BAR-08
    verification:
      - kind: other
        ref: "rg -n 'volume_off|volume_up|Audio\\.sink' .config/quickshell/modules/ii/bar/BarContent.qml"
        status: pass
    human_judgment: false
  - id: D2
    description: "Mic unmuted shows mic + source volume %; muted shows mic_off only (D-19)"
    requirement: BAR-08
    verification:
      - kind: other
        ref: "rg -n 'mic_off|Audio\\.source' .config/quickshell/modules/ii/bar/BarContent.qml"
        status: pass
    human_judgment: false
  - id: D3
    description: "Right-bar FocusedScrollMouseArea still calls Audio.incrementVolume/decrementVolume (D-20)"
    requirement: BAR-08
    verification:
      - kind: other
        ref: "rg -n 'incrementVolume|decrementVolume|FocusedScrollMouseArea' .config/quickshell/modules/ii/bar/BarContent.qml"
        status: pass
    human_judgment: false
  - id: D4
    description: "Left click toggles mute/mic; middle and right open Config volumeMixer via execDetached (D-23, D-26)"
    requirement: BAR-08
    verification:
      - kind: other
        ref: "rg -n 'acceptedButtons|toggleMute|toggleMicMute|volumeMixer|execDetached' .config/quickshell/modules/ii/bar/BarContent.qml"
        status: pass
    human_judgment: false
  - id: D5
    description: "Quickshell loads configuration after BarContent mute/mic changes"
    requirement: BAR-08
    verification:
      - kind: other
        ref: "timeout 4 quickshell 2>&1 | rg 'Configuration Loaded|Error'"
        status: pass
    human_judgment: false
  - id: D6
    description: "No dedicated volume module; no new volume OSD component (D-17, D-24)"
    requirement: BAR-08
    verification:
      - kind: other
        ref: "test ! -f .config/quickshell/modules/ii/bar/VolumeModule.qml"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-07-23
status: complete
---

# Phase 3 Plan 7: Mute/Mic Icon+Percent + Mixer Clicks Summary

**Indicators-pill mute/mic show icon+volume% when unmuted and icon-only when muted; left toggles mute, middle/right open pavucontrol via Config volumeMixer; right-bar scroll and stock OSD kept.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-23T10:18:55Z
- **Completed:** 2026-07-23T10:21:30Z
- **Tasks:** 2/2
- **Files modified:** 1

## Accomplishments

- Productized BAR-08 display on existing indicators: sink/source volume percent beside icons when unmuted
- Muted state collapses to icon-only (`volume_off` / `mic_off`) per D-18/D-19
- Multi-button click map: left = toggle mute/mic mute; middle/right = trusted `Config.options.apps.volumeMixer` launch
- Preserved right-bar `FocusedScrollMouseArea` volume scroll and stock ii OSD (no new module/OSD)

## Task Commits

Each task was committed atomically:

1. **Task 1: Mute and mic icon + percent display** - `fbc3a85` (feat)
2. **Task 2: Multi-button clicks — toggle mute + open pavucontrol** - `648350f` (feat)

**Plan metadata:** `ef32df8` (docs: complete plan)

## Files Created/Modified

- `.config/quickshell/modules/ii/bar/BarContent.qml` — mute/mic Item+RowLayout indicators with % + multi-button MouseAreas

## Decisions Made

- No dedicated volume module — enhance D-19 pill only (D-17)
- Mic percent from PipeWire source volume level (not peak meter)
- Both MiddleButton and RightButton open mixer (plan allows middle and/or right)
- Wheel not handled on indicator MouseArea so parent right-bar scroll still works (D-20)

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None — mixer launch uses only `Config.options.apps.volumeMixer` (T-03-02 mitigate); no new endpoints or auth paths.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: `.config/quickshell/modules/ii/bar/BarContent.qml` (mute/mic icon+%, acceptedButtons, volumeMixer)
- FOUND: commit `fbc3a85` (task 1)
- FOUND: commit `648350f` (task 2)
- Smoke: `Configuration Loaded` (pre-existing ToolbarTabBar warnings unrelated / out of scope)
