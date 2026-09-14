---
phase: 19-link-aware-verify
plan: 03
subsystem: infra
tags: [bash, stow, symlinks, git, verify, filesystem-walk, adversarial-test]

# Dependency graph
requires:
  - phase: 19-link-aware-verify
    provides: "19-01's flag parser, pre-walk precondition block with required_bins, relocated main_root/main_root_real resolution, and scripts/phase19-link-aware-verify-assert.sh with its fixture builder, runner and guard_scratch_target()"
  - phase: 19-link-aware-verify
    provides: "19-02's folded-ancestor pre-check and dangling-into-repo arm in the repo-side walk, git and realpath as hard required binaries, and the D-21 repo-vs-HEAD / untracked [INFO] observations"
  - phase: 18-capture-model-three-trees-and-the-collision-map
    provides: "run_verify()'s repo-side walk, the capture/ block, and the four-label / two-counter output contract the sweep appends to"
provides:
  - "The live-side sweep: a separate labelled pass in run_verify() that starts from the live filesystem instead of the repo, bounded to the 29 managed directories the repo trees imply"
  - "A bounded root set derived in one traversal of stow/*/ and restow/*/, resolved through $HOME only, with the dirname-returns-dot case canonicalised so the six files stowed directly at $HOME do not produce a thirtieth root"
  - "Exactly one directory-level line per managed root on every run: [INFO] absent, [FAIL] unreadable, [PASS] readable — an invariant line count regardless of what the tree holds"
  - "classify_sweep_entry(): D-03's single decision point, nine arms, governing every entry the sweep sees"
  - "The two conditions the repo-side walk structurally cannot see are now visible: a stale link into the repo at an undeclared path, and a link dangling into the repo at an undeclared path"
  - "resolve_dangling_target(): the raw-target resolution factored out of 19-02's repo-side dangling arm and shared with the sweep's dangling arms, so the two cannot drift"
  - "New message classes: [INFO] managed directory absent, [FAIL] unreadable managed directory, [FAIL] stale link into repo at an undeclared path, [INFO] installer backup artifact, [INFO] unclaimed upstream stub"
  - "Section 5 of the phase assert: one composite fixture staging all four sweep pathologies plus a missing-link case in five disjoint managed directories, asserting FAIL=4 FINDINGS=0 by exact value"
  - "The only live positive the folded-ancestor and dangling-into-repo checks have anywhere — neither has one on the real tree"
affects: [19-04, 19-05, phase-20-verify-proves-the-bulk-stow, phase-21-capture]

# Actuals (#2632) — same estimateTokens scale (chars/4) as the plan's estimate.
actuals:
  tokens: 29000
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Bounded live-side sweep: enumerate the live filesystem, but only in directories the repo declares, never globally"
    - "One decision point per classification domain — a helper function whose every arm returns 0 explicitly"
    - "Deterministic enumeration at both levels: LC_ALL=C sort over associative-array keys, find -print0 | LC_ALL=C sort -z over directory entries"
    - "Resolution rules that two passes both need are factored into one helper rather than written twice"

key-files:
  created: []
  modified:
    - "arch/dots-hyprland.sh — the live-side sweep pass, classify_sweep_entry(), resolve_dangling_target()"
    - "scripts/phase19-link-aware-verify-assert.sh — Section 5, build_sweep_fixture(), the unreadable-directory case, the determinism case, cleanup() permission restore"

key-decisions:
  - "The sweep is a separate pass appended after the capture/ block, leaving the Phase 18 repo-side loop byte-unchanged (D-07); Task 1's diff was pure insertion, zero deleted lines"
  - "The XDG config-home variable is named obliquely in the sweep's comments rather than literally, because it is in scope and tempting, and because the sibling assert convention counts literal tokens in arch/*.sh"
  - "resolve_dangling_target() sets two of run_verify()'s locals rather than printing, because both the canonicalised target (for the prefix test) and the raw target (for the message) are needed at every call site"
  - "An entry that is a regular file at a DECLARED path falls to arm 7 ([INFO] unclaimed upstream stub) rather than arm 1's skip, because arm 1's antecedent is a symlink; a destroyed link is correctly described twice, once as a repo-side [FAIL] and once as a sweep [INFO]"
  - "A fifth disjoint managed directory carries the missing-link case, because D-04's folded-ancestor suppression would hide it if co-located"

