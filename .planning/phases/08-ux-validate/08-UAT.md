---
status: partial
phase: 08-ux-validate
source: [08-01-SUMMARY.md]
started: 2026-04-16T12:23:10Z
updated: 2026-04-16T12:23:15Z
---

## Current Test

[testing complete]

## Tests

### 1. Snacks Dashboard on Neovim Launch
expected: Launch Neovim with no file argument. Snacks dashboard should appear as the startup screen instead of alpha.nvim.
result: pass
note: "Fixed: cleaned lazy-lock.json, removed deprecated plugins, updated arch/nvim.sh"

### 2. Snacks Notifications Work
expected: When an LSP server attaches or a long operation completes, a Snacks notification appears at the bottom-right.
result: blocked
blocked_by: server
reason: "LspStart/LspRestart commands unavailable — lua_ls not auto-attaching"

### 3. Statusline Visible
expected: Statusline (lualine) is visible at bottom of window. Shows current mode, git branch, LSP status, etc.
result: pass
note: "User requested enhancement: add last key pressed + last register display on right side"

### 4. Search Keys Open Snacks Picker
expected: <leader>ff opens Snacks file picker. <leader>fg opens Snacks grep picker. Results are navigable with j/k.
result: pass

### 5. Rollout Docs Readable
expected: README.md in .config/nvim/ contains: rollout section, machine checklist, post-deploy checks, rollback instructions.
result: pass

## Summary

total: 5
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 1

## Gaps

- truth: "Snacks dashboard appears on Neovim launch instead of alpha"
  status: resolved
  reason: "Fixed: cleaned lazy-lock.json, removed deprecated plugins, updated arch/nvim.sh"
  severity: major
  test: 1
  root_cause: "lazy-lock.json contained deprecated plugins that remained installed"
  artifacts: []
  missing: []
  debug_session: ".planning/debug/snacks-dashboard-alpha.md"

## Additional Fixes

- **Cmdline UI:** Re-added noice.nvim (minimal config) for cmdline popup at bottom-left
- **Rollout script:** Updated arch/nvim.sh to use rsync --delete and remove deprecated plugins
