#!/usr/bin/env bash
# Phase 28 Terminal & Fuzzel Launcher Dynamic Palette assert harness (TERM-01, TERM-02, INTG-01, INTG-02).
# One script, one section per requirement criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase28-terminal-fuzzel-assert.sh [--section <1-5>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

ASSERT_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"

FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
SCRATCH_ROOTS=()

cleanup() {
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true
  local root
  for root in ${SCRATCH_ROOTS[@]+"${SCRATCH_ROOTS[@]}"}; do
    [[ -n "$root" ]] || continue
    chmod -R u+rwX "$root" 2>/dev/null || true
    rm -rf "$root" 2>/dev/null || true
  done
  return 0
}
trap cleanup EXIT

RUN_SECTION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-5>]"
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

PORCELAIN_BEFORE="$(mktemp /tmp/p28-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p28-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: Template & Config Readiness (INTG-01, TERM-01, TERM-02, D-01, D-03, D-12, D-16)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Template & Config Readiness (INTG-01, TERM-01, TERM-02, D-01, D-03, D-12, D-16) ---"
  # Stub: implemented in Task 28-01-02
fi

# ===========================================================================
# Section 2: Fuzzel Theme Syntax & Configuration Integrity (TERM-01, D-13, D-14)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Fuzzel Theme Syntax & Configuration Integrity (TERM-01, D-13, D-14) ---"
  # Stub: implemented in Plan 28-02
fi

# ===========================================================================
# Section 3: Terminal Theme Syntax & Configuration Integrity (TERM-02, D-01, D-02, D-08..D-11)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Terminal Theme Syntax & Configuration Integrity (TERM-02, D-01, D-02, D-08..D-11) ---"
  # Stub: implemented in Plan 28-02
fi

# ===========================================================================
# Section 4: Live Reload Drill & Process Signaling (TERM-01, TERM-02, D-05, D-18)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Live Reload Drill & Process Signaling (TERM-01, TERM-02, D-05, D-18) ---"
  # Stub: implemented in Plan 28-03
fi

# ===========================================================================
# Section 5: Strict Verification Engine & Zero Git Drift (INTG-01, INTG-02, D-17, D-19)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Strict Verification Engine & Zero Git Drift (INTG-01, INTG-02, D-17, D-19) ---"
  # Stub: implemented in Plan 28-03
fi

# ===========================================================================
# Closing porcelain invariant check & summary
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run (D-19)"
else
  fail "Closing self-check: git status --porcelain mutated across run (D-19)"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
