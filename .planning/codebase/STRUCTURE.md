# Codebase Structure

**Analysis Date:** 2026-05-21

## Directory Layout

```
.dotfiles/
├── .config/
│   ├── nvim/                   # Neovim editor configuration (primary focus)
│   │   ├── init.lua            # Entry point
│   │   ├── .luarc.json         # Lua language server settings
│   │   ├── README.md           # Detailed config documentation
│   │   ├── lazy-lock.json      # Plugin version lockfile
│   │   ├── lua/
│   │   │   ├── core/           # Core editor infrastructure
│   │   │   │   ├── options.lua
│   │   │   │   ├── keymaps.lua
│   │   │   │   ├── open.lua
│   │   │   │   ├── health.lua
│   │   │   │   └── keymaps/    # Keymap subsystem (5 files)
│   │   │   ├── plugins/        # Plugin declarations (13 files)
│   │   │   └── config/         # Health reporting (1 file)
│   │   │       └── health.lua
│   │   └── README.md
│   ├── hypr/                   # Hyprland compositor (4 files)
│   ├── quickshell/             # Quickshell panel/bar (36 files)
│   ├── waybar/                 # Waybar status bar (9 files)
│   ├── kitty/                  # Kitty terminal
│   ├── alacritty/              # Alacritty terminal
│   ├── wezterm/                # WezTerm terminal
│   ├── rofi/                   # Rofi launcher
│   ├── swaync/                 # Sway notification center
│   ├── yazi/                   # Yazi file manager
│   ├── btop/                   # Btop system monitor
│   ├── fish/                   # Fish shell config
│   ├── tmux.conf               # Tmux config
│   ├── starship.toml           # Starship prompt
│   └── .zshrc                  # Zsh config
├── scripts/                    # Validation/automation scripts (3 files)
├── arch/                       # Arch Linux install scripts
├── debian/                     # Debian install scripts
├── ubuntu/                     # Ubuntu install scripts
├── .planning/                  # GSD project management artifacts
│   └── codebase/               # This analysis output
├── AGENTS.md                   # Agent instructions
└── README.md                   # Repo README
```

## File Inventory

### Core Neovim Config (6 files, 239 lines total)

| File | Lines | Purpose |
|------|-------|---------|
| `.config/nvim/init.lua` | 26 | Entry point: loads core modules, bootstraps lazy.nvim, patches treesitter, discovers plugins |
| `.config/nvim/.luarc.json` | 4 | Lua LSP settings (LuaJIT runtime, vim globals) |
| `.config/nvim/lazy-lock.json` | 38 | Pinned plugin versions managed by `:Lazy lock` |

### Core Modules (5 files, 340 lines total)

| File | Lines | Purpose |
|------|-------|---------|
| `lua/core/options.lua` | 51 | All editor defaults: line numbers, tabs, search, clipboard, UI, undo, splits |
| `lua/core/keymaps.lua` | 42 | Leader key, autosave autocmd (FocusLost), global keymap bootstrap |
| `lua/core/open.lua` | 47 | Cross-platform `vim.ui.open()` wrapper for external file opening |
| `lua/core/health.lua` | 147 | Tool/plugin probe infrastructure, TOOL_METADATA, snapshot(), check() delegator |

### Keymap Subsystem (5 files, 1193 lines total)

| File | Lines | Purpose |
|------|-------|---------|
| `lua/core/keymaps/registry.lua` | 887 | Declarative keymap registry: 4 scopes (global/lazy/buffer/plugin-local), 8 domains, query functions |
| `lua/core/keymaps/apply.lua` | 53 | Applies global-scope mappings at startup |
| `lua/core/keymaps/lazy.lua` | 143 | Compiles lazy-scope entries into lazy.nvim `keys` spec format with domain-specific helpers |
| `lua/core/keymaps/attach.lua` | 91 | Applies buffer-scope mappings on LspAttach event; provides setup_lsp_attach() |
| `lua/core/keymaps/whichkey.lua` | 73 | Registers domain groups and individual mapping hints with which-key |

### Plugin Configs (13 files, 848 lines total)

