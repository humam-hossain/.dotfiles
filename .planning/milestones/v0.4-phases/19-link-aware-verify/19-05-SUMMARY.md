---
phase: 19-link-aware-verify
plan: 05
subsystem: infra
tags: [research-record, drift-pin, phase-gate, validation-contract, symlinks, atomic-writes]
status: complete

# Dependency graph
requires:
  - phase: 19-link-aware-verify
    provides: "19-01's scripts/phase19-link-aware-verify-assert.sh — the marker file the new drift tier keys on; without it on disk the tier never fires"
  - phase: 19-link-aware-verify
    provides: "19-03's 85dbfbc — the final Phase 19 edit to arch/dots-hyprland.sh, and therefore the commit the new baseline resolves to"
  - phase: 19-link-aware-verify
    provides: "19-01..19-04's SUMMARY task lists — the real task IDs, plans and waves the validation map now names"
  - phase: 19-link-aware-verify
    provides: "19-RESEARCH.md §Q3 — the Qt source reading and the two measurement probes the PITFALLS extension records"
provides:
  - "PITFALLS.md entry A-6 carries the Q3 answer in the durable research record: the mechanism, the measured rate and its method, and the reasoning for shipping nothing (D-40..D-43)"
  - "scripts/phase13-d19-assert.sh has a Phase 19 tier pinned to 85dbfbc, resolved at execution time and confirmed byte-identical to the working tree — the drift check is live again after being red since 19-01"
  - "The pin is re-extractable by a single-line grep anchored on the marker filename, so it can be re-verified independently of which tier fires at runtime"
  - "19-VALIDATION.md: 20 map rows, every one naming a real task ID, plan, wave and a command that was really run; Wave 0 closed; three human-judgement checks in the Manual-Only table"
  - "A full phase-gate transcript with per-command summary lines and exit codes, including a precise diagnosis of both red scripts"
  - "A measured finding: scripts/phase14-verify.sh's D-37 probe is not link-aware — stat -c %s does not dereference, sha256sum does, and the two live confs became symlinks in feat(18-06)"
affects: [phase-20-verify-proves-the-bulk-stow, phase-14-verify-assert-owner, phase-17-assert-owner]

# Actuals (#2632) — same estimateTokens scale (chars/4) as the plan's estimate.
actuals:
  tokens: 9000
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A drift pin is RESOLVED at execution time (git log -1 on the file, then an empty git diff against the WORKING TREE) and never copied from a planning document"
    - "The pin's assignment line carries its own marker filename in the trailing comment, so the SHA has a single-line grep anchor and can be re-checked independently of which branch fires"
    - "A red gate is reported with its diagnosis, never closed by editing the script that reports it"
    - "Separate 'the validation map is complete' from 'every assert in the repo is green' — two claims, two frontmatter keys, so neither can be read as the other"
    - "Record a measurement's METHOD alongside its number, because a rate that depends on a burst-to-poll ratio is not reproducible from the number alone"

key-files:
  created: []
  modified:
    - ".planning/research/PITFALLS.md — entry A-6 gains a Q3 subsection (mechanism, measurement, no-rule decision, no-check decision) and its same-device sentence, Detection signal and Mitigation are corrected to the measured behaviour"
    - "scripts/phase13-d19-assert.sh — PHASE19_ASSERT marker, the Phase 19 tier as the first branch of the chain pinned to 85dbfbc, and two sentences in the ordering comment"
    - ".planning/phases/19-link-aware-verify/19-VALIDATION.md — 20 filled map rows, Wave 0 checkboxes, the Manual-Only table, the Phase Gate transcript with both red diagnoses, and an honest sign-off"
    - ".planning/WINDOWS.md — new entry: the phase14-verify D-37 link-awareness defect"

key-decisions:
  - "No .gitignore rule ships (D-41), although the measurement DID observe the artifact. The first half of D-41's condition is met and the second is not: the suffix is six random characters, so the only matching pattern is *.?????? — an over-match that would swallow foo.python and bar.config. That shape must not be confused with .gitignore's deliberate slash-free block, which is unanchored by DEPTH on purpose while this would be unanchored by NAME"
  - "A-6's same-device sentence was CORRECTED, not merely extended. It predicted that a cross-filesystem rename failure 'would be' a live concern if the repo moved to a separate mount; the mechanism says otherwise — the temp file is materialised in the RESOLVED directory and renamed within that same directory, so the link-and-rename pair stays inside the repo's own filesystem on both sides of such a move"
  - "The drift baseline is 85dbfbc, resolved with git log -1 on the wrapper and confirmed with an empty git diff against the WORKING TREE before it was written. The comparison in that script is against the working tree, not HEAD, so a pin off by one byte reports drift forever"
  - "The ordering comment also records plan 18-05's in-place re-pin of the Phase 17 tier to 8497511, which its prose had missed — the block still claimed the pin was b32faf6. Corrected by appending, never by deleting"
  - "status: validated and nyquist_compliant: true describe the validation MAP. A separate phase_gate: red key and an unchecked sign-off line carry the gate result, so 'validated' cannot be read as 'everything is green'"
  - "Neither red gate was repaired here. phase17's is a Phase 17/18 boundary condition (WINDOWS id 7); phase14's is a defect in a Phase 14 assert introduced by a Phase 18 move. Editing either from inside Phase 19 would be closing a red gate by editing the thing that reports it"

