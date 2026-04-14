---
phase: 02-central-command-and-keymap-architecture
plan: "02"
type: execute
subsystem: keymap-architecture
tags:
  - keymaps
  - registry
  - lazy.nvim
  - lsp
key-files:
  created:
    - .config/nvim/lua/core/keymaps/lazy.lua
    - .config/nvim/lua/core/keymaps/attach.lua
  modified:
    - .config/nvim/lua/plugins/fzflua.lua
    - .config/nvim/lua/plugins/lsp.lua
    - .config/nvim/lua/plugins/ufo.lua
    - .config/nvim/lua/plugins/neotree.lua
key-decisions:
  - "Plugin files now consume registry-generated keys instead of hand-owned keys tables"
  - "Buffer-local LSP mappings originate from central registry via attach helper"
  - "Fold and explorer keymaps apply from registry at config time"
requirements-completed:
  - KEY-01
  - KEY-02
  - KEY-03
---

# Phase 2 Plan 2: Migration of Plugin Mappings Summary

## Execution Summary

Migrated plugin entry points and buffer-local mappings under registry ownership while preserving lazy-loading and buffer/plugin-local semantics.

## Tasks Executed

| Task | Status | Description |
|------|--------|-------------|
| 1 | ✓ Complete | Created lazy.lua, refactored fzflua/ufo/neotree to use registry |
| 2 | ✓ Complete | Created attach.lua, refactored lsp.lua to use registry-driven buffer-local mappings |

## Files Created

- `.config/nvim/lua/core/keymaps/lazy.lua` — Compiler from registry entries to lazy.nvim key specs
- `.config/nvim/lua/core/keymaps/attach.lua` — Shared helpers for buffer-local LSP and plugin-local attachment

## Files Modified

- `.config/nvim/lua/plugins/fzflua.lua` — Now consumes `require("core.keymaps.lazy").search_keys()`
- `.config/nvim/lua/plugins/lsp.lua` — Uses `attach.apply_lsp()` for buffer-local mappings
- `.config/nvim/lua/plugins/ufo.lua` — Applies fold keys from registry
- `.config/nvim/lua/plugins/neotree.lua` — Applies explorer keys from registry

## Verification Results

```
✓ test -f .config/nvim/lua/core/keymaps/lazy.lua
✓ test -f .config/nvim/lua/core/keymaps/attach.lua
✓ rg "core\.keymaps\.lazy" fzflua.lua
✓ rg "core\.keymaps\.attach" lsp.lua
✓ rg -c "local map = function" lsp.lua = 0 (removed)
```

## Deviations

None — plan executed as written.

## Phase Readiness

Plan 02-02 complete. Ready for Plan 02-03 (documentation and duplicate-removal audit).