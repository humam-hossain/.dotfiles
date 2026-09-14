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
CAP_A="$(mktemp /tmp/p19-cap-a-XXXXXX)"
CAP_B="$(mktemp /tmp/p19-cap-b-XXXXXX)"
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
        "$STRIP_NONE" "$STRIP_STRICT" "$FILTER_NONE" \
        "$CAP_A" "$CAP_B" 2>/dev/null || true
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
# ---------------------------------------------------------------------------
# The vendored submodule path, composed from two halves and deliberately never
# written as one literal anywhere in this script's executable text.
#
# D-47 says neither `verify` nor this assert may depend on that directory, and
# the phase's source gate enforces it by stripping comment lines out of this
# file and grepping the remainder for the path. A literal in a code line reads
# as a dependency to that gate whatever the surrounding code actually does.
#
# Both uses below are STRING operations and nothing else: one compares the
# wrapper's own usage text, the other writes a scratch `.gitmodules`. Neither
# reads, stats, sources or executes anything under the real directory.
# ---------------------------------------------------------------------------
VENDOR_PARENT="vendor"
VENDOR_LEAF="dots-hyprland"
VENDOR_PATH="$VENDOR_PARENT/$VENDOR_LEAF"

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
  if [[ "$rc" -eq 0 ]] && grep -q -F -- "thin wrapper for $VENDOR_PATH" "$OUT"; then
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

# ---------------------------------------------------------------------------
# same_above_summary -- succeeds when the two captures named by $1 and $2 are
# byte-identical once the frozen `=== done:` line is removed from both. Leaves
# the two stripped copies in STRIP_NONE and STRIP_STRICT so a failing caller can
# diff them.
#
# D-14's claim -- --strict moves the exit code and nothing else -- is made twice
# in this script, in Section 3 over a clean fixture and in Section 6 over a
# findings-only one. Written once here for that reason: two copies of this
# comparison are two chances for them to drift into disagreeing about what
# "identical above the summary line" means, and the Section 6 half is the one
# that actually has a finding to keep fixed.
# ---------------------------------------------------------------------------
same_above_summary() {
  grep -v '^=== done: ' -- "$1" > "$STRIP_NONE" || true
  grep -v '^=== done: ' -- "$2" > "$STRIP_STRICT" || true
  cmp -s "$STRIP_NONE" "$STRIP_STRICT"
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
if same_above_summary "$CAP_NONE" "$CAP_STRICT"; then
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
# Section 6 / ROADMAP criteria 2 and 3 -- the findings-only `capture/` fixture
# and the --strict promotion (D-13, D-22, D-35, VER-02, VER-03).
#
# Every assertion in this section has to come from a staged fixture, and that is
# a property of the tree rather than a convenience. `capture/` holds exactly one
# file today -- its README -- and the block implementing VER-02 iterates package
# DIRECTORIES under it, so the block is vacuous on the live tree and cannot be
# exercised there at all. The empty-shape case below asserts that vacuity
# explicitly, which is what stops it from being mistaken for coverage.
#
# The same fixture is the only thing --strict has to promote. After D-06 moved
# the non-repo dangling links to [INFO] and D-21 made the repo-vs-HEAD content
# observation [INFO], `capture/` content drift and `capture/` missing-live-
# counterpart are the ONLY two [FINDING] sources this phase has (D-35). A
# findings-only fixture that staged no `capture/` package would leave --strict
# nothing to promote and the promotion assertion vacuously satisfied -- which is
# why the FINDINGS= value is asserted by EXACT NUMBER below and not merely as
# "greater than zero" (T-19-11).
#
# Why the labels differ from the link class, deliberately rather than
# inconsistently (D-22 against D-21): the `capture/` comparison holds two REAL
# artifacts side by side -- the live file and its repo mirror -- and observes a
# genuine disagreement between them. D-21's repo-vs-HEAD observation cannot
# distinguish an installer write-through from an operator's own uncommitted edit
# and is therefore [INFO]. Higher-confidence observation, louder class; the
# asymmetry is the point.
# =============================================================================
echo "=== Section 6 / ROADMAP criteria 2 and 3: the findings-only capture/ fixture and the --strict promotion ==="

# ---------------------------------------------------------------------------
# build_capture_fixture -- build_fixture's mechanics plus a `capture/` package,
# whose contract is INVERTED: the live file is a REAL file, never a link, and
# the repo holds a mirror copy of it.
#
# $1 selects what is staged on the live side, and nothing else varies:
#   drift    -- live file present, bytes DIFFER from the repo mirror
#   clean    -- live file present and byte-identical to the repo mirror
#   missing  -- no live counterpart at all
#   stowed   -- live path is a symlink INTO the repo (the inverted expectation)
#   ordering -- five byte-identical files, for the listing-order case
#   empty    -- a `capture/` directory holding only a README and no packages
#
# The stow/ side is staged clean and identical in every mode, so the only
# variable between two runs of this builder is the `capture/` staging. Sets T,
# T_REAL, RUN_REPO and RUN_HOME exactly as build_fixture does.
# ---------------------------------------------------------------------------
build_capture_fixture() {
  local mode="${1:-drift}"
  T="$(mktemp -d /tmp/p19-capture-XXXXXX)"
  SCRATCH_ROOTS+=("$T"); trap cleanup EXIT   # D-30: before the first write
  T_REAL="$(realpath -- "$T")"               # D-26: captured at setup

  mkdir -p "$T/repo/arch" "$T/repo/stow/fixture/.config/fixpkg" "$T/home/.config/fixpkg"
  cp -- "$REPO_ROOT/arch/dots-hyprland.sh" "$T/repo/arch/dots-hyprland.sh"
  chmod +x "$T/repo/arch/dots-hyprland.sh"
  printf 'v1\n' > "$T/repo/stow/fixture/.config/fixpkg/conf"

  # The README is present in EVERY mode, including `empty`. That mirrors the
  # real tree, where capture/README.md is the whole of the directory, and it is
  # what makes the empty case a statement about package directories rather than
  # about an absent tree.
  mkdir -p "$T/repo/capture"
  printf '# scratch capture tree contract\n' > "$T/repo/capture/README.md"

  local n
  case "$mode" in
    empty)
      : # README only -- no package directories, so the block iterates nothing
      ;;
    ordering)
      mkdir -p "$T/repo/capture/cappkg/.config/cappkg"
      for n in a b c d e; do
        printf 'mirror-%s\n' "$n" > "$T/repo/capture/cappkg/.config/cappkg/$n.conf"
      done
      ;;
    *)
      mkdir -p "$T/repo/capture/cappkg/.config/cappkg"
      printf 'repo-mirror\n' > "$T/repo/capture/cappkg/.config/cappkg/app.conf"
      ;;
  esac

  git -c init.defaultBranch=main init -q "$T/repo"
  git -C "$T/repo" config user.name "GSD Assert"
  git -C "$T/repo" config user.email "assert@local"
  git -C "$T/repo" add -A
  git -C "$T/repo" -c commit.gpgsign=false commit -q -m "capture fixture initial state ($mode)"

  ( cd "$T/repo/stow" && stow --no-folding -t "$T/home" fixture )

  # The live side, staged AFTER the commit so nothing here can reach the repo.
  case "$mode" in
    drift)
      mkdir -p "$T/home/.config/cappkg"
      printf 'live-bytes\n' > "$T/home/.config/cappkg/app.conf"
      ;;
    clean)
      mkdir -p "$T/home/.config/cappkg"
      printf 'repo-mirror\n' > "$T/home/.config/cappkg/app.conf"
      ;;
    missing)
      mkdir -p "$T/home/.config/cappkg"   # the directory exists; the file does not
      ;;
    stowed)
      mkdir -p "$T/home/.config/cappkg"
      ln -s "../../../repo/capture/cappkg/.config/cappkg/app.conf" \
            "$T/home/.config/cappkg/app.conf"
      ;;
    ordering)
      mkdir -p "$T/home/.config/cappkg"
      for n in a b c d e; do
        printf 'mirror-%s\n' "$n" > "$T/home/.config/cappkg/$n.conf"
      done
      ;;
  esac

  RUN_REPO="$T/repo"
  RUN_HOME="$T/home"
}

