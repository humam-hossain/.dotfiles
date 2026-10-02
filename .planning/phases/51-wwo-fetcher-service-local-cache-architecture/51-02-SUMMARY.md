---
phase: 51-wwo-fetcher-service-local-cache-architecture
plan: "02"
subsystem: weather-service
tags:
  - weather
  - fetcher
  - caching
  - rate-limiting
  - offline-resilience
requirements:
  - WWO-01
  - WWO-02
  - WWO-03
  - WWO-04
status: completed
completed_at: "2026-10-03T01:07:05+06:00"
commits:
  - 4461005b  # feat(51-02): implement standalone background weather fetcher service
  - 6bb6e99e  # feat(51-02): expand assertion test harness with sections 3, 4, and 5
---

# Plan 51-02 Summary: Core Fetcher Service & Comprehensive Assertion Suite

## Objective Accomplished
Implemented the standalone background Python fetcher `stow/weather/.config/weather/wwo-fetcher.py` and expanded the assertion test harness `scripts/phase51-weather-assert.sh` to fully validate dynamic budget pacing math, atomic tmpfs caching, envelope schema conformance, and two-tier offline resilience satisfying WWO-01, WWO-02, WWO-03, and WWO-04 per D-51-04 through D-51-09.

## Key Changes
1. **Background Weather Telemetry Fetcher (`stow/weather/.config/weather/wwo-fetcher.py`)**:
   - Zero third-party dependencies (pure Python standard library: `urllib.request`, `json`, `os`, `argparse`, `datetime`).
   - Dynamic budget pacing math: computes interval $(M_{\text{remaining}} / \max(1, 470 - \text{calls})) \ge 3.0$ min with automatic UTC midnight rollover in `~/.local/state/weather/quota.json`.
   - Absolute quota ceiling: 500 calls/day strictly enforced against WWO 429 quota exhaustion (`T-51-02`).
   - Atomic cache engine: writes to `weather.json.tmp.<pid>` inside `$XDG_RUNTIME_DIR/weather/`, flushes, fsyncs, and replaces via `os.replace` to eliminate cross-mount `EXDEV` failures and partial read race conditions (`T-51-03`, D-51-06).
   - Cold-boot offline resilience: seeds initial offline skeleton (`status: "offline"`, `data: null`, `is_stale: true`) and maintains persistent disk mirror at `~/.local/state/weather/last_known_weather.json` to prevent UI `ENOENT` crashes across reboots (D-51-07, D-51-08).
   - Error trapping: network drops or API errors preserve existing forecast data with `is_stale: true` and exit 0 to allow subsequent systemd timer ticks without immediate retry loops (D-51-05).
   - CLI flags: `--force` (bypass interval), `--status` (inspection report), `--dry-run` (simulation).

2. **Assertion Test Harness Expansion (`scripts/phase51-weather-assert.sh`)**:
   - Section 3: asserts dynamic budget pacing formula across 00:01 UTC, 18:00 UTC, and budget ceiling; verifies automatic UTC midnight quota reset and 500-call absolute ceiling throttling.
   - Section 4: asserts envelope JSON schema conformance (`status`, `fetched_epoch`, `is_stale`, `quota`, `data`) and verifies atomic `os.replace` inode transitions.
   - Section 5: validates cold-boot offline skeleton generation, persistent cache recovery across simulated reboot, and network outage error payload preservation with `is_stale: true`.

## Verification
- `./scripts/phase51-weather-assert.sh`: PASS (all 5 sections passing, 0 failures, 0 findings).
- `./stow/weather/.config/weather/wwo-fetcher.py --status`: PASS (reports valid status).
- `./stow/weather/.config/weather/wwo-fetcher.py --dry-run`: PASS (simulates resolution cleanly).

## Deviations from Plan
None — plan executed exactly as written.

## Self-Check: PASSED
- `stow/weather/.config/weather/wwo-fetcher.py` exists on disk and is executable (0755): YES
- `scripts/phase51-weather-assert.sh` passes all 5 sections: YES
- Commits recorded for plan: 4461005b, 6bb6e99e
