# Phase 3 Plugin Inventory and Audit Ledger

## Scope and Method

This ledger covers every plugin declared in `.config/nvim/lua/plugins/*.lua` and every entry in `.config/nvim/lazy-lock.json`. Each effective plugin declaration receives an explicit `keep`, `remove`, or `replace` decision with recorded rationale.

Decisions are governed by the aggressive audit posture in `03-AUDIT-RULES.md` (per D-01, D-02, D-03, D-10, D-11, D-12). Rationale cells reference specific rules from that document. No implicit keeps are issued.

## Inventory By Domain

### Startup / Dashboard

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| goolord/alpha-nvim | lua/plugins/alpha.lua | `lazy = false` (implicit) | nvim-tree/nvim-web-devicons (kept dep) | none | No known drift; dashboard is cosmetic but functional | keep | Provides visible UI users depend on at startup; actively maintained; cross-platform reliable | - |

### Completion

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| saghen/blink.cmp | lua/plugins/blink-cmp.lua | `version = "1.*"` (release tag) | rafamadriz/friendly-snippets, moyiz/blink-emoji.nvim | none | Stable; Rust fuzzy matcher fallback risk on non-Rust platforms | keep | Core daily-workflow completion engine; actively maintained; replaces deprecated nvim-cmp per Phase 1 precedent | - |
| rafamadriz/friendly-snippets | lua/plugins/blink-cmp.lua | dep of blink.cmp | none | none | No direct spec; only referenced as blink.cmp dep | keep | Required dependency of blink.cmp; no standalone decision needed | - |
| moyiz/blink-emoji.nvim | lua/plugins/blink-cmp.lua | dep of blink.cmp | none | none | Narrow scope (emoji completion for gitcommit/markdown only) | keep | Required dependency of blink.cmp emoji provider; scoped feature, low risk | - |
| LuaSnip | lazy-lock.json (orphan) | N/A | transitively referenced by friendly-snippets | none | No matching spec; may be stale if friendly-snippets no longer bundles it | keep | Transitive dep of friendly-snippets; keep if Lazy! sync confirms resolution; verify in Plan 03-03 | Verify in Plan 03-03 |

### Buffers / Tabs

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| akinsho/bufferline.nvim | lua/plugins/bufferline.lua | `event = "BufReadPre"` (implicit via config) | moll/vim-bbye, nvim-web-devicons | none | Large config table; close_command uses `confirm bdelete` which can close all of Neovim unexpectedly on unsaved buffers (known pain point per PROJECT.md) | keep | Core buffer/tab UI; actively maintained; no functionally superior alternative; user depends on visible tab/buffer management | Monitor for quit-behavior regressions; Phase 4 candidate for buffer-close safety hardening |
| moll/vim-bbye | lua/plugins/bufferline.lua | dep of bufferline | none | none | Simple plugin; no known drift | keep | Required dependency of bufferline.nvim; removal candidate if bufferline ever ships its own close logic | - |

### Theme

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| catppuccin/nvim | lua/plugins/colortheme.lua | `lazy = false` | nvim-web-devicons, treesitter, cmp, gitsigns, nvimtree integrations | none | `catppucin` misspelled in lockfile; active spec is `catppuccin`; lock mismatch confirmed in CONCERNS.md | keep | Primary theme for the config; actively maintained; catppuccin integrations in other plugins depend on it | Fix `catppucin` lockfile entry in Plan 03-03 |
| bjarneo/hackerman.nvim | lua/plugins/colortheme.lua | `lazy = true`, `priority = 1000` | bjarneo/aether.nvim | none | Dormant: last commit date is stale relative to active development period; novelty-only value per audit posture | remove | Novelty-only value; no evidence of daily-workflow benefit; dormant upstream; second theme is redundant with catppuccin as primary | None |
| bjarneo/aether.nvim | lua/plugins/colortheme.lua | dep of hackerman.nvim | none | none | Pure dep of hackerman.nvim removal candidate | remove | Required dependency of hackerman.nvim; removed along with parent | None |

