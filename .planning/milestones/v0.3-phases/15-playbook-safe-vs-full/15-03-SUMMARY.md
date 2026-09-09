---
phase: 15-playbook-safe-vs-full
plan: 03
subsystem: docs
tags: [runbook, rollback, backup, sha256, hyprland, recovery]

# Dependency graph
requires:
  - phase: 14-live-full-adopt-verify
    provides: "14-PRE-ADOPT-BASELINE.txt (hyprland_conf_sha256=3d17932a…), 14-LIVE-VERIFY.md post-adopt state, scripts/phase14-verify.sh BACKUP_DIR + D-36 assertion"
  - phase: 15-playbook-safe-vs-full
    provides: "15-01's `verified` gate answer (write machine-checked ground truth over the literal text of D-08/D-14/D-15) and its partial rewrite of tier-1 source 3"
provides:
  - "Rollback tier-1 source 3 names ~/ii-original-dots-backup/ and explicitly disqualifies ~/ii-original-dots-backup.<UTC timestamp>/ as a rollback source"
  - "A runnable, key-anchored sha256 command that decides which of the two backup directories holds the pre-adopt conf, by content rather than by name"
  - "Section 5 scoped to pre-adopt with a bold post-adopt caveat prohibiting --rotate-backup and recording IN-11 as a deferred script fix (D-19)"
  - "Sections 3 and 7 tense-scoped so no runbook line reads as a post-adopt instruction"
affects: [15-04, 15-05, 15-06]

actuals:
  tokens: 6008
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Correction-only doc edit: heading count pinned, headings asserted verbatim, only false clauses moved (D-02 + D-21)"
    - "Identify a recovery source by content digest against a recorded fixture, never by directory name or mtime"

key-files:
  created: []
  modified:
    - docs/phase14-adopt-runbook.md

key-decisions:
  - "Tier-1 source 3's discrimination command is key-anchored (grep -qxF 'hyprland_conf_sha256=<digest>'), not a loose hash grep — the same fixture also records the stale directory's digest as backup_dir_hyprland_conf_sha256, so an unanchored grep reports MATCH for both directories"
  - "The rotated directory is named literally as ~/ii-original-dots-backup.<UTC timestamp>/ rather than described by position, so an operator mid-failure cannot resolve it to the wrong path"
  - "Section 5 was scoped, not deleted: it remains the correct record of what the adopt window did (D-02), with the post-adopt prohibition added immediately after the mandatory sentence"
  - "scripts/phase14-preflight.sh:264 left unedited; its stale --rotate-backup remediation is recorded in the runbook prose as IN-11 (D-19)"
  - "REQUIREMENTS.md not touched: DOC-03 is declared by all six plans in this phase, so the shared-ID gate blocks marking it complete until 15-06 finishes"

patterns-established:
  - "Post-adopt caveat shape: bold parenthetical immediately after the pre-adopt instruction it qualifies, naming the flag, the script path and the deferred-fix ID"
  - "Every documented discrimination command is executed against both the true and the decoy input before it ships"

requirements-completed: [DOC-03]

