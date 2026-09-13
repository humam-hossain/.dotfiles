---
phase: 17-unblock-stow-and-restore-the-session-target
plan: 07
subsystem: installers
tags: [hyprland, installer, live-run, transcript, stow, one-way, redaction, dotfiles]

# Dependency graph
requires:
  - phase: 17-06
    provides: "arch/hyprland.sh with the pre-adopt restore deleted and, after the operator's hoist-script-dir decision, a single resolved REPO_ROOT — the two changes that made a run safe to attempt at all"
  - phase: 17-01
    provides: "the `--verbose=5 --no-folding` flag pair at both stow call sites, without which the run would abort after the package operations"
  - phase: 17-05
    provides: "the custom/execs.lua hook that starts hyprland-session.service on hyprland.start, which is why the session target is inactive in a session that predates it"
  - phase: 14
    provides: "the Lua configuration provider adopt, which this run had to leave intact and which is the before/after binding comparison"
provides:
  - "the executed evidence that arch/hyprland.sh runs end to end and exits 0 against the live session — criterion 2's live half, the one claim no grep can make"
  - ".planning/phases/17-unblock-stow-and-restore-the-session-target/17-LIVE-RUN.md — the run's evidence record, including its own gaps"
  - ".planning/phases/17-unblock-stow-and-restore-the-session-target/17-CRITERION2-TRANSCRIPT.txt — the 769-line transcript, machine ID and boot ID redacted in place"
  - "the measured finding that the run's irreversible cost was six database refreshes and nothing else, because every package and the group membership were already in place"

affects: [18-capture-model, 20-hypr-custom-overlays-and-startup-restore]

# Actuals
actuals:
  tokens: 9400
  tasks: 3
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A one-way run is wrapped in `script -q -e` and its exit status read from `$?`, never inferred from the transcript ending without a visible error — `set -x` makes a transcript that stops mid-stanza look much like one that finished"
    - "The precondition gate for an irreversible run is measured, not recited: what the plan assumed the run would cost is re-checked against the machine immediately before, because a cost that is already paid is not a cost"
    - "A full system upgrade immediately before a script that refreshes the package database without upgrading turns the hazard into a no-op, and the transcript then carries the proof in the form of every refresh reporting the databases already current"
    - "A terminal transcript is scanned for secrets before it is committed: sudo emits the host machine ID in an OSC sequence on every authentication, which gitleaks does not flag and which systemd treats as confidential"
    - "A redaction is proved scoped by normalising both the original and the redacted file on exactly the redacted patterns and diffing — equality means nothing else moved"
    - "An empty ActiveEnterTimestamp together with an empty InactiveEnterTimestamp distinguishes a unit a run stopped from one that was never started in this boot; a stopped unit carries an InactiveEnterTimestamp"

key-files:
  created:
    - .planning/phases/17-unblock-stow-and-restore-the-session-target/17-LIVE-RUN.md
    - .planning/phases/17-unblock-stow-and-restore-the-session-target/17-CRITERION2-TRANSCRIPT.txt
  modified:
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "Both blocking-human gates were put to the operator and answered by the operator. The decision gate was answered `run-now`. The precondition gate could not be satisfied by an agent at all: `sudo -n true` fails on this machine, so the operator ran both the full upgrade and the transcripted installer. This is stated because the immediately preceding plan, 17-06, skipped its own blocking-human gate and recorded an inferred answer as the operator's"
  - "The checkpoint was re-costed before it was put to the operator rather than quoted from the plan. All nineteen pacman packages, the one AUR package and the i2c group membership were already in place, so the plan's stated cost — package installation and a durable privilege widening — was not live. What remained was six database refreshes. The operator decided against a measured cost, not an assumed one"
  - "The absolute-path invocation was used even though it is no longer required. Plan 17-06's hoist means every invocation form now exits 0, and the plan's own text at lines 139-141 saying a repo-root-relative path fails is obsolete. The pinned form was kept anyway: a one-way run is not the moment to vary the one variable the plan fixed"
  - "The transcript was redacted, not re-captured. It carried this host's /etc/machine-id seven times inside the OSC sequence sudo emits on authentication, verified byte-for-byte against the file, and this repository has a GitHub remote. Redacting two token classes in place is not a re-run and the plan's ban on re-running to tidy the record therefore does not reach it; the unredacted capture was kept outside the repository"
  - "The three red scripts in the phase gate were reproduced at f314491 rather than assumed pre-existing. The archive commit was checked out into a scratch worktree and the three were run there, returning the same FAIL=1, FAIL=1 and abort. That commit is an ancestor of the phase's planning commit, so the failures predate Phase 17 — already deferred items D-1 and D-2"
  - "The unconfirmed half of the plan's human check is recorded as unconfirmed. The bar, notifications and screen-share sources could not be confirmed because those helpers were not running before the run either; the systemd timestamps prove the run stopped nothing. Confirming them needs the re-login criterion 5 already tracks, and the plan forbids a second run to produce a better record"

