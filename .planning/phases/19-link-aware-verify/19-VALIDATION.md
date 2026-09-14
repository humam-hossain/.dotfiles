---
phase: "19"
slug: "link-aware-verify"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-14"
validated: "2026-09-14"
# The validation MAP is complete and every row's automated command was really run.
# The phase GATE — every assert script in the repo green on one tree in one run —
# is NOT green, for two conditions neither of which is a Phase 19 deliverable and
# neither of which was closed by editing the script that reports it. Read the
# "Phase Gate" section below before quoting `status: validated` as "everything is
# green": those are two different claims and this file keeps them apart on purpose.
phase_gate: red
phase_gate_red: ["scripts/phase17-unblock-assert.sh", "scripts/phase14-verify.sh"]
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None. Custom bash assert scripts under `scripts/`, per `.planning/codebase/TESTING.md` — this repo has no unit-test framework and must not gain one for this phase |
| **Config file** | none — by design |
| **Quick run command** | `bash -n arch/dots-hyprland.sh && ./arch/dots-hyprland.sh verify` |
| **Full suite command** | `./scripts/phase19-link-aware-verify-assert.sh` |
| **Estimated runtime** | ~1 second for the quick run (0.97 s measured); the full assert (1731 lines, 8 sections, 81 `[PASS]`) runs in a few seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash -n arch/dots-hyprland.sh && ./arch/dots-hyprland.sh verify`
- **After every plan wave:** Run `./scripts/phase19-link-aware-verify-assert.sh`
- **Before `/gsd-verify-work`:** All of `phase19`, `phase18`, `phase17`, `phase13-d19`, `phase12-full-smoke` and `phase14-verify` green on a clean tree — the shape STATE.md records for the Phase 16 D-40 gate
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

Every row below names a task that was really executed, and an automated command that
was really run. Section numbers refer to `scripts/phase19-link-aware-verify-assert.sh`,
whose sections are the permanent proof for the arms they cover; the bare script
invocation runs all eight.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 19-01 T1 (tracer) | 19-01 | 1 | VER-03, VER-04 | T-19-01 | Section 1 — end-to-end, argv to exit code, against a `stow/` fixture destroyed on purpose by `rsync -a --delete`, with a negative control that must stay green | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ✅ | ✅ green |
| 19-01 T2 | 19-01 | 1 | VER-03 | — | Section 2 — the exit-code contract (0 clean / 1 drift / 2 precondition) and the closed flag surface: an unknown flag exits 2 on fd 2 and prints no summary line (D-15) | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ✅ | ✅ green |
| 19-01 T3 | 19-01 | 1 | VER-03 | — | Section 3 — `--strict` changes the verdict and `--quiet` changes the volume, neither changes the scope; output above the summary is byte-identical with and without `--strict` | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ✅ | ✅ green |
| 19-02 T1 | 19-02 | 2 | VER-01 | — | A folded ancestor directory and a link that dangles *into* the repo are separate named arms, not one collapsed "broken link" verdict; permanent proof is 19-03's composite fixture in Section 5 | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ✅ | ✅ green |
| 19-02 T2 | 19-02 | 2 | VER-01, VER-03 | — | `git` and `realpath` are hard dependencies: absent either is exit 2 with no soft-degrade arm, so a caller can never mistake a quieter run for a full one (D-23, resolved at a blocking-human checkpoint) | integration | `./scripts/phase19-link-aware-verify-assert.sh` (Section 2 precondition cases) | ✅ | ✅ green |
| 19-02 T3 | 19-02 | 2 | VER-01 | — | Section 4 — the repo-vs-`HEAD` content `[INFO]` (D-21), its untracked-file extension, and the cp-through boundary: link `[PASS]`, exit 0, content difference reported as `[INFO]` and never as a link failure | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ✅ | ✅ green |
| 19-03 T1 | 19-03 | 3 | VER-01 | — | The live-side sweep's bounded root set (29 managed directories) and per-directory verdicts, appended as a separate pass that leaves the Phase 18 repo-side loop byte-unchanged (D-07 — the diff was pure insertion) | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ✅ | ✅ green |
| 19-03 T2 | 19-03 | 3 | VER-01 | — | `classify_sweep_entry()` is one decision point with nine arms; arm 6 is tested before arm 8, and inverting them drops five of the nineteen real-tree artifacts out of the report | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ✅ | ✅ green |
| 19-03 T3 | 19-03 | 3 | VER-01 | — | Section 5 — all four sweep pathologies staged in one scratch `$HOME`: stale undeclared link, folded ancestor, dangling-into-repo, unclaimed stub (plus the shared-root exemption) | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ✅ | ✅ green |
| 19-04 T1 | 19-04 | 4 | VER-02, VER-03 | T-19-11 | Section 6 — `capture/` drift is its own `[FINDING]` class, asserted to name the live path *and* to appear on no `[FAIL]` line; counters asserted by exact value (`FAIL=0 FINDINGS=1`) before `--strict` promotion is asserted at all | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ✅ | ✅ green |
| 19-04 T2 | 19-04 | 4 | VER-02 | — | Section 7 — both branches of the installer's auto-backup primitive land on opposite sides of the link/content boundary: firstrun is a loud `[FAIL]` with a `stow -t` recovery, non-firstrun is a silent survivor only the sweep's artifact-shape arm reports | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ✅ | ✅ green |
| 19-04 T2 (D-47) | 19-04 | 4 | VER-03 | T-19-10 | `verify` never reads the vendored submodule — proven read-only twice: a static gate over `run_verify()`'s 320 non-comment lines, and a scratch fixture carrying a committed `.gitmodules` beside an empty vendored path | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ✅ | ✅ green |
| 19-04 T3 | 19-04 | 4 | VER-01 | T-19-10 | Section 8 — every scratch root from Sections 1–7 is torn down and the teardown is *asserted*, then a read-only real-tree run asserts only the exit code and records the counts as `[INFO]` so nothing rots into an expectation (D-36) | integration | `./scripts/phase19-link-aware-verify-assert.sh` | ✅ | ✅ green |
| 19-04 T3 (determinism) | 19-04 | 4 | VER-03 | — | Two back-to-back assert runs produce an identical `[PASS]` count — a flapping harness would make every row above a coin flip | smoke | `./scripts/phase19-link-aware-verify-assert.sh` run twice (`IDEMPOTENT_OK`) | ✅ | ✅ green |
| 19-04 T3 (no side effects) | 19-04 | 4 | VER-01 | T-19-10 | `git status --porcelain --ignored` bracketed around a full assert run is byte-identical and names no fixture path — the harness leaves the operator's tree untouched | smoke | `git status --porcelain --ignored` before and after `./scripts/phase19-link-aware-verify-assert.sh` | ✅ | ✅ green |
| 19-05 T1 | 19-05 | 5 | VER-01 | T-19-16 | The Q3 record extends `PITFALLS.md` entry A-6 only, and `.gitignore` ships no temp-file rule — the newest commit naming it is still the Phase 17 line-endings commit `936fd9e` | doc gate | `git log -1 --format=%H -- .gitignore` and `grep -- "### A-6" .planning/research/PITFALLS.md` | ✅ | ✅ green |
| 19-05 T2 | 19-05 | 5 | VER-03 | T-19-13 | Wrapper drift detection is live again: the Phase 19 tier's pin is re-extracted from the script by a single-line grep anchored on the marker filename and re-checked against the **working tree**, independently of which branch fires at runtime | integration | `./scripts/phase13-d19-assert.sh`, then `git cat-file -e <extracted SHA>^{commit}` and `git diff --name-only <extracted SHA> -- arch/dots-hyprland.sh` | ✅ | ✅ green |
| 19-05 T3 (real tree) | 19-05 | 5 | VER-01 | — | `verify` stays green on the real tree, bare and under `--strict` — ROADMAP criterion 5 | smoke | `./arch/dots-hyprland.sh verify` and `./arch/dots-hyprland.sh verify --strict` | ✅ | ✅ green |
| 19-05 T3 (regression, green) | 19-05 | 5 | regression | T-19-15 | The Phase 18, 13 and 12 asserts stay green after the Phase 19 wrapper edits | integration | `./scripts/phase18-capture-model-assert.sh`, `./scripts/phase13-d19-assert.sh`, `./scripts/phase12-full-smoke.sh` | ✅ | ✅ green |
| 19-05 T3 (regression, red) | 19-05 | 5 | regression | T-19-14 | The Phase 17 and Phase 14 asserts on the same tree in the same run — **both red**, for two conditions Phase 19 did not introduce and did not close by editing them. See the Phase Gate section | integration | `./scripts/phase17-unblock-assert.sh`, `./scripts/phase14-verify.sh` | ✅ | ❌ red |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs name the plan and the task number as they appear in that plan's `<tasks>` block and in its SUMMARY's Task Commits list.*

---

## Wave 0 Requirements

- [x] `scripts/phase19-link-aware-verify-assert.sh` — exists, 1731 lines, 8 sections, 81 `[PASS]`, covers VER-01 through VER-04
- [x] A reusable fixture builder inside that script. Factored as functions (`build_*_fixture`, `run_fixture_verify` with parameterised `RUN_REPO`/`RUN_HOME`, `teardown_scratch_roots`) inside the single script — there is no shared fixture library in this repo and `.planning/codebase/TESTING.md` says not to add one
- [x] Framework install: none required — none was installed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `verify --quiet` output is one-screen scannable | VER-03 | `--quiet` exists because the phase's signal is otherwise buried in its own success output. Only a human can say whether that worked. Measured input for the judgement: the real-tree `--quiet` run emits 1 line (the summary) against 95 without the flag | Run `./arch/dots-hyprland.sh verify --quiet` and confirm the surviving output is what you would want to read first. Deferred by `workflow.human_verify_mode: end-of-phase`; WINDOWS ledger id 8 |
| The 33 real-tree `[INFO]` conditions are ones the operator recognises | VER-01, VER-02 | The assert checks that the tree is green; it does not check that green is the *right answer*. Recognising the installer backup files, the unclaimed stubs and the Steam links that dangle when Steam is not running is judgement, not assertion | Run `./arch/dots-hyprland.sh verify` and read the 33 `[INFO]` lines. Confirm each names something you know about |
| The Phase 14 gate's finding count matches for the right reason | regression | A count that matches for the wrong reason is exactly what a transcript exists to let a human catch | Read the Phase Gate transcript below. `scripts/phase14-verify.sh` reports `FINDINGS=0`, not one finding: the known D-38 autostart loss is emitted as eleven `[INFO]` lines, every one marked `(expected)`. Confirm no *new* condition is hiding inside that `[INFO]` block |

*Three behaviours are human-judgement; every row of the map above has an automated command, so sampling continuity holds.*

---

## Phase Gate

Run on 2026-09-14 against the main working tree at `8c04382`, all seven commands
in the same run on the same tree. **Six green, two red** (seven commands, eight
lines because `verify` is counted separately from the six scripts).

| # | Command | Summary line | Exit |
|---|---------|--------------|------|
| 1 | `./scripts/phase19-link-aware-verify-assert.sh` | `=== done: FAIL=0 FINDINGS=0 ===` | **0** |
| 2 | `./scripts/phase18-capture-model-assert.sh` | `=== done: FAIL=0 FINDINGS=0 ===` | **0** |
| 3 | `./scripts/phase17-unblock-assert.sh` | `=== done: FAIL=8 ===` | **1** ❌ |
| 4 | `./scripts/phase13-d19-assert.sh` | `=== Phase 13 asserts: FAIL=0 ===` | **0** |
| 5 | `./scripts/phase12-full-smoke.sh` | `=== done: FAIL=0 ===` | **0** |
| 6 | `./scripts/phase14-verify.sh` | `=== done: FAIL=3 FINDINGS=0 ===` | **1** ❌ |
| 7 | `./arch/dots-hyprland.sh verify` | `=== done: FAIL=0 FINDINGS=0 ===` (123 `[PASS]`, 33 `[INFO]`) | **0** |
| 7b | `./arch/dots-hyprland.sh verify --strict` | — | **0** |

Line 4 is the one this plan closed: `[PASS] arch/dots-hyprland.sh unmodified since 85dbfbc`,
selected by the new Phase 19 tier. It was `[FAIL] … changed since 8497511` before plan `19-05`.

### Red 1 — `scripts/phase17-unblock-assert.sh`, `FAIL=8`

Pre-existing and previously dispositioned. Phase 18's redistribution (`18-04`, `18-06`)
emptied the repo-root `.config/` tree the Phase 17 assert hard-codes, so its 4b breadth
sweep, its F-9 `kdeglobals` tracking checks and its 5a/5b `execs.lua` checks all address
paths that moved. Recorded in `18-VERIFICATION.md`, in `19-01-SUMMARY.md` (Deviation 1),
in `19-02-SUMMARY.md` (Deviation 2, where the count was re-measured from 9 to 8 on the
main tree) and in `19-03-SUMMARY.md` (Deviation 1); it is WINDOWS ledger id 7. Not
touched here: rewriting a Phase 17 assert to agree with a Phase 18 decision is a Phase 17
or Phase 18 repair, not a Phase 19 one, and closing it from inside this phase would be
closing a red gate by editing the thing that reports it.

The eight failing lines:

```
[FAIL] 4b negative control path is missing …: .config/hypr/custom/general.lua
[FAIL] 4b negative control path is missing …: .config/hypr/hyprlock.conf
[FAIL] 4b breadth sweep: the set of tracked files an ignore pattern reaches has changed …
[FAIL] 4b F-9: .config/kdeglobals is no longer tracked — a file another phase owns was untracked
[FAIL] 4b F-9: check-ignore reports the TRACKED .config/kdeglobals as ignored …
[FAIL] 5a guard: .config/hypr/custom/execs.lua is missing, or holds no non-empty line …
[FAIL] 5a .config/hypr/custom/execs.lua does not carry the literal 'systemctl --user start hyprland-session.service' …
[FAIL] 5b .config/hypr/custom/execs.lua and /home/pera/.config/hypr/custom/execs.lua have DIVERGED …
```

### Red 2 — `scripts/phase14-verify.sh`, `FAIL=3` — new, and two of the three are a link-awareness defect in the assert itself

This is the first time this phase's gate has been run end to end, and it found something
the phase's own subject matter predicts. Two of the three failures are **false**: the
condition they claim (`the firstrun path fired and Phase 11 D-24 did not hold`) is not
what happened.

```
[FAIL] D-37 hyprlock.conf changed: 66 bytes / c3ecd68d…, fixture recorded 554 bytes / c3ecd68d…
[FAIL] D-37 hypridle.conf changed: 66 bytes / 6e720184…, fixture recorded 359 bytes / 6e720184…
```

Read the two halves of each line against each other: **the sha256 matches exactly on both
sides, and only the byte count differs.** `check_untouched()` (`scripts/phase14-verify.sh`
lines 399-412) probes with `stat -c '%s' "$path"` — which does **not** dereference — and
`sha256sum "$path"` — which does. Since `feat(18-06): move overwriting hypr configs to
restow/hypr/`, the two live paths are symlinks:

```
/home/pera/.config/hypr/hyprlock.conf -> ../../github_repo/.dotfiles/restow/hypr/.config/hypr/hyprlock.conf
/home/pera/.config/hypr/hypridle.conf -> ../../github_repo/.dotfiles/restow/hypr/.config/hypr/hypridle.conf
```

66 is the length of that link target string, not a file size. `stat -L -c %s` returns 554
and 359 — the fixture's recorded values, exactly. The content is byte-identical and
Phase 11 D-24 **did** hold; the assert is not link-aware, which is precisely the class of
defect this phase exists to remove from `verify`. The fix is one `-L` on the `stat` in
`check_untouched()`, and it belongs to whoever owns `scripts/phase14-verify.sh` — not to
this task, whose instruction is to report rather than edit. Recorded as a WINDOWS entry.

The third failure is environmental and transient:

```
[FAIL] D-35 working tree is dirty outside .planning/phases/14-live-full-adopt-verify/
        M stow/fish/.config/fish/config.fish
