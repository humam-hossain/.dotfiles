# Phase 31: Overlay Infrastructure & Pill Geometry Foundation - Pattern Map

**Phase:** 31  
**Domain:** GNU Stow `--no-folding` overlay architecture, Quickshell 0.2.x QML dynamic pill container geometry, Material 3 deceleration animation  
**Output Target:** `.planning/phases/31-overlay-infrastructure-pill-geometry-foundation/31-PATTERNS.md`  

---

## 1. File Inventory & Categorization

| Target File | Role | Closest Codebase Analog | Adaptation / Delta |
|---|---|---|---|
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml` | Overlay View Component | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/BarContent.qml` | Unclamp `leftCenterGroup` and `rightCenterGroup`; remove `implicitWidth: root.centerSideModuleWidth`; propagate `rightCenterGroupContent.implicitWidth` to `rightCenterGroup`. |
| `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` | Overlay Container Component | `vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/BarGroup.qml` | Add `Behavior on implicitWidth` using `Appearance.animationCurves.emphasizedDecel` (250ms duration, active when horizontal); retain all upstream tokens (`padding: 5`, `rounding.small`, `colLayer1`, `borderless`). |
| `scripts/phase31-overlay-pill-assert.sh` | Automated Test Harness | `scripts/phase30-tech-debt-assert.sh` & `scripts/phase28-terminal-fuzzel-assert.sh` | 4-section bash assert harness validating symlink integrity, unclamped QML properties, animation definitions, and `arch/dots-hyprland.sh verify --strict` pass. |
| `restow/README.md` | Documentation & Recovery Map | `restow/README.md` (existing) | Regenerate Section 3 markdown comment block via `./scripts/gen-collision-map.sh --restow-table` to include `quickshell` package mapped to `rsync-replace`. |

---

## 2. Component Pattern Mappings

### 2.1. `restow/quickshell/.../BarContent.qml` (Bar Layout Overlay)

#### Role & Data Flow
`BarContent.qml` defines the top-level status bar content layout:
- `leftSectionRowLayout`: Host sidebar toggle and active window title.
- `middleSection` (`Row`, centered): Houses `leftCenterGroup` (Resources, Media), `middleCenterGroup` (Workspaces), and `rightCenterGroup` (Clock, Utilities, Battery).
- `rightSectionRowLayout`: Host volume, mic, language, notifications, network, bluetooth, and system tray.

In upstream `dots-hyprland`, `leftCenterGroup` and `rightCenterGroup` are clamped to `implicitWidth: root.centerSideModuleWidth` (fixed to 360px, 280px, or 190px). Because `middleSection` is a `Row`, QtQuick automatically uses child `implicitWidth` to size and position row elements. Clamping `implicitWidth` prevents pills from expanding when detailed text strings (e.g., date formats, gigabyte RAM readings) lengthen.

