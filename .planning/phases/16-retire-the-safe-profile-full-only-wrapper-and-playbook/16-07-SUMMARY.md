---
phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook
plan: 07
subsystem: planning-artifacts
tags: [requirements, traceability, milestone-audit, disposition, coverage-arithmetic, markdown]

# Dependency graph
requires:
  - phase: 16-01
    provides: "the wrapper with SAFE_DEFAULTS and the session-hook cluster deleted — the change that actually closed blocker B-1 and retired Flow A"
  - phase: 16-02
    provides: "`--full` surviving only as an announced no-op alias, which is what FULL-02 now asserts"
  - phase: 16-03
    provides: "the deletion of scripts/phase14-preflight.sh, which closes the IN-11 tech-debt entry by deletion rather than by payment"
  - phase: 16-04
    provides: "the rewritten playbook section 10.3, the one flat apply command the audit's refreshed evidence cites"
  - phase: 16-06
    provides: "the W-3 fence-drift assert cited as that warning's resolution, and the wrapper drift pin that constrains this plan to planning artifacts only"
provides:
  - "`.planning/REQUIREMENTS.md` amended to nineteen internally consistent rows: six rewritten, three deleted with their traceability entries, coverage arithmetic 19/19/0"
  - "the phase's superseded-annotation form — a bold bracketed suffix `**[superseded by Phase 16]**` followed by a short clause naming what delivered it — first applied to CUT-01, to be reused verbatim by plans 16-08 and 16-09"
  - "`.planning/v0.3-MILESTONE-AUDIT.md` with both blockers dispositioned as closed by what actually closed them, not by their originally recorded remedies"
  - "audit evidence re-captured from the current wrapper's dry-run output, replacing quotes of deleted output strings, arrays and functions"
  - "the two genuinely open items (WR-02, the D-38 compositor-target autostart) still listed, still unowned"
affects: [16-08, 16-09, 16-10, phase-gate]

# Actuals (#2632)
actuals:
  tokens: null
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dispositioning over deletion: an audit finding keeps its identifier, severity and original issue statement, and gains `disposition` and `resolution` keys recording what actually closed it"
    - "A measurement block is left as measured: `status` and the scores stay at their audit date, and a `disposition_note` records the later state rather than rewriting the numbers"
    - "A checklist row and its traceability entry are deleted in the same edit, because a row present in one and absent from the other is worse than either state"
    - "A resolution that is the opposite of the recorded remedy is stated plainly as such, rather than being smoothed into the original plan's language"

key-files:
  created: []
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/v0.3-MILESTONE-AUDIT.md

key-decisions:
  - "INV-04 keeps its Phase 10 traceability mapping although its text was rewritten. D-26 says it stays at Phase 10; D-27 says rewritten rows map to Phase 16. The two conflict for exactly this one ID, and the specific rule governs — it is what keeps the row consistent with D-39, which deliberately leaves scripts/phase10-inventory-assert.sh requiring the retired language in the frozen Phase 10 record."
  - "The superseded-annotation form was fixed as `**[superseded by Phase 16]**` plus a short delivering clause. 16-CONTEXT.md left the wording to the executor as long as one form is used across REQUIREMENTS.md, PROJECT.md and STATE.md; plans 16-08 and 16-09 reuse this one verbatim."
  - "The three retired requirement IDs are not named anywhere in REQUIREMENTS.md, not even in the coverage note explaining the 22-to-19 drop. The plan's own orphan check bans FULL-03, FULL-05 and ADOPT-04 file-wide, so a coverage note naming them would read as an orphan. The note describes what each row promised instead, and points at 16-DOC-SWEEP.md for the identifiers."
  - "The milestone audit's `status: gaps_found` and its scores block were left as the 2026-09-06 measurement. Rewriting the scores would make the audit assert numbers it never measured; a `dispositioned` metadata block plus a `disposition_note` records the later state without restructuring the audit or erasing its findings."
  - "Flow A was retired out of the end-to-end completion count rather than left counted as broken. Its destination no longer exists, so 'broken' would misdescribe it. Flow C moved to complete, and both section headings state the audit-time and post-disposition counts side by side."
  - "W-1 and W-2 are marked resolved here with a citation to plan 16-08 and an explicit note that this plan does not pre-empt that edit — the source correction in 11-DISPOSITIONS.md belongs to 16-08."

