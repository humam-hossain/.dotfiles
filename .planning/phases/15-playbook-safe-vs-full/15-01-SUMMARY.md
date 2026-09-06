---
phase: 15-playbook-safe-vs-full
plan: 01
subsystem: docs
tags: [hyprland, dots-hyprland, illogical-impulse, quickshell, markdown, operator-playbook, rollback]

# Dependency graph
requires:
  - phase: 14-live-full-adopt-verify
    provides: "the live full adopt, `scripts/phase14-verify.sh` as executable SoT, `14-PRE-ADOPT-BASELINE.txt` fixture hashes, and `docs/phase14-adopt-runbook.md` §14 rollback"
  - phase: 13-personal-hypr-custom-overlays
    provides: "`.config/hypr/custom/` overlay SoT and `scripts/phase13-d19-assert.sh` as the regression floor"
provides:
  - "A corrected, runnable post-login verification block in `docs/dots-hyprland-workflow.md` §4, reachable from `README.md`"
  - "Section 4 retitled `Session model & verification` with the Outline anchor `#4-session-model--verification`"
  - "`.planning/PROJECT.md` product-surface lines true post-adopt (working probe, correct backup directory)"
  - "`15-DOC-SWEEP.md` seeded with three applied corrections and their evidence"
  - "Runbook §14 tier-1 source 3 pointed at the backup that actually holds the pre-adopt config"
affects: [15-02, 15-03, 15-04, 15-05, 15-06, doc-sweep, rollback-procedure]

actuals:
  tokens: 15003
  tasks: 2
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "In-fence `# expect:` idiom for command + expected output (15-PATTERNS.md)"
    - "Inlined shell assertions in plan `<verify>` blocks instead of a new `scripts/phase15-*.sh` (phase scope fence forbids new scripts)"

key-files:
  created:
    - .planning/phases/15-playbook-safe-vs-full/15-DOC-SWEEP.md
  modified:
    - README.md
    - docs/dots-hyprland-workflow.md
    - docs/phase14-adopt-runbook.md
    - .planning/PROJECT.md

key-decisions:
  - "Task 1 gate resolved `verified`: write the machine-checked ground truth over the literal text of locked decisions D-08 / D-14 / D-15."
  - "The compositor probe of record is `hyprctl -j status | jq -r .configProvider` → `lua`; `hyprctl getoption configProvider` returns `no such option` on Hyprland 0.56.2 and is banned from all four operator-facing docs."
  - "The adopt backup of record is `~/ii-original-dots-backup`; the timestamped `…20260904T171128Z` directory is the rotated stale backup and is not a rollback source."
  - "Correction 3 (runbook §14 tier-1 source 3) is executed in this plan under D-21, not deferred — the `verified` option was chosen over `split`."
  - "`15-CONTEXT.md` lines 30, 39, 40 and 127 keep their errors: it is a frozen artifact under D-22, flagged in the sweep record rather than edited."

patterns-established:
  - "Tracer doc slice: one corrected fact asserted to agree across every doc layer (entry pointer → playbook → planning prose → sweep record) before any layer is expanded."
  - "Two-sided scope fence for documentation phases: `git diff --quiet HEAD` for uncommitted changes plus a `<plan-commit>..HEAD` range check for committed ones."
  - "Allowlist-based forbidden-token guard (`grep -vx 'google-chrome-stable'`) with a pinned expected count, so silently editing a frozen historical record fails the same gate as adding a new occurrence."

requirements-completed: [DOC-03]

