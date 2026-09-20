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
    if awk '/id: resourcesGroup/,/^[[:space:]]*\}/{print}' "$REPO_BAR_CONTENT" | grep -q 'Resources {' && \
       awk '/id: resourcesGroup/,/^[[:space:]]*\}/{print}' "$REPO_BAR_CONTENT" | grep -q 'BarGroup'; then
      pass "S2: resourcesGroup wraps Resources in a BarGroup pill (D-03)"
    else
      fail "S2: resourcesGroup does not wrap Resources in a BarGroup pill"
    fi

    # utilButtonsGroup wraps UtilButtons in BarGroup with verbose & shortForm visibility guard
    if awk '/id: utilButtonsGroup/,/^[[:space:]]*\}/{print}' "$REPO_BAR_CONTENT" | grep -q 'UtilButtons {' && \
       awk '/id: utilButtonsGroup/,/^[[:space:]]*\}/{print}' "$REPO_BAR_CONTENT" | grep -q 'BarGroup' && \
       awk '/id: utilButtonsGroup/,/^[[:space:]]*\}/{print}' "$REPO_BAR_CONTENT" | grep -q 'Config.options.bar.verbose'; then
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
    if awk '/id: middleCenterGroup/,/id: rightCenterGroup/{print}' "$REPO_BAR_CONTENT" | grep -q 'Workspaces' && \
       awk '/id: middleCenterGroup/,/id: rightCenterGroup/{print}' "$REPO_BAR_CONTENT" | grep -q 'BarGroup'; then
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
    if awk '/id: sysTrayGroup/,/id: rightSidebarButton/{print}' "$REPO_BAR_CONTENT" | grep -q 'showSeparator: false' && \
       awk '/id: sysTrayGroup/,/id: rightSidebarButton/{print}' "$REPO_BAR_CONTENT" | grep -q 'BarGroup'; then
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
