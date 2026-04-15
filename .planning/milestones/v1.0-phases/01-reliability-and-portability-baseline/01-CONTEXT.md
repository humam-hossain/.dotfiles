# Phase 1: Reliability and Portability Baseline - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the Neovim config safe to use across Arch Linux, Debian/Ubuntu, and Windows by removing Linux-only runtime assumptions and by defining predictable save, quit, buffer, window, tab, and autosave behavior. This phase is about reliability and portability of existing editing flows, not adding new editor capabilities.

</domain>

<decisions>
## Implementation Decisions

### Buffer, Window, and Tab Model
- **D-01:** The config is buffer-first. Buffer close actions should operate on the current buffer, not implicitly on windows or the full Neovim session.
- **D-02:** Windows are layout only. Split/window management should stay separate from buffer lifecycle behavior.
- **D-03:** Tabs are explicit workspaces and must never be touched by normal buffer-close shortcuts unless the user invokes tab-specific commands directly.

### Close Semantics
- **D-04:** `<C-q>` should close the current buffer only.
- **D-05:** `<C-q>` must never implicitly exit the full Neovim session.
- **D-06:** If the current buffer has unsaved changes, close behavior should respect normal save/confirm behavior rather than force-discarding or silently quitting.

### Autosave Policy
- **D-07:** Autosave should be minimal rather than aggressive.
- **D-08:** Autosave should be limited to conservative, safe cases such as `FocusLost`, not on every `BufLeave`, `TextChanged`, or `InsertLeave`.
- **D-09:** Autosave must be restricted to normal file buffers and must not write special, unsupported, or transient buffers.

### External Open Behavior
- **D-10:** External open behavior should use one OS-aware helper that opens with the system default application.
- **D-11:** The same helper should be shared by core keymaps and neo-tree actions so behavior stays consistent across entry points.
- **D-12:** The helper should describe generic external opening, not browser-specific behavior.

### the agent's Discretion
- Exact helper/module placement for OS-aware open behavior
- Exact buffer-safety guards for autosave exclusions
- Exact user-facing keymap descriptions and command naming, as long as they preserve the decisions above

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 1 goal, plan breakdown, and success criteria for reliability and portability baseline work
- `.planning/REQUIREMENTS.md` — `PLAT-01`, `PLAT-02`, `PLAT-03`, `PLAT-04`, `CORE-01`, `CORE-02`, and `CORE-03`
- `.planning/PROJECT.md` — project-level constraints: one shared config repo, OS-specific guards in config, aggressive cleanup allowed

### Research and codebase analysis
- `.planning/research/SUMMARY.md` — recommends guarded helpers for platform-specific behavior and documents smoke-test direction
- `.planning/research/PITFALLS.md` — identifies Linux-only command assumptions and early-phase portability risks
- `.planning/codebase/CONCERNS.md` — flags autosave fragility and recommends stronger exclusions around non-file buffers
- `.planning/codebase/STACK.md` — platform/runtime expectations for the Neovim config

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.config/nvim/lua/core/keymaps.lua`: already holds the current save, quit, buffer, split, and external-open keymaps that Phase 1 will normalize
- `.config/nvim/lua/plugins/neotree.lua`: already defines custom neo-tree commands and is the natural integration point for shared external-open behavior
- `.config/nvim/lua/core/options.lua`: already establishes editor-wide tab, split, and window defaults that planning must keep consistent with the chosen buffer-first model

### Established Patterns
- Core editor behavior currently lives in `core/` modules, while plugin-specific behavior lives in `plugins/` modules
- The config already uses Lua callbacks for keymaps and autocommands, so OS guards and save/close policy can be centralized without changing the overall architecture
- Plugin loading is already modular through `lazy.nvim`, so helper extraction should fit the existing structure rather than introducing a separate config fork per OS

### Integration Points
- `core.keymaps` is the primary place to replace the current smart-quit and aggressive autosave behavior
- `neo-tree` custom commands should call the same external-open helper used by core keymaps
- Any portability helper introduced in this phase must be callable from both core and plugin code

</code_context>

<specifics>
## Specific Ideas

- Use a single OS-aware "open with default application" helper instead of Linux-only shell commands
- Treat buffers as the primary editing unit; windows are just layout and tabs are explicit workspaces
- Keep autosave conservative and limited to normal file buffers

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-reliability-and-portability-baseline*
*Context gathered: 2026-04-14*
