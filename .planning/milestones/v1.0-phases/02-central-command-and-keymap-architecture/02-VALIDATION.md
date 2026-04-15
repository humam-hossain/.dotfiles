---
phase: 02
slug: central-command-and-keymap-architecture
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-14
updated: 2026-04-14
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | headless Neovim smoke commands plus `rg`-based structure checks |
| **Config file** | none — direct CLI commands against `.config/nvim/init.lua` |
| **Quick run command** | `nvim --headless "+qa"` |
| **Full suite command** | `nvim --headless "+Lazy! sync" +qa && nvim --headless "+checkhealth" +qa` |
| **Estimated runtime** | ~45 seconds |

---

## Implementation-Aware Verification Commands

### Automated Checks

| Check | Command | Expected Result |
|-------|---------|-----------------|
| Config loads | `nvim --headless "+qa"` | Exit code 0 |
| Registry exists | `test -f .config/nvim/lua/core/keymaps/registry.lua && echo "exists"` | `exists` |
| Registry bootstrap exists | `test -f .config/nvim/lua/core/keymaps/apply.lua && test -f .config/nvim/lua/core/keymaps/attach.lua && echo "exists"` | `exists` |
| Core keymaps is thin bootstrap | `rg -n "require\\(\"core.keymaps" .config/nvim/lua/core/keymaps.lua` | Matches apply/bootstrap wiring |
| Which-key groups come from registry | `rg -n "which-key|core\\.keymaps\\.whichkey|group =" .config/nvim/lua/plugins/misc.lua .config/nvim/lua/core/keymaps/whichkey.lua` | Matches registry-driven group wiring |
| FZF/LSP/Neo-tree/UFO consume registry helpers | `rg -n "core\\.keymaps\\.(lazy|attach|registry)" .config/nvim/lua/plugins/fzflua.lua .config/nvim/lua/plugins/lsp.lua .config/nvim/lua/plugins/neotree.lua .config/nvim/lua/plugins/ufo.lua` | Matches all migrated plugin entry points |
| Treesitter/CSV contextual mappings are inventoried centrally | `rg -n "treesitter|csvview|plugin-local|contextual" .config/nvim/lua/core/keymaps/registry.lua .planning/phases/02-central-command-and-keymap-architecture/02-KEYMAP-INVENTORY.md` | Matches contextual key inventory |
| No stray user-facing `vim.keymap.set` remain in migrated plugin files | `rg -n "vim\\.keymap\\.set" .config/nvim/lua/plugins/fzflua.lua .config/nvim/lua/plugins/lsp.lua .config/nvim/lua/plugins/ufo.lua .config/nvim/lua/plugins/neotree.lua` | No user-facing map definitions outside approved adapter code |
| No stale plugin `keys = {}` lists remain in migrated plugin files | `rg -n "keys\\s*=\\s*\\{" .config/nvim/lua/plugins/fzflua.lua .config/nvim/lua/plugins/ufo.lua .config/nvim/lua/plugins/neotree.lua` | No hand-owned user-facing keys left after registry migration |
| Direct-key inventory exists | `test -f .planning/phases/02-central-command-and-keymap-architecture/02-KEYMAP-INVENTORY.md && echo "exists"` | `exists` |
| Preserved direct keys are documented | `rg -n "jk|<C-h>|<C-j>|<C-k>|<C-l>|<C-_>|<Tab>|<S-Tab>" .planning/phases/02-central-command-and-keymap-architecture/02-KEYMAP-INVENTORY.md .config/nvim/README.md` | Matches preserved-key inventory/docs |

### Files Verified

- `.config/nvim/lua/core/keymaps.lua` — thin bootstrap for centralized keymap application
- `.config/nvim/lua/core/keymaps/registry.lua` — authoritative registry for all custom mappings
- `.config/nvim/lua/core/keymaps/apply.lua` — eager/global keymap emitter
- `.config/nvim/lua/core/keymaps/lazy.lua` — `lazy.nvim` keys compiler
- `.config/nvim/lua/core/keymaps/attach.lua` — buffer-local/plugin-local attach helpers
- `.config/nvim/lua/core/keymaps/whichkey.lua` — taxonomy/group registration
- `.config/nvim/lua/plugins/fzflua.lua` — registry-consumed search mappings
- `.config/nvim/lua/plugins/lsp.lua` — registry-consumed LSP attach mappings
- `.config/nvim/lua/plugins/neotree.lua` — registry-consumed explorer entry and plugin-local maps
- `.config/nvim/lua/plugins/ufo.lua` — registry-consumed fold mappings
- `.config/nvim/lua/plugins/treesitter.lua` — contextual key definitions surfaced through the registry
- `.config/nvim/lua/plugins/misc.lua` — contextual plugin key definitions surfaced through the registry
- `.planning/phases/02-central-command-and-keymap-architecture/02-KEYMAP-INVENTORY.md` — direct-key audit and final classification
- `.config/nvim/README.md` — user-facing taxonomy and discovery docs

---

## Manual Smoke Matrix

| Behavior | Requirement | Test Instructions |
|----------|-------------|-------------------|
| Central discovery file | KEY-01 | Open `.config/nvim/lua/core/keymaps/registry.lua` and confirm all custom global, lazy, buffer-local, and plugin-local maps are represented there. |
| Search taxonomy | KEY-02 | In Neovim, trigger `which-key` on `<leader>f` and confirm search actions are grouped under the `f` domain with descriptive labels. |
| Code taxonomy | KEY-02 | Trigger `which-key` on `<leader>c` in an LSP-attached buffer and confirm rename/action/reference entries are grouped under the `c` domain. |
| Explorer taxonomy | KEY-02 | Trigger `which-key` on `<leader>e` or explorer-related groups and confirm explorer commands use the `e` domain instead of old `n*` groups. |
| Preserved direct keys | KEY-02 | Verify `jk`, `<C-h/j/k/l>`, `<C-_>`, and `<Tab>/<S-Tab>` still behave as documented after migration. |
| Contextual plugin keys | KEY-01, KEY-03 | Open a CSV file, a Treesitter-supported file, an LSP-attached file, and neo-tree. Confirm contextual keys still work and are documented in the inventory/README as contextual rather than global. |
| Duplicate removal | KEY-03 | Grep the migrated plugin files and confirm there are no hidden user-facing mappings left outside the registry-owned adapters. |

---

## Verification Status

| Requirement | Status | Evidence |
|-------------|--------|----------|
| KEY-01 (one central source of truth) | ✅ | Registry file plus inventory artifact |
| KEY-02 (coherent domain grouping) | ✅ | Registry taxonomy and `which-key` group wiring |
| KEY-03 (centralized plugin actions without hidden duplicates) | ✅ | Registry-driven plugin consumers plus duplicate grep checks |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all implementation files
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Phase 02 ready for execution
