# CHECKLIST.md — Reproduction Checklist (Final)

**Generated:** 2026-04-18
**Revised:** 2026-04-22 (Phase 7-02 — converted to post-fix regression checklist; all BUG-01 entries verified fixed)
**Revised:** 2026-04-22 (Phase 8-03 — Phase 8 regression results added; W-13 Linux external-open corrected to FAIL; tmux-navigation split finding recorded)
**Revised:** 2026-04-23 (Phase 9-01 — BUG-019 fix applied; BUG-020 investigation steps added; awaiting interactive verification in Task 2)
**Status:** Regression Checklist (post-Phase 9-01 automated work)
**Source:** [FAILURES.md](FAILURES.md)

---

## Phase 9 Interactive Verification (BUG-019 and BUG-020)

### BUG-019 — tmux cross-pane traversal (AWAITING interactive confirmation)

**Fix applied (Phase 9-01):** Added four `bind-key -n C-h/j/k/l` companion entries to `.config/.tmux.conf` and sourced the config.

**Automated check passes:**
```
$ rg -n "bind-key -n 'C-[hjkl]'" .config/.tmux.conf
41:bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
42:bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
43:bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
44:bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'
```

**Interactive verification steps (Task 2 — human required):**
1. Run `tmux source-file ~/.config/.tmux.conf` (if using deployed config) or `tmux source-file /path/to/.dotfiles/.config/.tmux.conf`
2. Open Neovim in one tmux pane with a vertical split (`<leader>v`)
3. Press `<C-h>` — confirm cursor moves left between Neovim splits AND between tmux panes
4. Press `<C-l>` — confirm cursor moves right across pane boundary back to Neovim
5. Open a second tmux pane and confirm `<C-h/j/k/l>` cross pane boundaries in both directions

**Expected:** Cross-pane navigation works seamlessly between Neovim splits and tmux panes.
**BUG-019 closes when:** Interactive pane crossing is confirmed.

---

### BUG-020 — Linux external-open `<C-S-o>` (AWAITING investigation in Task 2)

**Background:** `<C-S-o>` bound to `require("core.open").open_current_buffer()` does not open files externally on Linux. Phase 8-02 hardened `core/open.lua` to correctly capture the `vim.ui.open()` return tuple. Root cause is still unclear.

**Investigation order (D-31):**

**Step 1 — Verify key delivery:**
In Neovim, run `:verbose nmap <C-S-o>` and record the output.
- If result shows `file.open_external` → key reaches Neovim, continue to Step 2
- If no result or shows something else → terminal is stripping the chord; go to Step 4

**Step 2 — Test vim.ui.open() directly:**
On a normal file buffer, run:
```
:lua vim.ui.open(vim.fn.expand('%:p'))
```
Record the result or error message.
- If no error and file opens → the handler itself works; investigate keymap wiring
- If error shown → note the exact error string (likely xdg-open related)

**Step 3 — Test xdg-open from shell:**
```bash
xdg-open "$(pwd)/.config/nvim/README.md"
```
Record whether the host opener succeeds.

**Step 4 — Record results and decide:**
- If terminal strips `<C-S-o>` (Step 1 fails): rebind to `<leader>o` in `registry.lua` (D-32)
- If `vim.ui.open()` returns an error (Step 2): note the error and check xdg-open config
- If xdg-open fails (Step 3): environment-only issue; document as host-environment gap
- If all steps pass but `<C-S-o>` still fails: record findings and mark as environment-only

**Results (to be filled in Task 2):**
- `:verbose nmap <C-S-o>`: _[PENDING]_
- `:lua vim.ui.open(...)`: _[PENDING]_
- `xdg-open` test: _[PENDING]_
- Root cause: _[PENDING]_
- Final disposition: _[PENDING]_

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

## Phase 8 Regression Results (2026-04-22)

Interactive verification run after Phase 8-01 and 08-02 fixes. All items tested in the live dotfiles config.

### Workflow Matrix

