---
phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook
plan: 06
subsystem: testing
tags: [bash, assert-script, git-drift, markdown-fence, python3, doc-sweep, marker-file]

# Dependency graph
requires:
  - phase: 16-02
    provides: "arch/dots-hyprland.sh in its final Phase 16 state at 0771cc2 — the commit this plan pins the drift baseline to"
  - phase: 16-04
    provides: "the full-only docs/dots-hyprland-workflow.md whose §6 apply fence is now compared against the Phase 13 source of truth"
  - phase: 16-05
    provides: "the swept docs/phase14-adopt-runbook.md, the last of the five corrections the sweep record consolidates"
provides:
  - "`16-DOC-SWEEP.md` — the phase's written record of what changed where, in the 15-DOC-SWEEP.md shape, with eight per-file correction tables and 40 severity-tagged rows"
  - "the same file as a load-bearing marker: `scripts/phase13-d19-assert.sh` selects its wrapper drift baseline by testing for its presence"
  - "a three-tier wrapper drift baseline in `scripts/phase13-d19-assert.sh`, newest tier first, pinned to 0771cc2"
  - "a W-3 apply-fence drift assert comparing docs/dots-hyprland-workflow.md against 13-SOT-APPLY.md on every run"
  - "a parameterised `extract_fence()` — one Markdown fence extractor, three call sites"
  - "all five tree-clean-agnostic assert suites green on a committed tree for the first time in the phase"
affects: [16-07, 16-08, 16-09, 16-10, phase-gate]

# Actuals (#2632)
actuals:
  tokens: 6554
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Marker-file baseline tiering: newest phase marker tested first, because older markers still exist on disk and a later branch never fires"
    - "One extractor, N call sites — a transform used twice is parameterised, never duplicated in a second idiom"
    - "A reconciling filter in an equality assert carries an adjacent comment naming why it exists, so it reads as documented rather than rigged"

key-files:
  created:
    - .planning/phases/16-retire-the-safe-profile-full-only-wrapper-and-playbook/16-DOC-SWEEP.md
  modified:
    - scripts/phase13-d19-assert.sh

key-decisions:
  - "The baseline was resolved at execution time via `git log -1 --format=%h -- arch/dots-hyprland.sh` (→ 0771cc2) and confirmed byte-identical to the working tree before being written, rather than copied from a planning document"
  - "`DOC_SWEEP_16` was declared in the top constants block rather than adjacent to `LIVE_VERIFY`, following the file's stated 'path constants at the top, never inline' convention; `LIVE_VERIFY` was left where it is rather than moved, since moving it is an edit the plan did not ask for"
  - "The load-bearing filter comment was restructured from a right-margin annotation block into a lead-in comment plus a same-line trailing note, because the annotation form placed the explanatory keyword outside the ±2-line window the acceptance check reads"
  - "The W-3 block was placed immediately after the D-19 fence execution, keeping all fence handling in one region of the file"
  - "The script header gained a note that it now carries two checks outside Phase 13's own subject matter, so a later reader is not surprised to find a Phase 16 pin and a playbook comparison in a Phase 13 script"

patterns-established:
  - "Drift baselines are re-pinned, never loosened: the tier chain grows a branch and the git verdict block below it stays byte-unchanged"
  - "A duplicated procedure is compared, not executed twice, when the procedure touches live state"

