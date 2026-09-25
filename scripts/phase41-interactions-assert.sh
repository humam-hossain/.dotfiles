#!/usr/bin/env bash
# ===========================================================================
# Phase 41: Milestone v0.8 Integration & Verification Engine
# Enforces: INTG-01, INTG-02, INTG-03, POWER-01..03, MEDIA-01..02,
#           NOTIF-01..02, NAV-01..02, OTP-01..02, CLOCK-01, VOL-01..02,
#           T-41-01, T-41-02, T-41-03, T-41-04
#
# Usage (from REPO_ROOT):
#   ./scripts/phase41-interactions-assert.sh [OPTIONS]
#
# Options:
#   -s, --section <1-6>    Execute only the specified section (1-6)
#   -q, --quick,
#       --standalone       Run standalone sections only (skip sub-harnesses)
#   -c, --syntax           Execute static AST and syntax checks only
#   -l, --live-notify,
#       --live             Trigger live desktop notification test
#   -h, --help             Show this help message
#
# Exit 0 if all hard asserts pass (FAIL=0 FINDINGS=0); exit 1 if any FAIL.
# ===========================================================================

set -euo pipefail

# Fail closed if run as root (ASVS V4, T-41-01)
[[ "${EUID:-$(id -u)}" -ne 0 ]] || { echo "Error: Do not run as root" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }
soft() { printf '[SOFT] %s\n' "$1"; }

TMP_FILES=()
INITIAL_PROFILE=""

cleanup_power() {
  if [[ -n "$INITIAL_PROFILE" ]]; then
    local current
    current="$(powerprofilesctl get 2>/dev/null || echo "")"
    if [[ -n "$current" && "$current" != "$INITIAL_PROFILE" ]]; then
      info "Restoring initial power profile '$INITIAL_PROFILE' (was '$current')..."
      powerprofilesctl set "$INITIAL_PROFILE" 2>/dev/null || true
    fi
  fi
}

cleanup() {
  cleanup_power
  if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
    rm -f "${TMP_FILES[@]}" 2>/dev/null || true
  fi
  return 0
}
trap cleanup EXIT INT TERM

RUN_SECTION=0
QUICK_MODE=0
SYNTAX_ONLY=0
LIVE_NOTIFY=0

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
    --quick|--standalone|-q)
      QUICK_MODE=1
      shift
      ;;
    --syntax|-c)
      SYNTAX_ONLY=1
      shift
      ;;
    --live-notify|--live|-l)
      LIVE_NOTIFY=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -s, --section <1-6>    Execute only the specified section (1-6)"
      echo "  -q, --quick,           Run standalone sections only (skip sub-harnesses)"
      echo "      --standalone"
      echo "  -c, --syntax           Execute static AST and syntax checks only"
      echo "  -l, --live-notify,     Trigger live desktop notification test"
      echo "      --live"
      echo "  -h, --help             Show this help message"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

info "=== Milestone v0.8 Integration & Verification Engine ==="
info "Working directory: $REPO_ROOT"
info "Flags: section=$RUN_SECTION quick=$QUICK_MODE syntax_only=$SYNTAX_ONLY live_notify=$LIVE_NOTIFY"

# ===========================================================================
# Prerequisite Binaries Gate (D-05)
# ===========================================================================
info "--- Prerequisite Binaries Gate ---"
REQUIRED_BINS=(bash jq node lua luac powerprofilesctl wpctl qs git)
for bin in "${REQUIRED_BINS[@]}"; do
  if command -v "$bin" >/dev/null 2>&1; then
    pass "Prereq: Command '$bin' is available on PATH"
  else
    fail "Prereq: Required command '$bin' is MISSING on PATH (D-05)"
  fi
done

# ===========================================================================
# Working-Tree Porcelain Baseline Snapshot (D-09, T-41-04)
# ===========================================================================
porcelain_snapshot_raw() { git status --porcelain --ignored || true; }
porcelain_snapshot() { porcelain_snapshot_raw | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true; }

PORCELAIN_BEFORE="$(mktemp /tmp/p41-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p41-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Syntax Validation Branch (--syntax)
# ===========================================================================
if [[ "$SYNTAX_ONLY" -eq 1 ]]; then
  info "--- Syntax Verification Mode ---"
  if bash -n "$0"; then
    pass "Syntax: Harness bash -n validation passed"
  else
    fail "Syntax: Harness bash -n validation failed"
  fi

  CONFIG_JSON="$REPO_ROOT/capture/ii/.config/illogical-impulse/config.json"
  if [[ -f "$CONFIG_JSON" ]]; then
    if jq . "$CONFIG_JSON" >/dev/null 2>&1; then
      pass "Syntax: config.json is valid JSON"
    else
      fail "Syntax: config.json failed JSON parse"
    fi
  else
    fail "Syntax: config.json not found at $CONFIG_JSON"
  fi

  info "=========================================="
  info "Syntax Summary: FAIL=$FAIL FINDINGS=$FINDINGS"
  info "=========================================="
  exit "$FAIL"
fi

info "Scaffold baseline ready."
