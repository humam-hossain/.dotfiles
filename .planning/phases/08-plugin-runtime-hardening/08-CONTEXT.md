# Phase 8: Plugin Runtime Hardening - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix plugin misconfigurations and crash-prone runtime paths across core editing workflows. Delivers BUG-02 (search, explorer, git, LSP, UI workflows without config-caused runtime errors) and BUG-03 (common editing sessions without crashes from config code).

Three plans:
- 8-01 — plugin config defects exposed by startup/smoke/runtime usage
- 8-02 — crash-prone editor flows and unsafe runtime assumptions
- 8-03 — re-verify core plugin workflows (search, explorer, git, LSP, UI)

</domain>

<decisions>
## Implementation Decisions

### BUG-017: vim-tmux-navigator vs registry window navigation

- **D-01:** Remove the 4 `window.move_*` entries from `registry.lua` (lines 122–157: `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` wincmd mappings). vim-tmux-navigator owns `<C-h/j/k/l>` on both sides — Neovim splits and tmux pane crossing.
- **D-02:** No `$TMUX` guard needed. vim-tmux-navigator falls back to normal wincmd navigation when `$TMUX` is unset — non-tmux sessions are handled automatically.
- **D-03:** vim-tmux-navigator stays installed (already in `misc.lua` and `.config/.tmux.conf`). This is a conflict fix, not a plugin replacement.
- **D-04:** FAILURES.md BUG-017 status → `Fixed` after registry entries removed and verified.

### BUG-016: vim.tbl_flatten deprecation

- **D-05:** Trace the calling plugin via startup log grep (e.g. `nvim --startuptime` or capturing stderr output). Identify which plugin triggers the deprecation warning.
- **D-06:** Primary fix: update the offending plugin's pin in `lazy-lock.json` surgically (only that plugin — no broad lockfile refresh).
- **D-07:** Fallback if no upstream fix exists: remove the offending plugin if non-critical. If essential and unmaintained, document in FAILURES.md as Won't Fix with Neovim version risk noted.
- **D-08:** FAILURES.md BUG-016 status updated to `Fixed` or `Won't Fix` based on outcome.

### BUG-001: Stale neo-tree probe in health.lua

- **D-09:** Remove the neo-tree probe from `core/health.lua`. neo-tree was replaced by snacks.explorer in v1.0 — the probe is stale and produces false health signal. Belongs in Phase 8 (plugin config defect), not Phase 9 (health message quality).
- **D-10:** FAILURES.md BUG-001 status → `Fixed`.

### lsp.lua: basedpyright → pyright

- **D-11:** Remove `basedpyright` from `lsp_servers` and `mason_ensure_installed` in `lsp.lua` (already unstaged). Add `pyright` as replacement in the same commit.
- **D-12:** Both `lsp_servers` table and `mason_ensure_installed` list updated together so Mason installs pyright and LSP config activates it.

### core.open error handling

- **D-13:** Fix `core/open.lua` error handling — `vim.ui.open` returns `(job, errmsg?)` but current code only captures the first return value, silently dropping error messages. Fix to capture both values so failure notifications include the actual error.

### Plan 8-02: Crash-prone flow scope

- **D-14:** Plan 8-02 checks the following crash-prone patterns beyond FAILURES.md:
  - Format-on-save edge cases: BufWritePre triggering formatters in special buffers (fugitive, snacks picker, nofile buffers)
  - LSP attach safety: LSP attaching to non-file buffers or unsupported filetypes — pcall guards and nil checks
  - Autocmd guard review: autocmds in `options.lua` and plugins that assume buffer has a name or filetype
  - Plugin init order: plugins with inter-dependencies (snacks, which-key, treesitter) loading in correct order

### Plan 8-03: Workflow verification scope

- **D-15:** Re-verify all four core plugin workflows interactively:
  - Search: snacks picker — file find, live grep, buffer pick — no errors or crashes
  - Explorer: snacks.explorer — open/close, file ops, tree navigation — no errors
  - Git: gitsigns + fugitive + lazygit — hunk preview, blame, lazygit open — no errors
  - LSP: neovim 0.11 native — go-to-def, hover, diagnostics, format-on-save — no crashes

