# Project Research Summary

**Project:** Cross-Platform Neovim Dotfiles
**Domain:** Cross-platform Neovim configuration modernization
**Researched:** 2026-04-14
**Confidence:** HIGH

## Executive Summary

This project is not building a new editor config from scratch; it is modernizing an existing brownfield Neovim setup into a stable, cross-platform, maintainable system. The research points to a clear direction: keep the modular `lazy.nvim` foundation, raise the runtime baseline toward Neovim 0.11-era patterns, centralize keymaps and command policy, and wrap OS-specific behavior behind helpers instead of shell-specific commands.

The main risk is not “choosing the wrong plugin.” It is changing too much at once without a safety net. The roadmap should therefore start with reliability and portability, then centralize keymaps and add validation, then modernize plugin and LSP architecture, and only then spend effort on polish and optimization.

## Key Findings

### Recommended Stack

Keep `lazy.nvim` as the plugin manager, keep Lua modules as the config structure, and treat Neovim 0.11 as the target modern baseline for future-facing decisions. Use Mason for cross-platform tooling where practical, keep `blink.cmp` and Treesitter as likely-modern foundations unless audit findings show hard blockers, and replace Linux-specific runtime calls with Neovim APIs like `vim.ui.open()`.

**Core technologies:**
- Neovim 0.11.x baseline: native APIs and current ecosystem direction
- `lazy.nvim`: plugin management, lockfile, profiling, modular loading
- Mason + `mason-lspconfig`: cross-platform tooling with explicit 0.11 migration strategy

### Expected Features

For this domain, “features” mostly mean quality guarantees for the config itself.

**Must have (table stakes):**
- Stable startup across Arch Linux, Debian/Ubuntu, and Windows
- Predictable buffer/save/quit behavior
- Centralized keymaps
- Repeatable health checks and smoke tests

**Should have (competitive):**
- Aggressive plugin audit with explicit keep/remove/replace reasoning
- Structured portability layer
- Command taxonomy that makes mappings easy to evolve

**Defer (v2+):**
- Full CI automation across OSes
- Optional machine-role profiles if one shared config later becomes too broad

### Architecture Approach

The recommended architecture is a thin bootstrap, a strong core policy layer, a centralized command/keymap layer, and thinner plugin modules. Plugin files should configure features, while core modules own platform guards, open/path helpers, command abstractions, and editing policy. This separation is the cleanest path to portability and bug reduction.

**Major components:**
1. Bootstrap/runtime: `init.lua` and lazy bootstrap
2. Core policy: options, platform helpers, commands, keymaps
3. Feature modules: LSP, completion, formatting, tree, search, git, UI
4. Validation layer: health checks, headless smoke tests, profiling

### Critical Pitfalls

1. **Scattered keymaps and behavior ownership** — fix with centralized registry and named commands
2. **Platform-specific shell assumptions** — replace with guarded helpers and Neovim APIs
3. **LSP setup frozen on older patterns** — choose explicit 0.11 migration plan
4. **Plugin cleanup without validation** — add smoke tests before aggressive replacement
5. **Over-customized quit/save semantics** — simplify lifecycle behavior before polishing

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Reliability and Portability Baseline
**Rationale:** Fix the config’s most dangerous behaviors first and remove Linux-only assumptions.
**Delivers:** buffer/save/quit fixes, platform helper layer, open/path command cleanup
**Addresses:** stable startup, cross-platform behavior, quit/save bug
**Avoids:** platform-specific shell assumption pitfall

### Phase 2: Keymap and Validation Architecture
**Rationale:** Centralization and safety net should exist before deep plugin churn.
**Delivers:** centralized keymap registry, command taxonomy, documented headless smoke checks
**Uses:** current modular config foundation
**Implements:** core policy and validation architecture

### Phase 3: Plugin and LSP Modernization
**Rationale:** Once behavior is stable and testable, audit/replace plugins and modernize LSP setup.
**Delivers:** keep/remove/replace decisions, cleaned plugin set, explicit Neovim/LSP baseline
**Uses:** stack guidance from research
**Implements:** modern plugin architecture

### Phase 4: Performance and UX Polish
**Rationale:** Final polish matters only after stability and architecture are sound.
**Delivers:** startup tuning, UI cleanup, ergonomic refinements

### Phase Ordering Rationale

- Reliability before aesthetics because current core workflows already break
- Keymap centralization before major plugin swaps because behavior needs one control plane
- Validation before aggressive cleanup because otherwise every plugin change is risky
- LSP modernization after baseline stabilization because ecosystem migration choices affect many files

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3:** Neovim 0.11 migration details and plugin-specific replacement decisions

Phases with standard patterns (skip research-phase if desired):
- **Phase 1:** portability helper abstraction, save/quit bug isolation
- **Phase 2:** keymap centralization and smoke-test workflow

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified against official plugin docs and Neovim docs |
| Features | HIGH | Strongly aligned with user goals and current codebase risks |
| Architecture | HIGH | Derived from current codebase shape plus standard maintainability patterns |
| Pitfalls | HIGH | Directly supported by current config issues and official ecosystem direction |

**Overall confidence:** HIGH

### Gaps to Address

- Exact Neovim version support policy still needs explicit decision during planning
- Final plugin replacement list should be validated against actual usage, not only ecosystem popularity

## Sources

### Primary (HIGH confidence)
- https://github.com/folke/lazy.nvim
- https://github.com/mason-org/mason.nvim
- https://github.com/mason-org/mason-lspconfig.nvim
- https://github.com/folke/noice.nvim
- https://github.com/Saghen/blink.cmp
- https://github.com/nvim-neo-tree/neo-tree.nvim
- https://neovim.io/doc/user/lua.html

### Secondary (MEDIUM confidence)
- `.planning/codebase/STACK.md`
- `.planning/codebase/ARCHITECTURE.md`
- `.planning/codebase/CONCERNS.md`

---
*Research completed: 2026-04-14*
*Ready for roadmap: yes*
