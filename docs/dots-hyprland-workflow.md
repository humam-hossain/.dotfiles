# dots-hyprland workflow (illogical-impulse)

Canonical operator playbook for adopting **end-4/dots-hyprland** (illogical-impulse / `ii`) inside this `.dotfiles` repo.

## Purpose

After Phases 5–8 there is a **single product path**:

- **Fork + pin:** personal fork of end-4/dots-hyprland, submodule at `vendor/dots-hyprland`
- **Install entry:** only `arch/dots-hyprland.sh` (thin wrapper around vendor `./setup`)
- **Live product:** real directory tree under `~/.config/quickshell` (not a symlink into the repo)
- **Retired:** in-repo `.config/quickshell` product tree and `arch/quickshell.sh` (hard-deleted in Phase 8)

This playbook is the install and adopt source of truth for the **full ii session**, so a cold machine can reach a working session without tribal knowledge. There is one install path and it is the full one: a bare `install` takes the whole ii session, and no flag on this wrapper makes it take less.

**Note — state of this machine:** the machine this repo was written on already took the full adopt on 2026-09-04, so its live session is exactly the one this document describes. `docs/phase14-adopt-runbook.md` is the record of that adopt window and is not a prerequisite for reading the rest of this document.

> **Flag / subcommand details:** keep DRY — run `./arch/dots-hyprland.sh help` for the allowlisted subcommands, the two wrapper-owned meta flags and the uninstall flags. This doc does not re-copy the help text; it names only the consequences you have to weigh before you run the thing.
> **Adopt-window history:** `docs/phase14-adopt-runbook.md` is the narrative record of the 2026-09-04 adopt on this machine — what was run, in what order, and what it produced.

## Prerequisites

- **Arch Linux** primary target (Debian/Ubuntu parity is out of scope)
- `git` with **SSH access to GitHub** (clone origin + submodule fork URL)
- **AUR helper** as required by upstream setup (typically `yay`)
- **Hyprland** session — required to run the post-install checks in this document. The install renames your personal `hyprland.conf` to `.old` and enters the session through `hyprland.lua` instead; §5 is the session model that results
- Working directory awareness: commands below assume **REPO_ROOT** of this `.dotfiles` clone unless noted

## Canonical path

All dots-hyprland work after pin lives at:

```text
vendor/dots-hyprland
```

Do **not** treat a sibling clone (e.g. `~/github_repo/dots-hyprland`) as source of truth. Phase 5 D-13: only the vendored submodule path is canonical.

## Outline

