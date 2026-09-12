---
phase: 17-unblock-stow-and-restore-the-session-target
plan: 02
subsystem: infra
tags: [bash, dotfiles, safe-rm, destructive-guard, realpath, dispatch-guard, assert-harness]

# Dependency graph
requires:
  - phase: 17-01
    provides: "scripts/phase17-unblock-assert.sh with the D-20 contract (three prefixes, one FAIL counter, closing `=== done: FAIL=n ===`), and the repaired arch/*.sh stow call sites that make arch/dots-hyprland.sh's siblings parseable"
  - phase: 16-retire-safe-profile
    provides: "the frozen-record precedent — a planning artifact that is history is evidence, not code, and is never edited to turn a gate green; applied here to the archived 13-SOT-APPLY.md"
provides:
  - "`safe_rm_path` refuses every existing path that resolves under the repo root — the third refusal clause, canonicalising both sides with `realpath -m`, positioned after the $HOME allow-list, fail-closed with no override flag"
  - "`arch/dots-hyprland.sh` is safely sourceable: the tail `main \"$@\"` is now an `if [[ \"${BASH_SOURCE[0]}\" == \"${0}\" ]]` block, so a `set -e` caller survives the load and gets safe_rm_path as a library function (the hook Phase 18 criterion 7 builds on)"
  - "criterion 3 sections 3a-3d in scripts/phase17-unblock-assert.sh — three non-vacuous positive cases, two negative controls for the pre-existing clauses, and a sourceability probe"
  - "a fixture-guard pattern: every assert subshell that calls a destructive function shadows `rm` with a no-op, so the harness cannot destroy the repo it verifies when the guard under test regresses"
  - "scripts/phase13-d19-assert.sh re-pinned to WRAPPER_BASE=b32faf6 behind a new Phase 17 tier, and taught to resolve phase artifacts through the v0.3 milestone archive"
affects: [17-03, 18-tree-taxonomy, 20-hyprland-config-placement, 21-config-json-capture]

actuals:
  tokens: 13596
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Destructive-path guards compare `realpath -m` resolved strings, never literal prefixes on the unresolved argument — a $HOME-shaped path can reach the repo through a symlink, and one on this machine does"
    - "The source-safe dispatch guard is an `if … fi` block, never the `[[ … ]] && main \"$@\"` conjunction, whose return status of 1 aborts a `set -e` caller that sources the file"
    - "Fixture guard: an assert subshell exercising a destructive function shadows `rm` with a no-op function after loading the code under test, so a regression is reported rather than executed"
    - "Phase artifacts are resolved through a live-tree-then-milestone-archive lookup, because completing a milestone relocates .planning/phases/<phase>/ and silently breaks every hard-coded path and marker-file tier"
    - "An extracted fence is corrected in the open, at the call site, rather than by editing the frozen document it came from"

key-files:
  created: []
  modified:
    - arch/dots-hyprland.sh
    - scripts/phase17-unblock-assert.sh
    - scripts/phase13-d19-assert.sh

key-decisions:
  - "The dispatch guard is the `if … fi` spelling, not CONTEXT D-09's conjunction one-liner — research F-5 falsified the latter live, and its failure mode (a sourced return status of 1 aborting the caller) looks unrelated to the guard"
  - "The repo-containment clause is an `if` on two realpath-resolved strings, not a `case` glob — a glob cannot express a resolved comparison, and the resolved form is what catches the live systemd symlink into stow/"
  - "The criterion 3 fixture shadows `rm` inside every subshell: the plan's claim that the section is 'non-mutating by construction' was conditional on the correctness of the code under test, and that condition failed once during this plan and deleted README.md, stow/ and vendor/dots-hyprland"
  - "scripts/phase13-d19-assert.sh's stale .planning/phases/ paths were repaired rather than worked around: the v0.3 archival had left the script dying before its first assert, and its marker-file tiers would have selected the wrong baseline even after the re-pin"
  - "The archived 13-SOT-APPLY.md was NOT edited. The path it names is rewritten on the extracted fence text at the call site, mirroring the load-bearing `grep -v` filter the same script already applies in the open"
  - "The pre-existing `--force` mention in the wrapper's usage text was left intact — it is Phase 16 documentation stating the wrapper never injects that flag upstream, the opposite of an escape hatch, and deleting history to satisfy a literal grep is the false-green this project already rejected"

