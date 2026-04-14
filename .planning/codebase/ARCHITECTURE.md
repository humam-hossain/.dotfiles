# Architecture

**Analysis Date:** 2026-04-14

## Pattern Overview

**Overall:** Modular Neovim configuration built as lazy-loaded plugin specs around a thin core

**Key Characteristics:**
- Single entry point in `.config/nvim/init.lua`
- Core/editor defaults separated from plugin declarations
- One file per plugin domain under `.config/nvim/lua/plugins/`
- Heavy use of Neovim callbacks, autocommands, and plugin `config`/`opts` tables

## Layers

**Bootstrap Layer:**
- Purpose: Start plugin manager, set runtime path, load core modules
- Contains: `.config/nvim/init.lua`
- Depends on: built-in `vim` API and local module files
- Used by: Neovim startup

**Core Behavior Layer:**
- Purpose: Define editor-wide defaults independent of any single plugin
- Contains: `.config/nvim/lua/core/options.lua`, `.config/nvim/lua/core/keymaps.lua`
- Depends on: built-in `vim` API, plus `conform.nvim` and `gitsigns.nvim` for some keymaps
- Used by: all editing sessions

**Plugin Spec Layer:**
- Purpose: Register plugins, lazy-load triggers, dependencies, and plugin-local behavior
- Contains: `.config/nvim/lua/plugins/*.lua`
- Depends on: `lazy.nvim` discovery and plugin APIs
- Used by: `require("lazy").setup("plugins")`

**Tooling/Language Layer:**
- Purpose: Language support, formatting, search, git, tree navigation, UI polish
- Contains: `.config/nvim/lua/plugins/lsp.lua`, `conform.lua`, `treesitter.lua`, `fzflua.lua`, `git.lua`, `neotree.lua`, `notify.lua`
- Depends on: external binaries, parser downloads, plugin ecosystem
- Used by: interactive editor workflows

## Data Flow

**Neovim Startup:**

1. Neovim loads `.config/nvim/init.lua`
2. Core settings load via `require("core.options")` and `require("core.keymaps")`
3. `lazy.nvim` bootstrap clones plugin manager if missing
4. `lazy.nvim` scans `.config/nvim/lua/plugins/*.lua`
5. Immediate plugins load now; event/key/cmd-gated plugins load later

**Editing + Tooling Flow:**

1. User opens file/buffer
2. Lazy events load relevant plugins (`BufReadPre`, `InsertEnter`, `VeryLazy`, filetype callbacks)
3. LSP/Treesitter/Mason-backed features attach based on filetype
4. Keymaps in core or plugin config dispatch into plugin APIs
5. Plugins render UI or run external binaries, then update editor state

**State Management:**
- Stateless config code; persistent state lives in Neovim runtime dirs, plugin lockfile, and local installed tools
- Repo itself stores config only, not editor session state

## Key Abstractions

**Plugin Spec Module:**
- Purpose: Define one plugin or small plugin group
- Examples: `.config/nvim/lua/plugins/blink-cmp.lua`, `.config/nvim/lua/plugins/git.lua`, `.config/nvim/lua/plugins/misc.lua`
- Pattern: return Lua table consumed by `lazy.nvim`

**Autocommand Callback:**
- Purpose: React to editor lifecycle events
- Examples: autosave logic in `.config/nvim/lua/core/keymaps.lua`, `LspAttach` in `.config/nvim/lua/plugins/lsp.lua`, CSV filetype hook in `.config/nvim/lua/plugins/misc.lua`
- Pattern: `vim.api.nvim_create_autocmd(...)`

**Plugin Bridge Function:**
- Purpose: Translate local key/action into plugin call
- Examples: `require("fzf-lua").files()`, `require("conform").format()`, `require("ufo").openAllFolds()`
- Pattern: anonymous functions bound in keymaps or plugin commands

## Entry Points

**Startup Entry:**
- Location: `.config/nvim/init.lua`
- Triggers: Neovim startup
- Responsibilities: load core modules, bootstrap lazy, register plugin tree

**Core Editor Hooks:**
- Location: `.config/nvim/lua/core/keymaps.lua`
- Triggers: keypresses and common editor events
- Responsibilities: smart quit, save/format, autosave, movement, git actions

**Language Tooling Entry:**
- Location: `.config/nvim/lua/plugins/lsp.lua`
- Triggers: plugin load and `LspAttach`
- Responsibilities: diagnostics config, Mason installs, LSP setup, buffer-local LSP maps

## Error Handling

**Strategy:** Mostly optimistic config with limited explicit guardrails

**Patterns:**
- Hard fail on `lazy.nvim` clone failure via `error(...)` in `.config/nvim/init.lua`
- Most plugin configs assume dependencies exist once lazy loads them
- Some defensive checks exist, e.g. `client_supports_method(...)` in `.config/nvim/lua/plugins/lsp.lua`
- Save/autosave paths often use `silent!` to suppress write noise in `.config/nvim/lua/core/keymaps.lua`

## Cross-Cutting Concerns

**Logging/UI Feedback:**
- `folke/noice.nvim` and `rcarriga/nvim-notify` shape command/message UI

**Validation:**
- Minimal local validation; correctness mostly delegated to plugin APIs and Neovim runtime

**Formatting:**
- Manual and save-triggered formatting centralized around `conform.nvim`

**Navigation/Search:**
- `fzf-lua`, `neo-tree`, bufferline, lualine, and tmux navigation plugins provide most interaction surface

---

*Architecture analysis: 2026-04-14*
*Update when major patterns change*
