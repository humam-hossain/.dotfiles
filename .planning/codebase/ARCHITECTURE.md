<!-- refreshed: 2026-08-21 -->
# Architecture

**Analysis Date:** 2026-08-21

## System Overview

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                     Operator / live Arch session                        │
│              Hyprland + waybar + qs -c ii (dual-run)                    │
└────────────┬──────────────────────────┬─────────────────────────────────┘
             │                          │
             ▼                          ▼
┌──────────────────────────┐  ┌───────────────────────────────────────────┐
│   Personal config layer  │  │  GNU Stow packages                         │
│   `.config/hypr/`        │  │  `stow/<pkg>/.config/...` → `$HOME`        │
│   hyprland.conf + idle/  │  │  nvim, waybar, kitty, fish, systemd, …     │
│   lock/paper             │  └───────────────────────────────────────────┘
│   `.config/hypr/custom/` │  ← **absent** in parent repo (ii overlay slot)
└────────────┬─────────────┘
             │ exec-once qs -c ii; env ILLOGICAL_IMPULSE_VIRTUAL_ENV
             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  Thin wrapper (first-party)                                             │
│  `arch/dots-hyprland.sh`  →  vendor `./setup` (allowlisted install*)    │
│  Wrapper-owned: uninstall, protect, backup gate, --skip-hyprland inject │
└────────────┬────────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  Upstream submodule (not first-party product)                           │
│  `vendor/dots-hyprland`  pin gitlink in parent                          │
│  Live product after install: `~/.config/quickshell` (real dir, not repo)│
└─────────────────────────────────────────────────────────────────────────┘
             ▲
┌────────────┴────────────────────────────────────────────────────────────┐
│  Distro installers (first-party)                                        │
│  `arch/*.sh`  (primary)  ·  `ubuntu/*.sh` · `debian/*.sh` (CLI parity)  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Arch OS bootstrap notes | Useradd, systemd-boot, visudo — not automated | `arch/README.md` |
| Distro installers | Pacman/apt + stow/copy configs per app | `arch/*.sh`, `ubuntu/*.sh`, `debian/*.sh` |
| ii thin wrapper | Preflight submodule, inject safe defaults, backup gate, delegate `./setup`, enable hypr hooks, safe uninstall/protect | `arch/dots-hyprland.sh` |
| Personal Hyprland | Compositor, monitors, autostart dual-run, binds | `.config/hypr/hyprland.conf` |
| Hypr companions | Idle, lock, wallpaper | `.config/hypr/hypridle.conf`, `hyprlock.conf`, `hyprpaper.conf` |
| ii hypr/custom overlays | Personal Lua overlays required by upstream `hyprland.lua` after full hypr files | Authoring SoT: parent `.config/hypr/custom/` (**not in repo**). Upstream seeds: `vendor/dots-hyprland/dots/.config/hypr/custom/{env,execs,general,rules,keybinds,variables}.lua`. Live: `~/.config/hypr/custom/` |
| Stow packages | XDG-shaped trees symlink-deployed to `$HOME` | `stow/<name>/` |
| Waybar installer | Package list + managed file copy + stale cleanup | `arch/waybar.sh` |
| Neovim product | Lazy.nvim plugin tree | `stow/nvim/.config/nvim/` |
| Upstream ii | Quickshell illogical-impulse desktop shell | `vendor/dots-hyprland` (submodule) |
| Operator playbook | Clone, pin, dry-run, dual-run, pin-bump | `docs/dots-hyprland-workflow.md` |
| Phase assert scripts | GSD phase verification (not session runtime) | `scripts/phase*.sh`, `scripts/phase*.py` |

## Pattern Overview

**Overall:** Distro-scripted bootstrap + GNU Stow for app configs + **thin wrapper around an upstream submodule** for the Quickshell desktop shell.

