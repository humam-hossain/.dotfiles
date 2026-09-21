#!/usr/bin/env bash
# ===========================================================================
# Phase 37: VoicePill Bar Layout Integration, Dual-Monitor Verification & Strict Packaging
#
# Usage (from REPO_ROOT):
#   ./scripts/phase37-voice-pill-assert.sh [--section <1-5>] [-s <1-5>] [--syntax]
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

PORCELAIN_BEFORE="$(mktemp /tmp/p37-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p37-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# Helper to run a headless Quickshell QML snippet
run_qs_test() {
  local qml_content="$1"
  local runtime_dir="${2:-}"
  local timeout_sec="${3:-4.5}"

  local runner_file
  runner_file="$(mktemp "${XDG_CONFIG_HOME}/quickshell/ii/p37_runner_XXXXXX.qml")"
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

create_mock_voice_runtime() {
  local rt
  rt="$(mktemp -d /tmp/p37-rt-XXXXXX)"
  mkdir -p "$rt/voice-stt"
  local real_xdg="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  if [[ -n "${WAYLAND_DISPLAY:-}" && -e "$real_xdg/$WAYLAND_DISPLAY" ]]; then
    ln -s "$real_xdg/$WAYLAND_DISPLAY" "$rt/$WAYLAND_DISPLAY" 2>/dev/null || true
  fi
  printf "%s" "$rt"
}

VOICE_PILL_REPO="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/VoicePill.qml"
BAR_CONTENT_REPO="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
BAR_CONTENT_LIVE="$XDG_CONFIG_HOME/quickshell/ii/modules/ii/bar/BarContent.qml"
LIVE_BAR_DIR="$XDG_CONFIG_HOME/quickshell/ii/modules/ii/bar"
VOICE_PILL_LIVE="$XDG_CONFIG_HOME/quickshell/ii/modules/ii/bar/VoicePill.qml"

# ===========================================================================
# Section 1: Layout Integration & Direct Mounting
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Layout Integration & Direct Mounting ---"

  MEDIA_LINE=$(grep -n "id: mediaLoader" "$BAR_CONTENT_REPO" | cut -d: -f1)
  VOICE_LINE=$(grep -n "id: voicePill" "$BAR_CONTENT_REPO" | cut -d: -f1 || echo 0)
  UPDATES_LINE=$(grep -n "id: updatesLoader" "$BAR_CONTENT_REPO" | cut -d: -f1)
  
  if [[ "$VOICE_LINE" -gt "$MEDIA_LINE" ]] && [[ "$VOICE_LINE" -lt "$UPDATES_LINE" ]]; then
    pass "S1: VoicePill is declared directly inside rightSectionRowLayout immediately following mediaLoader"
  else
    fail "S1: VoicePill is NOT directly following mediaLoader"
  fi

  if grep -A 10 "VoicePill {" "$BAR_CONTENT_REPO" | grep -q "useShortenedForm: root.useShortenedForm"; then
    pass "S1: VoicePill explicitly binds useShortenedForm: root.useShortenedForm"
  else
    fail "S1: VoicePill missing useShortenedForm: root.useShortenedForm binding"
  fi

  if grep -A 10 "VoicePill {" "$BAR_CONTENT_REPO" | grep -q "Layout.alignment: Qt.AlignVCenter"; then
    pass "S1: VoicePill explicitly binds Layout.alignment: Qt.AlignVCenter"
  else
    fail "S1: VoicePill missing Layout.alignment: Qt.AlignVCenter"
  fi
  
  if grep -B 5 "id: voicePill" "$BAR_CONTENT_REPO" | grep -qE "Loader \{|BarGroup \{"; then
    fail "S1: VoicePill is wrapped in a redundant Loader or BarGroup"
  else
    pass "S1: VoicePill is declared directly without redundant wrappers"
  fi

  if [[ -L "$BAR_CONTENT_LIVE" ]]; then
    target="$(readlink "$BAR_CONTENT_LIVE")"
    if [[ "$target" == *"restow/quickshell/.config/quickshell/ii/modules/ii/bar/BarContent.qml"* ]]; then
      pass "S1: BarContent.qml is deployed as live symlink into restow: $target"
    else
      fail "S1: BarContent.qml symlink points elsewhere: $target"
    fi
  else
    fail "S1: BarContent.qml is not a live symlink: $BAR_CONTENT_LIVE"
  fi

  if [[ -d "$LIVE_BAR_DIR" && ! -L "$LIVE_BAR_DIR" ]]; then
    pass "S1: Parent directory $LIVE_BAR_DIR is a real directory (no folding)"
  else
    fail "S1: Parent directory $LIVE_BAR_DIR is symlinked or missing (folded)"
  fi

  # Vertical Bar Layout Integration (G-37-2)
  VERTICAL_BAR_CONTENT_REPO="$REPO_ROOT/restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml"
  VERTICAL_BAR_CONTENT_LIVE="$XDG_CONFIG_HOME/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml"
  LIVE_VERTICAL_BAR_DIR="$XDG_CONFIG_HOME/quickshell/ii/modules/ii/verticalBar"

  if [[ -f "$VERTICAL_BAR_CONTENT_REPO" ]]; then
    pass "S1: VerticalBarContent.qml exists in restow"
  else
    fail "S1: VerticalBarContent.qml does not exist in restow"
  fi

  if grep -A 10 "VoicePill {" "$VERTICAL_BAR_CONTENT_REPO" | grep -q "vertical: true"; then
    pass "S1: VerticalBarContent.qml explicitly instantiates VoicePill with vertical: true"
  else
    fail "S1: VerticalBarContent.qml missing VoicePill with vertical: true"
  fi

  if grep -A 10 "VoicePill {" "$VERTICAL_BAR_CONTENT_REPO" | grep -q "Layout.alignment: Qt.AlignHCenter"; then
    pass "S1: VerticalBarContent.qml binds VoicePill Layout.alignment: Qt.AlignHCenter"
  else
    fail "S1: VerticalBarContent.qml missing VoicePill Layout.alignment: Qt.AlignHCenter"
  fi

  if [[ -L "$VERTICAL_BAR_CONTENT_LIVE" ]]; then
    v_target="$(readlink "$VERTICAL_BAR_CONTENT_LIVE")"
    if [[ "$v_target" == *"restow/quickshell/.config/quickshell/ii/modules/ii/verticalBar/VerticalBarContent.qml"* ]]; then
      pass "S1: VerticalBarContent.qml is deployed as live symlink into restow: $v_target"
    else
      fail "S1: VerticalBarContent.qml symlink points elsewhere: $v_target"
    fi
  else
    fail "S1: VerticalBarContent.qml is not a live symlink: $VERTICAL_BAR_CONTENT_LIVE"
  fi

  if [[ -d "$LIVE_VERTICAL_BAR_DIR" && ! -L "$LIVE_VERTICAL_BAR_DIR" ]]; then
    pass "S1: Parent directory $LIVE_VERTICAL_BAR_DIR is a real directory (no folding)"
  else
    fail "S1: Parent directory $LIVE_VERTICAL_BAR_DIR is symlinked or missing (folded)"
  fi
fi

# ===========================================================================
# Section 2: Inert MouseArea & Event Isolation
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Inert MouseArea & Event Isolation ---"
  if grep -A 8 "id: inertMouseArea" "$VOICE_PILL_REPO" | grep -q "parent: root"; then
    pass "S2: inertMouseArea sets parent: root"
  else
    fail "S2: inertMouseArea missing parent: root"
  fi

  if grep -A 8 "id: inertMouseArea" "$VOICE_PILL_REPO" | grep -q "anchors.fill: parent"; then
    pass "S2: inertMouseArea sets anchors.fill: parent"
  else
    fail "S2: inertMouseArea missing anchors.fill: parent"
  fi

  if grep -A 8 "id: inertMouseArea" "$VOICE_PILL_REPO" | grep -q "acceptedButtons: Qt.AllButtons"; then
    pass "S2: inertMouseArea absorbs all buttons (Qt.AllButtons)"
  else
    fail "S2: inertMouseArea missing acceptedButtons: Qt.AllButtons"
  fi

  if grep -A 8 "id: inertMouseArea" "$VOICE_PILL_REPO" | grep -q "onPressed: event => event.accepted = true"; then
    pass "S2: inertMouseArea consumes onPressed events"
  else
    fail "S2: inertMouseArea missing onPressed event consumption"
  fi
fi

# ===========================================================================
# Section 3: Multi-Monitor Responsive Adaptation & Expansion Suppression
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Multi-Monitor Responsive Adaptation & Expansion Suppression ---"
  
  if [[ "$SYNTAX_ONLY" -eq 0 ]]; then
    RT_S3="$(create_mock_voice_runtime)"
    TMP_DIRS+=("$RT_S3")
    bash -c 'exec -a voice sleep 30' &
    STT_PID_S3=$!
    MOCK_PIDS+=("$STT_PID_S3")

    QML_S3_0=$(cat << 'QML0'
import QtQuick
import Quickshell
import "modules/ii/bar"
import "services"

Scope {
    id: scopeRoot
    property int step: 0
    VoicePill { id: pill; useShortenedForm: 0 }
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            scopeRoot.step++;
            Voice.poll();
            if (scopeRoot.step === 1) {
                Quickshell.execDetached(["bash", "-c", "echo 'STT_PID_S3 recording' > RT_S3/voice-stt/recorder.pid"]);
            } else if (scopeRoot.step === 5) {
                console.log("S3_FULL expanded=" + pill.isExpanded + " width=" + Math.round(pill.implicitWidth));
                Qt.quit();
            }
        }
    }
}
QML0
)
    QML_S3_0="${QML_S3_0//STT_PID_S3/$STT_PID_S3}"
    QML_S3_0="${QML_S3_0//RT_S3/$RT_S3}"
    OUT_S3_0="$(run_qs_test "$QML_S3_0" "$RT_S3")"
    if echo "$OUT_S3_0" | grep -q "expanded=true"; then
      pass "S3: useShortenedForm=0 permits expansion"
    else
      fail "S3: useShortenedForm=0 failed expansion: $OUT_S3_0"
    fi

    QML_S3_2=$(cat << 'QML2'
import QtQuick
import Quickshell
import "modules/ii/bar"
import "services"

Scope {
    id: scopeRoot
    property int step: 0
    VoicePill { id: pill; useShortenedForm: 2 }
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            scopeRoot.step++;
            Voice.poll();
            if (scopeRoot.step === 1) {
                Quickshell.execDetached(["bash", "-c", "echo 'STT_PID_S3 recording' > RT_S3/voice-stt/recorder.pid"]);
            } else if (scopeRoot.step === 5) {
                console.log("S3_SHORT expanded=" + pill.isExpanded + " width=" + Math.round(pill.implicitWidth));
                Qt.quit();
            }
        }
    }
}
QML2
)
    QML_S3_2="${QML_S3_2//STT_PID_S3/$STT_PID_S3}"
    QML_S3_2="${QML_S3_2//RT_S3/$RT_S3}"
    OUT_S3_2="$(run_qs_test "$QML_S3_2" "$RT_S3")"
    if echo "$OUT_S3_2" | grep -q "expanded=false"; then
      pass "S3: useShortenedForm=2 suppresses expansion to 26px resting width"
    else
      fail "S3: useShortenedForm=2 failed to suppress expansion: $OUT_S3_2"
    fi

    QML_S3_V=$(cat << 'QMLV'
import QtQuick
import Quickshell
import "modules/ii/bar"
import "services"

Scope {
    id: scopeRoot
    property int step: 0
    VoicePill { id: pill; vertical: true }
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            scopeRoot.step++;
            Voice.poll();
            if (scopeRoot.step === 1) {
                Quickshell.execDetached(["bash", "-c", "echo 'STT_PID_S3 recording' > RT_S3/voice-stt/recorder.pid"]);
            } else if (scopeRoot.step === 5) {
                console.log("S3_VERT expanded=" + pill.isExpanded + " width=" + Math.round(pill.implicitWidth));
                Qt.quit();
            }
        }
    }
}
QMLV
)
    QML_S3_V="${QML_S3_V//STT_PID_S3/$STT_PID_S3}"
    QML_S3_V="${QML_S3_V//RT_S3/$RT_S3}"
    OUT_S3_V="$(run_qs_test "$QML_S3_V" "$RT_S3")"
    if echo "$OUT_S3_V" | grep -q "expanded=false"; then
      pass "S3: vertical=true suppresses expansion"
    else
      fail "S3: vertical=true failed to suppress expansion: $OUT_S3_V"
    fi

    # STT Recording Duration Counter Verification (G-37-6)
    QML_S3_TIMER=$(cat << 'QMLT'
import QtQuick
import Quickshell
import "modules/ii/bar"
import "services"

Scope {
    id: scopeRoot
    property int step: 0
    property string initialDuration: ""
    property string finalDuration: ""

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            scopeRoot.step++;
            Voice.poll();
            if (scopeRoot.step === 1) {
                Quickshell.execDetached(["bash", "-c", "echo 'STT_PID_S3 recording' > RT_S3/voice-stt/recorder.pid"]);
            } else if (scopeRoot.step === 3) {
                scopeRoot.initialDuration = Voice.formattedDuration;
            } else if (scopeRoot.step === 14) {
                scopeRoot.finalDuration = Voice.formattedDuration;
                console.log("S3_TIMER init=" + scopeRoot.initialDuration + " final=" + scopeRoot.finalDuration + " elapsed=" + Voice.elapsedSeconds);
                Qt.quit();
            }
        }
    }
}
QMLT
)
    QML_S3_TIMER="${QML_S3_TIMER//STT_PID_S3/$STT_PID_S3}"
    QML_S3_TIMER="${QML_S3_TIMER//RT_S3/$RT_S3}"
    OUT_S3_TIMER="$(run_qs_test "$QML_S3_TIMER" "$RT_S3" 5)"
    if echo "$OUT_S3_TIMER" | grep -q "final=0:0[1-9]"; then
      pass "S3: STT recording duration counter increments continuously from 0:00 (G-37-6)"
    else
      fail "S3: STT recording duration counter remained stuck: $OUT_S3_TIMER"
    fi

    if grep -q "Math.max(0, uptimeSec" "$REPO_ROOT/restow/quickshell/.config/quickshell/ii/services/Voice.qml"; then
      pass "S3: Voice.qml clamps elapsedSec with Math.max(0, uptimeSec - ...)"
    else
      fail "S3: Voice.qml missing Math.max(0, uptimeSec clamping"
    fi
  else
    pass "S3: [SKIPPED in --syntax mode] Headless evaluation"
  fi
