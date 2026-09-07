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
DOC_SWEEP16=".planning/phases/16-retire-the-safe-profile-full-only-wrapper-and-playbook/16-DOC-SWEEP.md"
PLAYBOOK="docs/dots-hyprland-workflow.md"

# $1 = markdown file, $2 = heading whose first ```bash fence to extract.
extract_fence() {
  python3 - "$1" "$2" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text()
idx = text.find(sys.argv[2])
if idx < 0:
    raise SystemExit("heading missing: " + sys.argv[2])
rest = text[idx:]
start = rest.find("```bash")
end = rest.find("```", start + 7)
if start < 0 or end < 0:
    raise SystemExit("bash fence missing")
print(rest[start + 7:end].lstrip("\n"), end="")
PY
}

echo "=== Phase 13 overlay D-19 / OVL asserts (non-mutating) ==="

# --- D-19 fence extracted from 13-SOT-APPLY.md (not a copy of the checks) ---
FENCE="$(extract_fence "$SOT" '## In-repo verify (D-19)')"
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

# --- W-3: playbook §6 duplicates the D-18 apply fence; compare, do not execute ---
SOT_APPLY="$(extract_fence "$SOT" '## Apply command (D-18)' || true)"
PB_FENCE="$(extract_fence "$PLAYBOOK" '### Named files only' || true)"
if [ -z "$SOT_APPLY" ]; then
  fail "W-3 extract apply fence from $SOT"
elif [ -z "$PB_FENCE" ]; then
  fail "W-3 extract apply fence from $PLAYBOOK"
else
  # Load-bearing filter: the only difference between the two fences is the SoT's
  # adopt-phase-only comment. Drop that one expected line; do not edit either fence body.
  SOT_FENCE="$(printf '%s\n' "$SOT_APPLY" | grep -v '^# Phase 14 only')"
  if [ "$SOT_FENCE" = "$PB_FENCE" ]; then
    pass "W-3 playbook §6 apply fence matches 13-SOT-APPLY.md D-18 fence"
  else
    fail "W-3 playbook §6 apply fence has drifted from 13-SOT-APPLY.md D-18 fence"
    diff <(printf '%s' "$SOT_FENCE") <(printf '%s' "$PB_FENCE") || true
  fi
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
  # D-18 leaves these three to upstream. The repo carries no copy of them at all,
  # so "the repo copy did not land" is unobservable here -- asserting it would
  # print PASS for a condition never checked. What IS observable, and is the real
  # D-18 property, is that the repo never grew a copy to widen the fence with.
  for f in keybinds.lua rules.lua variables.lua; do
    if [ ! -e ".config/hypr/custom/$f" ]; then
      pass "repo has no custom/$f — D-18 fence cannot widen to it"
    elif ! cmp -s ".config/hypr/custom/$f" "$LIVE_CUSTOM/$f"; then
      pass "repo custom/$f exists but live copy differs (not applied)"
    else
      fail "live custom/$f is byte-identical to a repo copy — D-18 fence widened past its named files"
    fi
  done
fi

if [ "$(realpath -m .config/hypr/custom)" != "$(realpath -m "$LIVE_CUSTOM")" ]; then
  pass "worktree custom/ realpath != live custom"
else
  fail "worktree custom/ realpath != live custom"
fi

# Bare `git diff` compares worktree against index only, so a committed change is
# invisible to it -- arch/dots-hyprland.sh was modified during phase 14 and still
# passed this check. Compare against a pinned known-good commit instead.
#
# Which commit is the baseline is phase-dependent. Phase 13 wanted the wrapper
# untouched since phase 12. Phase 14 then changed it deliberately under D-28, so
# after that phase the known-good state is 14c6828, not e7e4e9f. Pinning both
# keeps drift detection live without asserting a premise the project has moved past.
if [ -f "$DOC_SWEEP16" ]; then
  WRAPPER_BASE="0771cc2"   # docs(16-02): rewrite wrapper usage to the surviving surface
elif [ -f "$LIVE_VERIFY" ]; then
  WRAPPER_BASE="14c6828"   # refactor(14-01): drop waybar and swaync from PROTECT_EXPLICIT (D-28)
else
  WRAPPER_BASE="e7e4e9f"   # feat(12-03): last phase-12 state of the wrapper
fi
if ! git cat-file -e "${WRAPPER_BASE}^{commit}" 2>/dev/null; then
  printf '[INFO] %s\n' "arch/dots-hyprland.sh: baseline $WRAPPER_BASE not in this repo; drift not checked"
elif [ -z "$(git diff --name-only "$WRAPPER_BASE" -- arch/dots-hyprland.sh)" ]; then
  pass "arch/dots-hyprland.sh unmodified since $WRAPPER_BASE"
else
  fail "arch/dots-hyprland.sh changed since $WRAPPER_BASE"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "=== Phase 13 asserts: FAIL=0 ==="
  exit 0
fi
echo "=== Phase 13 asserts: FAIL=$FAIL ==="
exit 1