patterns-established:
  - "Pattern: a verifier's safety must not depend on the correctness of the code it verifies — enforce it (shadow the destructive call) rather than assume it"
  - "Pattern: baseline SHAs are resolved at execution time via `git log -1 --format=%h -- <path>` plus an empty-diff confirmation, never transcribed from a planning document"
  - "Pattern: marker-file tier chains test the newest marker first, and every marker path is archive-aware"

requirements-completed: [FIX-04]

coverage:
  - id: D1
    description: "safe_rm_path returns non-zero for every existing path that resolves under the repo root — the repo root itself, a tracked file, a stow tree, and the vendored submodule with no carve-out"
    requirement: "FIX-04"
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh (3a — README.md, stow, vendor/dots-hyprland all refused)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The refusal survives symlink escape: ~/.config/systemd/user/hyprland-session.service is a $HOME-shaped path that resolves into stow/systemd/ and is refused by the new clause, which a literal prefix test on the unresolved path would have missed (D-05)"
    requirement: "FIX-04"
    verification:
      - kind: other
        ref: "( source ./arch/dots-hyprland.sh; safe_rm_path \"$HOME/.config/systemd/user/hyprland-session.service\" ) → rc=1, '[FAIL] Refusing to delete path inside the repo'"
        status: pass
    human_judgment: false
  - id: D3
    description: "The two pre-existing refusal clauses still fire after the edit — /etc/passwd is refused as outside $HOME, ~/.config/hypr/custom is refused as a hypr path — so a green criterion 3 cannot be produced by the old clauses alone"
    requirement: "FIX-04"
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh (3b, 3c)"
        status: pass
    human_judgment: false
  - id: D4
    description: "arch/dots-hyprland.sh is sourceable from a `set -euo pipefail` caller: the load returns 0, defines safe_rm_path as a function, and direct execution is behaviourally unchanged (bare invocation still prints usage and exits 0)"
    requirement: "FIX-04"
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh (3d — sourceability probe)"
        status: pass
      - kind: other
        ref: "bash -c 'set -euo pipefail; source ./arch/dots-hyprland.sh >/dev/null 2>&1; echo SOURCED_OK type=$(type -t safe_rm_path)' → SOURCED_OK type=function, exit 0"
        status: pass
      - kind: other
        ref: "./arch/dots-hyprland.sh >/dev/null 2>&1 → direct_exit=0"
        status: pass
    human_judgment: false
  - id: D5
    description: "Criterion 3a is non-vacuous — with the new refusal clause commented out the section reports [FAIL] for all three repo paths and the suite closes FAIL=3, exit 1"
    requirement: "FIX-04"
    verification:
      - kind: manual_procedural
        ref: "comment out the resolved-path branch in safe_rm_path, run ./scripts/phase17-unblock-assert.sh, restore via git checkout"
        status: pass
    human_judgment: true
    rationale: "A one-off procedure performed by hand during Task 3 and deliberately not committed as a test — a committed mutation-test would have to edit the very guard that protects the repo. Whether it should become a committed mutation harness is a scope judgment for a later phase."
  - id: D6
    description: "The criterion 3 fixture cannot destroy the repo when the guard regresses: every fixture subshell shadows `rm` with a no-op, so the same commented-out-clause run that previously deleted README.md, stow/ and vendor/dots-hyprland now leaves all three intact while still reporting FAIL"
    verification:
      - kind: manual_procedural
        ref: "re-run of the D5 procedure under the fixture guard — FAIL=3 reported, `ls -d README.md stow vendor/dots-hyprland` all present, `git status --short` shows only the deliberately edited file"
        status: pass
    human_judgment: true
    rationale: "Proven by the same one-off procedure as D5 and by the incident that motivated it. No committed test asserts the blast radius, because asserting it would require deliberately regressing the guard on every run."
  - id: D7
    description: "scripts/phase13-d19-assert.sh is green again: a Phase 17 tier pins WRAPPER_BASE=b32faf6 ahead of the Phase 16 tier, and the script resolves phase artifacts through the v0.3 milestone archive instead of dying on paths the archival moved"
    verification:
      - kind: integration
        ref: "./scripts/phase13-d19-assert.sh → exit 0, '=== Phase 13 asserts: FAIL=0 ===', '[PASS] arch/dots-hyprland.sh unmodified since b32faf6'"
        status: pass
      - kind: other
        ref: "git diff --name-only b32faf6 -- arch/dots-hyprland.sh → empty"
        status: pass
    human_judgment: false
  - id: D8
    description: "No sibling assert suite is left red by the wrapper edit — the Phase 16 retirement suite still closes FAIL=0"
    verification:
      - kind: integration
        ref: "./scripts/phase16-retire-assert.sh → exit 0, '=== done: FAIL=0 ==='"
        status: pass
    human_judgment: false

