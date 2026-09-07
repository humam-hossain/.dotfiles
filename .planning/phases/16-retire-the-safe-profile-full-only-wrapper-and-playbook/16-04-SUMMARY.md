---
phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook
plan: 04
subsystem: docs
tags: [markdown, playbook, operator-docs, assert-script, ban-grep, dots-hyprland]

# Dependency graph
requires:
  - phase: 16-01
    provides: "the full-only wrapper — the install path this playbook now describes, and the deletions (backup gate, protect subcommand, hook machinery) that made whole subsections of the old playbook describe machinery that no longer exists"
  - phase: 16-02
    provides: "arch/dots-hyprland.sh final for the phase, so the wrapper stdout quoted in §4 is re-captured from a binary that will not move again (D-23, D-42); and the interactivity note in usage() that §4's prose now mirrors"
  - phase: 16-03
    provides: "scripts/phase14-verify.sh green at 33 PASS / 0 FAIL / 1 FINDING, which is the summary tail §7 quotes; and the two script deletions whose dangling docs/ citations this plan clears (D-21)"
provides:
  - "docs/dots-hyprland-workflow.md full-only end to end — one install path, one apply command, no profile choice documented anywhere"
  - "wrapper output quoted in §4 re-captured from the finalised binary: `./setup install --skip-backup`"
  - "the clean-reinstall recovery paragraph (§9) that replaces every withdrawn rollback-tier pointer (D-20)"
  - "the hook-ownership statement naming hyprland/env.lua and hyprland/execs.lua as ii's, not the wrapper's (D-19)"
  - "the truthful interactivity note — the wrapper prompts for nothing, upstream still greets and pauses (research Pitfall 3)"
  - "scripts/phase16-retire-assert.sh documentation half: ban-only, playbook-scoped, negative-control proven — 23 PASS, FAIL=0"
affects: [16-05, 16-06, 16-07, 16-09, 16-10, phase-verification]

# Actuals (#2632)
actuals:
  tokens: 11841
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Documentation gates are ban-only: an assert over operator prose forbids strings and never requires them, so it can never contradict a frozen-record assert that requires the same strings"
    - "Section-scoped bans are implemented by extracting the section with an awk range and asserting the extract is non-empty, never by approximating the scope with a file-wide ban"
    - "Input guard before any ban-grep: a ban over a missing or empty file passes vacuously, which is the one way such a gate silently stops being a gate"
    - "Quoted program output in prose is re-captured from the running binary immediately before it is written, never composed and never carried forward"

key-files:
  created: []
  modified:
    - docs/dots-hyprland-workflow.md
    - scripts/phase16-retire-assert.sh

key-decisions:
  - "The profiles section carried no `## Outline` entry and no section number, so its deletion required no renumbering — the plan's renumber instruction was a no-op against the real file"
  - "§3 and §5 headings were renamed off the two-profile framing (`before installing`, `after installing`) with both Outline anchors updated, because a heading saying `before any full install` still implies a non-full one"
  - "The §11 `Full hyprland.lua / ii hypr tree takeover` row was deleted whole rather than having its false clause excised — a Non-goals table row reading `not a non-goal any more` is legacy scaffolding, and §4/§5 already carry the true statement"
  - "Task 1's file-wide vocabulary gate was satisfied in scope (front half) at Task 1 and literally file-wide at Task 2, because Task 1's own prohibition forbids touching §8 onward where four of the sites live"
  - "The residual-array identifier is banned file-wide in the assert as a deliberate A11 extension of D-36's list, in the same ban-only shape, with the reason recorded in a comment"
  - "The recovery paragraph lives in §9 rather than §7, so §7's failure pointer and §9's role-1 archive claim reference one story in one place"

patterns-established:
  - "Deletion over softening, applied to structure as well as prose: a section whose subject no longer exists loses its heading, not just its claims"
  - "A documentation gate ships with a negative control in the same plan that adds it — seed a banned term, assert non-zero, restore the file — so a vacuous gate fails the task rather than passing it"

