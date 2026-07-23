---
phase: 03-system-audio-modules
plan: 06
subsystem: ui
tags: [quickshell, qml, resources-strip, cpu, ram, disk, dual-threshold, bar-05, bar-06, bar-07]

requires:
  - phase: 03-system-audio-modules
    provides: dual-write thresholds (03-02), Resource.qml errorThreshold+labelText (03-03), disk metrics+formatBytes (03-05)
provides:
  - Resources.qml CPU→RAM→Disk strip with dual thresholds and capacity labels
  - Display-only strip (no ResourcesPopup, no click)
  - Swap removed from bar UI
affects:
  - 03-08 (nyquist / UAT of BAR-05..07 strip)
  - Future resources detail phase (ResourcesPopup.qml left on disk unused)

tech-stack:
  added: []
  patterns:
    - "Strip order L→R: planner_review (CPU) → memory (RAM) → hard_drive (Disk)"
    - "CPU labelText empty → default N%; RAM/Disk bind ResourceUsage capacity strings"
    - "Display-only Item root (no MouseArea popup host)"

key-files:
  created: []
  modified:
    - .config/quickshell/modules/ii/bar/Resources.qml

key-decisions:
  - "Disk iconName: hard_drive (standard Material Symbol; no prior ii disk icon)"
  - "Root is Item not MouseArea — no hover/click surface for Phase 3"
  - "alwaysShowAllResources kept for BarContent assignment API; shown:true always"

patterns-established:
  - "Resources strip productization wires Config dual thresholds + ResourceUsage helpers only"
  - "ResourcesPopup.qml retained on disk, unattached until detail phase"

requirements-completed: [BAR-05, BAR-06, BAR-07]

coverage:
  - id: D1
    description: "Resource strip order is CPU → RAM → Disk with no swap_horiz"
    requirement: BAR-05
    verification:
      - kind: other
        ref: "rg -n 'Resource \\{|iconName:|swap_horiz' .config/quickshell/modules/ii/bar/Resources.qml"
        status: pass
    human_judgment: false
  - id: D2
    description: "CPU/RAM/Disk dual thresholds from Config; RAM/Disk capacity labelText; diskUsedPercentage ring"
    requirement: BAR-06
    verification:
      - kind: other
        ref: "rg -n 'errorThreshold|labelText|diskUsedPercentage' .config/quickshell/modules/ii/bar/Resources.qml"
        status: pass
    human_judgment: false
  - id: D3
    description: "No ResourcesPopup; display-only Item; Configuration Loaded"
    requirement: BAR-07
    verification:
      - kind: other
        ref: "rg -n 'ResourcesPopup|onClicked|hoverEnabled' .config/quickshell/modules/ii/bar/Resources.qml (no matches)"
        status: pass
      - kind: other
        ref: "timeout 6 quickshell → Configuration Loaded"
        status: pass
    human_judgment: false

duration: 2min
completed: 2026-07-23
status: complete
---

# Phase 3 Plan 06: Resources Strip Productization Summary

**Resources.qml productized as always-visible CPU→RAM→Disk rings with dual Config thresholds, capacity labels, and no swap/popup/click.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-07-23T11:45:23Z
- **Completed:** 2026-07-23T11:47:36Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Strip order L→R is CPU (`planner_review`) → RAM (`memory`) → Disk (`hard_drive`); swap removed
- Dual thresholds wired: CPU 40/80, RAM 75/95, Disk 80/95 from `Config.options.bar.resources`
- Labels: CPU default `N%`; RAM `memoryUsedTotalString`; Disk `diskFreeTotalString` (free/total, no mount path)
- Always shown (`shown: true`); no MPRIS media-hide
- `ResourcesPopup` detached; root converted to display-only `Item` (D-09, D-25)

## Task Commits

Each task was committed atomically:

1. **Task 1: Rebuild strip CPU→RAM→Disk with dual thresholds and labels** - `b84db3c` (feat)
2. **Task 2: Disable ResourcesPopup and strip interactivity** - `8433953` (feat)
3. **Task 2 fix: keep alwaysShowAllResources for BarContent API** - `eb4ad54` (fix)

**Plan metadata:** `a525aae` (docs: complete plan)

_Note: TDD not used for this plan (`tdd: false`)_

## Files Created/Modified
- `.config/quickshell/modules/ii/bar/Resources.qml` — productized strip; Item root; three Resource children only
- `ResourcesPopup.qml` — left on disk unused (not deleted)

## Decisions Made
- Disk Material icon: `hard_drive` (no existing ii disk symbol; plan allowed hard_drive/storage)
- Keep `alwaysShowAllResources` property even though unused for hide logic — BarContent still assigns it
- Vertical-bar twin left unchanged (plan: optional only if trivial; primary surface is ii horizontal bar)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored `alwaysShowAllResources` property after Task 2**
- **Found during:** Task 2 (Disable ResourcesPopup / convert to Item)
- **Issue:** Removing the property broke shell load: `BarContent.qml` assigns `alwaysShowAllResources: root.useShortenedForm === 2` → `Cannot assign to non-existent property`
- **Fix:** Re-added `property bool alwaysShowAllResources: false` with comment that strip always shows (D-05)
- **Files modified:** `.config/quickshell/modules/ii/bar/Resources.qml`
- **Verification:** `timeout 6 quickshell` → `Configuration Loaded`
- **Committed in:** `eb4ad54`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary for shell load; no scope creep. Strip behavior still matches D-05 (always shown).

## Issues Encountered
- First Task-2 smoke failed on missing `alwaysShowAllResources` — fixed immediately (above)
- Pre-existing `ToolbarTabBar.qml` TypeError warnings during smoke — out of scope (unrelated WIP; not staged)

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- BAR-05/06/07 bar strip productization complete for Phase 3
- Remaining Phase 3: 03-08 validation (03-07 audio already done)
- ResourcesPopup available for future detail phase without reimplementation

## Self-Check: PASSED

- FOUND: `.config/quickshell/modules/ii/bar/Resources.qml`
- FOUND: commits `b84db3c`, `8433953`, `eb4ad54`
- Smoke: Configuration Loaded
- No `swap_horiz`, `ResourcesPopup`, `MprisController`, `onClicked` in Resources.qml

---
*Phase: 03-system-audio-modules*
*Completed: 2026-07-23*
