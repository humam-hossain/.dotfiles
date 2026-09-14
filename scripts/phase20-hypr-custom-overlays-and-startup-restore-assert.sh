#!/usr/bin/env bash
# Phase 20 hypr/custom overlays and startup restore asserts (D-22).
# One script, one section per ROADMAP criterion, one verdict for the phase.
#
# Usage (from REPO_ROOT):
#   ./scripts/phase20-hypr-custom-overlays-and-startup-restore-assert.sh [--section <1-7>]
# Exit 0 if all hard asserts pass; exit 1 if any hard FAIL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

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

# ---------------------------------------------------------------------------
# CLI Argument Parsing
# ---------------------------------------------------------------------------
RUN_SECTION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[1-7]$ ]]; then
        echo "Error: --section requires an integer from 1 to 7" >&2
        exit 1
      fi
      RUN_SECTION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--section <1-7>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# ===========================================================================
# Section 1: SAFE-01: isolated fixture backup, stub pruning, and stow dry-run
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 1 ]]; then
  info "--- Section 1: SAFE-01 isolated fixture backup, stub pruning, and stow dry-run ---"

  S1_ROOT="$(mktemp -d /tmp/p20-assert-s1-XXXXXX)"
  SCRATCH_ROOTS+=("$S1_ROOT")

  # Setup mock repo and home
  mkdir -p "$S1_ROOT/repo/stow/testpkg/.config/testpkg"
  mkdir -p "$S1_ROOT/home/.config/testpkg"

  printf 'return "managed"\n' > "$S1_ROOT/repo/stow/testpkg/.config/testpkg/target.lua"
  printf 'return "legacy stub"\n' > "$S1_ROOT/home/.config/testpkg/target.lua"

  # 1. Timestamped backup creation
  BACKUP_EPOCH="$(date +%s)"
  BACKUP_DIR="$S1_ROOT/home/.config/testpkg.backup.$BACKUP_EPOCH"
  cp -a "$S1_ROOT/home/.config/testpkg" "$BACKUP_DIR"

  if [[ -d "$BACKUP_DIR" ]] && [[ -f "$BACKUP_DIR/target.lua" ]] && grep -q 'legacy stub' "$BACKUP_DIR/target.lua"; then
    pass "SAFE-01 (S1): timestamped backup created with intact legacy contents"
  else
    fail "SAFE-01 (S1): backup directory missing or contents corrupted"
  fi

  # 2. Stub pruning
  rm -f "$S1_ROOT/home/.config/testpkg/target.lua"
  if [[ ! -e "$S1_ROOT/home/.config/testpkg/target.lua" ]]; then
    pass "SAFE-01 (S1): legacy unmanaged stub successfully pruned prior to stow"
  else
    fail "SAFE-01 (S1): legacy stub still exists after pruning"
  fi

  # 3. Dry-run stow
  DRY_OUT="$(mktemp /tmp/p20-s1-dryout-XXXXXX)"
  TMP_FILES+=("$DRY_OUT")
  if stow -n -v --no-folding -d "$S1_ROOT/repo/stow" -t "$S1_ROOT/home" testpkg >"$DRY_OUT" 2>&1; then
    if [[ ! -e "$S1_ROOT/home/.config/testpkg/target.lua" ]]; then
      pass "SAFE-01 (S1): stow dry-run (-n) succeeded cleanly with zero filesystem modifications"
    else
      fail "SAFE-01 (S1): stow dry-run modified target filesystem"
    fi
  else
    fail "SAFE-01 (S1): stow dry-run exited non-zero"
  fi

  # 4. Actual stow execution and link identity
  if stow -v --no-folding -d "$S1_ROOT/repo/stow" -t "$S1_ROOT/home" testpkg >/dev/null 2>&1; then
    if [[ -L "$S1_ROOT/home/.config/testpkg/target.lua" ]]; then
      if [[ "$S1_ROOT/repo/stow/testpkg/.config/testpkg/target.lua" -ef "$S1_ROOT/home/.config/testpkg/target.lua" ]]; then
        pass "SAFE-01 (S1): stow link identity verified (-ef confirms matching inode)"
      else
        fail "SAFE-01 (S1): target is symlink but does not resolve to repo source"
      fi
    else
      fail "SAFE-01 (S1): target is not a symlink after stow"
    fi
  else
    fail "SAFE-01 (S1): actual stow command failed in fixture"
  fi
fi

