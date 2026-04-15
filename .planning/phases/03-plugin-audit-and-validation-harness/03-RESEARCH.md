# Phase 3: Plugin Audit and Validation Harness - Research

**Researched:** 2026-04-15 [VERIFIED: local system date]
**Domain:** Neovim plugin audit, lockfile hygiene, headless validation, and graceful missing-tool behavior for shared dotfiles config [VERIFIED: codebase grep]
**Confidence:** HIGH [VERIFIED: codebase grep]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use aggressive audit posture. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
- **D-02:** Plugins do not stay by inertia; every plugin must earn keep. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
- **D-03:** Redundant, weakly justified, stale, or drift-prone plugins are remove candidates by default. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
- **D-04:** Validation harness must be strong, not docs-only. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
- **D-05:** Harness must cover startup validation, plugin sync/update safety, health verification, and smoke checks. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
- **D-06:** Validation flow must be repeatable and repo-owned. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
- **D-07:** Missing tools follow health-first policy. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
- **D-08:** Runtime should degrade gracefully where possible instead of warning-heavy startup. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
- **D-09:** Missing tools should surface through health/validation output with actionable guidance. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
- **D-10:** Phase must produce full plugin inventory. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
- **D-11:** Every current plugin gets explicit keep/remove/replace decision with rationale. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
- **D-12:** Implicit keep decisions are not acceptable. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]

### Agent Discretion
- Exact audit ledger format. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
- Exact validation entrypoint shape. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
- Exact mechanism for health reporting and missing-tool surfacing. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PLUG-01 | Maintainer can review every existing plugin as keep, replace, or remove with rationale recorded [VERIFIED: .planning/REQUIREMENTS.md] | Build one repo-owned ledger sourced from `lua/plugins/*.lua` plus `lazy-lock.json`, grouped by domain and recording plugin, file owner, dependencies, direct keys, risks, and explicit decision. [VERIFIED: codebase grep] |
| PLUG-03 | User can sync plugins from a refreshed lockfile that reflects audited plugin set [VERIFIED: .planning/REQUIREMENTS.md] | Audit must end with lockfile cleanup after plugin spec decisions, not before. Drift examples already exist (`catppuccin` name mismatch, missing/duplicate entries). [VERIFIED: .planning/codebase/CONCERNS.md][VERIFIED: codebase grep] |
| TOOL-01 | Maintainer can run documented headless smoke checks to catch startup and health regressions [VERIFIED: .planning/REQUIREMENTS.md] | Add one repeatable harness under repo control with startup, sync, health, and targeted smoke commands. Prefer scriptable shell entrypoint plus generated report files. [VERIFIED: .config/nvim/README.md][VERIFIED: codebase grep] |
| TOOL-03 | User gets actionable health information or graceful degradation when required external tools are missing [VERIFIED: .planning/REQUIREMENTS.md] | Harden tool-sensitive plugin surfaces to avoid noisy startup and move tool checks into explicit health reporting. [VERIFIED: .planning/codebase/CONCERNS.md][VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 3 should split into three plan lanes, matching roadmap: first produce plugin audit ledger, then build validation harness, then apply audit decisions to lockfile + missing-tool behavior. Doing lockfile refresh before audit is wrong order because drift status depends on explicit keep/remove/replace decisions. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]

Repo already exposes enough local data to produce deterministic audit artifact without external discovery: plugin spec files under `.config/nvim/lua/plugins/`, lock state in `.config/nvim/lazy-lock.json`, and codebase concern docs naming known drift. Main audit value is not counting plugins; main value is recording ownership, redundancy, fragility, and removal/replacement candidates in one place before Phase 4 modernization starts. [VERIFIED: .planning/codebase/STRUCTURE.md][VERIFIED: .planning/codebase/CONCERNS.md][VERIFIED: codebase grep]

Current config shows concrete drift signals that justify aggressive audit:
- `tpope/vim-fugitive` declared twice across `git.lua` and `misc.lua`. [VERIFIED: codebase grep]
- `folke/noice.nvim` spec uses `even = "VeryLazy"` typo, so lazy-loading intent is already suspect. [VERIFIED: .planning/codebase/CONCERNS.md][VERIFIED: .config/nvim/lua/plugins/notify.lua]
- Lockfile contains `catppucin` mismatch versus `catppuccin` spec name. [VERIFIED: .planning/codebase/CONCERNS.md]
- Some plugin modules are large, high-risk integration hubs (`lsp.lua`, `neotree.lua`, `lualine.lua`, `notify.lua`), so audit should record risk and validation needs per plugin/domain, not only keep/remove label. [VERIFIED: .planning/codebase/CONCERNS.md][VERIFIED: codebase grep]

