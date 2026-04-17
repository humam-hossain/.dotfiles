# Phase 12: Document nvim config codebase - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning
**Source:** User-provided scope

<domain>
## Phase Boundary

Document the Neovim Lua configuration files in `.config/nvim/lua/` for maintainability and future reference.

</domain>

<decisions>
## Implementation Decisions

### D-01: Documentation Format
- Use todo-comments.nvim for code annotations (TODO: for features, FIXME: for workarounds, NOTE: for context)
- No "===..." banner separators

### D-02: File Coverage
- Document all .lua files in: `lua/core/` and `lua/plugins/`
- Brief, actionable comments per module

### D-03: README Update
- Update `.config/nvim/README.md` with file inventory and purpose

### D-04: Unused Options
- For opts with unused options, comment what those options are in one line

</decisions>

<canonical_refs>
## Canonical References

- `.config/nvim/lua/` — Main Lua config directory
- `.config/nvim/README.md` — Existing documentation
- `.config/nvim/lua/plugins/misc.lua` — Contains todo-comments.nvim plugin

</canonical_refs>

<deferred>
## Deferred Ideas

None

</deferred>

---

*Phase: 12-document-nvim-config-codebase*
*Context gathered: 2026-04-17 via user-provided scope*