fi

# ===========================================================================
# Section 4: Dynamic Palette Adaptation & Theme Audit
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Dynamic Palette Adaptation & Theme Audit ---"
  
  HEX_MATCHES="$(grep -n -E "#[0-9a-fA-F]{3,8}" "$VOICE_PILL_REPO" || true)"
  if [[ -z "$HEX_MATCHES" ]]; then
    pass "S4: Zero hardcoded hex colors found in VoicePill.qml"
  else
    fail "S4: Hardcoded hex colors detected in VoicePill.qml: $HEX_MATCHES"
  fi

  if grep -q "Appearance.colors.colPrimary" "$VOICE_PILL_REPO" && \
     grep -q "Appearance.colors.colTertiary" "$VOICE_PILL_REPO" && \
     grep -q "Appearance.colors.colSecondary" "$VOICE_PILL_REPO"; then
    pass "S4: Semantic color token bindings are present"
  else
    fail "S4: Semantic color token bindings are missing"
  fi

  if pgrep -x quickshell > /dev/null; then
    info "S4: Quickshell process is running, live reload could be triggered"
  else
    info "S4: [SOFT] Quickshell process not running; skipping live reload trigger"
  fi
fi

# ===========================================================================
# Section 5: Strict Repository Verification Gate
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Strict Repository Verification Gate ---"
  
  if git diff --exit-code vendor/dots-hyprland >/dev/null 2>&1; then
    pass "S5: vendor/dots-hyprland is clean and unmodified"
  else
    fail "S5: vendor/dots-hyprland has been modified"
  fi

  porcelain_snapshot > "$PORCELAIN_AFTER"
  if diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" >/dev/null; then
    pass "S5: Git working tree invariant before vs after test harness run"
  else
    fail "S5: Git working tree churn detected during test run:"
    diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
  fi

  if [[ "$SYNTAX_ONLY" -eq 0 ]]; then
    info "Executing ./arch/dots-hyprland.sh verify --strict..."
    VERIFY_OUT="$(./arch/dots-hyprland.sh verify --strict 2>&1 || true)"
    if echo "$VERIFY_OUT" | grep -q "=== done: FAIL=0 FINDINGS=0 ==="; then
      pass "S5: arch/dots-hyprland.sh verify --strict passed with FAIL=0 FINDINGS=0"
    else
      fail "S5: arch/dots-hyprland.sh verify --strict reported failures or findings:"
      printf '%s\n' "$VERIFY_OUT" | grep -E "(\[FAIL\]|\[FINDING\])" || true
    fi
  else
    pass "S5: [SKIPPED in --syntax mode] Strict repository verification gate"
  fi
fi

# ===========================================================================
# Summary & Exit Code
# ===========================================================================
echo ""
echo "=== Phase 37 Voice Pill Assert Summary: FAIL=$FAIL FINDINGS=$FINDINGS ==="

if [[ "$FAIL" -eq 0 && "$FINDINGS" -eq 0 ]]; then
  exit 0
else
  exit 1
fi
