# DEBUG: STT duration timer stuck at 0:00 during recording (G-37-6)

**Status:** root_cause_found  
**Phase:** 37-bar-layout-integration-dual-monitor-verification-strict-pack  
**Gap:** G-37-6  
**Discovered:** UAT test 6

## Symptoms

- expected: When speaking (STT recording active), the duration timer increments and displays elapsed recording time (0:01, 0:02...) instead of remaining at 0:00.
- actual: User reported: "for sst specifically when i am speaking the timer doesnt start like its in 000 seconds so why is that i think this need to be fixed other than that everything else is working smoothly. this is not the issue in TTS for TTS is working completely fine there's no problem for TTS."
- reproduction: Trigger STT (`voice --toggle` or `SUPER + SHIFT + M`). Speak for several seconds. Observe the VoicePill text counter in the status bar.

## Root Cause

In `restow/quickshell/.config/quickshell/ii/services/Voice.qml`, `updateDuration()` initializes `startTime` via `recoverStartTime(activePid)`:

```javascript
function recoverStartTime(pid) {
    if (pid > 0) {
        sttStatFile.reload();
        uptimeFile.reload();
        const statText = sttStatFile.text().trim();
        const uptimeText = uptimeFile.text().trim();
        const lastParen = statText.lastIndexOf(")");
        if (lastParen !== -1 && uptimeText.length > 0) {
            const rest = statText.substring(lastParen + 1).trim().split(/\s+/);
            const startTicks = parseFloat(rest[19]); // Index 19 after comm is field 22
            const uptimeSec = parseFloat(uptimeText.split(/\s+/)[0]);
            if (!isNaN(startTicks) && !isNaN(uptimeSec)) {
                const elapsedSec = uptimeSec - (startTicks / 100.0);
                return Date.now() - (elapsedSec * 1000);
            }
        }
    }
    return Date.now();
}
```

Two compounding issues exist here:
1. **Unbounded / Negative `elapsedSec` calculation**: Because `/proc/<pid>/stat` field 22 (`startTicks`) and `/proc/uptime` are read at slightly different instants and use different kernel clock sources (jiffies vs boottime), `startTicks / 100.0` can exceed `uptimeSec` by a fractional amount or drift if reading is delayed, resulting in `elapsedSec < 0`. This sets `startTime` into the future (`Date.now() - negative = Date.now() + offset`). Consequently, `Math.max(0, Date.now() - startTime)` yields `0` for seconds or even longer, locking `formattedDuration` at `"0:00"`.
2. **Asymmetry with TTS**: In TTS, `activePid` is `ttsPid`. However, `recoverStartTime` only ever inspects `sttStatFile` (which binds to `path: root.sttPid > 0 ? ... : ""`). During TTS, `root.sttPid` is 0, so `sttStatFile.text()` is empty and `recoverStartTime` immediately falls back to line 136: `return Date.now()`. Setting `startTime = Date.now()` directly avoids procfs drift entirely, which is why TTS works flawlessly.
3. **Overuse of reload-recovery during live recording**: `recoverStartTime` was designed strictly for shell recovery when Quickshell reloads mid-recording. During normal recording started while Quickshell is already running, `Date.now()` at the moment of the `idle -> recording` transition is the exact start time.

## Evidence

- `Voice.qml` L85-89: `sttStatFile` binds strictly to `root.sttPid`. No `ttsStatFile` exists.
- `Voice.qml` L119-137: `recoverStartTime` does no sanity check (`elapsedSec <= 0 || elapsedSec > maxDurationSeconds`) and returns future timestamps if `elapsedSec < 0`.
- `Voice.qml` L140-150: `if (startTime <= 0)` runs once; once set (even to a future time), `startTime` remains until state returns to `idle`.
- User observation: TTS works completely fine (because it defaults to `Date.now()`), while STT fails.

## Files Involved

- `restow/quickshell/.config/quickshell/ii/services/Voice.qml`: `recoverStartTime` and `updateDuration` logic.

## Suggested Fix Direction

1. In `Voice.qml`, ensure `elapsedSec` is clamped (`const elapsedSec = Math.max(0, uptimeSec - (startTicks / 100.0))`).
2. When starting a fresh recording during an active shell session (detected on state change to `recording`), initialize `startTime = Date.now()`. Only call `recoverStartTime` if recovering an already-in-flight process where `startTime` was never initialized.
3. Alternatively, make `recoverStartTime` validate that `elapsedSec >= 0 && elapsedSec < maxDurationSeconds`; if negative or invalid, default cleanly to `Date.now()`.