| ID | Workflow | Result | Notes |
|----|----------|--------|-------|
| W-01 | Snacks file find (`<leader>ff`) | PASS | Picker opens, results navigable, no error |
| W-02 | Snacks live grep | PASS | Live grep results appear correctly, no error |
| W-03 | Snacks buffer picker | PASS | Buffer list shown, selection works, no error |
| W-04 | Snacks explorer open/close/navigate (`<leader>e`) | PASS | Explorer opens and closes, file navigation works, no error |
| W-05 | Gitsigns preview hunk (`<leader>gp`) | PASS | Hunk preview float opens in tracked file with changes, no error |
| W-06 | Gitsigns line blame (`<leader>gt`) | PASS | Inline blame annotation toggles, no error |
| W-07 | LazyGit (`<leader>gg`) | PASS | LazyGit UI opens, no error |
| W-08 | LSP definition / hover / diagnostics | PASS | All three functions work on attached buffer, no crash |
| W-09 | Format on save (`<C-s>`) | PASS | Save triggers formatter, no error |
| W-10 | which-key popup | PASS | Popup renders on `<leader>`, no error |
| W-11 | Notification / noice output | PASS | Notifications display correctly, no runtime error |
| W-12 | Statusline / fold rendering | PASS | Lualine visible, ufo folds render normally |
| W-13 | Linux external-open (`<C-S-o>`) | FAIL | Does not open file externally on Linux; root cause unclear (xdg-open, vim.ui.open availability, or key binding issue); open.lua hardening correct but underlying open fails; needs follow-up investigation |
| W-14 | Tmux-navigation — Neovim split movement (outside tmux) | PASS | `<C-h/j/k/l>` navigate Neovim splits normally |
| W-15 | Tmux-navigation — cross-pane traversal (inside tmux) | FAIL | Neovim mapping ownership correct; tmux.conf companion bindings absent (see BUG-019) |
| W-16 | Windows external-open (`<C-S-o>`) | DEFERRED | No Windows machine available for verification |

### BUG-017 — Tmux-Navigation Ownership Evidence (Phase 8-03)

**`:verbose nmap <C-h>` output (verbatim from user):**
```
n  <C-H>       * :<C-U>TmuxNavigateLeft<CR>
        Last set from ~/.local/share/nvim/lazy/vim-tmux-navigator/plugin/tmux_navigator.vim line 18
```

**Analysis:**
- Owner: `vim-tmux-navigator` plugin — CONFIRMED (not registry.lua)
- Phase 8-01 fix (remove registry `window.move_*` globals) is verified effective
- Neovim-side ownership: FIXED
- Cross-pane traversal: FAILS — the plugin script that tmux needs to call (`tmux-navigate` wrapper or `tmux_navigator.sh`) is not bound in `.tmux.conf`
- This is an environment/config gap in `.tmux.conf`, not a Neovim config defect

**Verdict for BUG-017:** Neovim side FIXED. Environment gap tracked separately as BUG-019.

---

## Root Cause (Historical)

All 10 confirmed bugs shared one of two root causes:

**RC-01 (8 bugs):** `core/keymaps/lazy.lua:29` called `vim.cmd(map.action)` for string actions. In Neovim 0.12+, `vim.cmd()` → `nvim_exec2()` rejects `<cmd>...<CR>` notation, `":...<CR>"` colon strings, and `<C-w>X` keyseq strings.

**RC-02 (2 bugs):** `:Gitsigns command<CR>` strings were not a valid gitsigns invocation format regardless of execution path.

**Phase 7 fix applied:** All 8 RC-01 entries moved from `M.lazy` to `M.global` with explicit Lua callback actions. Both RC-02 Gitsigns entries converted to `function() require("gitsigns").fn() end`. The `lazy.lua` dispatcher was also split (angle-bracket strings now route through `nvim_feedkeys`; plain ex-commands through `vim.cmd`) to prevent recurrence for any remaining `M.lazy` entries. All 9 target mappings passed interactive verification on 2026-04-22.
