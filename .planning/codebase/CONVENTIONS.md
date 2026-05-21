# Conventions

**Analysis Date:** 2026-05-21

## Naming Patterns

**Files:**
- Neovim Lua config uses `snake_case` for filenames: `lsp.lua`, `blink-cmp.lua`, `keymaps.lua`, `treesitter.lua`, `whichkey.lua`, `vim-indent-object.lua`
- Shell scripts use `kebab-case`: `nvim-validate.sh`, `nvim-audit-failures.sh`, `clone_repo.sh`, `system_monitor.sh`, `smartctl-wrapper.sh`
- Python files use `snake_case`: `migrate_add_target_host.py`, `migrate_csv_to_sqlite.py`
- QML files use `PascalCase`: `Bar.qml`, `BarContent.qml`, `VolumeOsd.qml`, `ModulePill.qml`
- Config files match their tool name: `hyprland.conf`, `kitty.conf`, `wezterm.lua`, `starship.toml`, `config.rasi`
- One Lua module per domain/plugin under `lua/plugins/` e.g., `lsp.lua`, `git.lua`, `treesitter.lua`, `misc.lua`
- Core infrastructure modules under `lua/core/`: `options.lua`, `keymaps.lua`, `open.lua`, `health.lua`
- Keymap submodules grouped in `lua/core/keymaps/`: `registry.lua`, `apply.lua`, `lazy.lua`, `attach.lua`, `whichkey.lua`

**Functions:**
- Lua uses `snake_case` for function names: `apply_global()`, `apply_lsp()`, `get_by_scope()`, `open_current_buffer()`, `notify_error()`, `cmd_startup()`, `scan_todo_fixme()`
- `camelCase` appears where upstream plugin APIs use it: `openAllFolds()`, `closeAllFolds()`, `peekFoldedLinesUnderCursor()`, `Snacks.picker.files()`
- Shell functions use `snake_case`: `cmd_startup()`, `cmd_sync()`, `cmd_health()`, `print_tail()`, `get_environment()`, `derive_owner()`
- Anonymous inline callback functions are the default pattern for keymap actions and Neovim autocmds

**Variables:**
- Lua uses `snake_case` for local variables: `local lazypath`, `local lsp_servers`, `local mason_tools`, `local bufnr`, `local bufname`
- Shell uses `UPPER_CASE` for constants and environment-facing vars: `SCRIPT_DIR`, `REPO_ROOT`, `REPORT_DIR`, `PLUGIN_LIST`, `TOOL_LIST`, `CACHE_FILE`, `BIND_HOST`, `PORT`
- Shell uses `snake_case` for local/loop variables: `local file`, `local lines`, `local rc`, `local key`, `local tool`
- QML properties use `camelCase`: `font_size`, `window_decorations`, `window_background_opacity`, `color_scheme`, `enable_tab_bar`

**Types:**
- No custom Lua type definitions found
- EmmyLua annotations used sparingly: `---@module "blink.cmp"`, `---@type CsvView.Options`, `---@param bufnr number`, `---@return table[]`
- EmmyLua comments appear in `blink-cmp.lua`, `csvview.nvim` config in `misc.lua`, and `lazy.lua`

## Code Style

**Formatting:**
- Lua files use **tabs** for indentation — confirmed across all `plugins/*.lua`, `core/*.lua`, `core/keymaps/*.lua`
- `init.lua` uses tabs (modeline: `vim: ts=2 sts=2 sw=2 et`)
- `options.lua` uses spaces (2-space indent) — only file with different indentation; mixed convention
- Shell scripts use 2-space or 4-space indentation inconsistently: `nvim-validate.sh` and `nvim-audit-failures.sh` use tabs, some platform scripts use spaces
- QML files use 4-space indentation (e.g., `shell.qml`, `Bar.qml`)
- `stylua` is the configured Lua formatter (in `conform.lua`: `lua = { "stylua" }`) but no `.stylua.toml` found; formatting enforcement is Mason-installed, not project-enforced

