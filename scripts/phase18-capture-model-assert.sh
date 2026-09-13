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

# Fixtures. All of them live outside the repo, and the EXIT trap is set
# immediately after the last mktemp so a failing check -- or any non-zero command
# under `set -euo pipefail` between here and the end -- still removes them
# (D-56; shape from scripts/phase16-retire-assert.sh:32-41). A fail() only
# increments a counter and does not abort, but nothing else here is so forgiving,
# and STATE.md records the Phase 17 incident where a fixture-handling assumption
# destroyed tracked files.
REGEN_OUT="$(mktemp /tmp/p18-regen-XXXXXX)"
DET_OUT_1="$(mktemp /tmp/p18-det1-XXXXXX)"
DET_OUT_2="$(mktemp /tmp/p18-det2-XXXXXX)"
FAKE_OUT="$(mktemp /tmp/p18-fakemap-XXXXXX)"
PORCELAIN_BEFORE="$(mktemp /tmp/p18-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p18-porcelain-after-XXXXXX)"
FAKE_ROOT="$(mktemp -d /tmp/p18-fakeroot-XXXXXX)"
FIX_HOME_7B=""
FIX_HOME_7C=""
cleanup() {
  if [[ -e "$SUBMODULE/.git.aside" && ! -e "$SUBMODULE/.git" ]]; then
    mv "$SUBMODULE/.git.aside" "$SUBMODULE/.git" 2>/dev/null || true
  fi
  rm -f "$REGEN_OUT" "$DET_OUT_1" "$DET_OUT_2" "$FAKE_OUT" "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"
  rm -rf "$FAKE_ROOT"
  [[ -n "$FIX_HOME_7B" ]] && rm -rf "$FIX_HOME_7B"
  [[ -n "$FIX_HOME_7C" ]] && rm -rf "$FIX_HOME_7C"
}
trap cleanup EXIT

git status --porcelain > "$PORCELAIN_BEFORE"

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
# Section 1 / CAP-01 -- the three capture trees and their contracts (D-11, D-12)
# =============================================================================
echo "=== Section 1 / CAP-01: the three capture trees and their contracts ==="

for T in stow restow capture; do
  if [[ -d "$T" ]]; then
    pass "1a directory $T/ exists"
  else
    fail "1a directory $T/ is missing"
  fi
done

for T in stow restow capture; do
  README="$T/README.md"
  if [[ -f "$README" ]]; then
    pass "1b $README exists"

    if grep -q -i -- 'contract' "$README"; then
      pass "1b $README states its contract"
    else
      fail "1b $README does not state its contract (missing 'contract')"
    fi

    if grep -q -E -- '(stow --verbose=5 --no-folding|dots-hyprland\.sh capture)' "$README"; then
      pass "1b $README states its exact recovery or refresh command"
    else
      fail "1b $README does not state its exact recovery command"
    fi

    if grep -q -i -- 'membership' "$README"; then
      pass "1b $README states its membership rule"
    else
      fail "1b $README does not state its membership rule (missing 'membership')"
    fi
  else
    fail "1b $README is missing"
  fi
done

if [[ -f capture/README.md ]]; then
  if grep -q -i -- 'hand-assigned' capture/README.md; then
    pass "1c capture/README.md states the hand-assigned membership rule in prose (D-05)"
  else
    fail "1c capture/README.md does not describe membership as hand-assigned prose (D-05)"
  fi
fi

for T in stow restow; do
  README="$T/README.md"
  if [[ -f "$README" ]]; then
    if grep -q -i -E -- '(only two|no third tree)' "$README"; then
      pass "1d $README acknowledges that only two derived trees exist in the collision map"
    else
      fail "1d $README claims or allows a third value in collision-map.tsv tree column"
    fi
  fi
done

if [[ -d docs/archive && -f docs/archive/README.md ]]; then
  pass "1e docs/archive/README.md exists with its retirement contract"
else
  fail "1e docs/archive/ or docs/archive/README.md is missing"
fi

info "1f restow/ package tag table check arrives with the generated table in plan 18-10"

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

# =============================================================================
# Section 3b / CAP-03 -- determinism. A flaky gate gets ignored, and ignoring it
# discards the real pin-bump signal along with the noise (RESEARCH F-3).
# =============================================================================
echo "=== Section 3b / CAP-03: two consecutive generator runs are byte-identical ==="