requirements-completed: [W-3, D-38, D-41, D-43]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "The phase has a written record of what changed where, in the same shape and vocabulary as the Phase 15 record, with the two later sections stubbed"
    requirement: "D-41"
    verification:
      - kind: other
        ref: "heading loop over the six required '## ' headings in 16-DOC-SWEEP.md => exit 0"
        status: pass
      - kind: other
        ref: "grep -c '^### ' => 11 (>=6); grep -cE severity-tagged four-column rows => 40 (>=8)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The record states the marker coupling and carries both unowned deferred rows"
    requirement: "D-43"
    verification:
      - kind: other
        ref: "grep -q 'phase13-d19-assert' && grep -qE 'WR-02' && grep -q 'graphical-session.target' => exit 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "The record quotes stale strings verbatim without tripping the phase-16 documentation ban, and names Waybar / rofi / swaync literally"
    requirement: "D-41"
    verification:
      - kind: integration
        ref: "non-allowlisted collective-noun token count => 0; ./scripts/phase16-retire-assert.sh => '=== done: FAIL=0 ==='"
        status: pass
    human_judgment: false
  - id: D4
    description: "The wrapper drift check is live again against a baseline that matches the working tree, selected by a tier that actually fires"
    requirement: "D-38"
    verification:
      - kind: integration
        ref: "./scripts/phase13-d19-assert.sh => 0 [FAIL], '[PASS] arch/dots-hyprland.sh unmodified since 0771cc2'"
        status: pass
      - kind: other
        ref: "git diff --name-only 0771cc2 -- arch/dots-hyprland.sh => empty; git status --porcelain -- arch/dots-hyprland.sh => empty"
        status: pass
    human_judgment: false
  - id: D5
    description: "The playbook's duplicated apply fence is compared against the Phase 13 source of truth, using one extractor, with the reconciling filter documented"
    requirement: "W-3"
    verification:
      - kind: integration
        ref: "./scripts/phase13-d19-assert.sh => '[PASS] W-3 docs/dots-hyprland-workflow.md apply fence matches the 13-SOT-APPLY.md D-18 fence'"
        status: pass
      - kind: other
        ref: "grep -c 'python3 - ' => 1; no awk/sed fence-extraction idiom; filter comment within the ±2-line window"
        status: pass
    human_judgment: false
  - id: D6
    description: "The fence-drift check demonstrably fails when the playbook copy drifts by one word, and the control leaves the file unmodified"
    requirement: "W-3"
    verification:
      - kind: integration
        ref: "negative control: sed one word in the playbook fence => rc=1, '[FAIL] W-3 … has drifted', diff printed; file restored, git status clean"
        status: pass
    human_judgment: false
  - id: D7
    description: "Every tree-clean-agnostic assert suite in the repository is green on a committed tree"
    requirement: "D-38"
    verification:
      - kind: integration
        ref: "phase10-inventory-assert, phase11-dispositions-assert, phase12-full-smoke, phase13-d19-assert, phase16-retire-assert => all OK / FAIL=0"
        status: pass
    human_judgment: false
  - id: D8
    description: "The sweep record's per-file correction tables faithfully consolidate what plans 16-01..16-05 actually did, rather than what they were planned to do"
    verification: []
    human_judgment: true
    rationale: "Fidelity of a prose record to five prior plans is a reading judgment, not a machine-checkable property. The stale strings were re-extracted from `git diff 7334498..HEAD` rather than transcribed from the plans, and the corrections cite the plan that made each one, but only a human comparing the record against the diffs can confirm nothing material was omitted or misattributed."

# Metrics
duration: 25 min
completed: 2026-09-08
status: complete
---

# Phase 16 Plan 06: Phase Sweep Record and Assert Repair Summary

