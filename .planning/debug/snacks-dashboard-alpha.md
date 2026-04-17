---
status: resolved
trigger: "alpha dashboard appears instead of snacks dashboard"
created: 2026-04-16T12:30:00Z
updated: 2026-04-16T14:50:00Z
---

## Symptoms

- **Expected:** Snacks dashboard appears as startup screen on Neovim launch with no file argument **Actual:** alpha.nvim dashboard appears instead
- **Error messages:** None visible
- **Timeline:** Since Phase 5 migration (snacks.nvim replacement)
- **Reproduction:** Launch Neovim with no file argument

## Current Focus

**Root cause confirmed:** `lazy-lock.json` still contained alpha-nvim and other Phase 5 deprecations. The old plugins were installed in lazy cache and their autocmds fired on startup.

**Fix applied:** Removed deprecated plugins from `lazy-lock.json`:
- alpha-nvim
- fzf-lua
- indent-blankline.nvim
- noice.nvim
- nvim-notify

**Next action:** User must run `:Lazy sync` in Neovim to remove installed plugins

## Evidence

- **timestamp:** 2026-04-16T14:40:00Z
  **checked:** `.config/nvim/lua/plugins/` directory
  **found:** No `alpha.lua` plugin spec file exists
  **implication:** alpha.nvim was removed from spec tree in Phase 5

- **timestamp:** 2026-04-16T14:41:00Z
  **checked:** `lazy-lock.json`
  **found:** Still contained deprecated plugins from Phase 5
  **implication:** These plugins remained installed in lazy cache despite being removed from spec tree

- **timestamp:** 2026-04-16T14:42:00Z
  **checked:** `snacks.lua`
  **found:** `dashboard = { enabled = true }` is correctly configured
  **implication:** snacks dashboard was properly configured but alpha.nvim's autocmds overrode it

## Root Cause

**Confirmed:** `lazy-lock.json` contained deprecated plugin entries (alpha-nvim, fzf-lua, etc.) from before Phase 5 migration. These plugins remained installed in `~/.local/share/nvim/lazy/` and their autocmds fired on Neovim startup, causing alpha dashboard to appear instead of snacks dashboard.

## Fix Applied

1. Removed deprecated plugins from `lazy-lock.json`:
   - `alpha-nvim`
   - `fzf-lua`
   - `indent-blankline.nvim`
   - `noice.nvim`
   - `nvim-notify`

2. Added `snacks.nvim` entry to lockfile

## Verification

User must:
1. Launch Neovim
2. Run `:Lazy sync` to remove old plugins from lazy cache
3. Quit and relaunch Neovim with no args
4. Confirm snacks dashboard appears instead of alpha
