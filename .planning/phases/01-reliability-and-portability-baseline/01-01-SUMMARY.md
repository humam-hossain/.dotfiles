---
phase: 01-reliability-and-portability-baseline
plan: 01
subsystem: platform
tags: [neovim, cross-platform, vim.ui.open, portability]

# Dependency graph
requires: []
provides:
  - Shared OS-aware external open helper using vim.ui.open()
  - Core keymap wired to shared helper
  - Neo-tree custom action wired to shared helper
affects: [01-02, 01-03]

# Tech tracking
tech-stack:
  added: [vim.ui.open (Neovim built-in)]
  patterns: [Cross-platform external open via Neovim native API]

key-files:
  created: [.config/nvim/lua/core/open.lua]
  modified: [.config/nvim/lua/core/keymaps.lua, .config/nvim/lua/plugins/neotree.lua]

key-decisions:
  - "Used vim.ui.open() instead of hardcoded shell commands for cross-platform support"
  - "Created generic open_externally command name instead of browser-specific naming"

patterns-established:
  - "One shared helper for all external open behavior (core keymaps and neo-tree)"

requirements-completed: [PLAT-01, PLAT-02, PLAT-03, PLAT-04]

# Metrics
duration: 3min
completed: 2026-04-14
---

# Phase 01 Plan 01: External Open Helper Summary

**Shared OS-aware external open helper using vim.ui.open() for cross-platform support**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-14T16:45:00Z
- **Completed:** 2026-04-14T16:48:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Created `.config/nvim/lua/core/open.lua` with `open()` and `open_current_buffer()` functions using `vim.ui.open()`
- Rewired `<C-S-o>` keymap in keymaps.lua to use `core.open.open_current_buffer()`
- Renamed neo-tree command from `open_in_browser` to `open_externally` and wired it to shared helper
- Removed all hardcoded `xdg-open` and `vim.fn.jobstart` calls from both call sites

## Task Commits

Each task was committed atomically:

1. **Task 1 + 2: Shared helper + rewire** - `30d3fd6` (feat)

**Plan metadata:** N/A (sequential inline execution)

## Files Created/Modified
- `.config/nvim/lua/core/open.lua` - Shared OS-aware external open helper
- `.config/nvim/lua/core/keymaps.lua` - Rewired `<C-S-o>` to use helper
- `.config/nvim/lua/plugins/neotree.lua` - Renamed command to `open_externally`

## Decisions Made
- Used vim.ui.open() for cross-platform support (Linux, macOS, Windows)
- Named command `open_externally` per D-12 (generic external opening, not browser-specific)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## Next Phase Readiness
- Phase 1 external-open flows no longer depend on hardcoded Linux-only commands
- Both global keymap and neo-tree custom action use the same shared helper
- Ready for Plan 01-02 (save/quit behavior simplification)

---
*Phase: 01-reliability-and-portability-baseline*
*Completed: 2026-04-14*
