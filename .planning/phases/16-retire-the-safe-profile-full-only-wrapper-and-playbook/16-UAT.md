---
status: complete
phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook
source: 16-01-SUMMARY.md, 16-02-SUMMARY.md, 16-03-SUMMARY.md, 16-04-SUMMARY.md, 16-05-SUMMARY.md, 16-06-SUMMARY.md, 16-07-SUMMARY.md, 16-08-SUMMARY.md, 16-09-SUMMARY.md, 16-10-SUMMARY.md
started: 2026-09-08T14:32:07Z
updated: 2026-09-08T15:10:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Live uninstall path still gates and honours surviving flags
expected: The real (mutating) uninstall path still gates, removes ii meta packages without a cascade, removes ii configs/state, and honours its four surviving flags
result: pass
coverage_id: 16-01/D8
rationale: Only the `--dry-run` path is executable under this plan's non-mutating prohibition. The real path's `read -r -p "Type 'yes' …"` gate, the `sudo pacman -R` removal and the `safe_rm_path` sweep were reviewed by reading, not by running. Proving them requires a live uninstall on the operator's machine, which this phase explicitly forbids.

### 2. Wrapper is final for Phase 16
expected: arch/dots-hyprland.sh is final for Phase 16, which is the precondition for the wave-4 drift re-pin
result: pass
source: automated
evidence: "phase13-d19-assert.sh green with WRAPPER_BASE=0771cc2; git log 7334498..HEAD -- arch/dots-hyprland.sh ends at 0771cc2 (16-02); no later plan touched the wrapper"
coverage_id: 16-02/D6
rationale: This is a claim about what later plans will NOT do. No assert available at this point can prove it; the real proof is scripts/phase13-d19-assert.sh returning green after plan 16-06 re-pins its baseline to 0771cc2. Files-modified frontmatter across 16-03..16-10 was checked and none names arch/dots-hyprland.sh, but that is evidence, not proof.

### 3. Playbook reads as one install path with no profile choice
expected: A cold operator reading the playbook end to end sees one install path and no profile choice
result: pass
source: automated
evidence: "Playbook read end to end. One install path in §4. Retired-vocabulary grep returns one hit (line 151), the sentence stating there is no profile to choose."
coverage_id: 16-04/D11
rationale: Absence-greps prove the retired tokens are gone; they cannot prove the surviving prose reads coherently to someone installing on a cold machine for the first time. The one surviving occurrence of the word 'profile' is the sentence stating there is no profile to choose, which is a judgment call about clarity, not a token check.

### 4. Sweep record tables match what 16-01 through 16-05 shipped
expected: The sweep record's per-file correction tables faithfully consolidate what plans 16-01..16-05 actually did, rather than what they were planned to do
result: issue
source: automated
reported: "Sweep record states phase07-live-smoke.sh deleted at 451 lines and phase14-preflight.sh at 327; commit 769bf9e deleted 456 and 322 respectively. Numbers transposed. Origin is 16-03-SUMMARY.md:172-173."
severity: minor
coverage_id: 16-06/D8
rationale: Fidelity of a prose record to five prior plans is a reading judgment, not a machine-checkable property. The stale strings were re-extracted from `git diff 7334498..HEAD` rather than transcribed from the plans, and the corrections cite the plan that made each one, but only a human comparing the record against the diffs can confirm nothing material was omitted or misattributed.

### 5. Requirement rows and audit evidence match what 16-01 through 16-06 shipped
expected: The rewritten requirement rows and the audit's refreshed evidence faithfully describe what plans 16-01 through 16-06 actually shipped
result: pass
source: automated
evidence: "FULL-01/02/04, ADOPT-03, DOC-03 mapped Phase 16; INV-04 held at Phase 10; DISP-03 at Phase 11; FULL-03/FULL-05/ADOPT-04 grep count 0; coverage 19/19/0 and roadmap 19/19."
coverage_id: 16-07/D10
rationale: Whether a rewritten requirement row states the shipped behavior — rather than a plausible-sounding neighbour of it — is a reading judgment against six prior plans. The evidence was re-captured from the current wrapper's dry-run output and each resolution cites the plan that produced it, but only a human comparing the rows against the diffs can confirm nothing was overstated.

