---
phase: 19-link-aware-verify
plan: 01
subsystem: testing
tags: [bash, stow, rsync, git, symlinks, exit-codes, adversarial-test]

# Dependency graph
requires:
  - phase: 18-capture-model-three-trees-and-the-collision-map
    provides: "run_verify()'s repo-side walk, the capture/ block, the wrapper-owned verify/capture dispatch, and the assert-script contract (four labels, two counters, porcelain bracket, scratch-repo fixture builder) that scripts/phase18-capture-model-assert.sh established"
  - phase: 14-live-full-adopt-verify
    provides: "scripts/phase14-verify.sh — the frozen output contract, the four labels, the `=== done: FAIL=n FINDINGS=n ===` summary line, and the governing 'never [PASS] what you could not observe' principle"
provides:
  - "`verify` accepts exactly -h, --help, --strict, --quiet and refuses every other argument with exit 2, on fd 2, with no summary line in either stream"
  - "A pre-walk precondition block in run_verify() — empty/non-directory HOME, absent stow/ and restow/, missing required binary, unresolvable main repo root — each a single `[FAIL] precondition: <reason>` on fd 2 and exit 2"
  - "`--strict` promotes findings to a failing exit code while leaving all output above the byte-frozen summary line unchanged"
  - "`--quiet` suppresses [PASS] lines only, reordering nothing"
  - "scripts/phase19-link-aware-verify-assert.sh — the phase assert, with its fixture builder, runner, guard_scratch_target() and Sections 1-3"
  - "guard_scratch_target() — a single callable fail-closed realpath prefix gate, proven by probe to refuse two real out-of-scratch targets and to admit the in-scratch one"
  - "The VER-04 adversarial harness: stow a fixture, rsync -a --delete over it, and verify goes from exit 0 on a [PASS] line to exit 1 on a [FAIL] line carrying a `stow -t` recovery invocation"
affects: [19-02, 19-03, 19-04, 19-05, phase-20-verify-proves-the-bulk-stow]

# Actuals (#2632) — same estimateTokens scale (chars/4) as the plan's estimate,
# measured over the realized diff, not a harness token count.
actuals:
  tokens: 8698
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Precondition block placed below the flag parser and above the counters — one placement satisfies both D-12's positional exit-2 rule and D-17's no-summary rule"
    - "A destructive assert harness whose only gate is a callable function that depends on nothing the code under test does, with a three-case subshell probe proving the gate FIRES rather than merely exists"
    - "Runner roots parameterised as RUN_REPO/RUN_HOME so precondition cases vary one root at a time instead of duplicating the runner"

key-files:
  created:
    - scripts/phase19-link-aware-verify-assert.sh
  modified:
    - arch/dots-hyprland.sh

key-decisions:
  - "Unknown verify flags exit 2 rather than 1 (D-15) — an unknown flag means the tree was never examined"
  - "--quiet gates pass() as an `if` block, never a trailing conjunction, because that form leaves the function's return status at 1 when quiet is 0 and aborts the set -euo pipefail caller at the first passing check"
  - "The D-26 guard's refusal is a bare `echo … >&2` and is deliberately NOT routed through the assert's fail() emitter — the probe expects two refusals, and routing them through fail() would end an entirely correct run at FAIL=2"
  - "Both guard-refusal probe candidates are real, EXISTING paths ($HOME/.config and the real stow/ tree) because realpath without -m fails on an absent path, which would exercise the fail-closed arm instead of the prefix-mismatch arm and prove the weaker thing"
  - "The plan's acceptance criterion that ./scripts/phase17-unblock-assert.sh exits 0 is unsatisfiable and pre-existing: it has been FAIL=8 since Phase 18 removed repo-root .config/, recorded in 18-11-SUMMARY.md and 18-VERIFICATION.md. Not fixed here (scope boundary); the half of that criterion this plan actually owns — the wrapper contributing zero occurrences of the counted stow flag pair — holds"
  - "The Phase 18 walk body and the capture/ block were not touched (D-07, D-22); the only movement inside them is the relocation of the two-line main_root resolution up into the precondition block"

patterns-established:
  - "Fail-closed destruction gate: resolve the target at CALL TIME with realpath, strict-prefix compare against a mktemp -d root captured at setup, return (never exit) so the refusal can be captured and asserted"
  - "Three-root harness wiring: HOME at the scratch home, the wrapper invoked being a copy inside the scratch repo, and the invocation's cwd being that scratch repo — break any one and the harness silently tests the real tree"
  - "Volumes that move with the operator's uncommitted edits are recorded in an [INFO] message and never wired into a comparison"

