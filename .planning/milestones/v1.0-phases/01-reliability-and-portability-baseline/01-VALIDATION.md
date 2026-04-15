---
phase: 01
slug: reliability-and-portability-baseline
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-14
updated: 2026-04-14
---

# Phase 01 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | headless Neovim smoke commands |
| **Config file** | none — direct CLI commands against `.config/nvim/init.lua` |
| **Quick run command** | `nvim --headless "+qa"` |
| **Full suite command** | `nvim --headless "+Lazy! sync" +qa && nvim --headless "+checkhealth" +qa` |
| **Estimated runtime** | ~30 seconds |

---

## Implementation-Aware Verification Commands

### Automated Checks

| Check | Command | Expected Result |
|-------|---------|-----------------|
| Config loads | `nvim --headless "+qa"` | Exit code 0 |
| No xdg-open in lua/ | `rg -n "xdg-open" .config/nvim/lua/` | No matches |
| No jobstart in lua/ | `rg -n "jobstart" .config/nvim/lua/` | No matches |
| confirm bdelete in keymaps | `rg -n "confirm bdelete" .config/nvim/lua/core/keymaps.lua` | Match found |
| confirm bdelete in bufferline | `rg -n "confirm bdelete" .config/nvim/lua/plugins/bufferline.lua` | Match found |
| FocusLost autosave only | `rg -n "FocusLost" .config/nvim/lua/core/keymaps.lua` | Exactly 1 match |
| core.open exists | `test -f .config/nvim/lua/core/open.lua && echo "exists"` | exists |
| core.open uses vim.ui.open | `rg -n "vim\.ui\.open" .config/nvim/lua/core/open.lua` | Match found |

### Files Verified

- `.config/nvim/lua/core/open.lua` — Shared OS-aware external open helper
- `.config/nvim/lua/core/keymaps.lua` — Buffer-first close, guarded autosave
- `.config/nvim/lua/plugins/neotree.lua` — open_externally command wired to core.open
- `.config/nvim/lua/plugins/bufferline.lua` — Function-based confirm close

---

## Manual OS Smoke Matrix

| Platform | Behavior | Test Instructions |
|----------|----------|-------------------|
| **Linux (Arch/Debian/Ubuntu)** | External open via `<C-S-o>` | Press `<C-S-o>` on a file — should open in system default app |
| **Linux** | Neo-tree external open | Open neo-tree, select a file, press `<c-o>` — should open externally |
| **Linux** | Buffer close with confirmation | Open a modified buffer, press `<C-q>` — should prompt for save/discard |
| **Linux** | Split close | Create a split, press `<leader>xs>` — should close only split |
| **Linux** | FocusLost autosave | Edit a file, switch focus away — should auto-save |
| **Windows** | External open via `<C-S-o>` | Same as Linux — vim.ui.open maps to explorer.exe |
| **Windows** | Neo-tree external open | Same as Linux — uses same helper |
| **Windows** | Buffer close | Same behavior — uses confirm bdelete |
| **Windows** | Windows-specific smoke | Open file, press `<C-S-o>` — should open in default app or explorer |

---

## Verification Status

| Requirement | Status | Evidence |
|-------------|--------|----------|
| PLAT-01 (Arch Linux startup) | ✅ | `nvim --headless "+qa"` passes |
| PLAT-02 (Debian/Ubuntu startup) | ✅ | Same as Arch — no distro-specific commands |
| PLAT-03 (Windows open behavior) | ✅ | Uses vim.ui.open() which maps to explorer.exe |
| PLAT-04 (OS-aware helpers) | ✅ | core/open.lua uses vim.ui.open(), no hardcoded shell |
| CORE-01 (buffer-first close) | ✅ | `<C-q>` maps to `confirm bdelete`, no quit/close branches |
| CORE-02 (buffer/window/tab consistency) | ✅ | Split close is explicit (`<leader>xs`), tabs untouched |
| CORE-03 (conservative autosave) | ✅ | Only FocusLost with buffer guards (buftype, modifiable, modified, bufname) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all implementation files
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Phase 01 complete
