---
phase: "29"
slug: "theme-data-contracts-verification-bootstrap-integration"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-18"
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Standalone Bash Assert Harness (`scripts/phase29-theme-data-contracts-assert.sh`) |
| **Config file** | `scripts/phase29-theme-data-contracts-assert.sh` |
| **Quick run command** | `bash scripts/phase29-theme-data-contracts-assert.sh --section 1` |
| **Full suite command** | `bash scripts/phase29-theme-data-contracts-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/phase29-theme-data-contracts-assert.sh --section <N>` matching the task domain
- **After every plan wave:** Run `bash scripts/phase29-theme-data-contracts-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green (`FAIL=0`, 0 findings)
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 29-01-01 | 01 | 0 | INTG-01 | T-29-01 | Scaffolding of test harness with fail-closed structure and argument parsing | contract | `bash scripts/phase29-theme-data-contracts-assert.sh --help` | ❌ W0 | ⬜ pending |
| 29-01-02 | 01 | 1 | INTG-01 | T-29-01 | Guard paths & .gitignore parity, collision map, restow table, and PAIR_COUNT | contract | `bash scripts/phase29-theme-data-contracts-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 29-01-03 | 01 | 1 | INTG-01, INTG-02 | T-29-01 | Package relocation to restow/ and strict verification engine pass | integration | `bash scripts/phase29-theme-data-contracts-assert.sh --section 3` | ❌ W0 | ⬜ pending |
| 29-02-01 | 02 | 2 | INTG-01 | T-29-02 | Live theme switching zero git churn drill with porcelain brackets | integration | `bash scripts/phase29-theme-data-contracts-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 29-02-02 | 02 | 2 | INTG-03 | T-29-02 | Bootstrap orchestrator destub, Catppuccin unlinking, parent dir pre-creation, fallback theming | integration | `bash scripts/phase29-theme-data-contracts-assert.sh --section 4` | ❌ W0 | ⬜ pending |
| 29-02-03 | 02 | 2 | INTG-01..03 | T-29-02 | Full multi-phase v0.5 regression sweep across phase 25-28 | regression | `bash scripts/phase29-theme-data-contracts-assert.sh --section 5` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase29-theme-data-contracts-assert.sh` — Phase 29 assert harness scaffold with `--section <1-5>` dispatch and fail-closed reporting

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | INTG-01..03 | Fully automated | All phase behaviors have automated verification in `scripts/phase29-theme-data-contracts-assert.sh` |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