# Metrics
duration: 3 min
completed: 2026-09-12
status: complete
---

# Phase 17 Plan 02: Fence the uninstaller out of the repo Summary

**`safe_rm_path` now refuses every path that *resolves* under the repo root — including a live `$HOME`-shaped symlink that lands in `stow/systemd/` — and `arch/dots-hyprland.sh` is sourceable, so that refusal is asserted by calling the function rather than by reading it.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-09-12T14:23:00Z
- **Completed:** 2026-09-12T14:25:45Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- **FIX-04 closed.** A third refusal clause in `safe_rm_path` canonicalises the candidate path and `$REPO_ROOT` with `realpath -m` and returns 1 when the resolved candidate equals the resolved root or sits beneath it. The message is `[FAIL] Refusing to delete path inside the repo: $path` on stderr, naming the offending path. No carve-out for `vendor/dots-hyprland` (D-08), no force flag, no environment override (D-07).
- **The clause is ordered correctly and provably so.** It sits *after* the `$HOME/*` allow-list — this repo is at `/home/pera/github_repo/.dotfiles`, inside `$HOME`, so every repo path already passed that clause and replacing it would have lost the outside-`$HOME` refusal outright. Both older clauses still fire, asserted by two negative controls.
- **The resolved comparison earns its keep on live state.** `~/.config/systemd/user/hyprland-session.service` is a relative symlink into `stow/systemd/` (D-05). It is `$HOME`-shaped, so a literal prefix test on the unresolved argument accepts it; the `realpath -m` comparison refuses it. Verified live.
- **The wrapper is sourceable (D-09/D-21).** The bare `main "$@"` tail became an `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]` block. Sourcing from a `set -euo pipefail` caller now returns 0 and leaves `safe_rm_path` defined; direct execution is unchanged. This is also the hook Phase 18 criterion 7 needs to register `verify` and `capture` as `main`-dispatched handlers.
- **Criterion 3 (3a-3d) added to the phase harness** under the D-20 contract — three existing, `$HOME`-resident repo paths refused, `/etc/passwd` and `~/.config/hypr/custom` as negative controls for the pre-existing clauses, and a sourceability probe. Six `[PASS]` lines mentioning `safe_rm_path`, zero `[FAIL]`.
- **The two sibling suites that read `arch/dots-hyprland.sh` are green.** The Phase 13 drift baseline is re-pinned to `b32faf6` behind a new Phase 17 tier, and the same script now resolves phase artifacts through the v0.3 milestone archive — it had been dying before its first assert since the archival.

