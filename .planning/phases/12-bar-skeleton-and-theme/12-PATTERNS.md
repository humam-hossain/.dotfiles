# Phase 12: Bar Skeleton and Theme — Pattern Map

**Mapped:** 2026-05-02
**Files analyzed:** 8
**Analogs found:** 1 / 8 (7 are greenfield QML with no prior QML in repo)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.config/quickshell/shell.qml` | config/entry-point | request-response | none — greenfield QML | no analog |
| `.config/quickshell/Bar.qml` | provider/scope | event-driven (monitor hotplug) | none — greenfield QML | no analog |
| `.config/quickshell/BarContent.qml` | component/window | request-response | none — greenfield QML | no analog |
| `.config/quickshell/BarGroup.qml` | component/container | transform | none — greenfield QML | no analog |
| `.config/quickshell/ModulePill.qml` | component/wrapper | transform | none — greenfield QML | no analog |
| `.config/quickshell/theme/Colours.qml` | config/singleton | transform | none — greenfield QML | no analog |
| `.config/quickshell/theme/qmldir` | config/registration | — | none — greenfield QML | no analog |
| `arch/quickshell.sh` | utility/install-script | batch | `arch/waybar.sh` | role-match |

---

## Pattern Assignments

### `arch/quickshell.sh` (utility, batch)

**Analog:** `arch/waybar.sh` (`/home/pera/github_repo/.dotfiles/arch/waybar.sh`)

**Match Quality:** role-match. Same role (install script), same data flow (batch: install packages, configure system, sync files). Different scope: quickshell.sh is simpler — single symlink instead of MANAGED_FILES array.

**Shebang + safety flags** (lines 1–3):
```bash
#!/usr/bin/env bash
set -euo pipefail
set -x
```

**REPO_ROOT detection pattern** (lines 5–7):
```bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAYBAR_SRC="$REPO_ROOT/.config/waybar"
WAYBAR_DST="$HOME/.config/waybar"
```
For quickshell.sh substitute `waybar` → `quickshell`:
```bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QS_SRC="$REPO_ROOT/.config/quickshell"
QS_DST="$HOME/.config/quickshell"
```

**PACKAGES array + pacman install pattern** (lines 9–24 and 72–75):
```bash
PACKAGES=(
  waybar
  curl
  # ... more packages
)

install_packages() {
  echo "[INSTALL] waybar and runtime dependencies"
  sudo pacman -Sy --noconfirm --needed "${PACKAGES[@]}"
}
```
For quickshell.sh:
```bash
PACKAGES=(quickshell ddcutil i2c-tools)

install_packages() {
  echo "[INSTALL] quickshell and runtime dependencies"
  sudo pacman -Sy --noconfirm --needed "${PACKAGES[@]}"
}
```

**main() dispatcher pattern** (lines 140–148):
```bash
main() {
  install_packages
  ensure_dirs
  sync_managed_files
  cleanup_stale_files
  verify_file_presence
  print_summary
}

main "$@"
```
For quickshell.sh, main() is simpler:
```bash
main() {
  install_packages
  setup_i2c
  symlink_config
  print_summary
}

main "$@"
```

**echo label convention** (consistent throughout waybar.sh):
```bash
echo "[INSTALL] ..."
echo "[CONFIG] ..."
echo "[VERIFY] ..."
echo "[DONE] ..."
```
quickshell.sh must use the same bracket-label convention.

**Note on symlink approach vs waybar.sh file-copy approach:** waybar.sh uses `install -Dm"$mode"` per-file copy. quickshell.sh uses a single directory symlink (`rm -f "$QS_DST"; ln -s "$QS_SRC" "$QS_DST"`) per D-17 — a deliberate divergence from waybar.sh's approach, matching the simpler single-config-dir pattern.

---

### `.config/quickshell/shell.qml` (config, entry-point)

**Analog:** none — greenfield QML.

**Pattern source:** RESEARCH.md Pattern 2 (Scope entry point). No existing analog in repo.

**Core pattern** (from RESEARCH.md Code Examples):
```qml
import Quickshell

Scope {
  Bar {}
}
```

**Key constraint:** `Scope` is the current Quickshell entry point type. `ShellRoot` is deprecated. No import other than `import Quickshell` is needed here.

---

### `.config/quickshell/Bar.qml` (provider/scope, event-driven)

**Analog:** none — greenfield QML.

**Pattern source:** RESEARCH.md Pattern 2 (Variants multi-monitor).

**Core pattern** (from RESEARCH.md Code Examples):
```qml
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

**Critical constraint:** `required property var modelData` must be declared inside the delegate. Quickshell injects the screen object from `Quickshell.screens` into this property. Omitting `required` causes silent failure — the bar renders but `screen` binding is undefined.

