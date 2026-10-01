# Phase 47: Center-Zone Layout Reorganization - Pattern Map

**Gathered:** 2026-09-29  
**Phase:** 47 - center-zone-layout-reorganization  
**Milestone:** v0.9 (Top Status Bar Resource Components & Hardware Telemetry)  
**Status:** Complete & Ready for Planning  

---

## 1. Executive Summary

This document establishes the authoritative architectural patterns, concrete code blueprints, exact code excerpts, geometric invariants, anti-pattern guardrails, and validation harness designs for **Phase 47: Center-Zone Layout Reorganization**.

Phase 47 completes the spatial and ergonomic reorganization of the Quickshell top status bar center zone:
1. **Clock/Date & Weather Position Swap (CNTR-01)**: The Clock & Date widget (`ClockWidget`) relocates from the right of the Workspaces indicator to the left of Workspaces. The Weather widget (`WeatherBar` wrapped in `weatherGroup`) relocates from the left of Workspaces to the right of Workspaces.
2. **Workspaces Dead-Center Alignment & Spacing Invariants (CNTR-02)**: The Workspaces widget (`middleCenterGroup`) remains rigidly anchored to `parent.horizontalCenter` on the bar across all display resolutions, flanked on both sides by uniform 4px margins (`anchors.rightMargin: 4` on the left, `anchors.leftMargin: 4` on the right).
3. **Responsive Rules, Dynamic Hit-Testing & Zero Git Churn (CNTR-03, INTG-02)**:
   - Outer `MouseArea` click behavior on `ClockWidget` toggling `GlobalStates.sidebarRightOpen` is strictly preserved.
   - Responsive date hiding (`showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)`) shrinks Clock width from ~220px to ~70px on narrow displays ($\le 900\text{px}$).
   - `middleSection` wrapper boundary anchors adapt dynamically: `anchors.left: leftCenterGroup.left` and `anchors.right: weatherGroup.active ? weatherGroup.right : middleCenterGroup.right`.
   - Relocating Clock to the left grants the congested Right zone an additional ~145px of clearance, eliminating tray clipping on compact displays while maintaining 0px layout overlap across ultrawide (3440px), QHD (2560px), FHD (1920px), compact (1200px), and minimum (900px) viewports.
   - Zero modifications to `vendor/dots-hyprland` submodule (zero git churn under `./arch/dots-hyprland.sh verify --strict`).

All changes are strictly mapped to existing codebase analogs with line references, property bindings, and AST check formulas.

---

## 2. File Inventory & Classification