## Task Commits

Each task was committed atomically:

1. **Task 1: source-safe dispatch guard** — `16ee295` (feat)
2. **Task 2: repo-containment refusal clause + `pwd -P`** — `b32faf6` (fix)
3. **Task 3: criterion 3 sections + sibling drift re-pin** — `8a3f722` (test)

**Plan metadata:** the `docs(17-02)` commit following this summary.

## Files Created/Modified

- `arch/dots-hyprland.sh` — the single global `REPO_ROOT` upgraded from `pwd` to `pwd -P` (D-06, still one assignment, still not `git rev-parse` so the uninstall path survives a broken checkout); the third `safe_rm_path` refusal clause; the tail dispatch guard.
- `scripts/phase17-unblock-assert.sh` — criterion 3 sections 3a-3d appended ahead of the D-02 folding audit, with the fixture guard described below. Still non-mutating, still the D-20 three-prefix/one-counter contract.
- `scripts/phase13-d19-assert.sh` — new Phase 17 baseline tier; archive-aware `phase_artifact()` resolver; an in-the-open path rewrite on the extracted D-19 fence.

## Verification Evidence

All three assert suites close green on a clean tree at `8a3f722`. Closing lines quoted verbatim:

```
$ ./scripts/phase17-unblock-assert.sh
=== done: FAIL=0 ===

$ ./scripts/phase13-d19-assert.sh
=== Phase 13 asserts: FAIL=0 ===

$ ./scripts/phase16-retire-assert.sh
=== done: FAIL=0 ===
```

Criterion 3, verbatim from the Phase 17 run — six `[PASS]`, zero `[FAIL]`:

```
[PASS] 3a safe_rm_path refuses a path inside the repo: /home/pera/github_repo/.dotfiles/README.md
[PASS] 3a safe_rm_path refuses a path inside the repo: /home/pera/github_repo/.dotfiles/stow
[PASS] 3a safe_rm_path refuses a path inside the repo: /home/pera/github_repo/.dotfiles/vendor/dots-hyprland
[PASS] 3b safe_rm_path still refuses a path outside $HOME: /etc/passwd
[PASS] 3c safe_rm_path still refuses a hypr path: /home/pera/.config/hypr/custom
[PASS] 3d the wrapper loads cleanly in a subshell and safe_rm_path is defined (D-09 dispatch guard)
```

The re-pinned baseline, resolved at execution time after Task 2 landed and confirmed clean:

```
$ git log -1 --format=%h -- arch/dots-hyprland.sh
b32faf6
$ git diff --name-only b32faf6 -- arch/dots-hyprland.sh
            <-- empty
$ ./scripts/phase13-d19-assert.sh | grep dots-hyprland
[PASS] arch/dots-hyprland.sh unmodified since b32faf6
```

**The commented-out-clause check (`<output>` asks for this result explicitly).** With the resolved-path branch commented out of `safe_rm_path`, section 3a flips to three `[FAIL]` lines and the suite closes `=== done: FAIL=3 ===` with exit 1, while 3b/3c/3d stay green — so the section cannot pass with the new code absent, and it is the *new* clause it is reading, not an older one:

```
[FAIL] 3a safe_rm_path ACCEPTED a path inside the repo: /home/pera/github_repo/.dotfiles/README.md
[FAIL] 3a safe_rm_path ACCEPTED a path inside the repo: /home/pera/github_repo/.dotfiles/stow
[FAIL] 3a safe_rm_path ACCEPTED a path inside the repo: /home/pera/github_repo/.dotfiles/vendor/dots-hyprland
[PASS] 3b safe_rm_path still refuses a path outside $HOME: /etc/passwd
[PASS] 3c safe_rm_path still refuses a hypr path: /home/pera/.config/hypr/custom
[PASS] 3d the wrapper loads cleanly in a subshell and safe_rm_path is defined (D-09 dispatch guard)
=== done: FAIL=3 ===
```

