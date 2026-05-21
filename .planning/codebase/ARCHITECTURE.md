# Architecture

**Analysis Date:** 2026-05-21

## Pattern Overview

**Overall:** Modular lazy-loaded Neovim configuration with centralized declarative keymap registry.

**Key Characteristics:**
- **Single entry point** — `init.lua` loads core modules first, then bootstraps `lazy.nvim` and discovers plugins
- **Plugin-per-file separation** — each plugin or plugin group lives in its own file under `lua/plugins/`, returned as a lazy.nvim spec table
- **Centralized keymap registry** — all custom mappings declared declaratively in `lua/core/keymaps/registry.lua` with scope, domain, and metadata
- **Scope-based keymap dispatch** — mappings applied by scope (global/lazy/buffer/plugin-local) via dedicated submodules
- **Neovim-native LSP registration** — uses `vim.lsp.config()` + `vim.lsp.enable()` (Neovim 0.12+), deprecates legacy `lspconfig[server].setup()` pattern
- **Cross-platform guarding** — OS-specific behavior (xdg-open, tmux, vim.ui.open) gated inside config code
- **Declarative health system** — `lua/config/health.lua` produces structured health checks; `core.health.lua` provides reusable probe infrastructure
- **External validation harness** — `scripts/nvim-validate.sh` orchestrates headless startup/sync/smoke/health/checkhealth tests

## Layers

### Layer: Entry Point
- **Purpose**: Start the plugin manager, set runtime path, apply initial guards, load core modules
- **Location**: `.config/nvim/init.lua`
- **Contains**: lazy.nvim bootstrap (clones if missing); Treesitter nil-node guard; `require("core.options")`; `require("core.keymaps")`; `require("lazy").setup("plugins")`
- **Depends on**: Built-in `vim` API, `git` for lazy clone
- **Used by**: Neovim startup process

### Layer: Core Modules
- **Purpose**: Define editor-wide defaults independent of any single plugin
- **Location**: `.config/nvim/lua/core/`
- **Files**:
  - `options.lua` — All `vim.o`, `vim.bo`, `vim.wo` defaults (line numbers, clipboard, tabs, search, UI)
  - `keymaps.lua` — Leader key setup, autosave autocmd, bootstrap of `core.keymaps.apply.apply_global()`
  - `open.lua` — Cross-platform external-open helper wrapping `vim.ui.open()`
  - `health.lua` — Reusable tool/plugin probe infrastructure and snapshot function; delegates `check()` to `config.health`
  - `keymaps/*.lua` — Five-file keymap subsystem (see Key Abstractions)
- **Depends on**: Built-in `vim` API only
- **Used by**: All editing sessions

### Layer: Plugin Declarations
- **Purpose**: Register plugins, configure lazy-load triggers, define per-plugin options and behavior
- **Location**: `.config/nvim/lua/plugins/`
- **Contains**: 12 files, one per plugin or plugin group (lsp, snacks, blink-cmp, treesitter, conform, git, lualine, bufferline, ufo, colortheme, misc, project, vim-indent-object)
- **Depends on**: `lazy.nvim` for discovery/loading; plugin APIs at runtime
- **Used by**: `require("lazy").setup("plugins")` in `init.lua`

### Layer: Config Modules
- **Purpose**: Health reporting and diagnostic infrastructure
- **Location**: `.config/nvim/lua/config/`
- **Files**:
  - `health.lua` — Full `:checkhealth config` provider with 6 sections: version, required tools, optional tools, plugin load, config guards, known environment gaps
- **Depends on**: `core.health` probe functions; external tool binaries
- **Used by**: `:checkhealth config` command

### Layer: External Scripts
- **Purpose**: Headless validation, health snapshot, and diagnostic tooling
- **Location**: `scripts/`
- **Files**:
  - `nvim-validate.sh` — Orchestrates startup/sync/smoke/health/checkhealth/keymaps/formats subcommands
  - `nvim-audit-failures.sh` — Failure audit and reporting
  - `clone_repo.sh` — Repository clone helper
- **Depends on**: Neovim headless mode, lazy.nvim, Mason, external tools
- **Used by**: CI or maintainer running `./scripts/nvim-validate.sh all`

### Layer: Desktop Environment Configs
- **Purpose**: Window manager, panel, bar, notification system configuration
- **Location**: `.config/hypr/`, `.config/quickshell/`, `.config/waybar/`, `.config/swaync/`, `.config/rofi/`, `.config/kitty/`, `.config/alacritty/`, `.config/wezterm/`, `.config/yazi/`, `.config/btop/`
- **Depends on**: Hyprland compositor, Quickshell, Waybar, system binaries
- **Used by**: Desktop environment sessions (independent of Neovim)

## Data Flow

### Startup Flow

1. Neovim reads `init.lua` (`.config/nvim/init.lua`)
2. `core.options` runs — sets all `vim.o`, `vim.bo`, `vim.wo` defaults
3. `core.keymaps` runs — sets leader key, creates autosave autocmd, calls `require("core.keymaps.apply").apply_global()` to register global-scope mappings
4. Treesitter nil-node guard patched into `vim.treesitter.get_node_text` (line 6-10)
5. lazy.nvim bootstrapped — cloned from GitHub if absent; prepended to `runtimepath`
6. `require("lazy").setup("plugins")` — lazy.nvim scans `lua/plugins/*.lua`, sets up lazy-load triggers, applies `keys` specs compiled from registry

### Keymap Dispatch Flow

