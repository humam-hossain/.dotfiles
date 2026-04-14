# Coding Conventions

**Analysis Date:** 2026-04-14

## Naming Patterns

**Files:**
- One Lua module per plugin/domain in `.config/nvim/lua/plugins/`
- Core modules use lowercase nouns: `.config/nvim/lua/core/options.lua`, `.config/nvim/lua/core/keymaps.lua`
- No tests found, so no test-file naming pattern established

**Functions:**
- `camelCase` for locals and callbacks: `client_supports_method`, `open_in_browser`
- Anonymous inline functions used heavily for plugin config and keymaps
- Handler-style names appear for event callbacks in plugin config

**Variables:**
- `snake_case` and `camelCase` both appear in Lua locals depending on upstream plugin examples
- Uppercase globals rare; notable Neovim globals use `vim.g.*`
- Descriptive local names preferred over terse abbreviations in most files

**Types:**
- No custom Lua type modules; occasional EmmyLua annotations inline, e.g. in `.config/nvim/lua/plugins/blink-cmp.lua` and `misc.lua`

## Code Style

**Formatting:**
- Tabs used for indentation in committed Lua files
- Strings mostly use double quotes
- Trailing commas common in multiline tables
- Comments are frequent, often explanatory and sectioned with long separator banners

**Linting:**
- No lint config found
- Formatting enforcement appears to rely on `stylua` via `conform.nvim`

## Import Organization

**Order:**
1. Built-in/global `vim` setup or local constants
2. `require(...)` calls near top of module or inside `config` fns
3. Inline plugin API calls inside mappings/callbacks

**Grouping:**
- Minimal formal grouping; modules are small enough that imports stay local
- Deferred `require(...)` inside callbacks common when plugin should load lazily

**Path Aliases:**
- None; standard Lua module paths only, e.g. `require("core.options")`, `require("fzf-lua")`

## Error Handling

**Patterns:**
- Startup-critical failure throws immediately, e.g. lazy bootstrap clone error in `.config/nvim/init.lua`
- Runtime editor actions often suppress noisy failures with `silent!`
- Capability checks used before optional LSP features are enabled in `.config/nvim/lua/plugins/lsp.lua`

**Error Types:**
- Plain `error(...)` and plugin/builtin command failures
- No custom error abstraction layer

## Logging

**Framework:**
- No dedicated logger
- User feedback delegated to Neovim UI and plugins like `noice.nvim` / `nvim-notify`

**Patterns:**
- Very little explicit logging in repo code
- Config favors UI state changes and editor commands over printed diagnostics

## Comments

**When to Comment:**
- Frequent comments explain plugin options, Neovim behavior, and intent
- Large banner comments divide files into topical sections, especially `.config/nvim/lua/core/keymaps.lua`
- Upstream-style educational comments preserved in `.config/nvim/lua/plugins/lsp.lua` and `treesitter.lua`

**JSDoc/TSDoc:**
- Lua annotation comments used sparingly for plugin-specific typing hints

**TODO Comments:**
- No active TODO convention found in `.config/nvim`

## Function Design

**Size:**
- Small direct config tables common
- A few larger config functions exist for complex plugins like `.config/nvim/lua/plugins/neotree.lua` and `lsp.lua`

**Parameters:**
- Callback params usually mirror Neovim/plugin APIs (`event`, `args`, `bufnr`, `filetype`, `buftype`)
- Helper functions stay local to enclosing config blocks

**Return Values:**
- Plugin modules return a table
- Helper callbacks usually act through side effects on `vim`

## Module Design

**Exports:**
- Default export style: one returned Lua table per module
- `misc.lua` and `git.lua` intentionally return arrays of plugin specs

**Barrel Files:**
- None; `lazy.nvim` scans directory directly

---

*Convention analysis: 2026-04-14*
*Update when patterns change*
