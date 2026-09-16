---
phase: 19-link-aware-verify
plan: 02
subsystem: testing
tags: [bash, stow, symlinks, git, dangling-links, folded-directories, content-observation]

# Dependency graph
requires:
  - phase: 19-link-aware-verify
    provides: "19-01's flag parser, the pre-walk precondition block with its `required_bins` local array and relocated `main_root` resolution, and `scripts/phase19-link-aware-verify-assert.sh` with its fixture builder, runner and guard_scratch_target()"
  - phase: 18-capture-model-three-trees-and-the-collision-map
    provides: "run_verify()'s repo-side walk, the four-label two-counter output contract, and the `stow -t` recovery-message shape"
provides:
  - "A per-directory folded-ancestor pre-check in run_verify()'s repo-side walk — one [FAIL] per folded component carrying an unstow-plus-re-stow recovery, never one [FAIL] per file underneath it"
  - "A dangling-into-repo arm reading the RAW link target and resolving it manually — [FAIL] when it lands under the repo (PITFALLS A-6), [INFO] otherwise"
  - "`realpath` as a declared required binary, and canonicalised repo-prefix comparison for both new arms (T-19-02)"
  - "`git` as a declared required binary — its absence is `[FAIL] precondition:` on fd 2 and exit 2 before the walk starts, so get_main_repo_root()'s $REPO_ROOT fallback is unreachable from `verify` (D-23, one-way)"
  - "D-21's repo-vs-HEAD content observation as [INFO], per file, placed after the passing link assertion"
  - "The untracked-repo-side-file [INFO] class, fed by a single batched `git ls-files -z -- stow restow` read before the walk (RESEARCH Pitfall 5)"
  - "scripts/phase19-link-aware-verify-assert.sh Section 4 — the cp-through boundary and the untracked-file case, 38 [PASS] lines total"
affects: [19-03, 19-04, 19-05]

actuals:
  tokens: 5575
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Two memos for one per-directory check: a per-live-directory verdict cache (walk once per directory, not once per file) plus a per-component reported-set (two managed directories under one folded component still emit exactly one [FAIL])"
    - "Canonicalise before every repo-prefix test — `realpath -m --` on the joined target, matching the safe_rm_path idiom already in this file"
    - "Batch the set membership, keep the per-file comparison: one `git ls-files -z` read before a 94-iteration walk, against D-21's deliberately literal per-file `git diff --quiet HEAD`"
    - "A precondition that is positionally above its consumer is what makes a dependency hard — `git` is checked before get_main_repo_root() runs, so the helper's fallback is unreachable rather than merely discouraged"

key-files:
  created: []
  modified:
    - arch/dots-hyprland.sh
    - scripts/phase19-link-aware-verify-assert.sh

key-decisions:
  - "The dangling arm canonicalises the joined target with `realpath -m --` before the repo-prefix test, because stow writes RELATIVE targets and a literal prefix test on `../../github_repo/.dotfiles/stow/…` never matches the repo root — found by probe, not by reading"
  - "`realpath` was added to `required_bins` because the two new arms now depend on it; an undeclared dependency that only matters on a pathological tree is a verdict that degrades silently in exactly the case it exists for"
  - "The folded-ancestor recovery text is the non-adjacent `stow -D --no-folding … && stow --no-folding …` form, so `scripts/phase17-unblock-assert.sh`'s counted `--verbose=5 --no-folding` pair stays at 18 and this file keeps contributing zero"
  - "D-23 resolved `hard-dependency` at the Task 2 blocking-human checkpoint: absent `git` is exit 2, with no soft-degrade arm. A second, quieter meaning for a green run that a caller cannot tell apart from a full one is worse than a refusal"
  - "`get_main_repo_root()`'s $REPO_ROOT fallback is left in place as shared code and made UNREACHABLE from `verify` by position, rather than deleted — `run_capture()` is its other caller, has no precondition block, and is outside this plan's scope"
  - "The repo-side [INFO] lines print the ABSOLUTE canonical repo path rather than the repo-relative one, so an operator can act on the line without reconstructing a root"
  - "run_capture()'s pre-existing single-path `git ls-files` trackedness probe is left untouched: the anti-pattern research names is batch-versus-per-file inside a 94-iteration walk, not the probe itself"

