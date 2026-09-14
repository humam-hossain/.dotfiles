---
phase: 19-link-aware-verify
plan: 04
subsystem: infra
tags: [bash, stow, symlinks, capture-tree, exit-codes, adversarial-test, submodule-independence]

# Dependency graph
requires:
  - phase: 19-link-aware-verify
    provides: "19-01's flag parser (--strict, --quiet), the pre-walk precondition block, and scripts/phase19-link-aware-verify-assert.sh with its fixture builder, runner and guard_scratch_target()"
  - phase: 19-link-aware-verify
    provides: "19-02's folded-ancestor pre-check, the dangling-into-repo arm, and the D-21 repo-vs-HEAD / untracked [INFO] observations"
  - phase: 19-link-aware-verify
    provides: "19-03's live-side sweep and classify_sweep_entry() — the nine-arm classifier whose arm-6-before-arm-8 ordering Section 7 regression-guards"
  - phase: 18-capture-model-three-trees-and-the-collision-map
    provides: "the capture/ block with its inverted expectation, and the four-label / two-counter output contract"
provides:
  - "Section 6: the findings-only capture/ fixture — the only thing in the phase that exercises the VER-02 block at all, because capture/ holds only its README on the live tree"
  - "The --strict promotion proven end to end: one fixture, exit 0 bare and exit 1 under --strict, FAIL=0 in both, output byte-identical above the summary line"
  - "build_capture_fixture(): a capture/ package staged in six shapes (drift, clean, missing, stowed, ordering, empty) with the stow/ side held identical, so the capture/ staging is the only variable"
  - "The empty-shape assertion — a package-less capture/ tree emits no capture-tree line and changes neither counter — which is what stops the block's vacuity on today's tree from being read as coverage"
  - "Section 7: both branches of the installer's auto-backup primitive, staged in separate fixtures with plain shell commands and no dependency on the vendored submodule"
  - "D-47 proven twice and read-only: a static gate over run_verify()'s own body, plus a scratch fixture reproducing a de-initialised submodule's on-disk shape. The real submodule is never de-initialised"
  - "Section 8: the read-only real-tree run that CHECKS ROADMAP criterion 5 rather than asserting it — exit code only, everything else recorded as [INFO]"
  - "teardown_scratch_roots(): a mid-run scratch teardown, asserted, so Section 8's answer is about the tree and not about the harness"
  - "A self-check that cannot silently stop checking: the fixture-leak sweep reads the TMP_FILES and SCRATCH_ROOTS arrays instead of a hand-copied list"
  - "Two structural gates on the porcelain bracket: exactly one `git status --porcelain` invocation in the file and it carries --ignored, and the filter removes only the lines matching its anchored two-prefix pattern"
  - "The completed `=== Phase 19 ROADMAP Criteria Summary ===` block — all five criteria named, none pending"
affects: [19-05, phase-20-verify-proves-the-bulk-stow, phase-21-capture]

# Actuals (#2632) — same estimateTokens scale (chars/4) as the plan's estimate.
actuals:
  tokens: 14000
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Prove a property of a vacuous code path from a staged fixture, and assert the vacuity explicitly so it cannot be mistaken for coverage"
    - "Assert a findings count by EXACT VALUE before asserting a promotion, so a fixture that produced zero findings fails rather than satisfying the promotion trivially"
    - "Prove independence from a component read-only — source text plus a scratch fixture reproducing its absent shape — rather than by removing the real one and restoring it"
    - "Self-checks that read the arrays the rest of the script appends to, so coverage extends itself when a section is added"
    - "A source gate composes its own probe pattern from halves, so the gate does not count itself"

key-files:
  created: []
  modified:
    - "scripts/phase19-link-aware-verify-assert.sh — Section 6, Section 7, Section 8, build_capture_fixture(), build_backup_fixture(), build_d47_fixture(), capture_tree_lines(), same_above_summary(), teardown_scratch_roots(), porcelain_snapshot_raw(), the TMP_FILES array, the two porcelain-bracket gates, the completed criteria summary, and the section-index header"

