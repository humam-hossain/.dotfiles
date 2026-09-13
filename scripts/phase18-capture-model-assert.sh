#!/usr/bin/env bash
# Phase 18 capture model asserts (D-57).
# One script, one section per ROADMAP criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase18-capture-model-assert.sh
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.
#
# Constraints (Phase 18):
#   - Non-mutating. Every check is a read, a grep, a diff, or a generator run
#     whose output goes to a temporary file outside the repo. Nothing under
#     REPO_ROOT or $HOME is written, moved or removed. The generator itself
#     emits to stdout only (D-59), so no section can leave a half-written map.
#   - Fixtures live under `mktemp`/`mktemp -d` outside the repo and are removed
#     by an EXIT trap set immediately after creation, so a failing check cannot
#     leave one behind (D-56, and the Phase 17 incident recorded in STATE.md).
#   - Contract (D-49): FOUR prefixes [PASS] [FAIL] [FINDING] [INFO] and TWO
#     counters, copied from the sibling scripts/phase14-verify.sh:24-41.
#     Everything else -- prologue, vacuity guards, process-substitution read
#     loops, closing line -- takes its shape from
#     scripts/phase17-unblock-assert.sh, which uses the OTHER contract (three
#     prefixes, one counter). That divergence is deliberate and is stated here
#     because both predecessors state theirs.
#   - No row count is hard-coded. The map's size is whatever the pin yields; the
#     regenerate-and-diff already covers a row appearing or disappearing, and a
#     count constant is one more thing a pin bump falsifies.
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

MAP="collision-map.tsv"
GEN="./scripts/gen-collision-map.sh"
SUBMODULE="vendor/dots-hyprland"
LEGACY_NAME="3.files-legacy.sh"
LEGACY="$SUBMODULE/sdata/subcmd-install/$LEGACY_NAME"
REGEN_CMD="$GEN > $MAP"

REGEN_OUT="$(mktemp /tmp/p18-regen-XXXXXX)"
# shellcheck disable=SC2064
trap 'rm -f "$REGEN_OUT"' EXIT

echo "=== Phase 18 capture model (non-mutating) ==="

# =============================================================================
# Vacuity guards -- run before every check that would otherwise pass over
# nothing. Shape from scripts/phase17-unblock-assert.sh:54-71.
# =============================================================================
MAP_PRESENT=0
MAP_ROWS=0
if [[ -s "$MAP" ]]; then
  MAP_ROWS="$(grep -v '^#' -- "$MAP" | grep -c . || true)"
  if [[ "$MAP_ROWS" -gt 0 ]]; then
    MAP_PRESENT=1
    pass "guard: $MAP exists and holds $MAP_ROWS data rows (the checks below cannot pass vacuously)"
  else
    fail "guard: $MAP exists but holds no data row -- every column check below would pass over nothing"
  fi
else
  fail "guard: $MAP is missing or empty. Regenerate (from REPO_ROOT): $REGEN_CMD"
fi

LEGACY_PRESENT=0
LEGACY_LINES=0
if [[ -s "$LEGACY" ]]; then
  LEGACY_LINES="$(wc -l < "$LEGACY")"
  LEGACY_PRESENT=1
  pass "guard: $LEGACY exists and holds $LEGACY_LINES lines (the source-line check below cannot pass vacuously)"
else
  fail "guard: $LEGACY is missing or empty -- the map's sole source is unreadable."
  echo "       Fix (from REPO_ROOT): git submodule update --init --recursive $SUBMODULE" >&2
fi

GEN_PRESENT=0
if [[ -x "$GEN" ]]; then
  GEN_PRESENT=1
  pass "guard: $GEN exists and is executable"
else
  fail "guard: $GEN is missing or not executable -- section 3 cannot regenerate anything"
fi

# =============================================================================
# Section 2 / CAP-02 -- the map is present, pinned, and internally coherent
# =============================================================================
echo "=== Section 2 / CAP-02: collision-map.tsv coverage and coherence ==="