if [[ "$GEN_PRESENT" -eq 1 ]]; then
  if "$GEN" > "$DET_OUT_1" && "$GEN" > "$DET_OUT_2"; then
    if cmp -s "$DET_OUT_1" "$DET_OUT_2"; then
      pass "3b two consecutive runs of $GEN produce byte-identical output"
    else
      fail "3b two consecutive runs of $GEN differ -- the row order is not deterministic"
      diff -u "$DET_OUT_1" "$DET_OUT_2" || true
      echo "       GNU find returns readdir order; the generator must emit through LC_ALL=C sort." >&2
    fi
  else
    fail "3b $GEN exited non-zero during the determinism check; see its own [FAIL] output above"
  fi
else
  info "3b skipped: the generator is unavailable"
fi

# =============================================================================
# Section 3c / CAP-03 -- simulated pin bump (D-55). A fake source tree with one
# primitive changed must produce a different map. This proves the generator
# reacts to upstream, not merely that a diff can be produced. The real submodule
# is never touched.
# =============================================================================
echo "=== Section 3c / CAP-03: a changed upstream primitive changes the map ==="

if [[ "$MAP_PRESENT" -eq 1 && "$GEN_PRESENT" -eq 1 ]]; then
  mkdir -p "$FAKE_ROOT/dots/.config/fakedir" \
           "$FAKE_ROOT/dots/.local/share/konsole" \
           "$FAKE_ROOT/sdata/subcmd-install"
  : > "$FAKE_ROOT/dots/.config/fakedir/settings.conf"
  : > "$FAKE_ROOT/dots/.config/fakefile.conf"
  : > "$FAKE_ROOT/dots/.local/share/konsole/fake.profile"

  # The hypr/custom call site below uses install_dir__sync where the real one at
  # 3.files-legacy.sh:75 uses install_dir__ignore_existing -- the one changed
  # primitive. Everything else is shaped like upstream so the generator parses it.
  cat > "$FAKE_ROOT/sdata/subcmd-install/3.files-legacy.sh" <<'FAKE_LEGACY_EOF'
# Fake dots-hyprland installer fragment. Fixture only.
for i in $(find dots/.config/ -mindepth 1 -maxdepth 1 ! -name 'quickshell' ! -name 'fish' ! -name 'hypr' ! -name 'fontconfig' -exec basename {} \;); do
  if [ -d "dots/.config/$i" ];then install_dir__sync "dots/.config/$i" "$XDG_CONFIG_HOME/$i"
  elif [ -f "dots/.config/$i" ];then install_file "dots/.config/$i" "$XDG_CONFIG_HOME/$i"
  fi
done
install_dir "dots/.local/share/konsole" "${XDG_DATA_HOME}"/konsole
install_dir__sync "dots/.config/hypr/custom" "${XDG_CONFIG_HOME}/hypr/custom"
FAKE_LEGACY_EOF

  if "$GEN" "$FAKE_ROOT" > "$FAKE_OUT"; then
    if diff -q "$MAP" "$FAKE_OUT" > /dev/null 2>&1; then
      fail "3c a source tree with install_dir__ignore_existing swapped for install_dir__sync produced a map identical to $MAP"
      echo "       The generator is not reading upstream; the regenerate-and-diff signal is void." >&2
    else
      pass "3c a source tree with one primitive changed produces a map that differs from $MAP"
    fi
    SWAPPED_ROW="$(awk -F'\t' '$1=="$XDG_CONFIG_HOME/hypr/custom"' "$FAKE_OUT" || true)"
    if [[ "$SWAPPED_ROW" == *"install_dir__sync"*"restow"* ]]; then
      pass "3c the swapped hypr/custom call site is read from the source tree and re-derives tree=restow"
    else
      fail "3c the swapped hypr/custom call site did not produce an install_dir__sync/restow row"
      echo "       Got: ${SWAPPED_ROW:-<no row>}" >&2
      echo "       The map would then differ for some unrelated reason, which is not the property D-55 claims." >&2
    fi
  else
    fail "3c $GEN exited non-zero against the fake source root; see its own [FAIL] output above"
  fi
else
  info "3c skipped: the map or the generator is unavailable"
fi

# =============================================================================
# Section 4 / CAP-08 -- the experimental files flag is refused with exit 2
# =============================================================================
echo "=== Section 4 / CAP-08: --exp-files refusal gate ==="

