---
phase: 08-retire-local-quickshell-product
plan: 01
subsystem: infra
tags: [quickshell, live-health, RET-01, dots-hyprland, pre-delete-gate]

requires:
  - phase: 07-install-session-hooks-dual-run-verify
    provides: live ~/.config/quickshell real ii install + hypr qs -c ii hooks
provides:
  - live install health green (LIVE-01/02 style hard asserts)
  - reinstall skipped (health already green)
  - 08-02 authorized for REPO-only git rm of .config/quickshell
affects:
  - 08-02 (tree delete requires this gate)
  - 08-03 (final live hold reuses same asserts)

tech-stack:
  added: []
  patterns:
    - "Inline LIVE-01/02 hard asserts only — no phase08 smoke harness (D-03)"
    - "phase07-live-smoke.sh is not the Phase 8 gate; D-04 expected red after RET-01"

key-files:
  created: []
  modified: []

key-decisions:
  - "All hard live-health asserts passed — reinstall branch SKIPPED"
  - "Did not run phase07-live-smoke as success gate (D-03)"
  - "In-repo .config/quickshell left intact for 08-02 (D-14 step 1 only)"

patterns-established:
  - "D-01/D-14: prove live real dir + not under repo before any product git rm"
  - "D-02: reinstall only via arch/dots-hyprland.sh when health fails (not needed here)"

requirements-completed: [RET-01]

coverage:
  - id: D1
    description: "Live ~/.config/quickshell is real dir (not symlink) with ii/shell.qml, not under repo product"
    requirement: RET-01
    verification:
      - kind: other
        ref: "test ! -L $HOME/.config/quickshell; test -f .../ii/shell.qml; readlink -f not under */.dotfiles/.config/quickshell*"
        status: pass
    human_judgment: false
  - id: D2
    description: "ii Python venv present at ~/.local/state/quickshell/.venv"
    requirement: RET-01
    verification:
      - kind: other
        ref: "test -d $HOME/.local/state/quickshell/.venv"
        status: pass
    human_judgment: false
  - id: D3
    description: "Repo hypr SoT still has ILLOGICAL_IMPULSE_VIRTUAL_ENV + exec-once = qs -c ii"
    requirement: RET-01
    verification:
      - kind: other
        ref: "grep LIVE-02 hooks in .config/hypr/hyprland.conf"
        status: pass
    human_judgment: false
  - id: D4
    description: "Reinstall skipped — live health green without wrapper reinstall"
    requirement: RET-01
    verification:
      - kind: other
        ref: "[SKIP] live health green — no reinstall"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-07-28
status: complete
---

# Phase 8 Plan 01: Live Install Health Gate Summary

**Live dots-hyprland ii install is healthy and independent of the in-repo product tree — reinstall skipped; 08-02 authorized for REPO-scoped tree delete only.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-07-28T09:10:00Z
- **Completed:** 2026-07-28T09:13:00Z
- **Tasks:** 3/3 complete
- **Files modified:** 0 (verification-only plan)

## Accomplishments

- All hard LIVE-01/02-style asserts passed on host
- Reinstall via `arch/dots-hyprland.sh` **skipped** (health green)
- Documented non-gates: no phase08 smoke; phase07 D-04 will be expected red after 08-02
- In-repo `.config/quickshell` still present (delete deferred to 08-02)

## Task Commits

Each task was verification-only (no production code changes):

1. **Task 1: Inline live install health asserts** — no code commit (host asserts only)
2. **Task 2: Reinstall if health failed** — `[SKIP] live health green — no reinstall`
3. **Task 3: Final health green + non-gates** — no code commit

**Plan metadata:** (this SUMMARY commit)

## Files Created/Modified

- `.planning/phases/08-retire-local-quickshell-product/08-01-SUMMARY.md` — this file

## Decisions Made

- Health green → skip reinstall (D-02 branch not taken)
- Did not invoke `./scripts/phase07-live-smoke.sh` as Phase 8 gate (D-03)
- Did not delete in-repo product or arch installer in this plan

## Live health evidence (Task 1 hard asserts)

| Assert | Result |
|--------|--------|
| `! -L ~/.config/quickshell` | PASS |
| `-d ~/.config/quickshell` | PASS |
| `-f ~/.config/quickshell/ii/shell.qml` | PASS |
| `readlink -f` not under `*/.dotfiles/.config/quickshell*` | PASS (`/home/pera/.config/quickshell`) |
| `-d ~/.local/state/quickshell/.venv` (+ pyvenv.cfg) | PASS |
| live `~/.config/hypr/hyprland.conf` present, no `.old` | PASS |
| repo `env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,` | PASS |
| repo `exec-once = qs -c ii` | PASS |

### Soft (non-blocking)

- `qs -c ii` running (pid 1193)
- `waybar` running

## Task 2

```
[SKIP] live health green — no reinstall
```

No dry-run, no backup gate, no package changes.

## Non-gates documented for 08-02+

- `./scripts/phase07-live-smoke.sh` is **not** the Phase 8 success gate
- After 08-02 deletes in-repo `.config/quickshell`, phase07 D-04 is **expected red** — leave frozen (D-03/D-11/D-12)
- No `scripts/phase08*` smoke harness created (Wave 0: none)
- 08-02 may proceed with REPO-scoped `git rm -r .config/quickshell` only
- Live home tree must never be the retirement target (D-14)

## Deviations

None.

## Self-Check: PASSED

- [x] All Task 1 hard asserts pass
- [x] In-repo `.config/quickshell` still present
- [x] `arch/dots-hyprland.sh` executable
- [x] No `scripts/phase08*` file
- [x] SUMMARY states phase07 D-04 expected red after RET-01
- [x] No home-tree delete / re-symlink / retired installer execution