### 6. Fresh login desktop is unchanged (compositor-target loss not worse)
expected: A fresh login confirms the desktop still comes up and behaves as it did before the phase, with the compositor-target autostart loss unchanged rather than newly worse
result: pass
coverage_id: 16-10/D10
rationale: The executing agent cannot end the operator's session. The automated probes confirm a surviving session, not a session that can be restarted; only a real logout distinguishes the two.

### 7. Sweep record tables match what 16-07 through 16-09 shipped
expected: The six per-file correction tables faithfully describe what plans 16-07 through 16-09 actually did, rather than what they were planned to do
result: pass
source: automated
evidence: "All six diffstats match the commits exactly: +24/-24, +199/-88, +33/-33, +4/-4, +6/-6, +18/-17. Annotation counts 23/8/1/1 match."
coverage_id: 16-10/D11
rationale: Each table row was sourced from the commit diff of the plan that made the change, not from the plan body, and the Correction column cites the plan and decision ID. Whether the summarised correction states the shipped edit rather than a plausible neighbour is a reading judgment against six commits.

### 8. A bare `install` / `install-files` invocation carries none of the three retired residual flags — full is what an operator gets without asking for it
expected: A bare `install` / `install-files` invocation carries none of the three retired residual flags — full is what an operator gets without asking for it
result: pass
source: automated
coverage_id: 16-01/D1

### 9. `--full` is accepted on every install-family subcommand, prints a `[CONFIG]` note saying it is ignored, and never reaches the would-exec line
expected: `--full` is accepted on every install-family subcommand, prints a `[CONFIG]` note saying it is ignored, and never reaches the would-exec line
result: pass
source: automated
coverage_id: 16-01/D2

### 10. `install` and `install-files` forward the upstream skip-backup flag; `install-deps` and `install-setups` do not
expected: `install` and `install-files` forward the upstream skip-backup flag; `install-deps` and `install-setups` do not
result: pass
source: automated
coverage_id: 16-01/D3

### 11. No wrapper-owned prompt stands between an `install` invocation and upstream `./setup` — the exact-token gate line is gone from every install path
expected: No wrapper-owned prompt stands between an `install` invocation and upstream `./setup` — the exact-token gate line is gone from every install path
result: pass
source: automated
coverage_id: 16-01/D4

### 12. A new executable contract exists at `scripts/phase16-retire-assert.sh` and exits 0 against the rewritten wrapper
expected: A new executable contract exists at `scripts/phase16-retire-assert.sh` and exits 0 against the rewritten wrapper
result: pass
source: automated
coverage_id: 16-01/D5

### 13. The retired `protect` subcommand is refused by the allowlist rather than by a missing function
expected: The retired `protect` subcommand is refused by the allowlist rather than by a missing function
result: pass
source: automated
coverage_id: 16-01/D6

### 14. `bash -n` is clean and the surviving uninstall machinery still resolves every helper it calls, so nothing aborts under `set -euo pipefail`
expected: `bash -n` is clean and the surviving uninstall machinery still resolves every helper it calls, so nothing aborts under `set -euo pipefail`
result: pass
source: automated
coverage_id: 16-01/D7

### 15. usage() documents only the surviving surface: five allowlisted subcommands plus help, two wrapper-owned meta flags, four uninstall flags and the guarded --upstream-dangerous hatch
expected: usage() documents only the surviving surface: five allowlisted subcommands plus help, two wrapper-owned meta flags, four uninstall flags and the guarded --upstream-dangerous hatch
result: pass
source: automated
coverage_id: 16-02/D1

