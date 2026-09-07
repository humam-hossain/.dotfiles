---
phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook
plan: 03
subsystem: testing
tags: [bash, assert-script, phase14-verify, script-deletion, rollback, in-11]

# Dependency graph
requires:
  - phase: 16-01
    provides: "the stripped wrapper — `protect` removed from ALLOWLIST, the backup gate and `II_BACKUP_DIR` deleted, the package-marking array gone; every probe this plan deletes was probing one of those"
  - phase: 16-02
    provides: "`arch/dots-hyprland.sh` final for the phase, so the surviving `uninstall --dry-run` probe is aimed at a subcommand that will not move again"
provides:
  - "`scripts/phase14-verify.sh` green against the stripped wrapper — 33 PASS, 0 FAIL, 1 FINDING on a committed tree"
  - "the real post-change tail for the playbook's §7 quoted expectation: `=== done: FAIL=0 FINDINGS=1 ===`"
  - "IN-11 closed by deletion — `scripts/phase14-preflight.sh` no longer exists to print `--rotate-backup` as mandatory"
  - "two fewer scripts; the `scripts/phase*.sh` family is down to six, all green or expected-red by design"
  - "a verified-empty runner sweep proving no Makefile, CI job, hook or script invoked either deleted stem"
affects: [16-04, 16-05, 16-06, 16-07, 16-09, 16-10]

# Actuals (#2632)
actuals:
  tokens: 14694
  tasks: 2
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Message relabel as a first-class edit class: an assertion can be relabelled off a deleted requirement ID onto a surviving decision ID with zero change to what it asserts"
    - "Tempfile hygiene as a single edit: an `mktemp` handle and its `trap` entry are removed together the moment their last writer goes"
    - "Reference sweeps split into a gate pass (everything outside `.git/`, `.planning/`, `docs/`) and a report pass (`docs/` only), so a wave-2 plan can prove no runner exists without editing wave-3 files"

key-files:
  created: []
  modified:
    - scripts/phase14-verify.sh
  deleted:
    - scripts/phase07-live-smoke.sh
    - scripts/phase14-preflight.sh

key-decisions:
  - "The `sha256sum` file-wide absence criterion was satisfied in scope, not literally — three of its four call sites are inside assertions D-37 explicitly keeps"
  - "The two surviving pre-adopt conf probes were relabelled off ADOPT-04 onto D-20, because ADOPT-04 is deleted from REQUIREMENTS.md this phase (D-26) and a live assertion must not cite a requirement that no longer exists"
  - "`BACKUP_DIR` keeps both its declaration and its configuration-banner echo — the plan's stated default when the banner is the only remaining reader"
  - "`PROTECT_OUT`'s `mktemp` and its `trap` entry were removed in the same edit as its only writer"
  - "The `docs/` citations to the deleted stems were reported and handed to plans 16-04 and 16-05 rather than fixed here, preserving the D-42 wrapper-before-documentation ordering"

patterns-established:
  - "Deleted-requirement citation hygiene extends to assert-script message strings, not just code comments — an operator reading `[PASS] ADOPT-04 …` against a deleted ADOPT-04 is being told something false"
  - "Delete-the-script beats fix-the-message when the script's entire subject matter is retired: IN-11's remediation text could not be made safe, only unreachable"