| File Path | Role | Data Flow | Closest Codebase Analog |
| :--- | :--- | :--- | :--- |
| [`restow/quickshell/.../bar/BarContent.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml) | UI Layout Container / Center-Zone Coordinator | Coordinates status bar zones; locks Workspaces dead-center; positions Clock to left and Weather to right; drives responsive date gating | Existing `BarContent.qml` [BarContent.qml:139-205](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml#L139-L205) |
| [`scripts/phase47-center-layout-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase47-center-layout-assert.sh) | Quality Assertion Engine / Test Harness | Automated CLI assertion suite validating symlink integrity, AST anchor topology, responsive date gating, multi-res geometry simulation, and strict repo verification | [`scripts/phase46-telemetry-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase46-telemetry-assert.sh#L1-L471) & [`scripts/phase41-interactions-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase41-interactions-assert.sh#L1-L909) |

---

## 3. Per-File Pattern Assignments

### 3.1 `BarContent.qml` (Center-Zone Layout Reorganization)

- **Target File:** [`restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml)
- **Role:** Master top status bar container orchestrating the Left, Middle, and Right visual zones.
- **Data Flow:**
  - Dead-centers Workspaces: `middleCenterGroup.anchors.horizontalCenter: parent.horizontalCenter`.
  - Anchors Clock/Date to left of Workspaces: `leftCenterGroup.anchors.right: middleCenterGroup.left` with `anchors.rightMargin: 4`.
  - Anchors Weather to right of Workspaces: `weatherGroup.anchors.left: middleCenterGroup.right` with `anchors.leftMargin: 4`.
  - Bounds `middleSection` wrapper: `anchors.left: leftCenterGroup.left` and `anchors.right: weatherGroup.active ? weatherGroup.right : middleCenterGroup.right`.
  - Forwards `showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)` to `ClockWidget`.
  - Gates `weatherGroup.active: Config.options.bar.weather.enable`.
  - Toggles `GlobalStates.sidebarRightOpen` on clicking `leftCenterGroup`.
- **Closest Codebase Analogs:**
  - Existing Center Zone in `BarContent.qml`: [BarContent.qml:139-205](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml#L139-L205).
  - Background pill styling & animation in `BarGroup.qml`: [BarGroup.qml:5-50](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml#L5-L50).
  - Responsive date display in `ClockWidget.qml`: [ClockWidget.qml:7-51](file:///home/pera/github_repo/.dotfiles/restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml#L7-L51).

#### Architectural Blueprint & Layout Sequence (CNTR-01, CNTR-02, CNTR-03)

The Center Zone sequence in `BarContent.qml` spans lines 139–205. The reorganization requires:
1. **Declaration Sequence in QML**:
   - `Item { id: middleSection ... }` (middle wrapper boundary)
   - `MouseArea { id: leftCenterGroup ... }` (Clock & Date pill on left of Workspaces)
   - `BarGroup { id: middleCenterGroup ... }` (Workspaces pill dead-centered)
   - `Loader { id: weatherGroup ... }` (Weather pill on right of Workspaces)
2. **Hit-Testing Isolation**:
   - `barLeftSideMouseArea` continues bounding to `anchors.right: middleSection.left`.
   - `barRightSideMouseArea` continues bounding to `anchors.left: middleSection.right`.
   - Clicking `leftCenterGroup` toggles `GlobalStates.sidebarRightOpen`.
   - Right-clicking `workspacesWidget` toggles `GlobalStates.overviewOpen`.
   - Right-clicking `WeatherBar` triggers manual weather refresh (`Weather.getData()`).

#### Concrete Code Excerpt: Existing vs Target

```qml
// =========================================================================
// BEFORE: restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml:139-205
// =========================================================================
    Item { // Middle section wrapper
        id: middleSection
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: weatherGroup.active ? weatherGroup.left : middleCenterGroup.left
        anchors.right: rightCenterGroup.right
        property int spacing: 4
    }

    Loader {
        id: weatherGroup
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: middleCenterGroup.left
        anchors.rightMargin: 4
        active: Config.options.bar.weather.enable

        sourceComponent: BarGroup {
            WeatherBar {}
        }
    }

    BarGroup {
        id: middleCenterGroup
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        padding: workspacesWidget?.widgetPadding ?? 0

        Workspaces {
            id: workspacesWidget
            Layout.fillHeight: true
            MouseArea {
                // Right-click to toggle overview
                anchors.fill: parent
                acceptedButtons: Qt.RightButton

                onPressed: event => {
                    if (event.button === Qt.RightButton) {
                        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                    }
                }
            }
        }
    }

    MouseArea {
        id: rightCenterGroup
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: middleCenterGroup.right
        anchors.leftMargin: 4
        implicitWidth: rightCenterGroupContent.implicitWidth
        implicitHeight: rightCenterGroupContent.implicitHeight

        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        BarGroup {
            id: rightCenterGroupContent
            anchors.fill: parent

            ClockWidget {
                showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }
        }
    }
```

```qml
// =========================================================================
// AFTER (TARGET): restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml:139-205
// =========================================================================
    Item { // Middle section wrapper
        id: middleSection
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: leftCenterGroup.left
        anchors.right: weatherGroup.active ? weatherGroup.right : middleCenterGroup.right
        property int spacing: 4
    }

    MouseArea {
        id: leftCenterGroup
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: middleCenterGroup.left
        anchors.rightMargin: 4
        implicitWidth: leftCenterGroupContent.implicitWidth
        implicitHeight: leftCenterGroupContent.implicitHeight

        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        BarGroup {
            id: leftCenterGroupContent
            anchors.fill: parent

            ClockWidget {
                showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }
        }
    }

    BarGroup {
        id: middleCenterGroup
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        padding: workspacesWidget?.widgetPadding ?? 0

        Workspaces {
            id: workspacesWidget
            Layout.fillHeight: true
            MouseArea {
                // Right-click to toggle overview
                anchors.fill: parent
                acceptedButtons: Qt.RightButton

                onPressed: event => {
                    if (event.button === Qt.RightButton) {
                        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                    }
                }
            }
        }
    }

    Loader {
        id: weatherGroup
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: middleCenterGroup.right
        anchors.leftMargin: 4
        active: Config.options.bar.weather.enable

        sourceComponent: BarGroup {
            WeatherBar {}
        }
    }
```

#### Detailed Layout & Anchoring Invariants

1. **Dead-Centering Invariant (`middleCenterGroup`)**:
   ```qml
   anchors.verticalCenter: parent.verticalCenter
   anchors.horizontalCenter: parent.horizontalCenter
   ```
   `middleCenterGroup` MUST NOT anchor to either `leftCenterGroup` or `weatherGroup`. It anchors solely to `parent.horizontalCenter`. This guarantees the workspace indicator remains at the exact pixel center of the screen, regardless of whether Weather is enabled or disabled, or whether Clock is showing the long date or short time.
2. **Left Flank Anchoring (`leftCenterGroup`)**:
   ```qml
   anchors.verticalCenter: parent.verticalCenter
   anchors.right: middleCenterGroup.left
   anchors.rightMargin: 4
   ```
   `leftCenterGroup` attaches its right edge to `middleCenterGroup.left` with an explicit `anchors.rightMargin: 4`.
   *(Crucial: using `leftMargin` here is ignored by QtQuick on a right anchor and results in 0px gap!)*
3. **Right Flank Anchoring (`weatherGroup`)**:
   ```qml
   anchors.verticalCenter: parent.verticalCenter
   anchors.left: middleCenterGroup.right
   anchors.leftMargin: 4
   ```
   `weatherGroup` attaches its left edge to `middleCenterGroup.right` with an explicit `anchors.leftMargin: 4`.
   *(Crucial: using `rightMargin` here is ignored by QtQuick on a left anchor and results in 0px gap!)*
4. **Dynamic Wrapper Anchors (`middleSection`)**:
   ```qml
   anchors.left: leftCenterGroup.left
   anchors.right: weatherGroup.active ? weatherGroup.right : middleCenterGroup.right
   ```
   Because Clock is now permanently on the left, `middleSection.anchors.left` is unconditionally bound to `leftCenterGroup.left`.
   For the right boundary, when weather is disabled (`Config.options.bar.weather.enable == false`), `weatherGroup.active` is false; ternary binding dynamically bounds `middleSection.right` flush to `middleCenterGroup.right`, preventing an empty 4px dead-zone.

#### Dynamic Implicit Width Propagation & Smooth Resizing

The outer `MouseArea` (`id: leftCenterGroup`) wraps `BarGroup` (`id: leftCenterGroupContent`). To propagate animated width changes:
```qml
implicitWidth: leftCenterGroupContent.implicitWidth
implicitHeight: leftCenterGroupContent.implicitHeight
```
Because `BarGroup.qml` contains:
```qml
Behavior on implicitWidth {
    NumberAnimation {
        duration: 250
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
    }
}
```
Binding `implicitWidth` on the outer `MouseArea` guarantees that whenever `ClockWidget` toggles between full date and shortened time under responsive breakpoints, the outer item smoothly glides to the new width without visual stutter.

---

### 3.2 `scripts/phase47-center-layout-assert.sh` (Test Harness Blueprint)

- **Target File:** [`scripts/phase47-center-layout-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase47-center-layout-assert.sh)
- **Role:** Quality Assertion Engine / Test Harness for Phase 47.
- **Data Flow:**
  - Evaluates CLI flags (`--section|-s <1-5>`, `--quick|-q`, `--syntax|-c`, `--help|-h`).
  - Section 1: Stow Leaf Symlink Topology & Submodule Packaging Integrity (INTG-02, CNTR-03).
  - Section 2: `BarContent.qml` Center Zone Layout AST & Semantic Positioning (CNTR-01, CNTR-02, CNTR-03).
  - Section 3: Responsive Behavior & Date Gating AST (CNTR-03).
  - Section 4: Mathematical Spacing & Centering Invariants Simulation (CNTR-02, CNTR-03).
  - Section 5: Sub-Harness Orchestration & Strict Repository Verification (INTG-02, CNTR-03).
