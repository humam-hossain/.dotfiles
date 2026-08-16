#!/usr/bin/env bash
# Phase 12 FULL-01..05 automated smoke asserts (Nyquist validation).
# Non-mutating only: help / --dry-run / refuse / syntax. Never runs live install --full.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase12-full-smoke.sh
# Exit 0 if all hard asserts pass; non-zero if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

WRAP="./arch/dots-hyprland.sh"
HELP_OUT="$(mktemp /tmp/p12-smoke-help-XXXXXX)"
FULL_OUT="$(mktemp /tmp/p12-smoke-full-XXXXXX)"
SAFE_OUT="$(mktemp /tmp/p12-smoke-safe-XXXXXX)"
FILES_OUT="$(mktemp /tmp/p12-smoke-files-XXXXXX)"
ALLOW_OUT="$(mktemp /tmp/p12-smoke-allow-XXXXXX)"
# shellcheck disable=SC2064
trap 'rm -f "$HELP_OUT" "$FULL_OUT" "$SAFE_OUT" "$FILES_OUT" "$ALLOW_OUT"' EXIT

echo "=== Phase 12 full-profile smoke (FULL-01..05, non-mutating) ==="

# --- syntax ---
if bash -n arch/dots-hyprland.sh; then
  pass "syntax: bash -n arch/dots-hyprland.sh"
else
  fail "syntax: bash -n arch/dots-hyprland.sh"
fi

# --- FULL-01 help documents --full ---
if "$WRAP" help >"$HELP_OUT" 2>&1; then
  if grep -q -- '--full' "$HELP_OUT"; then
    pass "FULL-01 help lists --full"
  else
    fail "FULL-01 help missing --full"
    sed -n '1,40p' "$HELP_OUT" || true
  fi
else
  fail "FULL-01 help exited non-zero"
fi

# --- D-04: help no longer sends operators outside the wrapper for full hypr ---
if grep -qi 'Full hypr install requires calling vendor' "$HELP_OUT"; then
  fail "D-04 help still has vendor-outside full note"
else
  pass "D-04 help has no vendor-outside full note"
fi

# --- D-13: playbook pointer ---
if grep -q 'dots-hyprland-workflow' "$HELP_OUT"; then
  pass "D-13 help points at dots-hyprland-workflow"
else
  fail "D-13 help missing dots-hyprland-workflow"
fi

# --- FULL-01/04 full dry-run argv ---
if printf 'yes\n' | "$WRAP" install --full --dry-run >"$FULL_OUT" 2>&1; then
  if grep -q 'would exec' "$FULL_OUT"; then
    pass "FULL-04 full dry-run prints would-exec"
  else
    fail "FULL-04 full dry-run missing would-exec"
    sed -n '1,40p' "$FULL_OUT" || true
  fi
  if grep -q -- '--skip-hyprland' "$FULL_OUT"; then
    fail "FULL-01 full dry-run leaked --skip-hyprland"
  else
    pass "FULL-01 full dry-run omits --skip-hyprland"
  fi
  if grep -q -- '--skip-sysupdate' "$FULL_OUT"; then
    fail "FULL-01 full dry-run leaked --skip-sysupdate"
  else
    pass "FULL-01 full dry-run omits --skip-sysupdate"
  fi
  if grep -E -- '(^|[[:space:]])--core([[:space:]]|$)' "$FULL_OUT" >/dev/null; then
    fail "FULL-01 full dry-run leaked standalone --core"
  else
    pass "FULL-01 full dry-run omits standalone --core"
  fi
  if grep 'would exec' "$FULL_OUT" | grep -q -- '--full'; then
    fail "FULL-01 would-exec line still has meta --full"
  else
    pass "FULL-01 would-exec strips meta --full"
  fi
else
  fail "FULL-04 install --full --dry-run exited non-zero"
  sed -n '1,40p' "$FULL_OUT" || true
fi

# --- FULL-02 safe residual still injected ---
if printf 'yes\n' | "$WRAP" install --dry-run >"$SAFE_OUT" 2>&1; then
  if grep -q -- '--core' "$SAFE_OUT" \
    && grep -q -- '--skip-hyprland' "$SAFE_OUT" \
    && grep -q -- '--skip-sysupdate' "$SAFE_OUT"; then
    pass "FULL-02 bare install --dry-run still injects triple residual"
  else
    fail "FULL-02 bare install --dry-run missing SAFE_DEFAULTS residuals"
    sed -n '1,40p' "$SAFE_OUT" || true
  fi
else
  fail "FULL-02 install --dry-run exited non-zero"
fi

# --- FULL-02b install-files residual ---
if printf 'yes\n' | "$WRAP" install-files --dry-run >"$FILES_OUT" 2>&1; then
  if grep -q -- '--skip-hyprland' "$FILES_OUT"; then
    pass "FULL-02b bare install-files --dry-run still shows residuals"
  else
    fail "FULL-02b install-files --dry-run missing residuals"
    sed -n '1,40p' "$FILES_OUT" || true
  fi
else
  fail "FULL-02b install-files --dry-run exited non-zero"
fi

# --- FULL-03 bare skip-backup refuse ---
if "$WRAP" install --full --skip-backup --dry-run >/tmp/p12-smoke-skip.txt 2>&1; then
  fail "FULL-03 install --full --skip-backup --dry-run should exit non-zero"
else
  pass "FULL-03 bare --skip-backup on full refused"
fi

# --- FULL-03b dual-key allow ---
if printf 'yes\n' | "$WRAP" install --full --skip-backup --allow-skip-backup --dry-run >"$ALLOW_OUT" 2>&1; then
  if grep -q 'would exec' "$ALLOW_OUT" \
    && grep -q -- '--skip-backup' "$ALLOW_OUT" \
    && ! grep -q -- '--allow-skip-backup' "$ALLOW_OUT" \
    && ! grep 'would exec' "$ALLOW_OUT" | grep -q -- '--full'; then
    pass "FULL-03b dual-key allow dry-run strips meta, keeps skip-backup"
  else
    fail "FULL-03b dual-key allow greps failed"
    sed -n '1,40p' "$ALLOW_OUT" || true
  fi
else
  fail "FULL-03b dual-key allow dry-run exited non-zero"
fi

# --- FULL-05 protect + ii hooks plan ---
if grep -q 'protect-list' "$FULL_OUT" \
  && grep -qiE 'ii hooks|enable ii hooks' "$FULL_OUT"; then
  pass "FULL-05 full dry-run plans protect-list + ii hooks"
else
  fail "FULL-05 full dry-run missing protect-list or ii hooks plan"
  sed -n '1,80p' "$FULL_OUT" || true
fi

# --- D-02 --full refused on install-deps ---
if "$WRAP" install-deps --full --dry-run >/tmp/p12-smoke-deps.txt 2>&1; then
  fail "D-02 install-deps --full --dry-run should exit non-zero"
else
  pass "D-02 --full refused on install-deps"
fi

echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
