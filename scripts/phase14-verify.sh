#!/usr/bin/env bash
# Phase 14 post-adopt verify — proves the live adopt landed, against the running session.
#
# Constraints (Phase 14 ADOPT-02 / ADOPT-03 prohibitions):
#   - READ-ONLY against the live session and the operator's home. This script never
#     terminates a process, never asks the compositor to re-read or to set any
#     configuration value, and never writes anything under "$XDG". Every probe is an
#     observation; nothing here mutates its own subject to green a check.
#   - Never invokes ./arch/dots-hyprland.sh without --dry-run.
#   - Never reports a [PASS] for a condition it could not observe. An unobservable
#     condition emits [INFO] or [FINDING], never a pass and never a silent skip.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase14-verify.sh
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.
#
# Output levels:
#   [PASS]     hard condition satisfied
#   [FAIL]     hard condition violated — moves the exit code
#   [FINDING]  observed condition recorded and dispositioned in 14-LIVE-VERIFY.md;
#              FINDINGS never move the exit code (D-14, D-38)
#   [INFO]     a condition this run could not observe, named rather than skipped

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
BASELINE=".planning/phases/14-live-full-adopt-verify/14-PRE-ADOPT-BASELINE.txt"
BACKUP_DIR="$HOME/ii-original-dots-backup"
WRAP="./arch/dots-hyprland.sh"

# --- fixture reader -----------------------------------------------------------
# After the install the live pre-adopt hyprland.conf no longer exists, so D-36 and
# D-37 are only provable against the recorded fixture. A missing fixture or a
# missing key is a loud hard failure, never an empty comparison that passes.
#
# baseline_value runs inside a command substitution, so an `exit` here would only
# leave the subshell and let the script sail on with an empty value. It therefore
# `return 1`s and every call site is written `X="$(baseline_value k)" || exit 1`.
# The fixture's existence is gated once, below, at the top level where exit works.
if [[ ! -f "$BASELINE" ]]; then
  printf '[FAIL] baseline fixture missing: %s\n' "$BASELINE" >&2
  printf '       Recorded by plan 14-01 before any mutation. Without it the D-36 and\n' >&2
  printf '       D-37 comparisons are circular: the live pre-adopt conf no longer exists.\n' >&2
  printf '       Aborting rather than comparing against nothing.\n' >&2
  exit 1
fi

baseline_value() {
  local key="$1" line
  line="$(grep -m1 -E "^${key}=" "$BASELINE" || true)"
  if [[ -z "$line" ]]; then
    printf '[FAIL] baseline key absent from %s: %s\n' "$BASELINE" "$key" >&2
    printf '       Fixture is present but incomplete. Aborting rather than comparing to empty.\n' >&2
    return 1
  fi
  printf '%s' "${line#*=}"
}

echo "=== Phase 14 post-adopt verify (read-only against the live session) ==="
echo "[CONFIG] repo_root=$REPO_ROOT"
echo "[CONFIG] xdg=$XDG"
echo "[CONFIG] baseline=$BASELINE"
echo "[CONFIG] backup_dir=$BACKUP_DIR"
BASELINE_CAPTURED="$(baseline_value baseline_captured)" || exit 1
echo "[CONFIG] baseline_captured=$BASELINE_CAPTURED"

# =============================================================================
# ADOPT-02 — the running session came from the ii Lua entry (D-33, three ways)
# =============================================================================

# 1. The rename happened.
if [[ -f "$XDG/hypr/hyprland.conf.old" ]]; then
  pass "ADOPT-02 hyprland.conf.old present: $XDG/hypr/hyprland.conf.old"
else
  fail "ADOPT-02 hyprland.conf.old missing — upstream's rename did not happen"
fi

# 2. The Lua entry installed.
if [[ -f "$XDG/hypr/hyprland.lua" ]]; then
  pass "ADOPT-02 hyprland.lua present: $XDG/hypr/hyprland.lua"
else
  fail "ADOPT-02 hyprland.lua missing — did --skip-hyprland-entry leak past the ban?"
fi

# 3. Nothing remains that could win over the Lua entry. Correct under either
#    reading of the 0.56.2 format preference (RESEARCH Open Question 1), and it
#    catches a failed rename directly.
if [[ ! -f "$XDG/hypr/hyprland.conf" ]]; then
  pass "ADOPT-02 hyprland.conf absent — no .conf can win over the Lua entry"
else
  fail "ADOPT-02 hyprland.conf still present at $XDG/hypr/hyprland.conf"
fi

# 4. The compositor names its own config provider. Assert the ABSENCE of the
#    recorded pre-adopt token, never the presence of a guessed post-adopt one:
#    the pre-adopt value is an observed fact, the post-adopt value is not.
CONFIG_PROVIDER_PRE="$(baseline_value configProvider_pre)" || exit 1
PROVIDER_LIVE="$(hyprctl -j status 2>/dev/null | jq -r '.configProvider' 2>/dev/null || true)"
if [[ -z "$PROVIDER_LIVE" || "$PROVIDER_LIVE" == "null" ]]; then
  fail "ADOPT-02 config provider unreadable — hyprctl -j status returned no configProvider"
elif [[ "$PROVIDER_LIVE" == "$CONFIG_PROVIDER_PRE" ]]; then
  fail "ADOPT-02 configProvider is still '$PROVIDER_LIVE' (recorded pre-adopt value) — session did not load the Lua entry"
else
  pass "ADOPT-02 configProvider is '$PROVIDER_LIVE', no longer the recorded pre-adopt '$CONFIG_PROVIDER_PRE'"
fi

# 5. The Lua REPL, independent of any token. Pre-adopt this refused with
#    "eval is only supported with the lua config manager".
EVAL_OUT="$(hyprctl eval 'return 1+1' 2>&1 || true)"
if [[ "$EVAL_OUT" == *"only supported with the lua config manager"* ]]; then
  fail "ADOPT-02 hyprctl eval refused — session is not under the Lua config manager"
else
  pass "ADOPT-02 hyprctl eval accepted, returned: ${EVAL_OUT//$'\n'/ }"
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
