---
phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook
plan: 10
subsystem: planning-artifacts
tags: [phase-gate, sweep-record, transcript, coverage-arithmetic, frozen-artifacts, clean-tree]

# Dependency graph
requires:
  - phase: 16-06
    provides: "`16-DOC-SWEEP.md` with its two stubbed sections, the re-pinned wrapper drift baseline at `0771cc2` and the W-3 fence-drift assert this gate exercises"
  - phase: 16-07
    provides: "the amended requirement set at 19/19/0, the dispositioned milestone audit, and the phase's superseded-annotation form — the source for two of the six per-file correction tables"
  - phase: 16-08
    provides: "the swept project file, the two corrected rows in the Phase 11 disposition record, and the two fixed annotation clause variants"
  - phase: 16-09
    provides: "the amended roadmap and state file — the last two per-file correction tables, and the clean tree this gate required"
provides:
  - "`16-DOC-SWEEP.md` complete: six per-file planning-artifact correction tables, the 22-to-19 coverage arithmetic with a reason per deleted ID, the one resolved D-26/D-27 mapping conflict, the four frozen-artifact override sites, and the D-40 gate transcript quoted verbatim"
  - "a phase whose six assert suites are green on a committed, clean tree, with the one known finding still emitted and still allowed"
  - "the playbook cross-check discharged: the live suite's summary line is byte-identical to the expectation quoted at `docs/dots-hyprland-workflow.md:326`"
  - "the D-40 human re-login recorded as an outstanding operator step rather than claimed"
affects: [milestone-close, gsd-map-codebase-rerun]

# Actuals (#2632)
actuals:
  tokens: 9200
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A gate transcript quotes summary lines verbatim; a paraphrase is not evidence, and the record is checked for the quoted lines rather than for a claim about them"
    - "Commit first, run second, record third — the live suite asserts a clean tree outside a hard-coded prefix, so a dirty tree turns the gate red for a reason unrelated to the gate"
    - "A step the executing agent physically cannot perform is recorded as outstanding with what the operator still owes, never marked done by proxy"
    - "A quoted stale string that would trip the quoting document's own gate is elided as `[…]` and the elision is marked, rather than silently smoothed"

key-files:
  created:
    - .planning/phases/16-retire-the-safe-profile-full-only-wrapper-and-playbook/16-10-SUMMARY.md
  modified:
    - .planning/phases/16-retire-the-safe-profile-full-only-wrapper-and-playbook/16-DOC-SWEEP.md

key-decisions:
  - "The D-40 human re-login is recorded as OUTSTANDING, not performed. The executing agent cannot end the operator's Hyprland session. The automated session probes in `scripts/phase14-verify.sh` did run post-change and confirm the Lua entry, `qs -c ii` and the stopped Waybar/swaync, which is the strongest automated statement available and a weaker one than a fresh login. The plan's `<done>` clause asserts the operator has re-logged in; that half of it is not true yet and the record says so."
  - "`scripts/phase10-inventory-assert.sh` was added to the gate run as a sixth script although D-40 names only five. Plan `16-07`'s `INV-04` rewrite deliberately left it requiring the retired language in the frozen Phase 10 record, so it is the assert that would have gone red had anyone reconciled it with the rewrite. Running it is what proves the D-26-over-D-27 resolution actually held."
  - "`requirements mark-complete` was run and made no change. `ADOPT-02` and `ADOPT-03` are already `[x]` in `.planning/REQUIREMENTS.md`; `D-40`, `D-41` and `D-03` are `16-CONTEXT.md` decision IDs with no row in the requirement set. The tool reported `updated: false` and the file is byte-identical, which is the outcome the run's standing constraint on that file required."
  - "Two stale quotes were elided rather than reproduced. The old `ADOPT-03` text and the audit's `W-2` title carry the collective noun this project bans (Phase 14 D-39), and the old STATE.md next-step-2 text carries the assignment noun that the record's own gate bans within reach of `graphical-session`. Both elisions are marked in place."

patterns-established:
  - "The sweep record is the single place the three deleted requirement identifiers are named — the requirement set's own orphan check bans them file-wide, so the coverage note points here instead"
  - "Negated regexes are re-checked in Python before being trusted, because a ugrep complexity error on a negated pattern makes the check pass without testing anything"