requirements-completed: [DOC-03, FULL-01, FULL-02, FULL-04, D-14, D-15, D-16, D-17, D-18, D-19, D-20, D-21, D-22, D-23, D-36, D-42]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "Every install example in the playbook is a bare command and the retired vocabulary is absent file-wide — an operator who pastes one gets the full behavior, which is the only behavior"
    requirement: "FULL-01"
    verification:
      - kind: other
        ref: "grep -q 'install-files' && ! grep -qiE 'dual-run|safe profile|safe defaults|SAFE_DEFAULTS' && ! grep -qE '^\\s*\\./arch/dots-hyprland\\.sh (install|install-files)[^|]*--full'  =>  exit 0 file-wide"
        status: pass
      - kind: integration
        ref: "./scripts/phase16-retire-assert.sh — 'D-36 playbook is free of the retired session-model term' + 'the retired profile term' + 'the retired residual array identifier'"
        status: pass
    human_judgment: false
  - id: D2
    description: "The playbook quotes wrapper output the wrapper actually prints today, re-captured from the binary 16-02 finalised"
    requirement: "D-23"
    verification:
      - kind: other
        ref: "printf '' | ./arch/dots-hyprland.sh install --dry-run  =>  './setup install --skip-backup' present in the playbook; 'full profile: no SAFE_DEFAULTS injection' and \"Type 'yes'\" both absent"
        status: pass
    human_judgment: false
  - id: D3
    description: "The playbook tells the truth about interactivity: the wrapper no longer prompts, upstream still greets and pauses"
    requirement: "D-14"
    verification:
      - kind: other
        ref: "grep -qiE 'upstream[^.]{0,120}(greeting|Enter to proceed|pause)' && ! grep -qiE 'unattended|non-interactive|no prompts|silent install'"
        status: pass
    human_judgment: false
  - id: D4
    description: "ii owns the session hooks in its own Lua tree; the wrapper does not touch them, and the repo copy's two lines are dead archive"
    requirement: "D-19"
    verification:
      - kind: other
        ref: "grep -qF 'hyprland/env.lua' && grep -qF 'hyprland/execs.lua'; live ownership confirmed at ~/.config/hypr/hyprland/env.lua:16 and hyprland/execs.lua:6"
        status: pass
    human_judgment: false
  - id: D5
    description: "No rollback tier list and no pointer to one survives; recovery is a clean reinstall from the pinned submodule"
    requirement: "D-20"
    verification:
      - kind: other
        ref: "! grep -qiE 'three-tier|tier 1|tier 2|tier 3' && ! grep -qF 'rotate the backup' && grep -qF 'phase14-adopt-runbook.md' (pointer kept, tier clause stripped)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The §10 update contract prescribes one flat apply command with no profile probe and no conditional, and carries no package-marking subsection"
    requirement: "D-17"
    verification:
      - kind: other
        ref: "awk-extracted §10 region: contains './arch/dots-hyprland.sh install-files'; contains none of --skip-hyprland, hyprctl, configProvider, \\bprotect\\b, 'backup gate', skip-backup"
        status: pass
    human_judgment: false
  - id: D7
    description: "The verification expectation quotes the summary line phase14-verify.sh prints today, observed after 16-03's deletions rather than carried forward"
    requirement: "FULL-04"
    verification:
      - kind: integration
        ref: "./scripts/phase14-verify.sh on the committed tree  =>  '=== done: FAIL=0 FINDINGS=1 ===', 33 PASS / 0 FAIL / 1 FINDING / 12 INFO; the literal is present in the playbook"
        status: pass
    human_judgment: false
  - id: D8
    description: "The documentation gate actually gates: it fails on a playbook seeded with a banned term, and does not contradict the two frozen-record asserts that require those same terms"
    requirement: "D-36"
    verification:
      - kind: integration
        ref: "negative control — append 'dual-run', run assert  =>  rc=1 with '[FAIL] D-36 playbook still names the retired session model'; file restored from the temp copy"
        status: pass
      - kind: integration
        ref: "./scripts/phase10-inventory-assert.sh + ./scripts/phase11-dispositions-assert.sh + ./scripts/phase12-full-smoke.sh  =>  each '=== done: FAIL=0 ==='"
        status: pass
    human_judgment: false
  - id: D9
    description: "Every in-page anchor and every relative link in the rewritten playbook resolves, and no link points at either deleted script"
    requirement: "D-21"
    verification:
      - kind: other
        ref: "GitHub slug-transform anchor loop (no MISSING ANCHOR) + relative-link resolver (no BROKEN) + grep for phase07-live-smoke / phase14-preflight  =>  none"
        status: pass
    human_judgment: false
  - id: D10
    description: "The §6 apply fence is byte-untouched, so plan 16-06's drift assert has two agreeing copies to compare"
    requirement: "D-42"
    verification:
      - kind: other
        ref: "git diff -U0 HEAD -- docs/dots-hyprland-workflow.md | grep -cE '^[+-].*hl\\.monitor|^[+-].*general\\.lua'  =>  0, on both task diffs"
        status: pass
    human_judgment: false
  - id: D11
    description: "A cold operator reading the playbook end to end sees one install path and no profile choice"
    verification: []
    human_judgment: true
    rationale: "Absence-greps prove the retired tokens are gone; they cannot prove the surviving prose reads coherently to someone installing on a cold machine for the first time. The one surviving occurrence of the word 'profile' is the sentence stating there is no profile to choose, which is a judgment call about clarity, not a token check."