**Note on delegate type:** The delegate instantiates `BarContent` directly (BarContent.qml IS the PanelWindow). This is the simpler approach vs inlining PanelWindow in Bar.qml. BarContent must declare `required property var modelData` and bind `screen: modelData`.

---

### `.config/quickshell/BarContent.qml` (component/window, request-response)

**Analog:** none — greenfield QML.

**Pattern source:** RESEARCH.md Pattern 1 (PanelWindow docking), Pattern 3 (BarContent layout), CONTEXT.md D-04/D-05/D-11/D-12, UI-SPEC.md Layout Contract.

**Import block pattern** (from RESEARCH.md Code Examples, BarContent.qml section):
```qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.theme
```

**PanelWindow docking + keyboard focus pattern** (RESEARCH.md Pattern 1):
```qml
PanelWindow {
  id: root
  required property var modelData
  screen: modelData

  color: "transparent"          // D-04
  exclusiveZone: height          // D-12: dynamic, content-driven

  anchors {
    top:   true                  // D-11: flush top, no margin
    left:  true
    right: true
  }

  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None  // P-16: mandatory
```

**Background Rectangle with DropShadow** (CONTEXT.md D-04, D-05; UI-SPEC.md Drop Shadow):
```qml
  Rectangle {
    id: bgRect
    anchors.fill: parent
    color: Colours.barBg           // #000000 D-02

    layer.enabled: true
    layer.effect: DropShadow {
      verticalOffset: 4            // D-05: mirrors box-shadow: 0 4px 6px rgba(0,0,0,0.3)
      horizontalOffset: 0
      radius:         6
      color:          Qt.rgba(0, 0, 0, 0.3)
    }
  }
```

