# Phase 9: Fix Keymap Registry Integration - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix runtime integration gaps so KEY-01/02/03 are satisfied at runtime:
1. Wire which-key group registration (M.groups declared but wk.add() never called)
2. Replace neo-tree with Snacks.explorer (eliminates domain mismatch + lazy-load conflicts)
3. Adopt full snacks-conventional key layout across registry
4. Clean up dead code (M.plugin_local, explorer_keys(), neotree.lua)

</domain>

<decisions>
## Implementation Decisions

### Which-key Registration
- **D-01:** Create new module `core/keymaps/whichkey.lua` — dedicated module for which-key group registration
- **D-02:** Invoke from `core/keymaps.lua` (or `core/options.lua`) at startup — NOT from misc.lua config block
- **D-03:** Register both prefix groups (from `M.groups`) AND all individual key descriptions from registry entries
- **D-04:** Use which-key v3 API: `wk.add()` — NOT `wk.register()` (v2 API, deprecated)

### Neo-tree Full Removal
- **D-05:** Delete `neotree.lua` entirely — remove `nvim-neo-tree/neo-tree.nvim` and its deps (`nvim-window-picker`, `nui.nvim` if only used by neo-tree)
- **D-06:** Replace with `Snacks.explorer()` — enable `explorer = { enabled = true, replace_netrw = true, trash = true }` in snacks.lua opts
- **D-07:** Snacks explorer config stays minimal — defaults handle git_status, diagnostics, watch, follow_file (all true by default)
- **D-08:** netrw disabled by snacks (`replace_netrw = true`) — remove any `vim.g.loaded_netrw` guards that were in neotree.lua init

### Key Layout — Full Snacks Convention
- **D-09:** Adopt complete snacks-conventional key layout (see snacks README defaults). Update ALL affected registry lazy entries.
- **D-10:** Explorer: `<leader>e` → `Snacks.explorer()` (same key, updated action)
- **D-11:** Git status: `<leader>gs` → `Snacks.picker.git_status()` (was `<leader>ngs` → neo-tree)
- **D-12:** Buffers: `<leader>,` → `Snacks.picker.buffers()` (was `<leader>nb` → neo-tree; `<leader><leader>` was `search.buffers` — reconcile conflict)
- **D-13:** LSP nav keys added to registry: `gd` → `Snacks.picker.lsp_definitions()`, `gr` → `Snacks.picker.lsp_references()`, `gI` → `Snacks.picker.lsp_implementations()`, `gy` → `Snacks.picker.lsp_type_definitions()`
- **D-14:** Additional git picker keys: `<leader>gl` (git log), `<leader>gb` (branches), `<leader>gd` (diff hunks), `<leader>gf` (git log file) — add to registry git domain
- **D-15:** Key conflict audit required — current `<leader><leader>` (search.buffers) vs `<leader>,` (new buffers) — planner decides which to keep or rename

### Registry Cleanup
- **D-16:** Remove `M.plugin_local` table from `registry.lua` — neo-tree window mappings, no longer needed
- **D-17:** Remove `explorer_keys()`, `buffer_keys()`, `window_keys()`, `toggle_keys()`, `save_keys()` helpers from `lazy.lua` if unused after neo-tree removal — audit which helpers remain referenced
- **D-18:** Remove neo-tree lazy entries: `explorer.toggle`, `explorer.reveal`, `explorer.git_status`, `explorer.buffers`, `explorer.reveal_file`, `git.commits` (was `:Neotree git_status`)
- **D-19:** With all lazy keys being snacks keys, `get_all_keys()` in snacks.lua remains correct — no filtering needed

### Domain Taxonomy Fix (now resolved by neo-tree removal)
- **D-20:** `explorer.git_status` entry (domain="g", was causing neo-tree load-trigger miss) — eliminated by D-18; replaced by D-11 `git.status` with `Snacks.picker.git_status()`
- **D-21:** Domain "e" (explorer) in M.groups remains — `<leader>e` maps to Snacks.explorer(), domain stays "e"