coverage:
  - id: D1
    description: "Rollback tier-1 source 3 points at the backup whose hyprland.conf matches the recorded pre-adopt fixture, names the rotated directory as a non-source, and carries a runnable cp -a restore line"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "grep -q '3d17932a' && grep -q '14-PRE-ADOPT-BASELINE.txt' && grep -q 'ii-original-dots-backup/' && test $(grep -c 'cp -a') -ge 3 (15-03 Task 1 verify 1+2)"
        status: pass
      - kind: other
        ref: "live probe: documented grep -qxF \"hyprland_conf_sha256=$(sha256sum <dir>/.config/hypr/hyprland.conf | cut -d' ' -f1)\" run against ~/ii-original-dots-backup (MATCH) and ~/ii-original-dots-backup.20260904T171128Z (STALE)"
        status: pass
    human_judgment: false
  - id: D2
    description: "No runbook line still reads as a post-adopt instruction: section 5's 'as it does today', section 3's 'is older than the live one' and section 7's 'currently has none' are all tense-scoped, with the section 5 caveat naming --rotate-backup, IN-11 and scripts/phase14-preflight.sh"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "! grep -qF 'which is whenever the directory exists, as it does today' && ! grep -qF 'inside it is older than the live one' && ! grep -qF 'only because live currently has none' && grep -q 'IN-11' (15-03 Task 1 verify 1, Task 2 verify 1)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The runbook's structure, section list and role as the record of the 2026-09-04 adopt window are unchanged, and scripts/phase14-preflight.sh is untouched"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "test $(grep -c '^## ') -eq 17 && both edited headings grep -qF verbatim && git diff --name-only $B..HEAD -- scripts/phase14-preflight.sh is empty && ./scripts/phase13-d19-assert.sh -> 15 [PASS] / 0 [FAIL]"
        status: pass
    human_judgment: false
  - id: D4
    description: "The corrected recovery procedure is followable by an operator mid-failure at a bare TTY under time pressure"
    requirement: DOC-03
    verification: []
    human_judgment: true
    rationale: "Whether a recovery instruction reads unambiguously under stress is a human call; greps prove the strings are present and correct, not that the prose lands. Best read at the 15-06 phase gate alongside the rest of the doc chain."

# Metrics
duration: 5min
completed: 2026-09-06
status: complete
---

# Phase 15 Plan 03: Runbook correction sweep Summary

**Rollback tier 1 now names `~/ii-original-dots-backup/` with a key-anchored sha256 check that distinguishes it from the rotated July backup, and the runbook's three remaining pre-adopt-tense claims are scoped so no section reads as a post-adopt instruction.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-06T06:04:30Z
- **Completed:** 2026-09-06T06:09:20Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- **The highest-severity finding in the phase is closed.** Section 14 tier-1 source 3 now names `~/ii-original-dots-backup.<UTC timestamp>/` literally as the rotated stale backup and states it is not a rollback source, instead of describing it only by position. 15-01 had already inverted the recommendation back to the correct directory; this plan supplies what it did not: the discrimination method and the explicit disqualification of the decoy path.
- **The operator no longer has to trust a directory name.** The comment carries one runnable command that hashes the candidate's `.config/hypr/hyprland.conf` and compares it, key-anchored, against `hyprland_conf_sha256` in `.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt`, printing `MATCH` or `STALE`. It was executed against both directories before shipping: `~/ii-original-dots-backup` → `MATCH`, `~/ii-original-dots-backup.20260904T171128Z` → `STALE`.
- **Section 5 can no longer be read as a live instruction.** Its pre-adopt qualifier is scoped, and a bold post-adopt caveat immediately after the mandatory sentence prohibits `./scripts/phase14-preflight.sh --rotate-backup`, explains that running it would rename away tier-1 source 3, and records the script's own stale remediation message as **IN-11**, deliberately unedited by a documentation phase (D-19).
- **Sections 3 and 7 agree with the post-adopt machine.** The go/no-go backup clause is scoped to "at the time this window was prepared" and carries a bracketed post-adopt note cross-linking the section 5 caveat and section 14; the `custom/` seeding bullet no longer says live "currently" has none, while the section 8 sentence is preserved verbatim.
- **The record was corrected, not rewritten.** 17 `## ` headings before and after, both edited headings byte-identical, nothing moved out of the runbook, `scripts/phase14-preflight.sh` untouched across the whole phase range.

## Task Commits

Each task was committed atomically:

1. **Task 1: Correct rollback tier-1 source 3 and add the post-adopt caveat to the rotate-backup section** — `ef0e5b1` (docs)
2. **Task 2: Correct the two remaining pre-adopt-tense claims in sections 3 and 8** — `fc45675` (docs)

## Files Created/Modified

