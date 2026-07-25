# Phase 1: Shell Foundation & Theme - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Bootstrap the Quickshell directory structure, entry point (shell.qml), service-singleton pattern, PanelLoader architecture, and Material theme system — by porting dots-hyprland's `ii` quickshell wholesale. Result: a visible, themed shell with the full ii panel family (bar, sidebars, dock, overlay, media controls) rendered on every connected monitor.

</domain>

<decisions>
## Implementation Decisions

### Theme Identity
- **D-01:** Fully embrace dots-hyprland's design for theming — adopt Material theme system wholesale, not a custom/simplified approach.
- **D-02:** Static Material palette — no wallpaper-based dynamic color extraction. The Python script (materialyoucolor) generates the color JSON once during provisioning. MaterialThemeLoader reads the static JSON at startup via FileView.
- **D-03:** Seed color: use dots-hyprland's default dark vibrant scheme. Planner picks a suitable accent color during planning.
- **D-04:** Dark mode only for Phase 1 — no light/dark toggle infrastructure.
- **D-05:** Copy dots-hyprland's Appearance + m3colors system wholesale. Widgets access theme tokens via `Appearance.m3colors.m3primary`, `Appearance.m3colors.m3surface`, etc. — not a simpler flat singleton.
- **D-06:** Color generation follows dots-hyprland's proven approach: `scripts/colors/generate_colors_material.py` generates JSON, `MaterialThemeLoader.qml` reads it via `FileView`. Run once during provisioning for the static scheme.

### Directory Structure & dots-hyprland Adaptation
- **D-07:** Full ii/ hierarchy — mirror dots-hyprland directory structure closely: `modules/{common,ii}`, `panelFamilies/`, `services/`, `scripts/`, `defaults/`, `assets/`, with `qmldir` manifests per directory.
- **D-08:** Keep 'ii' (Illogical Impulse) naming for maximum copy-paste compatibility from dots-hyprland. Files live under `modules/ii/`, `panelFamilies/IllogicalImpulseFamily/`.
- **D-09:** Symlink deploy — keep `arch/quickshell.sh`'s existing `ln -s` approach. Edits in the repo are live immediately at `~/.config/quickshell`.
- **D-10:** Include dots-hyprland's `Config.qml` + `Persistent.qml` + `defaults/` system for runtime configuration infrastructure, even though the GUI settings app is a later milestone.

### PanelLoader & Panel Families
- **D-11:** Full PanelLoader + LazyLoader from day 1 — port dots-hyprland's PanelLoader mechanism that dynamically loads panel families based on `Config.options.panelFamily`.
- **D-12:** Port the entire ii panel family wholesale from dots-hyprland (bar, sidebars, dock, overlay, media controls) — copy-paste is easier than writing code from scratch.
- **D-13:** All monitors get the same panel — follow dots-hyprland's `Quickshell.screens` Variants approach for DP-1 and HDMI-A-2.

### Service Singleton Bootstrap
- **D-14:** Port all dots-hyprland services wholesale (~46 singletons). Same copy-everything philosophy. Services that lack backends just won't do anything yet.
- **D-15:** Exact copy, fix only what breaks — port service files verbatim. Out-of-scope feature references (AI, Booru, SongRec) stay as dead code. Only fix hard errors preventing Quickshell from starting.
- **D-16:** Follow dots-hyprland's `qmldir` convention exactly — each directory gets a manifest declaring singletons and components.
- **D-17:** Copy dots-hyprland's `scripts/` directory wholesale too — services depend on helper scripts.

### Agent's Discretion
- Planner has flexibility to pick a specific Material accent seed color (D-03)
- Planner determines the right ordering for porting (which files first, dependency resolution)
- Fix-only-what-breaks: planner decides which import errors or missing dependencies constitute "hard errors" vs. harmless warnings

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### dots-hyprland Reference Source (PRIMARY — the architecture blueprint)
- `../dots-hyprland/dots/.config/quickshell/ii/` — Full quickshell source to port wholesale
- `../dots-hyprland/dots/.config/quickshell/ii/services/MaterialThemeLoader.qml` — Theme loading implementation
- `../dots-hyprland/dots/.config/quickshell/ii/scripts/colors/generate_colors_material.py` — Material color generation script (materialyoucolor)
- `../dots-hyprland/dots/.config/quickshell/ii/scripts/colors/terminal/scheme-base.json` — Terminal color scheme base

### Existing Codebase
- `.config/quickshell/` (git HEAD, deleted in working tree) — Old attempt, reference only. 39 files with flat structure.
- `arch/quickshell.sh` — Existing provisioning script with symlink deploy
- `issues/2026-07-16_igpu-flickering-hang-no-display.md` — Post-mortem: no ddcutil polling (constraint)

### Planning Documents
- `.planning/PROJECT.md` — Project context, constraints, key decisions
- `.planning/REQUIREMENTS.md` — Phase 1 requirements: FWK-01, FWK-03, FWK-04, FWK-05, THM-01, THM-02
- `.planning/ROADMAP.md` — Phase 1 success criteria (5 criteria)
- `.planning/codebase/ARCHITECTURE.md` — Existing quickshell architecture (old attempt)
- `.planning/codebase/STRUCTURE.md` — Directory layout for .config/quickshell/

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `arch/quickshell.sh` — Structured provisioning script with symlink deploy, already handles Quickshell + ddcutil/i2c installation. Verify step included.
- Old Quickshell attempt (git HEAD) — 14 services, 15 widgets, 3 popups with Catppuccin Colours.qml. Reference for what was tried before, but NOT a baseline to iterate on.
- `../dots-hyprland/dots/.config/quickshell/ii/` — 586 QML files, 46 services, full panel family architecture. THE source to port from.

### Established Patterns
- Singleton services via `qmldir` manifests — dots-hyprland's core pattern, also used in old attempt
- Symlink deploy model — `arch/quickshell.sh` already uses `ln -s $QS_SRC $QS_DST`
- Catppuccin Mocha theme contract — existing desktop uses this everywhere; being replaced by Material theme for the shell only
- `[LABEL] message` echo convention in provisioning scripts

### Integration Points
- `~/.config/quickshell/` symlink target — where the shell lives at runtime
- Hyprland `exec-once` — Phase 4 adds auto-start, but shell.qml must be runnable via `quickshell` command
- `hyprland.conf` — monitor definitions (DP-1, HDMI-A-2) that the shell reads via `Quickshell.screens`
- Python `materialyoucolor` library — dependency for color generation script

</code_context>

<specifics>
## Specific Ideas

- "Fully embrace dots-hyprland design for everything" — the user wants maximum fidelity to the dots-hyprland implementation, not a simplified subset
- "Copy-paste from dots-hyprland is easier than writing code" — guiding principle for all porting decisions
- "Bringing pretty much everything would be better, would be easy to avoid errors/bugs" — completeness preferred over minimalism
- "The same way dots-hyprland works" — when in doubt, match dots-hyprland's behavior exactly

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-Shell Foundation & Theme*
*Context gathered: 2026-07-20*
