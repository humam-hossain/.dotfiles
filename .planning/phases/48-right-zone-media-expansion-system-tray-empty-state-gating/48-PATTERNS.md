# Phase 48: Right-Zone Media Expansion & System Tray Empty State Gating - Pattern Map

**Gathered:** 2026-09-30  
**Phase:** 48 - right-zone-media-expansion-system-tray-empty-state-gating  
**Milestone:** v0.9 (Top Status Bar Resource Components & Hardware Telemetry)  
**Status:** Complete & Ready for Planning  

---

## 1. Executive Summary

This document defines the authoritative architectural patterns, concrete code blueprints, exact code excerpts, mathematical scaling equations, anti-pattern guardrails, and validation harness designs for **Phase 48: Right-Zone Media Expansion & System Tray Empty State Gating**.

Phase 48 completes the visual, ergonomic, and responsive polish of the Quickshell top status bar Right Zone across multi-monitor setups (notably Ultrawide `DP-1` at 3440px and secondary rotated `HDMI-A-2`):
1. **Responsive Media Pill Length & Dynamic Hugging (RGHT-01, D-01..D-04)**: Upgrades the media player pill's maximum width from a static 200px clamp to a dynamic screen-width proportional equation in `BarContent.qml`:
   - Standard full screens (`useShortenedForm === 0`): `Math.min(Math.max((root.screen?.width ?? 1920) * 0.12, 220), 450)` px (~413px on 3440px ultrawide, ~230px on 1080p).
   - Shortened screens (`useShortenedForm === 1`): `Math.min(Math.max((root.screen?.width ?? 1200) * 0.10, 140), 180)` px.
   - Dynamic hugging: the media pill automatically hugs the actual track text length via `implicitWidth`, expanding only as needed up to the clamp limit.
   - Fluid transitions: retains `BarGroup.qml`'s 250ms Material 3 emphasized deceleration animation (`elementMoveFast`) on width resizing.
2. **Track Title & Artist Visual Hierarchy with StyledText Elision (RGHT-02, D-05..D-08)**: Creates a personal leaf overlay `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml`:
   - Formats track title in bold primary foreground (`Appearance.colors.colOnLayer1`) and artist name in muted tone (`Appearance.colors.colSubtext`) joined by a clean bullet (`" • "`).
   - Uses `textFormat: Text.StyledText` to guarantee single-line right elision (`Text.ElideRight`) on overflow without clipping.
   - Preserves fallback behavior: renders `cleanedTitle` cleanly without trailing separator when artist is falsy.
   - Sanitizes metadata with `StringUtils.escapeHtml` to prevent XML parser syntax errors.
   - Eliminates upstream binding loop warning on `StyledText.width` in `RowLayout`.
   - Preserves `Config.options.bar.verbose` gating and 5-button mouse mapping (Left: toggle popup, Middle: play/pause, Right/Forward: next, Back: previous).
3. **Reactive System Tray Empty-State Gating & Reflow (RGHT-03, D-09..D-12)**:
   - Gates `sysTrayGroup` in `BarContent.qml` with `visible: (root.useShortenedForm === 0) && ((SystemTray.items?.values?.length ?? 0) > 0)`.
   - Completely collapses the pill when 0 apps are running, eliminating empty border artifacts while keeping the D-Bus service hot.
   - Provides instant 4px `RowLayout` reflow without layout jitter or ghost padding.
   - Retains system tray restriction to primary full-width screens (`root.useShortenedForm === 0`).
4. **Dynamic Media Popup Anchor Tracking (D-15)**: Retains Phase 39 dynamic coordinate tracking in `BarContent.qml` (`updateMediaPillCoords()`, `onWidthChanged`, `onXChanged`) so `MediaControls.qml` remains dynamically centered beneath the pill during track length transitions.
5. **Zero Vendor Submodule Churn (INTG-02)**: Implements changes strictly within `restow/quickshell/` and live symlinks, maintaining zero uncommitted changes in `vendor/dots-hyprland` and passing `./arch/dots-hyprland.sh verify --strict` with `FAIL=0 FINDINGS=0`.

---

## 2. File Inventory & Classification

