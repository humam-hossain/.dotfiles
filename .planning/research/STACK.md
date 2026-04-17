# Project Research: Stack for v1.1 Bug-Fix Milestone

**Project:** Cross-Platform Neovim Dotfiles
**Milestone:** v1.1 Neovim Setup Bug Fixes
**Researched:** 2026-04-17

## Existing Stack To Keep

- Neovim `0.11+` config model already adopted
- `lazy.nvim` remains plugin manager and lockfile authority
- Lua module layout under `.config/nvim/lua/` remains correct for maintenance
- `scripts/nvim-validate.sh` plus `core.health.snapshot()` remain baseline validation entry points

## Stack Additions Needed

### Runtime Triage

- Structured use of `:checkhealth` as milestone gate for actionable config defects
- More health probes inside `core.health` when current plugin/tool checks miss known failure modes
- Small diagnostic helpers around high-risk modules and keymap surfaces rather than broad new framework additions

### Validation

- Extend `scripts/nvim-validate.sh` with bug-fix-focused checks only where `:checkhealth` cannot prove correctness
- Add scripted regression coverage for keymap invocation, plugin load paths, and crash repros if they are reproducible headlessly
- Keep report artifacts under `.planning/tmp/nvim-validate/` as single debug location

## What Not To Add

- No new plugin manager, testing framework, or feature suite just for milestone optics
- No duplicate validation layer that overlaps fully with `:checkhealth`
- No broad plugin replacements unless a plugin is root cause of unresolved crashes or health failures

## Integration Points

- `.config/nvim/lua/core/health.lua`
- `scripts/nvim-validate.sh`
- `.config/nvim/lua/core/keymaps/**`
- `.config/nvim/lua/plugins/*.lua`
- `.config/nvim/README.md` rollout + verification docs if validation commands change

## Stack Recommendation

Use current stack. Improve observability and hardening around it. v1.1 is stabilization on top of v1.0 architecture, not another modernization wave.

---
*Research completed: 2026-04-17*