key-decisions:
  - "D-32's prediction that the firstrun auto-backup branch leaves an [INFO] installer-artifact sibling is FALSIFIED on a stowed path and the assert encodes the measured behaviour instead — `mv` renames the SYMLINK, so the sibling is a link into the repo at an undeclared path and classify_sweep_entry() tests -L before it reaches the artifact-shape arm"
  - "The artifact-shape [INFO] D-32 wanted from the `.old` suffix is asserted where the primitive really produces one — on an UNSTOWED target in the shared root, which is the shape all nineteen artifacts on the real tree have — so the arm-6-before-arm-8 regression guard is kept without staging a shape the primitive does not produce"
  - "The vendored submodule path is composed from two halves into VENDOR_PATH and never written as one literal in an executable line, so the D-47 source gate reads the script honestly; this also fixed a pre-existing hit from 19-01's usage-text assertion"
  - "The empty-shape case is asserted against the SAME fixture built with no capture/ directory at all, so the claim is that a package-less capture/ is indistinguishable from an absent one rather than merely quiet"
  - "same_above_summary() was extracted rather than copied, so Section 3 and Section 6 make D-14's identical-above-the-summary claim through one comparison"
  - "porcelain_snapshot() was split into a raw half and a filtering half, which turns 'the ignored form at both ends' into a structural property with exactly one invocation to gate"
  - "Section 8 asserts only the exit code; the summary line and the four label counts are emitted as [INFO] with an in-line warning against a later reader 'strengthening' them into expectations (D-36)"

patterns-established:
  - "Measured-deviation comments carry the falsifying transcript inline, so the next reader sees the evidence rather than an unexplained divergence from a decision record"
  - "A mid-run teardown is asserted, not assumed: the scratch-root array is walked and each root's absence is checked before the section that depends on it"

requirements-completed: [VER-02, VER-03]

