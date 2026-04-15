# Phase 4: Tooling and Ecosystem Modernization - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Modernize the Neovim tooling stack around a current ecosystem baseline by updating LSP, formatting, completion, search, tree, git, and related plugin integration patterns. This phase is about bringing the config to a cleaner, more current standard without major workflow regressions, not about adding unrelated editor capabilities.

</domain>

<decisions>
## Implementation Decisions

### Neovim baseline and LSP architecture
- **D-01:** Phase 4 should treat Neovim `0.11+` as the real baseline.
- **D-02:** The current `0.10` compatibility branching in the LSP setup should be removed where Phase 4 modernization makes it unnecessary.
- **D-03:** LSP modernization should prefer the native `0.11` direction rather than preserving older setup patterns.

### Tool provisioning policy
- **D-04:** Tooling should be Mason-first, not Mason-only.
- **D-05:** The config should declare and prefer a Mason-managed toolset for LSP servers and formatters across Linux and Windows.
- **D-06:** Relevant system binaries may still be used gracefully where they already fit the expected tool contract.

### Replacement posture
- **D-07:** Phase 4 should take a broad modernization pass rather than assuming all currently kept integrations are locked forever.
- **D-08:** Even plugins kept in the Phase 3 audit may be replaced if a cleaner modern alternative is clearly better for this config.
- **D-09:** Plugin replacement should still be justified by fit, maintainability, and workflow quality, not by novelty alone.

### Default editing UX
- **D-10:** The modernized stack should default to a productivity-first editing experience rather than a conservative or minimal one.
- **D-11:** Save-time formatting should be enabled where it is safe and predictable.
- **D-12:** Completion and inline assistance should be richer by default, as long as they do not create obvious instability or noise regressions.
- **D-13:** Helpful inline/editor guidance such as signature help, completion docs, and similar affordances should generally be enabled by default instead of hidden behind opt-in toggles.

### Carry-forward constraints
- **D-14:** One shared config across Linux and Windows remains locked; no forked per-OS config paths.
- **D-15:** OS-specific behavior must stay behind guarded helpers and portable Neovim APIs where possible.
- **D-16:** Keymaps remain centrally managed; modernization must not re-scatter user-facing mappings into plugin files.
- **D-17:** Aggressive cleanup remains valid; plugins do not stay by inertia.

### the agent's Discretion
- Exact migration path from current `lspconfig` setup to the chosen `0.11`-native structure
- Exact plugin replacement list, as long as replacements are justified against the modernization posture above
- Exact save-format safety rules, filetype exclusions, and fallback behavior
- Exact completion, diagnostics, and inline-assistance tuning, as long as the default experience remains productivity-first
- Exact plugin spec normalization strategy across `lua/plugins/*.lua`

</decisions>

<specifics>
## Specific Ideas

- The user explicitly chose a real `0.11+` baseline instead of preserving `0.10` compatibility scaffolding.
- The user wants Mason to be the preferred tool-management path, but not a hard requirement for every machine.
- The user chose a broad modernization pass, meaning even currently kept integrations may be reconsidered if a better modern stack exists.
- The user prefers productivity-first defaults: save-time formatting where safe, richer completion behavior, and more inline help by default.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 4 goal, plan breakdown, and success criteria for tooling and ecosystem modernization
- `.planning/REQUIREMENTS.md` — `PLUG-02` and `TOOL-02`
- `.planning/PROJECT.md` — project-wide constraints: one shared config, OS guards in config, aggressive cleanup allowed

### Locked prior-phase decisions
- `.planning/phases/01-reliability-and-portability-baseline/01-CONTEXT.md` — portability helper and runtime-behavior constraints that modernization must preserve
- `.planning/phases/02-central-command-and-keymap-architecture/02-CONTEXT.md` — centralized keymap architecture that plugin modernization must respect
- `.planning/phases/03-plugin-audit-and-validation-harness/03-CONTEXT.md` — aggressive audit posture, validation expectations, and missing-tool behavior rules

