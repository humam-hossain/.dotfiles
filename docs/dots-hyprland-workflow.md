# dots-hyprland workflow (illogical-impulse)

Canonical operator playbook for adopting **end-4/dots-hyprland** (illogical-impulse / `ii`) inside this `.dotfiles` repo.

## Purpose

After Phases 5–8 there is a **single product path**:

- **Fork + pin:** personal fork of end-4/dots-hyprland, submodule at `vendor/dots-hyprland`
- **Install entry:** only `arch/dots-hyprland.sh` (thin wrapper around vendor `./setup`)
- **Live product:** real directory tree under `~/.config/quickshell` (not a symlink into the repo)
- **Retired:** in-repo `.config/quickshell` product tree and `arch/quickshell.sh` (hard-deleted in Phase 8)

This playbook is the Install/Adopt source of truth so a cold machine can reach a working session without tribal knowledge. It covers two install profiles — the wrapper's **safe** default and the opt-in **full** profile — defined side by side in `Profiles: safe vs full` below.

**Note — state of this machine:** the machine this repo was written on already took the full adopt on 2026-09-04, so its live session is the full-profile one. `docs/phase14-adopt-runbook.md` is the record of that adopt window and is not a prerequisite for reading the rest of this document.

> **Flag / subcommand details:** keep DRY — run `./arch/dots-hyprland.sh help` for the full allowlist, safe defaults, backup gate, uninstall, and protect behavior. This doc does not re-copy the entire help text.
> It names only the flags whose consequences you must weigh when choosing a profile — the three safe-default axes, `--full`, and the backup pair; `./arch/dots-hyprland.sh help` remains the syntax source of truth.

## Prerequisites

- **Arch Linux** primary target (Debian/Ubuntu parity is out of scope)
- `git` with **SSH access to GitHub** (clone origin + submodule fork URL)
- **AUR helper** as required by upstream setup (typically `yay`)
- **Hyprland** session — required to run the post-install checks in this document; whether your personal `hyprland.conf` survives the install depends on which profile you run (stated per axis in `Profiles: safe vs full`)
- Working directory awareness: commands below assume **REPO_ROOT** of this `.dotfiles` clone unless noted

## Profiles: safe vs full

The wrapper ships two install profiles on one spine. Which one you run decides what the install is allowed to do to the `~/.config` you already have, so choose here before you reach the install step.

### Safe — the wrapper default

On `install` and `install-files` the wrapper injects a residual flag triple for you, defined at `arch/dots-hyprland.sh:12` and quoted here byte-for-byte:

```text
--core --skip-hyprland --skip-sysupdate
```

That injection applies to `install` and `install-files` only. In the wrapper's own words: "Safe defaults (injected for install and install-files only — unless `--full`) … `install-deps` / `install-setups` get no injection."

What safe does **not** touch: your personal `hyprland.conf` is neither renamed nor replaced, the misc overlay is not applied, and no unattended full system upgrade runs.

Under safe, `Waybar`, `rofi` and `swaync` keep running alongside `qs -c ii`. That dual-run is a property of this profile and of no other — it is not a milestone goal. The two conf-hook lines the safe profile relies on to start `qs -c ii` are documented in the session model section.

### Full — opt-in, `--full`

`--full` is wrapper-owned meta and is valid only on `install` and `install-files`; the wrapper refuses it on any other subcommand and exits non-zero (`arch/dots-hyprland.sh:1420-1424`). On the paths where it is valid it drops all three residuals at once — nothing from the triple is injected.

**The wrapper default is still safe, and `--full` is opt-in.** The wrapper's help says it plainly: "Default install / install-files without `--full` still inject the triple." The walkthrough later in this document walks the full profile end to end because that is the path this machine took and the one that needs a written record — that is a documentation choice, not a change of default.

Under full, `Waybar`, `rofi` and `swaync` are replaced by `qs -c ii`. That removal was explicitly accepted by Phase 11 D-11 in `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` section 6 — an accepted disposition, not an out-of-scope item — and the prior trees stay archived in the repo under `stow/` per its D-12 archive policy.

### Flag axes

| Axis | Injected (safe default) | Dropped (`--full`) |
|------|-------------------------|--------------------|
| `--skip-hyprland` | Personal `hyprland.conf` is neither renamed nor replaced; the skip is **full**, not entry-only | Upstream renames `hyprland.conf` to `.old`, syncs the ii `hypr/hyprland` Lua tree, installs `hyprland.lua`, and writes `.new` sidecars for hyprlock and hypridle |
| `--core` | Core install path only; the misc overlay is not applied | The misc overlay may overwrite, and the install also reaches fish, kitty, starship and misc |
| `--skip-sysupdate` | No unattended full system upgrade | `pacman -Syu` may run on the deps portion of `install` |

