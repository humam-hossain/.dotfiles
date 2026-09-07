---
phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook
plan: 02
subsystem: infra
tags: [bash, wrapper, dots-hyprland, assert-suite, usage-heredoc, full-only]

# Dependency graph
requires:
  - phase: 16-01
    provides: "Full-only run_install_family with touches_files scoping, --full retained as an announced no-op, backup gate / protect subcommand / package array / hypr session hooks removed, scripts/phase16-retire-assert.sh green"
provides:
  - "usage() heredoc rewritten to describe only the surviving surface — five allowlisted subcommands, two wrapper-owned meta flags, four uninstall flags plus the guarded --upstream-dangerous hatch"
  - "An explicit interactivity note: the wrapper no longer prompts, upstream still greets and pauses (research Pitfall 3)"
  - "arch/dots-hyprland.sh in its final state for Phase 16 — the wave-4 drift re-pin in 16-06 can baseline against 0771cc2"
  - "scripts/phase12-full-smoke.sh rewritten to the full-only contract and green (16 PASS, 0 FAIL) — no longer expected-red"
  - "A stated job split between the two live wrapper suites, carried in both headers"
affects: [16-04, 16-06, 16-07, phase-verification]

# Actuals (#2632)
actuals:
  tokens: 7987
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Assert suites are rewritten in place, never retired — one live suite per behavior (D-34)"
    - "Two sibling suites with distinct jobs, each header naming the other"

key-files:
  created: []
  modified:
    - arch/dots-hyprland.sh
    - scripts/phase12-full-smoke.sh

key-decisions:
  - "usage() replaced in one deliberate rewrite rather than incremental line deletion (research Pitfall 9)"
  - "The two stale removed-flag identifiers in function comments were retired to decision-ID citations, reading the action's 'comments elsewhere follow the same rule' clause as governing over 'do not touch any other function' — comment-only, zero behavior change, same commit"
  - "The inventory / dispositions / Phase-14 operator pointers were dropped from the help text; only the playbook pointer survives, which is the one the smoke suite asserts and the playbook reciprocates"
  - "The deleted refusal blocks were not replaced with substitute refusals; the retired-subcommand allowlist assert is a new positive, not a re-pointed old one"

patterns-established:
  - "Assert-message prefixes cite only requirement IDs that survive the phase (FULL-01/02/04) or phase decision IDs (D-04/D-05/D-07/D-13)"
  - "A [PASS] floor plus a ban on deleted requirement IDs makes 'delete the assert instead of fixing it' fail the gate"

requirements-completed: [FULL-01, FULL-02, FULL-04, D-05, D-11, D-13, D-34]

coverage:
  - id: D1
    description: "usage() documents only the surviving surface: five allowlisted subcommands plus help, two wrapper-owned meta flags, four uninstall flags and the guarded --upstream-dangerous hatch"
    requirement: "D-13"
    verification:
      - kind: other
        ref: "bash -n arch/dots-hyprland.sh && ./arch/dots-hyprland.sh help | assert literals --full, --dry-run, --keep-venv, --packages-only, --configs-only, dots-hyprland-workflow"
        status: pass
      - kind: other
        ref: "stale-token loop over SAFE_DEFAULTS / allow-skip-backup / skip-protect / keep-hypr-hooks / skip-hyprland / skip-sysupdate / 'Backup gate' / protect + standalone --core ERE against the help capture"
        status: pass
    human_judgment: false
  - id: D2
    description: "The help text states plainly that the wrapper no longer prompts but upstream still greets and pauses, and never claims the install is unattended"
    requirement: "D-05"
    verification:
      - kind: other
        ref: "grep -qiE 'upstream[^.]{0,80}(greeting|pause|Enter to proceed)' && ! grep -qiE 'unattended|non-interactive|no prompts|silent install'"
        status: pass
    human_judgment: false
  - id: D3
    description: "scripts/phase12-full-smoke.sh asserts the full-only contract and is green — the D-34 window opened by 16-01 is closed"
    requirement: "D-34"
    verification:
      - kind: integration
        ref: "./scripts/phase12-full-smoke.sh — 16 [PASS], 0 [FAIL], '=== done: FAIL=0 ==='"
        status: pass
      - kind: other
        ref: "PASS floor >= 12 && output contains 'non-allowlisted' && output cites neither FULL-03 nor FULL-05"
        status: pass
    human_judgment: false
  - id: D4
    description: "The retired subcommand is refused by the ALLOWLIST array, proving the array edit rather than the function deletion"
    requirement: "D-11"
    verification:
      - kind: integration
        ref: "scripts/phase12-full-smoke.sh — 'D-07 retired subcommand exits non-zero' + 'D-07 refusal names it as a non-allowlisted subcommand'"
        status: pass
    human_judgment: false
  - id: D5
    description: "The 16-01 retirement contract is unregressed by both edits"
    requirement: "FULL-01"
    verification:
      - kind: integration
        ref: "./scripts/phase16-retire-assert.sh — '=== done: FAIL=0 ===' re-run after each task"
        status: pass
    human_judgment: false
  - id: D6
    description: "arch/dots-hyprland.sh is final for Phase 16, which is the precondition for the wave-4 drift re-pin"
    verification: []
    human_judgment: true
    rationale: "This is a claim about what later plans will NOT do. No assert available at this point can prove it; the real proof is scripts/phase13-d19-assert.sh returning green after plan 16-06 re-pins its baseline to 0771cc2. Files-modified frontmatter across 16-03..16-10 was checked and none names arch/dots-hyprland.sh, but that is evidence, not proof."