**Three-section RowLayout** (RESEARCH.md Pattern 3; Claude's Discretion: RowLayout over Row):
```qml
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
          text:           "Left"
          font.family:    "JetBrainsMono Nerd Font"
          font.pixelSize: 14
          font.bold:      true
          color:          Colours.textColor
        }
      }
    }

    Item { Layout.fillWidth: true }   // flexible spacer — centers the center group

    BarGroup {
      ModulePill {
        Text { text: "Center"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.bold: true; color: Colours.textColor }
      }
    }

    Item { Layout.fillWidth: true }   // flexible spacer

    BarGroup {
      ModulePill {
        Text { text: "Right"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.bold: true; color: Colours.textColor }
      }
    }
  }
}
```

**Why RowLayout over Row:** RowLayout is explicitly preferred in Quickshell docs for `Layout.fillWidth` attachment support and pixel alignment guarantees. Row lacks Layout attachment — `Layout.fillWidth: true` on spacer Items only works inside a RowLayout.

---

### `.config/quickshell/BarGroup.qml` (component/container, transform)

**Analog:** none — greenfield QML.

**Pattern source:** RESEARCH.md Pattern 5 (BarGroup with default property alias), CONTEXT.md D-09.

**Core pattern** (RESEARCH.md Pattern 5):
```qml
import QtQuick

Item {
  default property alias children: row.children

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 8    // D-03: inter-module spacing 8px (4px margin each side in Waybar)
  }
}
```

**Key constraint:** `default property alias children: row.children` is what makes BarGroup behave as a native QML container — phases 13–16 place widgets directly inside BarGroup with no boilerplate. The alias wires to the inner Row's `children`, not BarGroup's own children. Without `default`, downstream phases must write `BarGroup { row.children: [...] }` instead of `BarGroup { MyWidget {} }`.

---

### `.config/quickshell/ModulePill.qml` (component/wrapper, transform)

**Analog:** none — greenfield QML.

**Pattern source:** RESEARCH.md Pattern 6 (ModulePill pill wrapper), CONTEXT.md D-10, D-03, UI-SPEC.md Component Inventory.

**Core pattern** (RESEARCH.md Pattern 6):
```qml
import QtQuick
import qs.theme

Rectangle {
  default property alias content: inner.children

  color:  Colours.moduleBg   // #1e1e2e base — D-06
  radius: 8                  // D-03: border-radius 8px

  topPadding:    6           // D-03: padding 6px 14px
  bottomPadding: 6
  leftPadding:   14
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

**Key constraint:** `default property alias content: inner.children` (not `children`) — using `content` avoids shadowing QML's built-in `children` property on Rectangle, which would break the Rectangle's own child management. The alias name `content` is conventional for wrapper components in QML.

**Sizing strategy:** `implicitWidth`/`implicitHeight` driven by inner content + padding. Do not set explicit `width`/`height` — let content size drive the pill. This is critical for phases 13–16 where pill content varies per widget.

---

### `.config/quickshell/theme/Colours.qml` (config/singleton, transform)

**Analog:** none — greenfield QML.

**Pattern source:** RESEARCH.md Pattern 3 (pragma Singleton), CONTEXT.md D-08, UI-SPEC.md Color section.

**Singleton declaration + root type** (RESEARCH.md Pattern 3):
```qml
pragma Singleton
import Quickshell

Singleton {
  // ...properties
}
```

**Critical constraint:** Root type must be `Singleton {}` (Quickshell type), NOT `QtObject`. Using `QtObject` with `pragma Singleton` is a different pattern (Qt-native singleton) and does not integrate with Quickshell's module system for `import qs.theme`.

**Full property pattern** (from RESEARCH.md Code Examples, Colours.qml section):
```qml
pragma Singleton
import Quickshell

Singleton {
  // 26 canonical Catppuccin Mocha hex values
  readonly property color rosewater: "#f5e0dc"
  readonly property color flamingo:  "#f2cdcd"
  // ... (all 26 — see UI-SPEC.md Color table for complete list)
  readonly property color surface0:  "#000000"   // D-02 project override
  readonly property color base:      "#1e1e2e"
  // ...

  // Semantic aliases (D-08) — aliases reference the color properties above
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

**All properties must be `readonly property color`** — not `string`. QML color type enables property binding and `Qt.rgba()` interop that string does not.

---

### `.config/quickshell/theme/qmldir` (config/registration)

**Analog:** none — no existing qmldir files in repo.

**Pattern source:** RESEARCH.md Pattern 3 (qmldir requirement), Pitfall 1 (missing qmldir).

**Complete file content:**
```
singleton Colours Colours.qml
```

**Critical constraint:** This file must exist at `.config/quickshell/theme/qmldir` exactly. Without it, any QML file importing `qs.theme` cannot resolve `Colours` by type name. Failure is a runtime error: `ReferenceError: Colours is not defined`. The file has no shebang, no comments required — exactly one line.

---

## Shared Patterns

### Import for Theme Access
**Apply to:** `BarContent.qml`, `BarGroup.qml`, `ModulePill.qml`, and all future widget files
```qml
import qs.theme
```
This import is required in every QML file that references `Colours.*`. Files in the root `.config/quickshell/` directory do NOT automatically see files in `theme/` subdirectory — explicit import is mandatory (see Pitfall 1 in RESEARCH.md).

### Keyboard Focus Safety
**Apply to:** Every PanelWindow (BarContent.qml in Phase 12; any future bar window)
```qml
WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
```
Must be set unconditionally. Omission causes Hyprland windows to lose keyboard focus while the bar is present (P-16).

### Font Declaration
**Apply to:** Every `Text {}` element in Phase 12 and all future widget text
```qml
font.family:    "JetBrainsMono Nerd Font"
font.pixelSize: 14
font.bold:      true
```
Source: `.config/waybar/style.css` lines 5–7 (global `*` selector). Exact match required for visual parity with Waybar.

### Echo Label Convention (install scripts)
**Apply to:** `arch/quickshell.sh` — consistent with `arch/waybar.sh` and all other arch scripts
```bash
echo "[INSTALL] ..."
echo "[CONFIG] ..."
echo "[CLEANUP] ..."
echo "[VERIFY] ..."
echo "[DONE] ..."
```

---

## No Analog Found

All QML files have no close match because no QML exists anywhere in the repository. Patterns are sourced entirely from RESEARCH.md verified code examples and CONTEXT.md locked decisions.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.config/quickshell/shell.qml` | config/entry-point | request-response | First QML file in repo — greenfield |
| `.config/quickshell/Bar.qml` | provider/scope | event-driven | No Variants/multi-monitor pattern exists in repo |
| `.config/quickshell/BarContent.qml` | component/window | request-response | No PanelWindow pattern exists in repo |
| `.config/quickshell/BarGroup.qml` | component/container | transform | No QML container component exists in repo |
| `.config/quickshell/ModulePill.qml` | component/wrapper | transform | No QML wrapper component exists in repo |
| `.config/quickshell/theme/Colours.qml` | config/singleton | transform | No QML singleton exists in repo |
| `.config/quickshell/theme/qmldir` | config/registration | — | No qmldir files exist in repo |

**Planner action for no-analog files:** Use RESEARCH.md code examples verbatim. All patterns are VERIFIED against Quickshell v0.2.1 API (Context7) and the existing Waybar CSS dimensions. No invention needed — every file has a complete, verified code example in RESEARCH.md.

---

## Analog Search Scope

**Directories searched:**
- `/home/pera/github_repo/.dotfiles/arch/` — install scripts (analog for quickshell.sh found: waybar.sh)
- `/home/pera/github_repo/.dotfiles/.config/` — all config subdirectories
- Full repo `find` for `*.qml` and `qmldir` — zero results confirmed

**Files scanned:** `arch/waybar.sh`, `arch/hyprland.sh`, `arch/fonts.sh`, `arch/system_monitor.sh`, `.config/waybar/style.css`, `.config/waybar/config.jsonc`

**QML files in repo:** 0 (confirmed via filesystem search)

**Pattern extraction date:** 2026-05-02
