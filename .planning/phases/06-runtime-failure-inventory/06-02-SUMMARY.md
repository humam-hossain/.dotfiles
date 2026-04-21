---
phase: 06-runtime-failure-inventory
plan: 02
subsystem: validation
tags: [keymaps, bugs, gitsigns, lazy, registry]

dependency_graph:
  requires:
    - phase: 06-runtime-failure-inventory-01
      provides: FAILURES.md with discovered failures
  provides:
    - FAILURES.md updated with confirmed statuses and root cause
    - CHECKLIST.md with reproduction steps for 10 confirmed bugs

tech_stack:
  patterns:
    - Interactive verification against static analysis predictions
    - Root cause tracing via stack traces to lazy.lua:29

key_files:
  created:
    - .planning/phases/06-runtime-failure-inventory/CHECKLIST.md
  modified:
    - .planning/phases/06-runtime-failure-inventory/FAILURES.md

key_decisions:
  - "RC-01: lazy.lua:29 vim.cmd(action) is the single root cause for 8 of 10 bugs"
  - "M.global keymaps all pass — only M.lazy string actions are broken"
  - "BUG-018 to BUG-028 invalidated — colon-format works fine via apply.lua"
  - "Section D (LSP, snacks, folding, completion, format) all pass"
  - "Fix strategy: convert M.lazy string actions to Lua functions in registry.lua"

patterns_established:
  - "Stack trace lazy.lua:29 identifies all RC-01 victims"
  - "M.lazy vs M.global scope determines which execution path is used"

---

## Summary

**Plan:** 06-02 — Manual verification and CHECKLIST generation (redone 2026-04-21)

**Completed:** Interactive verification of all FAILURES.md entries + thorough CHECKLIST.md

**Verification Results:**

| Category | Count | Result |
|----------|-------|--------|
| Confirmed bugs (RC-01: lazy.lua:29) | 8 | BUG-005 to BUG-012 |
| Confirmed bugs (RC-02: gitsigns format) | 2 | BUG-012, BUG-015 |
| Invalidated (not bugs) | 12 | BUG-014, BUG-018 to BUG-028 |
| By Design | 2 | BUG-001, BUG-013 |
| Discovered non-crashing | 2 | BUG-016, BUG-017 |
| Feature tests passed | 10 | Section D all pass |

**Root Cause:** `core/keymaps/lazy.lua:29` calls `vim.cmd(map.action)` as fallback for string actions. Neovim 0.12+ `nvim_exec2()` rejects `<cmd>...<CR>` keymap notation and `":cmd<CR>"` colon strings passed as ex commands.

**Next:** Phase 7 (Keymap Reliability Fixes) — convert all M.lazy string actions to Lua functions in registry.lua.
