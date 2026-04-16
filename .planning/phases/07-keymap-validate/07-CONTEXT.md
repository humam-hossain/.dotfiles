# Phase 7: Validate Keymap Requirements - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Verify KEY-01, KEY-02, KEY-03 satisfied through existing Phase 2 plans. Update 02-VERIFICATION.md with current evidence. Fix any gaps found during fresh scan.
</domain>

<decisions>
## Implementation Decisions

### Gap Action
- **D-01:** Fix gaps immediately — add `keys={}` to `snacks.lua` to wire search/codelsp keys from registry; remove duplicate `<leader>th` from `lsp.lua`

### KEY-01 Gap Fix
- **D-02:** Add `keys={}` to `snacks.lua` from `core.keymaps.lazy.get_all_keys()` (excludes fold-only entries)
- **D-03:** `snacks.nvim` must be the lazy.nvim key trigger for all search/codelsp picker keys
- **D-04:** Keep `fold_keys()` wired through `ufo.lua` as-is (already working)

### KEY-03 Gap Fix
- **D-05:** Remove `vim.keymap.set("n", "<leader>th", ...)` from `lsp.lua:121`
- **D-06:** The registry's `lsp.toggle_inlay` (buffer scope, `attach: "LspAttach"`) via `attach.apply_lsp()` is the sole source

### Domain Taxonomy (KEY-02)
- **D-07:** Minor: `explorer.git_status` has `domain = "g"` — should be `"e"` (explorer). Not blocking, noted for cleanup.

### Verification Update
- **D-08:** Update 02-VERIFICATION.md with fresh evidence from current codebase scan
- **D-09:** Health check: run `nvim-validate.sh` to confirm no regressions from fixes

### Scope Boundaries
- **D-10:** Phase 7 handles keymap gap fixes only. UX-02 rollout docs verified separately in Phase 8.
- **D-11:** snacks.nvim replaces fzf-lua — `fzflua.lua` removed in Phase 5. Registry references `Snacks.picker.*` correctly.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Keymap Architecture
- `.config/nvim/lua/core/keymaps/registry.lua` — Central registry with 4 scopes
- `.config/nvim/lua/core/keymaps/lazy.lua` — `get_keys()`, `get_all_keys()` for lazy.nvim key specs
- `.config/nvim/lua/core/keymaps/attach.lua` — `apply_lsp()` for buffer-local LSP maps
- `.config/nvim/lua/core/keymaps/apply.lua` — `apply_global()` for startup keymaps

### Plugin Keymap Wiring
- `.config/nvim/lua/plugins/snacks.lua` — Needs `keys={}` added
- `.config/nvim/lua/plugins/lsp.lua` — Has duplicate `<leader>th` to remove
- `.config/nvim/lua/plugins/ufo.lua` — Uses `lazy.fold_keys()` (working)
- `.config/nvim/lua/plugins/neotree.lua` — Uses `lazy.explorer_keys()` (working)

### Phase 2 Context
- `.planning/milestones/v1.0-phases/02-central-command-and-keymap-architecture/02-CONTEXT.md` — KEY-01/02/03 decisions
- `.planning/milestones/v1.0-phases/02-central-command-and-keymap-architecture/02-KEYMAP-INVENTORY.md` — Keymap registry inventory
- `.planning/milestones/v1.0-phases/02-central-command-and-keymap-architecture/02-VERIFICATION.md` — Existing verification (needs update)

### Prior Phase Decisions
- `.planning/phases/06-verify/06-CONTEXT.md` — Phase 6 split: Phase 7 handles keymap validation/fixes
- `.planning/PROJECT.md` §Requirements/Validated — KEY-01–03 marked as satisfied

### Validation
- `scripts/nvim-validate.sh` — Headless validation harness

</canonical_refs>

<codebase_context>
## Existing Code Insights

### Reusable Assets
- `core.keymaps.lazy.get_all_keys()` — returns all lazy-key specs from registry
- `attach.apply_lsp()` — applies buffer-scope LSP maps from registry on LspAttach
- `lazy.explorer_keys()` — consumed by neotree.lua (working pattern to replicate)

### Established Patterns
- `neotree.lua`: `keys = require("core.keymaps.lazy").explorer_keys()` — working lazy.nvim key trigger
- `ufo.lua`: calls `lazy.fold_keys()` inside plugin config — works for plugin-context folds
- `lsp.lua`: direct `vim.keymap.set` for `<leader>th` on LspAttach — duplicate to remove

### Integration Points
- `snacks.lua` → add `keys = require("core.keymaps.lazy").get_all_keys()` to register search/codelsp keys
- `lsp.lua` → remove lines 120-124 (the `<leader>th` direct vim.keymap.set)
- 02-VERIFICATION.md → update with current evidence

### Gap (Critical)
- **Snacks picker keys not registered**: `snacks.lua` has `lazy = false` but no `keys = {}`. All `<leader>f*`, `<leader>gg`, `<leader>gp/gt` are dead — not registered with lazy.nvim. Only `<leader>e`, `\\`, `<leader>nf` work (via neotree's `explorer_keys()`), and `zR/zM/zK` work (via ufo's `fold_keys()`).
- **Duplicate inlay hint key**: `lsp.lua:121` direct call vs registry's `lsp.toggle_inlay`

</codebase_context>

<specifics>
## Specific Ideas

- Snacks replaces fzf-lua per Phase 5 decision (D-06 in snacks.lua confirms)
- `<leader>gg` wired to `Snacks.lazygit()` in registry
- `lazy = false` for snacks — always loaded, so `Snacks.picker.*` calls work immediately when triggered
- The gap is purely the lazy.nvim key registration, not the functionality

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 07-keymap-validate*
*Context gathered: 2026-04-16*
