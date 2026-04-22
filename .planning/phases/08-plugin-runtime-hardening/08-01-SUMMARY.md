---
phase: "08-plugin-runtime-hardening"
plan: "01"
subsystem: "nvim-config"
tags: ["plugin-config", "keymaps", "lsp", "health-validator", "bug-fix"]
dependency_graph:
  requires: []
  provides:
    - "registry.lua without window.move_* globals — vim-tmux-navigator owns <C-h/j/k/l>"
    - "nvim-validate.sh health probe list aligned to active plugins (no neo-tree)"
    - "lsp.lua with pyright in both lsp_servers and mason_lsp_servers"
    - "lazy-lock.json with nvim-colorizer.lua entry removed"
    - "startup log free of vim.tbl_flatten deprecation (BUG-016)"
  affects:
    - "Phase 8-02: crash-prone flow hardening can now assume clean baseline"
    - "Phase 8-03: health validator is a trustworthy gate for workflow verification"
tech_stack:
  added: []
  patterns:
    - "Plugin ownership boundary: remove registry globals that shadow plugin-managed keys"
    - "Probe list alignment: health validator probes only active-stack plugins"
    - "Surgical lockfile edit: remove one entry for one traced unmaintained plugin"
key_files:
  created: []
  modified:
    - ".config/nvim/lua/core/keymaps/registry.lua"
    - ".config/nvim/lua/core/health.lua"
    - "scripts/nvim-validate.sh"
    - ".config/nvim/lua/plugins/lsp.lua"
    - ".config/nvim/lua/plugins/misc.lua"
    - ".config/nvim/lazy-lock.json"
    - ".planning/phases/06-runtime-failure-inventory/FAILURES.md"
decisions:
  - "D-01/D-03: Remove 4 window.move_* registry globals; vim-tmux-navigator owns <C-h/j/k/l> unconditionally"
  - "D-07/D-08: nvim-colorizer.lua removed (unmaintained, unguarded tbl_flatten, non-critical)"
  - "D-09/D-10: neo-tree probe removed from nvim-validate.sh PLUGIN_LIST and cmd_smoke list"
  - "D-11/D-12: basedpyright replaced with pyright in both lsp_servers and mason_lsp_servers together"
metrics:
  duration_minutes: 4
  tasks_completed: 2
  tasks_total: 2
  files_modified: 7
  completed_date: "2026-04-22"
---

# Phase 8 Plan 01: Plugin Runtime Hardening — Baseline Fixes Summary

**One-liner:** Removed registry `<C-h/j/k/l>` ownership conflict, aligned health probe list to active stack, swapped basedpyright for pyright, and eliminated BUG-016 `vim.tbl_flatten` deprecation by removing unmaintained nvim-colorizer.lua.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Remove stale plugin ownership conflicts | 378125d | registry.lua, nvim-validate.sh |
| 2 | Reconcile Python LSP and clear BUG-016 deprecation | 22b1223 | lsp.lua, misc.lua, lazy-lock.json |
| docs | Update FAILURES.md with fix outcomes | e0d97a6 | FAILURES.md |

## What Was Built

### Task 1: Plugin Ownership Conflict Removal

**registry.lua — window.move_* removal (BUG-017, D-01/D-03):**
- Deleted all 4 `window.move_*` entries (`<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`) from `M.global`
- These startup-time mappings were shadowing `vim-tmux-navigator`'s plugin-managed bindings
- vim-tmux-navigator handles both Neovim split navigation and tmux pane crossing natively; no `$TMUX` guard needed (D-02)
- Plugin stays installed in `misc.lua` (D-03); this is a conflict resolution, not a plugin removal

**nvim-validate.sh — neo-tree probe removal (BUG-001, D-09):**
- Removed `'neo-tree'` from `PLUGIN_LIST` shell variable (used by `cmd_health`)
- Removed `'neo-tree'` from the inline Lua `plugins` table in `cmd_smoke`
- neo-tree was replaced by `snacks.explorer` in v1.0; the stale probe was producing false health failures
- Health validator now passes with zero plugin failures; all 11 probed plugins report `loaded=true`

### Task 2: Python LSP Reconciliation and BUG-016 Clearance

