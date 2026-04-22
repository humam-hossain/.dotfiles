---
phase: "08-plugin-runtime-hardening"
plan: "03"
subsystem: "nvim-config"
tags: ["verification", "regression-checklist", "tmux-navigation", "bug-inventory", "phase-8"]
dependency_graph:
  requires:
    - "08-01: registry conflict removed, health validator clean, BUG-016 fixed"
    - "08-02: crash-prone flow guards in place"
  provides:
    - "CHECKLIST.md with Phase 8 workflow matrix (W-01 to W-16) and BUG-017 ownership evidence"
    - "FAILURES.md with BUG-017 Neovim-side Fixed, BUG-019 environment gap, and BUG-020 Linux external-open gap"
    - "Written evidence that 13 of 15 core workflows pass interactively after Phase 8 fixes"
    - "Precise gap record for .tmux.conf companion bindings (BUG-019) and Linux external-open (BUG-020) routable to follow-up"
  affects:
    - "Future phases: BUG-019 is a clean, bounded follow-up target for .tmux.conf configuration"
    - "Future phases: BUG-020 Linux external-open needs root cause investigation (xdg-open, vim.ui.open, key binding)"
tech_stack:
  added: []
  patterns:
    - "Split bug disposition: Neovim-side fix confirmed separately from environment-side gap"
    - "Verbatim :verbose nmap evidence preserved in CHECKLIST.md as regression anchor"
key_files:
  created: []
  modified:
    - ".planning/phases/06-runtime-failure-inventory/CHECKLIST.md"
    - ".planning/phases/06-runtime-failure-inventory/FAILURES.md"
decisions:
  - "BUG-017 closed as Fixed (Neovim side) — vim-tmux-navigator owns <C-h/j/k/l> confirmed via :verbose nmap"
  - "BUG-019 opened as environment gap — .tmux.conf companion bindings absent; not a Neovim config defect"
  - "Cross-pane traversal failure classified as environment gap, not Phase 8 regression, based on ownership evidence"
metrics:
  duration_minutes: 20
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
  completed_date: "2026-04-22"
---

# Phase 8 Plan 03: Plugin Runtime Hardening — Interactive Verification Summary

**One-liner:** Ran headless and interactive verification of all Phase 8 milestone workflows; confirmed 13 of 15 pass; split BUG-017 into Neovim-side Fixed and BUG-019 environment gap; Linux external-open fails on Linux with root cause unclear (tracked as BUG-020); Windows external-open deferred.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Re-run headless validation and update inventory | (prior session) | FAILURES.md |
| 2 | Interactive workflow verification and gap recording | f09fe5e | CHECKLIST.md, FAILURES.md |

## What Was Verified

### Task 1: Headless Validation (prior to checkpoint)

Both automated validators confirmed clean baseline after Phase 8-01 and 08-02 fixes:

| Check | Result |
|-------|--------|
| `./scripts/nvim-validate.sh startup` | PASS — no Error/E5108/E484/stack traceback |
| `./scripts/nvim-validate.sh health` — plugins | PASS — all 11 plugins loaded=true |
| `./scripts/nvim-validate.sh health` — tools | PASS — all 14 tools available |
| `./scripts/nvim-validate.sh health` — lazy | PASS — 28 loaded / 34 installed, 0 problems |

One residual warning (`vim.lsp.buf_get_clients()` from `project.nvim`) classified as environment noise — third-party plugin calling a deprecated upstream API. No config defect.

### Task 2: Interactive Workflow Matrix

All workflows from the D-15 matrix verified interactively. Results recorded in CHECKLIST.md (W-01 to W-15):

| Workflow Category | Items | Result |
|-------------------|-------|--------|
| Snacks search (file find, live grep, buffer picker) | W-01 to W-03 | PASS |
| Snacks explorer (open, close, navigate) | W-04 | PASS |
| Git workflow (gitsigns preview/blame, lazygit) | W-05 to W-07 | PASS |
| LSP workflow (definition, hover, diagnostics, format) | W-08 to W-09 | PASS |
| UI surfaces (which-key, notifications, statusline/folds) | W-10 to W-12 | PASS |
| Linux external-open (`<C-S-o>`) | W-13 | FAIL — does not open externally; root cause unclear (xdg-open, vim.ui.open, key binding); tracked as BUG-020 |
| Tmux-navigation — Neovim splits (outside tmux) | W-14 | PASS |
| Tmux-navigation — cross-pane traversal (inside tmux) | W-15 | FAIL — environment gap (BUG-019) |
| Windows external-open (`<C-S-o>`) | W-16 | DEFERRED — no Windows machine available |

