---
phase: "46"
slug: "left-zone-integration-verification-repository-integrity"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-29"
---

# Phase 46 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash assertion harness (`scripts/phase46-telemetry-assert.sh`) + `arch/dots-hyprland.sh verify --strict` |
| **Config file** | none — Wave 0 creates `scripts/phase46-telemetry-assert.sh` |
| **Quick run command** | `./scripts/phase46-telemetry-assert.sh -q` |
| **Full suite command** | `./scripts/phase46-telemetry-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase46-telemetry-assert.sh -q` (or specific section `./scripts/phase46-telemetry-assert.sh -s <N>`)
- **After every plan wave:** Run `./scripts/phase46-telemetry-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green (`FAIL=0 FINDINGS=0`)
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 46-01-01 | 01 | 0 | INTG-03 | — | N/A (Harness scaffold) | smoke | `test -x scripts/phase46-telemetry-assert.sh && bash -n scripts/phase46-telemetry-assert.sh` | ❌ W0 | ⬜ pending |
| 46-01-02 | 01 | 1 | INTG-01 | — | N/A (Layout reorder & AST) | integration | `./scripts/phase46-telemetry-assert.sh -s 2` | ❌ W0 | ⬜ pending |
| 46-01-03 | 01 | 1 | INTG-01 | — | N/A (Storage-first reorder) | integration | `./scripts/phase46-telemetry-assert.sh -s 3` | ❌ W0 | ⬜ pending |
| 46-01-04 | 01 | 1 | INTG-02 | — | Upstream submodule clean | integrity | `./scripts/phase46-telemetry-assert.sh -s 1 && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |
| 46-02-01 | 02 | 2 | INTG-03 | — | Liveness & centering | integration | `./scripts/phase46-telemetry-assert.sh -s 4 -s 5` | ❌ W0 | ⬜ pending |
| 46-02-02 | 02 | 2 | INTG-01..03 | — | Full milestone sign-off | e2e | `./scripts/phase46-telemetry-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase46-telemetry-assert.sh` — assertion harness covering Sections 1–6 (scaffold in Plan 46-01 Wave 0 or Plan 46-02)

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual aesthetic of Left zone pill sequence | INTG-01 | Human eye inspection of pill appearance | Observe bar: LeftSidebarButton → Storage/Memory → CPU/GPU → Network/Ping |
| Workspace dead-centering across monitor widths | INTG-01 | Visual centering check across multi-monitors / window resize | Verify workspaces stay visually centered on bar |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