requirements-completed: [ADOPT-02, ADOPT-03, D-40, D-41, D-03]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "The sweep record's planning-artifact section exists with one subsection per swept file"
    requirement: "D-41"
    verification:
      - kind: other
        ref: "`## Planning-artifact corrections` present; `^### ` count between it and `## Phase gate` = 9 (>= 6)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The record names the three deleted requirement IDs with a reason each, the new coverage number, the resolved mapping conflict, the override sites and the deferred snapshot refresh"
    requirement: "D-41"
    verification:
      - kind: other
        ref: "token loop over FULL-03, FULL-05, ADOPT-04, INV-04, 19, codebase => no MISSING RECORD; WR-02 and graphical-session.target present"
        status: pass
    human_judgment: false
  - id: D3
    description: "No home was invented for either genuinely open item, and the banned collective noun is absent"
    requirement: "CONTEXT.md 'Not in this phase', Phase 14 D-39"
    verification:
      - kind: other
        ref: "negated `(owner|owned by|assigned)[^.|]{0,40}(WR-02|graphical-session)` => no match; non-allowlisted chrome tokens = 0"
        status: pass
      - kind: other
        ref: "Python `re.findall` re-check of both patterns (ugrep vacuity guard): 0 and 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "Nothing outside the sweep record was modified by either task"
    requirement: "D-38, plan prohibition"
    verification:
      - kind: other
        ref: "`git diff --quiet HEAD -- arch/ docs/ scripts/ .config/ stow/ vendor/ .planning/REQUIREMENTS.md .planning/PROJECT.md .planning/ROADMAP.md .planning/STATE.md .planning/v0.3-MILESTONE-AUDIT.md` => 0, at both tasks"
        status: pass
    human_judgment: false
  - id: D5
    description: "The gate ran on a committed, clean tree"
    requirement: "D-40"
    verification:
      - kind: other
        ref: "`git status --porcelain` empty at 95b86fd before the first script started"
        status: pass
      - kind: integration
        ref: "phase14-verify.sh `[PASS] D-35 git status --porcelain is clean apart from paths under .planning/phases/14-live-full-adopt-verify/`"
        status: pass
    human_judgment: false
  - id: D6
    description: "The four tree-clean-agnostic suites are green and the wrapper drift baseline still holds"
    requirement: "D-40, D-38"
    verification:
      - kind: integration
        ref: "phase16-retire-assert / phase12-full-smoke / phase11-dispositions-assert => `=== done: FAIL=0 ===`; phase13-d19-assert => 0 [FAIL], `[PASS] arch/dots-hyprland.sh unmodified since 0771cc2`, `[PASS] W-3 … apply fence matches`"
        status: pass
    human_judgment: false
  - id: D7
    description: "The live suite is green with exactly one finding, and that finding is the known compositor-target loss"
    requirement: "D-40"
    verification:
      - kind: integration
        ref: "phase14-verify.sh => 0 [FAIL], 1 [FINDING], 33 [PASS], `=== done: FAIL=0 FINDINGS=1 ===`; the finding matches `^\\[FINDING\\].*D-38`"
        status: pass
    human_judgment: false
  - id: D8
    description: "The session still loads through the ii Lua entry and the retired session surfaces are still stopped, verified after the phase's changes"
    requirement: "ADOPT-02, ADOPT-03"
    verification:
      - kind: integration
        ref: "phase14-verify.sh at 95b86fd: configProvider is 'lua', hyprland.conf absent, `qs -c ii` running, waybar and swaync not running"
        status: pass
    human_judgment: false
  - id: D9
    description: "The live suite's summary line matches the expectation the playbook quotes"
    requirement: "D-40"
    verification:
      - kind: other
        ref: "observed `=== done: FAIL=0 FINDINGS=1 ===` found verbatim at docs/dots-hyprland-workflow.md:326; playbook not edited"
        status: pass
    human_judgment: false
  - id: D10
    description: "A fresh login confirms the desktop still comes up and behaves as it did before the phase, with the compositor-target autostart loss unchanged rather than newly worse"
    requirement: "ADOPT-02, ADOPT-03"
    verification:
      - kind: manual
        ref: "D-40 human re-login step — NOT PERFORMED. Recorded as outstanding in the sweep record's phase-gate section with the four checks the operator still owes."
        status: pending
    human_judgment: true
    rationale: "The executing agent cannot end the operator's session. The automated probes confirm a surviving session, not a session that can be restarted; only a real logout distinguishes the two."
  - id: D11
    description: "The six per-file correction tables faithfully describe what plans 16-07 through 16-09 actually did, rather than what they were planned to do"
    verification: []
    human_judgment: true
    rationale: "Each table row was sourced from the commit diff of the plan that made the change, not from the plan body, and the Correction column cites the plan and decision ID. Whether the summarised correction states the shipped edit rather than a plausible neighbour is a reading judgment against six commits."

