# Stack Research

**Domain:** Personal Arch `.dotfiles` adopting end-4/dots-hyprland (illogical-impulse) as a managed dependency
**Researched:** 2026-07-25
**Confidence:** HIGH (local clone `~/github_repo/dots-hyprland`, `./setup` CLI, `sdata/dist-arch/*`, existing `arch/*.sh` patterns)
**Note:** Stack researcher subagent hit rate limits; this file was completed by the orchestrator from the same primary sources FEATURES/ARCHITECTURE/PITFALLS used, plus live `./setup` inspection.

## Recommended Stack

### Core Technologies

| Technology | Version / pin | Purpose | Why Recommended |
|------------|---------------|---------|-----------------|
| **end-4/dots-hyprland** (illogical-impulse) | Submodule SHA pin; track `main` via `upstream` | Upstream rice + Quickshell `ii` shell + installer | Product vehicle for v0.2; already validated as “good enough” vs hand-rolled tree |
| **Git submodule** | Git 2.x recursive | Pin `vendor/dots-hyprland` inside `.dotfiles` | Reproducible install; nested `shapes` submodule requires `--recursive` |
| **Personal GitHub fork** | `origin` = fork, `upstream` = `https://github.com/end-4/dots-hyprland.git` | Own custom commits; pull end-4 updates | Decided milestone model; enables later `exp-merge` if wanted |
| **Upstream `./setup`** | As shipped in pin | install / install-deps / install-setups / install-files | Source of truth for deps + file sync — do **not** reimplement |
| **Quickshell (`qs`)** | Via upstream `illogical-impulse-quickshell-git` (AUR meta) | Runtime for `qs -c ii` | ii shell requires it; let setup install the right package set |
| **Hyprland** | Already on machine (0.56.x class) | Compositor / session | Keep personal `.config/hypr` as entry in v0.2; do not let setup rename conf |
| **Arch + yay** | Existing `arch/aur.sh` pattern | AUR packages for ii meta PKGBUILDs | Upstream dist-arch assumes Arch/AUR; matches primary target |

### Supporting Libraries / runtime paths

| Library / path | Purpose | When to Use |
|----------------|---------|-------------|
| `ILLOGICAL_IMPULSE_VIRTUAL_ENV` → `~/.local/state/quickshell/.venv` | Python venv for ii QS scripts (uv, py 3.12) | **Required** env in personal `hyprland.conf` after setups |
| `~/.config/quickshell` | Live installed QS tree (rsync from `dots/.config/quickshell`) | Runtime config; **not** a symlink to `.dotfiles/.config/quickshell` after cutover |
| `~/.local/state/quickshell` | Generated colors, user state, venv | Owned by runtime; do not vendor into git |
| Nested submodule `dots/.../shapes` → `end-4/rounded-polygon-qmljs` | QML shapes widgets | `git submodule update --init --recursive` always |
| `gh` CLI | Create fork, set remotes | Optional but preferred for fork bootstrap |
| Existing Waybar stack | Dual-run safety net | Keep until later parity milestone |