patterns-established:
  - "Pattern: re-measure an irreversible action's cost immediately before surfacing the gate, so the operator decides against the machine's actual state rather than the plan's estimate"
  - "Pattern: scan any committed terminal transcript for host identifiers, not only for credentials — gitleaks reports no leaks on a transcript that carries the machine ID"
  - "Pattern: record the gaps in a non-repeatable evidence document inside the document itself, because a second run to close them is forbidden and an unstated gap reads as a confirmed result"

requirements-completed: [FIX-02]

coverage:
  - id: D1
    description: "arch/hyprland.sh runs end to end against the live session and the wrapped command exits 0"
    requirement: FIX-02
    verification:
      - kind: e2e
        ref: "script -q -e -c 'bash /home/pera/github_repo/.dotfiles/arch/hyprland.sh' 17-CRITERION2-TRANSCRIPT.txt; WRAPPED_EXIT=0"
        status: pass
      - kind: other
        ref: "all eight installer stanzas present in the transcript in source order (installer lines 14,17,20,23,26,29,41,45 -> transcript lines 7,18,29,44,56,59,77,392)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The run did not revert the Phase 14 adopt — the configuration provider is unchanged and the pre-adopt live conf is still absent"
    requirement: FIX-02
    verification:
      - kind: e2e
        ref: "hyprctl -j status | jq -r .configProvider -> lua before and lua after; test ! -e ~/.config/hypr/hyprland.conf -> CONF_ABSENT before and after"
        status: pass
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh after the run -> === done: FAIL=0 ==="
        status: pass
    human_judgment: false
  - id: D3
    description: "The two stow packages the script places are still symbolic links resolving into the repo working tree, not plain files"
    requirement: FIX-02
    verification:
      - kind: e2e
        ref: "test -L + readlink -f on ~/.config/systemd/user/hyprland-session.service and the three ~/.config/swaync entries -> all resolve under /home/pera/github_repo/.dotfiles/stow/"
        status: pass
      - kind: other
        ref: "both stow invocations report a Skipping line (already points to the repo path) for every entry — no link was rewritten"
        status: pass
    human_judgment: false
  - id: D4
    description: "The partial-upgrade hazard did not land"
    requirement: FIX-02
    verification:
      - kind: other
        ref: "transcript scan for 'cannot open shared object|version .* not found|unresolvable|breaks dependency|conflicting files|error:|failed retrieving|invalid or corrupted' -> no match; 'there is nothing to do' x6"
        status: pass
    human_judgment: false
  - id: D5
    description: "The evidence record names everything the run cost, including what it could not confirm"
    requirement: FIX-02
    verification:
      - kind: manual_procedural
        ref: ".planning/phases/17-unblock-stow-and-restore-the-session-target/17-LIVE-RUN.md — invocation form, before/after provider, exit status, link state, transcript path, group-membership note, redaction proof, and a '## Gaps in this record' section"
        status: pass
    human_judgment: false
  - id: D6
    description: "The desktop session behaves normally after the run — bar running, notifications working, screen sharing offering sources"
    verification: []
    human_judgment: true
    rationale: "Not confirmable from this run. waybar, swaync and hyprpaper were not running before it either — every one of those units carries an empty ActiveEnterTimestamp and an empty InactiveEnterTimestamp for this boot, which proves the run stopped nothing but leaves the behaviour unobserved. The session target comes up at the next Hyprland launch via the 17-05 execs.lua hook, so this needs the operator re-login that criterion 5 already tracks. The plan forbids a second run."

# Metrics
duration: 21min
completed: 2026-09-13
status: complete
---