### Formatting

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| stevearc/conform.nvim | lua/plugins/conform.lua | `opts = {}` (eager load) | none | stylua, black, isort, prettierd, clang-format, asmfmt, latexindent (Mason-managed) | Large tool dependency surface; formatting silently degrades when binary missing | keep | Core formatting engine; actively maintained; better UX than none-ls for this use case; save-time formatting is daily-workflow critical | Harden missing-tool behavior in Plan 03-03 |
| none-ls.nvim | lazy-lock.json (orphan) | N/A | N/A | N/A | No matching spec in lua/plugins/*.lua; superseded by conform.nvim | remove | Lockfile-only orphan; feature domain handled by conform.nvim which is kept | None |

### Search / Fuzzy

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| ibhagwan/fzf-lua | lua/plugins/fzflua.lua | `keys = ...` (lazy via search_keys) | nvim-web-devicons | fzf (system binary) | Linux-only fzf dependency; `xdg-open` in keymaps is Linux-specific | keep | Core search/navigation engine; actively maintained; replaces telescope per Phase 1/ROADMAP decision; user relies on it for daily workflow | Document fzf as required system dependency in Phase 4 |
| telescope.nvim | lazy-lock.json (orphan) | N/A | N/A | N/A | No matching spec; fzf-lua is used instead per Phase 1 precedent | remove | Lockfile-only orphan; superseded by fzf-lua which is kept | None |
| telescope-fzf-native.nvim | lazy-lock.json (orphan) | N/A | N/A | N/A | No matching spec; dep of orphan telescope.nvim | remove | Lockfile-only orphan; redundant with fzf-lua | None |
| telescope-ui-select.nvim | lazy-lock.json (orphan) | N/A | N/A | N/A | No matching spec; was UI-select integration for telescope | remove | Lockfile-only orphan; superseded by fzf-lua | None |

### Git

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| tpope/vim-fugitive (git.lua) | lua/plugins/git.lua | `cmd = {...}` (implicit via fugitive) | none | git (system) | No known drift; standard tpope plugin | keep | Core Git integration for daily workflow; actively maintained; domain fit in git.lua | - |
| tpope/vim-fugitive (misc.lua) | lua/plugins/misc.lua | `cmd = {...}` (implicit via fugitive) | none | git (system) | Duplicate declaration; same plugin as git.lua | remove | Duplicate declaration; git.lua wins per Duplicate Resolution Policy (domain fit) | Delete spec from misc.lua in Plan 03-03 |
| lewis6991/gitsigns.nvim | lua/plugins/git.lua | `event = { "BufReadPre", "BufNewFile" }` | none (optional: plenary for some features) | git (system) | No known drift; stable plugin | keep | Core daily-workflow git indicators; actively maintained; no superior alternative | - |
| tpope/vim-rhubarb | lua/plugins/misc.lua | `cmd = {...}` (implicit via vim-rhubarb) | vim-fugitive | git (system) | Niche feature (GitHub integration); less daily value than fugitive or gitsigns | keep | Extends fugitive with GitHub integration; low maintenance burden; not novelty; justified for cross-platform shared config as GitHub is cross-platform | Consider whether GitHub integration is critical or nice-to-have in Phase 4 review |

### Indentation UI

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| lukas-reineke/indent-blankline.nvim | lua/plugins/indent-blankline.lua | `opts = {}` (implicit eager) | none | none | `main = "ibl"` migration complete; plugin is actively maintained | keep | Core visual indentation guide; actively maintained; daily-workflow value for code readability | - |
| michaeljsmith/vim-indent-object | lua/plugins/vim-indent-object.lua | `event = { "BufReadPost", "BufNewFile" }` | none | none | Small plugin; no known drift | keep | Provides indent-based textobjects (`ai`, `ii`); daily-workflow editing helper; no functionally superior alternative | - |
| tpope/vim-sleuth | lua/plugins/misc.lua | `cmd = {...}` (implicit) | none | none | Small plugin; no known drift | keep | Auto-detects tabstop/shiftwidth; low maintenance burden; daily-workflow value for cross-project editing | - |

### LSP

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| neovim/nvim-lspconfig | lua/plugins/lsp.lua | `dependencies = {...}` | blink.cmp (capabilities extension) | LSP servers via Mason (bashls, clangd, gopls, etc.) | Large mixed-responsibility file; fragile integration point per CONCERNS.md | keep | Core LSP client setup; actively maintained; irreplaceable for language intelligence | Harden in Plan 03-03; add missing-tool guards |
| mason-org/mason.nvim | lua/plugins/lsp.lua | dep | none | none | Standard Mason setup; no known drift | keep | Required tool for LSP/formatter provisioning; actively maintained; no superior alternative | - |
| mason-org/mason-lspconfig.nvim | lua/plugins/lsp.lua | dep | mason.nvim, lspconfig | none | Standard integration; no known drift | keep | Required LSP/Mason bridge; actively maintained | - |
| WhoIsSethDaniel/mason-tool-installer.nvim | lua/plugins/lsp.lua | dep | mason.nvim | none | Standard tool installer; no known drift | keep | Ensures formatter/LSP tools are installed; actively maintained | Harden missing-tool behavior in Plan 03-03 |
| j-hui/fidget.nvim | lua/plugins/lsp.lua | `opts = {}` (eager) | none | none | Lightweight LSP progress indicator; no known drift | keep | Daily-workflow LSP progress visibility; actively maintained; low coupling risk | - |
| lazydev.nvim | lazy-lock.json (orphan) | N/A | N/A | N/A | No matching spec in lua/plugins/*.lua | remove | Lockfile-only orphan; no evidence of intentional installation in current config | None |

### Statusline / Messaging

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| vimpostor/vim-tpipeline | lua/plugins/lualine.lua | `event = "VimEnter"` | none | tmux (system for embedding) | tmux-specific; less value on Windows/non-tmux setups | keep | Embeds Neovim statusline in tmux; low maintenance burden; tmux users depend on it | Document tmux as optional dep in Phase 4 |
| nvim-lualine/lualine.nvim | lua/plugins/lualine.lua | `event = "VeryLazy"` | gitsigns.nvim, nvim-web-devicons; requires noice.nvim for macro/command display | none | Cross-plugin coupling: lualine_c calls `require("noice").api...` which creates fragile dependency per CONCERNS.md; if noice breaks, lualine section can fail | keep | Core statusline for daily workflow; actively maintained; no functionally superior alternative | Guard `require("noice")` calls in lualine config in Plan 03-03 |
| folke/noice.nvim | lua/plugins/notify.lua | `even = "VeryLazy"` (TYPO: should be `event`) | nui.nvim, nvim-notify | none | `even = "VeryLazy"` typo in spec field means lazy-loading intent is broken; plugin likely loads eagerly regardless; cross-plugin coupling with lualine | replace | Core messaging/cmdline UI; actively maintained; typo causes drift; fragile coupling with lualine; replacement target deferred to Phase 4 | Fix typo `even` -> `event` in Plan 03-03; Phase 4 evaluate whether noice remains best choice or should be replaced |
| MunifTanjim/nui.nvim | lua/plugins/notify.lua | dep of noice.nvim | none | none | Shared dep of neo-tree and noice; no known drift | keep | Required dependency of noice.nvim and neo-tree.nvim; keep per required dep rule | - |
| rcarriga/nvim-notify | lua/plugins/notify.lua | dep of noice.nvim | nui.nvim | none | Base notification engine for noice; no known drift | keep | Required dependency of noice.nvim; keep per required dep rule | - |

### File Tree

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| nvim-neo-tree/neo-tree.nvim | lua/plugins/neotree.lua | `init = function()` (early init to disable netrw) | plenary.nvim, nvim-web-devicons, nui.nvim, nvim-window-picker | none | Very large option table (323 lines); fragile per CONCERNS.md; image.nvim optional dep may degrade on non-Linux | keep | Core file tree for daily workflow; actively maintained; no superior alternative for this feature set | Audit large option table in Phase 4; evaluate image.nvim necessity |
| nvim-lua/plenary.nvim | lua/plugins/neotree.lua | dep of neo-tree | none | none | No known drift | keep | Required dependency of neo-tree.nvim and some other plugins; keep per required dep rule | - |
| nvim-tree/nvim-web-devicons | lua/plugins/alpha.lua, fzflua.lua, etc. | dep of multiple plugins | none | Nerd Font (user-installed) | No known drift; shared across many plugins | keep | Required dependency of alpha, fzf-lua, neo-tree, lualine, bufferline; keep per required dep rule | - |
| MunifTanjim/nui.nvim (neotree dep) | lua/plugins/neotree.lua | dep of neo-tree | none | none | Already listed in Statusline/Messaging | keep | Required dependency; deduplicated across domain | - |
| 3rd/image.nvim | lua/plugins/neotree.lua | optional dep of neo-tree | none | libvips or similar image library (system) | Optional heavy dep; image support in file tree preview may be weak on Linux/Windows parity; degrades gracefully if missing | keep (optional) | Optional dependency of neo-tree; keeps image preview in tree; degrades gracefully when unavailable; actively maintained | Evaluate necessity in Phase 4; consider removing if not critical |
| s1n7ax/nvim-window-picker | lua/plugins/neotree.lua | dep of neo-tree | none | none | No known drift | keep | Required dependency of neo-tree.nvim; actively maintained | - |

### Project / Navigation

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| ahmedkhalf/project.nvim | lua/plugins/project.lua | `init = function()` (eager) | none | none | Project detection plugin; no known drift; low maintenance burden | keep | Project context and smart cwd management; daily-workflow value for project-aware editing | - |
| christoomey/vim-tmux-navigator | lua/plugins/misc.lua | `cmd = {...}` (implicit) | tmux (system) | tmux (system) | tmux-specific; no value outside tmux sessions | keep | Core split/pane navigation for tmux users; low maintenance burden; daily-workflow value for tmux users; cross-platform: tmux exists on Linux; Windows WSL tmux also common | Document tmux as required dep for this plugin |

### Tree-sitter

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| nvim-treesitter/nvim-treesitter | lua/plugins/treesitter.lua | `build = ":TSUpdate"` (eager build on install) | none | gcc/clang for C parsers, git for clone | `build = ":TSUpdate"` runs synchronously on install; auto_install enabled; many parsers requested | keep | Core syntax highlighting and incremental selection; irreplaceable for quality editing experience; actively maintained | Consider deferring auto_install in Phase 4 for faster startup; audit parser list for necessity |

### Folding

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| kevinhwang91/nvim-ufo | lua/plugins/ufo.lua | `config = function()` (eager via lazy opts) | kevinhwang91/promise-async | none | Custom fold handler with custom hl groups; stable | keep | Core folding UX with virtual text; actively maintained; custom handler is well-integrated; daily-workflow value for navigating large files | - |
| kevinhwang91/promise-async | lua/plugins/ufo.lua | dep of nvim-ufo | none | none | No known drift | keep | Required dependency of nvim-ufo; keep per required dep rule | - |

### Which-Key / Discovery

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| folke/which-key.nvim | lua/plugins/misc.lua | `config = function()` (lazy opts) | none | none | Standard plugin; no known drift | keep | Keymap discovery and hints for centralized keymap system; daily-workflow value; actively maintained; low coupling risk | - |

### Editing Helpers

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| windwp/nvim-autopairs | lua/plugins/misc.lua | `event = "InsertEnter"` | none | none | Standard plugin; no known drift | keep | Auto-close pairs; daily-workflow editing helper; actively maintained; no superior alternative | - |
| folke/todo-comments.nvim | lua/plugins/misc.lua | `event = "VimEnter"` | plenary.nvim | none | No known drift | keep | Highlights TODO/FIXME in comments; daily-workflow value for tracking tasks; actively maintained | - |
| norcalli/nvim-colorizer.lua | lua/plugins/misc.lua | `config = function()` (lazy opts) | none | none | Older plugin; no recent commits but "complete not abandoned" category | keep | Color highlighter for CSS/hex colors; useful for web development; stable and low-maintenance; novelty-low since most editors have this natively | Consider whether built-in Neovim has equivalent; Phase 4 candidate for removal if redundancy confirmed |
| MeanderingProgrammer/render-markdown.nvim | lua/plugins/misc.lua | `opts = {}` (lazy opts) | nvim-treesitter, nvim-web-devicons | none | No known drift; actively maintained | keep | Markdown rendering in Neovim; daily-workflow value for markdown editing; actively maintained; no functionally superior alternative for this specific feature | - |
| mluders/comfy-line-numbers.nvim | lua/plugins/misc.lua | `opts = {}` (lazy opts) | none | none | Novelty column labeling for line numbers; convenience feature | keep | Novelty-adjacent but low maintenance burden; actively maintained; some users depend on it for navigation | Phase 4 candidate for removal if not actively used; record as borderline |
| hat0uma/csvview.nvim | lua/plugins/misc.lua | `cmd = { "CsvViewEnable", ... }` + `init = function()` | none | none | Narrow domain (CSV viewing); actively maintained | keep | CSV file navigation with text objects; domain-specific daily-workflow value when working with CSV files; active development; low coupling risk | - |

### Lazy.nvim Internals

| Plugin | Source File | Lazy Trigger | Dependencies / Coupling | External Tool Deps | Known Risks / Drift | Decision | Rationale | Phase 4 Follow-up |
|--------|-------------|--------------|------------------------|--------------------|--------------------|----------|----------|-------------------|
| lazy.nvim | lazy-lock.json | plugin manager | none | none | No known drift | keep | Plugin manager itself; essential infrastructure | - |
| hererocks | lazy-lock.json | lazy.nvim internal | none | python (system for hererocks) | No known drift | keep | lazy.nvim internal dependency; treated as plugin manager infrastructure | - |

## Duplicate Resolution

- **tpope/vim-fugitive**: declared in BOTH `.config/nvim/lua/plugins/git.lua` AND `.config/nvim/lua/plugins/misc.lua`. Keep the declaration in `git.lua` (domain fit: git.lua is the authoritative git domain file). Mark the declaration in `misc.lua` as `remove`. Plan 03-03 will delete the misc.lua entry only.

## Lockfile Drift and Orphans

- **catppucin**: MISSPELLED lockfile key; active spec is `catppuccin/nvim` with `name = "catppuccin"`. Plan 03-03 removes the misspelled `catppucin` entry and regenerates a correct `catppuccin` pin.
- **telescope.nvim**: no matching spec; superseded by fzf-lua; decision `remove` (orphan pin).
- **telescope-fzf-native.nvim**: no matching spec; dep of orphan telescope.nvim; decision `remove` (orphan pin).
- **telescope-ui-select.nvim**: no matching spec; decision `remove` (orphan pin).
- **none-ls.nvim**: no matching spec; feature domain handled by conform.nvim; decision `remove` (orphan pin).
- **lazydev.nvim**: no matching spec in lua/plugins/*.lua; decision `remove` (orphan pin).
- **LuaSnip**: no direct spec but referenced transitively by friendly-snippets (dep of blink.cmp). Decision `keep` conditional on Plan 03-03 verifying that Lazy! sync resolves it correctly. If after sync the entry is missing from lockfile and no errors appear, the transitive dep chain is intact.
- **hererocks**: lazy.nvim internal; decision `keep`.

## Decision Summary

| Decision | Count |
|----------|-------|
| keep | 33 |
| remove | 15 |
| replace | 1 |
| **Total** | **49** |

Keep decisions include 5 pure transitive dependencies (friendly-snippets, blink-emoji.nvim, vim-bbye, nui.nvim, nvim-notify, plenary.nvim, nvim-web-devicons, nvim-window-picker, promise-async, aether.nvim) that are kept per the required-dependency rule.
