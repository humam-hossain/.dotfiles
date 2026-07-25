---
phase: 03-system-audio-modules
status: clean
reviewed: "2026-07-23T18:43:29Z"
depth: quick
scope: gap-closure 03-09 + 03-10
files_reviewed: 4
files_reviewed_list:
  - .config/hypr/hyprland/scripts/launch_first_available.sh
  - .config/quickshell/modules/common/Appearance.qml
  - .config/quickshell/modules/ii/bar/Resource.qml
  - .config/quickshell/services/ResourceUsage.qml
findings:
  critical: 0
  warning: 1
  info: 1
  total: 2
note: "Gap-closure re-review of plans 03-09 and 03-10 only. Prior phase baseline (plans 03-01..03-08) remains clean — see Prior Baseline below."
---

# Phase 03: Code Review Report (Gap-Closure Re-Review)

**Reviewed:** 2026-07-23T18:43:29Z  
**Depth:** quick  
**Scope:** gap-closure 03-09 + 03-10  
**Files Reviewed:** 4  
**Status:** clean (no blockers; 1 warning, 1 info)

## Summary

Adversarial re-review of the UAT gap-closure delta only (plans 03-09 and 03-10). Scoped files:

| File | Plan | Change under review |
|------|------|---------------------|
| `Appearance.qml` | 03-09 | `colWarning` amber token |
| `Resource.qml` | 03-09 | warning bind + dynamic 4/2 spacing |
| `ResourceUsage.qml` | 03-09 | `formatPair` single-unit labels |
| `launch_first_available.sh` | 03-10 | first-PATH launcher for volumeMixer |

**Verdict:** No critical/blocker defects. One maintainability warning (duplicate `formatPair` left by stacked 03-09 commits). Launcher script is correctly quoted and safe for fixed Config argv. Prior phase baseline remains clean.

## Prior Baseline (plans 03-01..03-08)

Previous review (`reviewed: 2026-07-23T12:55:00Z`, scope BAR-05..08 product files) found **no blockers**. Non-blocking notes retained for context:

1. volumeMixer via `bash -c Config.options.apps.volumeMixer` — Config-sourced, not bar text.
2. ResourceUsage Timer `interval: 1` first-tick then reassigns — intentional.
3. `alwaysShowAllResources` retained for API compatibility.
4. df Process false→true restart pattern gated ~10s.
5. Pre-existing ToolbarTabBar TypeError / polkit WARN on smoke — unrelated.
6. ResourcesPopup.qml left on disk unused (D-09).

This gap-closure pass does **not** re-litigate those items.

## Quick-scan Results

| Pattern class | Result |
|---------------|--------|
| Hardcoded secrets | none |
| Dangerous functions (`eval`, shell_exec, etc.) | none in delta |
| Debug artifacts (TODO/FIXME/console.log) | none |
| Empty catch blocks | none |
| Shell unquoted expansions | none — `"$cmd"` / `"$@"` correctly quoted |

## Warnings

### WR-01: Duplicate `formatPair` definitions (dead override)

**File:** `.config/quickshell/services/ResourceUsage.qml:59-67` and `:78-88`  
**Severity:** WARNING  
**Issue:** Two identically named `function formatPair(...)` blocks exist in the same Singleton. Git history shows:

1. `9092da8` (feat 03-09) introduced the second definition (lines 78–88, `bytesA`/`bytesB` + `Math.max`).
2. `58a4af5` (fix 03-09) inserted another definition *above* `kbToGbString` (lines 59–67, `aBytes`/`bBytes` + `a >= tib \|\| b >= tib`) without removing the first.

In QML/JS object scope the later binding wins, so runtime labels currently use the second body. Behavior is equivalent today (same TB/GB promotion rule), but:

- Editing the first copy has **no effect** (silent dead code).
- Future divergence between the two bodies would be hard to spot.
- Signals a incomplete merge of stacked task commits rather than intentional dual helpers.

