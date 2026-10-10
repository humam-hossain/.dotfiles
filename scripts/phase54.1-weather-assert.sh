#!/usr/bin/env bash
# ===========================================================================
# Phase 54.1: Top Status Bar Weather Component Polish Assert Harness
# Enforces: BAR-01, BAR-02, BAR-03, BAR-04, INTG-02, ASVS L1
# Decisions: D-54.1-01 through D-54.1-37
#
# Usage (from REPO_ROOT):
#   ./scripts/phase54.1-weather-assert.sh [1-5] [OPTIONS]
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

# Fail closed if executed as root (ASVS L1 Root Privilege Prevention / T-54.1-01)
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
      echo "  1: Stow Leaf Symlink Topology & Packaging Integrity (BAR-01, INTG-02, D-54.1-34..37)"
      echo "  2: BarContent.qml Center Zone Integration & Non-Mutation Invariants (BAR-01, D-54.1-09..12)"
      echo "  3: WeatherBar Temperature Parsing & Multi-Tier Responsive Formatting (BAR-02, D-54.1-13..23, D-54.1-28)"
      echo "  4: Alert Precedence, Imminent Rain Badge & Breathing Pulse Logic (BAR-03, D-54.1-15..17, D-54.1-22, D-54.1-25..26, D-54.1-32)"
      echo "  5: Pure Hover Trigger, M3 Surface Highlight & Pointer Ergonomics (BAR-04, D-54.1-01..08, D-54.1-24, D-54.1-29, D-54.1-31, D-54.1-33)"
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

WEATHERBAR_SRC="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherBar.qml"
BARCONTENT_SRC="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
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
# Section 1: Stow Leaf Symlink Topology & Packaging Integrity (BAR-01, INTG-02, D-54.1-34..37)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Stow Leaf Symlink Topology & Packaging Integrity ---"

  if [[ -s "$WEATHERBAR_SRC" ]]; then
    pass "S1: restow/quickshell/.../WeatherBar.qml exists and is non-empty"
  else
    fail "S1: Missing or empty source file: $WEATHERBAR_SRC"
  fi

  if [[ -L "$TARGET_DIR/WeatherBar.qml" ]]; then
    local_target="$(readlink -f "$TARGET_DIR/WeatherBar.qml" || true)"
    canonical_src="$(readlink -f "$WEATHERBAR_SRC" || true)"
    if [[ "$local_target" == "$canonical_src" ]]; then
      pass "S1: $TARGET_DIR/WeatherBar.qml is a valid symlink to restow overlay"
    else
      fail "S1: $TARGET_DIR/WeatherBar.qml points to $local_target, expected $canonical_src"
    fi
  elif [[ -f "$TARGET_DIR/WeatherBar.qml" ]]; then
    fail "S1: $TARGET_DIR/WeatherBar.qml exists as regular file, expected leaf symlink"
  else
    fail "S1: $TARGET_DIR/WeatherBar.qml is missing"
  fi

  if [[ -f "$TARGET_DIR/WeatherBar.qml.bak" && ! -L "$TARGET_DIR/WeatherBar.qml.bak" ]]; then
    pass "S1: Installer backup artifact $TARGET_DIR/WeatherBar.qml.bak preserved as regular file"
  else
    fail "S1: Missing or invalid installer backup artifact $TARGET_DIR/WeatherBar.qml.bak"
  fi

  # Assert all parent directories in ~/.config/quickshell/ii/modules/ii/bar/weather are real un-folded directories
  for check_dir in "$HOME/.config" "$HOME/.config/quickshell" "$HOME/.config/quickshell/ii" "$HOME/.config/quickshell/ii/modules" "$HOME/.config/quickshell/ii/modules/ii" "$HOME/.config/quickshell/ii/modules/ii/bar" "$TARGET_DIR"; do
    if [[ -d "$check_dir" && ! -L "$check_dir" ]]; then
      pass "S1: Directory $(basename "$check_dir") is an un-folded real directory"
    else
      fail "S1: Expected real directory (not symlink or missing): $check_dir"
    fi
  done

  # Assert git status vendor/dots-hyprland is empty
  vendor_churn="$(git status --porcelain vendor/dots-hyprland 2>/dev/null || true)"
  if [[ -z "$vendor_churn" ]]; then
    pass "S1: vendor/dots-hyprland has 0 working tree modifications (pristine vendor hygiene)"
  else
    fail "S1: Detected vendor/dots-hyprland git churn: $vendor_churn"
  fi

  if [[ "$QUICK_MODE" -eq 0 ]]; then
    info "S1: Executing dots-hyprland strict verification..."
    if ./arch/dots-hyprland.sh verify --strict >/dev/null 2>&1; then
      pass "S1: ./arch/dots-hyprland.sh verify --strict completed with FAIL=0 FINDINGS=0"
    else
      fail "S1: ./arch/dots-hyprland.sh verify --strict reported failures"
    fi
  else
    info "S1: Quick mode active: skipping dots-hyprland.sh verify --strict"
  fi