requirements-completed: [ADOPT-02, ADOPT-03, IN-11, D-33, D-37]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "The live verification suite runs against the stripped wrapper without invoking a subcommand or flag that no longer exists, and is green apart from the expected dirty-tree failure"
    requirement: "D-37"
    verification:
      - kind: integration
        ref: "bash -n scripts/phase14-verify.sh && ./scripts/phase14-verify.sh — 33 [PASS], 0 [FAIL], '=== done: FAIL=0 FINDINGS=1 ===' on the committed tree"
        status: pass
    human_judgment: false
  - id: D2
    description: "The live-session assertions on the D-37 keep list are untouched: the compositor is on the Lua entry, and Waybar, rofi and swaync are still stopped"
    requirement: "ADOPT-02"
    verification:
      - kind: integration
        ref: "test \"$(git diff -U0 HEAD -- scripts/phase14-verify.sh | grep -cE '^[+-].*(waybar|rofi|swaync|configProvider|hyprland\\.lua)')\" -eq 0 — count 0, diff-level keep-list check"
        status: pass
      - kind: integration
        ref: "./scripts/phase14-verify.sh — ADOPT-02 Lua-entry and ADOPT-03 accept-remove blocks all [PASS]"
        status: pass
    human_judgment: false
  - id: D3
    description: "The surviving removal path is still exercised — `uninstall --dry-run` exits 0 — under a label that no longer promises a deleted rollback tier"
    requirement: "ADOPT-03"
    verification:
      - kind: integration
        ref: "./scripts/phase14-verify.sh — '[PASS] D-10 wrapper removal path still reachable: uninstall --dry-run exits 0'"
        status: pass
      - kind: other
        ref: "grep -q 'uninstall --dry-run' scripts/phase14-verify.sh && ! grep -q 'ADOPT-04' scripts/phase14-verify.sh"
        status: pass
    human_judgment: false
  - id: D4
    description: "Nothing in the repo asserts the integrity of a backup no future install will produce, and the two on-disk snapshots are untouched"
    requirement: "D-37"
    verification:
      - kind: other
        ref: "grep -q -- 'backup_dir_hyprland_conf_mtime' scripts/phase14-verify.sh => absent; 'D-36 backup' => absent; 'BK_CONF' => absent"
        status: pass
      - kind: other
        ref: "git diff --diff-filter=D --name-only HEAD~2 HEAD names only the two deleted scripts; no path under $HOME was touched by any task"
        status: pass
    human_judgment: false
  - id: D5
    description: "`scripts/phase07-live-smoke.sh` and `scripts/phase14-preflight.sh` no longer exist, and nothing outside `.planning/` and `docs/` invokes them"
    requirement: "D-33"
    verification:
      - kind: integration
        ref: "test ! -e <both> && test -z \"$(git ls-files -- <both>)\""
        status: pass
      - kind: integration
        ref: "grep -rIl --exclude-dir=.git --exclude-dir=.planning --exclude-dir=docs -e phase07-live-smoke -e phase14-preflight . => RUNNERS:none"
        status: pass
    human_judgment: false
  - id: D6
    description: "IN-11 is closed by deletion: no script in the repo prints backup rotation as a mandatory step before an adopt that already happened"
    requirement: "IN-11"
    verification:
      - kind: integration
        ref: "grep -rIl --exclude-dir=.git --exclude-dir=.planning --exclude-dir=docs -e 'rotate-backup' scripts/ => no match; the only emitter was the deleted phase14-preflight.sh:264"
        status: pass
    human_judgment: false
  - id: D7
    description: "The three tree-clean-agnostic regression suites stayed green across both task commits"
    verification:
      - kind: integration
        ref: "./scripts/phase12-full-smoke.sh, ./scripts/phase16-retire-assert.sh, ./scripts/phase11-dispositions-assert.sh — each '=== done: FAIL=0 ==='"
        status: pass
    human_judgment: false
  - id: D8
    description: "The summary line the playbook quotes keeps its documented shape, so plan 16-04 can paste a real tail rather than carry a number forward on trust"
    verification:
      - kind: integration
        ref: "./scripts/phase14-verify.sh on the committed tree => '=== done: FAIL=0 FINDINGS=1 ===', single [FINDING] is D-38"
        status: pass
    human_judgment: false

# Metrics
duration: 10 min
completed: 2026-09-07
status: complete
---

# Phase 16 Plan 03: Script-surface alignment and deletion Summary

**`scripts/phase14-verify.sh` stripped of the three probes that went false with the wrapper — the backup-directory presence check, the `protect --dry-run` reachability check and the whole backup sha256/mtime block — leaving 33 PASS / 0 FAIL / 1 FINDING on a committed tree, and the two scripts whose entire subject matter this phase removed deleted with a verified-empty runner sweep.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-07T13:12:00Z
- **Completed:** 2026-09-07T13:21:00Z
- **Tasks:** 2
- **Files modified:** 3 (1 modified, 2 deleted)

## Accomplishments