1. **Global scope** — Applied immediately via `core.keymaps.apply.apply_global()` (called from `keymaps.lua` line 42). Iterates `registry.lua` entries with `scope = "global"`.
2. **Lazy scope** — Compiled into lazy.nvim `keys` specs by `core.keymaps.lazy` (`get_all_keys()`, `get_keys(domain)`). Plugins like `snacks.lua` call `require("core.keymaps.lazy").get_all_keys()` in their `keys` field. lazy.nvim registers them as key-triggered lazy loaders.
3. **Buffer scope** — Applied on `LspAttach` autocmd via `core.keymaps.attach.setup_lsp_attach()`. The `lsp.lua` plugin also calls `attach.apply_lsp(event.buf)` inside the LspAttach callback.
4. **Plugin-local scope** — Applied by plugins themselves (e.g., csvview keymaps baked into `misc.lua` spec).

### Plugin Load Flow

1. lazy.nvim discovers `lua/plugins/*.lua`
2. Each file returns a plugin spec table (single plugin or list of plugins for grouping)
3. lazy.nvim handles lazy-load based on `event`, `keys`, `cmd`, `ft` triggers
4. `config` function runs when plugin loads; may call registry subsystems (e.g., `whichkey.setup()` in `misc.lua`)
5. `opts` table applied automatically if plugin defines an `opts` function

### Health Check Flow

1. `:checkhealth config` invokes `lua/config/health.lua`'s `M.check()`
2. Loads `core.health` for probe infrastructure (`probe_tool`, `probe_plugin`, `TOOL_METADATA`)
3. Runs 6 sections: version check, required tools, optional tools, plugin load status, config guards, known environment gaps
4. Each section wrapped in `pcall` to prevent one crash aborting the entire check

### LSP Data Flow

1. `lsp.lua` plugin configures diagnostics, Mason install lists, and server configs
2. For each server in `lsp_servers` table, calls `vim.lsp.config(server_name, opts)` then `vim.lsp.enable(vim.tbl_keys(lsp_servers))`
3. Mason-tool-installer ensures packages are installed
4. `LspAttach` autocmd applies buffer-local keymaps, document highlight, and guards

## Key Abstractions

### Plugin Spec Table
- **Purpose**: Declare a lazy.nvim plugin with its dependencies, lazy-load triggers, and configuration
- **Examples**: Every file in `lua/plugins/` returns one
- **Pattern**: `return { "plugin/name", dependencies = {...}, opts = {...}, config = function() ... end }`
- **Consumes**: `require("core.keymaps.lazy").domain_keys()` functions for `keys` field

### Keymap Registry (lua/core/keymaps/registry.lua)
- **Purpose**: Central source of truth for all custom keymaps with explicit metadata fields
- **Structure**: 4 scope tables (`M.global`, `M.lazy`, `M.buffer`, `M.plugin_local`), each containing entries with `id`, `lhs`, `mode`, `desc`, `domain`, `scope`, `plugin`, `action`, `opts`
- **Domain taxonomy**: `f`=search, `c`=code/LSP, `g`=git, `e`=explorer, `b`=buffers, `w`=windows, `t`=toggles, `s`=save
- **Query functions**: `get_by_scope()`, `get_by_domain()`, `get_by_id()`
- **Used by**: `apply.lua`, `lazy.lua`, `attach.lua`, `whichkey.lua`

### Keymap Dispatchers
- **`apply.lua`** — Applies global-scope mappings via `vim.keymap.set()`
- **`lazy.lua`** — Compiles lazy-scope entries into lazy.nvim `keys` spec format with action dispatch logic (module-method, function, string, feedkeys)
- **`attach.lua`** — Applies buffer-scope mappings on `LspAttach`; provides `setup_lsp_attach()` for autocmd registration
- **`whichkey.lua`** — Registers domain groups and individual mapping hints with which-key

### Health Probe Infrastructure (lua/core/health.lua)
- **Purpose**: Reusable tool and plugin probing functions used by `config.health`
- **Exports**: `probe_tool(name)` checks executable availability; `probe_plugin(name)` pcall-requires module
- **TOOL_METADATA**: Declares required vs optional tools with affected_features and install_hints
- **snapshot()**: Produces machine-readable JSON health state

### Autosave Guard
- **Purpose**: Safe FocusLost-based autosave that never writes to special buffers
- **Location**: `lua/core/keymaps.lua` lines 22-35
- **Guards**: `buftype == ""`, `modifiable`, `modified`, non-empty bufname, `filereadable`

## Entry Points

### init.lua
- **Location**: `.config/nvim/init.lua` (26 lines)
- **Triggers**: Neovim startup
- **Responsibilities**: Load core modules, bootstrap lazy.nvim, register plugin tree, patch treesitter nil-node bug

### core/keymaps.lua
- **Location**: `.config/nvim/lua/core/keymaps.lua` (42 lines)
- **Triggers**: Startup (required by init.lua)
- **Responsibilities**: Set leader key, register FocusLost autosave autocmd, bootstrap global keymap application

### plugins/lsp.lua
- **Location**: `.config/nvim/lua/plugins/lsp.lua` (194 lines)
- **Triggers**: Plugin load (the largest single plugin config)
- **Responsibilities**: Configure diagnostics signs/text, declare LSP server list, set up Mason installs, call `vim.lsp.config/enable`, register `LspAttach` autocmd with document highlight and buffer keymaps

### plugins/snacks.lua
- **Location**: `.config/nvim/lua/plugins/snacks.lua` (62 lines)
- **Triggers**: Eager-load (lazy=false, priority=1000)
- **Responsibilities**: Wire all lazy keymaps from registry via `keys = function()`, configure notifier/dashboard/picker/indent/scroll/words/explorer/quickfile submodules

### config/health.lua
- **Location**: `.config/nvim/lua/config/health.lua` (239 lines)
- **Triggers**: `:checkhealth config`
- **Responsibilities**: Run 6-section health report; each section pcall-wrapped for resilience

---

*Architecture analysis: 2026-05-21*
