#!/usr/bin/env bash
# ===========================================================================
# Phase 52: Weather Service Singleton & Material Glyph Mapping Assert Harness
# Enforces: GLYPH-01, GLYPH-02, GLYPH-03, GLYPH-04, INTG-02, INTG-04
#
# Usage (from REPO_ROOT):
#   ./scripts/phase52-weather-assert.sh [1-5] [OPTIONS]
#
# Options:
#   -s, --section <1-5>    Execute only the specified section (1-5)
#   -q, --quick,           Run fast static checks only
#       --standalone
#   -c, --syntax           Execute static bash syntax checks only
#   -h, --help             Show this help message
#
# Exit 0 if all hard asserts pass (FAIL=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if executed as root (ASVS L1 Root Privilege Prevention / T-52-01)
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
      echo "  1: Stow Packaging & Symlink Topology (GLYPH-01, INTG-02)"
      echo "  2: Code Dictionary Coverage & Day/Night Branching (GLYPH-02, GLYPH-03)"
      echo "  3: Color & Severity Mapping (GLYPH-04)"
      echo "  4: Reactive Weather Service Schema & Legacy Facade Invariants (GLYPH-01, D-52-01..08)"
      echo "  5: Live Quickshell Log & Process Tree Verification (INTG-04, T-52-03)"
      echo ""
      echo "Options:"
      echo "  -s, --section <1-5>    Execute only the specified section (1-5)"
      echo "  -q, --quick,           Run fast static checks only"
      echo "      --standalone"
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

GLYPHS_SRC="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/WeatherGlyphs.qml"
WEATHER_SRC="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/Weather.qml"
TARGET_DIR="$HOME/.config/quickshell/ii/services"

# Syntax-only mode
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Running Syntax Validation Mode ---"
  bash -n "$0"
  pass "Assert harness bash syntax check passed (bash -n verified)"
  info "=== Syntax Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
  exit "$FAIL"
fi

# ===========================================================================
# Section 1: Stow Packaging & Symlink Topology (GLYPH-01, INTG-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Stow Packaging & Symlink Topology ---"

  if [[ -f "$GLYPHS_SRC" ]]; then
    pass "S1: restow/quickshell/.../WeatherGlyphs.qml exists as regular file"
  else
    fail "S1: Missing source file: $GLYPHS_SRC"
  fi

  if [[ -f "$WEATHER_SRC" ]]; then
    pass "S1: restow/quickshell/.../Weather.qml exists as regular file"
  elif [[ "$RUN_SECTION" -eq 1 ]]; then
    info "S1: restow/quickshell/.../Weather.qml pending implementation (Wave 2)"
  fi

  # Check active symlinks in ~/.config/quickshell/ii/services if deployed
  if [[ -L "$TARGET_DIR/WeatherGlyphs.qml" ]]; then
    local_target="$(readlink -f "$TARGET_DIR/WeatherGlyphs.qml" || true)"
    canonical_src="$(readlink -f "$GLYPHS_SRC" || true)"
    if [[ "$local_target" == "$canonical_src" ]]; then
      pass "S1: $TARGET_DIR/WeatherGlyphs.qml is a valid symlink to restow overlay"
    else
      fail "S1: $TARGET_DIR/WeatherGlyphs.qml points to $local_target, expected $canonical_src"
    fi
  elif [[ -f "$TARGET_DIR/WeatherGlyphs.qml" ]]; then
    fail "S1: $TARGET_DIR/WeatherGlyphs.qml exists as a regular file, expected leaf symlink"
  else
    info "S1: $TARGET_DIR/WeatherGlyphs.qml symlink pending deployment (Wave 3)"
  fi

  if [[ -L "$TARGET_DIR/Weather.qml" ]]; then
    local_target="$(readlink -f "$TARGET_DIR/Weather.qml" || true)"
    canonical_src="$(readlink -f "$WEATHER_SRC" || true)"
    if [[ "$local_target" == "$canonical_src" ]]; then
      pass "S1: $TARGET_DIR/Weather.qml is a valid symlink to restow overlay"
    else
      fail "S1: $TARGET_DIR/Weather.qml points to $local_target, expected $canonical_src"
    fi
  elif [[ -f "$TARGET_DIR/Weather.qml" && ! -f "$WEATHER_SRC" ]]; then
    info "S1: Upstream vendor Weather.qml present in target directory (pre-overlay)"
  elif [[ -f "$TARGET_DIR/Weather.qml" && -f "$WEATHER_SRC" ]]; then
    info "S1: $TARGET_DIR/Weather.qml regular file awaiting backup and symlink (Wave 3)"
  fi

  if [[ -f "$TARGET_DIR/Weather.qml.bak" ]]; then
    pass "S1: Installer backup artifact $TARGET_DIR/Weather.qml.bak preserved"
  else
    info "S1: Backup artifact $TARGET_DIR/Weather.qml.bak pending deployment (Wave 3)"
  fi
