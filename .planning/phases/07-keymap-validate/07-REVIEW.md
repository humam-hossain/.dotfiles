---
phase: "7"
reviewed: 2026-04-16T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - .config/nvim/lua/core/keymaps/registry.lua
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 7: Code Review Report

**Reviewed:** 2026-04-16
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

Reviewed `registry.lua` with gap-closure changes from phases 7.1 and 7.2:
- Added `<leader>gc` git commits via neo-tree
- Added `<leader>ww` (cycle windows) and `<leader>wm` (pick window)

The registry is well-structured but has a few quality concerns worth noting.

---

## Warnings

### WR-01: Buffer/Explorer keymap conflict

**File:** `.config/nvim/lua/core/keymaps/registry.lua:214-231`
**Issue:** `<Tab>` and `<S-Tab>` are mapped to buffer navigation in global scope, but CSV plugin-local mappings (lines 849-866) also use `<Tab>` and `<S-Tab>`. This creates a conflict: CSV navigation will never trigger because the global buffer navigation already captures these keys.

**Fix:** Either change CSV keymaps to different keys, or make buffer navigation lazy-loaded and scope CSV to take precedence. Example:
```lua
-- csvview.next_field in plugin_local should use different keys, e.g.:
lhs = "<C-Tab>",
```

### WR-02: neo-tree action is string, not function

**File:** `.config/nvim/lua/core/keymaps/registry.lua:479`
**Issue:** The `git.commits` mapping uses `action = ":Neotree git_commit<CR>"` as a string. This works, but the plugin-local neo-tree mappings (lines 815-844) use `action = "open_split"` etc., which are likely invalid — neo-tree doesn't accept raw string commands this way.

**Fix:** Change to function calls or Ex commands:
```lua
action = function() require("neo-tree.command").execute({ action = "show" }) end,
```
Or just verify this works with `:Neotree git_commit<CR>` style.

### WR-03: Redundant `vim.cmd` in buffer.new

**File:** `.config/nvim/lua/core/keymaps/registry.lua:542-543`
**Issue:** Uses `<cmd> enew <CR>` inside quotes, which is redundant. Should be direct Ex command string.

**Fix:**
```lua
action = ":enew<CR>",
```

---

## Info

### IN-01: Unused opts in lazy-loaded mappings

**File:** `.config/nvim/lua/core/keymaps/registry.lua:316-698`
**Issue:** Several lazy mappings have `opts` field defined but it's likely ignored since they're lazy-loaded (opts may be handled by lazy.nvim). Not a bug, just dead code.

**Example:** Line 317, 327, 337 — the `opts` field isn't needed for lazy mappings.

### IN-02: Inconsistent action type in global vs lazy

**File:** `.config/nvim/lua/core/keymaps/registry.lua`
**Issue:** Some mappings use string actions (`:bdelete!<CR>`), others use functions. This is fine but creates inconsistency in how actions are dispatched.

### IN-03: Duplicate keymap domains in git_status and explorer.buffers

**File:** `.config/nvim/lua/core/keymaps/registry.lua:507,518`
**Issue:** `explorer.git_status` has `domain = "g"` but `explorer.buffers` has `domain = "b"`. This is intentional but inconsistent with naming (`explorer.*` should likely share domain).

### IN-04: save.close_buffer uses confirm

**File:** `.config/nvim/lua/core/keymaps/registry.lua:654`
**Issue:** Uses `vim.cmd("confirm bdelete")` which will prompt user each time. May cause frustration in workflow.

**Fix:** Consider removing `confirm` for smoother workflow:
```lua
action = ":bdelete!<CR>",
```

---

_Reviewed: 2026-04-16_
_Reviewer: gsd-code-reviewer_
_Depth: standard_