patterns-established:
  - "Placeholder-with-a-voice: a stubbed call site emits an [INFO] saying it is not yet implemented rather than passing silently, so an intermediate commit cannot be mistaken for a clean run"
  - "Composite adversarial fixtures stage pathologies in disjoint directories and assert counters by exact value, so a masked pathology surfaces as a counter mismatch rather than a passing run"
  - "Cleanup restores permissions (chmod -R u+rwX) before rm -rf, so a fixture that deliberately makes a directory unreadable can never leave an undeletable scratch root behind"

requirements-completed: [VER-01]

coverage:
  - id: D1
    description: "The live-side sweep derives 29 managed roots deterministically from the repo trees and emits exactly one directory-level line per root"
    requirement: VER-01
    verification:
      - kind: integration
        ref: "./arch/dots-hyprland.sh verify — 29 'managed directory' lines, 123 [PASS] (94 repo-side + 29 sweep), FAIL=0 FINDINGS=0, exit 0"
        status: pass
      - kind: integration
        ref: "two consecutive ./arch/dots-hyprland.sh verify runs compared with [ \"$A\" = \"$B\" ] — byte-identical"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every live entry in a managed directory gets its verdict from one classifier; the five installer artifacts in $HOME and $HOME/.config stay visible and the two non-repo dangling links stay [INFO]"
    requirement: VER-01
    verification:
      - kind: integration
        ref: "./arch/dots-hyprland.sh verify — 33 [INFO] lines (19 installer artifacts + 11 unclaimed stubs + 2 dangling-outside-repo + 1 repo-vs-HEAD), FAIL=0"
        status: pass
      - kind: integration
        ref: "./arch/dots-hyprland.sh verify --quiet — zero [PASS] lines, all 33 [INFO] lines retained"
        status: pass
    human_judgment: false
  - id: D3
    description: "The two conditions the repo-side walk structurally cannot see — a stale link into the repo at an undeclared path, and a link dangling into the repo — are caught, together with the folded ancestor and the dangling-outside-repo control"
    requirement: VER-01
    verification:
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 5 — composite fixture, four pathologies in disjoint managed directories, each named on its expected labelled line, rc=1"
        status: pass
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 5 — summary counters asserted by exact value: FAIL=4 FINDINGS=0"
        status: pass
    human_judgment: false
  - id: D4
    description: "An unreadable managed directory is [FAIL] naming the directory and moves the exit code to 1, never to 2"
    requirement: VER-01
    verification:
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh Section 5 — chmod 000 on a managed directory, rc=1, [FAIL] names the directory"
        status: pass
    human_judgment: false
  - id: D5
    description: "verify mutates nothing it inspects — the plan's stated prohibition, resolved by test"
    requirement: VER-01
    verification:
      - kind: integration
        ref: "git status --porcelain --ignored bracketed around a real ./arch/dots-hyprland.sh verify run — byte-identical before and after"
        status: pass
      - kind: e2e
        ref: "scripts/phase19-link-aware-verify-assert.sh closing self-check — porcelain identical, no fixture basename in the after-state, no /tmp/p19-* leftovers"
        status: pass
    human_judgment: false

# Metrics
duration: 20 min
completed: 2026-09-14
status: complete
---

# Phase 19 Plan 03: The Live-Side Sweep Summary

**`verify` now walks outward from the live filesystem as well as from the repo — 29 bounded managed directories, one nine-arm classifier, and the first live positive the folded-ancestor and dangling-into-repo checks have ever had.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-09-14T06:27:00Z
- **Completed:** 2026-09-14T06:47:12Z
- **Tasks:** 3 of 3
- **Files modified:** 2

## Accomplishments