**lsp.lua — basedpyright → pyright (D-11/D-12):**
- Replaced `basedpyright = {}` with `pyright = {}` in `lsp_servers` table
- Replaced `"basedpyright"` with `"pyright"` in `mason_lsp_servers` list
- Both tables updated together so Mason provisions what LSP enables (no divergence)
- Preserves the partial user edit that had removed basedpyright without yet adding pyright

**nvim-colorizer.lua removal — BUG-016 fix (D-05/D-06/D-07):**

Trace result: BUG-016 `vim.tbl_flatten` deprecation traced to `norcalli/nvim-colorizer.lua`:
- `colorizer/nvim.lua:96` calls `vim.tbl_flatten {...}` unconditionally at startup
- Plugin loads at ~031ms in startuptime log (eager, via `plugin/colorizer.vim`)
- Plugin is unmaintained: last upstream commit `a065833`, no newer commits in the local clone
- Per D-07: removed as non-critical (color code highlighting; no keymaps, no core workflow dependency)
- Removed from `misc.lua` config block and from `lazy-lock.json` (surgical single-entry deletion)
- Startup log confirmed: `tbl_flatten` deprecation absent after removal; startup PASS

## Verification Results

| Check | Command | Result |
|-------|---------|--------|
| No window.move_* in registry | `rg -n 'window\.move_*' registry.lua` | PASS: 0 matches |
| No neo-tree in health/validator | `rg -n 'neo-tree' health.lua nvim-validate.sh` | PASS: 0 matches |
| vim-tmux-navigator stays installed | `rg -n 'vim-tmux-navigator' misc.lua` | PASS: still present |
| pyright in both lsp.lua tables | `rg -n 'pyright' lsp.lua` | PASS: lines 68, 89 |
| No basedpyright in lsp.lua | `rg -n 'basedpyright' lsp.lua` | PASS: 0 matches |
| lazy-lock.json single entry change | `git diff --stat lazy-lock.json` | PASS: 1 line removed |
| health validator | `./scripts/nvim-validate.sh health` | PASS: all plugins loaded, all tools available |
| startup validator | `./scripts/nvim-validate.sh startup` | PASS |
| tbl_flatten absent from startup.log | `grep tbl_flatten startup.log` | PASS: absent |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Updated FAILURES.md to reflect fix outcomes**
- **Found during:** Task 2 completion
- **Issue:** FAILURES.md is designated a "living doc" (06-CONTEXT.md D-12); BUG-001, BUG-016, BUG-017 remained marked Discovered/By Design after fixes landed
- **Fix:** Updated status column, Disposition Notes, and Summary section for all three bugs
- **Files modified:** `.planning/phases/06-runtime-failure-inventory/FAILURES.md`
- **Commit:** e0d97a6

**2. [Rule 1 - Bug] BUG-016 source was nvim-colorizer.lua, not nvim-treesitter**
- **Found during:** Task 2 BUG-016 trace step
- **Issue:** RESEARCH.md listed nvim-treesitter.compat as a candidate; actual trace showed colorizer loading at ~031ms with unguarded `vim.tbl_flatten` call; nvim-treesitter's compat.lua has a version guard (uses `vim.iter` on 0.11+) so it never fires the warning
- **Fix:** Applied D-07 fallback (remove non-critical unmaintained plugin) rather than D-06 pin bump (no upstream fix exists); documented actual plugin name in summary per plan instruction
- **Files modified:** `misc.lua`, `lazy-lock.json`
- **Commit:** 22b1223

## Known Stubs

None. All changes wire directly to runtime behavior.

## Threat Flags

No new security-relevant surface introduced. All changes remove or replace existing configuration.

## Self-Check: PASSED

All key files exist. All task commits present (378125d, 22b1223, e0d97a6). All acceptance criteria verified:
- No `window.move_*` globals in registry.lua
- No `neo-tree` in health.lua or nvim-validate.sh
- `pyright` present in both lsp_servers and mason_lsp_servers tables in lsp.lua
- No `basedpyright` remaining in lsp.lua
- Only one entry removed from lazy-lock.json
- Health validator PASS (all 11 plugins loaded, all tools available)
- Startup validator PASS, tbl_flatten deprecation absent from startup.log