requirements-completed: [VER-03, VER-04]

coverage:
  - id: D1
    description: "`verify` accepts exactly -h, --help, --strict, --quiet and refuses every other argument with exit 2, writing the reason on fd 2 and the summary line on neither stream"
    requirement: "VER-03"
    verification:
      - kind: integration
        ref: "scripts/phase19-link-aware-verify-assert.sh#Section 2 — accepted and rejected surface (4 accepted flags, 4 rejected arguments)"
        status: pass
      - kind: integration
        ref: "bash -c '... ./arch/dots-hyprland.sh verify --bogus ...' -> EXITCODE_OK"
        status: pass
    human_judgment: false
  - id: D2
    description: "A precondition failure exits 2 before the walk starts, printing one `[FAIL] precondition: <reason>` on fd 2 and no summary line"
    requirement: "VER-03"
    verification:
      - kind: integration
        ref: "scripts/phase19-link-aware-verify-assert.sh#Section 2 — three precondition cases (empty HOME, HOME naming a regular file, repo with neither stow/ nor restow/)"
        status: pass
    human_judgment: false
  - id: D3
    description: "--strict changes only the exit code and --quiet removes only [PASS] lines; neither narrows what is examined"
    requirement: "VER-03"
    verification:
      - kind: integration
        ref: "scripts/phase19-link-aware-verify-assert.sh#Section 3 — D-14 byte comparison, D-20 filtered comparison, D-13/D-16 counter equality across three runs"
        status: pass
    human_judgment: false
  - id: D4
    description: "The adversarial rsync-replace test: a stowed fixture passes, `rsync -a --delete` over it makes verify exit 1 naming the path with its `stow -t` recovery, and the identical run without the rsync exits 0"
    requirement: "VER-04"
    verification:
      - kind: integration
        ref: "scripts/phase19-link-aware-verify-assert.sh#Section 1 — negative control and VER-04 destruction"
        status: pass
    human_judgment: false
  - id: D5
    description: "The D-26 guard is one callable function that provably refuses two real out-of-scratch targets and admits the in-scratch one, and is the sole gate the destructive command passes through"
    requirement: "VER-04"
    verification:
      - kind: integration
        ref: "scripts/phase19-link-aware-verify-assert.sh#Section 1 — three-case subshell guard refusal probe (3 [PASS] lines carrying 'D-26 guard')"
        status: pass
    human_judgment: false
  - id: D6
    description: "`--quiet` output on the real tree is short enough to scan in one screen and every line it prints is worth seeing"
    requirement: "VER-03"
    verification: []
    human_judgment: true
    rationale: "Task 3's <human-check>. --quiet exists because the signal this phase produces is otherwise buried in its own success output; only a human can say whether that worked. workflow.human_verify_mode is end-of-phase, so this is deferred to phase verification rather than raised as a mid-flight checkpoint. Measured input for that judgement: the real-tree --quiet run emits exactly 1 line today (the summary), against 95 lines without the flag."

# Metrics
duration: 3 min
completed: 2026-09-14
status: complete
---

# Phase 19 Plan 01: Link-aware `verify` — argv to exit code, proven by a destroyed fixture — Summary

**`verify` now has a closed four-flag surface, a pre-walk exit-2 precondition block, and `--strict`/`--quiet` wired to the verdict and to `pass()` respectively — proven end-to-end by a new assert that stows a fixture, destroys it with a real `rsync -a --delete` behind a probe-proven fail-closed guard, and shows the run go from exit 0 to exit 1 naming the path and its recovery command.**

## Performance

- **Duration:** 3 min (execution window; excludes context load)
- **Started:** 2026-09-14T04:23:42Z
- **Completed:** 2026-09-14T04:27:01Z
- **Tasks:** 3
- **Files modified:** 2 (1 modified, 1 created)

## Accomplishments

