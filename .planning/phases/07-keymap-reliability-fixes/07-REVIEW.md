---
phase: 07-keymap-reliability-fixes
reviewed: 2026-04-22T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - .config/nvim/lua/core/keymaps/registry.lua
  - .config/nvim/lua/core/keymaps/lazy.lua
  - .config/nvim/lua/core/keymaps/attach.lua
findings:
  critical: 0
  warning: 5
  info: 3
  total: 8
status: issues_found
---

# Phase 7: Code Review Report

**Reviewed:** 2026-04-22
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Three files forming the central keymap registry and dispatch system were reviewed. No security issues or crash-level bugs were found. However, there are five substantive logic errors that cause keymaps to silently not register or behave incorrectly at runtime, plus three code quality issues. The most impactful bugs are the `fold_keys()` plugin-name mismatch (fold keymaps never register) and the module-dispatch `pcall` using repo slugs rather than Lua module names (always fails silently, masking intent). There is also a description inversion on two window-resize keymaps in the registry.

---

## Warnings

### WR-01: `fold_keys()` plugin filter never matches — fold keymaps silently not registered

**File:** `.config/nvim/lua/core/keymaps/lazy.lua:113`

**Issue:** `fold_keys()` filters with `map.plugin == "ufo"`, but every fold entry in the registry (lines 666-703 of `registry.lua`) sets `plugin = "kevinhwang91/nvim-ufo"`. The strings never match, so `fold_keys()` always returns an empty table. The `ufo.lua` plugin config calls `lazy.fold_keys()` and iterates the result — it registers nothing, leaving `zR`, `zM`, and `zK` unmapped even after ufo loads.

**Fix:**
```lua
-- lazy.lua line 113 — match the full plugin slug used in registry.lua
if map.plugin == "kevinhwang91/nvim-ufo" then
```

---

### WR-02: Module-method dispatch `pcall(require, map.plugin)` always fails for registry entries

**File:** `.config/nvim/lua/core/keymaps/lazy.lua:23`

**Issue:** The dispatch wrapper tries `pcall(require, map.plugin)` where `map.plugin` is a lazy.nvim repo slug like `"folke/snacks.nvim"` or `"lewis6991/gitsigns.nvim"`. Lua `require` uses dotted paths (e.g. `"snacks"`, `"gitsigns"`), not slash-separated slugs. The `pcall` will always return `ok = false` for every registry entry, so the module-method branch (`mod[map.action]()`) is permanently dead. The exact same dead code is duplicated in `fold_keys()` at lines 117-120.

Since all registry `lazy` entries use function closures for `action`, the fallback path at line 27 (`type(map.action) == "function"`) is always what runs. The `pcall` adds overhead on every keypress and obscures the real dispatch path. If module-method dispatch is intentional for future use, the plugin slug must be converted to a require-compatible name first.

**Fix (if module-method dispatch is not needed — simplest):**
```lua
-- Replace the entire dispatch closure with a direct call
function()
  if type(map.action) == "function" then
    map.action()
  elseif type(map.action) == "string" then
    if map.action:match("<[^>]+>") then
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(map.action, true, false, true),
        "n", false
      )
    else
      vim.cmd(map.action)
    end
  end
end
```

**Fix (if module-method dispatch is intended — derive require path from slug):**
```lua
-- Convert "folke/snacks.nvim" -> "snacks", "lewis6991/gitsigns.nvim" -> "gitsigns"
local require_name = map.plugin:match("/([^/]+)$"):gsub("%.nvim$", ""):gsub("%.lua$", "")
local ok, mod = pcall(require, require_name)
```

---

### WR-03: Window resize descriptions are inverted in the registry

**File:** `.config/nvim/lua/core/keymaps/registry.lua:195-210`

**Issue:** The `desc` fields for the horizontal resize bindings are swapped:

- `window.resize_left` (`<Left>`) maps to `:vertical resize +2<CR>` — this *increases* window width, but the description says "Decrease window width".
- `window.resize_right` (`<Right>`) maps to `:vertical resize -2<CR>` — this *decreases* window width, but the description says "Increase window width".

This causes which-key and any keymap browsers to show backwards descriptions, which will mislead users.

**Fix:**
```lua
-- registry.lua line 197-199
id = "window.resize_left",
lhs = "<Left>",
desc = "Increase window width",   -- was "Decrease window width"

-- registry.lua line 205-207
id = "window.resize_right",
lhs = "<Right>",
desc = "Decrease window width",   -- was "Increase window width"
```

---