# Metrics
duration: 17 min
completed: 2026-09-08
status: complete
---

# Phase 16 Plan 10: Sweep Record Completed and the D-40 Gate Run Summary

**The phase sweep record is now a complete account of the retirement — six per-file planning-artifact correction tables, the 22-to-19 coverage arithmetic with a reason per deleted requirement, the one resolved mapping conflict and the four frozen-artifact override sites — and it carries a verbatim D-40 gate transcript: six assert suites green on a committed clean tree, one known finding still emitted and still allowed, and the human re-login recorded as outstanding rather than claimed.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-09-08T09:53:00Z
- **Completed:** 2026-09-08T10:10:00Z
- **Tasks:** 2
- **Files modified:** 1 (1 created — this summary; 1 modified)

## Accomplishments

- **Six per-file correction tables, sourced from commits rather than plan bodies.** `.planning/REQUIREMENTS.md`, `.planning/v0.3-MILESTONE-AUDIT.md`, `.planning/PROJECT.md`, `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md`, `.planning/ROADMAP.md` and `.planning/STATE.md`, each in the record's existing four-column shape, each row quoting the stale text verbatim and citing the plan and decision ID that corrected it. Every quote was pulled from the diff of the commit that made the change, so the record states what those plans did rather than what they were planned to do — which matters, because three of them recorded documented deviations that changed the shape of the edit.
- **The annotate-rather-than-rewrite rule is recorded explicitly with its wording.** The two files swept under it are named as such, both fixed clause variants are quoted, the reason there are two rather than one is stated, and the annotated-line count is given per file — 23 in `PROJECT.md`, 8 in `STATE.md`, 1 each in `REQUIREMENTS.md` and `ROADMAP.md`. A future reader can grep `superseded by Phase 16` and find every site.
- **The coverage change is recorded with a reason per deleted ID.** `FULL-03` (the backup gate and the bare-flag refusal), `FULL-05` (the post-install package re-marking pass) and `ADOPT-04` (the three-tier rollback guidance) were deleted rather than rewritten because in each case the machinery the row described was removed and there was no surviving behavior to restate. This record is the only place in the planning tree those three identifiers are named — the requirement set's own orphan check bans them file-wide, so its coverage note describes the promises and points here.
- **The one documented rule conflict is recorded with its resolution and its consequence.** D-27 maps rewritten rows to Phase 16; D-26 keeps `INV-04` at Phase 10; the two disagree for exactly that one identifier and the specific rule governed. The record states why that is right on its own terms and not only by precedence: `scripts/phase10-inventory-assert.sh` is deliberately left requiring the retired language in the frozen Phase 10 record under D-39, and re-mapping the row would have created pressure to "fix" the assert and delete the only mechanical guarantee that the Phase 10 record still says what Phase 10 found.
- **The frozen-artifact override is bounded and named.** Exactly four sites: two rows in the Phase 11 disposition record, and the roadmap's milestone prose plus its coverage line. The record states that the Phase 10, 12, 13, 14 and 15 directories, the archived milestone trees and the pre-milestone research files all stayed frozen, and that the Phase 11 record's `accept-upstream` primary-entry row is byte-identical — which is what makes the override site-scoped rather than a licence to sweep the file.
- **The deferred section is extended and still has no invented homes.** A third row records that the six dated `.planning/codebase/` snapshots describe the wrapper as it was and are refreshed by a `/gsd-map-codebase` re-run rather than hand-edited, with all seventeen sites listed. `WR-02` and the D-38 compositor-target autostart bootstrap are unchanged, still open, still without a home.
- **The gate ran on a committed, clean tree and all six suites are green.** `git status --porcelain` was empty at `95b86fd` before the first script started. `phase16-retire-assert`, `phase12-full-smoke` and `phase11-dispositions-assert` each printed `=== done: FAIL=0 ===`; `phase13-d19-assert` printed `=== Phase 13 asserts: FAIL=0 ===` with zero `[FAIL]`, including `[PASS] arch/dots-hyprland.sh unmodified since 0771cc2` and the W-3 fence-drift check; `phase14-verify` printed `=== done: FAIL=0 FINDINGS=1 ===`.
- **The single finding is the known one, still emitted and still allowed.** `[FINDING] D-38 graphical-session.target is inactive …`. It was not silenced, not resolved, and no home was found for it.
- **The playbook cross-check is discharged with no follow-up owed.** The observed summary line is byte-identical to the expectation quoted at `docs/dots-hyprland-workflow.md:326`. The playbook was not edited during the gate.
- **A sixth script was run beyond D-40's five.** `scripts/phase10-inventory-assert.sh` — `=== done: FAIL=0 ===`, 29 `[PASS]` — because it is the assert the `INV-04` mapping resolution deliberately protects, and running it is what proves the resolution held.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fill the sweep record's planning-artifact section** — `95b86fd` (docs)
2. **Task 2: Run the phase gate on a committed clean tree and record the transcript** — `0d569eb` (docs)

