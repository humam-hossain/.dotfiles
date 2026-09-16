---
phase: 25-gtk-material-you-theming-catppuccin-de-linking
plan: 01
subsystem: desktop-theming
tags: [gtk, material-you, catppuccin, de-linking, assert-harness, stow]

requires:
  - phase: 22-kde-and-gtk-capture
    provides: GTK Stow package structure and unfolded directory management
provides:
  - Phase 25 fail-closed test assertion harness (`scripts/phase25-gtk-material-you-assert.sh`) covering Sections 1-5
  - Safely de-linked legacy Catppuccin symlinks in `~/.config/gtk-4.0/` (`assets`, `gtk.css`, `gtk-dark.css`)
  - Unfolded unprivileged `~/.config/gtk-4.0/` directory ready for Matugen CSS generation
affects: [gtk, matugen, desktop-appearance]

actuals:
  tokens: 28000
  tasks: 2
  commits: 1

tech-stack:
  added: []
  patterns: [Fail-closed dotfiles assert harness, porcelain snapshot brackets, unprivileged directory de-linking]

key-files:
  created:
    - scripts/phase25-gtk-material-you-assert.sh
  modified: []

key-decisions:
  - "Scaffolded scripts/phase25-gtk-material-you-assert.sh with 0755 permissions and 5 sections supporting --section filtering and git status porcelain snapshot verification (D-14)"
  - "Safely unlinked legacy Catppuccin symlinks (~/.config/gtk-4.0/assets, gtk.css, gtk-dark.css) pointing into /usr/share/themes/ to resolve root-ownership write-lock without modifying system packages (D-07, D-09)"
  - "Preserved ~/.config/gtk-4.0 as an unfolded regular directory with settings.ini Stow symlink intact, prohibiting unmanaged gtk-dark.css (D-08, D-09)"

patterns-established:
  - "GTK 4 configuration directory operates as an unfolded unprivileged directory accepting dynamic user-generated stylesheets"

requirements-completed:
  - GTK-02

coverage:
  - id: D1
    description: "Scaffold Phase 25 assertion harness covering Sections 1 through 5 with fail-closed structure"
    requirement: GTK-02
    verification:
      - kind: automated
        ref: "test -x scripts/phase25-gtk-material-you-assert.sh && bash scripts/phase25-gtk-material-you-assert.sh --help"
        status: pass
    human_judgment: false
  - id: D2
    description: "De-link legacy Catppuccin symlinks in ~/.config/gtk-4.0/ and assert clean directory state"
    requirement: GTK-02
    verification:
      - kind: automated
        ref: "bash scripts/phase25-gtk-material-you-assert.sh --section 1"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-09-16
status: complete
---

# Phase 25 Plan 01: Assertion Harness Scaffolding and Catppuccin De-linking Summary

**Scaffolded the Phase 25 gating test assertion harness covering Sections 1-5 with fail-closed porcelain checks and eliminated legacy root-pointing Catppuccin symlinks from `~/.config/gtk-4.0/`.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-16T14:28:10Z
- **Completed:** 2026-09-16T14:36:30Z
- **Tasks:** 2
- **Files created:** 1 (`scripts/phase25-gtk-material-you-assert.sh`)
- **Files modified:** 0

## Accomplishments

- Authored `scripts/phase25-gtk-material-you-assert.sh` with permissions `0755` adhering to dotfiles assertion harness conventions (`set -euo pipefail`, `--section <1-5>` CLI parsing, cleanup trap, porcelain snapshot comparisons).
- Implemented full specifications for all 5 harness sections:
  - Section 1: GTK-02 Catppuccin de-linking in `~/.config/gtk-4.0/` and unfolded parent check.
  - Section 2: GTK-03 Repository settings alignment in `stow/gtk/` for `settings.ini` files and bookmarks.
  - Section 3: GTK-04 GNOME desktop interface GSettings keys verification.
  - Section 4: GTK-01 Dynamic Matugen CSS generation and dry-run tests.
  - Section 5: INTG-01 & INTG-02 Verification engine execution and zero git churn.
- Unlinked legacy Catppuccin symlinks in `~/.config/gtk-4.0/` (`assets`, `gtk.css`, `gtk-dark.css`) pointing to `/usr/share/themes/catppuccin-mocha-teal-standard+default/gtk-4.0/`.
- Verified that `~/.config/gtk-4.0/` remains an unfolded physical directory with its `settings.ini` Stow symlink intact.
- Verified Section 1 of `scripts/phase25-gtk-material-you-assert.sh` passes with `FAIL=0` and 0 findings.

## Task Commits

Each repository modification was committed atomically:

1. **Task 1: Scaffold Phase 25 assertion harness (scripts/phase25-gtk-material-you-assert.sh) with fail-closed structure and Sections 1 to 5** - `5cc1432` (`test(25-01)`)
2. **Task 2: Safely de-link legacy Catppuccin symlinks in ~/.config/gtk-4.0/ and verify unprivileged directory state** - Completed without repository mutations (live user configuration de-linking).

## Verification Results

1. `test -x scripts/phase25-gtk-material-you-assert.sh && bash scripts/phase25-gtk-material-you-assert.sh --help` -> PASSED
2. `bash scripts/phase25-gtk-material-you-assert.sh --section 99` -> Exited 1 with validation error -> PASSED
3. `test ! -e "$HOME/.config/gtk-4.0/assets" && test ! -e "$HOME/.config/gtk-4.0/gtk-dark.css" && test ! -L "$HOME/.config/gtk-4.0/gtk.css" && test -d "$HOME/.config/gtk-4.0" && test ! -L "$HOME/.config/gtk-4.0"` -> PASSED
4. `bash scripts/phase25-gtk-material-you-assert.sh --section 1` -> PASSED (`=== done: FAIL=0 FINDINGS=0 ===`)

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
