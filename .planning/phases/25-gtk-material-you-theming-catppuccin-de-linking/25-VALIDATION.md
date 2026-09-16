---
phase: "25"
slug: "gtk-material-you-theming-catppuccin-de-linking"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-16"
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Custom Bash assertion harness (`scripts/phase25-gtk-material-you-assert.sh`) |
| **Config file** | `scripts/phase25-gtk-material-you-assert.sh` |
| **Quick run command** | `bash scripts/phase25-gtk-material-you-assert.sh` |
| **Full suite command** | `bash scripts/phase25-gtk-material-you-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/phase25-gtk-material-you-assert.sh`
- **After every plan wave:** Run `bash scripts/phase25-gtk-material-you-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-01-01 | 01 | 0 | INTG-01 | — | Fail-closed test harness scaffold | harness | `bash scripts/phase25-gtk-material-you-assert.sh || [ $? -ne 0 ]` | ❌ W0 | ⬜ pending |
| 25-01-02 | 01 | 1 | GTK-02 | T-25-01 | Safe unprivileged inode conversion | unit | `bash scripts/phase25-gtk-material-you-assert.sh --section 1` | ❌ W0 | ⬜ pending |
| 25-02-01 | 02 | 1 | GTK-03 | T-25-03 | Settings files clean with dark defaults | unit | `bash scripts/phase25-gtk-material-you-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 25-02-02 | 02 | 1 | GTK-04 | — | GSettings align with dark defaults | unit | `bash scripts/phase25-gtk-material-you-assert.sh --section 3` | ❌ W0 | ⬜ pending |
| 25-03-01 | 03 | 2 | GTK-01 | T-25-02 | Non-interactive Matugen CSS generation | integration | `bash scripts/phase25-gtk-material-you-assert.sh --section 4` | ❌ W0 | ⬜ pending |
| 25-03-02 | 03 | 2 | INTG-02 | T-25-03 | Zero git churn & strict guard compliance | integration | `bash scripts/phase25-gtk-material-you-assert.sh --section 5 && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase25-gtk-material-you-assert.sh` — automated assertion suite covering sections 1–5 for GTK-01, GTK-02, GTK-03, GTK-04, INTG-01, INTG-02

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual GTK app rendering | GTK-01 / GTK-03 | Visual inspection of running GTK applications | Open a GTK 3 app (e.g. `pavucontrol` or `nwg-look`) and GTK 4 app (`gnome-calculator` or `nautilus`) and confirm dark Material You color accents apply properly. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
