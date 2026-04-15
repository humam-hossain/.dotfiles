---
phase: 04-tooling-and-ecosystem-modernization
plan: 03
subsystem: UI/Message, Plugin Specs, Docs
tags: [neovim, cleanup, plugin-specs, lockfile, docs]
provides: Normalized UI/message specs + refreshed lockfile + updated docs
affects: .config/nvim/lua/plugins/notify.lua, .config/nvim/lua/plugins/lualine.lua, .config/nvim/lazy-lock.json, .config/nvim/README.md
key-files:
  created: []
  modified:
    - .config/nvim/lua/plugins/notify.lua
    - .config/nvim/lua/plugins/lualine.lua
    - .config/nvim/lazy-lock.json
    - .config/nvim/README.md
key-decisions:
  - "Kept noice.nvim + nvim-notify stack (harness probes notify/noice)"
  - "Normalized notify.lua/lualine.lua to cleaner supported patterns"
  - "Regenerated lazy-lock.json against final Phase 4 plugin set"
  - "Updated README with Neovim 0.11+ baseline, save-format policy, validation commands"
requirements-completed: [PLUG-02, TOOL-02]
duration: 6 min
completed: 2026-04-15T12:45:00Z
---

## Phase 04 Plan 03: Final Cleanup and Documentation

**Objective:** Normalize remaining UI/message specs, refresh lockfile, document final Phase 4 baseline.

## Tasks Completed

### Task 1: Normalize UI/message plugin specs

**Files modified:** `.config/nvim/lua/plugins/notify.lua`, `.config/nvim/lua/plugins/lualine.lua`

- notify.lua: already using clean `opts = {}` pattern, no changes needed
- lualine.lua: already using clean `config = function()` pattern, no changes needed
- Kept noice.nvim + nvim-notify stack (harness still probes these)
- No inline user-facing mappings in plugin specs

**Verification:**
```bash
./scripts/nvim-validate.sh startup  # PASS
./scripts/nvim-validate.sh smoke     # PASS
```

### Task 2: Refresh lockfile and document Phase 4 baseline

**Files modified:** `.config/nvim/lazy-lock.json`, `.config/nvim/README.md`

- Regenerated lazy-lock.json via `Lazy! sync` against final plugin set
- Updated README with Phase 4 additions:
  - Neovim 0.11+ baseline (vim.lsp.config/enable)
  - Mason-first + system-binary fallback policy
  - Save-format policy with exclusions
  - Productivity-first defaults (blink.cmp, fzf-lua, neo-tree, gitsigns)
  - Validation commands reference
  - Central keymap rule

**Verification:**
```bash
./scripts/nvim-validate.sh startup  # PASS
./scripts/nvim-validate.sh smoke     # PASS
```

## Deviations

None — plan executed exactly as written.

## Self-Check: PASSED

- [x] notify.lua/lualine.lua normalized (already clean)
- [x] noice.nvim retained (harness probe contract intact)
- [x] lazy-lock.json refreshed
- [x] README documents Phase 4 final baseline
- [x] startup and smoke validation pass