---
phase: "23"
slug: "one-command-bootstrap"
status: ready_for_execution
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-15"
---

# Phase 23 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash Assert Suite (`scripts/phase23-bootstrap-assert.sh`) |
| **Config file** | `scripts/phase23-bootstrap-assert.sh` (Wave 0 scaffolds) |
| **Quick run command** | `./scripts/phase23-bootstrap-assert.sh --section 1` |
| **Full suite command** | `./scripts/phase23-bootstrap-assert.sh && ./arch/dots-hyprland.sh verify --strict && ./scripts/phase17-unblock-assert.sh` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase23-bootstrap-assert.sh --section {N}`
- **After every plan wave:** Run `./scripts/phase23-bootstrap-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 23-01-01 | 01 | 1 | BOOT-01 | T-23-01 | Non-root EUID check & safe CLI flag parser | unit | `./scripts/phase23-bootstrap-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 23-01-02 | 01 | 1 | BOOT-01 | T-23-02 | JSON state machine persistence & atomic updates | unit | `./scripts/phase23-bootstrap-assert.sh --section 3` | ❌ W0 | ⬜ pending |
| 23-02-01 | 02 | 2 | BOOT-02 | T-23-03 | De-stub discovery, safe backup archive & MANIFEST.txt | integration | `./scripts/phase23-bootstrap-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 23-02-02 | 02 | 2 | BOOT-02 | T-23-04 | Pre-create dirs, link stow/restow without folding | integration | `./scripts/phase23-bootstrap-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 23-02-03 | 02 | 2 | BOOT-02 | T-23-05 | Capture baseline seed atomic copy & JSON validation | unit | `./scripts/phase23-bootstrap-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 23-03-01 | 03 | 3 | BOOT-05 | T-23-06 | Snapshots native/aur packages with headers | unit | `./scripts/phase23-bootstrap-assert.sh --section 4` | ❌ W0 | ⬜ pending |
| 23-03-02 | 03 | 3 | BOOT-03 | T-23-07 | Relogin banner, stage split, graphical probe | integration | `./scripts/phase23-bootstrap-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 23-03-03 | 03 | 3 | BOOT-04 | T-23-08 | Final verify exit code gate & live host dry-run | e2e | `./scripts/phase23-bootstrap-assert.sh --section 5` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase23-bootstrap-assert.sh` — test harness scaffolding with 5 section targets covering CLI, de-stubbing, resumability, snapshots, and verification.
- [ ] `./bootstrap.sh` stub entry point at repo root with `--help` and basic options.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Physical session relogin and compositor restart into `hyprland.lua` | BOOT-03 | Headless test runner cannot terminate display server and restart login greeter interactively | Verify Stage 1 pauses with border box instructions; log out via `hyprctl dispatch exit`; log back in via SDDM; verify Hyprland desktop loads. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved (ready for execution)