### Claude's Discretion
- Exact set of snacks keys to adopt beyond the neo-tree replacements — planner should cross-reference snacks docs and existing registry to avoid key conflicts, adopting snacks defaults where no conflict exists
- Whether `nui.nvim` and `plenary.nvim` are used by other plugins (check before removing) — planner must audit deps before removal
- Exact call site for `whichkey.lua` — `core/keymaps.lua` preferred, but planner confirms based on load order

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Keymap Architecture (current)
- `.config/nvim/lua/core/keymaps/registry.lua` — Central registry; M.global, M.lazy, M.plugin_local, M.groups
- `.config/nvim/lua/core/keymaps/lazy.lua` — Compiles registry to lazy.nvim key specs
- `.config/nvim/lua/core/keymaps.lua` — Core keymaps entry point (leader key, apply_global call site)

### Plugin Files (to modify or delete)
- `.config/nvim/lua/plugins/snacks.lua` — Add `explorer = { enabled = true, replace_netrw = true, trash = true }` to opts
- `.config/nvim/lua/plugins/neotree.lua` — DELETE this file
- `.config/nvim/lua/plugins/misc.lua` — which-key plugin spec lives here (config block)

### Which-key
- Which-key v3 API: `wk.add()` not `wk.register()` — snacks commit `3aab214` (see lazy-lock.json)
- `M.groups` in registry.lua — domain prefix → group label mapping (source for wk.add groups)

### Snacks Explorer Docs (researched)
- Snacks.explorer config: `{ replace_netrw = true, trash = true }` for explicit options; rest are defaults
- `Snacks.explorer()` — the API call (not `Snacks.explorer.open()`)
- Default explorer keys: `l`=open, `h`=close dir, `a`=add, `d`=del, `r`=rename, `c`=copy, `m`=move
- Snacks conventional key layout: `<leader>e` explorer, `<leader>gs` git status, `<leader>gl` git log, `<leader>gb` branches, `gd/gr/gI/gy` LSP nav

### Prior Phase Decisions
- `.planning/phases/07-keymap-validate/07-CONTEXT.md` — D-02/D-03: snacks.lua keys wired via get_all_keys(); D-04: fold_keys() stays via ufo.lua
- `.planning/phases/07-keymap-validate/07-REVIEW.md` — WR-01 (Tab conflict), IN-03 (domain mismatch now resolved by neo-tree removal)

### Validation
- `scripts/nvim-validate.sh` — Must pass after changes

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `M.groups` in registry.lua — already has domain prefix→label mapping, ready for wk.add()
- `get_all_keys()` in lazy.lua — stays as snacks.lua key source after neo-tree removal
- `fold_keys()` in lazy.lua — stays wired via ufo.lua (unaffected)
- `core/keymaps.lua` — existing call site for apply_global(); add whichkey.setup() call here

### Established Patterns
- snacks.lua pattern: `keys = function() return require("core.keymaps.lazy").get_all_keys() end`
- Plugin config pattern in misc.lua: `config = function() require("which-key").setup({}) end`
- After adding `explorer = { ... }` to snacks opts, Snacks.explorer() is available globally

### Integration Points
- `neotree.lua` deletion removes: nvim-neo-tree/neo-tree.nvim, s1n7ax/nvim-window-picker as deps
- `nui.nvim` and `plenary.nvim` — may be used by other plugins; check before removing
- `registry.lua` M.plugin_local removal: only affects neotree.lua (already deleted)
- `lazy.lua` cleanup: `explorer_keys()` becomes dead code; `get_by_scope("plugin-local")` call in utility functions also dead

</code_context>

<specifics>
## Specific Ideas

- User wants "full potential of snacks.explorer" — adopt complete snacks key convention, not just neo-tree replacements
- Snacks explorer is a picker-based file tree (not a separate plugin like neo-tree) — it uses Snacks.picker under the hood, so all picker config applies
- The `\` (backslash) reveal key from neo-tree — check if snacks.explorer has an equivalent (focus/reveal current file)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 09-fix-keymap-registry-integration*
*Context gathered: 2026-04-17*
