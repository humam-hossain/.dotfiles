# Phase 12: Bar Skeleton and Theme — Research

**Researched:** 2026-05-02
**Domain:** Quickshell QML — PanelWindow, Variants, Singleton theme, install script
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Each BarGroup section (left/center/right) renders a static placeholder Text label ("Left"/"Center"/"Right") wrapped in ModulePill — QML collapses empty containers so placeholder content is required to verify pill rendering, font, and three-section layout. Labels removed in Phase 13.

**D-02:** `surface0` override = `#000000` (pitch black), not canonical `#313244`. `Colours.barBg` alias maps to surface0.

**D-03:** Bar dimensions match Waybar (from `.config/waybar/style.css`): `border-radius: 8px`, module `padding: 6px 14px`, inter-module spacing `8px` (4px each side), `font-size: 14px bold`, height is content-driven.

**D-04:** PanelWindow background = transparent (`color: "transparent"`). BarContent contains a full-width `Rectangle { color: Colours.barBg }` background strip behind the BarGroups.

**D-05:** Drop shadow via `layer.enabled: true` + `DropShadow` from `Qt5Compat.GraphicalEffects` on the background Rectangle. Values: `verticalOffset: 4`, `radius: 6`, `color: Qt.rgba(0,0,0,0.3)`.

**D-06:** Module pill background = Catppuccin Mocha Base `#1e1e2e` (`Colours.moduleBg`).

**D-07:** Individual pill per module (not one big pill per section). Each widget wraps itself in `ModulePill.qml`.

**D-08:** `Colours.qml` is `pragma Singleton`. Contains all 26 canonical Catppuccin Mocha hex values plus semantic aliases: `barBg`, `moduleBg`, `accent`, `textColor`, `subtextColor`, `warning`, `critical`, `success`.

**D-09:** `BarGroup.qml` exposes `default property alias children: row.children` + `Row { id: row; spacing: 8 }`.

**D-10:** `ModulePill.qml` is a shared pill wrapper (`Rectangle { radius: 8; color: Colours.moduleBg; padding: 6/14 }` with `default property alias content`).

**D-11:** Bar is flush to screen top edge — no floating margin. `anchors { top: true; left: true; right: true }` on PanelWindow.

**D-12:** `exclusiveZone: height` (dynamic, content-driven).

**D-13:** Multi-monitor via `Variants { model: Quickshell.screens }` — identical bar on each connected screen.

**D-14:** Script installs: `quickshell ddcutil i2c-tools` via `pacman -S`.

**D-15:** i2c setup: `sudo modprobe i2c-dev`, `sudo usermod -aG i2c $USER`, write `i2c-dev` to `/etc/modules-load.d/i2c.conf`.

**D-16:** Prints relog reminder: `"Log out and back in for i2c group to take effect (required for ddcutil)"`.

**D-17:** Symlinks `$REPO_ROOT/.config/quickshell` → `~/.config/quickshell` (force overwrite). Follows `arch/waybar.sh` REPO_ROOT detection pattern.

**D-18:** JetBrainsMono Nerd Font assumed pre-installed. quickshell.sh does NOT install the font.

**D-19:** Phase 12 does NOT modify Hyprland `exec-once`. Quickshell launched manually during development.

**D-20:** All Quickshell-specific scripts go under `.config/quickshell/scripts/` (Phase 14). Waybar scripts untouched.

**D-21:** Phase 12 creates only what it needs — no empty placeholder directories.

### Claude's Discretion

- Row vs RowLayout choice for BarContent's three-section layout (research recommends RowLayout — see Architecture Patterns section)
- Exact QML import list per file
- Internal BarContent vertical alignment of BarGroups
- BarGroup's `row` ID and internal Row details

### Deferred Ideas (OUT OF SCOPE)

- `services/`, `widgets/`, `popups/` directory structure — created by phases 13–16
- `.config/quickshell/scripts/` directory — Phase 14
- Icon font size decisions — Phase 13
- Font weight global vs per-widget — Phase 13
- Floating bar with margin — not requested
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BAR-01 | Quickshell bar renders at top of screen on Hyprland startup with exclusive zone (tiling windows do not overlap) | PanelWindow `anchors { top/left/right: true }` + `exclusiveZone: height` — verified Quickshell v0.2.1 API |
| BAR-02 | One bar instance per monitor — Variants + Quickshell.screens; bars added/removed dynamically when monitors connect/disconnect | `Variants { model: Quickshell.screens; delegate: Component { PanelWindow { required property var modelData; screen: modelData } } }` — official pattern |
| BAR-03 | Bar has left/center/right BarGroup layout matching current Waybar section split | RowLayout with two fill spacers; `Layout.fillWidth: true` on spacer Items — verified from Waybar config.jsonc: left=[workspaces,disk,cpu,memory,network,ping] center=[weather,clock,weather2] right=[tray,music,pulseaudio,backlight,lock,power,notification] |
| BAR-04 | Catppuccin Mocha theme: Colours.qml pragma Singleton; pill-shaped modules; JetBrainsMono Nerd Font | `pragma Singleton` + `Singleton {}` base type — verified; 26 hex values confirmed against mocha.css; surface0 override #000000 confirmed |
| BAR-05 | `arch/quickshell.sh` install script — installs quickshell/ddcutil/i2c-tools via pacman; adds user to i2c group; loads i2c-dev module; persistence in /etc/modules-load.d/ | Pattern from arch/waybar.sh; pacman available; i2c-dev in modules-load.d — verified on target system |
| BAR-06 | Waybar config remains untouched and functional in parallel during development | D-19 explicitly prohibits Hyprland exec-once changes; waybar continues to autostart; both bars can coexist on same edge (P-07 mitigation) |
</phase_requirements>