- **The pass that can see what the repo never declared.** The existing walk starts from the repo and resolves outward, so it can only ever look at paths the repo already names. The sweep starts from the live filesystem instead, bounded to the 29 directories the repo trees imply, and catches the two conditions ROADMAP criterion 1 requires that were invisible by construction: a stale link into the repo at an undeclared path, and a link dangling into the repo at one.
- **A root set that is 29 and not 30.** Six `stow/` files live directly at `$HOME`, for which `dirname` returns a single dot. The canonicalisation to `$HOME` is what keeps `$HOME/.` from becoming a thirtieth root with a duplicate directory-level line. Measured on the real tree: 29 roots, 94 declared paths, both matching the research figures exactly.
- **One decision point, nine arms, zero false positives on the real tree.** A prototype of the classifier run against the live `$HOME` before any code was written measured arm 1 (declared link into repo, skip) at 94 and arm 2 (stale undeclared link) at **0** — which is what proves the declared-set key shape is right. Get that key shape wrong and a clean tree turns into 94 false stale-link failures.
- **The five artifacts that would otherwise have vanished.** Arm 6 (installer artifact shapes) is tested before arm 8's shared-root exemption, because D-05 exempts the shared roots from the unclaimed-stub clause *only*. Five of this tree's 19 installer artifacts sit in `$HOME` and `$HOME/.config`; inverting those two arms hides all five.
- **The only proof either 19-02 check works.** Neither the folded-ancestor check nor the dangling-into-repo arm has a live positive anywhere on the real tree — Phase 17 found two folded directories and Phase 18's redistribution resolved both. Section 5's composite fixture is the sole evidence either one functions.
- **Counter aggregation proven, not assumed.** Section 5 asserts `FAIL=4 FINDINGS=0` by exact value off a single run over five staged conditions. A silently-skipped or masked pathology surfaces as a counter mismatch rather than as a passing run.

## Task Commits

1. **Task 1: The bounded root set and the per-directory verdicts** — `123663c` (feat)
2. **Task 2: The entry classifier — one decision point, nine arms** — `85dbfbc` (feat)
3. **Task 3: Section 5 — all four sweep pathologies in one scratch `$HOME`** — `bd41820` (test)

## Files Created/Modified

- `arch/dots-hyprland.sh` — the live-side sweep pass inside `run_verify()` (root-set and declared-set derivation, per-directory verdicts, entry enumeration); `classify_sweep_entry()` with D-03's nine arms; `resolve_dangling_target()` factored out of 19-02's repo-side dangling arm and shared by both callers.
- `scripts/phase19-link-aware-verify-assert.sh` — Section 5 with `build_sweep_fixture()`, the composite four-pathology fixture, the missing-link recovery-text case, the unreadable-directory positional-rule case, the sweep-determinism case; `cleanup()` now restores permissions before removal; criterion 1 in the summary block now points at Section 5.

## Decisions Made

- **Task 1's diff was pure insertion — zero deleted lines.** That is the mechanical proof of D-07: the Phase 18 repo-side loop and the `capture/` block are byte-unchanged, and the frozen `=== done:` line was not touched.
- **The XDG config-home variable is named obliquely in the sweep's comments.** Task 1's action mandates a comment explaining why the sweep resolves through `$HOME` and not through XDG; its acceptance criterion requires `grep -c 'XDG_CONFIG_HOME' arch/dots-hyprland.sh` to be unchanged at 4. Writing the token literally in a comment satisfied the first and broke the second. The comment now makes the point in prose and records *why* it avoids the literal, so a later reader does not "fix" it back.
- **`resolve_dangling_target()` sets two of `run_verify()`'s locals rather than printing.** Both values are needed at every call site — the canonicalised target to test the repo prefix against, and the raw target to name in the message — and returning two values through stdout would have cost more at each call site than it saved. This follows the dynamic-scope convention `fail()`/`finding()` already use for the counters.
- **A regular file at a *declared* path falls to arm 7, not arm 1's skip.** Arm 1's antecedent is explicitly "symlink into repo"; a regular file sitting where a link should be is a genuinely different condition — it is precisely what a destroyed link looks like. Consequence, observed and accepted: in Section 1's `rsync` fixture the destroyed path is described twice, once as a repo-side `[FAIL] not a symlink` and once as a sweep `[INFO] unclaimed upstream stub`. Two angles on one broken path is informative; the "exactly once per run" invariant is about the healthy declared case, and the real tree proves it holds there (arm 1 = 94, arm 2 = 0, 123 `[PASS]` = 94 + 29 with no duplicates).
- **A fifth disjoint managed directory carries the missing-link case.** D-33's recovery-text assertion needs a `[FAIL] no live counterpart … stow -t` line, and D-04's folded-ancestor suppression would hide it if it were co-located with pathology 1. The same disjointness rule that separates the four sweep pathologies applies to it.