**Key Characteristics:**
- **Arch is the product desktop**; Ubuntu/Debian scripts exist for overlapping CLI tools only (no `dots-hyprland.sh` there).
- **Personal Hyprland is first-party and skip-protected.** Default wrapper injects `--core --skip-hyprland --skip-sysupdate` so upstream does not replace `hyprland.conf`.
- **Live ii is installed files**, not a repo symlink: `~/.config/quickshell` after `arch/dots-hyprland.sh install`.
- **Dual-run:** personal `waybar` stays; `exec-once = qs -c ii` starts the ii shell beside it.
- **Submodule is canonical vendor path only** (no sibling clone as source of truth). Wrapper never `git submodule update --init`.

## Layers

**Operator / session:**
- Purpose: Running Hyprland compositor and autostarted bars/shells
- Location: `$HOME/.config/hypr` (copied from `.config/hypr` by `arch/hyprland.sh`)
- Contains: Live `hyprland.conf`, user session units
- Depends on: Packages from `arch/hyprland.sh`, `arch/waybar.sh`, wrapper install
- Used by: User login

**First-party installers:**
- Purpose: Install packages and deploy configs
- Location: `arch/`, `ubuntu/`, `debian/`
- Contains: One script per concern (`nvim.sh`, `tools.sh`, …)
- Depends on: `pacman`/`apt`, `yay` where noted, `stow`
- Used by: Operator running scripts from repo root

**Stow config layer:**
- Purpose: Versioned XDG trees
- Location: `stow/`
- Contains: Package dirs with `.config/<app>/…` (and some home files)
- Depends on: GNU Stow (`stow -t ~ <pkg>` from `stow/`)
- Used by: Most `arch/*.sh` `[CONFIG]` steps

**Personal Hyprland overlay:**
- Purpose: Machine-specific compositor policy + dual-run hooks
- Location: `.config/hypr/`
- Contains: Monolithic `hyprland.conf` (not split via `source=` except comments). No `custom/` Lua tree in this repo.
- Depends on: Hyprland ecosystem packages
- Used by: Compositor; wrapper `enable_hypr_ii_hooks` / uninstall hook deletion

**ii `hypr/custom` Lua (contract present; parent files absent):**
- Purpose: After full hypr files, `hyprland.lua` optionally `require("custom.*")`
- Location (live): `~/.config/hypr/custom/*.lua` — guarded by `is_file_exists` in `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua`
- Location (upstream seed): `vendor/dots-hyprland/dots/.config/hypr/custom/`
- Location (parent authoring): `.config/hypr/custom/` — **does not exist**
- Depends on: Full-install Lua session (not the current `hyprland.conf` dual-run)
- Used by: Future full-adopt; do not commit machine overlays into `vendor/dots-hyprland`

**Vendor desktop shell:**
- Purpose: illogical-impulse Quickshell UI
- Location: `vendor/dots-hyprland`
- Contains: Upstream `setup`, QML, meta packages
- Depends on: Nested submodules, AUR (`yay`)
- Used by: `arch/dots-hyprland.sh` only for allowlisted `install*`

**Planning / verification:**
- Purpose: GSD phases and asserts
- Location: `.planning/`, `scripts/`
- Contains: Inventories, dispositions, smoke scripts
- Depends on: Repo layout + live system for some smokes
- Used by: Phase execution, not daily session

## Data Flow

### Primary Request Path

1. Operator clones repo with `--recurse-submodules` (`docs/dots-hyprland-workflow.md`).
2. OS/user/bootloader from `arch/README.md` (manual).
3. `arch/necessary.sh` and other `arch/*.sh` install packages; many `cd …/stow && stow -t ~ <pkg>`.
4. `arch/hyprland.sh` copies `.config/hypr/*` to `~/.config/hypr/` and stows `systemd` + `swaync`.
5. `./arch/dots-hyprland.sh install` preflights submodule, backup-gates, injects safe flags, runs `vendor/dots-hyprland/setup`, then `enable_hypr_ii_hooks`.
6. Session starts: `hyprland.conf` `exec-once` launches waybar, swaync, hyprpaper, `qs -c ii`.