Live probe of the whole refusal surface, run against the committed function:

| Path | rc | Message |
|---|---|---|
| `$REPO_ROOT/README.md` | 1 | Refusing to delete path inside the repo |
| `$REPO_ROOT/stow` | 1 | Refusing to delete path inside the repo |
| `$REPO_ROOT/vendor/dots-hyprland` | 1 | Refusing to delete path inside the repo |
| `$REPO_ROOT` itself | 1 | Refusing to delete path inside the repo |
| `/etc/passwd` | 1 | Refusing to delete path outside `$HOME` |
| `$HOME/.config/hypr/custom` | 1 | Refusing to delete hypr path |
| `$HOME/.config/systemd/user/hyprland-session.service` | 1 | **Refusing to delete path inside the repo** (symlink resolved — D-05) |
| `$REPO_ROOT/does-not-exist-xyz` | 0 | `skip (missing)` — the documented early return |

## Decisions Made

- **The `if … fi` dispatch guard, not CONTEXT D-09's conjunction one-liner.** Research F-5 falsified the conjunction form live: as the last statement of a sourced file it leaves the source's return status at 1 and aborts a `set -e` caller before it reaches any fixture. Both spellings are identical on direct execution; only the sourced path differs, which is precisely the path this plan depends on. No `|| true` apology either — the assert script should be able to rely on the guard without a comment explaining it.
- **The repo clause is an `if` on two resolved strings, not a `case` glob.** D-05 needs `realpath -m` on both sides and a `case` pattern cannot express that. Everything else was copied from the two clauses above it: the `# Extra belt: …` comment style, the `[FAIL] Refusing to … : $path` message on stderr, `return 1` and never `exit`.
- **`REPO_ROOT` upgraded in place, not duplicated, and not switched to git.** The file defines it exactly once; `pwd -P` gives the physical path the resolved comparison needs; `git rev-parse --show-toplevel` was rejected per D-06 because the uninstall path must keep working with a broken or absent checkout.
- **The criterion 3 fixture shadows `rm`.** See the incident below. The plan called the section "non-mutating by construction", but the construction was *conditional on the guard being correct* — which is the thing the section exists to doubt.
- **The archived `13-SOT-APPLY.md` was not edited.** Its D-19 fence names its own SoT document by the pre-archive `.planning/phases/…` path. The path is rewritten on the *extracted text*, at the call site, with a comment — the same in-the-open treatment the script already gives its load-bearing `grep -v '^# Phase 14 only'` filter. The frozen document remains untouched (`git status` confirms no change under `.planning/milestones/`).
- **The pre-existing `--force` string in the wrapper's usage text stays.** Task 2's acceptance criterion bans `--force` file-wide; the one occurrence is a Phase 16 usage line (`0771cc2`) stating *"This wrapper never auto-injects --force or --skip-allgreeting"* — documentation of an absence, not an escape hatch, and not reachable from `safe_rm_path`. Verified at the semantic level instead: `FORCE=` and `SAFE_RM_OVERRIDE` are absent (count 0), and no flag, variable or branch can bypass the repo refusal.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] The criterion 3 fixture could delete the repo, and did**

