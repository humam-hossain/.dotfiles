# Phase 1: Shell Foundation & Theme - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-20
**Phase:** 1-Shell Foundation & Theme
**Areas discussed:** Theme Identity, Directory structure & dots-hyprland adaptation, PanelLoader & panel families, Service singleton bootstrap

---

## Theme Identity

### Q1: Theme system approach

| Option | Description | Selected |
|--------|-------------|----------|
| Catppuccin Mocha via Material tokens | Map Catppuccin hex values into Material roles | |
| Material defaults | Use dots-hyprland's Material scheme as-is | |
| Wallpaper-extracted Material | Dynamic color extraction from wallpaper | |
| You decide | Let planner pick | |

**User's choice:** "Fully embrace dots-hyprland design for everything"
**Notes:** User wants maximum fidelity to dots-hyprland, not a hybrid approach.

### Q2: Dynamic vs static palette

| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic wallpaper extraction | MaterialThemeLoader reads wallpaper and generates scheme automatically | |
| Static Material palette | Pick a fixed Material color scheme, hardcode it | ✓ |
| Dynamic with manual override | Default to wallpaper extraction with config option to lock palette | |

**User's choice:** Static Material palette
**Notes:** No wallpaper dependency.

### Q3: Seed color for static palette

| Option | Description | Selected |
|--------|-------------|----------|
| Catppuccin accent as seed | Use a Catppuccin color (lavender/mauve) as Material seed | |
| Fresh accent color | Choose a new color unrelated to Catppuccin | |
| You decide | Let planner research and pick | |

**User's choice:** "Let's pick a theme from dots-hyprland" → Use dots-hyprland's default dark vibrant scheme; planner picks accent.
**Notes:** User wants dots-hyprland's default, planner has discretion on specific accent color.

### Q4: Light/dark toggle

| Option | Description | Selected |
|--------|-------------|----------|
| Dark mode only | No light/dark toggle infrastructure | ✓ |
| Dark default with toggle scaffolding | Include toggle mechanism from dots-hyprland | |
| You decide | Let planner determine | |

**User's choice:** Dark mode only
**Notes:** Keep it simple for Phase 1.

### Q5: Widget theme token access

| Option | Description | Selected |
|--------|-------------|----------|
| Copy Appearance + m3colors wholesale | Bring over Appearance.qml and m3colors object from dots-hyprland | ✓ |
| Simpler Theme singleton | Custom Theme.qml with flat QML properties | |
| You decide | Let planner determine | |

**User's choice:** Copy Appearance + m3colors system wholesale.

### Q6: Color generation timing

| Option | Description | Selected |
|--------|-------------|----------|
| Pre-generate at build/install time | Run Python script during provisioning | |
| Generate at shell startup | Shell runs Python script on launch | |
| Ship pre-baked JSON | Commit material-colors.json directly | |
| You decide | Let planner pick | |

**User's choice:** "The same way dots-hyprland works" — follow dots-hyprland's proven approach.
**Notes:** Python script generates JSON, MaterialThemeLoader reads it. Run once during provisioning for static scheme.

---

## Directory structure & dots-hyprland adaptation

### Q1: Hierarchy depth

| Option | Description | Selected |
|--------|-------------|----------|
| Full ii/ hierarchy | Mirror dots-hyprland structure closely | ✓ |
| Simplified subset | Flatter structure like old attempt | |
| Progressive adoption | Full skeleton, only populate Phase 1 dirs | |
| You decide | Let planner determine | |

**User's choice:** Full ii/ hierarchy

### Q2: Module naming

| Option | Description | Selected |
|--------|-------------|----------|
| Keep 'ii' name | Same Illogical Impulse naming as dots-hyprland | ✓ |
| Rename to something personal | modules/qs/, modules/pera/, etc. | |
| Generic names | modules/primary/, panelFamilies/DefaultFamily/ | |
| You decide | Let planner pick | |

**User's choice:** Keep 'ii' name for maximum copy-paste compatibility.

### Q3: Deploy mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Symlink deploy | Keep arch/quickshell.sh's ln -s approach | ✓ |
| Copy deploy | cp -rf like most other configs | |
| You decide | Let planner determine | |

**User's choice:** Symlink deploy (current)

### Q4: Config system

| Option | Description | Selected |
|--------|-------------|----------|
| Include Config + Persistent + defaults | Bring over runtime config infrastructure | ✓ |
| Skip, hardcode for now | Add config system later with GUI settings | |
| You decide | Let planner determine | |

**User's choice:** Include dots-hyprland's Config + Persistent + defaults system.

---

## PanelLoader & panel families

### Q1: PanelLoader infrastructure

| Option | Description | Selected |
|--------|-------------|----------|
| Full PanelLoader + LazyLoader | Port dots-hyprland's dynamic family loading | ✓ |
| Simple direct-load | shell.qml loads bar directly, no abstraction | |
| You decide | Let planner determine | |

**User's choice:** Full PanelLoader + LazyLoader from day 1.

### Q2: Family content scope

| Option | Description | Selected |
|--------|-------------|----------|
| Bar only (top panel) | Just the bar for Phase 1 | |
| Bar + overlay scaffold | Bar plus overlay/background layer | |
| Everything from dots-hyprland | Full ii family: bar, sidebars, dock, overlay, media controls | ✓ |

**User's choice:** "Take everything. Copy-paste from dots-hyprland is easier than writing code."

### Q3: Multi-monitor behavior

| Option | Description | Selected |
|--------|-------------|----------|
| All monitors, same panel | Same bar on DP-1 and HDMI-A-2 via Quickshell.screens Variants | ✓ |
| Per-monitor config | Different layouts per monitor | |
| Primary monitor only | Only render on primary for Phase 1 | |
| You decide | Let planner match dots-hyprland default | |

**User's choice:** All monitors, same panel.

---

## Service singleton bootstrap

### Q1: Service scope

| Option | Description | Selected |
|--------|-------------|----------|
| Port all 46 services wholesale | Copy everything, same philosophy | ✓ |
| Phase 1 services only | Just enough to prove the pattern | |
| Curated subset matching Waybar | Services mapping to existing Waybar modules | |
| You decide | Let planner determine | |

**User's choice:** Port all dots-hyprland services wholesale.
**Notes:** "Services that lack backends just won't do anything yet."

### Q2: Cleanup of excluded features

| Option | Description | Selected |
|--------|-------------|----------|
| Exact copy, fix only what breaks | Port verbatim, leave dead code for excluded features | ✓ |
| Copy then strip excluded features | Remove AI/Booru/SongRec references | |
| You decide | Let planner determine | |

**User's choice:** Exact copy, fix only what breaks.

### Q3: Service registration

| Option | Description | Selected |
|--------|-------------|----------|
| Follow dots-hyprland's qmldir convention exactly | Each directory gets a manifest | ✓ |
| You decide | Let planner match dots-hyprland | |

**User's choice:** Follow dots-hyprland's qmldir convention exactly.

### Q4: Helper scripts

| Option | Description | Selected |
|--------|-------------|----------|
| Copy scripts/ wholesale | Bring over entire scripts directory | ✓ |
| Copy only Phase 1 scripts | Just colors/generate_colors_material.py and dependencies | |
| You decide | Let planner determine | |

**User's choice:** "Bringing pretty much everything would be better, would be easy to avoid errors/bugs."

---

## Agent's Discretion

- Pick a specific Material accent seed color (D-03) — planner has flexibility
- Determine file porting order and dependency resolution strategy
- Determine which import errors constitute "hard errors" vs. harmless warnings during the copy-and-fix process

## Deferred Ideas

None — discussion stayed within phase scope.