**Quotes:**
- Lua strings predominantly use **double quotes**: `"stylua"`, `"snacks"`, `"bdelete!<CR>"`
- Single quotes used in some Lua strings, but double quotes are dominant
- Shell strings use double quotes for variable expansion, single quotes for literals
- JSON configs use standard JSON double-quote syntax

**Commas:**
- Trailing commas are **standard practice** in multiline Lua tables — used consistently across plugin configs
- No trailing commas in single-line tables

**Comment Style:**
- Lua: `--` for single-line, `---` for doc-comments (EmmyLua), `--[[ ]]` for block comments (not found in current code)
- Shell: `#` for comments
- QML: `//` for comments
- Heavy use of section banners with `===` or `---` separator lines in larger files
- All Lua module files in the keymap subsystem start with `--- TODO:` header comment

**Code Organization Within Files:**
- Plugin files are typically one `return { ... }` block with inline config
- Keymap registry (`registry.lua`) organized by scope sections with banner comments: `-- ========================================`
- `lsp.lua` organized sequentially: diagnostics config, server list, mason setup, LSP attach autocmd
- Shell validation scripts organized by subcommand functions with banner sections
- `open.lua` is a small utility module with clear function-per-responsibility pattern

## Import Organization

**Lua Modules:**
- `require()` calls appear at the top of files or top of function scope
- No formal grouping convention — `require()` calls are inline where needed
- Deferred `require()` inside callbacks is common for lazy loading: `require("ufo").openAllFolds()`
- No barrel files (`init.lua` re-exports) — each module is loaded directly by path
- Example from `lsp.lua`: `local attach = require("core.keymaps.attach")` at top of `config()` closure

**Shell Scripts:**
- No formal import mechanism — scripts are standalone executables
- `source` not used across scripts; `bash` subshell calls for tool invocation
- Shared logic (e.g., `derive_owner()`) is duplicated across `nvim-validate.sh` and `nvim-audit-failures.sh`

**QML:**
- `import` statements at the top of each QML file: `import Quickshell`, `import QtQuick`

## Error Handling

**Lua:**
- Startup-critical failures use `error()`: `error("Error cloning lazy.nvim:\n" .. out)` in `init.lua`
- Defensive `pcall(require, ...)` wrapping for optional dependencies: `local ok, which_key = pcall(require, "which-key")`
- Multiple guard clauses pattern in callbacks — `lsp.lua` `LspAttach` callback has three sequential guard returns (client validity, buffer validity, buftype check)
- Guard clauses used in `conform.lua` `format_on_save`: buftype check, modifiable check, unnamed buffer check, filetype exclusion
- Auto-save in `keymaps.lua` uses five guard conditions before writing
- `open.lua` uses explicit nil/empty checks with user-facing error notifications
- `health.lua` wraps every section in `pcall` so probe crashes become health errors rather than uncaught exceptions

**Shell:**
- `set -euo pipefail` is the standard safety header across all shell scripts — 70+ files consistently use this
- Exit code checking with explicit `local rc=$?` and `if [[ $rc -ne 0 ]]; then` pattern
- `set -x` used in platform install scripts (`arch/*.sh`, `debian/*.sh`, `ubuntu/*.sh`) for verbose debugging
- `print_tail` helper in `nvim-validate.sh` surfaces the last N lines of a log on failure
- Graceful fallback: `ping_status.sh` uses `FALLBACK` JSON and `exit 0` on curl failure

**Notable absence:**
- No centralized error handling abstraction in either Lua or shell
- No custom error types or error propagation patterns

## Logging

**Lua:**
- No dedicated logging library
- User feedback delegated to Neovim UI via `vim.notify()`: `vim.notify("[keymaps.apply] Unknown mapping ID: " .. id, vim.log.levels.WARN)`
- `vim.log.levels.ERROR`, `WARN`, `DEBUG` used where appropriate
- `vim.health.*` functions used for diagnostic output (not runtime logging)
- Health system provides structured reporting via `core.health.snapshot()` which writes JSON

**Shell:**
- `echo "==> step: description..."` pattern for progress logging in validation scripts
- `echo "FAIL: ..." >&2` for error output to stderr
- `echo "PASS: ..."` for success confirmation
- Standard `echo "[INSTALL] package"` / `echo "[CONFIG] component"` pattern in platform scripts

