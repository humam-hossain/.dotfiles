# Debug Session: Service Data Issues

## Root Cause
Three confirmed code-level defects in service singleton implementations:

### 1. BacklightService `readonly` blocks assignment
- `.config/quickshell/services/BacklightService.qml:9-10`: `brightnessPercent` and `formatted` declared `readonly`
- `.config/quickshell/services/BacklightService.qml:31-32`: Runtime assignment throws QML error
- Impact: "throwing error" (Test 7) + "data is wrong and has errors" (Test 1)

### 2. CpuService reads cumulative `/proc/stat` without delta sampling
- `.config/quickshell/services/CpuService.qml:22`: Each poll reads total CPU time since boot
- Between 3-second intervals, value changes by ~0.01%, appearing frozen
- Impact: "not responsive enough" (Test 2)

### 3. ClockService - strftime syntax incompatible with Qt QML *(handled by separate debug agent)*

## Evidence
- BacklightService.qml:9-10: `readonly property int brightnessPercent: 0`
- BacklightService.qml:31: `root.brightnessPercent = val` → WILL THROW
- CpuService.qml:22: No delta sampling logic

## Files Involved
- `.config/quickshell/services/BacklightService.qml` — Remove `readonly` (lines 9-10)
- `.config/quickshell/services/CpuService.qml` — Add delta-sampling (line 22)

## Fix Direction
1. BacklightService: Change `readonly property` to `property`
2. CpuService: Store prev_idle + prev_total, compute delta in `onStreamFinished`
