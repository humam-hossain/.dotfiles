# Stack Research

**Domain:** Cross-platform Neovim configuration modernization
**Researched:** 2026-04-14
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Neovim | 0.11.x baseline | Editor runtime and native APIs | Current ecosystem is converging on Neovim 0.11 APIs, especially around LSP and `vim.ui.*` helpers |
| `folke/lazy.nvim` | 11.x | Plugin management, lazy-loading, lockfile | Still standard for modular multi-file configs; official docs emphasize automatic lazy-loading, lockfile support, and profiling |
| Lua | 5.1 / LuaJIT runtime | Configuration language | Native Neovim config language; supports modular architecture and runtime guards cleanly |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mason-org/mason.nvim` | 2.x | Cross-platform tool installer | Use for LSP/formatter binaries that should work on Linux and Windows |
| `mason-org/mason-lspconfig.nvim` | 2.x | Bridge Mason and Neovim 0.11 LSP enablement | Use if migrating to native 0.11 `vim.lsp.config` flow while still wanting Mason-managed installs |
| `saghen/blink.cmp` | 1.x | Completion UI and source integration | Keep if completion UX remains strong; it is current, fast, and actively maintained |
| `nvim-treesitter/nvim-treesitter` | current | Parser-powered highlighting/textobjects | Keep as foundation for syntax, markdown, and docs rendering |
| `stevearc/conform.nvim` | current | Formatter routing | Good fit for centralized formatting policy and filetype-specific formatter fallback |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `:checkhealth` | Runtime diagnostics | Must be part of regression workflow after refactors |
| `nvim --headless "+Lazy! sync" +qa` | Plugin/bootstrap smoke test | Useful for CI-like local validation |
| `nvim --headless "+checkhealth" +qa` | Environment health smoke test | Catches missing binaries and platform drift early |
| `lazy.nvim` profiler | Startup/perf tuning | Use after cleanup to justify plugin replacements |

## Installation

```bash
# Core baseline
# Install Neovim 0.11+ on target OS

# Plugin manager + plugins
# Managed by .config/nvim/init.lua and lazy.nvim bootstrap

# Editor tooling
# Prefer Mason-managed LSPs/formatters where supported
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `lazy.nvim` | `mini.deps` | Use only if plugin count becomes tiny and you want a much smaller dependency surface |
| `blink.cmp` | `nvim-cmp` | Use only if a needed completion source or ecosystem integration is unavailable in blink |
| `neo-tree.nvim` | `oil.nvim` | Use if you want a simpler file-editing UX over a full tree explorer |
| `conform.nvim` | formatter setup via LSP only | Use only if formatter surface becomes very small and you want fewer moving parts |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Hardcoded `xdg-open` calls | Linux-only; breaks portability and duplicates Neovim capability | `vim.ui.open()` with fallback handling |
| Scattered ad hoc keymaps across plugin files | Hard to audit, deconflict, and port | One central keymap registry with plugin-aware handlers |
| Manual per-server `lspconfig` drift without 0.11 plan | Ecosystem now assumes newer native LSP APIs | Define a migration path to Neovim 0.11-native LSP config |
| Unchecked plugin accumulation | Increases startup cost and bug surface | Regular plugin audit with remove/replace/keep decisions |

## Stack Patterns by Variant

**If target machine is Linux:**
- Prefer system package install for Neovim itself
- Use Mason for editor tooling when possible
- Still avoid Linux-only assumptions in runtime config

**If target machine is Windows:**
- Prefer APIs that abstract shell/open behavior (`vim.ui.open`, `vim.system`)
- Minimize assumptions about shell commands, path separators, and binary names

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `mason-lspconfig.nvim@2.x` | Neovim 0.11+, `mason.nvim@2.x`, `nvim-lspconfig@2.x` | Official docs say v2 assumes the new native LSP configuration mechanism |
| `lazy.nvim@11.x` | Modern multi-file Lua config | Lockfile and lazy-loading patterns are stable choices for this project type |
| `blink.cmp@1.x` | Modern Neovim completion stacks | Active release line as of 2026-04 |

## Sources

- https://github.com/folke/lazy.nvim — verified lazy-loading, lockfile, profiling, current release line
- https://github.com/mason-org/mason.nvim — verified cross-platform tool-management positioning
- https://github.com/mason-org/mason-lspconfig.nvim — verified Neovim 0.11-native direction and recommended lazy setup
- https://github.com/Saghen/blink.cmp — verified active maintenance and current completion feature set
- https://neovim.io/doc/user/lua.html — verified `vim.ui.open()` cross-platform API

---
*Stack research for: cross-platform Neovim configuration modernization*
*Researched: 2026-04-14*
