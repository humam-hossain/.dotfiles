---
phase: 1
slug: shell-foundation-theme
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-21
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual QML validation (quickshell runtime) |
| **Config file** | none — no formal test framework for QML |
| **Quick run command** | `quickshell 2>&1 | head -50` |
| **Full suite command** | `quickshell --check-syntax 2>&1; quickshell 2>&1 | head -100` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `quickshell 2>&1 | head -50`
- **After every plan wave:** Run `quickshell --check-syntax 2>&1; quickshell 2>&1 | head -100`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | FWK-01 | — | N/A | manual | `ls -la .config/quickshell/` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 1 | FWK-03 | — | N/A | manual | `quickshell 2>&1 | head -20` | ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 1 | FWK-04 | — | N/A | manual | `quickshell 2>&1 | grep -i panel` | ❌ W0 | ⬜ pending |
| 01-04-01 | 04 | 2 | THM-01, THM-02 | — | N/A | manual | `quickshell 2>&1 | grep -i theme` | ❌ W0 | ⬜ pending |
| 01-05-01 | 05 | 2 | FWK-05 | — | N/A | manual | `quickshell 2>&1 | grep -i service` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Verify `quickshell` binary is installed and accessible
- [ ] Verify `../dots-hyprland/dots/.config/quickshell/ii/` source exists
- [ ] Verify `materialyoucolor` Python library is available
- [ ] Verify `arch/quickshell.sh` symlink mechanism works

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Bar renders on DP-1 and HDMI-A-2 | FWK-01 | Requires live Quickshell with Hyprland session | Launch `quickshell`, verify bars appear on both monitors |
| Material theme tokens accessible in QML | THM-01, THM-02 | Requires runtime QML property inspection | Check Appearance.m3colors properties are non-null at runtime |
| PanelLoader loads ii family | FWK-04 | Requires visual confirmation of panel content | Verify panel components render (bar, sidebar stubs) |
| Service singleton consumable | FWK-05 | Requires runtime QML binding test | Verify at least one service provides live data to a widget |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