patterns-established:
  - "An audit is dispositioned, never pruned: erasing a blocker stops the document being a record of what was found"
  - "Stale evidence is re-captured from the live artifact, not adjusted from memory"

requirements-completed: [INV-04, FULL-01, FULL-02, FULL-04, ADOPT-03, DOC-03, D-26, D-27, D-31]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "The requirement set contains nineteen rows and nineteen mappings, with coverage arithmetic that agrees"
    requirement: "D-27"
    verification:
      - kind: other
        ref: "grep 'v0.3 requirements: 19' && 'Mapped to phases: 19' && 'Unmapped: 0'; checklist row count => 19; traceability row count => 19"
        status: pass
    human_judgment: false
  - id: D2
    description: "No deleted requirement ID survives anywhere in the file as an orphan"
    requirement: "D-26"
    verification:
      - kind: other
        ref: "FULL-03, FULL-05, ADOPT-04 absent file-wide => exit 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "The mapping conflict resolves the specific way: INV-04 at Phase 10, DISP-03 untouched at Phase 11, five rewritten rows at Phase 16"
    requirement: "D-26"
    verification:
      - kind: other
        ref: "'| INV-04 | Phase 10 |' && '| DISP-03 | Phase 11 |' && five of (FULL-01|FULL-02|FULL-04|ADOPT-03|DOC-03) at Phase 16"
        status: pass
    human_judgment: false
  - id: D4
    description: "No retired claim survives in a requirement row or an out-of-scope row, and the frozen Phase 10 assert was not edited to agree with the rewrite"
    requirement: "D-39"
    verification:
      - kind: integration
        ref: "retired-claim grep alternation => no match; ./scripts/phase10-inventory-assert.sh => '=== done: FAIL=0 ==='"
        status: pass
    human_judgment: false
  - id: D5
    description: "Both blockers keep their identifiers and original issue statements and carry resolutions citing Phase 16 plans"
    requirement: "D-31"
    verification:
      - kind: other
        ref: "B-1 and B-2 present; findings carrying a Phase 16 resolution => 8 (>=4)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Every surviving citation of a deleted script, array, output string or function is marked as removed in Phase 16, and the tech-debt entry reads as closed by deletion"
    requirement: "D-33"
    verification:
      - kind: other
        ref: "stale-token loop over phase14-preflight, PROTECT_EXPLICIT, the dry-run string and list_hypr_ii_hook_target_files => no UNMARKED STALE; 'closed by deletion' present"
        status: pass
    human_judgment: false
  - id: D7
    description: "The archive-path evidence names the location that exists, and no recommendation prescribes a route back to the retired session model"
    requirement: "D-31"
    verification:
      - kind: other
        ref: "'stow/' present; '.config/{waybar,rofi,swaync}' absent; restore-route recommendation regex => no match"
        status: pass
    human_judgment: false
  - id: D8
    description: "The two genuinely open items remain listed and unowned"
    requirement: "D-31"
    verification:
      - kind: other
        ref: "WR-02 / three-roles present && graphical-session.target present && no owner assigned to either"
        status: pass
    human_judgment: false
  - id: D9
    description: "The planning-artifact edits left every owned directory untouched and the overlay assert green"
    requirement: "D-38"
    verification:
      - kind: integration
        ref: "git diff --quiet HEAD -- arch/ docs/ scripts/ .config/ stow/ vendor/ => 0; ./scripts/phase13-d19-assert.sh => 0 [FAIL]; collective-noun token count => within the baseline of 6"
        status: pass
    human_judgment: false
  - id: D10
    description: "The rewritten requirement rows and the audit's refreshed evidence faithfully describe what plans 16-01 through 16-06 actually shipped"
    verification: []
    human_judgment: true
    rationale: "Whether a rewritten requirement row states the shipped behavior — rather than a plausible-sounding neighbour of it — is a reading judgment against six prior plans. The evidence was re-captured from the current wrapper's dry-run output and each resolution cites the plan that produced it, but only a human comparing the rows against the diffs can confirm nothing was overstated."

# Metrics
duration: 15 min
completed: 2026-09-08
status: complete
---

# Phase 16 Plan 07: Milestone Bookkeeping Amended to What Shipped Summary

**The v0.3 requirement set now says what the project does — nineteen rows, nineteen mappings, three capabilities deleted along with the machinery that implemented them — and the milestone audit records what actually closed its two blockers rather than the remedies it originally proposed, both of which turned out to be the opposite of what happened.**

