# Phase 07 — Pattern Map

## Files Likely To Change

### `.config/nvim/lua/core/keymaps/registry.lua`

- **Role:** single source of truth for user-facing mappings
- **Existing pattern:** mapping entries use structured tables with `id`, `lhs`, `mode`, `desc`, `domain`, `scope`, `plugin`, `action`, `opts`
- **Important quirk:** execution ownership follows which top-level table (`M.global`, `M.lazy`, `M.buffer`, `M.plugin_local`) contains the entry, not only the entry's `scope` field
- **Relevant analog inside file:** existing safe entries already use direct functions for actions, especially snacks/gitsigns-adjacent mappings
- **Pattern to follow:** prefer `action = function() ... end` when behavior is more than a plain startup-safe RHS string

### `.config/nvim/lua/core/keymaps/apply.lua`

- **Role:** emits startup/global mappings from registry
- **Existing pattern:** both string and function actions are accepted and sent through `vim.keymap.set(...)`
- **Planning implication:** changing broken global mappings in `registry.lua` to functions does not require new apply-layer abstraction

### `.config/nvim/lua/core/keymaps/lazy.lua`

- **Role:** compiles lazy.nvim key specs
- **Existing pattern:** runtime wrapper first tries `require(map.plugin)` and module method lookup, then direct function action, then `vim.cmd(map.action)`
- **Planning implication:** lazy mappings that are semantically commands should prefer direct functions when possible; misfiled shared mappings should move out of `M.lazy`; Gitsigns entries fit the direct-function pattern

### `.config/nvim/lua/core/keymaps/attach.lua`

- **Role:** applies buffer/plugin-local mappings for contextual surfaces
- **Existing pattern:** fetch by scope, then `vim.keymap.set(...)` into buffer context
- **Risk pattern:** uses `plugin_local` token, while project docs/history use `plugin-local`
- **Planning implication:** normalize scope token rather than inventing new helper behavior

### `.planning/phases/06-runtime-failure-inventory/FAILURES.md`

- **Role:** living bug ledger consumed by later phases
- **Existing pattern:** status and root-cause narrative updated in place after verification
- **Planning implication:** Phase 7 should mark fixed items directly here instead of creating parallel status docs

### `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md`

- **Role:** manual repro matrix
- **Existing pattern:** each bug has numbered steps, expected behavior, and fix note
- **Planning implication:** keep same structure, but update expected post-fix outcomes for regression use

### `.config/nvim/README.md`

- **Role:** user-facing config and validation doc
- **Existing pattern:** central keymap rule and manual keymap smoke tables already exist
- **Planning implication:** only patch exact wording tied to fixed keymaps or helper terminology if behavior/docs diverge

## Closest Existing Code Patterns

### Direct function action in registry

- Snacks mappings already use:
  - `action = function() Snacks.picker.files() end`
  - `action = function() Snacks.lazygit() end`
- Use same style for fixed shared keymaps and Gitsigns actions.

### Ex command through callback

- Existing registry code uses:
  - `function() vim.cmd("confirm bdelete") end`
  - `function() vim.cmd("w") end`
- Use same shape for `enew`, `split`, `vsplit`, `close`, `wincmd =`, `noautocmd w`.

### Stateful toggle through callback

- Existing config already flips state through direct Lua in callbacks.
- Best analog for wrap toggle is local state mutation:
  - `function() vim.wo.wrap = not vim.wo.wrap end`

## Planning Notes

- Do not route fixes through plugin specs.
- Do not rely on `scope = "global"` metadata alone; verify the entry sits in the correct top-level registry table.
- Do not add new helper layers unless repo evidence shows repeat need.
- Keep write scope concentrated in registry/helper/docs; Phase 8 owns broader plugin-runtime hardening.
