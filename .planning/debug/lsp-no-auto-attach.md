---
status: resolved
trigger: "LSP not auto-attaching - lua_ls doesn't start when opening .lua files"
created: 2026-04-16T13:23:55Z
updated: 2026-04-16T13:23:55Z
---

## Symptoms

- **Expected:** Opening a .lua file should auto-attach lua_ls LSP
- **Actual:** No LSP attaches, :LspStart/:LspRestart commands not available
- **Error messages:** E492: Not an editor command: LspStart
- **Timeline:** Since config setup, LSP never auto-attached
- **Reproduction:** Open any .lua file, run :LspInfo — shows no clients

## Current Focus

**Hypothesis:** nvim-lspconfig's `lua_ls` config uses `root_markers` without `single_file_support`, causing `vim.lsp.start()` to skip starting the server when no root markers exist (e.g., `/tmp/` or non-git projects).

**Next action:** Apply fix — add `single_file_support = true` to lua_ls config

## Evidence

- timestamp: 2026-04-16T13:30:00Z
  **Test:** `nvim --version` → NVIM v0.12.1, but `:LspStart` not found (E492)
  **Finding:** `:LspStart` is provided by nvim-lspconfig plugin, but blocked by Neovim 0.11+ guard
  **Evidence:** `vim.fn.exists(':lsp')` returns `2` (built-in `:lsp` command exists), causing nvim-lspconfig's plugin guard to return early without registering `:LspStart`/`:LspRestart`/`:LspInfo`
- timestamp: 2026-04-16T13:35:00Z
  **Test:** Open `.lua` file in headless neovim — filetype=lua, `vim.lsp.get_active_clients()` → `0`
  **Finding:** `lua_ls` is NOT auto-attaching even though `vim.lsp.enable()` was called
- timestamp: 2026-04-16T13:40:00Z
  **Test:** `nvim --headless -c 'lua print(vim.lsp.is_enabled("lua_ls"))'` → `true`
  **Finding:** `lua_ls` IS in `vim.lsp._enabled_configs` — `vim.lsp.enable()` WAS called during startup
  **Finding:** `lua_ls` IS in `vim.lsp.config` — the config function ran correctly
  **Finding:** No FileType autocmd for `lua` pattern — the `vim.lsp.enable` autocmd fires but `lua_ls` fails to start
- timestamp: 2026-04-16T13:45:00Z
  **Test:** Manually call `vim.lsp.start()` with `root_dir = vim.fs.root(bufnr, root_markers)` for `/tmp/test.lua`
  **Finding:** `vim.fs.root()` returns `nil` because no root markers (`.git`, `.luarc.json`, etc.) exist in `/tmp/`
  **Finding:** `vim.lsp.start()` returns early at workspace_required check (line 744-751 of vim/lsp.lua) — `root_dir` is nil and no workspace folders
  **Finding:** nvim-lspconfig's `lsp/lua_ls.lua` uses `root_markers` only (no `root_dir`) and lacks `single_file_support = true`
  **Finding:** `vim.lsp.config["lua_ls"]` resolved config has: `name, cmd, filetypes, root_markers, settings, capabilities` — NO `root_dir`, NO `single_file_support`
- timestamp: 2026-04-16T13:50:00Z
  **Test:** Compare `lsp/` (new) vs `configs/` (old) nvim-lspconfig directories
  **Finding:** `lua_ls.lua` EXISTS in `lsp/` with the new format (flat fields), not in deprecated `configs/` directory
  **Finding:** The `lsp/` format uses `root_markers` (not `root_dir`) which is incompatible with the `workspace_required` check in Neovim 0.12's `vim.lsp.start()` when no markers are found

## Eliminated

- **Require failure for `core.keymaps.attach`:** File exists at `lua/core/keymaps/attach.lua` — ELIMINATED
- **Neovim version incompatibility:** Running 0.12.1 which supports all used APIs — ELIMINATED
- **`ty` server causing `vim.lsp.enable()` to fail:** All 15 servers are enabled (confirmed in `_enabled_configs`) — ELIMINATED
- **`blink.cmp.get_lsp_capabilities` not existing:** Function exists in installed blink.cmp version — ELIMINATED
- **`:LspStart` command should exist natively in Neovim:** Built-in `:lsp` command (lowercase) exists, but `:LspStart` (from nvim-lspconfig) is shadowed — ELIMINATED as root cause for the auto-attach failure

## Root Cause

The nvim-lspconfig `lua_ls` config uses the new `root_markers` API (Neovim 0.11+ format) but lacks `single_file_support`. When `vim.lsp.enable()` is called, the FileType autocommand fires for `.lua` buffers, but `vim.lsp.start()` skips starting `lua_ls` because:
1. `vim.fs.root()` returns `nil` when no root markers exist in `/tmp/` or outside a git project
2. `lua_ls` has no `workspace_required = false` override and no `single_file_support = true`
3. `vim.lsp.start()` returns early without starting the client

## Fix Applied

Two changes to the `lua_ls` entry in `lsp_servers`:
1. `single_file_support = true` - allows LSP to start without a workspace directory
2. `root_dir` as a **function** that always calls its callback with a fallback to the file's directory

The `root_dir` function:
```lua
root_dir = function(bufnr, on_resolved)
    local fname = vim.api.nvim_get_name(bufnr)
    local dir = vim.fs.dirname(fname)
    local resolved = vim.fs.root(dir, { ".git" }) or dir or "."
    on_resolved(resolved)
end,
```

This ensures:
- In git projects: uses the git root directory
- For single files: falls back to the file's directory

## Verification

✅ **PASSED** - Verified 2026-04-16

### Test 1: Single file (no git)
```bash
nvim --headless -c 'edit /tmp/test.lua' -c 'sleep 3' -c 'lua print(#vim.lsp.get_clients())'
```
Result: `1` client (lua_ls), root_dir = `/tmp`

### Test 2: Inside git project
```bash
cd ~/.dotfiles && nvim --headless -c 'edit .config/nvim/init.lua' -c 'sleep 3' -c 'lua print(#vim.lsp.get_clients())'
```
Result: `1` client (lua_ls), root_dir = `/home/pera/github_repo/.dotfiles`

### Test 3: Commands
- `:LspLog` - Opens LSP log file ✓
- `vim.lsp.is_enabled("lua_ls")` - Returns `true` ✓

## Files Changed

- `.config/nvim/lua/plugins/lsp.lua` (dotfiles repo)
- `~/.config/nvim/lua/plugins/lsp.lua` (user's running config - in sync)

## Resolution

**Root Cause:** nvim-lspconfig's `lua_ls` config lacked `single_file_support` and used `root_markers` which returns `nil` for single files outside git projects, causing `vim.lsp.start()` to skip starting the client.

**Fix Applied:** Added `single_file_support = true` and a `root_dir` function that always fires its callback with a fallback to the file's directory.

**Verification:** Confirmed working for both single files (`/tmp/test.lua`) and files inside git projects.

**Status:** RESOLVED
