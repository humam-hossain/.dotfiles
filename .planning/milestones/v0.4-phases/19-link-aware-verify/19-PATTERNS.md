# Phase 19: link-aware-verify - Pattern Map

**Mapped:** 2026-09-14
**Files analyzed:** 5 (1 new, 4 modified)
**Analogs found:** 5 / 5

All analog paths below were confirmed git-TRACKED (`git ls-files`). No gitignored
mirror paths appear in this document.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `arch/dots-hyprland.sh` `run_verify()` (modify, lines 737-845) | subcommand handler / verifier | request-response (argv → labelled report → exit code) | itself (Phase 18 loop) + `scripts/phase14-verify.sh` | exact |
| `scripts/phase19-link-aware-verify-assert.sh` (new) | test / phase assert | batch (fixture → run under test → assertions) | `scripts/phase18-capture-model-assert.sh` | exact |
| `scripts/phase19-…-assert.sh` fixture builder (new, internal) | test fixture factory | file-I/O | `scripts/phase18-capture-model-assert.sh` Section 7b (lines 743-790) | exact |
| `scripts/phase13-d19-assert.sh` (modify, wrapper drift pin) | test / drift guard | transform (commit → diff verdict) | itself (lines 236-269) | exact |
| `.planning/research/PITFALLS.md` (modify, A-6 extension) | documentation | — | existing A-6 entry | exact |

`scripts/phase17-unblock-assert.sh` is **not** a source to copy from — it uses a
different output contract (`=== done: FAIL=n ===`, three prefixes, one counter).
It is listed below only as a *coupling* to avoid breaking.

## Pattern Assignments

### `arch/dots-hyprland.sh` — `run_verify()` (modify)

**Analog:** itself + `scripts/phase14-verify.sh` (contract source of truth)

**Flag parser to widen** — current form, `arch/dots-hyprland.sh:738-756`. D-19 adds
`--strict` / `--quiet` arms; D-15 changes the `exit 1` to `exit 2`:

```bash
run_verify() {
  local -a unknown=()
  local arg
  for arg in "$@"; do
    case "$arg" in
      -h|--help)
        usage
        exit 0
        ;;
      *)
        unknown+=("$arg")
        ;;
    esac
  done

  if ((${#unknown[@]} > 0)); then
    echo "[FAIL] Unknown verify flag(s): ${unknown[*]}" >&2
    echo "[FAIL] See: ./arch/dots-hyprland.sh help" >&2
    exit 1
  fi
```

Copy the `>&2` + `exit` shape verbatim for D-17's precondition block, which is
inserted immediately below this parser (satisfies D-12's positional rule and
D-17's no-summary rule in one placement).

**Counter/emitter contract** — `arch/dots-hyprland.sh:759-763`. Do **not** add a
third counter (D-18); the new sweep appends to these two:

```bash
  local fail_count=0
  local finding_count=0
  pass() { printf '[PASS] %s\n' "$1"; }
  fail() { printf '[FAIL] %s\n' "$1"; fail_count=$((fail_count + 1)); }
  finding() { printf '[FINDING] %s\n' "$1"; finding_count=$((finding_count + 1)); }
  info() { printf '[INFO] %s\n' "$1"; }
```

`--quiet` is implemented by making `pass()` conditional — the counters and every
other emitter stay untouched (D-20, D-13). Note the `n=$((n + 1))` form: `((n++))`
aborts under the file's `set -euo pipefail`.

**Repo-root resolution** — `arch/dots-hyprland.sh:715-722`, unchanged. Supplies
D-21's `-C` argument and the `"$main_root"/*` repo-prefix criterion for D-03/D-06:

```bash
get_main_repo_root() {
  local common_dir
  if common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
    dirname "$common_dir"
  else
    printf '%s\n' "$REPO_ROOT"
  fi
}
```

**Tree-walk / deterministic-ordering idiom** — `arch/dots-hyprland.sh:770-808`.
The new D-01 root-set derivation reuses this exact loop skeleton (D-07 forbids
editing the loop body itself, but the *shape* is what the sweep copies):

```bash
  for tree in stow restow; do
    local tree_dir="$REPO_ROOT/$tree"
    [[ -d "$tree_dir" ]] || continue
    for pkg_dir in "$tree_dir"/*; do
      [[ -d "$pkg_dir" ]] || continue
      pkg="$(basename "$pkg_dir")"
      while IFS= read -r -d '' file_path; do
        rel="${file_path#"$pkg_dir"/}"
        live="$HOME/$rel"
        canonical_repo="$main_root/$tree/$pkg/$rel"
        ...
      done < <(find "$pkg_dir" -type f -print0 | LC_ALL=C sort -z)
    done
  done
```

**Link-before-content test + recovery-message format** — `arch/dots-hyprland.sh:781-806`.
The new sweep's `[FAIL]` lines must match this message shape (D-33 asserts the
`stow -t` recovery invocation is present and names the right package):