coverage:
  - id: D1
    description: "capture/ content drift is a [FINDING] of its own class, never a [FAIL], and never moves the exit code on its own"
    requirement: VER-02
    verification:
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 6 — staged capture/ package, live bytes differ from the repo mirror: [FINDING] names the live path as content drift, no [FAIL] names it, counters asserted by exact value FAIL=0 FINDINGS=1, rc=0"
        status: pass
    human_judgment: false
  - id: D2
    description: "The two capture/ [FINDING] sources and the one capture/ [FAIL] are each proven from their own fixture"
    requirement: VER-02
    verification:
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 6 — absent live counterpart: [FINDING], FAIL=0 FINDINGS=1, rc 0 bare and rc 1 under --strict"
        status: pass
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 6 — live path is a symlink into the repo: [FAIL] naming it wrongly stowed, FAIL=1 FINDINGS=0, rc=1 with no flag"
        status: pass
    human_judgment: false
  - id: D3
    description: "A capture/ tree holding only README.md — the shape of the real tree today — produces no capture-tree line and cannot change the verdict; and capture-path listing order is stable across runs"
    requirement: VER-02
    verification:
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 6 — package-less capture/ tree emits none of the four capture-tree message stems, and rc and both counters equal those of the same fixture built with no capture/ directory"
        status: pass
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 6 — a five-file capture/ package lists identically across two consecutive runs (cmp over the extracted capture-tree lines)"
        status: pass
    human_judgment: false
  - id: D4
    description: "--strict exits 1 on a fixture that has findings and no failures, and the identical fixture exits 0 without the flag, with output byte-identical above the summary line"
    requirement: VER-03
    verification:
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 6 — same fixture: rc 0 bare, rc 1 under --strict, FAIL=0 and FINDINGS=1 in both, same_above_summary() over the two captures"
        status: pass
      - kind: integration
        ref: "./arch/dots-hyprland.sh verify --strict on the real tree — exit 0, so --strict is a promotion of findings and not a blanket demotion of green"
        status: pass
    human_judgment: false
  - id: D5
    description: "Both branches of the installer's auto-backup primitive are covered, and they land on opposite sides of the link/content boundary"
    requirement: VER-03
    verification:
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 7 firstrun — [FAIL] 'not a symlink' carrying a stow -t recovery naming the package, the renamed-aside sibling on its own [FAIL], rc=1, FAIL=2 FINDINGS=0"
        status: pass
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 7 non-firstrun — [PASS] on the intact link, [INFO] installer backup artifact on the .new sibling, rc=0, FAIL=0 FINDINGS=0"
        status: pass
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 7 — a regular-file backup sibling staged in the SHARED ROOT still produces its [INFO], proving the artifact-shape arm runs before the shared-root exemption"
        status: pass
    human_judgment: false
  - id: D6
    description: "verify's independence from the vendored submodule is proven read-only, with the real submodule untouched"
    requirement: VER-03
    verification:
      - kind: static
        ref: "run_verify()'s body extracted from arch/dots-hyprland.sh and stripped of comments (320 lines) names neither the vendored submodule path nor preflight — asserted both by the plan's verify command and by Section 7's own in-script gate"
        status: pass
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 7 — scratch repo with a committed .gitmodules naming the vendored path beside that path as an EMPTY directory: verify exits 0; the [PASS] carries the literal token D-47"
        status: pass
      - kind: integration
        ref: "git submodule status before and after the full run — 1a9ffb78f0c272a45f82342587dc3bec72762233 unchanged; git status --porcelain -- vendor/dots-hyprland empty"
        status: pass
    human_judgment: false
  - id: D7
    description: "ROADMAP criterion 5 is CHECKED rather than asserted: a read-only run against the real $HOME after every fixture is torn down, failing only if it does not exit 0"
    requirement: VER-03
    verification:
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 8 — teardown_scratch_roots() then 17 scratch roots asserted gone, ./arch/dots-hyprland.sh verify rc=0 and verify --strict rc=0, the summary line and four label counts emitted as [INFO] and asserted nowhere"
        status: pass
      - kind: e2e
        ref: "two back-to-back full assert runs produce the same [PASS] count (80), which is what proves no fixture survived the first run to change the second"
        status: pass
    human_judgment: false
  - id: D8
    description: "The assert mutates nothing outside its own scratch, and the self-check that proves it covers every path the script creates"
    requirement: VER-03
    verification:
      - kind: integration
        ref: "git status --porcelain --ignored bracketed around a full assert run — byte-identical, naming no fixture path"
        status: pass
      - kind: e2e
        ref: "the fixture-leak sweep reads TMP_FILES and SCRATCH_ROOTS and reports 31 paths swept (14 temp files, 17 scratch roots), none named by git status"
        status: pass
      - kind: e2e
        ref: "the two porcelain-bracket gates — exactly one `git status --porcelain` invocation in the file and it carries --ignored; the filter removed exactly the 2 anchored-pattern lines out of 13 raw"
        status: pass
    human_judgment: false
  - id: D9
    description: "An operator reads Section 8's [INFO] lines against a full verify transcript and confirms nothing on the list is a surprise"
    requirement: VER-03
    verification: []
    human_judgment: true
    rationale: "The plan's own <human-check> for Task 3, deliberately unautomated: the assert checks that the tree is green, not that green is the right answer. Deferred to end-of-phase verification per workflow.human_verify_mode."

duration: 12 min
completed: 2026-09-14
status: complete
---

# Phase 19 Plan 04: Link-aware `verify` — capture/ drift, `--strict` promotion, and the real-tree check Summary

Three assert sections that prove what a clean tree cannot: `capture/` drift is its own `[FINDING]` class, `--strict` promotes it to a failing exit code on a fixture that exits 0 without it, both branches of the installer's auto-backup primitive land on opposite sides of the link/content boundary, and `verify` is independent of the vendored submodule — proven read-only, with the operator's real checkout never touched.

