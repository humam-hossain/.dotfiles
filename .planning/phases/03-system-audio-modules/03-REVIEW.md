---
phase: 03-system-audio-modules
status: clean
reviewed: "2026-07-23T12:55:00Z"
scope: phase 03 product files BAR-05..08 (plans 03-01..03-08)
note: "Advisory review completed orchestrator-inline after gsd-code-reviewer rate-limit (429). No findings elevated to blocking."
---

# Phase 3 Code Review

**Scope:** Resource strip, ResourceUsage multi-rate poll, Audio 130%/auto-unmute, mute/mic indicators, config dual-write, phase03 assert  
**Verdict:** clean (advisory — no blockers)

## Files Reviewed

| File | Notes |
|------|-------|
| `scripts/phase03-config-assert.py` | Stdlib-only; nested key asserts; exit 0 on host |
| `Config.qml` | Phase 3 thresholds/intervals/maxAllowed dual-write defaults |
| `Resource.qml` | Dual threshold ladder + labelText + TextMetrics |
| `Resources.qml` | CPU→RAM→Disk; no swap; no ResourcesPopup; Item root |
| `ResourceUsage.qml` | df argv + LANG=C; multi-rate counters; formatBytes |
| `Audio.qml` | maxVolume 1.30; muted=false on volume paths |
| `ScreenCorners.qml` | Delegates to Audio.incrementVolume |
| `hyprland.conf` | XF86AudioRaiseVolume `-l 1.3` |
| `BarContent.qml` | mute/mic % + volumeMixer middle/right + right scroll |

## Findings

None blocking.

### Notes (non-blocking)

1. **volumeMixer via `bash -c Config.options.apps.volumeMixer`** — command string is from dual-written Config, not bar text. Acceptable for desktop shell; same pattern as stock ii apps launches. Do not interpolate untrusted UI strings into the argv.

2. **ResourceUsage Timer starts at `interval: 1` then reassigns to `updateInterval`** — first-tick pattern used elsewhere in service; intentional, not a busy-loop (interval becomes 1000 after first fire).

3. **`alwaysShowAllResources` retained on Resources** — API compatibility with BarContent assignment after 03-06; strip always shows regardless of prop value. Documented in SUMMARY; fine.

4. **df Process toggles `running` false→true** — correct restart pattern; gated to ~10s so T-03-03 mitigated.

5. **Pre-existing ToolbarTabBar TypeError + polkit WARN** on smoke — unrelated to Phase 3; Configuration Loaded still reached.

6. **ResourcesPopup.qml left on disk unused** — intentional (D-09); do not delete in this phase.

## Security

| Area | Assessment |
|------|------------|
| Trust boundary: Config → thresholds | Local dual-write; assert script validates |
| Trust boundary: df/proc stdout | Numeric parse with isFinite guards |
| Process spawn: volumeMixer | Fixed Config path, not free-form user input from bar |
| No new network surface | Local metrics + Pipewire only |
| No package installs | Phase gate forbids SC installs |

No new high-severity issues for desktop-local metrics/audio control.

## Cross-check vs VERIFICATION

Agrees with `03-VERIFICATION.md`: code/wiring green; runtime visual/interaction items deferred to `03-UAT.md` / `/gsd-verify-work 3`.
