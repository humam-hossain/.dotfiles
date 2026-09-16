---
phase: 17-unblock-stow-and-restore-the-session-target
plan: 05
subsystem: session
tags: [systemd, graphical-session-target, hyprland, lua-overlay, stow, footgun, assert-harness, dotfiles]

# Dependency graph
requires:
  - phase: 17-04
    provides: "scripts/phase17-unblock-assert.sh closing `=== done: FAIL=0 ===` with criteria 1, 3, 4a-4d live, and the guard-before-content idiom every new section here reuses"
  - phase: 17-01
    provides: "the D-20 harness contract — three prefixes, one FAIL counter, closing `=== done: FAIL=n ===` — and the `--verbose=5 --no-folding` flag pair the documented recovery command pins"
  - phase: 13-personal-hypr-custom-overlays
    provides: "the authoring-SoT header comment in .config/hypr/custom/general.lua and the named-files apply that produces the live copy"
provides:
  - "the one startup entry lost at the Phase 14 adopt, restored: .config/hypr/custom/execs.lua carries `hl.exec_cmd(\"systemctl --user start hyprland-session.service\")` inside an `hl.on(\"hyprland.start\", ...)` block, applied live and byte-identical"
  - "a live measurement of the START-02 mechanism: starting the unit took graphical-session.target from inactive to active with the unit still `linked`, and the session was returned to its as-found state afterwards"
  - "the START-03 warning block in docs/dots-hyprland-workflow.md — the footgun, both halves of the recovery, `mask` as the safe alternative, and the never-enabled rule"
  - "criterion 5 sections 5a, 5b, 5c and 5e, and criterion 6 sections 6a, 6b and 6c, in scripts/phase17-unblock-assert.sh, with the script still non-mutating under the plan's ban-grep"
  - "17-HANDOFF.md — the three Phase 18 rows, including the execs.lua row that closes this phase's hand-sync window"
  - "a corrected phase-13 assertion: the execs.lua slot is fenced to exactly the one START-02 entry instead of being fenced empty"

affects: [18-tree-taxonomy, 20-hypr-custom-overlays-and-startup-restore]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A systemd target carrying RefuseManualStart is reached through a dependency edge, never by a start command: the unit's `Wants=` is the whole mechanism, and the Lua overlay only supplies the trigger"
    - "An assert whose false branch can only be cleared by a human reports [INFO], never [FAIL]. A red no agent can turn green is permanently red through no defect, which trains readers to ignore the colour"
    - "`systemctl --user is-enabled` is read by its printed STRING, never its exit status: it prints `linked` and exits 1, so a status-based assertion reports the precise opposite of the truth"
    - "A unit's runtime properties are not a record of what happened. Once a unit goes inactive, unreferenced and unenabled, the manager garbage-collects it and every timestamp resets to empty; the journal is what survives and what actually discriminates"
    - "A non-empty-file guard counts non-empty LINES, not bytes: a file holding a single newline passes `-s` while holding nothing, and that was this exact file's prior state"
    - "A byte comparison between two copies cannot substitute for a content assertion on the authoring copy — `cmp` passes happily when both copies are equally wrong, which the non-vacuity fixtures demonstrate directly"
    - "Three claims get three checks, never one alternation: `grep -E 'a|b|c'` is satisfied by any one of the three, so a half-documented footgun would pass it"
    - "An assertion that must be deleted before a requirement can land was testing the wrong property. Rewrite it to fence what is now true rather than removing the fence"

key-files:
  created:
    - .planning/phases/17-unblock-stow-and-restore-the-session-target/17-HANDOFF.md
  modified:
    - .config/hypr/custom/execs.lua
    - docs/dots-hyprland-workflow.md
    - scripts/phase17-unblock-assert.sh
    - scripts/phase13-d19-assert.sh
    - .planning/phases/17-unblock-stow-and-restore-the-session-target/deferred-items.md