### 16. The help text states plainly that the wrapper no longer prompts but upstream still greets and pauses, and never claims the install is unattended
expected: The help text states plainly that the wrapper no longer prompts but upstream still greets and pauses, and never claims the install is unattended
result: pass
source: automated
coverage_id: 16-02/D2

### 17. scripts/phase12-full-smoke.sh asserts the full-only contract and is green — the D-34 window opened by 16-01 is closed
expected: scripts/phase12-full-smoke.sh asserts the full-only contract and is green — the D-34 window opened by 16-01 is closed
result: pass
source: automated
coverage_id: 16-02/D3

### 18. The retired subcommand is refused by the ALLOWLIST array, proving the array edit rather than the function deletion
expected: The retired subcommand is refused by the ALLOWLIST array, proving the array edit rather than the function deletion
result: pass
source: automated
coverage_id: 16-02/D4

### 19. The 16-01 retirement contract is unregressed by both edits
expected: The 16-01 retirement contract is unregressed by both edits
result: pass
source: automated
coverage_id: 16-02/D5

### 20. The live verification suite runs against the stripped wrapper without invoking a subcommand or flag that no longer exists, and is green apart from the expected dirty-tree failure
expected: The live verification suite runs against the stripped wrapper without invoking a subcommand or flag that no longer exists, and is green apart from the expected dirty-tree failure
result: pass
source: automated
coverage_id: 16-03/D1

### 21. The live-session assertions on the D-37 keep list are untouched: the compositor is on the Lua entry, and Waybar, rofi and swaync are still stopped
expected: The live-session assertions on the D-37 keep list are untouched: the compositor is on the Lua entry, and Waybar, rofi and swaync are still stopped
result: pass
source: automated
coverage_id: 16-03/D2

### 22. The surviving removal path is still exercised — `uninstall --dry-run` exits 0 — under a label that no longer promises a deleted rollback tier
expected: The surviving removal path is still exercised — `uninstall --dry-run` exits 0 — under a label that no longer promises a deleted rollback tier
result: pass
source: automated
coverage_id: 16-03/D3

### 23. Nothing in the repo asserts the integrity of a backup no future install will produce, and the two on-disk snapshots are untouched
expected: Nothing in the repo asserts the integrity of a backup no future install will produce, and the two on-disk snapshots are untouched
result: pass
source: automated
coverage_id: 16-03/D4

### 24. `scripts/phase07-live-smoke.sh` and `scripts/phase14-preflight.sh` no longer exist, and nothing outside `.planning/` and `docs/` invokes them
expected: `scripts/phase07-live-smoke.sh` and `scripts/phase14-preflight.sh` no longer exist, and nothing outside `.planning/` and `docs/` invokes them
result: pass
source: automated
coverage_id: 16-03/D5

### 25. IN-11 is closed by deletion: no script in the repo prints backup rotation as a mandatory step before an adopt that already happened
expected: IN-11 is closed by deletion: no script in the repo prints backup rotation as a mandatory step before an adopt that already happened
result: pass
source: automated
coverage_id: 16-03/D6

### 26. The three tree-clean-agnostic regression suites stayed green across both task commits
expected: The three tree-clean-agnostic regression suites stayed green across both task commits
result: pass
source: automated
coverage_id: 16-03/D7

### 27. The summary line the playbook quotes keeps its documented shape, so plan 16-04 can paste a real tail rather than carry a number forward on trust
expected: The summary line the playbook quotes keeps its documented shape, so plan 16-04 can paste a real tail rather than carry a number forward on trust
result: pass
source: automated
coverage_id: 16-03/D8

### 28. Every install example in the playbook is a bare command and the retired vocabulary is absent file-wide — an operator who pastes one gets the full behavior, which is the only behavior
expected: Every install example in the playbook is a bare command and the retired vocabulary is absent file-wide — an operator who pastes one gets the full behavior, which is the only behavior
result: pass
source: automated
coverage_id: 16-04/D1

