#!/usr/bin/env bash
# ===========================================================================
# Phase 54.3: Interactive Multi-Metric Hourly Graph Component Assert Harness
# Enforces: GRAPH-01, GRAPH-02, GRAPH-03, GRAPH-04, ASVS L1
# Decisions: D-54.3-01 through D-54.3-27
# Phase 54.4: superseded and moved contracts are INFO lines citing D-54.4-00 / PA-4 / phase54.4 sections.
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
GRAPH_REL="restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather/WeatherGraph.qml"

# The live stow links target the MAIN checkout. When this harness runs from a linked
# worktree (parallel executor), REPO_ROOT differs from it; both are accepted
# (same rule as phase54.4-weather-assert.sh check_leaf_link).
MAIN_ROOT="$REPO_ROOT"
common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
if [[ -n "$common_dir" ]]; then
  MAIN_ROOT="$(cd "$common_dir/.." 2>/dev/null && pwd -P || printf '%s' "$REPO_ROOT")"
fi
IN_LINKED_WORKTREE=0
if [[ "$MAIN_ROOT" != "$REPO_ROOT" ]]; then
  IN_LINKED_WORKTREE=1
fi

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
    elif [[ "$IN_LINKED_WORKTREE" -eq 1 && "$target_link" == "$MAIN_ROOT/$GRAPH_REL" ]]; then
      pass "S1: $TARGET_GRAPH is a valid leaf symlink resolving to the main-checkout restow overlay (linked worktree run)"
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

  # Phase 54.4: the locked-metric model (D-54.3-10..14) is void; graphKind replaces activeMetric.
  info "S2: superseded by D-54.4-00 (D-54.3-10..14 locked metric): activeMetric property defaults to 'temp' (locked composite view)"
  info "S2: superseded by D-54.4-00 (D-54.3-10..14 locked metric): No runtime write to locked activeMetric remains (tab-less G-54.3-1)"
  info "S2: superseded by D-54.4-00 (D-54.3-10..14 locked metric): No popup-active reset handler reassigns activeMetric"
  info "S2: superseded by D-54.4-00 (D-54.3-10..14 per-metric colour helper): Solid primary stroke driven by getActiveMetricColor() (composite essentials)"
  info "S2: moved, re-asserted by phase54.4-weather-assert.sh S5 (GM.drawTemp dashed feels-like spline, D-54.4-15): Dashed secondary curve present (feels-like essentials)"
  info "S2: superseded by D-54.4-00 (D-54.3-09 rain bars in the temp card): Lower rain bars reference probability and volume fields (composite essentials)"
  info "S2: superseded by D-54.4-00 (D-54.3-10..14 guideline branches): Thermal high/low guideline labels present (composite essentials)"
  info "S2: superseded by D-54.4-00 (G-54.3-1 static card title): Static composite card title present (tab-less G-54.3-1)"
fi

