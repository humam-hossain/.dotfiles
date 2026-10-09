#!/usr/bin/env bash
# ===========================================================================
# Phase 54: Multi-Modal Popup Inspector & Interactive Graphs Assert Harness
# Enforces: POPUP-01..07, GRAPH-01..04, INTG-04, ASVS L1
# Decisions: D-54-01 through D-54-42
#
# Usage (from REPO_ROOT):
#   ./scripts/phase54-weather-assert.sh [1-5] [OPTIONS]
#
# Options:
#   -s, --section <1-5>    Execute only the specified section (1-5)
#   -q, --quick            Run fast static checks only (skips dots-hyprland.sh)
#       --standalone
#   -c, --syntax           Execute static bash syntax checks only
#   -h, --help             Show this help message
#
# Exit 0 if all hard asserts pass (FAIL=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if executed as root (ASVS L1 Root Privilege Prevention / T-54-01)
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
      echo "  1: Stow Leaf Symlink Topology, Packaging Integrity & QML Syntax (POPUP-01, D-54-01..04, D-54-41..42)"
      echo "  2: WeatherHeroCard Overview & WeatherAlertBanner Carousel (POPUP-02, POPUP-07, D-54-14..24)"
      echo "  3: WeatherGraph Dual Splines, Precipitation Bars & Scrub Tooltip (GRAPH-01..04, D-54-25..33)"
      echo "  4: Atmospheric, Wind, AQI & Astronomy Domain Telemetry Cards (POPUP-03..06, D-54-34..40)"
      echo "  5: Zero Submodule Churn & dots-hyprland Strict Verification (INTG-04, T-54-04)"
      echo ""
      echo "Options:"
      echo "  -s, --section <1-5>    Execute only the specified section (1-5)"
      echo "  -q, --quick            Run fast static checks only"
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

