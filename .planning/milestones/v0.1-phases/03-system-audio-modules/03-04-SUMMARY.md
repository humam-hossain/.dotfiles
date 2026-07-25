---
phase: 03-system-audio-modules
plan: 04
subsystem: audio
tags: [quickshell, qml, pipewire, volume, maxVolume, auto-unmute, hyprland, wpctl, bar-08]

requires:
  - phase: 03-system-audio-modules
    provides: Audio service + ScreenCorners scroll paths + Hyprland XF86 binds (existing ii foundation)
provides:
  - Audio.qml maxVolume 1.30 (D-22) with hardMaxValue 2.00 safety rail
  - Auto-unmute on sink/source volume change via dedicated Connections (D-21)
  - incrementVolume/decrementVolume unmute + clamp to maxVolume/0
  - ScreenCorners scroll aligned to Audio.incrementVolume/decrementVolume
  - Hyprland XF86AudioRaiseVolume wpctl -l 1.3 keyboard boost parity
affects:
  - 03-07 (BarContent mute/mic % and scroll already call incrementVolume)
  - 03-08 (nyquist static gates for maxVolume + muted=false + -l 1.3)

tech-stack:
  added: []
  patterns:
    - "Central maxVolume on Audio service; UI paths call incrementVolume"
    - "Dedicated Connections for auto-unmute not gated on protection.enable"
    - "Hyprland keyboard raise ceiling mirrors UI maxVolume via -l 1.3"

key-files:
  created: []
  modified:
    - .config/quickshell/services/Audio.qml
    - .config/quickshell/modules/ii/screenCorners/ScreenCorners.qml
    - .config/hypr/hyprland.conf

key-decisions:
  - "maxVolume 1.30 hardcoded on Audio independently of protection.maxAllowed dual-write (03-02)"
  - "Dedicated sink/source Connections for auto-unmute so D-21 works when protection.enable is false"
  - "ScreenCorners delegates to Audio.incrementVolume/decrementVolume rather than local Math.min"
  - "Hyprland raise bind -l 1.3 closed as YES (binds live in this repo)"

patterns-established:
  - "User raise paths: Audio.incrementVolume (maxVolume clamp + unmute)"
  - "External wpctl volume change → Connections onVolumeChanged → muted=false"
  - "Mic symmetry: source.audio onVolumeChanged auto-unmutes"

requirements-completed: [BAR-08]

coverage:
  - id: D1
    description: "User-driven volume raise reaches 130% linear via Audio.incrementVolume (maxVolume 1.30)"
    requirement: BAR-08
    verification:
      - kind: other
        ref: "rg -n 'maxVolume|Math.min\\(maxVolume' .config/quickshell/services/Audio.qml"
        status: pass
    human_judgment: false
  - id: D2
    description: "Volume change while muted auto-unmutes sink (scroll + external wpctl Connections)"
    requirement: BAR-08
    verification:
      - kind: other
        ref: "rg -n 'muted = false' .config/quickshell/services/Audio.qml"
        status: pass
    human_judgment: false
  - id: D3
    description: "Mic input volume change while muted auto-unmutes source (D-21 symmetry)"
    requirement: BAR-08
    verification:
      - kind: other
        ref: "rg -n 'source.audio.muted = false' .config/quickshell/services/Audio.qml"
        status: pass
    human_judgment: false
  - id: D4
    description: "ScreenCorners raise path uses Audio.incrementVolume (no Math.min(1 hard cap)"
    requirement: BAR-08
    verification:
      - kind: other
        ref: "rg -n 'incrementVolume|Math.min\\(1' .config/quickshell/modules/ii/screenCorners/ScreenCorners.qml"
        status: pass
    human_judgment: false
  - id: D5
    description: "Hyprland XF86AudioRaiseVolume uses wpctl -l 1.3"
    requirement: BAR-08
    verification:
      - kind: other
        ref: "rg -n 'XF86AudioRaiseVolume' .config/hypr/hyprland.conf → -l 1.3"
        status: pass
      - kind: other
        ref: "timeout 4 quickshell → Configuration Loaded"
        status: pass
    human_judgment: false

duration: 2min
completed: 2026-07-23
status: complete
---

# Phase 3 Plan 04: Audio 130% + Auto-unmute Summary

**Audio service productized for BAR-08: maxVolume 1.30, auto-unmute on any volume path (UI + keyboard), ScreenCorners and Hyprland XF86 raise aligned so no path silently caps at 100%.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-07-23T10:04:31Z
- **Completed:** 2026-07-23T10:06:00Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Added `readonly property real maxVolume: 1.30` (D-22); kept `hardMaxValue: 2.00` safety rail
- `incrementVolume` / `decrementVolume` unmute first then clamp to `maxVolume` / `0` (no more `Math.min(1, …)`)
- Dedicated sink + source `Connections` auto-unmute when volume actually changes while muted — not gated on `protection.enable` (D-21 keyboard/wpctl path)
- ScreenCorners right-corner scroll delegates to `Audio.incrementVolume()` / `decrementVolume()`
- Hyprland `XF86AudioRaiseVolume` raised to `wpctl set-volume -l 1.3` (lower/mute/mic-mute unchanged)
- Smoke: `Configuration Loaded` (pre-existing ToolbarTabBar.qml TypeError is unrelated dirty tree)

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 03-04-01 | Audio maxVolume 1.30 + auto-unmute + inc/dec clamp | 7698aef | `Audio.qml` |
| 03-04-02 | Align ScreenCorners and Hyprland XF86 raise to 130% | ea0baf0 | `ScreenCorners.qml`, `hyprland.conf` |

## Files Created/Modified

- `.config/quickshell/services/Audio.qml` — maxVolume, auto-unmute Connections, inc/dec clamp
- `.config/quickshell/modules/ii/screenCorners/ScreenCorners.qml` — scroll → Audio service
- `.config/hypr/hyprland.conf` — XF86 raise `-l 1.3`

## Decisions Made

- Hardcode `maxVolume` on Audio independently of protection dual-write (03-02 still pending) so UI boost works even before maxAllowed is live
- Prefer dedicated auto-unmute Connections over stuffing logic after protection early-return
- ScreenCorners calls service helpers rather than duplicating step/clamp math
- Hyprland bind update is in-scope (open question closed: binds live in this repo)

## Deviations from Plan

None - plan executed exactly as written.

## Residual raise paths (documented, out of interactive scroll scope)

Grep found no remaining `Math.min(1, Audio.sink…)` interactive raise caps. Direct `Audio.sink.audio.volume = value` slider writers remain in:

- `modules/ii/sidebarRight/QuickSliders.qml` — sidebar slider (max depends on StyledSlider range, not a scroll raise path)
- `modules/waffle/actionCenter/mainPage/MainPageBodySliders.qml` — waffle action center (not ii bar path)

Primary BAR-08 paths (BarContent scroll already used `incrementVolume`; ScreenCorners; Hyprland XF86) all allow 130%.

## Known Stubs

None.

## Threat Flags

None new — T-03-04 mitigated by maxVolume 1.30 + hardMaxValue 2.00; no unlimited raise path introduced.