**QML/Other:**
- No logging patterns observed in QML or config files

## Comments

**Style and Frequency:**
- **Heavy commenting** throughout the Neovim Lua config — near-executable-level documentation in every file
- Comments explain *why* not just *what*: e.g., the `open.lua` has a multi-line comment explaining why `pcall` must not wrap `vim.ui.open()`
- Each plugin file starts with `--- TODO: One-line purpose description`
- `keymaps/registry.lua` has extensive documentation of the keymap data structure at the top
- `lsp.lua` has multi-line inline notes about version compatibility, Mason exclusion rationale, and guard clause motivations

**Banner/Separator Patterns:**
- `-- ============================================================================` used as major section divider (80+ char width)
- `-- ─── Section helpers ──────────────────────────────────────────────────────────` used in `health.lua` with Unicode box-drawing
- `-- NOTE: Section label` for subsections, e.g., `-- NOTE: Leader key setup`
- `---` (triple dash) used for doc-comment headers on files

**Documentation Conventions:**
- No full JSDoc/TSDoc-style documentation — EmmyLua annotations only for type hints
- Inline comments are the primary documentation vehicle
- `options.lua` has parenthetical `(default: value)` after each option to document the Neovim default
- Cross-reference comments reference decision IDs like `-- D-04`, `-- D-08`, `-- D-11` (linking to design decisions)
- `scripts/nvim-validate.sh` has comprehensive header documenting all subcommands with usage block

## Function Design

**Size:**
- Most Lua functions are compact (2-15 lines) — single responsibility
- Notable exceptions: `lsp.lua` `LspAttach` callback (~30 lines), `ufo.lua` fold handler (~25 lines)
- Shell functions are larger — `cmd_health()` in `nvim-validate.sh` is ~80 lines, `cmd_checkhealth()` ~100 lines

**Parameters:**
- Lua functions use named parameters with expected types noted in EmmyLua: `---@param bufnr number`
- Some functions accept `opts` table (options bag pattern): `M.snapshot(opts)`
- Shell functions use `local name="$1"` positional parameter capture at the top of each function
- No default parameter values in Lua (manual nil coalescing instead)

**Return Values:**
- Lua module functions consistently return tables or primitive values
- Guard clause pattern: early return `nil` or `false` on failure, return value on success
- Shell functions return exit codes (0 for success, 1 for failure); output via stdout or file writes
- `health.lua` functions return structured tables from probes: `{ name, available, path, required, affected_feature, install_hint }`

## Module Design

**Export Patterns:**
- Standard Lua module pattern: `local M = {}` ... `return M`
- Plugin spec modules return a table directly: `return { "plugin/name", opts = {...} }`
- Array-of-specs pattern used for `misc.lua` and `git.lua` which return `{ {...}, {...} }` for multiple specs

**Module Size and Scope:**
- Plugin files are small: 10-100 lines each
- Utility modules: `open.lua` (47 lines), `apply.lua` (54 lines), `whichkey.lua` (73 lines)
- Larger modules: `lsp.lua` (194 lines), `health.lua` (239 lines), `registry.lua` (887 lines — largest, but mostly data)
- `registry.lua` is mostly declarative keymap data (800+ lines of table definitions); logic is ~60 lines
- Shell validation scripts are large single files: `nvim-validate.sh` (773 lines), `nvim-audit-failures.sh` (338 lines)

**File Responsibilities:**
- One file per plugin domain — clear single responsibility
- `misc.lua` is the exception: collects multiple unrelated small plugins (which-key, autopairs, todo-comments, render-markdown, csvview)
- Keymap subsystem split across 5 files: `keymaps.lua` (bootstrap), `registry.lua` (data), `apply.lua` (global apply), `lazy.lua` (lazy compile), `attach.lua` (buffer-local apply), `whichkey.lua` (which-key registration)
- Health subsystem split: `core/health.lua` (probe infrastructure + snapshot) and `config/health.lua` (full report)
- Platform shell scripts (`arch/*.sh`, `debian/*.sh`, `ubuntu/*.sh`) are one file per tool/package

---

*Convention analysis: 2026-05-21*
