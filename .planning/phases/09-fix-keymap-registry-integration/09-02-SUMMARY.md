---
phase: 09-fix-keymap-registry-integration
plan: "02"
subsystem: keymaps
tags:
  - keymaps
  - snacks
  - key-conflicts
key-files:
  modified:
    - .config/nvim/lua/core/keymaps/registry.lua
decisions:
  - "Changed search.buffers from <leader><leader> to <leader>, with domain 'b'"
  - "Added git picker keys: gl (log), gb (branches), gd (diffs)"
  - "LSP nav keys already use Snacks.picker (no changes needed)"
metrics:
  duration: null
  completed: "2026-04-17"
depends_on:
  - 09-01
---

# Plan 09-02: Snacks Key Layout Summary

## One-liner

Completed snacks key layout with git picker keys and resolved buffer picker key conflict.

## Completed Tasks

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 1bac699 | Verified explorer entries use Snacks (done in Wave 1) |
| 2 | 1bac699 | Resolved D-15: changed <leader><leader> to <leader>, |
| 3 | 1bac699 | Verified LSP nav keys use Snacks.picker (already correct) |
| 4 | 1bac699 | Added git picker keys: gl, gb, gd |

## Deviations from Plan

None — plan executed exactly as written.

## Key Changes

1. **registry.lua** — Key conflict resolution (D-15):
   - Removed `search.buffers` entry with `<leader><leader>`
   - Added `buffers.list` entry with `<leader>,` and domain "b"

2. **registry.lua** — Git picker keys added:
   - `git.log`: `<leader>gl` → `Snacks.picker.git_log()`
   - `git.branches`: `<leader>gb` → `Snacks.picker.git_branches()`
   - `git.diff`: `<leader>gd` → `Snacks.picker.diffs()`

3. **LSP nav keys** — Verified already using Snacks.picker:
   - `lsp.definition` → `Snacks.picker.lsp_definitions()`
   - `lsp.references` → `Snacks.picker.lsp_references()`
   - `lsp.implementations` → `Snacks.picker.lsp_implementations()`
   - `lsp.typedefs` → `Snacks.picker.lsp_type_definitions()`

## Verification

```bash
# Buffer picker key
grep -E "buffers.*<leader>,|<leader>,.*buffers" .config/nvim/lua/core/keymaps/registry.lua

# Git picker keys
grep -E "git_log|git_branches|diffs" .config/nvim/lua/core/keymaps/registry.lua

# Count Snacks references
grep -c "Snacks.picker\|Snacks.explorer" .config/nvim/lua/core/keymaps/registry.lua
```

## Self-Check: PASSED

- [x] Explorer entries updated to Snacks (Wave 1)
- [x] Key conflict resolved — <leader>, bound to buffers picker
- [x] LSP nav using Snacks.picker (verified 4 keys)
- [x] Git picker keys added (3 keys: gl, gb, gd)
