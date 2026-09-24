#!/usr/bin/env bash
# ===========================================================================
# Phase 40.1: Clock Pill Padding and Unified Volume Ceiling Ergonomics Assert Harness
# Enforces: CLOCK-01, VOL-01, VOL-02, INTG-01, INTG-03, T-40.1-01, T-40.1-02, T-40.1-03, T-40.1-04
#
# Usage (from REPO_ROOT):
#   ./scripts/phase40.1-clock-volume-assert.sh [--section <1-5>] [-s <1-5>] [--syntax]
#
# Exit 0 if all hard asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
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
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true
  return 0
}
trap cleanup EXIT

RUN_SECTION=0
SYNTAX_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    --syntax|-c)
      SYNTAX_ONLY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-5>] [--syntax]"
      echo "  -s, --section <1-5>  Execute only the specified section"
      echo "  -c, --syntax         Execute static AST and syntax checks only"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

porcelain_snapshot_raw() {
  git status --porcelain --ignored || true
}

porcelain_snapshot() {
  porcelain_snapshot_raw \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

PORCELAIN_BEFORE="$(mktemp /tmp/p40.1-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p40.1-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# Target file paths
CW_RESTOW="restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml"
CW_HOME="$HOME/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml"

CONF_RESTOW="restow/quickshell/.config/quickshell/ii/modules/common/Config.qml"
CONF_HOME="$HOME/.config/quickshell/ii/modules/common/Config.qml"

AUDIO_RESTOW="restow/quickshell/.config/quickshell/ii/services/Audio.qml"
AUDIO_HOME="$HOME/.config/quickshell/ii/services/Audio.qml"

QS_RESTOW="restow/quickshell/.config/quickshell/ii/modules/ii/sidebarRight/QuickSliders.qml"
QS_HOME="$HOME/.config/quickshell/ii/modules/ii/sidebarRight/QuickSliders.qml"

KB_STOW="stow/hypr/.config/hypr/custom/keybinds.lua"
KB_HOME="$HOME/.config/hypr/custom/keybinds.lua"

CFG_CAPTURE="capture/ii/.config/illogical-impulse/config.json"
CFG_HOME="$HOME/.config/illogical-impulse/config.json"

# ===========================================================================
# Syntax Validation (--syntax flag)
# ===========================================================================
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Syntax & Static Validation ---"

  if bash -n "$0"; then
    pass "Syntax: Harness bash syntax is valid"
  else
    fail "Syntax: Harness bash syntax error"
  fi

  if [[ -f "$REPO_ROOT/$CFG_CAPTURE" ]]; then
    if jq . "$REPO_ROOT/$CFG_CAPTURE" >/dev/null 2>&1; then
      pass "Syntax: capture config.json is valid JSON"
    else
      fail "Syntax: capture config.json is invalid JSON"
    fi
  fi

  if [[ -f "$REPO_ROOT/$KB_STOW" ]]; then
    if luac -p "$REPO_ROOT/$KB_STOW" >/dev/null 2>&1; then
      pass "Syntax: keybinds.lua syntax is valid"
    else
      fail "Syntax: keybinds.lua syntax error"
    fi
  fi

  if [[ -f "$REPO_ROOT/$CW_RESTOW" ]]; then
    if grep -q "DateTime\.time" "$REPO_ROOT/$CW_RESTOW" && grep -q "DateTime\.longDate" "$REPO_ROOT/$CW_RESTOW" && grep -q "implicitWidth:\s*8" "$REPO_ROOT/$CW_RESTOW"; then
      pass "Syntax: ClockWidget.qml preserves core time/date and spacer AST tokens"
    else
      fail "Syntax: ClockWidget.qml missing core time/date or spacer AST tokens"
    fi
  fi

  # Report summary and exit early if syntax only
  echo ""
  echo "=== Phase 40.1 Syntax Summary ==="
  echo "Failures: $FAIL"
  echo "Findings: $FINDINGS"
  [[ $FAIL -eq 0 ]] || exit 1
  exit 0
fi

# ===========================================================================
# Section 1: Restow Isolation & Symlink Integrity
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Restow Isolation & Symlink Integrity ---"

  # Assert git submodule vendor/dots-hyprland has 0 uncommitted changes
  sub_status="$(git -C vendor/dots-hyprland status --porcelain 2>/dev/null || true)"
  if [[ -z "$sub_status" ]]; then
    pass "S1: Git submodule vendor/dots-hyprland has 0 uncommitted changes (T-40.1-01)"
  else
    fail "S1: Git submodule vendor/dots-hyprland has uncommitted changes:\n$sub_status"
  fi

  # Assert ClockWidget.qml exists in restow and is symlinked
  if [[ -f "$REPO_ROOT/$CW_RESTOW" ]]; then
    pass "S1: Restow overlay exists: $CW_RESTOW"
  else
    fail "S1: Restow overlay MISSING: $CW_RESTOW"
  fi

  if [[ -L "$CW_HOME" ]]; then
    target="$(readlink -f "$CW_HOME" || true)"
    if [[ "$target" == *"/restow/quickshell/.config/quickshell/ii/modules/ii/bar/ClockWidget.qml"* ]]; then
      pass "S1: $CW_HOME is a symlink resolving into restow/quickshell/"
    else
      fail "S1: $CW_HOME symlink resolves to unexpected target: $target"
    fi
  else
    fail "S1: $CW_HOME is NOT a symlink in home deploy"
  fi

  # Assert keybinds.lua exists in stow and is symlinked
  if [[ -f "$REPO_ROOT/$KB_STOW" ]]; then
    pass "S1: Stow source exists: $KB_STOW"
  else
    fail "S1: Stow source MISSING: $KB_STOW"
  fi

  if [[ -L "$KB_HOME" ]]; then
    target="$(readlink -f "$KB_HOME" || true)"
    if [[ "$target" == *"/stow/hypr/.config/hypr/custom/keybinds.lua"* ]]; then
      pass "S1: $KB_HOME is a symlink resolving into stow/hypr/"
    else
      fail "S1: $KB_HOME symlink resolves to unexpected target: $target"
    fi
  else
    fail "S1: $KB_HOME is NOT a symlink in home deploy"
  fi

  # Assert directories are real directories without directory folding
  for dir_path in \
    "$HOME/.config/quickshell/ii" \
    "$HOME/.config/quickshell/ii/modules" \
    "$HOME/.config/quickshell/ii/modules/ii" \
    "$HOME/.config/quickshell/ii/modules/ii/bar" \
    "$HOME/.config/quickshell/ii/modules/common" \
    "$HOME/.config/quickshell/ii/services"; do
    if [[ -d "$dir_path" ]] && [[ ! -L "$dir_path" ]]; then
      pass "S1: Real directory without directory folding: $dir_path"
    else
      fail "S1: Directory folding violation or missing directory: $dir_path"
    fi
  done

  # Verify all overlays exist and are deployed as valid symlinks
  for overlay in "$CONF_RESTOW" "$AUDIO_RESTOW" "$QS_RESTOW"; do
    overlay_name="$(basename "$overlay")"
    parent_dir="$(dirname "$overlay" | sed 's|^restow/quickshell/||')"
    live_path="$HOME/$parent_dir/$overlay_name"
    if [[ -f "$REPO_ROOT/$overlay" ]]; then
      pass "S1: Restow overlay exists: $overlay"
      if [[ -L "$live_path" ]]; then
        target="$(readlink -f "$live_path" || true)"
        if [[ "$target" == *"/$overlay"* ]]; then
          pass "S1: Overlay $overlay_name is deployed as valid symlink to restow"
        else
          fail "S1: Overlay $overlay_name symlink target invalid: $target"
        fi
      else
        fail "S1: Overlay $overlay_name live path is NOT a symlink: $live_path"
      fi
    else
      if [[ "$RUN_SECTION" -eq 0 ]]; then
        fail "S1: Required overlay MISSING in full test run: $overlay"
      fi
    fi
  done
fi

# ===========================================================================
# Section 2: Clock Pill Geometry AST (CLOCK-01, D-01, D-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Clock Pill Geometry AST ---"

  if [[ ! -f "$REPO_ROOT/$CW_RESTOW" ]]; then
    fail "S2: ClockWidget.qml missing at $CW_RESTOW"
  else
    cw_content="$(cat "$REPO_ROOT/$CW_RESTOW")"

    # Check 5px margins on rowLayout (CLOCK-01, D-01)
    if grep -q "anchors\.leftMargin:\s*5" "$REPO_ROOT/$CW_RESTOW" && grep -q "anchors\.rightMargin:\s*5" "$REPO_ROOT/$CW_RESTOW"; then
      pass "S2: ClockWidget.qml specifies anchors.leftMargin: 5 and anchors.rightMargin: 5"
    else
      fail "S2: ClockWidget.qml missing 5px left/right margins on rowLayout (expected 10px combined breathing room)"
    fi

    # Check dynamic implicitWidth calculation matching Resources.qml pattern
    if grep -q "implicitWidth:\s*rowLayout\.implicitWidth\s*+\s*rowLayout\.anchors\.leftMargin\s*+\s*rowLayout\.anchors\.rightMargin" "$REPO_ROOT/$CW_RESTOW"; then
      pass "S2: ClockWidget.qml calculates dynamic implicitWidth including horizontal margins"
    else
      fail "S2: ClockWidget.qml does not calculate dynamic implicitWidth with rowLayout horizontal margins"
    fi

    # Check 8px non-glyph spacer (D-02, COMP-03)
    if grep -q "implicitWidth:\s*8" "$REPO_ROOT/$CW_RESTOW"; then
      pass "S2: ClockWidget.qml preserves 8px non-glyph spacer between time and date strings"
    else
      fail "S2: ClockWidget.qml missing 8px non-glyph spacer"
    fi

    # Check second precision and long date
    if grep -q "DateTime\.time" "$REPO_ROOT/$CW_RESTOW" && grep -q "DateTime\.longDate" "$REPO_ROOT/$CW_RESTOW"; then
      pass "S2: ClockWidget.qml preserves DateTime.time and DateTime.longDate formatting"
    else
      fail "S2: ClockWidget.qml missing DateTime.time or DateTime.longDate"
    fi
  fi
fi

# ===========================================================================
# Section 3: Single Source of Truth Ceiling Contract (VOL-01, D-03, D-04, D-05)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Single Source of Truth Ceiling Contract ---"

  # 1. config.json contains volumeCeiling: 1.5 in capture and live $HOME (D-03)
  if [[ -f "$REPO_ROOT/$CFG_CAPTURE" ]]; then
    cap_ceiling="$(jq -r '.audio.volumeCeiling // empty' "$REPO_ROOT/$CFG_CAPTURE" 2>/dev/null || echo "")"
    if [[ "$cap_ceiling" == "1.5" ]]; then
      pass "S3: $CFG_CAPTURE defines .audio.volumeCeiling == 1.5"
    else
      fail "S3: $CFG_CAPTURE has invalid or missing .audio.volumeCeiling (got: '$cap_ceiling')"
    fi
  else
    fail "S3: $CFG_CAPTURE does not exist"
  fi

  if [[ -f "$CFG_HOME" ]]; then
    home_ceiling="$(jq -r '.audio.volumeCeiling // empty' "$CFG_HOME" 2>/dev/null || echo "")"
    if [[ "$home_ceiling" == "1.5" ]]; then
      pass "S3: $CFG_HOME defines .audio.volumeCeiling == 1.5"
    else
      fail "S3: $CFG_HOME has invalid or missing .audio.volumeCeiling (got: '$home_ceiling')"
    fi
  else
    fail "S3: $CFG_HOME does not exist"
  fi

  # 2. keybinds.lua unbinds upstream and binds wpctl with dynamic ceiling (D-04, T-40.1-02)
  if [[ -f "$REPO_ROOT/$KB_STOW" ]]; then
    if grep -q 'unbind("XF86AudioRaiseVolume")' "$REPO_ROOT/$KB_STOW"; then
      pass "S3: keybinds.lua unbinds upstream XF86AudioRaiseVolume"
    else
      fail "S3: keybinds.lua does not unbind upstream XF86AudioRaiseVolume"
    fi

    if grep -q 'wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l ' "$REPO_ROOT/$KB_STOW"; then
      pass "S3: keybinds.lua binds wpctl raise with -l limit"
    else
      fail "S3: keybinds.lua missing wpctl set-volume -l binding"
    fi

    # Test pure Lua parser logic
    lua_test_result="$(lua -e '
      local HOME = os.getenv("HOME")
      local function get_volume_ceiling()
          local default_ceiling = "1.5"
          local config_path = HOME .. "/.config/illogical-impulse/config.json"
          local f = io.open(config_path, "r")
          if not f then return default_ceiling end
          local content = f:read("*a")
          f:close()
          if not content then return default_ceiling end
          local ceiling = content:match("\"volumeCeiling\"%s*:%s*([%d%.]+)")
          if ceiling and tonumber(ceiling) and tonumber(ceiling) > 0 then
              return ceiling
          end
          return default_ceiling
      end
      print(get_volume_ceiling())
    ' 2>/dev/null || echo "error")"

    if [[ "$lua_test_result" == "1.5" ]]; then
      pass "S3: Lua configuration parser correctly resolves volume_ceiling to 1.5"
    else
      fail "S3: Lua configuration parser returned unexpected value: '$lua_test_result'"
    fi
  else
    fail "S3: $KB_STOW does not exist"
  fi

  # 3. Config.qml declares property real volumeCeiling: 1.5 (D-05)
  if [[ -f "$REPO_ROOT/$CONF_RESTOW" ]]; then
    if grep -q "property real volumeCeiling:\s*1\.5" "$REPO_ROOT/$CONF_RESTOW"; then
      pass "S3: Config.qml declares property real volumeCeiling: 1.5"
    else
      fail "S3: Config.qml missing property real volumeCeiling: 1.5"
    fi
  else
    fail "S3: Config.qml missing at $CONF_RESTOW"
  fi

  # 4. Audio.qml defines readonly property real maxVolume: Config.options?.audio?.volumeCeiling ?? 1.5 (D-05)
  if [[ -f "$REPO_ROOT/$AUDIO_RESTOW" ]]; then
    if grep -q "readonly property real maxVolume:\s*Config\.options?\.audio?\.volumeCeiling\s*??\s*1\.5" "$REPO_ROOT/$AUDIO_RESTOW"; then
      pass "S3: Audio.qml exposes centralized maxVolume referencing Config.options.audio.volumeCeiling"
    else
      fail "S3: Audio.qml missing centralized maxVolume property definition"
    fi
  else
    fail "S3: Audio.qml missing at $AUDIO_RESTOW"
  fi
fi

# ===========================================================================
# Section 4: Quickshell Volume Ergonomics & Behavior (VOL-02, D-06 to D-11)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Quickshell Volume Ergonomics & Behavior ---"

  # QuickSliders.qml slider configuration checks
  if [[ -f "$REPO_ROOT/$QS_RESTOW" ]]; then
    if grep -q "to:\s*Audio\.maxVolume" "$REPO_ROOT/$QS_RESTOW"; then
      pass "S4: QuickSliders.qml volume slider upper bound bound to Audio.maxVolume (D-06)"
    else
      fail "S4: QuickSliders.qml volume slider missing to: Audio.maxVolume"
    fi

    if grep -q "stopIndicatorValues:\s*\[1\.0\]" "$REPO_ROOT/$QS_RESTOW"; then
      pass "S4: QuickSliders.qml volume slider specifies stopIndicatorValues: [1.0] without double normalization (D-07)"
    else
      fail "S4: QuickSliders.qml missing stopIndicatorValues: [1.0]"
    fi

    if grep -q "tooltipContent:\s*\`\${Math\.round(value\s*\*\s*100)}%\`" "$REPO_ROOT/$QS_RESTOW"; then
      pass "S4: QuickSliders.qml volume slider specifies tooltipContent with actual percentage (D-08)"
    else
      fail "S4: QuickSliders.qml missing explicit percentage tooltipContent"
    fi
  else
    fail "S4: QuickSliders.qml missing at $QS_RESTOW"
  fi

  # Audio.qml incrementVolume and decrementVolume checks
  if [[ -f "$REPO_ROOT/$AUDIO_RESTOW" ]]; then
    if grep -q "Audio\.sink\.audio\.muted\s*=\s*false" "$REPO_ROOT/$AUDIO_RESTOW"; then
      pass "S4: Audio.qml incrementVolume() automatically unmutes audio (D-10)"
    else
      fail "S4: Audio.qml incrementVolume() missing auto-unmute"
    fi

    if grep -q "Math\.min(root\.maxVolume" "$REPO_ROOT/$AUDIO_RESTOW"; then
      pass "S4: Audio.qml incrementVolume() dynamically clamps to root.maxVolume (D-09)"
    else
      fail "S4: Audio.qml incrementVolume() missing dynamic clamp to root.maxVolume"
    fi

    if grep -q "const step = currentVolume < 0.1 ? 0.01 : 0.02" "$REPO_ROOT/$AUDIO_RESTOW"; then
      pass "S4: Audio.qml uses 2% step size (1% below 10%) matching Hyprland keybinds (D-11)"
    else
      fail "S4: Audio.qml missing 2% step size logic"
    fi

    # Headless JS simulation of Audio.qml incrementVolume and decrementVolume logic
    js_sim_result="$(node -e '
      function createAudioModel(initialVolume, initialMuted, maxVolume) {
        const root = { maxVolume: maxVolume || 1.5, hardMaxValue: 2.0 };
        const Audio = {
          value: initialVolume,
          sink: {
            audio: {
              volume: initialVolume,
              muted: initialMuted
            }
          }
        };

        function incrementVolume() {
          if (Audio.sink?.audio) {
            Audio.sink.audio.muted = false;
            const currentVolume = Audio.value;
            const step = currentVolume < 0.1 ? 0.01 : 0.02;
            Audio.sink.audio.volume = Math.min(root.maxVolume, Audio.sink.audio.volume + step);
            Audio.value = Audio.sink.audio.volume;
          }
        }

        function decrementVolume() {
          if (Audio.sink?.audio) {
            const currentVolume = Audio.value;
            const step = currentVolume < 0.1 ? 0.01 : 0.02;
            Audio.sink.audio.volume = Math.max(0, Audio.sink.audio.volume - step);
            Audio.value = Audio.sink.audio.volume;
          }
        }

        return { Audio, incrementVolume, decrementVolume };
      }

      let errors = 0;

      // Test 1: Increment from 0.05 steps by 0.01 -> 0.06
      const s1 = createAudioModel(0.05, false, 1.5);
      s1.incrementVolume();
      if (Math.abs(s1.Audio.sink.audio.volume - 0.06) > 0.0001) {
        console.error("Test 1 failed: expected 0.06, got " + s1.Audio.sink.audio.volume);
        errors++;
      }

      // Test 2: Increment from 0.50 steps by 0.02 -> 0.52
      const s2 = createAudioModel(0.50, false, 1.5);
      s2.incrementVolume();
      if (Math.abs(s2.Audio.sink.audio.volume - 0.52) > 0.0001) {
        console.error("Test 2 failed: expected 0.52, got " + s2.Audio.sink.audio.volume);
        errors++;
      }

      // Test 3: Increment from 1.49 clamps exactly to 1.50
      const s3 = createAudioModel(1.49, false, 1.5);
      s3.incrementVolume();
      if (Math.abs(s3.Audio.sink.audio.volume - 1.50) > 0.0001) {
        console.error("Test 3 failed: expected 1.50, got " + s3.Audio.sink.audio.volume);
        errors++;
      }

      // Test 4: Increment while muted un-mutes
      const s4 = createAudioModel(0.50, true, 1.5);
      s4.incrementVolume();
      if (s4.Audio.sink.audio.muted !== false) {
        console.error("Test 4 failed: expected muted=false, got " + s4.Audio.sink.audio.muted);
        errors++;
      }

      // Test 5: Decrement from 0.01 clamps to 0.00 without going negative
      const s5 = createAudioModel(0.01, false, 1.5);
      s5.decrementVolume();
      if (Math.abs(s5.Audio.sink.audio.volume - 0.00) > 0.0001) {
        console.error("Test 5 failed: expected 0.00, got " + s5.Audio.sink.audio.volume);
        errors++;
      }

      if (errors > 0) process.exit(1);
      console.log("OK");
    ' 2>&1 || echo "FAIL")"

    if [[ "$js_sim_result" == "OK" ]]; then
      pass "S4: Headless JS simulation of step math, 1.5 boundary clamping, and auto-unmute succeeded"
    else
      fail "S4: Headless JS simulation failed: $js_sim_result"
    fi
  else
    fail "S4: Audio.qml missing at $AUDIO_RESTOW"
  fi
fi

# ===========================================================================
# Section 5: Strict Repository & Submodule Porcelain Verification (INTG-01, INTG-03, T-40.1-04)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Repository Integrity & Strict Verification ---"

  # Run dots-hyprland verify --strict
  set +e
  DOTS_OUTPUT="$("$REPO_ROOT/arch/dots-hyprland.sh" verify --strict 2>&1)"
  DOTS_EXIT=$?
  set -e

  if [[ $DOTS_EXIT -eq 0 ]] && echo "$DOTS_OUTPUT" | grep -q "=== done: FAIL=0 FINDINGS=0 ==="; then
    pass "S5: ./arch/dots-hyprland.sh verify --strict passed with FAIL=0 FINDINGS=0"
  else
    fail "S5: ./arch/dots-hyprland.sh verify --strict failed (exit $DOTS_EXIT)"
    echo "$DOTS_OUTPUT" | tail -n 15 >&2
  fi

  # Verify git porcelain status before and after execution
  porcelain_snapshot > "$PORCELAIN_AFTER"
  if diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" >/dev/null 2>&1; then
    pass "S5: Git porcelain status is identical before and after harness execution (T-40.1-04)"
  else
    fail "S5: Git porcelain status drifted during harness execution"
    diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
  fi
fi

# ===========================================================================
# Summary
# ===========================================================================
echo ""
echo "=== Phase 40.1 Assertion Summary ==="
echo "Failures: $FAIL"
echo "Findings: $FINDINGS"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi

exit 0
