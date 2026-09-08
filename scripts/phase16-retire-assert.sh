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
#   - The documentation ban-grep (D-36) applies to the playbook
#     docs/dots-hyprland-workflow.md and to no other file. It is ban-only: it
#     forbids retired vocabulary and never requires a token to be present, so
#     it can never contradict the frozen-record asserts that DO require those
#     same tokens.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

WRAP="./arch/dots-hyprland.sh"
PLAYBOOK="docs/dots-hyprland-workflow.md"
INSTALL_OUT="$(mktemp /tmp/p16-retire-install-XXXXXX)"
FILES_OUT="$(mktemp /tmp/p16-retire-files-XXXXXX)"
SETUPS_OUT="$(mktemp /tmp/p16-retire-setups-XXXXXX)"
FULL_OUT="$(mktemp /tmp/p16-retire-full-XXXXXX)"
DEPS_OUT="$(mktemp /tmp/p16-retire-deps-XXXXXX)"
KEEPBAK_OUT="$(mktemp /tmp/p16-retire-keepbak-XXXXXX)"
UNINST_PKG_OUT="$(mktemp /tmp/p16-retire-uninst-pkg-XXXXXX)"
UNINST_VENV_OUT="$(mktemp /tmp/p16-retire-uninst-venv-XXXXXX)"
# shellcheck disable=SC2064
trap 'rm -f "$INSTALL_OUT" "$FILES_OUT" "$SETUPS_OUT" "$FULL_OUT" "$DEPS_OUT" "$KEEPBAK_OUT" "$UNINST_PKG_OUT" "$UNINST_VENV_OUT"' EXIT

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

# =============================================================================
# Documentation half (D-36) — ban-only, scoped to the playbook.
#
# Every assert below FORBIDS a string. None of them requires one. That is not a
# stylistic choice: frozen Phase 10 and Phase 11 records legitimately carry this
# vocabulary as history, and two sibling assert scripts actively require it to
# be present in them. A ban widened past the playbook would put this script in
# direct contradiction with those two. The adopt-window runbook is excluded for
# the same reason — it is a true account of what the adopt ran.
# =============================================================================

# --- H-01: --keep-backup is the opt-out for the D-06 injection ---
# The D-06 asserts above pin the default (skip-backup forwarded). This pins the
# escape hatch, without which the suppression is unconditional and an operator
# has no way to keep upstream's only snapshot. Both directions are asserted so a
# future edit cannot silently drop either the default or the opt-out.
if printf '' | "$WRAP" install --keep-backup --dry-run >"$KEEPBAK_OUT" 2>&1; then
  if grep 'would exec' "$KEEPBAK_OUT" | grep -q -- '--skip-backup'; then
    fail "H-01 install --keep-backup still forwards the upstream skip-backup flag"
    sed -n '1,40p' "$KEEPBAK_OUT" || true
  else
    pass "H-01 install --keep-backup omits the upstream skip-backup flag"
  fi
  if grep -q -- '--keep-backup' <(grep 'would exec' "$KEEPBAK_OUT"); then
    fail "H-01 --keep-backup leaked to upstream instead of being stripped"
    sed -n '1,40p' "$KEEPBAK_OUT" || true
  else
    pass "H-01 --keep-backup is wrapper-owned and never forwarded"
  fi
else
  fail "H-01 install --keep-backup --dry-run exited non-zero"
  sed -n '1,40p' "$KEEPBAK_OUT" || true
fi

# --- C-01: the uninstall flag contract is visible in the dry-run plan ---
# The state re-clean used to run outside every flag guard, so --keep-venv and
# --packages-only were silently overruled and --dry-run never showed it. These
# assert the preview reports the plan that will actually run.
if printf '' | "$WRAP" uninstall --dry-run --packages-only >"$UNINST_PKG_OUT" 2>&1; then
  # Vacuity guard: the re-clean is only planned when a live qs process was found.
  # With none running these two asserts would pass without observing anything.
  if grep -q 'would stop qs/quickshell PIDs' "$UNINST_PKG_OUT"; then
    RECLEAN_OBSERVABLE=1
  else
    RECLEAN_OBSERVABLE=0
    printf '[NOTE] C-01 re-clean asserts are inconclusive: no live qs/quickshell process, so no re-clean is planned either way. Re-run with the bar up to exercise them.\n'
  fi
  if ((RECLEAN_OBSERVABLE == 1)) && grep -qi 're-clean' "$UNINST_PKG_OUT"; then
    fail "C-01 uninstall --packages-only plans a state re-clean it must not do"
    sed -n '1,60p' "$UNINST_PKG_OUT" || true
  else
    if ((RECLEAN_OBSERVABLE == 1)); then
      pass "C-01 uninstall --packages-only plans no state re-clean"
    fi
  fi
