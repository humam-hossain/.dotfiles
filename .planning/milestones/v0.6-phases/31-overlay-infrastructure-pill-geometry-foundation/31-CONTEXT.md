# Phase 31: Overlay Infrastructure & Pill Geometry Foundation - Context

**Gathered:** 2026-09-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish personal Quickshell overlay infrastructure in the repository and solve the core pill sizing limitation in upstream dots-hyprland:

1. **Overlay Infrastructure (PILL-01):** Establish `restow/quickshell/.config/quickshell/ii/modules/ii/bar/` overlay tree managed with GNU Stow (`stow --verbose=5 --no-folding -t ~ quickshell`) adhering to the repository's `collision-map.tsv` (`rsync-replace` tag).
2. **Dynamic Pill Width Sizing (PILL-02, PILL-03):** Unlock dynamic content-driven pill widths by eliminating the hardcoded `implicitWidth: root.centerSideModuleWidth` constraint in `BarContent.qml`. Allow pills and groups to expand and contract fluidly to fit variable-length text (detailed date/time, RAM `X.X GB / Y.Y GB`) without clipping or overflow.
3. **Smooth Width Animations:** Add fluid width transition animation to `BarGroup.qml` using `Appearance.animationCurves.emphasizedDecel` (250ms) so pills resize gracefully when internal text length updates.
4. **Dots-Hyprland Visual Purity (PILL-04):** Strictly preserve default dots-hyprland aesthetics (`Appearance.rounding.small` = 12px, `padding: 5`, `spacing: 4`, `Appearance.colors.colLayer1` fill, `Config.options.bar.borderless` toggling) with zero custom style drift or divergent CSS hacks.
5. **Live Reload & Validation:** Reload via native Hyprland keybind `Ctrl+Super+R` (`killall ydotool qs quickshell; qs -c $qsConfig &`) and author automated verification script `scripts/phase31-overlay-pill-assert.sh`.

Out of scope:
- Customizing individual bar components or reformatting RAM/CPU metrics (Phase 32 owns this).
- Rearranging modular bar sections across Left, Center, and Right or dual-monitor testing (Phase 33 owns this).
- Full milestone verification and bootstrap integration testing (Phase 34 owns this).

</domain>

<decisions>
## Implementation Decisions

### Dynamic Content Sizing & Pill Geometry (Core Requirement)
- **D-01 (Dynamic Width Unlocked):** In `BarContent.qml`, remove the artificial `implicitWidth: root.centerSideModuleWidth` overrides on `leftCenterGroup` and `rightCenterGroup`. Allow `BarGroup`'s native content calculation (`gridLayout.implicitWidth + padding * 2`) to govern pill width so pills expand dynamically with detailed text (e.g. clock/date, memory usage).
- **D-02 (Smooth Resizing Transitions):** In `BarGroup.qml`, add a `Behavior on implicitWidth` animated via `Appearance.animationCurves.emphasizedDecel` (250ms duration, enabled for horizontal bars). This prevents abrupt popping when text lengths change.
- **D-03 (Purity to Upstream Defaults):** Retain 100% fidelity to dots-hyprland visual styling per explicit user direction (*"the default dots-hyprland style is okay with me, just dynamic width of pills is my main concern, the rest of the design keep it dots-hyprland default"*):
  - Corner radius: `Appearance.rounding.small` (12px)
  - Internal padding: `padding: 5` (upstream default)
  - Inter-pill spacing: `spacing: 4` (upstream default in `BarContent.qml`)
  - Surface color: `Appearance.colors.colLayer1` with upstream `Config.options.bar.borderless` handling
- **D-04 (No Artificial Ceilings):** Pure dynamic content sizing — no hardcoded width floors or ceilings that artificially restrict pill expansion.

### Overlay Architecture & Repository Discipline
- **D-05 (File-Level Restow Overlay):** Create `restow/quickshell/.config/quickshell/ii/modules/ii/bar/` containing only the customized QML files (`BarContent.qml`, `BarGroup.qml`). Stowing with `--no-folding` symlinks only these specific files into `~/.config/quickshell/ii/modules/ii/bar/` while keeping all other upstream modules untouched.
- **D-06 (Collision Map & Recovery Alignment):** `$XDG_CONFIG_HOME/quickshell` is mapped in `collision-map.tsv` as `restow` with recovery tag `rsync-replace`. If upstream `./setup install` is executed, recovery is simply: `cd restow && stow --verbose=5 --no-folding -t ~ quickshell`.
- **D-07 (Live Reload Workflow):** Development reload uses the existing native Hyprland shortcut `Ctrl+Super+R` (`killall ydotool qs quickshell; qs -c $qsConfig &`) defined in `~/.config/hypr/hyprland/keybinds.lua`.
- **D-08 (Automated Assertion Harness):** Author `scripts/phase31-overlay-pill-assert.sh` exercising 4 test sections:
  1. Symlink integrity for `BarGroup.qml` and `BarContent.qml` pointing into `restow/quickshell`.
  2. QML syntax and property integrity (absence of `centerSideModuleWidth` clamps on center groups).
  3. Dynamic sizing and animation declaration verification.
  4. Repository hygiene asserting `arch/dots-hyprland.sh verify --strict` exits 0 with zero findings and git working tree remains clean.

