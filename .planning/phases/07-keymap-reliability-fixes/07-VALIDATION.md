---
phase: 07
slug: keymap-reliability-fixes
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
updated: 2026-04-22
---

# Phase 07 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | shell + headless Neovim commands + manual keypress regression |
| **Config file** | `scripts/nvim-validate.sh` |
| **Quick run command** | `./scripts/nvim-validate.sh startup` |
| **Full suite command** | `./scripts/nvim-validate.sh all` |
| **Estimated runtime** | ~30-60 seconds plus manual repro |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/nvim-validate.sh startup`
- **After every plan wave:** Run `./scripts/nvim-validate.sh all`
- **Before `$gsd-verify-work`:** Full suite must be green and manual keymap matrix complete
- **Max feedback latency:** 60 seconds for automated checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | BUG-01 | T-07-01 | Broken shared keymaps are function actions, not fragile string notations | integration | `./scripts/nvim-validate.sh startup && ./scripts/nvim-validate.sh smoke` | ✅ | ⬜ pending |
| 07-01-02 | 01 | 1 | BUG-01 | T-07-02 | Attachment helper uses valid registry scope token for plugin-local maps | static | `rg -n 'plugin-local|plugin_local' .config/nvim/lua/core/keymaps/attach.lua .config/nvim/lua/core/keymaps/registry.lua` | ✅ | ⬜ pending |
| 07-02-01 | 02 | 2 | BUG-01 | T-07-03 | Every confirmed shared keymap from Phase 6 executes without E488/Lua runtime error | manual | `./scripts/nvim-validate.sh all` | ✅ | ⬜ pending |
| 07-02-02 | 02 | 2 | BUG-01 | T-07-04 | Failure inventory and checklist reflect fixed status and post-fix expectations | static | `rg -n 'BUG-005|BUG-012|Fixed|Expected:' .planning/phases/06-runtime-failure-inventory/FAILURES.md .planning/phases/06-runtime-failure-inventory/CHECKLIST.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers automated validation:
  - `scripts/nvim-validate.sh`
  - `.planning/phases/06-runtime-failure-inventory/CHECKLIST.md`
  - `.planning/phases/06-runtime-failure-inventory/FAILURES.md`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `<leader>b`, `<leader>lw`, `<leader>sn`, `<leader>xs`, `<leader>v`, `<leader>h`, `<leader>se` execute cleanly | BUG-01 | Shared keymaps require interactive keypress | Open Neovim, trigger each keymap, confirm expected action happens and no E488/Lua error appears |
| `<leader>gp`, `<leader>gt` execute cleanly in git-tracked file | BUG-01 | Gitsigns behavior requires loaded plugin and git context | Open modified tracked file, trigger both mappings, confirm preview/blame toggle works with no invalid-action error |
| which-key/help text still matches shared keymap behavior | BUG-01 | Human-facing descriptions are easiest to validate interactively | Trigger which-key on affected groups and confirm labels still describe actual behavior |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or manual checklist coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all implementation files
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Phase 07 ready for execution
