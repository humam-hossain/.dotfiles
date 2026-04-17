---
phase: 08-ux-validate
fixed_at: 2026-04-17T00:00:00Z
review_path: .planning/phases/08-ux-validate/08-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 08: Code Review Fix Report

**Fixed at:** 2026-04-17
**Source review:** .planning/phases/08-ux-validate/08-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### WR-01: Multiple LSP clients on same buffer accumulate redundant highlight autocmds

**Files modified:** `.config/nvim/lua/plugins/lsp.lua`
**Commit:** 111678a
**Applied fix:** Added a buffer-local flag guard `vim.b[event.buf]._lsp_highlight_attached` to the `if client:supports_method(...)` condition. The condition now also checks `and not vim.b[event.buf]._lsp_highlight_attached`, and sets the flag to `true` immediately before registering the autocmds. This prevents duplicate `CursorHold`/`CursorMoved` autocmd registration when a second LSP client (e.g., `vimls`) attaches to a buffer that already has highlight autocmds registered by a first client (e.g., `lua_ls`).

### WR-02: "ty" Mason package may not exist in Mason's registry

**Files modified:** `.config/nvim/lua/plugins/lsp.lua`
**Commit:** 352f8f2
**Applied fix:** Removed `"ty"` from `mason_lsp_servers` list (line 77 now contains a comment explaining the exclusion). The `ty = {}` entry in `lsp_servers` (line 55) is intentionally retained so that users who install the `ty` binary manually (outside Mason) still get it configured and enabled via `vim.lsp.enable()`. Mason will no longer attempt to install an unknown package and fail silently on startup.

---

_Fixed: 2026-04-17_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
