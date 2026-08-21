# Codebase Structure

**Analysis Date:** 2026-08-21

## Directory Layout

```
.dotfiles/                          # Personal Arch Hyprland/Quickshell dots
├── arch/                           # Primary OS installers (pacman/yay + stow)
│   ├── README.md                   # Manual Arch bootstrap (bootloader, user)
│   ├── necessary.sh                # Base packages
│   ├── hyprland.sh                 # Compositor stack + copy `.config/hypr`
│   ├── dots-hyprland.sh            # Thin wrapper → vendor ./setup
│   ├── waybar.sh                   # Bar packages + managed file copy
│   └── *.sh                        # One script per tool/app
├── ubuntu/                         # apt + stow parity (CLI; no ii)
├── debian/                         # apt + stow parity (CLI; no ii)
├── stow/                           # GNU Stow packages (XDG-shaped)
│   ├── nvim/.config/nvim/          # Neovim (init.lua, lua/)
│   ├── waybar/.config/waybar/      # Waybar config/scripts
│   ├── kitty/, fish/, zsh/, …      # Terminals, shells, apps
│   └── systemd/.config/            # User systemd (hyprland-session)
├── .config/hypr/                   # First-party Hyprland (copied, not stowed)
│   ├── hyprland.conf               # Monolithic compositor config
│   ├── hypridle.conf
│   ├── hyprlock.conf
│   ├── hyprpaper.conf
│   ├── hyprland/scripts/           # Helper scripts
│   └── custom/                     # NOT PRESENT — parent authoring SoT for ii Lua overlays
├── .config/nvim/                   # NOT PRESENT — nvim SoT is stow/nvim; harness still points here
├── .config/quickshell/             # NOT PRESENT — retired in-repo product; live is ~/.config/quickshell
├── vendor/
│   └── dots-hyprland/              # Upstream submodule (not first-party)
├── scripts/                        # Clone helper + GSD phase asserts
├── docs/                           # Operator playbooks
│   └── dots-hyprland-workflow.md
├── issues/                         # Hardware/session notes
├── .planning/                      # GSD plans, inventories, this map
├── README.md                       # Desktop shell + nvim/tmux pointers
├── .gitmodules                     # vendor/dots-hyprland pin (no branch=)
└── .gitignore                      # .claude, .planning/tmp, secrets-ish paths
```

## Directory Purposes

**`arch/`:**
- Purpose: Arch Linux package + config deployment
- Contains: Executable `*.sh`, `README.md`
- Key files: `arch/dots-hyprland.sh`, `arch/hyprland.sh`, `arch/necessary.sh`, `arch/waybar.sh`, `arch/nvim.sh`

**`ubuntu/`, `debian/`:**
- Purpose: Parallel installers for overlapping CLI (nvim, zsh, docker, fonts)
- Contains: `*.sh` named like Arch counterparts
- Key files: `ubuntu/nvim.sh`, `debian/nvim.sh` — **no** `dots-hyprland.sh`

**`stow/`:**
- Purpose: Stow package roots; run `stow -t ~ <name>` from this directory
- Contains: One subdirectory per package with files relative to `$HOME`
- Key files: `stow/nvim/.config/nvim/init.lua`, `stow/waybar/.config/waybar/`

**`.config/hypr/`:**
- Purpose: Personal Hyprland source of truth in-repo (current dual-run session)
- Contains: Conf files copied by `arch/hyprland.sh` to `~/.config/hypr/`
- Key files: `.config/hypr/hyprland.conf`
- Absent: `.config/hypr/custom/` (ii overlay authoring tree — put new `general.lua` / `env.lua` / `execs.lua` here, not in `vendor/`)

**`vendor/`:**
- Purpose: Pinned upstream forks
- Contains: `dots-hyprland` git submodule
- Key files: `.gitmodules`; treat contents as upstream, not product edits

**`scripts/`:**
- Purpose: Validation and one-off operator tools
- Contains: `phaseNN-*.sh|py`, nvim validators, `clone_repo.sh`
- Key files: `scripts/phase12-full-smoke.sh`, `scripts/nvim-validate.sh`

**`docs/`:**
- Purpose: Human playbooks
- Contains: `dots-hyprland-workflow.md`

**`.planning/`:**
- Purpose: GSD phases, research, codebase maps
- Contains: `phases/`, `codebase/`, `research/`
- Generated: Phase artifacts; committed as project planning

**`.claude/`:**
- Purpose: GSD/Claude tooling (gitignored)
- Generated: Yes (local)
- Committed: No (`.gitignore`)

## Key File Locations

**Entry Points:**
- `arch/dots-hyprland.sh`: Only first-party ii install/uninstall/protect
- `arch/hyprland.sh`: Hyprland packages + personal conf copy
- `arch/necessary.sh`: Base system packages
- `.config/hypr/hyprland.conf`: Session autostart / dual-run
- `stow/nvim/.config/nvim/init.lua`: Neovim bootstrap
- `vendor/dots-hyprland/setup`: Upstream installer (via wrapper)

