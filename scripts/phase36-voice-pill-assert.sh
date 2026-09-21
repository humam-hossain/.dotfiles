#!/usr/bin/env bash
# ===========================================================================
# Phase 36: Visual Voice Pill Component & Dynamic Animations Assert Harness
# Enforces: VOICE-01, VOICE-02, VOICE-03, VOICE-04, VOICE-05, VOICE-06, D-01 through D-09
#
# Usage (from REPO_ROOT):
#   ./scripts/phase36-voice-pill-assert.sh [--section <1-6>] [-s <1-6>] [--syntax]
#
# Exit 0 if all hard asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if run as root
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
TMP_DIRS=()
MOCK_PIDS=()

cleanup() {
  for pid in ${MOCK_PIDS[@]+"${MOCK_PIDS[@]}"}; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" 2>/dev/null || true
    fi
  done

  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true

  for dir in ${TMP_DIRS[@]+"${TMP_DIRS[@]}"}; do
    [[ -n "$dir" && -d "$dir" ]] && rm -rf "$dir" 2>/dev/null || true
  done

  return 0
}
trap cleanup EXIT

RUN_SECTION=0
SYNTAX_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section|-s)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-6]$ ]]; then
        echo "Error: --section requires an integer from 1 to 6" >&2
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
      echo "Usage: $0 [--section <1-6>] [--syntax]"
      echo "  -s, --section <1-6>  Execute only the specified section"
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

PORCELAIN_BEFORE="$(mktemp /tmp/p36-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p36-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

create_mock_voice_runtime() {
  local rt
  rt="$(mktemp -d /tmp/p36-rt-XXXXXX)"
  mkdir -p "$rt/voice-stt"
  local real_xdg="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  if [[ -n "${WAYLAND_DISPLAY:-}" && -e "$real_xdg/$WAYLAND_DISPLAY" ]]; then
    ln -s "$real_xdg/$WAYLAND_DISPLAY" "$rt/$WAYLAND_DISPLAY" 2>/dev/null || true
  fi
  printf '%s' "$rt"
}

# Helper to run a headless Quickshell QML snippet inside ~/.config/quickshell/ii/
run_qs_test() {
  local qml_content="$1"
  local runtime_dir="${2:-}"
  local timeout_sec="${3:-4.5}"

  local runner_file
  runner_file="$(mktemp "${XDG_CONFIG_HOME}/quickshell/ii/p36_runner_XXXXXX.qml")"
  TMP_FILES+=("$runner_file")

  printf '%s\n' "$qml_content" > "$runner_file"

  local out=""
  if [[ -n "$runtime_dir" ]]; then
    out="$(XDG_RUNTIME_DIR="$runtime_dir" timeout "${timeout_sec}s" quickshell -p "$runner_file" 2>&1 || true)"
  else
    out="$(timeout "${timeout_sec}s" quickshell -p "$runner_file" 2>&1 || true)"
  fi

  rm -f "$runner_file" 2>/dev/null || true
  printf '%s\n' "$out"
}

VOICE_PILL_REPO="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml"
VOICE_PILL_LIVE="$XDG_CONFIG_HOME/quickshell/ii/modules/ii/bar/VoicePill.qml"