# ===========================================================================
# Section 3: Multi-Metric Visualizations, Dual-Tier Canvas & Scaling Math
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Multi-Metric Visualizations, Dual-Tier Canvas & Scaling Math ---"

  info "S3: moved, re-asserted by phase54.4-weather-assert.sh S1 (single graphCanvas in WeatherGraph.qml): Unified single Canvas item multiplexing metric groups present (D-54.3-07)"
  info "S3: superseded by D-54.4-00 (D-54.3-08 dual-tier coordinates): Standardized dual-tier layout coordinates defined (D-54.3-08)"
  info "S3: moved, re-asserted by phase54.4-weather-assert.sh S4/S5 (computeMonotoneSplineControlPoints in WeatherGraphMath.js): Fritsch-Carlson Monotone Cubic Spline generator present (GRAPH-01)"
  info "S3: moved, re-asserted by phase54.4-weather-assert.sh S4/S5 (GM.valueToY and markerPoints replace getMetricY): Symmetrical getMetricY() helper present (D-54.3-17)"
  info "S3: moved, re-asserted by phase54.4-weather-assert.sh S5 (GM.drawBackdrop past-data hatch, PA-4 No data): Cold-boot past data hatch fallback with 'Past data unavailable' present (D-54.3-18)"
  info "S3: moved, re-asserted by phase54.4-weather-assert.sh S4/S5 (headless Node vm evaluation of GM.valueToY and markerPoints): Headless Node.js evaluation of getMetricY() across all 6 metrics passed with zero NaNs"

  # Legend row presence with three explanatory entries (G-54.3-2)
  if [[ ! -s "$GRAPH_SRC" ]]; then
    fail "S3: WeatherGraph source missing; cannot verify legend contracts (fail-closed)"
  else
    info "S3: superseded by D-54.4-00 (G-54.3-2 per-metric legend row): Legend row present above canvas (G-54.3-2)"
    info "S3: superseded by D-54.4-00 (G-54.3-2 legend strings): Legend entries 'Actual temp', 'Feels-like', 'Rain chance' present (G-54.3-2)"
    info "S3: superseded by D-54.4-00 (D-54.3-16 colTertiary series token): Dashed feels-like stroke uses tertiary token (distinct palette G-54.3-2)"
    info "S3: superseded by D-54.4-00 (D-54.3-16 colSecondary series token): Rain bars use secondary token with opacity-driven depth (G-54.3-2)"
    info "S3: moved, re-asserted by phase54.4-weather-assert.sh S1 (zero hex colour literals in weather QML, D-54.4-11): Static blue volume hex absent from non-comment code (single-hue bars G-54.3-2)"
    info "S3: superseded by D-54.4-00 (D-54.3-08 dual-tier coordinates): Lower tier bottom reserves icon-strip band at height - 46 (G-54.3-5)"
    info "S3: moved, re-asserted by phase54.4-weather-assert.sh S1/S4 (axisStride 4 and 7-tick axis, D-54.4-06): Card-level axisStride property present (T-54.3-08)"
    info "S3: moved, re-asserted by phase54.4-weather-assert.sh S1/S4 (axisStride 4 and 7-tick axis, D-54.4-06): Canvas timestamp loop reads shared root.axisStride (T-54.3-08)"

    # Gutter-overflow gate (G-54.3-1, T-54.3-11)
    if [[ ! -s "$GRAPH_SRC" ]]; then
      fail "S3: WeatherGraph source missing; cannot verify gutter-overflow contracts (fail-closed)"
    else
      info "S3: superseded by D-54.4-00 (G-54.3-1 34px gutter constants; shared gutter per D-54.4-05): Paint and scrub gutter constants both read 34 (G-54.3-1)"
      info "S3: superseded by D-54.4-00 (G-54.3-1 34px gutter constants): No stale 14px gutter constant remains (T-54.3-11)"
      info "S3: superseded by D-54.4-00 (G-54.3-1 34px gutter constants): Y-label anchor derives from gutter constant minus 4 (G-54.3-1)"
      info "S3: superseded by D-54.4-00 (G-54.3-1 34px gutter constants): Anchor x=30 minus 24px label width stays at or above zero (G-54.3-1)"
      info "S3: superseded by D-54.4-00 (G-54.3-1 34px gutter constants): Axis icon strip left margin tracks gutter value 34 (G-54.3-1)"
    fi
  fi
fi

# ===========================================================================
# Section 4: Palette Tokens, Unified Scaling Architecture & Zero-Repaint Hover Scrub Overlay
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Palette Tokens & Zero-Repaint Hover Scrub Overlay ---"

  info "S4: moved, re-asserted by phase54.4-weather-assert.sh S5 (hoverMouse zero-repaint scrub, D-54.4-07): Zero-repaint invariant satisfied: onPositionChanged updates QML overlay without Canvas repainting (GRAPH-04, D-54.3-06)"
  info "S4: moved, re-asserted by phase54.4-weather-assert.sh S5 (hover overlay items: scrub line and point markers, D-54.4-07): QML overlay items 'scrubHairline', 'snapDot', 'tooltipPill' present (D-54.3-21)"
  info "S4: superseded by D-54.4-00 (D-54.3-19 tooltip pill; D-54.4-08 lets tooltips float past the card): Tooltip pill implements smart vertical flip when Y < 60px (D-54.3-22)"
  info "S4: superseded by D-54.4-00 (D-54.3-19 tooltip pill; D-54.4-08 lets tooltips float past the card): Tooltip pill clamps horizontally 6px from card edges (D-54.3-22)"
  info "S4: moved, re-asserted by phase54.4-weather-assert.sh S5 (snap marker at the hovered hour): Snap dot tracks activeScrubY (D-54.3-21)"
  info "S4: superseded by D-54.4-00 (D-54.3-19 tooltip readouts): Context-adaptive formatTooltipMetric helper present (D-54.3-19)"
  info "S4: superseded by D-54.4-00 (D-54.3-20 temporal-label helper): Full temporal context formatTemporalLabel helper present (D-54.3-20)"
  info "S4: moved, re-asserted by phase54.4-weather-assert.sh S5 (hover fade): Hover overlay implements smooth fade-out (Behavior on opacity ~150ms) (D-54.3-23)"
  info "S4: superseded by D-54.4-00 (D-54.3-16 theme-token palette; fixed palettes per D-54.4-11): WeatherGraph uses M3 theme tokens Appearance.colors.colPrimary/colSecondary/colTertiary/colOutlineVariant (D-54.3-16)"

  # Tooltip legibility: floor token absent from pill region (G-54.3-3)
  if [[ ! -s "$GRAPH_SRC" ]]; then
    fail "S4: WeatherGraph source missing; cannot verify tooltip contracts (fail-closed)"
  else
    info "S4: superseded by D-54.4-00 (D-54.3-19 tooltip pill structure): Floor type token absent from tooltip pill region (legible tooltip G-54.3-3)"
    info "S4: superseded by D-54.4-00 (D-54.3-19 tooltip pill structure): Tooltip temporal label and separators use raised 12px token (G-54.3-3)"
    info "S4: superseded by D-54.4-00 (D-54.3-19 tooltip pill structure): Tooltip metric readout uses raised 15px token (G-54.3-3)"

    # Tooltip-structure gate (G-54.3-3, T-54.3-12)
    if [[ ! -s "$GRAPH_SRC" ]]; then
      fail "S4: WeatherGraph source missing; cannot verify tooltip structure (fail-closed)"
    else
      info "S4: superseded by D-54.4-00 (D-54.3-19 tooltip pill structure): Tooltip pill contains stacked vertical ColumnLayout (G-54.3-3)"
      info "S4: superseded by D-54.4-00 (D-54.3-19 tooltip pill structure): Per-line tooltip helpers formatTooltipTempLine/formatTooltipRainLine present (G-54.3-3)"
      info "S4: superseded by D-54.4-00 (D-54.3-19 tooltip pill structure): Pill background element carries 0.75 opacity with text at full opacity (T-54.3-12)"
      info "S4: superseded by D-54.4-00 (D-54.3-19 tooltip readouts): Pill region routes per-card readout through formatTooltipMetric keyed on activeMetric (G-54.3-2/G-54.3-3)"
      info "S4: superseded by D-54.4-00 (D-54.3-19 tooltip readouts): Pill middle row preserves temp-composite line for the temp card (G-54.3-3)"
      info "S4: superseded by D-54.4-00 (D-54.3-09 rain in the temp card): Pill rain row visible only on the temp composite card (G-54.3-3)"
    fi
  fi
