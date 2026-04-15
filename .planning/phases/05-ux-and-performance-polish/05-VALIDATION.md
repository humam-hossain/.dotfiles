---
phase: 5
slug: ux-and-performance-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-15
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash / nvim --headless |
| **Config file** | `arch/nvim-validate.sh` |
| **Quick run command** | `bash arch/nvim-validate.sh smoke` |
| **Full suite command** | `bash arch/nvim-validate.sh health && bash arch/nvim-validate.sh smoke` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash arch/nvim-validate.sh smoke`
- **After every plan wave:** Run `bash arch/nvim-validate.sh health && bash arch/nvim-validate.sh smoke`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | UX-02 | — | N/A | smoke | `bash arch/nvim-validate.sh smoke` | ✅ | ⬜ pending |
| 05-01-02 | 01 | 1 | UX-02 | — | N/A | health | `bash arch/nvim-validate.sh health` | ✅ | ⬜ pending |
| 05-02-01 | 02 | 1 | UX-01 | — | N/A | smoke | `bash arch/nvim-validate.sh smoke` | ✅ | ⬜ pending |
| 05-02-02 | 02 | 1 | UX-01 | — | N/A | health | `bash arch/nvim-validate.sh health` | ✅ | ⬜ pending |
| 05-03-01 | 03 | 1 | UX-01 | — | N/A | manual | verify rollout doc exists + is complete | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements (`arch/nvim-validate.sh` already validates plugin presence and health).
- Update `PLUGIN_LIST` in `arch/nvim-validate.sh` to remove `notify`, `noice`, `fzf-lua`, `alpha` and add `snacks` before smoke/health runs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Startup time improvement | UX-02 | Requires timing measurement in live Neovim | Run `nvim --startuptime /tmp/nvim-startup.log +q && tail -1 /tmp/nvim-startup.log` before and after |
| Rollout doc completeness | UX-01 | Prose quality check | Read `.planning/phases/05-ux-and-performance-polish/ROLLOUT.md`, verify all sections complete |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
