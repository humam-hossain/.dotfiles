---
status: testing
phase: 02-central-command-and-keymap-architecture
source: [02-01-SUMMARY.md, 02-02-SUMMARY.md, 02-03-SUMMARY.md]
started: 2026-04-14T19:21:02Z
updated: 2026-04-14T19:22:00Z
---

## Current Test

<!-- OVERWRITE each test - shows where we are -->

number: 1
name: Cold Start Smoke Test
expected: |
  Nvim opens without errors. Registry loads, keymaps apply, no startup errors.
result: issue
reported: "Error in init.lua: registry.lua:734: module 'fzf-lua' not found"
severity: blocker

## Tests

### 1. Cold Start Smoke Test
expected: Nvim opens without errors. Registry loads, keymaps apply, no startup errors.
result: issue
reported: "Error in /home/pera/.config/nvim/init.lua: E5113: Lua chunk: /home/pera/.config/nvim/lua/core/keymaps/registry.lua:734: module 'fzf-lua' not found. Stack: require() → registry.lua:734 → apply.lua:7 → keymaps.lua:38 → init.lua:2"
severity: blocker

### 2. Registry-driven search keymaps work
expected: <leader>ff opens fzf-lua file picker. <leader>fg opens live grep. <leader>fc opens config finder.
result: [pending]

### 3. LSP keymaps attach on LspAttach
expected: <leader>cr shows code references via fzf-lua. <leader>cd goes to definition. <leader>ca opens code actions.
result: [pending]

### 4. Which-key domain groups visible
expected: Pressing <leader> then waiting shows domain groups: [f]ind, [c]ode, [g]it, [e]xplorer, [b]uffers, [w]indows, [t]oggles, [s]ave.
result: [pending]

### 5. Plugin keymaps from registry (fold/explorer)
expected: UFO fold keymaps work (zR/zM). Neo-tree toggle works.
result: [pending]

## Summary

total: 5
passed: 0
issues: 1
pending: 4
skipped: 0

## Gaps

- truth: "Nvim opens without errors. Registry loads, keymaps apply."
  status: failed
  reason: "User reported: registry.lua:734: module 'fzf-lua' not found — bare require() in action field evaluated at module load time before lazy.nvim loads plugins"
  severity: blocker
  test: 1
  artifacts:
    - .config/nvim/lua/core/keymaps/registry.lua:734
    - .config/nvim/lua/core/keymaps/registry.lua:744
    - .config/nvim/lua/core/keymaps/registry.lua:754
    - .config/nvim/lua/core/keymaps/registry.lua:764
    - .config/nvim/lua/core/keymaps/registry.lua:784
    - .config/nvim/lua/core/keymaps/registry.lua:794
  missing:
    - action fields for buffer-scope LSP entries must wrap require() in function() closures