### the agent's Discretion
- Exact easing curve parameters and duration for the width animation in `BarGroup.qml` (defaulting to `Appearance.animationCurves.emphasizedDecel`, 250ms).
- Assertion section structure in `scripts/phase31-overlay-pill-assert.sh`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and Requirements
- `.planning/ROADMAP.md` §Phase 31 — Goal statement, requirements, and success criteria
- `.planning/REQUIREMENTS.md` lines 8–14 — PILL-01, PILL-02, PILL-03, PILL-04 specifications
- `.planning/STATE.md` §Milestone v0.6 — Current project state and roadmap context

### Quickshell Upstream Implementation
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` — Base pill container, padding, radius, and `gridLayout.implicitWidth`
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/BarContent.qml` — Bar layout, `leftCenterGroup`, `rightCenterGroup`, and `centerSideModuleWidth` clamp
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Bar.qml` — Top-level bar window, layer shell settings, and floating styles
- `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/Appearance.qml` lines 201–212 — `rounding.small: 12`, animation curves, and colors

### Repository Architecture & Stow Rules
- `collision-map.tsv` line 83 — `$XDG_CONFIG_HOME/quickshell` tracked as `restow` (`rsync-replace`)
- `restow/README.md` — Restow contract, `--no-folding` discipline, recovery commands
- `arch/dots-hyprland.sh` — Verification engine (`verify --strict`)
- `~/.config/hypr/hyprland/keybinds.lua` line 56 — `Ctrl+Super+R` Quickshell reload keybinding

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BarGroup.qml`: Already contains the responsive calculation `implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (gridLayout.implicitWidth + padding * 2)`. Unclamping the parent container allows this native math to function as originally intended.
- `Appearance.animationCurves.emphasizedDecel`: Standard Material 3 deceleration curve defined in `Appearance.qml` line 260 for natural-feeling expansions.

### Established Patterns
- Three-tree dotfile management: Packages in `restow/` represent paths where upstream installer overwrites content (`install_dir__sync`).
- GNU Stow `--no-folding`: Ensures directory trees in `$HOME` remain real directories and only leaf overlay files become symlinks.
- Zero Git Churn: No generated cache or runtime artifacts may pollute git status.

### Integration Points
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` -> symlinked to `~/.config/quickshell/ii/modules/ii/bar/BarGroup.qml`
- `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` -> symlinked to `~/.config/quickshell/ii/modules/ii/bar/BarContent.qml`

</code_context>

<specifics>
## Specific Ideas

- **User Insight:** "the main issue with default dots-hyprland pills and bar groups basically groups and components the main problem is that the length they don't dynamically change like let's say for example right now the time date stuff the peel is not growing because well now it is much more detailed so that pills is not dynamically changing its length so that is the only issue I'm seeing like with the text the pills is not the length of the peel is not changing so that is the changes that need to be made"
- **User Directive:** "i think the default dots-hyprland style is okay with me, just dynamic width of pills is my main concern, the rest of the design keep it dots-hyprland default"

</specifics>

<deferred>
## Deferred Ideas

- **Phase 32 (Component Representation & Formatting Customization):** Reformatting RAM to definite `X.X GB / Y.Y GB`, tuning CPU metrics, Weather, Media, Utilities, Privacy alerts, and System Tray.
- **Phase 33 (Modular Layout & Rearrangement):** Reorganizing Left, Center, and Right bar sections in `BarContent.qml` and live trial-and-error testing across dual monitors (`DP-1` and `HDMI-A-1`).
- **Phase 34 (Verification & Bootstrap Integration):** Dynamic wallpaper palette switch tests (`switchwall.sh`), full strict verification pass, and `./bootstrap.sh` fresh-install validation.

</deferred>

---

*Phase: 31-overlay-infrastructure-pill-geometry-foundation*
*Context gathered: 2026-09-20*
