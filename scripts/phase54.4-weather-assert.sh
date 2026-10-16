#!/usr/bin/env bash
# ===========================================================================
# Phase 54.4: Modular Popup Inspector and Clean Card Layout Assert Harness
# Enforces: POPUP-01, POPUP-02, ASVS L1
# Decisions: D-54.4-01 through D-54.4-34 (sections grow per plan: 01, 03, 05, 06, 07)
#
# Usage (from REPO_ROOT):
#   ./scripts/phase54.4-weather-assert.sh [1-5] [OPTIONS]
#
# Sections:
#   1: Static layout, deploy topology and repository integrity (D-54.4-01/02/03/04)
#   2: Popup sizing math (D-54.4-03, T-54.4-01)
#   3: Palette and contrast (D-54.4-11)
#   4: Axis labels, gradient stops and scales (D-54.4-05/06/14, Pitfalls 1/5/7/8)
#   5: Draw functions against a recording mock canvas (D-54.4-13/15/17)
#
# Options:
#   -s, --section <1-5>    Execute only the specified section (1-5)
#   -q, --quick            Skip the strict repository verification (arch/dots-hyprland.sh)
#       --standalone       Alias for --quick
#   -c, --syntax           Execute static bash syntax checks only
#   -t, --tap              Emit TAP version 13 instead of [PASS]/[FAIL] lines
#   -h, --help             Show this help message
#
# Section 2-5 logic evaluates WeatherGraphMath.js headless in a Node `vm` sandbox.
# Every grep stays inside the weather overlay directory, the named source files and
# scripts/. No $HOME-wide or stow/ recursion.
#
# Exit status is the FAIL count (capped at 255); 0 means every executed assert passed.
# ===========================================================================

set -euo pipefail

# Fail closed if executed as root (ASVS L1 Root Privilege Prevention / T-54.4-05)
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Error: Do not run as root" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0
TESTS=0
TAP_MODE=0

_tap_desc() {
  # TAP descriptions are single-line; '#' would open a directive.
  local s="${1//$'\n'/ }"
  printf '%s' "${s//#/\\#}"
}

pass() {
  TESTS=$((TESTS + 1))
  if [[ "$TAP_MODE" -eq 1 ]]; then
    printf 'ok %d - %s\n' "$TESTS" "$(_tap_desc "$1")"
  else
    printf '[PASS] %s\n' "$1"
  fi
}
fail() {
  TESTS=$((TESTS + 1))
  FAIL=$((FAIL + 1))
  if [[ "$TAP_MODE" -eq 1 ]]; then
    printf 'not ok %d - %s\n' "$TESTS" "$(_tap_desc "$1")"
  else
    printf '[FAIL] %s\n' "$1"
  fi
}
finding() {
  FINDINGS=$((FINDINGS + 1))
  if [[ "$TAP_MODE" -eq 1 ]]; then
    printf '# FINDING %s\n' "${1//$'\n'/ }"
  else
    printf '[FINDING] %s\n' "$1"
  fi
}
info() {
  if [[ "$TAP_MODE" -eq 1 ]]; then
    printf '# %s\n' "${1//$'\n'/ }"
  else
    printf '[INFO] %s\n' "$1"
  fi
}

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

usage() {
  echo "Usage: $0 [1-5] [OPTIONS]"
  echo ""
  echo "Sections:"
  echo "  1: Static layout, deploy topology and repository integrity (D-54.4-01/02/03/04)"
  echo "  2: Popup sizing math (D-54.4-03, T-54.4-01)"
  echo "  3: Palette and contrast (D-54.4-11)"
  echo "  4: Axis labels, gradient stops and scales (D-54.4-05/06/14)"
  echo "  5: Draw functions against a recording mock canvas (D-54.4-13/15/17)"
  echo ""
  echo "Options:"
  echo "  -s, --section <1-5>    Execute only the specified section (1-5)"
  echo "  -q, --quick            Skip the strict repository verification (arch/dots-hyprland.sh)"
  echo "      --standalone       Alias for --quick"
  echo "  -c, --syntax           Execute static bash syntax checks only"
  echo "  -t, --tap              Emit TAP version 13 instead of [PASS]/[FAIL] lines"
  echo "  -h, --help             Show this help message"
}

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
    --tap|-t)
      TAP_MODE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ "$TAP_MODE" -eq 1 ]]; then
  printf 'TAP version 13\n'
fi

finish() {
  info "========================================================="
  info "Phase 54.4 Assert Harness Summary: FAIL=$FAIL, FINDINGS=$FINDINGS"
  info "========================================================="
  if [[ "$TAP_MODE" -eq 1 ]]; then
    printf '1..%d\n' "$TESTS"
  fi
  if [[ "$FAIL" -gt 255 ]]; then
    exit 255
  fi
  exit "$FAIL"
}

WEATHER_REL="restow/quickshell/.config/quickshell/ii/modules/ii/bar/weather"
WEATHER_DIR="$REPO_ROOT/$WEATHER_REL"
GM_JS="$WEATHER_DIR/WeatherGraphMath.js"
GRAPH_SRC="$WEATHER_DIR/WeatherGraph.qml"
POPUP_SRC="$WEATHER_DIR/WeatherPopup.qml"
BASE_CARD="$WEATHER_DIR/WeatherBaseCard.qml"
WIND_CARD_REL="$WEATHER_REL/WeatherWindCard.qml"
CONFIG_SRC="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/common/Config.qml"
STYLED_POPUP_SRC="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/StyledPopup.qml"
LIVE_WEATHER_DIR="$HOME/.config/quickshell/ii/modules/ii/bar/weather"
PHASE_BASE="d5022a29"

# The live stow links target the MAIN checkout. When this harness runs from a linked
# worktree (parallel executor), REPO_ROOT differs from it; both are accepted.
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
  if bash -n "$0"; then
    pass "Assert harness bash syntax check passed (bash -n verified)"
  else
    fail "Assert harness bash syntax check failed (bash -n)"
  fi
  finish
fi

# ===========================================================================
# Node vm integration
# ===========================================================================
HAVE_NODE=0
if command -v node >/dev/null 2>&1; then
  HAVE_NODE=1
fi

# Shared JS prelude: loads WeatherGraphMath.js into sandbox G and defines the harness
# helpers ok, near, mkTimeline, mockCtx, geomFor and rng.
read -r -d '' PRELUDE <<'JS' || true
const vm = require("vm");
const fs = require("fs");
const G = {};
vm.createContext(G);
vm.runInContext(fs.readFileSync(process.argv[1], "utf8"), G, { filename: "WeatherGraphMath.js" });