fi

# ===========================================================================
# Section 5: Day/Night Shading, Date Boundaries & Submodule Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Day/Night Shading, Date Boundaries & Submodule Verification ---"

  info "S5: moved, re-asserted by phase54.4-weather-assert.sh S5 (GM.drawBackdrop night shading, PA-4): Canvas renders nocturnal background shading for night slots (D-54.3-24)"
  info "S5: moved, re-asserted by phase54.4-weather-assert.sh S5 (GM.drawBackdrop midnight divider, PA-4): Canvas renders vertical dotted divider at midnight date boundary (D-54.3-25)"
  info "S5: superseded by D-54.4-00 (D-54.3-26 24h and NOW axis labels; the axis reads Now per D-54.4-06): X-axis center slot 12 NOW highlighted in colPrimary (D-54.3-26)"
  info "S5: superseded by PA-4 (NOW pill badge dropped; the axis already reads Now, D-54.4-06): NOW pill badge on the canvas centre slot (D-54.3-26)"
  info "S5: moved, re-asserted by phase54.4-weather-assert.sh S1/S4 (axis condition-icon row, D-54.4-06): Mini condition glyph rendering supported in bottom axis band (D-54.3-27)"

  # QML icon strip replaces canvas ligature words (G-54.3-5 canvas half)
  if [[ ! -s "$GRAPH_SRC" ]]; then
    fail "S5: WeatherGraph source missing; cannot verify icon-strip contracts (fail-closed)"
  else
    info "S5: moved, re-asserted by phase54.4-weather-assert.sh S1/S4 (axis icon strip, D-54.4-06): QML axis icon strip present (G-54.3-5)"
    info "S5: moved, re-asserted by phase54.4-weather-assert.sh S1/S4 (axisStride-driven ticks, D-54.4-06): Icon strip visibility driven by shared stride (T-54.3-08)"
    info "S5: superseded by D-54.4-00 (D-54.3-26 24h canvas axis labels): Timestamp baseline sits 8px above canvas base (G-54.3-5)"
    info "S5: superseded by PA-4 (D-54.3-25 date chip dropped; it collides with the D-54.4-09 legend row): Date chip draws at collision-offset clamped position (G-54.3-5)"
    info "S5: moved, re-asserted by phase54.4-weather-assert.sh S5 (raw glyph-name canvas check): No canvas call paints raw glyph-name strings (G-54.3-5)"
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
    info "S6: superseded by D-54.4-00 (G-54.3-4 stacked five instances; D-54.4-02 three graph cards): WeatherPopup stacks exactly 5 locked WeatherGraph instances (G-54.3-4)"

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

    info "S6: superseded by D-54.4-00 (G-54.3-4 locked bindings): Locked activeMetric wind declarative binding present in WeatherPopup (G-54.3-4)"
    info "S6: superseded by D-54.4-00 (G-54.3-4 locked bindings): Locked activeMetric 'temp', 'wind', 'aqi', 'baro', 'uv' each bound exactly once in WeatherPopup (G-54.3-4)"
    info "S6: superseded by D-54.4-00 (D-54.3-10..14 locked metric): Zero activeMetric runtime writes across stacked files (locked T-54.3-15)"

    # Popup-chrome anchoring gate (G-54.3-1): the StyledFlickable content
    # must be centered in popupBackground so the margin*2 surplus splits
    # evenly on all four sides, while the implicit-size chain stays
    # byte-identical so the window sizes exactly as before. All fail-closed.
    STYLED_POPUP_SRC="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml"
    if [[ ! -s "$POPUP_SRC" ]]; then
      fail "S6: WeatherPopup source missing; cannot verify popup-chrome anchoring (fail-closed)"
    elif [[ ! -s "$STYLED_POPUP_SRC" ]]; then
      fail "S6: StyledPopup source missing; cannot verify margin-times-2 formula (fail-closed)"
    else
      info "S6: superseded by D-54.4-03 (G-54.3-1 scrolling container): StyledFlickable region carries centering anchor (even padding G-54.3-1)"
      info "S6: superseded by D-54.4-03 (fixed 880 width): implicitWidth 880 sizing line still present (window sizing unchanged)"
      info "S6: superseded by D-54.4-03 (scroll contentHeight; popup no longer scrolls): contentHeight binding still present (window sizing unchanged)"

      if grep -qF 'implicitWidth: root.contentItem.implicitWidth + margin * 2' "$STYLED_POPUP_SRC" && grep -qF 'implicitHeight: root.contentItem.implicitHeight + margin * 2' "$STYLED_POPUP_SRC"; then
        pass "S6: StyledPopup margin-times-2 implicit-size formula untouched"
      else
        fail "S6: StyledPopup margin-times-2 implicit-size formula altered"
      fi
    fi

    # Per-metric wiring gate (G-54.3-2/G-54.3-3, plan 54.3-10): legend,
    # tooltip, and Y-axis branches must key off the card metric so no card
    # repeats the temperature composite. All fail-closed with file guards.
    if [[ ! -s "$GRAPH_SRC" ]]; then
      fail "S6: WeatherGraph source missing; cannot verify per-metric wiring (fail-closed)"
    else
      info "S6: superseded by D-54.4-00 (D-54.3-10..14 per-metric legend label helpers): Per-metric legend label helpers present for all three entries (G-54.3-2)"
      info "S6: superseded by D-54.4-00 (D-54.3-10..14 per-metric legend colour helpers): Per-metric legend color helpers present for all three entries (G-54.3-2)"
      info "S6: superseded by D-54.4-00 (D-54.3-10..14 per-metric legend): Legend region keys swatches and labels off the card metric (G-54.3-2)"
      info "S6: superseded by D-54.4-00 (D-54.3-10..14 per-metric legend helpers): Legend helpers bind M3 tokens or WeatherGlyphs helpers only, zero static hex (T-54.3-18)"
      info "S6: superseded by D-54.4-00 (D-54.3-10..14 guideline branches): Y-axis guideline branches for 'wind', 'aqi', 'uv' present (G-54.3-2)"
      info "S6: superseded by D-54.4-00 (D-54.3-13 baro label; the graph uses atm): Baro guideline labels are number-only (G-54.3-2)"
      info "S6: superseded by D-54.4-00 (D-54.3-13 baro label; the graph uses atm): Baro unit painted once as separate caption (G-54.3-2)"
      info "S6: superseded by D-54.4-00 (D-54.3-19 tooltip readouts): Tooltip pill region routes readout through the per-metric helper (G-54.3-3)"

      chrome_left=0
      for chrome_id in tabBarContainer tabsRepeater tabHighlight activeTabPill; do
        chrome_left=$((chrome_left + $(grep -v '^[[:space:]]*//' "$GRAPH_SRC" | grep -c "$chrome_id" || true)))
      done
      if [[ "$chrome_left" -eq 0 ]]; then
        pass "S6: Zero tab chrome in touched graph file (per-metric wiring gate)"
      else
        fail "S6: Tab chrome present ${chrome_left}x in touched graph file (per-metric wiring gate)"
      fi

      info "S6: moved, re-asserted by phase54.4-weather-assert.sh S5 (hoverMouse zero-repaint scrub, D-54.4-07): Zero requestPaint in scrub handlers (per-metric wiring gate)"

      info "S6: superseded by D-54.4-00 (D-54.3-10..14 locked metric): Zero activeMetric runtime writes in touched graph file (per-metric wiring gate)"
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
