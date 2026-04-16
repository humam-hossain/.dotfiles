---
status: diagnosed
phase: 07-keymap-validate
source: [07-01-SUMMARY.md]
started: 2026-04-16T09:45:00Z
updated: 2026-04-16T10:15:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Snacks File Picker
expected: Press <leader>ff — Snacks picker opens showing file tree. Navigate with arrows/j/k, Enter opens file.
result: pass

### 2. Snacks Grep Picker
expected: Press <leader>fg — Snacks picker opens with grep prompt. Type query, Enter searches. Results shown.
result: pass

### 3. Snacks Git Picker
expected: Press <leader>gc — Snacks picker opens showing git commits or changes.
result: issue
reported: "<leader>gc not working. Only <leader>gg opens LazyGit without error"
severity: major

### 4. LSP Toggle Inlay Hints
expected: With LSP attached (e.g., open a .lua file), press <leader>th — inlay hints toggle on/off.
result: pass

### 5. Buffer Navigation Keys
expected: Press <leader>fb — opens buffer picker showing open buffers. Select one to switch.
result: skipped
reason: "Wrong expectation — <leader>fb is Find Builtin FZF. Buffers = <leader><leader>"

### 6. Window Navigation
expected: Press <leader>ww — cycles through windows. <leader>wm shows window picker.
result: issue
reported: "No such keymaps exist. Window navigation uses C-hjkl instead"
severity: minor

## Summary

total: 6
passed: 3
issues: 2
pending: 0
skipped: 1
blocked: 0

## Gaps

- truth: "<leader>gc opens Snacks git picker showing commits/changes"
  status: failed
  reason: "User reported: <leader>gc not working. Only <leader>gg opens LazyGit. No git commits/changes picker exists in registry."
  severity: major
  test: 3
  root_cause: "Phase 2 never planned/added <leader>gc. Snacks has no built-in git_commits picker. Neo-tree git_commit source exists (neotree.lua:299)."
  artifacts:
    - path: ".config/nvim/lua/plugins/snacks.lua"
      issue: "No git_commits picker in snacks picker list"
  missing:
    - "Add <leader>gc entry to registry.lua using neo-tree git_commit source"
  debug_session: ""

- truth: "<leader>ww/<leader>wm window picker exists"
  status: failed
  reason: "User reported: no such keymaps. Window navigation via C-hjkl exists but no leader-based window picker."
  severity: minor
  test: 6
  root_cause: "Phase 2 never planned/added <leader>ww or <leader>wm. nvim-window-picker already installed as neo-tree dependency."
  artifacts:
    - path: ".config/nvim/lua/plugins/neotree.lua"
      issue: "nvim-window-picker dependency present but not exposed as user keymap"
  missing:
    - "Add <leader>ww (cycle windows) using <C-w>w"
    - "Add <leader>wm (pick window) using window-picker plugin"
  debug_session: ""

