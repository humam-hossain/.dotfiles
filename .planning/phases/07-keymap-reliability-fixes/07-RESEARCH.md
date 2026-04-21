# Phase 7: Keymap Reliability Fixes - Research

**Researched:** 2026-04-22 [VERIFIED: session date]  
**Domain:** Neovim registry-driven keymap execution and lazy-loading correctness [VERIFIED: codebase grep]  
**Confidence:** MEDIUM [VERIFIED: codebase grep][CITED: https://lazy.folke.io/spec/lazy_loading][CITED: https://neovim.io/doc/user/lua-guide#lua-guide-mappings]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

- **BUG-017** — vim-tmux-navigator `<C-h/j/k/l>` conflict: deferred to Phase 8 (plugin runtime hardening). Non-crashing, Discovered status.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BUG-01 | User can invoke every documented shared keymap in milestone scope without Lua or runtime errors [VERIFIED: .planning/REQUIREMENTS.md] | Align registry storage with declared scope, remove `vim.cmd()`-based lazy string execution, convert Gitsigns lazy actions to Lua functions, and re-run the Phase 6 checklist for all confirmed keymaps [VERIFIED: codebase grep][VERIFIED: headless nvim probe][CITED: https://lazy.folke.io/spec/lazy_loading] |
</phase_requirements>

## Summary

The contradiction between `07-CONTEXT.md` and `06-runtime-failure-inventory/CHECKLIST.md` is real, but the codebase shows a third, more important issue: execution path is controlled by which Lua table a mapping is stored in, not by its `scope` field. `lazy.lua` only reads `registry.get_by_scope("lazy")`, and `get_by_scope("lazy")` returns the whole `M.lazy` table without filtering its members by `map.scope`, so mappings like `<leader>b`, `<leader>v`, `<leader>lw`, and `<leader>sn` are still compiled as lazy key specs even though each entry says `scope = "global"` in the registry. [VERIFIED: codebase grep][VERIFIED: headless nvim probe]

Because of that, “fix `lazy.lua` centrally” is necessary but “fix `lazy.lua` alone” is not a good plan boundary. A pure dispatcher heuristic would preserve the underlying registry inconsistency and keep custom string-parsing logic in a place where `lazy.nvim` already has first-class support for string or function key RHS values. The lower-risk direction is: 1. correct the registry/attachment mismatch so truly global mappings live in `M.global`; 2. simplify `lazy.lua` so it stops forcing string actions through `vim.cmd()`; 3. convert the two Gitsigns entries to direct Lua functions because the plugin already exposes stable Lua APIs and most lazy mappings already use Lua callbacks. [VERIFIED: codebase grep][CITED: https://lazy.folke.io/spec/lazy_loading][CITED: https://neovim.io/doc/user/lua-guide#lua-guide-mappings]

**Primary recommendation:** Plan Phase 7 as a hybrid fix: normalize misfiled “global” mappings in the registry, harden `lazy.lua` by preserving native keymap RHS semantics instead of emulating them with `vim.cmd()`, and convert the two Gitsigns mappings to explicit Lua functions. [VERIFIED: codebase grep][CITED: https://lazy.folke.io/spec/lazy_loading]

## Project Constraints (from AGENTS.md)

- One shared config must stay cross-platform; Phase 7 should avoid Linux-only command assumptions in keymap fixes. [VERIFIED: AGENTS.md]
- Keymaps must remain centrally managed; Phase 7 should repair the registry pipeline, not scatter ad hoc mappings into plugin files. [VERIFIED: AGENTS.md]
- Reliability fixes take priority over feature work; Phase 7 should target config-caused runtime failures only. [VERIFIED: AGENTS.md]
- This repo already uses modular Lua files and `lazy.nvim`; Phase 7 should preserve that structure. [VERIFIED: AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Global shared mappings (`<leader>b`, `<leader>v`, `<leader>lw`, `<leader>sn`) | Registry data layer | Startup installer | Their declared `scope = "global"` means they belong in the eager registry set and should be applied by `core.keymaps.apply`, not piggyback on plugin `keys`. [VERIFIED: codebase grep] |
| Lazy plugin-triggered mappings (`Snacks`, `ufo`, `gitsigns`) | Lazy key compiler | Plugin runtime | These mappings should be compiled into `lazy.nvim` key specs and let `lazy.nvim` handle loading/execution semantics. [VERIFIED: codebase grep][CITED: https://lazy.folke.io/spec/lazy_loading] |
| Runtime dispatch for string/function RHS | Neovim keymap engine | lazy.nvim `keys` spec | Neovim and `lazy.nvim` already support string or function RHS directly, so custom `vim.cmd()` dispatch is unnecessary for native mapping forms. [CITED: https://neovim.io/doc/user/lua-guide#lua-guide-mappings][CITED: https://lazy.folke.io/spec/lazy_loading] |
| Git-specific actions (`preview_hunk`, `toggle_current_line_blame`) | Registry action definition | Gitsigns API | These are best expressed as Lua callbacks because the rest of the registry already prefers direct plugin APIs over command strings. [VERIFIED: codebase grep] |
| Verification and triage | Phase 6 checklist/docs | Existing validation harness | The checklist already names the failing lhs sequences, and `scripts/nvim-validate.sh` covers startup/smoke regressions around the same runtime surface. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library / Runtime | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| Neovim | `0.12.1` [VERIFIED: terminal probe] | Executes the Lua config and keymap engine | This phase is specifically about Neovim keymap semantics and runtime behavior. [VERIFIED: terminal probe] |
| `folke/lazy.nvim` | commit `306a05526ada86a7b30af95c5cc81ffba93fef97` [VERIFIED: lazy-lock.json] | Plugin spec loading and `keys`-triggered lazy-loading | Official docs support string or function RHS directly in `keys` specs, which makes custom `vim.cmd()` dispatch unnecessary. [VERIFIED: lazy-lock.json][CITED: https://lazy.folke.io/spec/lazy_loading] |
| Registry keymap modules | repo-local [VERIFIED: codebase grep] | Central keymap declarations and application | This repo’s keymap control plane is already registry-driven, so fixes should preserve that pattern. [VERIFIED: codebase grep] |

### Supporting
| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `folke/snacks.nvim` | commit `0a4ce56b5e0c8c2bfa04a7b25c56c80baa3cf1b0` [VERIFIED: lazy-lock.json] | Hosts the plugin spec that currently consumes `core.keymaps.lazy.get_all_keys()` | Relevant because misfiled “global” mappings are currently hitchhiking on the Snacks plugin `keys` field. [VERIFIED: codebase grep] |
| `lewis6991/gitsigns.nvim` | commit `8d82c240f190fc33723d48c308ccc1ed8baad69d` [VERIFIED: lazy-lock.json] | Provides the two lazy mappings that still use command strings | Convert these two to Lua callbacks in Phase 7-01. [VERIFIED: codebase grep] |
| `kevinhwang91/nvim-ufo` | commit `ab3eb124062422d276fae49e0dd63b3ad1062cfc` [VERIFIED: lazy-lock.json] | Uses `lazy.fold_keys()` and therefore shares the same wrapper logic as `get_keys()` | Any `lazy.lua` cleanup must keep the fold-key path aligned with the main lazy-key path. [VERIFIED: codebase grep] |
| `scripts/nvim-validate.sh` | repo-local [VERIFIED: codebase grep] | Startup/sync/smoke/health validation harness | Use as regression coverage after keymap changes, but it does not execute the broken lhs flows directly. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom `vim.cmd()` / `feedkeys()` dispatcher | Native string/function RHS in `lazy.nvim` `keys` specs | Native `keys` specs remove heuristic parsing risk and match upstream behavior; a dispatcher is only justified if the registry insists on representing non-native action types. [CITED: https://lazy.folke.io/spec/lazy_loading][CITED: https://neovim.io/doc/user/api/#nvim_feedkeys()] |
| Leaving mislabeled entries inside `M.lazy` | Move them into `M.global` | Moving them fixes the real attachment bug and makes declared `scope` truthful; leaving them in `M.lazy` keeps the same footgun in place. [VERIFIED: codebase grep] |
| Command strings for Gitsigns | Explicit Lua callbacks | Lua callbacks are clearer, avoid command-string parsing, and match current registry style. [VERIFIED: codebase grep] |

**Installation:**  
No new external packages are required for Phase 7; the relevant runtime and plugins are already present in the repo or local Neovim environment. [VERIFIED: codebase grep][VERIFIED: terminal probe]

**Version verification:**  
Runtime version was verified with `nvim --version`, and plugin revisions were verified from `.config/nvim/lazy-lock.json`. [VERIFIED: terminal probe][VERIFIED: lazy-lock.json]

## Architecture Patterns

### System Architecture Diagram

```text
keypress
  |
  v
registry entry selected
  |
  +--> M.global table
  |      |
  |      v
  |   apply.lua -> vim.keymap.set(string|function) -> Neovim executes RHS
  |
  +--> M.lazy table
         |
         v
      lazy.lua -> plugin keys spec -> lazy.nvim loads plugin -> Neovim executes RHS
```

The current defect is that some entries labeled `scope = "global"` live inside `M.lazy`, so they follow the lazy path even though `apply.lua` is the intended eager path. [VERIFIED: codebase grep][VERIFIED: headless nvim probe]

### Recommended Project Structure

```text
.config/nvim/lua/core/keymaps/
├── registry.lua    # Data source of truth; table placement and scope must agree
├── apply.lua       # Eager/startup mapping installer
├── lazy.lua        # lazy.nvim key-spec compiler for true lazy mappings only
└── whichkey.lua    # Description/group registration
```

### Pattern 1: Table Placement Must Match Declared Scope
**What:** A mapping’s storage table (`M.global`, `M.lazy`, `M.buffer`, `M.plugin_local`) must agree with its `scope` metadata. [VERIFIED: codebase grep]  
**When to use:** Any time a mapping is added, moved, or reclassified. [VERIFIED: codebase grep]  
**Example:** `apply.lua` only applies `registry.get_by_scope("global")`, while `lazy.lua` only compiles `registry.get_by_scope("lazy")`; there is no fallback that re-checks `map.scope` on each entry. [VERIFIED: codebase grep]

### Pattern 2: Preserve Native RHS Semantics for Lazy Keys
**What:** When a lazy mapping action is already a valid string or function RHS, pass it through to `lazy.nvim` instead of executing it yourself inside a wrapper. [CITED: https://lazy.folke.io/spec/lazy_loading][CITED: https://neovim.io/doc/user/lua-guide#lua-guide-mappings]  
**When to use:** All ordinary plugin keymaps in Phase 7. [VERIFIED: codebase grep]  
**Example:**
```lua
-- Source: https://lazy.folke.io/spec/lazy_loading
{
  "<leader>ft",
  "<cmd>Neotree toggle<cr>",
  desc = "NeoTree",
}
```

### Pattern 3: Use Plugin APIs for Plugin-Specific Actions
**What:** Prefer `function() require("gitsigns").preview_hunk() end` over stringified `:Gitsigns ...<CR>` commands for registry actions. [VERIFIED: codebase grep]  
**When to use:** When the plugin exposes a direct Lua API and the registry already uses functions heavily. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid

- **`vim.cmd()` as a generic keymap dispatcher:** It misinterprets keymap notation like `<cmd>...<CR>` and `<C-w>v` because those are mapping RHS strings, not plain Ex commands. [VERIFIED: codebase grep][CITED: https://neovim.io/doc/user/lua-guide#lua-guide-mappings]
- **Scope-field drift:** Keeping `scope = "global"` entries inside `M.lazy` makes the registry misleading and causes planners to reason from incorrect metadata. [VERIFIED: codebase grep]
- **Duplicated lazy wrapper logic:** `get_keys()` and `fold_keys()` both embed the same custom dispatch logic, so any fix that only touches one path is incomplete. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Executing string RHS for lazy mappings | Custom `vim.cmd()` / `feedkeys()` parser heuristics | Native `lazy.nvim` key spec string RHS | Upstream already supports this behavior and matches Neovim mapping semantics. [CITED: https://lazy.folke.io/spec/lazy_loading][CITED: https://neovim.io/doc/user/lua-guide#lua-guide-mappings] |
| Plugin command bridges | Command-string shims for APIs that already exist | Direct Lua callbacks | Less parsing ambiguity, easier static review, and consistent with most existing lazy entries. [VERIFIED: codebase grep] |
| Scope resolution | Inferring behavior from a free-text `scope` field alone | Keep storage table and scope metadata aligned | Current bugs exist because metadata and actual storage diverged. [VERIFIED: codebase grep] |

**Key insight:** The real footgun is not just “string actions exist”; it is “a custom wrapper overrides native mapping semantics while the registry metadata no longer matches the actual attachment path.” [VERIFIED: codebase grep][CITED: https://lazy.folke.io/spec/lazy_loading]

## Common Pitfalls

### Pitfall 1: Fixing `lazy.lua` But Leaving Misfiled Global Entries In `M.lazy`
**What goes wrong:** The current confirmed bugs disappear, but the registry still lies about which installer owns each mapping. [VERIFIED: codebase grep]  
**Why it happens:** `get_by_scope("lazy")` returns the whole `M.lazy` table, and planners may assume the `scope` field is authoritative when it is not. [VERIFIED: codebase grep]  
**How to avoid:** Move the mislabeled entries into `M.global` or change the registry API to filter by per-entry `scope` consistently before planning further keymap work. [VERIFIED: codebase grep]  
**Warning signs:** `lazy.get_all_keys()` still contains `<leader>b`, `<leader>v`, `<leader>lw`, or `<leader>sn` after the fix. [VERIFIED: headless nvim probe]

### Pitfall 2: Replacing `vim.cmd()` With Another Heuristic Dispatcher
**What goes wrong:** The code gains new branches for `<...>` detection, but remains sensitive to untested RHS forms and duplicates upstream behavior. [CITED: https://neovim.io/doc/user/api/#nvim_feedkeys()][CITED: https://lazy.folke.io/spec/lazy_loading]  
**Why it happens:** The wrapper is trying to emulate `vim.keymap.set()` / `lazy.nvim` semantics manually. [CITED: https://neovim.io/doc/user/lua-guide#lua-guide-mappings]  
**How to avoid:** Prefer direct RHS pass-through for native string/function mappings; only use `feedkeys()` if a mapping must truly synthesize keystrokes at runtime. [CITED: https://neovim.io/doc/user/api/#nvim_feedkeys()]  
**Warning signs:** New code checks for angle brackets, `<CR>`, or colon prefixes just to decide how to run a mapping. [VERIFIED: codebase grep]

### Pitfall 3: Fixing `get_keys()` But Forgetting `fold_keys()`
**What goes wrong:** Normal lazy mappings are fixed, but `ufo` fold mappings continue using a stale wrapper path. [VERIFIED: codebase grep]  
**Why it happens:** `fold_keys()` duplicates the same dispatch structure rather than delegating to a shared builder. [VERIFIED: codebase grep]  
**How to avoid:** Refactor both paths through one key-spec builder or remove the wrapper logic from both places in the same commit. [VERIFIED: codebase grep]  
**Warning signs:** `lazy.lua` still has two separate `vim.cmd(map.action)` branches. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources:

### Native Lazy Key Spec With String RHS
```lua
-- Source: https://lazy.folke.io/spec/lazy_loading
keys = {
  { "<leader>ft", "<cmd>Neotree toggle<cr>", desc = "NeoTree" },
}
```

### Native Neovim Mapping With String Or Function RHS
```lua
-- Source: https://neovim.io/doc/user/lua-guide#lua-guide-mappings
vim.keymap.set('n', '<Leader>ex1', '<cmd>echo "Example 1"<cr>')
vim.keymap.set('n', '<Leader>pl1', require('plugin').action, { desc = 'Execute action from plugin' })
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom callback wraps every lazy key and sends string RHS through `vim.cmd()` | `lazy.nvim` `keys` specs accept string or function RHS directly | Current `lazy.nvim` docs, crawled 2026-04-22 [CITED: https://lazy.folke.io/spec/lazy_loading] | Phase 7 does not need to emulate keymap execution manually for native RHS forms. [CITED: https://lazy.folke.io/spec/lazy_loading] |
| Treating registry `scope` as descriptive metadata only | Keeping storage table and scope metadata aligned | Not yet done in this repo [VERIFIED: codebase grep] | Prevents planners and implementers from debugging the wrong execution path. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Blind `vim.cmd(map.action)` for lazy string actions: outdated for this repo’s mapping forms because it breaks valid keymap RHS strings and duplicates native keymap behavior. [VERIFIED: codebase grep][CITED: https://neovim.io/doc/user/lua-guide#lua-guide-mappings]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Moving the mislabeled “global” entries from `M.lazy` to `M.global` should not change user-facing availability because the current consumer plugin (`snacks.nvim`) is configured with `lazy = false` and therefore installs its `keys` at startup. [ASSUMED] | Summary / Plan direction | If wrong, some mappings might register later than before or stop appearing until plugin load. |

## Open Questions

1. **Should Phase 7 only normalize the registry, or also simplify `lazy.lua` in the same phase?**
   - What we know: The registry mismatch is the actual reason “global” mappings still hit the lazy wrapper, and `lazy.lua` is still an unsafe abstraction even after registry cleanup. [VERIFIED: codebase grep]
   - What's unclear: Whether the maintainer wants the smallest bug-fix diff or a slightly larger but cleaner control-plane fix. [ASSUMED]
   - Recommendation: Keep both in Phase 7-01, but split commits so registry normalization lands before lazy-wrapper cleanup. [VERIFIED: codebase grep]

2. **Is a separate `VALIDATION.md` phase artifact warranted?**
   - What we know: `workflow.nyquist_validation` is enabled, Phase 6 already produced a manual checklist, and Phase 10 is explicitly reserved for broader validation-harness expansion. [VERIFIED: .planning/config.json][VERIFIED: .planning/ROADMAP.md][VERIFIED: codebase grep]
   - What's unclear: Whether the team wants a dedicated validation artifact for every phase regardless of automation depth. [ASSUMED]
   - Recommendation: No separate `VALIDATION.md` file is warranted for Phase 7; include a Validation Architecture section in planning docs and reuse `CHECKLIST.md` plus `scripts/nvim-validate.sh`. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Neovim | Runtime probes and manual verification | ✓ [VERIFIED: terminal probe] | `0.12.1` [VERIFIED: terminal probe] | — |
| `git` | Repo inspection and validator assumptions | ✓ [VERIFIED: terminal probe] | `2.53.0` [VERIFIED: terminal probe] | — |
| `rg` | Fast code and mapping searches | ✓ [VERIFIED: terminal probe] | `15.1.0` [VERIFIED: terminal probe] | `grep` if unavailable later [ASSUMED] |
| `scripts/nvim-validate.sh` | Startup/smoke regression checks | ✓ [VERIFIED: codebase grep] | repo-local [VERIFIED: codebase grep] | Manual checklist from Phase 6 [VERIFIED: codebase grep] |

**Missing dependencies with no fallback:**  
None found for planning Phase 7. [VERIFIED: terminal probe][VERIFIED: codebase grep]

**Missing dependencies with fallback:**  
Sandboxed headless probes in this session hit a read-only ShaDa/state path, so scripted checks inside restricted environments may need temporary XDG state/data directories; manual Neovim repro remains a valid fallback. [VERIFIED: headless nvim probe][ASSUMED]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Shell-based headless validator + manual checklist [VERIFIED: codebase grep] |
| Config file | none; behavior is encoded in `scripts/nvim-validate.sh` [VERIFIED: codebase grep] |
| Quick run command | `./scripts/nvim-validate.sh startup && ./scripts/nvim-validate.sh smoke` [VERIFIED: codebase grep] |
| Full suite command | `./scripts/nvim-validate.sh all` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BUG-01 | Shared keymaps execute without runtime errors | manual repro + smoke | `./scripts/nvim-validate.sh startup && ./scripts/nvim-validate.sh smoke` plus Phase 6 checklist for `<leader>b`, `<leader>v`, `<leader>lw`, `<leader>sn`, `<leader>gp`, `<leader>gt`, `<leader>xs`, `<leader>h`, `<leader>se` [VERIFIED: codebase grep] | ✅ checklist exists; ❌ no dedicated scripted keypress audit yet [VERIFIED: codebase grep] |

### Sampling Rate
- **Per task commit:** `./scripts/nvim-validate.sh startup` [VERIFIED: codebase grep]
- **Per wave merge:** `./scripts/nvim-validate.sh smoke` plus relevant checklist steps [VERIFIED: codebase grep]
- **Phase gate:** Re-run all Phase 6 confirmed keymap repros and update `FAILURES.md` statuses inline. [VERIFIED: .planning/phases/07-keymap-reliability-fixes/07-CONTEXT.md]

### Wave 0 Gaps
- [ ] No automated regression currently presses the failing lhs sequences end-to-end; this remains manual for Phase 7. [VERIFIED: codebase grep]
- [ ] `FAILURES.md` and `CHECKLIST.md` currently describe several scope/global mappings as if they were ordinary `M.lazy` items without explaining that table membership, not `scope`, controls execution. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: codebase grep] | — |
| V3 Session Management | no [VERIFIED: codebase grep] | — |
| V4 Access Control | no [VERIFIED: codebase grep] | — |
| V5 Input Validation | yes [VERIFIED: codebase grep] | Keep key actions registry-owned and avoid runtime parsing heuristics for string commands. [VERIFIED: codebase grep] |
| V6 Cryptography | no [VERIFIED: codebase grep] | — |

### Known Threat Patterns for Neovim keymap config

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Executing unintended Ex commands from malformed string dispatch | Tampering | Use native keymap RHS handling or explicit Lua callbacks instead of generic `vim.cmd()` dispatch. [VERIFIED: codebase grep][CITED: https://neovim.io/doc/user/lua-guide#lua-guide-mappings] |
| Hidden control-plane drift between metadata and execution path | Integrity | Keep registry table placement aligned with `scope` and verify lazy/global counts after edits. [VERIFIED: codebase grep][VERIFIED: headless nvim probe] |

## Recommended Plan Split

### Plan 7-01 — Fix miswired registry ownership and execution helpers

- Move the 11 entries currently inside `M.lazy` but labeled `scope = "global"` into `M.global`: `buffer.new`, `buffer.close`, `window.split_vert`, `window.split_horiz`, `window.equalize`, `window.close_split`, `window.picker`, `toggle.line_wrap`, `save.format_and_write`, `save.no_format`, and `save.close_buffer`. [VERIFIED: codebase grep]
- Update `core/keymaps/lazy.lua` so true lazy mappings preserve native string/function RHS semantics instead of forcing strings through `vim.cmd()`. The cleanest version is to stop wrapping native RHS values and let `lazy.nvim` handle them directly. [CITED: https://lazy.folke.io/spec/lazy_loading][CITED: https://neovim.io/doc/user/lua-guide#lua-guide-mappings]
- Refactor `fold_keys()` with the same builder or behavior as `get_keys()` so there is only one lazy key compilation path. [VERIFIED: codebase grep]
- Convert `git.preview_hunk` and `git.toggle_blame` to direct Lua callbacks in `registry.lua`. [VERIFIED: codebase grep]

**Files to modify:** `.config/nvim/lua/core/keymaps/registry.lua`, `.config/nvim/lua/core/keymaps/lazy.lua`, and likely `.planning/phases/06-runtime-failure-inventory/FAILURES.md` after fixes land. [VERIFIED: codebase grep]

### Plan 7-02 — Re-verify runtime behavior and correct docs

- Re-run the confirmed BUG-005 to BUG-012 and BUG-015 checklist steps. [VERIFIED: codebase grep]
- Update `FAILURES.md` statuses to `Fixed` and correct the root-cause wording so it explains the table-membership/scope mismatch explicitly. [VERIFIED: codebase grep]
- Update any keymap docs only if user-facing behavior or availability timing changed after moving entries to `M.global`. [ASSUMED]

**Files to modify:** `.planning/phases/06-runtime-failure-inventory/FAILURES.md`, `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md`, and mapping docs only if descriptions or behavior changed. [VERIFIED: codebase grep]

## Sources

### Primary (HIGH confidence)
- Codebase inspection: `.config/nvim/lua/core/keymaps/lazy.lua`, `.config/nvim/lua/core/keymaps/registry.lua`, `.config/nvim/lua/core/keymaps/apply.lua`, `.config/nvim/lua/plugins/snacks.lua`, `.config/nvim/lua/plugins/ufo.lua`, `.config/nvim/lazy-lock.json` - verified actual execution path, table membership mismatch, and current plugin revisions. [VERIFIED: codebase grep]
- Headless Neovim probes run on 2026-04-22 - verified `nvim` version, lazy/global key counts, and that `lazy.get_all_keys()` currently contains `<leader>b`, `<leader>v`, `<leader>lw`, and `<leader>sn`. [VERIFIED: headless nvim probe]
- `lazy.nvim` docs: https://lazy.folke.io/spec/lazy_loading - verified that `keys` specs accept string or function RHS and load plugins on first execution. [CITED: https://lazy.folke.io/spec/lazy_loading]
- Neovim Lua guide: https://neovim.io/doc/user/lua-guide#lua-guide-mappings - verified that `vim.keymap.set()` accepts string or function RHS. [CITED: https://neovim.io/doc/user/lua-guide#lua-guide-mappings]

### Secondary (MEDIUM confidence)
- Neovim API docs: https://neovim.io/doc/user/api/#nvim_feedkeys() - verified correct `nvim_feedkeys()` / `nvim_replace_termcodes()` usage, used here mainly to evaluate the proposed dispatcher alternative. [CITED: https://neovim.io/doc/user/api/#nvim_feedkeys()]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - runtime and plugin revisions were verified locally and the key `lazy.nvim` / Neovim semantics were confirmed from official docs. [VERIFIED: terminal probe][VERIFIED: lazy-lock.json][CITED: https://lazy.folke.io/spec/lazy_loading]
- Architecture: HIGH - the actual attachment path was verified from code and a headless Neovim probe. [VERIFIED: codebase grep][VERIFIED: headless nvim probe]
- Pitfalls: MEDIUM - the current failure mode is verified, but the exact user-visible timing impact of moving entries from `M.lazy` to `M.global` is still an assumption until implemented. [VERIFIED: codebase grep][ASSUMED]

**Research date:** 2026-04-22 [VERIFIED: session date]  
**Valid until:** 2026-05-22 for repo-local architecture; re-check sooner if registry layout changes. [ASSUMED]
