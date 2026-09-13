---
phase: 18-capture-model-three-trees-and-the-collision-map
plan: 01
subsystem: infra
tags: [bash, tsv, stow, dots-hyprland, collision-map, generator, assert]

# Dependency graph
requires:
  - phase: 17-unblock-stow-and-restore-the-session-target
    provides: "The assert-script contract (scripts/phase17-unblock-assert.sh) this phase's assert takes its shape from, and the D-02 folded-directory audit handed forward"
  - phase: 14-live-full-adopt-verify
    provides: "scripts/phase14-verify.sh's four-prefix / two-counter output vocabulary (D-49) and the loud-failure-inside-a-subshell caveat at :50-57"
provides:
  - "scripts/gen-collision-map.sh — derives the installer collision map mechanically from any dots-hyprland source root, stdout only"
  - "collision-map.tsv — 29 checked-in rows at pin 1a9ffb78, with the phase's reasoning in its comment header"
  - "scripts/phase18-capture-model-assert.sh — sections 2, 3a, 3b, 3c plus the two named-condition notices"
  - "The derived `tree` column every later plan in this phase reads for stow/ vs restow/ placement"
affects: [18-02, 18-03, 18-04, 18-05, 18-06, 18-07, 18-08, 18-09, 18-10, 18-11, 19-link-aware-verify, 20-first-bulk-stow]

# Actuals (#2632) — estimateTokens scale (chars/4 over the realized diff)
actuals:
  tokens: 9900
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Generator emits to stdout only; regeneration is an operator-typed redirect, so an interrupt cannot half-write the artifact"
    - "Loud-failure emitter runs in the main shell behind process substitution, never a pipeline"
    - "Comment header carries the artifact's reasoning so a reader does not re-derive it"

key-files:
  created:
    - scripts/gen-collision-map.sh
    - collision-map.tsv
    - scripts/phase18-capture-model-assert.sh
  modified:
    - .planning/STATE.md

key-decisions:
  - "Confirmed D-05 at the Task 1 checkpoint: `tree` is derived from the two outcome columns, two values only, no authored override column"
  - "The primitive lookup is hand-authored from RESEARCH's verified matrix, not transcribed from PITFALLS.md:285-290 (F-1)"
  - "A call site whose SOURCE argument lives under dots-extra/ is skipped as a flag-reached alternate — the mechanical rule that covers both recorded coverage gaps without hard-coding a line number"
  - "`source` cites the line of the primitive call site (MISC rows cite their [ -d ] / [ -f ] arm at :14/:15); the inline rename cites its whole if/fi block, resolved by scanning, not typed"
  - "The generator checks the installer's four MISC find exclusions rather than trusting them, so an upstream change to the modelled destination set fails loudly instead of being absorbed"

patterns-established:
  - "Vacuity guard before every check, with the guard's own result reported (phase17 shape)"
  - "One EXIT trap covering every mktemp fixture, set before any failure-capable code (phase16 shape)"
  - "Closing self-check comparing `git status --porcelain` before and after, so a non-mutating claim is demonstrated rather than asserted"

requirements-completed: [CAP-02, CAP-03]

coverage:
  - id: D1
    description: "collision-map.tsv is checked in, covers every destination 3.files-legacy.sh writes at the pin, and records the submodule SHA it was derived from"
    requirement: "CAP-02"
    verification:
      - kind: integration
        ref: "./scripts/phase18-capture-model-assert.sh — section 2a/2b/2c (pin equality, source-line resolution, tree column)"
        status: pass
    human_judgment: false
  - id: D2
    description: "scripts/gen-collision-map.sh reproduces the committed map byte-for-byte from the pinned submodule and writes nothing in place"
    requirement: "CAP-02"
    verification:
      - kind: integration
        ref: "./scripts/gen-collision-map.sh | diff -u collision-map.tsv -"
        status: pass
      - kind: integration
        ref: "./scripts/phase18-capture-model-assert.sh — section 3a"
        status: pass
    human_judgment: false
  - id: D3
    description: "The map cannot rot silently: regeneration is deterministic, and a source tree with one primitive changed produces a different map (CAP-03 partial — the mis-filed fixture lands in 18-10)"
    requirement: "CAP-03"
    verification:
      - kind: integration
        ref: "./scripts/phase18-capture-model-assert.sh — section 3b (cmp of two consecutive runs)"
        status: pass
      - kind: integration
        ref: "./scripts/phase18-capture-model-assert.sh — section 3c (D-55 fake source root, diff non-empty plus the re-derived restow row)"
        status: pass
    human_judgment: false
  - id: D4
    description: "An unrecognised installer primitive fails loudly, naming the primitive and its source line, instead of emitting a benign-looking row"
    requirement: "CAP-02"
    verification:
      - kind: manual_procedural
        ref: "./scripts/gen-collision-map.sh <fixture with install_dir__teleport> — exit 1, primitive and source line named (run during execution; no committed fixture, per D-56's no-permanent-fixture rule)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The map header carries the reasoning a future reader needs to not 'correct' the map against a host observation — D-04 coverage, D-06 no-SKIP_*, F-3 ordering, F-5 disarmed branch, F-13 gaps, D-32 accepted risk"
    verification: []
    human_judgment: true
    rationale: "Whether the header prose actually prevents the F-5 misreading is a judgment about explanatory adequacy; no assert can decide it. The assert can only check that the header's pin matches."