key-decisions:
  - "Exactly one entry landed in the overlay (D-15). The six other startup entries lost at the adopt are START-01 and belong to Phase 20; keeping them out also leaves Phase 20's workspace-pinning spelling question open for the experiment that phase plans"
  - "Start only, never enable (D-17). The unit is Type=oneshot with RemainAfterExit=yes, so one start per session suffices, and staying in state `linked` keeps the state in which the START-03 footgun bites out of reach entirely"
  - "The mechanism was proven once by hand and reverted, and that mutating check is deliberately absent from the assert script under any flag. Re-proving it every run would cost the script its non-mutating guarantee and would leave the target hand-started — the exact false green 5e exists to prevent"
  - "5e's inactive branch was re-based on the journal rather than on ActiveEnterTimestamp. The timestamp was measured empty seconds after a successful start and stop, because the manager garbage-collects the unit; the plan's prescribed probe would have reported 'never started' for a unit that had just run"
  - "5b is scoped to the single file rather than to the custom/ directory: the live directory legitimately holds four files the repo copy does not, and a directory comparison would go red on a difference this phase does not own"
  - "The stale phase-13 assertion was rewritten, not deleted. It now fences the slot to exactly one hl.exec_cmd — the START-02 bootstrap — which preserves the original intent and additionally guards D-15 against an early Phase 20 leak"
  - "The §7 playbook block states both expected finding counts and the condition selecting each, rather than replacing one stale number with another that would go stale at the moment the phase succeeds"

patterns-established:
  - "Pattern: the revert is part of the proof. A mechanism proven by a live mutation is only honestly proven if the session is returned to its as-found state, because the post-re-login check is the observation the phase cannot schedule"
  - "Pattern: measure the blast radius of a live mutation before running it, not after. The PartOf fan-out in D-3 was read out of `ConsistsOf=` and `StopWhenUnneeded=` before the proof, which is what made the mitigation possible"
  - "Pattern: non-vacuity is proven against a probe extracted verbatim from the shipped script, never by disabling a clause in the shipped script itself"
  - "Pattern: a sibling suite going red on a correct change is a stale assertion, not a regression — read what it was protecting before deciding how to answer it"

requirements-completed: [START-02, START-03]

coverage:
  - id: D1
    description: "The repo copy of custom/execs.lua carries the session-bootstrap command literal inside a hyprland.start handler, with the Phase 13 authoring-SoT header"
    requirement: START-02
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh — [PASS] 5a guard (19 non-empty lines) and [PASS] 5a literal grep"
        status: pass
      - kind: other
        ref: "head -1 execs.lua diffed against head -1 general.lua — identical; luac -p execs.lua exits 0 ([PASS] in phase13-d19-assert.sh)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The repo copy and the live copy are byte-identical, so the hand-sync window is closed on every commit"
    requirement: START-02
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh — [PASS] 5b cmp -s, scoped to the one file"
        status: pass
      - kind: integration
        ref: "./scripts/phase13-d19-assert.sh — [PASS] live custom/execs.lua matches repo source"
        status: pass
    human_judgment: false
  - id: D3
    description: "hyprland-session.service is in state `linked` and never `enabled`, asserted on the printed string rather than the exit status"
    requirement: START-02
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh — [PASS] 5c state 'linked'"
        status: pass
      - kind: manual_procedural
        ref: "systemctl --user is-enabled hyprland-session.service -> prints `linked`, exits 1 — the exact inversion a status-based assert would report"
        status: pass
    human_judgment: false
  - id: D4
    description: "Starting the unit takes graphical-session.target from inactive to active through the unit's Wants=, and the target cannot be reached any other way"
    requirement: START-02
    verification:
      - kind: manual_procedural
        ref: "the five Task 1 observations quoted verbatim below — inactive, start exit 0, active, still `linked`, inactive again"
        status: pass
      - kind: other
        ref: "systemctl --user show graphical-session.target -p RefuseManualStart -> yes; -p ConsistsOf lists 14 PartOf units and no WantedBy/RequiredBy"
        status: pass
    human_judgment: false
  - id: D5
    description: "The live session was left in its as-found state, so criterion 5e's post-re-login evidence is not contaminated by a hand start"
    requirement: START-02
    verification:
      - kind: manual_procedural
        ref: "post-revert: target inactive, unit inactive, unit `linked`, and all eight PartOf helpers returned to active by D-Bus activation alone"
        status: pass
    human_judgment: false
  - id: D6
    description: "An inactive target is reported [INFO] naming the operator re-login, never [FAIL], and the message separates a pending step from a real regression"
    requirement: START-02
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh — [INFO] 5e, three distinct inactive branches, all proven reachable"
        status: pass
      - kind: manual_procedural
        ref: "probe fixtures I, F/G and H — the [PASS] branch, the still-loaded branch and the never-ran branch each reached; the assert emits no [FAIL] in any of them"
        status: pass
    human_judgment: false
  - id: D7
    description: "The operator docs name the disable footgun, its recovery command, and mask as the safe alternative for a stow-managed unit"
    requirement: START-03
    verification:
      - kind: integration
        ref: "./scripts/phase17-unblock-assert.sh — [PASS] 6 guard, [PASS] 6a, [PASS] 6b (both halves), [PASS] 6c"
        status: pass
    human_judgment: false
  - id: D8
    description: "The assert script is non-mutating in the executable sense D-20 means: none of the four verbs appears in command position"
    requirement: START-02
    verification:
      - kind: other
        ref: "the plan's quote-stripping and comment-stripping ban-grep -> 0; raw whole-file count -> 3, as expected by construction"
        status: pass
      - kind: other
        ref: "every systemctl call site read by hand: is-enabled, is-active, show; plus one read-only journalctl"
        status: pass
    human_judgment: false
  - id: D9
    description: "The playbook's expected-output lines for the phase-14 verify script are correct both before and after the re-login that flips the finding count"
    requirement: START-03
    verification:
      - kind: other
        ref: "§7 now states both counts and the single condition selecting each; the stale ownership sentence and the pre-archive Phase 15 path are both gone (grep -c -> 0 for each)"
        status: pass
    human_judgment: true
    rationale: "That the post-re-login count is zero is read off the phase-14 script's own branch structure — the D-38 check routes to info() when the target is active — rather than measured, because the script currently aborts on the D-1 baseline path before reaching any assert. Logged as deferred D-4."
  - id: D10
    description: "Every new assertion is non-vacuous — proven capable of failing, against fixtures only"
    requirement: START-02
    verification:
      - kind: manual_procedural
        ref: "17 fixture cases against a probe extracted verbatim from the shipped script; every assertion turned red on its own fixture and left its siblings green. Table below."
        status: pass
    human_judgment: false
  - id: D11
    description: "The three Phase 18 handoff rows are on disk, including the one that closes this phase's hand-sync window"
    requirement: START-02
    verification:
      - kind: other
        ref: "17-HANDOFF.md exists, three table rows, each naming a Phase 18 requirement id; grep -c execs.lua -> non-zero"
        status: pass
    human_judgment: false

