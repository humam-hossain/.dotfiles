# Phase 08: Plugin Runtime Hardening - Research

**Researched:** 2026-04-22
**Domain:** Neovim plugin runtime hardening for startup, interactive workflows, and headless validation
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BUG-02 | User can use core plugin workflows for search, explorer, git, LSP, and UI without config-caused runtime errors. [VERIFIED: .planning/REQUIREMENTS.md] | Fix stale/incorrect plugin config in `core/health.lua`, `core/open.lua`, `plugins/lsp.lua`, `core/keymaps/registry.lua`, and `lazy-lock.json`; then re-run validator plus interactive workflow checks. [VERIFIED: 08-CONTEXT.md, FAILURES.md, codebase grep] |
| BUG-03 | User can complete common editing sessions without crashes caused by Neovim config code. [VERIFIED: .planning/REQUIREMENTS.md] | Review `FocusLost`, `format_on_save`, and `LspAttach` guard paths before re-verifying search/explorer/git/LSP flows. [VERIFIED: .config/nvim/lua/core/keymaps.lua, .config/nvim/lua/plugins/conform.lua, .config/nvim/lua/plugins/lsp.lua] |
</phase_requirements>

## Summary

Phase 8 is a targeted brownfield cleanup, not a plugin-refresh phase. The repo already has the right high-level runtime stack for this milestone: `snacks.nvim` owns search and explorer, `gitsigns.nvim` and `vim-fugitive` own git flows, `conform.nvim` owns formatting, `nvim-lspconfig` plus Mason own LSP setup, and `vim.ui.open()` is the cross-platform OS integration boundary. The planning work should focus on making these existing pieces stop contradicting each other or making stale assumptions. [VERIFIED: .planning/PROJECT.md, .config/nvim/lua/plugins/snacks.lua, .config/nvim/lua/plugins/git.lua, .config/nvim/lua/plugins/conform.lua, .config/nvim/lua/plugins/lsp.lua, .config/nvim/lua/core/open.lua]

The repo-local evidence lines up with the discuss decisions. `core/health.lua` still probes `neo-tree` even though the active explorer is `snacks.explorer`; `registry.lua` still binds `<C-h/j/k/l>` globally and overrides `vim-tmux-navigator`; `core/open.lua` currently uses `pcall(vim.ui.open, ...)` and therefore loses the real `errmsg`; and `lsp.lua` already has an unstaged partial removal of `basedpyright` without the paired `pyright` addition. [VERIFIED: .config/nvim/lua/core/health.lua, .config/nvim/lua/core/keymaps/registry.lua, .config/nvim/lua/core/open.lua, `git diff -- .config/nvim/lua/plugins/lsp.lua`]

The existing validator is useful but not yet authoritative for this phase. On this machine, `health` fails for the stale `neo-tree` probe, `startup` shows the real `vim.tbl_flatten` deprecation plus a sandbox-specific treesitter write-path error, and `smoke` fails in the sandbox because `nvim -l` triggers `vim.loader` bytecode writes under an unwritable cache path. Plans should treat the validator as a baseline tool that also needs interpretation, not as a perfect gate. [VERIFIED: `./scripts/nvim-validate.sh startup`, `./scripts/nvim-validate.sh smoke`, `./scripts/nvim-validate.sh health`]