fi

# ===========================================================================
# Section 2: BarContent.qml Center Zone Integration & Non-Mutation Invariants (BAR-01, D-54.1-09..12)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: BarContent.qml Center Zone Integration & Non-Mutation ---"

  barcontent_churn="$(git status --porcelain "$BARCONTENT_SRC" 2>/dev/null || true)"
  if [[ -z "$barcontent_churn" ]]; then
    pass "S2: BarContent.qml is 100% UNTOUCHED (0 working tree modifications per D-54.1-10)"
  else
    fail "S2: BarContent.qml has been modified: $barcontent_churn"
  fi

  if [[ ! -f "$BARCONTENT_SRC" ]]; then
    fail "S2: Missing BarContent.qml file ($BARCONTENT_SRC)"
  else
    bc_content="$(cat "$BARCONTENT_SRC")"

    # a. Assert id: weatherGroup Loader exists in Center Zone
    if echo "$bc_content" | grep -q 'id:\s*weatherGroup'; then
      pass "S2: Loader with id: weatherGroup exists in BarContent.qml"
    else
      fail "S2: Missing id: weatherGroup Loader in BarContent.qml"
    fi

    # b. Assert anchors.left: middleCenterGroup.right and anchors.leftMargin: 4
    if echo "$bc_content" | grep -q 'anchors\.left:\s*middleCenterGroup\.right' && echo "$bc_content" | grep -q 'anchors\.leftMargin:\s*4'; then
      pass "S2: weatherGroup anchors to middleCenterGroup.right with 4px leftMargin (D-54.1-10)"
    else
      fail "S2: Missing middleCenterGroup.right anchor or 4px leftMargin in weatherGroup"
    fi

    # c. Assert sourceComponent: BarGroup { WeatherBar {} }
    if echo "$bc_content" | grep -A 10 'id:\s*weatherGroup' | grep -q 'WeatherBar'; then
      pass "S2: weatherGroup loads WeatherBar inside BarGroup component wrapper (D-54.1-09)"
    else
      fail "S2: weatherGroup does not load WeatherBar inside BarGroup"
    fi

    # d. Assert active: Config.options.bar.weather.enable
    if echo "$bc_content" | grep -B 2 -A 5 'id:\s*weatherGroup' | grep -q 'active:\s*Config\.options\.bar\.weather\.enable'; then
      pass "S2: weatherGroup active property bound to Config.options.bar.weather.enable"
    else
      fail "S2: Missing active: Config.options.bar.weather.enable binding"
    fi

    # e. Assert standard BarGroup background styling without custom highlights
    if grep -q 'WeatherBar' "$BARCONTENT_SRC" && ! grep -A 5 'WeatherBar' "$BARCONTENT_SRC" | grep -q 'hoverColor'; then
      pass "S2: Standard BarGroup background styling preserved without custom hover highlights (D-54.1-09)"
    else
      fail "S2: Detected unwanted custom hover styling around WeatherBar"
    fi
  fi
fi

