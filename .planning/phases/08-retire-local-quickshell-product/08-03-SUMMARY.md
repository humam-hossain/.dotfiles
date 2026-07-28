---
phase: 08-retire-local-quickshell-product
plan: 03
subsystem: infra
tags: [quickshell, RET-02, installer-retirement, dots-hyprland]

requires:
  - phase: 08-retire-local-quickshell-product
    provides: 08-02 RET-01 tree delete (fb91789)
provides:
  - arch/quickshell.sh ABSENT (RET-02, no stub)
  - arch/dots-hyprland.sh sole Arch shell-product install entry
  - Pattern comment reworded off deleted installer filename
  - full post-retirement live + RET holds green
affects:
  - phase 9 playbook (docs only; product path already single)
  - historical phase07 D-04 (expected red — frozen)

tech-stack:
  added: []
  patterns:
    - "D-04 hard delete installer — no deprecation stub"
    - "D-09 separate commits: tree / installer / optional comment"
    - "D-11 zero active arch/quickshell.sh refs under arch/scripts/.config"

key-files:
  created: []
  modified:
    - arch/dots-hyprland.sh (Pattern comment only)
  deleted:
    - arch/quickshell.sh

key-decisions:
  - "Hard-deleted installer; no stub (D-04)"
  - "Reworded Pattern comment to arch/waybar.sh / arch/*.sh (preferred D-11)"
  - "Left phase07/phase04 scripts and .planning historical text alone (D-12)"

patterns-established:
  - "RET-02: git rm installer + assert ! -e + never execute before delete"
  - "Post-retirement grep gate: no active caller of deleted installer under product paths"

requirements-completed: [RET-02, RET-01]

coverage:
  - id: D1
    description: "arch/quickshell.sh hard-deleted with no stub"
    requirement: RET-02
    verification:
      - kind: other
        ref: "test ! -e arch/quickshell.sh; commit 81ac1e0"
        status: pass
    human_judgment: false
  - id: D2
    description: "arch/dots-hyprland.sh remains sole executable install entry"
    requirement: RET-02
    verification:
      - kind: other
        ref: "test -x arch/dots-hyprland.sh; bash -n"
        status: pass
    human_judgment: false
  - id: D3
    description: "No active arch/quickshell.sh refs under arch/scripts/.config after reword"
    requirement: RET-02
    verification:
      - kind: other
        ref: "git grep arch/quickshell.sh -- arch/ scripts/ .config/ (zero hits)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Live ii hold + RET-01 tree absence after installer gone"
    requirement: RET-01
    verification:
      - kind: other
        ref: "test ! -e .config/quickshell; live ii/shell.qml; hypr qs -c ii"
        status: pass
    human_judgment: false

duration: 6min
completed: 2026-07-28
status: complete
---

# Phase 8 Plan 03: Installer Retirement (RET-02) Summary

**Hard-deleted `arch/quickshell.sh` (no stub); wrapper is sole install entry; Pattern comment reworded; live ii + RET-01 holds green.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-07-28T09:15:00Z
- **Completed:** 2026-07-28T09:16:30Z
- **Tasks:** 3/3 complete
- **Files modified:** 2 (1 deleted, 1 comment)

## Accomplishments

- RET-02: `arch/quickshell.sh` gone — no deprecation stub
- Separate atomic commits for installer delete vs Pattern reword (D-09)
- Zero residual `arch/quickshell.sh` refs under `arch/`, `scripts/`, `.config/`
- Final post-retirement full assert set green (RET-01 + RET-02 + live hold)

## Task Commits

1. **Task 1: Hard-delete arch/quickshell.sh** — `81ac1e0` (chore RET-02)
2. **Task 2: Minimal stale-ref cleanup + Pattern reword** — `cb4f6a0` (chore comment)
3. **Task 3: Final post-retirement asserts** — (this SUMMARY commit)

**Plan metadata:** (docs SUMMARY following)

## Files Created/Modified

| Path | Change |
|------|--------|
| `arch/quickshell.sh` | **Deleted** (104 lines) |
| `arch/dots-hyprland.sh` | Pattern comment only: `arch/waybar.sh / arch/*.sh` |

## Decisions Made

- Preferred reword applied (not left as residual Pattern hit)
- Historical scripts (`phase07-live-smoke`, `phase04-*`) not modified
- No phase08 smoke harness; no package uninstall; no playbook (Phase 9)

## Commit SHAs (D-09 separation)

| Commit | Role |
|--------|------|
| `fb91789` | RET-01 tree delete (08-02) |
| `81ac1e0` | RET-02 installer hard-delete |
| `cb4f6a0` | Pattern comment reword |

## Final assert evidence

| Assert | Result |
|--------|--------|
| `! -e REPO/.config/quickshell` | PASS (RET-01) |
| `! -e arch/quickshell.sh` | PASS (RET-02) |
| `-x arch/dots-hyprland.sh` + `bash -n` | PASS |
| live `! -L` + `ii/shell.qml` + not under repo | PASS |
| venv present | PASS |
| repo hypr env + `qs -c ii` | PASS |
| waybar exec-once (soft) | PASS |
| no `arch/quickshell.sh` under arch/scripts/.config | PASS |
| no phase08 smoke | PASS |

## Non-gates

- `./scripts/phase07-live-smoke.sh` D-04 remains **expected red** — frozen (D-03/D-11/D-12)
- Phase 9 owns docs/playbook campaign (D-06)

## Deviations

None.

## Self-Check: PASSED

- [x] Installer absent, no stub
- [x] Tree still absent (RET-01 hold)
- [x] Wrapper sole entry
- [x] Separate commits per D-09
- [x] Live hold green
- [x] No active installer caller refs
- [x] Historical scripts untouched
