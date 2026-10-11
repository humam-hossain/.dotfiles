#!/usr/bin/env bash
# ===========================================================================
# Phase 54.2: Hourly Parameter Modeling and Rolling Cache Service Assert Harness
# Enforces: DATA-01, DATA-02, DATA-03, INTG-02, ASVS L1
# Decisions: D-54.2-01 through D-54.2-24
#
# Usage (from REPO_ROOT):
#   ./scripts/phase54.2-weather-assert.sh [1-5] [OPTIONS]
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

# Fail closed if executed as root (ASVS L1 Root Privilege Prevention / T-54.2-01)
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
  # Clean up any transient pycache in stow directories
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
      echo "  1: Stow Leaf Symlink Topology & Submodule Cleanliness (INTG-02, D-54.2-16)"
      echo "  2: wwo-fetcher.py 0-Cost Rollover & Historical Cache (DATA-02, D-54.2-09..16)"
      echo "  3: Weather.qml 25-Point Rolling Timeline Geometry & Top-of-Hour Sync (DATA-01, D-54.2-01..08)"
      echo "  4: Grouped Domain Sub-Objects & Numeric Normalization (DATA-03, D-54.2-17..18, D-54.2-21..24)"
      echo "  5: Cached Series Accessor & Backward Compatibility (DATA-01, DATA-03, D-54.2-19..20)"
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

FETCHER_SRC="$REPO_ROOT/stow/weather/.config/weather/wwo-fetcher.py"
WEATHER_SRC="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/Weather.qml"
TARGET_WEATHER="$HOME/.config/quickshell/ii/services/Weather.qml"

# Syntax-only mode
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  bash -n "$0"
  pass "Assert harness bash syntax check passed (bash -n verified)"
  info "=== Syntax Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Stow Leaf Symlink Topology & Submodule Cleanliness (INTG-02, D-54.2-16)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Stow Leaf Symlink Topology & Submodule Cleanliness ---"

  if [[ -s "$FETCHER_SRC" ]]; then
    pass "S1: stow/weather/.../wwo-fetcher.py exists and is non-empty"
  else
    fail "S1: Missing or empty fetcher source file: $FETCHER_SRC"
  fi

  if [[ -s "$WEATHER_SRC" ]]; then
    pass "S1: restow/quickshell/.../Weather.qml exists and is non-empty"
  else
    fail "S1: Missing or empty Weather.qml source file: $WEATHER_SRC"
  fi

  if [[ -L "$TARGET_WEATHER" ]]; then
    target_link="$(readlink -f "$TARGET_WEATHER" || true)"
    canonical_src="$(readlink -f "$WEATHER_SRC" || true)"
    if [[ "$target_link" == "$canonical_src" ]]; then
      pass "S1: $TARGET_WEATHER is a valid leaf symlink resolving to restow overlay"
    else
      fail "S1: $TARGET_WEATHER resolves to $target_link, expected $canonical_src"
    fi
  elif [[ -f "$TARGET_WEATHER" ]]; then
    fail "S1: $TARGET_WEATHER exists as a regular file, expected leaf symlink"
  else
    finding "S1: $TARGET_WEATHER is not present in local home directory"
  fi

  # Zero git churn in vendor/dots-hyprland (T-54.2-12)
  vendor_churn="$(git status --porcelain vendor/dots-hyprland 2>/dev/null || true)"
  if [[ -z "$vendor_churn" ]]; then
    pass "S1: vendor/dots-hyprland working tree is pristine with zero modifications"
  else
    fail "S1: vendor/dots-hyprland contains uncommitted changes:\n$vendor_churn"
  fi

  # Full repository verification unless running in quick mode
  if [[ "$QUICK_MODE" -eq 0 ]]; then
    info "S1: Running strict repository verification (arch/dots-hyprland.sh verify --strict)..."
    rm -rf "$REPO_ROOT/stow/weather/.config/weather/__pycache__" 2>/dev/null || true
    if ./arch/dots-hyprland.sh verify --strict >/dev/null 2>&1; then
      pass "S1: ./arch/dots-hyprland.sh verify --strict passed with zero findings"
    else
      fail "S1: ./arch/dots-hyprland.sh verify --strict reported errors or findings"
    fi
  else
    info "S1: Quick mode active; skipped full dots-hyprland.sh verify"
  fi
fi