```bash
        if [[ ! -e "$live" && ! -L "$live" ]]; then
          fail "no live counterpart: $live — recover with: cd $tree && stow -t ~ $pkg"
          continue
        fi
        if [[ ! -L "$live" ]]; then
          fail "not a symlink: $live — recover with: cd $tree && stow -t ~ $pkg"
          continue
        fi

        local live_target repo_target
        live_target="$(readlink -f -- "$live" || true)"
        repo_target="$(readlink -f -- "$canonical_repo" || true)"
        if [[ "$live_target" != "$repo_target" ]]; then
          fail "symlink points elsewhere: $live -> $live_target (expected $repo_target) — recover with: cd $tree && stow -t ~ $pkg"
          continue
        fi

        pass "verified: $live -> $canonical_repo"
```

Note `local x; x="$(cmd)"` is split across two statements so `local` does not
swallow the exit status — keep that in new code.

**`capture/` inverted-expectation block (D-22, preserve unchanged)** —
`arch/dots-hyprland.sh:812-838`. This is also the `[FINDING]`-emitting code the
D-35 findings-only fixture must exercise:

```bash
        if [[ -L "$live" ]]; then
          local live_target
          live_target="$(readlink -f -- "$live" || true)"
          if [[ "$live_target" == "$main_root"/* || "$live_target" == "$REPO_ROOT"/* ]]; then
            fail "live path is a symlink into repo: $live -> $live_target (wrongly stowed)"
            continue
          fi
        fi

        if [[ ! -e "$live" && ! -L "$live" ]]; then
          finding "live counterpart does not exist: $live"
          continue
        fi

        if ! cmp -s -- "$live" "$canonical_repo"; then
          finding "content drift between live and repo: $live"
        else
          pass "capture path verified: $live"
        fi
```

**Summary + exit (D-18 frozen, D-13 one-line change)** — `arch/dots-hyprland.sh:840-845`:

```bash
  echo "=== done: FAIL=$fail_count FINDINGS=$finding_count ==="
  if ((fail_count > 0)); then
    exit 1
  fi
  exit 0
```

D-13 changes only the condition to
`if ((fail_count > 0)) || { ((strict)) && ((finding_count > 0)); }`. The `echo`
line above it is byte-frozen (D-14, D-18).

**Usage text to extend** — `arch/dots-hyprland.sh:25-32`, a quoted `cat <<'EOF'`
heredoc. The line `  arch/dots-hyprland.sh verify` at line 32 gains the three
flags. Note the file's `ALLOWLIST` at line 17 already contains `verify`; no
dispatch change is needed (`arch/dots-hyprland.sh:1112-1114`).

---

### `scripts/phase19-link-aware-verify-assert.sh` (new; test, batch)

**Analog:** `scripts/phase18-capture-model-assert.sh` — same contract (4 prefixes,
2 counters), same prologue, same fixture discipline, same closing self-check.

**Prologue + contract header** — `scripts/phase18-capture-model-assert.sh:1-44`.
Copy this whole shape, swapping the phase-specific constraint prose:

```bash
#!/usr/bin/env bash
# Phase 18 capture model asserts (D-57).
# One script, one section per ROADMAP criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase18-capture-model-assert.sh
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.
#
# Constraints (Phase 18):
#   - Fixtures live under `mktemp`/`mktemp -d` outside the repo and are removed
#     by an EXIT trap set immediately after creation, so a failing check cannot
#     leave one behind (D-56, and the Phase 17 incident recorded in STATE.md).
#   - Contract (D-49): FOUR prefixes [PASS] [FAIL] [FINDING] [INFO] and TWO
#     counters, copied from the sibling scripts/phase14-verify.sh:24-41.
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
```

Note the assert scripts use UPPERCASE counters (`FAIL`/`FINDINGS`) while
`run_verify()` uses lowercase (`fail_count`/`finding_count`). Keep the uppercase
form here.

**Fixture declaration + cleanup trap (D-30)** — `scripts/phase18-capture-model-assert.sh:59-83`.
Trap set immediately after the last `mktemp`, before any write; `cleanup()` ends
with `return 0` so a failed `rm` cannot poison the exit status:

```bash
PORCELAIN_BEFORE="$(mktemp /tmp/p18-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p18-porcelain-after-XXXXXX)"
FAKE_ROOT="$(mktemp -d /tmp/p18-fakeroot-XXXXXX)"
FIX_HOME_7B=""
cleanup() {
  rm -f "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"
  rm -rf "$FAKE_ROOT"
  [[ -n "$FIX_HOME_7B" ]] && rm -rf "$FIX_HOME_7B"
  return 0
}
trap cleanup EXIT

git status --porcelain > "$PORCELAIN_BEFORE"
```

Phase 19 changes the naming prefix to `p19-` and, per RESEARCH Pitfall 4, should
use `git status --porcelain --ignored` with a known-prefix filter so the bracket
is not blind under `restow/kdeglobals/`.

**Scratch-repo fixture builder — the primary analog for D-24 / D-28 / Pitfall 1** —
`scripts/phase18-capture-model-assert.sh:747-792`. This already solves all three
roots (copied wrapper → `REPO_ROOT`; `cd` into the scratch repo → `git rev-parse`;
`HOME=` override → live side). Copy it near-verbatim:

```bash
FIX_HOME_7B="$(mktemp -d /tmp/p18-fix7b-XXXXXX)"
FIX_REPO_7B="$FIX_HOME_7B/fixture-repo"

git init -q "$FIX_REPO_7B"
git -C "$FIX_REPO_7B" config user.name "GSD Assert"
git -C "$FIX_REPO_7B" config user.email "assert@local"

mkdir -p "$FIX_REPO_7B/arch" "$FIX_REPO_7B/capture/testpkg/.config/testpkg"
cp "$REPO_ROOT/arch/dots-hyprland.sh" "$FIX_REPO_7B/arch/dots-hyprland.sh"
chmod +x "$FIX_REPO_7B/arch/dots-hyprland.sh"

mkdir -p "$FIX_HOME_7B/.config/testpkg"
...
git -C "$FIX_REPO_7B" add .
git -C "$FIX_REPO_7B" commit -q -m "initial fixture state"
...
CAP_7B_RC=0
CAP_7B_OUT="$(cd "$FIX_REPO_7B" && HOME="$FIX_HOME_7B" ./arch/dots-hyprland.sh capture 2>&1)" || CAP_7B_RC=$?
```

Two Phase-19 deltas on this analog:
1. The scratch **repo lives inside** the scratch `$HOME` here (`$FIX_HOME_7B/fixture-repo`).
   D-24 and RESEARCH Pitfall 2 want a single `mktemp -d` root with `repo/` and
   `home/` as **siblings** so GNU Stow's relative links stay short and D-26 has
   one prefix to guard. Adjust the layout; keep the `git init` / `cd` / `HOME=`
   invocation mechanics exactly.
2. D-37 requires stdout and stderr **separate**, not `2>&1` as above:
   `rc=0; ( cd "$T/repo" && HOME="$T/home" ./arch/dots-hyprland.sh verify "$@" ) >"$OUT" 2>"$ERR" || rc=$?`

**Exit-code capture + failure-diagnostic idiom** —
`scripts/phase18-capture-model-assert.sh:701-711`. Every non-zero-expecting call
uses `RC=0; OUT="$(...)" || RC=$?`, and a `fail()` dumps the captured output
indented to stderr:

```bash
VERIFY_RC=0
VERIFY_OUT="$(./arch/dots-hyprland.sh verify 2>&1)" || VERIFY_RC=$?
if grep -q -- "setup verify" <<<"$VERIFY_OUT" || grep -q '\./setup' <<<"$VERIFY_OUT"; then
  fail "7a ./arch/dots-hyprland.sh verify reached upstream setup dispatch (catch-all reached)"
  printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
else
  pass "7a ./arch/dots-hyprland.sh verify dispatched to wrapper handler (rc=$VERIFY_RC, never named ./setup)"
fi
```

This is also the closest analog for D-36's read-only real-tree run — the same
invocation, asserting `rc -eq 0`.

**Closing self-check (D-38) + fixture-leak sweep** —
`scripts/phase18-capture-model-assert.sh:981-1003`. Copy the whole block:

