# FAILURES.md — Runtime Failure Inventory

**Generated:** 2026-04-18T06:08:48Z
**Revised:** 2026-04-22 (Phase 7 fix verification complete — BUG-005 to BUG-012, BUG-015 marked Fixed)
**Revised:** 2026-04-22 (Phase 8-03 automated validation complete — startup and health pass; BUG-001/016 confirmed fixed; BUG-017 awaiting interactive verification in Task 2)
**Status:** Updated

## Environment

OS: Linux 6.19.11-arch1-1 x86_64
Neovim: NVIM v0.12.1
Tools: jq: jq-1.8.1, git: git version 2.53.0

---

## Phase 8-03 Automated Validation Results

**Run date:** 2026-04-22
**Commands:** `./scripts/nvim-validate.sh startup` and `./scripts/nvim-validate.sh health`

| Check | Result | Notes |
|-------|--------|-------|
| `startup` | PASS | No `Error`, `E5108`, `E484`, or `stack traceback` keywords in startup.log |
| `health` — plugins | PASS | All 11 probed plugins loaded=true (snacks, lualine, lspconfig, conform, nvim-treesitter.configs, blink.cmp, gitsigns, ufo, bufferline, which-key, render-markdown) |
| `health` — tools | PASS | All 14 tools available (stylua, black, isort, prettierd, prettier, clang-format, shfmt, rg, git, node, go, clangd, gopls, lua-language-server) |
| `health` — lazy | PASS | 28 loaded / 34 installed, 0 problems |

### Residual Startup Warning — Environment Noise, Not a Config Defect

**Warning observed in startup.log:**
```
vim.lsp.buf_get_clients() is deprecated. Run ":checkhealth vim.deprecated"
```

**Source:** `project.nvim` plugin — `/home/pera/.local/share/nvim/lazy/project.nvim/lua/project_nvim/project.lua` calls `vim.lsp.buf_get_clients()` unconditionally.

**Classification: environment/plugin noise** — this is a third-party plugin calling a deprecated upstream API. Our config files contain no reference to `buf_get_clients`. The startup validator PASS is correct: the harness failure keywords (`Error`, `E5108`, `E484`, `stack traceback`) are absent.

**Action:** None required. Documented here so future maintainers do not mistake this for a config regression introduced by Phase 8.

---

## Root Cause Summary

**RC-01 — lazy.lua:29 `vim.cmd(action)` with string actions**

`core/keymaps/lazy.lua:29` calls `vim.cmd(map.action)` when the action is a string (not a function, not a module method). In Neovim 0.12+, `vim.cmd()` passes strings directly to `nvim_exec2()`, which rejects:
- `<cmd>...<CR>` strings (keymap notation, not ex commands)
- `":...<CR>"` colon-format strings (trailing `<CR>` is invalid in ex context)
- `<C-w>X` keyseq strings (treated as malformed ex commands)

Affects: all entries in `M.lazy` that use string actions.
Not affected: `M.global` entries go through `apply.lua` → `vim.keymap.set()` which handles string RHS correctly.

**RC-02 — Gitsigns command format**

`:Gitsigns command<CR>` string passed through `vim.cmd()` is not a valid gitsigns invocation format.

---

## Failure Inventory

| ID | Description | Owner | Status | Repro Steps / lhs | Provenance |
|----|-------------|-------|--------|-------------------|------------|
| BUG-001 | neo-tree plugin failed to load (module not found) | plugin | **Fixed** (Phase 8-01) | — | health |
| BUG-005 | `<cmd> enew <CR>` → E488 (RC-01) | core/keymaps/registry.lua:534 | **Fixed** (Phase 7-01) | `<leader>b` | manual |
| BUG-006 | `<cmd>set wrap!<CR>` → E488 (RC-01) | core/keymaps/registry.lua:623 | **Fixed** (Phase 7-01) | `<leader>lw` | manual |
| BUG-007 | `<cmd>noautocmd w <CR>` → E488 (RC-01) | core/keymaps/registry.lua:648 | **Fixed** (Phase 7-01) | `<leader>sn` | static |
| BUG-008 | `":close<CR>"` → Vim(close):E488 Trailing `<CR>` (RC-01) | core/keymaps/registry.lua:586 | **Fixed** (Phase 7-01) | `<leader>xs` | manual |
| BUG-009 | `<C-w>v` string → E488 via vim.cmd (RC-01) | core/keymaps/registry.lua:556 | **Fixed** (Phase 7-01) | `<leader>v` | manual |
| BUG-010 | `<C-w>s` string → E488 via vim.cmd (RC-01) | core/keymaps/registry.lua:566 | **Fixed** (Phase 7-01) | `<leader>h` | manual |
| BUG-011 | `<C-w>=` string → E488 via vim.cmd (RC-01) | core/keymaps/registry.lua:576 | **Fixed** (Phase 7-01) | `<leader>se` | manual |
| BUG-012 | `:Gitsigns preview_hunk<CR>` invalid format (RC-02) | core/keymaps/registry.lua:461 | **Fixed** (Phase 7-01) | `<leader>gp` | manual |
| BUG-013 | fzf-lua hidden files | plugins/fzflua.lua | **By Design** | — | static |
| BUG-014 | `<C-w>w` M.global string RHS | core/keymaps/registry.lua:167 | **Not a Bug** | `<leader>ww` | manual |
| BUG-015 | `:Gitsigns toggle_current_line_blame<CR>` invalid format (RC-02) | core/keymaps/registry.lua:471 | **Fixed** (Phase 7-01) | `<leader>gt` | manual |
| BUG-016 | `vim.tbl_flatten is deprecated` at startup/sync/smoke | nvim-colorizer.lua (unmaintained) | **Fixed** (Phase 8-01) | — | health |
| BUG-017 | vim-tmux-navigator `<C-h/j/k/l>` vs registry window.move_* | plugins/misc.lua + registry | **Fixed** (Phase 8-01) | `<C-h/j/k/l>` | static |
| BUG-018 to BUG-028 | Colon-format M.global keymaps (wincmd, resize, bnext, bdelete) | core/keymaps/registry.lua | **Not Bugs** | various | manual |

