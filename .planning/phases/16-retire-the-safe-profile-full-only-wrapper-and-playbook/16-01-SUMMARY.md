---
phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook
plan: 01
subsystem: infra
tags: [bash, wrapper, dots-hyprland, install, uninstall, assert-script, pacman]

# Dependency graph
requires:
  - phase: 12-full-install-opt-in-profile
    provides: the `--full` opt-in profile, `SAFE_DEFAULTS` injection and `scripts/phase12-full-smoke.sh`, all of which this plan retires or invalidates
  - phase: 14-live-full-adopt-verify
    provides: the completed live full adopt that already demoted the personal stack to `--asdeps`, which is what makes D-07's package-marking removal a *costly* rather than *one-way* change
  - phase: 15-hypr-lua-session
    provides: the Lua session that no longer loads `~/.config/hypr/hyprland.conf`, which is the verified premise for deleting the session-hook machinery (D-08)
provides:
  - "`arch/dots-hyprland.sh` install path is full-only: a bare `install` / `install-files` builds `./setup <sub> --skip-backup` with no profile decision anywhere on the path"
  - "`--full` survives as an accepted no-op alias that prints a `[CONFIG]` ignored-note and is never forwarded to upstream `getopt`"
  - "`touches_files()` predicate scoping the upstream skip-backup flag to the two subcommands where upstream actually reads it"
  - "`scripts/phase16-retire-assert.sh` — the non-mutating contract of record for the retirement (17 hard asserts, FAIL=0)"
  - "a wrapper with no package re-marking machinery, no session-hook machinery, and no `protect` subcommand"
affects: [16-02 usage rewrite and smoke rewrite, 16-04 playbook rewrite, 16-06 d19 re-pin, 16-10 phase gate]

# Actuals (#2632)
actuals:
  tokens: 12500
  tasks: 3
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "assert-script in the `scripts/phase12-full-smoke.sh` shape: FAIL/pass()/fail() triple, mktemp+trap, `bash -n` gate first, `=== done: FAIL=N ===` footer"
    - "two-stage `grep 'would exec' | grep -q -- '<flag>'` for meta-flag-not-forwarded asserts, so the wrapper's own note line cannot fail its own check"
    - "word-boundary ERE `(^|[[:space:]])--core([[:space:]]|$)` for residual-flag omission checks"

key-files:
  created:
    - scripts/phase16-retire-assert.sh
  modified:
    - arch/dots-hyprland.sh

key-decisions:
  - "Operator confirmed `proceed` at the Task 1 blocking-human reversibility checkpoint: both the install backup (D-06) and the install confirmation prompt (D-09) are removed permanently"
  - "The upstream skip-backup flag is appended only for `install` / `install-files` via a new `touches_files()` predicate, not unconditionally (A1)"
  - "`--full` is accepted on all four install-family subcommands; `install-deps --full` flips from exit 1 to exit 0 (A2)"
  - "`run_upstream_uninstall_dangerous` and its `--upstream-dangerous` flag are left byte-unchanged, including the `UPSTREAM-UNINSTALL` type-token guard (A3)"
  - "`run_safe_uninstall`'s `rc` accumulator was removed with its only setter and the function now returns 0 explicitly — leaving `return $rc` after deleting `local rc=0` would abort under `set -u`"

patterns-established:
  - "Comment hygiene under grep-based contracts: comments cite decision IDs (D-04, D-06, D-09, D-11), never the identifiers they replaced, because an absence-grep cannot tell a tombstone comment from live code"
  - "Signature shrink discipline: positional reads and their call sites change in one edit, verified by an actual `--dry-run` exit-code check, because `set -u` turns a stale `local x=\"$5\"` into an abort rather than a default"

