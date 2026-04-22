# FAILURES.md — Runtime Failure Inventory

**Generated:** 2026-04-18T06:08:48Z
**Revised:** 2026-04-22 (Phase 7 fix verification complete — BUG-005 to BUG-012, BUG-015 marked Fixed)
**Revised:** 2026-04-22 (Phase 8-03 automated validation complete — startup and health pass; BUG-001/016 confirmed fixed; BUG-017 awaiting interactive verification in Task 2)
**Revised:** 2026-04-22 (Phase 8-03 interactive verification complete — BUG-017 Neovim side confirmed Fixed; tmux.conf gap tracked as BUG-019; Linux external-open W-13 corrected to FAIL, tracked as BUG-020)
**Revised:** 2026-04-23 (Phase 9-01 Task 1 — first checkhealth audit captured; render-markdown buftype config fixed; BUG-019 tmux companion bindings added to .tmux.conf; remaining errors classified as reserved/environment-only)
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

## Phase 9-01 First Checkhealth Audit (2026-04-23)

**Command:** `./scripts/nvim-validate.sh checkhealth`
**Artifact:** `.planning/tmp/nvim-validate/checkhealth.txt` (5667 lines)
**Initial exit:** FAIL (correct — errors detected before fixes)
**Post-fix exit:** FAIL (remaining errors are reserved/environment-only — documented below)

### Errors found and classification

| Provider | Error message | Classification | Action |
|----------|---------------|----------------|--------|
| `core` | `Failed to run healthcheck for "core" plugin. Exception: attempt to call field 'check' (a nil value)` | **Reserved for 9-02** — `core/health.lua` has no `check()` function yet; adding it is 9-02's task | None in 9-01 |
| `render-markdown` | `buftype - expected: nil, got: table` | **Config bug** — `buftype` was at root opts level; must be under `overrides.buftype` | **Fixed**: moved to `overrides.buftype` in `plugins/misc.lua` |
| `render-markdown` | `highlighter: not enabled` | **Environment-only** — treesitter highlighter is not active on the headless health buffer; always false in headless mode | None — not a config defect |
| `snacks` | `Snacks.dashboard setup did not run` | **Environment-only** — dashboard intentionally skips `did_setup` in headless mode (`#uis == 0` guard in `snacks/dashboard.lua`) | None — not a config defect |
| `snacks` | `Tool not found: 'mmdc'` | **Missing optional tool** — `mmdc` (mermaid CLI) not installed on this machine | None — optional tool, not a config defect |
| `tpipeline` | `Background job is not running: dead (init not called)` | **Environment-only** — tpipeline requires a live tmux session; headless mode has no tmux UI | None — not a config defect |

### Post-fix state

After fixing the `render-markdown` `overrides.buftype` config, the only remaining `❌ ERROR` lines in the headless audit are:
- `core` provider gap (reserved for 9-02)
- Headless-only environment issues (render-markdown highlighter, snacks dashboard, tpipeline)
- Missing optional external tool (`mmdc`)

This satisfies the Phase 9-01 acceptance criteria: "a non-zero exit is acceptable only when remaining ERROR lines are limited to the reserved provider-compatibility gap for 9-02 or proved environment-only issues."

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
| BUG-017 | vim-tmux-navigator `<C-h/j/k/l>` vs registry window.move_* | plugins/misc.lua + registry | **Fixed** (Phase 8-01, Neovim side) | `<C-h/j/k/l>` | static |
| BUG-018 to BUG-028 | Colon-format M.global keymaps (wincmd, resize, bnext, bdelete) | core/keymaps/registry.lua | **Not Bugs** | various | manual |
| BUG-019 | tmux.conf missing vim-tmux-navigator companion bindings — cross-pane traversal fails | .tmux.conf (environment) | **Fixed** (Phase 9-01) — companion `bind-key -n C-h/j/k/l` entries added to `.config/.tmux.conf`; tmux reloaded; pending interactive confirmation in Task 2 | `<C-h/j/k/l>` in tmux | interactive |
| BUG-020 | Linux external-open `<C-S-o>` does not open file externally — root cause unclear (xdg-open, vim.ui.open availability, or key binding) | core/open.lua + system | **Open** (needs investigation in Task 2) | `<C-S-o>` on Linux | interactive |

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

**BUG-017:** `vim-tmux-navigator` and registry both defined `<C-h/j/k/l>`. Registry `window.move_*` globals removed in Phase 8-01 (D-01/D-03) so vim-tmux-navigator owns split+tmux-pane navigation without startup-time shadowing. Phase 8-03 Task 2 interactive verification confirmed via `:verbose nmap <C-h>`:

```
n  <C-H>       * :<C-U>TmuxNavigateLeft<CR>
        Last set from ~/.local/share/nvim/lazy/vim-tmux-navigator/plugin/tmux_navigator.vim line 18
```