- **The verification suite probes only machinery that exists.** Three deletions landed exactly as D-37 enumerates: the `[[ -d "$BACKUP_DIR" ]] && [[ -n "$(ls -A …)" ]]` third rollback-source probe, the `protect --dry-run` third-tier reachability probe (which after 16-01 hits the allowlist refusal and would have failed every run), and the entire D-36 backup-integrity block that resolved `$BACKUP_DIR/.config/hypr/hyprland.conf`, hashed it against the baseline fixture and compared mtimes. Net `−50/+14` lines.
- **The surviving removal probe is byte-identical in structure and truthful in its label.** Its `printf '' |` stdin feed, its `sed -n '1,40p' "$OUT" || true` failure dump and its tempfile all survive verbatim; only the two message strings changed, from `ADOPT-04 tier 2 reachable/unreachable` to `D-10 wrapper removal path still reachable/unreachable`.
- **The known D-38 finding stayed a finding.** Its text lost the `PROTECT_EXPLICIT` citation and gained the observation the citation used to stand in for — the binary was expected to remain installed because it shipped as part of the personal stack, and the capability that used to protect that stack from an orphan sweep was retired in Phase 16. It sits in an `else` branch that does not fire on this machine; turning it into a `fail` would have moved the summary line the playbook quotes.
- **Tempfile and variable hygiene resolved by inspection, not assumption.** `PROTECT_OUT` lost its only writer, so its `mktemp` declaration and its `trap` entry went in the same edit. `BACKUP_DIR` still has one reader — the `[CONFIG] backup_dir=` banner echo at `:80` — so both the declaration and the echo were kept, which is the plan's stated default. `baseline_value backup_dir_hyprland_conf_mtime` was confirmed to have no other caller before removal; the accessor function itself survives with nine other call sites.
- **Two scripts deleted with `git rm`, 778 lines, and a runner sweep that returned nothing.** `RUNNERS:none` outside `.git/`, `.planning/` and `docs/`. No Makefile, no `.github/workflows`, no hook — D-33's "no runner to update" is now verified post-deletion, not just pre-deletion.
- **The real tail for plan 16-04 was captured on a committed tree, not carried forward on trust** (research Pitfall 6). See "Handover to plan 16-04" below.

## Task Commits

Each task was committed atomically:

1. **Task 1: Strip the deleted-machinery probes from the live verification suite** — `a7b6fa7` (fix)
2. **Task 2: Delete the live-smoke and preflight scripts, and prove nothing invoked them** — `769bf9e` (chore)

**Plan metadata:** the `docs(16-03)` commit that carries this file.

## Files Created/Modified

- `scripts/phase14-verify.sh` — three probe blocks deleted, the surviving removal probe and the two pre-adopt conf probes relabelled, one D-38 finding reworded, one `mktemp` handle and its `trap` entry dropped. `+14/−50`. Runs clean: 33 PASS, 0 FAIL, 1 FINDING, 12 INFO.
- `scripts/phase07-live-smoke.sh` — **deleted** (−451). Coverage given up, recorded here because nothing else will: LIVE-01..04 live-session asserts, the `D-06 install --dry-run SAFE_DEFAULTS` residual-argv assert, the post-install `protect asexplicit` and `enable ii hooks` dry-run plan asserts across three subcommands, the `uninstall --dry-run` protect-list asserts, `--skip-protect` omission, the `protect` subcommand's own six-assert block including `--install-missing`, the wrapper-help asserts for `--skip-protect` and the `protect` subcommand, and the LIVE-03 dual-run Waybar/swaync asserts. Every one of those targets was removed by 16-01 or accept-removed at the Phase 14 adopt. What survives elsewhere: the wrapper-behavior contract now lives in `scripts/phase12-full-smoke.sh` and `scripts/phase16-retire-assert.sh`; the live-session facts live in `scripts/phase14-verify.sh`.
- `scripts/phase14-preflight.sh` — **deleted** (−327). Coverage given up: the D-34 not-firstrun marker precondition, the D-12 submodule-pin check, the ADOPT-01 Phase 10/11 artifact gate, the Phase 13 overlay-readiness check, the D-15/D-35 runbook-freshness check, the D-13/D-27 backup-directory report **with its `--rotate-backup` mandatory-remediation message (IN-11)**, the D-26 protect assert, and the D-05 gate-fed `install --full` dry-run that piped `yes` into a backup gate 16-01 deleted. The adopt it gated ran on 2026-09-04 and nothing re-runs it.

## Decisions Made