# ---------------------------------------------------------------------------
# capture_tree_lines -- every line the `capture/` block can emit, and nothing
# else, read off the capture named by $1. The four message stems are quoted
# from arch/dots-hyprland.sh's capture block verbatim; the empty-shape case
# below asserts that a package-less `capture/` produces NONE of them.
# ---------------------------------------------------------------------------
capture_tree_lines() {
  grep -E 'capture path verified|content drift between live and repo|live counterpart does not exist|wrongly stowed' -- "$1" || true
}

# --- case 1: content drift is a [FINDING], and is NOT a [FAIL] --------------
build_capture_fixture drift
S6_LIVE="$T/home/.config/cappkg/app.conf"

run_fixture_verify
cp -- "$OUT" "$CAP_A"
S6_RC_NONE="$rc"

if grep '^\[FINDING\]' "$CAP_A" | grep -F -- "$S6_LIVE" | grep -q -F -- 'content drift between live and repo'; then
  pass "6 VER-02/D-22: a drifted capture/ path is named on a [FINDING] line as content drift between live and repo: $S6_LIVE"
else
  fail "6 VER-02/D-22: no [FINDING] names $S6_LIVE as content drift -- capture/ drift has no finding class of its own"
  sed 's/^/       /' < "$CAP_A" >&2 || true
fi

if grep '^\[FAIL\]' "$CAP_A" | grep -q -F -- "$S6_LIVE"; then
  fail "6 VER-02/D-22: $S6_LIVE is on a [FAIL] line -- content drift was collapsed into the link class, and the [FINDING] class D-22 requires does not exist"
  sed 's/^/       /' < "$CAP_A" >&2 || true