# Metrics
duration: 8 min
completed: 2026-09-07
status: complete
---

# Phase 16 Plan 04: Full-only playbook and its documentation gate Summary

**`docs/dots-hyprland-workflow.md` rewritten full-only end to end — one bare install path quoting `./setup install --skip-backup` re-captured from the finalised wrapper, ii named as the owner of the session hooks, and the rollback tier list replaced by a clean-reinstall paragraph — with a ban-only, playbook-scoped documentation gate added to `scripts/phase16-retire-assert.sh` and proven by a negative control.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-09-07T13:25:11Z
- **Completed:** 2026-09-07T13:33:11Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- **The playbook has one install path and says so.** The profiles section is gone in full — heading, both subsections, flag-axis table. Every command example is bare. The single surviving occurrence of the word "profile" is the sentence stating there is no profile to choose.
- **The quoted wrapper output was captured, not composed.** `printf '' | ./arch/dots-hyprland.sh install --dry-run` was run against the binary `16-02` finalised, and its two lines were copied verbatim into §4. The old three-line block — including `[CONFIG] full profile: no SAFE_DEFAULTS injection (DISP-02 drop-all-three)`, a string the program no longer prints — is gone (D-23, D-42).
- **The backup gate subsection was deleted, not softened.** Its narrative, its citation of a wrapper line number pointing at a deleted constant, and its `sha256sum`/`grep -qxF` verification recipe all went together. In its place: one plain paragraph saying no wrapper prompt, no wrapper-made snapshot, no undo — followed immediately by the truthful interactivity note. The playbook nowhere claims the install is unattended, and it ties `upstream` to a greeting and an `Enter to proceed` pause.
- **ii owns the session hooks.** §4 now names `hyprland/env.lua` and `hyprland/execs.lua` under `~/.config/hypr/` as the live owners, states the wrapper carries no hook machinery, and records the repo copy's two lines as dead archive that nothing loads. Verified live before writing: `env.lua:16` sets `ILLOGICAL_IMPULSE_VIRTUAL_ENV`, `execs.lua:6` runs `qs -c $qsConfig`.
- **The rollback tiers left as a unit.** Every pointer at the runbook §14 tier list, the tier-1-source-2 framing in §9, the copy-aside-before-escalating subsection, the never-rotate subsection, and the `## See also` tier clause were removed in one edit and replaced by one recovery paragraph: clean reinstall from the pinned submodule, never upstream's own removal subcommand, nothing preserved on install. The 2026-09-04 snapshot is named, left on disk, and explicitly described as no longer a documented route (D-20).
- **The §10 update contract is one flat command.** `./arch/dots-hyprland.sh install-files`, no probe, no conditional, no second command block. All three operator bullets deleted as one obsolete unit, the lead-in sentence with them, and the §10.4 package-marking subsection removed whole (D-16, D-17, D-18).
- **The verification expectation was re-observed, not trusted.** `./scripts/phase14-verify.sh` was run on the committed tree at `0908c18`: **33 `[PASS]`, 0 `[FAIL]`, 1 `[FINDING]`, `=== done: FAIL=0 FINDINGS=1 ===`**. Research Pitfall 6's relief held — the number in the playbook survives the D-37 deletions unchanged, and §7 now records the observed counts alongside it.
- **The documentation gate ships with its own negative control.** Five new asserts (input guard, three file-wide bans, one awk-scoped section ban) take `scripts/phase16-retire-assert.sh` from 17 to 23 `[PASS]` at `FAIL=0`. Seeding `dual-run` into the playbook makes it exit 1; the control restores the file first, so a failing control cannot leave a banned term behind.
- **No contradiction with the frozen-record asserts.** `phase10-inventory-assert.sh`, `phase11-dispositions-assert.sh` and `phase12-full-smoke.sh` were re-run after the ban landed and are all at `FAIL=0`. The gate names no adopt-runbook path and no planning path.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite the front half — purpose, prerequisites, profiles, gate, install, session model** — `0908c18` (docs)
2. **Task 2: Rewrite the back half — verification, known losses, three roles, update contract, non-goals** — `b054def` (docs)
3. **Task 3: Add the ban-only documentation gate to the phase-16 assert** — `825a029` (test)