Neovim-side ownership: CONFIRMED Fixed. The registry conflict is fully resolved.

**Split finding:** Cross-pane traversal inside tmux still fails. Root cause is that `.tmux.conf` is missing the companion `bind-key` entries that call the vim-tmux-navigator shell script — without these, tmux does not forward `<C-h/j/k/l>` to the navigator when Neovim is focused. This is an environment/config gap in `.tmux.conf`, not a Neovim config defect. Tracked separately as BUG-019.

**BUG-019:** `.tmux.conf` is missing the `bind-key -n C-h/j/k/l` companion bindings required by vim-tmux-navigator for cross-pane traversal. The plugin's README requires these entries to be present in `.tmux.conf` alongside the Neovim-side plugin installation. Without them, pressing `<C-h/j/k/l>` inside a tmux session does nothing at the tmux layer — only Neovim-internal split movement works (which uses the same keys but never crosses pane boundaries). Resolution requires adding the four `bind-key` entries and sourcing `.tmux.conf`. This is an environment gap, not a code regression.

**BUG-018 to BUG-028 (Not Bugs):** Colon-format `":cmd<CR>"` keymaps in `M.global` all work correctly via `apply.lua` → `vim.keymap.set()`. Only `M.lazy` string actions are broken.

**BUG-020:** Linux external-open `<C-S-o>` does not open the file externally on Linux. Phase 8-02 correctly hardened `core/open.lua` to capture the `vim.ui.open()` return tuple directly so the real OS error string surfaces. However the underlying open itself still fails. Possible root causes: (1) `xdg-open` is missing or misconfigured on this system, (2) `vim.ui.open()` is unavailable or behaves differently on this Neovim version, (3) the key binding `<C-S-o>` is not reaching the handler (terminal strips `<C-S-o>`). The hardening fix is correct and should be retained. Root cause investigation and fix are deferred to a follow-up phase.

---

## Summary

- **Fixed (Phase 7-01, verified Phase 7-02):** 10 bugs (BUG-005 to BUG-012, BUG-015) — all shared keymaps moved to `M.global` with callback-based actions in `registry.lua`; Gitsigns entries converted to direct `require("gitsigns").fn()` calls
- **Fixed (Phase 8-01):** 2 bugs fully resolved + 1 Neovim-side fix (BUG-001, BUG-016 fixed; BUG-017 Neovim-side fixed — neo-tree probe removed from health validator; nvim-colorizer.lua removed; registry window.move_* globals removed so vim-tmux-navigator owns `<C-h/j/k/l>` in Neovim)
- **Open — environment gap:** 1 (BUG-019) — `.tmux.conf` missing companion bindings for cross-pane traversal; requires `.tmux.conf` update outside Neovim config
- **Open — needs investigation:** 1 (BUG-020) — Linux external-open `<C-S-o>` does not work; open.lua hardening correct but underlying open fails; root cause (xdg-open, vim.ui.open, key binding) needs follow-up
- **Deferred:** Windows external-open — no Windows machine available for verification
- **By Design:** 1 (BUG-013)
- **Not Bugs:** 12 (BUG-014, BUG-018 to BUG-028)
- **Feature tests (Section D):** All pass

**Phase 7 outcome:** All 10 RC-01/RC-02 bugs resolved. Keymaps are now callback-based through `registry.lua` (`M.global` scope). Interactive re-verification of all 9 target mappings passed on 2026-04-22 with no Lua/E488 runtime errors.

**Phase 8-01 outcome:** BUG-001, BUG-016, and BUG-017 resolved. Health validator passes with zero plugin failures. Startup log clear of tbl_flatten deprecation. vim-tmux-navigator now sole owner of `<C-h/j/k/l>`.

**Phase 8-03 automated outcome (2026-04-22):** `startup` PASS — no error keywords. `health` PASS — all 11 plugins loaded, all 14 tools available, 0 lazy problems. One residual deprecation warning (`vim.lsp.buf_get_clients()`) classified as environment noise from `project.nvim` (third-party plugin); not a config defect.

**Phase 8-03 interactive outcome (2026-04-22):** 13 of 15 workflows passed (search, explorer, git, LSP, UI, Neovim-internal split navigation). BUG-017 Neovim-side ownership confirmed Fixed via `:verbose nmap <C-h>` — vim-tmux-navigator owns the mapping. Cross-pane tmux traversal fails due to missing `.tmux.conf` companion bindings (BUG-019) — environment gap, not a config regression. Linux external-open (`<C-S-o>`) FAILS on Linux (BUG-020) — open.lua hardening is correct but the underlying open does not complete; root cause unclear (xdg-open, vim.ui.open availability, or key binding); needs follow-up investigation. Windows external-open: DEFERRED — no Windows machine available.
