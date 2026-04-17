---
phase: 08-ux-validate
reviewed: 2026-04-17T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - .config/nvim/lua/plugins/lsp.lua
  - .config/nvim/lua/plugins/snacks.lua
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 08: Code Review Report

**Reviewed:** 2026-04-17
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Both files are structurally sound and use correct nvim 0.12 native LSP APIs. The
`vim.lsp.config()` + `vim.lsp.enable()` pattern, mason-lspconfig integration, and
`Snacks.picker.select` override for `vim.ui.select` are all implemented correctly.

Two warnings were found: a latent autocmd accumulation bug when multiple LSP clients
attach to the same buffer (pre-existing Kickstart pattern), and a mason package that
may not yet exist in Mason's registry ("ty"). Two info-level items were also noted.

## Warnings

### WR-01: Multiple LSP clients on same buffer accumulate redundant highlight autocmds

**File:** `.config/nvim/lua/plugins/lsp.lua:143-162`

**Issue:** Inside the `LspAttach` callback, `CursorHold`/`CursorHoldI` and
`CursorMoved`/`CursorMovedI` autocmds are added to the `kickstart-lsp-highlight`
augroup with `{ clear = false }`. Each time a new LSP client attaches to the same
buffer (e.g., `lua_ls` + `vimls` both attach to a `.lua` file), a new pair of
highlight autocmds is registered without clearing the previous ones. This causes
`vim.lsp.buf.document_highlight` and `vim.lsp.buf.clear_references` to fire multiple
times per cursor movement.

Separately, the nested `LspDetach` autocmd is created with `{ clear = true }` inside
the `LspAttach` callback, which means when the second client attaches, it replaces the
`LspDetach` handler registered by the first. The detach handler then only clears once
instead of per-client.

**Fix:** Guard the highlight autocmd registration so it only runs once per buffer, or
use a buffer-local flag:

```lua
-- At the top of the LspAttach callback, after the client nil-check:
if not client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
  return
end

-- Prevent duplicate registration if another client already set this up
if vim.b[event.buf]._lsp_highlight_attached then
  return
end
vim.b[event.buf]._lsp_highlight_attached = true

local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  buffer = event.buf,
  group = highlight_augroup,
  callback = vim.lsp.buf.document_highlight,
})
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  buffer = event.buf,
  group = highlight_augroup,
  callback = vim.lsp.buf.clear_references,
})
vim.api.nvim_create_autocmd("LspDetach", {
  group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
  callback = function(event2)
    vim.lsp.buf.clear_references()
    vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
  end,
})
```

---

### WR-02: "ty" Mason package may not exist in Mason's registry

**File:** `.config/nvim/lua/plugins/lsp.lua:55,76`

**Issue:** `ty` is listed as both an LSP server in `lsp_servers` (line 55) and as
`"ty"` in `mason_lsp_servers` (line 76). `ty` is Astral's new Python type-checker LSP
(as of early 2026 it is not yet in Mason's package registry). If Mason cannot find the
package, `mason-tool-installer` will emit an error on startup and the install will
silently fail. The LSP will then never start because its binary is absent.

**Fix:** Verify `ty` is available in Mason before keeping it in `mason_lsp_servers`.
As a fallback, move it out of the Mason-managed list and rely on a system-installed
`ty` binary, or remove it until Mason ships the package:

```lua
-- Option A: Remove from mason_lsp_servers (keep in lsp_servers if binary is on PATH)
-- mason_lsp_servers does not include "ty"

-- Option B: Remove entirely until Mason packages it
-- Remove "ty = {}" from lsp_servers and "ty" from mason_lsp_servers
```

Check availability with: `:MasonInstall ty` — if it errors, remove from the list.

---

## Info

### IN-01: Duplicate design-decision tag D-12 on two distinct snacks features

**File:** `.config/nvim/lua/plugins/snacks.lua:43,45`

**Issue:** Both `zen` (line 43) and `terminal` (line 45) share the comment tag
`-- D-12`. If design decisions are tracked by number, this is a tagging collision.
`terminal` is disabled for a different reason (kitty+tmux workflow) than `zen`
(no established use case), so they warrant separate decision IDs.

**Fix:** Assign a unique tag to one of them (e.g., `-- D-13` for `zen`) and update
the corresponding decision log.

---

### IN-02: Dead branch in attach.lua apply_lsp — identical code paths in if/else

**File:** `.config/nvim/lua/core/keymaps/attach.lua:29-34`

**Issue:** The `if type(map.action) == "function"` branch (line 29) and its `else`
(line 31) call identical code: `vim.keymap.set(mode, map.lhs, map.action, opts)`.
The condition is never meaningful — both branches do the same thing. This is dead
branching logic, not a bug in lsp.lua itself but in the helper it calls.

**Fix:** Collapse to a single call:

```lua
vim.keymap.set(mode, map.lhs, map.action, opts)
```

---

_Reviewed: 2026-04-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
