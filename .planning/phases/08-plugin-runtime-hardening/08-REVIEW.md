---
phase: 08-plugin-runtime-hardening
reviewed: 2026-04-22T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - .config/nvim/lazy-lock.json
  - .config/nvim/lua/core/keymaps.lua
  - .config/nvim/lua/core/keymaps/registry.lua
  - .config/nvim/lua/core/open.lua
  - .config/nvim/lua/plugins/conform.lua
  - .config/nvim/lua/plugins/lsp.lua
  - .config/nvim/lua/plugins/misc.lua
  - scripts/nvim-validate.sh
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 08: Code Review Report

**Reviewed:** 2026-04-22
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed all eight files changed in Phase 08: the plugin lock file, the
autosave/keymap harness, the declarative keymap registry, the external-open
helper, the conform format-on-save dispatcher, the LSP setup, misc plugins, and
the headless validation script.

The hardening work in `keymaps.lua`, `open.lua`, `lsp.lua`, and `conform.lua`
is solid. Guard chains are logically complete and ordered correctly. The
`window.move_*` registry removal and the colorizer removal are clean.

Two issues need attention before the validation harness can be trusted:

1. The smoke-test subcommand writes its failure marker to the wrong directory,
   causing smoke failures to go undetected (silent false-pass).
2. `conform.lua` includes a dead `format_on_save` key inside
   `default_format_options` that is not a valid conform option at that nesting
   level and will be silently ignored.

---

## Warnings

### WR-01: Smoke-test SMOKE_FAIL path mismatch — failures silently swallowed

**File:** `scripts/nvim-validate.sh:253` (Lua heredoc) and `:277` (bash check)

**Issue:** The Lua heredoc inside `cmd_smoke` opens the failure marker with a
bare relative path:

```lua
local f = io.open('SMOKE_FAIL', 'w')
```

Neovim's working directory when launched headless from an arbitrary shell is the
shell's cwd, **not** `$REPORT_DIR`. The bash check immediately after looks for
the file in the report directory:

```bash
if [[ -f "$REPORT_DIR/SMOKE_FAIL" ]]; then
```

These two paths will almost never agree. When a plugin fails to load the marker
is written to the caller's cwd, the bash check misses it, and `cmd_smoke`
returns 0 ("PASS") even though failures occurred. The remaining `rc -ne 0` guard
(line 285) would only catch a non-zero nvim exit, but `vim.cmd('cq')` may not
propagate reliably through the `-l` script path in all nvim versions.

**Fix:** Either pass an absolute path into the Lua script, or redirect to a
fixed location. The simplest fix is to pass the path via a `--cmd` `let`:

```bash
# Before launching nvim, pass the absolute marker path
local marker="$REPORT_DIR/SMOKE_FAIL"

nvim --headless \
    -u "$REPO_ROOT/.config/nvim/init.lua" \
    --cmd "set rtp^=$REPO_ROOT/.config/nvim" \
    --cmd "let g:smoke_fail_path = '$marker'" \
    -l "$lua_tmp" \
    > "$log" 2>&1
```

And inside the Lua heredoc:

```lua
local marker = vim.g.smoke_fail_path or 'SMOKE_FAIL'
local f = io.open(marker, 'w')
```

Alternatively, use an absolute path built with `vim.fn.stdpath` or pass
`REPORT_DIR` as an environment variable and read it with `os.getenv`.

---

### WR-02: LspDetach augroup recreated with `clear = true` on every attach — only last buffer's handler survives

**File:** `.config/nvim/lua/plugins/lsp.lua:183`

**Issue:** Every time `LspAttach` fires, the callback unconditionally creates the
`kickstart-lsp-detach` augroup with `{ clear = true }`:

```lua
vim.api.nvim_create_autocmd("LspDetach", {
    group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
    ...
})
```

`clear = true` deletes all existing autocmds in the group before adding the new
one. In a multi-buffer session where several buffers have LSP attached, each
subsequent `LspAttach` event wipes the detach handlers registered by all
previous buffers. When an earlier-attached buffer eventually detaches, its
`clear_references` and `nvim_clear_autocmds` cleanup will never run, leaving
stale document-highlight autocmds on that buffer.

The `_lsp_highlight_attached` guard (line 167) prevents duplicate highlight
autocmds per buffer but does not prevent the detach handler from being
overwritten by a later attach.

**Fix:** Use `{ clear = false }` for the detach augroup so each buffer's handler
accumulates rather than overwrites:

```lua
vim.api.nvim_create_autocmd("LspDetach", {
    group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = false }),
    callback = function(event2)
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
    end,
})
```

This mirrors the pattern used for `kickstart-lsp-highlight` two lines above
(also `{ clear = false }`), which was already correct.

---

## Info

### IN-01: Dead `format_on_save` key inside `default_format_options`

**File:** `.config/nvim/lua/plugins/conform.lua:65-67`

**Issue:** `default_format_options` is the conform.nvim table for per-formatter
option overrides (e.g. `timeout_ms`, `quiet`). The key `format_on_save` is not
a valid key at this nesting level — it is a top-level conform option. Placing it
inside `default_format_options` causes it to be silently ignored by conform.

```lua
default_format_options = {
    trim_trailing_whitespace = true,
    format_on_save = true,   -- <-- dead: not a valid default_format_options key
},
```

The actual format-on-save behavior is already correctly driven by the
`format_on_save` function above (lines 16-63). This stray key adds no
functionality and may mislead future readers into thinking it controls something.

**Fix:** Remove the `format_on_save = true` line from `default_format_options`:

```lua
default_format_options = {
    trim_trailing_whitespace = true,
},
```

---

### IN-02: `search.WORD` and `search.word` map to identical actions

**File:** `.config/nvim/lua/core/keymaps/registry.lua:473-491`

**Issue:** `search.word` (`<leader>fw`) and `search.WORD` (`<leader>fW`) both
call `Snacks.picker.grep_word()` with no difference in arguments. If the intent
is to grep the WORD under cursor (whitespace-delimited token) as opposed to the
vim `word` (alphanumeric), the implementation should differ between them.

```lua
-- search.word (line 476)
action = function() Snacks.picker.grep_word() end,

-- search.WORD (line 489)
action = function() Snacks.picker.grep_word() end,
```

**Fix:** If `Snacks.picker.grep_word` accepts a mode option to select WORD vs
word boundary, pass it here. If no such option exists and both bindings are
intentionally identical, remove `search.WORD` to avoid confusion. Otherwise,
document explicitly why both call the same function.

---

_Reviewed: 2026-04-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