- **Duration:** 12 min (12:48 → 13:00 local)
- **Tasks:** 3
- **Files modified:** 1 (`scripts/phase19-link-aware-verify-assert.sh`, +820/−19, 930 → 1731 lines)
- **Production code changed:** none. `arch/dots-hyprland.sh` reached its final Phase 19 state in plan 19-03 and is byte-unchanged by this plan.

## Accomplishments

**Section 6 — the findings-only `capture/` fixture and the `--strict` promotion.** `build_capture_fixture()` stages a `capture/` package in six shapes while holding the `stow/` side identical, so the `capture/` staging is the only variable between two runs. Content drift is asserted as a `[FINDING]` naming the live path AND asserted to be on no `[FAIL]` line — the two halves matter separately, because the interesting failure is the label class collapsing, not the path going unnamed. The counters are asserted by exact value (`FAIL=0 FINDINGS=1`) before the promotion is asserted at all: a fixture that produced zero findings would otherwise satisfy `--strict` trivially (T-19-11). The same fixture then exits 1 under `--strict` with `FAIL=` still 0, and the two captures are byte-identical above the frozen summary line. The absent-live-counterpart `[FINDING]` and the wrongly-stowed `[FAIL]` get their own fixtures; the empty shape — a `capture/` tree holding only `README.md`, which is the shape of the real tree — is asserted to emit no capture-tree line and to leave `rc` and both counters exactly where the same fixture built with no `capture/` directory leaves them.

**Section 7 — both branches of the installer's auto-backup primitive, and D-47.** Both branches are reproduced with plain shell commands inside separate fixtures; nothing in the section sources, executes, reads or stats anything under the vendored submodule, and the plan's source gate over the script's non-comment lines proves it. The firstrun branch is a loud failure (`[FAIL]` not-a-symlink carrying a `stow -t` recovery naming the package, exit 1); the non-firstrun branch is a silent survivor (`[PASS]` on the intact link, `[INFO]` on the `.new` sibling, exit 0) that only the sweep's artifact-shape arm reports at all. A regular-file artifact staged in the shared root still produces its `[INFO]`, which is the regression guard on the arm-6-before-arm-8 ordering — invert those arms and five of the nineteen artifacts on the real tree vanish from the report. D-47 is proven twice and read-only: a static gate over `run_verify()`'s own body (320 non-comment lines, naming neither the vendored path nor `preflight`) and a scratch fixture carrying a committed `.gitmodules` beside that path as an empty directory, over which `verify` exits 0.

**Section 8 — the read-only run against the real tree.** `teardown_scratch_roots()` removes every scratch root Sections 1–7 created and the removal is *asserted*, not assumed, because a leaked fixture would make this section's answer about the harness rather than about the tree (T-19-10). The section then asserts exactly one thing — `verify` exits 0, bare and under `--strict` — and records the summary line and the four label counts as `[INFO]`, with an in-line warning against a later reader turning either into an expectation. The closing self-check gained two structural gates on the porcelain bracket and a fixture-leak sweep that now reads the `TMP_FILES` and `SCRATCH_ROOTS` arrays instead of a hand-copied list, so it extends itself when a section is added. The criteria summary names all five ROADMAP criteria with none pending, and a section index heads the file.

## Verification Evidence

