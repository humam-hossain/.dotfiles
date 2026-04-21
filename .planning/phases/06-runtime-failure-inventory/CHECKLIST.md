# CHECKLIST.md — Interactive Verification Checklist

**Generated:** 2026-04-18
**Revised:** 2026-04-21
**Status:** Partial — confirmed bugs below, interactive session pending for colon-format keymaps and feature tests

---

## SECTION A: Already Confirmed (from prior session + static analysis)

### BUG-005 — `<cmd> enew <CR>` Leading Space → E488
**lhs:** `<leader>b` | **registry.lua:534**

Steps: Open Neovim → press `<leader>b`
Expected: New empty buffer opens
Error: `E5108: nvim_exec2(): Vim(<):E488: Trailing characters: cmd> enew <CR>`
Fix: Replace `"<cmd> enew <CR>"` with `function() vim.cmd("enew") end`

---

### BUG-006 — `<cmd>set wrap!<CR>` → E488
**lhs:** `<leader>lw` | **registry.lua:623**

Steps: Open Neovim → press `<leader>lw`
Expected: Line wrap toggles
Error: `E5108: nvim_exec2(): Vim(<):E488: Trailing characters: cmd>set wrap!<CR>`
Fix: Replace with `function() vim.wo.wrap = not vim.wo.wrap end`

---

### BUG-007 — `<cmd>noautocmd w <CR>` Trailing Space → E488
**lhs:** `<leader>sn` | **registry.lua:648**

Steps: Open a file → press `<leader>sn`
Expected: Saves without autocmds
Error: `E5108: nvim_exec2(): Vim(<):E488: Trailing characters: cmd>noautocmd w <CR>`
Fix: Replace with `function() vim.cmd("noautocmd w") end`

---

### BUG-008 — `":close<CR>"` → E488 Trailing Characters
**lhs:** `<leader>xs` | **registry.lua:586**
**Note:** Prior FAILURES.md had wrong action — actual action is `":close<CR>"` not `<cmd>enew`

Steps: Open a split → press `<leader>xs`
Expected: Closes the split
Error: `Vim(close):E488: Trailing characters: <CR>: :close<CR>`
Fix: Replace with `function() vim.cmd("close") end`

---

### BUG-009 — `<C-w>v` String RHS → E488
**lhs:** `<leader>v` | **registry.lua:556**

Steps: Press `<leader>v`
Expected: Vertical split
Error: `E5108: nvim_exec2(): Vim(<):E488: Trailing characters: C-w>v`
Fix: Replace with `function() vim.cmd("vsplit") end`

---

### BUG-010 — `<C-w>s` String RHS → E488
**lhs:** `<leader>h` | **registry.lua:566**

Steps: Press `<leader>h`
Expected: Horizontal split
Error: `E5108: nvim_exec2(): Vim(<):E488: Trailing characters: C-w>s`
Fix: Replace with `function() vim.cmd("split") end`

---

### BUG-011 — `<C-w>=` String RHS → E488
**lhs:** `<leader>se` | **registry.lua:576**

Steps: Open splits → press `<leader>se`
Expected: Windows equalized
Error: `E5108: nvim_exec2(): Vim(<):E488: Trailing characters: C-w>=`
Fix: Replace with `function() vim.cmd("wincmd =") end`

---

### BUG-012 — `:Gitsigns preview_hunk<CR>` Wrong Format
**lhs:** `<leader>gp` | **registry.lua:461**

Steps: Open file with git changes → press `<leader>gp`
Expected: Hunk preview popup
Error: `preview_hunk<CR> is not a valid function or action`
Fix: Replace with `function() require("gitsigns").preview_hunk() end`

---

## SECTION B: High-Confidence Discovered (Static Analysis — need confirmation)

### BUG-014 — `<C-w>w` String RHS → likely E488
**lhs:** `<leader>ww` | **registry.lua:167**

Steps: Open splits → press `<leader>ww`
Expected: Cycles to next window
[ ] PASS — works correctly
[ ] FAIL — E488 error (confirm and note exact error message)

---

### BUG-015 — `:Gitsigns toggle_current_line_blame<CR>` Wrong Format
**lhs:** `<leader>gt` | **registry.lua:471**

Steps: Open file with git history → press `<leader>gt`
Expected: Toggles inline git blame
[ ] PASS — blame toggles correctly
[ ] FAIL — error (confirm and note exact error message)

---

## SECTION C: Interactive Verification Required — Colon-Format Keymaps

These all use `":cmd<CR>"` string RHS. BUG-008 (`":close<CR>"`) confirmed broken.
Test each — mark PASS or FAIL with error message if failing.

### BUG-018 — `:wincmd k<CR>` — Window up
**lhs:** `<C-k>` | **registry.lua:127**

Steps: Open splits (`:vsplit`) → press `<C-k>`
Expected: Focus moves to window above
[ ] PASS
[ ] FAIL — error:

---

### BUG-019 — `:wincmd j<CR>` — Window down
**lhs:** `<C-j>` | **registry.lua:137**

Steps: Open splits → press `<C-j>`
Expected: Focus moves to window below
[ ] PASS
[ ] FAIL — error:

---

