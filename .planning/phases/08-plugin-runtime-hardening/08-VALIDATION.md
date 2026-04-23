---
phase: 08
slug: plugin-runtime-hardening
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
---

# Phase 08 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell-based Neovim validation harness in `scripts/nvim-validate.sh` |
| **Config file** | none — behavior is encoded directly in `scripts/nvim-validate.sh` |
| **Quick run command** | `rg -n 'window\\.move_(up|down|left|right)|neo-tree|basedpyright' .config/nvim/lua scripts .config/nvim/lazy-lock.json` |
| **Full suite command** | `./scripts/nvim-validate.sh all` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `rg -n 'window\\.move_(up|down|left|right)|neo-tree|basedpyright' .config/nvim/lua scripts .config/nvim/lazy-lock.json`
- **After every plan wave:** Run `./scripts/nvim-validate.sh health`
- **Before `$gsd-verify-work`:** Run `./scripts/nvim-validate.sh startup` and `./scripts/nvim-validate.sh health`, then complete manual workflow checks for search, explorer, git, LSP, and external open behavior
- **Max feedback latency:** 30 seconds for task-level grep probes; 120 seconds for wave/phase gates

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | BUG-02 | T-08-03 | Active plugin/runtime config matches shipped stack; no stale `neo-tree` health probe and no registry conflict for tmux navigation keys | integration | `rg -n 'window\\.move_(up|down|left|right)|neo-tree' .config/nvim/lua scripts` | ✅ `scripts/nvim-validate.sh` | ⬜ pending |
| 08-01-02 | 01 | 1 | BUG-02 | T-08-04 | Targeted BUG-016 trace identifies one caller before any lockfile pin change, and Python LSP runtime/install tables both target `pyright` | integration | `rg -n 'pyright|basedpyright' .config/nvim/lua/plugins/lsp.lua .config/nvim/lazy-lock.json && ./scripts/nvim-validate.sh startup` | ✅ `.planning/tmp/nvim-validate/` | ⬜ pending |
| 08-02-01 | 02 | 2 | BUG-03 | T-08-05 | External-open, autosave, and format-on-save paths bail safely on special or invalid buffers | integration | `rg -n 'vim\\.ui\\.open|buftype|modifiable|bufname' .config/nvim/lua/core/open.lua .config/nvim/lua/core/keymaps.lua .config/nvim/lua/plugins/conform.lua && ./scripts/nvim-validate.sh startup` | ✅ `.config/nvim/lua/core/open.lua` | ⬜ pending |
| 08-02-02 | 02 | 2 | BUG-02, BUG-03 | T-08-08 | LSP attach/highlight, options autocmds, and plugin init-order review cover crash-prone runtime paths without widening scope unnecessarily | integration | `rg -n 'LspAttach|document_highlight|which-key|treesitter|FocusLost' .config/nvim/lua && ./scripts/nvim-validate.sh startup` | ✅ `.config/nvim/lua/plugins/lsp.lua` | ⬜ pending |
| 08-03-01 | 03 | 3 | BUG-02 | T-08-09 | Automated validator outcomes are reflected in inventory with config-vs-environment triage | integration | `./scripts/nvim-validate.sh startup && ./scripts/nvim-validate.sh health` | ✅ `.planning/phases/06-runtime-failure-inventory/FAILURES.md` | ⬜ pending |
| 08-03-02 | 03 | 3 | BUG-02, BUG-03 | T-08-10 | Interactive search, explorer, git, LSP, UI, tmux-navigation, and external-open workflows are recorded in checklist and failure inventory | manual | `./scripts/nvim-validate.sh startup` | ✅ `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Snacks search workflow (`<leader>ff`, live grep, buffer pick) | BUG-02 | Harness does not drive picker UI | Open Neovim, run file finder, live grep, and buffer picker; confirm no error or crash |
| Snacks explorer workflow (`<leader>e`, navigation, open/close, file ops) | BUG-02 | Harness only probes module load, not explorer interaction | Open explorer, navigate tree, open file, close tree, perform safe file action if available; confirm no error |
| Git workflow (`<leader>gp`, `<leader>gt`, `<leader>gg`) | BUG-02 | Needs tracked repo state and interactive UI | In tracked file with changes, preview hunk, toggle blame, open lazygit or fallback git UI; confirm no runtime error |
| LSP workflow (hover, definition, diagnostics, format) | BUG-02, BUG-03 | Requires attached client in real buffer | Open file with active LSP, use hover/definition/diagnostics, save to trigger formatting, confirm no crash |
| UI workflow (message/notification surface, statusline, which-key/help surface) | BUG-02 | Harness does not exercise UI presentation layers | Trigger `which-key`, a notification/noice message, and inspect statusline/fold UI during normal editing; confirm no runtime error or broken render |
| Tmux navigation ownership (`<C-h/j/k/l>`) | BUG-02 | Requires live mapping ownership and pane traversal | Check `:verbose nmap <C-h>` points to `vim-tmux-navigator`; in tmux, cross from Neovim split to tmux pane and back; outside tmux, confirm normal split movement still works |
| External open fallback on Linux and Windows | BUG-02, BUG-03 | Requires real host integration on each OS | Verify `<C-S-o>` opens current file or reports real error string on Linux; repeat on a Windows target machine and record the result before phase close |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s for task-level probes; slower startup/health reserved for wave and phase gates
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