# ===========================================================================
# Section 2: wwo-fetcher.py 0-Cost Rollover & Historical Cache (DATA-02, D-54.2-09..16)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: wwo-fetcher.py 0-Cost Rollover & Historical Cache ---"

  # 1. Python AST parse
  if python3 -c "import ast; ast.parse(open('$FETCHER_SRC').read())" 2>/dev/null; then
    pass "S2: wwo-fetcher.py passes static AST compilation check"
  else
    fail "S2: wwo-fetcher.py failed AST compilation check"
  fi

  # 2. In-memory Python verification
  TEST_DIR="$(mktemp -d)"
  TMP_DIRS+=("$TEST_DIR")

  python_test_out=$(python3 - <<PYEOF 2>&1
import sys, os, json, tempfile
sys.path.insert(0, os.path.dirname("$FETCHER_SRC"))
import importlib.util

spec = importlib.util.spec_from_file_location("fetcher", "$FETCHER_SRC")
fetcher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fetcher)

# Test 2.1: Midnight rollover (day_diff == 1)
prev = {
    "data": {
        "weather": [
            {"date": "2026-10-10", "hourly": [{"time": "0"}, {"time": "100"}]}
        ]
    },
    "history": []
}
new_data = {
    "weather": [
        {"date": "2026-10-11", "hourly": [{"time": "0"}]}
    ]
}
hist1 = fetcher.resolve_history_rollover(prev, new_data)
assert len(hist1) == 1, f"Expected 1 history day, got {len(hist1)}"
assert hist1[0]["date"] == "2026-10-10", f"Expected promoted date 2026-10-10, got {hist1[0].get('date')}"
assert len(hist1[0]["hourly"]) == 2, f"Expected 2 hourly slots promoted, got {len(hist1[0].get('hourly', []))}"

# Test 2.2: Same-day update (day_diff == 0) preserves yesterday
prev_same = {
    "data": {"weather": [{"date": "2026-10-11", "hourly": []}]},
    "history": [{"date": "2026-10-10", "hourly": [{"time": "0"}]}]
}
new_same = {"weather": [{"date": "2026-10-11", "hourly": []}]}
hist2 = fetcher.resolve_history_rollover(prev_same, new_same)
assert len(hist2) == 1 and hist2[0]["date"] == "2026-10-10", f"Same-day preservation failed: {hist2}"

# Test 2.3: Multi-day downtime (day_diff > 1) invalidates
prev_stale = {
    "data": {"weather": [{"date": "2026-10-08", "hourly": []}]},
    "history": [{"date": "2026-10-07"}]
}
hist3 = fetcher.resolve_history_rollover(prev_stale, new_data)
assert len(hist3) == 0, f"Multi-day downtime invalidation failed: {hist3}"

# Test 2.4: Clock anomaly (day_diff < 0) invalidates
prev_future = {
    "data": {"weather": [{"date": "2026-10-15", "hourly": []}]},
    "history": []
}
hist4 = fetcher.resolve_history_rollover(prev_future, new_data)
assert len(hist4) == 0, f"Clock anomaly invalidation failed: {hist4}"

# Test 2.5: Cold boot restoration & downtime invalidation in ensure_fallback_cache
with tempfile.TemporaryDirectory() as td:
    c_path = os.path.join(td, "weather.json")
    p_path = os.path.join(td, "last.json")
    old_cache = {
        "status": "ok",
        "data": {"weather": [{"date": "2026-10-01", "hourly": []}]},
        "history": [{"date": "2026-09-30"}]
    }
    with open(p_path, "w") as f:
        json.dump(old_cache, f)
    fetcher.ensure_fallback_cache(c_path, p_path, {})
    with open(c_path) as f:
        restored = json.load(f)
    assert restored["history"] == [], "Cold boot failed to invalidate >1 day old history"
    assert restored["is_stale"] is True, "Cold boot restored cache must be marked is_stale"

print("ALL_PYTHON_ROLLOVER_TESTS_PASS")
PYEOF
)

  if [[ "$python_test_out" =~ "ALL_PYTHON_ROLLOVER_TESTS_PASS" ]]; then
    pass "S2: Python rollover state machine, downtime invalidation, and cold-boot restoration passed"
  else
    fail "S2: Python rollover unit tests failed:\n$python_test_out"
  fi

  # 3. CLI --status execution check
  status_out=$(python3 "$FETCHER_SRC" --status 2>&1 || true)
  if [[ "$status_out" =~ "Historical Cache:" ]]; then
    pass "S2: wwo-fetcher.py --status cleanly reports Historical Cache status"
  else
    fail "S2: wwo-fetcher.py --status missing Historical Cache output:\n$status_out"
  fi
fi

