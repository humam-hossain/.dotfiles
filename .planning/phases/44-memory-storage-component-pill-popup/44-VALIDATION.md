---
phase: "44"
slug: "memory-storage-component-pill-popup"
status: draft
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-28"
updated: "2026-09-28"
---

# Phase 44 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom Bash assertion harness (`scripts/phase44-memory-storage-assert.sh`) |
| **Config file** | `scripts/phase44-memory-storage-assert.sh` |
| **Quick run command** | `./scripts/phase44-memory-storage-assert.sh 1` |
| **Full suite command** | `./scripts/phase44-memory-storage-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase44-memory-storage-assert.sh 1` (or target section)
- **After every plan wave:** Run `./scripts/phase44-memory-storage-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 44-01-01 | 01 | 0 | MEMDSK-01, MEMDSK-04 | T-44-SC | fail closed non-root | test-harness | `test -x scripts/phase44-memory-storage-assert.sh && bash -n scripts/phase44-memory-storage-assert.sh` | ❌ W0 | ⬜ pending |
| 44-01-02 | 01 | 1 | MEMDSK-01, MEMDSK-04 | T-44-01 | safe procfs parsing & non-blocking polling | unit | `./scripts/phase44-memory-storage-assert.sh 1` | ❌ W0 | ⬜ pending |
| 44-01-03 | 01 | 2 | MEMDSK-01, MEMDSK-02 | T-44-02 | layout parity & bounded geometry | unit | `./scripts/phase44-memory-storage-assert.sh 2` | ❌ W0 | ⬜ pending |
| 44-02-01 | 02 | 1 | MEMDSK-02, MEMDSK-03 | T-44-03 | sanitized mount labels & bounded popup geometry | unit | `./scripts/phase44-memory-storage-assert.sh 3` | ❌ W0 | ⬜ pending |
| 44-02-02 | 02 | 2 | MEMDSK-01..04 | T-44-04 | strict stow verification & zero dirty drift | integration | `./scripts/phase44-memory-storage-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase44-memory-storage-assert.sh` — assertion harness covering 5 sections: service procfs parsing & timer lifecycle, status bar pill layout & styling, popup inspector layout & tiers, multi-mount and FUSE cloud display, and GNU Stow leaf symlink verification.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Status Bar Visual Parity & Pulse Animation | MEMDSK-01, MEMDSK-02 | Visual verification of circular progress rings, typography, and pulse animation requires interactive display | Inspect top status bar left zone; verify RAM and storage circular rings render beside CPU/GPU pill with identical sizing and typography; test high-load pulse animation |
| Popup Inspector Hover Intent & Multi-Mount Rendering | MEMDSK-02, MEMDSK-03 | GUI visual appearance and popup hover intent timing require interactive desktop inspection | Hover over `MemoryStoragePill`; verify 1000ms hover intent delay and smooth popup appearance; verify two-column layout with memory tiers on left and storage drives on right |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** draft 2026-09-28