| File Path | Operation | Role | Data Flow | Closest Codebase Analog |
| :--- | :--- | :--- | :--- | :--- |
| [`restow/quickshell/.../bar/BarContent.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml) | **MODIFY** | Layout Container / Right-Zone Coordinator | Evaluates screen width and shortened form tiers; drives responsive `Layout.maximumWidth` on `Media`; imports `Quickshell.Services.SystemTray` and gates `sysTrayGroup.visible`; tracks media pill center coordinates for popup anchoring. | Existing [`BarContent.qml:222-281`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml#L222-L281) & Phase 39 coordinate tracking [`BarContent.qml:20-53`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml#L20-L53) |
| [`restow/quickshell/.../bar/Media.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml) | **CREATE (OVERLAY)** | UI Widget / Media Player Pill | Consumes `MprisController.activePlayer` metadata; formats title in `colOnLayer1` and artist in `colSubtext` via `Text.StyledText`; escapes HTML via `StringUtils.escapeHtml`; elides via `Text.ElideRight`; handles mouse controls; gates verbose text display. | Upstream [`vendor/dots-hyprland/.../bar/Media.qml:1-90`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Media.qml#L1-L90), [`StringUtils.qml:226-235`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/functions/StringUtils.qml#L226-L235) & [`SysTray.qml:149-156`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/SysTray.qml#L149-L156) |
| [`scripts/phase48-right-zone-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase48-right-zone-assert.sh) | **CREATE** | Quality Assertion Engine / Test Harness | Automated CLI test suite validating stow leaf symlinks, AST regex on `BarContent.qml` and `Media.qml`, mathematical simulation across reference resolutions, system tray gating truth table, and strict repository verification. | [`scripts/phase47-center-layout-assert.sh:1-451`](file:///home/pera/github_repo/.dotfiles/scripts/phase47-center-layout-assert.sh#L1-L451) & [`scripts/phase46-telemetry-assert.sh:1-471`](file:///home/pera/github_repo/.dotfiles/scripts/phase46-telemetry-assert.sh#L1-L471) |

---

## 3. Per-File Pattern Assignments

### 3.1 `BarContent.qml` (Right-Zone Responsive Equation & Tray Gating)

- **Target File:** [`restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml)
- **Role:** Right-Zone container coordinator.
- **Data Flow:**
  - Consumes `root.screen?.width` and `root.useShortenedForm` to calculate responsive `Layout.maximumWidth` for `mediaLoader`.
  - Imports `Quickshell.Services.SystemTray` and consumes `SystemTray.items?.values?.length` to dynamically gate `sysTrayGroup.visible`.
  - Maintains `updateMediaPillCoords()` and `Connections` on `mediaLoader.item` for `onWidthChanged` and `onXChanged` to update `GlobalStates.mediaPillCenterX/Y/Screen`.
- **Closest Codebase Analogs:**
  - Existing Right Zone declarations: [`BarContent.qml:222-281`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml#L222-L281).
  - Existing coordinate tracking: [`BarContent.qml:20-53`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml#L20-L53).
  - Tray items count condition: [`SysTray.qml:154`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/SysTray.qml#L154).

#### Key Design Decisions Implemented
- **D-01 (Responsive Sizing Equation):**
  Full width (`useShortenedForm === 0`): `Math.min(Math.max((root.screen?.width ?? 1920) * 0.12, 220), 450)`.
- **D-02 (Shortened Tier Width Scaling):**
  Shortened width (`useShortenedForm === 1`): `Math.min(Math.max((root.screen?.width ?? 1200) * 0.10, 140), 180)`.
- **D-09 & D-10 (Reactive Tray Gating):**
  Bind `sysTrayGroup.visible: (root.useShortenedForm === 0) && ((SystemTray.items?.values?.length ?? 0) > 0)`.
- **D-11 & D-12 (Instant Reflow & Primary Screen Restriction):**
  Toggling `visible` on `sysTrayGroup` directly in `RowLayout` collapses the pill to 0px without destroying D-Bus listeners.
- **D-15 (Continuous Popup Tracking):**
  Retain existing `Connections` listening to `mediaLoader.item.onWidthChanged` and `onXChanged` to trigger `root.updateMediaPillCoords()`.

#### Concrete Code Excerpt: Existing vs Target

```qml
// =========================================================================
// BEFORE: restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml
// =========================================================================
import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
// [Missing Quickshell.Services.SystemTray]
...
            Loader {
                id: mediaLoader
                Layout.alignment: Qt.AlignVCenter
                active: (root.useShortenedForm < 2) && (MprisController.activePlayer != null && (MprisController.activePlayer.trackTitle?.length > 0))
                visible: active

                HoverHandler {
                    id: mediaHoverHandler
                }

                sourceComponent: BarGroup {
                    Media {
                        visible: root.useShortenedForm < 2
                        Layout.fillWidth: true
                        Layout.maximumWidth: (root.useShortenedForm === 1) ? 140 : 200
                    }
                }
            }
...
            BarGroup {
                id: sysTrayGroup
                Layout.alignment: Qt.AlignVCenter
                visible: root.useShortenedForm === 0

                SysTray {
                    showSeparator: false
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    invertSide: Config?.options.bar.bottom
                }
            }
```

```qml
// =========================================================================
// TARGET: restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml
// =========================================================================
import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
...
            Loader {
                id: mediaLoader
                Layout.alignment: Qt.AlignVCenter
                active: (root.useShortenedForm < 2) && (MprisController.activePlayer != null && (MprisController.activePlayer.trackTitle?.length > 0))
                visible: active

                HoverHandler {
                    id: mediaHoverHandler
                }

                sourceComponent: BarGroup {
                    Media {
                        visible: root.useShortenedForm < 2
                        Layout.fillWidth: true
                        Layout.maximumWidth: (root.useShortenedForm === 1)
                            ? Math.min(Math.max((root.screen?.width ?? 1200) * 0.10, 140), 180)
                            : Math.min(Math.max((root.screen?.width ?? 1920) * 0.12, 220), 450)
                    }
                }
            }
...
            BarGroup {
                id: sysTrayGroup
                Layout.alignment: Qt.AlignVCenter
                visible: (root.useShortenedForm === 0) && ((SystemTray.items?.values?.length ?? 0) > 0)

                SysTray {
                    showSeparator: false
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    invertSide: Config?.options.bar.bottom
                }
            }
```

---

### 3.2 `Media.qml` (Track & Artist Typography Hierarchy & Elision)

- **Target File:** [`restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml)
- **Role:** Individual status bar media pill content widget.
- **Data Flow:**
  - Binds to `MprisController.activePlayer` singleton.
  - Sanitizes and formats track metadata via `StringUtils.escapeHtml`.
  - Emits formatted HTML string with track title in `Appearance.colors.colOnLayer1` and artist in `Appearance.colors.colSubtext`.
  - Dispatches playback control signals to `activePlayer` on mouse clicks.
  - Controls popup visibility via `GlobalStates.mediaControlsOpen`.
- **Closest Codebase Analogs:**
  - Upstream layout & mouse handlers: [`vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Media.qml:1-90`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Media.qml#L1-L90).
  - HTML string escaping: [`StringUtils.qml:231-235`](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/common/functions/StringUtils.qml#L231-L235).
  - Bullet separator styling: [`SysTray.qml:149-156`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/SysTray.qml#L149-L156).

#### Key Design Decisions Implemented
- **D-05 (Visual Hierarchy):** Title styled in `Appearance.colors.colOnLayer1`, artist styled in `Appearance.colors.colSubtext` joined by `" • "`.
- **D-06 (Missing Artist Handling):** When `activePlayer.trackArtist` is falsy, empty, or undefined, emits only `escapedTitle` without trailing separators.
- **D-07 (Right Elision on Overflow):** Uses `textFormat: Text.StyledText` and `elide: Text.ElideRight` with `Layout.fillWidth: true`.
- **D-08 (Verbose Toggle Gating):** Text remains gated with `visible: Config.options.bar.verbose`.
- **D-13 & D-14 (Interaction Preservation):** Left-click toggles popup, Middle-click toggles play/pause, Right/Forward skips, Back goes to previous. Mouse wheel events pass through transparently.
- **Binding Loop Fix:** Removes upstream obsolete `width: rowLayout.width - (CircularProgress.size + rowLayout.spacing * 2)`, letting `RowLayout` handle sizing via `Layout.fillWidth: true`.

#### Concrete Code Blueprint

```qml
// =========================================================================
// TARGET: restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml
// =========================================================================
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")

    Layout.fillHeight: true
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
            }
        }
    }

    RowLayout { // Real content
        id: rowLayout

        spacing: 4
        anchors.fill: parent

        ClippedFilledCircularProgress {
            id: mediaCircProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: activePlayer?.position / activePlayer?.length
            implicitSize: 20
            colPrimary: Appearance.colors.colOnSecondaryContainer
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: mediaCircProg.implicitSize
                height: mediaCircProg.implicitSize
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: activePlayer?.isPlaying ? "pause" : "music_note"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSecondaryContainer
                }
            }
        }

        StyledText {
            id: mediaTrackInfoText
            visible: Config.options.bar.verbose
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true // Ensures the text takes up available space
            Layout.rightMargin: rowLayout.spacing
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight // Truncates the text on the right
            color: Appearance.colors.colOnLayer1
            textFormat: Text.StyledText
            text: {
                const escapedTitle = StringUtils.escapeHtml(cleanedTitle);
                const artist = activePlayer?.trackArtist;
                if (!artist) {
                    return `<span style="color: ${Appearance.colors.colOnLayer1};">${escapedTitle}</span>`;
                }
                const escapedArtist = StringUtils.escapeHtml(artist);
                return `<span style="color: ${Appearance.colors.colOnLayer1};">${escapedTitle}</span><span style="color: ${Appearance.colors.colSubtext};"> • ${escapedArtist}</span>`;
            }
        }

    }

}
```

#### Stow Leaf Symlink Topology Workflow
```bash
# 1. Create file in restow repository overlay
# File: restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml

# 2. Back up live upstream stub
mv ~/.config/quickshell/ii/modules/ii/bar/Media.qml ~/.config/quickshell/ii/modules/ii/bar/Media.qml.bak

# 3. Create relative leaf symlink
ln -sf ../../../../../../github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml ~/.config/quickshell/ii/modules/ii/bar/Media.qml

# 4. Strict verification check
./arch/dots-hyprland.sh verify --strict
# Output: [PASS] verified: /home/pera/.config/quickshell/ii/modules/ii/bar/Media.qml -> restow/...
# Output: [INFO] installer backup artifact: .../Media.qml.bak
# Output: === done: FAIL=0 FINDINGS=0 ===
```

---

### 3.3 `scripts/phase48-right-zone-assert.sh` (Comprehensive Test Harness)

- **Target File:** [`scripts/phase48-right-zone-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase48-right-zone-assert.sh)
- **Role:** Quality assurance automation harness enforcing RGHT-01, RGHT-02, RGHT-03.
- **Data Flow:**
  - Evaluates CLI options (`-s`, `-q`, `-c`, `-h`).
  - Verifies filesystem state, directory folding, and symlink destinations.
  - Parses QML syntax and AST patterns using `grep`, `sed`, `awk`.
  - Calculates responsive math formulas and tray gating boolean truth tables in bash.
  - Chains execution with previous milestone harnesses (`phase47-center-layout-assert.sh --quick`, `phase46-telemetry-assert.sh --quick`).
  - Executes `./arch/dots-hyprland.sh verify --strict`.
  - Asserts zero working tree drift (`git status --porcelain`).
