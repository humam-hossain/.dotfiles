---
phase: 09
slug: health-signal-cleanup
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
updated: 2026-04-22
---

# Phase 09 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | shell validator + headless Neovim health capture + manual tmux/open verification |
| **Config file** | `scripts/nvim-validate.sh` |
| **Quick run command** | `./scripts/nvim-validate.sh checkhealth` |
| **Full suite command** | `./scripts/nvim-validate.sh all` |
| **Estimated runtime** | ~60-120 seconds plus interactive tmux/external-open checks |

---

## Sampling Rate

- **After every task commit:** Run the task-scoped grep or headless check listed below.
- **After every plan wave:** Run `./scripts/nvim-validate.sh health` and `./scripts/nvim-validate.sh checkhealth`.
- **Before `$gsd-verify-work`:** Run `./scripts/nvim-validate.sh all`, then complete tmux pane-crossing and external-open verification recorded in `CHECKLIST.md`.
- **Max feedback latency:** 30 seconds for grep/module checks; 120 seconds for validator gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | HEAL-01 | T-09-01, T-09-02 | Validator captures full `:checkhealth` report to artifact, hardcodes required-tool fail gate in bash, and documents any reserved provider-only failures for 09-02 | integration | `./scripts/nvim-validate.sh checkhealth || (test -f .planning/tmp/nvim-validate/checkhealth.txt && rg -n '^ERROR:' .planning/tmp/nvim-validate/checkhealth.txt)` | ✅ `scripts/nvim-validate.sh` | ⬜ pending |
| 09-01-02 | 01 | 1 | HEAL-01 | T-09-03, T-09-04 | Tmux companion bindings and BUG-020 investigation leave evidence-backed outcomes in checklist and failure inventory | manual | `./scripts/nvim-validate.sh checkhealth` | ✅ `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md` | ⬜ pending |
| 09-02-01 | 02 | 2 | HEAL-01, HEAL-02 | T-09-05 | `core.health` exports reusable probes, owns required metadata, and no longer behaves as a broken auto-discovered provider | integration | `nvim --headless -u .config/nvim/init.lua --cmd \"set rtp^=.config/nvim\" +\"lua local h=require('core.health'); assert(type(h.probe_tool)=='function'); assert(type(h.probe_plugin)=='function'); vim.cmd('qa!')\"` | ✅ `.config/nvim/lua/core/health.lua` | ⬜ pending |
| 09-02-02 | 02 | 2 | HEAL-01, HEAL-02 | T-09-06, T-09-07, T-09-08 | `:checkhealth config` renders required/optional/env tiers and validator docs expose `checkhealth` command | integration | `./scripts/nvim-validate.sh health && ./scripts/nvim-validate.sh checkhealth && rg -n 'nvim-validate\\.sh checkhealth' .config/nvim/README.md` | ✅ `.config/nvim/lua/config/health.lua` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers automated validation:
  - `scripts/nvim-validate.sh`
  - `.planning/phases/06-runtime-failure-inventory/FAILURES.md`
  - `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md`
- No extra harness needed before execution; Phase 9 extends current validator rather than introducing a second tool.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| tmux cross-pane traversal with `<C-h/j/k/l>` | HEAL-01 | Requires live tmux + Neovim pane movement | Reload `.tmux.conf`, enter tmux, move from Neovim split into adjacent tmux panes and back, then record result in `CHECKLIST.md` |
| BUG-020 root-cause proof for external-open keybinding | HEAL-01 | Requires terminal key delivery and host opener behavior | Run `:verbose nmap <C-S-o>`, direct `vim.ui.open(...)`, shell `xdg-open`, then test final binding and record exact result in `CHECKLIST.md` |
| `:checkhealth config` readability | HEAL-02 | Severity tiers and guidance are easiest to verify interactively | Open Neovim, run `:checkhealth config`, confirm required tools show as errors, optional/environment entries as warnings, and six sections render cleanly |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or manual checklist coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all implementation files
- [x] No watch-mode flags
- [x] Feedback latency < 30s for task checks and < 120s for validator gates
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Phase 09 ready for execution