patterns-established:
  - "Prefix tests against the repo compare canonicalised strings on BOTH sides (`main_root_real`), never a literal prefix on an unresolved argument"
  - "A file-wide forbidden-literal gate constrains COMMENTS as well as code — a comment naming the banned flag turned the gate red and had to be reworded"

requirements-completed: [VER-01]

coverage:
  - id: D1
    description: "A managed file whose ancestor directory is itself a symlink into the repo produces exactly one [FAIL] for that directory, carrying an unfold command, and not one [FAIL] per file underneath it"
    requirement: "VER-01"
    verification:
      - kind: integration
        ref: "scratch fixture: folded $HOME/.config/fxpkg -> repo stow package; asserts rc=1, exactly one [FAIL], recovery command present -> FOLDED_OK"
        status: pass
    human_judgment: false
  - id: D2
    description: "A declared live path that is a symlink whose target does not exist is [FAIL] when the unresolved target lands under the repo (PITFALLS A-6) and [INFO] otherwise, with the raw target read by a bare `readlink` and resolved manually"
    requirement: "VER-01"
    verification:
      - kind: integration
        ref: "scratch fixture: absolute dangling-into-repo link and non-repo dangling link in one run -> [FAIL] + [INFO], FAIL=1"
        status: pass
      - kind: integration
        ref: "scratch fixture: RELATIVE dangling target `../../../repo/stow/…/gone` -> [FAIL], FAIL=1 (the live shape stow actually writes)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The two new link checks do not fire on the real tree, which is measured to have zero folded ancestors and zero repo-bound dangling links"
    requirement: "VER-01"
    verification:
      - kind: integration
        ref: "./arch/dots-hyprland.sh verify -> `=== done: FAIL=0 FINDINGS=0 ===`"
        status: pass
      - kind: integration
        ref: "./scripts/phase19-link-aware-verify-assert.sh -> FAIL=0 FINDINGS=0"
        status: pass
    human_judgment: false
  - id: D4
    description: "`git` is a declared required binary: its absence is a precondition failure with exit 2, decided before the walk starts (D-23)"
    requirement: "VER-01"
    verification:
      - kind: integration
        ref: "minimal-PATH probe (env bash find readlink cmp dirname basename mktemp realpath sed grep cat, no git) -> rc=2 with `precondition` on fd 2 -> GIT_PRECONDITION_OK"
        status: pass
    human_judgment: false
  - id: D5
    description: "A cp-through destruction is reported as a content observation, not a link failure: the link still [PASS]es, verify still exits 0, and the repo file's divergence from HEAD appears as [INFO] (D-27)"
    requirement: "VER-01"
    verification:
      - kind: integration
        ref: "scripts/phase19-link-aware-verify-assert.sh#Section 4 — cp-through case: link still -L, repo file holds the vendor payload, rc=0, live path on [PASS], repo path on a differs-from-HEAD [INFO], summary FAIL=0 FINDINGS=0"
        status: pass
    human_judgment: false
  - id: D6
    description: "A stow/ or restow/ repo-side file that exists on disk but was never committed is reported as its own [INFO] class, distinct in wording from the differs-from-HEAD one (RESEARCH Pitfall 5)"
    requirement: "VER-01"
    verification:
      - kind: integration
        ref: "scripts/phase19-link-aware-verify-assert.sh#Section 4 — untracked case: never-committed repo file stowed, rc=0, its own untracked [INFO], NO differs-from-HEAD line names it, summary FAIL=0 FINDINGS=0"
        status: pass
    human_judgment: false
  - id: D7
    description: "The real tree's one measured divergence is reported honestly and moves nothing: stow/fish/.config/fish/config.fish is named on an [INFO] line while the run still ends FAIL=0 FINDINGS=0"
    requirement: "VER-01"
    verification:
      - kind: integration
        ref: "./arch/dots-hyprland.sh verify -> `[INFO] repo file differs from HEAD: …/stow/fish/.config/fish/config.fish` with `=== done: FAIL=0 FINDINGS=0 ===` and exit 0"
        status: pass
    human_judgment: false

duration: 8 min
completed: 2026-09-14
status: complete
---

# Phase 19 Plan 02: The content observation and the two link observations the walk could not make — Summary

