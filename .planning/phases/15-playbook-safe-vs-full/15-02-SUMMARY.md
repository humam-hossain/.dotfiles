---
phase: 15-playbook-safe-vs-full
plan: 02
subsystem: docs
tags: [hyprland, dots-hyprland, illogical-impulse, quickshell, markdown, operator-playbook, install-profiles, process-gate]

# Dependency graph
requires:
  - phase: 15-playbook-safe-vs-full
    provides: "plan 15-01's corrected verification block, the retitled section 4, and the ground-truth rulings (probe of record, backup of record, 15-CONTEXT.md frozen under D-22)"
  - phase: 11-disposition-decisions
    provides: "`11-DISPOSITIONS.md` section 6 — the D-11 accept-remove for Waybar / rofi / swaync and the D-12 archive policy"
  - phase: 10-full-install-impact-inventory
    provides: "`10-INVENTORY.md` — the source of truth for what a full install touches, cited by the new gate section"
provides:
  - "`## Profiles: safe vs full` in `docs/dots-hyprland-workflow.md` — the safe definition, the full definition, and the three-row flag-axis table"
  - "The D-07 statement, in that section rather than a footnote: the wrapper default is still safe and `--full` is opt-in"
  - "`## 3. Required gate before any full install` — inventory → disposition → adopt, written before the install step so the ordering is provable by line number"
  - "A renumbered spine (1, 2, 3, 4, 5, 10, 11) with 6–9 reserved for plans 15-04 and 15-05, and an Outline that resolves at this commit"
  - "A Purpose and Prerequisites that address a cold machine, with two of D-10's three stale claims deleted"
affects: [15-04, 15-05, 15-06, doc-sweep]

actuals:
  tokens: 4623
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Gate-ordering asserted by line-number comparison (`first 10-INVENTORY.md mention` < `first ./arch/dots-hyprland.sh install` line) rather than by review"
    - "Extract-and-compare agreement check: `grep -oP '^SAFE_DEFAULTS=\\(\\K[^)]+' arch/dots-hyprland.sh` piped into `grep -qF` against the doc, so wrapper drift breaks the check instead of the reader"
    - "Reserved section numbers (6–9 unused) so every intermediate commit has a resolving Outline and no later renumber pass is needed"

key-files:
  created: []
  modified:
    - docs/dots-hyprland-workflow.md

key-decisions:
  - "The Purpose pointer to the profiles section is written as a backticked heading name, not a Markdown anchor link, so the Task 1 commit does not carry a link to a heading that Task 2 had not yet created."
  - "The Outline entries keep the literal section numbers 10 and 11 rather than renumbering to 6 and 7, because the entry number must match the `## N.` heading it names; GitHub renders an ordered list sequentially, so this reads 1–7 until 15-05 fills 6–9."
  - "The Non-goals row describing the Waybar / rofi / swaync removal as out of scope was corrected here rather than deferred, because Task 2's acceptance criterion requires the file as a whole not to describe that removal as out of scope."
  - "The `docs/phase14-adopt-runbook.md` citation is the one carried into Purpose as the record of the 2026-09-04 adopt window (D-02, D-04); no runbook content is copied and the file is not touched — plan 15-03 owns it in this wave."

patterns-established:
  - "Profile definition next to profile definition on a single spine (D-03 + D-06): safe and full are two `###` subsections and one shared table inside one `##` section, never two parallel tracks."
  - "A process gate is placed by line number, not by prose emphasis: if the gate must precede the install, the check compares the two line numbers."

requirements-completed: [DOC-03]

