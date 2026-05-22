# Debug Session: Click/Popup Actions

## Root Cause A: DiskWidget "throws error" (Test 4)
`Process.startDetached()` is a void QML method that silently swallows failures. No error reporting when process fails.

## Root Cause B: NetworkWidget click does nothing (Test 5)
Same silent failure mechanism — `startDetached()` discards return value.

## Root Cause C: Volume OSD never appears (Test 12)
Pipewire binding propagation broken in Quickshell 0.2.1. `onVolumePercentChanged` never fires because `AudioService.volumePercent` doesn't emit change signal.

## Files Involved
- `.config/quickshell/widgets/DiskWidget.qml:33` — silent startDetached()
- `.config/quickshell/widgets/NetworkWidget.qml:38` — silent startDetached()
- `.config/quickshell/popups/VolumeOsd.qml` — correct popup, wrong trigger
- `.config/quickshell/services/AudioService.qml` — Pipewire binding chain broken

## Fix Direction
1. Add `console.warn()` or error handlers to startDetached() callers
2. Volume OSD: direct signal connection or wpctl fallback