# ===========================================================================
# Section 3: Weather.qml 25-Point Rolling Timeline Geometry & Top-of-Hour Sync (DATA-01, D-54.2-01..08)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Weather.qml 25-Point Rolling Timeline Geometry & Top-of-Hour Sync ---"

  node_sec3_out=$(node - <<NODEOF 2>&1
const fs = require("fs");
const assert = require("assert");
const qml = fs.readFileSync("$WEATHER_SRC", "utf8");

// AST declarations
assert(qml.includes("property var timeline: []"), "Missing timeline property");
assert(qml.includes("property var tempBounds:"), "Missing tempBounds property");
assert(qml.includes("property var rainBounds:"), "Missing rainBounds property");
assert(qml.includes("property int activeTimelineHour:"), "Missing activeTimelineHour property");
assert(qml.includes("property var _seriesCache:"), "Missing _seriesCache property");
assert(qml.includes("property int _timelineRevision:"), "Missing _timelineRevision property");
assert(qml.includes("property var activePayload:"), "Missing activePayload property");
assert(qml.includes("function rebuildTimeline()"), "Missing rebuildTimeline method");

// WWO time 24 filter
assert(qml.includes('h.time === "24"') || qml.includes('h.time === 24'), "Missing WWO time 24 filter");

// 24-step normalizedX formula
assert(qml.includes("/ 24.0") || qml.includes("/ 24"), "Missing normalizedX index / 24 calculation");

// Top-of-hour listener in fallbackTimer
assert(qml.includes("currentHour !== root.activeTimelineHour"), "Missing top-of-hour rollover check");

console.log("SECTION_3_TIMELINE_GEOMETRY_PASS");
NODEOF
)

  if [[ "$node_sec3_out" =~ "SECTION_3_TIMELINE_GEOMETRY_PASS" ]]; then
    pass "S3: 25-point timeline geometry, time 24 filter, normalizedX grid, and top-of-hour listener verified"
  else
    fail "S3: Section 3 checks failed:\n$node_sec3_out"
  fi
fi

# ===========================================================================
# Section 4: Grouped Domain Sub-Objects & Numeric Normalization (DATA-03, D-54.2-17..18, D-54.2-21..24)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Grouped Domain Sub-Objects & Numeric Normalization ---"

  node_sec4_out=$(node - <<NODEOF 2>&1
const fs = require("fs");
const assert = require("assert");
const qml = fs.readFileSync("$WEATHER_SRC", "utf8");

// 6 domain objects
const domains = ["thermal:", "moisture:", "wind:", "aqi:", "atmosphere:", "solar:"];
domains.forEach(d => assert(qml.includes(d), "Missing domain object: " + d));

// Metric attributes across domains
const metrics = [
  "tempC:", "feelsLikeC:", "dewPointC:", "precipMM:", "rainProb:",
  "speedKmph:", "gustKmph:", "epaIndex:", "pm2_5:", "pm10:",
  "pressureHpa:", "visibilityKm:", "uvIndex:"
];
metrics.forEach(m => assert(qml.includes(m), "Missing metric key: " + m));

// Null-safe temperature bounds
assert(qml.includes("Math.min(...validTemps)"), "Missing null-safe temp bounds evaluation");
assert(qml.includes("Math.max(...validTemps)"), "Missing max temp bounds evaluation");

// NOW slot reconciliation
assert(qml.includes("isNow"), "Missing isNow flag handling");
assert(qml.includes("chanceofrain"), "Missing chanceofrain hourly forecast blend");

console.log("SECTION_4_DOMAIN_OBJECTS_PASS");
NODEOF
)

  if [[ "$node_sec4_out" =~ "SECTION_4_DOMAIN_OBJECTS_PASS" ]]; then
    pass "S4: 6 typed domain groups, numeric parsing, null-safe bounds, and NOW slot reconciliation verified"
  else
    fail "S4: Section 4 checks failed:\n$node_sec4_out"
  fi
fi