function ok(cond, msg) {
  console.log((cond ? "PASS " : "FAIL ") + msg);
}
function finding(msg) {
  console.log("FINDING " + msg);
}
function same(a, b) {
  return JSON.stringify(a) === JSON.stringify(b);
}
function near(a, b, eps) {
  return Math.abs(a - b) <= (eps === undefined ? 1e-9 : eps);
}
// Deterministic PRNG (mulberry32) so property tests are reproducible.
function rng(seed) {
  let s = seed >>> 0;
  return function () {
    s = (s + 0x6D2B79F5) >>> 0;
    let t = s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Inline 25-slot timeline fixture shaped like services/Weather.qml rebuildTimeline().
// hourNum = (i + 3) % 24, so index 12 is 3PM and isNow. The first opts.unavailable
// slots (default 3) are isHistoricalUnavailable with the zeroed/null groups Weather.qml uses.
// Variants: precip (0.4 and 3.2 mm on slots 15 and 18), epa (0, 1, 6 on slots 5, 6, 7),
// flatPressure (all available slots 1010 hPa).
function mkTimeline(opts) {
  const o = opts || {};
  const unavailable = o.unavailable === undefined ? 3 : o.unavailable;
  const slots = [];
  for (let i = 0; i < 25; ++i) {
    const hourNum = (i + 3) % 24;
    const isDay = hourNum >= 6 && hourNum <= 17;
    const un = i < unavailable;
    const base = {
      index: i, isPast: i < 12, isNow: i === 12, isFuture: i > 12,
      isHistoricalUnavailable: un, hourNum: hourNum, isDay: isDay,
      isDayBoundary: hourNum === 0, glyph: "sunny", desc: "Sunny", dateStr: "",
      timeLabel: i === 12 ? "Now" : String(hourNum).padStart(2, "0") + ":00"
    };
    if (un) {
      base.thermal = { tempC: null, feelsLikeC: null, dewPointC: null, heatIndexC: null, windChillC: null };
      base.moisture = { precipMM: 0.0, rainProb: 0, humidity: 0, cloudCover: 0, snowProb: 0, thunderProb: 0 };
      base.wind = { speedKmph: 0, gustKmph: 0, degree: 0, dir16: "N" };
      base.aqi = { epaIndex: 0, pm2_5: 0.0, pm10: 0.0, co: 0.0, no2: 0.0, o3: 0.0, so2: 0.0, defraIndex: 0 };
      base.atmosphere = { pressureHpa: 0, visibilityKm: 0 };
      base.solar = { uvIndex: 0, shortRad: 0.0, diffRad: 0.0 };
    } else {
      const t = 25 + (i % 10);
      const speed = 6 + (i % 12);
      const uv = isDay ? Math.min(7, Math.max(0, 7 - Math.abs(hourNum - 12))) : 0;
      let precip = 0;
      if (o.precip && i === 15) precip = 0.4;
      if (o.precip && i === 18) precip = 3.2;
      let epa = 2 + (i % 3);
      if (o.epa && i === 5) epa = 0;
      if (o.epa && i === 6) epa = 1;
      if (o.epa && i === 7) epa = 6;
      base.thermal = { tempC: t, feelsLikeC: t + 1 + (i % 2), dewPointC: 18, heatIndexC: t + 1, windChillC: t };
      base.moisture = { precipMM: precip, rainProb: i % 18, humidity: 70, cloudCover: 20, snowProb: 0, thunderProb: 0 };
      base.wind = { speedKmph: speed, gustKmph: Math.min(33, speed * 2), degree: 340, dir16: "NNW" };
      base.aqi = { epaIndex: epa, pm2_5: 34, pm10: 41, co: 210, no2: 12, o3: 88, so2: 4, defraIndex: 3 };
      base.atmosphere = { pressureHpa: o.flatPressure ? 1010 : 1008 + (i % 6), visibilityKm: 8 + (i % 3) };
      base.solar = { uvIndex: uv, shortRad: Math.round(855 * uv / 7), diffRad: 0 };
    }
    slots.push(base);
  }
  return slots;
}

// Recording Context2D mock: logs method calls and property sets (strokeStyle, fillStyle,
// globalAlpha, font, ...). Gradients log ["stop", offset, color].
function mockCtx() {
  const log = [];
  const state = {};
  const ctx = new Proxy(state, {
    get(target, key) {
      if (key in target) return target[key];
      if (typeof key === "symbol") return undefined;
      return function () {
        const args = Array.prototype.slice.call(arguments);
        log.push([key].concat(args));
        if (key === "createLinearGradient") {
          return { addColorStop: function (offset, color) { log.push(["stop", offset, color]); } };
        }
        if (key === "measureText") {
          return { width: String(args[0]).length * 6 };
        }
        return undefined;
      };
    },
    set(target, key, value) {
      log.push(["set", key, value]);
      target[key] = value;
      return true;
    }
  });
  return { ctx: ctx, log: log };
}

function geomFor(n) {
  const plotLeft = 24;
  const plotRight = 292;
  return {
    width: 300, height: 260, plotLeft: plotLeft, plotRight: plotRight,
    plotTop: 16, plotBottom: 260, slotW: (plotRight - plotLeft) / n, n: n, isTimeline25: true
  };
}

function calls(log, name) {
  return log.filter(function (e) { return e[0] === name; });
}
JS

run_node_section() {
  local label="$1"
  local js="$2"
  if [[ "$HAVE_NODE" -eq 0 ]]; then
    finding "$label: node not found on PATH; skipped WeatherGraphMath.js vm assertions"
    return 0
  fi
  if [[ ! -s "$GM_JS" ]]; then
    fail "$label: WeatherGraphMath.js missing or empty: $GM_JS (fail-closed)"
    return 0
  fi
  local out rc line
  set +e
  out="$(node -e "${PRELUDE}
${js}" "$GM_JS" 2>&1)"
  rc=$?
  set -e
  while IFS= read -r line; do
    case "$line" in
      "PASS "*) pass "${line#PASS }" ;;
      "FAIL "*) fail "${line#FAIL }" ;;
      "FINDING "*) finding "${line#FINDING }" ;;
      "") ;;
      *) info "$label: $line" ;;
    esac
  done <<<"$out"
  if [[ "$rc" -ne 0 ]]; then
    fail "$label: node exited with status $rc (uncaught exception in harness or module)"
  fi
}

# Live leaf symlink check. Accepts a link resolving to this checkout's restow file, or,
# from a linked worktree, to the main checkout's restow file (pending merge => FINDING).
check_leaf_link() {
  local name="$1"
  local live="$LIVE_WEATHER_DIR/$name"
  local rel="$WEATHER_REL/$name"
  local target
  if [[ -L "$live" ]]; then
    target="$(readlink -m -- "$live" 2>/dev/null || true)"
    if [[ "$target" == "$REPO_ROOT/$rel" ]]; then
      if [[ -e "$target" ]]; then
        pass "S1: live $name is a leaf symlink resolving to the restow overlay"
      else
        fail "S1: live $name is a dangling leaf symlink: $target"
      fi
    elif [[ "$IN_LINKED_WORKTREE" -eq 1 && "$target" == "$MAIN_ROOT/$rel" ]]; then
      if [[ -e "$target" ]]; then
        pass "S1: live $name is a leaf symlink resolving to the main-checkout restow overlay (linked worktree run)"
      elif [[ -s "$REPO_ROOT/$rel" ]]; then
        finding "S1: live $name targets the main checkout, where the file appears once this worktree is merged: $target"
      else
        fail "S1: live $name is dangling and the worktree has no $rel either"
      fi
    else
      fail "S1: live $name resolves to $target, expected $REPO_ROOT/$rel"
    fi
  elif [[ -e "$live" ]]; then
    fail "S1: live $name exists as a regular file, expected a stow leaf symlink"
  else
    finding "S1: live $name is not present in the local home directory (not deployed on this host)"
  fi
}

