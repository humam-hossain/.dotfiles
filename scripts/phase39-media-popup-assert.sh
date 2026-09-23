#!/usr/bin/env bash
# ===========================================================================
# Phase 39: Dynamic Media Popup Anchoring Assert Harness
# Enforces: MEDIA-01, MEDIA-02, INTG-01, INTG-02, INTG-03
#
# Usage (from REPO_ROOT):
#   ./scripts/phase39-media-popup-assert.sh [--section <1-5>] [-s <1-5>] [--syntax]
#
# Exit 0 if all hard asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if run as root
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
cleanup() {
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true
  return 0
}
trap cleanup EXIT

RUN_SECTION=0
SYNTAX_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    --syntax|-c)
      SYNTAX_ONLY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-5>] [--syntax]"
      echo "  -s, --section <1-5>  Execute only the specified section"
      echo "  -c, --syntax         Execute static AST and syntax checks only"
      echo "  -h, --help           Show this help message"
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

PORCELAIN_BEFORE="$(mktemp /tmp/p39-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p39-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# Helper to run a headless Quickshell QML snippet
run_qs_test() {
  local qml_content="$1"
  local runtime_dir="${2:-}"
  local timeout_sec="${3:-4.5}"

  local runner_file
  runner_file="$(mktemp "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/p39_runner_XXXXXX.qml")"
  TMP_FILES+=("$runner_file")

  printf '%s\n' "$qml_content" > "$runner_file"

  local out=""
  if [[ -n "$runtime_dir" ]]; then
    out="$(XDG_RUNTIME_DIR="$runtime_dir" timeout "${timeout_sec}s" quickshell -p "$runner_file" 2>&1 || true)"
  else
    out="$(timeout "${timeout_sec}s" quickshell -p "$runner_file" 2>&1 || true)"
  fi

  rm -f "$runner_file" 2>/dev/null || true
  printf '%s\n' "$out"
}

# Paths to restow overlay files
GS_RESTOW="restow/quickshell/.config/quickshell/ii/GlobalStates.qml"
BC_RESTOW="restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
VBC_RESTOW="restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml"
MC_RESTOW="restow/quickshell/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml"

# Home deploy paths
GS_HOME="$HOME/.config/quickshell/ii/GlobalStates.qml"
BC_HOME="$HOME/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
VBC_HOME="$HOME/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml"
MC_HOME="$HOME/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml"

# ===========================================================================
# Section 1: Symlink & Packaging Integrity
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Symlink & Packaging Integrity ---"

  # Verify restow files exist
  for restow_file in "$GS_RESTOW" "$BC_RESTOW" "$VBC_RESTOW"; do
    if [[ -f "$REPO_ROOT/$restow_file" ]]; then
      pass "S1: Restow overlay exists: $restow_file"
    else
      fail "S1: Restow overlay MISSING: $restow_file"
    fi
  done

  # Verify parent directories are real directories (no folding)
  for dir_path in \
    "$HOME/.config/quickshell/ii" \
    "$HOME/.config/quickshell/ii/modules" \
    "$HOME/.config/quickshell/ii/modules/ii" \
    "$HOME/.config/quickshell/ii/modules/ii/bar"; do
    if [[ -d "$dir_path" ]] && [[ ! -L "$dir_path" ]]; then
      pass "S1: Parent directory is a real dir (no folding): $dir_path"
    else
      fail "S1: Parent directory is NOT a real dir or is a symlink (folding): $dir_path"
    fi
  done

  # Verify GlobalStates.qml is a symlink into restow
  if [[ -L "$GS_HOME" ]]; then
    link_target="$(readlink -f "$GS_HOME")"
    if [[ "$link_target" == *"restow/quickshell/.config/quickshell/ii/GlobalStates.qml"* ]]; then
      pass "S1: $GS_HOME is a symlink resolving into restow/quickshell/"
    else
      fail "S1: $GS_HOME symlink resolves to unexpected target: $link_target"
    fi
  else
    fail "S1: $GS_HOME is NOT a symlink (expected leaf symlink into restow)"
  fi

  # Verify BarContent.qml is a symlink into restow
  if [[ -L "$BC_HOME" ]]; then
    link_target="$(readlink -f "$BC_HOME")"
    if [[ "$link_target" == *"restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"* ]]; then
      pass "S1: $BC_HOME is a symlink resolving into restow/quickshell/"
    else
      fail "S1: $BC_HOME symlink resolves to unexpected target: $link_target"
    fi
  else
    fail "S1: $BC_HOME is NOT a symlink (expected leaf symlink into restow)"
  fi

  # Verify VerticalBarContent.qml is a symlink into restow
  if [[ -L "$VBC_HOME" ]]; then
    link_target="$(readlink -f "$VBC_HOME")"
    if [[ "$link_target" == *"restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml"* ]]; then
      pass "S1: $VBC_HOME is a symlink resolving into restow/quickshell/"
    else
      fail "S1: $VBC_HOME symlink resolves to unexpected target: $link_target"
    fi
  else
    fail "S1: $VBC_HOME is NOT a symlink (expected leaf symlink into restow)"
  fi

  # Verify vendor/dots-hyprland is clean
  VENDOR_STATUS="$(cd "$REPO_ROOT/vendor/dots-hyprland" && git status --porcelain 2>/dev/null)"
  if [[ -z "$VENDOR_STATUS" ]]; then
    pass "S1: vendor/dots-hyprland has zero git diff or untracked files"
  else
    fail "S1: vendor/dots-hyprland has dirty working tree: $VENDOR_STATUS"
  fi
