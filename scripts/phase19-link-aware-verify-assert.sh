#!/usr/bin/env bash
# Phase 19 link-aware verify asserts (D-57).
# One script, one section per ROADMAP criterion, one verdict for the phase.
# Filename slug matches the phase directory and the roadmap title exactly (D-39).
#
# Usage (from REPO_ROOT):
#   ./scripts/phase19-link-aware-verify-assert.sh
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.
#
# Constraints (Phase 19):
#   - DESTRUCTIVE BY CONSTRUCTION, and scoped by construction rather than by a
#     gate (D-25). VER-04 runs `rsync -a --delete` for real, over a stowed
#     fixture, on every invocation. Everything it can reach lives under one
#     per-run `mktemp -d`; the real $HOME and the real repo tree are never
#     candidate targets.
#   - The only thing standing between that command and a real directory is
#     guard_scratch_target(), which resolves its argument at call time and
#     fails closed. It reads nothing the code under test produces and calls
#     nothing the code under test defines. STATE.md records this repo deleting
#     its own README.md, stow/ tree and vendored submodule exactly once,
#     because a harness assumed the guard it was testing was correct.
#   - Fixtures live under `mktemp`/`mktemp -d` outside the repo and are removed
#     by an EXIT trap set immediately after creation and before the first write
#     into them (D-30).
#   - Contract (D-49): FOUR prefixes [PASS] [FAIL] [FINDING] [INFO] and TWO
#     counters, copied from scripts/phase14-verify.sh:24-41 by way of
#     scripts/phase18-capture-model-assert.sh. Counters are UPPERCASE here and
#     lowercase inside run_verify(); that asymmetry is the existing convention.
#     Deliberately NOT shaped after scripts/phase17-unblock-assert.sh, which
#     uses the other contract (three prefixes, one counter, a different summary
#     line).
#   - No total line count is asserted anywhere. [INFO] volume moves with the
#     operator's uncommitted edits and with whatever installer backup files the
#     last install left; the FAIL=n FINDINGS=n counters are stable because
#     [INFO] cannot move them (D-13).
#
# Output levels:
#   [PASS]     hard condition satisfied
#   [FAIL]     hard condition violated -- moves the exit code
#   [FINDING]  observed condition recorded; FINDINGS never move the exit code
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

# ---------------------------------------------------------------------------
# Fixtures. Every one of them lives outside the repo. The EXIT trap is
# installed immediately after the last mktemp below, and re-installed inside
# build_fixture() on the line immediately after each `mktemp -d`, before the
# first write into it (D-30).
# ---------------------------------------------------------------------------
OUT="$(mktemp /tmp/p19-out-XXXXXX)"
ERR="$(mktemp /tmp/p19-err-XXXXXX)"
GOUT="$(mktemp /tmp/p19-gout-XXXXXX)"
GERR="$(mktemp /tmp/p19-gerr-XXXXXX)"
PORCELAIN_BEFORE="$(mktemp /tmp/p19-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p19-porcelain-after-XXXXXX)"
SCRATCH_ROOTS=()
T=""
T_REAL=""
RUN_REPO=""
RUN_HOME=""
BARE_REPO=""
rc=0

