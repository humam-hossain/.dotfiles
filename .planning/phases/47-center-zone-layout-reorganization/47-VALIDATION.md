---
phase: "47"
slug: "center-zone-layout-reorganization"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-29"
---

# Phase 47 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash assertion harness (`scripts/phase47-center-layout-assert.sh`) + repo verifier (`./arch/dots-hyprland.sh verify --strict`) |
| **Config file** | `none — Wave 0 creates scripts/phase47-center-layout-assert.sh` |
| **Quick run command** | `bash scripts/phase47-center-layout-assert.sh -q` |
| **Full suite command** | `bash scripts/phase47-center-layout-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/phase47-center-layout-assert.sh -q`
- **After every plan wave:** Run `bash scripts/phase47-center-layout-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 47-01-01 | 01 | 0 | CNTR-01, CNTR-02, CNTR-03 | — | N/A | test-scaffold | `test -x scripts/phase47-center-layout-assert.sh && bash -n scripts/phase47-center-layout-assert.sh` | ❌ W0 | ⬜ pending |
| 47-01-02 | 01 | 1 | CNTR-01, CNTR-02, CNTR-03 | — | N/A | integration/ast | `bash scripts/phase47-center-layout-assert.sh -s 2` | ❌ W0 | ⬜ pending |
| 47-01-03 | 01 | 1 | CNTR-03 | — | N/A | unit/responsive | `bash scripts/phase47-center-layout-assert.sh -s 3` | ❌ W0 | ⬜ pending |
| 47-02-01 | 02 | 2 | CNTR-02, CNTR-03 | — | N/A | simulation/geometry | `bash scripts/phase47-center-layout-assert.sh -s 4` | ❌ W0 | ⬜ pending |
| 47-02-02 | 02 | 2 | CNTR-01, CNTR-02, CNTR-03 | — | N/A | e2e/strict-verify | `bash scripts/phase47-center-layout-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase47-center-layout-assert.sh` — 5-section validation harness covering symlink integrity, AST anchor topology, responsive date behavior, multi-resolution geometry simulation, and strict repo verification.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual verification of centered Workspaces with Clock on left and Weather on right | CNTR-01, CNTR-02, CNTR-03 | Requires active Wayland compositor session | Launch QuickShell bar in test session and confirm visual balance |
| Sidebar toggle on Clock click | CNTR-01 | Interactive pointer event | Click Clock widget and verify right sidebar opens/closes |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