else
  pass "6 VER-02/D-22: no [FAIL] names $S6_LIVE -- drift between two real artifacts is a class of its own, distinct from a link failure and louder than D-21's repo-vs-HEAD [INFO] guess"
fi

S6_COUNTERS_NONE="$(summary_counters "$CAP_A")"
if [[ "$S6_COUNTERS_NONE" == "0 1" ]]; then
  pass "6 T-19-11: the drift fixture summarises exactly FAIL=0 FINDINGS=1 -- the staged set implies one finding and one finding was counted, so --strict below has something real to promote"
else
  fail "6 T-19-11: the drift fixture summarised '$S6_COUNTERS_NONE', expected '0 1' -- a fixture producing zero findings would satisfy the promotion assertion below vacuously"
  sed 's/^/       /' < "$CAP_A" >&2 || true
fi

if [[ "$S6_RC_NONE" -eq 0 ]]; then
  pass "6 D-13: the findings-only fixture exits 0 without --strict (rc=$S6_RC_NONE) -- a [FINDING] does not move the exit code on its own"
else
  fail "6 D-13: the findings-only fixture exited $S6_RC_NONE without --strict, expected 0 -- a finding moved the exit code with no flag asking it to"
  sed 's/^/       /' < "$CAP_A" >&2 || true
fi

# --- the promotion: identical fixture, identical labels, different exit code --
run_fixture_verify --strict
cp -- "$OUT" "$CAP_B"
S6_RC_STRICT="$rc"
S6_COUNTERS_STRICT="$(summary_counters "$CAP_B")"

if [[ "$S6_RC_STRICT" -eq 1 ]] && [[ "$S6_COUNTERS_STRICT" == "0 1" ]]; then
  pass "6 D-13/VER-03: the SAME fixture exits 1 under --strict with FAIL= still 0 (rc=$S6_RC_STRICT, counters '$S6_COUNTERS_STRICT') -- that pair is the whole of D-13 and the reason --strict exists"
else
  fail "6 D-13/VER-03: the findings-only fixture exited $S6_RC_STRICT under --strict with counters '$S6_COUNTERS_STRICT', expected rc 1 and '0 1' -- --strict did not promote the finding, or promoted it by inventing a failure"
  sed 's/^/       /' < "$CAP_B" >&2 || true
fi

if same_above_summary "$CAP_A" "$CAP_B"; then
  pass "6 D-14: the --strict and no-flag captures over the findings-only fixture are byte-identical above the summary line -- --strict re-labelled nothing and only the verdict moved"
else
  fail "6 D-14: the --strict capture differs from the no-flag capture above the summary line -- --strict changed a label on a fixture that has a finding to keep fixed"
  diff -u "$STRIP_NONE" "$STRIP_STRICT" || true
fi

# --- case 2: a capture/ path with no live counterpart -----------------------
# Its own fixture, so it cannot interact with the drift case above. This is the
# second and last [FINDING] source in the phase (D-35).
build_capture_fixture missing
S6_MISSING="$T/home/.config/cappkg/app.conf"

run_fixture_verify
cp -- "$OUT" "$CAP_A"
S6_MISS_RC="$rc"
S6_MISS_COUNTERS="$(summary_counters "$CAP_A")"

if grep '^\[FINDING\]' "$CAP_A" | grep -F -- "$S6_MISSING" | grep -q -F -- 'live counterpart does not exist'; then
  pass "6 VER-02: a capture/ path whose live counterpart is absent is named on a [FINDING] line: $S6_MISSING"
else
  fail "6 VER-02: no [FINDING] names $S6_MISSING as an absent live counterpart -- the phase's second finding source does not exist"
  sed 's/^/       /' < "$CAP_A" >&2 || true
fi

run_fixture_verify --strict
S6_MISS_RC_STRICT="$rc"

if [[ "$S6_MISS_RC" -eq 0 ]] && [[ "$S6_MISS_RC_STRICT" -eq 1 ]] && [[ "$S6_MISS_COUNTERS" == "0 1" ]]; then
  pass "6 D-13/D-35: the absent-counterpart fixture exits 0 bare and 1 under --strict with FAIL=0 (counters '$S6_MISS_COUNTERS') -- both of the phase's finding sources promote the same way"
else
  fail "6 D-13/D-35: the absent-counterpart fixture exited $S6_MISS_RC bare and $S6_MISS_RC_STRICT under --strict with counters '$S6_MISS_COUNTERS', expected 0, 1 and '0 1'"
  sed 's/^/       /' < "$CAP_A" >&2 || true
fi

# --- case 3: a capture/ path whose live counterpart is a symlink into the repo
# The inverted expectation is a HARD condition, not an observation: a link at
# one of these paths is destroyed by the first rename-over-the-link write, so it
# is [FAIL] and it moves the exit code with no flag asking it to.
build_capture_fixture stowed
S6_STOWED="$T/home/.config/cappkg/app.conf"