# ===========================================================================
# Section 2: SAFE-01: isolated fixture live undo drill and re-stow rehearsal
# ===========================================================================
if [[ "$RUN_SECTION" -eq 0 || "$RUN_SECTION" -eq 2 ]]; then
  info "--- Section 2: SAFE-01 isolated fixture live undo drill and re-stow rehearsal ---"

  S2_ROOT="$(mktemp -d /tmp/p20-assert-s2-XXXXXX)"
  SCRATCH_ROOTS+=("$S2_ROOT")

  # Setup mock hypr repo and live home
  mkdir -p "$S2_ROOT/repo/stow/hypr_drill/.config/hypr/custom"
  mkdir -p "$S2_ROOT/home/.config/hypr/custom"

  for f in variables.lua keybinds.lua rules.lua; do
    printf 'return "repo"\n' > "$S2_ROOT/repo/stow/hypr_drill/.config/hypr/custom/$f"
    printf 'return "legacy stub"\n' > "$S2_ROOT/home/.config/hypr/custom/$f"
  done

  # 1. Take timestamped backup
  BACKUP_EPOCH="$(date +%s)"
  BACKUP_DIR="$S2_ROOT/home/.config/hypr/custom.backup.$BACKUP_EPOCH"
  cp -a "$S2_ROOT/home/.config/hypr/custom" "$BACKUP_DIR"

  # 2. Prune stubs and execute initial stow
  rm -f "$S2_ROOT/home/.config/hypr/custom/"*.lua
  stow --no-folding -d "$S2_ROOT/repo/stow" -t "$S2_ROOT/home" hypr_drill

  ALL_LINKS=1
  for f in variables.lua keybinds.lua rules.lua; do
    if [[ ! -L "$S2_ROOT/home/.config/hypr/custom/$f" ]]; then
      ALL_LINKS=0
    fi
  done
  if [[ "$ALL_LINKS" -eq 1 ]]; then
    pass "SAFE-01 (S2): initial stow created symlinks for all target files"
  else
    fail "SAFE-01 (S2): initial stow did not create all expected symlinks"
  fi

  # 3. Execute undo drill: stow -D followed by backup restoration
  stow -D --no-folding -d "$S2_ROOT/repo/stow" -t "$S2_ROOT/home" hypr_drill

  ANY_LINK=0
  for f in variables.lua keybinds.lua rules.lua; do
    if [[ -e "$S2_ROOT/home/.config/hypr/custom/$f" || -L "$S2_ROOT/home/.config/hypr/custom/$f" ]]; then
      ANY_LINK=1
    fi
  done
  if [[ "$ANY_LINK" -eq 0 ]]; then
    pass "SAFE-01 (S2): unstow (stow -D) cleanly removed all managed symlinks"
  else
    fail "SAFE-01 (S2): unstow left residual symlinks or entries in target"
  fi

  # Restore from backup
  cp -a "$BACKUP_DIR/." "$S2_ROOT/home/.config/hypr/custom/"

  RESTORE_OK=1
  for f in variables.lua keybinds.lua rules.lua; do
    TGT="$S2_ROOT/home/.config/hypr/custom/$f"
    if [[ -L "$TGT" ]] || [[ ! -f "$TGT" ]] || ! grep -q 'legacy stub' "$TGT"; then
      RESTORE_OK=0
    fi
  done
  if [[ "$RESTORE_OK" -eq 1 ]]; then
    pass "SAFE-01 (S2): backup restoration restored exact pre-stow regular files and contents"
  else
    fail "SAFE-01 (S2): backup restoration failed to restore exact files or contents"
  fi

  # 4. Re-stow after rehearsal
  rm -f "$S2_ROOT/home/.config/hypr/custom/"*.lua
  stow --no-folding -d "$S2_ROOT/repo/stow" -t "$S2_ROOT/home" hypr_drill

  RESTOW_OK=1
  for f in variables.lua keybinds.lua rules.lua; do
    SRC="$S2_ROOT/repo/stow/hypr_drill/.config/hypr/custom/$f"
    TGT="$S2_ROOT/home/.config/hypr/custom/$f"
    if [[ ! -L "$TGT" ]] || [[ ! "$SRC" -ef "$TGT" ]]; then
      RESTOW_OK=0
    fi
  done
  if [[ "$RESTOW_OK" -eq 1 ]]; then
    pass "SAFE-01 (S2): re-stow cleanly restored symlink inode identity after undo rehearsal"
  else
    fail "SAFE-01 (S2): re-stow failed to establish matching inode symlinks"
  fi
fi

# ===========================================================================
# Terminal Summary
# ===========================================================================
echo "=== done: FAIL=${FAIL} FINDINGS=${FINDINGS} ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
