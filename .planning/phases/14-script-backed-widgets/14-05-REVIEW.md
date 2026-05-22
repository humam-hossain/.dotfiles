---
phase: 14-script-backed-widgets
plan: 05
reviewed: 2026-05-22T10:15:00Z
depth: deep
files_reviewed: 22
files_reviewed_list:
  - .config/quickshell/Bar.qml
  - .config/quickshell/BarContent.qml
  - .config/quickshell/popups/VolumeOsd.qml
  - .config/quickshell/services/AudioService.qml
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
  - .config/quickshell/widgets/DiskWidget.qml
  - .config/quickshell/widgets/ForecastWidget.qml
  - .config/quickshell/widgets/MemoryWidget.qml
  - .config/quickshell/widgets/MusicWidget.qml
  - .config/quickshell/widgets/NetworkWidget.qml
  - .config/quickshell/widgets/PingWidget.qml
  - .config/quickshell/widgets/VolumeWidget.qml
  - .config/quickshell/widgets/WeatherWidget.qml
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Plan 14-05: Code Review Report — Gap Closure Commit

**Reviewed:** 2026-05-22T10:15:00Z
**Depth:** deep
**Files Reviewed:** 22 (all source files from commit e5f27e3)
**Status:** issues_found

## Summary

Reviewed commit e5f27e3 which closes 9 UAT gaps across quickshell services and widgets. The commit makes service properties writable (readonly→property), replaces strftime format strings with Qt-compatible specifiers, adds CPU delta sampling, and pipes AudioService through a polling Timer workaround for Quickshell bug #807.

**Primary concern: Regression of a previously-reviewed fix.** WR-03 from the earlier code review (14-REVIEW.md) was fixed in commit ccc86f2, replacing `$HOME` shell expansion with `Qt.getenv("HOME")` path resolution in four services. Commit e5f27e3 reverts all four back to `$HOME` expansion, undoing the fix. This is the most significant finding.

**Secondary concern: Inconsistent error handling for `startDetached()`.** DiskWidget and NetworkWidget were updated with try/catch around `startDetached()`, but PingWidget and VolumeWidget were missed, creating two unhandled exception paths.

---

## Warnings

### WR-01: Regression — `$HOME` shell expansion reverted in four services (WR-03 undiagnosed)

**Files:**
- `.config/quickshell/services/ForecastService.qml:22`
- `.config/quickshell/services/MemoryService.qml:23`
- `.config/quickshell/services/PingService.qml:23`
- `.config/quickshell/services/WeatherService.qml:22`

**Issue:** Commit ccc86f2 explicitly fixed these four services to resolve `$HOME` shell expansion via `Qt.getenv("HOME")`. Commit e5f27e3 reverts all four back to `"$HOME/..."` expansion inside `bash -c`, undoing the reviewed and approved fix.

This is a defense-in-depth concern:
1. `$HOME` containing spaces, special chars, or symlinks can break shell path resolution
2. Environment variable `$HOME` may not be set identically in all contexts (unlikely in practice, but the prior fix specifically addressed this)
3. The prior review noted this pattern as a defense-in-depth violation

The regression is confirmed by examining the diff:

```
- command: ["bash", "-c", Qt.getenv("HOME") + "/.config/waybar/scripts/..."]
+ command: ["bash", "-c", "$HOME/.config/waybar/scripts/..."]
```

**Why it happened:** This commit's bulk readonly-removal operation on all services appears to have touched these lines unintentionally. The four services with script-path commands were modified to make properties writable, and the path format was simultaneously reverted.

**Fix:** Restore `Qt.getenv("HOME")` path resolution:

```qml
command: ["bash", "-c", Qt.getenv("HOME") + "/.config/waybar/scripts/weather/forcast_weather.sh"]
```

Apply identical change to all four services.

---

### WR-02: Missing try/catch around `startDetached()` in PingWidget

**File:** `.config/quickshell/widgets/PingWidget.qml:44`

**Issue:** This commit added try/catch error handling for `startDetached()` in DiskWidget (`nautilusProc`) and NetworkWidget (`nmtuiProc`), but **missed PingWidget**. The `browserProc.startDetached()` call at line 44 has no try/catch:

```qml
onClicked: browserProc.startDetached()
```

If `xdg-open` is not installed, fails, or throws, the exception propagates unhandled. The commit description lists "DiskWidget: try/catch startDetached()" and "NetworkWidget: try/catch startDetached()" as intentional changes, indicating the omission is an oversight.

**Fix:** Wrap in try/catch matching the pattern used in DiskWidget/NetworkWidget:

```qml
onClicked: {
    try {
        browserProc.startDetached()
    } catch (e) {
        console.warn("PingWidget: failed to launch browser:", e)
    }
}
```

---

### WR-03: Missing try/catch around `pavucontrolProc.startDetached()` in VolumeWidget

**File:** `.config/quickshell/widgets/VolumeWidget.qml:52`