# ===========================================================================
# Section 1: Foundation, Deployment & Configuration (VOICE-01, D-01)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Foundation, Deployment & Configuration (VOICE-01, D-01) ---"

  if [[ -f "$VOICE_PILL_REPO" ]]; then
    pass "S1: VoicePill.qml exists in restow tree: $VOICE_PILL_REPO"
  else
    fail "S1: VoicePill.qml missing from restow tree: $VOICE_PILL_REPO"
  fi

  if [[ -L "$VOICE_PILL_LIVE" ]]; then
    target="$(readlink "$VOICE_PILL_LIVE")"
    if [[ "$target" == *"restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml"* ]]; then
      pass "S1: VoicePill.qml is deployed as live symlink into restow: $target"
    else
      fail "S1: VoicePill.qml symlink points elsewhere: $target"
    fi
  else
    fail "S1: VoicePill.qml is not a live symlink: $VOICE_PILL_LIVE"
  fi

  # Ancestor directory realness check (no directory folding)
  LIVE_BAR_DIR="$XDG_CONFIG_HOME/quickshell/ii/modules/ii/bar"
  if [[ -d "$LIVE_BAR_DIR" && ! -L "$LIVE_BAR_DIR" ]]; then
    pass "S1: Parent directory $LIVE_BAR_DIR is a real directory (no folding)"
  else
    fail "S1: Parent directory $LIVE_BAR_DIR is symlinked or missing (folded)"
  fi

  # Check pragmas and root element
  if grep -q "pragma ComponentBehavior: Bound" "$VOICE_PILL_REPO"; then
    pass "S1: VoicePill.qml declares pragma ComponentBehavior: Bound"
  else
    fail "S1: VoicePill.qml missing pragma ComponentBehavior: Bound"
  fi

  if grep -q "BarGroup {" "$VOICE_PILL_REPO"; then
    pass "S1: VoicePill.qml root container is BarGroup (inherits 12px radius, 5px padding, colLayer1)"
  else
    fail "S1: VoicePill.qml root container is not BarGroup"
  fi

  if grep -q "clip: true" "$VOICE_PILL_REPO"; then
    pass "S1: VoicePill.qml declares clip: true"
  else
    fail "S1: VoicePill.qml missing clip: true"
  fi

  # Headless initial idle state check
  if [[ "$SYNTAX_ONLY" -eq 0 ]]; then
    QML_S1=$(cat << 'EOF'
import QtQuick
import Quickshell
import "modules/ii/bar"
import "services"

Scope {
    VoicePill {
        id: pill
    }
    Component.onCompleted: {
        console.log("PILL_INIT width=" + Math.round(pill.implicitWidth) + " text='" + pill.displayText + "' expanded=" + pill.isExpanded + " state=" + pill.effectiveState);
        Qt.quit();
    }
}
EOF
)
    OUT_S1="$(run_qs_test "$QML_S1")"
    if echo "$OUT_S1" | grep -q "PILL_INIT width=26 text='' expanded=false state=idle"; then
      pass "S1: VoicePill initializes in compact resting state (26px, icon only, idle, not expanded)"
    else
      fail "S1: VoicePill initial idle state check failed: $OUT_S1"
    fi
  fi
fi

# ===========================================================================
# Section 2: Component AST & Static Theming (VOICE-02, D-02, D-03, D-05, D-09)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Component AST & Static Theming (VOICE-02, D-02, D-03, D-05, D-09) ---"

  # Zero hardcoded hex colors
  HEX_MATCHES="$(grep -n -E "#[0-9a-fA-F]{3,8}" "$VOICE_PILL_REPO" || true)"
  if [[ -z "$HEX_MATCHES" ]]; then
    pass "S2: Zero hardcoded hex colors found in VoicePill.qml (D-09)"
  else
    fail "S2: Hardcoded hex colors detected in VoicePill.qml: $HEX_MATCHES"
  fi

  # AI identity icon declaration (graphic_eq via MaterialSymbol)
  if grep -q 'text: "graphic_eq"' "$VOICE_PILL_REPO" && grep -q "MaterialSymbol" "$VOICE_PILL_REPO"; then
    pass "S2: Renders graphic_eq glyph via MaterialSymbol widget (VOICE-02, D-02)"
  else
    fail "S2: Missing graphic_eq glyph or MaterialSymbol usage in VoicePill.qml"
  fi

  # Material You palette tokens
  if grep -q "Appearance.colors.colPrimary" "$VOICE_PILL_REPO" && \
     grep -q "Appearance.colors.colTertiary" "$VOICE_PILL_REPO" && \
     grep -q "Appearance.colors.colSecondary" "$VOICE_PILL_REPO" && \
     grep -q "Appearance.colors.colOnLayer1" "$VOICE_PILL_REPO"; then
    pass "S2: Dynamic Material You palette binds colPrimary, colTertiary, colSecondary, colOnLayer1 (D-09)"
  else
    fail "S2: Incomplete Material You palette token bindings in VoicePill.qml"
  fi

  # Wrap-up timer interval
  if grep -q "interval: 1500" "$VOICE_PILL_REPO"; then
    pass "S2: Wrap-up timer configured with 1500ms interval (D-06)"
  else
    fail "S2: Missing or incorrect wrap-up timer interval (expected 1500ms)"
  fi

  # Absence of separate vertical equalizer wave bars (D-05)
  WAVE_MATCHES="$(grep -i -E "(equalizer|wavebar|wave_bar)" "$VOICE_PILL_REPO" || true)"
  if [[ -z "$WAVE_MATCHES" ]]; then
    pass "S2: Omission of separate equalizer wave bars verified (D-05)"
  else
    fail "S2: Unexpected equalizer wave bar references found: $WAVE_MATCHES"
  fi