```bash
echo "=== Closing self-check: working tree unchanged ==="

git status --porcelain > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "self-check: git status --porcelain is identical before and after this run"
else
  fail "self-check: git status --porcelain changed during this run -- something here mutated the working tree"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi
FIXTURE_LEAK=0
for FIXTURE in "$REGEN_OUT" "$FAKE_ROOT" "$FIX_HOME_7B"; do
  [[ -z "$FIXTURE" ]] && continue
  if grep -q -F -- "$(basename "$FIXTURE")" "$PORCELAIN_AFTER"; then
    fail "self-check: git status names a path this script created: $FIXTURE"
    FIXTURE_LEAK=$((FIXTURE_LEAK + 1))
  fi
done
if [[ "$FIXTURE_LEAK" -eq 0 ]]; then
  pass "self-check: git status names no fixture path this script created (all fixtures live outside the repo or are removed by the EXIT trap)"
fi
```

**Criteria summary + close** — `scripts/phase18-capture-model-assert.sh:1005-1019`:

```bash
echo "=== Phase 18 ROADMAP Criteria Summary ==="
echo "Criterion 1 (...): Section 1"
...
echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

**Vacuity guard** — `scripts/phase18-capture-model-assert.sh:86-95` (shape credited
to `scripts/phase17-unblock-assert.sh:54-71`). Every check that could pass over
nothing is preceded by a presence/count guard. D-31's missing-`stow`/-`rsync`
`[FAIL]` is this same pattern applied to binaries.

---

### `scripts/phase13-d19-assert.sh` (modify — wrapper drift re-pin)

**Analog:** itself, lines 236-269. Phase 19 edits `arch/dots-hyprland.sh`, so the
pin must gain a new **first** tier. The ordering comment is load-bearing: the
newest marker is tested first, because every older marker file still exists.

```bash
# ORDERING IS LOAD-BEARING: the newest marker must be tested FIRST. 14-LIVE-VERIFY.md
# and 16-DOC-SWEEP.md both still exist, so a branch placed after their tests would
# never fire.
#
# git diff <BASE> -- <path> compares BASE against the WORKING TREE, not HEAD. So
# each pin names a commit whose blob is byte-identical to the working tree at the
# time it was written, and no later plan may touch arch/dots-hyprland.sh without
# re-pinning here.
if [ -f "$PHASE17_ASSERT" ]; then
  WRAPPER_BASE="8497511"   # fix(18-05): capture model wrapper-owned subcommands
elif [ -f "$DOC_SWEEP_16" ]; then
  WRAPPER_BASE="cfa63ad"   # fix(16): close C-01/H-01 from the phase 16 review
...
if ! git cat-file -e "${WRAPPER_BASE}^{commit}" 2>/dev/null; then
  printf '[INFO] %s\n' "arch/dots-hyprland.sh: baseline $WRAPPER_BASE not in this repo; drift not checked"
elif [ -z "$(git diff --name-only "$WRAPPER_BASE" -- arch/dots-hyprland.sh)" ]; then
  pass "arch/dots-hyprland.sh unmodified since $WRAPPER_BASE"
else
  fail "arch/dots-hyprland.sh changed since $WRAPPER_BASE"
