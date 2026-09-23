---
phase: "39"
slug: "dynamic-media-popup-anchoring"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-23"
---

# Phase 39 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom Bash Test Harness + Quickshell AST / Headless Assertion Runner |
| **Config file** | `scripts/phase39-media-popup-assert.sh` |
| **Quick run command** | `./scripts/phase39-media-popup-assert.sh --syntax` |
| **Full suite command** | `./scripts/phase39-media-popup-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase39-media-popup-assert.sh --syntax`
- **After every plan wave:** Run `./scripts/phase39-media-popup-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 0 | INTG-01 | — | Restow overlay leaf symlink integrity without directory folding | integration | `./scripts/phase39-media-popup-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 39-01-02 | 01 | 1 | MEDIA-01 | — | Coordinates mapped via `mapToItem` to root window coordinates; multi-monitor screen bound | unit/ast | `./scripts/phase39-media-popup-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 39-01-03 | 01 | 1 | MEDIA-02 | — | Boundary clamping enforces `Appearance.sizes.hyprlandGapsOut` across displays; fallback matches center | unit/math | `./scripts/phase39-media-popup-assert.sh --section 3` | ❌ W0 | ⬜ pending |
| 39-01-04 | 01 | 1 | MEDIA-01, MEDIA-02 | — | Multi-monitor screen target binding and dismissal reset lifecycle | integration | `./scripts/phase39-media-popup-assert.sh --section 4` | ❌ W0 | ⬜ pending |
| 39-01-05 | 01 | 1 | INTG-02, INTG-03 | — | Clean repository status with zero submodule diff and strict dots verification | smoke | `./scripts/phase39-media-popup-assert.sh --section 5` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase39-media-popup-assert.sh` — Test harness covering Sections 1–5 with `--section` and `--syntax` flags
- [ ] `restow/quickshell/.config/quickshell/ii/GlobalStates.qml` — Base state bridge overlay
- [ ] `restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml` — Base media controls overlay

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual popup animation & live MPRIS interaction | MEDIA-01 | Requires active compositor session and visual inspection | Left-click Media pill in top bar, confirm popup opens directly beneath pill with smooth layer-shell appearance |
| Multi-monitor dynamic placement | MEDIA-01 | Physical multi-monitor click testing | Click Media pill on secondary monitor bar, confirm popup opens on secondary monitor |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