- **The `sha256sum` absence criterion was satisfied in scope rather than literally.** See "Deviations" below — three of the four call sites are inside assertions D-37 keeps.
- **`ADOPT-04` was retired from every message in the file, not just from the removal probe.** D-26 deletes the `ADOPT-04` row from `.planning/REQUIREMENTS.md` outright, so a `[PASS] ADOPT-04 tier-1 source 1 …` line would cite a requirement that no longer exists — the same failure mode 16-01's comment-hygiene pattern was established to prevent, one layer out in operator-visible output. The two surviving pre-adopt conf probes now read `D-20 pre-adopt conf source $1 …`, which is what they actually establish under the replacement rollback story. Their assertions, their hashing and their pass/fail structure are unchanged.
- **The section header comment was rewritten rather than re-cited.** It now explains that Phase 16 retired the tiered-rollback promise these probes were labelled under, and that the probes themselves are unchanged. It names no retired identifier, per 16-01's rule that an absence-grep cannot tell a tombstone comment from live code.
- **`BACKUP_DIR` kept.** One reader survives (the banner echo). Removing a declaration that still has a reader is a `set -u` abort; keeping an under-used one is free. The plan's own instruction defaults to keeping both in exactly this case.
- **The `docs/` hits were reported, not fixed.** Editing `docs/dots-hyprland-workflow.md` or `docs/phase14-adopt-runbook.md` from a wave-2 script plan would break the D-42 wrapper-before-documentation ordering.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Task 1's `sha256sum` acceptance criterion is unsatisfiable as written; satisfied in scope instead**

- **Found during:** Task 1
- **Issue:** The acceptance criterion and its verify loop require `scripts/phase14-verify.sh` to contain none of `protect --dry-run`, `sha256sum`, `PROTECT_EXPLICIT`, `backup_dir_hyprland_conf_mtime`. Three of the four are single-site tokens living only inside the deleted blocks. `sha256sum` is not: at baseline it had four call sites, and only one (`:407`, in the D-36 backup-integrity block) is on the deletion list. The other three are `check_tier1_source` (`:365` — kept by D-37, which deletes only `:374-378` from that region), and `check_untouched` / `check_sidecar` (`:442`, `:459` — the Phase 11 D-24 hyprlock/hypridle block, which appears on no deletion list and which the task's own "Do not touch" clause protects). Satisfying the criterion literally would mean deleting kept assertions, which the same task forbids in the same breath — and `check_tier1_source`'s own comment (*"Presence is not identity … a `-s` test would keep printing PASS after either source drifted"*) is a standing argument against downgrading it to a non-hashing check.
- **Fix:** Deleted the single in-scope `sha256sum` call site with its block, and left the other three. The criterion's intent — that the backup-integrity block is gone — is proven by three tighter absence checks that have no false-positive surface: `backup_dir_hyprland_conf_mtime`, `D-36 backup` and `BK_CONF` are all absent from the file.
- **Files modified:** `scripts/phase14-verify.sh`
- **Verification:** `grep -n 'sha256sum'` returns exactly three lines, all inside kept assertions; `grep -q -- 'backup_dir_hyprland_conf_mtime'`, `grep -q 'D-36 backup'` and `grep -q 'BK_CONF'` all return non-zero. `protect --dry-run` and `PROTECT_EXPLICIT` are absent file-wide as specified.
- **Committed in:** `a7b6fa7` (Task 1 commit)
- **Ledger:** recorded as `.planning/WINDOWS.md` entry id 4 so the scope narrowing stays visible at ship time.

**2. [Rule 2 - Missing Critical] `ADOPT-04` retired from the two surviving pre-adopt conf probe messages and the section header**

- **Found during:** Task 1
- **Issue:** The task action scopes the relabel to the surviving removal probe and then says "Nothing else in the file changes." Its acceptance criteria say, more broadly, "No message in the file cites `ADOPT-04`." Those pull against each other, because `ADOPT-04` appears five more times outside the removal probe: the section header comment and the three `check_tier1_source` message strings. D-26 deletes the `ADOPT-04` row from `REQUIREMENTS.md` this phase, so leaving them would ship live operator-facing output citing a requirement ID with no definition anywhere in the repo.
- **Fix:** Relabelled the three `check_tier1_source` messages from `ADOPT-04 tier-1 source $1` to `D-20 pre-adopt conf source $1`, and rewrote the section header comment to name no retired identifier. Message strings only — no condition, no hash, no pass/fail structure changed.
- **Files modified:** `scripts/phase14-verify.sh`
- **Verification:** `grep -q -- 'ADOPT-04' scripts/phase14-verify.sh` returns non-zero; the block still emits two `[PASS] D-20 pre-adopt conf source …` lines against `~/.config/hypr/hyprland.conf.old` and the repo conf; total PASS count is 33 with FAIL=0.
- **Committed in:** `a7b6fa7` (Task 1 commit)

### Factual correction to the plan

**3. The `RUNNERS:` sweep is only meaningful after the deletion.** Task 2's action says to prove there is no runner *before* deleting. Run before the `git rm`, the gate pass returns the two scripts themselves — each file's usage header contains its own filename — so `test -z "$H"` fails on a tree where nothing is wrong. The sweep was therefore run twice: once before (hits: only the two files themselves, no third-party hit) and once after the `git rm` as the actual gate (`RUNNERS:none`). Both are recorded here; the ordering in the plan is a wording slip, not a missed check.

---

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical) + 1 factual correction to plan prose.
**Impact on plan:** No scope creep. Deviation 1 narrows a check that could not have been satisfied without destroying kept assertions, and substitutes three checks that are strictly more specific. Deviation 2 is message-only and is required by the plan's own acceptance criteria. Neither touches a prohibition: no keep-list assertion, no clean-tree guard, no snapshot directory and no live-machine state was affected.

