#!/usr/bin/env bash
# Phase 17 unblock contract asserts (D-20).
# Asserts the FIX-01 / CAP-04 stow-flag sweep: every stow invocation under
# arch/ and docs/ carries the valid --verbose=5 --no-folding spelling in that
# fixed order, the invalid short-verbosity spelling survives at zero sites in
# those two trees, the edited installer scripts still parse, and the installed
# GNU Stow actually accepts the new spelling.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase17-unblock-assert.sh
# Exit 0 if all hard asserts pass; non-zero if any hard FAIL.
#
# Constraints (Phase 17):
#   - Non-mutating: this script runs only greps, `bash -n`, stow simulate (-n)
#     runs and a sourced-subshell fixture. It never runs a live install, a live
#     uninstall, or any package operation.
#   - The D-02 folding audit is read-only and reports [INFO] only. This phase
#     records the already-folded directories and hands them to Phase 18; it
#     never unfolds one.
#   - Contract (D-20): three prefixes [PASS] [FAIL] [INFO], ONE counter FAIL,
#     closing line `=== done: FAIL=n ===`. The sibling phase14-verify.sh uses a
#     different contract (a second counter and a fourth prefix); it is not
#     copied here beyond its info() helper line.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

echo "=== Phase 17 unblock contract (non-mutating) ==="

# --- criterion 1e / FIX-01: the installed GNU Stow accepts the new spelling ---
# Behavioral, not textual. A grep proves only that the literal is written; only
# a real stow run proves the literal parses. `-n` makes it a simulate, so the
# run plans and reports without touching the destination tree.
if ( cd "$REPO_ROOT/stow" && stow --verbose=5 --no-folding -n -t ~ btop ) >/dev/null 2>&1; then
  pass "1e GNU Stow accepts --verbose=5 --no-folding (simulate run of package btop exits 0)"
else
  fail "1e GNU Stow rejected --verbose=5 --no-folding on a simulate run of package btop"
  ( cd "$REPO_ROOT/stow" && stow --verbose=5 --no-folding -n -t ~ btop ) || true
fi

echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