### BUG-020 — `:wincmd h<CR>` — Window left
**lhs:** `<C-h>` | **registry.lua:147**
**Note:** Also conflicts with vim-tmux-navigator (BUG-017)

Steps: Open vsplit → press `<C-h>`
Expected: Focus moves to left window
[ ] PASS
[ ] FAIL — error:
[ ] WRONG BEHAVIOR — vim-tmux-navigator taking over

---

### BUG-021 — `:wincmd l<CR>` — Window right
**lhs:** `<C-l>` | **registry.lua:157**
**Note:** Also conflicts with vim-tmux-navigator (BUG-017)

Steps: Open vsplit → press `<C-l>`
Expected: Focus moves to right window
[ ] PASS
[ ] FAIL — error:
[ ] WRONG BEHAVIOR — vim-tmux-navigator taking over

---

### BUG-022 — `:resize +2<CR>` — Resize up
**lhs:** `<Up>` | **registry.lua:179**

Steps: Open splits → press `<Up>`
Expected: Current window grows taller
[ ] PASS
[ ] FAIL — error:

---

### BUG-023 — `:resize -2<CR>` — Resize down
**lhs:** `<Down>` | **registry.lua:189**

Steps: Open splits → press `<Down>`
[ ] PASS
[ ] FAIL — error:

---

### BUG-024 — `:vertical resize +2<CR>` — Resize left
**lhs:** `<Left>` | **registry.lua:199**

Steps: Open vsplit → press `<Left>`
Expected: Current window grows wider
[ ] PASS
[ ] FAIL — error:

---

### BUG-025 — `:vertical resize -2<CR>` — Resize right
**lhs:** `<Right>` | **registry.lua:209**

Steps: Open vsplit → press `<Right>`
[ ] PASS
[ ] FAIL — error:

---

### BUG-026 — `:bnext<CR>` — Next buffer
**lhs:** `<Tab>` | **registry.lua:221**

Steps: Open 2+ buffers → press `<Tab>` in normal mode
Expected: Cycles to next buffer
[ ] PASS
[ ] FAIL — error:

---

### BUG-027 — `:bprevious<CR>` — Previous buffer
**lhs:** `<S-Tab>` | **registry.lua:231**

Steps: Open 2+ buffers → press `<S-Tab>` in normal mode
[ ] PASS
[ ] FAIL — error:

---

### BUG-028 — `:bdelete!<CR>` — Close buffer
**lhs:** `<leader>x` | **registry.lua:544**

Steps: Open a buffer → press `<leader>x`
Expected: Buffer closes
[ ] PASS
[ ] FAIL — error:

---

## SECTION D: Feature Tests (not yet covered)

These areas have not been tested at all in prior sessions.

### F-01 — LSP: Rename symbol
**lhs:** `<leader>cn` (on LSP buffer)

Steps: Open a .lua file, place cursor on a variable → `<leader>cn`
Expected: Rename prompt appears
[ ] PASS
[ ] FAIL

---

### F-02 — LSP: Code action
**lhs:** `<leader>ca` (on LSP buffer)

Steps: Open a .lua file, place cursor on code → `<leader>ca`
Expected: Code action menu appears
[ ] PASS
[ ] FAIL

---

### F-03 — Snacks Explorer toggle
**lhs:** `<leader>e`

Steps: Press `<leader>e`
Expected: File explorer opens/closes
[ ] PASS
[ ] FAIL

---

### F-04 — Snacks file picker
**lhs:** `<leader>ff`

Steps: Press `<leader>ff`
Expected: File picker opens with results including hidden files
[ ] PASS
[ ] FAIL

---

### F-05 — LazyGit integration
**lhs:** `<leader>gg`

Steps: Press `<leader>gg`
Expected: LazyGit window opens
[ ] PASS
[ ] FAIL — note: lazygit must be installed (`which lazygit`)

---

### F-06 — Folding (nvim-ufo)
**lhs:** `zM` (close all), `zR` (open all), `zK` (peek)

Steps: Open a file with folds → press `zM`
Expected: All folds close
[ ] PASS
[ ] FAIL

---

### F-07 — Completion (blink.cmp)
Steps: Open a .lua file, type `vim.` in insert mode
Expected: Completion menu appears
[ ] PASS
[ ] FAIL

---

### F-08 — Format on save (conform.nvim)
Steps: Open a .lua file with inconsistent indentation → `<C-s>`
Expected: File formats and saves
[ ] PASS
[ ] FAIL

---

### F-09 — Comment toggle
**lhs:** `<C-_>` (Ctrl+/)

Steps: Open a file, normal mode → `<C-_>`
Expected: Line gets commented/uncommented
[ ] PASS
[ ] FAIL

---

### F-10 — Insert mode escape
**lhs:** `jk`

Steps: Enter insert mode → type `jk`
Expected: Returns to normal mode
[ ] PASS
[ ] FAIL

---

## Summary

| Section | Total | Confirmed | Pending |
|---------|-------|-----------|---------|
| A: Already confirmed | 8 | 8 | 0 |
| B: Static high-confidence | 2 | 0 | 2 |
| C: Colon-format keymaps | 11 | 0 | 11 |
| D: Feature tests | 10 | 0 | 10 |
| **Total** | **31** | **8** | **23** |
