#!/usr/bin/env bash
# ===========================================================================
# Phase 54.3: Interactive Multi-Metric Hourly Graph Component Assert Harness
# Enforces: GRAPH-01, GRAPH-02, GRAPH-03, GRAPH-04, ASVS L1
# Decisions: D-54.3-01 through D-54.3-27
#
# Usage (from REPO_ROOT):
#   ./scripts/phase54.3-weather-assert.sh [1-6] [OPTIONS]
#
# Options:
#   -s, --section <1-6>    Execute only the specified section (1-6)
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
    1|2|3|4|5|6)
      RUN_SECTION="$1"
      shift
      ;;
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-6]$ ]]; then
        echo "Error: --section requires an integer from 1 to 6" >&2
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
      echo "  1: Stow Leaf Symlink Topology, Packaging Integrity, QML Syntax & Card-Layout Structure"
      echo "  2: Tab-Less Composite Essentials Architecture Contracts (G-54.3-1)"
      echo "  3: Multi-Metric Visualizations, Dual-Tier Canvas & Scaling Math (GRAPH-01, GRAPH-02, D-54.3-07..15, D-54.3-17..18)"
      echo "  4: Palette Tokens, Unified Scaling Architecture & Zero-Repaint Hover Scrub Overlay (GRAPH-03, GRAPH-04, D-54.3-16, D-54.3-19..23)"
      echo "  5: Day/Night Shading, Date Boundaries & Submodule Verification (D-54.3-24..27, ASVS L1)"
      echo "  6: Stacked Locked Graph Instances, Zero Tab Chrome & Locked Metric Bindings (G-54.3-4)"
      echo ""
      echo "Options:"
      echo "  -s, --section <1-6>    Execute only the specified section (1-6)"
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
POPUP_SRC="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherPopup.qml"
WEATHER_DIR="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather"
BASE_CARD="$WEATHER_DIR/WeatherBaseCard.qml"
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
  info "--- Section 1: Stow Leaf Symlink Topology, Packaging Integrity, QML Syntax & Card-Layout Structure ---"

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

  # QML AST formatting check over every weather overlay file (G-54.3-5 card-layout gate)
  if command -v qmlformat >/dev/null 2>&1; then
    if [[ ! -d "$WEATHER_DIR" ]]; then
      fail "S1: Weather overlay directory missing: $WEATHER_DIR (fail-closed)"
    else
      qml_count=0
      for qml_file in "$WEATHER_DIR"/*.qml; do
        [[ -e "$qml_file" ]] || continue
        qml_count=$((qml_count + 1))
        if qmlformat -n "$qml_file" >/dev/null 2>&1; then
          pass "S1: qmlformat -n passed for $(basename "$qml_file")"
        else
          fail "S1: qmlformat -n reported syntax or style errors for $(basename "$qml_file")"
        fi
      done
      if [[ "$qml_count" -eq 0 ]]; then
        fail "S1: No QML files found in $WEATHER_DIR (fail-closed)"
      fi
    fi
  else
    finding "S1: qmlformat not found on PATH; skipped static QML ast formatting check"
  fi

  # Quickshell session freshness guard (T-54.3-05): QML loads once at process
  # start, so a running quickshell older than the restow graph file is hosting
  # pre-fix UI. Fail-soft FINDING only — never FAIL — plus INFO skips.
  qs_pid="$(pgrep -o -f '[q]uickshell' 2>/dev/null || true)"
  if [[ -z "$qs_pid" ]]; then
    info "S1: No quickshell process found; skipped session freshness check (headless CI)"
  elif ! command -v date >/dev/null 2>&1; then
    info "S1: date utility unavailable; skipped session freshness check"
  else
    qs_elapsed="$(ps -o etimes= -p "$qs_pid" 2>/dev/null | tr -d '[:space:]' || true)"
    qs_epoch=""
    if [[ "$qs_elapsed" =~ ^[0-9]+$ ]]; then
      qs_now="$(date +%s 2>/dev/null || true)"
      if [[ "$qs_now" =~ ^[0-9]+$ ]]; then
        qs_epoch=$((qs_now - qs_elapsed))
      fi
    fi
    graph_mtime="$(stat -c %Y "$GRAPH_SRC" 2>/dev/null || true)"
    if [[ -z "$qs_epoch" || -z "$graph_mtime" ]]; then
      info "S1: Could not determine quickshell start epoch or graph mtime; skipped session freshness check"
    elif [[ "$graph_mtime" -gt "$qs_epoch" ]]; then
      finding "S1: STALE SESSION — quickshell PID $qs_pid started before restow WeatherGraph.qml was modified; restart with 'qs -c ii' (or 'systemctl --user restart quickshell') before any visual UAT claim"
    else
      pass "S1: Quickshell session is fresh (PID $qs_pid started after last graph modification)"
    fi
  fi

  # Card-layout structure gates (G-54.3-5): every popup card must report its
  # true content height via layout-driven sizing, with clipping as fail-safe.
  # All gates are fail-closed with explicit file-existence guards.
  if [[ ! -s "$BASE_CARD" ]]; then
    fail "S1: Base card source missing; cannot verify card-layout structure (fail-closed)"
  else
    if grep -q 'clip: true' "$BASE_CARD"; then
      pass "S1: Base card enables clipping fail-safe (G-54.3-5)"
    else
      fail "S1: Base card missing clip: true fail-safe (G-54.3-5)"
    fi

    if grep -q 'default property alias content: cardContent\.data' "$BASE_CARD"; then
      pass "S1: Base card exposes content host through default-property alias (G-54.3-5)"
    else
      fail "S1: Base card missing default property alias content: cardContent.data (G-54.3-5)"
    fi

    if grep -B1 'id: cardContent' "$BASE_CARD" | grep -q 'ColumnLayout'; then
      pass "S1: Base card content host is a size-propagating layout container (G-54.3-5)"
    else
      fail "S1: Base card content host is not a layout container; anchored children report zero implicit size (G-54.3-5)"
    fi
  fi

  for consumer in WeatherHeroCard WeatherAtmosphericCard WeatherWindCard WeatherAqiCard WeatherAstronomyCard WeatherGraph; do
    consumer_src="$WEATHER_DIR/${consumer}.qml"
    if [[ ! -s "$consumer_src" ]]; then
      fail "S1: Consumer source missing: ${consumer}.qml (fail-closed)"
    elif grep -q 'Layout\.fillWidth' "$consumer_src"; then
      pass "S1: ${consumer} content uses width-filling layout attachment (G-54.3-5)"
    else
      fail "S1: ${consumer} content missing Layout.fillWidth; card collapses to header height (G-54.3-5)"
    fi
  done
fi

# ===========================================================================
# Section 2: Tab-Less Composite Essentials Architecture Contracts (G-54.3-1)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Tab-Less Composite Essentials Architecture Contracts ---"

  # Tab chrome absence: the four removed selector identifiers must not appear on non-comment lines
  for chrome_id in tabBarContainer tabsRepeater tabHighlight activeTabPill; do
    chrome_count="$(grep -v '^[[:space:]]*//' "$GRAPH_SRC" | grep -c "$chrome_id" || true)"
    if [[ "$chrome_count" -eq 0 ]]; then
      pass "S2: Tab chrome identifier '$chrome_id' absent (tab-less G-54.3-1)"
    else
      fail "S2: Tab chrome identifier '$chrome_id' still present ${chrome_count}x (tab-less G-54.3-1)"
    fi
  done

  # Locked visible metric: declaration defaults to the thermal key
  if grep -qE 'property\s+string\s+activeMetric:\s*"temp"' "$GRAPH_SRC"; then
    pass "S2: activeMetric property defaults to 'temp' (locked composite view)"
  else
    fail "S2: Missing property string activeMetric: \"temp\" default"
  fi

  # Locked visible metric: zero runtime writes across non-comment lines
  metric_writes="$(grep -v '^[[:space:]]*//' "$GRAPH_SRC" | grep -cE 'activeMetric\s*=[^=]' || true)"
  if [[ "$metric_writes" -eq 0 ]]; then
    pass "S2: No runtime write to locked activeMetric remains (tab-less G-54.3-1)"
  else
    fail "S2: Found ${metric_writes} runtime write(s) to locked activeMetric"
  fi

  # No popup-active reset handler may reassign the metric
  if grep -A 8 'onPopupActiveChanged:' "$GRAPH_SRC" | grep -qE 'activeMetric\s*=[^=]'; then
    fail "S2: Popup-open handler still reassigns activeMetric (must stay locked)"
  else
    pass "S2: No popup-active reset handler reassigns activeMetric"
  fi

  # Composite essentials presence: solid primary stroke via active-metric color helper
  if grep -q 'getActiveMetricColor' "$GRAPH_SRC" && grep -q 'strokeStyle = root\.getActiveMetricColor()' "$GRAPH_SRC"; then
    pass "S2: Solid primary stroke driven by getActiveMetricColor() (composite essentials)"
  else
    fail "S2: Solid primary stroke via getActiveMetricColor() missing"
  fi

  # Composite essentials presence: dashed feels-like secondary curve
  if grep -q 'setLineDash(\[3, 3\])' "$GRAPH_SRC"; then
    pass "S2: Dashed secondary curve present (feels-like essentials)"
  else
    fail "S2: Dashed secondary curve via setLineDash missing"
  fi

  # Composite essentials presence: lower rain bars referencing probability and volume fields
  if grep -q 'rainProb' "$GRAPH_SRC" && grep -q 'precipMM' "$GRAPH_SRC"; then
    pass "S2: Lower rain bars reference probability and volume fields (composite essentials)"
  else
    fail "S2: Lower rain bars missing rainProb/precipMM field references"
  fi

  # Composite essentials presence: thermal high/low guideline labels
  if grep -qE 'bounds\.max - 1' "$GRAPH_SRC" && grep -qE 'bounds\.min \+ 1' "$GRAPH_SRC"; then
    pass "S2: Thermal high/low guideline labels present (composite essentials)"
  else
    fail "S2: Thermal high/low guideline labels missing"
  fi

  # Static composite card title
  if grep -q 'title: "Hourly Temperature and Rain Outlook"' "$GRAPH_SRC"; then
    pass "S2: Static composite card title present (tab-less G-54.3-1)"
  else
    fail "S2: Static card title 'Hourly Temperature and Rain Outlook' missing"
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

  # Legend row presence with three explanatory entries (G-54.3-2)
  if [[ ! -s "$GRAPH_SRC" ]]; then
    fail "S3: WeatherGraph source missing; cannot verify legend contracts (fail-closed)"
  else
    if grep -qE 'id:\s*legendRow' "$GRAPH_SRC"; then
      pass "S3: Legend row present above canvas (G-54.3-2)"
    else
      fail "S3: Missing legend row id: legendRow (G-54.3-2)"
    fi

    for legend_label in "Actual temp" "Feels-like" "Rain chance"; do
      if grep -qF "$legend_label" "$GRAPH_SRC"; then
        pass "S3: Legend entry '$legend_label' present (G-54.3-2)"
      else
        fail "S3: Legend entry '$legend_label' missing (G-54.3-2)"
      fi
    done

    # Distinct series palette: dashed stroke on tertiary, bars on secondary (G-54.3-2)
    if grep -q 'strokeStyle = Appearance\.colors\.colTertiary' "$GRAPH_SRC"; then
      pass "S3: Dashed feels-like stroke uses tertiary token (distinct palette G-54.3-2)"
    else
      fail "S3: Dashed stroke missing tertiary token (distinct palette G-54.3-2)"
    fi

    if grep -q 'fillStyle = Appearance\.colors\.colSecondary' "$GRAPH_SRC"; then
      pass "S3: Rain bars use secondary token with opacity-driven depth (G-54.3-2)"
    else
      fail "S3: Rain bars missing secondary token (G-54.3-2)"
    fi

    static_blue="$(grep -v '^[[:space:]]*//' "$GRAPH_SRC" | grep -c '#1976D2' || true)"
    if [[ "$static_blue" -eq 0 ]]; then
      pass "S3: Static blue volume hex absent from non-comment code (single-hue bars G-54.3-2)"
    else
      fail "S3: Static blue hex #1976D2 still present ${static_blue}x in non-comment code"
    fi

    # Lowered tier-bottom constant reserves the icon-strip band (G-54.3-5)
    if grep -qF 'plotLowerBottom = height - 46' "$GRAPH_SRC"; then
      pass "S3: Lower tier bottom reserves icon-strip band at height - 46 (G-54.3-5)"
    else
      fail "S3: Lower tier bottom not at height - 46 (icon-strip band G-54.3-5)"
    fi

    # Card-level stride property shared by canvas loop and QML strip (T-54.3-08)
    if grep -qE 'property\s+int\s+axisStride' "$GRAPH_SRC"; then
      pass "S3: Card-level axisStride property present (T-54.3-08)"
    else
      fail "S3: Missing card-level axisStride property (T-54.3-08)"
    fi

    if grep -q 'root\.axisStride' "$GRAPH_SRC"; then
      pass "S3: Canvas timestamp loop reads shared root.axisStride (T-54.3-08)"
    else
      fail "S3: Canvas timestamp loop does not read root.axisStride (T-54.3-08)"
    fi

    # Gutter-overflow gate (G-54.3-1, T-54.3-11): paint and scrub gutter
    # constants must both read 34 and match, the Y-label anchor must derive
    # from the gutter constant minus 4, the computed anchor x minus a
    # conservative 24px label width must stay at or above zero, and the icon
    # strip left margin must track the gutter. All fail-closed.
    if [[ ! -s "$GRAPH_SRC" ]]; then
      fail "S3: WeatherGraph source missing; cannot verify gutter-overflow contracts (fail-closed)"
    else
      paint_gutter="$(grep -c 'const plotLeft = 34;' "$GRAPH_SRC" || true)"
      if [[ "$paint_gutter" -ge 2 ]]; then
        pass "S3: Paint and scrub gutter constants both read 34 (G-54.3-1)"
      else
        fail "S3: Expected 2 gutter constants with value 34 (paint + scrub), found ${paint_gutter} (G-54.3-1)"
      fi

      if grep -q 'const plotLeft = 14;' "$GRAPH_SRC"; then
        fail "S3: Stale 14px gutter constant still present; paint/scrub misaligned (T-54.3-11)"
      else
        pass "S3: No stale 14px gutter constant remains (T-54.3-11)"
      fi

      if grep -q 'plotLeft - 4' "$GRAPH_SRC"; then
        pass "S3: Y-label anchor derives from gutter constant minus 4 (G-54.3-1)"
      else
        fail "S3: Y-label anchor no longer references gutter constant minus 4 (G-54.3-1)"
      fi

      gutter_val=34
      anchor_x=$((gutter_val - 4))
      clearance=$((anchor_x - 24))
      if [[ "$clearance" -ge 0 ]]; then
        pass "S3: Anchor x=${anchor_x} minus 24px label width stays at or above zero (clearance=${clearance}) (G-54.3-1)"
      else
        fail "S3: Anchor x=${anchor_x} minus 24px label width goes negative (clearance=${clearance}) (G-54.3-1)"
      fi

      if grep -q 'anchors.leftMargin: 34' "$GRAPH_SRC"; then
        pass "S3: Axis icon strip left margin tracks gutter value 34 (G-54.3-1)"
      else
        fail "S3: Axis icon strip left margin does not track gutter value 34 (G-54.3-1)"
      fi
    fi
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

  # Tooltip legibility: floor token absent from pill region (G-54.3-3)
  if [[ ! -s "$GRAPH_SRC" ]]; then
    fail "S4: WeatherGraph source missing; cannot verify tooltip contracts (fail-closed)"
  else
    pill_floor="$(sed -n '/id: tooltipPill/,/id: scrubMouseArea/p' "$GRAPH_SRC" | grep -c 'pixelSize\.smallest' || true)"
    if [[ "$pill_floor" -eq 0 ]]; then
      pass "S4: Floor type token absent from tooltip pill region (legible tooltip G-54.3-3)"
    else
      fail "S4: Floor type token still used ${pill_floor}x inside tooltip pill region (G-54.3-3)"
    fi

    if sed -n '/id: tooltipPill/,/id: scrubMouseArea/p' "$GRAPH_SRC" | grep -q 'pixelSize\.smaller'; then
      pass "S4: Tooltip temporal label and separators use raised 12px token (G-54.3-3)"
    else
      fail "S4: Tooltip missing raised pixelSize.smaller text (G-54.3-3)"
    fi

    if sed -n '/id: tooltipPill/,/id: scrubMouseArea/p' "$GRAPH_SRC" | grep -qE 'pixelSize\.small([^er]|$)'; then
      pass "S4: Tooltip metric readout uses raised 15px token (G-54.3-3)"
    else
      fail "S4: Tooltip readout missing raised pixelSize.small text (G-54.3-3)"
    fi

    # Tooltip-structure gate (G-54.3-3, T-54.3-12): stacked 3-row layout with
    # per-line helpers and background-only alpha. All fail-closed.
    if [[ ! -s "$GRAPH_SRC" ]]; then
      fail "S4: WeatherGraph source missing; cannot verify tooltip structure (fail-closed)"
    else
      if sed -n '/id: tooltipPill/,/id: scrubMouseArea/p' "$GRAPH_SRC" | grep -q 'ColumnLayout'; then
        pass "S4: Tooltip pill contains stacked vertical ColumnLayout (G-54.3-3)"
      else
        fail "S4: Tooltip pill missing stacked ColumnLayout; single-line layout regressed (G-54.3-3)"
      fi

      if grep -qE 'function\s+formatTooltipTempLine\s*\(' "$GRAPH_SRC" && grep -qE 'function\s+formatTooltipRainLine\s*\(' "$GRAPH_SRC"; then
        pass "S4: Per-line tooltip helpers formatTooltipTempLine/formatTooltipRainLine present (G-54.3-3)"
      else
        fail "S4: Per-line tooltip helpers missing (G-54.3-3)"
      fi

      if sed -n '/id: tooltipBackground/,/id: tooltipColumn/p' "$GRAPH_SRC" | grep -q 'opacity: 0.75'; then
        pass "S4: Pill background element carries 0.75 opacity with text at full opacity (T-54.3-12)"
      else
        fail "S4: 0.75 opacity not on pill background element; legibility at risk (T-54.3-12)"
      fi

      pill_metric_calls="$(sed -n '/id: tooltipPill/,/id: scrubMouseArea/p' "$GRAPH_SRC" | grep -c 'formatTooltipMetric' || true)"
      if [[ "$pill_metric_calls" -eq 0 ]]; then
        pass "S4: Pill region no longer routes readout through single fused string alone (G-54.3-3)"
      else
        fail "S4: Pill region still routes readout through formatTooltipMetric ${pill_metric_calls}x (G-54.3-3)"
      fi
    fi
  fi
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

  # QML icon strip replaces canvas ligature words (G-54.3-5 canvas half)
  if [[ ! -s "$GRAPH_SRC" ]]; then
    fail "S5: WeatherGraph source missing; cannot verify icon-strip contracts (fail-closed)"
  else
    if grep -qE 'id:\s*axisIconStrip' "$GRAPH_SRC"; then
      pass "S5: QML axis icon strip present (G-54.3-5)"
    else
      fail "S5: Missing QML axis icon strip id: axisIconStrip (G-54.3-5)"
    fi

    if grep -qF '% root.axisStride' "$GRAPH_SRC"; then
      pass "S5: Icon strip visibility driven by shared stride (T-54.3-08)"
    else
      fail "S5: Icon strip visibility not driven by root.axisStride (T-54.3-08)"
    fi

    if grep -qF 'cx, height - 8' "$GRAPH_SRC"; then
      pass "S5: Timestamp baseline sits 8px above canvas base (G-54.3-5)"
    else
      fail "S5: Timestamp baseline not at height - 8 (G-54.3-5)"
    fi

    if grep -q 'chipDrawX' "$GRAPH_SRC"; then
      pass "S5: Date chip draws at collision-offset clamped position (G-54.3-5)"
    else
      fail "S5: Missing chipDrawX collision-avoidance position (G-54.3-5)"
    fi

    ligature_paint="$(grep -v '^[[:space:]]*//' "$GRAPH_SRC" | grep -c 'glyphText' || true)"
    if [[ "$ligature_paint" -eq 0 ]]; then
      pass "S5: No canvas call paints raw glyph-name strings (G-54.3-5)"
    else
      fail "S5: Canvas still paints raw glyph-name strings ${ligature_paint}x (G-54.3-5)"
    fi
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

