---
phase: 17-unblock-stow-and-restore-the-session-target
plan: 01
subsystem: infra
tags: [stow, gnu-stow, bash, dotfiles, assert-harness, installer-scripts]

# Dependency graph
requires:
  - phase: 16-retire-safe-profile
    provides: "the D-20 assert-contract model (scripts/phase16-retire-assert.sh) — header shape, REPO_ROOT derivation, vacuity-guarded ban greps, evidence-printing fail branches, and the frozen-record precedent that keeps .planning/ artifacts out of ban-grep scope"
provides:
  - "scripts/phase17-unblock-assert.sh — the Phase 17 contract harness: three prefixes ([PASS]/[FAIL]/[INFO]), one FAIL counter, closing `=== done: FAIL=n ===`, covering criteria 1a, 1b, 1c, 1d, 1e plus the D-02 folding audit"
  - "All 15 stow call sites across 14 arch/*.sh files converted from the invalid `-v=5` to `--verbose=5 --no-folding` in a fixed flag order"
  - "The 16th invocation — the documented kitty re-stow recovery command in docs/phase14-adopt-runbook.md — corrected with its `-R` restow flag preserved (CAP-04)"
  - "A live D-02 folding record: ~/.config/qBittorrent and ~/.config/smartmontools are the two pre-existing folded directory symlinks, emitted as [INFO] on every assert run rather than frozen into a note"
affects: [17-02, 18-tree-taxonomy, 20-hyprland-config-placement]

actuals:
  tokens: 9814
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "D-20 three-prefix / one-counter assert contract, kept deliberately distinct from the four-prefix / two-counter phase14-verify.sh contract"
    - "Vacuity guard in front of every ban grep — the scoped tree is asserted present and non-empty before the ban runs"
    - "Ban greps scoped by explicit path list (arch/ docs/) rather than recursed from the repo root, so frozen .planning/ history can never force a false red"
    - "Read-only [INFO]-only audit sections that record state for a downstream phase without asserting on it"

key-files:
  created:
    - scripts/phase17-unblock-assert.sh
  modified:
    - arch/btop.sh
    - arch/alacritty.sh
    - arch/define.sh
    - arch/fish.sh
    - arch/hyprland.sh
    - arch/kitty.sh
    - arch/nvim.sh
    - arch/rofi.sh
    - arch/tmux.sh
    - arch/wezterm.sh
    - arch/xterm.sh
    - arch/yazi.sh
    - arch/zsh.sh
    - arch/zsh_powerlevel.sh
    - docs/phase14-adopt-runbook.md

key-decisions:
  - "Ban greps for the retired stow spelling are scoped by explicit path list to arch/ and docs/ — .planning/research/PITFALLS.md carries the same string as frozen history under the Phase 16 precedent and is never edited to make a gate green"
  - "The D-02 folding audit reports [INFO] only and never [PASS]/[FAIL] — the two pre-existing folded directory symlinks are recorded and handed to Phase 18 rather than unfolded here"
  - "Criterion 1e is behavioral, not textual: a real GNU Stow 2.4.1 simulate run proves the new spelling parses, because a grep only proves the literal was typed"
  - "Decomposed by call site, never by package — arch/zsh.sh and arch/zsh_powerlevel.sh both stow package `zsh`, and arch/hyprland.sh holds two sites"

patterns-established:
  - "Evidence-printing fail branch: every fail() is immediately followed by a re-run of the offending command suffixed `|| true`, so the [FAIL] line carries the output that produced it"
  - "Presence guard in front of a file-list loop, so a renamed or deleted file shrinks the loop loudly instead of silently"

requirements-completed: [FIX-01, CAP-04]

