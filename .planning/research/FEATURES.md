# Feature Research

**Domain:** Adopt upstream desktop rice (end-4/dots-hyprland / illogical-impulse) as a managed dependency inside personal `.dotfiles`
**Researched:** 2026-07-25
**Confidence:** HIGH (local setup CLI + PROJECT.md + official wiki; MEDIUM for general submodule/vendor ecosystem norms)
**Milestone:** v0.2 — foundation only (fork + submodule + thin wrapper + retire local QS + docs). Not product-bar parity.

## How this domain works (ecosystem model)

“Adopt upstream rice as managed dependency” is **not** a shell-widget product milestone. It is a **dependency + install + session wiring** product. Successful projects share the same shape:

| Layer | Role | This project |
|-------|------|--------------|
| **Ownership remote** | Personal fork so custom commits have a home | GitHub fork; `origin` = fork, `upstream` = end-4 |
| **Pin surface** | Reproducible SHA inside the parent repo | Git submodule at `vendor/dots-hyprland` |
| **Install source of truth** | Upstream installer, not a reimplementation | `./setup` (`install` / `install-deps` / `install-setups` / `install-files`) |
| **Thin host wrapper** | Match host distro/dotfiles style; pass flags | New `arch/*.sh` (replaces product-shipping `arch/quickshell.sh`) |
| **Live tree** | Runtime config under `$XDG_CONFIG_HOME`, not in-tree rewrite | Installed `~/.config/quickshell` from `dots/.config/quickshell` |
| **Overlays later** | Machine-specific / parity customs outside pin | Deferred (Waybar customs, full cutover) |
| **Migration posture** | Dual-run until parity proven | Keep Waybar/`exec-once` until a later milestone |