# Metrics
duration: 12 min
completed: 2026-09-13
status: complete
---

# Phase 18 Plan 01: Collision map spine Summary

**A 29-row `collision-map.tsv` derived mechanically from the pinned dots-hyprland installer, a stdout-only bash generator that reproduces it byte-for-byte, and an assert whose regenerate-and-diff, determinism and simulated-pin-bump sections make the map unable to rot silently.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-09-13T16:29:00Z
- **Completed:** 2026-09-13T16:41:00Z
- **Tasks:** 3 (one resolved checkpoint, one tracer, one auto)
- **Files modified:** 4 (3 created, 1 modified)

## Accomplishments

- `scripts/gen-collision-map.sh` parses `3.files-legacy.sh`'s primitive call sites, expands the MISC `find` loop against the source tree through `LC_ALL=C sort`, special-cases the inline `hyprland.conf` rename by name, and emits the complete TSV — header included — to stdout only. It refuses a source root with no `dots/.config/` and one with no readable `3.files-legacy.sh`, and it refuses to emit a body of zero rows.
- `collision-map.tsv` holds exactly the 29 rows RESEARCH F-13 predicted: 18 MISC rows plus 11 named ones, including `$XDG_CONFIG_HOME/hypr/hyprland.lua` at `:61`, which the CONTEXT never enumerated. Exactly one row derives `stow` (`$XDG_CONFIG_HOME/hypr/custom`, `install_dir__ignore_existing`); the other 28 derive `restow`.
- `$XDG_CONFIG_HOME/hypr/hyprland` and `$XDG_CONFIG_HOME/hypr/hyprland.conf` emit as two separate rows — the prefix-sharing case that a naive path merge would have collapsed.
- `scripts/phase18-capture-model-assert.sh` runs green with `FAIL=0 FINDINGS=0`: three vacuity guards, section 2 (pin equality, every source citation resolving to a real line, the `tree` column holding only `stow`/`restow`), 3a (regenerate-and-diff), 3b (two runs byte-identical), 3c (the D-55 fake source root with `install_dir__ignore_existing` swapped for `install_dir__sync`), the two `[INFO]` notices, and a closing `git status --porcelain` before/after comparison.
- No row count is hard-coded anywhere — not in the generator, not in the assert.

## Task Commits

1. **Task 1 (checkpoint:decision)** — resolved by the operator as `derived-two-value`; no commit of its own, recorded here and honored throughout.
2. **Task 2: End-to-end collision map (tracer)** — `83a0c66` (feat)
3. **Task 3: Prove the map cannot rot** — `b1023fb` (feat)

Housekeeping: `f91e0cf` (docs) — see Deviations.

## Files Created/Modified

- `scripts/gen-collision-map.sh` — the generator. Takes an optional source root (D-55), emits to stdout (D-59), fails loudly on an unrecognised primitive (D-03).
- `collision-map.tsv` — the checked-in map, 29 data rows under a 61-line reasoning header carrying `pin=1a9ffb78f0c272a45f82342587dc3bec72762233`.
- `scripts/phase18-capture-model-assert.sh` — the phase assert, sections 2 and 3a–3c.
- `.planning/STATE.md` — execution-start marker (see Deviations).

## Decisions Made

- **Checkpoint resolved: `derived-two-value` (D-05 confirmed).** The column set is `dest`, `primitive`, `symlink_outcome`, `repo_outcome`, `tree`, `source`; `tree` is derived and never authored; only `stow` and `restow` ever appear; `capture/` membership is hand-assigned prose in `capture/README.md` and is stated as such in the map header so the absence is legible rather than looking like an omission.
- **The `dots-extra/` rule.** Rather than excluding `3.files-legacy.sh:42` and `:66` by line number, the generator skips any call site whose *source* argument lives under `dots-extra/`. Both of the alternate-source branches (`--fontset`, `--via-nix`) are reached only by a flag this repo does not pass, and the rule survives a pin bump that moves them. Both are named in the header as coverage gaps.
- **Source citations point at the primitive call site**, so MISC rows cite `:14` or `:15` (the `[ -d ]` / `[ -f ]` arms) rather than the `for` line at `:11`. Every citation is checked by section 2b against the vendored file's real line count.
- **The inline rename's block bounds are resolved, not typed.** The generator finds the `mv` line, then scans out to the enclosing `if` and `fi`, producing `3.files-legacy.sh:51-54` at this pin and tracking upstream if the block moves.
- **The MISC exclusions are verified, not merely reproduced.** The four `! -name` exclusions are written verbatim per the plan, and the generator then asserts the installer's own `find` line still carries all four — an upstream change to the modelled destination set fails loudly instead of being silently absorbed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Committed the pre-existing `.planning/STATE.md` execution marker before Task 3**