fi
```

Existing marker variables, for the new one to match style
(`scripts/phase13-d19-assert.sh:43, 188, 191`):
`DOC_SWEEP_16="$(phase_artifact '16-…/16-DOC-SWEEP.md')"`,
`PHASE17_ASSERT="scripts/phase17-unblock-assert.sh"`. The Phase 19 tier should key
on `scripts/phase19-link-aware-verify-assert.sh` and be inserted as the **first**
branch. Re-pin in the same commit that lands the wrapper edit, or the repo is red
between commits.

---

### `.planning/research/PITFALLS.md` (modify — D-43)

**Analog:** the existing A-6 entry at §100-115 in that same file. Append the Q3
measurement (mechanism, `git_status_polls=2000 / hits=11`, device-`66311`
same-filesystem caveat) in the entry's existing prose style. No `.gitignore` rule
ships (RESEARCH recommendation; D-41's anchoring condition is unmet).

## Shared Patterns

### Output contract (four labels, two counters) — applies to BOTH files
**Source:** `scripts/phase14-verify.sh:24-41` (source of truth), mirrored at
`arch/dots-hyprland.sh:759-763` and `scripts/phase18-capture-model-assert.sh:38-44`.

```bash
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
```

Closing lines, same file (last 5 lines) — frozen verbatim (D-18):

```bash
echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
```

### Governing principle — applies to every new `[PASS]`/`[INFO]` decision
**Source:** `scripts/phase14-verify.sh:10-14`

```
#   - Never reports a [PASS] for a condition it could not observe. An unobservable
#     condition emits [INFO] or [FINDING], never a pass and never a silent skip.
#     The same rule runs in the other direction: an unobservable condition is never
#     reported as a specific defect either. A compositor this script cannot reach
#     produces ONE failure saying so, not a wall of "the overlay did not load".
```

This is the justification text for D-11, D-21 (`[INFO]`, not `[FINDING]`) and the
Pitfall-5 untracked-file arm. Cite it in the new code's comments, as both
predecessors do.

### Deterministic enumeration — applies to the sweep and every fixture walk
**Source:** `arch/dots-hyprland.sh:807`

```bash
done < <(find "$pkg_dir" -type f -print0 | LC_ALL=C sort -z)
```

For the sweep's per-directory entry listing use
`find "$d" -mindepth 1 -maxdepth 1 -print0 | LC_ALL=C sort -z` — never bash
globbing (needs `nullglob`+`dotglob`, and option changes leak from a sourced
function). Bash associative-array iteration is hash order: pipe
`"${!MANAGED_ROOTS[@]}"` through `LC_ALL=C sort` before emitting.

### Counter increment under `set -euo pipefail` — applies everywhere
**Source:** every existing counter, e.g. `arch/dots-hyprland.sh:761`,
`scripts/phase18-capture-model-assert.sh:995`

```bash
FAIL=$((FAIL + 1))          # correct
FIXTURE_LEAK=$((FIXTURE_LEAK + 1))
```

`((n++))` returns the pre-increment value 0 as status 1 and aborts the run. Never
use it.

### Quoting / injection discipline — applies to all new path handling
**Source:** `arch/dots-hyprland.sh:770-808`

`find -print0` + `while IFS= read -r -d ''`; `--` before every path argument to
`readlink`/`cmp`/`grep`; every expansion quoted; `|| true` on probes whose
non-zero status is expected; `local x` and `x="$(cmd)"` on separate lines so
`local` does not swallow the command's exit status.

## Couplings to Respect (not sources to copy from)

| File | Coupling | Action |
|------|----------|--------|
| `scripts/phase17-unblock-assert.sh:89-90` | `PAIR_COUNT="$(grep -ho -- '--verbose=5 --no-folding' arch/*.sh \| wc -l)"` asserted `-eq 18`. Today `arch/dots-hyprland.sh` contributes 0. | Write D-04's recovery text as `stow -D --no-folding -t ~ <pkg> && stow --no-folding -t ~ <pkg>` — no adjacent `--verbose=5 --no-folding` pair, so the count stays 18 |
| `scripts/phase17-unblock-assert.sh` output contract | Three prefixes, one counter (`=== done: FAIL=n ===`) | Do **not** copy its contract. Copy only its vacuity-guard shape, which `phase18` already re-exports |
| `scripts/phase18-capture-model-assert.sh` Section 7a (lines 687-741) | RESEARCH open question A5: does it assert `verify`'s unknown-flag exit code? | **Resolved during this mapping.** `grep -n 'verify --\|Unknown verify flag'` returns only line 597, an unrelated `--adopt` message. Section 7a asserts dispatch reachability and `rc` reporting only, never `rc -eq 1` for an unknown flag. D-15 does **not** break it. No same-commit edit needed |
| `arch/dots-hyprland.sh:17` `ALLOWLIST` | already contains `verify` (D-61) | No change |

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | Every file in this phase has a tracked in-repo analog. |

Two *sub-patterns* inside the new assert have no in-repo precedent and must come
from `19-RESEARCH.md` §Code Examples rather than from an analog:

| Sub-pattern | Why no analog | Source |
|---|---|---|
| `rsync -a --delete` destruction with a `realpath` fail-closed prefix guard (D-26) | No existing script runs a destructive command against a fixture; `phase18` is non-mutating by construction and STATE.md records the Phase 17 incident that resulted from getting this wrong | `19-RESEARCH.md` §"The working VER-04 harness shape" + Pitfall 8 |
| GNU Stow invoked against a scratch `$HOME` (`stow --no-folding -t "$T/home" fixture`) | `phase18`'s fixtures are hand-built file copies; no assert has ever run `stow` | `19-RESEARCH.md` §Code Examples, Pitfall 2 |
| `find -xtype l` dangling sweep | Genuinely new primitive in this repo | `.planning/research/PITFALLS.md` A-6 mandates the form |

## Metadata

**Analog search scope:** `scripts/`, `arch/`, repo root
**Files scanned:** 8 tracked files; 5 read for excerpts
**Tracked-source gate:** all analog paths verified with `git ls-files`
**Pattern extraction date:** 2026-09-14