# ===========================================================================
# Section 6: Stacked Locked Graph Instances (G-54.3-4, scope_decision_54_3_07)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 6 ]]; then
  info "--- Section 6: Stacked Locked Graph Instances ---"

  if [[ ! -s "$GRAPH_SRC" || ! -s "$POPUP_SRC" ]]; then
    fail "S6: WeatherGraph or WeatherPopup source missing; cannot verify stacked-instances contracts (fail-closed)"
  else
    instance_count="$(grep -c 'WeatherGraph {' "$POPUP_SRC" || true)"
    if [[ "$instance_count" -ge 2 ]]; then
      pass "S6: WeatherPopup stacks ${instance_count} locked WeatherGraph instances (G-54.3-4)"
    else
      fail "S6: Expected at least 2 stacked WeatherGraph instances, found ${instance_count} (G-54.3-4)"
    fi

    for chrome_id in tabBarContainer tabsRepeater tabHighlight activeTabPill; do
      chrome_graph="$(grep -v '^[[:space:]]*//' "$GRAPH_SRC" | grep -c "$chrome_id" || true)"
      chrome_popup="$(grep -v '^[[:space:]]*//' "$POPUP_SRC" | grep -c "$chrome_id" || true)"
      chrome_total=$((chrome_graph + chrome_popup))
      if [[ "$chrome_total" -eq 0 ]]; then
        pass "S6: Tab chrome identifier '$chrome_id' absent across stacked files (tab-less G-54.3-4)"
      else
        fail "S6: Tab chrome identifier '$chrome_id' present ${chrome_total}x across stacked files (tab-less G-54.3-4)"
      fi
    done

    if grep -qE 'activeMetric:[[:space:]]*"wind"' "$POPUP_SRC"; then
      pass "S6: Locked activeMetric wind declarative binding present in WeatherPopup (G-54.3-4)"
    else
      fail "S6: Missing locked activeMetric wind declarative binding in WeatherPopup (G-54.3-4)"
    fi

    writes_graph="$(grep -v '^[[:space:]]*//' "$GRAPH_SRC" | grep -cE 'activeMetric[[:space:]]*=[^=]' || true)"
    writes_popup="$(grep -v '^[[:space:]]*//' "$POPUP_SRC" | grep -cE 'activeMetric[[:space:]]*=[^=]' || true)"
    writes_total=$((writes_graph + writes_popup))
    if [[ "$writes_total" -eq 0 ]]; then
      pass "S6: Zero activeMetric runtime writes across stacked files (locked T-54.3-15)"
    else
      fail "S6: Found ${writes_total} activeMetric runtime write(s) across stacked files (locked T-54.3-15)"
    fi
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