run_fixture_verify
cp -- "$OUT" "$CAP_A"
S6_STOWED_RC="$rc"
S6_STOWED_COUNTERS="$(summary_counters "$CAP_A")"

if grep '^\[FAIL\]' "$CAP_A" | grep -F -- "$S6_STOWED" | grep -q -F -- 'wrongly stowed'; then
  pass "6 D-50: a capture/ path whose live counterpart is a symlink into the repo is a [FAIL] naming it as wrongly stowed: $S6_STOWED"
else
  fail "6 D-50: no [FAIL] names $S6_STOWED as wrongly stowed -- the inverted expectation is not enforced, and a link at a capture/ path survives only until the first rename-over-the-link write"
  sed 's/^/       /' < "$CAP_A" >&2 || true
fi

if [[ "$S6_STOWED_RC" -eq 1 ]] && [[ "$S6_STOWED_COUNTERS" == "1 0" ]]; then
  pass "6 D-50/D-13: the wrongly-stowed fixture exits 1 with no flag and summarises FAIL=1 FINDINGS=0 (rc=$S6_STOWED_RC) -- a hard condition, not a finding awaiting --strict"
else
  fail "6 D-50/D-13: the wrongly-stowed fixture exited $S6_STOWED_RC with counters '$S6_STOWED_COUNTERS', expected 1 and '1 0'"
  sed 's/^/       /' < "$CAP_A" >&2 || true
fi

# --- case 4: the empty shape, which is the shape of the real tree today ------
# Asserted against the SAME fixture built without a `capture/` directory at all,
# so the claim is that a package-less capture/ is indistinguishable from an
# absent one rather than merely quiet. The two runs use different scratch roots
# and their paths therefore differ, so the comparison is over the verdict and
# the counters, never over the bytes.
build_fixture
run_fixture_verify
S6_NOCAP_RC="$rc"
S6_NOCAP_COUNTERS="$(summary_counters "$OUT")"

build_capture_fixture empty
run_fixture_verify
cp -- "$OUT" "$CAP_A"
S6_EMPTY_RC="$rc"
S6_EMPTY_COUNTERS="$(summary_counters "$CAP_A")"

S6_EMPTY_LINES="$(capture_tree_lines "$CAP_A")"
if [[ -z "$S6_EMPTY_LINES" ]]; then
  pass "6 VER-02 (empty): a capture/ tree holding only its README and no package directories emits no capture-tree line at all -- the block is vacuous by design on a tree shaped like today's, and saying so explicitly is what stops that vacuity from being read as coverage"
else
  fail "6 VER-02 (empty): a package-less capture/ tree emitted capture-tree lines -- the block walked something it should not have"
  printf '%s\n' "$S6_EMPTY_LINES" | sed 's/^/       /' >&2 || true
fi

if [[ "$S6_EMPTY_RC" -eq "$S6_NOCAP_RC" ]] && [[ "$S6_EMPTY_COUNTERS" == "$S6_NOCAP_COUNTERS" ]]; then
  pass "6 VER-02 (empty): the package-less capture/ tree leaves rc and both counters exactly as the same fixture built with no capture/ directory at all (rc=$S6_EMPTY_RC, counters '$S6_EMPTY_COUNTERS') -- it cannot change the verdict"
else
  fail "6 VER-02 (empty): the package-less capture/ tree changed the verdict (rc $S6_NOCAP_RC -> $S6_EMPTY_RC, counters '$S6_NOCAP_COUNTERS' -> '$S6_EMPTY_COUNTERS')"
  sed 's/^/       /' < "$CAP_A" >&2 || true
fi

# --- case 5: listing order is stable across two consecutive runs -------------
# The capture/ walk enumerates with the same `find ... -print0 | LC_ALL=C sort -z`
# idiom as the repo-side walk, so this is a regression guard on that idiom rather
# than a discovery.
build_capture_fixture ordering
run_fixture_verify
capture_tree_lines "$OUT" > "$CAP_A"
run_fixture_verify
capture_tree_lines "$OUT" > "$CAP_B"
if [[ -s "$CAP_A" ]] && cmp -s "$CAP_A" "$CAP_B"; then
  pass "6 VER-02 (ordering): a capture/ package holding several files lists them in the same order on two consecutive runs over an unchanged tree ($(wc -l < "$CAP_A") capture-tree lines, identical)"
else
  fail "6 VER-02 (ordering): the capture-tree listing is empty or reordered itself between two consecutive runs over an unchanged tree"
  diff -u "$CAP_A" "$CAP_B" || true
fi