### Discovery scope

- **D-16:** Trust Phase 6 inventory as the baseline. No separate new discovery pass before fixes. Plan 8-03 surfaces any remaining issues through structured interactive re-verification.

### Claude's Discretion

- Exact startup log grep command for BUG-016 tracing
- Order of commits within each plan
- Whether BUG-016 pin update uses `:Lazy update {plugin}` or manual lock edit
- Specific pcall guard pattern for LSP attach safety in 8-02
- Format-on-save exclusion list review approach

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 8 goal, plan structure, BUG-02/BUG-03 requirements
- `.planning/REQUIREMENTS.md` — BUG-02 and BUG-03 acceptance criteria
- `.planning/PROJECT.md` — v1.1 milestone goals and constraints

### Failure inventory (primary source of truth for fix targets)
- `.planning/phases/06-runtime-failure-inventory/FAILURES.md` — inventory with BUG-001, BUG-016, BUG-017 open items; must be updated to Fixed/Won't Fix as fixes land
- `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` — repro steps for reference

### Files being modified
- `.config/nvim/lua/core/keymaps/registry.lua` — lines 122–157 (window.move_* entries to remove for BUG-017)
- `.config/nvim/lua/plugins/misc.lua` — vim-tmux-navigator stays, no changes needed
- `.config/nvim/lua/core/health.lua` — remove neo-tree probe (BUG-001)
- `.config/nvim/lua/plugins/lsp.lua` — remove basedpyright, add pyright
- `.config/nvim/lua/core/open.lua` — fix vim.ui.open error handling (D-13)
- `lazy-lock.json` — surgical pin update if BUG-016 has an upstream fix

### Tmux integration
- `.config/.tmux.conf` — already has vim-tmux-navigator plugin configured; no changes needed

### Prior phase context
- `.planning/phases/07-keymap-reliability-fixes/07-CONTEXT.md` — D-07: BUG-017 explicitly deferred here from Phase 7
- `.planning/phases/06-runtime-failure-inventory/06-CONTEXT.md` — D-12: FAILURES.md is a living doc; D-13/D-14/D-16: ownership labels

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/nvim-validate.sh` — run post-fix to confirm no regressions (startup/smoke/health)
- `.config/nvim/lua/core/open.lua` — `M.open()` and `M.open_current_buffer()` — targeted error fix in D-13
- `core/health.lua` — `probe_plugin()` function to remove neo-tree from probe list

### Established Patterns
- `apply.lua` → `vim.keymap.set()` — handles `M.global` entries; removing window.move_* from `M.global` means tmux-nav's plugin-managed mappings win
- `lazy.lua` dispatcher pattern — already fixed in Phase 7; string/function dispatch now correct
- Format-on-save exclusion pattern in `conform.lua` — `stop_after_first = true` with filetype safety list

### Integration Points
- `registry.lua` window.move_* removal propagates automatically — no other files reference these specific IDs
- `health.lua` probe list is a plain Lua table — remove the `"neo-tree"` entry from `plugins` list passed to `snapshot()`
- `lsp.lua` `lsp_servers` and `mason_ensure_installed` must both be updated together (D-12)
- vim-tmux-navigator in `misc.lua` has no config block — the plugin itself manages `<C-h/j/k/l>` once registry conflict is removed

</code_context>

<specifics>
## Specific Ideas

- Registry window.move_* entries are at lines 122–157 in registry.lua — four consecutive entries with `lhs = "<C-h/j/k/l>"` and `action = ":wincmd X<CR>"`
- BUG-016 trace: `nvim --startuptime /tmp/startuptime.log` then `grep -i flatten /tmp/startuptime.log` or capture stderr deprecation output
- core.open fix: `local job, err = vim.ui.open(target)` then check `if err then notify_error(err) end` — drops the pcall wrapper since vim.ui.open handles errors via return values
- pyright mason package name: `"pyright"` (same in both lsp_servers and mason_ensure_installed)
- `<C-S-o>` (`file.open_external`) keymap exists and is correctly wired — user confirmed no action needed

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 08-plugin-runtime-hardening*
*Context gathered: 2026-04-22*