# Metrics
duration: 10 min
completed: 2026-09-07
status: complete
---

# Phase 16 Plan 02: Wrapper Self-Description and Behavior Suite Summary

**usage() rewritten to the five surviving subcommands, two meta flags and a truthful "upstream still pauses" note, with scripts/phase12-full-smoke.sh inverted from asserting SAFE_DEFAULTS injection to asserting its absence — 16 PASS, 0 FAIL.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-07T13:01:00Z
- **Completed:** 2026-09-07T13:11:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `usage()` replaced in one deliberate rewrite. The heredoc now documents the five allowlisted subcommands plus `help`, a new "What this wrapper does" paragraph naming the surviving guarantees (allowlist validation, submodule/executable preflight, array-exec after `cd` into the vendored tree, scoped backup-suppression forwarding), the two wrapper-owned meta flags, the four uninstall flags plus the `UPSTREAM-UNINSTALL` type-token hatch, seven bare examples, and the playbook pointer.
- The retired dual-run qualifier is off the `uninstall` line (D-13); it now describes the wrapper-owned removal on its own terms — exact-token confirmation, `pacman -R` with no cascade, ii-owned configs and state.
- An explicit **Interactivity** section closes research Pitfall 3: the wrapper asks nothing, upstream still runs its greeting and at least one `Enter to proceed` pause. The help text is asserted in both directions — it must tie `upstream` to a greeting/pause, and must contain none of `unattended` / `non-interactive` / `no prompts` / `silent install`.
- `scripts/phase12-full-smoke.sh` rewritten in place to the full-only contract: three blocks inverted, two deleted with no substitute invented, one new allowlist-refusal block added, header restated with the job split. The suite is the regression floor for every plan after this one.
- The Phase 16 broken-windows entry for the expected-red smoke suite (`WINDOWS.md` id 2) is marked **fixed**. Id 3 (`phase13-d19-assert.sh`) stays open by design — it is re-pinned in plan 16-06.

## Task Commits

1. **Task 1: Rewrite the usage heredoc to the surviving surface** — `0771cc2` (docs)
2. **Task 2: Rewrite the wrapper-behavior smoke suite to the full-only contract** — `3ba563e` (test)

## Files Created/Modified

- `arch/dots-hyprland.sh` — `usage()` rewritten (70 → 78 heredoc lines, entirely different content); two function comments retired from removed-flag identifiers to decision-ID citations. No executable line changed. **Final for this phase.**
- `scripts/phase12-full-smoke.sh` — assertion bodies rewritten; preamble, `FAIL`/`pass()`/`fail()` triple, `SC2064` trap idiom and summary footer preserved byte-identically.

## Decisions Made

- **`usage()` rewritten wholesale, not edited line by line.** Research Pitfall 9 names incremental deletion as the mechanism by which a stale fragment survives a heredoc edit. Splicing a fresh block over lines 22–92 removed that failure mode entirely.
- **The two stale comments were fixed.** The action text says "Comments elsewhere in the file follow the same rule — cite decision IDs, not removed identifiers," and one sentence later says "Do not touch any other function." Those pull against each other. Resolved in favor of the comment rule, because the fix is comment-only (zero behavior change), lands in the same commit as `usage()`, and leaves the wrapper carrying no removed-flag identifier anywhere in the file. After this commit `grep -n -- '--core\|--skip-hyprland\|--skip-sysupdate' arch/dots-hyprland.sh` returns nothing.
- **The inventory / dispositions / Phase-14 pointers were dropped from the help.** The plan enumerates what the heredoc must document "and nothing else," and those three pointers are not on that list. Verified first that no script or doc greps the wrapper's help for them; only `dots-hyprland-workflow` is asserted, and it survives.
- **No substitute refusal was invented.** The two deleted blocks tested mechanisms that 16-01 removed. The new allowlist-refusal block is a fresh positive assertion about the `ALLOWLIST` array edit (D-07), not a re-pointing of a deleted assert at a different target.
- **`--full` asserted on the `--full` path, not the bare path.** The four omission greps are now true of every invocation, but the block is left invoking with the flag because that is the path where a forwarding regression would surface first. The bare paths get their own dedicated inverted blocks.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Two stale removed-flag identifiers retired from function comments**
- **Found during:** Task 1
- **Issue:** `collect_ii_meta_packages` carried `install with --core skips it` and `collect_ii_config_targets` carried `install used --skip-hyprland`. Both name flags this phase removed, and both are false statements about how installs now run. The task action explicitly requires comments to cite decision IDs rather than removed identifiers, but its next sentence says to touch nothing but `usage()`.
- **Fix:** Rewrote both comments to cite D-04 and D-07 respectively. No code changed.
- **Files modified:** `arch/dots-hyprland.sh`
- **Verification:** `bash -n` exits 0; `grep -n -- '--core\|--skip-hyprland\|--skip-sysupdate' arch/dots-hyprland.sh` returns nothing; `scripts/phase16-retire-assert.sh` still `FAIL=0`; `git diff --name-only HEAD~1 HEAD -- arch/` names only `arch/dots-hyprland.sh`.
- **Committed in:** `0771cc2` (Task 1 commit)

