# Codebase Structure

**Analysis Date:** 2026-04-14

## Directory Layout

```text
.config/nvim/
├── init.lua               # Startup bootstrap and lazy.nvim setup
├── lazy-lock.json         # Pinned plugin commits
├── README.md              # Human reference links
└── lua/
    ├── core/              # Global editor options and keymaps
    │   ├── options.lua
    │   └── keymaps.lua
    └── plugins/           # One file per plugin or plugin domain
        ├── alpha.lua
        ├── blink-cmp.lua
        ├── bufferline.lua
        ├── colortheme.lua
        ├── conform.lua
        ├── fzflua.lua
        ├── git.lua
        ├── indent-blankline.lua
        ├── lsp.lua
        ├── lualine.lua
        ├── misc.lua
        ├── neotree.lua
        ├── notify.lua
        ├── project.lua
        ├── treesitter.lua
        ├── ufo.lua
        └── vim-indent-object.lua
```

## Directory Purposes

**`.config/nvim/`:**
- Purpose: root of Neovim config subtree inside dotfiles repo
- Contains: entrypoint, lockfile, readme, Lua modules
- Key files: `.config/nvim/init.lua`, `.config/nvim/lazy-lock.json`
- Subdirectories: `lua/core/`, `lua/plugins/`

**`.config/nvim/lua/core/`:**
- Purpose: non-plugin-specific editor behavior
- Contains: option toggles and shared keymaps/autocmds
- Key files: `.config/nvim/lua/core/options.lua`, `.config/nvim/lua/core/keymaps.lua`
- Subdirectories: none

**`.config/nvim/lua/plugins/`:**
- Purpose: plugin specs and plugin-local config
- Contains: flat set of `*.lua` files, each mapping roughly to a feature area
- Key files: `.config/nvim/lua/plugins/lsp.lua`, `.config/nvim/lua/plugins/neotree.lua`, `.config/nvim/lua/plugins/misc.lua`
- Subdirectories: none; intentionally flat

## Key File Locations

**Entry Points:**
- `.config/nvim/init.lua` - startup entry and plugin manager bootstrap

**Configuration:**
- `.config/nvim/lazy-lock.json` - locked plugin revisions
- `.config/nvim/lua/core/options.lua` - baseline editor options
- `.config/nvim/lua/core/keymaps.lua` - global mappings and autosave hooks

**Core Logic:**
- `.config/nvim/lua/plugins/lsp.lua` - language servers, diagnostics, Mason installs
- `.config/nvim/lua/plugins/neotree.lua` - file tree behavior and mappings
- `.config/nvim/lua/plugins/fzflua.lua` - search/navigation mappings
- `.config/nvim/lua/plugins/conform.lua` - formatter routing by filetype

**Testing:**
- No test directory or test files found in `.config/nvim`

**Documentation:**
- `.config/nvim/README.md` - external learning resources only
- `.planning/codebase/*.md` - generated map docs from this run

## Naming Conventions

**Files:**
- `snake-ish`/kebab-mixed plugin filenames matching plugin/domain names: `blink-cmp.lua`, `indent-blankline.lua`, `vim-indent-object.lua`
- `core` modules use simple lowercase names: `options.lua`, `keymaps.lua`
- Markdown docs use uppercase descriptive names in `.planning/codebase/`

**Directories:**
- Lowercase directory names: `lua/`, `core/`, `plugins/`
- Flat plugin directory rather than nested feature folders

**Special Patterns:**
- One plugin spec per file, except grouped bundles like `.config/nvim/lua/plugins/misc.lua` and `.config/nvim/lua/plugins/git.lua`
- `return { ... }` as module export convention across plugin files

## Where to Add New Code

**New Editor-Wide Behavior:**
- Primary code: `.config/nvim/lua/core/`
- Config if needed: `.config/nvim/init.lua` only if load order changes

**New Plugin Integration:**
- Implementation: new or existing file in `.config/nvim/lua/plugins/`
- Lockfile impact: `.config/nvim/lazy-lock.json` after sync/update
- Keymaps: colocate in plugin file unless truly global

**New Formatting/LSP Rule:**
- Formatter config: `.config/nvim/lua/plugins/conform.lua`
- LSP/tool install list: `.config/nvim/lua/plugins/lsp.lua`

**New Documentation:**
- Human notes: `.config/nvim/README.md`
- Planning/reference docs: `.planning/codebase/`

## Special Directories

**`.planning/codebase/`:**
- Purpose: generated repo map/reference docs
- Source: created by GSD mapping workflow
- Committed: intended to be committed if project tracks planning artifacts

---

*Structure analysis: 2026-04-14*
*Update when directory structure changes*
