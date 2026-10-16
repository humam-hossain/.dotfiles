#!/usr/bin/env bash
# ===========================================================================
# Phase 54.4: Modular Popup Inspector and Clean Card Layout Assert Harness
# Enforces: POPUP-01, POPUP-02, ASVS L1
# Decisions: D-54.4-01 through D-54.4-36 (sections grow per plan: 01, 03, 05, 06, 07)
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

// Replays a mockCtx log and returns every method call as {name, args, st}, where st is the
// context state (globalAlpha, font, fillStyle, ...) in force at that call, honouring save/restore.
function annotate(log) {
  const out = [];
  const stack = [];
  let st = { globalAlpha: 1 };
  for (const e of log) {
    if (e[0] === "set") {
      st[e[1]] = e[2];
      continue;
    }
    if (e[0] === "stop") continue;
    if (e[0] === "save") stack.push(Object.assign({}, st));
    if (e[0] === "restore") st = stack.length ? stack.pop() : { globalAlpha: 1 };
    out.push({ name: e[0], args: e.slice(1), st: Object.assign({}, st) });
  }
  return out;
}

// Fixed theme object standing in for WeatherGraph.qml theme() (QML passes Appearance tokens).
const THEME = { grid: "#444746", text: "#c4c7c5", shade: "#1f2020", now: "#a8c7fa" };
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

    # Legend row (D-54.4-09): fixed 18px height on every card, entries from GM.legendEntries
    legend_block="$(awk '
      /id: legendRow$/ { inb = 1 }
      inb { print }
      inb && /^    \}$/ { exit }' "$GRAPH_SRC")"
    if [[ -n "$legend_block" ]]; then
      pass "S1: WeatherGraph.qml contains id: legendRow"
    else
      fail "S1: WeatherGraph.qml is missing id: legendRow"
    fi
    if grep -qF 'Layout.preferredHeight: 18' <<<"$legend_block" && grep -qF 'Layout.maximumHeight: 18' <<<"$legend_block"; then
      pass "S1: legendRow has a fixed 18px height (preferred and maximum, D-54.4-09)"
    else
      fail "S1: legendRow lacks Layout.preferredHeight: 18 / Layout.maximumHeight: 18"
    fi
    if grep -qE 'Repeater[[:space:]]*\{' <<<"$legend_block" && grep -qF 'model: GM.legendEntries(root.graphKind)' <<<"$legend_block"; then
      pass "S1: legendRow holds a Repeater over GM.legendEntries(root.graphKind)"
    else
      fail "S1: legendRow Repeater model is not GM.legendEntries(root.graphKind)"
    fi
    legend_ln="$(grep -n 'id: legendRow' "$GRAPH_SRC" | head -1 | cut -d: -f1 || true)"
    area_ln="$(grep -n 'id: graphArea' "$GRAPH_SRC" | head -1 | cut -d: -f1 || true)"
    if [[ -n "$legend_ln" && -n "$area_ln" && "$legend_ln" -lt "$area_ln" ]]; then
      pass "S1: legendRow is declared above graphArea (first card-content child)"
    else
      fail "S1: legendRow is not declared above graphArea (legend=$legend_ln graphArea=$area_ln)"
    fi
    if grep -qF 'GM.drawKind(ctx, root.graphKind, root.geom(), root.validHours, root.scales, root.theme())' "$GRAPH_SRC"; then
      pass "S1: onPaint passes root.theme() as drawKind's fifth argument (backdrop and axis colours)"
    else
      fail "S1: onPaint does not pass root.theme() to GM.drawKind"
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
// PA-3: the EPA Very Unhealthy and Hazardous hexes are locked by D-54.4-28 and sit below 3:1 on
// the card surface. They stay exactly as locked and are reported, never failed.
const PA3 = ["#ab47bc", "#c2185b"];
const lowLocked = [];
for (const [name, hex] of colours) {
  for (const surf of SURFACES) {
    const c = contrast(hex, surf);
    const tag = name + " " + hex + " on " + surf + " = " + c.toFixed(2);
    if (c >= 3) {
      ok(true, "S3: contrast " + tag + " (>= 3:1)");
    } else if (PA3.indexOf(hex) >= 0) {
      lowLocked.push(name);
      finding("S3: PA-3 locked EPA colour below 3:1, kept as D-54.4-28 locks it: " + tag + " (lighter alternatives #ce93d8 / #ec407a offered at verify-work)");
    } else if (LOCKED.indexOf(hex) >= 0) {
      lowLocked.push(name);
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

// Graph 2 rain palette and tiers (D-54.4-23)
ok(same(G.RAIN_EDGES, [30, 60]) && same(G.RAIN_COLORS, ["#90caf9", "#42a5f5", "#2979ff"]),
   "S3: RAIN_EDGES 30,60 and RAIN_COLORS #90caf9, #42a5f5, #2979ff exactly (D-54.4-23)");
const rainCases = [[0, "#90caf9"], [29.9, "#90caf9"], [30, "#42a5f5"], [45, "#42a5f5"], [60, "#42a5f5"], [60.1, "#2979ff"], [100, "#2979ff"]];
for (const [v, want] of rainCases) {
  ok(typeof G.rainColor === "function" && G.rainColor(v) === want, "S3: rainColor(" + v + ") = " + want + " (D-54.4-23)");
}

// Graph 2 tooltip lines 1-2 (D-54.4-26, D-54.4-36)
const rw = G.tooltipLines("rainwind", ttl, 12);
const cloudSfx = " · Cloud " + Math.round(s12.moisture.cloudCover) + "%";
ok(rw.length >= 1 && rw[0].text === s12.desc + cloudSfx, "S3: tooltipLines(rainwind) line 1 is '" + s12.desc + cloudSfx + "' (D-54.4-36, got " + JSON.stringify(rw[0] && rw[0].text) + ")");
ok(rw.length >= 2 && rw[1].icon === "water_drop" && /^\d+% · \d+\.\d mm$/.test(rw[1].text),
   "S3: tooltipLines(rainwind) line 2 is water_drop '<rain>% · <mm> mm' with no Thunder/Snow at 0 (got " + JSON.stringify(rw[1] && rw[1].text) + ")");
ok(rw.length >= 2 && rw[1].text === Math.round(s12.moisture.rainProb) + "% · " + Number(s12.moisture.precipMM).toFixed(1) + " mm",
   "S3: tooltipLines(rainwind) line 2 values come from the slot rainProb and precipMM");
function withMoisture(extra) {
  const c = ttl.slice();
  c[12] = Object.assign({}, s12, { moisture: Object.assign({}, s12.moisture, extra) });
  return G.tooltipLines("rainwind", c, 12);
}
const th20 = withMoisture({ thunderProb: 20, snowProb: 0 });
ok(th20.length >= 2 && / · Thunder 20%$/.test(th20[1].text) && th20[1].text.indexOf("Snow") < 0,
   "S3: thunderProb 20, snowProb 0: line 2 ends ' · Thunder 20%' with no Snow (D-54.4-36, got " + JSON.stringify(th20[1] && th20[1].text) + ")");
const th20s5 = withMoisture({ thunderProb: 20, snowProb: 5 });
ok(th20s5.length >= 2 && / · Thunder 20% · Snow 5%$/.test(th20s5[1].text),
   "S3: thunderProb 20, snowProb 5: line 2 ends ' · Thunder 20% · Snow 5%' (Thunder before Snow)");
const sn5 = withMoisture({ thunderProb: 0, snowProb: 5 });
ok(sn5.length >= 2 && / · Snow 5%$/.test(sn5[1].text) && sn5[1].text.indexOf("Thunder") < 0, "S3: snowProb 5 alone: line 2 ends ' · Snow 5%' with no Thunder");
const cl75 = withMoisture({ cloudCover: 75 });
ok(cl75.length >= 1 && / · Cloud 75%$/.test(cl75[0].text), "S3: cloudCover 75 reads 'Cloud 75%' on line 1");
const cl0 = withMoisture({ cloudCover: 0 });
ok(cl0.length >= 1 && / · Cloud 0%$/.test(cl0[0].text), "S3: cloud cover is always shown on line 1, even at 0% (D-54.4-36)");
const rwUn = G.tooltipLines("rainwind", ttl, 0);
ok(rwUn.length === 1 && rwUn[0].text === "No data", "S3: tooltipLines(rainwind) on an unavailable slot is one No data line");

// Graph 2 wind, gust, visibility and mm palette (D-54.4-23, PA-13)
ok(same(G.VIS_EDGES, [1, 4, 10]) && same(G.VIS_COLORS, ["#ef5350", "#ffa726", "#ffee58", "#66bb6a"]),
   "S3: VIS_EDGES 1,4,10 and VIS_COLORS #ef5350, #ffa726, #ffee58, #66bb6a exactly (D-54.4-23)");
ok(G.WIND_COLOR === "#ffffff" && G.WIND_ALPHA === 0.9, "S3: WIND_COLOR #ffffff at WIND_ALPHA 0.9 (D-54.4-23)");
ok(G.MM_COLOR === "#26c6da" && G.MM_ALPHA === 0.6, "S3: MM_COLOR #26c6da at MM_ALPHA 0.6 (D-54.4-23)");
ok(G.BAR_CAP === 0.4, "S3: BAR_CAP 0.4 caps mm bars at 40% of the plot height (PA-13)");
const HAS_VIS = typeof G.visibilityTier === "function" && typeof G.visColor === "function";
const visCases = [[0, "Fog", "#ef5350"], [0.9, "Fog", "#ef5350"], [1, "Poor", "#ffa726"], [3.9, "Poor", "#ffa726"], [4, "Moderate", "#ffee58"],
                  [9.9, "Moderate", "#ffee58"], [10, "Good", "#66bb6a"], [12, "Good", "#66bb6a"]];
for (const [km, word, hex] of visCases) {
  ok(HAS_VIS && G.visibilityTier(km) === word && G.visColor(km) === hex, "S3: visibilityTier(" + km + ") = " + word + " and visColor = " + hex + " (D-54.4-26)");
}

// Graph 2 tooltip lines 3-4 (D-54.4-26)
ok(rw.length === 4, "S3: tooltipLines(rainwind, fixture, 12) has 4 lines (got " + rw.length + ")");
ok(rw.length === 4 && rw[2].icon === "air" && /^\d+ km\/h · G\d+ · [A-Z]{1,3} \d+°$/.test(rw[2].text),
   "S3: tooltipLines(rainwind) line 3 is air '<speed> km/h · G<gust> · <dir16> <deg>°' (got " + JSON.stringify(rw[2] && rw[2].text) + ")");
ok(rw.length === 4 && rw[2].text === Math.round(s12.wind.speedKmph) + " km/h · G" + Math.round(s12.wind.gustKmph) + " · " + s12.wind.dir16 + " " + Math.round(s12.wind.degree) + "°",
   "S3: tooltipLines(rainwind) line 3 values come from the slot wind group");
ok(rw.length === 4 && rw[3].icon === "visibility" && /^\d+(\.\d)? km (Good|Moderate|Poor|Fog)$/.test(rw[3].text),
   "S3: tooltipLines(rainwind) line 4 is visibility '<km> km <tier>' (got " + JSON.stringify(rw[3] && rw[3].text) + ")");
ok(rw.length === 4 && HAS_VIS && rw[3].text === s12.atmosphere.visibilityKm + " km " + G.visibilityTier(s12.atmosphere.visibilityKm),
   "S3: tooltipLines(rainwind) line 4 reads the slot visibility in km (POPUP-03 interim)");
const visFrac = ttl.slice();
visFrac[12] = Object.assign({}, s12, { atmosphere: Object.assign({}, s12.atmosphere, { visibilityKm: 3.25 }) });
const vf = G.tooltipLines("rainwind", visFrac, 12);
ok(vf.length === 4 && vf[3].text === "3.3 km Poor", "S3: a fractional visibility reads with one decimal ('3.3 km Poor', got " + JSON.stringify(vf[3] && vf[3].text) + ")");
const fogTxt = G.tooltipLines("rainwind", ttl, 0).map(function (l) { return l.text; }).join("|");
ok(fogTxt.indexOf("Fog") < 0, "S3: the zero visibility of an unavailable slot never reads as Fog (T-54.4-20)");

// Graph 3 UV WHO palette and tiers (D-54.4-30/33, A4)
ok(same(G.UV_EDGES, [3, 6, 8, 11]) && same(G.UV_COLORS, ["#66bb6a", "#ffee58", "#ffa726", "#ef5350", "#ce93d8"]),
   "S3: UV_EDGES 3,6,8,11 and UV_COLORS #66bb6a, #ffee58, #ffa726, #ef5350, #ce93d8 exactly (D-54.4-30, A4)");
ok(G.RIBBON_H === 6, "S3: RIBBON_H is 6px (D-54.4-27)");
const HAS_UV = typeof G.uvTier === "function" && typeof G.uvColor === "function";
const uvCases = [[0, "Low", "#66bb6a"], [2, "Low", "#66bb6a"], [3, "Moderate", "#ffee58"], [5, "Moderate", "#ffee58"], [6, "High", "#ffa726"],
                 [7, "High", "#ffa726"], [8, "Very High", "#ef5350"], [10, "Very High", "#ef5350"], [11, "Extreme", "#ce93d8"], [14, "Extreme", "#ce93d8"]];
for (const [uv, word, hex] of uvCases) {
  ok(HAS_UV && G.uvTier(uv) === word && G.uvColor(uv) === hex, "S3: uvTier(" + uv + ") = " + word + " and uvColor = " + hex + " (D-54.4-30/33)");
}
ok(HAS_UV && [2, 3, 5, 6, 7, 8, 10, 11].map(G.uvTier).join(",") === "Low,Moderate,Moderate,High,High,Very High,Very High,Extreme",
   "S3: uvTier over 2,3,5,6,7,8,10,11 is Low,Moderate,Moderate,High,High,Very High,Very High,Extreme");
ok(HAS_UV && G.uvTier(NaN) === "" && G.uvTier(null) === "", "S3: uvTier of a non-finite index is ''");
for (const hex of (G.UV_COLORS || [])) {
  ok(contrast(hex, "#292a2a") >= 3 && contrast(hex, "#1f2020") >= 3, "S3: UV colour " + hex + " is at least 3:1 on both card surfaces");
}

// Graph 3 tooltip line 2 (D-54.4-33)
const au = G.tooltipLines("airuv", ttl, 12);
ok(au.length >= 2 && au[1].icon === "light_mode" && /^UV \d+ (Low|Moderate|High|Very High|Extreme) · \d+ W\/m²$/.test(au[1].text),
   "S3: tooltipLines(airuv) line 2 is light_mode 'UV <n> <tier> · <rad> W/m²' (got " + JSON.stringify(au[1] && au[1].text) + ")");
ok(au.length >= 2 && HAS_UV && au[1].text === "UV " + s12.solar.uvIndex + " " + G.uvTier(s12.solar.uvIndex) + " · " + Math.round(s12.solar.shortRad) + " W/m²",
   "S3: tooltipLines(airuv) line 2 values come from the slot uvIndex and shortRad");
ok(au.length >= 1 && au[0].text === s12.desc, "S3: tooltipLines(airuv) line 1 is the bare condition text (D-54.4-33)");
const auUn = G.tooltipLines("airuv", ttl, 0);
ok(auUn.length === 1 && auUn[0].text === "No data", "S3: tooltipLines(airuv) on an unavailable slot is one No data line (T-54.4-21)");

// Graph 3 EPA ribbon palette, names and solar bars (D-54.4-28/29, T-54.4-17)
ok(Array.isArray(G.EPA_COLORS) && G.EPA_COLORS.length === 7 && G.EPA_COLORS[0] === null
   && G.EPA_COLORS.slice(1).join(",") === "#66bb6a,#ffee58,#ffa726,#ef5350,#ab47bc,#c2185b",
   "S3: EPA_COLORS[1..6] are exactly #66bb6a, #ffee58, #ffa726, #ef5350, #ab47bc, #c2185b (D-54.4-28)");
ok(Array.isArray(G.EPA_NAMES) && same(G.EPA_NAMES.slice(1), ["Good", "Moderate", "Unhealthy for Sensitive", "Unhealthy", "Very Unhealthy", "Hazardous"]),
   "S3: EPA_NAMES[1..6] are Good, Moderate, Unhealthy for Sensitive, Unhealthy, Very Unhealthy, Hazardous");
const HAS_EPA = typeof G.epaColor === "function" && typeof G.epaName === "function";
for (let idx = 1; idx <= 6; ++idx) {
  ok(HAS_EPA && G.epaColor(idx) === G.EPA_COLORS[idx] && G.epaName(idx) === G.EPA_NAMES[idx], "S3: epaColor(" + idx + ") and epaName(" + idx + ") map to the locked tier");
}
for (const bad of [0, 7, 2.5, null, undefined, NaN, -1, "2"]) {
  ok(HAS_EPA && G.epaColor(bad) === null && G.epaName(bad) === "--", "S3: epaColor(" + (typeof bad === "string" ? JSON.stringify(bad) : String(bad)) + ") is null and epaName is '--' (no segment, no tier word, T-54.4-17)");
}
ok(HAS_EPA && G.epaName(2) === "Moderate" && G.epaName(0) === "--", "S3: epaName(2) is Moderate and epaName(0) is --");
ok(G.SOLAR_COLOR === "#ffb300" && G.SOLAR_ALPHA === 0.45, "S3: SOLAR_COLOR #ffb300 at SOLAR_ALPHA 0.45 (D-54.4-29)");
ok(lowLocked.indexOf("EPA_COLORS[5]") >= 0 && lowLocked.indexOf("EPA_COLORS[6]") >= 0,
   "S3: EPA indices 5 and 6 are reported as PA-3 FINDINGs, not FAILs (" + JSON.stringify(lowLocked) + ")");
ok(lowLocked.every(function (n) { return n === "EPA_COLORS[5]" || n === "EPA_COLORS[6]"; }), "S3: every other Graph 3 colour is at least 3:1 on both surfaces");

// Graph 3 tooltip lines 3-4 (D-54.4-33)
ok(au.length >= 3 && au[2].icon === "masks" && /^AQI (Good|Moderate|Unhealthy for Sensitive|Unhealthy|Very Unhealthy|Hazardous|--) · PM2\.5 \d+ · PM10 \d+$/.test(au[2].text),
   "S3: tooltipLines(airuv) line 3 is masks 'AQI <tier> · PM2.5 <n> · PM10 <n>' (got " + JSON.stringify(au[2] && au[2].text) + ")");
ok(au.length >= 3 && HAS_EPA && au[2].text === "AQI " + G.epaName(s12.aqi.epaIndex) + " · PM2.5 " + Math.round(s12.aqi.pm2_5) + " · PM10 " + Math.round(s12.aqi.pm10),
   "S3: tooltipLines(airuv) line 3 values come from the slot epaIndex, pm2_5 and pm10");
const wantL4 = "CO " + Math.round(s12.aqi.co) + " · NO₂ " + Math.round(s12.aqi.no2) + " · O₃ " + Math.round(s12.aqi.o3) + " · SO₂ " + Math.round(s12.aqi.so2);
ok(au.length >= 4 && au[3].icon === "" && au[3].text === wantL4, "S3: tooltipLines(airuv) line 4 is exactly '" + wantL4 + "' with no icon (got " + JSON.stringify(au[3] && au[3].text) + ")");
const epa0 = ttl.slice();
epa0[12] = Object.assign({}, s12, { aqi: Object.assign({}, s12.aqi, { epaIndex: 0, pm2_5: 12.6 }) });
const ae0 = G.tooltipLines("airuv", epa0, 12);
ok(ae0.length >= 3 && ae0[2].text === "AQI -- · PM2.5 13 · PM10 41", "S3: an EPA index outside 1-6 reads 'AQI --', never a tier word (got " + JSON.stringify(ae0[2] && ae0[2].text) + ")");
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
ok(same(G.computeScales("bogus", tl), {}), "S4: computeScales returns an empty object for an unknown kind");

// Graph 3 UV scale (D-54.4-29/30)
let uvMaxFx = 0;
for (const s of tl) if (G.isAvailable(s)) uvMaxFx = Math.max(uvMaxFx, s.solar.uvIndex);
const aus = G.computeScales("airuv", tl);
ok(!!aus.uv && same(aus.uv, { min: 0, max: Math.max(1, uvMaxFx) }), "S4: computeScales(airuv).uv is {min:0, max:max(1, max uvIndex)} over available slots (" + JSON.stringify(aus.uv) + ")");
const night = mkTimeline().map(function (s) { return Object.assign({}, s, { solar: Object.assign({}, s.solar, { uvIndex: 0 }) }); });
ok(!!G.computeScales("airuv", night).uv && G.computeScales("airuv", night).uv.max === 1, "S4: the UV scale max is floored at 1 when every index is 0 (T-54.4-16)");
const unUv = mkTimeline();
unUv[0] = Object.assign({}, unUv[0], { solar: Object.assign({}, unUv[0].solar, { uvIndex: 15 }) });
ok(!!G.computeScales("airuv", unUv).uv && G.computeScales("airuv", unUv).uv.max === Math.max(1, uvMaxFx), "S4: historical-unavailable slots never enter the UV scale");

// Graph 3 solar scale (D-54.4-29)
let radMaxFx = 0;
for (const s of tl) if (G.isAvailable(s)) radMaxFx = Math.max(radMaxFx, s.solar.shortRad);
ok(!!aus.solar && aus.solar.max === radMaxFx && radMaxFx > 0, "S4: computeScales(airuv).solar.max is the largest shortRad over available slots (" + radMaxFx + ")");
const dark = mkTimeline().map(function (s) { return Object.assign({}, s, { solar: Object.assign({}, s.solar, { shortRad: 0 }) }); });
const darkSolar = G.computeScales("airuv", dark).solar;
ok(!!darkSolar && darkSolar.max === 0, "S4: computeScales(airuv).solar.max is 0 when no hour has sun");
const unRad = mkTimeline();
unRad[1] = Object.assign({}, unRad[1], { solar: Object.assign({}, unRad[1].solar, { shortRad: 2000 }) });
ok(!!G.computeScales("airuv", unRad).solar && G.computeScales("airuv", unRad).solar.max === radMaxFx, "S4: historical-unavailable slots never enter the solar scale");
ok(same(G.computeScales("rainwind", tl).rain, { min: 0, max: 100 }), "S4: computeScales(rainwind).rain is {min:0, max:100} (D-54.4-22)");

// tierStops (PA-10, Pitfalls 1/2): hard-edged tier stops for rain % and visibility
const HAS_TIER = typeof G.tierStops === "function" && typeof G.rainColor === "function";
ok(HAS_TIER, "S4: tierStops and rainColor exist");
// Colour of a gradient at offset o: the colour between the bracketing stops (lerp inside an EPS band).
function sampleStops(stops, o) {
  for (let i = 1; i < stops.length; ++i) {
    if (o <= stops[i].offset) {
      const a = stops[i - 1];
      const b = stops[i];
      if (a.color === b.color || b.offset === a.offset) return b.color;
      return G.lerpColor(a.color, b.color, (o - a.offset) / (b.offset - a.offset));
    }
  }
  return stops[stops.length - 1].color;
}
function tierOk(stops) {
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
if (HAS_TIER) {
  const rs = G.tierStops(G.RAIN_EDGES, G.rainColor, 100, 0);
  ok(rs.length === 6 && tierOk(rs), "S4: tierStops(RAIN_EDGES, rainColor, 100, 0) gives 6 in-range non-decreasing stops (start, two per edge, end)");
  ok(rs.length === 6 && near(rs[1].offset, 0.4) && near(rs[2].offset, 0.4 + G.EPS) && near(rs[3].offset, 0.7) && near(rs[4].offset, 0.7 + G.EPS),
     "S4: each rain edge (60 at 0.4, 30 at 0.7) contributes two stops EPS apart (Pitfall 2)");
  ok(rs.length === 6 && rs[0].color === "#2979ff" && rs[1].color === "#2979ff" && rs[2].color === "#42a5f5" && rs[3].color === "#42a5f5" && rs[4].color === "#90caf9" && rs[5].color === "#90caf9",
     "S4: tierStops colours are hard-edged: deep blue above 60, blue 30-60, light blue below 30");
  let sampOk = true;
  let sampBad = "";
  for (let v = 0; v <= 100; v += 0.5) {
    if (Math.abs(v - 30) <= 1 || Math.abs(v - 60) <= 1) continue;
    const got = sampleStops(rs, G.valueOffset(v, 100, 0));
    if (got !== G.rainColor(v)) {
      sampOk = false;
      sampBad = sampBad || (v + " -> " + got + " want " + G.rainColor(v));
    }
  }
  ok(sampOk, "S4: tierStops sampled at every value more than 1 unit from an edge equals rainColor(value)" + (sampOk ? "" : " " + sampBad));
  const tr = rng(5406);
  let tierAll = true;
  let tierBad = "";
  const tierPairs = [[100, 0], [0, 100], [50, 50], [29, 0], [100, 61], [45, 35]];
  for (let k = 0; k < 200 - 6; ++k) tierPairs.push([Math.round(-20 + tr() * 160), Math.round(-20 + tr() * 160)]);
  for (const [top, bottom] of tierPairs) {
    const s = G.tierStops(G.RAIN_EDGES, G.rainColor, top, bottom);
    if (!tierOk(s)) {
      tierAll = false;
      tierBad = tierBad || JSON.stringify({ top, bottom, s });
    }
  }
  ok(tierAll, "S4: tierStops over 200 random (vTop, vBottom) pairs incl. inverted and flat: offsets in [0,1], non-decreasing, 0..1" + (tierAll ? "" : " " + tierBad));
  const close = G.tierStops([10, 10.00001], function (v) { return v < 10 ? "#000000" : "#ffffff"; }, 20, 0);
  ok(tierOk(close), "S4: tierStops stays non-decreasing when two edges lie within EPS of each other");
}

// legendEntries(rainwind) first entry (D-54.4-25, PA-15)
const rle = G.legendEntries("rainwind");
ok(rle.length >= 1 && rle[0].label === "Rain%" && rle[0].style === "solid" && rle[0].dot === true && rle[0].color === "#42a5f5" && same(rle[0].colors, G.RAIN_COLORS),
   "S4: legendEntries(rainwind)[0] is Rain%, solid, dot, colour #42a5f5, swatch RAIN_COLORS");
ok(rle.map(function (e) { return e.label; }).join(",") === "Rain%,mm,Wind,Gust,Vis", "S4: legendEntries(rainwind) labels are Rain%, mm, Wind, Gust, Vis in order (D-54.4-25)");
ok(same(rle.map(function (e) { return e.style; }), ["solid", "bar", "solid", "dashed", "dotted"]), "S4: legendEntries(rainwind) styles are solid, bar, solid, dashed, dotted (D-54.4-09)");
const RW_HEX = /^#[0-9a-fA-F]{6}$/;
ok(rle.length === 5 && rle.every(function (e) { return e.dot === true && RW_HEX.test(e.color) && (e.colors || []).every(function (c) { return RW_HEX.test(c); }); }),
   "S4: every legendEntries(rainwind) entry has a colour dot and 7-character hex colours (PA-15)");
ok(rle.length === 5 && rle[1].color === "#26c6da" && rle[2].color === "#ffffff" && rle[3].color === "#ffffff" && rle[4].color === "#66bb6a" && same(rle[4].colors, G.VIS_COLORS),
   "S4: legend colours: mm #26c6da, Wind and Gust #ffffff, Vis #66bb6a with the VIS_COLORS swatch");

// legendEntries(airuv) first entry (D-54.4-32)
const ale = G.legendEntries("airuv");
ok(ale.length >= 1 && ale[0].label === "UV" && ale[0].style === "solid" && ale[0].color === "#ffee58" && same(ale[0].colors, G.UV_COLORS),
   "S4: legendEntries(airuv)[0] is UV, solid, colour #ffee58, swatch UV_COLORS");
ok(ale.slice(0, 3).map(function (e) { return e.label; }).join(",") === "UV,Solar,AQI", "S4: legendEntries(airuv) starts UV, Solar, AQI (D-54.4-32)");
ok(ale.length >= 3 && ale[1].style === "bar" && ale[1].color === "#ffb300" && same(ale[1].colors, ["#ffb300"]),
   "S4: the Solar legend entry is a #ffb300 bar swatch");
ok(ale.length >= 3 && ale[2].style === "ribbon" && ale[2].color === "#66bb6a" && same(ale[2].colors, ["#66bb6a", "#ffee58", "#ffa726"]),
   "S4: the AQI legend entry is a ribbon swatch of EPA_COLORS[1..3] labelled #66bb6a");
ok(ale.every(function (e) { return !/PM|DEFRA|diff/i.test(e.label); }), "S4: no Graph 3 legend entry names PM2.5, PM10, DEFRA or diffRad (D-54.4-27)");

// Graph 3 UV tier gradient stops (D-54.4-30, Pitfalls 1/2)
if (HAS_TIER) {
  const us = G.tierStops(G.UV_EDGES, G.uvColor, 7, 0);
  ok(tierOk(us) && us.length === 6, "S4: tierStops(UV_EDGES, uvColor, 7, 0) gives 6 in-range stops (edges 3 and 6 inside 0..7)");
  ok(tierOk(us) && us[0].color === "#ffa726" && us[us.length - 1].color === "#66bb6a", "S4: the UV gradient runs from High orange at 7 down to Low green at 0");
  let uvSamp = true;
  for (let v = 0; v <= 7; v += 0.25) {
    if (G.UV_EDGES.some(function (e) { return Math.abs(v - e) <= 0.1; })) continue;
    if (sampleStops(us, G.valueOffset(v, 7, 0)) !== G.uvColor(v)) uvSamp = false;
  }
  ok(uvSamp, "S4: the UV tier gradient sampled away from an edge equals uvColor(value)");
  const us14 = G.tierStops(G.UV_EDGES, G.uvColor, 14, 0);
  ok(tierOk(us14) && us14.length === 10 && us14[0].color === "#ce93d8", "S4: a 0..14 UV range carries all four WHO edges (10 stops) with violet at the top");
}

// Graph 2 shared wind scale and mm scale (D-54.4-22, PA-13)
const rws = G.computeScales("rainwind", tl);
let wMax = 0;
for (const s of tl) {
  if (!G.isAvailable(s)) continue;
  wMax = Math.max(wMax, s.wind.speedKmph, s.wind.gustKmph, s.atmosphere.visibilityKm);
}
ok(!!rws.wind && rws.wind.min === 0 && rws.wind.max === Math.max(1, wMax), "S4: computeScales(rainwind).wind is 0..max(speed, gust, visibility) over available slots (" + wMax + ")");
ok(!!rws.mm && rws.mm.max === 0, "S4: computeScales(rainwind).mm.max is 0 when no hour has rain");
const rwp = G.computeScales("rainwind", mkTimeline({ precip: true }));
ok(!!rwp.mm && rwp.mm.max === 3.2, "S4: computeScales(rainwind).mm.max is the largest precipMM (3.2 on the precip variant)");
const calm = mkTimeline().map(function (s) {
  return Object.assign({}, s, { wind: Object.assign({}, s.wind, { speedKmph: 0, gustKmph: 0 }), atmosphere: Object.assign({}, s.atmosphere, { visibilityKm: 0 }) });
});
ok(!!G.computeScales("rainwind", calm).wind && G.computeScales("rainwind", calm).wind.max === 1, "S4: the wind scale max is floored at 1 when every value is 0 (T-54.4-15)");
const unWind = mkTimeline();
unWind[0] = Object.assign({}, unWind[0], { wind: Object.assign({}, unWind[0].wind, { gustKmph: 500 }), moisture: Object.assign({}, unWind[0].moisture, { precipMM: 50 }) });
const uws = G.computeScales("rainwind", unWind);
ok(!!uws.wind && uws.wind.max === Math.max(1, wMax) && uws.mm.max === 0, "S4: historical-unavailable slots never enter the wind or mm scale");
ok(G.computeScales("temp", tl).temp.max === 36, "S4: computeScales(temp) carries tempScale");

// legendEntries (D-54.4-09/18)
const le = G.legendEntries("temp");
ok(same(le.map(function (e) { return e.label; }), ["Temp", "Feels"]), "S4: legendEntries(temp) labels are Temp, Feels (D-54.4-18)");
ok(same(le.map(function (e) { return e.style; }), ["solid", "dashed"]), "S4: legendEntries(temp) styles are solid, dashed (D-54.4-18)");
const HEX7 = /^#[0-9a-fA-F]{6}$/;
let leHex = le.length > 0;
for (const e of le) {
  if (!HEX7.test(e.color)) leHex = false;
  for (const c of (e.colors || [])) if (!HEX7.test(c)) leHex = false;
}
ok(leHex, "S4: every legendEntries(temp) colour is a 7-character hex");
ok(le.every(function (e) { return same(e.colors, G.TEMP_RAMP.map(function (a) { return a.color; })); }), "S4: legendEntries(temp) swatches use the three TEMP_RAMP colours");
const STYLES = ["solid", "dashed", "dotted", "bar", "ribbon"];
ok(le.every(function (e) { return STYLES.indexOf(e.style) >= 0 && typeof e.dot === "boolean"; }), "S4: legendEntries(temp) styles are known and dot is a boolean");
ok(Array.isArray(G.legendEntries("rainwind")) && Array.isArray(G.legendEntries("airuv")) && same(G.legendEntries("bogus"), []),
   "S4: legendEntries returns an array for every kind and [] for an unknown kind");

// tempGridPlan (D-54.4-16): gridline every 1 degree, labels every 1 at >= 12px rows, else every 2
ok(typeof G.tempGridPlan === "function" && same(G.tempGridPlan({ min: 25, max: 36 }, 254), { step: 1, labelStep: 1 }),
   "S4: tempGridPlan({25..36}, 254) = {step:1, labelStep:1} (23px rows)");
ok(typeof G.tempGridPlan === "function" && G.tempGridPlan({ min: 10, max: 40 }, 300).labelStep === 2,
   "S4: tempGridPlan({10..40}, 300) thins labels to every 2 degrees (10px rows)");
ok(typeof G.tempGridPlan === "function" && G.tempGridPlan({ min: 0, max: 10 }, 120).labelStep === 1,
   "S4: tempGridPlan at exactly 12px rows keeps labelStep 1");
ok(typeof G.tempGridPlan === "function" && G.tempGridPlan({ min: 0, max: 10 }, 119).labelStep === 2,
   "S4: tempGridPlan at 11.9px rows gives labelStep 2");
ok(typeof G.tempGridPlan === "function" && G.tempGridPlan({ min: 5, max: 5 }, 100).step === 1 && G.tempGridPlan(null, 100).labelStep === 1,
   "S4: tempGridPlan tolerates a flat or missing scale");

// placeLabels: greedy collision-free peak-label placement (D-54.4-10, RESEARCH Pattern 6)
const HAS_PLACE = typeof G.placeLabels === "function" && typeof G.rectsIntersect === "function";
const BND = { left: 24, right: 292, top: 0, bottom: 260 };
function inside(p, b) {
  return p.x >= b.left && p.x + p.w <= b.right && p.y >= b.top && p.y + p.h <= b.bottom;
}
function cand(text, x, y, pr, rank, anchor, w) {
  return { text: text, x: x, y: y, w: w === undefined ? 18 : w, h: 10, priority: pr, rank: rank, color: "#ffb300", anchor: anchor || "above" };
}
ok(HAS_PLACE && same(G.placeLabels([], BND, []), []), "S4: placeLabels([], bounds, []) = []");
ok(HAS_PLACE && G.rectsIntersect({ x: 0, y: 0, w: 10, h: 10 }, { x: 5, y: 5, w: 10, h: 10 }) && !G.rectsIntersect({ x: 0, y: 0, w: 10, h: 10 }, { x: 10, y: 0, w: 10, h: 10 }),
   "S4: rectsIntersect detects overlap and treats touching edges as clear");
if (HAS_PLACE) {
  const co = G.placeLabels([cand("34°", 100, 40, 0, 34), cand("36°", 100, 40, 1, 36)], BND, []);
  ok(co.length >= 1 && !(co.length === 2 && G.rectsIntersect(co[0], co[1])) && co[0].text === "34°",
     "S4: two coincident candidates never give intersecting rects; the priority-0 label is kept (" + JSON.stringify(co) + ")");
  ok(co.every(function (p) { return inside(p, BND); }), "S4: coincident candidates stay inside bounds");
  const ac = G.placeLabels([cand("34°", 100, 40, 0, 34)], BND, []);
  ok(ac.length === 1 && near(ac[0].x, 91) && near(ac[0].y, 27) && ac[0].w === 18 && ac[0].h === 10 && ac[0].color === "#ffb300",
     "S4: an unobstructed 'above' candidate sits above-centre with a 3px gap, x/y as the top-left corner");
  const bc = G.placeLabels([cand("1.2", 100, 40, 0, 1, "below")], BND, []);
  ok(bc.length === 1 && near(bc[0].x, 91) && near(bc[0].y, 43), "S4: an unobstructed 'below' candidate sits below-centre with a 3px gap");
  const edge = G.placeLabels([cand("34°", BND.left, 40, 0, 34)], BND, []);
  ok(edge.length === 1 && edge[0].x >= BND.left && near(edge[0].x, BND.left + 3) && near(edge[0].y, 27),
     "S4: a candidate at plotLeft is shifted inside the bounds (above-right), not clipped");
  const redge = G.placeLabels([cand("34°", BND.right, 40, 0, 34)], BND, []);
  ok(redge.length === 1 && inside(redge[0], BND) && near(redge[0].x, BND.right - 18 - 3), "S4: a candidate at plotRight is shifted inside (above-left)");
  const topEdge = G.placeLabels([cand("34°", 100, 5, 0, 34)], BND, []);
  ok(topEdge.length === 1 && near(topEdge[0].y, 8), "S4: a candidate with no room above falls back to below-centre");
  const reserved = [{ x: 91, y: 27, w: 18, h: 10 }];
  const rv = G.placeLabels([cand("34°", 100, 40, 0, 34)], BND, reserved);
  ok(rv.every(function (p) { return !G.rectsIntersect(p, reserved[0]); }), "S4: a candidate overlapping a reserved rect is moved off it or dropped (" + JSON.stringify(rv) + ")");
  const tight = { left: 90, right: 112, top: 26, bottom: 39 };
  const tg = G.placeLabels([cand("A", 100, 40, 1, 1), cand("B", 100, 40, 0, 1), cand("C", 100, 40, 2, 1)], tight, []);
  ok(tg.length === 1 && tg[0].text === "B", "S4: when only one slot fits, the highest-priority label is kept and the rest are dropped");
  const rk = G.placeLabels([cand("low", 100, 40, 3, 10), cand("high", 100, 40, 3, 20)], tight, []);
  ok(rk.length === 1 && rk[0].text === "high", "S4: equal priority ties break on the larger rank");
  const junk = G.placeLabels([cand("nan", NaN, 40, 0, 1), null, cand("ok", 100, 40, 1, 1)], BND, null);
  ok(junk.length === 1 && junk[0].text === "ok", "S4: non-finite or null candidates are skipped, a null reserved list is tolerated");
  ok(same(G.placeLabels(null, BND, []), []), "S4: placeLabels(null) = []");

  // Property test: 300 random candidate sets
  const pr = rng(5410);
  let propOk = true;
  let propBad = "";
  let totalPlaced = 0;
  for (let k = 0; k < 300; ++k) {
    const n = 2 + Math.floor(pr() * 11);
    const cs = [];
    for (let j = 0; j < n; ++j) {
      cs.push({
        text: "L" + j, x: BND.left + pr() * (BND.right - BND.left), y: pr() * BND.bottom,
        w: 10 + Math.round(pr() * 50), h: 10, priority: Math.floor(pr() * 8), rank: Math.round(pr() * 100),
        color: "#ef5350", anchor: pr() < 0.5 ? "above" : "below"
      });
    }
    const placed = G.placeLabels(cs, BND, []);
    totalPlaced += placed.length;
    const seen = {};
    for (let a = 0; a < placed.length; ++a) {
      const p = placed[a];
      const src = cs.find(function (c) { return c.text === p.text; });
      if (!inside(p, BND) || !src || seen[p.text] || p.w !== src.w || p.h !== src.h) {
        propOk = false;
        propBad = propBad || JSON.stringify({ k: k, p: p });
      }
      seen[p.text] = true;
      for (let b = a + 1; b < placed.length; ++b) {
        if (G.rectsIntersect(p, placed[b])) {
          propOk = false;
          propBad = propBad || JSON.stringify({ k: k, a: p, b: placed[b] });
        }
      }
    }
  }
  ok(propOk && totalPlaced > 0, "S4: placeLabels property test over 300 random sets: inside bounds, zero intersections, placed is a subset of the input (" + totalPlaced + " placed)" + (propOk ? "" : " " + propBad));
}
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
    if (fn === "drawKind") {
      // drawKind also draws the backdrop and the temperature grid, which a single available
      // reading legitimately produces; the series spline must still be absent.
      ok(t === null && calls(d.log, "bezierCurveTo").length === 0, "S5: drawKind on " + label + " records no series spline and does not throw");
    } else {
      ok(t === null && calls(d.log, "stroke").length === 0, "S5: " + fn + " on " + label + " records no stroke and does not throw");
    }
  }
}
for (const [label, input] of [["an empty slot array", []], ["an all-null array", [null, null, null]]]) {
  const d = mockCtx();
  G.drawKind(d.ctx, "temp", geomFor(Math.max(1, input.length)), input, G.computeScales("temp", input), THEME);
  ok(calls(d.log, "stroke").length === 0, "S5: drawKind on " + label + " records no stroke at all (no grid, divider or Now line without data)");
}

// tempGridPlan / drawTempAxis (D-54.4-05/16)
const axisScale = { min: 25, max: 36 };
function axisRun(g) {
  const a = mockCtx();
  let t = null;
  try { G.drawTempAxis(a.ctx, g, axisScale, THEME); } catch (e) { t = e; }
  return { log: a.log, ann: annotate(a.log), threw: t };
}
const ax1 = axisRun(geom);
ok(ax1.threw === null, "S5: drawTempAxis on {25..36} does not throw" + (ax1.threw ? " (" + ax1.threw + ")" : ""));
const gridMoves = calls(ax1.log, "moveTo");
const gridLines = calls(ax1.log, "lineTo");
ok(calls(ax1.log, "stroke").length === 12 && gridMoves.length === 12, "S5: drawTempAxis strokes 12 gridlines for 25..36 (one per degree, D-54.4-16)");
let horiz = gridMoves.length === gridLines.length;
for (let i = 0; horiz && i < gridMoves.length; ++i) {
  if (gridMoves[i][1] !== geom.plotLeft || gridLines[i][1] !== geom.plotRight || gridMoves[i][2] !== gridLines[i][2]) horiz = false;
}
ok(horiz, "S5: every gridline is horizontal from plotLeft to plotRight");
const gridYs = gridMoves.map(function (e) { return e[2]; });
const wantYs = [];
for (let v = 25; v <= 36; ++v) wantYs.push(G.valueToY(v, 25, 36, geom.plotTop, geom.plotBottom));
ok(same(gridYs, wantYs), "S5: gridline y positions equal valueToY for 25..36");
ok(ax1.ann.filter(function (c) { return c.name === "stroke"; }).every(function (c) { return c.st.globalAlpha === 0.35 && c.st.lineWidth === 1 && c.st.strokeStyle === THEME.grid; }),
   "S5: gridlines use theme.grid at globalAlpha 0.35 and lineWidth 1");
const lab1 = ax1.ann.filter(function (c) { return c.name === "fillText"; });
ok(lab1.length === 12, "S5: labelStep 1 draws 12 y labels (got " + lab1.length + ")");
ok(lab1.every(function (c) { return /°$/.test(String(c.args[0])); }), "S5: every y label ends in the degree sign");
ok(lab1.every(function (c) { return c.st.font === G.Y_LABEL_FONT && c.st.textAlign === "right" && c.st.fillStyle === THEME.text; }),
   "S5: y labels use Y_LABEL_FONT, textAlign right and theme.text");
ok(lab1.every(function (c) {
  const w = String(c.args[0]).length * 6;
  const left = c.args[1] - w;
  return left >= 0 && left + w <= geom.plotLeft;
}), "S5: every y label fits the left gutter (left edge >= 0, left + width <= plotLeft, D-54.4-05)");
const cramped = Object.assign({}, geom, { plotBottom: geom.plotTop + 120 });
const ax2 = axisRun(cramped);
const lab2 = ax2.ann.filter(function (c) { return c.name === "fillText"; }).map(function (c) { return c.args[0]; });
ok(same(lab2, ["25°", "27°", "29°", "31°", "33°", "35°"]), "S5: labelStep 2 draws 6 labels at the min parity 25,27,...,35 (got " + JSON.stringify(lab2) + ")");
ok(calls(ax2.log, "stroke").length === 12, "S5: labelStep 2 still strokes a gridline every degree");
ok(calls(ax1.log, "save").length === calls(ax1.log, "restore").length && calls(ax1.log, "save").length >= 1, "S5: drawTempAxis wraps its drawing in save/restore");

// drawBackdrop (PA-4): night shading, midnight divider, Now hairline, past-data hatch
function backdropRun(slots, g) {
  const b = mockCtx();
  let t = null;
  try { G.drawBackdrop(b.ctx, g || geom, slots, THEME); } catch (e) { t = e; }
  return { log: b.log, ann: annotate(b.log), threw: t };
}
const bd = backdropRun(tl);
ok(bd.threw === null, "S5: drawBackdrop on the fixture does not throw" + (bd.threw ? " (" + bd.threw + ")" : ""));
const nightCount = tl.filter(function (s) { return !s.isDay; }).length;
const shade = bd.ann.filter(function (c) { return c.name === "fillRect" && c.st.globalAlpha === 0.12; });
ok(shade.length === nightCount && nightCount > 0, "S5: drawBackdrop fills one rect per night slot at globalAlpha 0.12 (" + shade.length + " of " + nightCount + ")");
ok(shade.every(function (c) { return c.args[1] === geom.plotTop && near(c.args[1] + c.args[3], geom.plotBottom) && near(c.args[2], geom.slotW) && c.st.fillStyle === THEME.shade; }),
   "S5: night shading spans plotTop..plotBottom over one slot column in theme.shade");
const midIdx = [];
tl.forEach(function (s, i) { if (i > 0 && (s.isDayBoundary || s.hourNum === 0)) midIdx.push(i); });
const strokesB = bd.ann.filter(function (c) { return c.name === "stroke"; });
const movesB = bd.ann.filter(function (c) { return c.name === "moveTo"; });
const midMoves = movesB.filter(function (c) { return midIdx.some(function (i) { return near(c.args[0], geom.plotLeft + i * geom.slotW); }); });
ok(midIdx.length === 1 && midMoves.length === midIdx.length, "S5: one dotted midnight divider per boundary at index > 0 (" + midMoves.length + " of " + midIdx.length + ")");
const nowX = G.slotCenterX(geom, 12);
const nowMoves = movesB.filter(function (c) { return near(c.args[0], nowX); });
ok(nowMoves.length === 1, "S5: one Now hairline at slotCenterX(12) when isTimeline25");
ok(calls(bd.log, "setLineDash").some(function (e) { return same(e[1], [3, 3]); }) && calls(bd.log, "setLineDash").some(function (e) { return same(e[1], G.DASH_DOTTED); }),
   "S5: the Now hairline is dashed [3,3] and the midnight divider uses DASH_DOTTED");
ok(strokesB.length === 2, "S5: drawBackdrop strokes exactly the midnight divider and the Now hairline (" + strokesB.length + ")");
const noTl = backdropRun(tl, Object.assign({}, geom, { isTimeline25: false }));
ok(calls(noTl.log, "moveTo").filter(function (e) { return near(e[1], nowX); }).length === 0, "S5: no Now hairline when the timeline is not the 25-slot form");
const texts = calls(bd.log, "fillText").map(function (e) { return e[1]; });
ok(texts.indexOf("NOW") < 0 && texts.every(function (t) { return t === "No data"; }), "S5: drawBackdrop never draws a NOW badge or a date chip (texts " + JSON.stringify(texts) + ", PA-4)");
ok(calls(bd.log, "rect").length === 0 && calls(bd.log, "fill").length === 0, "S5: drawBackdrop draws no badge rectangle");
const hatch = bd.ann.filter(function (c) { return c.name === "fillRect" && c.st.globalAlpha === 0.25; });
ok(hatch.length === 1 && hatch[0].args[0] === geom.plotLeft && near(hatch[0].args[2], 3 * geom.slotW), "S5: the leading 3 unavailable slots get one past-data hatch at alpha 0.25");
ok(texts.length === 0, "S5: a 3-slot hatch (" + (3 * geom.slotW).toFixed(1) + "px) is narrower than 'No data' + 4, so no text is drawn");
const wide = backdropRun(mkTimeline({ unavailable: 6 }));
const wideTexts = wide.ann.filter(function (c) { return c.name === "fillText"; });
ok(wideTexts.length === 1 && wideTexts[0].args[0] === "No data" && near(wideTexts[0].args[1], geom.plotLeft + 3 * geom.slotW),
   "S5: a 6-slot hatch is wide enough and centres 'No data' in it");
ok(wideTexts.length === 1 && /italic/.test(wideTexts[0].st.font) && /9px/.test(wideTexts[0].st.font) && wideTexts[0].st.fillStyle === THEME.text,
   "S5: 'No data' uses italic 9px in theme.text");
const none = backdropRun(mkTimeline({ unavailable: 0 }));
ok(none.ann.filter(function (c) { return c.name === "fillRect" && c.st.globalAlpha === 0.25; }).length === 0, "S5: no hatch when every slot is available");
ok(calls(bd.log, "save").length === calls(bd.log, "restore").length, "S5: drawBackdrop save/restore calls are balanced");
for (const [label, input] of [["[]", []], ["[null, slot, null]", [null, one, null]], ["null", null]]) {
  const r2 = backdropRun(input, geomFor(3));
  ok(r2.threw === null, "S5: drawBackdrop on " + label + " does not throw");
}

// drawKind order: backdrop first, then (temp) the y axis, then the series
const ko = mockCtx();
G.drawKind(ko.ctx, "temp", geom, tl, scales, THEME);
const koAnn = annotate(ko.log);
const firstShade = koAnn.findIndex(function (c) { return c.name === "fillRect" && c.st.globalAlpha === 0.12; });
const firstLabel = koAnn.findIndex(function (c) { return c.name === "fillText" && /°$/.test(String(c.args[0])); });
const firstBez = koAnn.findIndex(function (c) { return c.name === "bezierCurveTo"; });
ok(firstShade >= 0 && firstLabel > firstShade && firstBez > firstLabel, "S5: drawKind(temp) draws the backdrop, then the y axis, then the series (" + [firstShade, firstLabel, firstBez].join(",") + ")");
// peakCandidates (temp) and drawLabels (D-54.4-10, Pitfall 11)
const HAS_PEAK = typeof G.peakCandidates === "function" && typeof G.drawLabels === "function";
ok(HAS_PEAK, "S5: peakCandidates and drawLabels exist");
if (HAS_PEAK) {
  const pm = mockCtx();
  const pc = G.peakCandidates("temp", pm.ctx, geom, tl, scales);
  let tMax = -Infinity, tIdx = -1, fMax = -Infinity, fIdx = -1;
  tl.forEach(function (s, i) {
    if (!G.isAvailable(s)) return;
    if (s.thermal.tempC > tMax) { tMax = s.thermal.tempC; tIdx = i; }
    if (s.thermal.feelsLikeC > fMax) { fMax = s.thermal.feelsLikeC; fIdx = i; }
  });
  ok(pc.length === 2, "S5: peakCandidates(temp) gives 2 candidates (temperature max and feels-like max)");
  ok(pc.length === 2 && pc[0].text === Math.round(tMax) + "°" && pc[0].priority === 0 && pc[1].text === Math.round(fMax) + "°" && pc[1].priority === 1,
     "S5: temperature max '" + Math.round(tMax) + "°' is priority 0 and feels-like max '" + Math.round(fMax) + "°' is priority 1");
  ok(pc.length === 2 && near(pc[0].x, G.slotCenterX(geom, tIdx)) && near(pc[1].x, G.slotCenterX(geom, fIdx))
     && near(pc[0].y, G.valueToY(tMax, scales.temp.min, scales.temp.max, geom.plotTop, geom.plotBottom))
     && near(pc[1].y, G.valueToY(fMax, scales.temp.min, scales.temp.max, geom.plotTop, geom.plotBottom)),
     "S5: each peak candidate sits at the first slot holding the max, at valueToY on scales.temp");
  ok(pc.length === 2 && pc[0].color === G.rampColorAt(G.TEMP_RAMP, tMax) && pc[1].color === G.rampColorAt(G.TEMP_RAMP, fMax),
     "S5: peak candidate colours come from rampColorAt(TEMP_RAMP, value)");
  ok(pc.every(function (c) { return c.h === 10 && c.w === String(c.text).length * 6 && c.anchor === "above" && c.rank !== undefined; }),
     "S5: peak candidates measure width with ctx.measureText, h 10, anchor above");
  const fontBeforeMeasure = annotate(pm.log).filter(function (c) { return c.name === "measureText"; });
  ok(fontBeforeMeasure.length >= 2 && fontBeforeMeasure.every(function (c) { return c.st.font === G.LABEL_FONT; }), "S5: LABEL_FONT is set before every measureText");
  // Unavailable slots never yield a candidate, even with a bigger value (T-54.4-14)
  const poisoned = mkTimeline();
  poisoned[1] = Object.assign({}, poisoned[1], { thermal: { tempC: 60, feelsLikeC: 70, dewPointC: 0 } });
  const pp = G.peakCandidates("temp", mockCtx().ctx, geom, poisoned, G.computeScales("temp", poisoned));
  ok(pp.length === 2 && pp[0].text === Math.round(tMax) + "°" && pp[1].text === Math.round(fMax) + "°", "S5: a historical-unavailable slot never yields a peak candidate");
  const noData = mkTimeline({ unavailable: 25 });
  ok(same(G.peakCandidates("temp", mockCtx().ctx, geomFor(25), noData, G.computeScales("temp", noData)), []), "S5: an all-unavailable timeline yields no peak candidate");
  ok(same(G.peakCandidates("bogus", mockCtx().ctx, geom, tl, {}), []), "S5: peakCandidates returns [] for an unknown kind");

  // Rain % peak (Graph 2): priority 2, tier colour, skipped when the max is 0
  let rMax = -Infinity, rIdx = -1;
  tl.forEach(function (s, i) {
    if (G.isAvailable(s) && s.moisture.rainProb > rMax) { rMax = s.moisture.rainProb; rIdx = i; }
  });
  const rwScales = G.computeScales("rainwind", tl);
  const rpc = G.peakCandidates("rainwind", mockCtx().ctx, geom, tl, rwScales);
  const rainPk = rpc.find(function (c) { return c.text === Math.round(rMax) + "%"; });
  ok(!!rainPk && rainPk.priority === 2 && rainPk.color === G.rainColor(rMax) && rainPk.anchor === "above" && near(rainPk.x, G.slotCenterX(geom, rIdx))
     && near(rainPk.y, G.valueToY(rMax, 0, 100, geom.plotTop, geom.plotBottom)),
     "S5: peakCandidates(rainwind) labels the rain max '" + Math.round(rMax) + "%' at priority 2 in rainColor, on the 0..100 scale");
  const dry = mkTimeline().map(function (s) { return Object.assign({}, s, { moisture: Object.assign({}, s.moisture, { rainProb: 0 }) }); });
  ok(!G.peakCandidates("rainwind", mockCtx().ctx, geom, dry, G.computeScales("rainwind", dry)).some(function (c) { return /%$/.test(c.text); }),
     "S5: an all-zero rain series gets no rain peak label (nothing peaks)");
  const rpoison = mkTimeline();
  rpoison[1] = Object.assign({}, rpoison[1], { moisture: Object.assign({}, rpoison[1].moisture, { rainProb: 99 }) });
  ok(!G.peakCandidates("rainwind", mockCtx().ctx, geom, rpoison, G.computeScales("rainwind", rpoison)).some(function (c) { return c.text === "99%"; }),
     "S5: a historical-unavailable slot never yields a rain peak label");

  const dl = mockCtx();
  dl.ctx.globalAlpha = 0.45;
  dl.ctx.font = "7px serif";
  G.drawLabels(dl.ctx, [{ text: "34°", x: 91, y: 27, w: 18, h: 10, color: "#ef5350" }, { text: "36°", x: 91, y: 43, w: 18, h: 10, color: "#ffb300" }]);
  const dlTexts = annotate(dl.log).filter(function (c) { return c.name === "fillText"; });
  ok(dlTexts.length === 2 && dlTexts.every(function (c) { return c.st.globalAlpha === 1 && c.st.font === G.LABEL_FONT && c.st.textBaseline === "top" && c.st.textAlign === "left"; }),
     "S5: drawLabels sets globalAlpha 1, LABEL_FONT, top baseline and left align before every fillText (Pitfall 11)");
  ok(dlTexts.length === 2 && dlTexts[0].st.fillStyle === "#ef5350" && dlTexts[1].st.fillStyle === "#ffb300" && dlTexts[0].args[1] === 91 && dlTexts[0].args[2] === 27,
     "S5: drawLabels fills each label in its colour at its top-left corner");
  ok(calls(dl.log, "save").length === 1 && calls(dl.log, "restore").length === 1, "S5: drawLabels wraps its drawing in save/restore");

  const kl = mockCtx();
  G.drawKind(kl.ctx, "temp", geom, tl, scales, THEME);
  const klAnn = annotate(kl.log);
  const lastBez = klAnn.map(function (c) { return c.name; }).lastIndexOf("bezierCurveTo");
  const peakTexts = klAnn.filter(function (c, i) { return i > lastBez && c.name === "fillText"; });
  ok(peakTexts.length >= 1 && peakTexts.every(function (c) { return c.st.globalAlpha === 1 && c.st.font === G.LABEL_FONT; }),
     "S5: drawKind(temp) draws the peak labels after the series at full opacity (" + peakTexts.map(function (c) { return c.args[0]; }).join(",") + ")");
  ok(peakTexts.map(function (c) { return c.args[0]; }).indexOf(Math.round(tMax) + "°") >= 0, "S5: drawKind(temp) labels the temperature maximum");
}

for (const kind of ["rainwind", "airuv"]) {
  const kk = mockCtx();
  G.drawKind(kk.ctx, kind, geom, tl, {}, THEME);
  const kAnn = annotate(kk.log);
  ok(kAnn.filter(function (c) { return c.name === "fillRect" && c.st.globalAlpha === 0.12; }).length === nightCount, "S5: drawKind(" + kind + ") draws the shared backdrop");
  ok(kAnn.filter(function (c) { return c.name === "fillText" && /°$/.test(String(c.args[0])); }).length === 0, "S5: drawKind(" + kind + ") draws no temperature y labels (temp card only, D-54.4-16)");
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

// Graph 2: rain-probability tier spline (D-54.4-21..23)
const rwSc = G.computeScales("rainwind", tl);
const rk = mockCtx();
let rkThrew = null;
try { G.drawKind(rk.ctx, "rainwind", geom, tl, rwSc, THEME); } catch (e) { rkThrew = e; }
ok(rkThrew === null, "S5: drawKind(rainwind) on the fixture does not throw" + (rkThrew ? " (" + rkThrew + ")" : ""));
ok(calls(rk.log, "bezierCurveTo").length >= 1, "S5: drawKind(rainwind) records at least one bezierCurveTo (rain spline)");
ok(calls(rk.log, "createLinearGradient").length >= 1, "S5: drawKind(rainwind) creates a linear gradient for the rain tiers");
const rkStops = rk.log.filter(function (e) { return e[0] === "stop"; });
ok(rkStops.length >= 2 && rkStops.every(function (e) { return e[1] >= 0 && e[1] <= 1; }), "S5: drawKind(rainwind) adds no colour stop outside [0,1] (Pitfall 1)");
ok(calls(rk.log, "save").length === calls(rk.log, "restore").length, "S5: drawKind(rainwind) save/restore calls are balanced");
const rr = mockCtx();
G.drawRainWind(rr.ctx, geom, tl, rwSc);
const rrGrad = calls(rr.log, "createLinearGradient");
ok(rrGrad.length >= 1 && rrGrad[0][2] === geom.plotTop && rrGrad[0][4] === geom.plotBottom, "S5: the rain gradient runs vertically from plotTop to plotBottom");
const rrStops = rr.log.filter(function (e) { return e[0] === "stop"; }).slice(0, 6).map(function (e) { return e[2]; });
ok(same(rrStops, ["#2979ff", "#2979ff", "#42a5f5", "#42a5f5", "#90caf9", "#90caf9"]), "S5: the rain gradient carries the six hard-edged tier stops (" + JSON.stringify(rrStops) + ")");
const rrAnn = annotate(rr.log);
const rainStroke = rrAnn.find(function (c) { return c.name === "stroke"; });
ok(!!rainStroke && rainStroke.st.lineWidth === 2, "S5: the rain spline is stroked at lineWidth 2");
let rxOk = true;
for (const e of rr.log) {
  if (e[0] === "moveTo" && e[1] < minX) rxOk = false;
  if (e[0] === "bezierCurveTo" && (e[1] < minX || e[3] < minX || e[5] < minX)) rxOk = false;
}
ok(rxOk, "S5: the rain spline never enters the unavailable columns (T-54.4-20)");
const rmp = G.markerPoints("rainwind", tl, 12, geom, rwSc);
ok(rmp.some(function (p) { return p.color === G.rainColor(tl[12].moisture.rainProb) && near(p.y, G.valueToY(tl[12].moisture.rainProb, 0, 100, geom.plotTop, geom.plotBottom)); }),
   "S5: markerPoints(rainwind, fixture, 12) has the rain point in rainColor(rainProb) on the 0..100 scale");
ok(same(G.markerPoints("rainwind", tl, 0, geom, rwSc), []), "S5: markerPoints(rainwind) at the unavailable index 0 is []");

// Graph 2: mm bars, wind, gust and visibility (D-54.4-21..24, PA-11, PA-13)
// Replays an annotated log and attaches the line dash in force at each call (save/restore aware).
function withDash(ann) {
  const stack = [];
  let dash = [];
  return ann.map(function (c) {
    if (c.name === "save") stack.push(dash);
    if (c.name === "restore") dash = stack.length ? stack.pop() : [];
    if (c.name === "setLineDash") dash = c.args[0];
    return Object.assign({}, c, { dash: dash });
  });
}
function mmBars(ann) {
  return ann.filter(function (c) { return c.name === "fillRect" && c.st.fillStyle === "#26c6da" && c.st.globalAlpha === 0.6; });
}
const base = mockCtx();
G.drawRainWind(base.ctx, geom, tl, G.computeScales("rainwind", tl));
ok(calls(base.log, "fillRect").length === 0, "S5: drawRainWind on the base fixture (all precip 0) records zero fillRect (bars only when precipMM > 0)");
const ptl = mkTimeline({ precip: true });
const psc = G.computeScales("rainwind", ptl);
const pv = mockCtx();
G.drawRainWind(pv.ctx, geom, ptl, psc);
const pvAnn = withDash(annotate(pv.log));
const bars = mmBars(pvAnn);
ok(calls(pv.log, "fillRect").length === 2 && bars.length === 2, "S5: the precip variant records exactly two mm-bar fillRect calls at #26c6da and alpha 0.6 (" + bars.length + ")");
const plotH = geom.plotBottom - geom.plotTop;
const barW = Math.max(2, geom.slotW * 0.6);
const bar15 = bars.find(function (c) { return near(c.args[0] + c.args[2] / 2, G.slotCenterX(geom, 15)); });
const bar18 = bars.find(function (c) { return near(c.args[0] + c.args[2] / 2, G.slotCenterX(geom, 18)); });
ok(!!bar18 && near(bar18.args[2], barW) && near(bar18.args[3], 0.4 * plotH) && near(bar18.args[1] + bar18.args[3], geom.plotBottom),
   "S5: the 3.2 mm bar is centred on its slot, max(2, slotW*0.6) wide, BAR_CAP of the plot tall, and sits on plotBottom");
ok(!!bar15 && near(bar15.args[3], 0.4 / 3.2 * 0.4 * plotH), "S5: the 0.4 mm bar height is precipMM / mm.max * BAR_CAP * plot height");
const firstLine = pvAnn.findIndex(function (c) { return c.name === "stroke"; });
const lastBar = pvAnn.map(function (c) { return c.name; }).lastIndexOf("fillRect");
ok(lastBar >= 0 && firstLine > lastBar, "S5: mm bars are drawn first, under the lines");
const unBar = mkTimeline({ precip: true });
unBar[1] = Object.assign({}, unBar[1], { moisture: Object.assign({}, unBar[1].moisture, { precipMM: 5 }) });
const ub = mockCtx();
G.drawRainWind(ub.ctx, geom, unBar, G.computeScales("rainwind", unBar));
ok(calls(ub.log, "fillRect").length === 2 && calls(ub.log, "fillRect").every(function (e) { return e[1] >= geom.plotLeft + 3 * geom.slotW; }),
   "S5: no mm bar falls in an unavailable column (T-54.4-20)");
const strokes = pvAnn.filter(function (c) { return c.name === "stroke"; });
const windStroke = strokes.find(function (c) { return c.st.strokeStyle === "#ffffff" && same(c.dash, []); });
const gustStroke = strokes.find(function (c) { return c.st.strokeStyle === "#ffffff" && same(c.dash, G.DASH_DASHED); });
const visStroke = strokes.find(function (c) { return typeof c.st.strokeStyle === "object" && same(c.dash, G.DASH_DOTTED); });
ok(!!windStroke && windStroke.st.globalAlpha === 0.9 && windStroke.st.lineWidth === 1.5, "S5: wind is a solid #ffffff spline at alpha 0.9, lineWidth 1.5 (D-54.4-23)");
ok(!!gustStroke && gustStroke.st.globalAlpha === 0.9 && gustStroke.st.lineWidth === 1.2, "S5: gust is a DASH_DASHED #ffffff spline at alpha 0.9, lineWidth 1.2");
ok(!!visStroke && visStroke.st.lineWidth === 1.5, "S5: visibility is a DASH_DOTTED gradient spline at lineWidth 1.5");
const pvGrads = calls(pv.log, "createLinearGradient");
ok(pvGrads.length === 2, "S5: drawRainWind builds two vertical gradients (rain tiers, visibility tiers)");
const pvStops = pv.log.filter(function (e) { return e[0] === "stop"; });
ok(pvStops.every(function (e) { return e[1] >= 0 && e[1] <= 1; }), "S5: every drawRainWind colour stop lies in [0,1]");
const visGradColors = pvStops.slice(6).map(function (e) { return e[2]; });
ok(visGradColors.length >= 2 && visGradColors.every(function (c) { return G.VIS_COLORS.indexOf(c) >= 0; }) && visGradColors[0] === "#66bb6a" && visGradColors[visGradColors.length - 1] === "#ef5350",
   "S5: the visibility gradient uses the VIS tier colours from Good at the top to Fog at 0 (" + JSON.stringify(visGradColors) + ")");
ok(calls(pv.log, "save").length === calls(pv.log, "restore").length, "S5: drawRainWind save/restore calls are balanced");
let pxOk = true;
for (const e of pv.log) {
  if (e[0] === "moveTo" && e[1] < minX) pxOk = false;
  if (e[0] === "bezierCurveTo" && (e[1] < minX || e[3] < minX || e[5] < minX)) pxOk = false;
}
ok(pxOk, "S5: no Graph 2 spline enters the unavailable columns (T-54.4-20)");

// All-zero fixture: every recorded numeric argument is finite (T-54.4-15)
const zero = mkTimeline().map(function (s) {
  if (!G.isAvailable(s)) return s;
  return Object.assign({}, s, {
    moisture: Object.assign({}, s.moisture, { rainProb: 0, precipMM: 0 }),
    wind: Object.assign({}, s.wind, { speedKmph: 0, gustKmph: 0 }),
    atmosphere: Object.assign({}, s.atmosphere, { visibilityKm: 0 })
  });
});
const zr = mockCtx();
let zThrew = null;
try { G.drawKind(zr.ctx, "rainwind", geom, zero, G.computeScales("rainwind", zero), THEME); } catch (e) { zThrew = e; }
let finite = true;
for (const e of zr.log) {
  for (const a of e.slice(1)) if (typeof a === "number" && !isFinite(a)) finite = false;
}
ok(zThrew === null && finite, "S5: drawKind(rainwind) on an all-zero wind/gust/visibility/rain fixture records only finite numbers");
ok(mmBars(annotate(zr.log)).length === 0, "S5: the all-zero fixture draws no mm bar");

// Markers: rain, wind, gust and visibility (D-54.4-07)
const mp4 = G.markerPoints("rainwind", ptl, 12, geom, psc);
ok(mp4.length === 4, "S5: markerPoints(rainwind, fixture, 12) has 4 points (rain, wind, gust, vis; got " + mp4.length + ")");
ok(mp4.every(function (p) { return p.y >= geom.plotTop && p.y <= geom.plotBottom; }), "S5: every Graph 2 marker y lies in [plotTop, plotBottom]");
ok(mp4.length === 4 && mp4[1].color === "#ffffff" && mp4[2].color === "#ffffff" && HAS_VIS_FN() && mp4[3].color === G.visColor(ptl[12].atmosphere.visibilityKm)
   && near(mp4[1].y, G.valueToY(ptl[12].wind.speedKmph, 0, psc.wind.max, geom.plotTop, geom.plotBottom))
   && near(mp4[2].y, G.valueToY(ptl[12].wind.gustKmph, 0, psc.wind.max, geom.plotTop, geom.plotBottom))
   && near(mp4[3].y, G.valueToY(ptl[12].atmosphere.visibilityKm, 0, psc.wind.max, geom.plotTop, geom.plotBottom)),
   "S5: wind and gust markers are #ffffff and visibility is visColor, all on the shared wind scale");
function HAS_VIS_FN() { return typeof G.visColor === "function"; }

// Peak labels for the precip variant (D-54.4-10, D-54.4-24, PA-11)
const ppc = G.peakCandidates("rainwind", mockCtx().ctx, geom, ptl, psc);
const mmC = ppc.filter(function (c) { return c.priority === 7; });
ok(mmC.length === 2 && mmC.every(function (c) { return c.color === "#26c6da" && /^\d+\.\d$/.test(c.text); }) && same(mmC.map(function (c) { return c.text; }).sort(), ["0.4", "3.2"]),
   "S5: one mm candidate per bar at priority 7, text toFixed(1), colour #26c6da");
ok(ppc.some(function (c) { return c.priority === 3 && /^\d+$/.test(c.text) && c.color === "#ffffff"; }) && ppc.some(function (c) { return c.priority === 3 && /^G\d+$/.test(c.text); })
   && ppc.some(function (c) { return c.priority === 4 && /^\d+(\.\d)? km$/.test(c.text); }),
   "S5: wind max (priority 3), gust max 'G<n>' (priority 3) and visibility max '<km> km' (priority 4) are candidates");
const pBounds = { left: geom.plotLeft, right: geom.plotRight, top: 0, bottom: geom.plotBottom };
const pPlaced = G.placeLabels(ppc, pBounds, []);
let pClear = true;
for (let a = 0; a < pPlaced.length; ++a) for (let b = a + 1; b < pPlaced.length; ++b) if (G.rectsIntersect(pPlaced[a], pPlaced[b])) pClear = false;
ok(pPlaced.length >= 2 && pClear, "S5: placed Graph 2 labels for the precip variant never intersect (" + pPlaced.map(function (p) { return p.text; }).join(",") + ")");
const mmPlaced = pPlaced.filter(function (p) { return p.color === "#26c6da"; });
const barTopOf = { "3.2": geom.plotBottom - 0.4 * plotH, "0.4": geom.plotBottom - 0.4 / 3.2 * 0.4 * plotH };
ok(mmPlaced.length >= 1 && mmPlaced.every(function (p) { return p.y + p.h <= barTopOf[p.text] + 1e-9; }),
   "S5: every placed mm value sits above its bar, never inside it (D-54.4-24)");
const adj = mkTimeline();
adj[15] = Object.assign({}, adj[15], { moisture: Object.assign({}, adj[15].moisture, { precipMM: 3.1 }) });
adj[16] = Object.assign({}, adj[16], { moisture: Object.assign({}, adj[16].moisture, { precipMM: 3.2 }) });
adj[17] = Object.assign({}, adj[17], { moisture: Object.assign({}, adj[17].moisture, { precipMM: 3.0 }) });
const adjPlaced = G.placeLabels(G.peakCandidates("rainwind", mockCtx().ctx, geom, adj, G.computeScales("rainwind", adj)), pBounds, [])
  .filter(function (p) { return p.color === "#26c6da"; });
ok(adjPlaced.some(function (p) { return p.text === "3.2"; }) && adjPlaced.length < 3, "S5: when neighbouring mm labels collide, the larger value is kept and a smaller one is dropped (" + adjPlaced.map(function (p) { return p.text; }).join(",") + ")");
const dkp = mockCtx();
G.drawKind(dkp.ctx, "rainwind", geom, ptl, psc, THEME);
const dkpTexts = annotate(dkp.log).filter(function (c) { return c.name === "fillText" && c.st.fillStyle === "#26c6da"; });
ok(dkpTexts.length >= 1 && dkpTexts.every(function (c) { return c.st.globalAlpha === 1; }), "S5: drawKind(rainwind) writes the mm values at full opacity, never at the bar alpha (Pitfall 11)");

// Graph 3: UV tier spline (D-54.4-27/29/30)
const ribbonTop = geom.plotBottom - G.RIBBON_H;
const auSc = G.computeScales("airuv", tl);
const ak = mockCtx();
let akThrew = null;
try { G.drawKind(ak.ctx, "airuv", geom, tl, auSc, THEME); } catch (e) { akThrew = e; }
ok(akThrew === null, "S5: drawKind(airuv) on the fixture does not throw" + (akThrew ? " (" + akThrew + ")" : ""));
ok(calls(ak.log, "save").length === calls(ak.log, "restore").length, "S5: drawKind(airuv) save/restore calls are balanced");
const au1 = mockCtx();
G.drawAirUv(au1.ctx, geom, tl, auSc);
const au1Ann = withDash(annotate(au1.log));
const au1Grad = calls(au1.log, "createLinearGradient");
ok(au1Grad.length >= 1 && au1Grad[0][2] === geom.plotTop && au1Grad[0][4] === ribbonTop, "S5: the UV gradient runs vertically from plotTop to the ribbon top (plotBottom - RIBBON_H)");
const au1Stops = au1.log.filter(function (e) { return e[0] === "stop"; });
const uvGradStops = G.tierStops(G.UV_EDGES, G.uvColor, auSc.uv.max, 0);
ok(au1Stops.length >= uvGradStops.length && au1Stops.every(function (e) { return e[1] >= 0 && e[1] <= 1; })
   && same(au1Stops.slice(0, uvGradStops.length).map(function (e) { return e[2]; }), uvGradStops.map(function (s) { return s.color; })),
   "S5: the UV stroke carries tierStops(UV_EDGES, uvColor, uv.max, 0), every offset in [0,1] (Pitfall 1)");
const uvStroke = au1Ann.find(function (c) { return c.name === "stroke" && typeof c.st.strokeStyle === "object"; });
ok(!!uvStroke && uvStroke.st.lineWidth === 2 && same(uvStroke.dash, []), "S5: the UV spline is solid at lineWidth 2");
let auY = true;
let auX = true;
for (const e of au1.log) {
  if (e[0] === "moveTo" && (e[2] < geom.plotTop - 1e-9 || e[2] > ribbonTop + 1e-9)) auY = false;
  if (e[0] === "bezierCurveTo" && (e[6] < geom.plotTop - 1e-9 || e[6] > ribbonTop + 1e-9)) auY = false;
  if (e[0] === "moveTo" && e[1] < minX) auX = false;
  if (e[0] === "bezierCurveTo" && (e[1] < minX || e[3] < minX || e[5] < minX)) auX = false;
}
ok(auY, "S5: every Graph 3 path point lies between plotTop and the ribbon top (the ribbon is never drawn over)");
ok(auX, "S5: no Graph 3 spline enters the unavailable columns (T-54.4-21)");
const s12uv = tl[12].solar.uvIndex;
const amp = G.markerPoints("airuv", tl, 12, geom, auSc);
ok(amp.length >= 1 && amp[0].color === G.uvColor(s12uv) && near(amp[0].y, G.valueToY(s12uv, 0, auSc.uv.max, geom.plotTop, ribbonTop)),
   "S5: markerPoints(airuv, fixture, 12) starts with the UV point in uvColor(uv), on the UV scale above the ribbon");
ok(same(G.markerPoints("airuv", tl, 0, geom, auSc), []), "S5: markerPoints(airuv) at the unavailable index 0 is []");
let uvPk = -Infinity, uvPkI = -1;
tl.forEach(function (s, i) { if (G.isAvailable(s) && s.solar.uvIndex > uvPk) { uvPk = s.solar.uvIndex; uvPkI = i; } });
const apc = G.peakCandidates("airuv", mockCtx().ctx, geom, tl, auSc);
const uvC = apc.find(function (c) { return c.priority === 4; });
ok(!!uvC && uvC.text === String(Math.round(uvPk)) && uvC.color === G.uvColor(uvPk) && uvC.anchor === "above" && near(uvC.x, G.slotCenterX(geom, uvPkI))
   && near(uvC.y, G.valueToY(uvPk, 0, auSc.uv.max, geom.plotTop, ribbonTop)),
   "S5: peakCandidates(airuv) labels the UV max '" + Math.round(uvPk) + "' at priority 4 in uvColor, at its high point");
const uvNight = mkTimeline().map(function (s) { return Object.assign({}, s, { solar: Object.assign({}, s.solar, { uvIndex: 0 }) }); });
ok(!G.peakCandidates("airuv", mockCtx().ctx, geom, uvNight, G.computeScales("airuv", uvNight)).some(function (c) { return c.priority === 4; }),
   "S5: an all-zero UV series gets no UV peak label");
const uvPoison = mkTimeline();
uvPoison[1] = Object.assign({}, uvPoison[1], { solar: Object.assign({}, uvPoison[1].solar, { uvIndex: 12 }) });
ok(!G.peakCandidates("airuv", mockCtx().ctx, geom, uvPoison, G.computeScales("airuv", uvPoison)).some(function (c) { return c.text === "12"; }),
   "S5: a historical-unavailable slot never yields a UV peak label");

// Graph 3: EPA tier ribbon (D-54.4-27/28, T-54.4-17)
const etl = mkTimeline({ epa: true });
const esc = G.computeScales("airuv", etl);
const er = mockCtx();
G.drawAirUv(er.ctx, geom, etl, esc);
const erAnn = withDash(annotate(er.log));
const ribbon = erAnn.filter(function (c) { return c.name === "fillRect" && c.args[3] === G.RIBBON_H; });
const wantRibbon = [];
etl.forEach(function (s, i) {
  const e = s.aqi.epaIndex;
  if (G.isAvailable(s) && Number.isInteger(e) && e >= 1 && e <= 6) wantRibbon.push([i, e]);
});
ok(ribbon.length === wantRibbon.length && wantRibbon.length === 21,
   "S5: the epa variant records one ribbon fillRect per available slot with epaIndex 1-6 (" + ribbon.length + " of " + wantRibbon.length + ")");
let ribOk = ribbon.length === wantRibbon.length;
for (let k = 0; ribOk && k < ribbon.length; ++k) {
  const [i, e] = wantRibbon[k];
  const c = ribbon[k];
  if (!(near(c.args[0], geom.plotLeft + i * geom.slotW) && near(c.args[1], ribbonTop) && near(c.args[2], geom.slotW) && c.st.fillStyle === G.EPA_COLORS[e] && c.st.globalAlpha === 1)) ribOk = false;
}
ok(ribOk, "S5: each ribbon segment spans its slot column at y = plotBottom - RIBBON_H, in EPA_COLORS[epaIndex] at globalAlpha 1");
ok(!ribbon.some(function (c) { return near(c.args[0], geom.plotLeft + 5 * geom.slotW); }), "S5: the epaIndex 0 slot (index 5) gets no ribbon segment");
ok(!ribbon.some(function (c) { return c.args[0] < geom.plotLeft + 3 * geom.slotW - 1e-9; }), "S5: unavailable slots get no ribbon segment (T-54.4-21)");
ok(ribbon.some(function (c) { return c.st.fillStyle === "#66bb6a"; }) && ribbon.some(function (c) { return c.st.fillStyle === "#c2185b"; }),
   "S5: the epa variant ribbon carries Good (index 1) and Hazardous (index 6) segments");

// Graph 3: solar bars (D-54.4-29, T-54.4-16)
const solarBars = erAnn.filter(function (c) { return c.name === "fillRect" && c.st.fillStyle === "#ffb300" && c.st.globalAlpha === 0.45; });
const wantSolar = [];
etl.forEach(function (s, i) { if (G.isAvailable(s) && s.solar.shortRad > 0) wantSolar.push(i); });
ok(solarBars.length === wantSolar.length && wantSolar.length > 0, "S5: one solar fillRect per available slot with shortRad > 0 at #ffb300 and alpha 0.45 (" + solarBars.length + " of " + wantSolar.length + ")");
const solarPlotH = ribbonTop - geom.plotTop;
const solarW = Math.max(2, geom.slotW * 0.6);
ok(solarBars.length > 0 && solarBars.every(function (c) { return c.args[3] <= G.BAR_CAP * solarPlotH + 0.5 && near(c.args[1] + c.args[3], ribbonTop) && near(c.args[2], solarW); }),
   "S5: every solar bar is max(2, slotW*0.6) wide, at most BAR_CAP of the plot above the ribbon tall, and stands on the ribbon top");
const radMax = esc.solar ? esc.solar.max : NaN;
let solarGeo = solarBars.length === wantSolar.length;
for (let k = 0; solarGeo && k < solarBars.length; ++k) {
  const i = wantSolar[k];
  const c = solarBars[k];
  if (!near(c.args[0] + c.args[2] / 2, G.slotCenterX(geom, i)) || !near(c.args[3], etl[i].solar.shortRad / radMax * G.BAR_CAP * solarPlotH)) solarGeo = false;
}
ok(solarGeo, "S5: each solar bar is centred on its slot with height shortRad / solar.max * BAR_CAP * (ribbonTop - plotTop)");
const erFirstStroke = erAnn.findIndex(function (c) { return c.name === "stroke"; });
const erLastFill = erAnn.map(function (c) { return c.name; }).lastIndexOf("fillRect");
ok(erLastFill >= 0 && erFirstStroke > erLastFill, "S5: the ribbon and the solar bars are drawn before the lines");
ok(calls(er.log, "save").length === calls(er.log, "restore").length, "S5: drawAirUv save/restore calls are balanced");
const radPoison = mkTimeline();
radPoison[1] = Object.assign({}, radPoison[1], { solar: Object.assign({}, radPoison[1].solar, { shortRad: 900 }) });
const rp2 = mockCtx();
G.drawAirUv(rp2.ctx, geom, radPoison, G.computeScales("airuv", radPoison));
ok(annotate(rp2.log).filter(function (c) { return c.name === "fillRect" && c.st.fillStyle === "#ffb300"; }).every(function (c) { return c.args[0] >= geom.plotLeft + 3 * geom.slotW; }),
   "S5: no solar bar falls in an unavailable column (T-54.4-21)");
const darkTl = mkTimeline().map(function (s) {
  if (!G.isAvailable(s)) return s;
  return Object.assign({}, s, { solar: Object.assign({}, s.solar, { shortRad: 0, uvIndex: 0 }) });
});
const dk = mockCtx();
let dkThrew = null;
try { G.drawKind(dk.ctx, "airuv", geom, darkTl, G.computeScales("airuv", darkTl), THEME); } catch (e) { dkThrew = e; }
let dkFinite = true;
for (const e of dk.log) for (const a of e.slice(1)) if (typeof a === "number" && !isFinite(a)) dkFinite = false;
ok(dkThrew === null && dkFinite, "S5: drawKind(airuv) with every shortRad and UV at 0 records only finite numbers (no 0/0, T-54.4-16)");
ok(annotate(dk.log).filter(function (c) { return c.name === "fillRect" && c.st.fillStyle === "#ffb300"; }).length === 0, "S5: a sunless window draws no solar bar");

// Graph 3 strokes: only the drawn series, nothing derived from pm2_5, pm10, diffRad or DEFRA (D-54.4-27)
const auRuns = G.seriesRuns(tl, function (s) { return s.solar.uvIndex; }, Object.assign({}, geom, { plotBottom: ribbonTop }), auSc.uv).filter(function (r) { return r.length >= 2; });
ok(calls(au1.log, "stroke").length === auRuns.length, "S5: at this stage drawAirUv strokes exactly the UV runs (" + calls(au1.log, "stroke").length + " of " + auRuns.length + ")");

// Graph 3: solar peak value (D-54.4-29)
let radPkI = -1;
let radPkV = -Infinity;
tl.forEach(function (s, i) { if (G.isAvailable(s) && s.solar.shortRad > radPkV) { radPkV = s.solar.shortRad; radPkI = i; } });
const solC = apc.find(function (c) { return c.priority === 6; });
const solBarTop = auSc.solar ? ribbonTop - radPkV / auSc.solar.max * G.BAR_CAP * solarPlotH : NaN;
ok(!!solC && solC.text === Math.round(radPkV) + " W/m²" && solC.color === "#ffb300" && near(solC.x, G.slotCenterX(geom, radPkI)) && near(solC.y, solBarTop),
   "S5: peakCandidates(airuv) writes the solar peak '" + Math.round(radPkV) + " W/m²' at priority 6 in #ffb300, anchored at the tallest bar top");
ok(!!solC && solC.anchor === "bar-top", "S5: the solar peak value uses the bar-top anchor, so it is written above its bar and never inside it");
ok(!G.peakCandidates("airuv", mockCtx().ctx, geom, darkTl, G.computeScales("airuv", darkTl)).some(function (c) { return c.priority === 6; }),
   "S5: a sunless window gets no solar peak label");
ok(!G.peakCandidates("airuv", mockCtx().ctx, geom, radPoison, G.computeScales("airuv", radPoison)).some(function (c) { return c.text === "900 W/m²"; }),
   "S5: a historical-unavailable slot never yields a solar peak label");
const ak2 = mockCtx();
G.drawKind(ak2.ctx, "airuv", geom, tl, auSc, THEME);
const ak2Solar = annotate(ak2.log).filter(function (c) { return c.name === "fillText" && /W\/m²$/.test(String(c.args[0])); });
ok(ak2Solar.length === 1 && ak2Solar[0].st.globalAlpha === 1 && ak2Solar[0].st.fillStyle === "#ffb300", "S5: drawKind(airuv) writes the solar peak at full opacity, never at the bar alpha (Pitfall 11)");
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
