#!/usr/bin/env bash
# Phase 16 retirement contract asserts (D-35).
# Asserts the full-only install path: a bare invocation carries no residual
# profile flags, --full is accepted but never forwarded, the upstream
# skip-backup flag is forwarded only where upstream reads it, and no
# wrapper-owned prompt stands in front of an install.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase16-retire-assert.sh
# Exit 0 if all hard asserts pass; non-zero if any hard FAIL.
#
# Constraints (Phase 16):
#   - Non-mutating: syntax checks and --dry-run argv captures only.
#   - Never runs a live install, a live uninstall, or any package operation.
#   - The documentation ban-grep half (D-36) is scoped to
#     docs/dots-hyprland-workflow.md only and is added by plan 16-04.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

WRAP="./arch/dots-hyprland.sh"
INSTALL_OUT="$(mktemp /tmp/p16-retire-install-XXXXXX)"
FILES_OUT="$(mktemp /tmp/p16-retire-files-XXXXXX)"
SETUPS_OUT="$(mktemp /tmp/p16-retire-setups-XXXXXX)"
FULL_OUT="$(mktemp /tmp/p16-retire-full-XXXXXX)"
DEPS_OUT="$(mktemp /tmp/p16-retire-deps-XXXXXX)"
# shellcheck disable=SC2064
trap 'rm -f "$INSTALL_OUT" "$FILES_OUT" "$SETUPS_OUT" "$FULL_OUT" "$DEPS_OUT"' EXIT

echo "=== Phase 16 retirement contract (non-mutating) ==="

# --- syntax ---
if bash -n arch/dots-hyprland.sh; then
  pass "syntax: bash -n arch/dots-hyprland.sh"
else
  fail "syntax: bash -n arch/dots-hyprland.sh"
fi

# --- D-04 / FULL-01 / FULL-02: bare install is the full behavior ---
if printf '' | "$WRAP" install --dry-run >"$INSTALL_OUT" 2>&1; then
  if grep -q 'would exec' "$INSTALL_OUT"; then
    pass "D-04 bare install --dry-run prints would-exec"
  else
    fail "D-04 bare install --dry-run missing would-exec"
    sed -n '1,40p' "$INSTALL_OUT" || true
  fi
  if grep -q -- '--skip-hyprland' "$INSTALL_OUT"; then
    fail "FULL-01 bare install --dry-run leaked --skip-hyprland"
    sed -n '1,40p' "$INSTALL_OUT" || true
  else
    pass "FULL-01 bare install --dry-run omits --skip-hyprland"
  fi
  if grep -q -- '--skip-sysupdate' "$INSTALL_OUT"; then
    fail "FULL-01 bare install --dry-run leaked --skip-sysupdate"
    sed -n '1,40p' "$INSTALL_OUT" || true
  else
    pass "FULL-01 bare install --dry-run omits --skip-sysupdate"
  fi
  if grep -E -- '(^|[[:space:]])--core([[:space:]]|$)' "$INSTALL_OUT" >/dev/null; then
    fail "FULL-01 bare install --dry-run leaked standalone --core"
    sed -n '1,40p' "$INSTALL_OUT" || true
  else
    pass "FULL-01 bare install --dry-run omits standalone --core"
  fi
  if grep 'would exec' "$INSTALL_OUT" | grep -q -- '--skip-backup'; then
    pass "D-06 install would-exec forwards the upstream skip-backup flag"
  else
    fail "D-06 install would-exec is missing the upstream skip-backup flag"
    sed -n '1,40p' "$INSTALL_OUT" || true
  fi
else
  fail "D-04 install --dry-run exited non-zero"
  sed -n '1,40p' "$INSTALL_OUT" || true
fi