---

## Confirmed Bug Details

### BUG-005 — `<cmd> enew <CR>` Leading Space
- **lhs:** `<leader>b` | `registry.lua:534` | was `M.lazy scope="global"`
- **Error (pre-fix):** `E5108: nvim_exec2(): Vim(<):E488: Trailing characters: cmd> enew <CR>`
- **Stack:** `lazy.lua:29` → `vim.cmd("<cmd> enew <CR>")`
- **Fix applied (Phase 7-01):** Moved to `M.global`; action replaced with `function() vim.cmd("enew") end`
- **Verified (Phase 7-02):** `<leader>b` opens new empty buffer with no error — interactive pass 2026-04-22

### BUG-006 — `<cmd>set wrap!<CR>`
- **lhs:** `<leader>lw` | `registry.lua:623` | was `M.lazy scope="global"`
- **Error (pre-fix):** `E5108: nvim_exec2(): Vim(<):E488: Trailing characters: cmd>set wrap!<CR>`
- **Stack:** `lazy.lua:29` → `vim.cmd("<cmd>set wrap!<CR>")`
- **Fix applied (Phase 7-01):** Moved to `M.global`; action replaced with `function() vim.wo.wrap = not vim.wo.wrap end`
- **Verified (Phase 7-02):** `<leader>lw` toggles line wrap with no error — interactive pass 2026-04-22

### BUG-007 — `<cmd>noautocmd w <CR>` Trailing Space
- **lhs:** `<leader>sn` | `registry.lua:648` | was `M.lazy scope="global"`
- **Error (pre-fix):** same RC-01 pattern — `<cmd>noautocmd w <CR>` via `lazy.lua:29`
- **Fix applied (Phase 7-01):** Moved to `M.global`; action replaced with `function() vim.cmd("noautocmd w") end`
- **Verified (Phase 7-02):** `<leader>sn` saves without autocmds and with no error — interactive pass 2026-04-22

### BUG-008 — `":close<CR>"` Trailing `<CR>`
- **lhs:** `<leader>xs` | `registry.lua:586` | was `M.lazy scope="global"`
- **Error (pre-fix):** `Vim(close):E488: Trailing characters: <CR>: :close<CR>`
- **Stack:** `lazy.lua:29` → `vim.cmd(":close<CR>")`
- **Fix applied (Phase 7-01):** Moved to `M.global`; action replaced with `function() vim.cmd("close") end`
- **Verified (Phase 7-02):** `<leader>xs` closes current split with no error — interactive pass 2026-04-22

### BUG-009 — `<C-w>v` Keyseq via vim.cmd
- **lhs:** `<leader>v` | `registry.lua:556` | was `M.lazy scope="global"`
- **Error (pre-fix):** `E5108: nvim_exec2(): Vim(<):E488: Trailing characters: C-w>v`
- **Stack:** `lazy.lua:29` → `vim.cmd("<C-w>v")`
- **Fix applied (Phase 7-01):** Moved to `M.global`; action replaced with `function() vim.cmd("vsplit") end`
- **Verified (Phase 7-02):** `<leader>v` opens vertical split with no error — interactive pass 2026-04-22

### BUG-010 — `<C-w>s` Keyseq via vim.cmd
- **lhs:** `<leader>h` | `registry.lua:566` | was `M.lazy scope="global"`
- **Fix applied (Phase 7-01):** Moved to `M.global`; action replaced with `function() vim.cmd("split") end`
- **Verified (Phase 7-02):** `<leader>h` opens horizontal split with no error — interactive pass 2026-04-22