### Thin wrapper install family

1. `main()` allowlists subcommand (`arch/dots-hyprland.sh` ~1496).
2. `preflight()` requires `vendor/dots-hyprland/.git` and executable `setup` (never auto-init).
3. `backup_gate()` for `install` / `install-files` (type `yes`).
4. Safe defaults injected unless `--full`.
5. `--dry-run` prints argv; live execs `./setup`.
6. Success path re-marks `PROTECT_EXPLICIT` and enables hypr ii hooks in live + repo conf.

### Safe uninstall / protect

1. `uninstall` does **not** call upstream `./setup uninstall` unless `--upstream-dangerous`.
2. Removes `illogical-impulse-*` metas with `pacman -R` (no `-s` cascade).
3. Re-marks personal stack explicit; optionally strips configs/state and hypr hook lines.
4. `protect` heals `--asdeps` demotion without uninstalling ii.

**State Management:**
- Package install reason (`--asexplicit` vs `--asdeps`) is session-critical; wrapper owns protect list.
- Quickshell runtime venv: `~/.local/state/quickshell/.venv` (env in `hyprland.conf`).
- Upstream backups: `~/ii-original-dots-backup`.
- No application database; nvim lockfile at `stow/nvim/.config/nvim/lazy-lock.json`.

## Key Abstractions

**Thin wrapper:**
- Purpose: Policy around dangerous upstream setup (hypr skip, backup, uninstall)
- Examples: `arch/dots-hyprland.sh`
- Pattern: Allowlist + injected flags + wrapper-owned uninstall/protect

**Stow package:**
- Purpose: One app config tree
- Examples: `stow/nvim`, `stow/waybar`, `stow/kitty`
- Pattern: Directory named after package; contents relative to `$HOME`

**Arch installer script:**
- Purpose: Idempotent package + config deploy
- Examples: `arch/nvim.sh`, `arch/hyprland.sh`, `arch/waybar.sh`
- Pattern: `set -euo pipefail`; `[INSTALL]` / `[CONFIG]` / `[DONE]` echoes; `pacman -Sy --noconfirm --needed`

**PROTECT_EXPLICIT:**
- Purpose: Packages that must remain explicit after ii demotes deps
- Examples: listed in `arch/dots-hyprland.sh`
- Pattern: Curated dual-run + personal stack, not every `arch/*.sh` package

**Dual-run hooks:**
- Purpose: Start ii without replacing personal hypr
- Examples: `exec-once = qs -c ii` and `env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,…` in `.config/hypr/hyprland.conf`
- Pattern: Wrapper enable on install, delete on uninstall

## Entry Points

**`arch/dots-hyprland.sh`:**
- Location: `arch/dots-hyprland.sh`
- Triggers: Operator; only first-party ii install path
- Responsibilities: Preflight, gates, defaults, setup exec, hooks, uninstall, protect

**`vendor/dots-hyprland/setup`:**
- Location: submodule
- Triggers: Wrapper `install*` only; experimental cmds operator-direct
- Responsibilities: Upstream deps/setups/files

**`arch/hyprland.sh`:**
- Location: `arch/hyprland.sh`
- Triggers: Operator
- Responsibilities: Hyprland ecosystem packages, copy personal hypr, stow systemd/swaync

**`arch/*.sh` (other):**
- Location: `arch/`
- Triggers: Operator, typically after `necessary.sh`
- Responsibilities: Per-app packages + stow/copy

**Hyprland compositor:**
- Location: live `~/.config/hypr/hyprland.conf` (source `.config/hypr/hyprland.conf`)
- Triggers: Graphical login
- Responsibilities: Monitors, autostart, binds, env

**Neovim:**
- Location: `stow/nvim/.config/nvim/init.lua`
- Triggers: `nvim` after `arch/nvim.sh`
- Responsibilities: Load `core.*`, Lazy `plugins`