# ===========================================================================
# Section 1: Static layout, deploy topology and repository integrity
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Static layout, deploy topology and repository integrity (D-54.4-01/02/03/04) ---"

  for src in "$GM_JS" "$GRAPH_SRC" "$POPUP_SRC" "$BASE_CARD" "$CONFIG_SRC" "$STYLED_POPUP_SRC"; do
    if [[ -s "$src" ]]; then
      pass "S1: $(basename "$src") exists and is non-empty"
    else
      fail "S1: missing or empty source: $src"
    fi
  done

  for name in WeatherGraphMath.js WeatherGraph.qml WeatherPopup.qml; do
    check_leaf_link "$name"
  done

  # Real un-folded parent directories (stow --no-folding)
  for check_dir in "$HOME/.config" "$HOME/.config/quickshell" "$HOME/.config/quickshell/ii" "$HOME/.config/quickshell/ii/modules" "$HOME/.config/quickshell/ii/modules/ii" "$HOME/.config/quickshell/ii/modules/ii/bar" "$LIVE_WEATHER_DIR"; do
    if [[ -d "$check_dir" && ! -L "$check_dir" ]]; then
      pass "S1: directory $(basename "$check_dir") is an un-folded real directory"
    elif [[ ! -e "$check_dir" ]]; then
      finding "S1: directory $check_dir is not present on this host"
    else
      fail "S1: directory $(basename "$check_dir") is symlinked, expected an un-folded real directory"
    fi
  done

  # JS module syntax and Node-vm visibility contract
  if [[ "$HAVE_NODE" -eq 1 && -s "$GM_JS" ]]; then
    if node --check "$GM_JS" >/dev/null 2>&1; then
      pass "S1: node --check passed for WeatherGraphMath.js"
    else
      fail "S1: node --check rejected WeatherGraphMath.js"
    fi
  elif [[ "$HAVE_NODE" -eq 0 ]]; then
    finding "S1: node not found on PATH; skipped node --check"
  fi
  if [[ -s "$GM_JS" ]]; then
    if grep -qE '^(const|let)[[:space:]]' "$GM_JS"; then
      fail "S1: WeatherGraphMath.js has a top-level const/let (Node vm only exposes var/function)"
    else
      pass "S1: WeatherGraphMath.js declares top level only with var/function"
    fi
    if grep -qE '^[[:space:]]*\.pragma|^[[:space:]]*\.import' "$GM_JS"; then
      fail "S1: WeatherGraphMath.js uses .pragma/.import (must be a plain JS resource)"
    else
      pass "S1: WeatherGraphMath.js is a plain JS resource (no .pragma/.import)"
    fi
  fi

  # QML parse gate over every weather overlay file plus StyledPopup.qml and Config.qml
  if command -v qmlformat >/dev/null 2>&1; then
    qml_count=0
    for qml_file in "$WEATHER_DIR"/*.qml "$STYLED_POPUP_SRC" "$CONFIG_SRC"; do
      [[ -e "$qml_file" ]] || continue
      qml_count=$((qml_count + 1))
      if qmlformat -n "$qml_file" >/dev/null 2>&1; then
        pass "S1: qmlformat -n passed for $(basename "$qml_file")"
      else
        fail "S1: qmlformat -n reported errors for $(basename "$qml_file")"
      fi
    done
    if [[ "$qml_count" -eq 0 ]]; then
      fail "S1: no QML files found in $WEATHER_DIR (fail-closed)"
    fi
  else
    finding "S1: qmlformat not found on PATH; skipped QML parse gate"
  fi

  # Config keys live in the bar.weather JsonObject that holds fetchInterval (D-54.4-03)
  if [[ -s "$CONFIG_SRC" ]]; then
    weather_block="$(awk '
      /property JsonObject weather: JsonObject \{/ { inb = 1; buf = ""; match($0, /^ */); ind = RLENGTH; next }
      inb {
        if ($0 ~ /^ *\}/) { match($0, /^ */); if (RLENGTH == ind) { if (buf ~ /fetchInterval/) print buf; inb = 0; next } }
        buf = buf "\n" $0
      }' "$CONFIG_SRC")"
    if [[ -z "$weather_block" ]]; then
      fail "S1: could not locate the bar.weather JsonObject holding fetchInterval in Config.qml"
    else
      for key in "property int popupWidthPercent: 50" "property int popupHeightPercent: 50"; do
        if grep -qF "$key" <<<"$weather_block"; then
          pass "S1: Config.qml bar.weather declares '$key' next to fetchInterval"
        else
          fail "S1: Config.qml bar.weather is missing '$key' next to fetchInterval"
        fi
      done
    fi
  fi

  if [[ -s "$POPUP_SRC" ]]; then
    # No scrolling container of any kind (D-54.4-03: the popup must not scroll)
    if grep -qE '(Flickable|ScrollView|ScrollBar|ListView|GridView|PathView)[[:space:]]*\{' "$POPUP_SRC"; then
      fail "S1: WeatherPopup.qml still contains a scrolling container element"
    else
      pass "S1: WeatherPopup.qml contains no scrolling container element"
    fi
    if grep -qE 'StyledFlickable|Flickable' "$POPUP_SRC"; then
      fail "S1: WeatherPopup.qml still references a Flickable type"
    else
      pass "S1: WeatherPopup.qml references no Flickable type"
    fi

    content_root_block="$(grep -A3 'id: contentRoot' "$POPUP_SRC" || true)"
    if [[ -n "$content_root_block" ]] && grep -qF 'anchors.centerIn: parent' <<<"$content_root_block"; then
      pass "S1: WeatherPopup.qml contentRoot is centred (anchors.centerIn: parent)"
    else
      fail "S1: WeatherPopup.qml lacks id: contentRoot with anchors.centerIn: parent"
    fi

    kind_order="$(grep -oE 'graphKind: "[a-z]+"' "$POPUP_SRC" | sed -E 's/.*"([a-z]+)"/\1/' | paste -sd, - || true)"
    if [[ "$kind_order" == "temp,rainwind,airuv" ]]; then
      pass "S1: WeatherPopup.qml graph order is temp,rainwind,airuv (D-54.4-02)"
    else
      fail "S1: WeatherPopup.qml graph order is '$kind_order', expected temp,rainwind,airuv"
    fi

    alert_ln="$(grep -n 'id: alertBanner' "$POPUP_SRC" | head -1 | cut -d: -f1 || true)"
    hero_ln="$(grep -n 'id: heroCard' "$POPUP_SRC" | head -1 | cut -d: -f1 || true)"
    row_ln="$(grep -n 'id: graphRow' "$POPUP_SRC" | head -1 | cut -d: -f1 || true)"
    if [[ -n "$alert_ln" && -n "$hero_ln" && -n "$row_ln" && "$alert_ln" -lt "$row_ln" && "$hero_ln" -lt "$row_ln" ]]; then
      pass "S1: alertBanner and heroCard come before graphRow (D-54.4-01 top section)"
    else
      fail "S1: alertBanner/heroCard/graphRow order wrong or missing (alert=$alert_ln hero=$hero_ln row=$row_ln)"
    fi

    for gid in tempGraph rainGraph airGraph; do
      if grep -qE "id: ${gid}\$" "$POPUP_SRC"; then
        pass "S1: WeatherPopup.qml instantiates $gid"
      else
        fail "S1: WeatherPopup.qml is missing WeatherGraph id $gid"
      fi
    done
    pref_count="$(grep -cF 'Layout.preferredWidth: graphRow.cardWidth' "$POPUP_SRC" || true)"
    if [[ "$pref_count" -eq 3 ]]; then
      pass "S1: all three graph cards share graphRow.cardWidth (equal width, D-54.4-02)"
    else
      fail "S1: expected 3 cards bound to graphRow.cardWidth, found $pref_count"
    fi
    gutter_count="$(grep -cF 'gutter: contentRoot.graphGutter' "$POPUP_SRC" || true)"
    if [[ "$gutter_count" -eq 3 ]]; then
      pass "S1: all three graph cards bind the shared gutter (D-54.4-05)"
    else
      fail "S1: expected 3 cards bound to contentRoot.graphGutter, found $gutter_count"
    fi
    if grep -qE 'Config\.options\.bar\.weather\.popupWidthPercent' "$POPUP_SRC" && grep -qE 'Config\.options\.bar\.weather\.popupHeightPercent' "$POPUP_SRC"; then
      pass "S1: WeatherPopup.qml sizes from Config popupWidthPercent/popupHeightPercent"
    else
      fail "S1: WeatherPopup.qml does not read both popup percent keys"
    fi

    # Hidden, not deleted (D-54.4-01)
    for card in WeatherAtmosphericCard WeatherWindCard WeatherAqiCard WeatherAstronomyCard; do
      if grep -qE "^[[:space:]]*${card}[[:space:]]*\{" "$POPUP_SRC"; then
        pass "S1: $card is still instantiated in WeatherPopup.qml"
        row_state="$(awk -v card="$card" '
          /RowLayout[[:space:]]*\{/ { seg = "" }
          { seg = seg "\n" $0 }
          $0 ~ "^[[:space:]]*" card "[[:space:]]*\\{" { print ((seg ~ /visible: false/) ? "HIDDEN" : "SHOWN"); exit }
        ' "$POPUP_SRC")"
        if [[ "$row_state" == "HIDDEN" ]]; then
          pass "S1: the row holding $card carries visible: false"
        else
          fail "S1: the row holding $card is not hidden (visible: false missing)"
        fi
      else
        fail "S1: $card was deleted from WeatherPopup.qml (must be hidden, not deleted)"
      fi
    done
  fi

  # Zero hex literals in the two rewritten QML files (all fixed colours live in GM, D-54.4-11)
  for src in "$GRAPH_SRC" "$POPUP_SRC"; do
    [[ -s "$src" ]] || continue
    hex_hits="$(grep -cE '#[0-9a-fA-F]{3,8}' "$src" || true)"
    if [[ "$hex_hits" -eq 0 ]]; then
      pass "S1: zero hex colour literals in $(basename "$src")"
    else
      fail "S1: $hex_hits hex colour literal line(s) in $(basename "$src")"
    fi
    if grep -q 'activeMetric' "$src"; then
      fail "S1: $(basename "$src") still carries the retired activeMetric lock (D-54.4-00)"
    else
      pass "S1: $(basename "$src") has no retired activeMetric lock"
    fi
  done

  if [[ -s "$GRAPH_SRC" ]]; then
    for needle in 'property string graphKind' 'import "WeatherGraphMath.js" as GM' 'GM.drawKind(' 'GM.axisTicks(' 'GM.axisTickLabel(' 'function slotX(' 'function geom(' 'renderStrategy: Canvas.Immediate'; do
      if grep -qF "$needle" "$GRAPH_SRC"; then
        pass "S1: WeatherGraph.qml contains '$needle'"
      else
        fail "S1: WeatherGraph.qml is missing '$needle'"
      fi
    done
    if grep -qE 'Flickable|ScrollView' "$GRAPH_SRC"; then
      fail "S1: WeatherGraph.qml contains a scrolling element"
    else
      pass "S1: WeatherGraph.qml contains no scrolling element"
    fi
  fi

  # Read-only sizing: no runtime config writes from weather QML (D-54.4-04, T-54.4-09)
  write_hits="$(grep -nE 'writeAdapter|popup(Width|Height)Percent[[:space:]]*=[^=]' "$WEATHER_DIR"/*.qml 2>/dev/null || true)"
  if [[ -z "$write_hits" ]]; then
    pass "S1: zero writeAdapter calls or popup-percent assignments in weather QML"
  else
    fail "S1: runtime config write found in weather QML: $write_hits"
  fi

  if [[ -s "$BASE_CARD" ]] && grep -qE '^[[:space:]]*clip:[[:space:]]*true' "$BASE_CARD"; then
    pass "S1: WeatherBaseCard.qml keeps clip: true"
  else
    fail "S1: WeatherBaseCard.qml lost clip: true"
  fi

  # Re-clamp on late size resolution (POPUP-01, Pitfall 4)
  if [[ -s "$STYLED_POPUP_SRC" ]]; then
    reclamp_block="$(grep -A8 -E 'target:[[:space:]]*popupBackground' "$STYLED_POPUP_SRC" || true)"
    if [[ -n "$reclamp_block" ]] \
      && grep -qE 'onImplicitWidthChanged\(\)[[:space:]]*\{[[:space:]]*popupWindow\.updateLockedMargins\(\)' <<<"$reclamp_block" \
      && grep -qE 'onImplicitHeightChanged\(\)[[:space:]]*\{[[:space:]]*popupWindow\.updateLockedMargins\(\)' <<<"$reclamp_block"; then
      pass "S1: StyledPopup.qml re-clamps on popupBackground implicit size change (POPUP-01)"
    else
      fail "S1: StyledPopup.qml re-clamps on popupBackground implicit size change (POPUP-01)"
    fi
    for needle in 'property int hoverOpenDelayMs: 1000' 'interval: 200'; do
      if grep -qF "$needle" "$STYLED_POPUP_SRC"; then
        pass "S1: StyledPopup.qml keeps '$needle' (hover intent contract)"
      else
        fail "S1: StyledPopup.qml lost '$needle'"
      fi
    done
  fi

  # Repository integrity
  if git diff --quiet "$PHASE_BASE" -- "$WIND_CARD_REL" 2>/dev/null; then
    pass "S1: WeatherWindCard.qml unchanged since phase base $PHASE_BASE (D-54.4-01)"
  else
    fail "S1: WeatherWindCard.qml differs from phase base $PHASE_BASE"
  fi

  vendor_churn="$(git status --porcelain -- vendor/dots-hyprland 2>/dev/null || true)"
  if [[ -z "$vendor_churn" ]]; then
    pass "S1: vendor/dots-hyprland has zero modifications"
  else
    fail "S1: vendor/dots-hyprland contains changes: $vendor_churn"
  fi

  # Strict repository verification (full mode only)
  if [[ "$QUICK_MODE" -eq 0 ]]; then
    info "S1: Running strict repository verification (arch/dots-hyprland.sh verify --strict)..."
    set +e
    verify_out="$(./arch/dots-hyprland.sh verify --strict 2>&1)"
    verify_rc=$?
    set -e
    if [[ "$verify_rc" -eq 0 ]]; then
      pass "S1: ./arch/dots-hyprland.sh verify --strict passed with zero findings"
    else
      issue_lines="$(grep -E '^\[(FAIL|FINDING)\]' <<<"$verify_out" | sort -u || true)"
      if [[ -z "$issue_lines" ]]; then
        fail "S1: ./arch/dots-hyprland.sh verify --strict exited $verify_rc without a FAIL/FINDING line"
      else
        scoped_fail=0
        while IFS= read -r vline; do
          [[ -n "$vline" ]] || continue
          if [[ "$vline" == *"/.config/quickshell/"* ]]; then
            # A dangling link from a linked worktree run is pending merge, not broken.
            if [[ "$IN_LINKED_WORKTREE" -eq 1 && "$vline" == *"dangling symlink into repo"* ]]; then
              link_rel="${vline##*/.dotfiles/}"
              if [[ "$link_rel" == "$WEATHER_REL/"* && -s "$REPO_ROOT/$link_rel" ]]; then
                finding "S1: strict verify (linked worktree, pending merge): $vline"
                continue
              fi
            fi
            fail "S1: strict verify (quickshell scope): $vline"
            scoped_fail=1
          else
            finding "S1: strict verify reports a pre-existing issue outside the quickshell scope of this phase: $vline"
          fi
        done <<<"$issue_lines"
        if [[ "$scoped_fail" -eq 0 ]]; then
          pass "S1: strict verify reports no failure inside the quickshell deploy scope"
        fi
      fi
    fi
  else
    info "S1: quick mode active; skipped strict repository verification"
  fi
fi

# ===========================================================================
# Section 2: Popup sizing math (D-54.4-03, T-54.4-01)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Popup sizing math (D-54.4-03, T-54.4-01) ---"
  read -r -d '' S2_JS <<'JS' || true
const pct = [[19, 20], [20, 20], [21, 21], [99, 99], [100, 100], [101, 100], [-5, 20], [200, 100], ["60", 60]];
for (const [input, want] of pct) {
  ok(G.sanePercent(input, 50) === want, "S2: sanePercent(" + JSON.stringify(input) + ") = " + want);
}
for (const bad of [NaN, undefined, "abc", null, Infinity]) {
  ok(G.sanePercent(bad, 50) === 50, "S2: sanePercent(" + String(bad) + ") falls back to the 50 default");
}

function size(w, h, wp, hp, o) { return G.popupContentSize(w, h, wp, hp, o || {}); }
ok(same(size(1920, 1080, 50, 50), { width: 920, height: 500 }), "S2: popupContentSize 1920x1080 50/50 = 920x500");
ok(same(size(3440, 1440, 50, 50), { width: 1680, height: 680 }), "S2: popupContentSize 3440x1440 50/50 = 1680x680 (host ultrawide)");
ok(same(size(1280, 720, 50, 50), { width: 860, height: 320 }), "S2: popupContentSize 1280x720 50/50 = 860x320 (900px outer minimum)");
ok(size(1799, 1080, 50, 50).width === 860, "S2: 50% of a 1799px screen gives content width 860");
ok(size(1800, 1080, 50, 50).width === 860, "S2: 50% of a 1800px screen gives content width 860");
ok(size(1802, 1080, 50, 50).width === 861, "S2: 50% of a 1802px screen gives content width 861");
ok(size(880, 1080, 50, 50).width === 830, "S2: on an 880px screen the screen clamp wins (content width 830)");
ok(size(1920, 1080, 50, 50, { minContentH: 700 }).height === 700, "S2: minContentH 700 beats the 50% height on a 1080 screen");
ok(size(1920, 1080, 50, 50, { minContentH: 2000 }).height === 990, "S2: minContentH 2000 is clamped to 1080-40-10-40 = 990");
ok(same(size(NaN, -1, 50, 50), { width: 920, height: 500 }), "S2: a non-finite or non-positive screen falls back to 1920x1080");
ok(same(size(1920, 1080, "abc", undefined), { width: 920, height: 500 }), "S2: garbage percents fall back to 50/50");

// Property test over 500 random screens and percents: integer output, never above the clamp.
const r = rng(5440);
let intOk = true;
let clampOk = true;
let firstBad = "";
for (let k = 0; k < 500; ++k) {
  const w = Math.round(320 + r() * 7360);
  const h = Math.round(240 + r() * 4080);
  const wp = r() < 0.1 ? [NaN, -50, 500, "x", null][k % 5] : r() * 140 - 20;
  const hp = r() < 0.1 ? [NaN, -50, 500, "x", null][k % 5] : r() * 140 - 20;
  const o = { chrome: 40, edgeGap: 5, barHeight: 40, minOuterW: 900, minContentH: Math.round(r() * 1500) };
  const s = G.popupContentSize(w, h, wp, hp, o);
  if (!Number.isInteger(s.width) || !Number.isInteger(s.height)) {
    intOk = false;
    firstBad = firstBad || JSON.stringify({ w, h, wp, hp, s });
  }
  const maxW = Math.max(0, w - 2 * o.edgeGap - o.chrome);
  const maxH = Math.max(0, h - o.barHeight - 2 * o.edgeGap - o.chrome);
  if (s.width > Math.round(maxW) || s.height > Math.round(maxH) || s.width < 0 || s.height < 0) {
    clampOk = false;
    firstBad = firstBad || JSON.stringify({ w, h, wp, hp, s, maxW, maxH });
  }
}
ok(intOk, "S2: popupContentSize returns integer width and height over 500 random inputs" + (intOk ? "" : " " + firstBad));
ok(clampOk, "S2: popupContentSize never exceeds the screen clamp over 500 random inputs" + (clampOk ? "" : " " + firstBad));
ok(G.MIN_OUTER_W === 900, "S2: MIN_OUTER_W is 900 (D-54.4-03)");
JS
  run_node_section "S2" "$S2_JS"
fi

# ===========================================================================
# Section 3: Palette and contrast (D-54.4-11)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Palette and contrast (D-54.4-11) ---"
  read -r -d '' S3_JS <<'JS' || true
ok(same(G.TEMP_RAMP.map(function (a) { return [a.v, a.color]; }), [[20, "#64b5f6"], [28, "#ffb300"], [34, "#ef5350"]]),
   "S3: TEMP_RAMP is exactly 20 #64b5f6, 28 #ffb300, 34 #ef5350 (D-54.4-14, PA-10)");

function lum(hex) {
  const n = parseInt(hex.replace("#", ""), 16);
  const c = [(n >> 16) & 255, (n >> 8) & 255, n & 255].map(function (v) {
    const s = v / 255;
    return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
}
function contrast(a, b) {
  const la = lum(a);
  const lb = lum(b);
  return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
}
ok(near(contrast("#ffffff", "#000000"), 21, 0.01), "S3: WCAG contrast helper self-check (white on black = 21)");

// Colours locked verbatim by CONTEXT (D-54.4-23/28/29/31): below 3:1 is a FINDING, never a silent change.
const LOCKED = ["#90caf9", "#42a5f5", "#2979ff", "#26c6da", "#ffffff", "#66bb6a", "#ffee58", "#ffa726",
                "#ef5350", "#ab47bc", "#c2185b", "#ffb300", "#b0bec5"];
const SURFACES = ["#1f2020", "#292a2a"];
const HEX = /^#[0-9a-fA-F]{6}$/;

const colours = [];
for (const key of Object.keys(G)) {
  const v = G[key];
  if (typeof v === "string" && HEX.test(v)) colours.push([key, v.toLowerCase()]);
  if (Array.isArray(v)) {
    v.forEach(function (e, i) {
      if (e && typeof e === "object" && typeof e.color === "string" && HEX.test(e.color)) colours.push([key + "[" + i + "]", e.color.toLowerCase()]);
      if (typeof e === "string" && HEX.test(e)) colours.push([key + "[" + i + "]", e.toLowerCase()]);
    });
  }
}
ok(colours.length >= 3, "S3: WeatherGraphMath.js exposes its fixed colours (" + colours.length + " found)");
for (const [name, hex] of colours) {
  for (const surf of SURFACES) {
    const c = contrast(hex, surf);
    const tag = name + " " + hex + " on " + surf + " = " + c.toFixed(2);
    if (c >= 3) {
      ok(true, "S3: contrast " + tag + " (>= 3:1)");
    } else if (LOCKED.indexOf(hex) >= 0) {
      finding("S3: locked CONTEXT colour below 3:1: " + tag + " (D-54.4-11, Pitfall 11)");
    } else {
      ok(false, "S3: planner-chosen colour below 3:1: " + tag);
    }
  }
}

// comfortWord boundaries (D-54.4-20)
const comfort = [[15, "Comfortable"], [16, "Humid"], [20, "Humid"], [21, "Muggy"], [23, "Muggy"], [24, "Oppressive"],
                 [NaN, ""], [null, ""]];
for (const [dew, want] of comfort) {
  ok(G.comfortWord(dew) === want, "S3: comfortWord(" + String(dew) + ") = " + JSON.stringify(want) + " (D-54.4-20)");
}

// tooltipLines("temp") on the 25-slot fixture (D-54.4-12/19)
const ttl = mkTimeline();
const s12 = ttl[12];
const tNow = G.tooltipLines("temp", ttl, 12);
ok(tNow.length >= 1 && tNow[0].lead === "Now", "S3: tooltipLines(temp, fixture, 12) line 1 lead is Now");
ok(tNow.length >= 1 && tNow[0].icon === s12.glyph, "S3: tooltipLines(temp) line 1 icon is the slot condition glyph");
const tUn = G.tooltipLines("temp", ttl, 0);
ok(tUn.length === 1 && tUn[0].text === "No data" && tUn[0].icon === "", "S3: tooltipLines(temp) on the unavailable index 0 is one No data line");
ok(same(G.tooltipLines("temp", ttl, -1), []) && same(G.tooltipLines("temp", ttl, 25), []), "S3: tooltipLines(temp) at index -1 and 25 is []");
ok(same(G.tooltipLines("temp", null, 3), []) && same(G.tooltipLines("temp", [null], 0), []), "S3: tooltipLines tolerates a null timeline and a null slot");

// Locked D-54.4-19 lines, built from the fixture values of slot 12
const lockedL1 = s12.desc + " · " + G.comfortWord(s12.thermal.dewPointC);
const lockedL2 = Math.round(s12.thermal.tempC) + "° (" + Math.round(s12.thermal.feelsLikeC) + "°) · Dew " + Math.round(s12.thermal.dewPointC) + "°";
const rh = Math.round(s12.moisture.humidity) + "% RH";
const L2_RE = /^\d+° \(\d+°\) · Dew \d+°$/;
const L2_RH_RE = /^\d+° \(\d+°\) · Dew \d+° · \d+% RH$/;

// PA-1: the user-approved humidity placement, selected by the marker in WeatherGraphMath.js
const gmText = fs.readFileSync(process.argv[1], "utf8");
const markers = gmText.match(/\/\/ PA-1 option: [A-Za-z0-9-]+/g) || [];
const optionId = markers.length === 1 ? markers[0].replace("// PA-1 option: ", "") : "";
ok(markers.length === 1, "S3: PA-1 exactly one '// PA-1 option:' marker in WeatherGraphMath.js (found " + markers.length + ")");
const KNOWN = ["l1-suffix", "l2-suffix", "line3"];
ok(KNOWN.indexOf(optionId) >= 0, "S3: PA-1 option id '" + optionId + "' is one of " + KNOWN.join(", "));
if (optionId === "l1-suffix") {
  ok(tNow.length === 2 && tNow[0].text === lockedL1 + " · " + rh && L2_RE.test(tNow[1].text) && tNow[1].text === lockedL2,
     "S3: PA-1 l1-suffix: 2 lines, L1 '" + lockedL1 + " · " + rh + "', L2 '" + lockedL2 + "' (got " + JSON.stringify(tNow.map(function (l) { return l.text; })) + ")");
} else if (optionId === "l2-suffix") {
  ok(tNow.length === 2 && tNow[0].text === lockedL1 && L2_RH_RE.test(tNow[1].text) && tNow[1].text === lockedL2 + " · " + rh,
     "S3: PA-1 l2-suffix: 2 lines, L1 '" + lockedL1 + "', L2 '" + lockedL2 + " · " + rh + "'");
} else if (optionId === "line3") {
  ok(tNow.length === 3 && tNow[0].text === lockedL1 && L2_RE.test(tNow[1].text) && tNow[2].lead === "" && tNow[2].icon === "humidity_percentage" && tNow[2].text === rh,
     "S3: PA-1 line3: 3 lines, L1 '" + lockedL1 + "', L2 '" + lockedL2 + "', L3 humidity_percentage '" + rh + "'");
} else {
  ok(false, "S3: PA-1 no humidity-shape assertion ran (missing, duplicate or unknown option marker)");
}
ok(tNow.length >= 2 && tNow[1].icon === "thermostat", "S3: tooltipLines(temp) line 2 icon is thermostat (D-54.4-19)");

// Null humidity keeps exactly the locked D-54.4-19 lines
const noRh = ttl.slice();
noRh[12] = Object.assign({}, s12, { moisture: Object.assign({}, s12.moisture, { humidity: null }) });
const tNoRh = G.tooltipLines("temp", noRh, 12);
ok(tNoRh.length === 2 && tNoRh[0].text === lockedL1 && L2_RE.test(tNoRh[1].text) && tNoRh[1].text === lockedL2,
   "S3: PA-1 null humidity gives exactly the locked D-54.4-19 lines (" + JSON.stringify(tNoRh.map(function (l) { return l.text; })) + ")");

// Graphs 2 and 3 start with the shared header line (plans 06/07 append their lines)
for (const kind of ["rainwind", "airuv"]) {
  const t = G.tooltipLines(kind, ttl, 12);
  ok(t.length >= 1 && t[0].lead === "Now" && t[0].text.indexOf(s12.desc) === 0, "S3: tooltipLines(" + kind + ") starts with the shared header line");
}
JS
  run_node_section "S3" "$S3_JS"

  # Fixed hex colours of the phase live only in WeatherGraphMath.js (D-54.4-11)
  for src in "$GRAPH_SRC" "$POPUP_SRC"; do
    [[ -s "$src" ]] || continue
    if grep -qE '\|\|[[:space:]]*"#' "$src"; then
      fail "S3: $(basename "$src") carries a '|| \"#...\"' colour fallback"
    else
      pass "S3: $(basename "$src") has no '|| \"#...\"' colour fallback"
    fi
  done
fi

# ===========================================================================
# Section 4: Axis labels, gradient stops and scales
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Axis labels, gradient stops and scales (D-54.4-05/06/14) ---"
  read -r -d '' S4_JS <<'JS' || true
const clocks = [[0, "12AM"], [1, "1AM"], [11, "11AM"], [12, "12PM"], [13, "1PM"], [23, "11PM"]];
for (const [h, want] of clocks) ok(G.clock12(h) === want, "S4: clock12(" + h + ") = " + want);
ok(same(G.axisTicks(25, 4), [0, 4, 8, 12, 16, 20, 24]), "S4: axisTicks(25, 4) = 0,4,...,24 (7 ticks, D-54.4-06)");
ok(same(G.axisTicks(24, 3), [0, 3, 6, 9, 12, 15, 18, 21]), "S4: axisTicks(24, 3) for the hourly fallback");
ok(same(G.axisTicks(0, 4), []), "S4: axisTicks(0, 4) is empty");

const tl = mkTimeline();
ok(G.axisTickLabel(12, tl[12], true) === "Now", "S4: axisTickLabel(12, slot, true) = Now");
ok(G.axisTickLabel(0, tl[0], true) === "3AM", "S4: axisTickLabel(0) on the fixture is 3AM (12-hour clock)");
ok(G.axisTickLabel(24, tl[24], true) === "3AM", "S4: axisTickLabel(24) on the fixture is 3AM");
ok(G.axisTickLabel(12, tl[12], false) === "3PM", "S4: axisTickLabel(12) outside the 25-slot timeline is a clock label");
let noRelative = true;
for (const i of G.axisTicks(25, 4)) {
  if (/[+-]\d+h/.test(G.axisTickLabel(i, tl[i], true))) noRelative = false;
}
ok(noRelative, "S4: no axis tick carries a relative +Nh/-Nh tag (D-54.4-06)");

ok(G.slotHour({ time: "300" }) === 3, "S4: raw-time fallback parses \"300\" as 3");
ok(G.slotHour({ time: "0" }) === 0, "S4: raw-time fallback parses \"0\" as 0");
ok(G.slotHour({ time: "1200" }) === 12, "S4: raw-time fallback parses \"1200\" as 12");
ok(G.slotHour({ hourNum: 17, time: "300" }) === 17, "S4: hourNum wins over raw time");

// smoothRampStops property test: offsets in [0,1], non-decreasing, first 0, last 1.
function stopsOk(stops) {
  if (!Array.isArray(stops) || stops.length < 2) return false;
  if (stops[0].offset !== 0 || stops[stops.length - 1].offset !== 1) return false;
  for (let i = 0; i < stops.length; ++i) {
    const o = stops[i].offset;
    if (!(o >= 0 && o <= 1)) return false;
    if (i > 0 && o < stops[i - 1].offset) return false;
    if (!/^#[0-9a-f]{6}$/i.test(stops[i].color)) return false;
  }
  return true;
}
const pairs = [[15, 5], [19, 10], [45, 36], [60, 35], [34, 20], [28, 28], [30, 25]];
const r = rng(5444);
for (let k = 0; k < 200 - pairs.length; ++k) {
  const a = Math.round(-20 + r() * 70);
  const b = Math.round(-20 + r() * 70);
  pairs.push([Math.max(a, b), Math.min(a, b)]);
}
let allOk = true;
let bad = "";
for (const [top, bottom] of pairs) {
  const s = G.smoothRampStops(G.TEMP_RAMP, top, bottom);
  if (!stopsOk(s)) {
    allOk = false;
    bad = bad || JSON.stringify({ top, bottom, s });
  }
}
ok(allOk, "S4: smoothRampStops over 200 (vTop, vBottom) pairs incl. all-below-20 and all-above-34: offsets in [0,1], sorted, 0..1" + (allOk ? "" : " " + bad));
const below = G.smoothRampStops(G.TEMP_RAMP, 15, 5);
ok(below.length === 2 && below[0].color === "#64b5f6" && below[1].color === "#64b5f6", "S4: bounds entirely below 20 give two pure-blue endpoint stops");
const above = G.smoothRampStops(G.TEMP_RAMP, 45, 36);
ok(above.length === 2 && above[0].color === "#ef5350" && above[1].color === "#ef5350", "S4: bounds entirely above 34 give two pure-red endpoint stops");
const mid = G.smoothRampStops(G.TEMP_RAMP, 34, 25);
ok(mid.some(function (s) { return s.color === "#ffb300" && s.offset > 0 && s.offset < 1; }), "S4: the 28 degree amber anchor sits strictly inside a 25..34 range");
ok(G.rampColorAt(G.TEMP_RAMP, 24) === G.lerpColor("#64b5f6", "#ffb300", 0.5), "S4: rampColorAt interpolates smoothly between anchors (24 is halfway blue to amber)");

// tempScale: floor/ceil, skips unavailable, flat -> min+1, all-unavailable -> empty.
function slot(t, f, un) {
  return { isHistoricalUnavailable: !!un, thermal: { tempC: t, feelsLikeC: f } };
}
ok(same(G.tempScale([slot(25.4, 26.1), slot(33.6, 30)]), { min: 25, max: 34, empty: false }), "S4: tempScale floors the min and ceils the max");
ok(same(G.tempScale([slot(99, 99, true), slot(25, 26), slot(30, 31)]), { min: 25, max: 31, empty: false }), "S4: tempScale skips historical-unavailable slots");
ok(same(G.tempScale([slot(null, null, true), slot(null, null, true)]), { min: 0, max: 1, empty: true }), "S4: tempScale flags an all-unavailable input with empty:true");
ok(same(G.tempScale([slot(27, 27), slot(27, 27)]), { min: 27, max: 28, empty: false }), "S4: tempScale turns a flat series into a min+1 range");
ok(same(G.tempScale([]), { min: 0, max: 1, empty: true }), "S4: tempScale of an empty array is empty");
const fx = G.tempScale(tl);
ok(fx.min === 25 && fx.max === 36 && !fx.empty, "S4: tempScale over the 25-slot fixture is 25..36");

// valueToY (Pitfall 7: flat scale never divides by zero)
ok(G.valueToY(10, 0, 10, 16, 260) === 16 && G.valueToY(0, 0, 10, 16, 260) === 260, "S4: valueToY maps hi to top and lo to bottom");
ok(G.valueToY(5, 0, 0, 16, 260) === 260, "S4: valueToY on a flat zero scale draws at the bottom");
ok(G.valueToY(5, 5, 5, 16, 260) === 138, "S4: valueToY on a flat non-zero scale draws at the vertical centre");
ok(same(G.computeScales("rainwind", tl), {}) && same(G.computeScales("airuv", tl), {}), "S4: computeScales returns an empty object for kinds owned by plans 06/07");
ok(G.computeScales("temp", tl).temp.max === 36, "S4: computeScales(temp) carries tempScale");
JS
  run_node_section "S4" "$S4_JS"
fi

# ===========================================================================
# Section 5: Draw functions against a recording mock canvas
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Draw functions against a recording mock canvas (D-54.4-13/15/17) ---"
  read -r -d '' S5_JS <<'JS' || true
const tl = mkTimeline();
const geom = geomFor(25);
const scales = G.computeScales("temp", tl);
const m = mockCtx();
let threw = null;
try { G.drawTemp(m.ctx, geom, tl, scales); } catch (e) { threw = e; }
ok(threw === null, "S5: drawTemp on the 25-slot fixture does not throw" + (threw ? " (" + threw + ")" : ""));
ok(calls(m.log, "bezierCurveTo").length >= 1, "S5: drawTemp records at least one bezierCurveTo (monotone spline, D-54.4-13)");
ok(calls(m.log, "fillRect").length === 0, "S5: drawTemp records zero fillRect (no band, fill or rain bars, D-54.4-15/17)");
ok(calls(m.log, "fill").length === 0, "S5: drawTemp records zero fill calls");
const stops = m.log.filter(function (e) { return e[0] === "stop"; });
ok(stops.length >= 2 && stops.every(function (e) { return e[1] >= 0 && e[1] <= 1; }), "S5: every addColorStop offset lies in [0,1] (Pitfall 1)");
const grads = calls(m.log, "createLinearGradient");
ok(grads.length === 1 && grads[0][1] === 0 && grads[0][2] === geom.plotTop && grads[0][3] === 0 && grads[0][4] === geom.plotBottom,
   "S5: one vertical gradient from plotTop to plotBottom (D-54.4-14)");

const firstAvail = 3;
const minX = geom.plotLeft + firstAvail * geom.slotW;
let xOk = true;
for (const e of m.log) {
  if (e[0] === "moveTo" && e[1] < minX) xOk = false;
  if (e[0] === "bezierCurveTo" && (e[1] < minX || e[3] < minX || e[5] < minX)) xOk = false;
}
ok(xOk, "S5: no path point lies left of plotLeft + firstAvailableIndex*slotW (unavailable slots never drawn, Pitfall 5)");

const dashSets = calls(m.log, "setLineDash");
ok(dashSets.some(function (e) { return same(e[1], [4, 3]); }), "S5: the feels-like spline is dashed [4,3] (D-54.4-15)");
const alphaSets = m.log.filter(function (e) { return e[0] === "set" && e[1] === "globalAlpha"; });
ok(alphaSets.some(function (e) { return e[2] === 0.7; }), "S5: the feels-like spline uses globalAlpha 0.7 (PA-12)");
ok(calls(m.log, "stroke").length === 2, "S5: one temperature run and one feels-like run are stroked");
ok(calls(m.log, "save").length === calls(m.log, "restore").length, "S5: save/restore calls are balanced");

const k = mockCtx();
let kThrew = null;
try { G.drawKind(k.ctx, "temp", geom, tl, scales); } catch (e) { kThrew = e; }
ok(kThrew === null && calls(k.log, "bezierCurveTo").length === calls(m.log, "bezierCurveTo").length, "S5: drawKind(\"temp\") dispatches to drawTemp");
for (const kind of ["rainwind", "airuv", "bogus"]) {
  const q = mockCtx();
  let t = null;
  try { G.drawKind(q.ctx, kind, geom, tl, {}); } catch (e) { t = e; }
  ok(t === null, "S5: drawKind(\"" + kind + "\") does not throw");
}

// Degenerate inputs: zero stroke calls, no throw (T-54.4-02).
const one = mkTimeline()[12];
const cases = [["an empty slot array", []], ["a single-slot array", [one]], ["[null, slot, null]", [null, one, null]], ["an all-null array", [null, null, null]]];
for (const [label, input] of cases) {
  for (const fn of ["drawTemp", "drawKind", "computeScales"]) {
    const d = mockCtx();
    let t = null;
    try {
      if (fn === "drawTemp") G.drawTemp(d.ctx, geomFor(Math.max(1, input.length)), input, G.computeScales("temp", input));
      else if (fn === "drawKind") G.drawKind(d.ctx, "temp", geomFor(Math.max(1, input.length)), input, G.computeScales("temp", input));
      else G.computeScales("temp", input);
    } catch (e) { t = e; }
    ok(t === null && calls(d.log, "stroke").length === 0, "S5: " + fn + " on " + label + " records no stroke and does not throw");
  }
}
const allUn = mkTimeline({ unavailable: 25 });
const u = mockCtx();
G.drawTemp(u.ctx, geomFor(25), allUn, G.computeScales("temp", allUn));
ok(calls(u.log, "stroke").length === 0, "S5: an all-unavailable timeline draws nothing");

// normalizeSlots on a raw WWO hourly sample (Weather.hourly fallback)
const raw = [];
for (let h = 0; h <= 2400; h += 300) {
  raw.push({ time: String(h === 2400 ? 24 : h), tempC: String(20 + h / 300), FeelsLikeC: String(21 + h / 300), DewPointC: "18",
             chanceofrain: "40", precipMM: "0.4", windspeedKmph: "14", WindGustKmph: "22", winddirDegree: "340",
             winddir16Point: "NNW", pressure: "1009", visibility: "10", uvIndex: "6", shortrad: "512.5",
             weatherDesc: [{ value: "Partly cloudy" }], air_quality: { "us-epa-index": "2", pm2_5: "34.1" } });
}
const ns = G.normalizeSlots(raw);
ok(ns.length === 8, "S5: normalizeSlots drops the \"24\" item from a raw WWO hourly sample (8 of 9 kept)");
ok(ns[1].hourNum === 3 && ns[0].hourNum === 0 && ns[4].hourNum === 12, "S5: normalizeSlots derives hourNum from raw time");
ok(ns[1].thermal.tempC === 21 && ns[1].thermal.feelsLikeC === 22 && ns[1].moisture.precipMM === 0.4 && ns[1].wind.dir16 === "NNW",
   "S5: normalizeSlots parses raw fields with the Weather.qml int/float rules");
ok(ns[1].desc === "Partly cloudy" && ns[1].glyph === "" && ns[1].aqi.epaIndex === 2 && ns[1].solar.shortRad === 512.5,
   "S5: normalizeSlots carries desc, empty glyph, epaIndex and shortRad");
const many = [];
for (let i = 0; i < 30; ++i) many.push({ time: String((i % 8) * 300), tempC: "25" });
ok(G.normalizeSlots(many).length === 24, "S5: normalizeSlots caps raw input at 24 items");
const copy = G.normalizeSlots(tl);
ok(copy !== tl && copy.length === 25 && copy[12] === tl[12], "S5: normalizeSlots returns timeline slots as a shallow copy");
ok(same(G.normalizeSlots(null), []) && same(G.normalizeSlots(undefined), []), "S5: normalizeSlots tolerates null/undefined");
const rs = mockCtx();
G.drawTemp(rs.ctx, geomFor(ns.length), ns, G.computeScales("temp", ns));
ok(calls(rs.log, "bezierCurveTo").length >= 1, "S5: drawTemp draws the normalised hourly fallback");

// markerPoints: hover markers are data, drawn as QML items (zero canvas repaint, D-54.4-07)
const mp = G.markerPoints("temp", tl, 12, geom, scales);
ok(mp.length === 2, "S5: markerPoints(temp, fixture, 12) gives 2 points (temperature and feels-like)");
ok(mp.every(function (p) { return p.y >= geom.plotTop && p.y <= geom.plotBottom; }), "S5: markerPoints y values lie in [plotTop, plotBottom]");
ok(mp.length === 2 && mp[0].y === G.valueToY(tl[12].thermal.tempC, scales.temp.min, scales.temp.max, geom.plotTop, geom.plotBottom),
   "S5: markerPoints temperature y equals valueToY on scales.temp");
ok(mp.every(function (p) { return /^#[0-9a-f]{6}$/i.test(p.color); }), "S5: markerPoints colours come from the TEMP_RAMP ramp");
ok(same(G.markerPoints("temp", tl, 0, geom, scales), []), "S5: markerPoints at the unavailable index 0 is []");
ok(same(G.markerPoints("temp", tl, -1, geom, scales), []) && same(G.markerPoints("temp", tl, 25, geom, scales), []), "S5: markerPoints out of range is []");
ok(same(G.markerPoints("temp", tl, 12, null, scales), []), "S5: markerPoints without geometry is []");
JS
  run_node_section "S5" "$S5_JS"

  # Hover and tooltip-overlay contracts (D-54.4-07/08, T-54.4-03/07/11)
  # qml_block FILE ID: prints the QML object block that declares 'id: ID', found by brace depth.
  qml_block() {
    awk -v id="$2" '
      { lines[NR] = $0 }
      END {
        depth = 0
        for (i = 1; i <= NR; i++) {
          pre[i] = depth
          t = lines[i]
          o = gsub(/\{/, "", t)
          c = gsub(/\}/, "", t)
          depth += o - c
          post[i] = depth
        }
        idl = 0
        for (i = 1; i <= NR; i++) {
          if (lines[i] ~ ("^[[:space:]]*id:[[:space:]]*" id "[[:space:]]*$")) { idl = i; break }
        }
        if (idl == 0) exit 0
        d = pre[idl]
        for (s = idl - 1; s >= 1; s--) {
          if (pre[s] <= d - 1 && post[s] >= d) break
        }
        if (s < 1) exit 0
        for (e = s; e <= NR; e++) {
          print lines[e]
          if (e > s && post[e] <= d - 1) break
        }
      }' "$1"
  }
  noncomment() {
    grep -v '^[[:space:]]*//' "$1" || true
  }

  if [[ -s "$GRAPH_SRC" && -s "$POPUP_SRC" ]]; then
    hover_block="$(qml_block "$GRAPH_SRC" hoverMouse)"
    if [[ -z "$hover_block" ]]; then
      fail "S5: hoverMouse block not found in WeatherGraph.qml"
    else
      if head -1 <<<"$hover_block" | grep -qE 'MouseArea[[:space:]]*\{'; then
        pass "S5: hoverMouse is a MouseArea block (extracted by brace depth, $(wc -l <<<"$hover_block") lines)"
      else
        fail "S5: hoverMouse block does not open with 'MouseArea {'"
      fi
      if grep -q 'requestPaint' <<<"$hover_block"; then
        fail "S5: hoverMouse block calls requestPaint (hover must not repaint the canvas, T-54.4-07)"
      else
        pass "S5: hoverMouse block contains no requestPaint (zero-repaint hover, T-54.4-07)"
      fi
      if grep -qE 'hoverRequested\(' <<<"$hover_block"; then
        pass "S5: hoverMouse emits hoverRequested to the popup"
      else
        fail "S5: hoverMouse never emits hoverRequested"
      fi
    fi

    tip_block="$(qml_block "$POPUP_SRC" tooltipLayer)"
    if [[ -z "$tip_block" ]]; then
      fail "S5: tooltipLayer block not found in WeatherPopup.qml"
    else
      if grep -qE 'MouseArea|HoverHandler' <<<"$tip_block"; then
        fail "S5: tooltipLayer holds a MouseArea or HoverHandler (would block graph hover, T-54.4-11)"
      else
        pass "S5: tooltipLayer holds no MouseArea or HoverHandler (T-54.4-11)"
      fi
      st_count="$(grep -cE '^[[:space:]]*StyledText[[:space:]]*\{' <<<"$tip_block" || true)"
      pt_count="$(grep -cF 'textFormat: Text.PlainText' <<<"$tip_block" || true)"
      if [[ "$st_count" -ge 1 && "$pt_count" -ge "$st_count" ]]; then
        pass "S5: tooltipLayer text uses Text.PlainText on all $st_count StyledText items (T-54.4-03)"
      else
        fail "S5: tooltipLayer StyledText count $st_count but Text.PlainText count $pt_count (T-54.4-03)"
      fi
      if grep -qF 'GM.tooltipLines(' <<<"$tip_block"; then
        pass "S5: tooltipLayer text comes from GM.tooltipLines"
      else
        fail "S5: tooltipLayer does not read GM.tooltipLines"
      fi
    fi

    graph_writes="$(noncomment "$GRAPH_SRC" | grep -cE 'hoverSlot[[:space:]]*=[^=]' || true)"
    if [[ "$graph_writes" -eq 0 ]]; then
      pass "S5: WeatherGraph.qml never assigns hoverSlot (popup is the only writer, D-54.4-07)"
    else
      fail "S5: WeatherGraph.qml assigns hoverSlot $graph_writes time(s)"
    fi
    popup_writes="$(noncomment "$POPUP_SRC" | grep -cE 'hoverSlot[[:space:]]*=[^=]' || true)"
    if [[ "$popup_writes" -ge 1 ]]; then
      pass "S5: WeatherPopup.qml assigns hoverSlot ($popup_writes site(s))"
    else
      fail "S5: WeatherPopup.qml never assigns hoverSlot"
    fi
    if grep -qF 'signal hoverRequested(int idx)' "$GRAPH_SRC"; then
      pass "S5: WeatherGraph.qml declares signal hoverRequested(int idx)"
    else
      fail "S5: WeatherGraph.qml is missing signal hoverRequested(int idx)"
    fi
    hr_count="$(awk '/onHoverRequested/ { n++ } END { print n + 0 }' "$POPUP_SRC")"
    if [[ "$hr_count" -eq 3 ]]; then
      pass "S5: WeatherPopup.qml handles onHoverRequested on all 3 graph instances"
    else
      fail "S5: expected 3 onHoverRequested handlers in WeatherPopup.qml, found $hr_count"
    fi
    for src in "$GRAPH_SRC" "$POPUP_SRC"; do
      if grep -qE 'map(To|From)(Item|Global|Scene)[[:space:]]*\(' "$src"; then
        fail "S5: $(basename "$src") uses an item-mapping call (not reactive, D-54.4-08)"
      else
        pass "S5: $(basename "$src") has zero item-mapping calls (D-54.4-08)"
      fi
    done
    if grep -qiE 'id:[[:space:]]*[A-Za-z0-9_]*tooltip' "$GRAPH_SRC"; then
      fail "S5: WeatherGraph.qml owns a tooltip item (tooltips belong to the popup overlay, D-54.4-08)"
    else
      pass "S5: WeatherGraph.qml owns no tooltip item (D-54.4-08)"
    fi
    # qmlformat may wrap the if body onto its own line, so match on the joined source.
    popup_joined="$(tr '\n' ' ' <"$POPUP_SRC" | tr -s '[:space:]' ' ')"
    if grep -qE 'function onActiveChanged\(\) \{ if \(!root\.active\) root\.hoverSlot = -1;?' <<<"$popup_joined"; then
      pass "S5: closing the popup resets hoverSlot (if (!root.active) root.hoverSlot = -1)"
    else
      fail "S5: WeatherPopup.qml lacks the onActiveChanged hoverSlot reset"
    fi
    if grep -qF 'GlobalStates.activeInspectorCount++;' "$POPUP_SRC" \
      && grep -qF 'GlobalStates.activeInspectorCount = Math.max(0, GlobalStates.activeInspectorCount - 1);' "$POPUP_SRC"; then
      pass "S5: the activeInspectorCount increment and decrement handlers are intact"
    else
      fail "S5: the activeInspectorCount increment or decrement handler changed"
    fi
  fi
fi

finish