else
  fail "C-01 uninstall --dry-run --packages-only exited non-zero"
  sed -n '1,60p' "$UNINST_PKG_OUT" || true
fi

if printf '' | "$WRAP" uninstall --dry-run --keep-venv >"$UNINST_VENV_OUT" 2>&1; then
  if ((RECLEAN_OBSERVABLE == 1)) && grep -i 're-clean' "$UNINST_VENV_OUT" | grep -q '/\.venv$'; then
    fail "C-01 uninstall --keep-venv plans to re-clean the venv it promised to keep"
    sed -n '1,60p' "$UNINST_VENV_OUT" || true
  else
    if ((RECLEAN_OBSERVABLE == 1)); then
      pass "C-01 uninstall --keep-venv never plans to re-clean .venv"
    fi
  fi
else
  fail "C-01 uninstall --dry-run --keep-venv exited non-zero"
  sed -n '1,60p' "$UNINST_VENV_OUT" || true
fi

echo "=== Phase 16 documentation contract (ban-only, playbook-scoped) ==="

# --- input guard: a ban-grep over a missing file passes vacuously ---
if [[ -s "$PLAYBOOK" ]]; then
  pass "D-36 playbook $PLAYBOOK exists and is non-empty"
else
  fail "D-36 playbook $PLAYBOOK is missing or empty (a ban-grep over it would pass vacuously)"
fi

# --- D-36 file-wide ban: the retired session-model term ---
if grep -niE 'dual-run' "$PLAYBOOK" >/dev/null; then
  fail "D-36 playbook still names the retired session model (dual-run)"
  grep -niE 'dual-run' "$PLAYBOOK" || true
else
  pass "D-36 playbook is free of the retired session-model term"
fi

# --- D-36 file-wide ban: the retired profile term ---
if grep -niE 'safe profile|safe defaults' "$PLAYBOOK" >/dev/null; then
  fail "D-36 playbook still names the retired install profile"
  grep -niE 'safe profile|safe defaults' "$PLAYBOOK" || true
else
  pass "D-36 playbook is free of the retired profile term"
fi

# --- Ban: the retired residual-array identifier (case-sensitive).
# A deliberate extension of D-36's list, added in the same ban-only shape.
# D-36 names two vocabulary terms and one section-scoped flag; the array
# identifier is banned on the same rule because D-16 deletes the only bullet
# that mentioned it, so any surviving occurrence is stale by construction.
if grep -n 'SAFE_DEFAULTS' "$PLAYBOOK" >/dev/null; then
  fail "D-36/A11 playbook still names the retired residual array identifier"
  grep -n 'SAFE_DEFAULTS' "$PLAYBOOK" || true
else
  pass "D-36/A11 playbook is free of the retired residual array identifier"
fi

# --- D-36 section-scoped ban: one residual flag, in the update contract only.
# The scope is the decision's, not an approximation of it: the flag is banned
# in the update-contract section and nowhere else, because the argv the wrapper
# actually builds is quoted verbatim in the install section and must stay there.
UPDATE_SECTION="$(awk '/^## [0-9]+\. .*[Uu]pdate contract/,/^## [0-9]+\. [^U]/' "$PLAYBOOK")"
if [[ -n "$UPDATE_SECTION" ]]; then
  pass "D-36 update-contract section extracted from the playbook (non-empty)"
  if printf '%s\n' "$UPDATE_SECTION" | grep -n -- '--skip-hyprland' >/dev/null; then
    fail "D-36 update-contract section still carries the residual flag"
    printf '%s\n' "$UPDATE_SECTION" | grep -n -- '--skip-hyprland' || true
  else
    pass "D-36 update-contract section omits the residual flag"
  fi
else
  fail "D-36 update-contract section extraction is empty (the ban would pass vacuously)"
fi

echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
