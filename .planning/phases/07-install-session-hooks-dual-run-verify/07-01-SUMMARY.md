---
phase: 07-install-session-hooks-dual-run-verify
plan: 01
subsystem: infra
tags: [quickshell, symlink, pre-install, host-mutation, LIVE-01]

requires:
  - phase: 06-thin-setup-wrapper-safe-defaults
    provides: arch/dots-hyprland.sh wrapper ready for live install
provides:
  - qs/quickshell stopped before install-files
  - live ~/.config/quickshell not a symlink (path absent)
  - in-repo .config/quickshell product preserved (D-04)
  - operator approved pre-install ready for 07-02
affects:
  - 07-02 (live wrapper install requires this pre-state)
  - 07-03 (session hooks after LIVE-01 tree)

tech-stack:
  added: []
  patterns:
    - "Plain rm on QS symlink only — never recursive force-remove while path is a symlink"
    - "Pre-install gate: no qs process + ! -L live path + repo product still present"

key-files:
  created: []
  modified: []

key-decisions:
  - "Host-only mutations; no git product commits for Tasks 1–2"
  - "Path left absent (preferred first-run) so setup creates a real directory"
  - "Did not run arch/quickshell.sh (would re-symlink)"

patterns-established:
  - "D-01 unlink: plain rm symlink; assert ! -L; preserve REPO_ROOT/.config/quickshell"
  - "D-03 stop qs before path mutation; labeled [CONFIG]/[SKIP]/[FAIL] echos"

requirements-completed: [LIVE-01]

coverage:
  - id: D1
    description: "No qs or quickshell process running before install"
    requirement: LIVE-01
    verification:
      - kind: other
        ref: "pgrep -x qs; pgrep -x quickshell (both must fail)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Live ~/.config/quickshell is not a symlink (path absent preferred)"
    requirement: LIVE-01
    verification:
      - kind: other
        ref: "test ! -L $HOME/.config/quickshell; test ! -e $HOME/.config/quickshell"
        status: pass
    human_judgment: false
  - id: D3
    description: "In-repo .config/quickshell product tree still present"
    requirement: LIVE-01
    verification:
      - kind: other
        ref: "test -d $(git rev-parse --show-toplevel)/.config/quickshell"
        status: pass
    human_judgment: false
  - id: D4
    description: "Operator confirmed pre-install ready for wrapper install"
    requirement: LIVE-01
    verification: []
    human_judgment: true
    rationale: "Blocking checkpoint before machine-mutating 07-02 install"

duration: 5min
completed: 2026-07-27
status: complete
---

# Phase 7 Plan 01: Pre-Install Path Safety Summary

**qs stopped; live `~/.config/quickshell` symlink removed (path absent); in-repo product intact; operator approved for 07-02 install.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-27T07:44:34Z
- **Completed:** 2026-07-27T07:48:00Z
- **Tasks:** 3/3
- **Files modified:** 0 (host-only mutations; SUMMARY only)

## Accomplishments

- Confirmed no qs/quickshell process (`[SKIP] no qs/quickshell process`)
- Recorded pre-state symlink: `~/.config/quickshell -> /home/pera/github_repo/.dotfiles/.config/quickshell`
- Removed symlink with plain `rm` only (`[CONFIG] removing QS symlink (repo target preserved)`)
- Post-state: path **absent** (preferred first-run for setup to create real dir)
- Verified in-repo `.config/quickshell` still present; user WIP modules left untouched
- Did **not** run `arch/quickshell.sh`, `./setup`, or `arch/dots-hyprland.sh`
- Operator typed **approved** at blocking human-verify checkpoint

## Task Results

| Task | Result | Notes |
|------|--------|-------|
| 1. Stop qs (D-03) | PASS | Already stopped; hard-fail gate clean |
| 2. Unlink symlink (D-01, D-04) | PASS | Path absent; repo product OK |
| 3. Operator pre-install approve | PASS | Resume signal: `approved` |

## Verification Evidence

```text
ls -ld ~/.config/quickshell
# ls: cannot access '...': No such file or directory

pgrep -a qs || echo "no qs"
# no qs

test -d "$(git rev-parse --show-toplevel)/.config/quickshell" && echo "repo product OK"
# repo product OK

test ! -L "$HOME/.config/quickshell"  # PASS
```

## Deviations

- None. Host-only plan produced no production-code commits (expected).

## Self-Check

- [x] All tasks executed
- [x] LIVE-01 preconditions hold
- [x] Operator approved
- [x] SUMMARY written after approval
- [ ] STATE/ROADMAP updated by close-out step

## Next

Ready for **07-02**: dry-run then live `./arch/dots-hyprland.sh install` with safe defaults and backup gate.
