# Phase 3: Plugin Audit and Validation Harness - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Audit the current Neovim plugin set, record an explicit keep/remove/replace decision for every plugin, add a repeatable validation harness for startup/sync/health checks, and harden missing-tool behavior so the config fails gracefully with actionable guidance. This phase is about creating a safe foundation for aggressive cleanup, not doing the broader ecosystem modernization work reserved for Phase 4.

</domain>

<decisions>
## Implementation Decisions

### Audit strictness
- **D-01:** Phase 3 should use an aggressive audit posture.
- **D-02:** Plugins should not be kept by inertia; each plugin must earn its place based on strong day-to-day value, reliability, and fit with the cleaned-up cross-platform config.
- **D-03:** Novelty, redundant, weakly justified, stale, or drift-prone plugins should be considered removal candidates by default unless there is a clear reason to keep them.

### Validation harness
- **D-04:** Phase 3 should produce a strong validation harness rather than docs-only notes or a thin wrapper.
- **D-05:** The harness should cover startup validation, plugin sync/update safety, health verification, and smoke checks that are useful during aggressive plugin cleanup.
- **D-06:** The validation flow should be repeatable and repo-owned so the maintainer can run the same checks after audit decisions and lockfile refreshes.

### Missing-tool behavior
- **D-07:** Missing external tools should use a health-first policy.
- **D-08:** Runtime behavior should degrade gracefully where possible instead of becoming noisy during normal startup.
- **D-09:** Missing tools should be surfaced clearly through the validation/health workflow with actionable guidance rather than relying on startup warnings as the primary mechanism.

### Audit artifact format
- **D-10:** Phase 3 must produce a full plugin inventory.
- **D-11:** Every current plugin must receive an explicit keep, remove, or replace decision with rationale recorded.
- **D-12:** Implicit keep decisions are not acceptable for this phase; the inventory itself is part of the deliverable.

### the agent's Discretion
- Exact inventory document shape, ordering, and fields, as long as every plugin receives an explicit decision and rationale
- Exact harness entrypoint shape, such as script, Make target, shell command, or documented Neovim command wrapper
- Exact mechanism for surfacing missing tools in health output and validation results, as long as normal runtime stays graceful
- Exact grouping of plugins into audit categories, as long as the final output still records a per-plugin decision

</decisions>

<specifics>
## Specific Ideas

- The user wants Phase 3 to be the safe foundation for aggressive plugin cleanup, not a timid inventory pass.
- The validation harness should be strong enough to protect aggressive churn in the plugin set and lockfile.
- Missing-tool guidance should be clear and actionable without turning startup into a warning-heavy experience.
- The plugin audit artifact should read like a complete ledger, not a partial changelog.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked decisions
- `.planning/ROADMAP.md` — Phase 3 goal, plan breakdown, and success criteria for plugin audit, validation harness, and lockfile cleanup
- `.planning/REQUIREMENTS.md` — `PLUG-01`, `PLUG-03`, `TOOL-01`, and `TOOL-03`
- `.planning/PROJECT.md` — project constraints: one shared config, aggressive cleanup allowed, cross-platform reliability still takes priority
- `.planning/phases/01-reliability-and-portability-baseline/01-CONTEXT.md` — Phase 1 portability and graceful runtime decisions that Phase 3 must preserve
- `.planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md` — Phase 2 centralized keymap architecture that plugin audit work must respect

### Codebase analysis and known risks
- `.planning/codebase/STACK.md` — current plugin/tooling stack and platform/runtime expectations
- `.planning/codebase/STRUCTURE.md` — plugin file layout and where Phase 3 changes will land
- `.planning/codebase/CONCERNS.md` — existing plugin drift, validation gaps, and fragile integrations already identified

### Current plugin and validation surfaces
- `.config/nvim/lazy-lock.json` — current lockfile with historical drift that Phase 3 must audit and refresh
- `.config/nvim/README.md` — current smoke checklist baseline that can inform, but should not be the final harness
- `.config/nvim/init.lua` — startup bootstrap path used by headless validation
- `.config/nvim/lua/plugins/*.lua` — authoritative plugin inventory source for audit decisions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.config/nvim/lua/plugins/`: one-file-per-plugin-domain layout already gives Phase 3 a natural source for building the inventory and mapping decisions back to code
- `.config/nvim/lazy-lock.json`: current pinned state provides the baseline for detecting stale entries, mismatches, and post-audit lockfile cleanup
- `.config/nvim/README.md`: already contains a minimal smoke checklist (`nvim --headless "+qa"` and a few interactive checks) that can seed the stronger validation harness
- `.config/nvim/lua/core/open.lua`: demonstrates the Phase 1 pattern of graceful user-facing failure handling, which is the right behavioral baseline for missing-tool hardening

### Established Patterns
- Core behavior lives under `lua/core/`, while plugin ownership and configuration live under `lua/plugins/`
- The repo currently mixes plugin-spec styles: plain specs, grouped arrays, dependencies, lazy-loaded keys, and large inline config tables
- Prior phases already favored centralization and explicit control planes, so Phase 3 should prefer explicit audit artifacts and a clear validation entrypoint rather than scattered notes

### Integration Points
- `.config/nvim/init.lua` and `require("lazy").setup("plugins")` are the startup path the harness must validate in headless mode
- `.config/nvim/lua/plugins/lsp.lua` is the main missing-tool pressure point because it defines Mason installs, LSP servers, and formatter/tool expectations
- `.config/nvim/lua/plugins/notify.lua`, `.config/nvim/lua/plugins/lualine.lua`, `.config/nvim/lua/plugins/neotree.lua`, and `.config/nvim/lua/plugins/misc.lua` are strong audit targets because they contain known drift, fragile cross-plugin coupling, or broad plugin sprawl
- `.config/nvim/lua/plugins/colortheme.lua` and `.config/nvim/lazy-lock.json` already show evidence of naming/lock drift that the inventory and refresh work must resolve

</code_context>

<deferred>
## Deferred Ideas

- Broader plugin ecosystem modernization and replacement strategy beyond the audit boundary belongs to Phase 4
- Performance profiling and plugin-startup waste elimination beyond what is necessary for validation safety belongs to Phase 5

</deferred>

---

*Phase: 03-plugin-audit-and-validation-harness*
*Context gathered: 2026-04-15*
