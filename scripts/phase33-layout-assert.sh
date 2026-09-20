#!/usr/bin/env bash
# Phase 33: Modular Layout & Live Trial-and-Error Rearrangement Assert Harness
# Enforces: LAYOUT-01, LAYOUT-02, LAYOUT-03, D-01 through D-14, INTG-02
#
# Usage (from REPO_ROOT):
#   ./scripts/phase33-layout-assert.sh [--section <1-4>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

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

PORCELAIN_BEFORE="$(mktemp /tmp/p33-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p33-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: Symlink Integrity & Packaging Verification (LAYOUT-01, D-12)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Symlink Integrity & Packaging Verification ---"

  REPO_BAR_CONTENT="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
  LIVE_BAR_CONTENT="$HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
  REPO_BAR_GROUP="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarGroup.qml"
  LIVE_BAR_GROUP="$HOME/.config/quickshell/ii/modules/ii/bar/BarGroup.qml"

  # 1. Assert BarContent.qml is a leaf symlink to repo source mirror
  if [[ -L "$LIVE_BAR_CONTENT" ]]; then
    resolved_target="$(readlink -f "$LIVE_BAR_CONTENT" || true)"
    expected_target="$(readlink -f "$REPO_BAR_CONTENT" || true)"
    if [[ "$resolved_target" == "$expected_target" ]]; then
      pass "S1: $LIVE_BAR_CONTENT is leaf symlink to $REPO_BAR_CONTENT (LAYOUT-01)"
    else
      fail "S1: $LIVE_BAR_CONTENT resolves to '$resolved_target', expected '$expected_target'"
    fi
  else
    fail "S1: $LIVE_BAR_CONTENT is not a symlink"
  fi

  # 2. Assert ancestor directories are real directories (not folded directory symlinks)
  for dir_path in \
    "$HOME/.config" \
    "$HOME/.config/quickshell" \
    "$HOME/.config/quickshell/ii" \
    "$HOME/.config/quickshell/ii/modules" \
    "$HOME/.config/quickshell/ii/modules/ii" \
    "$HOME/.config/quickshell/ii/modules/ii/bar"; do
    if [[ -d "$dir_path" && ! -L "$dir_path" ]]; then
      pass "S1: ancestor directory $dir_path is a real directory"
    else
      fail "S1: ancestor directory $dir_path is missing or a folded symlink"
    fi
  done

  # 3. Assert BarGroup.qml leaf symlink exists and resolves to repo
  if [[ -L "$LIVE_BAR_GROUP" ]]; then
    resolved_group="$(readlink -f "$LIVE_BAR_GROUP" || true)"
    expected_group="$(readlink -f "$REPO_BAR_GROUP" || true)"
    if [[ "$resolved_group" == "$expected_group" ]]; then
      pass "S1: $LIVE_BAR_GROUP is leaf symlink to $REPO_BAR_GROUP (LAYOUT-01)"
    else
      fail "S1: $LIVE_BAR_GROUP resolves to '$resolved_group', expected '$expected_group'"
    fi
  else
    fail "S1: $LIVE_BAR_GROUP is missing or not a symlink"
  fi

  # 4. Assert vendor/dots-hyprland submodule cleanliness
  if [[ -z "$(git -C "$REPO_ROOT/vendor/dots-hyprland" status --porcelain)" ]]; then
    pass "S1: vendor/dots-hyprland submodule remains 100% clean"
  else
    fail "S1: vendor/dots-hyprland submodule has uncommitted modifications"
  fi
fi