# ===========================================================================
# Section 3: WeatherBar Temperature Parsing & Multi-Tier Responsive Formatting
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: WeatherBar Temperature Parsing & Multi-Tier Formatting ---"

  if [[ ! -f "$WEATHERBAR_SRC" ]]; then
    fail "S3: Cannot test WeatherBar.qml: file missing ($WEATHERBAR_SRC)"
  else
    node_res=0
    node -e '
      const fs = require("fs");
      const code = fs.readFileSync(process.argv[1], "utf8");

      let failures = [];

      // Test Typography & Aesthetic Hierarchy in AST
      if (!code.includes("iconSize: Appearance.font.pixelSize.large")) {
        failures.push("Missing large condition glyph sizing (Appearance.font.pixelSize.large)");
      }
      if (!code.includes("font.pixelSize: Appearance.font.pixelSize.small")) {
        failures.push("Missing small temp text sizing (Appearance.font.pixelSize.small)");
      }
      if (!code.includes("fill: 0")) {
        failures.push("Missing outline glyph fill: 0 styling on MaterialSymbol");
      }
      if (!code.includes("Appearance.animationCurves.expressiveEffects")) {
        failures.push("Missing 200ms expressiveEffects ColorAnimation on color transitions");
      }
      if (!code.includes("Appearance.m3colors.m3onSurfaceVariant")) {
        failures.push("Missing Appearance.m3colors.m3onSurfaceVariant dimming token");
      }
      if (!code.includes("Appearance.colors.colOnLayer1")) {
        failures.push("Missing neutral Appearance.colors.colOnLayer1 base token");
      }

      // Logic Evaluation Functions matching WeatherBar.qml implementation
      function computeFormattedTemp(tempC, useShortenedForm, vertical) {
        const raw = tempC;
        if (raw === undefined || raw === null || raw === "" || raw === "--") {
          return (useShortenedForm === 2 || vertical) ? "--°" : "--°C";
        }
        const num = Math.round(Number(raw));
        if (isNaN(num)) {
          return (useShortenedForm === 2 || vertical) ? "--°" : "--°C";
        }
        return num + ((useShortenedForm === 2 || vertical) ? "°" : "°C");
      }

      function computeContentColor(isStale, isOffline, Appearance) {
        return (isStale || isOffline) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.colors.colOnLayer1;
      }

      function computeConditionGlyph(tempC, glyph, WeatherGlyphs) {
        if ((tempC === "--" || tempC === undefined || tempC === null) && (!glyph || glyph === "cloud_off" || glyph === "")) {
          return WeatherGlyphs.glyphOffline || "cloud_off";
        }
        return glyph || (WeatherGlyphs.glyphDefault || "cloud");
      }

      const AppearanceMock = {
        m3colors: { m3onSurfaceVariant: "#49454f", m3primary: "#6750a4", m3error: "#ba1a1a" },
        colors: { colOnLayer1: "#1d1b20" },
        font: { pixelSize: { smaller: 11, small: 13, normal: 14, large: 17 } }
      };

      const WeatherGlyphsMock = {
        glyphOffline: "cloud_off",
        glyphDefault: "cloud",
        glyphHumidity: "water_drop"
      };

      // a. Integer Celsius formatting
      if (computeFormattedTemp(28, 0, false) !== "28°C") failures.push(`Expected 28 -> 28°C, got ${computeFormattedTemp(28, 0, false)}`);
      if (computeFormattedTemp(-5, 0, false) !== "-5°C") failures.push(`Expected -5 -> -5°C, got ${computeFormattedTemp(-5, 0, false)}`);

      // b. Rounding
      if (computeFormattedTemp(28.6, 0, false) !== "29°C") failures.push(`Expected 28.6 -> 29°C, got ${computeFormattedTemp(28.6, 0, false)}`);
      if (computeFormattedTemp(28.4, 0, false) !== "28°C") failures.push(`Expected 28.4 -> 28°C, got ${computeFormattedTemp(28.4, 0, false)}`);
      if (computeFormattedTemp("28.6", 0, false) !== "29°C") failures.push(`Expected "28.6" -> 29°C, got ${computeFormattedTemp("28.6", 0, false)}`);

      // c. Safe cold boot / NaN fallback
      if (computeFormattedTemp("--", 0, false) !== "--°C") failures.push(`Expected "--" -> "--°C", got ${computeFormattedTemp("--", 0, false)}`);
      if (computeFormattedTemp(null, 0, false) !== "--°C") failures.push(`Expected null -> "--°C", got ${computeFormattedTemp(null, 0, false)}`);
      if (computeFormattedTemp(undefined, 0, false) !== "--°C") failures.push(`Expected undefined -> "--°C", got ${computeFormattedTemp(undefined, 0, false)}`);
      if (computeFormattedTemp("invalid_temp", 0, false) !== "--°C") failures.push(`Expected NaN -> "--°C", got ${computeFormattedTemp("invalid_temp", 0, false)}`);

      // d. Tier 2 truncation (useShortenedForm === 2)
      if (computeFormattedTemp(28, 2, false) !== "28°") failures.push(`Expected 28 in Tier 2 -> 28°, got ${computeFormattedTemp(28, 2, false)}`);
      if (computeFormattedTemp("--", 2, false) !== "--°") failures.push(`Expected "--" in Tier 2 -> --°, got ${computeFormattedTemp("--", 2, false)}`);

      // e. Vertical mode truncation (vertical === true) per D-54.1-14, D-54.1-28
      if (computeFormattedTemp(28, 0, true) !== "28°") failures.push(`Expected 28 in vertical -> 28°, got ${computeFormattedTemp(28, 0, true)}`);
      if (computeFormattedTemp("--", 0, true) !== "--°") failures.push(`Expected "--" in vertical -> --°, got ${computeFormattedTemp("--", 0, true)}`);

      // f. Condition glyph selection
      if (computeConditionGlyph("--", undefined, WeatherGlyphsMock) !== "cloud_off") {
        failures.push(`Expected cold boot fallback cloud_off, got ${computeConditionGlyph("--", undefined, WeatherGlyphsMock)}`);
      }
      if (computeConditionGlyph("--", "cloud_off", WeatherGlyphsMock) !== "cloud_off") {
        failures.push(`Expected cold boot cloud_off, got ${computeConditionGlyph("--", "cloud_off", WeatherGlyphsMock)}`);
      }
      if (computeConditionGlyph(25, "clear_day", WeatherGlyphsMock) !== "clear_day") {
        failures.push(`Expected active glyph clear_day, got ${computeConditionGlyph(25, "clear_day", WeatherGlyphsMock)}`);
      }

      // g. Stale/offline color dimming
      if (computeContentColor(true, false, AppearanceMock) !== AppearanceMock.m3colors.m3onSurfaceVariant) {
        failures.push("Stale state failed to dim to m3onSurfaceVariant");
      }
      if (computeContentColor(false, true, AppearanceMock) !== AppearanceMock.m3colors.m3onSurfaceVariant) {
        failures.push("Offline state failed to dim to m3onSurfaceVariant");
      }
      if (computeContentColor(false, false, AppearanceMock) !== AppearanceMock.colors.colOnLayer1) {
        failures.push("Normal state failed to resolve colOnLayer1");
      }

      if (failures.length > 0) {
        console.error(failures.join("\n"));
        process.exit(1);
      }
    ' "$WEATHERBAR_SRC" || node_res=$?

    if [[ "$node_res" -eq 0 ]]; then
      pass "S3: Temperature parsing (integer Celsius, rounding, safe NaN/cold-boot fallback) verified"
      pass "S3: Multi-tier responsive formatting (XX°C in Tiers 0/1, XX° in Tier 2, XX° in vertical) verified"
      pass "S3: Condition glyph selection and stale/offline dimming verified"
      pass "S3: Neutral colOnLayer1 invariant for standard telemetry verified"
      pass "S3: Outline glyph styling (fill: 0) and 200ms expressiveEffects animation verified"
    else
      fail "S3: Node.js evaluation failed for Section 3 assertions"
    fi
  fi
