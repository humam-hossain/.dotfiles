---
phase: "22"
slug: "kde-and-gtk-capture"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-15"
validated: "2026-09-16"
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash Test Harness (`scripts/phase22-kde-and-gtk-capture-assert.sh`) |
| **Config file** | None (self-contained executable assert script) |
| **Quick run command** | `./scripts/phase22-kde-and-gtk-capture-assert.sh --section <1-6>` |
| **Full suite command** | `./scripts/phase22-kde-and-gtk-capture-assert.sh && ./arch/dots-hyprland.sh verify --strict` |
| **Estimated runtime** | ~6 seconds |

---

## Sampling Rate

- **After every task commit:** Run `./scripts/phase22-kde-and-gtk-capture-assert.sh --section <N>`
- **After every plan wave:** Run `./scripts/phase22-kde-and-gtk-capture-assert.sh`
- **Before `/gsd-verify-work`:** Full suite must be green AND `./arch/dots-hyprland.sh verify --strict` exits 0 with `FAIL=0 FINDINGS=0`
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 22-01-01 | 01 | 1 | KDE-01 | T-22-01 | Live KDE adoption via SAFE-01 (`.bak.<epoch>`), single `stow/kde/` package layout, inode identity, 0600 mode documented harmless | integration | `./scripts/phase22-kde-and-gtk-capture-assert.sh --section 1` | ✅ exists | ✅ green |
| 22-01-02 | 01 | 1 | KDE-01 | T-22-02 | Write-through validation: scratch XDG `kwriteconfig6` drill & live `kiorc` double-toggle test | integration / drill | `./scripts/phase22-kde-and-gtk-capture-assert.sh --section 2` | ✅ exists | ✅ green |
| 22-02-01 | 02 | 2 | KDE-02 | T-22-05 | GTK per-file stowing under `stow/gtk/`, unfolded parent dirs (`~/.config/gtk-3.0`, `~/.config/gtk-4.0`), `gtk-dark.css` gitignored | integration | `test -L "$HOME/.config/gtk-3.0/settings.ini" && test -L "$HOME/.config/gtk-3.0/bookmarks" && test -L "$HOME/.config/gtk-4.0/settings.ini" && test -d "$HOME/.config/gtk-3.0" && test ! -L "$HOME/.config/gtk-3.0"` | ✅ exists | ✅ green |
| 22-02-02 | 02 | 2 | KDE-02 | T-22-06 | GTK layout verification, unfolded parent directory assertion, and scratch link severance test | integration / drill | `./scripts/phase22-kde-and-gtk-capture-assert.sh --section 3` | ✅ exists | ✅ green |
| 22-03-01 | 03 | 3 | KDE-02 | T-22-09 | GUARD list data file (`guard-paths.tsv`), Q7/Q8 measurement docs, `kdeglobals` retirement to `docs/archive/`, live unlinking | integration | `test -f guard-paths.tsv && test -f docs/archive/kdeglobals && test ! -e restow/kdeglobals && test ! -L "$HOME/.config/kdeglobals"` | ✅ exists | ✅ green |
| 22-03-02 | 03 | 3 | KDE-02 | T-22-09 | `run_verify` GUARD check and sweep classifier refinement in `arch/dots-hyprland.sh` | integration / static | `./scripts/phase22-kde-and-gtk-capture-assert.sh --section 6` | ✅ exists | ✅ green |
| 22-04-01 | 04 | 4 | KDE-03 | T-22-13 | `restow/chrome-flags/` packaging, collision map tag, `restow/README.md` generated table match | integration | `./scripts/phase22-kde-and-gtk-capture-assert.sh --section 4` | ✅ exists | ✅ green |
| 22-04-02 | 04 | 4 | KDE-03 | T-22-14 | Live cp-through drill: clean-tree preflight, `install-files` write-through verification, `git checkout` recovery | live drill | `./scripts/phase22-kde-and-gtk-capture-assert.sh --section 5` | ✅ exists | ✅ green |
| 22-04-03 | 04 | 4 | KDE-01, KDE-02, KDE-03 | T-22-15 | Overall tree integrity, zero folded ancestors, clean GUARD sweep, strict verify gate | system check | `./scripts/phase22-kde-and-gtk-capture-assert.sh && ./arch/dots-hyprland.sh verify --strict && ./scripts/phase17-unblock-assert.sh` | ✅ exists | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `scripts/phase22-kde-and-gtk-capture-assert.sh` — gating assert script for Phase 22 (sections 1–6)
- [x] `guard-paths.tsv` — repository root data tracking the 7 guarded theme paths and Q7/Q8 findings

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Classification |
|----------|-------------|------------|-------------------|----------------|
| Dolphin GUI settings dialog write-through | KDE-01 | Wayland GUI interaction check | Open Dolphin -> Settings -> Configure Dolphin, toggle a preference, confirm file in `stow/kde/` updates | Non-blocking inspection / manual sampling (D-06) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-09-16