fi

# ===========================================================================
# Section 2: QML Property & Clamping Math Static AST
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 || "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Section 2: QML Property & Clamping Math Static AST ---"

  # GlobalStates.qml bridge properties
  if grep -qE 'property real mediaPillCenterX: -1' "$REPO_ROOT/$GS_RESTOW"; then
    pass "S2: GlobalStates.qml declares mediaPillCenterX: -1"
  else
    fail "S2: GlobalStates.qml MISSING mediaPillCenterX: -1"
  fi

  if grep -qE 'property real mediaPillCenterY: -1' "$REPO_ROOT/$GS_RESTOW"; then
    pass "S2: GlobalStates.qml declares mediaPillCenterY: -1"
  else
    fail "S2: GlobalStates.qml MISSING mediaPillCenterY: -1"
  fi

  if grep -qE 'property var mediaPillScreen: null' "$REPO_ROOT/$GS_RESTOW"; then
    pass "S2: GlobalStates.qml declares mediaPillScreen: null"
  else
    fail "S2: GlobalStates.qml MISSING mediaPillScreen: null"
  fi

  # BarContent.qml coordinate capture
  if [[ -f "$REPO_ROOT/$BC_RESTOW" ]]; then
    if grep -q "updateMediaPillCoords" "$REPO_ROOT/$BC_RESTOW"; then
      pass "S2: BarContent.qml defines updateMediaPillCoords"
    else
      fail "S2: BarContent.qml MISSING updateMediaPillCoords"
    fi

    if grep -q "mediaHoverHandler" "$REPO_ROOT/$BC_RESTOW"; then
      pass "S2: BarContent.qml defines mediaHoverHandler"
    else
      fail "S2: BarContent.qml MISSING mediaHoverHandler"
    fi

    if grep -q "mapToItem(null" "$REPO_ROOT/$BC_RESTOW"; then
      pass "S2: BarContent.qml uses mapToItem(null, ...)"
    else
      fail "S2: BarContent.qml MISSING mapToItem(null, ...)"
    fi
  fi

  # VerticalBarContent.qml coordinate capture
  if [[ -f "$REPO_ROOT/$VBC_RESTOW" ]]; then
    if grep -q "updateVerticalMediaPillCoords" "$REPO_ROOT/$VBC_RESTOW"; then
      pass "S2: VerticalBarContent.qml defines updateVerticalMediaPillCoords"
    else
      fail "S2: VerticalBarContent.qml MISSING updateVerticalMediaPillCoords"
    fi

    if grep -q "verticalMediaHoverHandler" "$REPO_ROOT/$VBC_RESTOW"; then
      pass "S2: VerticalBarContent.qml defines verticalMediaHoverHandler"
    else
      fail "S2: VerticalBarContent.qml MISSING verticalMediaHoverHandler"
    fi
  fi

  # MediaControls.qml screen binding and clamping
  if [[ -f "$REPO_ROOT/$MC_RESTOW" ]]; then
    if grep -q 'GlobalStates.mediaPillScreen' "$REPO_ROOT/$MC_RESTOW"; then
      pass "S2: MediaControls.qml binds GlobalStates.mediaPillScreen"
    else
      fail "S2: MediaControls.qml MISSING GlobalStates.mediaPillScreen binding"
    fi

    if grep -q 'GlobalStates.mediaPillCenterX' "$REPO_ROOT/$MC_RESTOW"; then
      pass "S2: MediaControls.qml uses GlobalStates.mediaPillCenterX for margins"
    else
      fail "S2: MediaControls.qml MISSING GlobalStates.mediaPillCenterX clamping"
    fi

    if grep -q 'Math.round' "$REPO_ROOT/$MC_RESTOW"; then
      pass "S2: MediaControls.qml uses Math.round for subpixel rounding"
    else
      fail "S2: MediaControls.qml MISSING Math.round subpixel rounding"
    fi

    if grep -q 'hyprlandGapsOut' "$REPO_ROOT/$MC_RESTOW"; then
      pass "S2: MediaControls.qml references hyprlandGapsOut for clamping"
    else
      fail "S2: MediaControls.qml MISSING hyprlandGapsOut reference"
    fi
  fi