### Factual corrections to the plan

**2. The mktemp handle count.** The plan's "Deleted by this plan" list says the two deleted blocks consumed "two `mktemp` handles." Only one did — `ALLOW_OUT`, used by the dual-key allow block. The bare-skip-backup refusal block used a hardcoded `/tmp/p12-smoke-skip.txt`, never `mktemp`, and so had no handle or trap entry to drop. `ALLOW_OUT` was dropped from both the declarations and the `trap` in the same edit as instructed. Two new handles were added (`DEPS_OUT`, `REFUSE_OUT`) because the inverted `install-deps --full` block now needs its capture greped for the ignored-note, and the new allowlist-refusal block needs a capture at all; both replaced hardcoded `/tmp` paths with the file's own `mktemp` idiom. Net: 5 handles → 6.

**3. `requirements.mark-complete` wrote nothing, correctly.** The plan's `requirements` frontmatter is `[FULL-01, FULL-02, FULL-04, D-05, D-11, D-13, D-34]`. `requirements.ready-ids` returned `FULL-01/02/04` as **blocked** (sibling plans in this phase also declare them and have no SUMMARY yet) and `D-05/D-11/D-13/D-34` as ready; `mark-complete` then returned all four as `not_found`, because those are Phase 16 *decision* IDs and have no row in `REQUIREMENTS.md`. `.planning/REQUIREMENTS.md` is therefore unchanged by this plan, which is the correct outcome, not a failed write.

---

**Total deviations:** 1 auto-fixed (1 missing critical) + 2 factual corrections to plan prose.
**Impact on plan:** None on scope. The auto-fix is comment-only and strictly reduces the surface that a later reader could act on incorrectly. Both corrections are bookkeeping.

## Issues Encountered

- **A `grep` shell function shadowed `/usr/bin/grep` in the execution shell and produced one false gate failure.** Task 2's third verify gate (`grep -q '=== done: FAIL=${FAIL} ==='` and the `pass()` one-liner BRE) returned non-zero. The same two patterns fail identically against the *pre-existing* `HEAD` version of the file, which is what identified it as an environment artifact rather than a regression: this session's shell snapshot defines `grep` as a function, and it does not handle those BREs the way the binary does. Re-running every gate for both tasks with an explicit `/usr/bin/grep` returned 0 across the board. No file was changed in response — changing the footer to satisfy a broken `grep` would have destroyed the byte-identical skeleton the plan requires.

- **`REQUIREMENTS.md` FULL-02 is now factually false and is not this plan's to fix.** Its text reads "Default `./arch/dots-hyprland.sh install` / `install-files` **still** injects SAFE_DEFAULTS … full is never accidental," which this phase deliberately falsifies. Plan `16-07` owns `.planning/REQUIREMENTS.md`; left untouched here per the scope boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `arch/dots-hyprland.sh` is final for Phase 16. Plan `16-06` should pin its drift baseline to `0771cc2`.
- `scripts/phase12-full-smoke.sh` is a green regression floor. Every later plan in this phase should re-run it.
- `scripts/phase16-retire-assert.sh` re-verified `FAIL=0` after each task.
- `scripts/phase13-d19-assert.sh` remains **expected-red** by design until `16-06`; `WINDOWS.md` id 3 stays open to track it. It was deliberately not run as a gate here.
- `scripts/phase14-verify.sh` was not run — it asserts a clean tree outside a hard-coded Phase 14 prefix and cannot pass mid-wave (research Pitfall 1). Plan `16-03` edits it.
- Carried forward for `16-07`: `REQUIREMENTS.md` FULL-02's text still describes the retired behavior.

## Self-Check: PASSED

- Files on disk: `arch/dots-hyprland.sh` FOUND, `scripts/phase12-full-smoke.sh` FOUND.
- Commits reachable: `0771cc2` FOUND, `3ba563e` FOUND.
- Task 1 gates 1–4: all exit 0 (re-run with `/usr/bin/grep`).
- Task 2 gates 1–4: all exit 0 (re-run with `/usr/bin/grep`).
- `./scripts/phase12-full-smoke.sh` → 16 `[PASS]`, 0 `[FAIL]`, `=== done: FAIL=0 ===`.
- `./scripts/phase16-retire-assert.sh` → `=== done: FAIL=0 ===`.
- No file deletions in either task commit; no untracked files left behind.

---
*Phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook*
*Completed: 2026-09-07*