# Phase 17 Plan 07: the one-way live run of `arch/hyprland.sh` — Summary

**The installer ran end to end against the live daily-driver session and exited 0, the Lua configuration provider survived it unchanged, and the run's real cost turned out to be six database refreshes rather than the package installation and privilege widening the plan had budgeted for.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-09-13T17:03:14+06:00
- **Completed:** 2026-09-13T17:24:28+06:00
- **Tasks:** 3 (two blocking-human gates, one auto task)
- **Files modified:** 4 (2 created, 2 state files)

## Accomplishments

- Criterion 2's live half is closed. `WRAPPED_EXIT=0`, read from `script -q -e`, not inferred from the transcript's ending.
- The Phase 14 adopt survived the run intact: `configProvider` reads `lua` before and after, and `~/.config/hypr/hyprland.conf` is still absent. This is the direct observation that plan 17-06's static assertions could not make, and it closes threat register row T-17-21.
- All four stow links still resolve into the repo working tree, and both `stow` invocations skipped every entry as already correctly linked — the evidence for T-17-22 that no symlink was overwritten with a plain file.
- The run's cost was re-measured before the operator was asked to accept it, and it was smaller than the plan stated. Nineteen `pacman` packages, one AUR package and the `i2c` membership were already in place, so every package operation reports `there is nothing to do` and `id -nG` is byte-identical across the run.
- A host identifier leak in the transcript was caught and redacted before the file was committed.

## Task Commits

1. **Task 1: Execute the transcripted run and record its evidence** — `3054608` (test)

**Plan metadata:** this summary.

The wave's state advances were committed separately as `d214080` (chore), which also restored the two-field shape of `last_activity` after the `state.update` verb collapsed the date field and the description field into one prose value.

## Files Created/Modified

- `.planning/phases/17-unblock-stow-and-restore-the-session-target/17-LIVE-RUN.md` — the evidence record: invocation form, before and after provider, exit status, post-run link state, transcript path, group-membership note, the redaction proof, the phase gate measured after the run, and an explicit gaps section.
- `.planning/phases/17-unblock-stow-and-restore-the-session-target/17-CRITERION2-TRANSCRIPT.txt` — 769 lines. Mostly `stow --verbose=5` planning output.
- `.planning/ROADMAP.md`, `.planning/STATE.md` — plan progress and phase state.

## Decisions Made

See the `key-decisions` frontmatter. The two that shaped the outcome:

**The checkpoint was re-costed before it was asked.** The plan's checkpoint text describes installing packages and widening group membership as the price of the run. Measured against the machine immediately beforehand, neither was live. Putting the plan's text to the operator verbatim would have asked them to accept a cost that did not exist and would have obscured the one that did — the six `-Sy` refreshes, which the precondition gate's full upgrade then neutralised.

**The transcript was redacted rather than re-captured.** `sudo` emits an OSC sequence carrying `machineid=` and `bootid=` on every authentication; the transcript held both seven times, and the machine ID matched `/etc/machine-id` byte-for-byte. The plan forbids re-running the installer to produce a better record, and redacting two token classes in place is not a re-run. Scope was proved by normalising the original and the redacted file on exactly those patterns and diffing — identical, 769 lines both.

## Deviations from Plan

**One, and it is a correction to the plan's own text rather than to its intent.**

### 1. The plan's pinned-invocation rationale is obsolete

- **Found during:** Task 1 preparation.
- **Issue:** `17-07-PLAN.md` lines 139-141 instruct the operator not to invoke the installer by a repo-root-relative path because "that form fails at the second directory change", and the task's `read_first` points at 17-06's checkpoint outcome to determine which forms are valid. That outcome was `hoist-script-dir`: commit `4599a86` hoists one resolved `REPO_ROOT` and every invocation form now exits 0.
- **Fix:** The pinned absolute form was used regardless — a one-way run is not the moment to vary the one variable the plan fixed — and the obsolescence is recorded in `17-LIVE-RUN.md` with a pointer to the D-5 measurements rather than left to mislead a later reader.
- **Files modified:** none beyond the evidence record.
- **Verification:** `git log -1 --oneline -- arch/hyprland.sh` -> `4599a86`, which is also what the plan's precondition 2 asks for.

---