**`16-DOC-SWEEP.md` written as both the phase's correction record and the marker file `scripts/phase13-d19-assert.sh` keys its wrapper drift baseline on — plus a third baseline tier pinned to 0771cc2 and a W-3 assert that compares the playbook's duplicated apply fence against the Phase 13 source of truth, taking all five assert suites green for the first time in the phase.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-09-08T04:40:00Z
- **Completed:** 2026-09-08T05:05:00Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- **The phase has a written record, and it doubles as a load-bearing marker.** `16-DOC-SWEEP.md` follows the Phase 15 shape exactly — preamble, the reused standing justification for why forbidden-string asserts never point at the sweep file itself, then `## Corrections applied` with eight `### <file path>` subsections, `## Reviewed, no findings`, `## Flagged, not edited`, `## Deferred fixes`, and the two sections plan `16-10` fills. It carries 40 severity-tagged correction rows against a floor of 8, and adds the sentence the Phase 15 record does not have: moving or renaming this file silently changes which commit the wrapper is compared against.
- **The stale strings were re-extracted, not transcribed.** Every quoted string in the correction tables came out of `git diff 7334498..HEAD` against the pre-phase state, so the record quotes what the repository actually said rather than what the plans said it said. For `arch/dots-hyprland.sh`, which lost 927 lines and whose line numbers all moved, the Line column names the symbol — `SAFE_DEFAULTS`, `backup_gate()`, `PROTECT_EXPLICIT`, `enable_hypr_ii_hooks()`, `usage()`.
- **The drift check is live again, against a baseline resolved at run time.** `git log -1 --format=%h -- arch/dots-hyprland.sh` returned `0771cc2` (`docs(16-02): rewrite wrapper usage to the surviving surface`), and `git diff --name-only 0771cc2 -- arch/dots-hyprland.sh` returned empty before the pin was written — which is the property that matters, because the check compares the pinned commit against the **working tree**, not against HEAD.
- **The new tier is first in the chain, and the file says why.** `14-LIVE-VERIFY.md` still exists on disk, so a branch placed after its test would never fire. The comment above the chain now states that ordering constraint, the working-tree comparison semantics, and the consequence — no later plan may touch the wrapper without re-pinning here.
- **The verdict block was not touched.** The `git cat-file -e` existence probe, the informational not-in-repo branch and the pass/fail pair below the chain are byte-unchanged in the diff. The check was re-pinned, not loosened, and the failure was not turned into an informational line.
- **W-3 closed with one extractor, not two.** The existing python3 heredoc was lifted into `extract_fence()` parameterised over (file, heading) and now serves three call sites: the D-19 fence that is executed, the `## Apply command (D-18)` fence in `13-SOT-APPLY.md`, and the `### Named files only` fence in the playbook. `grep -c 'python3 - '` is still exactly 1; no `awk`/`sed` extraction idiom was added; neither fence body was edited.
- **The reconciling filter is documented in the open.** The SoT copy carries one line the playbook copy does not — `# Phase 14 only. Do not run in Phase 13 (D-02, D-17).` — and the `grep -v` that drops it sits under a five-line comment naming it as the only difference and as load-bearing, plus a same-line trailing note. Without that documentation a later maintainer reads the filter as the assert cheating.
- **The playbook copy is compared, never executed.** The fence touches a live configuration tree; running both copies would double the side effects of one procedure. The `mktemp` + `bash -e` + `rm -f` execution half still applies to the SoT fence alone, unchanged.
- **The negative control proves the comparison is real.** Perturbing one word inside the playbook fence (`missing` → `absent`) made the script exit 1 with `[FAIL] W-3 … has drifted` and a printed `diff`; the control restored the file from a copy taken beforehand and `git status` came back clean.
- **All five tree-clean-agnostic suites are green on a committed tree.** `phase10-inventory-assert`, `phase11-dispositions-assert`, `phase12-full-smoke`, `phase13-d19-assert` and `phase16-retire-assert` all pass. This is the first point in the phase where that is true, and it is the precondition for the wave-5 planning-artifact edits.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write the phase sweep record** — `68ed661` (docs)
2. **Task 2: Re-pin the wrapper drift baseline and add the apply-fence drift assert** — `407fefc` (test)

## Files Created/Modified

- `.planning/phases/16-retire-the-safe-profile-full-only-wrapper-and-playbook/16-DOC-SWEEP.md` — **created**, 20160 bytes. Eight per-file correction subsections (`arch/dots-hyprland.sh`, `scripts/phase12-full-smoke.sh`, `scripts/phase14-verify.sh`, the two deleted scripts, `docs/dots-hyprland-workflow.md`, `docs/phase14-adopt-runbook.md`, and `scripts/phase16-retire-assert.sh` as a creation), three `## Reviewed, no findings` entries, an eight-row `## Flagged, not edited` table, two unowned deferred rows, and two stubbed sections for plan `16-10`.
- `scripts/phase13-d19-assert.sh` — `+64/−11`. Header note about the two non-Phase-13 checks it now carries; `PLAYBOOK` and `DOC_SWEEP_16` path constants added to the top block; the inline python3 heredoc lifted into `extract_fence()`; a W-3 comparison block with empty-extraction guards on both sides and a `diff … || true` on mismatch; the baseline `if`/`else` extended to a three-branch chain with the Phase 16 tier first. The git verdict block and the fence execution half are unchanged.