**Plan metadata:** the `docs(16-04)` commit that carries this file.

## Files Created/Modified

- `docs/dots-hyprland-workflow.md` — rewritten full-only end to end. 536 → 448 lines, `+129/−148` across the two task commits. Deleted whole: the profiles section, the backup-gate subsection with its checksum recipe, the copy-aside-before-escalating subsection, the never-rotate subsection, the §10.4 package-marking subsection, the retired-subcommand table row, the §11 takeover row, and both hard-coded wrapper line-number citations. Rewritten: purpose, the cross-reference block, prerequisites, §3's gate framing, §4 end to end, the hook-ownership statement, §5's session model, §7's verification tail, §9's three roles, §10.3's apply, and the `## See also` block.
- `scripts/phase16-retire-assert.sh` — documentation half added after the argv half and before the summary footer; header `Constraints (Phase 16):` list extended with the scope record; `PLAYBOOK` path constant declared with the other constants. `+73/−4`. The argv half is byte-untouched.

## Decisions Made

- **§3 and §5 were renamed, and their Outline anchors with them.** "Required gate before any full install" and "Session model after a full install" both imply a non-full install exists. They are now "Required gate before installing" and "Session model after installing". The anchor loop is what proves the Outline followed.
- **The §11 takeover row went whole.** The plan says the row asserting the personal compositor config remains source of truth via a residual flag "is false post-adopt and goes." Excising only the false clause would leave a Non-goals table carrying a row whose status reads "not a non-goal any more" — legacy scaffolding of exactly the kind this sweep removes, and the true statement it carried is already in §4 and §5.
- **The recovery paragraph lives in §9, not §7.** §7's failure pointer used to send the reader at the runbook's tier list; §9 already held the file whose role-1 archive claim is the closest thing to a recovery artifact this repo has. Putting the replacement there keeps one recovery story in one place and gives §7 something to point at.
- **The residual-array identifier is banned file-wide.** D-36 names two vocabulary terms plus one section-scoped flag. The array identifier is added in the same ban-only shape, with a comment recording that it is a planner extension (A11) justified by D-16 deleting the only bullet that mentioned it, so any surviving occurrence is stale by construction.
- **The section ban is extracted, not approximated.** `awk '/^## [0-9]+\. .*[Uu]pdate contract/,/^## [0-9]+\. [^U]/'` — matching D-36's stated scope exactly. A file-wide ban on that flag would be a stricter gate than the decision authorises and would fail on legitimate surviving prose elsewhere (research Pitfall 8, A14). The extraction is asserted non-empty before it is grepped, for the same vacuous-pass reason as the file guard.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Task 1's file-wide vocabulary gate is unsatisfiable within Task 1's own prohibition; satisfied in scope, then literally at Task 2**

- **Found during:** Task 1
- **Issue:** Task 1's first `<automated>` gate and its matching acceptance criterion require the whole file to match none of `dual-run` / `safe profile` / `safe defaults` / `SAFE_DEFAULTS`. Four of those sites live in the back half — `:398` (§8), `:478` and `:492` (§10), `:517` (§11) — and Task 1's own action says in as many words: "Do not touch in this task: … everything from §8 onward. Task 2 owns the back half." The gate as written can only pass after Task 2 runs.
- **Fix:** Ran the gate scoped to the front half (lines 1 to the `## 6.` heading) as Task 1's gate — it returned clean — and re-ran the identical gate **file-wide** immediately after Task 2's edit, where it also returned clean. No prohibition was crossed to satisfy a gate.
- **Files modified:** `docs/dots-hyprland-workflow.md`
- **Verification:** front-half scope at Task 1: no match. File-wide after Task 2: `T1 gate1 PASS (file-wide)`, and gates 3 and 4 re-run file-wide at the same point, both passing.
- **Committed in:** `0908c18` (front half) and `b054def` (back half)

