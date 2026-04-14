# Cross-Platform Neovim Dotfiles

## What This Is

This project is a shared Neovim configuration inside a `.dotfiles` repo that should run reliably across Arch Linux, Debian/Ubuntu, and Windows with OS-specific guards inside one codebase. It already provides a modular `lazy.nvim`-based setup with LSP, completion, search, file tree, git, formatting, and UI plugins, but it now needs to be cleaned up, modernized, and made predictable.

The next evolution is not "add random features." It is to turn the current config into a clean, up-to-date, best-practice Neovim setup with organized keymaps, fewer bugs, better plugin choices, and safer cross-platform behavior.

## Core Value

One shared Neovim config should give a clean, modern, bug-resistant editing experience across Linux and Windows without the setup fighting the user.

## Requirements

### Validated

- ✓ Modular Neovim config loads from `.config/nvim/init.lua` with `core/` and `plugins/` split — existing
- ✓ Plugin management is already based on `lazy.nvim` with pinned revisions in `.config/nvim/lazy-lock.json` — existing
- ✓ Current setup already includes LSP, Mason tool installs, formatting, Treesitter, fuzzy search, file explorer, git UI, statusline, folding, and theme support — existing
- ✓ Custom editor behavior already exists through centralized options and many custom keymaps — existing

### Active

- [ ] Make the Neovim config stable across Arch Linux, Debian/Ubuntu, and Windows using one shared repo with OS-specific guards
- [ ] Fix known bugs and sharp edges in the current setup, especially buffer/tab/save-quit behavior that can close all of Neovim unexpectedly
- [ ] Centralize all custom keymaps into a single authoritative location so updates are easy to manage
- [ ] Audit every plugin for relevance, correctness, and maintenance status; aggressively replace weak choices when a better option exists
- [ ] Update the configuration to current Neovim ecosystem standards and plugin conventions
- [ ] Improve startup/runtime safety with better health checks, validation, and regression prevention
- [ ] Improve performance, UI polish, and day-to-day editing ergonomics as part of the cleanup

### Out of Scope

- Separate per-OS Neovim repos or divergent configs — one shared config with guards is the chosen strategy
- Machine-specific install scripts as primary source of truth for behavior — install scripts may remain, but config quality must live in the Neovim code itself
- Adding unrelated editor features before reliability, organization, and cross-platform support are fixed — cleanup comes first

## Context

This is a brownfield Neovim configuration in `/home/pera/github_repo/.dotfiles/.config/nvim`. The codebase map shows a modular layout: `.config/nvim/init.lua` bootstraps `lazy.nvim`, `.config/nvim/lua/core/` holds global options and keymaps, and `.config/nvim/lua/plugins/` contains a flat set of plugin spec modules.

Current architecture is functional but uneven. Keymaps are broad and scattered between core and plugin files. Plugin choices mix newer tools such as `blink.cmp` with older or inconsistent patterns. Some config details are Linux-specific today, such as `xdg-open`, and the current repo has no automated validation for startup, health, plugin drift, or platform compatibility.

Known pain points already surfaced:
- Save/quit behavior around buffers/tabs can close all of Neovim unexpectedly
- Custom keymaps need to be centralized and normalized
- Plugin configs need review for bugs, outdated conventions, and better replacements
- Cross-platform support must be explicit rather than accidental

Operational note: the repo is just dotfiles. Deploying changes onto a machine may require running `@arch/nvim.sh`, which can require `sudo`.

## Constraints

- **Platform**: One shared config repo across Arch Linux, Debian/Ubuntu, and Windows — avoid forked configs because maintenance cost grows fast
- **Architecture**: OS-specific behavior must be guarded inside config code — portability is a first-class requirement
- **Quality**: Aggressive cleanup is allowed, including plugin replacement — current choices are not sacred
- **Usability**: Keymaps must become centrally managed — maintainability matters as much as feature count
- **Reliability**: Bug fixes and regression prevention are required, not optional polish — current failure modes break core editing flow
- **Workflow**: This lives in a `.dotfiles` repo and may need external install/update scripts on target machines — rollout must respect that reality

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep one shared Neovim config repo across Linux and Windows | Single source of truth is easier to maintain than separate per-OS setups | — Pending |
| Use OS-specific guards inside config rather than separate codepaths/repos | Cross-platform support is required but divergence should stay controlled | — Pending |
| Centralize all custom keymaps in one place | Current mappings are scattered and hard to audit safely | — Pending |
| Allow aggressive plugin cleanup and replacement | Goal is best-fit modern config, not preservation of every existing choice | — Pending |
| Include reliability, plugin audit, performance, UI polish, and regression prevention in v1 scope | User wants a clean up-to-date best Neovim configuration, not a narrow bugfix patch | — Pending |

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
*Last updated: 2026-04-14 after initialization*