### 29. The playbook quotes wrapper output the wrapper actually prints today, re-captured from the binary 16-02 finalised
expected: The playbook quotes wrapper output the wrapper actually prints today, re-captured from the binary 16-02 finalised
result: pass
source: automated
coverage_id: 16-04/D2

### 30. The playbook tells the truth about interactivity: the wrapper no longer prompts, upstream still greets and pauses
expected: The playbook tells the truth about interactivity: the wrapper no longer prompts, upstream still greets and pauses
result: pass
source: automated
coverage_id: 16-04/D3

### 31. ii owns the session hooks in its own Lua tree; the wrapper does not touch them, and the repo copy's two lines are dead archive
expected: ii owns the session hooks in its own Lua tree; the wrapper does not touch them, and the repo copy's two lines are dead archive
result: pass
source: automated
coverage_id: 16-04/D4

### 32. No rollback tier list and no pointer to one survives; recovery is a clean reinstall from the pinned submodule
expected: No rollback tier list and no pointer to one survives; recovery is a clean reinstall from the pinned submodule
result: pass
source: automated
coverage_id: 16-04/D5

### 33. The §10 update contract prescribes one flat apply command with no profile probe and no conditional, and carries no package-marking subsection
expected: The §10 update contract prescribes one flat apply command with no profile probe and no conditional, and carries no package-marking subsection
result: pass
source: automated
coverage_id: 16-04/D6

### 34. The verification expectation quotes the summary line phase14-verify.sh prints today, observed after 16-03's deletions rather than carried forward
expected: The verification expectation quotes the summary line phase14-verify.sh prints today, observed after 16-03's deletions rather than carried forward
result: pass
source: automated
coverage_id: 16-04/D7

### 35. The documentation gate actually gates: it fails on a playbook seeded with a banned term, and does not contradict the two frozen-record asserts that require those same terms
expected: The documentation gate actually gates: it fails on a playbook seeded with a banned term, and does not contradict the two frozen-record asserts that require those same terms
result: pass
source: automated
coverage_id: 16-04/D8

### 36. Every in-page anchor and every relative link in the rewritten playbook resolves, and no link points at either deleted script
expected: Every in-page anchor and every relative link in the rewritten playbook resolves, and no link points at either deleted script
result: pass
source: automated
coverage_id: 16-04/D9

### 37. The §6 apply fence is byte-untouched, so plan 16-06's drift assert has two agreeing copies to compare
expected: The §6 apply fence is byte-untouched, so plan 16-06's drift assert has two agreeing copies to compare
result: pass
source: automated
coverage_id: 16-04/D10

### 38. Every reference to the deleted preflight script reads as an account of what was run on 2026-09-04 rather than as a step to perform now
expected: Every reference to the deleted preflight script reads as an account of what was run on 2026-09-04 rather than as a step to perform now
result: pass
source: automated
coverage_id: 16-05/D1

### 39. The rollback section describes a clean reinstall from the pinned submodule rather than a tier list whose machinery has been deleted
expected: The rollback section describes a clean reinstall from the pinned submodule rather than a tier list whose machinery has been deleted
result: pass
source: automated
coverage_id: 16-05/D2

### 40. The file keeps its seventeen sections and its role as the adopt-window narrative
expected: The file keeps its seventeen sections and its role as the adopt-window narrative
result: pass
source: automated
coverage_id: 16-05/D3

### 41. The pre-adopt snapshot is acknowledged as present on disk without being aimed at with a destructive command or presented as a recovery tier
expected: The pre-adopt snapshot is acknowledged as present on disk without being aimed at with a destructive command or presented as a recovery tier
result: pass
source: automated
coverage_id: 16-05/D4

### 42. Every relative link in the file resolves to an existing path
expected: Every relative link in the file resolves to an existing path
result: pass
source: automated
coverage_id: 16-05/D5