### Factual corrections to the plan

**2. The profiles section had no `## Outline` entry and no section number.** Task 1's action says to "Delete its `## Outline` entry too, and renumber the spine so the numbered sections stay contiguous with no gap." Against the real file the profiles section is `## Profiles: safe vs full` — unnumbered, sitting *above* the Outline, and absent from the Outline's eleven entries, all of which map to `## N.` headings. Deleting it therefore left the spine already contiguous and required no renumbering. The Outline *was* edited, but for a different reason: the §3 and §5 heading renames above. The anchor loop passed both before and after.

**3. `docs/dots-hyprland-workflow.md:389`'s expectation survived, as 16-03 predicted, but was re-observed anyway.** The plan and research both allow that the number might have moved. It did not: the committed-tree tail is byte-identical to what the file already claimed. The action's instruction to re-run rather than trust was still followed, and §7 now also records the observed 33/0/1 counts, which the file did not carry before.

---

**Total deviations:** 1 auto-fixed (1 bug) + 2 factual corrections to plan prose.
**Impact on plan:** No scope creep and no prohibition crossed. Deviation 1 sequences a gate that the plan's own task boundary made impossible to satisfy in place; the criterion is now literally true of the committed file. Both corrections are bookkeeping — one records that an instructed edit was a no-op against the real file, the other records that a re-observation confirmed rather than changed a number.

## Issues Encountered

- **The `grep` shell-function shadowing reported by 16-02 and 16-03 was live in this session too.** Every gate in this plan was run with an explicit `/usr/bin/grep`. No gate was relaxed or reinterpreted on the basis of a shadowed-`grep` result, and no file was changed to satisfy one.
- **`scripts/phase14-verify.sh` returns `FAIL=1` on a dirty tree.** Task 2's gate normalises the failure count to zero with `sed` before comparing, which is what makes the gate runnable mid-task. The real committed-tree run — after Task 1's commit and again after Task 3's — returns `FAIL=0 FINDINGS=1` with no normalisation.
- **`requirements.mark-complete` wrote nothing, correctly.** `requirements.ready-ids` returned `DOC-03` / `FULL-01` / `FULL-02` / `FULL-04` / `D-20` as **blocked** (sibling plans in this phase also declare them and have no SUMMARY yet), and the eleven remaining Phase 16 decision IDs as ready. `mark-complete` then reported every one of those eleven as `applied: false` — they are decision IDs with no row in `.planning/REQUIREMENTS.md`. That file is unchanged by this plan, which is the correct outcome, not a failed write. `REQUIREMENTS.md` is plan `16-07`'s to amend.
- **`WINDOWS.md` id 1 still applies and was deliberately not closed.** It records that the playbook's §8 cites `15-DOC-SWEEP.md` as carrying the D-38 restoration work as a deferred item while that section of the sweep record is still a placeholder. The rewritten §8 still makes that citation — correctly, because the underlying situation is unchanged and D-38 stays unowned by decision. Closing the window would require editing a Phase 15 frozen artifact, which is out of this plan's scope.

## Known Stubs

None. Every section marked for deletion is gone from the playbook — heading, body and table row alike — and nothing was commented out, softened into a placeholder, or left as a `TODO`. The assert script's documentation half contains no skipped or disabled assertion; all five new asserts execute on every run and all five are exercised (four positively by the green run, the session-model ban additionally by the negative control).

## Threat Flags

None. This plan adds no network endpoint, auth path, file-access pattern or schema change; it edits prose and adds read-only greps. The registered trust boundaries held:

- **T-16-20** (quoted wrapper output) — output captured from the finalised binary immediately before writing; the playbook carries the real argv fragment `./setup install --skip-backup` and none of the deleted announcement lines.
- **T-16-21** (unattended-install expectation) — asserted in both directions: `upstream` is tied to a greeting and an `Enter to proceed` pause, and none of `unattended` / `non-interactive` / `no prompts` / `silent install` appears anywhere in the file.
- **T-16-22** (recovery narrative) — the tier list and every pointer to it were removed together, and the ban covers `three-tier` / `tier 1` / `tier 2` / `tier 3` so a half-removed reference fails the gate.
- **T-16-23** (the gate itself) — the negative control seeds `dual-run`, observes `rc=1`, and restores the file from a `mktemp` copy taken beforehand.
- **T-16-24** (ban scope creep) — the script contains no `.planning/` path and no adopt-runbook reference, and the two frozen-record asserts were re-run as an explicit contradiction check.
- **T-16-25** (the §6 apply fence) — `git diff -U0 HEAD` matched zero added or removed lines containing `hl.monitor` or `general.lua` on both task diffs; the only `cp -a` line in the whole diff is the deleted §9 escalation command, not the fence.
- **T-16-26** (broken links) — the relative-link resolver walked every link in the file and reported none broken; both deleted script stems are absent from the file entirely.
- **T-16-SC** — no `npm` / `pip` / `cargo` / `pacman` install step was added or run.

## User Setup Required

None — no external service configuration required. The plan's frontmatter carries no `user_setup` block.

## Next Phase Readiness

- **Ready for `16-05`.** The playbook now points at `docs/phase14-adopt-runbook.md` purely as the adopt-window narrative, with no tier clause attached. `16-05` owns the runbook's own §5 and §14 rewrites and its six `phase14-preflight.sh` invocation sites; nothing in this plan pre-empts them.
- **Ready for `16-06`.** The §6 apply fence is byte-untouched, so the W-3 drift assert has two agreeing copies to compare. `arch/dots-hyprland.sh` was not touched by this plan either, so the D-19 re-pin baseline stays `0771cc2`.
- **Regression floors for the rest of the phase:** `scripts/phase16-retire-assert.sh` (now 23 PASS), `scripts/phase12-full-smoke.sh`, `scripts/phase10-inventory-assert.sh` and `scripts/phase11-dispositions-assert.sh` are all `FAIL=0`. `scripts/phase14-verify.sh` is at `FAIL=0 FINDINGS=1` on a committed tree.
- **`scripts/phase13-d19-assert.sh` remains expected-red by design** until `16-06`. `WINDOWS.md` id 3 stays open to track it. It was deliberately not run as a gate here.
- **Carried forward for `16-07`:** `REQUIREMENTS.md` still carries the unamended `FULL-01` / `FULL-02` / `FULL-04` / `DOC-03` rows this playbook now contradicts, plus the `FULL-03` / `FULL-05` / `ADOPT-04` rows D-26 deletes.
- **Carried forward for `16-09`:** `STATE.md`'s Phase 14 three-tier rollback decision line is now contradicted by the playbook's recovery paragraph; D-30 marks it superseded in wave 5.
- **New for the `16-10` gate:** the documentation half of the retirement assert is a live contract over `docs/dots-hyprland-workflow.md`. Any later plan that edits that file must re-run `./scripts/phase16-retire-assert.sh`, not just the script asserts it previously cared about.

## Self-Check: PASSED

- `docs/dots-hyprland-workflow.md` — FOUND on disk, 448 lines
- `scripts/phase16-retire-assert.sh` — FOUND on disk, executable, `bash -n` clean, `=== done: FAIL=0 ===` with 23 `[PASS]`
- Commit `0908c18` — FOUND in `git log --oneline --all`
- Commit `b054def` — FOUND in `git log --oneline --all`
- Commit `825a029` — FOUND in `git log --oneline --all`
- Task 1 acceptance criteria: 7 of 8 pass as written at Task 1; the file-wide vocabulary clause satisfied in scope per deviation 1 and literally after Task 2
- Task 2 acceptance criteria: all 9 pass
- Task 3 acceptance criteria: all 7 pass, including the negative control (`rc=1`, file restored) and the three-suite contradiction check
- Plan-level `<verification>`: four regression floors at `FAIL=0`; `phase13-d19-assert.sh` correctly not run as a gate; `phase14-verify.sh` run only to capture its tail, `FAIL=0 FINDINGS=1` on the committed tree; the anchor loop and the relative-link loop both clean
- `git status --short` empty after each task commit; no file deletions in any task commit; no untracked files left behind

---
*Phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook*
*Completed: 2026-09-07*
