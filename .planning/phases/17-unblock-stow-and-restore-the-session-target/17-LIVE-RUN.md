# Phase 17 — criterion 2, live half: the one-way run of `arch/hyprland.sh`

This document is the evidence record for a run that cannot be repeated. The plan that
governs it — `17-07-PLAN.md` — forbids re-running the installer to produce a tidier
record, so anything this document does not contain was not captured, and is recorded
below as a gap rather than re-measured.

Run date: 2026-09-13. Repository HEAD at run time: `d214080`.

## The decision that authorised it

`17-07-PLAN.md` carries two `blocking-human` gates. Both were put to the operator and
both were answered by the operator, not inferred.

- The decision gate (plan line 76) asked whether to accept the one-way cost now or defer
  criterion 2's live half. The operator answered **`run-now`**.
- The precondition gate (plan line 113) required six preconditions confirmed immediately
  before the run. Five were measured and reported; the sixth — a full system upgrade — was
  run by the operator, because `sudo -n true` fails on this machine and every privileged
  line in the installer needs an interactive password. The operator ran both commands.

## What the cost actually was

The plan's checkpoint text was written on the assumption that the run would install
packages and widen group membership. Measured immediately before the run, neither was
true on this machine:

- All nineteen packages the installer names through `pacman` were already installed.
- `gnome-network-displays`, the one package installed through the AUR helper, was already
  installed.
- The operator was already a member of the `i2c` group (`i2c:x:966:pera`).

So `--needed` installed nothing and `usermod -aG i2c` was a no-op. The transcript confirms
this directly: all six package operations end in `there is nothing to do`, and the group
list is byte-identical before and after.

What remained genuinely irreversible was narrower than the plan anticipated — five
`pacman -Sy` refreshes and one `yay -Sy` refresh, each without an upgrade flag. The
precondition gate's full upgrade was run immediately beforehand for exactly this reason,
and it neutralised them: every subsequent refresh in the transcript reports the databases
already up to date.

The full upgrade itself moved six packages, one of which the installer also names:

    ddcutil 3.0.1-1, pyalpm 0.12.0-1, python-grpcio 1.84.0-1,
    python-grpcio-tools 1.84.0-1, python-platformdirs 4.11.8-1, python-urwid 4.1.3-1

The installer's fourth stanza then reported `ddcutil-3.0.1-1 is up to date -- skipping`,
which is the ordering the gate intended.

## The invocation form

    script -q -e -c 'bash /home/pera/github_repo/.dotfiles/arch/hyprland.sh' \
      .planning/phases/17-unblock-stow-and-restore-the-session-target/17-CRITERION2-TRANSCRIPT.txt

An absolute path. `-e` makes `script` return the wrapped command's exit status rather than
its own, which is the flag spelling the plan deliberately deferred to run time
(`17-07-PLAN.md` flagged planner assumption). `script` is util-linux 2.42.3.

The plan's own text at lines 139-141 says a repo-root-relative invocation "fails at the
second directory change". That was true when the plan was written and is no longer true.
Plan 17-06's checkpoint was answered `hoist-script-dir`, and commit `4599a86` hoisted a
single resolved `REPO_ROOT` at the top of the installer. Every invocation form now exits 0;
the measurements are in `deferred-items.md` D-5. The absolute form was used anyway, because
it is the form the plan pinned and the run was not the moment to vary it.

## Result

| Observation | Before | After |
|---|---|---|
| `hyprctl -j status \| jq -r .configProvider` | `lua` | `lua` |
| `~/.config/hypr/hyprland.conf` | absent | absent |
| `~/.config/systemd/user/hyprland-session.service` | symlink into the repo | symlink into the repo |
| `id -nG` | `pera wireshark docker i2c video input wheel` | `pera wireshark docker i2c video input wheel` |

**Wrapped command exit status: `0`.** Read from `WRAPPED_EXIT=$?` after a `script -e`
invocation, not inferred from the transcript ending without a visible error.

Post-run link state, each checked for link-ness and resolved target rather than mere
presence:

    ~/.config/systemd/user/hyprland-session.service
      -> /home/pera/github_repo/.dotfiles/stow/systemd/.config/systemd/user/hyprland-session.service
    ~/.config/swaync/config.json
      -> /home/pera/github_repo/.dotfiles/stow/swaync/.config/swaync/config.json
    ~/.config/swaync/mocha.css
      -> /home/pera/github_repo/.dotfiles/stow/swaync/.config/swaync/mocha.css
    ~/.config/swaync/style.css
      -> /home/pera/github_repo/.dotfiles/stow/swaync/.config/swaync/style.css

Both `stow` invocations were no-ops. Every entry reports `--- Skipping ... as it already
points to ...`, which is the correct outcome for links that were already in place and is
evidence that the run did not overwrite a symlink with a plain file — the T-17-22 concern.

## Transcript

`.planning/phases/17-unblock-stow-and-restore-the-session-target/17-CRITERION2-TRANSCRIPT.txt`
— 769 lines, 58829 bytes at capture. Most of it is `stow --verbose=5` planning output.

All eight of the installer's stanzas appear, in source order:

| # | stanza | installer line | transcript line |
|---|---|---|---|
| 1 | `[INSTALL] Core Hyprland & Wayland Protocols` | 14 | 7 |
| 2 | `[INSTALL] XDG Desktop Portals` | 17 | 18 |
| 3 | `[INSTALL] Hyprland Ecosystem (Wallpaper, Lock, Idle, Screen etc.)` | 20 | 29 |
| 4 | `[INSTALL] Utilities & Clipboard` | 23 | 44 |
| 5 | `[CONFIG] Setup i2c group for ddcutil` | 26 | 56 |
| 6 | `[INSTALL] Notifications, Bluetooth & Casting (Swaync dependencies)` | 29 | 59 |
| 7 | `[CONFIG] Graphical Session Bootstrap (systemd xdg-desktop-portal fix)` | 41 | 77 |
| 8 | `[CONFIG] Swaync Config` | 45 | 392 |

None was skipped and none ran out of order.

### Partial-upgrade signature scan

The plan's human check asks for the one failure mode a zero exit status would hide. A scan
of the transcript for `cannot open shared object`, `version ... not found`, `unresolvable`,
`breaks dependency`, `conflicting files`, `error:`, `failed retrieving` and
`invalid or corrupted` returns no match. `there is nothing to do` appears six times, once
per package operation.

### Redaction

The transcript as captured contained this host's `/etc/machine-id` and boot ID seven times
each, inside the OSC escape sequence `sudo` emits on each authentication. The value was
verified byte-for-byte against `/etc/machine-id`. systemd treats the machine ID as
confidential and it must not be published; this repository has a GitHub remote. Both
identifier classes were replaced with `REDACTED-MACHINE-ID` and `REDACTED-BOOT-ID`.

The redaction was proved to be scoped to those two token classes: normalising both the
original and the redacted file on exactly those patterns produces byte-identical output,
and the line count is unchanged at 769. The unredacted capture was kept outside the
repository, in the session scratchpad, and is not committed.

The operator's password is not present. `sudo` disables terminal echo, so the typed
characters were never written to the pty. `gitleaks dir` over the file reports
`no leaks found`.

## Group membership note

`sudo usermod -aG i2c pera` ran and is recorded in the transcript at stanza 5. On this
machine it changed nothing, because the operator was already a member. The line remains a
durable privilege widening on any machine where it is not already true, it survives logout,
and it maps to no Phase 17 requirement — it is threat register row T-17-04, dispositioned
`accept`, and it is surfaced here as the plan requires rather than left to be discovered.

## Phase gate, measured after the run

| Script | Closing line |
|---|---|
| `./scripts/phase17-unblock-assert.sh` | `=== done: FAIL=0 ===` |
| `./scripts/phase16-retire-assert.sh` | `=== done: FAIL=0 ===` |
| `./scripts/phase13-d19-assert.sh` | `=== Phase 13 asserts: FAIL=0 ===` |
| `./scripts/phase12-full-smoke.sh` | `=== done: FAIL=0 ===` |
| `./scripts/phase11-dispositions-assert.sh` | `=== done: FAIL=1 ===` |
| `./scripts/phase10-inventory-assert.sh` | `=== done: FAIL=1 ===` |
| `./scripts/phase14-verify.sh` | `       Aborting rather than comparing against nothing.` |

The three that are not green are not regressions from this run, and not regressions from
Phase 17 at all. Each names a file that still exists but moved:

    [FAIL] D-01 dispositions file missing: .planning/phases/11-disposition-decisions/11-DISPOSITIONS.md
    [FAIL] D-01 inventory file missing:    .planning/phases/10-full-install-impact-inventory/10-INVENTORY.md
    [FAIL] baseline fixture missing:       .planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt

All three are present under `.planning/milestones/v0.3-phases/`. The scripts hold the
pre-archive paths. This was reproduced rather than assumed: commit `f314491`
(`chore: archive v0.3 milestone`) was checked out into a scratch worktree and the three
scripts were run there, returning `FAIL=1`, `FAIL=1` and the same abort. `f314491` is an
ancestor of `1f10eee`, Phase 17's planning commit, so the failures predate the phase. They
are already recorded as deferred items D-1 and D-2.

The identical results before and after the run are themselves evidence: the run changed
nothing the suites measure.

## Session state after the run — recorded honestly

`hyprland-session.service` and `graphical-session.target` are both `inactive`, and
`waybar.service`, `swaync.service` and `hyprpaper.service` are inactive with no running
processes. This is not damage from the run, and the distinction was measured rather than
argued: `systemctl --user show` reports an empty `ActiveEnterTimestamp` *and* an empty
`InactiveEnterTimestamp` for every one of those units. A unit the run had stopped would
carry an `InactiveEnterTimestamp`. These units have not been active at any point in this
boot, so there was nothing for the run to stop.

The cause is the expected one. The live Hyprland process started at 16:34:32, before the
`custom/execs.lua` hook from plan 17-05 could apply; that hook starts
`hyprland-session.service` on `hyprland.start`, so the target comes up at the next Hyprland
launch. `hypridle` and `xdg-desktop-portal-hyprland` are running. No user unit is in the
`failed` state. Hyprland itself is pid 1501.

This means one acceptance item from the plan's human check — that the bar is running,
notifications work, and screen sharing offers sources — is **not confirmed by this
document**, because those helpers were not running before the run either. The run neither
broke them nor fixed them. Confirming them needs the operator re-login that criterion 5
already tracks, and that re-login is also what deferred item D-4 is waiting on.

## Gaps in this record

- The pre-run capture did not include user-unit states, so the "never active this boot"
  finding rests on the empty systemd timestamps rather than on a before/after comparison.
  The timestamps are conclusive on their own, but the symmetry is missing.
- The desktop-behaviour half of the plan's human check is unconfirmed, for the reason given
  above. It is not re-measurable without the pending re-login, and the plan forbids a second
  run.