## Deviations from Plan

### 1. [Scope boundary — not fixed] Task 2's second `<verify>` block requires `scripts/phase17-unblock-assert.sh` to exit 0; it is pre-existing red

- **Found during:** Task 2 (the entry classifier)
- **Issue:** The gate `./scripts/phase19-… && ./scripts/phase17-unblock-assert.sh && ./scripts/phase18-… && [pair count -eq 18]` returns 1. Run individually: phase19 `rc=0 FAIL=0`, phase18 `rc=0 FAIL=0`, pair count 18 — only phase17 is red, at `FAIL=8`.
- **Disposition:** Not fixed. This is the pre-existing repo-root `.config/` condition that Phase 18's redistribution created and that has been dispositioned twice already; the dispatch brief names it explicitly as out of scope.
- **Evidence it is unrelated to this plan:** all 8 failures name repo-root `.config/…` paths and git-index state for `.config/kdeglobals` and `.config/hypr/custom/execs.lua`; `ls -d .config` at the repo root reports no such directory. `grep -c 'run_verify\|live-side sweep\|classify_sweep' scripts/phase17-unblock-assert.sh` is **0** — that assert never reads any symbol this plan touches. Its one check over `arch/*.sh`, the `--verbose=5 --no-folding` pair count, passes at 18.
- **Ledger:** already recorded as open entry 7 in `.planning/WINDOWS.md`, filed by 19-01 against the identical criterion. No duplicate row added.
- **Files modified:** none.

### 2. [Rule 3 - Blocker] The mandated XDG comment broke the XDG token-count criterion

- **Found during:** Task 1
- **Issue:** Task 1's action says to "add a comment saying so, because the variable is in scope and looks tempting"; its acceptance criterion says `grep -c 'XDG_CONFIG_HOME' arch/dots-hyprland.sh` must be unchanged from its pre-task value of 4. The first comment written raised it to 5.
- **Fix:** Reworded the comment to make the same point without the literal token, and added a line recording *why* it is named obliquely, so the next reader does not restore the literal and re-break the count.
- **Verification:** `grep -c 'XDG_CONFIG_HOME' arch/dots-hyprland.sh` → 4, matching the pre-task baseline.
- **Committed in:** `123663c` (part of the Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 3 — blocker), 1 pre-existing condition documented and deliberately not fixed (scope boundary).
**Impact on plan:** No scope creep. The Rule 3 fix is cosmetic in effect and preserves both halves of a genuinely conflicting task specification. The phase17 condition is unchanged by this plan in either direction.

## Verification Evidence

Plan-level `<verification>`, re-run on the real tree at close-out:

| Check | Result |
|---|---|
| `bash -n` on both files | clean |
| `./arch/dots-hyprland.sh verify` | exit 0, `=== done: FAIL=0 FINDINGS=0 ===` |
| `[PASS]` count ≥ 120 | **123** (94 repo-side + 29 sweep) |
| `[INFO]` count ≥ 25 | **33** (19 artifacts + 11 stubs + 2 dangling-outside + 1 repo-vs-HEAD) |
| Two consecutive runs byte-identical | yes |
| `git status --porcelain --ignored` bracketed around a run | byte-identical |
| `./arch/dots-hyprland.sh verify --quiet` | exit 0, 0 `[PASS]`, all 33 `[INFO]` retained |
| Composite fixture: four pathologies, labelled lines, exit 1, exact counters | all named, `rc=1`, `FAIL=4 FINDINGS=0` |
| Unreadable managed directory | `rc=1`, never 2; `[FAIL]` names the directory |
| `./scripts/phase19-link-aware-verify-assert.sh` | exit 0, `FAIL=0 FINDINGS=0`, **50** `[PASS]` |
| `./scripts/phase18-capture-model-assert.sh` | exit 0, `FAIL=0 FINDINGS=0` |
| `./scripts/phase17-unblock-assert.sh` | `FAIL=8` — pre-existing, see Deviations |
| stow flag-pair count `grep -ho -- '--verbose=5 --no-folding' arch/*.sh \| wc -l` | **18**, unchanged |
| `grep -c 'XDG_CONFIG_HOME' arch/dots-hyprland.sh` | **4**, unchanged |
| `/tmp/p19-*` after an assert run | none |

**On the determinism assertion's strength (stated honestly).** Section 5's byte-identical check over 5 managed roots is a weaker instrument than the real-tree check over 29: bash's hash function is not randomised between processes, so associative-array iteration over an identical insertion sequence would repeat even without the `LC_ALL=C sort`. What both checks genuinely prove is that `find`'s directory-order output — which *is* filesystem-dependent — does not leak into the report, because the entry enumeration is sorted. The root-level `LC_ALL=C sort` is justified by the same reasoning applied to insertion order, which changes whenever a package is added or renamed; it is defence against a future tree, not against a second run of this one.

## Issues Encountered

None beyond the two documented deviations. All three tasks passed their `<verify>` blocks on first execution; no fix-attempt budget was consumed on implementation defects.

## Known Stubs

None. The Task 1 placeholder classifier and its per-directory `[INFO]` were both removed by Task 2, as the plan specified; `grep 'not yet implemented' arch/dots-hyprland.sh` returns nothing.

## Threat Flags

None. The files changed introduce no new network endpoint, auth path or schema. The two surfaces this plan does add — live filesystem entry names and symlink targets flowing into the classifier, and managed-directory permissions flowing into the sweep's verdict — are both already in the plan's `<threat_model>` as T-19-05 and T-19-02/T-19-08, and each is mitigated as written: `find -print0` with `while IFS= read -r -d ''` and never bash globbing, `--` before every path argument, every expansion quoted, canonicalised strings on every repo-prefix test, and a read-only contract proven by the porcelain bracket.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Ready for 19-04.** Plan 19-04 owns the remaining assert coverage: ROADMAP criterion 2 (`capture/` drift as its own finding class), criterion 3's findings-only `--strict` promotion case (which needs a `capture/` package staged in the scratch repo — after D-06 and D-21, `capture/` is the only `[FINDING]` source left in this phase), and criterion 5's green-on-today's-tree check. The sweep's `[INFO] unclaimed upstream stub` class that criterion 5's second half needs is shipped and live.

**Carried red window, unchanged and expected:** `./scripts/phase13-d19-assert.sh` remains red for the wrapper drift pin. This plan landed the last wrapper edit of the phase, as the plan's objective anticipated, so 19-05's re-pin will resolve against `85dbfbc` — the final state of `arch/dots-hyprland.sh` for Phase 19.

**One condition for a later phase to decide, not a blocker.** The `assumption_delta_decision` names the promote trigger: a third pass needing the same classification, or any observed case where the repo-side pass and the sweep reach different verdicts about the same path. One adjacent case now exists in the record — a regular file at a declared path draws a repo-side `[FAIL]` and a sweep `[INFO]` (see Decisions Made). These are not conflicting verdicts about the same question, so the trigger has not fired; a future reader evaluating a promote should start there.

## Self-Check: PASSED

- `arch/dots-hyprland.sh` — FOUND
- `scripts/phase19-link-aware-verify-assert.sh` — FOUND
- `.planning/phases/19-link-aware-verify/19-03-SUMMARY.md` — FOUND
- commit `123663c` — FOUND
- commit `85dbfbc` — FOUND
- commit `bd41820` — FOUND

---
*Phase: 19-link-aware-verify*
*Completed: 2026-09-14*