**Configuration:**
- `.config/hypr/*`: Compositor
- `stow/<pkg>/.config/…`: App configs
- `.gitmodules`: Submodule URL (SSH fork)

**Core Logic:**
- `arch/dots-hyprland.sh`: Policy wrapper (allowlist, gates, `PROTECT_EXPLICIT`, hooks)
- `arch/waybar.sh`: Explicit `PACKAGES`, `MANAGED_FILES`, stale cleanup
- `docs/dots-hyprland-workflow.md`: Operator contract

**Testing:**
- `scripts/phase02-config-assert.py` … `scripts/phase12-full-smoke.sh`: Phase contracts
- `scripts/nvim-validate.sh`, `scripts/nvim-audit-failures.sh`: Neovim checks
- No unit-test tree for bash wrappers

## Naming Conventions

**Files:**
- Distro installers: `snake_case.sh` matching app (`google_chrome.sh`, `system_monitor.sh`)
- Wrapper: `arch/dots-hyprland.sh` (product name, hyphenated)
- Phase scripts: `scripts/phaseNN-<topic>-assert.sh|py` or `phaseNN-*-smoke.sh`
- Hypr conf: `hypr*.conf`

**Directories:**
- Stow packages: lowercase app name (`nvim`, `waybar`, `qbittorrent`)
- Distro folders: `arch`, `ubuntu`, `debian`
- Vendor: `vendor/<upstream-name>`

**Script internals (prescriptive):**
- Use `set -euo pipefail`
- Resolve `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` when paths needed
- Echo `[INSTALL]` / `[CONFIG]` / `[DONE]` / `[FAIL]`
- Stow from `stow/`: `cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ <pkg>`
- Pacman: `sudo pacman -Sy --noconfirm --needed` (avoid unattended `-Syu` in targeted scripts)

## Where to Add New Code

**New Arch package + config:**
- Installer: `arch/<name>.sh`
- Config tree: `stow/<name>/.config/<app>/…`
- Wire stow at end of installer (see `arch/nvim.sh`)
- Optional Ubuntu/Debian copies only if CLI parity is wanted

**New Hyprland behavior (binds, exec-once, monitors) — current dual-run:**
- Edit `.config/hypr/hyprland.conf` (repo source)
- Deploy via `arch/hyprland.sh` copy or manual copy to `~/.config/hypr/`
- Do **not** put personal hypr under `stow/` unless changing the copy-vs-stow pattern
- Dual-run ii lines: let `arch/dots-hyprland.sh` enable/delete; keep the two canonical hook lines

**ii `hypr/custom` Lua overlays (full-adopt layer):**
- Author in parent `.config/hypr/custom/` (`general.lua`, empty `env.lua` / `execs.lua` slots)
- Match require names in `vendor/dots-hyprland/dots/.config/hypr/hyprland.lua` (`custom.general`, `custom.env`, `custom.execs`)
- Do **not** commit machine overlays into `vendor/dots-hyprland/dots/.config/hypr/custom/`
- Do **not** add parent `.config/hypr/monitors.lua` or `workspaces.lua` unless intentionally using nwg-displays
- Live apply is copy onto `~/.config/hypr/custom/` after ii files install — not stow, not wrapper rewrite

**ii / Quickshell changes:**
- Do not add a first-party `.config/quickshell` product tree
- Pin bumps: submodule SHA in parent; playbook in `docs/dots-hyprland-workflow.md`
- Wrapper policy (flags, protect list, uninstall): `arch/dots-hyprland.sh` only
- Upstream QML/setup: `vendor/dots-hyprland` (fork), not this repo’s `stow/`

**New validation:**
- `scripts/` named for the phase or tool (`phaseNN-…`, `nvim-…`)

**Utilities:**
- Shared helpers: none extracted; keep logic in the owning `arch/*.sh` unless a second consumer appears
- Repo clone helper stays `scripts/clone_repo.sh`

**New Component/Module:**
- Neovim plugin spec: `stow/nvim/.config/nvim/lua/plugins/`
- Neovim core: `stow/nvim/.config/nvim/lua/core/`
- Waybar scripts: `stow/waybar/.config/waybar/scripts/…` and register in `arch/waybar.sh` `MANAGED_FILES` / `EXECUTABLE_FILES`

## Special Directories

**`vendor/dots-hyprland`:**
- Purpose: Pinned illogical-impulse fork
- Generated: No (submodule checkout)
- Committed: Gitlink SHA in parent; nested submodules required

**`.planning/`:**
- Purpose: GSD planning artifacts and codebase maps
- Generated: Partially (phase outputs)
- Committed: Yes (except `.planning/tmp/` gitignored)

**`.claude/`:**
- Purpose: Local GSD/agent runtime
- Generated: Yes
- Committed: No

**`stow/qbittorrent/.config/qBittorrent/`:**
- Purpose: App config; lock/ipc/rss state gitignored
- Generated: Runtime files ignored
- Committed: Config only

**`scripts/__pycache__/`:**
- Purpose: Python bytecode from phase asserts
- Generated: Yes
- Committed: No (`__pycache__/` in `.gitignore`)

---

*Structure analysis: 2026-08-21*