- **Found during:** Task 3, while performing the plan's own acceptance criterion *"Commenting out the new refusal clause makes section 3a report `[FAIL]` — confirm this once by hand."*
- **Issue:** The plan states the section is "non-mutating by construction: every path passed to `safe_rm_path` is one the function refuses, so control never reaches the `rm -rf`." That construction holds only while the guard under test is correct. The moment the clause was commented out — which the plan explicitly instructs — `safe_rm_path` fell through to its real `rm -rf -- "$path"` and the fixture deleted `README.md`, the entire `stow/` tree (85 tracked files) and the `vendor/dots-hyprland` submodule working tree. The same trap is permanent, not specific to the mutation test: any future regression in `safe_rm_path` would have had the *verifier* destroy the repo it verifies.
- **Fix:** (a) Full restoration — `git checkout -- README.md stow arch/dots-hyprland.sh` and `git submodule update --init --recursive`; the tree was confirmed clean apart from the intended script edit, and the submodule is back at its pinned `1a9ffb78`. Nothing was lost; every deleted path was tracked. (b) Every fixture subshell in criterion 3 now shadows `rm` with a no-op function defined *after* the wrapper is loaded. `safe_rm_path` calls a bare `rm` (not `command rm`, not an absolute path), so the shell function intercepts it, the call still returns 0, and an accepted path is still correctly reported as `ACCEPTED`. The assert keeps all of its discriminating power and loses its blast radius.
- **Files modified:** `scripts/phase17-unblock-assert.sh`
- **Verification:** The mutation procedure was re-run under the guard: section 3a reports `[FAIL]` three times and the suite closes `FAIL=3` exactly as before, while `ls -d README.md stow vendor/dots-hyprland` shows all three present and `git status --short` lists only the file deliberately edited. Discrimination preserved, destruction eliminated.
- **Committed in:** `8a3f722` (Task 3 commit)

**2. [Rule 3 - Blocking] `scripts/phase13-d19-assert.sh` was already red and died before its first assert**

- **Found during:** Task 3, baseline run before touching the file.
- **Issue:** Task 3's acceptance criterion and `<verify>` both require this suite to close `FAIL=0`, and it was exiting 1 — not because of the wrapper edit, but because completing milestone v0.3 relocated `.planning/phases/13-…/`, `14-…/` and `16-…/` into `.planning/milestones/v0.3-phases/`. The script hard-coded all three paths. Its fence extractor raised `FileNotFoundError` on the missing `13-SOT-APPLY.md` and the run aborted before any assert. Worse for this plan specifically: the drift tier chain selects `WRAPPER_BASE` by *marker-file presence*, so both existing markers read as absent and the chain would have silently fallen through to the Phase 12 pin. Re-pinning alone would not have fixed it.
- **Fix:** Added a `phase_artifact()` resolver that looks in `.planning/phases/<rel>` first and `.planning/milestones/*-phases/<rel>` second, and routed `SOT`, `DOC_SWEEP_16` and `LIVE_VERIFY` through it. The extracted D-19 fence carries the stale path *inside its own body*; that occurrence is rewritten with `sed` at the call site, in the open and commented, because the document it came from is frozen history under the Phase 16 precedent and is never edited to turn a gate green.
- **Files modified:** `scripts/phase13-d19-assert.sh`
- **Verification:** The extracted fence was run standalone both ways to prove the moved path was the *only* failure — `bash -e` on the raw fence exits 1, on the path-corrected fence exits 0. Full suite then closes `=== Phase 13 asserts: FAIL=0 ===`, 16 `[PASS]`, exit 0, with `[PASS] arch/dots-hyprland.sh unmodified since b32faf6`.
- **Committed in:** `8a3f722` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (1 missing-critical safety, 1 blocking).
**Impact on plan:** Both were necessary — deviation 1 removes a live destructive capability from the verification harness, deviation 2 was the only way Task 3's own acceptance criterion could be met. No scope creep: both changes are confined to the two files the plan already lists in `files_modified`, and no prohibition was touched (no override flag, no carve-out, no edited frozen artifact).

## Issues Encountered

**The repo was briefly destroyed and fully restored.** Documented in full as deviation 1 above rather than buried, because the lesson generalises past this phase: `.planning`-driven verification of destructive code paths must enforce its own non-mutation, not assume it. Recovery was total — every deleted path was tracked or submodule-managed — but it depended on that being true, which is luck, not design. The live `~/.config` stow symlinks pointed at the deleted `stow/` trees during the window; restoring the files healed them, since symlinks resolve by path.