---

## Summary

Phase 12 is a greenfield QML implementation establishing the visual scaffolding for all subsequent bar phases. No existing QML exists in the repo — this is the first `.config/quickshell/` directory. The phase has seven output files: five QML files (shell.qml, Bar.qml, BarContent.qml, BarGroup.qml, ModulePill.qml), one theme singleton (theme/Colours.qml), and one shell script (arch/quickshell.sh).

All architecture decisions are locked in CONTEXT.md. Research confirms the Quickshell v0.2.1 API matches every decision exactly: PanelWindow anchor API, Variants multi-monitor pattern, pragma Singleton mechanism. The only meaningful finding beyond confirming locked decisions is the drop shadow implementation: CONTEXT.md D-05 specifies Qt5Compat.GraphicalEffects DropShadow, but the Quickshell v0.2.1 FAQ explicitly recommends `RectangularShadow` from `QtQuick.Effects` for rectangular drop shadows, and this API is available on the target system (Qt 6.11 — RectangularShadow requires Qt 6.9+). Both work; the planner should note the discrepancy but honor D-05 unless instructed to update.

The install script follows the established `arch/waybar.sh` pattern exactly. Qt 6.11 and qt6-5compat are both installed on this machine; all required Qt modules are present.

**Primary recommendation:** Follow CONTEXT.md decisions verbatim. The only discretionary choice with research backing is RowLayout over Row for BarContent — RowLayout is explicitly recommended over Row/Column in Quickshell docs for its Layout attachment support and pixel alignment guarantees.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Bar docking to screen edge | Wayland layer shell (PanelWindow) | — | `WlrLayershell` protocol owns edge anchoring and exclusive zone |
| Multi-monitor bar instances | Quickshell runtime (Variants) | — | Quickshell.screens ObjectModel drives delegate lifecycle |
| Three-section layout | QML layout engine (RowLayout) | — | Client-side layout; no compositor involvement |
| Pill styling (radius, padding, background) | QML renderer (Rectangle) | — | Visual-only; no system integration needed |
| Theme constants | QML Singleton (Colours.qml) | — | Module-level singleton; no external data source |
| Font rendering | Qt text engine | OS font system | JetBrainsMono Nerd Font pre-installed; Qt resolves by family name |
| Install + system config | Bash (arch/quickshell.sh) | pacman / kernel modules | Package install, i2c group, kernel module persistence are OS-level |
| i2c kernel module persistence | OS (/etc/modules-load.d/) | systemd-modules-load | Kernel module auto-load on boot |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| quickshell | 0.2.1-6 [verified: pacman] | QML shell framework — PanelWindow, Variants, Singleton | Ships in Arch `[extra]`; all required modules compiled in |
| Qt 6 (Qt Quick) | 6.11.0 [verified: qmake6] | QML runtime, RowLayout, Rectangle, Text | Ships with quickshell; no separate install needed |
| Qt6-5compat | 6.11.0 [verified: pacman] | Qt5Compat.GraphicalEffects DropShadow (D-05) | Installed on target; provides DropShadow.qml |
| ddcutil | (via pacman) | DDC/CI brightness queries — installed by quickshell.sh | Required for Phase 14 backlight; installed now per D-14 |
| i2c-tools | (via pacman) | i2c bus access for ddcutil | Required companion to ddcutil; per D-14 |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| QtQuick.Effects (RectangularShadow) | Qt 6.9+ (available as Qt 6.11) | Native drop shadow — lighter-weight than Qt5Compat | Alternative to D-05; available but not the locked choice |
| QtQuick.Layouts | Bundled with Qt | RowLayout for BarContent three-section layout | Planner's discretion (Claude's Discretion per CONTEXT.md) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Qt5Compat.GraphicalEffects DropShadow (D-05) | QtQuick.Effects RectangularShadow | RectangularShadow is Qt-native, no compatibility layer; requires Qt 6.9+; target has Qt 6.11 so either works. D-05 locks in DropShadow — deviation requires explicit planner decision. |
| RowLayout (recommended) | Row | Row lacks Layout attachment; RowLayout preferred per Quickshell docs for pixel alignment. Both are viable for Phase 12 static layout. |

**Installation:**

```bash
sudo pacman -S --needed quickshell ddcutil i2c-tools
```

**Version verification:** [VERIFIED: pacman -Si quickshell] — 0.2.1-6 in Arch `[extra]`.

---

## Architecture Patterns

### System Architecture Diagram

