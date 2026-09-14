---
phase: 19-link-aware-verify
plan: 02
subsystem: testing
tags: [bash, stow, symlinks, git, dangling-links, folded-directories]

# Dependency graph
requires:
  - phase: 19-link-aware-verify
    provides: "19-01's flag parser, the pre-walk precondition block with its `required_bins` local array and relocated `main_root` resolution, and `scripts/phase19-link-aware-verify-assert.sh` with its fixture builder, runner and guard_scratch_target()"
  - phase: 18-capture-model-three-trees-and-the-collision-map
    provides: "run_verify()'s repo-side walk, the four-label two-counter output contract, and the `stow -t` recovery-message shape"
provides:
  - "A per-directory folded-ancestor pre-check in run_verify()'s repo-side walk — one [FAIL] per folded component carrying an unstow-plus-re-stow recovery, never one [FAIL] per file underneath it"
  - "A dangling-into-repo arm reading the RAW link target and resolving it manually — [FAIL] when it lands under the repo (PITFALLS A-6), [INFO] otherwise"
  - "`realpath` as a declared required binary, and canonicalised repo-prefix comparison for both new arms (T-19-02)"
affects: [19-03, 19-04, 19-05]

actuals:
  tokens: 2400
  tasks: 1
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Two memos for one per-directory check: a per-live-directory verdict cache (walk once per directory, not once per file) plus a per-component reported-set (two managed directories under one folded component still emit exactly one [FAIL])"
    - "Canonicalise before every repo-prefix test — `realpath -m --` on the joined target, matching the safe_rm_path idiom already in this file"

key-files:
  created: []
  modified:
    - arch/dots-hyprland.sh

key-decisions:
  - "The dangling arm canonicalises the joined target with `realpath -m --` before the repo-prefix test, because stow writes RELATIVE targets and a literal prefix test on `../../github_repo/.dotfiles/stow/…` never matches the repo root — found by probe, not by reading"
  - "`realpath` was added to `required_bins` because the two new arms now depend on it; an undeclared dependency that only matters on a pathological tree is a verdict that degrades silently in exactly the case it exists for"
  - "The folded-ancestor recovery text is the non-adjacent `stow -D --no-folding … && stow --no-folding …` form, so `scripts/phase17-unblock-assert.sh`'s counted `--verbose=5 --no-folding` pair stays at 18 and this file keeps contributing zero"

patterns-established:
  - "Prefix tests against the repo compare canonicalised strings on BOTH sides (`main_root_real`), never a literal prefix on an unresolved argument"

requirements-completed: []

coverage:
  - id: D1
    description: "A managed file whose ancestor directory is itself a symlink into the repo produces exactly one [FAIL] for that directory, carrying an unfold command, and not one [FAIL] per file underneath it"
    requirement: "VER-01"
    verification:
      - kind: integration
        ref: "scratch fixture: folded $HOME/.config/fxpkg -> repo stow package; asserts rc=1, exactly one [FAIL], recovery command present -> FOLDED_OK"
        status: pass
    human_judgment: false
  - id: D2
    description: "A declared live path that is a symlink whose target does not exist is [FAIL] when the unresolved target lands under the repo (PITFALLS A-6) and [INFO] otherwise, with the raw target read by a bare `readlink` and resolved manually"
    requirement: "VER-01"
    verification:
      - kind: integration
        ref: "scratch fixture: absolute dangling-into-repo link and non-repo dangling link in one run -> [FAIL] + [INFO], FAIL=1"
        status: pass
      - kind: integration
        ref: "scratch fixture: RELATIVE dangling target `../../../repo/stow/…/gone` -> [FAIL], FAIL=1 (the live shape stow actually writes)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The two new checks do not fire on the real tree, which is measured to have zero folded ancestors and zero repo-bound dangling links"
    requirement: "VER-01"
    verification:
      - kind: integration
        ref: "./arch/dots-hyprland.sh verify -> `=== done: FAIL=0 FINDINGS=0 ===`"
        status: pass
      - kind: integration
        ref: "./scripts/phase19-link-aware-verify-assert.sh -> FAIL=0 FINDINGS=0"
        status: pass
    human_judgment: false

duration: 2 min
completed: 2026-09-14
status: halted
---

# Phase 19 Plan 02: The content observation and the two link observations the walk could not make — Summary (HALTED AT CHECKPOINT)

**Task 1 shipped: `run_verify()`'s repo-side walk now sees a folded ancestor directory (one `[FAIL]` per folded component, never one per file) and a link that dangles into the repo (raw target read and resolved manually, because `readlink -f` returns the empty string and would report a broken pair as `[PASS]`). Execution then stopped at Task 2, a `gate="blocking-human"` decision checkpoint that cannot be auto-selected.**

## Status: HALTED — awaiting a human decision

This plan is **not complete**. It stopped at Task 2 by design.

