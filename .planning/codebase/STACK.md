# Technology Stack

**Analysis Date:** 2026-04-14

## Languages

**Primary:**
- Lua - All Neovim configuration under `.config/nvim/init.lua` and `.config/nvim/lua/**`

**Secondary:**
- Markdown - Lightweight docs in `.config/nvim/README.md`
- JSON - Plugin lockfile in `.config/nvim/lazy-lock.json`

## Runtime

**Environment:**
- Neovim 0.10+ baseline, with explicit compatibility shim for 0.10 vs 0.11 in `.config/nvim/lua/plugins/lsp.lua`
- User shell and system tools available to Neovim commands, including `git`, `rg`, `xdg-open`, and formatter/LSP binaries installed through Mason

**Package Manager:**
- `lazy.nvim` plugin manager bootstrapped in `.config/nvim/init.lua`
- Lockfile: `.config/nvim/lazy-lock.json` present

## Frameworks

**Core:**
- Neovim Lua config - Entire editor config is plain Lua modules loaded via `require(...)`
- `folke/lazy.nvim` - Discovers plugin specs from `.config/nvim/lua/plugins/*.lua`

**Testing:**
- None found in `.config/nvim`

**Build/Dev:**
- `mason.nvim`, `mason-lspconfig.nvim`, `mason-tool-installer.nvim` in `.config/nvim/lua/plugins/lsp.lua` - LSP/tool provisioning
- `stevearc/conform.nvim` in `.config/nvim/lua/plugins/conform.lua` - Formatter dispatch
- `nvim-treesitter` in `.config/nvim/lua/plugins/treesitter.lua` - Parser installs via `:TSUpdate`

## Key Dependencies

**Critical:**
- `neovim/nvim-lspconfig` - LSP client setup and per-server registration in `.config/nvim/lua/plugins/lsp.lua`
- `saghen/blink.cmp` - Completion engine and LSP capability extension in `.config/nvim/lua/plugins/blink-cmp.lua`
- `ibhagwan/fzf-lua` - Search/navigation frontend used directly by many keymaps in `.config/nvim/lua/plugins/fzflua.lua`
- `nvim-neo-tree/neo-tree.nvim` - File explorer with file actions and preview hooks in `.config/nvim/lua/plugins/neotree.lua`
- `catppuccin/nvim` - Primary colorscheme in `.config/nvim/lua/plugins/colortheme.lua`
- `kevinhwang91/nvim-ufo` - Folding UX and custom virtual text in `.config/nvim/lua/plugins/ufo.lua`

**Infrastructure:**
- `lewis6991/gitsigns.nvim` and `tpope/vim-fugitive` - Git indicators and commands in `.config/nvim/lua/plugins/git.lua`
- `stevearc/conform.nvim` - Save-time/manual formatting from `.config/nvim/lua/core/keymaps.lua`
- `nvim-treesitter/nvim-treesitter` - Syntax parsing and incremental selection in `.config/nvim/lua/plugins/treesitter.lua`
- `folke/noice.nvim` and `rcarriga/nvim-notify` - UI messaging used by lualine in `.config/nvim/lua/plugins/notify.lua` and `.config/nvim/lua/plugins/lualine.lua`

## Configuration

**Environment:**
- No project-local `.env` or external secret file found in `.config/nvim`
- Plugin versions pinned in `.config/nvim/lazy-lock.json`
- Editor options and keymaps configured centrally in `.config/nvim/lua/core/options.lua` and `.config/nvim/lua/core/keymaps.lua`

**Build:**
- Bootstrap path logic in `.config/nvim/init.lua`
- Per-plugin config split across `.config/nvim/lua/plugins/*.lua`
- Tool install list centralized in `.config/nvim/lua/plugins/lsp.lua`

## Platform Requirements

**Development:**
- Linux desktop strongly implied by `xdg-open` calls in `.config/nvim/lua/core/keymaps.lua` and `.config/nvim/lua/plugins/neotree.lua`
- Nerd Font support expected for icons in alpha, diagnostics, folds, bufferline, and neo-tree
- Mason-managed or system-installed binaries needed for configured servers/formatters: `bashls`, `clangd`, `gopls`, `lua_ls`, `prettier`, `black`, `stylua`, `latexindent`, etc.

**Production:**
- Not an app deployment target; this is end-user workstation config under `.config/nvim`
- Runtime success depends on local Neovim installation plus plugin/tool availability

---

*Stack analysis: 2026-04-14*
*Update after major dependency changes*