### 43. The phase has a written record of what changed where, in the same shape and vocabulary as the Phase 15 record, with the two later sections stubbed
expected: The phase has a written record of what changed where, in the same shape and vocabulary as the Phase 15 record, with the two later sections stubbed
result: pass
source: automated
coverage_id: 16-06/D1

### 44. The record states the marker coupling and carries both unowned deferred rows
expected: The record states the marker coupling and carries both unowned deferred rows
result: pass
source: automated
coverage_id: 16-06/D2

### 45. The record quotes stale strings verbatim without tripping the phase-16 documentation ban, and names Waybar / rofi / swaync literally
expected: The record quotes stale strings verbatim without tripping the phase-16 documentation ban, and names Waybar / rofi / swaync literally
result: pass
source: automated
coverage_id: 16-06/D3

### 46. The wrapper drift check is live again against a baseline that matches the working tree, selected by a tier that actually fires
expected: The wrapper drift check is live again against a baseline that matches the working tree, selected by a tier that actually fires
result: pass
source: automated
coverage_id: 16-06/D4

### 47. The playbook's duplicated apply fence is compared against the Phase 13 source of truth, using one extractor, with the reconciling filter documented
expected: The playbook's duplicated apply fence is compared against the Phase 13 source of truth, using one extractor, with the reconciling filter documented
result: pass
source: automated
coverage_id: 16-06/D5

### 48. The fence-drift check demonstrably fails when the playbook copy drifts by one word, and the control leaves the file unmodified
expected: The fence-drift check demonstrably fails when the playbook copy drifts by one word, and the control leaves the file unmodified
result: pass
source: automated
coverage_id: 16-06/D6

### 49. Every tree-clean-agnostic assert suite in the repository is green on a committed tree
expected: Every tree-clean-agnostic assert suite in the repository is green on a committed tree
result: pass
source: automated
coverage_id: 16-06/D7

### 50. The requirement set contains nineteen rows and nineteen mappings, with coverage arithmetic that agrees
expected: The requirement set contains nineteen rows and nineteen mappings, with coverage arithmetic that agrees
result: pass
source: automated
coverage_id: 16-07/D1

### 51. No deleted requirement ID survives anywhere in the file as an orphan
expected: No deleted requirement ID survives anywhere in the file as an orphan
result: pass
source: automated
coverage_id: 16-07/D2

### 52. The mapping conflict resolves the specific way: INV-04 at Phase 10, DISP-03 untouched at Phase 11, five rewritten rows at Phase 16
expected: The mapping conflict resolves the specific way: INV-04 at Phase 10, DISP-03 untouched at Phase 11, five rewritten rows at Phase 16
result: pass
source: automated
coverage_id: 16-07/D3

### 53. No retired claim survives in a requirement row or an out-of-scope row, and the frozen Phase 10 assert was not edited to agree with the rewrite
expected: No retired claim survives in a requirement row or an out-of-scope row, and the frozen Phase 10 assert was not edited to agree with the rewrite
result: pass
source: automated
coverage_id: 16-07/D4

### 54. Both blockers keep their identifiers and original issue statements and carry resolutions citing Phase 16 plans
expected: Both blockers keep their identifiers and original issue statements and carry resolutions citing Phase 16 plans
result: pass
source: automated
coverage_id: 16-07/D5

### 55. Every surviving citation of a deleted script, array, output string or function is marked as removed in Phase 16, and the tech-debt entry reads as closed by deletion
expected: Every surviving citation of a deleted script, array, output string or function is marked as removed in Phase 16, and the tech-debt entry reads as closed by deletion
result: pass
source: automated
coverage_id: 16-07/D6

### 56. The archive-path evidence names the location that exists, and no recommendation prescribes a route back to the retired session model
expected: The archive-path evidence names the location that exists, and no recommendation prescribes a route back to the retired session model
result: pass
source: automated
coverage_id: 16-07/D7

### 57. The two genuinely open items remain listed and unowned
expected: The two genuinely open items remain listed and unowned
result: pass
source: automated
coverage_id: 16-07/D8

