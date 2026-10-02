---
phase: 51-wwo-fetcher-service-local-cache-architecture
plan: "03"
subsystem: weather-service
tags:
  - weather
  - systemd
  - bootstrap
  - stow
  - deployment
requirements:
  - WWO-02
status: completed
completed_at: "2026-10-03T01:12:00+06:00"
commits:
  - 204b500f  # feat(51-03): author wwo systemd user units and integrate into bootstrap.sh
  - b67d6d9a  # fix(51-03): preserve XDG_RUNTIME_DIR/weather across oneshot service invocations
---

# Plan 51-03 Summary: Systemd Automation, Bootstrap Integration & Verification

## Objective Accomplished
Authored the systemd user service and timer units (`wwo-fetcher.service`, `wwo-fetcher.timer`), integrated directory pre-creation and timer activation into `bootstrap.sh`, deployed the `stow/weather` package to `$HOME` via GNU Stow without folding, enabled the user timer under systemd, and performed end-to-end regression validation via `scripts/phase51-weather-assert.sh` and `./arch/dots-hyprland.sh verify --strict` satisfying WWO-02, D-51-01, D-51-02, and D-51-03.

## Key Changes
1. **Systemd User Units (`stow/weather/.config/systemd/user/`)**:
   - `wwo-fetcher.service`: oneshot service invoking `%h/.config/weather/wwo-fetcher.py` with `Nice=19`, `TimeoutStartSec=30s`, `SyslogIdentifier=wwo-fetcher`, `RuntimeDirectory=weather`, `RuntimeDirectoryMode=0755`, and `RuntimeDirectoryPreserve=yes` so `$XDG_RUNTIME_DIR/weather` persists across timer executions.
   - `wwo-fetcher.timer`: 3-minute recurring timer (`OnStartupSec=1m`, `OnUnitActiveSec=3m`, `Persistent=true`) triggering `wwo-fetcher.service` per D-51-04.

2. **System Bootstrap Integration (`bootstrap.sh`)**:
   - Step 5 (`run_stow_step`): pre-creates `$target/.config/weather` alongside sensitive config directories prior to running GNU Stow, strictly preventing directory folding collisions (`T-51-06`, D-51-01).
   - Step 7 (`step_verify`): enables and starts `wwo-fetcher.timer` with user session checks during automated installations per D-51-03.

3. **Live Deployment & Verification**:
   - Stowed `stow/weather` into `$HOME` with clean discrete leaf symlinks.
   - Reloaded user daemon and enabled `wwo-fetcher.timer` (active and scheduled).
   - Executed full test suite `scripts/phase51-weather-assert.sh` (Sections 1–5 passing with FAIL=0).
   - Executed strict repository verification `./arch/dots-hyprland.sh verify --strict` (passing with 0 failures, 0 findings).

## Verification
- `systemctl --user is-active wwo-fetcher.timer`: active.
- `./scripts/phase51-weather-assert.sh`: PASS (all 5 sections passing with FAIL=0, FINDINGS=0).
- `./arch/dots-hyprland.sh verify --strict`: PASS (FAIL=0, FINDINGS=0).

## Deviations from Plan
- **Rule 1 Auto-Fix**: Added `RuntimeDirectoryPreserve=yes` to `wwo-fetcher.service`. By default, systemd deletes `RuntimeDirectory` when a oneshot service exits; preserving it allows `$XDG_RUNTIME_DIR/weather/weather.json` to remain continuously accessible to Quickshell between timer intervals.

## Self-Check: PASSED
- `stow/weather/.config/systemd/user/wwo-fetcher.service` exists: YES
- `stow/weather/.config/systemd/user/wwo-fetcher.timer` exists: YES
- `bootstrap.sh` includes `wwo-fetcher.timer` and `.config/weather`: YES
- Commits recorded for plan: 204b500f, b67d6d9a