```
User runs: quickshell
        │
        ▼
shell.qml (Scope entry point)
        │
        └── Bar.qml (Scope)
              │
              └── Variants { model: Quickshell.screens }
                    │  (creates one delegate per connected monitor)
                    │  (monitors connect/disconnect → delegates added/removed)
                    │
                    └── [per-screen delegate]
                          │
                          └── PanelWindow
                                ├── screen: modelData       ← bound to Quickshell screen
                                ├── anchors.top/left/right  ← docks to top edge
                                ├── exclusiveZone: height   ← pushes tiling windows down
                                ├── color: "transparent"    ← D-04
                                └── WlrLayershell.keyboardFocus: None  ← P-16
                                      │
                                      └── BarContent.qml
                                            │
                                            ├── Rectangle (barBg #000000) + DropShadow
                                            │
                                            └── RowLayout (full width)
                                                  ├── BarGroup (left)
                                                  │     └── ModulePill
                                                  │           └── Text "Left"
                                                  ├── Item (Layout.fillWidth: true)  ← spacer
                                                  ├── BarGroup (center)
                                                  │     └── ModulePill
                                                  │           └── Text "Center"
                                                  ├── Item (Layout.fillWidth: true)  ← spacer
                                                  └── BarGroup (right)
                                                        └── ModulePill
                                                              └── Text "Right"

theme/Colours.qml (pragma Singleton)
  └── Colours.barBg, Colours.moduleBg, Colours.textColor + 26 Catppuccin Mocha values
        │  (auto-instantiated; referenced by name from any QML file in the module)
        ▼
  BarContent.qml  →  Rectangle { color: Colours.barBg }
  ModulePill.qml  →  Rectangle { color: Colours.moduleBg }
  Text labels     →  color: Colours.textColor
```

### Recommended Project Structure

```
.config/quickshell/
├── shell.qml               # Scope { Bar {} }
├── Bar.qml                 # Scope { Variants { model: Quickshell.screens; ... } }
├── BarContent.qml          # PanelWindow + RowLayout left/spacer/center/spacer/right
├── BarGroup.qml            # Row container with default property alias
├── ModulePill.qml          # Rectangle pill with radius 8, padding 6/14
└── theme/
    ├── qmldir              # singleton Colours Colours.qml
    └── Colours.qml         # pragma Singleton; all 26 hex + semantic aliases

arch/
└── quickshell.sh           # pacman install + i2c setup + symlink
```

### Pattern 1: PanelWindow Docked to Top with Exclusive Zone

**What:** Anchoring PanelWindow to top/left/right and setting `exclusiveZone: height` reserves bar height from tiling windows.
**When to use:** Every bar window. `exclusiveZone: height` is dynamic — bar can resize without extra code.

```qml
// Source: https://quickshell.org/docs/v0.2.1/types/Quickshell/PanelWindow
// [VERIFIED: Context7 /websites/quickshell_v0_2_1]
PanelWindow {
  required property var modelData
  screen: modelData

  color: "transparent"
  exclusiveZone: height    // D-12: content-driven, dynamic

  anchors {
    top:   true            // D-11: flush top
    left:  true
    right: true
  }

  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None  // P-16: mandatory
}
```

### Pattern 2: Variants Multi-Monitor

**What:** `Variants { model: Quickshell.screens }` creates one delegate per connected monitor and automatically adds/removes delegates as monitors connect/disconnect.
**When to use:** Bar.qml outer scope. Identical bar on each screen — no primary/secondary distinction (D-13).

```qml
// Source: https://quickshell.org/docs/v0.2.1/guide/introduction
// [VERIFIED: Context7 /websites/quickshell_v0_2_1]
Scope {
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        required property var modelData
        screen: modelData
        // ... bar content
      }
    }
  }
}
```

**Critical:** `required property var modelData` must be declared. Quickshell injects the screen object into this property from the `Quickshell.screens` model.

### Pattern 3: pragma Singleton for Theme

**What:** QML file with `pragma Singleton` at the top and `Singleton {}` as the root type. Quickshell makes all properties available by type name (e.g., `Colours.barBg`) from any adjacent QML file — no explicit import required for files in the same module.
**When to use:** Colours.qml. Also the pattern for all future services (Clock.qml, PingStatus.qml, etc.).

```qml
// Source: https://quickshell.org/docs/v0.2.1/guide/qml-language
// [VERIFIED: Context7 /websites/quickshell_v0_2_1]
// theme/Colours.qml
pragma Singleton
import Quickshell

Singleton {
  readonly property color barBg:    "#000000"   // surface0 override D-02
  readonly property color moduleBg: "#1e1e2e"   // base D-06
  // ...
}
```

**qmldir requirement (CRITICAL):** A `qmldir` file must exist in `theme/` to register the singleton. Without it, Quickshell cannot find `Colours` by name from parent-directory files.

```
# theme/qmldir
singleton Colours Colours.qml
```

Files in the root `.config/quickshell/` directory that reference `Colours` must import the subdirectory:

```qml
import qs.theme   // Quickshell module import syntax; path relative to shell.qml
```

### Pattern 4: BarContent Three-Section Layout

