# Phase 2: Central Command and Keymap Architecture - Research

**Researched:** 2026-04-14 [VERIFIED: local system date]
**Domain:** Neovim keymap architecture, `lazy.nvim` key-trigger loading, and centralized command taxonomy for a Lua config [VERIFIED: codebase grep][CITED: https://lazy.folke.io/]
**Confidence:** HIGH [VERIFIED: codebase grep][CITED: https://neovim.io/doc/user/api/][CITED: https://github.com/folke/which-key.nvim]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Phase 2 must introduce a single declarative registry as the authoritative source of truth for all custom mappings. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- **D-02:** Plugin files must not own separate user-facing mapping definitions after migration; they should consume the central registry instead. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- **D-03:** The registry should enforce strict domain prefixes rather than preserving mixed ad hoc groupings. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- **D-04:** The preferred domain model is: search under `f`, code/LSP under `c`, git under `g`, explorer/tree under `e`, buffers under `b`, windows under `w`, toggles under `t`, and save/session actions under `s`. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- **D-05:** Only a small, intentional set of non-leader direct keys should remain; most custom workflow commands should move behind leader-prefixed groups. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- **D-06:** The direct keys explicitly preserved are `jk`, `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`, comment toggle mappings, and `<Tab>` / `<S-Tab>` buffer cycling. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- **D-07:** Before changing any direct-key behavior, Phase 2 must provide a complete inventory of current direct custom mappings so the user can review them first. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- **D-08:** All mappings, including plugin-local and context-local mappings, should be pulled into the central registry architecture rather than remaining scattered across plugin files. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- **D-09:** Buffer-local or window-local behavior is allowed at runtime, but its definition must still originate from the same central registry and remain discoverable there. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]

### Claude's Discretion
- Exact module/file layout for the registry and helper functions [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- Exact registry data shape, as long as it stays declarative and centralized [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- Exact migration order across core and plugin files [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- Exact documentation format for the keymap inventory and final organization [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| KEY-01 | User can find all custom keymaps in one central source of truth [VERIFIED: .planning/REQUIREMENTS.md] | Use one declarative registry module plus generated lazy specs and buffer-attach helpers so every custom mapping is declared once and emitted many ways [VERIFIED: codebase grep][CITED: https://lazy.folke.io/][CITED: https://github.com/folke/which-key.nvim] |
| KEY-02 | User can understand keymap groups by domain and descriptive labels instead of scattered one-off mappings [VERIFIED: .planning/REQUIREMENTS.md] | Use the locked prefix taxonomy plus `desc` on every entry and `which-key` group metadata from the same registry [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md][CITED: https://github.com/folke/which-key.nvim] |
| KEY-03 | User can trigger plugin actions from centralized mappings without hidden duplicate mappings remaining in plugin files [VERIFIED: .planning/REQUIREMENTS.md] | Compile plugin-facing `keys = {}` entries from the registry for lazy loading, and move runtime buffer-local maps to registry-driven attach functions [VERIFIED: codebase grep][CITED: https://lazy.folke.io/][CITED: https://neovim.io/doc/user/api/] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- The repo is a shared dotfiles repository and `.config/nvim/` is copied into `~/.config/nvim/`; rollout may require external install scripts on target machines. [VERIFIED: CLAUDE.md]
- The Neovim config architecture is `init.lua` -> `core.options` -> `core.keymaps` -> `lazy.nvim` plugin discovery under `lua/plugins/`. [VERIFIED: CLAUDE.md]
- `fzf-lua` is the search/navigation frontend already used for fuzzy finding and LSP navigation. [VERIFIED: CLAUDE.md]
- `which-key.nvim` is already installed in the repo and currently initialized in `lua/plugins/misc.lua`. [VERIFIED: codebase grep][VERIFIED: lazy-lock.json]
- Existing high-value direct keys in the repo include `jk`, `<C-_>`, `<Tab>`, `<S-Tab>`, and `<C-h/j/k/l>`, which matches the Phase 2 preservation decisions. [VERIFIED: codebase grep][VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- Commit convention in this repo is `[UPDATE] description`. [VERIFIED: CLAUDE.md]

## Summary

The repo currently defines custom mappings in three different ways: direct global `vim.keymap.set(...)` calls in `lua/core/keymaps.lua`, plugin-spec `keys = {}` in `lua/plugins/fzflua.lua`, and runtime buffer-local or plugin-local mappings inside plugin config callbacks such as `LspAttach` and `neo-tree` setup. That fragmentation is the exact planning problem for Phase 2 because it makes discoverability, lazy-loading behavior, and duplicate-removal hard to reason about. [VERIFIED: codebase grep]

The stable design is a central declarative registry that stores every user-facing mapping exactly once, then exposes three emitters from that same data: eager global application for core mappings, generated `lazy.nvim` `keys` specs for plugin-triggered mappings, and runtime attach helpers for buffer-local/window-local/plugin-local mappings. `lazy.nvim` already supports lazy-loading on key mappings, Neovim supports buffer-local maps with `buffer = bufnr`, and `which-key` v3 can register group metadata independently from the mapping itself. [CITED: https://lazy.folke.io/][CITED: https://neovim.io/doc/user/api/][CITED: https://github.com/folke/which-key.nvim]

The migration should not be “move everything into one giant `vim.keymap.set` file.” That would regress plugin lazy-loading and make buffer-local semantics harder to preserve. The right control plane is declarative data plus emitters, not one imperative file. [VERIFIED: codebase grep][CITED: https://lazy.folke.io/][CITED: https://neovim.io/doc/user/api/]

**Primary recommendation:** Build one `core.keymaps.registry` data module that declares all user-facing maps once, then compile it into global mappings, plugin `keys` specs, `which-key` groups, and runtime attach helpers. [VERIFIED: codebase grep][CITED: https://lazy.folke.io/][CITED: https://github.com/folke/which-key.nvim]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Neovim built-in keymap API | `NVIM v0.12.1` locally installed [VERIFIED: local nvim --version] | Own the final mapping application, including buffer-local mappings via options like `buffer` and descriptive `desc` fields [CITED: https://neovim.io/doc/user/api/] | It is the canonical runtime API that every plugin layer ultimately targets [CITED: https://neovim.io/doc/user/api/] |
| `folke/lazy.nvim` | pinned commit `6c3bda4aca61a13a9c63f1c1d1b16b9d3be90d7a` in `lazy-lock.json` [VERIFIED: lazy-lock.json] | Generate plugin-facing `keys` specs so plugin actions still lazy-load on first use [CITED: https://lazy.folke.io/] | The repo already uses it as the plugin control plane, and official docs state it lazy-loads on key mappings and supports multi-file specs [VERIFIED: CLAUDE.md][CITED: https://lazy.folke.io/] |
| `folke/which-key.nvim` | pinned commit `370ec46f710e058c9c1646273e6b225acf47cbed` in `lazy-lock.json` [VERIFIED: lazy-lock.json] | Register domain groups and discoverable labels from the same registry [CITED: https://github.com/folke/which-key.nvim] | Official docs say it reads `desc` from mappings and can add group-only metadata with `add()` / spec entries [CITED: https://github.com/folke/which-key.nvim] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `ibhagwan/fzf-lua` | configured in repo, but no `fzf-lua` entry was found in the current `lazy-lock.json` during this research session [VERIFIED: codebase grep][VERIFIED: lazy-lock.json] | Backing implementation for the `f` search domain and LSP navigation actions already mapped in this repo [VERIFIED: codebase grep] | Keep it as the action backend while Phase 2 centralizes the invocation points; Phase 3 can decide whether the missing lockfile entry needs cleanup [VERIFIED: CLAUDE.md][VERIFIED: codebase grep][ASSUMED] |
| `nvim-neo-tree/neo-tree.nvim` | pinned commit `cea666ef965884414b1b71f6b39a537f9238bdb2` [VERIFIED: lazy-lock.json] | Backing implementation for explorer-domain entry points and plugin-local tree window mappings [VERIFIED: codebase grep] | Use registry-generated entry maps plus registry-documented internal window maps [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Registry -> lazy/global/attach emitters | One imperative file that calls `vim.keymap.set` for everything | Simpler to read at first, but it defeats `lazy.nvim` key-trigger loading and obscures buffer-local semantics [CITED: https://lazy.folke.io/][CITED: https://neovim.io/doc/user/api/] |
| `which-key` group metadata from the registry | Comments-only grouping in Lua files | Comments do not provide in-editor discoverability and drift easily from actual mappings [VERIFIED: codebase grep][CITED: https://github.com/folke/which-key.nvim] |
| Centralized registry-owned plugin entry maps | Leaving user-facing `keys = {}` or `vim.keymap.set(...)` inside plugin files | That directly violates D-02 and preserves hidden duplication risk [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md] |

**Installation:** No new external package is required for Phase 2 because Neovim, `lazy.nvim`, and `which-key.nvim` are already present in the repo/runtime. [VERIFIED: local nvim --version][VERIFIED: lazy-lock.json][VERIFIED: codebase grep]

**Version verification:** `npm view` is not applicable here because the stack is Neovim core plus GitHub-hosted plugins; the verified versions above come from the local Neovim runtime and repo lockfile. [VERIFIED: local nvim --version][VERIFIED: lazy-lock.json]

## Architecture Patterns

### Recommended Project Structure
```text
.config/nvim/lua/core/
├── options.lua                 # existing editor options [VERIFIED: .planning/codebase/STRUCTURE.md]
├── keymaps.lua                 # thin bootstrap that applies eager maps [VERIFIED: codebase grep]
└── keymaps/
    ├── registry.lua            # single source of truth for all user-facing mappings [ASSUMED]
    ├── apply.lua               # applies eager/global maps via vim.keymap.set [ASSUMED]
    ├── lazy.lua                # compiles plugin key specs from the registry [ASSUMED]
    ├── whichkey.lua            # registers groups/spec from the registry [ASSUMED]
    └── attach.lua              # installs buffer-local/plugin-local maps from registry entries [ASSUMED]
```

### Pattern 1: Declarative Registry With Stable Entry Shape
**What:** Each mapping entry should be plain data with fields for `id`, `lhs`, `mode`, `desc`, `domain`, `scope`, `plugin`, `action`, `opts`, and optional `attach` / `cond` metadata. That keeps inventory, documentation, and emitters aligned. [VERIFIED: codebase grep][CITED: https://github.com/folke/which-key.nvim][CITED: https://neovim.io/doc/user/api/]
**When to use:** Use for every custom user-facing mapping, including global, lazy plugin-triggered, buffer-local, and plugin-window-local entries. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
**Example:**
```lua
-- Source pattern: Neovim `desc`/buffer API + which-key v3 spec + lazy.nvim key specs
return {
  {
    id = "search.files",
    lhs = "<leader>ff",
    mode = "n",
    desc = "Find files",
    domain = "f",
    scope = "lazy",
    plugin = "ibhagwan/fzf-lua",
    action = function()
      require("fzf-lua").files()
    end,
  },
  {
    id = "code.rename",
    lhs = "<leader>cn",
    mode = "n",
    desc = "Rename symbol",
    domain = "c",
    scope = "buffer",
    attach = "lsp",
    action = vim.lsp.buf.rename,
  },
}
```

### Pattern 2: Compile The Same Entry Into Different Targets
**What:** One entry should compile to one of three targets: immediate `vim.keymap.set`, lazy plugin `keys = {}`, or runtime attachment inside a known attach point such as `LspAttach` or `neo-tree` setup. [VERIFIED: codebase grep][CITED: https://lazy.folke.io/][CITED: https://neovim.io/doc/user/api/]
**When to use:** Use whenever a mapping’s runtime semantics differ but its source of truth must stay central. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
**Example:**
```lua
-- Source pattern: lazy.nvim keys + Neovim buffer-local keymaps
local function to_lazy_key(entry)
  return { entry.lhs, entry.action, mode = entry.mode, desc = entry.desc }
end

local function apply_buffer_map(bufnr, entry)
  vim.keymap.set(entry.mode, entry.lhs, entry.action, {
    buffer = bufnr,
    desc = entry.desc,
    silent = true,
  })
end
```

### Pattern 3: Keep Plugin-Internal Maps Documented But Separate From User Entry Maps
**What:** Plugin-internal maps such as neo-tree window mappings or csvview local navigation can stay plugin-owned at runtime, but their definitions should still be mirrored in the central registry as `scope = "plugin-local"` entries so the control plane remains complete. [VERIFIED: codebase grep][VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
**When to use:** Use for mappings that only exist inside plugin buffers or modes and are not sensible as top-level global maps. [VERIFIED: codebase grep]
**Example:**
```lua
-- Source pattern: which-key group-only metadata + plugin-local inventory
{
  id = "explorer.internal.open_split",
  lhs = "S",
  mode = "n",
  desc = "Open in horizontal split",
  domain = "e",
  scope = "plugin-local",
  attach = "neo-tree.filesystem",
}
```

### Direct-Key Inventory and Preservation Policy

**Explicitly preserved by locked decision:** `jk`, `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`, comment toggle mappings on `<C-_>`, and `<Tab>` / `<S-Tab>` buffer cycling. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]

**Current global direct custom mappings to inventory before cleanup:** `<C-q>`, `<C-s>`, `jk`, `x`, `<C-d>`, `<C-u>`, `n`, `N`, `<C-_>`, `gl`, `<Up>`, `<Down>`, `<Left>`, `<Right>`, `<Tab>`, `<S-Tab>`, `<C-k>`, `<C-j>`, `<C-h>`, `<C-l>`, `<C-S-o>`, and `<C-i>`. [VERIFIED: codebase grep]

**Current plugin-driven direct custom mappings that still affect user workflow:** `zR`, `zM`, `zK` in `ufo`; `grt`, `gO`, and `gW` in LSP attach; `\` for neo-tree reveal; treesitter incremental selection on `<Enter>` / `<Backspace>`; csvview navigation on `<Tab>`, `<S-Tab>`, `<Enter>`, and `<S-Enter>` inside CSV contexts; neo-tree window-local keys such as `l`, `S`, `s`, `t`, `w`, `a`, `d`, `r`, `q`, `H`, `/`, and ordering prefixes under `o*`. [VERIFIED: codebase grep]

**Planning implication:** 02-01 should produce this inventory as a reviewed artifact before any direct-key removals or relocations, then classify each item as `preserve`, `move-behind-leader`, `plugin-local-only`, or `drop`. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md][VERIFIED: codebase grep]

### Concrete Plan Decomposition For The 3 Roadmap Plans

**02-01: Design command taxonomy and central keymap registry structure** should define the registry schema, prefix taxonomy, preserved-direct-key policy, and first complete inventory of all current custom mappings and scopes. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md][VERIFIED: codebase grep]

**02-02: Migrate scattered mappings into the central registry without breaking workflows** should move `core/keymaps.lua`, `fzflua.lua`, `lsp.lua`, `ufo.lua`, and neo-tree entry-point maps first, then migrate plugin-local attach points like `LspAttach` and neo-tree window mappings to consume registry data. [VERIFIED: .planning/ROADMAP.md][VERIFIED: codebase grep]

**02-03: Document keymap organization and remove stale/duplicate mapping definitions** should generate human-facing docs from the registry, wire `which-key` groups from the same source, and verify no duplicate user-facing definitions remain in plugin files. [VERIFIED: .planning/ROADMAP.md][VERIFIED: codebase grep][CITED: https://github.com/folke/which-key.nvim]

### Anti-Patterns to Avoid
- **Single giant imperative keymap file:** This centralizes text but not semantics, and it breaks the existing lazy/plugin lifecycle model. [VERIFIED: codebase grep][CITED: https://lazy.folke.io/]
- **Registry plus hand-maintained plugin duplicates:** That recreates the current drift problem under a different name. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- **Buffer-local maps emitted as globals:** LSP and plugin-buffer actions like neo-tree input/window mappings need runtime scoping. [VERIFIED: codebase grep][CITED: https://neovim.io/doc/user/api/]
- **Changing direct keys before inventory review:** That violates D-07 and risks breaking muscle memory without audit. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Key-trigger plugin loading | A custom dispatcher that `require(...)`s plugins from a global map table | `lazy.nvim` `keys` specs generated from the registry [CITED: https://lazy.folke.io/] | `lazy.nvim` already handles correct load timing, dependency ordering, and key-trigger lazy loading [CITED: https://lazy.folke.io/] |
| Keymap discovery UI | A custom popup or static cheat-sheet-only system | `which-key.nvim` groups/spec derived from the registry [CITED: https://github.com/folke/which-key.nvim] | The plugin already supports group metadata, labels, proxies, and popup discovery [CITED: https://github.com/folke/which-key.nvim] |
| Buffer-local attach plumbing | Ad hoc per-plugin inline `map()` helpers scattered across files | One shared `attach.lua` helper driven by registry entries [VERIFIED: codebase grep][CITED: https://neovim.io/doc/user/api/] | The repo already has repeated attach-time mapping logic in `lsp.lua` and plugin-local buffers [VERIFIED: codebase grep] |
| Inventory/documentation maintenance | Manual duplicate lists in comments and docs | Generate docs/inventory views from the registry data [ASSUMED] | Generated docs are less likely to drift than a second handwritten source of truth [ASSUMED] |

**Key insight:** The hand-rolled part should be only the registry schema and emitters; lazy loading, mapping application, and key-hint UX already have mature primitives in the current stack. [VERIFIED: codebase grep][CITED: https://lazy.folke.io/][CITED: https://github.com/folke/which-key.nvim][CITED: https://neovim.io/doc/user/api/]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None found for keymap architecture; this repo stores config text and `lazy-lock.json`, not a runtime datastore of mappings [VERIFIED: .planning/codebase/STRUCTURE.md][VERIFIED: codebase grep] | None — code edit only [VERIFIED: codebase grep] |
| Live service config | None found for Neovim keymaps; no external service/UI-managed keymap config is referenced by this phase [VERIFIED: codebase grep] | None [VERIFIED: codebase grep] |
| OS-registered state | None found for Neovim keymap definitions; unrelated systemd units exist elsewhere in the dotfiles repo but are not part of `.config/nvim` keymap behavior [VERIFIED: codebase grep] | None for this phase [VERIFIED: codebase grep] |
| Secrets/env vars | No secret or env-var name appears to gate current keymap definitions; `mapleader` is a normal Neovim global, not an external secret or deployment variable [VERIFIED: codebase grep] | None [VERIFIED: codebase grep] |
| Build artifacts | No installed artifact stores old keymap identifiers; lazy cache/shada may cache runtime state, but the repo contains no rename-sensitive package artifact for this phase [VERIFIED: codebase grep][ASSUMED] | None beyond normal Neovim restart after implementation [ASSUMED] |

## Common Pitfalls

### Pitfall 1: Centralizing Text But Breaking Lazy Loading
**What goes wrong:** Moving plugin actions from `keys = {}` into eager top-level maps causes plugin code to load earlier than before or fail on missing `require(...)` timing. [VERIFIED: codebase grep][CITED: https://lazy.folke.io/]
**Why it happens:** The current repo already relies on `lazy.nvim` key-trigger loading for `fzf-lua`, while other plugin actions are eager in core or runtime attach callbacks. [VERIFIED: codebase grep]
**How to avoid:** Keep a `scope = "lazy"` path in the registry and compile it back into plugin `keys` specs. [CITED: https://lazy.folke.io/]
**Warning signs:** Startup begins requiring plugin modules earlier, or mappings only work after manually opening the plugin once. [ASSUMED]

### Pitfall 2: Losing Buffer Scope During Migration
**What goes wrong:** LSP or plugin-buffer maps become global, shadowing normal editing motions or leaking into unrelated buffers. [VERIFIED: codebase grep][CITED: https://neovim.io/doc/user/api/]
**Why it happens:** Current `lsp.lua` uses `buffer = event.buf`, and neo-tree also defines buffer-local input/window mappings. [VERIFIED: codebase grep]
**How to avoid:** Model `scope = "buffer"` or `scope = "plugin-local"` explicitly in the registry and only apply those entries through attach helpers. [VERIFIED: codebase grep][CITED: https://neovim.io/doc/user/api/]
**Warning signs:** `grt`, `gO`, `gW`, or tree-local keys appear in non-LSP or non-tree buffers. [VERIFIED: codebase grep][ASSUMED]

### Pitfall 3: Duplicate User-Facing Maps Survive The Refactor
**What goes wrong:** The registry defines a new map but the old plugin file still keeps its own copy, leaving hidden duplicates or conflicting descriptions. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
**Why it happens:** The repo currently mixes direct `vim.keymap.set`, plugin `keys`, and plugin-internal tables across multiple files. [VERIFIED: codebase grep]
**How to avoid:** Add a verification step that greps for user-facing mapping definitions outside the approved registry/apply modules after migration. [VERIFIED: codebase grep]
**Warning signs:** `rg -n "vim\\.keymap\\.set|keys\\s*=\\s*\\{" .config/nvim/lua` still shows user-facing definitions in old plugin files after 02-02. [VERIFIED: codebase grep]

### Pitfall 4: Direct-Key Cleanup Collides With Contextual Plugin Keys
**What goes wrong:** Global cleanup decisions accidentally remove or overwrite contextual keys used by treesitter, csvview, or neo-tree. [VERIFIED: codebase grep]
**Why it happens:** The same physical keys like `<Tab>` and `<Enter>` are used both globally and inside context-specific plugin modes. [VERIFIED: codebase grep]
**How to avoid:** Separate the inventory into `global direct`, `buffer-local direct`, and `plugin-window-local direct` classes before deciding what to preserve or move. [VERIFIED: codebase grep]
**Warning signs:** CSV navigation, incremental selection, or tree navigation stops working after “cleanup” even though global maps look correct. [VERIFIED: codebase grep][ASSUMED]

## Code Examples

Verified patterns from official sources:

### Neovim Buffer-Local Mapping
```lua
vim.keymap.set("n", "<leader>cn", vim.lsp.buf.rename, {
  buffer = bufnr,
  desc = "Rename symbol",
})
```
Source: Neovim mapping/API docs describe `desc` and callback support, and the repo already uses buffer-local attachment for LSP mappings. [CITED: https://neovim.io/doc/user/api/][VERIFIED: codebase grep]

### `which-key` Group Registration
```lua
require("which-key").add({
  { "<leader>f", group = "search" },
  { "<leader>c", group = "code" },
  { "<leader>g", group = "git" },
})
```
Source: `which-key.nvim` v3 README documents `add()` and group-only spec entries. [CITED: https://github.com/folke/which-key.nvim]

### `lazy.nvim` Key-Triggered Plugin Spec
```lua
{
  "ibhagwan/fzf-lua",
  keys = {
    {
      "<leader>ff",
      function()
        require("fzf-lua").files()
      end,
      desc = "Find Files",
    },
  },
}
```
Source: the repo already uses this pattern in `fzflua.lua`, and `lazy.nvim` documents lazy-loading on key mappings. [VERIFIED: .config/nvim/lua/plugins/fzflua.lua][CITED: https://lazy.folke.io/]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `which-key` older register-style configuration | `which-key` v3 recommends `add()` / `opts.spec` and states the mappings spec changed in v3 [CITED: https://github.com/folke/which-key.nvim] | Current README on `main` branch as crawled 2026-04 [CITED: https://github.com/folke/which-key.nvim] | Phase 2 should target `add()`-style group registration instead of older snippets [CITED: https://github.com/folke/which-key.nvim] |
| Scattered mapping ownership by file | Central registry compiled into lazy/global/attach targets [VERIFIED: codebase grep][ASSUMED] | This is the needed repo evolution for Phase 2, not an upstream plugin change [VERIFIED: .planning/ROADMAP.md][ASSUMED] | It preserves runtime behavior while making the source of truth singular [VERIFIED: .planning/REQUIREMENTS.md][ASSUMED] |
| Plugin-local inline attach helpers | Shared buffer-attach helper using `buffer = bufnr` [VERIFIED: codebase grep][CITED: https://neovim.io/doc/user/api/] | Supported by current Neovim runtime [VERIFIED: local nvim --version][CITED: https://neovim.io/doc/user/api/] | Reduces duplicated attach logic and makes buffer-local mappings auditable [ASSUMED] |

**Deprecated/outdated:**
- Keeping group structure only in comments or file layout is outdated for this repo because `which-key` is already installed and can expose the taxonomy interactively from registry metadata. [VERIFIED: codebase grep][CITED: https://github.com/folke/which-key.nvim]
- Leaving user-facing mappings mixed across `core/keymaps.lua`, plugin `keys`, and runtime callbacks is outdated relative to the locked Phase 2 decisions. [VERIFIED: codebase grep][VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A dedicated `core/keymaps/` module split (`registry.lua`, `apply.lua`, `lazy.lua`, `whichkey.lua`, `attach.lua`) is the best file layout for this repo | Architecture Patterns | Low — planner can choose a different file layout without changing the research conclusions |
| A2 | Generated docs/inventory from the registry are worth doing in 02-03 instead of maintaining a manual markdown list only | Don't Hand-Roll | Low — planner can keep docs manual if implementation cost is not justified |
| A3 | Normal Neovim restart is sufficient after refactor because no separate installed artifact stores old keymap IDs | Runtime State Inventory | Low — if wrong, planner may need to add a cache-clear note |
| A4 | Warning-sign behaviors described for lazy-loading and contextual-key regressions are the likely failure modes during migration | Common Pitfalls | Low — they are guardrails, not locked requirements |
| A5 | The central registry should compile into lazy/global/attach targets rather than staying as docs plus imperative code | State of the Art / Summary | Medium — this is the core architectural recommendation for planning |

## Open Questions

1. **Should plugin-window-local maps like neo-tree’s internal `window.mappings` be fully generated from the registry, or only inventoried there and projected into plugin config tables?**
   - What we know: D-08 and D-09 require the definitions to originate from the same registry, but neo-tree currently expects nested `window.mappings` tables rather than `vim.keymap.set` calls. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md][VERIFIED: codebase grep]
   - What's unclear: Whether the planner wants a full compiler into plugin option tables in Phase 2 or a smaller first step that centralizes data and injects it into neo-tree config. [VERIFIED: codebase grep][ASSUMED]
   - Recommendation: Plan neo-tree as a first-class adapter case in 02-02 instead of treating it like ordinary global maps. [VERIFIED: codebase grep][ASSUMED]

2. **Should contextual plugin keymaps that intentionally override preserved direct keys stay invisible to the global taxonomy or be surfaced as a separate appendix?**
   - What we know: CSV view and treesitter already reuse `<Tab>`, `<S-Tab>`, and `<Enter>` contextually. [VERIFIED: codebase grep]
   - What's unclear: The desired final doc UX for those contextual overlaps. [VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md][ASSUMED]
   - Recommendation: Give the planner two output classes in 02-03: global user-facing maps and context/plugin-local maps. [VERIFIED: codebase grep][ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Neovim | Implementing and validating keymap behavior | ✓ [VERIFIED: local command] | `NVIM v0.12.1` [VERIFIED: local nvim --version] | — |
| `git` | Repo diff/commit flow for phase artifacts | ✓ [VERIFIED: local command] | installed, version not probed because Phase 2 planning does not depend on a git feature gate [VERIFIED: local command] | — |
| `rg` | Fast mapping inventory and duplicate-grep verification | ✓ [VERIFIED: local command] | installed, version not probed because Phase 2 planning only needs command presence [VERIFIED: local command] | `grep` if required [ASSUMED] |

**Missing dependencies with no fallback:** None found for planning this phase. [VERIFIED: local command]

**Missing dependencies with fallback:** None found for planning this phase. [VERIFIED: local command]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None found in `.config/nvim` [VERIFIED: .planning/codebase/TESTING.md] |
| Config file | none — see Wave 0 [VERIFIED: .planning/codebase/TESTING.md] |
| Quick run command | `nvim --headless "+qa"` for startup safety, plus `rg -n "vim\\.keymap\\.set|keys\\s*=\\s*\\{" .config/nvim/lua` for duplicate audit [VERIFIED: local nvim --version][VERIFIED: codebase grep] |
| Full suite command | `nvim --headless "+Lazy! sync" +qa` and `nvim --headless "+checkhealth" +qa` are the current practical validation path documented in repo analysis [VERIFIED: .planning/codebase/TESTING.md] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| KEY-01 | All custom keymaps have one central declaration site [VERIFIED: .planning/REQUIREMENTS.md] | static audit | `rg -n "vim\\.keymap\\.set|keys\\s*=\\s*\\{" .config/nvim/lua` and verify remaining hits are only approved registry/apply modules plus plugin-internal tables intentionally fed from registry [VERIFIED: codebase grep] | ❌ Wave 0 [VERIFIED: .planning/codebase/TESTING.md] |
| KEY-02 | Domain groups and descriptions are coherent and discoverable [VERIFIED: .planning/REQUIREMENTS.md] | manual + smoke | `nvim --headless "+qa"` for startup, then interactive `which-key` review in a normal session because no automated UI test exists [VERIFIED: local nvim --version][VERIFIED: .planning/codebase/TESTING.md][CITED: https://github.com/folke/which-key.nvim] | ❌ Wave 0 [VERIFIED: .planning/codebase/TESTING.md] |
| KEY-03 | Plugin actions trigger from centralized mappings with no hidden duplicates [VERIFIED: .planning/REQUIREMENTS.md] | smoke + static audit | `nvim --headless "+qa"` plus duplicate grep, followed by manual checks for `fzf-lua`, LSP attach, neo-tree, and `ufo` [VERIFIED: local nvim --version][VERIFIED: codebase grep][VERIFIED: .planning/codebase/TESTING.md] | ❌ Wave 0 [VERIFIED: .planning/codebase/TESTING.md] |

### Sampling Rate
- **Per task commit:** `nvim --headless "+qa"` and the duplicate grep audit [VERIFIED: local nvim --version][VERIFIED: codebase grep]
- **Per wave merge:** `nvim --headless "+checkhealth" +qa` plus manual workflow smoke for search/code/git/explorer/buffer domains [VERIFIED: .planning/codebase/TESTING.md][VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]
- **Phase gate:** Startup smoke green, duplicate grep reduced to approved locations, and direct-key inventory reviewed before any direct-key removals [VERIFIED: codebase grep][VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md]

### Wave 0 Gaps
- [ ] No automated test harness exists for Neovim config behavior in this repo. [VERIFIED: .planning/codebase/TESTING.md]
- [ ] No scripted assertion currently checks that all custom user-facing maps come from approved registry modules only. [VERIFIED: codebase grep][ASSUMED]
- [ ] No non-interactive coverage exists for `which-key` grouping or plugin-buffer-local mapping correctness. [VERIFIED: .planning/codebase/TESTING.md][CITED: https://github.com/folke/which-key.nvim]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: codebase grep] | Not applicable to this editor-config phase [VERIFIED: codebase grep] |
| V3 Session Management | no [VERIFIED: codebase grep] | Not applicable to this editor-config phase [VERIFIED: codebase grep] |
| V4 Access Control | no [VERIFIED: codebase grep] | Not applicable to this editor-config phase [VERIFIED: codebase grep] |
| V5 Input Validation | yes [VERIFIED: codebase grep] | Keep mapping callbacks argument-safe and preserve buffer/plugin scope boundaries instead of applying context actions globally [VERIFIED: codebase grep][CITED: https://neovim.io/doc/user/api/] |
| V6 Cryptography | no [VERIFIED: codebase grep] | Never hand-roll crypto; none is needed here [VERIFIED: codebase grep] |

### Known Threat Patterns for Neovim keymap centralization
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Context-specific action exposed globally by mistake | Elevation/Tampering [ASSUMED] | Preserve `buffer = bufnr` and plugin-local application paths in registry emitters [VERIFIED: codebase grep][CITED: https://neovim.io/doc/user/api/] |
| Duplicate bindings execute a stale or unintended action | Tampering [ASSUMED] | Add duplicate-grep verification and remove user-facing key ownership from plugin files [VERIFIED: codebase grep][VERIFIED: .planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md] |
| External-action mappings become shell-string based during refactor | Tampering [VERIFIED: .planning/codebase/CONCERNS.md] | Keep callback functions and existing helper-based path opening instead of interpolated shell commands [VERIFIED: .planning/codebase/CONCERNS.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md` - locked decisions, discretion, and phase scope [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - `KEY-01` through `KEY-03` requirement text [VERIFIED: local file]
- `.planning/ROADMAP.md` - 3-plan phase decomposition and success criteria [VERIFIED: local file]
- `.config/nvim/lua/core/keymaps.lua` - current global/direct mapping inventory [VERIFIED: local file]
- `.config/nvim/lua/plugins/fzflua.lua` - current lazy `keys = {}` pattern [VERIFIED: local file]
- `.config/nvim/lua/plugins/lsp.lua` - current buffer-local `LspAttach` mapping pattern [VERIFIED: local file]
- `.config/nvim/lua/plugins/neotree.lua` - current plugin-local mapping tables and global explorer entry maps [VERIFIED: local file]
- `.config/nvim/lua/plugins/ufo.lua` - direct fold mappings outside the core file [VERIFIED: local file]
- `.config/nvim/lua/plugins/misc.lua` - existing `which-key` installation and contextual plugin key tables [VERIFIED: local file]
- `.config/nvim/lazy-lock.json` - pinned plugin revisions for `lazy.nvim`, `which-key.nvim`, and neo-tree [VERIFIED: local file]
- `https://neovim.io/doc/user/api/` - official mapping API details for callbacks, descriptions, and buffer-local mapping support [CITED: https://neovim.io/doc/user/api/]
- `https://lazy.folke.io/` - official `lazy.nvim` docs describing lazy-loading on key mappings and multi-file spec usage [CITED: https://lazy.folke.io/]
- `https://github.com/folke/which-key.nvim` - official README for group metadata, `add()`, and spec usage [CITED: https://github.com/folke/which-key.nvim]

### Secondary (MEDIUM confidence)
- `.planning/codebase/STRUCTURE.md` - current repo layout summary [VERIFIED: local file]
- `.planning/codebase/CONCERNS.md` - fragility notes around neo-tree and shell-launch helpers [VERIFIED: local file]
- `.planning/codebase/TESTING.md` - current validation path and absence of tests [VERIFIED: local file]

### Tertiary (LOW confidence)
- None. All externally cited claims were taken from official docs or local verified sources. [VERIFIED: local research notes]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - backed by local runtime/lockfile verification plus official Neovim, `lazy.nvim`, and `which-key` docs. [VERIFIED: local nvim --version][VERIFIED: lazy-lock.json][CITED: https://neovim.io/doc/user/api/][CITED: https://lazy.folke.io/][CITED: https://github.com/folke/which-key.nvim]
- Architecture: HIGH - directly derived from the repo’s current fragmentation points and the official capabilities of the existing stack. [VERIFIED: codebase grep][CITED: https://lazy.folke.io/][CITED: https://neovim.io/doc/user/api/][CITED: https://github.com/folke/which-key.nvim]
- Pitfalls: MEDIUM - grounded in verified current code patterns, with some failure-mode language inferred from those patterns. [VERIFIED: codebase grep][ASSUMED]

**Research date:** 2026-04-14 [VERIFIED: local system date]
**Valid until:** 2026-05-14 for stack and docs, or until the repo’s keymap/plugin architecture changes materially. [ASSUMED]