One interpretation call, recorded for the verifier rather than treated as a deviation: Task 2's acceptance criterion *"contains no `--force`"* is stated file-wide, and one pre-existing occurrence survives in the wrapper's Phase 16 usage text, where it documents that the wrapper never injects that flag. The criterion's intent — stated in the plan's own prohibitions as "no escape hatch that lets a caller bypass the repo refusal" — was verified semantically instead. Deleting Phase 16 documentation to satisfy a substring match would be the same false green this project rejected in plan 17-01.

## Known Stubs

None. Every section added performs a real check against real state. No placeholder, TODO, or hardcoded-empty value was introduced, and no test was skipped.

## Threat Flags

None — no new security-relevant surface. The three registered threats were mitigated as planned:

- **T-17-01** (uninstall caller hands `safe_rm_path` a repo path) — mitigated by the third clause: `realpath -m` on both sides, positioned after the `$HOME` allow-list, `return 1`, no override.
- **T-17-11** (uninstall reaching configuration v0.4 will capture) — same clause; `vendor/dots-hyprland` is inside the guard with no carve-out, so no tree the capture phases create can be reached.
- **T-17-12** (assert script sourcing a `set -e` script that calls `exit`) — mitigated by the `if`-block dispatch guard and by confining every fixture to a subshell, so the wrapper's own `set -euo pipefail` and its colliding `REPO_ROOT` never reach the caller.

The one genuinely new finding is the reverse direction of T-17-12 and is already dispositioned as deviation 1: the *fixture* could reach the filesystem through the code under test. Mitigated by the `rm` shadow.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **Criterion 3 of the ROADMAP is closed**, and FIX-04 with it. The uninstall path's seven destructive call sites all funnel through a chokepoint that now cannot reach the repo.
- **Phase 18 criterion 7 has its hook.** `arch/dots-hyprland.sh` is sourceable and `main`-dispatched, so `verify` and `capture` can be registered in `ALLOWLIST` and dispatched as handlers without restructuring the entrypoint.
- **The drift baseline is `b32faf6`.** `scripts/phase13-d19-assert.sh` carries the standing warning from Phase 16 and it still applies: **no later plan may touch `arch/dots-hyprland.sh` without re-pinning there**, resolving the SHA at execution time via `git log -1 --format=%h -- arch/dots-hyprland.sh` plus an empty-diff confirmation. The Phase 17 tier is the newest and must stay first in the chain.
- **Two folded directories are still inherited by Phase 18** from plan 17-01 (`~/.config/qBittorrent`, `~/.config/smartmontools`), re-emitted as `[INFO]` on every Phase 17 assert run.
- **A pattern worth carrying forward:** any future assert that exercises a destructive function should shadow the destructive call, as criterion 3 now does. Phases 20-22 all plan bulk stow operations against live trees.
- **No blockers.**

## Self-Check: PASSED

- `arch/dots-hyprland.sh`, `scripts/phase17-unblock-assert.sh`, `scripts/phase13-d19-assert.sh` — all FOUND on disk; the two scripts executable, all three `bash -n` clean.
- Commits `16ee295`, `b32faf6`, `8a3f722` — all FOUND in `git log --oneline --all`.
- All three tasks' acceptance criteria re-run at plan close: every one PASS (the two interpretation calls recorded above).
- Plan-level `<verification>` re-run at plan close: `phase17-unblock-assert.sh` `=== done: FAIL=0 ===`, `phase16-retire-assert.sh` `=== done: FAIL=0 ===`, `phase13-d19-assert.sh` `=== Phase 13 asserts: FAIL=0 ===`; all exit 0.
- Working tree clean at close apart from this summary and the planning files committed with it; `git submodule status` reports `vendor/dots-hyprland` at its pinned `1a9ffb78`, and no file under `.planning/milestones/` was modified.

---
*Phase: 17-unblock-stow-and-restore-the-session-target*
*Completed: 2026-09-12*