# Metrics
duration: 18 min
completed: 2026-09-13
status: complete

actuals:
  tokens: 21000
  tasks: 3
  commits: 4
---

# Phase 17 Plan 05: Unblock Stow and Restore the Session Target Summary

**The one startup entry lost at the Phase 14 adopt is back in the custom overlay and applied live, the mechanism was measured once by hand and the session put back exactly as found, the `systemctl --user disable` footgun is written down with both halves of its recovery, and seven new assert sections hold all of it — with the one check no agent can turn green reporting `[INFO]` rather than a permanent red.**

## Performance

- **Duration:** 18 min
- **Completed:** 2026-09-13
- **Tasks:** 3
- **Commits:** 4
- **Files modified:** 5, plus 1 created

## Task Commits

| Task | Commit | Subject |
| --- | --- | --- |
| 1 | `1619cef` | feat(17-05): restore the session bootstrap in the custom overlay |
| 2 | `82a297c` | docs(17-05): document the disable footgun and correct two stale playbook claims |
| 3 | `6d63dbe` | test(17-05): assert criteria 5 and 6, with the inactive target reported as INFO |
| — | (this summary) | docs(17-05): complete the session target and footgun plan |

## The five systemd observations, verbatim

The plan authorises exactly one mutating check, run by hand and then reverted.
It was run once, at 16:40:47 local, and quoted here as it was printed:

```
=== OBS-1 BEFORE: target ===
inactive
=== OBS-1b BEFORE: unit ===
inactive
=== OBS-2 START (the one authorised mutating proof) ===
start exit=0
=== OBS-3 DURING: target ===
active
=== OBS-4 DURING: unit state ===
linked
=== OBS-4b DURING: unit active ===
active
=== REVERT: stop the unit ===
stop exit=0
=== OBS-5 AFTER: target ===
inactive
=== OBS-5b AFTER: unit ===
inactive
=== OBS-5c AFTER: unit state ===
linked
```

