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

# --- vacuity guard for the criterion 1a / 1d ban greps ---------------------
# A ban-grep over a missing directory, or over a directory holding none of the
# files it means to police, passes while observing nothing. Both scoped trees
# are asserted present and non-empty before either ban runs.
ARCH_SH_COUNT="$(find arch -maxdepth 1 -type f -name '*.sh' | wc -l || true)"
DOCS_MD_COUNT="$(find docs -type f -name '*.md' | wc -l || true)"
if [[ -d arch && "$ARCH_SH_COUNT" -gt 0 ]]; then
  pass "1a guard: arch/ exists and holds $ARCH_SH_COUNT *.sh files (the ban below cannot pass vacuously)"
else
  fail "1a guard: arch/ is missing or holds no *.sh file — the ban-grep would pass over nothing"
  ls -la arch 2>&1 || true
fi
if [[ -d docs && "$DOCS_MD_COUNT" -gt 0 ]]; then
  pass "1d guard: docs/ exists and holds $DOCS_MD_COUNT *.md files (the ban below cannot pass vacuously)"
else
  fail "1d guard: docs/ is missing or holds no *.md file — the ban-grep would pass over nothing"
  ls -la docs 2>&1 || true
fi

# --- criterion 1a / FIX-01 + CAP-04: the invalid spelling survives nowhere ---
# Scoped by EXPLICIT path list to arch/ and docs/, never recursed from the repo
# root. The same string lives in .planning/research/PITFALLS.md, a frozen
# research artifact that is history under the Phase 16 precedent and must not
# be edited to turn this grep green.
if grep -rn -- '-v=5' arch/ docs/ >/dev/null 2>&1; then
  fail "1a the invalid short-verbosity spelling still survives under arch/ or docs/"
  grep -rn -- '-v=5' arch/ docs/ || true
else
  pass "1a the invalid short-verbosity spelling survives at zero sites under arch/ and docs/"
fi

# --- criterion 1b / FIX-01: all 15 arch/ call sites carry the valid pair ----
# A counted grep, not a ban: the fixed flag order (--verbose=5 then
# --no-folding) at every site is what makes a single literal count a complete
# audit of all 15 sites. arch/hyprland.sh holds two of them.
PAIR_COUNT="$(grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l || true)"
if [[ "$PAIR_COUNT" -eq 15 ]]; then
  pass "1b all 15 arch/ stow call sites carry the literal --verbose=5 --no-folding"
else
  fail "1b expected 15 arch/ sites carrying --verbose=5 --no-folding, counted $PAIR_COUNT"
  grep -rn -- '--verbose=5 --no-folding' arch/*.sh || true
  grep -rn 'stow ' arch/*.sh || true
fi

# --- criterion 1d / CAP-04: the operator doc is a named claim ---------------
# 1a already covers docs/ as part of its path list. This re-asserts the same
# ban scoped to docs/ alone so the operator-doc scope of CAP-04 is an explicit
# claim rather than a side effect of the wider grep — the 16th invocation (the
# documented kitty re-stow recovery command) is copy-pasteable and exited 1.
if grep -rn -- '-v=5' docs/ >/dev/null 2>&1; then
  fail "1d the operator docs still carry the invalid short-verbosity spelling"
  grep -rn -- '-v=5' docs/ || true
else
  pass "1d docs/ carries zero invalid stow invocations (CAP-04 operator-doc scope)"
fi

# --- criterion 1c / FIX-01: the edited installer scripts still parse --------
# `bash -n` passed on all 14 files before the sweep, so this is a regression
# guard on the edit rather than a currently-failing check. The guard in front
# of the loop asserts every path still exists: a renamed or deleted file would
# otherwise shrink the loop silently and let it pass over less than it claims.
SYNTAX_FILES=(
  arch/alacritty.sh
  arch/btop.sh
  arch/define.sh
  arch/fish.sh
  arch/hyprland.sh
  arch/kitty.sh
  arch/nvim.sh
  arch/rofi.sh
  arch/tmux.sh
  arch/wezterm.sh
  arch/xterm.sh
  arch/yazi.sh
  arch/zsh.sh
  arch/zsh_powerlevel.sh
)
SYNTAX_MISSING=0
for f in "${SYNTAX_FILES[@]}"; do
  [[ -f "$f" ]] || { SYNTAX_MISSING=$((SYNTAX_MISSING + 1)); printf '  missing: %s\n' "$f"; }
done
if [[ "${#SYNTAX_FILES[@]}" -eq 14 && "$SYNTAX_MISSING" -eq 0 ]]; then
  pass "1c guard: all 14 files holding a stow call site are present (the syntax loop cannot shrink silently)"
else
  fail "1c guard: expected 14 present call-site files, list holds ${#SYNTAX_FILES[@]} with $SYNTAX_MISSING missing"
fi
for f in "${SYNTAX_FILES[@]}"; do
  if bash -n "$f" 2>/dev/null; then
    pass "1c syntax: bash -n $f"
  else
    fail "1c syntax: bash -n $f"
    bash -n "$f" || true
  fi
done

# =============================================================================
# D-02 folding audit — READ-ONLY, [INFO] only, never [PASS]/[FAIL].
#
# This section deliberately asserts nothing. `--no-folding` governs NEW stow
# runs only, so the directories that folded before this phase stay folded and
# this phase does not unfold one. The audit exists to produce a live record
# rather than a note frozen into a research artifact, and Phase 18 — which owns
# the tree taxonomy — inherits that list and decides what each folded directory
# becomes. Unfolding later is a `stow -D` plus a re-stow with --no-folding.
#
# Non-mutating by construction: the section runs `find`, `readlink` and a `-d`
# test. It invokes no stow, and removes, moves or links nothing. (The `-lname`
# predicate below is a find test, not the link-creating command it echoes.)
# =============================================================================
echo "=== Phase 17 D-02 folding audit (read-only, [INFO] only) ==="

FOLDED_COUNT=0
while IFS= read -r LINKPATH; do
  [[ -n "$LINKPATH" ]] || continue
  if [[ -d "$LINKPATH" ]]; then
    FOLDED_COUNT=$((FOLDED_COUNT + 1))
    info "D-02 folded directory symlink: $LINKPATH -> $(readlink "$LINKPATH")"
  fi
done < <(find "$HOME/.config" -maxdepth 2 -type l -lname '*.dotfiles*' 2>/dev/null | sort)

info "D-02 audit complete: $FOLDED_COUNT folded stow directory symlink(s) under \$HOME/.config. Phase 17 does not unfold them — --no-folding governs new runs only. Phase 18 owns the tree taxonomy that decides what each folded directory becomes."

echo "=== done: FAIL=${FAIL} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
