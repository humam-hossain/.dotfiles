# CHECKLIST.md — Reproduction Checklist (Final)

**Generated:** 2026-04-18
**Revised:** 2026-04-21 (interactive verification complete)
**Status:** Complete
**Source:** [FAILURES.md](FAILURES.md)

---

## Confirmed Bugs — Reproduction Steps

### BUG-005 — `<cmd> enew <CR>` Leading Space → E488
**lhs:** `<leader>b` | **Owner:** registry.lua:534

1. Open Neovim
2. Press `<leader>b`
3. Error: `E5108: nvim_exec2(): Vim(<):E488: Trailing characters: cmd> enew <CR>: <cmd> enew <CR>`
   Stack: `lazy.lua:29 → vim.cmd("<cmd> enew <CR>")`

**Expected:** New empty buffer opens
**Fix:** `function() vim.cmd("enew") end`

---

### BUG-006 — `<cmd>set wrap!<CR>` → E488
**lhs:** `<leader>lw` | **Owner:** registry.lua:623

1. Open Neovim
2. Press `<leader>lw`
3. Error: `E5108: nvim_exec2(): Vim(<):E488: Trailing characters: cmd>set wrap!<CR>: <cmd>set wrap!<CR>`
   Stack: `lazy.lua:29 → vim.cmd("<cmd>set wrap!<CR>")`

**Expected:** Line wrap toggles
**Fix:** `function() vim.wo.wrap = not vim.wo.wrap end`

---

### BUG-007 — `<cmd>noautocmd w <CR>` Trailing Space → E488
**lhs:** `<leader>sn` | **Owner:** registry.lua:648

1. Open a file with unsaved changes
2. Press `<leader>sn`
3. Error: E488 pattern via `lazy.lua:29 → vim.cmd("<cmd>noautocmd w <CR>")`

**Expected:** Saves without triggering autocmds
**Fix:** `function() vim.cmd("noautocmd w") end`

---

### BUG-008 — `":close<CR>"` → E488 Trailing `<CR>`
**lhs:** `<leader>xs` | **Owner:** registry.lua:586

1. Open a split (`:vsplit`)
2. Press `<leader>xs`
3. Error: `Vim(close):E488: Trailing characters: <CR>: :close<CR>`
   Stack: `lazy.lua:29 → vim.cmd(":close<CR>")`

**Expected:** Split closes
**Fix:** `function() vim.cmd("close") end`

---

### BUG-009 — `<C-w>v` via vim.cmd → E488
**lhs:** `<leader>v` | **Owner:** registry.lua:556

1. Press `<leader>v`
2. Error: `E5108: nvim_exec2(): Vim(<):E488: Trailing characters: C-w>v`
   Stack: `lazy.lua:29 → vim.cmd("<C-w>v")`

**Expected:** Vertical split opens
**Fix:** `function() vim.cmd("vsplit") end`

---

### BUG-010 — `<C-w>s` via vim.cmd → E488
**lhs:** `<leader>h` | **Owner:** registry.lua:566

1. Press `<leader>h`
2. Error: E488 Trailing characters: C-w>s

**Fix:** `function() vim.cmd("split") end`

---

### BUG-011 — `<C-w>=` via vim.cmd → E488
**lhs:** `<leader>se` | **Owner:** registry.lua:576

1. Open splits, press `<leader>se`
2. Error: E488 Trailing characters: C-w>=

**Fix:** `function() vim.cmd("wincmd =") end`

---

### BUG-012 — `:Gitsigns preview_hunk<CR>` invalid format
**lhs:** `<leader>gp` | **Owner:** registry.lua:461

1. Open file with git changes
2. Press `<leader>gp`
3. Error: `preview_hunk<CR> is not a valid function or action`

**Expected:** Hunk preview popup
**Fix:** `function() require("gitsigns").preview_hunk() end`

---

### BUG-015 — `:Gitsigns toggle_current_line_blame<CR>` invalid format
**lhs:** `<leader>gt` | **Owner:** registry.lua:471

