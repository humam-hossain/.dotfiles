---
phase: "29"
plan: "01"
subsystem: "theme-data-contracts"
tags: [contracts, gitignore, restow, stow, verification]
requires: []
provides:
  - "Scaffolded Phase 29 assertion harness with fail-closed structure"
  - "1:1 parity between guard-paths.tsv and .gitignore with v0.5 architecture documentation"
  - "relocated fuzzel and kitty packages in restow/ satisfying collision-map derivation"
  - "regenerated restow/README.md Section 3 recovery table"
  - "arch/kitty.sh stowing from ../restow preserving PAIR_COUNT == 18"
  - "hierarchical prefix matching and recursive directory checks in arch/dots-hyprland.sh"
affects:
  - guard-paths.tsv
  - .gitignore
  - restow/README.md
  - arch/kitty.sh
  - arch/dots-hyprland.sh
  - restow/fuzzel/.config/fuzzel/fuzzel.ini
  - restow/kitty/.config/kitty/kitty.conf
  - restow/kitty/.config/kitty/search.py
  - restow/kitty/.config/kitty/scroll_mark.py
  - scripts/phase28-terminal-fuzzel-assert.sh
  - scripts/phase29-theme-data-contracts-assert.sh
tech-stack:
  added: []
  patterns:
    - "Hierarchical prefix walk for directory-level guard matching"
    - "Recursive symlink check for guarded directories against repository root"
    - "Three-tree taxonomy derivation: DESTROYED symlink outcome maps to restow/"
key-files:
  created:
    - scripts/phase29-theme-data-contracts-assert.sh
  modified:
    - guard-paths.tsv
    - .gitignore
    - restow/README.md
    - arch/kitty.sh
    - arch/dots-hyprland.sh
    - restow/fuzzel/.config/fuzzel/fuzzel.ini
    - restow/kitty/.config/kitty/kitty.conf
    - restow/kitty/.config/kitty/search.py
    - restow/kitty/.config/kitty/scroll_mark.py
    - scripts/phase28-terminal-fuzzel-assert.sh
key-decisions:
  - "Relocated fuzzel and kitty from stow/ to restow/ to honor collision-map.tsv derivation (symlink DESTROYED -> restow) caused by upstream install_dir__sync."
  - "Updated arch/kitty.sh line 10 to stow from ../restow while preserving PAIR_COUNT == 18 invariant across arch/*.sh."
  - "Retained Q7: and Q8: literal tokens in guard-paths.tsv while documenting all 8 v0.5 theme outputs."
  - "Implemented hierarchical prefix matching in arch/dots-hyprland.sh classify_entry and recursive directory inspection in guard validation."
requirements-completed: [INTG-01, INTG-02]
duration: "4 min"
completed: "2026-09-18T09:51:00Z"
coverage:
  - deliverable: "Scaffold Phase 29 assertion harness"
    verification:
      kind: command
      ref: "bash scripts/phase29-theme-data-contracts-assert.sh --help"
      status: pass
    human_judgment: false
  - deliverable: "Data contracts & gitignore 1:1 parity and package relocation"
    verification:
      kind: command
      ref: "bash scripts/phase29-theme-data-contracts-assert.sh --section 1"
      status: pass
    human_judgment: false
  - deliverable: "Strict verification engine compliance & hierarchical prefix matching"
    verification:
      kind: command
      ref: "bash scripts/phase29-theme-data-contracts-assert.sh --section 3 && ./arch/dots-hyprland.sh verify --strict"
      status: pass
    human_judgment: false
---

# Phase 29 Plan 01: Theme Data Contracts, Package Taxonomy & Verifier Alignment Summary

Established Phase 29 tracer slice by scaffolding the assertion harness, reconciling data contracts and gitignore parity, relocating `fuzzel` and `kitty` packages from `stow/` to `restow/` to satisfy `collision-map.tsv` derivation, and enhancing `arch/dots-hyprland.sh` with hierarchical prefix guard matching and recursive directory checks.

## Key Changes

1. **Assertion Harness Scaffolding (`scripts/phase29-theme-data-contracts-assert.sh`):**
   - Implemented mode 0755 fail-closed runner supporting `--section <1-5>` and `-h|--help`.
   - Added two-phase working tree porcelain brackets filtering ephemeral noise.
   - Fully implemented and verified Section 1 (Data Contracts & Parity) and Section 3 (Strict Verification Engine).

2. **Data Contracts & Parity (`guard-paths.tsv`, `.gitignore`):**
   - Reconciled `guard-paths.tsv` to document all 8 v0.5 dynamic outputs while strictly preserving `Q7:` and `Q8:` backward compatibility markers.
   - Added `kde-material-you-colors/` to root `.gitignore` establishing 1:1 parity with the 8 guarded entries.

3. **Three-Tree Taxonomy Alignment (`stow/` $\rightarrow$ `restow/`):**
   - Migrated `fuzzel` and `kitty` from `stow/` to `restow/` via `git mv`.
   - Regenerated `restow/README.md` Section 3 table via `./scripts/gen-collision-map.sh --restow-table`, assigning `rsync-replace` recovery tags.
   - Updated `arch/kitty.sh` to stow from `../restow` while strictly preserving `PAIR_COUNT == 18` across `arch/*.sh`.
   - Aligned `scripts/phase28-terminal-fuzzel-assert.sh` to check `restow/`, verifying Section 1 passes with zero regressions.
   - Re-stowed live symlinks in `~/.config/fuzzel/` and `~/.config/kitty/` pointing directly into `restow/`.

4. **Verification Engine Hardening (`arch/dots-hyprland.sh`):**
   - Enforced hierarchical prefix matching in `classify_entry()`, correctly classifying files nested within guarded directories as guarded theme output.
   - Added recursive directory inspection to the guard validation gate, ensuring no symlinks inside guarded directories point into the repository.
   - Verified `./arch/dots-hyprland.sh verify --strict` exits 0 with `FAIL=0 FINDINGS=0`.

## Self-Check: PASSED

- All 3 plan tasks completed and verified
- All acceptance criteria satisfied
- `arch/dots-hyprland.sh verify --strict` clean (`FAIL=0 FINDINGS=0`)