fi

# ===========================================================================
# Section 3: Sequential Linear Flow & Badging (VOICE-04, VOICE-05, D-06, D-07)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Sequential Linear Flow & Badging (VOICE-04, VOICE-05, D-06, D-07) ---"

  if [[ "$SYNTAX_ONLY" -eq 0 ]]; then
    RT_S3="$(create_mock_voice_runtime)"
    TMP_DIRS+=("$RT_S3")

    bash -c 'exec -a voice sleep 30' &
    STT_PID_S3=$!
    MOCK_PIDS+=("$STT_PID_S3")

    bash -c 'exec -a voice-tts sleep 30' &
    TTS_PID_S3=$!
    MOCK_PIDS+=("$TTS_PID_S3")
    sleep 0.1

    QML_S3=$(cat << EOF
import QtQuick
import Quickshell
import "modules/ii/bar"
import "services"

Scope {
    id: testRoot

    VoicePill {
        id: pill
    }

    Timer {
        id: flowTimer
        interval: 100
        repeat: true
        property int step: 0
        onTriggered: {
            step++;
            Voice.poll();
            if (step === 1) {
                console.log("S3_IDLE text='" + pill.displayText + "' expanded=" + pill.isExpanded + " state=" + pill.effectiveState);
                Quickshell.execDetached(["bash", "-c", "echo '$STT_PID_S3 recording' > $RT_S3/voice-stt/recorder.pid"]);
            } else if (step === 3) {
                // Update duration
                Voice.formattedDuration = "0:05";
                console.log("S3_REC text='" + pill.displayText + "' expanded=" + pill.isExpanded + " state=" + pill.effectiveState);
                Quickshell.execDetached(["bash", "-c", "echo '$STT_PID_S3 transcribing' > $RT_S3/voice-stt/recorder.pid"]);
            } else if (step === 5) {
                console.log("S3_TRANS text='" + pill.displayText + "' expanded=" + pill.isExpanded + " state=" + pill.effectiveState);
                Quickshell.execDetached(["bash", "-c", "echo '$STT_PID_S3 typing' > $RT_S3/voice-stt/recorder.pid"]);
            } else if (step === 7) {
                console.log("S3_TYPE text='" + pill.displayText + "' expanded=" + pill.isExpanded + " state=" + pill.effectiveState);
                Quickshell.execDetached(["bash", "-c", "rm -f $RT_S3/voice-stt/recorder.pid"]);
            } else if (step === 19) {
                // After 1100ms, Voice.qml typing linger elapsed -> entered idle, triggering wrapUpTimer!
                console.log("S3_WRAPUP inWrapUp=" + pill.inWrapUp + " text='" + pill.displayText + "' expanded=" + pill.isExpanded + " state=" + pill.effectiveState);
                pill.wrapUpTimer.interval = 50;
                pill.wrapUpTimer.restart();
            } else if (step === 21) {
                console.log("S3_EXPIRED inWrapUp=" + pill.inWrapUp + " text='" + pill.displayText + "' expanded=" + pill.isExpanded + " state=" + pill.effectiveState);
                Quickshell.execDetached(["bash", "-c", "echo '$TTS_PID_S3 speaking' > $RT_S3/voice-stt/tts.pid"]);
            } else if (step === 23) {
                console.log("S3_SPEAK text='" + pill.displayText + "' expanded=" + pill.isExpanded + " state=" + pill.effectiveState);
                Quickshell.execDetached(["bash", "-c", "rm -f $RT_S3/voice-stt/tts.pid"]);
                Qt.quit();
            }
        }
    }

    Component.onCompleted: {
        flowTimer.start();
    }
}
EOF
)
    OUT_S3="$(run_qs_test "$QML_S3" "$RT_S3")"

    if echo "$OUT_S3" | grep -q "S3_IDLE text='' expanded=false state=idle"; then
      pass "S3: Idle state renders empty text label and collapsed width"
    else
      fail "S3: Idle state test failed: $OUT_S3"
    fi

    if echo "$OUT_S3" | grep -q "S3_REC text='0:05' expanded=true state=recording"; then
      pass "S3: Recording state displays formatted live duration '0:05' (VOICE-05)"
    else
      fail "S3: Recording state live timer test failed: $OUT_S3"
    fi

    if echo "$OUT_S3" | grep -q "S3_TRANS text='Transcribing...' expanded=true state=transcribing"; then
      pass "S3: Transcribing state displays localized 'Transcribing...' badge (VOICE-05)"
    else
      fail "S3: Transcribing badge test failed: $OUT_S3"
    fi

    if echo "$OUT_S3" | grep -q "S3_TYPE text='Typing...' expanded=true state=typing"; then
      pass "S3: Typing state displays localized 'Typing...' badge (VOICE-05)"
    else
      fail "S3: Typing badge test failed: $OUT_S3"
    fi

    if echo "$OUT_S3" | grep -q "S3_WRAPUP inWrapUp=true text='0:05' expanded=true state=wrapup"; then
      pass "S3: Wrap-up state lingers on cached final duration '0:05' despite service resetting to '0:00' (D-06)"
    else
      fail "S3: Wrap-up linger test failed: $OUT_S3"
    fi

    if echo "$OUT_S3" | grep -q "S3_EXPIRED inWrapUp=false text='' expanded=false state=idle"; then
      pass "S3: Expiration of wrap-up timer cleanly returns pill to compact idle state (D-06)"
    else
      fail "S3: Wrap-up expiration test failed: $OUT_S3"
    fi

    if echo "$OUT_S3" | grep -q "S3_SPEAK text='0:00' expanded=true state=speaking" || \
       echo "$OUT_S3" | grep -q "S3_SPEAK text='0:01' expanded=true state=speaking"; then
      pass "S3: TTS speaking state displays live formatted playback duration (D-07)"
    else
      fail "S3: TTS playback display test failed: $OUT_S3"
    fi
  else
    pass "S3: [SKIPPED in --syntax mode] Sequential linear flow headless tests"
  fi