## Handover to plan 16-04

**The real tail, captured on the committed tree at `769bf9e`:**

```
[PASS] D-35 git status --porcelain is clean apart from paths under .planning/phases/14-live-full-adopt-verify/
=== done: FAIL=0 FINDINGS=1 ===
```

Full counts: **33 `[PASS]`, 0 `[FAIL]`, 1 `[FINDING]`, 12 `[INFO]`.** The single finding is the known D-38 loss:

```
[FINDING] D-38 graphical-session.target is inactive — hyprland-session.service lost its autostart with the renamed conf (expected). This is why screen share may be broken. Phase 15 item.
```

`docs/dots-hyprland-workflow.md:389`'s existing `# expect: === done: FAIL=0 FINDINGS=1 ===   (the 1 finding is the D-38 known loss)` therefore remains **correct** after the D-37 deletions — research Pitfall 6's relief held. Paste this tail rather than re-deriving it.

## Handover: dangling `docs/` references

The Task 2 reference sweep's reporting pass returned:

```
DOC_HANDOVERS:docs/dots-hyprland-workflow.md
docs/phase14-adopt-runbook.md
```

Both now cite scripts that do not exist. Owners:

| File | Owning plan | Decision |
|------|-------------|----------|
| `docs/dots-hyprland-workflow.md` | `16-04` | D-21 |
| `docs/phase14-adopt-runbook.md` | `16-05` | D-25 (§5 becomes historical narrative; invocation sites `:81`, `:84`, `:100`, `:146`, `:149`, `:153`) |

Each of those plans carries its own link assert, which is what proves the dangling pointers are gone.

## Handover: IN-11 closes here, but two artifacts still say otherwise

IN-11 — *post-adopt, `scripts/phase14-preflight.sh` still prints `--rotate-backup` as "mandatory before go"; running it now would rename away a rollback source* — is **closed by deletion** in commit `769bf9e`. The emitting line was `scripts/phase14-preflight.sh:264`.

Two planning artifacts still record it as open, and are corrected in wave 5:

| Artifact | Site | Owning plan |
|----------|------|-------------|
| `.planning/v0.3-MILESTONE-AUDIT.md` | tech-debt entry, `:70` | `16-07` |
| `.planning/STATE.md` | open-review entry under "Concerns carried forward" | `16-09` |

Between wave 2 and wave 5 the repo says IN-11 is open while its cause is already gone. Recorded so a mid-phase reader is not misled (plan assumption A10).

## Issues Encountered

- **The `grep` shell-function shadowing reported by 16-02 was live in this session too.** Every gate in this plan was run with an explicit `/usr/bin/grep`. No gate was re-interpreted or relaxed on the basis of a shadowed-`grep` result.
- **`scripts/phase11-dispositions-assert.sh` does not *end* at `=== done: FAIL=0 ===`.** It prints `phase11 dispositions asserts OK` after it. Task 2's acceptance criterion says the three suites "each end in exactly `=== done: FAIL=0 ===`", but its verify command uses `grep -q '^=== done: FAIL=0 ===$'`, which is satisfied. No script was changed to match the stricter prose reading; the gate as written passes and the suite is green.
- **A residual stale citation was left in place deliberately.** The fixture-missing abort message at `scripts/phase14-verify.sh:59-60` still reads "Without it the D-36 and D-37 comparisons are circular." The D-36 comparison is now deleted; the D-37 (hyprlock/hypridle) comparisons and the pre-adopt conf sha comparisons still depend on the fixture, so the message remains substantially true and the abort still fires for the right reason. It is a fatal-path message, not an assertion, no grep bans the token, and editing it is outside this plan's enumerated surface. Flagged here for the 16-10 phase gate rather than silently fixed.