## Files Created/Modified

- `.planning/phases/16-retire-the-safe-profile-full-only-wrapper-and-playbook/16-DOC-SWEEP.md` — `+233/−2` across the two commits. The `## Planning-artifact corrections` stub replaced by six per-file tables plus three cross-cutting subsections (the coverage change, the mapping-rule conflict, the frozen-artifact override); the `## Deferred fixes` table extended by one row; the `## Phase gate` stub replaced by the transcript.
- `.planning/phases/16-retire-the-safe-profile-full-only-wrapper-and-playbook/16-10-SUMMARY.md` — created.

No other file in the repository was modified by either task. The scope fence over `arch/ docs/ scripts/ .config/ stow/ vendor/ .planning/REQUIREMENTS.md .planning/PROJECT.md .planning/ROADMAP.md .planning/STATE.md .planning/v0.3-MILESTONE-AUDIT.md` exited 0 at both tasks.

## Decisions Made

- **The human re-login is outstanding, and the record says so.** See the deviation below. The plan's `<done>` clause asserts the operator has re-logged in and confirmed the session; the executing agent cannot end the operator's session, and marking that step done by proxy would put a false claim into the one artifact whose whole purpose is to be the evidence. The phase-gate section records what the operator still owes, as four lettered checks with a dated result row left blank.
- **`phase10-inventory-assert.sh` joined the gate run.** D-40 names five scripts. The sixth is the one plan `16-07` deliberately left in tension with its own rewrite, and the tension resolves only if it still passes.
- **`requirements mark-complete` was run and changed nothing.** `ADOPT-02` and `ADOPT-03` were already complete; `D-40`, `D-41` and `D-03` are `16-CONTEXT.md` decision identifiers, not requirement rows. The tool returned `updated: false` with `not_found: [D-40, D-41, D-03]`, and `.planning/REQUIREMENTS.md` is byte-identical — which is required, since that file was finalised in wave 5.
- **Two classes of stale quote were elided rather than reproduced.** Quoting is the point of this record, but three specific stale strings would have tripped the record's own gates: the old `ADOPT-03` text and the audit's `W-2` title carry the banned collective noun, and the old `STATE.md` next-step-2 text carries the assignment noun the gate bans within reach of `graphical-session`. Each is elided as `[…]` with the elision marked in place, so a reader knows a word was removed and why rather than reading a smoothed paraphrase as verbatim.

## Deviations from Plan

### Deviations recorded, not fixed

**1. The D-40 human step could not be performed by the executing agent**

- **Found during:** Task 2
- **Issue:** The plan's `<human-check>` requires logging out of the running Hyprland session and logging back in, and the task's `<done>` clause asserts that the operator has done so. Neither the executing agent nor the orchestrator can end the operator's session. Performing it is outside what a repository-scoped agent can do.
- **Action taken:** Recorded as `OUTSTANDING, not performed` in the sweep record's phase-gate section, with the four lettered checks the operator still owes and a result table row left at `outstanding`. The automated half of the same verification did run post-change and is quoted: `configProvider is 'lua'`, `hyprland.conf absent`, `qs -c ii` running, waybar and swaync not running. The record states plainly that this is a weaker statement than a fresh login, and why.
- **Files modified:** the sweep record only.
- **Committed in:** `0d569eb`
- **Impact:** The `must_haves` truth marked `verification: backstop` — "a real re-login into a fresh session confirms the desktop still comes up" — is the one truth in this plan that is not yet discharged. Everything else in the gate is.

### Auto-fixed Issues

**2. [Rule 3 - Blocking] Two verbatim quotes tripped the record's own forbidden-token gates**

