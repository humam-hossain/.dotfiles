# Phase 14 live full adopt runbook

Operator playbook for the one-window live `illogical-impulse` (`ii`) full adopt on this machine: install, overlay apply, reboot, first login, verification, and rollback.

## Purpose

Phase 14 is the first phase that mutates the live machine, and **the operator runs the mutation, not an agent** (ADOPT-01, D-01). This document is the single unambiguous order for the whole window (D-21). Read it end to end before starting.

One window covers all of it: install → overlay apply → reboot → first login → verify. There is no second gate part-way through (D-21).

> **Flag / subcommand details:** keep DRY — run `./arch/dots-hyprland.sh help` for the allowlisted subcommands, the wrapper-owned meta flags, and the uninstall flags. This document does not re-copy the help text. It names only the flags that were *forbidden* during the window (section 4) and the ones the window actually used.

> **This is a record, not a procedure.** It describes the 2026-09-04 adopt window as it was run. Phase 16 later retired the safe profile, the wrapper's backup gate, the `protect` subcommand and the ii-hook injection, so several steps below no longer occur on a present-day install. Each such step is marked where it appears. For what to run today, use [`docs/dots-hyprland-workflow.md`](./dots-hyprland-workflow.md).

> **Read this from GitHub or from your local copy, not from a browser you no longer have.** Section 2 stages a plain-text copy outside the config tree so section 14 is reachable from a bare TTY (D-25).

## Outline