### WR-04: Dead branch in `apply_lsp()` — both arms of `if/else` are identical

**File:** `.config/nvim/lua/core/keymaps/attach.lua:31-35`

**Issue:** The `type(map.action) == "function"` check produces two branches that call `vim.keymap.set` with exactly the same arguments. The distinction is meaningless — Lua's `vim.keymap.set` accepts both functions and strings as the rhs without callers needing to pre-check the type.

```lua
-- Current (lines 31-35)
if type(map.action) == "function" then
  vim.keymap.set(mode, map.lhs, map.action, opts)
else
  vim.keymap.set(mode, map.lhs, map.action, opts)  -- identical
end
```

While not a bug that causes incorrect behavior today, it signals an incomplete implementation — the original intent was likely to handle string actions (ex-commands) differently. If a string action like `":some_cmd<CR>"` is ever added to a `buffer`-scope entry in the registry, it will be passed raw to `vim.keymap.set`, which does accept strings, but any `<CR>` or `<Cmd>` notation in a raw string may not behave as intended depending on how the user typed the key. The dead branch should either be removed or completed.

**Fix:**
```lua
-- Simplest: collapse the branch
vim.keymap.set(mode, map.lhs, map.action, opts)
```

---

### WR-05: `search.word` and `search.WORD` call the same function — WORD variant is a duplicate

**File:** `.config/nvim/lua/core/keymaps/registry.lua:511-529`

**Issue:** Both `search.word` (`<leader>fw`) and `search.WORD` (`<leader>fW`) invoke `Snacks.picker.grep_word()` with no arguments. The WORD variant provides no differentiated behavior despite the distinct id, lhs, and description ("Find current WORD" vs "Find current Word"). One of the two bindings is a no-op duplicate.

**Fix:** Either remove `search.WORD` if unneeded, or pass a flag that changes word-boundary semantics:
```lua
-- search.WORD action — grep_word with WORD (space-delimited) boundaries if the API supports it
action = function() Snacks.picker.grep_word({ WORD = true }) end,
```
Check snacks.nvim docs for the correct option name; if `grep_word` does not support a WORD flag, remove the duplicate entry.

---

## Info

### IN-01: `M.setup_lsp_attach()` is defined but never called — dead exported function

**File:** `.config/nvim/lua/core/keymaps/attach.lua:78-89`

**Issue:** `M.setup_lsp_attach()` is a public function that creates a `LspAttach` autocmd to call `M.apply_lsp()`. It is never required or called anywhere in the codebase. The actual LSP attach wiring is done directly in `lsp.lua` via its own `LspAttach` autocmd. If `setup_lsp_attach()` were ever called in addition to the `lsp.lua` autocmd, mappings would be applied twice per attach event. The function is dead code and its presence creates a trap.

**Fix:** Remove `M.setup_lsp_attach()` from `attach.lua`, or add a comment clearly noting it must not be called alongside the `lsp.lua` autocmd.

---

### IN-02: TODO header comments on all three files are unfulfilled placeholders

**File:** `.config/nvim/lua/core/keymaps/registry.lua:1`, `.config/nvim/lua/core/keymaps/lazy.lua:1`, `.config/nvim/lua/core/keymaps/attach.lua:1`

**Issue:** Each file opens with `--- TODO: ...` describing what the file does. These are now implemented modules, not stubs. The TODO markers are misleading — they imply incomplete work rather than serving as documentation.

**Fix:** Convert to normal module-doc comments or remove the TODO prefix:
```lua
--- Declarative keymap registry - id, lhs, mode, desc, domain, scope
```

---

### IN-03: `fold_keys()` duplicates the full dispatch closure from `get_keys()` verbatim

**File:** `.config/nvim/lua/core/keymaps/lazy.lua:110-140`

**Issue:** `fold_keys()` contains a copy-pasted version of the dispatch closure from `get_keys()` (lines 22-43). Any future change to dispatch logic must be applied in two places. After fixing WR-01 (the plugin filter mismatch), this duplication will remain.

**Fix:** Once WR-01 is fixed and `fold_keys()` can actually match entries, refactor to reuse `get_keys()` by filtering on `plugin`:
```lua
function M.fold_keys()
  local all = registry.get_by_scope("lazy")
  local fold_maps = {}
  for _, map in ipairs(all) do
    if map.plugin == "kevinhwang91/nvim-ufo" then
      table.insert(fold_maps, map)
    end
  end
  -- Build specs using the same logic as get_keys()
  -- (or: return M.get_keys() filtered by a new helper)
end
```

---

_Reviewed: 2026-04-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
