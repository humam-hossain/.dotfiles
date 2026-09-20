---
phase: "34"
slug: "verification-zero-drift-bootstrap-integration"
status: ready
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-20"
---

# Phase 34 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom Bash test harness (`scripts/phase34-verification-assert.sh`) + `arch/dots-hyprland.sh verify --strict` |
| **Config file** | `guard-paths.tsv`, `collision-map.tsv`, `arch/dots-hyprland.sh` |
| **Quick run command** | `bash scripts/phase34-verification-assert.sh --section 1` |
| **Full suite command** | `bash scripts/phase34-verification-assert.sh` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/phase34-verification-assert.sh --section <N>` (or quick verification command)
- **After every plan wave:** Run `bash scripts/phase34-verification-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green (`FAIL=0` across all 5 sections)
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-01 | 01 | 1 | INTG-02 | T-34-01 | Baseline tracked files committed cleanly | integration | `git status --porcelain capture stow \| wc -l \| grep -q '^0$' && ./arch/dots-hyprland.sh verify --strict \| grep -q 'FINDINGS=0'` | ✅ | ⬜ pending |
| 34-01-02 | 01 | 1 | INTG-03 | T-34-02 | Stow pre-creation and color priming verified | unit | `bash -n bootstrap.sh && grep -q '\.config/quickshell/ii/modules/ii/bar' bootstrap.sh && grep -q 'colors.json' bootstrap.sh` | ✅ | ⬜ pending |
| 34-01-03 | 01 | 1 | INTG-01 | — | Phase 31 borderless check aligned for Phase 33 layout | regression | `bash scripts/phase31-overlay-pill-assert.sh && bash scripts/phase32-component-formatting-assert.sh && bash scripts/phase33-layout-assert.sh` | ✅ | ⬜ pending |
| 34-02-01 | 02 | 2 | INTG-01, INTG-02, INTG-03 | T-34-07 | 5-section verification assert script authored | unit | `test -x scripts/phase34-verification-assert.sh && bash scripts/phase34-verification-assert.sh --help \| grep -q -- '--section <1-5>' && bash scripts/phase34-verification-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 34-02-02 | 02 | 2 | INTG-01, INTG-02, INTG-03 | T-34-05, T-34-06 | Full test harness execution & zero working tree drift | integration | `bash scripts/phase34-verification-assert.sh && ./arch/dots-hyprland.sh verify --strict \| grep -q 'FINDINGS=0'` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase34-verification-assert.sh` — test harness covering INTG-01, INTG-02, INTG-03

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | — | All phase behaviors have automated verification. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** verified 2026-09-20
