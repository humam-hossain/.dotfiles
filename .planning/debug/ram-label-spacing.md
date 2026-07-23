# DEBUG: RAM label format + resource spacing (G-03-2)

**Status:** root_cause_found  
**Phase:** 03-system-audio-modules  
**Gap:** G-03-2  
**Discovered:** UAT test 2

## Symptoms

- expected: `used/total GB` (or auto-human single unit); ring↔text spacing matching CPU
- actual: `GB / GB` style (unit on both sides); RAM/disk ring–text spacing feels wrong vs CPU

## Root Cause

1. **Double unit:** `ResourceUsage.memoryUsedTotalString` (and disk) concatenates two `formatBytes()` results, each of which already appends `" GB"` / `" TB"`:
   ```
   formatBytes(used) + "/" + formatBytes(total)  →  "12.3 GB/31.2 GB"
   ```
2. **Spacing:** `Resource.qml` uses fixed `RowLayout` `spacing: 2` for all modules. CPU labels are short (`N%`); capacity labels are long, so the same spacing reads tighter/wrong. Inter-module gap after CPU→RAM (`Layout.leftMargin: 6` on RAM/Disk) is fine per user.

## Evidence

- `ResourceUsage.qml` L34–35, L46–51
- `Resource.qml` L25 (`spacing: 2`), L61–81 (label TextMetrics)
- `Resources.qml` L33–50 (RAM/Disk `Layout.leftMargin: 6`)

## Files Involved

- `.config/quickshell/services/ResourceUsage.qml` — string format
- `.config/quickshell/modules/ii/bar/Resource.qml` — ring/label spacing
- `.config/quickshell/modules/ii/bar/Resources.qml` — optional per-module spacing tweak

## Suggested Fix Direction

- Format as `12.3/31.2 GB` (or auto unit once on the right): e.g. format both numbers then one unit suffix.
- Increase ring↔label spacing for capacity labels (or always use a slightly larger spacing that still looks good for CPU).