| Check | Result |
|---|---|
| `bash -n scripts/phase19-link-aware-verify-assert.sh` | clean |
| `./scripts/phase19-link-aware-verify-assert.sh` | exit 0, `=== done: FAIL=0 FINDINGS=0 ===`, **80 `[PASS]`** (was 50), 4 `[INFO]` |
| Two back-to-back assert runs | identical `[PASS]` count — `IDEMPOTENT_OK` |
| `git status --porcelain --ignored` bracketed around a full assert run | byte-identical; no fixture path named |
| `./arch/dots-hyprland.sh verify` | exit 0, `FAIL=0 FINDINGS=0`, 123 `[PASS]`, 33 `[INFO]` |
| `./arch/dots-hyprland.sh verify --strict` | exit 0 |
| Two consecutive real-tree `verify` runs | byte-identical |
| Task 1 verify block | `SECTION6_OK pass=63` |
| Task 2 verify block 1 | `SECTION7_OK pass=75` (no `assert_depends_on_vendor`) |
| Task 2 verify block 2 | `D47_HOLDS` |
| Task 3 verify block 1 | `SECTION8_OK pass=80 info=4` |
| Task 3 verify block 2 | `IDEMPOTENT_OK` |
| `./scripts/phase18-capture-model-assert.sh` | exit 0, `FAIL=0 FINDINGS=0` |
| `grep -ho -- '--verbose=5 --no-folding' arch/*.sh \| wc -l` | 18 |
| `grep -c 'XDG_CONFIG_HOME' arch/dots-hyprland.sh` | 4 |
| `grep -c 'pending' scripts/phase19-link-aware-verify-assert.sh` | 0 |
| `git submodule status` before/after | `1a9ffb78…` unchanged; `git status --porcelain -- vendor/dots-hyprland` empty |

## Deviations from Plan

### 1. [Rule 1 — falsified expectation] D-32's firstrun `[INFO]` prediction does not hold on a stowed path