Best validation shape for this repo is one shell entrypoint under `scripts/` plus one small Lua helper module/command inside `.config/nvim` for machine-readable health output. Shell handles orchestration; Neovim Lua handles editor-native checks like plugin/module load, `lazy` status, and health collection. This keeps harness repeatable on Linux and Windows-adjacent shells while preserving one shared config. [INFERRED from .planning/PROJECT.md, .planning/codebase/STACK.md, and codebase layout]

**Primary recommendation:** Plan 03-01 creates plugin audit ledger and decision rules, 03-02 builds repo-owned headless validation harness with report artifacts, 03-03 applies audited plugin/lockfile cleanup and adds tool-health guards at the most fragile runtime surfaces. [VERIFIED: .planning/ROADMAP.md][INFERRED from codebase evidence]

## Current Plugin Surface

### Inventory Sources
- Authoritative spec sources: `.config/nvim/lua/plugins/*.lua`. [VERIFIED: .planning/codebase/STRUCTURE.md]
- Runtime pin source: `.config/nvim/lazy-lock.json`. [VERIFIED: .planning/codebase/STACK.md]
- Existing manual smoke baseline: `.config/nvim/README.md`. [VERIFIED: .config/nvim/README.md]

### High-Risk Audit Targets
- `.config/nvim/lua/plugins/lsp.lua` — large mixed-responsibility file; most tool-sensitive surface. [VERIFIED: .planning/codebase/CONCERNS.md]
- `.config/nvim/lua/plugins/neotree.lua` — large nested config with optional `image.nvim` and window-picker coupling. [VERIFIED: .planning/codebase/CONCERNS.md][VERIFIED: codebase grep]
- `.config/nvim/lua/plugins/notify.lua` + `.config/nvim/lua/plugins/lualine.lua` — cross-plugin coupling and load-order fragility around `noice`. [VERIFIED: .planning/codebase/CONCERNS.md][VERIFIED: codebase grep]
- `.config/nvim/lua/plugins/misc.lua` — plugin sprawl bucket; likely strongest removal candidate cluster. [VERIFIED: codebase grep]

### Concrete Drift / Smell Findings
- Duplicate plugin declaration: `tpope/vim-fugitive` in both `git.lua` and `misc.lua`. [VERIFIED: codebase grep]
- Typo in lazy event key: `even = "VeryLazy"` in `notify.lua`. [VERIFIED: .config/nvim/lua/plugins/notify.lua]
- Theme drift: active `catppuccin` plus dormant `hackerman.nvim`; lock mismatch already noted. [VERIFIED: .config/nvim/lua/plugins/colortheme.lua][VERIFIED: .planning/codebase/CONCERNS.md]
- Optional/image-heavy dependency `3rd/image.nvim` sits inside file-tree path and may be weak cross-platform fit. [VERIFIED: .config/nvim/lua/plugins/neotree.lua]
- Plugin-local keymaps still exist in plugin files and should be inventoried as part of audit rationale because they affect validation scope. [VERIFIED: codebase grep]

## Recommended Audit Artifact

Use one markdown ledger, likely `03-PLUGIN-AUDIT.md`, with one row per plugin declaration and one normalized row per effective plugin after duplicate resolution. Minimum fields:
- plugin repo / display name
- source file
- feature domain
- dependencies / reverse-coupling
- lazy trigger style (`event`, `keys`, `cmd`, eager)
- external tool dependency if any
- user-facing value
- known risks / drift notes
- decision: `keep`, `remove`, `replace`
- rationale
- follow-up action for Phase 3 vs Phase 4

Planning implication: 03-01 should not only document decisions. It should also define audit rules so future plugin additions can be judged with same standard. [INFERRED]

## Validation Harness Architecture

### Harness Shape
- Shell orchestrator in `scripts/` for portability and CI-friendliness later.
- Neovim-side Lua helper/command for machine-readable health snapshots and plugin load checks.
- Output reports under `.planning/phases/03-plugin-audit-and-validation-harness/` or `.planning/tmp/` so planning artifacts stay inspectable.

### Recommended Checks
1. Startup smoke: `nvim --headless "+qa"` against repo config. [VERIFIED: .config/nvim/README.md]
2. Lazy sync smoke: headless `Lazy! sync`/`Lazy! restore` path with non-interactive exit handling. [INFERRED from stack using lazy.nvim]
3. Health capture: headless command that writes `:checkhealth`-style output or structured summary to file instead of requiring manual buffer inspection. [INFERRED]
4. Plugin load probes for high-risk modules: `notify/noice`, `lualine`, `neo-tree`, `lsp`, `conform`, `treesitter`. [VERIFIED: codebase grep]
5. Optional-tool checks separated from startup: confirm binaries/tools expected by `lsp.lua` and `conform.lua`, but report through explicit health command. [VERIFIED: codebase grep]

### Why Not Docs-Only
Current README only gives minimal manual smoke checklist. That does not protect aggressive plugin churn, does not produce reusable reports, and does not force lockfile/health verification after sync. [VERIFIED: .config/nvim/README.md]

