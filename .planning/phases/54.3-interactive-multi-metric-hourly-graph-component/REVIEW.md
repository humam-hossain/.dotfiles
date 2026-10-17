---
phase: 54.3-interactive-multi-metric-hourly-graph-component
reviewed: 2026-10-15T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml
  - scripts/phase54.3-weather-assert.sh
  - .planning/phases/54.3-interactive-multi-metric-hourly-graph-component/54.3-UAT.md
  - .planning/phases/54.3-interactive-multi-metric-hourly-graph-component/54.3-07-SUMMARY.md
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 54.3 Plan 07: Code Review Report

**Reviewed:** 2026-10-15
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed plan 07 gap-closure edits (gutter 14→34 / plotTop 20→30, 3-row tooltip pill with background-only 0.75 alpha, harness Sections 3–4 gates, UAT scope note). Threat mitigations verify clean: T-54.3-11 parity holds (paint line 610 == scrub line 1042, strip margin line 1006 tracks), T-54.3-12 alpha sits on background-only `tooltipBackground` (line 953–959) with text siblings at full opacity, T-54.3-13 holds (no tab chrome, no metric writes — harness Section 2 gates intact). No secrets, injection, or auth surface. Findings are robustness/docs gaps only — advisory, never blocking.

## Warnings

### WR-01: Tooltip pill Y position can go negative (missing vertical clamp)

**File:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml:951`
**Issue:** `y` flips above the cursor when `activeScrubY >= 60` via `activeScrubY - implicitHeight - 8`, but unlike `x` (clamped 6px from edges) there is no lower clamp. With a ~65–75px pill, any `activeScrubY` in roughly 60–85px pushes `y` negative and the pill clips under the card top edge.
**Fix:** Clamp the result, mirroring the horizontal pattern:
```qml
y: Math.max(6, (root.activeScrubY < 60) ? (root.activeScrubY + 14) : (root.activeScrubY - implicitHeight - 8))
```

### WR-02: Harness gutter/tooltip gates prove presence, not the invariant (T-54.3-11/T-54.3-12 partially gapped)

**File:** `scripts/phase54.3-weather-assert.sh:482-514,632-636`
**Issue:** (a) Gutter parity asserts `grep -c 'const plotLeft = 34;' >= 2` — a count, not paint==scrub equality. A third stray `34` (comment, dead branch) would mask a real divergence, and the stale check only rejects the literal `14`, missing any other wrong value. (b) T-54.3-12 asserts 0.75 exists on `tooltipBackground` but never asserts text siblings lack opacity — adding `opacity: 0.75` to a `StyledText` later would keep the gate green while violating legibility.
**Fix:**
```bash
# exact parity: exactly 2 occurrences, and no other plotLeft value
[[ "$(grep -c 'const plotLeft = 34;' "$GRAPH_SRC")" -eq 2 ]] || fail "..."
[[ "$(grep -cE 'const plotLeft = [0-9]+;' "$GRAPH_SRC")" -eq 2 ]] || fail "..."
# text stays full opacity
! sed -n '/id: tooltipColumn/,/id: axisIconStrip/p' "$GRAPH_SRC" | grep -q 'opacity:' || fail "..."
```

### WR-03: SUMMARY claims G-54.3-1/G-54.3-3 CLOSED while UAT.md still records them failed/issue

**File:** `.planning/phases/54.3-interactive-multi-metric-hourly-graph-component/54.3-UAT.md:17,27,98-135`
**Issue:** `54.3-07-SUMMARY.md` (Accomplishments, lines 81–82) marks G-54.3-1/G-54.3-3 CLOSED, but `54.3-UAT.md` Tests 1 and 3 still read `result: issue` and both gaps still read `status: failed`. A verifier reading UAT truth will report gaps_found against a summary claiming closure — stale-truth divergence that can misroute the follow-up plan.
**Fix:** Either update Tests 1/3 to `result: pass` with re-test evidence plus gap `status: closed`, or downgrade the SUMMARY to "harness-gated, awaiting human re-test" and keep gaps open. Do one consistently.

## Info

### IN-01: Dead locals yMax/yMin computed but never used

**File:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml:770-771`
**Issue:** `yMax` (via `getMetricY("temp", -1, …)`, which by guard returns `plotBottom`) and `yMin` (algebraically `plotUpperBottom`) are never referenced — only `yHigh`/`yLow` are drawn. Dead math plus a confusing out-of-range probe call.
**Fix:** Delete both lines.

### IN-02: Unreachable per-metric branches retained under locked-temp scope

**File:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml:132-202,243-289,406-491`
**Issue:** `activeMetric` is locked to `"temp"` with zero writes (Section 2 gate), so `calcWindMax`/`calcBaroBounds`/`calcUvMax`, the wind/aqi/baro/uv arms of `getMetricY`, and the non-temp arms of `formatTooltipMetric` (including the still-fused temp string at line 404, now bypassed by the pill) are unreachable. Harmless but contradicts the "pruned branches" narrative and widens future confusion about what needs re-adding for stack-instances.
**Fix:** Add a one-line comment marking them `// retained for stack-instances follow-up (unreachable while activeMetric locked)` or delete and let the follow-up plan restore.

### IN-03: Gutter/headroom magic numbers triplicated with no single source

**File:** `restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml:610,616,1006,1042,1052`
**Issue:** `34` appears in paint, scrub, and `axisIconStrip.leftMargin`; `30` in paint and scrub; `0.60` tier split likewise duplicated. Canvas-JS scoping makes sharing awkward, but three unsynced edit sites plus a count-based harness gate is exactly how the original 14/34 skew happened.
**Fix:** Hoist to card-level readonly properties (e.g. `readonly property int gutterLeft: 34`) and reference from paint/scrub/strip; harness then asserts the property value once.

### IN-04: Harness Node extraction and pill-range fragility (local-only, low risk)

**File:** `scripts/phase54.3-weather-assert.sh:356-405,596-609`
**Issue:** (a) `node -e` interpolates `$GRAPH_SRC` into a single-quoted JS string — a path with a quote/space breaks the eval (local trusted path, low risk). (b) The `getMetricY` extraction regex depends on qmlformat's 4-space indent; reformatting silently breaks the headless math check fail-closed. (c) The `sed -n '/id: tooltipPill/,/id: scrubMouseArea/p'` ranges also swallow the intervening `axisIconStrip` block, so future token checks inside that range can false-positive. None affect current green; harden on next harness touch.
**Fix:** Pass the path via `argv`/env (`GRAPH_SRC="$GRAPH_SRC" node -e '...process.env.GRAPH_SRC...'`), anchor extraction on balanced braces, and bound pill ranges at `/id: tooltipColumn/` close instead of `scrubMouseArea`.

---

_Reviewed: 2026-10-15_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