coverage:
  - id: D1
    description: "The playbook's post-login verification block runs the probe that exists on this machine and names `scripts/phase14-verify.sh` as its executable source of truth"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "grep -q -- '-j status' && grep -q 'configProvider' && grep -q 'phase14-verify.sh' docs/dots-hyprland-workflow.md"
        status: pass
      - kind: other
        ref: "grep -l 'getoption configProvider' across the four operator-facing docs returns empty"
        status: pass
    human_judgment: false
  - id: D2
    description: "Section 4 retitled and its Outline entry updated; every in-page anchor in the playbook resolves to a heading under the GitHub slug transform"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "anchor-resolution loop over docs/dots-hyprland-workflow.md — exit 0, no MISSING ANCHOR lines"
        status: pass
    human_judgment: false
  - id: D3
    description: "`README.md` cold-clone pointer is profile-neutral and no longer promises dual-run as the destination; the line 9 link is unchanged"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "! grep -q 'dual-run' README.md; relative-link resolution loop over README.md exits 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "`.planning/PROJECT.md` product-surface lines state the working probe and the recoverable backup directory"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "grep -q 'configProvider: lua' .planning/PROJECT.md; ! grep -qE 'ii-original-dots-backup\\.[0-9]{8}T' .planning/PROJECT.md"
        status: pass
      - kind: other
        ref: "non-allowlisted chrome-token count in .planning/PROJECT.md == 3 (frozen historical records intact)"
        status: pass
    human_judgment: false
  - id: D5
    description: "`15-DOC-SWEEP.md` exists with its three headings and records the applied corrections with evidence"
    requirement: DOC-03
    verification:
      - kind: other
        ref: "test -s + grep for '## Corrections applied', '## Reviewed, no findings', '## Flagged, not edited (D-22)'"
        status: pass
    human_judgment: false
  - id: D6
    description: "Runbook §14 tier-1 source 3 names `~/ii-original-dots-backup/` and warns off the rotated timestamped directory"
    verification:
      - kind: manual_procedural
        ref: "read docs/phase14-adopt-runbook.md tier 1, source 3; sha256 evidence in 15-DOC-SWEEP.md"
        status: unknown
    human_judgment: true
    rationale: "This edit sits inside a recovery procedure that is only exercised on a broken desktop. No automated check can confirm an operator following the corrected line actually recovers; a human must read the tier-1 block end to end and confirm the restore ordering still makes sense after the substitution."
  - id: D7
    description: "No file under `arch/`, `scripts/`, `.config/`, `stow/` or `vendor/` changed, and `.planning/STATE.md` / `.planning/ROADMAP.md` are untouched by this plan's commits"
    verification:
      - kind: other
        ref: "git diff --quiet HEAD -- <fenced paths> (exit 0); git diff --name-only 6e2ae94..HEAD lists exactly the 5 intended files"
        status: pass
      - kind: other
        ref: "./scripts/phase13-d19-assert.sh — exit 0, 15 [PASS], 0 [FAIL]"
        status: pass
    human_judgment: false

# Metrics
duration: 16min
completed: 2026-09-06
status: complete
---

# Phase 15 Plan 01: Doc-chain ground truth Summary

**One corrected fact — the compositor is on the Lua entry and `hyprctl -j status` is the probe that shows it — now agrees across the README pointer, the operator playbook, `.planning/PROJECT.md` and the new sweep record, and the runbook no longer sends a recovering operator to a stale config.**

## Performance