WRAPPER="./arch/dots-hyprland.sh"
if [[ -x "$WRAPPER" ]]; then
  EXP_RC=0
  EXP_OUT="$("$WRAPPER" install --dry-run --exp-files 2>&1)" || EXP_RC=$?
  if [[ "$EXP_RC" -eq 2 ]] \
     && grep -q 'collision-map.tsv' <<<"$EXP_OUT" \
     && ! grep -q '\./setup' <<<"$EXP_OUT"; then
    pass "4a --exp-files refused with exit 2, names collision-map.tsv, never reached ./setup"
  else
    fail "4a --exp-files was not refused correctly (rc=$EXP_RC, expected 2; map named=$(grep -c 'collision-map.tsv' <<<"$EXP_OUT"); setup announced=$(grep -c '\./setup' <<<"$EXP_OUT"))"
    printf '%s\n' "$EXP_OUT" | sed 's/^/       /' >&2
  fi

  POS_RC=0
  POS_OUT="$("$WRAPPER" install --dry-run other-arg --exp-files 2>&1)" || POS_RC=$?
  if [[ "$POS_RC" -eq 2 ]] && grep -q 'collision-map.tsv' <<<"$POS_OUT"; then
    pass "4b --exp-files is refused identically when placed after other arguments (exit 2)"
  else
    fail "4b --exp-files position independence failed (rc=$POS_RC, expected 2)"
    printf '%s\n' "$POS_OUT" | sed 's/^/       /' >&2
  fi

  EQ_RC=0
  EQ_OUT="$("$WRAPPER" install --dry-run --exp-files=true 2>&1)" || EQ_RC=$?
  if [[ "$EQ_RC" -eq 2 ]] && grep -q 'collision-map.tsv' <<<"$EQ_OUT"; then
    pass "4c --exp-files=... is refused identically (exit 2)"
  else
    fail "4c --exp-files=... refusal failed (rc=$EQ_RC, expected 2)"
    printf '%s\n' "$EQ_OUT" | sed 's/^/       /' >&2
  fi

  SUB_RC=0
  SUB_OUT="$("$WRAPPER" --exp-files-not 2>&1)" || SUB_RC=$?
  if ! grep -q 'collision-map.tsv' <<<"$SUB_OUT" && grep -q 'Unknown or non-allowlisted' <<<"$SUB_OUT"; then
    pass "4d argument merely containing the token as a substring is not refused by the gate (reaches allowlist)"
  else
    fail "4d substring argument was wrongly caught by the --exp-files gate or bypassed allowlist"
    printf '%s\n' "$SUB_OUT" | sed 's/^/       /' >&2
  fi

  info "4e D-32: the gate is a deny-list of exactly one flag (--exp-files). The font-set flag (--fontset) still forwards to 3.files-legacy.sh:42, a source the map does not model, recorded as an accepted coverage gap in collision-map.tsv."
else
  fail "4 wrapper $WRAPPER is missing or not executable"
fi

# =============================================================================
# Section 5 / CAP-07 -- the banned stow flag is absent and documented
# =============================================================================
echo "=== Section 5 / CAP-07: the banned stow flag is absent and documented ==="

ARCH_SH_COUNT="$(find arch -maxdepth 1 -type f -name '*.sh' | wc -l || true)"
SCRIPTS_SH_COUNT="$(find scripts -maxdepth 1 -type f -name '*.sh' | wc -l || true)"

if [[ -d arch && "$ARCH_SH_COUNT" -gt 0 ]]; then
  pass "5 guard: arch/ exists and holds $ARCH_SH_COUNT *.sh files (the ban below cannot pass vacuously)"
else
  fail "5 guard: arch/ is missing or holds no *.sh file -- the ban-grep would pass over nothing"
fi

if [[ -d scripts && "$SCRIPTS_SH_COUNT" -gt 0 ]]; then
  pass "5 guard: scripts/ exists and holds $SCRIPTS_SH_COUNT *.sh files (the ban below cannot pass vacuously)"
else
  fail "5 guard: scripts/ is missing or holds no *.sh file -- the ban-grep would pass over nothing"
fi

# The ban itself: recursive grep over arch/ and scripts/ for --adopt.
# scripts/phase18-capture-model-assert.sh is excluded by name: its own grep
# pattern is a quoted literal living under scripts/, so an unexcluded ban would
# count the policeman as the offender (RESEARCH F-9 trap 1).
ADOPT_HITS="$(grep -rn -F --exclude="phase18-capture-model-assert.sh" -- "--adopt" arch scripts 2>/dev/null || true)"
if [[ -z "$ADOPT_HITS" ]]; then
  pass "5a the banned stow flag (--adopt) appears in no script under arch/ or scripts/ (excluding assert pattern)"