- `run_verify()` accepts exactly `-h`, `--help`, `--strict`, `--quiet` and refuses everything else with **exit 2** on fd 2 — with the frozen `=== done:` line appearing in neither stream, because the refusal returns before the counters exist.
- A precondition block sits below the parser and above the counters, so D-12's positional exit-2 rule and D-17's no-summary rule are satisfied by one placement. It covers an empty or non-directory `HOME`, both `stow/` and `restow/` absent, a missing required binary (declared as a local array so 19-02 can add `git` under D-23 without restructuring), and an unresolvable main repo root — whose resolution moved up from below the counters so the condition is genuinely checked before the walk.
- `--strict` is a change to the exit condition only, written as a braced group inside the `if` so `set -e` cannot fire on the arithmetic test; `--quiet` gates `pass()` as an `if` block. Output above the byte-frozen summary line is unchanged under `--strict`, and `--quiet`'s output is the normal output minus its `[PASS]` lines, byte for byte.
- `scripts/phase19-link-aware-verify-assert.sh` is new and green at `FAIL=0 FINDINGS=0` with **27 `[PASS]` lines**, covering the VER-04 rsync-replace class and its negative control, the exit-code contract and the closed flag surface, and the flag-invariance of scope.
- The destruction is bounded by `guard_scratch_target()` — one callable function, resolving at call time, failing closed, returning rather than exiting — and the assert **proves it fires**: a three-case subshell probe refuses `$HOME/.config` and the real `stow/` tree (each `[FAIL]` naming both resolved values) and admits the in-scratch fixture target.

## Task Commits

1. **Task 1 (tracer): End-to-end — argv to exit code, proven by a fixture destroyed on purpose** — `c787051` (feat)
2. **Task 2: Section 2 — the exit-code contract and the closed flag surface** — `98f29a3` (test)
3. **Task 3: Section 3 — `--strict` and `--quiet` change the verdict and the volume, never the scope** — `437936b` (test)

**Plan metadata:** see the `docs(19-01)` commit that carries this file.

## Files Created/Modified

- `arch/dots-hyprland.sh` — `run_verify()`: widened flag parser with `strict`/`quiet` locals, exit 2 on unknown flags, the pre-walk precondition block with its `required_bins` local array and the relocated `main_root` resolution, `pass()` gated on `quiet`, the `--strict` exit branch; `usage()` gains the two flags on the `verify` line plus a "Verify" block documenting them and the exit-2 refusal.
- `scripts/phase19-link-aware-verify-assert.sh` — new, executable, 556 lines. Prologue with the four-label two-counter contract; `--ignored` porcelain bracket with a narrow known-artifact filter; binary guard for `stow`/`rsync`; `build_fixture()` and `build_bare_repo()`; `run_fixture_verify()` with separated stdout/stderr captures; `guard_scratch_target()`; Sections 1-3; closing self-check with the `FIXTURE_LEAK` sweep and the ROADMAP criteria summary.

## Decisions Made

- **Exit 2 for unknown flags, not 1** (D-15). Confirmed safe by grep: `scripts/phase18-capture-model-assert.sh` Section 7a reports `rc` but never asserts `rc -eq 1` for a rejected flag, so no same-commit edit was needed there.
- **`--quiet` as an `if` block, never a trailing conjunction.** As the last command of a function the conjunction form leaves the return status at 1 whenever `quiet` is 0, which aborts the `set -euo pipefail` caller at the first passing check — the exact defect STATE.md records being falsified live in Phase 17's dispatch guard.
- **The guard's refusal bypasses the assert's `fail()` emitter.** `fail()` increments the FAIL counter and the probe deliberately provokes two refusals; routing them through it would end an entirely correct run at `FAIL=2`. A refusal the harness asked for is not a harness failure.
- **Both refusal-probe candidates are real, existing paths.** `realpath` without `-m` fails on an absent path, so a nonexistent probe path would exercise the fail-closed arm instead of the prefix-mismatch arm and prove the weaker thing.
- **Runner roots parameterised as `RUN_REPO`/`RUN_HOME`** rather than adding a second runner, so Section 2's three precondition cases vary exactly one root at a time. This is the only change Task 2 made to Task 1's code.
- **The last merged-stream redirect was removed** (`command -v … 2>&1` became `2>/dev/null`), so a scan of the file for a merged capture finds nothing at all. It was a discard rather than a capture, but leaving it would have made D-37's separated-stream property ambiguous to a later grep.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The plan's `phase17-unblock-assert.sh` acceptance criterion is unsatisfiable and pre-existing**
- **Found during:** Task 1 (plan verification, coupling block)
- **Issue:** The plan requires `./scripts/phase17-unblock-assert.sh` to exit 0. It exits 1 with `FAIL=8`. Every one of those 8 failures reads repo-root `.config/` paths (`.config/hypr/custom/execs.lua`, `.config/kdeglobals`) that Phase 18 removed permanently under FIX-03. The condition is recorded as expected in `18-11-SUMMARY.md` (`FAIL=8` — expected due to repo-root `.config/` removal) and dispositioned in `18-VERIFICATION.md` (closed-phase asserts are not edited retroactively, per 18-CONTEXT.md D-20).
- **Fix:** None applied — this is a pre-existing failure in files unrelated to this task's changes, and the scope boundary forbids fixing it. The half of the criterion this plan actually owns was verified instead: `grep -c -- '--verbose=5 --no-folding' arch/dots-hyprland.sh` is **0**, so the wrapper still contributes zero occurrences and the across-`arch/` total of 18 that check 1b asserts is untouched (check 1b passes).
- **Files modified:** none
- **Verification:** `FAIL=8` both before and after this plan's changes; none of the 8 failing checks reads `arch/dots-hyprland.sh`; `./scripts/phase18-capture-model-assert.sh` exits 0 with `FAIL=0 FINDINGS=0`.
- **Committed in:** n/a (no code change)

