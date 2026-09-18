#!/usr/bin/env bash
# Phase 29: Theme Data Contracts, Verification & Bootstrap Integration assert harness
# Enforces: INTG-01, INTG-02, INTG-03, and D-01 through D-16
#
# Usage (from REPO_ROOT):
#   ./scripts/phase29-theme-data-contracts-assert.sh [--section <1-5>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

ASSERT_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"

FAIL=0
FINDINGS=0
pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
finding() { printf '[FINDING] %s\n' "$1"; FINDINGS=$((FINDINGS + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

TMP_FILES=()
SCRATCH_ROOTS=()

cleanup() {
  rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"} 2>/dev/null || true
  local root
  for root in ${SCRATCH_ROOTS[@]+"${SCRATCH_ROOTS[@]}"}; do
    [[ -n "$root" ]] || continue
    chmod -R u+rwX "$root" 2>/dev/null || true
    rm -rf "$root" 2>/dev/null || true
  done
  return 0
}
trap cleanup EXIT

RUN_SECTION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-5]$ ]]; then
        echo "Error: --section requires an integer from 1 to 5" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-5>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

porcelain_snapshot_raw() {
  git status --porcelain --ignored || true
}

porcelain_snapshot() {
  porcelain_snapshot_raw \
    | grep -v -E '^!! (\.commandcode/|scripts/__pycache__/)$' || true
}

PORCELAIN_BEFORE="$(mktemp /tmp/p29-porcelain-before-XXXXXX)"
PORCELAIN_AFTER="$(mktemp /tmp/p29-porcelain-after-XXXXXX)"
TMP_FILES+=("$PORCELAIN_BEFORE" "$PORCELAIN_AFTER")

porcelain_snapshot > "$PORCELAIN_BEFORE"