**`run_verify()`'s repo-side walk now sees the three things it structurally could not: a folded ancestor directory (one `[FAIL]` per folded component, never one per file), a link that dangles into the repo (raw target read and resolved manually, because `readlink -f` returns the empty string and would report a broken pair as `[PASS]`), and a repo-side file whose content no longer matches `HEAD` — the last as `[INFO]`, because an installer write-through and an uncommitted edit are indistinguishable. `git` became a hard dependency in the process, and Section 4 of the assert pins the boundary the cp-through destruction sits exactly on.**

| Task | Name | Type | State |
|------|------|------|-------|
| 1 | Folded ancestor directories and links that dangle into the repo | `auto` | **Complete** — committed `0edddfe` |
| 2 | Make `git` a hard dependency of `verify` — its absence becomes exit 2 | `checkpoint:decision` `gate="blocking-human"` | **Complete** — decided `hard-dependency`, committed `15b4d0b` |
| 3 | The content observation, the untracked-file gap, and the cp-through boundary | `auto` | **Complete** — committed `7f12272` |

Task 2 was rated **one-way** (D-23 in `19-CONTEXT.md`) and halted execution at a `gate="blocking-human"` checkpoint, which is never auto-approved in any mode. The human answered `hard-dependency`; a fresh continuation agent resumed at Task 2 and carried the plan to completion on the main working tree (worktree isolation was degraded to sequential for this dispatch — local HEAD had diverged from `origin/HEAD`).

## Performance

- **Duration:** 8 min wall across the checkpoint pause (Task 1: 2 min; Tasks 2–3: ~6 min). Excludes context load and the human decision window.
- **Started:** 2026-09-14T06:31:59Z
- **Halted at checkpoint:** 2026-09-14T06:34:09Z
- **Resumed and completed:** 2026-09-14T06:39:38Z
- **Tasks:** 3 of 3
- **Files modified:** 2

## Accomplishments

- **Folded-ancestor pre-check (D-04).** For each declared live path, the walk climbs the ancestor chain from the file's own directory up to (not including) `$HOME`, and a component that is itself a symlink resolving under the repo is a `[FAIL]` naming the component, its resolved target and the unfold command. It runs **before** the per-file `-e`/`-L` tests and `continue`s on a hit, so a folded directory is reported as a folded directory rather than as N misplaced links.
- **Two memos, not one.** `folded_verdict` caches the verdict per live directory (the chain is walked once per directory, not once per file); `folded_reported` caches which ancestor *components* have already been named. The second is what makes "one failure, not N" hold when two managed directories sit under one folded component — a single per-file memo would emit one `[FAIL]` per managed directory.
- **Dangling-into-repo arm (D-06 / PITFALLS A-6).** Positioned after the `-L` test and before the `readlink -f` equality comparison, because `readlink -f` returns the **empty string** for a dangling link: it both discards where the link pointed and compares equal to the equally-empty resolution of a missing repo-side target, so the existing equality test would report a broken pair as `[PASS]`. The arm reads the raw target with a bare `readlink --`, joins a relative one against the link's own directory, and splits `[FAIL]` (under the repo) from `[INFO]` (anywhere else).
- **The recovery text keeps the Phase 17 count at 18.** The folded `[FAIL]` names `stow -D --no-folding -t ~ <pkg> && stow --no-folding -t ~ <pkg>` — two invocations, each with the no-folding flag, and no verbosity flag anywhere, so `arch/dots-hyprland.sh` still contributes zero occurrences of the counted adjacent pair.
- **`git` is a hard dependency (D-23, `hard-dependency`).** It joined `required_bins`, which sits **above** the `get_main_repo_root()` call in the precondition block. That position is the whole mechanism: `verify` refuses with `[FAIL] precondition: required command not found on PATH: git` on fd 2 and exit 2 before the helper is ever called, so the helper's `$REPO_ROOT` fallback is unreachable from this subcommand. No soft-degrade arm exists, and the comment records the published-contract consequence and the one known future caller (BOOT-04, Phase 23) that provably has `git` by the time it calls `verify`.
- **D-21's content observation, honoured literally.** `git -C "$main_root" diff --quiet HEAD -- "$tree/$pkg/$rel"`, per file, placed immediately after the passing link assertion so a path that failed any link test never reaches it (D-46). The measured 0.437 s per-file cost against 0.006 s batched is recorded in a comment as known and accepted, so a later reader does not re-litigate it. A difference is `[INFO]`, never `[FINDING]`.
- **The untracked gap closed (RESEARCH Pitfall 5, Open Question 3).** The walk enumerates from the filesystem, so a never-committed repo-side file makes `git diff --quiet HEAD` return 0 — a literal statement that it matches `HEAD`, which is false. The tracked set is read **once**, before the walk, with a single `git ls-files -z -- stow restow` into an associative array; membership is tested per file and an untracked file gets its own `[INFO]` class, worded distinctly. Recorded in the code as an extension of D-21, not a new decision.
- **Assert Section 4 is the mirror of Section 1.** `PITFALLS.md` §30's claim is that both destroying installer primitives leave the repo file untouched, so a content-only `verify` reports no drift in exactly the case that matters — Section 1 proves that half by destroying the link. The mirror is that a link-only `verify` reports a clean `[PASS]` for a repo file overwritten **through** an intact link. Section 4 proves it: `cp -f` through the live stowed path, then `rc=0`, the live path on a `[PASS]`, the repo path on a differs-from-`HEAD` `[INFO]`, and `FAIL=0 FINDINGS=0`. A second case stages a never-committed repo file, stows it, and asserts its untracked `[INFO]` plus the *absence* of any differs-from-`HEAD` line naming it — proving the two classes are distinct rather than merely both present.
- **Everything is silent or informational on the real tree.** `verify` reports `=== done: FAIL=0 FINDINGS=0 ===` with exactly one new `[INFO]`: `stow/fish/.config/fish/config.fish`, the operator's own uncommitted edit, which is precisely the file D-21 predicted and precisely the reason it is `[INFO]`.

