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
CAP_NONE="$(mktemp /tmp/p19-cap-none-XXXXXX)"
CAP_STRICT="$(mktemp /tmp/p19-cap-strict-XXXXXX)"
CAP_QUIET="$(mktemp /tmp/p19-cap-quiet-XXXXXX)"
STRIP_NONE="$(mktemp /tmp/p19-strip-none-XXXXXX)"
STRIP_STRICT="$(mktemp /tmp/p19-strip-strict-XXXXXX)"
FILTER_NONE="$(mktemp /tmp/p19-filter-none-XXXXXX)"
SCRATCH_ROOTS=()
T=""
T_REAL=""
RUN_REPO=""
RUN_HOME=""
BARE_REPO=""
rc=0

cleanup() {
  rm -f "$OUT" "$ERR" "$GOUT" "$GERR" "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" \
        "$CAP_NONE" "$CAP_STRICT" "$CAP_QUIET" \
        "$STRIP_NONE" "$STRIP_STRICT" "$FILTER_NONE" 2>/dev/null || true
  local root
  for root in ${SCRATCH_ROOTS[@]+"${SCRATCH_ROOTS[@]}"}; do
    [[ -n "$root" ]] || continue
    # Restore write and search permission across the whole scratch root BEFORE
    # removing it. Section 5 makes a managed directory unreadable on purpose to
    # prove D-11, and a failure between the chmod 000 and its restore would
    # otherwise leave an undeletable directory behind in /tmp for the operator
    # to find later. u+rwX (capital X) sets the search bit on directories only
    # and never marks a regular file executable.
    chmod -R u+rwX "$root" 2>/dev/null || true
    rm -rf "$root" 2>/dev/null || true
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

# ---------------------------------------------------------------------------
# summary_counters -- prints the two numbers off the frozen summary line of the
# capture named by $1, as "<fail> <findings>". Nothing else in this script ever
# reads a count out of a capture.
# ---------------------------------------------------------------------------
summary_counters() {
  sed -n 's/^=== done: FAIL=\([0-9][0-9]*\) FINDINGS=\([0-9][0-9]*\) ===$/\1 \2/p' -- "$1" | tail -1
}

# =============================================================================
# Section 3 / ROADMAP criterion 3 -- --strict and --quiet change the verdict and
# the volume, never the scope (D-13, D-14, D-16, D-18, D-20).
# =============================================================================
echo "=== Section 3 / ROADMAP criterion 3: --strict and --quiet change the verdict and the volume, never the scope ==="

build_fixture

run_fixture_verify
cp -- "$OUT" "$CAP_NONE"
RC_NONE="$rc"

run_fixture_verify --strict
cp -- "$OUT" "$CAP_STRICT"
RC_STRICT="$rc"

run_fixture_verify --quiet
cp -- "$OUT" "$CAP_QUIET"
RC_QUIET="$rc"

# --- D-14: byte-identical output above the summary line ---------------------
grep -v '^=== done: ' -- "$CAP_NONE" > "$STRIP_NONE" || true
grep -v '^=== done: ' -- "$CAP_STRICT" > "$STRIP_STRICT" || true
if cmp -s "$STRIP_NONE" "$STRIP_STRICT"; then
  pass "3 D-14: output above the summary line is byte-identical with and without --strict -- labels are fixed under --strict and only the exit code moves"
else
  fail "3 D-14: output above the summary line DIFFERS between the normal and the --strict run -- --strict changed a label, not just the verdict"
  diff -u "$STRIP_NONE" "$STRIP_STRICT" || true
fi

# --- D-20: --quiet suppresses [PASS] lines ONLY -----------------------------
if ! grep -q '^\[PASS\]' -- "$CAP_QUIET"; then
  pass "3 D-20: the --quiet capture contains zero [PASS] lines"
else
  fail "3 D-20: the --quiet capture still carries [PASS] lines"
  grep '^\[PASS\]' -- "$CAP_QUIET" | sed 's/^/       /' >&2 || true
fi

grep -v '^\[PASS\]' -- "$CAP_NONE" > "$FILTER_NONE" || true
if cmp -s "$FILTER_NONE" "$CAP_QUIET"; then
  pass "3 D-20: filtering [PASS] lines out of the no-flag capture yields the --quiet capture byte-for-byte -- --quiet suppressed only that label and reordered nothing"
else
  fail "3 D-20: the --quiet capture is not the no-flag capture minus its [PASS] lines -- --quiet suppressed or moved something else"
  diff -u "$FILTER_NONE" "$CAP_QUIET" || true
fi

# --- D-13 / D-16: no flag narrows what is examined --------------------------
COUNTERS_NONE="$(summary_counters "$CAP_NONE")"
COUNTERS_STRICT="$(summary_counters "$CAP_STRICT")"
COUNTERS_QUIET="$(summary_counters "$CAP_QUIET")"
if [[ -n "$COUNTERS_NONE" ]] \
   && [[ "$COUNTERS_NONE" == "$COUNTERS_STRICT" ]] \
   && [[ "$COUNTERS_NONE" == "$COUNTERS_QUIET" ]]; then
  pass "3 D-13/D-16: the FAIL and FINDINGS counters are identical across the normal, --strict and --quiet runs over the same tree (both runs report: $COUNTERS_NONE) -- --strict makes the verdict harsher and --quiet makes the output shorter, both over the identical full sweep"
else
  fail "3 D-13/D-16: the counters differ across the three runs (normal: '$COUNTERS_NONE', strict: '$COUNTERS_STRICT', quiet: '$COUNTERS_QUIET') -- a flag narrowed what is examined"
fi

# --- D-13's exit arithmetic, the half a clean fixture can prove --------------
# The findings-but-no-failures case needs a capture/ package staged in the
# scratch repo, which is plan 19-04's section for VER-02; it is deliberately NOT
# built here. 19-04 owns the findings-only --strict promotion case. What a clean
# fixture can prove is asserted here instead: --strict over a fixture reporting
# no failures and no findings still exits 0, so --strict is not a blanket
# demotion of green.
if [[ "$RC_NONE" -eq 0 ]] && [[ "$RC_STRICT" -eq 0 ]] && [[ "$RC_QUIET" -eq 0 ]]; then
  pass "3 D-13: over a clean fixture all three runs exit 0 -- --strict is not a blanket demotion of green (plan 19-04 owns the findings-only promotion case)"
else
  fail "3 D-13: a clean fixture did not exit 0 under all three runs (normal rc=$RC_NONE, strict rc=$RC_STRICT, quiet rc=$RC_QUIET)"
fi

# --- the superseded D-20 measurements, recorded once and asserted nowhere ----
info "3 superseded measurements, recorded here and asserted nowhere. 19-CONTEXT.md D-20's clean-run figures (30 [INFO] lines, 153 total, roughly 31 under --quiet) were re-measured during research to 32, 157 and 34 respectively, because D-06's own review moved the two non-repo dangling links from [FINDING] to [INFO] after the 30 was counted. This script therefore asserts no total line count anywhere: [INFO] volume moves with the operator's uncommitted edits and with whatever installer backup files the last install left, while the two summary counters are stable because [INFO] cannot move them (D-13). An executor reading D-20 later must not restore those numbers."

# =============================================================================
# Section 4 / ROADMAP criteria 4 and 5 -- the cp-through destruction class
# (D-27) and the untracked repo-side file (RESEARCH Pitfall 5).
#
# This is the section that makes `verify` honest, and it is the mirror image of
# Section 1. PITFALLS.md §30's claim is that BOTH destroying installer
# primitives leave the repo file untouched, so a CONTENT-only `verify` reports
# "no drift" in exactly the case that matters -- Section 1 proves that half by
# destroying the link and watching the verdict go red. The mirror of the same
# claim is that a LINK-only `verify` reports a clean [PASS] for a repo file that
# was overwritten THROUGH an intact link -- `cp -f` follows the destination
# symlink and rewrites its target, so every `test -L` and `readlink -f`
# assertion still passes while the repo file now holds upstream's bytes
# (PITFALLS.md A-1). Section 4 proves that half.
#
# The boundary this pins: the link class and the content class stay DISTINCT.
# The link still [PASS]es, the run still exits 0, and the content change is
# named as [INFO] (D-21/D-27) -- an observation, not a defect, because `verify`
# cannot tell an installer write-through from an ordinary uncommitted edit and
# reporting a guess as a defect is what scripts/phase14-verify.sh:10-14 forbids.
# =============================================================================
echo "=== Section 4 / ROADMAP criteria 4 and 5: the cp-through boundary and the untracked repo-side file ==="

# --- cp-through destruction (D-27) ------------------------------------------
build_fixture
S4_LIVE="$T/home/.config/fixpkg/conf"
S4_REPO="$(realpath -m -- "$T/repo/stow/fixture/.config/fixpkg/conf")"

mkdir -p "$T/vendor/fixpkg"
printf 'vendorcontent\n' > "$T/vendor/fixpkg/conf"

# The same fail-closed gate Section 1 uses, for the same reason: `cp -f`
# resolves the destination symlink, so the path actually written is the RESOLVED
# one. Handing the guard the link is therefore exactly right -- it resolves at
# call time and answers the question that matters, "is the file this write lands
# on inside the scratch root".
guard_scratch_target "$S4_LIVE" || exit 1
cp -f -- "$T/vendor/fixpkg/conf" "$S4_LIVE"

if [[ -L "$S4_LIVE" ]]; then
  pass "4 D-27 fixture: the live path is STILL a symlink after cp -f wrote through it -- the link survived, which is the whole point of this class"
else
  fail "4 D-27 fixture: cp -f replaced the link instead of writing through it -- this fixture is staging the Section 1 class, not the cp-through class"
fi

if [[ "$(cat -- "$S4_REPO")" == "vendorcontent" ]]; then
  pass "4 D-27 fixture: the REPO-side file now holds the vendor payload -- the destruction really happened, on the repo side, with the link untouched"
else
  fail "4 D-27 fixture: the repo-side file does not hold the vendor payload (got: $(cat -- "$S4_REPO")) -- nothing was destroyed and the assertions below would prove nothing"
fi

run_fixture_verify
if [[ "$rc" -eq 0 ]]; then
  pass "4 D-27: verify exits 0 after the cp-through (rc=$rc) -- an overwritten repo file is not a link failure"
else
  fail "4 D-27: verify exited $rc after the cp-through, expected 0 -- the content class leaked into the link verdict"
  sed 's/^/       /' < "$OUT" >&2 || true
  sed 's/^/       /' < "$ERR" >&2 || true
fi

if grep '^\[PASS\]' "$OUT" | grep -q -F -- "$S4_LIVE"; then
  pass "4 D-27: the live path is still on a [PASS] line: $S4_LIVE -- it survived every test -L and readlink -f assertion intact"
else
  fail "4 D-27: $S4_LIVE is absent from any [PASS] line -- the link was reported as broken when only its target's content changed"
  sed 's/^/       /' < "$OUT" >&2 || true
fi

if grep '^\[INFO\]' "$OUT" | grep -F -- "$S4_REPO" | grep -q -F -- 'differs from HEAD'; then
  pass "4 D-21/D-27: the repo-side path is named on an [INFO] line as differing from HEAD: $S4_REPO -- only this observation can see a cp-through"
else
  fail "4 D-21/D-27: no [INFO] line names $S4_REPO as differing from HEAD -- the cp-through is invisible to this verify"
  sed 's/^/       /' < "$OUT" >&2 || true
fi

if grep -q -F -- '=== done: FAIL=0 FINDINGS=0 ===' "$OUT"; then
  pass "4 D-13/D-27: the cp-through run summarises FAIL=0 FINDINGS=0 -- an [INFO] moves neither counter"
else
  fail "4 D-13/D-27: the cp-through run did not summarise FAIL=0 FINDINGS=0 -- the content observation was wired as a failure or a finding"
  grep -- '=== done:' "$OUT" >&2 || true
fi

# --- the untracked repo-side file (RESEARCH Pitfall 5) ----------------------
# A FRESH fixture, so the only content anomaly in this run is the untracked one
# and the [INFO] asserted below cannot be the cp-through's line in disguise.
# This is the case where `git diff --quiet HEAD` returns 0 -- a literal "matches
# HEAD" for a file that was never committed -- and would otherwise have said
# nothing at all.
build_fixture
S4_NEW_REPO="$(realpath -m -- "$T/repo/stow/fixture/.config/fixpkg/newfile")"
S4_NEW_LIVE="$T/home/.config/fixpkg/newfile"

printf 'never committed\n' > "$T/repo/stow/fixture/.config/fixpkg/newfile"
( cd "$T/repo/stow" && stow --no-folding -t "$T/home" fixture )

if [[ -L "$S4_NEW_LIVE" ]]; then
  pass "4 Pitfall 5 fixture: the never-committed repo file is stowed and its live counterpart is a symlink -- it reaches the content observation at all"
else
  fail "4 Pitfall 5 fixture: $S4_NEW_LIVE is not a symlink -- the walk would stop at the link test and never reach the trackedness arm"
fi

run_fixture_verify
if [[ "$rc" -eq 0 ]]; then
  pass "4 Pitfall 5: verify exits 0 over a fixture holding an untracked repo-side file (rc=$rc)"
else
  fail "4 Pitfall 5: verify exited $rc, expected 0 -- an untracked file was wired to move the verdict"
  sed 's/^/       /' < "$OUT" >&2 || true
  sed 's/^/       /' < "$ERR" >&2 || true
fi

if grep '^\[INFO\]' "$OUT" | grep -F -- "$S4_NEW_REPO" | grep -q -F -- 'untracked'; then
  pass "4 Pitfall 5: the never-committed repo file is named on its own untracked [INFO] line: $S4_NEW_REPO"
else
  fail "4 Pitfall 5: no untracked [INFO] line names $S4_NEW_REPO -- git diff --quiet HEAD returned 0 for it and verify silently called that 'matches HEAD'"
  sed 's/^/       /' < "$OUT" >&2 || true
fi

if grep '^\[INFO\]' "$OUT" | grep -F -- "$S4_NEW_REPO" | grep -q -F -- 'differs from HEAD'; then
  fail "4 Pitfall 5: $S4_NEW_REPO is reported as differing from HEAD -- the untracked class is not distinct from the differs-from-HEAD class"
else
  pass "4 Pitfall 5: the untracked class is worded distinctly -- no 'differs from HEAD' line names $S4_NEW_REPO"
fi

if grep -q -F -- '=== done: FAIL=0 FINDINGS=0 ===' "$OUT"; then
  pass "4 D-13/Pitfall 5: the untracked run summarises FAIL=0 FINDINGS=0 -- both new emissions are [INFO] and move no counter"
else
  fail "4 D-13/Pitfall 5: the untracked run did not summarise FAIL=0 FINDINGS=0"
  grep -- '=== done:' "$OUT" >&2 || true
fi

# =============================================================================
# Section 5 / ROADMAP criterion 1 -- the live-side sweep's four pathologies,
# staged SIMULTANEOUSLY in one scratch $HOME (D-34).
#
# Five setup/teardown cycles become one, and -- the reason to prefer the
# composite rather than merely a convenience -- one run over all four
# additionally proves that the counters AGGREGATE across pathologies, which no
# single-pathology fixture can test. Do not split this back apart for
# readability: the aggregation proof is the exact thing that would be lost.
#
# The pathologies are staged in DISJOINT managed directories, and that is
# load-bearing rather than tidy. D-04's own "one failure, not N" rule means a
# folded ancestor directory SUPPRESSES the per-file checks underneath it, so a
# stale link staged inside the folded directory would be masked and this section
# would silently prove three pathologies while reporting four passes (T-19-09,
# and RESEARCH Assumptions Log A1, the fixture's one medium-risk assumption).
# One directory per pathology dissolves it. A later reader must not consolidate
# them.
#
# Neither the folded-ancestor check nor the dangling-into-repo arm has a live
# positive anywhere on the real tree -- Phase 17 found two folded directories
# and Phase 18's redistribution resolved both -- so this fixture is the ONLY
# proof either check works at all.
# =============================================================================
echo "=== Section 5 / ROADMAP criterion 1: the live-side sweep's four pathologies, staged together ==="

# ---------------------------------------------------------------------------
# build_sweep_fixture -- build_fixture's mechanics with a package declaring
# files in five disjoint managed directories, so each pathology gets one of its
# own. Sets T, T_REAL, RUN_REPO and RUN_HOME exactly as build_fixture does.
# ---------------------------------------------------------------------------
build_sweep_fixture() {
  T="$(mktemp -d /tmp/p19-sweep-XXXXXX)"
  SCRATCH_ROOTS+=("$T"); trap cleanup EXIT   # D-30: before the first write
  T_REAL="$(realpath -- "$T")"               # D-26: captured at setup

  mkdir -p "$T/repo/arch"
  cp -- "$REPO_ROOT/arch/dots-hyprland.sh" "$T/repo/arch/dots-hyprland.sh"
  chmod +x "$T/repo/arch/dots-hyprland.sh"

  local d
  for d in folded danglein dangleout stale missing; do
    mkdir -p "$T/repo/stow/sweepfix/.config/$d"
  done
  # Two declared files under the folded directory, so the D-04 "one failure,
  # not N" behaviour is actually exercised rather than assumed.
  printf 'a\n' > "$T/repo/stow/sweepfix/.config/folded/a.conf"
  printf 'b\n' > "$T/repo/stow/sweepfix/.config/folded/b.conf"
  printf 'd\n' > "$T/repo/stow/sweepfix/.config/danglein/d.conf"
  printf 'o\n' > "$T/repo/stow/sweepfix/.config/dangleout/o.conf"
  printf 's\n' > "$T/repo/stow/sweepfix/.config/stale/s.conf"
  printf 'm\n' > "$T/repo/stow/sweepfix/.config/missing/m.conf"

  git -c init.defaultBranch=main init -q "$T/repo"
  git -C "$T/repo" config user.name "GSD Assert"
  git -C "$T/repo" config user.email "assert@local"
  git -C "$T/repo" add -A
  git -C "$T/repo" -c commit.gpgsign=false commit -q -m "sweep fixture initial state"

  mkdir -p "$T/home"
  ( cd "$T/repo/stow" && stow --no-folding -t "$T/home" sweepfix )

  RUN_REPO="$T/repo"
  RUN_HOME="$T/home"
}

build_sweep_fixture

# --- pathology 1: a folded ancestor directory -------------------------------
# Replace the stowed directory with a symlink INTO the repo -- exactly what
# stow's own folding produces when --no-folding is not passed. The target is
# written RELATIVE because that is the shape stow emits, and a literal prefix
# test on a relative target is the defect T-19-02 exists to catch.
S5_FOLDED="$T/home/.config/folded"
rm -rf -- "$S5_FOLDED"
ln -s "../../repo/stow/sweepfix/.config/folded" "$S5_FOLDED"

# --- pathology 2: a link that dangles INTO the repo --------------------------
# Staged as an UNDECLARED extra link rather than by deleting a repo file, so the
# managed directory keeps a declared file and stays a managed root. The repo-side
# walk enumerates the repo, so it can never see this link at all -- only the
# sweep can, which is the whole reason the sweep exists. PITFALLS.md A-6.
S5_DANGLE_IN="$T/home/.config/danglein/gone.conf"
ln -s "../../../repo/stow/sweepfix/.config/danglein/gone.conf" "$S5_DANGLE_IN"

# --- pathology 3: a link that dangles OUTSIDE the repo, the [INFO] control ---
# Same shape as pathology 2, differing only in where the target points. Without
# this control the section would prove that verify shouts at dangling links,
# not that it distinguishes the two kinds (D-06).
S5_DANGLE_OUT="$T/home/.config/dangleout/absent.conf"
ln -s "$T/nowhere/absent.conf" "$S5_DANGLE_OUT"

# --- pathology 4: a stale link at an undeclared path, and an unclaimed stub ---
S5_STALE="$T/home/.config/stale/extra.conf"
ln -s "../../../repo/stow/sweepfix/.config/stale/s.conf" "$S5_STALE"
S5_STUB="$T/home/.config/stale/stub.conf"
printf 'upstream wrote this\n' > "$S5_STUB"

# --- the repo-side recovery-text case (D-33) --------------------------------
# A missing live link, in its own disjoint directory. The folded directory
# cannot carry this one: D-04 suppresses the per-file checks underneath it, so
# the [FAIL] whose recovery text is being asserted would never be emitted.
S5_MISSING="$T/home/.config/missing/m.conf"
rm -f -- "$S5_MISSING"

run_fixture_verify
cp -- "$OUT" "$CAP_NONE"
S5_RC="$rc"

if [[ "$S5_RC" -eq 1 ]]; then
  pass "5 composite: verify exits 1 over a fixture staging all four sweep pathologies at once (rc=$S5_RC)"
else
  fail "5 composite: verify exited $S5_RC over the composite fixture, expected 1"
  sed 's/^/       /' < "$OUT" >&2 || true
  sed 's/^/       /' < "$ERR" >&2 || true
fi

if grep '^\[FAIL\]' "$CAP_NONE" | grep -F -- "$S5_FOLDED" | grep -q -F -- 'folded ancestor directory'; then
  pass "5 pathology 1 (D-04): a [FAIL] names the folded ancestor directory: $S5_FOLDED"
else
  fail "5 pathology 1 (D-04): no [FAIL] names $S5_FOLDED as a folded ancestor directory -- the check has no live positive on the real tree, so this fixture is its only proof"
  sed 's/^/       /' < "$CAP_NONE" >&2 || true
fi

S5_FOLD_LINE="$(grep '^\[FAIL\]' "$CAP_NONE" | grep -F -- 'folded ancestor directory' | head -1 || true)"
if [[ -n "$S5_FOLD_LINE" ]] \
   && printf '%s\n' "$S5_FOLD_LINE" | grep -q -F -- 'stow -D --no-folding -t' \
   && printf '%s\n' "$S5_FOLD_LINE" | grep -q -F -- 'stow --no-folding -t' \
   && printf '%s\n' "$S5_FOLD_LINE" | grep -q -F -- 'sweepfix'; then
  pass "5 pathology 1 / D-33: the folded-ancestor [FAIL] carries the unstow-and-re-stow pair with the no-folding flag and names the package"
else
  fail "5 pathology 1 / D-33: the folded-ancestor [FAIL] does not carry an unstow-and-re-stow recovery pair naming the package -- a failure the operator cannot act on"
  printf '       %s\n' "$S5_FOLD_LINE" >&2 || true
fi

if grep '^\[FAIL\]' "$CAP_NONE" | grep -F -- "$S5_DANGLE_IN" | grep -q -F -- 'dangling symlink into repo'; then
  pass "5 pathology 2 (D-06 / PITFALLS A-6): a [FAIL] names the link dangling into the repo: $S5_DANGLE_IN"
else
  fail "5 pathology 2 (D-06): no [FAIL] names $S5_DANGLE_IN as dangling into the repo -- either the sweep never saw an undeclared link, or the relative target was prefix-tested unresolved (T-19-02)"
  sed 's/^/       /' < "$CAP_NONE" >&2 || true
fi

if grep '^\[INFO\]' "$CAP_NONE" | grep -F -- "$S5_DANGLE_OUT" | grep -q -F -- 'dangling symlink (outside repo)'; then
  pass "5 pathology 3 (D-06 control): the link dangling OUTSIDE the repo is an [INFO], not a [FAIL]: $S5_DANGLE_OUT"
else
  fail "5 pathology 3 (D-06 control): $S5_DANGLE_OUT is not on an [INFO] dangling-outside-repo line -- verify shouts at every dangling link instead of distinguishing the two kinds, which makes a healthy machine permanently noisy"
  sed 's/^/       /' < "$CAP_NONE" >&2 || true
fi

if grep '^\[FAIL\]' "$CAP_NONE" | grep -F -- "$S5_STALE" | grep -q -F -- 'stale link into repo at an undeclared path'; then
  pass "5 pathology 4 (D-03 arm 2): a [FAIL] names the stale link into the repo at a path the repo never declared: $S5_STALE"
else
  fail "5 pathology 4 (D-03 arm 2): no [FAIL] names $S5_STALE -- this condition is invisible to the repo-side walk by construction, so the sweep is the only thing that can catch it"
  sed 's/^/       /' < "$CAP_NONE" >&2 || true
fi

if grep '^\[INFO\]' "$CAP_NONE" | grep -q -F -- "$S5_STUB"; then
  pass "5 pathology 4 (D-03 arm 7): the unclaimed stub sitting beside a managed link is named on an [INFO] line: $S5_STUB"
else
  fail "5 pathology 4 (D-03 arm 7): no [INFO] names the unclaimed stub $S5_STUB"
  sed 's/^/       /' < "$CAP_NONE" >&2 || true
fi

S5_MISSING_LINE="$(grep '^\[FAIL\]' "$CAP_NONE" | grep -F -- "$S5_MISSING" | head -1 || true)"
if [[ -n "$S5_MISSING_LINE" ]] \
   && printf '%s\n' "$S5_MISSING_LINE" | grep -q -F -- 'stow -t' \
   && printf '%s\n' "$S5_MISSING_LINE" | grep -q -F -- 'sweepfix'; then
  pass "5 D-33: the missing-link [FAIL] names the path and carries a stow -t recovery invocation naming the package"
else
  fail "5 D-33: no [FAIL] line names $S5_MISSING together with a stow -t recovery invocation naming the package"
  sed 's/^/       /' < "$CAP_NONE" >&2 || true
fi

# --- the aggregation proof (D-34) -------------------------------------------
# The two counters asserted by EXACT VALUE. This is what the composite buys and
# a per-pathology fixture cannot: a silently-skipped pathology shows up here as
# a counter mismatch rather than as a passing run.
#
# FAIL=4 is: the folded ancestor (ONE line for a directory holding TWO declared
# files -- D-04's "one failure, not N"), the missing live link, the link
# dangling into the repo, and the stale undeclared link. FINDINGS=0 because the
# fixture stages no capture/ tree, which after D-06 and D-21 is the only
# [FINDING] source left in this phase.
#
# No total line count is asserted here or anywhere else in this script: [INFO]
# volume is not stable, and a line-count assertion rots (RESEARCH Anti-Patterns).
S5_COUNTERS="$(summary_counters "$CAP_NONE")"
if [[ "$S5_COUNTERS" == "4 0" ]]; then
  pass "5 D-34 aggregation: the composite run summarises exactly FAIL=4 FINDINGS=0 -- the counters aggregate across all four pathologies and the four [INFO] emissions moved neither"
else
  fail "5 D-34 aggregation: the composite run summarised '$S5_COUNTERS', expected '4 0' -- a pathology was skipped, double-counted, or masked another (T-19-09)"
  sed 's/^/       /' < "$CAP_NONE" >&2 || true
fi

# --- sweep-level determinism (bash associative-array iteration is HASH order) -
# One line's worth of assertion standing between the sweep and a report that
# reorders itself between runs on an unchanged tree. Without the LC_ALL=C sort
# over the managed roots this fails and nothing else in the script would.
run_fixture_verify
cp -- "$OUT" "$CAP_STRICT"
if cmp -s "$CAP_NONE" "$CAP_STRICT"; then
  pass "5 determinism: two consecutive runs over the same unmodified composite fixture produce byte-identical stdout -- the associative-array hash order does not leak into the report"
else
  fail "5 determinism: two consecutive runs over an unmodified fixture produced DIFFERENT stdout -- the managed-root iteration is in hash order, not sorted"
  diff -u "$CAP_NONE" "$CAP_STRICT" || true
fi

# --- the unreadable managed directory (D-11 and D-12's positional rule) ------
# A FRESH fixture, so the mode change cannot interact with anything staged
# above. D-12's rule is POSITIONAL, not semantic: an unreadable directory LOOKS
# like a precondition -- "this run cannot make a verdict here" -- but it is
# discovered DURING the walk, so it is exit 1 and never exit 2. Exit 2 is
# decided before the walk starts and nowhere else.
build_fixture
S5_UNREADABLE="$T/home/.config/fixpkg"
chmod 000 "$S5_UNREADABLE"
run_fixture_verify
# Restored IMMEDIATELY, before any assertion can short-circuit past it. The
# cleanup function also chmods the scratch root before removing it, so a failure
# between these two lines still cannot leave an undeletable directory behind.
chmod 755 "$S5_UNREADABLE"

if [[ "$rc" -eq 1 ]]; then
  pass "5 D-11/D-12: an unreadable managed directory yields exit 1, not exit 2 (rc=$rc) -- a mid-walk discovery never collapses into a precondition failure"
else
  fail "5 D-11/D-12: an unreadable managed directory yielded exit $rc, expected 1 -- exit 2 here would turn D-12's positional rule into a semantic one"
  sed 's/^/       /' < "$OUT" >&2 || true
  sed 's/^/       /' < "$ERR" >&2 || true
fi

if grep '^\[FAIL\]' "$OUT" | grep -F -- "$S5_UNREADABLE" | grep -q -F -- 'unreadable managed directory'; then
  pass "5 D-11: the [FAIL] names the directory it could not read: $S5_UNREADABLE -- verify never reports [PASS] for a condition it could not observe"
else
  fail "5 D-11: no [FAIL] names $S5_UNREADABLE as unreadable -- the sweep either passed it or skipped it silently"
  sed 's/^/       /' < "$OUT" >&2 || true
fi

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
               "$CAP_NONE" "$CAP_STRICT" "$CAP_QUIET" \
               "$STRIP_NONE" "$STRIP_STRICT" "$FILTER_NONE" \
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
echo "Criterion 1 (repo-side link order: -L, readlink -f, folded ancestor, dangling; plus the live-side sweep for the two conditions the repo-side walk structurally cannot see): Section 5 -- the composite fixture stages a folded ancestor, a link dangling into the repo, its dangling-outside-repo [INFO] control, a stale link at an undeclared path and an unclaimed stub in five disjoint managed directories, and one run names all of them, carries the recovery text, exits 1 and reports FAIL=4 FINDINGS=0. Section 5 is the only live positive the folded-ancestor and dangling-into-repo checks have anywhere"
echo "Criterion 2 (capture/ drift as its own finding class): pending -- plan 19-04"
echo "Criterion 3 (exit 0/1/2, --strict promotion, frozen output contract): Sections 1, 2 and 3 (exit 0/1, closed flag surface and exit 2, flag-invariant scope); findings-only --strict promotion pending -- plan 19-04"
echo "Criterion 4 (adversarial rsync -a --delete and its negative control): Section 1; cp-through class: Section 4"
echo "Criterion 5 (green on today's tree, repo-vs-HEAD [INFO], unclaimed stub [INFO]): repo-vs-HEAD [INFO] and its untracked-file extension: Section 4; green-on-today's-tree and the unclaimed-stub [INFO] pending -- plan 19-04"

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