## Performance

- **Duration:** 15 min
- **Tasks:** 2
- **Files modified:** 2 (0 created, 2 modified)

## Accomplishments

- **Six rows rewritten, three deleted, arithmetic reconciled.** `INV-04`, `FULL-01`, `FULL-02`, `FULL-04`, `ADOPT-03` and `DOC-03` were rewritten to the shipped behavior; `FULL-03` (the backup gate and bare-flag refusal), `FULL-05` (post-install package re-marking) and `ADOPT-04` (rollback guidance) were removed from the checklist and from the traceability table in the same edit. Coverage went from 22 total / 22 mapped to 19 total / 19 mapped / 0 unmapped.
- **The one place D-26 and D-27 conflict was resolved deliberately, and the file says why.** `INV-04` was rewritten but kept its Phase 10 mapping, with a coverage note naming D-26 over D-27 and D-39 as the reason. `scripts/phase10-inventory-assert.sh` still passes with `=== done: FAIL=0 ===`, which is the property that would have broken had the row been re-mapped and the assert "fixed" to match.
- **The deleted IDs leave no orphan and no mention.** `FULL-03`, `FULL-05` and `ADOPT-04` appear nowhere in `REQUIREMENTS.md`, including in the coverage note that explains the drop — the note describes what each row promised and points at `16-DOC-SWEEP.md` for the identifiers.
- **`CUT-01` carries the phase's superseded annotation.** `**[superseded by Phase 16]**` plus a clause naming the Phase 11 D-11 decision and the Phase 14 adopt as what delivered it, and an explicit statement that it stays outside the coverage count. This is the form plans `16-08` and `16-09` reuse.
- **Two out-of-scope rows contradicted by what shipped were removed**, and the module-ports row kept its place with its reason clause reworded off the retired session model.
- **Both blockers are dispositioned, not deleted.** `B-1` and `B-2` keep their identifiers, severities and original issue statements. `B-1` closes because the wrapper flip made the opt-in flag unnecessary — plan `16-01` deleted the `SAFE_DEFAULTS` array and its injection branch, and plan `16-04` rewrote playbook section 10.3 to one flat `install-files`. `B-2` closes because the destination was retired rather than routed back to, which the resolution states plainly as the opposite of the recorded remedy and as deliberate.
- **The audit's measurement is left as measured.** `status: gaps_found` and the scores block are untouched at their 2026-09-06 values; a `dispositioned` / `dispositioned_by` / `disposition_note` block records the later state. An audit that rewrites its own scores stops being a measurement.
- **Stale evidence was re-captured from the live wrapper.** Quotes of deleted output strings, the deleted `PROTECT_EXPLICIT` array and `list_hypr_ii_hook_target_files (arch/dots-hyprland.sh:651-665)` are either refreshed from the current dry-run output or kept as the historical statement with a note that Phase 16 removed the machinery. The archive-path evidence now names `stow/waybar`, `stow/rofi`, `stow/swaync` instead of a `.config/` directory set that does not exist.
- **The flow section was restated honestly rather than upgraded silently.** Flow A left the completion count as **retired** — its destination no longer exists, so calling it broken would misdescribe it — Flow B was restated, and Flow C moved to complete because its apply hop is now one flat `install-files`. Both section headings state the audit-time and post-disposition counts side by side: `1/3 complete at audit time; 2/2 after the Phase 16 dispositions, with one flow retired`.
- **The tech-debt entry closed by deletion.** `IN-11` is recorded as retired rather than paid: `scripts/phase14-preflight.sh` was deleted whole in plan `16-03`, and the original entry is kept verbatim as the record of what the debt was.
- **The unowned counts were recomputed, not patched in one place.** Both statements of the count moved from 3 to 2 together. `WR-02` and the D-38 `graphical-session.target` autostart are still listed as open with no owner invented for either.

## Task Commits

Each task was committed atomically:

1. **Task 1: Amend the requirement set and its traceability table** — `cb73968` (docs)
2. **Task 2: Disposition the milestone audit's blockers and clear its stale evidence** — `993be6d` (docs)

## Files Created/Modified

