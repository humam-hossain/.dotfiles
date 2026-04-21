# CHECKLIST.md — Reproduction Checklist for Confirmed Failures

**Generated:** 2026-04-18
**Status:** Confirmed failures for Phase 7-9 fixing

## Environment

OS: Linux 6.19.11-arch1-1 x86_64
Neovim: NVIM v0.12.1

---

## BUG-005 — Keymap registry: `<cmd> enew <CR>` Trailing Characters

**Owner:** core/keymaps/registry.lua  
**Status:** Confirmed  
**Provenance:** manual

### Reproduction Steps

1. Open Neovim
2. Press `<leader>b` (maps to buffer.new in registry)
3. Observe error:
```
E5108: Lua: vim/_core/editor.lua:0: nvim_exec2(), line 1: Vim(<):E488: Trailing characters: cmd> enew <CR>: <cmd> enew <CR>
```

### Expected Outcome

Keymap should create a new buffer without error.

### Fix Guidance

Action string `"<cmd> enew <CR>"` has leading space. Should be `"enew"` or use Lua function.

---

## BUG-006 — Keymap registry: `<cmd>set wrap!<CR>` Trailing Characters

**Owner:** core/keymaps/registry.lua  
**Status:** Confirmed  
**Provenance:** manual

### Reproduction Steps

1. Open Neovim
2. Press `<leader>lw` (toggle line wrap)
3. Observe error:
```
E5108: Lua: vim/_core/editor.lua:0: nvim_exec2(), line 1: Vim(<):E488: Trailing characters: cmd>set wrap!<CR>: <cmd>set wrap!<CR>
```

### Expected Outcome

Line wrap toggles without error.

### Fix Guidance

Action should use Lua: `function() vim.wo.wrap = not vim.wo.wrap end`

---

## BUG-007 — Keymap registry: `<cmd>noautocmd w <CR>` Trailing Characters

**Owner:** core/keymaps/registry.lua  
**Status:** Confirmed  
**Provenance:** manual

### Reproduction Steps

1. Open Neovim
2. Press `<leader>sn` (save without autocmds)
3. Observe error:
```
E5108: Lua: vim/_core/editor.lua:0: nvim_exec2(), line 1: Vim(<):E488: Trailing characters: cmd>noautocmd w <CR>: <cmd>noautocmd w <CR>
```

### Expected Outcome

Saves file without triggering autocmds.

### Fix Guidance

Action string invalid in 0.12+. Use Lua function instead.

---

## BUG-008 — Keymap registry: `<cmd>enew <CR>` Trailing Characters

**Owner:** core/keymaps/registry.lua  
**Status:** Confirmed  
**Provenance:** manual

### Reproduction Steps

1. Open Neovim
2. Press `<leader>xs` (close window)
3. Observe error:
```
E5108: Lua: vim/_core/editor.lua:0: nvim_exec2(), line 1: Vim(close):E488: Trailing characters: <CR>: :close<CR>
```

### Expected Outcome

Window closes without error.

### Fix Guidance

Action `"<cmd>enew <CR>"` causes confusion. Use `:close` properly or Lua function.

---

## BUG-009 — Keymap registry: `<C-w>v` Invalid Format

**Owner:** core/keymaps/registry.lua  
**Status:** Confirmed  
**Provenance:** manual

### Reproduction Steps

1. Open Neovim
2. Press `<leader>v` (split vertically)
3. Observe error:
```
E5108: Lua: vim/_core/editor.lua:0: nvim_exec2(), line 1: Vim(<):E488: Trailing characters: C-w>v: <C-w>v
```

### Expected Outcome

Window splits vertically.

### Fix Guidance

`<C-w>v` should not be wrapped in `<cmd>`. Use as direct action: `vim.cmd("vsplit")` or `<C-w>v` as lhs with no action wrapper.

---

## BUG-010 — Keymap registry: `<C-w>s` Invalid Format

**Owner:** core/keymaps/registry.lua  
**Status:** Confirmed  
**Provenance:** manual

### Reproduction Steps

1. Open Neovim
2. Press `<leader>h` (split horizontally)
3. Observe error:
```
E5108: Lua: vim/_core/editor.lua:0: nvim_exec2(), line 1: Vim(<):E488: Trailing characters: C-w>s: <C-w>s
```

### Expected Outcome

Window splits horizontally.

### Fix Guidance

Same as BUG-009 - keymap format issue.

---

## BUG-011 — Keymap registry: `<C-w>=` Invalid Format

**Owner:** core/keymaps/registry.lua  
**Status:** Confirmed  
**Provenance:** manual

### Reproduction Steps

1. Open Neovim
2. Press `<leader>se` (equalize windows)
3. Observe error:
```
E5108: Lua: vim/_core/editor.lua:0: nvim_exec2(), line 1: Vim(<):E488: Trailing characters: C-w>=: <C-w>=
```

### Expected Outcome

All windows equalize in size.

### Fix Guidance

`<C-w>=` is a normal mode command, not a `<cmd>` string.

---

## BUG-012 — Gitsigns: preview_hunk Not a Valid Function

**Owner:** plugins/git.lua  
**Status:** Confirmed  
**Provenance:** manual

### Reproduction Steps

1. Open a file with changes
2. Press `<leader>gp` (preview hunk)
3. Observe error:
```
preview_hunk<CR> is not a valid function or action
```

### Expected Outcome

Git hunk preview opens.

### Fix Guidance

gitsigns uses `Gsigns preview_hunk` or `:Gitsigns preview_hunk<CR>` not `:Gitsigns preview_hunk<CR>` (colon vs capital G).

---

## BUG-013 — fzf-lua: Hidden Files Not Searchable

**Owner:** plugins/fzflua.lua  
**Status:** Confirmed  
**Provenance:** manual

### Reproduction Steps

1. Open Neovim
2. Press `<leader>f` (files search)
3. Type filename matching hidden file (starts with `.`)
4. File not found

### Expected Outcome

Hidden files included in search.

### Fix Guidance

fzf-lua `files` command needs `hidden = true` in config.

---

## Summary

| Bug ID | Type | Owner | Fix Approach |
|--------|------|-------|---------------|
| BUG-005 | keymap | registry.lua | Remove leading space in action string |
| BUG-006 | keymap | registry.lua | Convert to Lua function |
| BUG-007 | keymap | registry.lua | Convert to Lua function |
| BUG-008 | keymap | registry.lua | Fix action string format |
| BUG-009 | keymap | registry.lua | Use direct vim.cmd or lhs-only |
| BUG-010 | keymap | registry.lua | Use direct vim.cmd or lhs-only |
| BUG-011 | keymap | registry.lua | Use direct vim.cmd or lhs-only |
| BUG-012 | plugin | git.lua | Fix gitsigns command format |
| BUG-013 | plugin | fzflua.lua | Add `hidden = true` to files config |

**Total Confirmed:** 9 bugs ready for Phase 7-8 fixing.