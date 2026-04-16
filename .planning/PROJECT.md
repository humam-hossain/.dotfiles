# Cross-Platform Neovim Dotfiles

**Last updated:** 2026-04-16 — Phase 6 (Nyquist Verification) complete. All 18 v1.0 requirements verified PASS across phases 1-5.

## What This Is

A shared Neovim configuration inside a `.dotfiles` repo that runs reliably across Arch Linux, Debian/Ubuntu, and Windows via OS-specific guards inside one codebase. The v1.0 milestone delivered a clean, modernized, best-practice Neovim setup: organized keymaps, aggressive plugin cleanup, cross-platform portability, a headless validation harness, and full rollout documentation.

## Core Value

One shared Neovim config gives a clean, modern, bug-resistant editing experience across Linux and Windows without the setup fighting the user.

## Requirements

### Validated

- ✓ Modular Neovim config loads from `.config/nvim/init.lua` with `core/` and `plugins/` split — existing
- ✓ Plugin management via `lazy.nvim` with pinned revisions in `lazy-lock.json` — existing
- ✓ LSP, Mason, formatting, Treesitter, fuzzy search, file explorer, git UI, statusline, folding, and theme — existing
- ✓ Custom editor behavior via centralized options and keymaps — existing
- ✓ Cross-platform OS-aware open helper (`vim.ui.open()`) replacing hardcoded shell commands — v1.0 (PLAT-01–04)
- ✓ Buffer-first close with confirmation, conservative FocusLost-only autosave — v1.0 (CORE-01–03)
- ✓ Central keymap registry with domain taxonomy; all plugins consume registry keys — v1.0 (KEY-01–03)
- ✓ Plugin audit: keep/remove/replace decisions for every plugin; refreshed lockfile — v1.0 (PLUG-01, PLUG-03)
- ✓ Headless validation harness (`nvim-validate.sh` + `core/health.lua`) for startup/sync/health/smoke — v1.0 (TOOL-01)
- ✓ Actionable health output for missing external tools — v1.0 (TOOL-03)
- ✓ Neovim 0.11-native LSP (`vim.lsp.config/enable`); format-on-save with filetype safety policy — v1.0 (PLUG-02, TOOL-02)
- ✓ Coherent UI: snacks.nvim replacing 5 plugins, globalstatus statusline, tmux-aware laststatus — v1.0 (UX-01)
- ✓ Rollout documentation: machine checklist, phase summary, verification steps, rollback modes — v1.0 (UX-02)

### Active

*(None — all v1.0 requirements shipped. Next milestone defines new active requirements.)*

### Out of Scope

- Separate per-OS Neovim repos or divergent configs — one shared config with guards is the chosen strategy
- Machine-specific install scripts as primary source of truth for behavior — config quality lives in Neovim code
- Adding unrelated editor features before reliability, organization, and cross-platform support are fixed — cleanup came first
- CI-based automated cross-platform validation — deferred to v2 (AUTO-01)
- Machine-role optional plugin profiles — deferred to v2 (AUTO-02)
- Automated machine update tooling — deferred to v2 (ROLL-01)

## Context

Shipped v1.0 on 2026-04-15. Neovim config at `.config/nvim/` is now clean and modernized:
- **2,550 LOC** Lua across 34 files
- **Stack:** Neovim 0.11+, lazy.nvim, snacks.nvim, blink.cmp, fzf-lua, conform.nvim, mason, gitsigns, neo-tree, lualine, catppuccin mocha
- **Validation:** `scripts/nvim-validate.sh` covers startup, sync, health, smoke
- **Rollout:** `README.md` documents full machine update workflow

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep one shared Neovim config repo across Linux and Windows | Single source of truth is easier to maintain than separate per-OS setups | ✓ Shipped v1.0 with OS guards |
| Use OS-specific guards inside config rather than separate codepaths | Cross-platform support required but divergence stays controlled | ✓ `vim.ui.open()` pattern established |
| Centralize all custom keymaps in one registry | Current mappings were scattered and hard to audit safely | ✓ Registry with domain taxonomy, all plugins consume keys |
| Allow aggressive plugin cleanup and replacement | Goal is best-fit modern config, not preservation of existing choices | ✓ Dropped 3 plugins, migrated 5 to snacks.nvim |
| Include reliability, plugin audit, performance, UI polish, and regression prevention in v1 scope | User wants a clean up-to-date Neovim config, not a narrow bugfix patch | ✓ All delivered |
| Neovim 0.11-native LSP via `vim.lsp.config/enable` | Removes lspconfig dependency; follows upstream direction | ✓ Clean migration, all servers work |
| snacks.nvim replaces dashboard, indent, input, notifier, scope (5 plugins) | UX coherence — one well-maintained plugin over 5 separate ones | ✓ Shipped in 05-01 |
| Format-on-save with filetype safety policy | Avoid polluting gitcommit/markdown/scratch with formatter noise | ✓ Exclusion list well-tested |
| Headless validation harness in-repo | Catch regressions without a full Neovim UI session | ✓ `nvim-validate.sh` ships in all target machines |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-15 after v1.0 milestone*