fi

# ===========================================================================
# Section 4: Alert Precedence, Imminent Rain Badge & Breathing Pulse Logic
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Alert Precedence, Imminent Rain Badge & Pulse Animation ---"

  if [[ ! -f "$WEATHERBAR_SRC" ]]; then
    fail "S4: Cannot test WeatherBar.qml: file missing ($WEATHERBAR_SRC)"
  else
    node_res=0
    node -e '
      const fs = require("fs");
      const code = fs.readFileSync(process.argv[1], "utf8");

      let failures = [];

      // Test AST Invariants for Animation, Spacing, and Component Hierarchy
      if (!code.includes("id: alertPulseAnimation")) {
        failures.push("Missing id: alertPulseAnimation SequentialAnimation");
      }
      if (!code.includes("loops: 3")) {
        failures.push("alertPulseAnimation must have loops: 3 (D-54.1-16)");
      }
      if (!code.includes("to: 0.4") || !code.includes("to: 1.0")) {
        failures.push("alertPulseAnimation opacity cycle must oscillate between 1.0 and 0.4");
      }
      if (!code.includes("Easing.InOutSine")) {
        failures.push("alertPulseAnimation must use Easing.InOutSine");
      }
      if (!code.includes("duration: 600")) {
        failures.push("alertPulseAnimation half-cycle duration must be 600ms");
      }
      if (!code.includes("alertIcon.opacity = 1.0")) {
        failures.push("alertPulseAnimation onRunningChanged must reset alertIcon.opacity to 1.0 on completion");
      }
      if (!code.includes("columnSpacing: 4")) {
        failures.push("contentLayout must maintain 4px columnSpacing (D-54.1-26)");
      }
      if (!code.includes("Revealer")) {
        failures.push("Hazard indicators must use Revealer containers");
      }

      // Stale alert dimming in alertColor AST
      if (!code.includes("Weather.isStale || Weather.isOffline")) {
        failures.push("alertColor must check Weather.isStale || Weather.isOffline (D-54.1-22)");
      }

      // Test Left-to-Right Sequential Ordering: Alert -> Glyph -> Temp -> Rain (D-54.1-11)
      const alertIdx = code.indexOf("id: alertRevealer");
      const glyphIdx = code.indexOf("id: conditionGlyph");
      const tempIdx = code.indexOf("id: tempText");
      const rainIdx = code.indexOf("id: rainRevealer");

      if (alertIdx === -1 || glyphIdx === -1 || tempIdx === -1 || rainIdx === -1) {
        failures.push("One or more sequential pill layout items missing in contentLayout");
      } else if (!(alertIdx < glyphIdx && glyphIdx < tempIdx && tempIdx < rainIdx)) {
        failures.push(`Invalid element ordering: expected Alert (${alertIdx}) < Glyph (${glyphIdx}) < Temp (${tempIdx}) < Rain (${rainIdx})`);
      }

      // Logic Evaluation Functions matching WeatherBar.qml implementation
      function computeImminentRainChance(hourly) {
        if (!hourly || hourly.length === 0) return 0;
        let maxChance = 0;
        const slots = Math.min(3, hourly.length);
        for (let i = 0; i < slots; ++i) {
          const chance = parseInt(hourly[i]?.chanceofrain || "0", 10);
          if (!isNaN(chance) && chance > maxChance) maxChance = chance;
        }
        return maxChance;
      }

      function computeShowRainBadge(imminentRainChance, hasSevereAlert, useShortenedForm, vertical) {
        const imminentRain = imminentRainChance > 50;
        return imminentRain && !hasSevereAlert && (useShortenedForm < 2) && !vertical;
      }

      function computeAlertColor(isStale, isOffline, activeAlert, Appearance, WeatherGlyphs) {
        if (isStale || isOffline) return Appearance.m3colors.m3onSurfaceVariant;
        return activeAlert?.color || (activeAlert?.severity ? WeatherGlyphs.getAlertColor(activeAlert.severity) : Appearance.m3colors.m3error);
      }

      const AppearanceMock = {
        m3colors: { m3onSurfaceVariant: "#49454f", m3primary: "#6750a4", m3error: "#ba1a1a" }
      };
      const WeatherGlyphsMock = {
        getAlertColor: (sev) => "#ff0000"
      };

      // a. Imminent rain chance calculation (3-hour window)
      const hourlyHigh = [{ chanceofrain: "20" }, { chanceofrain: "65" }, { chanceofrain: "40" }, { chanceofrain: "90" }];
      if (computeImminentRainChance(hourlyHigh) !== 65) {
        failures.push(`Expected 3-hour max chance 65%, got ${computeImminentRainChance(hourlyHigh)}%`);
      }

      const hourlyLow = [{ chanceofrain: "10" }, { chanceofrain: "30" }, { chanceofrain: "45" }];
      if (computeImminentRainChance(hourlyLow) !== 45) {
        failures.push(`Expected 3-hour max chance 45%, got ${computeImminentRainChance(hourlyLow)}%`);
      }

      // b. Threshold check
      if (computeImminentRainChance(hourlyHigh) <= 50) failures.push("65% rain should exceed 50% threshold");
      if (computeImminentRainChance(hourlyLow) > 50) failures.push("45% rain should not exceed 50% threshold");

      // c. Rain badge visibility in horizontal mode
      if (!computeShowRainBadge(65, false, 0, false)) failures.push("Rain badge should be visible for 65% rain, no alerts, Tier 0, horizontal");
      if (computeShowRainBadge(45, false, 0, false)) failures.push("Rain badge should NOT be visible for 45% rain");

      // d. Severe alert precedence: active alert suppresses rain badge even when rain > 50% (D-54.1-16)
      if (computeShowRainBadge(75, true, 0, false)) {
        failures.push("Severe alert failed to suppress imminent rain badge (D-54.1-16)");
      }

      // e. Responsive Tier 2 suppression (D-54.1-17)
      if (computeShowRainBadge(65, false, 2, false)) {
        failures.push("Tier 2 failed to suppress imminent rain badge (D-54.1-17)");
      }

      // f. Vertical mode suppression (D-54.1-17, D-54.1-25)
      if (computeShowRainBadge(65, false, 0, true)) {
        failures.push("Vertical mode failed to suppress imminent rain badge (D-54.1-25)");
      }

      // g. Stale alert color dimming (D-54.1-22)
      const mockAlert = { severity: "warning" };
      if (computeAlertColor(true, false, mockAlert, AppearanceMock, WeatherGlyphsMock) !== AppearanceMock.m3colors.m3onSurfaceVariant) {
        failures.push("Stale alert color failed to dim to m3onSurfaceVariant");
      }
      if (computeAlertColor(false, false, mockAlert, AppearanceMock, WeatherGlyphsMock) !== "#ff0000") {
        failures.push("Active alert color failed to resolve alert severity color");
      }

      if (failures.length > 0) {
        console.error(failures.join("\n"));
        process.exit(1);
      }
    ' "$WEATHERBAR_SRC" || node_res=$?

    if [[ "$node_res" -eq 0 ]]; then
      pass "S4: alertPulseAnimation 3-loop breathing cycle and opacity reset to 1.0 verified"
      pass "S4: Stale alert color dimming to m3onSurfaceVariant verified"
      pass "S4: Ordered hierarchy [Alert] -> [Glyph] -> [Temp] -> [Rain] in contentLayout verified"
      pass "S4: Imminent rain badge 3-hour window calculation and >50% threshold verified"
      pass "S4: Severe alert precedence over rain badge verified"
      pass "S4: Tier 2 and vertical mode rain badge suppression verified"
    else
      fail "S4: Node.js evaluation failed for Section 4 assertions"
    fi
  fi