### 58. The planning-artifact edits left every owned directory untouched and the overlay assert green
expected: The planning-artifact edits left every owned directory untouched and the overlay assert green
result: pass
source: automated
coverage_id: 16-07/D9

### 59. PROJECT.md's current-state claims describe the project after this phase: one install path, no wrapper backup gate, no package re-marking, ii owning the session hooks, rollback as a clean reinstall from the pinned submodule
expected: PROJECT.md's current-state claims describe the project after this phase: one install path, no wrapper backup gate, no package re-marking, ii owning the session hooks, rollback as a clean reinstall from the pinned submodule
result: pass
source: automated
coverage_id: 16-08/D1

### 60. PROJECT.md's per-phase delivered lines and key-decision rows keep their original claim text and carry the phase's superseded annotation, in at most two spellings
expected: PROJECT.md's per-phase delivered lines and key-decision rows keep their original claim text and carry the phase's superseded annotation, in at most two spellings
result: pass
source: automated
coverage_id: 16-08/D2

### 61. The three Waybar/rofi/swaync collective-noun occurrences the previous phase deliberately froze survive, and no rewritten line introduced a fourth
expected: The three Waybar/rofi/swaync collective-noun occurrences the previous phase deliberately froze survive, and no rewritten line introduced a fourth
result: pass
source: automated
coverage_id: 16-08/D3

### 62. W-1 closed at source — the three migrate-to-hypr-custom must-keep rows in the Phase 11 record read as completed outcomes citing Phase 13 and Phase 14, with no future-intent phrasing
expected: W-1 closed at source — the three migrate-to-hypr-custom must-keep rows in the Phase 11 record read as completed outcomes citing Phase 13 and Phase 14, with no future-intent phrasing
result: pass
source: automated
coverage_id: 16-08/D4

### 63. W-2 closed at source — the archive policy names the three stow/ trees, which still exist in the repository, and no longer names the directory set that does not
expected: W-2 closed at source — the archive policy names the three stow/ trees, which still exist in the repository, and no longer names the directory set that does not
result: pass
source: automated
coverage_id: 16-08/D5

### 64. The gating assert survived the rewrite untouched and every literal it requires is still present in the record
expected: The gating assert survived the rewrite untouched and every literal it requires is still present in the record
result: pass
source: automated
coverage_id: 16-08/D6

### 65. The frozen-artifact override stayed scoped to the two named sites; no other planning, code or documentation surface was touched
expected: The frozen-artifact override stayed scoped to the two named sites; no other planning, code or documentation surface was touched
result: pass
source: automated
coverage_id: 16-08/D7

### 66. The roadmap's milestone overview states the outcome that shipped — one install path, residual defaults retired, playbook documenting that single path — while keeping the inventory-then-disposition gate that still governs
expected: The roadmap's milestone overview states the outcome that shipped — one install path, residual defaults retired, playbook documenting that single path — while keeping the inventory-then-disposition gate that still governs
result: pass
source: automated
coverage_id: 16-09/D1

### 67. The roadmap coverage line equals the arithmetic plan 16-07 wrote into the requirement set
expected: The roadmap coverage line equals the arithmetic plan 16-07 wrote into the requirement set
result: pass
source: automated
coverage_id: 16-09/D2

### 68. The per-phase roadmap history for Phases 11, 12 and 14 survives the sweep, and no successor phase was invented
expected: The per-phase roadmap history for Phases 11, 12 and 14 survives the sweep, and no successor phase was invented
result: pass
source: automated
coverage_id: 16-09/D3

### 69. The state file carries no current-state claim this phase falsified, and its accumulated-context entries recording past decisions are annotated rather than rewritten
expected: The state file carries no current-state claim this phase falsified, and its accumulated-context entries recording past decisions are annotated rather than rewritten
result: pass
source: automated
coverage_id: 16-09/D4