**Primary recommendation:** Plan `8-01` around concrete config defects first (`registry.lua`, `health.lua`, `open.lua`, `lsp.lua`, targeted lockfile bump), then use `8-02` to harden guard clauses already present in autosave/format/LSP code, and make `8-03` an evidence-gathering pass that combines headless validation with interactive workflow checks. [VERIFIED: 08-CONTEXT.md, codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Search and explorer runtime (`Snacks.picker`, `Snacks.explorer`) | Neovim plugin runtime [VERIFIED: .config/nvim/lua/plugins/snacks.lua] | OS filesystem [VERIFIED: snacks explorer docs] | The config selects and wires the plugin; the OS only supplies file operations underneath. [VERIFIED: .config/nvim/lua/core/keymaps/registry.lua][CITED: https://github.com/folke/snacks.nvim/blob/main/docs/explorer.md] |
| Git workflow runtime (`gitsigns`, `fugitive`, `lazygit`) | Neovim plugin runtime [VERIFIED: .config/nvim/lua/plugins/git.lua, registry.lua] | External binaries (`git`, `lazygit`) [VERIFIED: environment audit] | The plugin layer owns UI behavior; the binaries are dependencies, not the source of config regressions. [VERIFIED: .config/nvim/lua/plugins/git.lua, `command -v git`, `command -v lazygit`] |
| LSP provisioning and attach behavior | Neovim runtime config [VERIFIED: .config/nvim/lua/plugins/lsp.lua] | Mason/toolchain binaries [VERIFIED: .config/nvim/lua/plugins/lsp.lua, environment audit] | `vim.lsp.config()` and `vim.lsp.enable()` own attach-time behavior, while Mason only provisions executables. [CITED: https://neovim.io/doc/user/lsp/][VERIFIED: .config/nvim/lua/plugins/lsp.lua] |
| Cross-pane navigation with tmux | Plugin-owned keymaps in Neovim [VERIFIED: .config/nvim/lua/plugins/misc.lua, registry.lua] | tmux config [VERIFIED: 08-CONTEXT.md, tmux audit] | `vim-tmux-navigator` only works correctly if repo keymaps stop shadowing its `<C-h/j/k/l>` bindings. [CITED: https://github.com/christoomey/vim-tmux-navigator][VERIFIED: .config/nvim/lua/core/keymaps/registry.lua] |
| External open behavior | Neovim core helper `vim.ui.open()` [CITED: https://neovim.io/doc/user/lua.html] | OS opener (`xdg-open`/`explorer.exe`) [CITED: https://neovim.io/doc/user/lua.html] | The repo should not shell out manually; it should only report `vim.ui.open()` failures correctly. [VERIFIED: .config/nvim/lua/core/open.lua][CITED: https://neovim.io/doc/user/lua.html] |
| Headless validation | Repo shell harness [VERIFIED: scripts/nvim-validate.sh] | Headless Neovim runtime [VERIFIED: scripts/nvim-validate.sh] | The script owns pass/fail policy; Neovim only executes the probes it is told to run. [VERIFIED: scripts/nvim-validate.sh] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Neovim | `0.12.1` [VERIFIED: `nvim --version`] | Runtime and Lua API surface | All Phase 8 defects are runtime/config interactions inside this API surface, and Neovim 0.10 deprecated `vim.tbl_flatten()`. [VERIFIED: `nvim --version`][CITED: https://neovim.io/doc/user/deprecated/] |
| `folke/lazy.nvim` | `306a055` [VERIFIED: .config/nvim/lazy-lock.json] | Plugin loading and lockfile pinning | This phase needs surgical plugin pin updates, not a broad refresh. [VERIFIED: .config/nvim/lazy-lock.json, 08-CONTEXT.md] |
| `folke/snacks.nvim` | `0a4ce56` [VERIFIED: .config/nvim/lazy-lock.json] | Search, explorer, notifier, lazygit entrypoint | Search and explorer are already standardized on Snacks in this repo. [VERIFIED: .config/nvim/lua/plugins/snacks.lua, registry.lua] |
| `neovim/nvim-lspconfig` | `d10ce09` [VERIFIED: .config/nvim/lazy-lock.json] | LSP config registration and enablement | Current LSP setup is already written against `vim.lsp.config()` / `vim.lsp.enable()` and should be hardened rather than replaced. [VERIFIED: .config/nvim/lua/plugins/lsp.lua][CITED: https://neovim.io/doc/user/lsp/] |
| `stevearc/conform.nvim` | `086a40d` [VERIFIED: .config/nvim/lazy-lock.json] | Format-on-save and manual formatting | Existing save-format policy already contains the right style of buffer/filetype guards for Phase 8. [VERIFIED: .config/nvim/lua/plugins/conform.lua][CITED: https://github.com/stevearc/conform.nvim] |
| `christoomey/vim-tmux-navigator` | `e41c431` [VERIFIED: .config/nvim/lazy-lock.json] | Split and tmux pane navigation | The repo already chose this plugin; the missing work is to stop shadowing its keymaps. [VERIFIED: .config/nvim/lua/plugins/misc.lua, registry.lua][CITED: https://github.com/christoomey/vim-tmux-navigator] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `lewis6991/gitsigns.nvim` | `8d82c24` [VERIFIED: .config/nvim/lazy-lock.json] | Hunk preview and blame UI | Use for git workflow verification and regression checks. [VERIFIED: .config/nvim/lua/plugins/git.lua, registry.lua] |
| `tpope/vim-fugitive` | `3b753cf` [VERIFIED: .config/nvim/lazy-lock.json] | Git command UX | Use for repo-integrated git flows that should not crash normal editing. [VERIFIED: .config/nvim/lua/plugins/git.lua] |
| `folke/which-key.nvim` | `3aab214` [VERIFIED: .config/nvim/lazy-lock.json] | Keymap metadata display | Keep because registry-driven descriptions already depend on it. [VERIFIED: .config/nvim/lua/plugins/misc.lua, .config/nvim/lua/core/keymaps/whichkey.lua] |
| `nvim-treesitter/nvim-treesitter` | `cf12346` [VERIFIED: .config/nvim/lazy-lock.json] | Parser-backed highlighting, incremental selection, indent hooks | Keep in the BUG-016 trace set because startup timing shows `nvim-treesitter.compat` loading and that file still calls `vim.tbl_flatten()`. [VERIFIED: startuptime log, local plugin source grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Removing registry `<C-h/j/k/l>` and keeping `vim-tmux-navigator` [VERIFIED: 08-CONTEXT.md] | Guard registry mappings behind `$TMUX` [VERIFIED: 08-CONTEXT.md] | Locked decision rejects extra branching because `vim-tmux-navigator` already falls back in non-tmux sessions. [CITED: https://github.com/christoomey/vim-tmux-navigator][VERIFIED: 08-CONTEXT.md] |
| Surgical plugin pin update [VERIFIED: 08-CONTEXT.md] | Full `:Lazy update` refresh [VERIFIED: 08-CONTEXT.md] | Full refresh increases unrelated regression surface and contradicts the locked decision. [VERIFIED: 08-CONTEXT.md] |
| `pyright` replacement for removed `basedpyright` [VERIFIED: 08-CONTEXT.md, git diff] | Leaving Python LSP absent temporarily | Leaving the partial edit as-is would desynchronize configured servers from provisioned tools. [VERIFIED: .config/nvim/lua/plugins/lsp.lua, git diff] |

**Synchronization:**
```bash
nvim --headless -u .config/nvim/init.lua --cmd "set rtp^=.config/nvim" "+Lazy! sync" +qa
```
[VERIFIED: scripts/nvim-validate.sh]

**Pin verification:** Use `.config/nvim/lazy-lock.json` as the current source of truth and update only the traced plugin for BUG-016. [VERIFIED: .config/nvim/lazy-lock.json, 08-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Keypress / Buf event / Startup
        |
        v
  core/*.lua guards
  (FocusLost, open helper, keymaps)
        |
        +--> registry.lua ------> plugin-owned action
        |                         (Snacks / Gitsigns / LSP / tmux-nav)
        |
        +--> lsp.lua -----------> vim.lsp.config/enable ---> Mason-provided binary
        |
        +--> conform.lua -------> formatter selection -----> external formatter
        |
        +--> health.lua --------> plugin/tool probes ------> validator JSON/logs
        |
        v
  User-visible workflow result
  (search, explorer, git, LSP, UI)
```
[VERIFIED: .config/nvim/lua/core/keymaps.lua, registry.lua, .config/nvim/lua/plugins/lsp.lua, .config/nvim/lua/plugins/conform.lua, .config/nvim/lua/core/health.lua, scripts/nvim-validate.sh]

### Recommended Project Structure
```text
.config/nvim/lua/core/
├── health.lua              # Headless health probes; keep aligned with active plugins
├── open.lua                # Cross-platform OS open boundary
├── keymaps.lua             # Global runtime autocmds such as FocusLost autosave
└── keymaps/
    ├── registry.lua        # Source of truth for user mappings
    └── attach.lua          # Buffer/plugin-local attachment helpers

.config/nvim/lua/plugins/
├── snacks.lua              # Search/explorer/notifier/lazygit
├── conform.lua             # Format-on-save policy
├── lsp.lua                 # LSP provisioning + attach guards
├── git.lua                 # Gitsigns/fugitive
└── misc.lua                # which-key, vim-tmux-navigator, render-markdown, csvview

scripts/
└── nvim-validate.sh        # Startup/smoke/health automation
```
[VERIFIED: codebase file list]

### Pattern 1: Plugin Owns Plugin-Specific Keys
**What:** When a plugin already provides behavior-specific mappings, remove overlapping registry keys rather than layering another generic mapping on top. [VERIFIED: 08-CONTEXT.md, registry.lua, misc.lua]
**When to use:** Use for `vim-tmux-navigator` and any future plugin that depends on exact key ownership. [CITED: https://github.com/christoomey/vim-tmux-navigator][VERIFIED: .config/nvim/lua/plugins/misc.lua]
**Example:**
```lua
-- Repo pattern for Phase 8: delete window.move_{up,down,left,right}
-- from registry.lua so vim-tmux-navigator owns <C-h/j/k/l>.
```
[VERIFIED: .config/nvim/lua/core/keymaps/registry.lua, 08-CONTEXT.md]

### Pattern 2: Guard Before Side Effects
**What:** Keep event callbacks cheap and defensive by checking buffer kind, modifiability, buffer name, and LSP client presence before calling plugin APIs or write operations. [VERIFIED: .config/nvim/lua/core/keymaps.lua, .config/nvim/lua/plugins/conform.lua, .config/nvim/lua/plugins/lsp.lua]
**When to use:** Use in `FocusLost`, `format_on_save`, `LspAttach`, and external-open helpers. [VERIFIED: codebase grep]
**Example:**
```lua
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end
  end,
})
```
// Source: https://neovim.io/doc/user/lsp/

### Pattern 3: Trace First, Then Bump One Pin
**What:** For plugin regressions exposed by Neovim deprecations, identify the caller with startup evidence and source grep before editing `lazy-lock.json`. [VERIFIED: 08-CONTEXT.md, startuptime log, local plugin grep]
**When to use:** Use for BUG-016 and any future deprecation warning. [VERIFIED: 08-CONTEXT.md]
**Example:**
```bash
nvim --headless --startuptime .planning/tmp/nvim-validate/startuptime.phase8.log \
  -u .config/nvim/init.lua --cmd "set rtp^=.config/nvim" \
  +"lua vim.defer_fn(function() vim.cmd('qa!') end, 50)"
rg -n "tbl_flatten|vim\\.tbl_flatten" \
  ~/.local/share/nvim/lazy ~/.local/share/nvim/site
```
[VERIFIED: local commands run in this session]

### Anti-Patterns to Avoid
- **Stale health probes:** `core.health.snapshot()` currently checks `neo-tree`, which guarantees a false failure because the repo no longer configures that plugin. [VERIFIED: .config/nvim/lua/core/health.lua, FAILURES.md, snacks.lua]
- **Shadowing plugin keys with registry defaults:** The current `<C-h/j/k/l>` entries override `vim-tmux-navigator` behavior and silently remove tmux-pane traversal. [VERIFIED: registry.lua, misc.lua, CHECKLIST.md][CITED: https://github.com/christoomey/vim-tmux-navigator]
- **Treating `vim.ui.open()` as an exception-throwing API:** Neovim documents it as returning `(cmd, err)`; the repo currently drops the returned error string. [VERIFIED: .config/nvim/lua/core/open.lua][CITED: https://neovim.io/doc/user/lua.html]
- **Broad lockfile refreshes for one deprecation:** This phase has a locked surgical-update policy. [VERIFIED: 08-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-platform file/URL opening | Shell-specific `xdg-open` / `start` / `open` dispatch | `vim.ui.open()` [CITED: https://neovim.io/doc/user/lua.html] | Neovim already abstracts the platform differences and returns structured failure info. [CITED: https://neovim.io/doc/user/lua.html] |
| Split + tmux pane crossing | Custom `$TMUX` keymap branching | `vim-tmux-navigator` [CITED: https://github.com/christoomey/vim-tmux-navigator] | The plugin already handles Vim-only and tmux-aware navigation; the repo just needs to stop conflicting with it. [VERIFIED: misc.lua, registry.lua][CITED: https://github.com/christoomey/vim-tmux-navigator] |
| Save-time formatter routing | Custom `BufWritePre` formatter matrix | `conform.nvim` `format_on_save` policy [CITED: https://github.com/stevearc/conform.nvim] | The repo already has filetype and buftype exclusions in one place. [VERIFIED: .config/nvim/lua/plugins/conform.lua] |
| Search/explorer UI | Ad hoc picker/explorer wrappers | `Snacks.picker` and `Snacks.explorer` [CITED: https://github.com/folke/snacks.nvim/blob/main/docs/picker.md][CITED: https://github.com/folke/snacks.nvim/blob/main/docs/explorer.md] | These are the repo’s active workflows and already match the milestone scope. [VERIFIED: snacks.lua, registry.lua] |

**Key insight:** Most Phase 8 work is about deleting stale or overlapping config so the chosen plugins can operate normally. The repo does not need new abstractions; it needs tighter ownership boundaries and cleaner validation. [VERIFIED: 08-CONTEXT.md, FAILURES.md, codebase grep]

## Common Pitfalls

### Pitfall 1: False Health Failures from Removed Plugins
**What goes wrong:** `health` fails even when the actual runtime explorer is working. [VERIFIED: `./scripts/nvim-validate.sh health`, .config/nvim/lua/core/health.lua]
**Why it happens:** `core.health.snapshot()` still probes `neo-tree`, but the repo migrated to `snacks.explorer` in v1.0. [VERIFIED: .config/nvim/lua/core/health.lua, .config/nvim/lua/plugins/snacks.lua, FAILURES.md]
**How to avoid:** Keep the probe list aligned with active plugin specs and lockfile entries. [VERIFIED: core/health.lua, lazy-lock.json]
**Warning signs:** `health.json` shows `neo-tree` as `loaded=false` while explorer keymaps still target Snacks. [VERIFIED: health run, registry.lua]

### Pitfall 2: Silent Feature Loss from Duplicate Keymaps
**What goes wrong:** Navigation appears to work inside Neovim splits, but tmux crossing is gone. [VERIFIED: FAILURES.md, CHECKLIST.md]
**Why it happens:** Startup-applied registry mappings win before plugin-owned mappings take effect. [VERIFIED: core/keymaps.lua, registry.lua, misc.lua]
**How to avoid:** Let the plugin own `<C-h/j/k/l>` entirely. [VERIFIED: 08-CONTEXT.md]
**Warning signs:** `:verbose nmap <C-h>` does not point to `vim-tmux-navigator`. [CITED: https://github.com/christoomey/vim-tmux-navigator]

### Pitfall 3: Misreading Validator Output
**What goes wrong:** Planning effort gets spent on sandbox or environment noise instead of repo defects. [VERIFIED: startup/smoke runs in this session]
**Why it happens:** The current startup/smoke runs mix real repo problems (`vim.tbl_flatten`) with sandbox-only write-path failures from treesitter parser directories and `vim.loader` cache writes. [VERIFIED: startup.log, smoke.log][CITED: https://github.com/nvim-treesitter/nvim-treesitter/wiki/Supported-Languages-Information]
**How to avoid:** Record which failures reproduce on a normal workstation versus only in the agent sandbox. [VERIFIED: local validator outputs]
**Warning signs:** Errors reference `EROFS`, `~/.cache/nvim/luac`, or plugin parser directories rather than repo file paths. [VERIFIED: smoke.log, startup.log]

### Pitfall 4: Partial LSP Table Edits
**What goes wrong:** A server disappears from `lsp_servers` but is not replaced in Mason provisioning, or vice versa. [VERIFIED: git diff, lsp.lua]
**Why it happens:** `lsp.lua` keeps runtime enablement and install lists in separate tables. [VERIFIED: .config/nvim/lua/plugins/lsp.lua]
**How to avoid:** Edit both tables in the same commit and verify `:LspInfo` / Mason package state after sync. [VERIFIED: 08-CONTEXT.md, lsp.lua]
**Warning signs:** Python files stop attaching an LSP after a seemingly harmless provider swap. [VERIFIED: lsp.lua structure]

## Code Examples

Verified patterns from official and repo sources:

### Handle `vim.ui.open()` Correctly
```lua
local cmd, err = vim.ui.open(target)
if err then
  vim.notify(err, vim.log.levels.ERROR, { title = "External Open" })
  return
end
if cmd then
  -- optional: cmd:wait()
end
```
// Source: https://neovim.io/doc/user/lua.html

### Keep Format-on-Save Guarded
```lua
format_on_save = function(bufnr)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local ft = vim.bo[bufnr].filetype
  local buftype = vim.bo[bufnr].buftype

  if buftype ~= "" and buftype ~= "acwrite" then
    return false
  end
  if not vim.bo[bufnr].modifiable or bufname == "" then
    return false
  end
  if ({ gitcommit = true, markdown = true, diff = true, qf = true })[ft] then
    return false
  end
  return { timeout_ms = 500, lsp_format = "fallback" }
end
```
// Source: repo pattern from .config/nvim/lua/plugins/conform.lua and conform docs

### Use `LspAttach` as the Guard Boundary
```lua
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end
    -- attach buffer-local mappings and guarded highlights here
  end,
})
```
// Source: https://neovim.io/doc/user/lsp/

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `vim.tbl_flatten()` in plugins | `vim.iter(...):flatten(math.huge):totable()` [CITED: https://neovim.io/doc/user/deprecated/] | Deprecated in Neovim 0.10. [CITED: https://neovim.io/doc/user/deprecated/] | BUG-016 should be fixed by tracing and updating or removing whichever pinned plugin still calls the deprecated helper. [VERIFIED: 08-CONTEXT.md, local plugin grep] |
| `neo-tree` explorer/probe assumptions | `snacks.explorer` as active explorer [VERIFIED: snacks.lua, FAILURES.md] | Repo v1.0 migration. [VERIFIED: FAILURES.md, PROJECT.md] | Validation and docs must stop probing removed plugins. [VERIFIED: core/health.lua, FAILURES.md] |
| Explicit shell open commands | `vim.ui.open()` [CITED: https://neovim.io/doc/user/lua.html] | Repo v1.0 migration. [VERIFIED: PROJECT.md, README.md, open.lua] | Phase 8 only needs to fix return-value handling, not replace the approach. [VERIFIED: open.lua] |
| Registry-owned `<C-h/j/k/l>` window movement | `vim-tmux-navigator`-owned split/tmux navigation [VERIFIED: 08-CONTEXT.md] | Locked for Phase 8 on 2026-04-22. [VERIFIED: 08-CONTEXT.md] | Removes silent tmux-navigation regression risk. [VERIFIED: 08-CONTEXT.md, CHECKLIST.md] |

**Deprecated/outdated:**
- `core.health.lua` probing `neo-tree` is outdated for this repo. [VERIFIED: .config/nvim/lua/core/health.lua, .config/nvim/lua/plugins/snacks.lua]
- Leaving `basedpyright` removed without adding `pyright` is an unstable intermediate state. [VERIFIED: git diff, 08-CONTEXT.md]
- Treating the validator as environment-neutral is outdated; current `startup`/`smoke` behavior depends on writable treesitter/cache paths. [VERIFIED: startup.log, smoke.log]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| None | All research claims below are verified or cited. [VERIFIED: this document] | — | — |

## Open Questions (RESOLVED FOR PLANNING)

1. **Which exact pinned plugin is BUG-016?**
   - Resolved planning disposition: the exact caller remains an execution-time trace gate inside Plan `08-01`, not an open planning blocker. The plan now requires trace-confirm-first, then one surgical lockfile change only after attribution is confirmed. [VERIFIED: 08-CONTEXT.md, 08-01-PLAN.md]
   - Current bounded candidate set: `nvim-treesitter.compat` remains the strongest candidate from startup timing, but the executor must record the actual plugin name in the summary before editing `lazy-lock.json`. [VERIFIED: startuptime log, local plugin grep, 08-01-PLAN.md]

2. **Should Treesitter parser install paths be hardened later?**
   - Resolved planning disposition: this is out of core Phase 8 scope unless it reproduces outside the agent sandbox on a normal workstation. Treat it as validator/environment triage, not a gated Phase 8 code requirement. [VERIFIED: phase scope docs, 08-RESEARCH.md Summary]
   - Routing decision: if workstation repro appears during execution, record it as follow-up validation hardening for Phase 10 rather than widening Phase 8 opportunistically. [VERIFIED: REQUIREMENTS.md, ROADMAP.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `nvim` | All Phase 8 work | ✓ [VERIFIED: environment audit] | `0.12.1` [VERIFIED: environment audit] | — |
| `git` | `lazy.nvim`, gitsigns, fugitive, validator | ✓ [VERIFIED: environment audit] | `2.53.0` [VERIFIED: environment audit] | — |
| `rg` | Search workflow and some validator/tooling checks | ✓ [VERIFIED: environment audit] | `15.1.0` [VERIFIED: environment audit] | Manual file navigation only. [VERIFIED: dependency role in project docs and local tooling] |
| `tmux` | `vim-tmux-navigator` cross-pane verification | ✓ [VERIFIED: environment audit] | `3.6a` [VERIFIED: environment audit] | Non-tmux fallback still works inside Neovim. [CITED: https://github.com/christoomey/vim-tmux-navigator] |
| `lazygit` | `<leader>gg` workflow verification | ✓ [VERIFIED: environment audit] | `0.61.1` [VERIFIED: environment audit] | Git verification can still use fugitive/gitsigns if absent. [VERIFIED: registry.lua, git.lua] |
| `tree-sitter` CLI | Parser updates for `nvim-treesitter` | ✓ [VERIFIED: environment audit] | `0.26.8` [VERIFIED: environment audit] | Existing parsers may still work if no update is needed. [CITED: https://github.com/nvim-treesitter/nvim-treesitter] |

**Missing dependencies with no fallback:**
- None on this Linux workstation for the Phase 8 target flows. [VERIFIED: environment audit]

**Missing dependencies with fallback:**
- Windows-specific verification is not available in this Linux session; Phase 8 should plan manual Windows confirmation for `vim.ui.open()` and non-tmux navigation fallback. [VERIFIED: current environment, project constraints]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Shell-based Neovim validation harness in `scripts/nvim-validate.sh`. [VERIFIED: scripts/nvim-validate.sh] |
| Config file | none — behavior is encoded directly in `scripts/nvim-validate.sh`. [VERIFIED: scripts/nvim-validate.sh] |
| Quick run command | `./scripts/nvim-validate.sh startup` [VERIFIED: scripts/nvim-validate.sh] |
| Full suite command | `./scripts/nvim-validate.sh all` [VERIFIED: scripts/nvim-validate.sh] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BUG-02 | Search/explorer/git/LSP/UI workflows do not error from config. [VERIFIED: REQUIREMENTS.md] | headless baseline + interactive verification | `./scripts/nvim-validate.sh health` plus manual search/explorer/git/LSP walkthrough. [VERIFIED: scripts/nvim-validate.sh, 08-CONTEXT.md] | ✅ |
| BUG-03 | Common editing sessions do not crash from config code. [VERIFIED: REQUIREMENTS.md] | headless startup + guarded manual editing session | `./scripts/nvim-validate.sh startup` plus manual save/format/LSP attach checks. [VERIFIED: scripts/nvim-validate.sh, 08-CONTEXT.md] | ✅ |

### Sampling Rate
- **Per task commit:** `./scripts/nvim-validate.sh startup` [VERIFIED: scripts/nvim-validate.sh]
- **Per wave merge:** `./scripts/nvim-validate.sh health` after `core/health.lua` is fixed. [VERIFIED: scripts/nvim-validate.sh, 08-CONTEXT.md]
- **Phase gate:** `startup`, `health`, and an interactive workflow pass for search/explorer/git/LSP/UI before Phase 8 closes. [VERIFIED: 08-CONTEXT.md]

### Wave 0 Gaps
- [ ] `scripts/nvim-validate.sh` still probes `neo-tree`; Phase 8 must fix that before `health` can gate BUG-02. [VERIFIED: scripts/nvim-validate.sh, core/health.lua, health run]
- [ ] No automated probe currently exercises Snacks search/explorer or `vim.ui.open()` end-to-end; those remain manual in `8-03`. [VERIFIED: scripts/nvim-validate.sh, registry.lua]
- [ ] `smoke` is not agent-sandbox-safe because `nvim -l` plus `vim.loader` writes to an unwritable cache path here. [VERIFIED: smoke.log]
- [ ] No automated assertion currently detects the partial `basedpyright`→`pyright` transition. [VERIFIED: git diff, lsp.lua]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: repo scope] | — |
| V3 Session Management | no [VERIFIED: repo scope] | — |
| V4 Access Control | no [VERIFIED: repo scope] | — |
| V5 Input Validation | yes [VERIFIED: codebase guard patterns] | Buffer/path guard clauses before writes, formatting, or OS-open calls. [VERIFIED: core/keymaps.lua, conform.lua, open.lua, lsp.lua] |
| V6 Cryptography | no [VERIFIED: repo scope] | — |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsafe external open command composition | Tampering | Use `vim.ui.open()` instead of constructing shell strings. [CITED: https://neovim.io/doc/user/lua.html][VERIFIED: open.lua] |
| Writes triggered in special/non-file buffers | Tampering | Gate autosave and format-on-save on `buftype`, `modifiable`, and non-empty buffer names. [VERIFIED: core/keymaps.lua, conform.lua] |
| Plugin/API calls on missing LSP clients | Denial of Service | Check `vim.lsp.get_client_by_id()` and only register per-buffer extras once. [VERIFIED: lsp.lua][CITED: https://neovim.io/doc/user/lsp/] |

## Sources

### Primary (HIGH confidence)
- Repo code and planning artifacts (`08-CONTEXT.md`, `FAILURES.md`, `CHECKLIST.md`, `REQUIREMENTS.md`, `PROJECT.md`, `core/open.lua`, `core/health.lua`, `plugins/lsp.lua`, `plugins/snacks.lua`, `plugins/conform.lua`, `registry.lua`, `scripts/nvim-validate.sh`) — phase scope, active runtime stack, current defects. [VERIFIED: codebase reads in this session]
- Neovim Lua docs — `vim.ui.open()` return contract: https://neovim.io/doc/user/lua.html [CITED: https://neovim.io/doc/user/lua.html]
- Neovim LSP docs — `LspAttach` event data and attach pattern: https://neovim.io/doc/user/lsp/ [CITED: https://neovim.io/doc/user/lsp/]
- Neovim deprecated docs — `vim.tbl_flatten()` deprecated in 0.10: https://neovim.io/doc/user/deprecated/ [CITED: https://neovim.io/doc/user/deprecated/]
- `snacks.nvim` explorer docs: https://github.com/folke/snacks.nvim/blob/main/docs/explorer.md [CITED: https://github.com/folke/snacks.nvim/blob/main/docs/explorer.md]
- `conform.nvim` docs: https://github.com/stevearc/conform.nvim [CITED: https://github.com/stevearc/conform.nvim]
- `vim-tmux-navigator` docs: https://github.com/christoomey/vim-tmux-navigator [CITED: https://github.com/christoomey/vim-tmux-navigator]
- `nvim-treesitter` parser install docs: https://github.com/nvim-treesitter/nvim-treesitter/wiki/Supported-Languages-Information [CITED: https://github.com/nvim-treesitter/nvim-treesitter/wiki/Supported-Languages-Information]

### Secondary (MEDIUM confidence)
- Local startup timing and source grep against `~/.local/share/nvim/lazy/*` — narrowed BUG-016 candidate set and validated current pinned plugin code still containing `vim.tbl_flatten()`. [VERIFIED: commands run in this session]

### Tertiary (LOW confidence)
- None. [VERIFIED: this research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - active plugins, pins, and runtime ownership are directly visible in repo code and lockfile. [VERIFIED: codebase, lazy-lock.json]
- Architecture: MEDIUM - the fault boundaries are clear, but the exact BUG-016 caller still needs one final trace step before implementation. [VERIFIED: validator output, local plugin grep]
- Pitfalls: MEDIUM - most are directly reproduced, but sandbox-specific validator noise needs normal-workstation confirmation before turning into code work. [VERIFIED: local validator runs]

**Research date:** 2026-04-22
**Valid until:** 2026-05-22
