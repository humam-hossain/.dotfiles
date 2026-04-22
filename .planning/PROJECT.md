# Cross-Platform Neovim Dotfiles

**Last updated:** 2026-04-17 — Milestone v1.1 started for Neovim setup bug fixes.

## What This Is

A shared Neovim configuration inside a `.dotfiles` repo that runs across Arch Linux, Debian/Ubuntu, and Windows via OS-specific guards inside one codebase. The v1.0 milestone delivered a modernized, modular setup; v1.1 shifts focus from feature churn to bug removal, health cleanup, and stronger regression detection so the setup stays predictable under daily use.

## Current Milestone: v1.1 Neovim Setup Bug Fixes

**Goal:** Make the shared Neovim setup bug-free and predictable for daily editing.

**Target features:**
- Fix broken or erroring keymaps
- Fix plugin runtime bugs and misconfigurations
- Fix crashes caused by config behavior
- Resolve actionable `:checkhealth` errors and warnings
- Strengthen validation with `:checkhealth` first, scripted checks second when health is insufficient

## Core Value

One shared Neovim config gives a clean, modern, bug-resistant editing experience across Linux and Windows without the setup fighting the user.

## Requirements

### Validated

- ✓ Config-caused E488/Lua errors removed from 9 shared keymaps; registry-driven mappings execute safely — v1.1 (BUG-01, validated Phase 7)
- ✓ Modular Neovim config loads from `.config/nvim/init.lua` with `core/` and `plugins/` split — existing
- ✓ Plugin management via `lazy.nvim` with pinned revisions in `lazy-lock.json` — existing
- ✓ LSP, Mason, formatting, Treesitter, search, file explorer, git UI, statusline, folding, and theme — existing
- ✓ Custom editor behavior via centralized options and keymaps — existing
- ✓ Cross-platform OS-aware open helper (`vim.ui.open()`) replacing hardcoded shell commands — v1.0 (PLAT-01–04)
- ✓ Buffer-first close with confirmation, conservative FocusLost-only autosave — v1.0 (CORE-01–03)
- ✓ Central keymap registry with domain taxonomy; all plugins consume registry keys — v1.0 (KEY-01–03)
- ✓ Plugin audit: keep/remove/replace decisions for every plugin; refreshed lockfile — v1.0 (PLUG-01, PLUG-03)
- ✓ Headless validation harness (`scripts/nvim-validate.sh` + `core/health.lua`) for startup/sync/health/smoke — v1.0 (TOOL-01)
- ✓ Actionable health output for missing external tools — v1.0 (TOOL-03)
- ✓ Neovim 0.11-native LSP (`vim.lsp.config/enable`); format-on-save with filetype safety policy — v1.0 (PLUG-02, TOOL-02)
- ✓ Coherent UI: snacks.nvim replacing 5 plugins, globalstatus statusline, tmux-aware laststatus — v1.0 (UX-01)
- ✓ Rollout documentation: machine checklist, phase summary, verification steps, rollback modes — v1.0 (UX-02)

### Active

- [ ] v1.1 bug-fix milestone removes config-caused runtime errors from keymaps, plugins, and crash-prone flows
- [ ] v1.1 milestone makes `:checkhealth` a trustworthy first-line diagnostic for this setup
- [ ] v1.1 milestone expands validation so regressions blocked by scripts are reproducible when `:checkhealth` alone is not enough

### Out of Scope

- New feature expansion unrelated to bug fixing — milestone is stabilization-first
- Forked per-OS Neovim configs — one shared config remains source of truth
- Eliminating warnings caused only by optional user tooling or machine-local preferences — document and classify instead
- CI-based multi-OS automation — still deferred until local validation is strong enough
- Machine-role optional plugin profiles — still deferred until core setup is stable

## Context

Shipped v1.0 on 2026-04-15, then closed remaining gap and documentation work through phases 6-12 on 2026-04-17. Current config already has:
- Modular Lua structure under `.config/nvim/`
- Central keymap registry and helper layers
- Headless validator in `scripts/nvim-validate.sh`
- Rollout docs in `.config/nvim/README.md`

v1.1 is a brownfield stabilization milestone. Work should start from real failures: keymaps that throw, plugin configs that misbehave at runtime, crashes during normal workflows, and `:checkhealth` output that points to config bugs or missing guards. `:checkhealth` is primary signal; additional scripted checks should cover flows that health cannot validate reliably.

## Constraints

- **Platform**: One shared config across Arch Linux, Debian/Ubuntu, and Windows — portability remains first-class
- **Workflow**: This lives in a `.dotfiles` repo — fixes must be safe for rollout onto existing machines
- **Reliability**: Bug fixes outrank feature additions — regression prevention is part of done
- **Validation**: `:checkhealth` should catch what it can; scripts cover the remaining runtime gaps
- **Compatibility**: Preserve existing modern v1.0 architecture unless a bug requires targeted rollback or replacement

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep one shared Neovim config repo across Linux and Windows | Single source of truth is easier to maintain than separate per-OS setups | ✓ Shipped v1.0 with OS guards |
| Use OS-specific guards inside config rather than separate codepaths | Cross-platform support required but divergence stays controlled | ✓ `vim.ui.open()` pattern established |
| Centralize all custom keymaps in one registry | Scattered mappings were hard to audit safely | ✓ Registry with domain taxonomy, all plugins consume keys |
| Allow aggressive plugin cleanup and replacement | Goal is best-fit modern config, not preservation of existing choices | ✓ Dropped 3 plugins, migrated 5 to snacks.nvim |
| Include reliability, plugin audit, performance, UI polish, and regression prevention in v1 scope | User wanted a clean up-to-date Neovim config, not a narrow bugfix patch | ✓ Delivered |
| Neovim 0.11-native LSP via `vim.lsp.config/enable` | Removes legacy setup path; follows upstream direction | ✓ Clean migration, all servers work |
| snacks.nvim replaces dashboard, indent, input, notifier, scope (5 plugins) | UX coherence: one well-maintained plugin over several overlapping plugins | ✓ Shipped in v1.0 |
| Format-on-save with filetype safety policy | Avoid polluting commit messages, markdown, and scratch buffers with formatter noise | ✓ Exclusion list well-tested |
| Headless validation harness lives in-repo | Catch regressions without full UI session | ✓ `scripts/nvim-validate.sh` shipped |
| v1.1 bug-fix milestone treats `:checkhealth` as first diagnostic surface | Health output is fastest shared debugging entry point across machines | — Pending |
| Add scripts only where `:checkhealth` cannot prove setup correctness | Avoid duplicate validation surfaces and keep maintenance cost bounded | — Pending |

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
*Last updated: 2026-04-22 after Phase 7 (keymap-reliability-fixes) complete*
