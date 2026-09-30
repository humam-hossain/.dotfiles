---
phase: "49"
slug: "quickshell-resource-profiling-component-performance-audit"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-30"
---

# Phase 49 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash Assertion Harness (`scripts/phase49-audit-assert.sh`, `scripts/profile-quickshell.sh`) |
| **Config file** | `scripts/phase49-audit-assert.sh` (Wave 0 scaffold) |
| **Quick run command** | `bash scripts/phase49-audit-assert.sh -s 1` |
| **Full suite command** | `bash scripts/phase49-audit-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/phase49-audit-assert.sh -s 1` (or relevant section `-s <N>`)
- **After every plan wave:** Run `bash scripts/phase49-audit-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 49-01-01 | 01 | 1 | AUDIT-01 | T-49-01 | Safe harness execution without root privileges | unit | `test -x scripts/phase49-audit-assert.sh && bash -n scripts/phase49-audit-assert.sh` | ❌ W0 | ⬜ pending |
| 49-01-02 | 01 | 1 | AUDIT-01 | T-49-03 | Non-destructive telemetry sampling with media playback preflight check | integration | `bash scripts/phase49-audit-assert.sh -s 2` | ❌ W0 | ⬜ pending |
| 49-02-01 | 02 | 2 | AUDIT-02 | T-49-06 | Calibrated Wayland 2x coordinate dispatch & stage registry validation | unit | `bash -n scripts/profile-quickshell.sh && ./scripts/profile-quickshell.sh --list-stages \| grep -q "popup_cpugpu"` | ✅ | ⬜ pending |
| 49-02-02 | 02 | 2 | AUDIT-02 | T-49-05 | Full interactive popup execution & layer verification | integration | `bash scripts/phase49-audit-assert.sh -s 3` | ❌ W0 | ⬜ pending |
| 49-03-01 | 03 | 3 | AUDIT-03 | T-49-09 | Stable QML bindings, capped spectrum loops, and relaxed polling intervals | integration | `bash scripts/phase49-audit-assert.sh -s 4` | ❌ W0 | ⬜ pending |
| 49-03-02 | 03 | 3 | AUDIT-03 | T-49-12 | Zero GNU Stow symlink drift and repository strict compliance | regression | `bash scripts/phase49-audit-assert.sh -s 5 && ./arch/dots-hyprland.sh verify --strict` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase49-audit-assert.sh` — assertion harness covering sections 1–5
- [ ] Extension of `scripts/profile-quickshell.sh` — automated baseline capture, interactive popup suite, and JSON telemetry export

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual Popup Rendering Verification | AUDIT-02 | Visual aesthetics & popup alignment | Inspect desktop display during popup activation to ensure no clipping or rendering glitching |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