## Task Commits

1. **Task 1: Folded ancestor directories and links that dangle into the repo** — `0edddfe` (feat)
2. **Task 2: `git` as a hard dependency — absent `git` is exit 2** — `15b4d0b` (feat)
3. **Task 3: The content observation, the untracked-file gap, and the cp-through boundary** — `7f12272` (feat)

**Plan metadata:** see the `docs(19-02)` commit that carries this file.

## Files Created/Modified

- `arch/dots-hyprland.sh` — `run_verify()`: `realpath` and `git` added to `required_bins`; `main_root_real` canonicalised once in the precondition block; the `folded_verdict`/`folded_reported` associative memos and the ancestor-walk loop at the head of the per-file chain; the dangling arm between the `-L` test and the `readlink -f` equality comparison; the `tracked_repo_files` set populated from one `git ls-files -z -- stow restow` read before the walk; the two `[INFO]` emissions after the `pass "verified: …"` line. `run_capture()` untouched; the `capture/` block's `[FINDING]` untouched (D-22).
- `scripts/phase19-link-aware-verify-assert.sh` — Section 4 (cp-through case + untracked case, 9 asserts) inserted before the closing self-check; the ROADMAP criteria summary updated for criteria 1, 4 and 5.

## Decisions Made

- **The dangling arm canonicalises the joined target before the prefix test.** See Deviation 1 — the literal form silently misclassified the exact shape `stow` produces.
- **`realpath` became a declared required binary** rather than an assumed one. It is already the established idiom in this file (`safe_rm_path`, lines 462-470), and Task 3's minimal-PATH probe lists it, so declaring it costs nothing and closes a silent-degradation path.
- **`main_root_real` is computed once in the precondition block**, not per file. The pre-existing `capture/` block's unresolved `"$main_root"/*` comparison was left alone — it is outside this plan's changes (scope boundary).
- **D-23 resolved `hard-dependency`** at the Task 2 checkpoint. The alternative (`soft-degrade`) would have created a second, quieter meaning for a green run that a caller cannot distinguish from a full one, with nothing consuming the `[INFO]` that marked the difference.
- **The `$REPO_ROOT` fallback in `get_main_repo_root()` was made unreachable by position, not deleted.** Deleting it would change `run_capture()`, which is that helper's other caller, has no precondition block of its own, and is outside this plan's `files_modified` intent. The effect D-23 asks for — a git-less machine gets exit 2, never a degraded verdict — holds exactly, and is proven by the minimal-PATH probe.
- **The two new `[INFO]` lines print the absolute canonical repo path.** The repo-relative form is what `git` is asked about; the absolute form is what an operator can act on without reconstructing a root.
- **`run_capture()`'s pre-existing single-path trackedness probe stays.** The anti-pattern research names is 94 per-file `git` calls *inside a walk*, not the single-path form itself, which `mirror_is_capturable()` uses correctly (one path, on demand). See Deviation 3.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The dangling arm's repo-prefix test was written against an unresolved path and misclassified every relative target**

