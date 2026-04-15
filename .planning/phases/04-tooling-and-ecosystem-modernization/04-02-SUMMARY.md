---
phase: 04-tooling-and-ecosystem-modernization
plan: 02
subsystem: Formatting, Completion, Search, Tree, Git
tags: [neovim, formatting, completion, search, tree, git]
provides: Safe format-on-save policy + productivity-first completion + centralized workflow keymaps
affects: .config/nvim/lua/plugins/conform.lua, .config/nvim/lua/plugins/blink-cmp.lua, .config/nvim/lua/plugins/neotree.lua, .config/nvim/lua/plugins/fzflua.lua, .config/nvim/lua/plugins/git.lua
key-files:
  created: []
  modified:
    - .config/nvim/lua/plugins/conform.lua
    - .config/nvim/lua/plugins/blink-cmp.lua
    - .config/nvim/lua/plugins/neotree.lua
    - .config/nvim/lua/plugins/fzflua.lua
key-decisions:
  - "Enabled format_on_save with function-based safety policy — excludes gitcommit, text, markdown, diff, neo-tree, qf buffers"
  - "Kept blink.cmp docs/signature/ghost_text enabled by default per D-12/D-13"
  - "Moved neotree explorer keys from inline vim.keymap.set loop to lazy.nvim keys spec"
  - "Preserved fzf-lua and git as thin adapters to central registry — no new Linux-only paths"
  - "Preserved manual format (<leader>cf) and save-without-format (<leader>sn) in registry"
requirements-completed: [PLUG-02, TOOL-02]
duration: 8 min
completed: 2026-04-15T12:20:00Z
---

## Phase 04 Plan 02: Modernize Workflow Integrations

**Objective:** Enable productivity-first defaults for formatting/completion, clean search/tree/git integrations while preserving central keymap ownership.

## Tasks Completed

### Task 1: Turn on safe format-on-save and tune completion defaults

**Files modified:** `.config/nvim/lua/plugins/conform.lua`, `.config/nvim/lua/plugins/blink-cmp.lua`

- Enabled `format_on_save` with function-based safety policy:
  - Runs only for normal file buffers (`buftype == ""`, modifiable)
  - Skips unsafe/noisy filetypes: `gitcommit`, `text`, `markdown`, `gitrebase`, `diff`, `NeogitCommitMessage`, `neo-tree`, `qf`
  - Skips unnamed scratch buffers
  - Uses `lsp_format = "fallback"` for predictable behavior
- Kept blink.cmp productivity defaults:
  - `documentation.auto_show = true` for docs popups
  - `signature.enabled = true` for signature help
  - `ghost_text.enabled = true` for inline completion hints
- Central keymap registry preserved:
  - Manual format: `<leader>cf` → `code.format` (conform.format)
  - Save without format: `<leader>sn` → `save.no_format` (noautocmd w)

**Verification:**
```bash
rg -n 'format_on_save' .config/nvim/lua/plugins/conform.lua  # 2 matches (function + default_format_options)
rg -n 'auto_show\s*=\s*true' .config/nvim/lua/plugins/blink-cmp.lua  # 1 match
rg -n 'signature' .config/nvim/lua/plugins/blink-cmp.lua  # 2 matches (comment + enabled)
rg -n 'ghost_text' .config/nvim/lua/plugins/blink-cmp.lua  # 1 match
./scripts/nvim-validate.sh startup  # PASS
./scripts/nvim-validate.sh smoke     # PASS
```

### Task 2: Modernize search, tree, and git integrations

**Files modified:** `.config/nvim/lua/plugins/neotree.lua`, `.config/nvim/lua/plugins/fzflua.lua`

- Removed end-of-file global `vim.keymap.set(...)` loop in neotree.lua
- Replaced with `keys = require("core.keymaps.lazy").explorer_keys()` in plugin spec (lazy.nvim handles key-trigger loading)
- External open behavior already uses `vim.ui.open` in `core/open.lua` (cross-platform, no Linux-specific assumptions)
- fzf-lua remains thin adapter to central search key set
- git.lua unchanged (thin config over gitsigns + fugitive)

**Verification:**
```bash
! rg -n 'vim\.keymap\.set\(' .config/nvim/lua/plugins/neotree.lua  # only event handler, no global loop
./scripts/nvim-validate.sh startup  # PASS
./scripts/nvim-validate.sh smoke     # PASS
```

## Deviations

None — plan executed exactly as written.

## Self-Check: PASSED

- [x] conform.lua has active format_on_save policy with exclusions
- [x] blink-cmp.lua keeps docs/signature/ghost_text enabled
- [x] neotree.lua no longer sets global mappings via inline loop
- [x] All workflow keymaps remain owned by central registry
- [x] No new Linux-only command paths in search/tree/git
- [x] startup and smoke validation pass