| File | Lines | Dependencies | Purpose |
|------|-------|-------------|---------|
| `lua/plugins/lsp.lua` | 194 | nvim-lspconfig, mason.nvim, mason-lspconfig, mason-tool-installer, fidget.nvim, blink.cmp | LSP client, diagnostics, Mason provisioning, LspAttach handlers |
| `lua/plugins/snacks.lua` | 62 | folke/snacks.nvim | UI hub: picker (replaces fzf-lua), notifier, dashboard, indent, scroll, words, lazygit, explorer |
| `lua/plugins/blink-cmp.lua` | 98 | saghen/blink.cmp, friendly-snippets, blink-emoji | Completion engine with LSP/path/snippet/buffer/emoji sources |
| `lua/plugins/treesitter.lua` | 65 | nvim-treesitter | Syntax parsing, incremental selection, auto-install parsers |
| `lua/plugins/conform.lua` | 68 | stevearc/conform.nvim | Format-on-save with filetype exclusions (gitcommit, markdown, etc.) |
| `lua/plugins/misc.lua` | 88 | which-key, nvim-autopairs, todo-comments, render-markdown, comfy-line-numbers, csvview, vim-tmux-navigator, vim-sleuth, vim-rhubarb | Misc plugins grouped in one file |
| `lua/plugins/git.lua` | 47 | vim-fugitive, gitsigns.nvim | Git integration: signs, blame, commands |
| `lua/plugins/lualine.lua` | 53 | lualine.nvim, vim-tpipeline, web-devicons | Statusline with tmux integration |
| `lua/plugins/bufferline.lua` | 63 | bufferline.nvim, vim-bbye, web-devicons | Buffer tab bar at top |
| `lua/plugins/ufo.lua` | 81 | nvim-ufo, promise-async | Folding with custom virtual text handler |
| `lua/plugins/colortheme.lua` | 26 | catppuccin/nvim | Catppuccin Mocha colorscheme with integrations |
| `lua/plugins/project.lua` | 12 | project.nvim | Project root detection (pattern-only to avoid deprecated LSP calls) |
| `lua/plugins/vim-indent-object.lua` | 8 | vim-indent-object | Indent-based text objects (`ii`, `ai`) |

### Config Layer (1 file, 239 lines total)

| File | Lines | Purpose |
|------|-------|---------|
| `lua/config/health.lua` | 239 | `:checkhealth config` provider with 6 pcall-wrapped sections |

### Validation Scripts (3 files)

| File | Purpose |
|------|---------|
| `scripts/nvim-validate.sh` | Headless validation harness: startup, sync, smoke, health, checkhealth, keymaps, formats |
| `scripts/nvim-audit-failures.sh` | Failure audit reporting from validation artifacts |
| `scripts/clone_repo.sh` | Repository clone helper |

### Desktop Environment Configs

| Directory | Files | Purpose |
|-----------|-------|---------|
| `.config/hypr/` | 4 (hyprland.conf, hypridle.conf, hyprpaper.conf, hyprlock.conf) | Hyprland compositor, idle, wallpaper, lock screen |
| `.config/quickshell/` | 36 (Bar.qml, BarContent.qml, BarGroup.qml, shell.qml + services/ + widgets/ + theme/) | Desktop bar panel in QML with CPU, memory, disk, network, weather, clock, audio, notification, MPRIS services |
| `.config/waybar/` | 9 (config.jsonc, style.css, mocha.css + scripts/) | Waybar status bar (fallback/companion) |
| `.config/swaync/` | - | Sway notification center |
| `.config/rofi/` | - | Application launcher |
| `.config/kitty/` | - | Kitty terminal config |
| `.config/alacritty/` | - | Alacritty terminal config |
| `.config/wezterm/` | - | WezTerm terminal config |
| `.config/yazi/` | - | Yazi file manager config |
| `.config/btop/` | - | Btop system monitor config |
| `.config/starship.toml` | - | Cross-shell prompt |
| `.config/tmux.conf` | - | Tmux configuration |

## Module Map

### require() Dependency Graph (Neovim config only)