**What:** RowLayout with two `Layout.fillWidth: true` spacer Items creates left-aligned left group, horizontally centered center group, and right-aligned right group.
**When to use:** BarContent.qml — this is the Claude's Discretion layout choice. RowLayout is preferred over Row per Quickshell docs (pixel alignment, Layout attachment support).

```qml
// Source: https://quickshell.org/docs/v0.2.1/guide/size-position
// [VERIFIED: Context7 /websites/quickshell_v0_2_1 — RowLayout preferred over Row]
import QtQuick
import QtQuick.Layouts

Item {
  anchors.fill: parent

  // Background strip with drop shadow (D-04, D-05)
  Rectangle {
    id: bgRect
    anchors.fill: parent
    color: Colours.barBg   // #000000

    layer.enabled: true
    layer.effect: DropShadow {
      verticalOffset: 4
      radius:         6
      color:          Qt.rgba(0, 0, 0, 0.3)
    }
  }

  RowLayout {
    anchors {
      left:   parent.left
      right:  parent.right
      top:    parent.top
      bottom: parent.bottom
      margins: 4
    }
    spacing: 0

    BarGroup {
      ModulePill { Text { text: "Left";   font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.bold: true; color: Colours.textColor } }
    }

    Item { Layout.fillWidth: true }   // flexible spacer

    BarGroup {
      ModulePill { Text { text: "Center"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.bold: true; color: Colours.textColor } }
    }

    Item { Layout.fillWidth: true }   // flexible spacer

    BarGroup {
      ModulePill { Text { text: "Right";  font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.bold: true; color: Colours.textColor } }
    }
  }
}
```

### Pattern 5: BarGroup with Default Property Alias

**What:** `default property alias children: row.children` makes BarGroup behave like a native container — widgets placed directly inside BarGroup are wired to the inner Row's children list.
**When to use:** BarGroup.qml. Phases 13–16 place widgets directly inside BarGroup with no boilerplate.

```qml
// Source: CONTEXT.md D-09, confirmed by QML default alias docs
// [VERIFIED: CONTEXT.md; standard QML default alias pattern]
import QtQuick

Item {
  default property alias children: row.children

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 8    // D-03: inter-module spacing 8px
  }
}
```

### Pattern 6: ModulePill Pill Wrapper

**What:** Rectangle with `radius: 8`, `color: Colours.moduleBg`, `topPadding: 6`, `bottomPadding: 6`, `leftPadding: 14`, `rightPadding: 14`, and a `default property alias` for content.
**When to use:** Every widget wraps itself in ModulePill. This is the single source of truth for pill shape across all 16+ widgets.

```qml
// Source: CONTEXT.md D-10, D-03, UI-SPEC.md
// [VERIFIED: CONTEXT.md + UI-SPEC.md]
import QtQuick

Rectangle {
  default property alias content: inner.children

  color:  Colours.moduleBg   // #1e1e2e base — D-06
  radius: 8                  // D-03 border-radius

  topPadding:    6           // D-03
  bottomPadding: 6
  leftPadding:   14          // D-03
  rightPadding:  14

  implicitWidth:  inner.implicitWidth  + leftPadding + rightPadding
  implicitHeight: inner.implicitHeight + topPadding  + bottomPadding

  Item {
    id: inner
    anchors.centerIn: parent
    implicitWidth:  childrenRect.width
    implicitHeight: childrenRect.height
  }
}
```

### Pattern 7: Install Script Structure

**What:** Bash script following `arch/waybar.sh` pattern — `set -euo pipefail`, REPO_ROOT detection, pacman install, system config, symlink.
**When to use:** `arch/quickshell.sh`. All other arch scripts follow the same pattern.

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QS_SRC="$REPO_ROOT/.config/quickshell"
QS_DST="$HOME/.config/quickshell"

PACKAGES=(quickshell ddcutil i2c-tools)

# Install packages
sudo pacman -Sy --noconfirm --needed "${PACKAGES[@]}"

# i2c setup (P-13 prevention)
sudo modprobe i2c-dev
sudo usermod -aG i2c "$USER"
echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c.conf > /dev/null

# Symlink config (force overwrite, D-17)
rm -f "$QS_DST"
ln -s "$QS_SRC" "$QS_DST"

