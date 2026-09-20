# Phase 31: Overlay Infrastructure & Pill Geometry Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-20
**Phase:** 31-overlay-infrastructure-pill-geometry-foundation
**Areas discussed:** Pill Corner Radius & Geometry, Dynamic Sizing Constraints, Transition Animation, Padding & Margins, Surface & Border Styling, Overlay Architecture & Live Sync

---

## Pill Corner Radius & Geometry

| Option | Description | Selected |
|--------|-------------|----------|
| 14px | Balanced sweet spot for 30–36px bar height | |
| 16px | Maximum softness; pronounced pill aesthetic | |
| 12px | Subtle rounding; crisp modern container | |
| Default dots-hyprland (`Appearance.rounding.small` = 12px) | User explicitly stated "default hyprland is good enough" | ✓ |

**User's choice:** `default hyrpland is good enough.`
**Notes:** Retained upstream dots-hyprland default `Appearance.rounding.small` (12px), maintaining complete consistency with the desktop theme.

---

## Dynamic Pill Sizing (Root Cause & User Insight)

| Option | Description | Selected |
|--------|-------------|----------|
| Pure dynamic content sizing | Pill width strictly wraps its internal content (`contentWidth + padding * 2`), growing/shrinking automatically | ✓ |
| Dynamic sizing with minimum width floor | Pill expands dynamically with text, but keeps a minimum width | |
| Dynamic sizing with maximum width ceiling | Pill expands up to a threshold with elision | |

**User's choice:** Pure dynamic content sizing.
**Notes:** The user identified that in upstream dots-hyprland, `BarContent.qml` forcibly locked `leftCenterGroup` and `rightCenterGroup` to `implicitWidth: root.centerSideModuleWidth` (~180–200px), preventing pills from expanding when detailed date/time or metrics were rendered. Removing this clamp unlocks the native responsive math already present in `BarGroup.qml`.

---

## Width Transition Animation

| Option | Description | Selected |
|--------|-------------|----------|
| Smooth animated transitions | Animate pill width with `Appearance.animationCurves.emphasizedDecel` (250ms) for fluid stretching | ✓ |
| Instantaneous resizing | No animation; pill bounds snap immediately | |
| You decide | Agent benchmark | |

**User's choice:** Smooth animated transitions via `Appearance.animationCurves.emphasizedDecel`.
**Notes:** Implemented as a `Behavior on implicitWidth` on `BarGroup.qml`.

---

## Visual Styling & Purity Review

| Option | Description | Selected |
|--------|-------------|----------|
| Custom borders and asymmetric padding | 1px subtle borders, 8-10px horizontal padding, 6-8px gaps | |
| 100% Native dots-hyprland defaults | Default `colLayer1` fill, `padding: 5`, `spacing: 4`, standard borderless toggle | ✓ |

**User's choice:** User directive: *"i think the default dots-hyprland style is okay with me, just dynamic width of pills is my main concern, the rest of the design keep it dots-hyprland default"*.
**Notes:** Reviewed all decisions to eliminate unnecessary custom theme drift. Simplified implementation to focus squarely on fixing the dynamic width bottleneck.

---

## Overlay Architecture & Live Sync

| Option | Description | Selected |
|--------|-------------|----------|
| File-level restow overlay | `restow/quickshell/.config/quickshell/ii/modules/ii/bar/` with `--no-folding` | ✓ |
| Full bar module restow overlay | Replace entire bar directory | |
| You decide | Agent choice | |

**User's choice:** File-level restow overlay.
**Notes:** Stows only `BarContent.qml` and `BarGroup.qml`. Recoverable post-install via `cd restow && stow --verbose=5 --no-folding -t ~ quickshell`.

---

## Live Reload Method

| Option | Description | Selected |
|--------|-------------|----------|
| Reload via Hyprland keybind (`Ctrl+Super+R`) | Uses existing binding `killall ydotool qs quickshell; qs -c $qsConfig &` | ✓ |
| Automatic inotify QML reload daemon | Custom watcher script | |

**User's choice:** Reload via Hyprland keybind (`Ctrl+Super+R`) only.

---

## the agent's Discretion

- Selected 250ms duration for `emphasizedDecel` width transition animation.
- Formulated `scripts/phase31-overlay-pill-assert.sh` test plan structure.

---

## Deferred Ideas

- Auditing and customizing all 17 individual bar components (RAM `X.X GB / Y.Y GB`, CPU, Media, Weather, Tray, etc.) deferred to Phase 32.
- Modular section layout rearrangement and live trial-and-error across dual monitors deferred to Phase 33.
- Full verification and bootstrap testing deferred to Phase 34.
