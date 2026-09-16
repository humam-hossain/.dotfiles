---
phase: 22-kde-and-gtk-capture
plan: 03
subsystem: guard
tags: [guard, kdeglobals, theme-exclusion, archive, verify]
requires:
  - "22-01"
  - "22-02"
provides:
  - "guard-paths.tsv contract file"
  - "docs/archive/kdeglobals retirement"
  - "arch/dots-hyprland.sh GUARD enforcement and sweep classification"
  - "scripts/phase22-kde-and-gtk-capture-assert.sh (Section 6)"
affects:
  - "guard-paths.tsv"
  - "docs/archive/kdeglobals"
  - "docs/archive/README.md"
  - "docs/config-redistribution.md"
  - "arch/dots-hyprland.sh"
  - "~/.config/kdeglobals"
tech-stack:
  added: []
  patterns: [guard-contract, archive-retirement, verify-guard-gate]
key-files:
  created:
    - guard-paths.tsv
    - docs/archive/kdeglobals
  modified:
    - docs/archive/README.md
    - docs/config-redistribution.md
    - arch/dots-hyprland.sh
    - scripts/phase22-kde-and-gtk-capture-assert.sh
key-decisions:
  - "D-18: Checked in guard-paths.tsv tracking 7 generated theme outputs with Q7/Q8 empirical resolutions"
  - "D-19: Tracked kdeglobals, Kvantum, gtk.css (3 & 4), fuzzel_theme.ini, colors.lua, and colors.conf in GUARD"
  - "D-20: Retired restow/kdeglobals to docs/archive/kdeglobals and converted live file to unmanaged regular file"
  - "D-21: Documented Q7 finding: kde-material-you-colors actively churns kdeglobals on wallpaper change"
  - "D-22: Documented Q8 finding: ~/.config/gtk-4.0/gtk.css is a symlink to root-owned theme file"
  - "D-23: Integrated GUARD path verification into arch/dots-hyprland.sh run_verify()"
  - "D-24: Updated classify_sweep_entry to identify guarded theme outputs instead of unclaimed upstream stubs"
requirements-completed: [KDE-02]
coverage:
  - id: D8
    description: "KDE-02 Check in guard-paths.tsv data contract with 7 paths and Q7/Q8 resolutions"
    requirement: "KDE-02"
    verification:
      - kind: unit
        ref: "test -f guard-paths.tsv && grep -q 'kde-material-you-colors' guard-paths.tsv"
        status: pass
    human_judgment: false
  - id: D9
    description: "KDE-02 Retire kdeglobals to docs/archive/ and convert live kdeglobals to regular file"
    requirement: "KDE-02"
    verification:
      - kind: unit
        ref: "test -f docs/archive/kdeglobals && test ! -e restow/kdeglobals && test ! -L ~/.config/kdeglobals && test -f ~/.config/kdeglobals"
        status: pass
    human_judgment: false
  - id: D10
    description: "KDE-02 Integrate GUARD check into run_verify() and classify_sweep_entry()"
    requirement: "KDE-02"
    verification:
      - kind: unit
        ref: "./arch/dots-hyprland.sh verify"
        status: pass
    human_judgment: false
  - id: D11
    description: "KDE-02 Implement Section 6 in phase 22 assert harness"
    requirement: "KDE-02"
    verification:
      - kind: unit
        ref: "./scripts/phase22-kde-and-gtk-capture-assert.sh --section 6"
        status: pass
    human_judgment: false
duration: 3 min
completed: 2026-09-15T09:08:00Z
---

# Phase 22 Plan 03: GUARD Contract & kdeglobals Retirement Summary

Data contract `guard-paths.tsv` established at repo root documenting empirical Q7 and Q8 resolutions, `kdeglobals` retired to `docs/archive/kdeglobals` and unlinked from live tracking to eliminate wallpaper churn, and `arch/dots-hyprland.sh` augmented with fail-closed GUARD verification and sweep classification.

## Accomplishments
- **GUARD Contract Deployment (D-18, D-19):** Authored `guard-paths.tsv` tracking 7 generated theme outputs (`kdeglobals`, `Kvantum`, `gtk.css` (3.0 & 4.0), `fuzzel_theme.ini`, `colors.lua`, `colors.conf`) with empirical commentary for Q7 (`kde-material-you-colors` churn) and Q8 (root-owned theme symlink).
- **kdeglobals Retirement (D-20, D-21):** Moved `restow/kdeglobals/.config/kdeglobals` to `docs/archive/kdeglobals`, removed `restow/kdeglobals`, converted live `~/.config/kdeglobals` to a standalone regular file, and updated `docs/archive/README.md` and row 36 of `docs/config-redistribution.md`.
- **Verification Engine GUARD Integration (D-23, D-24):** Added a fail-closed check in `arch/dots-hyprland.sh run_verify()` ensuring no guarded paths are tracked in `stow/`, `restow/`, or `capture/` and no live path symlinks into the repo; updated `classify_sweep_entry` to label guarded files as `guarded theme output`.
- **Harness Gate Implementation:** Added Section 6 to `scripts/phase22-kde-and-gtk-capture-assert.sh` verifying data integrity, comment documentation, archive placement, live unlinking, scratch guard violation rejection, and clean verify execution.

## Self-Check: PASSED
- `guard-paths.tsv` and `docs/archive/kdeglobals` exist in repository.
- `restow/kdeglobals` directory is absent.
- `~/.config/kdeglobals` is a regular file on host.
- `./scripts/phase22-kde-and-gtk-capture-assert.sh --section 6` passes with `FAIL=0 FINDINGS=0`.
- `./arch/dots-hyprland.sh verify` passes with `FAIL=0 FINDINGS=0`.
- Working tree clean.

## Deviations from Plan
None - plan executed exactly as written.
