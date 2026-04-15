# Phase 4 Research: Tooling and Ecosystem Modernization

**Phase:** 04
**Researched:** 2026-04-15
**Confidence:** HIGH

## Objective

Answer planning question for Phase 4: what must change in this Neovim config to reach a modern `0.11+` tooling baseline without breaking daily LSP, completion, formatting, tree/search, and git workflows across Linux and Windows?

## Constraints Carried Forward

- Neovim `0.11+` is real baseline; Phase 4 should remove `0.10` compatibility branching where modernization makes it obsolete.
- Mason is preferred provisioning path, but config must still degrade gracefully when tools come from system packages instead.
- One shared config remains mandatory across Linux and Windows.
- User-facing mappings stay centralized; modernization must not re-scatter keymaps into plugin specs.
- Validation harness from Phase 3 is required safety net for all plugin/tool churn.

## Current State Summary

### Strong Foundations To Keep

- `lazy.nvim` multi-file plugin architecture already fits project goals.
- `blink.cmp` is already modern, active, and configured for richer completion UX.
- `conform.nvim` already centralizes formatter routing.
- `fzf-lua`, `neo-tree`, `gitsigns`, and `vim-fugitive` cover required workflow domains with current ecosystem relevance.
- Phase 3 delivered repo-owned validation and missing-tool health reporting, which reduces modernization risk.

### Main Modernization Pressure Points

- `.config/nvim/lua/plugins/lsp.lua` is still mixed-responsibility and uses `lspconfig[server].setup(...)` plus `0.10/0.11` branching.
- Mason package names and LSP server names are mixed in one table, making drift likely.
- Save-format behavior is commented out in `conform.lua`, which conflicts with locked productivity-first defaults for Phase 4.
- Plugin spec patterns are inconsistent across files: some use `opts`, some `config`, some embed large setup logic directly.
- `neo-tree` config remains large and fragile; safe to keep, but its surface area should be normalized and trimmed where possible.

## Recommended Modern Baseline

### LSP and Mason

- Move to Neovim `0.11` native LSP registration pattern built around `vim.lsp.config()` and `vim.lsp.enable()`.
- Keep `nvim-lspconfig`, `mason.nvim`, `mason-lspconfig.nvim`, and `mason-tool-installer.nvim`.
- Split responsibilities in LSP config:
  - diagnostics + attach/autocmd policy
  - server definitions
  - Mason install list
  - enable/setup bridge
- Keep Mason-first provisioning, but avoid assuming Mason owns every binary at runtime.
- Keep `blink.cmp` capability extension, but clean capability merge path and remove obsolete compatibility helpers.

### Formatting

- Keep `conform.nvim`.
- Turn on save-time formatting with explicit safety rules instead of leaving it commented out.
- Use `lsp_format = "fallback"` or equivalent predictable fallback so language formatting still works when formatter is intentionally absent.
- Define exclusions for buffers/filetypes where save-format is unsafe or noisy.
- Keep formatter selection centralized in one file; do not push format logic back into LSP server config.

### Completion, Search, Tree, Git

- Completion: keep `blink.cmp`; tune only if needed for docs/signature/ghost-text noise.
- Search: keep `fzf-lua`; no strong evidence for replacement.
- Tree: keep `neo-tree`; modernize config shape and dependency choices rather than swapping unless a specific drift issue appears.
- Git: keep `gitsigns.nvim` and `vim-fugitive`; no ecosystem pressure to replace.

### Replace / Remove Candidates

- Re-evaluate optional or weak integrations left alive after Phase 3 if they fight modernization or add cross-plugin fragility.
- `noice.nvim` stays candidate for replacement only if its coupling keeps leaking into unrelated UI modules; otherwise keep and simplify.
- Large bespoke config blocks should be reduced before replacing whole plugins by default.

## Plugin-Spec Normalization Direction

- Prefer `opts = function()` or `opts = {}` when plugin supports it cleanly; reserve `config = function()` for plugins needing imperative setup.
- Keep one plugin/domain per file unless a file intentionally groups tightly related specs.
- Move reusable helpers out of giant inline config functions when they are not plugin-specific.
- Avoid duplicate responsibility inside one file: install lists, diagnostics policy, keymaps, and runtime guards should not be tangled.
- Keep lazy triggers explicit and boring: `event`, `cmd`, `keys`, `ft`, or `lazy = false` only when justified.