## Known Stubs

None. Every probe marked for deletion is gone from code and comments alike; nothing was stubbed, commented out, or left as a placeholder. No `TODO`, `FIXME` or skipped assertion was introduced.

## Threat Flags

None. This plan is net-subtractive: no new network endpoint, auth path, file-access pattern or schema change. The registered trust boundaries held:

- **T-16-14** (destruction of data via the preflight rotation path) — mitigated as designed. The script is deleted outright, the post-deletion sweep proves nothing can invoke it, and `git diff --diff-filter=D` across both task commits names only the two scripts. `~/ii-original-dots-backup` and `~/ii-original-dots-backup.20260904T171128Z` were neither read for mutation, moved, rotated, renamed nor removed.
- **T-16-15** (repudiation — the suite as evidence) — the three deletions are asserted by absence and the keep list by a diff-level check that returned 0.
- **T-16-16** (tampering with the clean-tree assertion) — `PHASE14_PREFIX` and its hard-coded Phase 14 value survive untouched; the guard fired correctly on the dirty mid-task tree and passed on the committed tree.
- **T-16-17** (`trap` / variable hygiene under `set -u`) — surfaced by an actual run, not by inspection alone: every `mktemp` handle in the file has a writer and the single `trap` entry names a declared variable.
- **T-16-18** (the quoted summary line) — findings count pinned at exactly 1, reworded finding still a finding.
- **T-16-SC** — no package-manager install step was added or run.

## User Setup Required

None — no external service configuration required. The plan's frontmatter carries no `user_setup` block.

## Next Phase Readiness

- **Ready for wave 3.** Plan `16-04` has the real `phase14-verify.sh` tail above and a named dangling-reference to clear in `docs/dots-hyprland-workflow.md`. Plan `16-05` has the runbook's six `phase14-preflight.sh` invocation sites.
- **Regression floors for the rest of the phase:** `scripts/phase12-full-smoke.sh`, `scripts/phase16-retire-assert.sh` and `scripts/phase11-dispositions-assert.sh` are all `FAIL=0`. `scripts/phase10-inventory-assert.sh` is also green and stays untouched by design (D-39). `scripts/phase14-verify.sh` joins them as a floor, with the caveat that it can only be run on a committed tree.
- **`scripts/phase13-d19-assert.sh` remains expected-red by design** until plan `16-06` re-pins its baseline to `0771cc2`. `WINDOWS.md` id 3 stays open to track it. It was deliberately not run as a gate here.
- **New ledger entry:** `WINDOWS.md` id 4 records the `sha256sum` scope narrowing. It should be reviewed at the 16-10 gate, along with the `:59-60` fixture-message staleness noted above.
- **Nothing in this plan blocks `16-06`.** No task touched `arch/dots-hyprland.sh`; it remains final at `0771cc2`.

## Self-Check: PASSED

- `scripts/phase14-verify.sh` — FOUND on disk, executable, `bash -n` clean, `=== done: FAIL=0 FINDINGS=1 ===` on the committed tree
- `scripts/phase07-live-smoke.sh` — CONFIRMED absent from disk and from `git ls-files`
- `scripts/phase14-preflight.sh` — CONFIRMED absent from disk and from `git ls-files`
- Commit `a7b6fa7` — FOUND in `git log --oneline --all`
- Commit `769bf9e` — FOUND in `git log --oneline --all`
- Task 1 acceptance criteria: 6 of 7 pass as written; the `sha256sum` clause satisfied in scope per deviation 1
- Task 2 acceptance criteria: all 5 pass
- Plan-level `<verification>`: three regression floors at `FAIL=0`; `phase13-d19-assert.sh` correctly not run as a gate; the `phase14-verify.sh` dirty-tree failure excluded by name mid-task and absent on the committed tree; findings count exactly 1 and it is D-38
- No untracked files left behind; `git status --short` is empty

---
*Phase: 16-retire-the-safe-profile-full-only-wrapper-and-playbook*
*Completed: 2026-09-07*