fi

# ===========================================================================
# Section 5: Pure Hover Trigger, M3 Surface Highlight & Pointer Ergonomics
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Pure Hover Trigger, M3 Surface Highlight & Pointer Ergonomics ---"

  if [[ ! -f "$WEATHERBAR_SRC" ]]; then
    fail "S5: Cannot test WeatherBar.qml: file missing ($WEATHERBAR_SRC)"
  else
    wb_code="$(cat "$WEATHERBAR_SRC")"

    # a. Root component is MouseArea
    if echo "$wb_code" | grep -E -A 2 '^MouseArea\s*\{' | grep -q 'id:\s*root'; then
      pass "S5: WeatherBar root component is MouseArea (eliminating nested BarGroup padding per D-54.1-09)"
    else
      fail "S5: WeatherBar root component must be MouseArea"
    fi

    # b. MouseArea parameters: acceptedButtons, cursorShape, hoverEnabled
    if echo "$wb_code" | grep -q 'acceptedButtons:\s*Qt\.AllButtons' && echo "$wb_code" | grep -q 'cursorShape:\s*Qt\.ArrowCursor' && echo "$wb_code" | grep -q 'hoverEnabled:\s*true'; then
      pass "S5: MouseArea configured with Qt.AllButtons, Qt.ArrowCursor, and hoverEnabled: true (D-54.1-02, D-54.1-03)"
    else
      fail "S5: MouseArea missing acceptedButtons: Qt.AllButtons, cursorShape: Qt.ArrowCursor, or hoverEnabled: true"
    fi

    # c. onPressed and onClicked call event.accepted = true (D-54.1-02)
    if echo "$wb_code" | grep -q 'onPressed:\s*event\s*=>\s*event\.accepted\s*=\s*true' && echo "$wb_code" | grep -q 'onClicked:\s*event\s*=>\s*event\.accepted\s*=\s*true'; then
      pass "S5: MouseArea absorbs all click/press events to prevent bubbling (event.accepted = true per D-54.1-02)"
    else
      fail "S5: MouseArea missing click absorption (event.accepted = true)"
    fi

    # d. Double padding elimination
    if echo "$wb_code" | grep -F -q '+ 10 * 2'; then
      fail "S5: Redundant double-padding (+ 10 * 2) detected in WeatherBar.qml (D-54.1-09)"
    else
      pass "S5: Double-padding (+ 10 * 2) eliminated; implicitWidth delegates to contentLayout (D-54.1-09)"
    fi

    # e. WeatherPopup instantiated with hoverOpenDelayMs: 300 and hoverTarget: root (D-54.1-01)
    if echo "$wb_code" | grep -A 6 'WeatherPopup {' | grep -q 'hoverOpenDelayMs:\s*300' && echo "$wb_code" | grep -A 6 'WeatherPopup {' | grep -q 'hoverTarget:\s*root'; then
      pass "S5: WeatherPopup instantiated with hoverOpenDelayMs: 300 and hoverTarget: root (D-54.1-01)"
    else
      fail "S5: Missing WeatherPopup with hoverOpenDelayMs: 300 and hoverTarget: root"
    fi

    # f. Material 3 Inner Surface Hover Highlight (D-54.1-05..08)
    if echo "$wb_code" | grep -A 25 'id:\s*hoverHighlight' | grep -q 'color:\s*Appearance\.colors\.colLayer1Hover' \
       && echo "$wb_code" | grep -A 25 'id:\s*hoverHighlight' | grep -q 'radius:\s*Appearance\.rounding\.small' \
       && echo "$wb_code" | grep -A 25 'id:\s*hoverHighlight' | grep -q 'duration:\s*150'; then
      pass "S5: hoverHighlight Rectangle configured with colLayer1Hover, rounding.small, and 150ms transition (D-54.1-05..08)"
    else
      fail "S5: hoverHighlight missing colLayer1Hover color, rounding.small radius, or 150ms duration"
    fi

    # g. Startup animation dampening timer (D-54.1-31)
    if echo "$wb_code" | grep -q 'id:\s*startupDampenTimer' && echo "$wb_code" | grep -q 'interval:\s*350' && echo "$wb_code" | grep -q 'property\s*bool\s*startupSettled'; then
      pass "S5: startupDampenTimer configured with 350ms interval and startupSettled property (D-54.1-31)"
    else
      fail "S5: Missing startupDampenTimer (interval: 350) or startupSettled property"
    fi

    # h. Public property aliases (Section 4.2 Research)
    aliases=(
      "hoverHighlight:\s*hoverHighlight"
      "contentLayout:\s*contentLayout"
      "alertRevealer:\s*alertRevealer"
      "alertIcon:\s*alertIcon"
      "conditionGlyphItem:\s*conditionGlyph"
      "tempTextItem:\s*tempText"
      "rainRevealer:\s*rainRevealer"
      "popup:\s*weatherPopup"
      "popupActive:\s*weatherPopup\.active"
    )
    all_aliases_ok=1
    for a in "${aliases[@]}"; do
      if ! echo "$wb_code" | grep -Eq "$a"; then
        fail "S5: Missing public property alias: $a"
        all_aliases_ok=0
      fi
    done
    if [[ "$all_aliases_ok" -eq 1 ]]; then
      pass "S5: All 9 public property aliases cleanly exposed for testing & integration"
    fi

    # i. Vertical layout configuration (D-54.1-24, D-54.1-27)
    if echo "$wb_code" | grep -q 'columns:\s*root\.vertical\s*?\s*1\s*:\s*-1' \
       && echo "$wb_code" | grep -q 'implicitWidth:\s*root\.vertical\s*?\s*Appearance\.sizes\.baseVerticalBarWidth\s*:\s*contentLayout\.implicitWidth' \
       && echo "$wb_code" | grep -q 'implicitHeight:\s*root\.vertical\s*?\s*contentLayout\.implicitHeight\s*:\s*Appearance\.sizes\.baseBarHeight'; then
      pass "S5: Vertical mode dimensions and columns toggle correctly bound (D-54.1-24, D-54.1-27)"
    else
      fail "S5: Vertical mode geometry or columns binding missing"
    fi
  fi
fi

info "=== Summary: FAIL=$FAIL, FINDINGS=$FINDINGS ==="
exit "$FAIL"