requirements-completed: [FULL-01, FULL-02, FULL-04, D-02, D-04, D-05, D-06, D-07, D-08, D-09, D-10, D-11, D-12, D-13, D-35]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "A bare `install` / `install-files` invocation carries none of the three retired residual flags — full is what an operator gets without asking for it"
    requirement: "FULL-01"
    verification:
      - kind: integration
        ref: "./scripts/phase16-retire-assert.sh#FULL-01 bare install --dry-run omits --skip-hyprland / --skip-sysupdate / standalone --core (both install and install-files)"
        status: pass
    human_judgment: false
  - id: D2
    description: "`--full` is accepted on every install-family subcommand, prints a `[CONFIG]` note saying it is ignored, and never reaches the would-exec line"
    requirement: "D-05"
    verification:
      - kind: integration
        ref: "./scripts/phase16-retire-assert.sh#D-05 install --full exits 0, prints the ignored-note, would-exec strips meta --full; A2 install-deps --full exits 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "`install` and `install-files` forward the upstream skip-backup flag; `install-deps` and `install-setups` do not"
    requirement: "D-06"
    verification:
      - kind: integration
        ref: "./scripts/phase16-retire-assert.sh#D-06 install/install-files would-exec forwards the flag, install-setups would-exec omits it"
        status: pass
    human_judgment: false
  - id: D4
    description: "No wrapper-owned prompt stands between an `install` invocation and upstream `./setup` — the exact-token gate line is gone from every install path"
    requirement: "D-09"
    verification:
      - kind: integration
        ref: "./scripts/phase16-retire-assert.sh#D-09 install path has no wrapper-owned confirmation prompt"
        status: pass
    human_judgment: false
  - id: D5
    description: "A new executable contract exists at `scripts/phase16-retire-assert.sh` and exits 0 against the rewritten wrapper"
    requirement: "D-35"
    verification:
      - kind: integration
        ref: "test -x scripts/phase16-retire-assert.sh && ./scripts/phase16-retire-assert.sh  =>  === done: FAIL=0 ==="
        status: pass
    human_judgment: false
  - id: D6
    description: "The retired `protect` subcommand is refused by the allowlist rather than by a missing function"
    requirement: "D-07"
    verification:
      - kind: integration
        ref: "./arch/dots-hyprland.sh protect --dry-run  =>  exit 1, 'non-allowlisted subcommand: protect'"
        status: pass
    human_judgment: false
  - id: D7
    description: "`bash -n` is clean and the surviving uninstall machinery still resolves every helper it calls, so nothing aborts under `set -euo pipefail`"
    requirement: "D-11"
    verification:
      - kind: integration
        ref: "bash -n arch/dots-hyprland.sh; printf '' | ./arch/dots-hyprland.sh uninstall --dry-run  =>  exit 0; grep -c print_lines >= 4"
        status: pass
    human_judgment: false
  - id: D8
    description: "The real (mutating) uninstall path still gates, removes ii meta packages without a cascade, removes ii configs/state, and honours its four surviving flags"
    requirement: "D-10"
    verification: []
    human_judgment: true
    rationale: "Only the `--dry-run` path is executable under this plan's non-mutating prohibition. The real path's `read -r -p \"Type 'yes' …\"` gate, the `sudo pacman -R` removal and the `safe_rm_path` sweep were reviewed by reading, not by running. Proving them requires a live uninstall on the operator's machine, which this phase explicitly forbids."

# Metrics
duration: 38 min
completed: 2026-09-07
status: complete
---

# Phase 16 Plan 01: Full-only wrapper and its retirement contract Summary

**`arch/dots-hyprland.sh` now has one install code path — a bare `install` builds `./setup install --skip-backup` with no profile decision, no snapshot and no wrapper prompt — proven by a new 17-assert non-mutating contract at `scripts/phase16-retire-assert.sh`.**

## Performance

- **Duration:** 38 min
- **Started:** 2026-09-07T12:20:00Z (approx — executor resumed mid-plan after the Task 1 checkpoint)
- **Completed:** 2026-09-07T12:58:15Z
- **Tasks:** 3 (1 checkpoint decision, 1 tracer, 1 auto)
- **Files modified:** 2 (1 modified, 1 created)

## Accomplishments

- **The seam is gone.** `run_install_family` no longer contains a profile decision. It parses argv, preflights, builds `cmd=(./setup "$subcmd")`, conditionally appends the upstream skip-backup flag, appends user flags, and execs the array inside a `cd` subshell. The `[CONFIG] dry-run: would exec from …` contract line and the array-only exec (`"${cmd[@]}"`) survive byte-intact.
- **`--full` is now a documented no-op that is still parsed.** Deleting the arm would have handed a long option to upstream's `getopt`, whose `*)` handler exits 1 — so the arm stays, prints `[CONFIG] --full is accepted but ignored: full is now the only install behavior.`, and never appends to `cmd`.
- **Backup skip is scoped, not blanket.** A new one-line `touches_files()` predicate appends `--skip-backup` for `install` / `install-files` only, matching the single upstream read site at `vendor/dots-hyprland/sdata/subcmd-install/3.files.sh:219`. `install-setups --dry-run` shows no such flag — the crisp negative the assert tests.
- **670 lines of retired machinery removed** in one commit: the 60-entry package array and its four collect/mark helpers, the `protect` subcommand (removed from `ALLOWLIST`, so it is refused rather than dispatched into a hole), and the eight hypr session-hook helpers with every call site.
- **Two function signatures shrunk safely.** `uninstall_gate` 5→3 and `run_safe_uninstall` 6→4 positional parameters, renumbered contiguous, with both call sites updated in the same edit. Verified by an actual `uninstall --dry-run` exit-code check — the place where a `set -u` unbound-variable abort would surface.
- **`scripts/phase16-retire-assert.sh` created** in the exact `phase12-full-smoke.sh` evidence shape, non-mutating, 17 hard asserts, ending `=== done: FAIL=0 ===`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Confirm the two one-way removals** — no commit (the deliverable is the decision). The operator answered `proceed` at the `gate="blocking-human"` checkpoint, confirming removal of both the install backup (D-06) and the install confirmation prompt (D-09) exactly as planned.
2. **Task 2: End-to-end full-only install path + its assert** — `584f5ec` (feat)
3. **Task 3: Delete package-marking and session-hook machinery, shrink signatures** — `b4320f5` (refactor)

