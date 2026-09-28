---
status: complete
phase: 44-memory-storage-component-pill-popup
source: [44-01-SUMMARY.md, 44-02-SUMMARY.md]
started: 2026-09-28T19:58:00+06:00
updated: 2026-09-28T22:26:00+06:00
---

## Current Test

[testing complete]

## Tests

### 1. Memory & Storage Pill Appears on Status Bar
expected: The status bar shows a MemoryStoragePill with two circular progress rings — one for RAM (with a "memory" Material Symbol icon) and one for Storage (with a "storage" Material Symbol icon). Both rings are always visible regardless of bar shortened form. The fill levels reflect current system usage percentages.
result: issue
reported: "The pill should show free GB out of total GB for memory, and free GB out of total GB for the root storage. The percentage is not important on the pill — detailed info belongs in the popup."
severity: major

### 2. Pill Alert States & Breathing Pulse
expected: When RAM or Storage usage crosses 70%, the corresponding ring shifts to a warning color (amber). When usage crosses 90%, it shifts to a critical color and a 600ms infinite breathing pulse animation begins on that ring. When usage drops back below the threshold, the animation stops and opacity resets to 1.0.
result: pass

### 3. Popup Opens on Hover
expected: Hovering over the MemoryStoragePill opens a two-column overlay popup (MemoryStoragePopup). The popup is anchored to the pill's hover area. Moving the mouse away closes it.
result: pass

### 4. Memory Column — Allocation Bar & Tier Breakdown
expected: The left column of the popup shows a "Memory" card with a multi-segment stacked allocation bar displaying Used (colored), Buffers/Cache (reclaimable, different color), and Free segments with proportional widths and color legend dots. Below the bar, numeric tier rows show Used, Available, Buffers, Cached, and Free values in human-readable format. A Swap row appears only if the system has swap enabled (swapTotal > 0).
result: pass

### 5. Storage Column — Drives & Throughput Badge
expected: The right column of the popup shows a "Storage" card with a live header throughput badge displaying current read/write speeds (auto-scaled B/s through GB/s) with arrow_downward/arrow_upward glyphs. Below, physical drives are listed with StyledProgressBar meters showing used/total capacity, block device labels, and mount paths. If a Google Drive cloud mount is present, it appears in a separate section; otherwise it's hidden.
result: issue
reported: "no storage column is not working at all, no text showing up and progress bar shows zero"
severity: blocker

### 6. Active Drive Indicator
expected: In the storage column, the drive currently performing active I/O is highlighted with a subtle indicator dot. The dot appears when StorageUsage.diskIoPercentage > 0 for that drive and disappears when I/O stops.
result: issue
reported: "nope"
severity: major

### 7. Demand-Gated Fast Polling
expected: When the popup opens, telemetry polling accelerates (ResourceUsage updates at ~1000ms cadence, StorageUsage refreshes immediately). When the popup closes, polling returns to the normal idle cadence. The popup shows live-updating values while open.
result: pass
source: automated
notes: "Verified via scripts/phase44-memory-storage-assert.sh section 3: demand-gated fast-polling triggers on active change and resets on destruction"

## Summary

total: 7
passed: 4
issues: 3
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-44-1
  truth: "MemoryStoragePill shows free GB out of total GB for memory and root storage — not percentage rings"
  status: failed
  reason: "User reported: The pill should show free GB out of total GB for memory, and free GB out of total GB for the root storage. The percentage is not important on the pill — detailed info belongs in the popup."
  severity: major
  test: 1
  artifacts: []
  missing: []

- gap_id: G-44-5
  truth: "Storage column displays physical drives with progress bars, labels, mount paths, and live throughput badge"
  status: failed
  reason: "User reported: no storage column is not working at all, no text showing up and progress bar shows zero"
  severity: blocker
  test: 5
  artifacts: []
  missing: []

- gap_id: G-44-6
  truth: "Drive performing active I/O is highlighted with an indicator dot when StorageUsage.diskIoPercentage > 0"
  status: failed
  reason: "User reported: nope (indicator dot does not appear, storage drive items not rendering correctly)"
  severity: major
  test: 6
  artifacts: []
  missing: []