- `.planning/REQUIREMENTS.md` — `+24/−24`. Six rewritten checklist rows, three deleted rows with their three traceability entries, five re-mappings to Phase 16, the `CUT-01` superseded annotation, two out-of-scope deletions and one reason-clause reword, and the coverage block rewritten to 19/19/0 with a note explaining the drop.
- `.planning/v0.3-MILESTONE-AUDIT.md` — `+199/−88`. A `dispositioned` metadata block; `disposition` and `resolution` keys on `B-1`, `B-2`, `W-1`, `W-2`, `W-3` and the disposition-row evidence; refreshed integration-flow evidence; Flow A retired, Flow C complete, both counts restated in their headings; the `IN-11` tech-debt entry closed by deletion; the recommended-closure section rewritten to what the phase did, with the two open items left unowned.

## Decisions Made

- **`INV-04` stays at Phase 10.** D-26 (specific) governs over D-27 (general) for this one ID, because the row records what Phase 10 captured and `scripts/phase10-inventory-assert.sh` deliberately still verifies that frozen record under D-39.
- **The superseded annotation is `**[superseded by Phase 16]**` followed by a delivering clause.** 16-CONTEXT.md left the wording open provided one form is used across the three files; this fixes it for plans `16-08` and `16-09`.
- **The coverage note names no retired ID.** The plan's own orphan check bans them file-wide, so naming them in the explanation would trip it. The note describes the promises instead and cites `16-DOC-SWEEP.md`.
- **The audit's scores were not recomputed.** Dispositioning in place with an added metadata block records the later state without making the document assert a measurement it never took.
- **Flow A was retired, not repaired.** Leaving it counted as broken would misdescribe a flow whose destination no longer exists.

## Deviations from Plan

None — both tasks executed as written, and all ten `<verify>` blocks pass.

## Issues Encountered

- **The executing agent was terminated after its second commit, before it wrote this summary.** Both task commits (`cb73968`, `993be6d`) and its `.planning/STATE.md` edit were already on disk; the agent's own process was killed by a session-level context compaction roughly two hours before the orchestrator next checked on it, so it never emitted a completion signal, never wrote `16-07-SUMMARY.md`, never committed `STATE.md` and never ticked the roadmap row.
- **The orchestrator closed the plan out rather than re-executing it.** All ten `<verify>` blocks from both tasks were re-run against the committed tree and all ten pass, so the work itself was complete and verified; re-executing would have redone correct work against files it had already amended. This summary, the `STATE.md` commit and the roadmap tick were written by the orchestrator from the plan, the two commits and the agent's own recorded decisions.
- **One verify command cannot run under `ugrep`.** Task 2's third check uses `grep -qiE '(write|document|add)[^.]{0,60}restore[^.]{0,40}dual-run'`, which this machine's `grep` (ugrep) rejects with `error at position 654 … exceeds complexity limits`. Because the clause is negated with `!`, the error makes the check pass vacuously. It was re-verified with an equivalent Python `re.findall`, which returns no matches — the check genuinely passes. Any later plan reusing that alternation should expect the same vacuous pass.
- **`actuals.tokens` is unrecorded.** The agent's token accounting was lost with its process.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **The roadmap's coverage line still reads 22 and is corrected by plan `16-09`.** `REQUIREMENTS.md` now says 19; until `16-09` lands, the two documents disagree by design, and that disagreement is the plan's own stated hand-off.
- **Plan `16-08` owns the source corrections for W-1 and W-2.** The audit marks both resolved and cites `16-08`; `11-DISPOSITIONS.md` itself is still unedited, and this plan deliberately did not pre-empt it.
- **The superseded-annotation form is fixed** and must be reused verbatim by `16-08` (`PROJECT.md`) and `16-09` (`STATE.md`).
- **The standing constraints still bind.** `arch/dots-hyprland.sh` must not be touched, and `16-DOC-SWEEP.md` must not be moved or renamed; both remain load-bearing for `scripts/phase13-d19-assert.sh`.
- **`WR-02` and the D-38 autostart stay open and unowned** in the audit, matching their treatment in the sweep record.

---
*Phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook*
*Completed: 2026-09-08*

## Self-Check: PASSED

- `.planning/REQUIREMENTS.md` — present on disk, 19 rows / 19 mappings
- `.planning/v0.3-MILESTONE-AUDIT.md` — present on disk, both blockers dispositioned
- `16-07-SUMMARY.md` — present on disk
- Commits `cb73968`, `993be6d` — both present in `git log`
