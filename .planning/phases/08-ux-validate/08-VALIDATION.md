---
phase: "08"
status: captured
captured: "2026-04-16"
source: "Phase 5 (05-ux-and-performance-polish) VERIFICATION.md"
---

# Phase 8 Validation: UX Requirements Criteria Capture

## Purpose

Captures UX-01, UX-02 success criteria from Phase 5 for regression testing. Follows Phase 7 VALIDATION.md pattern.

## UX-01: Coherent UI — Criteria

| Criterion | Source File | Verification Method |
|-----------|-------------|---------------------|
| snacks.nvim replaces notify/alpha/indent/fzf-lua/noice | snacks.lua | File exists + submodule enabled flags checked |
| Registry wired to Snacks.picker (search keys) | registry.lua | `Snacks.picker.` calls in lazy mappings |
| Registry wired to Snacks.lazygit | registry.lua | `Snacks.lazygit()` call in git.lazygit entry |
| lualine globalstatus=true | lualine.lua | `globalstatus = true` in options table |
| lualine tmux-aware laststatus | lualine.lua | `if vim.env.TMUX then vim.o.laststatus = 0 else vim.o.laststatus = 3 end` |
| catppuccin snacks integration | colortheme.lua | `integrations = { snacks = { enabled = true } }` |

**Regression test:**
```bash
grep "Snacks.picker" .config/nvim/lua/core/keymaps/registry.lua
grep "globalstatus.*true" .config/nvim/lua/plugins/lualine.lua
grep "TMUX" .config/nvim/lua/plugins/lualine.lua
grep "snacks.*enabled.*true" .config/nvim/lua/plugins/colortheme.lua
```

## UX-02: Rollout Documentation — Criteria

| Criterion | Source File | Verification Method |
|-----------|-------------|---------------------|
| Rollout section exists | README.md | "Rollout and Update Workflow" section present |
| Machine checklist present | README.md | "Machine Update Checklist" section present |
| Post-deploy verification steps | README.md | "Post-Deploy Verification" section present |
| Rollback instructions present | README.md | "Rollback Instructions" section present |

**Regression test:**
```bash
grep -E "Rollout|Checklist|Verification|Rollback" .config/nvim/README.md | wc -l
# Expect >= 4 matches
```

## Source Evidence

Captured from `.planning/milestones/v1.0-phases/05-ux-and-performance-polish/05-VERIFICATION.md` (Phase 5, completed 2026-04-15).
