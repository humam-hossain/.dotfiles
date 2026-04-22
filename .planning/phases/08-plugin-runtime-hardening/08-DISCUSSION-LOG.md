# Phase 8: Plugin Runtime Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-22
**Phase:** 08-plugin-runtime-hardening
**Areas discussed:** BUG-017 nav conflict, BUG-016 deprecation, Discovery scope, lsp.lua uncommitted change, Plan 8-02 crash scope, BUG-001 phase ownership, BUG-016 trace method, Lock file policy, core.open error handling

---

## BUG-017: vim-tmux-navigator vs registry <C-h/j/k/l>

| Option | Description | Selected |
|--------|-------------|----------|
| Remove registry entries | Delete 4 window.move_* M.global entries; tmux-nav owns all nav | ✓ |
| Remove tmux-navigator | Registry wincmd handles splits; tmux users use tmux keys directly | |
| Guard by $TMUX | Conditional load — registry when $TMUX unset, tmux-nav when set | |
| Replace with smart-splits.nvim | Modern replacement handling nvim splits + tmux/wezterm/kitty | |

**User's choice:** Remove registry entries
**Notes:** User wants seamless nvim-tmux-nvim navigation (cross-pane crossing). tmux.conf already has vim-tmux-navigator plugin configured. Registry entries win over tmux-nav because apply.lua runs at startup. Fix: remove the 4 window.move_* entries from registry.lua.

Follow-up — non-tmux fallback:

| Option | Description | Selected |
|--------|-------------|----------|
| Acceptable — tmux-nav fallback fine | vim-tmux-navigator handles non-tmux sessions (acts as wincmd) | ✓ |
| Need explicit non-tmux guard | Add $TMUX check for registry fallback | |

---

## BUG-016: vim.tbl_flatten deprecation

| Option | Description | Selected |
|--------|-------------|----------|
| Trace and fix | Find calling plugin, update pin | ✓ |
| Shim at startup | Add compat line in init.lua | |
| Accept as noise | Document as Won't Fix | |

**User's choice:** Trace and fix

Follow-up — fallback if no upstream fix:

| Option | Description | Selected |
|--------|-------------|----------|
| Remove the offending plugin | Only if non-critical | ✓ |
| Shim at startup | Add compat line as fallback | |
| Document as Won't Fix | Accept if essential and unmaintained | |

---

## Discovery Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Trust Phase 6 + verify in 8-03 | Fix known bugs, then structured re-verify in 8-03 | ✓ |
| New discovery pass first | Live interactive session before planning fixes | |

**Workflow verification scope (multiselect):**

| Workflow | Selected |
|----------|----------|
| Search (snacks picker) | ✓ |
| Explorer (snacks.explorer) | ✓ |
| Git (gitsigns + fugitive + lazygit) | ✓ |
| LSP (neovim 0.11 native) | ✓ |

---

## lsp.lua: basedpyright removal

| Option | Description | Selected |
|--------|-------------|----------|
| Intentional — include in Phase 8 | Commit removal as plugin config fix | ✓ |
| Intentional — separate concern | Commit separately | |
| Accidental — revert it | Restore basedpyright | |

**Reason for removal:**

| Option | Description | Selected |
|--------|-------------|----------|
| Replaced by pyright | Switching to standard pyright | ✓ |
| Mason install fails | Not installable | |
| Not needed | No Python LSP needed | |

**Replacement:**

| Option | Description | Selected |
|--------|-------------|----------|
| Add pyright as replacement | Remove basedpyright, add pyright in same commit | ✓ |
| Remove only | Leave pyright for later | |

---

## Plan 8-02: Crash-prone flow scope

| Flow | Selected |
|------|----------|
| Format-on-save edge cases | ✓ |
| LSP attach safety | ✓ |
| Autocmd guard review | ✓ |
| Plugin init order | ✓ |

---

## BUG-001: Phase ownership (neo-tree probe)

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 8 | Plugin config defect — fix with other plugin cleanup | ✓ |
| Phase 9 | Health signal quality issue | |

---

## BUG-016 Trace Method

| Option | Description | Selected |
|--------|-------------|----------|
| Startup log grep | nvim --startuptime, grep for deprecation warning | ✓ |
| Grep plugin source | rg 'tbl_flatten' in ~/.local/share/nvim/lazy/ | |
| Both — log first, grep to confirm | | |

---

## Lock File Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Update pin surgically | Only offending plugin, no broad refresh | ✓ |
| Keep pins frozen, shim instead | Don't touch lazy-lock.json | |
| Full lockfile refresh | :Lazy update all | |

---

## core.open error handling

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — fix error handling | Capture both vim.ui.open return values | ✓ |
| No — out of scope | Success case works, leave it | |

**Notes:** User asked about `<C-o>` for open-in-default-app. Actual binding is `<C-S-o>` (`file.open_external`). `<C-o>` is native Neovim jumplist — cannot shadow. Binding confirmed working; only error handling fix needed.

---

## Claude's Discretion

- Exact startup log grep command for BUG-016
- Commit order within plans
- BUG-016 pin update mechanism (`:Lazy update` vs manual)
- pcall guard pattern for LSP attach safety
- Format-on-save exclusion list review approach

## Deferred Ideas

None.