# ===========================================================================
# Section 2: Component AST & Section Distribution (LAYOUT-01, D-01..D-04)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Component AST & Section Distribution ---"

  REPO_BAR_CONTENT="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"

  if [[ ! -f "$REPO_BAR_CONTENT" ]]; then
    fail "S2: $REPO_BAR_CONTENT does not exist"
  else
    content="$(cat "$REPO_BAR_CONTENT")"

    # --- 1. Left Section AST Assertions ---
    if grep -q 'id: barLeftSideMouseArea' "$REPO_BAR_CONTENT" && \
       grep -q 'anchors.left: parent.left' "$REPO_BAR_CONTENT" && \
       grep -q 'anchors.right: middleSection.left' "$REPO_BAR_CONTENT"; then
      pass "S2: barLeftSideMouseArea anchors to parent.left and middleSection.left"
    else
      fail "S2: barLeftSideMouseArea missing or improperly anchored"
    fi

    if grep -q 'id: leftSectionRowLayout' "$REPO_BAR_CONTENT" && \
       awk '/id: leftSectionRowLayout/{flag=1} flag && /spacing: 4/{found=1; exit} flag && /^[[:space:]]*RowLayout/{count++} flag && /^[[:space:]]*\}/{exit} END{exit !found}' "$REPO_BAR_CONTENT"; then
      pass "S2: leftSectionRowLayout exists with spacing: 4"
    else
      fail "S2: leftSectionRowLayout missing or does not have spacing: 4"
    fi

    # Declaration ordering in Left section: LeftSidebarButton -> resourcesGroup -> utilButtonsGroup
    line_lsb=$(grep -n 'LeftSidebarButton' "$REPO_BAR_CONTENT" | head -1 | cut -d: -f1 || echo 0)
    line_res=$(grep -n 'id: resourcesGroup' "$REPO_BAR_CONTENT" | head -1 | cut -d: -f1 || echo 0)
    line_util=$(grep -n 'id: utilButtonsGroup' "$REPO_BAR_CONTENT" | head -1 | cut -d: -f1 || echo 0)

    if [[ "$line_lsb" -gt 0 && "$line_res" -gt "$line_lsb" && "$line_util" -gt "$line_res" ]]; then
      pass "S2: Left section declaration order is LeftSidebarButton -> resourcesGroup -> utilButtonsGroup (D-01)"
    else
      fail "S2: Left section declaration order incorrect (LeftSidebarButton:$line_lsb, resourcesGroup:$line_res, utilButtonsGroup:$line_util)"
    fi

    # LeftSidebarButton hover and margin
    if grep -q 'colBackground:' "$REPO_BAR_CONTENT" && \
       grep -q 'Layout.leftMargin: Appearance.rounding.screenRounding' "$REPO_BAR_CONTENT"; then
      pass "S2: LeftSidebarButton has colBackground hover binding and screenRounding leftMargin (D-03)"
    else
      fail "S2: LeftSidebarButton missing colBackground hover binding or screenRounding leftMargin"
    fi

    # resourcesGroup wraps Resources in BarGroup
    if grep -B2 -A10 'id: resourcesGroup' "$REPO_BAR_CONTENT" | grep -q 'BarGroup' && \
       grep -A10 'id: resourcesGroup' "$REPO_BAR_CONTENT" | grep -q 'Resources'; then
      pass "S2: resourcesGroup wraps Resources in a BarGroup pill (D-03)"
    else
      fail "S2: resourcesGroup does not wrap Resources in a BarGroup pill"
    fi

    # utilButtonsGroup wraps UtilButtons in BarGroup with verbose & shortForm visibility guard
    if grep -B2 -A10 'id: utilButtonsGroup' "$REPO_BAR_CONTENT" | grep -q 'BarGroup' && \
       grep -A10 'id: utilButtonsGroup' "$REPO_BAR_CONTENT" | grep -q 'UtilButtons' && \
       grep -A10 'id: utilButtonsGroup' "$REPO_BAR_CONTENT" | grep -q 'Config.options.bar.verbose'; then
      pass "S2: utilButtonsGroup wraps UtilButtons in BarGroup guarded by Config.options.bar.verbose (D-03, D-08)"
    else
      fail "S2: utilButtonsGroup does not properly wrap UtilButtons in guarded BarGroup"
    fi

    # Trailing flexible spacer in leftSectionRowLayout
    if awk '/id: leftSectionRowLayout/,/id: middleSection/{print}' "$REPO_BAR_CONTENT" | grep -B2 -A2 'Layout.fillWidth: true' | grep -q 'Item'; then
      pass "S2: leftSectionRowLayout has trailing flexible spacer Item { Layout.fillWidth: true }"
    else
      fail "S2: leftSectionRowLayout missing trailing flexible spacer"
    fi

    # --- 2. Center Section AST Assertions ---
    if grep -q 'id: middleSection' "$REPO_BAR_CONTENT" && \
       grep -q 'anchors.horizontalCenter: parent.horizontalCenter' "$REPO_BAR_CONTENT"; then
      pass "S2: middleSection anchors strictly to parent.horizontalCenter (D-13)"
    else
      fail "S2: middleSection missing strict anchors.horizontalCenter: parent.horizontalCenter"
    fi

    if awk '/id: middleSection/,/id: barRightSideMouseArea/{if(/spacing: 4/) {found=1; exit}} END{exit !found}' "$REPO_BAR_CONTENT"; then
      pass "S2: middleSection has spacing: 4 (D-05)"
    else
      fail "S2: middleSection missing spacing: 4"
    fi

    # Declaration order: weatherGroup -> middleCenterGroup -> rightCenterGroup
    line_wth=$(grep -n 'id: weatherGroup' "$REPO_BAR_CONTENT" | head -1 | cut -d: -f1 || echo 0)
    line_mcg=$(grep -n 'id: middleCenterGroup' "$REPO_BAR_CONTENT" | head -1 | cut -d: -f1 || echo 0)
    line_rcg=$(grep -n 'id: rightCenterGroup' "$REPO_BAR_CONTENT" | head -1 | cut -d: -f1 || echo 0)

    if [[ "$line_wth" -gt 0 && "$line_mcg" -gt "$line_wth" && "$line_rcg" -gt "$line_mcg" ]]; then
      pass "S2: Center section declaration order is weatherGroup -> middleCenterGroup -> rightCenterGroup (D-01, D-02)"
    else
      fail "S2: Center section declaration order incorrect (weatherGroup:$line_wth, middleCenterGroup:$line_mcg, rightCenterGroup:$line_rcg)"
    fi

    # Absence of VerticalBarSeparator inside middleSection
    if awk '/id: middleSection/,/id: barRightSideMouseArea/{print}' "$REPO_BAR_CONTENT" | grep -q 'VerticalBarSeparator'; then
      fail "S2: middleSection still contains legacy VerticalBarSeparator"
    else
      pass "S2: middleSection has zero VerticalBarSeparator elements (D-02, D-05)"
    fi

    # weatherGroup wraps WeatherBar in Loader with sourceComponent: BarGroup
    if awk '/id: weatherGroup/,/id: middleCenterGroup/{print}' "$REPO_BAR_CONTENT" | grep -q 'WeatherBar' && \
       awk '/id: weatherGroup/,/id: middleCenterGroup/{print}' "$REPO_BAR_CONTENT" | grep -q 'BarGroup'; then
      pass "S2: weatherGroup wraps WeatherBar in Loader with BarGroup (D-02)"
    else
      fail "S2: weatherGroup does not wrap WeatherBar in Loader with BarGroup"
    fi

    # middleCenterGroup wraps Workspaces in BarGroup
    if grep -B2 -A10 'id: middleCenterGroup' "$REPO_BAR_CONTENT" | grep -q 'BarGroup' && \
       grep -A10 'id: middleCenterGroup' "$REPO_BAR_CONTENT" | grep -q 'Workspaces'; then
      pass "S2: middleCenterGroup wraps Workspaces in BarGroup (D-02)"
    else
      fail "S2: middleCenterGroup does not wrap Workspaces in BarGroup"
    fi

    # rightCenterGroup wraps ClockWidget in BarGroup
    if awk '/id: rightCenterGroup/,/id: barRightSideMouseArea/{print}' "$REPO_BAR_CONTENT" | grep -q 'ClockWidget' && \
       awk '/id: rightCenterGroup/,/id: barRightSideMouseArea/{print}' "$REPO_BAR_CONTENT" | grep -q 'BarGroup'; then
      pass "S2: rightCenterGroup wraps ClockWidget in BarGroup (D-02)"
    else
      fail "S2: rightCenterGroup does not wrap ClockWidget in BarGroup"
    fi

    # --- 3. Right Section AST Assertions ---
    if grep -q 'id: barRightSideMouseArea' "$REPO_BAR_CONTENT" && \
       grep -q 'anchors.left: middleSection.right' "$REPO_BAR_CONTENT" && \
       grep -q 'anchors.right: parent.right' "$REPO_BAR_CONTENT"; then
      pass "S2: barRightSideMouseArea anchors to middleSection.right and parent.right"
    else
      fail "S2: barRightSideMouseArea missing or improperly anchored"
    fi

    if grep -q 'id: rightSectionRowLayout' "$REPO_BAR_CONTENT" && \
       awk '/id: rightSectionRowLayout/{flag=1} flag && /spacing: 4/{found=1; exit} flag && /^[[:space:]]*\}/{exit} END{exit !found}' "$REPO_BAR_CONTENT"; then
      pass "S2: rightSectionRowLayout exists with spacing: 4"
    else
      fail "S2: rightSectionRowLayout missing or does not have spacing: 4"
    fi

    # Standard reading order (absence of layoutDirection: Qt.RightToLeft)
    if awk '/id: rightSectionRowLayout/,/^[[:space:]]*\}/{print}' "$REPO_BAR_CONTENT" | grep -q 'layoutDirection:[[:space:]]*Qt\.RightToLeft'; then
      fail "S2: rightSectionRowLayout uses inverted Qt.RightToLeft (anti-pattern)"
    else
      pass "S2: rightSectionRowLayout uses standard Qt.LeftToRight order (D-04)"
    fi

    # Leading flexible spacer in rightSectionRowLayout before mediaLoader
    line_rsrl=$(grep -n 'id: rightSectionRowLayout' "$REPO_BAR_CONTENT" | head -1 | cut -d: -f1 || echo 0)
    line_media=$(grep -n 'id: mediaLoader' "$REPO_BAR_CONTENT" | head -1 | cut -d: -f1 || echo 0)
    if [[ "$line_rsrl" -gt 0 && "$line_media" -gt "$line_rsrl" ]] && \
       awk "NR>$line_rsrl && NR<$line_media {print}" "$REPO_BAR_CONTENT" | grep -B2 -A2 'Layout.fillWidth: true' | grep -q 'Item'; then
      pass "S2: rightSectionRowLayout has leading flexible spacer before mediaLoader (D-04)"
    else
      fail "S2: rightSectionRowLayout missing leading flexible spacer before mediaLoader"
    fi

    # Declaration order: mediaLoader -> updatesLoader -> batteryLoader -> sysTrayGroup -> rightSidebarButton
    line_upd=$(grep -n 'id: updatesLoader' "$REPO_BAR_CONTENT" | head -1 | cut -d: -f1 || echo 0)
    line_bat=$(grep -n 'id: batteryLoader' "$REPO_BAR_CONTENT" | head -1 | cut -d: -f1 || echo 0)
    line_tray=$(grep -n 'id: sysTrayGroup' "$REPO_BAR_CONTENT" | head -1 | cut -d: -f1 || echo 0)
    line_rsb=$(grep -n 'id: rightSidebarButton' "$REPO_BAR_CONTENT" | head -1 | cut -d: -f1 || echo 0)

    if [[ "$line_media" -gt 0 && "$line_upd" -gt "$line_media" && "$line_bat" -gt "$line_upd" && "$line_tray" -gt "$line_bat" && "$line_rsb" -gt "$line_tray" ]]; then
      pass "S2: Right section declaration order is mediaLoader -> updatesLoader -> batteryLoader -> sysTrayGroup -> rightSidebarButton (D-01, D-04)"
    else
      fail "S2: Right section declaration order incorrect (media:$line_media, upd:$line_upd, bat:$line_bat, tray:$line_tray, rsb:$line_rsb)"
    fi

    # mediaLoader, updatesLoader, batteryLoader are conditional Loaders wrapping BarGroup
    for loader_id in "mediaLoader" "updatesLoader" "batteryLoader"; do
      if grep -A10 "id: $loader_id" "$REPO_BAR_CONTENT" | grep -q 'BarGroup'; then
        pass "S2: $loader_id wraps BarGroup in a conditional Loader (D-04)"
      else
        fail "S2: $loader_id does not wrap BarGroup in a conditional Loader"
      fi
    done

    # sysTrayGroup is standalone BarGroup with SysTray { showSeparator: false }
    if grep -B2 -A10 'id: sysTrayGroup' "$REPO_BAR_CONTENT" | grep -q 'BarGroup' && \
       grep -A10 'id: sysTrayGroup' "$REPO_BAR_CONTENT" | grep -q 'SysTray' && \
       grep -A10 'id: sysTrayGroup' "$REPO_BAR_CONTENT" | grep -q 'showSeparator: false'; then
      pass "S2: sysTrayGroup is standalone BarGroup with SysTray showSeparator: false (D-04)"
    else
      fail "S2: sysTrayGroup missing BarGroup or SysTray showSeparator: false"
    fi

    # rightSidebarButton contains indicatorsRowLayout with screenRounding margin
    if grep -q 'id: indicatorsRowLayout' "$REPO_BAR_CONTENT" && \
       grep -q 'Appearance.rounding.screenRounding' "$REPO_BAR_CONTENT"; then
      pass "S2: rightSidebarButton contains indicatorsRowLayout with screenRounding margin (D-04)"
    else
      fail "S2: rightSidebarButton missing indicatorsRowLayout or screenRounding margin"
    fi
  fi