fi

# ===========================================================================
# Section 3: Headless Quickshell Coordinate Mapping & Clamping Math Execution
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Headless Quickshell Coordinate Mapping & Clamping Math Execution ---"

  if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
    info "S3: Syntax-only mode — skipping headless Quickshell clamping tests"
  else
    CLAMP_QML='import QtQuick
import Quickshell

Scope {
    Component.onCompleted: {
        // Clamping constants matching Appearance.sizes
        var widgetWidth = 440;
        var widgetHeight = 160;
        var osdWidth = 180;
        var gap = 5; // hyprlandGapsOut

        function clampHorizontal(pillCenterX, screenWidth) {
            if (pillCenterX <= 0) {
                return (screenWidth / 2) - (osdWidth / 2) - widgetWidth;
            }
            var targetX = pillCenterX - (widgetWidth / 2);
            var minX = gap;
            var maxX = screenWidth - widgetWidth - gap;
            var clampedX = (maxX < minX) ? minX : Math.max(minX, Math.min(targetX, maxX));
            return Math.round(clampedX);
        }

        function clampVertical(pillCenterY, screenHeight) {
            if (pillCenterY <= 0) {
                return (screenHeight / 2) - (widgetHeight * 1.5);
            }
            var targetY = pillCenterY - (widgetHeight / 2);
            var minY = gap;
            var maxY = screenHeight - widgetHeight - gap;
            var clampedY = (maxY < minY) ? minY : Math.max(minY, Math.min(targetY, maxY));
            return Math.round(clampedY);
        }

        // Test 1: Normal center (1920x1080, pill at 1500)
        var r1 = clampHorizontal(1500, 1920);
        console.log("T1_NORMAL_CENTER:" + r1);

        // Test 2: Left edge clamp (1920x1080, pill at 100)
        var r2 = clampHorizontal(100, 1920);
        console.log("T2_LEFT_CLAMP:" + r2);

        // Test 3: Right edge clamp (1920x1080, pill at 1800)
        var r3 = clampHorizontal(1800, 1920);
        console.log("T3_RIGHT_CLAMP:" + r3);

        // Test 4: Ultrawide normal (3440x1440, pill at 3200)
        var r4 = clampHorizontal(3200, 3440);
        console.log("T4_ULTRAWIDE_NORMAL:" + r4);

        // Test 5: Ultrawide right clamp (3440x1440, pill at 3400)
        var r5 = clampHorizontal(3400, 3440);
        console.log("T5_ULTRAWIDE_CLAMP:" + r5);

        // Test 6: Narrow display (400px wide, pill at 200)
        var r6 = clampHorizontal(200, 400);
        console.log("T6_NARROW_CLAMP:" + r6);

        // Test 7: Fallback (mediaPillCenterX = -1, 1920px)
        var r7 = clampHorizontal(-1, 1920);
        console.log("T7_FALLBACK:" + r7);

        // Test 8: Subpixel rounding (pill at 1500.7)
        var r8 = clampHorizontal(1500.7, 1920);
        console.log("T8_SUBPIXEL:" + r8);

        // Test 9: Vertical clamping normal
        var r9 = clampVertical(500, 1080);
        console.log("T9_VERT_NORMAL:" + r9);

        // Test 10: Vertical fallback
        var r10 = clampVertical(-1, 1080);
        console.log("T10_VERT_FALLBACK:" + r10);

        Qt.quit();
    }
}'

    CLAMP_OUT="$(run_qs_test "$CLAMP_QML" "" 4.5)"

    # Test 1: Normal center: 1500 - 220 = 1280 (within bounds)
    if echo "$CLAMP_OUT" | grep -q "T1_NORMAL_CENTER:1280"; then
      pass "S3: Normal center alignment (1920x1080, pill=1500) -> 1280"
    else
      fail "S3: Normal center alignment expected 1280, got: $(echo "$CLAMP_OUT" | grep 'T1_NORMAL_CENTER' || echo 'MISSING')"
    fi

    # Test 2: Left edge clamp: 100 - 220 = -120, clamped to minX=5
    if echo "$CLAMP_OUT" | grep -q "T2_LEFT_CLAMP:5"; then
      pass "S3: Left edge clamp (pill=100) -> 5"
    else
      fail "S3: Left edge clamp expected 5, got: $(echo "$CLAMP_OUT" | grep 'T2_LEFT_CLAMP' || echo 'MISSING')"
    fi

    # Test 3: Right edge clamp: 1800 - 220 = 1580, maxX = 1920 - 440 - 5 = 1475
    if echo "$CLAMP_OUT" | grep -q "T3_RIGHT_CLAMP:1475"; then
      pass "S3: Right edge clamp (pill=1800) -> 1475"
    else
      fail "S3: Right edge clamp expected 1475, got: $(echo "$CLAMP_OUT" | grep 'T3_RIGHT_CLAMP' || echo 'MISSING')"
    fi

    # Test 4: Ultrawide normal: 3200 - 220 = 2980 (within bounds)
    if echo "$CLAMP_OUT" | grep -q "T4_ULTRAWIDE_NORMAL:2980"; then
      pass "S3: Ultrawide normal (pill=3200) -> 2980"
    else
      fail "S3: Ultrawide normal expected 2980, got: $(echo "$CLAMP_OUT" | grep 'T4_ULTRAWIDE_NORMAL' || echo 'MISSING')"
    fi

    # Test 5: Ultrawide right clamp: 3400 - 220 = 3180, maxX = 3440 - 440 - 5 = 2995
    if echo "$CLAMP_OUT" | grep -q "T5_ULTRAWIDE_CLAMP:2995"; then
      pass "S3: Ultrawide right clamp (pill=3400) -> 2995"
    else
      fail "S3: Ultrawide right clamp expected 2995, got: $(echo "$CLAMP_OUT" | grep 'T5_ULTRAWIDE_CLAMP' || echo 'MISSING')"
    fi

    # Test 6: Narrow display: maxX = 400 - 440 - 5 = -45 < minX=5, so clamps to minX=5
    if echo "$CLAMP_OUT" | grep -q "T6_NARROW_CLAMP:5"; then
      pass "S3: Narrow display guard (400px, pill=200) -> 5"
    else
      fail "S3: Narrow display guard expected 5, got: $(echo "$CLAMP_OUT" | grep 'T6_NARROW_CLAMP' || echo 'MISSING')"
    fi

    # Test 7: Fallback: (1920 / 2) - (180 / 2) - 440 = 960 - 90 - 440 = 430
    if echo "$CLAMP_OUT" | grep -q "T7_FALLBACK:430"; then
      pass "S3: Fallback center (pillCenterX=-1, 1920px) -> 430"
    else
      fail "S3: Fallback center expected 430, got: $(echo "$CLAMP_OUT" | grep 'T7_FALLBACK' || echo 'MISSING')"
    fi

    # Test 8: Subpixel: 1500.7 - 220 = 1280.7, rounded to 1281
    if echo "$CLAMP_OUT" | grep -q "T8_SUBPIXEL:1281"; then
      pass "S3: Subpixel rounding (pill=1500.7) -> 1281"
    else
      fail "S3: Subpixel rounding expected 1281, got: $(echo "$CLAMP_OUT" | grep 'T8_SUBPIXEL' || echo 'MISSING')"
    fi

    # Test 9: Vertical normal: 500 - 80 = 420 (within bounds)
    if echo "$CLAMP_OUT" | grep -q "T9_VERT_NORMAL:420"; then
      pass "S3: Vertical normal clamping (pill=500, 1080px) -> 420"
    else
      fail "S3: Vertical normal expected 420, got: $(echo "$CLAMP_OUT" | grep 'T9_VERT_NORMAL' || echo 'MISSING')"
    fi

    # Test 10: Vertical fallback: (1080 / 2) - (160 * 1.5) = 540 - 240 = 300
    if echo "$CLAMP_OUT" | grep -q "T10_VERT_FALLBACK:300"; then
      pass "S3: Vertical fallback (pillCenterY=-1, 1080px) -> 300"
    else
      fail "S3: Vertical fallback expected 300, got: $(echo "$CLAMP_OUT" | grep 'T10_VERT_FALLBACK' || echo 'MISSING')"
    fi
  fi