**Plan metadata:** see the `docs(16-01)` commit that carries this file.

## Files Created/Modified

- `arch/dots-hyprland.sh` — install path reduced to a single seam; `SAFE_DEFAULTS`, `II_BACKUP_DIR`, `needs_safe_defaults`, `backup_gate`, `is_help_only_user_flags`, `user_flags_contain`, the whole package-marking cluster and the whole session-hook cluster deleted; `touches_files()` added; `uninstall_gate` / `run_safe_uninstall` signatures shrunk; retired documentation removed from `usage()`. `+204/−162` in the Task 2 commit and `+9/−670` in the Task 3 commit, taking the file from 1531 to 740 lines.
- `scripts/phase16-retire-assert.sh` — new, executable, non-mutating. Syntax gate, then per-subcommand dry-run argv captures asserting residual-flag omission, scoped skip-backup forwarding, prompt absence, and `--full` acceptance-without-forwarding.

## Decisions Made

- **`proceed` on the one-way gate (Task 1).** Both D-06 and D-09 land as written. Bounding facts, both re-verified this run: the existing snapshots `~/ii-original-dots-backup` and `~/ii-original-dots-backup.20260904T171128Z` are untouched on disk, and the install does not become unattended — upstream `./setup` still sources `0.greeting.sh` and calls `pause()` unless `-f/--force` is passed, which this wrapper never injects.
- **A1 — scoped skip-backup.** Appending the flag everywhere is accepted by upstream `getopt` but would put a flag in the `install-setups` dry-run preview that cannot affect anything. `touches_files()` is the deleted `needs_safe_defaults` predicate under a name that is now true.
- **A2 — `--full` accepted everywhere.** The old scope check used the very predicate D-04 deletes. `install-deps --full` therefore flips from exit 1 to exit 0; the printed ignored-note makes the behaviour self-explaining, and the assert records the flip explicitly.
- **A3 — `run_upstream_uninstall_dangerous` untouched.** `git diff -U0 HEAD~ -- arch/dots-hyprland.sh | grep -c 'upstream_uninstall_dangerous'` is 0. After this phase it is the only remaining route to a cascading removal, and its `UPSTREAM-UNINSTALL` type-token guard is intact.
- **`usage()` scope split.** The retired *content* was removed here because Task 2's and Task 3's acceptance criteria forbid `allow-skip-backup`, `PROTECT_EXPLICIT`, `skip-protect` and `keep-hypr-hooks` anywhere in the file *including comments*, and all four lived in the heredoc. The heredoc's *structure* and the line `uninstall  Safe dual-run uninstall (wrapper-owned; see below)` were deliberately left alone — Task 3 says in as many words to fix only the `[UNINSTALL]` banner echo here and to leave the heredoc rewrite to plan `16-02`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed the `rc` accumulator from `run_safe_uninstall`**
- **Found during:** Task 3 (signature shrink, step C)
- **Issue:** `rc` had exactly one setter — the `protect_explicit_packages 0 || { …; rc=1; }` block that step A deletes. The plan's step C enumerates the *positional* reads to remove but not this local. Deleting `local rc=0` while leaving the trailing `if ((rc != 0))` warning and `return $rc` is an unbound-variable abort under `set -euo pipefail` at the very end of a real uninstall; leaving `local rc=0` in place instead would leave provably dead code that the next reader would mistake for an unfinished edit.
- **Fix:** Removed `local rc=0`, the `if ((rc != 0))` warning block, and replaced `return $rc` with an explicit `return 0`. The function's success contract is unchanged (it previously returned 0 on every path that did not hit a protect failure).
- **Files modified:** `arch/dots-hyprland.sh`
- **Verification:** `bash -n` clean; `printf '' | ./arch/dots-hyprland.sh uninstall --dry-run` exits 0; `grep -n '="\$[0-9]"'` confirms contiguous `$1..$3` and `$1..$4` reads against 3- and 4-argument call sites.
- **Committed in:** `b4320f5` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking).
**Impact on plan:** The fix is forced by a deletion the plan mandates and is confined to the function that deletion empties. No scope creep — every other edit maps to an enumerated call site in `16-RESEARCH.md`'s surgery map.