fi

# ===========================================================================
# Section 4: M3 Emphasized Deceleration Width Resizing (VOICE-06, D-04)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: M3 Emphasized Deceleration Width Resizing (VOICE-06, D-04) ---"

  # Static check for width override driving BarGroup's native Behavior on implicitWidth
  if grep -q "implicitWidth: vertical ?" "$VOICE_PILL_REPO" && \
     grep -q "voiceIcon.implicitWidth + (isExpanded ?" "$VOICE_PILL_REPO"; then
    pass "S4: Root implicitWidth directly bound to content dimensions (bypasses Qt 6.11 GridLayout bug, D-04, VOICE-06)"
  else
    fail "S4: Root implicitWidth formula missing or incorrect in VoicePill.qml"
  fi

  if [[ "$SYNTAX_ONLY" -eq 0 ]]; then
    RT_S4="$(create_mock_voice_runtime)"
    TMP_DIRS+=("$RT_S4")

    bash -c 'exec -a voice sleep 30' &
    STT_PID_S4=$!
    MOCK_PIDS+=("$STT_PID_S4")
    sleep 0.1

    QML_S4=$(cat << EOF
import QtQuick
import Quickshell
import "modules/ii/bar"
import "services"

Scope {
    id: testRoot

    VoicePill {
        id: pill
    }

    Timer {
        id: widthTimer
        interval: 100
        repeat: true
        property int step: 0
        onTriggered: {
            step++;
            Voice.poll();
            if (step === 1) {
                console.log("S4_IDLE width=" + Math.round(pill.implicitWidth));
                Quickshell.execDetached(["bash", "-c", "echo '$STT_PID_S4 recording' > $RT_S4/voice-stt/recorder.pid"]);
            } else if (step === 4) {
                console.log("S4_REC width=" + Math.round(pill.implicitWidth));
                Quickshell.execDetached(["bash", "-c", "echo '$STT_PID_S4 transcribing' > $RT_S4/voice-stt/recorder.pid"]);
            } else if (step === 8) {
                console.log("S4_TRANS width=" + Math.round(pill.implicitWidth));
                Quickshell.execDetached(["bash", "-c", "rm -f $RT_S4/voice-stt/recorder.pid"]);
            } else if (step === 11) {
                pill.wrapUpTimer.interval = 10;
            } else if (step === 24) {
                console.log("S4_RETURN_IDLE width=" + Math.round(pill.implicitWidth));
                Qt.quit();
            }
        }
    }

    Component.onCompleted: {
        widthTimer.start();
    }
}
EOF
)
    OUT_S4="$(run_qs_test "$QML_S4" "$RT_S4")"

    if echo "$OUT_S4" | grep -q "S4_IDLE width=26"; then
      pass "S4: Idle resting pill implicitWidth is exactly 26px (16px icon + 10px padding)"
    else
      fail "S4: Idle implicitWidth failed: $OUT_S4"
    fi

    REC_W="$(echo "$OUT_S4" | grep -oE "S4_REC width=[0-9]+" | cut -d= -f2 || echo 0)"
    if [[ "$REC_W" -ge 60 && "$REC_W" -le 80 ]]; then
      pass "S4: Recording pill implicitWidth dynamically expands to $REC_W px (expected 60-80px)"
    else
      fail "S4: Recording implicitWidth out of bounds ($REC_W px): $OUT_S4"
    fi

    TRANS_W="$(echo "$OUT_S4" | grep -oE "S4_TRANS width=[0-9]+" | cut -d= -f2 || echo 0)"
    if [[ "$TRANS_W" -ge 100 && "$TRANS_W" -le 140 ]]; then
      pass "S4: Transcribing pill implicitWidth dynamically expands to $TRANS_W px (expected 100-140px)"
    else
      fail "S4: Transcribing implicitWidth out of bounds ($TRANS_W px): $OUT_S4"
    fi

    if echo "$OUT_S4" | grep -q "S4_RETURN_IDLE width=26"; then
      pass "S4: Pill implicitWidth contracts cleanly back to 26px upon returning to idle"
    else
      fail "S4: Return to idle implicitWidth failed: $OUT_S4"
    fi
  else
    pass "S4: [SKIPPED in --syntax mode] Width resizing headless tests"
  fi