## Validation Architecture

Nyquist strategy for Phase 3 should treat validation harness itself as first-class deliverable:
- **Wave 1 / quick check:** headless startup command plus syntax/load validation for changed Lua files.
- **Wave 2 / full check:** harness entrypoint runs startup + sync + health + tool report generation.
- **Before phase verification:** run full harness after lockfile refresh and after missing-tool hardening lands.

Recommended future commands for execution plans:
- Quick: `nvim --headless "+qa"`
- Full: `./scripts/nvim-validate.sh all`
- Audit-specific: `./scripts/nvim-validate.sh health`

If shell portability becomes issue on Windows, planner should reserve thin wrappers (`bash`, PowerShell, or documented manual fallback) without forking Neovim config itself. [INFERRED from project constraint of one shared codebase]

## Missing-Tool Behavior

Best pattern for this repo:
- Startup path should not eagerly fail on absent non-critical binaries.
- Tool-sensitive features should guard execution, then route user to explicit health guidance.
- Health command should print missing tool, affected feature, likely install path, and severity (`required for formatting`, `optional enhancement`, `needed for language X`). [INFERRED]

Main pressure points:
- `.config/nvim/lua/plugins/lsp.lua` for Mason installs, LSP servers, inlay/doc behavior. [VERIFIED: codebase grep]
- `.config/nvim/lua/plugins/conform.lua` for formatter binaries. [VERIFIED: .config/nvim/lua/plugins/conform.lua]
- `.config/nvim/lua/plugins/treesitter.lua` for parser install/update expectations. [VERIFIED: .config/nvim/lua/plugins/treesitter.lua]
- `.config/nvim/lua/plugins/neotree.lua` optional image support and external helper dependencies. [VERIFIED: .config/nvim/lua/plugins/neotree.lua]

Planning implication: Phase 3 should prefer helper modules or health-report tables over scattered `vim.notify` warnings at startup. [INFERRED from D-07 to D-09]

## Plan Decomposition

### 03-01 Build plugin inventory with keep/remove/replace rationale
- Enumerate all effective plugins from spec files.
- Normalize duplicates and record lockfile mismatches.
- Produce audit ledger with explicit decision + rationale for every plugin.
- Mark Phase 4 handoffs where replacement/modernization is deferred.

### 03-02 Add documented headless smoke checks and health verification workflow
- Create repo-owned validation entrypoint and report files.
- Document exact startup/sync/health commands.
- Add machine-readable health export path for later verification and CI.

### 03-03 Refresh lockfile and harden missing-tool behavior after audit decisions
- Remove dead/duplicate plugin specs chosen by audit.
- Refresh `lazy-lock.json` to match actual audited plugin set.
- Harden tool-sensitive code paths to degrade gracefully and feed health output.

## Common Pitfalls

### Pitfall 1: Refresh lockfile before audit decisions
Causes churn without reducing drift; old plugins stay pinned for no reason. Avoid by sequencing audit first, cleanup second. [INFERRED]

### Pitfall 2: Treat domain bundles as single plugin decisions
Files like `misc.lua` contain many unrelated plugins. Audit must decide per plugin, not per file. [VERIFIED: codebase grep]

### Pitfall 3: Put missing-tool warnings on startup
Violates D-08 and creates noisy editor load. Prefer explicit health command and guarded runtime checks. [VERIFIED: .planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md]

### Pitfall 4: Build harness around only `nvim --headless "+qa"`
Good startup smoke, bad system check. Need sync + health + targeted probes too. [VERIFIED: .config/nvim/README.md][INFERRED]

### Pitfall 5: Remove fragile plugins without recording replacement path
Phase 3 is audit foundation; Phase 4 handles modernization. Audit should state whether removal is final or replacement deferred. [VERIFIED: .planning/ROADMAP.md]

## Assumptions Log

| # | Claim | Risk |
|---|-------|------|
| A1 | Shell-script harness under `scripts/` is acceptable for this dotfiles repo and easier to reuse later in CI | Low |
| A2 | Health export may need a small Lua helper because raw `:checkhealth` output is awkward in headless automation | Medium |
| A3 | Audit ledger should live in phase dir rather than `.config/nvim/README.md` because it is phase artifact first, user doc second | Low |
| A4 | Lockfile refresh belongs in 03-03, not earlier plans | Low |

## Open Questions (RESOLVED)

1. Should duplicate declarations like `vim-fugitive` be resolved as immediate cleanup in 03-03 or only recorded in 03-01 if audit keeps plugin?
   - Recommendation: record in 03-01, fix in 03-03.
2. Should validation harness write reports into phase dir or stable repo path under `scripts/`/`.planning/tmp/`?
   - Recommendation: command in `scripts/`, report output in `.planning/` so results stay inspectable.

## RESEARCH COMPLETE