requirements-completed: [VER-01, VER-02, VER-03, VER-04]

duration: "4 min"
completed: "2026-09-14"
---

# Phase 19 Plan 05: Close the record, re-pin the drift baseline, run the gate Summary

Three loose ends closed — the Q3 atomic-write measurement written into `PITFALLS.md` A-6, the wrapper drift check re-pinned to `85dbfbc` behind a new Phase 19 tier, and the validation map filled from the four executed plans — plus a full phase-gate run that found two red scripts and diagnosed both instead of silencing either.

- **Duration:** 4 min (12:57 → 13:01 local)
- **Tasks:** 3
- **Commits:** 3
- **Files modified:** 4 (+229 / −37)
- **Production code changed:** none. `arch/dots-hyprland.sh` reached its final Phase 19 state in plan `19-03` and is byte-unchanged by this plan — which is exactly why the new pin can name `85dbfbc`.

## Accomplishments

**Task 1 — the Q3 answer is in the durable record.** `PITFALLS.md` entry A-6 gains a subsection stating the mechanism as fact rather than inference: `QSaveFile` resolves the symlink chain before writing, so the temp file is created in the resolved directory *inside the repo*; during the write it has no directory entry at all (`O_TMPFILE`), which is why the naive hold-the-write-open probe reports "never observable" and returns the wrong answer; at commit time the `linkat()` to the final name fails with an already-exists error, the writer materialises the file under `<target>.XXXXXX` in that same directory and renames it over the target. The named window is two syscalls wide. The measurement is recorded with its method, not just its number — a 3000-write burst against 2000 `git status --porcelain` polls produced 11 hits, ≈ 0.55 %, every name matching the six-character template — because the rate is a property of the burst-to-poll ratio and is not reproducible from the figure alone. Then the two negative decisions and why: no ignore rule (D-41, the anchoring half of the condition fails), and no dedicated `verify` check (D-42, a 0.55 %-visible artifact makes a verdict a coin flip). The same-device sentence was corrected rather than duplicated, and the Detection signal and Mitigation lines now read as delivered — the `-xtype l` sweep A-6 asked of `verify` shipped in plans `19-02` and `19-03`. `.gitignore` is untouched; the newest commit naming it is still the Phase 17 line-endings commit `936fd9e`.

**Task 2 — wrapper drift detection is live again.** `scripts/phase13-d19-assert.sh` has been reporting `[FAIL] arch/dots-hyprland.sh changed since 8497511` since plan `19-01` first edited the wrapper. A `PHASE19_ASSERT` marker now names `scripts/phase19-link-aware-verify-assert.sh`, and the Phase 19 branch sits FIRST in the tier chain — every older marker file still exists, so a branch placed after their tests would never fire. The baseline was resolved at execution time (`git log -1 --format=%h -- arch/dots-hyprland.sh` → `85dbfbc`) and confirmed with an empty `git diff --name-only 85dbfbc -- arch/dots-hyprland.sh` *before* it was written, because the comparison in that script is against the working tree rather than `HEAD`. The assignment line carries the marker filename in its trailing comment, which is load-bearing: every branch tests a variable and never a literal, so without that anchor the tier's SHA cannot be told from Phase 17's by a single-line grep. The second verify block re-extracts the SHA from the file and re-runs both checks independently — `SHA_OK 85dbfbc`.

**Task 3 — the gate ran, and it is not green.** All seven commands ran on the same tree in the same run. Five of the six scripts plus `verify` are green; `phase17-unblock-assert` (`FAIL=8`) and `phase14-verify` (`FAIL=3`) are red. Both are diagnosed line by line in `19-VALIDATION.md` and neither was touched. The validation map's eight `_pending_` seed rows became twenty rows naming real task IDs, plans, waves and commands that were really run, including the six behaviours the seeded table did not anticipate (folded ancestor, dangling-into-repo split, untracked-repo-file arm, the auto-backup branch pair, D-47 read-only independence, and the two determinism checks).

