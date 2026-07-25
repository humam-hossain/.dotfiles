# Architecture Research

**Domain:** Personal dotfiles + vendored desktop shell (dots-hyprland / illogical-impulse)
**Researched:** 2026-07-25
**Confidence:** HIGH (local sources); MEDIUM (upstream edge-case flags / future Lua cutover)

## Standard Architecture

### System Overview

v0.2 integrates **end-4/dots-hyprland** as a managed dependency inside `.dotfiles` without replacing the personal Hyprland/Waybar session ownership yet.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         .dotfiles (owner repo)                            │
├──────────────────────────────────────────────────────────────────────────┤
│  Provisioning          │  Personal configs       │  Vendored third-party  │
│  arch/*.sh             │  .config/hypr/          │  vendor/dots-hyprland/ │
│  arch/hyprland.sh      │  .config/waybar/        │    (git submodule)     │
│  arch/waybar.sh        │  .config/swaync/        │    origin  = personal  │
│  arch/dots-hyprland.sh │  .config/rofi/ …        │    upstream = end-4    │
│  (NEW thin wrapper)    │  (KEEP — personal SoT)  │    ./setup = installer  │
└────────────┬───────────────────────┬───────────────────────┬─────────────┘
             │                       │                       │
             ▼                       ▼                       ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                     $HOME runtime (XDG)                                   │
├──────────────────────────────────────────────────────────────────────────┤
│  ~/.config/hypr/hyprland.conf     ← still owned by .dotfiles (v0.2)      │
│  ~/.config/waybar/                ← dual-run until later cutover         │
│  ~/.config/quickshell/ii/         ← INSTALLED by vendor ./setup          │
│  ~/.local/state/quickshell/       ← ii runtime state / venv              │
│  hyprland-session.service         ← personal screen-share bootstrap      │
└──────────────────────────────────────────────────────────────────────────┘
             │
             ▼  session start
┌──────────────────────────────────────────────────────────────────────────┐
│  Hyprland (0.56.0 present)                                                │
│    exec-once: hyprland-session.service | polkit | waybar+swaync+hyprpaper│
│    exec-once: qs -c ii   (NEW — live shell from install path)            │
│    bind Super+w: pkill waybar && waybar                                  │
└──────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `.dotfiles` root | Personal ownership, pin, install orchestration | Git repo; `arch/*.sh`; `.config/*` |
| Personal fork of dots-hyprland | Own custom commits; PR/rebase surface | GitHub fork; remotes: `origin`=fork, `upstream`=end-4 |
| `vendor/dots-hyprland` submodule | Reproducible pin of fork tip inside `.dotfiles` | `.gitmodules` path + SHA |
| Upstream `./setup` | Source of truth for deps/setups/files install | `setup install` / `install-deps` / `install-setups` / `install-files` |
| `arch/dots-hyprland.sh` (NEW) | Thin Arch-style wrapper; no reimplementation | `REPO_ROOT`, labeled echos, `cd` submodule, call `./setup` with flags |
| `arch/hyprland.sh` (MODIFIED lightly) | Packages + personal hypr/swaync + session unit | Keep; do **not** hand ownership of session to ii in v0.2 |
| `arch/quickshell.sh` (RETIRE) | Local QS product install/symlink | Delete after live ii path works |
| `.config/quickshell` (RETIRE) | v0.1 local product tree | Delete from repo after install proven |
| `~/.config/quickshell` | Live ii shell files | Written by `./setup install-files` (`rsync --delete`) |
| Personal `hyprland.conf` | Session entry, monitors, workspaces, dual-run exec-once | Still primary entry in v0.2 |
| ii `hyprland.lua` + `hyprland/` | Upstream session model (Lua) | **Deferred full cutover**; do not let install clobber personal entry blindly |
| `~/.config/hypr/custom/` | Upstream-designed personal overlay (update-safe) | `install_dir__ignore_existing` — later home for personal Lua overlays |

## Recommended Project Structure

```
.dotfiles/
├── arch/
│   ├── hyprland.sh              # KEEP — packages + personal hypr deploy + session unit
│   ├── waybar.sh                # KEEP — dual-run until later milestone
│   ├── quickshell.sh            # RETIRE after Phase that proves ii install
│   ├── dots-hyprland.sh         # NEW — thin wrapper around vendor/./setup
│   └── …
├── .config/
│   ├── hypr/                    # KEEP personal SoT (hyprland.conf, hyprlock, hyprpaper, …)
│   ├── waybar/                  # KEEP
│   ├── swaync/                  # KEEP
│   └── quickshell/              # DELETE (v0.1 product) once live path verified
├── vendor/
│   └── dots-hyprland/           # NEW git submodule → personal fork
│       ├── setup                # upstream installer entry
│       ├── sdata/               # install steps, dist-arch PKGBUILDs, libs
│       ├── dots/.config/
│       │   ├── quickshell/ii/   # shell product shipped by install-files
│       │   └── hypr/            # lua session model (future cutover)
│       └── .gitmodules          # nested: rounded-polygon shapes widget
├── .gitmodules                  # NEW entry: vendor/dots-hyprland
└── docs or arch/README notes    # fork/submodule/update workflow
```

### Structure Rationale

- **`vendor/` boundary:** Third-party code stays out of `.config/` so personal configs remain clearly owned by `.dotfiles`.
- **Submodule pin:** SHA-locked checkout makes machine rebuilds reproducible; fork remote allows personal patches without losing `upstream` pulls.
- **Thin wrapper only:** `./setup` already implements deps → setups → files; reimplementing in `arch/` would fork maintenance.
- **Personal `.config/hypr` retained:** v0.2 goal is live ii shell, not full Hyprland config cutover (PROJECT.md).
- **Delete local QS product after install:** Avoid two competing shell trees and the current symlink `~/.config/quickshell → .dotfiles/.config/quickshell`.

## Architectural Patterns

### Pattern 1: Fork + Submodule + Thin Wrapper

**What:** Personal GitHub fork is the submodule URL; remotes inside the submodule are `origin` (fork) and `upstream` (end-4). `.dotfiles` pins a SHA. `arch/dots-hyprland.sh` only orchestrates `./setup` with chosen flags and verify steps.

**When to use:** Always for v0.2 — this is the decided delivery model.

**Trade-offs:**
- (+) Reproducible, updateable, matches existing `arch/*.sh` culture
- (+) Custom commits live on the fork, not as ad-hoc patches in `.dotfiles`
- (−) Nested submodule (`shapes`) requires `git submodule update --init --recursive`
- (−) Two-level git mental model (parent pin + submodule worktree)

**Example wrapper shape (illustrative):**
```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
II_ROOT="$REPO_ROOT/vendor/dots-hyprland"

main() {
  echo "[CHECK] submodule present"
  test -x "$II_ROOT/setup" || { echo "[FAIL] vendor/dots-hyprland missing; init submodule"; exit 1; }

  echo "[INSTALL] illogical-impulse via upstream setup (core + skip full hypr takeover)"
  (
    cd "$II_ROOT"
    # --core: skip fish/fontconfig/miscconf/plasma-browser-integration noise
    # --skip-hyprland: do NOT rename personal hyprland.conf or rsync hyprland/
    ./setup install --core --skip-hyprland --skip-sysupdate
  )

  echo "[CONFIG] ensure personal session launches qs -c ii"
  # see Coexistence section — patch or document exec-once in .config/hypr/hyprland.conf

  echo "[VERIFY] quickshell binary + ii tree"
  command -v qs >/dev/null || command -v quickshell >/dev/null
  test -d "$HOME/.config/quickshell/ii"
  echo "[DONE] dots-hyprland installed; personal hyprland.conf still owns session"
}
main "$@"
```

### Pattern 2: Install-Path Live Shell (not repo symlink)

**What:** Live shell is whatever `./setup install-files` writes under `~/.config/quickshell` (rsync `--delete` from `dots/.config/quickshell`). Edits for customization go to the **fork** (then reinstall-files) or to ii user state — not to a deleted local product tree.

**When to use:** From the moment local `.config/quickshell` is retired.

**Trade-offs:**
- (+) Single product path; matches upstream update model
- (−) Live-edit loop is “edit fork → install-files → reload”, slower than the old symlink
- (−) `rsync --delete` wipes local-only files under `~/.config/quickshell`

### Pattern 3: Personal Hypr Entry + Optional Upstream Overlay (coexistence)

**What:** Keep `.dotfiles` `hyprland.conf` as the Hyprland entry file. Add minimal env + `exec-once` for `qs -c ii`. Defer switching entry to `hyprland.lua`.

**When to use:** Entire v0.2 and until a dedicated “Hypr Lua cutover” milestone.

**Trade-offs:**
- (+) Protects monitors, workspaces, personal apps, waybar dual-run, session unit
- (+) Avoids forced Hyprland 0.55+ Lua migration work in this milestone
- (−) Misses stock ii keybinds/execs until cutover or selective cherry-picks
- (−) Must manually set `ILLOGICAL_IMPULSE_VIRTUAL_ENV` (normally from ii `hyprland/env.lua`)

### Pattern 4: Upstream `custom/` Overlay (future)

**What:** ii’s `hyprland.lua` loads `~/.config/hypr/custom/{env,execs,general,rules,keybinds,variables}.lua` when present. Install uses `install_dir__ignore_existing` for `custom/`, so re-install does not clobber user overlays.

**When to use:** When cutting over session entry to `hyprland.lua` (post-v0.2).

**Trade-offs:**
- (+) Official update-safe personalization surface
- (−) Requires Lua rewrite of personal conf concerns (monitors, workspaces, binds)
- (−) Not the v0.2 primary path

## Data Flow

### Install / update flow (repo → setup → ~/.config)

```
[Personal fork on GitHub]
        │  git submodule add / update
        ▼
[.dotfiles vendor/dots-hyprland @ pinned SHA]
        │  arch/dots-hyprland.sh
        ▼
[./setup install | install-deps | install-setups | install-files]
        │
        ├─ 1.deps-router → sdata/dist-arch/* PKGBUILDs (yay)
        │       → quickshell, ii meta packages, fonts, toolkits, …
        ├─ 2.setups → permissions/services (group, portals, etc.)
        └─ 3.files (legacy default)
                ├─ rsync --delete dots/.config/quickshell → ~/.config/quickshell
                ├─ (if NOT --skip-hyprland)
                │     rsync --delete hyprland/ → ~/.config/hypr/hyprland/
                │     mv hyprland.conf → hyprland.conf.old   ← DANGER for personal
                │     install hyprland.lua (unless --skip-hyprland-entry)
                │     hyprlock/hypridle with .old/.new backup rules
                │     custom/ only if missing (ignore-existing)
                └─ optional misc/fish/fontconfig (skipped by --core)

[Personal path — separate, still owned by .dotfiles]
arch/hyprland.sh
  → pacman hyprland stack
  → cp .config/hypr/* → ~/.config/hypr/     (restores/keeps personal conf)
  → hyprland-session.service
arch/waybar.sh → ~/.config/waybar
```

### Session runtime flow

```
TTY / DM
  → Hyprland reads ~/.config/hypr/hyprland.conf   (personal entry, v0.2)
       → exec-once: systemctl --user start hyprland-session.service
       → exec-once: polkit agent
       → exec-once: waybar & swaync & hyprpaper &     (dual-run kept)
       → exec-once: qs -c ii                          (NEW)
       → env: ILLOGICAL_IMPULSE_VIRTUAL_ENV=...       (NEW, required by ii)
            ↓
       qs loads ~/.config/quickshell/ii
            ↓
       uses ~/.local/state/quickshell (.venv, generated colors, user state)
```

### Key Data Flows

1. **Pin flow:** fork tip → submodule SHA in `.dotfiles` → clone on target machine → same install.
2. **Shell update flow:** `cd vendor/dots-hyprland && git fetch upstream && rebase/merge && push origin &&` parent bumps submodule SHA → `./setup install` (or `install-files`) → `~/.config/quickshell` refreshed.
3. **Personal config flow:** edit `.dotfiles/.config/hypr` → `arch/hyprland.sh` (or manual cp) → `~/.config/hypr` — independent of ii file install when `--skip-hyprland`.
4. **Conflict flow (if `--skip-hyprland` omitted):** ii renames `hyprland.conf` → `.old`, installs `hyprland.lua`; personal session semantics disappear until restored. **Prevention is architectural, not optional.**

## Coexistence: hyprland.conf / exec-once with ii install

### What upstream does to Hyprland configs (verified in `3.files-legacy.sh`)

| Target | Behavior | Risk to personal setup |
|--------|----------|------------------------|
| `~/.config/hypr/hyprland/` | `rsync -a --delete` from upstream | High if mixed with personal files in that dir |
| `~/.config/hypr/hyprland.conf` | **Renamed to `.old` if present** (unconditional when hyprland install runs) | **Critical** — disables personal entry |
| `~/.config/hypr/hyprland.lua` | Copied (unless `--skip-hyprland-entry`) | Becomes new entry under Hypr 0.55+ |
| `hyprlock.conf` / `hypridle.conf` | Firstrun → `.old` then replace; else write `.new` | Medium — hyprlock is intentionally kept personal |
| `~/.config/hypr/custom/` | Copy **only if missing** | Low — safe overlay seed |
| `~/.config/quickshell` | `rsync -a --delete` whole tree | Expected; replaces local QS product |

Install flags that matter:

| Flag | Effect |
|------|--------|
| `--skip-hyprland` | Skip **all** hypr file install (tree, entry, lock, idle, custom seed) |
| `--skip-hyprland-entry` | Skip only `hyprland.lua`; still renames `hyprland.conf` and syncs `hyprland/` |
| `--skip-quickshell` | Skip QS tree (not wanted for v0.2 goal) |
| `--core` | Skip plasma-browser-integration, fish, fontconfig, misc conf — **still installs hypr + QS** |
| `--skip-allfiles` / `install-deps` only | Deps without file copy |

**Critical insight:** `--skip-hyprland-entry` alone does **not** protect personal `hyprland.conf` — the rename still runs. Protecting personal session requires `--skip-hyprland` **or** an explicit restore of personal conf after install **or** full Lua cutover.

### Recommended v0.2 coexistence policy (opinionated)

1. **Default wrapper flags:** `./setup install --core --skip-hyprland` (plus noninteractive force flags as needed).
   - Installs deps + setups + **quickshell** (+ core-allowed pieces).
   - Does **not** rename personal `hyprland.conf`.
   - Does **not** overwrite personal `hyprlock.conf` / `hypridle.conf`.
2. **Personal `hyprland.conf` gains minimal ii hooks** (owned by `.dotfiles`):
   ```conf
   # illogical-impulse runtime (required for QS scripts/venv)
   env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,$HOME/.local/state/quickshell/.venv

   # Live shell from install path (dual-run with waybar for now)
   exec-once = qs -c ii
   ```
   Keep existing:
   ```conf
   exec-once = systemctl --user start hyprland-session.service
   exec-once = waybar & swaync & hyprpaper &
   ```
3. **Do not** point `~/.config/quickshell` at `.dotfiles/.config/quickshell` anymore; that tree is deleted after verification.
4. **Order of deploy on a machine:**
   1. `arch/hyprland.sh` (packages + personal conf + session unit)
   2. `arch/waybar.sh` / other personal desktop scripts as needed
   3. `arch/dots-hyprland.sh` (ii deps + files, skip hypr)
   4. Confirm `exec-once` includes `qs -c ii` and env
   5. Only then delete local product + retire `arch/quickshell.sh`
5. **If a future phase wants ii `hyprland/` helpers without full cutover:** copy selected files manually or run install then **immediately re-run personal hypr deploy** so `hyprland.conf` wins again. Prefer explicit restore over hoping `--skip-hyprland-entry` is enough (it is not).

### Later cutover (out of v0.2, architectural preview)

```
Personal hyprland.conf  ──migrate──►  hyprland.lua entry
                                      + hyprland/* from upstream
                                      + custom/*.lua for monitors, apps,
                                        hyprland-session.service, waybar dual-run
                                        (until waybar removed)
```

Official docs note Hyprland 0.55+ Luaification; this machine already runs **Hyprland 0.56.0**, so Lua cutover is feasible later but is a dedicated milestone (monitors DP-1/HDMI-A-2, workspace layout, chrome/kitty/vesktop exec-once, Catppuccin cursor, session unit).

## New vs Modified vs Retired Components

| Item | Change | Notes |
|------|--------|-------|
| Personal GitHub fork of end-4/dots-hyprland | **NEW** | `origin`=fork, `upstream`=end-4 |
| `.gitmodules` + `vendor/dots-hyprland` | **NEW** | Recursive init for nested shapes submodule |
| `arch/dots-hyprland.sh` | **NEW** | Thin wrapper; verify; document flags |
| Workflow docs (README / arch notes) | **NEW** | clone, update, bump pin, reinstall-files |
| `.config/hypr/hyprland.conf` | **MODIFIED** | Add `qs -c ii` + `ILLOGICAL_IMPULSE_VIRTUAL_ENV`; keep waybar dual-run |
| `arch/hyprland.sh` | **UNCHANGED or minor** | Still deploys personal hypr; optional note “run before/after ii” |
| `arch/waybar.sh`, waybar configs | **UNCHANGED** | Dual-run until later cutover |
| `arch/quickshell.sh` | **RETIRE** | After ii path verified |
| `.config/quickshell/` (repo) | **DELETE** | After ii path verified; stops symlink live path |
| `~/.config/quickshell` symlink | **REPLACE** | Becomes real directory from install-files |
| debian/ubuntu QS path | **OUT OF SCOPE** | Arch-primary per PROJECT.md |

## Integration Points

### External / third-party

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| end-4/dots-hyprland | Submodule + `./setup` | Do not reimplement sdata steps |
| Personal fork | Git remotes in submodule | Custom commits; rebase from upstream |
| AUR / yay | Via `./setup install-deps` + dist-arch PKGBUILDs | Also `IgnoreGroup=illogical-impulse` recommended by upstream docs |
| Quickshell (`qs`) | Binary from ii deps; config from install-files | Launch `qs -c ii` |
| Hyprland 0.56 | Personal conf entry remains | Lua entry deferred |
| nested `rounded-polygon-qmljs` | Submodule of vendor repo | `--recursive` required |

### Internal boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `.dotfiles` ↔ `vendor/dots-hyprland` | Submodule SHA only | No copy of ii QML into `.config/` |
| `arch/dots-hyprland.sh` ↔ `./setup` | Process exec, flags | Wrapper owns UX; setup owns logic |
| Personal hypr ↔ ii shell | `exec-once` + env + IPC later | No shared config directory ownership in v0.2 |
| Waybar ↔ ii bar | Dual process | Accept overlap until cutover milestone |
| `arch/hyprland.sh` ↔ ii install | Ordering + restore policy | Personal conf must win after any accidental hypr file install |
| Ping monitor (`:8765`) | Unchanged service | Future ii module consumer; not wired in v0.2 |

## Suggested Build Order (Roadmap Phases 5+)

Continue numbering after v0.1 phases 1–4. Dependencies are hard: **fork before submodule before wrapper before delete**.

### Phase 5 — Fork & Submodule Foundation
**Goal:** Ownership and pin exist; no session behavior change yet.  
**Delivers:**
- Personal fork created; `upstream` remote configured
- `vendor/dots-hyprland` submodule added (recursive)
- Document clone/`submodule update --init --recursive` for fresh machines  
**Avoids:** Running `./setup` before pin exists; deleting local QS early  
**Depends on:** Nothing (first)

### Phase 6 — Thin Arch Wrapper around `./setup`
**Goal:** Idempotent Arch-style install path for ii deps + files without hypr takeover.  
**Delivers:**
- `arch/dots-hyprland.sh` calling `./setup` with `--core --skip-hyprland` (and verify)
- Optional split: `install-deps` / `install-setups` / `install-files` subcommands for debugging
- Noninteractive/`--force` story for automation where safe  
**Avoids:** Reimplementing PKGBUILD lists; full `install` without skip flags  
**Depends on:** Phase 5

### Phase 7 — Session Coexistence (personal hypr + live ii shell)
**Goal:** Hyprland still boots personal conf; ii bar runs beside Waybar.  
**Delivers:**
- `hyprland.conf` gains `env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,...` and `exec-once = qs -c ii`
- Confirm `hyprland-session.service` still starts
- Manual/UAT: both bars visible or acceptable overlap; no conf rename
- Document restore procedure if someone runs setup without `--skip-hyprland`  
**Avoids:** Enabling full ii hyprland.lua entry; removing waybar/swaync  
**Depends on:** Phase 6 (install must place `~/.config/quickshell/ii`)

### Phase 8 — Retire Local Quickshell Product
**Goal:** Single shell product path.  
**Delivers:**
- Stop shipping/using `arch/quickshell.sh`
- Delete `.config/quickshell` from `.dotfiles`
- Ensure `~/.config/quickshell` is install-files output (not symlink to repo)
- Grep/clean docs and scripts that reference the local product  
**Avoids:** Deleting before Phase 7 verification (bricks dual-run experiment)  
**Depends on:** Phase 7 verified live `qs -c ii`

### Phase 9 — Workflow Documentation & Update Path
**Goal:** Operable long-term maintenance.  
**Delivers:**
- Document: update fork from upstream, bump submodule SHA, re-run wrapper
- Document: what is safe to re-run (`install-files` vs full install)
- Note pacman `IgnoreGroup=illogical-impulse` per upstream post-install
- Note nested submodule gotcha  
**Depends on:** Phases 5–8 practically done (can draft earlier, finalize here)

### Later milestones (not v0.2 phases, but architectural sequence)
10. **Selective ii hypr helpers / custom overlays** — optional  
11. **Waybar-parity module ports** (ping, weather, earthquake) into ii  
12. **Waybar/rofi/swaync cutover** — remove dual-run exec-once  
13. **Full Lua hypr cutover** — `hyprland.lua` entry + `custom/*` for personal monitors/apps/session unit  

### Phase ordering rationale

```
Fork ──► Submodule pin ──► Wrapper(setup) ──► Live QS files in $HOME
                                              │
                                              ▼
                                    Personal conf hooks (exec-once/env)
                                              │
                                              ▼
                                    Verify dual-run session
                                              │
                                              ▼
                                    Delete local QS product + retire arch/quickshell.sh
                                              │
                                              ▼
                                    Docs / update workflow
```

- **Fork before submodule:** submodule URL should be the fork you control.  
- **Submodule before wrapper:** wrapper must `cd` to a real `./setup`.  
- **Install before delete local QS:** never remove the only working shell tree before ii files land.  
- **Session hooks before retire:** proves the new path is actually exec’d.  
- **Docs last (or continuous):** encode the flags that prevent hypr conf destruction.

## Anti-Patterns

### Anti-Pattern 1: Full `./setup install` without hypr guards

**What people do:** Run stock install from the submodule and expect personal hypr to survive.  
**Why it's wrong:** Legacy files step **renames `hyprland.conf` → `.old`** and installs Lua entry + `hyprland/` with `--delete`.  
**Do this instead:** `--skip-hyprland` in v0.2; or install then immediately restore personal conf from `.dotfiles`; plan Lua cutover as its own milestone.

### Anti-Pattern 2: Believing `--skip-hyprland-entry` preserves personal conf

**What people do:** Pass only `--skip-hyprland-entry`.  
**Why it's wrong:** Rename of `hyprland.conf` still executes; you can end with neither entry nor Lua file.  
**Do this instead:** `--skip-hyprland` for coexistence, or full entry cutover with `hyprland.lua`.

### Anti-Pattern 3: Reimplementing `./setup` inside `arch/*.sh`

**What people do:** Copy PKGBUILD depends lists and rsync commands into a new script.  
**Why it's wrong:** Diverges from upstream; every ii update becomes a merge tax.  
**Do this instead:** Thin wrapper; flags + verify + personal post-hooks only.

### Anti-Pattern 4: Submodule without recursive init

**What people do:** `git submodule update --init` without `--recursive`.  
**Why it's wrong:** Nested `shapes` widget submodule missing → QS UI breakage.  
**Do this instead:** Always recursive; document in clone instructions.

### Anti-Pattern 5: Delete local `.config/quickshell` before install-files success

**What people do:** Clean up first for a “tidy” diff.  
**Why it's wrong:** Live path today is often a **symlink** into that tree; early delete blanks the shell.  
**Do this instead:** Phase order 6→7→8; verify `~/.config/quickshell/ii` is a real install tree first.

### Anti-Pattern 6: Symlink `~/.config/quickshell` to `vendor/dots-hyprland/dots/...`

**What people do:** Skip install-files; point at git worktree for “live edits.”  
**Why it's wrong:** Bypasses firstrun/state/venv expectations; breaks upstream update model; couples session to dirty worktree.  
**Do this instead:** install-files to XDG; edit on fork; reinstall-files or exp-update.

### Anti-Pattern 7: Letting ii replace hyprlock

**What people do:** Allow hyprland file install to take hyprlock/hypridle freely.  
**Why it's wrong:** PROJECT.md keeps hyprlock; ii idle hooks QS lock paths.  
**Do this instead:** `--skip-hyprland` in v0.2; later custom overlays if needed.

## Scaling Considerations

Not a multi-tenant service — “scale” means **machines, updates, and config surface**.

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 1 machine (now) | Single submodule pin; wrapper flags hardcoded for coexistence |
| 2–3 machines | Same pin; personal hypr remains per-machine overlays in `.dotfiles` branches or host-specific conf fragments |
| Long-term updates | Rebase fork on `upstream` regularly; bump SHA; prefer `install-files` for QS-only refreshes |
| Full rice cutover | Collapse personal hypr into `custom/*.lua`; drop waybar dual-run; one session model |

### Scaling Priorities

1. **First bottleneck:** Accidental hypr conf clobber on reinstall — mitigate with wrapper flag defaults.  
2. **Second bottleneck:** Update drift (fork vs upstream vs parent pin) — document three-step update.  
3. **Third bottleneck:** Dual bar / dual notification stacks resource noise — resolved at cutover milestone, not v0.2.

## Sources

- Local: `/home/pera/github_repo/.dotfiles/.planning/PROJECT.md` (v0.2 decisions)
- Local: `/home/pera/github_repo/.dotfiles/arch/hyprland.sh`, `arch/quickshell.sh`
- Local: `/home/pera/github_repo/.dotfiles/.config/hypr/hyprland.conf` (exec-once model)
- Local: `/home/pera/github_repo/.dotfiles/.planning/codebase/ARCHITECTURE.md`, `STRUCTURE.md`
- Local: `/home/pera/github_repo/dots-hyprland/setup` (subcommand router + help)
- Local: `/home/pera/github_repo/dots-hyprland/sdata/subcmd-install/{options,3.files,3.files-legacy}.sh`
- Local: `/home/pera/github_repo/dots-hyprland/dots/.config/hypr/hyprland.lua`, `hyprland/execs.lua`, `hyprland/variables.lua`
- Official docs: https://ii.clsty.link/en/ii-qs/01setup/ (install/update/uninstall, `--core`, post-install, Lua migration notes)
- Runtime check: Hyprland **0.56.0** present on research machine (Lua-capable)

### Confidence notes

| Claim | Confidence | Basis |
|-------|------------|-------|
| Submodule + thin wrapper model | HIGH | PROJECT.md decisions + existing arch script patterns |
| `install-files` rsync --delete for quickshell | HIGH | Read `3.files.sh` / `3.files-legacy.sh` |
| `hyprland.conf` renamed to `.old` on hypr install | HIGH | Explicit lines in `3.files-legacy.sh` |
| `--skip-hyprland-entry` still renames conf | HIGH | Rename outside the entry skip case |
| `--core` still installs hypr+QS | HIGH | `options.sh` only sets fish/font/misc/plasma skips |
| `custom/` is ignore-existing | HIGH | `install_dir__ignore_existing` call |
| `qs -c ii` is stock autostart | HIGH | `hyprland/execs.lua` |
| Exact noninteractive flag UX under automation | MEDIUM | Interactive `ask` paths exist; wrapper may need `--force` |
| Best long-term Lua migration mapping for personal monitors | MEDIUM | Needs phase-level research at cutover |

---
*Architecture research for: adopting dots-hyprland into .dotfiles (v0.2)*  
*Researched: 2026-07-25*