- **Found during:** Task 2, before a line of Section 7 was written — the primitive's effect was staged on a throwaway fixture first, exactly because the plan says an assertion that fails is more likely to encode the wrong expectation than to indicate broken code.
- **Issue:** D-32 (and the plan's acceptance criteria) predict that the firstrun branch leaves its `.old` sibling on an `[INFO]` line naming it an installer backup artifact. On a *stowed* path it cannot: `mv $t $t.old` renames the **symlink**, so the sibling is a symlink into the repo at a path the repo never declared, and `classify_sweep_entry()` tests `-L` before it ever reaches the artifact-shape arm. Arm 2 claims it first.
- **Evidence** (scratch fixture, faithful reproduction of `mv $t $t.old` then `cp $s $t`):
  ```
  [FAIL] not a symlink: …/home/.config/fixpkg/conf — recover with: cd stow && stow -t ~ fixture
  [INFO] unclaimed upstream stub: …/home/.config/fixpkg/conf
  [FAIL] stale link into repo at an undeclared path:
         …/home/.config/fixpkg/conf.old -> …/repo/stow/fixture/.config/fixpkg/conf
  === done: FAIL=2 FINDINGS=0 ===
  ```
- **Fix:** No production code changed. The assertion encodes the measured behaviour and the falsifying transcript is quoted inline in the section's header comment so the divergence from D-32 is not left unexplained. The result is *louder* than D-32 predicted, not quieter — the firstrun branch remains the loud half of the section's contrast, and it now reports two distinct failures instead of one.
- **Coverage not lost:** the artifact-shape `[INFO]` D-32 wanted from the `.old` suffix is asserted where the primitive genuinely produces one — on an **unstowed** target in the shared root, which is the shape all nineteen artifacts on the real tree have. That placement also satisfies the plan's arm-6-before-arm-8 regression guard, so nothing the plan asked for went unproven; only the fixture that proves it moved.
- **Files modified:** `scripts/phase19-link-aware-verify-assert.sh`
- **Commit:** `8d06b65`

### 2. [Rule 3 — blocker] The plan's own D-47 source gate was red against pre-existing code

- **Found during:** Task 1 (discovered while preparing Task 2's gate).
- **Issue:** Task 2's verify block fails with `assert_depends_on_vendor` if any non-comment line of the assert names the vendored submodule path. Line 380, written in plan 19-01, greps the wrapper's usage text for `'thin wrapper for vendor/dots-hyprland'` — a string comparison against output, not a dependency, but indistinguishable to the gate.
- **Fix:** The path is composed from two halves into `VENDOR_PATH` at the top of the script, with a comment stating why, and the usage assertion now interpolates it. The assertion is unchanged in what it proves. `VENDOR_PATH` is reused by the D-47 fixture's `.gitmodules`.
- **Files modified:** `scripts/phase19-link-aware-verify-assert.sh`
- **Commit:** `26d6741`

### 3. [Rule 3 — blocker] The porcelain-invocation gate counted itself

- **Found during:** Task 3.
- **Issue:** The new "exactly one `git status --porcelain` invocation" gate, written as one literal, matched its own grep, both of its verdict messages, and every comment sentence mentioning the command — reporting 11 invocations on a script that makes one.
- **Fix:** The gate composes its probe pattern from three halves (`PC_HEAD`/`PC_TAIL`/`PC_IGN`), scans only non-comment lines, and both verdict messages interpolate the same variables. The two bracket-comparison messages were reworded to interpolate them as well. The gate now reports 1 and 1.
- **Files modified:** `scripts/phase19-link-aware-verify-assert.sh`
- **Commit:** `9223081`

**Total deviations:** 3 auto-fixed (1 falsified expectation, 2 blocking issues). **Impact:** No production code changed; `arch/dots-hyprland.sh` is byte-identical to its 19-03 state. Deviation 1 is a correction to a CONTEXT decision record and should be carried into `19-CONTEXT.md`'s D-32 when the phase is verified — it is recorded here and in the script's own comment block rather than silently absorbed.

## Known Stubs

None. No placeholder, no `TODO`, no skipped test, and no `<verify>` block left unrun. No `.planning/WINDOWS.md` entry is filed: the one falsified expectation is closed in-plan with a passing assertion over measured behaviour, and recording a resolved item as an open window would create a false ship blocker.

The pre-existing `scripts/phase17-unblock-assert.sh` `FAIL=8` (WINDOWS entry 7) and the `scripts/phase13-d19-assert.sh` red window (closes in 19-05) are untouched by this plan, which changed no production code and therefore neither widened nor closed either.

## Outstanding Human Check

Task 3 carries a `<human-check>` the assert deliberately does not make: read Section 8's `[INFO]` lines and a full `./arch/dots-hyprland.sh verify` transcript, and confirm the 33 `[INFO]` conditions on the real tree are ones you recognise — the installer backup files you know about, the unclaimed stubs you have not claimed yet, and the Steam links that dangle when Steam is not running. The assert checks that the tree is green; it does not check that green is the right answer. Deferred to end-of-phase verification per `workflow.human_verify_mode: end-of-phase`.

## Threat Flags

None. This plan changed no production code and introduced no network endpoint, auth path, file-access pattern or schema change. Every fixture lives under `mktemp -d` outside the repo, is registered with the EXIT trap before its first write, is torn down before the real-tree run, and is swept by the closing self-check.

## Next Phase Readiness

**Ready for 19-05.** ROADMAP criteria 2, 3 and 5 are now covered by the assert, and criteria 1 and 4 were covered in 19-03 and 19-01/19-03 respectively — the `=== Phase 19 ROADMAP Criteria Summary ===` block names all five with none pending. Plan 19-05 owns the carried red window: `./scripts/phase13-d19-assert.sh` remains red for the wrapper drift pin, which this plan neither widened nor closed.

## Self-Check: PASSED

- `scripts/phase19-link-aware-verify-assert.sh` exists on disk (1731 lines) — FOUND
- `26d6741` — FOUND in `git log --oneline --all`
- `8d06b65` — FOUND in `git log --oneline --all`
- `9223081` — FOUND in `git log --oneline --all`
- All task `<acceptance_criteria>` re-run after the final commit; all pass (see Verification Evidence)
- Plan-level `<verification>` re-run after the final commit; all seven items pass
