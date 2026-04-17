# Phase 10: Resolve noice.nvim / UX-01 - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Remove noice.nvim entirely from the Neovim config. This restores native Vim cmdline and makes UX-01 accurate without any wording update — "snacks replacing noice" holds once the plugin is gone.

</domain>

<decisions>
## Implementation Decisions

### noice.nvim Removal
- **D-01:** Delete the entire noice.nvim plugin block from `.config/nvim/lua/plugins/misc.lua`
- **D-02:** Remove `MunifTanjim/nui.nvim` — confirmed not used by any other plugin (grep clean)
- **D-03:** `nvim-lua/plenary.nvim` stays — used by `todo-comments.nvim`
- **D-04:** Native Vim cmdline (`:` prompt in statusline) is acceptable — no replacement needed
- **D-05:** UX-01 wording unchanged — removal makes the existing claim accurate

### UX-01 Requirement
- **D-06:** No wording update to UX-01 or PROJECT.md requirements — full removal resolves the gap cleanly

### Claude's Discretion
- Verify lazy-lock.json entry for noice + nui removed after lazy sync (or remove manually if lazy doesn't clean up automatically)
- Check `lazy-lock.json` for `folke/noice.nvim` and `MunifTanjim/nui.nvim` entries and remove them

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Target File
- `.config/nvim/lua/plugins/misc.lua` — noice.nvim plugin block to remove (lines 3–21)

### Requirement Being Closed
- `.planning/PROJECT.md` §Requirements/Validated — UX-01: "Coherent UI: snacks.nvim replacing 5 plugins"
- `.planning/ROADMAP.md` §Phase 10 — Gap closure: "noice still active despite snacks replacing noice claim"

### Prior Phase Evidence
- `.planning/phases/08-ux-validate/08-CONTEXT.md` — Phase 8 validated UX-01 with noice partial gap noted
- `.planning/phases/09-fix-keymap-registry-integration/09-CONTEXT.md` — lualine noice component already removed

</canonical_refs>

<code_context>
## Existing Code Insights

### What noice.nvim is currently doing
- `cmdline = { enabled = true }` — bottom-edge `:` prompt popup (position row="100%", no border, 100 wide)
- `notify = { enabled = false }` — already disabled (snacks handles notifications)
- `messages = { enabled = false }` — already disabled
- `lsp.progress = { enabled = false }` — already disabled

### What removal restores
- Native Vim cmdline at bottom of screen (default behavior)
- No functionality lost — all active noice features were cosmetic cmdline styling only

### Dependencies safe to remove
- `MunifTanjim/nui.nvim` — zero references outside noice block (grep confirms)
- `nvim-lua/plenary.nvim` — keep (todo-comments.nvim depends on it)

### Integration Points
- `misc.lua` — remove lines 3–21 (the noice plugin block)
- `lazy-lock.json` — remove noice + nui entries after sync

</code_context>

<specifics>
## Specific Ideas

User preference: full removal, no cmdline replacement. Native Vim cmdline is acceptable.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 10-resolve-noice-ux01*
*Context gathered: 2026-04-17*