`./arch/dots-hyprland.sh help` is the syntax source of truth; the table above is narrative about consequences, not a flag reference.

## Canonical path

All dots-hyprland work after pin lives at:

```text
vendor/dots-hyprland
```

Do **not** treat a sibling clone (e.g. `~/github_repo/dots-hyprland`) as source of truth. Phase 5 D-13: only the vendored submodule path is canonical.

## Outline

1. [Clone & recursive submodule init](#1-clone--recursive-submodule-init)
2. [Verify fork remotes & pin](#2-verify-fork-remotes--pin)
3. [Required gate before any full install](#3-required-gate-before-any-full-install)
4. [Install via the thin wrapper](#4-install-via-the-thin-wrapper)
5. [Session model after a full install](#5-session-model-after-a-full-install)
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

## 3. Required gate before any full install

This is a gate, not advice: a cold machine must not reach `--full` from this document without passing it first. ADOPT-01 is a **process** gate — the wrapper does not enforce it at runtime and will not stop you.

1. **Inventory.** Enumerate what a full install would touch on *this* machine — the hypr files that dropping `--skip-hyprland` renames or replaces, the misc surfaces that dropping `--core` may overwrite, and the package and sysupdate effects that dropping `--skip-sysupdate` allows. `.planning/phases/10-full-install-impact-inventory/10-INVENTORY.md` is the source of truth for what a full install touches.
2. **Disposition.** Decide, per surface the inventory named, whether you accept upstream's version, keep yours, or migrate yours into a personal overlay. `.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` is the source of truth for the per-surface decisions.
3. **Adopt.** Only with both in hand, run the full install in §4 — backup gate answered, not skipped.

Those two files are **this machine's worked instance** of the gate: it was run here, against this host's `~/.config`, in Phases 10 and 11. On any other machine they are an example of the artifact you have to produce, not a substitute for producing it — a different host has different collisions and therefore different dispositions.

The safe profile does not require this gate. It injects the residual triple precisely so the install cannot reach the surfaces the inventory exists to enumerate, which is what makes the gate specifically a **full**-profile precondition.

---

## 4. Install via the thin wrapper

**Only install entry:** `./arch/dots-hyprland.sh` (thin wrapper around vendor `./setup`). Full flag/subcommand details: `./arch/dots-hyprland.sh help`.

### Preflight

Missing or incomplete submodule → wrapper prints the recursive init fix and exits. It does **not** auto-init.

### Dry-run first

```bash
./arch/dots-hyprland.sh install --dry-run
```

Dry-run argv for `install` / `install-files` must show safe defaults:

```text
--core --skip-hyprland --skip-sysupdate
```

- `--core` — core install path (not full experimental surface)
- `--skip-hyprland` — **full** skip so personal `hyprland.conf` is not renamed/replaced
- `--skip-sysupdate` — no unattended full system upgrade

`--force` is **never** auto-injected.

### Live install (first adoption)

```bash
./arch/dots-hyprland.sh install
```

At the **backup gate**, type `yes` (interactive confirmation). Upstream backup directory:

```text
~/ii-original-dots-backup
```

**Do not** pass bare `--skip-backup` on first adoption. Bare `--skip-backup` is refused unless you also pass `--allow-skip-backup` (intentional override only).

### Allowlisted subcommands (summary)

| Subcommand | Role |
|------------|------|
| `install` | Full pipeline (deps + setups + files) + safe defaults + backup gate |
| `install-deps` | Dependencies only |
| `install-setups` | Setup steps only |
| `install-files` | Files only + safe defaults + backup gate |
| `uninstall` | Safe dual-run uninstall (wrapper-owned; not upstream cascade) |
| `protect` | Re-mark personal dual-run packages explicit; optional reinstall missing |

Experimental paths such as `exp-merge` / `exp-update` are **refused** by the wrapper. See [§11 Non-goals](#11-non-goals--non-primary-paths) (plan 09-02).

### Hooks after successful install

A successful `install` (and related success paths) runs wrapper `enable_hypr_ii_hooks`, which enables the two ii hook lines in whichever of its two target files exist — the live `~/.config/hypr/hyprland.conf` and the repo `.config/hypr/hyprland.conf`. After a full adopt only the repo copy remains a target, because upstream renamed the live `hyprland.conf` to `.old`; §9 covers what that repo copy is for. It uncomments leftover disabled lines and inserts any missing active hooks. `uninstall` **deletes** those lines; **re-install re-enables** them. Do not assume your current session already has hooks active after an uninstall.

---

## 5. Session model after a full install

### Personal hypr hooks (two lines)

```text
env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv
exec-once = qs -c ii
```

These belong in personal `~/.config/hypr/hyprland.conf` (wrapper injects/enables on successful install in live + repo; deletes them on uninstall).

### Live product path

`~/.config/quickshell` must be a **real directory** (not a symlink into this repo). Expect `ii/shell.qml` under it:

```bash
test ! -L ~/.config/quickshell && test -d ~/.config/quickshell
test -f ~/.config/quickshell/ii/shell.qml
test -d ~/.local/state/quickshell/.venv
```

### Verify the session after login

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

`scripts/phase14-verify.sh` is the executable source of truth for every check in the block above; the individual commands are the hand version of what it asserts. If any of them fails, go to `docs/phase14-adopt-runbook.md` §14.

### Mid-session reload

After install or hook changes:

```bash
hyprctl reload
# restart qs if needed, or full re-login
```

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

Same safe defaults and backup gate as first adoption. Prefer dry-run when unsure:

```bash
./arch/dots-hyprland.sh install-files --dry-run
# or full pipeline if deps/setups changed:
# ./arch/dots-hyprland.sh install --dry-run

./arch/dots-hyprland.sh install-files
# or: ./arch/dots-hyprland.sh install
# or: ./arch/dots-hyprland.sh install-deps   # when only packages changed
```

- Type `yes` at the backup gate when prompted
- Do **not** casually pass bare `--skip-backup`
- Safe defaults (`--core --skip-hyprland --skip-sysupdate`) still apply on `install` / `install-files`

### 10.4 Optional: protect after deps demotion

ii install may demote shared packages to `--asdeps`. After deps-heavy updates:

```bash
./arch/dots-hyprland.sh protect
# optional: ./arch/dots-hyprland.sh protect --install-missing
```

Details: `./arch/dots-hyprland.sh help`.

---

## 11. Non-goals / non-primary paths

These are **out of scope** or **non-primary** for the managed `.dotfiles` workflow (aligned with `.planning/REQUIREMENTS.md` Out of Scope). Do not treat them as the default update or adopt path.

| Path / idea | Status | Why |
|-------------|--------|-----|
| **`exp-merge` / `exp-update`** | **Non-primary / experimental** | Not the update contract. Wrapper **refuses** them: `./arch/dots-hyprland.sh exp-merge` → non-allowlisted `[FAIL]`. If you truly need upstream experimental tools, run `vendor/dots-hyprland/./setup` **directly** and own the risk — still not documented default. |
| **Online cache / curl install into `~/.cache/dots-hyprland`** | **Non-primary / not managed** | Bypasses parent submodule pin and fork ownership. Not the `.dotfiles` adoption path. |
| **Auto-bump submodule on every parent pull** | Out of scope | Breaks pin reproducibility; parent gitlink bumps are explicit. |
| **Waybar / rofi / swaync custom module ports** | Deferred (CUST-01..03) | Not out of scope, and not the same thing as the cutover: the removal of `Waybar`, `rofi` and `swaync` under the full profile was explicitly accepted by Phase 11 D-11 (`.planning/phases/11-disposition-decisions/11-DISPOSITIONS.md` section 6). Only the module *ports* remain deferred. |
| **Full hyprland.lua / ii hypr tree takeover** | Out of scope this milestone | Personal hypr conf remains SoT via `--skip-hyprland`. |
| **Reimplementing package lists in `arch/` without `./setup`** | Forbidden | Single product path is wrapper → vendor setup. |
| **Wrapper `verify` subcommand** | Future (POLISH-01) | Not required for DOC-01/02; use the session checks in §5. |

**Bottom line:** update with **§10 pin-bump**, not exp-merge or online cache install.

---

## See also

- `./arch/dots-hyprland.sh help` — flag and subcommand source of truth
- `vendor/dots-hyprland` — canonical pin path (submodule)
- [`.planning/PROJECT.md`](../.planning/PROJECT.md) — product goals, non-goals, milestone checklist
- [`.planning/REQUIREMENTS.md`](../.planning/REQUIREMENTS.md) — DOC-01 / DOC-02 and Out of Scope
- [`.planning/ROADMAP.md`](../.planning/ROADMAP.md) — Phase 9 success criteria
- Root [`README.md`](../README.md) — cold-clone discovery pointer