1. [Prerequisites and scope of this window](#1-prerequisites-and-scope-of-this-window)
2. [Start the recording and stage an offline copy](#2-start-the-recording-and-stage-an-offline-copy)
3. [Go / no-go gate (ADOPT-01, D-18..D-22)](#3-go--no-go-gate-adopt-01-d-18d-22)
4. [Banned flags and prompt answers (D-22)](#4-banned-flags-and-prompt-answers-d-22)
5. [Rotate the stale backup (D-27)](#5-rotate-the-stale-backup-d-27)
6. [Stop Hyprland and switch to a bare TTY (D-06)](#6-stop-hyprland-and-switch-to-a-bare-tty-d-06)
7. [Run the install (D-07)](#7-run-the-install-d-07)
8. [Apply the Phase 13 overlay (D-08)](#8-apply-the-phase-13-overlay-d-08)
9. [Re-stow kitty (D-17)](#9-re-stow-kitty-d-17)
10. [Reboot (D-10)](#10-reboot-d-10)
11. [Log in at a TTY and start the session (D-16)](#11-log-in-at-a-tty-and-start-the-session-d-16)
12. [Verify (plan 14-02)](#12-verify-plan-14-02)
13. [Known losses (D-38)](#13-known-losses-d-38)
14. [Rollback (ADOPT-04, D-23, D-24)](#14-rollback-adopt-04-d-23-d-24)

Reference links live in [See also](#see-also) at the foot of the file.

**Follow the sections in the order above and do not reorder them.** That numbering is the D-21 sequence; it appears once, here, and nowhere else in this file.

---

## 1. Prerequisites and scope of this window

This one window covers **all five** of: the full install, the Phase 13 overlay apply, the reboot, the first login, and the verification run. You do not stop for approval between them (D-21). You stop only for the gate in section 3, before anything mutates.

Have all of this before you start:

- **At least a two-hour uninterrupted window.** A `pacman -Syu` runs inside the install and may pull a kernel.
- **A physically reachable TTY.** `Ctrl+Alt+F2` on this machine. The install must not run inside a live Hyprland session (section 6).
- **A second device that can reach GitHub** — phone or laptop. If this machine ends up with no desktop, section 14 is what you read, and you read it from there or from `~/phase14-rollback.txt`.
- **You have read** [`.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md`](../.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md). Section 13 assumes it.
- **Working directory is the repo root** of this `.dotfiles` clone for every command below, unless the command starts with `~`.
- **This machine has no display manager.** The session starts from `/usr/bin/start-hyprland` at a TTY (section 11).

---

## 2. Start the recording and stage an offline copy

1. **Start the transcript.** From the repo root:

   ```bash
   script .planning/phases/14-live-full-adopt-verify/14-ADOPT-TRANSCRIPT.txt
   # expect: "Script started, output log file is '...14-ADOPT-TRANSCRIPT.txt'"
   ```

   Everything from here to the end of section 12 happens inside that shell. Type `exit` to close the recording when the window is over.

   > **Do not add `--log-in` or `--log-io`.** The install runs `sudo pacman`, and those two modes record terminal *input* — which means your sudo password lands in a file this repo commits. Plain `script` records output only. That is what we want.

2. **Stage the offline copy of this document.** Still from the repo root:

   ```bash
   cp docs/phase14-adopt-runbook.md ~/phase14-rollback.txt
   # expect: no output; ~/phase14-rollback.txt now exists
   ```

   This is the belt to D-25's braces. Section 14 has to be readable from a bare TTY with `less ~/phase14-rollback.txt` even when the desktop and the network are both gone. It lives outside the config tree on purpose — nothing in this window writes to `$HOME` except the backup rotation in section 5 and upstream's own install.

---

## 3. Go / no-go gate (ADOPT-01, D-18..D-22)

**The gate is this checklist, worked by a human. It is not a script's exit code.**

On 2026-09-04, `scripts/phase14-preflight.sh` was run as **input 1** to the gate. The following is a record of what that run produced. The script was removed in Phase 16 because the adopt it gated has happened and nothing re-runs it.

Record of the 2026-09-04 preflight run:

```bash
# Record: this command was run on 2026-09-04 before the install.
# scripts/phase14-preflight.sh no longer exists (removed in Phase 16).
#   ./scripts/phase14-preflight.sh
# result: exit 0, and a [FINDING] line naming ii-original-dots-backup
```

The script printed at three levels and only the last one moved its exit code:

| Level | Meaning | Moved exit code |
|---|---|---|
| `[PASS]` | hard condition satisfied | — |
| `[FINDING]` | a condition the script deliberately declined to encode as an exit code, because clearing it required a `$HOME` mutation reserved for this window | **no** |
| `[FAIL]` | hard condition violated | **yes** |

That split was D-18 in practice: the exit code was input 1, this checklist was the gate. A `[FINDING]` was not a pass — it was a condition to disposition by hand before deciding.

### Go inputs — all four held on 2026-09-04

1. `scripts/phase14-preflight.sh` exited **0**.
2. Every `[FINDING]` line that run printed was **read and dispositioned** against the no-go list below.
3. `11-DISPOSITIONS.md` had been read.
4. A physical TTY was reachable.

### No-go conditions — every one of these was a hard blocker

Any single one meant **stop**. Do not start the install.

- The preflight exited non-zero.
- `installed_true` was absent (the preflight would abort early and say so). Without it upstream treats this as a first run and replaces your lock and idle configs instead of writing `.new` sidecars alongside them.
- The working tree was dirty, or commits were not on `origin/main`. The version of this document you may have to read from a phone would not be the version you are following.
- The vendor submodule was dirty, or the parent recorded a different pin.
- You had less than a two-hour window.
- There was no second device able to reach GitHub.
- **The preflight printed a `[FINDING]` naming `ii-original-dots-backup` and section 5 had not been run yet.**

   Write this one out rather than take it by reference, because it was the one no-go the exit code did not enforce. At the time the window was prepared, `~/ii-original-dots-backup` existed on this machine and the `hyprland.conf` inside it was older than the live one. Upstream's `auto_backup_configs` skips the backup **entirely** when that directory is already present and `ask` has been flipped false — so the run about to be made would take no fresh backup at all, and the only "backup" would be a stale copy from an earlier install. Clearing that was a `$HOME` mutation, and a `$HOME` mutation belonged inside this window and nowhere else. That is precisely why the script *reported* the condition instead of failing on it: a preflight that failed here would have been unconditionally red during prep and would have pushed whoever ran it into rotating the backup days early. [Post-adopt: `~/ii-original-dots-backup` was recreated by the `--full` install and now holds the *pre-adopt* configs, which at the time made it a rollback source rather than a stale directory to clear. Phase 16 withdrew the tiered rollback entirely — [section 14](#14-rollback-adopt-04-d-23-d-24) now documents clean reinstall as the only route, and that directory is left on disk without being presented as a recovery path — read the post-adopt caveat in [section 5](#5-rotate-the-stale-backup-d-27) before acting on this no-go.]

   Going without rotating would have cost the rollback tier that existed at the time its third source. (Phase 16 withdrew the tiers; section 14 now documents clean reinstall as the only route.) Section 5 was run first, then the preflight was re-run, and then this list was worked.

### Making the decision

The go or no-go decision was said **out loud** while the transcript from section 2 was running, so it landed in the recording (D-19). There was no separate signed-off file — the spoken decision in the transcript is the record.

---

## 4. Banned flags and prompt answers (D-22)

Do not pass any of these to the install. Each one silently removes a protection this whole phase is built on.

| Never pass | What it breaks |
|---|---|
| `-f` / `--force` | Sets `ask` false. With `ask` false and the backup directory present, `auto_backup_configs` takes **no backup at all**. |
| `--skip-backup` | At the time of this window the wrapper refused it bare. **Phase 16 inverted that:** the wrapper now passes `--skip-backup` to upstream on every `install` / `install-files` (see section 5), so it is no longer an operator flag to avoid — it is the wrapper's own injection. Pass `--keep-backup` to leave upstream's snapshot enabled for a run. |
| `-F` / `--firstrun` | Makes upstream treat this as a first install, so it **replaces** live `hyprlock.conf` and `hypridle.conf` instead of writing `.new` sidecars alongside them. That breaks D-24's lock/idle no-touch guarantee. |
| `--skip-hyprland-entry` | Skips installing `hyprland.lua`. The install appears to succeed and ADOPT-02 is silently defeated — the session never becomes Lua-configured. |

**A fifth prohibition that is not a flag:** never type `yesforall` at any prompt, and answer `y` at the greeting. Both `n` at the greeting and `yesforall` mid-install set `ask` false *before* the backup stage runs, which lands you in exactly the no-backup branch the table above describes. Answer `y` / `Y` at every prompt, one at a time.

---

## 5. Rotate the stale backup (D-27)

This section was mandatory whenever the preflight's `ii-original-dots-backup` line came back as a `[FINDING]` — which was whenever the directory existed, as it did at the time the 2026-09-04 window was prepared.

On 2026-09-04, the rotation was performed. The following is a record of what was run:

```bash
# Record: these commands were run on 2026-09-04 before the install.
# scripts/phase14-preflight.sh no longer exists (removed in Phase 16).
#   ./scripts/phase14-preflight.sh --rotate-backup
# result: [ROTATED] old: /home/<you>/ii-original-dots-backup
#         [ROTATED] new: /home/<you>/ii-original-dots-backup.20260904T171128Z

#   ./scripts/phase14-preflight.sh
# result: the ii-original-dots-backup line was now [PASS], not [FINDING]
```

`--rotate-backup` was the only mutating path in that script. It performed one `mv` and no delete of any kind; the old backup was renamed aside, never removed. The timestamped directory `~/ii-original-dots-backup.20260904T171128Z` still exists on disk as a result of that rotation.

**This mechanism is retired.** The wrapper no longer takes a backup on install (Phase 16 passes `--skip-backup` to upstream unconditionally), so no future install produces a `~/ii-original-dots-backup` directory and no reader should rotate anything now. The script that performed the rotation has been deleted.

---

## 6. Stop Hyprland and switch to a bare TTY (D-06)

The install must not run from inside a live Hyprland session.

```bash
# From inside the session: exit Hyprland (SUPER+M on the pre-adopt config),
# then log in at a TTY:  Ctrl+Alt+F2
```

Upstream's files stage ends by asking the compositor to reload a config file it has just renamed away. With nothing running that call fails harmlessly. Inside a live session it reloads a config that no longer exists, and the failure mode is a session you then have to recover from before you have even finished installing.

Re-open the transcript from section 2 at the TTY if your `script` shell did not survive the switch, and `cd` back to the repo root.

---

## 7. Run the install (D-07)

This is the real mutating run and it is **yours to type**. No agent runs it.

```bash
./arch/dots-hyprland.sh install --full
```

That is the whole invocation: the wrapper, its `install` subcommand, the `--full` meta flag, and nothing else. No extra flags — see section 4.

### What was seen during the window, in upstream's own order

**Record of the 2026-09-04 run.** Steps 1 and 6, and the backup sub-step of step 5, no longer occur: Phase 16 removed the wrapper's backup gate, its protect-list re-mark and its ii-hook enable, and the wrapper now passes `--skip-backup` so upstream's `auto_backup_configs` is suppressed by default. On a present-day install, upstream's greeting is the first and only pause — nothing prompts before files are touched unless you pass `--keep-backup`.

1. **Wrapper preflight and backup gate.** The gate asked for confirmation before anything touched files; the answer was `yes`. *(Retired in Phase 16 — no wrapper-owned prompt stands in front of an install today.)*
2. **Greeting.** Answer `y`. Not `n`, not `yesforall` (section 4).
3. **Dependencies.** A `pacman -Syu` runs here and may pull a new kernel. Let it finish.
4. **Setups.** Upstream's per-component setup steps.
5. **Files stage,** in this order: backup → misc → quickshell → fish → fontconfig → **hypr**. *(The backup sub-step is skipped today unless `--keep-backup` is passed.)*

   Inside the hypr block, specifically:
   - the `~/.config/hypr/hyprland/` tree is replaced wholesale;
   - `~/.config/hypr/hyprland.conf` is **renamed** to `hyprland.conf.old` — it is not deleted, and the rollback tier documented at the time restored from it (the tiers were withdrawn in Phase 16);
   - `hyprlock.conf` and `hypridle.conf` get `.new` sidecars written alongside them rather than being replaced (this is what `installed_true` buys you);
   - `hyprland.lua` is installed — this is ADOPT-02;
   - `custom/` is seeded, and only because live had no `custom/` at the time of this window. Section 8 then overwrites the three files you own.
6. **Wrapper post-install:** the protect-list re-mark and the ii hook enable. *(Both removed in Phase 16 — nothing runs after the upstream exec today.)*

### If it dies partway

Capture the output. **Do not hand-patch. Do not roll back.** Re-run the identical command:

```bash
./arch/dots-hyprland.sh install --full
```

The install is written to be re-runnable. A hand-patched half-state is not something section 14 knows how to recover.

---

## 8. Apply the Phase 13 overlay (D-08)

Do this **before** you relog. The overlay is what makes your monitors and workspaces come back.

The apply command is authoritative in [`13-SOT-APPLY.md`](../.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md) under **§"Apply command (D-18)"**. Run the fence exactly as written there. It is not restated here on purpose — it is version-controlled and D-19-verified, and a second copy would rot.

Then run the post-apply sanity gate:

```bash
luac -p ~/.config/hypr/custom/*.lua
# expect: no output (all overlay files parse)
```

**The one thing that must never happen:** the apply stays a named-file copy of `general.lua`, `env.lua`, and `execs.lua`. It never becomes a delete-sync. Upstream's seed also lands `keybinds.lua`, `rules.lua`, `variables.lua`, and a wallpaper-restore script that ii's own startup references — deleting those breaks ii, not just your overlay.

---

## 9. Re-stow kitty (D-17)

```bash
# run from the repo root; matches arch/kitty.sh:10
cd stow && stow -R -v=5 -t ~ kitty
```

Packages live under `stow/`, and the target must be `-t ~`. A bare `stow -R kitty`
from the repo root finds no package and would target the repo's parent directory.

This is the one named exception to Phase 11 D-28's accept-upstream default. Upstream's kitty sync replaces the stow symlink with its own real file and adds two kitten scripts. Your repo file is never touched, so a re-stow restores the personal config and the upstream kitten scripts sit inert alongside it.

**The deliberate asymmetry:** `starship.toml` is *not* protected this way. It is a symlink into the repo, upstream's copy follows it, and your repo copy is overwritten in place. That is an accepted loss (D-17). Fish stays accept-upstream too — do not re-stow it.

---

## 10. Reboot (D-10)

```bash
sudo reboot
```

Unconditional, whether or not a kernel landed in step 3 of section 7. Do not try to shortcut it with a relogin.

---

## 11. Log in at a TTY and start the session (D-16)

Log in at the TTY, then:

```bash
start-hyprland
```

This machine has **no display manager**. Upstream's closing warning about session-picker entries and "do not select UWSM" does not apply here — there is no picker. `/usr/bin/start-hyprland` is how the session comes up, exactly as it did before the adopt.

---

## 12. Verify (plan 14-02)

```bash
./scripts/phase14-verify.sh
```

Record the results per plan 14-02. Then `exit` the `script` shell from section 2 to close the transcript.

**Before you run it:** if you want the dual-head half of the check exercised, have HDMI-A-2 connected and powered. It was attached when the pre-adopt baseline was captured, and `14-PRE-ADOPT-BASELINE.txt` records its pre-adopt geometry for comparison. If it is disconnected at verify time the script degrades to a single-head run and prints an informational line rather than a failure — but you will not have proven the dual-head half.

---

## 13. Known losses (D-38)

Two lists. Read both before you file anything as a bug. Most of what looks missing on first login is in the first list.

### Replaced by ii — not losses

- **The polkit authentication agent.** Quickshell provides one.
- **Clipboard history, text and image.** ii carries its own.
- **Wallpaper.** Quickshell owns it now.
- **Cursor theme.**
- **The Qt platform theme.** `QT_QPA_PLATFORMTHEME` moves to `kde`.

### Actually lost, and accepted

- **The personal `hyprland-session.service` autostart.** The unit file itself **survives** — it lives under `stow/systemd/` and the symlink in `~/.config/systemd/user/` is untouched. Only the `exec-once` line that started it dies with the renamed conf. Consequence: screen share may stop working. That is a **recorded finding for Phase 15, not a blocker for this window**, and the fix is one `systemctl --user start` or one line in `custom/execs.lua`.
- **`wl-clip-persist`.** Its autostart goes with the same conf.
- **The four workspace-pinned autostarts** — `google-chrome-stable` on workspace 1, `kitty -e tmux` on workspace 1, `btop` on its special workspace, and `discord` on `special:social`. The apps are all still installed; only the pinned launch-at-login behaviour goes.
- **`hyprpaper` becomes stopped-but-installed.** Its autostart shared a single `exec-once` line with the bar stack, so it dies with them. The package and `~/.config/hypr/hyprpaper.conf` both survive untouched — nothing starts it, that is all.
- **`~/.config/hypr/hyprland/scripts/launch_first_available.sh`** is deleted from live by the hypr tree sync. It is already tracked byte-identically in this repo at `.config/hypr/hyprland/scripts/launch_first_available.sh`, so nothing is actually gone.

The bar stack on this machine is `Waybar/rofi/swaync`. Its autostart line goes away with the renamed conf and the packages stay installed. Note that the launcher in that stack has **no autostart at all** — it was never a daemon. Only its keybinds go away with the renamed conf, and ii ships its own launcher to replace them.

---

## 14. Rollback (ADOPT-04, D-23, D-24)

Recovery from a bad install is a clean reinstall from the pinned submodule at `vendor/dots-hyprland`. The pin is fixed in the parent repository, so a reinstall is reproducible rather than a fetch of whatever upstream looks like today. Fix whatever was wrong — the pin, an overlay, a disposition you would decide differently — and re-run the install command from [§4 of the playbook](./dots-hyprland-workflow.md).

The wrapper never calls upstream's own removal subcommand. A bad install is never "undone" by handing the vendor tree a cascade it will take too far. The wrapper's own removal path exists: it gates with its own exact-token confirmation, removes the `illogical-impulse-*` packages without a cascading dependency sweep, and removes ii-owned configs and state. If a recovery instruction you find anywhere tells you to invoke removal through the vendor tree directly, it is wrong for this repo.

Nothing is preserved on install. The wrapper takes no snapshot on the way in, so there is no saved copy of the state you are replacing and no undo. A pre-adopt snapshot from 2026-09-04 does still sit on disk at `~/ii-original-dots-backup` and `~/ii-original-dots-backup.20260904T171128Z`. Both are left exactly where they are, untouched, and are no longer presented as a documented recovery route — nothing produces one on a fresh install, and nothing verifies that these are still intact.

For the canonical operator document covering install, update and recovery, see [`docs/dots-hyprland-workflow.md`](./dots-hyprland-workflow.md).

---

## See also

- [`docs/dots-hyprland-workflow.md`](./dots-hyprland-workflow.md) — canonical install/adopt playbook
- [`.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md`](../.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md) — overlay source of truth and the authoritative apply command
- [`.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md`](../.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md) — per-item adopt dispositions