# =============================================================================
# Section 7 / ROADMAP criterion 4 -- both branches of the installer's auto-backup
# primitive, and D-47 proven read-only (D-32, D-33, D-47).
#
# The primitive branches on ONE flag and its two arms land on OPPOSITE sides of
# the link/content boundary. Firstrun renames the target aside and copies a
# fresh regular file into its place: on a stowed path the link is DESTROYED and
# a suffixed sibling appears beside it. Non-firstrun copies alongside instead:
# the link is INTACT and a differently-suffixed sibling appears. One branch is a
# loud failure; the other is a silent survivor that only the sweep's
# artifact-shape arm reports at all. That contrast is this section's point.
#
# Both branches are reproduced with PLAIN SHELL COMMANDS inside the fixture.
# Nothing here sources, executes, reads or stats anything under the vendored
# submodule: D-47 requires `verify` to run with it de-initialised and this
# assert holds the same line. The primitive's two effects were read out of the
# vendor file once, by a human, and staged by hand.
#
# MEASURED DEVIATION FROM D-32, recorded here rather than papered over.
# D-32 predicts the firstrun branch's `.old` sibling lands on an [INFO] line
# naming it an installer backup artifact. On a STOWED path it does not, and
# cannot: `mv` renames the SYMLINK itself, so the sibling is a symlink into the
# repo at a path the repo never declared, and the sweep classifier tests -L
# before it reaches the artifact-shape arm -- so arm 2 claims it first and it is
# a [FAIL], not an [INFO]. Measured on a scratch fixture during execution of
# plan 19-04:
#     [FAIL] not a symlink: .../home/.config/fixpkg/conf - recover with: ...
#     [FAIL] stale link into repo at an undeclared path:
#            .../home/.config/fixpkg/conf.old -> .../repo/stow/.../conf
#     === done: FAIL=2 FINDINGS=0 ===
# The assertion below therefore encodes what the primitive actually produces.
# This is louder than D-32 predicted, not quieter, and the firstrun branch stays
# the loud half of the contrast. The artifact-shape [INFO] that D-32 wanted from
# the `.old` suffix is asserted where the primitive really produces one: on the
# UNSTOWED target in the shared root below, which is the shape all nineteen
# artifacts on the real tree have.
# =============================================================================
echo "=== Section 7 / ROADMAP criterion 4: both branches of the installer auto-backup primitive, and D-47 read-only ==="

# ---------------------------------------------------------------------------
# build_backup_fixture -- build_fixture's mechanics with a package declaring one
# file in a package-owned directory at depth two below the scratch $HOME and one
# file directly in the shared root, so a sibling artifact can be staged in each
# and the arm-ordering property can be exercised on both.
#
# Both placements matter and the shared-root one is the regression guard: the
# classifier tests the artifact-shape arm BEFORE the shared-root exemption, and
# research measured five of the nineteen installer artifacts on the real tree
# living in the two shared roots. Invert those two arms and those five vanish
# from the report while every other assertion in this script still passes.
# ---------------------------------------------------------------------------
build_backup_fixture() {
  T="$(mktemp -d /tmp/p19-backup-XXXXXX)"
  SCRATCH_ROOTS+=("$T"); trap cleanup EXIT   # D-30: before the first write
  T_REAL="$(realpath -- "$T")"               # D-26: captured at setup

  mkdir -p "$T/repo/arch" "$T/repo/stow/backupfix/.config/backuppkg" \
           "$T/home/.config/backuppkg"
  cp -- "$REPO_ROOT/arch/dots-hyprland.sh" "$T/repo/arch/dots-hyprland.sh"
  chmod +x "$T/repo/arch/dots-hyprland.sh"
  printf 'mine\n' > "$T/repo/stow/backupfix/.config/backuppkg/app.conf"
  printf 'mine-shared\n' > "$T/repo/stow/backupfix/.config/shared.conf"

  git -c init.defaultBranch=main init -q "$T/repo"
  git -C "$T/repo" config user.name "GSD Assert"
  git -C "$T/repo" config user.email "assert@local"
  git -C "$T/repo" add -A
  git -C "$T/repo" -c commit.gpgsign=false commit -q -m "auto-backup fixture initial state"

  ( cd "$T/repo/stow" && stow --no-folding -t "$T/home" backupfix )

  # Upstream's payload, staged outside both the repo and the scratch home so the
  # copies below are unambiguously "new content arriving from the installer".
  mkdir -p "$T/vendorpayload"
  printf 'upstream\n' > "$T/vendorpayload/app.conf"

  RUN_REPO="$T/repo"
  RUN_HOME="$T/home"
}

# --- branch 1: firstrun -- rename the target aside, copy a fresh file in ------
build_backup_fixture
S7_LIVE="$T/home/.config/backuppkg/app.conf"
S7_OLD="$T/home/.config/backuppkg/app.conf.old"

# The primitive's firstrun effect, by hand: `mv $t $t.old` then `cp $s $t`.
guard_scratch_target "$S7_LIVE" || exit 1
mv -- "$S7_LIVE" "$S7_OLD"
cp -f -- "$T/vendorpayload/app.conf" "$S7_LIVE"