# ===========================================================================
# Section 1: Data Contracts & Gitignore Parity (INTG-01, INTG-02)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: Data Contracts & Gitignore Parity (INTG-01, INTG-02) ---"

  GUARD_TSV="$REPO_ROOT/guard-paths.tsv"
  GITIGNORE="$REPO_ROOT/.gitignore"
  COLLISION_MAP="$REPO_ROOT/collision-map.tsv"
  RESTOW_README="$REPO_ROOT/restow/README.md"

  # 1. guard-paths.tsv existence and 8 valid tab-separated rows
  if [[ -f "$GUARD_TSV" ]]; then
    pass "S1: guard-paths.tsv exists"
    EXPECTED_GUARDS=(
      '$XDG_CONFIG_HOME/kdeglobals'
      '$XDG_CONFIG_HOME/Kvantum'
      '$XDG_CONFIG_HOME/gtk-3.0/gtk.css'
      '$XDG_CONFIG_HOME/gtk-4.0/gtk.css'
      '$XDG_CONFIG_HOME/fuzzel/fuzzel_theme.ini'
      '$XDG_CONFIG_HOME/hypr/hyprland/colors.lua'
      '$XDG_CONFIG_HOME/hypr/hyprlock/colors.conf'
      '$XDG_CONFIG_HOME/kde-material-you-colors'
    )
    guard_count=0
    all_guards_ok=1
    while IFS=$'\t' read -r p cat gen reason || [[ -n "$p" ]]; do
      [[ -n "$p" && "$p" != \#* ]] || continue
      guard_count=$((guard_count + 1))
      if [[ -z "$cat" || -z "$gen" || -z "$reason" ]]; then
        fail "S1: guard-paths.tsv row invalid or missing columns: $p"
        all_guards_ok=0
      fi
    done < "$GUARD_TSV"

    if [[ "$guard_count" -eq 8 && "$all_guards_ok" -eq 1 ]]; then
      pass "S1: guard-paths.tsv contains exactly 8 valid tab-separated rows"
    else
      fail "S1: guard-paths.tsv row count is $guard_count (expected 8)"
    fi

    # Check Q7 and Q8 compatibility markers
    if grep -q "Q7:" "$GUARD_TSV" && grep -q "kde-material-you-colors" "$GUARD_TSV" && \
       grep -q "Q8:" "$GUARD_TSV" && grep -q "gtk-4.0/gtk.css" "$GUARD_TSV"; then
      pass "S1: guard-paths.tsv preserves Q7 and Q8 backward compatibility markers"
    else
      fail "S1: guard-paths.tsv header missing required Q7 or Q8 markers"
    fi
  else
    fail "S1: guard-paths.tsv missing"
  fi

  # 2. 1:1 Parity between guard-paths.tsv and .gitignore (D-01)
  if [[ -f "$GITIGNORE" ]]; then
    for g_entry in kdeglobals gtk.css Kvantum/ colors.lua colors.conf fuzzel_theme.ini kde-material-you-colors/; do
      if grep -q "^${g_entry}$" "$GITIGNORE"; then
        pass "S1: .gitignore contains $g_entry"
      else
        fail "S1: .gitignore missing required entry $g_entry"
      fi
    done
  else
    fail "S1: .gitignore missing"
  fi

  # 3. Three-tree placement: fuzzel and kitty in restow/ (D-05)
  if [[ -d "$REPO_ROOT/restow/fuzzel" && -d "$REPO_ROOT/restow/kitty" && \
        ! -e "$REPO_ROOT/stow/fuzzel" && ! -e "$REPO_ROOT/stow/kitty" ]]; then
    pass "S1: fuzzel and kitty reside in restow/ and are removed from stow/ (D-05)"
  else
    fail "S1: Package tree placement incorrect: fuzzel or kitty missing from restow/ or remaining in stow/"
  fi

  # 4. collision-map.tsv derivation for fuzzel and kitty
  if grep -qF '$XDG_CONFIG_HOME/fuzzel'$'\t''install_dir__sync'$'\t''DESTROYED'$'\t''untouched'$'\t''restow' "$COLLISION_MAP" && \
     grep -qF '$XDG_CONFIG_HOME/kitty'$'\t''install_dir__sync'$'\t''DESTROYED'$'\t''untouched'$'\t''restow' "$COLLISION_MAP"; then
    pass "S1: collision-map.tsv maps fuzzel and kitty to tree=restow (DESTROYED outcome)"
  else
    fail "S1: collision-map.tsv missing or incorrect for fuzzel/kitty"
  fi

  # 5. restow/README.md Section 3 generated table contains fuzzel and kitty with rsync-replace tag (D-06)
  if grep -q '| `fuzzel` | `rsync-replace` |' "$RESTOW_README" && \
     grep -q '| `kitty` | `rsync-replace` |' "$RESTOW_README"; then
    pass "S1: restow/README.md Section 3 table contains fuzzel and kitty with rsync-replace tag (D-06)"
  else
    fail "S1: restow/README.md table missing fuzzel or kitty rsync-replace entries"
  fi

  # 6. arch/kitty.sh stows from ../restow (D-07)
  KITTY_SH="$REPO_ROOT/arch/kitty.sh"
  if [[ -f "$KITTY_SH" ]] && grep -q '\.\./restow.*stow.*kitty' "$KITTY_SH"; then
    pass "S1: arch/kitty.sh stows from ../restow (D-07)"
  else
    fail "S1: arch/kitty.sh does not stow kitty from ../restow"
  fi

  # 7. Invariant: PAIR_COUNT in arch/*.sh MUST remain strictly 18
  PAIR_COUNT="$(grep -ho -- '--verbose=5 --no-folding' arch/*.sh | wc -l || true)"
  if [[ "$PAIR_COUNT" -eq 18 ]]; then
    pass "S1: PAIR_COUNT invariant in arch/*.sh is strictly 18"
  else
    fail "S1: PAIR_COUNT in arch/*.sh drifted (expected 18, counted $PAIR_COUNT)"
  fi
fi

# ===========================================================================
# Section 2: Live Zero Git Churn Drill (INTG-01, D-14, D-15)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: Live Zero Git Churn Drill (INTG-01, D-14, D-15) ---"
  # Stub: Implemented in Task 29-02-01
fi

# ===========================================================================
# Section 3: Strict Repository Verification Engine (INTG-02, D-04, D-08)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 3 ]]; then
  info "--- Section 3: Strict Repository Verification Engine (INTG-02, D-04, D-08) ---"
  # Stub: Implemented in Task 29-01-03
fi

# ===========================================================================
# Section 4: Bootstrap Integration & Destub Scratch Drill (INTG-03)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 4 ]]; then
  info "--- Section 4: Bootstrap Integration & Destub Scratch Drill (INTG-03) ---"
  # Stub: Implemented in Task 29-02-02
fi

# ===========================================================================
# Section 5: Full v0.5 Regression Sweep (Phases 25, 26, 27, 28)
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 5 ]]; then
  info "--- Section 5: Full v0.5 Regression Sweep (Phases 25, 26, 27, 28) ---"
  # Stub: Implemented in Task 29-02-03
fi

# ===========================================================================
# Closing porcelain invariant check & summary
# ===========================================================================
porcelain_snapshot > "$PORCELAIN_AFTER"
if cmp -s "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER"; then
  pass "Closing self-check: git status --porcelain unchanged across run (D-15)"
else
  fail "Closing self-check: git status --porcelain mutated across run (D-15)"
  diff -u "$PORCELAIN_BEFORE" "$PORCELAIN_AFTER" || true
fi

echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