Canonical upstream behaviors (verified against local `~/github_repo/dots-hyprland` clone + [ii.clsty.link setup docs](https://ii.clsty.link/en/ii-qs/01setup/)):

- `./setup install` is **idempotent** and stepwise (greeting → deps → setups → files).
- Granular: `install-deps`, `install-setups`, `install-files`.
- Flags matter for dual-run hosts: `--core`, `--skip-hyprland`, `--skip-hyprland-entry`, `--skip-quickshell`, `--skip-miscconf`, `--skip-fish`, `--skip-fontconfig`, `--force`, `--skip-backup`.
- Files step **syncs** `dots/.config/quickshell` → `~/.config/quickshell` (overwrite whole dir).
- Hyprland step can **rename** existing `hyprland.conf` → `.old` and install Lua entry — dangerous without a dual-run plan.
- Documented update: `git stash && git pull && ./setup install` (online-script default path `~/.cache/dots-hyprland`; our model uses submodule pin instead of floating cache clone).
- Experimental: `exp-update` (partial sync), `exp-merge` (rebase user `~/.config/quickshell` against upstream; requires `upstream` remote). **Not** MVP foundation.

---

## Feature Landscape

### Table Stakes (Users Expect These)

For an **adoption / foundation** milestone, “user” = the machine owner reinstalling or re-cloning `.dotfiles`. Missing any of these = “dots-hyprland is not actually managed.”

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Personal fork with dual remotes** | Ownership + ability to pull end-4 without losing custom commits | LOW | `origin` → personal fork; `upstream` → `end-4/dots-hyprland`. Seed from existing `~/github_repo/dots-hyprland` clone if useful. |
| **Git submodule at fixed path** | Repro pin; clear third-party boundary | LOW–MED | Path fixed: `vendor/dots-hyprland`. Parent commit records SHA. Clone needs `git submodule update --init --recursive` (or `--recurse-submodules`). |
| **Thin `arch/` wrapper around `./setup`** | Matches existing `.dotfiles` Arch style (`REPO_ROOT`, labeled echos, dispatcher) | MED | Wrapper must not reimplement deps/files; it invokes upstream from submodule cwd. Modes map to `install`, `install-deps`, `install-setups`, `install-files` (+ optional flag passthrough). |
| **Install foundation (deps + setups + files for shell)** | Without this there is no live ii shell | MED–HIGH | First successful run: packages/AUR via upstream, permission/services setups, rsync of quickshell (and chosen other dots). Prefer deliberate flags over blind full install. |
| **Live session uses installed ii shell** | Success criterion is runtime, not repo layout | MED | `~/.config/quickshell` comes from install, not from retired in-tree product. Process starts (exec-once or manual) and bar/shell is visible. |
| **Retire local v0.1 Quickshell product** | Dual product trees = dual maintenance + confusion | MED | Delete/stop shipping `.config/quickshell` product tree; retire `arch/quickshell.sh` as the product install path; remove any docs that treat the local tree as primary. |
| **Dual-run with Waybar preserved** | Waybar still carries customs (ping/weather/earthquake); cutover is later | MED | Do **not** remove `waybar` from `hyprland.conf` `exec-once` in v0.2. Expect two bars possible; document layout/overlap. |
| **Documented workflow** | Without docs, fork/submodule/update is one-off tribal knowledge | LOW–MED | Cover: clone+submodule init, first install, pin bump, pull from upstream into fork, re-run setup, dual-run notes, what is *not* managed yet. |
| **Idempotent re-install path** | Upstream design assumes re-run; host must not fight it | LOW | Wrapper re-entry safe; document which steps overwrite (especially quickshell sync, hyprland files). |
| **Submodule pin is intentional** | Floating `main` inside submodule defeats “managed dependency” | LOW | Bump = explicit parent commit. No silent auto-update of vendor SHA. |

### Differentiators (Competitive Advantage for *this* setup)

Not required for a bare “I ran end-4’s curl installer” install — but they make **this** `.dotfiles` adoption better than a cache clone under `~/.cache/dots-hyprland`.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **`.dotfiles`-native Arch wrapper** | Same muscle memory as `arch/waybar.sh` / `arch/hyprland.sh` | MED | Labeled `[INSTALL]`/`[CONFIG]`/`[VERIFY]`; REPO_ROOT-relative; optional verify step (qs binary, `~/.config/quickshell` present, submodule SHA printed). |
| **Managed pin inside monorepo** | One clone of `.dotfiles` pins the rice version with the rest of the machine | LOW | Beats online script’s default `~/.cache` floating tree for multi-machine / disaster recovery. |
| **Safe dual-run install mode** | Install shell without nuking personal Hyprland/Waybar session | HIGH | Wrapper should expose or default toward flags that avoid full hyprland entry overwrite when coexisting (`--skip-hyprland` / `--skip-hyprland-entry` / selective files) **or** document a minimal overlay that only starts qs beside existing `exec-once = waybar & …`. This is the hard differentiator of v0.2. |
| **`--core` / skip-flag surface in wrapper** | Minimal surface: Hyprland+Quickshell-oriented install without fish/misc conf spam | LOW | Upstream `--core` = skip plasma-browser-integration, fish, fontconfig, miscconf. Good default candidate for dual-run hosts. |
| **Explicit cleanup checklist** | Clean break from v0.1 local QS (~589 QML / ~57k LOC) | MED | Uninstall/stop old qs if running; remove tree; retire script; grep for stale references in docs/scripts; keep Waybar scripts intact. |
| **Documented update/merge *contract*** | Future customs need a known path | LOW | v0.2 ships the **documented** contract (pin bump → setup re-run; optional experimental `exp-update`/`exp-merge` noted as later). Does not require automating merge. |
| **Verify step after install** | Catches “script exited 0 but shell dead” | LOW | `command -v quickshell`, config dir exists, optional `qs` smoke; print submodule commit. Matches `arch/quickshell.sh` / `arch/system_monitor.sh` verify pattern. |

### Anti-Features (Tempting in v0.2 — defer or refuse)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Port Waybar customs (ping / weather / earthquake / music)** | Core long-term value; user lives on these | Needs stable live shell + QML service design; blocks foundation if mixed in | Later milestone after install foundation ships |
| **Full Waybar / rofi / swaync cutover** | “One shell” end state | Parity not verified; customs still on Waybar; risk of broken session | Dual-run until parity checklist green |
| **Continue maintaining local `.config/quickshell` product** | sunk-cost / v0.1 polish | Double maintenance; contradicts adoption goal | Delete tree; customize via fork commits or post-install overlays later |
| **Blind full `./setup install` overwriting all Hyprland** | “Just install like the wiki” | Renames `hyprland.conf`, syncs hyprland tree, may drop personal exec-once (Waybar, portals, machine monitors) | Controlled flags + dual-run session wiring; backup first |
| **Deep theming / Material rework / bar layout parity with v0.1** | Make stock ii look like old bar | Scope is install foundation, not product polish | Accept stock ii visuals in v0.2; theme later |
| **Custom QML modules in submodule without fork discipline** | Quick hacks in vendor tree | Dirty submodule; lost on pin reset; unreviewable | Commit on fork branch, bump submodule SHA in parent |
| **Brightness / ddcutil polling widgets** | “Complete metrics” | Known iGPU hang (`issues/2026-07-16_…`); Waybar backlight already disabled | Never enable DDC/CI polling in shell |
| **Replace hyprlock with QS lock screen** | Upstream ships lock UI | hyprlock works; out of scope | Keep hyprlock |
| **Enable niche ii features (AI chat, Booru, SongRec, LaTeX, translation, anti-flashbang, first-run investment)** | Upstream has them | Noise; not wanted per PROJECT.md | Leave disabled / ignore |
| **Debian/Ubuntu install parity for new path** | Cross-distro nicety | Primary target Arch; upstream non-Arch is community/WIP | Arch-only wrapper in v0.2 |
| **Auto-bump submodule on every pull** | “Always latest rice” | Breaks repro; surprise breakage | Manual pin bump + test session |
| **Make `exp-merge` / `exp-update` the primary update path** | Cool upstream tools | Marked experimental; merge assumes fork/`upstream` workflow maturity | Document as optional later; primary = pin bump + `./setup install` |
| **Re-ship v0.1 bar module list as v0.2 requirements** | Continuity of validated features | Those validate a **deleted** tree; re-verify against installed product later | Treat v0.1 capabilities as historical; re-check stock ii separately |
| **Online curl installer as sole path** | Fastest first-time | Bypasses submodule pin; installs outside `.dotfiles` control | Submodule + wrapper is the managed path |

---

## Feature Dependencies

```
Personal fork (origin + upstream)
    └──requires──> GitHub (or equivalent) remote ready

Git submodule vendor/dots-hyprland
    └──requires──> Personal fork URL (or end-4 until fork lands)
    └──requires──> Parent .gitmodules + commit pin

Thin arch/ wrapper
    └──requires──> Submodule present & initialized
    └──requires──> Upstream ./setup executable

Install modes (deps / setups / files / full)
    └──requires──> Wrapper
    └──requires──> Arch + yay/AUR reality (existing aur.sh pattern)

Live session uses installed ii
    └──requires──> Successful install-files (quickshell sync)
    └──requires──> Session integration (start qs without killing Waybar)
    └──conflicts──> Blind full hyprland overwrite without dual-run plan

Retire local QS product
    └──requires──> Live installed shell path proven (or explicit cutover window)
    └──enhances──> Single source of truth

Documentation
    └──enhances──> All of the above (clone, install, update, dual-run, cleanup)

Dual-run with Waybar
    └──conflicts──> Full cutover (anti-feature)
    └──enhances──> Safe migration / rollback

Update/merge workflow (documented)
    └──requires──> Fork + submodule + install path
    └──enhances──> Future custom module milestones

Waybar custom ports / cutover
    └──requires──> Live ii foundation (this milestone)
    └──deferred──> Post-v0.2
```

### Dependency Notes

- **Fork before (or with) submodule:** Submodule URL should point at the personal fork once ownership is required; pointing only at end-4 blocks custom commits.
- **Wrapper after submodule:** Script `cd`s into `vendor/dots-hyprland` and runs `./setup`; missing init = hard fail with clear message.
- **Session integration after files install:** Config on disk without start path ≠ success. Minimal exec-once or documented manual launch is enough for v0.2; FWK-02-style polish can follow.
- **Cleanup after (or tightly with) live path:** Deleting local tree before any installable shell works risks a barless gap unless Waybar dual-run is intact (it should be — Waybar remains).
- **Customs/cutover require foundation:** Do not schedule ping/weather ports in the same phase as first install.

---

## Expected user-visible behaviors after v0.2 success

What “done” looks like on the machine (acceptance-oriented):

1. **Repo layout:** `.dotfiles` contains `vendor/dots-hyprland` submodule; `.gitmodules` records URL (fork) and path; parent commit pins a SHA.
2. **Remotes (in submodule):** `git remote -v` shows `origin` → personal fork, `upstream` → end-4.
3. **Install entrypoint:** Running the Arch wrapper (e.g. `arch/dots-hyprland.sh` or agreed name) from REPO_ROOT drives upstream setup and prints familiar labeled steps.
4. **Installed shell:** `~/.config/quickshell` is the **upstream-installed** tree (sync from `dots/.config/quickshell`), not the retired hand-rolled product.
5. **Runtime:** illogical-impulse / Quickshell shell is startable and visibly runs in the Hyprland session (bar/shell chrome present).
6. **Waybar still present:** Existing Waybar (and customs) still start via current session config; dual-run is intentional and documented.
7. **Local product gone:** In-repo v0.1 `.config/quickshell` product no longer shipped; `arch/quickshell.sh` retired or reduced to a deprecation stub pointing at the new wrapper — not a second installer.
8. **Docs:** README or `.planning`/arch docs explain clone → submodule init → install → update (pin bump) → dual-run caveats.
9. **Non-goals visible by absence:** No new ping/weather/earthquake QS modules; Waybar/rofi/swaync not removed; hyprlock unchanged; no ddcutil brightness widget.

---

## MVP Definition

### Launch With (v0.2 foundation)

- [ ] **Personal fork + dual remotes** — ownership and upstream pull path
- [ ] **Submodule `vendor/dots-hyprland` with pin** — repro inside `.dotfiles`
- [ ] **Thin `arch/` wrapper** — `./setup` install / deps / setups / files (+ flag passthrough)
- [ ] **Successful install producing live `~/.config/quickshell`** — foundation runtime
- [ ] **Session path starts installed shell while Waybar dual-runs** — user-visible success without cutover
- [ ] **Retire local QS product + `arch/quickshell.sh` product path** — single live shell source
- [ ] **Workflow documentation** — clone, install, update/pin bump, dual-run, cleanup

### Add After Validation (same milestone polish if time, else early next)

- [ ] **Wrapper verify subcommand** — binary + config + SHA checks
- [ ] **Default safe flag profile** (`--core` and/or hyprland skip strategy) — reduce footguns
- [ ] **Explicit backup reminder** before files step — upstream already backs up; surface it in wrapper docs

### Future Consideration (post-v0.2)

- [ ] Waybar custom ports into ii (ping @ `127.0.0.1:8765`, weather, earthquake, …)
- [ ] Full cutover: remove Waybar/rofi/swaync from `exec-once` after parity
- [ ] Fork-side custom commits + routine `upstream` merge / optional `exp-merge`
- [ ] FWK-02 / IPC-02 finishing (auto-start polish, bar toggle keybind) under upstream model
- [ ] Machine overlays (monitors, Asia/Dhaka, conda paths) as documented overlay layer

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Personal fork + remotes | HIGH | LOW | P1 |
| Submodule pin at `vendor/dots-hyprland` | HIGH | LOW | P1 |
| Thin `arch/` → `./setup` wrapper | HIGH | MED | P1 |
| Install foundation (deps/setups/files) | HIGH | MED–HIGH | P1 |
| Live session uses installed ii | HIGH | MED | P1 |
| Dual-run Waybar preserved | HIGH | MED | P1 |
| Retire local QS tree + old install script | HIGH | MED | P1 |
| Workflow documentation | HIGH | LOW | P1 |
| Safe flag profile / hyprland-skip dual-run mode | HIGH | MED–HIGH | P1–P2 |
| Wrapper verify | MED | LOW | P2 |
| Documented pin-bump update contract | MED | LOW | P1 (doc) / P2 (automation) |
| exp-update / exp-merge automation | LOW (v0.2) | HIGH | P3 |
| Waybar custom ports | HIGH (later) | HIGH | P3 (next milestone) |
| Full shell cutover | HIGH (later) | HIGH | P3 (next milestone) |
| Deep theming / v0.1 bar re-parity | MED | HIGH | P3 |
| Debian/Ubuntu wrapper | LOW | MED | P3 / out of scope |

**Priority key:**
- P1: Must have for v0.2 launch
- P2: Should have when cheap; same milestone if low risk
- P3: Explicitly later or anti-feature for v0.2

---

## Competitor / Pattern Feature Analysis

| Concern | Online ii install (`curl …/get` → `~/.cache`) | Copy-paste rice into dotfiles | **Our approach (fork + submodule + wrapper)** |
|---------|-----------------------------------------------|-------------------------------|-----------------------------------------------|
| Ownership of customs | Weak (cache tree, easy to lose) | Full but forks silently from upstream | Fork owns commits; upstream remote explicit |
| Reproducibility | Weak (floating pull) | Commit files; hard to re-merge upstream | Submodule SHA pin in parent |
| Install truth | Upstream `./setup` | Manual / ad hoc | Upstream `./setup` via thin host wrapper |
| Host style | Generic | Varies | Matches `arch/*.sh` REPO_ROOT style |
| Update story | `stash && pull && setup install` | Manual diff hell | Pin bump + same setup re-run; merge tools later |
| Dual-run migration | Not designed for existing Waybar customs | Ad hoc | Explicit dual-run until parity |
| Risk of overwrite | High if full install | High if rsync blindly | Mitigate with flags + docs + backups |

Other patterns considered and not chosen for v0.2 primary path:

- **True copy-vendoring** of QML into `.config/quickshell` — that *was* v0.1; retired.
- **git subtree** — possible but noisier history; submodule boundary is clearer for “third party.”
- **chezmoi / Nix home-manager as the rice manager** — powerful, but out of scope for this Arch script-based repo.
- **Only fork, no submodule** — ownership without pin in parent repo; multi-machine drift.

---

## Implications for REQUIREMENTS.md (v0.2 categories)

Suggested requirement categories for the orchestrator (map 1:1 to table stakes):

1. **OWN** — Personal fork; `origin` / `upstream` remotes configured and documented.
2. **PIN** — Submodule at `vendor/dots-hyprland`; parent records SHA; init instructions.
3. **WRAP** — Thin Arch wrapper; modes for install / deps / setups / files; style match; no reimplementation of upstream installer.
4. **INST** — Foundation install succeeds on Arch (deps + setups + quickshell files at minimum).
5. **SESS** — Session uses installed illogical-impulse shell; dual-run with Waybar; no full cutover.
6. **CLEAN** — Local v0.1 QS product removed; `arch/quickshell.sh` retired as product path; stale references cleaned.
7. **DOC** — Clone/init/install/update/dual-run/cleanup workflow documented.
8. **SAFE** (optional P2) — Default or documented flag profile avoiding destructive Hyprland overwrite during dual-run.

Explicit **non-requirements** for v0.2 (anti-features → REQUIREMENTS out-of-scope):

- Waybar custom module ports
- Waybar/rofi/swaync removal
- v0.1 module feature re-list as acceptance
- hyprlock replacement; ddcutil brightness
- Debian/Ubuntu parity
- Primary reliance on `exp-update` / `exp-merge`

---

## Sources

| Source | Confidence | Use |
|--------|------------|-----|
| `.planning/PROJECT.md` (v0.2 goals, out of scope, dual-run) | HIGH | Scope authority |
| Local clone `~/github_repo/dots-hyprland` — `./setup`, `sdata/subcmd-install/options.sh`, `3.files-legacy.sh`, exp-update/exp-merge help | HIGH | Install modes, skip flags, overwrite behavior |
| [illogical-impulse setup wiki](https://ii.clsty.link/en/ii-qs/01setup/) | HIGH | Official install/update/uninstall, `--core`, post-install, update TL;DR |
| Existing `arch/quickshell.sh`, `arch/waybar.sh`, `arch/hyprland.sh`, `.config/hypr/hyprland.conf` | HIGH | Host style + dual-run baseline (`exec-once = waybar & …`) |
| Ecosystem norms: vendor/ + submodule pin + thin wrapper (web survey) | MEDIUM | Pattern language for managed upstream configs |
| Training/general rice dual-run anecdotes | LOW | Not used as authority; dual-run policy comes from PROJECT.md |

---
*Feature research for: adopt dots-hyprland as managed dependency (v0.2 foundation)*
*Researched: 2026-07-25*
*Do not re-list v0.1 bar modules as product goals for this milestone.*
