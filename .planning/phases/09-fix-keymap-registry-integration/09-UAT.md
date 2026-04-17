---
status: complete
phase: 09-fix-keymap-registry-integration
source: [09-01-SUMMARY.md, 09-02-SUMMARY.md]
started: 2026-04-17T00:00:00Z
updated: 2026-04-17T12:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Which-key group labels
expected: Press `<leader>` in normal mode and hold. Which-key popup shows labeled groups: f=Search, c=Code/LSP, g=Git, e=Explorer, b=Buffers, w=Windows, t=Toggles, s=Save.
result: issue
reported: "popup shows up at the bottom, keys are like: f → +11 keymaps, c → +6 keymaps, g → +7 keymaps, e → Toggle File Explorer, b → New Buffer, w → +2 keymaps, t → +1 keymaps, s → +2 keymaps"
severity: major

### 2. Snacks explorer toggle
expected: Press `<leader>e` in normal mode. Snacks file explorer panel opens (not neo-tree). Panel shows current directory file tree. Press again and it closes.
result: pass

### 3. Git status picker
expected: Press `<leader>gs` in normal mode. Snacks picker opens showing git-changed files (modified/staged/untracked). Selecting a file opens it.
result: issue
reported: "works but constantly throwing treesitter error: vim/treesitter.lua:196: attempt to call method 'range' (a nil value) — originates from snacks picker diff preview/highlight pipeline"
severity: minor

### 4. Buffer list picker
expected: Press `<leader>,` in normal mode. Snacks picker opens listing open buffers. Selecting one switches to that buffer.
result: pass
note: "which-key popup appears first, then pressing , from popup opens buffer list — working as expected"

### 5. Git log picker
expected: Press `<leader>gl` in normal mode. Snacks picker opens showing git log (commits). Can navigate/select commits.
result: pass

### 6. Git branches picker
expected: Press `<leader>gb` in normal mode. Snacks picker opens listing git branches. Can navigate/select to switch.
result: pass

### 7. Git diff picker
expected: Press `<leader>gd` in normal mode. Snacks picker opens showing diff hunks for current repo.
result: issue
reported: "E5108: Lua: registry.lua:509: attempt to call field 'diffs' (a nil value) — Snacks.picker.diffs() does not exist"
severity: blocker

## Summary

total: 7
passed: 4
issues: 3
skipped: 0
pending: 0

## Gaps

- truth: "Which-key popup shows labeled groups: f=Search, c=Code/LSP, g=Git, e=Explorer, b=Buffers, w=Windows, t=Toggles, s=Save"
  status: failed
  reason: "User reported: popup shows +N keymaps counts instead of group labels; e shows 'Toggle File Explorer', b shows 'New Buffer'"
  severity: major
  test: 1
  artifacts: [.config/nvim/lua/core/keymaps/whichkey.lua]
  missing: []

- truth: "Git status picker opens without errors"
  status: failed
  reason: "User reported: works but constantly throwing treesitter error — vim/treesitter.lua:196: attempt to call method 'range' (a nil value) — from snacks picker diff preview/highlight pipeline"
  severity: minor
  test: 3
  artifacts: []
  missing: []

- truth: "<leader>gd opens Snacks diff picker"
  status: failed
  reason: "User reported: E5108 — Snacks.picker.diffs() is nil, wrong API call in registry.lua:509"
  severity: blocker
  test: 7
  artifacts: [.config/nvim/lua/core/keymaps/registry.lua]
  missing: []