### 70. The review entry for the deleted preflight script is closed in the state file, and the pointer to the phase sweep record exists
expected: The review entry for the deleted preflight script is closed in the state file, and the pointer to the phase sweep record exists
result: pass
source: automated
coverage_id: 16-09/D5

### 71. The two items this phase has no authority over are still present, still open, and still unowned
expected: The two items this phase has no authority over are still present, still open, and still unowned
result: pass
source: automated
coverage_id: 16-09/D6

### 72. Nothing outside the two files changed, and the wrapper drift baseline still holds
expected: Nothing outside the two files changed, and the wrapper drift baseline still holds
result: pass
source: automated
coverage_id: 16-09/D7

### 73. The sweep record's planning-artifact section exists with one subsection per swept file
expected: The sweep record's planning-artifact section exists with one subsection per swept file
result: pass
source: automated
coverage_id: 16-10/D1

### 74. The record names the three deleted requirement IDs with a reason each, the new coverage number, the resolved mapping conflict, the override sites and the deferred snapshot refresh
expected: The record names the three deleted requirement IDs with a reason each, the new coverage number, the resolved mapping conflict, the override sites and the deferred snapshot refresh
result: pass
source: automated
coverage_id: 16-10/D2

### 75. No home was invented for either genuinely open item, and the banned collective noun is absent
expected: No home was invented for either genuinely open item, and the banned collective noun is absent
result: pass
source: automated
coverage_id: 16-10/D3

### 76. Nothing outside the sweep record was modified by either task
expected: Nothing outside the sweep record was modified by either task
result: pass
source: automated
coverage_id: 16-10/D4

### 77. The gate ran on a committed, clean tree
expected: The gate ran on a committed, clean tree
result: pass
source: automated
coverage_id: 16-10/D5

### 78. The four tree-clean-agnostic suites are green and the wrapper drift baseline still holds
expected: The four tree-clean-agnostic suites are green and the wrapper drift baseline still holds
result: pass
source: automated
coverage_id: 16-10/D6

### 79. The live suite is green with exactly one finding, and that finding is the known compositor-target loss
expected: The live suite is green with exactly one finding, and that finding is the known compositor-target loss
result: pass
source: automated
coverage_id: 16-10/D7

### 80. The session still loads through the ii Lua entry and the retired session surfaces are still stopped, verified after the phase's changes
expected: The session still loads through the ii Lua entry and the retired session surfaces are still stopped, verified after the phase's changes
result: pass
source: automated
coverage_id: 16-10/D8

### 81. The live suite's summary line matches the expectation the playbook quotes
expected: The live suite's summary line matches the expectation the playbook quotes
result: pass
source: automated
coverage_id: 16-10/D9

## Summary

total: 81
passed: 80
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-16-4
  truth: "The sweep record's per-file correction tables faithfully consolidate what plans 16-01..16-05 actually did"
  status: failed
  reason: "Automated check: 16-DOC-SWEEP.md records phase07-live-smoke.sh deleted at 451 lines and phase14-preflight.sh at 327 lines; commit 769bf9e deleted 456 and 322 respectively. The two numbers are transposed. Origin is 16-03-SUMMARY.md:172-173, which the record consolidated instead of re-reading the diff."
  severity: minor
  test: 4
  root_cause: "Line counts were carried forward from 16-03-SUMMARY.md rather than re-extracted from the deletion commit's diffstat."
  artifacts:
    - path: ".planning/phases/16-retire-the-safe-profile-full-only-wrapper-and-playbook/16-DOC-SWEEP.md"
      issue: "phase07-live-smoke.sh row says 451 lines (actual 456); phase14-preflight.sh row says 327 lines (actual 322)"
    - path: ".planning/phases/16-retire-the-safe-profile-full-only-wrapper-and-playbook/16-03-SUMMARY.md"
      issue: "lines 172-173 state -451 and -327"
  missing:
    - "Correct both line counts to 456 and 322 in 16-DOC-SWEEP.md and 16-03-SUMMARY.md"
  debug_session: ""