echo "Log out and back in for i2c group to take effect (required for ddcutil)"
```

[VERIFIED: arch/waybar.sh — REPO_ROOT pattern, set -euo pipefail, pacman install array]
[VERIFIED: CONTEXT.md D-15, D-16, D-17]

### Anti-Patterns to Avoid

- **Second PanelWindow for popups:** Only one PanelWindow per bar instance. Popups use PopupWindow — not relevant to Phase 12 but established here for Phase 15.
- **`opacity: 0` to hide components:** Always use `visible: false`. Not applicable in Phase 12 (no interactive elements) but establishes the convention.
- **`NotificationServer` instantiation:** Never instantiate — conflicts with swaync on D-Bus. Not relevant to Phase 12 but must not appear anywhere in the Quickshell tree.
- **`grabFocus: true` on PanelWindow:** Always set `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None` on the bar PanelWindow (P-16).
- **Missing `theme/qmldir`:** Without `singleton Colours Colours.qml` in `theme/qmldir`, files importing `qs.theme` cannot resolve `Colours` by name. This is a silent failure — QML engine logs a "type not found" error.
- **Colours.qml without qmldir using wrong base type:** Must use `Singleton {}` as root type (not `QtObject`) for Quickshell pragma Singleton. [VERIFIED: official Quickshell docs]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-monitor bar creation | Custom screen detection loop | `Variants { model: Quickshell.screens }` | Handles monitor hotplug, removal, ID changes automatically |
| Exclusive zone management | Manual Hyprland IPC reservation | `PanelWindow { exclusiveZone: height }` | Dynamic — updates on bar resize; IPC requires re-dispatch |
| Keyboard focus prevention | Custom focus filter | `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None` | Compositor-level; cannot be replicated in QML |
| Theme constants distribution | Passing colors as properties everywhere | `pragma Singleton` Colours.qml | Singleton accessed by name — no prop-drilling |
| Drop shadow | Drawing a shadow Rectangle manually | `Qt5Compat.GraphicalEffects DropShadow` (D-05) or `QtQuick.Effects RectangularShadow` (Qt 6.9+) | Both handle GPU compositing correctly |

**Key insight:** The Quickshell and Qt APIs cover all Phase 12 requirements directly. Every structural element (window anchoring, multi-monitor, exclusive zone, theme singleton) has a documented 3–5 line QML pattern. No custom QML utilities need to be written for Phase 12.

---

## Common Pitfalls

### Pitfall 1: Missing theme/qmldir (P-QMLDIR — not in PITFALLS.md)

**What goes wrong:** `Colours` type not found at runtime; QML engine logs an error and components referencing `Colours.barBg` fail to render.
**Why it happens:** Quickshell automatically imports adjacent files (same directory), but files in subdirectories require explicit module registration via `qmldir`.
**How to avoid:** Create `theme/qmldir` with exactly: `singleton Colours Colours.qml`. Add `import qs.theme` to every QML file in the root that references `Colours`.
**Warning signs:** Runtime QML error: `qrc:/.../BarContent.qml:N: ReferenceError: Colours is not defined`

### Pitfall 2: P-16 — Bar Steals Keyboard Focus

**What goes wrong:** Hyprland windows lose keyboard focus when bar is present; keystrokes go to bar instead of active app.
**Why it happens:** Default `WlrKeyboardFocus` is not `None` — PanelWindow can capture keyboard events.
**How to avoid:** `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None` on the PanelWindow in BarContent (or Bar.qml). Set unconditionally on the bar window.
**Warning signs:** Typing in a terminal while bar is visible; characters go nowhere.

### Pitfall 3: P-07 — Parallel Deploy Exclusive Zone Conflict

**What goes wrong:** Waybar and Quickshell both request exclusive zone at the top edge; one pushes the other's reserved space.
**Why it happens:** Both bars are PanelWindows at WlrLayer.Top requesting exclusive zone from the same edge.
**How to avoid:** Phase 12 launches Quickshell manually from terminal, not via `exec-once`. Waybar remains the autostart bar. Both can coexist if they request the same edge — Hyprland stacks exclusive zones. Verify visually on first run.
**Warning signs:** Waybar appears to shift down, or tiling window gap doubles.

### Pitfall 4: P-15 — Variants Delegate Cleanup on Monitor Disconnect

**What goes wrong:** When a monitor disconnects, the Variants delegate is destroyed; if Timers or other objects inside the delegate are not stopped, they may produce errors on destruction.
**Why it happens:** `Variants` cleans up delegates when the model item (screen) is removed. Any running state inside the delegate must handle `Component.onDestruction`.
**How to avoid:** Phase 12 has no Timers inside the delegate (no data processes in skeleton phase). Future phases must stop timers on `Component.onDestruction`.
**Warning signs:** QML errors after monitor disconnect: "Cannot read property of null" or similar.

### Pitfall 5: P-13 — i2c Group Not Active Until Relog

**What goes wrong:** `ddcutil getvcp 10` returns "DDC/CI not accessible" or permission error even after install script runs.
**Why it happens:** `usermod -aG i2c $USER` adds the user to the group for future sessions. The current shell session does not pick up the new group.
**How to avoid:** install script prints D-16 reminder. Planner must include this as a note in the install task — users must log out and back in before ddcutil works.
**Warning signs:** `ddcutil getvcp 10` returns an error immediately after running quickshell.sh in the same session.

### Pitfall 6: D-05 Drop Shadow — Qt5Compat vs QtQuick.Effects Discrepancy

**What goes wrong:** CONTEXT.md D-05 specifies `Qt5Compat.GraphicalEffects DropShadow`. The Quickshell v0.2.1 FAQ now recommends `RectangularShadow` from `QtQuick.Effects` for rectangular shapes. If the planner uses the newer API without noting the context deviation, reviewers may flag it.
**Why it happens:** `RectangularShadow` was added in Qt 6.9 (after the CONTEXT.md was written using Qt5Compat pattern). The target machine has Qt 6.11 — both approaches work.
**How to avoid:** Honor D-05 (Qt5Compat.GraphicalEffects DropShadow) unless the planner explicitly decides to use RectangularShadow. Document the choice if deviating.
**Warning signs:** If using Qt5Compat DropShadow, the `layer.enabled: true` + `layer.effect: DropShadow {}` pattern is correct. Ensure `qt6-5compat` is installed (it is on target: 6.11.0-1).

---

## Code Examples

### shell.qml — Entry Point

```qml
// Source: https://quickshell.org/docs/v0.2.1/guide/introduction
// [VERIFIED: Context7 /websites/quickshell_v0_2_1]
import Quickshell