- **Found during:** Task 1 (probe of the `<done>` criterion, before committing)
- **Issue:** The plan and `19-RESEARCH.md` §Pattern 3 both specify joining the raw target against the link's directory and then `case`-matching the result against `"$main_root"/*`. Probed with the shape `stow` actually writes — a **relative** target — the joined string is `…/home/.config/fxpkg/../../../repo/stow/fx/.config/fxpkg/gone`. The `..` components are not collapsed, so the literal prefix never matches the repo root and a dangling link **into the repo** was reported as `[INFO] dangling symlink (outside repo)` with `FAIL=0`, exit 0. That is the precise inversion of PITFALLS A-6 — the condition the arm exists to make loud, reported as the benign one. It is also the tampering vector the plan's own `<threat_model>` names as **T-19-02**: "compare resolved strings against `"$main_root"/*`, never a literal prefix on the unresolved argument".
- **Fix:** The joined path is canonicalised with `realpath -m --` before the `case`, and both sides of every repo-prefix test now compare canonicalised strings (`main_root_real`, resolved once in the precondition block). `-m` is what allows canonicalising a path whose final component does not exist, which is the definition of the dangling case. `realpath` was added to `required_bins` so the new dependency is declared rather than assumed. `readlink -f` is still **not** used to make the D-06 split — the raw target is still read with a bare `readlink --` and is still what the message prints.
- **Files modified:** `arch/dots-hyprland.sh`
- **Verification:** a third scratch fixture staging a relative dangling target `../../../repo/stow/fx/.config/fxpkg/gone` now yields `[FAIL] dangling symlink into repo: … -> ../../../repo/stow/fx/.config/fxpkg/gone` with `FAIL=1` and exit 1; it yielded `[INFO]` and exit 0 before the fix. The absolute-target and non-repo fixtures are unchanged, and the real tree still reports `FAIL=0 FINDINGS=0`.
- **Committed in:** `0edddfe` (part of the Task 1 commit)

**2. [Scope boundary — not fixed] Two of Task 1's three assert-script acceptance criteria were unsatisfiable inside the git worktree, and one of the two resolved on the main tree**

- **Found during:** Task 1 (acceptance-criteria verification), re-measured during Task 3 on the main tree
- **Issue as recorded at the checkpoint:** the criterion requires `./scripts/phase19-link-aware-verify-assert.sh`, `./scripts/phase17-unblock-assert.sh` and `./scripts/phase18-capture-model-assert.sh` to all exit 0. Measured in the worktree: phase19 exited 0, phase17 exited 1 with `FAIL=9`, phase18 exited 1 with `FAIL=6`.
  - **phase18 `FAIL=6`** — all six failures named `vendor/dots-hyprland`, **empty in that worktree** and populated in the main checkout. Git worktrees do not populate submodules.
  - **phase17 `FAIL=9`** — eight were the pre-existing repo-root `.config/` failures dispositioned in `18-VERIFICATION.md`. The ninth, `1e GNU Stow rejected --verbose=5 --no-folding on a simulate run of package btop`, was a worktree artifact: check 1e ran `stow -n` from the worktree's `stow/` tree while the live `~/.config/btop/*` links are owned by the main repo.
- **Re-measured on the main tree at Task 3:** **phase18 is `FAIL=0` and exits 0** — the submodule diagnosis is confirmed, and the criterion holds here. **phase17 is `FAIL=8`, not 9** — the ninth failure is gone, confirming the `stow -n` diagnosis exactly. The remaining `FAIL=8` is the pre-existing, twice-dispositioned repo-root `.config/` condition (`18-11-SUMMARY.md`, `18-VERIFICATION.md`, `19-01-SUMMARY.md` Deviation 1).
- **Fix:** None applied. No failure in either list names `arch/dots-hyprland.sh`, and `18-CONTEXT.md` D-20 forbids editing a closed phase's assert retroactively.
- **Files modified:** none
- **Verification:** `grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l` reports **18** both before and after this plan, so neither new recovery message added a counted pair (phase17 check 1b passes). phase18 and phase19 both exit 0 on the main tree.
- **Committed in:** n/a (no code change)