- **Duration:** ~16 min
- **Started:** 2026-09-06T05:35:00Z (approximate — this is a continuation agent; the plan's first run stopped at the Task 1 gate without committing)
- **Completed:** 2026-09-06T05:50:55Z
- **Tasks:** 2 of 2 (Task 1 resolved at the human gate, Task 2 executed)
- **Files modified:** 5 (4 modified, 1 created)

Estimate calibration note: `actuals.tokens: 15003` is chars/4 over the five files actually changed (60,010 chars). The realized diff alone is 11,250 chars ≈ 2,813 estimate-tokens. Both are far under the plan's `estimate.tokens: 45000`, which was authored at `confidence: low` and priced the gate plus a full-file rewrite of section 4; the executed edit was a bounded in-place replacement of one subsection.

## Accomplishments

- Replaced the playbook's dual-run subsection with a `### Verify the session after login` block carrying the six corrected checks in the repo's in-fence `# expect:` idiom, and retitled section 4 to `Session model & verification` with the Outline anchor updated to match.
- Removed the dead `hyprctl getoption configProvider` spelling from every operator-facing doc; the probe of record is now `hyprctl -j status | jq -r .configProvider` → `lua`, matching what `scripts/phase14-verify.sh:168-173` actually runs.
- Corrected the rollback source of record to `~/ii-original-dots-backup` in `.planning/PROJECT.md` **and** inside `docs/phase14-adopt-runbook.md` §14 tier 1, where the prior text sent a mid-rollback operator to the rotated July config.
- Made `README.md`'s cold-clone pointer profile-neutral (clone → recursive submodule → gate → install → session → verify → pin-bump update), dropping dual-run as the promised destination.
- Created `15-DOC-SWEEP.md` with all three corrections recorded against their evidence (live probe output, `scripts/phase14-verify.sh` line cites, sha256 comparison against `14-PRE-ADOPT-BASELINE.txt`, `arch/dots-hyprland.sh:21`).

## Task Commits

1. **Task 1: Confirm the three ground-truth deviations from locked decisions D-08 / D-14 / D-15** — no commit (a `checkpoint:decision` gate; resolved `verified` by the operator, carried into the commits below)
2. **Task 2 (tracer), Correction 3 half: runbook rollback fix** — `f8e8174` (fix)
3. **Task 2 (tracer), doc-chain half: README + playbook + PROJECT.md + sweep record** — `fd1e684` (docs)

**Plan metadata:** see the final `docs(15-01)` commit carrying this SUMMARY.

## Files Created/Modified

- `.planning/phases/15-playbook-safe-vs-full/15-DOC-SWEEP.md` — **created.** The phase's findings surface (D-20, D-22): a scope statement, a `## Corrections applied` table with three evidenced rows, and empty `## Reviewed, no findings` / `## Flagged, not edited (D-22)` sections for plan `15-06` to fill.
- `docs/dots-hyprland-workflow.md` — section 4 retitled (line 172) with its Outline entry (line 41); the `### Dual-run (intentional this milestone)` subsection and its soft process-check fence replaced by `### Verify the session after login` at line 193.
- `docs/phase14-adopt-runbook.md` — §14 tier-1 source 3 rewritten in place to name `~/ii-original-dots-backup/`, cite the matching fixture sha256, warn explicitly off the rotated timestamped directory, and carry the `cp -a` line sources 1 and 2 already had.
- `.planning/PROJECT.md` — line 18 now reads `hyprctl -j status` → `configProvider: lua` with the pre-adopt `hyprlang` value named; line 28 names `~/ii-original-dots-backup`.
- `README.md` — line 7 pointer sequence made profile-neutral; line 9 link untouched.

## Decisions Made

Task 1's gate was the plan's one architectural decision and it was answered by the operator, not by this executor. Choosing `verified` means the doc chain is now written against machine-checkable ground truth rather than against the literal text of D-08 / D-14 / D-15, and that `15-CONTEXT.md` keeps its wrong lines (30, 39, 40, 127) as a frozen artifact under D-22.

The one judgment call left to the executor was commit granularity. The runbook correction was split into its own commit ahead of the doc-chain commit because it is the phase's highest-severity finding, is authorised by a different decision (D-21 rather than D-01/D-15), and is the one change a reviewer or `/gsd-undo` would most plausibly want to isolate. The sweep record then lands in the second commit already citing a committed fix rather than an uncommitted one.

## Deviations from Plan

### 1. [Human decision — Task 1 gate] Correction 3 executed here rather than deferred to plan 15-03

- **Found during:** Task 1 (the `checkpoint:decision` gate)
- **Issue:** The plan's `files_modified` frontmatter and Task 2's `<files>` list both omit `docs/phase14-adopt-runbook.md`, and the `split` option existed precisely to defer that edit. The operator chose `verified` over `split`, and the resume instruction states Correction 3 is in scope for this plan under D-21.
- **Fix:** Corrected `docs/phase14-adopt-runbook.md` §14 tier-1 source 3 in place — minimal edit, no content moved, no restructuring (D-02 preserved). Added a third row to `15-DOC-SWEEP.md`'s `## Corrections applied` table (the plan specified two).
- **Files modified:** `docs/phase14-adopt-runbook.md`, `.planning/phases/15-playbook-safe-vs-full/15-DOC-SWEEP.md`
- **Verification:** The file was already inside the plan's verify surface (the dead-spelling ban and the relative-link check both name it); both still pass. The rotated-backup regex ban is scoped to the playbook and `PROJECT.md`, so the runbook may still name the timestamped directory as the stale rotated backup, which is what the corrected text does.
- **Committed in:** `f8e8174`

### 2. [DIV-1 — carried forward from the plan] Gate emitted as `checkpoint:decision`, not `checkpoint:human-verify`

- **Found during:** Planning; recorded here per the resume instruction.
- **Issue:** The spawn instruction asked for a `checkpoint:human-verify` before any corrected string is written. `workflow.human_verify_mode` is `end-of-phase` in `.planning/config.json`, which suppresses planner-emitted human-verify tasks and harvests them *after* the phase — that is, after the corrected strings would already be on disk. A human-verify would therefore not have gated the write at all.
- **Fix:** The plan emitted `checkpoint:decision`, which is unaffected by `human_verify_mode` and stops before the work. Same operator, same evidence, same one-look confirmation, correct timing.
- **Files modified:** none (planning-time divergence)
- **Verification:** The gate did stop the first executor run before any commit; that run returned with a clean worktree and no production commits, which is the behaviour a pre-write gate is supposed to produce.
- **Committed in:** n/a

### 3. [DIV-2 — carried forward from the plan] The playbook is briefly incomplete on the session model

- **Found during:** Task 2
- **Issue:** The new verification block coexists with the older `### Personal hypr hooks (two lines)` and `### Live product path` subsections, which describe the pre-adopt conf-hook method as if it were the current session model.
- **Fix:** Left intentionally intact. Plan `15-04` replaces them with the full session model and demotes the conf-hook method to a pointer line (D-08). The tracer deliberately closed only the verification path, so the file is briefly incomplete on the session model but never wrong about verification.
- **Files modified:** `docs/dots-hyprland-workflow.md`
- **Verification:** Called out in the plan's `<done>` so it is not mistaken for an oversight.
- **Committed in:** `fd1e684`

---

**Total deviations:** 3 (1 scope expansion authorised by the Task 1 human decision, 2 planning-time divergences carried forward and recorded)
**Impact on plan:** No scope creep. The one added file was explicitly authorised by the operator at the gate and is the phase's highest-severity finding; the other two are disclosures, not changes.

## Issues Encountered

None that required problem-solving. Two mechanical notes:

- The `git diff --name-only <plan-commit>..HEAD` range in the plan's scope-fence verify uses `f54714b` (the `15-01-PLAN.md` commit), which predates two later planning commits. That range therefore lists `.planning/STATE.md` and `.planning/ROADMAP.md` as changed — from those intervening planning commits, not from this plan. The range restricted to the five fenced directories is empty as required, and `git diff --name-only 6e2ae94..HEAD` (this executor's own base) lists exactly the five intended files and neither `STATE.md` nor `ROADMAP.md`.
- The regression floor held: `./scripts/phase13-d19-assert.sh` returns exit 0 with 15 `[PASS]` and 0 `[FAIL]`, unchanged from the pre-edit baseline.