if [[ "$MAP_PRESENT" -eq 1 ]]; then
  MAP_PIN="$(grep -m1 '^# collision-map v1' -- "$MAP" | sed -n 's/.*pin=//p' || true)"
  if [[ -z "$MAP_PIN" ]]; then
    fail "2a $MAP carries no 'pin=' in its header line. Regenerate: $REGEN_CMD"
  elif [[ ! -e "$SUBMODULE/.git" ]]; then
    fail "2a $SUBMODULE is not a git checkout, so the header pin cannot be checked against it."
  else
    LIVE_PIN="$(git -C "$SUBMODULE" rev-parse HEAD)"
    if [[ "$MAP_PIN" == "$LIVE_PIN" ]]; then
      pass "2a map header pin matches the submodule HEAD ($LIVE_PIN)"
    else
      fail "2a map header pin is stale: header=$MAP_PIN submodule HEAD=$LIVE_PIN"
      echo "       A pin bump dirties the map by design (D-60). Re-review the rows, then: $REGEN_CMD" >&2
    fi
  fi
else
  info "2a skipped: no map to read a pin from"
fi

if [[ "$MAP_PRESENT" -eq 1 && "$LEGACY_PRESENT" -eq 1 ]]; then
  SRC_BAD=0
  SRC_CHECKED=0
  while IFS=$'\t' read -r DEST PRIM SYM REPO TREE SRC; do
    [[ -n "$DEST" ]] || continue
    SRC_CHECKED=$((SRC_CHECKED + 1))
    SRC_FILE="${SRC%%:*}"
    SRC_LINES="${SRC#*:}"
    if [[ "$SRC_FILE" != "$LEGACY_NAME" ]]; then
      fail "2b row '$DEST' cites a source file that is not $LEGACY_NAME: $SRC"
      SRC_BAD=$((SRC_BAD + 1))
      continue
    fi
    IFS='-' read -r -a SRC_PARTS <<< "$SRC_LINES"
    for PART in "${SRC_PARTS[@]}"; do
      if [[ ! "$PART" =~ ^[0-9]+$ ]]; then
        fail "2b row '$DEST' cites a non-numeric source line: $SRC"
        SRC_BAD=$((SRC_BAD + 1))
      elif [[ "$PART" -lt 1 || "$PART" -gt "$LEGACY_LINES" ]]; then
        fail "2b row '$DEST' cites $LEGACY_NAME:$PART, which does not exist (the file has $LEGACY_LINES lines)"
        SRC_BAD=$((SRC_BAD + 1))
      fi
    done
  done < <(grep -v '^#' -- "$MAP" | grep . || true)
  if [[ "$SRC_BAD" -eq 0 ]]; then
    pass "2b every source citation in $MAP resolves to a line that exists in $LEGACY ($SRC_CHECKED rows checked)"
  fi
else
  info "2b skipped: the map or the vendored $LEGACY_NAME is unavailable"
fi

if [[ "$MAP_PRESENT" -eq 1 ]]; then
  TREE_OTHER="$(grep -v '^#' -- "$MAP" | grep . | cut -f5 | LC_ALL=C sort -u | grep -v -x -e stow -e restow || true)"
  if [[ -z "$TREE_OTHER" ]]; then
    pass "2c the tree column holds only stow or restow (D-05: derived from the two outcome columns, never authored)"
  else
    fail "2c the tree column holds a value that is neither stow nor restow: $(echo "$TREE_OTHER" | tr '\n' ' ')"
    echo "       The column is derived, not authored. capture/ membership is hand-assigned prose" >&2
    echo "       in capture/README.md and never appears here (D-05)." >&2
  fi
else
  info "2c skipped: no map to read a tree column from"
fi

# =============================================================================
# Section 3a / CAP-03 -- regenerate and diff. The diff IS the pin-rot signal.
# =============================================================================
echo "=== Section 3a / CAP-03: the map reproduces from the pinned submodule ==="

if [[ "$MAP_PRESENT" -eq 1 && "$GEN_PRESENT" -eq 1 ]]; then
  if "$GEN" > "$REGEN_OUT"; then
    if diff -u "$MAP" "$REGEN_OUT" > /dev/null 2>&1; then
      pass "3a $GEN reproduces $MAP byte-for-byte from the pinned submodule"
    else
      fail "3a regenerated map differs from the committed $MAP -- the map has rotted against the submodule"
      diff -u "$MAP" "$REGEN_OUT" || true
      echo "       Re-review the rows above, then regenerate (from REPO_ROOT): $REGEN_CMD" >&2
    fi
  else
    fail "3a $GEN exited non-zero; see its own [FAIL] output above"
  fi
else
  info "3a skipped: the map or the generator is unavailable"
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