## Risks and Migration Pitfalls

### Risk 1: Half-Migrated LSP Pattern

If Phase 4 mixes old `require("lspconfig")[server].setup(...)` and new `vim.lsp.config()` flows, debugging becomes worse, not better.

**Planner implication:** one plan must own complete LSP baseline migration end-to-end.

### Risk 2: Save-Format Regressions

Enabling format-on-save globally without exclusions can reintroduce editing friction or touch unsupported buffers.

**Planner implication:** formatting plan must define safe filetype/buftype/path policy plus validation cases.

### Risk 3: Plugin Churn Without Workflow Coverage

Swapping multiple major integrations at once can break daily editing flow even when startup passes.

**Planner implication:** each plan needs feature smoke coverage tied to `scripts/nvim-validate.sh` plus a manual workflow checklist.

### Risk 4: Central Keymap Architecture Drift

Plugin upgrades often tempt inline `keys = ...` additions inside plugin specs.

**Planner implication:** plans must explicitly preserve central keymap ownership and route any new commands through existing registry patterns.

### Risk 5: Windows / Mason Assumption Gaps

A Mason-first design can still fail if runtime logic assumes Mason install paths or Linux binary names.

**Planner implication:** plans must keep system-binary fallback behavior and use Phase 3 health metadata as guardrail.

## Validation Implications

Phase 4 plans should reuse and extend existing harness coverage:

- `./scripts/nvim-validate.sh startup`
- `./scripts/nvim-validate.sh sync`
- `./scripts/nvim-validate.sh health`
- `./scripts/nvim-validate.sh smoke`

Additional manual smoke targets planner should include:

- open file, attach LSP, jump/rename/code action/diagnostics
- save-time formatting for representative filetypes
- completion docs, ghost text, signature help
- `fzf-lua` file search and live grep
- `neo-tree` open, preview, rename, external open
- `gitsigns` indicators and fugitive commands

## Recommended 3-Plan Decomposition

### 04-01: Modernize LSP and Mason Architecture

Own Neovim `0.11+` LSP baseline migration. Refactor `.config/nvim/lua/plugins/lsp.lua` into cleaner responsibility boundaries, remove `0.10` compatibility shims, normalize server/tool definitions, and preserve centralized LSP key attachment behavior.

**Primary files:** `.config/nvim/lua/plugins/lsp.lua`, related health/README files only if required by new tool metadata or docs.

### 04-02: Modernize Formatting, Completion, Search, Tree, and Git Integrations

Own workflow-facing tooling behavior after LSP baseline lands. Enable safe save-format defaults, tune `blink.cmp` productivity defaults if needed, and clean integration edges in `fzf-lua`, `neo-tree`, and git modules without breaking central keymap ownership.

**Primary files:** `.config/nvim/lua/plugins/conform.lua`, `.config/nvim/lua/plugins/blink-cmp.lua`, `.config/nvim/lua/plugins/fzflua.lua`, `.config/nvim/lua/plugins/neotree.lua`, `.config/nvim/lua/plugins/git.lua`, any central keymap registry files only where wiring is required.

### 04-03: Replace Weak or Outdated Patterns and Normalize Plugin Specs

Own final cleanup pass. Replace or simplify fragile/outdated integrations where justified, normalize plugin spec patterns across touched files, refresh lockfile if plugin set changes, and update docs/validation notes to reflect final modern baseline.

**Primary files:** touched plugin spec files across `lua/plugins/*.lua`, `.config/nvim/lazy-lock.json`, `.config/nvim/README.md`, and Phase 4 verification docs if workflow expects them later.

## Planning Guidance

- Do not spend a plan on re-auditing Phase 3 decisions; Phase 4 should execute modernization, not reopen every prior argument.
- Prefer “keep and modernize” over “replace by novelty”.
- Keep changes sliced by risk domain, not by raw file count.
- Every plan must state validation explicitly because TOOL-02 is workflow-facing, not docs-only.

## Ready For Planning

Yes. Research points to a clear plan split:

1. LSP/Mason baseline migration.
2. Workflow tooling modernization.
3. Cleanup/replacements/spec normalization.

This split matches ROADMAP 04-01, 04-02, and 04-03 while preserving bounded risk and checker-friendly verification.