### BUG-017 Split Finding — The Key Outcome

**`:verbose nmap <C-h>` evidence (verbatim):**
```
n  <C-H>       * :<C-U>TmuxNavigateLeft<CR>
        Last set from ~/.local/share/nvim/lazy/vim-tmux-navigator/plugin/tmux_navigator.vim line 18
```

This confirms the Phase 8-01 fix (removing `window.move_*` globals from `registry.lua`) is fully effective. `vim-tmux-navigator` is the sole owner of `<C-h/j/k/l>` in Neovim. No registry shadowing remains.

Cross-pane traversal failure has a different root cause: `.tmux.conf` is missing the `bind-key -n C-h/j/k/l` companion entries that the plugin requires on the tmux side. Without these, tmux does not intercept `<C-h/j/k/l>` and pass them to the navigator script when Neovim is the focused pane. Neovim-internal split movement works correctly (W-14 PASS) because that path never touches tmux.

**Disposition:**
- BUG-017: **Fixed** (Neovim side) — registry conflict resolved, ownership confirmed
- BUG-019: **Open** (environment gap) — `.tmux.conf` companion bindings required

## Deviations from Plan

### Auto-fixed Issues

None.

### Scope Decisions

**BUG-019 created instead of marking BUG-017 fully closed:**
- Plan instruction: "mark BUG-017 fixed only after Task 2 records `:verbose nmap` ownership and tmux-pane traversal outcomes"
- Outcome: `:verbose nmap` ownership confirmed (Neovim side Fixed). Interactive tmux-pane traversal failed, but failure root cause is environment-only (`.tmux.conf`), not a regression in Neovim config or Phase 8 work.
- Decision: Split disposition — BUG-017 marked Fixed (Neovim side), BUG-019 opened for `.tmux.conf` gap. This accurately represents what was fixed vs. what remains, without conflating two separate problems.

**Linux external-open (W-13) corrected to FAIL after post-checkpoint user verification:**
- The plan expected `<C-S-o>` to open externally or report the real OS error string.
- Post-checkpoint user verification confirmed it does not open externally on Linux.
- The Phase 8-02 `core/open.lua` hardening (direct tuple capture, real errmsg surfacing) is correct and retained.
- The failure is in the underlying open mechanism — root cause unclear: xdg-open missing/misconfigured, `vim.ui.open()` unavailable on this Neovim build, or terminal stripping `<C-S-o>`.
- Tracked as BUG-020 for follow-up investigation in a future phase.

**Windows external-open (W-16) not verified:**
- No Windows machine was available. This item is DEFERRED rather than marked PASS without evidence.

## Known Stubs

None. All changes are documentation updates grounded in actual verification evidence.

## Threat Flags

No new security-relevant surface introduced. Documentation-only plan.

## Self-Check: PASSED

**Files exist:**
- `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` — FOUND
- `.planning/phases/06-runtime-failure-inventory/FAILURES.md` — FOUND

**Commits exist:**
- f09fe5e (Task 2 regression results — prior session) — FOUND
- e11da02 (W-13 correction + BUG-020 — post-checkpoint) — FOUND

**Acceptance criteria verified:**
- CHECKLIST.md contains explicit Phase 8 regression steps/results for all workflow categories — PASS
- BUG-017 `:verbose nmap` ownership evidence recorded in CHECKLIST.md — PASS
- FAILURES.md and CHECKLIST.md agree on BUG-017 (Neovim-side Fixed), BUG-019 (Open, environment gap), and BUG-020 (Open, needs investigation) — PASS
- `./scripts/nvim-validate.sh startup` passes after documentation updates — PASS
- Linux external-open W-13 correctly recorded as FAIL with BUG-020 tracking — PASS
- Windows external-open W-16 correctly recorded as DEFERRED — PASS