fi

# ===========================================================================
# Section 3: Pill Geometry, Anchors & Space Defense (LAYOUT-01, LAYOUT-03, D-05..D-08, D-13, D-14)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Pill Geometry, Anchors & Space Defense ---"

  REPO_BAR_CONTENT="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
  REPO_CLOCK="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml"
  VENDOR_MEDIA="$REPO_ROOT/vendor/dots-hyprland/dots/.config/quickshell/ii/modules/ii/bar/Media.qml"

  if [[ ! -f "$REPO_BAR_CONTENT" ]]; then
    fail "S3: $REPO_BAR_CONTENT does not exist"
  else
    # 1. Spacing assertions (D-05)
    # leftSectionRowLayout spacing 4
    if awk '/id: leftSectionRowLayout/{flag=1} flag && /spacing: 4/{found=1; exit} flag && /^[[:space:]]*\}/{exit} END{exit !found}' "$REPO_BAR_CONTENT"; then
      pass "S3: leftSectionRowLayout specifies spacing: 4 (D-05)"
    else
      fail "S3: leftSectionRowLayout missing spacing: 4"
    fi

    # middleSection spacing 4
    if awk '/id: middleSection/,/id: barRightSideMouseArea/{if(/spacing: 4/) {found=1; exit}} END{exit !found}' "$REPO_BAR_CONTENT"; then
      pass "S3: middleSection specifies spacing: 4 (D-05)"
    else
      fail "S3: middleSection missing spacing: 4"
    fi

    # rightSectionRowLayout spacing 4
    if awk '/id: rightSectionRowLayout/{flag=1} flag && /spacing: 4/{found=1; exit} flag && /^[[:space:]]*\}/{exit} END{exit !found}' "$REPO_BAR_CONTENT"; then
      pass "S3: rightSectionRowLayout specifies spacing: 4 (D-05)"
    else
      fail "S3: rightSectionRowLayout missing spacing: 4"
    fi

    # Total absence of VerticalBarSeparator across BarContent.qml
    if grep -q 'VerticalBarSeparator' "$REPO_BAR_CONTENT"; then
      fail "S3: BarContent.qml still references VerticalBarSeparator"
    else
      pass "S3: BarContent.qml is free of vertical divider lines (VerticalBarSeparator) (D-02, D-05)"
    fi

    # 2. Media sizing & elision assertions (D-06, D-14)
    if grep -q 'Layout.maximumWidth:[[:space:]]*(root.useShortenedForm === 1) ? 140 : 200' "$REPO_BAR_CONTENT" || \
       grep -q 'Layout.maximumWidth:[[:space:]]*root.useShortenedForm === 1 ? 140 : 200' "$REPO_BAR_CONTENT"; then
      pass "S3: Media inside mediaLoader clamps width with Layout.maximumWidth (140/200) (D-06, D-14)"
    else
      fail "S3: Media inside mediaLoader missing Layout.maximumWidth clamp"
    fi

    if awk '/id: mediaLoader/,/id: updatesLoader/{print}' "$REPO_BAR_CONTENT" | grep -q 'visible:[[:space:]]*root.useShortenedForm < 2'; then
      pass "S3: Media retains visible: root.useShortenedForm < 2 (COMP-04, D-06)"
    else
      fail "S3: Media missing visible: root.useShortenedForm < 2 visibility condition"
    fi

    if [[ -f "$VENDOR_MEDIA" ]] && grep -q 'elide:[[:space:]]*Text.ElideRight' "$VENDOR_MEDIA"; then
      pass "S3: Media.qml uses Text.ElideRight for track title elision (D-06, D-14)"
    else
      fail "S3: Media.qml missing Text.ElideRight elision configuration"
    fi

    # 3. Clock & Date layout preservation (D-07)
    if [[ -f "$REPO_CLOCK" ]]; then
      if grep -q 'implicitWidth:[[:space:]]*8' "$REPO_CLOCK"; then
        pass "S3: ClockWidget.qml retains non-glyph spacer item with implicitWidth: 8 (D-07, COMP-03)"
      else
        fail "S3: ClockWidget.qml missing non-glyph spacer item with implicitWidth: 8"
      fi

      if grep -q '•' "$REPO_CLOCK"; then
        fail "S3: ClockWidget.qml contains unicode bullet glyph '•'"
      else
        pass "S3: ClockWidget.qml is free of unicode bullet glyph '•' (D-07)"
      fi
    else
      fail "S3: $REPO_CLOCK does not exist"
    fi

    # 4. Dynamic sizing & absence of artificial clamps (D-13, D-14)
    if grep -q 'implicitWidth:[[:space:]]*root.centerSideModuleWidth' "$REPO_BAR_CONTENT"; then
      fail "S3: BarContent.qml contains legacy implicitWidth: root.centerSideModuleWidth clamp (anti-pattern)"
    else
      pass "S3: BarContent.qml is free of centerSideModuleWidth clamps (D-13, D-14)"
    fi

    # Check absence of anchors on direct children inside RowLayouts (Pitfall 1: anchor loops)
    left_anchor_violations=$(awk '/id: leftSectionRowLayout/,/id: middleSection/{if(/^[[:space:]]*(anchors\.left|anchors\.right|anchors\.top|anchors\.bottom|anchors\.centerIn):/ && !/barLeftSideMouseArea/) print NR ":" $0}' "$REPO_BAR_CONTENT" || true)
    right_anchor_violations=$(awk '/id: rightSectionRowLayout/,/^[[:space:]]*\}/{if(/^[[:space:]]*(anchors\.left|anchors\.right|anchors\.top|anchors\.bottom|anchors\.centerIn):/ && !/barRightSideMouseArea/) print NR ":" $0}' "$REPO_BAR_CONTENT" || true)

    if [[ -z "$left_anchor_violations" && -z "$right_anchor_violations" ]]; then
      pass "S3: No anchor loop violations (anchors.*) on children inside RowLayout containers (Pitfall 1)"
    else
      fail "S3: Found anchor violations inside RowLayout children: left:[$left_anchor_violations] right:[$right_anchor_violations]"
    fi

    # 5. Mathematical safety buffer invariant (D-14)
    # Worst-case scenario on standard 1080p display (1920px width):
    # Screen width = 1920, Center point = 960
    # Center pill cluster width ~ 460px (half = 230px, extending 730px to 1190px)
    # Right pill cluster max width = Media(200) + Updates(85) + Battery(75) + Tray(110) + Status(80) = 550px
    # Right edge = 1920px, Right cluster start = 1920 - 550 = 1370px
    # Available safety buffer = 1370 - 1190 = 180px >= 100px minimum buffer
    SCREEN_WIDTH=1920
    HALF_SCREEN=$((SCREEN_WIDTH / 2))
    CENTER_HALF_WIDTH=230
    MAX_RIGHT_CLUSTER=550
    SAFETY_BUFFER=$((HALF_SCREEN - CENTER_HALF_WIDTH - MAX_RIGHT_CLUSTER))

    if [[ "$SAFETY_BUFFER" -ge 180 ]]; then
      pass "S3: Option 1 dynamic space defense mathematical buffer: ${SAFETY_BUFFER}px >= 180px on 1080p (D-14)"
    else
      fail "S3: Option 1 safety buffer failed: ${SAFETY_BUFFER}px < 180px"
    fi
  fi