That is the whole of START-02's mechanism, measured rather than argued: the
target went from `inactive` to `active` on a single start of the unit, and the
unit stayed in state `linked` throughout — it was never enabled. The target
carries `RefuseManualStart=yes`, so the unit's `Wants=` is not merely the
chosen path to it but the only reachable one.

**The session was returned to its as-found state**, and this matters more than
it looks: leaving the target hand-started would have made the post-re-login
check report a green it had not earned, which is the one observation this phase
genuinely cannot schedule for itself. The assert run immediately afterwards
reports `[INFO]` for 5e, which is the honest reading.

## What the revert cost, and why it is in deferred-items rather than here

The revert did more than return two units to inactive, and the plan did not say
so because nothing in the plan's sources did.

`graphical-session.target` carries `StopWhenUnneeded=yes`, and
`hyprland-session.service` is the only unit that `Wants=` it. Stopping the
service therefore stopped the target — and fourteen services carry
`PartOf=graphical-session.target`, eight of which were active. `PartOf`
propagates stop. All eight went down: the four portals, the document portal, the
permission store, `gvfs-daemon` and the accessibility bus.

This was read out of `ConsistsOf=` and `StopWhenUnneeded=` **before** the proof
was run, not discovered afterwards, which is what made the mitigation possible:

- The proof ran only after confirming `/run/user/1000/gvfs` held no active fuse
  mount and no capture process was running, so a portal restart could not lose
  anything.
- All eight were returned to `active` by **natural D-Bus activation** — a
  ScreenCast `AvailableSourceTypes` read, a `GetMountPoint` call, `gio mount -l`
  and an `org.a11y.Bus GetAddress` getter. All read-only, and not one
  `systemctl` verb among them. The portal answered `u 7` both before and after,
  unchanged.

It is logged as **deferred D-3** rather than treated as a defect, because there
is nothing here to fix: this is the operator's systemd graph behaving as
configured, and the same fan-out happens at every normal session end. What is
worth recording is the blast radius, because it is invisible from the plan text
and the next person to hand-prove this mechanism — Phase 20, most likely — will
otherwise stop a live screen share and read it as an unrelated failure.

## The restored entry

`.config/hypr/custom/execs.lua` had been one byte, a bare newline, since the
adopt. It now carries the Phase 13 authoring-SoT header verbatim, a comment
explaining the mechanism, and one handler:

```lua
hl.on("hyprland.start", function ()
    hl.exec_cmd("systemctl --user start hyprland-session.service")
end)
```

The call sits **inside** the handler because it is a former `exec-once`: it must
fire once per session, not on every config reload — which is exactly what the
vendor file's own first line says about where former startup commands belong.
Both handlers coexist because `hyprland.lua` requires `custom.execs` after
`hyprland.execs`, which is the entire purpose of the overlay slot. The vendor
tree was not touched.

Exactly one entry landed. The six others lost at the adopt are START-01 and
belong to Phase 20, and the phase-13 assert rewritten below now fences that: a
second `hl.exec_cmd` appearing here turns it red.

## What 5a-5e and 6a-6c assert

**5a — the command literal, in the authoring copy.** Behind a guard that counts
non-empty *lines* rather than testing `-s`, and the reason is this file
specifically: a single newline is one byte and passes `-s` while holding
nothing, which is precisely the state it was in before this plan. 5a runs
against the repo copy because that is the authoring source of truth, and because
5b cannot substitute for it — the fixture table below shows a file with the right
handler shape and the wrong verb passing `cmp` cleanly against an equally wrong
live copy.

**5b — byte identity, scoped to one file.** The live `custom/` directory
legitimately holds four files the repo copy does not; upstream seeds them and
the named-files apply leaves every one alone. A directory comparison would go
red on a difference this phase does not own. The window it watches is real and
temporary, and 17-HANDOFF.md row 3 is what eventually closes it.

**5c — the state word, never the exit status.** `systemctl --user is-enabled`
prints `linked` and **exits 1** for this unit, which is the correct state. A
status-based assertion would report the precise opposite of the truth, and an
unguarded command substitution would abort the whole run under `set -euo
pipefail` before the word could be read. Four states are handled distinctly,
and `enabled` gets its own message naming the footgun it arms.

