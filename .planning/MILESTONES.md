# Milestones

## v1.1 Neovim Setup Bug Fixes (Shipped: 2026-04-25)

**Phases completed:** 6 phases, 15 plans, 19 tasks

**Key accomplishments:**

- Created:
- Plan:
- All 10 confirmed BUG-01 keymaps fixed: mislabeled M.lazy entries moved to M.global with callback actions, Gitsigns converted to direct Lua calls, lazy.lua dispatcher split for safe string routing, attach.lua scope token normalized.
- Phase 6 failure inventory updated: all 10 BUG-01 shared keymap entries marked Fixed with interactive verification evidence; CHECKLIST.md converted from pre-fix repro log to post-fix regression checklist.
- One-liner:
- One-liner:
- One-liner:
- Headless `:checkhealth` validator added to nvim-validate.sh with buffer-dump capture, first audit artifact captured, render-markdown config error fixed, tmux companion bindings added (BUG-019 closed), and external-open rebound from `<C-S-o>` to `<leader>o` after proving terminal delivery failure (BUG-020 closed).
- `core.health` refactored into exported probe infrastructure with required/optional classification, new `lua/config/health.lua` provider ships `:checkhealth config` with six sections, and the pre-existing `core` provider nil-check crash is eliminated via a compatibility shim.
- One-liner:
- One-liner:
- Fresh checkhealth warning audit classified 20+ warning families across all providers; config-caused which-key duplicate-prefix warnings for `<leader>e` and `<leader>b` fixed by adding a claimed-lhs guard to group registration in `whichkey.lua`.
- One-liner:
- One-liner:

---

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