## Verification Evidence

| Check | Result |
|---|---|
| Task 1 verify block | `PITFALLS_OK entries=34` — `.gitignore` still last touched by `936fd9e` |
| Task 1 diff containment | one hunk, `@@ -109,5 +109,44 @@` — entirely inside A-6's range (lines 101-115) |
| Task 2 verify block 1 | `PIN_OK` — `bash -n` clean, script exits 0, `FAIL=0`, `[PASS] arch/dots-hyprland.sh unmodified since 85dbfbc` |
| Task 2 verify block 2 | `SHA_OK 85dbfbc` — SHA re-extracted from the file, is a real commit, blob identical to the working tree |
| Task 3 verify block 1 | **FAILED** — `gate_red script=scripts/phase17-unblock-assert.sh rc=1`, `gate_red script=scripts/phase14-verify.sh rc=1` |
| Task 3 verify block 2 | `VALIDATION_OK` — zero `_pending_`, `status: validated`, `wave_0_complete: true`, 8 rows naming the phase assert, no code touched by this plan |
| `./scripts/phase19-link-aware-verify-assert.sh` | exit 0, `=== done: FAIL=0 FINDINGS=0 ===` |
| `./scripts/phase18-capture-model-assert.sh` | exit 0, `=== done: FAIL=0 FINDINGS=0 ===` |
| `./scripts/phase17-unblock-assert.sh` | **exit 1**, `=== done: FAIL=8 ===` |
| `./scripts/phase13-d19-assert.sh` | exit 0, `=== Phase 13 asserts: FAIL=0 ===` |
| `./scripts/phase12-full-smoke.sh` | exit 0, `=== done: FAIL=0 ===` |
| `./scripts/phase14-verify.sh` | **exit 1**, `=== done: FAIL=3 FINDINGS=0 ===` |
| `./arch/dots-hyprland.sh verify` | exit 0, `FAIL=0 FINDINGS=0`, 123 `[PASS]`, 33 `[INFO]` |
| `./arch/dots-hyprland.sh verify --strict` | exit 0 |
| `git diff --quiet HEAD -- .gitignore` | clean |

## Deviations from Plan

### 1. [Reported, not fixed] The phase gate is red — `scripts/phase14-verify.sh` FAIL=3, and two of the three failures are FALSE

- **Found during:** Task 3, first end-to-end gate run of the phase.
- **Issue:** The plan expected `phase14-verify` to exit 0 with one known finding. It exits 1 with `FAIL=3`.
  - Two failures claim `D-37 hyprlock.conf changed: 66 bytes / c3ecd68d…, fixture recorded 554 bytes / c3ecd68d…` (and the same shape for `hypridle.conf`). **The sha256 matches exactly on both sides; only the byte count differs.** `check_untouched()` (lines 399-412) probes with `stat -c '%s' "$path"`, which does not dereference, and `sha256sum "$path"`, which does. Since `feat(18-06): move overwriting hypr configs to restow/hypr/`, both live paths are symlinks; 66 is the length of the link target string, and `stat -L -c %s` returns 554 and 359 — the fixture's recorded values exactly. Phase 11 D-24 **did** hold. The assert is not link-aware, which is the very class of defect this phase exists to remove from `verify`.
  - The third is `D-35 working tree is dirty`, naming `stow/fish/.config/fish/config.fish` — an operator modification that predates this phase and was deliberately left alone throughout it. It clears when that file is committed or reverted.
- **Fix:** none applied. The repair is one `-L` on the `stat` in `check_untouched()` and belongs to whoever owns `scripts/phase14-verify.sh`; the plan's own instruction for a red gate is to stop and report rather than edit, and this repo's standing rule (STATE.md, Phase 17) is that a gate turned green by rewriting the thing that reports it is a false green.
- **Recorded:** `19-VALIDATION.md` §Phase Gate → Red 2, with the transcript; new `.planning/WINDOWS.md` entry (kind `unmet-truth`).
- **Commit:** `a8a509c`

### 2. [Scope boundary — not fixed] `scripts/phase17-unblock-assert.sh` FAIL=8, pre-existing

- **Found during:** Task 3.
- **Issue:** The assert hard-codes repo-root `.config/…` paths that Phase 18's redistribution (`18-04`, `18-06`) moved. Its 4b breadth sweep, its F-9 `kdeglobals` tracking checks and its 5a/5b `execs.lua` checks all address paths that no longer exist there.
- **Fix:** none. Already dispositioned in `18-VERIFICATION.md`, `19-01-SUMMARY.md`, `19-02-SUMMARY.md` and `19-03-SUMMARY.md`, and recorded as WINDOWS ledger id 7. No duplicate entry added.
- **Commit:** n/a (recorded in `a8a509c`)

