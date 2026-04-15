# Phase 2: Central Command and Keymap Architecture - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Move all custom Neovim mappings under one maintainable control plane, group them coherently by domain, and remove hidden duplicate user-facing mappings from plugin files. This phase is about architecture, discoverability, and normalization of existing commands, not adding new editor capabilities.

</domain>

<decisions>
## Implementation Decisions

### Central Registry Shape
- **D-01:** Phase 2 must introduce a single declarative registry as the authoritative source of truth for all custom mappings.
- **D-02:** Plugin files must not own separate user-facing mapping definitions after migration; they should consume the central registry instead.

### Prefix Taxonomy
- **D-03:** The registry should enforce strict domain prefixes rather than preserving mixed ad hoc groupings.
- **D-04:** The preferred domain model is: search under `f`, code/LSP under `c`, git under `g`, explorer/tree under `e`, buffers under `b`, windows under `w`, toggles under `t`, and save/session actions under `s`.

### Direct Key Policy
- **D-05:** Only a small, intentional set of non-leader direct keys should remain; most custom workflow commands should move behind leader-prefixed groups.
- **D-06:** The direct keys explicitly preserved are `jk`, `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`, comment toggle mappings, and `<Tab>` / `<S-Tab>` buffer cycling.
- **D-07:** Before changing any direct-key behavior, Phase 2 must provide a complete inventory of current direct custom mappings so the user can review them first.

### Plugin-Local Mapping Rules
- **D-08:** All mappings, including plugin-local and context-local mappings, should be pulled into the central registry architecture rather than remaining scattered across plugin files.
- **D-09:** Buffer-local or window-local behavior is allowed at runtime, but its definition must still originate from the same central registry and remain discoverable there.

### the agent's Discretion
- Exact module/file layout for the registry and helper functions
- Exact registry data shape, as long as it stays declarative and centralized
- Exact migration order across core and plugin files
- Exact documentation format for the keymap inventory and final organization

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 2 goal, plan breakdown, and success criteria for central keymap architecture
- `.planning/REQUIREMENTS.md` — `KEY-01`, `KEY-02`, and `KEY-03`
- `.planning/PROJECT.md` — project constraints around one shared config, aggressive cleanup, and maintainability

### Existing code and architecture
- `.planning/phases/01-reliability-and-portability-baseline/01-CONTEXT.md` — carry forward Phase 1 decisions, especially predictable buffer/window/tab semantics
- `.planning/codebase/STRUCTURE.md` — current placement of `core/` and `plugins/` modules
- `.planning/codebase/CONCERNS.md` — notes scattered behavior and fragile areas that centralization should reduce

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.config/nvim/lua/core/keymaps.lua`: current home of many global custom mappings and the clearest starting point for a registry extraction
- `.config/nvim/lua/plugins/fzflua.lua`: already expresses mappings in a declarative `keys = {}` style that could inform the registry shape
- `.config/nvim/lua/plugins/lsp.lua`: contains buffer-local LSP mappings currently created in `LspAttach`, making it a key migration target
- `.config/nvim/lua/plugins/neotree.lua`: contains both global entry-point mappings and large plugin-local mapping tables, so it is a major source of hidden mapping drift
- `.config/nvim/lua/plugins/ufo.lua`: contains direct `vim.keymap.set` calls for fold actions that must become visible in the central control plane

### Established Patterns
- Core behavior currently lives in `lua/core/`, while plugin integrations live in `lua/plugins/`
- The repo already mixes two mapping styles: direct `vim.keymap.set(...)` calls and plugin-spec `keys = {}` declarations
- Descriptions already exist for many mappings, so the registry can build on existing labels rather than inventing them from scratch

### Integration Points
- `core.keymaps` is the immediate extraction point for registry-driven global mappings
- Plugin specs that support `keys = {}` should consume the same registry rather than hardcoding their own entries
- Plugin configs that need buffer-local or window-local attachment should still pull definitions from the central registry layer

</code_context>

<specifics>
## Specific Ideas

- The user wants to keep a short set of intentional direct keys, not eliminate them entirely
- The user explicitly wants to preserve `jk`, `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`, comment toggle mappings, and buffer cycling on `<Tab>` / `<S-Tab>`
- The user wants to see the full direct-key inventory before any direct-key cleanup changes are made

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-central-command-and-keymap-architecture*
*Context gathered: 2026-04-14*