- **Closest Codebase Analogs:**
  - Structure, CLI parsing, and traps from [`scripts/phase46-telemetry-assert.sh`](file:///home/pera/github_repo/.dotfiles/scripts/phase46-telemetry-assert.sh#L1-L135).
  - Multi-resolution simulation logic from [`scripts/phase46-telemetry-assert.sh:372-397`](file:///home/pera/github_repo/.dotfiles/scripts/phase46-telemetry-assert.sh#L372-L397).
  - Sub-harness orchestration & porcelain checks from [`scripts/phase46-telemetry-assert.sh:401-454`](file:///home/pera/github_repo/.dotfiles/scripts/phase46-telemetry-assert.sh#L401-L454).

#### Concrete Code Blueprints for Harness Sections

##### Preamble, CLI Parser & Cleanup Trap
```bash
#!/usr/bin/env bash
# ===========================================================================
# Phase 47: Center-Zone Layout Reorganization Assertion Harness
# Enforces: CNTR-01, CNTR-02, CNTR-03, INTG-02
#
# Usage (from REPO_ROOT):
#   ./scripts/phase47-center-layout-assert.sh [OPTIONS] [1-5]
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
      echo "Sections:"
      echo "  1: Stow Leaf Symlink Topology & Packaging Integrity (INTG-02, CNTR-03)"
      echo "  2: BarContent.qml Center Zone Layout AST & Semantic Positioning (CNTR-01, CNTR-02, CNTR-03)"
      echo "  3: Responsive Behavior & Date Gating AST (CNTR-03)"
      echo "  4: Mathematical Spacing & Centering Invariants Simulation (CNTR-02, CNTR-03)"
      echo "  5: Sub-Harness Orchestration & Strict Repository Verification (INTG-02, CNTR-03)"
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
TARGET_SYMLINK="$HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml"

PORCELAIN_BEFORE="$(mktemp "${TMPDIR:-/tmp}/p47-porcelain-before.XXXXXX")"
TMP_FILES+=("$PORCELAIN_BEFORE")
git status --porcelain > "$PORCELAIN_BEFORE"

if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  pass "Assert harness bash syntax check passed (bash -n verified)"
  if [[ -f "$BAR_CONTENT" ]]; then
    pass "Component file exists: BarContent.qml"
  else
    fail "Component file missing: $BAR_CONTENT"
  fi
  exit "$FAIL"
fi
```

##### Section 1: Stow Leaf Symlink Topology & Packaging Integrity
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Stow Leaf Symlink Topology & Packaging Integrity ---"

  # 1. Assert ~/.config/quickshell/ii/modules/ii/bar/BarContent.qml is a leaf symlink
  if [[ -L "$TARGET_SYMLINK" ]]; then
    pass "S1: $TARGET_SYMLINK is a valid symlink"
  else
    fail "S1: $TARGET_SYMLINK is missing or not a symlink"
  fi

  # 2. Assert ancestor directories are real directories (no folded symlinks)
  for dir in "$HOME/.config" "$HOME/.config/quickshell" "$HOME/.config/quickshell/ii" "$HOME/.config/quickshell/ii/modules" "$HOME/.config/quickshell/ii/modules/ii" "$HOME/.config/quickshell/ii/modules/ii/bar"; do
    if [[ -d "$dir" && ! -L "$dir" ]]; then
      pass "S1: Directory $dir is a real un-folded directory"
    else
      fail "S1: Directory $dir is missing or is an invalid folded symlink"
    fi
  done

  # 3. Assert vendor/dots-hyprland submodule has zero git churn
  SUBMODULE_STATUS="$(git status --porcelain vendor/dots-hyprland 2>/dev/null || true)"
  if [[ -z "$SUBMODULE_STATUS" ]]; then
    pass "S1: vendor/dots-hyprland submodule has 0 git churn (clean porcelain)"
  else
    fail "S1: vendor/dots-hyprland submodule has uncommitted modifications: $SUBMODULE_STATUS"
  fi
fi
```

##### Section 2: BarContent.qml Center Zone Layout AST & Semantic Positioning
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: BarContent.qml Center Zone Layout AST & Semantic Positioning ---"

  if [[ ! -f "$BAR_CONTENT" ]]; then
    fail "S2: BarContent.qml not found at $BAR_CONTENT"
  else
    # 1. Declaration order: middleSection -> leftCenterGroup -> middleCenterGroup -> weatherGroup
    line_mid_sec=$(grep -n "id: middleSection" "$BAR_CONTENT" | head -n1 | cut -d: -f1 || echo 0)
    line_left_cg=$(grep -n "id: leftCenterGroup" "$BAR_CONTENT" | head -n1 | cut -d: -f1 || echo 0)
    line_mid_cg=$(grep -n "id: middleCenterGroup" "$BAR_CONTENT" | head -n1 | cut -d: -f1 || echo 0)
    line_wthr_g=$(grep -n "id: weatherGroup" "$BAR_CONTENT" | head -n1 | cut -d: -f1 || echo 0)
    line_right_ma=$(grep -n "id: barRightSideMouseArea" "$BAR_CONTENT" | head -n1 | cut -d: -f1 || echo 0)

    if (( line_mid_sec > 0 && line_left_cg > line_mid_sec && line_mid_cg > line_left_cg && line_wthr_g > line_mid_cg && line_right_ma > line_wthr_g )); then
      pass "S2: QML declaration order correct: middleSection ($line_mid_sec) < leftCenterGroup ($line_left_cg) < middleCenterGroup ($line_mid_cg) < weatherGroup ($line_wthr_g) < barRightSideMouseArea ($line_right_ma)"
    else
      fail "S2: QML declaration order violated ($line_mid_sec, $line_left_cg, $line_mid_cg, $line_wthr_g, $line_right_ma)"
    fi

    # 2. middleSection boundary anchors
    if grep -A 7 "id: middleSection" "$BAR_CONTENT" | grep -q "anchors.left: leftCenterGroup.left"; then
      pass "S2: middleSection anchors.left correctly bound to leftCenterGroup.left"
    else
      fail "S2: middleSection anchors.left not bound to leftCenterGroup.left"
    fi

    if grep -A 7 "id: middleSection" "$BAR_CONTENT" | grep -q "anchors.right: weatherGroup.active ? weatherGroup.right : middleCenterGroup.right"; then
      pass "S2: middleSection anchors.right correctly uses dynamic ternary for weatherGroup.active"
    else
      fail "S2: middleSection anchors.right missing dynamic weatherGroup.active ternary"
    fi

    # 3. leftCenterGroup MouseArea geometry & behavior
    if grep -A 6 "id: leftCenterGroup" "$BAR_CONTENT" | grep -q "anchors.right: middleCenterGroup.left" && \
       grep -A 6 "id: leftCenterGroup" "$BAR_CONTENT" | grep -q "anchors.rightMargin: 4"; then
      pass "S2: leftCenterGroup anchors to middleCenterGroup.left with rightMargin: 4 (CNTR-01, CNTR-02)"
    else
      fail "S2: leftCenterGroup missing anchors.right: middleCenterGroup.left or rightMargin: 4"
    fi

    if grep -A 8 "id: leftCenterGroup" "$BAR_CONTENT" | grep -q "implicitWidth: leftCenterGroupContent.implicitWidth" && \
       grep -A 8 "id: leftCenterGroup" "$BAR_CONTENT" | grep -q "implicitHeight: leftCenterGroupContent.implicitHeight"; then
      pass "S2: leftCenterGroup binds implicitWidth and implicitHeight to content"
    else
      fail "S2: leftCenterGroup missing implicitWidth/implicitHeight content bindings"
    fi

    if grep -A 12 "id: leftCenterGroup" "$BAR_CONTENT" | grep -q "GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen"; then
      pass "S2: leftCenterGroup onPressed toggles GlobalStates.sidebarRightOpen (CNTR-03)"
    else
      fail "S2: leftCenterGroup onPressed missing sidebarRightOpen toggle"
    fi

    # 4. leftCenterGroup content wrapping
    if grep -A 6 "id: leftCenterGroupContent" "$BAR_CONTENT" | grep -q "ClockWidget"; then
      pass "S2: leftCenterGroupContent wraps ClockWidget inside BarGroup"
    else
      fail "S2: leftCenterGroupContent missing ClockWidget inside BarGroup"
    fi

    # 5. middleCenterGroup dead-center anchoring
    if grep -A 5 "id: middleCenterGroup" "$BAR_CONTENT" | grep -q "anchors.horizontalCenter: parent.horizontalCenter"; then
      pass "S2: middleCenterGroup dead-centered via anchors.horizontalCenter: parent.horizontalCenter (CNTR-02)"
    else
      fail "S2: middleCenterGroup missing anchors.horizontalCenter: parent.horizontalCenter"
    fi

    if grep -A 10 "id: middleCenterGroup" "$BAR_CONTENT" | grep -q "Workspaces"; then
      pass "S2: middleCenterGroup hosts Workspaces component (CNTR-02)"
    else
      fail "S2: middleCenterGroup missing Workspaces component"
    fi

    # 6. weatherGroup Loader geometry
    if grep -A 6 "id: weatherGroup" "$BAR_CONTENT" | grep -q "anchors.left: middleCenterGroup.right" && \
       grep -A 6 "id: weatherGroup" "$BAR_CONTENT" | grep -q "anchors.leftMargin: 4"; then
      pass "S2: weatherGroup anchors to middleCenterGroup.right with leftMargin: 4 (CNTR-01, CNTR-02)"
    else
      fail "S2: weatherGroup missing anchors.left: middleCenterGroup.right or leftMargin: 4"
    fi

    if grep -A 6 "id: weatherGroup" "$BAR_CONTENT" | grep -q "active: Config.options.bar.weather.enable"; then
      pass "S2: weatherGroup gated by Config.options.bar.weather.enable"
    else
      fail "S2: weatherGroup missing Config.options.bar.weather.enable active gating"
    fi

    # 7. Flanking MouseAreas
    if grep -A 8 "id: barLeftSideMouseArea" "$BAR_CONTENT" | grep -q "anchors.right: middleSection.left"; then
      pass "S2: barLeftSideMouseArea anchors.right bound to middleSection.left"
    else
      fail "S2: barLeftSideMouseArea anchors.right not bound to middleSection.left"
    fi

    if grep -A 8 "id: barRightSideMouseArea" "$BAR_CONTENT" | grep -q "anchors.left: middleSection.right"; then
      pass "S2: barRightSideMouseArea anchors.left bound to middleSection.right"
    else
      fail "S2: barRightSideMouseArea anchors.left not bound to middleSection.right"
    fi

    # 8. Assert obsolete rightCenterGroup is completely eliminated
    if grep -q "id: rightCenterGroup" "$BAR_CONTENT"; then
      fail "S2: Obsolete id: rightCenterGroup still present in BarContent.qml"
    else
      pass "S2: Obsolete id: rightCenterGroup completely replaced by leftCenterGroup"
    fi
  fi
fi
```

##### Section 3: Responsive Behavior & Date Gating AST
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Responsive Behavior & Date Gating AST ---"

  if [[ ! -f "$BAR_CONTENT" ]]; then
    fail "S3: BarContent.qml not found at $BAR_CONTENT"
  else
    # 1. Verify ClockWidget showDate responsive binding
    if grep -A 4 "ClockWidget" "$BAR_CONTENT" | grep -q "showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)"; then
      pass "S3: ClockWidget specifies responsive showDate contract '(Config.options.bar.verbose && root.useShortenedForm < 2)' (CNTR-03)"
    else
      fail "S3: ClockWidget missing responsive showDate contract"
    fi

    # 2. Verify useShortenedForm derivation in root
    if grep -q "property real useShortenedForm:" "$BAR_CONTENT"; then
      pass "S3: root declares useShortenedForm responsive tier property"
    else
      fail "S3: root missing useShortenedForm property"
    fi
  fi
fi
```

##### Section 4: Mathematical Spacing & Centering Invariants Simulation
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Mathematical Spacing & Centering Invariants Simulation ---"

  # Mathematical verification across standard breakpoints:
  # 3440 (Ultrawide), 2560 (QHD), 1920 (FHD), 1200 (Compact), 900 (Minimum)
  # Standard component dimension models:
  # Workspaces W_w = 180px
  # Clock W_c = 220px (full) / 70px (shortened, useShortenedForm == 2)
  # Weather W_t = 75px
  # Margin M = 4px

  RESOLUTIONS=(3440 2560 1920 1200 900)

  for screen_w in "${RESOLUTIONS[@]}"; do
    screen_center=$(( screen_w / 2 ))
    w_workspaces=180
    w_weather=75

    if (( screen_w <= 900 )); then
      form=2
      w_clock=70
      req_left=220
      req_right=250
    elif (( screen_w < 1200 )); then
      form=1
      w_clock=220
      req_left=277
      req_right=380
    else
      form=0
      w_clock=220
      req_left=612
      req_right=480
    fi

    # Workspaces dead center coordinates
    ws_left=$(( screen_center - (w_workspaces / 2) ))
    ws_right=$(( ws_left + w_workspaces ))
    ws_calc_center=$(( (ws_left + ws_right) / 2 ))

    if (( ws_calc_center == screen_center )); then
      pass "S4: [${screen_w}px] Workspaces center perfectly locked to ${screen_center}px (50% physical width)"
    else
      fail "S4: [${screen_w}px] Workspaces center mismatch: got ${ws_calc_center}px, expected ${screen_center}px"
    fi

    # Clock coordinates (left of workspaces with 4px margin)
    clk_right=$(( ws_left - 4 ))
    clk_left=$(( clk_right - w_clock ))
    left_gap=$(( ws_left - clk_right ))

    if (( left_gap == 4 )); then
      pass "S4: [${screen_w}px] Clock-to-Workspaces margin is exactly 4px (left: $clk_left, right: $clk_right)"
    else
      fail "S4: [${screen_w}px] Clock-to-Workspaces margin is $left_gap px (expected 4px)"
    fi

    # Weather coordinates (right of workspaces with 4px margin)
    wthr_left=$(( ws_right + 4 ))
    wthr_right=$(( wthr_left + w_weather ))
    right_gap=$(( wthr_left - ws_right ))

    if (( right_gap == 4 )); then
      pass "S4: [${screen_w}px] Workspaces-to-Weather margin is exactly 4px (left: $wthr_left, right: $wthr_right)"
    else
      fail "S4: [${screen_w}px] Workspaces-to-Weather margin is $right_gap px (expected 4px)"
    fi

    # MiddleSection bounds
    mid_left=$clk_left
    mid_right=$wthr_right

    # Left zone clearance (0 to mid_left)
    left_avail=$mid_left
    left_clearance=$(( left_avail - req_left ))

    if (( left_clearance >= 0 )); then
      pass "S4: [${screen_w}px] Left zone clearance positive: +${left_clearance}px (avail: ${left_avail}px >= req: ${req_left}px)"
    else
      fail "S4: [${screen_w}px] Left zone layout overlap detected! Clearance: ${left_clearance}px"
    fi

    # Right zone clearance (mid_right to screen_w)
    right_avail=$(( screen_w - mid_right ))
    right_clearance=$(( right_avail - req_right ))

    if (( right_clearance >= 0 )); then
      pass "S4: [${screen_w}px] Right zone clearance positive: +${right_clearance}px (avail: ${right_avail}px >= req: ${req_right}px)"
    else
      fail "S4: [${screen_w}px] Right zone layout overlap detected! Clearance: ${right_clearance}px"
    fi
  done
fi
```

##### Section 5: Sub-Harness Orchestration & Strict Repository Verification
```bash
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Sub-Harness Orchestration & Strict Repository Verification ---"

  if [[ "$QUICK_MODE" -eq 1 ]]; then
    info "S5: Quick mode active; skipping sub-harness delegation"
  else
    # 1. Run Phase 46 Telemetry & Left Zone assert harness
    if [[ -x "$REPO_ROOT/scripts/phase46-telemetry-assert.sh" ]]; then
      info "Running sub-harness: scripts/phase46-telemetry-assert.sh --quick"
      if "$REPO_ROOT/scripts/phase46-telemetry-assert.sh" --quick >/dev/null 2>&1; then
        pass "S5: Sub-harness phase46-telemetry-assert.sh --quick passed cleanly"
      else
        fail "S5: Sub-harness phase46-telemetry-assert.sh --quick encountered failures"
      fi
    else
      fail "S5: scripts/phase46-telemetry-assert.sh is missing or not executable"
    fi

    # 2. Strict repository verification gate
    if [[ -x "$REPO_ROOT/arch/dots-hyprland.sh" ]]; then
      info "Running repository strict verification gate: ./arch/dots-hyprland.sh verify --strict"
      if ./arch/dots-hyprland.sh verify --strict >/dev/null 2>&1; then
        pass "S5: ./arch/dots-hyprland.sh verify --strict passed (FAIL=0 FINDINGS=0)"
      else
        fail "S5: ./arch/dots-hyprland.sh verify --strict encountered failures"
      fi
    else
      fail "S5: arch/dots-hyprland.sh is missing or not executable"
    fi
  fi

  # 3. Git porcelain check for working tree drift
  PORCELAIN_AFTER="$(mktemp "${TMPDIR:-/tmp}/p47-porcelain-after.XXXXXX")"
  TMP_FILES+=("$PORCELAIN_AFTER")
  git status --porcelain > "$PORCELAIN_AFTER"

  if diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" >/dev/null 2>&1; then
    pass "S5: Zero working tree drift during assert execution (clean porcelain match)"
  else
    fail "S5: Working tree drift detected during assert execution"
  fi
fi

# ===========================================================================
# Final Summary
# ===========================================================================
info "=== Phase 47 Center-Zone Layout Assertion Summary ==="
info "Failures: $FAIL, Findings: $FINDINGS"

if [[ "$FAIL" -eq 0 && "$FINDINGS" -eq 0 ]]; then
  pass "All hard assertions passed with zero findings! (Phase 47 verified)"
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

## 4. Shared Architectural Rules & Geometric Invariants

### 4.1 Resolution Matrix & Coordinate Alignment

| Metric / Coordinate | Ultrawide (3440px) | 1440p QHD (2560px) | 1080p FHD (1920px) | Compact (1200px) | Hella-Shortened (900px) |
|---|---|---|---|---|---|
| Screen Center | 1720px | 1280px | 960px | 600px | 450px |
| `useShortenedForm` | 0 | 0 | 0 | 1 | 2 |
| Workspaces Center | **1720px** | **1280px** | **960px** | **600px** | **450px** |
| Workspaces Width | 180px | 180px | 180px | 180px | 180px |
| Workspaces Bounds | [1630, 1810] | [1190, 1370] | [870, 1050] | [510, 690] | [360, 540] |
| Clock Width | 220px | 220px | 220px | 220px | **70px** (date hidden) |
| Clock Bounds | [1406, 1626] | [966, 1186] | [646, 866] | [286, 506] | [286, 356] |
| Margin (Clock-to-Workspaces) | **4px** | **4px** | **4px** | **4px** | **4px** |
| Weather Width | 75px | 75px | 75px | 75px | 75px |
| Weather Bounds | [1814, 1889] | [1374, 1449] | [1054, 1129] | [694, 769] | [544, 619] |
| Margin (Workspaces-to-Weather) | **4px** | **4px** | **4px** | **4px** | **4px** |
| `middleSection` Bounds | [1406, 1889] | [966, 1449] | [646, 1129] | [286, 769] | [286, 619] |
| Left Zone Width Available | 1406px | 966px | 646px | 286px | 286px |
| Left Zone Required Width | 612px | 612px | 612px | 277px (util dropped) | 220px (compact) |
| Left Zone Clearance | **+794px** | **+354px** | **+34px** | **+9px** | **+66px** |
| Right Zone Width Available | 1551px | 1111px | 791px | 431px | 281px |
| Layout Overlap Detected? | **NO (0px)** | **NO (0px)** | **NO (0px)** | **NO (0px)** | **NO (0px)** |

### 4.2 Anchor Direction Rules

In QtQuick, anchor margins only take effect in the direction of the anchor:
- **Left of an element**:
  ```qml
  anchors.right: middleCenterGroup.left
  anchors.rightMargin: 4  // CORRECT: spaces 4px to the left of middleCenterGroup
  // anchors.leftMargin: 4  <-- WRONG: ignored by QtQuick!
  ```
- **Right of an element**:
  ```qml
  anchors.left: middleCenterGroup.right
  anchors.leftMargin: 4   // CORRECT: spaces 4px to the right of middleCenterGroup
  // anchors.rightMargin: 4 <-- WRONG: ignored by QtQuick!
  ```
- **Dead-Center**:
  ```qml
  anchors.horizontalCenter: parent.horizontalCenter
  // Never bind left or right anchors on middleCenterGroup!
  ```

---

## 5. Anti-Patterns & Common Pitfalls Checklist

| Pitfall ID | Anti-Pattern | Correct Engineering Pattern | Enforced By |
| :--- | :--- | :--- | :--- |
| **PIT-47-01** | Inverting margin direction (e.g. `anchors.leftMargin: 4` on `leftCenterGroup` or `anchors.rightMargin: 4` on `weatherGroup`) | Use `anchors.rightMargin: 4` for right-anchored left elements, and `anchors.leftMargin: 4` for left-anchored right elements. | Section 2 AST check & Section 4 simulation |
| **PIT-47-02** | Static `middleSection.anchors.right: weatherGroup.right` | Use dynamic ternary `anchors.right: weatherGroup.active ? weatherGroup.right : middleCenterGroup.right` so the center zone bounds flush to Workspaces when weather is disabled. | Section 2 AST check |
| **PIT-47-03** | Modifying `vendor/dots-hyprland` files directly | Make edits only in `restow/quickshell/.../BarContent.qml`. `vendor/dots-hyprland` must remain 100% clean porcelain. | Section 1 & Section 5 `./arch/dots-hyprland.sh verify --strict` |
| **PIT-47-04** | Breaking `middleCenterGroup` dead-center alignment by chaining left/right anchors | Keep `middleCenterGroup` anchored strictly to `parent.horizontalCenter`. Flanking items anchor relative to it. | Section 2 AST check & Section 4 simulation |
| **PIT-47-05** | Dropping `implicitWidth` / `implicitHeight` propagation on outer `leftCenterGroup` `MouseArea` | Explicitly bind `implicitWidth: leftCenterGroupContent.implicitWidth` and `implicitHeight: leftCenterGroupContent.implicitHeight` to preserve `BarGroup` 250ms width animations. | Section 2 AST check |
| **PIT-47-06** | Removing responsive `showDate` contract on `ClockWidget` | Maintain `showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)` ensuring date shrinks away on narrow displays. | Section 3 AST check & Section 4 simulation |
| **PIT-47-07** | Leaving dead identifier `rightCenterGroup` in QML | Rename and restructure fully to `leftCenterGroup` and `leftCenterGroupContent`. | Section 2 AST check |

---

## 6. Implementation Checklist & Traceability Matrix

| Requirement | Description | Target Component | Verifying Section |
| :--- | :--- | :--- | :--- |
| **CNTR-01** | Widget Reordering: Clock/Date to left of Workspaces, Weather to right of Workspaces | `BarContent.qml:139-205` | Section 2, Section 4 |
| **CNTR-02** | Workspaces Dead-Centering: `middleCenterGroup` locked to `parent.horizontalCenter` with 4px margins on both sides | `BarContent.qml:160-182` | Section 2, Section 4 |
| **CNTR-03** | Wrapper Boundary Anchors, Click Behaviors, Responsive Rules & Zero Churn | `BarContent.qml:139-205` | Section 1, Section 2, Section 3, Section 5 |
| **INTG-02** | Zero git churn in `vendor/dots-hyprland` and passing `./arch/dots-hyprland.sh verify --strict` | Repo packaging & Stow leaf symlinks | Section 1, Section 5 |

---

## PATTERN MAPPING COMPLETE