**5e — `[INFO]`, never `[FAIL]`.** The target comes up at login, and no agent
can end the operator's session, so a red here would be permanently red through
no defect — which is worse than no check at all, because it teaches readers to
ignore the colour. The probe is phase-14's, kept verbatim; only the
classification changes, per D-23.

**6a, 6b, 6c — three checks, not one alternation.** A single
`grep -E 'a|b|c'` is satisfied by any one of the three, so a playbook that named
the footgun and forgot both the recovery and the safe alternative would pass it.
6b asserts both halves of the recovery separately and reports which half is
missing, and it pins the valid `--verbose=5 --no-folding` flag pair — a recovery
documented with the old `-v=5` spelling is copy-pasteable and exits 1, which the
fixture table proves it catches.

## A probe the plan prescribed that would have lied

The plan specified `ActiveEnterTimestamp` as 5e's discriminator between a
pending re-login and a real regression: empty means never started, populated
means started and stopped.

Measured immediately after the hand proof above, seconds after a successful
start and stop, **every** runtime timestamp on the unit read empty:

```
StateChangeTimestamp=
InactiveExitTimestamp=
ActiveEnterTimestamp=
ActiveExitTimestamp=
InactiveEnterTimestamp=
```

Once the unit goes inactive it is unreferenced, jobless and not enabled, so the
manager garbage-collects the unit object and the runtime properties reset. An
empty timestamp does not mean "never started"; it means "not currently loaded",
which is the normal state and says nothing at all. The prescribed probe would
have reported `never ran this boot` for a unit that had just run.

The journal survives collection and discriminates cleanly: **3** records for the
unit this boot after the hand proof, **0** for `plasma-plasmashell.service` as a
control — a unit that genuinely never ran. 5e now reads the journal, and keeps
the timestamp as the *first* check with a sharper meaning than the plan gave it:
populated means the unit is still loaded and active **while the target is down**,
which is the genuinely broken state rather than a pending one.

All three inactive branches are reachable and were reached. See the fixture
table.

## Non-vacuity evidence

Every new assertion was proven capable of failing. No clause was disabled in any
shipped script, no real input was mutated, and no fixture ran a recursive
delete — the fixtures are plain files under the session scratchpad.

The probe is not a re-implementation: the criterion 5 and 6 block is extracted
**verbatim** from `scripts/phase17-unblock-assert.sh`, with only seven
input-variable spellings made env-overridable so fixtures can be fed in. Every
condition and every message is the shipped text. Run with no overrides it
reproduces the shipped output line for line, `=== done: FAIL=0 ===`.

| # | Fixture | Result |
| --- | --- | --- |
| A | repo overlay path missing | `[FAIL] 5a guard` + `[FAIL] 5a` literal + `[FAIL] 5b`; `FAIL=3` |
| B | repo overlay is one newline (the `-s` trap) | `[FAIL] 5a guard` — the byte-size test would have passed here |
| C | right handler shape, verb changed to `restart` | `[PASS] 5a guard`, `[FAIL] 5a` literal, **`[PASS] 5b`** — the direct demonstration that `cmp` passes when both copies are equally wrong |
| D | applied copy missing | `[FAIL] 5b` naming the apply hop |
| E | copies drifted by one appended line | `[FAIL] 5b` DIVERGED |
| F | unit probe → `pipewire.service` (state `enabled`) | `[FAIL] 5c` naming the armed-footgun state |
| G | unit probe → `dbus.service` (state `alias`) | `[FAIL] 5c` catch-all branch |
| H | unit probe → a name that does not exist | `[FAIL] 5c` `not-found`, pointing at the recovery block |
| I | target probe → an active unit | `[PASS] 5e` — the pass branch is reachable |
| F/G | (same runs) target inactive, probed unit active | `[INFO] 5e` still-LOADED branch, with a populated timestamp |
| H | (same run) target inactive, unit never ran this boot | `[INFO] 5e` never-ran branch |
| — | live repo, target inactive, unit ran and stopped | `[INFO] 5e` ran-and-stopped branch, 3 journal records |
| J | playbook path missing | `[FAIL] 6 guard` + 6a + 6b + 6c; `FAIL=4` |
| K | playbook empty | `[FAIL] 6 guard` + 6a + 6b + 6c; `FAIL=4` |
| L | minimal fixture with all four literals | all four `[PASS]` — the checks are satisfiable, not impossible |
| M | footgun verb absent, rest present | `[FAIL] 6a` alone; 6b and 6c stay green |
| N | re-stow command absent | `[FAIL] 6b` (`present=0`, `reload=1`) alone |
| O | re-stow present with the invalid `-v=5` spelling | `[FAIL] 6b` — the flag pair is genuinely pinned |
| P | daemon-reload absent | `[FAIL] 6b` (`present=1`, `reload=0`) alone |
| Q | safe alternative absent | `[FAIL] 6c` alone |

