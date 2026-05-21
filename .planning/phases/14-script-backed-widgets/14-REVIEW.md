---
phase: 14-script-backed-widgets
reviewed: 2026-05-21T12:00:00Z
depth: deep
files_reviewed: 25
files_reviewed_list:
  - .config/quickshell/BarContent.qml
  - .config/quickshell/popups/VolumeOsd.qml
  - .config/quickshell/services/BacklightService.qml
  - .config/quickshell/services/ClockService.qml
  - .config/quickshell/services/CpuService.qml
  - .config/quickshell/services/DiskService.qml
  - .config/quickshell/services/ForecastService.qml
  - .config/quickshell/services/MemoryService.qml
  - .config/quickshell/services/NetworkService.qml
  - .config/quickshell/services/NotificationService.qml
  - .config/quickshell/services/PingService.qml
  - .config/quickshell/services/WeatherService.qml
  - .config/quickshell/services/qmldir
  - .config/quickshell/theme/Colours.qml
  - .config/quickshell/widgets/BacklightWidget.qml
  - .config/quickshell/widgets/ClockWidget.qml
  - .config/quickshell/widgets/CpuWidget.qml
  - .config/quickshell/widgets/DiskWidget.qml
  - .config/quickshell/widgets/ForecastWidget.qml
  - .config/quickshell/widgets/MemoryWidget.qml
  - .config/quickshell/widgets/NetworkWidget.qml
  - .config/quickshell/widgets/NotificationWidget.qml
  - .config/quickshell/widgets/PingWidget.qml
  - .config/quickshell/widgets/WeatherWidget.qml
  - .config/quickshell/widgets/qmldir
findings:
  critical: 2
  warning: 3
  info: 4
  total: 9
status: issues_found
---

# Phase 14: Code Review Report — Script-Backed Widgets

**Reviewed:** 2026-05-21T12:00:00Z
**Depth:** deep
**Files Reviewed:** 25
**Status:** issues_found

## Summary

Reviewed 25 QML files across the quickshell bar system: 13 services (singletons polling shell commands), 10 display widgets, 1 popup, 1 theme, 1 bar layout, and 2 module registries. Architecture is clean — services provide reactive properties, widgets consume them via QML bindings/Connections, and Colours.qml provides centralized theming.

Cross-file consistency verified: all service singletons registered in `services/qmldir` match widget references, all widgets declared in `widgets/qmldir` match `BarContent.qml` usage, and semantic color aliases (e.g., `pingGood`, `cpuColor`) are used consistently.

**Primary concern:** `BacklightService.qml` has three clustered issues — an empty catch block with no error fallback, a cumulative brightness adjustment bug (`_pendingDelta` never reset), and an unnecessary `bash -c` shell wrapper for a simple ddcutil command. The empty catch is the most serious because it silently renders a 0% reading indistinguishable from a broken service.