### Development / host tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `git` + submodule | Pin, update, recursive init | Document `git clone --recurse-submodules` and repair commands |
| `gh repo fork` | One-shot personal fork | Or GitHub UI; then add `upstream` |
| Thin `arch/dots-hyprland.sh` | Host-style wrapper | REPO_ROOT, labeled `[INSTALL]`/`[CONFIG]` echos, flag passthrough |
| `arch/hyprland.sh` / `arch/waybar.sh` | Personal session + dual-run | Run **before** or independently of ii; re-apply after any accidental hypr overwrite |
| Manual backup dir `~/dots-pre-ii-backup-$stamp` | Pre-setup safety | Wrapper should encourage/require before files step |
| Official docs [ii.clsty.link](https://ii.clsty.link) | Operator reference | Link from `.dotfiles` docs; do not fork the wiki |

## Installation

### What `./setup` owns (do not duplicate in arch/)

Upstream stepwise install (idempotent):

1. **install-deps** — Arch meta packages under `sdata/dist-arch/illogical-impulse-*` (basic, quickshell-git, fonts-themes, python, hyprland meta, backlight, audio, widgets, portal, toolkit, …)
2. **install-setups** — permissions/services, venv under `~/.local/state/quickshell/.venv`
3. **install-files** — sync configs; **critical** QS: `rsync -a --delete` → `~/.config/quickshell`; hypr path can rename `hyprland.conf` → `.old`

**v0.2 default flag profile (from ARCHITECTURE/PITFALLS):**

```bash
./setup install --core --skip-hyprland
# optionally staged:
./setup install-deps ...
./setup install-setups ...
./setup install-files --core --skip-hyprland
```

| Flag | v0.2 stance |
|------|-------------|
| `--core` | **Default on** — skip fish/fontconfig/misc/plasma integration noise |
| `--skip-hyprland` | **Default on** — protect personal `hyprland.conf` / hyprlock |
| `--skip-hyprland-entry` alone | **Insufficient** — conf rename still happens; do not rely on it |
| `--skip-quickshell` | **Never** for foundation goal |
| `--skip-backup` | **Never** on first adoption |
| `--force` | Only for noninteractive CI-like reruns after backup proven |
| `exp-update` / `exp-merge` | Document only; **not** primary update path |

### What `.dotfiles` arch wrapper owns

```text
arch/dots-hyprland.sh
  → resolve REPO_ROOT
  → require vendor/dots-hyprland/.git (submodule initialized)
  → cd vendor/dots-hyprland
  → ensure nested submodules recursive
  → invoke ./setup <subcommand> with safe defaults + "$@" passthrough
  → print dual-run / backup reminders
```

**Retire:** `arch/quickshell.sh` (symlink-to-repo model + ddcutil group setup as product path).

**Do not add:** second package list that reimplements `illogical-impulse-*` PKGBUILDs; Debian/Ubuntu path for v0.2.

### Personal session hooks (stack, not upstream files)

After install, personal Hyprland entry must include:

```conf
env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,$HOME/.local/state/quickshell/.venv
exec-once = qs -c ii
```

Keep existing Waybar/swaync/hyprpaper/`hyprland-session.service` exec-once lines.

## What NOT to add

| Tempting addition | Why skip |
|-------------------|----------|
| Reimplemented pacman/yay package arrays for all ii deps | Diverges from upstream; bitrot on every end-4 bump |
| Symlink `~/.config/quickshell` → `.dotfiles/.config/quickshell` | Conflicts with setup rsync; was v0.1 model being retired |
| Vendoring full `~/.local/state/quickshell` | Machine-local state; not portable |
| Making ddcutil/backlight a first-class enablement | Historical iGPU hang (`issues/2026-07-16_*`); upstream may pull backlight package — do not build brightness widgets / DDC polling |
| Online curl-to-`~/.cache/dots-hyprland` as managed path | Bypasses submodule pin and `.dotfiles` ownership |
| `exp-merge` as default update | Experimental; requires mature fork workflow |
| Nix/`--via-nix` install path | WIP upstream; out of Arch-primary scope |
| Extra QML frameworks beyond what setup installs | Customs are later milestones |

## Integration with existing `.dotfiles` stack

| Existing piece | Relationship to v0.2 stack |
|----------------|----------------------------|
| `arch/hyprland.sh` | Still installs hyprland/hyprpaper/hyprlock/swaync + copies personal conf; **session SoT** |
| `arch/waybar.sh` | Dual-run safety; unchanged |
| `arch/rofi.sh` / swaync configs | Unchanged; cutover later |
| `arch/quickshell.sh` | **Retired** after live ii verified |
| `arch/aur.sh` / yay | Prerequisite for setup deps |
| `.config/hypr/*` in repo | Gains minimal ii env + `qs -c ii` lines |
| `.config/quickshell/*` in repo | **Deleted** after verify (product retirement) |

## Version / pin strategy

1. **Submodule URL** points at personal fork once fork exists (or end-4 briefly during bootstrap, then retarget).
2. **Parent commit** records exact SHA — “what’s installed” is auditable in `.dotfiles` history.
3. **Update contract:**  
   `cd vendor/dots-hyprland && git fetch upstream && git merge/rebase upstream/main && git push origin`  
   → parent bumps submodule → `./setup install` (or `install-files`) on machines.
4. **Do not** auto-bump on every `git pull` of parent without an explicit operator step.

## Sources

| Source | Confidence |
|--------|------------|
| `~/github_repo/dots-hyprland/setup` + `install -h` | HIGH |
| `sdata/dist-arch/illogical-impulse-*`, `package-installers.sh` (venv path) | HIGH |
| `.gitmodules` nested shapes submodule | HIGH |
| `arch/quickshell.sh`, `arch/waybar.sh`, `arch/hyprland.sh` | HIGH |
| Sibling research FEATURES.md / ARCHITECTURE.md / PITFALLS.md | HIGH |
| [ii.clsty.link](https://ii.clsty.link) setup docs | MEDIUM–HIGH |

---
*Stack research for: v0.2 Adopt dots-hyprland*
*Researched: 2026-07-25*
*Mode: ecosystem / adoption stack (orchestrator completion after researcher rate-limit)*