coverage:
  - id: D1
    description: "Purpose and Prerequisites address a cold machine; the dual-run destination claim and the unconditional `hyprland.conf` claim are gone, and the DRY callout still names the wrapper help as the syntax SoT"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "! grep -qF 'wrapper defaults **do not** replace' && ! grep -qF 'reach dual-run' && grep -qF './arch/dots-hyprland.sh help' && grep -q 'phase14-adopt-runbook.md' && grep -qi 'profiles' — docs/dots-hyprland-workflow.md"
        status: pass
    human_judgment: false
  - id: D2
    description: "`## Profiles: safe vs full` exists between Prerequisites and Canonical path, quotes the live SAFE_DEFAULTS array byte-for-byte, and carries exactly three flag-axis table rows"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "SD=$(grep -oP '^SAFE_DEFAULTS=\\(\\K[^)]+' arch/dots-hyprland.sh); grep -qF -- \"$SD\" docs/dots-hyprland-workflow.md — pass"
        status: pass
      - kind: other
        ref: "grep -cE '^\\| *`--(skip-hyprland|core|skip-sysupdate)`' == 3"
        status: pass
    human_judgment: false
  - id: D3
    description: "The D-07 statement is present in the profiles section: the wrapper default is still safe and `--full` is opt-in, with the wrapper's own help sentence quoted"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "grep -qiE 'default.*(safe|SAFE_DEFAULTS)' docs/dots-hyprland-workflow.md — pass"
        status: pass
    human_judgment: false
  - id: D4
    description: "`## 3. Required gate before any full install` is a precondition, not a postscript: the first `10-INVENTORY.md` mention precedes the first wrapper install command line"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "line-number comparison — 10-INVENTORY.md at line 156 < ./arch/dots-hyprland.sh install at line 177"
        status: pass
    human_judgment: false
  - id: D5
    description: "The spine is renumbered 1, 2, 3, 4, 5, 10, 11; the Outline lists exactly those seven sections and every in-page anchor resolves"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "anchor-resolution loop (no MISSING ANCHOR lines) + grep -cE '^## [0-9]+\\. ' == 7 + grep -cE '^[0-9]+\\. \\[' == 7"
        status: pass
      - kind: other
        ref: "relative-link resolution loop over docs/dots-hyprland-workflow.md — exit 0, no BROKEN lines"
        status: pass
    human_judgment: false
  - id: D6
    description: "No file under `arch/`, `scripts/`, `.config/`, `stow/`, `vendor/` changed, `STATE.md` / `ROADMAP.md` untouched, and the Phase 13 regression floor still holds"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "git diff --quiet HEAD -- <fenced paths> (exit 0); ./scripts/phase13-d19-assert.sh — exit 0, 15 [PASS], 0 [FAIL]"
        status: pass
    human_judgment: false
  - id: D7
    description: "A reader can actually decide between the two profiles from the one section — the framing does not read as a recommendation of full by omission"
    verification:
      - kind: manual_procedural
        ref: "read docs/dots-hyprland-workflow.md `## Profiles: safe vs full` end to end and confirm the safe-is-default statement lands before the reader reaches the full walkthrough"
        status: unknown
    human_judgment: true
    rationale: "The grep proves the D-07 sentence exists; it cannot prove the section reads as a neutral choice rather than as a nudge toward `--full`. T-15-06 is a framing threat, and framing is only assessable by a human reading the section in order."

# Metrics
duration: 10min
completed: 2026-09-06
status: complete
---

# Phase 15 Plan 02: Profiles, flag axes and the pre-install gate Summary

**The playbook now defines safe and full side by side with a three-row flag-axis table quoted byte-for-byte from the wrapper, states in that same section that safe is still the default, and puts the inventory → disposition → adopt gate 21 lines ahead of the first install command so the ordering is provable rather than asserted.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-09-06T05:52:00Z (approximate — agent spawn)
- **Completed:** 2026-09-06T06:01:00Z
- **Tasks:** 3 of 3
- **Files modified:** 1

Estimate calibration note: `actuals.tokens: 4623` is chars/4 over the single file actually changed (18,493 chars); the realized diff alone is ~14,000 chars ≈ 3,500 estimate-tokens. Both are far under the plan's `estimate.tokens: 55000`, which was authored at `confidence: low` and priced three prose sections plus a full-spine renumber as if each needed the whole file rewritten. In practice all three tasks were bounded in-place substitutions plus one insertion. This is the second consecutive plan in this phase to come in at roughly a tenth of estimate — the phase's estimator is pricing documentation edits as if they were file rewrites.

## Accomplishments

