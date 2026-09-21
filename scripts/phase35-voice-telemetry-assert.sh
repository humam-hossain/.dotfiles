#!/usr/bin/env bash
# ===========================================================================
# Phase 35: Voice Telemetry & State Service Architecture Assert Harness
# Enforces: TELEM-01, TELEM-02, TELEM-03, TELEM-04, TELEM-05, D-01 through D-11
#
# Usage (from REPO_ROOT):
#   ./scripts/phase35-voice-telemetry-assert.sh [--section <1-6>] [-s <1-6>]
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
  # Kill any spawned mock background processes
  for pid in ${MOCK_PIDS[@]+"${MOCK_PIDS[@]}"}; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" 2>/dev/null || true
    fi
  done

  # Remove temporary files
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true

  # Remove temporary directories
  for dir in ${TMP_DIRS[@]+"${TMP_DIRS[@]}"}; do
    [[ -n "$dir" && -d "$dir" ]] && rm -rf "$dir" 2>/dev/null || true
  done

  return 0
}
trap cleanup EXIT

RUN_SECTION=0

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
    -h|--help)
      echo "Usage: $0 [--section <1-6>]"
      echo "  -s, --section <1-6>  Execute only the specified section"
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

PORCELAIN_BEFORE="$(mktemp /tmp/p35-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p35-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# Helper to run a headless Quickshell QML snippet inside ~/.config/quickshell/ii/
run_qs_test() {
  local qml_content="$1"
  local runtime_dir="${2:-}"
  local timeout_sec="${3:-1.8}"

  local runner_file
  runner_file="$(mktemp "${XDG_CONFIG_HOME}/quickshell/ii/p35_runner_XXXXXX.qml")"
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

# ===========================================================================
# Section 1: Foundation, Deployment & Configuration (TELEM-01, D-01, D-03)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Foundation, Deployment & Configuration (TELEM-01, D-01, D-03) ---"

  VOICE_REPO="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/Voice.qml"
  VOICE_LIVE="$XDG_CONFIG_HOME/quickshell/ii/services/Voice.qml"

  if [[ -f "$VOICE_REPO" ]]; then
    pass "S1: Voice.qml exists in restow tree: $VOICE_REPO"
  else
    fail "S1: Voice.qml missing from restow tree: $VOICE_REPO"
  fi

  if [[ -L "$VOICE_LIVE" ]]; then
    target="$(readlink "$VOICE_LIVE")"
    if [[ "$target" == *"restow/quickshell/.config/quickshell/ii/services/Voice.qml"* ]]; then
      pass "S1: Voice.qml is deployed as live symlink into restow: $target"
    else
      fail "S1: Voice.qml symlink points elsewhere: $target"
    fi
  else
    fail "S1: Voice.qml is not a live symlink: $VOICE_LIVE"
  fi

  # Check pragmas
  if grep -q "^pragma Singleton" "$VOICE_REPO" && grep -q "^pragma ComponentBehavior: Bound" "$VOICE_REPO"; then
    pass "S1: Voice.qml declares pragma Singleton and pragma ComponentBehavior: Bound"
  else
    fail "S1: Voice.qml missing required pragmas"
  fi

  # Check FileView error suppression and block loading (D-03)
  fv_count="$(grep -c "FileView" "$VOICE_REPO" || true)"
  pe_count="$(grep -c "printErrors: false" "$VOICE_REPO" || true)"
  bl_count="$(grep -c "blockLoading: true" "$VOICE_REPO" || true)"
  if [[ "$fv_count" -gt 0 && "$fv_count" -le "$pe_count" && "$fv_count" -le "$bl_count" ]]; then
    pass "S1: All $fv_count FileView instances configure printErrors: false and blockLoading: true (D-03)"
  else
    fail "S1: FileView count mismatch ($fv_count FileViews vs $pe_count printErrors:false vs $bl_count blockLoading:true)"
  fi

  # Check adaptive polling timer interval (D-01)
  if grep -q "overallState === \"idle\"" "$VOICE_REPO" && grep -q "500 : 100" "$VOICE_REPO"; then
    pass "S1: Adaptive polling timer shifts between 500ms (idle) and 100ms (active) (D-01)"
  else
    fail "S1: Adaptive polling timer interval definition missing or incorrect in Voice.qml"
  fi
fi

# ===========================================================================
# Section 2: Speech Lifecycle State Detection & Precedence (TELEM-02, D-04, D-05, D-06)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Speech Lifecycle State Detection & Precedence (TELEM-02, D-04..06) ---"

  RT_S2="$(mktemp -d /tmp/p35-s2-rt-XXXXXX)"
  TMP_DIRS+=("$RT_S2")
  mkdir -p "$RT_S2/voice-stt"

  # Start mock processes
  bash -c 'exec -a voice sleep 30' &
  MOCK_STT=$!
  MOCK_PIDS+=("$MOCK_STT")

  bash -c 'exec -a voice-tts sleep 30' &
  MOCK_TTS=$!
  MOCK_PIDS+=("$MOCK_TTS")
  sleep 0.1

  # Test discrete states and precedence in a single test runner
  QML_S2=$(cat << 'EOF'
import QtQuick
import Quickshell
import "services"

Scope {
    id: testRoot

    Component.onCompleted: {
        // 1. Idle state
        Voice.poll();
        console.log("STATE_IDLE overall=" + Voice.overallState + " stt=" + Voice.sttState + " tts=" + Voice.ttsState);

        // Precedence function test directly against overallState evaluation logic
        // Priority order: recording > transcribing > speaking > typing > starting > idle
        Voice.sttState = "recording"; Voice.ttsState = "speaking";
        console.log("PREC_REC_SPK overall=" + Voice.overallState);

        Voice.sttState = "transcribing"; Voice.ttsState = "speaking";
        console.log("PREC_TRANS_SPK overall=" + Voice.overallState);

        Voice.sttState = "typing"; Voice.ttsState = "speaking";
        console.log("PREC_TYP_SPK overall=" + Voice.overallState);

        Voice.sttState = "starting"; Voice.ttsState = "speaking";
        console.log("PREC_START_SPK overall=" + Voice.overallState);

        Voice.sttState = "starting"; Voice.ttsState = "idle";
        console.log("PREC_START_IDLE overall=" + Voice.overallState);

        // Reset
        Voice.sttState = "idle"; Voice.ttsState = "idle";
        Qt.quit();
    }
}
EOF
)

  OUT_S2="$(run_qs_test "$QML_S2" "$RT_S2")"

  if echo "$OUT_S2" | grep -q "STATE_IDLE overall=idle stt=idle tts=idle"; then
    pass "S2: Discrete state 'idle' correctly detected when no state files exist"
  else
    fail "S2: Idle state evaluation failed: $OUT_S2"
  fi

  if echo "$OUT_S2" | grep -q "PREC_REC_SPK overall=recording" && \
     echo "$OUT_S2" | grep -q "PREC_TRANS_SPK overall=transcribing" && \
     echo "$OUT_S2" | grep -q "PREC_TYP_SPK overall=speaking" && \
     echo "$OUT_S2" | grep -q "PREC_START_SPK overall=speaking" && \
     echo "$OUT_S2" | grep -q "PREC_START_IDLE overall=starting"; then
    pass "S2: Priority hierarchy strictly enforced: recording > transcribing > speaking > typing > starting > idle (D-04)"
  else
    fail "S2: Precedence hierarchy evaluation failed: $OUT_S2"
  fi

  # Test live PID file detection for starting, recording, transcribing
  for st in starting recording transcribing; do
    echo "$MOCK_STT $st" > "$RT_S2/voice-stt/recorder.pid"
    QML_ST=$(cat << EOF
import QtQuick
import Quickshell
import "services"

Scope {
    Component.onCompleted: {
        Voice.poll();
        console.log("DETECTED_ST stt=" + Voice.sttState + " overall=" + Voice.overallState);
        Qt.quit();
    }
}
EOF
)
    OUT_ST="$(run_qs_test "$QML_ST" "$RT_S2")"
    if echo "$OUT_ST" | grep -q "DETECTED_ST stt=$st overall=$st"; then
      pass "S2: Active STT state '$st' successfully detected from recorder.pid"
    else
      fail "S2: Failed to detect STT state '$st': $OUT_ST"
    fi
  done

  # Test typing linger timer (D-06): holding typing state for 1000ms after transcribing
  echo "$MOCK_STT transcribing" > "$RT_S2/voice-stt/recorder.pid"
  QML_LINGER=$(cat << 'EOF'
import QtQuick
import Quickshell
import "services"

Scope {
    id: lingerRoot
    property int tick: 0

    Timer {
        interval: 200
        repeat: true
        running: true
        onTriggered: {
            lingerRoot.tick++;
            if (lingerRoot.tick === 1) {
                // Poll initially to read transcribing
                Voice.poll();
                // Then remove recorder.pid to simulate daemon finishing transcription
                // and poll again to trigger transcribing -> typing transition
                Quickshell.execDetached(["rm", "-f", Voice.recorderPidPath]);
            } else if (lingerRoot.tick === 2) {
                Voice.poll();
                console.log("LINGER_T1 overall=" + Voice.overallState + " stt=" + Voice.sttState);
            } else if (lingerRoot.tick === 4) {
                // At ~800ms, should still be typing
                console.log("LINGER_T2 overall=" + Voice.overallState + " stt=" + Voice.sttState);
            } else if (lingerRoot.tick === 8) {
                // At ~1600ms, typingLingerTimer has expired -> should return to idle
                console.log("LINGER_T3 overall=" + Voice.overallState + " stt=" + Voice.sttState);
                Qt.quit();
            }
        }
    }
}
EOF
)
  OUT_LINGER="$(run_qs_test "$QML_LINGER" "$RT_S2" 2.5)"
  if echo "$OUT_LINGER" | grep -q "LINGER_T1 overall=typing stt=typing" && \
     echo "$OUT_LINGER" | grep -q "LINGER_T2 overall=typing stt=typing" && \
     echo "$OUT_LINGER" | grep -q "LINGER_T3 overall=idle stt=idle"; then
    pass "S2: typingLingerTimer holds typing state for 1000ms window before returning to idle (D-06)"
  else
    fail "S2: typingLingerTimer window assertion failed: $OUT_LINGER"
  fi
fi

# ===========================================================================
# Section 3: Process Liveness Verification & Stale Lock Purge (TELEM-03, D-10, D-11)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Process Liveness Verification & Stale Lock Purge (TELEM-03, D-10, D-11) ---"

  RT_S3="$(mktemp -d /tmp/p35-s3-rt-XXXXXX)"
  TMP_DIRS+=("$RT_S3")
  mkdir -p "$RT_S3/voice-stt"

  # Scenario A: Dead PID (999999)
  echo "999999 recording" > "$RT_S3/voice-stt/recorder.pid"
  QML_DEAD=$(cat << 'EOF'
import QtQuick
import Quickshell
import "services"

Scope {
    Timer {
        interval: 150
        running: true
        repeat: false
        onTriggered: {
            console.log("PURGE_A overall=" + Voice.overallState);
            Qt.quit();
        }
    }
}
EOF
)
  OUT_DEAD="$(run_qs_test "$QML_DEAD" "$RT_S3")"
  sleep 0.15
  if [[ ! -f "$RT_S3/voice-stt/recorder.pid" ]] && echo "$OUT_DEAD" | grep -q "Purged stale PID lock: 999999" && echo "$OUT_DEAD" | grep -q "PURGE_A overall=idle"; then
    pass "S3 Scenario A: Non-existent PID 999999 lock was purged from disk and logged warning (D-10, D-11)"
  else
    fail "S3 Scenario A: Dead PID purge failed (file exists: $(test -f "$RT_S3/voice-stt/recorder.pid" && echo yes || echo no)): $OUT_DEAD"
  fi

  # Scenario B: Recycled non-voice PID (PID 1 / systemd)
  echo "1 recording" > "$RT_S3/voice-stt/recorder.pid"
  OUT_RECYCLED="$(run_qs_test "$QML_DEAD" "$RT_S3")"
  sleep 0.15
  if [[ ! -f "$RT_S3/voice-stt/recorder.pid" ]] && echo "$OUT_RECYCLED" | grep -q "Purged stale PID lock: 1"; then
    pass "S3 Scenario B: Recycled non-voice PID 1 lock was purged from disk (T-35-02)"
  else
    fail "S3 Scenario B: Recycled PID purge failed: $OUT_RECYCLED"
  fi

  # Scenario C: Healthy PID with "voice" in cmdline
  bash -c 'exec -a voice sleep 30' &
  HEALTHY_PID=$!
  MOCK_PIDS+=("$HEALTHY_PID")
  sleep 0.1

  echo "$HEALTHY_PID recording" > "$RT_S3/voice-stt/recorder.pid"
  QML_HEALTHY=$(cat << 'EOF'
import QtQuick
import Quickshell
import "services"

Scope {
    Timer {
        interval: 150
        running: true
        repeat: false
        onTriggered: {
            console.log("HEALTHY_C overall=" + Voice.overallState + " sttPid=" + Voice.sttPid);
            Qt.quit();
        }
    }
}
EOF
)
  OUT_HEALTHY="$(run_qs_test "$QML_HEALTHY" "$RT_S3")"
  if [[ -f "$RT_S3/voice-stt/recorder.pid" ]] && echo "$OUT_HEALTHY" | grep -q "HEALTHY_C overall=recording sttPid=$HEALTHY_PID"; then
    pass "S3 Scenario C: Healthy voice PID $HEALTHY_PID was verified alive and lock preserved"
  else
    fail "S3 Scenario C: Healthy process verification failed: $OUT_HEALTHY"
  fi
fi

# ===========================================================================
# Section 4: Live Duration Counter & Reload Recovery (TELEM-04, D-07, D-08, D-09)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Live Duration Counter & Reload Recovery (TELEM-04, D-07..09) ---"

  RT_S4="$(mktemp -d /tmp/p35-s4-rt-XXXXXX)"
  TMP_DIRS+=("$RT_S4")
  mkdir -p "$RT_S4/voice-stt"

  bash -c 'exec -a voice sleep 30' &
  DUR_PID=$!
  MOCK_PIDS+=("$DUR_PID")
  sleep 0.2

  echo "$DUR_PID recording" > "$RT_S4/voice-stt/recorder.pid"

  QML_DUR=$(cat << 'EOF'
import QtQuick
import Quickshell
import "services"

Scope {
    id: durRoot
    property int tick: 0
    property string frozenDuration: ""

    Timer {
        interval: 200
        repeat: true
        running: true
        onTriggered: {
            durRoot.tick++;
            if (durRoot.tick === 1) {
                Voice.poll();
                console.log("DUR_FORMAT_CHECK formatDuration=" + Voice.formatDuration(65) + " formatDuration0=" + Voice.formatDuration(0));
                console.log("DUR_MAX maxDurationSeconds=" + Voice.maxDurationSeconds);
            } else if (durRoot.tick === 3) {
                Voice.poll();
                console.log("DUR_LIVE elapsedSec=" + Voice.elapsedSeconds + " formatted=" + Voice.formattedDuration + " elapsedMs=" + (Voice.elapsedMs > 0 ? "gt0" : "0"));
                // Switch to transcribing by writing transcribing to recorder.pid (D-08)
                Quickshell.execDetached(["bash", "-c", "echo " + Voice.sttPid + " transcribing > " + Voice.recorderPidPath]);
            } else if (durRoot.tick === 5) {
                Voice.poll();
                durRoot.frozenDuration = Voice.formattedDuration;
            } else if (durRoot.tick === 7) {
                Voice.poll();
                console.log("DUR_FROZEN frozen=" + (Voice.formattedDuration === durRoot.frozenDuration ? "yes" : "no"));
                // Remove file and reset duration to test idle reset (D-08)
                Quickshell.execDetached(["rm", "-f", Voice.recorderPidPath]);
                Voice.sttState = "idle";
                Voice.resetDuration();
                console.log("DUR_RESET elapsedSec=" + Voice.elapsedSeconds + " formatted=" + Voice.formattedDuration);
                Qt.quit();
            }
        }
    }
}
EOF
)
  OUT_DUR="$(run_qs_test "$QML_DUR" "$RT_S4" 2.8)"

  if echo "$OUT_DUR" | grep -q "DUR_FORMAT_CHECK formatDuration=1:05 formatDuration0=0:00"; then
    pass "S4: formatDuration formats seconds as M:SS (e.g. 65s -> 1:05)"
  else
    fail "S4: formatDuration check failed: $OUT_DUR"
  fi

  if echo "$OUT_DUR" | grep -q "DUR_MAX maxDurationSeconds=300"; then
    pass "S4: maxDurationSeconds property is exposed as 300s (D-09)"
  else
    fail "S4: maxDurationSeconds check failed: $OUT_DUR"
  fi

  if echo "$OUT_DUR" | grep -q "DUR_LIVE " && echo "$OUT_DUR" | grep -q "elapsedMs=gt0"; then
    pass "S4: Live elapsed duration tracking updates elapsedSeconds and elapsedMs in real-time (TELEM-04)"
  else
    fail "S4: Live duration tracking check failed: $OUT_DUR"
  fi

  if echo "$OUT_DUR" | grep -q "DUR_FROZEN frozen=yes"; then
    pass "S4: Duration freezes at final recording length during transcribing (D-08)"
  else
    fail "S4: Duration freeze check failed: $OUT_DUR"
  fi

  if echo "$OUT_DUR" | grep -q "DUR_RESET elapsedSec=0 formatted=0:00"; then
    pass "S4: Duration resets to 0 / 0:00 when returning to idle (D-08)"
  else
    fail "S4: Duration reset check failed: $OUT_DUR"
  fi

  # Reload recovery anchor test (D-07)
  QML_RECOVERY=$(cat << EOF
import QtQuick
import Quickshell
import "services"

Scope {
    Component.onCompleted: {
        const recoveredStart = Voice.recoverStartTime($DUR_PID);
        const diff = Date.now() - recoveredStart;
        console.log("DUR_RELOAD diff_ms=" + diff + " valid=" + (diff >= 0 && diff < 30000 ? "yes" : "no"));
        Qt.quit();
    }
}
EOF
)
  OUT_RECOVERY="$(run_qs_test "$QML_RECOVERY" "$RT_S4")"
  if echo "$OUT_RECOVERY" | grep -q "DUR_RELOAD .*valid=yes"; then
    pass "S4: recoverStartTime anchors process launch time across Quickshell reload using procfs (D-07)"
  else
    fail "S4: recoverStartTime reload anchor failed: $OUT_RECOVERY"
  fi
fi

# ===========================================================================
# Section 5: TTS Voice & Backend Metadata Extraction (TELEM-05, D-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: TTS Voice & Backend Metadata Extraction (TELEM-05, D-02) ---"

  RT_S5="$(mktemp -d /tmp/p35-s5-rt-XXXXXX)"
  TMP_DIRS+=("$RT_S5")
  mkdir -p "$RT_S5/voice-stt"

  # Case 1: Active TTS process with explicit --tts-voice af_bella and --tts-backend kokoro
  bash -c 'exec -a voice-tts python3 -c "import time; time.sleep(30)" --tts-voice af_bella --tts-backend kokoro' &
  TTS_PID_1=$!
  MOCK_PIDS+=("$TTS_PID_1")
  sleep 0.1

  echo "$TTS_PID_1 speaking" > "$RT_S5/voice-stt/tts.pid"

  QML_TTS_1=$(cat << 'EOF'
import QtQuick
import Quickshell
import "services"

Scope {
    Component.onCompleted: {
        Voice.poll();
        console.log("TTS_CASE1 voice=" + Voice.ttsVoice + " backend=" + Voice.ttsBackend + " state=" + Voice.ttsState);
        Qt.quit();
    }
}
EOF
)
  OUT_TTS_1="$(run_qs_test "$QML_TTS_1" "$RT_S5")"

  if echo "$OUT_TTS_1" | grep -q "TTS_CASE1 voice=af_bella backend=kokoro state=speaking"; then
    pass "S5 Case 1: Successfully extracted --tts-voice af_bella and --tts-backend kokoro from cmdline (TELEM-05)"
  else
    fail "S5 Case 1: TTS metadata extraction failed: $OUT_TTS_1"
  fi

  # Case 2: Process without voice arguments -> verify default fallback to af_heart / kokoro
  bash -c 'exec -a voice-tts python3 -c "import time; time.sleep(30)"' &
  TTS_PID_2=$!
  MOCK_PIDS+=("$TTS_PID_2")
  sleep 0.1

  echo "$TTS_PID_2 speaking" > "$RT_S5/voice-stt/tts.pid"

  QML_TTS_2=$(cat << 'EOF'
import QtQuick
import Quickshell
import "services"

Scope {
    Component.onCompleted: {
        Voice.poll();
        console.log("TTS_CASE2 voice=" + Voice.ttsVoice + " backend=" + Voice.ttsBackend + " state=" + Voice.ttsState);
        Qt.quit();
    }
}
EOF
)
  OUT_TTS_2="$(run_qs_test "$QML_TTS_2" "$RT_S5")"

  if echo "$OUT_TTS_2" | grep -q "TTS_CASE2 voice=af_heart backend=kokoro state=speaking"; then
    pass "S5 Case 2: Successfully fell back to default voice af_heart and backend kokoro (D-02)"
  else
    fail "S5 Case 2: TTS default fallback failed: $OUT_TTS_2"
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
  info "Executing ./arch/dots-hyprland.sh verify --strict..."
  VERIFY_OUT="$(./arch/dots-hyprland.sh verify --strict 2>&1 || true)"
  if echo "$VERIFY_OUT" | grep -q "=== done: FAIL=0 FINDINGS=0 ==="; then
    pass "S6: arch/dots-hyprland.sh verify --strict passed with FAIL=0 FINDINGS=0"
  else
    fail "S6: arch/dots-hyprland.sh verify --strict reported failures or findings:"
    printf '%s\n' "$VERIFY_OUT" | grep -E "(\[FAIL\]|\[FINDING\])" || true
  fi
fi

# ===========================================================================
# Summary & Exit Code
# ===========================================================================
echo ""
echo "=== Phase 35 Telemetry Assert Summary: FAIL=$FAIL FINDINGS=$FINDINGS ==="

if [[ "$FAIL" -eq 0 && "$FINDINGS" -eq 0 ]]; then
  exit 0
else
  exit 1
fi
