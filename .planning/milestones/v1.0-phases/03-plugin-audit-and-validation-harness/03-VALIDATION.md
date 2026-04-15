---
phase: 03
slug: plugin-audit-and-validation-harness
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-15
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | shell + headless Neovim commands |
| **Config file** | none — Wave 0 installs validation entrypoint |
| **Quick run command** | `nvim --headless "+qa"` |
| **Full suite command** | `./scripts/nvim-validate.sh all` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `nvim --headless "+qa"`
- **After every plan wave:** Run `./scripts/nvim-validate.sh all`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | PLUG-01 | T-03-01 | Every effective plugin receives explicit keep/remove/replace decision with rationale | audit | `rg -n "keep|remove|replace" .planning/phases/03-plugin-audit-and-validation-harness/03-PLUGIN-AUDIT.md` | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 1 | TOOL-01 | T-03-02 | Validation entrypoint runs non-interactively and writes report artifacts | integration | `./scripts/nvim-validate.sh all` | ❌ W0 | ⬜ pending |
| 03-03-01 | 03 | 2 | PLUG-03 / TOOL-03 | T-03-03 | Lockfile matches audited plugin set and missing tools surface via health output, not startup noise | integration | `./scripts/nvim-validate.sh health` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/nvim-validate.sh` — repo-owned validation entrypoint
- [ ] `.config/nvim/lua/core/health.lua` or equivalent — machine-readable health/report helper
- [ ] report output path under `.planning/phases/03-plugin-audit-and-validation-harness/` or `.planning/tmp/`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Audit rationale quality | PLUG-01 | Human judgment needed for keep/remove/replace decisions | Read `03-PLUGIN-AUDIT.md` and confirm every plugin has explicit rationale, not placeholder text |
| Cross-platform fallback wording | TOOL-03 | Windows/Linux install guidance may need human review | Inspect generated health report and confirm affected feature + install guidance are clear |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