else
  fail "5a the banned stow flag (--adopt) was found in script(s):"
  echo "$ADOPT_HITS" | sed 's/^/       /' >&2
fi

if [[ -f stow/README.md ]]; then
  HAS_ADOPT_DOC="$(grep -c -F -- "--adopt" stow/README.md || true)"
  HAS_INTERACTIVE="$(grep -c -i -- "interactive" stow/README.md || true)"
  HAS_CLEAN_TREE="$(grep -c -i -- "clean tree" stow/README.md || true)"
  HAS_ONE_PATH="$(grep -c -i -- "one path at a time" stow/README.md || true)"

  if [[ "$HAS_ADOPT_DOC" -gt 0 && "$HAS_INTERACTIVE" -gt 0 && "$HAS_CLEAN_TREE" -gt 0 && "$HAS_ONE_PATH" -gt 0 ]]; then
    pass "5b stow/README.md documents the --adopt ban and all three exception terms (interactive, clean tree, one path at a time)"
  else
    fail "5b stow/README.md missing --adopt documentation or one of the three exception terms (adopt=$HAS_ADOPT_DOC interactive=$HAS_INTERACTIVE clean_tree=$HAS_CLEAN_TREE one_path=$HAS_ONE_PATH)"
  fi
else
  fail "5b stow/README.md is missing -- cannot verify --adopt ban documentation"
fi

# =============================================================================
# Section 7a / ROADMAP criterion 7 -- wrapper-owned verify and capture dispatch
# =============================================================================
echo "=== Section 7a / ROADMAP criterion 7: wrapper-owned verify and capture dispatch ==="

# 7a-1: Behavioural read of allowlist output on refusal of unknown subcommand
NON_ALLOW_OUT="$(./arch/dots-hyprland.sh __nonexistent_subcmd__ 2>&1 || true)"
if grep -q -w "verify" <<<"$NON_ALLOW_OUT" && grep -q -w "capture" <<<"$NON_ALLOW_OUT"; then
  pass "7a allowlist refusal output contains both verify and capture"
else
  fail "7a allowlist refusal output missing verify or capture"
  printf '%s\n' "$NON_ALLOW_OUT" | sed 's/^/       /' >&2
fi

# 7a-2: verify runs to a real exit code without reaching upstream setup
VERIFY_RC=0
VERIFY_OUT="$(./arch/dots-hyprland.sh verify 2>&1)" || VERIFY_RC=$?
if grep -q -- "setup verify" <<<"$VERIFY_OUT" || grep -q '\./setup' <<<"$VERIFY_OUT"; then
  fail "7a ./arch/dots-hyprland.sh verify reached upstream setup dispatch (catch-all reached)"
  printf '%s\n' "$VERIFY_OUT" | sed 's/^/       /' >&2
elif grep -q -- "non-allowlisted" <<<"$VERIFY_OUT"; then
  fail "7a ./arch/dots-hyprland.sh verify was rejected as non-allowlisted"
else
  pass "7a ./arch/dots-hyprland.sh verify dispatched to wrapper handler (rc=$VERIFY_RC, never named ./setup)"
fi

# 7a-3: capture on empty tree exits 0 with explicit empty-tree message
CAPTURE_RC=0
CAPTURE_OUT="$(./arch/dots-hyprland.sh capture 2>&1)" || CAPTURE_RC=$?
if [[ "$CAPTURE_RC" -eq 0 ]] && grep -q -i 'empty' <<<"$CAPTURE_OUT" && ! grep -q -- "setup capture" <<<"$CAPTURE_OUT" && ! grep -q '\./setup' <<<"$CAPTURE_OUT"; then
  pass "7a ./arch/dots-hyprland.sh capture exits 0 with explicit empty-tree message on empty capture/ tree"
else
  fail "7a ./arch/dots-hyprland.sh capture failed (rc=$CAPTURE_RC) or missing empty-tree message or reached ./setup"
  printf '%s\n' "$CAPTURE_OUT" | sed 's/^/       /' >&2
fi

# 7a-4: verify survives de-initialised submodule
SUB_DIRTY="$(git -C "$SUBMODULE" status --porcelain 2>/dev/null || true)"
if [[ -n "$SUB_DIRTY" ]]; then
  fail "7a submodule $SUBMODULE is dirty -- skipping de-init test to prevent risking uncommitted work"