**Issue:** Same pattern as WR-02 — `pavucontrolProc.startDetached()` at line 52 has no try/catch. If `pavucontrol` is not installed or fails to launch, the error is unhandled:

```qml
if (mouse.button === Qt.LeftButton)       pavucontrolProc.startDetached()
```

This is the same defect pattern that was fixed in DiskWidget and NetworkWidget but was overlooked here.

**Fix:** Wrap in try/catch:

```qml
if (mouse.button === Qt.LeftButton) {
    try {
        pavucontrolProc.startDetached()
    } catch (e) {
        console.warn("VolumeWidget: failed to launch pavucontrol:", e)
    }
}
```

---

### WR-04: VolumeWidget icon condition has dead code branch

**File:** `.config/quickshell/widgets/VolumeWidget.qml:21-24`

**Issue:** The icon selection logic has two sequential conditions that return the same value `""`:

```qml
text: {
    if (AudioService.muted || AudioService.volumePercent === 0) return ""
    if (AudioService.volumePercent < 33)                         return ""
    if (AudioService.volumePercent < 66)                         return ""   // ← dead code branch
    return ""
}
```

The second `if (AudioService.volumePercent < 33)` condition is redundant — any value that passes the first condition (not 0) and fails the second (>=33) still returns "" via the third condition. The condition `< 33` is functionally identical to dead code because `< 66` subsumes it.

**Behavior is correct** (all values 1-65 → "", 66-100 → ""), but the dead branch is misleading to maintainers. A future reader might adjust one branch and not the other, introducing a visual inconsistency.

**Fix:** Consolidate the redundant branches:

```qml
text: {
    if (AudioService.muted || AudioService.volumePercent === 0) return ""
    if (AudioService.volumePercent < 66)                         return ""
    return ""
}
```

---

## Info

### IN-01: VolumeOsd.qml — no-op division by 1.0

**File:** `.config/quickshell/popups/VolumeOsd.qml:35`

**Issue:** The progress bar width calculation divides by 1.0 unnecessarily:

```qml
width: parent.width * (AudioService.volume / 1.0)
```

`AudioService.volume` is already a real value in range `0.0-1.0`. The `/ 1.0` is a no-op that wastes CPU cycles on every binding evaluation. This is likely a leftover from when `volume` was treated as a percentage (0-100) and the division normalized it.

**Fix:** Remove the no-op division:

```qml
width: parent.width * AudioService.volume
```

---

### IN-02: ClockService.qml — `rawDate` property uses `var` instead of `date` type

**File:** `.config/quickshell/services/ClockService.qml:10`

**Issue:** The `rawDate` property is declared as `property var rawDate: new Date()`. Using `var` bypasses QML's type system for date values. The property should use the `date` QML type for type safety and proper date coercion in bindings:

```qml
property var rawDate: new Date()
```

**Fix:** Use the native `date` QML type:

```qml
property date rawDate: new Date()
```

Note: If consumers bind to this property expecting a `Date` object with methods like `.getHours()`, the `var` type preserves the object reference. Changing to `date` stores a date value (which may lose prototype methods). Verify consumers before changing.

---

### IN-03: CpuService.qml — `__prevIdle`/`__prevTotal` properties trigger unnecessary change notifications

**File:** `.config/quickshell/services/CpuService.qml:11-12`

**Issue:** The delta-sampling state variables are declared as QML properties:

```qml
property int __prevIdle: -1
property int __prevTotal: -1
```

Because they are `property int`, QML creates change notification signals (`__prevIdleChanged`, `__prevTotalChanged`) and evaluates any bindings that read them. These are internal state variables only used within `onStreamFinished` and should not trigger binding re-evaluations. No widget binds to these — they're purely computational scratch space.

**Alternative:** If Quickshell/QtQml supports it, wrap these in a non-property `QtObject` to avoid signal overhead:

```qml
QtObject {
    id: d
    property int prevIdle: -1
    property int prevTotal: -1
}
```

However, this is speculative — `QtObject` members are still QML properties and would still generate signals. A true private variable in QML is not possible without helper JS modules. This is a low-priority concern.

---

## Verification Against Prior Review Fixes

| Previous Finding | Fix Commit | Status in e5f27e3 |
|---|---|---|
| CR-01: BacklightService empty catch | a329173 | ✓ Preserved (only readonly→mutable changed) |
| CR-02: Shell string concatenation | d1d5b13 | ✓ Preserved |
| WR-01: _pendingDelta never reset | e07de7f | ✓ Preserved |
| WR-02: Optimistic UI update | 3e4869e | ✓ Preserved |
| WR-03: $HOME shell expansion | ccc86f2 | **✗ REVERTED** — four services back to `$HOME/...` (see WR-01 above) |

One of five previously-reviewed-and-fixed issues has regressed in this commit.

---

_Reviewed: 2026-05-22T10:15:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