**3. [Rule 3 - Blocking] Task 3's `<verify>` bans `error-unmatch` file-wide, but a legitimate pre-existing call site has existed in `run_capture()` since Phase 18**

- **Found during:** Task 3 (running the plan's first `<automated>` block)
- **Issue:** the block asserts `! grep -q -- "error-unmatch" arch/dots-hyprland.sh` — file-wide. `arch/dots-hyprland.sh:1172`, inside `run_capture()`'s `mirror_is_capturable()`, has carried `git ls-files --error-unmatch -- "$p"` since commit `dfd1df3` (`feat(18-05)`). That call is correct and in a different function: it tests **one** path per call, on demand, to decide whether a capture mirror has a `HEAD` version to recover. The plan's own acceptance criterion is scoped correctly — "**the walk** contains no `--error-unmatch` call" — and the `<verify>` command's file-wide form is a stricter encoding written on the stale assumption that no such call existed anywhere. Deleting the Phase 18 call site to green a gate would change `capture` semantics for no reason and is exactly the "turn a gate green by rewriting the record" move `STATE.md` records the Phase 17 precedent against.
- **Fix:** the scoped criterion was verified instead, by extracting `run_verify()`'s body and grepping that: `awk '/^run_verify\(\) \{/{f=1} f{print} f&&/^\}/{exit}' arch/dots-hyprland.sh | grep -c -- 'error-unmatch'` reports **0**. Every other clause of the `<verify>` block ran unmodified and passed. A secondary instance of the same trap was genuinely auto-fixed: a comment I wrote inside `run_verify()` named the banned flag while explaining why not to use it, which turned the file-wide gate red from the new code itself — that comment was reworded, and the reason a file-wide literal gate constrains comments too is now recorded in the file.
- **Files modified:** `arch/dots-hyprland.sh` (comment wording only)
- **Verification:** `run_verify()` body: 0 occurrences. Whole file: 1 occurrence, at line 1172, unchanged from `dfd1df3`. `git diff 44d3781..HEAD -- arch/dots-hyprland.sh` touches nothing inside `run_capture()`.
- **Committed in:** `7f12272`

**4. [Rule 2 - Missing Critical] The assert's criterion-1 summary line still claimed plan 19-02 owed a section**

- **Found during:** Task 3 (extending the criteria summary block)
- **Issue:** the plan instructs extending criteria 4 and 5 only. Criterion 1's line read `pending -- plan 19-02 and 19-03`. Left alone, the assert would print, on every run after this plan completed, that a completed plan still owes a section — a false statement in the one artifact whose entire purpose is to state truths about the tree.
- **Fix:** the line now distinguishes the two halves honestly: the folded-ancestor and dangling arms **shipped** in plan 19-02, and their **proof** is still pending because plan `19-03`'s composite fixture is the only live positive either check has (today's tree is measured to have zero of both).
- **Files modified:** `scripts/phase19-link-aware-verify-assert.sh`
- **Verification:** `./scripts/phase19-link-aware-verify-assert.sh` exits 0 at `FAIL=0 FINDINGS=0`; the criteria summary block prints the corrected line and asserts nothing new.
- **Committed in:** `7f12272`

---

**Total deviations:** 4 (2 auto-fixed, 1 unsatisfiable `<verify>` clause reclassified to the scope its own acceptance criterion names, 1 unsatisfiable criterion reclassified as out of scope with the owned half verified and partially resolved by re-measurement)
**Impact on plan:** No scope creep. Deviation 1 is the difference between the dangling arm working and being decorative. Deviation 3 changed one comment. Deviation 4 changed one echo. Deviation 2 changed nothing and its main-tree re-measurement retires half of what it recorded.

## Authentication Gates

None.

## Issues Encountered

- The expected red window from `19-01` is still open and was **not** touched: `./scripts/phase13-d19-assert.sh` reports `[FAIL] arch/dots-hyprland.sh changed since 8497511`. Plan `19-05` closes it behind a new Phase 19 tier. This plan's three commits widen that diff further, exactly as the objective states.
- `./scripts/phase17-unblock-assert.sh` remains `FAIL=8`, pre-existing and twice dispositioned. See Deviation 2.

