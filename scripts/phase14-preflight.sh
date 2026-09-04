#!/usr/bin/env bash
# Phase 14 live-adopt preflight — mechanical go conditions for the ADOPT-01 window.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase14-preflight.sh
# Exit 0 if all hard asserts pass; non-zero if any hard FAIL.
#
# Output levels:
#   [PASS]     hard condition satisfied
#   [FAIL]     hard condition violated — moves the exit code
#   [FINDING]  reported condition the script deliberately declines to encode as an
#              exit code; it is dispositioned by the runbook's go/no-go checklist
#              (D-18). FINDINGS never move the exit code.
#
# Constraints (Phase 14):
#   - The default path performs no mv/rm/cp/rsync under $HOME. It is read-only
#     against the operator's home directory and safe to run repeatedly (D-13, D-27).
#   - Never call ./setup or arch/dots-hyprland.sh without --dry-run.
#   - The exit code is input 1 to the go/no-go gate in
#     docs/phase14-adopt-runbook.md — it is not the gate itself (D-18).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }

XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$HOME/ii-original-dots-backup"
WRAP="./arch/dots-hyprland.sh"
VENDOR="vendor/dots-hyprland"

FULL_OUT="$(mktemp /tmp/p14-preflight-full-XXXXXX)"
# shellcheck disable=SC2064
trap 'rm -f "$FULL_OUT"' EXIT

echo "=== Phase 14 adopt preflight (non-mutating on the default path) ==="
echo "[CONFIG] repo_root=$REPO_ROOT"
echo "[CONFIG] xdg=$XDG"
echo "[CONFIG] backup_dir=$BACKUP_DIR"

# --- D-34: not-firstrun marker (hard precondition; every later check depends on it) ---
if [[ -f "$XDG/illogical-impulse/installed_true" ]]; then
  pass "D-34 not-firstrun marker present: $XDG/illogical-impulse/installed_true"
else
  fail "D-34 not-firstrun marker missing: $XDG/illogical-impulse/installed_true"
  echo "       Without installed_true, upstream sets INSTALL_FIRSTRUN=true and replaces"
  echo "       live hyprlock.conf / hypridle.conf instead of writing .new sidecars."
  echo "       Phase 11 D-24 (lock/idle no-touch) stops holding. Adopt is a no-go."
  echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
  exit 1
fi

# --- D-12: vendor submodule pin recorded and clean ---
VENDOR_PIN="$(git -C "$VENDOR" rev-parse HEAD)"
echo "[CONFIG] submodule pin=$VENDOR_PIN"
VENDOR_DIRTY="$(git -C "$VENDOR" status --porcelain)"
VENDOR_SUBS="$(git -C "$VENDOR" submodule status --recursive 2>/dev/null | grep -E '^[+U-]' || true)"
PARENT_VENDOR_DIRTY="$(git status --porcelain -- "$VENDOR")"
if [[ -z "$VENDOR_DIRTY" && -z "$VENDOR_SUBS" && -z "$PARENT_VENDOR_DIRTY" ]]; then
  pass "D-12 vendor submodule clean and pin matches parent: $VENDOR_PIN"
else
  fail "D-12 vendor submodule dirty or pin mismatch"
  [[ -n "$VENDOR_DIRTY" ]] && printf '       worktree: %s\n' "$VENDOR_DIRTY"
  [[ -n "$VENDOR_SUBS" ]] && printf '       nested submodule: %s\n' "$VENDOR_SUBS"
  [[ -n "$PARENT_VENDOR_DIRTY" ]] && printf '       parent records a different pin: %s\n' "$PARENT_VENDOR_DIRTY"
fi

# --- D-05: gate-fed dry-run (the only agent-safe wrapper invocation) ---
# The `printf 'yes\n' |` pipe is mandatory: backup_gate reads stdin and exits 1 on
# any non-`yes` token before argv is ever assembled.
if printf 'yes\n' | "$WRAP" install --full --dry-run >"$FULL_OUT" 2>&1; then
  if grep -q 'would exec' "$FULL_OUT" && ! grep -q -- '--skip-hyprland' "$FULL_OUT"; then
    pass "D-05 gate-fed install --full --dry-run prints would-exec, no --skip-hyprland"
  else
    fail "D-05 gate-fed install --full --dry-run malformed (missing would-exec or leaked --skip-hyprland)"
    sed -n '1,40p' "$FULL_OUT" || true
  fi
else
  fail "D-05 gate-fed install --full --dry-run exited non-zero"
  sed -n '1,40p' "$FULL_OUT" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