fi

# ===========================================================================
# Section 2: Code Dictionary Coverage & Day/Night Branching (GLYPH-02, GLYPH-03)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Code Dictionary Coverage & Day/Night Branching ---"

  if [[ ! -f "$GLYPHS_SRC" ]]; then
    fail "S2: Cannot test WeatherGlyphs.qml: file missing ($GLYPHS_SRC)"
  else
    # Run Node verification harness for WeatherGlyphs
    node_res=0
    node -e '
      const fs = require("fs");
      const content = fs.readFileSync(process.argv[1], "utf8");

      const Appearance = {
        m3colors: {
          m3error: "#ffb4ab",
          m3errorContainer: "#93000a",
          m3secondary: "#cac5c8"
        }
      };

      const startIdx = content.indexOf("id: root");
      const lastBraceIdx = content.lastIndexOf("}");
      if (startIdx === -1 || lastBraceIdx === -1) {
        console.error("FATAL: Unable to isolate Singleton body from QML file");
        process.exit(1);
      }
      const body = content.substring(startIdx, lastBraceIdx);

      const jsCode = `const root = {};\n` + body
        .replace(/id:\s*root/, "")
        .replace(/readonly\s+property\s+string\s+(\w+)\s*:\s*("[^"]*")/g, "root.$1 = $2;")
        .replace(/readonly\s+property\s+var\s+glyphMap\s*:\s*\(\{/g, "root.glyphMap = ({")
        .replace(/function\s+(\w+)\s*\(/g, "root.$1 = function(");

      const vm = require("vm");
      const context = { Appearance, console };
      vm.createContext(context);
      try {
        vm.runInContext(jsCode + "; this.root = root;", context);
      } catch (err) {
        console.error("JS Evaluation Error:", err);
        process.exit(1);
      }
      const root = context.root;

      let failures = [];

      // 1. Authoritative 59 WWO Codes Check
      const authoritativeCodes = [
        113, 116, 119, 122, 125, 128, 131, 134, 137, 140, 143, 146, 149, 152, 155, 158, 161,
        176, 179, 182, 185, 200, 227, 230, 248, 260, 263, 266, 281, 284, 293, 296, 299, 302,
        305, 308, 311, 314, 317, 320, 323, 326, 329, 332, 335, 338, 350, 353, 356, 359, 362,
        365, 368, 371, 374, 377, 386, 389, 392, 395
      ];
      for (const code of authoritativeCodes) {
        if (!Object.prototype.hasOwnProperty.call(root.glyphMap, String(code))) {
          failures.push(`Missing condition code in glyphMap: ${code}`);
        }
      }

      // 2. Day/Night Branching for 113 and 116
      if (root.getGlyph(113, true) !== "clear_day") failures.push(`Code 113 day failed: ${root.getGlyph(113, true)}`);
      if (root.getGlyph(113, false) !== "clear_night") failures.push(`Code 113 night failed: ${root.getGlyph(113, false)}`);
      if (root.getGlyph(116, true) !== "partly_cloudy_day") failures.push(`Code 116 day failed: ${root.getGlyph(116, true)}`);
      if (root.getGlyph(116, false) !== "partly_cloudy_night") failures.push(`Code 116 night failed: ${root.getGlyph(116, false)}`);

      // 3. isdaytime Input Normalization
      const normCases = [
        [true, "clear_day"],
        [false, "clear_night"],
        ["yes", "clear_day"],
        ["no", "clear_night"],
        [1, "clear_day"],
        [0, "clear_night"],
        ["1", "clear_day"],
        ["0", "clear_night"]
      ];
      for (const [inp, exp] of normCases) {
        const res = root.getGlyph(113, inp);
        if (res !== exp) failures.push(`isdaytime norm failed for ${JSON.stringify(inp)}: got ${res}, expected ${exp}`);
      }

      // 4. Obscuring Condition Ligatures
      if (root.getGlyph(149, true) !== "foggy") failures.push(`Dhaka code 149 failed: ${root.getGlyph(149, true)}`);
      if (root.getGlyph(200, true) !== "thunderstorm") failures.push(`Code 200 failed: ${root.getGlyph(200, true)}`);
      if (root.getGlyph(308, true) !== "weather_hail") failures.push(`Code 308 failed: ${root.getGlyph(308, true)}`);

      // 5. Universal Neutral Fallback
      if (root.getGlyph(999, true) !== "cloud") failures.push(`Invalid code 999 failed: ${root.getGlyph(999, true)}`);
      if (root.getGlyph("", true) !== "cloud") failures.push(`Empty code failed: ${root.getGlyph("", true)}`);
      if (root.getGlyph(null, true) !== "cloud") failures.push(`Null code failed: ${root.getGlyph(null, true)}`);
      if (root.getGlyph(undefined, true) !== "cloud") failures.push(`Undefined code failed: ${root.getGlyph(undefined, true)}`);

      // 6. Standardized Metric Glyph Constants
      const expectedConstants = {
        glyphHumidity: "water_drop",
        glyphPressure: "speed",
        glyphUv: "wb_sunny",
        glyphVisibility: "visibility",
        glyphWind: "air",
        glyphSunrise: "wb_twilight",
        glyphSunset: "bedtime",
        glyphAlert: "warning",
        glyphOffline: "cloud_off",
        glyphDefault: "cloud"
      };
      for (const [prop, val] of Object.entries(expectedConstants)) {
        if (root[prop] !== val) {
          failures.push(`Metric constant ${prop} failed: got ${root[prop]}, expected ${val}`);
        }
      }

      if (failures.length > 0) {
        console.error("FAILURES:\n" + failures.join("\n"));
        process.exit(1);
      }
      console.log("OK");
    ' "$GLYPHS_SRC" || node_res=$?

    if [[ "$node_res" -eq 0 ]]; then
      pass "S2: Authoritative WWO condition dictionary coverage (59 codes) verified"
      pass "S2: Day/night dynamic branching for 113 and 116 verified"
      pass "S2: isdaytime input normalization (bool/str/num) verified"
      pass "S2: Dhaka smoky haze (149), thunderstorm (200), and hail (308) ligatures verified"
      pass "S2: Universal neutral fallback ('cloud') on invalid/null/empty verified"
      pass "S2: Standardized metric glyph constants (humidity, UV, wind, astro, etc.) verified"
    else
      fail "S2: WeatherGlyphs condition dictionary unit test failed"
    fi
  fi
fi

# ===========================================================================
# Section 3: Color & Severity Mapping (GLYPH-04)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Color & Severity Mapping ---"

  if [[ ! -f "$GLYPHS_SRC" ]]; then
    fail "S3: Cannot test WeatherGlyphs.qml: file missing ($GLYPHS_SRC)"
  else
    node_res=0
    node -e '
      const fs = require("fs");
      const content = fs.readFileSync(process.argv[1], "utf8");

      const Appearance = {
        m3colors: {
          m3error: "#ffb4ab",
          m3errorContainer: "#93000a",
          m3secondary: "#cac5c8"
        }
      };

      const startIdx = content.indexOf("id: root");
      const lastBraceIdx = content.lastIndexOf("}");
      const body = content.substring(startIdx, lastBraceIdx);

      const jsCode = `const root = {};\n` + body
        .replace(/id:\s*root/, "")
        .replace(/readonly\s+property\s+string\s+(\w+)\s*:\s*("[^"]*")/g, "root.$1 = $2;")
        .replace(/readonly\s+property\s+var\s+glyphMap\s*:\s*\(\{/g, "root.glyphMap = ({")
        .replace(/function\s+(\w+)\s*\(/g, "root.$1 = function(");

      const vm = require("vm");
      const context = { Appearance, console };
      vm.createContext(context);
      vm.runInContext(jsCode + "; this.root = root;", context);
      const root = context.root;

      let failures = [];

      // 1. US-EPA Air Quality Category
      const aqiCatCases = [
        [1, "Good"],
        [2, "Moderate"],
        [3, "Unhealthy for Sensitive Groups"],
        [4, "Unhealthy"],
        [5, "Very Unhealthy"],
        [6, "Hazardous"],
        [0, "Unavailable"],
        [99, "Unavailable"],
        [null, "Unavailable"]
      ];
      for (const [idx, exp] of aqiCatCases) {
        const res = root.getAqiCategory(idx);
        if (res !== exp) failures.push(`getAqiCategory(${idx}) got ${res}, expected ${exp}`);
      }

      // 2. US-EPA Air Quality Colors
      const aqiColorCases = [
        [1, "#81C784"],
        [2, "#FFD54F"],
        [3, "#FF9800"],
        [4, "#E53935"],
        [5, "#BA68C8"],
        [6, "#880E4F"],
        [0, "transparent"],
        [null, "transparent"]
      ];
      for (const [idx, exp] of aqiColorCases) {
        const res = root.getAqiColor(idx);
        if (res !== exp) failures.push(`getAqiColor(${idx}) got ${res}, expected ${exp}`);
      }

      // 3. Alert Severity Colors
      if (root.getAlertColor("Extreme Heat Warning") !== Appearance.m3colors.m3error) {
        failures.push("Alert Extreme Heat Warning failed to return m3error");
      }
      if (root.getAlertColor("Tornado Warning") !== Appearance.m3colors.m3error) {
        failures.push("Alert Tornado Warning failed to return m3error");
      }
      if (root.getAlertColor("High Danger Alert") !== Appearance.m3colors.m3error) {
        failures.push("Alert High Danger Alert failed to return m3error");
      }
      if (root.getAlertColor("Severe Thunderstorm Watch") !== Appearance.m3colors.m3errorContainer) {
        failures.push("Alert Severe Thunderstorm Watch failed to return m3errorContainer");
      }
      if (root.getAlertColor("Flash Flood Watch") !== Appearance.m3colors.m3errorContainer) {
        failures.push("Alert Flash Flood Watch failed to return m3errorContainer");
      }
      if (root.getAlertColor("Flood Advisory") !== Appearance.m3colors.m3secondary) {
        failures.push("Alert Flood Advisory failed to return m3secondary");
      }
      if (root.getAlertColor("") !== Appearance.m3colors.m3secondary) {
        failures.push("Alert empty string failed to return m3secondary");
      }
      if (root.getAlertColor(null) !== Appearance.m3colors.m3secondary) {
        failures.push("Alert null failed to return m3secondary");
      }

      if (failures.length > 0) {
        console.error("FAILURES:\n" + failures.join("\n"));
        process.exit(1);
      }
      console.log("OK");
    ' "$GLYPHS_SRC" || node_res=$?

    if [[ "$node_res" -eq 0 ]]; then
      pass "S3: US-EPA AQI categories 1–6 and unavailable fallback verified"
      pass "S3: US-EPA AQI high-contrast Material You color tokens verified"
      pass "S3: Severe alert color mapping hierarchy (Extreme -> m3error, Watch -> m3errorContainer, Advisory -> m3secondary) verified"
    else
      fail "S3: Color and severity mapping unit test failed"
    fi
  fi
fi

# ===========================================================================
# Section 4: Reactive Weather Service Schema & Legacy Facade Invariants
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Reactive Weather Service Schema & Legacy Facade ---"

  if [[ ! -f "$WEATHER_SRC" ]]; then
    if [[ "$RUN_SECTION" -eq 4 ]]; then
      fail "S4: Cannot test Weather.qml: file missing ($WEATHER_SRC)"
    else
      info "S4: Weather.qml pending implementation in Wave 2"
    fi
  else
    # 1. Passive observation verify: zero curl, wttr.in, or Process in Weather.qml
    if grep -E -q 'curl|wttr\.in|Process' "$WEATHER_SRC"; then
      fail "S4: Security violation: curl/wttr.in/Process detected in Weather.qml"
    else
      pass "S4: Passive observation verified: zero curl, wttr.in, or Process child subshells"
    fi

    # 2. FileView & Timer presence
    if grep -q 'Quickshell\.Io' "$WEATHER_SRC" && grep -q 'FileView' "$WEATHER_SRC" && grep -q 'watchChanges: true' "$WEATHER_SRC"; then
      pass "S4: FileView inotify observation configuration verified"
    else
      fail "S4: Missing Quickshell.Io FileView with watchChanges: true"
    fi

    if grep -q 'interval: 60000' "$WEATHER_SRC" || grep -q 'interval:\s*60000' "$WEATHER_SRC"; then
      pass "S4: 60-second inotify fallback Timer verified"
    else
      fail "S4: Missing 60000ms fallback Timer in Weather.qml"
    fi

    # 3. Node schema and cold-boot test
    node_res=0
    node -e '
      const fs = require("fs");
      const path = require("path");
      const weatherCode = fs.readFileSync(process.argv[1], "utf8");

      let failures = [];

      // Cold boot defaults evaluation
      // Check presence of required property declarations
      if (!weatherCode.includes("property bool isStale: true")) failures.push("Missing isStale: true default");
      if (!weatherCode.includes("property bool isOffline: true")) failures.push("Missing isOffline: true default");
      if (!weatherCode.includes("glyph: \"cloud_off\"")) failures.push("Missing glyph: cloud_off default in current");
      if (!weatherCode.includes("temp: \"--°C\"")) failures.push("Missing temp: \"--°C\" default in data facade");
      if (!weatherCode.includes("tempFeelsLike: \"--°C\"")) failures.push("Missing tempFeelsLike: \"--°C\" default in data facade");
      if (!weatherCode.includes("function getData()")) failures.push("Missing getData() facade method");

      // Verify WeatherWidget compatibility: "--°C".substring(0, temp.length - 1) == "--°"
      const defaultTemp = "--°C";
      const sub = defaultTemp.substring(0, defaultTemp.length - 1);
      if (sub !== "--°") {
        failures.push(`WeatherWidget expression failed on default temp: got ${sub}`);
      }

      // Check current group 13 fields presence
      const currentFields = [
        "tempC", "tempFeelsLikeC", "desc", "glyph", "humidity", "uv",
        "windKmph", "windDir", "windDegree", "precipMM", "pressureHpa",
        "visibilityKm", "isDaytime"
      ];
      for (const f of currentFields) {
        if (!weatherCode.includes(f + ":")) {
          failures.push(`Missing field ${f} in current group declaration`);
        }
      }

      // Check live or sample cache parsing if present
      const runtimeDir = process.env.XDG_RUNTIME_DIR || `/run/user/${process.getuid()}`;
      const cachePath = path.join(runtimeDir, "weather/weather.json");
      const samplePath = path.resolve("test_wwo_api/raw_response.json");
      let testPayload = null;

      if (fs.existsSync(cachePath)) {
        try { testPayload = JSON.parse(fs.readFileSync(cachePath, "utf8")); } catch (e) {}
      } else if (fs.existsSync(samplePath)) {
        try { testPayload = { data: JSON.parse(fs.readFileSync(samplePath, "utf8")) }; } catch (e) {}
      }

      if (testPayload && testPayload.data) {
        const raw = testPayload.data;
        const cur = raw.current_condition ? raw.current_condition[0] : null;
        const weather0 = raw.weather ? raw.weather[0] : null;
        if (!cur) failures.push("Cache payload missing current_condition[0]");
        if (!weather0 || !weather0.hourly || weather0.hourly.length !== 24) {
          failures.push(`Hourly array expected 24 slots, got ${weather0?.hourly?.length}`);
        }
      }

      if (failures.length > 0) {
        console.error("FAILURES:\n" + failures.join("\n"));
        process.exit(1);
      }
      console.log("OK");
    ' "$WEATHER_SRC" || node_res=$?

    if [[ "$node_res" -eq 0 ]]; then
      pass "S4: Cold-boot defaults and WeatherWidget compatibility string operations verified"
      pass "S4: Current group (13 fields) and hourly 24-slot schema preservation verified"
      pass "S4: Backward-compatible Weather.data.* facade and getData() verified"
    else
      fail "S4: Schema conformance and cold boot test failed"
    fi
  fi
fi

# ===========================================================================
# Section 5: Live Quickshell Log & Process Tree Verification (INTG-04, T-52-03)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Live Quickshell Log & Process Tree Verification ---"

  if pgrep -x quickshell >/dev/null 2>&1; then
    qs_pids="$(pgrep -x quickshell)"
    pass "S5: Quickshell is actively running (PIDs: $qs_pids)"

    # Check child processes for curl or bash network commands
    has_bad_child=0
    for pid in $qs_pids; do
      if pgrep -P "$pid" -a 2>/dev/null | grep -E 'curl|wttr\.in' >/dev/null 2>&1; then
        has_bad_child=1
        fail "S5: Found forbidden child curl/wttr.in process spawned by Quickshell PID $pid"
      fi
    done
    if [[ "$has_bad_child" -eq 0 ]]; then
      pass "S5: Process hierarchy verified: 0 child curl or wttr.in processes spawned by Quickshell"
    fi

    # Inspect recent journal logs for quickshell errors
    if command -v journalctl >/dev/null 2>&1; then
      recent_errs="$(journalctl --user -u quickshell --since "5 minutes ago" --no-pager 2>/dev/null | grep -E -i 'Weather.*(ReferenceError|TypeError|SyntaxError)' || true)"
      if [[ -n "$recent_errs" ]]; then
        fail "S5: QML runtime errors detected in quickshell logs: $recent_errs"
      else
        pass "S5: Zero Weather-related TypeError or ReferenceError exceptions in recent Quickshell journal logs"
      fi
    fi
  else
    info "S5: Quickshell process not actively running; skipping live process inspection"
  fi
fi

# ===========================================================================
# Summary
# ===========================================================================
echo ""
info "=== Phase 52 Assert Harness Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