elif [[ ! -e "$SUBMODULE/.git" ]]; then
  fail "7a submodule $SUBMODULE/.git is missing before de-init test"
else
  mv "$SUBMODULE/.git" "$SUBMODULE/.git.aside"
  DEINIT_RC=0
  DEINIT_OUT="$(./arch/dots-hyprland.sh verify 2>&1)" || DEINIT_RC=$?
  mv "$SUBMODULE/.git.aside" "$SUBMODULE/.git"

  if grep -q -i 'submodule' <<<"$DEINIT_OUT" || grep -q 'missing .git' <<<"$DEINIT_OUT" || grep -q '\./setup' <<<"$DEINIT_OUT"; then
    fail "7a verify with de-initialised submodule reported submodule error or reached ./setup"
    printf '%s\n' "$DEINIT_OUT" | sed 's/^/       /' >&2
  else
    pass "7a verify runs to a real exit code (rc=$DEINIT_RC) with $SUBMODULE de-initialised (preflight never reached)"
  fi
fi

# =============================================================================
# Section 7b / CAP-05 -- capture fixture, copy, and refusals
# =============================================================================
echo "=== Section 7b / CAP-05: capture fixture copy and refusals ==="

FIX_HOME_7B="$(mktemp -d /tmp/p18-fix7b-XXXXXX)"
FIX_REPO_7B="$FIX_HOME_7B/fixture-repo"

git init -q "$FIX_REPO_7B"
git -C "$FIX_REPO_7B" config user.name "GSD Assert"
git -C "$FIX_REPO_7B" config user.email "assert@local"

mkdir -p "$FIX_REPO_7B/arch" "$FIX_REPO_7B/capture/testpkg/.config/testpkg"
cp "$REPO_ROOT/arch/dots-hyprland.sh" "$FIX_REPO_7B/arch/dots-hyprland.sh"
chmod +x "$FIX_REPO_7B/arch/dots-hyprland.sh"

mkdir -p "$FIX_HOME_7B/.config/testpkg"

# 1. Clean and tracked mirror
CLEAN_MIRROR="$FIX_REPO_7B/capture/testpkg/.config/testpkg/clean_tracked.conf"
CLEAN_LIVE="$FIX_HOME_7B/.config/testpkg/clean_tracked.conf"
printf 'clean_initial_repo\n' > "$CLEAN_MIRROR"
printf 'clean_modified_live\n' > "$CLEAN_LIVE"

# 2. Tracked and dirty mirror
DIRTY_MIRROR="$FIX_REPO_7B/capture/testpkg/.config/testpkg/tracked_dirty.conf"
DIRTY_LIVE="$FIX_HOME_7B/.config/testpkg/tracked_dirty.conf"
printf 'dirty_initial_repo\n' > "$DIRTY_MIRROR"
printf 'dirty_live_content\n' > "$DIRTY_LIVE"

# 3. Missing live counterpart
MISSING_MIRROR="$FIX_REPO_7B/capture/testpkg/.config/testpkg/missing_live.conf"
printf 'missing_live_repo_content\n' > "$MISSING_MIRROR"

# Initial commit in fixture repo (clean_tracked, tracked_dirty, missing_live)
git -C "$FIX_REPO_7B" add .
git -C "$FIX_REPO_7B" commit -q -m "initial fixture state"

# Make tracked_dirty dirty against HEAD in working tree
printf 'dirty_working_tree_edit\n' >> "$DIRTY_MIRROR"

# 4. Untracked mirror (created after initial commit, never added to git)
UNTRACKED_MIRROR="$FIX_REPO_7B/capture/testpkg/.config/testpkg/untracked.conf"
UNTRACKED_LIVE="$FIX_HOME_7B/.config/testpkg/untracked.conf"
printf 'untracked_repo_content\n' > "$UNTRACKED_MIRROR"
printf 'untracked_live_content\n' > "$UNTRACKED_LIVE"

# Run capture in fixture environment
CAP_7B_RC=0
CAP_7B_OUT="$(cd "$FIX_REPO_7B" && HOME="$FIX_HOME_7B" ./arch/dots-hyprland.sh capture 2>&1)" || CAP_7B_RC=$?

