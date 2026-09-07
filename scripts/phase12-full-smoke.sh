#!/usr/bin/env bash
# Wrapper-behavior suite for the full-only contract (D-34).
# Formerly the Phase 12 full-profile smoke; the filename is kept deliberately so
# existing references in .planning/ and the validation command lists keep resolving.
# Covers wrapper behavior only: syntax, help surface, dry-run argv, exit codes.
#
# Job split (16-RESEARCH Open Question 3): this suite covers wrapper behavior;
# scripts/phase16-retire-assert.sh covers the retirement contract and the
# documentation ban-grep (D-36).
#
# Usage (from REPO_ROOT):
#   ./scripts/phase12-full-smoke.sh
# Exit 0 if all hard asserts pass; non-zero if any hard FAIL.
#
# Constraints:
#   - Non-mutating: help / --dry-run / refusal / syntax only.
#   - Never runs a live install, a live uninstall, or any package operation.

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
DEPS_OUT="$(mktemp /tmp/p12-smoke-deps-XXXXXX)"
REFUSE_OUT="$(mktemp /tmp/p12-smoke-refuse-XXXXXX)"
# shellcheck disable=SC2064
trap 'rm -f "$HELP_OUT" "$FULL_OUT" "$SAFE_OUT" "$FILES_OUT" "$DEPS_OUT" "$REFUSE_OUT"' EXIT

echo "=== wrapper behavior: full-only contract (FULL-01/02/04, non-mutating) ==="

# --- syntax ---
if bash -n arch/dots-hyprland.sh; then
  pass "syntax: bash -n arch/dots-hyprland.sh"
else
  fail "syntax: bash -n arch/dots-hyprland.sh"
fi

# --- D-05 help documents --full as an accepted no-op alias ---
if "$WRAP" help >"$HELP_OUT" 2>&1; then
  if grep -q -- '--full' "$HELP_OUT"; then
    pass "D-05 help documents --full as an accepted no-op alias"
  else
    fail "D-05 help missing the --full no-op alias"
    sed -n '1,40p' "$HELP_OUT" || true
  fi
else
  fail "D-05 help exited non-zero"
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

# --- FULL-01/04 argv shape. Asserted on the --full path because that is where a
# --- forwarding regression would surface first; the omissions below are now true
# --- of every invocation, not only of this one.
if printf 'yes\n' | "$WRAP" install --full --dry-run >"$FULL_OUT" 2>&1; then
  if grep -q 'would exec' "$FULL_OUT"; then
    pass "FULL-04 dry-run prints would-exec"
  else
    fail "FULL-04 dry-run missing would-exec"
    sed -n '1,40p' "$FULL_OUT" || true
  fi
  if grep -q -- '--skip-hyprland' "$FULL_OUT"; then
    fail "FULL-01 dry-run leaked --skip-hyprland (must hold for every invocation)"
  else
    pass "FULL-01 dry-run omits --skip-hyprland (holds for every invocation)"
  fi
  if grep -q -- '--skip-sysupdate' "$FULL_OUT"; then
    fail "FULL-01 dry-run leaked --skip-sysupdate (must hold for every invocation)"
  else
    pass "FULL-01 dry-run omits --skip-sysupdate (holds for every invocation)"
  fi
  if grep -E -- '(^|[[:space:]])--core([[:space:]]|$)' "$FULL_OUT" >/dev/null; then
    fail "FULL-01 dry-run leaked standalone --core (must hold for every invocation)"
  else
    pass "FULL-01 dry-run omits standalone --core (holds for every invocation)"
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

# --- FULL-02 a bare install injects no residual profile flags ---
if printf 'yes\n' | "$WRAP" install --dry-run >"$SAFE_OUT" 2>&1; then
  if ! grep -q -- '--skip-hyprland' "$SAFE_OUT" \
    && ! grep -q -- '--skip-sysupdate' "$SAFE_OUT" \
    && ! grep -E -- '(^|[[:space:]])--core([[:space:]]|$)' "$SAFE_OUT" >/dev/null; then
    pass "FULL-02 bare install --dry-run omits all three residual profile flags"
  else
    fail "FULL-02 bare install --dry-run still injects a residual profile flag"
    sed -n '1,40p' "$SAFE_OUT" || true
  fi
else
  fail "FULL-02 install --dry-run exited non-zero"
fi

# --- FULL-02 a bare install-files is the same story ---
if printf 'yes\n' | "$WRAP" install-files --dry-run >"$FILES_OUT" 2>&1; then
  if grep -q -- '--skip-hyprland' "$FILES_OUT"; then
    fail "FULL-02 bare install-files --dry-run still shows a residual profile flag"
    sed -n '1,40p' "$FILES_OUT" || true
  else
    pass "FULL-02 bare install-files --dry-run omits --skip-hyprland"
  fi
else
  fail "FULL-02 install-files --dry-run exited non-zero"
fi

# --- D-07 the dry-run plan no longer marks packages or enables session hooks ---
if grep -q 'protect-list' "$FULL_OUT" \
  || grep -qiE 'ii hooks|enable ii hooks' "$FULL_OUT"; then
  fail "D-07 dry-run still plans package marking or session hooks"
  sed -n '1,80p' "$FULL_OUT" || true
else
  pass "D-07 dry-run plans no package marking and no session hooks"
fi

# --- D-05 --full is accepted on install-deps and announced as ignored (A2) ---
if "$WRAP" install-deps --full --dry-run >"$DEPS_OUT" 2>&1; then
  pass "D-05 install-deps --full --dry-run exits 0 (scope refusal retired)"
  if grep '^\[CONFIG\]' "$DEPS_OUT" | grep -q -- '--full'; then
    pass "D-05 install-deps --full prints the [CONFIG] ignored-note"
  else
    fail "D-05 install-deps --full prints no [CONFIG] ignored-note"
    sed -n '1,40p' "$DEPS_OUT" || true
  fi
else
  fail "D-05 install-deps --full --dry-run exited non-zero"
  sed -n '1,40p' "$DEPS_OUT" || true
fi

# --- D-07 the retired subcommand is refused by the ALLOWLIST array ---
if "$WRAP" protect --dry-run >"$REFUSE_OUT" 2>&1; then
  fail "D-07 retired subcommand still dispatches; expected a non-zero exit"
  sed -n '1,40p' "$REFUSE_OUT" || true
else
  pass "D-07 retired subcommand exits non-zero"
  if grep -q 'non-allowlisted' "$REFUSE_OUT"; then
    pass "D-07 refusal names it as a non-allowlisted subcommand"
  else
    fail "D-07 refusal message does not name it as non-allowlisted"
    sed -n '1,40p' "$REFUSE_OUT" || true
  fi
fi

echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
