---
phase: 01
slug: reliability-and-portability-baseline
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-14
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

## Sampling Rate

- **After every task commit:** Run `nvim --headless "+qa"`
- **After every plan wave:** Run `nvim --headless "+Lazy! sync" +qa && nvim --headless "+checkhealth" +qa`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | PLAT-01, PLAT-02, PLAT-03, PLAT-04 | T-01-01 | External open logic uses OS-aware helpers instead of shell-specific strings | smoke | `rg -n "xdg-open|explorer.exe|start " .config/nvim/lua` | ✅ | ⬜ pending |
| 01-02-01 | 02 | 1 | CORE-01, CORE-02, CORE-03 | T-01-02 | Buffer close never routes through implicit app quit; autosave writes only normal file buffers on approved triggers | smoke | `nvim --headless "+qa"` | ✅ | ⬜ pending |
| 01-03-01 | 03 | 2 | PLAT-01, PLAT-02, PLAT-03, CORE-01, CORE-02, CORE-03 | T-01-03 | Portability and lifecycle expectations are documented with runnable smoke steps | doc-check | `rg -n "Windows|Arch|Debian|Ubuntu|FocusLost|buffer" .planning/phases/01-reliability-and-portability-baseline` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| External default-app open on Windows | PLAT-03, PLAT-04 | Linux workspace cannot execute Windows shell integration | On a Windows machine, launch Neovim with this config, trigger the external-open keymap and neo-tree open action, confirm the system default app/file manager opens without shell errors. |
| Linux distro smoke on Arch and Debian/Ubuntu | PLAT-01, PLAT-02 | This repo is a dotfiles setup and distro-level tool availability varies by machine | On each distro target, start Neovim, run the external-open action, close a modified buffer with `<C-q>`, and verify no session-wide quit or runtime command failure occurs. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