## Threat Flags

None. No new network endpoint, auth path or schema change. The plan's `<threat_model>` entries are mitigated as specified:

- **T-19-02** (repo-prefix tests) — canonicalised comparison on **both** sides via `main_root_real`, strengthened past the plan's own text (Deviation 1).
- **T-19-03** (`git -C … -- <path>` argument construction) — `--` before every path argument in both new `git` calls, every expansion quoted, paths sourced from `find -print0` and `git ls-files -z`, never from word-splitting.
- **T-19-04** (new arms under `set -euo pipefail`) — `git diff --quiet`'s status captured with the `rc=0; cmd || rc=$?` idiom rather than tested inline; the `ls-files` read guarded with `|| true`; `local x` split from `x="$(cmd)"`; no post-increment arithmetic.
- **T-19-06** (`[INFO]` lines naming repo-side paths) — accepted as planned: paths only, never content.
- **T-19-SC** — vacuous; this phase installs no external packages.

One security-relevant note that is a **tightening**, not a new surface: D-23 converts a silent degradation path into a refusal. `verify` can no longer produce a verdict it was not equipped to make.

## Known Stubs

None. Every arm this plan added is asserted against a real fixture, except the two link arms from Task 1 — the folded-ancestor check and the dangling-into-repo arm — whose live positives do not exist on today's tree (Phase 17's audit found two folded directories and Phase 18's redistribution resolved both). Those were proven by scratch fixtures during Task 1 and their permanent proof is plan `19-03`'s composite fixture, which the assert's criteria summary now names explicitly rather than implying the work is unowned.

The sections this plan does not own remain named as pending with their owning plan: criterion 2 and the findings-only `--strict` promotion (plan `19-04`), criterion 5's green-on-today's-tree and unclaimed-stub halves (plan `19-04`), criterion 1's proof (plan `19-03`).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Ready for `19-03`.** What it inherits:

- `run_verify()`'s repo-side walk is complete for criterion 1: link existence, link-ness, dangling split, folded ancestor and resolved-target equality, checked in order and failing at the first miss, with the content observation strictly after the passing link assertion.
- The folded-ancestor and dangling arms exist and are unproven against a live positive on purpose. `19-03`'s composite fixture (D-34) is the only thing that can prove them, and the criteria summary now says so in the script itself.
- `scripts/phase19-link-aware-verify-assert.sh` has four sections and a shared fixture builder, runner and guard; `19-03` appends Section 5 rather than rebuilding harness mechanics.
- `verify` now requires `git`. Any fixture `19-03` builds must `git init` and commit, as `build_fixture()` already does — a fixture repo with no `HEAD` would make D-21's comparison report every file as differing.

**Known open item carried forward:** `./scripts/phase13-d19-assert.sh` is red by design from plan `19-01` onward and is closed by `19-05`.

---
*Phase: 19-link-aware-verify*
*Completed: 2026-09-14*

## Self-Check: PASSED

- `arch/dots-hyprland.sh` — present on disk, `bash -n` clean
- `scripts/phase19-link-aware-verify-assert.sh` — present on disk, executable, `bash -n` clean
- Commits `0edddfe`, `15b4d0b`, `7f12272` — all found in `git log --oneline --all`
- `./arch/dots-hyprland.sh verify` — exit 0, `=== done: FAIL=0 FINDINGS=0 ===`, one `[INFO]` naming `stow/fish/.config/fish/config.fish`
- `./arch/dots-hyprland.sh verify` with no `git` on PATH — exit 2, `[FAIL] precondition:` on fd 2 (`GIT_PRECONDITION_OK`)
- `./scripts/phase19-link-aware-verify-assert.sh` — exit 0, `FAIL=0 FINDINGS=0`, 38 `[PASS]` lines (criterion requires ≥ 24)
- `./scripts/phase18-capture-model-assert.sh` — exit 0, `FAIL=0 FINDINGS=0`
- `grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l` — 18
- `git status --porcelain --ignored` identical before and after the assert run
- `run_verify()` body contains 0 occurrences of the banned per-path trackedness flag; the whole file contains 1, pre-existing in `run_capture()` since `dfd1df3`