Cases M through Q are the ones that prove 6a/6b/6c are independent rather than
an alternation: each turns exactly its own assertion red and leaves both
siblings green.

The rewritten phase-13 assertion was proven the same way, against the same
fixtures: `good.lua` passes; the wrong-verb file fails; a file with a second
`hl.exec_cmd` — a simulated early Phase 20 leak — fails on `counted 2`; the
newline-only file and an absent file both fail on `counted 0`.

**One branch not demonstrated:** 5c's empty-string branch, which fires when the
user manager answers nothing at all. A nonexistent unit name produces
`not-found` rather than silence, so the branch is defensive and remains
unexercised. It is a `[FAIL]` either way, so it cannot produce a false green.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] 5e's prescribed probe reports the opposite of the truth.**
`ActiveEnterTimestamp` is wiped when the manager garbage-collects the stopped
unit, so the plan's "empty means never started" reading would have called a unit
that had just run `never ran this boot`. Re-based the branch on the journal,
which survives collection, and gave the timestamp the sharper meaning it
actually carries. Measured both sides before changing anything. Landed in
`6d63dbe`.

**2. [Rule 3 — Blocking] `scripts/phase13-d19-assert.sh` went red on a correct
change.** It asserted `execs.lua exists with no Lua statements` — the exact
absence START-02 requires be filled. An assertion that has to be deleted before
a requirement can land was testing the wrong property, so it was **rewritten,
not removed**: the slot is now fenced to exactly one `hl.exec_cmd`, and that it
is the session bootstrap. This keeps the original intent (nothing stray in the
overlay) and additionally guards D-15 against an early Phase 20 entry. A
`luac -p` parse check was added alongside. Landed in `6d63dbe`.

**3. [Rule 2 — Missing Critical] The revert's blast radius was measured before
running it, and mitigated.** The plan described the revert as returning two
units to inactive. It also stops eight live helper services through
`StopWhenUnneeded` plus `PartOf` propagation. Pre-checked that nothing could be
lost, ran the proof, then restored all eight by D-Bus activation alone. Logged
as deferred D-3 for whoever repeats the proof.

**4. [Rule 1 — Bug] The §8 ownership rewrite initially said "the remaining
five".** It is six: `wl-clip-persist`, four workspace-pinned autostarts, and
`hyprpaper`. Corrected before the Task 2 commit.

---

**Total deviations:** 4 auto-fixed (1 blocking, 1 missing critical, 2 bugs)
**Impact on plan:** No scope creep. Deviations 1 and 2 are both the same shape —
a check that would have passed while observing the wrong thing — and deviation 3
added no repo change at all, only a measurement and a deferred row.

## Issues Encountered

**`scripts/phase14-verify.sh` exits 1 — pre-existing, deferred, not fixed.**
Unchanged from 17-03 and 17-04. It hard-codes a baseline fixture path that
`f314491 chore: archive v0.3 milestone` relocated, and aborts before its first
assert:

```
[FAIL] baseline fixture missing: .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt
```

Logged as D-1, with the repo-wide sweep for the same pattern as D-2. This plan's
`<verify>` block calls that script, so that one check cannot be satisfied here;
it is a known unrelated failure and not a regression from this wave. A
second-order consequence is logged as **D-4**: the playbook's §7 observed-counts
line cannot be re-measured while D-1 stands, which is why §7 now documents both
expected outcomes and the condition selecting them rather than a fresh
measurement.

## Known Stubs

None. The one thing deliberately left incomplete is the criterion 5e observation
itself, which is not a stub but the operator re-login this phase cannot schedule
— it is carried as the human check below and reports `[INFO]` until then.

## Threat Flags

