# Phase 7: Keymap Reliability Fixes - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the 10 Confirmed keymap bugs from the Phase 6 inventory (BUG-005 to BUG-012, BUG-015). All are `M.lazy` string actions routed through `lazy.lua:29` → `vim.cmd()` which rejects keymap notation strings under Neovim 0.12. Fix the dispatch logic centrally in `lazy.lua` and convert the two Gitsigns entries to direct Lua function calls. Update FAILURES.md status per entry as fixes land.

Phase 7 does NOT address BUG-017 (vim-tmux-navigator conflict) — deferred to Phase 8 (plugin runtime). No new scripts required for verification — manual repro via CHECKLIST.md steps is sufficient.

</domain>

<decisions>
## Implementation Decisions

### RC-01 Fix Strategy (BUG-005 to BUG-011)

- **D-01:** Fix `lazy.lua:29` centrally — replace `vim.cmd(map.action)` with a dispatcher that distinguishes string types
- **D-02:** Dispatcher logic: if action string contains angle-bracket sequences (`<...>`) → route through `vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(action, true, false, true), "n", false)`. Otherwise → `vim.cmd(action)`. This handles all confirmed broken patterns: `<cmd>...<CR>`, `<C-w>X`, `":close<CR>"`
- **D-03:** feedkeys mode flag and exact `nvim_replace_termcodes` parameters are Claude's discretion — use whatever is correct for normal-mode keymap execution
- **D-04:** Add a short comment near the dispatcher in `lazy.lua` explaining why string actions split between feedkeys and vim.cmd — prevents the same footgun from being re-introduced

### RC-02 Fix Strategy (BUG-012, BUG-015 — Gitsigns)

- **D-05:** Convert Gitsigns entries to direct Lua function calls: `function() require("gitsigns").preview_hunk() end` and `function() require("gitsigns").toggle_current_line_blame() end` — these are wrong-format strings regardless of dispatch method, so they become functions, not strings
- **D-06:** These two entries are NOT routed through the string dispatcher — they are function-valued actions in the registry

### BUG-017 Scope

- **D-07:** BUG-017 (vim-tmux-navigator `<C-h/j/k/l>` conflict) deferred to Phase 8. It is Discovered/non-crashing and is a plugin interaction concern, not a keymap config error. Phase 7 stays focused on the 10 Confirmed crashes-on-use bugs.

### Verification

- **D-08:** Verification method: manual repro using the numbered steps in `CHECKLIST.md`. Developer triggers each `lhs`, verifies no E488/error. No new script required.
- **D-09:** FAILURES.md entries updated to `Fixed` status inline as each bug is fixed — consistent with Phase 6 D-12 (FAILURES.md is a living doc). Phases 8-9 readers will see accurate status.

### Claude's Discretion

- Exact `nvim_replace_termcodes` parameters and feedkeys mode string
- Whether to add a type annotation or `@type` comment to the `M.lazy` action field in registry.lua
- Order of fix commits within plan 7-01

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and inventory
- `.planning/ROADMAP.md` — Phase 7 goal, requirements BUG-01, plan structure
- `.planning/REQUIREMENTS.md` — BUG-01 acceptance criteria
- `.planning/PROJECT.md` — v1.1 milestone goals and constraints

### Failure inventory (primary source of truth for fix targets)
- `.planning/phases/06-runtime-failure-inventory/FAILURES.md` — full inventory with root cause summary (RC-01, RC-02), confirmed bug details, and suggested fixes per entry
- `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` — numbered repro steps for each Confirmed bug; used for verification in plan 7-02

### Files being modified
- `.config/nvim/lua/core/keymaps/lazy.lua` — dispatcher at line 29 (the RC-01 fix site)
- `.config/nvim/lua/core/keymaps/registry.lua` — BUG-012, BUG-015 Gitsigns entries (RC-02 fix site)

### Prior phase context
- `.planning/phases/06-runtime-failure-inventory/06-CONTEXT.md` — Phase 6 decisions, especially D-12 (FAILURES.md living doc) and D-13 (keymap failure ownership)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/nvim-validate.sh` — existing validator for startup/sync/smoke/health; can be run post-fix to confirm no regressions introduced
- `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` — repro steps ready to use as the verification checklist for plan 7-02

### Established Patterns
- `lazy.lua` already wraps `mod[map.action]()` for function-valued actions and `map.action()` for direct functions — the string branch (`else vim.cmd(map.action)`) is the only broken path
- `apply.lua` → `vim.keymap.set()` handles string RHS correctly (M.global entries work fine) — this confirms `vim.keymap.set()` is not the problem; `lazy.lua` is the isolated fix point
- `require("gitsigns").fn()` pattern is the correct gitsigns invocation (no command-format string)

### Integration Points
- `lazy.lua` is consumed by plugin specs via `M.get_keys(domain)` — fixing `lazy.lua:29` propagates to all plugin lazy-load key specs automatically
- FAILURES.md in `.planning/phases/06-runtime-failure-inventory/` must be updated to `Fixed` as bugs are resolved — downstream phases (8, 9) read it

</code_context>

<specifics>
## Specific Ideas

- Dispatcher pattern-detect heuristic: `string.find(action, "[<>]")` or `action:match("<[^>]+>")` — identifies all confirmed broken strings (`<cmd>`, `<C-w>`, `<CR>` embedded in string)
- Comment tone should be directive, not explanatory prose: e.g., `-- keymap notation (e.g. <cmd>...<CR>) must go through feedkeys, not vim.cmd`
- FAILURES.md status update: change `**Confirmed**` → `**Fixed**` per entry as plan 7-01 commits land; plan 7-02 can do a final sweep

</specifics>

<deferred>
## Deferred Ideas

- **BUG-017** — vim-tmux-navigator `<C-h/j/k/l>` conflict: deferred to Phase 8 (plugin runtime hardening). Non-crashing, Discovered status.

</deferred>

---

*Phase: 07-keymap-reliability-fixes*
*Context gathered: 2026-04-22*
