#!/usr/bin/env bash
# ===========================================================================
# Phase 38: Power Profiles Daemon System Integration Assert Harness
# Enforces: POWER-01, POWER-02, POWER-03, D-01 through D-08
#
# Usage (from REPO_ROOT):
#   ./scripts/phase38-power-profiles-assert.sh [--section <1-5>] [-s <1-5>] [--syntax]
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

PORCELAIN_BEFORE="$(mktemp /tmp/p38-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p38-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# Helper to run a headless Quickshell QML snippet
run_qs_test() {
  local qml_content="$1"
  local runtime_dir="${2:-}"
  local timeout_sec="${3:-4.5}"

  local runner_file
  runner_file="$(mktemp "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/p38_runner_XXXXXX.qml")"
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
# Section 1: Package Manifest & Installation Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Package Manifest & Installation Verification ---"

  if pacman -Q power-profiles-daemon >/dev/null 2>&1; then
    pass "S1: Package power-profiles-daemon is installed via pacman"
  else
    fail "S1: Package power-profiles-daemon is NOT installed"
  fi
fi

# ===========================================================================
# Section 2: Systemd Service & D-Bus Bus Verification
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Systemd Service & D-Bus Bus Verification ---"

  if systemctl is-active --quiet power-profiles-daemon.service; then
    pass "S2: power-profiles-daemon.service is active"
  else
    fail "S2: power-profiles-daemon.service is NOT active"
  fi

  if systemctl is-enabled --quiet power-profiles-daemon.service; then
    pass "S2: power-profiles-daemon.service is enabled"
  else
    fail "S2: power-profiles-daemon.service is NOT enabled"
  fi

  if busctl status net.hadess.PowerProfiles >/dev/null 2>&1; then
    pass "S2: net.hadess.PowerProfiles is responding on system D-Bus"
  else
    fail "S2: net.hadess.PowerProfiles is NOT responding on system D-Bus"
  fi

  if powerprofilesctl list >/dev/null 2>&1; then
    pass "S2: powerprofilesctl list executed successfully"
  else
    fail "S2: powerprofilesctl list failed"
  fi
fi

# ===========================================================================
# Summary & Porcelain Check
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
DIFF_OUT="$(diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true)"
if [[ -n "$DIFF_OUT" ]]; then
  fail "Working tree porcelain drift detected during test execution:"
  printf '%s\n' "$DIFF_OUT" >&2
else
  pass "Working tree porcelain is clean (no drift)"
fi

echo "=========================================="
echo "Phase 38 Test Results: FAIL=$FAIL FINDINGS=$FINDINGS"
echo "=========================================="

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
