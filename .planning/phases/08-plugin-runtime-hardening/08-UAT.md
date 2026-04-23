---
status: complete
phase: 08-plugin-runtime-hardening
source: 08-01-SUMMARY.md, 08-02-SUMMARY.md, 08-03-SUMMARY.md
started: 2026-04-24T00:00:00Z
updated: 2026-04-24T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Startup Clean — No Deprecation Warnings
expected: Run `./scripts/nvim-validate.sh startup`. Should PASS with no errors. No `vim.tbl_flatten` deprecation warning in output (BUG-016 fix via nvim-colorizer.lua removal).
result: pass

### 2. Health Validator All Green
expected: Run `./scripts/nvim-validate.sh health`. All 11 plugins report `loaded=true`, all 14 tools available, 0 problems. No false failure from neo-tree (neo-tree probe removed; snacks.explorer is the active replacement).
result: pass

### 3. Neovim Split Navigation
expected: Open two vertical splits in Neovim (outside tmux or inside tmux with Neovim focused). Press `<C-h>` and `<C-l>` to move between splits. Movement works cleanly — no double-binding error, no "not an editor command" message. `:verbose nmap <C-h>` shows only vim-tmux-navigator as the owner.
result: pass

### 4. Python LSP (pyright) Active
expected: Open a `.py` file. Hover over a symbol (`K`) shows pyright type info. Go-to-definition (`gd`) works. No "basedpyright" or LSP-not-attached errors. Mason has `pyright` installed (`:Mason` shows it).
result: pass

### 5. FocusLost Autosave Guard — Special Buffers
expected: Open a terminal buffer (`:terminal`), switch away (focus another app or split). No error "E32: No file name" or unexpected write attempt. The autosave guard should silently skip non-file buffers.
result: pass

### 6. Format-on-Save Skips Fugitive/Git Buffers
expected: Open a git commit message buffer (run `:Git commit` or `<leader>gc`). Write/save. No formatter runs — no delay, no "conform" error. The fugitive `acwrite` buffer saves normally as a plain text file.
result: pass

### 7. External-Open Error Surfaces (Linux)
expected: Press `<C-S-o>` on a URL or file path. If xdg-open or vim.ui.open is unavailable/misconfigured, a real error notification appears (e.g., "Failed to open: <OS error string>") rather than silent failure. (Note: BUG-020 — actual opening may still fail; the test is that the *error message* surfaces.)
result: pass

### 8. Snacks Search Workflows
expected: `<leader>ff` opens file finder, `<leader>fg` opens live grep, `<leader>fb` opens buffer picker. All three load, accept input, and navigate to selected results without errors.
result: pass

### 9. Git Workflow — Gitsigns and Lazygit
expected: In a file with git changes: `<leader>gp` previews the hunk, `<leader>gb` shows inline blame. `<leader>gg` (or configured key) opens lazygit full-screen and closes cleanly on `q`.
result: pass

### 10. LSP Workflow — Diagnostics and Format
expected: In a code file with an LSP attached: hover (`K`) shows docs, `gd` jumps to definition, `<leader>e` (or `]d`) shows the diagnostics float. `:Format` (or `<leader>lf`) runs conform without error. No stray LSP-attach errors in `:messages`.
result: pass

## Summary

total: 10
passed: 10
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