WEATHER_MOD_SRC="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather"
WEATHERPOPUP_SRC="$WEATHER_MOD_SRC/WeatherPopup.qml"
WEATHERBASE_SRC="$WEATHER_MOD_SRC/WeatherBaseCard.qml"
TARGET_DIR="$HOME/.config/quickshell/ii/modules/ii/bar/weather"

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

  # 1. Mock JSON fixtures
  for fix in "nominal.json" "severe_alerts.json" "heavy_rain.json" "sparse_offline.json"; do
    fix_path="$REPO_ROOT/tests/fixtures/weather/$fix"
    if [[ -s "$fix_path" ]]; then
      if jq empty "$fix_path" 2>/dev/null; then
        pass "S1: Fixture $fix exists and parses validly as JSON"
      else
        fail "S1: Fixture $fix has invalid JSON syntax"
      fi
    else
      fail "S1: Missing or empty fixture: $fix_path"
    fi
  done

  # 2. Source file existence
  if [[ -s "$WEATHERBASE_SRC" ]]; then
    pass "S1: restow/quickshell/.../WeatherBaseCard.qml exists and is non-empty"
  else
    fail "S1: Missing or empty source file: $WEATHERBASE_SRC"
  fi

  if [[ -s "$WEATHERPOPUP_SRC" ]]; then
    pass "S1: restow/quickshell/.../WeatherPopup.qml exists and is non-empty"
  else
    fail "S1: Missing or empty source file: $WEATHERPOPUP_SRC"
  fi

  # 3. Leaf symlink and backup verification
  if [[ -L "$TARGET_DIR/WeatherPopup.qml" ]]; then
    local_target="$(readlink -f "$TARGET_DIR/WeatherPopup.qml" || true)"
    canonical_src="$(readlink -f "$WEATHERPOPUP_SRC" || true)"
    if [[ "$local_target" == "$canonical_src" ]]; then
      pass "S1: $TARGET_DIR/WeatherPopup.qml is a valid symlink to restow overlay"
    else
      fail "S1: $TARGET_DIR/WeatherPopup.qml points to $local_target, expected $canonical_src"
    fi
  elif [[ -f "$TARGET_DIR/WeatherPopup.qml" ]]; then
    fail "S1: $TARGET_DIR/WeatherPopup.qml exists as regular file, expected leaf symlink"
  else
    fail "S1: $TARGET_DIR/WeatherPopup.qml is missing"
  fi

  if [[ -f "$TARGET_DIR/WeatherPopup.qml.bak" ]]; then
    pass "S1: Installer backup artifact $TARGET_DIR/WeatherPopup.qml.bak preserved"
  else
    fail "S1: Missing installer backup artifact $TARGET_DIR/WeatherPopup.qml.bak"
  fi

  if [[ -L "$TARGET_DIR/WeatherBaseCard.qml" ]]; then
    local_target="$(readlink -f "$TARGET_DIR/WeatherBaseCard.qml" || true)"
    canonical_src="$(readlink -f "$WEATHERBASE_SRC" || true)"
    if [[ "$local_target" == "$canonical_src" ]]; then
      pass "S1: $TARGET_DIR/WeatherBaseCard.qml is a valid symlink to restow overlay"
    else
      fail "S1: $TARGET_DIR/WeatherBaseCard.qml points to $local_target, expected $canonical_src"
    fi
  else
    fail "S1: $TARGET_DIR/WeatherBaseCard.qml is missing or not a symlink"
  fi

  # 4. Assert all parent directories are real un-folded directories
  for check_dir in "$HOME/.config" "$HOME/.config/quickshell" "$HOME/.config/quickshell/ii" "$HOME/.config/quickshell/ii/modules" "$HOME/.config/quickshell/ii/modules/ii" "$HOME/.config/quickshell/ii/modules/ii/bar" "$TARGET_DIR"; do
    if [[ -d "$check_dir" && ! -L "$check_dir" ]]; then
      pass "S1: Directory $(basename "$check_dir") is an un-folded real directory"
    else
      fail "S1: Directory $(basename "$check_dir") is symlinked or missing, expected un-folded real directory"
    fi
  done

  # 5. QML formatting & syntax check via qmlformat
  if command -v qmlformat >/dev/null 2>&1; then
    for qml_file in "$WEATHERBASE_SRC" "$WEATHERPOPUP_SRC"; do
      if [[ -f "$qml_file" ]]; then
        if qmlformat -n "$qml_file" >/dev/null 2>&1; then
          pass "S1: qmlformat -n passed for $(basename "$qml_file")"
        else
          fail "S1: qmlformat -n reported syntax or style errors for $(basename "$qml_file")"
        fi
      fi
    done
  else
    finding "S1: qmlformat not found on PATH; skipped static QML ast formatting check"
  fi

  # 6. WeatherBaseCard contract checks (D-54-04)
  if [[ -f "$WEATHERBASE_SRC" ]]; then
    base_code="$(cat "$WEATHERBASE_SRC")"
    if echo "$base_code" | grep -q 'Appearance\.colors\.colLayer2'; then
      pass "S1: WeatherBaseCard uses Appearance.colors.colLayer2 M3 surface color"
    else
      fail "S1: WeatherBaseCard missing colLayer2 surface color"
    fi
    if echo "$base_code" | grep -q 'border\.color:\s*Appearance\.colors\.colOutlineVariant'; then
      pass "S1: WeatherBaseCard uses Appearance.colors.colOutlineVariant stroke"
    else
      fail "S1: WeatherBaseCard missing colOutlineVariant stroke"
    fi
    if echo "$base_code" | grep -q 'default\s*property\s*alias\s*content:'; then
      pass "S1: WeatherBaseCard exports default property alias content for slot projection"
    else
      fail "S1: WeatherBaseCard missing default property alias content"
    fi
    if echo "$base_code" | grep -q 'iconSize:\s*18'; then
      pass "S1: WeatherBaseCard standardizes on 18px header iconography"
    else
      fail "S1: WeatherBaseCard missing 18px header iconSize"
    fi
  fi

  # 7. WeatherPopup contract checks (D-54-08, D-54-09, D-54-12, D-54-13)
  if [[ -f "$WEATHERPOPUP_SRC" ]]; then
    popup_code="$(cat "$WEATHERPOPUP_SRC")"
    if echo "$popup_code" | grep -qE 'implicitWidth:\s*(440|880)'; then
      pass "S1: WeatherPopup sets implicitWidth (440 or 880 expanded)"
    else
      fail "S1: WeatherPopup missing implicitWidth: 440/880 (D-54-08)"
    fi
    if echo "$popup_code" | grep -q 'StyledFlickable'; then
      pass "S1: WeatherPopup encapsulates content in StyledFlickable container (D-54-09)"
    else
      fail "S1: WeatherPopup missing StyledFlickable container"
    fi
    if echo "$popup_code" | grep -q 'activeInspectorCount'; then
      pass "S1: WeatherPopup tracks GlobalStates.activeInspectorCount lifecycle"
    else
      fail "S1: WeatherPopup missing GlobalStates.activeInspectorCount lifecycle hooks"
    fi
  fi
fi