**2. [Rule 2 - Missing Critical] The runner's two roots were parameterised so Section 2 could vary one at a time**
- **Found during:** Task 2 (Section 2, the three precondition exit-2 cases)
- **Issue:** Task 1's `run_fixture_verify()` hard-coded `cd "$T/repo"` and `HOME="$T/home"`. Section 2 must run against an empty `HOME`, a `HOME` naming a regular file, and a second repo holding neither `stow/` nor `restow/` — none reachable through a hard-coded runner. The plan explicitly requires reusing the Task 1 runner rather than introducing new ones.
- **Fix:** Introduced globals `RUN_REPO`/`RUN_HOME`, set by `build_fixture()` to the same two values, and read by the runner. `build_bare_repo()` was added for the third case, reusing the fixture builder's scratch-repo mechanics (a `git init`ed repo holding only the copied wrapper) so the sole variable is the absence of the two trees.
- **Files modified:** `scripts/phase19-link-aware-verify-assert.sh`
- **Verification:** all three precondition cases exit 2 with a `[FAIL] precondition:` line on fd 2; Section 1 and Section 3 still pass unchanged through the same runner.
- **Committed in:** `98f29a3`

---

**Total deviations:** 2 (1 blocking-criterion reclassified as out of scope with the owned half verified, 1 missing-critical parameterisation)
**Impact on plan:** No scope creep. The parameterisation is the minimum change that lets the plan's own instruction ("reuse the Task 1 runner") hold. The `phase17` criterion was a stale planning assumption about a closed phase's assert, not a defect introduced here.

## Issues Encountered

None. The expected red window opened exactly as the plan predicted: `./scripts/phase13-d19-assert.sh` now reports `[FAIL] arch/dots-hyprland.sh changed since 8497511` and exits 1. Per the objective this was **not** fixed, re-pinned or commented out — plan `19-05` closes it behind a new Phase 19 tier.

## Threat Flags

None. No new network endpoint, auth path, file-access pattern or schema change was introduced. The one new trust boundary — the assert's `rsync -a --delete` against the real filesystem — was already in the plan's `<threat_model>` as T-19-01 and is mitigated exactly as specified (callable `guard_scratch_target()`, call-time `realpath`, strict-prefix compare against the setup-captured `mktemp -d` root, fail-closed, refusal branch proven by a three-case probe rather than inferred from source text).

## Known Stubs

None. Every section written in this plan asserts against a real fixture. The sections this plan does not own are named as pending in the ROADMAP criteria summary block (criteria 1, 2 and 5, and the cp-through class and findings-only `--strict` promotion), each naming the plan that owes it, so later plans fill in the existing structure rather than inventing new structure.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `19-02`. The three things it depends on are in place and proven:

- The flag parser and precondition block exist in the shape `19-02` extends — `required_bins` is a local array, so adding `git` under D-23 is a one-element change.
- The assert's fixture builder, runner and `guard_scratch_target()` are functions, so `19-02` appends a section rather than rebuilding harness mechanics.
- The three-root wiring is proven, retiring the risk RESEARCH named as the single largest in this phase.

**Known open item carried forward:** `./scripts/phase13-d19-assert.sh` is red by design from this plan onward and is closed by `19-05`.

---
*Phase: 19-link-aware-verify*
*Completed: 2026-09-14*

## Self-Check: PASSED

- `arch/dots-hyprland.sh` — present on disk
- `scripts/phase19-link-aware-verify-assert.sh` — present on disk and executable
- `.planning/phases/19-link-aware-verify/19-01-SUMMARY.md` — present on disk
- Commits `c787051`, `98f29a3`, `437936b` — all found in `git log --oneline --all`
