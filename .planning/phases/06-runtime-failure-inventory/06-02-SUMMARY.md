---
phase: 06-runtime-failure-inventory
plan: 02
subsystem: validation
tags: [keymaps, bugs, gitsigns, fzf-lua, registry]

# Dependency graph
requires:
  - phase: 06-runtime-failure-inventory-01
    provides: FAILURES.md with discovered failures
provides:
  - FAILURES.md updated with confirmed status
  - CHECKLIST.md with reproduction steps for 9 confirmed bugs

# Tech tracking
patterns:
  - Manual verification workflow for discovered failures
  - Keymap registry format issue (Neovim 0.12+ trailing characters)

key-files:
  created:
    - .planning/phases/06-runtime-failure-inventory/CHECKLIST.md
  modified:
    - .planning/phases/06-runtime-failure-inventory/FAILURES.md

key-decisions:
  - "BUG-001 neo-tree was already replaced by snacks in v1.0 - not a bug"
  - "14 TODO entries are feature tracking, not real bugs"
  - "Root cause: registry.lua actions use vim.cmd format invalid in 0.12+"

patterns-established:
  - "Manual verification adds human confirmation to automated discovery"
  - "CHECKLIST.md format: ID + repro steps + expected outcome + fix guidance"

---

## Summary

**Plan:** 06-02 — Manual verification and CHECKLIST generation

**Completed:** Human verification of FAILURES.md entries + CHECKLIST.md creation

**Key Findings:**

| Bug | Type | Root Cause |
|-----|------|------------|
| 9 keymap errors | Confirmed | `vim.cmd()` format strings with trailing chars invalid in 0.12+ |
| 1 gitsigns error | Confirmed | Wrong command format (colon vs capital G) |
| 1 fzf-lua | Confirmed | Missing `hidden = true` option |
| 1 neo-tree | Discovered | Already replaced by snacks in v1.0 |

**Verification Method:** Interactive Neovim session - pressed each keymap to reproduce errors.

**Next:** Phase 7 (Keymap Reliability Fixes) will fix BUG-005 through BUG-011 using CHECKLIST.md repro steps.