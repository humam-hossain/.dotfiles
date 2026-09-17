---
phase: "26"
slug: "qt-kde-apps-material-you-harmonization"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-17"
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Standalone Bash Assert Harness (`scripts/phase26-qt-kde-material-you-assert.sh`) |
| **Config file** | `scripts/phase26-qt-kde-material-you-assert.sh` |
| **Quick run command** | `bash scripts/phase26-qt-kde-material-you-assert.sh --section 1` |
| **Full suite command** | `bash scripts/phase26-qt-kde-material-you-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/phase26-qt-kde-material-you-assert.sh --section <N>` matching the task domain
- **After every plan wave:** Run `bash scripts/phase26-qt-kde-material-you-assert.sh && ./arch/dots-hyprland.sh verify --strict`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 26-01-01 | 01 | 0 | INTG-01 | T-26-01 | Guard-paths contract & fail-closed harness scaffold | contract | `bash scripts/phase26-qt-kde-material-you-assert.sh --help` | ❌ W0 | ⬜ pending |
| 26-01-02 | 01 | 1 | QT-01 | T-26-01 | Virtualenv readiness & environment variable check | unit | `bash scripts/phase26-qt-kde-material-you-assert.sh --section 1 && bash scripts/phase26-qt-kde-material-you-assert.sh --section 2` | ❌ W0 | ⬜ pending |
| 26-02-01 | 02 | 2 | QT-01 | T-26-02 | Darkly style engine & guard status enforcement | integration | `bash scripts/phase26-qt-kde-material-you-assert.sh --section 3` | ❌ W0 | ⬜ pending |
| 26-02-02 | 02 | 2 | QT-02 | T-26-01 | Dynamic Material You generation probe | integration | `bash scripts/phase26-qt-kde-material-you-assert.sh --section 4` | ❌ W0 | ⬜ pending |
| 26-03-01 | 03 | 3 | QT-03 | T-26-03 | Desktop file pickers & KDE application compliance | integration | `bash scripts/phase26-qt-kde-material-you-assert.sh --section 5` | ❌ W0 | ⬜ pending |
| 26-03-02 | 03 | 3 | INTG-02 | T-26-02 | Full assert harness pass & strict verification 0 findings | smoke / regression | `bash scripts/phase26-qt-kde-material-you-assert.sh && ./arch/dots-hyprland.sh verify --strict` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/phase26-qt-kde-material-you-assert.sh` — author 5-section test harness covering QT-01, QT-02, QT-03, INTG-01, INTG-02
- [ ] `guard-paths.tsv` update — add `$XDG_CONFIG_HOME/kde-material-you-colors\tgenerated_theme\tkde-material-you-colors\tUpstream directory sync`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dolphin & Gwenview visual inspection | QT-03 | Visual inspection of active UI render | Open Dolphin and Gwenview; confirm window background, view areas, and navigation sidebars inherit dark Material You palette accents from wallpaper. |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