- `docs/phase14-adopt-runbook.md` — four corrected sites: section 14 tier-1 source 3 comment (+ its existing `cp -a` line kept, not duplicated), section 5's mandatory sentence + new bold post-adopt caveat, section 3's backup no-go clause + bracketed post-adopt note, section 7's `custom/` seeding bullet. 19 insertions, 5 deletions across both commits.

## Decisions Made

- **Key-anchored comparison, not a bare hash grep.** The obvious one-liner (`grep -qF "<digest>" 14-PRE-ADOPT-BASELINE.txt`) is wrong: the fixture also records the stale directory's digest on its own line as `backup_dir_hyprland_conf_sha256=c5c65023…`, so it returns `MATCH` for both directories. The shipped command uses `grep -qxF "hyprland_conf_sha256=<digest>"`, and the comment records *why* the `-x` and the key prefix must stay, so a later editor cannot "simplify" it back into a check that always says yes.
- **The rotated directory is named as a literal path.** `~/ii-original-dots-backup.<UTC timestamp>/` rather than "the timestamped directory section 5 rotated aside" — a reader in a broken session resolves a path faster and more reliably than a back-reference to another section.
- **Anchor links, not plain prose cross-references.** Section 5's caveat links `[section 14](#14-rollback-adopt-04-d-23-d-24)` and section 3's note links both `section 14` and `[section 5](#5-rotate-the-stale-backup-d-27)`. Both slugs already existed in the runbook Outline, so no new anchor surface was created, and the Task 2 anchor-resolution loop passes.
- **Section 5 scoped, not deleted.** D-02 preserves structure and the section is the correct record of what the adopt window did; the correction is a caveat placed where the stale instruction is read, not a removal.
- **REQUIREMENTS.md not touched.** DOC-03 is declared by all six plans in this phase (`15-01` … `15-06`), so the shared-ID gate blocks marking it complete until the last declaring plan produces a SUMMARY. `15-06` will close it.
- **STATE.md / ROADMAP.md not touched.** This plan's own scope-fence verifies fail on any diff in either file; the orchestrator owns wave tracking.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The first draft of the sha256 discrimination command matched both backup directories**

- **Found during:** Task 1 (before the task commit)
- **Issue:** The command as first written — `grep -qF "$(sha256sum …| cut -d' ' -f1)" 14-PRE-ADOPT-BASELINE.txt && echo MATCH || echo STALE` — printed `MATCH` for `~/ii-original-dots-backup.20260904T171128Z` as well as for `~/ii-original-dots-backup`. The fixture records the stale directory's own digest as `backup_dir_hyprland_conf_sha256=c5c65023…`, so an unanchored substring grep finds a hit for either input. Shipping it would have handed a recovering operator a check that always says yes — the exact failure mode this correction exists to prevent, wearing the costume of a fix.
- **Fix:** Changed to `grep -qxF "hyprland_conf_sha256=$(sha256sum …| cut -d' ' -f1)"` — whole-line match, keyed to the pre-adopt fixture line. Added four comment lines recording why the `-x` and the key prefix must not be dropped.
- **Files modified:** `docs/phase14-adopt-runbook.md`
- **Verification:** Executed against both directories: `~/ii-original-dots-backup` → `MATCH`, `~/ii-original-dots-backup.20260904T171128Z` → `STALE`. Both are read-only `sha256sum` + `grep`; nothing was mutated.
- **Committed in:** `ef0e5b1` (Task 1 commit — caught and fixed before the commit, so the defective form was never committed)

**2. [Rule 2 - Missing Critical] Multi-line continuation form replaced with a single copy-pasteable line**

