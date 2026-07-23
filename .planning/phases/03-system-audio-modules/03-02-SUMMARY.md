---
phase: 03-system-audio-modules
plan: 02
subsystem: config
tags: [dual-write, config-qml, illogical-impulse, thresholds, intervals, maxAllowed, bar-05, bar-06, bar-07, bar-08]

requires:
  - phase: 03-system-audio-modules
    provides: Wave 0 phase03-config-assert.py predicates (03-01)
provides:
  - Config.qml Phase 3 defaults for bar.resources dual thresholds, resources multi-rate intervals, audio maxAllowed 130
  - Live ~/.config/illogical-impulse/config.json dual-write of same keys
  - phase03-config-assert.py green (config asserts OK)
affects:
  - 03-05 (ResourceUsage multi-rate timers consume interval keys)
  - 03-06 (Resources strip consumes threshold + alwaysShow keys)
  - 03-04/audio (maxAllowed 130 already productized; dual-write prevents FileView stale-win)
  - 03-08 (nyquist verification)

tech-stack:
  added: []
  patterns:
    - "Dual-write Config.qml defaults + live config.json so FileView cannot stale-win"
    - "Split poll intervals: updateInterval=1000 (CPU), memoryUpdateInterval=3000, diskUpdateInterval=10000"

key-files:
  created: []
  modified:
    - .config/quickshell/modules/common/Config.qml
    - /home/pera/.config/illogical-impulse/config.json

key-decisions:
  - "CPU 40/80, RAM 75/95, disk 80/95 dual-written (D-07, D-13)"
  - "alwaysShowSwap false + alwaysShowCpu true dual-written (D-04, D-05)"
  - "Split intervals dual-written not counter-only (D-08, D-14)"
  - "maxAllowed 130 with protection enable left false (D-22)"

patterns-established:
  - "Phase 3 dual-write payload mirrors Phase 2: edit Config.qml then merge live JSON keys only"
  - "Live config is outside the git repo — dual-write via Python json, verify with phase03-config-assert.py"

requirements-completed: [BAR-05, BAR-06, BAR-07, BAR-08]

coverage:
  - id: D1
    description: "Config.qml bar.resources dual thresholds CPU 40/80 RAM 75/95 disk 80/95 and alwaysShow flags"
    requirement: BAR-05
    verification:
      - kind: other
        ref: "rg -n 'cpuWarningThreshold:|cpuErrorThreshold:|memoryWarningThreshold:|memoryErrorThreshold:|diskWarningThreshold:|diskErrorThreshold:|alwaysShowSwap:|alwaysShowCpu:' .config/quickshell/modules/common/Config.qml"
        status: pass
    human_judgment: false
  - id: D2
    description: "Config.qml resources multi-rate intervals 1000/3000/10000 and audio.protection.maxAllowed 130"
    requirement: BAR-08
    verification:
      - kind: other
        ref: "rg -n 'updateInterval:|memoryUpdateInterval:|diskUpdateInterval:|maxAllowed:' .config/quickshell/modules/common/Config.qml"
        status: pass
    human_judgment: false
  - id: D3
    description: "Live config.json dual-written for all Phase 3 keys; phase03-config-assert.py exits 0"
    requirement: BAR-05
    verification:
      - kind: other
        ref: "python3 scripts/phase03-config-assert.py"
        status: pass
    human_judgment: false
  - id: D4
    description: "Quickshell loads dual-written config without hard errors"
    requirement: BAR-05
    verification:
      - kind: other
        ref: "timeout 4 quickshell → Configuration Loaded"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-07-23
status: complete
---

# Phase 3 Plan 02: Dual-write Config Defaults Summary

**Config.qml + live illogical-impulse config.json dual-written for Phase 3 thresholds (CPU 40/80, RAM 75/95, disk 80/95), alwaysShow flags, multi-rate intervals (1s/3s/10s), and audio maxAllowed 130 — phase03-config-assert.py green.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-23T10:12:06Z
- **Completed:** 2026-07-23T10:14:00Z
- **Tasks:** 2/2
- **Files modified:** 2 (1 in-repo + 1 live host path)

## Accomplishments

- Updated `Config.qml` `audio.protection.maxAllowed` 99 → 130 (enable remains false; maxAllowedIncrease 10)
- Updated `bar.resources`: alwaysShowSwap false, alwaysShowCpu true; CPU 40/80, RAM 75/95, disk 80/95; kept swapWarningThreshold for service/history
- Updated top-level `resources` poll block: updateInterval 1000, memoryUpdateInterval 3000, diskUpdateInterval 10000; historyLength 60
- Dual-wrote identical Phase 3 keys into `~/.config/illogical-impulse/config.json` (preserved volumeMixer, workspaces.shown=4, all other structure)
- `python3 scripts/phase03-config-assert.py` → `config asserts OK` (exit 0)
- Smoke: `timeout 4 quickshell` → `Configuration Loaded` (unrelated ToolbarTabBar TypeError pre-existing dirty tree)

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 03-02-01 | Update Config.qml Phase 3 defaults | 946b363 | `.config/quickshell/modules/common/Config.qml` |
| 03-02-02 | Dual-write live config.json + assert green | (out-of-repo) | `/home/pera/.config/illogical-impulse/config.json` |

_Note: Task 2 only mutates the host live config path outside the git tree; verification is the green assert, not a git commit._

## Files Created/Modified

- `.config/quickshell/modules/common/Config.qml` — Phase 3 defaults for bar.resources, resources intervals, audio.protection.maxAllowed
- `/home/pera/.config/illogical-impulse/config.json` — live dual-write of same keys (not in repo)

## Decisions Made

- Dual-write both Config.qml and live JSON so FileView cannot stale-win with old cpuWarning 90 / maxAllowed 99 (T-03-01)
- protection.enable left false so protection clamp does not fight intentional 130% boost (D-22 / T-03-04)
- volumeMixer string and workspaces.shown (UAT=4) left untouched
- swapWarningThreshold retained for service/history; bar UI hides swap via alwaysShowSwap false (D-04)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Live dual-write and assert passed on first attempt. Quickshell smoke showed only pre-existing dirty-tree ToolbarTabBar TypeError (unrelated, not staged).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Wave 0 assert is green; downstream plans (03-05 ResourceUsage intervals, 03-06 Resources strip) can read dual-written keys at runtime
- Audio 130% productization (03-04) already shipped; dual-write closes T-03-01 stale-win gap for maxAllowed

## Self-Check: PASSED

- FOUND: `.config/quickshell/modules/common/Config.qml`
- FOUND: `/home/pera/.config/illogical-impulse/config.json`
- FOUND: commit `946b363`
- FOUND: `python3 scripts/phase03-config-assert.py` → config asserts OK

---
*Phase: 03-system-audio-modules*
*Completed: 2026-07-23*
