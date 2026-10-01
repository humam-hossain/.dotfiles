---
status: resolved
updated: "2026-10-01T17:30:00+06:00"
---

# Debug Session: Pill Free Total GB Display

## ROOT CAUSE FOUND

**Debug Session:** .planning/debug/pill-free-total-gb-display.md

**Root Cause:**
`MemoryStoragePill.qml` was implemented using dual circular progress rings (`ClippedFilledCircularProgress`) with percentage readouts (`${Math.round(memoryUsedPercentage * 100)}%` and storage percent) instead of user-requested free GB out of total GB capacity readouts (`free GB / total GB`) for both Memory and Root Storage.

**Evidence Summary:**
- Lines 47-117 in `MemoryStoragePill.qml` implement circular progress ring with `text: ${Math.round((ResourceUsage.memoryUsedPercentage || 0.0) * 100)}%`.
- Lines 120-190 in `MemoryStoragePill.qml` implement circular progress ring with `text: ${StorageUsage.rootDisk?.usePercent ?? 0}%`.
- User explicit requirement: "the memory it should be this GB free out of this this amount of GB of memory the percentage is not important here and for the storage it should be the same and it should be the main the root storage this GB and that GB this GB free out of this total GB and the rest is for the pop-up".

**Files Involved:**
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/MemoryStoragePill.qml`: Displays circular progress rings and percentage strings instead of free GB / total GB text for RAM and Root Disk.

**Suggested Fix Direction:**
Update `MemoryStoragePill.qml` to display text readouts showing free GB out of total GB for memory (using `ResourceUsage.memoryAvailable` or `memoryFree` converted to GB) and root storage (using `StorageUsage.rootDisk.availKb` and `totalKb` converted to GB), while retaining icons and alert coloring/animations.