### Phase 3 audit and handoff artifacts
- `.planning/phases/03-plugin-audit-and-validation-harness/03-PLUGIN-AUDIT.md` — authoritative keep/remove/replace decisions and Phase 4 follow-up notes
- `.planning/phases/03-plugin-audit-and-validation-harness/03-AUDIT-RULES.md` — decision framework for when replacement is justified vs removal
- `.planning/phases/03-plugin-audit-and-validation-harness/03-RESEARCH.md` — Phase 3 findings about fragile integration hubs and modernization pressure points
- `.planning/phases/03-plugin-audit-and-validation-harness/03-VALIDATION.md` — validation surfaces that must remain usable after modernization
- `.planning/phases/03-plugin-audit-and-validation-harness/03-VERIFICATION.md` — verified outcomes and regression constraints from the audit phase

### Research baseline for modernization
- `.planning/research/SUMMARY.md` — recommended project-wide direction toward Neovim `0.11`, Mason, and current ecosystem conventions
- `.planning/research/STACK.md` — stack guidance, compatibility notes, and replacement alternatives for major tooling areas
- `.planning/research/PITFALLS.md` — migration pitfalls around LSP baseline changes, plugin churn, and portability regressions

### Existing code and current integration surfaces
- `.planning/codebase/STACK.md` — current runtime and plugin baseline in the repo
- `.planning/codebase/CONCERNS.md` — current fragile areas and known drift affecting modernization choices
- `.planning/codebase/STRUCTURE.md` — file layout and plugin ownership boundaries
- `.config/nvim/lua/plugins/lsp.lua` — current mixed-responsibility LSP and Mason setup
- `.config/nvim/lua/plugins/conform.lua` — formatter routing and save-format baseline
- `.config/nvim/lua/plugins/blink-cmp.lua` — current completion behavior and default UX settings
- `.config/nvim/lua/plugins/fzflua.lua` — current search integration
- `.config/nvim/lua/plugins/neotree.lua` — current file-tree integration and large option surface
- `.config/nvim/lua/plugins/git.lua` — current git workflow integrations
- `.config/nvim/lua/plugins/notify.lua` and `.config/nvim/lua/plugins/lualine.lua` — messaging/UI coupling and replacement pressure around `noice.nvim`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.config/nvim/lua/plugins/lsp.lua`: already centralizes server definitions, Mason installs, LSP attach behavior, diagnostics, and capability wiring, making it the main modernization entry point
- `.config/nvim/lua/plugins/conform.lua`: already centralizes formatter selection by filetype, so save-format policy can be modernized in one place
- `.config/nvim/lua/plugins/blink-cmp.lua`: already uses a current completion engine with rich UI features enabled, so Phase 4 can tune or replace from a strong baseline rather than building from scratch
- `.config/nvim/lua/core/keymaps/` and lazy key registries: provide the central keymap control plane that plugin modernizations should reuse rather than bypass

### Established Patterns
- The repo uses one Lua module per plugin/domain under `.config/nvim/lua/plugins/`
- Plugin declarations are already managed through `lazy.nvim`, so modernization should normalize spec patterns instead of introducing a different plugin architecture
- Prior phases already moved user-facing mappings into a central registry, so plugin files should expose features through that registry rather than reintroducing ad hoc mappings
- Phase 3 established a repo-owned validation harness and health-first missing-tool policy, so modernization should keep using explicit validation rather than startup warnings

### Integration Points
- LSP, Mason, and formatter modernization connect primarily through `.config/nvim/lua/plugins/lsp.lua`, `.config/nvim/lua/plugins/conform.lua`, and the health/validation surfaces added in Phase 3
- Completion, diagnostics, and inline-help choices connect through `.config/nvim/lua/plugins/blink-cmp.lua` plus LSP capability wiring
- Search, tree, and git modernization connect through `.config/nvim/lua/plugins/fzflua.lua`, `.config/nvim/lua/plugins/neotree.lua`, and `.config/nvim/lua/plugins/git.lua`
- Broad plugin replacement decisions must still preserve centralized mapping ownership, portability helpers, and the Phase 3 validation workflow

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 04-tooling-and-ecosystem-modernization*
*Context gathered: 2026-04-15*