## Decisions Made

- **The baseline was resolved, not copied.** Research assumed a single wave-1 wrapper commit; the plan set actually split the wrapper across `16-01` and `16-02`, so a SHA taken from either planning document would have been wrong. Running `git log -1` and confirming an empty diff is self-correcting and survives a re-run — flagged assumption A4, resolved as the plan directed.
- **`DOC_SWEEP_16` went into the top constants block.** The plan's instruction carried two clauses in mild tension: "next to the existing marker constant" and "following the file's convention of constants at the top." `LIVE_VERIFY` is declared mid-file at its point of use. Declaring the new constant at the top satisfies the stated convention without moving an existing declaration the plan did not authorise touching; no acceptance criterion depends on adjacency.
- **The filter comment was restructured after a failing check, not weakened.** The first form put the explanation in a right-margin annotation block *below* the `grep -v` line; the acceptance check reads a ±2-line window around the `Phase 14 only` string, and the keyword landed outside it. The fix moved the explanation above the assignment and added a same-line trailing note. The documentation got stronger, not the assert weaker.
- **The script header now declares its widened remit.** A Phase 13 script that carries a Phase 16 wrapper pin and a playbook comparison is surprising on first read; three header lines now say so and cite D-38.

## Deviations from Plan

None — plan executed exactly as written.

Two things worth recording that are *not* deviations, because the plan anticipated both:

- The tier-ordering trap the plan and research both flagged as "the single most likely way to get the edit wrong" did not fire: the new branch was written first, and the run's pass line names `0771cc2` rather than falling through to the Phase 14 pin.
- `arch/dots-hyprland.sh` was not modified. `git status --porcelain -- arch/dots-hyprland.sh` is empty at the end of the plan, and `git diff --name-only 0771cc2 -- arch/dots-hyprland.sh` is empty, so the pin is valid against the working tree.

## Issues Encountered

- **One acceptance check failed on first run and was fixed before the commit.** `grep -B2 -A2 'Phase 14 only' | grep -iE '#.*(filter|only difference|load-bearing|expected)'` returned non-zero because the explanatory comment sat three-plus lines below the filter. Resolved by moving the explanation above the assignment and adding a same-line trailing note; re-ran and it passed. This is exactly what the check exists to catch — a filter whose justification is too far away to be read alongside it.
- **The plan's `<verification>` says all five assert scripts must be green while also stating `scripts/phase14-verify.sh` is not run here.** Read as: the five *tree-clean-agnostic* suites (`phase10`, `phase11`, `phase12`, `phase13`, `phase16`) are the set that must be green now; `phase14-verify.sh`'s clean-tree assertion cannot pass mid-wave and runs at the gate in plan `16-10`. All five are green.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **Wave 5 is unblocked.** Every assert suite that can be green mid-phase is green on a committed tree, which is the stated precondition for the planning-artifact edits in plans `16-07` through `16-09`.
- **One standing constraint now binds every later plan in this phase:** `arch/dots-hyprland.sh` must not be touched. The drift check compares the pinned `0771cc2` against the working tree, so any wrapper edit — including a one-character touch-up — re-breaks `scripts/phase13-d19-assert.sh` and requires re-pinning here.
- **`16-DOC-SWEEP.md` must not be moved or renamed.** Its path is what the first tier tests for. A rename silently reverts the baseline to the Phase 14 pin and the drift check starts failing again.
- **Two sections of the sweep record are stubs.** Plan `16-10` fills `## Planning-artifact corrections` (after wave 5) and `## Phase gate` (at the gate).
- **WR-02 and the D-38 autostart bootstrap stay open and unowned,** recorded as deferred in the sweep record with no owner invented for either.

---
*Phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook*
*Completed: 2026-09-08*

## Self-Check: PASSED

- `16-DOC-SWEEP.md` — present on disk
- `scripts/phase13-d19-assert.sh` — present on disk
- `16-06-SUMMARY.md` — present on disk
- Commits `68ed661`, `407fefc`, `86266fa` — all present in `git log`
