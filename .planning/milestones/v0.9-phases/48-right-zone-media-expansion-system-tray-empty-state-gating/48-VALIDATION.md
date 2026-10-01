---
phase: "48"
slug: "right-zone-media-expansion-system-tray-empty-state-gating"
status: draft
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-30"
---

# Phase 48 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash assertion harness (`scripts/phase48-right-zone-assert.sh`) + repo verifier (`./arch/dots-hyprland.sh verify --strict`) |
| **Config file** | `none — Wave 0 creates scripts/phase48-right-zone-assert.sh` |
| **Quick run command** | `bash scripts/phase48-right-zone-assert.sh -q` |
| **Full suite command** | `bash scripts/phase48-right-zone-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/phase48-right-zone-assert.sh -q`
- **After every plan wave:** Run `bash scripts/phase48-right-zone-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 48-01-01 | 01 | 0 | RGHT-01, RGHT-02, RGHT-03 | — | N/A | test-scaffold | `test -x scripts/phase48-right-zone-assert.sh && bash -n scripts/phase48-right-zone-assert.sh` | ❌ W0 | ⬜ pending |
| 48-01-02 | 01 | 1 | RGHT-01, RGHT-03 | — | N/A | integration/ast | `bash scripts/phase48-right-zone-assert.sh -s 2` | ❌ W0 | ⬜ pending |
| 48-01-03 | 01 | 1 | RGHT-02 | — | N/A | unit/typography | `bash scripts/phase48-right-zone-assert.sh -s 3` | ❌ W0 | ⬜ pending |
| 48-02-01 | 02 | 2 | RGHT-01, RGHT-03 | — | N/A | simulation/math | `bash scripts/phase48-right-zone-assert.sh -s 4` | ❌ W0 | ⬜ pending |
| 48-02-02 | 02 | 2 | RGHT-01, RGHT-02, RGHT-03 | — | N/A | e2e/strict-verify | `bash scripts/phase48-right-zone-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase48-right-zone-assert.sh` — 5-section validation harness covering stow leaf symlinks, BarContent responsive equation & tray gating AST, Media.qml StyledText typography & elision AST, math equation simulation, and strict repo verification.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual verification of responsive media pill width across monitors | RGHT-01 | Requires active Wayland compositor session on physical monitors | Play song in Spotify/mpv on DP-1 (ultrawide) and HDMI-A-2; verify width scales naturally |
| Visual verification of primary title / muted artist visual separation | RGHT-02 | Visual perception of font styling & color tokens | Check top bar media pill; confirm clean bullet separator and proper contrast |
| Empty-state system tray hiding and reflow | RGHT-03 | Dynamic process lifecycle across D-Bus SNI | Close all tray apps (or test without tray apps); confirm sysTray pill completely disappears with zero border artifact |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** draft