1. [Clone & recursive submodule init](#1-clone--recursive-submodule-init)
2. [Verify fork remotes & pin](#2-verify-fork-remotes--pin)
3. [Required gate before installing](#3-required-gate-before-installing)
4. [Install via the thin wrapper](#4-install-via-the-thin-wrapper)
5. [Session model after installing](#5-session-model-after-installing)
6. [Personal overlays: repo, live, fork](#6-personal-overlays-repo-live-fork)
7. [Verify after login](#7-verify-after-login)
8. [Known losses after the full adopt](#8-known-losses-after-the-full-adopt)
9. [Three roles of the repo hyprland.conf](#9-three-roles-of-the-repo-hyprlandconf)
10. [Update contract (pin-bump)](#10-update-contract-pin-bump)
11. [Non-goals / non-primary paths](#11-non-goals--non-primary-paths)

---

## 1. Clone & recursive submodule init

Phase 5 does **not** ship a custom bootstrap script — use stock git only.

### Fresh clone (preferred)

```bash
# From a machine with git + SSH to GitHub
git clone --recurse-submodules git@github.com:humam-hossain/.dotfiles.git
cd .dotfiles
```

Confirm origin matches your fork remote if you use a different URL:

```bash
git remote -v
```

### Repair path (cloned without recurse)

From **REPO_ROOT**:

```bash
git submodule update --init --recursive
```

### Why `--recursive` matters

`vendor/dots-hyprland` has nested submodules (e.g. shapes / rounded-polygon). Omitting `--recursive` / `--recurse-submodules` leaves them empty and breaks QML widgets (OWN-03). There is no Phase 5 auto-init helper — the wrapper **preflight** only prints the fix command; it never runs submodule init for you.

### Presence check

```bash
git submodule status
# expect a line for vendor/dots-hyprland with a SHA (not a leading '-')

# Nested shapes should exist under the pin (path may vary slightly by pin):
ls vendor/dots-hyprland/sdata 2>/dev/null || ls vendor/dots-hyprland 2>/dev/null | head
```

Canonical work path remains **`vendor/dots-hyprland` only** (Phase 5 D-13). Do not develop against a sibling checkout as source of truth.

---

## 2. Verify fork remotes & pin

Parent records the pin as a **gitlink** SHA in the parent repo (no `branch =` auto-track in `.gitmodules`). Explicit pin = reproducibility.

```bash
git submodule status vendor/dots-hyprland

git -C vendor/dots-hyprland remote -v
# expect:
#   origin   → personal fork (e.g. git@github.com:humam-hossain/dots-hyprland.git)
#   upstream → end-4 (https://github.com/end-4/dots-hyprland.git)
```

If `upstream` is missing, add it once:

```bash
git -C vendor/dots-hyprland remote add upstream https://github.com/end-4/dots-hyprland.git
```

---

## 3. Required gate before installing

This is a gate, not advice: a cold machine must not reach the install in §4 from this document without passing it first. ADOPT-01 is a **process** gate — the wrapper does not enforce it at runtime and will not stop you.

1. **Inventory.** Enumerate what the install would touch on *this* machine — the hypr files it renames or replaces, the misc surfaces it may overwrite, and the package and system-upgrade effects it allows. `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` is the source of truth for what the install touches.
2. **Disposition.** Decide, per surface the inventory named, whether you accept upstream's version, keep yours, or migrate yours into a personal overlay. `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` is the source of truth for the per-surface decisions.
3. **Adopt.** Only with both in hand, run the install in §4.

Those two files are **this machine's worked instance** of the gate: it was run here, against this host's `~/.config`, in Phases 10 and 11. On any other machine they are an example of the artifact you have to produce, not a substitute for producing it — a different host has different collisions and therefore different dispositions.

This gate is the only thing between you and an unreviewed overwrite. The wrapper takes no snapshot on the way in (§4), so there is nothing to fall back on if you skip the gate and dislike the result.

---

## 4. Install via the thin wrapper

**Only install entry:** `./arch/dots-hyprland.sh` (thin wrapper around vendor `./setup`). Full flag/subcommand details: `./arch/dots-hyprland.sh help`.

### Preflight

Missing or incomplete submodule → wrapper prints the recursive init fix and exits. It does **not** auto-init.

### Dry-run first

```bash
./arch/dots-hyprland.sh install --dry-run
# expect:
#   [INSTALL] ./setup install --skip-backup  (cwd=REPO_ROOT/vendor/dots-hyprland)
#   [CONFIG] dry-run: would exec from REPO_ROOT/vendor/dots-hyprland: ./setup install --skip-backup
```

The would-exec line is the whole contract: it is the exact argv the wrapper will hand to upstream, built as an array and never as a string. It carries no profile flag, because there is no profile to choose.

`--skip-backup` on that argv is the wrapper's own addition, and it is scoped: `install` and `install-files` get it because upstream reads it on the files step, and `install-deps` / `install-setups` do not, because there it could not mean anything. `./arch/dots-hyprland.sh install-setups --dry-run` shows a bare argv, which is the crisp way to see the scope.

`--force` is **never** auto-injected, and neither is `--skip-allgreeting`.

### No snapshot, and no undo

The wrapper asks nothing and copies nothing aside before an install. With the backup-suppression flag on the argv, files are replaced in place: there is no wrapper-made snapshot and no undo. Recovery after a bad install is covered in §9.

That is the default, not a law. `--keep-backup` is a wrapper-owned meta flag: it is stripped from the argv like `--dry-run` and `--full`, and its only effect is that the wrapper does *not* add `--skip-backup`, so upstream's own `auto_backup_configs` runs for that invocation. `./arch/dots-hyprland.sh install --keep-backup --dry-run` shows the argv without the flag. It is meaningful on `install` and `install-files` only; on the other two the wrapper says so and carries on.

**The install is still interactive.** The wrapper prompts for nothing — but upstream still runs its own greeting and pauses at least once on `(Ctrl-C to abort, Enter to proceed)` unless it is force-run, and this wrapper never force-runs it. Expect to answer, and do not walk away from a terminal you started an install in.

### The install

```bash
./arch/dots-hyprland.sh install
# expect: upstream's greeting, at least one Enter-to-proceed pause, then the real install
```

What the install is allowed to do to this machine:

- Your personal `hyprland.conf` may be renamed to `.old` by the upstream install, which is what moves the session onto the Lua entry (§5).
- The misc overlay may overwrite: the install is not restricted to the core path.
- `pacman -Syu` may run on the deps portion of `install`.
- Nothing is copied aside first, and the wrapper offers no undo.

If you have not worked §3's inventory → disposition gate against *this* host's `~/.config`, stop and do that first — ADOPT-01 is process discipline and the wrapper will not stop you. When the install finishes, reboot or log back in, then run §7.

### Allowlisted subcommands (summary)

| Subcommand | Role |
|------------|------|
| `install` | Full upstream pipeline (deps + setups + files); forwards the upstream backup-suppression flag |
| `install-deps` | Dependencies only |
| `install-setups` | Setup steps only |
| `install-files` | File install only; forwards the upstream backup-suppression flag |
| `uninstall` | Safe removal — wrapper-owned, exact-token confirmation, `pacman -R` on the `illogical-impulse-*` meta packages with **no** dependency cascade, plus ii-owned configs and state |

Experimental paths such as `exp-merge` / `exp-update` are **refused** by the wrapper. See [§11 Non-goals](#11-non-goals--non-primary-paths) (plan 09-02).

### Who owns the session hooks

After the adopt, **ii owns them.** The environment hook that sets `ILLOGICAL_IMPULSE_VIRTUAL_ENV` lives in ii's own Lua tree at `hyprland/env.lua`, and the shell-launch hook that starts `qs -c ii` lives at `hyprland/execs.lua` — under `~/.config/hypr/` on the live machine. The wrapper neither writes, enables nor deletes them; it carries no hook machinery at all, and `uninstall` reaches them only as part of the ii-owned config tree it removes.

The repo copy `.config/hypr/hyprland.conf` still carries those two lines, as a dead archive. Nothing loads it; §9 is what that file is.

---

## 5. Session model after installing

After the install the session is entered through Lua, not through a conf. `~/.config/hypr/hyprland.lua` is the entry upstream installs, and `configProvider` reports `lua` — where the value recorded on this machine before the adopt was `hyprlang`, kept as `configProvider_pre=hyprlang` in `.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt`. Your previous `~/.config/hypr/hyprland.conf` is not deleted: upstream renames it to `hyprland.conf.old`, and §9 covers the roles the repo copy of that file still plays beyond archival. Personal overlays keep living under `~/.config/hypr/custom/`; §6 is the policy for what belongs there and which direction it flows.

The paths that make up the session model:

```text
~/.config/hypr/hyprland.lua        session entry installed by upstream
~/.config/hypr/hyprland.conf.old   your pre-adopt conf, renamed rather than deleted
~/.config/hypr/custom/             personal overlays (policy in §6)
~/.config/quickshell/ii/           the live ii product tree
```

`Waybar`, `rofi` and `swaync` are not part of this session at all; `qs -c ii` replaces them, which is the accepted Phase 11 D-11 outcome rather than an oversight, and §8 lists what that costs.

### Live product path

`~/.config/quickshell` must be a **real directory** (not a symlink into this repo). Expect `ii/shell.qml` under it:

```bash
test ! -L ~/.config/quickshell && test -d ~/.config/quickshell
test -f ~/.config/quickshell/ii/shell.qml
test -d ~/.local/state/quickshell/.venv
```

### Mid-session reload

After an install or an overlay apply:

```bash
hyprctl reload
# restart qs if needed, or full re-login
```
---

## 6. Personal overlays: repo, live, fork

Personal machine layout — monitors, workspace pins, and whatever else stock ii cannot know about your hardware — lives in `hypr/custom` overlays. Three locations are involved and they hold three different roles. `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` is the source of truth for the full policy; this section is the operator's summary of it.

**Repo `.config/hypr/custom/` is the authoring source of truth.** It is the place you edit, and the version that survives a reinstall and reproduces on the next machine.

**Live `~/.config/hypr/custom/` is an applied copy, not an editing surface.** A tweak made there is real for this session and gone at the next apply. Persist it by copying it back into the repo.

**`vendor/dots-hyprland` and the personal fork are product source of truth only.** Machine overlays are never committed into either — mixing the two would couple pin-bumps to this host's layout.

### Direction

Apply is **one-way, repo to live**, run after the full files install. There is no sync daemon and no reverse sync; copy-back into the repo is a manual step you take deliberately.

### Named files only

The apply copies `general.lua`, `env.lua` and `execs.lua` by name with `cp -a`, overwriting the ii seeds of those names where present. It never uses a mirroring delete, and it never touches `keybinds.lua`, `rules.lua` or `variables.lua`. Run from **REPO_ROOT** after the files install:

```bash
set -euo pipefail
REPO_CUSTOM=".config/hypr/custom"
LIVE_CUSTOM="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom"

mkdir -p "$LIVE_CUSTOM"

# Fail if repo general.lua is missing (layout required).
if [ ! -f "$REPO_CUSTOM/general.lua" ]; then
  echo "FAIL: repo $REPO_CUSTOM/general.lua is missing; abort apply" >&2
  exit 1
fi
cp -a "$REPO_CUSTOM/general.lua" "$LIVE_CUSTOM/"

for slot in env.lua execs.lua; do
  if [ -f "$REPO_CUSTOM/$slot" ]; then
    cp -a "$REPO_CUSTOM/$slot" "$LIVE_CUSTOM/"
  else
    echo "WARN: repo $REPO_CUSTOM/$slot missing; continuing without it" >&2
  fi
done
```

That is the operator copy of the authoritative apply recorded in `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md`; if the two ever disagree, the source of truth wins.

The named-files rule is why live `custom/` legitimately holds **more** files than the repo does. Upstream seeds `keybinds.lua`, `rules.lua`, `variables.lua` and a `scripts/` directory there, and the apply deliberately leaves every one of them alone. A live directory with extra files in it is the expected state, not drift.

### Failure modes

The apply **aborts** when repo `general.lua` is missing: the layout it carries is required, and continuing without it would hand you a session with the wrong monitor setup and no error. `env.lua` and `execs.lua` are optional slots — if either is absent the apply warns and continues.

After apply, reload Hyprland or log back in before expecting the overlay to take effect.

### Verifying the fence

`scripts/phase13-d19-assert.sh` is the executable that runs the in-repo verify for this policy: repo layout, the seeds the apply must never have copied, and the fork boundary that keeps machine overlays out of `vendor/dots-hyprland`. Its checks are extracted from `.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md` rather than restated there, so prose and check cannot drift. Run it from **REPO_ROOT**:

```bash
./scripts/phase13-d19-assert.sh
# expect: exit 0, and no [FAIL] lines
```

---

## 7. Verify after login

Run these **after login**, not before: the first three need an active Hyprland session, which is why the runbook orders its verify section after its log-in section.

```bash
# 1. The compositor is on the Lua entry
hyprctl -j status | jq -r .configProvider
# expect: lua
# note: 14-PRE-ADOPT-BASELINE.txt recorded configProvider_pre=hyprlang before the adopt

# 2. Token-independent confirmation the Lua config manager is live
hyprctl eval 'return 1+1'
# expect: ok

# 3. The ii shell is running
pgrep -f 'qs -c ii' >/dev/null && echo "qs -c ii running"
# expect: qs -c ii running

# 4. Upstream renamed the previous conf; no .conf can win over the Lua entry
test -f ~/.config/hypr/hyprland.lua      && echo "lua entry present"
test -f ~/.config/hypr/hyprland.conf.old && echo "pre-adopt conf archived"
test ! -f ~/.config/hypr/hyprland.conf   && echo "no competing hyprland.conf"
# expect: all three echo lines

# 5. Personal overlays applied
ls ~/.config/hypr/custom/{general,env,execs}.lua
# expect: general.lua, env.lua, execs.lua all listed

# 6. Full check — the executable source of truth for everything above
./scripts/phase14-verify.sh
# expect: === done: FAIL=0 FINDINGS=1 ===   (the 1 finding is the D-38 known loss)
```

`scripts/phase14-verify.sh` is the executable source of truth for every check in the block above; the individual commands are the hand version of what it asserts. Observed on a committed tree after the Phase 16 script edits: **33 `[PASS]`, 0 `[FAIL]`, one `[FINDING]`** — the known loss in §8. Two caveats on running it: it asserts a clean working tree, so commit first; and it is the *whole* check, not a rollback trigger. If something is wrong, §9 has the recovery story.

---

## 8. Known losses after the full adopt

These are the surfaces the adopt actually cost this machine. They are an accepted cost under Phase 11 D-11, not a goal of the milestone and not a defect. Read the whole list before filing anything as a bug: each item leads with what **survives**, so the damage is neither over- nor under-estimated.

- **The personal `hyprland-session.service` autostart.** The unit file itself **survives** — it lives under `stow/systemd/` and the symlink in `~/.config/systemd/user/` is untouched. What died with the renamed conf is the `exec-once` line that started it, so `graphical-session.target` is now inactive. Consequence: the xdg-desktop-portal ScreenCast path depends on that target, so screen share **may** stop working. The portal still answers with an unchanged `AvailableSourceTypes`, so what was lost is the session bootstrap, not the portal itself. This is not a deletion.
- **`wl-clip-persist`.** Not running; same cause — its `exec-once` line went with the renamed conf. The binary is still installed.
- **The four workspace-pinned autostarts.** `google-chrome-stable` on workspace 1, `kitty -e tmux` on workspace 1, `btop` on its special workspace, and `discord` on `special:social`. All four applications are still installed; only the pinned launch-at-login behaviour is gone.
- **`hyprpaper`.** Stopped but installed — the binary is on PATH and `~/.config/hypr/hyprpaper.conf` survives untouched; nothing starts it. Wallpaper is Quickshell's job under the ii shell, so this is a changed owner rather than breakage.

This document records these losses and owns no fix — restoring the session bootstrap, `wl-clip-persist` and the four autostarts is **unowned work with no owning phase**, and the sweep record at `.planning/phases/15-playbook-safe-vs-full/15-DOC-SWEEP.md` carries it as a deferred item. `scripts/phase14-verify.sh` reports the session-target loss as a `[FINDING]` rather than a failure, which is why the expected output in §7 is one finding rather than zero.

---

## 9. Three roles of the repo hyprland.conf

The repo's `.config/hypr/hyprland.conf` is not merely an archived copy. It was carrying three separate roles at once. One of them died with the wrapper machinery retired in Phase 16, and the other two are unchanged.

**Role 1 — pre-adopt archive.** This repo's copy of the compositor config as it stood before the adopt, committed before anything mutated, whose sha256 matches the fixture recorded in `.planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt`. `scripts/phase14-verify.sh` still hashes it against that fixture on every run.

**Role 2 — frozen evidence.** It is the record of what this machine's hypr config was before the adopt. That is why it is committed rather than regenerated: a regenerated file would prove nothing about the pre-adopt state.

**Role 3 — retired.** This file used to be the wrapper's hook-injection target: the wrapper enabled the two ii hook lines in whichever of its candidate files existed, and after the adopt this repo copy was the only one left. Phase 16 deleted that machinery outright. The wrapper now writes nothing here, and `uninstall` no longer strips the two lines from it. They remain in the file as dead archive, and nothing loads the file — the live hooks are ii's own, in `hyprland/env.lua` and `hyprland/execs.lua` (§4).

### Recovery after a bad install

Recovery is a clean reinstall from the pinned submodule: fix whatever was wrong — the pin, the overlay, a disposition you would decide differently — and re-run §4's install. That is the whole route, and it is deliberately the only one.

Two things follow from it. The wrapper never calls upstream's own removal subcommand, so a bad install is never "undone" by handing the vendor tree a cascade it will take too far; `uninstall` here is the wrapper's own narrow removal, described in §4. And nothing is preserved on install — no snapshot is taken on the way in, so there is no saved copy of the state you are replacing.

A pre-adopt snapshot from the 2026-09-04 adopt does still sit on disk at `~/ii-original-dots-backup.20260904T171128Z`. It is left exactly where it is, and it is **no longer presented as a documented recovery route**: nothing produces one on a fresh install, and nothing verifies that this one is still intact. Treat it as a historical artifact of that one adopt window, not as a route back.

---

## 10. Update contract (pin-bump)

**Primary update path** for end-4 changes: work in the fork submodule, push origin, bump the parent gitlink pin, re-run the wrapper. This is intentional reproducibility — **not** auto-bump on every parent pull.

Do not develop against a sibling checkout as SoT; always use `vendor/dots-hyprland`.

### 10.1 Fetch and merge upstream into the fork

```bash
cd vendor/dots-hyprland

# ensure dual remotes (origin=fork, upstream=end-4)
git remote -v
git fetch upstream

# merge or rebase desired upstream ref onto your fork branch; resolve conflicts
# example (adjust branch/ref to match your pin workflow):
#   git merge upstream/main
#   # or: git rebase upstream/main

git push origin HEAD
cd ../..
```

### 10.2 Bump parent pin (gitlink)

From **REPO_ROOT**:

```bash
git add vendor/dots-hyprland   # stage new submodule SHA (gitlink)
git status                     # confirm only the pin change (unless you have other work)
git commit -m "chore(vendor): bump dots-hyprland pin"
```

Parent records the pin as an explicit gitlink — clones get that SHA until you bump again.

### 10.3 Apply on the machine (re-run setup)

One command applies a bumped pin. Preview it first if you are unsure what changed:

```bash
./arch/dots-hyprland.sh install-files --dry-run
# or full pipeline if deps/setups changed:
# ./arch/dots-hyprland.sh install --dry-run

./arch/dots-hyprland.sh install-files
# or: ./arch/dots-hyprland.sh install
# or: ./arch/dots-hyprland.sh install-deps   # when only packages changed
```

A re-apply is the same install as the first one — same behavior, same absence of an undo (§4). Upstream still greets and pauses, so run it somewhere you can answer it.

---

## 11. Non-goals / non-primary paths

These are **out of scope** or **non-primary** for the managed `.dotfiles` workflow (aligned with `.planning/REQUIREMENTS.md` Out of Scope). Do not treat them as the default update or adopt path.

| Path / idea | Status | Why |
|-------------|--------|-----|
| **`exp-merge` / `exp-update`** | **Non-primary / experimental** | Not the update contract. Wrapper **refuses** them: `./arch/dots-hyprland.sh exp-merge` → non-allowlisted `[FAIL]`. If you truly need upstream experimental tools, run `vendor/dots-hyprland/./setup` **directly** and own the risk — still not documented default. |
| **Online cache / curl install into `~/.cache/dots-hyprland`** | **Non-primary / not managed** | Bypasses parent submodule pin and fork ownership. Not the `.dotfiles` adoption path. |
| **Auto-bump submodule on every parent pull** | Out of scope | Breaks pin reproducibility; parent gitlink bumps are explicit. |
| **Waybar / rofi / swaync custom module ports** | Cutover **done** (Phase 11 D-11); only the ports are deferred (CUST-01..03) | Not out of scope, and not the same thing as the cutover: the removal of `Waybar`, `rofi` and `swaync` was explicitly accepted by Phase 11 D-11 (`.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` section 6). Only the module *ports* remain deferred. |
| **Reimplementing package lists in `arch/` without `./setup`** | Forbidden | Single product path is wrapper → vendor setup. |
| **Wrapper `verify` subcommand** | Future (POLISH-01) | Not required for DOC-01..DOC-04; use the post-login checks in §7 and `scripts/phase14-verify.sh`, which is the executable verifier this milestone actually shipped. |

**Bottom line:** update with **§10 pin-bump**, not exp-merge or online cache install.

---

## See also

- `./arch/dots-hyprland.sh help` — flag and subcommand source of truth
- `vendor/dots-hyprland` — canonical pin path (submodule)
- [`docs/phase14-adopt-runbook.md`](./phase14-adopt-runbook.md) — the narrative record of the 2026-09-04 adopt window
- [`.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md`](../.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md) — what the install touches
- [`.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md`](../.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md) — per-item adopt dispositions
- [`.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md`](../.planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md) — overlay source of truth and the authoritative apply command
- [`.planning/PROJECT.md`](../.planning/PROJECT.md) — product goals, non-goals, milestone checklist
- [`.planning/REQUIREMENTS.md`](../.planning/REQUIREMENTS.md) — DOC-03 / DOC-04 and Out of Scope
- [`.planning/ROADMAP.md`](../.planning/ROADMAP.md) — Phase 16 success criteria
- Root [`README.md`](../README.md) — cold-clone discovery pointer