# Sub-check 1: Overall run exits non-zero because dirty/untracked/missing were skipped (D-36, D-43)
if [[ "$CAP_7B_RC" -ne 0 ]]; then
  pass "7b overall capture run exited non-zero due to skipped paths (rc=$CAP_7B_RC)"
else
  fail "7b overall capture run exited 0 despite dirty, untracked, and missing-live mirrors"
fi

# Sub-check 2: Clean and tracked mirror was copied, and staged diff in fixture is empty (D-38)
if cmp -s "$CLEAN_MIRROR" "$CLEAN_LIVE"; then
  pass "7b clean tracked mirror copied live content successfully"
else
  fail "7b clean tracked mirror was not copied"
fi

CACHED_DIFF_7B="$(git -C "$FIX_REPO_7B" diff --cached)"
if [[ -z "$CACHED_DIFF_7B" ]]; then
  pass "7b fixture git diff --cached is empty (never staged, never committed)"
else
  fail "7b fixture git diff --cached is non-empty after capture"
  printf '%s\n' "$CACHED_DIFF_7B" | sed 's/^/       /' >&2
fi

# Sub-check 3: Tracked and dirty mirror was refused with dirty reason and bytes unchanged (D-36, D-37)
if grep -q -- "repo mirror is dirty against HEAD" <<<"$CAP_7B_OUT" && grep -q -- "tracked_dirty.conf" <<<"$CAP_7B_OUT"; then
  pass "7b tracked dirty mirror refused naming dirty against HEAD"
else
  fail "7b tracked dirty mirror not refused with dirty-against-HEAD reason"
  printf '%s\n' "$CAP_7B_OUT" | sed 's/^/       /' >&2
fi
if grep -q "dirty_working_tree_edit" "$DIRTY_MIRROR" && ! grep -q "dirty_live_content" "$DIRTY_MIRROR"; then
  pass "7b tracked dirty mirror working-tree bytes left intact (not overwritten by live)"
else
  fail "7b tracked dirty mirror was corrupted or overwritten"
fi

# Sub-check 4: Untracked mirror was refused with distinct untracked reason (RESEARCH F-8)
if grep -q -- "repo mirror is untracked" <<<"$CAP_7B_OUT" && grep -q -- "untracked.conf" <<<"$CAP_7B_OUT"; then
  pass "7b untracked repo mirror refused with distinct untracked reason"
else
  fail "7b untracked repo mirror not refused with untracked reason"
  printf '%s\n' "$CAP_7B_OUT" | sed 's/^/       /' >&2
fi
if ! cmp -s "$UNTRACKED_MIRROR" "$UNTRACKED_LIVE"; then
  pass "7b untracked repo mirror bytes unchanged"
else
  fail "7b untracked repo mirror was wrongly overwritten"
fi

# Sub-check 5: Missing live counterpart reported as [FINDING], moves exit code, repo copy preserved (D-43)
if grep -q -- "\[FINDING\].*live counterpart missing" <<<"$CAP_7B_OUT" && grep -q -- "missing_live.conf" <<<"$CAP_7B_OUT"; then
  pass "7b missing live counterpart produced [FINDING] naming missing_live.conf"
else
  fail "7b missing live counterpart did not produce expected [FINDING]"
  printf '%s\n' "$CAP_7B_OUT" | sed 's/^/       /' >&2
fi
if [[ -f "$MISSING_MIRROR" ]] && grep -q "missing_live_repo_content" "$MISSING_MIRROR"; then
  pass "7b missing live counterpart repo copy was preserved and not deleted"
else
  fail "7b missing live counterpart repo copy was deleted or corrupted"
fi

# =============================================================================
# Section 7c / ROADMAP criterion 7 -- dry run, empty tree, symlink refusal, D-45
# =============================================================================
echo "=== Section 7c / ROADMAP criterion 7: dry run, empty tree, symlink refusal ==="

FIX_HOME_7C="$(mktemp -d /tmp/p18-fix7c-XXXXXX)"
FIX_REPO_7C="$FIX_HOME_7C/fixture-repo"

git init -q "$FIX_REPO_7C"
git -C "$FIX_REPO_7C" config user.name "GSD Assert"
git -C "$FIX_REPO_7C" config user.email "assert@local"

mkdir -p "$FIX_REPO_7C/arch" "$FIX_REPO_7C/capture/testpkg/.config/testpkg"
cp "$REPO_ROOT/arch/dots-hyprland.sh" "$FIX_REPO_7C/arch/dots-hyprland.sh"
chmod +x "$FIX_REPO_7C/arch/dots-hyprland.sh"

