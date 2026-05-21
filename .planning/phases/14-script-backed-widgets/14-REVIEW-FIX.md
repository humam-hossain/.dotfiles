---
phase: 14-script-backed-widgets
fixed_at: 2026-05-21T12:00:00Z
review_path: .planning/phases/14-script-backed-widgets/14-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 14: Code Review Fix Report

**Fixed at:** 2026-05-21T12:00:00Z
**Source review:** .planning/phases/14-script-backed-widgets/14-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: BacklightService — empty catch block silently swallows errors, no "err" fallback

**Files modified:** `.config/quickshell/services/BacklightService.qml`
**Commit:** a329173
**Applied fix:** Added `else` branch after validation that sets `root.formatted = "err"` when `ddcutil` output is invalid. Replaced empty `catch (e) { }` with `catch (e) { root.formatted = "err" }` so read failures are visibly indistinguishable from a valid 0% reading.

### CR-02: BacklightService — shell command via string concatenation (defense-in-depth)

**Files modified:** `.config/quickshell/services/BacklightService.qml`
**Commit:** d1d5b13
**Applied fix:** Replaced `["bash", "-c", "ddcutil setvcp 10 " + target]` with direct argument array `["ddcutil", "setvcp", "10", String(target)]`. Eliminates unnecessary `bash -c` wrapper and string interpolation, removing injection surface.

### WR-01: BacklightService — `_pendingDelta` never reset after debounce write, causing cumulative adjustment errors

**Files modified:** `.config/quickshell/services/BacklightService.qml`
**Commit:** e07de7f
**Applied fix:** Added `root._pendingDelta = 0` at the end of the debounce handler after the write command is issued. Prevents cumulative drift where each scroll event compounds on previous deltas within the same debounce session.

### WR-02: BacklightService — optimistic UI update before write confirmation

**Files modified:** `.config/quickshell/services/BacklightService.qml`
**Commit:** 3e4869e
**Applied fix:** Removed optimistic `root.brightnessPercent = target` and `root.formatted = ...` from the debounce handler. These properties are now updated only after the hardware write completes, via the existing re-read chain in `writeProc.onStreamFinished` (which triggers `pollTimer.restart()` and `readProc.running = true`). The re-read restores values from actual hardware, so a failed write won't display a false value.

### WR-03: Four services use `$HOME` shell expansion for script paths

**Files modified:** `.config/quickshell/services/ForecastService.qml`, `.config/quickshell/services/MemoryService.qml`, `.config/quickshell/services/PingService.qml`, `.config/quickshell/services/WeatherService.qml`
**Commit:** ccc86f2
**Applied fix:** Replaced `"$HOME/..."` shell variable expansion with `Qt.getenv("HOME") + "/..."` in all four services. Resolves the path programmatically via Qt's process environment API instead of relying on shell expansion, making paths robust against `$HOME` containing spaces or special characters.

## Skipped Issues

None — all 5 in-scope findings were successfully fixed.

---

_Fixed: 2026-05-21T12:00:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