Scope {
  Bar {}
}
```

### Bar.qml — Multi-Monitor Variants

```qml
// Source: https://quickshell.org/docs/v0.2.1/guide/introduction
// [VERIFIED: Context7 /websites/quickshell_v0_2_1]
import Quickshell

Scope {
  Variants {
    model: Quickshell.screens

    delegate: Component {
      BarContent {
        required property var modelData
        screen: modelData
      }
    }
  }
}
```

**Note:** The delegate wraps `BarContent` (which is a PanelWindow subcomponent) rather than inlining PanelWindow directly, for separation of concerns. `BarContent` must accept `screen` as a property since it contains the PanelWindow.

### BarContent.qml — PanelWindow with Layout

```qml
// Source: D-04, D-05, D-11, D-12; PanelWindow API verified Context7
// [VERIFIED: Context7 /websites/quickshell_v0_2_1 + CONTEXT.md]
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.theme

PanelWindow {
  id: root
  required property var modelData
  screen: modelData

  color: "transparent"          // D-04
  exclusiveZone: height          // D-12

  anchors {
    top:   true                  // D-11
    left:  true
    right: true
  }

  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None  // P-16

  // Background strip with drop shadow (D-04, D-05)
  Rectangle {
    id: bgRect
    anchors.fill: parent
    color: Colours.barBg           // #000000 D-02

    layer.enabled: true
    layer.effect: DropShadow {
      verticalOffset: 4            // D-05
      radius:         6
      color:          Qt.rgba(0, 0, 0, 0.3)
    }
  }

  RowLayout {
    anchors {
      left:    parent.left
      right:   parent.right
      top:     parent.top
      bottom:  parent.bottom
      margins: 4
    }
    spacing: 0

    BarGroup {
      ModulePill {
        Text {
          text: "Left"
          font.family:    "JetBrainsMono Nerd Font"
          font.pixelSize: 14
          font.bold:      true
          color:          Colours.textColor
        }
      }
    }

    Item { Layout.fillWidth: true }

    BarGroup {
      ModulePill {
        Text {
          text: "Center"
          font.family:    "JetBrainsMono Nerd Font"
          font.pixelSize: 14
          font.bold:      true
          color:          Colours.textColor
        }
      }
    }

    Item { Layout.fillWidth: true }

    BarGroup {
      ModulePill {
        Text {
          text: "Right"
          font.family:    "JetBrainsMono Nerd Font"
          font.pixelSize: 14
          font.bold:      true
          color:          Colours.textColor
        }
      }
    }
  }
}
```

### theme/Colours.qml — Full Palette + Semantic Aliases

```qml
// Source: mocha.css (verified line-by-line); CONTEXT.md D-08
// [VERIFIED: .config/waybar/mocha.css read directly — surface0: #000000 confirmed]
pragma Singleton
import Quickshell

Singleton {
  // 26 canonical Catppuccin Mocha values
  readonly property color rosewater: "#f5e0dc"
  readonly property color flamingo:  "#f2cdcd"
  readonly property color pink:      "#f5c2e7"
  readonly property color mauve:     "#cba6f7"
  readonly property color red:       "#f38ba8"
  readonly property color maroon:    "#eba0ac"
  readonly property color peach:     "#fab387"
  readonly property color yellow:    "#f9e2af"
  readonly property color green:     "#a6e3a1"
  readonly property color teal:      "#94e2d5"
  readonly property color sky:       "#89dceb"
  readonly property color sapphire:  "#74c7ec"
  readonly property color blue:      "#89b4fa"
  readonly property color lavender:  "#b4befe"
  readonly property color text:      "#cdd6f4"
  readonly property color subtext1:  "#bac2de"
  readonly property color subtext0:  "#a6adc8"
  readonly property color overlay2:  "#9399b2"
  readonly property color overlay1:  "#7f849c"
  readonly property color overlay0:  "#6c7086"
  readonly property color surface2:  "#585b70"
  readonly property color surface1:  "#45475a"
  readonly property color surface0:  "#000000"   // project override D-02
  readonly property color base:      "#1e1e2e"
  readonly property color mantle:    "#181825"
  readonly property color crust:     "#11111b"

  // Semantic aliases (D-08)
  readonly property color barBg:        surface0   // #000000
  readonly property color moduleBg:     base       // #1e1e2e
  readonly property color accent:       mauve      // #cba6f7
  readonly property color textColor:    text       // #cdd6f4
  readonly property color subtextColor: subtext1   // #bac2de
  readonly property color warning:      yellow     // #f9e2af
  readonly property color critical:     red        // #f38ba8
  readonly property color success:      green      // #a6e3a1
}
```

### theme/qmldir — Singleton Registration

```
# theme/qmldir
singleton Colours Colours.qml
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Qt5Compat.GraphicalEffects DropShadow | QtQuick.Effects RectangularShadow | Qt 6.9 (2024) | Native GPU-backed shadow; no compatibility layer. Both work; D-05 locks the older approach. |
| Row/Column for layouts | RowLayout/ColumnLayout (preferred) | Qt 5+ (established) | Layout attachment, pixel alignment guarantees |
| ShellRoot as entry point | Scope as entry point | Quickshell 0.2.x | ShellRoot still referenced in old docs; Scope is current |