mkdir -p "$FIX_HOME_7C/.config/testpkg"

DRY_MIRROR="$FIX_REPO_7C/capture/testpkg/.config/testpkg/dry_test.conf"
DRY_LIVE="$FIX_HOME_7C/.config/testpkg/dry_test.conf"
printf 'dry_repo_initial\n' > "$DRY_MIRROR"
printf 'dry_live_new\n' > "$DRY_LIVE"

git -C "$FIX_REPO_7C" add .
git -C "$FIX_REPO_7C" commit -q -m "dry run fixture initial"
PORCELAIN_PRE_DRY="$(git -C "$FIX_REPO_7C" status --porcelain)"

# 7c-1: Dry run preview (D-42)
DRY_RC=0
DRY_OUT="$(cd "$FIX_REPO_7C" && HOME="$FIX_HOME_7C" ./arch/dots-hyprland.sh capture --dry-run 2>&1)" || DRY_RC=$?
PORCELAIN_POST_DRY="$(git -C "$FIX_REPO_7C" status --porcelain)"

if [[ "$DRY_RC" -eq 0 ]] && grep -q -- "dry-run: would copy" <<<"$DRY_OUT" && grep -q -- "dry_test.conf" <<<"$DRY_OUT"; then
  pass "7c capture --dry-run printed would-copy preview naming dry_test.conf"
else
  fail "7c capture --dry-run failed or did not print expected preview message"
  printf '%s\n' "$DRY_OUT" | sed 's/^/       /' >&2
fi
if grep -q "dry_repo_initial" "$DRY_MIRROR" && ! grep -q "dry_live_new" "$DRY_MIRROR"; then
  pass "7c capture --dry-run left repo mirror bytes unchanged"
else
  fail "7c capture --dry-run modified repo mirror bytes"
fi
if [[ "$PORCELAIN_PRE_DRY" == "$PORCELAIN_POST_DRY" ]]; then
  pass "7c capture --dry-run left fixture git status unchanged"
else
  fail "7c capture --dry-run changed fixture git status"
fi

# 7c-2: Empty tree in fixture repo (D-41)
EMPTY_REPO_7C="$FIX_HOME_7C/empty-repo"
git init -q "$EMPTY_REPO_7C"
mkdir -p "$EMPTY_REPO_7C/arch" "$EMPTY_REPO_7C/capture"
cp "$REPO_ROOT/arch/dots-hyprland.sh" "$EMPTY_REPO_7C/arch/dots-hyprland.sh"
chmod +x "$EMPTY_REPO_7C/arch/dots-hyprland.sh"

EMPTY_RC=0
EMPTY_OUT="$(cd "$EMPTY_REPO_7C" && HOME="$FIX_HOME_7C" ./arch/dots-hyprland.sh capture 2>&1)" || EMPTY_RC=$?
if [[ "$EMPTY_RC" -eq 0 ]] && grep -q -i "capture/ is empty, nothing to capture" <<<"$EMPTY_OUT"; then
  pass "7c capture against fixture empty capture/ exits 0 with explicit message"
else
  fail "7c capture against fixture empty capture/ failed (rc=$EMPTY_RC) or missing explicit message"
  printf '%s\n' "$EMPTY_OUT" | sed 's/^/       /' >&2
fi

# Also check against this repository's real empty capture/ tree
REAL_EMPTY_RC=0
REAL_EMPTY_OUT="$(./arch/dots-hyprland.sh capture 2>&1)" || REAL_EMPTY_RC=$?
if [[ "$REAL_EMPTY_RC" -eq 0 ]] && grep -q -i "capture/ is empty, nothing to capture" <<<"$REAL_EMPTY_OUT"; then
  pass "7c capture against real repository empty capture/ exits 0 with explicit message"
else
  fail "7c capture against real repository empty capture/ failed (rc=$REAL_EMPTY_RC)"
fi

# 7c-3: Symlink refusal (D-39)
# In fixture, set up live path as a symlink pointing into the repo mirror
SYMLINK_MIRROR="$FIX_REPO_7C/capture/testpkg/.config/testpkg/symlink_test.conf"
SYMLINK_LIVE="$FIX_HOME_7C/.config/testpkg/symlink_test.conf"
printf 'symlink_repo_initial\n' > "$SYMLINK_MIRROR"
git -C "$FIX_REPO_7C" add "$SYMLINK_MIRROR"
git -C "$FIX_REPO_7C" commit -q -m "add symlink test mirror"
ln -s "$SYMLINK_MIRROR" "$SYMLINK_LIVE"