## Known Stubs

`15-DOC-SWEEP.md` ships with two intentionally empty sections — `## Reviewed, no findings` and `## Flagged, not edited (D-22)`, each carrying a `_To be filled by plan 15-06._` placeholder. This is the plan's explicit instruction, not an oversight: the sweep record is seeded here so the phase has a findings surface from its first commit, and plan `15-06` performs the actual sweep that populates both sections. The plan's goal — a doc chain that agrees on the corrected ground truth — is achieved without them.

## Threat Flags

None. No file created or modified by this plan introduces network, auth, file-access or schema surface; the phase is documentation-only. The mitigations assigned to this plan in the threat register are all in place: T-15-01 (playbook and `PROJECT.md` quote the probe `scripts/phase14-verify.sh` actually runs), T-15-02 (`~/ii-original-dots-backup` named, rotated form banned by regex), T-15-03 (two-sided scope fence clean), T-15-04 (`PROJECT.md` frozen-token count still exactly 3).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Ready. The corrected probe string and the corrected backup path are now the operator-facing contract that plans `15-02` through `15-06` are written against, and `15-DOC-SWEEP.md` exists for them to append to.

Notes for the plans that follow:

- **`15-03`** should confirm the runbook's remaining pre-adopt framing is still its own: §14 tier-1 source 3 is now fixed, but `docs/phase14-adopt-runbook.md:117`, `:144` ("as it does today") and `:199` ("currently") are still pre-adopt tense and were deliberately left alone here.
- **`15-04`** owns the D-08 demotion of `### Personal hypr hooks (two lines)` and `### Live product path` — see DIV-2 above.
- **`15-06`** fills the sweep record's two empty sections and runs `./scripts/phase14-verify.sh` at the phase gate, which additionally asserts a clean working tree (D-35) and so cannot run inside a pre-commit task verify.
- `.planning/STATE.md` and `.planning/ROADMAP.md` were deliberately not written by this executor; the orchestrator owns those updates.

## Self-Check: PASSED

All claimed files exist on disk and both claimed commits resolve in `git log --all`:

| Claim | Result |
|---|---|
| `README.md` | FOUND |
| `docs/dots-hyprland-workflow.md` | FOUND |
| `docs/phase14-adopt-runbook.md` | FOUND |
| `.planning/PROJECT.md` | FOUND |
| `.planning/phases/15-playbook-safe-vs-full/15-DOC-SWEEP.md` | FOUND |
| `.planning/phases/15-playbook-safe-vs-full/15-01-SUMMARY.md` | FOUND |
| commit `f8e8174` | FOUND |
| commit `fd1e684` | FOUND |

---
*Phase: 15-playbook-safe-vs-full*
*Completed: 2026-09-06*