- **Found during:** Task 3 (the plan's Task 2)
- **Issue:** The orchestrator's "Phase 18 execution started" edit to `.planning/STATE.md` was sitting uncommitted in the working tree. Task 3's `<verify>` ends in `[ -z "$(git status --porcelain)" ]`, which that edit made unsatisfiable no matter how clean the assert itself was.
- **Fix:** Committed the marker on its own as `docs(18-01)` before the task commits, so the porcelain clause tests what it was written to test — whether the assert left a fixture behind.
- **Files modified:** `.planning/STATE.md`
- **Verification:** `[ -z "$(git status --porcelain)" ]` now passes after the task commits.
- **Commit:** `f91e0cf`

**2. [Rule 2 - Missing Critical] Added a second refusal for a missing `3.files-legacy.sh`**

- **Found during:** Task 2 (the plan's Task 1)
- **Issue:** The plan specifies a loud refusal for a source root with no `dots/.config/`. A source root that has `dots/.config/` but no readable `sdata/subcmd-install/3.files-legacy.sh` would instead have died inside `grep` under `set -e`, with a cryptic message and no fix instruction — the same silent-failure class the first refusal exists to prevent.
- **Fix:** A parallel `[FAIL]`-prefixed refusal naming the missing path and the `git submodule update` fix.
- **Files modified:** `scripts/gen-collision-map.sh`
- **Verification:** Exercised against a temporary source root with `dots/.config/` present and the installer fragment absent — exit 1 with the path named.
- **Commit:** `83a0c66`

**3. [Rule 2 - Missing Critical] Section 3c asserts the swapped row, not only that a diff exists**

- **Found during:** Task 3
- **Issue:** D-55's stated property is "the generator reacts to upstream, not merely that a diff can be produced". A fake tree differs from the committed map for many reasons that have nothing to do with the swapped primitive, so a bare non-zero `diff` would pass even if the generator ignored the call site entirely.
- **Fix:** Kept the non-zero `diff` as the hard check per the plan, and added a second hard check that the fake map's `$XDG_CONFIG_HOME/hypr/custom` row carries `install_dir__sync` and re-derives `tree=restow`.
- **Files modified:** `scripts/phase18-capture-model-assert.sh`
- **Verification:** Both checks report `[PASS]`; no row count is compared.
- **Commit:** `b1023fb`

---

**Total deviations:** 3 auto-fixed (1 blocking, 2 missing critical)
**Impact on plan:** None widened scope. Deviation 1 unblocked a verify clause; 2 and 3 close silent-failure paths in the mechanisms the plan itself specifies.

## Issues Encountered

None. The generator's output matched RESEARCH F-13's enumeration exactly on the first run — 18 MISC rows plus 11 named rows, 29 total — which is the strongest available evidence that the parse is reading what the installer reads.

## Known Stubs

None. Every path in both scripts is exercised by the assert or by a refusal probe run during execution.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `collision-map.tsv` is committed ahead of any file move, satisfying D-26's ordering gate. Plans 18-02 onward may now derive tree membership, the `rsync-replace`/`cp-through` tags and every FIX-03 destination decision from it.
- CAP-03 is **partially** satisfied here. The regenerate-and-diff (3a), determinism (3b) and simulated pin bump (3c) all ship; the D-56 mis-filed-fixture demonstration is plan 18-10's, and `requirements.mark-complete` correctly withholds the ID until that plan produces its summary.
- Two open items this plan deliberately did not touch: the `PITFALLS.md:288` correction that RESEARCH F-1 recommends (D-35 opens that file in a later plan), and F-2's warning that the FIX-03 `stow` moves will exit 1 against the live real files unless each migration task clears the destination first.
- The `[INFO]` notices are load-bearing, not decoration. The F-5 line is what stops the next reader from "correcting" `hypridle.conf` and `hyprlock.conf` into `stow/` after watching an install run leave them intact on this disarmed host.

## Self-Check: PASSED

- `scripts/gen-collision-map.sh` — FOUND
- `collision-map.tsv` — FOUND
- `scripts/phase18-capture-model-assert.sh` — FOUND
- Commit `83a0c66` — FOUND
- Commit `b1023fb` — FOUND
- Commit `f91e0cf` — FOUND
- `./scripts/phase18-capture-model-assert.sh` — exit 0, `FAIL=0 FINDINGS=0`
- `./scripts/gen-collision-map.sh | diff -u collision-map.tsv -` — empty
- `git status --porcelain` — empty after the task commits

---
*Phase: 18-capture-model-three-trees-and-the-collision-map*
*Completed: 2026-09-13*