# The same primitive's firstrun effect on an UNSTOWED target in the shared root:
# the original was a regular file, so the sibling it leaves behind is a regular
# file too. This is the shape every installer artifact on the real tree has, and
# it is the one that exercises the artifact-shape arm against the shared-root
# exemption.
printf 'upstream\n' > "$T/home/.config/upstream-thing.conf"
printf 'theirs-previous\n' > "$T/home/.config/upstream-thing.conf.old"
S7_SHARED_OLD="$T/home/.config/upstream-thing.conf.old"

if [[ ! -L "$S7_LIVE" && -f "$S7_LIVE" && -L "$S7_OLD" ]]; then
  pass "7 D-32 firstrun fixture: the stowed link was renamed aside and a plain regular file now sits at $S7_LIVE -- the destroying arm really destroyed something"
else
  fail "7 D-32 firstrun fixture: $S7_LIVE is not a plain regular file, or $S7_OLD is not the renamed link -- this fixture is not staging the firstrun branch"
  ls -la -- "$T/home/.config/backuppkg" >&2 || true
fi

run_fixture_verify
cp -- "$OUT" "$CAP_A"
S7_FIRSTRUN_RC="$rc"
S7_FIRSTRUN_COUNTERS="$(summary_counters "$CAP_A")"

S7_FAIL_LINE="$(grep '^\[FAIL\]' "$CAP_A" | grep -F -- "$S7_LIVE" | grep -F -- 'not a symlink' | head -1 || true)"
if [[ -n "$S7_FAIL_LINE" ]] \
   && printf '%s\n' "$S7_FAIL_LINE" | grep -q -F -- 'stow -t' \
   && printf '%s\n' "$S7_FAIL_LINE" | grep -q -F -- 'backupfix'; then
  pass "7 D-32/D-33 firstrun: the destroyed link is a [FAIL] stating it is not a symlink, and the line carries a stow -t recovery invocation naming the package: $S7_LIVE"
else
  fail "7 D-32/D-33 firstrun: no [FAIL] names $S7_LIVE as not a symlink together with a stow -t recovery invocation naming the package -- a failure the operator cannot act on"
  sed 's/^/       /' < "$CAP_A" >&2 || true
fi

if grep '^\[FAIL\]' "$CAP_A" | grep -F -- "$S7_OLD" | grep -q -F -- 'stale link into repo at an undeclared path'; then
  pass "7 D-32 firstrun (measured, not as D-32 predicted): the renamed-aside sibling is itself a symlink into the repo, so the sweep's arm 2 claims it as a stale link at an undeclared path before the artifact-shape arm is ever reached: $S7_OLD"
else
  fail "7 D-32 firstrun: $S7_OLD is on no [FAIL] naming it a stale link into the repo at an undeclared path -- mv renames the link itself, so this sibling IS a link and the classifier must say so"
  sed 's/^/       /' < "$CAP_A" >&2 || true
fi

if grep '^\[INFO\]' "$CAP_A" | grep -F -- "$S7_SHARED_OLD" | grep -q -F -- 'installer backup artifact'; then
  pass "7 D-32/D-05 arm ordering: the regular-file backup sibling sitting in the SHARED ROOT is still named on an [INFO] installer-backup-artifact line: $S7_SHARED_OLD -- the artifact-shape arm runs before the shared-root exemption, and inverting them would silence five of the nineteen artifacts on the real tree"
else
  fail "7 D-32/D-05 arm ordering: no [INFO] names $S7_SHARED_OLD as an installer backup artifact -- the shared-root exemption swallowed it, which is the exact arm inversion the ordering exists to prevent"
  sed 's/^/       /' < "$CAP_A" >&2 || true
fi

if [[ "$S7_FIRSTRUN_RC" -eq 1 ]] && [[ "$S7_FIRSTRUN_COUNTERS" == "2 0" ]]; then
  pass "7 D-32 firstrun: the destroying branch exits 1 and summarises FAIL=2 FINDINGS=0 (rc=$S7_FIRSTRUN_RC) -- the destroyed link and the link renamed aside with it, counted once each"
else
  fail "7 D-32 firstrun: the destroying branch exited $S7_FIRSTRUN_RC with counters '$S7_FIRSTRUN_COUNTERS', expected 1 and '2 0'"
  sed 's/^/       /' < "$CAP_A" >&2 || true
fi

# --- branch 2: non-firstrun -- copy alongside, leave the target alone --------
# Its own fixture, so neither branch can mask the other.
build_backup_fixture
S7_LIVE2="$T/home/.config/backuppkg/app.conf"
S7_NEW="$T/home/.config/backuppkg/app.conf.new"

# The primitive's non-firstrun effect, by hand: `cp $s $t.new`, and $t untouched.
cp -f -- "$T/vendorpayload/app.conf" "$S7_NEW"

if [[ -L "$S7_LIVE2" && -f "$S7_NEW" && ! -L "$S7_NEW" ]]; then
  pass "7 D-32 non-firstrun fixture: the stowed link is INTACT and a plain regular sibling sits beside it at $S7_NEW -- the surviving arm really survived"