- **Found during:** Task 1
- **Issue:** The task instruction is to quote stale text verbatim in backticks; the task's third verify bans non-allowlisted occurrences of the collective noun file-wide, and bans the assignment noun within 40 characters of `WR-02` or `graphical-session`. Three of the stale strings that most needed recording contain exactly those tokens: the pre-sweep `ADOPT-03` requirement row, the milestone audit's `W-2` warning title, and `STATE.md`'s pre-sweep operator next-step 2. Quoting them verbatim turns the gate red; omitting them leaves the record silent about three real corrections.
- **Fix:** Elided the offending word in each quote as `[…]` and appended an in-cell note naming what was elided and why — "the elided word is the banned collective noun", and for the third "the elided word is the assignment noun this record's own gate bans within reach of that identifier, which is the same reason the state file could not keep it". A preamble above the tables states the elision convention once, so no reader mistakes an elided quote for a complete one.
- **Files modified:** the sweep record only.
- **Verification:** the collective-noun count is 0 and the assignment-noun pattern returns no match, under both ugrep and a Python `re` re-check.
- **Committed in:** `95b86fd`

**3. [Rule 3 - Blocking] A prose sentence about the gate itself carried the banned token**

- **Found during:** Task 1
- **Issue:** The `PROJECT.md:43` correction row explains why plan `16-08` annotated that line instead of rewriting it — the plan's own gate pins the file's non-allowlisted occurrences of the collective noun at exactly 3, and rewriting the line would have dropped one. Stating that required naming the token, which trips the same ban in this file.
- **Fix:** Reworded to "one of the three occurrences of the banned collective noun that the previous phase deliberately froze in that file". The explanation is unchanged; only the token form is.
- **Files modified:** the sweep record only.
- **Verification:** file-wide count is 0.
- **Committed in:** `95b86fd`

---

**Total deviations:** 1 recorded and handed to the operator, 2 auto-fixed (both Rule 3 blocking).
**Impact on scope:** None. Every change stayed inside `16-DOC-SWEEP.md`. Both auto-fixes exist for the same structural reason as the deviations in plans `16-07` through `16-09`: the gates are file-wide while the instructions are site-scoped, and a document whose job is to quote stale strings is the hardest case for a forbidden-string gate.

## Issues Encountered

- **The ugrep vacuity hazard did not fire, and was checked for anyway.** Both of this plan's negated patterns — the assignment-noun ban and the collective-noun count — executed cleanly under this machine's `grep`. Because a complexity-limit error on a negated pattern makes the check pass without testing anything, both were independently re-run through Python `re.findall`. Both returned zero matches, matching the shell result. Recorded because the run's tooling note flags this specifically, and a "pass" from a negated ugrep is worth nothing without the cross-check.
- **`phase11-dispositions-assert.sh`'s last output line is not its summary line.** It prints `=== done: FAIL=0 ===` and then `phase11 dispositions asserts OK`. A gate check written as `tail -1 | grep FAIL=0` would report a false failure; the plan's verify greps the whole transcript, which is correct. The same shape applies to `phase10-inventory-assert.sh`. Both summary lines are quoted in full in the transcript.
- **The plan's `<precondition>` about the summary-in-progress being committed is not satisfiable as literally written.** It requires this summary to be committed before the gate runs, but the gate transcript is content this summary reports on and the phase-gate section is written from the gate's output. The plan's own verify ordering resolves it — clean tree, then run, then record — and that is the order followed. The tree was clean at `95b86fd` when the live suite ran.

## Verification

| Suite | Result |
|-------|--------|
| `./scripts/phase10-inventory-assert.sh` | `=== done: FAIL=0 ===` (29 `[PASS]`) |
| `./scripts/phase11-dispositions-assert.sh` | `=== done: FAIL=0 ===` (38 `[PASS]`) |
| `./scripts/phase12-full-smoke.sh` | `=== done: FAIL=0 ===` (16 `[PASS]`) |
| `./scripts/phase13-d19-assert.sh` | `=== Phase 13 asserts: FAIL=0 ===` (16 `[PASS]`, 0 `[FAIL]`; drift pin `0771cc2` and the W-3 fence both hold) |
| `./scripts/phase14-verify.sh` | `=== done: FAIL=0 FINDINGS=1 ===` (33 `[PASS]`, 0 `[FAIL]`, 1 `[FINDING]` — the known D-38 loss) |
| `./scripts/phase16-retire-assert.sh` | `=== done: FAIL=0 ===` (23 `[PASS]`) |

Task-level verifies: all four of Task 1's blocks and all five of Task 2's automated blocks exited 0. Task 2's `<human-check>` is **pending** — see the deviation above.

