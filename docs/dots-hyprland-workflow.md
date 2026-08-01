# dots-hyprland workflow (illogical-impulse)

Canonical operator playbook for adopting **end-4/dots-hyprland** (illogical-impulse / `ii`) inside this `.dotfiles` repo.

## Purpose

After Phases 5–8 there is a **single product path**:

- **Fork + pin:** personal fork of end-4/dots-hyprland, submodule at `vendor/dots-hyprland`
- **Install entry:** only `arch/dots-hyprland.sh` (thin wrapper around vendor `./setup`)
- **Live product:** real directory tree under `~/.config/quickshell` (not a symlink into the repo)
- **Retired:** in-repo `.config/quickshell` product tree and `arch/quickshell.sh` (hard-deleted in Phase 8)

This playbook is the Install/Adopt source of truth so a cold machine can reach dual-run (`waybar` + `qs -c ii`) without tribal knowledge.

> **Flag / subcommand details:** keep DRY — run `./arch/dots-hyprland.sh help` for the full allowlist, safe defaults, backup gate, uninstall, and protect behavior. This doc does not re-copy the entire help text.

## Prerequisites

- **Arch Linux** primary target (Debian/Ubuntu parity is out of scope)
- `git` with **SSH access to GitHub** (clone origin + submodule fork URL)
- **AUR helper** as required by upstream setup (typically `yay`)
- **Hyprland** session already running; you own personal `~/.config/hypr` (wrapper defaults **do not** replace `hyprland.conf`)
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
3. [Install via thin wrapper (dry-run → live)](#3-install-via-thin-wrapper-dry-run--live)
4. [Session hooks & dual-run expectations](#4-session-hooks--dual-run-expectations)
5. [Update contract (pin-bump)](#5-update-contract-pin-bump) — *stub; filled in plan 09-02*
6. [Non-goals / non-primary paths](#6-non-goals--non-primary-paths) — *stub; filled in plan 09-02*
7. [See also](#see-also)

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

## 3. Install via thin wrapper (dry-run → live)

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

Experimental paths such as `exp-merge` / `exp-update` are **refused** by the wrapper. See [§6 Non-goals](#6-non-goals--non-primary-paths) (plan 09-02).

### Hooks after successful install

A successful `install` (and related success paths) runs wrapper `enable_hypr_ii_hooks` so personal hypr gets the dual-run lines. `uninstall` comments those lines out; **re-install re-enables** them. Do not assume your current session already has hooks active after an uninstall.

---

## 4. Session hooks & dual-run expectations

### Personal hypr hooks (two lines)

```text
env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,~/.local/state/quickshell/.venv
exec-once = qs -c ii
```

These belong in personal `~/.config/hypr/hyprland.conf` (wrapper injects/enables on successful install; comments them on uninstall).

### Live product path

`~/.config/quickshell` must be a **real directory** (not a symlink into this repo). Expect `ii/shell.qml` under it:

```bash
test ! -L ~/.config/quickshell && test -d ~/.config/quickshell
test -f ~/.config/quickshell/ii/shell.qml
test -d ~/.local/state/quickshell/.venv
```

### Dual-run (intentional this milestone)

- Keep **waybar** (and existing swaync/rofi as you already configure them)
- `qs -c ii` runs alongside — **both bars OK** even if they overlap
- **No Waybar cutover** required for this milestone

Optional soft process checks:

```bash
pgrep -x waybar || true
pgrep -a qs || true
```

### Mid-session reload

After install or hook changes:

```bash
hyprctl reload
# restart qs if needed, or full re-login
```

---

## 5. Update contract (pin-bump)

*Stub — pin-bump / re-run setup narrative lands in plan 09-02 (DOC-02).*

---

## 6. Non-goals / non-primary paths

*Stub — exp-merge, online cache install, auto-bump, cutover, and related non-primary paths land in plan 09-02 (DOC-02).*

---

## See also

- `./arch/dots-hyprland.sh help` — flag and subcommand source of truth
- `vendor/dots-hyprland` — canonical pin path (submodule)
- `.planning/REQUIREMENTS.md` — DOC-01 / DOC-02 and related contracts
- Root `README.md` — discovery pointer (cross-link in plan 09-03)