fi

# ===========================================================================
# Section 5: Breathing Pulse Animation & Opacity Invariants (VOICE-03, D-08)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Breathing Pulse Animation & Opacity Invariants (VOICE-03, D-08) ---"

  # Static checks for animation declaration
  if grep -q "SequentialAnimation {" "$VOICE_PILL_REPO" && \
     grep -q 'running: root.effectiveState === "recording"' "$VOICE_PILL_REPO" && \
     grep -q "loops: Animation.Infinite" "$VOICE_PILL_REPO"; then
    pass "S5: SequentialAnimation declared running strictly during recording with infinite loops (VOICE-03, D-08)"
  else
    fail "S5: Pulse animation declaration or running condition missing/incorrect in VoicePill.qml"
  fi

  if grep -q "if (!running) voiceIcon.opacity = 1.0" "$VOICE_PILL_REPO"; then
    pass "S5: onRunningChanged resets voiceIcon.opacity unconditionally to 1.0 on stop (Pitfall 3)"
  else
    fail "S5: Missing onRunningChanged opacity reset guard in VoicePill.qml"
  fi

  if grep -q "to: 0.5" "$VOICE_PILL_REPO" && grep -q "to: 1.0" "$VOICE_PILL_REPO" && grep -q "duration: 500" "$VOICE_PILL_REPO"; then
    pass "S5: Breathing cycle oscillates between 1.0 and 0.5 over 1000ms period (500ms down + 500ms up)"
  else
    fail "S5: Pulse animation timing or opacity range incorrect (expected 500ms + 500ms, 1.0 <-> 0.5)"
  fi

  if [[ "$SYNTAX_ONLY" -eq 0 ]]; then
    RT_S5="$(create_mock_voice_runtime)"
    TMP_DIRS+=("$RT_S5")

    bash -c 'exec -a voice sleep 30' &
    STT_PID_S5=$!
    MOCK_PIDS+=("$STT_PID_S5")
    sleep 0.1

    QML_S5=$(cat << EOF
import QtQuick
import Quickshell
import "modules/ii/bar"
import "services"

Scope {
    id: testRoot

    VoicePill {
        id: pill
    }

    Timer {
        id: pulseTimer
        interval: 100
        repeat: true
        property int step: 0
        onTriggered: {
            step++;
            Voice.poll();
            if (step === 1) {
                console.log("S5_IDLE running=" + pill.pulseAnimation.running + " opacity=" + pill.voiceIcon.opacity);
                Quickshell.execDetached(["bash", "-c", "echo '$STT_PID_S5 recording' > $RT_S5/voice-stt/recorder.pid"]);
            } else if (step === 3) {
                console.log("S5_REC running=" + pill.pulseAnimation.running + " opacity=" + pill.voiceIcon.opacity);
                // Abruptly interrupt recording mid-cycle by changing state to transcribing
                Quickshell.execDetached(["bash", "-c", "echo '$STT_PID_S5 transcribing' > $RT_S5/voice-stt/recorder.pid"]);
            } else if (step === 5) {
                console.log("S5_TRANS running=" + pill.pulseAnimation.running + " opacity=" + pill.voiceIcon.opacity);
                Quickshell.execDetached(["bash", "-c", "rm -f $RT_S5/voice-stt/recorder.pid"]);
            } else if (step === 8) {
                console.log("S5_FINAL_IDLE running=" + pill.pulseAnimation.running + " opacity=" + pill.voiceIcon.opacity);
                Qt.quit();
            }
        }
    }

    Component.onCompleted: {
        pulseTimer.start();
    }
}
EOF
)
    OUT_S5="$(run_qs_test "$QML_S5" "$RT_S5")"

    if echo "$OUT_S5" | grep -q "S5_IDLE running=false opacity=1"; then
      pass "S5: In idle state, pulseAnimation is not running and opacity is 1.0"
    else
      fail "S5: Idle state pulse animation test failed: $OUT_S5"
    fi

    if echo "$OUT_S5" | grep -q "S5_REC running=true"; then
      pass "S5: In recording state, pulseAnimation is active and running"
    else
      fail "S5: Recording state pulse activation failed: $OUT_S5"
    fi

    if echo "$OUT_S5" | grep -q "S5_TRANS running=false opacity=1"; then
      pass "S5: Abrupt transition to transcribing stops pulse and immediately resets opacity to 1.0 (VOICE-03)"
    else
      fail "S5: Transcribing opacity reset failed: $OUT_S5"
    fi

    if echo "$OUT_S5" | grep -q "S5_FINAL_IDLE running=false opacity=1"; then
      pass "S5: Idle state preserves restored 1.0 opacity"
    else
      fail "S5: Final idle opacity check failed: $OUT_S5"
    fi
  else
    pass "S5: [SKIPPED in --syntax mode] Pulse animation headless tests"
  fi