```
init.lua
├── core.options                     # vim.o/vim.wo defaults
├── core.keymaps                     # Leader, autosave, bootstrap
│   └── core.keymaps.apply           # apply_global() (eager startup)
│       └── core.keymaps.registry    # gets global-scope entries
└── lazy setup("plugins")
    └── lua/plugins/*.lua (13 files)
        ├── snacks.lua
        │   └── core.keymaps.lazy    # get_all_keys() for keys specs
        │       └── core.keymaps.registry
        ├── misc.lua
        │   └── core.keymaps.whichkey  # setup() for which-key groups
        │       └── core.keymaps.registry
        ├── ufo.lua
        │   └── core.keymaps.lazy      # fold_keys() for fold keymaps
        │       └── core.keymaps.registry
        ├── lsp.lua
        │   └── core.keymaps.attach    # apply_lsp(bufnr) in LspAttach
        │       └── core.keymaps.registry
        ├── blink-cmp.lua
        ├── treesitter.lua
        ├── conform.lua
        ├── git.lua
        ├── lualine.lua
        ├── bufferline.lua
        ├── colortheme.lua
        ├── project.lua
        └── vim-indent-object.lua

Plugin-internal cross-references:
- lsp.lua: requires("blink.cmp") for get_lsp_capabilities()
- lualine.lua: depends on gitsigns.nvim at runtime
- bufferline.lua: depends on vim-bbye, web-devicons
- misc.lua: config() calls whichkey.setup() which loads registry

Health chain (called by :checkhealth config):
config.health
└── core.health                  # probe_tool(), probe_plugin(), TOOL_METADATA
```

### Key Architectural Relationships

```
Keymap Registry (registry.lua)
    ├── scope=global  ──▶ apply.lua (eager startup)
    ├── scope=lazy    ──▶ lazy.lua (→ snacks.lua keys field → lazy.nvim)
    ├── scope=buffer  ──▶ attach.lua (→ LspAttach autocmd in lsp.lua)
    └── scope=plugin-local ──▶ attach.lua (csvview, others)
    
    domain groups ──▶ whichkey.lua → which-key plugin
```

## Naming Conventions

**Files:**
- Core module files: lowercase single-word (`options.lua`, `keymaps.lua`, `open.lua`, `health.lua`)
- Plugin files: descriptive kebab-case or short name (`blink-cmp.lua`, `vim-indent-object.lua`, `treesitter.lua`)
- Keymap submodules: role-based (`registry.lua`, `apply.lua`, `lazy.lua`, `attach.lua`)

**Variables:**
- `camelCase` for Lua locals and parameters: `client_supports_method`, `open_in_browser`, `lazyKeys`
- Descriptive names preferred over terse abbreviations

**Tables:**
- Uppercase `M` for module return tables: `local M = {}` / `return M`
- Plugin `opts` tables use snake_case keys matching plugin API conventions

## Where to Add New Code

**New Plugin:**
1. Create `lua/plugins/<plugin-name>.lua` returning a lazy.nvim spec table
2. Add its keymaps to `lua/core/keymaps/registry.lua` if they use existing domains
3. If no domain fits, add a new domain group to `registry.lua`'s `M.groups` table

**New Core Feature:**
- Add to existing core file if closely related (e.g., an option in `options.lua`)
- Create new file in `lua/core/` and `require()` it from `init.lua`

**New Keymap:**
- Single source of truth: add entry to `lua/core/keymaps/registry.lua`
- Choose scope: `global` (eager), `lazy` (plugin-triggered), `buffer` (LSP-attached), `plugin-local` (scoped)
- Assign domain prefix: `f`/`c`/`g`/`e`/`b`/`w`/`t`/`s`
- Plugins that use lazy-scope keys call `require("core.keymaps.lazy").get_keys(domain)` in their `keys` field

**New Health Check:**
- Add probe function to `lua/core/health.lua` if reusable
- Add section function to `lua/config/health.lua` and call it from `M.check()`

**New Validator:**
- Add subcommand to `scripts/nvim-validate.sh`
- Follow existing pattern: run test, check exit code, print PASS/FAIL

---

*Structure analysis: 2026-05-21*