else
  fail "7 D-32 non-firstrun fixture: $S7_LIVE2 is not still a symlink, or $S7_NEW is not a plain regular file -- this fixture is staging the firstrun branch, not the non-firstrun one"
  ls -la -- "$T/home/.config/backuppkg" >&2 || true
fi

run_fixture_verify
cp -- "$OUT" "$CAP_B"
S7_NONFIRST_RC="$rc"
S7_NONFIRST_COUNTERS="$(summary_counters "$CAP_B")"

if grep '^\[PASS\]' "$CAP_B" | grep -q -F -- "$S7_LIVE2"; then
  pass "7 D-32 non-firstrun: the live path is still on a [PASS] line: $S7_LIVE2 -- this branch never touched the link, and every link assertion passes"
else
  fail "7 D-32 non-firstrun: $S7_LIVE2 is absent from any [PASS] line -- a branch that copies ALONGSIDE the link was reported as a link failure"
  sed 's/^/       /' < "$CAP_B" >&2 || true
fi

if grep '^\[INFO\]' "$CAP_B" | grep -F -- "$S7_NEW" | grep -q -F -- 'installer backup artifact'; then
  pass "7 D-32 non-firstrun: the sibling in a package-owned directory is named on an [INFO] installer-backup-artifact line: $S7_NEW -- the sweep's artifact arm is the only thing in the whole run that reports this branch at all"
else
  fail "7 D-32 non-firstrun: no [INFO] names $S7_NEW as an installer backup artifact -- the silent-survivor branch is completely invisible, which is the condition it exists to make visible"
  sed 's/^/       /' < "$CAP_B" >&2 || true
fi

if [[ "$S7_NONFIRST_RC" -eq 0 ]] && [[ "$S7_NONFIRST_COUNTERS" == "0 0" ]]; then
  pass "7 D-32 non-firstrun: the surviving branch exits 0 and summarises FAIL=0 FINDINGS=0 (rc=$S7_NONFIRST_RC) -- the same primitive, one flag apart, on the opposite side of the link/content boundary from the branch above"
else
  fail "7 D-32 non-firstrun: the surviving branch exited $S7_NONFIRST_RC with counters '$S7_NONFIRST_COUNTERS', expected 0 and '0 0' -- an [INFO] moved a counter"
  sed 's/^/       /' < "$CAP_B" >&2 || true
fi

# ---------------------------------------------------------------------------
# D-47, proven read-only: against run_verify()'s own source text and against a
# scratch fixture, and NEVER against the operator's real submodule.
#
# The real submodule is not de-initialised here, and no verify command in this
# phase de-initialises it either. That form discards local submodule
# modifications on its way out, and a restore that is tolerated is invisible
# when it fails -- leaving the daily-driver checkout broken while the command
# still reports success, inside a phase whose entire discipline is a
# `git status --porcelain --ignored` bracket proving nothing moved. The scratch
# fixture answers the identical question without touching it.
#
# What the fixture DOES reproduce: the on-disk shape a de-initialised submodule
# leaves behind -- a committed `.gitmodules` entry naming the vendored path, and
# that path present as an EMPTY directory. Those two are the whole of what
# run_verify() could observe about the submodule.
#
# What it deliberately does NOT stage: the index gitlink for that path. Nothing
# in run_verify() reads the index for it -- the static gate immediately below
# asserts exactly that, against the function's own body -- so staging a gitlink
# would add a fixture detail that no code path can see and would imply a
# dependency the source text says does not exist.
# ---------------------------------------------------------------------------
S7_BODY="$(sed -n '/^run_verify()/,/^}/p' arch/dots-hyprland.sh | grep -v '^[[:space:]]*#' || true)"
if [[ -z "$S7_BODY" ]]; then
  fail "7 D-47 static gate: run_verify()'s body could not be extracted from arch/dots-hyprland.sh -- the function's boundaries moved and this gate would otherwise scan nothing and pass"
elif printf '%s\n' "$S7_BODY" | grep -q -F -- "$VENDOR_PATH"; then
  fail "7 D-47 static gate: run_verify()'s body names the vendored submodule path -- verify has taken a dependency on a directory that may be de-initialised"
  printf '%s\n' "$S7_BODY" | grep -F -- "$VENDOR_PATH" | sed 's/^/       /' >&2 || true
elif printf '%s\n' "$S7_BODY" | grep -q -F -- 'preflight'; then
  fail "7 D-47 static gate: run_verify()'s body calls preflight -- the subcommand routes through the vendored setup path it is required to stay clear of"
  printf '%s\n' "$S7_BODY" | grep -F -- 'preflight' | sed 's/^/       /' >&2 || true
else
  pass "7 D-47 static gate: run_verify()'s own body ($(printf '%s\n' "$S7_BODY" | wc -l) non-comment lines) names neither the vendored submodule path nor preflight"
fi