- Added `## Profiles: safe vs full` between `## Prerequisites` and `## Canonical path`: what the wrapper injects (`--core --skip-hyprland --skip-sysupdate`, quoted from `arch/dots-hyprland.sh:12`), the `install` / `install-files`-only injection scope in the wrapper's own words, what safe does not touch, and what `--full` drops — one section on the one spine, not a second track.
- Put the D-07 statement where a reader deciding between profiles will hit it, in bold and in that section: **the wrapper default is still safe, and `--full` is opt-in**, backed by the wrapper help's own sentence "Default install / install-files without `--full` still inject the triple", with the full walkthrough labelled a documentation choice rather than a default change.
- Wrote `## 3. Required gate before any full install` as three ordered steps citing `10-INVENTORY.md` and `11-DISPOSITIONS.md` as this machine's worked instance, and placed it before the install section so the check is a line-number comparison (gate at 156, first `./arch/dots-hyprland.sh install` at 177) rather than a reading.
- Renumbered the spine to 1, 2, 3, 4, 5, 10, 11 with 6–9 reserved for plans 15-04 and 15-05, rewrote the Outline to exactly the seven sections that exist at this commit, and updated the three in-body cross-references that carried old numbers.
- Deleted two of D-10's three stale claims — the Purpose promise that a cold machine reaches dual-run as its destination, and the Prerequisites assertion that wrapper defaults unconditionally leave `hyprland.conf` alone — and corrected the install section's hooks paragraph, which claimed the hooks land in both the live and the repo `hyprland.conf` when the live file no longer exists.

## Task Commits

1. **Task 1: Rewrite Purpose and Prerequisites for a cold machine** — `2f36072` (docs)
2. **Task 2: Add the Profiles section with the three-row flag-axis table** — `eae9ead` (docs)
3. **Task 3: Insert the required pre-install gate and renumber the spine** — `fe931cc` (docs)

**Plan metadata:** see the final `docs(15-02)` commit carrying this SUMMARY.

## Files Created/Modified

- `docs/dots-hyprland-workflow.md` — the only file this plan touched.
  - Purpose (lines 14–19): destination claim replaced with the Install/Adopt SoT sentence plus a two-sentence, clearly secondary note that this machine took the full adopt on 2026-09-04, citing `docs/phase14-adopt-runbook.md`; the DRY callout gained a second blockquote line naming the flags this doc weighs and re-naming `./arch/dots-hyprland.sh help` as the syntax SoT.
  - Prerequisites (line 26): the Hyprland bullet is now profile-conditional and defers the fate of `hyprland.conf` to the profiles section.
  - `## Profiles: safe vs full` (lines 29–63): new. Two `###` subsections and the `### Flag axes` table.
  - `## 3. Required gate before any full install` (lines 152–164): new.
  - Spine: `## 3. Install via thin wrapper (dry-run → live)` → `## 4. Install via the thin wrapper`; `## 4. Session model & verification` → `## 5. Session model after a full install`; `## 5. Update contract (pin-bump)` → `## 10.` with `5.1`–`5.4` → `10.1`–`10.4`; `## 6. Non-goals / non-primary paths` → `## 11.`.
  - Cross-references: `[§6 Non-goals](#6-non-goals--non-primary-paths)` → `§11`; "use manual dual-run checks in §4" → "use the session checks in §5"; "**Bottom line:** update with **§5 pin-bump**" → **§10**.
  - Hooks paragraph and the Non-goals Waybar / rofi / swaync row — see Deviations below.

## Decisions Made

- **The Task 1 pointer to the profiles section is prose, not a link.** Task 1 commits before Task 2 creates the heading. A Markdown anchor written in Task 1 would have pointed at a non-existent heading for one commit, which is exactly what D-23 and the plan's reserved-numbers reasoning try to avoid. The pointer is a backticked heading name and stays readable either way.
- **Outline entries keep the literal numbers 10 and 11.** The alternative — renumbering the entries 1–7 while the sections read 10 and 11 — would make the Outline entry number disagree with the heading it links to. Since CommonMark renumbers ordered lists on render, GitHub will show these as 6 and 7 until plan 15-05 fills sections 6–9; the link text and target are correct throughout, which is what the anchor check and a reader both need.
- **`§9` is referenced before it exists.** The plan's Task 3 instruction requires the hooks paragraph to point at section 9 for what the repo `.config/hypr/hyprland.conf` is for. Section 9 is plan 15-05's (D-18 / WR-02). This is a deliberate forward reference recorded under Known Stubs, not an oversight; it is plain text, so it does not break in-page link integrity at this commit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Self-contradiction introduced by Task 2] Non-goals still described the Waybar / rofi / swaync removal as out of scope**