# --- D-04 / FULL-02: install-files is the same story ---
if printf '' | "$WRAP" install-files --dry-run >"$FILES_OUT" 2>&1; then
  if grep -q 'would exec' "$FILES_OUT"; then
    pass "D-04 bare install-files --dry-run prints would-exec"
  else
    fail "D-04 bare install-files --dry-run missing would-exec"
    sed -n '1,40p' "$FILES_OUT" || true
  fi
  if grep -q -- '--skip-hyprland' "$FILES_OUT"; then
    fail "FULL-01 bare install-files --dry-run leaked --skip-hyprland"
    sed -n '1,40p' "$FILES_OUT" || true
  else
    pass "FULL-01 bare install-files --dry-run omits --skip-hyprland"
  fi
  if grep -q -- '--skip-sysupdate' "$FILES_OUT"; then
    fail "FULL-01 bare install-files --dry-run leaked --skip-sysupdate"
    sed -n '1,40p' "$FILES_OUT" || true
  else
    pass "FULL-01 bare install-files --dry-run omits --skip-sysupdate"
  fi
  if grep -E -- '(^|[[:space:]])--core([[:space:]]|$)' "$FILES_OUT" >/dev/null; then
    fail "FULL-01 bare install-files --dry-run leaked standalone --core"
    sed -n '1,40p' "$FILES_OUT" || true
  else
    pass "FULL-01 bare install-files --dry-run omits standalone --core"
  fi
  if grep 'would exec' "$FILES_OUT" | grep -q -- '--skip-backup'; then
    pass "D-06 install-files would-exec forwards the upstream skip-backup flag"
  else
    fail "D-06 install-files would-exec is missing the upstream skip-backup flag"
    sed -n '1,40p' "$FILES_OUT" || true
  fi
else
  fail "D-04 install-files --dry-run exited non-zero"
  sed -n '1,40p' "$FILES_OUT" || true
fi

# --- D-06 scope: the flag is NOT forwarded where upstream never reads it ---
if printf '' | "$WRAP" install-setups --dry-run >"$SETUPS_OUT" 2>&1; then
  if grep 'would exec' "$SETUPS_OUT" | grep -q -- '--skip-backup'; then
    fail "D-06 install-setups would-exec carries the skip-backup flag (predicate is unscoped)"
    sed -n '1,40p' "$SETUPS_OUT" || true
  else
    pass "D-06 install-setups would-exec omits the skip-backup flag"
  fi
else
  fail "D-06 install-setups --dry-run exited non-zero"
  sed -n '1,40p' "$SETUPS_OUT" || true
fi

# --- D-09: no wrapper-owned prompt on the install path ---
if grep -q "Type 'yes'" "$INSTALL_OUT"; then
  fail "D-09 install --dry-run still prints the exact-token gate line"
  sed -n '1,40p' "$INSTALL_OUT" || true
else
  pass "D-09 install path has no wrapper-owned confirmation prompt"
fi

# --- D-05: --full accepted, announced as ignored, never forwarded ---
if printf '' | "$WRAP" install --full --dry-run >"$FULL_OUT" 2>&1; then
  pass "D-05 install --full --dry-run exits 0"
  if grep '^\[CONFIG\]' "$FULL_OUT" | grep -q -- '--full'; then
    pass "D-05 install --full prints a [CONFIG] note naming the ignored flag"
  else
    fail "D-05 install --full prints no [CONFIG] ignored-note"
    sed -n '1,40p' "$FULL_OUT" || true
  fi
  if grep 'would exec' "$FULL_OUT" | grep -q -- '--full'; then
    fail "D-05 would-exec line still carries meta --full"
    sed -n '1,40p' "$FULL_OUT" || true
  else
    pass "D-05 would-exec strips meta --full"
  fi
else
  fail "D-05 install --full --dry-run exited non-zero"
  sed -n '1,40p' "$FULL_OUT" || true
fi

# --- A2: --full is accepted on every install-family subcommand ---
if printf '' | "$WRAP" install-deps --full --dry-run >"$DEPS_OUT" 2>&1; then
  pass "A2 install-deps --full --dry-run exits 0 (scope refusal retired)"
else
  fail "A2 install-deps --full --dry-run exited non-zero"
  sed -n '1,40p' "$DEPS_OUT" || true
fi

echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