# ---------------------------------------------------------------------------
# build_d47_fixture -- a clean stowed fixture carrying, additionally, the
# on-disk shape of a de-initialised submodule. Sets T, T_REAL, RUN_REPO and
# RUN_HOME exactly as build_fixture does, plus D47_GITMODULES and D47_VENDOR_DIR.
# ---------------------------------------------------------------------------
D47_GITMODULES=""
D47_VENDOR_DIR=""
build_d47_fixture() {
  T="$(mktemp -d /tmp/p19-d47-XXXXXX)"
  SCRATCH_ROOTS+=("$T"); trap cleanup EXIT   # D-30: before the first write
  T_REAL="$(realpath -- "$T")"               # D-26: captured at setup

  mkdir -p "$T/repo/arch" "$T/repo/stow/fixture/.config/fixpkg" "$T/home/.config/fixpkg"
  cp -- "$REPO_ROOT/arch/dots-hyprland.sh" "$T/repo/arch/dots-hyprland.sh"
  chmod +x "$T/repo/arch/dots-hyprland.sh"
  printf 'v1\n' > "$T/repo/stow/fixture/.config/fixpkg/conf"

  D47_GITMODULES="$T/repo/.gitmodules"
  D47_VENDOR_DIR="$T/repo/$VENDOR_PATH"
  {
    printf '[submodule "%s"]\n' "$VENDOR_PATH"
    printf '\tpath = %s\n' "$VENDOR_PATH"
    printf '\turl = git@example.invalid:scratch/fixture.git\n'
  } > "$D47_GITMODULES"
  # Present, and EMPTY -- which is what a de-initialised submodule leaves on
  # disk. git cannot track an empty directory, so it survives the commit below
  # as a directory with no entries rather than as a gitlink.
  mkdir -p "$D47_VENDOR_DIR"

  git -c init.defaultBranch=main init -q "$T/repo"
  git -C "$T/repo" config user.name "GSD Assert"
  git -C "$T/repo" config user.email "assert@local"
  git -C "$T/repo" add -A
  git -C "$T/repo" -c commit.gpgsign=false commit -q -m "d47 fixture: committed .gitmodules beside an empty vendored directory"

  ( cd "$T/repo/stow" && stow --no-folding -t "$T/home" fixture )

  RUN_REPO="$T/repo"
  RUN_HOME="$T/home"
}

build_d47_fixture

if git -C "$RUN_REPO" ls-files --error-unmatch -- .gitmodules >/dev/null 2>&1 \
   && [[ -d "$D47_VENDOR_DIR" ]] \
   && [[ -z "$(ls -A -- "$D47_VENDOR_DIR" 2>/dev/null || true)" ]]; then
  pass "7 D-47 fixture: the scratch repo carries a COMMITTED .gitmodules naming the vendored path beside that path as an EMPTY directory -- the on-disk shape of a de-initialised submodule, staged without touching the real one"
else
  fail "7 D-47 fixture: the scratch repo does not carry a committed .gitmodules plus an empty vendored directory -- the runtime half of D-47 would prove nothing"
  git -C "$RUN_REPO" ls-files | sed 's/^/       /' >&2 || true
fi

run_fixture_verify
if [[ "$rc" -eq 0 ]]; then
  pass "7 D-47 runtime: verify runs to exit 0 over a repo whose vendored submodule directory is present and empty with its .gitmodules entry committed (rc=$rc) -- the subcommand reads the repo's own trees and the live filesystem and nothing else"
else
  fail "7 D-47 runtime: verify exited $rc over the de-initialised-submodule fixture, expected 0 -- verify has a dependency on the vendored submodule that the static gate above could not see"
  sed 's/^/       /' < "$OUT" >&2 || true
  sed 's/^/       /' < "$ERR" >&2 || true
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
echo "Criterion 2 (capture/ drift as its own finding class): Section 6 -- a staged capture/ package with drifted content is a [FINDING] and never a [FAIL], its absent-live-counterpart sibling is the phase's only other [FINDING], a live path that is a symlink into the repo is a [FAIL] under the inverted expectation, and a package-less capture/ tree (the shape of the real tree today) emits no capture-tree line and changes neither counter"
echo "Criterion 3 (exit 0/1/2, --strict promotion, frozen output contract): Sections 1, 2 and 3 (exit 0/1, closed flag surface and exit 2, flag-invariant scope); the findings-only --strict promotion: Section 6 -- one fixture, FINDINGS asserted by exact number, exit 0 bare and exit 1 under --strict with FAIL=0 in both and byte-identical output above the summary line"
echo "Criterion 4 (adversarial rsync -a --delete and its negative control): Section 1; cp-through class: Section 4; the installer auto-backup primitive, both branches, and D-47 proven read-only from the run_verify() body text plus a scratch de-initialised-submodule fixture: Section 7"
echo "Criterion 5 (green on today's tree, repo-vs-HEAD [INFO], unclaimed stub [INFO]): repo-vs-HEAD [INFO] and its untracked-file extension: Section 4; green-on-today's-tree and the unclaimed-stub [INFO] pending -- plan 19-04"

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
