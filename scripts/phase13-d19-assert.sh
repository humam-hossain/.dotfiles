#!/usr/bin/env bash
# Phase 13 OVL-01..03 in-repo asserts (Nyquist validation).
# Non-mutating only. Never copies onto live ~/.config/hypr/custom (D-02, D-17).
#
# Usage (from REPO_ROOT):
#   ./scripts/phase13-d19-assert.sh
# Exit 0 if all hard asserts pass; non-zero if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

SOT=".planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md"
GENERAL=".config/hypr/custom/general.lua"
ENV=".config/hypr/custom/env.lua"
EXECS=".config/hypr/custom/execs.lua"
LIVE_CUSTOM="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom"

echo "=== Phase 13 overlay D-19 / OVL asserts (non-mutating) ==="

# --- D-19 fence extracted from 13-SOT-APPLY.md (not a copy of the checks) ---
FENCE="$(python3 - "$SOT" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text()
idx = text.find("## In-repo verify (D-19)")
if idx < 0:
    raise SystemExit("D-19 heading missing")
rest = text[idx:]
start = rest.find("```bash")
end = rest.find("```", start + 7)
if start < 0 or end < 0:
    raise SystemExit("D-19 bash fence missing")
print(rest[start + 7:end].lstrip("\n"), end="")
PY
)"
if [ -z "$FENCE" ]; then
  fail "extract D-19 fence from $SOT"
else
  TMP="$(mktemp /tmp/p13-d19-XXXXXX.sh)"
  printf '%s' "$FENCE" >"$TMP"
  if bash -e "$TMP"; then
    pass "D-19 fence bash -e (extracted from 13-SOT-APPLY.md)"
  else
    fail "D-19 fence bash -e (extracted from 13-SOT-APPLY.md)"
  fi
  rm -f "$TMP"
fi

# --- extra OVL checks not all in the D-19 fence ---
if [ -s "$GENERAL" ] && [ "$(grep -c 'hl.monitor' "$GENERAL")" -eq 2 ] && [ "$(grep -c 'hl.workspace_rule' "$GENERAL")" -eq 11 ]; then
  pass "general.lua hl.monitor==2 hl.workspace_rule==11"
else
  fail "general.lua hl.monitor==2 hl.workspace_rule==11"
fi

if luac -p "$GENERAL" >/dev/null 2>&1; then
  pass "luac -p $GENERAL"
else
  fail "luac -p $GENERAL"
fi

no_lua_stmts() {
  local f="$1"
  [ -f "$f" ] || return 1
  ! grep -vE '^[[:space:]]*$|^[[:space:]]*--' "$f" | grep -q .
}

if no_lua_stmts "$ENV"; then
  pass "env.lua exists with no Lua statements (test -f)"
else
  fail "env.lua exists with no Lua statements (test -f)"
fi

if no_lua_stmts "$EXECS"; then
  pass "execs.lua exists with no Lua statements (test -f)"
else
  fail "execs.lua exists with no Lua statements (test -f)"
fi

if grep -q 'cp -a' "$SOT" && grep -Eiq 'fail' "$SOT" && grep -Eiq 'warn' "$SOT" && grep -q 'rsync --delete' "$SOT"; then
  pass "13-SOT-APPLY.md names cp -a / fail / warn / rsync --delete"
else
  fail "13-SOT-APPLY.md names cp -a / fail / warn / rsync --delete"
fi

# Phase 13 never applied the overlay itself; Phase 14 did, under the D-18 fence.
# Before that apply the live tree must be absent. After it, the three named files
# must match the repo source byte for byte, and the files the fence deliberately
# leaves to upstream must not have been copied over.
LIVE_VERIFY=".planning/phases/14-live-full-adopt-verify/14-LIVE-VERIFY.md"
if [ ! -f "$LIVE_VERIFY" ]; then
  if [ ! -e "$LIVE_CUSTOM" ]; then
    pass "live $LIVE_CUSTOM absent (apply not run)"
  else
    fail "live $LIVE_CUSTOM absent (apply not run)"
  fi
else
  if [ -d "$LIVE_CUSTOM" ]; then
    pass "live $LIVE_CUSTOM present (phase 14 apply recorded)"
  else
    fail "live $LIVE_CUSTOM present (phase 14 apply recorded)"
  fi
  for f in general.lua env.lua execs.lua; do
    if [ -f ".config/hypr/custom/$f" ] && [ -f "$LIVE_CUSTOM/$f" ] \
      && cmp -s ".config/hypr/custom/$f" "$LIVE_CUSTOM/$f"; then
      pass "live custom/$f matches repo source"
    else
      fail "live custom/$f matches repo source"
    fi
  done
  # D-18 leaves these three to upstream. A repo copy landing on them means the
  # fence was widened past the named files.
  for f in keybinds.lua rules.lua variables.lua; do
    if [ ! -f ".config/hypr/custom/$f" ] || ! cmp -s ".config/hypr/custom/$f" "$LIVE_CUSTOM/$f"; then
      pass "live custom/$f left to upstream (not overwritten from repo)"
    else
      fail "live custom/$f left to upstream (not overwritten from repo)"
    fi
  done
fi

if [ "$(realpath -m .config/hypr/custom)" != "$(realpath -m "$LIVE_CUSTOM")" ]; then
  pass "worktree custom/ realpath != live custom"
else
  fail "worktree custom/ realpath != live custom"
fi

if [ -z "$(git diff --name-only -- arch/dots-hyprland.sh)" ]; then
  pass "arch/dots-hyprland.sh unmodified"
else
  fail "arch/dots-hyprland.sh unmodified"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "=== Phase 13 asserts: FAIL=0 ==="
  exit 0
fi
echo "=== Phase 13 asserts: FAIL=$FAIL ==="
exit 1