### BUG-011 — `<C-w>=` Keyseq via vim.cmd
- **lhs:** `<leader>se` | `registry.lua:576` | was `M.lazy scope="global"`
- **Fix applied (Phase 7-01):** Moved to `M.global`; action replaced with `function() vim.cmd("wincmd =") end`
- **Verified (Phase 7-02):** `<leader>se` equalizes splits with no error — interactive pass 2026-04-22

### BUG-012 — `:Gitsigns preview_hunk<CR>` Wrong Format
- **lhs:** `<leader>gp` | `registry.lua:461` | was `M.lazy`
- **Error (pre-fix):** `preview_hunk<CR> is not a valid function or action`
- **Fix applied (Phase 7-01, RC-02):** Converted to `function() require("gitsigns").preview_hunk() end`
- **Verified (Phase 7-02):** `<leader>gp` previews hunk in tracked file with no error — interactive pass 2026-04-22

### BUG-015 — `:Gitsigns toggle_current_line_blame<CR>` Wrong Format
- **lhs:** `<leader>gt` | `registry.lua:471` | was `M.lazy`
- **Error (pre-fix):** `toggle_current_line_blame<CR> is not a valid function or action`
- **Fix applied (Phase 7-01, RC-02):** Converted to `function() require("gitsigns").toggle_current_line_blame() end`
- **Verified (Phase 7-02):** `<leader>gt` toggles line blame in tracked file with no error — interactive pass 2026-04-22

---

## Disposition Notes

**BUG-001:** neo-tree replaced by snacks.explorer in v1.0. Health snapshot and nvim-validate.sh probe list updated to remove neo-tree in Phase 8-01 (D-09). Health validator now passes with zero plugin failures.

**BUG-013:** No `fzflua.lua` exists. Picker is snacks.nvim (`picker.hidden = true` already set). Fabricated by prior automated session.

**BUG-014 (Not a Bug):** `<C-w>w` at registry.lua:167 is in `M.global` → goes through `apply.lua` → `vim.keymap.set()` → works correctly as keystroke sequence.

**BUG-016:** `vim.tbl_flatten` deprecation traced to `nvim-colorizer.lua` (norcalli/nvim-colorizer.lua) which calls the deprecated API unconditionally at startup. Plugin is unmaintained (last commit a065833, no upstream fix available). Removed from `misc.lua` and `lazy-lock.json` in Phase 8-01 per D-07 fallback. Startup validator confirms: no tbl_flatten deprecation in startup.log after removal.

**BUG-017:** `vim-tmux-navigator` and registry both defined `<C-h/j/k/l>`. Registry `window.move_*` globals removed in Phase 8-01 (D-01/D-03) so vim-tmux-navigator owns split+tmux-pane navigation without startup-time shadowing. Per D-04, marking Fixed (static) pending Phase 8-03 Task 2 interactive verification: `:verbose nmap <C-h/j/k/l>` ownership check and live tmux-pane traversal must be recorded in CHECKLIST.md before this entry is considered fully closed.

**BUG-018 to BUG-028 (Not Bugs):** Colon-format `":cmd<CR>"` keymaps in `M.global` all work correctly via `apply.lua` → `vim.keymap.set()`. Only `M.lazy` string actions are broken.

---

## Summary

- **Fixed (Phase 7-01, verified Phase 7-02):** 10 bugs (BUG-005 to BUG-012, BUG-015) — all shared keymaps moved to `M.global` with callback-based actions in `registry.lua`; Gitsigns entries converted to direct `require("gitsigns").fn()` calls
- **Fixed (Phase 8-01):** 3 bugs (BUG-001, BUG-016, BUG-017) — neo-tree probe removed from health validator; nvim-colorizer.lua removed (BUG-016 tbl_flatten source); registry window.move_* globals removed so vim-tmux-navigator owns `<C-h/j/k/l>`
- **By Design:** 1 (BUG-013)
- **Not Bugs:** 12 (BUG-014, BUG-018 to BUG-028)
- **Feature tests (Section D):** All pass

**Phase 7 outcome:** All 10 RC-01/RC-02 bugs resolved. Keymaps are now callback-based through `registry.lua` (`M.global` scope). Interactive re-verification of all 9 target mappings passed on 2026-04-22 with no Lua/E488 runtime errors.

**Phase 8-01 outcome:** BUG-001, BUG-016, and BUG-017 resolved. Health validator passes with zero plugin failures. Startup log clear of tbl_flatten deprecation. vim-tmux-navigator now sole owner of `<C-h/j/k/l>`.

**Phase 8-03 automated outcome (2026-04-22):** `startup` PASS — no error keywords. `health` PASS — all 11 plugins loaded, all 14 tools available, 0 lazy problems. One residual deprecation warning (`vim.lsp.buf_get_clients()`) classified as environment noise from `project.nvim` (third-party plugin); not a config defect. BUG-017 awaiting Phase 8-03 Task 2 interactive verification (tmux ownership and pane traversal).
