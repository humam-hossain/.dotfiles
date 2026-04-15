---
phase: 05-ux-and-performance-polish
plan: 01
subsystem: plugins
tags:
  - neovim
  - plugins
  - snacks
  - migration

key-files:
  created:
    - .config/nvim/lua/plugins/snacks.lua
  modified:
    - .config/nvim/lua/core/keymaps/registry.lua
    - scripts/nvim-validate.sh

key-decisions:
  - Replace 5 plugins with single snacks.nvim spec for UX coherence
  - Wire all fzf-lua registry entries to Snacks.picker.* equivalents
  - Keep lazygit keymap at <leader>gg via Snacks.lazygit()

requirements-completed:
  - UX-01

duration: 3 tasks
started: 2026-04-15T15:30:00Z
completed: 2026-04-15T15:34:00Z
---

# Phase 05 Plan 01: snacks.nvim Migration Summary

## Overview

Replaced five Neovim plugins (noice.nvim, nvim-notify, alpha-nvim, fzf-lua, indent-blankline) with a single `folke/snacks.nvim` spec. Rewired all keymap registry entries to use Snacks.picker.* equivalents while preserving lhs/desc/id values.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Create snacks.lua spec with 9 enabled modules | 71d6e98 |
| 2 | Rewire registry.lua fzf-lua entries to Snacks.picker | 71d6e98 |
| 3 | Update validation harness and run sync/smoke/health | 71d6e98 |

## Key Changes

- **snacks.lua**: Created with notifier, dashboard, picker, indent, scroll, words, lazygit, quickfile enabled; image, terminal, zen disabled
- **Deleted**: notify.lua, alpha.lua, indent-blankline.lua, fzflua.lua
- **registry.lua**: 13 search entries + 6 LSP buffer-local entries rewired to Snacks.picker.*; added git.lazygit at `<leader>gg`
- **nvim-validate.sh**: Updated PLUGIN_LIST and smoke list from 'notify','noice','fzf-lua','alpha' to 'snacks'

## Verification

- startup: PASS
- sync: PASS
- smoke: PASS
- health: PASS (snacks loaded=true)

## Deviations

None - plan executed exactly as written.

## Next Steps

Ready for Plan 02: polish lualine and colortheme after snacks migration.