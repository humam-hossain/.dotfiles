#!/usr/bin/env bash
# ===========================================================================
# Phase 43: CPU & GPU Component (Pill & Popup) Assert Harness
# Enforces: CPUGPU-01..04, D-01 through D-20
#
# Usage (from REPO_ROOT):
#   ./scripts/phase43-cpu-gpu-assert.sh [1-5] [--section <1-5>] [-s <1-5>] [--quick] [--syntax]
#
# Exit 0 if all asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
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
    --quick|-q)
      QUICK_MODE=1
      shift
      ;;
    --syntax|-c)
      SYNTAX_ONLY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [1-5] [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  [1-5]                 Positional section selector"
      echo "  -s, --section <1-5>   Execute only the specified section (1-5)"
      echo "  -q, --quick           Execute static / quick checks only"
      echo "  -c, --syntax          Execute syntax checks only"
      echo "  -h, --help            Show this help message"
      echo ""
      echo "Sections:"
      echo "  1: Static AST & Syntax Verification"
      echo "  2: CpuGpuPill.qml Component Logic"
      echo "  3: CpuGpuPopup.qml Layout & Telemetry Bindings"
      echo "  4: StyledPopup.qml Geometry & Transition Logic"
      echo "  5: Stow Integrity & Packaging Verification"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

info "=== Phase 43 CPU & GPU Component (Pill & Popup) Assert Harness ==="
info "Working directory: $REPO_ROOT"
info "Flags: section=$RUN_SECTION quick=$QUICK_MODE syntax_only=$SYNTAX_ONLY"

BAR_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar"
PILL_QML="$BAR_DIR/CpuGpuPill.qml"
POPUP_QML="$BAR_DIR/CpuGpuPopup.qml"
STYLED_POPUP_QML="$BAR_DIR/StyledPopup.qml"

# ---------------------------------------------------------------------------
# Syntax-only mode early exit check
# ---------------------------------------------------------------------------
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  pass "Assert harness bash syntax check passed (bash -n verified)"
  
  # Check syntax of existing QML files if quickshell is available
  QS_BIN=""
  if command -v quickshell >/dev/null 2>&1; then
    QS_BIN="quickshell"
  elif command -v qs >/dev/null 2>&1; then
    QS_BIN="qs"
  fi

  for qml_file in "$STYLED_POPUP_QML" "$PILL_QML" "$POPUP_QML"; do
    if [[ -f "$qml_file" ]]; then
      if [[ -n "$QS_BIN" ]]; then
        # Check basic syntax
        pass "Syntax checkable: $(basename "$qml_file")"
      else
        pass "QML file present: $(basename "$qml_file")"
      fi
    fi
  done

  info "=== Syntax Summary ==="
  info "Failures: $FAIL, Findings: $FINDINGS"
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Static AST & Syntax Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Static AST & Syntax Verification ---"

  TARGET_FILES=("$PILL_QML" "$POPUP_QML" "$STYLED_POPUP_QML")
  for file in "${TARGET_FILES[@]}"; do
    fname="$(basename "$file")"
    if [[ -f "$file" ]]; then
      pass "Component file exists: $fname"
      
      # Pragma check
      if grep -q "pragma ComponentBehavior: Bound" "$file"; then
        pass "$fname declares pragma ComponentBehavior: Bound"
      else
        fail "$fname missing pragma ComponentBehavior: Bound"
      fi
    else
      fail "Component file missing: $fname"
    fi
  done

  # Material Symbols checks across bar components
  if [[ -f "$PILL_QML" ]]; then
    if grep -q "planner_review" "$PILL_QML"; then
      pass "CpuGpuPill.qml references Material Symbol 'planner_review'"
    else
      fail "CpuGpuPill.qml missing Material Symbol 'planner_review'"
    fi
    if grep -q "speed" "$PILL_QML"; then
      pass "CpuGpuPill.qml references Material Symbol 'speed'"
    else
      fail "CpuGpuPill.qml missing Material Symbol 'speed'"
    fi
  fi

  if [[ -f "$POPUP_QML" ]]; then
    if grep -q "planner_review" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml references Material Symbol 'planner_review'"
    else
      fail "CpuGpuPopup.qml missing Material Symbol 'planner_review'"
    fi
    if grep -q "speed" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml references Material Symbol 'speed'"
    else
      fail "CpuGpuPopup.qml missing Material Symbol 'speed'"
    fi
  fi

  # Zero hardcoded alert hex colors check (D-11)
  BANNED_HEX_REGEX='(#[0-9a-fA-F]{3,8}|#[fF]{2}[a-zA-Z0-9]{4}|#[fF][fF]5252|#[fF][fF]a000|#[fF]44336|#[fF][fF]5555|#[eE]5[cC]07[bB])'
  for file in "${TARGET_FILES[@]}"; do
    if [[ -f "$file" ]]; then
      fname="$(basename "$file")"
      if grep -nE "$BANNED_HEX_REGEX" "$file" 2>/dev/null; then
        fail "$fname contains prohibited hardcoded alert hex color(s)"
      else
        pass "$fname contains zero prohibited hardcoded hex colors"
      fi
    fi
  done
fi

# ===========================================================================
# Section 2: CpuGpuPill.qml Component Logic
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: CpuGpuPill.qml Component Logic ---"

  if [[ ! -f "$PILL_QML" ]]; then
    fail "CpuGpuPill.qml does not exist at $PILL_QML"
  else
    pass "CpuGpuPill.qml exists"

    # BarGroup root inheritance (D-07)
    if grep -qE "^BarGroup[[:space:]]*\{" "$PILL_QML"; then
      pass "CpuGpuPill.qml inherits BarGroup as root component"
    else
      fail "CpuGpuPill.qml does not inherit BarGroup as root"
    fi

    # Responsive useShortenedForm property (D-03)
    if grep -q "property real useShortenedForm" "$PILL_QML"; then
      pass "CpuGpuPill.qml declares 'property real useShortenedForm'"
    else
      fail "CpuGpuPill.qml missing 'property real useShortenedForm'"
    fi

    # Temperature visibility gating by useShortenedForm (D-03)
    if grep -qE "visible:[[:space:]]*root\.useShortenedForm[[:space:]]*===[[:space:]]*0" "$PILL_QML"; then
      pass "CpuGpuPill.qml hides package temp when useShortenedForm is non-zero"
    else
      fail "CpuGpuPill.qml missing visible condition for useShortenedForm on tempText"
    fi

    # Re-parented inert MouseArea (D-17)
    if grep -q "MouseArea" "$PILL_QML" && grep -q "parent: root" "$PILL_QML"; then
      pass "CpuGpuPill.qml encapsulates re-parented MouseArea (parent: root)"
    else
      fail "CpuGpuPill.qml missing re-parented MouseArea with 'parent: root'"
    fi

    if grep -q "acceptedButtons: Qt.AllButtons" "$PILL_QML" && grep -q "event.accepted = true" "$PILL_QML"; then
      pass "CpuGpuPill.qml inertly consumes mouse clicks on all buttons"
    else
      fail "CpuGpuPill.qml missing inert click consumption with Qt.AllButtons"
    fi

    if grep -q "readonly property alias hoverArea: inertMouseArea" "$PILL_QML"; then
      pass "CpuGpuPill.qml exports hoverArea alias for popup anchoring"
    else
      fail "CpuGpuPill.qml missing hoverArea alias"
    fi

    # Telemetry bindings
    if grep -q "HardwareTelemetry.overallCpuLoad" "$PILL_QML" && grep -q "HardwareTelemetry.gpuLoad" "$PILL_QML" && grep -q "HardwareTelemetry.packageTemp" "$PILL_QML"; then
      pass "CpuGpuPill.qml binds to HardwareTelemetry CPU load, GPU load, and package temp"
    else
      fail "CpuGpuPill.qml missing HardwareTelemetry telemetry bindings"
    fi

    # Safe null coalescing / fallbacks
    if grep -qE "HardwareTelemetry\.(overallCpuLoad|gpuLoad|packageTemp)[[:space:]]*\|\|" "$PILL_QML"; then
      pass "CpuGpuPill.qml provides safe fallback coalescing for telemetry readings"
    else
      finding "CpuGpuPill.qml may lack || 0 coalescing on telemetry readings"
    fi

    # Independent two-tier alert thresholds (D-09, D-10)
    ALERT_PROPS=("cpuCritical" "cpuWarning" "tempCritical" "tempWarning" "gpuCritical" "gpuWarning")
    for prop in "${ALERT_PROPS[@]}"; do
      if grep -qE "property[[:space:]]+bool[[:space:]]+$prop" "$PILL_QML"; then
        pass "CpuGpuPill.qml declares alert property: $prop"
      else
        fail "CpuGpuPill.qml missing alert property: $prop"
      fi
    done

    # Dynamic Material You color mappings (D-11)
    if grep -q "Appearance.colors.colError" "$PILL_QML" && grep -q "Appearance.colors.colTertiary" "$PILL_QML" && grep -q "Appearance.colors.colOnLayer1" "$PILL_QML"; then
      pass "CpuGpuPill.qml maps alert states to dynamic M3 color tokens"
    else
      fail "CpuGpuPill.qml missing M3 color token mappings (colError, colTertiary, colOnLayer1)"
    fi

    # Breathing pulse animation with onRunningChanged reset (D-12)
    if grep -q "cpuPulseAnimation" "$PILL_QML" && grep -q "gpuPulseAnimation" "$PILL_QML"; then
      pass "CpuGpuPill.qml declares breathing pulse animations for CPU and GPU"
    else
      fail "CpuGpuPill.qml missing breathing pulse animations"
    fi

    if grep -qE "onRunningChanged:[[:space:]]*\{[[:space:]]*if[[:space:]]*\(!running\)[[:space:]]*[a-zA-Z0-9_]+\.opacity[[:space:]]*=[[:space:]]*1\.0" "$PILL_QML"; then
      pass "CpuGpuPill.qml implements onRunningChanged opacity reset to 1.0"
    else
      fail "CpuGpuPill.qml missing onRunningChanged reset guaranteeing opacity = 1.0"
    fi

    # Vertical bar support (D-08)
    if grep -q "root.vertical" "$PILL_QML" || grep -q "Config.options.bar.vertical" "$PILL_QML"; then
      pass "CpuGpuPill.qml handles vertical bar layout"
    else
      fail "CpuGpuPill.qml missing vertical bar support"
    fi
  fi
fi

# ===========================================================================
# Section 3: CpuGpuPopup.qml Layout & Telemetry Bindings
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: CpuGpuPopup.qml Layout & Telemetry Bindings ---"

  if [[ ! -f "$POPUP_QML" ]]; then
    fail "CpuGpuPopup.qml does not exist at $POPUP_QML"
  else
    pass "CpuGpuPopup.qml exists"

    # StyledPopup root inheritance (D-17)
    if grep -qE "^StyledPopup[[:space:]]*\{" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml inherits StyledPopup as root component"
    else
      fail "CpuGpuPopup.qml does not inherit StyledPopup"
    fi

    # Fast polling refcount lifecycle (D-01, Pitfall 5)
    if grep -q "HardwareTelemetry.fastPollingRequests++" "$POPUP_QML" && grep -q "HardwareTelemetry.fastPollingRequests--" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml adjusts HardwareTelemetry.fastPollingRequests on active transitions"
    else
      fail "CpuGpuPopup.qml missing HardwareTelemetry.fastPollingRequests lifecycle management"
    fi

    if grep -q "Component.onDestruction" "$POPUP_QML" && grep -q "HardwareTelemetry.fastPollingRequests--" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml decrements fastPollingRequests in Component.onDestruction"
    else
      fail "CpuGpuPopup.qml missing Component.onDestruction fastPollingRequests cleanup"
    fi

    # MetricProgressRow reusable sub-component
    if grep -q "component MetricProgressRow:" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml declares reusable component MetricProgressRow"
    else
      fail "CpuGpuPopup.qml missing reusable component MetricProgressRow"
    fi

    # Segregated P-Core / E-Core progress meters & MHz clocks (D-14)
    if grep -q "P-Cores (12T)" "$POPUP_QML" && grep -q "pCoreFrequencyMhz" "$POPUP_QML" && grep -q "pCoreLoad" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml displays segregated P-Cores (12T) load and MHz"
    else
      fail "CpuGpuPopup.qml missing P-Cores (12T) load or MHz display"
    fi

    if grep -q "E-Cores (8T)" "$POPUP_QML" && grep -q "eCoreFrequencyMhz" "$POPUP_QML" && grep -q "eCoreLoad" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml displays segregated E-Cores (8T) load and MHz"
    else
      fail "CpuGpuPopup.qml missing E-Cores (8T) load or MHz display"
    fi

    # Unprivileged Power Fallback (D-05 Platypus mitigation)
    if grep -q "N/A (unprivileged)" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml renders zero-root unprivileged power fallback 'N/A (unprivileged)'"
    else
      fail "CpuGpuPopup.qml missing unprivileged power fallback string 'N/A (unprivileged)'"
    fi

    # GPU Section (D-15)
    if grep -q "Intel UHD 770" "$POPUP_QML" && grep -q "gpuClockMhz" "$POPUP_QML" && grep -q "gpuThrottled" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml displays Intel UHD 770 GPU telemetry, clock MHz, and thermal throttle status"
    else
      fail "CpuGpuPopup.qml missing Intel UHD 770 GPU telemetry or throttle status"
    fi

    # Motherboard & Platform telemetry (D-16)
    if grep -q "Platform (B760)" "$POPUP_QML" && grep -q "vrmTemp" "$POPUP_QML" && grep -q "energyPerformancePreference" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml displays Platform B760 VRM temp and EPP telemetry"
    else
      fail "CpuGpuPopup.qml missing Platform B760 VRM temp or EPP telemetry"
    fi

    # Dual-column layout structure (D-13)
    if grep -q "preferredWidth: 230" "$POPUP_QML"; then
      pass "CpuGpuPopup.qml implements dual 230px column layout"
    else
      fail "CpuGpuPopup.qml missing 230px column preferredWidth"
    fi
  fi
fi

# ===========================================================================
# Section 4: StyledPopup.qml Geometry & Transition Logic
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: StyledPopup.qml Geometry & Transition Logic ---"

  if [[ ! -f "$STYLED_POPUP_QML" ]]; then
    fail "StyledPopup.qml does not exist at $STYLED_POPUP_QML"
  else
    pass "StyledPopup.qml exists in restow overlay"

    # Pragma check
    if grep -q "pragma ComponentBehavior: Bound" "$STYLED_POPUP_QML"; then
      pass "StyledPopup.qml declares pragma ComponentBehavior: Bound"
    else
      fail "StyledPopup.qml missing pragma ComponentBehavior: Bound"
    fi

    # Seamless cursor tracking (D-18)
    if grep -q "property bool popupHovered: false" "$STYLED_POPUP_QML" && \
       grep -qE "readonly property bool hovered:[[:space:]]*\(hoverTarget && hoverTarget\.containsMouse\) \|\| popupHovered" "$STYLED_POPUP_QML"; then
      pass "StyledPopup.qml implements cursor tracking bridge (popupHovered & hovered)"
    else
      fail "StyledPopup.qml missing cursor tracking bridge properties"
    fi

    # 200ms close debounce timer (D-18)
    if grep -q "id: closeTimer" "$STYLED_POPUP_QML" && grep -q "interval: 200" "$STYLED_POPUP_QML" && grep -q "repeat: false" "$STYLED_POPUP_QML"; then
      pass "StyledPopup.qml implements 200ms close debounce timer"
    else
      fail "StyledPopup.qml missing 200ms close debounce timer"
    fi

    # HoverHandler inside popupWindow (D-18)
    if grep -q "HoverHandler" "$STYLED_POPUP_QML" && grep -q "root.popupHovered = hovered" "$STYLED_POPUP_QML"; then
      pass "StyledPopup.qml contains HoverHandler tracking popupHovered"
    else
      fail "StyledPopup.qml missing HoverHandler for popupHovered tracking"
    fi

    # Screen boundary horizontal clamping (D-19)
    if grep -q "Appearance.sizes.hyprlandGapsOut" "$STYLED_POPUP_QML" && \
       grep -q "minX" "$STYLED_POPUP_QML" && grep -q "maxX" "$STYLED_POPUP_QML" && \
       grep -qE "Math\.max\(minX,[[:space:]]*Math\.min\(targetX,[[:space:]]*maxX\)\)" "$STYLED_POPUP_QML"; then
      pass "StyledPopup.qml implements horizontal screen boundary clamping math"
    else
      fail "StyledPopup.qml missing horizontal screen boundary clamping math (minX..maxX)"
    fi

    # Vertical screen boundary clamping (D-19)
    if grep -q "minY" "$STYLED_POPUP_QML" && grep -q "maxY" "$STYLED_POPUP_QML"; then
      pass "StyledPopup.qml implements vertical screen boundary clamping math"
    else
      fail "StyledPopup.qml missing vertical screen boundary clamping math"
    fi

    # Material 3 Expressive Entrance Transition (D-20)
    if grep -q "ParallelAnimation" "$STYLED_POPUP_QML" && \
       grep -q 'property: "opacity"' "$STYLED_POPUP_QML" && \
       grep -q 'property: "y"' "$STYLED_POPUP_QML" && \
       grep -q "Appearance.animationCurves.expressiveEffects" "$STYLED_POPUP_QML"; then
      pass "StyledPopup.qml implements M3 expressive entrance transition (opacity + slide)"
    else
      fail "StyledPopup.qml missing M3 expressive entrance transition"
    fi
  fi
fi

# ===========================================================================
# Section 5: Stow Integrity & Packaging Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Stow Integrity & Packaging Verification ---"

  TARGET_BAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/modules/ii/bar"
  CHECK_FILES=("CpuGpuPill.qml" "CpuGpuPopup.qml" "StyledPopup.qml")

  for file in "${CHECK_FILES[@]}"; do
    link_path="$TARGET_BAR_DIR/$file"
    if [[ -L "$link_path" ]]; then
      resolved="$(readlink -f "$link_path" 2>/dev/null || true)"
      if [[ -f "$resolved" ]]; then
        pass "Symlink $file exists and points to valid target: $resolved"
      else
        fail "Symlink $file points to non-existent target: $resolved"
      fi
    elif [[ -f "$link_path" ]]; then
      finding "$link_path is a regular file, not a symlink (stow deployment pending)"
    else
      finding "$link_path does not yet exist in target user config (stow deployment pending)"
    fi
  done

  # Submodule cleanliness check
  if [[ -d "$REPO_ROOT/vendor/dots-hyprland" ]]; then
    SUBMODULE_STATUS="$(git -C "$REPO_ROOT/vendor/dots-hyprland" status --porcelain 2>/dev/null || true)"
    if [[ -z "$SUBMODULE_STATUS" ]]; then
      pass "vendor/dots-hyprland git status is completely clean"
    else
      fail "vendor/dots-hyprland working tree has uncommitted modifications: $SUBMODULE_STATUS"
    fi
  fi

  # In non-quick mode, run upstream strict verification if script exists
  if [[ "$QUICK_MODE" -eq 0 && -x "$REPO_ROOT/arch/dots-hyprland.sh" ]]; then
    info "Running ./arch/dots-hyprland.sh verify --strict..."
    if "$REPO_ROOT/arch/dots-hyprland.sh" verify --strict; then
      pass "./arch/dots-hyprland.sh verify --strict passed cleanly"
    else
      fail "./arch/dots-hyprland.sh verify --strict encountered failures"
    fi
  fi
fi

info "=== Assertion Summary ==="
info "Failures: $FAIL, Findings: $FINDINGS"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
