# Project Research Summary

**Project:** Quickshell Desktop Shell / `.dotfiles`  
**Domain:** Adopt upstream desktop rice (end-4/dots-hyprland) as a managed dependency  
**Researched:** 2026-07-25  
**Confidence:** HIGH  
**Milestone:** v0.2 Adopt dots-hyprland (foundation only)

## Executive Summary

v0.2 is **not** a widget/product-bar milestone. It is a **dependency + install + session-wiring** milestone: own end-4/dots-hyprland via a personal fork, pin it as `vendor/dots-hyprland`, drive upstream `./setup` through a thin `arch/` wrapper, get a live `qs -c ii` session while Waybar dual-runs, then delete the hand-rolled `.config/quickshell` product and retire `arch/quickshell.sh`.

Experts treat rice adoption as: **ownership remote → pin surface → upstream installer as SoT → host wrapper → runtime under XDG → overlays later**. Reimplementing install package lists or continuing a local QS rewrite creates a second maintenance surface—the failure mode v0.1 already demonstrated at ~57k LOC.

The dominant risk is **destructive first install**: setup can rename `hyprland.conf` → `.old`, rsync-delete config trees, and leave a machine without personal session semantics. Mitigation is architectural: default `--core --skip-hyprland`, mandatory backup before files, retarget/remove the live QS symlink before install-files, verify live ii **before** deleting the repo tree, and never re-enable DDC/CI brightness polling.

## Key Findings

### Recommended Stack

Git submodule + personal fork remotes + upstream `./setup` + Arch/yay. Runtime: Quickshell from upstream meta packages, `ILLOGICAL_IMPULSE_VIRTUAL_ENV` at `~/.local/state/quickshell/.venv`, live tree at `~/.config/quickshell` (installed copy, not repo symlink). Host glue: new `arch/dots-hyprland.sh`; personal Hyprland entry keeps ownership and only adds env + `exec-once = qs -c ii`.

**Core technologies:**
- **dots-hyprland (submodule pin):** third-party SoT for shell + installer
- **`./setup`:** deps/setups/files — do not reimplement
- **Personal fork remotes:** origin/upstream for ownership and updates
- **Thin arch wrapper:** matches existing `.dotfiles` style
- **Personal hypr + Waybar:** session SoT and dual-run safety net

### Expected Features

**Must have (table stakes):**
- Personal fork + `origin`/`upstream` remotes
- Submodule at `vendor/dots-hyprland` with SHA pin (+ recursive nested submodules)
- Thin `arch/` wrapper → `./setup` (install / deps / setups / files + flag passthrough)
- Successful install → live `~/.config/quickshell` from upstream
- Session starts `qs -c ii` while Waybar still runs
- Retire local QS product tree + `arch/quickshell.sh`
- Workflow docs (clone, init, install, pin-bump update, dual-run, cleanup)

**Should have (differentiators):**
- Safe default flag profile (`--core --skip-hyprland`)
- Backup gate / reminder before files step
- Wrapper `verify` subcommand (binary, config path, submodule SHA)

**Defer (later milestones):**
- Waybar custom ports (ping, weather, earthquake, …)
- Full Waybar/rofi/swaync cutover
- Full ii Hyprland Lua entry cutover
- `exp-merge` / `exp-update` as primary update
- Deep theming / machine overlays productization

### Architecture Approach

```
.dotfiles
  arch/dots-hyprland.sh  →  vendor/dots-hyprland/./setup
  .config/hypr (personal SoT)  →  ~/.config/hypr  (+ ii env & qs exec-once)
  vendor pin  →  setup install-files  →  ~/.config/quickshell (live ii)
  Waybar path unchanged (dual-run)
```

**Major components:**
1. **Fork + submodule** — ownership and pin
2. **Wrapper + setup** — provision runtime
3. **Personal session hooks** — start ii without surrendering hypr ownership
4. **Retirement** — delete local product after verify
5. **Docs** — operator contract

**Critical coexistence rule:** `--skip-hyprland-entry` is **not** enough to protect `hyprland.conf`. Use **`--skip-hyprland`**.

### Critical Pitfalls

1. **Blind `./setup install` on a customized host** — backup first; default skip-hyprland; never `--skip-backup` on first run
2. **Delete repo `.config/quickshell` while `~/.config/quickshell` still symlinks to it** — retarget/install real tree first; then delete
3. **Relying on `--skip-hyprland-entry` alone** — conf still renamed; use full `--skip-hyprland`
4. **Nested submodule not initialized** — always `--recursive`; broken shapes/widgets otherwise
5. **Re-enabling ddcutil DDC polling / brightness widgets** — known iGPU hang class; guard even if upstream pulls backlight packages
6. **Delete-before-verify** — Waybar dual-run helps, but live ii path must be proven before product deletion

## Implications for Roadmap

Continue phase numbering after v0.1 (phases 1–4 shipped). Suggested **Phases 5–9**:

### Phase 5: Fork & Submodule Pin
**Rationale:** Ownership and pin before any install  
**Delivers:** Personal fork, remotes, `vendor/dots-hyprland`, `.gitmodules`, recursive init documented/working  
**Addresses:** Fork + submodule table stakes  
**Avoids:** Floating cache clone; non-recursive submodule breakage  

### Phase 6: Thin Setup Wrapper & Safe Defaults
**Rationale:** Install path must be host-native and non-destructive by default  
**Delivers:** `arch/dots-hyprland.sh`, flag profile `--core --skip-hyprland`, backup guidance, staged subcommands  
**Addresses:** Wrapper + safe install features  
**Avoids:** Blind full rice overwrite; reimplemented package lists  

### Phase 7: Install, Session Hooks & Dual-Run Verify
**Rationale:** Live shell is the success signal before cleanup  
**Delivers:** deps/setups/files run; `ILLOGICAL_IMPULSE_VIRTUAL_ENV` + `qs -c ii` in personal hypr; Waybar still up; verify checklist  
**Addresses:** Live session + dual-run  
**Avoids:** Symlink collisions; barless gap; hypr conf rename  

### Phase 8: Retire Local Quickshell Product
**Rationale:** Single product path only after verify  
**Delivers:** Delete `.config/quickshell` tree from repo; retire `arch/quickshell.sh`; no second installer  
**Addresses:** Product retirement  
**Avoids:** Delete-while-symlink-live; zombie install script  

### Phase 9: Workflow Documentation & Update Contract
**Rationale:** Adoption fails without an operator playbook  
**Delivers:** Docs for clone/init/install/update (pin bump)/dual-run/cleanup; optional verify notes  
**Addresses:** Documentation table stakes  
**Avoids:** Undocumented exp-merge as primary; auto-bump surprises  

**Hard sequencing:** backup → wrapper defaults → retarget symlink → install → verify ii → delete local tree → docs.

## Sources

- `.planning/research/STACK.md` (orchestrator completion post rate-limit)
- `.planning/research/FEATURES.md` (gsd-project-researcher)
- `.planning/research/ARCHITECTURE.md` (gsd-project-researcher)
- `.planning/research/PITFALLS.md` (gsd-project-researcher; file landed before session rate-limit error)
- Local `~/github_repo/dots-hyprland` setup + sdata
- `.planning/PROJECT.md` v0.2 scope

---
*Research summary for: v0.2 Adopt dots-hyprland*
*Researched: 2026-07-25*