**Total deviations:** 1 documented.
**Impact on plan:** none on execution. The plan's instruction was followed as written; only its stated reason no longer holds.

## Issues Encountered

**The transcript carried this host's machine ID.** Caught by reading the sudo-prompt region of the transcript before committing, not by a scanner — `gitleaks dir` over the same file reports `no leaks found`, because a machine ID is not a credential pattern. systemd treats it as confidential and the repository has a GitHub remote. Both identifier classes were replaced in place, the scope of the replacement was proved, and the unredacted capture was kept in the session scratchpad outside the repository. The operator's password is not in the file: `sudo` disables terminal echo, so nothing was written to the pty.

**Three scripts in the phase gate are red, and none of it is this phase's doing.** `phase11-dispositions-assert.sh` and `phase10-inventory-assert.sh` close `FAIL=1` and `phase14-verify.sh` aborts, each naming a file under `.planning/phases/` that was moved to `.planning/milestones/v0.3-phases/`. Rather than assume this was pre-existing, `f314491` (`chore: archive v0.3 milestone`) was checked out into a scratch worktree and the three scripts were run there: same `FAIL=1`, same `FAIL=1`, same abort. `git merge-base --is-ancestor f314491 1f10eee` confirms the archive precedes the phase's planning commit. Already recorded as deferred items D-1 and D-2. The results are identical before and after the live run, which is itself evidence that the run changed nothing those suites measure.

**The session helpers are not running, and the run did not stop them.** `hyprland-session.service`, `graphical-session.target`, `waybar.service`, `swaync.service` and `hyprpaper.service` are all inactive. Every one of them reports an empty `ActiveEnterTimestamp` *and* an empty `InactiveEnterTimestamp`, so none has been active at any point in this boot and there was nothing for the run to stop. The live Hyprland process started at 16:34:32, before the 17-05 `custom/execs.lua` hook could apply; that hook starts the session service on `hyprland.start`, so the target comes up at the next Hyprland launch. `hypridle` and `xdg-desktop-portal-hyprland` are running and no user unit is in the `failed` state.

## User Setup Required

None as a precondition. Two things are pending on the operator, neither introduced by this plan:

- **A re-login.** It is what brings `hyprland-session.target` up through the 17-05 hook, it is criterion 5, and it is what deferred item D-4 waits on. It is also what would let the unconfirmed half of this plan's human check — bar, notifications, screen-share sources — be observed.
- **A re-login for the group change, on any other machine.** On this machine `usermod -aG i2c` was a no-op. Elsewhere it is a durable privilege widening that survives logout, threat register row T-17-04, dispositioned `accept`.

## Next Phase Readiness

Phase 17's seventh and final plan is complete. Every requirement the phase owns — FIX-01, FIX-02, FIX-04, FIX-06, CAP-04, START-02, START-03 — has its plan executed.

Two things a later phase inherits:

- **Phase 20 / HYPR-01** owns Hyprland configuration placement. The marker comment plan 17-06 left in `arch/hyprland.sh` names the exact point in the script where a stow invocation belongs once a `stow/hypr/` package exists.
- **Deferred items D-1 through D-4** stand. D-1 and D-2 are the archive-path staleness that keeps three assert scripts red; D-3 is the `StopWhenUnneeded` fan-out; D-4 is the §7 count that cannot be measured while D-1 stands. D-5 is closed — it was resolved in this phase, not deferred.

## Self-Check: PASSED

- Wrapped command exit status `0`, read from `$?` after `script -e`, recorded in `17-LIVE-RUN.md`.
- `hyprctl -j status | jq -r .configProvider` -> `lua` after the run.
- `~/.config/hypr/hyprland.conf` absent after the run.
- `~/.config/systemd/user/hyprland-session.service` is a symbolic link resolving to `/home/pera/github_repo/.dotfiles/stow/systemd/.config/systemd/user/hyprland-session.service`; the three swaync entries likewise resolve under the repo.
- `./scripts/phase17-unblock-assert.sh` closes `=== done: FAIL=0 ===` after the run.
- Transcript exists at the recorded path, 769 lines, non-empty, all eight stanzas present in source order.
- `17-LIVE-RUN.md` records the before provider, after provider, exit status, invocation form, transcript path and group-membership note.

---
*Phase: 17-unblock-stow-and-restore-the-session-target*
*Completed: 2026-09-13*
