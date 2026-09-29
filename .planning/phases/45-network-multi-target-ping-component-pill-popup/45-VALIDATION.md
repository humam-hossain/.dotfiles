---
phase: "45"
slug: "network-multi-target-ping-component-pill-popup"
status: draft
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-29"
updated: "2026-09-29"
---

# Phase 45 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom Bash assertion harness (`scripts/phase45-network-ping-assert.sh`) |
| **Config file** | `scripts/phase45-network-ping-assert.sh` |
| **Quick run command** | `./scripts/phase45-network-ping-assert.sh 1` |
| **Full suite command** | `./scripts/phase45-network-ping-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase45-network-ping-assert.sh [1-5]` (target section)
- **After every plan wave:** Run `./scripts/phase45-network-ping-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 45-01-01 | 01 | 0 | NETPING-01, NETPING-03 | T-45-SC | fail closed non-root | test-harness | `test -x scripts/phase45-network-ping-assert.sh && bash -n scripts/phase45-network-ping-assert.sh` | ❌ W0 | ⬜ pending |
| 45-01-02 | 01 | 1 | NETPING-01, NETPING-03 | T-45-01 | safe procfs parsing & non-blocking polling | unit | `./scripts/phase45-network-ping-assert.sh 1` | ❌ W0 | ⬜ pending |
| 45-01-03 | 01 | 2 | NETPING-01, NETPING-02, NETPING-05 | T-45-02 | layout parity & bounded geometry | unit | `./scripts/phase45-network-ping-assert.sh 2` | ❌ W0 | ⬜ pending |
| 45-02-01 | 02 | 1 | NETPING-04, NETPING-05 | T-45-03 | sanitized telemetry & bounded popup geometry | unit | `./scripts/phase45-network-ping-assert.sh 3` | ❌ W0 | ⬜ pending |
| 45-02-02 | 02 | 2 | NETPING-01..05 | T-45-04 | strict stow verification & zero dirty drift | integration | `./scripts/phase45-network-ping-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase45-network-ping-assert.sh` — assertion harness covering 5 sections: service procfs parsing & timer lifecycle, status bar pill layout & ping presentation, popup inspector two-column layout & diagnostic cards, formatting math & live system probes, and GNU Stow leaf symlink verification.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Status Bar Visual Parity & Ping Colors | NETPING-01, NETPING-02 | Visual verification of directional glyphs, vertical divider, ping target MaterialSymbols, and latency coloring requires interactive display | Inspect top status bar left zone; verify throughput glyphs and 3 ping target latencies render beside memory/storage pill; test health coloring (green/amber/red) |
| Popup Inspector Hover Intent & Diagnostic Cards | NETPING-04, NETPING-05 | GUI visual appearance, popup hover intent timing, and web browser launch on click require interactive desktop inspection | Hover over `NetworkPingPill`; verify 1000ms hover intent delay and smooth popup appearance; verify two-column layout with interface card on left and 3 ping diagnostic cards on right; click pill or dashboard button to verify browser opens `http://127.0.0.1:8765/` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** draft 2026-09-29