```

That modification predates Phase 19 and was deliberately left alone throughout it; `verify`
itself names it as an `[INFO]` on every run (the D-21 repo-vs-`HEAD` arm — working as
designed). It clears the moment the operator commits or reverts that file.

### On the expected "one known finding"

The plan expected `scripts/phase14-verify.sh` to exit 0 with one finding — the D-38
autostart loss. It reports `FINDINGS=0`. The D-38 losses are emitted as eleven `[INFO]`
lines, each marked `(expected)`, and `graphical-session.target is active`. Nothing was
absorbed into a matching count, because the count is zero; the expectation in the plan
describes an older shape of that script. The `[INFO]` block is unchanged from the Phase 16
D-40 gate transcript.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies — every one of the 20 map rows carries a command that was really run
- [x] Sampling continuity: no 3 consecutive tasks without automated verify — all 15 executed tasks across plans `19-01`…`19-05` have one
- [x] Wave 0 covers all MISSING references — the assert script and its in-script fixture builders exist
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter
- [ ] **Phase gate green on a clean tree** — NOT met. Two scripts red, neither a Phase 19 deliverable, neither closed by weakening its claim. See the Phase Gate section
- [ ] Three human-judgement checks outstanding (Manual-Only table)

**Approval:** validation map complete and signed off; phase gate **red pending** the two
conditions above, both of which belong to other phases' assert scripts and are recorded
rather than repaired here.
