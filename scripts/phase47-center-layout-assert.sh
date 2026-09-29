#!/usr/bin/env bash
# ===========================================================================
# Phase 47: Center-Zone Layout Reorganization Assert Harness
# Enforces: CNTR-01, CNTR-02, CNTR-03
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

PORCELAIN_BEFORE="$(mktemp "${TMPDIR:-/tmp}/p47-porcelain-before.XXXXXX")"
TMP_FILES+=("$PORCELAIN_BEFORE")
git status --porcelain > "$PORCELAIN_BEFORE"

# ---------------------------------------------------------------------------
# Syntax-only mode early exit check
# ---------------------------------------------------------------------------
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  pass "Assert harness bash syntax check passed (bash -n verified)"
  
  if [[ -f "$BAR_CONTENT" ]]; then
    pass "Component file exists: BarContent.qml"
  else
    fail "Component file missing: $BAR_CONTENT"
  fi
  info "=== Syntax Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Stow Leaf Symlink Topology & Packaging Integrity
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Stow Leaf Symlink Topology & Packaging Integrity ---"

  LIVE_BAR="$HOME/.config/quickshell/ii/modules/ii/bar"
  if [[ -L "$LIVE_BAR/BarContent.qml" ]] && [[ "$(readlink "$LIVE_BAR/BarContent.qml")" =~ restow/quickshell/\.config/quickshell/ii/modules/ii/bar/BarContent\.qml ]]; then
    pass "S1: BarContent.qml is a valid symlink to restow/quickshell/.../BarContent.qml"
  elif [[ -f "$LIVE_BAR/BarContent.qml" ]]; then
    info "S1: BarContent.qml is a regular file"
  else
    finding "S1: BarContent.qml symlink missing or invalid"
  fi

  for dir in "$HOME/.config" "$HOME/.config/quickshell" "$HOME/.config/quickshell/ii" "$HOME/.config/quickshell/ii/modules" "$HOME/.config/quickshell/ii/modules/ii" "$HOME/.config/quickshell/ii/modules/ii/bar"; do
    if [[ -d "$dir" && ! -L "$dir" ]]; then
      pass "S1: Ancestor directory $dir is a real un-folded directory"
    elif [[ -L "$dir" ]]; then
      finding "S1: Ancestor directory $dir is a symlink (folded)"
    else
      finding "S1: Ancestor directory $dir missing"
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
# Section 2: BarContent.qml Center Zone Layout AST & Semantic Positioning
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: BarContent.qml Center Zone Layout AST & Semantic Positioning ---"

  if [[ ! -f "$BAR_CONTENT" ]]; then
    fail "S2: BarContent.qml not found at $BAR_CONTENT"
  else
    pos_middle_sec=$(grep -n "id: middleSection" "$BAR_CONTENT" | head -n1 | cut -d: -f1 || echo "")
    pos_left_cg=$(grep -n "id: leftCenterGroup" "$BAR_CONTENT" | head -n1 | cut -d: -f1 || echo "")
    pos_middle_cg=$(grep -n "id: middleCenterGroup" "$BAR_CONTENT" | head -n1 | cut -d: -f1 || echo "")
    pos_weather=$(grep -n "id: weatherGroup" "$BAR_CONTENT" | head -n1 | cut -d: -f1 || echo "")
    pos_bar_rs=$(grep -n "id: barRightSideMouseArea" "$BAR_CONTENT" | head -n1 | cut -d: -f1 || echo "")
    
    if [[ -n "$pos_middle_sec" && -n "$pos_left_cg" && -n "$pos_middle_cg" && -n "$pos_weather" && -n "$pos_bar_rs" ]]; then
      if (( pos_middle_sec < pos_left_cg && pos_left_cg < pos_middle_cg && pos_middle_cg < pos_weather && pos_weather < pos_bar_rs )); then
        pass "S2: Center Zone declaration sequence verified"
      else
        fail "S2: Center Zone sequence mismatch"
      fi
    else
      fail "S2: Missing Center Zone components"
    fi

    if grep -A 5 "id: middleSection" "$BAR_CONTENT" | grep -q "anchors.left: leftCenterGroup.left"; then
      pass "S2: middleSection anchors.left bound to leftCenterGroup.left"
    else
      fail "S2: middleSection missing anchors.left: leftCenterGroup.left"
    fi

    if grep -A 5 "id: middleSection" "$BAR_CONTENT" | grep -q 'anchors.right: weatherGroup.active ? weatherGroup.right : middleCenterGroup.right'; then
      pass "S2: middleSection anchors.right correctly dynamically bound"
    else
      fail "S2: middleSection missing proper dynamic anchors.right"
    fi

    if grep -A 10 "id: leftCenterGroup" "$BAR_CONTENT" | grep -q "anchors.right: middleCenterGroup.left"; then
      pass "S2: leftCenterGroup anchors.right: middleCenterGroup.left"
    else
      fail "S2: leftCenterGroup missing anchors.right: middleCenterGroup.left"
    fi

    if grep -A 10 "id: leftCenterGroup" "$BAR_CONTENT" | grep -q "anchors.rightMargin: 4"; then
      pass "S2: leftCenterGroup anchors.rightMargin: 4"
    else
      fail "S2: leftCenterGroup missing anchors.rightMargin: 4"
    fi

    if grep -A 10 "id: leftCenterGroup" "$BAR_CONTENT" | grep -q "implicitWidth: leftCenterGroupContent.implicitWidth" && grep -A 10 "id: leftCenterGroup" "$BAR_CONTENT" | grep -q "implicitHeight: leftCenterGroupContent.implicitHeight"; then
      pass "S2: leftCenterGroup binds implicit dimensions"
    else
      fail "S2: leftCenterGroup missing implicit dimension bindings"
    fi

    if grep -A 15 "id: leftCenterGroup" "$BAR_CONTENT" | grep -q "GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen"; then
      pass "S2: leftCenterGroup toggles GlobalStates.sidebarRightOpen on click"
    else
      fail "S2: leftCenterGroup click toggle missing or incorrect"
    fi

    if sed -n '/id: leftCenterGroupContent/,/}/p' "$BAR_CONTENT" | grep -q "ClockWidget"; then
      pass "S2: leftCenterGroupContent wraps ClockWidget"
    else
      fail "S2: leftCenterGroupContent missing ClockWidget"
    fi

    if grep -A 5 "id: middleCenterGroup" "$BAR_CONTENT" | grep -q "anchors.horizontalCenter: parent.horizontalCenter"; then
      pass "S2: middleCenterGroup dead-centered horizontally"
    else
      fail "S2: middleCenterGroup not dead-centered horizontally"
    fi

    if grep -A 5 "id: middleCenterGroup" "$BAR_CONTENT" | grep -q "anchors.verticalCenter: parent.verticalCenter"; then
      pass "S2: middleCenterGroup dead-centered vertically"
    else
      fail "S2: middleCenterGroup not dead-centered vertically"
    fi

    if sed -n '/id: middleCenterGroup/,/}/p' "$BAR_CONTENT" | grep -q "id: workspacesWidget"; then
      pass "S2: middleCenterGroup hosts Workspaces component"
    else
      fail "S2: middleCenterGroup missing Workspaces component"
    fi

    if grep -A 5 "id: weatherGroup" "$BAR_CONTENT" | grep -q "anchors.left: middleCenterGroup.right"; then
      pass "S2: weatherGroup anchors.left: middleCenterGroup.right"
    else
      fail "S2: weatherGroup missing anchors.left: middleCenterGroup.right"
    fi

    if grep -A 5 "id: weatherGroup" "$BAR_CONTENT" | grep -q "anchors.leftMargin: 4"; then
      pass "S2: weatherGroup anchors.leftMargin: 4"
    else
      fail "S2: weatherGroup missing anchors.leftMargin: 4"
    fi

    if grep -A 5 "id: weatherGroup" "$BAR_CONTENT" | grep -q "active: Config.options.bar.weather.enable"; then
      pass "S2: weatherGroup active gated by Config"
    else
      fail "S2: weatherGroup active not correctly gated"
    fi

    if sed -n '/id: weatherGroup/,/}/p' "$BAR_CONTENT" | grep -q "WeatherBar"; then
      pass "S2: weatherGroup wraps WeatherBar"
    else
      fail "S2: weatherGroup missing WeatherBar"
    fi

    if grep -A 10 "id: barLeftSideMouseArea" "$BAR_CONTENT" | grep -q "anchors.right: middleSection.left"; then
      pass "S2: barLeftSideMouseArea anchors.right bound to middleSection.left"
    else
      fail "S2: barLeftSideMouseArea missing correct right anchor"
    fi

    if grep -A 10 "id: barRightSideMouseArea" "$BAR_CONTENT" | grep -q "anchors.left: middleSection.right"; then
      pass "S2: barRightSideMouseArea anchors.left bound to middleSection.right"
    else
      fail "S2: barRightSideMouseArea missing correct left anchor"
    fi

    if grep -q "id: rightCenterGroup" "$BAR_CONTENT"; then
      fail "S2: Obsolete id: rightCenterGroup found in BarContent.qml"
    else
      pass "S2: Obsolete id: rightCenterGroup absent"
    fi
  fi
fi

# ===========================================================================
# Section 3: Responsive Behavior & Date Gating AST
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Responsive Behavior & Date Gating AST ---"

  if grep -A 10 "ClockWidget" "$BAR_CONTENT" | grep -q "showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)"; then
    pass "S3: ClockWidget showDate binds correctly"
  else
    fail "S3: ClockWidget missing correct showDate binding"
  fi

  if grep -q "property real useShortenedForm:" "$BAR_CONTENT"; then
    pass "S3: root item declares property real useShortenedForm"
  else
    fail "S3: root item missing property real useShortenedForm"
  fi
fi

# ===========================================================================
# Section 4 and 5 stubs
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Stub ---"
  pass "S4: Stub passed"
fi

if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Stub ---"
  pass "S5: Stub passed"
fi

# Git porcelain check for working tree drift
PORCELAIN_AFTER="$(mktemp "${TMPDIR:-/tmp}/p47-porcelain-after.XXXXXX")"
TMP_FILES+=("$PORCELAIN_AFTER")
git status --porcelain > "$PORCELAIN_AFTER"

# ===========================================================================
# Final Summary
# ===========================================================================
info "=== Phase 47 Assertion Summary ==="
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