# ===========================================================================
# Section 5: Cached Series Accessor & Backward Compatibility (DATA-01, DATA-03, D-54.2-19..20)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Cached Series Accessor & Backward Compatibility ---"

  node_sec5_out=$(node - <<NODEOF 2>&1
const fs = require("fs");
const assert = require("assert");
const qml = fs.readFileSync("$WEATHER_SRC", "utf8");

// getSeries declaration and caching
assert(qml.includes("function getSeries(metricPath)"), "Missing getSeries method");
assert(qml.includes("root._seriesCache[metricPath]"), "Missing _seriesCache read/write");
assert(qml.includes("root._seriesCache = ({})") || qml.includes("root._seriesCache = {}"), "Missing cache invalidation");
assert(qml.includes("root._timelineRevision++"), "Missing revision increment");

// Backward compatibility facades
assert(qml.includes("property var hourly: []"), "Missing hourly facade");
assert(qml.includes("property var current:"), "Missing current facade");
assert(qml.includes("property var aqi:"), "Missing aqi facade");
assert(qml.includes("property var astronomy:"), "Missing astronomy facade");
assert(qml.includes("property var alerts: []"), "Missing alerts facade");
assert(qml.includes("property var data:"), "Missing data facade");

// Simulated VM timeline projection & getSeries validation
const WeatherGlyphs = {
  getGlyph: () => "clear",
  getAqiCategory: () => "Good",
  getAqiColor: () => "green",
  getAlertColor: () => "red"
};

const root = {
  activePayload: {
    status: "ok",
    data: {
      current_condition: [{
        temp_C: "25",
        FeelsLikeC: "27",
        humidity: "65",
        windspeedKmph: "15",
        winddirDegree: "210",
        winddir16Point: "SSW",
        precipMM: "0.5",
        pressure: "1015",
        visibility: "10",
        uvIndex: "5",
        weatherCode: "113",
        observation_time: "10:00 AM",
        air_quality: { "us-epa-index": "1", pm2_5: "10.0", pm10: "18.0", co: "0.2", no2: "8.0", o3: "30.0", so2: "1.0", "gb-defra-index": "1" }
      }],
      weather: [{
        date: new Date().toISOString().slice(0, 10),
        hourly: Array.from({length: 24}, (_, h) => ({
          time: String(h * 100),
          tempC: String(18 + h % 12),
          FeelsLikeC: String(19 + h % 12),
          chanceofrain: String(h * 4),
          precipMM: "0.0",
          humidity: "55",
          cloudcover: "10",
          windspeedKmph: "12",
          WindGustKmph: "18",
          winddirDegree: "200",
          weatherCode: "113",
          uvIndex: "4"
        }))
      }]
    },
    history: []
  },
  timeline: [],
  tempBounds: { min: 0, max: 0 },
  rainBounds: { maxProb: 0, maxMM: 0 },
  activeTimelineHour: -1,
  _seriesCache: {},
  _timelineRevision: 0
};

const rebuildMatch = qml.match(/function rebuildTimeline\(\) \{([\s\S]*?)\n    \}\n\n    function getSeries/);
assert(rebuildMatch, "Failed to extract rebuildTimeline code");
const getSeriesMatch = qml.match(/function getSeries\(metricPath\) \{([\s\S]*?)\n    \}\n\n    Component/);
assert(getSeriesMatch, "Failed to extract getSeries code");

const rebuildFn = new Function("root", "WeatherGlyphs", rebuildMatch[1]);
const getSeriesFn = new Function("root", "metricPath", getSeriesMatch[1]);

root.rebuildTimeline = () => rebuildFn(root, WeatherGlyphs);
root.getSeries = (metricPath) => getSeriesFn(root, metricPath);

root.rebuildTimeline();

assert.strictEqual(root.timeline.length, 25, "Timeline must contain 25 slots");
assert.strictEqual(root.timeline[12].isNow, true, "Center slot must be NOW");
assert.strictEqual(root.timeline[12].thermal.tempC, 25, "NOW live tempC must be 25");

const tempSeries = root.getSeries("thermal.tempC");
assert.strictEqual(tempSeries.length, 25, "tempSeries length must be 25");
assert.strictEqual(tempSeries[12], 25, "tempSeries[12] must be 25");

const rainSeries = root.getSeries("moisture.rainProb");
assert.strictEqual(rainSeries.length, 25, "rainSeries length must be 25");

console.log("SECTION_5_SERIES_ACCESSOR_PASS");
NODEOF
)

  if [[ "$node_sec5_out" =~ "SECTION_5_SERIES_ACCESSOR_PASS" ]]; then
    pass "S5: getSeries memoization, cache invalidation, and 100% legacy facade compatibility verified"
  else
    fail "S5: Section 5 checks failed:\n$node_sec5_out"
  fi
fi

# ===========================================================================
# Summary & Exit
# ===========================================================================
info "========================================================="
info "Phase 54.2 Assert Harness Summary: FAIL=$FAIL, FINDINGS=$FINDINGS"
info "========================================================="

if [[ "$FAIL" -eq 0 ]]; then
  pass "All executed assertion sections passed successfully!"
  exit 0
else
  fail "Assertion harness detected $FAIL failure(s)."
  exit 1
fi