cleanup() {
  rm -f "$OUT" "$ERR" "$GOUT" "$GERR" "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" 2>/dev/null || true
  local root
  for root in ${SCRATCH_ROOTS[@]+"${SCRATCH_ROOTS[@]}"}; do
    [[ -n "$root" ]] && rm -rf "$root" 2>/dev/null || true
  done
  return 0
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Porcelain bracket (D-38).
#
# The --ignored form, NOT the plain one. .gitignore's deliberately slash-free
# `kdeglobals` pattern is unanchored, so it also matches the DIRECTORY
# restow/kdeglobals/ -- a plain bracket is blind in exactly the package a Qt
# application is most likely to write through (RESEARCH Pitfall 4). The known
# build-artifact prefixes are filtered here rather than by widening the
# pattern: .gitignore's generated-theme block explicitly forbids rewriting it
# and D-41 forbids contradicting that prose.
# ---------------------------------------------------------------------------
porcelain_snapshot() {
  git status --porcelain --ignored \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

porcelain_snapshot > "$PORCELAIN_BEFORE"

echo "=== Phase 19 link-aware verify (VER-03 / VER-04) ==="

# ---------------------------------------------------------------------------
# Binary guard (D-31). An absence is a [FAIL] naming the binary, never an
# [INFO] and never a skipped section -- an unprovable claim is a failed claim.
# This is distinct from `verify` itself, which needs neither of these.
# ---------------------------------------------------------------------------
REQUIRED_MISSING=0
for BIN in stow rsync; do
  if command -v "$BIN" >/dev/null 2>/dev/null; then
    pass "0 required binary present: $BIN ($(command -v "$BIN"))"
  else
    fail "0 required binary missing: $BIN -- the VER-04 destruction section cannot prove anything without it"
    REQUIRED_MISSING=$((REQUIRED_MISSING + 1))
  fi
done

# ---------------------------------------------------------------------------
# build_fixture (D-24) -- sets the globals T and T_REAL.
#
# ONE `mktemp -d` root holding repo/ and home/ as SIBLINGS. GNU Stow computes
# the shortest relative path from target to stow directory and therefore emits
# RELATIVE links; a single root keeps that chain short and leaves the D-26
# guard with exactly one prefix to check (RESEARCH Pitfall 2).
#
# The scratch repo is `git init`ed and committed (D-28) so D-21's repo-vs-HEAD
# code path later runs against a real HEAD. Fixture content is authored LF-only
# so the repo's `* text=auto eol=lf` attribute cannot change a verdict.
# ---------------------------------------------------------------------------
build_fixture() {
  T="$(mktemp -d /tmp/p19-fixture-XXXXXX)"
  SCRATCH_ROOTS+=("$T"); trap cleanup EXIT   # D-30: before the first write
  T_REAL="$(realpath -- "$T")"               # D-26: captured at setup

  mkdir -p "$T/repo/arch" "$T/repo/stow/fixture/.config/fixpkg" "$T/home/.config/fixpkg"
  cp -- "$REPO_ROOT/arch/dots-hyprland.sh" "$T/repo/arch/dots-hyprland.sh"
  chmod +x "$T/repo/arch/dots-hyprland.sh"
  printf 'v1\n' > "$T/repo/stow/fixture/.config/fixpkg/conf"

  git -c init.defaultBranch=main init -q "$T/repo"
  git -C "$T/repo" config user.name "GSD Assert"
  git -C "$T/repo" config user.email "assert@local"
  git -C "$T/repo" add -A
  git -C "$T/repo" -c commit.gpgsign=false commit -q -m "fixture initial state"

  ( cd "$T/repo/stow" && stow --no-folding -t "$T/home" fixture )

  # The runner's two roots, so the precondition cases in Section 2 can vary one
  # of them at a time without a second copy of the runner.
  RUN_REPO="$T/repo"
  RUN_HOME="$T/home"
}

# ---------------------------------------------------------------------------
# build_bare_repo -- the fixture builder's scratch-repo mechanics ONLY: a
# `git init`ed repo holding nothing but the copied wrapper, so the single
# variable against build_fixture is the absence of stow/ and restow/.
# Sets the global BARE_REPO.
# ---------------------------------------------------------------------------
build_bare_repo() {
  local root
  root="$(mktemp -d /tmp/p19-bare-XXXXXX)"
  SCRATCH_ROOTS+=("$root"); trap cleanup EXIT   # D-30: before the first write

  mkdir -p "$root/repo/arch"
  cp -- "$REPO_ROOT/arch/dots-hyprland.sh" "$root/repo/arch/dots-hyprland.sh"
  chmod +x "$root/repo/arch/dots-hyprland.sh"

  git -c init.defaultBranch=main init -q "$root/repo"
  git -C "$root/repo" config user.name "GSD Assert"
  git -C "$root/repo" config user.email "assert@local"
  git -C "$root/repo" add -A
  git -C "$root/repo" -c commit.gpgsign=false commit -q -m "bare fixture: wrapper only, no stow/ or restow/"

  BARE_REPO="$root/repo"
}

# ---------------------------------------------------------------------------
# run_fixture_verify (D-37) -- sets the global rc; captures into OUT and ERR.
#
# All THREE roots must be satisfied at once, because REPO_ROOT comes from the
# copied script's own BASH_SOURCE and main_root comes from `git rev-parse` run
# in the caller's cwd, and NEITHER follows $HOME (RESEARCH Pitfall 1):
#   1. HOME points at the scratch home
#   2. the wrapper invoked is the copy inside the scratch repo
#   3. the invocation's cwd is that scratch repo
#
# Symptoms of a mis-wired harness, as opposed to a real defect in the code
# under test: a FAIL count near 94 on a fixture that stages one file, and a
# [FAIL] line reading `(expected )` with nothing after `expected`.
#
# stdout and stderr are kept in two SEPARATE files and never merged into one
# stream -- that separation is the only thing that proves an exit-2 reason
# landed on fd 2 and that the summary line appeared in neither stream.
# ---------------------------------------------------------------------------
run_fixture_verify() {
  rc=0
  ( cd "$RUN_REPO" && HOME="$RUN_HOME" ./arch/dots-hyprland.sh verify "$@" ) >"$OUT" 2>"$ERR" || rc=$?
}

# ---------------------------------------------------------------------------
# guard_scratch_target (D-26) -- the ONLY gate on `rsync -a --delete`.
#
# Takes the path about to be destroyed as $1 and reads $T_REAL from the
# enclosing scope. Resolves its argument at CALL TIME with realpath and fails
# closed: an unresolvable or empty result, or an empty $T_REAL, is a refusal,
# never a pass. It `return`s and never `exit`s, so its refusal can be captured
# and asserted by the probe below.
#
# Its refusal is a bare `echo ... >&2` and is deliberately NOT routed through
# fail(): fail() increments the FAIL counter, and the probe below expects two
# refusals, so routing them through it would end an entirely correct run at
# FAIL=2 and exit 1. A refusal the harness asked for is not a harness failure.
#
# It performs no destruction of any kind -- `rsync` appears only at its call
# site and never inside it, which is precisely what makes it safe to point at
# real paths in the probe below.
# ---------------------------------------------------------------------------
guard_scratch_target() {
  local candidate="${1:-}"
  local resolved
  local root="${T_REAL:-}"

  if [[ -z "$root" ]]; then
    echo "[FAIL] guard refusing destruction: resolved scratch root is empty (candidate=${candidate:-<empty>})" >&2
    return 1
  fi
  if [[ -z "$candidate" ]]; then
    echo "[FAIL] guard refusing destruction: empty target (resolved scratch root $root)" >&2
    return 1
  fi
  resolved="$(realpath -- "$candidate" 2>/dev/null || true)"
  if [[ -z "$resolved" ]]; then
    echo "[FAIL] guard refusing destruction: target did not resolve: $candidate (resolved scratch root $root)" >&2
    return 1
  fi
  case "$resolved" in
    "$root"/*)
      return 0
      ;;
  esac
  echo "[FAIL] guard refusing rsync --delete: resolved target $resolved is not under resolved scratch root $root" >&2
  return 1
}

# =============================================================================
# Section 1 / ROADMAP criterion 4 -- VER-04: the rsync-replace class and its
# negative control (D-29). Only the destructive command varies between the two
# runs; the fixture builder is shared.
# =============================================================================
echo "=== Section 1 / ROADMAP criterion 4: VER-04 rsync-replace class and negative control ==="

build_fixture
LIVE_PATH="$T/home/.config/fixpkg/conf"

# --- negative control: the identical run WITHOUT the rsync ------------------
run_fixture_verify
if [[ "$rc" -eq 0 ]]; then
  pass "1 negative control: verify over the intact fixture exits 0 (rc=$rc)"
else
  fail "1 negative control: verify over the intact fixture exited $rc, expected 0"
  sed 's/^/       /' < "$OUT" >&2 || true
  sed 's/^/       /' < "$ERR" >&2 || true
fi

if grep -q -F -- "$LIVE_PATH" "$OUT" && grep '^\[PASS\]' "$OUT" | grep -q -F -- "$LIVE_PATH"; then
  pass "1 negative control: the stowed live path appears on a [PASS] line: $LIVE_PATH"
else
  fail "1 negative control: $LIVE_PATH is absent from any [PASS] line -- harness may be walking the real tree (RESEARCH Pitfall 1)"
  sed 's/^/       /' < "$OUT" >&2 || true
fi

# --- D-26 guard refusal probe, three cases ----------------------------------
# These three cases are the only thing separating a guard that is PRESENT from
# a guard that WORKS. A wrong `case` glob, a comparison against the unresolved
# argument, or a $T_REAL left empty by a failed realpath all leave a
# source-grep fully satisfied while `rsync -a --delete` runs against whatever
# it was handed.
#
# Both refusal candidates are real, existing, precious paths, chosen BECAUSE
# they exist: realpath without -m fails on an absent path, so a nonexistent
# probe path would exercise the fail-closed arm instead of the prefix-mismatch
# arm and prove the weaker thing.
VICTIM="$T/home/.config/fixpkg"

for CANDIDATE in "$HOME/.config" "$REPO_ROOT/stow"; do
  CANDIDATE_REAL="$(realpath -- "$CANDIDATE" 2>/dev/null || true)"
  if [[ -z "$CANDIDATE_REAL" ]]; then
    fail "1 D-26 guard probe: candidate $CANDIDATE does not resolve -- the probe would exercise the fail-closed arm instead of the prefix-mismatch arm"
    continue
  fi
  rc=0
  ( guard_scratch_target "$CANDIDATE" ) >"$GOUT" 2>"$GERR" || rc=$?
  if [[ "$rc" -ne 0 ]] \
     && grep -q '^\[FAIL\]' "$GERR" \
     && grep -q -F -- "$CANDIDATE_REAL" "$GERR" \
     && grep -q -F -- "$T_REAL" "$GERR"; then
    pass "1 D-26 guard refuses the out-of-scratch target $CANDIDATE_REAL (rc=$rc; its [FAIL] names both the resolved target and the resolved scratch root)"
  else
    fail "1 D-26 guard did NOT refuse $CANDIDATE_REAL as required (rc=$rc) -- destruction is not actually bounded"
    sed 's/^/       /' < "$GERR" >&2 || true
  fi
done

rc=0
( guard_scratch_target "$VICTIM" ) >"$GOUT" 2>"$GERR" || rc=$?
if [[ "$rc" -eq 0 ]]; then
  pass "1 D-26 guard admits the in-scratch fixture target $VICTIM (rc=$rc) -- the guard discriminates rather than refusing everything"
else
  fail "1 D-26 guard refused the in-scratch fixture target $VICTIM (rc=$rc) -- it refuses everything and proves nothing"
  sed 's/^/       /' < "$GERR" >&2 || true
fi

# --- the destruction --------------------------------------------------------
mkdir -p "$T/vendor/fixpkg"
printf 'vendorcontent\n' > "$T/vendor/fixpkg/conf"

guard_scratch_target "$VICTIM" || exit 1
rsync -a --delete "$T/vendor/fixpkg/" "$VICTIM/"

run_fixture_verify
if [[ "$rc" -eq 1 ]]; then
  pass "1 VER-04: verify exits 1 after rsync -a --delete replaced the stowed link (rc=$rc)"
else
  fail "1 VER-04: verify exited $rc after the rsync, expected 1 -- a destroyed symlink is not a loud failure"
  sed 's/^/       /' < "$OUT" >&2 || true
fi

FAIL_LINE="$(grep '^\[FAIL\]' "$OUT" | grep -F -- "$LIVE_PATH" | head -1 || true)"
if [[ -n "$FAIL_LINE" ]] \
   && printf '%s\n' "$FAIL_LINE" | grep -q -F -- 'stow -t' \
   && printf '%s\n' "$FAIL_LINE" | grep -q -F -- 'fixture'; then
  pass "1 VER-04 / D-33: the [FAIL] names the path and carries a stow -t recovery invocation naming the fixture package"
else
  fail "1 VER-04 / D-33: no [FAIL] line names $LIVE_PATH together with a stow -t recovery invocation naming the package"
  sed 's/^/       /' < "$OUT" >&2 || true
fi

# =============================================================================
# Section 2 / ROADMAP criterion 3 -- the exit-code contract and the closed flag
# surface (D-12, D-15, D-17, D-19, D-37).
# =============================================================================
echo "=== Section 2 / ROADMAP criterion 3: exit-code contract and closed flag surface ==="

build_fixture

# --- accepted surface, enumerated LITERALLY and exhaustively (D-19) ---------
# A closed surface is what makes D-15 meaningful, so the accepted set is spelled
# out here rather than sampled.
for ACCEPTED in --strict --quiet; do
  run_fixture_verify "$ACCEPTED"
  if [[ "$rc" -eq 0 ]]; then
    pass "2 accepted flag $ACCEPTED exits 0 over a clean fixture (rc=$rc)"
  else
    fail "2 accepted flag $ACCEPTED exited $rc over a clean fixture, expected 0"
    sed 's/^/       /' < "$ERR" >&2 || true
  fi
done

for HELP_FLAG in -h --help; do
  run_fixture_verify "$HELP_FLAG"
  if [[ "$rc" -eq 0 ]] && grep -q -F -- 'thin wrapper for vendor/dots-hyprland' "$OUT"; then
    pass "2 accepted flag $HELP_FLAG exits 0 and prints the usage text (rc=$rc)"
  else
    fail "2 accepted flag $HELP_FLAG exited $rc or did not print the usage text"
    sed 's/^/       /' < "$ERR" >&2 || true
  fi
done

# --- rejected surface (D-15, D-17, D-37) ------------------------------------
# The two captures stay in SEPARATE files for every one of these calls. That
# separation is the only thing that proves the reason landed on fd 2 and that
# the `=== done:` line -- which asserts a completed verdict -- was never emitted
# on either stream.
for REJECTED in --nonexistent-flag --json -x extraword; do
  run_fixture_verify "$REJECTED"
  REJ_OK=1
  [[ "$rc" -eq 2 ]] || REJ_OK=0
  grep -q -F -- "$REJECTED" "$ERR" || REJ_OK=0
  grep -q -F -- '=== done:' "$OUT" && REJ_OK=0
  grep -q -F -- '=== done:' "$ERR" && REJ_OK=0
  if [[ "$REJ_OK" -eq 1 ]]; then
    pass "2 rejected argument $REJECTED exits 2, names the token on fd 2, and emits the summary line on neither stream (rc=$rc)"
  else
    fail "2 rejected argument $REJECTED did not meet the exit-2 contract (rc=$rc, expected 2; token on fd 2; no === done: in either stream)"
    sed 's/^/       /' < "$OUT" >&2 || true
    sed 's/^/       /' < "$ERR" >&2 || true
  fi
done

# --- precondition exit-2 cases (D-12) ---------------------------------------
# D-12's rule is POSITIONAL, not semantic: everything decided before the walk
# starts is exit 2, and everything discovered DURING the walk -- an unreadable
# directory included -- is exit 1. The unreadable-directory half of that pair is
# proven in plan 19-03, once the live-side sweep that can encounter one exists;
# it is named here as the section that owes it rather than left unstated.

HOME_AS_FILE="$T/home-is-a-regular-file"
printf 'not a directory\n' > "$HOME_AS_FILE"
build_bare_repo

PRE_LABELS=("empty HOME" "HOME naming a regular file" "repo with neither stow/ nor restow/")
PRE_REPOS=("$T/repo" "$T/repo" "$BARE_REPO")
PRE_HOMES=("" "$HOME_AS_FILE" "$T/home")

for PRE_I in 0 1 2; do
  RUN_REPO="${PRE_REPOS[$PRE_I]}"
  RUN_HOME="${PRE_HOMES[$PRE_I]}"
  run_fixture_verify
  if [[ "$rc" -eq 2 ]] && grep -q -- '^\[FAIL\] precondition:' "$ERR"; then
    pass "2 precondition (${PRE_LABELS[$PRE_I]}) exits 2 with a named reason on fd 2 (rc=$rc)"
  else
    fail "2 precondition (${PRE_LABELS[$PRE_I]}) exited $rc without a '[FAIL] precondition:' line on fd 2, expected 2"
    sed 's/^/       /' < "$ERR" >&2 || true
  fi
done

RUN_REPO="$T/repo"
RUN_HOME="$T/home"

# --- the one case this entry point cannot reach, named rather than skipped ---
info "2 a fully UNSET HOME cannot be exercised through this entry point: the wrapper dereferences \$HOME at file scope to default XDG_CONFIG_HOME under set -u, so the process dies before dispatch and never reaches the precondition block. The two reachable exit-2 HOME forms are an empty HOME and a HOME naming a non-directory, and both are asserted above (scripts/phase14-verify.sh:10-14 applied to this assert itself)."

# =============================================================================
# Closing self-check -- this script mutates nothing outside its own scratch.
# =============================================================================
echo "=== Closing self-check: working tree unchanged ==="

porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "self-check: git status --porcelain --ignored is identical before and after this run"
else
  fail "self-check: git status --porcelain --ignored changed during this run -- something here mutated the working tree"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

FIXTURE_LEAK=0
for FIXTURE in "$OUT" "$ERR" "$GOUT" "$GERR" "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" \
               ${SCRATCH_ROOTS[@]+"${SCRATCH_ROOTS[@]}"}; do
  [[ -z "$FIXTURE" ]] && continue
  if grep -q -F -- "$(basename -- "$FIXTURE")" "$PORCELAIN_AFTER"; then
    fail "self-check: git status names a path this script created: $FIXTURE"
    FIXTURE_LEAK=$((FIXTURE_LEAK + 1))
  fi
done
if [[ "$FIXTURE_LEAK" -eq 0 ]]; then
  pass "self-check: git status names no fixture path this script created (every fixture lives outside the repo and is removed by the EXIT trap)"
fi

echo "=== Phase 19 ROADMAP Criteria Summary ==="
echo "Criterion 1 (repo-side link order: -L, readlink -f, folded ancestor, dangling): pending -- plan 19-02 and 19-03"
echo "Criterion 2 (capture/ drift as its own finding class): pending -- plan 19-04"
echo "Criterion 3 (exit 0/1/2, --strict promotion, frozen output contract): Section 1 (exit 0 and 1) and Section 2 (closed flag surface, exit 2, precondition cases); Section 3 pending -- this plan"
echo "Criterion 4 (adversarial rsync -a --delete and its negative control): Section 1; cp-through class pending -- plan 19-02"
echo "Criterion 5 (green on today's tree, repo-vs-HEAD [INFO], unclaimed stub [INFO]): pending -- plan 19-04"

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