#### Closest Codebase Analog
[BarContent.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/BarContent.qml#L102-L188)

#### Upstream Clamped Pattern
```qml
// vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/BarContent.qml:111-125
        BarGroup {
            id: leftCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: root.centerSideModuleWidth // <-- HARDCODED CLAMP PREVENTING EXPANSION

            Resources {
                alwaysShowAllResources: root.useShortenedForm === 2
                Layout.fillWidth: root.useShortenedForm === 2
            }

            Media {
                visible: root.useShortenedForm < 2
                Layout.fillWidth: true
            }
        }

// lines 157-170:
        MouseArea {
            id: rightCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: root.centerSideModuleWidth // <-- HARDCODED CLAMP PREVENTING EXPANSION
            implicitHeight: rightCenterGroupContent.implicitHeight

            onPressed: {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }

            BarGroup {
                id: rightCenterGroupContent
                anchors.fill: parent
                // ...
```

#### Overlay Unclamped Pattern (`restow/quickshell/.../BarContent.qml`)
```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml
        BarGroup {
            id: leftCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            // implicitWidth: root.centerSideModuleWidth removed per D-01, PILL-02, PILL-03.
            // Native BarGroup math (gridLayout.implicitWidth + padding * 2) governs width dynamically.

            Resources {
                alwaysShowAllResources: root.useShortenedForm === 2
                Layout.fillWidth: root.useShortenedForm === 2
            }

            Media {
                visible: root.useShortenedForm < 2
                Layout.fillWidth: true
            }
        }

        VerticalBarSeparator {
            visible: Config.options?.bar.borderless
        }

        BarGroup {
            id: middleCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            padding: workspacesWidget.widgetPadding

            Workspaces {
                id: workspacesWidget
                Layout.fillHeight: true
                MouseArea {
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

        VerticalBarSeparator {
            visible: Config.options?.bar.borderless
        }

        MouseArea {
            id: rightCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            // Propagate calculated implicit size from inner BarGroup to outer MouseArea (D-01, PILL-03)
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

                UtilButtons {
                    visible: (Config.options.bar.verbose && root.useShortenedForm === 0)
                    Layout.alignment: Qt.AlignVCenter
                }

                BatteryIndicator {
                    visible: (root.useShortenedForm < 2 && Battery.available)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
```

#### Conventions & Invariants to Maintain
1. **Preserve Upstream Imports & Properties:** Retain all top-level imports (`qs.modules.ii.bar.weather`, `QtQuick`, `QtQuick.Layouts`, `Quickshell`, `Quickshell.Services.UPower`, `qs`, `qs.services`, `qs.modules.common`, `qs.modules.common.widgets`, `qs.modules.common.functions`).
2. **Preserve `VerticalBarSeparator` Component:** Defined on lines 20–26, driven by `Config.options?.bar.borderless`.
3. **Preserve Surrounding Sections:** `barBackground`, `barLeftSideMouseArea`, `barRightSideMouseArea`, and all internal signal handlers must remain identical to upstream.

---

### 2.2. `restow/quickshell/.../BarGroup.qml` (Status Bar Pill Container)

#### Role & Data Flow
`BarGroup.qml` is the fundamental container for modular bar widgets.
- It exposes a `GridLayout` containing child items (`default property alias items: gridLayout.children`).
- It calculates width: `implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (gridLayout.implicitWidth + padding * 2)`.
- It renders a `Rectangle` background with rounded corners (`radius: Appearance.rounding.small` = 12px) and color based on `Config.options?.bar.borderless ? "transparent" : Appearance.colors.colLayer1`.
- When child text strings grow or shrink, `gridLayout.implicitWidth` changes. The addition of a `Behavior on implicitWidth` animates this change over 250ms using `Appearance.animationCurves.emphasizedDecel`, eliminating visual popping.

#### Closest Codebase Analog
[BarGroup.qml](file:///home/pera/github_repo/.dotfiles/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/BarGroup.qml#L1-L41)

#### Upstream Static Container Pattern
```qml
// vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/BarGroup.qml:1-41
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool vertical: false
    property real padding: 5
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (gridLayout.implicitWidth + padding * 2)
    implicitHeight: vertical ? (gridLayout.implicitHeight + padding * 2) : Appearance.sizes.baseBarHeight
    default property alias items: gridLayout.children

    Rectangle {
        id: background
        anchors {
            fill: parent
            topMargin: root.vertical ? 0 : 4
            bottomMargin: root.vertical ? 0 : 4
            leftMargin: root.vertical ? 4 : 0
            rightMargin: root.vertical ? 4 : 0
        }
        color: Config.options?.bar.borderless ? "transparent" : Appearance.colors.colLayer1
        radius: Appearance.rounding.small
    }

    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors {
            verticalCenter: root.vertical ? undefined : parent.verticalCenter
            horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            left: root.vertical ? undefined : parent.left
            right: root.vertical ? undefined : parent.right
            top: root.vertical ? parent.top : undefined
            bottom: root.vertical ? parent.bottom : undefined
            margins: root.padding
        }
        columnSpacing: 4
        rowSpacing: 12
    }
}
```

#### Overlay Animated Pattern (`restow/quickshell/.../BarGroup.qml`)
```qml
// restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml
import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool vertical: false
    property real padding: 5
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (gridLayout.implicitWidth + padding * 2)
    implicitHeight: vertical ? (gridLayout.implicitHeight + padding * 2) : Appearance.sizes.baseBarHeight
    default property alias items: gridLayout.children

    // Smooth pill expansion/contraction animation (D-02, PILL-03)
    Behavior on implicitWidth {
        enabled: !root.vertical
        NumberAnimation {
            duration: 250
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
        }
    }

    Rectangle {
        id: background
        anchors {
            fill: parent
            topMargin: root.vertical ? 0 : 4
            bottomMargin: root.vertical ? 0 : 4
            leftMargin: root.vertical ? 4 : 0
            rightMargin: root.vertical ? 4 : 0
        }
        color: Config.options?.bar.borderless ? "transparent" : Appearance.colors.colLayer1
        radius: Appearance.rounding.small
    }

    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors {
            verticalCenter: root.vertical ? undefined : parent.verticalCenter
            horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            left: root.vertical ? undefined : parent.left
            right: root.vertical ? undefined : parent.right
            top: root.vertical ? parent.top : undefined
            bottom: root.vertical ? parent.bottom : undefined
            margins: root.padding
        }
        columnSpacing: 4
        rowSpacing: 12
    }
}
```

#### Conventions & Invariants to Maintain
1. **Material 3 Easing Curve:** Must use `Appearance.animationCurves.emphasizedDecel` (`[0.05, 0.7, 0.1, 1, 1, 1]`, defined in `Appearance.qml:260`).
2. **Animation Scope:** `enabled: !root.vertical` ensures vertical bars (if ever configured) do not animate horizontal width.
3. **Pill Visual Purity (D-03, PILL-02, PILL-04):**
   - Corner radius: strictly `Appearance.rounding.small` (12px).
   - Internal padding: strictly `padding: 5`.
   - Grid spacing: `columnSpacing: 4`, `rowSpacing: 12`.
   - Surface color: `Config.options?.bar.borderless ? "transparent" : Appearance.colors.colLayer1`.
   - No hardcoded pixel width clamps or custom CSS styles.

---

### 2.3. `scripts/phase31-overlay-pill-assert.sh` (Automated Assertion Harness)

#### Role & Structure
The test harness acts as the automated verification authority for Phase 31:
- Conforms to repository bash script conventions (`set -euo pipefail`, 2-space indentation).
- Implements `--section <1-4>` filtering, help text, temporary file traps, and porcelain snapshot invariant checks.
- Returns exit code 0 when all asserts pass, 1 if `FAIL > 0`.

#### Closest Codebase Analogs
- [scripts/phase30-tech-debt-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase30-tech-debt-assert.sh#L1-L80) — Porcelain snapshots, section flags, error traps.
- [scripts/phase28-terminal-fuzzel-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase28-terminal-fuzzel-assert.sh#L1-L60) — File-level symlink and content verification.
- [scripts/phase21-ii-bar-config-capture-assert.sh](file:///home/pera/github_repo/.dotfiles/scripts/phase21-ii-bar-config-capture-assert.sh#L1-L65) — Strict packaging checks and clean teardown.

#### Test Harness Scaffold Pattern
```bash
#!/usr/bin/env bash
# Phase 31: Overlay Infrastructure & Pill Geometry Foundation Assert Harness
# Enforces: PILL-01, PILL-02, PILL-03, PILL-04, and D-01 through D-08
#
# Usage (from REPO_ROOT):
#   ./scripts/phase31-overlay-pill-assert.sh [--section <1-4>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

ASSERT_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"

FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
SCRATCH_ROOTS=()

cleanup() {
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true
  local root
  for root in ${SCRATCH_ROOTS[@]+"${SCRATCH_ROOTS[@]}"}; do
    [[ -n "$root" ]] || continue
    chmod -R u+rwX "$root" 2>/dev/null || true
    rm -rf "$root" 2>/dev/null || true
  done
  return 0
}
trap cleanup EXIT

RUN_SECTION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-4]$ ]]; then
        echo "Error: --section requires an integer from 1 to 4" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-4>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

porcelain_snapshot_raw() {
  git status --porcelain --ignored || true
}

porcelain_snapshot() {
  porcelain_snapshot_raw \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

PORCELAIN_BEFORE="$(mktemp /tmp/p31-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p31-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"
```

#### Section Assert Details

##### Section 1: Symlink & Packaging Integrity (PILL-01, D-05, D-06)
```bash
# 1. Target files in ~/.config/quickshell/ii/modules/ii/bar/ must be symlinks
#    resolving to $REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/<file>
for qml_file in BarContent.qml BarGroup.qml; do
  live_path="$HOME/.config/quickshell/ii/modules/ii/bar/$qml_file"
  target_repo="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/$qml_file"
  if [[ -L "$live_path" ]]; then
    actual_target="$(readlink -f "$live_path")"
    expected_target="$(readlink -f "$target_repo")"
    if [[ "$actual_target" == "$expected_target" ]]; then
      pass "S1: $live_path is symlink to $target_repo"
    else
      fail "S1: $live_path points to $actual_target, expected $expected_target"
    fi
  else
    fail "S1: $live_path is not a symlink"
  fi
done

# 2. Assert no ancestor directory is folded (directory symlink into repo)
for check_dir in "$HOME/.config" "$HOME/.config/quickshell" "$HOME/.config/quickshell/ii" "$HOME/.config/quickshell/ii/modules" "$HOME/.config/quickshell/ii/modules/ii" "$HOME/.config/quickshell/ii/modules/ii/bar"; do
  if [[ -L "$check_dir" ]]; then
    fail "S1: ancestor directory $check_dir is a symlink (folded directory violation)"
  else
    pass "S1: ancestor directory $check_dir is a real directory"
  fi
done

# 3. Assert sibling files in ~/.config/quickshell/ii/modules/ii/bar/ remain regular files
for sibling in Bar.qml ActiveWindow.qml ClockWidget.qml Workspaces.qml; do
  sib_path="$HOME/.config/quickshell/ii/modules/ii/bar/$sibling"
  if [[ -f "$sib_path" && ! -L "$sib_path" ]]; then
    pass "S1: sibling module $sibling remains an intact regular file"
  else
    fail "S1: sibling module $sibling missing or turned into a symlink"
  fi
done

# 4. Assert vendor/dots-hyprland submodule remains completely clean
if [[ -z "$(git -C "$REPO_ROOT/vendor/dots-hyprland" status --porcelain)" ]]; then
  pass "S1: vendor/dots-hyprland working tree is 100% clean"
else
  fail "S1: vendor/dots-hyprland working tree has uncommitted modifications"
fi
```

##### Section 2: QML Property & Unclamped Sizing Integrity (PILL-02, PILL-03, D-01)
```bash
CONTENT_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"

# 1. Assert absence of centerSideModuleWidth clamps in leftCenterGroup and rightCenterGroup
# Check leftCenterGroup block does NOT contain implicitWidth: root.centerSideModuleWidth
if awk '/id: leftCenterGroup/,/id: middleCenterGroup/' "$CONTENT_QML" | grep -q 'implicitWidth: root.centerSideModuleWidth'; then
  fail "S2: leftCenterGroup still contains implicitWidth: root.centerSideModuleWidth clamp"
else
  pass "S2: leftCenterGroup is free of artificial width clamp (D-01)"
fi

# Check rightCenterGroup block does NOT contain implicitWidth: root.centerSideModuleWidth
if awk '/id: rightCenterGroup/,/BarGroup {/' "$CONTENT_QML" | grep -q 'implicitWidth: root.centerSideModuleWidth'; then
  fail "S2: rightCenterGroup still contains implicitWidth: root.centerSideModuleWidth clamp"
else
  pass "S2: rightCenterGroup is free of artificial width clamp (D-01)"
fi

# 2. Assert dynamic implicitWidth and implicitHeight propagation in rightCenterGroup
if awk '/id: rightCenterGroup/,/BarGroup {/' "$CONTENT_QML" | grep -q 'implicitWidth: rightCenterGroupContent.implicitWidth'; then
  pass "S2: rightCenterGroup propagates rightCenterGroupContent.implicitWidth (D-01)"
else
  fail "S2: rightCenterGroup missing dynamic implicitWidth propagation"
fi

if awk '/id: rightCenterGroup/,/BarGroup {/' "$CONTENT_QML" | grep -q 'implicitHeight: rightCenterGroupContent.implicitHeight'; then
  pass "S2: rightCenterGroup propagates rightCenterGroupContent.implicitHeight (D-01)"
else
  fail "S2: rightCenterGroup missing dynamic implicitHeight propagation"
fi
```

##### Section 3: Dynamic Animation & Visual Defaults (PILL-02, PILL-03, PILL-04, D-02, D-03)
```bash
GROUP_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml"
CONTENT_QML="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"

# 1. Assert Behavior on implicitWidth with emphasizedDecel curve and 250ms duration in BarGroup.qml
if grep -q 'Behavior on implicitWidth' "$GROUP_QML" && \
   grep -q 'easing.bezierCurve: Appearance.animationCurves.emphasizedDecel' "$GROUP_QML" && \
   grep -q 'duration: 250' "$GROUP_QML" && \
   grep -q 'enabled: !root.vertical' "$GROUP_QML"; then
  pass "S3: BarGroup.qml declares animated Behavior on implicitWidth with emphasizedDecel (250ms) (D-02, PILL-03)"
else
  fail "S3: BarGroup.qml missing correct Behavior on implicitWidth definition"
fi

# 2. Assert upstream visual styling fidelity tokens in BarGroup.qml (D-03)
if grep -q 'radius: Appearance.rounding.small' "$GROUP_QML"; then
  pass "S3: BarGroup.qml uses Appearance.rounding.small (12px) (PILL-02, D-03)"
else
  fail "S3: BarGroup.qml missing Appearance.rounding.small"
fi

if grep -q 'property real padding: 5' "$GROUP_QML"; then
  pass "S3: BarGroup.qml preserves padding: 5 (PILL-03, D-03)"
else
  fail "S3: BarGroup.qml missing padding: 5"
fi

if grep -q 'color: Config.options?.bar.borderless ? "transparent" : Appearance.colors.colLayer1' "$GROUP_QML"; then
  pass "S3: BarGroup.qml preserves borderless background toggling and colLayer1 (PILL-04, D-03)"
else
  fail "S3: BarGroup.qml missing standard borderless color condition"
fi

# 3. Assert middleSection spacing: 4 and VerticalBarSeparator borderless binding in BarContent.qml
if grep -q 'spacing: 4' "$CONTENT_QML"; then
  pass "S3: BarContent.qml preserves inter-pill spacing: 4 (D-03)"
else
  fail "S3: BarContent.qml missing spacing: 4"
fi

if grep -q 'visible: Config.options?.bar.borderless' "$CONTENT_QML"; then
  pass "S3: BarContent.qml preserves VerticalBarSeparator borderless binding (PILL-04)"
else
  fail "S3: BarContent.qml missing VerticalBarSeparator borderless binding"
fi
```

##### Section 4: Repository Hygiene & Verification Engine (PILL-01, D-06, D-08, INTG-02)
```bash
# 1. Assert restow/README.md matches fresh ./scripts/gen-collision-map.sh --restow-table
GEN_TABLE="$(mktemp /tmp/p31-gen-table-XXXXXX)"
TMP_FILES+=("$GEN_TABLE")
"$REPO_ROOT/scripts/gen-collision-map.sh" --restow-table > "$GEN_TABLE"

README_TABLE="$(mktemp /tmp/p31-readme-table-XXXXXX)"
TMP_FILES+=("$README_TABLE")
awk '/<!-- BEGIN generated: gen-collision-map.sh --restow-table -->/{flag=1; next} /<!-- END generated: gen-collision-map.sh --restow-table -->/{flag=0} flag' "$REPO_ROOT/restow/README.md" > "$README_TABLE"

if cmp -s "$GEN_TABLE" "$README_TABLE"; then
  pass "S4: restow/README.md generated table matches ./scripts/gen-collision-map.sh --restow-table"
else
  fail "S4: restow/README.md generated table is out of sync with collision-map generator"
  diff -u "$GEN_TABLE" "$README_TABLE" || true
fi

# Assert quickshell entry is present in generated table with rsync-replace tag
if grep -q '| `quickshell` | `rsync-replace` | `cd restow && stow --verbose=5 --no-folding -t ~ quickshell` |' "$README_TABLE"; then
  pass "S4: restow/README.md contains quickshell package with rsync-replace tag"
else
  fail "S4: restow/README.md missing quickshell rsync-replace entry"
fi

# 2. Strict system verifier gate
VERIFY_SCRIPT="$REPO_ROOT/arch/dots-hyprland.sh"
if [[ -x "$VERIFY_SCRIPT" ]]; then
  v_rc=0
  v_out="$("$VERIFY_SCRIPT" verify --strict 2>&1)" || v_rc=$?
  if [[ "$v_rc" -eq 0 ]] && printf '%s\n' "$v_out" | grep -q 'FINDINGS=0'; then
    pass "S4: ./arch/dots-hyprland.sh verify --strict passed with 0 findings (D-08, INTG-02)"
  else
    fail "S4: ./arch/dots-hyprland.sh verify --strict failed (exit code $v_rc)"
    printf '%s\n' "$v_out" | tail -n 20 | sed 's/^/       /' >&2
  fi
else
  fail "S4: arch/dots-hyprland.sh missing or not executable"
fi
```

---

### 2.4. `restow/README.md` (Package Recovery Documentation)

#### Role & Update Mechanism
`restow/README.md` documents the contract for packages subject to installer overwrites.
Section 3 of this document contains a machine-generated markdown table enclosed between comment markers:
`<!-- BEGIN generated: gen-collision-map.sh --restow-table -->` and `<!-- END generated: gen-collision-map.sh --restow-table -->`.

When `restow/quickshell/` is created, running `./scripts/gen-collision-map.sh --restow-table` detects row 83 in `collision-map.tsv` (`$XDG_CONFIG_HOME/quickshell` -> `install_dir__sync`, `DESTROYED`, `restow`). It classifies the package as `rsync-replace` and outputs the row:
```markdown
| `quickshell` | `rsync-replace` | `cd restow && stow --verbose=5 --no-folding -t ~ quickshell` |
```

#### Closest Codebase Analog
[restow/README.md](file:///home/pera/github_repo/.dotfiles/restow/README.md#L46-L65)

#### Generated Table Pattern (Section 3)
```markdown
<!-- BEGIN generated: gen-collision-map.sh --restow-table -->
| Package | Tag | Recovery Command |
|---|---|---|
| `chrome-flags` | `cp-through` | `git checkout -- restow/chrome-flags/.config/chrome-flags.conf && cd restow && stow --verbose=5 --no-folding -t ~ chrome-flags` |
| `dolphinrc` | `cp-through` | `git checkout -- restow/dolphinrc/.config/dolphinrc && cd restow && stow --verbose=5 --no-folding -t ~ dolphinrc` |
| `fuzzel` | `rsync-replace` | `cd restow && stow --verbose=5 --no-folding -t ~ fuzzel` |
| `hypr` | `rsync-replace` | `cd restow && stow --verbose=5 --no-folding -t ~ hypr` |
| `kitty` | `rsync-replace` | `cd restow && stow --verbose=5 --no-folding -t ~ kitty` |
| `quickshell` | `rsync-replace` | `cd restow && stow --verbose=5 --no-folding -t ~ quickshell` |
| `starship` | `cp-through` | `git checkout -- restow/starship/.config/starship.toml && cd restow && stow --verbose=5 --no-folding -t ~ starship` |
<!-- END generated: gen-collision-map.sh --restow-table -->
```

---

## 3. Cross-Cutting Operational Patterns

### 3.1. Safe Stow Overlay Deployment Procedure (Replacing Banned `--adopt`)
**Context:** `~/.config/quickshell/ii/modules/ii/bar/` already exists and contains regular files installed by dots-hyprland (`BarContent.qml` and `BarGroup.qml`).  
GNU Stow refuses to create symlinks over existing regular files, and `--adopt` is strictly banned (`stow/README.md:64-73`).

**Execution Pattern:**
1. Populate repository files:
   - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml`
   - `restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml`
2. Remove or backup the two regular files in `$HOME`:
   ```bash
   rm -f "$HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml" \
         "$HOME/.config/quickshell/ii/modules/ii/bar/BarGroup.qml"
   ```
3. Deploy the overlay symlinks with `--no-folding`:
   ```bash
   cd restow && stow --verbose=5 --no-folding -t ~ quickshell
   ```
4. Verify leaf symlinks:
   ```bash
   test -L "$HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
   test -L "$HOME/.config/quickshell/ii/modules/ii/bar/BarGroup.qml"
   ```
   and ensure ancestor directories remain real directories (no folding).

### 3.2. Live Quickshell Reload Pattern
**Context:** Quickshell caches QML in memory. After modifying or stowing overlay QML files, reload the shell process.  
**Methods:**
- Operator hotkey: `Ctrl+Super+R` (configured in `~/.config/hypr/hyprland/keybinds.lua:56`).
- Scripted / headless execution:
  ```bash
  killall qs quickshell 2>/dev/null || true
  nohup qs -c ii >/dev/null 2>&1 &
  ```

---

## 4. Anti-Patterns to Avoid

| Anti-Pattern | Why Prohibited | Proper Alternative |
|---|---|---|
| Editing files in `vendor/dots-hyprland/` | Breaks submodule pin tracking, prevents clean vendor updates, and pollutes git tree. | Author changes exclusively in `restow/quickshell/` and stow into `$HOME`. |
| Running `stow` without `--no-folding` | Stow folds `~/.config/quickshell` into a directory symlink, destroying siblings and failing strict verification. | Always specify `stow --verbose=5 --no-folding -t ~ <pkg>`. |
| Using `stow --adopt` | Overwrites local repo changes with target files on disk. Strictly banned in repository policy. | Remove or backup live target files prior to stowing. |
| Hardcoding pixel width floors/ceilings (`Math.max(200, ...)`) | Violates D-04 and prevents true dynamic content-driven pill sizing. | Allow `BarGroup`'s `gridLayout.implicitWidth + padding * 2` to govern pill width fluidly. |
| Using `qmllint` or `qmlformat` in bash assertions | Standalone Qt 6 tools crash on ECMAScript optional chaining (`?.`), causing false test failures. | Validate QML integrity via regex/token checks and live shell execution. |
| Hand-editing Section 3 in `restow/README.md` | Causes Phase 18 capture-model assertion failures due to byte discrepancies. | Run `./scripts/gen-collision-map.sh --restow-table` to update the section. |

---

*Pattern map generated for Phase 31 planning.*
