---
phase: 02-core-bar-modules
plan: 02
subsystem: config
tags: [Config.qml, time, tray, dual-write, BAR-02, BAR-03]

requires:
  - phase: 02-core-bar-modules
    provides: phase02-config-assert.py Wave 0 harness
provides:
  - Config.qml time.format + secondPrecision defaults
  - tray.monochromeIcons false default
  - dual-written ~/.config/illogical-impulse/config.json
affects: [02-03, 02-05, bar-clock, systray]

tech-stack:
  added: []
  patterns: [dual-write Config.qml + live config.json]

key-files:
  created: []
  modified:
    - .config/quickshell/modules/common/Config.qml
    - ~/.config/illogical-impulse/config.json

key-decisions:
  - "time.format = ddd yyyy-MM-dd hh:mm:ss AP (Waybar-comparable)"
  - "secondPrecision true for per-second clock ticks"
  - "tray.monochromeIcons false for full-color icons"
  - "No timezone property — system TZ only (D-07)"

patterns-established:
  - "Pattern: always dual-write Config defaults and live config.json"

requirements-completed: [BAR-01, BAR-02, BAR-03]

coverage:
  - id: D1
    description: Clock format and secondPrecision in Config + live JSON
    requirement: BAR-02
    verification:
      - kind: other
        ref: "python3 scripts/phase02-config-assert.py"
        status: pass
    human_judgment: false
  - id: D2
    description: Full-color tray + pin policy dual-written
    requirement: BAR-03
    verification:
      - kind: other
        ref: "python3 scripts/phase02-config-assert.py"
        status: pass
    human_judgment: false
  - id: D3
    description: Workspace appearance + weather-off locked
    requirement: BAR-01
    verification:
      - kind: other
        ref: "python3 scripts/phase02-config-assert.py"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-21
status: complete
---

# Phase 02: Plan 02 Summary

**Dual-wrote Config.qml and live config.json so clock seconds, full-color tray, workspace locks, and weather-off are active at runtime.**

## Accomplishments

- Config.qml `time.format` → `ddd yyyy-MM-dd hh:mm:ss AP`, `secondPrecision: true`
- Config.qml `tray.monochromeIcons: false`; pin policy unchanged (invert + Fcitx)
- Live `~/.config/illogical-impulse/config.json` dual-written for same keys
- `python3 scripts/phase02-config-assert.py` → `config asserts OK` (exit 0)
- Workspace defaults (shown 10 / showAppIcons / monochrome) and weather.enable false preserved

## Self-Check: PASSED

- phase02-config-assert.py exit 0
- No TZ hardcode under time block