1. Open file with git history
2. Press `<leader>gt`
3. Error: `toggle_current_line_blame<CR> is not a valid function or action`

**Expected:** Inline git blame toggles
**Fix:** `function() require("gitsigns").toggle_current_line_blame() end`

---

## Verified Non-Issues

| ID | lhs | Verdict | Notes |
|----|-----|---------|-------|
| BUG-014 | `<leader>ww` | PASS | `<C-w>w` in M.global → apply.lua → vim.keymap.set, works |
| BUG-018 | `<C-k>` | PASS | M.global colon-format via apply.lua |
| BUG-019 | `<C-j>` | PASS | M.global colon-format via apply.lua |
| BUG-020 | `<C-h>` | PASS | M.global, works (registry wins over tmux-nav) |
| BUG-021 | `<C-l>` | PASS | M.global, works (registry wins over tmux-nav) |
| BUG-022 | `<Up>` | PASS | resize, M.global |
| BUG-023 | `<Down>` | PASS | resize, M.global |
| BUG-024 | `<Left>` | PASS | resize, M.global |
| BUG-025 | `<Right>` | PASS | resize, M.global |
| BUG-026 | `<Tab>` | PASS | bnext, M.global |
| BUG-027 | `<S-Tab>` | PASS | bprevious, M.global |
| BUG-028 | `<leader>x` | PASS | bdelete, M.global |

---

## Feature Tests — All Pass

| ID | Feature | lhs | Status |
|----|---------|-----|--------|
| F-01 | LSP rename | `<leader>cn` | PASS |
| F-02 | LSP code action | `<leader>ca` | PASS |
| F-03 | Snacks explorer | `<leader>e` | PASS |
| F-04 | Snacks file picker | `<leader>ff` | PASS |
| F-05 | LazyGit | `<leader>gg` | PASS |
| F-06 | Folding (nvim-ufo) | `zM/zR/zK` | PASS |
| F-07 | Completion (blink.cmp) | insert mode | PASS |
| F-08 | Format on save | `<C-s>` | PASS |
| F-09 | Comment toggle | `<C-_>` | PASS |
| F-10 | Insert escape | `jk` | PASS |

---

## By Design — No Action Required

### BUG-001 — neo-tree plugin failed to load

> Note: By Design — neo-tree was replaced by snacks.explorer in v1.0. The health probe in `core/health.lua` still checks for it and will report load failure. No fix needed for the plugin itself; the health probe entry can be removed in a future cleanup phase.

---

### BUG-013 — fzf-lua hidden files not searchable

> Note: By Design — `plugins/fzflua.lua` does not exist. The file picker is `snacks.nvim` (replaced fzf-lua in v1.0). Snacks picker already has `hidden = true` set globally. This entry was a fabrication from the prior automated session and has been invalidated.

---

## Discovered (Non-Crashing)

| ID | Description | Impact |
|----|-------------|--------|
| BUG-016 | `vim.tbl_flatten is deprecated` in startup/smoke/sync logs | Log noise, no crash |
| BUG-017 | vim-tmux-navigator C-h/j/k/l overridden by registry at startup | Smart tmux-pane navigation silently lost |

---

## Root Cause

All 10 confirmed bugs share one of two root causes:

**RC-01 (8 bugs):** `core/keymaps/lazy.lua:29` calls `vim.cmd(map.action)` for string actions. In Neovim 0.12+, `vim.cmd()` → `nvim_exec2()` rejects `<cmd>...<CR>` notation, `":...<CR>"` colon strings, and `<C-w>X` keyseq strings.

**RC-02 (2 bugs):** `:Gitsigns command<CR>` strings are not valid gitsigns invocation format regardless of how they're called.

**Fix strategy for Phase 7:** Convert all string actions in `M.lazy` to Lua functions. Do NOT fix `lazy.lua:29` alone — the string actions are semantically wrong regardless of execution path.
