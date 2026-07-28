---
phase: 08-retire-local-quickshell-product
plan: 02
subsystem: infra
tags: [quickshell, RET-01, tree-delete, dual-path-retirement]

requires:
  - phase: 08-retire-local-quickshell-product
    provides: 08-01 live health green gate
provides:
  - in-repo .config/quickshell ABSENT (RET-01)
  - atomic tree-delete commit fb91789
  - live ~/.config/quickshell still real ii install
affects:
  - 08-03 (installer hard-delete after tree gone)
  - phase07-live-smoke D-04 (expected red — leave frozen)

tech-stack:
  added: []
  patterns:
    - "REPO-scoped git rm -rf only; never home recursive remove as retirement"
    - "D-08 discard WIP with -f; no salvage commit before delete"
    - "D-09 tree delete own commit; installer stays until 08-03"

key-files:
  created: []
  modified: []
  deleted:
    - .config/quickshell/ (entire tree, 933 tracked files)

key-decisions:
  - "Forced git rm -rf for 3 dirty WIP files (ToolbarTabBar, AiChat, Anime) — discarded per D-08"
  - "No annotated recovery tag (D-10)"
  - "arch/quickshell.sh intentionally left for 08-03 (D-09)"

patterns-established:
  - "RET-01: git rm -rf .config/quickshell under REPO_ROOT only + post-assert live ii/shell.qml"
  - "phase07 D-04 expected red after this commit — do not thrash historical smoke"

requirements-completed: [RET-01]

coverage:
  - id: D1
    description: "In-repo .config/quickshell fully removed from REPO (933 files)"
    requirement: RET-01
    verification:
      - kind: other
        ref: "test ! -e $REPO/.config/quickshell; commit fb91789"
        status: pass
    human_judgment: false
  - id: D2
    description: "Live ~/.config/quickshell still real with ii/shell.qml after repo delete"
    requirement: RET-01
    verification:
      - kind: other
        ref: "test ! -L; test -f $HOME/.config/quickshell/ii/shell.qml; readlink not under repo"
        status: pass
    human_judgment: false
  - id: D3
    description: "Tree delete is dedicated commit; installer still present pending 08-03"
    requirement: RET-01
    verification:
      - kind: other
        ref: "git log -1 RET-01; test -f arch/quickshell.sh"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-07-28
status: complete
---

# Phase 8 Plan 02: In-Repo Product Tree Delete (RET-01) Summary

**Deleted 933 tracked files under REPO `.config/quickshell`; live home ii install untouched. Dual product path ended in-repo.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-28T09:13:30Z
- **Completed:** 2026-07-28T09:14:30Z
- **Tasks:** 3/3 complete
- **Files deleted:** 933 tracked (+ 3 uncommitted WIP discarded)

## Accomplishments

- Pre-delete re-assert: live independent + repo tree present
- `git rm -rf .config/quickshell` (force for dirty WIP per D-08)
- Atomic commit `fb91789` — tree only; installer not included
- Post-delete live hold green; no recovery tag

## Task Commits

1. **Task 1: Pre-delete re-assert live independence** — no code commit (asserts only)
2. **Task 2: git rm -r tree + atomic RET-01 commit** — `fb91789` (chore)
3. **Task 3: Post-delete live hold + D-04 red note** — (this SUMMARY commit)

**Plan metadata:** (docs SUMMARY commit following)

## Files Created/Modified

- **Deleted:** entire `.config/quickshell/` tree under REPO_ROOT (933 files, 77826 deletions)
- **Discarded WIP (not committed):** `ToolbarTabBar.qml`, `AiChat.qml`, `Anime.qml`
- **Preserved:** `~/.config/quickshell/ii/shell.qml`, `arch/quickshell.sh` (until 08-03)

## Decisions Made

- Used `git rm -rf` because three files had local modifications; D-08 forbids salvage
- Did not create annotated tag (D-10)
- Did not touch `arch/quickshell.sh` in this commit (D-09)

## Evidence

| Check | Result |
|-------|--------|
| `test ! -e REPO/.config/quickshell` | PASS |
| live `! -L` + `ii/shell.qml` | PASS |
| live not under `*/.dotfiles/.config/quickshell*` | PASS |
| venv present | PASS |
| `arch/quickshell.sh` still exists | PASS (08-03) |
| no phase08 smoke | PASS |
| no recovery tag | PASS |
| waybar exec-once in repo hypr | SOFT PASS |

**Tree delete SHA:** `fb91789`  
**Message:** `chore(08): remove in-repo v0.1 .config/quickshell product tree (RET-01)`

## Non-gates

- `./scripts/phase07-live-smoke.sh` D-04 is now **expected red** — leave frozen (D-03/D-11/D-12)
- Installer hard-delete remains **08-03**
- No `scripts/phase08*` created

## Deviations

- Plan suggested `git rm -r`; used `git rm -rf` because dirty WIP blocked non-force remove. Equivalent outcome; WIP discarded intentionally (D-08).

## Self-Check: PASSED

- [x] In-repo `.config/quickshell` absent
- [x] Live `ii/shell.qml` present, not symlink
- [x] Dedicated RET-01 commit (not installer)
- [x] Installer still present for 08-03
- [x] No phase08 smoke; D-04 expected red documented