**`scripts/clone_repo.sh`:**
- Location: `scripts/clone_repo.sh`
- Triggers: Operator with `gh`
- Responsibilities: Clone all GitHub repos via `gh repo list` — unrelated to ii pin

## Architectural Constraints

- **Threading:** Shell sequential; Hyprland/Quickshell are their own processes. Wrapper is single-process bash.
- **Global state:** Pacman explicit/asdeps; live `~/.config/*`; no in-repo runtime DB.
- **Circular imports:** Not applicable (shell/config). Avoid treating `vendor/` as editable product.
- **Submodule:** Nested submodules required (`--recursive`). Wrapper does not init them.
- **Hypr skip is one-way:** `--skip-hyprland` has no upstream undo; use `--full` for full profile (may rename personal hypr to `.old`).
- **Debian/Ubuntu:** No ii wrapper; desktop shell Arch-only.
- **No in-repo Quickshell or Neovim config at `.config/`:** `scripts/phase04-ipc-reload-assert.py` and `scripts/nvim-validate.sh` still point at `.config/quickshell` and `.config/nvim`, which are not in this tree. Live Quickshell is `~/.config/quickshell`; Neovim SoT is `stow/nvim/.config/nvim/`.

## Anti-Patterns

### Edit or develop against a sibling `dots-hyprland` clone

**What happens:** Operator treats `~/github_repo/dots-hyprland` as source of truth.
**Why it's wrong:** Parent pin and wrapper only see `vendor/dots-hyprland`.
**Do this instead:** All pin/install work from `vendor/dots-hyprland` (`docs/dots-hyprland-workflow.md`).

### Call upstream `./setup uninstall` by default

**What happens:** `yay -Rns` on metas cascade-removes hyprland/fish/etc.
**Why it's wrong:** Dual-run personal stack is marked asdeps by ii install.
**Do this instead:** `arch/dots-hyprland.sh uninstall` (safe). `--upstream-dangerous` only with typed `UPSTREAM-UNINSTALL`.

### Symlink repo Quickshell as live product

**What happens:** Expect `.config/quickshell` in this repo or a stow link.
**Why it's wrong:** Product tree was retired; live tree is a real directory under `~/.config/quickshell`.
**Do this instead:** Install via wrapper; assert `test ! -L ~/.config/quickshell`.

### Auto-init submodule in the wrapper

**What happens:** Missing pin silently fetched.
**Why it's wrong:** Reproducibility requires explicit operator `git submodule update --init --recursive`.
**Do this instead:** Fail preflight with the fix command printed.

### Bare `--skip-backup` on first adoption

**What happens:** Upstream overwrites without backup dir.
**Why it's wrong:** First-run clobber of Quickshell/other dots.
**Do this instead:** Confirm backup gate; dual-key `--skip-backup --allow-skip-backup` only when intentional.

## Error Handling

**Strategy:** `set -euo pipefail` on installers; wrapper prints `[FAIL]` / `[CONFIG]` and exits 1 on policy violations.

**Patterns:**
- Preflight missing submodule → print `git submodule update --init --recursive`, exit 1
- Backup/uninstall gates require exact tokens (`yes`, `UPSTREAM-UNINSTALL`)
- Non-allowlisted subcommands refused with pointer to vendor `./setup`
- Pacman `--needed` for idempotent package installs

## Cross-Cutting Concerns

**Logging:** Echo prefixes `[INSTALL]`, `[CONFIG]`, `[DONE]`, `[FAIL]`. Many scripts also `set -x`. Wrapper dry-run prints would-exec argv.

**Validation:** Phase scripts (`scripts/phase10-inventory-assert.sh`, `scripts/phase12-full-smoke.sh`, etc.) encode contracts; nvim has `scripts/nvim-validate.sh`.

**Authentication:** GitHub SSH for clone/submodule (`git@github.com:humam-hossain/dots-hyprland.git` in `.gitmodules`). Session polkit agent in `hyprland.conf`. No app auth layer.

---

*Architecture analysis: 2026-08-21*