| Task | Name | Type | State |
|------|------|------|-------|
| 1 | Folded ancestor directories and links that dangle into the repo | `auto` | **Complete** — committed `0edddfe` |
| 2 | Make `git` a hard dependency of `verify` — its absence becomes exit 2 | `checkpoint:decision` `gate="blocking-human"` | **BLOCKED — awaiting human** |
| 3 | The content observation, the untracked-file gap, and the cp-through boundary | `auto` | Not started — gated on Task 2 |

Task 2 is rated **one-way** (D-23 in `19-CONTEXT.md`). `gate="blocking-human"` is never auto-approved in any mode, auto-mode included. A fresh continuation agent resumes at Task 3 once the decision is given.

## Performance

- **Duration:** 2 min (Task 1 only; excludes context load)
- **Started:** 2026-09-14T06:31:59Z
- **Halted:** 2026-09-14T06:34:09Z
- **Tasks:** 1 of 3
- **Files modified:** 1

## Accomplishments

- **Folded-ancestor pre-check (D-04).** For each declared live path, the walk climbs the ancestor chain from the file's own directory up to (not including) `$HOME`, and a component that is itself a symlink resolving under the repo is a `[FAIL]` naming the component, its resolved target and the unfold command. It runs **before** the per-file `-e`/`-L` tests and `continue`s on a hit, so a folded directory is reported as a folded directory rather than as N misplaced links.
- **Two memos, not one.** `folded_verdict` caches the verdict per live directory (the chain is walked once per directory, not once per file); `folded_reported` caches which ancestor *components* have already been named. The second is what makes "one failure, not N" hold when two managed directories sit under one folded component — a single per-file memo would emit one `[FAIL]` per managed directory.
- **Dangling-into-repo arm (D-06 / PITFALLS A-6).** Positioned after the `-L` test and before the `readlink -f` equality comparison, because `readlink -f` returns the **empty string** for a dangling link: it both discards where the link pointed and compares equal to the equally-empty resolution of a missing repo-side target, so the existing equality test would report a broken pair as `[PASS]`. The arm reads the raw target with a bare `readlink --`, joins a relative one against the link's own directory, and splits `[FAIL]` (under the repo) from `[INFO]` (anywhere else).
- **The recovery text keeps the Phase 17 count at 18.** The folded `[FAIL]` names `stow -D --no-folding -t ~ <pkg> && stow --no-folding -t ~ <pkg>` — two invocations, each with the no-folding flag, and no verbosity flag anywhere, so `arch/dots-hyprland.sh` still contributes zero occurrences of the counted adjacent pair.
- **Both checks are silent on the real tree**, which is measured to have zero folded ancestors and zero repo-bound dangling links. `verify` still reports `=== done: FAIL=0 FINDINGS=0 ===`.

## Task Commits

1. **Task 1: Folded ancestor directories and links that dangle into the repo** — `0edddfe` (feat)

_No plan-metadata commit yet — this SUMMARY is the partial written at the checkpoint, and it will be superseded when the plan completes._

## Files Created/Modified

- `arch/dots-hyprland.sh` — `run_verify()`: `realpath` added to `required_bins`; `main_root_real` canonicalised once in the precondition block; the `folded_verdict`/`folded_reported` associative memos and the ancestor-walk loop at the head of the per-file chain; the dangling arm between the `-L` test and the `readlink -f` equality comparison.

## Decisions Made

- **The dangling arm canonicalises the joined target before the prefix test.** See Deviation 1 — the literal form silently misclassified the exact shape `stow` produces.
- **`realpath` became a declared required binary** rather than an assumed one. It is already the established idiom in this file (`safe_rm_path`, lines 462-470), and the plan's own Task 3 minimal-PATH probe lists it, so declaring it costs nothing and closes a silent-degradation path.
- **`main_root_real` is computed once in the precondition block**, not per file. The pre-existing `capture/` block's unresolved `"$main_root"/*` comparison was left alone — it is outside this task's changes (scope boundary).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The dangling arm's repo-prefix test was written against an unresolved path and misclassified every relative target**

- **Found during:** Task 1 (probe of the `<done>` criterion, before committing)
- **Issue:** The plan and `19-RESEARCH.md` §Pattern 3 both specify joining the raw target against the link's directory and then `case`-matching the result against `"$main_root"/*`. Probed with the shape `stow` actually writes — a **relative** target — the joined string is `…/home/.config/fxpkg/../../../repo/stow/fx/.config/fxpkg/gone`. The `..` components are not collapsed, so the literal prefix never matches the repo root and a dangling link **into the repo** was reported as `[INFO] dangling symlink (outside repo)` with `FAIL=0`, exit 0. That is the precise inversion of PITFALLS A-6 — the condition the arm exists to make loud, reported as the benign one. It is also the tampering vector the plan's own `<threat_model>` names as **T-19-02**: "compare resolved strings against `"$main_root"/*`, never a literal prefix on the unresolved argument".
- **Fix:** The joined path is canonicalised with `realpath -m --` before the `case`, and both sides of every repo-prefix test now compare canonicalised strings (`main_root_real`, resolved once in the precondition block). `-m` is what allows canonicalising a path whose final component does not exist, which is the definition of the dangling case. `realpath` was added to `required_bins` so the new dependency is declared rather than assumed. `readlink -f` is still **not** used to make the D-06 split — the raw target is still read with a bare `readlink --` and is still what the message prints.
- **Files modified:** `arch/dots-hyprland.sh`
- **Verification:** a third scratch fixture staging a relative dangling target `../../../repo/stow/fx/.config/fxpkg/gone` now yields `[FAIL] dangling symlink into repo: … -> ../../../repo/stow/fx/.config/fxpkg/gone` with `FAIL=1` and exit 1; it yielded `[INFO]` and exit 0 before the fix. The absolute-target and non-repo fixtures are unchanged, and the real tree still reports `FAIL=0 FINDINGS=0`.
- **Committed in:** `0edddfe` (part of the Task 1 commit)

