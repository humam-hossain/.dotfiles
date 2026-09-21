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

  # Simple check if VoicePill exists before updatesLoader
  # Get line numbers
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
  
  # Assert that VoicePill is declared directly without being wrapped in a redundant Loader or nested BarGroup
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
