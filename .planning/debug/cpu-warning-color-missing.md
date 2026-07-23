# DEBUG: CPU warning color missing (G-03-1)

**Status:** root_cause_found  
**Phase:** 03-system-audio-modules  
**Gap:** G-03-1  
**Discovered:** UAT test 1

## Symptoms

- expected: Two-step ring colors per D-07 — warning ≥40%, error ≥80%
- actual: Above 80% goes reddish; no perceptible warning color in the warning band
- reproduction: Stress CPU into 40–79% and observe ring; then ≥80%

## Root Cause

`Resource.qml` warning tier binds to `Appearance.colors.colPrimary`, not a distinct warning token. Plan 03-03 intentionally locked this (no `colWarning` existed), but on the live theme `colPrimary` does not read as a warning state relative to the default ring color (`colOnSecondaryContainer`). Error tier (`colError`) is clearly reddish and is what the user sees.

Thresholds themselves are correct in live config (`cpuWarningThreshold: 40`, `cpuErrorThreshold: 80`) and wired in `Resources.qml`.

## Evidence

- `Resource.qml` L37–41: `isWarning ? Appearance.colors.colPrimary : …`
- `Appearance.qml`: has `colError`, `colPrimary`, `colTertiary` — no `colWarning`
- Live `~/.config/illogical-impulse/config.json`: CPU thresholds 40/80 present
- 03-CONTEXT D-07: “Use theme **warning** vs **error** colors”

## Files Involved

- `.config/quickshell/modules/ii/bar/Resource.qml` — warning color ladder
- `.config/quickshell/modules/common/Appearance.qml` — missing/underused warning token

## Suggested Fix Direction

Add a distinct `Appearance.colors.colWarning` (or reuse a clearly non-error accent such as a warm mix / tertiary) and bind the `isWarning` branch to it so 40–79% is visually distinct from default and from error.