### 3. [Rule 1 — falsified expectation] The "one known D-38 finding" the plan expects does not exist

- **Found during:** Task 3.
- **Issue:** The plan (and this phase's validation contract) expected `phase14-verify` to emit exactly one finding, the D-38 autostart loss. It reports `FINDINGS=0`. The D-38 losses are emitted as eleven `[INFO]` lines, each marked `(expected)`, alongside `[INFO] D-38 graphical-session.target is active`. The `[INFO]` block is unchanged from the Phase 16 D-40 gate transcript.
- **Fix:** the expectation was recorded as falsified rather than the script adjusted to produce a finding. The plan's `<human-check>` — "confirm it reports exactly one finding and that it is the known autostart loss, not a new one absorbed into the same count" — is answered in `19-VALIDATION.md`: the count is zero, so nothing can be hiding inside a matching count, and the eleven `[INFO]` lines are individually named there for a human to scan.
- **Commit:** `a8a509c`

### 4. [Rule 2 — record correctness] The drift assert's ordering comment claimed a pin the chain no longer carries

- **Found during:** Task 2.
- **Issue:** The comment's narrative ended at "Phase 17 plan 02 … so it is now b32faf6. Pinning all four…", but plan `18-05` had re-pinned that same tier in place to `8497511` without updating the prose, and the chain now has five branches.
- **Fix:** corrected by appending — the `18-05` re-pin is named, Phase 19's own wrapper change is named, and the count reads five. Nothing was deleted.
- **Commit:** `8c04382`

**Total deviations:** 2 reported-not-fixed (scope boundary / standing no-false-green rule), 1 falsified expectation, 1 record correction. **Impact:** the plan's three artifacts all shipped exactly as specified. The one acceptance criterion not met is the phase-gate greenness, and it is not met because the gate found real conditions in two other phases' assert scripts — which is the gate working, not the gate failing.

## Issues Encountered

The phase gate is red and cannot be closed from inside Phase 19. Two follow-ups are owed:

1. `scripts/phase14-verify.sh` — add `-L` to the `stat` in `check_untouched()` (or compare dereferenced sizes explicitly) so the D-37 probe is link-aware. Until then the script reports two false failures on any tree where those two confs are stowed, which is every tree since `18-06`.
2. `scripts/phase17-unblock-assert.sh` — reconcile with Phase 18's redistribution. WINDOWS id 7, open since `19-01`.

Neither blocks Phase 20: `verify` itself, the Phase 19 assert, the Phase 18 assert, the drift assert and the full smoke are all green.

## Known Stubs

None. No placeholder, TODO or unwired path was introduced. `19-VALIDATION.md` contains zero `_pending_` tokens.

## Threat Flags

None. This plan added no network surface, no auth path, no file-access pattern and no schema. T-19-13 (drift baseline tampering) is mitigated as planned — the SHA is resolved at execution time, confirmed against the working tree before it is written, and re-derived from the file by an independent verify command. T-19-14 (closing a red gate by weakening its claim) was live for real this time and was not taken: both red scripts are untouched and diagnosed. T-19-16 (editing a frozen record so a ban stops matching) — Task 1 is confined to A-6 by a one-hunk diff, and `.gitignore` is provably untouched.

## Self-Check: PASSED

- `.planning/research/PITFALLS.md` — FOUND, A-6 carries the Q3 subsection
- `scripts/phase13-d19-assert.sh` — FOUND, `bash -n` clean, exits 0, Phase 19 tier fires
- `.planning/phases/19-link-aware-verify/19-VALIDATION.md` — FOUND, zero `_pending_`
- `.planning/WINDOWS.md` — FOUND, new entry recorded
- `d85ecab` — FOUND in `git log`
- `8c04382` — FOUND in `git log`
- `a8a509c` — FOUND in `git log`

One acceptance criterion is deliberately unmet and reported rather than papered over: the phase gate is red (see Deviations 1 and 2).

## Next Phase Readiness

Phase 19 is complete. `verify` is link-aware, flag-complete, exit-code-contracted and green on the real tree; its assert is 1731 lines across 8 sections at `FAIL=0`; the drift pin is live at `85dbfbc`; the research record states the Q3 answer and why nothing shipped for it. Phase 20 (the first bulk stow at `hypr/custom`) can rely on `verify` to prove the stow, which is the dependency the v0.4 ordering was built around.

Carry into phase verification: the two red asserts above, and the three human-judgement checks in `19-VALIDATION.md`'s Manual-Only table (`--quiet` scannability, the 33 real-tree `[INFO]` conditions, and the `phase14-verify` `[INFO]` block).
