<!--toc:start-->
- [Project](#project)
  - [Constraints](#constraints)
- [Technology Stack](#technology-stack)
- [Languages](#languages)
- [Runtime](#runtime)
- [Frameworks](#frameworks)
- [Key Dependencies](#key-dependencies)
- [Configuration](#configuration)
- [Platform Requirements](#platform-requirements)
- [Conventions](#conventions)
- [Naming Patterns](#naming-patterns)
- [Code Style](#code-style)
- [Import Organization](#import-organization)
- [Error Handling](#error-handling)
- [Logging](#logging)
- [Comments](#comments)
- [Function Design](#function-design)
- [Module Design](#module-design)
- [Architecture](#architecture)
- [Pattern Overview](#pattern-overview)
- [Layers](#layers)
- [Data Flow](#data-flow)
- [Key Abstractions](#key-abstractions)
- [Entry Points](#entry-points)
- [Error Handling](#error-handling-1)
- [Cross-Cutting Concerns](#cross-cutting-concerns)
- [Project Skills](#project-skills)
- [GSD Workflow Enforcement](#gsd-workflow-enforcement)
- [Developer Profile](#developer-profile)
<!--toc:end-->

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Cross-Platform Neovim Dotfiles**

This project is a shared Neovim configuration inside a `.dotfiles` repo that should run reliably across Arch Linux, Debian/Ubuntu, and Windows with OS-specific guards inside one codebase. It already provides a modular `lazy.nvim`-based setup with LSP, completion, search, file tree, git, formatting, and UI plugins, but it now needs to be cleaned up, modernized, and made predictable.

The next evolution is not "add random features." It is to turn the current config into a clean, up-to-date, best-practice Neovim setup with organized keymaps, fewer bugs, better plugin choices, and safer cross-platform behavior.

**Core Value:** One shared Neovim config should give a clean, modern, bug-resistant editing experience across Linux and Windows without the setup fighting the user.

### Constraints

- **Platform**: One shared config repo across Arch Linux, Debian/Ubuntu, and Windows — avoid forked configs because maintenance cost grows fast
- **Architecture**: OS-specific behavior must be guarded inside config code — portability is a first-class requirement
- **Quality**: Aggressive cleanup is allowed, including plugin replacement — current choices are not sacred
- **Usability**: Keymaps must become centrally managed — maintainability matters as much as feature count
- **Reliability**: Bug fixes and regression prevention are required, not optional polish — current failure modes break core editing flow
- **Workflow**: This lives in a `.dotfiles` repo and may need external install/update scripts on target machines — rollout must respect that reality
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Lua - All Neovim configuration under `.config/nvim/init.lua` and `.config/nvim/lua/**`
- Markdown - Lightweight docs in `.config/nvim/README.md`
- JSON - Plugin lockfile in `.config/nvim/lazy-lock.json`
## Runtime
- Neovim 0.10+ baseline, with explicit compatibility shim for 0.10 vs 0.11 in `.config/nvim/lua/plugins/lsp.lua`
- User shell and system tools available to Neovim commands, including `git`, `rg`, `xdg-open`, and formatter/LSP binaries installed through Mason
- `lazy.nvim` plugin manager bootstrapped in `.config/nvim/init.lua`
- Lockfile: `.config/nvim/lazy-lock.json` present
## Frameworks
- Neovim Lua config - Entire editor config is plain Lua modules loaded via `require(...)`
- `folke/lazy.nvim` - Discovers plugin specs from `.config/nvim/lua/plugins/*.lua`
- None found in `.config/nvim`
- `mason.nvim`, `mason-lspconfig.nvim`, `mason-tool-installer.nvim` in `.config/nvim/lua/plugins/lsp.lua` - LSP/tool provisioning
- `stevearc/conform.nvim` in `.config/nvim/lua/plugins/conform.lua` - Formatter dispatch
- `nvim-treesitter` in `.config/nvim/lua/plugins/treesitter.lua` - Parser installs via `:TSUpdate`
## Key Dependencies
- `neovim/nvim-lspconfig` - LSP client setup and per-server registration in `.config/nvim/lua/plugins/lsp.lua`
- `saghen/blink.cmp` - Completion engine and LSP capability extension in `.config/nvim/lua/plugins/blink-cmp.lua`
- `ibhagwan/fzf-lua` - Search/navigation frontend used directly by many keymaps in `.config/nvim/lua/plugins/fzflua.lua`
- `nvim-neo-tree/neo-tree.nvim` - File explorer with file actions and preview hooks in `.config/nvim/lua/plugins/neotree.lua`
- `catppuccin/nvim` - Primary colorscheme in `.config/nvim/lua/plugins/colortheme.lua`
- `kevinhwang91/nvim-ufo` - Folding UX and custom virtual text in `.config/nvim/lua/plugins/ufo.lua`
- `lewis6991/gitsigns.nvim` and `tpope/vim-fugitive` - Git indicators and commands in `.config/nvim/lua/plugins/git.lua`
- `stevearc/conform.nvim` - Save-time/manual formatting from `.config/nvim/lua/core/keymaps.lua`
- `nvim-treesitter/nvim-treesitter` - Syntax parsing and incremental selection in `.config/nvim/lua/plugins/treesitter.lua`
- `folke/noice.nvim` and `rcarriga/nvim-notify` - UI messaging used by lualine in `.config/nvim/lua/plugins/notify.lua` and `.config/nvim/lua/plugins/lualine.lua`
## Configuration
- No project-local `.env` or external secret file found in `.config/nvim`
- Plugin versions pinned in `.config/nvim/lazy-lock.json`
- Editor options and keymaps configured centrally in `.config/nvim/lua/core/options.lua` and `.config/nvim/lua/core/keymaps.lua`
- Bootstrap path logic in `.config/nvim/init.lua`
- Per-plugin config split across `.config/nvim/lua/plugins/*.lua`
- Tool install list centralized in `.config/nvim/lua/plugins/lsp.lua`
## Platform Requirements
- Linux desktop strongly implied by `xdg-open` calls in `.config/nvim/lua/core/keymaps.lua` and `.config/nvim/lua/plugins/neotree.lua`
- Nerd Font support expected for icons in alpha, diagnostics, folds, bufferline, and neo-tree
- Mason-managed or system-installed binaries needed for configured servers/formatters: `bashls`, `clangd`, `gopls`, `lua_ls`, `prettier`, `black`, `stylua`, `latexindent`, etc.
- Not an app deployment target; this is end-user workstation config under `.config/nvim`
- Runtime success depends on local Neovim installation plus plugin/tool availability
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- One Lua module per plugin/domain in `.config/nvim/lua/plugins/`
- Core modules use lowercase nouns: `.config/nvim/lua/core/options.lua`, `.config/nvim/lua/core/keymaps.lua`
- No tests found, so no test-file naming pattern established
- `camelCase` for locals and callbacks: `client_supports_method`, `open_in_browser`
- Anonymous inline functions used heavily for plugin config and keymaps
- Handler-style names appear for event callbacks in plugin config
- `snake_case` and `camelCase` both appear in Lua locals depending on upstream plugin examples
- Uppercase globals rare; notable Neovim globals use `vim.g.*`
- Descriptive local names preferred over terse abbreviations in most files
- No custom Lua type modules; occasional EmmyLua annotations inline, e.g. in `.config/nvim/lua/plugins/blink-cmp.lua` and `misc.lua`
## Code Style
- Tabs used for indentation in committed Lua files
- Strings mostly use double quotes
- Trailing commas common in multiline tables
- Comments are frequent, often explanatory and sectioned with long separator banners
- No lint config found
- Formatting enforcement appears to rely on `stylua` via `conform.nvim`
## Import Organization
- Minimal formal grouping; modules are small enough that imports stay local
- Deferred `require(...)` inside callbacks common when plugin should load lazily
- None; standard Lua module paths only, e.g. `require("core.options")`, `require("fzf-lua")`
## Error Handling
- Startup-critical failure throws immediately, e.g. lazy bootstrap clone error in `.config/nvim/init.lua`
- Runtime editor actions often suppress noisy failures with `silent!`
- Capability checks used before optional LSP features are enabled in `.config/nvim/lua/plugins/lsp.lua`
- Plain `error(...)` and plugin/builtin command failures
- No custom error abstraction layer
## Logging
- No dedicated logger
- User feedback delegated to Neovim UI and plugins like `noice.nvim` / `nvim-notify`
- Very little explicit logging in repo code
- Config favors UI state changes and editor commands over printed diagnostics
## Comments
- Frequent comments explain plugin options, Neovim behavior, and intent
- Large banner comments divide files into topical sections, especially `.config/nvim/lua/core/keymaps.lua`
- Upstream-style educational comments preserved in `.config/nvim/lua/plugins/lsp.lua` and `treesitter.lua`
- Lua annotation comments used sparingly for plugin-specific typing hints
- No active TODO convention found in `.config/nvim`
## Function Design
- Small direct config tables common
- A few larger config functions exist for complex plugins like `.config/nvim/lua/plugins/neotree.lua` and `lsp.lua`
- Callback params usually mirror Neovim/plugin APIs (`event`, `args`, `bufnr`, `filetype`, `buftype`)
- Helper functions stay local to enclosing config blocks
- Plugin modules return a table
- Helper callbacks usually act through side effects on `vim`
## Module Design
- Default export style: one returned Lua table per module
- `misc.lua` and `git.lua` intentionally return arrays of plugin specs
- None; `lazy.nvim` scans directory directly
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- Single entry point in `.config/nvim/init.lua`
- Core/editor defaults separated from plugin declarations
- One file per plugin domain under `.config/nvim/lua/plugins/`
- Heavy use of Neovim callbacks, autocommands, and plugin `config`/`opts` tables
## Layers
- Purpose: Start plugin manager, set runtime path, load core modules
- Contains: `.config/nvim/init.lua`
- Depends on: built-in `vim` API and local module files
- Used by: Neovim startup
- Purpose: Define editor-wide defaults independent of any single plugin
- Contains: `.config/nvim/lua/core/options.lua`, `.config/nvim/lua/core/keymaps.lua`
- Depends on: built-in `vim` API, plus `conform.nvim` and `gitsigns.nvim` for some keymaps
- Used by: all editing sessions
- Purpose: Register plugins, lazy-load triggers, dependencies, and plugin-local behavior
- Contains: `.config/nvim/lua/plugins/*.lua`
- Depends on: `lazy.nvim` discovery and plugin APIs
- Used by: `require("lazy").setup("plugins")`
- Purpose: Language support, formatting, search, git, tree navigation, UI polish
- Contains: `.config/nvim/lua/plugins/lsp.lua`, `conform.lua`, `treesitter.lua`, `fzflua.lua`, `git.lua`, `neotree.lua`, `notify.lua`
- Depends on: external binaries, parser downloads, plugin ecosystem
- Used by: interactive editor workflows
## Data Flow
- Stateless config code; persistent state lives in Neovim runtime dirs, plugin lockfile, and local installed tools
- Repo itself stores config only, not editor session state
## Key Abstractions
- Purpose: Define one plugin or small plugin group
- Examples: `.config/nvim/lua/plugins/blink-cmp.lua`, `.config/nvim/lua/plugins/git.lua`, `.config/nvim/lua/plugins/misc.lua`
- Pattern: return Lua table consumed by `lazy.nvim`
- Purpose: React to editor lifecycle events
- Examples: autosave logic in `.config/nvim/lua/core/keymaps.lua`, `LspAttach` in `.config/nvim/lua/plugins/lsp.lua`, CSV filetype hook in `.config/nvim/lua/plugins/misc.lua`
- Pattern: `vim.api.nvim_create_autocmd(...)`
- Purpose: Translate local key/action into plugin call
- Examples: `require("fzf-lua").files()`, `require("conform").format()`, `require("ufo").openAllFolds()`
- Pattern: anonymous functions bound in keymaps or plugin commands
## Entry Points
- Location: `.config/nvim/init.lua`
- Triggers: Neovim startup
- Responsibilities: load core modules, bootstrap lazy, register plugin tree
- Location: `.config/nvim/lua/core/keymaps.lua`
- Triggers: keypresses and common editor events
- Responsibilities: smart quit, save/format, autosave, movement, git actions
- Location: `.config/nvim/lua/plugins/lsp.lua`
- Triggers: plugin load and `LspAttach`
- Responsibilities: diagnostics config, Mason installs, LSP setup, buffer-local LSP maps
## Error Handling
- Hard fail on `lazy.nvim` clone failure via `error(...)` in `.config/nvim/init.lua`
- Most plugin configs assume dependencies exist once lazy loads them
- Some defensive checks exist, e.g. `client_supports_method(...)` in `.config/nvim/lua/plugins/lsp.lua`
- Save/autosave paths often use `silent!` to suppress write noise in `.config/nvim/lua/core/keymaps.lua`
## Cross-Cutting Concerns
- `folke/noice.nvim` and `rcarriga/nvim-notify` shape command/message UI
- Minimal local validation; correctness mostly delegated to plugin APIs and Neovim runtime
- Manual and save-triggered formatting centralized around `conform.nvim`
- `fzf-lua`, `neo-tree`, bufferline, lualine, and tmux navigation plugins provide most interaction surface
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
