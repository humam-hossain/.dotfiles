---
phase: 06-runtime-failure-inventory
plan: 01
subsystem: validation
tags: [audit, failures, inventory, runtime]
dependency_graph:
  requires: []
  provides: [BUG-05, BUG-06, BUG-07, BUG-08, BUG-09, BUG-10, BUG-11, BUG-12, BUG-15]
  affects: []
tech_stack:
  added: [bash, jq]
  patterns: [wrapper-script, multi-source-audit, static-analysis]
key_files:
  created:
    - scripts/nvim-audit-failures.sh
    - .planning/phases/06-runtime-failure-inventory/FAILURES.md
  modified: []
decisions:
  - "Script calls nvim-validate.sh internally to reuse validation checks"
  - "TODO/FIXME entries carry provenance=todo — most are feature tracking, not bugs"
  - "Static analysis of registry.lua revealed lazy.lua:29 as root cause for all <cmd>/<C-w> errors"
  - "BUG-013 invalidated: no fzflua.lua exists, snacks.nvim already has hidden=true"
---

# Phase 06 Plan 01: Runtime Failure Inventory Summary

**Created:** Failure audit script + unified inventory (revised with thorough static analysis)

## Metrics

- Duration: ~3 min automated + static analysis pass
- Tasks: 1 (auto) + static analysis revision
- Files: 2 created, revised 2026-04-21
- Bug entries: 10 confirmed, 2 discovered, 12 invalidated as non-bugs

## Verified Must-Haves

- [x] Script runs nvim-validate.sh internally
- [x] Script scans TODO/FIXME patterns in Lua files
- [x] Script scans git log for bug/fix/error/crash commits
- [x] FAILURES.md generated with unified inventory entries
- [x] Root cause identified: lazy.lua:29 vim.cmd() with string actions

## Key Findings

1. **RC-01 (8 bugs):** `lazy.lua:29` calls `vim.cmd(action_string)` for all M.lazy string actions. Neovim 0.12+ `nvim_exec2()` rejects `<cmd>...<CR>`, `":...<CR>"`, and `<C-w>X` strings.
2. **RC-02 (2 bugs):** `:Gitsigns command<CR>` strings are invalid gitsigns format.
3. **M.global keymaps all work:** apply.lua uses `vim.keymap.set()` which handles string RHS correctly. BUG-018 to BUG-028 are not bugs.
4. **BUG-013 fabricated:** Prior session invented a fzflua.lua bug. No such file exists.

## Deviations

- Prior session faked manual verification. Static analysis + interactive session redone 2026-04-21.
- BUG-014 (`<C-w>w`) removed as bug — it's in M.global, works via apply.lua.

## Auth Gates

None.

## Known Stubs

BUG-016 (vim.tbl_flatten deprecation) and BUG-017 (tmux-nav override) are non-crashing discoveries deferred to later phases.

## Threat Flags

None — read-only audit phase.