Defense-in-depth: four services route script paths through `$HOME` shell expansion instead of resolving the path programmatically. Pattern is low-risk (user's own dotfiles) but inconsistent with Quickshell's `Process` argument-array API design.

---

## Critical Issues

### CR-01: BacklightService — empty catch block silently swallows errors, no "err" fallback

**File:** `.config/quickshell/services/BacklightService.qml:26-37`

**Issue:** The `readProc` process handler has an empty `catch (e) { }` at line 34. When `ddcutil` fails (monitor disconnected, command not found, permission denied), `parseInt` returns `NaN`, the validation `!isNaN(val) && val >= 0 && val <= 100` at line 30 fails, and **no assignment happens**. The `brightnessPercent` stays at its initial value of `0` — which is a valid 0% reading, indistinguishable from a working service at 0% brightness.

Every other service in the codebase follows a consistent error-handling pattern:
- **CpuService.qml:31-35** — else branch sets `"err"`, catch sets `"err"`
- **DiskService.qml:32-37** — else branch sets `"err"`, catch sets `"err"`
- **PingService.qml:31-33** — catch sets `"err"` / `"dead"`

BacklightService has neither the else branch nor a non-empty catch, making it the only service with silent failure.

**Fix:**

Replace the empty catch and add an else fallback:

```qml
// BacklightService.qml lines 26-37 — revised
stdout: StdioCollector {
    onStreamFinished: {
        try {
            const val = parseInt(this.text.trim(), 10)
            if (!isNaN(val) && val >= 0 && val <= 100) {
                root.brightnessPercent = val
                root.formatted = (val < 10 ? "  " : val < 100 ? " " : "") + val + "%"
            } else {
                root.formatted = "err"   // ← added: explicit error state
            }
        } catch (e) {
            root.formatted = "err"       // ← replaced: empty catch → error state
        }
    }
}
```

---

### CR-02: BacklightService — shell command via string concatenation (defense-in-depth)

**File:** `.config/quickshell/services/BacklightService.qml:47`

**Issue:** The write command is constructed via string concatenation into a `bash -c` shell string:

```qml
writeProc.command = ["bash", "-c", "ddcutil setvcp 10 " + target]
```

While `target` is mathematically constrained to `[0, 100]` (line 46), the pattern introduces a defense-in-depth violation:
1. String concatenation into a shell command is the classic injection pattern — any future code change that alters how `target` is computed (reading from config, external input) could create an exploit path.
2. The `bash -c` wrapper is unnecessary — `ddcutil` is a single binary with no pipes, redirects, or shell features needed.

Compare to the read command (line 25) which legitimately needs `bash -c` for the awk pipeline. The write command has no such requirement.

**Fix:** Use direct argument array — eliminates shell interpolation entirely:

```qml
writeProc.command = ["ddcutil", "setvcp", "10", String(target)]
```

---

## Warnings

### WR-01: BacklightService — `_pendingDelta` never reset after debounce write, causing cumulative adjustment errors

**File:** `.config/quickshell/services/BacklightService.qml:45-51,54-56`

**Issue:** The `adjustBrightness(delta)` function (line 54) accumulates scroll delta into `_pendingDelta`, and the debounce timer (line 44) writes `current + _pendingDelta` to hardware. But `_pendingDelta` is **never reset to 0** after the write.

This causes each subsequent adjustment to compound on previous ones:

| Step | User action | _pendingDelta | Target brightness | Expected |
|------|------------|---------------|-------------------|----------|
| 1 | Scroll +5 | 5 | 50→55 | 55 ✓ |
| 2 | Scroll +5 | 5+5=10 | 55→65 | 60 ✗ |
| 3 | Scroll +5 | 10+5=15 | 65→80 | 70 ✗ |
| 4 | Scroll +5 | 15+5=20 | 80→100 (clamped) | 75 ✗ |

The error grows linearly with each scroll event within the same "active" session (where the user never leaves a 300ms idle gap).

**Fix:** Reset `_pendingDelta` at the end of the debounce handler:

```qml
// BacklightService.qml line 45-51 — revised
onTriggered: {
    const current = root.brightnessPercent
    const target  = Math.max(0, Math.min(100, current + root._pendingDelta))
    writeProc.command = ["bash", "-c", "ddcutil setvcp 10 " + target]
    writeProc.running = true
    root.brightnessPercent = target
    root.formatted = (target < 10 ? "  " : target < 100 ? " " : "") + target + "%"
    root._pendingDelta = 0   // ← added: reset accumulator after write
}
```

---

### WR-02: BacklightService — optimistic UI update before write confirmation

**File:** `.config/quickshell/services/BacklightService.qml:48-49`

**Issue:** The UI properties `brightnessPercent` and `formatted` are updated immediately in the debounce handler, before the `writeProc` ddcutil command completes. If the hardware write fails (monitor disconnected after sleep/wake, permission error), the UI displays the new value while the hardware is unchanged. There is no rollback logic.

Compare this to a read-then-confirm pattern: the `readProc` handler (line 27) has a post-write re-read sequence (lines 63-67) that sets `pollTimer.interval = 2000` and re-reads from hardware, which will correct a stale optimistic value — but only after a 2-second delay.

**Fix (minimal):** Move the property assignments into `writeProc`'s `onStreamFinished` to update only after hardware confirms:

```qml
// BacklightService.qml — revised writeProc
Process {
    id: writeProc
    running: false
    stdout: StdioCollector {
        onStreamFinished: {
            // Read-back is already triggered below; UI update here is also fine
            // but properties should NOT be set before write starts
        }
    }
}
```

Then remove lines 48-49 from the debounce handler — the re-read at line 64-66 (`pollTimer.restart(); readProc.running = true`) will update properties when the read completes.

---

### WR-03: Four services use `$HOME` shell expansion for script paths

**Files:**
- `.config/quickshell/services/ForecastService.qml:22`
- `.config/quickshell/services/MemoryService.qml:23`
- `.config/quickshell/services/PingService.qml:23`
- `.config/quickshell/services/WeatherService.qml:22`

**Issue:** All four services invoke external scripts by passing a path through `bash -c` via `$HOME` expansion:

```qml
command: ["bash", "-c", "$HOME/.config/waybar/scripts/weather/forcast_weather.sh"]
```

This creates a shell dependency for what should be a static file path. If `$HOME` contains spaces or special characters (e.g., `/home/user name`), the path breaks. Additionally, referencing `$HOME` assumes the environment variable is always set in the process context — which is true in practice for interactive shells but inconsistent with the security principle of using explicit paths.

The scripts are static assets installed during dotfiles setup; the path does not vary at runtime.

**Fix:** Resolve the path programmatically:

```qml
// Using process environment via Quickshell or plain QML
command: ["bash", "-c", Qt.getenv("HOME") + "/.config/waybar/scripts/weather/forcast_weather.sh"]
```

Or better, if the scripts are migrated into the quickshell config directory:

```qml
command: [Qt.getenv("HOME") + "/.config/waybar/scripts/weather/forcast_weather.sh"]
```

(No `bash -c` wrapper needed for a single script invocation — Quickshell's Process accepts an argument array directly.)

---

## Info

### IN-01: Duplicated padding formatting logic across three services

**Files:**
- `.config/quickshell/services/BacklightService.qml:32,49`
- `.config/quickshell/services/CpuService.qml:30`
- `.config/quickshell/services/NotificationService.qml:29`

**Issue:** The output-padding pattern `(pct < 10 ? "  " : pct < 100 ? " " : "") + pct + "%"` is duplicated verbatim in BacklightService (twice) and CpuService. NotificationService has a similar variant (`(val < 10 ? " " : "") + String(val)`).

This is a textbook candidate for a shared utility function. The padding logic is non-trivial enough that inconsistency would cause visual alignment bugs across widgets.

**Fix:** Define in a shared module (e.g., `services/Utils.qml` or inline in a helper):

```qml
// Shared utility singleton
pragma Singleton
import Quickshell
Singleton {
    function padPercent(val) {
        return (val < 10 ? "  " : val < 100 ? " " : "") + Math.round(val) + "%"
    }
    function padCount(val) {
        return (val < 10 ? " " : "") + String(val)
    }
}
```

---

### IN-02: Inconsistent error handling — BacklightService is the only service without "err" fallback

**Files:**
- `.config/quickshell/services/BacklightService.qml:26-35`
- `.config/quickshell/services/CpuService.qml:31-35`
- `.config/quickshell/services/DiskService.qml:32-37`
- `.config/quickshell/services/ForecastService.qml:29-31`
- `.config/quickshell/services/MemoryService.qml:31-33`
- `.config/quickshell/services/PingService.qml:31-34`
- `.config/quickshell/services/WeatherService.qml:29-31`

**Issue:** All seven other services set properties to `"err"` (or equivalent) in catch blocks and/or validation-else branches. BacklightService is the sole outlier with an empty catch and no else fallback.

While this issue is subsumed by CR-01 (the empty catch), it's worth noting as a consistency concern. If future services use BacklightService as a template, they'll inherit the broken error pattern.

**Fix:** Already covered by the fix in CR-01.

---

### IN-03: BacklightService — read command awk quoting is fragile

**File:** `.config/quickshell/services/BacklightService.qml:25`

**Issue:** The read command has heavily escaped quotes inside a shell string:

```qml
command: ["bash", "-c", "ddcutil getvcp 10 2>/dev/null | awk '/current value/ {gsub(/,/,\"\",$9); print $9}'"]
```

The `gsub(/,/,\"\",$9)` is a maintenance hazard — the backslash escaping inside the double-quoted string is difficult to read, modify, and debug. If someone needs to change the awk logic, they're one typo away from breaking the shell escaping.

**Fix:** Use a small helper script file, or split the command into arguments:

```qml
// Option A: separate script file
command: [Qt.getenv("HOME") + "/.config/quickshell/scripts/backlight-read.sh"]

// Option B: use Process with piped commands won't work directly
// Better to keep as-is but document the escaping clearly
```

Given that the pipe from `ddcutil` to `awk` requires shell features, a separate script file is the cleanest solution.

---

### IN-04: BacklightService — `_pendingDelta` property should be private by convention

**File:** `.config/quickshell/services/BacklightService.qml:12`

**Issue:** The `_pendingDelta` property is prefixed with underscore (indicating private convention) but is declared as a plain `property int` rather than having any runtime protection. Another QML file could technically write to `BacklightService._pendingDelta` directly, bypassing the `adjustBrightness()` API.

This is a minor encapsulation concern. Not actionable without broader team convention.

---

## Cross-File Consistency Verification

| Check | Result |
|-------|--------|
| Service singletons in `services/qmldir` match widget imports | 13/13 ✓ |
| Widget types in `widgets/qmldir` match `BarContent.qml` usage | 14/14 ✓ |
| Widget services references (e.g., `CpuWidget → CpuService`) | 10/10 ✓ |
| Semantic color aliases used in correct widgets | 5/5 ✓ |
| VolumeOsd AudioService reference matches services/qmldir | ✓ |
| `ModulePill` base component in parent dir imported correctly | ✓ |
| `BarGroup` container component layout chain valid | ✓ |
| `.config/quickshell/popups/qmldir` missing (uses directory import instead) | OK — directory imports work without qmldir |

No missing service registrations, no widget-to-service mapping errors, no orphan type references.

---

_Reviewed: 2026-05-21T12:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