**Negated-regex cross-checks.** Task 1's third verify is the only block in this plan built on negated patterns. It was re-run in Python:

- `(?i)(owner|owned by|assigned)[^.|]{0,40}(WR-02|graphical-session)` → 0 hits
- `[A-Za-z0-9_-]*[Cc]hrome[A-Za-z0-9_-]*` minus the `google-chrome-stable` allowlist entry → 0 tokens

Both match the shell result, so neither passed vacuously. No other verify in this plan uses a negated complex alternation.

**Scope fences.** `git diff --quiet HEAD -- arch/ docs/ scripts/ .config/ stow/ vendor/ .planning/REQUIREMENTS.md .planning/PROJECT.md .planning/ROADMAP.md .planning/STATE.md .planning/v0.3-MILESTONE-AUDIT.md` exited 0 at both tasks. `arch/dots-hyprland.sh` is untouched, as the drift pin requires, and `16-DOC-SWEEP.md` is at its original path, as the baseline's marker tier requires.

## Known Stubs

None. `16-DOC-SWEEP.md`'s two stubbed sections are both filled; the file has no remaining placeholder.

One item is **pending, not stubbed**: the D-40 human re-login, recorded in the phase-gate section with an explicit `outstanding` result row. It is tracked as pending coverage item D10 above.

## Threat Flags

None. The only file changed is planning prose. No credential, endpoint, schema or auth path is introduced or changed, and the five gate scripts are read-only against the session — none of them installs, uninstalls, or runs a package operation.

The plan's threat register is discharged as follows. **T-16-63** (paraphrased transcript): every summary line is quoted verbatim from a captured transcript, and the record carries nine `FAIL=0` lines against a floor of four. **T-16-64** (dirty-tree gate): `git status --porcelain` was empty before the first script, and the live suite's own `D-35` assertion confirms it independently. **T-16-65** (a surviving session mistaken for a working one): explicitly *not* discharged — recorded as outstanding rather than assumed, which is what this threat exists to prevent. **T-16-66** (known finding silenced): the finding count is exactly 1 and the finding matches the known loss. **T-16-67** (inline fixes during the gate): no file other than the sweep record was modified; no defect was found, so nothing needed handing over. **T-16-68** (playbook expectation drift): the observed line is byte-identical to the quoted expectation. **T-16-69** and **T-16-SC** were accepted at planning time and nothing here changes that.

## User Setup Required

**One outstanding operator action — the D-40 human re-login.**

Log out of the current Hyprland session completely, or reboot, then log back in and confirm:

1. The desktop comes up and the ii shell is running — the bar, the launcher and the notification surface all appear.
2. `hyprctl -j status | jq -r .configProvider` prints `lua`.
3. `./scripts/phase14-verify.sh` prints `=== done: FAIL=0 FINDINGS=1 ===`.
4. Nothing that worked before the phase has stopped working, beyond the compositor-target autostart loss already recorded as a known, unowned loss.

Record the date and result in the table at the end of `16-DOC-SWEEP.md`'s `## Phase gate` section. If step 4 surfaces something new, record it as a finding and name the plan that owns the file — do not fix it inside the gate record.

## Next Phase Readiness

- **Phase 16 is complete.** All ten plans executed; the sweep record is finished; the gate is green on a clean tree.
- **Outstanding before the milestone closes:** the D-40 re-login above. It is the only unmet `must_haves` truth in this plan, and it is a backstop-verified one.
- **Still open by design, still without a home:** `WR-02` (the roles of the repository copy of the pre-adopt compositor config) and the D-38 `graphical-session.target` autostart bootstrap. `scripts/phase14-verify.sh` keeps emitting the latter as an allowed `[FINDING]`.
- **Queued, not a blocker:** a `/gsd-map-codebase` re-run. Six of the seven `.planning/codebase/` snapshots are stamped `2026-08-21` and describe the retired wrapper; two cite scripts this phase deleted. The seventeen affected sites are listed in the sweep record's deferred table.
- **No blockers.**

---
*Phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook*
*Completed: 2026-09-08*

## Self-Check: PASSED

Files claimed, verified present on disk: `16-DOC-SWEEP.md`, `16-10-SUMMARY.md`.
Commits claimed, verified in `git log`: `95b86fd`, `0d569eb`, `9ad36b9`.
All six assert suites re-run on the committed tree at `9ad36b9`: five at `FAIL=0`, `phase14-verify.sh` at `FAIL=0 FINDINGS=1`.
`git status --porcelain` is empty.