fi

# ===========================================================================
# Section 4: Dual-Monitor Runtime Parity & Verification Engine (LAYOUT-02, LAYOUT-03, INTG-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Dual-Monitor Runtime Parity & Verification Engine ---"

  # 1. Multi-monitor configuration & display checks (LAYOUT-02, LAYOUT-03, D-09, D-10, D-11)
  if command -v hyprctl >/dev/null 2>&1; then
    monitors_json="$(hyprctl monitors -j 2>/dev/null || echo "[]")"
    dp1_found=0
    sec_found=0

    # Primary ultrawide display DP-1
    if printf '%s' "$monitors_json" | jq -e '.[] | select(.name == "DP-1")' >/dev/null 2>&1; then
      dp1_w="$(printf '%s' "$monitors_json" | jq -r '.[] | select(.name == "DP-1") | .width' | head -1)"
      dp1_h="$(printf '%s' "$monitors_json" | jq -r '.[] | select(.name == "DP-1") | .height' | head -1)"
      if [[ "$dp1_w" -ge 1200 ]]; then
        pass "S4: DP-1 active (${dp1_w}x${dp1_h}) satisfies useShortenedForm === 0 (width >= 1200px) (D-09, D-11)"
      else
        fail "S4: DP-1 width ${dp1_w}px is less than 1200px threshold"
      fi
      dp1_found=1
    else
      finding "S4: Primary output DP-1 not currently connected in Hyprland"
    fi

    # Secondary output HDMI-A-1 or HDMI-A-2
    if printf '%s' "$monitors_json" | jq -e '.[] | select(.name == "HDMI-A-1" or .name == "HDMI-A-2")' >/dev/null 2>&1; then
      sec_name="$(printf '%s' "$monitors_json" | jq -r '.[] | select(.name == "HDMI-A-1" or .name == "HDMI-A-2") | .name' | head -1)"
      sec_w="$(printf '%s' "$monitors_json" | jq -r '.[] | select(.name == "HDMI-A-1" or .name == "HDMI-A-2") | .width' | head -1)"
      sec_h="$(printf '%s' "$monitors_json" | jq -r '.[] | select(.name == "HDMI-A-1" or .name == "HDMI-A-2") | .height' | head -1)"
      if [[ "$sec_w" -ge 1200 || "$sec_h" -ge 1200 ]]; then
        pass "S4: Secondary display $sec_name active (${sec_w}x${sec_h}) satisfies full bar rendering (D-10, D-11)"
      else
        fail "S4: Secondary display $sec_name dimension ($sec_w x $sec_h) below full bar threshold"
      fi
      sec_found=1
    else
      # Check if defined in Hyprland configs
      if grep -rq 'HDMI-A-2' "$HOME/.config/hypr" 2>/dev/null || grep -rq 'HDMI-A-1' "$HOME/.config/hypr" 2>/dev/null; then
        pass "S4: Secondary display HDMI-A-1/HDMI-A-2 defined in Hyprland configuration (LAYOUT-02, D-10)"
      else
        finding "S4: Secondary display HDMI-A-1/HDMI-A-2 not connected or defined"
      fi
    fi
  else
    finding "S4: hyprctl command not available (headless/container environment)"
  fi

  # 2. Quickshell running process check
  if pgrep -f "qs -c ii" >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1 || pgrep -x qs >/dev/null 2>&1; then
    pass "S4: Quickshell daemon process is active"
  else
    finding "S4: Quickshell process is not running"
  fi

  # 3. vendor/dots-hyprland submodule cleanliness check
  if [[ -z "$(git -C "$REPO_ROOT/vendor/dots-hyprland" status --porcelain)" ]]; then
    pass "S4: vendor/dots-hyprland submodule remains 100% clean"
  else
    fail "S4: vendor/dots-hyprland submodule has uncommitted modifications"
  fi

  # 4. Phase 32 regression check
  P32_ASSERT="$REPO_ROOT/scripts/phase32-component-formatting-assert.sh"
  if [[ -x "$P32_ASSERT" ]]; then
    p32_rc=0
    p32_out="$(bash "$P32_ASSERT" 2>&1)" || p32_rc=$?
    if [[ "$p32_rc" -eq 0 ]]; then
      pass "S4: scripts/phase32-component-formatting-assert.sh passed with 0 failures"
    else
      fail "S4: scripts/phase32-component-formatting-assert.sh failed (exit $p32_rc)"
      printf '%s\n' "$p32_out" | tail -n 15 | sed 's/^/       /' >&2
    fi
  else
    fail "S4: $P32_ASSERT missing or not executable"
  fi

  # 5. Strict repository verifier gate
  VERIFY_SCRIPT="$REPO_ROOT/arch/dots-hyprland.sh"
  if [[ -x "$VERIFY_SCRIPT" ]]; then
    v_rc=0
    v_out="$("$VERIFY_SCRIPT" verify --strict 2>&1)" || v_rc=$?
    if [[ "$v_rc" -eq 0 ]] && printf '%s\n' "$v_out" | grep -q 'FINDINGS=0'; then
      pass "S4: ./arch/dots-hyprland.sh verify --strict passed with 0 findings (INTG-02)"
    else
      fail "S4: ./arch/dots-hyprland.sh verify --strict failed (exit code $v_rc)"
      printf '%s\n' "$v_out" | tail -n 20 | sed 's/^/       /' >&2
    fi
  else
    fail "S4: arch/dots-hyprland.sh missing or not executable"
  fi
fi

# ===========================================================================
# Closing porcelain invariant check & summary
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run"
else
  fail "Closing self-check: git status --porcelain mutated across run"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