coverage:
  - id: D1
    description: "All 15 stow call sites across the 14 arch/*.sh files carry the literal `--verbose=5 --no-folding` in a fixed flag order, and the invalid short-verbosity spelling survives at zero sites under arch/"
    requirement: "FIX-01"
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh (criterion 1b — counted grep over arch/*.sh equals 15)"
        status: pass
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh (criterion 1a — vacuity-guarded ban grep over arch/ docs/)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The installed GNU Stow 2.4.1 actually accepts the new spelling — proven by a real non-mutating simulate run, not only by a grep"
    requirement: "FIX-01"
    verification:
      - kind: e2e
        ref: "./scripts/phase17-unblock-assert.sh (criterion 1e — `stow --verbose=5 --no-folding -n -t ~ btop` exits 0)"
        status: pass
    human_judgment: false
  - id: D3
    description: "`bash -n` exits 0 on all 14 arch/*.sh files that hold a stow call site after the sweep"
    requirement: "FIX-01"
    verification:
      - kind: unit
        ref: "./scripts/phase17-unblock-assert.sh (criterion 1c — 14 PASS lines, one per file, fronted by a presence guard)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The 16th invocation — the documented kitty re-stow recovery command in docs/phase14-adopt-runbook.md — carries the valid flag pair with `-R` preserved, and docs/ carries zero invalid stow invocations"
    requirement: "CAP-04"
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh (criterion 1d — docs-scoped ban grep)"
        status: pass
      - kind: other
        ref: "grep -o 'stow -R --verbose=5 --no-folding -t ~ kitty' docs/phase14-adopt-runbook.md"
        status: pass
    human_judgment: false
  - id: D5
    description: "scripts/phase17-unblock-assert.sh exists with the D-20 three-prefix, one-counter contract — no FINDINGS counter leaked in from the phase-14 contract"
    verification:
      - kind: other
        ref: "grep -c 'FINDINGS' scripts/phase17-unblock-assert.sh == 0; closing line is `=== done: FAIL=0 ===`"
        status: pass
    human_judgment: false
  - id: D6
    description: "The D-02 folding audit records the pre-existing folded directory symlinks as live [INFO] output and hands them to Phase 18 without unfolding them"
    verification:
      - kind: other
        ref: "./scripts/phase17-unblock-assert.sh | grep -c '^\\[INFO\\]' == 3; executable lines of the audit section invoke only find/readlink/-d"
        status: pass
    human_judgment: true
    rationale: "The audit asserts nothing by design (D-02) — it emits [INFO] only, so there is no PASS/FAIL for a machine to read. Whether the recorded list is the right handoff for Phase 18 is a judgment about scope, not a testable property."
  - id: D7
    description: "The sibling Phase 16 assert suite is still green after this wave — no regression from the flag sweep"
    verification:
      - kind: integration
        ref: "./scripts/phase16-retire-assert.sh"
        status: pass
    human_judgment: false

# Metrics
duration: 2 min
completed: 2026-09-12
status: complete
---

# Phase 17 Plan 01: Unblock the stow flag sweep and land the assert harness Summary

**All 16 `stow` invocations in the repo's live trees move from the invalid `-v=5` (which GNU Stow 2.4.1 rejects with `Unknown option: =`) to `--verbose=5 --no-folding`, proved by a new D-20 assert harness that runs a real stow simulate rather than only a grep.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-09-12T14:19:18Z
- **Completed:** 2026-09-12T14:21:01Z
- **Tasks:** 3
- **Files modified:** 16 (1 created, 15 modified)

## Accomplishments

- **FIX-01 closed:** all 15 stow call sites across 14 `arch/*.sh` files now carry `--verbose=5 --no-folding` in a fixed order. The edit is flags-only per D-01 — the `cd "$(dirname "${BASH_SOURCE[0]}")/../stow" &&` prefix, `-t ~`, and every package name are byte-identical. No `-d`, no `--restow`, and critically no `--adopt` was introduced at any site.
- **CAP-04 closed:** the 16th invocation, the copy-pasteable kitty re-stow recovery command at `docs/phase14-adopt-runbook.md:247`, is corrected to `cd stow && stow -R --verbose=5 --no-folding -t ~ kitty` with its deliberate `-R` restow flag preserved. That command previously exited 1 for any operator who ran it.
- **`scripts/phase17-unblock-assert.sh` created** with the D-20 contract — exactly three prefix helpers (`pass`, `fail`, `info`), exactly one counter (`FAIL`), closing line `=== done: FAIL=n ===`. It covers criteria 1a (vacuity-guarded ban grep), 1b (counted grep == 15), 1c (14-file `bash -n` loop behind a presence guard), 1d (docs-scoped ban), and 1e (a real GNU Stow simulate run), plus the read-only D-02 folding audit.
- **The blocker on `arch/hyprland.sh` is lifted.** Two of the 15 sites live in that file behind irreversible system mutation; criterion 2's live run was gated on this plan landing. Phase 18 is likewise unblocked — `--no-folding` is now universal before any tree is stowed.

## Task Commits

Each task was committed atomically:

1. **Task 1 (tracer): D-20 assert harness + the btop call site** — `de3a2b6` (feat)
2. **Task 2: the remaining 14 call sites and the documented recovery command** — `ae87eac` (fix)
3. **Task 3: criterion 1c syntax gate and the D-02 folding audit** — `943da09` (test)

**Plan metadata:** see the `docs(17-01)` commit following this summary.

## Files Created/Modified

- `scripts/phase17-unblock-assert.sh` — **new.** The Phase 17 contract harness. Non-mutating by construction: greps, `bash -n`, stow simulate (`-n`) runs, `find`/`readlink`. Runs no install, no uninstall, no package operation.
- `arch/btop.sh` — the tracer call site, first converted and proven end to end.
- `arch/alacritty.sh`, `arch/define.sh`, `arch/fish.sh`, `arch/kitty.sh`, `arch/nvim.sh`, `arch/rofi.sh`, `arch/tmux.sh`, `arch/wezterm.sh`, `arch/xterm.sh`, `arch/yazi.sh`, `arch/zsh.sh`, `arch/zsh_powerlevel.sh` — one call site each, flags-only.
- `arch/hyprland.sh` — **two** call sites (packages `systemd` and `swaync`), both converted.
- `docs/phase14-adopt-runbook.md` — the 16th invocation, `-R` preserved.

## Verification Evidence

Both assert suites close green. Closing lines quoted verbatim, as `<output>` requires:

```
$ ./scripts/phase17-unblock-assert.sh
=== done: FAIL=0 ===

$ ./scripts/phase16-retire-assert.sh
=== done: FAIL=0 ===
```

The Phase 17 run emits **21 `[PASS]` lines, 0 `[FAIL]` lines and 3 `[INFO]` lines**, and exits 0. Fourteen of the PASS lines are the criterion 1c `bash -n` loop, one per call-site file.

Supporting counts, all re-run at wave close:

| Check | Result |
|---|---|
| `grep -ho -- '--verbose=5 --no-folding' arch/*.sh \| wc -l` | `15` |
| `grep -c -- '--verbose=5 --no-folding' arch/hyprland.sh` | `2` |
| `grep -rn -- '-v=5' arch/ docs/` | no match (exit 1) |
| `grep -c -- '--adopt' arch/*.sh docs/phase14-adopt-runbook.md` | `0` at every file |
| `grep -c 'FINDINGS' scripts/phase17-unblock-assert.sh` | `0` |
| `git diff --name-only -- .planning/research/PITFALLS.md` | empty — frozen artifact untouched |

**Behavioral proof that the spelling parses (criterion 1e):** `stow --verbose=5 --no-folding -n -t ~ btop` against GNU Stow 2.4.1 exits 0 and plans nothing (`link_task_action(.): no task`, `dir_task_action(.): no task`) — `~/.config/btop` is confirmed a real directory, not a folded symlink, and the `--no-folding` run leaves it one. Research §F-1 recorded the counterfactual: `stow -v=5 -n` on the same version dies with `Unknown option: =` / `Unknown option: 5`, EXIT=1.

## D-02 Folding Audit — handoff to Phase 18

The audit is **read-only and reports `[INFO]` only** — it never emits `[PASS]`/`[FAIL]`. `--no-folding` governs new runs only, so the directories that folded before this phase stay folded. Phase 18 owns the tree taxonomy that decides what each becomes.

Two folded directory symlinks found under `$HOME/.config` (matching research §F-10 exactly):

| Path | Target |
|---|---|
| `~/.config/qBittorrent` | `../github_repo/.dotfiles/stow/qbittorrent/.config/qBittorrent` |
| `~/.config/smartmontools` | `../github_repo/.dotfiles/stow/smartmontools/.config/smartmontools` |

Neither package is stowed by any `arch/*.sh` script — `smartmontools` is placed by `arch/scrutiny.sh` via `sudo cp`, and `qbittorrent` has no installer script at all. That is precisely why they folded: nothing ever pre-created the real destination directory. Both are live write paths into the repo working tree, which `.planning/research/PITFALLS.md:497` rates the highest-priority stow risk. The audit now re-emits this list on every assert run, so the handoff is live output rather than a note that can go stale.

## Decisions Made

- **Ban greps are scoped by explicit path list to `arch/ docs/`, never recursed from the repo root.** `.planning/research/PITFALLS.md:475` carries the same `-v=5` string as frozen history. Under the Phase 16 frozen-record precedent that file is evidence, not code — a gate turned green by rewriting the historical record is a false green. The plan's prohibition on exactly this was honored and is re-asserted by an acceptance criterion.
- **The D-02 audit asserts nothing.** Emitting `[PASS]` for "two directories are folded" would encode today's accident as a contract that Phase 18 then has to break.
- **Criterion 1e is behavioral, not textual.** A grep proves the literal was typed; only a real stow run proves it parses. That distinction is the whole defect — `-v=5` was typed 16 times and never parsed once.
- **Decomposed by call site, never by package.** `arch/zsh.sh` and `arch/zsh_powerlevel.sh` both stow package `zsh`, and `arch/hyprland.sh` holds two sites; a one-edit-per-package pass would have missed two.

## Deviations from Plan

None - plan executed exactly as written.

All three tasks ran as specified, every acceptance criterion passed on first evaluation, and no deviation rule was triggered. No `--adopt` was introduced, no frozen planning artifact was edited, and no auto-fix attempts were consumed.

**Total deviations:** 0
**Impact on plan:** none.

## Issues Encountered

One interpretation call, recorded for the verifier rather than treated as a deviation:

Task 3's acceptance criterion reads *"the section contains no `stow ` invocation without `-n`, no `rm`, no `mv`, and no `ln`."* A naive substring grep over the folding-audit section hits three false positives that are unavoidable when documenting stow: the `find -lname` predicate the plan itself prescribes contains the substring `ln`; a comment explaining that unfolding later is a `stow -D` plus a re-stow contains `stow `; and the summary `[INFO]` message contains the English phrase "folded stow directory symlink(s)".

The criterion's stated intent is *"the folding-audit section performs no write"*, so it was verified at the command level instead of by substring. The section's executable (non-comment) lines are exactly: `echo`, an arithmetic increment, a `while read` loop, `[[ -n ]]`, `[[ -d ]]`, `readlink`, `info`, and `find … -type l -lname`. A scan for `stow`/`rm`/`mv`/`ln` in command position over those lines returns nothing. The prose was left intact rather than contorted to satisfy a substring match.

## Tracer Feedback Gate

Task 1 was `type="tracer"`. After its commit the gate ran per `human_verify_mode: end-of-phase` with a `<verify>` block carrying only `<automated>` entries and no `gate="blocking-human"`: the tracer verify was re-run end to end, passed (`=== done: FAIL=0 ===`, `bash -n arch/btop.sh` OK, literal count `1`, FINDINGS count `0`), and expansion proceeded without synthesizing a checkpoint.

## Known Stubs

None. Every section of the assert script performs a real check against real state; no placeholder, TODO, or hardcoded-empty value was introduced.

## Threat Flags

None. The three registered threats were mitigated as planned and no new security-relevant surface was introduced:

- **T-17-08** (folding lets an external writer reach the working tree) — `--no-folding` now rides all 16 invocations; the two pre-existing folded directories are enumerated and handed to Phase 18 per D-02.
- **T-17-09** (`--adopt` silently replacing repo content) — verified absent at all 15 arch/ sites and in the operator doc, both before and after the sweep.
- **T-17-10** (frozen `.planning/` artifacts edited to pass a gate) — ban grep scoped by explicit path list; `.planning/research/PITFALLS.md` confirmed unmodified across all three commits.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **`17-02` is unblocked.** `arch/hyprland.sh` now parses and both its call sites are valid, so the FIX-02 deletion of lines 24-26 and criterion 2's live run can proceed. Note the plan's own warning: line numbers in that file shift from 29/33 once D-03 deletes lines 24-26 — write every subsequent edit and grep against **content**, not line number.
- **Phase 18 inherits two folded directories**, `~/.config/qBittorrent` and `~/.config/smartmontools`, re-emitted as `[INFO]` on every `phase17-unblock-assert.sh` run. Unfolding either is a `stow -D` plus a re-stow carrying `--no-folding`.
- **The harness is extensible in place.** `scripts/phase17-unblock-assert.sh` is structured one commented section per criterion; `17-02` adds its sections to the same file under the same D-20 contract. Do not import `finding()` or a `FINDINGS` counter from `scripts/phase14-verify.sh` — an acceptance criterion asserts that counter's absence.
- **No blockers.**

## Self-Check: PASSED

- `scripts/phase17-unblock-assert.sh` — FOUND on disk, executable.
- `arch/btop.sh`, `docs/phase14-adopt-runbook.md` — FOUND on disk.
- Commits `de3a2b6`, `ae87eac`, `943da09` — all FOUND in `git log --oneline --all`.
- All three tasks' acceptance criteria re-run at wave close: every one PASS.
- Plan-level `<verification>` re-run at wave close: `phase17-unblock-assert.sh` and `phase16-retire-assert.sh` both close `=== done: FAIL=0 ===`.

---
*Phase: 17-unblock-stow-and-restore-the-session-target*
*Completed: 2026-09-12*
