# Project Research: Architecture for v1.1 Bug-Fix Milestone

**Project:** Cross-Platform Neovim Dotfiles
**Milestone:** v1.1 Neovim Setup Bug Fixes
**Researched:** 2026-04-17

## Recommended Integration Approach

v1.1 should keep current architecture layers intact:

1. Bootstrap in `.config/nvim/init.lua`
2. Core policy/helpers in `.config/nvim/lua/core/**`
3. Plugin-local behavior in `.config/nvim/lua/plugins/*.lua`
4. Validator + health artifacts in `scripts/` and `.planning/tmp/`

## Change Strategy

### New vs Modified

- **Modify:** keymap registry/helpers if mappings throw or bind incorrectly
- **Modify:** plugin specs/config tables where runtime failures or health errors originate
- **Modify:** `core.health` and validator scripts to improve bug detection
- **Avoid new components:** unless repeated bugs show missing abstraction

### Data Flow

- User reports or validation failures produce repro case
- Repro case maps to one of: keymap, plugin config, crash path, health output
- Fix lands in config
- Validation updates prove bug stays fixed
- README/health guidance updates if maintainer workflow changes

## Suggested Build Order

1. Inventory failures and reproduce them reliably
2. Fix keymap/runtime errors that block core navigation and editing
3. Harden plugin configs and crash-prone flows
4. Clean up `:checkhealth` signal
5. Expand scripts only for uncovered regressions
6. Verify full milestone with documented commands

## Architecture Guardrails

- Keep keymap authority centralized in registry helpers
- Prefer narrow plugin config fixes over wholesale rewrites
- Treat `:checkhealth` as shared diagnostic contract
- Keep validation outputs machine-readable where practical

---
*Research completed: 2026-04-17*