- **Found during:** Task 3 (discovered while renumbering section 11; the contradiction was created by Task 2)
- **Issue:** After Task 2 the file said, in `## Profiles: safe vs full`, that the removal of `Waybar`, `rofi` and `swaync` under the full profile "was explicitly accepted by Phase 11 D-11", while the Non-goals table still carried the row `| **Full Waybar / rofi / swaync cutover** | Out of scope this milestone | Dual-run is intentional; custom ports deferred (CUST-*). |`. Task 2's own acceptance criterion is that the file "cites `11-DISPOSITIONS.md` for the accept-remove decision **and does not describe the removal as out of scope**", and T-15-10 in the plan's threat register is precisely this repudiation risk. `15-RESEARCH.md` flags the same row (line 293 of the pre-edit file) as stale for the same reason.
- **Fix:** Rewrote that one row to `| **Waybar / rofi / swaync custom module ports** | Deferred (CUST-01..03) | …the removal … was explicitly accepted by Phase 11 D-11 (…11-DISPOSITIONS.md section 6). Only the module *ports* remain deferred. |`. Two cells, one row; no other row touched. This stays inside `REQUIREMENTS.md`'s Out of Scope, whose rows defer the *module ports* (CUST-01..03) and make the default-keep of the surfaces conditional on "if DISP-03 explicitly accepts" — which Phase 11 D-11 did.
- **Files modified:** `docs/dots-hyprland-workflow.md`
- **Verification:** `grep -q '11-DISPOSITIONS.md'`, the literal `Waybar` / `\brofi\b` / `swaync` checks and the zero-`chrome` allowlist check all still pass; the row is not a heading so no anchor or count changed.
- **Committed in:** `fe931cc`

**2. [Rule 1 — Stale cross-reference] Three in-body section references still named the old numbers**

- **Found during:** Task 3
- **Issue:** The renumber left `[§6 Non-goals](#6-non-goals--non-primary-paths)` pointing at a slug no heading produces any more (this one would have failed the anchor check outright), plus two plain-text references — "use manual dual-run checks in §4" in the Non-goals table and "**Bottom line:** update with **§5 pin-bump**" — that silently pointed at the wrong sections.
- **Fix:** Updated all three to §11, §5 and §10 respectively. The §4 reference also lost the phrase "dual-run checks", which D-09 bans as a description of the post-adopt session; it now reads "the session checks in §5".
- **Files modified:** `docs/dots-hyprland-workflow.md`
- **Verification:** Anchor-resolution loop prints no `MISSING ANCHOR` lines.
- **Committed in:** `fe931cc`

### Not fixed — left for the plan that owns it

**`## 11. Non-goals` still carries a directly false row:** `| **Full hyprland.lua / ii hypr tree takeover** | Out of scope this milestone | Personal hypr conf remains SoT via --skip-hyprland. |`. This is exactly what the Phase 14 adopt did, and `15-RESEARCH.md` flags it (pre-edit line 294). It is not required by any acceptance criterion in this plan, it is not a contradiction this plan introduced, and section 11 is rewritten in a later plan — so per the executor scope boundary it was left alone rather than opportunistically edited. **Owner: plan `15-05`** (or `15-06`'s sweep if 15-05's scope does not reach the Non-goals table).

---

**Total deviations:** 2 auto-fixed (both Rule 1), 1 out-of-scope finding recorded and deferred
**Impact on plan:** No scope creep. Both fixes are inside `docs/dots-hyprland-workflow.md`, the plan's only declared file, and both were required to keep the file internally consistent after the plan's own edits.

## Issues Encountered

None requiring problem-solving. Two mechanical notes:

- The `SAFE_DEFAULTS` agreement check extracts `--core --skip-hyprland --skip-sysupdate` from `arch/dots-hyprland.sh:12` at check time and requires a byte-identical `grep -qF` hit in the doc. It passed on the first run; the value is inside a `text` fence per the repo's literal-value convention, so a future wrapper change will break the check rather than the reader.
- The `\brofi\b` word boundary earned its keep: after this plan the file contains "profile" 30-odd times, and an unanchored `rofi` grep would have passed regardless of whether the surface was ever named.

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| Forward reference to `§9` | `docs/dots-hyprland-workflow.md` | ~222 (hooks paragraph) | Plan-mandated (Task 3): the hooks paragraph points at section 9 for what the repo `.config/hypr/hyprland.conf` is for. Section 9 is plan `15-05`'s deliverable (D-18 / WR-02). Plain text, not a link, so in-page link integrity holds at this commit. |
| Section numbers 6–9 reserved and unused | `docs/dots-hyprland-workflow.md` | Outline + spine | Deliberate (plan assumption A-02-1). `15-04` adds 6 and 7, `15-05` adds 8 and 9. The Outline lists only existing sections at every commit, so D-23 holds throughout; the cost is that GitHub renders the last two Outline entries as 6 and 7 rather than 10 and 11 until the gap is filled. |

Neither stub blocks this plan's goal: a reader can choose a profile and cannot reach `--full` without the gate, which is what DOC-03's first success criterion asks for.

_No `.planning/WINDOWS.md` ledger exists in this project, so the two entries above are recorded here only._

## Threat Flags

None. Documentation-only phase; no network, auth, file-access or schema surface is introduced. The mitigations this plan owns in the threat register are in place:

- **T-15-06** (framing spoofs full as the default): the bold D-07 sentence sits in `## Profiles: safe vs full`, asserted by `grep -qiE 'default.*(safe|SAFE_DEFAULTS)'`, with the walkthrough labelled a documentation choice in the same section. The residual — whether it *reads* neutral — is coverage entry D7, flagged for human judgment.
- **T-15-07** (table drifts from `arch/dots-hyprland.sh:12`): extract-and-compare check, passing.
- **T-15-08** (reader reaches `--full` without the gate): gate at line 156, first install command at line 177, asserted by line-number comparison.
- **T-15-09** (fenced directories): `git diff --quiet HEAD -- arch/ scripts/ .config/ stow/ vendor/ .planning/STATE.md .planning/ROADMAP.md` clean after every task; `./scripts/phase13-d19-assert.sh` exit 0, 15 `[PASS]`, 0 `[FAIL]`.
- **T-15-10** (removal described as out of scope): closed, including the Non-goals row — see Deviation 1.

## User Setup Required

None.

## Next Phase Readiness

Ready. The spine, the Outline contract and the profile vocabulary the remaining plans write against are now on disk.

Notes for the plans that follow:

- **`15-04`** owns sections 6 and 7, the D-08 demotion of `### Personal hypr hooks (two lines)` / `### Live product path` (15-01's DIV-2), and D-10's third stale claim — the "No Waybar cutover required for this milestone" framing, which still lives inside section 5. Section 5 is titled `Session model after a full install` but still opens with the pre-adopt conf-hook subsections; that mismatch is 15-04's to close.
- **`15-05`** owns sections 8 and 9, the final Outline once 6–9 exist (which also resolves both Known Stubs above), and the false `hyprland.lua takeover` Non-goals row recorded under "Not fixed" above.
- **`15-06`** should carry Deviation 1 and the deferred Non-goals row into `15-DOC-SWEEP.md`, and runs `./scripts/phase14-verify.sh` at the phase gate.
- `.planning/STATE.md` and `.planning/ROADMAP.md` were deliberately not written by this executor; the orchestrator owns those updates.

## Self-Check: PASSED

| Claim | Result |
|---|---|
| `docs/dots-hyprland-workflow.md` | FOUND |
| `.planning/phases/15-playbook-safe-vs-full/15-02-SUMMARY.md` | FOUND |
| commit `2f36072` | FOUND |
| commit `eae9ead` | FOUND |
| commit `fe931cc` | FOUND |

---
*Phase: 15-playbook-safe-vs-full*
*Completed: 2026-09-06*
