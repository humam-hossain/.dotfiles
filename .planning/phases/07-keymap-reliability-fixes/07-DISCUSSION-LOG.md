# Phase 7: Keymap Reliability Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-22
**Phase:** 07-keymap-reliability-fixes
**Areas discussed:** RC-01 fix strategy, BUG-017 scope, Verification method

---

## RC-01 Fix Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Fix lazy.lua:29 centrally | Pattern-detect `<...>` → feedkeys, else vim.cmd. One change closes all 8 bugs. | ✓ |
| Convert each action to Lua function | Update 8 registry.lua entries individually. Explicit but leaves lazy.lua:29 as footgun. | |
| Both | Fix lazy.lua + convert registry entries. Belt-and-suspenders. | |

**User's choice:** Fix lazy.lua:29 centrally

---

### RC-01 dispatcher detail

| Option | Description | Selected |
|--------|-------------|----------|
| Pattern-detect: `<...>` → feedkeys, else vim.cmd | Angle-bracket detection routes keymap notation through nvim_feedkeys. | ✓ |
| Always use feedkeys | Uniform dispatch for all string actions. Simpler logic. | |
| You decide | Claude picks. | |

**User's choice:** Pattern-detect: `<...>` → feedkeys, else vim.cmd

---

### RC-02 Gitsigns fix (BUG-012, BUG-015)

| Option | Description | Selected |
|--------|-------------|----------|
| Convert to `function() require('gitsigns').fn() end` | Direct Lua API call. Correct regardless of dispatch method. | ✓ |
| Fix string format and let feedkeys handle | Rewrite as `:Gitsigns cmd` (no `<CR>`), rely on dispatcher. | |
| You decide | Claude picks. | |

**User's choice:** Convert to `function() require('gitsigns').fn() end`

---

### Guard comment in lazy.lua

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — add short comment | One-line comment near dispatcher. Prevents re-introduction of the bug. | ✓ |
| No — code is self-explanatory | Skip comment. | |
| You decide | Claude decides. | |

**User's choice:** Yes — add a short comment in lazy.lua

---

## BUG-017 Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Defer to Phase 8 | Plugin interaction, not a keymap config error. Phase 8 owns plugin runtime. | ✓ |
| Include in Phase 7 | Keymap domain argument. Resolve registry vs tmux-nav conflict here. | |
| Note it, no fix | Document conflict in FAILURES.md, no ownership yet. | |

**User's choice:** Defer to Phase 8

---

## Verification Method

| Option | Description | Selected |
|--------|-------------|----------|
| Manual repro using CHECKLIST.md steps | FAILURES.md repro steps per entry. Developer triggers each lhs, verifies no error. | ✓ |
| Write a targeted headless script | New script exercises each fixed lhs headlessly, checks for E488. | |
| Both: manual + update nvim-validate.sh | Manual verification + add coverage to existing validator. | |

**User's choice:** Manual repro using CHECKLIST.md steps

---

### FAILURES.md update cadence

| Option | Description | Selected |
|--------|-------------|----------|
| Update to Fixed inline as bugs are fixed | Per-entry update as fixes land. Keeps inventory accurate for Phases 8-9. | ✓ |
| Leave as Confirmed, update at milestone end | Batch update. Less churn during active work. | |
| You decide | Claude picks. | |

**User's choice:** Update to Fixed inline as bugs are fixed

---

## Claude's Discretion

- feedkeys mode flag and `nvim_replace_termcodes` exact parameters
- Whether to add type annotation to `M.lazy` action field in registry.lua
- Order of fix commits within plan 7-01

## Deferred Ideas

- BUG-017 (vim-tmux-navigator conflict) — deferred to Phase 8