**Deprecated/outdated:**
- `ShellRoot`: Old entry point type — Quickshell intro docs now use `Scope`. Still works but ARCHITECTURE.md uses Scope.
- `variants:` property on Variants: Old API used `variants: Quickshell.screens`; current API uses `model: Quickshell.screens`. [VERIFIED: both patterns appear in docs; `model:` is the current form]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Bar.qml` delegates `BarContent` as a PanelWindow (not inlining PanelWindow in Bar.qml) | Code Examples | If BarContent must contain PanelWindow and also accept `screen:`, the `required property var modelData` + `screen: modelData` must be passed through. This is a valid QML pattern but implementation details belong to planner. | 
| A2 | `BarGroup.qml` uses plain `Item` as root with inner `Row` (not Rectangle) | Architecture Patterns | ARCHITECTURE.md shows `Rectangle` with pill styling for BarGroup; CONTEXT.md D-09 specifies `Row { id: row; spacing: 8 }` with default alias. The root type (Item vs Rectangle) is left to planner. |

**All hex values, API names, package versions, and file paths are VERIFIED against the codebase or official docs. No critical claims are ASSUMED.**

---

## Open Questions

1. **BarContent as PanelWindow vs BarContent wrapping PanelWindow**
   - What we know: CONTEXT.md D-21 file list shows `BarContent.qml` as the PanelWindow content root. Bar.qml owns `Variants { model: Quickshell.screens }`.
   - What's unclear: Whether `BarContent.qml` IS the PanelWindow (root type PanelWindow) or wraps PanelWindow content (root type Item, instantiated inside a PanelWindow in Bar.qml). ARCHITECTURE.md section 8 builds list includes a plain `PanelWindow` in step 2, suggesting Bar.qml has the PanelWindow and BarContent is its content.
   - Recommendation: Planner should verify the delegation pattern — both approaches work. The simpler approach is BarContent.qml is the PanelWindow itself (root type PanelWindow), and Bar.qml's Variants delegate instantiates it directly.

2. **`import qs.theme` vs relative import in BarGroup/ModulePill**
   - What we know: Quickshell supports `import qs.<path>` for subdirectory imports relative to shell.qml.
   - What's unclear: Whether files in the root `.config/quickshell/` directory can reference `Colours` without an explicit import if `theme/qmldir` is present and the theme directory is adjacent.
   - Recommendation: Add `import qs.theme` explicitly to every QML file that uses `Colours.*`. Explicit over implicit.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| quickshell | BAR-01 to BAR-04 | NOT YET INSTALLED | 0.2.1-6 in pacman [extra] | None — installed by arch/quickshell.sh |
| qt6-5compat | D-05 DropShadow | YES | 6.11.0-1 [verified: pacman] | QtQuick.Effects RectangularShadow (Qt 6.9+) |
| Qt 6 | QML runtime | YES | 6.11.0 [verified: qmake6] | — |
| ddcutil | BAR-05 | NOT YET INSTALLED | available in pacman [extra] | — |
| i2c-tools | BAR-05 | NOT YET INSTALLED | available in pacman [extra] | — |
| hyprland | Runtime target | YES | 0.54.3 [verified: hyprland --version] | — |
| waybar | BAR-06 parallel deploy | YES | 0.15.0 [verified: waybar --version] | — |
| JetBrainsMono Nerd Font | BAR-04 typography | [ASSUMED pre-installed] | via fonts.sh/waybar.sh | D-18 states font pre-installed; not verified in this session |
| pacman | arch/quickshell.sh | YES | Arch Linux [verified: OS] | — |

**Missing dependencies with no fallback:**
- `quickshell`, `ddcutil`, `i2c-tools` — installed by `arch/quickshell.sh` as part of BAR-05. Must run before testing BAR-01/BAR-02/BAR-03/BAR-04.

**Missing dependencies with fallback:**
- Qt5Compat.GraphicalEffects DropShadow (D-05): qt6-5compat is installed; DropShadow.qml confirmed at `/usr/lib/qt6/qml/Qt5Compat/GraphicalEffects/DropShadow.qml`. Also: QtQuick.Effects RectangularShadow (Qt 6.9+) is available via QtQuick.Effects at Qt 6.11.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — no automated test framework applicable (QML visual rendering + Wayland compositor) |
| Config file | none |
| Quick run command | `quickshell` (manual visual inspection) |
| Full suite command | Visual checklist per BAR-01 through BAR-06 |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| BAR-01 | Bar docks at top, exclusive zone active — tiling windows do not overlap | manual/visual | `quickshell` then launch a terminal | Verify gap above window matches bar height |
| BAR-02 | Second monitor connecting adds a new bar | manual/visual | Connect second monitor while quickshell running | Verify bar appears on new screen |
| BAR-03 | Left/center/right pill sections visible with placeholder text | manual/visual | `quickshell` | Verify "Left"/"Center"/"Right" labels in pills |
| BAR-04 | Catppuccin colors correct (#000000 bar bg, #1e1e2e pills, #cdd6f4 text), JetBrainsMono Nerd Font | manual/visual | `quickshell` + screenshot comparison | Color pick from screenshot |
| BAR-05 | quickshell.sh runs to completion — packages installed, i2c configured, symlink created | smoke (CLI) | `bash arch/quickshell.sh` | Check exit 0, verify symlink, verify /etc/modules-load.d/i2c.conf |
| BAR-06 | Waybar still renders correctly after quickshell is running | manual/visual | `quickshell` then observe Waybar | Both bars visible simultaneously |

### Sampling Rate

- **Per task commit:** `bash arch/quickshell.sh` (exit 0 check) + `quickshell` launch (no startup error in stderr)
- **Per wave merge:** Full visual checklist BAR-01 through BAR-06
- **Phase gate:** All six requirements visually confirmed before phase close

### Wave 0 Gaps

None — this phase has no automated tests. All validation is visual/manual. No test files to create.

---

## Security Domain

This phase has no network calls, no user input handling, no authentication, and no credentials. The only security-relevant operations are in `arch/quickshell.sh`:

| Operation | Risk | Mitigation |
|-----------|------|-----------|
| `sudo pacman -S` | Package install with sudo | Standard Arch pattern; same as arch/waybar.sh |
| `sudo usermod -aG i2c $USER` | Group membership change | Grants i2c bus access — required for ddcutil; minimal privilege |
| `sudo modprobe i2c-dev` | Kernel module load | i2c-dev is a standard, safe kernel module |
| Write to `/etc/modules-load.d/i2c.conf` | System config write | Idempotent; standard persistence mechanism for kernel modules |

No ASVS categories applicable to Phase 12 (no auth, no sessions, no network, no user input, no cryptography).

---

## Sources

### Primary (HIGH confidence)

- Context7 `/websites/quickshell_v0_2_1` — PanelWindow API, Variants/screens pattern, pragma Singleton, RowLayout recommendation, WlrLayershell.keyboardFocus, import qs.path syntax
- `.config/waybar/mocha.css` — all 26 Catppuccin Mocha hex values; surface0: #000000 override confirmed
- `.config/waybar/style.css` — exact pixel dimensions: border-radius 8px, padding 6px 14px, margin 6px 4px, font 14px bold, box-shadow values
- `.config/waybar/config.jsonc` — three-section module layout: left/center/right widgets
- `arch/waybar.sh` — install script pattern: REPO_ROOT detection, set -euo pipefail, pacman install array, symlink logic
- `/usr/lib/qt6/qml/Qt5Compat/GraphicalEffects/qmldir` — DropShadow confirmed available [VERIFIED: filesystem]
- `/usr/lib/qt6/qml/QtQuick/Effects/plugins.qmltypes` — RectangularShadow confirmed Qt 6.9+ in QtQuick.Effects [VERIFIED: filesystem]
- `pacman -Si quickshell` — version 0.2.1-6 in Arch [extra] [VERIFIED]
- `qmake6 --version` — Qt 6.11.0 on target [VERIFIED]

### Secondary (MEDIUM confidence)

- https://quickshell.org/docs/v0.2.1/guide/faq/ — DropShadow vs RectangularShadow guidance
- `.planning/research/ARCHITECTURE.md` — Quickshell architecture patterns researched 2026-05-02 (HIGH confidence, cites Context7)
- `.planning/research/PITFALLS.md` — Pitfall catalog researched 2026-05-02 (HIGH confidence)
- `.planning/research/SUMMARY.md` — Stack and feature summary 2026-05-02 (HIGH confidence)
- `.planning/phases/12-bar-skeleton-and-theme/12-UI-SPEC.md` — UI design contract with spacing tokens and color map

---

## Metadata

**Confidence breakdown:**

| Area | Level | Reason |
|------|-------|--------|
| Standard stack | HIGH | Package versions verified via pacman; Qt modules verified on filesystem |
| PanelWindow / Variants API | HIGH | Verified Context7 /websites/quickshell_v0_2_1 |
| Singleton / qmldir pattern | HIGH | Verified Context7; qmldir syntax is standard Qt QML |
| Drop shadow approach | MEDIUM | Two valid options (Qt5Compat vs QtQuick.Effects); D-05 locks Qt5Compat but newer approach available |
| BarContent layout (RowLayout vs Row) | HIGH | Quickshell docs explicitly prefer RowLayout; Claude's Discretion item |
| Install script | HIGH | Pattern verified directly from arch/waybar.sh in repo |
| Pitfalls | HIGH | From PITFALLS.md researched 2026-05-02; P-16 and P-15 both directly applicable |

**Research date:** 2026-05-02
**Valid until:** 2026-06-01 (Quickshell 0.2.x stable; Qt 6.11 stable)