fi

# ===========================================================================
# Section 6: Git Working-Tree Invariance & Strict Verification Gate
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 6 ]]; then
  info "--- Section 6: Git Working-Tree Invariance & Strict Verification Gate ---"

  # Check working-tree invariance
  porcelain_snapshot > "$PORCELAIN_AFTER"
  if diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" >/dev/null; then
    pass "S6: Git working tree invariant before vs after test harness run"
  else
    fail "S6: Git working tree churn detected during test run:"
    diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
  fi

  # Strict repository verification gate
  if [[ "$SYNTAX_ONLY" -eq 0 ]]; then
    info "Executing ./arch/dots-hyprland.sh verify --strict..."
    VERIFY_OUT="$(./arch/dots-hyprland.sh verify --strict 2>&1 || true)"
    if echo "$VERIFY_OUT" | grep -q "=== done: FAIL=0 FINDINGS=0 ==="; then
      pass "S6: arch/dots-hyprland.sh verify --strict passed with FAIL=0 FINDINGS=0"
    else
      fail "S6: arch/dots-hyprland.sh verify --strict reported failures or findings:"
      printf '%s\n' "$VERIFY_OUT" | grep -E "(\[FAIL\]|\[FINDING\])" || true
    fi
  else
    pass "S6: [SKIPPED in --syntax mode] Strict repository verification gate"
  fi
fi

# ===========================================================================
# Summary & Exit Code
# ===========================================================================
echo ""
echo "=== Phase 36 Voice Pill Assert Summary: FAIL=$FAIL FINDINGS=$FINDINGS ==="

if [[ "$FAIL" -eq 0 && "$FINDINGS" -eq 0 ]]; then
  exit 0
else
  exit 1
fi