**Fix:** Keep a single definition; delete the other.

```qml
/**
 * Pair label: "used/total UNIT" with single shared unit suffix (D-15, G-03-2).
 * Unit from larger value: TB when ≥ 1 TiB, else GB.
 */
function formatPair(bytesA, bytesB) {
    const a = Number(bytesA) || 0
    const b = Number(bytesB) || 0
    const tib = 1024 * 1024 * 1024 * 1024
    const larger = Math.max(a, b)
    if (larger >= tib) {
        return (a / tib).toFixed(1) + "/" + (b / tib).toFixed(1) + " TB"
    }
    const gib = 1024 * 1024 * 1024
    return (a / gib).toFixed(1) + "/" + (b / gib).toFixed(1) + " GB"
}
```

Call sites at lines 34–35 (`memoryUsedTotalString`, `diskFreeTotalString`) need no change.

## Info

### IN-01: Launcher does not forward extra argv to the chosen binary

**File:** `.config/hypr/hyprland/scripts/launch_first_available.sh:6-9`  
**Severity:** INFO  
**Issue:** `exec "$cmd"` launches the bare binary with no additional arguments. Config usage is binary-name-only (`pavucontrol-qt` / `pavucontrol`), so current volumeMixer path is fine. If a future Config value needs flags (e.g. `pavucontrol --tab 3`), this script cannot express that without redesign.

**Fix:** Only if needed later — e.g. treat first matching token as command and pass remaining `"$@"` after a `--` separator. Out of scope for G-03-8.

## Files Reviewed (detail)

### `.config/hypr/hyprland/scripts/launch_first_available.sh` (03-10)

- Shebang `#!/usr/bin/env bash`; executable bit set.
- Iterates `"$@"`; `command -v "$cmd"` then `exec "$cmd"` — no word-splitting, no shell metacharacter evaluation of the command name.
- Fail path: stderr message + exit 1 when none found. Smoke-tested: missing binaries → exit 1; `true` → exit 0.
- Trust model: invoked via Config `apps.volumeMixer` through existing `bash -c` (tilde expands under bash). Same trust boundary as prior phase review — not free-form bar input.

### `.config/quickshell/modules/common/Appearance.qml` (03-09)

- `colWarning: "#FFB74D"` at line 211 under `colors` QtObject, adjacent to `colError*`.
- Comment documents Material amber-300 rationale (D-07). No secrets, no side effects.

### `.config/quickshell/modules/ii/bar/Resource.qml` (03-09)

- Threshold ladder: `isError` → `isWarning` → default (lines 20–21, 38–42).
- Warning ring binds `Appearance.colors.colWarning` (not `colPrimary`) — closes G-03-1.
- Dynamic spacing: `labelText.length > 0 ? 4 : 2` (line 26) — closes G-03 spacing gap.
- TextMetrics still bind to displayed string to avoid capacity-label clip.

### `.config/quickshell/services/ResourceUsage.qml` (03-09)

- Call sites use shared-unit `formatPair` (closes G-03-2 double-unit labels).
- **WR-01** duplicate function — only defect in this delta.
- Remainder of multi-rate poll / df argv / LANG=C parse path is pre-existing phase work (out of re-scope except as call-chain context).

## Security (gap-closure delta)

| Area | Assessment |
|------|------------|
| `launch_first_available.sh` argv | Quoted; `exec` of command name only; no `eval` |
| Config → volumeMixer | Still Config dual-write path; script does not widen trust |
| Appearance hex token | Static color; no injection surface |
| ResourceUsage formatters | Pure numeric formatting; no process spawn in delta |

No new high-severity issues.

## Critical Issues

None.

---

_Reviewed: 2026-07-23T18:43:29Z_  
_Reviewer: Claude (gsd-code-reviewer)_  
_Depth: quick_  
_Scope: gap-closure 03-09 + 03-10_
