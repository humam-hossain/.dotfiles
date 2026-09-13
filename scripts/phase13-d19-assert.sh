#!/usr/bin/env bash
# Phase 13 OVL-01..03 in-repo asserts (Nyquist validation).
# Non-mutating only. Never copies onto live ~/.config/hypr/custom (D-02, D-17).
#
# Also carries two checks that are not Phase 13's own subject matter but belong
# here because this is the script that already reads the D-18/D-19 fences:
#   - the arch/dots-hyprland.sh drift baseline, tiered on phase marker files;
#   - the W-3 apply-fence drift check between docs/dots-hyprland-workflow.md
#     and the 13-SOT-APPLY.md source of truth (Phase 16 D-38).
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

# Phase artifacts MOVE when a milestone is archived: completing a milestone
# relocates .planning/phases/<phase>/ to
# .planning/milestones/<version>-phases/<phase>/. v0.3 was archived after Phase
# 16, which left every hard-coded .planning/phases/ path in this script pointing
# at nothing — the extractor below died on a missing file before reaching a
# single assert. Resolve the live tree first, then the archive, so this script
# keeps reading the same artifact across an archival instead of dying on a path
# that moved. The marker-file tiers further down depend on this too: a marker
# that silently "disappears" into the archive would select the wrong baseline.
phase_artifact() {
  local rel="$1" cand
  for cand in ".planning/phases/$rel" .planning/milestones/*-phases/"$rel"; do
    if [ -f "$cand" ]; then printf '%s\n' "$cand"; return 0; fi
  done
  printf '%s\n' ".planning/phases/$rel"   # unresolved: report the canonical path
}

SOT="$(phase_artifact '13-personal-hypr-custom-overlays/13-SOT-APPLY.md')"
PLAYBOOK="docs/dots-hyprland-workflow.md"
DOC_SWEEP_16="$(phase_artifact '16-retire-the-safe-profile-full-only-wrapper-and-playbook/16-DOC-SWEEP.md')"
GENERAL=".config/hypr/custom/general.lua"
ENV=".config/hypr/custom/env.lua"
EXECS=".config/hypr/custom/execs.lua"
LIVE_CUSTOM="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom"

echo "=== Phase 13 overlay D-19 / OVL asserts (non-mutating) ==="

# --- Markdown fence extractor, parameterised over (file, heading) ---
# One extractor, three call sites: the D-19 fence that is executed below, and
# the two apply fences the W-3 drift check compares. A second extraction idiom
# (awk/sed) is deliberately NOT added -- two extractors for one job drift apart,
# and a hand-transcribed fence in this script would drift from both.
extract_fence() {
  python3 - "$1" "$2" <<'PY'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text()
idx = text.find(sys.argv[2])
if idx < 0:
    raise SystemExit(f"heading missing: {sys.argv[2]}")
rest = text[idx:]
start = rest.find("```bash")
end = rest.find("```", start + 7)
if start < 0 or end < 0:
    raise SystemExit("bash fence missing")
print(rest[start + 7:end].lstrip("\n"), end="")
PY
}

# --- D-19 fence extracted from 13-SOT-APPLY.md (not a copy of the checks) ---
# The fence body names its own SoT document by the .planning/phases/ path that
# was live when Phase 13 wrote it, and the v0.3 archival moved that document.
# The path is rewritten HERE, in the open, on the extracted text -- exactly as
# the W-3 filter below is applied in the open -- rather than by editing the
# archived document, which is frozen history under the Phase 16 precedent and is
# never edited to turn a gate green. The fence stays the single source of the
# checks; only the location of the artifact it points at is corrected. When the
# document has not been archived, $SOT equals the literal below and the
# substitution is a no-op.
SOT_LITERAL=".planning/phases/13-personal-hypr-custom-overlays/13-SOT-APPLY.md"
FENCE="$(extract_fence "$SOT" '## In-repo verify (D-19)' \
  | sed "s#${SOT_LITERAL}#${SOT}#g")"   # <- load-bearing rewrite, explained just above
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

# --- W-3: the playbook duplicates the D-18 apply fence; nothing checked the copy ---
# docs/dots-hyprland-workflow.md carries an operator-runnable copy of the
# 13-SOT-APPLY.md D-18 apply fence. The copy is COMPARED here, never executed:
# the fence touches a live configuration tree, and running both copies would
# double the side effects of one procedure. The SoT copy above is the only one
# this script executes.
# The SoT copy carries one line the playbook copy does not -- a comment
# restricting the fence to the adopt phase. That is the only difference between
# the two fences. Neither fence body is edited to make this comparison pass;
# instead the one differing line is filtered out here, in the open, because
# without the filter the check fails against two fences that already agree.
SOT_APPLY_FENCE="$(extract_fence "$SOT" '## Apply command (D-18)' \
  | grep -v '^# Phase 14 only')"   # <- load-bearing filter, explained just above
PB_APPLY_FENCE="$(extract_fence "$PLAYBOOK" '### Named files only')"

if [ -z "$SOT_APPLY_FENCE" ]; then
  fail "W-3 extract D-18 apply fence from $SOT (empty)"
elif [ -z "$PB_APPLY_FENCE" ]; then
  fail "W-3 extract apply fence from $PLAYBOOK (empty)"
elif [ "$SOT_APPLY_FENCE" = "$PB_APPLY_FENCE" ]; then
  pass "W-3 $PLAYBOOK apply fence matches the 13-SOT-APPLY.md D-18 fence"
else
  fail "W-3 $PLAYBOOK apply fence has drifted from the 13-SOT-APPLY.md D-18 fence"
  # diff exits non-zero on difference; this script runs under set -e.
  diff <(printf '%s' "$SOT_APPLY_FENCE") <(printf '%s' "$PB_APPLY_FENCE") || true
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

# execs.lua is NO LONGER an empty placeholder, and this assert was rewritten
# rather than deleted when that changed. Phase 13 asserted the slot held no Lua
# statement because at that point it held nothing and a stray statement would
# have meant the apply had invented content. Phase 17 plan 17-05 authored the
# session bootstrap into it under START-02, so the old spelling asserted the
# exact absence of the thing a later requirement demands — a check that would
# have had to be deleted to land the feature is a check that was testing the
# wrong property. What survives, and is the property actually worth fencing, is
# that the slot holds THAT ONE entry and nothing else: exactly one hl.exec_cmd,
# and it is the session bootstrap. The six workspace-pinned autostarts belong to
# START-01 in Phase 20 (D-15), so an early leak of one shows up here as a count
# greater than 1 rather than silently riding along.
EXECS_CMDS="$(grep -c 'hl\.exec_cmd' "$EXECS" 2>/dev/null || true)"
if [ -f "$EXECS" ] \
  && [ "${EXECS_CMDS:-0}" -eq 1 ] \
  && grep -Fq 'systemctl --user start hyprland-session.service' "$EXECS"; then
  pass "execs.lua holds exactly one hl.exec_cmd and it is the START-02 session bootstrap"
else
  fail "execs.lua should hold exactly the one START-02 session-bootstrap hl.exec_cmd (counted ${EXECS_CMDS:-0}) — a Phase 20 START-01 entry may have landed early, or the bootstrap line is gone"
fi

if luac -p "$EXECS" >/dev/null 2>&1; then
  pass "luac -p $EXECS"
else
  fail "luac -p $EXECS"
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
LIVE_VERIFY="$(phase_artifact '14-live-full-adopt-verify/14-LIVE-VERIFY.md')"
# Phase 17 marker. Not a phase artifact: it is a script in the live tree, so it
# does not move when a milestone is archived and needs no resolver.
PHASE17_ASSERT="scripts/phase17-unblock-assert.sh"
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
# after that phase the known-good state is 14c6828, not e7e4e9f. Phase 16 then
# rewrote the wrapper full-only, so after that phase it was 0771cc2 — and then the
# phase 16 review's C-01/H-01 fixes changed it again, so it became cfa63ad. Phase
# 17 plan 02 then added the D-09 dispatch guard and the safe_rm_path repo-
# containment clause, so it is now b32faf6. Pinning all four keeps drift detection
# live without asserting a premise the project has moved past.
#
# ORDERING IS LOAD-BEARING: the newest marker must be tested FIRST. 14-LIVE-VERIFY.md
# and 16-DOC-SWEEP.md both still exist, so a branch placed after their tests would
# never fire.
#
# git diff <BASE> -- <path> compares BASE against the WORKING TREE, not HEAD. So
# each pin names a commit whose blob is byte-identical to the working tree at the
# time it was written, and no later plan may touch arch/dots-hyprland.sh without
# re-pinning here.
if [ -f "$PHASE17_ASSERT" ]; then
  WRAPPER_BASE="b32faf6"   # fix(17-02): safe_rm_path refuses any target resolving inside the repo
elif [ -f "$DOC_SWEEP_16" ]; then
  WRAPPER_BASE="cfa63ad"   # fix(16): close C-01/H-01 from the phase 16 review
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
