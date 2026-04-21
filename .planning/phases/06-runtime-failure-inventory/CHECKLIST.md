# CHECKLIST.md — Reproduction Checklist (Final)

**Generated:** 2026-04-18
**Revised:** 2026-04-22 (Phase 7-02 — converted to post-fix regression checklist; all BUG-01 entries verified fixed)
**Status:** Regression Checklist (post-Phase 7)
**Source:** [FAILURES.md](FAILURES.md)

---

## Post-Fix Regression Checklist (Phase 7+)

These steps verify the Phase 7-01 fixes remain intact. Each entry replaces the original repro
steps with regression-detection steps. Historical error details are preserved in FAILURES.md.

### BUG-005 — `<leader>b` opens new buffer (was: E488 from `<cmd> enew <CR>`)
**lhs:** `<leader>b` | **Owner:** registry.lua (M.global)

1. Open Neovim
2. Press `<leader>b`

**Expected:** New empty buffer opens with no error or notification
**Regression signal:** Any E488 or Lua error in the notification area
**Fixed by:** Moved to `M.global`; action is `function() vim.cmd("enew") end`

---

### BUG-006 — `<leader>lw` toggles line wrap (was: E488 from `<cmd>set wrap!<CR>`)
**lhs:** `<leader>lw` | **Owner:** registry.lua (M.global)

1. Open Neovim
2. Press `<leader>lw` — confirm wrap mode toggles (long lines wrap or unwrap)
3. Press `<leader>lw` again — confirm it toggles back

**Expected:** `vim.wo.wrap` toggles each press with no error
**Regression signal:** Any E488 or Lua error
**Fixed by:** Moved to `M.global`; action is `function() vim.wo.wrap = not vim.wo.wrap end`

---

### BUG-007 — `<leader>sn` saves without autocmds (was: E488 from `<cmd>noautocmd w <CR>`)
**lhs:** `<leader>sn` | **Owner:** registry.lua (M.global)

1. Open a file with unsaved changes
2. Press `<leader>sn`

**Expected:** File saves without triggering format-on-save autocmds; no error
**Regression signal:** Any E488 or Lua error
**Fixed by:** Moved to `M.global`; action is `function() vim.cmd("noautocmd w") end`

---

### BUG-008 — `<leader>xs` closes current split (was: E488 from `":close<CR>"`)
**lhs:** `<leader>xs` | **Owner:** registry.lua (M.global)

1. Open a split (`:vsplit` or `<leader>v`)
2. Press `<leader>xs`

**Expected:** Current split closes, remaining window fills the space; no error
**Regression signal:** Any E488 or Lua error
**Fixed by:** Moved to `M.global`; action is `function() vim.cmd("close") end`

---

### BUG-009 — `<leader>v` opens vertical split (was: E488 from `<C-w>v` via vim.cmd)
**lhs:** `<leader>v` | **Owner:** registry.lua (M.global)

1. Press `<leader>v`

**Expected:** Vertical split opens showing same buffer; no error
**Regression signal:** Any E488 or Lua error
**Fixed by:** Moved to `M.global`; action is `function() vim.cmd("vsplit") end`

---

### BUG-010 — `<leader>h` opens horizontal split (was: E488 from `<C-w>s` via vim.cmd)
**lhs:** `<leader>h` | **Owner:** registry.lua (M.global)

1. Press `<leader>h`

**Expected:** Horizontal split opens showing same buffer; no error
**Regression signal:** Any E488 or Lua error
**Fixed by:** Moved to `M.global`; action is `function() vim.cmd("split") end`

---

### BUG-011 — `<leader>se` equalizes splits (was: E488 from `<C-w>=` via vim.cmd)
**lhs:** `<leader>se` | **Owner:** registry.lua (M.global)

1. Open two or more splits of unequal size
2. Press `<leader>se`

**Expected:** All splits resize to equal dimensions; no error
**Regression signal:** Any E488 or Lua error
**Fixed by:** Moved to `M.global`; action is `function() vim.cmd("wincmd =") end`

---

### BUG-012 — `<leader>gp` previews hunk (was: invalid Gitsigns format)
**lhs:** `<leader>gp` | **Owner:** registry.lua (M.global) | **Precondition:** file tracked by git with unstaged changes

1. Open a file with git changes (unstaged hunk visible)
2. Position cursor inside a changed hunk
3. Press `<leader>gp`

**Expected:** Gitsigns hunk preview float opens showing the diff; no error
**Regression signal:** "not a valid function or action" error or Lua traceback
**Fixed by:** Converted to `function() require("gitsigns").preview_hunk() end`

---

### BUG-015 — `<leader>gt` toggles line blame (was: invalid Gitsigns format)
**lhs:** `<leader>gt` | **Owner:** registry.lua (M.global) | **Precondition:** file tracked by git with commit history

1. Open a file with git commit history
2. Press `<leader>gt`

**Expected:** Inline git blame annotation appears at end of current line; no error
**Regression signal:** "not a valid function or action" error or Lua traceback
**Fixed by:** Converted to `function() require("gitsigns").toggle_current_line_blame() end`

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

## Root Cause (Historical)

All 10 confirmed bugs shared one of two root causes:

**RC-01 (8 bugs):** `core/keymaps/lazy.lua:29` called `vim.cmd(map.action)` for string actions. In Neovim 0.12+, `vim.cmd()` → `nvim_exec2()` rejects `<cmd>...<CR>` notation, `":...<CR>"` colon strings, and `<C-w>X` keyseq strings.

**RC-02 (2 bugs):** `:Gitsigns command<CR>` strings were not a valid gitsigns invocation format regardless of execution path.

**Phase 7 fix applied:** All 8 RC-01 entries moved from `M.lazy` to `M.global` with explicit Lua callback actions. Both RC-02 Gitsigns entries converted to `function() require("gitsigns").fn() end`. The `lazy.lua` dispatcher was also split (angle-bracket strings now route through `nvim_feedkeys`; plain ex-commands through `vim.cmd`) to prevent recurrence for any remaining `M.lazy` entries. All 9 target mappings passed interactive verification on 2026-04-22.