- **Found during:** Task 1
- **Issue:** The discrimination command was first written across five `#`-prefixed continuation lines. Inside a `#` comment a trailing `\` does not continue anything, so an operator would have had to strip five comment prefixes correctly, at a bare TTY, mid-failure, to run it.
- **Fix:** Collapsed to one line with the explanation moved into surrounding prose comments.
- **Files modified:** `docs/phase14-adopt-runbook.md`
- **Verification:** The single-line form was the one executed against both directories above.
- **Committed in:** `ef0e5b1` (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical). Both were self-inflicted defects in this plan's own new content, caught by executing the documented command rather than by inspecting it, and both were fixed before the task commit.
**Impact on plan:** None on scope. Both fixes are inside the site the plan authorises editing, and both serve the plan's stated purpose (an operator can tell the two directories apart by content). No scope creep; no other file touched.

## Issues Encountered

- **15-01 had partially applied this plan's Task 1 item 1.** Tier-1 source 3 already recommended `~/ii-original-dots-backup/` and already carried a `cp -a` line. Handled as instructed: extended rather than undone, and the `cp -a` was not duplicated (file count stays at exactly 3, satisfying `>= 3`).
- **The plan's objective says "This plan runs in parallel with `15-02`".** Stale — 15-02 merged at `5c1ad75` before this run. Executed sequentially on `main` as a single writer; `docs/dots-hyprland-workflow.md` was not read or edited, and nothing written here contradicts its new `## Profiles: safe vs full` / `## 3. Required gate before any full install` sections or the safe-by-default framing (D-07).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Ready for `15-04`. Facts downstream plans should treat as given:

- **The runbook is now internally consistent on the backup question.** `15-05` writes the same rotation prohibition into `docs/dots-hyprland-workflow.md` §9 and must not contradict what section 5 now says: rotation is a **pre-adopt** step; post-adopt `~/ii-original-dots-backup` *is* tier-1 source 3 and `--rotate-backup` must not be run.
- **IN-11's wording precedent is set here** and `15-05`'s verify greps for the same three tokens (`--rotate-backup`, `IN-11`, `scripts/phase14-preflight.sh`). Reuse the phrasing: stale remediation message, tracked as IN-11, deliberately unedited because a documentation phase does not edit the script it documents (D-19). `15-06` records the deferred fix with an owner.
- **The discrimination command is reusable, but only in its anchored form.** If `15-05` restates the sha256 identity argument, do not reduce it to a bare hash grep — `14-PRE-ADOPT-BASELINE.txt` carries `backup_dir_hyprland_conf_sha256=c5c65023…` on a separate line and an unanchored grep matches both directories.
- **The runbook heading contract is pinned at 17 `## ` headings** with `## 5. Rotate the stale backup (D-27)` and `## 14. Rollback (ADOPT-04, D-23, D-24)` verbatim. `15-06`'s phase gate should keep asserting it.
- **`scripts/phase14-preflight.sh` remains frozen and unmodified across the entire phase range** (`git diff --name-only f54714b..HEAD -- scripts/phase14-preflight.sh` is empty). `scripts/phase13-d19-assert.sh` still reports 15 `[PASS]` / 0 `[FAIL]`.
- **DOC-03 is still open in REQUIREMENTS.md by design** — all six plans declare it, so it marks complete only after `15-06`.
- **`./scripts/phase14-verify.sh` was not run** (it asserts a clean working tree, D-35). It belongs to the `15-06` phase gate, as the plan specifies.

---
*Phase: 15-playbook-safe-vs-full*
*Completed: 2026-09-06*

## Self-Check: PASSED

- `docs/phase14-adopt-runbook.md` — FOUND on disk.
- `.planning/phases/15-playbook-safe-vs-full/15-03-SUMMARY.md` — FOUND on disk.
- Commit `ef0e5b1` — FOUND in `git log --oneline --all`.
- Commit `fc45675` — FOUND in `git log --oneline --all`.
- All 7 Task 1 acceptance criteria and all 7 Task 2 acceptance criteria re-run and PASS.
- All 6 `<automated>` verify blocks (3 per task) re-run and exit 0.
- `./scripts/phase13-d19-assert.sh` — exit 0, 15 `[PASS]`, 0 `[FAIL]`.
- Working tree clean apart from this SUMMARY; only `docs/phase14-adopt-runbook.md` changed by this plan; `.planning/STATE.md` and `.planning/ROADMAP.md` untouched.