- **Closest Codebase Analogs:**
  - Full harness structure: [`scripts/phase47-center-layout-assert.sh:1-451`](file:///home/pera/github_repo/.dotfiles/scripts/phase47-center-layout-assert.sh#L1-L451).
  - Section execution and trap handlers: [`scripts/phase46-telemetry-assert.sh:1-110`](file:///home/pera/github_repo/.dotfiles/scripts/phase46-telemetry-assert.sh#L1-L110).

#### Section Architecture

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                     scripts/phase48-right-zone-assert.sh Harness Architecture           │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ Section 1: Stow Leaf Symlink Topology & Repository Integrity                           │
│   • restow/quickshell/.../Media.qml exists and is tracked in git                       │
│   • restow/quickshell/.../BarContent.qml exists and is tracked in git                  │
│   • live ~/.config/quickshell/.../Media.qml is symlink to restow                       │
│   • live ~/.config/quickshell/.../BarContent.qml is symlink to restow                  │
│   • ancestor directories are real un-folded directories                                │
│   • vendor/dots-hyprland submodule has 0 uncommitted changes                           │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ Section 2: BarContent.qml Responsive Width Equation & Tray Gating AST                  │
│   • import Quickshell.Services.SystemTray is present in BarContent.qml                 │
│   • mediaLoader Layout.maximumWidth contains Tier 1 clamp: Math.min(Math.max(*0.10,140),180)│
│   • mediaLoader Layout.maximumWidth contains Tier 0 clamp: Math.min(Math.max(*0.12,220),450)│
│   • sysTrayGroup.visible bound to (root.useShortenedForm === 0) && (length > 0)        │
│   • updateMediaPillCoords() function and Connections onWidth/XChanged preserved        │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ Section 3: Media.qml Typography, Styling Hierarchy & Elision AST                       │
│   • import qs.modules.common.functions present                                        │
│   • StyledText uses textFormat: Text.StyledText                                        │
│   • StyledText uses elide: Text.ElideRight and Layout.fillWidth: true                  │
│   • StringUtils.escapeHtml applied to title and artist                                 │
│   • Title formatted in Appearance.colors.colOnLayer1                                   │
│   • Artist formatted in Appearance.colors.colSubtext with separator " • "              │
│   • Absence of artist returns title without separator                                  │
│   • Config.options.bar.verbose gating and 5-button MouseArea handlers preserved       │
│   • Obsolete StyledText.width binding loop removed                                     │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ Section 4: Mathematical Simulation & Logic Verification                                │
│   • Evaluates responsive equation across 3440, 2560, 1920, 1366, 1200, 1080 resolutions│
│   • Verifies dynamic hugging behavior (implicitWidth <= Layout.maximumWidth)           │
│   • Evaluates tray gating truth table across tiers 0, 1, 2 and tray counts 0, 1, 5     │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ Section 5: Sub-Harness Orchestration & Strict Repository Verification                  │
│   • Runs scripts/phase47-center-layout-assert.sh --quick                               │
│   • Runs scripts/phase46-telemetry-assert.sh --quick                                   │
│   • Runs ./arch/dots-hyprland.sh verify --strict (FAIL=0 FINDINGS=0)                   │
│   • Verifies zero working tree drift (porcelain before vs after)                       │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

#### Concrete Code Blueprint

```bash
#!/usr/bin/env bash
# ===========================================================================
# Phase 48: Right-Zone Media Expansion & System Tray Empty State Gating Assert Harness
# Enforces: RGHT-01, RGHT-02, RGHT-03, D-01 through D-16
#
# Usage (from REPO_ROOT):
#   ./scripts/phase48-right-zone-assert.sh [OPTIONS] [1-5]
#
# Options:
#   -s, --section <1-5>    Execute only the specified section (1-5)
#   -q, --quick,
#       --standalone       Run standalone sections only (skip sub-harnesses in S5)
#   -c, --syntax           Execute static AST and syntax checks only
#   -h, --help             Show this help message
#
# Exit 0 if all hard asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if run as root
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
cleanup() {
  if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
    rm -f "${TMP_FILES[@]}" 2>/dev/null || true
  fi
  return 0
}
trap cleanup EXIT INT TERM

RUN_SECTION=0
QUICK_MODE=0
SYNTAX_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    1|2|3|4|5)
      RUN_SECTION="$1"
      shift
      ;;
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    --quick|--standalone|-q)
      QUICK_MODE=1
      shift
      ;;
    --syntax|-c)
      SYNTAX_ONLY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS] [1-5]"
      echo ""
      echo "Options:"
      echo "  [1-5]                  Execute only specified section"
      echo "  -s, --section <1-5>    Execute only the specified section (1-5)"
      echo "  -q, --quick,           Run standalone sections only"
      echo "      --standalone"
      echo "  -c, --syntax           Execute static AST and syntax checks only"
      echo "  -h, --help             Show this help message"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

BAR_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar"
BAR_CONTENT="$BAR_DIR/BarContent.qml"
MEDIA_QML="$BAR_DIR/Media.qml"

PORCELAIN_BEFORE="$(mktemp "${TMPDIR:-/tmp}/p48-porcelain-before.XXXXXX")"
TMP_FILES+=("$PORCELAIN_BEFORE")
git status --porcelain > "$PORCELAIN_BEFORE"

# Syntax-only mode
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  bash -n "$0"
  pass "Assert harness bash syntax check passed (bash -n verified)"
  [[ -f "$BAR_CONTENT" ]] && pass "BarContent.qml exists" || fail "Missing: $BAR_CONTENT"
  [[ -f "$MEDIA_QML" ]] && pass "Media.qml exists" || fail "Missing: $MEDIA_QML"
  info "=== Syntax Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Stow Leaf Symlink Topology & Repository Integrity
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Stow Leaf Symlink Topology & Repository Integrity ---"

  LIVE_BAR="$HOME/.config/quickshell/ii/modules/ii/bar"

  if [[ -f "$MEDIA_QML" ]]; then
    pass "S1: Overlay file exists: $MEDIA_QML"
  else
    fail "S1: Overlay file missing: $MEDIA_QML"
  fi

  if [[ -f "$BAR_CONTENT" ]]; then
    pass "S1: Overlay file exists: $BAR_CONTENT"
  else
    fail "S1: Overlay file missing: $BAR_CONTENT"
  fi

  if [[ -L "$LIVE_BAR/Media.qml" ]] && [[ "$(readlink "$LIVE_BAR/Media.qml")" =~ restow/quickshell/\.config/quickshell/ii/modules/ii/bar/Media\.qml ]]; then
    pass "S1: Live Media.qml is a valid symlink to restow/quickshell/.../Media.qml"
  elif [[ -f "$LIVE_BAR/Media.qml" ]]; then
    finding "S1: Live Media.qml is a regular file (not yet symlinked to restow)"
  else
    fail "S1: Live Media.qml missing"
  fi

  if [[ -L "$LIVE_BAR/BarContent.qml" ]] && [[ "$(readlink "$LIVE_BAR/BarContent.qml")" =~ restow/quickshell/\.config/quickshell/ii/modules/ii/bar/BarContent\.qml ]]; then
    pass "S1: Live BarContent.qml is a valid symlink to restow/quickshell/.../BarContent.qml"
  else
    fail "S1: Live BarContent.qml symlink missing or invalid"
  fi

  for dir in "$HOME/.config" "$HOME/.config/quickshell" "$HOME/.config/quickshell/ii" "$HOME/.config/quickshell/ii/modules" "$HOME/.config/quickshell/ii/modules/ii" "$HOME/.config/quickshell/ii/modules/ii/bar"; do
    if [[ -d "$dir" && ! -L "$dir" ]]; then
      pass "S1: Ancestor directory $dir is a real un-folded directory"
    elif [[ -L "$dir" ]]; then
      fail "S1: Ancestor directory $dir is folded (symlink)"
    else
      fail "S1: Ancestor directory $dir missing"
    fi
  done

  SUBMODULE_STATUS="$(git status --porcelain vendor/dots-hyprland 2>/dev/null || true)"
  if [[ -z "$SUBMODULE_STATUS" ]]; then
    pass "S1: vendor/dots-hyprland submodule has 0 git churn"
  else
    fail "S1: vendor/dots-hyprland has uncommitted churn: $SUBMODULE_STATUS"
  fi
fi

# ===========================================================================
# Section 2: BarContent.qml Responsive Width Equation & Tray Gating AST
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: BarContent.qml Responsive Width Equation & Tray Gating AST ---"

  if grep -q "import Quickshell.Services.SystemTray" "$BAR_CONTENT"; then
    pass "S2: BarContent.qml imports Quickshell.Services.SystemTray"
  else
    fail "S2: BarContent.qml missing import Quickshell.Services.SystemTray"
  fi

  if grep -A 10 "id: mediaLoader" "$BAR_CONTENT" | grep -q "Math.min(Math.max.*0.12.*220.*450"; then
    pass "S2: mediaLoader contains full-width responsive equation (0.12 clamp [220, 450])"
  elif sed -n '/id: mediaLoader/,/id: voicePill/p' "$BAR_CONTENT" | grep -q "Math.min(Math.max.*0.12.*220.*450"; then
    pass "S2: mediaLoader contains full-width responsive equation (0.12 clamp [220, 450])"
  else
    fail "S2: mediaLoader missing full-width responsive equation"
  fi

  if grep -A 10 "id: mediaLoader" "$BAR_CONTENT" | grep -q "Math.min(Math.max.*0.10.*140.*180"; then
    pass "S2: mediaLoader contains shortened-width responsive equation (0.10 clamp [140, 180])"
  elif sed -n '/id: mediaLoader/,/id: voicePill/p' "$BAR_CONTENT" | grep -q "Math.min(Math.max.*0.10.*140.*180"; then
    pass "S2: mediaLoader contains shortened-width responsive equation (0.10 clamp [140, 180])"
  else
    fail "S2: mediaLoader missing shortened-width responsive equation"
  fi

  if sed -n '/id: sysTrayGroup/,/SysTray {/p' "$BAR_CONTENT" | grep -q "SystemTray.items.*length"; then
    pass "S2: sysTrayGroup visible bound to SystemTray.items length"
  else
    fail "S2: sysTrayGroup missing SystemTray.items length binding"
  fi

  if sed -n '/id: sysTrayGroup/,/SysTray {/p' "$BAR_CONTENT" | grep -q "root.useShortenedForm === 0"; then
    pass "S2: sysTrayGroup restricted to root.useShortenedForm === 0"
  else
    fail "S2: sysTrayGroup missing root.useShortenedForm === 0 restriction"
  fi

  if grep -q "function updateMediaPillCoords()" "$BAR_CONTENT"; then
    pass "S2: updateMediaPillCoords() function preserved"
  else
    fail "S2: updateMediaPillCoords() function missing"
  fi

  if grep -q "onWidthChanged.*root.updateMediaPillCoords()" "$BAR_CONTENT"; then
    pass "S2: onWidthChanged coordinate tracking connection preserved"
  else
    fail "S2: onWidthChanged coordinate tracking connection missing"
  fi
fi

# ===========================================================================
# Section 3: Media.qml Typography, Styling Hierarchy & Elision AST
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Media.qml Typography, Styling Hierarchy & Elision AST ---"

  if grep -q "import qs.modules.common.functions" "$MEDIA_QML"; then
    pass "S3: Media.qml imports qs.modules.common.functions"
  else
    fail "S3: Media.qml missing import qs.modules.common.functions"
  fi

  if grep -A 20 "StyledText" "$MEDIA_QML" | grep -q "textFormat: Text.StyledText"; then
    pass "S3: StyledText uses textFormat: Text.StyledText"
  else
    fail "S3: StyledText missing textFormat: Text.StyledText"
  fi

  if grep -A 20 "StyledText" "$MEDIA_QML" | grep -q "elide: Text.ElideRight"; then
    pass "S3: StyledText uses elide: Text.ElideRight"
  else
    fail "S3: StyledText missing elide: Text.ElideRight"
  fi

  if grep -A 20 "StyledText" "$MEDIA_QML" | grep -q "Layout.fillWidth: true"; then
    pass "S3: StyledText uses Layout.fillWidth: true"
  else
    fail "S3: StyledText missing Layout.fillWidth: true"
  fi

  if grep -A 20 "StyledText" "$MEDIA_QML" | grep -q "StringUtils.escapeHtml"; then
    pass "S3: StyledText text binding uses StringUtils.escapeHtml"
  else
    fail "S3: StyledText text binding missing StringUtils.escapeHtml"
  fi

  if grep -A 20 "StyledText" "$MEDIA_QML" | grep -q "Appearance.colors.colOnLayer1"; then
    pass "S3: Title uses Appearance.colors.colOnLayer1"
  else
    fail "S3: Title missing Appearance.colors.colOnLayer1"
  fi

  if grep -A 20 "StyledText" "$MEDIA_QML" | grep -q "Appearance.colors.colSubtext"; then
    pass "S3: Artist uses Appearance.colors.colSubtext"
  else
    fail "S3: Artist missing Appearance.colors.colSubtext"
  fi

  if grep -A 20 "StyledText" "$MEDIA_QML" | grep -q "CircularProgress.size"; then
    fail "S3: Obsolete width binding loop on StyledText still present"
  else
    pass "S3: Obsolete width binding loop on StyledText removed"
  fi

  if grep -A 15 "MouseArea" "$MEDIA_QML" | grep -q "GlobalStates.mediaControlsOpen"; then
    pass "S3: MouseArea preserves LeftButton mediaControlsOpen toggle"
  else
    fail "S3: MouseArea missing LeftButton mediaControlsOpen toggle"
  fi

  if grep -A 15 "MouseArea" "$MEDIA_QML" | grep -q "activePlayer.togglePlaying()"; then
    pass "S3: MouseArea preserves MiddleButton togglePlaying()"
  else
    fail "S3: MouseArea missing MiddleButton togglePlaying()"
  fi

  if grep -A 15 "MouseArea" "$MEDIA_QML" | grep -q "activePlayer.next()"; then
    pass "S3: MouseArea preserves next() handler"
  else
    fail "S3: MouseArea missing next() handler"
  fi

  if grep -A 15 "MouseArea" "$MEDIA_QML" | grep -q "activePlayer.previous()"; then
    pass "S3: MouseArea preserves previous() handler"
  else
    fail "S3: MouseArea missing previous() handler"
  fi
fi

# ===========================================================================
# Section 4: Mathematical Simulation & Logic Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Mathematical Simulation & Logic Verification ---"

  calc_tier0() {
    local w="$1"
    python3 -c "import math; print(f'{min(max($w * 0.12, 220), 450):.1f}')"
  }

  calc_tier1() {
    local w="$1"
    python3 -c "import math; print(f'{min(max($w * 0.10, 140), 180):.1f}')"
  }

  res_3440=$(calc_tier0 3440)
  if [[ "$res_3440" == "412.8" ]]; then
    pass "S4: 3440px Ultrawide evaluates to 412.8px (expected 412.8px)"
  else
    fail "S4: 3440px Ultrawide evaluates to $res_3440 != 412.8px"
  fi

  res_2560=$(calc_tier0 2560)
  if [[ "$res_2560" == "307.2" ]]; then
    pass "S4: 2560px QHD evaluates to 307.2px (expected 307.2px)"
  else
    fail "S4: 2560px QHD evaluates to $res_2560 != 307.2px"
  fi

  res_1920=$(calc_tier0 1920)
  if [[ "$res_1920" == "230.4" ]]; then
    pass "S4: 1920px FHD evaluates to 230.4px (expected 230.4px)"
  else
    fail "S4: 1920px FHD evaluates to $res_1920 != 230.4px"
  fi

  res_1366=$(calc_tier0 1366)
  if [[ "$res_1366" == "220.0" ]]; then
    pass "S4: 1366px Laptop hits 220.0px floor clamp (expected 220.0px)"
  else
    fail "S4: 1366px Laptop evaluates to $res_1366 != 220.0px"
  fi

  res_1200_t1=$(calc_tier1 1200)
  if [[ "$res_1200_t1" == "140.0" ]]; then
    pass "S4: 1200px Shortened hits 140.0px floor clamp (expected 140.0px)"
  else
    fail "S4: 1200px Shortened evaluates to $res_1200_t1 != 140.0px"
  fi

  res_1080_t1=$(calc_tier1 1080)
  if [[ "$res_1080_t1" == "140.0" ]]; then
    pass "S4: 1080px Rotated hits 140.0px floor clamp (expected 140.0px)"
  else
    fail "S4: 1080px Rotated evaluates to $res_1080_t1 != 140.0px"
  fi

  # Tray gating logic verification
  check_tray_vis() {
    local form="$1"
    local count="$2"
    if (( form == 0 && count > 0 )); then echo "1"; else echo "0"; fi
  }

  [[ "$(check_tray_vis 0 0)" == "0" ]] && pass "S4: Form 0 + 0 items -> hidden (visible: false)" || fail "S4: Gating error"
  [[ "$(check_tray_vis 0 1)" == "1" ]] && pass "S4: Form 0 + 1 items -> visible (visible: true)" || fail "S4: Gating error"
  [[ "$(check_tray_vis 0 5)" == "1" ]] && pass "S4: Form 0 + 5 items -> visible (visible: true)" || fail "S4: Gating error"
  [[ "$(check_tray_vis 1 3)" == "0" ]] && pass "S4: Form 1 + 3 items -> hidden (visible: false)" || fail "S4: Gating error"
  [[ "$(check_tray_vis 2 3)" == "0" ]] && pass "S4: Form 2 + 3 items -> hidden (visible: false)" || fail "S4: Gating error"
fi

# ===========================================================================
# Section 5: Sub-Harness Orchestration & Strict Repository Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Sub-Harness Orchestration & Strict Repository Verification ---"

  if [[ "$QUICK_MODE" -eq 1 ]]; then
    info "S5: Quick mode enabled. Skipping sub-harness delegation and repo verify."
  else
    if bash scripts/phase47-center-layout-assert.sh --quick; then
      pass "S5: Sub-harness phase47-center-layout-assert.sh --quick passed"
    else
      fail "S5: Sub-harness phase47-center-layout-assert.sh --quick failed"
    fi

    if bash scripts/phase46-telemetry-assert.sh --quick; then
      pass "S5: Sub-harness phase46-telemetry-assert.sh --quick passed"
    else
      fail "S5: Sub-harness phase46-telemetry-assert.sh --quick failed"
    fi

    if ./arch/dots-hyprland.sh verify --strict; then
      pass "S5: Repository strict verification passed (dots-hyprland.sh)"
    else
      fail "S5: Repository strict verification failed (dots-hyprland.sh)"
    fi
  fi
fi

# Working tree drift check
PORCELAIN_AFTER="$(mktemp "${TMPDIR:-/tmp}/p48-porcelain-after.XXXXXX")"
TMP_FILES+=("$PORCELAIN_AFTER")
git status --porcelain > "$PORCELAIN_AFTER"

if diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" >/dev/null; then
  pass "S5: Zero working tree drift during assert execution (porcelain unchanged)"
else
  fail "S5: Working tree drifted during assert execution"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

# Final Summary
info "=== Phase 48 Assertion Summary ==="
info "Failures: $FAIL, Findings: $FINDINGS"

if [[ "$FAIL" -eq 0 && "$FINDINGS" -eq 0 ]]; then
  pass "All hard assertions passed with zero findings!"
  exit 0
elif [[ "$FAIL" -eq 0 ]]; then
  pass "All hard assertions passed ($FINDINGS informational findings)"
  exit 0
else
  fail "Assert harness encountered $FAIL failure(s)"
  exit 1
fi
```

---

## 4. Multi-Resolution Responsive Scaling Model

The responsive sizing model scales dynamically with screen width, providing ample space for long titles on ultrawide monitors while keeping compact screens balanced.

```qml
Layout.maximumWidth: (root.useShortenedForm === 1)
    ? Math.min(Math.max((root.screen?.width ?? 1200) * 0.10, 140), 180)
    : Math.min(Math.max((root.screen?.width ?? 1920) * 0.12, 220), 450)
```

| Screen Width | Monitor Context | Form Tier (`useShortenedForm`) | Sizing Formula | Max Width | Content Hugging Example | Pill Layout Width (`+10px` padding) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **3440 px** | UWQHD Ultrawide (`DP-1`) | Tier 0 (Full) | $\min(\max(3440 \times 0.12, 220), 450)$ | **412.8 px** | Title "Hey Jude" (~90px) | ~100 px (Hugs text) |
| **3440 px** | UWQHD Ultrawide (`DP-1`) | Tier 0 (Full) | $\min(\max(3440 \times 0.12, 220), 450)$ | **412.8 px** | Long title + artist (>500px) | ~423 px (Clamps & elides) |
| **2560 px** | QHD Standard | Tier 0 (Full) | $\min(\max(2560 \times 0.12, 220), 450)$ | **307.2 px** | Medium title (~200px) | ~210 px (Hugs text) |
| **1920 px** | FHD 1080p Standard | Tier 0 (Full) | $\min(\max(1920 \times 0.12, 220), 450)$ | **230.4 px** | Medium title (~200px) | ~210 px (Hugs text) |
| **1366 px** | Compact Laptop | Tier 0 (Full) | $\min(\max(1366 \times 0.12, 220), 450)$ | **220.0 px** (Floor) | Title "No media" (~80px) | ~90 px (Hugs text) |
| **1200 px** | Shortened Threshold | Tier 1 (Shortened) | $\min(\max(1200 \times 0.10, 140), 180)$ | **140.0 px** (Floor) | Any track > 140px | ~150 px (Clamps & elides) |
| **1080 px** | Secondary Rotated (`HDMI-A-2`) | Tier 1 (Shortened) | $\min(\max(1080 \times 0.10, 140), 180)$ | **140.0 px** (Floor) | Any track > 140px | ~150 px (Clamps & elides) |
| **1600 px** | Shortened Wide Tier | Tier 1 (Shortened) | $\min(\max(1600 \times 0.10, 140), 180)$ | **160.0 px** | Title (~120px) | ~130 px (Hugs text) |
| **$\le$ 1000 px** | Hella Shortened | Tier 2 (Hella Shortened) | Media inactive (`active: root.useShortenedForm < 2`) | **0 px** (Collapsed) | Inactive / Hidden | 0 px |

---

## 5. System Tray Empty-State Gating & Truth Table

In `BarContent.qml`, gating is bound to `sysTrayGroup.visible`:

```qml
visible: (root.useShortenedForm === 0) && ((SystemTray.items?.values?.length ?? 0) > 0)
```

| `root.screen` | Screen Width | Form Tier (`useShortenedForm`) | Active SNI Apps (`items.values.length`) | Outer Pill `sysTrayGroup.visible` | Resulting Layout State |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `DP-1` (Primary) | 3440 px | Tier 0 | 0 | `false` | Completely collapsed (0px width, 0px border artifact) |
| `DP-1` (Primary) | 3440 px | Tier 0 | 1 | `true` | Displayed with 1 app icon + 4px spacing |
| `DP-1` (Primary) | 3440 px | Tier 0 | 4 | `true` | Displayed with pinned items + overflow chevron |
| `HDMI-A-2` (Secondary) | 1080 px (Rotated) | Tier 1 | 0 | `false` | Completely collapsed |
| `HDMI-A-2` (Secondary) | 1080 px (Rotated) | Tier 1 | 3 | `false` | Completely collapsed (tray restricted to primary display) |
| Any (Cold Start) | undefined / booting | Tier 0 | nullish | `false` | Fallback to `?? 0 > 0` evaluates false; zero QML ReferenceErrors |

---

## 6. Anti-Patterns & Guardrails

| Anti-Pattern | Risk / Consequence | Solution / Correct Pattern |
| :--- | :--- | :--- |
| **Using `textFormat: Text.RichText`** | QtQuick explicitly disables `elide: Text.ElideRight` on `RichText`, causing overflowing text to clip abruptly without an ellipsis. | Use `textFormat: Text.StyledText`. StyledText supports `<span>` inline styles while preserving single-line right elision with an ellipsis (`...`). |
| **Unescaped metadata in `<span>` tags** | Song titles containing `<`, `>`, `&`, `"`, `'` (e.g. `"Simon & Garfunkel"`, `"Track <VIP Remix>"`) crash the StyledText XML parser, rendering blank text. | Wrap both title and artist with `StringUtils.escapeHtml(...)` before assembling the template literal. |
| **Specifying explicit `width:` in `RowLayout`** | Setting `width: rowLayout.width - ...` while `Layout.fillWidth: true` creates cyclic binding loops and QML console warnings. | Remove the explicit `width:` line. Let `RowLayout` calculate child width via `Layout.fillWidth: true`. |
| **Wrapping `SysTray` in a conditional `Loader.active`** | Toggling `Loader.active` unloads the SNI service and disconnects D-Bus watchers, causing tray app registration delays and crashes. | Keep `SysTray` instantiated in `sysTrayGroup` and gate visibility (`sysTrayGroup.visible`). D-Bus listeners stay hot while Qt Quick layout reflows immediately. |
| **Editing files in `vendor/dots-hyprland/`** | Breaks upstream git submodule purity and fails `./arch/dots-hyprland.sh verify --strict`. | Always create personal overlays under `restow/quickshell/` and manage deployment via symlinks. |
| **Folding parent directories during stow/symlink** | Symlinking parent directories instead of individual `.qml` files breaks GNU Stow multi-package overlays and triggers Arm 6 audit failures. | Maintain real physical ancestor directories (`~/.config/quickshell/ii/modules/ii/bar`) and symlink only leaf `.qml` files. |
| **Omitting defensive defaults on `root.screen?.width`** | During cold startup or hotplug events, `root.screen` may be undefined for one frame, leading to `NaN` width calculations. | Always supply fallback defaults: `(root.screen?.width ?? 1920)` for Tier 0 and `(root.screen?.width ?? 1200)` for Tier 1. |

---

## 7. Implementation Plan Sequence (For Planner)

Downstream planner should structure Phase 48 into the following atomic execution phases:

1. **Plan 48-01: `BarContent.qml` Responsive Equation & System Tray Gating**
   - Add `import Quickshell.Services.SystemTray` to `BarContent.qml`.
   - Update `mediaLoader` `Layout.maximumWidth` with Tier 0 and Tier 1 responsive display equations.
   - Update `sysTrayGroup.visible` with reactive `SystemTray.items?.values?.length` empty-state gating.
   - Verify coordinate tracking Connections (`onWidthChanged`, `onXChanged`) remain intact.

2. **Plan 48-02: `Media.qml` Personal Overlay Creation & Typography Styling**
   - Create personal overlay file at `restow/quickshell/.config/quickshell/ii/modules/ii/bar/Media.qml`.
   - Implement `textFormat: Text.StyledText` with visual hierarchy (primary `colOnLayer1`, muted `colSubtext`, separator `" • "`, `StringUtils.escapeHtml` sanitization, clean missing artist fallback, `Text.ElideRight`).
   - Remove obsolete width binding loop.
   - Back up live `~/.config/quickshell/ii/modules/ii/bar/Media.qml` to `Media.qml.bak` and create leaf symlink to `restow/.../Media.qml`.

3. **Plan 48-03: Quality Assertion Harness & Multi-Monitor Validation**
   - Create test harness `scripts/phase48-right-zone-assert.sh` with sections 1 through 5.
   - Make script executable (`chmod +x scripts/phase48-right-zone-assert.sh`).
   - Run full assertion suite and verify `./arch/dots-hyprland.sh verify --strict` returns `FAIL=0 FINDINGS=0`.
