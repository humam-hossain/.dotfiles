---
phase: 10-validation-harness-expansion
plan: "04"
subsystem: validation
tags: [neovim, checkhealth, which-key, keymaps, whichkey, warning-audit, failures-inventory]

# Dependency graph
requires:
  - phase: 09-health-signal-cleanup
    provides: checkhealth subcommand, first audit artifact, classification approach for errors
  - phase: 06-runtime-failure-inventory
    provides: FAILURES.md living-doc pattern, D-12 status workflow
  - phase: 07-keymap-reliability-fixes
    provides: registry.lua with M.global/M.lazy mapping structure

provides:
  - FAILURES.md Phase 10 warning audit section with dispositions for all warning families
  - whichkey.lua fix skipping group registration for lhs values already owned by real mappings
  - Elimination of config-caused which-key duplicate-prefix warnings for <leader>e and <leader>b

affects: [future-checkhealth-audits, which-key-registration-pattern]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "which-key group registration skip: build 'claimed' set from global+lazy mappings; skip group add() when group_lhs is in claimed"
    - "Warning audit classification: config-caused vs environment-only vs optional-tool gap — same approach as Phase 9-01 for errors"

key-files:
  created: []
  modified:
    - .config/nvim/lua/core/keymaps/whichkey.lua (group registration skip for claimed lhs values)
    - .planning/phases/06-runtime-failure-inventory/FAILURES.md (Phase 10-04 warning audit section)

key-decisions:
  - "which-key duplicate-prefix warnings for <leader>e and <leader>b are config-caused: whichkey.lua registers group specs whose lhs is also a real mapping, generating which-key duplicates — fix by skipping group registration for claimed lhs values"
  - "All other warning families (20+) classified as By Design or Won't Fix: mason missing Ruby/PHP/Julia/Perl, lazy luarocks lua-5.1, render-markdown headless env, snacks headless env, vim.provider optional packages, vim.deprecated from project.nvim third-party, treesitter filetype gaps"
  - "Validator headless constraint documented: nvim-validate.sh checkhealth loads deployed ~/.config/nvim for Lua modules even with worktree -u flag; fix correctness verified via logic simulation rather than post-fix checkhealth re-run"

patterns-established:
  - "Pattern: which-key group registration guard — collect all mapping lhs values into a 'claimed' set before registering group specs; skip any group whose <leader><prefix> appears in claimed"

requirements-completed:
  - TEST-03

# Metrics
duration: 3min
completed: 2026-04-23
---

# Phase 10 Plan 04: Warning Audit and which-key Duplicate Fix Summary

**Fresh checkhealth warning audit classified 20+ warning families across all providers; config-caused which-key duplicate-prefix warnings for `<leader>e` and `<leader>b` fixed by adding a claimed-lhs guard to group registration in `whichkey.lua`.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-23T01:06:24Z
- **Completed:** 2026-04-23T01:09:34Z
- **Tasks:** 2 of 2 complete
- **Files modified:** 2

## Accomplishments

- Ran `./scripts/nvim-validate.sh checkhealth` to refresh `.planning/tmp/nvim-validate/checkhealth.txt` as required by D-14
- Classified all current WARNING families in FAILURES.md: 20+ entries across blink.cmp, config/core, lazy.nvim, mason, render-markdown, snacks, vim.deprecated, vim.provider, which-key, and treesitter filetype providers
- Identified two config-caused warnings: `which-key` "Duplicates for `<leader>e`" and "Duplicates for `<leader>b`" — both caused by `whichkey.lua` registering group specs for prefixes that are also real mapping lhs values
- Fixed `whichkey.lua`: added pre-registration claimed-lhs set built from `M.global` and `M.lazy` mappings; group registration now skips any `<leader><prefix>` already owned by a real mapping
- Verified fix logic correctly skips exactly `<leader>e` (Explorer group, owned by `explorer.toggle` in M.lazy) and `<leader>b` (Buffers group, owned by `buffer.new` in M.global), while all 6 remaining groups (`f`, `c`, `g`, `w`, `t`, `s`) are still registered correctly

## Task Commits

1. **Task 1: Warning audit and FAILURES.md classification** — `160d0f0` (docs)
2. **Task 2: whichkey.lua duplicate-prefix fix** — `ad62b87` (fix)

## Files Created/Modified

- `.config/nvim/lua/core/keymaps/whichkey.lua` — Added claimed-lhs set construction before group loop; group registration skips when exact `<leader><prefix>` lhs is in claimed set
- `.planning/phases/06-runtime-failure-inventory/FAILURES.md` — Added Phase 10-04 warning audit table with 20+ warning families, all classified; two config-caused entries marked Fixed (Task 2); all others marked By Design or Won't Fix

## Decisions Made

- **which-key duplicate source confirmed**: Root cause is that `registry.groups` includes `{ prefix = "e", label = "Explorer" }` and `{ prefix = "b", label = "Buffers" }`, leading `whichkey.lua` to call `which_key.add({ { "<leader>e", group = "Explorer" } })`. At the same time, the mapping registration loops also add `{ "<leader>e", desc = "Toggle file explorer" }` (from M.lazy) and `{ "<leader>b", desc = "New buffer" }` (from M.global). which-key detects two registrations for the same lhs and warns.
- **Fix approach chosen**: Build a claimed set from all M.global and M.lazy lhs values before the group loop; skip `which_key.add()` for any group whose computed lhs is in claimed. This is minimal — only prevents the group-spec add, leaving description registration fully intact. The real mapping description (with correct desc) remains registered.
- **Headless constraint noted**: `nvim-validate.sh checkhealth` loads Lua modules from `~/.config/nvim` (deployed config) even when `-u` points to the worktree, because `~/.config/nvim` comes first in rtp. Fix correctness was verified via logic simulation (`claimed` set output against live registry data) rather than relying on a post-fix headless re-run that would still show the old deployed state.

## Deviations from Plan

None — plan executed exactly as written. The fresh audit confirmed which-key duplicate-prefix warnings are config-caused, and the fix was applied as planned. All other warnings classified as By Design or Won't Fix per D-15/D-16.

## Issues Encountered

**Headless test environment constraint:** `nvim-validate.sh checkhealth` always loads Lua modules from the deployed `~/.config/nvim` (which comes first in rtp), not from the worktree config. This means a post-fix checkhealth re-run would still show the old duplicate warnings until the fix is deployed. This is a pre-existing constraint of the validation harness design — not a new issue. Fix correctness was confirmed via direct logic simulation against live registry data (Neovim headless Lua execution proving `<leader>e` and `<leader>b` are correctly in the claimed set).

## Known Stubs

None — fix is fully implemented. Deployment to `~/.config/nvim` via dotfiles rollout is the normal path for the fix to take effect on the running machine.

## Next Phase Readiness

- Phase 10-04 work complete: config-caused which-key warning noise removed, all other warning families documented
- FAILURES.md is a complete living document reflecting the current warning state
- The remaining checkhealth warnings (By Design and Won't Fix) are all documented with clear rationale

## Self-Check

Files modified verified:
- `.config/nvim/lua/core/keymaps/whichkey.lua`: `claimed` set construction and group skip guard present
- `.planning/phases/06-runtime-failure-inventory/FAILURES.md`: Phase 10-04 warning audit section present

Commits verified:
- `160d0f0`: docs(10-04) Task 1 — FAILURES.md warning audit
- `ad62b87`: fix(10-04) Task 2 — whichkey.lua duplicate fix

## Self-Check: PASSED

---
*Phase: 10-validation-harness-expansion*
*Completed: 2026-04-23*
