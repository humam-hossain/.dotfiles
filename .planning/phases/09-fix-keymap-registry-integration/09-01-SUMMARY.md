---
phase: 09-fix-keymap-registry-integration
plan: "01"
subsystem: keymaps
tags:
  - keymaps
  - which-key
  - snacks
  - neo-tree-removal
key-files:
  created:
    - .config/nvim/lua/core/keymaps/whichkey.lua
  modified:
    - .config/nvim/lua/core/keymaps.lua
    - .config/nvim/lua/core/keymaps/registry.lua
    - .config/nvim/lua/plugins/snacks.lua
  deleted:
    - .config/nvim/lua/plugins/neotree.lua
decisions:
  - "Created whichkey.lua setup() function using wk.add() v3 API"
  - "Enabled snacks explorer with replace_netrw and trash options"
  - "Deleted neotree.lua entirely (neo-tree plugin removed)"
  - "Updated explorer.toggle to use Snacks.explorer()"
  - "Updated git.commits to git.status with Snacks.picker.git_status()"
  - "Removed neo-tree entries from M.plugin_local"
metrics:
  duration: null
  completed: "2026-04-17"
---

# Plan 09-01: Keymap Group Registration Summary

## One-liner

Wired which-key group registration, enabled snacks explorer, removed neo-tree plugin.

## Completed Tasks

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 8b1460a | Created whichkey.lua with wk.add() group registration |
| 2 | 8b1460a | Wired whichkey.setup() from core/keymaps.lua |
| 3 | 8b1460a | Enabled snacks explorer (replace_netrw, trash) |
| 4 | 8b1460a | Deleted neotree.lua, removed neo-tree entries from registry |

## Deviations from Plan

None — plan executed exactly as written.

## Key Changes

1. **whichkey.lua** — New module with `setup()` function that:
   - Registers domain prefix groups (f→Search, c→Code/LSP, g→Git, e→Explorer, b→Buffers, w→Windows, t→Toggles, s→Save)
   - Registers individual key descriptions from all registry scopes

2. **core/keymaps.lua** — Added `require("core.keymaps.whichkey").setup()` after apply_global()

3. **snacks.lua** — Added `explorer = { enabled = true, replace_netrw = true, trash = true }`

4. **registry.lua** — Updated lazy entries:
   - explorer.toggle: `plugin = "folke/snacks.nvim"`, `action = Snacks.explorer()`
   - git.commits → git.status: `action = Snacks.picker.git_status()`

5. **neotree.lua** — DELETED (neo-tree plugin removed)

## Verification

```bash
# whichkey.lua exists with wk.add() calls
grep -l "wk.add\|which-key" .config/nvim/lua/core/keymaps/whichkey.lua

# core/keymaps.lua calls whichkey.setup()
grep -n "whichkey" .config/nvim/lua/core/keymaps.lua

# snacks.lua has explorer enabled
grep -n "explorer" .config/nvim/lua/plugins/snacks.lua

# neotree.lua deleted
ls .config/nvim/lua/plugins/neotree.lua 2>&1 | grep -q "No such file"
```

## Self-Check: PASSED

- [x] whichkey.lua exists, exports setup(), uses wk.add() for groups and keys
- [x] core/keymaps.lua calls whichkey.setup()
- [x] snacks.lua has explorer.enabled = true
- [x] neotree.lua deleted
- [x] Neo-tree lazy entries removed from registry