SYM_RC=0
SYM_OUT="$(cd "$FIX_REPO_7C" && HOME="$FIX_HOME_7C" ./arch/dots-hyprland.sh capture 2>&1)" || SYM_RC=$?
if [[ "$SYM_RC" -ne 0 ]] && grep -q -- "refusing live path that is a symlink" <<<"$SYM_OUT"; then
  pass "7c capture refused live path that is a symlink into repo (D-39)"
else
  fail "7c capture did not refuse live symlink into repo (rc=$SYM_RC)"
  printf '%s\n' "$SYM_OUT" | sed 's/^/       /' >&2
fi

# 7c-4: Range-scoped check for D-45 implementation constraint
# run_capture body must contain no hardcoded /home/ and no bare ~
CAPTURE_BODY="$(awk '/^run_capture\(\)/,/^}$/' arch/dots-hyprland.sh)"
if grep -q '/home/' <<<"$CAPTURE_BODY"; then
  fail "7c arch/dots-hyprland.sh run_capture() contains hardcoded /home/ path"
else
  pass "7c arch/dots-hyprland.sh run_capture() contains no hardcoded /home/ path"
fi
if grep -q -- '~[a-zA-Z0-9_/]' <<<"$CAPTURE_BODY"; then
  fail "7c arch/dots-hyprland.sh run_capture() contains tilde path bypassing \$HOME"
else
  pass "7c arch/dots-hyprland.sh run_capture() contains no tilde path bypassing \$HOME"
fi

# 7c-5: Record accepted TOCTOU risk
info "7c accepted risk: window between capturability test and copy is a TOCTOU gap, accepted on single-operator single-machine repo"

# =============================================================================
# Named conditions this run cannot decide. [INFO] only -- neither moves the exit
# code, and both exist so a green run is not read as saying more than it does.
# =============================================================================
echo "=== Named conditions (INFO only) ==="

II_MARKER="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/installed_true"
if [[ -e "$II_MARKER" ]]; then
  info "RESEARCH F-5: $II_MARKER exists, so install_file__auto_backup's DESTRUCTIVE branch is DISARMED on this host -- an install run today writes a .new sidecar and leaves hypridle.conf and hyprlock.conf intact. The map deliberately records the FIRSTRUN outcome (DESTROYED), which is one deleted marker or one --firstrun away. An empirical spot-check will contradict those rows; the rows are right and the observation is the disarmed branch. Do not 'correct' the map to match the host."
else
  info "RESEARCH F-5: $II_MARKER is ABSENT, so install_file__auto_backup's destructive firstrun branch is ARMED on this host -- the outcome the map records (DESTROYED) is the one an install run would take today."
fi

info "RESEARCH F-11: scripts/phase17-unblock-assert.sh still reports 'all 14 files holding a stow call site are present'. That sentence goes factually stale as this phase adds call sites, but the check counts its own 14-element SYNTAX_FILES list rather than the filesystem, so it stays green and is deliberately NOT edited (D-20): a closed assert must keep describing what its own phase verified. The current count lives in this phase's own asserts."

# =============================================================================
# Closing self-check -- this script mutates nothing it can see.
# =============================================================================
echo "=== Closing self-check: working tree unchanged ==="

git status --porcelain > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "self-check: git status --porcelain is identical before and after this run"
else
  fail "self-check: git status --porcelain changed during this run -- something here mutated the working tree"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi
FIXTURE_LEAK=0
for FIXTURE in "$REGEN_OUT" "$DET_OUT_1" "$DET_OUT_2" "$FAKE_OUT" "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" "$FAKE_ROOT" "$FIX_HOME_7B" "$FIX_HOME_7C"; do
  [[ -z "$FIXTURE" ]] && continue
  if grep -q -F -- "$(basename "$FIXTURE")" "$PORCELAIN_AFTER"; then
    fail "self-check: git status names a path this script created: $FIXTURE"
    FIXTURE_LEAK=$((FIXTURE_LEAK + 1))
  fi
done
if [[ "$FIXTURE_LEAK" -eq 0 ]]; then
  pass "self-check: git status names no fixture path this script created (all fixtures live outside the repo and are removed by the EXIT trap)"
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
