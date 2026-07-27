#!/usr/bin/env bash
# Phase 7 LIVE-01..04 automated smoke asserts (Nyquist validation).
# Safe to re-run post-install. Does not mutate machine state except dry-run
# of arch/dots-hyprland.sh install --dry-run (no files written).
#
# Usage (from REPO_ROOT):
#   ./scripts/phase07-live-smoke.sh
# Exit 0 if all automated asserts pass; non-zero on first hard failure.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
soft() { printf '[SOFT] %s\n' "$1"; }

echo "=== Phase 7 live smoke (LIVE-01..04 automated) ==="

# --- LIVE-01 ---
if test ! -L "${HOME}/.config/quickshell" \
  && test -d "${HOME}/.config/quickshell" \
  && test -f "${HOME}/.config/quickshell/ii/shell.qml"; then
  pass "LIVE-01 real dir + ii/shell.qml"
else
  fail "LIVE-01 real dir + ii/shell.qml"
fi

case "$(readlink -f "${HOME}/.config/quickshell" 2>/dev/null || true)" in
  */.dotfiles/.config/quickshell*) fail "LIVE-01 path under .dotfiles product" ;;
  *) pass "LIVE-01 path not under .dotfiles product" ;;
esac

if test -d "${HOME}/.local/state/quickshell/.venv"; then
  pass "LIVE-01 ii Python venv"
else
  fail "LIVE-01 ii Python venv"
fi

if test -f "${HOME}/.config/hypr/hyprland.conf" \
  && test ! -e "${HOME}/.config/hypr/hyprland.conf.old"; then
  pass "LIVE-01 personal hypr conf present, no .old"
else
  fail "LIVE-01 personal hypr conf present, no .old"
fi

if test -d "${REPO_ROOT}/.config/quickshell"; then
  pass "D-04 in-repo .config/quickshell still present"
else
  fail "D-04 in-repo .config/quickshell still present"
fi

# --- D-06 dry-run SAFE_DEFAULTS ---
bash -n ./arch/dots-hyprland.sh
pass "bash -n arch/dots-hyprland.sh"

DRY_OUT="$(mktemp)"
# shellcheck disable=SC2064
trap 'rm -f "$DRY_OUT"' EXIT
if printf 'yes\n' | ./arch/dots-hyprland.sh install --dry-run >"$DRY_OUT" 2>&1; then
  if grep -q -- '--core' "$DRY_OUT" \
    && grep -q -- '--skip-hyprland' "$DRY_OUT" \
    && grep -q -- '--skip-sysupdate' "$DRY_OUT" \
    && grep -qiE 'dry-run|would exec' "$DRY_OUT"; then
    pass "D-06 install --dry-run SAFE_DEFAULTS"
  else
    fail "D-06 install --dry-run SAFE_DEFAULTS (argv missing)"
    sed -n '1,40p' "$DRY_OUT" || true
  fi
else
  fail "D-06 install --dry-run exited non-zero"
  sed -n '1,40p' "$DRY_OUT" || true
fi

# --- LIVE-02 ---
if grep -E 'env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,' .config/hypr/hyprland.conf >/dev/null; then
  pass "LIVE-02 repo env ILLOGICAL_IMPULSE_VIRTUAL_ENV"
else
  fail "LIVE-02 repo env ILLOGICAL_IMPULSE_VIRTUAL_ENV"
fi

if grep -E 'exec-once = qs -c ii' .config/hypr/hyprland.conf >/dev/null; then
  pass "LIVE-02 repo exec-once qs -c ii"
else
  fail "LIVE-02 repo exec-once qs -c ii"
fi

if cmp -s .config/hypr/hyprland.conf "${HOME}/.config/hypr/hyprland.conf"; then
  pass "LIVE-02 repo/live hyprland.conf cmp -s"
else
  fail "LIVE-02 repo/live hyprland.conf cmp -s"
fi

# --- LIVE-03 ---
if pgrep -x waybar >/dev/null; then
  pass "LIVE-03 waybar process"
else
  fail "LIVE-03 waybar process"
fi

if grep -E 'exec-once = waybar' .config/hypr/hyprland.conf >/dev/null; then
  pass "LIVE-03 waybar exec-once preserved"
else
  fail "LIVE-03 waybar exec-once preserved"
fi

if pgrep -x swaync >/dev/null; then
  pass "LIVE-03 swaync soft present"
else
  soft "LIVE-03 swaync not running (soft assert)"
fi

# --- LIVE-04 automated (chrome is manual / UAT) ---
if pgrep -a qs 2>/dev/null | grep -E -- '-c ii|\bii\b' >/dev/null; then
  pass "LIVE-04 qs -c ii process"
else
  fail "LIVE-04 qs -c ii process"
fi

QS_PID="$(pgrep -n -x qs 2>/dev/null || true)"
if [[ -n "$QS_PID" ]] \
  && tr '\0' '\n' <"/proc/${QS_PID}/environ" 2>/dev/null \
    | grep -q '^ILLOGICAL_IMPULSE_VIRTUAL_ENV='; then
  pass "LIVE-04 qs environ has ILLOGICAL_IMPULSE_VIRTUAL_ENV"
else
  fail "LIVE-04 qs environ has ILLOGICAL_IMPULSE_VIRTUAL_ENV"
fi

echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