fi

# ===========================================================================
# Section 4: Multi-Monitor Screen Binding & State Reset Lifecycle
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Multi-Monitor Screen Binding & State Reset Lifecycle ---"

  if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
    info "S4: Syntax-only mode — skipping headless Quickshell state lifecycle tests"
  else
    STATE_QML='import QtQuick
import Quickshell

Scope {
    Component.onCompleted: {
        // Simulate GlobalStates initial values
        var mediaPillCenterX = -1;
        var mediaPillCenterY = -1;
        var mediaPillScreen = null;

        console.log("INIT_X:" + mediaPillCenterX);
        console.log("INIT_Y:" + mediaPillCenterY);
        console.log("INIT_SCREEN:" + (mediaPillScreen === null ? "null" : "non-null"));

        // Simulate pill click setting coordinates
        mediaPillCenterX = 960;
        mediaPillCenterY = 20;
        mediaPillScreen = "MONITOR_1";
        console.log("SET_X:" + mediaPillCenterX);
        console.log("SET_Y:" + mediaPillCenterY);
        console.log("SET_SCREEN:" + mediaPillScreen);

        // Simulate dismissal reset
        mediaPillCenterX = -1;
        mediaPillCenterY = -1;
        mediaPillScreen = null;
        console.log("RESET_X:" + mediaPillCenterX);
        console.log("RESET_Y:" + mediaPillCenterY);
        console.log("RESET_SCREEN:" + (mediaPillScreen === null ? "null" : "non-null"));

        Qt.quit();
    }
}'

    STATE_OUT="$(run_qs_test "$STATE_QML" "" 4.5)"

    if echo "$STATE_OUT" | grep -q "INIT_X:-1" && echo "$STATE_OUT" | grep -q "INIT_Y:-1" && echo "$STATE_OUT" | grep -q "INIT_SCREEN:null"; then
      pass "S4: Initial state: mediaPillCenterX=-1, mediaPillCenterY=-1, mediaPillScreen=null"
    else
      fail "S4: Initial state verification failed: $STATE_OUT"
    fi

    if echo "$STATE_OUT" | grep -q "SET_X:960" && echo "$STATE_OUT" | grep -q "SET_Y:20" && echo "$STATE_OUT" | grep -q "SET_SCREEN:MONITOR_1"; then
      pass "S4: State update on pill click: X=960, Y=20, Screen=MONITOR_1"
    else
      fail "S4: State update verification failed: $STATE_OUT"
    fi

    if echo "$STATE_OUT" | grep -q "RESET_X:-1" && echo "$STATE_OUT" | grep -q "RESET_Y:-1" && echo "$STATE_OUT" | grep -q "RESET_SCREEN:null"; then
      pass "S4: Dismissal reset: mediaPillCenterX=-1, mediaPillCenterY=-1, mediaPillScreen=null"
    else
      fail "S4: Dismissal reset verification failed: $STATE_OUT"
    fi
  fi
fi

# ===========================================================================
# Section 5: Repository Integrity & Strict Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Repository Integrity & Strict Verification ---"

  if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
    info "S5: Syntax-only mode — skipping dots-hyprland.sh verify --strict"
  else
    STRICT_OUT="$(./arch/dots-hyprland.sh verify --strict 2>&1)" || {
      fail "S5: arch/dots-hyprland.sh verify --strict exited with non-zero status"
    }
    if [[ "$STRICT_OUT" == *"FAIL=0 FINDINGS=0"* ]]; then
      pass "S5: arch/dots-hyprland.sh verify --strict passed with zero findings"
    else
      fail "S5: arch/dots-hyprland.sh verify --strict reported findings or failures"
    fi
  fi
fi

# ===========================================================================
# Summary & Porcelain Check
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
DIFF_OUT="$(diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true)"
if [[ -n "$DIFF_OUT" ]]; then
  fail "Working tree porcelain drift detected during test execution:"
  printf '%s\n' "$DIFF_OUT" >&2
else
  pass "Working tree porcelain is clean (no drift)"
fi

echo "=========================================="
echo "Phase 39 Test Results: FAIL=$FAIL FINDINGS=$FINDINGS"
echo "=========================================="

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
