---
phase: 22-kde-and-gtk-capture
plan: 04
subsystem: restow-and-gate
tags: [restow, chrome-flags, cp-through, verification-gate, phase22]
requires:
  - "22-01"
  - "22-02"
  - "22-03"
provides:
  - "restow/chrome-flags package"
  - "restow/README.md Section 3 table update"
  - "scripts/phase22-kde-and-gtk-capture-assert.sh (Sections 4 & 5)"
  - "Phase 22 phase gate completion"
affects:
  - "restow/chrome-flags/.config/chrome-flags.conf"
  - "restow/README.md"
  - "scripts/phase22-kde-and-gtk-capture-assert.sh"
  - "~/.config/chrome-flags.conf"
tech-stack:
  added: []
  patterns: [restow-packaging, cp-through-drill, recovery-contract, phase-gate]
key-files:
  created:
    - restow/chrome-flags/.config/chrome-flags.conf
  modified:
    - restow/README.md
    - scripts/phase22-kde-and-gtk-capture-assert.sh
key-decisions:
  - "D-14: Adopted chrome-flags.conf into restow/chrome-flags/ using SAFE-01 with matching live inode"
  - "D-15: Regenerated restow/README.md Section 3 table via scripts/gen-collision-map.sh --restow-table"
  - "D-16: Implemented Section 5 live cp-through drill proving write-through modification and git checkout recovery"
  - "D-17: Verified collision-map.tsv maps chrome-flags.conf to restow tree with OVERWRITTEN outcome"
  - "D-25: Preserved PAIR_COUNT == 18 in arch/ scripts (zero script proliferation; no arch/kde.sh or arch/gtk.sh)"
  - "D-26: Passed full 6-section phase22 assert suite and arch/dots-hyprland.sh verify --strict"
requirements-completed: [KDE-03]
coverage:
  - id: D12
    description: "KDE-03 Package chrome-flags.conf into restow/ and link live"
    requirement: "KDE-03"
    verification:
      - kind: unit
        ref: "test -f restow/chrome-flags/.config/chrome-flags.conf && test -L ~/.config/chrome-flags.conf"
        status: pass
    human_judgment: false
  - id: D13
    description: "KDE-03 Regenerate restow/README.md package recovery table"
    requirement: "KDE-03"
    verification:
      - kind: unit
        ref: "grep -q 'chrome-flags' restow/README.md && ! grep -q 'kdeglobals' restow/README.md"
        status: pass
    human_judgment: false
  - id: D14
    description: "KDE-03 Implement Section 4 and Section 5 in phase 22 assert harness"
    requirement: "KDE-03"
    verification:
      - kind: unit
        ref: "./scripts/phase22-kde-and-gtk-capture-assert.sh --section 4 && ./scripts/phase22-kde-and-gtk-capture-assert.sh --section 5"
        status: pass
    human_judgment: false
  - id: D15
    description: "KDE-03 Execute Phase 22 full test suite and strict verification gate"
    requirement: "KDE-03"
    verification:
      - kind: unit
        ref: "./scripts/phase22-kde-and-gtk-capture-assert.sh && ./arch/dots-hyprland.sh verify --strict"
        status: pass
    human_judgment: false
duration: 6 min
completed: 2026-09-15T09:14:00Z
---

# Phase 22 Plan 04: Desktop Flags Capture & Verification Gate Summary

Desktop flags (`chrome-flags.conf`) captured into `restow/chrome-flags/` under the SAFE-01 protocol, `restow/README.md` package recovery table mechanically regenerated, live cp-through drill and recovery verified end-to-end in Section 5 of the assert harness, and strict phase gate passed with zero findings.

## Accomplishments
- **restow/chrome-flags Packaging (D-14, D-17):** Adopted `chrome-flags.conf` into `restow/chrome-flags/.config/chrome-flags.conf` via the SAFE-01 protocol, verifying identical inode identity (`16417673`) between repository mirror and live symlink `~/.config/chrome-flags.conf`.
- **Package Recovery Table Regeneration (D-15):** Regenerated Section 3 of `restow/README.md` via `scripts/gen-collision-map.sh --restow-table`, documenting `chrome-flags` tagged `cp-through` with exact recovery command: `git checkout -- restow/chrome-flags/.config/chrome-flags.conf && cd restow && stow --verbose=5 --no-folding -t ~ chrome-flags`, while confirming `kdeglobals` is completely absent from the table.
- **Section 4 & Section 5 Assert Implementation (D-16, D-26):**
  - Section 4: Verified `restow/chrome-flags/` file existence, symlink and inode identity, collision map entry (`OVERWRITTEN`), and exact README table reproduction.
  - Section 5: Rehearsed live `install-files` drill: verified clean-tree preflight, invoked `./arch/dots-hyprland.sh install-files`, proved write-through modifications occurred on `restow/dolphinrc` and `restow/chrome-flags`, and restored clean state with `git checkout -- restow/chrome-flags restow/dolphinrc` and symlink re-stow.
- **Phase Gate & Strict Verification (D-25, D-26):**
  - Ran all 6 sections of `scripts/phase22-kde-and-gtk-capture-assert.sh`, passing with `FAIL=0 FINDINGS=0`.
  - Ran `./arch/dots-hyprland.sh verify --strict`, passing across all stow, restow, capture, and guarded paths with `FAIL=0 FINDINGS=0`.
  - Ran `./scripts/phase17-unblock-assert.sh` verifying `PAIR_COUNT == 18` is preserved, proving zero script proliferation (no `arch/kde.sh` or `arch/gtk.sh` created).
  - Ran `./scripts/phase21-ii-bar-config-capture-assert.sh`, verifying Quickshell bar capture stability with `FAIL=0 FINDINGS=0`.

## Self-Check: PASSED
- `restow/chrome-flags/.config/chrome-flags.conf` exists and matches live `~/.config/chrome-flags.conf` inode.
- `restow/README.md` lists `chrome-flags` tagged `cp-through`.
- `./scripts/phase22-kde-and-gtk-capture-assert.sh` passes all 6 sections (`FAIL=0 FINDINGS=0`).
- `./arch/dots-hyprland.sh verify --strict` passes (`FAIL=0 FINDINGS=0`).
- Requirement `KDE-03` marked complete.

## Deviations from Plan
- In Section 5 post-drill recovery, added re-stowing of symlinks severed by upstream `install_dir__sync` (`hypr`, `fish`, `kitty`) so that the live system remains fully verified for subsequent strict assertion runs.