**2. [Scope boundary — not fixed] Two of Task 1's three assert-script acceptance criteria are unsatisfiable inside a git worktree**

- **Found during:** Task 1 (acceptance-criteria verification)
- **Issue:** The criterion requires `./scripts/phase19-link-aware-verify-assert.sh`, `./scripts/phase17-unblock-assert.sh` and `./scripts/phase18-capture-model-assert.sh` to all exit 0. Measured here: phase19 exits 0 (`FAIL=0 FINDINGS=0`), phase17 exits 1 with `FAIL=9`, phase18 exits 1 with `FAIL=6`.
  - **phase18 `FAIL=6`** — all six failures name `vendor/dots-hyprland`, which is **empty in this worktree** and populated in the main checkout (`ls` confirms: `.`/`..` only here, a full tree there). Git worktrees do not populate submodules. `19-01-SUMMARY.md` records this same assert green in the main checkout.
  - **phase17 `FAIL=9`** — eight are the pre-existing repo-root `.config/` failures dispositioned in `18-VERIFICATION.md` and re-recorded in `19-01-SUMMARY.md`. The ninth, `1e GNU Stow rejected --verbose=5 --no-folding on a simulate run of package btop`, is a worktree artifact: check 1e runs `stow -n` from **this worktree's** `stow/` tree while the live `~/.config/btop/*` links are owned by the **main** repo, so stow reports `existing target is not owned by stow` and aborts. Reproduced directly.
- **Fix:** None applied. Neither condition is caused by this task's changes — no failure in either list names `arch/dots-hyprland.sh` — and both are environmental to worktree execution, so the scope boundary forbids touching them. Initialising the submodule would write into the main repo's shared `.git/modules`, which a worktree sub-agent must not do.
- **Files modified:** none
- **Verification:** the half of the criterion this task genuinely owns holds — `grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l` reports **18**, so the new recovery text added no counted pair (phase17 check 1b passes). phase19's own assert is green.
- **Committed in:** n/a (no code change)

---

**Total deviations:** 2 (1 auto-fixed bug, 1 unsatisfiable criterion reclassified as out of scope with the owned half verified)
**Impact on plan:** No scope creep. Deviation 1 is a correctness fix to code written in this task and is the difference between the dangling arm working and being decorative. Deviation 2 changes nothing.

## Issues Encountered

- The expected red window from `19-01` is still open and was **not** touched: `./scripts/phase13-d19-assert.sh` reports `[FAIL] arch/dots-hyprland.sh changed since 8497511`. Plan `19-05` closes it. This task's edits widen that diff further, exactly as the plan's objective states.

## Threat Flags

None. No new network endpoint, auth path or schema change. The two trust boundaries the plan's `<threat_model>` names for this task are mitigated as specified — T-19-02 by canonicalised comparison on both sides (strengthened past the plan's own text, see Deviation 1), and T-19-04 by `local x` split from `x="$(cmd)"`, `|| true` on every probe whose non-zero status is expected, and no post-increment arithmetic.

## Known Stubs

None from Task 1. Tasks 2 and 3 are unstarted, so this plan's share of ROADMAP criteria 4 (cp-through) and 5 (`[INFO]` content observation) is still owed, and `scripts/phase19-link-aware-verify-assert.sh`'s criteria summary still names them as pending.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Not ready.** This plan resumes at Task 3 once the Task 2 decision is given. Task 1's output is complete, committed and independently verified, so a continuation agent starts from a green tree and needs only:

1. The resolution of the `git`-as-hard-dependency decision (`hard-dependency` or `soft-degrade`).
2. `arch/dots-hyprland.sh` — the precondition block's `required_bins` (now `find readlink cmp dirname basename realpath`) and the walk's `pass "verified: …"` arm, both unchanged in shape from what Task 3's `<read_first>` expects.

---
*Phase: 19-link-aware-verify*
*Halted at checkpoint: 2026-09-14*

## Self-Check: PASSED

- `arch/dots-hyprland.sh` — present on disk, `bash -n` clean
- Commit `0edddfe` — found in `git log`
- `./arch/dots-hyprland.sh verify` — exit 0, `=== done: FAIL=0 FINDINGS=0 ===`
- `./scripts/phase19-link-aware-verify-assert.sh` — exit 0, `FAIL=0 FINDINGS=0`