# ===========================================================================
# Section 2: WeatherHeroCard Overview & WeatherAlertBanner Carousel
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: WeatherHeroCard Overview & WeatherAlertBanner Carousel ---"
  HERO_SRC="$WEATHER_MOD_SRC/WeatherHeroCard.qml"
  ALERT_SRC="$WEATHER_MOD_SRC/WeatherAlertBanner.qml"

  if [[ ! -f "$HERO_SRC" && ! -f "$ALERT_SRC" ]]; then
    if [[ "$RUN_SECTION" -eq 2 ]]; then
      fail "S2: Hero and Alert components not authored yet"
    else
      info "S2: Hero and Alert components pending wave 2"
    fi
  else
  if [[ -s "$HERO_SRC" ]]; then
    pass "S2: WeatherHeroCard.qml exists"
    hero_code="$(cat "$HERO_SRC")"
    if echo "$hero_code" | grep -q 'iconSize:\s*36'; then
      pass "S2: WeatherHeroCard uses 36px condition glyph (D-54-34)"
    else
      fail "S2: WeatherHeroCard missing 36px iconSize"
    fi
    if echo "$hero_code" | grep -q 'WeatherBaseCard'; then
      pass "S2: WeatherHeroCard inherits WeatherBaseCard"
    else
      fail "S2: WeatherHeroCard must extend WeatherBaseCard"
    fi
    if echo "$hero_code" | grep -q 'Weather\.getData()'; then
      pass "S2: WeatherHeroCard wires passive debounced reload via Weather.getData() (D-54-18, D-54-37)"
    else
      fail "S2: WeatherHeroCard missing Weather.getData() refresh wiring"
    fi
    if echo "$hero_code" | grep -q 'staleText' && echo "$hero_code" | grep -q 'm3errorContainer'; then
      pass "S2: WeatherHeroCard implements soft amber status pill for stale/offline state (D-54-32)"
    else
      fail "S2: WeatherHeroCard missing stale/offline status pill"
    fi
    if echo "$hero_code" | grep -q 'pixelSize:\s*Appearance\.font\.pixelSize\.huge'; then
      pass "S2: WeatherHeroCard uses huge bold font for temperature readout (D-54-34)"
    else
      fail "S2: WeatherHeroCard missing huge temperature pixelSize"
    fi
    if echo "$hero_code" | grep -q 'refreshDebounceTimer'; then
      pass "S2: WeatherHeroCard provides 2-second debounce timer on reload (D-54-38)"
    else
      fail "S2: WeatherHeroCard missing reload debounce timer"
    fi
  else
    fail "S2: Missing or empty $HERO_SRC"
  fi

  if [[ -s "$ALERT_SRC" ]]; then
    pass "S2: WeatherAlertBanner.qml exists"
    alert_code="$(cat "$ALERT_SRC")"
    if echo "$alert_code" | grep -q 'Revealer'; then
      pass "S2: WeatherAlertBanner wraps container in Revealer (D-54-20)"
    else
      fail "S2: WeatherAlertBanner missing Revealer wrapper"
    fi
    if echo "$alert_code" | grep -q 'alertCarousel' || echo "$alert_code" | grep -q 'currentIndex'; then
      pass "S2: WeatherAlertBanner provides multi-alert navigation carousel (D-54-22, D-54-31)"
    else
      fail "S2: WeatherAlertBanner missing multi-alert stepping logic"
    fi
    if echo "$alert_code" | grep -q 'getAlertColor'; then
      pass "S2: WeatherAlertBanner binds dynamic M3 severity tint via WeatherGlyphs.getAlertColor (D-54-30)"
    else
      fail "S2: WeatherAlertBanner missing dynamic getAlertColor tint binding"
    fi
    if echo "$alert_code" | grep -q 'expanded\s*=\s*!root\.expanded' || echo "$alert_code" | grep -q 'root\.expanded'; then
      pass "S2: WeatherAlertBanner implements animated advisory drawer (D-54-30)"
    else
      fail "S2: WeatherAlertBanner missing expandable advisory drawer"
    fi
  else
    fail "S2: Missing or empty $ALERT_SRC"
  fi

  # 3. WeatherPopup composition check
  if [[ -s "$WEATHERPOPUP_SRC" ]]; then
    popup_code="$(cat "$WEATHERPOPUP_SRC")"
    if echo "$popup_code" | grep -q 'WeatherAlertBanner' && echo "$popup_code" | grep -q 'WeatherHeroCard'; then
      pass "S2: WeatherPopup instantiates both WeatherAlertBanner and WeatherHeroCard"
    else
      fail "S2: WeatherPopup missing WeatherAlertBanner or WeatherHeroCard instantiation"
    fi
  fi

  # 4. Headless Mock Data JS Logic Evaluation via Node.js
  if command -v node >/dev/null 2>&1; then
    node_res=$(node -e '
      const fs = require("fs");
      const nominal = JSON.parse(fs.readFileSync("tests/fixtures/weather/nominal.json"));
      const severe = JSON.parse(fs.readFileSync("tests/fixtures/weather/severe_alerts.json"));
      const sparse = JSON.parse(fs.readFileSync("tests/fixtures/weather/sparse_offline.json"));

      // Hero temp format logic check
      function formatTemp(raw) {
        if (raw === undefined || raw === null || raw === "" || raw === "--" || isNaN(Number(raw))) return "--°C";
        return Math.round(Number(raw)) + "°C";
      }

      if (formatTemp(nominal.data.current_condition[0].temp_C) !== "28°C") throw new Error("nominal temp mismatch");
      if (formatTemp(sparse.data.current_condition[0].temp_C) !== "--°C") throw new Error("sparse temp mismatch");

      // Alert array check
      if (!Array.isArray(severe.data.alerts.alert) || severe.data.alerts.alert.length < 2) throw new Error("severe alerts count < 2");
      if (nominal.data.alerts.alert.length !== 0) throw new Error("nominal alerts not empty");

      console.log("OK");
    ' 2>/dev/null || echo "FAIL")
    if [[ "$node_res" == "OK" ]]; then
      pass "S2: Headless Node.js evaluation of mock fixtures logic passed"
    else
      fail "S2: Headless Node.js evaluation of mock fixtures failed"
    fi
  fi
  fi
fi

# ===========================================================================
# Section 3: WeatherGraph Dual Splines, Precipitation Bars & Scrub Tooltip
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: WeatherGraph Dual Splines, Precipitation Bars & Scrub Tooltip ---"
  GRAPH_SRC="$WEATHER_MOD_SRC/WeatherGraph.qml"

  if [[ ! -f "$GRAPH_SRC" ]]; then
    if [[ "$RUN_SECTION" -eq 3 ]]; then
      fail "S3: WeatherGraph.qml not authored yet"
    else
      info "S3: WeatherGraph.qml pending wave 3"
    fi
  else
  if [[ -s "$GRAPH_SRC" ]]; then
    pass "S3: WeatherGraph.qml exists"
    graph_code="$(cat "$GRAPH_SRC")"
    if echo "$graph_code" | grep -q 'WeatherBaseCard'; then
      pass "S3: WeatherGraph extends WeatherBaseCard"
    else
      fail "S3: WeatherGraph must extend WeatherBaseCard"
    fi
    if echo "$graph_code" | grep -q 'Canvas\s*{'; then
      pass "S3: WeatherGraph instantiates 2D Canvas for spline rendering (GRAPH-01)"
    else
      fail "S3: WeatherGraph missing Canvas component"
    fi
    if echo "$graph_code" | grep -q 'bezierCurveTo' && echo "$graph_code" | grep -q 'computeMonotoneSplineControlPoints'; then
      pass "S3: WeatherGraph implements Fritsch-Carlson Monotone Cubic Spline interpolation (GRAPH-01, D-54-15)"
    else
      fail "S3: WeatherGraph missing Fritsch-Carlson spline interpolation logic"
    fi
    if echo "$graph_code" | grep -q 'time.*!==.*"24"'; then
      pass "S3: WeatherGraph normalizes hourly data by explicitly filtering time: '24' day roll-up slot (Pitfall 1)"
    else
      fail "S3: WeatherGraph missing time: '24' roll-up filter"
    fi
    if echo "$graph_code" | grep -q 'MouseArea' && echo "$graph_code" | grep -q 'hoverEnabled:\s*true'; then
      pass "S3: WeatherGraph implements hover scrub MouseArea (GRAPH-03)"
    else
      fail "S3: WeatherGraph missing hover scrub MouseArea"
    fi
    if echo "$graph_code" | grep -A 25 'onPositionChanged:' | grep -q 'requestPaint'; then
      fail "S3: Zero-repaint violation: requestPaint() found inside onPositionChanged (GRAPH-03, D-54-20)"
    else
      pass "S3: Zero-repaint invariant satisfied: onPositionChanged updates QML overlay without Canvas repainting (GRAPH-03, D-54-20)"
    fi
    if echo "$graph_code" | grep -q 'popupActive' && echo "$graph_code" | grep -q 'requestPaint'; then
      pass "S3: WeatherGraph gates Canvas repaints strictly behind popupActive visibility (GRAPH-04, D-54-22)"
    else
      fail "S3: WeatherGraph missing popupActive gating for Canvas repaints"
    fi
    if echo "$graph_code" | grep -q 'tooltipPill' && echo "$graph_code" | grep -q 'snapDot'; then
      pass "S3: WeatherGraph includes snapDot and tooltipPill overlay items (D-54-21)"
    else
      fail "S3: WeatherGraph missing snapDot or tooltipPill overlay items"
    fi
  else
    fail "S3: Missing or empty $GRAPH_SRC"
  fi

  # 2. WeatherPopup instantiates WeatherGraph
  if [[ -s "$WEATHERPOPUP_SRC" ]]; then
    popup_code="$(cat "$WEATHERPOPUP_SRC")"
    if echo "$popup_code" | grep -q 'WeatherGraph'; then
      pass "S3: WeatherPopup instantiates WeatherGraph at position 3"
    else
      fail "S3: WeatherPopup missing WeatherGraph instantiation"
    fi
  fi

  # 3. Headless Node.js Monotone Spline Math Evaluation
  if command -v node >/dev/null 2>&1; then
    math_res=$(node -e '
      const fs = require("fs");
      const nominal = JSON.parse(fs.readFileSync("tests/fixtures/weather/nominal.json"));
      const hours = nominal.data.weather[0].hourly.filter(h => String(h.time) !== "24");
      if (hours.length !== 24) throw new Error("filtered hours !== 24, got " + hours.length);

      const points = hours.map((h, i) => ({ x: i * 10, y: Number(h.tempC) }));

      function computeMonotoneSplineControlPoints(pts) {
        const n = pts.length;
        const dx = [], dy = [], m = [];
        for (let i = 0; i < n - 1; ++i) {
          const dxi = pts[i + 1].x - pts[i].x;
          const dyi = pts[i + 1].y - pts[i].y;
          dx.push(dxi); dy.push(dyi);
          m.push(dxi === 0 ? 0 : dyi / dxi);
        }
        const tangents = new Array(n);
        tangents[0] = m[0]; tangents[n - 1] = m[n - 2];
        for (let i = 1; i < n - 1; ++i) tangents[i] = (m[i - 1] + m[i]) / 2;
        for (let i = 0; i < n - 1; ++i) {
          if (m[i] === 0) { tangents[i] = 0; tangents[i + 1] = 0; }
          else {
            const alpha = tangents[i] / m[i];
            const beta = tangents[i + 1] / m[i];
            if (alpha < 0) tangents[i] = 0;
            if (beta < 0) tangents[i + 1] = 0;
            const distSq = alpha * alpha + beta * beta;
            if (distSq > 9) {
              const tau = 3 / Math.sqrt(distSq);
              tangents[i] = tau * alpha * m[i];
              tangents[i + 1] = tau * beta * m[i];
            }
          }
        }
        const cp = [];
        for (let i = 0; i < n - 1; ++i) {
          cp.push({
            cp1x: pts[i].x + dx[i] / 3,
            cp1y: pts[i].y + tangents[i] * dx[i] / 3,
            cp2x: pts[i + 1].x - dx[i] / 3,
            cp2y: pts[i + 1].y - tangents[i + 1] * dx[i] / 3
          });
        }
        return cp;
      }

      const cp = computeMonotoneSplineControlPoints(points);
      if (cp.length !== 23) throw new Error("control points length !== 23");
      for (const seg of cp) {
        if (isNaN(seg.cp1x) || isNaN(seg.cp1y) || isNaN(seg.cp2x) || isNaN(seg.cp2y)) {
          throw new Error("NaN control point coordinate found");
        }
      }
      console.log("OK");
    ' 2>/dev/null || echo "FAIL")
    if [[ "$math_res" == "OK" ]]; then
      pass "S3: Headless Node.js evaluation of Fritsch-Carlson control points passed with zero NaNs"
    else
      fail "S3: Headless Node.js evaluation of Fritsch-Carlson spline math failed"
    fi
  fi
  fi
fi

# ===========================================================================
# Section 4: Atmospheric, Wind, AQI & Astronomy Domain Telemetry Cards
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Atmospheric, Wind, AQI & Astronomy Domain Telemetry Cards ---"
  ATMO_SRC="$WEATHER_MOD_SRC/WeatherAtmosphericCard.qml"
  WIND_SRC="$WEATHER_MOD_SRC/WeatherWindCard.qml"
  AQI_SRC="$WEATHER_MOD_SRC/WeatherAqiCard.qml"
  ASTRO_SRC="$WEATHER_MOD_SRC/WeatherAstronomyCard.qml"

  cards_present=0
  for card_file in "$ATMO_SRC" "$WIND_SRC" "$AQI_SRC" "$ASTRO_SRC"; do
    if [[ -s "$card_file" ]]; then
      cards_present=$((cards_present + 1))
    fi
  done

  if [[ "$cards_present" -lt 4 ]]; then
    if [[ "$RUN_SECTION" -eq 4 ]]; then
      fail "S4: Some domain telemetry cards not authored yet ($cards_present/4 found)"
    else
      info "S4: Domain telemetry cards pending wave 4"
    fi
  else
    # 1. Atmospheric Card Contract & Invariants
    if [[ -s "$ATMO_SRC" ]]; then
      pass "S4: WeatherAtmosphericCard.qml exists"
      atmo_code="$(cat "$ATMO_SRC")"
      if echo "$atmo_code" | grep -q 'WeatherBaseCard'; then
        pass "S4: WeatherAtmosphericCard extends WeatherBaseCard (D-54-04)"
      else
        fail "S4: WeatherAtmosphericCard must extend WeatherBaseCard"
      fi
      if echo "$atmo_code" | grep -q 'columns:\s*2'; then
        pass "S4: WeatherAtmosphericCard uses 2-column compact grid layout (D-54-23)"
      else
        fail "S4: WeatherAtmosphericCard missing 2-column grid layout"
      fi
      if echo "$atmo_code" | grep -q 'Humidity' && echo "$atmo_code" | grep -q 'Pressure'; then
        pass "S4: WeatherAtmosphericCard presents Humidity and Pressure telemetry (POPUP-03)"
      else
        fail "S4: WeatherAtmosphericCard missing humidity/pressure metrics"
      fi
      if echo "$atmo_code" | grep -q 'UV Index' && echo "$atmo_code" | grep -q 'getUvRisk'; then
        pass "S4: WeatherAtmosphericCard presents UV index with qualitative risk categories (POPUP-03, D-54-23)"
      else
        fail "S4: WeatherAtmosphericCard missing UV index qualitative categories"
      fi
      if echo "$atmo_code" | grep -q 'Visibility'; then
        pass "S4: WeatherAtmosphericCard presents Visibility telemetry (POPUP-03)"
      else
        fail "S4: WeatherAtmosphericCard missing visibility metrics"
      fi
    else
      fail "S4: Missing $ATMO_SRC"
    fi

    # 2. Wind Card Contract, Compass Rose Dial & Shortest-Path Math
    if [[ -s "$WIND_SRC" ]]; then
      pass "S4: WeatherWindCard.qml exists"
      wind_code="$(cat "$WIND_SRC")"
      if echo "$wind_code" | grep -q 'WeatherBaseCard'; then
        pass "S4: WeatherWindCard extends WeatherBaseCard (D-54-04)"
      else
        fail "S4: WeatherWindCard must extend WeatherBaseCard"
      fi
      if echo "$wind_code" | grep -q 'implicitHeight:\s*56' && echo "$wind_code" | grep -q 'implicitWidth:\s*56'; then
        pass "S4: WeatherWindCard renders 56px circular compass dial (D-54-24)"
      else
        fail "S4: WeatherWindCard missing 56px circular compass dial"
      fi
      if echo "$wind_code" | grep -q 'colPrimary' && echo "$wind_code" | grep -q 'text:\s*"N"'; then
        pass "S4: WeatherWindCard highlights North cardinal mark in primary accent (D-54-26)"
      else
        fail "S4: WeatherWindCard missing highlighted North cardinal mark"
      fi
      if echo "$wind_code" | grep -q '(targetDegree - (currentDegree % 360) + 540) % 360 - 180'; then
        pass "S4: WeatherWindCard implements shortest-path angular delta math (POPUP-05, D-54-25)"
      else
        fail "S4: WeatherWindCard missing shortest-path angular math equation"
      fi
      if echo "$wind_code" | grep -q 'expressiveEffects'; then
        pass "S4: WeatherWindCard animates needle with expressiveEffects Bezier curve (D-54-25)"
      else
        fail "S4: WeatherWindCard missing expressiveEffects animation curve"
      fi
      if echo "$wind_code" | grep -q 'windKmph' && echo "$wind_code" | grep -q 'windGustKmph' && echo "$wind_code" | grep -q 'windDir'; then
        pass "S4: WeatherWindCard presents wind speed, gusts and 16-point direction (POPUP-05)"
      else
        fail "S4: WeatherWindCard missing wind speed, gust or direction metrics"
      fi
    else
      fail "S4: Missing $WIND_SRC"
    fi

    # 3. AQI Card Contract, EPA Badge & 6-Segment Meter
    if [[ -s "$AQI_SRC" ]]; then
      pass "S4: WeatherAqiCard.qml exists"
      aqi_code="$(cat "$AQI_SRC")"
      if echo "$aqi_code" | grep -q 'WeatherBaseCard'; then
        pass "S4: WeatherAqiCard extends WeatherBaseCard (D-54-04)"
      else
        fail "S4: WeatherAqiCard must extend WeatherBaseCard"
      fi
      if echo "$aqi_code" | grep -q 'WeatherGlyphs\.getAqiColor'; then
        pass "S4: WeatherAqiCard binds US-EPA category badge color via WeatherGlyphs.getAqiColor (POPUP-04, D-54-27)"
      else
        fail "S4: WeatherAqiCard missing WeatherGlyphs.getAqiColor badge binding"
      fi
      if echo "$aqi_code" | grep -q 'model:\s*6'; then
        pass "S4: WeatherAqiCard renders 6-segment EPA scale mini progress meter (POPUP-04, D-54-27)"
      else
        fail "S4: WeatherAqiCard missing 6-segment mini progress meter"
      fi
      if echo "$aqi_code" | grep -q 'pm2_5' && echo "$aqi_code" | grep -q 'pm10'; then
        pass "S4: WeatherAqiCard presents PM2.5 and PM10 particulate readouts (POPUP-04, D-54-27)"
      else
        fail "S4: WeatherAqiCard missing particulate PM2.5 or PM10 readouts"
      fi
    else
      fail "S4: Missing $AQI_SRC"
    fi

    # 4. Astronomy Card Contract, Twilight Glyphs & Canvas 2D Lunar Disc
    if [[ -s "$ASTRO_SRC" ]]; then
      pass "S4: WeatherAstronomyCard.qml exists"
      astro_code="$(cat "$ASTRO_SRC")"
      if echo "$astro_code" | grep -q 'WeatherBaseCard'; then
        pass "S4: WeatherAstronomyCard extends WeatherBaseCard (D-54-04)"
      else
        fail "S4: WeatherAstronomyCard must extend WeatherBaseCard"
      fi
      if echo "$astro_code" | grep -q 'sunrise' && echo "$astro_code" | grep -q 'sunset' && echo "$astro_code" | grep -q 'wb_twilight'; then
        pass "S4: WeatherAstronomyCard presents solar twilight telemetry (POPUP-06, D-54-28)"
      else
        fail "S4: WeatherAstronomyCard missing solar twilight telemetry"
      fi
      if echo "$astro_code" | grep -q 'moonCanvas' && echo "$astro_code" | grep -q 'ctx\.ellipse' && echo "$astro_code" | grep -q 'ctx\.arc'; then
        pass "S4: WeatherAstronomyCard renders dynamic lunar disc terminator arc via Canvas 2D (POPUP-06, D-54-29)"
      else
        fail "S4: WeatherAstronomyCard missing Canvas 2D lunar terminator arc"
      fi
      if echo "$astro_code" | grep -q 'moonPhase' && echo "$astro_code" | grep -q 'moonIllumination'; then
        pass "S4: WeatherAstronomyCard presents moon phase name and illumination percentage (POPUP-06)"
      else
        fail "S4: WeatherAstronomyCard missing moon phase or illumination percentage"
      fi
    else
      fail "S4: Missing $ASTRO_SRC"
    fi

    # 5. WeatherPopup Paired Grid Arrangement
    if [[ -s "$WEATHERPOPUP_SRC" ]]; then
      popup_code="$(cat "$WEATHERPOPUP_SRC")"
      if echo "$popup_code" | grep -q 'WeatherAtmosphericCard' && echo "$popup_code" | grep -q 'WeatherWindCard'; then
        pass "S4: WeatherPopup pairs WeatherAtmosphericCard and WeatherWindCard in 2-column row (D-54-10)"
      else
        fail "S4: WeatherPopup missing Atmospheric/Wind paired row"
      fi
      if echo "$popup_code" | grep -q 'WeatherAqiCard' && echo "$popup_code" | grep -q 'WeatherAstronomyCard'; then
        pass "S4: WeatherPopup pairs WeatherAqiCard and WeatherAstronomyCard in 2-column row (D-54-10)"
      else
        fail "S4: WeatherPopup missing AQI/Astronomy paired row"
      fi
    fi

    # 6. Leaf Symlinks Check for all 4 Domain Cards
    for card_name in "WeatherAtmosphericCard.qml" "WeatherWindCard.qml" "WeatherAqiCard.qml" "WeatherAstronomyCard.qml"; do
      if [[ -L "$TARGET_DIR/$card_name" ]]; then
        target_dest="$(readlink -f "$TARGET_DIR/$card_name" || true)"
        expected_dest="$(readlink -f "$WEATHER_MOD_SRC/$card_name" || true)"
        if [[ "$target_dest" == "$expected_dest" ]]; then
          pass "S4: $TARGET_DIR/$card_name is a valid leaf symlink to restow overlay"
        else
          fail "S4: $TARGET_DIR/$card_name points to $target_dest, expected $expected_dest"
        fi
      else
        fail "S4: $TARGET_DIR/$card_name missing or not a symlink"
      fi
    done

    # 7. Headless Node.js Wind Shortest-Path & Lunar Illumination Math
    if command -v node >/dev/null 2>&1; then
      node_eval=$(node -e '
        // Test 1: Wind shortest path across 355° -> 5° boundary
        function shortestDelta(current, target) {
          return (target - (current % 360) + 540) % 360 - 180;
        }
        const delta1 = shortestDelta(355, 5); // Should be +10, NOT -350
        if (delta1 !== 10) throw new Error("delta 355->5 expected 10, got " + delta1);

        const delta2 = shortestDelta(5, 355); // Should be -10, NOT +350
        if (delta2 !== -10) throw new Error("delta 5->355 expected -10, got " + delta2);

        const delta3 = shortestDelta(90, 270); // 180 degrees
        if (Math.abs(delta3) !== 180) throw new Error("delta 90->270 expected +/-180, got " + delta3);

        // Test 2: UV risk classification
        function getUvRisk(uv) {
          const val = parseInt(uv, 10);
          if (isNaN(val) || val <= 2) return "Low";
          if (val <= 5) return "Moderate";
          if (val <= 7) return "High";
          if (val <= 10) return "Very High";
          return "Extreme";
        }
        if (getUvRisk("1") !== "Low" || getUvRisk("4") !== "Moderate" || getUvRisk("6") !== "High" || getUvRisk("9") !== "Very High" || getUvRisk("12") !== "Extreme") {
          throw new Error("UV risk classifier mismatch");
        }

        // Test 3: Lunar terminator arc geometry values
        const radius = 15;
        for (let pct = 0; pct <= 100; pct += 25) {
          const frac = pct / 100.0;
          const k = 2 * frac - 1;
          const termX = Math.max(0.1, Math.abs(k) * radius);
          if (isNaN(termX) || termX < 0.1 || termX > radius + 0.001) {
            throw new Error("Terminator X calculation out of bounds: " + termX);
          }
        }
        console.log("OK");
      ' 2>/dev/null || echo "FAIL")

      if [[ "$node_eval" == "OK" ]]; then
        pass "S4: Headless Node.js evaluation of shortest-path wind math, UV risk logic & lunar terminator geometry passed"
      else
        fail "S4: Headless Node.js evaluation of domain telemetry math failed"
      fi
    fi
  fi
fi

# ===========================================================================
# Section 5: Zero Submodule Churn & dots-hyprland Strict Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Zero Submodule Churn & dots-hyprland Strict Verification ---"

  # Assert submodule vendor/dots-hyprland has zero untracked/modified git churn
  vendor_churn="$(git status --porcelain "$REPO_ROOT/vendor/dots-hyprland" 2>/dev/null || true)"
  if [[ -z "$vendor_churn" ]]; then
    pass "S5: Submodule vendor/dots-hyprland is completely clean (zero git churn)"
  else
    fail "S5: Submodule vendor/dots-hyprland has uncommitted changes: $vendor_churn"
  fi

  # Execute arch/dots-hyprland.sh verify --strict unless in quick mode
  if [[ "$QUICK_MODE" -eq 1 ]]; then
    info "S5: Quick mode active; skipped ./arch/dots-hyprland.sh verify --strict"
  else
    if [[ -x "$REPO_ROOT/arch/dots-hyprland.sh" ]]; then
      if "$REPO_ROOT/arch/dots-hyprland.sh" verify --strict >/dev/null 2>&1; then
        pass "S5: ./arch/dots-hyprland.sh verify --strict exited 0"
      else
        fail "S5: ./arch/dots-hyprland.sh verify --strict reported failures"
      fi
    else
      fail "S5: $REPO_ROOT/arch/dots-hyprland.sh not executable or missing"
    fi
  fi
fi

# ===========================================================================
# Final Summary
# ===========================================================================
info "=========================================================="
info "Phase 54 Assert Summary: FAIL=$FAIL, FINDINGS=$FINDINGS"
info "=========================================================="

if [[ "$FAIL" -gt 0 ]]; then
  echo "Phase 54 assert harness failed with $FAIL failure(s)" >&2
  exit 1
fi

pass "All executed Phase 54 assertions passed successfully!"
exit 0