- **T-17-05 (tampering, `disable` against a stow-managed unit) — mitigated and
  asserted.** The footgun, both halves of its recovery and the safe alternative
  are in the playbook and asserted by 6a/6b/6c. The unit is never enabled, which
  keeps the state where the footgun bites out of reach.
- **T-17-16 (repo/live divergence) — mitigated and asserted.** 5b gates byte
  identity on every run, and 17-HANDOFF.md row 3 carries the closure obligation
  to Phase 18 so the duplication is retired rather than forgotten.
- **T-17-17 (a hand-started target reporting an unearned green) — mitigated.**
  The proof was reverted and the as-found state verified; 5e reports
  informationally rather than passing while the target is inactive.
- **T-17-18 (target reachable by manual start) — accepted, and re-measured.**
  `RefuseManualStart=yes` confirmed live. The start direction propagates to
  nothing: the target has no `WantedBy` and no `RequiredBy`, and its fourteen
  `ConsistsOf` units are `PartOf` relationships, which propagate stop and
  restart but never start. The **stop** direction does propagate, which is new
  information and is recorded as D-3.

## User Setup Required

**One operator step, and it is the last sub-claim of criterion 5.** Log out of
the Hyprland session and log back in, then run:

```bash
./scripts/phase17-unblock-assert.sh
# expect: the 5e line reads [PASS] graphical-session.target is ACTIVE
```

That is the proof the target came up **from the custom overlay at login**, which
is the only thing a hand start cannot demonstrate. If 5e still reads `[INFO]`
after a genuine re-login, that is a real regression rather than a pending step.

`./scripts/phase14-verify.sh` is the independent corroboration — its finding
count should drop to zero — but it cannot run until D-1 is fixed.

## Next Phase Readiness

**Ready for 17-06.** The harness closes `=== done: FAIL=0 ===` with 76 `[PASS]`
and 4 `[INFO]` lines, covering criteria 1, 3, 4, 5 and 6. Both sibling suites
are green: `phase16-retire-assert.sh` at `=== done: FAIL=0 ===` and
`phase13-d19-assert.sh` at `=== Phase 13 asserts: FAIL=0 ===`.

**Handed to Phase 18** in `17-HANDOFF.md`: the two folded directory symlinks
(CAP-01/CAP-02), the still-tracked `.config/kdeglobals` (FIX-03), and the
`custom/execs.lua` authoring copy that must appear in FIX-03's redistribution
table as moving into `stow/hypr/` under HYPR-01. That third row is what closes
the hand-sync window this plan opened.

**Open, not blocking:** deferred D-1 through D-4.

## Self-Check: PASSED

- `.config/hypr/custom/execs.lua` — found on disk, 19 non-empty lines, one
  `hl.exec_cmd`, header byte-identical to `general.lua` line 1, `luac -p` clean,
  byte-identical to the live copy under `cmp -s`.
- `docs/dots-hyprland-workflow.md` — found; carries all of
  `systemctl --user disable`, `systemctl --user mask`,
  `stow --verbose=5 --no-folding -t ~ systemd`,
  `systemctl --user daemon-reload`, and both pinned invocation forms; carries
  zero occurrences of `unowned work with no owning phase` and zero of
  `.planning/phases/15-playbook-safe-vs-full/`.
- `17-HANDOFF.md` — found, three rows, each naming a Phase 18 requirement id.
- `scripts/phase17-unblock-assert.sh` — found, `bash -n` clean, closes
  `=== done: FAIL=0 ===`; the quote-stripping and comment-stripping ban-grep
  reads **0** while the raw whole-file count reads 3, exactly as the plan
  predicts for a correct script.
- `scripts/phase13-d19-assert.sh` — found, `bash -n` clean, closes
  `=== Phase 13 asserts: FAIL=0 ===`.
- Commits `1619cef`, `82a297c` and `6d63dbe` — all three present in `git log`.
- Live session confirmed in its as-found state: target `inactive`, unit
  `inactive` and `linked`, all eight `PartOf` helpers `active`, portal answering
  `u 7` unchanged.
- All task `<acceptance_criteria>` re-run and passing; all plan `<verify>`
  commands re-run, with the single `phase14-verify.sh` failure documented above
  as pre-existing and out of scope.

---
*Phase: 17-unblock-stow-and-restore-the-session-target*
*Completed: 2026-09-13*
