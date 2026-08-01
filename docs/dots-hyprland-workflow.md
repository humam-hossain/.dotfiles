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

*Section body filled in plan 09-01 Task 2.*

---

## 2. Verify fork remotes & pin

*Section body filled in plan 09-01 Task 3.*

---

## 3. Install via thin wrapper (dry-run → live)

*Section body filled in plan 09-01 Task 3.*

---

## 4. Session hooks & dual-run expectations

*Section body filled in plan 09-01 Task 3.*

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
