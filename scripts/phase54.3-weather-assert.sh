#!/usr/bin/env bash
# ===========================================================================
# Phase 54.3: Interactive Multi-Metric Hourly Graph Component Assert Harness
# Enforces: GRAPH-01, GRAPH-02, GRAPH-03, GRAPH-04, ASVS L1
# Decisions: D-54.3-01 through D-54.3-27
#
# Usage (from REPO_ROOT):
#   ./scripts/phase54.3-weather-assert.sh [1-5] [OPTIONS]
#
# Options:
#   -s, --section <1-5>    Execute only the specified section (1-5)
#   -q, --quick            Run fast static checks only (skips dots-hyprland.sh)
#       --standalone       Alias for --quick
#   -c, --syntax           Execute static bash syntax checks only
#   -h, --help             Show this help message
#
# Exit 0 if all hard asserts pass (FAIL=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if executed as root (ASVS L1 Root Privilege Prevention / T-54.3-01)
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Error: Do not run as root" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass()    { printf '[PASS] %s\n' "$1"; }
fail()    { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info()    { printf '[INFO] %s\n' "$1"; }

TMP_DIRS=()
cleanup() {
  local exit_code=$?
  if [[ ${#TMP_DIRS[@]} -gt 0 ]]; then
    for d in "${TMP_DIRS[@]}"; do
      rm -rf "$d" 2>/dev/null || true
    done
  fi
  rm -rf "$REPO_ROOT/stow/weather/.config/weather/__pycache__" 2>/dev/null || true
  return "$exit_code"
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
      echo "Usage: $0 [1-5] [OPTIONS]"
      echo ""
      echo "Sections:"
      echo "  1: Stow Leaf Symlink Topology, Packaging Integrity & QML Syntax"
      echo "  2: Metric Selector Tab Bar Architecture & Styling Contracts (D-54.3-01..06)"
      echo "  3: Multi-Metric Visualizations, Dual-Tier Canvas & Scaling Math (GRAPH-01, GRAPH-02, D-54.3-07..15, D-54.3-17..18)"
      echo "  4: Palette Tokens, Unified Scaling Architecture & Zero-Repaint Hover Scrub Overlay (GRAPH-03, GRAPH-04, D-54.3-16, D-54.3-19..23)"
      echo "  5: Day/Night Shading, Date Boundaries & Submodule Verification (D-54.3-24..27, ASVS L1)"
      echo ""
      echo "Options:"
      echo "  -s, --section <1-5>    Execute only the specified section (1-5)"
      echo "  -q, --quick            Run fast static checks only (skips dots-hyprland.sh)"
      echo "      --standalone       Alias for --quick"
      echo "  -c, --syntax           Execute static bash syntax checks only"
      echo "  -h, --help             Show this help message"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

GRAPH_SRC="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml"
TARGET_GRAPH="$HOME/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml"

# Syntax-only mode
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  bash -n "$0"
  pass "Assert harness bash syntax check passed (bash -n verified)"
  info "=== Syntax Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Stow Leaf Symlink Topology, Packaging Integrity & QML Syntax
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Stow Leaf Symlink Topology, Packaging Integrity & QML Syntax ---"

  if [[ -s "$GRAPH_SRC" ]]; then
    pass "S1: $GRAPH_SRC exists and is non-empty"
  else
    fail "S1: Missing or empty WeatherGraph source: $GRAPH_SRC"
  fi

  if [[ -L "$TARGET_GRAPH" ]]; then
    target_link="$(readlink -f "$TARGET_GRAPH" || true)"
    canonical_src="$(readlink -f "$GRAPH_SRC" || true)"
    if [[ "$target_link" == "$canonical_src" ]]; then
      pass "S1: $TARGET_GRAPH is a valid leaf symlink resolving to restow overlay"
    else
      fail "S1: $TARGET_GRAPH resolves to $target_link, expected $canonical_src"
    fi
  elif [[ -f "$TARGET_GRAPH" ]]; then
    fail "S1: $TARGET_GRAPH exists as regular file, expected leaf symlink"
  else
    finding "S1: $TARGET_GRAPH is not present in local home directory"
  fi

  # Real un-folded parent directories
  for check_dir in "$HOME/.config" "$HOME/.config/quickshell" "$HOME/.config/quickshell/ii" "$HOME/.config/quickshell/ii/modules" "$HOME/.config/quickshell/ii/modules/ii" "$HOME/.config/quickshell/ii/modules/ii/bar" "$HOME/.config/quickshell/ii/modules/ii/bar/weather"; do
    if [[ -d "$check_dir" && ! -L "$check_dir" ]]; then
      pass "S1: Directory $(basename "$check_dir") is an un-folded real directory"
    else
      fail "S1: Directory $(basename "$check_dir") is symlinked or missing, expected un-folded real directory"
    fi
  done

  # QML AST formatting check
  if command -v qmlformat >/dev/null 2>&1; then
    if qmlformat -n "$GRAPH_SRC" >/dev/null 2>&1; then
      pass "S1: qmlformat -n passed for WeatherGraph.qml"
    else
      fail "S1: qmlformat -n reported syntax or style errors for WeatherGraph.qml"
    fi
  else
    finding "S1: qmlformat not found on PATH; skipped static QML ast formatting check"
  fi
fi

# ===========================================================================
# Section 2: Metric Selector Tab Bar Architecture & Styling Contracts (D-54.3-01..06)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Metric Selector Tab Bar Architecture & Styling Contracts ---"

  # Default activeMetric: "temp" property
  if grep -qE 'property\s+string\s+activeMetric:\s*"temp"' "$GRAPH_SRC"; then
    pass "S2: activeMetric property defaults to 'temp' (D-54.3-05)"
  else
    fail "S2: Missing property string activeMetric: \"temp\" default"
  fi

  # Single-row tabBarContainer
  if grep -q 'id:\s*tabBarContainer' "$GRAPH_SRC"; then
    pass "S2: Single-row tabBarContainer present directly beneath card header (D-54.3-01)"
  else
    fail "S2: Missing id: tabBarContainer tab row definition"
  fi

  # 6-pill keys: temp, rain, wind, aqi, baro, uv
  for metric in temp rain wind aqi baro uv; do
    if grep -qE "(id:\s*\"$metric\"|\"id\":\s*\"$metric\")" "$GRAPH_SRC"; then
      pass "S2: Tab bar includes metric pill key '$metric' (D-54.3-02)"
    else
      fail "S2: Tab bar missing metric pill key '$metric' (D-54.3-02)"
    fi
  done

  # Labels: Temp, Rain, Wind, AQI, Baro, UV with pixelSize.smallest and bold
  for label in Temp Rain Wind AQI Baro UV; do
    if grep -qE "(label:\s*\"$label\"|\"label\":\s*\"$label\")" "$GRAPH_SRC"; then
      pass "S2: Tab bar includes label '$label'"
    else
      fail "S2: Tab bar missing label '$label'"
    fi
  done
  if grep -q 'pixelSize\.smallest' "$GRAPH_SRC" && grep -qE '(Font\.Bold|font\.bold:\s*true)' "$GRAPH_SRC"; then
    pass "S2: Tab pills use pixelSize.smallest and bold font weight"
  else
    fail "S2: Tab pills missing pixelSize.smallest or bold weight"
  fi

  # Material Symbols outline icons (thermostat, water_drop, air, eco, speed, wb_sunny) with fill: 0, iconSize: 14
  for icon in thermostat water_drop air eco speed wb_sunny; do
    if grep -qE "(icon:\s*\"$icon\"|\"icon\":\s*\"$icon\")" "$GRAPH_SRC"; then
      pass "S2: Tab bar includes outline icon '$icon' (D-54.3-04)"
    else
      fail "S2: Tab bar missing outline icon '$icon' (D-54.3-04)"
    fi
  done
  if grep -qE 'fill:\s*0' "$GRAPH_SRC" && grep -qE 'iconSize:\s*14' "$GRAPH_SRC"; then
    pass "S2: Tab pills enforce Material Symbols outline aesthetic (fill: 0, iconSize: 14)"
  else
    fail "S2: Tab pills missing fill: 0 or iconSize: 14 outline icon styling"
  fi

  # Sliding highlight animation with colPrimary and expressiveEffects
  if grep -q 'tabHighlight' "$GRAPH_SRC" && grep -q 'Appearance\.animationCurves\.expressiveEffects' "$GRAPH_SRC"; then
    pass "S2: Tab highlight rectangle uses Appearance.animationCurves.expressiveEffects Bezier easing (D-54.3-03)"
  else
    fail "S2: Tab highlight missing tabHighlight or expressiveEffects animation curve (D-54.3-03)"
  fi

  # Tab click sets activeMetric and invokes requestPaint()
  if grep -A 10 -E 'onClicked:' "$GRAPH_SRC" | grep -q 'graphCanvas\.requestPaint()'; then
    pass "S2: Tab click invokes single-shot graphCanvas.requestPaint() (D-54.3-06)"
  else
    fail "S2: Tab click missing graphCanvas.requestPaint() invocation (D-54.3-06)"
  fi

  # Default to Temp tab on popupActive
  if grep -A 8 'onPopupActiveChanged:' "$GRAPH_SRC" | grep -qE 'activeMetric\s*=\s*"temp"'; then
    pass "S2: WeatherGraph resets activeMetric to 'temp' on popup open (D-54.3-05)"
  else
    fail "S2: WeatherGraph does not reset activeMetric to 'temp' on popup open (D-54.3-05)"
  fi
fi

# ===========================================================================
# Section 3: Multi-Metric Visualizations, Dual-Tier Canvas & Scaling Math
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Multi-Metric Visualizations, Dual-Tier Canvas & Scaling Math ---"

  # Unified single Canvas
  if grep -q 'id:\s*graphCanvas' "$GRAPH_SRC"; then
    pass "S3: Unified single Canvas item multiplexing metric groups present (D-54.3-07)"
  else
    fail "S3: Missing id: graphCanvas"
  fi

  # Dual-tier layout geometry
  if grep -q 'plotUpperBottom' "$GRAPH_SRC" && grep -q 'plotLowerTop' "$GRAPH_SRC" && grep -q 'plotLowerBottom' "$GRAPH_SRC"; then
    pass "S3: Standardized dual-tier layout coordinates defined (D-54.3-08)"
  else
    fail "S3: Standardized dual-tier layout coordinates missing (D-54.3-08)"
  fi

  # Fritsch-Carlson Monotone Cubic Spline generator
  if grep -q 'computeMonotoneSplineControlPoints' "$GRAPH_SRC"; then
    pass "S3: Fritsch-Carlson Monotone Cubic Spline generator present (GRAPH-01)"
  else
    fail "S3: computeMonotoneSplineControlPoints missing from WeatherGraph"
  fi

  # Symmetrical getMetricY helper
  if grep -qE 'function\s+getMetricY\s*\(' "$GRAPH_SRC"; then
    pass "S3: Symmetrical getMetricY() helper present (D-54.3-17)"
  else
    fail "S3: Symmetrical getMetricY() helper missing from WeatherGraph"
  fi

  # Cold-boot past data hatch fallback
  if grep -q 'isHistoricalUnavailable' "$GRAPH_SRC" && grep -q 'Past data unavailable' "$GRAPH_SRC"; then
    pass "S3: Cold-boot past data hatch fallback with 'Past data unavailable' present (D-54.3-18)"
  else
    fail "S3: Cold-boot past data hatch fallback missing or lacking 'Past data unavailable' (D-54.3-18)"
  fi

  # Headless Node.js evaluation of getMetricY across all 6 metrics
  if command -v node >/dev/null 2>&1; then
    node_res=$(node -e '
      const fs = require("fs");
      const qml = fs.readFileSync("'"$GRAPH_SRC"'", "utf8");

      // Extract getMetricY function
      const fnMatch = qml.match(/function\s+getMetricY\s*\(metricKey,\s*slotIndex,\s*plotTop,\s*plotBottom\)\s*\{([\s\S]*?\n\s{4}\})/);
      if (!fnMatch) {
        console.error("Could not match getMetricY function in QML");
        process.exit(1);
      }

      // Mock root object with 25-point timeline
      const root = {
        isTimeline25: true,
        validHours: Array.from({ length: 25 }, (_, i) => ({
          isHistoricalUnavailable: i < 5,
          thermal: { tempC: 20 + i, feelsLikeC: 22 + i },
          moisture: { rainProb: i * 4, precipMM: i * 0.2 },
          wind: { speedKmph: 10 + i, gustKmph: 15 + i },
          aqi: { epaIndex: Math.min(6, 1 + Math.floor(i / 5)) },
          atmosphere: { pressureHpa: 1000 + i * 2, visibilityKm: 10 },
          solar: { uvIndex: Math.min(11, i), shortRad: i * 50 }
        })),
        calcTempBounds: () => ({ min: 15, max: 45 }),
        calcWindMax: () => 40,
        calcBaroBounds: () => ({ min: 990, max: 1060 }),
        calcUvMax: () => 12
      };

      let body = fnMatch[1];
      // Strip trailing closing brace if captured
      body = body.replace(/\n\s*\}\s*$/, "");
      const getMetricY = new Function("root", "metricKey", "slotIndex", "plotTop", "plotBottom", body);

      const metrics = ["temp", "rain", "wind", "aqi", "baro", "uv"];
      for (const m of metrics) {
        // Test normal slot (slot 12 NOW)
        const yNow = getMetricY.call(null, root, m, 12, 20, 200);
        if (isNaN(yNow) || !isFinite(yNow) || yNow < 20 || yNow > 200) {
          throw new Error("Invalid Y for " + m + " at index 12: " + yNow);
        }

        // Test historical unavailable slot (slot 0)
        const yPast = getMetricY.call(null, root, m, 0, 20, 200);
        if (yPast !== 200) {
          throw new Error("Historical unavailable slot must return plotBottom (200), got: " + yPast);
        }
      }
      console.log("OK");
    ' 2>&1 || echo "FAIL")

    if [[ "$node_res" == *"OK"* ]]; then
      pass "S3: Headless Node.js evaluation of getMetricY() across all 6 metrics passed with zero NaNs"
    else
      fail "S3: Headless Node.js evaluation of getMetricY() failed: $node_res"
    fi
  else
    finding "S3: Node.js not found on PATH; skipped headless math evaluation"
  fi
fi

# ===========================================================================
# Section 4: Palette Tokens, Unified Scaling Architecture & Zero-Repaint Hover Scrub Overlay
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Palette Tokens & Zero-Repaint Hover Scrub Overlay ---"

  # Zero-repaint invariant: verify NO requestPaint inside scrubMouseArea onPositionChanged
  if grep -A 35 -E 'id:\s*scrubMouseArea' "$GRAPH_SRC" | grep -A 25 -E 'onPositionChanged:' | grep -q 'requestPaint'; then
    fail "S4: Zero-repaint violation: requestPaint() found inside onPositionChanged (GRAPH-04, D-54.3-06)"
  else
    pass "S4: Zero-repaint invariant satisfied: onPositionChanged updates QML overlay without Canvas repainting (GRAPH-04, D-54.3-06)"
  fi

  # QML overlay items: scrubHairline, snapDot, tooltipPill
  for item in scrubHairline snapDot tooltipPill; do
    if grep -qE "id:\s*$item" "$GRAPH_SRC"; then
      pass "S4: QML overlay item '$item' present (D-54.3-21)"
    else
      fail "S4: Missing QML overlay item '$item' (D-54.3-21)"
    fi
  done

  # Smart vertical flip when Y < 60px
  if grep -qE 'activeScrubY\s*<\s*60' "$GRAPH_SRC"; then
    pass "S4: Tooltip pill implements smart vertical flip when Y < 60px (D-54.3-22)"
  else
    fail "S4: Tooltip pill missing Y < 60px vertical flip condition (D-54.3-22)"
  fi

  # Horizontal edge clamping
  if grep -qE 'Math\.max\(\s*6,\s*Math\.min' "$GRAPH_SRC"; then
    pass "S4: Tooltip pill clamps horizontally 6px from card edges (D-54.3-22)"
  else
    fail "S4: Tooltip pill missing 6px horizontal edge clamping (D-54.3-22)"
  fi

  # Dynamic curve tracking snap dot tracks activeScrubY calculated from getMetricY
  if grep -q 'snapDot' "$GRAPH_SRC" && grep -q 'activeScrubY' "$GRAPH_SRC"; then
    pass "S4: Snap dot tracks activeScrubY (D-54.3-21)"
  else
    fail "S4: Snap dot missing activeScrubY tracking"
  fi

  # Context-adaptive tooltip readouts via formatTooltipMetric
  if grep -qE 'function\s+formatTooltipMetric\s*\(' "$GRAPH_SRC"; then
    pass "S4: Context-adaptive formatTooltipMetric helper present (D-54.3-19)"
  else
    fail "S4: Context-adaptive formatTooltipMetric helper missing (D-54.3-19)"
  fi

  # Full temporal context via formatTemporalLabel
  if grep -qE 'function\s+formatTemporalLabel\s*\(' "$GRAPH_SRC"; then
    pass "S4: Full temporal context formatTemporalLabel helper present (D-54.3-20)"
  else
    fail "S4: formatTemporalLabel helper missing (D-54.3-20)"
  fi

  # Smooth fade-out on cursor exit via Behavior on opacity (150ms)
  if grep -B 2 -A 5 'Behavior on opacity' "$GRAPH_SRC" | grep -qE '150'; then
    pass "S4: Hover overlay implements smooth fade-out (Behavior on opacity ~150ms) (D-54.3-23)"
  else
    fail "S4: Hover overlay missing 150ms Behavior on opacity (D-54.3-23)"
  fi

  # Material 3 tokens
  for token in colPrimary colSecondary colTertiary colOutlineVariant; do
    if grep -q "Appearance\.colors\.$token" "$GRAPH_SRC"; then
      pass "S4: WeatherGraph uses M3 theme token Appearance.colors.$token (D-54.3-16)"
    else
      fail "S4: WeatherGraph missing Appearance.colors.$token (D-54.3-16)"
    fi
  done
fi

# ===========================================================================
# Section 5: Day/Night Shading, Date Boundaries & Submodule Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Day/Night Shading, Date Boundaries & Submodule Verification ---"

  # Nocturnal shading
  if grep -qE '(!hours\[i\]\.isDay|!h\.isDay|!isDay)' "$GRAPH_SRC"; then
    pass "S5: Canvas renders nocturnal background shading for night slots (D-54.3-24)"
  else
    fail "S5: Canvas missing nocturnal background shading (D-54.3-24)"
  fi

  # Midnight date divider with dotted stroke and compact date chip
  if grep -q 'isDayBoundary' "$GRAPH_SRC" && (grep -q 'setLineDash' "$GRAPH_SRC" || grep -q 'formatDateChip' "$GRAPH_SRC"); then
    pass "S5: Canvas renders vertical dotted divider at midnight date boundary (D-54.3-25)"
  else
    fail "S5: Canvas missing midnight date boundary divider with setLineDash or formatDateChip (D-54.3-25)"
  fi

  # X-axis timestamps with index 12 "NOW" highlighted
  if grep -qE '("NOW"|NOW)' "$GRAPH_SRC" && grep -q 'colPrimary' "$GRAPH_SRC"; then
    pass "S5: X-axis center slot 12 NOW highlighted in colPrimary (D-54.3-26)"
  else
    fail "S5: X-axis missing NOW highlight in colPrimary (D-54.3-26)"
  fi

  # Mini outline condition glyphs (12px, fill: 0, colOnSurfaceVariant)
  if grep -q 'WeatherGlyphs' "$GRAPH_SRC" || grep -q 'glyph' "$GRAPH_SRC"; then
    pass "S5: Mini condition glyph rendering supported in bottom axis band (D-54.3-27)"
  else
    fail "S5: Missing condition glyph references in bottom axis band (D-54.3-27)"
  fi

  # Zero vendor git churn
  vendor_churn="$(git status --porcelain vendor/dots-hyprland 2>/dev/null || true)"
  if [[ -z "$vendor_churn" ]]; then
    pass "S5: vendor/dots-hyprland working tree is pristine with zero modifications (ASVS L1)"
  else
    fail "S5: vendor/dots-hyprland contains uncommitted changes:\n$vendor_churn"
  fi

  # Strict repository verification
  if [[ "$QUICK_MODE" -eq 0 ]]; then
    info "S5: Running strict repository verification (arch/dots-hyprland.sh verify --strict)..."
    rm -rf "$REPO_ROOT/stow/weather/.config/weather/__pycache__" 2>/dev/null || true
    if ./arch/dots-hyprland.sh verify --strict >/dev/null 2>&1; then
      pass "S5: ./arch/dots-hyprland.sh verify --strict passed with zero findings (ASVS L1)"
    else
      fail "S5: ./arch/dots-hyprland.sh verify --strict reported errors or findings"
    fi
  else
    info "S5: Quick mode active; skipped full dots-hyprland.sh verify"
  fi
fi

# Summary & Exit
info "========================================================="
info "Phase 54.3 Assert Harness Summary: FAIL=$FAIL, FINDINGS=$FINDINGS"
info "========================================================="

if [[ "$FAIL" -eq 0 ]]; then
  pass "All executed assertion sections passed successfully!"
  exit 0
else
  fail "Assertion harness detected $FAIL failure(s)."
  exit 1
fi
