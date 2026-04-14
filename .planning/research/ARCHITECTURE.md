# Architecture Research

**Domain:** Cross-platform Neovim configuration modernization
**Researched:** 2026-04-14
**Confidence:** HIGH

## Standard Architecture

### System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                    Bootstrap / Runtime                      │
├─────────────────────────────────────────────────────────────┤
│ init.lua → lazy.nvim bootstrap → plugin discovery          │
├─────────────────────────────────────────────────────────────┤
│                    Core Policy Layer                        │
├─────────────────────────────────────────────────────────────┤
│ options │ platform helpers │ commands │ keymap registry    │
├─────────────────────────────────────────────────────────────┤
│                    Feature Modules                          │
├─────────────────────────────────────────────────────────────┤
│ lsp │ completion │ formatting │ tree │ search │ git │ ui   │
├─────────────────────────────────────────────────────────────┤
│                 Validation / Health Layer                   │
├─────────────────────────────────────────────────────────────┤
│ checkhealth │ headless smoke tests │ profile / audit        │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Bootstrap | Load core config and plugin manager safely | `init.lua` plus minimal bootstrap logic |
| Core policy | Own editor defaults, shared helpers, and platform guards | `lua/core/*.lua` + small utility modules |
| Keymap registry | Define every custom mapping in one place | one file or one table-driven registry |
| Feature modules | Configure plugin domains without owning global behavior | `lua/plugins/*.lua` |
| Validation layer | Catch breakage after refactors and plugin updates | headless commands, health docs, optional scripts |

## Recommended Project Structure

```text
.config/nvim/
├── init.lua
├── lua/
│   ├── core/
│   │   ├── options.lua
│   │   ├── platform.lua
│   │   ├── commands.lua
│   │   ├── keymaps.lua
│   │   └── health.lua
│   ├── plugins/
│   │   ├── lsp.lua
│   │   ├── editor.lua
│   │   ├── ui.lua
│   │   ├── navigation.lua
│   │   └── ...
│   └── util/
│       ├── os.lua
│       ├── paths.lua
│       └── guards.lua
└── README.md
```

### Structure Rationale

- **`core/`:** global policy belongs here, not spread across plugins
- **`platform.lua` / `util/os.lua`:** one place to abstract Windows vs Linux behavior
- **`commands.lua` + `keymaps.lua`:** commands first, mappings second; easier to test and reorganize
- **`plugins/`:** plugin modules should declare plugin behavior, not global UX policy

## Architectural Patterns

### Pattern 1: Central Command Registry

**What:** Define reusable commands/functions first, then bind keys to them centrally  
**When to use:** Any action shared across keymaps or platforms  
**Trade-offs:** Slight upfront structure cost, large maintainability gain

### Pattern 2: Platform Guard Wrapper

**What:** One helper decides how to open paths, detect OS, and call shell tools  
**When to use:** Any command touching shell, filesystem, path separators, or external apps  
**Trade-offs:** More indirection, much better portability

### Pattern 3: Thin Plugin Modules

**What:** Plugin files should use `opts`/small `config` blocks and avoid owning global policy  
**When to use:** Most plugin setup, especially lazy-loaded ones  
**Trade-offs:** Requires stronger shared core utilities, but avoids config sprawl

## Data Flow

### Request Flow

```text
Neovim startup
    ↓
init.lua
    ↓
core policy load
    ↓
lazy.nvim plugin registration
    ↓
user action / event
    ↓
command helper
    ↓
plugin API / Neovim API / external tool
```

### State Management

```text
Config files
    ↓
Neovim runtime state
    ↓
Plugin-local state
    ↓
External tool availability
```

### Key Data Flows

1. **Startup flow:** bootstrap → core policy → lazy spec registration → event/key-driven plugin activation
2. **User action flow:** keymap → command helper → plugin or built-in API → editor state update

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Single machine | Minimal guard wrappers are enough |
| Linux + Windows + multiple machines | Dedicated platform helper layer becomes mandatory |
| Large plugin surface / long-lived repo | Health checks, audit docs, and stricter module boundaries become mandatory |

### Scaling Priorities

1. **First bottleneck:** scattered global behavior, especially keymaps and quit/save hooks
2. **Second bottleneck:** plugin drift against Neovim and ecosystem updates

## Anti-Patterns

### Anti-Pattern 1: Plugin Files Owning Global UX

**What people do:** put mappings, shell commands, and policy decisions inside every plugin file  
**Why it's wrong:** behavior becomes impossible to audit or port cleanly  
**Do this instead:** centralize commands/keymaps, leave plugin files thin

### Anti-Pattern 2: Shell-Specific Runtime Logic

**What people do:** call `xdg-open`, assume POSIX paths, assume Unix binaries  
**Why it's wrong:** Windows breaks immediately  
**Do this instead:** route through `vim.ui.open()` and platform helpers

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| GitHub plugin repos | lazy bootstrap + lockfile | Pin versions; upgrade deliberately |
| Mason package registry | tool install abstraction | Best fit for cross-platform editor tooling |
| Local OS shell | wrapped helper calls | Must not leak platform assumptions everywhere |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `core/*` ↔ `plugins/*` | direct Lua module calls | Core owns policy; plugins consume helpers |
| `commands.lua` ↔ `keymaps.lua` | function/table registry | Keeps bindings thin |
| `platform helpers` ↔ feature modules | helper API | Single source for OS branching |

## Sources

- `.planning/codebase/ARCHITECTURE.md`
- `.planning/codebase/STRUCTURE.md`
- https://github.com/folke/lazy.nvim
- https://github.com/mason-org/mason-lspconfig.nvim
- https://neovim.io/doc/user/lua.html

---
*Architecture research for: cross-platform Neovim configuration modernization*
*Researched: 2026-04-14*