## Issues Encountered

- **`printf 'yes\n' |` is no longer needed but was kept out of the new assert.** `16-PATTERNS.md` notes the pipe becomes unnecessary once D-09 lands and that leaving it is harmless. The new script feeds `printf ''` instead, which is strictly stronger: it proves nothing on the install path is waiting on stdin, rather than merely tolerating a fed answer.
- **Positive `grep A | grep -q B` under `set -o pipefail`.** The repo idiom risks a SIGPIPE-derived non-zero pipeline status when the right-hand `grep -q` exits early. It is safe here because the reader cannot match before the writer's single short line is written, so the write always completes first. Retained verbatim so the new script stays structurally indistinguishable from its analog.

## Expected-Red Suites (by design, not regressions)

Both are recorded as `open` entries in `.planning/WINDOWS.md` so they stay visible at ship time:

| Script | Why red | Repaired by |
|--------|---------|-------------|
| `scripts/phase12-full-smoke.sh` | Asserts the retired safe-profile behaviour (residual injection on a bare install, `--skip-backup` refusal, `--full` scope refusal) | plan `16-02` (D-34) |
| `scripts/phase13-d19-assert.sh` | Hard-fails on any `arch/dots-hyprland.sh` diff from its pinned base `14c6828` | plan `16-06` (D-38) — must be re-pinned against the *final* wrapper state, i.e. after `16-02` |

`scripts/phase14-verify.sh` was deliberately not run: it asserts a clean working tree outside a hard-coded Phase 14 prefix and cannot pass mid-wave (research Pitfall 1). It is edited in `16-03` and run at the phase gate in `16-10`.

## Known Stubs

None. Every symbol the plan marks for deletion is gone from code and comments alike; nothing was stubbed out or left as a placeholder.

## Threat Flags

None. No new network endpoint, auth path, file-access pattern or schema change was introduced — this plan is net-subtractive. The registered trust boundaries are unchanged: T-16-01 (unknown long option reaching upstream `getopt`) is held by the retained `--full)` arm and asserted two-stage; T-16-02 by removing `protect` from `ALLOWLIST` and asserting the refusal message; T-16-03 by the untouched array-only exec; T-16-04 by the in-one-edit signature shrink plus the exit-code check; T-16-07 by leaving `run_upstream_uninstall_dangerous` out of this plan's diff entirely.

## User Setup Required

None — no external service configuration required. The plan's frontmatter carries no `user_setup` block.

## Next Phase Readiness

- **Ready for `16-02`.** `usage()` is intentionally stale: it still describes the pre-retirement uninstall as a "dual-run" uninstall and still documents the wrapper as if the retired flags exist in spirit. `16-02` rewrites the heredoc and inverts `scripts/phase12-full-smoke.sh`.
- **Blocker for `16-06`, not for `16-02`.** `git diff <BASE> -- <path>` compares BASE against the *working tree*, so `16-06`'s D-19 re-pin must resolve its base at run time and must land after `16-02`'s wrapper touch. Recorded as assumption A4 in the plan; nothing in this plan pre-empts it.
- **Wrapper stdout is now final for the wave-1 half.** The two strings the wave-3 playbook must quote are `[INSTALL] ./setup <sub> [--skip-backup] …  (cwd=…)` and `[CONFIG] dry-run: would exec from <II_ROOT>: ./setup <sub> [--skip-backup]`, plus the new `[CONFIG] --full is accepted but ignored: full is now the only install behavior.` note. `16-02`'s usage rewrite is the only remaining wrapper change before D-42's documentation freeze.

## Self-Check: PASSED

- `scripts/phase16-retire-assert.sh` — FOUND on disk, executable, exits 0 at `=== done: FAIL=0 ===`
- `arch/dots-hyprland.sh` — FOUND on disk, `bash -n` clean, 740 lines
- `.planning/phases/16-.../16-01-SUMMARY.md` — FOUND on disk
- Commit `584f5ec` — FOUND in `git log --oneline --all`
- Commit `b4320f5` — FOUND in `git log --oneline --all`
- Every `<acceptance_criteria>` item from Task 2 and Task 3 re-run after the final commit: all pass
- Plan-level `<verification>` honoured: the retirement assert is at `FAIL=0`; `phase12-full-smoke.sh` / `phase13-d19-assert.sh` were left red by design and not run as gates; `phase14-verify.sh` was not run at all

---
*Phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook*
*Completed: 2026-09-07*
