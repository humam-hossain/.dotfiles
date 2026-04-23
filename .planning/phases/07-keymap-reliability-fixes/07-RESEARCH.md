---
phase: 07
slug: keymap-reliability-fixes
status: ready
created: 2026-04-22
---

# Phase 07 — Research

## Goal

Plan Phase 7 so `BUG-01` is actually closed: every documented shared keymap in v1.1 scope must execute without config-caused Lua/runtime errors.

---

## What Repo Evidence Says

### 1. Phase context is partly stale, but not in the obvious way

`07-CONTEXT.md` says the main fix is central dispatcher logic in `lua/core/keymaps/lazy.lua`. My first read suggested that was wrong because several confirmed failures are labeled `scope = "global"` in `registry.lua`. Deeper code reading shows the real issue is table membership, not the `scope` field alone:

- `registry.get_by_scope("lazy")` returns the full `M.lazy` table.
- `M.lazy` currently contains several entries labeled `scope = "global"`, including:
  - `<leader>b` → `<cmd> enew <CR>`
  - `<leader>v` → `<C-w>v`
  - `<leader>h` → `<C-w>s`
  - `<leader>se` → `<C-w>=`
  - `<leader>xs` → `:close<CR>`
  - `<leader>lw` → `<cmd>set wrap!<CR>`
  - `<leader>sn` → `<cmd>noautocmd w <CR>`
- Those entries therefore do flow through `lazy.lua` today, even though their metadata says `global`.
- `apply.lua` only sees items that actually live in `M.global`.

Result: changing `lazy.lua` alone is still insufficient, but `lazy.lua` is part of the real fix because misfiled shared mappings currently route through it.

### 2. Current inventory/checklist is directionally right, but fix shape should be hybrid

`FAILURES.md` and `CHECKLIST.md` correctly separate two classes:

- RC-01: registry string actions that are semantically fragile or invalid in their current form
- RC-02: Gitsigns `:Gitsigns ...<CR>` strings in lazy mappings, which are wrong-format actions and should be functions

`CHECKLIST.md` explicitly recommends converting broken actions to direct Lua behavior instead of trying to preserve key-notation strings. That matches current code structure better, but the plan should also normalize the registry layout:

- move mislabeled shared mappings out of `M.lazy` and into `M.global`
- `apply.lua` already accepts function-valued `action`
- `lazy.lua` should stop forcing arbitrary string actions through `vim.cmd(map.action)`
- direct Lua/ex-command callbacks are clearer and easier to verify than mixed key-notation strings

### 3. There is also an attachment-helper wiring bug still live

`lua/core/keymaps/attach.lua` uses `registry.get_by_scope("plugin_local")`, but project docs/history consistently use `plugin-local`.

Implications:

- `apply_neotree()` and `get_plugin_local_maps()` currently read the wrong scope string
- this is a registry/helper safety issue even if it is not one of the Phase 6 confirmed crash repros
- roadmap wording for 7-01 ("registry and attachment helpers") supports fixing this now, because it affects whether registry-driven mappings can execute through helper paths safely

This is a good secondary task in Plan 7-01, but not the main BUG-01 closure path.

---

## File-Level Conclusions

### Primary fix files

- `.config/nvim/lua/core/keymaps/registry.lua`
  - move misfiled shared mappings from `M.lazy` into `M.global`
  - convert confirmed broken registry entries from strings to explicit Lua functions/ex commands
  - convert Gitsigns lazy actions to direct `require("gitsigns").…()` callbacks
- `.config/nvim/lua/core/keymaps/lazy.lua`
  - remove `vim.cmd(map.action)` fallback for arbitrary string actions
  - let lazy key specs execute through native RHS semantics or explicit callbacks

### Secondary safety file

- `.config/nvim/lua/core/keymaps/attach.lua`
  - normalize `"plugin_local"` → `"plugin-local"` if registry still uses hyphenated scope
  - confirm helper behavior aligns with registry terminology and README docs

### Verification/doc files

- `.planning/phases/06-runtime-failure-inventory/FAILURES.md`
  - update BUG-005..BUG-012 and BUG-015 status from Confirmed to Fixed as work lands
- `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md`
  - turn repro checklist into regression checklist by recording expected fixed behavior
- `.config/nvim/README.md`
  - update only if user-visible keymap behavior/wording changed or if helper terminology is wrong

---

## Recommended Planning Split

### 7-01 — Repair registry/helper execution paths

Scope:

