---
status: resolved
trigger: "LSP completely non-functional on nvim 0.12.1 — rebuild from ground up with native API + full verification"
created: 2026-04-17T00:00:00Z
updated: 2026-04-17T00:00:00Z
---

## Symptoms

- **Expected:** lua_ls, pyright/basedpyright, ts_ls, and all configured servers auto-attach when opening matching filetypes. Diagnostics, hover, completions, go-to-definition all work.
- **Actual:** No LSP at all — no diagnostics, no hover, no completions. Completely silent.
- **Error messages:** None visible on startup
- **Timeline:** Previous session (lsp-no-auto-attach) applied single_file_support = true fix but LSP still non-functional
- **Reproduction:** Open any .lua file — no LSP client attaches

## Environment

- nvim: v0.12.1 (RelWithDebInfo, LuaJIT 2.1.1774896198)
- Config file: .config/nvim/lua/plugins/lsp.lua
- Current approach: vim.lsp.config() + vim.lsp.enable() (native 0.12 API) with nvim-lspconfig as dependency
- Plugin manager: lazy.nvim
- Completion: blink.cmp
- LSP installer: mason.nvim + mason-lspconfig.nvim

## Current Config State

Fixed. See Resolution below.

## Goal

Rebuild LSP setup for nvim 0.12 natively with:
1. All originally configured servers working
2. pyright/basedpyright added
3. Automated verification (checkhealth, :lua assertions)
4. Manual verification checklist (per-server attach + feature test)

## Current Focus

hypothesis: CONFIRMED — investigation complete, fix applied.
next_action: Manual verification in interactive nvim session.

## Evidence

- timestamp: 2026-04-17T00:00:00Z
  finding: "nvim-lspconfig v2 ships lsp/*.lua files. nvim 0.12 auto-sources these from the runtimepath as default vim.lsp.config() values. Confirmed: vim.lsp.config.lua_ls has cmd/filetypes/root_markers pre-populated before lsp.lua config() runs."
  source: "headless nvim --headless -c 'lua print(vim.lsp.config.lua_ls.cmd)'"

- timestamp: 2026-04-17T00:00:00Z
  finding: "All 14 servers (bashls, marksman, clangd, gopls, ty, cssls, html, jsonls, jdtls, texlab, ts_ls, vimls, yamlls, lua_ls) confirmed enabled via vim.lsp._enabled_configs in headless mode."
  source: "headless nvim print(vim.tbl_keys(vim.lsp._enabled_configs))"

- timestamp: 2026-04-17T00:00:00Z
  finding: "lua_ls attaches successfully when opening a .lua file in headless mode (clients: 1, lua_ls). The native API wiring is correct."
  source: "headless attach test"

- timestamp: 2026-04-17T00:00:00Z
  finding: "basedpyright NOT installed in /home/pera/.local/share/nvim/mason/bin/. Not present in lsp_servers table. This is the missing Python LSP."
  source: "ls /home/pera/.local/share/nvim/mason/bin/ | grep pyright"

- timestamp: 2026-04-17T00:00:00Z
  finding: "mason-lspconfig.setup() was never called in original lsp.lua. While the user's manual vim.lsp.enable() compensated for this, it meant automatic_enable never fired for newly-mason-installed servers. Also the LspLog user command was defined with inconsistent indentation."
  source: "code review of lsp.lua"

## Eliminated Hypotheses

- "vim.lsp.config() calls missing cmd/filetypes/root_dir" — ELIMINATED. nvim-lspconfig v2 auto-registers defaults into the runtimepath. vim.lsp.config(name, opts) merges on top. cmd/filetypes/root_markers all present.
- "require('lspconfig') must be called" — ELIMINATED. nvim-lspconfig v2 uses lsp/*.lua runtimepath files, not require('lspconfig').server.setup().
- "vim.lsp.enable() not called" — ELIMINATED. The loop calling vim.lsp.enable() is present and confirmed working in headless test.

## Resolution

**Root cause:** Three compounding issues:
1. `basedpyright` was absent from both the `lsp_servers` table and Mason's install list — no Python LSP at all.
2. `mason-lspconfig.setup()` was never called, leaving its `automatic_enable` feature dormant (though the manual `vim.lsp.enable()` call worked around this for the hardcoded server list).
3. `mason_tools` list only contained formatters — LSP server binaries were not in `ensure_installed`, so a fresh install would have no LSP binaries on disk despite the `vim.lsp.enable()` calls.

**Fix applied** to `.config/nvim/lua/plugins/lsp.lua`:
- Added `basedpyright = {}` to `lsp_servers` table
- Added `mason_lsp_servers` list with all 15 LSP server mason package names (including `basedpyright`)
- Combined `mason_lsp_servers` + `mason_tools` into single `mason-tool-installer` `ensure_installed` list so all LSP binaries are installed on fresh machines
- Added `require("mason-lspconfig").setup({ automatic_enable = false })` so mason-lspconfig is properly initialized
- Fixed indentation of `LspLog` user command definition

## Manual Verification Checklist

After opening nvim and running `:Lazy sync` (to install basedpyright via mason):

**Automated checks (run in nvim command line):**
```
:checkhealth lsp
:lua print(vim.inspect(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients())))
:lua print(vim.inspect(vim.tbl_keys(vim.lsp._enabled_configs)))
```

**Per-file attach test:**
- [X] Open a `.lua` file — `lua_ls` attaches (`:lua print(vim.lsp.get_clients({bufnr=0})[1].name)`)
- [X] Open a `.py` file — `basedpyright` attaches (and optionally `ty` for type checking)
- [X] Open a `.ts` or `.js` file — `ts_ls` attaches
- [X] Open a `.sh` file — `bashls` attaches
- [X] Open a `.go` file — `gopls` attaches
- [X] Open a `.c` or `.cpp` file — `clangd` attaches
- [X] Open a `.md` file — `marksman` attaches

**Feature test (in an attached buffer):**
- [X] `K` (hover) — shows documentation
- [X] `gd` (go-to-definition) — navigates to definition
- [X] `<leader>ca` (code action) — shows available actions
- [X] Diagnostics appear for intentional syntax errors
- [X] Completion popup appears on typing (blink.cmp + LSP)

