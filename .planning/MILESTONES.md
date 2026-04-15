# Milestones

## v1.0 Neovim Modernization (Shipped: 2026-04-15)

**Phases completed:** 5 phases, 15 plans, 15 tasks

**Key accomplishments:**

- Replaced hardcoded Linux commands with `vim.ui.open()` OS-aware helper across core keymaps and neo-tree (PLAT-01–04)
- Fixed buffer/window/save-quit lifecycle — buffer-first close with confirmation, conservative FocusLost-only autosave (CORE-01–03)
- Built central keymap registry with domain taxonomy (f/c/g/e/b/w/t/s prefixes); all plugin files now consume registry keys (KEY-01–03)
- Built headless validation harness (`scripts/nvim-validate.sh` + `core/health.lua`) for startup, sync, health, and smoke checks (TOOL-01)
- Audited every plugin (keep/remove/replace); dropped hackerman.nvim, aether.nvim, image.nvim; refreshed lazy-lock.json (PLUG-01, PLUG-03)
- Migrated LSP to Neovim 0.11-native `vim.lsp.config/enable`; enabled format-on-save with filetype safety policy (PLUG-02, TOOL-02)
- Replaced 5 plugins with snacks.nvim; polished statusline with globalstatus + tmux-aware laststatus guard (UX-01)
- Documented full rollout workflow: machine update checklist, phase-by-phase change summary, verification steps, rollback modes (UX-02)

---