- move mislabeled shared mappings from `M.lazy` into `M.global`
- simplify `lazy.lua` so it no longer forces string actions through `vim.cmd()`
- convert all confirmed broken shared keymaps in `registry.lua` to safe function actions
- convert two Gitsigns lazy actions to direct Lua callbacks
- fix `attach.lua` scope-name mismatch if repo still uses hyphenated `plugin-local`

Why separate:

- this is the code-changing plan
- it should keep write scope tight and verification easy

### 7-02 — Re-verify shared keymaps and docs

Scope:

- rerun targeted checklist for BUG-005..BUG-012 and BUG-015
- run headless harness to catch startup/smoke regressions
- update `FAILURES.md`, `CHECKLIST.md`, and README wording only if behavior/terminology changed

Why separate:

- roadmap already expects a distinct verification/doc pass
- manual keymap confirmation belongs after code changes, not mixed into the fix plan

---

## Concrete Implementation Guidance

### Prefer explicit callbacks over string heuristics

Best path for this repo:

- `"<cmd> enew <CR>"` → `function() vim.cmd("enew") end`
- `"<C-w>v"` → `function() vim.cmd("vsplit") end`
- `"<C-w>s"` → `function() vim.cmd("split") end`
- `"<C-w>="` → `function() vim.cmd("wincmd =") end`
- `":close<CR>"` → `function() vim.cmd("close") end`
- `"<cmd>set wrap!<CR>"` → `function() vim.wo.wrap = not vim.wo.wrap end`
- `"<cmd>noautocmd w <CR>"` → `function() vim.cmd("noautocmd w") end`
- `":Gitsigns preview_hunk<CR>"` → `function() require("gitsigns").preview_hunk() end`
- `":Gitsigns toggle_current_line_blame<CR>"` → `function() require("gitsigns").toggle_current_line_blame() end`

Why:

- aligns with current `apply.lua` and `lazy.lua` behavior
- avoids brittle string-dispatch heuristics
- makes future static audits easier

### Normalize table membership at same time

Best path is not "functions only" or "dispatcher only". It is:

1. Move shared mappings that should be eager/startup-owned into `M.global`.
2. Keep truly lazy/plugin-trigger mappings in `M.lazy`.
3. Convert the confirmed broken actions to explicit callbacks.
4. Remove `lazy.lua`'s `vim.cmd(map.action)` fallback so future string notation does not silently become an ex-command bug.

### Do not broaden scope into tmux-nav/runtime plugin issues

Keep Phase 7 out of:

- BUG-017 tmux navigator conflict
- plugin load/runtime crashes outside shared keymap execution
- new scripted regression harness work beyond targeted use of existing `nvim-validate.sh`

Those belong to later phases.

---

## Risks

| Risk | Why it matters | Mitigation |
|------|----------------|------------|
| Moving mappings between `M.lazy` and `M.global` changes load timing | shared mappings may currently rely on lazy key spec path by accident | move only the confirmed shared mappings and rerun manual keypress + harness checks |
| Changing registry action type regresses apply/lazy helpers | registry supports both string and function paths | keep edits limited to known broken entries; verify startup + smoke |
| Simplifying `lazy.lua` breaks valid lazy mappings | lazy wrappers currently assume string fallback exists | keep plugin-trigger mappings on functions/native RHS and verify snacks/gitsigns/ufo smoke paths |
| Helper scope fix changes neo-tree/plugin-local behavior | attach helper is already miswired | limit change to scope token normalization and verify no new global key drift |
| Docs drift from actual behavior | README already contains some stale wording from earlier phases | only update exact sections tied to fixed/shared keymaps or helper terminology |

---

## Validation Architecture

Phase 7 does not need new framework/test infrastructure. Existing validation surface is enough:

- Quick command: `./scripts/nvim-validate.sh startup`
- Full command: `./scripts/nvim-validate.sh all`
- Manual regression set: Phase 6 `CHECKLIST.md` steps for BUG-005..BUG-012 and BUG-015

Nyquist implication: create `07-VALIDATION.md` with a per-task map that combines headless harness checks plus explicit manual keymap verification.

---

## Planning Implications

Planner should encode these facts explicitly:

1. Main fix is hybrid: normalize `registry.lua` table membership and simplify `lazy.lua`; do not treat either file as sufficient alone.
2. Gitsigns lazy actions must become functions.
3. `attach.lua` scope mismatch is a valid helper-hardening task in 7-01.
4. Verification must include both:
   - automated harness (`startup`, `smoke`, ideally `all`)
   - manual keypress regression for every confirmed BUG-01 keymap
5. `FAILURES.md` / `CHECKLIST.md` are living docs and should be updated during verification.

## RESEARCH COMPLETE
